#if os(macOS)
import SwiftUI
import AppKit
import ApplicationServices
import SentinelCore

@MainActor
final class AppModel: ObservableObject {
    @Published var settings: SentrySettings
    @Published var events: [SentryEvent] = []
    @Published var isArmed: Bool = false
    @Published var countdownRemaining: Int?
    @Published var authMonitorAvailable: Bool = false
    @Published var accessibilityTrusted: Bool = AXIsProcessTrusted()
    @Published var helperStatus: HelperStatus?
    @Published var lastRuntimeError: String?
    @Published var captures: [CaptureRecord] = []
    @Published var cameraPermissionGranted: Bool = false

    let eye = EyeViewModel()

    private let runtimeStore: SharedRuntimeStore
    private let eventStore: EventStore
    private let captureStore: CaptureStore
    private let lockService = LockScreenService()
    private let cameraCaptureService = CameraCaptureService()
    private var countdownTask: Task<Void, Never>?
    private var helperPollTimer: Timer?
    private var lastObservedHelperState: HelperState?
    private var captureTail: Task<Void, Never>?

    private lazy var overlayController = OverlayWindowController(model: self)
    private lazy var coordinator = SentryCoordinator(
        settingsProvider: { [weak self] in self?.settings ?? .default },
        eventHandler: { [weak self] event in
            Task { @MainActor in self?.receive(event) }
        },
        authenticationAvailabilityHandler: { [weak self] available in
            Task { @MainActor in self?.authMonitorAvailable = available }
        }
    )

    init() {
        let directory = SharedRuntimeStore.defaultDirectory()
        let fallback = FileManager.default.temporaryDirectory.appendingPathComponent("Sentinel", isDirectory: true)
        self.runtimeStore = (try? SharedRuntimeStore(directory: directory)) ?? (try! SharedRuntimeStore(directory: fallback))
        self.eventStore = (try? EventStore(directory: directory)) ?? (try! EventStore(directory: fallback))
        self.captureStore = (try? CaptureStore(directory: directory)) ?? (try! CaptureStore(directory: fallback))
        self.settings = (try? runtimeStore.readSettings()) ?? .default
        self.isArmed = (try? runtimeStore.readArmed()) ?? false
        self.events = ((try? eventStore.load()) ?? []).sorted { $0.timestamp > $1.timestamp }
        self.captures = ((try? captureStore.load()) ?? []).sorted { $0.timestamp > $1.timestamp }
        self.helperStatus = try? runtimeStore.readHelperStatus()

        eye.naturalBlinkEnabled = settings.naturalBlinkEnabled
        eye.startAmbient()
        coordinator.start()
        cameraPermissionGranted = cameraCaptureService.isAuthorized
        persistSettings()
        startHelperStatusPolling()
        if isArmed && lockService.isSessionLocked {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
                self?.overlayController.show()
            }
        }

        NotificationCenter.default.addObserver(
            forName: NSApplication.willTerminateNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            try? self.runtimeStore.writeArmed(false)
        }
    }

    deinit {
        helperPollTimer?.invalidate()
        countdownTask?.cancel()
        captureTail?.cancel()
    }

    func text(_ key: AppStringKey) -> String {
        AppStrings.text(key, language: settings.language)
    }

    func binding<Value>(_ keyPath: WritableKeyPath<SentrySettings, Value>) -> Binding<Value> {
        Binding(
            get: { self.settings[keyPath: keyPath] },
            set: { value in
                self.settings[keyPath: keyPath] = value
                self.persistSettings()
                self.applyVisualSettings()
                self.coordinator.refreshSettings()
            }
        )
    }

    func startSentry() {
        countdownTask?.cancel()
        let seconds = ActivationPolicy.normalizedCountdown(settings.manualActivationCountdown)
        settings.manualActivationCountdown = seconds
        persistSettings()

        if seconds == 0 {
            enterSentryNow()
            return
        }

        countdownRemaining = seconds
        countdownTask = Task { [weak self] in
            guard let self else { return }
            for remaining in stride(from: seconds, through: 1, by: -1) {
                if Task.isCancelled { return }
                await MainActor.run { self.countdownRemaining = remaining }
                try? await Task.sleep(nanoseconds: 1_000_000_000)
            }
            if Task.isCancelled { return }
            await MainActor.run { self.enterSentryNow() }
        }
    }

    func cancelCountdown() {
        countdownTask?.cancel()
        countdownTask = nil
        countdownRemaining = nil
    }

    func enterSentryNow() {
        cancelCountdown()
        arm(recordEvent: true)
        accessibilityTrusted = lockService.isAccessibilityTrusted
        if !lockService.requestLock(promptIfNeeded: true) {
            accessibilityTrusted = lockService.isAccessibilityTrusted
            lastRuntimeError = text(.accessibilityRequired)
        } else {
            lastRuntimeError = nil
        }
    }

    func stopSentry() {
        cancelCountdown()
        disarm(recordEvent: true)
        overlayController.hide()
    }

    func clearHistory() {
        do {
            try eventStore.clear()
            events = []
        } catch {
            lastRuntimeError = error.localizedDescription
        }
    }

    func setAuthenticationFailureCaptureEnabled(_ enabled: Bool) {
        guard enabled else {
            settings.authenticationFailureCaptureEnabled = false
            persistSettings()
            return
        }

        Task { [weak self] in
            guard let self else { return }
            let granted = await self.cameraCaptureService.requestPermission()
            await MainActor.run {
                self.cameraPermissionGranted = granted
                self.settings.authenticationFailureCaptureEnabled = granted
                self.persistSettings()
                if !granted { self.lastRuntimeError = self.text(.cameraPermissionDenied) }
            }
        }
    }

    func refreshCameraPermissionStatus() {
        cameraPermissionGranted = cameraCaptureService.isAuthorized
    }

    func requestCameraPermission() {
        Task { [weak self] in
            guard let self else { return }
            let granted = await self.cameraCaptureService.requestPermission()
            await MainActor.run {
                self.cameraPermissionGranted = granted
                if !granted { self.lastRuntimeError = self.text(.cameraPermissionDenied) }
            }
        }
    }

    func captureRecord(id: UUID) -> CaptureRecord? {
        captures.first(where: { $0.id == id })
    }

    func captureImageURL(for record: CaptureRecord) -> URL {
        captureStore.imageURL(for: record)
    }

    func deleteCapture(_ record: CaptureRecord) {
        do {
            try captureStore.delete(id: record.id)
            try eventStore.updateCapture(eventID: record.eventID, state: nil, captureID: nil)
            reloadEventsAndCaptures()
        } catch {
            lastRuntimeError = error.localizedDescription
        }
    }

    func clearCaptures() {
        do {
            let captureIDs = Set(captures.map(\.id))
            try captureStore.clear()
            for event in events where event.captureID.map(captureIDs.contains) == true {
                try eventStore.updateCapture(eventID: event.id, state: nil, captureID: nil)
            }
            reloadEventsAndCaptures()
        } catch {
            lastRuntimeError = error.localizedDescription
        }
    }

    func openAccessibilitySettings() {
        lockService.openAccessibilitySettings()
    }

    func simulateAuthenticationFailure(kind: AuthenticationKind = .unknown) {
        coordinator.simulateAuthenticationOutcome(.failed(kind))
    }

    func simulateAuthenticationSuccess() {
        coordinator.simulateAuthenticationOutcome(.succeeded)
    }

    func eventTitle(_ event: SentryEvent) -> String {
        if event.type == .authenticationFailed {
            switch event.detail.flatMap(AuthenticationKind.init(rawValue:)) ?? .unknown {
            case .password: return text(.passwordFailure)
            case .touchID: return text(.touchIDFailure)
            case .unknown: return text(.unknownAuthentication)
            }
        }
        return EventPresentation.title(for: event.type, language: settings.language)
    }

    func statusText() -> String {
        if eye.state == .alertHigh || eye.state == .alertLow { return text(.alert) }
        return isArmed ? text(.protected) : text(.inactive)
    }

    private func arm(recordEvent: Bool) {
        guard !isArmed else { return }
        isArmed = true
        try? runtimeStore.writeArmed(true)
        if recordEvent { receive(SentryEvent(type: .sentryArmed)) }
    }

    private func disarm(recordEvent: Bool) {
        guard isArmed else { return }
        isArmed = false
        try? runtimeStore.writeArmed(false)
        if recordEvent { receive(SentryEvent(type: .sentryDisarmed)) }
    }

    private func receive(_ incomingEvent: SentryEvent) {
        var event = incomingEvent
        let shouldCapture = event.type == .authenticationFailed
            && settings.authenticationFailureCaptureEnabled && isArmed
        if shouldCapture { event.captureState = .pending }

        do {
            try eventStore.append(event)
            try eventStore.prune(retentionDays: settings.eventRetentionDays)
            reloadEventsAndCaptures()
        } catch {
            lastRuntimeError = error.localizedDescription
        }

        eye.handle(event: event, highAlertDuration: settings.highAlertDuration)

        if event.severity == .alert, settings.alertSoundEnabled {
            NSSound.beep()
        }

        if shouldCapture {
            enqueueAuthenticationCapture(for: event)
        }

        switch event.type {
        case .sessionLocked:
            if settings.autoArmOnLock { arm(recordEvent: !isArmed) }
            if isArmed { overlayController.show() }
        case .sessionUnlocked:
            overlayController.hide()
            if isArmed { disarm(recordEvent: true) }
        default:
            break
        }
    }

    private func enqueueAuthenticationCapture(for event: SentryEvent) {
        let previous = captureTail
        captureTail = Task { @MainActor [weak self] in
            if let previous { _ = await previous.result }
            guard let self else { return }
            await self.performAuthenticationCapture(for: event)
        }
    }

    private func performAuthenticationCapture(for event: SentryEvent) async {
        guard settings.authenticationFailureCaptureEnabled && isArmed else {
            markCapture(eventID: event.id, state: .failed, captureID: nil)
            return
        }

        let kind = event.detail.flatMap(AuthenticationKind.init(rawValue:)) ?? .unknown
        do {
            let frame = try await cameraCaptureService.captureJPEG(quality: settings.captureImageQuality)
            let record = try captureStore.saveJPEG(
                frame.data,
                eventID: event.id,
                authenticationKind: kind,
                width: frame.width,
                height: frame.height,
                timestamp: Date()
            )
            try eventStore.updateCapture(eventID: event.id, state: .available, captureID: record.id)
            try pruneCapturesAndAssociations()
            cameraPermissionGranted = cameraCaptureService.isAuthorized
            reloadEventsAndCaptures()
        } catch {
            markCapture(eventID: event.id, state: .failed, captureID: nil)
            cameraPermissionGranted = cameraCaptureService.isAuthorized
            lastRuntimeError = error.localizedDescription
        }
    }

    private func markCapture(eventID: UUID, state: CaptureState, captureID: UUID?) {
        do {
            try eventStore.updateCapture(eventID: eventID, state: state, captureID: captureID)
            reloadEventsAndCaptures()
        } catch {
            lastRuntimeError = error.localizedDescription
        }
    }

    private func pruneCapturesAndAssociations() throws {
        let maxBytes = Int64(max(1, settings.captureMaxStorageMB)) * 1_024 * 1_024
        let removed = try captureStore.prune(
            retentionDays: settings.captureRetentionDays,
            maxBytes: maxBytes
        )
        guard !removed.isEmpty else { return }
        let removedIDs = Set(removed)
        for event in try eventStore.load() where event.captureID.map(removedIDs.contains) == true {
            try eventStore.updateCapture(eventID: event.id, state: nil, captureID: nil)
        }
    }

    private func reloadEventsAndCaptures() {
        events = ((try? eventStore.load()) ?? []).sorted { $0.timestamp > $1.timestamp }
        captures = ((try? captureStore.load()) ?? []).sorted { $0.timestamp > $1.timestamp }
    }

    private func applyVisualSettings() {
        eye.naturalBlinkEnabled = settings.naturalBlinkEnabled
    }

    private func persistSettings() {
        do {
            try runtimeStore.writeSettings(settings)
            try pruneCapturesAndAssociations()
            reloadEventsAndCaptures()
        } catch {
            lastRuntimeError = error.localizedDescription
        }
    }

    private func startHelperStatusPolling() {
        helperPollTimer?.invalidate()
        helperPollTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in
            guard let self else { return }
            let previous = self.lastObservedHelperState
            let status = try? self.runtimeStore.readHelperStatus()
            self.helperStatus = status
            self.accessibilityTrusted = self.lockService.isAccessibilityTrusted

            guard let status else { return }
            if status.state != previous {
                switch status.state {
                case .recoveryAttempted:
                    if status.lastRecoveryAttemptAt.map({ Date().timeIntervalSince($0) < 120 }) ?? false {
                        self.receive(SentryEvent(type: .monitoringInterrupted))
                    }
                case .recoveryFailed, .recoveryBlocked:
                    self.receive(SentryEvent(type: .monitoringRecoveryFailed, severity: .alert))
                case .healthy:
                    if previous == .recoveryAttempted || previous == .recoveryFailed || previous == .recoveryBlocked {
                        self.receive(SentryEvent(type: .monitoringRecovered))
                    }
                case .idle:
                    break
                }
                self.lastObservedHelperState = status.state
            }
        }
        helperPollTimer?.fire()
    }
}
#endif

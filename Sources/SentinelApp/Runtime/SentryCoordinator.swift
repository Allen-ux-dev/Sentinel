#if os(macOS)
import Foundation
import SentinelCore

@MainActor
final class SentryCoordinator {
    private let settingsProvider: () -> SentrySettings
    private let eventHandler: (SentryEvent) -> Void
    private let authenticationAvailabilityHandler: (Bool) -> Void

    private let network = NetworkMonitor()
    private let power = PowerMonitor()
    private let usb = USBMonitor()
    private let session = SessionMonitor()
    private let authentication: ExperimentalSystemLogAuthMonitor
    private let heartbeat: HeartbeatWriter
    private var failureTracker: AuthenticationFailureTracker

    init(
        settingsProvider: @escaping () -> SentrySettings,
        eventHandler: @escaping (SentryEvent) -> Void,
        authenticationAvailabilityHandler: @escaping (Bool) -> Void
    ) {
        self.settingsProvider = settingsProvider
        self.eventHandler = eventHandler
        self.authenticationAvailabilityHandler = authenticationAvailabilityHandler
        let settings = settingsProvider()
        self.failureTracker = AuthenticationFailureTracker(
            threshold: settings.authenticationFailureThreshold,
            window: settings.authenticationFailureWindow
        )
        self.authentication = ExperimentalSystemLogAuthMonitor()
        let store = (try? SharedRuntimeStore(directory: SharedRuntimeStore.defaultDirectory()))
            ?? (try! SharedRuntimeStore(directory: FileManager.default.temporaryDirectory.appendingPathComponent("Sentinel")))
        self.heartbeat = HeartbeatWriter(runtimeStore: store)
    }

    func start() {
        heartbeat.start()
        network.start { [weak self] connected in
            self?.emit(connected ? .networkConnected : .networkDisconnected)
        }
        power.start { [weak self] connected in
            self?.emit(connected ? .powerConnected : .powerDisconnected)
        }
        usb.start { [weak self] in self?.emit(.usbChanged) }
        session.start { [weak self] type in
            guard let self else { return }
            if type == .sessionUnlocked { self.failureTracker.recordSuccess() }
            self.emit(type)
        }
        startAuthenticationMonitorIfEnabled()
    }

    func stop() {
        network.stop()
        power.stop()
        usb.stop()
        session.stop()
        authentication.stop()
        heartbeat.stop()
        authenticationAvailabilityHandler(false)
    }

    func refreshSettings() {
        let settings = settingsProvider()
        failureTracker = AuthenticationFailureTracker(
            threshold: settings.authenticationFailureThreshold,
            window: settings.authenticationFailureWindow
        )
        startAuthenticationMonitorIfEnabled()
    }

    func simulateAuthenticationOutcome(_ outcome: AuthenticationOutcome) {
        processAuthentication(outcome)
    }

    private func startAuthenticationMonitorIfEnabled() {
        authentication.stop()
        guard settingsProvider().experimentalAuthenticationMonitorEnabled else {
            authenticationAvailabilityHandler(false)
            return
        }
        authentication.start { [weak self] outcome in
            Task { @MainActor in self?.processAuthentication(outcome) }
        }
        authenticationAvailabilityHandler(authentication.isAvailable)
    }

    private func processAuthentication(_ outcome: AuthenticationOutcome) {
        switch outcome {
        case .failed(let kind):
            eventHandler(SentryEvent(type: .authenticationFailed, detail: kind.rawValue))
            if failureTracker.recordFailure() {
                eventHandler(SentryEvent(type: .authenticationAlert, severity: .alert))
            }
        case .succeeded:
            failureTracker.recordSuccess()
            eventHandler(SentryEvent(type: .authenticationSucceeded))
        }
    }

    private func emit(_ type: SentryEventType) {
        eventHandler(SentryEvent(type: type))
    }
}
#endif

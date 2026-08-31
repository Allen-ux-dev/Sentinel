#if os(macOS)
import SwiftUI
import SentinelCore

@MainActor
final class EyeViewModel: ObservableObject {
    @Published var state: EyeState = .idle
    @Published var eyelidClosure: CGFloat = 0
    @Published var pupilScale: CGFloat = 1
    @Published var innerScale: CGFloat = 1
    @Published var gazeBias: CGSize = .zero
    @Published var ripplePhase: CGFloat = 0
    @Published var rippleOpacity: CGFloat = 0
    @Published var naturalBlinkEnabled: Bool = true

    let mouseTracker = MouseTracker()
    private var selector = ReactionSelector(historyLimit: 3)
    private var reactionTask: Task<Void, Never>?
    private var ambientTask: Task<Void, Never>?
    private var alertTask: Task<Void, Never>?
    private var stateResetTask: Task<Void, Never>?

    func startAmbient() {
        mouseTracker.start()
        ambientTask?.cancel()
        ambientTask = Task { [weak self] in
            while !Task.isCancelled {
                let seconds = AmbientBlinkPolicy.delaySeconds(forUnitValue: Double.random(in: 0...1))
                try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                guard !Task.isCancelled, let self else { return }
                if self.naturalBlinkEnabled, self.state == .idle || self.state == .tracking {
                    let reaction = AmbientBlinkPolicy.reaction(forPercentile: Int.random(in: 0..<100))
                    await self.play(reaction)
                }
            }
        }
    }

    func handle(event: SentryEvent, highAlertDuration: TimeInterval) {
        let isPersistentAlert = state == .alertHigh || state == .alertLow
        let clearsAlert = event.type == .authenticationSucceeded || event.type == .sessionUnlocked
        let startsAlert = event.type == .authenticationAlert || event.type == .monitoringRecoveryFailed

        if clearsAlert {
            alertTask?.cancel()
            alertTask = nil
        }

        if !isPersistentAlert || clearsAlert || startsAlert {
            state = EyeStateReducer.state(for: event)
        }

        switch event.type {
        case .authenticationFailed:
            var pool = event.detail == AuthenticationKind.touchID.rawValue
                ? EyeReaction.touchIDFailurePool
                : EyeReaction.authenticationFailurePool
            if Int.random(in: 0..<100) < 5 { pool.append(.easterEggPauseGlance) }
            if let reaction = selector.choose(from: pool) { playDetached(reaction) }
            scheduleIdleIfAllowed(after: 1.1)

        case .authenticationSucceeded, .sessionUnlocked:
            playDetached(.singleBlink)
            scheduleIdleIfAllowed(after: 0.65, force: true)

        case .authenticationAlert, .monitoringRecoveryFailed:
            stateResetTask?.cancel()
            playDetached(.pupilConstrict)
            alertTask?.cancel()
            alertTask = Task { [weak self] in
                let nanos = UInt64(max(1, highAlertDuration) * 1_000_000_000)
                try? await Task.sleep(nanoseconds: nanos)
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    if self?.state == .alertHigh { self?.state = .alertLow }
                }
            }

        case .networkDisconnected, .powerDisconnected:
            playDetached(.pupilConstrict)
            scheduleIdleIfAllowed(after: 1.0)

        case .networkConnected, .powerConnected:
            playDetached(.ringRipple)
            scheduleIdleIfAllowed(after: 1.0)

        case .usbChanged:
            playDetached(.singleBlink)
            scheduleIdleIfAllowed(after: 0.8)

        case .systemSleeping:
            stateResetTask?.cancel()
            withAnimation(.easeInOut(duration: 0.7)) { eyelidClosure = 0.72 }

        case .systemWoke:
            withAnimation(.spring(response: 0.65, dampingFraction: 0.8)) { eyelidClosure = 0 }
            playDetached(.wakeAndFocus)
            scheduleIdleIfAllowed(after: 1.2)

        case .monitoringInterrupted:
            playDetached(.squint)
            scheduleIdleIfAllowed(after: 1.0)

        case .monitoringRecovered:
            playDetached(.ringRipple)
            scheduleIdleIfAllowed(after: 1.0)

        case .sentryArmed, .sentryDisarmed, .sessionLocked:
            scheduleIdleIfAllowed(after: 0.9)
        }
    }

    private func scheduleIdleIfAllowed(after seconds: Double, force: Bool = false) {
        stateResetTask?.cancel()
        stateResetTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(max(0, seconds) * 1_000_000_000))
            guard !Task.isCancelled else { return }
            await MainActor.run {
                guard let self else { return }
                if force || (self.state != .alertHigh && self.state != .alertLow && self.state != .sleeping) {
                    self.state = .idle
                }
            }
        }
    }

    private func playDetached(_ reaction: EyeReaction) {
        reactionTask?.cancel()
        reactionTask = Task { [weak self] in
            guard let self else { return }
            await self.play(reaction)
        }
    }

    private func sleep(_ seconds: Double) async {
        try? await Task.sleep(nanoseconds: UInt64(max(0, seconds) * 1_000_000_000))
    }

    private func resetTransient(animated: Bool = true) {
        let updates = {
            self.eyelidClosure = self.state == .alertLow ? 0.13 : 0
            self.pupilScale = 1
            self.innerScale = 1
            self.gazeBias = .zero
            self.rippleOpacity = 0
            self.ripplePhase = 0
        }
        if animated { withAnimation(.easeOut(duration: 0.28), updates) } else { updates() }
    }

    func play(_ reaction: EyeReaction) async {
        resetTransient(animated: false)
        switch reaction {
        case .pupilConstrict:
            withAnimation(.easeOut(duration: 0.10)) { pupilScale = 0.56; eyelidClosure = 0.10 }
            await sleep(0.38)
            resetTransient()
        case .squint:
            withAnimation(.easeInOut(duration: 0.18)) { eyelidClosure = 0.38 }
            await sleep(0.46)
            resetTransient()
        case .glanceLeft:
            withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) { gazeBias = CGSize(width: -0.52, height: 0.03) }
            await sleep(0.45)
            resetTransient()
        case .glanceRight:
            withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) { gazeBias = CGSize(width: 0.52, height: 0.03) }
            await sleep(0.45)
            resetTransient()
        case .singleBlink:
            withAnimation(.easeIn(duration: 0.085)) { eyelidClosure = 1 }
            await sleep(0.09)
            withAnimation(.easeOut(duration: 0.15)) { eyelidClosure = state == .alertLow ? 0.13 : 0 }
        case .doubleBlink:
            for _ in 0..<2 {
                withAnimation(.easeIn(duration: 0.075)) { eyelidClosure = 1 }
                await sleep(0.08)
                withAnimation(.easeOut(duration: 0.12)) { eyelidClosure = 0 }
                await sleep(0.11)
            }
            resetTransient()
        case .innerShrink:
            withAnimation(.spring(response: 0.25, dampingFraction: 0.72)) { innerScale = 0.965 }
            await sleep(0.32)
            resetTransient()
        case .ringRipple:
            ripplePhase = 0
            rippleOpacity = 0.72
            withAnimation(.easeOut(duration: 0.72)) { ripplePhase = 1; rippleOpacity = 0 }
            await sleep(0.74)
            resetTransient(animated: false)
        case .pupilOffset:
            let direction: CGFloat = Bool.random() ? -1 : 1
            withAnimation(.spring(response: 0.22, dampingFraction: 0.75)) { gazeBias = CGSize(width: 0.42 * direction, height: -0.12) }
            await sleep(0.35)
            resetTransient()
        case .wakeAndFocus:
            pupilScale = 1.18
            withAnimation(.spring(response: 0.38, dampingFraction: 0.72)) { pupilScale = 0.84; eyelidClosure = 0 }
            await sleep(0.34)
            resetTransient()
        case .easterEggPauseGlance:
            await sleep(0.26)
            let direction: CGFloat = Bool.random() ? -1 : 1
            withAnimation(.easeInOut(duration: 0.32)) { gazeBias = CGSize(width: 0.62 * direction, height: 0.08) }
            await sleep(0.55)
            resetTransient()
        }
    }
}
#endif

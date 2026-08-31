#if os(macOS)
import Foundation
import SentinelCore

final class WatchdogLoop {
    private let runtimeStore: SharedRuntimeStore
    private var retryBudget: RetryBudget
    private var lastBudgetShape: (Int, TimeInterval)
    private var isFirstTick = true
    private let staleAfter: TimeInterval = 30

    init(runtimeStore: SharedRuntimeStore) {
        self.runtimeStore = runtimeStore
        let settings = (try? runtimeStore.readSettings()) ?? .default
        self.retryBudget = RetryBudget(maxAttempts: settings.watchdogMaxAttempts, window: settings.watchdogWindow)
        self.lastBudgetShape = (settings.watchdogMaxAttempts, settings.watchdogWindow)
    }

    func run() -> Never {
        while true {
            autoreleasepool { tick() }
            Thread.sleep(forTimeInterval: 8)
        }
    }

    private func tick() {
        let now = Date()
        let settings = (try? runtimeStore.readSettings()) ?? .default
        rebuildBudgetIfNeeded(settings)
        let armed = (try? runtimeStore.readArmed()) ?? false
        let heartbeat = try? runtimeStore.readHeartbeat()

        if isFirstTick {
            isFirstTick = false
            if settings.launchAtLogin {
                let heartbeatIsMissingOrStale = heartbeat == nil || (heartbeat.map {
                    WatchdogPolicy.isHeartbeatStale($0, now: now, staleAfter: 90)
                } ?? true)
                if heartbeatIsMissingOrStale {
                    _ = openSentinel()
                }
            }
        }

        guard WatchdogPolicy.requiresRecovery(armed: armed, heartbeat: heartbeat, now: now, staleAfter: staleAfter) else {
            try? runtimeStore.writeHelperStatus(HelperStatus(
                lastCheckedAt: now,
                lastRecoveryAttemptAt: nil,
                recoveryAttemptsInWindow: retryBudget.attemptCount,
                state: .healthy
            ))
            return
        }

        guard retryBudget.consume(at: now) else {
            try? runtimeStore.writeHelperStatus(HelperStatus(
                lastCheckedAt: now,
                lastRecoveryAttemptAt: nil,
                recoveryAttemptsInWindow: retryBudget.attemptCount,
                state: .recoveryBlocked
            ))
            return
        }

        let launched = openSentinel()
        try? runtimeStore.writeHelperStatus(HelperStatus(
            lastCheckedAt: now,
            lastRecoveryAttemptAt: now,
            recoveryAttemptsInWindow: retryBudget.attemptCount,
            state: launched ? .recoveryAttempted : .recoveryFailed
        ))
    }

    private func rebuildBudgetIfNeeded(_ settings: SentrySettings) {
        let shape = (settings.watchdogMaxAttempts, settings.watchdogWindow)
        if shape.0 != lastBudgetShape.0 || shape.1 != lastBudgetShape.1 {
            retryBudget = RetryBudget(maxAttempts: shape.0, window: shape.1)
            lastBudgetShape = shape
        }
    }

    @discardableResult
    private func openSentinel() -> Bool {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        process.arguments = ["-g", "-b", "dev.sentinel.mac"]
        do {
            try process.run()
            process.waitUntilExit()
            return process.terminationStatus == 0
        } catch {
            return false
        }
    }
}
#endif

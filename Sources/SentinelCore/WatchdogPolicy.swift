import Foundation

public enum WatchdogPolicy {
    public static func isHeartbeatStale(
        _ heartbeat: HeartbeatSnapshot,
        now: Date = Date(),
        staleAfter: TimeInterval = 30
    ) -> Bool {
        now.timeIntervalSince(heartbeat.timestamp) > max(1, staleAfter)
    }

    public static func requiresRecovery(
        armed: Bool,
        heartbeat: HeartbeatSnapshot?,
        now: Date = Date(),
        staleAfter: TimeInterval = 30
    ) -> Bool {
        guard armed else { return false }
        guard let heartbeat else { return true }
        return isHeartbeatStale(heartbeat, now: now, staleAfter: staleAfter)
    }
}

import Foundation

public struct RetentionPolicy: Sendable {
    public let days: Int

    public init(days: Int) {
        self.days = max(1, days)
    }

    public func prune(_ events: [SentryEvent], now: Date = Date()) -> [SentryEvent] {
        let cutoff = now.addingTimeInterval(-TimeInterval(days) * 86_400)
        return events.filter { $0.timestamp >= cutoff }
    }
}

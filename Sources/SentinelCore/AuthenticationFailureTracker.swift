import Foundation

public struct AuthenticationFailureTracker: Sendable {
    public let threshold: Int
    public let window: TimeInterval
    private var failures: [Date] = []
    private var hasCrossedThreshold = false

    public init(threshold: Int, window: TimeInterval) {
        self.threshold = max(1, threshold)
        self.window = max(1, window)
    }

    public var failureCount: Int { failures.count }

    @discardableResult
    public mutating func recordFailure(at date: Date = Date()) -> Bool {
        prune(reference: date)
        failures.append(date)
        guard failures.count >= threshold, !hasCrossedThreshold else { return false }
        hasCrossedThreshold = true
        return true
    }

    public mutating func recordSuccess() {
        failures.removeAll(keepingCapacity: true)
        hasCrossedThreshold = false
    }

    public mutating func prune(reference: Date = Date()) {
        let cutoff = reference.addingTimeInterval(-window)
        failures.removeAll { $0 < cutoff }
        if failures.count < threshold {
            hasCrossedThreshold = false
        }
    }
}

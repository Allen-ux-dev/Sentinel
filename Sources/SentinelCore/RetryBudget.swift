import Foundation

public struct RetryBudget: Sendable {
    public let maxAttempts: Int
    public let window: TimeInterval
    private var attempts: [Date] = []

    public init(maxAttempts: Int, window: TimeInterval) {
        self.maxAttempts = max(1, maxAttempts)
        self.window = max(1, window)
    }

    public var attemptCount: Int { attempts.count }

    @discardableResult
    public mutating func consume(at date: Date = Date()) -> Bool {
        let cutoff = date.addingTimeInterval(-window)
        attempts.removeAll { $0 < cutoff }
        guard attempts.count < maxAttempts else { return false }
        attempts.append(date)
        return true
    }

    public mutating func reset() {
        attempts.removeAll(keepingCapacity: true)
    }
}

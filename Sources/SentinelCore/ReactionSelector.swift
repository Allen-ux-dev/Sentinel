import Foundation

public struct ReactionSelector: Sendable {
    public let historyLimit: Int
    public private(set) var recent: [EyeReaction] = []

    public init(historyLimit: Int = 3) {
        self.historyLimit = max(0, historyLimit)
    }

    public mutating func choose(
        from pool: [EyeReaction],
        randomIndex: (Int) -> Int = { Int.random(in: 0..<$0) }
    ) -> EyeReaction? {
        guard !pool.isEmpty else { return nil }

        var available = pool.filter { !recent.contains($0) }
        if available.isEmpty { available = pool }

        let rawIndex = randomIndex(available.count)
        let index = max(0, min(available.count - 1, rawIndex))
        let selected = available[index]

        if historyLimit > 0 {
            recent.append(selected)
            if recent.count > historyLimit {
                recent.removeFirst(recent.count - historyLimit)
            }
        }
        return selected
    }

    public mutating func reset() {
        recent.removeAll(keepingCapacity: true)
    }
}

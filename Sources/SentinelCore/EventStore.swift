import Foundation

public final class EventStore: @unchecked Sendable {
    private let fileURL: URL
    private let lock = NSLock()
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    public init(directory: URL) throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        self.fileURL = directory.appendingPathComponent("events.json")
        self.encoder = JSONEncoder()
        self.decoder = JSONDecoder()
        self.encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        if !FileManager.default.fileExists(atPath: fileURL.path) {
            try Data("[]".utf8).write(to: fileURL, options: .atomic)
        }
    }

    public func load() throws -> [SentryEvent] {
        lock.lock(); defer { lock.unlock() }
        return try loadUnlocked()
    }

    public func append(_ event: SentryEvent) throws {
        lock.lock(); defer { lock.unlock() }
        var events = try loadUnlocked()
        events.append(event)
        try writeUnlocked(events)
    }

    public func clear() throws {
        lock.lock(); defer { lock.unlock() }
        try writeUnlocked([])
    }

    public func updateCapture(eventID: UUID, state: CaptureState?, captureID: UUID?) throws {
        lock.lock(); defer { lock.unlock() }
        var events = try loadUnlocked()
        guard let index = events.firstIndex(where: { $0.id == eventID }) else { return }
        events[index].captureState = state
        events[index].captureID = captureID
        try writeUnlocked(events)
    }

    public func prune(retentionDays: Int, now: Date = Date()) throws {
        lock.lock(); defer { lock.unlock() }
        let current = try loadUnlocked()
        let pruned = RetentionPolicy(days: retentionDays).prune(current, now: now)
        if pruned != current { try writeUnlocked(pruned) }
    }

    private func loadUnlocked() throws -> [SentryEvent] {
        let data = try Data(contentsOf: fileURL)
        return try decoder.decode([SentryEvent].self, from: data)
    }

    private func writeUnlocked(_ events: [SentryEvent]) throws {
        let data = try encoder.encode(events)
        try data.write(to: fileURL, options: .atomic)
    }
}

import Foundation

public final class CaptureStore: @unchecked Sendable {
    private let rootDirectory: URL
    private let capturesDirectory: URL
    private let metadataURL: URL
    private let lock = NSLock()
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    public init(directory: URL) throws {
        self.rootDirectory = directory
        self.capturesDirectory = directory.appendingPathComponent("Captures", isDirectory: true)
        self.metadataURL = directory.appendingPathComponent("captures.json")
        self.encoder = JSONEncoder()
        self.decoder = JSONDecoder()
        self.encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        try FileManager.default.createDirectory(at: rootDirectory, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: capturesDirectory, withIntermediateDirectories: true)
        if !FileManager.default.fileExists(atPath: metadataURL.path) {
            try Data("[]".utf8).write(to: metadataURL, options: .atomic)
        }
    }

    public func load() throws -> [CaptureRecord] {
        lock.lock(); defer { lock.unlock() }
        return try loadUnlocked()
    }

    @discardableResult
    public func saveJPEG(
        _ data: Data,
        eventID: UUID,
        authenticationKind: AuthenticationKind,
        width: Int,
        height: Int,
        timestamp: Date = Date()
    ) throws -> CaptureRecord {
        lock.lock(); defer { lock.unlock() }

        let id = UUID()
        let filename = "capture-\(id.uuidString).jpg"
        let imageURL = capturesDirectory.appendingPathComponent(filename)
        let record = CaptureRecord(
            id: id,
            eventID: eventID,
            timestamp: timestamp,
            authenticationKind: authenticationKind,
            filename: filename,
            byteCount: data.count,
            width: width,
            height: height
        )

        try data.write(to: imageURL, options: .atomic)
        do {
            var records = try loadUnlocked()
            records.append(record)
            try writeUnlocked(records)
        } catch {
            try? FileManager.default.removeItem(at: imageURL)
            throw error
        }
        return record
    }

    public func imageURL(for record: CaptureRecord) -> URL {
        capturesDirectory.appendingPathComponent(record.filename)
    }

    public func delete(id: UUID) throws {
        lock.lock(); defer { lock.unlock() }
        var records = try loadUnlocked()
        guard let index = records.firstIndex(where: { $0.id == id }) else { return }
        let record = records.remove(at: index)
        let url = capturesDirectory.appendingPathComponent(record.filename)
        if FileManager.default.fileExists(atPath: url.path) {
            try FileManager.default.removeItem(at: url)
        }
        try writeUnlocked(records)
    }

    public func clear() throws {
        lock.lock(); defer { lock.unlock() }
        let records = try loadUnlocked()
        for record in records {
            let url = capturesDirectory.appendingPathComponent(record.filename)
            try? FileManager.default.removeItem(at: url)
        }
        try writeUnlocked([])
    }

    @discardableResult
    public func prune(retentionDays: Int, maxBytes: Int64, now: Date = Date()) throws -> [UUID] {
        lock.lock(); defer { lock.unlock() }
        var records = try loadUnlocked()
        let cutoff = now.addingTimeInterval(-Double(max(1, retentionDays)) * 86_400)
        var removed: [CaptureRecord] = []

        records.removeAll { record in
            if record.timestamp < cutoff {
                removed.append(record)
                return true
            }
            return false
        }

        let cap = max(0, maxBytes)
        var total = records.reduce(Int64(0)) { $0 + Int64(max(0, $1.byteCount)) }
        if total > cap {
            let oldestFirst = records.sorted { $0.timestamp < $1.timestamp }
            var removeIDs = Set<UUID>()
            for record in oldestFirst where total > cap {
                removeIDs.insert(record.id)
                removed.append(record)
                total -= Int64(max(0, record.byteCount))
            }
            records.removeAll { removeIDs.contains($0.id) }
        }

        for record in removed {
            let url = capturesDirectory.appendingPathComponent(record.filename)
            try? FileManager.default.removeItem(at: url)
        }
        try writeUnlocked(records)
        return removed.map(\.id)
    }

    private func loadUnlocked() throws -> [CaptureRecord] {
        let data = try Data(contentsOf: metadataURL)
        return try decoder.decode([CaptureRecord].self, from: data)
    }

    private func writeUnlocked(_ records: [CaptureRecord]) throws {
        let data = try encoder.encode(records)
        try data.write(to: metadataURL, options: .atomic)
    }
}

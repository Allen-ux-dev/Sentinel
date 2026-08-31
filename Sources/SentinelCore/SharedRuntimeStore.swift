import Foundation

public struct HeartbeatSnapshot: Codable, Equatable, Sendable {
    public var timestamp: Date
    public var processID: Int32

    public init(timestamp: Date = Date(), processID: Int32) {
        self.timestamp = timestamp
        self.processID = processID
    }
}

public enum HelperState: String, Codable, Equatable, Sendable {
    case idle
    case healthy
    case recoveryAttempted
    case recoveryBlocked
    case recoveryFailed
}

public struct HelperStatus: Codable, Equatable, Sendable {
    public var lastCheckedAt: Date
    public var lastRecoveryAttemptAt: Date?
    public var recoveryAttemptsInWindow: Int
    public var state: HelperState

    public init(
        lastCheckedAt: Date = Date(),
        lastRecoveryAttemptAt: Date? = nil,
        recoveryAttemptsInWindow: Int = 0,
        state: HelperState = .idle
    ) {
        self.lastCheckedAt = lastCheckedAt
        self.lastRecoveryAttemptAt = lastRecoveryAttemptAt
        self.recoveryAttemptsInWindow = recoveryAttemptsInWindow
        self.state = state
    }
}

public final class SharedRuntimeStore: @unchecked Sendable {
    public let directory: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let lock = NSLock()

    public init(directory: URL) throws {
        self.directory = directory
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    }

    public static func defaultDirectory() -> URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/Application Support")
        return base.appendingPathComponent("Sentinel", isDirectory: true)
    }

    public func writeSettings(_ value: SentrySettings) throws { try write(value, name: "settings.json") }
    public func readSettings() throws -> SentrySettings { try read(SentrySettings.self, name: "settings.json") ?? .default }

    public func writeHeartbeat(_ value: HeartbeatSnapshot) throws { try write(value, name: "heartbeat.json") }
    public func readHeartbeat() throws -> HeartbeatSnapshot? { try read(HeartbeatSnapshot.self, name: "heartbeat.json") }

    public func writeArmed(_ value: Bool) throws { try write(value, name: "armed.json") }
    public func readArmed() throws -> Bool { try read(Bool.self, name: "armed.json") ?? false }

    public func writeHelperStatus(_ value: HelperStatus) throws { try write(value, name: "helper-status.json") }
    public func readHelperStatus() throws -> HelperStatus? { try read(HelperStatus.self, name: "helper-status.json") }

    private func write<T: Encodable>(_ value: T, name: String) throws {
        lock.lock(); defer { lock.unlock() }
        let data = try encoder.encode(value)
        try data.write(to: directory.appendingPathComponent(name), options: .atomic)
    }

    private func read<T: Decodable>(_ type: T.Type, name: String) throws -> T? {
        lock.lock(); defer { lock.unlock() }
        let url = directory.appendingPathComponent(name)
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        return try decoder.decode(type, from: Data(contentsOf: url))
    }
}

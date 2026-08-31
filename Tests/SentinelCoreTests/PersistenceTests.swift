import XCTest
@testable import SentinelCore

final class PersistenceTests: XCTestCase {
    private func temporaryDirectory() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    func testEventStoreRoundTripsAndPrunesExpiredEvents() throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = try EventStore(directory: directory)
        let now = Date(timeIntervalSince1970: 2_000_000)

        try store.append(SentryEvent(timestamp: now.addingTimeInterval(-10 * 86_400), type: .networkDisconnected))
        let recent = SentryEvent(timestamp: now.addingTimeInterval(-86_400), type: .networkConnected)
        try store.append(recent)
        try store.prune(retentionDays: 7, now: now)

        XCTAssertEqual(try store.load().map(\.id), [recent.id])
    }

    func testEventStoreClearRemovesHistory() throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = try EventStore(directory: directory)
        try store.append(SentryEvent(type: .usbChanged))
        try store.clear()
        XCTAssertTrue(try store.load().isEmpty)
    }

    func testSharedRuntimeStoreRoundTripsSettingsHeartbeatAndArmedState() throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let runtime = try SharedRuntimeStore(directory: directory)
        var settings = SentrySettings.default
        settings.language = .zhHans
        settings.launchAtLogin = false
        let heartbeat = HeartbeatSnapshot(timestamp: Date(timeIntervalSince1970: 42), processID: 123)

        try runtime.writeSettings(settings)
        try runtime.writeHeartbeat(heartbeat)
        try runtime.writeArmed(true)

        XCTAssertEqual(try runtime.readSettings(), settings)
        XCTAssertEqual(try runtime.readHeartbeat(), heartbeat)
        XCTAssertTrue(try runtime.readArmed())
    }

    func testSharedRuntimeStoreRoundTripsHelperStatus() throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let runtime = try SharedRuntimeStore(directory: directory)
        let status = HelperStatus(
            lastCheckedAt: Date(timeIntervalSince1970: 100),
            lastRecoveryAttemptAt: Date(timeIntervalSince1970: 90),
            recoveryAttemptsInWindow: 2,
            state: .recoveryAttempted
        )

        try runtime.writeHelperStatus(status)
        XCTAssertEqual(try runtime.readHelperStatus(), status)
    }
}

extension PersistenceTests {
    func testLegacyEventJSONDecodesWithoutCaptureFields() throws {
        struct LegacyEvent: Codable {
            var id: UUID
            var timestamp: Date
            var type: SentryEventType
            var severity: SentrySeverity
            var detail: String?
        }

        let id = UUID()
        let legacy = LegacyEvent(
            id: id,
            timestamp: Date(timeIntervalSince1970: 1234),
            type: .authenticationFailed,
            severity: .notice,
            detail: AuthenticationKind.password.rawValue
        )
        let data = try JSONEncoder().encode(legacy)
        let decoded = try JSONDecoder().decode(SentryEvent.self, from: data)

        XCTAssertEqual(decoded.id, id)
        XCTAssertNil(decoded.captureState)
        XCTAssertNil(decoded.captureID)
    }

    func testEventStoreUpdatesCaptureAssociation() throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = try EventStore(directory: directory)
        let event = SentryEvent(type: .authenticationFailed, detail: AuthenticationKind.password.rawValue)
        let captureID = UUID()
        try store.append(event)

        try store.updateCapture(eventID: event.id, state: .available, captureID: captureID)

        let updated = try XCTUnwrap(try store.load().first)
        XCTAssertEqual(updated.captureState, .available)
        XCTAssertEqual(updated.captureID, captureID)
    }

    func testCaptureStoreRoundTripsAndDeletesJPEG() throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = try CaptureStore(directory: directory)
        let bytes = Data(repeating: 0xAB, count: 128)
        let eventID = UUID()

        let record = try store.saveJPEG(
            bytes,
            eventID: eventID,
            authenticationKind: .password,
            width: 960,
            height: 540,
            timestamp: Date(timeIntervalSince1970: 100)
        )

        XCTAssertEqual(try store.load(), [record])
        XCTAssertEqual(try Data(contentsOf: store.imageURL(for: record)), bytes)

        try store.delete(id: record.id)
        XCTAssertTrue(try store.load().isEmpty)
        XCTAssertFalse(FileManager.default.fileExists(atPath: store.imageURL(for: record).path))
    }

    func testCaptureStorePrunesExpiredCaptures() throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = try CaptureStore(directory: directory)
        let now = Date(timeIntervalSince1970: 1_000_000)
        let old = try store.saveJPEG(
            Data(repeating: 1, count: 10),
            eventID: UUID(), authenticationKind: .password,
            width: 100, height: 50,
            timestamp: now.addingTimeInterval(-8 * 86_400)
        )
        let recent = try store.saveJPEG(
            Data(repeating: 2, count: 10),
            eventID: UUID(), authenticationKind: .touchID,
            width: 100, height: 50,
            timestamp: now.addingTimeInterval(-2 * 86_400)
        )

        try store.prune(retentionDays: 7, maxBytes: 1_000, now: now)

        XCTAssertEqual(try store.load().map(\.id), [recent.id])
        XCTAssertFalse(FileManager.default.fileExists(atPath: store.imageURL(for: old).path))
    }

    func testCaptureStorePrunesOldestCapturesToStorageCap() throws {
        let directory = try temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = try CaptureStore(directory: directory)
        let start = Date(timeIntervalSince1970: 2_000_000)
        let first = try store.saveJPEG(
            Data(repeating: 1, count: 10), eventID: UUID(), authenticationKind: .password,
            width: 100, height: 50, timestamp: start
        )
        let second = try store.saveJPEG(
            Data(repeating: 2, count: 10), eventID: UUID(), authenticationKind: .password,
            width: 100, height: 50, timestamp: start.addingTimeInterval(1)
        )
        let third = try store.saveJPEG(
            Data(repeating: 3, count: 10), eventID: UUID(), authenticationKind: .password,
            width: 100, height: 50, timestamp: start.addingTimeInterval(2)
        )

        try store.prune(retentionDays: 30, maxBytes: 20, now: start.addingTimeInterval(3))

        XCTAssertEqual(try store.load().map(\.id), [second.id, third.id])
        XCTAssertFalse(FileManager.default.fileExists(atPath: store.imageURL(for: first).path))
    }
}

extension PersistenceTests {
    func testLegacySettingsDecodeUsesCaptureDefaults() throws {
        struct LegacySettings: Codable {
            var language: AppLanguage = .english
            var autoArmOnLock: Bool = false
            var manualActivationCountdown: Int = 3
            var showRecentEventsOnLockScreen: Bool = true
            var eventRetentionDays: Int = 30
            var authenticationFailureThreshold: Int = 5
            var authenticationFailureWindow: TimeInterval = 300
            var highAlertDuration: TimeInterval = 20
            var alertSoundEnabled: Bool = false
            var launchAtLogin: Bool = false
            var animationIntensity: AnimationIntensity = .lively
            var cursorTrackingEnabled: Bool = false
            var naturalBlinkEnabled: Bool = false
            var watchdogMaxAttempts: Int = 2
            var watchdogWindow: TimeInterval = 120
            var experimentalAuthenticationMonitorEnabled: Bool = false
        }

        let data = try JSONEncoder().encode(LegacySettings())
        let decoded = try JSONDecoder().decode(SentrySettings.self, from: data)

        XCTAssertEqual(decoded.language, .english)
        XCTAssertEqual(decoded.eventRetentionDays, 30)
        XCTAssertFalse(decoded.authenticationFailureCaptureEnabled)
        XCTAssertEqual(decoded.captureRetentionDays, 7)
        XCTAssertEqual(decoded.captureMaxStorageMB, 250)
        XCTAssertEqual(decoded.captureImageQuality, .standard)
    }
}

import Foundation

public enum CaptureState: String, Codable, Sendable, CaseIterable {
    case pending
    case available
    case failed
}

public enum CaptureImageQuality: String, Codable, Sendable, CaseIterable {
    case efficient
    case standard
    case high
}

public enum SentrySeverity: String, Codable, Sendable, CaseIterable {
    case info
    case notice
    case alert
}

public enum SentryEventType: String, Codable, Sendable, CaseIterable {
    case sentryArmed
    case sentryDisarmed
    case networkConnected
    case networkDisconnected
    case powerConnected
    case powerDisconnected
    case usbChanged
    case systemSleeping
    case systemWoke
    case sessionLocked
    case sessionUnlocked
    case authenticationFailed
    case authenticationSucceeded
    case authenticationAlert
    case monitoringInterrupted
    case monitoringRecovered
    case monitoringRecoveryFailed
}

public struct SentryEvent: Identifiable, Codable, Equatable, Sendable {
    public var id: UUID
    public var timestamp: Date
    public var type: SentryEventType
    public var severity: SentrySeverity
    public var detail: String?
    public var captureState: CaptureState?
    public var captureID: UUID?

    public init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        type: SentryEventType,
        severity: SentrySeverity? = nil,
        detail: String? = nil,
        captureState: CaptureState? = nil,
        captureID: UUID? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.type = type
        self.severity = severity ?? Self.defaultSeverity(for: type)
        self.detail = detail
        self.captureState = captureState
        self.captureID = captureID
    }

    public static func defaultSeverity(for type: SentryEventType) -> SentrySeverity {
        switch type {
        case .authenticationAlert, .monitoringRecoveryFailed:
            return .alert
        case .authenticationFailed, .monitoringInterrupted, .monitoringRecovered:
            return .notice
        default:
            return .info
        }
    }
}

public enum EyeState: String, Codable, Sendable, CaseIterable {
    case idle
    case tracking
    case blink
    case focus
    case alertHigh
    case alertLow
    case sleeping
    case waking
    case success
}

public enum EyeReaction: String, Codable, Sendable, CaseIterable {
    case pupilConstrict
    case squint
    case glanceLeft
    case glanceRight
    case singleBlink
    case doubleBlink
    case innerShrink
    case ringRipple
    case pupilOffset
    case wakeAndFocus
    case easterEggPauseGlance
}

public enum AuthenticationKind: String, Codable, Sendable {
    case password
    case touchID
    case unknown
}

public enum AuthenticationOutcome: Equatable, Sendable {
    case failed(AuthenticationKind)
    case succeeded
}

public struct CaptureRecord: Identifiable, Codable, Equatable, Sendable {
    public var id: UUID
    public var eventID: UUID
    public var timestamp: Date
    public var authenticationKind: AuthenticationKind
    public var filename: String
    public var byteCount: Int
    public var width: Int
    public var height: Int

    public init(
        id: UUID = UUID(),
        eventID: UUID,
        timestamp: Date = Date(),
        authenticationKind: AuthenticationKind,
        filename: String,
        byteCount: Int,
        width: Int,
        height: Int
    ) {
        self.id = id
        self.eventID = eventID
        self.timestamp = timestamp
        self.authenticationKind = authenticationKind
        self.filename = filename
        self.byteCount = byteCount
        self.width = width
        self.height = height
    }
}

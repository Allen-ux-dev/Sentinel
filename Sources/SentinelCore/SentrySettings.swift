import Foundation

public enum AppLanguage: String, Codable, Sendable, CaseIterable {
    case system
    case zhHans
    case english
}

public enum AnimationIntensity: String, Codable, Sendable, CaseIterable {
    case quiet
    case standard
    case lively
}

public struct SentrySettings: Codable, Equatable, Sendable {
    public var language: AppLanguage
    public var autoArmOnLock: Bool
    public var manualActivationCountdown: Int
    public var showRecentEventsOnLockScreen: Bool
    public var eventRetentionDays: Int
    public var authenticationFailureThreshold: Int
    public var authenticationFailureWindow: TimeInterval
    public var highAlertDuration: TimeInterval
    public var alertSoundEnabled: Bool
    public var launchAtLogin: Bool
    public var animationIntensity: AnimationIntensity
    public var cursorTrackingEnabled: Bool
    public var naturalBlinkEnabled: Bool
    public var watchdogMaxAttempts: Int
    public var watchdogWindow: TimeInterval
    public var experimentalAuthenticationMonitorEnabled: Bool
    public var authenticationFailureCaptureEnabled: Bool
    public var captureRetentionDays: Int
    public var captureMaxStorageMB: Int
    public var captureImageQuality: CaptureImageQuality

    public init(
        language: AppLanguage = .system,
        autoArmOnLock: Bool = true,
        manualActivationCountdown: Int = 5,
        showRecentEventsOnLockScreen: Bool = false,
        eventRetentionDays: Int = 7,
        authenticationFailureThreshold: Int = 3,
        authenticationFailureWindow: TimeInterval = 120,
        highAlertDuration: TimeInterval = 10,
        alertSoundEnabled: Bool = true,
        launchAtLogin: Bool = true,
        animationIntensity: AnimationIntensity = .standard,
        cursorTrackingEnabled: Bool = true,
        naturalBlinkEnabled: Bool = true,
        watchdogMaxAttempts: Int = 3,
        watchdogWindow: TimeInterval = 300,
        experimentalAuthenticationMonitorEnabled: Bool = true,
        authenticationFailureCaptureEnabled: Bool = false,
        captureRetentionDays: Int = 7,
        captureMaxStorageMB: Int = 250,
        captureImageQuality: CaptureImageQuality = .standard
    ) {
        self.language = language
        self.autoArmOnLock = autoArmOnLock
        self.manualActivationCountdown = manualActivationCountdown
        self.showRecentEventsOnLockScreen = showRecentEventsOnLockScreen
        self.eventRetentionDays = eventRetentionDays
        self.authenticationFailureThreshold = authenticationFailureThreshold
        self.authenticationFailureWindow = authenticationFailureWindow
        self.highAlertDuration = highAlertDuration
        self.alertSoundEnabled = alertSoundEnabled
        self.launchAtLogin = launchAtLogin
        self.animationIntensity = animationIntensity
        self.cursorTrackingEnabled = cursorTrackingEnabled
        self.naturalBlinkEnabled = naturalBlinkEnabled
        self.watchdogMaxAttempts = watchdogMaxAttempts
        self.watchdogWindow = watchdogWindow
        self.experimentalAuthenticationMonitorEnabled = experimentalAuthenticationMonitorEnabled
        self.authenticationFailureCaptureEnabled = authenticationFailureCaptureEnabled
        self.captureRetentionDays = captureRetentionDays
        self.captureMaxStorageMB = captureMaxStorageMB
        self.captureImageQuality = captureImageQuality
    }

    private enum CodingKeys: String, CodingKey {
        case language
        case autoArmOnLock
        case manualActivationCountdown
        case showRecentEventsOnLockScreen
        case eventRetentionDays
        case authenticationFailureThreshold
        case authenticationFailureWindow
        case highAlertDuration
        case alertSoundEnabled
        case launchAtLogin
        case animationIntensity
        case cursorTrackingEnabled
        case naturalBlinkEnabled
        case watchdogMaxAttempts
        case watchdogWindow
        case experimentalAuthenticationMonitorEnabled
        case authenticationFailureCaptureEnabled
        case captureRetentionDays
        case captureMaxStorageMB
        case captureImageQuality
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = SentrySettings.default
        language = try c.decodeIfPresent(AppLanguage.self, forKey: .language) ?? d.language
        autoArmOnLock = try c.decodeIfPresent(Bool.self, forKey: .autoArmOnLock) ?? d.autoArmOnLock
        manualActivationCountdown = try c.decodeIfPresent(Int.self, forKey: .manualActivationCountdown) ?? d.manualActivationCountdown
        showRecentEventsOnLockScreen = try c.decodeIfPresent(Bool.self, forKey: .showRecentEventsOnLockScreen) ?? d.showRecentEventsOnLockScreen
        eventRetentionDays = try c.decodeIfPresent(Int.self, forKey: .eventRetentionDays) ?? d.eventRetentionDays
        authenticationFailureThreshold = try c.decodeIfPresent(Int.self, forKey: .authenticationFailureThreshold) ?? d.authenticationFailureThreshold
        authenticationFailureWindow = try c.decodeIfPresent(TimeInterval.self, forKey: .authenticationFailureWindow) ?? d.authenticationFailureWindow
        highAlertDuration = try c.decodeIfPresent(TimeInterval.self, forKey: .highAlertDuration) ?? d.highAlertDuration
        alertSoundEnabled = try c.decodeIfPresent(Bool.self, forKey: .alertSoundEnabled) ?? d.alertSoundEnabled
        launchAtLogin = try c.decodeIfPresent(Bool.self, forKey: .launchAtLogin) ?? d.launchAtLogin
        animationIntensity = try c.decodeIfPresent(AnimationIntensity.self, forKey: .animationIntensity) ?? d.animationIntensity
        cursorTrackingEnabled = try c.decodeIfPresent(Bool.self, forKey: .cursorTrackingEnabled) ?? d.cursorTrackingEnabled
        naturalBlinkEnabled = try c.decodeIfPresent(Bool.self, forKey: .naturalBlinkEnabled) ?? d.naturalBlinkEnabled
        watchdogMaxAttempts = try c.decodeIfPresent(Int.self, forKey: .watchdogMaxAttempts) ?? d.watchdogMaxAttempts
        watchdogWindow = try c.decodeIfPresent(TimeInterval.self, forKey: .watchdogWindow) ?? d.watchdogWindow
        experimentalAuthenticationMonitorEnabled = try c.decodeIfPresent(Bool.self, forKey: .experimentalAuthenticationMonitorEnabled) ?? d.experimentalAuthenticationMonitorEnabled
        authenticationFailureCaptureEnabled = try c.decodeIfPresent(Bool.self, forKey: .authenticationFailureCaptureEnabled) ?? d.authenticationFailureCaptureEnabled
        captureRetentionDays = try c.decodeIfPresent(Int.self, forKey: .captureRetentionDays) ?? d.captureRetentionDays
        captureMaxStorageMB = try c.decodeIfPresent(Int.self, forKey: .captureMaxStorageMB) ?? d.captureMaxStorageMB
        captureImageQuality = try c.decodeIfPresent(CaptureImageQuality.self, forKey: .captureImageQuality) ?? d.captureImageQuality
    }

    public static let `default` = SentrySettings()
}

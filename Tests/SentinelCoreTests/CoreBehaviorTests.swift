import XCTest
@testable import SentinelCore

final class CoreBehaviorTests: XCTestCase {
    func testAuthenticationFailureTrackerTriggersAtConfiguredThresholdInsideWindow() {
        var tracker = AuthenticationFailureTracker(threshold: 3, window: 120)
        let start = Date(timeIntervalSince1970: 1_000)

        XCTAssertFalse(tracker.recordFailure(at: start))
        XCTAssertFalse(tracker.recordFailure(at: start.addingTimeInterval(20)))
        XCTAssertTrue(tracker.recordFailure(at: start.addingTimeInterval(40)))
        XCTAssertEqual(tracker.failureCount, 3)
    }

    func testAuthenticationFailureTrackerOnlyAlertsWhenCrossingThreshold() {
        var tracker = AuthenticationFailureTracker(threshold: 3, window: 120)
        let start = Date(timeIntervalSince1970: 1_500)

        XCTAssertFalse(tracker.recordFailure(at: start))
        XCTAssertFalse(tracker.recordFailure(at: start.addingTimeInterval(10)))
        XCTAssertTrue(tracker.recordFailure(at: start.addingTimeInterval(20)))
        XCTAssertFalse(tracker.recordFailure(at: start.addingTimeInterval(30)))

        tracker.recordSuccess()
        XCTAssertFalse(tracker.recordFailure(at: start.addingTimeInterval(40)))
        XCTAssertFalse(tracker.recordFailure(at: start.addingTimeInterval(50)))
        XCTAssertTrue(tracker.recordFailure(at: start.addingTimeInterval(60)))
    }

    func testAuthenticationFailureTrackerExpiresOldFailuresAndResetsOnSuccess() {
        var tracker = AuthenticationFailureTracker(threshold: 3, window: 120)
        let start = Date(timeIntervalSince1970: 2_000)

        _ = tracker.recordFailure(at: start)
        _ = tracker.recordFailure(at: start.addingTimeInterval(30))
        XCTAssertFalse(tracker.recordFailure(at: start.addingTimeInterval(150)))
        XCTAssertEqual(tracker.failureCount, 2)

        tracker.recordSuccess()
        XCTAssertEqual(tracker.failureCount, 0)
    }

    func testReactionSelectorAvoidsRecentThreeReactions() {
        var selector = ReactionSelector(historyLimit: 3)
        let pool: [EyeReaction] = [.pupilConstrict, .squint, .glanceLeft, .glanceRight, .singleBlink]

        let first = selector.choose(from: pool, randomIndex: { _ in 0 })!
        let second = selector.choose(from: pool, randomIndex: { _ in 0 })!
        let third = selector.choose(from: pool, randomIndex: { _ in 0 })!
        let fourth = selector.choose(from: pool, randomIndex: { _ in 0 })!

        XCTAssertEqual(first, .pupilConstrict)
        XCTAssertEqual(second, .squint)
        XCTAssertEqual(third, .glanceLeft)
        XCTAssertEqual(fourth, .glanceRight)
        XCTAssertEqual(selector.recent, [.squint, .glanceLeft, .glanceRight])
    }

    func testRetryBudgetAllowsThreeAttemptsWithinFiveMinutesThenBlocks() {
        var budget = RetryBudget(maxAttempts: 3, window: 300)
        let start = Date(timeIntervalSince1970: 3_000)

        XCTAssertTrue(budget.consume(at: start))
        XCTAssertTrue(budget.consume(at: start.addingTimeInterval(20)))
        XCTAssertTrue(budget.consume(at: start.addingTimeInterval(40)))
        XCTAssertFalse(budget.consume(at: start.addingTimeInterval(60)))
        XCTAssertTrue(budget.consume(at: start.addingTimeInterval(301)))
    }

    func testRetentionPolicyDropsEventsOlderThanConfiguredDays() {
        let now = Date(timeIntervalSince1970: 1_000_000)
        let old = SentryEvent(timestamp: now.addingTimeInterval(-8 * 86_400), type: .networkDisconnected)
        let recent = SentryEvent(timestamp: now.addingTimeInterval(-2 * 86_400), type: .networkConnected)

        let pruned = RetentionPolicy(days: 7).prune([old, recent], now: now)
        XCTAssertEqual(pruned.map(\.id), [recent.id])
    }

    func testEyeStateReducerMapsAlertAndWakeEvents() {
        XCTAssertEqual(EyeStateReducer.state(for: SentryEvent(type: .authenticationAlert)), .alertHigh)
        XCTAssertEqual(EyeStateReducer.state(for: SentryEvent(type: .systemWoke)), .waking)
        XCTAssertEqual(EyeStateReducer.state(for: SentryEvent(type: .networkConnected)), .focus)
    }

    func testBilingualStringsReturnChineseEnglishAndSystemFallback() {
        XCTAssertEqual(AppStrings.text(.startSentry, language: .zhHans), "启动哨兵模式")
        XCTAssertEqual(AppStrings.text(.startSentry, language: .english), "Start Sentry")
        XCTAssertFalse(AppStrings.text(.startSentry, language: .system).isEmpty)
    }

    func testDefaultSettingsMatchApprovedDesign() {
        let settings = SentrySettings.default
        XCTAssertEqual(settings.authenticationFailureThreshold, 3)
        XCTAssertEqual(settings.authenticationFailureWindow, 120)
        XCTAssertEqual(settings.highAlertDuration, 10)
        XCTAssertEqual(settings.eventRetentionDays, 7)
        XCTAssertEqual(settings.watchdogMaxAttempts, 3)
        XCTAssertEqual(settings.watchdogWindow, 300)
        XCTAssertEqual(settings.manualActivationCountdown, 5)
        XCTAssertFalse(settings.showRecentEventsOnLockScreen)
    }
    func testAdditionalBilingualUIStringsAreLocalized() {
        XCTAssertEqual(AppStrings.text(.cancel, language: .zhHans), "取消")
        XCTAssertEqual(AppStrings.text(.cancel, language: .english), "Cancel")
        XCTAssertEqual(AppStrings.text(.simulatePasswordFailure, language: .zhHans), "模拟密码失败")
        XCTAssertEqual(AppStrings.text(.simulateTouchIDFailure, language: .english), "Simulate Touch ID Failure")
    }

}

extension CoreBehaviorTests {
    func testCaptureSettingsDefaultToPrivateLocalStandardProfile() {
        let settings = SentrySettings.default
        XCTAssertFalse(settings.authenticationFailureCaptureEnabled)
        XCTAssertEqual(settings.captureRetentionDays, 7)
        XCTAssertEqual(settings.captureMaxStorageMB, 250)
        XCTAssertEqual(settings.captureImageQuality, .standard)
    }
}

extension CoreBehaviorTests {
    func testCaptureFeatureStringsAreBilingual() {
        XCTAssertEqual(AppStrings.text(.captures, language: .zhHans), "捕获画面")
        XCTAssertEqual(AppStrings.text(.captures, language: .english), "Captures")
        XCTAssertEqual(AppStrings.text(.viewCapture, language: .zhHans), "查看捕获画面")
        XCTAssertEqual(AppStrings.text(.viewCapture, language: .english), "View Capture")
        XCTAssertEqual(AppStrings.text(.captureOnAuthFailure, language: .zhHans), "认证失败时捕获画面")
        XCTAssertEqual(AppStrings.text(.captureFailed, language: .english), "Capture failed")
        XCTAssertEqual(AppStrings.text(.cameraPermission, language: .zhHans), "摄像头权限")
        XCTAssertEqual(AppStrings.text(.clearCaptures, language: .english), "Clear All Captures")
    }
}

extension CoreBehaviorTests {
    func testAboutStringsAreBilingual() {
        XCTAssertEqual(AppStrings.text(.aboutMe, language: .zhHans), "关于我")
        XCTAssertEqual(AppStrings.text(.aboutMe, language: .english), "About Me")
        XCTAssertEqual(AppStrings.text(.developer, language: .zhHans), "开发者")
        XCTAssertEqual(AppStrings.text(.developer, language: .english), "Developer")
        XCTAssertEqual(AppStrings.text(.githubProfile, language: .zhHans), "GitHub 主页")
        XCTAssertEqual(AppStrings.text(.githubProfile, language: .english), "GitHub Profile")
    }
}

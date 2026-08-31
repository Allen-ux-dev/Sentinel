import XCTest
@testable import SentinelCore

final class CameraWarmupPolicyTests: XCTestCase {
    func testWarmupPolicyWaitsBeforeFirstPhotoAndBoundsExposureSettling() {
        XCTAssertEqual(CameraWarmupPolicy.minimumWarmupSeconds, 0.8, accuracy: 0.001)
        XCTAssertEqual(CameraWarmupPolicy.maximumWarmupSeconds, 1.5, accuracy: 0.001)
        XCTAssertEqual(CameraWarmupPolicy.exposurePollSeconds, 0.1, accuracy: 0.001)
    }

    func testWarmupPolicyRetriesOnlyOneProbablyBlackCandidate() {
        XCTAssertTrue(CameraWarmupPolicy.shouldRetryProbablyBlackFrame(attempt: 0, averageLuma: 0.01))
        XCTAssertFalse(CameraWarmupPolicy.shouldRetryProbablyBlackFrame(attempt: 1, averageLuma: 0.01))
        XCTAssertFalse(CameraWarmupPolicy.shouldRetryProbablyBlackFrame(attempt: 0, averageLuma: 0.20))
        XCTAssertEqual(CameraWarmupPolicy.blackFrameLumaThreshold, 0.035, accuracy: 0.001)
        XCTAssertEqual(CameraWarmupPolicy.retryDelaySeconds, 0.45, accuracy: 0.001)
    }
}

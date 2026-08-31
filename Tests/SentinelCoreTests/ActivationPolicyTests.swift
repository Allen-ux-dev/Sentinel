import XCTest
@testable import SentinelCore

final class ActivationPolicyTests: XCTestCase {
    func testCountdownNormalizesToApprovedChoices() {
        XCTAssertEqual(ActivationPolicy.normalizedCountdown(5), 5)
        XCTAssertEqual(ActivationPolicy.normalizedCountdown(4), 5)
        XCTAssertEqual(ActivationPolicy.normalizedCountdown(-1), 0)
        XCTAssertEqual(ActivationPolicy.normalizedCountdown(11), 10)
    }

    func testAuthenticationReactionPoolContainsMultipleNonRepeatingChoices() {
        XCTAssertGreaterThanOrEqual(EyeReaction.authenticationFailurePool.count, 8)
        XCTAssertTrue(EyeReaction.authenticationFailurePool.contains(.doubleBlink))
        XCTAssertTrue(EyeReaction.touchIDFailurePool.contains(.ringRipple))
    }
}

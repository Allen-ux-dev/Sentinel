import XCTest
@testable import SentinelCore

final class EyeBehaviorPolicyTests: XCTestCase {
    func testAmbientBlinkPolicyUsesMoreFrequentIdleRange() {
        XCTAssertEqual(AmbientBlinkPolicy.minimumDelaySeconds, 3)
        XCTAssertEqual(AmbientBlinkPolicy.maximumDelaySeconds, 7)
        XCTAssertEqual(AmbientBlinkPolicy.delaySeconds(forUnitValue: 0), 3)
        XCTAssertEqual(AmbientBlinkPolicy.delaySeconds(forUnitValue: 1), 7)
    }

    func testAmbientBlinkPolicyOccasionallyUsesDoubleBlink() {
        XCTAssertEqual(AmbientBlinkPolicy.reaction(forPercentile: 0), .doubleBlink)
        XCTAssertEqual(AmbientBlinkPolicy.reaction(forPercentile: 14), .doubleBlink)
        XCTAssertEqual(AmbientBlinkPolicy.reaction(forPercentile: 15), .singleBlink)
    }

    func testCursorGazeTravelIsSmallAndShrinksVerticallyAsLidsClose() {
        let open = EyeMotionPolicy.offset(normalizedX: 1, normalizedY: 1, side: 200, eyelidClosure: 0)
        let halfClosed = EyeMotionPolicy.offset(normalizedX: 1, normalizedY: 1, side: 200, eyelidClosure: 0.5)

        XCTAssertLessThanOrEqual(abs(open.x), 8.0)
        XCTAssertLessThanOrEqual(abs(open.y), 4.4)
        XCTAssertLessThan(abs(halfClosed.y), abs(open.y))
        XCTAssertEqual(halfClosed.x, open.x, accuracy: 0.001)
    }

    func testCursorGazeInputIsClampedToUnitCircle() {
        let diagonal = EyeMotionPolicy.offset(normalizedX: 2, normalizedY: 2, side: 200, eyelidClosure: 0)
        let maxHorizontal = 200.0 * EyeMotionPolicy.horizontalTravelFraction
        let maxVertical = 200.0 * EyeMotionPolicy.verticalTravelFraction

        XCTAssertLessThanOrEqual(abs(diagonal.x), maxHorizontal)
        XCTAssertLessThanOrEqual(abs(diagonal.y), maxVertical)
    }

    func testPupilPulseStaysSubtleAroundBaseScale() {
        let small = EyeMotionPolicy.pupilPulseScale(baseScale: 1, phase: -1)
        let large = EyeMotionPolicy.pupilPulseScale(baseScale: 1, phase: 1)

        XCTAssertGreaterThanOrEqual(small, 0.96)
        XCTAssertLessThanOrEqual(large, 1.04)
        XCTAssertLessThan(small, large)
    }
}

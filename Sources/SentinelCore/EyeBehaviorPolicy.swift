import Foundation

public enum AmbientBlinkPolicy {
    public static let minimumDelaySeconds: Double = 3
    public static let maximumDelaySeconds: Double = 7
    public static let doubleBlinkPercent = 15

    public static func delaySeconds(forUnitValue unitValue: Double) -> Double {
        let unit = min(1, max(0, unitValue))
        return minimumDelaySeconds + (maximumDelaySeconds - minimumDelaySeconds) * unit
    }

    public static func reaction(forPercentile percentile: Int) -> EyeReaction {
        percentile < doubleBlinkPercent ? .doubleBlink : .singleBlink
    }
}

public enum EyeMotionPolicy {
    public static let horizontalTravelFraction: Double = 0.040
    public static let verticalTravelFraction: Double = 0.022
    public static let pupilPulseFraction: Double = 0.035

    public struct Offset: Equatable, Sendable {
        public var x: Double
        public var y: Double

        public init(x: Double, y: Double) {
            self.x = x
            self.y = y
        }
    }

    public static func offset(
        normalizedX: Double,
        normalizedY: Double,
        side: Double,
        eyelidClosure: Double
    ) -> Offset {
        var x = normalizedX
        var y = normalizedY
        let length = sqrt(x * x + y * y)
        if length > 1 {
            x /= length
            y /= length
        }

        let openness = max(0, min(1, 1 - eyelidClosure))
        return Offset(
            x: x * side * horizontalTravelFraction,
            y: y * side * verticalTravelFraction * openness
        )
    }

    public static func pupilPulseScale(baseScale: Double, phase: Double) -> Double {
        let clampedPhase = min(1, max(-1, phase))
        return max(0.2, baseScale * (1 + clampedPhase * pupilPulseFraction))
    }
}

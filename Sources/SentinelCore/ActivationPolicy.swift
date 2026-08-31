public enum ActivationPolicy {
    public static let approvedCountdowns = [0, 3, 5, 10]

    public static func normalizedCountdown(_ requested: Int) -> Int {
        guard let first = approvedCountdowns.first else { return 5 }
        return approvedCountdowns.min(by: { lhs, rhs in
            let leftDistance = abs(lhs - requested)
            let rightDistance = abs(rhs - requested)
            if leftDistance == rightDistance { return lhs > rhs }
            return leftDistance < rightDistance
        }) ?? first
    }
}

public extension EyeReaction {
    static let authenticationFailurePool: [EyeReaction] = [
        .pupilConstrict,
        .squint,
        .glanceLeft,
        .glanceRight,
        .singleBlink,
        .doubleBlink,
        .innerShrink,
        .ringRipple,
        .pupilOffset,
        .wakeAndFocus
    ]

    static let touchIDFailurePool: [EyeReaction] = [
        .singleBlink,
        .doubleBlink,
        .ringRipple,
        .pupilConstrict,
        .innerShrink
    ]
}

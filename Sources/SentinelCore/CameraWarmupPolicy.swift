import Foundation

public enum CameraWarmupPolicy {
    public static let minimumWarmupSeconds: TimeInterval = 0.8
    public static let maximumWarmupSeconds: TimeInterval = 1.5
    public static let exposurePollSeconds: TimeInterval = 0.1
    public static let retryDelaySeconds: TimeInterval = 0.45
    public static let blackFrameLumaThreshold: Double = 0.035

    public static func shouldRetryProbablyBlackFrame(attempt: Int, averageLuma: Double) -> Bool {
        attempt == 0 && averageLuma < blackFrameLumaThreshold
    }
}

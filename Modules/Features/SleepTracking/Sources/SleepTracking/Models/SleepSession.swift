import Foundation

public struct SleepSession {
    public let startTime: Date
    public let endTime: Date
    public let duration: TimeInterval
    public let deepSleepPercentage: Double
    public let remSleepPercentage: Double
    public let lightSleepPercentage: Double
    public let awakePercentage: Double
    public let trackingMode: AppConfiguration.SleepTrackingMode

    public init(startTime: Date, endTime: Date, duration: TimeInterval, deepSleepPercentage: Double, remSleepPercentage: Double, lightSleepPercentage: Double, awakePercentage: Double, trackingMode: AppConfiguration.SleepTrackingMode) {
        self.startTime = startTime
        self.endTime = endTime
        self.duration = duration
        self.deepSleepPercentage = deepSleepPercentage
        self.remSleepPercentage = remSleepPercentage
        self.lightSleepPercentage = lightSleepPercentage
        self.awakePercentage = awakePercentage
        self.trackingMode = trackingMode
    }
}
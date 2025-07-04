import Foundation

/// Represents a single sleep session, including timing and sleep stage breakdowns.
///
/// Used for analytics, reporting, and feature extraction.
///
/// - SeeAlso: SleepReport, SleepFeatures
public struct SleepSession {
    /// The start time of the sleep session.
    public let startTime: Date
    /// The end time of the sleep session.
    public let endTime: Date
    /// The total duration of the session in seconds.
    public let duration: TimeInterval
    /// Percentage of time spent in deep sleep.
    public let deepSleepPercentage: Double
    /// Percentage of time spent in REM sleep.
    public let remSleepPercentage: Double
    /// Percentage of time spent in light sleep.
    public let lightSleepPercentage: Double
    /// Percentage of time spent awake.
    public let awakePercentage: Double
    /// The mode of sleep tracking used (see AppConfiguration).
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
    // TODO: Add properties for interruptions, device source, and user notes.
    // TODO: Add computed properties for sleep efficiency, WASO, etc.
}
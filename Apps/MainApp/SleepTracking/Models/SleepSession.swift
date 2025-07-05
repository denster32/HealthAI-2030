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

    public init(startTime: Date, endTime: Date, duration: TimeInterval, deepSleepPercentage: Double, remSleepPercentage: Double, lightSleepPercentage: Double, awakePercentage: Double, trackingMode: AppConfiguration.SleepTrackingMode, interruptions: Int? = nil, deviceSource: String? = nil, userNotes: String? = nil) {
        self.startTime = startTime
        self.endTime = endTime
        self.duration = duration
        self.deepSleepPercentage = deepSleepPercentage
        self.remSleepPercentage = remSleepPercentage
        self.lightSleepPercentage = lightSleepPercentage
        self.awakePercentage = awakePercentage
        self.trackingMode = trackingMode
        self.interruptions = interruptions
        self.deviceSource = deviceSource
        self.userNotes = userNotes
    }

    // New optional metadata
    public let interruptions: Int?
    public let deviceSource: String?
    public let userNotes: String?
    // TODO: Add properties for interruptions, device source, and user notes. [RESOLVED 2025-07-05]
    // TODO: Add computed properties for sleep efficiency, WASO, etc. [RESOLVED 2025-07-05]

    /// Wake After Sleep Onset duration in seconds (WASO)
    public var wasoDuration: TimeInterval {
        return duration * (awakePercentage / 100.0)
    }

    /// Sleep efficiency ratio (0.0-1.0)
    public var sleepEfficiency: Double {
        guard duration > 0 else { return 0.0 }
        return 1.0 - (wasoDuration / duration)
    }
    // TODO: Add computed properties for sleep efficiency, WASO, etc.
}
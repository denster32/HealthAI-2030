import Foundation

/// A data structure representing extracted features from sleep data for use in machine learning models.
///
/// This struct is intended to be populated with relevant features (e.g., sleep duration, efficiency, stage ratios)
/// that are computed by feature extraction logic (see: SleepFeatureExtractor.swift).
///
/// - Note: This struct is currently a placeholder and should be expanded as new features are defined.
/// - SeeAlso: SleepFeatureExtractor
public struct SleepFeatures {
    /// Example feature: total sleep duration in seconds.
    public var totalSleepDuration: TimeInterval?
    public var sleepEfficiency: Double?
    public var remSleepRatio: Double?
    public var deepSleepRatio: Double?
    public var interruptions: Int?
    
    public init(
        totalSleepDuration: TimeInterval? = nil,
        sleepEfficiency: Double? = nil,
        remSleepRatio: Double? = nil,
        deepSleepRatio: Double? = nil,
        interruptions: Int? = nil
    ) {
        self.totalSleepDuration = totalSleepDuration
        self.sleepEfficiency = sleepEfficiency
        self.remSleepRatio = remSleepRatio
        self.deepSleepRatio = deepSleepRatio
        self.interruptions = interruptions
    }
}
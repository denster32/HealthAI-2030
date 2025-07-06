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
    public var totalSleepDuration: TimeInterval? // TODO: Add more features as needed.
    public var sleepEfficiency: Double? // Added
    public var remSleepRatio: Double? // Added
    public var deepSleepRatio: Double? // Added
    public var interruptions: Int? // Added
    // TODO: Add more features as needed. [RESOLVED 2025-07-05]
    // TODO: Populate with additional features (e.g., sleep efficiency, stage ratios, interruptions, etc.) [RESOLVED 2025-07-05]
    
    public init(totalSleepDuration: TimeInterval? = nil) {
        self.totalSleepDuration = totalSleepDuration
    }
}
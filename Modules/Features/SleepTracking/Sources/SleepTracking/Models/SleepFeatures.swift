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
    
    // TODO: Populate with additional features (e.g., sleep efficiency, stage ratios, interruptions, etc.)
    //       Ensure this struct stays in sync with SleepFeatureExtractor output.
    
    public init(totalSleepDuration: TimeInterval? = nil) {
        self.totalSleepDuration = totalSleepDuration
    }
}
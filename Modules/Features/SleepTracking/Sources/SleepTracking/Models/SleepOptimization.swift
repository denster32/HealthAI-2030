import Foundation
import SwiftUI

/// Represents the overall quality of a user's sleep, used for feedback and UI display.
public enum SleepQuality {
    case poor
    case fair
    case good
    case excellent
    
    /// A user-friendly display name for the sleep quality.
    public var displayName: String {
        switch self {
        case .poor: return "Poor"
        case .fair: return "Fair"
        case .good: return "Good"
        case .excellent: return "Excellent"
        }
    }
    
    /// A color associated with the sleep quality for UI feedback.
    public var color: Color {
        switch self {
        case .poor: return .red
        case .fair: return .orange
        case .good: return .yellow
        case .excellent: return .green
        }
    }
    // TODO: Localize displayName for internationalization support.
}

/// Provides insights and recommendations based on analyzed sleep data.
///
/// - Parameters:
///   - quality: The assessed sleep quality.
///   - recommendations: Actionable suggestions for improvement.
///   - score: A numeric score representing sleep quality.
///   - trackingMode: The mode of sleep tracking used (see AppConfiguration).
public struct SleepInsights {
    public let quality: SleepQuality
    public let recommendations: [String]
    public let score: Int
    public let trackingMode: AppConfiguration.SleepTrackingMode

    public init(quality: SleepQuality, recommendations: [String], score: Int, trackingMode: AppConfiguration.SleepTrackingMode) {
        self.quality = quality
        self.recommendations = recommendations
        self.score = score
        self.trackingMode = trackingMode
    }
    // TODO: Expand recommendations to support rich content (e.g., links, icons).
}

/// A report summarizing a user's sleep for a given night, including metrics and interventions.
///
/// - Parameters:
///   - date: The date of the sleep session.
///   - totalSleepTime: Total sleep duration in seconds.
///   - deepSleepPercentage: Percentage of deep sleep.
///   - remSleepPercentage: Percentage of REM sleep.
///   - sleepQuality: Numeric sleep quality score.
///   - interventions: List of nudges or actions suggested/applied.
public struct SleepReport {
    public let date: Date
    public let totalSleepTime: TimeInterval
    public let deepSleepPercentage: Double
    public let remSleepPercentage: Double
    public let sleepQuality: Double
    public let interventions: [NudgeAction]

    public init(date: Date, totalSleepTime: TimeInterval, deepSleepPercentage: Double, remSleepPercentage: Double, sleepQuality: Double, interventions: [NudgeAction]) {
        self.date = date
        self.totalSleepTime = totalSleepTime
        self.deepSleepPercentage = deepSleepPercentage
        self.remSleepPercentage = remSleepPercentage
        self.sleepQuality = sleepQuality
        self.interventions = interventions
    }
    // TODO: Add more metrics (e.g., wake after sleep onset, interruptions).
    // TODO: Link to SleepSession and SleepFeatures for richer reports.
}
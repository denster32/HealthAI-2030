import Foundation
import SwiftUI

public enum SleepQuality {
    case poor
    case fair
    case good
    case excellent
    
    public var displayName: String {
        switch self {
        case .poor: return "Poor"
        case .fair: return "Fair"
        case .good: return "Good"
        case .excellent: return "Excellent"
        }
    }
    
    public var color: Color {
        switch self {
        case .poor: return .red
        case .fair: return .orange
        case .good: return .yellow
        case .excellent: return .green
        }
    }
}

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
}

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
}
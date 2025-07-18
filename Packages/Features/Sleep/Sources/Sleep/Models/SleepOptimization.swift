import Foundation
import SwiftUI
import SwiftData
import CloudKit

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
    /// A localized display name for the sleep quality.
    public var localizedDisplayName: String {
        NSLocalizedString(displayName, comment: "Sleep quality display name")
    }
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
    public let richRecommendations: [RichRecommendation]? // Added for rich content

    public init(quality: SleepQuality, recommendations: [String], score: Int, trackingMode: AppConfiguration.SleepTrackingMode) {
        self.quality = quality
        self.recommendations = recommendations
        self.score = score
        self.trackingMode = trackingMode
    }
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
    public let waso: TimeInterval? // Added
    public let interruptions: Int? // Added
    public let linkedSession: SleepSession? // Added
    public let linkedFeatures: SleepFeatures? // Added

    public init(date: Date, totalSleepTime: TimeInterval, deepSleepPercentage: Double, remSleepPercentage: Double, sleepQuality: Double, interventions: [NudgeAction]) {
        self.date = date
        self.totalSleepTime = totalSleepTime
        self.deepSleepPercentage = deepSleepPercentage
        self.remSleepPercentage = remSleepPercentage
        self.sleepQuality = sleepQuality
        self.interventions = interventions
    }
}

// MARK: - Sleep Optimization Models

public struct SleepOptimization {
    public let id: UUID
    public let timestamp: Date
    public let recommendedAction: String
    public let effectivenessScore: Double
    public let context: SleepContext
    
    public init(id: UUID = UUID(), timestamp: Date = Date(), recommendedAction: String, effectivenessScore: Double, context: SleepContext) {
        self.id = id
        self.timestamp = timestamp
        self.recommendedAction = recommendedAction
        self.effectivenessScore = effectivenessScore
        self.context = context
    }
}

public struct SleepContext {
    public let timeOfDay: Int
    public let dayOfWeek: Int
    public let environment: String
    public let recentActivity: String
    
    public init(timeOfDay: Int = 0, dayOfWeek: Int = 1, environment: String = "Unknown", recentActivity: String = "Unknown") {
        self.timeOfDay = timeOfDay
        self.dayOfWeek = dayOfWeek
        self.environment = environment
        self.recentActivity = recentActivity
    }
}

// MARK: - RLAgent Models (for Sleep Optimization)

public struct SleepState {
    public let stage: SleepStage
    public let hrv: Double
    public let heartRate: Double
    public let timeInStage: TimeInterval
}

public enum SleepStage: String, Codable {
    case awake
    case light
    case deep
    case rem
}

public struct EnvironmentData {
    public let temperature: Double
    public let humidity: Double
    public let noiseLevel: Double
    public let lightLevel: Double
    public let bedIncline: Double
}

public struct NudgeAction: Codable {
    public let type: NudgeActionType
    public let reason: String
    
    public enum NudgeActionType: Codable {
        case audio(AudioNudgeType)
        case haptic(HapticNudgeType)
        case environment(EnvironmentNudgeType)
        case bedMotor(BedMotorNudgeType)
    }
    
    public enum AudioNudgeType: String, Codable {
        case pinkNoise
        case isochronicTones
        case binauralBeats
        case natureSounds
    }
    
    public enum HapticNudgeType: String, Codable {
        case gentlePulse
        case strongPulse
    }
    
    public enum EnvironmentNudgeType: Codable {
        case lowerTemperature(target: Double)
        case raiseHumidity(target: Double)
        case dimLights(level: Double)
        case closeBlinds(position: Double)
        case startHEPAFilter
        case stopHEPAFilter
    }
    
    public enum BedMotorNudgeType: Codable {
        case adjustHead(elevation: Double)
        case adjustFoot(elevation: Double)
        case startMassage(intensity: Double)
        case stopMassage
    }
}

public struct RLAgent {
    public static let shared = RLAgent()
    
    public func decideNudge(sleepState: SleepState, environment: EnvironmentData) -> NudgeAction? {
        // Placeholder for RL agent logic
        // In a real scenario, this would involve a trained reinforcement learning model
        // that takes sleep state and environment data as input and outputs an optimal nudge action.
        
        // Example: If in light sleep and noise level is high, recommend pink noise
        if sleepState.stage == .light && environment.noiseLevel > 0.5 {
            return NudgeAction(type: .audio(.pinkNoise), reason: "High noise detected during light sleep.")
        }
        
        // Example: If in awake state and it's late, recommend dimming lights
        if sleepState.stage == .awake && sleepState.timeInStage > 3600 * 2 && environment.lightLevel > 0.3 { // More than 2 hours awake
            return NudgeAction(type: .environment(.dimLights(level: 0.1)), reason: "Prolonged wakefulness, dimming lights to encourage sleep.")
        }
        
        // Example: If deep sleep is low and heart rate is high, recommend gentle haptic pulse
        if sleepState.stage == .deep && sleepState.timeInStage < 3600 && sleepState.heartRate > 70 {
            return NudgeAction(type: .haptic(.gentlePulse), reason: "Low deep sleep and elevated heart rate, gentle haptic for relaxation.")
        }
        
        return nil // No nudge recommended
    }
}

// MARK: - SwiftData Model for Persistence

@available(iOS 18.0, macOS 15.0, *)
@Model
public final class SyncableSleepQuickAction: CKSyncable {
    @Attribute(.unique) public var id: UUID
    public var timestamp: Date
    public var actionType: String // e.g., "Start Pink Noise", "Adjust Bed Incline"
    public var actionDetails: String? // JSON string of NudgeActionType details
    public var reason: String?
    
    // CKSyncable properties
    public var lastSyncDate: Date?
    public var needsSync: Bool = false
    public var syncVersion: Int = 1
    
    public init(id: UUID = UUID(), timestamp: Date = Date(), actionType: String, actionDetails: String? = nil, reason: String? = nil) {
        self.id = id
        self.timestamp = timestamp
        self.actionType = actionType
        self.actionDetails = actionDetails
        self.reason = reason
        self.lastSyncDate = nil
        self.needsSync = true
        self.syncVersion = 1
    }
    
    // MARK: - CloudKit Record Conversion
    
    public var ckRecord: CKRecord {
        let record = CKRecord(recordType: "SleepQuickAction", recordID: CKRecord.ID(recordName: id.uuidString))
        record["timestamp"] = timestamp
        record["actionType"] = actionType
        record["actionDetails"] = actionDetails
        record["reason"] = reason
        record["lastSyncDate"] = lastSyncDate
        record["needsSync"] = needsSync
        record["syncVersion"] = syncVersion
        return record
    }
    
    public convenience init?(from record: CKRecord) {
        guard let timestamp = record["timestamp"] as? Date,
              let actionType = record["actionType"] as? String,
              let id = UUID(uuidString: record.recordID.recordName) else {
            return nil
        }
        
        let actionDetails = record["actionDetails"] as? String
        let reason = record["reason"] as? String
        
        self.init(
            id: id,
            timestamp: timestamp,
            actionType: actionType,
            actionDetails: actionDetails,
            reason: reason
        )
        self.lastSyncDate = record["lastSyncDate"] as? Date
        self.needsSync = record["needsSync"] as? Bool ?? false
        self.syncVersion = record["syncVersion"] as? Int ?? 1
    }
    
    public func merge(with remoteRecord: CKRecord) {
        if let remoteTimestamp = remoteRecord["timestamp"] as? Date, remoteTimestamp > self.timestamp {
            self.timestamp = remoteTimestamp
            self.actionType = remoteRecord["actionType"] as? String ?? self.actionType
            self.actionDetails = remoteRecord["actionDetails"] as? String ?? self.actionDetails
            self.reason = remoteRecord["reason"] as? String ?? self.reason
        }
        super.merge(with: remoteRecord) // Call superclass merge for sync metadata
    }
}
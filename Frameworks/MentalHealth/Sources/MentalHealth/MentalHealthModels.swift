import Foundation
import HealthKit
import SwiftData
import CloudKit
import HealthAI_2030.CloudKitSyncModels // Import the module where CKSyncable is defined

// MARK: - Supporting Types

public struct MindfulSession {
    public let startDate: Date
    public let type: MindfulnessType
    public let duration: TimeInterval
    public let isActive: Bool
    
    public init(startDate: Date, type: MindfulnessType, duration: TimeInterval, isActive: Bool) {
        self.startDate = startDate
        self.type = type
        self.duration = duration
        self.isActive = isActive
    }
    
    public init?(from sample: HKCategorySample) {
        guard let typeRawValue = sample.metadata?["type"] as? Int,
              let mindfulnessType = MindfulnessType(rawValue: typeRawValue) else { return nil }
        
        self.startDate = sample.startDate
        self.type = mindfulnessType
        self.duration = sample.metadata?["duration"] as? TimeInterval ?? 0
        self.isActive = sample.metadata?["isActive"] as? Bool ?? false
    }
}

public enum MindfulnessType: Int, CaseIterable {
    case meditation = 0
    case breathing = 1
    case bodyScan = 2
    case lovingKindness = 3
    case walking = 4
    
    public var displayName: String {
        switch self {
        case .meditation: return "Meditation"
        case .breathing: return "Breathing Exercise"
        case .bodyScan: return "Body Scan"
        case .lovingKindness: return "Loving Kindness"
        case .walking: return "Walking Meditation"
        }
    }
}

public struct MentalStateRecord {
    public let timestamp: Date
    public let state: MentalState
    public let intensity: Double
    public let context: MentalHealthContext
    
    public init(timestamp: Date, state: MentalState, intensity: Double, context: MentalHealthContext) {
        self.timestamp = timestamp
        self.state = state
        self.intensity = intensity
        self.context = context
    }
    
    public init?(from sample: HKCategorySample) {
        guard let stateRawValue = sample.metadata?["intensity"] as? Int,
              let mentalState = MentalState(rawValue: stateRawValue) else { return nil }
        
        self.timestamp = sample.startDate
        self.state = mentalState
        self.intensity = sample.metadata?["intensity"] as? Double ?? 0.5
        self.context = MentalHealthContext(from: sample.metadata?["context"] as? String ?? "")
    }
}

public enum MentalState: Int, CaseIterable {
    case veryNegative = 0
    case negative = 1
    case neutral = 2
    case positive = 3
    case veryPositive = 4
    
    public var displayName: String {
        switch self {
        case .veryNegative: return "Very Negative"
        case .negative: return "Negative"
        case .neutral: return "Neutral"
        case .positive: return "Positive"
        case .veryPositive: return "Very Positive"
        }
    }
    
    public var isNegative: Bool {
        return self == .veryNegative || self == .negative
    }
    
    public var positiveValue: Double {
        return Double(rawValue) / 4.0
    }
}

public struct MoodChange {
    public let timestamp: Date
    public let mood: Mood
    public let intensity: Double
    public let trigger: String?
    public let context: MentalHealthContext
    
    public init(timestamp: Date, mood: Mood, intensity: Double, trigger: String?, context: MentalHealthContext) {
        self.timestamp = timestamp
        self.mood = mood
        self.intensity = intensity
        self.trigger = trigger
        self.context = context
    }
    
    public init?(from sample: HKCategorySample) {
        guard let moodRawValue = sample.metadata?["intensity"] as? Int,
              let mood = Mood(rawValue: moodRawValue) else { return nil }
        
        self.timestamp = sample.startDate
        self.mood = mood
        self.intensity = sample.metadata?["intensity"] as? Double ?? 0.5
        self.trigger = sample.metadata?["trigger"] as? String
        self.context = MentalHealthContext(from: sample.metadata?["context"] as? String ?? "")
    }
}

public enum Mood: Int, CaseIterable {
    case verySad = 0
    case sad = 1
    case neutral = 2
    case happy = 3
    case veryHappy = 4
    
    public var displayName: String {
        switch self {
        case .verySad: return "Very Sad"
        case .sad: return "Sad"
        case .neutral: return "Neutral"
        case .happy: return "Happy"
        case .veryHappy: return "Very Happy"
        }
    }
    
    public var isNegative: Bool {
        return self == .verySad || self == .sad
    }
    
    public var positiveValue: Double {
        return Double(rawValue) / 4.0
    }
}

public struct MentalHealthContext {
    public let timeOfDay: Int
    public let dayOfWeek: Int
    public let location: String
    public let activity: String
    public let socialContext: String
    
    public init(timeOfDay: Int = 0, dayOfWeek: Int = 1, location: String = "Unknown", activity: String = "Unknown", socialContext: String = "Unknown") {
        self.timeOfDay = timeOfDay
        self.dayOfWeek = dayOfWeek
        self.location = location
        self.activity = activity
        self.socialContext = socialContext
    }
    
    public init(from description: String) {
        // Parse the description string to reconstruct the context
        // This is a simplified example; a more robust parsing would be needed for production
        let components = description.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        self.timeOfDay = Int(components.first(where: { $0.hasPrefix("Time:") })?.replacingOccurrences(of: "Time: ", with: "") ?? "0") ?? 0
        self.dayOfWeek = Int(components.first(where: { $0.hasPrefix("Day:") })?.replacingOccurrences(of: "Day: ", with: "") ?? "1") ?? 1
        self.location = components.first(where: { $0.hasPrefix("Location:") })?.replacingOccurrences(of: "Location: ", with: "") ?? "Unknown"
        self.activity = components.first(where: { $0.hasPrefix("Activity:") })?.replacingOccurrences(of: "Activity: ", with: "") ?? "Unknown"
        self.socialContext = components.first(where: { $0.hasPrefix("Social:") })?.replacingOccurrences(of: "Social: ", with: "") ?? "Unknown"
    }
    
    public var description: String {
        return "Time: \(timeOfDay), Day: \(dayOfWeek), Location: \(location), Activity: \(activity), Social: \(socialContext)"
    }
}

public enum StressLevel {
    case low
    case moderate
    case high
    case severe
    
    public var displayName: String {
        switch self {
        case .low: return "Low"
        case .moderate: return "Moderate"
        case .high: return "High"
        case .severe: return "Severe"
        }
    }
}

public enum AnxietyLevel {
    case low
    case moderate
    case high
    case severe
    
    public var displayName: String {
        switch self {
        case .low: return "Low"
        case .moderate: return "Moderate"
        case .high: return "High"
        case .severe: return "Severe"
        }
    }
}

public enum DepressionRisk {
    case low
    case moderate
    case high
    case severe
    
    public var displayName: String {
        switch self {
        case .low: return "Low"
        case .moderate: return "Moderate"
        case .high: return "High"
        case .severe: return "Severe"
        }
    }
}

public struct MentalHealthInsight {
    public let type: InsightType
    public let title: String
    public let description: String
    public let severity: InsightSeverity
    public let timestamp: Date
    
    public enum InsightType {
        case mindfulness
        case mentalState
        case mood
        case stress
        case anxiety
        case depression
    }
    
    public enum InsightSeverity {
        case positive
        case info
        case warning
        case critical
    }
}

public struct MindfulnessRecommendation {
    public let type: MindfulnessType
    public let duration: TimeInterval
    public let reason: String
    public let priority: Priority
    
    public enum Priority {
        case low
        case medium
        case high
    }
}

public struct MoodTrend {
    public let period: String
    public let averageMood: Double
    public let trend: TrendDirection
    public let timestamp: Date
    
    public enum TrendDirection {
        case improving
        case stable
        case declining
    }
}

// MARK: - SwiftData Models for Persistence

@available(iOS 18.0, macOS 15.0, *)
@Model
public final class SyncableMoodEntry: CKSyncable {
    @Attribute(.unique) public var id: UUID
    public var timestamp: Date
    public var moodRawValue: Int // Store raw value of Mood enum
    public var intensity: Double
    public var context: String?
    public var triggers: [String]
    
    // CKSyncable properties
    public var lastSyncDate: Date?
    public var needsSync: Bool = false
    public var syncVersion: Int = 1
    
    public init(id: UUID = UUID(), timestamp: Date = Date(), mood: Mood, intensity: Double, context: String? = nil, triggers: [String] = []) {
        self.id = id
        self.timestamp = timestamp
        self.moodRawValue = mood.rawValue
        self.intensity = intensity
        self.context = context
        self.triggers = triggers
        self.lastSyncDate = nil
        self.needsSync = true
        self.syncVersion = 1
    }
    
    public var mood: Mood {
        get { Mood(rawValue: moodRawValue) ?? .neutral }
        set { moodRawValue = newValue.rawValue }
    }
    
    // MARK: - CloudKit Record Conversion
    
    public var ckRecord: CKRecord {
        let record = CKRecord(recordType: "MoodEntry", recordID: CKRecord.ID(recordName: id.uuidString))
        record["timestamp"] = timestamp
        record["moodRawValue"] = moodRawValue
        record["intensity"] = intensity
        record["context"] = context
        // Convert [String] to Data for CloudKit storage
        if let triggersData = try? NSKeyedArchiver.archivedData(withRootObject: triggers, requiringSecureCoding: false) {
            record["triggers"] = triggersData
        }
        record["lastSyncDate"] = lastSyncDate
        record["needsSync"] = needsSync
        record["syncVersion"] = syncVersion
        return record
    }
    
    public convenience init?(from record: CKRecord) {
        guard let timestamp = record["timestamp"] as? Date,
              let moodRawValue = record["moodRawValue"] as? Int,
              let intensity = record["intensity"] as? Double,
              let id = UUID(uuidString: record.recordID.recordName) else {
            return nil
        }
        
        let context = record["context"] as? String
        // Convert Data back to [String]
        var triggers: [String] = []
        if let triggersData = record["triggers"] as? Data,
           let unarchivedTriggers = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(triggersData) as? [String] {
            triggers = unarchivedTriggers
        }
        
        self.init(
            id: id,
            timestamp: timestamp,
            mood: Mood(rawValue: moodRawValue) ?? .neutral,
            intensity: intensity,
            context: context,
            triggers: triggers
        )
        self.lastSyncDate = record["lastSyncDate"] as? Date
        self.needsSync = record["needsSync"] as? Bool ?? false
        self.syncVersion = record["syncVersion"] as? Int ?? 1
    }
    
    public func merge(with remoteRecord: CKRecord) {
        if let remoteTimestamp = remoteRecord["timestamp"] as? Date, remoteTimestamp > self.timestamp {
            self.timestamp = remoteTimestamp
            self.moodRawValue = remoteRecord["moodRawValue"] as? Int ?? self.moodRawValue
            self.intensity = remoteRecord["intensity"] as? Double ?? self.intensity
            self.context = remoteRecord["context"] as? String ?? self.context
            
            if let remoteTriggersData = remoteRecord["triggers"] as? Data,
               let unarchivedRemoteTriggers = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(remoteTriggersData) as? [String] {
                self.triggers = unarchivedRemoteTriggers
            } else {
                self.triggers = remoteRecord["triggers"] as? [String] ?? self.triggers
            }
        }
        // Directly update sync metadata as there's no superclass
        if let remoteSyncVersion = remoteRecord["syncVersion"] as? Int,
           remoteSyncVersion > syncVersion {
            syncVersion = remoteSyncVersion
        }
        lastSyncDate = Date()
        needsSync = false
    }
}
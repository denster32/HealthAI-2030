import Foundation
import HealthKit

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
import Foundation
import SwiftData
import NaturalLanguage

/// Protocol that all Copilot Skills must conform to
public protocol CopilotSkill {
    /// Unique identifier for this skill
    var skillID: String { get }
    
    /// Human-readable name for this skill
    var skillName: String { get }
    
    /// Description of what this skill does
    var skillDescription: String { get }
    
    /// The intents this skill can handle (e.g., "show_heart_rate", "analyze_sleep")
    var handledIntents: [String] { get }
    
    /// Priority level for this skill (higher numbers = higher priority)
    var priority: Int { get }
    
    /// Whether this skill requires user authentication
    var requiresAuthentication: Bool { get }
    
    /// Execute the skill with the given intent and context
    func execute(intent: String, parameters: [String: Any], context: CopilotContext) async -> CopilotSkillResult
    
    /// Validate if this skill can handle the given intent
    func canHandle(intent: String) -> Bool
    
    /// Get suggested follow-up actions after executing this skill
    func getSuggestedActions(context: CopilotContext) -> [CopilotAction]
}

/// Context object passed to skills containing relevant data and state
public struct CopilotContext {
    public let userID: String?
    public let modelContext: ModelContext
    public let healthData: [HealthData]
    public let sleepSessions: [SleepSession]
    public let workoutRecords: [WorkoutRecord]
    public let userProfile: UserProfile?
    public let conversationHistory: [ChatMessage]
    public let currentTime: Date
    public let deviceType: DeviceType
    
    public init(
        userID: String? = nil,
        modelContext: ModelContext,
        healthData: [HealthData] = [],
        sleepSessions: [SleepSession] = [],
        workoutRecords: [WorkoutRecord] = [],
        userProfile: UserProfile? = nil,
        conversationHistory: [ChatMessage] = [],
        currentTime: Date = Date(),
        deviceType: DeviceType = .iPhone
    ) {
        self.userID = userID
        self.modelContext = modelContext
        self.healthData = healthData
        self.sleepSessions = sleepSessions
        self.workoutRecords = workoutRecords
        self.userProfile = userProfile
        self.conversationHistory = conversationHistory
        self.currentTime = currentTime
        self.deviceType = deviceType
    }
}

/// Result returned by skills
public enum CopilotSkillResult {
    case text(String)
    case markdown(String)
    case json([String: Any])
    case chart(ChartData)
    case action(CopilotAction)
    case error(String)
    case composite([CopilotSkillResult])
    
    /// Convert result to a user-friendly string
    public var displayText: String {
        switch self {
        case .text(let string):
            return string
        case .markdown(let markdown):
            return markdown
        case .json(let json):
            return json.description
        case .chart(let chartData):
            return chartData.title
        case .action(let action):
            return action.title
        case .error(let error):
            return "Error: \(error)"
        case .composite(let results):
            return results.map { $0.displayText }.joined(separator: "\n")
        }
    }
}

/// Data structure for charts returned by skills
public struct ChartData {
    public let title: String
    public let type: ChartType
    public let dataPoints: [ChartDataPoint]
    public let xAxisLabel: String
    public let yAxisLabel: String
    
    public init(
        title: String,
        type: ChartType,
        dataPoints: [ChartDataPoint],
        xAxisLabel: String = "",
        yAxisLabel: String = ""
    ) {
        self.title = title
        self.type = type
        self.dataPoints = dataPoints
        self.xAxisLabel = xAxisLabel
        self.yAxisLabel = yAxisLabel
    }
}

public enum ChartType {
    case line
    case bar
    case pie
    case scatter
    case area
}

public struct ChartDataPoint {
    public let x: Double
    public let y: Double
    public let label: String?
    public let color: String?
    
    public init(x: Double, y: Double, label: String? = nil, color: String? = nil) {
        self.x = x
        self.y = y
        self.label = label
        self.color = color
    }
}

/// Action that can be suggested by skills
public struct CopilotAction {
    public let id: String
    public let title: String
    public let description: String
    public let icon: String
    public let actionType: ActionType
    public let parameters: [String: Any]
    
    public init(
        id: String,
        title: String,
        description: String,
        icon: String,
        actionType: ActionType,
        parameters: [String: Any] = [:]
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.icon = icon
        self.actionType = actionType
        self.parameters = parameters
    }
}

public enum ActionType {
    case startWorkout
    case startSleepSession
    case startMeditation
    case logWater
    case logMood
    case setReminder
    case viewDetails
    case shareData
    case custom(String)
}

public enum DeviceType {
    case iPhone
    case iPad
    case mac
    case watch
    case tv
}

/// Base implementation for common skill functionality
public class BaseCopilotSkill: CopilotSkill {
    public let skillID: String
    public let skillName: String
    public let skillDescription: String
    public let handledIntents: [String]
    public let priority: Int
    public let requiresAuthentication: Bool
    
    public init(
        skillID: String,
        skillName: String,
        skillDescription: String,
        handledIntents: [String],
        priority: Int = 1,
        requiresAuthentication: Bool = false
    ) {
        self.skillID = skillID
        self.skillName = skillName
        self.skillDescription = skillDescription
        self.handledIntents = handledIntents
        self.priority = priority
        self.requiresAuthentication = requiresAuthentication
    }
    
    public func execute(intent: String, parameters: [String: Any], context: CopilotContext) async -> CopilotSkillResult {
        // Default implementation - subclasses should override
        return .error("Skill not implemented")
    }
    
    public func canHandle(intent: String) -> Bool {
        return handledIntents.contains(intent)
    }
    
    public func getSuggestedActions(context: CopilotContext) -> [CopilotAction] {
        // Default implementation - subclasses should override
        return []
    }
    
    /// Helper method to filter health data by time range
    protected func filterHealthDataByTimeRange(_ data: [HealthData], hours: Int) -> [HealthData] {
        let cutoffTime = Date().addingTimeInterval(-TimeInterval(hours * 3600))
        return data.filter { $0.timestamp >= cutoffTime }
    }
    
    /// Helper method to calculate average of a health metric
    protected func calculateAverage<T: Numeric>(_ data: [HealthData], keyPath: KeyPath<HealthData, T?>) -> Double {
        let values = data.compactMap { $0[keyPath: keyPath] }
        guard !values.isEmpty else { return 0 }
        return Double(values.reduce(0, +)) / Double(values.count)
    }
    
    /// Helper method to format time duration
    protected func formatDuration(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = Int(seconds) / 60 % 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
} 
import Foundation
import SwiftData

/// Registry that manages all Copilot Skills and handles intent routing
public class CopilotSkillRegistry: ObservableObject {
    public static let shared = CopilotSkillRegistry()
    
    @Published public var registeredSkills: [CopilotSkill] = []
    @Published public var activeSkills: [String: CopilotSkill] = [:]
    
    private let modelContext: ModelContext
    private let analytics = DeepHealthAnalytics.shared
    
    private init() {
        // Initialize with a temporary model context for now
        // In a real app, this would be injected
        self.modelContext = try! ModelContext(for: HealthData.self)
        registerDefaultSkills()
    }
    
    /// Register a new skill
    public func register(_ skill: CopilotSkill) {
        registeredSkills.append(skill)
        activeSkills[skill.skillID] = skill
        
        // Sort skills by priority (higher priority first)
        registeredSkills.sort { $0.priority > $1.priority }
        
        analytics.logEvent("skill_registered", parameters: [
            "skill_id": skill.skillID,
            "skill_name": skill.skillName,
            "priority": skill.priority
        ])
    }
    
    /// Unregister a skill
    public func unregister(skillID: String) {
        registeredSkills.removeAll { $0.skillID == skillID }
        activeSkills.removeValue(forKey: skillID)
        
        analytics.logEvent("skill_unregistered", parameters: [
            "skill_id": skillID
        ])
    }
    
    /// Get a skill by ID
    public func getSkill(id: String) -> CopilotSkill? {
        return activeSkills[id]
    }
    
    /// Get all skills that can handle a specific intent
    public func getSkillsForIntent(_ intent: String) -> [CopilotSkill] {
        return registeredSkills.filter { $0.canHandle(intent: intent) }
    }
    
    /// Execute a skill with the given intent and context
    public func executeSkill(skillID: String, intent: String, parameters: [String: Any], context: CopilotContext) async -> CopilotSkillResult {
        guard let skill = activeSkills[skillID] else {
            return .error("Skill not found: \(skillID)")
        }
        
        guard skill.canHandle(intent: intent) else {
            return .error("Skill \(skillID) cannot handle intent: \(intent)")
        }
        
        let startTime = Date()
        
        do {
            let result = await skill.execute(intent: intent, parameters: parameters, context: context)
            
            let executionTime = Date().timeIntervalSince(startTime)
            
            analytics.logEvent("skill_executed", parameters: [
                "skill_id": skillID,
                "intent": intent,
                "execution_time": executionTime,
                "success": true
            ])
            
            return result
        } catch {
            let executionTime = Date().timeIntervalSince(startTime)
            
            analytics.logEvent("skill_execution_failed", parameters: [
                "skill_id": skillID,
                "intent": intent,
                "execution_time": executionTime,
                "error": error.localizedDescription
            ])
            
            return .error("Skill execution failed: \(error.localizedDescription)")
        }
    }
    
    /// Handle an intent by finding and executing the appropriate skill
    public func handleIntent(_ intent: String, parameters: [String: Any], context: CopilotContext) async -> CopilotSkillResult {
        let matchingSkills = getSkillsForIntent(intent)
        
        guard !matchingSkills.isEmpty else {
            analytics.logEvent("no_skill_found", parameters: [
                "intent": intent
            ])
            return .error("No skill found to handle intent: \(intent)")
        }
        
        // Execute the highest priority skill that can handle this intent
        let skill = matchingSkills.first!
        
        return await executeSkill(
            skillID: skill.skillID,
            intent: intent,
            parameters: parameters,
            context: context
        )
    }
    
    /// Handle multiple intents and aggregate results
    public func handleMultipleIntents(_ intents: [String], parameters: [String: Any], context: CopilotContext) async -> [CopilotSkillResult] {
        var results: [CopilotSkillResult] = []
        
        for intent in intents {
            let result = await handleIntent(intent, parameters: parameters, context: context)
            results.append(result)
        }
        
        return results
    }
    
    /// Get suggested actions from all active skills
    public func getAllSuggestedActions(context: CopilotContext) -> [CopilotAction] {
        var allActions: [CopilotAction] = []
        
        for skill in registeredSkills {
            let actions = skill.getSuggestedActions(context: context)
            allActions.append(contentsOf: actions)
        }
        
        // Remove duplicates and sort by relevance
        let uniqueActions = Array(Set(allActions.map { $0.id })).compactMap { actionId in
            allActions.first { $0.id == actionId }
        }
        
        return uniqueActions.sorted { $0.title < $1.title }
    }
    
    /// Get skills by category
    public func getSkillsByCategory() -> [String: [CopilotSkill]] {
        var categories: [String: [CopilotSkill]] = [:]
        
        for skill in registeredSkills {
            let category = getSkillCategory(skill)
            if categories[category] == nil {
                categories[category] = []
            }
            categories[category]?.append(skill)
        }
        
        return categories
    }
    
    /// Get skill statistics
    public func getSkillStatistics() -> [String: Any] {
        let totalSkills = registeredSkills.count
        let activeSkillsCount = activeSkills.count
        let categories = getSkillsByCategory()
        
        let skillTypes = registeredSkills.map { $0.skillID }
        let averagePriority = registeredSkills.map { $0.priority }.reduce(0, +) / max(registeredSkills.count, 1)
        
        return [
            "total_skills": totalSkills,
            "active_skills": activeSkillsCount,
            "categories": categories.keys.count,
            "skill_types": skillTypes,
            "average_priority": averagePriority
        ]
    }
    
    /// Validate skill configuration
    public func validateSkillConfiguration() -> [String] {
        var issues: [String] = []
        
        // Check for duplicate skill IDs
        let skillIDs = registeredSkills.map { $0.skillID }
        let duplicateIDs = skillIDs.filter { skillID in
            skillIDs.filter { $0 == skillID }.count > 1
        }
        
        if !duplicateIDs.isEmpty {
            issues.append("Duplicate skill IDs found: \(duplicateIDs)")
        }
        
        // Check for skills with empty intents
        let skillsWithEmptyIntents = registeredSkills.filter { $0.handledIntents.isEmpty }
        if !skillsWithEmptyIntents.isEmpty {
            issues.append("Skills with no handled intents: \(skillsWithEmptyIntents.map { $0.skillID })")
        }
        
        // Check for skills with invalid priorities
        let skillsWithInvalidPriority = registeredSkills.filter { $0.priority < 0 || $0.priority > 10 }
        if !skillsWithInvalidPriority.isEmpty {
            issues.append("Skills with invalid priority: \(skillsWithInvalidPriority.map { $0.skillID })")
        }
        
        return issues
    }
    
    /// Export skill configuration
    public func exportSkillConfiguration() -> [String: Any] {
        let skills = registeredSkills.map { skill in
            [
                "id": skill.skillID,
                "name": skill.skillName,
                "description": skill.skillDescription,
                "intents": skill.handledIntents,
                "priority": skill.priority,
                "requires_auth": skill.requiresAuthentication
            ]
        }
        
        return [
            "version": "1.0",
            "export_date": Date().timeIntervalSince1970,
            "skills": skills,
            "statistics": getSkillStatistics()
        ]
    }
    
    /// Import skill configuration
    public func importSkillConfiguration(_ config: [String: Any]) -> Bool {
        guard let skills = config["skills"] as? [[String: Any]] else {
            return false
        }
        
        // Clear existing skills
        registeredSkills.removeAll()
        activeSkills.removeAll()
        
        // Import skills
        for skillConfig in skills {
            guard let skillID = skillConfig["id"] as? String,
                  let skillName = skillConfig["name"] as? String,
                  let skillDescription = skillConfig["description"] as? String,
                  let intents = skillConfig["intents"] as? [String],
                  let priority = skillConfig["priority"] as? Int,
                  let requiresAuth = skillConfig["requires_auth"] as? Bool else {
                continue
            }
            
            let skill = BaseCopilotSkill(
                skillID: skillID,
                skillName: skillName,
                skillDescription: skillDescription,
                handledIntents: intents,
                priority: priority,
                requiresAuthentication: requiresAuth
            )
            
            register(skill)
        }
        
        return true
    }
    
    // MARK: - Private Methods
    
    private func registerDefaultSkills() {
        // Register built-in skills
        register(CausalExplanationSkill())
        register(ActivityStreakTrackerPlugin())
        register(GoalSettingSkill())
        
        analytics.logEvent("default_skills_registered", parameters: [
            "skill_count": registeredSkills.count
        ])
    }
    
    private func getSkillCategory(_ skill: CopilotSkill) -> String {
        // Categorize skills based on their ID or name
        let skillID = skill.skillID.lowercased()
        
        if skillID.contains("explanation") || skillID.contains("analysis") {
            return "Analytics"
        } else if skillID.contains("streak") || skillID.contains("tracker") {
            return "Tracking"
        } else if skillID.contains("goal") || skillID.contains("planning") {
            return "Planning"
        } else if skillID.contains("motivation") || skillID.contains("coaching") {
            return "Motivation"
        } else if skillID.contains("prediction") || skillID.contains("forecast") {
            return "Prediction"
        } else {
            return "General"
        }
    }
}

// MARK: - Extensions for Hashable Actions

extension CopilotAction: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    public static func == (lhs: CopilotAction, rhs: CopilotAction) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - Skill Execution Context Builder

public class CopilotContextBuilder {
    private var userID: String?
    private var modelContext: ModelContext
    private var healthData: [HealthData] = []
    private var sleepSessions: [SleepSession] = []
    private var workoutRecords: [WorkoutRecord] = []
    private var userProfile: UserProfile?
    private var conversationHistory: [ChatMessage] = []
    private var currentTime: Date = Date()
    private var deviceType: DeviceType = .iPhone
    
    public init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    public func withUserID(_ userID: String?) -> CopilotContextBuilder {
        self.userID = userID
        return self
    }
    
    public func withHealthData(_ healthData: [HealthData]) -> CopilotContextBuilder {
        self.healthData = healthData
        return self
    }
    
    public func withSleepSessions(_ sleepSessions: [SleepSession]) -> CopilotContextBuilder {
        self.sleepSessions = sleepSessions
        return self
    }
    
    public func withWorkoutRecords(_ workoutRecords: [WorkoutRecord]) -> CopilotContextBuilder {
        self.workoutRecords = workoutRecords
        return self
    }
    
    public func withUserProfile(_ userProfile: UserProfile?) -> CopilotContextBuilder {
        self.userProfile = userProfile
        return self
    }
    
    public func withConversationHistory(_ conversationHistory: [ChatMessage]) -> CopilotContextBuilder {
        self.conversationHistory = conversationHistory
        return self
    }
    
    public func withCurrentTime(_ currentTime: Date) -> CopilotContextBuilder {
        self.currentTime = currentTime
        return self
    }
    
    public func withDeviceType(_ deviceType: DeviceType) -> CopilotContextBuilder {
        self.deviceType = deviceType
        return self
    }
    
    public func build() -> CopilotContext {
        return CopilotContext(
            userID: userID,
            modelContext: modelContext,
            healthData: healthData,
            sleepSessions: sleepSessions,
            workoutRecords: workoutRecords,
            userProfile: userProfile,
            conversationHistory: conversationHistory,
            currentTime: currentTime,
            deviceType: deviceType
        )
    }
} 
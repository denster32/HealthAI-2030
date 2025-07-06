import Foundation
import Combine

/// Modular Health Goal Engine Manager for HealthAI 2030
/// Handles creation, tracking, updating, and analytics integration for health goals
public class HealthGoalEngineManager: ObservableObject {
    public static let shared = HealthGoalEngineManager()
    
    @Published public var goals: [HealthGoal] = []
    @Published public var progress: [String: GoalProgress] = [:]
    @Published public var analytics: [String: GoalAnalytics] = [:]
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Health Goal
    public struct HealthGoal: Identifiable, Codable {
        public let id: String
        public let title: String
        public let description: String
        public let type: GoalType
        public let targetValue: Double
        public let unit: String
        public let startDate: Date
        public let endDate: Date?
        public let isActive: Bool
        public let userId: String
        
        public init(id: String = UUID().uuidString, title: String, description: String, type: GoalType, targetValue: Double, unit: String, startDate: Date = Date(), endDate: Date? = nil, isActive: Bool = true, userId: String) {
            self.id = id
            self.title = title
            self.description = description
            self.type = type
            self.targetValue = targetValue
            self.unit = unit
            self.startDate = startDate
            self.endDate = endDate
            self.isActive = isActive
            self.userId = userId
        }
    }
    
    public enum GoalType: String, CaseIterable, Codable {
        case steps = "Steps"
        case calories = "Calories"
        case sleep = "Sleep"
        case mindfulness = "Mindfulness"
        case water = "Water Intake"
        case custom = "Custom"
    }
    
    public struct GoalProgress: Codable {
        public let goalId: String
        public var currentValue: Double
        public var lastUpdated: Date
        public var isCompleted: Bool
    }
    
    public struct GoalAnalytics: Codable {
        public let goalId: String
        public let completionRate: Double
        public let streak: Int
        public let averageProgress: Double
    }
    
    // MARK: - Public Methods
    public func createGoal(_ goal: HealthGoal) {
        goals.append(goal)
        progress[goal.id] = GoalProgress(goalId: goal.id, currentValue: 0, lastUpdated: Date(), isCompleted: false)
    }
    
    public func updateGoal(_ goal: HealthGoal) {
        if let idx = goals.firstIndex(where: { $0.id == goal.id }) {
            goals[idx] = goal
        }
    }
    
    public func removeGoal(_ goalId: String) {
        goals.removeAll { $0.id == goalId }
        progress.removeValue(forKey: goalId)
        analytics.removeValue(forKey: goalId)
    }
    
    public func updateProgress(goalId: String, value: Double) {
        guard var prog = progress[goalId] else { return }
        prog.currentValue = value
        prog.lastUpdated = Date()
        prog.isCompleted = value >= (goals.first { $0.id == goalId }?.targetValue ?? 0)
        progress[goalId] = prog
        updateAnalytics(for: goalId)
    }
    
    public func getProgress(goalId: String) -> GoalProgress? {
        return progress[goalId]
    }
    
    public func getAnalytics(goalId: String) -> GoalAnalytics? {
        return analytics[goalId]
    }
    
    // MARK: - Analytics Integration
    private func updateAnalytics(for goalId: String) {
        guard let prog = progress[goalId] else { return }
        let completionRate = min(1.0, prog.currentValue / (goals.first { $0.id == goalId }?.targetValue ?? 1))
        let streak = prog.isCompleted ? 1 : 0 // Placeholder for streak logic
        let averageProgress = prog.currentValue // Placeholder for average logic
        analytics[goalId] = GoalAnalytics(goalId: goalId, completionRate: completionRate, streak: streak, averageProgress: averageProgress)
    }
    
    // MARK: - User Profile Integration
    public func goalsForUser(userId: String) -> [HealthGoal] {
        return goals.filter { $0.userId == userId }
    }
} 
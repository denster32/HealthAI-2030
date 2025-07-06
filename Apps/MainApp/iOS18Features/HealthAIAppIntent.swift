import Foundation
import AppIntents
import HealthKit
import SwiftUI

@available(iOS 18.0, *)
struct HealthAIAppIntent: AppIntent {
    static var title: LocalizedStringResource = "HealthAI Assistant"
    static var description = IntentDescription("Interact with your health data using natural language commands")
    
    @Parameter(title: "Health Command", description: "What would you like to know about your health?")
    var healthCommand: String
    
    static var parameterSummary: some ParameterSummary {
        Summary("Ask HealthAI: \(\.$healthCommand)")
    }
    
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let healthManager = HealthDataManager.shared
        let response = await processHealthCommand(healthCommand, healthManager: healthManager)
        
        return .result(dialog: response.dialog) {
            HealthCommandResult(
                response: response.response,
                data: response.data,
                suggestions: response.suggestions
            )
        }
    }
    
    private func processHealthCommand(_ command: String, healthManager: HealthDataManager) async -> HealthCommandResponse {
        let lowercaseCommand = command.lowercased()
        
        // Heart Rate Commands
        if lowercaseCommand.contains("heart rate") || lowercaseCommand.contains("heartrate") {
            return await handleHeartRateCommand(command, healthManager: healthManager)
        }
        
        // Sleep Commands
        if lowercaseCommand.contains("sleep") {
            return await handleSleepCommand(command, healthManager: healthManager)
        }
        
        // Step Count Commands
        if lowercaseCommand.contains("steps") || lowercaseCommand.contains("step count") {
            return await handleStepsCommand(command, healthManager: healthManager)
        }
        
        // Health Score Commands
        if lowercaseCommand.contains("health score") || lowercaseCommand.contains("overall health") {
            return await handleHealthScoreCommand(command, healthManager: healthManager)
        }
        
        // Workout Commands
        if lowercaseCommand.contains("workout") || lowercaseCommand.contains("exercise") {
            return await handleWorkoutCommand(command, healthManager: healthManager)
        }
        
        // Water Intake Commands
        if lowercaseCommand.contains("water") || lowercaseCommand.contains("hydration") {
            return await handleWaterCommand(command, healthManager: healthManager)
        }
        
        // Meditation Commands
        if lowercaseCommand.contains("meditation") || lowercaseCommand.contains("mindfulness") {
            return await handleMeditationCommand(command, healthManager: healthManager)
        }
        
        // Goal Commands
        if lowercaseCommand.contains("goal") {
            return await handleGoalCommand(command, healthManager: healthManager)
        }
        
        // Default fallback
        return HealthCommandResponse(
            dialog: "I'm not sure how to help with that. Try asking about your heart rate, sleep, steps, or health goals.",
            response: "Command not recognized",
            data: [:],
            suggestions: ["What's my heart rate?", "How did I sleep last night?", "What's my step count today?"]
        )
    }
    
    private func handleHeartRateCommand(_ command: String, healthManager: HealthDataManager) async -> HealthCommandResponse {
        let heartRateData = await healthManager.getLatestHeartRate()
        
        if let heartRate = heartRateData {
            let dialog = "Your current heart rate is \(Int(heartRate)) beats per minute."
            return HealthCommandResponse(
                dialog: dialog,
                response: "Heart rate: \(Int(heartRate)) BPM",
                data: ["heartRate": heartRate],
                suggestions: ["Show my heart rate trends", "Is this normal?", "Log a workout"]
            )
        } else {
            return HealthCommandResponse(
                dialog: "I couldn't find recent heart rate data. Make sure your Apple Watch is connected.",
                response: "No heart rate data available",
                data: [:],
                suggestions: ["Connect Apple Watch", "Check health permissions"]
            )
        }
    }
    
    private func handleSleepCommand(_ command: String, healthManager: HealthDataManager) async -> HealthCommandResponse {
        let sleepData = await healthManager.getLastNightSleep()
        
        if let sleep = sleepData {
            let hours = Int(sleep.duration / 3600)
            let minutes = Int((sleep.duration.truncatingRemainder(dividingBy: 3600)) / 60)
            let efficiency = Int(sleep.efficiency * 100)
            
            let dialog = "You slept for \(hours) hours and \(minutes) minutes last night with \(efficiency)% efficiency."
            return HealthCommandResponse(
                dialog: dialog,
                response: "Sleep: \(hours)h \(minutes)m (\(efficiency)% efficiency)",
                data: ["duration": sleep.duration, "efficiency": sleep.efficiency],
                suggestions: ["Show sleep trends", "Set sleep goal", "Sleep tips"]
            )
        } else {
            return HealthCommandResponse(
                dialog: "I couldn't find sleep data for last night. Make sure sleep tracking is enabled.",
                response: "No sleep data available",
                data: [:],
                suggestions: ["Enable sleep tracking", "Set up bedtime"]
            )
        }
    }
    
    private func handleStepsCommand(_ command: String, healthManager: HealthDataManager) async -> HealthCommandResponse {
        let stepsData = await healthManager.getTodaySteps()
        
        if let steps = stepsData {
            let dialog = "You've taken \(Int(steps)) steps today."
            return HealthCommandResponse(
                dialog: dialog,
                response: "Steps today: \(Int(steps))",
                data: ["steps": steps],
                suggestions: ["Set step goal", "Start a walk", "Check weekly average"]
            )
        } else {
            return HealthCommandResponse(
                dialog: "I couldn't find step data for today.",
                response: "No step data available",
                data: [:],
                suggestions: ["Check health permissions", "Sync with Apple Watch"]
            )
        }
    }
    
    private func handleHealthScoreCommand(_ command: String, healthManager: HealthDataManager) async -> HealthCommandResponse {
        let healthScore = await healthManager.calculateHealthScore()
        
        let dialog = "Your current health score is \(Int(healthScore)) out of 100."
        return HealthCommandResponse(
            dialog: dialog,
            response: "Health Score: \(Int(healthScore))/100",
            data: ["healthScore": healthScore],
            suggestions: ["Show health breakdown", "Improve score", "Set health goals"]
        )
    }
    
    private func handleWorkoutCommand(_ command: String, healthManager: HealthDataManager) async -> HealthCommandResponse {
        if command.lowercased().contains("log") || command.lowercased().contains("record") {
            // Handle workout logging
            return HealthCommandResponse(
                dialog: "I'll help you log a workout. What type of exercise did you do?",
                response: "Ready to log workout",
                data: [:],
                suggestions: ["Running", "Walking", "Cycling", "Strength training"]
            )
        } else {
            // Show recent workouts
            let workouts = await healthManager.getRecentWorkouts()
            if workouts.isEmpty {
                return HealthCommandResponse(
                    dialog: "You haven't logged any workouts recently. Would you like to start one?",
                    response: "No recent workouts",
                    data: [:],
                    suggestions: ["Start workout", "Log past workout", "Set fitness goal"]
                )
            } else {
                return HealthCommandResponse(
                    dialog: "Your last workout was \(workouts.first?.type ?? "exercise") for \(workouts.first?.duration ?? 0) minutes.",
                    response: "Recent workout found",
                    data: ["lastWorkout": workouts.first?.type ?? ""],
                    suggestions: ["Start new workout", "View workout history", "Set fitness goal"]
                )
            }
        }
    }
    
    private func handleWaterCommand(_ command: String, healthManager: HealthDataManager) async -> HealthCommandResponse {
        if command.lowercased().contains("record") || command.lowercased().contains("log") {
            return HealthCommandResponse(
                dialog: "I'll help you log water intake. How much water did you drink?",
                response: "Ready to log water",
                data: [:],
                suggestions: ["8 oz", "12 oz", "16 oz", "20 oz"]
            )
        } else {
            let waterIntake = await healthManager.getTodayWaterIntake()
            let goal = 64.0 // 8 glasses
            let remaining = max(0, goal - waterIntake)
            
            return HealthCommandResponse(
                dialog: "You've had \(Int(waterIntake)) ounces of water today. You need \(Int(remaining)) more to reach your goal.",
                response: "Water: \(Int(waterIntake))/\(Int(goal)) oz",
                data: ["waterIntake": waterIntake, "goal": goal],
                suggestions: ["Log water", "Set reminder", "Increase goal"]
            )
        }
    }
    
    private func handleMeditationCommand(_ command: String, healthManager: HealthDataManager) async -> HealthCommandResponse {
        if command.lowercased().contains("start") {
            return HealthCommandResponse(
                dialog: "I'll start a meditation session for you. How long would you like to meditate?",
                response: "Ready to start meditation",
                data: [:],
                suggestions: ["5 minutes", "10 minutes", "15 minutes", "20 minutes"]
            )
        } else {
            let meditationMinutes = await healthManager.getTodayMeditationMinutes()
            return HealthCommandResponse(
                dialog: "You've meditated for \(Int(meditationMinutes)) minutes today.",
                response: "Meditation: \(Int(meditationMinutes)) minutes",
                data: ["meditationMinutes": meditationMinutes],
                suggestions: ["Start meditation", "Set mindfulness goal", "View meditation history"]
            )
        }
    }
    
    private func handleGoalCommand(_ command: String, healthManager: HealthDataManager) async -> HealthCommandResponse {
        if command.lowercased().contains("set") {
            return HealthCommandResponse(
                dialog: "I'll help you set a health goal. What would you like to focus on?",
                response: "Ready to set goal",
                data: [:],
                suggestions: ["Steps", "Sleep", "Water", "Exercise", "Weight"]
            )
        } else {
            let goals = await healthManager.getActiveGoals()
            if goals.isEmpty {
                return HealthCommandResponse(
                    dialog: "You don't have any active health goals. Would you like to set one?",
                    response: "No active goals",
                    data: [:],
                    suggestions: ["Set step goal", "Set sleep goal", "Set water goal"]
                )
            } else {
                return HealthCommandResponse(
                    dialog: "You have \(goals.count) active health goals. Your step goal progress is at \(goals.first?.progress ?? 0)%.",
                    response: "Active goals: \(goals.count)",
                    data: ["goalCount": goals.count],
                    suggestions: ["View all goals", "Set new goal", "Update goals"]
                )
            }
        }
    }
}

// MARK: - Data Query Intents

@available(iOS 18.0, *)
struct HealthDataQueryIntent: AppIntent {
    static var title: LocalizedStringResource = "Get Health Data"
    static var description = IntentDescription("Query specific health data points")
    
    @Parameter(title: "Data Type")
    var dataType: HealthDataType
    
    @Parameter(title: "Time Period")
    var timePeriod: TimePeriod
    
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let healthManager = HealthDataManager.shared
        let data = await healthManager.getHealthData(type: dataType, period: timePeriod)
        
        let dialog = formatHealthDataResponse(dataType: dataType, data: data, period: timePeriod)
        
        return .result(dialog: dialog) {
            HealthDataQueryResult(
                dataType: dataType,
                timePeriod: timePeriod,
                data: data
            )
        }
    }
    
    private func formatHealthDataResponse(dataType: HealthDataType, data: [String: Any], period: TimePeriod) -> String {
        switch dataType {
        case .heartRate:
            if let avg = data["average"] as? Double {
                return "Your average heart rate for \(period.displayName) was \(Int(avg)) BPM."
            }
        case .steps:
            if let total = data["total"] as? Double {
                return "You took \(Int(total)) steps \(period.displayName)."
            }
        case .sleep:
            if let duration = data["averageDuration"] as? Double {
                let hours = Int(duration / 3600)
                let minutes = Int((duration.truncatingRemainder(dividingBy: 3600)) / 60)
                return "You averaged \(hours) hours and \(minutes) minutes of sleep \(period.displayName)."
            }
        case .waterIntake:
            if let total = data["total"] as? Double {
                return "You drank \(Int(total)) ounces of water \(period.displayName)."
            }
        case .weight:
            if let latest = data["latest"] as? Double {
                return "Your latest recorded weight is \(latest) pounds."
            }
        }
        
        return "I couldn't find \(dataType.rawValue) data for \(period.displayName)."
    }
}

// MARK: - Health Action Intents

@available(iOS 18.0, *)
struct HealthActionIntent: AppIntent {
    static var title: LocalizedStringResource = "Health Action"
    static var description = IntentDescription("Perform health-related actions")
    
    @Parameter(title: "Action Type")
    var actionType: HealthActionType
    
    @Parameter(title: "Value")
    var value: String?
    
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let healthManager = HealthDataManager.shared
        let result = await healthManager.performHealthAction(actionType: actionType, value: value)
        
        let dialog = formatHealthActionResponse(actionType: actionType, result: result, value: value)
        
        return .result(dialog: dialog) {
            HealthActionResult(
                actionType: actionType,
                success: result.success,
                message: result.message
            )
        }
    }
    
    private func formatHealthActionResponse(actionType: HealthActionType, result: HealthActionResponse, value: String?) -> String {
        if result.success {
            switch actionType {
            case .logWorkout:
                return "Great! I've logged your workout session."
            case .recordWaterIntake:
                return "Perfect! I've recorded \(value ?? "your water intake")."
            case .startMeditation:
                return "Starting your meditation session now. Find a quiet place and relax."
            case .setHealthGoal:
                return "Excellent! I've set your health goal: \(value ?? "")."
            }
        } else {
            return result.message ?? "I couldn't complete that action right now. Please try again."
        }
    }
}

// MARK: - Health Goal Intent

@available(iOS 18.0, *)
struct HealthGoalIntent: AppIntent {
    static var title: LocalizedStringResource = "Health Goal Management"
    static var description = IntentDescription("Manage your health and fitness goals")
    
    @Parameter(title: "Goal Action")
    var goalAction: GoalAction
    
    @Parameter(title: "Goal Type")
    var goalType: HealthGoalType?
    
    @Parameter(title: "Target Value")
    var targetValue: String?
    
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let healthManager = HealthDataManager.shared
        
        switch goalAction {
        case .create:
            guard let goalType = goalType, let targetValue = targetValue else {
                return .result(dialog: "I need both a goal type and target value to create a goal.")
            }
            
            let success = await healthManager.createHealthGoal(type: goalType, target: targetValue)
            let dialog = success ? "I've created your \(goalType.rawValue) goal of \(targetValue)." : "I couldn't create that goal right now."
            
            return .result(dialog: dialog) {
                HealthGoalResult(action: goalAction, success: success)
            }
            
        case .check:
            let goals = await healthManager.getActiveGoals()
            if goals.isEmpty {
                return .result(dialog: "You don't have any active health goals. Would you like to set one?")
            } else {
                let progress = goals.map { "\($0.type): \(Int($0.progress))%" }.joined(separator: ", ")
                return .result(dialog: "Here's your goal progress: \(progress)")
            }
            
        case .update:
            guard let goalType = goalType else {
                return .result(dialog: "Which goal would you like to update?")
            }
            
            let success = await healthManager.updateHealthGoal(type: goalType, newTarget: targetValue)
            let dialog = success ? "I've updated your \(goalType.rawValue) goal." : "I couldn't update that goal right now."
            
            return .result(dialog: dialog) {
                HealthGoalResult(action: goalAction, success: success)
            }
            
        case .delete:
            guard let goalType = goalType else {
                return .result(dialog: "Which goal would you like to delete?")
            }
            
            let success = await healthManager.deleteHealthGoal(type: goalType)
            let dialog = success ? "I've deleted your \(goalType.rawValue) goal." : "I couldn't delete that goal right now."
            
            return .result(dialog: dialog) {
                HealthGoalResult(action: goalAction, success: success)
            }
        }
    }
}

// MARK: - Supporting Data Structures

struct HealthCommandResponse {
    let dialog: String
    let response: String
    let data: [String: Any]
    let suggestions: [String]
}

struct HealthCommandResult {
    let response: String
    let data: [String: Any]
    let suggestions: [String]
}

struct HealthDataQueryResult {
    let dataType: HealthDataType
    let timePeriod: TimePeriod
    let data: [String: Any]
}

struct HealthActionResult {
    let actionType: HealthActionType
    let success: Bool
    let message: String?
}

struct HealthGoalResult {
    let action: GoalAction
    let success: Bool
}

struct HealthActionResponse {
    let success: Bool
    let message: String?
}

// MARK: - Enums

enum HealthDataType: String, AppEnum {
    case heartRate = "Heart Rate"
    case steps = "Steps"
    case sleep = "Sleep"
    case waterIntake = "Water Intake"
    case weight = "Weight"
    
    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Health Data Type")
    static var caseDisplayRepresentations: [HealthDataType: DisplayRepresentation] = [
        .heartRate: "Heart Rate",
        .steps: "Steps",
        .sleep: "Sleep",
        .waterIntake: "Water Intake",
        .weight: "Weight"
    ]
}

enum TimePeriod: String, AppEnum {
    case today = "Today"
    case yesterday = "Yesterday"
    case thisWeek = "This Week"
    case lastWeek = "Last Week"
    case thisMonth = "This Month"
    case lastMonth = "Last Month"
    
    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Time Period")
    static var caseDisplayRepresentations: [TimePeriod: DisplayRepresentation] = [
        .today: "Today",
        .yesterday: "Yesterday",
        .thisWeek: "This Week",
        .lastWeek: "Last Week",
        .thisMonth: "This Month",
        .lastMonth: "Last Month"
    ]
    
    var displayName: String {
        switch self {
        case .today: return "today"
        case .yesterday: return "yesterday"
        case .thisWeek: return "this week"
        case .lastWeek: return "last week"
        case .thisMonth: return "this month"
        case .lastMonth: return "last month"
        }
    }
}

enum HealthActionType: String, AppEnum {
    case logWorkout = "Log Workout"
    case recordWaterIntake = "Record Water Intake"
    case startMeditation = "Start Meditation"
    case setHealthGoal = "Set Health Goal"
    
    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Health Action")
    static var caseDisplayRepresentations: [HealthActionType: DisplayRepresentation] = [
        .logWorkout: "Log Workout",
        .recordWaterIntake: "Record Water Intake",
        .startMeditation: "Start Meditation",
        .setHealthGoal: "Set Health Goal"
    ]
}

enum HealthGoalType: String, AppEnum {
    case steps = "Steps"
    case sleep = "Sleep"
    case water = "Water"
    case exercise = "Exercise"
    case weight = "Weight"
    
    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Goal Type")
    static var caseDisplayRepresentations: [HealthGoalType: DisplayRepresentation] = [
        .steps: "Steps",
        .sleep: "Sleep",
        .water: "Water",
        .exercise: "Exercise",
        .weight: "Weight"
    ]
}

enum GoalAction: String, AppEnum {
    case create = "Create"
    case check = "Check"
    case update = "Update"
    case delete = "Delete"
    
    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Goal Action")
    static var caseDisplayRepresentations: [GoalAction: DisplayRepresentation] = [
        .create: "Create",
        .check: "Check",
        .update: "Update",
        .delete: "Delete"
    ]
}

// MARK: - Mock Data Structures for HealthDataManager

struct WorkoutData {
    let type: String
    let duration: Int
}

struct HealthGoal {
    let type: String
    let progress: Double
}

struct SleepData {
    let duration: TimeInterval
    let efficiency: Double
}

// MARK: - Mock HealthDataManager

class HealthDataManager {
    static let shared = HealthDataManager()
    private init() {}
    
    func getLatestHeartRate() async -> Double? {
        // Mock implementation - replace with actual HealthKit integration
        return Double.random(in: 60...100)
    }
    
    func getLastNightSleep() async -> SleepData? {
        // Mock implementation
        return SleepData(
            duration: Double.random(in: 6...9) * 3600,
            efficiency: Double.random(in: 0.7...0.95)
        )
    }
    
    func getTodaySteps() async -> Double? {
        // Mock implementation
        return Double.random(in: 1000...15000)
    }
    
    func calculateHealthScore() async -> Double {
        // Mock implementation
        return Double.random(in: 60...95)
    }
    
    func getRecentWorkouts() async -> [WorkoutData] {
        // Mock implementation
        return [
            WorkoutData(type: "Running", duration: 30),
            WorkoutData(type: "Walking", duration: 45)
        ]
    }
    
    func getTodayWaterIntake() async -> Double {
        // Mock implementation
        return Double.random(in: 20...80)
    }
    
    func getTodayMeditationMinutes() async -> Double {
        // Mock implementation
        return Double.random(in: 0...30)
    }
    
    func getActiveGoals() async -> [HealthGoal] {
        // Mock implementation
        return [
            HealthGoal(type: "Steps", progress: Double.random(in: 0...100)),
            HealthGoal(type: "Sleep", progress: Double.random(in: 0...100))
        ]
    }
    
    func getHealthData(type: HealthDataType, period: TimePeriod) async -> [String: Any] {
        // Mock implementation
        switch type {
        case .heartRate:
            return ["average": Double.random(in: 60...100)]
        case .steps:
            return ["total": Double.random(in: 5000...15000)]
        case .sleep:
            return ["averageDuration": Double.random(in: 6...9) * 3600]
        case .waterIntake:
            return ["total": Double.random(in: 40...80)]
        case .weight:
            return ["latest": Double.random(in: 120...200)]
        }
    }
    
    func performHealthAction(actionType: HealthActionType, value: String?) async -> HealthActionResponse {
        // Mock implementation
        return HealthActionResponse(success: true, message: "Action completed successfully")
    }
    
    func createHealthGoal(type: HealthGoalType, target: String) async -> Bool {
        // Mock implementation
        return true
    }
    
    func updateHealthGoal(type: HealthGoalType, newTarget: String?) async -> Bool {
        // Mock implementation
        return true
    }
    
    func deleteHealthGoal(type: HealthGoalType) async -> Bool {
        // Mock implementation
        return true
    }
}
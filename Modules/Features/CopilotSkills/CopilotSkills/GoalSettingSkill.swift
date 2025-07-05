import Foundation
import SwiftData

/// Skill that helps users set and track health goals
public class GoalSettingSkill: BaseCopilotSkill {
    
    public init() {
        super.init(
            skillID: "goal_setting",
            skillName: "Goal Setting",
            skillDescription: "Helps users set and track health goals",
            handledIntents: [
                "set_goal",
                "check_goal_progress",
                "update_goal",
                "list_goals",
                "celebrate_goal_achievement",
                "suggest_goals"
            ],
            priority: 2,
            requiresAuthentication: false
        )
    }
    
    public override func execute(intent: String, parameters: [String: Any], context: CopilotContext) async -> CopilotSkillResult {
        switch intent {
        case "set_goal":
            return await setGoal(parameters: parameters, context: context)
        case "check_goal_progress":
            return await checkGoalProgress(parameters: parameters, context: context)
        case "update_goal":
            return await updateGoal(parameters: parameters, context: context)
        case "list_goals":
            return await listGoals(context: context)
        case "celebrate_goal_achievement":
            return await celebrateGoalAchievement(parameters: parameters, context: context)
        case "suggest_goals":
            return await suggestGoals(context: context)
        default:
            return .error("Unknown intent: \(intent)")
        }
    }
    
    private func setGoal(parameters: [String: Any], context: CopilotContext) async -> CopilotSkillResult {
        guard let goalType = parameters["goal_type"] as? String,
              let targetValue = parameters["target_value"] as? Double else {
            return .error("Missing required parameters: goal_type and target_value")
        }
        
        let goalName = parameters["goal_name"] as? String ?? generateGoalName(type: goalType, value: targetValue)
        let deadline = parameters["deadline"] as? Date ?? calculateDefaultDeadline(goalType: goalType, value: targetValue)
        let description = parameters["description"] as? String ?? generateGoalDescription(type: goalType, value: targetValue)
        
        // In a real implementation, this would save to SwiftData
        // For now, we'll simulate goal creation
        let goal = Goal(
            id: UUID().uuidString,
            name: goalName,
            type: goalType,
            targetValue: targetValue,
            currentValue: 0,
            startDate: Date(),
            deadline: deadline,
            description: description,
            isActive: true
        )
        
        let result: [String: Any] = [
            "goal_created": true,
            "goal_id": goal.id,
            "goal_name": goal.name,
            "goal_type": goal.type,
            "target_value": goal.targetValue,
            "deadline": goal.deadline.timeIntervalSince1970,
            "progress_percentage": goal.progressPercentage
        ]
        
        let message = "🎯 Goal set! \(goal.name) - Target: \(formatGoalValue(type: goalType, value: targetValue)) by \(formatDate(goal.deadline))"
        
        return .composite([
            .text(message),
            .json(result)
        ])
    }
    
    private func checkGoalProgress(parameters: [String: Any], context: CopilotContext) async -> CopilotSkillResult {
        guard let goalId = parameters["goal_id"] as? String else {
            return .error("Missing required parameter: goal_id")
        }
        
        // In a real implementation, this would fetch from SwiftData
        // For now, we'll simulate goal progress
        let goal = simulateGoalProgress(goalId: goalId, context: context)
        
        let progressMessage = generateProgressMessage(goal: goal)
        let timeRemaining = goal.deadline.timeIntervalSince(goal.startDate)
        let isOnTrack = goal.progressPercentage >= calculateRequiredProgress(goal: goal)
        
        let result: [String: Any] = [
            "goal_id": goal.id,
            "goal_name": goal.name,
            "current_value": goal.currentValue,
            "target_value": goal.targetValue,
            "progress_percentage": goal.progressPercentage,
            "time_remaining": timeRemaining,
            "is_on_track": isOnTrack,
            "days_remaining": Int(timeRemaining / (24 * 3600))
        ]
        
        return .composite([
            .text(progressMessage),
            .json(result)
        ])
    }
    
    private func updateGoal(parameters: [String: Any], context: CopilotContext) async -> CopilotSkillResult {
        guard let goalId = parameters["goal_id"] as? String else {
            return .error("Missing required parameter: goal_id")
        }
        
        let newTargetValue = parameters["new_target_value"] as? Double
        let newDeadline = parameters["new_deadline"] as? Date
        let newDescription = parameters["new_description"] as? String
        
        // In a real implementation, this would update SwiftData
        // For now, we'll simulate goal update
        let result: [String: Any] = [
            "goal_updated": true,
            "goal_id": goalId,
            "updates": [
                "target_value": newTargetValue,
                "deadline": newDeadline?.timeIntervalSince1970,
                "description": newDescription
            ]
        ]
        
        var message = "✅ Goal updated successfully!"
        if let newTarget = newTargetValue {
            message += " New target: \(newTarget)"
        }
        if let newDeadline = newDeadline {
            message += " New deadline: \(formatDate(newDeadline))"
        }
        
        return .composite([
            .text(message),
            .json(result)
        ])
    }
    
    private func listGoals(context: CopilotContext) async -> CopilotSkillResult {
        // In a real implementation, this would fetch from SwiftData
        // For now, we'll simulate active goals
        let activeGoals = simulateActiveGoals(context: context)
        
        if activeGoals.isEmpty {
            return .text("You don't have any active goals. Would you like to set one?")
        }
        
        let goalsList = activeGoals.map { goal in
            "• \(goal.name): \(formatGoalValue(type: goal.type, value: goal.currentValue))/\(formatGoalValue(type: goal.type, value: goal.targetValue)) (\(Int(goal.progressPercentage))%)"
        }.joined(separator: "\n")
        
        let result: [String: Any] = [
            "active_goals": activeGoals.map { goal in
                [
                    "id": goal.id,
                    "name": goal.name,
                    "type": goal.type,
                    "current_value": goal.currentValue,
                    "target_value": goal.targetValue,
                    "progress_percentage": goal.progressPercentage,
                    "deadline": goal.deadline.timeIntervalSince1970
                ]
            }
        ]
        
        return .composite([
            .text("📋 Your Active Goals:\n\(goalsList)"),
            .json(result)
        ])
    }
    
    private func celebrateGoalAchievement(parameters: [String: Any], context: CopilotContext) async -> CopilotSkillResult {
        guard let goalId = parameters["goal_id"] as? String else {
            return .error("Missing required parameter: goal_id")
        }
        
        // In a real implementation, this would fetch from SwiftData
        // For now, we'll simulate goal achievement
        let goal = simulateGoalProgress(goalId: goalId, context: context)
        
        if goal.progressPercentage >= 100 {
            let celebration = generateGoalCelebration(goal: goal)
            
            let result: [String: Any] = [
                "goal_achieved": true,
                "goal_id": goal.id,
                "goal_name": goal.name,
                "achievement_date": Date().timeIntervalSince1970,
                "celebration_message": celebration
            ]
            
            return .composite([
                .text(celebration),
                .json(result)
            ])
        } else {
            return .text("You're close! You've achieved \(Int(goal.progressPercentage))% of your goal. Keep going!")
        }
    }
    
    private func suggestGoals(context: CopilotContext) async -> CopilotSkillResult {
        let suggestions = generateGoalSuggestions(context: context)
        
        let suggestionsList = suggestions.map { suggestion in
            "• \(suggestion.name): \(suggestion.description)"
        }.joined(separator: "\n")
        
        let result: [String: Any] = [
            "suggested_goals": suggestions.map { suggestion in
                [
                    "name": suggestion.name,
                    "type": suggestion.type,
                    "target_value": suggestion.targetValue,
                    "description": suggestion.description,
                    "difficulty": suggestion.difficulty
                ]
            }
        ]
        
        return .composite([
            .text("💡 Suggested Goals Based on Your Health Data:\n\(suggestionsList)"),
            .json(result)
        ])
    }
    
    // MARK: - Helper Methods
    
    private struct Goal {
        let id: String
        let name: String
        let type: String
        let targetValue: Double
        let currentValue: Double
        let startDate: Date
        let deadline: Date
        let description: String
        let isActive: Bool
        
        var progressPercentage: Double {
            guard targetValue > 0 else { return 0 }
            return min((currentValue / targetValue) * 100, 100)
        }
    }
    
    private struct GoalSuggestion {
        let name: String
        let type: String
        let targetValue: Double
        let description: String
        let difficulty: String
    }
    
    private func generateGoalName(type: String, value: Double) -> String {
        switch type {
        case "steps":
            return "Daily Steps Goal"
        case "workouts":
            return "Weekly Workouts Goal"
        case "sleep":
            return "Sleep Duration Goal"
        case "weight":
            return "Weight Goal"
        case "strength":
            return "Strength Training Goal"
        default:
            return "Health Goal"
        }
    }
    
    private func generateGoalDescription(type: String, value: Double) -> String {
        switch type {
        case "steps":
            return "Walk \(Int(value)) steps per day to improve cardiovascular health"
        case "workouts":
            return "Complete \(Int(value)) workouts per week to build strength and endurance"
        case "sleep":
            return "Get \(String(format: "%.1f", value)) hours of sleep per night for optimal recovery"
        case "weight":
            return "Achieve a healthy weight of \(String(format: "%.1f", value)) kg"
        case "strength":
            return "Complete \(Int(value)) strength training sessions per week"
        default:
            return "Improve your overall health and wellness"
        }
    }
    
    private func calculateDefaultDeadline(goalType: String, value: Double) -> Date {
        let calendar = Calendar.current
        let now = Date()
        
        switch goalType {
        case "steps":
            return calendar.date(byAdding: .month, value: 1, to: now) ?? now
        case "workouts":
            return calendar.date(byAdding: .month, value: 2, to: now) ?? now
        case "sleep":
            return calendar.date(byAdding: .month, value: 1, to: now) ?? now
        case "weight":
            return calendar.date(byAdding: .month, value: 6, to: now) ?? now
        case "strength":
            return calendar.date(byAdding: .month, value: 3, to: now) ?? now
        default:
            return calendar.date(byAdding: .month, value: 3, to: now) ?? now
        }
    }
    
    private func formatGoalValue(type: String, value: Double) -> String {
        switch type {
        case "steps":
            return "\(Int(value)) steps"
        case "workouts":
            return "\(Int(value)) workouts"
        case "sleep":
            return "\(String(format: "%.1f", value)) hours"
        case "weight":
            return "\(String(format: "%.1f", value)) kg"
        case "strength":
            return "\(Int(value)) sessions"
        default:
            return "\(value)"
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    private func simulateGoalProgress(goalId: String, context: CopilotContext) -> Goal {
        // Simulate goal progress based on real health data
        let recentHealthData = filterHealthDataByTimeRange(context.healthData, hours: 168) // Last week
        let recentWorkouts = context.workoutRecords.suffix(7)
        
        // Simulate different goal types
        let goalTypes = ["steps", "workouts", "sleep", "weight", "strength"]
        let randomType = goalTypes[goalId.hashValue % goalTypes.count]
        
        let currentValue: Double
        switch randomType {
        case "steps":
            currentValue = Double(recentHealthData.compactMap { $0.dailySteps }.reduce(0, +))
        case "workouts":
            currentValue = Double(recentWorkouts.count)
        case "sleep":
            currentValue = recentHealthData.compactMap { $0.sleepDuration }.reduce(0, +) / Double(max(recentHealthData.count, 1))
        case "weight":
            currentValue = 70.0 // Simulate current weight
        case "strength":
            currentValue = Double(recentWorkouts.filter { $0.workoutType == "strength" }.count)
        default:
            currentValue = 50.0
        }
        
        let targetValue = currentValue * 1.5 // Simulate target
        let startDate = Date().addingTimeInterval(-7 * 24 * 3600) // Started a week ago
        let deadline = Date().addingTimeInterval(30 * 24 * 3600) // Due in 30 days
        
        return Goal(
            id: goalId,
            name: generateGoalName(type: randomType, value: targetValue),
            type: randomType,
            targetValue: targetValue,
            currentValue: currentValue,
            startDate: startDate,
            deadline: deadline,
            description: generateGoalDescription(type: randomType, value: targetValue),
            isActive: true
        )
    }
    
    private func simulateActiveGoals(context: CopilotContext) -> [Goal] {
        // Simulate 2-3 active goals
        let goalIds = ["goal_1", "goal_2", "goal_3"]
        return goalIds.map { simulateGoalProgress(goalId: $0, context: context) }
    }
    
    private func generateProgressMessage(goal: Goal) -> String {
        let progress = Int(goal.progressPercentage)
        
        if progress >= 100 {
            return "🎉 Congratulations! You've achieved your goal: \(goal.name)!"
        } else if progress >= 80 {
            return "🔥 You're so close! \(goal.name): \(progress)% complete. Almost there!"
        } else if progress >= 50 {
            return "💪 Great progress! \(goal.name): \(progress)% complete. Keep up the momentum!"
        } else if progress >= 25 {
            return "🚀 Good start! \(goal.name): \(progress)% complete. You're building momentum!"
        } else {
            return "🌟 Getting started! \(goal.name): \(progress)% complete. Every step counts!"
        }
    }
    
    private func calculateRequiredProgress(goal: Goal) -> Double {
        let totalDays = goal.deadline.timeIntervalSince(goal.startDate) / (24 * 3600)
        let elapsedDays = Date().timeIntervalSince(goal.startDate) / (24 * 3600)
        return (elapsedDays / totalDays) * 100
    }
    
    private func generateGoalCelebration(goal: Goal) -> String {
        let celebrations = [
            "🎊 Amazing achievement! You've reached your goal: \(goal.name)!",
            "🏆 Outstanding work! Goal accomplished: \(goal.name)!",
            "🌟 Incredible dedication! You've achieved: \(goal.name)!",
            "💎 You're unstoppable! Goal completed: \(goal.name)!",
            "🔥 Phenomenal success! You've reached: \(goal.name)!"
        ]
        
        let randomIndex = goal.id.hashValue % celebrations.count
        return celebrations[randomIndex]
    }
    
    private func generateGoalSuggestions(context: CopilotContext) -> [GoalSuggestion] {
        let recentHealthData = filterHealthDataByTimeRange(context.healthData, hours: 168)
        let recentWorkouts = context.workoutRecords.suffix(14)
        
        var suggestions: [GoalSuggestion] = []
        
        // Analyze current patterns and suggest improvements
        let averageSteps = recentHealthData.compactMap { $0.dailySteps }.reduce(0, +) / max(recentHealthData.count, 1)
        if averageSteps < 8000 {
            suggestions.append(GoalSuggestion(
                name: "Increase Daily Steps",
                type: "steps",
                targetValue: 10000,
                description: "Boost your daily step count to improve cardiovascular health",
                difficulty: "Beginner"
            ))
        }
        
        let workoutCount = recentWorkouts.count
        if workoutCount < 3 {
            suggestions.append(GoalSuggestion(
                name: "Weekly Workout Routine",
                type: "workouts",
                targetValue: 3,
                description: "Establish a consistent weekly workout routine",
                difficulty: "Beginner"
            ))
        }
        
        let averageSleep = recentHealthData.compactMap { $0.sleepDuration }.reduce(0, +) / max(recentHealthData.count, 1)
        if averageSleep < 7 {
            suggestions.append(GoalSuggestion(
                name: "Improve Sleep Duration",
                type: "sleep",
                targetValue: 7.5,
                description: "Increase your nightly sleep duration for better recovery",
                difficulty: "Intermediate"
            ))
        }
        
        let strengthWorkouts = recentWorkouts.filter { $0.workoutType == "strength" }.count
        if strengthWorkouts < 2 {
            suggestions.append(GoalSuggestion(
                name: "Strength Training",
                type: "strength",
                targetValue: 2,
                description: "Add strength training to build muscle and improve metabolism",
                difficulty: "Intermediate"
            ))
        }
        
        return suggestions
    }
    
    public override func getSuggestedActions(context: CopilotContext) -> [CopilotAction] {
        return [
            CopilotAction(
                id: "set_new_goal",
                title: "Set New Goal",
                description: "Create a new health goal",
                icon: "target",
                actionType: .custom("set_goal")
            ),
            CopilotAction(
                id: "view_goals",
                title: "View Goals",
                description: "See all your active goals and progress",
                icon: "list.bullet",
                actionType: .viewDetails,
                parameters: ["section": "goals"]
            ),
            CopilotAction(
                id: "suggest_goals",
                title: "Get Suggestions",
                description: "Get personalized goal recommendations",
                icon: "lightbulb",
                actionType: .custom("suggest_goals")
            )
        ]
    }
} 
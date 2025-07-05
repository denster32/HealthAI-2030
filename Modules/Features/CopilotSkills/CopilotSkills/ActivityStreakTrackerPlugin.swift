import Foundation
import SwiftData

/// Plugin that tracks activity streaks and provides motivation
public class ActivityStreakTrackerPlugin: BaseCopilotSkill {
    
    public init() {
        super.init(
            skillID: "activity_streak_tracker",
            skillName: "Activity Streak Tracker",
            skillDescription: "Tracks consecutive days of activity and provides motivation",
            handledIntents: [
                "get_activity_streak",
                "check_streak_status",
                "motivate_activity",
                "set_streak_goal",
                "celebrate_streak"
            ],
            priority: 2,
            requiresAuthentication: false
        )
    }
    
    public override func execute(intent: String, parameters: [String: Any], context: CopilotContext) async -> CopilotSkillResult {
        switch intent {
        case "get_activity_streak":
            return await getActivityStreak(context: context)
        case "check_streak_status":
            return await checkStreakStatus(context: context)
        case "motivate_activity":
            return await motivateActivity(context: context)
        case "set_streak_goal":
            return await setStreakGoal(parameters: parameters, context: context)
        case "celebrate_streak":
            return await celebrateStreak(context: context)
        default:
            return .error("Unknown intent: \(intent)")
        }
    }
    
    private func getActivityStreak(context: CopilotContext) async -> CopilotSkillResult {
        let streakData = calculateActivityStreak(context: context)
        
        let result: [String: Any] = [
            "current_streak": streakData.currentStreak,
            "longest_streak": streakData.longestStreak,
            "total_workouts": streakData.totalWorkouts,
            "streak_start_date": streakData.streakStartDate?.timeIntervalSince1970,
            "goal_streak": streakData.goalStreak,
            "progress_to_goal": streakData.progressToGoal
        ]
        
        let message = generateStreakMessage(streakData: streakData)
        
        return .composite([
            .text(message),
            .json(result)
        ])
    }
    
    private func checkStreakStatus(context: CopilotContext) async -> CopilotSkillResult {
        let streakData = calculateActivityStreak(context: context)
        let today = Date()
        let calendar = Calendar.current
        
        // Check if user has been active today
        let todayWorkouts = context.workoutRecords.filter { workout in
            calendar.isDate(workout.startTime, inSameDayAs: today)
        }
        
        let hasBeenActiveToday = !todayWorkouts.isEmpty
        let isStreakAtRisk = !hasBeenActiveToday && streakData.currentStreak > 0
        
        var status = "active"
        var message = ""
        
        if hasBeenActiveToday {
            status = "completed"
            message = "Great job! You've completed your activity for today. Your streak is safe!"
        } else if isStreakAtRisk {
            status = "at_risk"
            message = "⚠️ Your \(streakData.currentStreak)-day streak is at risk! Complete a workout today to keep it going."
        } else {
            status = "inactive"
            message = "No activity recorded today. Start a workout to begin building your streak!"
        }
        
        let result: [String: Any] = [
            "status": status,
            "current_streak": streakData.currentStreak,
            "has_been_active_today": hasBeenActiveToday,
            "is_streak_at_risk": isStreakAtRisk,
            "time_remaining": getTimeRemainingInDay()
        ]
        
        return .composite([
            .text(message),
            .json(result)
        ])
    }
    
    private func motivateActivity(context: CopilotContext) async -> CopilotSkillResult {
        let streakData = calculateActivityStreak(context: context)
        let motivation = generateMotivationMessage(streakData: streakData)
        
        let result: [String: Any] = [
            "motivation_type": getMotivationType(streakData: streakData),
            "current_streak": streakData.currentStreak,
            "next_milestone": getNextMilestone(currentStreak: streakData.currentStreak),
            "motivation_message": motivation
        ]
        
        return .composite([
            .text(motivation),
            .json(result)
        ])
    }
    
    private func setStreakGoal(parameters: [String: Any], context: CopilotContext) async -> CopilotSkillResult {
        guard let goalDays = parameters["goal_days"] as? Int else {
            return .error("Missing required parameter: goal_days")
        }
        
        // In a real implementation, this would save to UserDefaults or SwiftData
        // For now, we'll simulate setting a goal
        let result: [String: Any] = [
            "goal_set": true,
            "goal_days": goalDays,
            "message": "Goal set! Aim for \(goalDays) consecutive days of activity."
        ]
        
        return .composite([
            .text("Goal set! Aim for \(goalDays) consecutive days of activity."),
            .json(result)
        ])
    }
    
    private func celebrateStreak(context: CopilotContext) async -> CopilotSkillResult {
        let streakData = calculateActivityStreak(context: context)
        
        guard streakData.currentStreak > 0 else {
            return .text("No active streak to celebrate. Start working out to build your streak!")
        }
        
        let celebration = generateCelebrationMessage(streakData: streakData)
        
        let result: [String: Any] = [
            "celebration_type": getCelebrationType(streakData: streakData),
            "current_streak": streakData.currentStreak,
            "achievement": getAchievementForStreak(streakData.currentStreak),
            "celebration_message": celebration
        ]
        
        return .composite([
            .text(celebration),
            .json(result)
        ])
    }
    
    // MARK: - Helper Methods
    
    private struct StreakData {
        let currentStreak: Int
        let longestStreak: Int
        let totalWorkouts: Int
        let streakStartDate: Date?
        let goalStreak: Int
        let progressToGoal: Double
    }
    
    private func calculateActivityStreak(context: CopilotContext) -> StreakData {
        let calendar = Calendar.current
        let today = Date()
        let sortedWorkouts = context.workoutRecords.sorted { $0.startTime > $1.startTime }
        
        var currentStreak = 0
        var longestStreak = 0
        var streakStartDate: Date?
        var tempStreak = 0
        var lastWorkoutDate: Date?
        
        // Calculate current streak
        var checkDate = today
        while true {
            let workoutsOnDate = sortedWorkouts.filter { workout in
                calendar.isDate(workout.startTime, inSameDayAs: checkDate)
            }
            
            if !workoutsOnDate.isEmpty {
                currentStreak += 1
                if streakStartDate == nil {
                    streakStartDate = checkDate
                }
                lastWorkoutDate = checkDate
            } else {
                break
            }
            
            checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate) ?? checkDate
        }
        
        // Calculate longest streak
        var consecutiveDays = 0
        var maxConsecutiveDays = 0
        var previousDate: Date?
        
        for workout in sortedWorkouts {
            let workoutDate = calendar.startOfDay(for: workout.startTime)
            
            if let previous = previousDate {
                let daysBetween = calendar.dateComponents([.day], from: workoutDate, to: previous).day ?? 0
                
                if daysBetween == 1 {
                    consecutiveDays += 1
                } else {
                    maxConsecutiveDays = max(maxConsecutiveDays, consecutiveDays)
                    consecutiveDays = 1
                }
            } else {
                consecutiveDays = 1
            }
            
            previousDate = workoutDate
        }
        
        longestStreak = max(maxConsecutiveDays, consecutiveDays)
        
        // Simulate goal streak (in real app, this would come from user settings)
        let goalStreak = 30
        let progressToGoal = min(Double(currentStreak) / Double(goalStreak), 1.0)
        
        return StreakData(
            currentStreak: currentStreak,
            longestStreak: longestStreak,
            totalWorkouts: sortedWorkouts.count,
            streakStartDate: streakStartDate,
            goalStreak: goalStreak,
            progressToGoal: progressToGoal
        )
    }
    
    private func generateStreakMessage(streakData: StreakData) -> String {
        if streakData.currentStreak == 0 {
            return "You don't have an active streak right now. Start working out today to begin building your streak!"
        }
        
        var message = "🔥 You're on a \(streakData.currentStreak)-day activity streak!"
        
        if streakData.currentStreak == streakData.longestStreak {
            message += " This is your longest streak ever!"
        } else if streakData.longestStreak > streakData.currentStreak {
            message += " Your longest streak is \(streakData.longestStreak) days."
        }
        
        if let startDate = streakData.streakStartDate {
            let daysSinceStart = Calendar.current.dateComponents([.day], from: startDate, to: Date()).day ?? 0
            message += " You've been consistent for \(daysSinceStart) days."
        }
        
        if streakData.progressToGoal > 0 {
            let percentage = Int(streakData.progressToGoal * 100)
            message += " You're \(percentage)% of the way to your \(streakData.goalStreak)-day goal!"
        }
        
        return message
    }
    
    private func generateMotivationMessage(streakData: StreakData) -> String {
        if streakData.currentStreak == 0 {
            return "Ready to start your fitness journey? Every expert was once a beginner. Take that first step today! 💪"
        }
        
        let motivations = [
            "You're building an incredible habit! Consistency is the key to long-term success. 🎯",
            "Your future self will thank you for every workout you complete today. 🌟",
            "You're not just working out, you're investing in your health and happiness. 💎",
            "Every day you maintain your streak, you're proving to yourself that you can do hard things. 🏆",
            "Your streak shows dedication and discipline. Keep that momentum going! 🚀"
        ]
        
        let milestoneMotivations = [
            7: "One week strong! You're building a real habit now. 🎉",
            14: "Two weeks! You're past the hardest part. Keep going! 🔥",
            21: "Three weeks! They say it takes 21 days to form a habit. You're there! 🎊",
            30: "A full month! You're officially a fitness warrior! ⚔️",
            60: "Two months! You're in the top tier of consistency! 👑",
            100: "100 days! You're absolutely unstoppable! 💯"
        ]
        
        if let milestoneMotivation = milestoneMotivations[streakData.currentStreak] {
            return milestoneMotivation
        }
        
        let randomIndex = streakData.currentStreak % motivations.count
        return motivations[randomIndex]
    }
    
    private func generateCelebrationMessage(streakData: StreakData) -> String {
        let celebrations = [
            "🎉 Congratulations on your \(streakData.currentStreak)-day streak! You're absolutely crushing it!",
            "🏆 Amazing work! \(streakData.currentStreak) days of consistent activity is no small feat!",
            "🌟 You're a fitness inspiration! Keep that \(streakData.currentStreak)-day streak going!",
            "💪 Incredible dedication! \(streakData.currentStreak) days and counting!",
            "🔥 You're on fire! \(streakData.currentStreak) days of pure consistency!"
        ]
        
        let randomIndex = streakData.currentStreak % celebrations.count
        return celebrations[randomIndex]
    }
    
    private func getMotivationType(streakData: StreakData) -> String {
        if streakData.currentStreak == 0 {
            return "start"
        } else if streakData.currentStreak < 7 {
            return "build"
        } else if streakData.currentStreak < 30 {
            return "maintain"
        } else {
            return "excel"
        }
    }
    
    private func getCelebrationType(streakData: StreakData) -> String {
        if streakData.currentStreak >= 100 {
            return "century"
        } else if streakData.currentStreak >= 60 {
            return "milestone"
        } else if streakData.currentStreak >= 30 {
            return "month"
        } else if streakData.currentStreak >= 7 {
            return "week"
        } else {
            return "daily"
        }
    }
    
    private func getNextMilestone(currentStreak: Int) -> Int {
        let milestones = [7, 14, 21, 30, 60, 100]
        return milestones.first { $0 > currentStreak } ?? (currentStreak + 10)
    }
    
    private func getAchievementForStreak(_ streak: Int) -> String {
        switch streak {
        case 1...6:
            return "Getting Started"
        case 7...13:
            return "Habit Builder"
        case 14...20:
            return "Consistency Champion"
        case 21...29:
            return "Habit Master"
        case 30...59:
            return "Fitness Warrior"
        case 60...99:
            return "Elite Athlete"
        default:
            return "Legendary"
        }
    }
    
    private func getTimeRemainingInDay() -> TimeInterval {
        let calendar = Calendar.current
        let now = Date()
        let endOfDay = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: now) ?? now
        return endOfDay.timeIntervalSince(now)
    }
    
    public override func getSuggestedActions(context: CopilotContext) -> [CopilotAction] {
        let streakData = calculateActivityStreak(context: context)
        
        var actions: [CopilotAction] = []
        
        if streakData.currentStreak == 0 {
            actions.append(CopilotAction(
                id: "start_workout",
                title: "Start Workout",
                description: "Begin your first workout to start your streak",
                icon: "figure.run",
                actionType: .startWorkout
            ))
        } else {
            actions.append(CopilotAction(
                id: "continue_streak",
                title: "Continue Streak",
                description: "Keep your \(streakData.currentStreak)-day streak going",
                icon: "flame.fill",
                actionType: .startWorkout
            ))
        }
        
        actions.append(CopilotAction(
            id: "view_streak_details",
            title: "View Streak Details",
            description: "See your complete streak history and achievements",
            icon: "chart.line.uptrend.xyaxis",
            actionType: .viewDetails,
            parameters: ["section": "streaks"]
        ))
        
        return actions
    }
} 
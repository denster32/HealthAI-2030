import Foundation
import AppIntents
import HealthKit

// MARK: - Vital Signs Intents

@available(iOS 18.0, *)
struct GetHeartRateIntent: AppIntent {
    static var title: LocalizedStringResource = "Get Heart Rate"
    static var description = IntentDescription("Retrieve your current or most recent heart rate reading")
    
    @Parameter(title: "Time Period", description: "Which heart rate reading to get")
    var timePeriod: HeartRateTimePeriod?
    
    static var parameterSummary: some ParameterSummary {
        Summary("Get my \(\.$timePeriod) heart rate")
    }
    
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let healthManager = HealthDataManager.shared
        
        let heartRateData: Double?
        switch timePeriod ?? .current {
        case .current:
            heartRateData = await healthManager.getLatestHeartRate()
        case .average:
            heartRateData = await healthManager.getAverageHeartRate(timeframe: .today)
        case .resting:
            heartRateData = await healthManager.getRestingHeartRate()
        case .maximum:
            heartRateData = await healthManager.getMaxHeartRate(timeframe: .today)
        }
        
        if let heartRate = heartRateData {
            let dialog = "Your \(timePeriod?.displayName ?? "current") heart rate is \(Int(heartRate)) beats per minute."
            return .result(dialog: dialog) {
                HeartRateResult(heartRate: heartRate, timePeriod: timePeriod ?? .current)
            }
        } else {
            return .result(dialog: "I couldn't find recent heart rate data. Make sure your Apple Watch is connected.")
        }
    }
}

@available(iOS 18.0, *)
struct GetBloodPressureIntent: AppIntent {
    static var title: LocalizedStringResource = "Get Blood Pressure"
    static var description = IntentDescription("Retrieve your latest blood pressure reading")
    
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let healthManager = HealthDataManager.shared
        let bloodPressure = await healthManager.getLatestBloodPressure()
        
        if let bp = bloodPressure {
            let dialog = "Your latest blood pressure is \(Int(bp.systolic)) over \(Int(bp.diastolic))."
            return .result(dialog: dialog) {
                BloodPressureResult(systolic: bp.systolic, diastolic: bp.diastolic, timestamp: bp.timestamp)
            }
        } else {
            return .result(dialog: "No recent blood pressure readings found. Consider logging a reading manually.")
        }
    }
}

// MARK: - Activity Intents

@available(iOS 18.0, *)
struct GetStepCountIntent: AppIntent {
    static var title: LocalizedStringResource = "Get Step Count"
    static var description = IntentDescription("Check your daily step count and progress towards your goal")
    
    @Parameter(title: "Time Frame", description: "Which time period to check")
    var timeframe: StepTimeframe?
    
    static var parameterSummary: some ParameterSummary {
        Summary("Get my steps for \(\.$timeframe)")
    }
    
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let healthManager = HealthDataManager.shared
        let period = timeframe ?? .today
        
        let steps = await healthManager.getStepCount(for: period)
        let goal = await healthManager.getStepGoal()
        
        if let stepCount = steps {
            let progress = goal > 0 ? (stepCount / goal) * 100 : 0
            let remaining = max(0, goal - stepCount)
            
            var dialog = "You've taken \(Int(stepCount)) steps \(period.displayName)."
            
            if goal > 0 {
                if stepCount >= goal {
                    dialog += " Congratulations! You've reached your goal of \(Int(goal)) steps."
                } else {
                    dialog += " You need \(Int(remaining)) more steps to reach your goal."
                }
            }
            
            return .result(dialog: dialog) {
                StepCountResult(
                    stepCount: stepCount,
                    goal: goal,
                    progress: progress,
                    timeframe: period
                )
            }
        } else {
            return .result(dialog: "I couldn't find step data for \(period.displayName). Make sure your iPhone or Apple Watch is tracking your activity.")
        }
    }
}

@available(iOS 18.0, *)
struct LogWorkoutIntent: AppIntent {
    static var title: LocalizedStringResource = "Log Workout"
    static var description = IntentDescription("Record a completed workout session")
    
    @Parameter(title: "Workout Type", description: "What type of exercise did you do?")
    var workoutType: WorkoutType
    
    @Parameter(title: "Duration (minutes)", description: "How long did you exercise?")
    var duration: Int
    
    @Parameter(title: "Intensity", description: "How intense was your workout?")
    var intensity: WorkoutIntensity?
    
    @Parameter(title: "Calories Burned", description: "Estimated calories burned (optional)")
    var calories: Int?
    
    static var parameterSummary: some ParameterSummary {
        Summary("Log a \(\.$duration) minute \(\.$workoutType) workout") {
            \.$intensity
            \.$calories
        }
    }
    
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let healthManager = HealthDataManager.shared
        
        let workout = WorkoutData(
            type: workoutType,
            duration: TimeInterval(duration * 60),
            intensity: intensity ?? .moderate,
            calories: calories,
            timestamp: Date()
        )
        
        let success = await healthManager.logWorkout(workout)
        
        if success {
            var dialog = "Great job! I've logged your \(duration)-minute \(workoutType.displayName) workout."
            
            if let cal = calories {
                dialog += " You burned approximately \(cal) calories."
            }
            
            return .result(dialog: dialog) {
                WorkoutLogResult(workout: workout, success: true)
            }
        } else {
            return .result(dialog: "I had trouble logging your workout. Please try again or check your permissions.")
        }
    }
}

@available(iOS 18.0, *)
struct StartWorkoutIntent: AppIntent {
    static var title: LocalizedStringResource = "Start Workout"
    static var description = IntentDescription("Begin a new workout session")
    
    @Parameter(title: "Workout Type", description: "What type of exercise are you starting?")
    var workoutType: WorkoutType
    
    @Parameter(title: "Estimated Duration", description: "How long do you plan to exercise?")
    var estimatedDuration: Int?
    
    static var parameterSummary: some ParameterSummary {
        Summary("Start a \(\.$workoutType) workout") {
            \.$estimatedDuration
        }
    }
    
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let healthManager = HealthDataManager.shared
        
        let workoutSession = WorkoutSession(
            type: workoutType,
            startTime: Date(),
            estimatedDuration: estimatedDuration.map { TimeInterval($0 * 60) }
        )
        
        let success = await healthManager.startWorkout(workoutSession)
        
        if success {
            var dialog = "Starting your \(workoutType.displayName) workout now!"
            
            if let duration = estimatedDuration {
                dialog += " I'll track your progress for \(duration) minutes."
            }
            
            dialog += " Have a great workout!"
            
            return .result(dialog: dialog) {
                WorkoutStartResult(session: workoutSession, success: true)
            }
        } else {
            return .result(dialog: "I couldn't start your workout session. Please check your Apple Watch connection and try again.")
        }
    }
}

// MARK: - Nutrition Intents

@available(iOS 18.0, *)
struct LogWaterIntakeIntent: AppIntent {
    static var title: LocalizedStringResource = "Log Water Intake"
    static var description = IntentDescription("Record water consumption to track your hydration")
    
    @Parameter(title: "Amount", description: "How much water did you drink?")
    var amount: Double
    
    @Parameter(title: "Unit", description: "What unit of measurement?")
    var unit: WaterUnit?
    
    static var parameterSummary: some ParameterSummary {
        Summary("Log \(\.$amount) \(\.$unit) of water")
    }
    
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let healthManager = HealthDataManager.shared
        let waterUnit = unit ?? .ounces
        
        let success = await healthManager.logWaterIntake(amount: amount, unit: waterUnit)
        
        if success {
            let todayTotal = await healthManager.getTodayWaterIntake()
            let goal = 64.0 // Default goal in ounces
            let remaining = max(0, goal - todayTotal)
            
            var dialog = "Perfect! I've logged \(Int(amount)) \(waterUnit.displayName) of water."
            
            if remaining > 0 {
                dialog += " You've had \(Int(todayTotal)) ounces today. You need \(Int(remaining)) more to reach your daily goal."
            } else {
                dialog += " Great job! You've reached your daily hydration goal."
            }
            
            return .result(dialog: dialog) {
                WaterIntakeResult(
                    amount: amount,
                    unit: waterUnit,
                    todayTotal: todayTotal,
                    goal: goal
                )
            }
        } else {
            return .result(dialog: "I couldn't log your water intake. Please try again.")
        }
    }
}

@available(iOS 18.0, *)
struct LogMealIntent: AppIntent {
    static var title: LocalizedStringResource = "Log Meal"
    static var description = IntentDescription("Record a meal and its nutritional information")
    
    @Parameter(title: "Meal Type", description: "What type of meal is this?")
    var mealType: MealType
    
    @Parameter(title: "Calories", description: "Estimated calories (optional)")
    var calories: Int?
    
    @Parameter(title: "Description", description: "Brief description of the meal")
    var description: String?
    
    static var parameterSummary: some ParameterSummary {
        Summary("Log a \(\.$mealType)") {
            \.$calories
            \.$description
        }
    }
    
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let healthManager = HealthDataManager.shared
        
        let meal = MealData(
            type: mealType,
            description: description,
            calories: calories,
            timestamp: Date()
        )
        
        let success = await healthManager.logMeal(meal)
        
        if success {
            var dialog = "I've logged your \(mealType.displayName)"
            
            if let desc = description {
                dialog += ": \(desc)"
            }
            
            if let cal = calories {
                dialog += ". That's \(cal) calories."
            }
            
            return .result(dialog: dialog) {
                MealLogResult(meal: meal, success: true)
            }
        } else {
            return .result(dialog: "I couldn't log your meal. Please try again.")
        }
    }
}

// MARK: - Sleep Intents

@available(iOS 18.0, *)
struct GetSleepDataIntent: AppIntent {
    static var title: LocalizedStringResource = "Get Sleep Data"
    static var description = IntentDescription("Retrieve sleep analysis and trends")
    
    @Parameter(title: "Time Frame", description: "Which sleep data to retrieve")
    var timeframe: SleepTimeframe?
    
    static var parameterSummary: some ParameterSummary {
        Summary("Get my sleep data for \(\.$timeframe)")
    }
    
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let healthManager = HealthDataManager.shared
        let period = timeframe ?? .lastNight
        
        let sleepData = await healthManager.getSleepData(for: period)
        
        if let sleep = sleepData {
            let hours = Int(sleep.duration / 3600)
            let minutes = Int((sleep.duration.truncatingRemainder(dividingBy: 3600)) / 60)
            let efficiency = Int(sleep.efficiency * 100)
            
            var dialog = "Your sleep data for \(period.displayName): "
            dialog += "\(hours) hours and \(minutes) minutes with \(efficiency)% efficiency."
            
            if sleep.efficiency > 0.85 {
                dialog += " That's excellent sleep quality!"
            } else if sleep.efficiency > 0.75 {
                dialog += " Good sleep quality overall."
            } else {
                dialog += " Consider improving your bedtime routine for better sleep quality."
            }
            
            return .result(dialog: dialog) {
                SleepDataResult(
                    duration: sleep.duration,
                    efficiency: sleep.efficiency,
                    bedtime: sleep.bedtime,
                    wakeTime: sleep.wakeTime,
                    timeframe: period
                )
            }
        } else {
            return .result(dialog: "I couldn't find sleep data for \(period.displayName). Make sure sleep tracking is enabled.")
        }
    }
}

@available(iOS 18.0, *)
struct SetSleepGoalIntent: AppIntent {
    static var title: LocalizedStringResource = "Set Sleep Goal"
    static var description = IntentDescription("Configure your sleep duration and bedtime goals")
    
    @Parameter(title: "Bedtime", description: "What time do you want to go to bed?")
    var bedtime: Date
    
    @Parameter(title: "Wake Time", description: "What time do you want to wake up?")
    var wakeTime: Date
    
    static var parameterSummary: some ParameterSummary {
        Summary("Set bedtime to \(\.$bedtime) and wake time to \(\.$wakeTime)")
    }
    
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let healthManager = HealthDataManager.shared
        
        // Calculate sleep duration
        let calendar = Calendar.current
        var sleepDuration = wakeTime.timeIntervalSince(bedtime)
        
        // Handle overnight sleep (bedtime after wake time)
        if sleepDuration < 0 {
            sleepDuration += 24 * 3600 // Add 24 hours
        }
        
        let hours = Int(sleepDuration / 3600)
        let minutes = Int((sleepDuration.truncatingRemainder(dividingBy: 3600)) / 60)
        
        let sleepGoal = SleepGoal(
            bedtime: bedtime,
            wakeTime: wakeTime,
            duration: sleepDuration
        )
        
        let success = await healthManager.setSleepGoal(sleepGoal)
        
        if success {
            let bedtimeString = DateFormatter.timeFormatter.string(from: bedtime)
            let wakeTimeString = DateFormatter.timeFormatter.string(from: wakeTime)
            
            let dialog = "Perfect! I've set your sleep goal: bedtime at \(bedtimeString) and wake time at \(wakeTimeString). That's \(hours) hours and \(minutes) minutes of sleep."
            
            return .result(dialog: dialog) {
                SleepGoalResult(goal: sleepGoal, success: true)
            }
        } else {
            return .result(dialog: "I couldn't set your sleep goal. Please try again.")
        }
    }
}

// MARK: - Mental Health Intents

@available(iOS 18.0, *)
struct StartMeditationIntent: AppIntent {
    static var title: LocalizedStringResource = "Start Meditation"
    static var description = IntentDescription("Begin a guided meditation session")
    
    @Parameter(title: "Duration (minutes)", description: "How long would you like to meditate?")
    var duration: Int?
    
    @Parameter(title: "Type", description: "What type of meditation?")
    var type: MeditationType?
    
    static var parameterSummary: some ParameterSummary {
        Summary("Start a \(\.$duration) minute \(\.$type) meditation")
    }
    
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let meditationDuration = duration ?? 10
        let meditationType = type ?? .breathing
        
        let session = MeditationSession(
            type: meditationType,
            duration: TimeInterval(meditationDuration * 60),
            startTime: Date()
        )
        
        let healthManager = HealthDataManager.shared
        let success = await healthManager.startMeditation(session)
        
        if success {
            let dialog = "Starting your \(meditationDuration)-minute \(meditationType.displayName) meditation. Find a comfortable position and focus on your breath."
            
            return .result(dialog: dialog) {
                MeditationStartResult(session: session, success: true)
            }
        } else {
            return .result(dialog: "I couldn't start your meditation session. Please try again.")
        }
    }
}

@available(iOS 18.0, *)
struct LogMoodIntent: AppIntent {
    static var title: LocalizedStringResource = "Log Mood"
    static var description = IntentDescription("Record your current mood and mental state")
    
    @Parameter(title: "Mood", description: "How are you feeling?")
    var mood: MoodType
    
    @Parameter(title: "Notes", description: "Any additional notes about your mood?")
    var notes: String?
    
    static var parameterSummary: some ParameterSummary {
        Summary("Log my mood as \(\.$mood)") {
            \.$notes
        }
    }
    
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let healthManager = HealthDataManager.shared
        
        let moodEntry = MoodEntry(
            mood: mood,
            notes: notes,
            timestamp: Date()
        )
        
        let success = await healthManager.logMood(moodEntry)
        
        if success {
            var dialog = "Thanks for sharing! I've recorded that you're feeling \(mood.displayName)"
            
            if let notes = notes {
                dialog += ". Note: \(notes)"
            }
            
            dialog += ". Tracking your mood helps identify patterns over time."
            
            return .result(dialog: dialog) {
                MoodLogResult(entry: moodEntry, success: true)
            }
        } else {
            return .result(dialog: "I couldn't log your mood entry. Please try again.")
        }
    }
}

// MARK: - Goal Management Intents

@available(iOS 18.0, *)
struct SetHealthGoalIntent: AppIntent {
    static var title: LocalizedStringResource = "Set Health Goal"
    static var description = IntentDescription("Create or update health and fitness goals")
    
    @Parameter(title: "Goal Type", description: "What type of goal would you like to set?")
    var goalType: HealthGoalType
    
    @Parameter(title: "Target", description: "What's your target value?")
    var target: Double
    
    @Parameter(title: "Time Frame", description: "By when do you want to achieve this goal?")
    var timeframe: GoalTimeframe?
    
    static var parameterSummary: some ParameterSummary {
        Summary("Set a \(\.$goalType) goal of \(\.$target)") {
            \.$timeframe
        }
    }
    
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let healthManager = HealthDataManager.shared
        let goalTimeframe = timeframe ?? .ongoing
        
        let goal = HealthGoal(
            type: goalType,
            target: target,
            timeframe: goalTimeframe,
            createdDate: Date()
        )
        
        let success = await healthManager.setHealthGoal(goal)
        
        if success {
            let dialog = "Excellent! I've set your \(goalType.displayName) goal to \(Int(target)) \(goalType.unit). \(goalTimeframe.motivationalMessage)"
            
            return .result(dialog: dialog) {
                HealthGoalResult(goal: goal, success: true)
            }
        } else {
            return .result(dialog: "I couldn't set your health goal. Please try again.")
        }
    }
}

@available(iOS 18.0, *)
struct CheckGoalProgressIntent: AppIntent {
    static var title: LocalizedStringResource = "Check Goal Progress"
    static var description = IntentDescription("Review progress towards your health goals")
    
    @Parameter(title: "Goal Type", description: "Which goal would you like to check?")
    var goalType: HealthGoalType?
    
    static var parameterSummary: some ParameterSummary {
        Summary("Check my \(\.$goalType) goal progress")
    }
    
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let healthManager = HealthDataManager.shared
        
        if let specificGoalType = goalType {
            // Check specific goal
            let progress = await healthManager.getGoalProgress(for: specificGoalType)
            
            if let progressData = progress {
                let percentComplete = Int(progressData.percentComplete)
                let dialog = "Your \(specificGoalType.displayName) goal is \(percentComplete)% complete. Current: \(Int(progressData.current)), Target: \(Int(progressData.target))."
                
                return .result(dialog: dialog) {
                    GoalProgressResult(
                        goalType: specificGoalType,
                        progress: progressData.percentComplete,
                        current: progressData.current,
                        target: progressData.target
                    )
                }
            } else {
                return .result(dialog: "You don't have a \(specificGoalType.displayName) goal set. Would you like to create one?")
            }
        } else {
            // Check all goals
            let allProgress = await healthManager.getAllGoalProgress()
            
            if allProgress.isEmpty {
                return .result(dialog: "You don't have any active health goals. Setting goals can help motivate your health journey!")
            } else {
                let progressSummary = allProgress.map { progress in
                    "\(progress.goalType.displayName): \(Int(progress.percentComplete))%"
                }.joined(separator: ", ")
                
                let dialog = "Here's your goal progress: \(progressSummary). Keep up the great work!"
                
                return .result(dialog: dialog) {
                    AllGoalsProgressResult(progress: allProgress)
                }
            }
        }
    }
}

// MARK: - Analysis Intents

@available(iOS 18.0, *)
struct HealthSummaryIntent: AppIntent {
    static var title: LocalizedStringResource = "Health Summary"
    static var description = IntentDescription("Get a comprehensive overview of your health data")
    
    @Parameter(title: "Time Frame", description: "Which time period to summarize")
    var timeframe: SummaryTimeframe?
    
    static var parameterSummary: some ParameterSummary {
        Summary("Get my health summary for \(\.$timeframe)")
    }
    
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let healthManager = HealthDataManager.shared
        let period = timeframe ?? .today
        
        let summary = await healthManager.getHealthSummary(for: period)
        
        var dialog = "Here's your health summary for \(period.displayName): "
        
        var summaryParts: [String] = []
        
        if let heartRate = summary.averageHeartRate {
            summaryParts.append("average heart rate \(Int(heartRate)) BPM")
        }
        
        if let steps = summary.stepCount {
            summaryParts.append("\(Int(steps)) steps")
        }
        
        if let sleep = summary.sleepHours {
            summaryParts.append("\(String(format: "%.1f", sleep)) hours of sleep")
        }
        
        if let water = summary.waterIntake {
            summaryParts.append("\(Int(water)) ounces of water")
        }
        
        if summaryParts.isEmpty {
            dialog += "No health data available for this period."
        } else {
            dialog += summaryParts.joined(separator: ", ") + "."
        }
        
        // Add motivational message
        if summary.overallScore > 80 {
            dialog += " You're doing excellent with your health!"
        } else if summary.overallScore > 60 {
            dialog += " Good progress on your health goals."
        } else {
            dialog += " There's room for improvement in your health routine."
        }
        
        return .result(dialog: dialog) {
            HealthSummaryResult(summary: summary, timeframe: period)
        }
    }
}

@available(iOS 18.0, *)
struct HealthTrendsIntent: AppIntent {
    static var title: LocalizedStringResource = "Health Trends"
    static var description = IntentDescription("Analyze health data trends and patterns")
    
    @Parameter(title: "Data Type", description: "Which health metric to analyze")
    var dataType: TrendDataType
    
    @Parameter(title: "Time Frame", description: "How far back to analyze")
    var timeframe: TrendTimeframe?
    
    static var parameterSummary: some ParameterSummary {
        Summary("Analyze \(\.$dataType) trends for \(\.$timeframe)")
    }
    
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let healthManager = HealthDataManager.shared
        let period = timeframe ?? .lastWeek
        
        let trends = await healthManager.getHealthTrends(for: dataType, timeframe: period)
        
        if let trendData = trends {
            var dialog = "Your \(dataType.displayName) trend for \(period.displayName): "
            
            switch trendData.direction {
            case .increasing:
                dialog += "trending upward by \(String(format: "%.1f", trendData.changePercent))%"
            case .decreasing:
                dialog += "trending downward by \(String(format: "%.1f", abs(trendData.changePercent)))%"
            case .stable:
                dialog += "remaining stable"
            }
            
            dialog += ". Average: \(String(format: "%.1f", trendData.average))"
            
            // Add insight
            switch dataType {
            case .heartRate:
                if trendData.direction == .decreasing {
                    dialog += ". This could indicate improved cardiovascular fitness."
                }
            case .steps:
                if trendData.direction == .increasing {
                    dialog += ". Great job increasing your activity level!"
                }
            case .sleep:
                if trendData.direction == .increasing {
                    dialog += ". Better sleep duration is excellent for your health."
                }
            case .weight:
                if abs(trendData.changePercent) < 2 {
                    dialog += ". Your weight is staying consistent."
                }
            }
            
            return .result(dialog: dialog) {
                HealthTrendsResult(
                    dataType: dataType,
                    timeframe: period,
                    trends: trendData
                )
            }
        } else {
            return .result(dialog: "I don't have enough \(dataType.displayName) data for \(period.displayName) to analyze trends.")
        }
    }
}

// MARK: - Supporting Data Structures and Extensions

extension DateFormatter {
    static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()
}

// Additional enums and data structures would be defined here...
// (This file is already quite long, so I'll create separate files for the enums and data structures)
import Foundation
import SwiftUI
import Combine
import CoreML
import HealthKit
import SwiftData
import CoreMotion

/// Advanced Fitness & Exercise Optimization Engine
/// Provides comprehensive fitness tracking, AI-powered exercise optimization,
/// advanced training features, and social fitness tools
@MainActor
final class FitnessExerciseOptimizationEngine: ObservableObject {
    // MARK: - Published Properties
    @Published var workoutHistory: [WorkoutSession] = []
    @Published var fitnessLevel: FitnessLevel = .beginner
    @Published var performanceMetrics: PerformanceMetrics = PerformanceMetrics()
    @Published var aiWorkoutPlan: WorkoutPlan?
    @Published var recoveryStatus: RecoveryStatus = .recovered
    @Published var socialFeatures: [SocialFitnessFeature] = []
    @Published var errorMessage: String?
    @Published var isLoading: Bool = false
    @Published var fitnessSummary: FitnessSummary = FitnessSummary()
    @Published var analytics: FitnessAnalytics = FitnessAnalytics(
        performanceTrends: [],
        strengthProgress: [],
        enduranceProgress: [],
        flexibilityProgress: [],
        balanceProgress: [],
        insights: [],
        recommendations: [],
        currentActivity: "Idle",
        activityConfidence: 0.0,
        dailySteps: 0,
        dailyDistance: 0.0,
        activeCalories: 0.0,
        activityHistory: []
    )
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private let healthDataManager: HealthDataManager
    private let mlModelManager: MLModelManager
    private let notificationManager: NotificationManager
    private let persistenceManager = FitnessPersistenceManager.shared
    
    // Activity Recognition Properties
    private let activityRecognitionModel = RealActivityRecognitionModel()
    private let motionManager = CMMotionManager()
    private var motionUpdateTimer: Timer?
    
    // MARK: - Initialization
    init(healthDataManager: HealthDataManager, mlModelManager: MLModelManager, notificationManager: NotificationManager) {
        self.healthDataManager = healthDataManager
        self.mlModelManager = mlModelManager
        self.notificationManager = notificationManager
        setupSubscriptions()
        loadWorkoutHistory()
    }
    
    // MARK: - Setup
    private func setupSubscriptions() {
        // Subscribe to fitness data changes from HealthKit
        healthDataManager.fitnessDataPublisher
            .sink { [weak self] fitnessData in
                Task { @MainActor in
                    await self?.handleFitnessDataUpdate(fitnessData)
                }
            }
            .store(in: &cancellables)
        
        // Subscribe to ML model updates
        mlModelManager.modelUpdatePublisher
            .sink { [weak self] _ in
                Task { @MainActor in
                    await self?.regenerateAIWorkoutPlan()
                }
            }
            .store(in: &cancellables)
        
        // Subscribe to recovery status changes
        healthDataManager.recoveryStatusPublisher
            .sink { [weak self] recoveryStatus in
                Task { @MainActor in
                    await self?.updateRecoveryStatus(recoveryStatus)
                }
            }
            .store(in: &cancellables)
        
        // Start activity tracking
        startActivityTracking()
    }
    // MARK: - Fitness Tracking
    func recordWorkoutSession(_ session: WorkoutSession) async throws {
        isLoading = true
        errorMessage = nil
        
        do {
            // Save workout session to persistence
            try await persistenceManager.saveWorkoutSession(session)
            
            // Analyze performance
            await analyzeWorkoutPerformance(session)
            
            // Update fitness level
            await assessFitnessLevel()
            
            // Update recovery status
            await updateRecoveryStatus()
            
            // Update analytics
            await updateAnalytics()
            
            // Reload workout history
            await loadWorkoutHistory()
            
            // Send notification
            await notificationManager.sendWorkoutCompletionNotification(session)
            
        } catch {
            errorMessage = "Failed to record workout: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func analyzeWorkoutPerformance(_ session: WorkoutSession? = nil) async {
        do {
            let sessionsToAnalyze = session != nil ? [session!] : workoutHistory
            
            for workoutSession in sessionsToAnalyze {
                // Analyze performance metrics
                let performance = try await mlModelManager.analyzeWorkoutPerformance(workoutSession)
                
                // Update performance metrics
                performanceMetrics.updateMetrics(from: performance)
                
                // Incorporate activity recognition data
                if let activityInsights = await analyzeActivityData(for: workoutSession) {
                    // Add activity-based insights to performance analysis
                    performanceMetrics.updateWithActivityData(activityInsights)
                }
                
                // Analyze exercise form if video data is available
                if workoutSession.hasVideoData {
                    await analyzeExerciseForm(workoutSession)
                }
            }
            
            // Update fitness summary
            updateFitnessSummary()
            
        } catch {
            errorMessage = "Failed to analyze workout performance: \(error.localizedDescription)"
        }
    }
    
    func assessFitnessLevel() async {
        do {
            // Use ML model to assess fitness level based on workout history and performance
            let assessedLevel = try await mlModelManager.assessFitnessLevel(
                workoutHistory: workoutHistory,
                performanceMetrics: performanceMetrics
            )
            
            fitnessLevel = assessedLevel
            
            // Update fitness summary
            updateFitnessSummary()
            
        } catch {
            errorMessage = "Failed to assess fitness level: \(error.localizedDescription)"
        }
    }
    
    func analyzeExerciseForm(_ session: WorkoutSession) async {
        do {
            // Use computer vision to analyze exercise form
            let formAnalysis = try await mlModelManager.analyzeExerciseForm(session)
            
            // Update session with form analysis
            session.formAnalysis = formAnalysis
            
            // Save updated session
            try await persistenceManager.saveWorkoutSession(session)
            
            // Send form feedback notification if needed
            if formAnalysis.needsImprovement {
                await notificationManager.sendFormFeedbackNotification(formAnalysis)
            }
            
        } catch {
            errorMessage = "Failed to analyze exercise form: \(error.localizedDescription)"
        }
    }
    
    func updateRecoveryStatus(_ newStatus: RecoveryStatus? = nil) async {
        do {
            if let status = newStatus {
                recoveryStatus = status
            } else {
                // Calculate recovery status based on recent workouts and health data
                let calculatedStatus = try await mlModelManager.calculateRecoveryStatus(
                    recentWorkouts: Array(workoutHistory.prefix(7)),
                    healthData: healthDataManager.currentHealthData
                )
                recoveryStatus = calculatedStatus
            }
            
            // Update fitness summary
            updateFitnessSummary()
            
        } catch {
            errorMessage = "Failed to update recovery status: \(error.localizedDescription)"
        }
    }
    
    func updateFitnessSummary() {
        // Calculate comprehensive fitness summary
        let totalWorkouts = workoutHistory.count
        let totalDuration = workoutHistory.reduce(0) { $0 + $1.duration }
        let heartRates = workoutHistory.compactMap { $0.averageHeartRate }
        let averageHeartRate = heartRates.isEmpty ? 0.0 : heartRates.reduce(0, +) / Double(heartRates.count)
        let totalCalories = workoutHistory.reduce(0) { $0 + $1.caloriesBurned }
        
        fitnessSummary = FitnessSummary(
            totalWorkouts: totalWorkouts,
            totalDuration: totalDuration,
            averageHeartRate: averageHeartRate,
            totalCalories: totalCalories,
            fitnessLevel: fitnessLevel,
            recoveryStatus: recoveryStatus,
            performanceTrend: calculatePerformanceTrend(),
            weeklyGoalProgress: calculateWeeklyGoalProgress()
        )
    }
    
    // MARK: - Activity Recognition Methods
    
    private func startActivityTracking() {
        guard motionManager.isDeviceMotionAvailable else {
            print("Device motion not available")
            return
        }
        
        // Start device motion updates at 50Hz
        motionManager.deviceMotionUpdateInterval = 1.0 / 50.0
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, error in
            guard let motion = motion, error == nil else { return }
            
            Task { @MainActor in
                await self?.processMotionData(motion)
            }
        }
        
        // Also start activity updates for additional context
        if CMMotionActivityManager.isActivityAvailable() {
            let activityManager = CMMotionActivityManager()
            activityManager.startActivityUpdates(to: .main) { [weak self] activity in
                guard let activity = activity else { return }
                
                Task { @MainActor in
                    await self?.processActivityData(activity)
                }
            }
        }
    }
    
    private func processMotionData(_ motion: CMDeviceMotion) async {
        // Convert Core Motion data to our format
        let motionData = RealActivityRecognitionModel.motionData(from: motion)
        
        // Classify activity
        let prediction = await activityRecognitionModel.classifyActivity(from: motionData)
        
        // Update analytics with activity data
        analytics.currentActivity = prediction.activity.rawValue
        analytics.activityConfidence = prediction.confidence
        
        // Get current metrics
        let metrics = activityRecognitionModel.getCurrentMetrics()
        analytics.dailySteps = metrics.totalSteps
        analytics.dailyDistance = metrics.distance
        analytics.activeCalories = metrics.activeCalories
        
        // Add to history
        let dataPoint = ActivityDataPoint(
            timestamp: Date(),
            activity: prediction.activity.rawValue,
            confidence: prediction.confidence,
            steps: metrics.totalSteps,
            distance: metrics.distance,
            calories: metrics.activeCalories
        )
        analytics.activityHistory.append(dataPoint)
        
        // Limit history to last 24 hours
        let cutoffDate = Date().addingTimeInterval(-24 * 3600)
        analytics.activityHistory = analytics.activityHistory.filter { $0.timestamp > cutoffDate }
        
        // If activity changes significantly during workout, update the session
        if let currentWorkout = workoutHistory.first(where: { isWorkoutActive($0) }),
           prediction.activity != .idle && prediction.confidence > 0.7 {
            // Update workout type based on detected activity
            updateWorkoutTypeBasedOnActivity(currentWorkout, activity: prediction.activity)
        }
    }
    
    private func processActivityData(_ activity: CMMotionActivity) async {
        // Use Core Motion activity as additional context
        let activityType = RealActivityRecognitionModel.activityType(from: activity)
        
        // This provides additional validation for our ML predictions
        print("Core Motion Activity: \(activityType.rawValue)")
    }
    
    private func isWorkoutActive(_ workout: WorkoutSession) -> Bool {
        // Check if workout is currently active (within last hour)
        let timeSinceStart = Date().timeIntervalSince(workout.timestamp)
        return timeSinceStart < workout.duration + 300 // 5 minute buffer
    }
    
    private func updateWorkoutTypeBasedOnActivity(_ workout: WorkoutSession, activity: RealActivityRecognitionModel.ActivityType) {
        // Map detected activity to workout type
        let mappedType: WorkoutType
        switch activity {
        case .running:
            mappedType = .running
        case .cycling:
            mappedType = .cycling
        case .walking:
            mappedType = .cardio
        case .stairs:
            mappedType = .hiit
        case .workout:
            mappedType = .strength
        default:
            return // Don't update for idle or driving
        }
        
        // Only update if significantly different
        if workout.workoutType != mappedType {
            // This would update the workout type based on detected activity
            print("Detected activity change: \(workout.workoutType.rawValue) -> \(mappedType.rawValue)")
        }
    }
    
    func stopActivityTracking() {
        motionManager.stopDeviceMotionUpdates()
        motionUpdateTimer?.invalidate()
        motionUpdateTimer = nil
    }
    
    private func analyzeActivityData(for session: WorkoutSession) async -> ActivityInsights? {
        // Find activity data points during the workout session
        let sessionStart = session.timestamp
        let sessionEnd = session.timestamp.addingTimeInterval(session.duration)
        
        let relevantActivityData = analytics.activityHistory.filter { dataPoint in
            dataPoint.timestamp >= sessionStart && dataPoint.timestamp <= sessionEnd
        }
        
        guard !relevantActivityData.isEmpty else { return nil }
        
        // Calculate activity insights
        let totalSteps = relevantActivityData.last?.steps ?? 0
        let totalDistance = relevantActivityData.last?.distance ?? 0.0
        let avgConfidence = relevantActivityData.map { $0.confidence }.reduce(0, +) / Double(relevantActivityData.count)
        
        // Determine dominant activity
        let activityCounts = Dictionary(grouping: relevantActivityData, by: { $0.activity })
            .mapValues { $0.count }
        let dominantActivity = activityCounts.max(by: { $0.value < $1.value })?.key ?? "Unknown"
        
        return ActivityInsights(
            dominantActivity: dominantActivity,
            totalSteps: totalSteps,
            totalDistance: totalDistance,
            averageConfidence: avgConfidence,
            activityVariation: Double(activityCounts.count)
        )
    }
    
    func logWorkout(_ session: WorkoutSession) {
        Task {
            do {
                try await recordWorkoutSession(session)
            } catch {
                errorMessage = "Failed to log workout: \(error.localizedDescription)"
            }
        }
    }
    // MARK: - AI-Powered Exercise Optimization
    func generateAIWorkoutPlan() async throws {
        isLoading = true
        errorMessage = nil
        
        do {
            // Generate personalized AI workout plan
            let plan = try await mlModelManager.generateWorkoutPlan(
                fitnessLevel: fitnessLevel,
                recoveryStatus: recoveryStatus,
                performanceMetrics: performanceMetrics,
                workoutHistory: workoutHistory,
                userPreferences: getUserPreferences()
            )
            
            aiWorkoutPlan = plan
            
            // Save plan to persistence
            try await persistenceManager.saveWorkoutPlan(plan)
            
        } catch {
            errorMessage = "Failed to generate workout plan: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func suggestProgressiveOverload() async {
        do {
            let suggestions = try await mlModelManager.suggestProgressiveOverload(
                currentWorkoutPlan: aiWorkoutPlan,
                performanceMetrics: performanceMetrics,
                recoveryStatus: recoveryStatus
            )
            
            // Update workout plan with progressive overload suggestions
            if let plan = aiWorkoutPlan {
                plan.updateWithProgressiveOverload(suggestions)
                try await persistenceManager.saveWorkoutPlan(plan)
            }
            
        } catch {
            errorMessage = "Failed to suggest progressive overload: \(error.localizedDescription)"
        }
    }
    
    func suggestExerciseVariations() async {
        do {
            let variations = try await mlModelManager.suggestExerciseVariations(
                currentExercises: aiWorkoutPlan?.exercises ?? [],
                fitnessLevel: fitnessLevel,
                userPreferences: getUserPreferences()
            )
            
            // Update workout plan with exercise variations
            if let plan = aiWorkoutPlan {
                plan.updateWithExerciseVariations(variations)
                try await persistenceManager.saveWorkoutPlan(plan)
            }
            
        } catch {
            errorMessage = "Failed to suggest exercise variations: \(error.localizedDescription)"
        }
    }
    
    func suggestInjuryPreventionStrategies() async {
        do {
            let strategies = try await mlModelManager.suggestInjuryPreventionStrategies(
                workoutHistory: workoutHistory,
                performanceMetrics: performanceMetrics,
                recoveryStatus: recoveryStatus
            )
            
            // Send injury prevention notification
            await notificationManager.sendInjuryPreventionNotification(strategies)
            
        } catch {
            errorMessage = "Failed to suggest injury prevention strategies: \(error.localizedDescription)"
        }
    }
    // MARK: - Advanced Training Features
    func planPeriodization() async {
        do {
            let periodizationPlan = try await mlModelManager.planPeriodization(
                fitnessLevel: fitnessLevel,
                performanceMetrics: performanceMetrics,
                userGoals: getUserGoals()
            )
            
            // Update workout plan with periodization
            if let plan = aiWorkoutPlan {
                plan.updateWithPeriodization(periodizationPlan)
                try await persistenceManager.saveWorkoutPlan(plan)
            }
            
        } catch {
            errorMessage = "Failed to plan periodization: \(error.localizedDescription)"
        }
    }
    
    func optimizeCrossTraining() async {
        do {
            let crossTrainingPlan = try await mlModelManager.optimizeCrossTraining(
                currentWorkoutPlan: aiWorkoutPlan,
                fitnessLevel: fitnessLevel,
                recoveryStatus: recoveryStatus
            )
            
            // Update workout plan with cross-training
            if let plan = aiWorkoutPlan {
                plan.updateWithCrossTraining(crossTrainingPlan)
                try await persistenceManager.saveWorkoutPlan(plan)
            }
            
        } catch {
            errorMessage = "Failed to optimize cross-training: \(error.localizedDescription)"
        }
    }
    
    func planSportSpecificTraining() async {
        do {
            let sportTrainingPlan = try await mlModelManager.planSportSpecificTraining(
                sport: getUserSport(),
                fitnessLevel: fitnessLevel,
                performanceMetrics: performanceMetrics
            )
            
            // Update workout plan with sport-specific training
            if let plan = aiWorkoutPlan {
                plan.updateWithSportTraining(sportTrainingPlan)
                try await persistenceManager.saveWorkoutPlan(plan)
            }
            
        } catch {
            errorMessage = "Failed to plan sport-specific training: \(error.localizedDescription)"
        }
    }
    
    func prepareForCompetition() async {
        do {
            let competitionPlan = try await mlModelManager.prepareForCompetition(
                competitionDate: getCompetitionDate(),
                currentFitnessLevel: fitnessLevel,
                performanceMetrics: performanceMetrics
            )
            
            // Update workout plan for competition preparation
            if let plan = aiWorkoutPlan {
                plan.updateForCompetition(competitionPlan)
                try await persistenceManager.saveWorkoutPlan(plan)
            }
            
        } catch {
            errorMessage = "Failed to prepare for competition: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Social Fitness Features
    func shareWorkout(_ session: WorkoutSession) async {
        do {
            // Share workout with community
            try await socialFeaturesManager.shareWorkout(session)
            
            // Update social features
            await loadSocialFeatures()
            
        } catch {
            errorMessage = "Failed to share workout: \(error.localizedDescription)"
        }
    }
    
    func joinGroupTrainingSession() async {
        do {
            // Join group training session
            let groupSession = try await socialFeaturesManager.joinGroupTrainingSession()
            
            // Add to social features
            socialFeatures.append(groupSession)
            
        } catch {
            errorMessage = "Failed to join group training session: \(error.localizedDescription)"
        }
    }
    
    func connectWithTrainer() async {
        do {
            // Connect with personal trainer
            let trainerConnection = try await socialFeaturesManager.connectWithTrainer()
            
            // Add to social features
            socialFeatures.append(trainerConnection)
            
        } catch {
            errorMessage = "Failed to connect with trainer: \(error.localizedDescription)"
        }
    }
    
    func participateInCommunityChallenge() async {
        do {
            // Participate in community challenge
            let challenge = try await socialFeaturesManager.participateInCommunityChallenge()
            
            // Add to social features
            socialFeatures.append(challenge)
            
        } catch {
            errorMessage = "Failed to participate in community challenge: \(error.localizedDescription)"
        }
    }
    
    func joinGroupSession(_ group: SocialFitnessFeature) {
        Task {
            do {
                try await socialFeaturesManager.joinGroupSession(group)
                
                // Update social features
                await loadSocialFeatures()
                
            } catch {
                errorMessage = "Failed to join group session: \(error.localizedDescription)"
            }
        }
    }
    
    // MARK: - Analytics
    func updateAnalytics() async {
        do {
            var updatedAnalytics = try await mlModelManager.generateFitnessAnalytics(
                workoutHistory: workoutHistory,
                performanceMetrics: performanceMetrics,
                fitnessLevel: fitnessLevel
            )
            
            // Preserve activity recognition data
            updatedAnalytics.currentActivity = analytics.currentActivity
            updatedAnalytics.activityConfidence = analytics.activityConfidence
            updatedAnalytics.dailySteps = analytics.dailySteps
            updatedAnalytics.dailyDistance = analytics.dailyDistance
            updatedAnalytics.activeCalories = analytics.activeCalories
            updatedAnalytics.activityHistory = analytics.activityHistory
            
            // Add activity-based insights
            if !analytics.activityHistory.isEmpty {
                let activityInsight = FitnessInsight(
                    title: "Activity Recognition Active",
                    description: "Currently detected as \(analytics.currentActivity) with \(Int(analytics.activityConfidence * 100))% confidence",
                    category: .performance,
                    confidence: analytics.activityConfidence
                )
                updatedAnalytics.insights.append(activityInsight)
                
                // Add step goal progress
                let stepGoalProgress = Double(analytics.dailySteps) / 10000.0
                if stepGoalProgress >= 1.0 {
                    let stepInsight = FitnessInsight(
                        title: "Daily Step Goal Achieved!",
                        description: "You've walked \(analytics.dailySteps) steps today",
                        category: .performance,
                        confidence: 1.0
                    )
                    updatedAnalytics.insights.append(stepInsight)
                }
            }
            
            analytics = updatedAnalytics
            
        } catch {
            errorMessage = "Failed to update analytics: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Data Loading
    private func loadWorkoutHistory() async {
        do {
            let history = try await persistenceManager.loadWorkoutHistory()
            workoutHistory = history
        } catch {
            errorMessage = "Failed to load workout history: \(error.localizedDescription)"
        }
    }
    
    private func loadSocialFeatures() async {
        do {
            let features = try await socialFeaturesManager.loadSocialFeatures()
            socialFeatures = features
        } catch {
            errorMessage = "Failed to load social features: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Helper Methods
    private func handleFitnessDataUpdate(_ fitnessData: FitnessData) async {
        // Handle fitness data updates from HealthKit
        await updateAnalytics()
        await assessFitnessLevel()
    }
    
    private func regenerateAIWorkoutPlan() async {
        do {
            try await generateAIWorkoutPlan()
        } catch {
            errorMessage = "Failed to regenerate workout plan: \(error.localizedDescription)"
        }
    }
    
    private func getUserPreferences() -> UserFitnessPreferences {
        // Load user fitness preferences from persistence
        return persistenceManager.loadUserPreferences()
    }
    
    private func getUserGoals() -> [FitnessGoal] {
        // Load user fitness goals from persistence
        return persistenceManager.loadUserGoals()
    }
    
    private func getUserSport() -> Sport {
        // Load user's primary sport from persistence
        return persistenceManager.loadUserSport()
    }
    
    private func getCompetitionDate() -> Date? {
        // Load competition date from persistence
        return persistenceManager.loadCompetitionDate()
    }
    
    private func calculatePerformanceTrend() -> PerformanceTrend {
        // Calculate performance trend based on recent workouts
        let recentWorkouts = Array(workoutHistory.prefix(10))
        return PerformanceTrend.calculate(from: recentWorkouts)
    }
    
    private func calculateWeeklyGoalProgress() -> Double {
        // Calculate weekly goal progress
        let weeklyGoal = getUserGoals().first { $0.type == .weeklyWorkouts }
        let completedWorkouts = workoutHistory.filter { 
            Calendar.current.isDate($0.timestamp, equalTo: Date(), toGranularity: .weekOfYear)
        }.count
        
        guard let goal = weeklyGoal else { return 0.0 }
        return Double(completedWorkouts) / goal.target
    }
}
// MARK: - Supporting Types

// MARK: - Core Fitness Types

struct FitnessSummary {
    let totalWorkouts: Int
    let totalDuration: TimeInterval
    let averageHeartRate: Double
    let totalCalories: Double
    let fitnessLevel: FitnessLevel
    let recoveryStatus: RecoveryStatus
    let performanceTrend: PerformanceTrend
    let weeklyGoalProgress: Double
}

struct WorkoutSession: Identifiable, Codable {
    let id = UUID()
    let timestamp: Date
    let duration: TimeInterval
    let workoutType: WorkoutType
    let caloriesBurned: Double
    let averageHeartRate: Double?
    let maxHeartRate: Double?
    let exercises: [Exercise]
    let notes: String?
    var formAnalysis: ExerciseFormAnalysis?
    var hasVideoData: Bool { formAnalysis != nil }
    
    init(timestamp: Date = Date(), duration: TimeInterval, workoutType: WorkoutType, caloriesBurned: Double, averageHeartRate: Double? = nil, maxHeartRate: Double? = nil, exercises: [Exercise] = [], notes: String? = nil) {
        self.timestamp = timestamp
        self.duration = duration
        self.workoutType = workoutType
        self.caloriesBurned = caloriesBurned
        self.averageHeartRate = averageHeartRate
        self.maxHeartRate = maxHeartRate
        self.exercises = exercises
        self.notes = notes
    }
}

enum WorkoutType: String, CaseIterable, Codable {
    case strength = "Strength Training"
    case cardio = "Cardio"
    case yoga = "Yoga"
    case pilates = "Pilates"
    case running = "Running"
    case cycling = "Cycling"
    case swimming = "Swimming"
    case hiit = "HIIT"
    case flexibility = "Flexibility"
    case sports = "Sports"
}

struct Exercise: Identifiable, Codable {
    let id = UUID()
    let name: String
    let sets: [ExerciseSet]
    let restTime: TimeInterval
    let notes: String?
}

struct ExerciseSet: Identifiable, Codable {
    let id = UUID()
    let reps: Int?
    let weight: Double?
    let duration: TimeInterval?
    let distance: Double?
    let intensity: ExerciseIntensity
}

enum ExerciseIntensity: String, CaseIterable, Codable {
    case light = "Light"
    case moderate = "Moderate"
    case vigorous = "Vigorous"
    case maximum = "Maximum"
}

struct ExerciseFormAnalysis: Codable {
    let overallScore: Double
    let needsImprovement: Bool
    let feedback: [String]
    let recommendations: [String]
}

enum FitnessLevel: String, CaseIterable, Codable {
    case beginner = "Beginner"
    case intermediate = "Intermediate"
    case advanced = "Advanced"
    case elite = "Elite"
}

struct PerformanceMetrics: Codable {
    var strengthScore: Double = 0.0
    var enduranceScore: Double = 0.0
    var flexibilityScore: Double = 0.0
    var balanceScore: Double = 0.0
    var overallScore: Double = 0.0
    var activityScore: Double = 0.0
    
    mutating func updateMetrics(from performance: PerformanceAnalysis) {
        strengthScore = performance.strengthScore
        enduranceScore = performance.enduranceScore
        flexibilityScore = performance.flexibilityScore
        balanceScore = performance.balanceScore
        overallScore = (strengthScore + enduranceScore + flexibilityScore + balanceScore) / 4.0
    }
    
    mutating func updateWithActivityData(_ insights: ActivityInsights) {
        // Update activity score based on insights
        activityScore = min(100, (Double(insights.totalSteps) / 10000.0) * 100)
        
        // Adjust endurance score based on distance covered
        let distanceBonus = min(20, insights.totalDistance / 1000.0 * 2) // 2 points per km
        enduranceScore = min(100, enduranceScore + distanceBonus)
        
        // Recalculate overall score including activity
        overallScore = (strengthScore + enduranceScore + flexibilityScore + balanceScore + activityScore) / 5.0
    }
}

struct PerformanceAnalysis: Codable {
    let strengthScore: Double
    let enduranceScore: Double
    let flexibilityScore: Double
    let balanceScore: Double
}

enum RecoveryStatus: String, CaseIterable, Codable {
    case recovered = "Recovered"
    case lightFatigue = "Light Fatigue"
    case moderateFatigue = "Moderate Fatigue"
    case heavyFatigue = "Heavy Fatigue"
    case overtraining = "Overtraining"
}

struct PerformanceTrend: Codable {
    let direction: TrendDirection
    let magnitude: Double
    let confidence: Double
    
    static func calculate(from workouts: [WorkoutSession]) -> PerformanceTrend {
        // Simplified trend calculation
        guard workouts.count >= 2 else {
            return PerformanceTrend(direction: .stable, magnitude: 0.0, confidence: 0.0)
        }
        
        let recentWorkouts = Array(workouts.prefix(5))
        let olderWorkouts = Array(workouts.suffix(5))
        
        let recentAvg = recentWorkouts.reduce(0.0) { $0 + $1.caloriesBurned } / Double(recentWorkouts.count)
        let olderAvg = olderWorkouts.reduce(0.0) { $0 + $1.caloriesBurned } / Double(olderWorkouts.count)
        
        let change = recentAvg - olderAvg
        let magnitude = abs(change) / olderAvg
        
        let direction: TrendDirection
        if change > 0.1 {
            direction = .improving
        } else if change < -0.1 {
            direction = .declining
        } else {
            direction = .stable
        }
        
        return PerformanceTrend(direction: direction, magnitude: magnitude, confidence: 0.8)
    }
}

enum TrendDirection: String, Codable {
    case improving = "Improving"
    case stable = "Stable"
    case declining = "Declining"
}

// MARK: - AI Workout Plan Types

struct WorkoutPlan: Codable {
    let id = UUID()
    let name: String
    let description: String
    let duration: Int // in weeks
    let fitnessLevel: FitnessLevel
    let exercises: [PlannedExercise]
    let progression: ProgressionPlan
    let recoveryDays: [Int] // day numbers
    var periodization: PeriodizationPlan?
    var crossTraining: CrossTrainingPlan?
    var sportTraining: SportTrainingPlan?
    var competitionPlan: CompetitionPlan?
    
    mutating func updateWithProgressiveOverload(_ suggestions: [ProgressiveOverloadSuggestion]) {
        // Update exercises with progressive overload suggestions
        for suggestion in suggestions {
            if let index = exercises.firstIndex(where: { $0.id == suggestion.exerciseId }) {
                exercises[index].updateWithSuggestion(suggestion)
            }
        }
    }
    
    mutating func updateWithExerciseVariations(_ variations: [ExerciseVariation]) {
        // Update exercises with variations
        for variation in variations {
            if let index = exercises.firstIndex(where: { $0.id == variation.exerciseId }) {
                exercises[index].updateWithVariation(variation)
            }
        }
    }
    
    mutating func updateWithPeriodization(_ plan: PeriodizationPlan) {
        self.periodization = plan
    }
    
    mutating func updateWithCrossTraining(_ plan: CrossTrainingPlan) {
        self.crossTraining = plan
    }
    
    mutating func updateWithSportTraining(_ plan: SportTrainingPlan) {
        self.sportTraining = plan
    }
    
    mutating func updateForCompetition(_ plan: CompetitionPlan) {
        self.competitionPlan = plan
    }
}

struct PlannedExercise: Identifiable, Codable {
    let id = UUID()
    let name: String
    let sets: Int
    let reps: Int?
    let weight: Double?
    let duration: TimeInterval?
    let restTime: TimeInterval
    let progression: ExerciseProgression
    
    mutating func updateWithSuggestion(_ suggestion: ProgressiveOverloadSuggestion) {
        // Update exercise based on progressive overload suggestion
        if let newWeight = suggestion.suggestedWeight {
            self.weight = newWeight
        }
        if let newReps = suggestion.suggestedReps {
            self.reps = newReps
        }
    }
    
    mutating func updateWithVariation(_ variation: ExerciseVariation) {
        // Update exercise with variation
        self.name = variation.variationName
    }
}

struct ExerciseProgression: Codable {
    let type: ProgressionType
    let increment: Double
    let frequency: Int // every N workouts
}

enum ProgressionType: String, Codable {
    case weight = "Weight"
    case reps = "Reps"
    case duration = "Duration"
    case intensity = "Intensity"
}

struct ProgressiveOverloadSuggestion: Codable {
    let exerciseId: UUID
    let suggestedWeight: Double?
    let suggestedReps: Int?
    let reason: String
}

struct ExerciseVariation: Codable {
    let exerciseId: UUID
    let variationName: String
    let difficulty: FitnessLevel
    let benefits: [String]
}

struct ProgressionPlan: Codable {
    let type: ProgressionType
    let schedule: [Int: Double] // week number -> increment
}

struct PeriodizationPlan: Codable {
    let phases: [TrainingPhase]
    let transitions: [PhaseTransition]
}

struct TrainingPhase: Codable {
    let name: String
    let duration: Int // weeks
    let focus: String
    let intensity: Double
}

struct PhaseTransition: Codable {
    let fromPhase: String
    let toPhase: String
    let duration: Int // days
}

struct CrossTrainingPlan: Codable {
    let activities: [CrossTrainingActivity]
    let schedule: [Int: [CrossTrainingActivity]] // day number -> activities
}

struct CrossTrainingActivity: Codable {
    let name: String
    let duration: TimeInterval
    let intensity: ExerciseIntensity
    let benefits: [String]
}

struct SportTrainingPlan: Codable {
    let sport: Sport
    let skills: [SportSkill]
    let drills: [SportDrill]
}

struct SportSkill: Codable {
    let name: String
    let importance: Double
    let currentLevel: Double
    let targetLevel: Double
}

struct SportDrill: Codable {
    let name: String
    let duration: TimeInterval
    let repetitions: Int
    let focus: String
}

struct CompetitionPlan: Codable {
    let competitionDate: Date
    let phases: [CompetitionPhase]
    let tapering: TaperingPlan
}

struct CompetitionPhase: Codable {
    let name: String
    let duration: Int // weeks
    let focus: String
    let volume: Double
    let intensity: Double
}

struct TaperingPlan: Codable {
    let duration: Int // weeks
    let volumeReduction: Double
    let intensityMaintenance: Double
}

// MARK: - Social Fitness Types

struct SocialFitnessFeature: Identifiable, Codable {
    let id = UUID()
    let type: SocialFeatureType
    let name: String
    let description: String
    let participants: Int
    let startTime: Date?
    let duration: TimeInterval?
    let location: String?
    let isActive: Bool
}

enum SocialFeatureType: String, Codable {
    case groupTraining = "Group Training"
    case challenge = "Challenge"
    case trainerSession = "Trainer Session"
    case communityEvent = "Community Event"
}

// MARK: - Analytics Types

struct FitnessAnalytics: Codable {
    let performanceTrends: [PerformanceTrend]
    let strengthProgress: [DataPoint]
    let enduranceProgress: [DataPoint]
    let flexibilityProgress: [DataPoint]
    let balanceProgress: [DataPoint]
    let insights: [FitnessInsight]
    let recommendations: [FitnessRecommendation]
    
    // Activity Recognition Data
    var currentActivity: String = "Idle"
    var activityConfidence: Double = 0.0
    var dailySteps: Int = 0
    var dailyDistance: Double = 0.0 // meters
    var activeCalories: Double = 0.0
    var activityHistory: [ActivityDataPoint] = []
}

struct DataPoint: Codable {
    let date: Date
    let value: Double
}

struct ActivityDataPoint: Codable {
    let timestamp: Date
    let activity: String
    let confidence: Double
    let steps: Int
    let distance: Double
    let calories: Double
}

struct ActivityInsights {
    let dominantActivity: String
    let totalSteps: Int
    let totalDistance: Double
    let averageConfidence: Double
    let activityVariation: Double
}

struct FitnessInsight: Codable {
    let title: String
    let description: String
    let category: InsightCategory
    let confidence: Double
}

enum InsightCategory: String, Codable {
    case performance = "Performance"
    case recovery = "Recovery"
    case progression = "Progression"
    case injury = "Injury Prevention"
}

struct FitnessRecommendation: Codable {
    let title: String
    let description: String
    let priority: Priority
    let actionable: Bool
    let actionItems: [String]
}

enum Priority: String, Codable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case critical = "Critical"
}

// MARK: - User Preferences Types

struct UserFitnessPreferences: Codable {
    let preferredWorkoutTypes: [WorkoutType]
    let availableTime: TimeInterval
    let equipment: [String]
    let location: WorkoutLocation
    let intensity: ExerciseIntensity
}

enum WorkoutLocation: String, Codable {
    case home = "Home"
    case gym = "Gym"
    case outdoors = "Outdoors"
    case pool = "Pool"
}

struct FitnessGoal: Codable {
    let id = UUID()
    let type: GoalType
    let target: Double
    let deadline: Date
    let unit: String
}

enum GoalType: String, Codable {
    case weightLoss = "Weight Loss"
    case muscleGain = "Muscle Gain"
    case endurance = "Endurance"
    case strength = "Strength"
    case flexibility = "Flexibility"
    case weeklyWorkouts = "Weekly Workouts"
}

enum Sport: String, Codable {
    case running = "Running"
    case cycling = "Cycling"
    case swimming = "Swimming"
    case tennis = "Tennis"
    case basketball = "Basketball"
    case soccer = "Soccer"
    case golf = "Golf"
    case yoga = "Yoga"
    case pilates = "Pilates"
    case martialArts = "Martial Arts"
    case other = "Other"
}

// MARK: - Data Types

struct FitnessData: Codable {
    let heartRate: [HeartRateDataPoint]
    let steps: Int
    let calories: Double
    let activeMinutes: TimeInterval
    let workouts: [WorkoutSession]
}

struct HeartRateDataPoint: Codable {
    let timestamp: Date
    let value: Double
}

// MARK: - Manager Types

class FitnessPersistenceManager {
    static let shared = FitnessPersistenceManager()
    
    private init() {}
    
    func saveWorkoutSession(_ session: WorkoutSession) async throws {
        let context = ModelContainer.shared.mainContext
        let entity = WorkoutSessionEntity()
        entity.id = session.id
        entity.timestamp = session.timestamp
        entity.duration = session.duration
        entity.workoutType = session.workoutType.rawValue
        entity.caloriesBurned = session.caloriesBurned
        entity.averageHeartRate = session.averageHeartRate
        entity.maxHeartRate = session.maxHeartRate
        entity.exercises = session.exercises
        entity.notes = session.notes
        
        context.insert(entity)
        try context.save()
    }
    
    func saveWorkoutPlan(_ plan: WorkoutPlan) async throws {
        let context = ModelContainer.shared.mainContext
        let entity = WorkoutPlanEntity()
        entity.id = plan.id
        entity.name = plan.name
        entity.description = plan.description
        entity.duration = plan.duration
        entity.fitnessLevel = plan.fitnessLevel.rawValue
        entity.exercises = plan.exercises
        entity.progression = plan.progression
        entity.recoveryDays = plan.recoveryDays
        
        context.insert(entity)
        try context.save()
    }
    
    func loadWorkoutHistory() async throws -> [WorkoutSession] {
        let context = ModelContainer.shared.mainContext
        let descriptor = FetchDescriptor<WorkoutSessionEntity>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        let entities = try context.fetch(descriptor)
        
        return entities.map { entity in
            WorkoutSession(
                timestamp: entity.timestamp,
                duration: entity.duration,
                workoutType: WorkoutType(rawValue: entity.workoutType) ?? .strength,
                caloriesBurned: entity.caloriesBurned,
                averageHeartRate: entity.averageHeartRate,
                maxHeartRate: entity.maxHeartRate,
                exercises: entity.exercises,
                notes: entity.notes
            )
        }
    }
    
    func loadUserPreferences() -> UserFitnessPreferences {
        // Load from UserDefaults or SwiftData
        return UserFitnessPreferences(
            preferredWorkoutTypes: [.strength, .cardio],
            availableTime: 3600, // 1 hour
            equipment: ["dumbbells", "resistance bands"],
            location: .home,
            intensity: .moderate
        )
    }
    
    func loadUserGoals() -> [FitnessGoal] {
        // Load from UserDefaults or SwiftData
        return [
            FitnessGoal(type: .weeklyWorkouts, target: 3, deadline: Date().addingTimeInterval(7*24*3600), unit: "workouts"),
            FitnessGoal(type: .strength, target: 100, deadline: Date().addingTimeInterval(30*24*3600), unit: "kg")
        ]
    }
    
    func loadUserSport() -> Sport {
        // Load from UserDefaults or SwiftData
        return .running
    }
    
    func loadCompetitionDate() -> Date? {
        // Load from UserDefaults or SwiftData
        return nil
    }
}

class SocialFeaturesManager {
    func shareWorkout(_ session: WorkoutSession) async throws {
        // Implement social sharing functionality
        try await Task.sleep(nanoseconds: 1_000_000_000) // Simulate network request
    }
    
    func joinGroupTrainingSession() async throws -> SocialFitnessFeature {
        // Implement group training session joining
        try await Task.sleep(nanoseconds: 1_000_000_000) // Simulate network request
        return SocialFitnessFeature(
            type: .groupTraining,
            name: "Morning Cardio Group",
            description: "High-intensity cardio session",
            participants: 12,
            startTime: Date().addingTimeInterval(3600),
            duration: 3600,
            location: "Central Park",
            isActive: true
        )
    }
    
    func connectWithTrainer() async throws -> SocialFitnessFeature {
        // Implement trainer connection
        try await Task.sleep(nanoseconds: 1_000_000_000) // Simulate network request
        return SocialFitnessFeature(
            type: .trainerSession,
            name: "Personal Training Session",
            description: "One-on-one training with certified trainer",
            participants: 1,
            startTime: Date().addingTimeInterval(7200),
            duration: 3600,
            location: "Local Gym",
            isActive: true
        )
    }
    
    func participateInCommunityChallenge() async throws -> SocialFitnessFeature {
        // Implement community challenge participation
        try await Task.sleep(nanoseconds: 1_000_000_000) // Simulate network request
        return SocialFitnessFeature(
            type: .challenge,
            name: "30-Day Fitness Challenge",
            description: "Complete 30 days of consistent workouts",
            participants: 150,
            startTime: Date(),
            duration: 30*24*3600,
            location: "Global",
            isActive: true
        )
    }
    
    func joinGroupSession(_ group: SocialFitnessFeature) async throws {
        // Implement group session joining
        try await Task.sleep(nanoseconds: 1_000_000_000) // Simulate network request
    }
    
    func loadSocialFeatures() async throws -> [SocialFitnessFeature] {
        // Load social features from network or local storage
        try await Task.sleep(nanoseconds: 500_000_000) // Simulate network request
        return []
    }
}

// MARK: - SwiftData Entities

@Model
class WorkoutSessionEntity {
    var id: UUID
    var timestamp: Date
    var duration: TimeInterval
    var workoutType: String
    var caloriesBurned: Double
    var averageHeartRate: Double?
    var maxHeartRate: Double?
    var exercises: [Exercise]
    var notes: String?
    
    init() {
        self.id = UUID()
        self.timestamp = Date()
        self.duration = 0
        self.workoutType = ""
        self.caloriesBurned = 0
        self.exercises = []
    }
}

@Model
class WorkoutPlanEntity {
    var id: UUID
    var name: String
    var description: String
    var duration: Int
    var fitnessLevel: String
    var exercises: [PlannedExercise]
    var progression: ProgressionPlan
    var recoveryDays: [Int]
    
    init() {
        self.id = UUID()
        self.name = ""
        self.description = ""
        self.duration = 0
        self.fitnessLevel = ""
        self.exercises = []
        self.progression = ProgressionPlan(type: .weight, schedule: [:])
        self.recoveryDays = []
    }
} 
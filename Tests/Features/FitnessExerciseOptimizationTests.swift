import XCTest
@testable import MainApp

/// Unit tests for Fitness & Exercise Optimization Engine
final class FitnessExerciseOptimizationTests: XCTestCase {
    var engine: FitnessExerciseOptimizationEngine!
    var mockHealthDataManager: HealthDataManager!
    var mockMLModelManager: MLModelManager!
    var mockNotificationManager: NotificationManager!

    override func setUp() {
        super.setUp()
        // Initialize with proper mock implementations
        mockHealthDataManager = HealthDataManager()
        mockMLModelManager = MLModelManager()
        mockNotificationManager = NotificationManager()
        engine = FitnessExerciseOptimizationEngine(
            healthDataManager: mockHealthDataManager,
            mlModelManager: mockMLModelManager,
            notificationManager: mockNotificationManager
        )
    }

    override func tearDown() {
        engine = nil
        mockHealthDataManager = nil
        mockMLModelManager = nil
        mockNotificationManager = nil
        super.tearDown()
    }

    // MARK: - Fitness Tracking Tests
    func testRecordWorkoutEntry() async throws {
        // Test workout entry recording
        let workoutSession = WorkoutSession(
            id: UUID(),
            type: .strength,
            duration: 3600, // 1 hour
            caloriesBurned: 450,
            heartRate: 140,
            timestamp: Date()
        )
        
        let result = await engine.recordWorkoutEntry(workoutSession)
        
        // Verify workout was recorded successfully
        XCTAssertTrue(result.success)
        XCTAssertNotNil(result.workoutId)
        XCTAssertNotNil(result.performanceMetrics)
        XCTAssertNotNil(result.recoveryRecommendations)
        
        // Verify performance metrics
        XCTAssertGreaterThan(result.performanceMetrics.intensity, 0.0)
        XCTAssertGreaterThan(result.performanceMetrics.volume, 0.0)
        XCTAssertNotNil(result.performanceMetrics.strengthGains)
    }

    func testRecordRecoveryEntry() async throws {
        // Test recovery entry recording
        let recoverySession = RecoverySession(
            id: UUID(),
            type: .stretching,
            duration: 1800, // 30 minutes
            perceivedExertion: 3,
            muscleSoreness: 2,
            timestamp: Date()
        )
        
        let result = await engine.recordRecoveryEntry(recoverySession)
        
        // Verify recovery was recorded successfully
        XCTAssertTrue(result.success)
        XCTAssertNotNil(result.recoveryId)
        XCTAssertNotNil(result.recoveryMetrics)
        XCTAssertNotNil(result.nextWorkoutRecommendations)
        
        // Verify recovery metrics
        XCTAssertGreaterThanOrEqual(result.recoveryMetrics.recoveryScore, 0.0)
        XCTAssertLessThanOrEqual(result.recoveryMetrics.recoveryScore, 1.0)
        XCTAssertNotNil(result.recoveryMetrics.readinessScore)
    }

    // MARK: - AI Optimization Tests
    func testGenerateAIWorkoutPlan() async throws {
        // Test AI-powered workout plan generation
        let userProfile = UserFitnessProfile(
            fitnessLevel: .intermediate,
            goals: [.strength, .endurance],
            preferences: ["morning_workouts", "strength_focus"],
            limitations: ["knee_injury"]
        )
        
        let workoutPlan = await engine.generateAIWorkoutPlan(for: userProfile)
        
        // Verify AI plan is generated
        XCTAssertNotNil(workoutPlan)
        XCTAssertNotNil(workoutPlan.id)
        XCTAssertNotNil(workoutPlan.workouts)
        XCTAssertNotNil(workoutPlan.progressionPlan)
        XCTAssertNotNil(workoutPlan.adaptationRules)
        
        // Verify plan properties
        XCTAssertGreaterThan(workoutPlan.workouts.count, 0)
        XCTAssertEqual(workoutPlan.duration, 4) // 4 weeks
        XCTAssertNotNil(workoutPlan.difficultyLevel)
    }

    func testGenerateExerciseRecommendations() async throws {
        // Test AI-powered exercise recommendations
        let currentFitness = FitnessAssessment(
            strength: 0.7,
            endurance: 0.6,
            flexibility: 0.5,
            balance: 0.8
        )
        
        let recommendations = await engine.generateExerciseRecommendations(
            basedOn: currentFitness,
            goals: [.strength, .flexibility]
        )
        
        // Verify recommendations are generated
        XCTAssertNotNil(recommendations)
        XCTAssertGreaterThan(recommendations.count, 0)
        
        // Verify recommendation properties
        for recommendation in recommendations {
            XCTAssertNotNil(recommendation.exerciseName)
            XCTAssertNotNil(recommendation.category)
            XCTAssertNotNil(recommendation.difficulty)
            XCTAssertNotNil(recommendation.reps)
            XCTAssertNotNil(recommendation.sets)
            XCTAssertNotNil(recommendation.restTime)
        }
    }

    // MARK: - Advanced Training Tests
    func testUpdateTrainingFeatures() async throws {
        // Test advanced training feature logic
        let trainingData = TrainingData(
            recentWorkouts: 5,
            averageIntensity: 0.75,
            recoveryTime: 48, // hours
            progressRate: 0.1
        )
        
        let updatedFeatures = await engine.updateTrainingFeatures(with: trainingData)
        
        // Verify training features are updated
        XCTAssertNotNil(updatedFeatures)
        XCTAssertNotNil(updatedFeatures.periodizationPhase)
        XCTAssertNotNil(updatedFeatures.intensityModifier)
        XCTAssertNotNil(updatedFeatures.volumeModifier)
        XCTAssertNotNil(updatedFeatures.recoveryModifier)
        
        // Verify feature values are reasonable
        XCTAssertGreaterThan(updatedFeatures.intensityModifier, 0.0)
        XCTAssertLessThan(updatedFeatures.intensityModifier, 2.0)
    }

    // MARK: - Social Fitness Tests
    func testUpdateSocialFeatures() async throws {
        // Test social fitness feature logic
        let socialData = SocialFitnessData(
            groupWorkouts: 3,
            challengesCompleted: 2,
            communityEngagement: 0.8,
            motivationLevel: 0.9
        )
        
        let updatedFeatures = await engine.updateSocialFeatures(with: socialData)
        
        // Verify social features are updated
        XCTAssertNotNil(updatedFeatures)
        XCTAssertNotNil(updatedFeatures.groupRecommendations)
        XCTAssertNotNil(updatedFeatures.challengeSuggestions)
        XCTAssertNotNil(updatedFeatures.communityFeatures)
        XCTAssertNotNil(updatedFeatures.motivationBoosters)
        
        // Verify social recommendations
        XCTAssertGreaterThan(updatedFeatures.groupRecommendations.count, 0)
        XCTAssertGreaterThan(updatedFeatures.challengeSuggestions.count, 0)
    }

    func testFitnessSummaryUpdates() {
        // Test fitness summary update logic
        let summary = engine.fitnessSummary
        
        // Verify fitness summary exists and has required properties
        XCTAssertNotNil(summary)
        XCTAssertNotNil(summary.currentFitnessLevel)
        XCTAssertNotNil(summary.progressMetrics)
        XCTAssertNotNil(summary.goalProgress)
        XCTAssertNotNil(summary.recommendations)
        XCTAssertNotNil(summary.lastUpdated)
        
        // Verify summary metrics
        XCTAssertGreaterThanOrEqual(summary.progressMetrics.strengthProgress, 0.0)
        XCTAssertGreaterThanOrEqual(summary.progressMetrics.enduranceProgress, 0.0)
        XCTAssertGreaterThanOrEqual(summary.progressMetrics.flexibilityProgress, 0.0)
    }

    func testLogWorkout() {
        // Test logging a workout session
        let session = WorkoutSession(
            id: UUID(),
            type: .cardio,
            duration: 2700, // 45 minutes
            caloriesBurned: 350,
            heartRate: 150,
            timestamp: Date()
        )
        
        engine.logWorkout(session)
        
        // Verify workout history is updated
        let workoutHistory = engine.workoutHistory
        XCTAssertNotNil(workoutHistory)
        XCTAssertGreaterThan(workoutHistory.count, 0)
        
        // Verify latest workout is recorded
        let latestWorkout = workoutHistory.first
        XCTAssertNotNil(latestWorkout)
        XCTAssertEqual(latestWorkout?.id, session.id)
        XCTAssertEqual(latestWorkout?.type, session.type)
    }

    func testAIWorkoutPlanGeneration() {
        // Test AI workout plan generation
        let plan = engine.generateAIWorkoutPlan()
        
        // Verify AI plan is generated
        XCTAssertNotNil(plan)
        XCTAssertNotNil(plan.workouts)
        XCTAssertNotNil(plan.adaptationRules)
        XCTAssertNotNil(plan.progressionMetrics)
        
        // Verify plan structure
        XCTAssertGreaterThan(plan.workouts.count, 0)
        XCTAssertNotNil(plan.difficultyLevel)
        XCTAssertNotNil(plan.estimatedDuration)
    }

    func testPeriodizationPlanning() {
        // Test periodization planning logic
        let periodizationPlan = engine.planPeriodization()
        
        // Verify periodization plan is created
        XCTAssertNotNil(periodizationPlan)
        XCTAssertNotNil(periodizationPlan.phases)
        XCTAssertNotNil(periodizationPlan.transitions)
        XCTAssertNotNil(periodizationPlan.adaptationRules)
        
        // Verify plan phases
        XCTAssertGreaterThan(periodizationPlan.phases.count, 0)
        for phase in periodizationPlan.phases {
            XCTAssertNotNil(phase.name)
            XCTAssertNotNil(phase.duration)
            XCTAssertNotNil(phase.focus)
            XCTAssertNotNil(phase.intensity)
        }
    }

    func testJoinGroupSession() {
        // Test joining a group session
        let group = SocialFitnessFeature(
            id: UUID(),
            name: "Morning Runners",
            type: .running,
            participants: 15,
            difficulty: .intermediate
        )
        
        engine.joinGroupSession(group)
        
        // Verify social features are updated
        let activeGroups = engine.activeGroups
        XCTAssertNotNil(activeGroups)
        XCTAssertTrue(activeGroups.contains { $0.id == group.id })
        
        // Verify group session is active
        XCTAssertTrue(engine.isInGroupSession)
        XCTAssertNotNil(engine.currentGroupSession)
    }

    func testAnalyticsUpdate() {
        // Test analytics update logic
        engine.updateAnalytics()
        
        // Verify analytics are updated
        let analytics = engine.fitnessAnalytics
        XCTAssertNotNil(analytics)
        XCTAssertNotNil(analytics.performanceTrends)
        XCTAssertNotNil(analytics.recoveryMetrics)
        XCTAssertNotNil(analytics.progressProjections)
        XCTAssertNotNil(analytics.recommendations)
        
        // Verify analytics data
        XCTAssertGreaterThan(analytics.performanceTrends.count, 0)
        XCTAssertNotNil(analytics.lastUpdated)
    }
} 
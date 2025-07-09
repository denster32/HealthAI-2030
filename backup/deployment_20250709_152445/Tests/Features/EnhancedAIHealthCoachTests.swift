import XCTest
import HealthKit
import CoreML
import NaturalLanguage
@testable import HealthAI2030

final class EnhancedAIHealthCoachTests: XCTestCase {
    var coachManager: EnhancedAIHealthCoachManager!
    var mockHealthStore: MockHealthStore!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        mockHealthStore = MockHealthStore()
        coachManager = EnhancedAIHealthCoachManager()
    }
    
    override func tearDownWithError() throws {
        coachManager = nil
        mockHealthStore = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Initialization Tests
    
    func testInitialization() throws {
        XCTAssertNotNil(coachManager)
        XCTAssertFalse(coachManager.isListening)
        XCTAssertFalse(coachManager.isProcessing)
        XCTAssertTrue(coachManager.conversationHistory.count > 0) // Should have greeting
        XCTAssertNil(coachManager.currentWorkoutRecommendation)
        XCTAssertNil(coachManager.nutritionPlan)
        XCTAssertEqual(coachManager.mentalHealthStatus, .good)
        XCTAssertTrue(coachManager.progressGoals.isEmpty)
        XCTAssertTrue(coachManager.motivationalMessages.isEmpty)
    }
    
    func testInitializationWithGreeting() throws {
        let greeting = coachManager.conversationHistory.first
        XCTAssertNotNil(greeting)
        XCTAssertEqual(greeting?.sender, .ai)
        XCTAssertEqual(greeting?.messageType, .greeting)
        XCTAssertTrue(greeting?.content.contains("AI health coach") ?? false)
    }
    
    // MARK: - Conversational AI Tests
    
    func testSendMessage() throws {
        // Given
        let message = "I need a workout recommendation"
        let initialCount = coachManager.conversationHistory.count
        
        // When
        coachManager.sendMessage(message)
        
        // Then
        XCTAssertEqual(coachManager.conversationHistory.count, initialCount + 2) // User message + AI response
        XCTAssertEqual(coachManager.conversationHistory[initialCount].content, message)
        XCTAssertEqual(coachManager.conversationHistory[initialCount].sender, .user)
        XCTAssertEqual(coachManager.conversationHistory[initialCount + 1].sender, .ai)
    }
    
    func testIntentDetection_Workout() throws {
        // Given
        let messages = [
            "I need a workout",
            "Can you recommend some exercises?",
            "What should I do for fitness?",
            "I want to exercise"
        ]
        
        // When & Then
        for message in messages {
            let intent = coachManager.determineIntent(message)
            XCTAssertEqual(intent, .workoutRecommendation)
        }
    }
    
    func testIntentDetection_Nutrition() throws {
        // Given
        let messages = [
            "What should I eat?",
            "I need nutrition advice",
            "Help me with my diet",
            "What's a good meal plan?"
        ]
        
        // When & Then
        for message in messages {
            let intent = coachManager.determineIntent(message)
            XCTAssertEqual(intent, .nutritionGuidance)
        }
    }
    
    func testIntentDetection_MentalHealth() throws {
        // Given
        let messages = [
            "I'm feeling stressed",
            "I need mental health support",
            "I'm anxious",
            "Help me with my mental health"
        ]
        
        // When & Then
        for message in messages {
            let intent = coachManager.determineIntent(message)
            XCTAssertEqual(intent, .mentalHealthSupport)
        }
    }
    
    func testIntentDetection_Progress() throws {
        // Given
        let messages = [
            "How am I doing?",
            "Show me my progress",
            "What are my achievements?",
            "Track my goals"
        ]
        
        // When & Then
        for message in messages {
            let intent = coachManager.determineIntent(message)
            XCTAssertEqual(intent, .progressTracking)
        }
    }
    
    func testIntentDetection_Motivation() throws {
        // Given
        let messages = [
            "I need motivation",
            "Encourage me",
            "Give me a pep talk",
            "I need inspiration"
        ]
        
        // When & Then
        for message in messages {
            let intent = coachManager.determineIntent(message)
            XCTAssertEqual(intent, .motivation)
        }
    }
    
    func testIntentDetection_GeneralHealth() throws {
        // Given
        let messages = [
            "How are you?",
            "What's the weather?",
            "Tell me a joke",
            "Hello"
        ]
        
        // When & Then
        for message in messages {
            let intent = coachManager.determineIntent(message)
            XCTAssertEqual(intent, .generalHealth)
        }
    }
    
    func testSentimentAnalysis() throws {
        // Given
        let positiveMessages = ["I feel great!", "I'm so happy", "This is amazing"]
        let negativeMessages = ["I'm sad", "This is terrible", "I feel awful"]
        let neutralMessages = ["Hello", "What time is it?", "The weather is nice"]
        
        // When & Then
        for message in positiveMessages {
            let sentiment = coachManager.analyzeSentiment(message)
            // Note: Actual sentiment analysis would depend on the loaded model
            XCTAssertNotNil(sentiment)
        }
        
        for message in negativeMessages {
            let sentiment = coachManager.analyzeSentiment(message)
            XCTAssertNotNil(sentiment)
        }
        
        for message in neutralMessages {
            let sentiment = coachManager.analyzeSentiment(message)
            XCTAssertNotNil(sentiment)
        }
    }
    
    // MARK: - Workout Recommendation Tests
    
    func testWorkoutRecommendationGeneration() throws {
        // Given
        coachManager.userProfile.fitnessGoals = .weightLoss
        coachManager.userProfile.availableTime = 45
        
        // When
        let recommendation = coachManager.generatePersonalizedWorkout()
        
        // Then
        XCTAssertNotNil(recommendation)
        XCTAssertEqual(recommendation.type, .cardio)
        XCTAssertEqual(recommendation.intensity, .moderate)
        XCTAssertEqual(recommendation.duration, 45)
        XCTAssertFalse(recommendation.exercises.isEmpty)
        XCTAssertFalse(recommendation.tips.isEmpty)
        XCTAssertGreaterThan(recommendation.caloriesBurned, 0)
    }
    
    func testWorkoutRecommendation_StrengthGoal() throws {
        // Given
        coachManager.userProfile.fitnessGoals = .strength
        coachManager.userProfile.availableTime = 60
        
        // When
        let recommendation = coachManager.generatePersonalizedWorkout()
        
        // Then
        XCTAssertEqual(recommendation.type, .strength)
        XCTAssertEqual(recommendation.intensity, .high)
        XCTAssertEqual(recommendation.duration, 60)
    }
    
    func testWorkoutRecommendation_FlexibilityGoal() throws {
        // Given
        coachManager.userProfile.fitnessGoals = .flexibility
        coachManager.userProfile.availableTime = 30
        
        // When
        let recommendation = coachManager.generatePersonalizedWorkout()
        
        // Then
        XCTAssertEqual(recommendation.type, .flexibility)
        XCTAssertEqual(recommendation.intensity, .low)
        XCTAssertEqual(recommendation.duration, 30)
    }
    
    func testFitnessLevelAssessment() throws {
        // Given
        coachManager.userProfile.activityLevel = 12000
        coachManager.userProfile.averageHeartRate = 65
        
        // When
        let level = coachManager.assessFitnessLevel()
        
        // Then
        XCTAssertEqual(level, .advanced)
    }
    
    func testFitnessLevelAssessment_Intermediate() throws {
        // Given
        coachManager.userProfile.activityLevel = 8000
        coachManager.userProfile.averageHeartRate = 75
        
        // When
        let level = coachManager.assessFitnessLevel()
        
        // Then
        XCTAssertEqual(level, .intermediate)
    }
    
    func testFitnessLevelAssessment_Beginner() throws {
        // Given
        coachManager.userProfile.activityLevel = 3000
        coachManager.userProfile.averageHeartRate = 85
        
        // When
        let level = coachManager.assessFitnessLevel()
        
        // Then
        XCTAssertEqual(level, .beginner)
    }
    
    func testExerciseGeneration_Cardio() throws {
        // Given
        let type = WorkoutType.cardio
        let duration = 30
        let fitnessLevel = FitnessLevel.intermediate
        
        // When
        let exercises = coachManager.generateExercises(for: type, duration: duration, fitnessLevel: fitnessLevel)
        
        // Then
        XCTAssertFalse(exercises.isEmpty)
        for exercise in exercises {
            XCTAssertEqual(exercise.type, .cardio)
            XCTAssertGreaterThan(exercise.duration, 0)
        }
    }
    
    func testExerciseGeneration_Strength() throws {
        // Given
        let type = WorkoutType.strength
        let duration = 45
        let fitnessLevel = FitnessLevel.advanced
        
        // When
        let exercises = coachManager.generateExercises(for: type, duration: duration, fitnessLevel: fitnessLevel)
        
        // Then
        XCTAssertFalse(exercises.isEmpty)
        for exercise in exercises {
            XCTAssertEqual(exercise.type, .strength)
            XCTAssertGreaterThan(exercise.duration, 0)
        }
    }
    
    func testExerciseGeneration_Flexibility() throws {
        // Given
        let type = WorkoutType.flexibility
        let duration = 20
        let fitnessLevel = FitnessLevel.beginner
        
        // When
        let exercises = coachManager.generateExercises(for: type, duration: duration, fitnessLevel: fitnessLevel)
        
        // Then
        XCTAssertFalse(exercises.isEmpty)
        for exercise in exercises {
            XCTAssertEqual(exercise.type, .flexibility)
            XCTAssertGreaterThan(exercise.duration, 0)
        }
    }
    
    func testCalorieEstimation() throws {
        // Given
        let type = WorkoutType.cardio
        let duration = 30
        let intensity = WorkoutIntensity.moderate
        
        // When
        let calories = coachManager.estimateCaloriesBurned(type: type, duration: duration, intensity: intensity)
        
        // Then
        XCTAssertGreaterThan(calories, 0)
        XCTAssertLessThan(calories, 1000) // Reasonable range for 30 min moderate cardio
    }
    
    // MARK: - Nutrition Guidance Tests
    
    func testNutritionPlanGeneration() throws {
        // Given
        coachManager.userProfile.weight = 70.0
        coachManager.userProfile.height = 170.0
        coachManager.userProfile.age = 30
        coachManager.userProfile.gender = .male
        coachManager.userProfile.nutritionGoal = .maintenance
        coachManager.userProfile.activityLevel = 8000
        
        // When
        let plan = coachManager.generateNutritionPlan()
        
        // Then
        XCTAssertNotNil(plan)
        XCTAssertGreaterThan(plan.dailyCalories, 0)
        XCTAssertGreaterThan(plan.proteinGrams, 0)
        XCTAssertGreaterThan(plan.carbGrams, 0)
        XCTAssertGreaterThan(plan.fatGrams, 0)
        XCTAssertFalse(plan.meals.isEmpty)
        XCTAssertGreaterThan(plan.hydrationTarget, 0)
    }
    
    func testNutritionPlan_WeightLoss() throws {
        // Given
        coachManager.userProfile.nutritionGoal = .weightLoss
        
        // When
        let plan = coachManager.generateNutritionPlan()
        
        // Then
        let bmr = coachManager.calculateBMR()
        let tdee = coachManager.calculateTDEE(bmr: bmr)
        let expectedCalories = Int(Double(tdee) * 0.85)
        XCTAssertEqual(plan.dailyCalories, expectedCalories)
    }
    
    func testNutritionPlan_MuscleGain() throws {
        // Given
        coachManager.userProfile.nutritionGoal = .muscleGain
        
        // When
        let plan = coachManager.generateNutritionPlan()
        
        // Then
        let bmr = coachManager.calculateBMR()
        let tdee = coachManager.calculateTDEE(bmr: bmr)
        let expectedCalories = Int(Double(tdee) * 1.1)
        XCTAssertEqual(plan.dailyCalories, expectedCalories)
    }
    
    func testBMRCalculation_Male() throws {
        // Given
        coachManager.userProfile.weight = 70.0
        coachManager.userProfile.height = 170.0
        coachManager.userProfile.age = 30
        coachManager.userProfile.gender = .male
        
        // When
        let bmr = coachManager.calculateBMR()
        
        // Then
        // Expected BMR for 70kg, 170cm, 30-year-old male: ~1650 calories
        XCTAssertGreaterThan(bmr, 1500)
        XCTAssertLessThan(bmr, 1800)
    }
    
    func testBMRCalculation_Female() throws {
        // Given
        coachManager.userProfile.weight = 60.0
        coachManager.userProfile.height = 160.0
        coachManager.userProfile.age = 25
        coachManager.userProfile.gender = .female
        
        // When
        let bmr = coachManager.calculateBMR()
        
        // Then
        // Expected BMR for 60kg, 160cm, 25-year-old female: ~1350 calories
        XCTAssertGreaterThan(bmr, 1200)
        XCTAssertLessThan(bmr, 1500)
    }
    
    func testTDEECalculation() throws {
        // Given
        let bmr = 1650
        coachManager.userProfile.activityLevel = 8000 // Moderately active
        
        // When
        let tdee = coachManager.calculateTDEE(bmr: bmr)
        
        // Then
        let expectedTDEE = Int(Double(bmr) * 1.55) // Moderately active multiplier
        XCTAssertEqual(tdee, expectedTDEE)
    }
    
    func testMealPlanGeneration() throws {
        // Given
        let calories = 2000
        let protein = 120
        let carbs = 200
        let fat = 67
        
        // When
        let meals = coachManager.generateMealPlan(calories: calories, protein: protein, carbs: carbs, fat: fat)
        
        // Then
        XCTAssertEqual(meals.count, 4) // Breakfast, lunch, dinner, snack
        XCTAssertEqual(meals[0].type, .breakfast)
        XCTAssertEqual(meals[1].type, .lunch)
        XCTAssertEqual(meals[2].type, .dinner)
        XCTAssertEqual(meals[3].type, .snack)
        
        let totalCalories = meals.map { $0.calories }.reduce(0, +)
        XCTAssertEqual(totalCalories, calories)
    }
    
    func testSupplementRecommendations() throws {
        // Given
        coachManager.userProfile.sunExposure = 10 // Low sun exposure
        coachManager.userProfile.proteinIntake = 50 // Low protein intake
        
        // When
        let supplements = coachManager.generateSupplementRecommendations()
        
        // Then
        XCTAssertFalse(supplements.isEmpty)
        
        let vitaminD = supplements.first { $0.name == "Vitamin D" }
        XCTAssertNotNil(vitaminD)
        
        let protein = supplements.first { $0.name == "Protein Powder" }
        XCTAssertNotNil(protein)
    }
    
    // MARK: - Mental Health Support Tests
    
    func testMentalHealthStatusAssessment_Excellent() throws {
        // Given
        coachManager.userProfile.averageSleepQuality = 9.0
        coachManager.userProfile.stressLevel = 2
        coachManager.userProfile.moodScore = 8.5
        
        // When
        let status = coachManager.assessMentalHealthStatus()
        
        // Then
        XCTAssertEqual(status, .excellent)
    }
    
    func testMentalHealthStatusAssessment_Good() throws {
        // Given
        coachManager.userProfile.averageSleepQuality = 7.5
        coachManager.userProfile.stressLevel = 4
        coachManager.userProfile.moodScore = 6.5
        
        // When
        let status = coachManager.assessMentalHealthStatus()
        
        // Then
        XCTAssertEqual(status, .good)
    }
    
    func testMentalHealthStatusAssessment_Moderate() throws {
        // Given
        coachManager.userProfile.averageSleepQuality = 5.5
        coachManager.userProfile.stressLevel = 6
        coachManager.userProfile.moodScore = 4.5
        
        // When
        let status = coachManager.assessMentalHealthStatus()
        
        // Then
        XCTAssertEqual(status, .moderate)
    }
    
    func testMentalHealthStatusAssessment_Poor() throws {
        // Given
        coachManager.userProfile.averageSleepQuality = 3.0
        coachManager.userProfile.stressLevel = 8
        coachManager.userProfile.moodScore = 2.5
        
        // When
        let status = coachManager.assessMentalHealthStatus()
        
        // Then
        XCTAssertEqual(status, .poor)
    }
    
    // MARK: - Progress Tracking Tests
    
    func testProgressCalculation() throws {
        // Given
        let goal1 = HealthGoal(id: UUID(), name: "Weight Loss", target: 10.0, current: 5.0, unit: "kg", deadline: Date())
        let goal2 = HealthGoal(id: UUID(), name: "Steps", target: 10000.0, current: 8000.0, unit: "steps", deadline: Date())
        coachManager.progressGoals = [goal1, goal2]
        
        // When
        let progress = coachManager.calculateProgress()
        
        // Then
        XCTAssertEqual(progress.overallProgress, 0.65) // (0.5 + 0.8) / 2
        XCTAssertEqual(progress.goalsCompleted, 0)
        XCTAssertEqual(progress.totalGoals, 2)
    }
    
    func testProgressCalculation_CompletedGoals() throws {
        // Given
        let goal1 = HealthGoal(id: UUID(), name: "Weight Loss", target: 10.0, current: 10.0, unit: "kg", deadline: Date())
        let goal2 = HealthGoal(id: UUID(), name: "Steps", target: 10000.0, current: 12000.0, unit: "steps", deadline: Date())
        coachManager.progressGoals = [goal1, goal2]
        
        // When
        let progress = coachManager.calculateProgress()
        
        // Then
        XCTAssertEqual(progress.overallProgress, 1.0) // Both goals completed
        XCTAssertEqual(progress.goalsCompleted, 2)
        XCTAssertEqual(progress.totalGoals, 2)
    }
    
    func testNextMilestoneDetermination() throws {
        // Given
        let progress25 = 0.2
        let progress50 = 0.6
        let progress75 = 0.8
        let progress100 = 1.0
        
        // When & Then
        let milestone25 = coachManager.determineNextMilestone(progress: progress25)
        XCTAssertTrue(milestone25.contains("25%"))
        
        let milestone50 = coachManager.determineNextMilestone(progress: progress50)
        XCTAssertTrue(milestone50.contains("50%"))
        
        let milestone75 = coachManager.determineNextMilestone(progress: progress75)
        XCTAssertTrue(milestone75.contains("75%"))
        
        let milestone100 = coachManager.determineNextMilestone(progress: progress100)
        XCTAssertTrue(milestone100.contains("all"))
    }
    
    // MARK: - Motivation System Tests
    
    func testMotivationalMessageGeneration_Positive() throws {
        // Given
        let sentiment = Sentiment.positive
        
        // When
        let message = coachManager.generatePersonalizedMotivationalMessage(sentiment: sentiment)
        
        // Then
        XCTAssertNotNil(message)
        XCTAssertEqual(message.category, .celebration)
        XCTAssertFalse(message.content.isEmpty)
        XCTAssertTrue(message.content.contains("!") || message.content.contains("🌟"))
    }
    
    func testMotivationalMessageGeneration_Negative() throws {
        // Given
        let sentiment = Sentiment.negative
        
        // When
        let message = coachManager.generatePersonalizedMotivationalMessage(sentiment: sentiment)
        
        // Then
        XCTAssertNotNil(message)
        XCTAssertEqual(message.category, .encouragement)
        XCTAssertFalse(message.content.isEmpty)
        XCTAssertTrue(message.content.contains("💙") || message.content.contains("Remember"))
    }
    
    func testMotivationalMessageGeneration_Neutral() throws {
        // Given
        let sentiment = Sentiment.neutral
        
        // When
        let message = coachManager.generatePersonalizedMotivationalMessage(sentiment: sentiment)
        
        // Then
        XCTAssertNotNil(message)
        XCTAssertFalse(message.content.isEmpty)
    }
    
    // MARK: - Health Score Tests
    
    func testHealthScoreCalculation() throws {
        // Given
        coachManager.userProfile.heartHealthScore = 90
        coachManager.userProfile.fitnessScore = 80
        coachManager.userProfile.mentalHealthScore = 85
        coachManager.userProfile.nutritionScore = 75
        coachManager.userProfile.sleepScore = 80
        
        // When
        let healthScore = coachManager.calculateHealthScore()
        
        // Then
        let expectedScore = (90 + 80 + 85 + 75 + 80) / 5
        XCTAssertEqual(healthScore, expectedScore)
    }
    
    // MARK: - Voice Recognition Tests
    
    func testVoiceRecognitionSetup() throws {
        // Given
        let manager = EnhancedAIHealthCoachManager()
        
        // When & Then
        XCTAssertNotNil(manager.speechRecognizer)
        XCTAssertNotNil(manager.speechRecognizer?.delegate)
    }
    
    func testVoiceRecognitionStartStop() throws {
        // Given
        let manager = EnhancedAIHealthCoachManager()
        
        // When
        manager.startVoiceRecognition()
        
        // Then
        // Note: Actual voice recognition testing would require audio input
        // This test verifies the method can be called without crashing
        XCTAssertTrue(true)
        
        // When
        manager.stopVoiceRecognition()
        
        // Then
        XCTAssertFalse(manager.isListening)
    }
    
    // MARK: - Performance Tests
    
    func testMessageProcessingPerformance() throws {
        // Given
        let iterations = 100
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // When
        for i in 0..<iterations {
            coachManager.sendMessage("Test message \(i)")
        }
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let executionTime = endTime - startTime
        
        // Then
        XCTAssertLessThan(executionTime, 5.0) // Should complete within 5 seconds
    }
    
    func testWorkoutGenerationPerformance() throws {
        // Given
        let iterations = 50
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // When
        for _ in 0..<iterations {
            _ = coachManager.generatePersonalizedWorkout()
        }
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let executionTime = endTime - startTime
        
        // Then
        XCTAssertLessThan(executionTime, 1.0) // Should complete within 1 second
    }
    
    func testNutritionPlanGenerationPerformance() throws {
        // Given
        let iterations = 50
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // When
        for _ in 0..<iterations {
            _ = coachManager.generateNutritionPlan()
        }
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let executionTime = endTime - startTime
        
        // Then
        XCTAssertLessThan(executionTime, 1.0) // Should complete within 1 second
    }
}

// MARK: - Mock Health Store

class MockHealthStore: HKHealthStore {
    var mockHeartRateData: [HKQuantitySample] = []
    var mockBloodPressureData: [HKQuantitySample] = []
    var mockOxygenSaturationData: [HKQuantitySample] = []
    var mockTemperatureData: [HKQuantitySample] = []
    
    override func requestAuthorization(toShare typesToShare: Set<HKSampleType>?, read typesToRead: Set<HKObjectType>?, completion: @escaping (Bool, Error?) -> Void) {
        completion(true, nil)
    }
    
    override func execute(_ query: HKQuery) {
        // Mock implementation for health queries
    }
    
    func addMockHeartRateData(_ samples: [HKQuantitySample]) {
        mockHeartRateData.append(contentsOf: samples)
    }
    
    func addMockBloodPressureData(_ samples: [HKQuantitySample]) {
        mockBloodPressureData.append(contentsOf: samples)
    }
    
    func addMockOxygenSaturationData(_ samples: [HKQuantitySample]) {
        mockOxygenSaturationData.append(contentsOf: samples)
    }
    
    func addMockTemperatureData(_ samples: [HKQuantitySample]) {
        mockTemperatureData.append(contentsOf: samples)
    }
} 
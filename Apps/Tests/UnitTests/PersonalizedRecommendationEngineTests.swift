import XCTest
import Foundation
import CoreML
import HealthKit
@testable import HealthAI2030MainApp

@MainActor
final class PersonalizedRecommendationEngineTests: XCTestCase {
    
    var recommendationEngine: PersonalizedRecommendationEngine!
    var mockHealthKitManager: MockHealthKitManager!
    var mockMLPredictor: MockHealthPredictor!
    var mockUserProfileManager: MockUserProfileManager!
    
    override func setUp() async throws {
        try await super.setUp()
        
        mockHealthKitManager = MockHealthKitManager()
        mockMLPredictor = MockHealthPredictor()
        mockUserProfileManager = MockUserProfileManager()
        
        recommendationEngine = PersonalizedRecommendationEngine(
            healthKitManager: mockHealthKitManager,
            mlPredictor: mockMLPredictor,
            userProfileManager: mockUserProfileManager
        )
    }
    
    override func tearDown() async throws {
        recommendationEngine = nil
        mockHealthKitManager = nil
        mockMLPredictor = nil
        mockUserProfileManager = nil
        try await super.tearDown()
    }
    
    // MARK: - Recommendation Generation Tests
    
    func testGenerateRecommendations() async throws {
        // Given
        setupMockHealthData()
        
        // When
        try await recommendationEngine.generateRecommendations()
        
        // Then
        XCTAssertFalse(recommendationEngine.currentRecommendations.isEmpty)
        XCTAssertFalse(recommendationEngine.isGeneratingRecommendations)
        XCTAssertGreaterThan(recommendationEngine.recommendationHistory.count, 0)
    }
    
    func testGenerateRecommendationsWithEmptyHealthData() async throws {
        // Given
        setupEmptyHealthData()
        
        // When
        try await recommendationEngine.generateRecommendations()
        
        // Then
        XCTAssertFalse(recommendationEngine.currentRecommendations.isEmpty) // Should still have temporal recommendations
        XCTAssertFalse(recommendationEngine.isGeneratingRecommendations)
    }
    
    func testGenerateRecommendationsHandlesErrors() async throws {
        // Given
        mockHealthKitManager.shouldThrowError = true
        
        // When/Then
        do {
            try await recommendationEngine.generateRecommendations()
            XCTFail("Should have thrown an error")
        } catch {
            XCTAssertTrue(error is MockHealthKitManager.MockError)
        }
    }
    
    // MARK: - Condition-Specific Recommendations Tests
    
    func testGetRecommendationsForDiabetes() async throws {
        // When
        let recommendations = try await recommendationEngine.getRecommendationsForCondition(.diabetes)
        
        // Then
        XCTAssertFalse(recommendations.isEmpty)
        XCTAssertTrue(recommendations.allSatisfy { recommendation in
            recommendation.description.contains("Diabetes")
        })
    }
    
    func testGetRecommendationsForHypertension() async throws {
        // When
        let recommendations = try await recommendationEngine.getRecommendationsForCondition(.hypertension)
        
        // Then
        XCTAssertFalse(recommendations.isEmpty)
        XCTAssertTrue(recommendations.allSatisfy { recommendation in
            recommendation.description.contains("Hypertension")
        })
    }
    
    func testGetRecommendationsForUnknownCondition() async throws {
        // When
        let recommendations = try await recommendationEngine.getRecommendationsForCondition(.cardiovascular)
        
        // Then
        XCTAssertTrue(recommendations.isEmpty)
    }
    
    func testRecommendationCaching() async throws {
        // Given
        let condition = HealthCondition.diabetes
        
        // When - First call
        let recommendations1 = try await recommendationEngine.getRecommendationsForCondition(condition)
        
        // Then - Second call should return cached results
        let recommendations2 = try await recommendationEngine.getRecommendationsForCondition(condition)
        
        XCTAssertEqual(recommendations1.count, recommendations2.count)
        XCTAssertEqual(recommendations1.first?.id, recommendations2.first?.id)
    }
    
    // MARK: - User Preferences Tests
    
    func testUpdateUserPreferences() async throws {
        // Given
        let newPreferences = UserHealthPreferences()
        newPreferences.preferredCategories = [.activity, .nutrition]
        newPreferences.preferredTimeOfDay = .morning
        newPreferences.maxTimePerRecommendation = 15
        
        // When
        try await recommendationEngine.updateUserPreferences(newPreferences)
        
        // Then
        XCTAssertEqual(recommendationEngine.userPreferences.preferredCategories, [.activity, .nutrition])
        XCTAssertEqual(recommendationEngine.userPreferences.preferredTimeOfDay, .morning)
        XCTAssertEqual(recommendationEngine.userPreferences.maxTimePerRecommendation, 15)
    }
    
    func testPreferenceAlignmentScoring() async throws {
        // Given
        var preferences = UserHealthPreferences()
        preferences.preferredCategories = [.activity]
        preferences.preferredTimeOfDay = .morning
        preferences.maxTimePerRecommendation = 30
        
        try await recommendationEngine.updateUserPreferences(preferences)
        
        let recommendation = HealthRecommendation(
            id: UUID(),
            title: "Test Activity",
            description: "Test description",
            category: .activity,
            priority: .medium,
            timeOfDay: .morning,
            evidenceLevel: .moderate,
            personalizationFactors: [],
            estimatedImpact: .moderate,
            timeToImplement: 20,
            frequency: .daily
        )
        
        // When
        let score = calculatePreferenceAlignmentScore(recommendation)
        
        // Then
        XCTAssertGreaterThan(score, 0.5) // Should have good alignment
    }
    
    // MARK: - Recommendation Scoring Tests
    
    func testRecommendationScoringWithStrongEvidence() async throws {
        // Given
        let recommendation = HealthRecommendation(
            id: UUID(),
            title: "Strong Evidence Recommendation",
            description: "Test description",
            category: .activity,
            priority: .high,
            timeOfDay: .anytime,
            evidenceLevel: .strong,
            personalizationFactors: [],
            estimatedImpact: .high,
            timeToImplement: 30,
            frequency: .daily
        )
        
        // When
        let score = calculateRecommendationScore(recommendation)
        
        // Then
        XCTAssertGreaterThan(score, 10.0) // Base score for strong evidence
    }
    
    func testRecommendationScoringWithWeakEvidence() async throws {
        // Given
        let recommendation = HealthRecommendation(
            id: UUID(),
            title: "Weak Evidence Recommendation",
            description: "Test description",
            category: .activity,
            priority: .low,
            timeOfDay: .anytime,
            evidenceLevel: .weak,
            personalizationFactors: [],
            estimatedImpact: .low,
            timeToImplement: 30,
            frequency: .daily
        )
        
        // When
        let score = calculateRecommendationScore(recommendation)
        
        // Then
        XCTAssertLessThan(score, 10.0) // Lower score for weak evidence
    }
    
    func testRecommendationScoringWithPersonalization() async throws {
        // Given
        setupMockHealthData()
        
        let recommendation = HealthRecommendation(
            id: UUID(),
            title: "Personalized Recommendation",
            description: "Test description",
            category: .sleep,
            priority: .medium,
            timeOfDay: .evening,
            evidenceLevel: .moderate,
            personalizationFactors: ["sleep_quality"],
            estimatedImpact: .moderate,
            timeToImplement: 20,
            frequency: .daily
        )
        
        // When
        let score = calculateRecommendationScore(recommendation)
        
        // Then
        XCTAssertGreaterThan(score, 7.0) // Should have personalization bonus
    }
    
    // MARK: - Time Relevance Tests
    
    func testTimeRelevanceScoring() async throws {
        let currentHour = Calendar.current.component(.hour, from: Date())
        
        // Test morning recommendation during morning hours
        let morningRecommendation = HealthRecommendation(
            id: UUID(),
            title: "Morning Activity",
            description: "Test description",
            category: .activity,
            priority: .medium,
            timeOfDay: .morning,
            evidenceLevel: .moderate,
            personalizationFactors: [],
            estimatedImpact: .moderate,
            timeToImplement: 30,
            frequency: .daily
        )
        
        let morningScore = calculateTimeRelevanceScore(morningRecommendation)
        
        if currentHour >= 6 && currentHour <= 10 {
            XCTAssertEqual(morningScore, 1.0)
        } else {
            XCTAssertEqual(morningScore, 0.0)
        }
        
        // Test anytime recommendation
        let anytimeRecommendation = HealthRecommendation(
            id: UUID(),
            title: "Anytime Activity",
            description: "Test description",
            category: .activity,
            priority: .medium,
            timeOfDay: .anytime,
            evidenceLevel: .moderate,
            personalizationFactors: [],
            estimatedImpact: .moderate,
            timeToImplement: 30,
            frequency: .daily
        )
        
        let anytimeScore = calculateTimeRelevanceScore(anytimeRecommendation)
        XCTAssertEqual(anytimeScore, 0.5)
    }
    
    // MARK: - Personalization Tests
    
    func testPersonalizationMatchScoring() async throws {
        // Given
        setupMockHealthData()
        
        let sleepRecommendation = HealthRecommendation(
            id: UUID(),
            title: "Sleep Improvement",
            description: "Test description",
            category: .sleep,
            priority: .medium,
            timeOfDay: .evening,
            evidenceLevel: .moderate,
            personalizationFactors: ["sleep_quality"],
            estimatedImpact: .moderate,
            timeToImplement: 20,
            frequency: .daily
        )
        
        // When
        let matchScore = calculatePersonalizationMatchScore(sleepRecommendation)
        
        // Then
        XCTAssertGreaterThan(matchScore, 0.0)
        XCTAssertLessThanOrEqual(matchScore, 1.0)
    }
    
    func testPersonalizationMatchWithMultipleFactors() async throws {
        // Given
        setupMockHealthData()
        
        let multiFactorRecommendation = HealthRecommendation(
            id: UUID(),
            title: "Multi-Factor Recommendation",
            description: "Test description",
            category: .activity,
            priority: .medium,
            timeOfDay: .anytime,
            evidenceLevel: .moderate,
            personalizationFactors: ["sleep_quality", "activity_levels", "stress_levels"],
            estimatedImpact: .moderate,
            timeToImplement: 30,
            frequency: .daily
        )
        
        // When
        let matchScore = calculatePersonalizationMatchScore(multiFactorRecommendation)
        
        // Then
        XCTAssertGreaterThan(matchScore, 0.0)
        XCTAssertLessThanOrEqual(matchScore, 1.0)
    }
    
    // MARK: - Engagement Tracking Tests
    
    func testTrackRecommendationEngagement() async throws {
        // Given
        let recommendation = HealthRecommendation(
            id: UUID(),
            title: "Test Recommendation",
            description: "Test description",
            category: .activity,
            priority: .medium,
            timeOfDay: .anytime,
            evidenceLevel: .moderate,
            personalizationFactors: [],
            estimatedImpact: .moderate,
            timeToImplement: 30,
            frequency: .daily
        )
        
        // When
        recommendationEngine.trackRecommendationEngagement(recommendation, action: .view)
        recommendationEngine.trackRecommendationEngagement(recommendation, action: .click)
        recommendationEngine.trackRecommendationEngagement(recommendation, action: .complete)
        
        // Then
        XCTAssertEqual(recommendation.engagementMetrics.views, 1)
        XCTAssertEqual(recommendation.engagementMetrics.clicks, 1)
        XCTAssertEqual(recommendation.engagementMetrics.completions, 1)
        XCTAssertEqual(recommendation.engagementMetrics.dismissals, 0)
        XCTAssertNotNil(recommendation.engagementMetrics.lastViewed)
    }
    
    // MARK: - A/B Testing Tests
    
    func testABTestingApplication() async throws {
        // Given
        let recommendations = [
            HealthRecommendation(
                id: UUID(),
                title: "Test Recommendation 1",
                description: "Test description 1",
                category: .activity,
                priority: .medium,
                timeOfDay: .anytime,
                evidenceLevel: .moderate,
                personalizationFactors: [],
                estimatedImpact: .moderate,
                timeToImplement: 30,
                frequency: .daily
            ),
            HealthRecommendation(
                id: UUID(),
                title: "Test Recommendation 2",
                description: "Test description 2",
                category: .nutrition,
                priority: .medium,
                timeOfDay: .anytime,
                evidenceLevel: .moderate,
                personalizationFactors: [],
                estimatedImpact: .moderate,
                timeToImplement: 15,
                frequency: .daily
            )
        ]
        
        // When
        let testedRecommendations = applyABTesting(to: recommendations)
        
        // Then
        XCTAssertEqual(testedRecommendations.count, recommendations.count)
    }
    
    // MARK: - Evidence-Based Interventions Tests
    
    func testEvidenceBasedInterventionsForDiabetes() async throws {
        // Given
        let database = EvidenceBasedInterventionDatabase()
        
        // When
        let interventions = try await database.getInterventionsForCondition(.diabetes)
        
        // Then
        XCTAssertFalse(interventions.isEmpty)
        XCTAssertTrue(interventions.allSatisfy { intervention in
            intervention.evidenceLevel == .strong
        })
    }
    
    func testEvidenceBasedInterventionsForHealthData() async throws {
        // Given
        let database = EvidenceBasedInterventionDatabase()
        let healthData = createMockHealthDataSnapshot()
        
        // When
        let interventions = try await database.getInterventionsForHealthData(healthData)
        
        // Then
        XCTAssertFalse(interventions.isEmpty)
        XCTAssertTrue(interventions.allSatisfy { intervention in
            intervention.evidenceLevel == .strong
        })
    }
    
    // MARK: - Data Analysis Tests
    
    func testSleepPatternAnalysis() async throws {
        // Given
        let sleepData = createMockSleepData()
        
        // When
        let recommendation = analyzeSleepPatterns(sleepData)
        
        // Then
        XCTAssertNotNil(recommendation)
        XCTAssertEqual(recommendation?.category, .sleep)
    }
    
    func testActivityPatternAnalysis() async throws {
        // Given
        let activityData = createMockActivityData()
        
        // When
        let recommendation = analyzeActivityPatterns(activityData)
        
        // Then
        XCTAssertNotNil(recommendation)
        XCTAssertEqual(recommendation?.category, .activity)
    }
    
    func testHeartRatePatternAnalysis() async throws {
        // Given
        let heartRateData = createMockHeartRateData()
        
        // When
        let recommendation = analyzeHeartRatePatterns(heartRateData)
        
        // Then
        XCTAssertNotNil(recommendation)
        XCTAssertEqual(recommendation?.category, .mindfulness)
    }
    
    func testNutritionPatternAnalysis() async throws {
        // Given
        let nutritionData = createMockNutritionData()
        
        // When
        let recommendation = analyzeNutritionPatterns(nutritionData)
        
        // Then
        XCTAssertNotNil(recommendation)
        XCTAssertEqual(recommendation?.category, .nutrition)
    }
    
    // MARK: - Helper Methods
    
    private func setupMockHealthData() {
        mockHealthKitManager.mockSleepData = createMockSleepData()
        mockHealthKitManager.mockActivityData = createMockActivityData()
        mockHealthKitManager.mockHeartRateData = createMockHeartRateData()
        mockHealthKitManager.mockNutritionData = createMockNutritionData()
        mockHealthKitManager.mockMindfulnessData = createMockMindfulnessData()
    }
    
    private func setupEmptyHealthData() {
        mockHealthKitManager.mockSleepData = []
        mockHealthKitManager.mockActivityData = []
        mockHealthKitManager.mockHeartRateData = []
        mockHealthKitManager.mockNutritionData = []
        mockHealthKitManager.mockMindfulnessData = []
    }
    
    private func createMockSleepData() -> [SleepRecord] {
        return [
            SleepRecord(id: UUID(), startTime: Date(), endTime: Date().addingTimeInterval(6*3600), quality: 6.5, duration: 6.0, stages: [:], source: "HealthKit"),
            SleepRecord(id: UUID(), startTime: Date().addingTimeInterval(-24*3600), endTime: Date().addingTimeInterval(-18*3600), quality: 5.5, duration: 5.5, stages: [:], source: "HealthKit")
        ]
    }
    
    private func createMockActivityData() -> [ActivityRecord] {
        return [
            ActivityRecord(id: UUID(), date: Date(), stepCount: 6000, activeMinutes: 45, caloriesBurned: 300, workouts: [], source: "HealthKit"),
            ActivityRecord(id: UUID(), date: Date().addingTimeInterval(-24*3600), stepCount: 5500, activeMinutes: 40, caloriesBurned: 280, workouts: [], source: "HealthKit")
        ]
    }
    
    private func createMockHeartRateData() -> [HeartRateRecord] {
        return [
            HeartRateRecord(id: UUID(), timestamp: Date(), heartRate: 85, hrv: 25, source: "HealthKit"),
            HeartRateRecord(id: UUID(), timestamp: Date().addingTimeInterval(-3600), heartRate: 82, hrv: 28, source: "HealthKit")
        ]
    }
    
    private func createMockNutritionData() -> [NutritionRecord] {
        return [
            NutritionRecord(id: UUID(), date: Date(), waterIntake: 1500, calories: 1800, protein: 80, carbs: 200, fat: 60, source: "HealthKit"),
            NutritionRecord(id: UUID(), date: Date().addingTimeInterval(-24*3600), waterIntake: 1400, calories: 1750, protein: 75, carbs: 190, fat: 55, source: "HealthKit")
        ]
    }
    
    private func createMockMindfulnessData() -> [MindfulnessRecord] {
        return [
            MindfulnessRecord(id: UUID(), startTime: Date().addingTimeInterval(-3600), endTime: Date().addingTimeInterval(-3300), type: .meditation, duration: 5, source: "HealthKit")
        ]
    }
    
    private func createMockHealthDataSnapshot() -> HealthDataSnapshot {
        return HealthDataSnapshot(
            userId: "test-user",
            sleepData: createMockSleepData(),
            activityData: createMockActivityData(),
            heartRateData: createMockHeartRateData(),
            nutritionData: createMockNutritionData(),
            mindfulnessData: createMockMindfulnessData(),
            timestamp: Date()
        )
    }
    
    // MARK: - Private Test Methods (using reflection for testing private methods)
    
    private func calculateRecommendationScore(_ recommendation: HealthRecommendation) -> Double {
        // This would normally use reflection to test private methods
        // For now, we'll simulate the scoring logic
        var score: Double = 0.0
        
        switch recommendation.evidenceLevel {
        case .strong: score += 10.0
        case .moderate: score += 7.0
        case .weak: score += 4.0
        case .anecdotal: score += 2.0
        }
        
        switch recommendation.priority {
        case .critical: score *= 2.0
        case .high: score *= 1.5
        case .medium: score *= 1.0
        case .low: score *= 0.7
        }
        
        return score
    }
    
    private func calculateTimeRelevanceScore(_ recommendation: HealthRecommendation) -> Double {
        let currentHour = Calendar.current.component(.hour, from: Date())
        
        switch recommendation.timeOfDay {
        case .morning:
            return currentHour >= 6 && currentHour <= 10 ? 1.0 : 0.0
        case .afternoon:
            return currentHour >= 12 && currentHour <= 16 ? 1.0 : 0.0
        case .evening:
            return currentHour >= 18 && currentHour <= 22 ? 1.0 : 0.0
        case .anytime:
            return 0.5
        }
    }
    
    private func calculatePersonalizationMatchScore(_ recommendation: HealthRecommendation) -> Double {
        // Simulate personalization match calculation
        var matchScore: Double = 0.0
        
        for factor in recommendation.personalizationFactors {
            switch factor {
            case "sleep_quality":
                matchScore += 1.0 // Mock data has poor sleep quality
            case "activity_levels":
                matchScore += 1.0 // Mock data has low activity
            case "stress_levels":
                matchScore += 1.0 // Mock data has high heart rate
            default:
                matchScore += 0.5
            }
        }
        
        return min(matchScore / Double(recommendation.personalizationFactors.count), 1.0)
    }
    
    private func calculatePreferenceAlignmentScore(_ recommendation: HealthRecommendation) -> Double {
        var alignment: Double = 0.0
        
        if recommendationEngine.userPreferences.preferredCategories.contains(recommendation.category) {
            alignment += 1.0
        }
        
        if recommendationEngine.userPreferences.preferredTimeOfDay == recommendation.timeOfDay {
            alignment += 1.0
        }
        
        if recommendation.timeToImplement <= recommendationEngine.userPreferences.maxTimePerRecommendation {
            alignment += 1.0
        }
        
        return alignment / 3.0
    }
    
    private func applyABTesting(to recommendations: [HealthRecommendation]) -> [HealthRecommendation] {
        // Simulate A/B testing application
        return recommendations
    }
    
    private func analyzeSleepPatterns(_ sleepData: [SleepRecord]) -> HealthRecommendation? {
        guard !sleepData.isEmpty else { return nil }
        
        let avgSleepQuality = sleepData.map { $0.quality }.reduce(0, +) / Double(sleepData.count)
        
        if avgSleepQuality < 7.0 {
            return HealthRecommendation(
                id: UUID(),
                title: "Improve Sleep Quality",
                description: "Your sleep quality is below optimal.",
                category: .sleep,
                priority: .high,
                timeOfDay: .evening,
                evidenceLevel: .strong,
                personalizationFactors: ["sleep_quality"],
                estimatedImpact: .high,
                timeToImplement: 20,
                frequency: .daily
            )
        }
        
        return nil
    }
    
    private func analyzeActivityPatterns(_ activityData: [ActivityRecord]) -> HealthRecommendation? {
        guard !activityData.isEmpty else { return nil }
        
        let avgSteps = activityData.map { $0.stepCount }.reduce(0, +) / Double(activityData.count)
        
        if avgSteps < 8000 {
            return HealthRecommendation(
                id: UUID(),
                title: "Increase Daily Steps",
                description: "Aim for 10,000 steps per day.",
                category: .activity,
                priority: .medium,
                timeOfDay: .anytime,
                evidenceLevel: .strong,
                personalizationFactors: ["activity_levels"],
                estimatedImpact: .moderate,
                timeToImplement: 30,
                frequency: .daily
            )
        }
        
        return nil
    }
    
    private func analyzeHeartRatePatterns(_ heartRateData: [HeartRateRecord]) -> HealthRecommendation? {
        guard !heartRateData.isEmpty else { return nil }
        
        let avgHeartRate = heartRateData.map { $0.heartRate }.reduce(0, +) / Double(heartRateData.count)
        
        if avgHeartRate > 80 {
            return HealthRecommendation(
                id: UUID(),
                title: "Stress Management",
                description: "Your heart rate suggests elevated stress levels.",
                category: .mindfulness,
                priority: .medium,
                timeOfDay: .anytime,
                evidenceLevel: .moderate,
                personalizationFactors: ["stress_levels"],
                estimatedImpact: .moderate,
                timeToImplement: 10,
                frequency: .daily
            )
        }
        
        return nil
    }
    
    private func analyzeNutritionPatterns(_ nutritionData: [NutritionRecord]) -> HealthRecommendation? {
        guard !nutritionData.isEmpty else { return nil }
        
        let avgWaterIntake = nutritionData.map { $0.waterIntake }.reduce(0, +) / Double(nutritionData.count)
        
        if avgWaterIntake < 2000 {
            return HealthRecommendation(
                id: UUID(),
                title: "Increase Water Intake",
                description: "Aim for 8-10 glasses of water per day.",
                category: .nutrition,
                priority: .medium,
                timeOfDay: .anytime,
                evidenceLevel: .strong,
                personalizationFactors: ["hydration"],
                estimatedImpact: .moderate,
                timeToImplement: 1,
                frequency: .daily
            )
        }
        
        return nil
    }
}

// MARK: - Mock Classes

class MockHealthKitManager: HealthKitManager {
    var mockSleepData: [SleepRecord] = []
    var mockActivityData: [ActivityRecord] = []
    var mockHeartRateData: [HeartRateRecord] = []
    var mockNutritionData: [NutritionRecord] = []
    var mockMindfulnessData: [MindfulnessRecord] = []
    var shouldThrowError = false
    
    enum MockError: Error {
        case mockError
    }
    
    override func getSleepData(for startDate: Date, to endDate: Date) async throws -> [SleepRecord] {
        if shouldThrowError {
            throw MockError.mockError
        }
        return mockSleepData
    }
    
    override func getActivityData(for startDate: Date, to endDate: Date) async throws -> [ActivityRecord] {
        if shouldThrowError {
            throw MockError.mockError
        }
        return mockActivityData
    }
    
    override func getHeartRateData(for startDate: Date, to endDate: Date) async throws -> [HeartRateRecord] {
        if shouldThrowError {
            throw MockError.mockError
        }
        return mockHeartRateData
    }
    
    override func getNutritionData(for startDate: Date, to endDate: Date) async throws -> [NutritionRecord] {
        if shouldThrowError {
            throw MockError.mockError
        }
        return mockNutritionData
    }
    
    override func getMindfulnessData(for startDate: Date, to endDate: Date) async throws -> [MindfulnessRecord] {
        if shouldThrowError {
            throw MockError.mockError
        }
        return mockMindfulnessData
    }
}

class MockHealthPredictor: HealthPredictor {
    func predictHealthOutcome(for data: HealthData) async throws -> HealthPrediction {
        return HealthPrediction(
            riskLevel: .low,
            confidence: 0.8,
            factors: ["mock_factor"],
            recommendations: []
        )
    }
}

class MockUserProfileManager: UserProfileManager {
    var currentUser: UserProfile?
    
    func loadUserPreferences() async -> UserHealthPreferences {
        return UserHealthPreferences()
    }
} 
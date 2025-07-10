import XCTest
import Foundation
import Combine
@testable import HealthAI2030

@available(iOS 18.0, macOS 15.0, *)
final class AdvancedMentalHealthEngineTests: XCTestCase {
    
    var mentalHealthEngine: AdvancedMentalHealthEngine!
    var healthDataManager: HealthDataManager!
    var predictionEngine: AdvancedHealthPredictionEngine!
    var analyticsEngine: AnalyticsEngine!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        healthDataManager = HealthDataManager()
        predictionEngine = AdvancedHealthPredictionEngine()
        analyticsEngine = AnalyticsEngine()
        mentalHealthEngine = AdvancedMentalHealthEngine(
            healthDataManager: healthDataManager,
            predictionEngine: predictionEngine,
            analyticsEngine: analyticsEngine
        )
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDown() {
        cancellables = nil
        mentalHealthEngine = nil
        healthDataManager = nil
        predictionEngine = nil
        analyticsEngine = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testInitialization() {
        XCTAssertNotNil(mentalHealthEngine)
        XCTAssertFalse(mentalHealthEngine.isMonitoringActive)
        XCTAssertEqual(mentalHealthEngine.stressLevel, .low)
        XCTAssertEqual(mentalHealthEngine.moodScore, 0.0)
        XCTAssertEqual(mentalHealthEngine.wellnessScore, 0.0)
        XCTAssertTrue(mentalHealthEngine.mentalHealthHistory.isEmpty)
        XCTAssertTrue(mentalHealthEngine.stressEvents.isEmpty)
        XCTAssertTrue(mentalHealthEngine.moodTrends.isEmpty)
        XCTAssertTrue(mentalHealthEngine.wellnessRecommendations.isEmpty)
    }
    
    // MARK: - Monitoring Tests
    
    func testStartMonitoring() async throws {
        // Given
        XCTAssertFalse(mentalHealthEngine.isMonitoringActive)
        
        // When
        try await mentalHealthEngine.startMonitoring()
        
        // Then
        XCTAssertTrue(mentalHealthEngine.isMonitoringActive)
        XCTAssertNotNil(mentalHealthEngine.currentMentalState)
        XCTAssertNil(mentalHealthEngine.lastError)
    }
    
    func testStopMonitoring() async throws {
        // Given
        try await mentalHealthEngine.startMonitoring()
        XCTAssertTrue(mentalHealthEngine.isMonitoringActive)
        
        // When
        await mentalHealthEngine.stopMonitoring()
        
        // Then
        XCTAssertFalse(mentalHealthEngine.isMonitoringActive)
        XCTAssertFalse(mentalHealthEngine.mentalHealthHistory.isEmpty)
    }
    
    func testStartMonitoringFailure() async {
        // Given
        let failingEngine = AdvancedMentalHealthEngine(
            healthDataManager: MockFailingHealthDataManager(),
            predictionEngine: predictionEngine,
            analyticsEngine: analyticsEngine
        )
        
        // When & Then
        do {
            try await failingEngine.startMonitoring()
            XCTFail("Should have thrown an error")
        } catch {
            XCTAssertFalse(failingEngine.isMonitoringActive)
            XCTAssertNotNil(failingEngine.lastError)
        }
    }
    
    // MARK: - Mental Health Analysis Tests
    
    func testAnalyzeMentalHealth() async throws {
        // Given
        try await mentalHealthEngine.startMonitoring()
        
        // When
        let analysis = try await mentalHealthEngine.analyzeMentalHealth()
        
        // Then
        XCTAssertNotNil(analysis)
        XCTAssertEqual(analysis.timestamp.timeIntervalSinceNow, 0, accuracy: 1.0)
        XCTAssertTrue(analysis.stressScore >= 0.0 && analysis.stressScore <= 1.0)
        XCTAssertTrue(analysis.moodScore >= 0.0 && analysis.moodScore <= 1.0)
        XCTAssertTrue(analysis.wellnessScore >= 0.0 && analysis.wellnessScore <= 1.0)
        XCTAssertTrue(analysis.energyLevel >= 0.0 && analysis.energyLevel <= 1.0)
        XCTAssertTrue(analysis.focusLevel >= 0.0 && analysis.focusLevel <= 1.0)
        XCTAssertTrue(analysis.sleepQuality >= 0.0 && analysis.sleepQuality <= 1.0)
        XCTAssertTrue(analysis.socialConnection >= 0.0 && analysis.socialConnection <= 1.0)
        XCTAssertTrue(analysis.physicalActivity >= 0.0 && analysis.physicalActivity <= 1.0)
        XCTAssertTrue(analysis.nutrition >= 0.0 && analysis.nutrition <= 1.0)
    }
    
    func testAnalyzeMentalHealthWithoutMonitoring() async {
        // Given
        XCTAssertFalse(mentalHealthEngine.isMonitoringActive)
        
        // When & Then
        do {
            _ = try await mentalHealthEngine.analyzeMentalHealth()
            XCTFail("Should have thrown an error")
        } catch MentalHealthError.noActiveMonitoring {
            // Expected error
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    // MARK: - Stress Event Tests
    
    func testRecordStressEvent() async {
        // Given
        let initialCount = mentalHealthEngine.stressEvents.count
        
        // When
        await mentalHealthEngine.recordStressEvent(
            type: .work,
            intensity: 0.7,
            trigger: "Deadline pressure"
        )
        
        // Then
        XCTAssertEqual(mentalHealthEngine.stressEvents.count, initialCount + 1)
        
        let event = mentalHealthEngine.stressEvents.last
        XCTAssertNotNil(event)
        XCTAssertEqual(event?.type, .work)
        XCTAssertEqual(event?.intensity, 0.7)
        XCTAssertEqual(event?.trigger, "Deadline pressure")
    }
    
    func testRecordMultipleStressEvents() async {
        // Given
        let events = [
            (StressEventType.work, 0.8, "Meeting"),
            (StressEventType.personal, 0.5, "Family issue"),
            (StressEventType.health, 0.3, "Minor illness")
        ]
        
        // When
        for (type, intensity, trigger) in events {
            await mentalHealthEngine.recordStressEvent(
                type: type,
                intensity: intensity,
                trigger: trigger
            )
        }
        
        // Then
        XCTAssertEqual(mentalHealthEngine.stressEvents.count, events.count)
        
        for (index, (type, intensity, trigger)) in events.enumerated() {
            let event = mentalHealthEngine.stressEvents[index]
            XCTAssertEqual(event.type, type)
            XCTAssertEqual(event.intensity, intensity)
            XCTAssertEqual(event.trigger, trigger)
        }
    }
    
    // MARK: - Mood Assessment Tests
    
    func testRecordMoodAssessment() async {
        // Given
        let initialCount = mentalHealthEngine.moodTrends.count
        
        // When
        await mentalHealthEngine.recordMoodAssessment(
            mood: .happy,
            intensity: 0.8,
            notes: "Had a great day"
        )
        
        // Then
        XCTAssertEqual(mentalHealthEngine.moodTrends.count, initialCount + 1)
        
        let moodRecord = mentalHealthEngine.moodTrends.last
        XCTAssertNotNil(moodRecord)
        XCTAssertEqual(moodRecord?.mood, .happy)
        XCTAssertEqual(moodRecord?.intensity, 0.8)
        XCTAssertEqual(moodRecord?.notes, "Had a great day")
    }
    
    func testRecordMultipleMoodAssessments() async {
        // Given
        let moods = [
            (MoodType.happy, 0.9, "Excellent day"),
            (MoodType.neutral, 0.5, "Regular day"),
            (MoodType.sad, 0.3, "Feeling down")
        ]
        
        // When
        for (mood, intensity, notes) in moods {
            await mentalHealthEngine.recordMoodAssessment(
                mood: mood,
                intensity: intensity,
                notes: notes
            )
        }
        
        // Then
        XCTAssertEqual(mentalHealthEngine.moodTrends.count, moods.count)
        
        for (index, (mood, intensity, notes)) in moods.enumerated() {
            let moodRecord = mentalHealthEngine.moodTrends[index]
            XCTAssertEqual(moodRecord.mood, mood)
            XCTAssertEqual(moodRecord.intensity, intensity)
            XCTAssertEqual(moodRecord.notes, notes)
        }
    }
    
    // MARK: - Wellness Recommendations Tests
    
    func testGenerateWellnessRecommendations() async throws {
        // Given
        try await mentalHealthEngine.startMonitoring()
        let analysis = try await mentalHealthEngine.analyzeMentalHealth()
        
        // When
        let recommendations = try await mentalHealthEngine.generateWellnessRecommendations(analysis: analysis)
        
        // Then
        XCTAssertFalse(recommendations.isEmpty)
        
        for recommendation in recommendations {
            XCTAssertFalse(recommendation.title.isEmpty)
            XCTAssertFalse(recommendation.description.isEmpty)
            XCTAssertTrue(recommendation.estimatedImpact >= 0.0 && recommendation.estimatedImpact <= 1.0)
            XCTAssertTrue(recommendation.duration >= 0)
        }
    }
    
    func testGenerateWellnessRecommendationsWithoutAnalysis() async throws {
        // Given
        try await mentalHealthEngine.startMonitoring()
        
        // When
        let recommendations = try await mentalHealthEngine.generateWellnessRecommendations()
        
        // Then
        XCTAssertFalse(recommendations.isEmpty)
        XCTAssertEqual(mentalHealthEngine.wellnessRecommendations.count, recommendations.count)
    }
    
    func testRecommendationPriorities() async throws {
        // Given
        try await mentalHealthEngine.startMonitoring()
        
        // When
        let recommendations = try await mentalHealthEngine.generateWellnessRecommendations()
        
        // Then
        let priorities = recommendations.map { $0.priority.rawValue }
        let sortedPriorities = priorities.sorted(by: >)
        XCTAssertEqual(priorities, sortedPriorities, "Recommendations should be sorted by priority")
    }
    
    // MARK: - Mental Health Insights Tests
    
    func testGetMentalHealthInsights() async {
        // Given
        let timeframes: [Timeframe] = [.day, .week, .month, .quarter]
        
        // When & Then
        for timeframe in timeframes {
            let insights = await mentalHealthEngine.getMentalHealthInsights(timeframe: timeframe)
            
            XCTAssertNotNil(insights)
            XCTAssertTrue(insights.averageMoodScore >= 0.0 && insights.averageMoodScore <= 1.0)
            XCTAssertNotNil(insights.stressTrend)
            XCTAssertNotNil(insights.moodTrend)
            XCTAssertNotNil(insights.wellnessTrend)
            XCTAssertNotNil(insights.commonStressors)
            XCTAssertNotNil(insights.moodPatterns)
            XCTAssertNotNil(insights.recommendations)
        }
    }
    
    func testInsightsWithData() async {
        // Given
        await mentalHealthEngine.recordStressEvent(type: .work, intensity: 0.7, trigger: "Deadline")
        await mentalHealthEngine.recordMoodAssessment(mood: .happy, intensity: 0.8, notes: "Good day")
        
        // When
        let insights = await mentalHealthEngine.getMentalHealthInsights(timeframe: .week)
        
        // Then
        XCTAssertFalse(insights.commonStressors.isEmpty)
        XCTAssertFalse(insights.moodPatterns.isEmpty)
    }
    
    // MARK: - Wellness Preferences Tests
    
    func testSetWellnessPreferences() async {
        // Given
        let preferences = WellnessPreferences(
            stressManagement: .meditation,
            moodTracking: .daily,
            meditation: .guided,
            exercise: .yoga,
            socialConnection: .family
        )
        
        // When
        await mentalHealthEngine.setWellnessPreferences(preferences)
        
        // Then
        let currentPreferences = mentalHealthEngine.getUserWellnessPreferences()
        XCTAssertEqual(currentPreferences.stressManagement, .meditation)
        XCTAssertEqual(currentPreferences.moodTracking, .daily)
        XCTAssertEqual(currentPreferences.meditation, .guided)
        XCTAssertEqual(currentPreferences.exercise, .yoga)
        XCTAssertEqual(currentPreferences.socialConnection, .family)
    }
    
    func testPreferencesUpdateRecommendations() async throws {
        // Given
        try await mentalHealthEngine.startMonitoring()
        let initialRecommendations = try await mentalHealthEngine.generateWellnessRecommendations()
        
        let preferences = WellnessPreferences(
            stressManagement: .breathing,
            moodTracking: .weekly,
            meditation: .mindfulness,
            exercise: .walking,
            socialConnection: .friends
        )
        
        // When
        await mentalHealthEngine.setWellnessPreferences(preferences)
        
        // Then
        let updatedRecommendations = mentalHealthEngine.wellnessRecommendations
        XCTAssertNotEqual(initialRecommendations.count, updatedRecommendations.count)
    }
    
    // MARK: - Stress Prediction Tests
    
    func testGetStressPrediction() async throws {
        // Given
        try await mentalHealthEngine.startMonitoring()
        
        // When
        let prediction = try await mentalHealthEngine.getStressPrediction()
        
        // Then
        XCTAssertNotNil(prediction)
        XCTAssertTrue(prediction.confidence >= 0.0 && prediction.confidence <= 1.0)
        XCTAssertTrue(prediction.timeframe > 0)
        XCTAssertNotNil(prediction.factors)
        XCTAssertNotNil(prediction.recommendations)
    }
    
    func testStressPredictionWithoutMonitoring() async throws {
        // Given
        XCTAssertFalse(mentalHealthEngine.isMonitoringActive)
        
        // When
        let prediction = try await mentalHealthEngine.getStressPrediction()
        
        // Then
        XCTAssertNotNil(prediction)
        XCTAssertNotNil(prediction.predictedStressLevel)
    }
    
    // MARK: - Voice Coaching Tests
    
    func testProvideMentalHealthCoaching() async {
        // Given
        let message = "Let's practice deep breathing"
        
        // When & Then
        // This test verifies the method doesn't crash
        await mentalHealthEngine.provideMentalHealthCoaching(message: message)
        
        // Note: Actual voice synthesis testing would require more complex setup
        // This test ensures the method executes without errors
    }
    
    // MARK: - Data Persistence Tests
    
    func testMentalHealthHistoryPersistence() async throws {
        // Given
        try await mentalHealthEngine.startMonitoring()
        let initialCount = mentalHealthEngine.mentalHealthHistory.count
        
        // When
        await mentalHealthEngine.stopMonitoring()
        
        // Then
        XCTAssertEqual(mentalHealthEngine.mentalHealthHistory.count, initialCount + 1)
        
        let record = mentalHealthEngine.mentalHealthHistory.last
        XCTAssertNotNil(record)
        XCTAssertNotNil(record?.mentalState)
        XCTAssertTrue(record?.duration ?? 0 > 0)
    }
    
    func testStressEventsPersistence() async {
        // Given
        let eventCount = 5
        
        // When
        for i in 0..<eventCount {
            await mentalHealthEngine.recordStressEvent(
                type: .work,
                intensity: Double(i) / Double(eventCount),
                trigger: "Event \(i)"
            )
        }
        
        // Then
        XCTAssertEqual(mentalHealthEngine.stressEvents.count, eventCount)
        
        for (index, event) in mentalHealthEngine.stressEvents.enumerated() {
            XCTAssertEqual(event.type, .work)
            XCTAssertEqual(event.intensity, Double(index) / Double(eventCount), accuracy: 0.01)
            XCTAssertEqual(event.trigger, "Event \(index)")
        }
    }
    
    func testMoodTrendsPersistence() async {
        // Given
        let moodCount = 3
        let moods: [MoodType] = [.happy, .neutral, .sad]
        
        // When
        for (index, mood) in moods.enumerated() {
            await mentalHealthEngine.recordMoodAssessment(
                mood: mood,
                intensity: Double(index + 1) / Double(moodCount),
                notes: "Mood \(index)"
            )
        }
        
        // Then
        XCTAssertEqual(mentalHealthEngine.moodTrends.count, moodCount)
        
        for (index, moodRecord) in mentalHealthEngine.moodTrends.enumerated() {
            XCTAssertEqual(moodRecord.mood, moods[index])
            XCTAssertEqual(moodRecord.intensity, Double(index + 1) / Double(moodCount), accuracy: 0.01)
            XCTAssertEqual(moodRecord.notes, "Mood \(index)")
        }
    }
    
    // MARK: - Error Handling Tests
    
    func testErrorHandling() async {
        // Given
        let failingEngine = AdvancedMentalHealthEngine(
            healthDataManager: MockFailingHealthDataManager(),
            predictionEngine: predictionEngine,
            analyticsEngine: analyticsEngine
        )
        
        // When
        do {
            try await failingEngine.startMonitoring()
            XCTFail("Should have thrown an error")
        } catch {
            // Then
            XCTAssertNotNil(failingEngine.lastError)
            XCTAssertFalse(failingEngine.isMonitoringActive)
        }
    }
    
    func testAnalysisErrorHandling() async {
        // Given
        let failingEngine = AdvancedMentalHealthEngine(
            healthDataManager: healthDataManager,
            predictionEngine: MockFailingPredictionEngine(),
            analyticsEngine: analyticsEngine
        )
        
        try? await failingEngine.startMonitoring()
        
        // When & Then
        do {
            _ = try await failingEngine.analyzeMentalHealth()
            XCTFail("Should have thrown an error")
        } catch {
            XCTAssertNotNil(failingEngine.lastError)
        }
    }
    
    // MARK: - Performance Tests
    
    func testPerformanceAnalysis() {
        measure {
            let expectation = XCTestExpectation(description: "Performance test")
            
            Task {
                try? await mentalHealthEngine.startMonitoring()
                _ = try? await mentalHealthEngine.analyzeMentalHealth()
                await mentalHealthEngine.stopMonitoring()
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 5.0)
        }
    }
    
    func testPerformanceRecommendations() {
        measure {
            let expectation = XCTestExpectation(description: "Recommendations performance test")
            
            Task {
                try? await mentalHealthEngine.startMonitoring()
                _ = try? await mentalHealthEngine.generateWellnessRecommendations()
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 5.0)
        }
    }
    
    // MARK: - Integration Tests
    
    func testIntegrationWithHealthDataManager() async {
        // Given
        XCTAssertNotNil(mentalHealthEngine.healthDataManager)
        
        // When & Then
        // This test verifies the engine can work with the health data manager
        try? await mentalHealthEngine.startMonitoring()
        XCTAssertTrue(mentalHealthEngine.isMonitoringActive || mentalHealthEngine.lastError != nil)
    }
    
    func testIntegrationWithPredictionEngine() async throws {
        // Given
        XCTAssertNotNil(mentalHealthEngine.predictionEngine)
        
        // When
        let prediction = try await mentalHealthEngine.getStressPrediction()
        
        // Then
        XCTAssertNotNil(prediction)
    }
    
    func testIntegrationWithAnalyticsEngine() async {
        // Given
        XCTAssertNotNil(mentalHealthEngine.analyticsEngine)
        
        // When
        await mentalHealthEngine.recordStressEvent(type: .work, intensity: 0.5, trigger: "Test")
        
        // Then
        // Analytics should be tracked (implementation dependent)
        XCTAssertEqual(mentalHealthEngine.stressEvents.count, 1)
    }
}

// MARK: - Mock Classes

class MockFailingHealthDataManager: HealthDataManager {
    override func requestHealthKitPermissions() async throws {
        throw NSError(domain: "MockError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock failure"])
    }
}

class MockFailingPredictionEngine: AdvancedHealthPredictionEngine {
    override func generatePredictions() async throws -> ComprehensiveHealthPrediction {
        throw NSError(domain: "MockError", code: 2, userInfo: [NSLocalizedDescriptionKey: "Mock prediction failure"])
    }
}

// MARK: - Test Extensions

extension AdvancedMentalHealthEngine {
    var healthDataManager: HealthDataManager {
        // Access the private property for testing
        return Mirror(reflecting: self).children.first { $0.label == "healthDataManager" }?.value as! HealthDataManager
    }
    
    var predictionEngine: AdvancedHealthPredictionEngine {
        return Mirror(reflecting: self).children.first { $0.label == "predictionEngine" }?.value as! AdvancedHealthPredictionEngine
    }
    
    var analyticsEngine: AnalyticsEngine {
        return Mirror(reflecting: self).children.first { $0.label == "analyticsEngine" }?.value as! AnalyticsEngine
    }
} 
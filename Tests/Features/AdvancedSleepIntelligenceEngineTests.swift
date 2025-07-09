import XCTest
import HealthKit
import Combine
@testable import HealthAI2030

@available(iOS 18.0, macOS 15.0, *)
final class AdvancedSleepIntelligenceEngineTests: XCTestCase {
    
    var sleepEngine: AdvancedSleepIntelligenceEngine!
    var healthDataManager: HealthDataManager!
    var predictionEngine: AdvancedHealthPredictionEngine!
    var analyticsEngine: AnalyticsEngine!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        healthDataManager = HealthDataManager()
        predictionEngine = AdvancedHealthPredictionEngine()
        analyticsEngine = AnalyticsEngine()
        
        sleepEngine = AdvancedSleepIntelligenceEngine(
            healthDataManager: healthDataManager,
            predictionEngine: predictionEngine,
            analyticsEngine: analyticsEngine
        )
    }
    
    override func tearDownWithError() throws {
        sleepEngine = nil
        healthDataManager = nil
        predictionEngine = nil
        analyticsEngine = nil
        
        try super.tearDownWithError()
    }
    
    // MARK: - Sleep Tracking Tests
    
    func testStartSleepTracking() async throws {
        // Given - No active session
        
        // When
        let session = try await sleepEngine.startSleepTracking()
        
        // Then
        XCTAssertNotNil(session)
        XCTAssertEqual(session.status, .tracking)
        XCTAssertNil(session.endTime)
        XCTAssertTrue(sleepEngine.isSleepTrackingActive)
        XCTAssertEqual(sleepEngine.currentSleepSession?.id, session.id)
        XCTAssertNotNil(session.environment)
    }
    
    func testStartSleepTrackingWithActiveSession() async throws {
        // Given - Active session already exists
        let firstSession = try await sleepEngine.startSleepTracking()
        
        // When & Then - Should throw error or handle gracefully
        do {
            let secondSession = try await sleepEngine.startSleepTracking()
            // If no error, second session should replace first
            XCTAssertNotEqual(firstSession.id, secondSession.id)
        } catch {
            // Error is acceptable behavior
            XCTAssertTrue(error is SleepError)
        }
    }
    
    func testEndSleepTracking() async throws {
        // Given
        let session = try await sleepEngine.startSleepTracking()
        
        // When
        let analysis = try await sleepEngine.endSleepTracking()
        
        // Then
        XCTAssertFalse(sleepEngine.isSleepTrackingActive)
        XCTAssertNil(sleepEngine.currentSleepSession)
        XCTAssertEqual(session.status, .completed)
        XCTAssertNotNil(session.endTime)
        XCTAssertNotNil(session.analysis)
        XCTAssertNotNil(analysis)
        XCTAssertGreaterThan(sleepEngine.sleepScore, 0)
    }
    
    func testEndSleepTrackingWithoutActiveSession() async {
        // Given - No active session
        
        // When & Then
        do {
            _ = try await sleepEngine.endSleepTracking()
            XCTFail("Should throw error when no session is active")
        } catch {
            XCTAssertTrue(error is SleepError)
        }
    }
    
    // MARK: - Sleep Analysis Tests
    
    func testAnalyzeSleepData() async throws {
        // Given
        let sleepData = createMockSleepData()
        
        // When
        let analysis = try await sleepEngine.analyzeSleepData(sleepData)
        
        // Then
        XCTAssertNotNil(analysis)
        XCTAssertGreaterThan(analysis.duration, 0)
        XCTAssertGreaterThanOrEqual(analysis.efficiency, 0)
        XCTAssertLessThanOrEqual(analysis.efficiency, 1)
        XCTAssertNotNil(sleepEngine.sleepInsights)
    }
    
    func testAnalyzeSleepDataWithEmptyData() async throws {
        // Given
        let emptyData: [HKCategorySample] = []
        
        // When
        let analysis = try await sleepEngine.analyzeSleepData(emptyData)
        
        // Then
        XCTAssertNotNil(analysis)
        // Should handle empty data gracefully
    }
    
    func testSleepScoreCalculation() async throws {
        // Given
        let session = try await sleepEngine.startSleepTracking()
        let analysis = try await sleepEngine.endSleepTracking()
        
        // When
        let score = sleepEngine.sleepScore
        
        // Then
        XCTAssertGreaterThanOrEqual(score, 0)
        XCTAssertLessThanOrEqual(score, 1)
        
        // Verify score calculation logic
        let expectedScore = calculateExpectedSleepScore(analysis: analysis)
        XCTAssertEqual(score, expectedScore, accuracy: 0.1)
    }
    
    // MARK: - Optimization Tests
    
    func testGenerateOptimizationRecommendations() async throws {
        // Given
        let session = try await sleepEngine.startSleepTracking()
        let analysis = try await sleepEngine.endSleepTracking()
        
        // When
        let recommendations = try await sleepEngine.generateOptimizationRecommendations(analysis: analysis)
        
        // Then
        XCTAssertFalse(recommendations.isEmpty)
        XCTAssertEqual(sleepEngine.optimizationRecommendations.count, recommendations.count)
        
        // Verify recommendation structure
        for recommendation in recommendations {
            XCTAssertFalse(recommendation.title.isEmpty)
            XCTAssertFalse(recommendation.description.isEmpty)
            XCTAssertGreaterThan(recommendation.estimatedImpact, 0)
            XCTAssertLessThanOrEqual(recommendation.estimatedImpact, 1)
        }
    }
    
    func testGenerateOptimizationRecommendationsWithoutAnalysis() async {
        // Given - No analysis available
        
        // When & Then
        do {
            _ = try await sleepEngine.generateOptimizationRecommendations()
            XCTFail("Should throw error when no analysis is available")
        } catch {
            XCTAssertTrue(error is SleepError)
        }
    }
    
    func testOptimizationRecommendationsPrioritized() async throws {
        // Given
        let session = try await sleepEngine.startSleepTracking()
        let analysis = try await sleepEngine.endSleepTracking()
        
        // When
        let recommendations = try await sleepEngine.generateOptimizationRecommendations(analysis: analysis)
        
        // Then
        let priorities = recommendations.map { $0.priority.rawValue }
        let sortedPriorities = priorities.sorted(by: >)
        XCTAssertEqual(priorities, sortedPriorities, "Recommendations should be sorted by priority")
    }
    
    func testOptimizationRecommendationsByType() async throws {
        // Given
        let session = try await sleepEngine.startSleepTracking()
        let analysis = try await sleepEngine.endSleepTracking()
        
        // When
        let recommendations = try await sleepEngine.generateOptimizationRecommendations(analysis: analysis)
        
        // Then
        let types = Set(recommendations.map { $0.type })
        XCTAssertTrue(types.count > 1, "Should have multiple optimization types")
        
        // Verify specific types based on analysis
        if analysis.efficiency < 0.85 {
            let efficiencyRecommendations = recommendations.filter { $0.type == .efficiency }
            XCTAssertFalse(efficiencyRecommendations.isEmpty)
        }
        
        if analysis.deepSleepPercentage < 0.2 {
            let deepSleepRecommendations = recommendations.filter { $0.type == .deepSleep }
            XCTAssertFalse(deepSleepRecommendations.isEmpty)
        }
    }
    
    // MARK: - Insights Tests
    
    func testGetSleepInsights() async {
        // Given
        let timeframe: Timeframe = .week
        
        // When
        let insights = await sleepEngine.getSleepInsights(timeframe: timeframe)
        
        // Then
        XCTAssertNotNil(insights)
        XCTAssertGreaterThanOrEqual(insights.averageSleepDuration, 0)
        XCTAssertGreaterThanOrEqual(insights.averageSleepEfficiency, 0)
        XCTAssertLessThanOrEqual(insights.averageSleepEfficiency, 1)
        XCTAssertNotNil(insights.sleepQualityTrend)
    }
    
    func testGetSleepInsightsWithHistory() async throws {
        // Given
        let session1 = try await sleepEngine.startSleepTracking()
        let analysis1 = try await sleepEngine.endSleepTracking()
        
        let session2 = try await sleepEngine.startSleepTracking()
        let analysis2 = try await sleepEngine.endSleepTracking()
        
        // When
        let insights = await sleepEngine.getSleepInsights(timeframe: .week)
        
        // Then
        XCTAssertNotNil(insights)
        XCTAssertGreaterThan(insights.averageSleepDuration, 0)
        XCTAssertGreaterThan(insights.averageSleepEfficiency, 0)
    }
    
    func testSleepInsightsTrendAnalysis() async throws {
        // Given
        // Create multiple sessions with varying quality
        for i in 0..<5 {
            let session = try await sleepEngine.startSleepTracking()
            // Simulate different sleep quality
            session.analysis = createMockAnalysis(efficiency: 0.7 + Double(i) * 0.05)
            await sleepEngine.endSleepTracking()
        }
        
        // When
        let insights = await sleepEngine.getSleepInsights(timeframe: .week)
        
        // Then
        XCTAssertNotNil(insights.sleepQualityTrend)
        // Should detect improving trend
        XCTAssertEqual(insights.sleepQualityTrend, .improving)
    }
    
    func testCommonIssuesIdentification() async throws {
        // Given
        // Create sessions with common issues
        for _ in 0..<3 {
            let session = try await sleepEngine.startSleepTracking()
            session.analysis = createMockAnalysis(duration: 6.0, efficiency: 0.75)
            await sleepEngine.endSleepTracking()
        }
        
        // When
        let insights = await sleepEngine.getSleepInsights(timeframe: .week)
        
        // Then
        XCTAssertFalse(insights.commonIssues.isEmpty)
        XCTAssertTrue(insights.commonIssues.contains("Short sleep duration"))
    }
    
    // MARK: - Preferences Tests
    
    func testSetSleepPreferences() async {
        // Given
        let preferences = SleepPreferences(
            targetBedtime: Calendar.current.date(bySettingHour: 22, minute: 0, second: 0, of: Date()) ?? Date(),
            targetWakeTime: Calendar.current.date(bySettingHour: 7, minute: 0, second: 0, of: Date()) ?? Date(),
            targetDuration: 8.0,
            environmentPreferences: .cool
        )
        
        // When
        await sleepEngine.setSleepPreferences(preferences)
        
        // Then
        let savedPreferences = sleepEngine.getUserSleepPreferences()
        XCTAssertEqual(savedPreferences.targetDuration, 8.0)
        XCTAssertEqual(savedPreferences.environmentPreferences, .cool)
    }
    
    func testSleepScheduleOptimization() async throws {
        // Given
        let preferences = SleepPreferences(
            targetBedtime: Calendar.current.date(bySettingHour: 22, minute: 0, second: 0, of: Date()) ?? Date(),
            targetWakeTime: Calendar.current.date(bySettingHour: 7, minute: 0, second: 0, of: Date()) ?? Date(),
            targetDuration: 8.0,
            environmentPreferences: .standard
        )
        await sleepEngine.setSleepPreferences(preferences)
        
        // When
        let optimization = try await sleepEngine.optimizeSleepSchedule()
        
        // Then
        XCTAssertNotNil(optimization)
        XCTAssertGreaterThanOrEqual(optimization.confidence, 0)
        XCTAssertLessThanOrEqual(optimization.confidence, 1)
        XCTAssertFalse(optimization.reasoning.isEmpty)
        
        if let schedule = optimization.recommendedSchedule {
            XCTAssertGreaterThan(schedule.duration, 0)
            XCTAssertLessThan(schedule.duration, 12) // Reasonable sleep duration
        }
    }
    
    // MARK: - Voice Coaching Tests
    
    func testProvideSleepCoaching() async {
        // Given
        let message = "Great job on your sleep last night!"
        
        // When & Then - Should not crash
        await sleepEngine.provideSleepCoaching(message)
        
        // Note: We can't easily test AVSpeechSynthesizer in unit tests
        // This test ensures the method doesn't crash
    }
    
    // MARK: - Performance Tests
    
    func testSleepTrackingPerformance() async throws {
        // Given
        let iterations = 10
        
        // When
        let startTime = CFAbsoluteTimeGetCurrent()
        
        for _ in 0..<iterations {
            let session = try await sleepEngine.startSleepTracking()
            _ = try await sleepEngine.endSleepTracking()
        }
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let duration = endTime - startTime
        
        // Then
        let averageTime = duration / Double(iterations)
        XCTAssertLessThan(averageTime, 2.0, "Average sleep tracking time should be less than 2 seconds")
    }
    
    func testAnalysisPerformance() async throws {
        // Given
        let sleepData = createMockSleepData()
        
        // When
        let startTime = CFAbsoluteTimeGetCurrent()
        _ = try await sleepEngine.analyzeSleepData(sleepData)
        let endTime = CFAbsoluteTimeGetCurrent()
        
        let duration = endTime - startTime
        
        // Then
        XCTAssertLessThan(duration, 3.0, "Sleep analysis should complete within 3 seconds")
    }
    
    func testRecommendationGenerationPerformance() async throws {
        // Given
        let session = try await sleepEngine.startSleepTracking()
        let analysis = try await sleepEngine.endSleepTracking()
        
        // When
        let startTime = CFAbsoluteTimeGetCurrent()
        _ = try await sleepEngine.generateOptimizationRecommendations(analysis: analysis)
        let endTime = CFAbsoluteTimeGetCurrent()
        
        let duration = endTime - startTime
        
        // Then
        XCTAssertLessThan(duration, 2.0, "Recommendation generation should complete within 2 seconds")
    }
    
    // MARK: - Integration Tests
    
    func testFullSleepWorkflow() async throws {
        // Given
        let preferences = SleepPreferences(
            targetBedtime: Calendar.current.date(bySettingHour: 22, minute: 0, second: 0, of: Date()) ?? Date(),
            targetWakeTime: Calendar.current.date(bySettingHour: 7, minute: 0, second: 0, of: Date()) ?? Date(),
            targetDuration: 8.0,
            environmentPreferences: .standard
        )
        
        // When - Complete sleep workflow
        await sleepEngine.setSleepPreferences(preferences)
        let session = try await sleepEngine.startSleepTracking()
        let analysis = try await sleepEngine.endSleepTracking()
        let recommendations = try await sleepEngine.generateOptimizationRecommendations(analysis: analysis)
        let insights = await sleepEngine.getSleepInsights(timeframe: .week)
        let optimization = try await sleepEngine.optimizeSleepSchedule()
        
        // Then
        XCTAssertEqual(session.status, .completed)
        XCTAssertNotNil(session.analysis)
        XCTAssertFalse(recommendations.isEmpty)
        XCTAssertNotNil(insights)
        XCTAssertNotNil(optimization)
        XCTAssertGreaterThan(sleepEngine.sleepScore, 0)
    }
    
    // MARK: - Error Handling Tests
    
    func testErrorHandlingInSleepTracking() async {
        // Given - Mock failure scenario
        // This would require mocking the dependencies to simulate failures
        
        // When & Then
        // Test would verify that errors are properly handled and lastError is set
    }
    
    func testErrorHandlingInAnalysis() async {
        // Given - Mock failure scenario
        
        // When & Then
        // Test would verify that analysis errors are handled gracefully
    }
    
    // MARK: - Edge Cases Tests
    
    func testMultipleRapidSessions() async throws {
        // Given
        let sessions: [SleepSession] = []
        
        // When
        for _ in 0..<5 {
            let session = try await sleepEngine.startSleepTracking()
            _ = try await sleepEngine.endSleepTracking()
        }
        
        // Then
        XCTAssertFalse(sleepEngine.isSleepTrackingActive)
        XCTAssertGreaterThan(sleepEngine.sleepHistory.count, 0)
    }
    
    func testSessionWithNoAnalysis() async throws {
        // Given
        let session = try await sleepEngine.startSleepTracking()
        
        // When
        _ = try await sleepEngine.endSleepTracking()
        
        // Then
        XCTAssertNotNil(session.analysis)
        XCTAssertGreaterThan(session.analysis?.duration ?? 0, 0)
    }
    
    func testRecommendationsWithMinimalData() async throws {
        // Given
        let session = try await sleepEngine.startSleepTracking()
        let analysis = try await sleepEngine.endSleepTracking()
        
        // When
        let recommendations = try await sleepEngine.generateOptimizationRecommendations(analysis: analysis)
        
        // Then
        XCTAssertFalse(recommendations.isEmpty, "Should generate recommendations even with minimal data")
    }
    
    // MARK: - Helper Methods
    
    private func createMockSleepData() -> [HKCategorySample] {
        // Create mock HealthKit sleep data
        return []
    }
    
    private func createMockAnalysis(
        duration: TimeInterval = 8.0,
        efficiency: Double = 0.85,
        deepSleepPercentage: Double = 0.22,
        remSleepPercentage: Double = 0.25,
        lightSleepPercentage: Double = 0.48,
        awakePercentage: Double = 0.05
    ) -> SleepAnalysis {
        return SleepAnalysis(
            sessionId: UUID(),
            duration: duration,
            efficiency: efficiency,
            deepSleepPercentage: deepSleepPercentage,
            remSleepPercentage: remSleepPercentage,
            lightSleepPercentage: lightSleepPercentage,
            awakePercentage: awakePercentage,
            sleepStages: [],
            biometrics: [],
            insights: [],
            timestamp: Date()
        )
    }
    
    private func calculateExpectedSleepScore(analysis: SleepAnalysis) -> Double {
        var score = 0.0
        
        // Duration score (25%)
        let durationScore = min(analysis.duration / 8.0, 1.0) * 0.25
        score += durationScore
        
        // Efficiency score (30%)
        score += analysis.efficiency * 0.30
        
        // Deep sleep score (25%)
        score += min(analysis.deepSleepPercentage / 0.25, 1.0) * 0.25
        
        // REM sleep score (20%)
        score += min(analysis.remSleepPercentage / 0.25, 1.0) * 0.20
        
        return min(score, 1.0)
    }
}

// MARK: - Test Helpers

extension AdvancedSleepIntelligenceEngineTests {
    
    func createMockEnvironment() -> SleepEnvironment {
        return SleepEnvironment(
            temperature: 70.0,
            humidity: 0.5,
            lightLevel: 0.2,
            noiseLevel: 0.3,
            airQuality: 0.8,
            timestamp: Date()
        )
    }
    
    func createMockSleepStage(type: SleepStage.StageType, duration: TimeInterval) -> SleepStage {
        return SleepStage(
            type: type,
            startTime: Date(),
            endTime: Date().addingTimeInterval(duration),
            duration: duration
        )
    }
    
    func createMockBiometric(type: SleepBiometric.BiometricType, value: Double) -> SleepBiometric {
        return SleepBiometric(
            type: type,
            value: value,
            timestamp: Date()
        )
    }
} 
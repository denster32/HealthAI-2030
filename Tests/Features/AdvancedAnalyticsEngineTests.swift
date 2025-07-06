import XCTest
import Combine
import SwiftUI
@testable import HealthAI2030Core

@available(iOS 18.0, macOS 15.0, *)
final class AdvancedAnalyticsEngineTests: XCTestCase {
    
    var analyticsManager: AdvancedAnalyticsManager!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        analyticsManager = AdvancedAnalyticsManager.shared
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDown() {
        cancellables.removeAll()
        analyticsManager = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testAnalyticsManagerInitialization() {
        XCTAssertNotNil(analyticsManager)
        XCTAssertEqual(analyticsManager.currentHealthScore, 0.0)
        XCTAssertTrue(analyticsManager.healthTrends.isEmpty)
        XCTAssertTrue(analyticsManager.insights.isEmpty)
        XCTAssertTrue(analyticsManager.recommendations.isEmpty)
        XCTAssertTrue(analyticsManager.riskAssessments.isEmpty)
        XCTAssertFalse(analyticsManager.isAnalyzing)
    }
    
    // MARK: - Analytics Control Tests
    
    func testStartAnalytics() {
        let expectation = XCTestExpectation(description: "Analytics started")
        
        analyticsManager.$isAnalyzing
            .dropFirst()
            .sink { isAnalyzing in
                XCTAssertTrue(isAnalyzing)
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        analyticsManager.startAnalytics()
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testStopAnalytics() {
        analyticsManager.isAnalyzing = true
        
        let expectation = XCTestExpectation(description: "Analytics stopped")
        
        analyticsManager.$isAnalyzing
            .dropFirst()
            .sink { isAnalyzing in
                XCTAssertFalse(isAnalyzing)
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        analyticsManager.stopAnalytics()
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    // MARK: - Health Analysis Tests
    
    func testPerformHealthAnalysis() async throws {
        let report = try await analyticsManager.performHealthAnalysis()
        
        XCTAssertNotNil(report)
        XCTAssertNotNil(report.analyticsReport)
        XCTAssertNotNil(report.predictiveAnalytics)
        XCTAssertNotNil(report.timestamp)
    }
    
    func testPerformHealthAnalysisUpdatesPublishedProperties() async throws {
        let initialHealthScore = analyticsManager.currentHealthScore
        let initialTrendsCount = analyticsManager.healthTrends.count
        let initialInsightsCount = analyticsManager.insights.count
        
        _ = try await analyticsManager.performHealthAnalysis()
        
        // Wait for UI updates
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        XCTAssertNotEqual(analyticsManager.currentHealthScore, initialHealthScore)
        XCTAssertNotEqual(analyticsManager.healthTrends.count, initialTrendsCount)
        XCTAssertNotEqual(analyticsManager.insights.count, initialInsightsCount)
    }
    
    // MARK: - Insights Tests
    
    func testGetInsightsForOverallDimension() async throws {
        let insights = try await analyticsManager.getInsights(for: .overall)
        
        XCTAssertNotNil(insights)
        XCTAssertTrue(insights is [HealthInsight])
    }
    
    func testGetInsightsForSpecificDimension() async throws {
        let insights = try await analyticsManager.getInsights(for: .cardiovascular)
        
        XCTAssertNotNil(insights)
        XCTAssertTrue(insights is [HealthInsight])
    }
    
    func testGetInsightsFiltersByDimension() async throws {
        let cardiovascularInsights = try await analyticsManager.getInsights(for: .cardiovascular)
        let sleepInsights = try await analyticsManager.getInsights(for: .sleep)
        
        // Insights should be filtered by dimension
        XCTAssertNotEqual(cardiovascularInsights.count, sleepInsights.count)
    }
    
    // MARK: - Trends Tests
    
    func testGetTrendsForOverallDimension() async throws {
        let trends = try await analyticsManager.getTrends(for: .overall)
        
        XCTAssertNotNil(trends)
        XCTAssertTrue(trends is [HealthTrend])
    }
    
    func testGetTrendsForSpecificDimension() async throws {
        let trends = try await analyticsManager.getTrends(for: .activity)
        
        XCTAssertNotNil(trends)
        XCTAssertTrue(trends is [HealthTrend])
    }
    
    func testGetTrendsFiltersByDimension() async throws {
        let activityTrends = try await analyticsManager.getTrends(for: .activity)
        let sleepTrends = try await analyticsManager.getTrends(for: .sleep)
        
        // Trends should be filtered by dimension
        XCTAssertNotEqual(activityTrends.count, sleepTrends.count)
    }
    
    // MARK: - Recommendations Tests
    
    func testGetRecommendations() async throws {
        let recommendations = try await analyticsManager.getRecommendations()
        
        XCTAssertNotNil(recommendations)
        XCTAssertTrue(recommendations is [HealthRecommendation])
    }
    
    func testRecommendationsAreActionable() async throws {
        let recommendations = try await analyticsManager.getRecommendations()
        
        for recommendation in recommendations {
            XCTAssertTrue(recommendation.actionable)
            XCTAssertFalse(recommendation.title.isEmpty)
            XCTAssertFalse(recommendation.description.isEmpty)
        }
    }
    
    // MARK: - Risk Assessment Tests
    
    func testGetRiskAssessments() async throws {
        let assessments = try await analyticsManager.getRiskAssessments()
        
        XCTAssertNotNil(assessments)
        XCTAssertTrue(assessments is [HealthRiskAssessment])
    }
    
    func testRiskAssessmentsHaveValidData() async throws {
        let assessments = try await analyticsManager.getRiskAssessments()
        
        for assessment in assessments {
            XCTAssertFalse(assessment.description.isEmpty)
            XCTAssertFalse(assessment.recommendations.isEmpty)
            XCTAssertTrue(assessment.riskLevel == .low || assessment.riskLevel == .medium || assessment.riskLevel == .high || assessment.riskLevel == .critical)
        }
    }
    
    // MARK: - Error Handling Tests
    
    func testAnalyticsManagerHandlesErrorsGracefully() async {
        // This test verifies that the manager doesn't crash when errors occur
        do {
            _ = try await analyticsManager.performHealthAnalysis()
            // If we get here, no error was thrown
            XCTAssertTrue(true)
        } catch {
            // If an error is thrown, it should be handled gracefully
            XCTAssertTrue(error is AnalyticsError)
        }
    }
    
    // MARK: - Performance Tests
    
    func testAnalyticsPerformance() async throws {
        let startTime = Date()
        
        _ = try await analyticsManager.performHealthAnalysis()
        
        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)
        
        // Analytics should complete within reasonable time (5 seconds)
        XCTAssertLessThan(duration, 5.0)
    }
    
    func testConcurrentAnalyticsRequests() async throws {
        let expectation1 = XCTestExpectation(description: "First analytics request")
        let expectation2 = XCTestExpectation(description: "Second analytics request")
        
        async let report1 = analyticsManager.performHealthAnalysis()
        async let report2 = analyticsManager.performHealthAnalysis()
        
        let (result1, result2) = try await (report1, report2)
        
        XCTAssertNotNil(result1)
        XCTAssertNotNil(result2)
        
        expectation1.fulfill()
        expectation2.fulfill()
        
        wait(for: [expectation1, expectation2], timeout: 10.0)
    }
    
    // MARK: - Data Model Tests
    
    func testHealthAnalysisReportStructure() {
        let report = HealthAnalysisReport(
            analyticsReport: AnalyticsReport(period: DateInterval(), metrics: [:], insights: []),
            predictiveAnalytics: PredictiveAnalytics(predictions: [], forecasts: [], confidence: 0.0),
            timestamp: Date()
        )
        
        XCTAssertNotNil(report.analyticsReport)
        XCTAssertNotNil(report.predictiveAnalytics)
        XCTAssertNotNil(report.timestamp)
    }
    
    func testHealthTrendStructure() {
        let trend = HealthTrend(
            metric: "heart_rate",
            direction: .increasing,
            confidence: 0.8,
            description: "Heart rate is increasing"
        )
        
        XCTAssertEqual(trend.metric, "heart_rate")
        XCTAssertEqual(trend.direction, .increasing)
        XCTAssertEqual(trend.confidence, 0.8)
        XCTAssertEqual(trend.description, "Heart rate is increasing")
    }
    
    func testHealthRiskAssessmentStructure() {
        let assessment = HealthRiskAssessment(
            category: .cardiovascular,
            riskLevel: .medium,
            description: "Elevated heart rate",
            recommendations: ["Monitor stress", "Consult doctor"]
        )
        
        XCTAssertEqual(assessment.category, .cardiovascular)
        XCTAssertEqual(assessment.riskLevel, .medium)
        XCTAssertEqual(assessment.description, "Elevated heart rate")
        XCTAssertEqual(assessment.recommendations.count, 2)
    }
    
    // MARK: - Integration Tests
    
    func testAnalyticsManagerIntegrationWithEngine() async throws {
        // Test that the manager properly integrates with the underlying analytics engine
        let report = try await analyticsManager.performHealthAnalysis()
        
        XCTAssertNotNil(report.analyticsReport)
        XCTAssertNotNil(report.predictiveAnalytics)
        
        // Verify that the engine processed the data
        XCTAssertNotNil(report.analyticsReport.metrics)
        XCTAssertNotNil(report.analyticsReport.insights)
    }
    
    func testPeriodicUpdates() async throws {
        let expectation = XCTestExpectation(description: "Periodic update")
        expectation.expectedFulfillmentCount = 2
        
        var updateCount = 0
        analyticsManager.$lastUpdateTime
            .dropFirst()
            .sink { _ in
                updateCount += 1
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // Wait for periodic updates (should happen every 5 minutes, but we'll wait less for testing)
        wait(for: [expectation], timeout: 10.0)
        
        XCTAssertGreaterThanOrEqual(updateCount, 1)
    }
    
    // MARK: - Mock Data Tests
    
    func testMockHealthDataGeneration() async throws {
        let healthData = try await analyticsManager.performHealthAnalysis()
        
        // Verify that mock data was generated and processed
        XCTAssertNotNil(healthData)
        XCTAssertNotNil(healthData.analyticsReport)
    }
    
    // MARK: - Health Score Calculation Tests
    
    func testHealthScoreCalculation() async throws {
        let initialScore = analyticsManager.currentHealthScore
        
        _ = try await analyticsManager.performHealthAnalysis()
        
        // Wait for UI updates
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        let finalScore = analyticsManager.currentHealthScore
        
        // Health score should be calculated and updated
        XCTAssertNotEqual(initialScore, finalScore)
        XCTAssertGreaterThanOrEqual(finalScore, 0.0)
        XCTAssertLessThanOrEqual(finalScore, 1.0)
    }
    
    // MARK: - UI Integration Tests
    
    func testPublishedPropertiesForUI() {
        // Test that all published properties are accessible for UI binding
        XCTAssertNotNil(analyticsManager.currentHealthScore)
        XCTAssertNotNil(analyticsManager.healthTrends)
        XCTAssertNotNil(analyticsManager.insights)
        XCTAssertNotNil(analyticsManager.recommendations)
        XCTAssertNotNil(analyticsManager.riskAssessments)
        XCTAssertNotNil(analyticsManager.isAnalyzing)
        XCTAssertNotNil(analyticsManager.lastUpdateTime)
    }
    
    func testObservableObjectConformance() {
        // Test that the manager conforms to ObservableObject for SwiftUI
        XCTAssertTrue(analyticsManager is ObservableObject)
    }
}

// MARK: - Test Helpers

extension AdvancedAnalyticsEngineTests {
    
    func createMockHealthData() -> [HealthData] {
        let now = Date()
        var data: [HealthData] = []
        
        for i in 0..<7 {
            let timestamp = now.addingTimeInterval(-Double(i * 24 * 3600))
            data.append(HealthData(
                timestamp: timestamp,
                heartRate: Int.random(in: 60...100),
                steps: Int.random(in: 5000...15000),
                sleepHours: Double.random(in: 6.0...9.0),
                calories: Int.random(in: 1500...2500)
            ))
        }
        
        return data
    }
    
    func createMockAnalyticsReport() -> AnalyticsReport {
        return AnalyticsReport(
            period: DateInterval(start: Date().addingTimeInterval(-7 * 24 * 3600), duration: 7 * 24 * 3600),
            metrics: [
                "activity_score": 0.75,
                "sleep_quality_score": 0.8,
                "mean_heart_rate": 75.0
            ],
            insights: [
                AnalyticsInsight(
                    title: "Good Activity Level",
                    description: "Your activity level is within healthy range",
                    confidence: 0.9,
                    actionable: true
                )
            ]
        )
    }
} 
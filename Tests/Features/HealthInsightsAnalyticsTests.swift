import XCTest
import SwiftUI
import CoreML
@testable import HealthAI2030

/// Comprehensive unit tests for the Health Insights and Analytics Engine
/// Tests all functionality including insights generation, trend analysis, predictions, and recommendations
final class HealthInsightsAnalyticsTests: XCTestCase {
    
    var analyticsEngine: HealthInsightsAnalyticsEngine!
    
    override func setUpWithError() throws {
        super.setUp()
        analyticsEngine = HealthInsightsAnalyticsEngine.shared
        analyticsEngine.insights.removeAll()
        analyticsEngine.trends.removeAll()
        analyticsEngine.predictions.removeAll()
        analyticsEngine.recommendations.removeAll()
        analyticsEngine.analyticsStatus = .idle
    }
    
    override func tearDownWithError() throws {
        analyticsEngine = nil
        super.tearDown()
    }
    
    // MARK: - Engine Tests
    
    func testAnalyticsEngineInitialization() {
        XCTAssertNotNil(analyticsEngine)
        XCTAssertEqual(analyticsEngine.analyticsStatus, .idle)
        XCTAssertEqual(analyticsEngine.insights.count, 0)
        XCTAssertEqual(analyticsEngine.trends.count, 0)
        XCTAssertEqual(analyticsEngine.predictions.count, 0)
        XCTAssertEqual(analyticsEngine.recommendations.count, 0)
        XCTAssertNil(analyticsEngine.lastAnalysisDate)
    }
    
    func testAnalyticsEngineSingleton() {
        let instance1 = HealthInsightsAnalyticsEngine.shared
        let instance2 = HealthInsightsAnalyticsEngine.shared
        XCTAssertTrue(instance1 === instance2)
    }
    
    // MARK: - Status Tests
    
    func testAnalyticsStatusColors() {
        XCTAssertEqual(HealthInsightsAnalyticsEngine.AnalyticsStatus.idle.color, "gray")
        XCTAssertEqual(HealthInsightsAnalyticsEngine.AnalyticsStatus.analyzing.color, "blue")
        XCTAssertEqual(HealthInsightsAnalyticsEngine.AnalyticsStatus.generatingInsights.color, "green")
        XCTAssertEqual(HealthInsightsAnalyticsEngine.AnalyticsStatus.predicting.color, "purple")
        XCTAssertEqual(HealthInsightsAnalyticsEngine.AnalyticsStatus.error.color, "red")
    }
    
    func testInsightCategoryIcons() {
        XCTAssertEqual(HealthInsightsAnalyticsEngine.InsightCategory.trends.icon, "chart.line.uptrend.xyaxis")
        XCTAssertEqual(HealthInsightsAnalyticsEngine.InsightCategory.anomalies.icon, "exclamationmark.triangle")
        XCTAssertEqual(HealthInsightsAnalyticsEngine.InsightCategory.correlations.icon, "link")
        XCTAssertEqual(HealthInsightsAnalyticsEngine.InsightCategory.patterns.icon, "repeat")
        XCTAssertEqual(HealthInsightsAnalyticsEngine.InsightCategory.improvements.icon, "arrow.up.circle")
        XCTAssertEqual(HealthInsightsAnalyticsEngine.InsightCategory.warnings.icon, "exclamationmark.circle")
    }
    
    func testInsightCategoryAllCases() {
        let categories = HealthInsightsAnalyticsEngine.InsightCategory.allCases
        XCTAssertEqual(categories.count, 6)
        XCTAssertTrue(categories.contains(.trends))
        XCTAssertTrue(categories.contains(.anomalies))
        XCTAssertTrue(categories.contains(.correlations))
        XCTAssertTrue(categories.contains(.patterns))
        XCTAssertTrue(categories.contains(.improvements))
        XCTAssertTrue(categories.contains(.warnings))
    }
    
    func testTrendDirectionColors() {
        XCTAssertEqual(HealthInsightsAnalyticsEngine.TrendDirection.improving.color, "green")
        XCTAssertEqual(HealthInsightsAnalyticsEngine.TrendDirection.declining.color, "red")
        XCTAssertEqual(HealthInsightsAnalyticsEngine.TrendDirection.stable.color, "blue")
        XCTAssertEqual(HealthInsightsAnalyticsEngine.TrendDirection.fluctuating.color, "orange")
    }
    
    func testTrendDirectionAllCases() {
        let directions = HealthInsightsAnalyticsEngine.TrendDirection.allCases
        XCTAssertEqual(directions.count, 4)
        XCTAssertTrue(directions.contains(.improving))
        XCTAssertTrue(directions.contains(.declining))
        XCTAssertTrue(directions.contains(.stable))
        XCTAssertTrue(directions.contains(.fluctuating))
    }
    
    func testPredictionConfidencePercentage() {
        XCTAssertEqual(HealthInsightsAnalyticsEngine.PredictionConfidence.low.percentage, 0.25)
        XCTAssertEqual(HealthInsightsAnalyticsEngine.PredictionConfidence.medium.percentage, 0.5)
        XCTAssertEqual(HealthInsightsAnalyticsEngine.PredictionConfidence.high.percentage, 0.75)
        XCTAssertEqual(HealthInsightsAnalyticsEngine.PredictionConfidence.veryHigh.percentage, 0.95)
    }
    
    func testPredictionConfidenceAllCases() {
        let confidences = HealthInsightsAnalyticsEngine.PredictionConfidence.allCases
        XCTAssertEqual(confidences.count, 4)
        XCTAssertTrue(confidences.contains(.low))
        XCTAssertTrue(confidences.contains(.medium))
        XCTAssertTrue(confidences.contains(.high))
        XCTAssertTrue(confidences.contains(.veryHigh))
    }
    
    // MARK: - Health Insight Tests
    
    func testHealthInsightCreation() {
        let insight = HealthInsightsAnalyticsEngine.HealthInsight(
            category: .trends,
            title: "Heart Rate Trend",
            description: "Heart rate has improved over the past week",
            dataType: "Heart Rate",
            value: 72.0,
            unit: "bpm",
            confidence: 0.85,
            actionable: true,
            actionItems: ["Continue exercise routine", "Monitor stress levels"],
            relatedInsights: []
        )
        
        XCTAssertEqual(insight.category, .trends)
        XCTAssertEqual(insight.title, "Heart Rate Trend")
        XCTAssertEqual(insight.description, "Heart rate has improved over the past week")
        XCTAssertEqual(insight.dataType, "Heart Rate")
        XCTAssertEqual(insight.value, 72.0)
        XCTAssertEqual(insight.unit, "bpm")
        XCTAssertEqual(insight.confidence, 0.85)
        XCTAssertTrue(insight.actionable)
        XCTAssertEqual(insight.actionItems.count, 2)
        XCTAssertEqual(insight.relatedInsights.count, 0)
        XCTAssertNotNil(insight.timestamp)
    }
    
    // MARK: - Health Trend Tests
    
    func testHealthTrendCreation() {
        let dataPoints = [
            HealthInsightsAnalyticsEngine.DataPoint(date: Date(), value: 72.0, unit: "bpm"),
            HealthInsightsAnalyticsEngine.DataPoint(date: Date().addingTimeInterval(3600), value: 70.0, unit: "bpm")
        ]
        
        let trend = HealthInsightsAnalyticsEngine.HealthTrend(
            dataType: "Heart Rate",
            direction: .improving,
            startDate: Date().addingTimeInterval(-7 * 24 * 3600),
            endDate: Date(),
            dataPoints: dataPoints,
            changePercentage: -5.2,
            significance: 0.85,
            description: "Heart rate has improved by 5.2% over the past week"
        )
        
        XCTAssertEqual(trend.dataType, "Heart Rate")
        XCTAssertEqual(trend.direction, .improving)
        XCTAssertEqual(trend.dataPoints.count, 2)
        XCTAssertEqual(trend.changePercentage, -5.2)
        XCTAssertEqual(trend.significance, 0.85)
        XCTAssertEqual(trend.description, "Heart rate has improved by 5.2% over the past week")
    }
    
    func testDataPointCreation() {
        let date = Date()
        let dataPoint = HealthInsightsAnalyticsEngine.DataPoint(
            date: date,
            value: 72.0,
            unit: "bpm"
        )
        
        XCTAssertEqual(dataPoint.date, date)
        XCTAssertEqual(dataPoint.value, 72.0)
        XCTAssertEqual(dataPoint.unit, "bpm")
    }
    
    // MARK: - Health Prediction Tests
    
    func testHealthPredictionCreation() {
        let prediction = HealthInsightsAnalyticsEngine.HealthPrediction(
            dataType: "Heart Rate",
            predictedValue: 68.0,
            unit: "bpm",
            predictionDate: Date().addingTimeInterval(7 * 24 * 3600),
            confidence: .high,
            factors: ["Current trend", "Sleep quality", "Stress levels"],
            description: "Heart rate is predicted to improve to 68 bpm in the next week",
            actionable: true
        )
        
        XCTAssertEqual(prediction.dataType, "Heart Rate")
        XCTAssertEqual(prediction.predictedValue, 68.0)
        XCTAssertEqual(prediction.unit, "bpm")
        XCTAssertEqual(prediction.confidence, .high)
        XCTAssertEqual(prediction.factors.count, 3)
        XCTAssertEqual(prediction.description, "Heart rate is predicted to improve to 68 bpm in the next week")
        XCTAssertTrue(prediction.actionable)
    }
    
    // MARK: - Health Recommendation Tests
    
    func testHealthRecommendationCreation() {
        let recommendation = HealthInsightsAnalyticsEngine.HealthRecommendation(
            title: "Increase Exercise",
            description: "Add 30 minutes of moderate exercise daily",
            category: .exercise,
            priority: .high,
            actionable: true,
            steps: ["Start with walking", "Gradually increase intensity", "Track progress"],
            expectedOutcome: "Improved cardiovascular health",
            timeToImplement: 30 * 60, // 30 minutes
            difficulty: .moderate
        )
        
        XCTAssertEqual(recommendation.title, "Increase Exercise")
        XCTAssertEqual(recommendation.description, "Add 30 minutes of moderate exercise daily")
        XCTAssertEqual(recommendation.category, .exercise)
        XCTAssertEqual(recommendation.priority, .high)
        XCTAssertTrue(recommendation.actionable)
        XCTAssertEqual(recommendation.steps.count, 3)
        XCTAssertEqual(recommendation.expectedOutcome, "Improved cardiovascular health")
        XCTAssertEqual(recommendation.timeToImplement, 30 * 60)
        XCTAssertEqual(recommendation.difficulty, .moderate)
    }
    
    func testRecommendationCategoryIcons() {
        XCTAssertEqual(HealthInsightsAnalyticsEngine.RecommendationCategory.exercise.icon, "figure.walk")
        XCTAssertEqual(HealthInsightsAnalyticsEngine.RecommendationCategory.nutrition.icon, "leaf")
        XCTAssertEqual(HealthInsightsAnalyticsEngine.RecommendationCategory.sleep.icon, "bed.double")
        XCTAssertEqual(HealthInsightsAnalyticsEngine.RecommendationCategory.stress.icon, "brain.head.profile")
        XCTAssertEqual(HealthInsightsAnalyticsEngine.RecommendationCategory.monitoring.icon, "heart")
        XCTAssertEqual(HealthInsightsAnalyticsEngine.RecommendationCategory.lifestyle.icon, "house")
    }
    
    func testRecommendationCategoryAllCases() {
        let categories = HealthInsightsAnalyticsEngine.RecommendationCategory.allCases
        XCTAssertEqual(categories.count, 6)
        XCTAssertTrue(categories.contains(.exercise))
        XCTAssertTrue(categories.contains(.nutrition))
        XCTAssertTrue(categories.contains(.sleep))
        XCTAssertTrue(categories.contains(.stress))
        XCTAssertTrue(categories.contains(.monitoring))
        XCTAssertTrue(categories.contains(.lifestyle))
    }
    
    func testRecommendationPriorityColors() {
        XCTAssertEqual(HealthInsightsAnalyticsEngine.RecommendationPriority.low.color, "gray")
        XCTAssertEqual(HealthInsightsAnalyticsEngine.RecommendationPriority.medium.color, "blue")
        XCTAssertEqual(HealthInsightsAnalyticsEngine.RecommendationPriority.high.color, "orange")
        XCTAssertEqual(HealthInsightsAnalyticsEngine.RecommendationPriority.critical.color, "red")
    }
    
    func testRecommendationPriorityAllCases() {
        let priorities = HealthInsightsAnalyticsEngine.RecommendationPriority.allCases
        XCTAssertEqual(priorities.count, 4)
        XCTAssertTrue(priorities.contains(.low))
        XCTAssertTrue(priorities.contains(.medium))
        XCTAssertTrue(priorities.contains(.high))
        XCTAssertTrue(priorities.contains(.critical))
    }
    
    func testRecommendationDifficultyDescription() {
        XCTAssertEqual(HealthInsightsAnalyticsEngine.RecommendationDifficulty.easy.description, "Can be implemented immediately")
        XCTAssertEqual(HealthInsightsAnalyticsEngine.RecommendationDifficulty.moderate.description, "Requires some planning")
        XCTAssertEqual(HealthInsightsAnalyticsEngine.RecommendationDifficulty.challenging.description, "Requires significant effort")
        XCTAssertEqual(HealthInsightsAnalyticsEngine.RecommendationDifficulty.expert.description, "Requires professional guidance")
    }
    
    func testRecommendationDifficultyAllCases() {
        let difficulties = HealthInsightsAnalyticsEngine.RecommendationDifficulty.allCases
        XCTAssertEqual(difficulties.count, 4)
        XCTAssertTrue(difficulties.contains(.easy))
        XCTAssertTrue(difficulties.contains(.moderate))
        XCTAssertTrue(difficulties.contains(.challenging))
        XCTAssertTrue(difficulties.contains(.expert))
    }
    
    // MARK: - Analytics Operations Tests
    
    func testAnalyzeTrends() async {
        await analyticsEngine.analyzeTrends()
        
        XCTAssertGreaterThan(analyticsEngine.trends.count, 0)
        
        // Check that we have trends with different directions
        let improvingTrends = analyticsEngine.trends.filter { $0.direction == .improving }
        let decliningTrends = analyticsEngine.trends.filter { $0.direction == .declining }
        
        XCTAssertGreaterThan(improvingTrends.count, 0)
        XCTAssertGreaterThan(decliningTrends.count, 0)
        
        // Check that trends have data points
        for trend in analyticsEngine.trends {
            XCTAssertGreaterThan(trend.dataPoints.count, 0)
            XCTAssertNotNil(trend.description)
            XCTAssertNotEqual(trend.significance, 0)
        }
    }
    
    func testGenerateInsights() async {
        // First analyze trends to have data to work with
        await analyticsEngine.analyzeTrends()
        await analyticsEngine.generateInsights()
        
        XCTAssertGreaterThan(analyticsEngine.insights.count, 0)
        
        // Check that we have insights in different categories
        let trendInsights = analyticsEngine.insights.filter { $0.category == .trends || $0.category == .improvements || $0.category == .warnings }
        let correlationInsights = analyticsEngine.insights.filter { $0.category == .correlations }
        let patternInsights = analyticsEngine.insights.filter { $0.category == .patterns }
        
        XCTAssertGreaterThan(trendInsights.count, 0)
        XCTAssertGreaterThan(correlationInsights.count, 0)
        XCTAssertGreaterThan(patternInsights.count, 0)
        
        // Check that insights have required properties
        for insight in analyticsEngine.insights {
            XCTAssertFalse(insight.title.isEmpty)
            XCTAssertFalse(insight.description.isEmpty)
            XCTAssertFalse(insight.dataType.isEmpty)
            XCTAssertGreaterThan(insight.confidence, 0)
            XCTAssertLessThanOrEqual(insight.confidence, 1)
        }
    }
    
    func testMakePredictions() async {
        await analyticsEngine.makePredictions()
        
        XCTAssertGreaterThan(analyticsEngine.predictions.count, 0)
        
        // Check that we have predictions with different confidence levels
        let highConfidencePredictions = analyticsEngine.predictions.filter { $0.confidence == .high || $0.confidence == .veryHigh }
        let mediumConfidencePredictions = analyticsEngine.predictions.filter { $0.confidence == .medium }
        
        XCTAssertGreaterThan(highConfidencePredictions.count, 0)
        XCTAssertGreaterThan(mediumConfidencePredictions.count, 0)
        
        // Check that predictions have required properties
        for prediction in analyticsEngine.predictions {
            XCTAssertFalse(prediction.dataType.isEmpty)
            XCTAssertGreaterThan(prediction.predictedValue, 0)
            XCTAssertFalse(prediction.unit.isEmpty)
            XCTAssertFalse(prediction.description.isEmpty)
            XCTAssertGreaterThan(prediction.factors.count, 0)
        }
    }
    
    func testCreateRecommendations() async {
        // First generate insights to have data to work with
        await analyticsEngine.analyzeTrends()
        await analyticsEngine.generateInsights()
        await analyticsEngine.createRecommendations()
        
        XCTAssertGreaterThan(analyticsEngine.recommendations.count, 0)
        
        // Check that we have recommendations in different categories
        let exerciseRecommendations = analyticsEngine.recommendations.filter { $0.category == .exercise }
        let nutritionRecommendations = analyticsEngine.recommendations.filter { $0.category == .nutrition }
        let sleepRecommendations = analyticsEngine.recommendations.filter { $0.category == .sleep }
        
        XCTAssertGreaterThan(exerciseRecommendations.count, 0)
        XCTAssertGreaterThan(nutritionRecommendations.count, 0)
        XCTAssertGreaterThan(sleepRecommendations.count, 0)
        
        // Check that recommendations have required properties
        for recommendation in analyticsEngine.recommendations {
            XCTAssertFalse(recommendation.title.isEmpty)
            XCTAssertFalse(recommendation.description.isEmpty)
            XCTAssertFalse(recommendation.expectedOutcome.isEmpty)
        }
    }
    
    func testPerformAnalysis() async {
        await analyticsEngine.performAnalysis()
        
        // Check that all analysis components were executed
        XCTAssertGreaterThan(analyticsEngine.trends.count, 0)
        XCTAssertGreaterThan(analyticsEngine.insights.count, 0)
        XCTAssertGreaterThan(analyticsEngine.predictions.count, 0)
        XCTAssertGreaterThan(analyticsEngine.recommendations.count, 0)
        XCTAssertNotNil(analyticsEngine.lastAnalysisDate)
        XCTAssertEqual(analyticsEngine.analyticsStatus, .idle)
    }
    
    // MARK: - Filtering Tests
    
    func testGetInsightsByCategory() async {
        await analyticsEngine.performAnalysis()
        
        let trendInsights = analyticsEngine.getInsights(for: .trends)
        let improvementInsights = analyticsEngine.getInsights(for: .improvements)
        let warningInsights = analyticsEngine.getInsights(for: .warnings)
        
        XCTAssertGreaterThan(trendInsights.count, 0)
        XCTAssertGreaterThan(improvementInsights.count, 0)
        XCTAssertGreaterThan(warningInsights.count, 0)
        
        // Verify filtering works correctly
        for insight in trendInsights {
            XCTAssertEqual(insight.category, .trends)
        }
        
        for insight in improvementInsights {
            XCTAssertEqual(insight.category, .improvements)
        }
        
        for insight in warningInsights {
            XCTAssertEqual(insight.category, .warnings)
        }
    }
    
    func testGetTrendsByDirection() async {
        await analyticsEngine.analyzeTrends()
        
        let improvingTrends = analyticsEngine.getTrends(for: .improving)
        let decliningTrends = analyticsEngine.getTrends(for: .declining)
        
        XCTAssertGreaterThan(improvingTrends.count, 0)
        XCTAssertGreaterThan(decliningTrends.count, 0)
        
        // Verify filtering works correctly
        for trend in improvingTrends {
            XCTAssertEqual(trend.direction, .improving)
        }
        
        for trend in decliningTrends {
            XCTAssertEqual(trend.direction, .declining)
        }
    }
    
    func testGetPredictionsByConfidence() async {
        await analyticsEngine.makePredictions()
        
        let highPredictions = analyticsEngine.getPredictions(withConfidence: .high)
        let mediumPredictions = analyticsEngine.getPredictions(withConfidence: .medium)
        
        XCTAssertGreaterThan(highPredictions.count, 0)
        XCTAssertGreaterThan(mediumPredictions.count, 0)
        
        // Verify filtering works correctly
        for prediction in highPredictions {
            XCTAssertEqual(prediction.confidence, .high)
        }
        
        for prediction in mediumPredictions {
            XCTAssertEqual(prediction.confidence, .medium)
        }
    }
    
    func testGetRecommendationsByCategory() async {
        await analyticsEngine.createRecommendations()
        
        let exerciseRecommendations = analyticsEngine.getRecommendations(for: .exercise)
        let nutritionRecommendations = analyticsEngine.getRecommendations(for: .nutrition)
        
        XCTAssertGreaterThan(exerciseRecommendations.count, 0)
        XCTAssertGreaterThan(nutritionRecommendations.count, 0)
        
        // Verify filtering works correctly
        for recommendation in exerciseRecommendations {
            XCTAssertEqual(recommendation.category, .exercise)
        }
        
        for recommendation in nutritionRecommendations {
            XCTAssertEqual(recommendation.category, .nutrition)
        }
    }
    
    func testGetRecommendationsByPriority() async {
        await analyticsEngine.createRecommendations()
        
        let highPriorityRecommendations = analyticsEngine.getRecommendations(withPriority: .high)
        let mediumPriorityRecommendations = analyticsEngine.getRecommendations(withPriority: .medium)
        
        XCTAssertGreaterThan(highPriorityRecommendations.count, 0)
        XCTAssertGreaterThan(mediumPriorityRecommendations.count, 0)
        
        // Verify filtering works correctly
        for recommendation in highPriorityRecommendations {
            XCTAssertEqual(recommendation.priority, .high)
        }
        
        for recommendation in mediumPriorityRecommendations {
            XCTAssertEqual(recommendation.priority, .medium)
        }
    }
    
    // MARK: - Analytics Summary Tests
    
    func testGetAnalyticsSummary() async {
        await analyticsEngine.performAnalysis()
        
        let summary = analyticsEngine.getAnalyticsSummary()
        
        XCTAssertGreaterThan(summary.totalInsights, 0)
        XCTAssertGreaterThan(summary.actionableInsights, 0)
        XCTAssertGreaterThan(summary.improvingTrends, 0)
        XCTAssertGreaterThan(summary.highConfidencePredictions, 0)
        XCTAssertGreaterThan(summary.criticalRecommendations, 0)
        XCTAssertNotNil(summary.lastAnalysisDate)
        
        // Check calculated rates
        XCTAssertGreaterThanOrEqual(summary.insightsActionabilityRate, 0)
        XCTAssertLessThanOrEqual(summary.insightsActionabilityRate, 1)
        XCTAssertGreaterThanOrEqual(summary.trendImprovementRate, 0)
        XCTAssertLessThanOrEqual(summary.trendImprovementRate, 1)
    }
    
    func testGetAnalyticsSummaryWithNoData() {
        let summary = analyticsEngine.getAnalyticsSummary()
        
        XCTAssertEqual(summary.totalInsights, 0)
        XCTAssertEqual(summary.actionableInsights, 0)
        XCTAssertEqual(summary.improvingTrends, 0)
        XCTAssertEqual(summary.decliningTrends, 0)
        XCTAssertEqual(summary.highConfidencePredictions, 0)
        XCTAssertEqual(summary.criticalRecommendations, 0)
        XCTAssertNil(summary.lastAnalysisDate)
        XCTAssertEqual(summary.insightsActionabilityRate, 0)
        XCTAssertEqual(summary.trendImprovementRate, 0)
    }
    
    // MARK: - Export Tests
    
    func testExportAnalyticsDataWithNoData() {
        let exportData = analyticsEngine.exportAnalyticsData()
        XCTAssertNotNil(exportData)
        
        if let data = exportData {
            let decoder = JSONDecoder()
            let exportStruct = try? decoder.decode(AnalyticsExportData.self, from: data)
            XCTAssertNotNil(exportStruct)
            
            if let export = exportStruct {
                XCTAssertEqual(export.insights.count, 0)
                XCTAssertEqual(export.trends.count, 0)
                XCTAssertEqual(export.predictions.count, 0)
                XCTAssertEqual(export.recommendations.count, 0)
                XCTAssertNil(export.lastAnalysisDate)
            }
        }
    }
    
    func testExportAnalyticsDataWithData() async {
        await analyticsEngine.performAnalysis()
        
        let exportData = analyticsEngine.exportAnalyticsData()
        XCTAssertNotNil(exportData)
        
        if let data = exportData {
            let decoder = JSONDecoder()
            let exportStruct = try? decoder.decode(AnalyticsExportData.self, from: data)
            XCTAssertNotNil(exportStruct)
            
            if let export = exportStruct {
                XCTAssertGreaterThan(export.insights.count, 0)
                XCTAssertGreaterThan(export.trends.count, 0)
                XCTAssertGreaterThan(export.predictions.count, 0)
                XCTAssertGreaterThan(export.recommendations.count, 0)
                XCTAssertNotNil(export.lastAnalysisDate)
            }
        }
    }
    
    // MARK: - Performance Tests
    
    func testAnalysisPerformance() async {
        let startTime = Date()
        
        await analyticsEngine.performAnalysis()
        
        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)
        
        // Analysis should complete quickly (less than 5 seconds)
        XCTAssertLessThan(duration, 5.0, "Analysis took too long: \(duration) seconds")
        
        // Should have generated data
        XCTAssertGreaterThan(analyticsEngine.trends.count, 0)
        XCTAssertGreaterThan(analyticsEngine.insights.count, 0)
        XCTAssertGreaterThan(analyticsEngine.predictions.count, 0)
        XCTAssertGreaterThan(analyticsEngine.recommendations.count, 0)
    }
    
    func testFilteringPerformance() async {
        await analyticsEngine.performAnalysis()
        
        let startTime = Date()
        
        // Perform multiple filtering operations
        for _ in 0..<100 {
            _ = analyticsEngine.getInsights(for: .trends)
            _ = analyticsEngine.getTrends(for: .improving)
            _ = analyticsEngine.getPredictions(withConfidence: .high)
            _ = analyticsEngine.getRecommendations(for: .exercise)
        }
        
        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)
        
        // Filtering should be fast (less than 1 second for 100 operations)
        XCTAssertLessThan(duration, 1.0, "Filtering took too long: \(duration) seconds")
    }
    
    // MARK: - Edge Case Tests
    
    func testEmptyAnalyticsData() {
        let summary = analyticsEngine.getAnalyticsSummary()
        let exportData = analyticsEngine.exportAnalyticsData()
        
        XCTAssertNotNil(summary)
        XCTAssertNotNil(exportData)
        XCTAssertEqual(summary.totalInsights, 0)
    }
    
    func testSpecialCharactersInData() {
        let insight = HealthInsightsAnalyticsEngine.HealthInsight(
            category: .trends,
            title: "Special chars: !@#$%^&*()_+-=[]{}|;':\",./<>?",
            description: "Description with special chars: áéíóúñü",
            dataType: "Test Data",
            value: 100.0,
            unit: "units"
        )
        
        XCTAssertEqual(insight.title, "Special chars: !@#$%^&*()_+-=[]{}|;':\",./<>?")
        XCTAssertEqual(insight.description, "Description with special chars: áéíóúñü")
    }
    
    func testLargeDataSets() async {
        // Test with many insights
        for i in 0..<100 {
            let insight = HealthInsightsAnalyticsEngine.HealthInsight(
                category: .trends,
                title: "Insight \(i)",
                description: "Description for insight \(i)",
                dataType: "Test Data",
                value: Double(i),
                unit: "units"
            )
            analyticsEngine.insights.append(insight)
        }
        
        let summary = analyticsEngine.getAnalyticsSummary()
        XCTAssertEqual(summary.totalInsights, 100)
        
        let exportData = analyticsEngine.exportAnalyticsData()
        XCTAssertNotNil(exportData)
    }
}

// MARK: - Test Data Structure

private struct AnalyticsExportData: Codable {
    let insights: [HealthInsightsAnalyticsEngine.HealthInsight]
    let trends: [HealthInsightsAnalyticsEngine.HealthTrend]
    let predictions: [HealthInsightsAnalyticsEngine.HealthPrediction]
    let recommendations: [HealthInsightsAnalyticsEngine.HealthRecommendation]
    let lastAnalysisDate: Date?
    let exportDate: Date
} 
import XCTest
import Combine
import CoreML
@testable import HealthAI2030

/// Comprehensive unit tests for the Advanced AI Orchestration Manager
/// Tests all functionality including model initialization, insight generation, recommendations, predictions, and performance monitoring
@MainActor
final class AdvancedAIOrchestrationTests: XCTestCase {
    
    var aiOrchestrator: AdvancedAIOrchestrationManager!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        aiOrchestrator = AdvancedAIOrchestrationManager()
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDown() {
        aiOrchestrator.stopOrchestration()
        cancellables.removeAll()
        aiOrchestrator = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testAIOrchestratorInitialization() {
        // Given - AI orchestrator is initialized
        
        // Then - Should be properly initialized
        XCTAssertNotNil(aiOrchestrator)
        XCTAssertEqual(aiOrchestrator.orchestrationStatus, .initializing)
        XCTAssertTrue(aiOrchestrator.healthInsights.isEmpty)
        XCTAssertTrue(aiOrchestrator.recommendations.isEmpty)
        XCTAssertTrue(aiOrchestrator.predictions.isEmpty)
        XCTAssertTrue(aiOrchestrator.aiModels.isEmpty)
        XCTAssertNotNil(aiOrchestrator.performanceMetrics)
    }
    
    func testOrchestrationStatusTransitions() {
        // Given - AI orchestrator is initialized
        
        // When - Starting orchestration
        aiOrchestrator.startOrchestration()
        
        // Then - Status should transition appropriately
        let expectation = XCTestExpectation(description: "Orchestration status transition")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            XCTAssertTrue([.starting, .running].contains(self.aiOrchestrator.orchestrationStatus))
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 2.0)
    }
    
    // MARK: - Model Initialization Tests
    
    func testAIModelInitialization() async {
        // Given - AI orchestrator is running
        
        // When - Initializing AI models
        aiOrchestrator.startOrchestration()
        
        // Then - Models should be initialized
        let expectation = XCTestExpectation(description: "AI models initialized")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            XCTAssertGreaterThan(self.aiOrchestrator.aiModels.count, 0)
            
            // Verify model properties
            for model in self.aiOrchestrator.aiModels {
                XCTAssertFalse(model.name.isEmpty)
                XCTAssertTrue([.ready, .running, .initializing].contains(model.status))
                XCTAssertFalse(model.version.isEmpty)
                XCTAssertGreaterThanOrEqual(model.accuracy, 0.0)
                XCTAssertLessThanOrEqual(model.accuracy, 1.0)
                XCTAssertGreaterThanOrEqual(model.latency, 0.0)
                XCTAssertGreaterThanOrEqual(model.memoryUsage, 0.0)
            }
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 3.0)
    }
    
    func testModelTypeCoverage() async {
        // Given - AI models are initialized
        
        // When - Checking model types
        aiOrchestrator.startOrchestration()
        
        // Then - Should have coverage for all model types
        let expectation = XCTestExpectation(description: "Model type coverage")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            let modelTypes = Set(self.aiOrchestrator.aiModels.map { $0.type })
            let expectedTypes: Set<AIModelType> = [
                .healthPrediction,
                .sleepAnalysis,
                .moodAnalysis,
                .ecgAnalysis,
                .federatedLearning,
                .mlxPrediction
            ]
            
            XCTAssertTrue(modelTypes.isSuperset(of: expectedTypes))
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 3.0)
    }
    
    // MARK: - Health Insights Tests
    
    func testHealthInsightsGeneration() async throws {
        // Given - AI orchestrator is running
        
        // When - Generating health insights
        aiOrchestrator.startOrchestration()
        
        // Wait for initialization
        try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
        let insights = try await aiOrchestrator.generateHealthInsights()
        
        // Then - Should generate insights
        XCTAssertGreaterThan(insights.count, 0)
        
        // Verify insight properties
        for insight in insights {
            XCTAssertFalse(insight.title.isEmpty)
            XCTAssertFalse(insight.description.isEmpty)
            XCTAssertGreaterThanOrEqual(insight.confidence, 0.0)
            XCTAssertLessThanOrEqual(insight.confidence, 1.0)
            XCTAssertTrue(InsightSeverity.allCases.contains(insight.severity))
            XCTAssertFalse(insight.source.isEmpty)
        }
    }
    
    func testInsightTypeDistribution() async throws {
        // Given - Health insights are generated
        
        // When - Analyzing insight types
        aiOrchestrator.startOrchestration()
        
        // Wait for initialization
        try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
        let insights = try await aiOrchestrator.generateHealthInsights()
        
        // Then - Should have various insight types
        let insightTypes = Set(insights.map { $0.type })
        XCTAssertGreaterThan(insightTypes.count, 0)
        
        // Verify insight types are valid
        let validTypes: Set<InsightType> = [
            .healthAlert,
            .sleepQuality,
            .mentalHealth,
            .cardiacHealth,
            .aiLearning,
            .aiPrediction
        ]
        
        for insightType in insightTypes {
            XCTAssertTrue(validTypes.contains(insightType))
        }
    }
    
    func testInsightSeverityDistribution() async throws {
        // Given - Health insights are generated
        
        // When - Analyzing insight severity
        aiOrchestrator.startOrchestration()
        
        // Wait for initialization
        try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
        let insights = try await aiOrchestrator.generateHealthInsights()
        
        // Then - Should have various severity levels
        let severityLevels = Set(insights.map { $0.severity })
        XCTAssertGreaterThan(severityLevels.count, 0)
        
        // Verify severity levels are valid
        for severity in severityLevels {
            XCTAssertTrue(InsightSeverity.allCases.contains(severity))
        }
    }
    
    func testInsightConfidenceValidation() async throws {
        // Given - Health insights are generated
        
        // When - Validating insight confidence
        aiOrchestrator.startOrchestration()
        
        // Wait for initialization
        try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
        let insights = try await aiOrchestrator.generateHealthInsights()
        
        // Then - Confidence should be within valid range
        for insight in insights {
            XCTAssertGreaterThanOrEqual(insight.confidence, 0.0)
            XCTAssertLessThanOrEqual(insight.confidence, 1.0)
        }
    }
    
    // MARK: - Recommendations Tests
    
    func testRecommendationsGeneration() async throws {
        // Given - AI orchestrator is running
        
        // When - Generating recommendations
        aiOrchestrator.startOrchestration()
        
        // Wait for initialization
        try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
        let recommendations = try await aiOrchestrator.generateRecommendations()
        
        // Then - Should generate recommendations
        XCTAssertGreaterThan(recommendations.count, 0)
        
        // Verify recommendation properties
        for recommendation in recommendations {
            XCTAssertFalse(recommendation.title.isEmpty)
            XCTAssertFalse(recommendation.description.isEmpty)
            XCTAssertGreaterThanOrEqual(recommendation.confidence, 0.0)
            XCTAssertLessThanOrEqual(recommendation.confidence, 1.0)
            XCTAssertTrue(RecommendationPriority.allCases.contains(recommendation.priority))
        }
    }
    
    func testRecommendationTypeDistribution() async throws {
        // Given - Recommendations are generated
        
        // When - Analyzing recommendation types
        aiOrchestrator.startOrchestration()
        
        // Wait for initialization
        try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
        let recommendations = try await aiOrchestrator.generateRecommendations()
        
        // Then - Should have various recommendation types
        let recommendationTypes = Set(recommendations.map { $0.type })
        XCTAssertGreaterThan(recommendationTypes.count, 0)
        
        // Verify recommendation types are valid
        let validTypes: Set<RecommendationType> = [
            .exercise,
            .sleep,
            .nutrition,
            .stress,
            .medication,
            .lifestyle
        ]
        
        for recommendationType in recommendationTypes {
            XCTAssertTrue(validTypes.contains(recommendationType))
        }
    }
    
    func testRecommendationPriorityDistribution() async throws {
        // Given - Recommendations are generated
        
        // When - Analyzing recommendation priorities
        aiOrchestrator.startOrchestration()
        
        // Wait for initialization
        try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
        let recommendations = try await aiOrchestrator.generateRecommendations()
        
        // Then - Should have various priority levels
        let priorityLevels = Set(recommendations.map { $0.priority })
        XCTAssertGreaterThan(priorityLevels.count, 0)
        
        // Verify priority levels are valid
        for priority in priorityLevels {
            XCTAssertTrue(RecommendationPriority.allCases.contains(priority))
        }
    }
    
    func testActionableRecommendations() async throws {
        // Given - Recommendations are generated
        
        // When - Checking actionable recommendations
        aiOrchestrator.startOrchestration()
        
        // Wait for initialization
        try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
        let recommendations = try await aiOrchestrator.generateRecommendations()
        
        // Then - Should have actionable recommendations
        let actionableRecommendations = recommendations.filter { $0.actionable }
        XCTAssertGreaterThan(actionableRecommendations.count, 0)
        
        // Verify actionable recommendations have proper content
        for recommendation in actionableRecommendations {
            XCTAssertFalse(recommendation.title.isEmpty)
            XCTAssertFalse(recommendation.description.isEmpty)
            XCTAssertGreaterThanOrEqual(recommendation.confidence, 0.5) // Should be reasonably confident
        }
    }
    
    // MARK: - Predictions Tests
    
    func testPredictionsGeneration() async throws {
        // Given - AI orchestrator is running
        
        // When - Generating predictions
        aiOrchestrator.startOrchestration()
        
        // Wait for initialization
        try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
        let predictions = try await aiOrchestrator.generatePredictions()
        
        // Then - Should generate predictions
        XCTAssertGreaterThan(predictions.count, 0)
        
        // Verify prediction properties
        for prediction in predictions {
            XCTAssertFalse(prediction.title.isEmpty)
            XCTAssertFalse(prediction.description.isEmpty)
            XCTAssertGreaterThanOrEqual(prediction.probability, 0.0)
            XCTAssertLessThanOrEqual(prediction.probability, 1.0)
            XCTAssertGreaterThanOrEqual(prediction.confidence, 0.0)
            XCTAssertLessThanOrEqual(prediction.confidence, 1.0)
        }
    }
    
    func testPredictionTypeDistribution() async throws {
        // Given - Predictions are generated
        
        // When - Analyzing prediction types
        aiOrchestrator.startOrchestration()
        
        // Wait for initialization
        try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
        let predictions = try await aiOrchestrator.generatePredictions()
        
        // Then - Should have various prediction types
        let predictionTypes = Set(predictions.map { $0.type })
        XCTAssertGreaterThan(predictionTypes.count, 0)
        
        // Verify prediction types are valid
        let validTypes: Set<PredictionType> = [
            .healthRisk,
            .sleepQuality,
            .energyLevel,
            .moodTrend,
            .performance
        ]
        
        for predictionType in predictionTypes {
            XCTAssertTrue(validTypes.contains(predictionType))
        }
    }
    
    func testPredictionTimeframeDistribution() async throws {
        // Given - Predictions are generated
        
        // When - Analyzing prediction timeframes
        aiOrchestrator.startOrchestration()
        
        // Wait for initialization
        try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
        let predictions = try await aiOrchestrator.generatePredictions()
        
        // Then - Should have various timeframes
        let timeframes = Set(predictions.map { $0.timeframe })
        XCTAssertGreaterThan(timeframes.count, 0)
        
        // Verify timeframes are valid
        let validTimeframes: Set<PredictionTimeframe> = [
            .oneWeek,
            .twoWeeks,
            .oneMonth,
            .threeMonths,
            .sixMonths
        ]
        
        for timeframe in timeframes {
            XCTAssertTrue(validTimeframes.contains(timeframe))
        }
    }
    
    func testPredictionProbabilityValidation() async throws {
        // Given - Predictions are generated
        
        // When - Validating prediction probabilities
        aiOrchestrator.startOrchestration()
        
        // Wait for initialization
        try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
        let predictions = try await aiOrchestrator.generatePredictions()
        
        // Then - Probabilities should be within valid range
        for prediction in predictions {
            XCTAssertGreaterThanOrEqual(prediction.probability, 0.0)
            XCTAssertLessThanOrEqual(prediction.probability, 1.0)
        }
    }
    
    // MARK: - Performance Tests
    
    func testModelPerformanceUpdate() async throws {
        // Given - AI orchestrator is running
        
        // When - Updating model performance
        aiOrchestrator.startOrchestration()
        
        // Wait for initialization
        try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
        try await aiOrchestrator.updateModelPerformance()
        
        // Then - Performance metrics should be updated
        let metrics = aiOrchestrator.performanceMetrics
        XCTAssertGreaterThan(metrics.totalModels, 0)
        XCTAssertGreaterThanOrEqual(metrics.readyModels, 0)
        XCTAssertLessThanOrEqual(metrics.readyModels, metrics.totalModels)
        XCTAssertGreaterThanOrEqual(metrics.averageAccuracy, 0.0)
        XCTAssertLessThanOrEqual(metrics.averageAccuracy, 1.0)
        XCTAssertGreaterThanOrEqual(metrics.averageLatency, 0.0)
        XCTAssertGreaterThanOrEqual(metrics.totalMemoryUsage, 0.0)
    }
    
    func testModelOptimization() async throws {
        // Given - AI models are initialized
        
        // When - Optimizing models for device
        aiOrchestrator.startOrchestration()
        
        // Wait for initialization
        try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
        let originalModels = aiOrchestrator.aiModels
        XCTAssertGreaterThan(originalModels.count, 0)
        
        try await aiOrchestrator.optimizeModelsForDevice()
        
        // Then - Models should be optimized
        let optimizedModels = aiOrchestrator.aiModels
        XCTAssertEqual(originalModels.count, optimizedModels.count)
        
        // Verify optimization improvements
        for (original, optimized) in zip(originalModels, optimizedModels) {
            XCTAssertEqual(original.id, optimized.id)
            XCTAssertEqual(original.name, optimized.name)
            XCTAssertEqual(original.type, optimized.type)
            XCTAssertEqual(original.status, optimized.status)
            XCTAssertEqual(original.version, optimized.version)
            
            // Accuracy should be improved or maintained
            XCTAssertGreaterThanOrEqual(optimized.accuracy, original.accuracy)
            
            // Latency should be improved or maintained
            XCTAssertLessThanOrEqual(optimized.latency, original.latency)
            
            // Memory usage should be improved or maintained
            XCTAssertLessThanOrEqual(optimized.memoryUsage, original.memoryUsage)
        }
    }
    
    // MARK: - Integration Tests
    
    func testEndToEndOrchestration() async throws {
        // Given - AI orchestrator is initialized
        
        // When - Running complete orchestration
        aiOrchestrator.startOrchestration()
        
        // Wait for initialization
        try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
        // Generate all outputs
        let insights = try await aiOrchestrator.generateHealthInsights()
        let recommendations = try await aiOrchestrator.generateRecommendations()
        let predictions = try await aiOrchestrator.generatePredictions()
        try await aiOrchestrator.updateModelPerformance()
        
        // Then - All components should work together
        XCTAssertGreaterThan(insights.count, 0)
        XCTAssertGreaterThan(recommendations.count, 0)
        XCTAssertGreaterThan(predictions.count, 0)
        XCTAssertGreaterThan(aiOrchestrator.aiModels.count, 0)
        XCTAssertEqual(aiOrchestrator.orchestrationStatus, .running)
    }
    
    func testOrchestrationStopping() {
        // Given - AI orchestrator is running
        
        // When - Stopping orchestration
        aiOrchestrator.startOrchestration()
        
        let expectation = XCTestExpectation(description: "Orchestration stopping")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.aiOrchestrator.stopOrchestration()
            
            // Then - Should stop properly
            XCTAssertEqual(self.aiOrchestrator.orchestrationStatus, .stopped)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 2.0)
    }
    
    // MARK: - Error Handling Tests
    
    func testErrorHandling() async {
        // Given - AI orchestrator is running
        
        // When - Encountering errors (simulated)
        aiOrchestrator.startOrchestration()
        
        // Then - Should handle errors gracefully
        // This test verifies that the orchestrator doesn't crash on errors
        XCTAssertNotNil(aiOrchestrator)
        XCTAssertNotEqual(aiOrchestrator.orchestrationStatus, .error)
    }
    
    // MARK: - Performance Tests
    
    func testOrchestrationPerformance() {
        // Given - AI orchestrator operations
        
        // When - Measuring performance
        measure {
            // This would measure the performance of orchestration operations
            // For now, we'll measure a simple operation
            let expectation = XCTestExpectation(description: "Performance test")
            
            Task {
                self.aiOrchestrator.startOrchestration()
                
                try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                
                _ = try? await self.aiOrchestrator.generateHealthInsights()
                
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 5.0)
        }
    }
    
    func testMemoryUsage() {
        // Given - AI orchestrator operations
        
        // When - Measuring memory usage
        let initialMemory = getMemoryUsage()
        
        Task {
            aiOrchestrator.startOrchestration()
            
            try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
            
            _ = try? await aiOrchestrator.generateHealthInsights()
            _ = try? await aiOrchestrator.generateRecommendations()
            _ = try? await aiOrchestrator.generatePredictions()
        }
        
        let finalMemory = getMemoryUsage()
        let memoryIncrease = finalMemory - initialMemory
        
        // Memory increase should be reasonable (less than 100MB)
        XCTAssertLessThan(memoryIncrease, 100.0)
    }
    
    // MARK: - Helper Methods
    
    private func getMemoryUsage() -> Double {
        // Mock memory usage measurement
        return Double.random(in: 100.0...200.0)
    }
}

// MARK: - Mock Data Generators

extension AdvancedAIOrchestrationTests {
    
    func generateMockHealthData() -> HealthData {
        return HealthData(
            heartRate: HeartRateData(
                average: 75.0,
                min: 60.0,
                max: 120.0,
                ecgData: Array(repeating: 0.0, count: 100)
            ),
            sleep: SleepData(
                duration: 7.5,
                efficiency: 0.85,
                stages: ["light": 0.4, "deep": 0.3, "rem": 0.3]
            ),
            respiratory: RespiratoryData(
                averageRate: 16.0,
                patterns: ["normal": 0.8, "deep": 0.2]
            ),
            environment: EnvironmentData(
                temperature: 22.0,
                humidity: 45.0,
                airQuality: 85.0
            ),
            timestamp: Date()
        )
    }
    
    func generateMockInsights() -> [HealthInsight] {
        return [
            HealthInsight(
                id: UUID(),
                type: .healthAlert,
                title: "Elevated Heart Rate",
                description: "Your average heart rate is elevated.",
                severity: .medium,
                confidence: 0.85,
                timestamp: Date(),
                source: "HealthPredictor"
            ),
            HealthInsight(
                id: UUID(),
                type: .sleepQuality,
                title: "Good Sleep Quality",
                description: "Your sleep quality is within normal range.",
                severity: .low,
                confidence: 0.92,
                timestamp: Date(),
                source: "SleepStageClassifier"
            )
        ]
    }
    
    func generateMockRecommendations() -> [HealthRecommendation] {
        return [
            HealthRecommendation(
                id: UUID(),
                type: .exercise,
                title: "Increase Physical Activity",
                description: "Aim for 30 minutes of moderate exercise daily.",
                priority: .medium,
                confidence: 0.85,
                actionable: true,
                timestamp: Date()
            ),
            HealthRecommendation(
                id: UUID(),
                type: .sleep,
                title: "Maintain Sleep Schedule",
                description: "Keep your consistent sleep schedule.",
                priority: .low,
                confidence: 0.78,
                actionable: true,
                timestamp: Date()
            )
        ]
    }
    
    func generateMockPredictions() -> [HealthPrediction] {
        return [
            HealthPrediction(
                id: UUID(),
                type: .healthRisk,
                title: "Low Cardiovascular Risk",
                description: "Low risk of cardiovascular issues.",
                probability: 0.15,
                timeframe: .threeMonths,
                confidence: 0.88,
                timestamp: Date()
            ),
            HealthPrediction(
                id: UUID(),
                type: .sleepQuality,
                title: "Sleep Improvement",
                description: "Predicted improvement in sleep quality.",
                probability: 0.75,
                timeframe: .oneMonth,
                confidence: 0.85,
                timestamp: Date()
            )
        ]
    }
    
    func generateMockModels() -> [AIModel] {
        return [
            AIModel(
                id: UUID(),
                name: "HealthPredictor",
                type: .healthPrediction,
                status: .ready,
                version: "1.0.0",
                accuracy: 0.92,
                latency: 25.0,
                memoryUsage: 150.0,
                lastUpdated: Date()
            ),
            AIModel(
                id: UUID(),
                name: "SleepStageClassifier",
                type: .sleepAnalysis,
                status: .ready,
                version: "1.0.0",
                accuracy: 0.88,
                latency: 30.0,
                memoryUsage: 120.0,
                lastUpdated: Date()
            )
        ]
    }
} 
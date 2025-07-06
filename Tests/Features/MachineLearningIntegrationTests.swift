import XCTest
import Foundation
import CoreML
import Combine
@testable import HealthAI2030

/// Comprehensive unit tests for Machine Learning Integration Manager
/// Tests all ML functionality including predictions, anomaly detection, recommendations, and model management
final class MachineLearningIntegrationTests: XCTestCase {
    var mlManager: MachineLearningIntegrationManager!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        mlManager = MachineLearningIntegrationManager.shared
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDown() {
        cancellables.removeAll()
        mlManager = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testInitialization() async {
        // Test initial state
        XCTAssertEqual(mlManager.mlStatus, .idle)
        XCTAssertTrue(mlManager.modelStatus.isEmpty)
        XCTAssertTrue(mlManager.predictions.isEmpty)
        XCTAssertTrue(mlManager.anomalies.isEmpty)
        XCTAssertTrue(mlManager.recommendations.isEmpty)
        XCTAssertTrue(mlManager.modelPerformance.isEmpty)
        XCTAssertNil(mlManager.lastTrainingDate)
        
        // Test initialization
        await mlManager.initialize()
        
        // Verify models are loaded
        XCTAssertFalse(mlManager.modelStatus.isEmpty)
        XCTAssertTrue(mlManager.modelStatus.values.contains(.ready))
    }
    
    func testModelLoading() async {
        await mlManager.loadModels()
        
        // Verify models are loaded
        XCTAssertFalse(mlManager.modelStatus.isEmpty)
        
        // Check specific models
        XCTAssertNotNil(mlManager.modelStatus["heartRatePredictor"])
        XCTAssertNotNil(mlManager.modelStatus["anomalyDetector"])
        XCTAssertNotNil(mlManager.modelStatus["recommendationEngine"])
    }
    
    // MARK: - Prediction Tests
    
    func testHealthPrediction() async {
        let inputData: [String: Any] = [
            "age": 30,
            "weight": 70.0,
            "activity_level": 8,
            "sleep_quality": 7,
            "stress_level": 5
        ]
        
        let prediction = await mlManager.makePrediction(
            for: .heartRate,
            inputData: inputData,
            modelName: "heartRatePredictor"
        )
        
        XCTAssertNotNil(prediction)
        XCTAssertEqual(prediction?.type, .heartRate)
        XCTAssertGreaterThan(prediction?.predictedValue ?? 0, 0)
        XCTAssertGreaterThanOrEqual(prediction?.confidence ?? 0, 0.7)
        XCTAssertLessThanOrEqual(prediction?.confidence ?? 1, 0.95)
        XCTAssertEqual(prediction?.modelName, "heartRatePredictor")
        XCTAssertFalse(prediction?.factors.isEmpty ?? true)
    }
    
    func testMultiplePredictionTypes() async {
        let inputData: [String: Any] = [
            "age": 25,
            "weight": 65.0,
            "activity_level": 9
        ]
        
        let predictionTypes: [MachineLearningIntegrationManager.PredictionType] = [
            .heartRate, .bloodPressure, .sleepQuality, .activityLevel
        ]
        
        for predictionType in predictionTypes {
            let prediction = await mlManager.makePrediction(
                for: predictionType,
                inputData: inputData
            )
            
            XCTAssertNotNil(prediction)
            XCTAssertEqual(prediction?.type, predictionType)
            XCTAssertGreaterThan(prediction?.predictedValue ?? 0, 0)
        }
    }
    
    func testPredictionWithEmptyInput() async {
        let prediction = await mlManager.makePrediction(
            for: .heartRate,
            inputData: [:]
        )
        
        // Should still return a prediction (using default values)
        XCTAssertNotNil(prediction)
    }
    
    func testPredictionConfidenceRange() async {
        let inputData: [String: Any] = ["age": 30]
        
        for _ in 0..<10 {
            let prediction = await mlManager.makePrediction(
                for: .heartRate,
                inputData: inputData
            )
            
            XCTAssertNotNil(prediction)
            XCTAssertGreaterThanOrEqual(prediction?.confidence ?? 0, 0.7)
            XCTAssertLessThanOrEqual(prediction?.confidence ?? 1, 0.95)
        }
    }
    
    // MARK: - Anomaly Detection Tests
    
    func testAnomalyDetection() async {
        let data = [70.0, 72.0, 75.0, 120.0, 68.0, 71.0] // 120 is an anomaly
        let timestamps = (0..<6).map { Date().addingTimeInterval(Double($0) * 3600) }
        
        let anomalies = await mlManager.detectAnomalies(
            for: .heartRate,
            data: data,
            timestamps: timestamps
        )
        
        XCTAssertFalse(anomalies.isEmpty)
        
        // Check if anomaly with value 120 is detected
        let anomaly120 = anomalies.first { $0.detectedValue == 120.0 }
        XCTAssertNotNil(anomaly120)
        XCTAssertEqual(anomaly120?.type, .heartRate)
        XCTAssertTrue(anomaly120?.severity == .high || anomaly120?.severity == .critical)
    }
    
    func testAnomalyDetectionWithNormalData() async {
        let data = [70.0, 72.0, 75.0, 68.0, 71.0, 73.0] // All normal values
        let timestamps = (0..<6).map { Date().addingTimeInterval(Double($0) * 3600) }
        
        let anomalies = await mlManager.detectAnomalies(
            for: .heartRate,
            data: data,
            timestamps: timestamps
        )
        
        // Should detect fewer or no anomalies with normal data
        XCTAssertLessThanOrEqual(anomalies.count, 1)
    }
    
    func testAnomalySeverityClassification() async {
        let data = [70.0, 150.0, 200.0, 300.0] // Increasingly severe anomalies
        let timestamps = (0..<4).map { Date().addingTimeInterval(Double($0) * 3600) }
        
        let anomalies = await mlManager.detectAnomalies(
            for: .heartRate,
            data: data,
            timestamps: timestamps
        )
        
        XCTAssertGreaterThanOrEqual(anomalies.count, 3)
        
        // Check severity progression
        let sortedAnomalies = anomalies.sorted { $0.detectedValue < $1.detectedValue }
        XCTAssertGreaterThanOrEqual(sortedAnomalies.count, 3)
        
        // Higher values should have higher severity
        if sortedAnomalies.count >= 3 {
            let severityOrder: [MachineLearningIntegrationManager.AnomalySeverity] = [.low, .medium, .high, .critical]
            let firstIndex = severityOrder.firstIndex(of: sortedAnomalies[0].severity) ?? 0
            let lastIndex = severityOrder.firstIndex(of: sortedAnomalies.last!.severity) ?? 0
            XCTAssertGreaterThanOrEqual(lastIndex, firstIndex)
        }
    }
    
    func testAnomalyRecommendations() async {
        let data = [200.0] // High heart rate
        let timestamps = [Date()]
        
        let anomalies = await mlManager.detectAnomalies(
            for: .heartRate,
            data: data,
            timestamps: timestamps
        )
        
        XCTAssertFalse(anomalies.isEmpty)
        
        let anomaly = anomalies.first
        XCTAssertNotNil(anomaly)
        XCTAssertFalse(anomaly?.recommendations.isEmpty ?? true)
        
        // Check for specific recommendations
        let recommendations = anomaly?.recommendations ?? []
        XCTAssertTrue(recommendations.contains { $0.contains("healthcare provider") })
    }
    
    // MARK: - Recommendation Tests
    
    func testRecommendationGeneration() async {
        let userProfile: [String: Any] = [
            "age": 30,
            "gender": "male",
            "activity_level": "moderate",
            "goals": ["weight_loss", "better_sleep"]
        ]
        
        let healthData: [String: Any] = [
            "current_weight": 80.0,
            "target_weight": 70.0,
            "sleep_quality": 6,
            "stress_level": 7
        ]
        
        let recommendations = await mlManager.generateRecommendations(
            userProfile: userProfile,
            healthData: healthData
        )
        
        XCTAssertFalse(recommendations.isEmpty)
        XCTAssertGreaterThanOrEqual(recommendations.count, 2)
        
        // Check recommendation properties
        for recommendation in recommendations {
            XCTAssertFalse(recommendation.title.isEmpty)
            XCTAssertFalse(recommendation.description.isEmpty)
            XCTAssertGreaterThanOrEqual(recommendation.confidence, 0.7)
            XCTAssertLessThanOrEqual(recommendation.confidence, 0.95)
            XCTAssertFalse(recommendation.reasoning.isEmpty)
            XCTAssertFalse(recommendation.expectedImpact.isEmpty)
            XCTAssertGreaterThan(recommendation.timeToImplement, 0)
        }
    }
    
    func testRecommendationCategories() async {
        let userProfile: [String: Any] = ["age": 25]
        let healthData: [String: Any] = ["activity_level": 3]
        
        let recommendations = await mlManager.generateRecommendations(
            userProfile: userProfile,
            healthData: healthData
        )
        
        XCTAssertFalse(recommendations.isEmpty)
        
        // Check that we have recommendations from different categories
        let categories = Set(recommendations.map { $0.category })
        XCTAssertGreaterThanOrEqual(categories.count, 2)
        
        // Verify all categories are valid
        let validCategories = Set(MachineLearningIntegrationManager.RecommendationCategory.allCases)
        XCTAssertTrue(categories.isSubset(of: validCategories))
    }
    
    func testRecommendationPriorities() async {
        let userProfile: [String: Any] = ["age": 40]
        let healthData: [String: Any] = ["stress_level": 9]
        
        let recommendations = await mlManager.generateRecommendations(
            userProfile: userProfile,
            healthData: healthData
        )
        
        XCTAssertFalse(recommendations.isEmpty)
        
        // Check that we have different priority levels
        let priorities = Set(recommendations.map { $0.priority })
        XCTAssertGreaterThanOrEqual(priorities.count, 2)
        
        // Verify all priorities are valid
        let validPriorities = Set(MachineLearningIntegrationManager.RecommendationPriority.allCases)
        XCTAssertTrue(priorities.isSubset(of: validPriorities))
    }
    
    func testRecommendationWithEmptyData() async {
        let recommendations = await mlManager.generateRecommendations(
            userProfile: [:],
            healthData: [:]
        )
        
        // Should still generate some recommendations
        XCTAssertFalse(recommendations.isEmpty)
    }
    
    // MARK: - Model Training Tests
    
    func testModelTraining() async {
        let trainingData: [String: Any] = [
            "features": [[1.0, 2.0, 3.0], [4.0, 5.0, 6.0]],
            "labels": [0, 1],
            "metadata": ["version": "1.0"]
        ]
        
        let configuration = MachineLearningIntegrationManager.ModelConfiguration(
            modelType: .healthPrediction,
            version: "1.0.0",
            lastTrainingDate: nil,
            performanceThreshold: 0.8,
            retrainingInterval: 7 * 24 * 3600,
            inputFeatures: ["feature1", "feature2", "feature3"],
            outputFeatures: ["prediction"]
        )
        
        await mlManager.trainModel(
            modelName: "testModel",
            trainingData: trainingData,
            configuration: configuration
        )
        
        // Verify training completed
        XCTAssertNotNil(mlManager.lastTrainingDate)
        XCTAssertEqual(mlManager.modelStatus["testModel"], .ready)
    }
    
    func testModelEvaluation() async {
        // First ensure we have a model to evaluate
        await mlManager.loadModels()
        
        let performance = await mlManager.evaluateModel(modelName: "heartRatePredictor")
        
        XCTAssertNotNil(performance)
        XCTAssertGreaterThanOrEqual(performance?.accuracy ?? 0, 0.7)
        XCTAssertLessThanOrEqual(performance?.accuracy ?? 1, 0.95)
        XCTAssertGreaterThanOrEqual(performance?.precision ?? 0, 0.7)
        XCTAssertGreaterThanOrEqual(performance?.recall ?? 0, 0.7)
        XCTAssertGreaterThanOrEqual(performance?.f1Score ?? 0, 0.7)
        XCTAssertGreaterThan(performance?.trainingSamples ?? 0, 0)
        XCTAssertGreaterThan(performance?.evaluationSamples ?? 0, 0)
        XCTAssertFalse(performance?.modelVersion.isEmpty ?? true)
    }
    
    // MARK: - Data Management Tests
    
    func testGetPredictionsByType() {
        // Add some test predictions
        let prediction1 = MachineLearningIntegrationManager.MLPrediction(
            type: .heartRate,
            predictedValue: 75.0,
            confidence: 0.85,
            predictionDate: Date(),
            modelName: "testModel",
            factors: ["age", "activity"]
        )
        
        let prediction2 = MachineLearningIntegrationManager.MLPrediction(
            type: .bloodPressure,
            predictedValue: 120.0,
            confidence: 0.80,
            predictionDate: Date(),
            modelName: "testModel",
            factors: ["age", "weight"]
        )
        
        mlManager.predictions = [prediction1, prediction2]
        
        let heartRatePredictions = mlManager.getPredictions(for: .heartRate)
        XCTAssertEqual(heartRatePredictions.count, 1)
        XCTAssertEqual(heartRatePredictions.first?.type, .heartRate)
        
        let bloodPressurePredictions = mlManager.getPredictions(for: .bloodPressure)
        XCTAssertEqual(bloodPressurePredictions.count, 1)
        XCTAssertEqual(bloodPressurePredictions.first?.type, .bloodPressure)
    }
    
    func testGetAnomaliesBySeverity() {
        // Add some test anomalies
        let anomaly1 = MachineLearningIntegrationManager.MLAnomaly(
            type: .heartRate,
            severity: .low,
            detectedValue: 85.0,
            expectedRange: 60...100,
            detectionDate: Date(),
            modelName: "testModel",
            description: "Slightly elevated heart rate"
        )
        
        let anomaly2 = MachineLearningIntegrationManager.MLAnomaly(
            type: .heartRate,
            severity: .high,
            detectedValue: 150.0,
            expectedRange: 60...100,
            detectionDate: Date(),
            modelName: "testModel",
            description: "High heart rate"
        )
        
        mlManager.anomalies = [anomaly1, anomaly2]
        
        let lowSeverityAnomalies = mlManager.getAnomalies(withSeverity: .low)
        XCTAssertEqual(lowSeverityAnomalies.count, 1)
        XCTAssertEqual(lowSeverityAnomalies.first?.severity, .low)
        
        let highSeverityAnomalies = mlManager.getAnomalies(withSeverity: .high)
        XCTAssertEqual(highSeverityAnomalies.count, 1)
        XCTAssertEqual(highSeverityAnomalies.first?.severity, .high)
    }
    
    func testGetRecommendationsByCategory() {
        // Add some test recommendations
        let recommendation1 = MachineLearningIntegrationManager.MLRecommendation(
            title: "Exercise More",
            description: "Increase daily activity",
            category: .exercise,
            confidence: 0.85,
            priority: .medium,
            modelName: "testModel",
            reasoning: ["Low activity level"],
            expectedImpact: "Better health",
            timeToImplement: 30 * 60
        )
        
        let recommendation2 = MachineLearningIntegrationManager.MLRecommendation(
            title: "Eat Better",
            description: "Improve nutrition",
            category: .nutrition,
            confidence: 0.80,
            priority: .high,
            modelName: "testModel",
            reasoning: ["Poor diet"],
            expectedImpact: "Better nutrition",
            timeToImplement: 60 * 60
        )
        
        mlManager.recommendations = [recommendation1, recommendation2]
        
        let exerciseRecommendations = mlManager.getRecommendations(for: .exercise)
        XCTAssertEqual(exerciseRecommendations.count, 1)
        XCTAssertEqual(exerciseRecommendations.first?.category, .exercise)
        
        let nutritionRecommendations = mlManager.getRecommendations(for: .nutrition)
        XCTAssertEqual(nutritionRecommendations.count, 1)
        XCTAssertEqual(nutritionRecommendations.first?.category, .nutrition)
    }
    
    // MARK: - Export and Summary Tests
    
    func testExportMLData() {
        // Add some test data
        mlManager.predictions = [
            MachineLearningIntegrationManager.MLPrediction(
                type: .heartRate,
                predictedValue: 75.0,
                confidence: 0.85,
                predictionDate: Date(),
                modelName: "testModel",
                factors: ["age"]
            )
        ]
        
        let exportData = mlManager.exportMLData()
        XCTAssertNotNil(exportData)
        
        // Verify data can be decoded
        if let data = exportData {
            let decoder = JSONDecoder()
            XCTAssertNoThrow(try decoder.decode(MLExportData.self, from: data))
        }
    }
    
    func testGetMLSummary() {
        // Add some test data
        mlManager.modelStatus = ["model1": .ready, "model2": .ready, "model3": .error]
        mlManager.predictions = [MachineLearningIntegrationManager.MLPrediction(
            type: .heartRate,
            predictedValue: 75.0,
            confidence: 0.85,
            predictionDate: Date(),
            modelName: "testModel",
            factors: ["age"]
        )]
        mlManager.anomalies = [MachineLearningIntegrationManager.MLAnomaly(
            type: .heartRate,
            severity: .low,
            detectedValue: 85.0,
            expectedRange: 60...100,
            detectionDate: Date(),
            modelName: "testModel",
            description: "Test anomaly"
        )]
        mlManager.recommendations = [MachineLearningIntegrationManager.MLRecommendation(
            title: "Test",
            description: "Test recommendation",
            category: .exercise,
            confidence: 0.85,
            priority: .medium,
            modelName: "testModel",
            reasoning: ["test"],
            expectedImpact: "test",
            timeToImplement: 30 * 60
        )]
        
        let summary = mlManager.getMLSummary()
        
        XCTAssertEqual(summary.totalModels, 3)
        XCTAssertEqual(summary.readyModels, 2)
        XCTAssertEqual(summary.totalPredictions, 1)
        XCTAssertEqual(summary.totalAnomalies, 1)
        XCTAssertEqual(summary.totalRecommendations, 1)
        XCTAssertEqual(summary.modelReadinessRate, 2.0 / 3.0, accuracy: 0.01)
    }
    
    // MARK: - Edge Case Tests
    
    func testEmptyModelStatus() {
        mlManager.modelStatus = [:]
        let summary = mlManager.getMLSummary()
        XCTAssertEqual(summary.totalModels, 0)
        XCTAssertEqual(summary.readyModels, 0)
        XCTAssertEqual(summary.modelReadinessRate, 0.0)
    }
    
    func testModelStatusUpdates() {
        // Test status transitions
        mlManager.modelStatus["testModel"] = .loading
        XCTAssertEqual(mlManager.getModelStatus(for: "testModel"), .loading)
        
        mlManager.modelStatus["testModel"] = .ready
        XCTAssertEqual(mlManager.getModelStatus(for: "testModel"), .ready)
        
        mlManager.modelStatus["testModel"] = .error
        XCTAssertEqual(mlManager.getModelStatus(for: "testModel"), .error)
    }
    
    func testNonExistentModel() {
        XCTAssertEqual(mlManager.getModelStatus(for: "nonExistentModel"), .notLoaded)
        XCTAssertNil(mlManager.getModelPerformance(for: "nonExistentModel"))
    }
    
    // MARK: - Performance Tests
    
    func testConcurrentPredictions() async {
        let inputData: [String: Any] = ["age": 30]
        
        await withTaskGroup(of: MachineLearningIntegrationManager.MLPrediction?.self) { group in
            for _ in 0..<10 {
                group.addTask {
                    await self.mlManager.makePrediction(
                        for: .heartRate,
                        inputData: inputData
                    )
                }
            }
            
            var predictions: [MachineLearningIntegrationManager.MLPrediction?] = []
            for await prediction in group {
                predictions.append(prediction)
            }
            
            XCTAssertEqual(predictions.count, 10)
            XCTAssertTrue(predictions.allSatisfy { $0 != nil })
        }
    }
    
    func testLargeDatasetAnomalyDetection() async {
        // Test with larger dataset
        let data = Array(0..<1000).map { Double($0 % 100) + Double.random(in: -5...5) }
        let timestamps = (0..<1000).map { Date().addingTimeInterval(Double($0) * 3600) }
        
        let anomalies = await mlManager.detectAnomalies(
            for: .heartRate,
            data: data,
            timestamps: timestamps
        )
        
        // Should complete without crashing
        XCTAssertGreaterThanOrEqual(anomalies.count, 0)
    }
}

// MARK: - Supporting Structures for Tests

private struct MLExportData: Codable {
    let mlStatus: MachineLearningIntegrationManager.MLStatus
    let modelStatus: [String: MachineLearningIntegrationManager.ModelStatus]
    let predictions: [MachineLearningIntegrationManager.MLPrediction]
    let anomalies: [MachineLearningIntegrationManager.MLAnomaly]
    let recommendations: [MachineLearningIntegrationManager.MLRecommendation]
    let modelPerformance: [String: MachineLearningIntegrationManager.ModelPerformance]
    let lastTrainingDate: Date?
    let exportDate: Date
} 
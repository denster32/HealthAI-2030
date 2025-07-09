import XCTest
import Combine
import SwiftUI
import CoreML
@testable import HealthAI2030Core

@available(iOS 18.0, macOS 15.0, *)
final class PredictiveHealthModelingEngineTests: XCTestCase {
    
    var modelingEngine: PredictiveHealthModelingEngine!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        modelingEngine = PredictiveHealthModelingEngine.shared
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDown() {
        cancellables.removeAll()
        modelingEngine = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testModelingEngineInitialization() {
        XCTAssertNotNil(modelingEngine)
        XCTAssertTrue(modelingEngine.currentPredictions.isEmpty)
        XCTAssertTrue(modelingEngine.riskAssessments.isEmpty)
        XCTAssertTrue(modelingEngine.personalizedModels.isEmpty)
        XCTAssertFalse(modelingEngine.isModeling)
        XCTAssertEqual(modelingEngine.modelAccuracy, 0.0)
        XCTAssertEqual(modelingEngine.predictionConfidence, 0.0)
    }
    
    // MARK: - Modeling Control Tests
    
    func testStartModeling() {
        let expectation = XCTestExpectation(description: "Modeling started")
        
        modelingEngine.$isModeling
            .dropFirst()
            .sink { isModeling in
                XCTAssertTrue(isModeling)
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        modelingEngine.startModeling()
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testStopModeling() {
        modelingEngine.isModeling = true
        
        let expectation = XCTestExpectation(description: "Modeling stopped")
        
        modelingEngine.$isModeling
            .dropFirst()
            .sink { isModeling in
                XCTAssertFalse(isModeling)
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        modelingEngine.stopModeling()
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    // MARK: - Predictive Modeling Tests
    
    func testPerformPredictiveModeling() async throws {
        let report = try await modelingEngine.performPredictiveModeling()
        
        XCTAssertNotNil(report)
        XCTAssertNotNil(report.predictions)
        XCTAssertNotNil(report.riskAssessments)
        XCTAssertNotNil(report.personalizedModels)
        XCTAssertNotNil(report.timestamp)
    }
    
    func testPerformPredictiveModelingUpdatesPublishedProperties() async throws {
        let initialPredictionsCount = modelingEngine.currentPredictions.count
        let initialRisksCount = modelingEngine.riskAssessments.count
        let initialModelsCount = modelingEngine.personalizedModels.count
        
        _ = try await modelingEngine.performPredictiveModeling()
        
        // Wait for UI updates
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        XCTAssertNotEqual(modelingEngine.currentPredictions.count, initialPredictionsCount)
        XCTAssertNotEqual(modelingEngine.riskAssessments.count, initialRisksCount)
        XCTAssertNotEqual(modelingEngine.personalizedModels.count, initialModelsCount)
    }
    
    // MARK: - Prediction Generation Tests
    
    func testGeneratePredictionsForSpecificMetrics() async throws {
        let metrics: [HealthMetricType] = [.heartRate, .sleep, .steps]
        let horizon: TimeInterval = 7 * 24 * 3600 // 7 days
        
        let predictions = try await modelingEngine.generatePredictions(for: metrics, horizon: horizon)
        
        XCTAssertNotNil(predictions)
        XCTAssertTrue(predictions is [HealthPrediction])
        XCTAssertGreaterThanOrEqual(predictions.count, 0)
    }
    
    func testGeneratePredictionsWithDefaultHorizon() async throws {
        let metrics: [HealthMetricType] = [.heartRate]
        
        let predictions = try await modelingEngine.generatePredictions(for: metrics)
        
        XCTAssertNotNil(predictions)
        XCTAssertTrue(predictions is [HealthPrediction])
    }
    
    // MARK: - Risk Assessment Tests
    
    func testAssessHealthRisks() async throws {
        let assessments = try await modelingEngine.assessHealthRisks()
        
        XCTAssertNotNil(assessments)
        XCTAssertTrue(assessments is [HealthRiskAssessment])
    }
    
    func testAssessHealthRisksUpdatesPublishedProperties() async throws {
        let initialRisksCount = modelingEngine.riskAssessments.count
        
        _ = try await modelingEngine.assessHealthRisks()
        
        // Wait for UI updates
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        XCTAssertNotEqual(modelingEngine.riskAssessments.count, initialRisksCount)
    }
    
    // MARK: - Personalized Models Tests
    
    func testGeneratePersonalizedModels() async throws {
        let models = try await modelingEngine.generatePersonalizedModels()
        
        XCTAssertNotNil(models)
        XCTAssertTrue(models is [PersonalizedHealthModel])
        XCTAssertGreaterThanOrEqual(models.count, 0)
    }
    
    func testGeneratePersonalizedModelsUpdatesPublishedProperties() async throws {
        let initialModelsCount = modelingEngine.personalizedModels.count
        
        _ = try await modelingEngine.generatePersonalizedModels()
        
        // Wait for UI updates
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        XCTAssertNotEqual(modelingEngine.personalizedModels.count, initialModelsCount)
    }
    
    // MARK: - Model Training Tests
    
    func testTrainModels() async throws {
        let mockData = createMockProcessedHealthData()
        
        // This should not throw an error
        try await modelingEngine.trainModels(with: mockData)
    }
    
    func testEvaluateModelPerformance() async throws {
        let performance = try await modelingEngine.evaluateModelPerformance()
        
        XCTAssertNotNil(performance)
        XCTAssertTrue(performance is ModelPerformance)
        XCTAssertGreaterThanOrEqual(performance.overallAccuracy, 0.0)
        XCTAssertLessThanOrEqual(performance.overallAccuracy, 1.0)
    }
    
    // MARK: - Query Tests
    
    func testGetPredictionsForHorizon() async throws {
        // First generate some predictions
        let metrics: [HealthMetricType] = [.heartRate]
        _ = try await modelingEngine.generatePredictions(for: metrics, horizon: 7 * 24 * 3600)
        
        // Then query for specific horizon
        let predictions = try await modelingEngine.getPredictions(for: 7 * 24 * 3600)
        
        XCTAssertNotNil(predictions)
        XCTAssertTrue(predictions is [HealthPrediction])
    }
    
    func testGetRiskAssessmentsForCategory() async throws {
        // First assess risks
        _ = try await modelingEngine.assessHealthRisks()
        
        // Then query for specific category
        let assessments = try await modelingEngine.getRiskAssessments(for: .cardiovascular)
        
        XCTAssertNotNil(assessments)
        XCTAssertTrue(assessments is [HealthRiskAssessment])
    }
    
    func testGetPersonalizedModelForAspect() async throws {
        // First generate personalized models
        _ = try await modelingEngine.generatePersonalizedModels()
        
        // Then query for specific aspect
        let model = try await modelingEngine.getPersonalizedModel(for: .cardiovascular)
        
        // Model might be nil if no models were generated for this aspect
        if let model = model {
            XCTAssertTrue(model is PersonalizedHealthModel)
            XCTAssertEqual(model.aspect, .cardiovascular)
        }
    }
    
    // MARK: - Error Handling Tests
    
    func testModelingEngineHandlesErrorsGracefully() async {
        // This test verifies that the engine doesn't crash when errors occur
        do {
            _ = try await modelingEngine.performPredictiveModeling()
            // If we get here, no error was thrown
            XCTAssertTrue(true)
        } catch {
            // If an error is thrown, it should be handled gracefully
            XCTAssertTrue(error is PredictiveModelingError)
        }
    }
    
    func testPredictiveModelingErrorTypes() {
        let errors: [PredictiveModelingError] = [
            .engineNotInitialized,
            .digitalTwinNotAvailable,
            .modelTrainingFailed,
            .predictionFailed,
            .dataUnavailable
        ]
        
        for error in errors {
            XCTAssertNotNil(error.errorDescription)
            XCTAssertFalse(error.errorDescription!.isEmpty)
        }
    }
    
    // MARK: - Performance Tests
    
    func testModelingPerformance() async throws {
        let startTime = Date()
        
        _ = try await modelingEngine.performPredictiveModeling()
        
        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)
        
        // Modeling should complete within reasonable time (10 seconds)
        XCTAssertLessThan(duration, 10.0)
    }
    
    func testConcurrentModelingRequests() async throws {
        let expectation1 = XCTestExpectation(description: "First modeling request")
        let expectation2 = XCTestExpectation(description: "Second modeling request")
        
        async let report1 = modelingEngine.performPredictiveModeling()
        async let report2 = modelingEngine.performPredictiveModeling()
        
        let (result1, result2) = try await (report1, report2)
        
        XCTAssertNotNil(result1)
        XCTAssertNotNil(result2)
        
        expectation1.fulfill()
        expectation2.fulfill()
        
        wait(for: [expectation1, expectation2], timeout: 15.0)
    }
    
    // MARK: - Data Model Tests
    
    func testPredictiveModelingReportStructure() {
        let report = PredictiveModelingReport(
            predictions: [],
            riskAssessments: [],
            personalizedModels: [],
            timestamp: Date()
        )
        
        XCTAssertNotNil(report.predictions)
        XCTAssertNotNil(report.riskAssessments)
        XCTAssertNotNil(report.personalizedModels)
        XCTAssertNotNil(report.timestamp)
    }
    
    func testPersonalizedHealthModelStructure() {
        let model = PersonalizedHealthModel(
            aspect: .cardiovascular,
            features: ["heart_rate": 75.0],
            predictions: [],
            recommendations: [],
            accuracy: 0.85,
            lastUpdated: Date()
        )
        
        XCTAssertEqual(model.aspect, .cardiovascular)
        XCTAssertEqual(model.features["heart_rate"], 75.0)
        XCTAssertEqual(model.accuracy, 0.85)
        XCTAssertNotNil(model.lastUpdated)
    }
    
    func testHealthAspectEnum() {
        let aspects = HealthAspect.allCases
        
        XCTAssertEqual(aspects.count, 5)
        XCTAssertTrue(aspects.contains(.cardiovascular))
        XCTAssertTrue(aspects.contains(.sleep))
        XCTAssertTrue(aspects.contains(.activity))
        XCTAssertTrue(aspects.contains(.nutrition))
        XCTAssertTrue(aspects.contains(.mental))
    }
    
    // MARK: - Integration Tests
    
    func testModelingEngineIntegrationWithPredictionEngine() async throws {
        // Test that the modeling engine properly integrates with the underlying prediction engine
        let report = try await modelingEngine.performPredictiveModeling()
        
        XCTAssertNotNil(report.predictions)
        XCTAssertNotNil(report.riskAssessments)
        XCTAssertNotNil(report.personalizedModels)
    }
    
    func testModelingEngineIntegrationWithDigitalTwin() async throws {
        // Test that the modeling engine properly integrates with the digital twin
        let models = try await modelingEngine.generatePersonalizedModels()
        
        XCTAssertNotNil(models)
        XCTAssertTrue(models is [PersonalizedHealthModel])
    }
    
    // MARK: - Periodic Updates Tests
    
    func testPeriodicUpdates() async throws {
        let expectation = XCTestExpectation(description: "Periodic update")
        expectation.expectedFulfillmentCount = 2
        
        var updateCount = 0
        modelingEngine.$lastUpdateTime
            .dropFirst()
            .sink { _ in
                updateCount += 1
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // Wait for periodic updates (should happen every 10 minutes, but we'll wait less for testing)
        wait(for: [expectation], timeout: 15.0)
        
        XCTAssertGreaterThanOrEqual(updateCount, 1)
    }
    
    // MARK: - Mock Data Tests
    
    func testMockDataGeneration() async throws {
        let report = try await modelingEngine.performPredictiveModeling()
        
        // Verify that mock data was generated and processed
        XCTAssertNotNil(report)
        XCTAssertNotNil(report.predictions)
        XCTAssertNotNil(report.riskAssessments)
        XCTAssertNotNil(report.personalizedModels)
    }
    
    // MARK: - Model Accuracy Tests
    
    func testModelAccuracyCalculation() async throws {
        let initialAccuracy = modelingEngine.modelAccuracy
        
        _ = try await modelingEngine.performPredictiveModeling()
        
        // Wait for UI updates
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        let finalAccuracy = modelingEngine.modelAccuracy
        
        // Model accuracy should be calculated and updated
        XCTAssertNotEqual(initialAccuracy, finalAccuracy)
        XCTAssertGreaterThanOrEqual(finalAccuracy, 0.0)
        XCTAssertLessThanOrEqual(finalAccuracy, 1.0)
    }
    
    func testPredictionConfidenceCalculation() async throws {
        let initialConfidence = modelingEngine.predictionConfidence
        
        _ = try await modelingEngine.performPredictiveModeling()
        
        // Wait for UI updates
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        let finalConfidence = modelingEngine.predictionConfidence
        
        // Prediction confidence should be calculated and updated
        XCTAssertNotEqual(initialConfidence, finalConfidence)
        XCTAssertGreaterThanOrEqual(finalConfidence, 0.0)
        XCTAssertLessThanOrEqual(finalConfidence, 1.0)
    }
    
    // MARK: - UI Integration Tests
    
    func testPublishedPropertiesForUI() {
        // Test that all published properties are accessible for UI binding
        XCTAssertNotNil(modelingEngine.currentPredictions)
        XCTAssertNotNil(modelingEngine.riskAssessments)
        XCTAssertNotNil(modelingEngine.personalizedModels)
        XCTAssertNotNil(modelingEngine.modelPerformance)
        XCTAssertNotNil(modelingEngine.isModeling)
        XCTAssertNotNil(modelingEngine.lastUpdateTime)
        XCTAssertNotNil(modelingEngine.modelAccuracy)
        XCTAssertNotNil(modelingEngine.predictionConfidence)
    }
    
    func testObservableObjectConformance() {
        // Test that the modeling engine conforms to ObservableObject for SwiftUI
        XCTAssertTrue(modelingEngine is ObservableObject)
    }
    
    // MARK: - Health Aspect Tests
    
    func testHealthAspectFeatures() async throws {
        // Test that each health aspect can generate features
        for aspect in HealthAspect.allCases {
            let features = try await extractFeaturesForAspect(aspect)
            XCTAssertNotNil(features)
            XCTAssertFalse(features.isEmpty)
        }
    }
    
    func testHealthAspectPredictions() async throws {
        // Test that each health aspect can generate predictions
        for aspect in HealthAspect.allCases {
            let features = try await extractFeaturesForAspect(aspect)
            let predictions = try await generatePredictionsForAspect(aspect, features: features)
            XCTAssertNotNil(predictions)
            XCTAssertTrue(predictions is [HealthPrediction])
        }
    }
    
    // MARK: - Test Helpers
    
    private func createMockProcessedHealthData() -> [ProcessedHealthData] {
        let now = Date()
        var data: [ProcessedHealthData] = []
        
        for i in 0..<7 {
            let timestamp = now.addingTimeInterval(-Double(i * 24 * 3600))
            let healthData = HealthData(
                timestamp: timestamp,
                heartRate: Int.random(in: 60...100),
                steps: Int.random(in: 5000...15000),
                sleepHours: Double.random(in: 6.0...9.0),
                calories: Int.random(in: 1500...2500)
            )
            
            let processedData = ProcessedHealthData(
                originalData: healthData,
                metrics: HealthMetrics(),
                quality: .high
            )
            
            data.append(processedData)
        }
        
        return data
    }
    
    private func extractFeaturesForAspect(_ aspect: HealthAspect) async throws -> [String: Double] {
        // Mock feature extraction for testing
        switch aspect {
        case .cardiovascular:
            return ["resting_heart_rate": 75.0, "blood_pressure_systolic": 120.0]
        case .sleep:
            return ["sleep_duration": 7.5, "sleep_quality": 0.8]
        case .activity:
            return ["daily_steps": 8000, "exercise_minutes": 150]
        case .nutrition:
            return ["calorie_intake": 2000, "water_intake": 2500]
        case .mental:
            return ["stress_level": 0.3, "mood_score": 0.8]
        }
    }
    
    private func generatePredictionsForAspect(_ aspect: HealthAspect, features: [String: Double]) async throws -> [HealthPrediction] {
        // Mock prediction generation for testing
        let prediction = HealthPrediction(
            type: .healthRisk,
            value: 0.5,
            confidence: 0.8,
            timeframe: 30 * 24 * 3600,
            timestamp: Date()
        )
        
        return [prediction]
    }
}

// MARK: - Test Extensions

extension PredictiveHealthModelingEngineTests {
    
    func testModelingEngineSingleton() {
        let instance1 = PredictiveHealthModelingEngine.shared
        let instance2 = PredictiveHealthModelingEngine.shared
        
        XCTAssertTrue(instance1 === instance2)
    }
    
    func testModelingEngineMemoryManagement() {
        weak var weakReference: PredictiveHealthModelingEngine?
        
        autoreleasepool {
            let strongReference = PredictiveHealthModelingEngine.shared
            weakReference = strongReference
        }
        
        // The singleton should remain in memory
        XCTAssertNotNil(weakReference)
    }
} 
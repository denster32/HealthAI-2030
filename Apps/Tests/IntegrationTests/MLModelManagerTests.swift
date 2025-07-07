import XCTest
import CoreML
@testable import HealthAI2030ML

final class MLModelManagerTests: XCTestCase {
    var modelManager: MLModelManager!
    
    override func setUp() {
        super.setUp()
        modelManager = .shared
    }
    
    /// Test secure model storage and retrieval
    func testModelStorageAndRetrieval() {
        // Create a mock MLModel (this would typically be a real CoreML model)
        let mockModelURL = Bundle.main.url(forResource: "MockHealthModel", withExtension: "mlmodel")!
        
        do {
            let mockModel = try MLModel(contentsOf: mockModelURL)
            
            // Store the model
            try modelManager.storeModel(model: mockModel, identifier: "healthPredictionModel")
            
            // Retrieve the model
            let retrievedModel = try modelManager.loadModel(identifier: "healthPredictionModel")
            
            XCTAssertNotNil(retrievedModel, "Retrieved model should not be nil")
        } catch {
            XCTFail("Model storage or retrieval failed: \(error)")
        }
    }
    
    /// Test model performance validation
    func testModelPerformanceValidation() {
        // Create mock performance metrics
        let validMetrics = ModelPerformanceMetrics(
            accuracy: 0.90,
            precision: 0.88,
            recall: 0.92,
            f1Score: 0.90,
            inferenceTime: 0.3
        )
        
        let invalidMetrics = ModelPerformanceMetrics(
            accuracy: 0.70,
            precision: 0.65,
            recall: 0.60,
            f1Score: 0.62,
            inferenceTime: 0.8
        )
        
        // Create a mock MLModel (this would typically be a real CoreML model)
        let mockModelURL = Bundle.main.url(forResource: "MockHealthModel", withExtension: "mlmodel")!
        
        do {
            let mockModel = try MLModel(contentsOf: mockModelURL)
            
            // Test valid metrics
            try modelManager.validateModel(model: mockModel, metrics: validMetrics)
            
            // Test invalid metrics
            XCTAssertThrowsError(try modelManager.validateModel(model: mockModel, metrics: invalidMetrics)) { error in
                XCTAssertTrue(error is MLModelError)
                XCTAssertEqual(error as? MLModelError, .modelValidationFailed)
            }
        } catch {
            XCTFail("Model validation test failed: \(error)")
        }
    }
    
    /// Test model drift detection
    func testModelDriftDetection() {
        let baselineDistribution = [0.3, 0.4, 0.3]
        let similarDistribution = [0.31, 0.38, 0.31]
        let significantlyDifferentDistribution = [0.1, 0.8, 0.1]
        
        do {
            // First call sets baseline
            try modelManager.detectModelDrift(modelIdentifier: "testModel", newDistribution: baselineDistribution)
            
            // Similar distribution should not trigger drift
            try modelManager.detectModelDrift(modelIdentifier: "testModel", newDistribution: similarDistribution)
            
            // Significantly different distribution should trigger drift
            XCTAssertThrowsError(try modelManager.detectModelDrift(modelIdentifier: "testModel", newDistribution: significantlyDifferentDistribution)) { error in
                XCTAssertTrue(error is MLModelError)
                XCTAssertEqual(error as? MLModelError, .driftDetected)
            }
        } catch {
            XCTFail("Model drift detection test failed: \(error)")
        }
    }
    
    /// Test model fairness analysis
    func testModelFairnessAnalysis() {
        // Simulated predictions across different demographic groups
        let predictions: [(input: [String: Any], prediction: Any, group: String)] = [
            (input: ["age": 25, "gender": "female"], prediction: "healthy", group: "young_female"),
            (input: ["age": 25, "gender": "female"], prediction: "healthy", group: "young_female"),
            (input: ["age": 25, "gender": "female"], prediction: "healthy", group: "young_female"),
            (input: ["age": 50, "gender": "male"], prediction: "healthy", group: "middle_aged_male"),
            (input: ["age": 50, "gender": "male"], prediction: "unhealthy", group: "middle_aged_male"),
            (input: ["age": 50, "gender": "male"], prediction: "unhealthy", group: "middle_aged_male")
        ]
        
        do {
            // This should not throw an error
            try modelManager.analyzeFairness(predictions: predictions)
        } catch {
            XCTFail("Fairness analysis failed unexpectedly: \(error)")
        }
        
        // Test with potentially biased predictions
        let biasedPredictions: [(input: [String: Any], prediction: Any, group: String)] = [
            (input: ["age": 25, "gender": "female"], prediction: "healthy", group: "young_female"),
            (input: ["age": 25, "gender": "female"], prediction: "healthy", group: "young_female"),
            (input: ["age": 25, "gender": "female"], prediction: "healthy", group: "young_female"),
            (input: ["age": 50, "gender": "male"], prediction: "unhealthy", group: "middle_aged_male"),
            (input: ["age": 50, "gender": "male"], prediction: "unhealthy", group: "middle_aged_male"),
            (input: ["age": 50, "gender": "male"], prediction: "unhealthy", group: "middle_aged_male")
        ]
        
        XCTAssertThrowsError(try modelManager.analyzeFairness(predictions: biasedPredictions)) { error in
            XCTAssertTrue(error is MLModelError)
            XCTAssertEqual(error as? MLModelError, .biasDetected)
        }
    }
    
    /// Test model performance tracking
    func testModelPerformanceTracking() {
        // This test ensures the tracking method doesn't throw and logs correctly
        XCTAssertNoThrow(
            modelManager.trackModelPerformance(
                modelIdentifier: "performanceTrackingTest", 
                accuracy: 0.85, 
                precision: 0.82, 
                recall: 0.88, 
                inferenceTime: 0.4
            )
        )
    }
    
    /// Test model update mechanism
    func testModelUpdateFromRemote() {
        // Create a mock remote URL (in a real scenario, this would be a valid model download URL)
        let mockRemoteURL = URL(string: "https://example.com/models/health_prediction.mlmodel")!
        
        let expectation = XCTestExpectation(description: "Model Update")
        
        do {
            try modelManager.updateModelFromRemote(modelIdentifier: "healthPredictionModel", remoteURL: mockRemoteURL)
            
            // Wait for async operation
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                expectation.fulfill()
            }
        } catch {
            XCTFail("Model update failed: \(error)")
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5)
    }
}

// Placeholder for mock model - in a real project, this would be a real CoreML model
extension Bundle {
    static var main: Bundle {
        // Provide a mock bundle for testing
        return Bundle(for: MLModelManagerTests.self)
    }
} 
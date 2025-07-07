import XCTest
import Combine
import HealthKit
@testable import SleepTracking

final class SleepEnvironmentOptimizerTests: XCTestCase {
    var optimizer: SleepEnvironmentOptimizer!
    var cancellables: Set<AnyCancellable> = []
    
    override func setUp() {
        super.setUp()
        optimizer = .shared
    }
    
    override func tearDown() {
        cancellables.removeAll()
        super.tearDown()
    }
    
    /// Test biometric updates publisher
    func testBiometricUpdatesPublisher() {
        let expectation = XCTestExpectation(description: "Receive biometric updates")
        
        optimizer.subscribeToBiometricUpdates()
            .sink { model in
                XCTAssertGreaterThan(model.temperature, 0, "Temperature should be valid")
                XCTAssertGreaterThan(model.humidity, 0, "Humidity should be valid")
                XCTAssertGreaterThan(model.noise, 0, "Noise level should be valid")
                XCTAssertGreaterThan(model.light, 0, "Light level should be valid")
                XCTAssertGreaterThan(model.breathingPattern, 0, "Breathing pattern should be valid")
                
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // Manually trigger optimization to simulate update
        optimizer.optimizeEnvironment()
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    /// Test intervention recommendations publisher
    func testInterventionRecommendationsPublisher() {
        let expectation = XCTestExpectation(description: "Receive intervention recommendations")
        
        optimizer.subscribeToInterventionRecommendations()
            .sink { recommendation in
                XCTAssertGreaterThan(recommendation.intensity, 0, "Intervention intensity should be positive")
                XCTAssertGreaterThan(recommendation.duration, 0, "Intervention duration should be positive")
                XCTAssertFalse(recommendation.explanation.isEmpty, "Intervention explanation should not be empty")
                
                // Verify intervention type is valid
                switch recommendation.type {
                case .temperatureAdjustment, .soundMasking, .lightModulation, 
                     .breathingExercise, .relaxationGuide, .none:
                    break
                }
                
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // Manually trigger optimization to simulate recommendation
        optimizer.optimizeEnvironment()
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    /// Test heart rate variability calculation
    func testHeartRateVariabilityCalculation() {
        // Simulate heart rate samples
        let heartRates = [
            70.0, 75.0, 72.0, 68.0, 73.0,  // Simulated heart rate measurements
            71.0, 69.0, 74.0, 76.0, 70.0
        ]
        
        // Use reflection to call private method
        let method = NSSelectorFromString("calculateHeartRateVariability:")
        let calculation = optimizer.perform(method, with: heartRates)
        
        guard let hrvValue = calculation?.takeUnretainedValue() as? Double else {
            XCTFail("Heart rate variability calculation failed")
            return
        }
        
        XCTAssertGreaterThan(hrvValue, 0, "HRV should be a positive value")
        XCTAssertLessThan(hrvValue, 10, "HRV should be within reasonable range")
    }
    
    /// Test environment sensing methods
    func testEnvironmentSensingMethods() {
        // Use reflection to call private methods
        let methods = [
            "getCurrentRoomTemperature",
            "getCurrentHumidity",
            "getCurrentNoiseLevel",
            "getCurrentLightLevel",
            "getCurrentBreathingRate"
        ]
        
        for methodName in methods {
            let selector = NSSelectorFromString(methodName)
            let result = optimizer.perform(selector)
            
            guard let value = result?.takeUnretainedValue() as? Double else {
                XCTFail("Failed to call method: \(methodName)")
                continue
            }
            
            XCTAssertGreaterThan(value, 0, "\(methodName) should return a positive value")
        }
    }
    
    /// Test intervention explanation generation
    func testInterventionExplanationGeneration() {
        let interventionTypes: [SleepInterventionRecommendation.InterventionType] = [
            .temperatureAdjustment, .soundMasking, .lightModulation,
            .breathingExercise, .relaxationGuide, .none
        ]
        
        for type in interventionTypes {
            // Use reflection to call private method
            let method = NSSelectorFromString("generateInterventionExplanation:")
            let calculation = optimizer.perform(method, with: type)
            
            guard let explanation = calculation?.takeUnretainedValue() as? String else {
                XCTFail("Explanation generation failed for type: \(type)")
                continue
            }
            
            XCTAssertFalse(explanation.isEmpty, "Explanation should not be empty for type: \(type)")
            XCTAssertTrue(explanation.count > 10, "Explanation should be meaningful")
        }
    }
    
    /// Test ML model prediction mapping
    func testMLPredictionMapping() {
        let testPredictions: [[String: Any]] = [
            ["interventionType": "temperature"],
            ["interventionType": "sound"],
            ["interventionType": "light"],
            ["interventionType": "breathing"],
            ["interventionType": "relaxation"],
            ["interventionType": "unknown"]
        ]
        
        let expectedTypes: [SleepInterventionRecommendation.InterventionType] = [
            .temperatureAdjustment, .soundMasking, .lightModulation,
            .breathingExercise, .relaxationGuide, .none
        ]
        
        for (prediction, expectedType) in zip(testPredictions, expectedTypes) {
            // Use reflection to call private method
            let method = NSSelectorFromString("mapMLPredictionToInterventionType:")
            let calculation = optimizer.perform(method, with: prediction)
            
            guard let mappedType = calculation?.takeUnretainedValue() as? SleepInterventionRecommendation.InterventionType else {
                XCTFail("Prediction mapping failed for input: \(prediction)")
                continue
            }
            
            XCTAssertEqual(mappedType, expectedType, "Incorrect mapping for prediction: \(prediction)")
        }
    }
}

// Extension to help with private method testing
extension SleepEnvironmentOptimizer {
    func perform(_ selector: Selector, with object: Any? = nil) -> Unmanaged<AnyObject>? {
        let method = class_getInstanceMethod(type(of: self), selector)
        typealias MethodType = @convention(c) (AnyObject, Selector, Any?) -> Unmanaged<AnyObject>?
        let methodImplementation = method_getImplementation(method!)
        let imp = unsafeBitCast(methodImplementation, to: MethodType.self)
        return imp(self, selector, object)
    }
} 
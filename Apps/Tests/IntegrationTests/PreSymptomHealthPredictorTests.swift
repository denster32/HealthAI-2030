import XCTest
import Combine
@testable import PredictionEngineKit
import HealthKit

class PreSymptomHealthPredictorTests: XCTestCase {
    var predictor: PreSymptomHealthPredictor!
    var cancellables: Set<AnyCancellable> = []
    
    override func setUp() {
        super.setUp()
        predictor = PreSymptomHealthPredictor.shared
    }
    
    override func tearDown() {
        predictor = nil
        cancellables.removeAll()
        super.tearDown()
    }
    
    /// Comprehensive scenario-based prediction testing
    func testScenarioBasedPredictions() {
        let scenarios: [MockHealthDataGenerator.HealthScenario] = [
            .healthy, .preDiabetic, .highStress, 
            .poorSleep, .cardiovascularRisk, .metabolicSyndrome
        ]
        
        let expectation = XCTestExpectation(description: "Scenario-Based Predictions")
        expectation.expectedFulfillmentCount = scenarios.count
        
        scenarios.forEach { scenario in
            let input = MockHealthDataGenerator.generateHealthInput(scenario: scenario)
            
            predictor.predictPreSymptomHealthRisks(input: input) { result in
                switch result {
                case .success(let output):
                    XCTAssertNotNil(output, "Prediction output should not be nil for scenario: \(scenario)")
                    XCTAssertFalse(output.predictedRisks.isEmpty, "Should have predicted risks for scenario: \(scenario)")
                    
                    // Validate risk level based on scenario
                    switch scenario {
                    case .healthy:
                        XCTAssertTrue(output.overallRiskLevel == .low, "Healthy scenario should have low risk")
                    case .preDiabetic, .highStress, .poorSleep:
                        XCTAssertTrue([.moderate, .high].contains(output.overallRiskLevel), "Scenario should have moderate to high risk")
                    case .cardiovascularRisk, .metabolicSyndrome:
                        XCTAssertTrue([.high, .critical].contains(output.overallRiskLevel), "Scenario should have high or critical risk")
                    case .random:
                        break // No specific assertions for random scenario
                    }
                    
                    expectation.fulfill()
                    
                case .failure(let error):
                    XCTFail("Prediction failed for scenario \(scenario): \(error)")
                    expectation.fulfill()
                }
            }
        }
        
        wait(for: [expectation], timeout: 10.0)
    }
    
    /// Stress test with large number of random health inputs
    func testStressTestDataset() {
        let stressTestDataset = MockHealthDataGenerator.generateStressTestDataset(scenarioCount: 500)
        
        let expectation = XCTestExpectation(description: "Stress Test Predictions")
        expectation.expectedFulfillmentCount = stressTestDataset.count
        
        var successCount = 0
        var failureCount = 0
        
        stressTestDataset.forEach { input in
            predictor.predictPreSymptomHealthRisks(input: input) { result in
                switch result {
                case .success:
                    successCount += 1
                case .failure:
                    failureCount += 1
                }
                
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 30.0)
        
        XCTAssertTrue(successCount > 0, "At least some predictions should succeed")
        XCTAssertTrue(failureCount < stressTestDataset.count / 10, "Failure rate should be low")
    }
    
    /// Test edge case inputs for robustness
    func testEdgeCaseInputs() {
        let edgeCaseInputs = MockHealthDataGenerator.generateEdgeCaseInputs()
        
        let expectation = XCTestExpectation(description: "Edge Case Predictions")
        expectation.expectedFulfillmentCount = edgeCaseInputs.count
        
        edgeCaseInputs.forEach { input in
            predictor.predictPreSymptomHealthRisks(input: input) { result in
                switch result {
                case .success(let output):
                    // Validate that the predictor can handle extreme/invalid inputs
                    XCTAssertNotNil(output, "Edge case prediction should not return nil")
                    
                case .failure(let error):
                    // It's acceptable to have failures for extreme inputs
                    print("Edge case prediction error: \(error)")
                }
                
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 10.0)
    }
    
    /// Performance test for large dataset processing
    func testLargeDatasetPerformance() {
        measure {
            let largeDataset = MockHealthDataGenerator.generateStressTestDataset(scenarioCount: 100)
            
            let expectation = XCTestExpectation(description: "Large Dataset Performance")
            expectation.expectedFulfillmentCount = largeDataset.count
            
            largeDataset.forEach { input in
                predictor.predictPreSymptomHealthRisks(input: input) { _ in
                    expectation.fulfill()
                }
            }
            
            wait(for: [expectation], timeout: 10.0)
        }
    }
} 
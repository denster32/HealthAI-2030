import XCTest
import Combine
@testable import MentalHealth

@available(iOS 17.0, macOS 14.0, watchOS 10.0, tvOS 17.0, *)
final class MoodEnergyForecastingTests: XCTestCase {
    var forecastingEngine: MoodEnergyForecastingEngine!
    var cancellables: Set<AnyCancellable> = []
    
    override func setUp() {
        super.setUp()
        forecastingEngine = .shared
    }
    
    override func tearDown() {
        cancellables.removeAll()
        super.tearDown()
    }
    
    /// Test prediction output validation
    func testPredictionOutputValidation() {
        let expectation = XCTestExpectation(description: "Receive mood and energy prediction")
        
        forecastingEngine.subscribeToPredictions()
            .sink { prediction in
                // Validate mood score
                XCTAssertGreaterThanOrEqual(prediction.moodScore, 0.0, "Mood score should be at least 0.0")
                XCTAssertLessThanOrEqual(prediction.moodScore, 1.0, "Mood score should be at most 1.0")
                
                // Validate energy score
                XCTAssertGreaterThanOrEqual(prediction.energyScore, 0.0, "Energy score should be at least 0.0")
                XCTAssertLessThanOrEqual(prediction.energyScore, 1.0, "Energy score should be at most 1.0")
                
                // Validate confidence interval
                XCTAssertGreaterThanOrEqual(prediction.confidenceInterval, 0.0, "Confidence interval should be at least 0.0")
                XCTAssertLessThanOrEqual(prediction.confidenceInterval, 1.0, "Confidence interval should be at most 1.0")
                
                // Validate contributing factors
                XCTAssertFalse(prediction.contributingFactors.isEmpty, "Contributing factors should not be empty")
                
                // Validate recommended interventions
                XCTAssertFalse(prediction.recommendedInterventions.isEmpty, "Recommended interventions should not be empty")
                
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // Trigger prediction
        forecastingEngine.predictMoodAndEnergy()
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    /// Test sensitivity analysis
    func testSensitivityAnalysis() {
        let expectation = XCTestExpectation(description: "Receive sensitivity analysis")
        
        // Create a base input for sensitivity analysis
        let baseInput = MoodEnergyPredictionInput(
            heartRateVariability: 50.0,
            sleepQuality: 0.7,
            physicalActivity: 0.6,
            nutritionalIntake: 0.5,
            socialInteractions: 0.4,
            stressLevel: 0.3,
            screenTime: 0.2
        )
        
        forecastingEngine.subscribeToSensitivityAnalysis()
            .sink { sensitivityFactors in
                // Validate sensitivity factors
                XCTAssertFalse(sensitivityFactors.isEmpty, "Sensitivity factors should not be empty")
                
                // Check specific sensitivity factors
                XCTAssertTrue(sensitivityFactors.keys.contains("heartRateVariability"), "Should have heart rate variability sensitivity")
                XCTAssertTrue(sensitivityFactors.keys.contains("sleepQuality"), "Should have sleep quality sensitivity")
                XCTAssertTrue(sensitivityFactors.keys.contains("physicalActivity"), "Should have physical activity sensitivity")
                
                // Validate sensitivity values
                for (_, sensitivity) in sensitivityFactors {
                    XCTAssertGreaterThanOrEqual(sensitivity, 0.0, "Sensitivity should be at least 0.0")
                    XCTAssertLessThanOrEqual(sensitivity, 1.0, "Sensitivity should be at most 1.0")
                }
                
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // Trigger sensitivity analysis
        let _ = forecastingEngine.analyzeSensitivity(baseInput: baseInput)
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    /// Test intervention generation for different mood and energy scenarios
    func testInterventionGeneration() {
        // Test low mood and low energy
        let lowMoodLowEnergyInput = MoodEnergyPredictionInput(
            heartRateVariability: 30.0,
            sleepQuality: 0.2,
            physicalActivity: 0.1,
            nutritionalIntake: 0.3,
            socialInteractions: 0.2,
            stressLevel: 0.8,
            screenTime: 0.9
        )
        
        // Trigger prediction
        forecastingEngine.predictMoodAndEnergy(input: lowMoodLowEnergyInput)
        
        // Test high mood and high energy
        let highMoodHighEnergyInput = MoodEnergyPredictionInput(
            heartRateVariability: 80.0,
            sleepQuality: 0.9,
            physicalActivity: 0.8,
            nutritionalIntake: 0.7,
            socialInteractions: 0.9,
            stressLevel: 0.2,
            screenTime: 0.1
        )
        
        // Trigger prediction
        forecastingEngine.predictMoodAndEnergy(input: highMoodHighEnergyInput)
        
        // Add expectations to verify different intervention scenarios
        let expectation = XCTestExpectation(description: "Verify intervention generation")
        
        forecastingEngine.subscribeToPredictions()
            .sink { prediction in
                // Verify interventions for different scenarios
                if prediction.moodScore < 0.4 {
                    XCTAssertTrue(prediction.recommendedInterventions.contains { $0.contains("mindfulness") || $0.contains("support") }, 
                                  "Low mood should trigger supportive interventions")
                }
                
                if prediction.energyScore < 0.3 {
                    XCTAssertTrue(prediction.recommendedInterventions.contains { $0.contains("exercise") || $0.contains("sleep") }, 
                                  "Low energy should trigger activation interventions")
                }
                
                if prediction.moodScore > 0.7 && prediction.energyScore > 0.7 {
                    XCTAssertTrue(prediction.recommendedInterventions.contains { $0.contains("challenging tasks") }, 
                                  "High mood and energy should suggest challenging tasks")
                }
                
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    /// Test edge case handling with empty or minimal input
    func testEdgeCaseHandling() {
        // Create an input with minimal or zero values
        let emptyInput = MoodEnergyPredictionInput(
            heartRateVariability: 0.0,
            sleepQuality: 0.0,
            physicalActivity: 0.0,
            nutritionalIntake: 0.0,
            socialInteractions: 0.0,
            stressLevel: 0.0,
            screenTime: 0.0
        )
        
        let expectation = XCTestExpectation(description: "Handle edge case input")
        
        forecastingEngine.subscribeToPredictions()
            .sink { prediction in
                // Verify default/fallback behavior
                XCTAssertGreaterThanOrEqual(prediction.moodScore, 0.0, "Mood score should have a default value")
                XCTAssertLessThanOrEqual(prediction.moodScore, 1.0, "Mood score should be within valid range")
                
                XCTAssertGreaterThanOrEqual(prediction.energyScore, 0.0, "Energy score should have a default value")
                XCTAssertLessThanOrEqual(prediction.energyScore, 1.0, "Energy score should be within valid range")
                
                XCTAssertFalse(prediction.recommendedInterventions.isEmpty, "Should provide interventions even for edge cases")
                
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // Trigger prediction with empty input
        forecastingEngine.predictMoodAndEnergy(input: emptyInput)
        
        wait(for: [expectation], timeout: 5.0)
    }
} 
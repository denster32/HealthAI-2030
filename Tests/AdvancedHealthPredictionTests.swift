import XCTest
import Combine
@testable import HealthAI2030

@available(iOS 18.0, macOS 15.0, *)
final class AdvancedHealthPredictionTests: XCTestCase {
    var engine: AdvancedHealthPredictionEngine!
    var analyticsEngine: MockAnalyticsEngine!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        analyticsEngine = MockAnalyticsEngine()
        engine = AdvancedHealthPredictionEngine(analyticsEngine: analyticsEngine)
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDown() {
        engine = nil
        analyticsEngine = nil
        cancellables = nil
        super.tearDown()
    }
    
    func testGeneratePredictionsSuccess() async throws {
        let prediction = try await engine.generatePredictions()
        XCTAssertNotNil(prediction.cardiovascular)
        XCTAssertNotNil(prediction.sleep)
        XCTAssertNotNil(prediction.stress)
        XCTAssertNotNil(prediction.trajectory)
        XCTAssertFalse(engine.isProcessing)
        XCTAssertNil(engine.lastError)
    }
    
    func testCardiovascularRiskPrediction() async throws {
        let features = HealthFeatures(averageHeartRate: 70, averageHRV: 50, averageSystolicBP: 120, averageDiastolicBP: 80, age: 40, gender: .male, activityLevel: 0.7, stressLevel: 0.2)
        let prediction = try await engine.predictCardiovascularRisk(features: features)
        XCTAssertGreaterThanOrEqual(prediction.riskScore, 0.0)
        XCTAssertLessThanOrEqual(prediction.riskScore, 1.0)
    }
    
    func testSleepQualityForecast() async throws {
        let features = HealthFeatures(averageSleepDuration: 7.5, sleepEfficiency: 0.9, deepSleepPercentage: 0.2, remSleepPercentage: 0.2, activityLevel: 0.6, stressLevel: 0.1, caffeineIntake: 0.0, screenTime: 1.0)
        let prediction = try await engine.predictSleepQuality(features: features)
        XCTAssertGreaterThanOrEqual(prediction.qualityScore, 0.0)
        XCTAssertLessThanOrEqual(prediction.qualityScore, 1.0)
    }
    
    func testStressPatternPrediction() async throws {
        let features = HealthFeatures(averageHRV: 45, heartRate: 75, activityLevel: 0.5, sleepQuality: 0.8, calendarEvents: ["meeting"], locationData: ["office"], voiceTone: 0.5)
        let prediction = try await engine.predictStressPattern(features: features)
        XCTAssertGreaterThanOrEqual(prediction.stressLevel, 0.0)
        XCTAssertLessThanOrEqual(prediction.stressLevel, 1.0)
    }
    
    func testHealthTrajectoryPrediction() async throws {
        let features = HealthFeatures(healthScore: 0.7, healthTrend: [0.6, 0.7, 0.8], lifestyleFactors: ["exercise"], medicalHistory: ["hypertension"], geneticFactors: ["APOE4"])
        let prediction = try await engine.predictHealthTrajectory(features: features)
        XCTAssertGreaterThanOrEqual(prediction.confidence, 0.0)
        XCTAssertLessThanOrEqual(prediction.confidence, 1.0)
    }
    
    func testErrorHandlingModelNotLoaded() async {
        // Simulate model not loaded by setting models to nil
        engine.cardiovascularModel = nil
        do {
            let features = HealthFeatures()
            _ = try await engine.predictCardiovascularRisk(features: features)
            XCTFail("Should throw modelNotLoaded error")
        } catch let error as PredictionError {
            XCTAssertEqual(error, .modelNotLoaded)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testIsProcessingFlag() async throws {
        let expectation = XCTestExpectation(description: "isProcessing flag updates")
        engine.$isProcessing
            .dropFirst()
            .sink { isProcessing in
                XCTAssertFalse(isProcessing)
                expectation.fulfill()
            }
            .store(in: &cancellables)
        _ = try await engine.generatePredictions()
        wait(for: [expectation], timeout: 2.0)
    }
    
    func testAnalyticsEventTracking() async throws {
        _ = try await engine.generatePredictions()
        XCTAssertTrue(analyticsEngine.trackedEvents.contains("health_predictions_generated"))
    }
}

// MARK: - Mock Analytics Engine
class MockAnalyticsEngine: AnalyticsEngine {
    var trackedEvents: [String] = []
    override func trackEvent(_ event: String, properties: [String : Any]? = nil) {
        trackedEvents.append(event)
    }
} 
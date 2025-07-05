import XCTest
@testable import HealthAI_2030

class SleepStageTransformerTests: XCTestCase {

    var transformer: SleepStageTransformer!

    override func setUp() {
        super.setUp()
        transformer = SleepStageTransformer()
    }

    override func tearDown() {
        transformer = nil
        super.tearDown()
    }

    func testPredictSleepStage_emptyFeatures() {
        let features: [Double] = []
        let prediction = transformer.predictSleepStage(features: features)
        XCTAssertEqual(prediction, "Unknown", "Prediction for empty features should be 'Unknown'")
    }

    func testPredictSleepStage_lowFeatures() {
        let features: [Double] = [1.0, 0.5, 2.0]
        let prediction = transformer.predictSleepStage(features: features)
        XCTAssertEqual(prediction, "Wake", "Prediction for low sum features should be 'Wake'")
    }

    func testPredictSleepStage_mediumFeatures() {
        let features: [Double] = [2.0, 3.0, 1.5, 0.5] // Sum = 7.0
        let prediction = transformer.predictSleepStage(features: features)
        XCTAssertEqual(prediction, "N2", "Prediction for medium sum features should be 'N2'")
    }

    func testPredictSleepStage_highFeatures() {
        let features: [Double] = [5.0, 4.0, 3.0, 2.0] // Sum = 14.0
        let prediction = transformer.predictSleepStage(features: features)
        XCTAssertEqual(prediction, "REM", "Prediction for high sum features should be 'REM'")
    }
    
    func testPredictSleepStage_paddedFeatures() {
        let features: [Double] = [1.0, 2.0] // Less than 7 features, should be padded
        let prediction = transformer.predictSleepStage(features: features)
        // The simulated model logic in SleepStageTransformer only checks the sum,
        // so padding won't change the outcome for this specific test, but it verifies
        // the feature extractor's output compatibility.
        XCTAssertEqual(prediction, "Wake", "Prediction for padded features should be 'Wake'")
    }
}
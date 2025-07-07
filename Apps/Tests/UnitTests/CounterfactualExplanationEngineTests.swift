import XCTest
@testable import HealthAI2030App

final class CounterfactualExplanationEngineTests: XCTestCase {

    func testExplainWhatIfReturnsValue() {
        let engine = CounterfactualExplanationEngine()
        let original = ["x": 1.0]
        let modified = ["x": 2.0]
        let result = engine.explainWhatIf(originalFeatures: original, modifiedFeatures: modified)
        XCTAssertEqual(result, 0.0) // Stub returns placeholder
    }
} 
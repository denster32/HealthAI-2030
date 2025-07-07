import XCTest
@testable import HealthAI2030App

final class LocalExplanationManagerTests: XCTestCase {

    func testExplainLocallyReturnsMap() {
        let manager = LocalExplanationManager()
        let dataPoint = ["f1": 0.5, "f2": 0.8]
        let explanations = manager.explainLocally(dataPoint: dataPoint)
        XCTAssertEqual(explanations.keys.count, dataPoint.keys.count)
        for value in explanations.values {
            XCTAssertEqual(value, 0.0)
        }
    }
} 
import XCTest
@testable import HealthAI2030App

final class ExplanationViewManagerTests: XCTestCase {

    func testComputeFeatureImportances() {
        let manager = ExplanationViewManager()
        let features = ["featureA": 0.2, "featureB": 0.8]
        let importances = manager.computeFeatureImportances(features: features, prediction: 0.5)
        XCTAssertEqual(importances.keys.count, features.keys.count)
        for score in importances.values {
            XCTAssertGreaterThan(score, 0.0)
        }
    }
} 
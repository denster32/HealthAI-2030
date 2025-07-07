import XCTest
@testable import HealthAI2030App

final class DynamicModelSelectorTests: XCTestCase {

    func testSelectModelDefault() {
        let modelName = DynamicModelSelector.selectModelName()
        XCTAssertTrue(modelName == "default_model" || modelName == "lightweight_model")
    }
} 
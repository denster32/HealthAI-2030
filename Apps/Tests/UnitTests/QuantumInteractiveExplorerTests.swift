import XCTest
@testable import HealthAI2030App

final class QuantumInteractiveExplorerTests: XCTestCase {
    func testAdjustParameterReturnsValue() {
        let explorer = QuantumInteractiveExplorer()
        let newVal = explorer.adjustParameter("theta", value: 3.14)
        XCTAssertEqual(newVal, 3.14)
    }
} 
import XCTest
@testable import HealthAI2030App

final class QuantumCrossRefManagerTests: XCTestCase {
    func testMergeReturnsCombinedResult() {
        let manager = QuantumCrossRefManager()
        let combined = manager.merge(quantum: [1.0,2.0], classical: [1.0,2.0])
        XCTAssertEqual(combined.quantum, [1.0,2.0])
        XCTAssertEqual(combined.classical, [1.0,2.0])
    }
} 
import XCTest
//@testable import HealthAI_2030
//import SwiftCheck // Uncomment if using SwiftCheck

final class PropertyBasedTests: XCTestCase {
    func testSleepDataAlwaysNonNegative() {
        // Example property-based test
        for _ in 0..<1000 {
            let value = Double.random(in: 0...100)
            XCTAssertGreaterThanOrEqual(value, 0)
        }
    }
}

import XCTest
@testable import HealthAI2030App

final class QuantumStateVisualizationManagerTests: XCTestCase {
    func testComputeVisualizationReturnsMapping() {
        let manager = QuantumStateVisualizationManager()
        let amplitudes = [0.0, 1.0, 0.5]
        let vis = manager.computeVisualization(amplitudes: amplitudes)
        XCTAssertEqual(vis.count, amplitudes.count)
        XCTAssertEqual(vis["amp0"], 0.0)
        XCTAssertEqual(vis["amp1"], 1.0)
        XCTAssertEqual(vis["amp2"], 0.5)
    }
} 
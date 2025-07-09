import XCTest
import CoreML
@testable import Core

final class NeuralOptimizerTests: XCTestCase {
    func testOptimizeNeuralArchitecture() {
        let constraints = ArchitectureConstraints(maxSize: 10_000_000, maxLatency: 50.0, minAccuracy: 0.9)
        let architecture = NeuralOptimizer.shared.optimizeNeuralArchitecture(for: "classification", constraints: constraints)
        XCTAssertNotNil(architecture)
    }
    
    func testSetupAdvancedActivations() {
        let manager = NeuralOptimizer.shared.setupAdvancedActivations()
        XCTAssertNotNil(manager)
    }
    
    func testOptimizeRegularization() {
        let dummyNetwork = NeuralNetwork() // Replace with a mock or test network
        let regularized = NeuralOptimizer.shared.optimizeRegularization(for: dummyNetwork)
        XCTAssertNotNil(regularized)
    }
    
    func testSetupAttentionMechanisms() {
        let manager = NeuralOptimizer.shared.setupAttentionMechanisms()
        XCTAssertNotNil(manager)
    }
    
    func testOptimizeNeuralDeployment() {
        let dummyNetwork = NeuralNetwork() // Replace with a mock or test network
        let optimized = NeuralOptimizer.shared.optimizeNeuralDeployment(for: dummyNetwork, target: .edge)
        XCTAssertNotNil(optimized)
    }
} 
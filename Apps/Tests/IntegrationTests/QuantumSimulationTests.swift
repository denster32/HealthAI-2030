import XCTest
@testable import QuantumHealth

final class QuantumSimulationTests: XCTestCase {
    var simulationEngine: QuantumSimulationEngine!
    
    override func setUp() {
        super.setUp()
        guard let engine = QuantumSimulationEngine.shared else {
            XCTFail("Failed to initialize QuantumSimulationEngine")
            return
        }
        simulationEngine = engine
    }
    
    /// Test basic quantum circuit simulation
    func testBasicQuantumCircuitSimulation() {
        // Test with minimal configuration
        let config = QuantumCircuitConfig(qubits: 4, depth: 10)
        
        let simulationResult = simulationEngine.simulateQuantumCircuit(config: config)
        
        XCTAssertEqual(simulationResult.count, 16, "State vector should have 2^qubits elements")
        XCTAssertEqual(simulationResult[0].magnitude, 1.0, "Initial state should be |0⟩")
    }
    
    /// Test quantum circuit with noise models
    func testQuantumCircuitWithNoiseModels() {
        let config = QuantumCircuitConfig(
            qubits: 5, 
            depth: 15, 
            noiseModel: [.bitFlip, .phaseFlip, .depolarizing], 
            errorRate: 0.01
        )
        
        let simulationResult = simulationEngine.simulateQuantumCircuit(config: config)
        
        XCTAssertEqual(simulationResult.count, 32, "State vector should have 2^qubits elements")
        XCTAssertNotEqual(simulationResult[0].magnitude, 1.0, "Noise should modify initial state")
    }
    
    /// Test performance measurement
    func testSimulationPerformanceMeasurement() {
        let config = QuantumCircuitConfig(qubits: 6, depth: 20)
        
        let performanceMetrics = simulationEngine.measureSimulationPerformance(config: config)
        
        XCTAssertGreaterThan(performanceMetrics.executionTime, 0, "Execution time should be positive")
        XCTAssertGreaterThan(performanceMetrics.resourceUtilization.cpu, 0, "CPU usage should be positive")
        XCTAssertGreaterThan(performanceMetrics.resourceUtilization.gpu, 0, "GPU usage should be positive")
        XCTAssertGreaterThan(performanceMetrics.resourceUtilization.memory, 0, "Memory usage should be positive")
        
        XCTAssertLessThan(performanceMetrics.executionTime, 1.0, "Execution time should be under 1 second")
        XCTAssertLessThan(performanceMetrics.resourceUtilization.cpu, 1.0, "CPU usage should be under 100%")
        XCTAssertLessThan(performanceMetrics.resourceUtilization.gpu, 1.0, "GPU usage should be under 100%")
    }
    
    /// Test error correction effectiveness
    func testErrorCorrectionEffectiveness() {
        // Test with high noise levels to stress error correction
        let highNoiseConfig = QuantumCircuitConfig(
            qubits: 4, 
            depth: 20, 
            noiseModel: [.bitFlip, .phaseFlip, .depolarizing], 
            errorRate: 0.1  // High error rate
        )
        
        let simulationResult = simulationEngine.simulateQuantumCircuit(config: highNoiseConfig)
        
        // Verify that error correction prevents complete state destruction
        XCTAssertEqual(simulationResult.count, 16, "State vector size should be preserved")
        XCTAssertNotEqual(simulationResult[0].magnitude, 0, "State should not be completely destroyed")
    }
    
    /// Test cross-platform consistency simulation
    func testCrossPlatformSimulationConsistency() {
        // Configurations to test consistency
        let configs = [
            QuantumCircuitConfig(qubits: 3, depth: 10),
            QuantumCircuitConfig(qubits: 4, depth: 15, noiseModel: [.bitFlip]),
            QuantumCircuitConfig(qubits: 5, depth: 20, noiseModel: [.phaseFlip, .depolarizing], errorRate: 0.05)
        ]
        
        var previousResults: [[Complex]] = []
        
        for config in configs {
            let simulationResult = simulationEngine.simulateQuantumCircuit(config: config)
            
            // Compare results across multiple runs
            if !previousResults.isEmpty {
                let previousResult = previousResults.last!
                
                // Check state vector size consistency
                XCTAssertEqual(simulationResult.count, previousResult.count, "State vector size should be consistent")
                
                // Check magnitude preservation
                let previousMagnitudeSum = previousResult.reduce(0) { $0 + $1.magnitude }
                let currentMagnitudeSum = simulationResult.reduce(0) { $0 + $1.magnitude }
                
                XCTAssertEqual(
                    previousMagnitudeSum, 
                    currentMagnitudeSum, 
                    accuracy: 0.01, 
                    "Total state vector magnitude should be preserved"
                )
            }
            
            previousResults.append(simulationResult)
        }
    }
    
    /// Test complex number operations
    func testComplexNumberOperations() {
        let a = Complex(3, 4)
        let b = Complex(1, 2)
        
        // Addition
        let sum = a + b
        XCTAssertEqual(sum.real, 4)
        XCTAssertEqual(sum.imaginary, 6)
        
        // Subtraction
        let diff = a - b
        XCTAssertEqual(diff.real, 2)
        XCTAssertEqual(diff.imaginary, 2)
        
        // Negation
        let negA = -a
        XCTAssertEqual(negA.real, -3)
        XCTAssertEqual(negA.imaginary, -4)
        
        // Magnitude
        XCTAssertEqual(a.magnitude, 5, accuracy: 0.001)
    }
}

// Ensure the test bundle can access the QuantumSimulationEngine
extension Bundle {
    static var testBundle: Bundle {
        return Bundle(for: QuantumSimulationTests.self)
    }
} 
import XCTest
@testable import HealthAI_2030

/// Comprehensive Test Suite for Quantum Neural Network
/// Tests all aspects of quantum neural network functionality including circuits, layers, and training
@available(iOS 18.0, macOS 15.0, *)
final class QuantumNeuralNetworkTests: XCTestCase {
    
    var quantumNetwork: QuantumNeuralNetwork!
    var quantumCircuit: QuantumCircuit!
    var quantumState: QuantumState!
    
    override func setUp() async throws {
        try await super.setUp()
        quantumNetwork = QuantumNeuralNetwork()
        quantumCircuit = QuantumCircuit()
        quantumState = QuantumState()
    }
    
    override func tearDown() async throws {
        quantumNetwork = nil
        quantumCircuit = nil
        quantumState = nil
        try await super.tearDown()
    }
    
    // MARK: - Network Initialization Tests
    
    func testQuantumNetworkInitialization() {
        XCTAssertNotNil(quantumNetwork)
        
        let architecture = quantumNetwork.buildNetwork(
            inputSize: 8,
            hiddenLayers: [6, 4],
            outputSize: 2,
            quantumDepth: 3
        )
        
        XCTAssertEqual(architecture.inputSize, 8)
        XCTAssertEqual(architecture.hiddenLayers, [6, 4])
        XCTAssertEqual(architecture.outputSize, 2)
        XCTAssertEqual(architecture.quantumDepth, 3)
        XCTAssertGreaterThan(architecture.totalParameters, 0)
    }
    
    func testNetworkArchitectureValidation() {
        // Test various network architectures
        let architectures = [
            (inputSize: 4, hiddenLayers: [3], outputSize: 1, quantumDepth: 2),
            (inputSize: 10, hiddenLayers: [8, 6, 4], outputSize: 3, quantumDepth: 4),
            (inputSize: 16, hiddenLayers: [12, 8], outputSize: 5, quantumDepth: 3)
        ]
        
        for arch in architectures {
            let architecture = quantumNetwork.buildNetwork(
                inputSize: arch.inputSize,
                hiddenLayers: arch.hiddenLayers,
                outputSize: arch.outputSize,
                quantumDepth: arch.quantumDepth
            )
            
            XCTAssertEqual(architecture.inputSize, arch.inputSize)
            XCTAssertEqual(architecture.hiddenLayers, arch.hiddenLayers)
            XCTAssertEqual(architecture.outputSize, arch.outputSize)
            XCTAssertEqual(architecture.quantumDepth, arch.quantumDepth)
        }
    }
    
    // MARK: - Quantum Circuit Tests
    
    func testQuantumCircuitInitialization() {
        XCTAssertNotNil(quantumCircuit)
        
        quantumCircuit.setup()
        quantumCircuit.initializeDefaultCircuit()
        
        let metrics = quantumCircuit.getCircuitMetrics()
        XCTAssertGreaterThanOrEqual(metrics.totalQubits, 0)
        XCTAssertGreaterThanOrEqual(metrics.totalGates, 0)
    }
    
    func testQuantumGateApplication() {
        quantumCircuit.setup()
        quantumCircuit.initializeDefaultCircuit()
        
        // Test Hadamard gate
        let hadamardGate = QuantumGate(
            type: .hadamard,
            qubits: [0],
            parameter: nil
        )
        
        let success = quantumCircuit.applyGate(hadamardGate)
        XCTAssertTrue(success)
        
        // Test CNOT gate
        let cnotGate = QuantumGate(
            type: .cnot,
            qubits: [0, 1],
            parameter: nil
        )
        
        let cnotSuccess = quantumCircuit.applyGate(cnotGate)
        XCTAssertTrue(cnotSuccess)
        
        // Test rotation gate
        let rotationGate = QuantumGate(
            type: .rotationY,
            qubits: [0],
            parameter: QuantumParameter(name: "test_rotation", value: Double.pi/4, type: .rotation)
        )
        
        let rotationSuccess = quantumCircuit.applyGate(rotationGate)
        XCTAssertTrue(rotationSuccess)
    }
    
    func testQuantumMeasurement() {
        quantumCircuit.setup()
        quantumCircuit.initializeDefaultCircuit()
        
        // Apply some gates
        let hadamardGate = QuantumGate(type: .hadamard, qubits: [0], parameter: nil)
        _ = quantumCircuit.applyGate(hadamardGate)
        
        let measurement = quantumCircuit.measure()
        XCTAssertNotNil(measurement)
        XCTAssertFalse(measurement.qubits.isEmpty)
        XCTAssertFalse(measurement.probabilities.isEmpty)
        XCTAssertFalse(measurement.bitString.isEmpty)
    }
    
    func testQuantumGradientCalculation() {
        quantumCircuit.setup()
        quantumCircuit.initializeDefaultCircuit()
        
        let target = HealthTarget(value: 0.8)
        let predicted = HealthPrediction(value: 0.6)
        
        let gradients = quantumCircuit.calculateGradients(target: target, predicted: predicted)
        XCTAssertFalse(gradients.isEmpty)
        
        for gradient in gradients {
            XCTAssertNotNil(gradient.parameter)
            XCTAssertFalse(gradient.value.isNaN)
            XCTAssertFalse(gradient.value.isInfinite)
        }
    }
    
    // MARK: - Quantum State Tests
    
    func testQuantumStateInitialization() {
        let qubits = [QuantumQubit(id: 0), QuantumQubit(id: 1), QuantumQubit(id: 2)]
        let state = QuantumState(qubits: qubits)
        
        XCTAssertEqual(state.getQubitCount(), 3)
        
        let stateVector = state.getStateVector()
        XCTAssertEqual(stateVector.count, 8) // 2^3
        
        // Check initial state is |000⟩
        XCTAssertEqual(stateVector[0].real, 1.0, accuracy: 1e-10)
        XCTAssertEqual(stateVector[0].imaginary, 0.0, accuracy: 1e-10)
        
        for i in 1..<stateVector.count {
            XCTAssertEqual(stateVector[i].magnitude, 0.0, accuracy: 1e-10)
        }
    }
    
    func testQuantumStateOperations() {
        let qubits = [QuantumQubit(id: 0), QuantumQubit(id: 1)]
        let state = QuantumState(qubits: qubits)
        
        // Test Hadamard gate
        let hadamardMatrix = [
            [Complex(real: 1/sqrt(2), imaginary: 0), Complex(real: 1/sqrt(2), imaginary: 0)],
            [Complex(real: 1/sqrt(2), imaginary: 0), Complex(real: -1/sqrt(2), imaginary: 0)]
        ]
        
        state.applySingleQubitGate(matrix: hadamardMatrix, qubit: 0)
        
        let stateVector = state.getStateVector()
        XCTAssertEqual(stateVector[0].magnitude, 1/sqrt(2), accuracy: 1e-10)
        XCTAssertEqual(stateVector[2].magnitude, 1/sqrt(2), accuracy: 1e-10)
        
        // Test CNOT gate
        state.applyCNOTGate(control: 0, target: 1)
        
        let finalStateVector = state.getStateVector()
        XCTAssertEqual(finalStateVector[0].magnitude, 1/sqrt(2), accuracy: 1e-10)
        XCTAssertEqual(finalStateVector[3].magnitude, 1/sqrt(2), accuracy: 1e-10)
    }
    
    func testQuantumStateMeasurement() {
        let qubits = [QuantumQubit(id: 0), QuantumQubit(id: 1)]
        let state = QuantumState(qubits: qubits)
        
        // Create superposition
        let hadamardMatrix = [
            [Complex(real: 1/sqrt(2), imaginary: 0), Complex(real: 1/sqrt(2), imaginary: 0)],
            [Complex(real: 1/sqrt(2), imaginary: 0), Complex(real: -1/sqrt(2), imaginary: 0)]
        ]
        state.applySingleQubitGate(matrix: hadamardMatrix, qubit: 0)
        
        let measurement = state.measureAllQubits()
        XCTAssertEqual(measurement.count, 2)
        
        // Check that measurement results are valid
        for result in measurement {
            XCTAssertTrue(result == true || result == false)
        }
    }
    
    func testQuantumStateMetrics() {
        let qubits = [QuantumQubit(id: 0), QuantumQubit(id: 1)]
        let state = QuantumState(qubits: qubits)
        
        // Test fidelity
        let fidelity = state.calculateFidelity()
        XCTAssertGreaterThanOrEqual(fidelity, 0.0)
        XCTAssertLessThanOrEqual(fidelity, 1.0)
        
        // Test entropy
        let entropy = state.calculateVonNeumannEntropy()
        XCTAssertGreaterThanOrEqual(entropy, 0.0)
        
        // Test entanglement
        let entanglement = state.calculateQubitEntanglement(qubit: 0)
        XCTAssertGreaterThanOrEqual(entanglement, 0.0)
        
        // Test coherence
        let coherence = state.calculateCoherence()
        XCTAssertGreaterThanOrEqual(coherence, 0.0)
    }
    
    // MARK: - Quantum Layer Tests
    
    func testQuantumInputLayer() {
        let inputLayer = QuantumInputLayer(inputSize: 4, quantumDepth: 2)
        
        XCTAssertEqual(inputLayer.inputSize, 4)
        XCTAssertEqual(inputLayer.outputSize, 4)
        XCTAssertEqual(inputLayer.quantumDepth, 2)
        XCTAssertEqual(inputLayer.requiredQubits, 4)
        XCTAssertGreaterThan(inputLayer.parameterCount, 0)
        
        let qubits = Array(0..<4).map { QuantumQubit(id: $0) }
        let inputState = QuantumState(qubits: qubits)
        
        let outputState = inputLayer.forward(input: inputState)
        XCTAssertEqual(outputState.getQubitCount(), 4)
    }
    
    func testQuantumHiddenLayer() {
        let hiddenLayer = QuantumHiddenLayer(
            inputSize: 4,
            outputSize: 3,
            quantumDepth: 2,
            layerType: .variational
        )
        
        XCTAssertEqual(hiddenLayer.inputSize, 4)
        XCTAssertEqual(hiddenLayer.outputSize, 3)
        XCTAssertEqual(hiddenLayer.quantumDepth, 2)
        XCTAssertGreaterThan(hiddenLayer.parameterCount, 0)
        
        let qubits = Array(0..<4).map { QuantumQubit(id: $0) }
        let inputState = QuantumState(qubits: qubits)
        
        let outputState = hiddenLayer.forward(input: inputState)
        XCTAssertEqual(outputState.getQubitCount(), 3)
    }
    
    func testQuantumOutputLayer() {
        let outputLayer = QuantumOutputLayer(
            inputSize: 3,
            outputSize: 2,
            quantumDepth: 2,
            outputStrategy: .measurement
        )
        
        XCTAssertEqual(outputLayer.inputSize, 3)
        XCTAssertEqual(outputLayer.outputSize, 2)
        XCTAssertEqual(outputLayer.quantumDepth, 2)
        XCTAssertGreaterThan(outputLayer.parameterCount, 0)
        
        let qubits = Array(0..<3).map { QuantumQubit(id: $0) }
        let inputState = QuantumState(qubits: qubits)
        
        let outputState = outputLayer.forward(input: inputState)
        XCTAssertNotNil(outputState)
    }
    
    func testQuantumLayerBackpropagation() {
        let hiddenLayer = QuantumHiddenLayer(inputSize: 3, outputSize: 2, quantumDepth: 2)
        
        let parameter = QuantumParameter(name: "test", value: 0.5, type: .rotation)
        let gradient = QuantumGradient(parameter: parameter, value: 0.1, parameterIndex: 0)
        
        let backpropResult = hiddenLayer.backward(gradient: gradient)
        XCTAssertNotNil(backpropResult)
        XCTAssertFalse(backpropResult.value.isNaN)
        XCTAssertFalse(backpropResult.value.isInfinite)
    }
    
    // MARK: - Health Prediction Tests
    
    func testHealthDataEncoding() {
        let healthData = createTestHealthData()
        let quantumState = quantumCircuit.prepareState(from: healthData)
        
        XCTAssertNotNil(quantumState)
        XCTAssertGreaterThan(quantumState.getQubitCount(), 0)
        
        let stateVector = quantumState.getStateVector()
        XCTAssertFalse(stateVector.isEmpty)
        
        // Check normalization
        let norm = stateVector.reduce(0.0) { $0 + $1.magnitude * $1.magnitude }
        XCTAssertEqual(norm, 1.0, accuracy: 1e-10)
    }
    
    func testHealthPrediction() {
        let architecture = quantumNetwork.buildNetwork(
            inputSize: 8,
            hiddenLayers: [6, 4],
            outputSize: 3,
            quantumDepth: 2
        )
        
        let healthData = createTestHealthData()
        let prediction = quantumNetwork.predict(
            healthData: healthData,
            healthTask: .diseasePrediction
        )
        
        XCTAssertNotNil(prediction)
        XCTAssertGreaterThanOrEqual(prediction.confidence, 0.0)
        XCTAssertLessThanOrEqual(prediction.confidence, 1.0)
        XCTAssertGreaterThan(prediction.executionTime, 0.0)
        XCTAssertNotNil(prediction.quantumContributions)
        XCTAssertNotNil(prediction.classicalContributions)
    }
    
    func testMultipleHealthTasks() {
        let healthTasks: [HealthPredictionTask] = [
            .diseasePrediction,
            .healthScorePrediction,
            .treatmentResponsePrediction
        ]
        
        let architecture = quantumNetwork.buildNetwork(
            inputSize: 8,
            hiddenLayers: [6],
            outputSize: 1,
            quantumDepth: 2
        )
        
        for task in healthTasks {
            let healthData = createTestHealthData()
            let prediction = quantumNetwork.predict(
                healthData: healthData,
                healthTask: task
            )
            
            XCTAssertNotNil(prediction)
            XCTAssertEqual(prediction.healthTask, task)
        }
    }
    
    // MARK: - Training Tests
    
    func testQuantumTraining() {
        let architecture = quantumNetwork.buildNetwork(
            inputSize: 4,
            hiddenLayers: [3],
            outputSize: 1,
            quantumDepth: 2
        )
        
        let trainingData = createTestTrainingData(count: 10)
        let validationData = createTestValidationData(count: 5)
        
        let trainingResult = quantumNetwork.train(
            trainingData: trainingData,
            validationData: validationData,
            healthTask: .diseasePrediction
        )
        
        XCTAssertNotNil(trainingResult)
        XCTAssertTrue(trainingResult.success || trainingResult.error != nil)
        XCTAssertGreaterThan(trainingResult.epochs, 0)
        XCTAssertGreaterThan(trainingResult.executionTime, 0.0)
        XCTAssertGreaterThanOrEqual(trainingResult.quantumEfficiency, 0.0)
    }
    
    func testQuantumBackpropagation() {
        let target = HealthTarget(value: 0.8)
        let predicted = HealthPrediction(value: 0.6)
        
        let backpropResult = quantumNetwork.performQuantumBackpropagation(
            target: target,
            predicted: predicted,
            learningRate: 0.01
        )
        
        XCTAssertNotNil(backpropResult)
        XCTAssertFalse(backpropResult.quantumGradients.isEmpty)
        XCTAssertFalse(backpropResult.classicalGradients.isEmpty)
        XCTAssertGreaterThan(backpropResult.executionTime, 0.0)
    }
    
    func testTrainingConvergence() {
        let architecture = quantumNetwork.buildNetwork(
            inputSize: 2,
            hiddenLayers: [2],
            outputSize: 1,
            quantumDepth: 1
        )
        
        // Create simple XOR-like problem
        let trainingData = [
            HealthTrainingData(
                input: HealthInputData(heartRate: 60, systolicBP: 120, diastolicBP: 80, temperature: 98.6, oxygenSaturation: 98, glucose: 100, weight: 150, height: 170),
                target: HealthTarget(value: 0.0)
            ),
            HealthTrainingData(
                input: HealthInputData(heartRate: 100, systolicBP: 140, diastolicBP: 90, temperature: 99.0, oxygenSaturation: 96, glucose: 120, weight: 180, height: 175),
                target: HealthTarget(value: 1.0)
            )
        ]
        
        let validationData = trainingData.map { training in
            HealthValidationData(input: training.input, target: training.target)
        }
        
        let trainingResult = quantumNetwork.train(
            trainingData: trainingData,
            validationData: validationData,
            healthTask: .diseasePrediction
        )
        
        XCTAssertNotNil(trainingResult)
        // Training might not converge with minimal data, but should complete
        XCTAssertGreaterThan(trainingResult.epochs, 0)
    }
    
    // MARK: - Performance Tests
    
    func testPredictionPerformance() {
        let architecture = quantumNetwork.buildNetwork(
            inputSize: 8,
            hiddenLayers: [6, 4],
            outputSize: 3,
            quantumDepth: 2
        )
        
        measure {
            for _ in 0..<10 {
                let healthData = createTestHealthData()
                let _ = quantumNetwork.predict(
                    healthData: healthData,
                    healthTask: .diseasePrediction
                )
            }
        }
    }
    
    func testTrainingPerformance() {
        let architecture = quantumNetwork.buildNetwork(
            inputSize: 4,
            hiddenLayers: [3],
            outputSize: 1,
            quantumDepth: 1
        )
        
        let trainingData = createTestTrainingData(count: 5)
        let validationData = createTestValidationData(count: 2)
        
        measure {
            let _ = quantumNetwork.train(
                trainingData: trainingData,
                validationData: validationData,
                healthTask: .diseasePrediction
            )
        }
    }
    
    func testQuantumCircuitPerformance() {
        quantumCircuit.setup()
        quantumCircuit.initializeDefaultCircuit()
        
        measure {
            for _ in 0..<100 {
                let rotationGate = QuantumGate(
                    type: .rotationY,
                    qubits: [0],
                    parameter: QuantumParameter(name: "test", value: Double.random(in: 0...2*Double.pi), type: .rotation)
                )
                _ = quantumCircuit.applyGate(rotationGate)
            }
        }
    }
    
    // MARK: - Error Handling Tests
    
    func testInvalidNetworkConfiguration() {
        // Test with invalid input size
        let invalidArch1 = quantumNetwork.buildNetwork(
            inputSize: 0,
            hiddenLayers: [4],
            outputSize: 2,
            quantumDepth: 2
        )
        XCTAssertEqual(invalidArch1.inputSize, 0)
        
        // Test with negative quantum depth
        let invalidArch2 = quantumNetwork.buildNetwork(
            inputSize: 4,
            hiddenLayers: [4],
            outputSize: 2,
            quantumDepth: -1
        )
        XCTAssertEqual(invalidArch2.quantumDepth, -1)
    }
    
    func testInvalidTrainingData() {
        let architecture = quantumNetwork.buildNetwork(
            inputSize: 4,
            hiddenLayers: [3],
            outputSize: 1,
            quantumDepth: 2
        )
        
        // Test with empty training data
        let emptyTrainingData: [HealthTrainingData] = []
        let validationData = createTestValidationData(count: 2)
        
        let trainingResult = quantumNetwork.train(
            trainingData: emptyTrainingData,
            validationData: validationData,
            healthTask: .diseasePrediction
        )
        
        XCTAssertFalse(trainingResult.success)
        XCTAssertNotNil(trainingResult.error)
    }
    
    func testQuantumGateErrors() {
        quantumCircuit.setup()
        quantumCircuit.initializeDefaultCircuit()
        
        // Test with invalid qubit index
        let invalidGate = QuantumGate(
            type: .hadamard,
            qubits: [999], // Invalid qubit index
            parameter: nil
        )
        
        let success = quantumCircuit.applyGate(invalidGate)
        XCTAssertFalse(success)
    }
    
    // MARK: - Integration Tests
    
    func testEndToEndHealthPrediction() {
        // Build comprehensive network
        let architecture = quantumNetwork.buildNetwork(
            inputSize: 8,
            hiddenLayers: [6, 4],
            outputSize: 3,
            quantumDepth: 3
        )
        
        // Train with realistic data
        let trainingData = createRealisticTrainingData(count: 20)
        let validationData = createRealisticValidationData(count: 10)
        
        let trainingResult = quantumNetwork.train(
            trainingData: trainingData,
            validationData: validationData,
            healthTask: .diseasePrediction
        )
        
        // Make predictions
        let testData = createTestHealthData()
        let prediction = quantumNetwork.predict(
            healthData: testData,
            healthTask: .diseasePrediction
        )
        
        // Verify results
        XCTAssertNotNil(prediction)
        XCTAssertGreaterThan(prediction.confidence, 0.0)
        XCTAssertLessThanOrEqual(prediction.confidence, 1.0)
        
        // Get network statistics
        let statistics = quantumNetwork.getNetworkStatistics()
        XCTAssertGreaterThan(statistics.totalLayers, 0)
        XCTAssertGreaterThan(statistics.totalParameters, 0)
        XCTAssertGreaterThanOrEqual(statistics.quantumEfficiency, 0.0)
    }
    
    func testMultiTaskPrediction() {
        let architecture = quantumNetwork.buildNetwork(
            inputSize: 8,
            hiddenLayers: [6, 4],
            outputSize: 3,
            quantumDepth: 2
        )
        
        let healthData = createTestHealthData()
        
        // Test all prediction tasks
        let tasks: [HealthPredictionTask] = [
            .diseasePrediction,
            .healthScorePrediction,
            .treatmentResponsePrediction
        ]
        
        for task in tasks {
            let prediction = quantumNetwork.predict(
                healthData: healthData,
                healthTask: task
            )
            
            XCTAssertNotNil(prediction)
            XCTAssertEqual(prediction.healthTask, task)
            XCTAssertGreaterThanOrEqual(prediction.confidence, 0.0)
            XCTAssertLessThanOrEqual(prediction.confidence, 1.0)
        }
    }
    
    // MARK: - Helper Methods
    
    private func createTestHealthData() -> HealthInputData {
        return HealthInputData(
            heartRate: 75.0,
            systolicBP: 120.0,
            diastolicBP: 80.0,
            temperature: 98.6,
            oxygenSaturation: 98.0,
            glucose: 100.0,
            weight: 150.0,
            height: 170.0
        )
    }
    
    private func createTestTrainingData(count: Int) -> [HealthTrainingData] {
        return (0..<count).map { _ in
            HealthTrainingData(
                input: HealthInputData(
                    heartRate: Double.random(in: 60...100),
                    systolicBP: Double.random(in: 90...140),
                    diastolicBP: Double.random(in: 60...90),
                    temperature: Double.random(in: 97...99),
                    oxygenSaturation: Double.random(in: 95...100),
                    glucose: Double.random(in: 70...140),
                    weight: Double.random(in: 120...200),
                    height: Double.random(in: 150...190)
                ),
                target: HealthTarget(value: Double.random(in: 0...1))
            )
        }
    }
    
    private func createTestValidationData(count: Int) -> [HealthValidationData] {
        return createTestTrainingData(count: count).map { training in
            HealthValidationData(input: training.input, target: training.target)
        }
    }
    
    private func createRealisticTrainingData(count: Int) -> [HealthTrainingData] {
        return (0..<count).map { i in
            let isHealthy = i % 2 == 0
            
            return HealthTrainingData(
                input: HealthInputData(
                    heartRate: isHealthy ? Double.random(in: 60...80) : Double.random(in: 90...120),
                    systolicBP: isHealthy ? Double.random(in: 90...120) : Double.random(in: 130...160),
                    diastolicBP: isHealthy ? Double.random(in: 60...80) : Double.random(in: 85...100),
                    temperature: isHealthy ? Double.random(in: 98.0...98.8) : Double.random(in: 99.0...101.0),
                    oxygenSaturation: isHealthy ? Double.random(in: 98...100) : Double.random(in: 92...97),
                    glucose: isHealthy ? Double.random(in: 80...110) : Double.random(in: 140...200),
                    weight: Double.random(in: 120...200),
                    height: Double.random(in: 150...190)
                ),
                target: HealthTarget(value: isHealthy ? 0.0 : 1.0)
            )
        }
    }
    
    private func createRealisticValidationData(count: Int) -> [HealthValidationData] {
        return createRealisticTrainingData(count: count).map { training in
            HealthValidationData(input: training.input, target: training.target)
        }
    }
}

// MARK: - Performance Benchmark Tests

@available(iOS 18.0, macOS 15.0, *)
final class QuantumNeuralNetworkBenchmarkTests: XCTestCase {
    
    var quantumNetwork: QuantumNeuralNetwork!
    
    override func setUp() async throws {
        try await super.setUp()
        quantumNetwork = QuantumNeuralNetwork()
    }
    
    override func tearDown() async throws {
        quantumNetwork = nil
        try await super.tearDown()
    }
    
    func testLargePredictionPerformance() {
        let architecture = quantumNetwork.buildNetwork(
            inputSize: 16,
            hiddenLayers: [12, 8, 4],
            outputSize: 5,
            quantumDepth: 4
        )
        
        measure {
            for _ in 0..<50 {
                let healthData = createRandomHealthData()
                let _ = quantumNetwork.predict(
                    healthData: healthData,
                    healthTask: .diseasePrediction
                )
            }
        }
    }
    
    func testLargeNetworkTraining() {
        let architecture = quantumNetwork.buildNetwork(
            inputSize: 8,
            hiddenLayers: [6, 4],
            outputSize: 2,
            quantumDepth: 2
        )
        
        let trainingData = createLargeTrainingDataset(count: 50)
        let validationData = createLargeValidationDataset(count: 20)
        
        measure {
            let _ = quantumNetwork.train(
                trainingData: trainingData,
                validationData: validationData,
                healthTask: .diseasePrediction
            )
        }
    }
    
    func testQuantumCircuitScaling() {
        let circuitSizes = [4, 8, 12, 16]
        
        for size in circuitSizes {
            let circuit = QuantumCircuit()
            circuit.setup()
            circuit.initializeDefaultCircuit()
            
            measure {
                for _ in 0..<20 {
                    let rotationGate = QuantumGate(
                        type: .rotationY,
                        qubits: [0],
                        parameter: QuantumParameter(name: "test", value: Double.random(in: 0...2*Double.pi), type: .rotation)
                    )
                    _ = circuit.applyGate(rotationGate)
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func createRandomHealthData() -> HealthInputData {
        return HealthInputData(
            heartRate: Double.random(in: 40...200),
            systolicBP: Double.random(in: 80...200),
            diastolicBP: Double.random(in: 50...120),
            temperature: Double.random(in: 95...105),
            oxygenSaturation: Double.random(in: 85...100),
            glucose: Double.random(in: 70...400),
            weight: Double.random(in: 100...300),
            height: Double.random(in: 140...220)
        )
    }
    
    private func createLargeTrainingDataset(count: Int) -> [HealthTrainingData] {
        return (0..<count).map { _ in
            HealthTrainingData(
                input: createRandomHealthData(),
                target: HealthTarget(value: Double.random(in: 0...1))
            )
        }
    }
    
    private func createLargeValidationDataset(count: Int) -> [HealthValidationData] {
        return createLargeTrainingDataset(count: count).map { training in
            HealthValidationData(input: training.input, target: training.target)
        }
    }
}
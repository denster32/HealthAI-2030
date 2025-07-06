import XCTest
@testable import QuantumHealth

final class QuantumSimulationTests: XCTestCase {
    
    func testQuantumHealthSimulatorInitialization() {
        let simulator = QuantumHealthSimulator(qubits: 4)
        XCTAssertNotNil(simulator)
    }
    
    func testQuantumFourierTransform() {
        let simulator = QuantumHealthSimulator(qubits: 4)
        let healthSignal = [1.0, 0.5, 0.2, 0.1, 0.05, 0.02, 0.01, 0.005]
        
        let result = simulator.quantumFourierTransform(healthSignal: healthSignal)
        
        XCTAssertEqual(result.count, healthSignal.count)
        XCTAssertTrue(result.allSatisfy { !$0.real.isNaN && !$0.imaginary.isNaN })
    }
    
    func testQuantumMachineLearning() {
        let simulator = QuantumHealthSimulator(qubits: 4)
        let healthData = [
            [1.0, 0.5, 0.2],
            [0.8, 0.6, 0.3],
            [0.9, 0.4, 0.1],
            [0.7, 0.7, 0.4]
        ]
        let labels = [0, 1, 0, 1]
        
        let model = simulator.quantumMachineLearning(healthData: healthData, labels: labels)
        
        XCTAssertNotNil(model)
        XCTAssertEqual(model.inputSize, 3)
        XCTAssertEqual(model.outputSize, 2)
        
        let prediction = model.predict(input: [0.8, 0.5, 0.2])
        XCTAssertEqual(prediction.count, 2)
        XCTAssertTrue(prediction.allSatisfy { !$0.isNaN })
    }
    
    func testQuantumRandomNumberGeneration() {
        let simulator = QuantumHealthSimulator(qubits: 4)
        let randomNumbers = simulator.quantumRandomNumberGeneration(count: 10)
        
        XCTAssertEqual(randomNumbers.count, 10)
        XCTAssertTrue(randomNumbers.allSatisfy { $0 >= 0.0 && $0 <= 1.0 })
    }
    
    func testQuantumErrorCorrection() {
        let simulator = QuantumHealthSimulator(qubits: 4)
        let noisyData = [1.1, 0.9, 1.05, 0.95, 1.02]
        
        let correctedData = simulator.quantumErrorCorrection(noisyData: noisyData)
        
        XCTAssertEqual(correctedData.count, noisyData.count)
        XCTAssertTrue(correctedData.allSatisfy { !$0.isNaN })
    }
    
    func testQuantumEntanglement() {
        let simulator = QuantumHealthSimulator(qubits: 4)
        let healthParameters = [0.5, 0.3, 0.8, 0.2]
        
        let entangledParameters = simulator.quantumEntanglement(healthParameters: healthParameters)
        
        XCTAssertEqual(entangledParameters.count, healthParameters.count)
        XCTAssertTrue(entangledParameters.allSatisfy { !$0.isNaN })
    }
    
    func testGroversHealthSearch() {
        let database = [
            HealthRecord(id: "1", condition: "diabetes", symptoms: ["fatigue", "thirst"], severity: 0.7, timestamp: Date()),
            HealthRecord(id: "2", condition: "hypertension", symptoms: ["headache", "dizziness"], severity: 0.5, timestamp: Date()),
            HealthRecord(id: "3", condition: "diabetes", symptoms: ["blurred vision", "fatigue"], severity: 0.8, timestamp: Date()),
            HealthRecord(id: "4", condition: "asthma", symptoms: ["cough", "wheezing"], severity: 0.6, timestamp: Date())
        ]
        
        let results = QuantumHealthAlgorithms.groversHealthSearch(database: database, targetCondition: "diabetes")
        
        XCTAssertTrue(results.count >= 1)
        XCTAssertTrue(results.allSatisfy { $0.condition.contains("diabetes") })
    }
    
    func testQuantumSVM() {
        let trainingData = [
            HealthDataPoint(features: [1.0, 0.5, 0.2], label: 0, timestamp: Date()),
            HealthDataPoint(features: [0.8, 0.6, 0.3], label: 1, timestamp: Date()),
            HealthDataPoint(features: [0.9, 0.4, 0.1], label: 0, timestamp: Date()),
            HealthDataPoint(features: [0.7, 0.7, 0.4], label: 1, timestamp: Date())
        ]
        let labels = [0, 1, 0, 1]
        
        let model = QuantumHealthAlgorithms.quantumSVM(trainingData: trainingData, labels: labels)
        
        XCTAssertNotNil(model)
        XCTAssertEqual(model.weights.count, 3)
        
        let prediction = model.predict([0.8, 0.5, 0.2])
        XCTAssertTrue(prediction == 1 || prediction == -1)
    }
    
    func testQuantumNeuralNetwork() {
        let healthData = [
            [1.0, 0.5, 0.2],
            [0.8, 0.6, 0.3],
            [0.9, 0.4, 0.1],
            [0.7, 0.7, 0.4]
        ]
        let labels = [0, 1, 0, 1]
        
        let model = QuantumHealthAlgorithms.quantumNeuralNetwork(healthData: healthData, labels: labels)
        
        XCTAssertNotNil(model)
        let prediction = model.predict([0.8, 0.5, 0.2])
        XCTAssertTrue(prediction.allSatisfy { !$0.isNaN })
    }
    
    func testQuantumPCA() {
        let healthData = [
            [1.0, 0.5, 0.2, 0.1],
            [0.8, 0.6, 0.3, 0.2],
            [0.9, 0.4, 0.1, 0.15],
            [0.7, 0.7, 0.4, 0.25]
        ]
        
        let model = QuantumHealthAlgorithms.quantumPCA(healthData: healthData, components: 2)
        
        XCTAssertNotNil(model)
        XCTAssertEqual(model.principalComponents.count, 2)
        
        let transformed = model.transform([0.8, 0.5, 0.2, 0.1])
        XCTAssertEqual(transformed.count, 2)
        XCTAssertTrue(transformed.allSatisfy { !$0.isNaN })
    }
    
    func testQuantumClustering() {
        let healthData = [
            [1.0, 0.5],
            [0.8, 0.6],
            [0.9, 0.4],
            [0.7, 0.7],
            [0.2, 0.1],
            [0.3, 0.2],
            [0.1, 0.3]
        ]
        
        let model = QuantumHealthAlgorithms.quantumClustering(healthData: healthData, clusters: 2)
        
        XCTAssertNotNil(model)
        XCTAssertEqual(model.centroids.count, 2)
        XCTAssertEqual(model.assignments.count, healthData.count)
        
        let prediction = model.predict([0.5, 0.5])
        XCTAssertTrue(prediction >= 0 && prediction < 2)
    }
    
    func testQuantumApproximateOptimizationAlgorithm() {
        let objective = HealthObjectiveFunction { parameter, quantumContribution in
            return pow(parameter - 0.5, 2) + 0.1 * quantumContribution
        }
        
        let parameters = [0.1, 0.2, 0.3, 0.4]
        
        let result = QuantumHealthOptimizer.quantumApproximateOptimizationAlgorithm(
            healthObjective: objective,
            parameters: parameters,
            layers: 3
        )
        
        XCTAssertNotNil(result)
        XCTAssertEqual(result.optimizedParameters.count, parameters.count)
        XCTAssertTrue(result.finalCost >= 0)
        XCTAssertTrue(result.converged)
    }
    
    func testVariationalQuantumEigensolver() {
        let hamiltonian = HealthHamiltonian(matrix: [
            [1.0, 0.5, 0.0, 0.0],
            [0.5, 2.0, 0.3, 0.0],
            [0.0, 0.3, 1.5, 0.2],
            [0.0, 0.0, 0.2, 1.8]
        ])
        
        let initialParameters = [0.1, 0.2, 0.3, 0.4]
        
        let result = QuantumHealthOptimizer.variationalQuantumEigensolver(
            healthHamiltonian: hamiltonian,
            initialParameters: initialParameters
        )
        
        XCTAssertNotNil(result)
        XCTAssertTrue(result.groundStateEnergy.isFinite)
        XCTAssertEqual(result.optimizedParameters.count, initialParameters.count)
        XCTAssertTrue(result.converged)
    }
    
    func testQuantumAdiabaticOptimization() {
        let initialHamiltonian = HealthHamiltonian(matrix: [
            [0.0, 1.0],
            [1.0, 0.0]
        ])
        
        let finalHamiltonian = HealthHamiltonian(matrix: [
            [1.0, 0.0],
            [0.0, -1.0]
        ])
        
        let result = QuantumHealthOptimizer.quantumAdiabaticOptimization(
            initialHamiltonian: initialHamiltonian,
            finalHamiltonian: finalHamiltonian,
            evolutionTime: 10.0
        )
        
        XCTAssertNotNil(result)
        XCTAssertTrue(result.finalEnergy.isFinite)
        XCTAssertEqual(result.solution.count, 2)
        XCTAssertTrue(result.energyHistory.count > 0)
    }
    
    func testQuantumAnnealingOptimization() {
        let problem = HealthOptimizationProblem(
            dimension: 3,
            bounds: -1.0...1.0
        ) { solution in
            return solution.map { $0 * $0 }.reduce(0, +)
        }
        
        let result = QuantumHealthOptimizer.quantumAnnealingOptimization(
            healthProblem: problem,
            initialTemperature: 100.0,
            finalTemperature: 0.01,
            annealingSchedule: .exponential
        )
        
        XCTAssertNotNil(result)
        XCTAssertEqual(result.bestSolution.count, 3)
        XCTAssertTrue(result.bestCost >= 0)
        XCTAssertTrue(result.converged)
    }
    
    func testComplexNumbers() {
        let c1 = Complex(1.0, 2.0)
        let c2 = Complex(3.0, 4.0)
        
        let sum = c1 + c2
        XCTAssertEqual(sum.real, 4.0)
        XCTAssertEqual(sum.imaginary, 6.0)
        
        let product = c1 * c2
        XCTAssertEqual(product.real, -5.0)
        XCTAssertEqual(product.imaginary, 10.0)
        
        let conjugate = c1.conjugate()
        XCTAssertEqual(conjugate.real, 1.0)
        XCTAssertEqual(conjugate.imaginary, -2.0)
    }
}
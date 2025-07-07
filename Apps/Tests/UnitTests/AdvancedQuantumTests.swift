import XCTest
@testable import HealthAI2030Core

final class AdvancedQuantumTests: XCTestCase {
    let quantum = AdvancedQuantumManager.shared
    
    func testOptimizeQuantumAlgorithm() {
        let parameters = ["qubits": 10, "depth": 5]
        let optimization = quantum.optimizeQuantumAlgorithm(algorithm: .grover, parameters: parameters)
        
        XCTAssertEqual(optimization["performanceGain"] as? Double, 0.25)
        XCTAssertEqual(optimization["resourceReduction"] as? Double, 0.3)
        XCTAssertEqual(optimization["optimizationTime"] as? String, "2.5s")
    }
    
    func testAllQuantumAlgorithms() {
        let algorithms: [AdvancedQuantumManager.QuantumAlgorithm] = [
            .qft,
            .grover,
            .shor,
            .vqe,
            .qaoa,
            .quantumML
        ]
        
        for algorithm in algorithms {
            let benchmark = quantum.benchmarkQuantumAlgorithm(algorithm: algorithm)
            XCTAssertEqual(benchmark["executionTime"] as? Double, 1.5)
            XCTAssertEqual(benchmark["accuracy"] as? Double, 0.95)
            XCTAssertEqual(benchmark["qubitEfficiency"] as? Double, 0.88)
            XCTAssertEqual(benchmark["errorRate"] as? Double, 0.02)
        }
    }
    
    func testCompareWithClassical() {
        let quantumResult = Data("quantum".utf8)
        let classicalResult = Data("classical".utf8)
        let comparison = quantum.compareWithClassical(quantumResult: quantumResult, classicalResult: classicalResult)
        
        XCTAssertEqual(comparison["quantumAdvantage"] as? Double, 0.15)
        XCTAssertEqual(comparison["speedup"] as? Double, 2.5)
        XCTAssertEqual(comparison["accuracyImprovement"] as? Double, 0.08)
        XCTAssertEqual(comparison["resourceEfficiency"] as? Double, 0.75)
    }
    
    func testCreateHybridWorkflow() {
        let quantumSteps = ["quantum_step1", "quantum_step2"]
        let classicalSteps = ["classical_step1", "classical_step2", "classical_step3"]
        let workflowId = quantum.createHybridWorkflow(quantumSteps: quantumSteps, classicalSteps: classicalSteps)
        XCTAssertEqual(workflowId, "hybrid_workflow_123")
    }
    
    func testExecuteHybridComputation() {
        let data = Data([1,2,3,4,5])
        let result = quantum.executeHybridComputation(workflowId: "workflow1", data: data)
        XCTAssertNotNil(result)
    }
    
    func testOptimizeHybridPartitioning() {
        let optimization = quantum.optimizeHybridPartitioning(workflowId: "workflow1")
        XCTAssertEqual(optimization["quantumSteps"] as? Int, 3)
        XCTAssertEqual(optimization["classicalSteps"] as? Int, 7)
        XCTAssertEqual(optimization["optimizationGain"] as? Double, 0.2)
        XCTAssertEqual(optimization["partitioningStrategy"] as? String, "adaptive")
    }
    
    func testMonitorHybridPerformance() {
        let performance = quantum.monitorHybridPerformance(workflowId: "workflow1")
        XCTAssertEqual(performance["quantumUtilization"] as? Double, 0.6)
        XCTAssertEqual(performance["classicalUtilization"] as? Double, 0.8)
        XCTAssertEqual(performance["overallEfficiency"] as? Double, 0.72)
        XCTAssertEqual(performance["bottlenecks"] as? [String], ["quantum_initialization"])
    }
    
    func testApplyErrorCorrection() {
        let data = Data([1,2,3,4,5])
        let corrected = quantum.applyErrorCorrection(data: data, code: .surfaceCode)
        XCTAssertNotNil(corrected)
    }
    
    func testAllErrorCorrectionCodes() {
        let codes: [AdvancedQuantumManager.ErrorCorrectionCode] = [
            .surfaceCode,
            .stabilizerCode,
            .colorCode,
            .toricCode
        ]
        
        for code in codes {
            let data = Data([1,2,3])
            let corrected = quantum.applyErrorCorrection(data: data, code: code)
            XCTAssertNotNil(corrected)
        }
    }
    
    func testMeasureErrorRate() {
        let beforeData = Data([1,2,3])
        let afterData = Data([1,2,3])
        let errorRate = quantum.measureErrorRate(beforeCorrection: beforeData, afterCorrection: afterData)
        XCTAssertEqual(errorRate, 0.001)
    }
    
    func testImplementErrorMitigation() {
        let data = Data([1,2,3,4,5])
        let mitigated = quantum.implementErrorMitigation(strategy: "zero_noise_extrapolation", data: data)
        XCTAssertNotNil(mitigated)
    }
    
    func testValidateErrorCorrection() {
        let data = Data([1,2,3])
        let validation = quantum.validateErrorCorrection(data: data)
        XCTAssertEqual(validation["logicalErrorRate"] as? Double, 0.0001)
        XCTAssertEqual(validation["physicalErrorRate"] as? Double, 0.01)
        XCTAssertEqual(validation["correctionSuccess"] as? Double, 0.99)
        XCTAssertEqual(validation["overhead"] as? Double, 1.5)
    }
    
    func testGenerateQuantumKey() {
        let key = quantum.generateQuantumKey(keyLength: 256)
        XCTAssertNotNil(key)
    }
    
    func testQuantumEncryptionAndDecryption() {
        let originalData = Data("secret data".utf8)
        let key = quantum.generateQuantumKey(keyLength: 256)
        
        let encrypted = quantum.implementQuantumEncryption(data: originalData, key: key)
        XCTAssertNotNil(encrypted)
        
        let decrypted = quantum.performQuantumDecryption(encryptedData: encrypted, key: key)
        XCTAssertNotNil(decrypted)
    }
    
    func testValidateQuantumSecurity() {
        let security = quantum.validateQuantumSecurity(protocol: "BB84")
        XCTAssertEqual(security["securityLevel"] as? String, "post_quantum")
        XCTAssertEqual(security["vulnerabilityAssessment"] as? String, "secure")
        XCTAssertEqual(security["keyStrength"] as? Int, 256)
        XCTAssertEqual(security["attackResistance"] as? String, "high")
    }
    
    func testMonitorQuantumPerformance() {
        let performance = quantum.monitorQuantumPerformance(deviceId: "quantum_device_1")
        XCTAssertEqual(performance["coherenceTime"] as? Double, 50.0)
        XCTAssertEqual(performance["gateFidelity"] as? Double, 0.99)
        XCTAssertEqual(performance["qubitCount"] as? Int, 50)
        XCTAssertEqual(performance["connectivity"] as? Double, 0.8)
        XCTAssertEqual(performance["temperature"] as? Double, 0.015)
    }
    
    func testTrackQuantumMetrics() {
        let metrics = quantum.trackQuantumMetrics(deviceId: "quantum_device_1")
        XCTAssertEqual(metrics["fidelity"]?.count, 4)
        XCTAssertEqual(metrics["coherence"]?.count, 4)
        XCTAssertEqual(metrics["errorRate"]?.count, 4)
    }
    
    func testGenerateQuantumReport() {
        let report = quantum.generateQuantumReport(deviceId: "quantum_device_1")
        XCTAssertNotNil(report)
    }
    
    func testConductQuantumResearch() {
        let research = quantum.conductQuantumResearch(area: "quantum_machine_learning")
        XCTAssertEqual(research["researchArea"] as? String, "quantum_machine_learning")
        XCTAssertEqual(research["progress"] as? Double, 0.75)
        XCTAssertEqual(research["breakthroughs"] as? [String], ["new_algorithm", "error_reduction"])
        XCTAssertEqual(research["publications"] as? Int, 3)
        XCTAssertEqual(research["patents"] as? Int, 1)
    }
    
    func testDevelopQuantumProtocol() {
        let success = quantum.developQuantumProtocol(protocolName: "quantum_health_protocol")
        XCTAssertTrue(success)
    }
    
    func testValidateQuantumProtocol() {
        let validation = quantum.validateQuantumProtocol(protocolName: "quantum_health_protocol")
        XCTAssertEqual(validation["valid"] as? Bool, true)
        XCTAssertEqual(validation["efficiency"] as? Double, 0.85)
        XCTAssertEqual(validation["scalability"] as? String, "high")
        XCTAssertEqual(validation["robustness"] as? Double, 0.92)
        XCTAssertEqual(validation["recommendations"] as? [String], ["optimize_initialization", "reduce_overhead"])
    }
    
    func testGenerateResearchReport() {
        let report = quantum.generateResearchReport()
        XCTAssertNotNil(report)
    }
} 
import XCTest
@testable import HealthAI2030Core

final class ChaosEngineeringTests: XCTestCase {
    let chaos = ChaosEngineeringManager.shared
    
    func testFailureInjection() {
        chaos.injectFailure(.networkLatency, duration: 5.0)
        chaos.injectFailure(.serviceUnavailable, duration: 10.0)
        chaos.stopFailureInjection()
        // No assertion, just ensure no crash
    }
    
    func testResilienceTesting() {
        let result = chaos.runResilienceTest(scenario: "network_failure")
        XCTAssertTrue(result)
    }
    
    func testFailureRecoveryValidation() {
        let recovered = chaos.validateFailureRecovery()
        XCTAssertTrue(recovered)
    }
    
    func testSystemStabilityMonitoring() {
        let stability = chaos.monitorSystemStability()
        XCTAssertEqual(stability["cpu"] as? Double, 45.0)
        XCTAssertEqual(stability["memory"] as? Double, 60.0)
        XCTAssertEqual(stability["responseTime"] as? Double, 0.2)
    }
    
    func testSystemHealthCheck() {
        let healthy = chaos.checkSystemHealth()
        XCTAssertTrue(healthy)
    }
    
    func testResilienceReportGeneration() {
        let report = chaos.generateResilienceReport()
        XCTAssertEqual(report["testsRun"] as? Int, 10)
        XCTAssertEqual(report["failuresDetected"] as? Int, 2)
        XCTAssertEqual(report["recoveryTime"] as? Double, 5.0)
        XCTAssertEqual(report["systemStability"] as? Double, 0.95)
    }
    
    func testResilienceMetrics() {
        let metrics = chaos.getResilienceMetrics()
        XCTAssertEqual(metrics["meanTimeToRecovery"], 3.5)
        XCTAssertEqual(metrics["failureRate"], 0.02)
        XCTAssertEqual(metrics["availability"], 0.998)
    }
    
    func testAutomatedResilienceTests() {
        let success = chaos.runAutomatedResilienceTests()
        XCTAssertTrue(success)
    }
    
    func testDeploymentResilienceValidation() {
        let valid = chaos.validateDeploymentResilience()
        XCTAssertTrue(valid)
    }
    
    func testAllFailureTypes() {
        let failureTypes: [ChaosEngineeringManager.FailureType] = [
            .networkLatency,
            .serviceUnavailable,
            .memoryLeak,
            .cpuSpike,
            .diskFull,
            .databaseConnection
        ]
        
        for failureType in failureTypes {
            chaos.injectFailure(failureType, duration: 1.0)
        }
        chaos.stopFailureInjection()
        // No assertion, just ensure no crash
    }
} 
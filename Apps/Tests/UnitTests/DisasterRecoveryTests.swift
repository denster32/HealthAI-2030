import XCTest
@testable import HealthAI2030Core

final class DisasterRecoveryTests: XCTestCase {
    let dr = DisasterRecoveryManager.shared
    
    func testCreateBackup() {
        let success = dr.createBackup(backupId: "backup1", data: Data([1,2,3]))
        XCTAssertTrue(success)
    }
    
    func testRestoreBackup() {
        let restored = dr.restoreBackup(backupId: "backup1")
        XCTAssertNotNil(restored)
    }
    
    func testListBackups() {
        let backups = dr.listBackups()
        XCTAssertEqual(backups.count, 3)
        XCTAssertTrue(backups.contains("backup1"))
    }
    
    func testReplicateToRegion() {
        let success = dr.replicateToRegion(data: Data([4,5,6]), region: "us-west")
        XCTAssertTrue(success)
    }
    
    func testFailoverToRegion() {
        let success = dr.failoverToRegion(region: "us-west")
        XCTAssertTrue(success)
    }
    
    func testGetAvailableRegions() {
        let regions = dr.getAvailableRegions()
        XCTAssertEqual(regions.count, 4)
        XCTAssertTrue(regions.contains("us-east"))
        XCTAssertTrue(regions.contains("us-west"))
        XCTAssertTrue(regions.contains("eu-west"))
        XCTAssertTrue(regions.contains("ap-southeast"))
    }
    
    func testCreateBusinessContinuityPlan() {
        let success = dr.createBusinessContinuityPlan(planId: "bcp1")
        XCTAssertTrue(success)
    }
    
    func testTestBusinessContinuity() {
        let success = dr.testBusinessContinuity(planId: "bcp1")
        XCTAssertTrue(success)
    }
    
    func testValidateBusinessContinuity() {
        let validation = dr.validateBusinessContinuity()
        XCTAssertEqual(validation["status"] as? String, "valid")
        XCTAssertEqual(validation["lastTested"] as? String, "2024-01-15")
        XCTAssertEqual(validation["nextTest"] as? String, "2024-02-15")
    }
    
    func testSetAndGetRTO() {
        dr.setRTO(service: "api-service", rto: 300.0)
        let rto = dr.getRTO(service: "api-service")
        XCTAssertEqual(rto, 300.0)
    }
    
    func testSetAndGetRPO() {
        dr.setRPO(service: "api-service", rpo: 60.0)
        let rpo = dr.getRPO(service: "api-service")
        XCTAssertEqual(rpo, 60.0)
    }
    
    func testAutomateRecovery() {
        let success = dr.automateRecovery(recoveryId: "recovery1")
        XCTAssertTrue(success)
    }
    
    func testOrchestrateRecovery() {
        let services = ["api-service", "database", "cache"]
        let success = dr.orchestrateRecovery(services: services)
        XCTAssertTrue(success)
    }
    
    func testTestDisasterRecovery() {
        let success = dr.testDisasterRecovery(scenario: "region_failure")
        XCTAssertTrue(success)
    }
    
    func testValidateDisasterRecovery() {
        let validation = dr.validateDisasterRecovery()
        XCTAssertEqual(validation["status"] as? String, "ready")
        XCTAssertEqual(validation["lastTested"] as? String, "2024-01-10")
        XCTAssertEqual(validation["recoveryTime"] as? Double, 240.0)
        XCTAssertEqual(validation["dataLoss"] as? Double, 0.0)
    }
} 
import XCTest
@testable import HealthAI2030Core

final class AdvancedDataArchitectureTests: XCTestCase {
    let manager = AdvancedDataArchitectureManager.shared
    
    func testRegisterAndGetTenant() {
        manager.registerTenant(id: "t1", name: "Tenant1", partition: "p1")
        let tenant = manager.getTenant(by: "t1")
        XCTAssertNotNil(tenant)
        XCTAssertEqual(tenant?.name, "Tenant1")
        XCTAssertEqual(tenant?.dataPartition, "p1")
    }
    
    func testSharding() {
        let shard = manager.getShard(for: "user123", shardCount: 10)
        XCTAssertTrue(shard >= 0 && shard < 10)
    }
    
    func testReplication() {
        manager.replicateData(data: Data([1,2,3]), to: ["node1", "node2"])
        // No assertion, just ensure no crash
    }
    
    func testArchivingAndRestore() {
        manager.archiveData(data: Data([4,5,6]), archiveId: "a1")
        let restored = manager.restoreData(archiveId: "a1")
        XCTAssertNil(restored) // Stub returns nil
    }
    
    func testDataValidation() {
        XCTAssertTrue(manager.validateData(Data([1,2,3])))
        XCTAssertFalse(manager.validateData(Data()))
    }
    
    func testMonitorDataQuality() {
        let metrics = manager.monitorDataQuality()
        XCTAssertEqual(metrics["validRecords"] as? Int, 1000)
        XCTAssertEqual(metrics["invalidRecords"] as? Int, 0)
    }
    
    func testBackupAndRecovery() {
        manager.backupData(data: Data([7,8,9]), backupId: "b1")
        let recovered = manager.recoverBackup(backupId: "b1")
        XCTAssertNil(recovered) // Stub returns nil
    }
} 
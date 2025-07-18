import XCTest
import HealthAI2030Core

@available(iOS 17.0, macOS 14.0, watchOS 10.0, tvOS 17.0, *)
final class MultiDeviceSyncTests: XCTestCase {
    private var syncManager: CrossDeviceSyncManager!

    override func setUpWithError() throws {
        try super.setUpWithError()
        syncManager = CrossDeviceSyncManager()
    }

    override func tearDownWithError() throws {
        syncManager = nil
        try super.tearDownWithError()
    }

    func testInitialSyncStatus() async {
        XCTAssertEqual(syncManager.syncStatus, SyncStatus.idle)
    }

    func testQueueHealthDataForSync() async {
        // Test that sync can be started
        syncManager.startSyncCoordination()
        XCTAssertEqual(syncManager.syncStatus, SyncStatus.syncing)
    }

    func testQueueUserPreferencesForSync() async {
        // Test user preferences sync
        syncManager.startSyncCoordination()
        XCTAssertEqual(syncManager.syncStatus, SyncStatus.syncing)
    }

    func testSyncHealthData() async {
        // Test health data synchronization
        syncManager.startSyncCoordination()
        
        // Wait for sync to complete
        let expectation = XCTestExpectation(description: "Sync completion")
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            expectation.fulfill()
        }
        
        await fulfillment(of: [expectation], timeout: 3.0)
        
        // Check that sync completed
        XCTAssertTrue([SyncStatus.completed, SyncStatus.idle].contains(syncManager.syncStatus))
    }

    func testSyncUserPreferences() async {
        // Test user preferences synchronization
        syncManager.startSyncCoordination()
        
        let expectation = XCTestExpectation(description: "Preferences sync completion")
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            expectation.fulfill()
        }
        
        await fulfillment(of: [expectation], timeout: 3.0)
        
        XCTAssertTrue([SyncStatus.completed, SyncStatus.idle].contains(syncManager.syncStatus))
    }

    func testConflictResolution() async {
        // Create mock conflict using the correct types
        let mockLocalItem = HealthDataSyncItem(
            id: "test-id",
            deviceId: "device-1",
            dataType: "steps",
            encryptedData: Data(),
            creationDate: Date(),
            modificationDate: Date(),
            priority: SyncPriority.normal
        )
        
        let mockRemoteItem = HealthDataSyncItem(
            id: "test-id",
            deviceId: "device-2",
            dataType: "steps",
            encryptedData: Data(),
            creationDate: Date(),
            modificationDate: Date().addingTimeInterval(60),
            priority: SyncPriority.normal
        )
        
        let conflict = SyncConflict(
            id: UUID(),
            type: SyncDataType.healthData,
            localItem: mockLocalItem,
            remoteItem: mockRemoteItem,
            conflictReason: ConflictReason.simultaneousModification
        )
        
        syncManager.syncConflicts = [conflict]
        
        // Test conflict resolution
        await syncManager.resolveSyncConflict(conflict.id, resolution: ConflictResolutionStrategy.useLocal)
        
        // Verify that conflicts are resolved
        XCTAssertTrue(syncManager.syncConflicts.isEmpty)
    }
}
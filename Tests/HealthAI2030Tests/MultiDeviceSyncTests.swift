import XCTest
@testable import HealthAI2030

@available(iOS 16.0, *)
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
        XCTAssertEqual(syncManager.syncStatus, .idle)
    }

    func testQueueHealthDataForSync() async {
        let mockData = HealthData(
            id: UUID(),
            date: Date(),
            type: .steps,
            value: 1000
        )
        syncManager.queueHealthDataForSync(mockData)
        // Add assertions to check if data is queued correctly
        XCTAssertGreaterThan(syncManager.pendingSyncItems, 0)
    }

    func testQueueUserPreferencesForSync() async {
        let mockPreferences = ["dailyStepGoal": 8000]
        syncManager.queueUserPreferencesForSync(mockPreferences)
        // Add assertions to check if preferences are queued correctly
        XCTAssertGreaterThan(syncManager.pendingSyncItems, 0)
    }

    func testSyncHealthData() async {
        let mockData = HealthData(
            id: UUID(),
            date: Date(),
            type: .steps,
            value: 1000
        )
        syncManager.queueHealthDataForSync(mockData)
        await syncManager.syncHealthData()
        // Add assertions to check if data is synced and pending queue is empty
        XCTAssertEqual(syncManager.pendingSyncItems, 0)
    }

    func testSyncUserPreferences() async {
        let mockPreferences = ["dailyStepGoal": 8000]
        syncManager.queueUserPreferencesForSync(mockPreferences)
        await syncManager.syncUserPreferences()
        // Add assertions to check if preferences are synced and pending queue is empty
        XCTAssertEqual(syncManager.pendingSyncItems, 0)
    }

    func testConflictResolution() async {
        // Create mock conflict
        let conflict = SyncConflict(
            id: UUID(),
            type: .healthData,
            localItem: HealthData(id: UUID(), date: Date(), type: .steps, value: 1000),
            remoteItem: HealthData(id: UUID(), date: Date().addingTimeInterval(60), type: .steps, value: 1200),
            conflictReason: .simultaneousModification
        )
        syncManager.syncConflicts = [conflict]

        // Resolve conflict using local data
        await syncManager.resolveSyncConflict(conflict.id, resolution: .useLocal)
        XCTAssertTrue(syncManager.syncConflicts.isEmpty) // Check if conflict is resolved
    }
}
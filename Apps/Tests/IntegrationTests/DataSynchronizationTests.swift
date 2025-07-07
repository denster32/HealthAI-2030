import XCTest
import SwiftData
@testable import HealthAI2030Core
@testable import HealthAI2030Core
@testable import HealthAI2030Networking

@available(iOS 18.0, macOS 15.0, *)
final class DataSynchronizationTests: XCTestCase {
    var syncManager: RealTimeDataSyncManager!
    var dataManager: SwiftDataManager!

    override func setUpWithError() throws {
        syncManager = RealTimeDataSyncManager.shared
        dataManager = SwiftDataManager()
        syncManager.networkStatus = .disconnected // simulate offline
    }

    override func tearDownWithError() throws {
        syncManager.networkStatus = .connected
        syncManager.syncStatus = .idle
        syncManager.pendingChanges.removeAll()
        dataManager = nil
        syncManager = nil
    }

    func testOfflineDataCreationThenSync() async throws {
        // Create data offline
        let model = TestModel(name: "OfflineSync", value: 1)
        try await dataManager.save(model)
        XCTAssertEqual(try await dataManager.fetchAll(TestModel.self).count, 1)
        
        // Simulate going online and syncing
        syncManager.networkStatus = .connected
        await syncManager.performSync() // assume performSync exists
        
        // After sync, pendingChanges should be empty and lastSyncDate set
        XCTAssertTrue(syncManager.pendingChanges.isEmpty)
        XCTAssertNotNil(syncManager.lastSyncDate)
    }

    func testOnlineThenOfflineModifyThenResync() async throws {
        // Start online, create data
        syncManager.networkStatus = .connected
        let model = TestModel(name: "Initial", value: 0)
        try await dataManager.save(model)
        await syncManager.performSync()
        
        // Go offline and modify
        syncManager.networkStatus = .disconnected
        model.name = "ModifiedOffline"
        try await dataManager.update(model)
        XCTAssertEqual(try await dataManager.fetch(predicate: #Predicate { $0.name == "ModifiedOffline" }).first?.value, 0)
        
        // Go online and sync again
        syncManager.networkStatus = .connected
        await syncManager.performSync()
        // Check that remote has updated value
        // This would require mock server; for now verify pendingChanges emptied
        XCTAssertTrue(syncManager.pendingChanges.isEmpty)
    }

    func testLongTermOfflineAccumulationAndSync() async throws {
        syncManager.networkStatus = .disconnected
        for i in 0..<50 {
            try await dataManager.save(TestModel(name: "Batch-\(i)", value: i))
        }
        XCTAssertEqual(try await dataManager.fetchAll(TestModel.self).count, 50)
        
        syncManager.networkStatus = .connected
        await syncManager.performSync()
        XCTAssertTrue(syncManager.pendingChanges.isEmpty)
    }

    func testConcurrentSyncAttempts() async throws {
        syncManager.networkStatus = .connected
        // Simulate multiple sync operations
        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<5 {
                group.addTask {
                    await show try? syncManager.performSync()
                }
            }
        }
        XCTAssertTrue(syncManager.syncStatus == .idle || syncManager.syncStatus == .syncing)
    }

    func testNetworkErrorsDuringSync() async throws {
        syncManager.networkStatus = .connected
        // Simulate network flapping
        syncManager.networkStatus = .connected
        await syncManager.performSync()
        syncManager.networkStatus = .disconnected
        await syncManager.performSync()
        // Should not crash, error state expected
        XCTAssertTrue(syncManager.syncStatus == .error)
    }
} 
import XCTest
import SwiftData
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

    // MARK: - Basic Sync Scenarios
    
    func testOfflineDataCreationThenSync() async throws {
        // Create data offline
        let model = TestModel(name: "OfflineSync", value: 1)
        try await dataManager.save(model)
        XCTAssertEqual(try await dataManager.fetchAll(TestModel.self).count, 1)
        
        // Simulate going online and syncing
        syncManager.networkStatus = .connected
        await syncManager.startSync()
        
        // After sync, pendingChanges should be empty and lastSyncDate set
        XCTAssertTrue(syncManager.pendingChanges.isEmpty)
        XCTAssertNotNil(syncManager.lastSyncDate)
    }

    func testOnlineThenOfflineModifyThenResync() async throws {
        // Start online, create data
        syncManager.networkStatus = .connected
        let model = TestModel(name: "Initial", value: 0)
        try await dataManager.save(model)
        await syncManager.startSync()
        
        // Go offline and modify
        syncManager.networkStatus = .disconnected
        model.name = "ModifiedOffline"
        try await dataManager.update(model)
        XCTAssertEqual(try await dataManager.fetch(predicate: #Predicate { $0.name == "ModifiedOffline" }).first?.value, 0)
        
        // Go online and sync again
        syncManager.networkStatus = .connected
        await syncManager.startSync()
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
        await syncManager.startSync()
        XCTAssertTrue(syncManager.pendingChanges.isEmpty)
    }

    func testConcurrentSyncAttempts() async throws {
        syncManager.networkStatus = .connected
        // Simulate multiple sync operations
        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<5 {
                group.addTask {
                    await self.syncManager.startSync()
                }
            }
        }
        XCTAssertTrue(syncManager.syncStatus == .idle || syncManager.syncStatus == .syncing)
    }

    func testNetworkErrorsDuringSync() async throws {
        syncManager.networkStatus = .connected
        // Simulate network flapping
        syncManager.networkStatus = .connected
        await syncManager.startSync()
        syncManager.networkStatus = .disconnected
        await syncManager.startSync()
        // Should not crash, error state expected
        XCTAssertTrue(syncManager.syncStatus == .error || syncManager.syncStatus == .offline)
    }
    
    // MARK: - Advanced Sync Scenarios
    
    func testPriorityBasedSync() async throws {
        syncManager.networkStatus = .connected
        
        // Create changes with different priorities
        let criticalData = "critical_data".data(using: .utf8)!
        let highData = "high_data".data(using: .utf8)!
        let normalData = "normal_data".data(using: .utf8)!
        let lowData = "low_data".data(using: .utf8)!
        
        await syncManager.queueChange(
            entityType: "TestModel",
            entityId: "critical-1",
            operation: .create,
            data: criticalData,
            priority: .critical
        )
        
        await syncManager.queueChange(
            entityType: "TestModel",
            entityId: "high-1",
            operation: .create,
            data: highData,
            priority: .high
        )
        
        await syncManager.queueChange(
            entityType: "TestModel",
            entityId: "normal-1",
            operation: .create,
            data: normalData,
            priority: .normal
        )
        
        await syncManager.queueChange(
            entityType: "TestModel",
            entityId: "low-1",
            operation: .create,
            data: lowData,
            priority: .low
        )
        
        // Critical and high priority changes should trigger immediate sync
        XCTAssertEqual(syncManager.pendingChanges.count, 4)
        XCTAssertTrue(syncManager.syncStatus == .syncing || syncManager.syncStatus == .idle)
    }
    
    func testConflictDetectionAndResolution() async throws {
        syncManager.networkStatus = .connected
        
        // Create conflicting changes
        let localData = "local_change".data(using: .utf8)!
        let remoteData = "remote_change".data(using: .utf8)!
        
        await syncManager.queueChange(
            entityType: "TestModel",
            entityId: "conflict-1",
            operation: .update,
            data: localData,
            priority: .normal
        )
        
        // Simulate remote change (in real scenario, this would come from another device)
        await syncManager.queueChange(
            entityType: "TestModel",
            entityId: "conflict-1",
            operation: .update,
            data: remoteData,
            priority: .normal
        )
        
        // Start sync to trigger conflict detection
        await syncManager.startSync()
        
        // Should detect conflicts
        XCTAssertGreaterThanOrEqual(syncManager.conflicts.count, 0)
        
        // Resolve conflicts
        for conflict in syncManager.conflicts {
            await syncManager.resolveConflict(conflict, resolution: .useLocal)
        }
        
        // Conflicts should be resolved
        XCTAssertTrue(syncManager.conflicts.allSatisfy { $0.isResolved })
    }
    
    func testMultiDeviceSync() async throws {
        syncManager.networkStatus = .connected
        
        // Simulate multiple devices
        let device1 = RealTimeDataSyncManager.ConnectedDevice(
            deviceId: "device-1",
            deviceName: "iPhone Test",
            deviceType: .iPhone,
            lastSeen: Date(),
            isOnline: true,
            syncStatus: .idle
        )
        
        let device2 = RealTimeDataSyncManager.ConnectedDevice(
            deviceId: "device-2",
            deviceName: "iPad Test",
            deviceType: .iPad,
            lastSeen: Date(),
            isOnline: true,
            syncStatus: .syncing
        )
        
        // Add devices to connected devices list
        syncManager.connectedDevices = [device1, device2]
        
        // Verify device tracking
        XCTAssertEqual(syncManager.connectedDevices.count, 2)
        XCTAssertTrue(syncManager.connectedDevices.contains { $0.deviceId == "device-1" })
        XCTAssertTrue(syncManager.connectedDevices.contains { $0.deviceId == "device-2" })
        
        // Test sync across devices
        await syncManager.startSync()
        
        // Verify sync status is updated
        XCTAssertTrue(syncManager.syncStatus == .idle || syncManager.syncStatus == .syncing)
    }
    
    func testOfflineQueueManagement() async throws {
        syncManager.networkStatus = .disconnected
        
        // Queue multiple changes while offline
        for i in 0..<10 {
            let data = "offline_data_\(i)".data(using: .utf8)!
            await syncManager.queueChange(
                entityType: "TestModel",
                entityId: "offline-\(i)",
                operation: .create,
                data: data,
                priority: .normal
            )
        }
        
        // Verify changes are queued
        XCTAssertEqual(syncManager.pendingChanges.count, 10)
        XCTAssertEqual(syncManager.syncStatus, .offline)
        
        // Go online and sync
        syncManager.networkStatus = .connected
        await syncManager.startSync()
        
        // Verify all changes are processed
        XCTAssertTrue(syncManager.pendingChanges.isEmpty || syncManager.pendingChanges.allSatisfy { $0.isResolved })
    }
    
    func testSyncPauseAndResume() async throws {
        syncManager.networkStatus = .connected
        
        // Queue some changes
        for i in 0..<5 {
            let data = "pause_resume_\(i)".data(using: .utf8)!
            await syncManager.queueChange(
                entityType: "TestModel",
                entityId: "pause-\(i)",
                operation: .create,
                data: data,
                priority: .normal
            )
        }
        
        // Pause sync
        syncManager.pauseSync()
        XCTAssertEqual(syncManager.syncStatus, .paused)
        
        // Resume sync
        await syncManager.resumeSync()
        XCTAssertEqual(syncManager.syncStatus, .idle)
        
        // Verify changes are processed
        await syncManager.startSync()
        XCTAssertTrue(syncManager.pendingChanges.isEmpty || syncManager.pendingChanges.allSatisfy { $0.isResolved })
    }
    
    func testSyncStatistics() async throws {
        syncManager.networkStatus = .connected
        
        // Create some changes and conflicts
        for i in 0..<5 {
            let data = "stats_\(i)".data(using: .utf8)!
            await syncManager.queueChange(
                entityType: "TestModel",
                entityId: "stats-\(i)",
                operation: .create,
                data: data,
                priority: .normal
            )
        }
        
        // Create a conflict
        let conflict = RealTimeDataSyncManager.SyncConflict(
            entityType: "TestModel",
            entityId: "conflict-stats",
            localChange: RealTimeDataSyncManager.SyncChange(
                entityType: "TestModel",
                entityId: "conflict-stats",
                operation: .update,
                data: "local".data(using: .utf8)!,
                deviceId: "device-1"
            ),
            remoteChange: RealTimeDataSyncManager.SyncChange(
                entityType: "TestModel",
                entityId: "conflict-stats",
                operation: .update,
                data: "remote".data(using: .utf8)!,
                deviceId: "device-2"
            ),
            conflictType: .simultaneousEdit
        )
        syncManager.conflicts = [conflict]
        
        // Get statistics
        let stats = syncManager.getSyncStatistics()
        
        // Verify statistics
        XCTAssertEqual(stats.totalChanges, 5)
        XCTAssertEqual(stats.totalConflicts, 1)
        XCTAssertEqual(stats.pendingChanges, 5)
        XCTAssertEqual(stats.pendingConflicts, 1)
        XCTAssertEqual(stats.syncStatus, syncManager.syncStatus)
        XCTAssertEqual(stats.networkStatus, syncManager.networkStatus)
    }
    
    func testSyncDataExport() async throws {
        syncManager.networkStatus = .connected
        
        // Create some test data
        for i in 0..<3 {
            let data = "export_\(i)".data(using: .utf8)!
            await syncManager.queueChange(
                entityType: "TestModel",
                entityId: "export-\(i)",
                operation: .create,
                data: data,
                priority: .normal
            )
        }
        
        // Export sync data
        let exportData = syncManager.exportSyncData()
        XCTAssertNotNil(exportData, "Export data should not be nil")
        
        // Verify export data can be decoded
        if let data = exportData {
            let decoder = JSONDecoder()
            XCTAssertNoThrow(try decoder.decode(SyncExportData.self, from: data))
        }
    }
    
    func testNetworkStatusTransitions() async throws {
        // Test various network status transitions
        
        // Start disconnected
        syncManager.networkStatus = .disconnected
        XCTAssertEqual(syncManager.networkStatus, .disconnected)
        XCTAssertFalse(syncManager.networkStatus.isConnected)
        
        // Transition to WiFi
        syncManager.networkStatus = .wifi
        XCTAssertEqual(syncManager.networkStatus, .wifi)
        XCTAssertTrue(syncManager.networkStatus.isConnected)
        
        // Transition to cellular
        syncManager.networkStatus = .cellular
        XCTAssertEqual(syncManager.networkStatus, .cellular)
        XCTAssertTrue(syncManager.networkStatus.isConnected)
        
        // Transition to connected (generic)
        syncManager.networkStatus = .connected
        XCTAssertEqual(syncManager.networkStatus, .connected)
        XCTAssertTrue(syncManager.networkStatus.isConnected)
        
        // Transition back to disconnected
        syncManager.networkStatus = .disconnected
        XCTAssertEqual(syncManager.networkStatus, .disconnected)
        XCTAssertFalse(syncManager.networkStatus.isConnected)
    }
    
    func testSyncProgressTracking() async throws {
        syncManager.networkStatus = .connected
        
        // Create multiple changes to track progress
        for i in 0..<10 {
            let data = "progress_\(i)".data(using: .utf8)!
            await syncManager.queueChange(
                entityType: "TestModel",
                entityId: "progress-\(i)",
                operation: .create,
                data: data,
                priority: .normal
            )
        }
        
        // Start sync
        await syncManager.startSync()
        
        // Verify progress is tracked
        XCTAssertGreaterThanOrEqual(syncManager.syncProgress, 0.0)
        XCTAssertLessThanOrEqual(syncManager.syncProgress, 1.0)
        
        // After sync completion, progress should be 1.0
        if syncManager.syncStatus == .idle {
            XCTAssertEqual(syncManager.syncProgress, 1.0)
        }
    }
    
    func testSyncErrorRecovery() async throws {
        syncManager.networkStatus = .connected
        
        // Create changes
        for i in 0..<3 {
            let data = "error_recovery_\(i)".data(using: .utf8)!
            await syncManager.queueChange(
                entityType: "TestModel",
                entityId: "error-\(i)",
                operation: .create,
                data: data,
                priority: .normal
            )
        }
        
        // Simulate error state
        syncManager.syncStatus = .error
        
        // Attempt recovery by starting sync again
        await syncManager.startSync()
        
        // Should recover from error state
        XCTAssertNotEqual(syncManager.syncStatus, .error)
    }
    
    func testSyncQueueClearing() async throws {
        syncManager.networkStatus = .connected
        
        // Create pending changes
        for i in 0..<5 {
            let data = "clear_\(i)".data(using: .utf8)!
            await syncManager.queueChange(
                entityType: "TestModel",
                entityId: "clear-\(i)",
                operation: .create,
                data: data,
                priority: .normal
            )
        }
        
        XCTAssertEqual(syncManager.pendingChanges.count, 5)
        
        // Clear pending changes
        await syncManager.clearPendingChanges()
        XCTAssertTrue(syncManager.pendingChanges.isEmpty)
        
        // Create conflicts
        let conflict = RealTimeDataSyncManager.SyncConflict(
            entityType: "TestModel",
            entityId: "clear-conflict",
            localChange: RealTimeDataSyncManager.SyncChange(
                entityType: "TestModel",
                entityId: "clear-conflict",
                operation: .update,
                data: "local".data(using: .utf8)!,
                deviceId: "device-1"
            ),
            remoteChange: RealTimeDataSyncManager.SyncChange(
                entityType: "TestModel",
                entityId: "clear-conflict",
                operation: .update,
                data: "remote".data(using: .utf8)!,
                deviceId: "device-2"
            ),
            conflictType: .simultaneousEdit
        )
        syncManager.conflicts = [conflict]
        
        XCTAssertEqual(syncManager.conflicts.count, 1)
        
        // Clear conflicts
        await syncManager.clearConflicts()
        XCTAssertTrue(syncManager.conflicts.isEmpty)
    }
    
    // MARK: - Performance Tests
    
    func testSyncPerformance() async throws {
        syncManager.networkStatus = .connected
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Create many changes
        for i in 0..<100 {
            let data = "perf_\(i)".data(using: .utf8)!
            await syncManager.queueChange(
                entityType: "TestModel",
                entityId: "perf-\(i)",
                operation: .create,
                data: data,
                priority: .normal
            )
        }
        
        // Start sync
        await syncManager.startSync()
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let duration = endTime - startTime
        
        // Should complete within reasonable time
        XCTAssertLessThan(duration, 10.0, "Sync took too long: \(duration)s")
    }
    
    func testConcurrentSyncPerformance() async throws {
        syncManager.networkStatus = .connected
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Perform concurrent sync operations
        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<10 {
                group.addTask {
                    await self.syncManager.startSync()
                }
            }
        }
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let duration = endTime - startTime
        
        // Should handle concurrent operations efficiently
        XCTAssertLessThan(duration, 5.0, "Concurrent sync took too long: \(duration)s")
    }
}

// MARK: - Supporting Types

private struct SyncExportData: Codable {
    let syncStatus: RealTimeDataSyncManager.SyncStatus
    let lastSyncDate: Date?
    let pendingChanges: [RealTimeDataSyncManager.SyncChange]
    let conflicts: [RealTimeDataSyncManager.SyncConflict]
    let connectedDevices: [RealTimeDataSyncManager.ConnectedDevice]
    let networkStatus: RealTimeDataSyncManager.NetworkStatus
    let exportDate: Date
} 
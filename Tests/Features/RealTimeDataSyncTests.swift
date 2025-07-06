import XCTest
import SwiftUI
import Network
@testable import HealthAI2030

/// Comprehensive unit tests for the Real-Time Data Sync Manager
/// Tests all functionality including sync operations, conflict resolution, and device management
final class RealTimeDataSyncTests: XCTestCase {
    
    var syncManager: RealTimeDataSyncManager!
    
    override func setUpWithError() throws {
        super.setUp()
        syncManager = RealTimeDataSyncManager.shared
        syncManager.pendingChanges.removeAll()
        syncManager.conflicts.removeAll()
        syncManager.connectedDevices.removeAll()
        syncManager.syncStatus = .idle
        syncManager.syncProgress = 0.0
    }
    
    override func tearDownWithError() throws {
        syncManager = nil
        super.tearDown()
    }
    
    // MARK: - Manager Tests
    
    func testSyncManagerInitialization() {
        XCTAssertNotNil(syncManager)
        XCTAssertEqual(syncManager.syncStatus, .idle)
        XCTAssertEqual(syncManager.pendingChanges.count, 0)
        XCTAssertEqual(syncManager.conflicts.count, 0)
        XCTAssertEqual(syncManager.connectedDevices.count, 0)
        XCTAssertEqual(syncManager.syncProgress, 0.0)
        XCTAssertNil(syncManager.lastSyncDate)
    }
    
    func testSyncManagerSingleton() {
        let instance1 = RealTimeDataSyncManager.shared
        let instance2 = RealTimeDataSyncManager.shared
        XCTAssertTrue(instance1 === instance2)
    }
    
    // MARK: - Status Tests
    
    func testSyncStatusColors() {
        XCTAssertEqual(RealTimeDataSyncManager.SyncStatus.idle.color, "gray")
        XCTAssertEqual(RealTimeDataSyncManager.SyncStatus.syncing.color, "blue")
        XCTAssertEqual(RealTimeDataSyncManager.SyncStatus.paused.color, "orange")
        XCTAssertEqual(RealTimeDataSyncManager.SyncStatus.error.color, "red")
        XCTAssertEqual(RealTimeDataSyncManager.SyncStatus.offline.color, "yellow")
        XCTAssertEqual(RealTimeDataSyncManager.SyncStatus.conflict.color, "purple")
    }
    
    func testNetworkStatusIsConnected() {
        XCTAssertFalse(RealTimeDataSyncManager.NetworkStatus.unknown.isConnected)
        XCTAssertTrue(RealTimeDataSyncManager.NetworkStatus.connected.isConnected)
        XCTAssertFalse(RealTimeDataSyncManager.NetworkStatus.disconnected.isConnected)
        XCTAssertTrue(RealTimeDataSyncManager.NetworkStatus.wifi.isConnected)
        XCTAssertTrue(RealTimeDataSyncManager.NetworkStatus.cellular.isConnected)
    }
    
    func testSyncPriorityDelays() {
        XCTAssertEqual(RealTimeDataSyncManager.SyncPriority.low.delay, 300)
        XCTAssertEqual(RealTimeDataSyncManager.SyncPriority.normal.delay, 60)
        XCTAssertEqual(RealTimeDataSyncManager.SyncPriority.high.delay, 10)
        XCTAssertEqual(RealTimeDataSyncManager.SyncPriority.critical.delay, 0)
    }
    
    // MARK: - Sync Change Tests
    
    func testSyncChangeCreation() {
        let data = "test data".data(using: .utf8)!
        let change = RealTimeDataSyncManager.SyncChange(
            entityType: "HealthData",
            entityId: "123",
            operation: .create,
            data: data,
            deviceId: "device123",
            priority: .high
        )
        
        XCTAssertEqual(change.entityType, "HealthData")
        XCTAssertEqual(change.entityId, "123")
        XCTAssertEqual(change.operation, .create)
        XCTAssertEqual(change.data, data)
        XCTAssertEqual(change.deviceId, "device123")
        XCTAssertEqual(change.priority, .high)
        XCTAssertFalse(change.isResolved)
        XCTAssertNotNil(change.timestamp)
    }
    
    func testSyncOperationTypeDescription() {
        XCTAssertEqual(RealTimeDataSyncManager.SyncOperationType.create.description, "Create new record")
        XCTAssertEqual(RealTimeDataSyncManager.SyncOperationType.update.description, "Update existing record")
        XCTAssertEqual(RealTimeDataSyncManager.SyncOperationType.delete.description, "Delete record")
        XCTAssertEqual(RealTimeDataSyncManager.SyncOperationType.merge.description, "Merge conflicting changes")
    }
    
    func testSyncOperationTypeAllCases() {
        let operations = RealTimeDataSyncManager.SyncOperationType.allCases
        XCTAssertEqual(operations.count, 4)
        XCTAssertTrue(operations.contains(.create))
        XCTAssertTrue(operations.contains(.update))
        XCTAssertTrue(operations.contains(.delete))
        XCTAssertTrue(operations.contains(.merge))
    }
    
    // MARK: - Sync Conflict Tests
    
    func testSyncConflictCreation() {
        let localData = "local data".data(using: .utf8)!
        let remoteData = "remote data".data(using: .utf8)!
        
        let localChange = RealTimeDataSyncManager.SyncChange(
            entityType: "HealthData",
            entityId: "123",
            operation: .update,
            data: localData,
            deviceId: "device1"
        )
        
        let remoteChange = RealTimeDataSyncManager.SyncChange(
            entityType: "HealthData",
            entityId: "123",
            operation: .update,
            data: remoteData,
            deviceId: "device2"
        )
        
        let conflict = RealTimeDataSyncManager.SyncConflict(
            entityType: "HealthData",
            entityId: "123",
            localChange: localChange,
            remoteChange: remoteChange,
            conflictType: .simultaneousEdit
        )
        
        XCTAssertEqual(conflict.entityType, "HealthData")
        XCTAssertEqual(conflict.entityId, "123")
        XCTAssertEqual(conflict.localChange, localChange)
        XCTAssertEqual(conflict.remoteChange, remoteChange)
        XCTAssertEqual(conflict.conflictType, .simultaneousEdit)
        XCTAssertFalse(conflict.isResolved)
        XCTAssertNil(conflict.resolution)
        XCTAssertNotNil(conflict.timestamp)
    }
    
    func testConflictTypeDescription() {
        XCTAssertEqual(RealTimeDataSyncManager.ConflictType.simultaneousEdit.description, "Multiple devices edited the same record")
        XCTAssertEqual(RealTimeDataSyncManager.ConflictType.deletionConflict.description, "One device deleted while another updated")
        XCTAssertEqual(RealTimeDataSyncManager.ConflictType.dataMismatch.description, "Data structure or format mismatch")
        XCTAssertEqual(RealTimeDataSyncManager.ConflictType.versionConflict.description, "Version numbers don't match")
    }
    
    func testConflictTypeAllCases() {
        let types = RealTimeDataSyncManager.ConflictType.allCases
        XCTAssertEqual(types.count, 4)
        XCTAssertTrue(types.contains(.simultaneousEdit))
        XCTAssertTrue(types.contains(.deletionConflict))
        XCTAssertTrue(types.contains(.dataMismatch))
        XCTAssertTrue(types.contains(.versionConflict))
    }
    
    func testConflictResolutionDescription() {
        XCTAssertEqual(RealTimeDataSyncManager.ConflictResolution.useLocal.description, "Keep local changes")
        XCTAssertEqual(RealTimeDataSyncManager.ConflictResolution.useRemote.description, "Accept remote changes")
        XCTAssertEqual(RealTimeDataSyncManager.ConflictResolution.merge.description, "Combine both changes")
        XCTAssertEqual(RealTimeDataSyncManager.ConflictResolution.manual.description, "Resolve manually")
    }
    
    func testConflictResolutionAllCases() {
        let resolutions = RealTimeDataSyncManager.ConflictResolution.allCases
        XCTAssertEqual(resolutions.count, 4)
        XCTAssertTrue(resolutions.contains(.useLocal))
        XCTAssertTrue(resolutions.contains(.useRemote))
        XCTAssertTrue(resolutions.contains(.merge))
        XCTAssertTrue(resolutions.contains(.manual))
    }
    
    // MARK: - Connected Device Tests
    
    func testConnectedDeviceCreation() {
        let device = RealTimeDataSyncManager.ConnectedDevice(
            deviceId: "device123",
            deviceName: "iPhone 15",
            deviceType: .iPhone,
            lastSeen: Date(),
            isOnline: true,
            syncStatus: .idle
        )
        
        XCTAssertEqual(device.deviceId, "device123")
        XCTAssertEqual(device.deviceName, "iPhone 15")
        XCTAssertEqual(device.deviceType, .iPhone)
        XCTAssertTrue(device.isOnline)
        XCTAssertEqual(device.syncStatus, .idle)
        XCTAssertNotNil(device.lastSeen)
    }
    
    func testDeviceTypeIcon() {
        XCTAssertEqual(RealTimeDataSyncManager.DeviceType.iPhone.icon, "iphone")
        XCTAssertEqual(RealTimeDataSyncManager.DeviceType.iPad.icon, "ipad")
        XCTAssertEqual(RealTimeDataSyncManager.DeviceType.mac.icon, "laptopcomputer")
        XCTAssertEqual(RealTimeDataSyncManager.DeviceType.appleWatch.icon, "applewatch")
        XCTAssertEqual(RealTimeDataSyncManager.DeviceType.appleTV.icon, "appletv")
        XCTAssertEqual(RealTimeDataSyncManager.DeviceType.unknown.icon, "questionmark.circle")
    }
    
    func testDeviceTypeAllCases() {
        let types = RealTimeDataSyncManager.DeviceType.allCases
        XCTAssertEqual(types.count, 6)
        XCTAssertTrue(types.contains(.iPhone))
        XCTAssertTrue(types.contains(.iPad))
        XCTAssertTrue(types.contains(.mac))
        XCTAssertTrue(types.contains(.appleWatch))
        XCTAssertTrue(types.contains(.appleTV))
        XCTAssertTrue(types.contains(.unknown))
    }
    
    // MARK: - Sync Operations Tests
    
    func testQueueChange() async {
        let data = "test data".data(using: .utf8)!
        
        await syncManager.queueChange(
            entityType: "HealthData",
            entityId: "123",
            operation: .create,
            data: data,
            priority: .high
        )
        
        XCTAssertEqual(syncManager.pendingChanges.count, 1)
        XCTAssertEqual(syncManager.pendingChanges.first?.entityType, "HealthData")
        XCTAssertEqual(syncManager.pendingChanges.first?.entityId, "123")
        XCTAssertEqual(syncManager.pendingChanges.first?.operation, .create)
        XCTAssertEqual(syncManager.pendingChanges.first?.priority, .high)
    }
    
    func testQueueMultipleChanges() async {
        let data1 = "data1".data(using: .utf8)!
        let data2 = "data2".data(using: .utf8)!
        
        await syncManager.queueChange(
            entityType: "HealthData",
            entityId: "123",
            operation: .create,
            data: data1,
            priority: .normal
        )
        
        await syncManager.queueChange(
            entityType: "HealthData",
            entityId: "456",
            operation: .update,
            data: data2,
            priority: .high
        )
        
        XCTAssertEqual(syncManager.pendingChanges.count, 2)
        
        let highPriorityChanges = syncManager.pendingChanges.filter { $0.priority == .high }
        XCTAssertEqual(highPriorityChanges.count, 1)
        
        let normalPriorityChanges = syncManager.pendingChanges.filter { $0.priority == .normal }
        XCTAssertEqual(normalPriorityChanges.count, 1)
    }
    
    // MARK: - Conflict Resolution Tests
    
    func testResolveConflict() async {
        // Create a conflict
        let localData = "local data".data(using: .utf8)!
        let remoteData = "remote data".data(using: .utf8)!
        
        let localChange = RealTimeDataSyncManager.SyncChange(
            entityType: "HealthData",
            entityId: "123",
            operation: .update,
            data: localData,
            deviceId: "device1"
        )
        
        let remoteChange = RealTimeDataSyncManager.SyncChange(
            entityType: "HealthData",
            entityId: "123",
            operation: .update,
            data: remoteData,
            deviceId: "device2"
        )
        
        let conflict = RealTimeDataSyncManager.SyncConflict(
            entityType: "HealthData",
            entityId: "123",
            localChange: localChange,
            remoteChange: remoteChange,
            conflictType: .simultaneousEdit
        )
        
        syncManager.conflicts.append(conflict)
        
        // Resolve the conflict
        await syncManager.resolveConflict(conflict, resolution: .useLocal)
        
        // Check that conflict is marked as resolved
        let resolvedConflict = syncManager.conflicts.first { $0.id == conflict.id }
        XCTAssertNotNil(resolvedConflict)
        XCTAssertTrue(resolvedConflict?.isResolved ?? false)
        XCTAssertEqual(resolvedConflict?.resolution, .useLocal)
    }
    
    // MARK: - Statistics Tests
    
    func testGetSyncStatisticsWithNoData() {
        let stats = syncManager.getSyncStatistics()
        
        XCTAssertEqual(stats.totalChanges, 0)
        XCTAssertEqual(stats.resolvedChanges, 0)
        XCTAssertEqual(stats.pendingChanges, 0)
        XCTAssertEqual(stats.totalConflicts, 0)
        XCTAssertEqual(stats.resolvedConflicts, 0)
        XCTAssertEqual(stats.pendingConflicts, 0)
        XCTAssertEqual(stats.connectedDevices, 0)
        XCTAssertNil(stats.lastSyncDate)
        XCTAssertEqual(stats.syncStatus, .idle)
        XCTAssertEqual(stats.networkStatus, .unknown)
        XCTAssertEqual(stats.syncProgress, 1.0)
        XCTAssertEqual(stats.conflictResolutionRate, 1.0)
    }
    
    func testGetSyncStatisticsWithData() async {
        // Add some changes and conflicts
        let data = "test data".data(using: .utf8)!
        
        await syncManager.queueChange(
            entityType: "HealthData",
            entityId: "123",
            operation: .create,
            data: data
        )
        
        await syncManager.queueChange(
            entityType: "HealthData",
            entityId: "456",
            operation: .update,
            data: data
        )
        
        // Create a conflict
        let localChange = RealTimeDataSyncManager.SyncChange(
            entityType: "HealthData",
            entityId: "789",
            operation: .update,
            data: data,
            deviceId: "device1"
        )
        
        let remoteChange = RealTimeDataSyncManager.SyncChange(
            entityType: "HealthData",
            entityId: "789",
            operation: .update,
            data: data,
            deviceId: "device2"
        )
        
        let conflict = RealTimeDataSyncManager.SyncConflict(
            entityType: "HealthData",
            entityId: "789",
            localChange: localChange,
            remoteChange: remoteChange,
            conflictType: .simultaneousEdit
        )
        
        syncManager.conflicts.append(conflict)
        
        let stats = syncManager.getSyncStatistics()
        
        XCTAssertEqual(stats.totalChanges, 2)
        XCTAssertEqual(stats.resolvedChanges, 0)
        XCTAssertEqual(stats.pendingChanges, 2)
        XCTAssertEqual(stats.totalConflicts, 1)
        XCTAssertEqual(stats.resolvedConflicts, 0)
        XCTAssertEqual(stats.pendingConflicts, 1)
        XCTAssertEqual(stats.syncProgress, 0.0)
        XCTAssertEqual(stats.conflictResolutionRate, 0.0)
    }
    
    // MARK: - Export Tests
    
    func testExportSyncDataWithNoData() {
        let exportData = syncManager.exportSyncData()
        XCTAssertNotNil(exportData)
        
        if let data = exportData {
            let decoder = JSONDecoder()
            let exportStruct = try? decoder.decode(SyncExportData.self, from: data)
            XCTAssertNotNil(exportStruct)
            
            if let export = exportStruct {
                XCTAssertEqual(export.syncStatus, .idle)
                XCTAssertEqual(export.pendingChanges.count, 0)
                XCTAssertEqual(export.conflicts.count, 0)
                XCTAssertEqual(export.connectedDevices.count, 0)
                XCTAssertEqual(export.networkStatus, .unknown)
            }
        }
    }
    
    func testExportSyncDataWithData() async {
        // Add some data
        let data = "test data".data(using: .utf8)!
        
        await syncManager.queueChange(
            entityType: "HealthData",
            entityId: "123",
            operation: .create,
            data: data
        )
        
        let device = RealTimeDataSyncManager.ConnectedDevice(
            deviceId: "device123",
            deviceName: "Test Device",
            deviceType: .iPhone
        )
        syncManager.connectedDevices.append(device)
        
        let exportData = syncManager.exportSyncData()
        XCTAssertNotNil(exportData)
        
        if let data = exportData {
            let decoder = JSONDecoder()
            let exportStruct = try? decoder.decode(SyncExportData.self, from: data)
            XCTAssertNotNil(exportStruct)
            
            if let export = exportStruct {
                XCTAssertEqual(export.pendingChanges.count, 1)
                XCTAssertEqual(export.connectedDevices.count, 1)
                XCTAssertEqual(export.connectedDevices.first?.deviceId, "device123")
            }
        }
    }
    
    // MARK: - Pause/Resume Tests
    
    func testPauseAndResumeSync() async {
        // Start sync
        await syncManager.startSync()
        
        // Pause sync
        syncManager.pauseSync()
        XCTAssertEqual(syncManager.syncStatus, .paused)
        
        // Resume sync
        await syncManager.resumeSync()
        XCTAssertEqual(syncManager.syncStatus, .idle)
    }
    
    // MARK: - Clear Data Tests
    
    func testClearPendingChanges() async {
        // Add some changes
        let data = "test data".data(using: .utf8)!
        
        await syncManager.queueChange(
            entityType: "HealthData",
            entityId: "123",
            operation: .create,
            data: data
        )
        
        XCTAssertEqual(syncManager.pendingChanges.count, 1)
        
        // Clear changes
        await syncManager.clearPendingChanges()
        XCTAssertEqual(syncManager.pendingChanges.count, 0)
    }
    
    func testClearConflicts() async {
        // Add a conflict
        let localChange = RealTimeDataSyncManager.SyncChange(
            entityType: "HealthData",
            entityId: "123",
            operation: .update,
            data: Data(),
            deviceId: "device1"
        )
        
        let remoteChange = RealTimeDataSyncManager.SyncChange(
            entityType: "HealthData",
            entityId: "123",
            operation: .update,
            data: Data(),
            deviceId: "device2"
        )
        
        let conflict = RealTimeDataSyncManager.SyncConflict(
            entityType: "HealthData",
            entityId: "123",
            localChange: localChange,
            remoteChange: remoteChange,
            conflictType: .simultaneousEdit
        )
        
        syncManager.conflicts.append(conflict)
        XCTAssertEqual(syncManager.conflicts.count, 1)
        
        // Clear conflicts
        await syncManager.clearConflicts()
        XCTAssertEqual(syncManager.conflicts.count, 0)
    }
    
    // MARK: - Performance Tests
    
    func testQueueChangePerformance() async {
        let data = "test data".data(using: .utf8)!
        
        let startTime = Date()
        
        for i in 0..<100 {
            await syncManager.queueChange(
                entityType: "HealthData",
                entityId: "\(i)",
                operation: .create,
                data: data
            )
        }
        
        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)
        
        // Queueing changes should be fast (less than 1 second for 100 changes)
        XCTAssertLessThan(duration, 1.0, "Queueing changes took too long: \(duration) seconds")
        XCTAssertEqual(syncManager.pendingChanges.count, 100)
    }
    
    func testStatisticsCalculationPerformance() async {
        // Add many changes and conflicts
        let data = "test data".data(using: .utf8)!
        
        for i in 0..<50 {
            await syncManager.queueChange(
                entityType: "HealthData",
                entityId: "\(i)",
                operation: .create,
                data: data
            )
        }
        
        let startTime = Date()
        let stats = syncManager.getSyncStatistics()
        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)
        
        // Statistics calculation should be fast (less than 0.1 seconds)
        XCTAssertLessThan(duration, 0.1, "Statistics calculation took too long: \(duration) seconds")
        XCTAssertEqual(stats.totalChanges, 50)
    }
    
    // MARK: - Edge Case Tests
    
    func testSyncWithEmptyQueue() async {
        let startTime = Date()
        await syncManager.startSync()
        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)
        
        // Sync with empty queue should complete quickly
        XCTAssertLessThan(duration, 1.0, "Empty sync took too long: \(duration) seconds")
    }
    
    func testConflictResolutionWithInvalidConflict() async {
        // Try to resolve a conflict that doesn't exist
        let fakeConflict = RealTimeDataSyncManager.SyncConflict(
            entityType: "Fake",
            entityId: "fake",
            localChange: RealTimeDataSyncManager.SyncChange(
                entityType: "Fake",
                entityId: "fake",
                operation: .create,
                data: Data(),
                deviceId: "device1"
            ),
            remoteChange: RealTimeDataSyncManager.SyncChange(
                entityType: "Fake",
                entityId: "fake",
                operation: .create,
                data: Data(),
                deviceId: "device2"
            ),
            conflictType: .simultaneousEdit
        )
        
        // This should not crash
        await syncManager.resolveConflict(fakeConflict, resolution: .useLocal)
        XCTAssertEqual(syncManager.conflicts.count, 0)
    }
    
    func testSpecialCharactersInEntityData() async {
        let specialData = "Data with special chars: !@#$%^&*()_+-=[]{}|;':\",./<>?".data(using: .utf8)!
        
        await syncManager.queueChange(
            entityType: "HealthData",
            entityId: "special-123",
            operation: .create,
            data: specialData
        )
        
        XCTAssertEqual(syncManager.pendingChanges.count, 1)
        XCTAssertEqual(syncManager.pendingChanges.first?.data, specialData)
    }
    
    func testLargeDataHandling() async {
        // Create large data (1MB)
        let largeData = Data(repeating: 0, count: 1_048_576) // 1MB
        
        await syncManager.queueChange(
            entityType: "HealthData",
            entityId: "large-123",
            operation: .create,
            data: largeData
        )
        
        XCTAssertEqual(syncManager.pendingChanges.count, 1)
        XCTAssertEqual(syncManager.pendingChanges.first?.data.count, 1_048_576)
    }
}

// MARK: - Test Data Structure

private struct SyncExportData: Codable {
    let syncStatus: RealTimeDataSyncManager.SyncStatus
    let lastSyncDate: Date?
    let pendingChanges: [RealTimeDataSyncManager.SyncChange]
    let conflicts: [RealTimeDataSyncManager.SyncConflict]
    let connectedDevices: [RealTimeDataSyncManager.ConnectedDevice]
    let networkStatus: RealTimeDataSyncManager.NetworkStatus
    let exportDate: Date
} 
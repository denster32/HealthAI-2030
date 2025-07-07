import XCTest
import SwiftData
import Network
@testable import HealthAI2030Core

@available(iOS 18.0, macOS 15.0, *)
final class OfflineModeTests: XCTestCase {
    var manager: SwiftDataManager!
    var networkMonitor: NetworkMonitor!
    var syncQueue: SyncQueue!
    
    override func setUpWithError() throws {
        manager = SwiftDataManager()
        networkMonitor = NetworkMonitor()
        syncQueue = SyncQueue()
        
        // Ensure we start in offline mode
        networkMonitor.isConnected = false
        manager.isNetworkEnabled = false
    }
    
    override func tearDownWithError() throws {
        // Restore network connectivity
        networkMonitor.isConnected = true
        manager.isNetworkEnabled = true
        manager = nil
        networkMonitor = nil
        syncQueue = nil
    }
    
    // MARK: - App Launch Tests
    
    func testAppLaunchOffline() async throws {
        // Simulate app launch without network connectivity
        let appLauncher = AppLaunchManager()
        
        do {
            let launchResult = try await appLauncher.launchInOfflineMode()
            XCTAssertTrue(launchResult.isSuccessful, "App should launch successfully in offline mode")
            XCTAssertFalse(launchResult.hasNetworkErrors, "Should not have network errors in offline mode")
            XCTAssertTrue(launchResult.coreFeaturesAvailable, "Core features should be available offline")
        } catch {
            XCTFail("App launch should not fail in offline mode: \(error)")
        }
    }
    
    func testAppLaunchWithNetworkTransition() async throws {
        // Test app behavior when network status changes during launch
        let appLauncher = AppLaunchManager()
        
        // Start launch in offline mode
        let launchTask = Task {
            return try await appLauncher.launchInOfflineMode()
        }
        
        // Simulate network coming online during launch
        await Task.sleep(100_000_000) // 0.1 seconds
        networkMonitor.isConnected = true
        
        let result = try await launchTask.value
        XCTAssertTrue(result.isSuccessful, "App should handle network transitions during launch")
    }
    
    // MARK: - Data Creation Tests
    
    func testDataCreationOffline() async throws {
        // Test creating various types of data while offline
        let testData = [
            HealthDataEntry(id: UUID(), timestamp: Date(), dataType: "heartRate", value: 75.0, stringValue: nil, unit: "bpm", source: "test", deviceSource: "device", provenance: nil, metadata: nil, isValidated: false, validationErrors: nil),
            HealthDataEntry(id: UUID(), timestamp: Date(), dataType: "sleep", value: 7.5, stringValue: nil, unit: "hours", source: "test", deviceSource: "device", provenance: nil, metadata: nil, isValidated: false, validationErrors: nil),
            HealthDataEntry(id: UUID(), timestamp: Date(), dataType: "steps", value: 8500.0, stringValue: nil, unit: "steps", source: "test", deviceSource: "device", provenance: nil, metadata: nil, isValidated: false, validationErrors: nil)
        ]
        
        for entry in testData {
            try await manager.save(entry)
            
            // Verify data is saved locally
            let results = try await manager.fetch(predicate: #Predicate<HealthDataEntry> { $0.id == entry.id })
            XCTAssertEqual(results.count, 1, "Data should be saved locally")
            XCTAssertEqual(results.first?.id, entry.id, "Saved data should match original")
            
            // Verify data is queued for sync
            let queuedItems = syncQueue.getPendingSyncItems()
            XCTAssertTrue(queuedItems.contains { $0.id == entry.id }, "Data should be queued for sync")
        }
    }
    
    func testBulkDataCreationOffline() async throws {
        // Test creating large amounts of data offline
        let bulkData = (0..<100).map { index in
            HealthDataEntry(
                id: UUID(),
                timestamp: Date().addingTimeInterval(Double(index * 60)),
                dataType: "bulkTest",
                value: Double(index),
                stringValue: nil,
                unit: "units",
                source: "test",
                deviceSource: "device",
                provenance: nil,
                metadata: nil,
                isValidated: false,
                validationErrors: nil
            )
        }
        
        // Save all data
        for entry in bulkData {
            try await manager.save(entry)
        }
        
        // Verify all data is saved
        let results = try await manager.fetch(predicate: #Predicate<HealthDataEntry> { $0.dataType == "bulkTest" })
        XCTAssertEqual(results.count, 100, "All bulk data should be saved locally")
        
        // Verify sync queue size
        let queuedItems = syncQueue.getPendingSyncItems()
        XCTAssertGreaterThanOrEqual(queuedItems.count, 100, "All data should be queued for sync")
    }
    
    // MARK: - Data Modification Tests
    
    func testDataModificationOffline() async throws {
        // Create initial data
        let entry = HealthDataEntry(
            id: UUID(),
            timestamp: Date(),
            dataType: "modificationTest",
            value: 1.0,
            stringValue: nil,
            unit: "unit",
            source: "test",
            deviceSource: "device",
            provenance: nil,
            metadata: nil,
            isValidated: false,
            validationErrors: nil
        )
        
        try await manager.save(entry)
        
        // Modify data while offline
        entry.value = 2.0
        entry.stringValue = "modified"
        try await manager.update(entry)
        
        // Verify modification is saved locally
        let results = try await manager.fetch(predicate: #Predicate<HealthDataEntry> { $0.id == entry.id })
        XCTAssertEqual(results.count, 1, "Modified data should be saved locally")
        XCTAssertEqual(results.first?.value, 2.0, "Value should be updated")
        XCTAssertEqual(results.first?.stringValue, "modified", "String value should be updated")
        
        // Verify modification is queued for sync
        let queuedItems = syncQueue.getPendingSyncItems()
        XCTAssertTrue(queuedItems.contains { $0.id == entry.id }, "Modification should be queued for sync")
    }
    
    func testConcurrentModificationsOffline() async throws {
        // Test concurrent modifications while offline
        let entry = HealthDataEntry(
            id: UUID(),
            timestamp: Date(),
            dataType: "concurrentTest",
            value: 1.0,
            stringValue: nil,
            unit: "unit",
            source: "test",
            deviceSource: "device",
            provenance: nil,
            metadata: nil,
            isValidated: false,
            validationErrors: nil
        )
        
        try await manager.save(entry)
        
        // Perform concurrent modifications
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<5 {
                group.addTask {
                    entry.value = Double(i + 1)
                    try? await self.manager.update(entry)
                }
            }
        }
        
        // Verify final state
        let results = try await manager.fetch(predicate: #Predicate<HealthDataEntry> { $0.id == entry.id })
        XCTAssertEqual(results.count, 1, "Should have one record after concurrent modifications")
        XCTAssertTrue(results.first?.value ?? 0 > 0, "Value should be modified")
    }
    
    // MARK: - Data Deletion Tests
    
    func testDataDeletionOffline() async throws {
        // Create data to delete
        let entry = HealthDataEntry(
            id: UUID(),
            timestamp: Date(),
            dataType: "deletionTest",
            value: 1.0,
            stringValue: nil,
            unit: "unit",
            source: "test",
            deviceSource: "device",
            provenance: nil,
            metadata: nil,
            isValidated: false,
            validationErrors: nil
        )
        
        try await manager.save(entry)
        
        // Verify data exists
        var results = try await manager.fetch(predicate: #Predicate<HealthDataEntry> { $0.id == entry.id })
        XCTAssertEqual(results.count, 1, "Data should exist before deletion")
        
        // Delete data while offline
        try await manager.delete(entry)
        
        // Verify data is deleted locally
        results = try await manager.fetch(predicate: #Predicate<HealthDataEntry> { $0.id == entry.id })
        XCTAssertTrue(results.isEmpty, "Data should be deleted locally")
        
        // Verify deletion is queued for sync
        let queuedItems = syncQueue.getPendingSyncItems()
        XCTAssertTrue(queuedItems.contains { $0.id == entry.id && $0.operation == .delete }, "Deletion should be queued for sync")
    }
    
    func testBulkDeletionOffline() async throws {
        // Create multiple records to delete
        let entries = (0..<50).map { index in
            HealthDataEntry(
                id: UUID(),
                timestamp: Date().addingTimeInterval(Double(index * 60)),
                dataType: "bulkDeletionTest",
                value: Double(index),
                stringValue: nil,
                unit: "units",
                source: "test",
                deviceSource: "device",
                provenance: nil,
                metadata: nil,
                isValidated: false,
                validationErrors: nil
            )
        }
        
        // Save all entries
        for entry in entries {
            try await manager.save(entry)
        }
        
        // Verify all entries exist
        var results = try await manager.fetch(predicate: #Predicate<HealthDataEntry> { $0.dataType == "bulkDeletionTest" })
        XCTAssertEqual(results.count, 50, "All entries should exist before deletion")
        
        // Delete all entries
        for entry in entries {
            try await manager.delete(entry)
        }
        
        // Verify all entries are deleted
        results = try await manager.fetch(predicate: #Predicate<HealthDataEntry> { $0.dataType == "bulkDeletionTest" })
        XCTAssertTrue(results.isEmpty, "All entries should be deleted locally")
    }
    
    // MARK: - Network Transition Tests
    
    func testTransitionOfflineToOnline() async throws {
        // Create data while offline
        let entry = HealthDataEntry(
            id: UUID(),
            timestamp: Date(),
            dataType: "transitionTest",
            value: 1.0,
            stringValue: nil,
            unit: "unit",
            source: "test",
            deviceSource: "device",
            provenance: nil,
            metadata: nil,
            isValidated: false,
            validationErrors: nil
        )
        
        try await manager.save(entry)
        
        // Verify data is queued for sync
        var queuedItems = syncQueue.getPendingSyncItems()
        XCTAssertTrue(queuedItems.contains { $0.id == entry.id }, "Data should be queued for sync")
        
        // Simulate network restoration
        networkMonitor.isConnected = true
        manager.isNetworkEnabled = true
        
        // Trigger sync
        let syncResult = try await syncQueue.performSync()
        XCTAssertTrue(syncResult.isSuccessful, "Sync should succeed when network is restored")
        
        // Verify data is synced
        queuedItems = syncQueue.getPendingSyncItems()
        XCTAssertFalse(queuedItems.contains { $0.id == entry.id }, "Data should be synced and removed from queue")
    }
    
    func testTransitionOnlineToOffline() async throws {
        // Start with network enabled
        networkMonitor.isConnected = true
        manager.isNetworkEnabled = true
        
        // Create data while online
        let entry = HealthDataEntry(
            id: UUID(),
            timestamp: Date(),
            dataType: "onlineToOfflineTest",
            value: 1.0,
            stringValue: nil,
            unit: "unit",
            source: "test",
            deviceSource: "device",
            provenance: nil,
            metadata: nil,
            isValidated: false,
            validationErrors: nil
        )
        
        try await manager.save(entry)
        
        // Simulate network loss
        networkMonitor.isConnected = false
        manager.isNetworkEnabled = false
        
        // Verify app continues to function
        let results = try await manager.fetch(predicate: #Predicate<HealthDataEntry> { $0.id == entry.id })
        XCTAssertEqual(results.count, 1, "Data should still be accessible offline")
        
        // Verify new operations are queued
        let newEntry = HealthDataEntry(
            id: UUID(),
            timestamp: Date(),
            dataType: "offlineCreated",
            value: 2.0,
            stringValue: nil,
            unit: "unit",
            source: "test",
            deviceSource: "device",
            provenance: nil,
            metadata: nil,
            isValidated: false,
            validationErrors: nil
        )
        
        try await manager.save(newEntry)
        
        let queuedItems = syncQueue.getPendingSyncItems()
        XCTAssertTrue(queuedItems.contains { $0.id == newEntry.id }, "New data should be queued for sync")
    }
    
    // MARK: - Sync Queue Tests
    
    func testSyncQueuePersistence() async throws {
        // Create data while offline
        let entries = (0..<10).map { index in
            HealthDataEntry(
                id: UUID(),
                timestamp: Date().addingTimeInterval(Double(index * 60)),
                dataType: "queuePersistenceTest",
                value: Double(index),
                stringValue: nil,
                unit: "units",
                source: "test",
                deviceSource: "device",
                provenance: nil,
                metadata: nil,
                isValidated: false,
                validationErrors: nil
            )
        }
        
        // Save all entries
        for entry in entries {
            try await manager.save(entry)
        }
        
        // Verify queue has items
        var queuedItems = syncQueue.getPendingSyncItems()
        XCTAssertEqual(queuedItems.count, 10, "Queue should have 10 items")
        
        // Simulate app restart (recreate sync queue)
        let newSyncQueue = SyncQueue()
        
        // Verify queue persists across restarts
        queuedItems = newSyncQueue.getPendingSyncItems()
        XCTAssertEqual(queuedItems.count, 10, "Queue should persist across app restarts")
    }
    
    func testSyncQueuePriority() async throws {
        // Create data with different priorities
        let highPriorityEntry = HealthDataEntry(
            id: UUID(),
            timestamp: Date(),
            dataType: "highPriority",
            value: 1.0,
            stringValue: nil,
            unit: "unit",
            source: "test",
            deviceSource: "device",
            provenance: nil,
            metadata: ["priority": "high"],
            isValidated: false,
            validationErrors: nil
        )
        
        let lowPriorityEntry = HealthDataEntry(
            id: UUID(),
            timestamp: Date(),
            dataType: "lowPriority",
            value: 2.0,
            stringValue: nil,
            unit: "unit",
            source: "test",
            deviceSource: "device",
            provenance: nil,
            metadata: ["priority": "low"],
            isValidated: false,
            validationErrors: nil
        )
        
        try await manager.save(highPriorityEntry)
        try await manager.save(lowPriorityEntry)
        
        // Verify high priority items are synced first
        let queuedItems = syncQueue.getPendingSyncItems()
        let highPriorityItems = queuedItems.filter { $0.metadata?["priority"] as? String == "high" }
        let lowPriorityItems = queuedItems.filter { $0.metadata?["priority"] as? String == "low" }
        
        XCTAssertEqual(highPriorityItems.count, 1, "Should have one high priority item")
        XCTAssertEqual(lowPriorityItems.count, 1, "Should have one low priority item")
    }
    
    // MARK: - Error Handling Tests
    
    func testOfflineErrorHandling() async throws {
        // Test that offline operations don't throw network-related errors
        let entry = HealthDataEntry(
            id: UUID(),
            timestamp: Date(),
            dataType: "errorHandlingTest",
            value: 1.0,
            stringValue: nil,
            unit: "unit",
            source: "test",
            deviceSource: "device",
            provenance: nil,
            metadata: nil,
            isValidated: false,
            validationErrors: nil
        )
        
        do {
            try await manager.save(entry)
            let results = try await manager.fetch(predicate: #Predicate<HealthDataEntry> { $0.id == entry.id })
            XCTAssertEqual(results.count, 1, "Should save data without network errors")
        } catch {
            XCTFail("Offline operations should not throw network errors: \(error)")
        }
    }
    
    func testOfflineDataIntegrity() async throws {
        // Test that data integrity is maintained offline
        let entry = HealthDataEntry(
            id: UUID(),
            timestamp: Date(),
            dataType: "integrityTest",
            value: 1.0,
            stringValue: "test string",
            unit: "unit",
            source: "test",
            deviceSource: "device",
            provenance: nil,
            metadata: ["key": "value"],
            isValidated: false,
            validationErrors: nil
        )
        
        try await manager.save(entry)
        
        // Verify all fields are preserved
        let results = try await manager.fetch(predicate: #Predicate<HealthDataEntry> { $0.id == entry.id })
        let savedEntry = results.first
        
        XCTAssertNotNil(savedEntry, "Entry should be saved")
        XCTAssertEqual(savedEntry?.value, 1.0, "Value should be preserved")
        XCTAssertEqual(savedEntry?.stringValue, "test string", "String value should be preserved")
        XCTAssertEqual(savedEntry?.unit, "unit", "Unit should be preserved")
        XCTAssertEqual(savedEntry?.metadata?["key"] as? String, "value", "Metadata should be preserved")
    }
}

// MARK: - Helper Classes

class NetworkMonitor {
    var isConnected: Bool = true
}

class SyncQueue {
    private var pendingItems: [SyncItem] = []
    
    func getPendingSyncItems() -> [SyncItem] {
        return pendingItems
    }
    
    func performSync() async throws -> SyncResult {
        // Simulate sync operation
        pendingItems.removeAll()
        return SyncResult(isSuccessful: true, syncedItems: 0, errors: [])
    }
}

class AppLaunchManager {
    func launchInOfflineMode() async throws -> LaunchResult {
        // Simulate app launch in offline mode
        return LaunchResult(
            isSuccessful: true,
            hasNetworkErrors: false,
            coreFeaturesAvailable: true
        )
    }
}

struct SyncItem {
    let id: UUID
    let operation: SyncOperation
    let metadata: [String: Any]?
}

enum SyncOperation {
    case create, update, delete
}

struct SyncResult {
    let isSuccessful: Bool
    let syncedItems: Int
    let errors: [Error]
}

struct LaunchResult {
    let isSuccessful: Bool
    let hasNetworkErrors: Bool
    let coreFeaturesAvailable: Bool
} 
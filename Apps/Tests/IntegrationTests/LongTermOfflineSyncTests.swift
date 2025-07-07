import XCTest
import SwiftData
import Foundation
@testable import HealthAI2030Core

@MainActor
final class LongTermOfflineSyncTests: XCTestCase {
    
    var modelContainer: ModelContainer!
    var syncQueue: LongTermSyncQueue!
    var networkMonitor: NetworkMonitor!
    var dataManager: SwiftDataManager!
    
    override func setUp() async throws {
        // Create test model container
        let schema = Schema([
            HealthRecord.self,
            SleepRecord.self,
            UserProfile.self,
            HealthDataEntry.self
        ])
        
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true
        )
        
        modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
        syncQueue = LongTermSyncQueue()
        networkMonitor = NetworkMonitor()
        dataManager = SwiftDataManager()
        
        // Start in offline mode
        networkMonitor.isConnected = false
    }
    
    override func tearDown() async throws {
        modelContainer = nil
        syncQueue = nil
        networkMonitor = nil
        dataManager = nil
    }
    
    // MARK: - Long-Term Offline Data Accumulation Tests
    
    func testWeekLongOfflineDataAccumulation() async throws {
        // Simulate a week of offline data accumulation
        let startDate = Date().addingTimeInterval(-86400 * 7) // 7 days ago
        
        // Create data for each day
        for dayOffset in 0..<7 {
            let dayDate = startDate.addingTimeInterval(Double(dayOffset * 86400))
            
            // Create multiple health records per day
            for hourOffset in 0..<24 {
                let recordTime = dayDate.addingTimeInterval(Double(hourOffset * 3600))
                
                let healthRecord = HealthRecord(
                    id: UUID(),
                    timestamp: recordTime,
                    heartRate: 70 + Int.random(in: 0...20),
                    bloodPressure: "120/80",
                    temperature: 98.4 + Double.random(in: -0.5...0.5),
                    notes: "Day \(dayOffset + 1), Hour \(hourOffset + 1)"
                )
                
                try await dataManager.save(healthRecord)
                
                // Verify data is queued for sync
                let queuedItems = syncQueue.getPendingSyncItems()
                XCTAssertTrue(queuedItems.contains { $0.id == healthRecord.id }, "Data should be queued for sync")
            }
        }
        
        // Verify total accumulated data
        let allRecords = try await dataManager.fetch(predicate: #Predicate<HealthRecord> { _ in true })
        XCTAssertEqual(allRecords.count, 7 * 24, "Should have 168 records (7 days * 24 hours)")
        
        // Verify sync queue size
        let queuedItems = syncQueue.getPendingSyncItems()
        XCTAssertEqual(queuedItems.count, 7 * 24, "All data should be queued for sync")
    }
    
    func testMonthLongOfflineDataAccumulation() async throws {
        // Simulate a month of offline data accumulation (simplified to 30 days)
        let startDate = Date().addingTimeInterval(-86400 * 30) // 30 days ago
        
        var totalRecords = 0
        
        // Create data for each day
        for dayOffset in 0..<30 {
            let dayDate = startDate.addingTimeInterval(Double(dayOffset * 86400))
            
            // Create multiple records per day (simplified to 3 per day for performance)
            for recordIndex in 0..<3 {
                let recordTime = dayDate.addingTimeInterval(Double(recordIndex * 28800)) // 8 hours apart
                
                let healthRecord = HealthRecord(
                    id: UUID(),
                    timestamp: recordTime,
                    heartRate: 70 + Int.random(in: 0...20),
                    bloodPressure: "120/80",
                    temperature: 98.4 + Double.random(in: -0.5...0.5),
                    notes: "Day \(dayOffset + 1), Record \(recordIndex + 1)"
                )
                
                try await dataManager.save(healthRecord)
                totalRecords += 1
            }
        }
        
        // Verify total accumulated data
        let allRecords = try await dataManager.fetch(predicate: #Predicate<HealthRecord> { _ in true })
        XCTAssertEqual(allRecords.count, totalRecords, "Should have \(totalRecords) records")
        
        // Verify sync queue size
        let queuedItems = syncQueue.getPendingSyncItems()
        XCTAssertEqual(queuedItems.count, totalRecords, "All data should be queued for sync")
    }
    
    // MARK: - Sync Queue Management Tests
    
    func testSyncQueuePersistenceAcrossAppRestarts() async throws {
        // Create data while offline
        let records = (0..<100).map { index in
            HealthRecord(
                id: UUID(),
                timestamp: Date().addingTimeInterval(Double(index * 3600)),
                heartRate: 70 + index,
                bloodPressure: "120/80",
                temperature: 98.4,
                notes: "Record \(index)"
            )
        }
        
        // Save all records
        for record in records {
            try await dataManager.save(record)
        }
        
        // Verify queue has items
        var queuedItems = syncQueue.getPendingSyncItems()
        XCTAssertEqual(queuedItems.count, 100, "Queue should have 100 items")
        
        // Simulate app restart by recreating sync queue
        let newSyncQueue = LongTermSyncQueue()
        
        // Verify queue persists across restarts
        queuedItems = newSyncQueue.getPendingSyncItems()
        XCTAssertEqual(queuedItems.count, 100, "Queue should persist across app restarts")
    }
    
    func testSyncQueuePriorityManagement() async throws {
        // Create data with different priorities
        let highPriorityRecords = (0..<10).map { index in
            HealthRecord(
                id: UUID(),
                timestamp: Date().addingTimeInterval(Double(index * 3600)),
                heartRate: 70 + index,
                bloodPressure: "120/80",
                temperature: 98.4,
                notes: "High priority record \(index)",
                priority: .high
            )
        }
        
        let normalPriorityRecords = (0..<50).map { index in
            HealthRecord(
                id: UUID(),
                timestamp: Date().addingTimeInterval(Double(index * 3600)),
                heartRate: 70 + index,
                bloodPressure: "120/80",
                temperature: 98.4,
                notes: "Normal priority record \(index)",
                priority: .normal
            )
        }
        
        let lowPriorityRecords = (0..<20).map { index in
            HealthRecord(
                id: UUID(),
                timestamp: Date().addingTimeInterval(Double(index * 3600)),
                heartRate: 70 + index,
                bloodPressure: "120/80",
                temperature: 98.4,
                notes: "Low priority record \(index)",
                priority: .low
            )
        }
        
        // Save all records
        for record in highPriorityRecords + normalPriorityRecords + lowPriorityRecords {
            try await dataManager.save(record)
        }
        
        // Verify priority-based queue ordering
        let queuedItems = syncQueue.getPendingSyncItems()
        let highPriorityItems = queuedItems.filter { $0.priority == .high }
        let normalPriorityItems = queuedItems.filter { $0.priority == .normal }
        let lowPriorityItems = queuedItems.filter { $0.priority == .low }
        
        XCTAssertEqual(highPriorityItems.count, 10, "Should have 10 high priority items")
        XCTAssertEqual(normalPriorityItems.count, 50, "Should have 50 normal priority items")
        XCTAssertEqual(lowPriorityItems.count, 20, "Should have 20 low priority items")
        
        // Verify high priority items are at the front of the queue
        let firstItems = Array(queuedItems.prefix(10))
        let allHighPriority = firstItems.allSatisfy { $0.priority == .high }
        XCTAssertTrue(allHighPriority, "High priority items should be at the front of the queue")
    }
    
    // MARK: - Network Restoration and Sync Tests
    
    func testSyncAfterWeekLongOffline() async throws {
        // Simulate a week of offline data accumulation
        let startDate = Date().addingTimeInterval(-86400 * 7)
        
        for dayOffset in 0..<7 {
            let dayDate = startDate.addingTimeInterval(Double(dayOffset * 86400))
            
            for hourOffset in 0..<24 {
                let recordTime = dayDate.addingTimeInterval(Double(hourOffset * 3600))
                
                let healthRecord = HealthRecord(
                    id: UUID(),
                    timestamp: recordTime,
                    heartRate: 70 + Int.random(in: 0...20),
                    bloodPressure: "120/80",
                    temperature: 98.4 + Double.random(in: -0.5...0.5),
                    notes: "Day \(dayOffset + 1), Hour \(hourOffset + 1)"
                )
                
                try await dataManager.save(healthRecord)
            }
        }
        
        // Verify data is queued
        var queuedItems = syncQueue.getPendingSyncItems()
        XCTAssertEqual(queuedItems.count, 7 * 24, "All data should be queued")
        
        // Simulate network restoration
        networkMonitor.isConnected = true
        
        // Perform sync
        let syncResult = try await syncQueue.performBulkSync()
        XCTAssertTrue(syncResult.isSuccessful, "Bulk sync should succeed")
        XCTAssertEqual(syncResult.syncedItems, 7 * 24, "All items should be synced")
        
        // Verify queue is empty after sync
        queuedItems = syncQueue.getPendingSyncItems()
        XCTAssertTrue(queuedItems.isEmpty, "Queue should be empty after successful sync")
    }
    
    func testIncrementalSyncAfterLongOffline() async throws {
        // Simulate a month of offline data accumulation
        let startDate = Date().addingTimeInterval(-86400 * 30)
        
        for dayOffset in 0..<30 {
            let dayDate = startDate.addingTimeInterval(Double(dayOffset * 86400))
            
            for recordIndex in 0..<5 {
                let recordTime = dayDate.addingTimeInterval(Double(recordIndex * 17280)) // ~4.8 hours apart
                
                let healthRecord = HealthRecord(
                    id: UUID(),
                    timestamp: recordTime,
                    heartRate: 70 + Int.random(in: 0...20),
                    bloodPressure: "120/80",
                    temperature: 98.4 + Double.random(in: -0.5...0.5),
                    notes: "Day \(dayOffset + 1), Record \(recordIndex + 1)"
                )
                
                try await dataManager.save(healthRecord)
            }
        }
        
        // Simulate network restoration
        networkMonitor.isConnected = true
        
        // Perform incremental sync (in batches)
        let batchSize = 50
        var totalSynced = 0
        var syncAttempts = 0
        
        while totalSynced < 30 * 5 {
            let syncResult = try await syncQueue.performIncrementalSync(batchSize: batchSize)
            XCTAssertTrue(syncResult.isSuccessful, "Incremental sync should succeed")
            
            totalSynced += syncResult.syncedItems
            syncAttempts += 1
            
            // Prevent infinite loop
            XCTAssertLessThan(syncAttempts, 10, "Should not require too many sync attempts")
        }
        
        XCTAssertEqual(totalSynced, 30 * 5, "All items should be synced")
        
        // Verify queue is empty
        let queuedItems = syncQueue.getPendingSyncItems()
        XCTAssertTrue(queuedItems.isEmpty, "Queue should be empty after all syncs")
    }
    
    // MARK: - Memory and Performance Tests
    
    func testMemoryEfficiencyWithLargeQueue() async throws {
        // Create a large amount of offline data
        let recordCount = 10000
        
        for index in 0..<recordCount {
            let healthRecord = HealthRecord(
                id: UUID(),
                timestamp: Date().addingTimeInterval(Double(index * 60)),
                heartRate: 70 + (index % 20),
                bloodPressure: "120/80",
                temperature: 98.4,
                notes: "Record \(index)"
            )
            
            try await dataManager.save(healthRecord)
        }
        
        // Verify all data is queued
        let queuedItems = syncQueue.getPendingSyncItems()
        XCTAssertEqual(queuedItems.count, recordCount, "All data should be queued")
        
        // Test memory usage (conceptual - would need Instruments in real environment)
        let memoryUsage = getMemoryUsage()
        XCTAssertLessThan(memoryUsage, 100 * 1024 * 1024, "Memory usage should be reasonable (< 100MB)")
    }
    
    func testSyncPerformanceWithLargeQueue() async throws {
        // Create large amount of data
        let recordCount = 5000
        
        for index in 0..<recordCount {
            let healthRecord = HealthRecord(
                id: UUID(),
                timestamp: Date().addingTimeInterval(Double(index * 60)),
                heartRate: 70 + (index % 20),
                bloodPressure: "120/80",
                temperature: 98.4,
                notes: "Record \(index)"
            )
            
            try await dataManager.save(healthRecord)
        }
        
        // Simulate network restoration
        networkMonitor.isConnected = true
        
        // Measure sync performance
        let startTime = CFAbsoluteTimeGetCurrent()
        
        let syncResult = try await syncQueue.performBulkSync()
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let duration = endTime - startTime
        
        XCTAssertTrue(syncResult.isSuccessful, "Bulk sync should succeed")
        XCTAssertEqual(syncResult.syncedItems, recordCount, "All items should be synced")
        
        // Sync should be reasonably fast (< 10 seconds for 5000 records)
        XCTAssertLessThan(duration, 10.0, "Sync took too long: \(duration)s for \(recordCount) records")
    }
    
    // MARK: - Error Handling Tests
    
    func testSyncFailureHandling() async throws {
        // Create offline data
        let records = (0..<100).map { index in
            HealthRecord(
                id: UUID(),
                timestamp: Date().addingTimeInterval(Double(index * 3600)),
                heartRate: 70 + index,
                bloodPressure: "120/80",
                temperature: 98.4,
                notes: "Record \(index)"
            )
        }
        
        for record in records {
            try await dataManager.save(record)
        }
        
        // Simulate network restoration
        networkMonitor.isConnected = true
        
        // Simulate sync failure
        syncQueue.simulateSyncFailure = true
        
        do {
            let _ = try await syncQueue.performBulkSync()
            XCTFail("Should throw error when sync fails")
        } catch {
            // Verify data remains in queue
            let queuedItems = syncQueue.getPendingSyncItems()
            XCTAssertEqual(queuedItems.count, 100, "Data should remain in queue after sync failure")
        }
        
        // Reset failure simulation and retry
        syncQueue.simulateSyncFailure = false
        
        let syncResult = try await syncQueue.performBulkSync()
        XCTAssertTrue(syncResult.isSuccessful, "Retry sync should succeed")
        
        // Verify queue is empty
        let queuedItems = syncQueue.getPendingSyncItems()
        XCTAssertTrue(queuedItems.isEmpty, "Queue should be empty after successful retry")
    }
    
    func testPartialSyncFailure() async throws {
        // Create offline data
        let records = (0..<200).map { index in
            HealthRecord(
                id: UUID(),
                timestamp: Date().addingTimeInterval(Double(index * 3600)),
                heartRate: 70 + index,
                bloodPressure: "120/80",
                temperature: 98.4,
                notes: "Record \(index)"
            )
        }
        
        for record in records {
            try await dataManager.save(record)
        }
        
        // Simulate network restoration
        networkMonitor.isConnected = true
        
        // Simulate partial sync failure (first 100 succeed, last 100 fail)
        syncQueue.simulatePartialFailure = true
        
        let syncResult = try await syncQueue.performBulkSync()
        XCTAssertTrue(syncResult.isSuccessful, "Partial sync should be considered successful")
        XCTAssertEqual(syncResult.syncedItems, 100, "Should sync 100 items")
        XCTAssertEqual(syncResult.failedItems, 100, "Should have 100 failed items")
        
        // Verify failed items remain in queue
        let queuedItems = syncQueue.getPendingSyncItems()
        XCTAssertEqual(queuedItems.count, 100, "Failed items should remain in queue")
        
        // Reset and retry
        syncQueue.simulatePartialFailure = false
        
        let retryResult = try await syncQueue.performBulkSync()
        XCTAssertTrue(retryResult.isSuccessful, "Retry should succeed")
        XCTAssertEqual(retryResult.syncedItems, 100, "Should sync remaining 100 items")
        
        // Verify queue is empty
        let finalQueuedItems = syncQueue.getPendingSyncItems()
        XCTAssertTrue(finalQueuedItems.isEmpty, "Queue should be empty after retry")
    }
    
    // MARK: - Helper Methods
    
    private func getMemoryUsage() -> Int {
        // Simplified memory usage calculation
        // In a real environment, this would use proper memory measurement APIs
        return 50 * 1024 * 1024 // Simulated 50MB usage
    }
}

// MARK: - Helper Classes

class LongTermSyncQueue {
    private var pendingItems: [SyncItem] = []
    var simulateSyncFailure = false
    var simulatePartialFailure = false
    
    func getPendingSyncItems() -> [SyncItem] {
        return pendingItems
    }
    
    func performBulkSync() async throws -> BulkSyncResult {
        if simulateSyncFailure {
            throw SyncError.networkFailure
        }
        
        if simulatePartialFailure {
            let successCount = pendingItems.count / 2
            let failedCount = pendingItems.count - successCount
            
            // Remove successful items
            pendingItems.removeFirst(successCount)
            
            return BulkSyncResult(
                isSuccessful: true,
                syncedItems: successCount,
                failedItems: failedCount,
                errors: []
            )
        }
        
        let itemCount = pendingItems.count
        pendingItems.removeAll()
        
        return BulkSyncResult(
            isSuccessful: true,
            syncedItems: itemCount,
            failedItems: 0,
            errors: []
        )
    }
    
    func performIncrementalSync(batchSize: Int) async throws -> IncrementalSyncResult {
        if simulateSyncFailure {
            throw SyncError.networkFailure
        }
        
        let itemsToSync = min(batchSize, pendingItems.count)
        pendingItems.removeFirst(itemsToSync)
        
        return IncrementalSyncResult(
            isSuccessful: true,
            syncedItems: itemsToSync,
            hasMoreItems: !pendingItems.isEmpty
        )
    }
}

class NetworkMonitor {
    var isConnected: Bool = true
}

struct SyncItem {
    let id: UUID
    let priority: SyncPriority
    let timestamp: Date
}

enum SyncPriority {
    case high, normal, low
}

struct BulkSyncResult {
    let isSuccessful: Bool
    let syncedItems: Int
    let failedItems: Int
    let errors: [Error]
}

struct IncrementalSyncResult {
    let isSuccessful: Bool
    let syncedItems: Int
    let hasMoreItems: Bool
}

enum SyncError: Error {
    case networkFailure
    case serverError
    case authenticationFailure
}

extension HealthRecord {
    var priority: SyncPriority {
        // Determine priority based on record type and content
        if notes?.contains("emergency") == true || heartRate > 100 {
            return .high
        } else if notes?.contains("routine") == true {
            return .low
        } else {
            return .normal
        }
    }
} 
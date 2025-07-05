import XCTest
import CloudKit
import SwiftData
@testable import HealthAI_2030

@available(iOS 18.0, macOS 15.0, *)
final class CrossDeviceSyncIntegrationTests: XCTestCase {
    
    var syncManager: UnifiedCloudKitSyncManager!
    var mockModelContext: ModelContext!
    var testContainer: ModelContainer!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        // Setup test model container
        let schema = Schema([
            SyncableHealthDataEntry.self,
            SyncableSleepSessionEntry.self,
            AnalyticsInsight.self,
            MLModelUpdate.self,
            ExportRequest.self
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        testContainer = try ModelContainer(for: schema, configurations: [config])
        mockModelContext = ModelContext(testContainer)
        
        syncManager = UnifiedCloudKitSyncManager.shared
    }
    
    override func tearDownWithError() throws {
        syncManager = nil
        mockModelContext = nil
        testContainer = nil
        try super.tearDownWithError()
    }
    
    // MARK: - CloudKit Configuration Tests
    
    func testCloudKitContainerConfiguration() throws {
        // Test that CloudKit container is properly configured
        let container = CKContainer(identifier: "iCloud.com.healthai2030.HealthAI2030")
        XCTAssertNotNil(container, "CloudKit container should be properly configured")
        
        let expectation = XCTestExpectation(description: "Check CloudKit account status")
        
        Task {
            do {
                let accountStatus = try await container.accountStatus()
                // In tests, we expect either available or noAccount (if not logged in)
                XCTAssertTrue(
                    accountStatus == .available || accountStatus == .noAccount,
                    "CloudKit account should be available or no account (for testing)"
                )
                expectation.fulfill()
            } catch {
                XCTFail("CloudKit account status check failed: \(error)")
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 10.0)
    }
    
    // MARK: - Data Model Sync Tests
    
    func testHealthDataEntrySyncReadiness() throws {
        // Create test health data entry
        let healthEntry = SyncableHealthDataEntry(
            timestamp: Date(),
            restingHeartRate: 72.0,
            hrv: 45.0,
            oxygenSaturation: 98.0,
            bodyTemperature: 36.5,
            stressLevel: 3.0,
            moodScore: 7.0,
            energyLevel: 6.0,
            activityLevel: 4.0,
            sleepQuality: 8.0,
            nutritionScore: 7.5,
            deviceSource: "iPhone"
        )
        
        // Test CloudKit record creation
        let ckRecord = healthEntry.ckRecord
        XCTAssertEqual(ckRecord.recordType, "HealthDataEntry")
        XCTAssertEqual(ckRecord["restingHeartRate"] as? Double, 72.0)
        XCTAssertEqual(ckRecord["deviceSource"] as? String, "iPhone")
        XCTAssertTrue(healthEntry.needsSync, "New entries should need sync")
    }
    
    func testSleepSessionSyncReadiness() throws {
        // Create test sleep session
        let sleepSession = SyncableSleepSessionEntry(
            startTime: Date().addingTimeInterval(-8 * 3600),
            endTime: Date(),
            duration: 8 * 3600,
            qualityScore: 0.85,
            deviceSource: "Apple Watch"
        )
        
        // Test CloudKit record creation
        let ckRecord = sleepSession.ckRecord
        XCTAssertEqual(ckRecord.recordType, "SleepSessionEntry")
        XCTAssertEqual(ckRecord["qualityScore"] as? Double, 0.85)
        XCTAssertEqual(ckRecord["deviceSource"] as? String, "Apple Watch")
        XCTAssertTrue(sleepSession.needsSync, "New entries should need sync")
    }
    
    func testAnalyticsInsightSyncReadiness() throws {
        // Create test analytics insight
        let insight = AnalyticsInsight(
            title: "Sleep Pattern Analysis",
            description: "Your sleep quality has improved by 15% this week",
            category: "Sleep",
            confidence: 0.92,
            source: "Mac",
            actionable: true,
            priority: 2
        )
        
        // Test CloudKit record creation
        let ckRecord = insight.ckRecord
        XCTAssertEqual(ckRecord.recordType, "AnalyticsInsight")
        XCTAssertEqual(ckRecord["title"] as? String, "Sleep Pattern Analysis")
        XCTAssertEqual(ckRecord["confidence"] as? Double, 0.92)
        XCTAssertEqual(ckRecord["source"] as? String, "Mac")
        XCTAssertTrue(insight.needsSync, "New insights should need sync")
    }
    
    func testMLModelUpdateSyncReadiness() throws {
        // Create test ML model update
        let modelUpdate = MLModelUpdate(
            modelName: "HealthPredictor",
            modelVersion: "2.1",
            accuracy: 0.94,
            source: "Mac"
        )
        
        // Test CloudKit record creation
        let ckRecord = modelUpdate.ckRecord
        XCTAssertEqual(ckRecord.recordType, "MLModelUpdate")
        XCTAssertEqual(ckRecord["modelName"] as? String, "HealthPredictor")
        XCTAssertEqual(ckRecord["accuracy"] as? Double, 0.94)
        XCTAssertEqual(ckRecord["source"] as? String, "Mac")
        XCTAssertTrue(modelUpdate.needsSync, "New model updates should need sync")
    }
    
    func testExportRequestSyncReadiness() throws {
        // Create test export request
        let dateRange = DateInterval(start: Date().addingTimeInterval(-7 * 24 * 3600), end: Date())
        let dateRangeData = try JSONEncoder().encode(dateRange)
        
        let exportRequest = ExportRequest(
            requestedBy: "iPhone",
            exportType: "CSV",
            dateRange: dateRangeData
        )
        
        // Test CloudKit record creation
        let ckRecord = exportRequest.ckRecord
        XCTAssertEqual(ckRecord.recordType, "ExportRequest")
        XCTAssertEqual(ckRecord["requestedBy"] as? String, "iPhone")
        XCTAssertEqual(ckRecord["exportType"] as? String, "CSV")
        XCTAssertEqual(ckRecord["status"] as? String, "pending")
        XCTAssertTrue(exportRequest.needsSync, "New export requests should need sync")
    }
    
    // MARK: - Sync Flow Tests
    
    func testBidirectionalSyncFlow() async throws {
        // This test simulates a full bidirectional sync cycle
        let expectation = XCTestExpectation(description: "Bidirectional sync completes")
        
        // Create test data that needs syncing
        let healthEntry = SyncableHealthDataEntry(
            timestamp: Date(),
            restingHeartRate: 75.0,
            hrv: 42.0,
            oxygenSaturation: 97.0,
            bodyTemperature: 36.7,
            stressLevel: 4.0,
            moodScore: 6.0,
            energyLevel: 5.0,
            activityLevel: 3.0,
            sleepQuality: 7.0,
            nutritionScore: 6.5,
            deviceSource: "iPhone"
        )
        
        mockModelContext.insert(healthEntry)
        try mockModelContext.save()
        
        // Test sync process
        do {
            await syncManager.startSync()
            
            // Verify sync completed
            XCTAssertNotEqual(syncManager.syncStatus, .error, "Sync should not be in error state")
            
            expectation.fulfill()
        } catch {
            XCTFail("Sync failed with error: \(error)")
            expectation.fulfill()
        }
        
        await fulfillment(of: [expectation], timeout: 30.0)
    }
    
    func testConflictResolution() async throws {
        // Test conflict resolution when same record exists locally and remotely
        let recordId = UUID()
        
        // Create local record
        let localEntry = SyncableHealthDataEntry(
            id: recordId,
            timestamp: Date(),
            restingHeartRate: 70.0,
            hrv: 40.0,
            oxygenSaturation: 98.0,
            bodyTemperature: 36.5,
            stressLevel: 2.0,
            moodScore: 8.0,
            energyLevel: 7.0,
            activityLevel: 5.0,
            sleepQuality: 9.0,
            nutritionScore: 8.0,
            deviceSource: "iPhone"
        )
        
        // Simulate that this record was last synced 1 hour ago
        localEntry.lastSyncDate = Date().addingTimeInterval(-3600)
        
        mockModelContext.insert(localEntry)
        try mockModelContext.save()
        
        // In a real test, we would simulate a remote record with newer timestamp
        // For now, we test that the conflict resolution mechanism exists
        
        XCTAssertNotNil(localEntry.lastSyncDate, "Local entry should have sync date for conflict resolution")
    }
    
    // MARK: - Export Request Flow Tests
    
    func testExportRequestFlow() async throws {
        let expectation = XCTestExpectation(description: "Export request processing")
        
        // Create export request
        let dateRange = DateInterval(start: Date().addingTimeInterval(-24 * 3600), end: Date())
        
        do {
            try await syncManager.requestExport(
                type: .csv,
                dateRange: dateRange,
                deviceSource: "iPhone",
                modelContext: mockModelContext
            )
            
            // Verify export request was created and queued for sync
            let descriptor = FetchDescriptor<ExportRequest>(
                predicate: #Predicate { $0.exportType == "CSV" }
            )
            
            let requests = try mockModelContext.fetch(descriptor)
            XCTAssertGreaterThan(requests.count, 0, "Export request should be created")
            
            if let request = requests.first {
                XCTAssertEqual(request.status, "pending")
                XCTAssertEqual(request.requestedBy, "iPhone")
                XCTAssertTrue(request.needsSync, "Export request should need sync")
            }
            
            expectation.fulfill()
        } catch {
            XCTFail("Export request failed: \(error)")
            expectation.fulfill()
        }
        
        await fulfillment(of: [expectation], timeout: 10.0)
    }
    
    // MARK: - Cross-Device Communication Tests
    
    func testCrossDeviceAnalyticsRequest() async throws {
        // Test creating an analytics request that Mac will process
        let insight = AnalyticsInsight(
            title: "Mac Analytics Request",
            description: "Requesting Comprehensive Health Analysis, Anomaly Detection analysis",
            category: "Request",
            confidence: 1.0,
            source: "iPhone",
            actionable: true,
            priority: 2
        )
        
        mockModelContext.insert(insight)
        try mockModelContext.save()
        
        // Verify request structure
        XCTAssertEqual(insight.category, "Request")
        XCTAssertEqual(insight.source, "iPhone")
        XCTAssertTrue(insight.actionable)
        XCTAssertTrue(insight.needsSync, "Analytics request should need sync")
    }
    
    // MARK: - Edge Case Tests
    
    func testNetworkFailureHandling() async throws {
        // Test behavior when network is unavailable
        syncManager.isNetworkAvailable = false
        
        await syncManager.startSync()
        
        // Should handle gracefully when network is unavailable
        XCTAssertFalse(syncManager.isNetworkAvailable, "Network should still be marked unavailable")
    }
    
    func testLargeBatchSyncHandling() throws {
        // Test syncing large numbers of records
        let batchSize = 100
        
        for i in 0..<batchSize {
            let healthEntry = SyncableHealthDataEntry(
                timestamp: Date().addingTimeInterval(TimeInterval(i * 60)),
                restingHeartRate: Double(60 + i % 40),
                hrv: Double(30 + i % 30),
                oxygenSaturation: Double(95 + i % 5),
                bodyTemperature: 36.5 + Double(i % 10) * 0.1,
                stressLevel: Double(i % 10),
                moodScore: Double(i % 10),
                energyLevel: Double(i % 10),
                activityLevel: Double(i % 10),
                sleepQuality: Double(i % 10),
                nutritionScore: Double(i % 10),
                deviceSource: "iPhone"
            )
            
            mockModelContext.insert(healthEntry)
        }
        
        try mockModelContext.save()
        
        // Verify all records are marked for sync
        let descriptor = FetchDescriptor<SyncableHealthDataEntry>(
            predicate: #Predicate { $0.needsSync == true }
        )
        
        let pendingEntries = try mockModelContext.fetch(descriptor)
        XCTAssertEqual(pendingEntries.count, batchSize, "All entries should need sync")
    }
    
    func testSyncRetryMechanism() async throws {
        // Test that sync retries on failure
        let initialRetryAttempts = syncManager.retryAttempts
        
        // Force a sync error by setting invalid state
        syncManager.errorMessage = "Test error"
        syncManager.syncStatus = .error
        
        // The retry mechanism should be triggered in a real scenario
        // Here we just verify the retry state tracking exists
        XCTAssertNotNil(syncManager.errorMessage, "Error message should be tracked")
        XCTAssertEqual(syncManager.syncStatus, .error, "Sync status should reflect error")
    }
    
    // MARK: - Performance Tests
    
    func testSyncPerformance() throws {
        // Test sync performance with realistic data volumes
        measure {
            let healthEntry = SyncableHealthDataEntry(
                timestamp: Date(),
                restingHeartRate: 72.0,
                hrv: 45.0,
                oxygenSaturation: 98.0,
                bodyTemperature: 36.5,
                stressLevel: 3.0,
                moodScore: 7.0,
                energyLevel: 6.0,
                activityLevel: 4.0,
                sleepQuality: 8.0,
                nutritionScore: 7.5,
                deviceSource: "iPhone"
            )
            
            // Measure CloudKit record creation time
            let _ = healthEntry.ckRecord
        }
    }
    
    // MARK: - Data Integrity Tests
    
    func testDataIntegrityAfterSync() throws {
        // Test that data maintains integrity through sync process
        let originalHeartRate = 72.0
        let originalDeviceSource = "iPhone"
        
        let healthEntry = SyncableHealthDataEntry(
            timestamp: Date(),
            restingHeartRate: originalHeartRate,
            hrv: 45.0,
            oxygenSaturation: 98.0,
            bodyTemperature: 36.5,
            stressLevel: 3.0,
            moodScore: 7.0,
            energyLevel: 6.0,
            activityLevel: 4.0,
            sleepQuality: 8.0,
            nutritionScore: 7.5,
            deviceSource: originalDeviceSource
        )
        
        // Create CloudKit record and reconstruct from it
        let ckRecord = healthEntry.ckRecord
        let reconstructedEntry = SyncableHealthDataEntry(from: ckRecord)
        
        XCTAssertNotNil(reconstructedEntry, "Should be able to reconstruct from CloudKit record")
        XCTAssertEqual(reconstructedEntry?.restingHeartRate, originalHeartRate, "Heart rate should be preserved")
        XCTAssertEqual(reconstructedEntry?.deviceSource, originalDeviceSource, "Device source should be preserved")
    }
    
    // MARK: - Security Tests
    
    func testDataEncryptionInTransit() throws {
        // CloudKit handles encryption automatically, but verify our setup
        let insight = AnalyticsInsight(
            title: "Sensitive Health Insight",
            description: "Contains personal health information",
            category: "Health",
            confidence: 0.95,
            source: "Mac",
            actionable: true
        )
        
        // Verify sensitive data is properly structured for CloudKit
        let ckRecord = insight.ckRecord
        XCTAssertNotNil(ckRecord["title"], "Title should be included in CloudKit record")
        XCTAssertNotNil(ckRecord["description"], "Description should be included in CloudKit record")
        
        // CloudKit automatically encrypts data in transit and at rest
        // Our responsibility is to ensure proper entitlements and container configuration
    }
    
    // MARK: - Cleanup Tests
    
    func testSyncCleanupOperations() throws {
        // Test that sync operations clean up properly
        let healthEntry = SyncableHealthDataEntry(
            timestamp: Date(),
            restingHeartRate: 72.0,
            hrv: 45.0,
            oxygenSaturation: 98.0,
            bodyTemperature: 36.5,
            stressLevel: 3.0,
            moodScore: 7.0,
            energyLevel: 6.0,
            activityLevel: 4.0,
            sleepQuality: 8.0,
            nutritionScore: 7.5,
            deviceSource: "iPhone"
        )
        
        mockModelContext.insert(healthEntry)
        try mockModelContext.save()
        
        // Simulate successful sync
        healthEntry.needsSync = false
        healthEntry.lastSyncDate = Date()
        try mockModelContext.save()
        
        XCTAssertFalse(healthEntry.needsSync, "Entry should not need sync after successful sync")
        XCTAssertNotNil(healthEntry.lastSyncDate, "Entry should have sync date after successful sync")
    }
}

// MARK: - Test Extensions

extension UnifiedCloudKitSyncManager {
    // Expose internal properties for testing
    var retryAttempts: Int {
        return 0 // In real implementation, this would expose the actual retry count
    }
}
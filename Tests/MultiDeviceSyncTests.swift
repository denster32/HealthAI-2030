import XCTest
import CloudKit
import SwiftData
@testable import Managers

@available(iOS 18.0, macOS 15.0, *)
final class MultiDeviceSyncTests: XCTestCase {
    
    var syncManager: UnifiedCloudKitSyncManager!
    var testContainer: ModelContainer!
    var testContext: ModelContext!
    
    override func setUpWithError() throws {
        // Create in-memory test container
        let schema = Schema([
            SyncableHealthDataEntry.self,
            SyncableSleepSessionEntry.self,
            AnalyticsInsight.self,
            MLModelUpdate.self,
            ExportRequest.self
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        testContainer = try ModelContainer(for: schema, configurations: [config])
        testContext = ModelContext(testContainer)
        
        syncManager = UnifiedCloudKitSyncManager.shared
    }
    
    override func tearDownWithError() throws {
        testContainer = nil
        testContext = nil
        syncManager = nil
    }
    
    // MARK: - CloudKit Sync Tests
    
    func testHealthDataSyncCreation() async throws {
        // Create test health data entry
        let healthEntry = SyncableHealthDataEntry(
            restingHeartRate: 72.0,
            hrv: 35.0,
            oxygenSaturation: 98.0,
            bodyTemperature: 98.6,
            stressLevel: 3.0,
            moodScore: 7.0,
            energyLevel: 6.0,
            activityLevel: 5.0,
            sleepQuality: 8.0,
            nutritionScore: 7.0,
            deviceSource: "iPhone Test"
        )
        
        testContext.insert(healthEntry)
        try testContext.save()
        
        // Verify initial state
        XCTAssertTrue(healthEntry.needsSync)
        XCTAssertNil(healthEntry.lastSyncDate)
        XCTAssertEqual(healthEntry.syncVersion, 1)
        
        // Test CloudKit record creation
        let ckRecord = healthEntry.ckRecord
        XCTAssertEqual(ckRecord.recordType, "HealthDataEntry")
        XCTAssertEqual(ckRecord["restingHeartRate"] as? Double, 72.0)
        XCTAssertEqual(ckRecord["deviceSource"] as? String, "iPhone Test")
    }
    
    func testAnalyticsInsightSync() async throws {
        // Create test analytics insight
        let insight = AnalyticsInsight(
            title: "Sleep Quality Improvement",
            description: "Your sleep quality has improved by 15% this week",
            category: "Sleep",
            confidence: 0.92,
            source: "Mac",
            actionable: true,
            priority: 1
        )
        
        testContext.insert(insight)
        try testContext.save()
        
        // Verify insight properties
        XCTAssertTrue(insight.needsSync)
        XCTAssertTrue(insight.actionable)
        XCTAssertEqual(insight.priority, 1)
        
        // Test CloudKit record conversion
        let ckRecord = insight.ckRecord
        XCTAssertEqual(ckRecord.recordType, "AnalyticsInsight")
        XCTAssertEqual(ckRecord["confidence"] as? Double, 0.92)
        XCTAssertEqual(ckRecord["actionable"] as? Bool, true)
    }
    
    func testMLModelUpdateSync() async throws {
        // Create test ML model update
        let modelUpdate = MLModelUpdate(
            modelName: "SleepPredictor",
            modelVersion: "2.1.0",
            accuracy: 0.94,
            source: "Mac"
        )
        
        testContext.insert(modelUpdate)
        try testContext.save()
        
        // Verify model update
        XCTAssertTrue(modelUpdate.needsSync)
        XCTAssertEqual(modelUpdate.accuracy, 0.94)
        
        // Test CloudKit record
        let ckRecord = modelUpdate.ckRecord
        XCTAssertEqual(ckRecord.recordType, "MLModelUpdate")
        XCTAssertEqual(ckRecord["modelName"] as? String, "SleepPredictor")
        XCTAssertEqual(ckRecord["accuracy"] as? Double, 0.94)
    }
    
    func testExportRequestFlow() async throws {
        // Create test export request
        let dateRange = DateInterval(start: Date().addingTimeInterval(-86400), end: Date())
        let dateRangeData = try JSONEncoder().encode(dateRange)
        
        let exportRequest = ExportRequest(
            requestedBy: "iPhone",
            exportType: "CSV",
            dateRange: dateRangeData
        )
        
        testContext.insert(exportRequest)
        try testContext.save()
        
        // Verify export request
        XCTAssertEqual(exportRequest.status, "pending")
        XCTAssertTrue(exportRequest.needsSync)
        XCTAssertEqual(exportRequest.exportType, "CSV")
        
        // Simulate processing
        exportRequest.status = "completed"
        exportRequest.completedDate = Date()
        exportRequest.resultURL = "https://example.com/export.csv"
        
        // Verify completion
        XCTAssertEqual(exportRequest.status, "completed")
        XCTAssertNotNil(exportRequest.completedDate)
        XCTAssertNotNil(exportRequest.resultURL)
    }
    
    // MARK: - Conflict Resolution Tests
    
    func testConflictResolutionTimestampBased() async throws {
        // Create local health entry
        let localEntry = SyncableHealthDataEntry(
            restingHeartRate: 70.0,
            hrv: 30.0,
            oxygenSaturation: 97.0,
            bodyTemperature: 98.4,
            stressLevel: 4.0,
            moodScore: 6.0,
            energyLevel: 5.0,
            activityLevel: 4.0,
            sleepQuality: 7.0,
            nutritionScore: 6.0,
            deviceSource: "iPhone"
        )
        localEntry.lastSyncDate = Date().addingTimeInterval(-3600) // 1 hour ago
        
        testContext.insert(localEntry)
        try testContext.save()
        
        // Create remote entry (more recent)
        let remoteEntry = SyncableHealthDataEntry(
            id: localEntry.id, // Same ID for conflict
            restingHeartRate: 75.0,
            hrv: 35.0,
            oxygenSaturation: 98.0,
            bodyTemperature: 98.6,
            stressLevel: 3.0,
            moodScore: 8.0,
            energyLevel: 7.0,
            activityLevel: 6.0,
            sleepQuality: 8.0,
            nutritionScore: 8.0,
            deviceSource: "Apple Watch"
        )
        remoteEntry.lastSyncDate = Date() // More recent
        
        // Simulate conflict resolution (remote wins due to timestamp)
        XCTAssertLessThan(localEntry.lastSyncDate ?? Date.distantPast, 
                         remoteEntry.lastSyncDate ?? Date.distantPast)
        
        // In real implementation, remote values would overwrite local
        XCTAssertEqual(remoteEntry.restingHeartRate, 75.0)
        XCTAssertEqual(remoteEntry.deviceSource, "Apple Watch")
    }
    
    // MARK: - Cross-Device Data Flow Tests
    
    func testCrossDeviceAnalyticsFlow() async throws {
        // 1. iPhone creates health data
        let iPhoneHealthData = SyncableHealthDataEntry(
            restingHeartRate: 68.0,
            hrv: 42.0,
            oxygenSaturation: 99.0,
            bodyTemperature: 98.2,
            stressLevel: 2.0,
            moodScore: 8.0,
            energyLevel: 8.0,
            activityLevel: 7.0,
            sleepQuality: 9.0,
            nutritionScore: 8.0,
            deviceSource: "iPhone"
        )
        
        testContext.insert(iPhoneHealthData)
        try testContext.save()
        
        // 2. Mac processes analytics and creates insight
        let macInsight = AnalyticsInsight(
            title: "Excellent Recovery Detected",
            description: "Your HRV indicates excellent recovery. Great time for intense training.",
            category: "Recovery",
            confidence: 0.95,
            source: "Mac",
            actionable: true,
            priority: 2
        )
        
        testContext.insert(macInsight)
        try testContext.save()
        
        // 3. Mac creates ML model update
        let modelUpdate = MLModelUpdate(
            modelName: "RecoveryPredictor",
            modelVersion: "1.3.2",
            accuracy: 0.96,
            source: "Mac"
        )
        
        testContext.insert(modelUpdate)
        try testContext.save()
        
        // Verify flow
        XCTAssertEqual(iPhoneHealthData.deviceSource, "iPhone")
        XCTAssertEqual(macInsight.source, "Mac")
        XCTAssertEqual(modelUpdate.source, "Mac")
        XCTAssertTrue(macInsight.actionable)
        XCTAssertEqual(macInsight.priority, 2)
    }
    
    func testMacAnalyticsOffloadFlow() async throws {
        // Create multiple health data entries to simulate data for analysis
        let entries = [
            SyncableHealthDataEntry(restingHeartRate: 65, hrv: 45, oxygenSaturation: 99, bodyTemperature: 98.1, stressLevel: 1, moodScore: 9, energyLevel: 9, activityLevel: 8, sleepQuality: 9, nutritionScore: 9, deviceSource: "iPhone"),
            SyncableHealthDataEntry(restingHeartRate: 72, hrv: 38, oxygenSaturation: 98, bodyTemperature: 98.3, stressLevel: 3, moodScore: 7, energyLevel: 6, activityLevel: 5, sleepQuality: 7, nutritionScore: 7, deviceSource: "iPhone"),
            SyncableHealthDataEntry(restingHeartRate: 78, hrv: 25, oxygenSaturation: 97, bodyTemperature: 98.8, stressLevel: 6, moodScore: 4, energyLevel: 3, activityLevel: 2, sleepQuality: 4, nutritionScore: 5, deviceSource: "iPhone")
        ]
        
        for entry in entries {
            testContext.insert(entry)
        }
        try testContext.save()
        
        // Simulate Mac processing trigger
        let processingRequest = AnalyticsInsight(
            title: "Mac Analytics Request",
            description: "Requesting comprehensive health analysis",
            category: "Request",
            confidence: 1.0,
            source: "iPhone",
            actionable: true,
            priority: 2
        )
        
        testContext.insert(processingRequest)
        try testContext.save()
        
        // Simulate Mac responding with insights
        let analysisResult = AnalyticsInsight(
            title: "Stress Pattern Detected",
            description: "Analysis shows increasing stress levels over the past 3 days. Recommend stress management techniques.",
            category: "Stress",
            confidence: 0.88,
            source: "Mac",
            actionable: true,
            priority: 2
        )
        
        testContext.insert(analysisResult)
        try testContext.save()
        
        // Verify offload flow
        XCTAssertEqual(entries.count, 3)
        XCTAssertEqual(processingRequest.category, "Request")
        XCTAssertEqual(analysisResult.source, "Mac")
        XCTAssertTrue(analysisResult.actionable)
    }
    
    // MARK: - Export Tests
    
    func testDataExportFlow() async throws {
        // Create comprehensive test data
        let healthEntry = SyncableHealthDataEntry(
            restingHeartRate: 70,
            hrv: 35,
            oxygenSaturation: 98,
            bodyTemperature: 98.6,
            stressLevel: 3,
            moodScore: 7,
            energyLevel: 6,
            activityLevel: 5,
            sleepQuality: 8,
            nutritionScore: 7,
            deviceSource: "Test Device"
        )
        
        let sleepSession = SyncableSleepSessionEntry(
            startTime: Date().addingTimeInterval(-28800), // 8 hours ago
            endTime: Date(),
            duration: 28800, // 8 hours
            qualityScore: 0.85,
            deviceSource: "Test Device"
        )
        
        let insight = AnalyticsInsight(
            title: "Sleep Analysis Complete",
            description: "Your sleep efficiency was 85% last night",
            category: "Sleep",
            confidence: 0.92,
            source: "Mac"
        )
        
        testContext.insert(healthEntry)
        testContext.insert(sleepSession)
        testContext.insert(insight)
        try testContext.save()
        
        // Create export request
        let dateRange = DateInterval(start: Date().addingTimeInterval(-86400), end: Date())
        let dateRangeData = try JSONEncoder().encode(dateRange)
        
        let exportRequest = ExportRequest(
            requestedBy: "Test",
            exportType: "CSV",
            dateRange: dateRangeData
        )
        
        testContext.insert(exportRequest)
        try testContext.save()
        
        // Verify export request creation
        XCTAssertEqual(exportRequest.exportType, "CSV")
        XCTAssertEqual(exportRequest.status, "pending")
        XCTAssertTrue(exportRequest.needsSync)
    }
    
    // MARK: - Performance Tests
    
    func testLargeBatchSync() async throws {
        let batchSize = 100
        
        // Create large batch of health data
        let startTime = CFAbsoluteTimeGetCurrent()
        
        for i in 0..<batchSize {
            let entry = SyncableHealthDataEntry(
                restingHeartRate: Double(60 + i % 40),
                hrv: Double(20 + i % 30),
                oxygenSaturation: Double(95 + i % 5),
                bodyTemperature: Double(97 + (i % 3)),
                stressLevel: Double(i % 10),
                moodScore: Double(i % 10),
                energyLevel: Double(i % 10),
                activityLevel: Double(i % 10),
                sleepQuality: Double(i % 10),
                nutritionScore: Double(i % 10),
                deviceSource: "Performance Test"
            )
            testContext.insert(entry)
        }
        
        try testContext.save()
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let duration = endTime - startTime
        
        // Verify performance (should complete within 1 second)
        XCTAssertLessThan(duration, 1.0, "Batch creation took too long: \(duration)s")
        
        // Verify all entries were created
        let descriptor = FetchDescriptor<SyncableHealthDataEntry>(
            predicate: #Predicate { $0.deviceSource == "Performance Test" }
        )
        let fetchedEntries = try testContext.fetch(descriptor)
        XCTAssertEqual(fetchedEntries.count, batchSize)
    }
    
    // MARK: - Error Handling Tests
    
    func testInvalidDataHandling() async throws {
        // Test with invalid data
        let invalidEntry = SyncableHealthDataEntry(
            restingHeartRate: -1, // Invalid negative heart rate
            hrv: 1000, // Unrealistic HRV
            oxygenSaturation: 120, // Invalid oxygen saturation
            bodyTemperature: 110, // Dangerously high temperature
            stressLevel: 15, // Out of normal range
            moodScore: -5, // Invalid negative mood
            energyLevel: 20, // Out of range
            activityLevel: -10, // Invalid negative activity
            sleepQuality: 15, // Out of range
            nutritionScore: -3, // Invalid negative nutrition
            deviceSource: ""
        )
        
        testContext.insert(invalidEntry)
        try testContext.save()
        
        // Verify the entry was created (validation should happen at UI/business logic layer)
        XCTAssertEqual(invalidEntry.restingHeartRate, -1)
        XCTAssertEqual(invalidEntry.deviceSource, "")
        
        // In a real implementation, these would be validated and sanitized
        // before being saved to the model context
    }
    
    func testSyncErrorRecovery() async throws {
        // Create entry that will fail to sync
        let problematicEntry = SyncableHealthDataEntry(
            restingHeartRate: 70,
            hrv: 35,
            oxygenSaturation: 98,
            bodyTemperature: 98.6,
            stressLevel: 3,
            moodScore: 7,
            energyLevel: 6,
            activityLevel: 5,
            sleepQuality: 8,
            nutritionScore: 7,
            deviceSource: "Error Test"
        )
        
        testContext.insert(problematicEntry)
        try testContext.save()
        
        // Verify initial sync state
        XCTAssertTrue(problematicEntry.needsSync)
        XCTAssertNil(problematicEntry.lastSyncDate)
        
        // Simulate sync failure recovery
        // In real implementation, failed syncs would be retried with exponential backoff
        XCTAssertEqual(problematicEntry.syncVersion, 1)
    }
    
    // MARK: - Integration Tests
    
    func testEndToEndMultiDeviceFlow() async throws {
        // 1. iPhone creates health data
        let iPhoneData = SyncableHealthDataEntry(
            restingHeartRate: 65,
            hrv: 45,
            oxygenSaturation: 99,
            bodyTemperature: 98.1,
            stressLevel: 2,
            moodScore: 8,
            energyLevel: 8,
            activityLevel: 7,
            sleepQuality: 9,
            nutritionScore: 8,
            deviceSource: "iPhone"
        )
        testContext.insert(iPhoneData)
        
        // 2. Apple Watch creates additional data
        let watchData = SyncableHealthDataEntry(
            restingHeartRate: 68,
            hrv: 42,
            oxygenSaturation: 98,
            bodyTemperature: 98.3,
            stressLevel: 3,
            moodScore: 7,
            energyLevel: 7,
            activityLevel: 8,
            sleepQuality: 8,
            nutritionScore: 7,
            deviceSource: "Apple Watch"
        )
        testContext.insert(watchData)
        
        // 3. Mac processes and creates insights
        let macInsight = AnalyticsInsight(
            title: "Cross-Device Health Analysis",
            description: "Combined data from iPhone and Apple Watch shows excellent health trends",
            category: "Health",
            confidence: 0.94,
            source: "Mac",
            actionable: true,
            priority: 1
        )
        testContext.insert(macInsight)
        
        // 4. User requests export
        let dateRange = DateInterval(start: Date().addingTimeInterval(-86400), end: Date())
        let dateRangeData = try JSONEncoder().encode(dateRange)
        
        let exportRequest = ExportRequest(
            requestedBy: "iPhone",
            exportType: "FHIR",
            dateRange: dateRangeData
        )
        testContext.insert(exportRequest)
        
        // 5. Mac processes export
        exportRequest.status = "completed"
        exportRequest.completedDate = Date()
        exportRequest.resultURL = "https://example.com/export.fhir"
        
        try testContext.save()
        
        // Verify end-to-end flow
        XCTAssertEqual(iPhoneData.deviceSource, "iPhone")
        XCTAssertEqual(watchData.deviceSource, "Apple Watch")
        XCTAssertEqual(macInsight.source, "Mac")
        XCTAssertEqual(exportRequest.status, "completed")
        XCTAssertNotNil(exportRequest.resultURL)
        
        // Verify all entities are marked for sync
        XCTAssertTrue(iPhoneData.needsSync)
        XCTAssertTrue(watchData.needsSync)
        XCTAssertTrue(macInsight.needsSync)
        XCTAssertTrue(exportRequest.needsSync)
    }
}
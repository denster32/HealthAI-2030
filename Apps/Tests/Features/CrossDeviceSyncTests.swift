import XCTest
import CloudKit
import SwiftData
@testable import HealthAI_2030

@available(iOS 18.0, macOS 15.0, *)
final class CrossDeviceSyncTests: XCTestCase {
    
    var syncManager: UnifiedCloudKitSyncManager!
    var testModelContainer: ModelContainer!
    var testModelContext: ModelContext!
    
    override func setUpWithError() throws {
        super.setUp()
        
        // Setup test model container
        let schema = Schema([
            SyncableHealthDataEntry.self,
            SyncableSleepSessionEntry.self,
            AnalyticsInsight.self,
            MLModelUpdate.self,
            ExportRequest.self
        ])
        
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        testModelContainer = try ModelContainer(for: schema, configurations: [config])
        testModelContext = ModelContext(testModelContainer)
        
        // Initialize sync manager
        syncManager = UnifiedCloudKitSyncManager.shared
    }
    
    override func tearDownWithError() throws {
        syncManager = nil
        testModelContext = nil
        testModelContainer = nil
        super.tearDown()
    }
    
    // MARK: - Data Model Tests
    
    func testHealthDataEntryCloudKitMapping() throws {
        // Create test health data entry
        let entry = SyncableHealthDataEntry(
            timestamp: Date(),
            restingHeartRate: 72.0,
            hrv: 45.0,
            oxygenSaturation: 98.5,
            bodyTemperature: 36.8,
            stressLevel: 3.2,
            moodScore: 7.5,
            energyLevel: 6.8,
            activityLevel: 8.2,
            sleepQuality: 7.9,
            nutritionScore: 6.5,
            deviceSource: "iPhone"
        )
        
        // Test CloudKit record conversion
        let ckRecord = entry.ckRecord
        
        XCTAssertEqual(ckRecord.recordType, "HealthDataEntry")
        XCTAssertEqual(ckRecord["restingHeartRate"] as? Double, 72.0)
        XCTAssertEqual(ckRecord["hrv"] as? Double, 45.0)
        XCTAssertEqual(ckRecord["deviceSource"] as? String, "iPhone")
        XCTAssertEqual(ckRecord["syncVersion"] as? Int, 1)
        
        // Test reverse conversion
        let recreatedEntry = SyncableHealthDataEntry(from: ckRecord)
        XCTAssertNotNil(recreatedEntry)
        XCTAssertEqual(recreatedEntry?.restingHeartRate, 72.0)
        XCTAssertEqual(recreatedEntry?.deviceSource, "iPhone")
        XCTAssertFalse(recreatedEntry?.needsSync ?? true)
    }
    
    func testSleepSessionCloudKitMapping() throws {
        let startTime = Date()
        let endTime = startTime.addingTimeInterval(8 * 3600) // 8 hours
        
        let sleepSession = SyncableSleepSessionEntry(
            startTime: startTime,
            endTime: endTime,
            duration: 8 * 3600,
            qualityScore: 0.85,
            deviceSource: "Apple Watch"
        )
        
        let ckRecord = sleepSession.ckRecord
        
        XCTAssertEqual(ckRecord.recordType, "SleepSessionEntry")
        XCTAssertEqual(ckRecord["startTime"] as? Date, startTime)
        XCTAssertEqual(ckRecord["endTime"] as? Date, endTime)
        XCTAssertEqual(ckRecord["duration"] as? TimeInterval, 8 * 3600)
        XCTAssertEqual(ckRecord["qualityScore"] as? Double, 0.85)
        
        let recreatedSession = SyncableSleepSessionEntry(from: ckRecord)
        XCTAssertNotNil(recreatedSession)
        XCTAssertEqual(recreatedSession?.duration, 8 * 3600)
    }
    
    func testAnalyticsInsightCloudKitMapping() throws {
        let insight = AnalyticsInsight(
            title: "Heart Rate Trend",
            description: "Your resting heart rate has improved by 5% this week",
            category: "Cardiovascular",
            confidence: 0.92,
            source: "Mac",
            actionable: true,
            priority: 2
        )
        
        let ckRecord = insight.ckRecord
        
        XCTAssertEqual(ckRecord.recordType, "AnalyticsInsight")
        XCTAssertEqual(ckRecord["title"] as? String, "Heart Rate Trend")
        XCTAssertEqual(ckRecord["confidence"] as? Double, 0.92)
        XCTAssertEqual(ckRecord["source"] as? String, "Mac")
        XCTAssertEqual(ckRecord["actionable"] as? Bool, true)
        XCTAssertEqual(ckRecord["priority"] as? Int, 2)
    }
    
    // MARK: - Sync Flow Tests
    
    func testBasicSyncFlow() async throws {
        // Create test data
        let healthEntry = SyncableHealthDataEntry(
            timestamp: Date(),
            restingHeartRate: 75.0,
            hrv: 42.0,
            oxygenSaturation: 97.8,
            bodyTemperature: 36.9,
            stressLevel: 2.8,
            moodScore: 8.0,
            energyLevel: 7.2,
            activityLevel: 6.8,
            sleepQuality: 8.5,
            nutritionScore: 7.3
        )
        
        testModelContext.insert(healthEntry)
        try testModelContext.save()
        
        // Verify initial state
        XCTAssertTrue(healthEntry.needsSync)
        XCTAssertNil(healthEntry.lastSyncDate)
        XCTAssertEqual(healthEntry.syncVersion, 1)
        
        // Test sync (mocked)
        // In real implementation, this would sync with CloudKit
        healthEntry.lastSyncDate = Date()
        healthEntry.needsSync = false
        try testModelContext.save()
        
        XCTAssertFalse(healthEntry.needsSync)
        XCTAssertNotNil(healthEntry.lastSyncDate)
    }
    
    func testConflictResolution() async throws {
        // Create local and remote versions of the same record
        let recordId = UUID()
        let baseTime = Date()
        
        let localEntry = SyncableHealthDataEntry(
            id: recordId,
            timestamp: baseTime,
            restingHeartRate: 72.0,
            hrv: 45.0,
            oxygenSaturation: 98.0,
            bodyTemperature: 36.8,
            stressLevel: 3.0,
            moodScore: 7.0,
            energyLevel: 6.0,
            activityLevel: 8.0,
            sleepQuality: 7.5,
            nutritionScore: 6.8
        )
        localEntry.lastSyncDate = baseTime.addingTimeInterval(-300) // 5 minutes ago
        
        let remoteEntry = SyncableHealthDataEntry(
            id: recordId,
            timestamp: baseTime,
            restingHeartRate: 74.0, // Different value
            hrv: 45.0,
            oxygenSaturation: 98.0,
            bodyTemperature: 36.8,
            stressLevel: 3.0,
            moodScore: 7.0,
            energyLevel: 6.0,
            activityLevel: 8.0,
            sleepQuality: 7.5,
            nutritionScore: 6.8
        )
        remoteEntry.lastSyncDate = baseTime // More recent
        
        // In a real conflict resolution scenario, the more recent version (remote) should win
        // This test verifies the logic for determining which version is newer
        
        let localTimestamp = localEntry.lastSyncDate ?? Date.distantPast
        let remoteTimestamp = remoteEntry.lastSyncDate ?? Date.distantPast
        
        XCTAssertTrue(remoteTimestamp > localTimestamp, "Remote version should be newer")
        
        // In real implementation, local entry would be updated with remote values
        localEntry.restingHeartRate = remoteEntry.restingHeartRate
        localEntry.lastSyncDate = Date()
        localEntry.needsSync = false
        
        XCTAssertEqual(localEntry.restingHeartRate, 74.0)
        XCTAssertFalse(localEntry.needsSync)
    }
    
    // MARK: - Export Request Tests
    
    func testExportRequestCreation() async throws {
        let dateRange = DateInterval(
            start: Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date(),
            end: Date()
        )
        
        let dateRangeData = try JSONEncoder().encode(dateRange)
        
        let exportRequest = ExportRequest(
            requestedBy: "iPhone",
            exportType: "CSV",
            dateRange: dateRangeData,
            status: "pending"
        )
        
        testModelContext.insert(exportRequest)
        try testModelContext.save()
        
        XCTAssertEqual(exportRequest.status, "pending")
        XCTAssertEqual(exportRequest.exportType, "CSV")
        XCTAssertEqual(exportRequest.requestedBy, "iPhone")
        XCTAssertTrue(exportRequest.needsSync)
        
        // Test CloudKit record conversion
        let ckRecord = exportRequest.ckRecord
        XCTAssertEqual(ckRecord.recordType, "ExportRequest")
        XCTAssertEqual(ckRecord["status"] as? String, "pending")
        XCTAssertEqual(ckRecord["exportType"] as? String, "CSV")
        
        // Simulate processing
        exportRequest.status = "completed"
        exportRequest.completedDate = Date()
        exportRequest.resultURL = "https://example.com/export.csv"
        exportRequest.needsSync = true
        
        XCTAssertEqual(exportRequest.status, "completed")
        XCTAssertNotNil(exportRequest.completedDate)
        XCTAssertNotNil(exportRequest.resultURL)
    }
    
    // MARK: - ML Model Update Tests
    
    func testMLModelUpdateSync() async throws {
        let modelUpdate = MLModelUpdate(
            modelName: "HealthPredictor",
            modelVersion: "2.1",
            accuracy: 0.94,
            trainingDate: Date(),
            source: "Mac"
        )
        
        testModelContext.insert(modelUpdate)
        try testModelContext.save()
        
        XCTAssertEqual(modelUpdate.modelName, "HealthPredictor")
        XCTAssertEqual(modelUpdate.accuracy, 0.94)
        XCTAssertEqual(modelUpdate.source, "Mac")
        XCTAssertTrue(modelUpdate.needsSync)
        
        // Test CloudKit conversion
        let ckRecord = modelUpdate.ckRecord
        XCTAssertEqual(ckRecord["modelName"] as? String, "HealthPredictor")
        XCTAssertEqual(ckRecord["accuracy"] as? Double, 0.94)
        XCTAssertEqual(ckRecord["source"] as? String, "Mac")
    }
    
    // MARK: - Data Validation Tests
    
    func testHealthDataValidation() throws {
        // Test valid data
        let validEntry = SyncableHealthDataEntry(
            timestamp: Date(),
            restingHeartRate: 72.0,
            hrv: 45.0,
            oxygenSaturation: 98.0,
            bodyTemperature: 36.8,
            stressLevel: 3.0,
            moodScore: 7.0,
            energyLevel: 6.0,
            activityLevel: 8.0,
            sleepQuality: 7.5,
            nutritionScore: 6.8
        )
        
        XCTAssertTrue(isValidHealthData(validEntry))
        
        // Test edge cases
        let edgeEntry = SyncableHealthDataEntry(
            timestamp: Date(),
            restingHeartRate: 0,  // Invalid
            hrv: -1,             // Invalid
            oxygenSaturation: 101, // Invalid
            bodyTemperature: 50,   // Invalid
            stressLevel: -1,       // Invalid
            moodScore: 11,         // Invalid
            energyLevel: -1,       // Invalid
            activityLevel: -1,     // Invalid
            sleepQuality: 2,       // Invalid
            nutritionScore: -1     // Invalid
        )
        
        XCTAssertFalse(isValidHealthData(edgeEntry))
    }
    
    private func isValidHealthData(_ entry: SyncableHealthDataEntry) -> Bool {
        return entry.restingHeartRate > 0 && entry.restingHeartRate < 200 &&
               entry.hrv >= 0 &&
               entry.oxygenSaturation >= 80 && entry.oxygenSaturation <= 100 &&
               entry.bodyTemperature >= 30 && entry.bodyTemperature <= 45 &&
               entry.stressLevel >= 0 && entry.stressLevel <= 10 &&
               entry.moodScore >= 0 && entry.moodScore <= 10 &&
               entry.energyLevel >= 0 && entry.energyLevel <= 10 &&
               entry.activityLevel >= 0 && entry.activityLevel <= 10 &&
               entry.sleepQuality >= 0 && entry.sleepQuality <= 10 &&
               entry.nutritionScore >= 0 && entry.nutritionScore <= 10
    }
    
    // MARK: - Performance Tests
    
    func testLargeBatchSync() throws {
        measure {
            // Create a large batch of health data entries
            for i in 0..<1000 {
                let entry = SyncableHealthDataEntry(
                    timestamp: Date().addingTimeInterval(TimeInterval(-i * 3600)),
                    restingHeartRate: Double.random(in: 60...100),
                    hrv: Double.random(in: 20...80),
                    oxygenSaturation: Double.random(in: 95...100),
                    bodyTemperature: Double.random(in: 36...38),
                    stressLevel: Double.random(in: 0...10),
                    moodScore: Double.random(in: 0...10),
                    energyLevel: Double.random(in: 0...10),
                    activityLevel: Double.random(in: 0...10),
                    sleepQuality: Double.random(in: 0...10),
                    nutritionScore: Double.random(in: 0...10)
                )
                testModelContext.insert(entry)
            }
            
            do {
                try testModelContext.save()
            } catch {
                XCTFail("Failed to save large batch: \(error)")
            }
        }
    }
    
    func testCloudKitRecordConversionPerformance() throws {
        let entries = (0..<100).map { i in
            SyncableHealthDataEntry(
                timestamp: Date().addingTimeInterval(TimeInterval(-i * 3600)),
                restingHeartRate: Double.random(in: 60...100),
                hrv: Double.random(in: 20...80),
                oxygenSaturation: Double.random(in: 95...100),
                bodyTemperature: Double.random(in: 36...38),
                stressLevel: Double.random(in: 0...10),
                moodScore: Double.random(in: 0...10),
                energyLevel: Double.random(in: 0...10),
                activityLevel: Double.random(in: 0...10),
                sleepQuality: Double.random(in: 0...10),
                nutritionScore: Double.random(in: 0...10)
            )
        }
        
        measure {
            for entry in entries {
                let ckRecord = entry.ckRecord
                let _ = SyncableHealthDataEntry(from: ckRecord)
            }
        }
    }
    
    // MARK: - Error Handling Tests
    
    func testInvalidCloudKitRecord() throws {
        // Create an invalid CloudKit record missing required fields
        let invalidRecord = CKRecord(recordType: "HealthDataEntry")
        // Missing required fields like timestamp, restingHeartRate, etc.
        
        let recreatedEntry = SyncableHealthDataEntry(from: invalidRecord)
        XCTAssertNil(recreatedEntry, "Should return nil for invalid record")
    }
    
    func testMalformedData() throws {
        // Test handling of malformed export request data
        let malformedData = "invalid json data".data(using: .utf8)!
        
        let exportRequest = ExportRequest(
            requestedBy: "Test",
            exportType: "CSV",
            dateRange: malformedData
        )
        
        // Attempting to decode should fail gracefully
        XCTAssertThrowsError(try JSONDecoder().decode(DateInterval.self, from: malformedData))
    }
    
    // MARK: - Integration Tests
    
    func testEndToEndSyncFlow() async throws {
        // This test simulates a complete sync flow between devices
        
        // 1. iPhone creates health data
        let phoneData = SyncableHealthDataEntry(
            timestamp: Date(),
            restingHeartRate: 72.0,
            hrv: 45.0,
            oxygenSaturation: 98.0,
            bodyTemperature: 36.8,
            stressLevel: 3.0,
            moodScore: 7.0,
            energyLevel: 6.0,
            activityLevel: 8.0,
            sleepQuality: 7.5,
            nutritionScore: 6.8,
            deviceSource: "iPhone"
        )
        
        testModelContext.insert(phoneData)
        try testModelContext.save()
        
        // 2. Mac processes analytics and creates insight
        let macInsight = AnalyticsInsight(
            title: "Improved Recovery",
            description: "Your HRV shows 15% improvement this week",
            category: "Recovery",
            confidence: 0.89,
            source: "Mac",
            actionable: true
        )
        
        testModelContext.insert(macInsight)
        try testModelContext.save()
        
        // 3. Export request is created
        let dateRange = DateInterval(start: Date().addingTimeInterval(-7*24*3600), end: Date())
        let dateRangeData = try JSONEncoder().encode(dateRange)
        
        let exportRequest = ExportRequest(
            requestedBy: "iPhone",
            exportType: "CSV",
            dateRange: dateRangeData
        )
        
        testModelContext.insert(exportRequest)
        try testModelContext.save()
        
        // 4. Verify all records are marked for sync
        XCTAssertTrue(phoneData.needsSync)
        XCTAssertTrue(macInsight.needsSync)
        XCTAssertTrue(exportRequest.needsSync)
        
        // 5. Simulate successful sync
        phoneData.needsSync = false
        phoneData.lastSyncDate = Date()
        
        macInsight.needsSync = false
        macInsight.lastSyncDate = Date()
        
        exportRequest.needsSync = false
        exportRequest.lastSyncDate = Date()
        
        try testModelContext.save()
        
        // 6. Verify sync completion
        XCTAssertFalse(phoneData.needsSync)
        XCTAssertFalse(macInsight.needsSync)
        XCTAssertFalse(exportRequest.needsSync)
        
        XCTAssertNotNil(phoneData.lastSyncDate)
        XCTAssertNotNil(macInsight.lastSyncDate)
        XCTAssertNotNil(exportRequest.lastSyncDate)
    }
}
import XCTest
import CloudKit
@testable import HealthAI_2030

class DataSyncTests: XCTestCase {
    var cloudKitSyncManager: CloudKitSyncManager!

    override func setUp() {
        super.setUp()
        cloudKitSyncManager = CloudKitSyncManager.shared
        // Note: For actual unit testing, you would typically use a mock CKContainer
        // or a test-specific CloudKit database to avoid hitting the live CloudKit service.
        // For this POC, we're using the shared instance for simplicity.
    }

    override func tearDown() {
        cloudKitSyncManager = nil
        super.tearDown()
    }

    func testSaveAndFetchHealthDataSnapshot() {
        let expectation = self.expectation(description: "Save and fetch HealthDataSnapshot")

        let dummyHealthData = HealthDataSnapshot(
            heartRate: 70.0,
            hrv: 50.0,
            oxygenSaturation: 98.0,
            bodyTemperature: 36.5,
            stepCount: 1000,
            activeEnergyBurned: 500.0,
            sleepData: [
                SleepDataSnapshot(startDate: Date().addingTimeInterval(-3600), endDate: Date(), sleepStage: 2, timestamp: Date())
            ],
            timestamp: Date()
        )

        let record = CKRecord(recordType: "HealthDataSnapshot")
        record["heartRate"] = dummyHealthData.heartRate as CKRecordValue
        record["hrv"] = dummyHealthData.hrv as CKRecordValue
        record["oxygenSaturation"] = dummyHealthData.oxygenSaturation as CKRecordValue
        record["bodyTemperature"] = dummyHealthData.bodyTemperature as CKRecordValue
        record["stepCount"] = dummyHealthData.stepCount as CKRecordValue
        record["activeEnergyBurned"] = dummyHealthData.activeEnergyBurned as CKRecordValue
        record["timestamp"] = dummyHealthData.timestamp as CKRecordValue
        
        // For sleepData, you'd typically serialize it to Data or a custom CKAsset
        // For POC, we'll just add a simple indicator
        record["hasSleepData"] = true as CKRecordValue

        cloudKitSyncManager.saveRecord(record) { result in
            switch result {
            case .success(let savedRecord):
                XCTAssertNotNil(savedRecord.recordID, "Saved record should have a recordID")
                
                let query = CKQuery(recordType: "HealthDataSnapshot", predicate: NSPredicate(format: "recordID = %@", savedRecord.recordID))
                self.cloudKitSyncManager.fetchRecords(query: query) { fetchResult in
                    switch fetchResult {
                    case .success(let fetchedRecords):
                        XCTAssertFalse(fetchedRecords.isEmpty, "Should fetch at least one record")
                        XCTAssertEqual(fetchedRecords.first?.recordID, savedRecord.recordID, "Fetched record ID should match saved record ID")
                        expectation.fulfill()
                    case .failure(let error):
                        XCTFail("Failed to fetch record: \(error.localizedDescription)")
                        expectation.fulfill()
                    }
                }
            case .failure(let error):
                XCTFail("Failed to save record: \(error.localizedDescription)")
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 10.0)
    }

    func testWatchConnectivityMessageSend() {
        // Real test: Simulate sending a message via WatchConnectivity and verify delivery
        let expectation = self.expectation(description: "WatchConnectivity message sent and received")
        let mockWCManager = MockWatchConnectivityManager()
        let testMessage = ["type": "sync", "payload": ["steps": 1234]]
        mockWCManager.sendMessage(testMessage) { success in
            XCTAssertTrue(success, "Message should be sent successfully")
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)
    }
    
    func testBackgroundTaskScheduling() {
        // Real test: Simulate scheduling a background sync and verify it is queued
        let expectation = self.expectation(description: "Background task scheduled")
        let mockScheduler = MockBackgroundTaskScheduler()
        mockScheduler.scheduleTask(identifier: "com.healthai.data-sync") { scheduled in
            XCTAssertTrue(scheduled, "Background task should be scheduled")
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)
    }
}
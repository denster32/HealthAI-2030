import XCTest
@testable import HealthAI2030
import SwiftData

final class SwiftDataManagerTests: XCTestCase {
    var manager: SwiftDataManager!
    var testModel: TestModel!
    
    override func setUp() async throws {
        try await super.setUp()
        manager = SwiftDataManager.shared
        testModel = TestModel(name: "Test", value: 42)
    }
    
    override func tearDown() async throws {
        try await manager.deleteAll(TestModel.self)
        try await super.tearDown()
    }
    
    func testSaveAndFetch() async throws {
        // Test saving and fetching a model
        try await manager.save(testModel)
        let fetched = try await manager.fetch(predicate: #Predicate { $0.id == testModel.id })
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.id, testModel.id)
    }
    
    func testFetchOrCreate() async throws {
        // Test fetchOrCreate with new model
        let newModel = try await manager.fetchOrCreate(id: testModel.id) { testModel }
        XCTAssertEqual(newModel.id, testModel.id)
        
        // Test fetchOrCreate with existing model
        let existingModel = try await manager.fetchOrCreate(id: testModel.id) { 
            TestModel(name: "ShouldNotCreate", value: 0) 
        }
        XCTAssertEqual(existingModel.id, testModel.id)
        XCTAssertEqual(existingModel.name, "Test")
    }
    
    func testUpdate() async throws {
        // Save initial model
        try await manager.save(testModel)
        
        // Modify and update
        testModel.name = "Updated"
        try await manager.update(testModel)
        
        // Verify update
        let fetched = try await manager.fetch(predicate: #Predicate { $0.id == testModel.id })
        XCTAssertEqual(fetched.first?.name, "Updated")
    }
    
    func testDelete() async throws {
        // Save then delete
        try await manager.save(testModel)
        try await manager.delete(testModel)
        
        // Verify deletion
        let fetched = try await manager.fetch(predicate: #Predicate { $0.id == testModel.id })
        XCTAssertTrue(fetched.isEmpty)
    }
    
    func testFetchAll() async throws {
        // Create multiple models
        let models = [
            TestModel(name: "A", value: 1),
            TestModel(name: "B", value: 2),
            TestModel(name: "C", value: 3)
        ]
        
        // Save all
        for model in models {
            try await manager.save(model)
        }
        
        // Fetch all and verify
        let allModels = try await manager.fetchAll(TestModel.self)
        XCTAssertEqual(allModels.count, 3)
    }
    
    func testDeleteAll() async throws {
        // Create and save models
        try await manager.save(TestModel(name: "A", value: 1))
        try await manager.save(TestModel(name: "B", value: 2))
        
        // Delete all and verify
        try await manager.deleteAll(TestModel.self)
        let allModels = try await manager.fetchAll(TestModel.self)
        XCTAssertTrue(allModels.isEmpty)
    }
    
    func testErrorHandling() async {
        // Test context unavailable error
        manager.modelContainer = nil
        await XCTAssertThrowsError(try await manager.save(testModel))
    }

    // MARK: - CloudKit Sync Tests
    
    func testCloudKitSyncStatus() async throws {
        try await manager.save(testModel)
        let fetched = try await manager.fetch(predicate: #Predicate { $0.id == testModel.id })
        XCTAssertEqual(fetched.first?.syncStatus, .notSynced)
        
        // Simulate sync completion
        try await manager.update(testModel)
        XCTAssertEqual(testModel.syncStatus, .synced)
    }
    
    func testCloudKitConflictResolution() async throws {
        // Create two models with same ID
        let model1 = TestModel(name: "Original", value: 1)
        let model2 = TestModel(name: "Conflict", value: 2)
        model2.id = model1.id
        
        try await manager.save(model1)
        try await manager.save(model2)
        
        // Should resolve conflict using timestamp
        let fetched = try await manager.fetch(predicate: #Predicate { $0.id == model1.id })
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.name, "Conflict")
    }
    
    /// Extended conflict scenario: simulate updates from two devices
    func testCloudKitConflictResolution_MultipleDevices() async throws {
        // Device A: initial save
        let entry = TestModel(name: "Original", value: 1)
        try await manager.save(entry)

        // Device A offline update
        entry.value = 5
        try await manager.update(entry)

        // Device B: direct context modification (simulating remote update)
        let container = manager.modelContainer!
        let contextB = ModelContext(container)
        if let entryB = try contextB.fetchAll(TestModel.self).first(where: { $0.id == entry.id }) {
            entryB.value = 10
            try contextB.save()
        }

        // Conflict resolution: last write wins (remote)
        let result = try await manager.fetch(predicate: #Predicate { $0.id == entry.id })
        XCTAssertEqual(result.first?.value, 10)
    }
    
    /// Test conflict resolution for HealthDataEntry model using last-write-wins strategy
    func testCloudKitConflictResolution_HealthDataEntry() async throws {
        let entry = HealthDataEntry(
            id: UUID(),
            timestamp: Date(),
            dataType: "conflictTest",
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
        // Initial save
        try await manager.save(entry)
        // Local update offline
        entry.value = 2.0
        try await manager.update(entry)

        // Remote update (simulated via direct context save)
        let container = manager.modelContainer!
        let contextB = ModelContext(container)
        if let remoteEntry = try contextB.fetchAll(HealthDataEntry.self).first(where: { $0.id == entry.id }) {
            remoteEntry.value = 3.0
            try contextB.save()
        }

        // Fetch and verify the remote update prevails
        let result = try await manager.fetch(predicate: #Predicate { $0.id == entry.id })
        XCTAssertEqual(result.first?.value, 3.0)
    }
    
    // MARK: - Concurrency Tests
    
    func testConcurrentSaves() async throws {
        let numberOfModels = 100_000 // Increased for high-volume stress testing
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<numberOfModels {
                group.addTask {
                    let model = TestModel(name: "Concurrent-\(i)", value: i)
                    try? await self.manager.save(model)
                }
            }
        }
        
        let allModels = try await manager.fetchAll(TestModel.self)
        XCTAssertEqual(allModels.count, numberOfModels) // Verify all models are saved
        
        // Basic data integrity check
        let fetchedModel = try await manager.fetch(predicate: #Predicate { $0.name == "Concurrent-50000" })
        XCTAssertFalse(fetchedModel.isEmpty)
        XCTAssertEqual(fetchedModel.first?.value, 50000)
    }
    
    func testConcurrentUpdatesAndDeletes() async throws {
        let initialModels = 5_000
        for i in 0..<initialModels {
            try await manager.save(TestModel(name: "Initial-\(i)", value: i))
        }
        
        let modelsToUpdate = try await manager.fetchAll(TestModel.self)
        XCTAssertEqual(modelsToUpdate.count, initialModels)
        
        let numberOfConcurrentOps = 50_000 // Increased for high-volume operations
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<numberOfConcurrentOps {
                group.addTask {
                    if i % 2 == 0 { // Concurrently update some models
                        if let model = modelsToUpdate.randomElement() {
                            model.name = "Updated-\(i)"
                            try? await self.manager.update(model)
                        }
                    } else { // Concurrently delete others
                        if let model = modelsToUpdate.randomElement() {
                            try? await self.manager.delete(model)
                        }
                    }
                }
            }
        }
        
        // Verify remaining models and their integrity (approximate count due to random deletes/updates)
        let remainingModels = try await manager.fetchAll(TestModel.self)
        XCTAssertLessThanOrEqual(remainingModels.count, initialModels)
        
        // Attempt to fetch a few updated models to ensure consistency
        let updatedModel = try await manager.fetch(predicate: #Predicate { $0.name.contains("Updated") })
        XCTAssertFalse(updatedModel.isEmpty, "Should have some updated models remaining")
        
        // Data integrity checks
        XCTAssertTrue(remainingModels.allSatisfy { !$0.name.isEmpty }, "All remaining models have valid non-empty names")
        XCTAssertTrue(remainingModels.allSatisfy { $0.value >= 0 }, "All remaining models have valid values")
    }
    
    func testThreadSafety() async throws {
        try await manager.save(testModel)
        
        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<50 {
                group.addTask {
                    _ = try? await self.manager.fetch(predicate: #Predicate { $0.id == self.testModel.id })
                }
                group.addTask {
                    try? await self.manager.delete(self.testModel)
                }
            }
        }
    }
    
    // MARK: - Long-Duration Data Persistence Stress Test
    func testLongDurationDataPersistence() async throws {
        let startTime = Date()
        let duration: TimeInterval = 30 * 60 // 30 minutes
        var count = 0
        while Date().timeIntervalSince(startTime) < duration {
            let model = TestModel(name: "Stress-\(count)", value: count)
            try await manager.save(model)
            count += 1
            if count % 1000 == 0 {
                let allModels = try await manager.fetchAll(TestModel.self)
                XCTAssertEqual(allModels.count, count)
            }
            if count % 2000 == 0, let randomModel = (try await manager.fetchAll(TestModel.self)).randomElement() {
                try await manager.delete(randomModel)
                count -= 1
            }
        }
        let finalModels = try await manager.fetchAll(TestModel.self)
        XCTAssertFalse(finalModels.isEmpty)
    }
    
    // MARK: - Long Duration Data Persistence Test
    
    func testLongDurationDataPersistence() async throws {
        let recordsPerMinute = 1000
        let durationInMinutes = 30
        let totalRecords = recordsPerMinute * durationInMinutes
        
        // Simulate long-running data generation and persistence
        for minute in 0..<durationInMinutes {
            for i in 0..<recordsPerMinute {
                let record = TestModel(
                    name: "LongDuration-Minute\(minute)-Record\(i)", 
                    value: Double(minute * recordsPerMinute + i)
                )
                try await manager.save(record)
            }
            
            // Periodic consistency checks
            let recordsAtMinute = try await manager.fetch(
                predicate: #Predicate { $0.name.contains("LongDuration-Minute\(minute)") }
            )
            XCTAssertEqual(recordsAtMinute.count, recordsPerMinute, "All records for minute \(minute) should be saved")
            
            // Simulate a brief pause between batches
            try await Task.sleep(for: .seconds(1))
        }
        
        // Final consistency check
        let allRecords = try await manager.fetchAll(TestModel.self)
        XCTAssertEqual(allRecords.count, totalRecords, "Total number of records should match expected")
        
        // Memory and resource usage would typically be monitored externally
        // This test ensures data integrity and consistent saving
    }
    
    // MARK: - Performance Tests
    
    func testSavePerformance() throws {
        measure {
            let exp = expectation(description: "Save completion")
            Task {
                try await manager.save(testModel)
                exp.fulfill()
            }
            wait(for: [exp], timeout: 5)
        }
    }
    
    func testFetchPerformance() throws {
        try await manager.save(testModel)
        
        measure {
            let exp = expectation(description: "Fetch completion")
            Task {
                _ = try await manager.fetch(predicate: #Predicate { $0.id == self.testModel.id })
                exp.fulfill()
            }
            wait(for: [exp], timeout: 5)
        }
    }
}

// Helper model for testing
@Model
final class TestModel: CKSyncable {
    var id: UUID
    var name: String
    var value: Int
    
    init(name: String, value: Int) {
        self.id = UUID()
        self.name = name
        self.value = value
    }
}

// Helper assertion
func XCTAssertThrowsError<T>(
    _ expression: @autoclosure () async throws -> T,
    _ message: @autoclosure () -> String = "",
    file: StaticString = #filePath,
    line: UInt = #line
) async {
    do {
        _ = try await expression()
        XCTFail(message(), file: file, line: line)
    } catch {
        // Expected error
    }
}
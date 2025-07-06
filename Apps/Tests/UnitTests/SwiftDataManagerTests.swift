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
    
    // MARK: - Concurrency Tests
    
    func testConcurrentSaves() async throws {
        let numberOfModels = 10_000 // Increased for stress testing
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
        let fetchedModel = try await manager.fetch(predicate: #Predicate { $0.name == "Concurrent-5000" })
        XCTAssertFalse(fetchedModel.isEmpty)
        XCTAssertEqual(fetchedModel.first?.value, 5000)
    }
    
    func testConcurrentUpdatesAndDeletes() async throws {
        let initialModels = 5_000
        for i in 0..<initialModels {
            try await manager.save(TestModel(name: "Initial-\(i)", value: i))
        }
        
        let modelsToUpdate = try await manager.fetchAll(TestModel.self)
        XCTAssertEqual(modelsToUpdate.count, initialModels)
        
        let numberOfConcurrentOps = 5_000
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
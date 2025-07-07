import XCTest
@testable import HealthAI2030App

final class MLModelStorageManagerTests: XCTestCase {

    func testStoreAndLoadEncryptedModel() throws {
        let manager = MLModelStorageManager.shared
        let testData = "test-data".data(using: .utf8)!
        let modelName = "testModel"
        
        // Clean any existing directory
        let directory = try manager.modelsDirectory()
        try? FileManager.default.removeItem(at: directory)
        
        // Store and load
        try manager.storeModel(data: testData, named: modelName)
        let loadedData = try manager.loadModel(named: modelName)
        XCTAssertEqual(loadedData, testData, "Loaded data should match stored test data.")
    }
} 
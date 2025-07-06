import XCTest
import SwiftData
import HealthKit
@testable import HealthAI2030Core

@available(iOS 18.0, macOS 15.0, *)
final class HealthDataManagerTests: XCTestCase {
    
    var healthDataManager: HealthDataManager!
    var mockSwiftDataManager: MockSwiftDataManager!
    var mockCloudKitSyncManager: MockUnifiedCloudKitSyncManager!
    var mockPrivacySecurityManager: MockPrivacySecurityManager!
    var modelContainer: ModelContainer!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        // Create in-memory model container for testing
        let schema = Schema([
            HealthDataEntry.self,
            DigitalTwin.self
        ])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: schema, configurations: config)
        
        // Create mock dependencies
        mockSwiftDataManager = MockSwiftDataManager()
        mockCloudKitSyncManager = MockUnifiedCloudKitSyncManager()
        mockPrivacySecurityManager = MockPrivacySecurityManager()
        
        // Create HealthDataManager with mock dependencies
        healthDataManager = HealthDataManager(
            swiftDataManager: mockSwiftDataManager,
            healthKitStore: nil, // No HealthKit in tests
            cloudKitSyncManager: mockCloudKitSyncManager,
            privacySecurityManager: mockPrivacySecurityManager
        )
    }
    
    override func tearDownWithError() throws {
        healthDataManager = nil
        mockSwiftDataManager = nil
        mockCloudKitSyncManager = nil
        mockPrivacySecurityManager = nil
        modelContainer = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Initialization Tests
    
    func testInitialization() async throws {
        // Given
        mockSwiftDataManager.modelContainer = modelContainer
        
        // When
        await healthDataManager.initialize()
        
        // Then
        XCTAssertTrue(healthDataManager.isInitialized)
    }
    
    func testInitializationFailure() async throws {
        // Given
        mockSwiftDataManager.modelContainer = nil
        
        // When & Then
        do {
            await healthDataManager.initialize()
            XCTFail("Should throw error when SwiftData is not available")
        } catch {
            XCTAssertTrue(error is HealthDataError)
        }
    }
    
    // MARK: - Save Health Data Tests
    
    func testSaveHealthData() async throws {
        // Given
        mockSwiftDataManager.modelContainer = modelContainer
        await healthDataManager.initialize()
        
        let healthData = CoreHealthDataModel(
            id: UUID(),
            timestamp: Date(),
            sourceDevice: "Test Device",
            dataType: .heartRate,
            metricValue: 75.0,
            unit: "bpm",
            metadata: nil
        )
        
        // When
        try await healthDataManager.saveHealthData(healthData)
        
        // Then
        XCTAssertTrue(mockSwiftDataManager.saveCalled)
        XCTAssertTrue(mockCloudKitSyncManager.upsertCalled)
    }
    
    func testSaveHealthDataNotInitialized() async throws {
        // Given
        let healthData = CoreHealthDataModel(
            id: UUID(),
            timestamp: Date(),
            sourceDevice: "Test Device",
            dataType: .heartRate,
            metricValue: 75.0,
            unit: "bpm",
            metadata: nil
        )
        
        // When & Then
        do {
            try await healthDataManager.saveHealthData(healthData)
            XCTFail("Should throw error when not initialized")
        } catch {
            XCTAssertTrue(error is HealthDataError)
        }
    }
    
    // MARK: - Fetch Health Data Tests
    
    func testFetchHealthData() async throws {
        // Given
        mockSwiftDataManager.modelContainer = modelContainer
        await healthDataManager.initialize()
        
        let startDate = Date().addingTimeInterval(-86400) // 1 day ago
        let endDate = Date()
        
        // Create test data
        let testEntry = HealthDataEntry(
            timestamp: Date(),
            dataType: "HEART_RATE",
            value: 75.0,
            stringValue: nil,
            source: "Test Device",
            privacyConsentGiven: true
        )
        mockSwiftDataManager.mockFetchResults = [testEntry]
        
        // When
        let results = try await healthDataManager.fetchHealthData(
            startDate: startDate,
            endDate: endDate,
            dataType: .heartRate
        )
        
        // Then
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.dataType, .heartRate)
        XCTAssertEqual(results.first?.metricValue, 75.0)
    }
    
    func testFetchHealthDataEmptyResults() async throws {
        // Given
        mockSwiftDataManager.modelContainer = modelContainer
        await healthDataManager.initialize()
        
        let startDate = Date().addingTimeInterval(-86400)
        let endDate = Date()
        mockSwiftDataManager.mockFetchResults = []
        
        // When
        let results = try await healthDataManager.fetchHealthData(
            startDate: startDate,
            endDate: endDate,
            dataType: .heartRate
        )
        
        // Then
        XCTAssertEqual(results.count, 0)
    }
    
    // MARK: - Delete Health Data Tests
    
    func testDeleteHealthData() async throws {
        // Given
        mockSwiftDataManager.modelContainer = modelContainer
        await healthDataManager.initialize()
        
        let testId = UUID()
        let testEntry = HealthDataEntry(
            timestamp: Date(),
            dataType: "HEART_RATE",
            value: 75.0,
            stringValue: nil,
            source: "Test Device",
            privacyConsentGiven: true
        )
        mockSwiftDataManager.mockFetchResults = [testEntry]
        
        // When
        try await healthDataManager.deleteHealthData(testId)
        
        // Then
        XCTAssertTrue(mockSwiftDataManager.deleteCalled)
        XCTAssertTrue(mockCloudKitSyncManager.deleteCalled)
    }
    
    func testDeleteHealthDataRecordNotFound() async throws {
        // Given
        mockSwiftDataManager.modelContainer = modelContainer
        await healthDataManager.initialize()
        
        let testId = UUID()
        mockSwiftDataManager.mockFetchResults = []
        
        // When & Then
        do {
            try await healthDataManager.deleteHealthData(testId)
            XCTFail("Should throw error when record not found")
        } catch {
            XCTAssertTrue(error is HealthDataError)
        }
    }
    
    // MARK: - Update Health Data Tests
    
    func testUpdateHealthData() async throws {
        // Given
        mockSwiftDataManager.modelContainer = modelContainer
        await healthDataManager.initialize()
        
        let testId = UUID()
        let healthData = CoreHealthDataModel(
            id: testId,
            timestamp: Date(),
            sourceDevice: "Test Device",
            dataType: .heartRate,
            metricValue: 80.0,
            unit: "bpm",
            metadata: nil
        )
        
        let testEntry = HealthDataEntry(
            timestamp: Date(),
            dataType: "HEART_RATE",
            value: 75.0,
            stringValue: nil,
            source: "Test Device",
            privacyConsentGiven: true
        )
        mockSwiftDataManager.mockFetchResults = [testEntry]
        
        // When
        try await healthDataManager.updateHealthData(healthData)
        
        // Then
        XCTAssertTrue(mockSwiftDataManager.updateCalled)
        XCTAssertTrue(mockCloudKitSyncManager.upsertCalled)
    }
    
    // MARK: - Error Handling Tests
    
    func testSaveHealthDataError() async throws {
        // Given
        mockSwiftDataManager.modelContainer = modelContainer
        mockSwiftDataManager.shouldThrowError = true
        await healthDataManager.initialize()
        
        let healthData = CoreHealthDataModel(
            id: UUID(),
            timestamp: Date(),
            sourceDevice: "Test Device",
            dataType: .heartRate,
            metricValue: 75.0,
            unit: "bpm",
            metadata: nil
        )
        
        // When & Then
        do {
            try await healthDataManager.saveHealthData(healthData)
            XCTFail("Should throw error when save fails")
        } catch {
            XCTAssertTrue(error is HealthDataError)
        }
    }
    
    func testFetchHealthDataError() async throws {
        // Given
        mockSwiftDataManager.modelContainer = modelContainer
        mockSwiftDataManager.shouldThrowError = true
        await healthDataManager.initialize()
        
        let startDate = Date().addingTimeInterval(-86400)
        let endDate = Date()
        
        // When & Then
        do {
            _ = try await healthDataManager.fetchHealthData(
                startDate: startDate,
                endDate: endDate,
                dataType: .heartRate
            )
            XCTFail("Should throw error when fetch fails")
        } catch {
            XCTAssertTrue(error is HealthDataError)
        }
    }
}

// MARK: - Mock Classes

@available(iOS 18.0, macOS 15.0, *)
class MockSwiftDataManager: SwiftDataManager {
    var saveCalled = false
    var fetchCalled = false
    var deleteCalled = false
    var updateCalled = false
    var shouldThrowError = false
    var mockFetchResults: [HealthDataEntry] = []
    
    override func save<T>(_ model: T) async throws where T : PersistentModel, T : CKSyncable {
        if shouldThrowError {
            throw SwiftDataError.saveFailed("Mock error")
        }
        saveCalled = true
    }
    
    override func fetch<T>(_ modelType: T.Type, predicate: Predicate<T>? = nil, sortBy: [SortDescriptor<T>] = []) async throws -> [T] where T : PersistentModel, T : CKSyncable {
        if shouldThrowError {
            throw SwiftDataError.fetchFailed("Mock error")
        }
        fetchCalled = true
        return mockFetchResults as! [T]
    }
    
    override func delete<T>(_ model: T) async throws where T : PersistentModel, T : CKSyncable {
        if shouldThrowError {
            throw SwiftDataError.deleteFailed("Mock error")
        }
        deleteCalled = true
    }
    
    override func update<T>(_ model: T) async throws where T : PersistentModel, T : CKSyncable {
        if shouldThrowError {
            throw SwiftDataError.updateFailed("Mock error")
        }
        updateCalled = true
    }
}

@available(iOS 18.0, macOS 15.0, *)
class MockUnifiedCloudKitSyncManager: UnifiedCloudKitSyncManager {
    var upsertCalled = false
    var deleteCalled = false
    
    override func upsert<T>(_ model: T) async throws where T : PersistentModel, T : CKSyncable {
        upsertCalled = true
    }
    
    override func delete<T>(_ model: T) async throws where T : PersistentModel, T : CKSyncable {
        deleteCalled = true
    }
}

class MockPrivacySecurityManager: PrivacySecurityManager {
    override func isSharingAllowed(for dataType: PrivacySettings.DataType) -> Bool {
        return true
    }
} 
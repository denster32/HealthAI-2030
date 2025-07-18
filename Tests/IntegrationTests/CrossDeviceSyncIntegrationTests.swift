import XCTest
import CloudKit
import Combine
@testable import HealthAI2030

@available(iOS 17.0, macOS 14.0, watchOS 10.0, tvOS 17.0, *)
final class CrossDeviceSyncIntegrationTests: XCTestCase {
    
    var syncOrchestrator: CrossDeviceSyncOrchestrator!
    var cloudKitService: CloudKitService!
    var conflictResolver: ConflictResolutionService!
    var encryptionService: DataEncryptionService!
    var networkMonitor: NetworkMonitorService!
    var cancellables: Set<AnyCancellable>!
    
    // Mock devices for testing
    var mockiPhone: MockDevice!
    var mockiPad: MockDevice!
    var mockWatch: MockDevice!
    var mockMac: MockDevice!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Initialize core services
        cloudKitService = CloudKitService()
        conflictResolver = ConflictResolutionService()
        encryptionService = DataEncryptionService()
        networkMonitor = NetworkMonitorService()
        syncOrchestrator = CrossDeviceSyncOrchestrator(
            cloudKitService: cloudKitService,
            conflictResolver: conflictResolver,
            encryptionService: encryptionService,
            networkMonitor: networkMonitor
        )
        
        cancellables = Set<AnyCancellable>()
        
        // Set up mock devices
        mockiPhone = MockDevice(type: .iPhone, name: "Test iPhone")
        mockiPad = MockDevice(type: .iPad, name: "Test iPad")
        mockWatch = MockDevice(type: .watch, name: "Test Watch")
        mockMac = MockDevice(type: .mac, name: "Test Mac")
        
        // Configure test environment
        try await setupTestEnvironment()
    }
    
    override func tearDown() async throws {
        await cleanupTestEnvironment()
        cancellables = nil
        syncOrchestrator = nil
        cloudKitService = nil
        conflictResolver = nil
        encryptionService = nil
        networkMonitor = nil
        try await super.tearDown()
    }
    
    // MARK: - Basic Sync Tests
    
    func testBasicTwoDeviceSync() async throws {
        // Test basic sync between iPhone and iPad
        let healthData = createMockHealthData(type: .heartRate, value: 72.0, device: mockiPhone)
        
        // Device 1 (iPhone) creates data
        try await syncOrchestrator.syncData(healthData, from: mockiPhone)
        
        // Device 2 (iPad) should receive the data
        let syncedData = try await syncOrchestrator.fetchData(for: mockiPad, type: .heartRate)
        
        XCTAssertEqual(syncedData.count, 1)
        XCTAssertEqual(syncedData.first?.value, 72.0)
        XCTAssertEqual(syncedData.first?.sourceDeviceId, mockiPhone.id)
    }
    
    func testMultiDeviceSync() async throws {
        // Test sync across iPhone, iPad, Watch, and Mac
        let devices = [mockiPhone, mockiPad, mockWatch, mockMac]
        let healthDataItems = [
            createMockHealthData(type: .heartRate, value: 72.0, device: mockiPhone),
            createMockHealthData(type: .bloodPressure, value: 120.0, device: mockiPad),
            createMockHealthData(type: .steps, value: 5000.0, device: mockWatch),
            createMockHealthData(type: .sleepDuration, value: 8.0, device: mockMac)
        ]
        
        // Each device creates data
        for (index, healthData) in healthDataItems.enumerated() {
            try await syncOrchestrator.syncData(healthData, from: devices[index]!)
        }
        
        // Wait for sync to complete
        try await Task.sleep(for: .milliseconds(500))
        
        // Each device should have all data
        for device in devices {
            let allData = try await syncOrchestrator.fetchAllData(for: device!)
            XCTAssertEqual(allData.count, 4)
            
            // Verify each type is present
            XCTAssertTrue(allData.contains { $0.type == .heartRate })
            XCTAssertTrue(allData.contains { $0.type == .bloodPressure })
            XCTAssertTrue(allData.contains { $0.type == .steps })
            XCTAssertTrue(allData.contains { $0.type == .sleepDuration })
        }
    }
    
    // MARK: - Conflict Resolution Tests
    
    func testSimultaneousDataModification() async throws {
        let initialData = createMockHealthData(type: .weight, value: 70.0, device: mockiPhone)
        
        // Initial sync
        try await syncOrchestrator.syncData(initialData, from: mockiPhone)
        
        // Both devices modify the same data simultaneously
        let iPhoneUpdate = createMockHealthData(type: .weight, value: 71.0, device: mockiPhone, timestamp: Date())
        let iPadUpdate = createMockHealthData(type: .weight, value: 69.5, device: mockiPad, timestamp: Date().addingTimeInterval(1))
        
        // Simulate simultaneous updates
        async let iPhoneSync: Void = syncOrchestrator.syncData(iPhoneUpdate, from: mockiPhone)
        async let iPadSync: Void = syncOrchestrator.syncData(iPadUpdate, from: mockiPad)
        
        try await iPhoneSync
        try await iPadSync
        
        // Wait for conflict resolution
        try await Task.sleep(for: .milliseconds(1000))
        
        // Verify conflict resolution (latest timestamp should win)
        let resolvedData = try await syncOrchestrator.fetchData(for: mockiPhone, type: .weight)
        XCTAssertEqual(resolvedData.count, 1)
        XCTAssertEqual(resolvedData.first?.value, 69.5) // iPad's update was later
    }
    
    func testConflictResolutionStrategies() async throws {
        // Test different conflict resolution strategies
        let strategies: [ConflictResolutionStrategy] = [
            .lastWriteWins,
            .mergeChanges,
            .userChoice,
            .devicePriority
        ]
        
        for strategy in strategies {
            conflictResolver.setStrategy(strategy)
            
            let data1 = createMockHealthData(type: .heartRate, value: 72.0, device: mockiPhone)
            let data2 = createMockHealthData(type: .heartRate, value: 74.0, device: mockiPad)
            
            try await syncOrchestrator.syncData(data1, from: mockiPhone)
            try await syncOrchestrator.syncData(data2, from: mockiPad)
            
            let resolvedData = try await syncOrchestrator.fetchData(for: mockiPhone, type: .heartRate)
            
            switch strategy {
            case .lastWriteWins:
                XCTAssertEqual(resolvedData.last?.value, 74.0)
            case .devicePriority:
                // iPhone has higher priority in our test setup
                XCTAssertEqual(resolvedData.last?.value, 72.0)
            default:
                XCTAssertGreaterThan(resolvedData.count, 0)
            }
        }
    }
    
    // MARK: - Network Conditions Tests
    
    func testSyncWithPoorNetworkConditions() async throws {
        // Simulate poor network conditions
        networkMonitor.simulateNetworkCondition(.poor)
        
        let healthData = createMockHealthData(type: .heartRate, value: 75.0, device: mockiPhone)
        
        let startTime = Date()
        try await syncOrchestrator.syncData(healthData, from: mockiPhone)
        let syncDuration = Date().timeIntervalSince(startTime)
        
        // Should take longer with poor network
        XCTAssertGreaterThan(syncDuration, 0.5)
        
        // But should still succeed
        let syncedData = try await syncOrchestrator.fetchData(for: mockiPad, type: .heartRate)
        XCTAssertEqual(syncedData.count, 1)
    }
    
    func testOfflineToOnlineSync() async throws {
        // Start offline
        networkMonitor.simulateNetworkCondition(.offline)
        
        let offlineData = [
            createMockHealthData(type: .steps, value: 1000.0, device: mockiPhone),
            createMockHealthData(type: .heartRate, value: 68.0, device: mockiPhone),
            createMockHealthData(type: .sleep, value: 7.5, device: mockiPhone)
        ]
        
        // Queue data while offline
        for data in offlineData {
            try await syncOrchestrator.queueDataForSync(data, from: mockiPhone)
        }
        
        // Verify data is queued but not synced
        let queuedItems = await syncOrchestrator.getQueuedItemsCount(for: mockiPhone)
        XCTAssertEqual(queuedItems, 3)
        
        // Go back online
        networkMonitor.simulateNetworkCondition(.excellent)
        
        // Trigger sync
        try await syncOrchestrator.processSyncQueue(for: mockiPhone)
        
        // Wait for sync to complete
        try await Task.sleep(for: .seconds(2))
        
        // Verify all queued data was synced
        let finalQueuedItems = await syncOrchestrator.getQueuedItemsCount(for: mockiPhone)
        XCTAssertEqual(finalQueuedItems, 0)
        
        // Verify data is available on other devices
        let syncedData = try await syncOrchestrator.fetchAllData(for: mockiPad)
        XCTAssertEqual(syncedData.count, 3)
    }
    
    // MARK: - Data Encryption Tests
    
    func testDataEncryptionDuringSync() async throws {
        let sensitiveData = createMockHealthData(type: .medicalHistory, value: 1.0, device: mockiPhone)
        sensitiveData.isEncrypted = true
        
        // Sync encrypted data
        try await syncOrchestrator.syncData(sensitiveData, from: mockiPhone)
        
        // Verify data is encrypted in transit and at rest
        let rawCloudData = try await cloudKitService.fetchRawData(for: sensitiveData.id)
        XCTAssertTrue(rawCloudData.isEncrypted)
        
        // Verify data can be decrypted on receiving device
        let decryptedData = try await syncOrchestrator.fetchData(for: mockiPad, type: .medicalHistory)
        XCTAssertEqual(decryptedData.count, 1)
        XCTAssertEqual(decryptedData.first?.value, 1.0)
    }
    
    func testEncryptionKeyRotation() async throws {
        let data1 = createMockHealthData(type: .heartRate, value: 72.0, device: mockiPhone)
        try await syncOrchestrator.syncData(data1, from: mockiPhone)
        
        // Rotate encryption keys
        try await encryptionService.rotateKeys()
        
        // Sync more data with new keys
        let data2 = createMockHealthData(type: .heartRate, value: 74.0, device: mockiPhone)
        try await syncOrchestrator.syncData(data2, from: mockiPhone)
        
        // Both old and new data should be accessible
        let allData = try await syncOrchestrator.fetchData(for: mockiPad, type: .heartRate)
        XCTAssertEqual(allData.count, 2)
        XCTAssertTrue(allData.contains { $0.value == 72.0 })
        XCTAssertTrue(allData.contains { $0.value == 74.0 })
    }
    
    // MARK: - Large Dataset Tests
    
    func testLargeDatasetSync() async throws {
        let largeDataset = (0..<1000).map { i in
            createMockHealthData(
                type: .heartRate,
                value: Double(60 + i % 40),
                device: mockiPhone,
                timestamp: Date().addingTimeInterval(TimeInterval(i * -60)) // 1 minute intervals
            )
        }
        
        let startTime = Date()
        
        // Sync large dataset
        try await syncOrchestrator.syncBatchData(largeDataset, from: mockiPhone)
        
        let syncDuration = Date().timeIntervalSince(startTime)
        XCTAssertLessThan(syncDuration, 30.0) // Should complete within 30 seconds
        
        // Verify all data synced
        let syncedData = try await syncOrchestrator.fetchData(for: mockiPad, type: .heartRate)
        XCTAssertEqual(syncedData.count, 1000)
    }
    
    func testBatchSyncPerformance() async throws {
        let batchSizes = [10, 50, 100, 500]
        var results: [Int: TimeInterval] = [:]
        
        for batchSize in batchSizes {
            let dataset = (0..<batchSize).map { i in
                createMockHealthData(type: .steps, value: Double(i * 100), device: mockiPhone)
            }
            
            let startTime = Date()
            try await syncOrchestrator.syncBatchData(dataset, from: mockiPhone)
            let duration = Date().timeIntervalSince(startTime)
            
            results[batchSize] = duration
            
            // Clean up for next test
            try await cloudKitService.deleteAllData(ofType: .steps)
        }
        
        // Verify performance scales reasonably
        XCTAssertLessThan(results[10]!, 5.0)
        XCTAssertLessThan(results[500]!, 30.0)
        
        // Larger batches should be more efficient per item
        let efficiency10 = results[10]! / 10
        let efficiency500 = results[500]! / 500
        XCTAssertLessThan(efficiency500, efficiency10)
    }
    
    // MARK: - Device Priority Tests
    
    func testDevicePriorityHierarchy() async throws {
        // Set up device priorities (iPhone > iPad > Watch > Mac in our test)
        syncOrchestrator.setDevicePriority(mockiPhone, priority: 100)
        syncOrchestrator.setDevicePriority(mockiPad, priority: 80)
        syncOrchestrator.setDevicePriority(mockWatch, priority: 60)
        syncOrchestrator.setDevicePriority(mockMac, priority: 40)
        
        // Create conflicting data from different priority devices
        let iPhoneData = createMockHealthData(type: .weight, value: 70.0, device: mockiPhone)
        let watchData = createMockHealthData(type: .weight, value: 71.0, device: mockWatch)
        
        // Sync from lower priority device first
        try await syncOrchestrator.syncData(watchData, from: mockWatch)
        
        // Then sync from higher priority device
        try await syncOrchestrator.syncData(iPhoneData, from: mockiPhone)
        
        // Higher priority device should win
        let resolvedData = try await syncOrchestrator.fetchData(for: mockiPad, type: .weight)
        XCTAssertEqual(resolvedData.last?.value, 70.0) // iPhone value
        XCTAssertEqual(resolvedData.last?.sourceDeviceId, mockiPhone.id)
    }
    
    // MARK: - Real-time Sync Tests
    
    func testRealTimeSyncNotifications() async throws {
        let expectation = XCTestExpectation(description: "Real-time sync notification")
        
        // Set up real-time sync listener on iPad
        syncOrchestrator.startRealTimeSync(for: mockiPad)
            .sink { syncEvent in
                if case .dataUpdated(let data) = syncEvent,
                   data.type == .heartRate {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // Create data on iPhone
        let heartRateData = createMockHealthData(type: .heartRate, value: 78.0, device: mockiPhone)
        try await syncOrchestrator.syncData(heartRateData, from: mockiPhone)
        
        await fulfillment(of: [expectation], timeout: 5.0)
    }
    
    func testRealTimeSyncMultipleSubscribers() async throws {
        let ipadExpectation = XCTestExpectation(description: "iPad sync notification")
        let watchExpectation = XCTestExpectation(description: "Watch sync notification")
        let macExpectation = XCTestExpectation(description: "Mac sync notification")
        
        // Set up multiple subscribers
        syncOrchestrator.startRealTimeSync(for: mockiPad)
            .sink { _ in ipadExpectation.fulfill() }
            .store(in: &cancellables)
        
        syncOrchestrator.startRealTimeSync(for: mockWatch)
            .sink { _ in watchExpectation.fulfill() }
            .store(in: &cancellables)
        
        syncOrchestrator.startRealTimeSync(for: mockMac)
            .sink { _ in macExpectation.fulfill() }
            .store(in: &cancellables)
        
        // Create data on iPhone
        let data = createMockHealthData(type: .bloodPressure, value: 120.0, device: mockiPhone)
        try await syncOrchestrator.syncData(data, from: mockiPhone)
        
        await fulfillment(of: [ipadExpectation, watchExpectation, macExpectation], timeout: 5.0)
    }
    
    // MARK: - Error Recovery Tests
    
    func testSyncFailureRecovery() async throws {
        // Simulate CloudKit failure
        cloudKitService.simulateFailure(.networkUnavailable)
        
        let healthData = createMockHealthData(type: .heartRate, value: 76.0, device: mockiPhone)
        
        do {
            try await syncOrchestrator.syncData(healthData, from: mockiPhone)
            XCTFail("Expected sync to fail")
        } catch {
            // Expected failure
        }
        
        // Verify data is queued for retry
        let queuedItems = await syncOrchestrator.getQueuedItemsCount(for: mockiPhone)
        XCTAssertEqual(queuedItems, 1)
        
        // Restore CloudKit functionality
        cloudKitService.simulateFailure(nil)
        
        // Trigger retry
        try await syncOrchestrator.retryFailedSyncs(for: mockiPhone)
        
        // Verify sync succeeded
        let syncedData = try await syncOrchestrator.fetchData(for: mockiPad, type: .heartRate)
        XCTAssertEqual(syncedData.count, 1)
        XCTAssertEqual(syncedData.first?.value, 76.0)
    }
    
    func testPartialSyncFailureRecovery() async throws {
        let mixedDataset = [
            createMockHealthData(type: .heartRate, value: 72.0, device: mockiPhone),
            createMockHealthData(type: .invalidType, value: 0.0, device: mockiPhone), // This will fail
            createMockHealthData(type: .steps, value: 5000.0, device: mockiPhone)
        ]
        
        // Attempt batch sync with mixed success
        let results = await syncOrchestrator.syncBatchDataWithResults(mixedDataset, from: mockiPhone)
        
        // Verify partial success
        XCTAssertEqual(results.successful.count, 2)
        XCTAssertEqual(results.failed.count, 1)
        
        // Verify successful items were synced
        let heartRateData = try await syncOrchestrator.fetchData(for: mockiPad, type: .heartRate)
        let stepsData = try await syncOrchestrator.fetchData(for: mockiPad, type: .steps)
        
        XCTAssertEqual(heartRateData.count, 1)
        XCTAssertEqual(stepsData.count, 1)
    }
    
    // MARK: - Memory and Performance Tests
    
    func testSyncMemoryUsage() async throws {
        let initialMemory = getCurrentMemoryUsage()
        
        // Sync large amount of data
        let largeDataset = (0..<5000).map { i in
            createMockHealthData(type: .heartRate, value: Double(i), device: mockiPhone)
        }
        
        try await syncOrchestrator.syncBatchData(largeDataset, from: mockiPhone)
        
        let peakMemory = getCurrentMemoryUsage()
        let memoryIncrease = peakMemory - initialMemory
        
        // Memory increase should be reasonable (less than 100MB for this test)
        XCTAssertLessThan(memoryIncrease, 100 * 1024 * 1024)
        
        // Force cleanup
        try await syncOrchestrator.cleanup()
        
        let finalMemory = getCurrentMemoryUsage()
        let memoryRetained = finalMemory - initialMemory
        
        // Most memory should be released
        XCTAssertLessThan(memoryRetained, 10 * 1024 * 1024)
    }
    
    // MARK: - Helper Methods
    
    private func setupTestEnvironment() async throws {
        // Configure test CloudKit container
        try await cloudKitService.configureTestContainer()
        
        // Set up encryption service
        try await encryptionService.initializeTestKeys()
        
        // Configure network monitor for testing
        networkMonitor.enableTestMode()
        
        // Clear any existing test data
        try await cloudKitService.deleteAllTestData()
    }
    
    private func cleanupTestEnvironment() async {
        try? await cloudKitService.deleteAllTestData()
        syncOrchestrator.stopAllRealTimeSync()
        networkMonitor.disableTestMode()
    }
    
    private func createMockHealthData(
        type: HealthDataType,
        value: Double,
        device: MockDevice,
        timestamp: Date = Date()
    ) -> HealthData {
        return HealthData(
            id: UUID(),
            type: type,
            value: value,
            timestamp: timestamp,
            sourceDeviceId: device.id,
            sourceDeviceType: device.type,
            isEncrypted: false
        )
    }
    
    private func getCurrentMemoryUsage() -> UInt64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        return kerr == KERN_SUCCESS ? UInt64(info.resident_size) : 0
    }
}

// MARK: - Mock Classes and Supporting Types

class MockDevice {
    let id: String
    let type: DeviceType
    let name: String
    
    init(type: DeviceType, name: String) {
        self.id = UUID().uuidString
        self.type = type
        self.name = name
    }
}

enum DeviceType: String, CaseIterable {
    case iPhone = "iPhone"
    case iPad = "iPad"
    case watch = "Apple Watch"
    case mac = "Mac"
}

enum HealthDataType: String, CaseIterable {
    case heartRate = "heart_rate"
    case bloodPressure = "blood_pressure"
    case steps = "steps"
    case sleepDuration = "sleep_duration"
    case weight = "weight"
    case medicalHistory = "medical_history"
    case sleep = "sleep"
    case invalidType = "invalid_type"
}

struct HealthData {
    let id: UUID
    let type: HealthDataType
    let value: Double
    let timestamp: Date
    let sourceDeviceId: String
    let sourceDeviceType: DeviceType
    var isEncrypted: Bool
}

enum SyncEvent {
    case dataUpdated(HealthData)
    case dataDeleted(UUID)
    case conflictResolved(HealthData, HealthData)
    case syncCompleted
}

enum ConflictResolutionStrategy {
    case lastWriteWins
    case mergeChanges
    case userChoice
    case devicePriority
}

enum NetworkCondition {
    case excellent
    case good
    case poor
    case offline
}

enum CloudKitError {
    case networkUnavailable
    case quotaExceeded
    case zoneNotFound
    case recordNotFound
}

struct SyncResults {
    let successful: [HealthData]
    let failed: [HealthData]
}

// MARK: - Mock Service Implementations

class CloudKitService {
    private var shouldFail: CloudKitError?
    private var testData: [UUID: HealthData] = [:]
    
    func configureTestContainer() async throws {
        // Mock CloudKit container setup
    }
    
    func deleteAllTestData() async throws {
        testData.removeAll()
    }
    
    func deleteAllData(ofType type: HealthDataType) async throws {
        testData = testData.filter { $0.value.type != type }
    }
    
    func fetchRawData(for id: UUID) async throws -> MockCloudData {
        guard shouldFail == nil else {
            throw shouldFail!
        }
        
        return MockCloudData(isEncrypted: true)
    }
    
    func simulateFailure(_ error: CloudKitError?) {
        shouldFail = error
    }
}

class ConflictResolutionService {
    private var strategy: ConflictResolutionStrategy = .lastWriteWins
    
    func setStrategy(_ strategy: ConflictResolutionStrategy) {
        self.strategy = strategy
    }
}

class DataEncryptionService {
    func initializeTestKeys() async throws {
        // Mock encryption key setup
    }
    
    func rotateKeys() async throws {
        // Mock key rotation
    }
}

class NetworkMonitorService {
    private var currentCondition: NetworkCondition = .excellent
    private var testMode = false
    
    func simulateNetworkCondition(_ condition: NetworkCondition) {
        guard testMode else { return }
        currentCondition = condition
    }
    
    func enableTestMode() {
        testMode = true
    }
    
    func disableTestMode() {
        testMode = false
    }
}

struct MockCloudData {
    let isEncrypted: Bool
}

// MARK: - CrossDeviceSyncOrchestrator Mock Implementation

class CrossDeviceSyncOrchestrator {
    private let cloudKitService: CloudKitService
    private let conflictResolver: ConflictResolutionService
    private let encryptionService: DataEncryptionService
    private let networkMonitor: NetworkMonitorService
    
    private var syncQueue: [String: [HealthData]] = [:]
    private var devicePriorities: [String: Int] = [:]
    private var realTimeSyncSubjects: [String: PassthroughSubject<SyncEvent, Never>] = [:]
    
    init(
        cloudKitService: CloudKitService,
        conflictResolver: ConflictResolutionService,
        encryptionService: DataEncryptionService,
        networkMonitor: NetworkMonitorService
    ) {
        self.cloudKitService = cloudKitService
        self.conflictResolver = conflictResolver
        self.encryptionService = encryptionService
        self.networkMonitor = networkMonitor
    }
    
    func syncData(_ data: HealthData, from device: MockDevice) async throws {
        // Mock sync implementation
        try await Task.sleep(for: .milliseconds(100))
    }
    
    func fetchData(for device: MockDevice, type: HealthDataType) async throws -> [HealthData] {
        // Mock fetch implementation
        return []
    }
    
    func fetchAllData(for device: MockDevice) async throws -> [HealthData] {
        // Mock fetch all implementation
        return []
    }
    
    func queueDataForSync(_ data: HealthData, from device: MockDevice) async throws {
        var queue = syncQueue[device.id] ?? []
        queue.append(data)
        syncQueue[device.id] = queue
    }
    
    func getQueuedItemsCount(for device: MockDevice) async -> Int {
        return syncQueue[device.id]?.count ?? 0
    }
    
    func processSyncQueue(for device: MockDevice) async throws {
        syncQueue[device.id] = []
    }
    
    func syncBatchData(_ data: [HealthData], from device: MockDevice) async throws {
        // Mock batch sync
        try await Task.sleep(for: .milliseconds(500))
    }
    
    func syncBatchDataWithResults(_ data: [HealthData], from device: MockDevice) async -> SyncResults {
        let successful = data.filter { $0.type != .invalidType }
        let failed = data.filter { $0.type == .invalidType }
        return SyncResults(successful: successful, failed: failed)
    }
    
    func setDevicePriority(_ device: MockDevice, priority: Int) {
        devicePriorities[device.id] = priority
    }
    
    func startRealTimeSync(for device: MockDevice) -> AnyPublisher<SyncEvent, Never> {
        let subject = PassthroughSubject<SyncEvent, Never>()
        realTimeSyncSubjects[device.id] = subject
        return subject.eraseToAnyPublisher()
    }
    
    func stopAllRealTimeSync() {
        realTimeSyncSubjects.removeAll()
    }
    
    func retryFailedSyncs(for device: MockDevice) async throws {
        // Mock retry implementation
    }
    
    func cleanup() async throws {
        // Mock cleanup
    }
}
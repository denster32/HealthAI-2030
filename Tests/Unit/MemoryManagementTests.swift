import XCTest
import Combine
@testable import HealthAI2030

final class MemoryManagementTests: XCTestCase {
    
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDown() {
        cancellables = nil
        super.tearDown()
    }
    
    // MARK: - Weak Reference Tests
    
    func testWeakReferencesInClosures() {
        var performanceMonitor: AdvancedPerformanceMonitor? = AdvancedPerformanceMonitor()
        weak var weakMonitor = performanceMonitor
        
        // Test that closure captures don't create retain cycles
        performanceMonitor?.$currentMetrics
            .sink { [weak performanceMonitor] metrics in
                XCTAssertNotNil(performanceMonitor)
                // Use weakly captured reference
                _ = performanceMonitor?.isMonitoring
            }
            .store(in: &cancellables)
        
        // Release strong reference
        performanceMonitor = nil
        
        // Weak reference should be nil after strong reference is released
        XCTAssertNil(weakMonitor)
    }
    
    func testTimerMemoryLeaks() async {
        var monitor: AdvancedPerformanceMonitor? = AdvancedPerformanceMonitor()
        weak var weakMonitor = monitor
        
        // Start monitoring which creates timer
        try? monitor?.startMonitoring(interval: 0.1)
        
        // Wait briefly
        try? await Task.sleep(for: .milliseconds(100))
        
        // Stop monitoring to clean up timer
        monitor?.stopMonitoring()
        
        // Release monitor
        monitor = nil
        
        // Wait for cleanup
        try? await Task.sleep(for: .milliseconds(100))
        
        // Should be deallocated
        XCTAssertNil(weakMonitor)
    }
    
    // MARK: - Actor Memory Management Tests
    
    func testActorMemoryIsolation() async {
        let sleepEngine = SleepIntelligenceEngine.shared
        
        // Measure initial memory
        let initialMemory = getCurrentMemoryUsage()
        
        // Perform memory-intensive operations
        for _ in 0..<100 {
            let state = SleepState(
                id: UUID(),
                timestamp: Date(),
                sleepStage: .deep,
                heartRateVariability: 45.0,
                bodyTemperature: 36.5,
                movementLevel: 0.1,
                environmentalFactors: EnvironmentalFactors(
                    lightLevel: 0,
                    noiseLevel: 20,
                    temperature: 20,
                    humidity: 40
                )
            )
            
            await sleepEngine.updateSleepState(state)
        }
        
        let peakMemory = getCurrentMemoryUsage()
        let memoryIncrease = peakMemory - initialMemory
        
        // Memory increase should be reasonable
        XCTAssertLessThan(memoryIncrease, 50 * 1024 * 1024) // Less than 50MB
    }
    
    // MARK: - Collection Memory Tests
    
    func testLargeCollectionMemoryUsage() {
        let initialMemory = getCurrentMemoryUsage()
        
        // Create large collection
        var largeArray: [String] = []
        for i in 0..<100000 {
            largeArray.append("Item \(i)")
        }
        
        let peakMemory = getCurrentMemoryUsage()
        
        // Clear collection
        largeArray.removeAll()
        
        let finalMemory = getCurrentMemoryUsage()
        
        // Memory should be released after clearing
        let memoryRetained = finalMemory - initialMemory
        XCTAssertLessThan(memoryRetained, 10 * 1024 * 1024) // Less than 10MB retained
    }
    
    func testDictionaryCacheMemoryLeaks() {
        var cache: [String: Data] = [:]
        let initialMemory = getCurrentMemoryUsage()
        
        // Fill cache with data
        for i in 0..<1000 {
            let data = Data(repeating: UInt8(i % 256), count: 1024) // 1KB each
            cache["key\(i)"] = data
        }
        
        let peakMemory = getCurrentMemoryUsage()
        
        // Clear cache
        cache.removeAll()
        
        let finalMemory = getCurrentMemoryUsage()
        
        // Most memory should be released
        let memoryRetained = finalMemory - initialMemory
        XCTAssertLessThan(memoryRetained, 5 * 1024 * 1024) // Less than 5MB retained
    }
    
    // MARK: - Combine Memory Tests
    
    func testCombinePublisherMemoryLeaks() {
        var publisher: PassthroughSubject<String, Never>? = PassthroughSubject()
        weak var weakPublisher = publisher
        
        // Create subscription
        publisher?.sink { value in
            print("Received: \(value)")
        }
        .store(in: &cancellables)
        
        // Send some values
        publisher?.send("test1")
        publisher?.send("test2")
        
        // Complete publisher
        publisher?.send(completion: .finished)
        publisher = nil
        
        // Publisher should be deallocated
        XCTAssertNil(weakPublisher)
    }
    
    func testCombineRetainCycles() {
        class TestObservableObject: ObservableObject {
            @Published var value: String = ""
            private var cancellables = Set<AnyCancellable>()
            
            init() {
                // Test potential retain cycle with self capture
                $value
                    .sink { [weak self] newValue in
                        self?.handleValueChange(newValue)
                    }
                    .store(in: &cancellables)
            }
            
            private func handleValueChange(_ value: String) {
                // Handle value change
            }
        }
        
        var testObject: TestObservableObject? = TestObservableObject()
        weak var weakTestObject = testObject
        
        testObject?.value = "test"
        testObject = nil
        
        // Should be deallocated despite internal subscriptions
        XCTAssertNil(weakTestObject)
    }
    
    // MARK: - Task Memory Tests
    
    func testAsyncTaskMemoryCleanup() async {
        let concurrencyManager = OptimizedConcurrencyManager.shared
        let initialMemory = getCurrentMemoryUsage()
        
        // Execute many concurrent tasks
        let tasks = (0..<100).map { i in
            return ("task\(i)", {
                try await Task.sleep(for: .milliseconds(10))
                return "result\(i)"
            })
        }
        
        let results = await concurrencyManager.executeConcurrentTasks(tasks: tasks)
        
        let peakMemory = getCurrentMemoryUsage()
        
        // Wait for cleanup
        try? await Task.sleep(for: .milliseconds(500))
        
        let finalMemory = getCurrentMemoryUsage()
        
        // Verify tasks completed
        XCTAssertEqual(results.count, 100)
        
        // Memory should be cleaned up
        let memoryRetained = finalMemory - initialMemory
        XCTAssertLessThan(memoryRetained, 20 * 1024 * 1024) // Less than 20MB retained
    }
    
    // MARK: - Core Data Memory Tests
    
    func testCoreDataMemoryPressure() {
        // Simulate Core Data memory pressure
        let initialMemory = getCurrentMemoryUsage()
        
        // Create many managed objects (simulated)
        var objects: [MockManagedObject] = []
        for i in 0..<10000 {
            objects.append(MockManagedObject(id: i))
        }
        
        let peakMemory = getCurrentMemoryUsage()
        
        // Clear objects
        objects.removeAll()
        
        // Force garbage collection
        autoreleasepool {
            // Simulate Core Data cleanup
        }
        
        let finalMemory = getCurrentMemoryUsage()
        
        // Memory should be mostly released
        let memoryRetained = finalMemory - initialMemory
        XCTAssertLessThan(memoryRetained, 15 * 1024 * 1024) // Less than 15MB retained
    }
    
    // MARK: - Image Memory Tests
    
    func testImageMemoryManagement() {
        let initialMemory = getCurrentMemoryUsage()
        
        // Create large images in memory
        var images: [Data] = []
        for _ in 0..<50 {
            // Simulate 1MB image data
            let imageData = Data(repeating: 0xFF, count: 1024 * 1024)
            images.append(imageData)
        }
        
        let peakMemory = getCurrentMemoryUsage()
        
        // Clear images
        images.removeAll()
        
        let finalMemory = getCurrentMemoryUsage()
        
        // Most memory should be released
        let memoryRetained = finalMemory - initialMemory
        XCTAssertLessThan(memoryRetained, 10 * 1024 * 1024) // Less than 10MB retained
    }
    
    // MARK: - Performance Memory Tests
    
    func testMemoryUsageStability() async {
        let performanceMonitor = AdvancedPerformanceMonitor()
        let initialMemory = getCurrentMemoryUsage()
        
        // Run monitoring for extended period
        try? performanceMonitor.startMonitoring(interval: 0.01) // Very frequent
        
        try? await Task.sleep(for: .seconds(5))
        
        performanceMonitor.stopMonitoring()
        
        let finalMemory = getCurrentMemoryUsage()
        let memoryGrowth = finalMemory > initialMemory ? finalMemory - initialMemory : 0
        
        // Memory growth should be minimal during extended monitoring
        XCTAssertLessThan(memoryGrowth, 30 * 1024 * 1024) // Less than 30MB growth
    }
    
    // MARK: - Helper Methods
    
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
    
    private func measureMemoryUsage<T>(operation: () throws -> T) rethrows -> (result: T, memoryUsed: UInt64) {
        let startMemory = getCurrentMemoryUsage()
        let result = try operation()
        let endMemory = getCurrentMemoryUsage()
        let memoryUsed = endMemory > startMemory ? endMemory - startMemory : 0
        
        return (result: result, memoryUsed: memoryUsed)
    }
}

// MARK: - Mock Classes

class MockManagedObject {
    let id: Int
    let data: Data
    
    init(id: Int) {
        self.id = id
        self.data = Data(repeating: UInt8(id % 256), count: 1024) // 1KB per object
    }
}
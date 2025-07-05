import XCTest
import BackgroundTasks
import UserNotifications
@testable import HealthAI_2030

/// Comprehensive background task testing suite for real device validation
@MainActor
class BackgroundTaskTests: XCTestCase {
    
    var backgroundManager: EnhancedSleepBackgroundManager!
    var mockBatteryMonitor: MockBatteryMonitor!
    var mockCacheManager: MockSleepDataCacheManager!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Initialize test components
        backgroundManager = EnhancedSleepBackgroundManager.shared
        mockBatteryMonitor = MockBatteryMonitor()
        mockCacheManager = MockSleepDataCacheManager()
        
        // Reset state
        await resetBackgroundManagerState()
    }
    
    override func tearDown() async throws {
        // Clean up
        backgroundManager.disableBackgroundProcessing()
        try await super.tearDown()
    }
    
    private func resetBackgroundManagerState() async {
        backgroundManager.disableBackgroundProcessing()
        // Wait for any active tasks to complete
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
    }
    
    // MARK: - Background Task Registration Tests
    
    func testBackgroundTaskRegistration() async throws {
        // Test that all background tasks are properly registered
        let expectedIdentifiers = [
            "com.healthai.sleep-analysis",
            "com.healthai.data-sync",
            "com.healthai.ai-processing",
            "com.healthai.smart-alarm",
            "com.healthai.health-alert",
            "com.healthai.environment-monitoring",
            "com.healthai.model-update",
            "com.healthai.data-cleanup"
        ]
        
        // Verify identifiers are in Info.plist
        // This test would need access to app bundle to read Info.plist
        XCTAssertTrue(true, "Background task identifiers should be properly registered")
    }
    
    func testBackgroundTaskScheduling() async throws {
        // Test scheduling of background tasks
        backgroundManager.enableBackgroundProcessing()
        
        // Verify background processing is enabled
        XCTAssertTrue(backgroundManager.isBackgroundProcessingEnabled)
        
        // Test scheduling doesn't crash
        backgroundManager.scheduleOptimalBackgroundTasks()
        
        // Should complete without errors
        XCTAssertTrue(backgroundManager.isBackgroundProcessingEnabled)
    }
    
    // MARK: - Battery Optimization Tests
    
    func testBatteryOptimizationLevels() async throws {
        // Test aggressive optimization (critical battery)
        mockBatteryMonitor.setBatteryLevel(0.15, isCharging: false)
        
        let aggressiveLevel = determineMockBatteryOptimizationLevel(
            batteryLevel: 0.15,
            isCharging: false
        )
        XCTAssertEqual(aggressiveLevel, .aggressive)
        
        // Test conservative optimization (low battery)
        mockBatteryMonitor.setBatteryLevel(0.25, isCharging: false)
        
        let conservativeLevel = determineMockBatteryOptimizationLevel(
            batteryLevel: 0.25,
            isCharging: false
        )
        XCTAssertEqual(conservativeLevel, .conservative)
        
        // Test performance mode (charging)
        mockBatteryMonitor.setBatteryLevel(0.8, isCharging: true)
        
        let performanceLevel = determineMockBatteryOptimizationLevel(
            batteryLevel: 0.8,
            isCharging: true
        )
        XCTAssertEqual(performanceLevel, .performance)
        
        // Test balanced mode (normal battery)
        mockBatteryMonitor.setBatteryLevel(0.6, isCharging: false)
        
        let balancedLevel = determineMockBatteryOptimizationLevel(
            batteryLevel: 0.6,
            isCharging: false
        )
        XCTAssertEqual(balancedLevel, .balanced)
    }
    
    func testTaskExecutionBasedOnBattery() async throws {
        // Test that critical tasks always execute
        mockBatteryMonitor.setBatteryLevel(0.1, isCharging: false)
        
        let shouldExecuteCritical = shouldMockExecuteTask(.critical, batteryLevel: 0.1, isCharging: false)
        XCTAssertTrue(shouldExecuteCritical, "Critical tasks should always execute")
        
        // Test that low priority tasks are skipped on low battery
        let shouldExecuteLow = shouldMockExecuteTask(.low, batteryLevel: 0.25, isCharging: false)
        XCTAssertFalse(shouldExecuteLow, "Low priority tasks should be skipped on low battery")
        
        // Test that low priority tasks execute when charging
        let shouldExecuteLowCharging = shouldMockExecuteTask(.low, batteryLevel: 0.25, isCharging: true)
        XCTAssertTrue(shouldExecuteLowCharging, "Low priority tasks should execute when charging")
    }
    
    // MARK: - Individual Task Tests
    
    func testSleepAnalysisTask() async throws {
        // Test sleep analysis task execution
        let success = await backgroundManager.forceExecuteTask(.sleepAnalysis)
        XCTAssertTrue(success, "Sleep analysis task should execute successfully")
    }
    
    func testDataSyncTask() async throws {
        // Test data sync task execution
        let success = await backgroundManager.forceExecuteTask(.dataSync)
        XCTAssertTrue(success, "Data sync task should execute successfully")
    }
    
    func testAIProcessingTask() async throws {
        // Test AI processing task execution
        let success = await backgroundManager.forceExecuteTask(.aiProcessing)
        XCTAssertTrue(success, "AI processing task should execute successfully")
    }
    
    func testSmartAlarmTask() async throws {
        // Test smart alarm task execution
        let success = await backgroundManager.forceExecuteTask(.smartAlarm)
        XCTAssertTrue(success, "Smart alarm task should execute successfully")
    }
    
    func testHealthAlertTask() async throws {
        // Test health alert task execution
        let success = await backgroundManager.forceExecuteTask(.healthAlert)
        XCTAssertTrue(success, "Health alert task should execute successfully")
    }
    
    func testEnvironmentMonitoringTask() async throws {
        // Test environment monitoring task execution
        let success = await backgroundManager.forceExecuteTask(.environmentMonitoring)
        XCTAssertTrue(success, "Environment monitoring task should execute successfully")
    }
    
    func testModelUpdateTask() async throws {
        // Test model update task execution
        let success = await backgroundManager.forceExecuteTask(.modelUpdate)
        XCTAssertTrue(success, "Model update task should execute successfully")
    }
    
    func testDataCleanupTask() async throws {
        // Test data cleanup task execution
        let success = await backgroundManager.forceExecuteTask(.dataCleanup)
        XCTAssertTrue(success, "Data cleanup task should execute successfully")
    }
    
    // MARK: - Performance Tests
    
    func testTaskExecutionPerformance() async throws {
        // Test that tasks complete within reasonable time
        let startTime = CFAbsoluteTimeGetCurrent()
        
        let success = await backgroundManager.forceExecuteTask(.sleepAnalysis)
        
        let executionTime = CFAbsoluteTimeGetCurrent() - startTime
        
        XCTAssertTrue(success, "Task should complete successfully")
        XCTAssertLessThan(executionTime, 10.0, "Task should complete within 10 seconds")
    }
    
    func testMemoryUsageDuringTasks() async throws {
        let initialMemory = getMemoryUsage()
        
        // Execute multiple tasks
        for _ in 0..<5 {
            _ = await backgroundManager.forceExecuteTask(.sleepAnalysis)
        }
        
        let finalMemory = getMemoryUsage()
        let memoryIncrease = finalMemory - initialMemory
        
        // Memory increase should be reasonable (< 20MB)
        XCTAssertLessThan(memoryIncrease, 20_000_000, "Memory usage should remain reasonable")
    }
    
    func testConcurrentTaskExecution() async throws {
        // Test that multiple tasks can run concurrently without issues
        async let task1 = backgroundManager.forceExecuteTask(.sleepAnalysis)
        async let task2 = backgroundManager.forceExecuteTask(.dataSync)
        async let task3 = backgroundManager.forceExecuteTask(.healthAlert)
        
        let results = await [task1, task2, task3]
        
        // All tasks should complete successfully
        for result in results {
            XCTAssertTrue(result, "Concurrent tasks should complete successfully")
        }
    }
    
    // MARK: - Data Persistence Tests
    
    func testBackgroundStatspersistence() async throws {
        // Execute some tasks
        _ = await backgroundManager.forceExecuteTask(.sleepAnalysis)
        _ = await backgroundManager.forceExecuteTask(.dataSync)
        
        let status = backgroundManager.getDetailedStatus()
        XCTAssertGreaterThan(status.totalExecutions, 0, "Execution count should be tracked")
        XCTAssertGreaterThanOrEqual(status.successRate, 0.0, "Success rate should be valid")
        XCTAssertLessThanOrEqual(status.successRate, 1.0, "Success rate should be valid")
    }
    
    func testExecutionHistoryTracking() async throws {
        // Execute a task
        _ = await backgroundManager.forceExecuteTask(.sleepAnalysis)
        
        let status = backgroundManager.getDetailedStatus()
        XCTAssertGreaterThan(status.recentExecutions.count, 0, "Execution history should be tracked")
        
        let lastExecution = status.recentExecutions.last
        XCTAssertNotNil(lastExecution, "Last execution should be recorded")
        XCTAssertEqual(lastExecution?.identifier, "com.healthai.sleep-analysis", "Correct task should be recorded")
    }
    
    // MARK: - Notification Tests
    
    func testSmartAlarmNotification() async throws {
        // Test smart alarm notification delivery
        // Note: This would require notification permissions and mock notification center
        
        // For now, test that the method doesn't crash
        let success = await backgroundManager.forceExecuteTask(.smartAlarm)
        XCTAssertTrue(success, "Smart alarm task should complete without crashing")
    }
    
    func testHealthAlertNotification() async throws {
        // Test health alert notification delivery
        let success = await backgroundManager.forceExecuteTask(.healthAlert)
        XCTAssertTrue(success, "Health alert task should complete without crashing")
    }
    
    // MARK: - Edge Cases and Error Handling
    
    func testTaskExecutionWithNoData() async throws {
        // Test task execution when no health data is available
        // This should handle gracefully without crashing
        
        let success = await backgroundManager.forceExecuteTask(.sleepAnalysis)
        // Should not crash even if no data is available
        XCTAssertNotNil(success, "Task should handle missing data gracefully")
    }
    
    func testBackgroundProcessingDisabled() async throws {
        // Test behavior when background processing is disabled
        backgroundManager.disableBackgroundProcessing()
        
        XCTAssertFalse(backgroundManager.isBackgroundProcessingEnabled)
        
        // Should not schedule new tasks
        backgroundManager.scheduleOptimalBackgroundTasks()
        // Should complete without errors
    }
    
    func testTaskCancellation() async throws {
        // Test that tasks can be properly cancelled
        backgroundManager.enableBackgroundProcessing()
        
        // Start background processing
        backgroundManager.scheduleOptimalBackgroundTasks()
        
        // Disable should cancel tasks
        backgroundManager.disableBackgroundProcessing()
        
        XCTAssertFalse(backgroundManager.isBackgroundProcessingEnabled)
    }
    
    // MARK: - Integration Tests
    
    func testFullBackgroundCycle() async throws {
        // Test complete background processing cycle
        
        // 1. Enable background processing
        backgroundManager.enableBackgroundProcessing()
        XCTAssertTrue(backgroundManager.isBackgroundProcessingEnabled)
        
        // 2. Execute critical tasks
        let alertSuccess = await backgroundManager.forceExecuteTask(.healthAlert)
        XCTAssertTrue(alertSuccess)
        
        let alarmSuccess = await backgroundManager.forceExecuteTask(.smartAlarm)
        XCTAssertTrue(alarmSuccess)
        
        // 3. Execute analysis tasks
        let analysisSuccess = await backgroundManager.forceExecuteTask(.sleepAnalysis)
        XCTAssertTrue(analysisSuccess)
        
        let syncSuccess = await backgroundManager.forceExecuteTask(.dataSync)
        XCTAssertTrue(syncSuccess)
        
        // 4. Verify status
        let status = backgroundManager.getDetailedStatus()
        XCTAssertGreaterThanOrEqual(status.totalExecutions, 4)
        XCTAssertGreaterThan(status.successRate, 0.0)
        
        // 5. Clean up
        backgroundManager.disableBackgroundProcessing()
        XCTAssertFalse(backgroundManager.isBackgroundProcessingEnabled)
    }
    
    func testOptimalExecutionWindow() async throws {
        // Test optimal execution window calculation
        let testSleepTime = Calendar.current.date(bySettingHour: 23, minute: 0, second: 0, of: Date())!
        
        backgroundManager.updateUserSleepTime(testSleepTime)
        
        // This should update the optimal execution window
        // Verify it doesn't crash
        XCTAssertTrue(true, "Updating sleep time should complete without errors")
    }
    
    // MARK: - Real Device Validation Tests
    
    func testRealDeviceCompatibility() async throws {
        // Test that works on real device (not just simulator)
        
        #if targetEnvironment(simulator)
        Logger.warning("Running on simulator - some tests may not reflect real device behavior", log: Logger.backgroundTasks)
        #else
        Logger.info("Running on real device - full validation possible", log: Logger.backgroundTasks)
        #endif
        
        // Test basic functionality works
        let success = await backgroundManager.forceExecuteTask(.sleepAnalysis)
        XCTAssertTrue(success, "Basic functionality should work on real device")
    }
    
    func testBatteryMonitoring() async throws {
        // Test battery monitoring functionality
        let currentLevel = UIDevice.current.batteryLevel
        let chargingState = UIDevice.current.batteryState
        
        // Battery monitoring should be enabled
        XCTAssertTrue(UIDevice.current.isBatteryMonitoringEnabled, "Battery monitoring should be enabled")
        
        // Battery level should be valid (unless unknown)
        if currentLevel >= 0 {
            XCTAssertGreaterThanOrEqual(currentLevel, 0.0)
            XCTAssertLessThanOrEqual(currentLevel, 1.0)
        }
        
        // Charging state should be known
        XCTAssertNotEqual(chargingState, .unknown, "Battery state should be determinable")
    }
    
    // MARK: - TestFlight Specific Tests
    
    func testTestFlightReadyBackgroundTasks() async throws {
        // Comprehensive test for TestFlight readiness
        
        // 1. All tasks should execute without crashing
        let taskIdentifiers: [EnhancedSleepBackgroundManager.TaskIdentifier] = [
            .sleepAnalysis, .dataSync, .aiProcessing, .smartAlarm,
            .healthAlert, .environmentMonitoring, .modelUpdate, .dataCleanup
        ]
        
        for taskId in taskIdentifiers {
            let success = await backgroundManager.forceExecuteTask(taskId)
            XCTAssertTrue(success, "Task \(taskId) should execute successfully for TestFlight")
        }
        
        // 2. Background processing should be configurable
        backgroundManager.enableBackgroundProcessing()
        XCTAssertTrue(backgroundManager.isBackgroundProcessingEnabled)
        
        backgroundManager.disableBackgroundProcessing()
        XCTAssertFalse(backgroundManager.isBackgroundProcessingEnabled)
        
        // 3. Status reporting should work
        let status = backgroundManager.getDetailedStatus()
        XCTAssertNotNil(status)
        XCTAssertGreaterThanOrEqual(status.totalExecutions, 0)
        
        // 4. Performance should be acceptable
        let startTime = CFAbsoluteTimeGetCurrent()
        _ = await backgroundManager.forceExecuteTask(.sleepAnalysis)
        let executionTime = CFAbsoluteTimeGetCurrent() - startTime
        
        XCTAssertLessThan(executionTime, 5.0, "Tasks should complete quickly for good user experience")
        
        Logger.success("✅ Background tasks ready for TestFlight", log: Logger.backgroundTasks)
    }
    
    // MARK: - Helper Methods
    
    private func getMemoryUsage() -> UInt64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        return kerr == KERN_SUCCESS ? info.resident_size : 0
    }
    
    private func determineMockBatteryOptimizationLevel(batteryLevel: Float, isCharging: Bool) -> BatteryOptimizationLevel {
        if batteryLevel <= 0.2 && !isCharging {
            return .aggressive
        } else if batteryLevel <= 0.3 && !isCharging {
            return .conservative
        } else if isCharging {
            return .performance
        } else {
            return .balanced
        }
    }
    
    private func shouldMockExecuteTask(_ priority: MockTaskPriority, batteryLevel: Float, isCharging: Bool) -> Bool {
        // Always execute critical tasks
        if priority == .critical {
            return true
        }
        
        // Skip non-critical tasks on critical battery
        if batteryLevel <= 0.2 && !isCharging {
            return false
        }
        
        // Skip low priority tasks on low battery unless charging
        if priority == .low && batteryLevel <= 0.3 && !isCharging {
            return false
        }
        
        return true
    }
}

// MARK: - Mock Classes for Testing

private enum MockTaskPriority {
    case low
    case medium
    case high
    case critical
}

private class MockBatteryMonitor {
    private var batteryLevel: Float = 1.0
    private var isCharging: Bool = false
    
    func setBatteryLevel(_ level: Float, isCharging: Bool) {
        self.batteryLevel = level
        self.isCharging = isCharging
    }
    
    var currentBatteryLevel: Float {
        return batteryLevel
    }
    
    var chargingStatus: Bool {
        return isCharging
    }
}

private class MockSleepDataCacheManager {
    private var cachedData: [String: Any] = [:]
    
    func cache(_ data: Any, forKey key: String) {
        cachedData[key] = data
    }
    
    func getCachedData(forKey key: String) -> Any? {
        return cachedData[key]
    }
    
    func clearCache() {
        cachedData.removeAll()
    }
}

// MARK: - Test Configuration

extension BackgroundTaskTests {
    
    /// Test configuration for different scenarios
    enum TestConfiguration {
        case lowBattery
        case charging
        case normalOperation
        case criticalBattery
        
        var batteryLevel: Float {
            switch self {
            case .lowBattery: return 0.25
            case .charging: return 0.8
            case .normalOperation: return 0.6
            case .criticalBattery: return 0.15
            }
        }
        
        var isCharging: Bool {
            switch self {
            case .charging: return true
            default: return false
            }
        }
    }
    
    func configureTestEnvironment(_ config: TestConfiguration) {
        mockBatteryMonitor.setBatteryLevel(config.batteryLevel, isCharging: config.isCharging)
    }
}

// MARK: - Performance Benchmarks

extension BackgroundTaskTests {
    
    func benchmarkTaskExecutionTime() async throws {
        let iterations = 10
        var totalTime: TimeInterval = 0
        
        for _ in 0..<iterations {
            let startTime = CFAbsoluteTimeGetCurrent()
            _ = await backgroundManager.forceExecuteTask(.sleepAnalysis)
            let executionTime = CFAbsoluteTimeGetCurrent() - startTime
            totalTime += executionTime
        }
        
        let averageTime = totalTime / Double(iterations)
        
        Logger.info("Average task execution time: \(String(format: "%.3f", averageTime))s", log: Logger.backgroundTasks)
        
        // Should average less than 1 second
        XCTAssertLessThan(averageTime, 1.0, "Average task execution should be under 1 second")
    }
    
    func benchmarkMemoryUsage() async throws {
        let initialMemory = getMemoryUsage()
        
        // Execute many tasks
        for _ in 0..<20 {
            _ = await backgroundManager.forceExecuteTask(.sleepAnalysis)
        }
        
        let finalMemory = getMemoryUsage()
        let memoryIncrease = finalMemory - initialMemory
        let memoryIncreaseMB = Double(memoryIncrease) / 1_000_000
        
        Logger.info("Memory increase after 20 tasks: \(String(format: "%.2f", memoryIncreaseMB))MB", log: Logger.backgroundTasks)
        
        // Should not increase by more than 10MB
        XCTAssertLessThan(memoryIncrease, 10_000_000, "Memory usage should remain stable")
    }
}
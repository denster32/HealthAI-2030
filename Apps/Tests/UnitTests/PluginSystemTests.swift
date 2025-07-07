import XCTest
@testable import HealthAI2030

@MainActor
final class PluginSystemTests: XCTestCase {
    var pluginManager: HealthAIPluginManager!
    
    override func setUp() {
        super.setUp()
        pluginManager = HealthAIPluginManager()
    }
    
    override func tearDown() {
        pluginManager = nil
        super.tearDown()
    }
    
    // MARK: - Plugin Discovery Tests
    func testPluginDiscovery() async throws {
        let plugins = try await pluginManager.discoverPlugins()
        XCTAssertNotNil(plugins)
        // Note: This will return empty array in test environment
        XCTAssertTrue(plugins.isEmpty)
    }
    
    // MARK: - Plugin Loading Tests
    func testPluginLoading() async {
        // Test loading a non-existent plugin
        do {
            try await pluginManager.loadPlugin(at: "/nonexistent/path")
            XCTFail("Should throw error for non-existent plugin")
        } catch {
            XCTAssertTrue(error is PluginError)
        }
    }
    
    func testPluginLoadingWithInvalidPath() async {
        do {
            try await pluginManager.loadPlugin(at: "")
            XCTFail("Should throw error for empty path")
        } catch {
            XCTAssertTrue(error is PluginError)
        }
    }
    
    // MARK: - Plugin Execution Tests
    func testPluginExecutionWithNonExistentPlugin() async {
        do {
            _ = try await pluginManager.executePlugin("nonexistent", with: [:])
            XCTFail("Should throw error for non-existent plugin")
        } catch {
            XCTAssertEqual(error as? PluginError, .pluginNotFound)
        }
    }
    
    func testPluginExecutionWithEmptyData() async {
        // This test will fail since no plugins are loaded
        // But it tests the error handling
        do {
            _ = try await pluginManager.executePlugin("test", with: [:])
            XCTFail("Should throw error for non-existent plugin")
        } catch {
            XCTAssertEqual(error as? PluginError, .pluginNotFound)
        }
    }
    
    // MARK: - Plugin Management Tests
    func testPluginUnloading() async {
        // Test unloading a non-existent plugin
        do {
            try await pluginManager.unloadPlugin("nonexistent")
            XCTFail("Should throw error for non-existent plugin")
        } catch {
            XCTAssertEqual(error as? PluginError, .pluginNotFound)
        }
    }
    
    func testGetPluginStatus() {
        let status = pluginManager.getPluginStatus("nonexistent")
        XCTAssertNil(status)
    }
    
    func testGetPluginPerformance() {
        let performance = pluginManager.getPluginPerformance("nonexistent")
        XCTAssertNil(performance)
    }
    
    // MARK: - Plugin Health Check Tests
    func testPluginHealthCheck() async {
        let healthStatuses = await pluginManager.performHealthCheck()
        XCTAssertNotNil(healthStatuses)
        XCTAssertTrue(healthStatuses.isEmpty)
    }
    
    // MARK: - Plugin Metadata Tests
    func testPluginMetadataStructure() {
        let metadata = PluginMetadata(
            id: "test-plugin",
            name: "Test Plugin",
            version: "1.0.0",
            description: "A test plugin",
            author: "Test Author",
            permissions: [.healthData, .networkAccess],
            path: "/test/path"
        )
        
        XCTAssertEqual(metadata.id, "test-plugin")
        XCTAssertEqual(metadata.name, "Test Plugin")
        XCTAssertEqual(metadata.version, "1.0.0")
        XCTAssertEqual(metadata.description, "A test plugin")
        XCTAssertEqual(metadata.author, "Test Author")
        XCTAssertEqual(metadata.permissions.count, 2)
        XCTAssertEqual(metadata.path, "/test/path")
    }
    
    // MARK: - Plugin Performance Metrics Tests
    func testPluginPerformanceMetricsStructure() {
        let metrics = PluginPerformanceMetrics(
            averageExecutionTime: 1.5,
            totalExecutions: 10,
            lastExecutionTime: Date(),
            memoryUsage: 1024,
            errorCount: 0
        )
        
        XCTAssertEqual(metrics.averageExecutionTime, 1.5)
        XCTAssertEqual(metrics.totalExecutions, 10)
        XCTAssertNotNil(metrics.lastExecutionTime)
        XCTAssertEqual(metrics.memoryUsage, 1024)
        XCTAssertEqual(metrics.errorCount, 0)
    }
    
    // MARK: - Plugin Health Status Tests
    func testPluginHealthStatusStructure() {
        let performance = PluginPerformanceMetrics(
            averageExecutionTime: 1.0,
            totalExecutions: 5,
            lastExecutionTime: Date(),
            memoryUsage: 512,
            errorCount: 0
        )
        
        let healthStatus = PluginHealthStatus(
            pluginId: "test-plugin",
            status: .loaded,
            performance: performance,
            lastExecution: Date()
        )
        
        XCTAssertEqual(healthStatus.pluginId, "test-plugin")
        XCTAssertEqual(healthStatus.status, .loaded)
        XCTAssertNotNil(healthStatus.performance)
        XCTAssertNotNil(healthStatus.lastExecution)
    }
    
    // MARK: - Plugin Permission Tests
    func testPluginPermissions() {
        let permissions: [PluginPermission] = [.healthData, .networkAccess, .fileSystem]
        
        XCTAssertTrue(permissions.contains(.healthData))
        XCTAssertTrue(permissions.contains(.networkAccess))
        XCTAssertTrue(permissions.contains(.fileSystem))
        XCTAssertFalse(permissions.contains(.notifications))
        XCTAssertFalse(permissions.contains(.location))
    }
    
    func testPluginPermissionRawValues() {
        XCTAssertEqual(PluginPermission.healthData.rawValue, "health_data")
        XCTAssertEqual(PluginPermission.networkAccess.rawValue, "network_access")
        XCTAssertEqual(PluginPermission.fileSystem.rawValue, "file_system")
        XCTAssertEqual(PluginPermission.notifications.rawValue, "notifications")
        XCTAssertEqual(PluginPermission.location.rawValue, "location")
    }
    
    // MARK: - Plugin Status Tests
    func testPluginStatusCases() {
        let loadedStatus = PluginStatus.loaded
        let runningStatus = PluginStatus.running
        let stoppedStatus = PluginStatus.stopped
        let errorStatus = PluginStatus.error("Test error")
        
        XCTAssertNotEqual(loadedStatus, runningStatus)
        XCTAssertNotEqual(runningStatus, stoppedStatus)
        XCTAssertNotEqual(stoppedStatus, errorStatus)
    }
    
    // MARK: - Plugin Error Tests
    func testPluginErrorCases() {
        let errors: [PluginError] = [
            .securityValidationFailed,
            .pluginNotFound,
            .initializationFailed,
            .executionFailed,
            .cleanupFailed
        ]
        
        XCTAssertEqual(errors.count, 5)
    }
    
    // MARK: - Concurrent Access Tests
    func testConcurrentPluginOperations() async {
        // Test that the plugin manager can handle concurrent operations
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<10 {
                group.addTask {
                    let healthStatuses = await self.pluginManager.performHealthCheck()
                    XCTAssertNotNil(healthStatuses)
                }
            }
        }
    }
    
    // MARK: - Memory Management Tests
    func testPluginManagerMemoryManagement() {
        weak var weakManager: HealthAIPluginManager?
        
        autoreleasepool {
            let manager = HealthAIPluginManager()
            weakManager = manager
        }
        
        // The manager should be deallocated after the autoreleasepool
        XCTAssertNil(weakManager)
    }
    
    // MARK: - Integration Tests
    func testPluginSystemIntegration() async {
        // Test the complete plugin system workflow
        let healthStatuses = await pluginManager.performHealthCheck()
        XCTAssertTrue(healthStatuses.isEmpty)
        
        let plugins = try? await pluginManager.discoverPlugins()
        XCTAssertNotNil(plugins)
        XCTAssertTrue(plugins?.isEmpty ?? false)
    }
} 
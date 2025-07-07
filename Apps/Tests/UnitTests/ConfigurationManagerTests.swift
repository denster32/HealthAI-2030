import XCTest
@testable import HealthAI2030

@MainActor
final class ConfigurationManagerTests: XCTestCase {
    var configurationManager: AppConfigurationManager!
    
    override func setUp() {
        super.setUp()
        configurationManager = AppConfigurationManager()
    }
    
    override func tearDown() {
        configurationManager = nil
        super.tearDown()
    }
    
    // MARK: - Environment Management Tests
    func testInitialEnvironment() {
        XCTAssertEqual(configurationManager.getEnvironment(), .development)
    }
    
    func testAvailableEnvironments() {
        let environments = configurationManager.getAvailableEnvironments()
        XCTAssertEqual(environments.count, 4)
        XCTAssertTrue(environments.contains(.development))
        XCTAssertTrue(environments.contains(.staging))
        XCTAssertTrue(environments.contains(.production))
        XCTAssertTrue(environments.contains(.testing))
    }
    
    func testSwitchToStagingEnvironment() async throws {
        try await configurationManager.switchEnvironment(.staging)
        
        XCTAssertEqual(configurationManager.getEnvironment(), .staging)
        XCTAssertEqual(configurationManager.getConfiguration().environment, .staging)
        XCTAssertFalse(configurationManager.isLoading)
        XCTAssertNil(configurationManager.error)
    }
    
    func testSwitchToProductionEnvironment() async throws {
        try await configurationManager.switchEnvironment(.production)
        
        XCTAssertEqual(configurationManager.getEnvironment(), .production)
        XCTAssertEqual(configurationManager.getConfiguration().environment, .production)
        XCTAssertFalse(configurationManager.isLoading)
        XCTAssertNil(configurationManager.error)
    }
    
    func testSwitchToTestingEnvironment() async throws {
        try await configurationManager.switchEnvironment(.testing)
        
        XCTAssertEqual(configurationManager.getEnvironment(), .testing)
        XCTAssertEqual(configurationManager.getConfiguration().environment, .testing)
        XCTAssertFalse(configurationManager.isLoading)
        XCTAssertNil(configurationManager.error)
    }
    
    func testSwitchBackToDevelopmentEnvironment() async throws {
        // First switch to staging
        try await configurationManager.switchEnvironment(.staging)
        XCTAssertEqual(configurationManager.getEnvironment(), .staging)
        
        // Then switch back to development
        try await configurationManager.switchEnvironment(.development)
        XCTAssertEqual(configurationManager.getEnvironment(), .development)
        XCTAssertEqual(configurationManager.getConfiguration().environment, .development)
    }
    
    // MARK: - Configuration Access Tests
    func testGetConfiguration() {
        let configuration = configurationManager.getConfiguration()
        XCTAssertNotNil(configuration)
        XCTAssertEqual(configuration.environment, .development)
        XCTAssertFalse(configuration.version.isEmpty)
    }
    
    func testGetConfigurationValue() {
        let baseURL: String? = configurationManager.getConfigurationValue(for: .apiBaseURL)
        XCTAssertNotNil(baseURL)
        XCTAssertFalse(baseURL?.isEmpty ?? true)
        
        let timeout: TimeInterval? = configurationManager.getConfigurationValue(for: .apiTimeout)
        XCTAssertNotNil(timeout)
        XCTAssertGreaterThan(timeout ?? 0, 0)
    }
    
    func testSetConfigurationValue() async throws {
        let newTimeout: TimeInterval = 60.0
        try await configurationManager.setConfigurationValue(newTimeout, for: .apiTimeout)
        
        let updatedTimeout: TimeInterval? = configurationManager.getConfigurationValue(for: .apiTimeout)
        XCTAssertEqual(updatedTimeout, newTimeout)
    }
    
    // MARK: - Feature Flag Tests
    func testFeatureFlagsLoaded() {
        let featureFlags = configurationManager.getFeatureFlags()
        XCTAssertFalse(featureFlags.isEmpty)
        
        // Check for expected feature flags
        XCTAssertNotNil(featureFlags["advanced_analytics"])
        XCTAssertNotNil(featureFlags["beta_features"])
        XCTAssertNotNil(featureFlags["experimental_ml"])
    }
    
    func testFeatureFlagEnabledInDevelopment() {
        // In development, experimental_ml should be enabled
        XCTAssertTrue(configurationManager.isFeatureEnabled("experimental_ml"))
        
        // Beta features should be enabled in development
        XCTAssertTrue(configurationManager.isFeatureEnabled("beta_features"))
    }
    
    func testFeatureFlagDisabledInDevelopment() {
        // Advanced analytics should be disabled in development
        XCTAssertFalse(configurationManager.isFeatureEnabled("advanced_analytics"))
    }
    
    func testUpdateFeatureFlag() async throws {
        // Initially, advanced_analytics should be disabled in development
        XCTAssertFalse(configurationManager.isFeatureEnabled("advanced_analytics"))
        
        // Enable the feature flag
        try await configurationManager.updateFeatureFlag("advanced_analytics", isEnabled: true)
        
        // Verify it's now enabled
        XCTAssertTrue(configurationManager.isFeatureEnabled("advanced_analytics"))
        
        // Disable it again
        try await configurationManager.updateFeatureFlag("advanced_analytics", isEnabled: false)
        
        // Verify it's disabled
        XCTAssertFalse(configurationManager.isFeatureEnabled("advanced_analytics"))
    }
    
    func testCreateNewFeatureFlag() async throws {
        let newFeatureName = "new_feature"
        
        // Initially, the feature should not exist
        XCTAssertFalse(configurationManager.isFeatureEnabled(newFeatureName))
        XCTAssertNil(configurationManager.getFeatureFlag(newFeatureName))
        
        // Create the feature flag
        try await configurationManager.updateFeatureFlag(newFeatureName, isEnabled: true)
        
        // Verify it's now enabled
        XCTAssertTrue(configurationManager.isFeatureEnabled(newFeatureName))
        
        let featureFlag = configurationManager.getFeatureFlag(newFeatureName)
        XCTAssertNotNil(featureFlag)
        XCTAssertEqual(featureFlag?.name, newFeatureName)
        XCTAssertTrue(featureFlag?.isEnabled ?? false)
    }
    
    // MARK: - Configuration Validation Tests
    func testValidateConfiguration() async throws {
        let validationResult = try await configurationManager.validateConfiguration()
        
        XCTAssertTrue(validationResult.isValid)
        XCTAssertTrue(validationResult.errors.isEmpty)
        // May have warnings, which is acceptable
    }
    
    func testGetConfigurationSchema() {
        let schema = configurationManager.getConfigurationSchema()
        
        XCTAssertFalse(schema.requiredFields.isEmpty)
        XCTAssertFalse(schema.fieldTypes.isEmpty)
        
        // Check for expected required fields
        XCTAssertTrue(schema.requiredFields.contains("version"))
        XCTAssertTrue(schema.requiredFields.contains("environment"))
        XCTAssertTrue(schema.requiredFields.contains("apiConfiguration"))
        XCTAssertTrue(schema.requiredFields.contains("databaseConfiguration"))
        
        // Check for expected field types
        XCTAssertEqual(schema.fieldTypes["version"], "String")
        XCTAssertEqual(schema.fieldTypes["environment"], "Environment")
        XCTAssertEqual(schema.fieldTypes["apiConfiguration"], "APIConfiguration")
    }
    
    // MARK: - Configuration Versioning Tests
    func testGetConfigurationVersion() {
        let version = configurationManager.getConfigurationVersion()
        XCTAssertFalse(version.isEmpty)
        XCTAssertTrue(version.contains("1.0.0"))
    }
    
    func testRollbackConfiguration() async {
        // This test would require a previous configuration to exist
        // For now, we'll test the error case
        do {
            try await configurationManager.rollbackConfiguration()
            XCTFail("Should throw error when no previous configuration exists")
        } catch {
            XCTAssertTrue(error is ConfigurationError)
        }
    }
    
    // MARK: - Dynamic Configuration Updates Tests
    func testRefreshConfiguration() async throws {
        let originalVersion = configurationManager.getConfigurationVersion()
        
        try await configurationManager.refreshConfiguration()
        
        let newVersion = configurationManager.getConfigurationVersion()
        XCTAssertEqual(newVersion, originalVersion) // Should be the same in test environment
        
        XCTAssertFalse(configurationManager.isLoading)
        XCTAssertNil(configurationManager.error)
    }
    
    // MARK: - Configuration Export/Import Tests
    func testExportConfiguration() async throws {
        let exportData = try await configurationManager.exportConfiguration()
        
        XCTAssertFalse(exportData.isEmpty)
        
        // Try to decode the exported data
        let decodedExport = try JSONDecoder().decode(ConfigurationExport.self, from: exportData)
        
        XCTAssertEqual(decodedExport.environment, configurationManager.getEnvironment())
        XCTAssertEqual(decodedExport.configuration.version, configurationManager.getConfigurationVersion())
        XCTAssertFalse(decodedExport.featureFlags.isEmpty)
        XCTAssertNotNil(decodedExport.exportDate)
    }
    
    func testImportConfiguration() async throws {
        // First export current configuration
        let exportData = try await configurationManager.exportConfiguration()
        
        // Switch to a different environment
        try await configurationManager.switchEnvironment(.staging)
        XCTAssertEqual(configurationManager.getEnvironment(), .staging)
        
        // Import the exported configuration (which was from development)
        try await configurationManager.importConfiguration(exportData)
        
        // Should be back to development environment
        XCTAssertEqual(configurationManager.getEnvironment(), .development)
        XCTAssertEqual(configurationManager.getConfiguration().environment, .development)
    }
    
    // MARK: - Environment-Specific Configuration Tests
    func testDevelopmentConfiguration() async throws {
        try await configurationManager.switchEnvironment(.development)
        let config = configurationManager.getConfiguration()
        
        XCTAssertEqual(config.environment, .development)
        XCTAssertTrue(config.version.contains("dev"))
        XCTAssertTrue(config.apiConfiguration.baseURL.contains("dev"))
        XCTAssertFalse(config.securityConfiguration.encryptionEnabled)
        XCTAssertFalse(config.analyticsConfiguration.enabled)
    }
    
    func testStagingConfiguration() async throws {
        try await configurationManager.switchEnvironment(.staging)
        let config = configurationManager.getConfiguration()
        
        XCTAssertEqual(config.environment, .staging)
        XCTAssertTrue(config.version.contains("staging"))
        XCTAssertTrue(config.apiConfiguration.baseURL.contains("staging"))
        XCTAssertTrue(config.securityConfiguration.encryptionEnabled)
        XCTAssertTrue(config.analyticsConfiguration.enabled)
    }
    
    func testProductionConfiguration() async throws {
        try await configurationManager.switchEnvironment(.production)
        let config = configurationManager.getConfiguration()
        
        XCTAssertEqual(config.environment, .production)
        XCTAssertTrue(config.version.contains("1.0.0"))
        XCTAssertTrue(config.apiConfiguration.baseURL.contains("api.healthai2030.com"))
        XCTAssertTrue(config.securityConfiguration.encryptionEnabled)
        XCTAssertTrue(config.analyticsConfiguration.enabled)
    }
    
    func testTestingConfiguration() async throws {
        try await configurationManager.switchEnvironment(.testing)
        let config = configurationManager.getConfiguration()
        
        XCTAssertEqual(config.environment, .testing)
        XCTAssertTrue(config.version.contains("test"))
        XCTAssertTrue(config.apiConfiguration.baseURL.contains("test"))
        XCTAssertFalse(config.securityConfiguration.encryptionEnabled)
        XCTAssertFalse(config.analyticsConfiguration.enabled)
    }
    
    // MARK: - Error Handling Tests
    func testConfigurationErrorHandling() async {
        // Test that errors are properly captured
        do {
            try await configurationManager.switchEnvironment(.development)
            // This should succeed, but we can test error state
            XCTAssertNil(configurationManager.error)
        } catch {
            XCTAssertNotNil(configurationManager.error)
        }
    }
    
    // MARK: - Concurrent Operations Tests
    func testConcurrentEnvironmentSwitches() async {
        await withTaskGroup(of: Void.self) { group in
            // Add multiple concurrent environment switches
            group.addTask {
                try? await self.configurationManager.switchEnvironment(.staging)
            }
            
            group.addTask {
                try? await self.configurationManager.switchEnvironment(.production)
            }
            
            group.addTask {
                try? await self.configurationManager.switchEnvironment(.testing)
            }
        }
        
        // Verify no crashes occurred
        XCTAssertNotNil(configurationManager)
    }
    
    // MARK: - Performance Tests
    func testConfigurationSwitchPerformance() async throws {
        let startTime = Date()
        
        try await configurationManager.switchEnvironment(.staging)
        
        let switchTime = Date().timeIntervalSince(startTime)
        XCTAssertLessThan(switchTime, 2.0) // Should complete within 2 seconds
    }
    
    func testFeatureFlagUpdatePerformance() async throws {
        let startTime = Date()
        
        try await configurationManager.updateFeatureFlag("test_performance", isEnabled: true)
        
        let updateTime = Date().timeIntervalSince(startTime)
        XCTAssertLessThan(updateTime, 1.0) // Should complete within 1 second
    }
    
    // MARK: - Memory Management Tests
    func testConfigurationManagerMemoryManagement() {
        weak var weakManager: AppConfigurationManager?
        
        autoreleasepool {
            let manager = AppConfigurationManager()
            weakManager = manager
        }
        
        // The manager should be deallocated after the autoreleasepool
        XCTAssertNil(weakManager)
    }
    
    // MARK: - Integration Tests
    func testCompleteConfigurationWorkflow() async throws {
        // 1. Start in development
        XCTAssertEqual(configurationManager.getEnvironment(), .development)
        
        // 2. Switch to staging
        try await configurationManager.switchEnvironment(.staging)
        XCTAssertEqual(configurationManager.getEnvironment(), .staging)
        
        // 3. Update a feature flag
        try await configurationManager.updateFeatureFlag("test_workflow", isEnabled: true)
        XCTAssertTrue(configurationManager.isFeatureEnabled("test_workflow"))
        
        // 4. Validate configuration
        let validationResult = try await configurationManager.validateConfiguration()
        XCTAssertTrue(validationResult.isValid)
        
        // 5. Export configuration
        let exportData = try await configurationManager.exportConfiguration()
        XCTAssertFalse(exportData.isEmpty)
        
        // 6. Switch to production
        try await configurationManager.switchEnvironment(.production)
        XCTAssertEqual(configurationManager.getEnvironment(), .production)
        
        // 7. Import previous configuration
        try await configurationManager.importConfiguration(exportData)
        XCTAssertEqual(configurationManager.getEnvironment(), .staging)
        
        // 8. Refresh configuration
        try await configurationManager.refreshConfiguration()
        XCTAssertFalse(configurationManager.isLoading)
        XCTAssertNil(configurationManager.error)
    }
} 
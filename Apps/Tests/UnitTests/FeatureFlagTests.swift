import XCTest
@testable import HealthAI2030

@MainActor
final class FeatureFlagTests: XCTestCase {
    var featureFlagManager: FeatureFlagManager!
    
    override func setUp() {
        super.setUp()
        featureFlagManager = FeatureFlagManager()
    }
    
    override func tearDown() {
        featureFlagManager = nil
        super.tearDown()
    }
    
    // MARK: - Feature Flag Management Tests
    func testInitialFeatureFlags() {
        // Wait for async loading to complete
        let expectation = XCTestExpectation(description: "Feature flags loaded")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let flags = self.featureFlagManager.featureFlags
            XCTAssertFalse(flags.isEmpty)
            XCTAssertNotNil(flags["advanced_analytics"])
            XCTAssertNotNil(flags["new_ui"])
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testIsFeatureEnabled() {
        // Test with existing feature
        XCTAssertTrue(featureFlagManager.isFeatureEnabled("advanced_analytics"))
        XCTAssertFalse(featureFlagManager.isFeatureEnabled("new_ui"))
        
        // Test with non-existent feature
        XCTAssertFalse(featureFlagManager.isFeatureEnabled("nonexistent_feature"))
    }
    
    func testIsFeatureEnabledWithUserId() {
        let userId = "test_user_123"
        
        // Test with user ID (should use rollout percentage)
        let isEnabled = featureFlagManager.isFeatureEnabled("advanced_analytics", for: userId)
        XCTAssertTrue(isEnabled) // Should be enabled based on rollout percentage
    }
    
    func testGetFeatureFlag() {
        let flag = featureFlagManager.getFeatureFlag("advanced_analytics")
        XCTAssertNotNil(flag)
        XCTAssertEqual(flag?.name, "advanced_analytics")
        XCTAssertTrue(flag?.isEnabled ?? false)
        XCTAssertEqual(flag?.rolloutPercentage, 50)
        XCTAssertTrue(flag?.targetUsers.contains("beta_users") ?? false)
    }
    
    func testUpdateFeatureFlag() async throws {
        let featureName = "test_feature"
        
        // Initially, the feature should not exist
        XCTAssertFalse(featureFlagManager.isFeatureEnabled(featureName))
        
        // Create the feature flag
        try await featureFlagManager.updateFeatureFlag(featureName, isEnabled: true, rolloutPercentage: 75)
        
        // Verify it's now enabled
        XCTAssertTrue(featureFlagManager.isFeatureEnabled(featureName))
        
        let flag = featureFlagManager.getFeatureFlag(featureName)
        XCTAssertNotNil(flag)
        XCTAssertTrue(flag?.isEnabled ?? false)
        XCTAssertEqual(flag?.rolloutPercentage, 75)
        
        // Update the feature flag
        try await featureFlagManager.updateFeatureFlag(featureName, isEnabled: false, rolloutPercentage: 0)
        
        // Verify it's now disabled
        XCTAssertFalse(featureFlagManager.isFeatureEnabled(featureName))
        
        let updatedFlag = featureFlagManager.getFeatureFlag(featureName)
        XCTAssertFalse(updatedFlag?.isEnabled ?? true)
        XCTAssertEqual(updatedFlag?.rolloutPercentage, 0)
    }
    
    func testDeleteFeatureFlag() async throws {
        let featureName = "test_delete_feature"
        
        // Create a feature flag
        try await featureFlagManager.updateFeatureFlag(featureName, isEnabled: true)
        XCTAssertTrue(featureFlagManager.isFeatureEnabled(featureName))
        
        // Delete the feature flag
        try await featureFlagManager.deleteFeatureFlag(featureName)
        
        // Verify it's deleted
        XCTAssertFalse(featureFlagManager.isFeatureEnabled(featureName))
        XCTAssertNil(featureFlagManager.getFeatureFlag(featureName))
    }
    
    // MARK: - A/B Testing Tests
    func testCreateExperiment() async throws {
        let experiment = Experiment(
            id: "test_experiment",
            name: "Test Experiment",
            description: "A test experiment",
            variants: [
                ExperimentVariant(id: "control", name: "Control", weight: 50),
                ExperimentVariant(id: "treatment", name: "Treatment", weight: 50)
            ],
            isActive: true,
            startDate: Date(),
            endDate: Date().addingTimeInterval(86400 * 7), // 7 days
            targetAudience: ["test_users"],
            trafficAllocation: 100
        )
        
        try await featureFlagManager.createExperiment(experiment)
        
        let activeExperiments = featureFlagManager.getActiveExperiments()
        XCTAssertTrue(activeExperiments.contains { $0.id == "test_experiment" })
    }
    
    func testGetExperimentVariant() async throws {
        let experiment = Experiment(
            id: "variant_test",
            name: "Variant Test",
            description: "Testing variant selection",
            variants: [
                ExperimentVariant(id: "control", name: "Control", weight: 50),
                ExperimentVariant(id: "treatment", name: "Treatment", weight: 50)
            ]
        )
        
        try await featureFlagManager.createExperiment(experiment)
        
        let userId = "test_user_456"
        let variant = featureFlagManager.getExperimentVariant("variant_test", for: userId)
        
        XCTAssertNotNil(variant)
        XCTAssertTrue(variant?.id == "control" || variant?.id == "treatment")
    }
    
    func testTrackExperimentEvent() async {
        let experimentId = "event_test"
        let userId = "test_user_789"
        let event = "button_click"
        let metadata = ["button_id": "submit", "page": "checkout"]
        
        // This should not throw
        await featureFlagManager.trackExperimentEvent(
            experimentId: experimentId,
            event: event,
            userId: userId,
            metadata: metadata
        )
    }
    
    func testGetExperimentResults() async throws {
        let experimentId = "results_test"
        
        let results = try await featureFlagManager.getExperimentResults(experimentId)
        
        XCTAssertEqual(results.experimentId, experimentId)
        XCTAssertNotNil(results.variantResults)
        XCTAssertNotNil(results.statisticalSignificance)
    }
    
    // MARK: - Gradual Rollouts Tests
    func testStartGradualRollout() async throws {
        let featureName = "rollout_test"
        
        // First create a feature flag
        try await featureFlagManager.updateFeatureFlag(featureName, isEnabled: true, rolloutPercentage: 10)
        
        // Start gradual rollout
        try await featureFlagManager.startGradualRollout(
            featureName: featureName,
            targetPercentage: 100,
            duration: 3600 // 1 hour
        )
        
        // Get active rollouts
        let activeRollouts = try await featureFlagManager.getActiveRollouts()
        XCTAssertFalse(activeRollouts.isEmpty)
        
        // Find our rollout
        let rollout = activeRollouts.first { $0.featureName == featureName }
        XCTAssertNotNil(rollout)
        XCTAssertEqual(rollout?.startPercentage, 10)
        XCTAssertEqual(rollout?.targetPercentage, 100)
        XCTAssertTrue(rollout?.isActive ?? false)
    }
    
    func testPauseAndResumeRollout() async throws {
        let featureName = "pause_resume_test"
        
        // Create feature flag and start rollout
        try await featureFlagManager.updateFeatureFlag(featureName, isEnabled: true, rolloutPercentage: 20)
        try await featureFlagManager.startGradualRollout(
            featureName: featureName,
            targetPercentage: 80,
            duration: 1800 // 30 minutes
        )
        
        // Pause rollout
        try await featureFlagManager.pauseRollout(featureName)
        
        // Resume rollout
        try await featureFlagManager.resumeRollout(featureName)
        
        // Verify no errors occurred
        XCTAssertNil(featureFlagManager.error)
    }
    
    // MARK: - User Targeting Tests
    func testAddTargetUser() async throws {
        let featureName = "targeting_test"
        let userId = "target_user_123"
        
        // Create feature flag
        try await featureFlagManager.updateFeatureFlag(featureName, isEnabled: true)
        
        // Initially, user should not be targeted
        XCTAssertFalse(featureFlagManager.isUserTargeted(userId, for: featureName))
        
        // Add user to targeting
        try await featureFlagManager.addTargetUser(userId, to: featureName)
        
        // Verify user is now targeted
        XCTAssertTrue(featureFlagManager.isUserTargeted(userId, for: featureName))
        
        // Feature should be enabled for targeted user
        XCTAssertTrue(featureFlagManager.isFeatureEnabled(featureName, for: userId))
    }
    
    func testRemoveTargetUser() async throws {
        let featureName = "remove_targeting_test"
        let userId = "remove_user_456"
        
        // Create feature flag and add user
        try await featureFlagManager.updateFeatureFlag(featureName, isEnabled: true)
        try await featureFlagManager.addTargetUser(userId, to: featureName)
        
        // Verify user is targeted
        XCTAssertTrue(featureFlagManager.isUserTargeted(userId, for: featureName))
        
        // Remove user from targeting
        try await featureFlagManager.removeTargetUser(userId, from: featureName)
        
        // Verify user is no longer targeted
        XCTAssertFalse(featureFlagManager.isUserTargeted(userId, for: featureName))
    }
    
    func testAddTargetUserToNonExistentFlag() async {
        do {
            try await featureFlagManager.addTargetUser("test_user", to: "nonexistent_flag")
            XCTFail("Should throw error for non-existent flag")
        } catch {
            XCTAssertTrue(error is FeatureFlagError)
        }
    }
    
    // MARK: - Analytics and Monitoring Tests
    func testGetFeatureFlagAnalytics() async throws {
        let featureName = "analytics_test"
        
        let analytics = try await featureFlagManager.getFeatureFlagAnalytics(featureName)
        
        XCTAssertEqual(analytics.featureName, featureName)
        XCTAssertGreaterThanOrEqual(analytics.totalUsers, 0)
        XCTAssertGreaterThanOrEqual(analytics.enabledUsers, 0)
        XCTAssertGreaterThanOrEqual(analytics.conversionRate, 0.0)
        XCTAssertLessThanOrEqual(analytics.conversionRate, 1.0)
        XCTAssertGreaterThanOrEqual(analytics.averageSessionDuration, 0)
        XCTAssertGreaterThanOrEqual(analytics.errorRate, 0.0)
        XCTAssertLessThanOrEqual(analytics.errorRate, 1.0)
    }
    
    func testGetFeatureFlagUsage() async throws {
        let featureName = "usage_test"
        let timeRange = TimeRange.lastDay
        
        let usage = try await featureFlagManager.getFeatureFlagUsage(featureName, timeRange: timeRange)
        
        XCTAssertNotNil(usage)
        // Usage array may be empty in test environment
    }
    
    func testGetExperimentAnalytics() async throws {
        let experimentId = "experiment_analytics_test"
        
        let analytics = try await featureFlagManager.getExperimentAnalytics(experimentId)
        
        XCTAssertEqual(analytics.experimentId, experimentId)
        XCTAssertGreaterThanOrEqual(analytics.totalUsers, 0)
        XCTAssertGreaterThanOrEqual(analytics.activeUsers, 0)
        XCTAssertGreaterThanOrEqual(analytics.conversionRate, 0.0)
        XCTAssertLessThanOrEqual(analytics.conversionRate, 1.0)
        XCTAssertGreaterThanOrEqual(analytics.averageSessionDuration, 0)
    }
    
    // MARK: - Emergency Controls Tests
    func testEmergencyDisable() async throws {
        let featureName = "emergency_disable_test"
        
        // Create and enable feature flag
        try await featureFlagManager.updateFeatureFlag(featureName, isEnabled: true, rolloutPercentage: 100)
        XCTAssertTrue(featureFlagManager.isFeatureEnabled(featureName))
        
        // Emergency disable
        try await featureFlagManager.emergencyDisable(featureName)
        
        // Verify feature is disabled
        XCTAssertFalse(featureFlagManager.isFeatureEnabled(featureName))
        
        let flag = featureFlagManager.getFeatureFlag(featureName)
        XCTAssertFalse(flag?.isEnabled ?? true)
        XCTAssertEqual(flag?.rolloutPercentage, 0)
    }
    
    func testEmergencyEnable() async throws {
        let featureName = "emergency_enable_test"
        
        // Create and disable feature flag
        try await featureFlagManager.updateFeatureFlag(featureName, isEnabled: false, rolloutPercentage: 0)
        XCTAssertFalse(featureFlagManager.isFeatureEnabled(featureName))
        
        // Emergency enable
        try await featureFlagManager.emergencyEnable(featureName)
        
        // Verify feature is enabled
        XCTAssertTrue(featureFlagManager.isFeatureEnabled(featureName))
        
        let flag = featureFlagManager.getFeatureFlag(featureName)
        XCTAssertTrue(flag?.isEnabled ?? false)
        XCTAssertEqual(flag?.rolloutPercentage, 100)
    }
    
    // MARK: - Remote Configuration Tests
    func testRefreshFromRemote() async throws {
        // This should not throw
        try await featureFlagManager.refreshFromRemote()
        
        // Verify no errors occurred
        XCTAssertNil(featureFlagManager.error)
    }
    
    // MARK: - Error Handling Tests
    func testFeatureFlagErrorHandling() async {
        // Test error handling for non-existent features
        do {
            try await featureFlagManager.startGradualRollout(
                featureName: "nonexistent",
                targetPercentage: 100,
                duration: 3600
            )
            XCTFail("Should throw error for non-existent feature")
        } catch {
            XCTAssertTrue(error is FeatureFlagError)
        }
    }
    
    // MARK: - Concurrent Operations Tests
    func testConcurrentFeatureFlagOperations() async {
        await withTaskGroup(of: Void.self) { group in
            // Add multiple concurrent operations
            group.addTask {
                try? await self.featureFlagManager.updateFeatureFlag("concurrent_test_1", isEnabled: true)
            }
            
            group.addTask {
                try? await self.featureFlagManager.updateFeatureFlag("concurrent_test_2", isEnabled: false)
            }
            
            group.addTask {
                try? await self.featureFlagManager.emergencyDisable("concurrent_test_3")
            }
        }
        
        // Verify no crashes occurred
        XCTAssertNotNil(featureFlagManager)
    }
    
    // MARK: - Performance Tests
    func testFeatureFlagPerformance() async throws {
        let startTime = Date()
        
        try await featureFlagManager.updateFeatureFlag("performance_test", isEnabled: true)
        
        let updateTime = Date().timeIntervalSince(startTime)
        XCTAssertLessThan(updateTime, 1.0) // Should complete within 1 second
    }
    
    func testExperimentVariantSelectionPerformance() async throws {
        let experiment = Experiment(
            id: "performance_experiment",
            name: "Performance Test",
            description: "Testing performance",
            variants: [
                ExperimentVariant(id: "control", name: "Control", weight: 50),
                ExperimentVariant(id: "treatment", name: "Treatment", weight: 50)
            ]
        )
        
        try await featureFlagManager.createExperiment(experiment)
        
        let startTime = Date()
        
        for i in 0..<100 {
            let userId = "user_\(i)"
            _ = featureFlagManager.getExperimentVariant("performance_experiment", for: userId)
        }
        
        let selectionTime = Date().timeIntervalSince(startTime)
        XCTAssertLessThan(selectionTime, 1.0) // Should complete within 1 second
    }
    
    // MARK: - Memory Management Tests
    func testFeatureFlagManagerMemoryManagement() {
        weak var weakManager: FeatureFlagManager?
        
        autoreleasepool {
            let manager = FeatureFlagManager()
            weakManager = manager
        }
        
        // The manager should be deallocated after the autoreleasepool
        XCTAssertNil(weakManager)
    }
    
    // MARK: - Integration Tests
    func testCompleteFeatureFlagWorkflow() async throws {
        let featureName = "workflow_test"
        let userId = "workflow_user_123"
        
        // 1. Create feature flag
        try await featureFlagManager.updateFeatureFlag(featureName, isEnabled: true, rolloutPercentage: 25)
        XCTAssertTrue(featureFlagManager.isFeatureEnabled(featureName))
        
        // 2. Add user targeting
        try await featureFlagManager.addTargetUser(userId, to: featureName)
        XCTAssertTrue(featureFlagManager.isUserTargeted(userId, for: featureName))
        
        // 3. Start gradual rollout
        try await featureFlagManager.startGradualRollout(
            featureName: featureName,
            targetPercentage: 100,
            duration: 7200 // 2 hours
        )
        
        // 4. Create experiment
        let experiment = Experiment(
            id: "workflow_experiment",
            name: "Workflow Experiment",
            description: "Testing complete workflow",
            variants: [
                ExperimentVariant(id: "control", name: "Control", weight: 50),
                ExperimentVariant(id: "treatment", name: "Treatment", weight: 50)
            ]
        )
        try await featureFlagManager.createExperiment(experiment)
        
        // 5. Get experiment variant
        let variant = featureFlagManager.getExperimentVariant("workflow_experiment", for: userId)
        XCTAssertNotNil(variant)
        
        // 6. Track experiment event
        await featureFlagManager.trackExperimentEvent(
            experimentId: "workflow_experiment",
            event: "test_event",
            userId: userId
        )
        
        // 7. Get analytics
        let analytics = try await featureFlagManager.getFeatureFlagAnalytics(featureName)
        XCTAssertNotNil(analytics)
        
        // 8. Emergency disable
        try await featureFlagManager.emergencyDisable(featureName)
        XCTAssertFalse(featureFlagManager.isFeatureEnabled(featureName))
        
        // 9. Emergency enable
        try await featureFlagManager.emergencyEnable(featureName)
        XCTAssertTrue(featureFlagManager.isFeatureEnabled(featureName))
        
        // 10. Remove user targeting
        try await featureFlagManager.removeTargetUser(userId, from: featureName)
        XCTAssertFalse(featureFlagManager.isUserTargeted(userId, for: featureName))
        
        // 11. Delete feature flag
        try await featureFlagManager.deleteFeatureFlag(featureName)
        XCTAssertFalse(featureFlagManager.isFeatureEnabled(featureName))
    }
} 
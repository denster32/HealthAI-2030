import XCTest
@testable import HealthAI2030

@MainActor
final class PluginMarketplaceTests: XCTestCase {
    var pluginManager: HealthAIPluginManager!
    var marketplace: PluginMarketplace!
    
    override func setUp() {
        super.setUp()
        pluginManager = HealthAIPluginManager()
        marketplace = PluginMarketplace(pluginManager: pluginManager)
    }
    
    override func tearDown() {
        marketplace = nil
        pluginManager = nil
        super.tearDown()
    }
    
    // MARK: - Plugin Discovery Tests
    func testPluginDiscovery() async {
        await marketplace.discoverPlugins()
        
        XCTAssertFalse(marketplace.isLoading)
        XCTAssertNil(marketplace.error)
        XCTAssertFalse(marketplace.availablePlugins.isEmpty)
        
        // Verify plugin structure
        let plugin = marketplace.availablePlugins.first!
        XCTAssertFalse(plugin.id.isEmpty)
        XCTAssertFalse(plugin.name.isEmpty)
        XCTAssertFalse(plugin.version.isEmpty)
        XCTAssertFalse(plugin.description.isEmpty)
        XCTAssertFalse(plugin.author.isEmpty)
        XCTAssertFalse(plugin.category.isEmpty)
        XCTAssertFalse(plugin.downloadUrl.isEmpty)
        XCTAssertGreaterThanOrEqual(plugin.downloadCount, 0)
        XCTAssertGreaterThanOrEqual(plugin.averageRating, 0.0)
        XCTAssertLessThanOrEqual(plugin.averageRating, 5.0)
        XCTAssertGreaterThanOrEqual(plugin.reviewCount, 0)
        XCTAssertGreaterThan(plugin.size, 0)
        XCTAssertFalse(plugin.compatibility.isEmpty)
        XCTAssertFalse(plugin.tags.isEmpty)
    }
    
    func testPluginSearch() async {
        await marketplace.searchPlugins(query: "sleep")
        
        XCTAssertFalse(marketplace.isLoading)
        XCTAssertNil(marketplace.error)
        
        // Should find sleep-related plugins
        let sleepPlugins = marketplace.searchResults.filter { plugin in
            plugin.name.localizedCaseInsensitiveContains("sleep") ||
            plugin.description.localizedCaseInsensitiveContains("sleep") ||
            plugin.tags.contains { $0.localizedCaseInsensitiveContains("sleep") }
        }
        
        XCTAssertFalse(sleepPlugins.isEmpty)
    }
    
    func testPluginSearchByCategory() async {
        let category = marketplace.categories.first { $0.id == "sleep-analysis" }!
        await marketplace.getPluginsByCategory(category)
        
        XCTAssertFalse(marketplace.isLoading)
        XCTAssertNil(marketplace.error)
        
        // All results should be in the sleep-analysis category
        for plugin in marketplace.searchResults {
            XCTAssertEqual(plugin.category, "sleep-analysis")
        }
    }
    
    func testEmptySearchResults() async {
        await marketplace.searchPlugins(query: "nonexistentplugin")
        
        XCTAssertFalse(marketplace.isLoading)
        XCTAssertNil(marketplace.error)
        XCTAssertTrue(marketplace.searchResults.isEmpty)
    }
    
    // MARK: - Plugin Installation Tests
    func testPluginInstallation() async throws {
        // First discover plugins
        await marketplace.discoverPlugins()
        let plugin = marketplace.availablePlugins.first!
        
        // Install the plugin
        try await marketplace.installPlugin(plugin)
        
        XCTAssertFalse(marketplace.isLoading)
        XCTAssertNil(marketplace.error)
        
        // Verify plugin is installed
        let installedPlugin = marketplace.installedPlugins[plugin.id]
        XCTAssertNotNil(installedPlugin)
        XCTAssertEqual(installedPlugin?.id, plugin.id)
        XCTAssertEqual(installedPlugin?.name, plugin.name)
        XCTAssertEqual(installedPlugin?.version, plugin.version)
        XCTAssertFalse(installedPlugin?.installationPath.isEmpty ?? true)
        XCTAssertNotNil(installedPlugin?.installDate)
    }
    
    func testPluginUninstallation() async throws {
        // First install a plugin
        await marketplace.discoverPlugins()
        let plugin = marketplace.availablePlugins.first!
        try await marketplace.installPlugin(plugin)
        
        // Verify it's installed
        XCTAssertNotNil(marketplace.installedPlugins[plugin.id])
        
        // Uninstall the plugin
        try await marketplace.uninstallPlugin(plugin.id)
        
        XCTAssertFalse(marketplace.isLoading)
        XCTAssertNil(marketplace.error)
        
        // Verify plugin is uninstalled
        XCTAssertNil(marketplace.installedPlugins[plugin.id])
    }
    
    func testUninstallNonExistentPlugin() async {
        do {
            try await marketplace.uninstallPlugin("nonexistent")
            XCTFail("Should throw error for non-existent plugin")
        } catch {
            XCTAssertTrue(error is MarketplaceError)
        }
    }
    
    // MARK: - Plugin Update Tests
    func testCheckForUpdates() async {
        // Install a plugin first
        await marketplace.discoverPlugins()
        let plugin = marketplace.availablePlugins.first!
        try? await marketplace.installPlugin(plugin)
        
        // Check for updates
        let updates = await marketplace.checkForUpdates()
        
        // Should return array (may be empty if no updates available)
        XCTAssertNotNil(updates)
        
        // If there are updates, verify structure
        for update in updates {
            XCTAssertFalse(update.pluginId.isEmpty)
            XCTAssertFalse(update.currentVersion.isEmpty)
            XCTAssertFalse(update.newVersion.isEmpty)
            XCTAssertFalse(update.changelog.isEmpty)
        }
    }
    
    func testPluginUpdate() async throws {
        // This test would require a plugin with an available update
        // For now, we'll test the error case
        do {
            try await marketplace.updatePlugin("nonexistent")
            XCTFail("Should throw error for non-existent plugin")
        } catch {
            XCTAssertTrue(error is MarketplaceError)
        }
    }
    
    // MARK: - Reviews and Ratings Tests
    func testSubmitReview() async throws {
        let pluginId = "test-plugin"
        
        // Submit a valid review
        try await marketplace.submitReview(for: pluginId, rating: 5, comment: "Excellent plugin!")
        
        // Submit another review
        try await marketplace.submitReview(for: pluginId, rating: 4, comment: "Good plugin, but could be better.")
    }
    
    func testSubmitInvalidRating() async {
        do {
            try await marketplace.submitReview(for: "test", rating: 0, comment: "Invalid rating")
            XCTFail("Should throw error for invalid rating")
        } catch {
            XCTAssertTrue(error is MarketplaceError)
        }
        
        do {
            try await marketplace.submitReview(for: "test", rating: 6, comment: "Invalid rating")
            XCTFail("Should throw error for invalid rating")
        } catch {
            XCTAssertTrue(error is MarketplaceError)
        }
    }
    
    func testGetReviews() async throws {
        let pluginId = "test-plugin"
        let reviews = try await marketplace.getReviews(for: pluginId)
        
        XCTAssertNotNil(reviews)
        
        // Verify review structure
        for review in reviews {
            XCTAssertEqual(review.pluginId, pluginId)
            XCTAssertGreaterThanOrEqual(review.rating, 1)
            XCTAssertLessThanOrEqual(review.rating, 5)
            XCTAssertFalse(review.comment.isEmpty)
            XCTAssertNotNil(review.timestamp)
        }
    }
    
    // MARK: - Analytics Tests
    func testTrackPluginUsage() async {
        let pluginId = "test-plugin"
        
        // Track usage (should not throw)
        await marketplace.trackPluginUsage(pluginId)
    }
    
    func testGetPluginAnalytics() async throws {
        let pluginId = "test-plugin"
        let analytics = try await marketplace.getPluginAnalytics(pluginId)
        
        XCTAssertEqual(analytics.pluginId, pluginId)
        XCTAssertGreaterThanOrEqual(analytics.totalDownloads, 0)
        XCTAssertGreaterThanOrEqual(analytics.activeUsers, 0)
        XCTAssertGreaterThanOrEqual(analytics.averageRating, 0.0)
        XCTAssertLessThanOrEqual(analytics.averageRating, 5.0)
        XCTAssertGreaterThanOrEqual(analytics.reviewCount, 0)
        XCTAssertFalse(analytics.usageStats.isEmpty)
        XCTAssertFalse(analytics.performanceMetrics.isEmpty)
    }
    
    // MARK: - Category Tests
    func testCategories() {
        let categories = marketplace.categories
        
        XCTAssertFalse(categories.isEmpty)
        
        // Verify category structure
        for category in categories {
            XCTAssertFalse(category.id.isEmpty)
            XCTAssertFalse(category.name.isEmpty)
            XCTAssertFalse(category.description.isEmpty)
        }
        
        // Check for specific categories
        let categoryIds = categories.map { $0.id }
        XCTAssertTrue(categoryIds.contains("health-monitoring"))
        XCTAssertTrue(categoryIds.contains("sleep-analysis"))
        XCTAssertTrue(categoryIds.contains("workout-tracking"))
        XCTAssertTrue(categoryIds.contains("mental-health"))
    }
    
    // MARK: - Error Handling Tests
    func testNetworkErrorHandling() async {
        // Simulate network error by testing with invalid marketplace
        // This would require mocking the API layer
        // For now, we'll test that errors are properly handled
        
        await marketplace.discoverPlugins()
        
        // If there's an error, it should be captured
        if let error = marketplace.error {
            XCTAssertFalse(error.isEmpty)
        }
    }
    
    // MARK: - Concurrent Operations Tests
    func testConcurrentPluginOperations() async {
        await withTaskGroup(of: Void.self) { group in
            // Add multiple concurrent operations
            group.addTask {
                await self.marketplace.discoverPlugins()
            }
            
            group.addTask {
                await self.marketplace.searchPlugins(query: "test")
            }
            
            group.addTask {
                let updates = await self.marketplace.checkForUpdates()
                XCTAssertNotNil(updates)
            }
        }
        
        // Verify no crashes occurred
        XCTAssertNotNil(marketplace)
    }
    
    // MARK: - Integration Tests
    func testCompletePluginWorkflow() async throws {
        // 1. Discover plugins
        await marketplace.discoverPlugins()
        XCTAssertFalse(marketplace.availablePlugins.isEmpty)
        
        // 2. Search for a specific plugin
        await marketplace.searchPlugins(query: "sleep")
        XCTAssertNotNil(marketplace.searchResults)
        
        // 3. Install a plugin
        let plugin = marketplace.availablePlugins.first!
        try await marketplace.installPlugin(plugin)
        XCTAssertNotNil(marketplace.installedPlugins[plugin.id])
        
        // 4. Check for updates
        let updates = await marketplace.checkForUpdates()
        XCTAssertNotNil(updates)
        
        // 5. Submit a review
        try await marketplace.submitReview(for: plugin.id, rating: 5, comment: "Great plugin!")
        
        // 6. Get reviews
        let reviews = try await marketplace.getReviews(for: plugin.id)
        XCTAssertNotNil(reviews)
        
        // 7. Track usage
        await marketplace.trackPluginUsage(plugin.id)
        
        // 8. Get analytics
        let analytics = try await marketplace.getPluginAnalytics(plugin.id)
        XCTAssertNotNil(analytics)
        
        // 9. Uninstall plugin
        try await marketplace.uninstallPlugin(plugin.id)
        XCTAssertNil(marketplace.installedPlugins[plugin.id])
    }
    
    // MARK: - Performance Tests
    func testMarketplacePerformance() async {
        let startTime = Date()
        
        await marketplace.discoverPlugins()
        
        let discoveryTime = Date().timeIntervalSince(startTime)
        XCTAssertLessThan(discoveryTime, 5.0) // Should complete within 5 seconds
        
        let searchStartTime = Date()
        await marketplace.searchPlugins(query: "test")
        
        let searchTime = Date().timeIntervalSince(searchStartTime)
        XCTAssertLessThan(searchTime, 3.0) // Should complete within 3 seconds
    }
    
    // MARK: - Memory Management Tests
    func testMarketplaceMemoryManagement() {
        weak var weakMarketplace: PluginMarketplace?
        
        autoreleasepool {
            let manager = HealthAIPluginManager()
            let marketplace = PluginMarketplace(pluginManager: manager)
            weakMarketplace = marketplace
        }
        
        // The marketplace should be deallocated after the autoreleasepool
        XCTAssertNil(weakMarketplace)
    }
} 
import Foundation
import SwiftUI

// MARK: - Plugin Marketplace
@MainActor
public class PluginMarketplace: ObservableObject {
    @Published private(set) var availablePlugins: [MarketplacePlugin] = []
    @Published private(set) var installedPlugins: [String: InstalledPlugin] = [:]
    @Published private(set) var searchResults: [MarketplacePlugin] = []
    @Published private(set) var categories: [PluginCategory] = []
    @Published private(set) var isLoading = false
    @Published private(set) var error: String?
    
    private let pluginManager: HealthAIPluginManager
    private let marketplaceAPI = MarketplaceAPI()
    private let pluginInstaller = PluginInstaller()
    
    public init(pluginManager: HealthAIPluginManager) {
        self.pluginManager = pluginManager
        loadCategories()
    }
    
    // MARK: - Plugin Discovery
    public func discoverPlugins() async {
        isLoading = true
        error = nil
        
        do {
            availablePlugins = try await marketplaceAPI.fetchAvailablePlugins()
            isLoading = false
        } catch {
            self.error = error.localizedDescription
            isLoading = false
        }
    }
    
    public func searchPlugins(query: String, category: PluginCategory? = nil) async {
        isLoading = true
        error = nil
        
        do {
            searchResults = try await marketplaceAPI.searchPlugins(query: query, category: category)
            isLoading = false
        } catch {
            self.error = error.localizedDescription
            isLoading = false
        }
    }
    
    public func getPluginsByCategory(_ category: PluginCategory) async {
        isLoading = true
        error = nil
        
        do {
            searchResults = try await marketplaceAPI.getPluginsByCategory(category)
            isLoading = false
        } catch {
            self.error = error.localizedDescription
            isLoading = false
        }
    }
    
    // MARK: - Plugin Installation
    public func installPlugin(_ plugin: MarketplacePlugin) async throws {
        isLoading = true
        error = nil
        
        do {
            let installedPlugin = try await pluginInstaller.install(plugin)
            installedPlugins[plugin.id] = installedPlugin
            
            // Load the plugin into the plugin manager
            try await pluginManager.loadPlugin(at: installedPlugin.installationPath)
            
            isLoading = false
        } catch {
            self.error = error.localizedDescription
            isLoading = false
            throw error
        }
    }
    
    public func uninstallPlugin(_ pluginId: String) async throws {
        guard let installedPlugin = installedPlugins[pluginId] else {
            throw MarketplaceError.pluginNotInstalled
        }
        
        isLoading = true
        error = nil
        
        do {
            // Unload from plugin manager
            try await pluginManager.unloadPlugin(pluginId)
            
            // Remove from filesystem
            try await pluginInstaller.uninstall(installedPlugin)
            
            installedPlugins.removeValue(forKey: pluginId)
            isLoading = false
        } catch {
            self.error = error.localizedDescription
            isLoading = false
            throw error
        }
    }
    
    // MARK: - Plugin Updates
    public func checkForUpdates() async -> [PluginUpdate] {
        var updates: [PluginUpdate] = []
        
        for (pluginId, installedPlugin) in installedPlugins {
            if let availablePlugin = availablePlugins.first(where: { $0.id == pluginId }) {
                if availablePlugin.version > installedPlugin.version {
                    updates.append(PluginUpdate(
                        pluginId: pluginId,
                        currentVersion: installedPlugin.version,
                        newVersion: availablePlugin.version,
                        changelog: availablePlugin.changelog
                    ))
                }
            }
        }
        
        return updates
    }
    
    public func updatePlugin(_ pluginId: String) async throws {
        guard let update = (await checkForUpdates()).first(where: { $0.pluginId == pluginId }) else {
            throw MarketplaceError.noUpdateAvailable
        }
        
        guard let availablePlugin = availablePlugins.first(where: { $0.id == pluginId }) else {
            throw MarketplaceError.pluginNotFound
        }
        
        // Uninstall current version
        try await uninstallPlugin(pluginId)
        
        // Install new version
        try await installPlugin(availablePlugin)
    }
    
    // MARK: - Reviews and Ratings
    public func submitReview(for pluginId: String, rating: Int, comment: String) async throws {
        guard rating >= 1 && rating <= 5 else {
            throw MarketplaceError.invalidRating
        }
        
        let review = PluginReview(
            pluginId: pluginId,
            rating: rating,
            comment: comment,
            timestamp: Date()
        )
        
        try await marketplaceAPI.submitReview(review)
    }
    
    public func getReviews(for pluginId: String) async throws -> [PluginReview] {
        return try await marketplaceAPI.getReviews(for: pluginId)
    }
    
    // MARK: - Analytics
    public func trackPluginUsage(_ pluginId: String) async {
        await marketplaceAPI.trackUsage(pluginId: pluginId)
    }
    
    public func getPluginAnalytics(_ pluginId: String) async throws -> PluginAnalytics {
        return try await marketplaceAPI.getAnalytics(for: pluginId)
    }
    
    // MARK: - Private Methods
    private func loadCategories() {
        categories = [
            PluginCategory(id: "health-monitoring", name: "Health Monitoring", description: "Plugins for monitoring health metrics"),
            PluginCategory(id: "data-analysis", name: "Data Analysis", description: "Advanced data analysis and insights"),
            PluginCategory(id: "workout-tracking", name: "Workout Tracking", description: "Fitness and exercise tracking"),
            PluginCategory(id: "sleep-analysis", name: "Sleep Analysis", description: "Sleep tracking and analysis"),
            PluginCategory(id: "mental-health", name: "Mental Health", description: "Mental health and wellness tools"),
            PluginCategory(id: "nutrition", name: "Nutrition", description: "Nutrition tracking and advice"),
            PluginCategory(id: "meditation", name: "Meditation", description: "Meditation and mindfulness tools"),
            PluginCategory(id: "utilities", name: "Utilities", description: "Utility and helper plugins")
        ]
    }
}

// MARK: - Supporting Models
public struct MarketplacePlugin: Identifiable, Codable {
    public let id: String
    public let name: String
    public let version: String
    public let description: String
    public let author: String
    public let category: String
    public let permissions: [PluginPermission]
    public let downloadUrl: String
    public let downloadCount: Int
    public let averageRating: Double
    public let reviewCount: Int
    public let changelog: String
    public let releaseDate: Date
    public let size: Int64
    public let compatibility: [String]
    public let tags: [String]
}

public struct InstalledPlugin: Identifiable {
    public let id: String
    public let name: String
    public let version: String
    public let installationPath: String
    public let installDate: Date
    public let lastUsed: Date?
    public let usageCount: Int
}

public struct PluginCategory: Identifiable {
    public let id: String
    public let name: String
    public let description: String
}

public struct PluginUpdate {
    public let pluginId: String
    public let currentVersion: String
    public let newVersion: String
    public let changelog: String
}

public struct PluginReview: Identifiable, Codable {
    public let id = UUID()
    public let pluginId: String
    public let rating: Int
    public let comment: String
    public let timestamp: Date
    public let userId: String?
}

public struct PluginAnalytics {
    public let pluginId: String
    public let totalDownloads: Int
    public let activeUsers: Int
    public let averageRating: Double
    public let reviewCount: Int
    public let usageStats: [String: Int]
    public let performanceMetrics: [String: Double]
}

// MARK: - Errors
public enum MarketplaceError: Error {
    case pluginNotFound
    case pluginNotInstalled
    case noUpdateAvailable
    case invalidRating
    case installationFailed
    case networkError
    case serverError
}

// MARK: - API Layer
private class MarketplaceAPI {
    private let baseURL = "https://api.healthai2030.com/marketplace"
    
    func fetchAvailablePlugins() async throws -> [MarketplacePlugin] {
        // Simulate API call
        return [
            MarketplacePlugin(
                id: "sleep-analyzer",
                name: "Advanced Sleep Analyzer",
                version: "2.1.0",
                description: "Advanced sleep analysis with AI-powered insights",
                author: "SleepTech Labs",
                category: "sleep-analysis",
                permissions: [.healthData],
                downloadUrl: "https://example.com/sleep-analyzer",
                downloadCount: 15420,
                averageRating: 4.8,
                reviewCount: 342,
                changelog: "Improved accuracy, new sleep stage detection",
                releaseDate: Date(),
                size: 1024 * 1024 * 5, // 5MB
                compatibility: ["iOS 17.0+", "watchOS 10.0+"],
                tags: ["sleep", "analysis", "AI"]
            ),
            MarketplacePlugin(
                id: "workout-tracker",
                name: "Smart Workout Tracker",
                version: "1.5.2",
                description: "Intelligent workout tracking with form analysis",
                author: "FitAI",
                category: "workout-tracking",
                permissions: [.healthData, .location],
                downloadUrl: "https://example.com/workout-tracker",
                downloadCount: 8920,
                averageRating: 4.6,
                reviewCount: 156,
                changelog: "Added new workout types, improved GPS accuracy",
                releaseDate: Date().addingTimeInterval(-86400 * 7), // 7 days ago
                size: 1024 * 1024 * 8, // 8MB
                compatibility: ["iOS 17.0+", "watchOS 10.0+"],
                tags: ["workout", "fitness", "tracking"]
            )
        ]
    }
    
    func searchPlugins(query: String, category: PluginCategory?) async throws -> [MarketplacePlugin] {
        let plugins = try await fetchAvailablePlugins()
        
        var filtered = plugins
        
        if let category = category {
            filtered = filtered.filter { $0.category == category.id }
        }
        
        if !query.isEmpty {
            filtered = filtered.filter { plugin in
                plugin.name.localizedCaseInsensitiveContains(query) ||
                plugin.description.localizedCaseInsensitiveContains(query) ||
                plugin.tags.contains { $0.localizedCaseInsensitiveContains(query) }
            }
        }
        
        return filtered
    }
    
    func getPluginsByCategory(_ category: PluginCategory) async throws -> [MarketplacePlugin] {
        let plugins = try await fetchAvailablePlugins()
        return plugins.filter { $0.category == category.id }
    }
    
    func submitReview(_ review: PluginReview) async throws {
        // Simulate API call
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
    }
    
    func getReviews(for pluginId: String) async throws -> [PluginReview] {
        // Simulate API call
        return [
            PluginReview(
                pluginId: pluginId,
                rating: 5,
                comment: "Excellent plugin! Very accurate and easy to use.",
                timestamp: Date(),
                userId: "user123"
            ),
            PluginReview(
                pluginId: pluginId,
                rating: 4,
                comment: "Great functionality, but could use some UI improvements.",
                timestamp: Date().addingTimeInterval(-86400),
                userId: "user456"
            )
        ]
    }
    
    func trackUsage(pluginId: String) async {
        // Simulate analytics tracking
    }
    
    func getAnalytics(for pluginId: String) async throws -> PluginAnalytics {
        return PluginAnalytics(
            pluginId: pluginId,
            totalDownloads: 15420,
            activeUsers: 8920,
            averageRating: 4.8,
            reviewCount: 342,
            usageStats: ["daily": 1200, "weekly": 8500, "monthly": 32000],
            performanceMetrics: ["avg_load_time": 0.5, "memory_usage": 45.2, "cpu_usage": 12.8]
        )
    }
}

// MARK: - Plugin Installer
private class PluginInstaller {
    func install(_ plugin: MarketplacePlugin) async throws -> InstalledPlugin {
        // Simulate plugin installation
        let installationPath = "/Applications/HealthAI2030/Plugins/\(plugin.id)"
        
        // In a real implementation, this would:
        // 1. Download the plugin from downloadUrl
        // 2. Validate the download
        // 3. Extract to the plugins directory
        // 4. Verify installation
        
        return InstalledPlugin(
            id: plugin.id,
            name: plugin.name,
            version: plugin.version,
            installationPath: installationPath,
            installDate: Date(),
            lastUsed: nil,
            usageCount: 0
        )
    }
    
    func uninstall(_ plugin: InstalledPlugin) async throws {
        // Simulate plugin uninstallation
        // In a real implementation, this would:
        // 1. Stop the plugin if running
        // 2. Remove files from filesystem
        // 3. Clean up any configuration
    }
} 
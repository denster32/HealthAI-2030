import Foundation
import SwiftUI

// MARK: - Feature Flag Manager
@MainActor
public class FeatureFlagManager: ObservableObject {
    @Published private(set) var featureFlags: [String: FeatureFlag] = [:]
    @Published private(set) var experiments: [String: Experiment] = [:]
    @Published private(set) var isLoading = false
    @Published private(set) var error: String?
    
    private let flagStorage = FeatureFlagStorage()
    private let experimentEngine = ExperimentEngine()
    private let analyticsTracker = FeatureFlagAnalytics()
    private let remoteConfig = RemoteConfigurationService()
    
    public init() {
        loadFeatureFlags()
    }
    
    // MARK: - Feature Flag Management
    public func loadFeatureFlags() {
        Task {
            isLoading = true
            error = nil
            
            do {
                let flags = try await flagStorage.loadFeatureFlags()
                featureFlags = flags
                
                // Load experiments
                let experiments = try await experimentEngine.loadExperiments()
                self.experiments = experiments
                
                isLoading = false
            } catch {
                self.error = error.localizedDescription
                isLoading = false
            }
        }
    }
    
    public func isFeatureEnabled(_ featureName: String, for userId: String? = nil) -> Bool {
        guard let flag = featureFlags[featureName] else {
            return false
        }
        
        // Check if feature is globally enabled
        if !flag.isEnabled {
            return false
        }
        
        // Check rollout percentage
        if let userId = userId {
            return isUserInRollout(featureName: featureName, userId: userId, percentage: flag.rolloutPercentage)
        }
        
        return true
    }
    
    public func getFeatureFlag(_ featureName: String) -> FeatureFlag? {
        return featureFlags[featureName]
    }
    
    public func updateFeatureFlag(_ featureName: String, isEnabled: Bool, rolloutPercentage: Int = 100) async throws {
        var updatedFlags = featureFlags
        
        if let existingFlag = updatedFlags[featureName] {
            updatedFlags[featureName] = FeatureFlag(
                name: existingFlag.name,
                isEnabled: isEnabled,
                rolloutPercentage: rolloutPercentage,
                targetUsers: existingFlag.targetUsers,
                environment: existingFlag.environment,
                description: existingFlag.description,
                createdAt: existingFlag.createdAt,
                updatedAt: Date()
            )
        } else {
            updatedFlags[featureName] = FeatureFlag(
                name: featureName,
                isEnabled: isEnabled,
                rolloutPercentage: rolloutPercentage,
                targetUsers: [],
                environment: .development,
                description: "",
                createdAt: Date(),
                updatedAt: Date()
            )
        }
        
        featureFlags = updatedFlags
        try await flagStorage.saveFeatureFlags(updatedFlags)
        
        // Track the change
        await analyticsTracker.trackFlagUpdate(featureName: featureName, isEnabled: isEnabled, rolloutPercentage: rolloutPercentage)
    }
    
    public func deleteFeatureFlag(_ featureName: String) async throws {
        var updatedFlags = featureFlags
        updatedFlags.removeValue(forKey: featureName)
        
        featureFlags = updatedFlags
        try await flagStorage.saveFeatureFlags(updatedFlags)
        
        // Track the deletion
        await analyticsTracker.trackFlagDeletion(featureName: featureName)
    }
    
    // MARK: - A/B Testing
    public func createExperiment(_ experiment: Experiment) async throws {
        var updatedExperiments = experiments
        updatedExperiments[experiment.id] = experiment
        
        experiments = updatedExperiments
        try await experimentEngine.saveExperiment(experiment)
        
        // Track experiment creation
        await analyticsTracker.trackExperimentCreation(experiment: experiment)
    }
    
    public func getExperimentVariant(_ experimentId: String, for userId: String) -> ExperimentVariant? {
        guard let experiment = experiments[experimentId] else {
            return nil
        }
        
        return experimentEngine.getVariant(experiment: experiment, userId: userId)
    }
    
    public func trackExperimentEvent(_ experimentId: String, event: String, userId: String, metadata: [String: Any] = [:]) async {
        await analyticsTracker.trackExperimentEvent(
            experimentId: experimentId,
            event: event,
            userId: userId,
            metadata: metadata
        )
    }
    
    public func getExperimentResults(_ experimentId: String) async throws -> ExperimentResults {
        return try await analyticsTracker.getExperimentResults(experimentId: experimentId)
    }
    
    // MARK: - Gradual Rollouts
    public func startGradualRollout(_ featureName: String, targetPercentage: Int, duration: TimeInterval) async throws {
        guard let flag = featureFlags[featureName] else {
            throw FeatureFlagError.flagNotFound
        }
        
        let rollout = GradualRollout(
            featureName: featureName,
            startPercentage: flag.rolloutPercentage,
            targetPercentage: targetPercentage,
            startTime: Date(),
            duration: duration,
            isActive: true
        )
        
        try await flagStorage.saveGradualRollout(rollout)
        
        // Track rollout start
        await analyticsTracker.trackRolloutStart(rollout: rollout)
    }
    
    public func getActiveRollouts() async throws -> [GradualRollout] {
        return try await flagStorage.getActiveRollouts()
    }
    
    public func pauseRollout(_ featureName: String) async throws {
        try await flagStorage.pauseRollout(featureName: featureName)
        
        // Track rollout pause
        await analyticsTracker.trackRolloutPause(featureName: featureName)
    }
    
    public func resumeRollout(_ featureName: String) async throws {
        try await flagStorage.resumeRollout(featureName: featureName)
        
        // Track rollout resume
        await analyticsTracker.trackRolloutResume(featureName: featureName)
    }
    
    // MARK: - User Targeting
    public func addTargetUser(_ userId: String, to featureName: String) async throws {
        guard var flag = featureFlags[featureName] else {
            throw FeatureFlagError.flagNotFound
        }
        
        var targetUsers = flag.targetUsers
        if !targetUsers.contains(userId) {
            targetUsers.append(userId)
        }
        
        flag.targetUsers = targetUsers
        flag.updatedAt = Date()
        
        featureFlags[featureName] = flag
        try await flagStorage.saveFeatureFlags(featureFlags)
        
        // Track user targeting
        await analyticsTracker.trackUserTargeting(featureName: featureName, userId: userId, action: "add")
    }
    
    public func removeTargetUser(_ userId: String, from featureName: String) async throws {
        guard var flag = featureFlags[featureName] else {
            throw FeatureFlagError.flagNotFound
        }
        
        flag.targetUsers.removeAll { $0 == userId }
        flag.updatedAt = Date()
        
        featureFlags[featureName] = flag
        try await flagStorage.saveFeatureFlags(featureFlags)
        
        // Track user targeting removal
        await analyticsTracker.trackUserTargeting(featureName: featureName, userId: userId, action: "remove")
    }
    
    public func isUserTargeted(_ userId: String, for featureName: String) -> Bool {
        guard let flag = featureFlags[featureName] else {
            return false
        }
        
        return flag.targetUsers.contains(userId)
    }
    
    // MARK: - Analytics and Monitoring
    public func getFeatureFlagAnalytics(_ featureName: String) async throws -> FeatureFlagAnalytics {
        return try await analyticsTracker.getFeatureFlagAnalytics(featureName: featureName)
    }
    
    public func getFeatureFlagUsage(_ featureName: String, timeRange: TimeRange) async throws -> [FeatureFlagUsage] {
        return try await analyticsTracker.getFeatureFlagUsage(featureName: featureName, timeRange: timeRange)
    }
    
    public func getActiveExperiments() -> [Experiment] {
        return Array(experiments.values.filter { $0.isActive })
    }
    
    public func getExperimentAnalytics(_ experimentId: String) async throws -> ExperimentAnalytics {
        return try await analyticsTracker.getExperimentAnalytics(experimentId: experimentId)
    }
    
    // MARK: - Emergency Controls
    public func emergencyDisable(_ featureName: String) async throws {
        try await updateFeatureFlag(featureName, isEnabled: false, rolloutPercentage: 0)
        
        // Track emergency disable
        await analyticsTracker.trackEmergencyAction(featureName: featureName, action: "disable")
    }
    
    public func emergencyEnable(_ featureName: String) async throws {
        try await updateFeatureFlag(featureName, isEnabled: true, rolloutPercentage: 100)
        
        // Track emergency enable
        await analyticsTracker.trackEmergencyAction(featureName: featureName, action: "enable")
    }
    
    // MARK: - Remote Configuration
    public func refreshFromRemote() async throws {
        let remoteFlags = try await remoteConfig.fetchFeatureFlags()
        featureFlags = remoteFlags
        
        let remoteExperiments = try await remoteConfig.fetchExperiments()
        experiments = remoteExperiments
        
        // Save to local storage
        try await flagStorage.saveFeatureFlags(featureFlags)
        for experiment in experiments.values {
            try await experimentEngine.saveExperiment(experiment)
        }
    }
    
    // MARK: - Private Methods
    private func isUserInRollout(featureName: String, userId: String, percentage: Int) -> Bool {
        // Use consistent hashing to ensure same user always gets same result
        let hash = userId.hashValue
        let normalizedHash = abs(hash) % 100
        
        return normalizedHash < percentage
    }
}

// MARK: - Supporting Models
public struct FeatureFlag: Codable, Identifiable {
    public let id = UUID()
    public let name: String
    public let isEnabled: Bool
    public let rolloutPercentage: Int
    public let targetUsers: [String]
    public let environment: Environment
    public let description: String
    public let createdAt: Date
    public let updatedAt: Date
    
    public init(
        name: String,
        isEnabled: Bool,
        rolloutPercentage: Int,
        targetUsers: [String],
        environment: Environment,
        description: String = "",
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.name = name
        self.isEnabled = isEnabled
        self.rolloutPercentage = rolloutPercentage
        self.targetUsers = targetUsers
        self.environment = environment
        self.description = description
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

public struct Experiment: Codable, Identifiable {
    public let id: String
    public let name: String
    public let description: String
    public let variants: [ExperimentVariant]
    public let isActive: Bool
    public let startDate: Date
    public let endDate: Date?
    public let targetAudience: [String]
    public let trafficAllocation: Int
    
    public init(
        id: String,
        name: String,
        description: String,
        variants: [ExperimentVariant],
        isActive: Bool = true,
        startDate: Date = Date(),
        endDate: Date? = nil,
        targetAudience: [String] = [],
        trafficAllocation: Int = 100
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.variants = variants
        self.isActive = isActive
        self.startDate = startDate
        self.endDate = endDate
        self.targetAudience = targetAudience
        self.trafficAllocation = trafficAllocation
    }
}

public struct ExperimentVariant: Codable {
    public let id: String
    public let name: String
    public let weight: Int
    public let configuration: [String: Any]
    
    public init(id: String, name: String, weight: Int, configuration: [String: Any] = [:]) {
        self.id = id
        self.name = name
        self.weight = weight
        self.configuration = configuration
    }
}

public struct GradualRollout: Codable {
    public let featureName: String
    public let startPercentage: Int
    public let targetPercentage: Int
    public let startTime: Date
    public let duration: TimeInterval
    public let isActive: Bool
    
    public var currentPercentage: Int {
        guard isActive else { return startPercentage }
        
        let elapsed = Date().timeIntervalSince(startTime)
        let progress = min(elapsed / duration, 1.0)
        
        return Int(Double(startPercentage) + (Double(targetPercentage - startPercentage) * progress))
    }
}

public struct FeatureFlagAnalytics: Codable {
    public let featureName: String
    public let totalUsers: Int
    public let enabledUsers: Int
    public let conversionRate: Double
    public let averageSessionDuration: TimeInterval
    public let errorRate: Double
}

public struct FeatureFlagUsage: Codable {
    public let timestamp: Date
    public let userCount: Int
    public let enabledCount: Int
    public let eventCount: Int
}

public struct ExperimentResults: Codable {
    public let experimentId: String
    public let variantResults: [String: VariantResult]
    public let statisticalSignificance: Double
    public let winner: String?
}

public struct VariantResult: Codable {
    public let variantId: String
    public let userCount: Int
    public let conversionRate: Double
    public let averageValue: Double
    public let confidenceInterval: (Double, Double)
}

public struct ExperimentAnalytics: Codable {
    public let experimentId: String
    public let totalUsers: Int
    public let activeUsers: Int
    public let conversionRate: Double
    public let averageSessionDuration: TimeInterval
}

public enum TimeRange {
    case lastHour
    case lastDay
    case lastWeek
    case lastMonth
    case custom(start: Date, end: Date)
}

public enum FeatureFlagError: Error {
    case flagNotFound
    case invalidRolloutPercentage
    case experimentNotFound
    case invalidVariant
    case storageError
    case networkError
}

// MARK: - Supporting Classes
private class FeatureFlagStorage {
    func loadFeatureFlags() async throws -> [String: FeatureFlag] {
        // Simulate loading from storage
        return [
            "advanced_analytics": FeatureFlag(
                name: "advanced_analytics",
                isEnabled: true,
                rolloutPercentage: 50,
                targetUsers: ["beta_users"],
                environment: .production,
                description: "Advanced analytics features"
            ),
            "new_ui": FeatureFlag(
                name: "new_ui",
                isEnabled: false,
                rolloutPercentage: 0,
                targetUsers: [],
                environment: .development,
                description: "New user interface design"
            )
        ]
    }
    
    func saveFeatureFlags(_ flags: [String: FeatureFlag]) async throws {
        // Simulate saving to storage
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
    }
    
    func saveGradualRollout(_ rollout: GradualRollout) async throws {
        // Simulate saving rollout
        try await Task.sleep(nanoseconds: 50_000_000) // 0.05 seconds
    }
    
    func getActiveRollouts() async throws -> [GradualRollout] {
        // Simulate getting active rollouts
        return []
    }
    
    func pauseRollout(featureName: String) async throws {
        // Simulate pausing rollout
        try await Task.sleep(nanoseconds: 50_000_000) // 0.05 seconds
    }
    
    func resumeRollout(featureName: String) async throws {
        // Simulate resuming rollout
        try await Task.sleep(nanoseconds: 50_000_000) // 0.05 seconds
    }
}

private class ExperimentEngine {
    func loadExperiments() async throws -> [String: Experiment] {
        // Simulate loading experiments
        return [:]
    }
    
    func saveExperiment(_ experiment: Experiment) async throws {
        // Simulate saving experiment
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
    }
    
    func getVariant(experiment: Experiment, userId: String) -> ExperimentVariant? {
        // Simple hash-based variant selection
        let hash = userId.hashValue
        let normalizedHash = abs(hash) % 100
        
        var cumulativeWeight = 0
        for variant in experiment.variants {
            cumulativeWeight += variant.weight
            if normalizedHash < cumulativeWeight {
                return variant
            }
        }
        
        return experiment.variants.first
    }
}

private class FeatureFlagAnalytics {
    func trackFlagUpdate(featureName: String, isEnabled: Bool, rolloutPercentage: Int) async {
        // Simulate tracking
    }
    
    func trackFlagDeletion(featureName: String) async {
        // Simulate tracking
    }
    
    func trackExperimentCreation(experiment: Experiment) async {
        // Simulate tracking
    }
    
    func trackExperimentEvent(experimentId: String, event: String, userId: String, metadata: [String: Any]) async {
        // Simulate tracking
    }
    
    func getExperimentResults(experimentId: String) async throws -> ExperimentResults {
        // Simulate getting results
        return ExperimentResults(
            experimentId: experimentId,
            variantResults: [:],
            statisticalSignificance: 0.0,
            winner: nil
        )
    }
    
    func getFeatureFlagAnalytics(featureName: String) async throws -> FeatureFlagAnalytics {
        // Simulate getting analytics
        return FeatureFlagAnalytics(
            featureName: featureName,
            totalUsers: 1000,
            enabledUsers: 500,
            conversionRate: 0.15,
            averageSessionDuration: 300,
            errorRate: 0.01
        )
    }
    
    func getFeatureFlagUsage(featureName: String, timeRange: TimeRange) async throws -> [FeatureFlagUsage] {
        // Simulate getting usage data
        return []
    }
    
    func getExperimentAnalytics(experimentId: String) async throws -> ExperimentAnalytics {
        // Simulate getting analytics
        return ExperimentAnalytics(
            experimentId: experimentId,
            totalUsers: 500,
            activeUsers: 250,
            conversionRate: 0.12,
            averageSessionDuration: 280
        )
    }
    
    func trackUserTargeting(featureName: String, userId: String, action: String) async {
        // Simulate tracking
    }
    
    func trackRolloutStart(rollout: GradualRollout) async {
        // Simulate tracking
    }
    
    func trackRolloutPause(featureName: String) async {
        // Simulate tracking
    }
    
    func trackRolloutResume(featureName: String) async {
        // Simulate tracking
    }
    
    func trackEmergencyAction(featureName: String, action: String) async {
        // Simulate tracking
    }
}

private class RemoteConfigurationService {
    func fetchFeatureFlags() async throws -> [String: FeatureFlag] {
        // Simulate fetching from remote
        return [:]
    }
    
    func fetchExperiments() async throws -> [String: Experiment] {
        // Simulate fetching from remote
        return [:]
    }
} 
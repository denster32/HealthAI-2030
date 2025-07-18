import Foundation
import SwiftUI

// MARK: - Configuration Manager
@MainActor
public class AppConfigurationManager: ObservableObject {
    @Published private(set) var currentEnvironment: Environment = .development
    @Published private(set) var configuration: AppConfiguration
    @Published private(set) var featureFlags: [String: FeatureFlag] = [:]
    @Published private(set) var isLoading = false
    @Published private(set) var error: String?
    
    private let configurationLoader = ConfigurationLoader()
    private let featureFlagManager = FeatureFlagManager()
    private let configurationValidator = ConfigurationValidator()
    private let secureStorage = SecureConfigurationStorage()
    
    public init() {
        // Load default configuration
        self.configuration = AppConfiguration.default
        loadConfiguration()
    }
    
    // MARK: - Environment Management
    public func switchEnvironment(_ environment: Environment) async throws {
        isLoading = true
        error = nil
        
        do {
            let newConfiguration = try await configurationLoader.loadConfiguration(for: environment)
            
            // Validate configuration
            try configurationValidator.validate(newConfiguration)
            
            // Update current environment and configuration
            currentEnvironment = environment
            configuration = newConfiguration
            
            // Load feature flags for new environment
            featureFlags = try await featureFlagManager.loadFeatureFlags(for: environment)
            
            // Save configuration to secure storage
            try await secureStorage.saveConfiguration(newConfiguration, for: environment)
            
            isLoading = false
        } catch {
            self.error = error.localizedDescription
            isLoading = false
            throw error
        }
    }
    
    public func getEnvironment() -> Environment {
        return currentEnvironment
    }
    
    public func getAvailableEnvironments() -> [Environment] {
        return Environment.allCases
    }
    
    // MARK: - Configuration Access
    public func getConfiguration() -> AppConfiguration {
        return configuration
    }
    
    public func getConfigurationValue<T>(for key: ConfigurationKey) -> T? {
        return configuration.getValue(for: key) as? T
    }
    
    public func setConfigurationValue<T>(_ value: T, for key: ConfigurationKey) async throws {
        var updatedConfiguration = configuration
        updatedConfiguration.setValue(value, for: key)
        
        // Validate updated configuration
        try configurationValidator.validate(updatedConfiguration)
        
        // Update configuration
        configuration = updatedConfiguration
        
        // Save to secure storage
        try await secureStorage.saveConfiguration(configuration, for: currentEnvironment)
    }
    
    // MARK: - Feature Flag Management
    public func isFeatureEnabled(_ featureName: String) -> Bool {
        guard let flag = featureFlags[featureName] else {
            return false
        }
        
        return flag.isEnabled
    }
    
    public func getFeatureFlag(_ featureName: String) -> FeatureFlag? {
        return featureFlags[featureName]
    }
    
    public func updateFeatureFlag(_ featureName: String, isEnabled: Bool) async throws {
        var updatedFlags = featureFlags
        if let existingFlag = updatedFlags[featureName] {
            updatedFlags[featureName] = FeatureFlag(
                name: existingFlag.name,
                isEnabled: isEnabled,
                rolloutPercentage: existingFlag.rolloutPercentage,
                targetUsers: existingFlag.targetUsers,
                environment: existingFlag.environment
            )
        } else {
            updatedFlags[featureName] = FeatureFlag(
                name: featureName,
                isEnabled: isEnabled,
                rolloutPercentage: 100,
                targetUsers: [],
                environment: currentEnvironment
            )
        }
        
        featureFlags = updatedFlags
        try await featureFlagManager.saveFeatureFlags(updatedFlags, for: currentEnvironment)
    }
    
    public func getFeatureFlags() -> [String: FeatureFlag] {
        return featureFlags
    }
    
    // MARK: - Configuration Validation
    public func validateConfiguration() async throws -> ValidationResult {
        return try await configurationValidator.validate(configuration)
    }
    
    public func getConfigurationSchema() -> ConfigurationSchema {
        return configurationValidator.getSchema()
    }
    
    // MARK: - Configuration Versioning
    public func getConfigurationVersion() -> String {
        return configuration.version
    }
    
    public func rollbackConfiguration() async throws {
        guard let previousConfiguration = await secureStorage.getPreviousConfiguration(for: currentEnvironment) else {
            throw ConfigurationError.noPreviousVersion
        }
        
        configuration = previousConfiguration
        try await secureStorage.saveConfiguration(configuration, for: currentEnvironment)
    }
    
    // MARK: - Dynamic Configuration Updates
    public func refreshConfiguration() async throws {
        let updatedConfiguration = try await configurationLoader.loadConfiguration(for: currentEnvironment)
        
        // Validate configuration
        try configurationValidator.validate(updatedConfiguration)
        
        // Update configuration
        configuration = updatedConfiguration
        
        // Save to secure storage
        try await secureStorage.saveConfiguration(configuration, for: currentEnvironment)
    }
    
    // MARK: - Configuration Export/Import
    public func exportConfiguration() async throws -> Data {
        let exportData = ConfigurationExport(
            environment: currentEnvironment,
            configuration: configuration,
            featureFlags: featureFlags,
            exportDate: Date()
        )
        
        return try JSONEncoder().encode(exportData)
    }
    
    public func importConfiguration(_ data: Data) async throws {
        let importData = try JSONDecoder().decode(ConfigurationExport.self, from: data)
        
        // Validate imported configuration
        try configurationValidator.validate(importData.configuration)
        
        // Update configuration
        currentEnvironment = importData.environment
        configuration = importData.configuration
        featureFlags = importData.featureFlags
        
        // Save to secure storage
        try await secureStorage.saveConfiguration(configuration, for: currentEnvironment)
        try await featureFlagManager.saveFeatureFlags(featureFlags, for: currentEnvironment)
    }
    
    // MARK: - Private Methods
    private func loadConfiguration() {
        Task {
            do {
                // Try to load from secure storage first
                if let savedConfiguration = await secureStorage.getConfiguration(for: currentEnvironment) {
                    configuration = savedConfiguration
                } else {
                    // Load default configuration
                    configuration = try await configurationLoader.loadConfiguration(for: currentEnvironment)
                    try await secureStorage.saveConfiguration(configuration, for: currentEnvironment)
                }
                
                // Load feature flags
                featureFlags = try await featureFlagManager.loadFeatureFlags(for: currentEnvironment)
            } catch {
                self.error = error.localizedDescription
            }
        }
    }
}

// MARK: - Supporting Models
public enum Environment: String, CaseIterable, Codable {
    case development = "development"
    case staging = "staging"
    case production = "production"
    case testing = "testing"
    
    public var displayName: String {
        switch self {
        case .development: return "Development"
        case .staging: return "Staging"
        case .production: return "Production"
        case .testing: return "Testing"
        }
    }
}

public struct AppConfiguration: Codable {
    public let version: String
    public let environment: Environment
    public let apiConfiguration: APIConfiguration
    public let databaseConfiguration: DatabaseConfiguration
    public let securityConfiguration: SecurityConfiguration
    public let analyticsConfiguration: AnalyticsConfiguration
    public let customSettings: [String: Any]
    
    public init(
        version: String,
        environment: Environment,
        apiConfiguration: APIConfiguration,
        databaseConfiguration: DatabaseConfiguration,
        securityConfiguration: SecurityConfiguration,
        analyticsConfiguration: AnalyticsConfiguration,
        customSettings: [String: Any] = [:]
    ) {
        self.version = version
        self.environment = environment
        self.apiConfiguration = apiConfiguration
        self.databaseConfiguration = databaseConfiguration
        self.securityConfiguration = securityConfiguration
        self.analyticsConfiguration = analyticsConfiguration
        self.customSettings = customSettings
    }
    
    public static var `default`: AppConfiguration {
        return AppConfiguration(
            version: "1.0.0",
            environment: .development,
            apiConfiguration: APIConfiguration.default,
            databaseConfiguration: DatabaseConfiguration.default,
            securityConfiguration: SecurityConfiguration.default,
            analyticsConfiguration: AnalyticsConfiguration.default
        )
    }
    
    public func getValue<T>(for key: ConfigurationKey) -> T? {
        switch key {
        case .apiBaseURL:
            return apiConfiguration.baseURL as? T
        case .apiTimeout:
            return apiConfiguration.timeout as? T
        case .databaseURL:
            return databaseConfiguration.url as? T
        case .encryptionEnabled:
            return securityConfiguration.encryptionEnabled as? T
        case .analyticsEnabled:
            return analyticsConfiguration.enabled as? T
        case .custom(let customKey):
            return customSettings[customKey] as? T
        }
    }
    
    public mutating func setValue<T>(_ value: T, for key: ConfigurationKey) {
        switch key {
        case .custom(let customKey):
            var settings = customSettings
            settings[customKey] = value
            // Note: This is a simplified implementation
            // In a real implementation, you'd need to handle the mutability properly
        default:
            // Handle other cases as needed
            break
        }
    }
}

public enum ConfigurationKey {
    case apiBaseURL
    case apiTimeout
    case databaseURL
    case encryptionEnabled
    case analyticsEnabled
    case custom(String)
}

public struct APIConfiguration: Codable {
    public let baseURL: String
    public let timeout: TimeInterval
    public let retryCount: Int
    public let apiKey: String?
    
    public static var `default`: APIConfiguration {
        return APIConfiguration(
            baseURL: "https://api.healthai2030.com",
            timeout: 30.0,
            retryCount: 3,
            apiKey: nil
        )
    }
}

public struct DatabaseConfiguration: Codable {
    public let url: String
    public let maxConnections: Int
    public let timeout: TimeInterval
    
    public static var `default`: DatabaseConfiguration {
        return DatabaseConfiguration(
            url: "sqlite:///healthai2030.db",
            maxConnections: 10,
            timeout: 5.0
        )
    }
}

public struct SecurityConfiguration: Codable {
    public let encryptionEnabled: Bool
    public let encryptionKey: String?
    public let certificatePinning: Bool
    
    public static var `default`: SecurityConfiguration {
        return SecurityConfiguration(
            encryptionEnabled: true,
            encryptionKey: nil,
            certificatePinning: true
        )
    }
}

public struct AnalyticsConfiguration: Codable {
    public let enabled: Bool
    public let endpoint: String
    public let batchSize: Int
    
    public static var `default`: AnalyticsConfiguration {
        return AnalyticsConfiguration(
            enabled: true,
            endpoint: "https://analytics.healthai2030.com",
            batchSize: 100
        )
    }
}

public struct FeatureFlag: Codable {
    public let name: String
    public let isEnabled: Bool
    public let rolloutPercentage: Int
    public let targetUsers: [String]
    public let environment: Environment
}

public struct ValidationResult {
    public let isValid: Bool
    public let errors: [String]
    public let warnings: [String]
}

public struct ConfigurationSchema {
    public let requiredFields: [String]
    public let optionalFields: [String]
    public let fieldTypes: [String: String]
}

public struct ConfigurationExport: Codable {
    public let environment: Environment
    public let configuration: AppConfiguration
    public let featureFlags: [String: FeatureFlag]
    public let exportDate: Date
}

public enum ConfigurationError: Error {
    case invalidConfiguration
    case environmentNotFound
    case noPreviousVersion
    case validationFailed
    case saveFailed
    case loadFailed
}

// MARK: - Supporting Classes
private class ConfigurationLoader {
    func loadConfiguration(for environment: Environment) async throws -> AppConfiguration {
        // Simulate loading configuration from different sources
        switch environment {
        case .development:
            return AppConfiguration(
                version: "1.0.0-dev",
                environment: .development,
                apiConfiguration: APIConfiguration(
                    baseURL: "https://dev-api.healthai2030.com",
                    timeout: 60.0,
                    retryCount: 5,
                    apiKey: "dev-key"
                ),
                databaseConfiguration: DatabaseConfiguration(
                    url: "sqlite:///dev-healthai2030.db",
                    maxConnections: 5,
                    timeout: 10.0
                ),
                securityConfiguration: SecurityConfiguration(
                    encryptionEnabled: false,
                    encryptionKey: nil,
                    certificatePinning: false
                ),
                analyticsConfiguration: AnalyticsConfiguration(
                    enabled: false,
                    endpoint: "https://dev-analytics.healthai2030.com",
                    batchSize: 50
                )
            )
        case .staging:
            return AppConfiguration(
                version: "1.0.0-staging",
                environment: .staging,
                apiConfiguration: APIConfiguration(
                    baseURL: "https://staging-api.healthai2030.com",
                    timeout: 45.0,
                    retryCount: 3,
                    apiKey: "staging-key"
                ),
                databaseConfiguration: DatabaseConfiguration(
                    url: "sqlite:///staging-healthai2030.db",
                    maxConnections: 8,
                    timeout: 7.0
                ),
                securityConfiguration: SecurityConfiguration(
                    encryptionEnabled: true,
                    encryptionKey: "staging-key",
                    certificatePinning: true
                ),
                analyticsConfiguration: AnalyticsConfiguration(
                    enabled: true,
                    endpoint: "https://staging-analytics.healthai2030.com",
                    batchSize: 75
                )
            )
        case .production:
            return AppConfiguration(
                version: "1.0.0",
                environment: .production,
                apiConfiguration: APIConfiguration(
                    baseURL: "https://api.healthai2030.com",
                    timeout: 30.0,
                    retryCount: 3,
                    apiKey: "prod-key"
                ),
                databaseConfiguration: DatabaseConfiguration(
                    url: "sqlite:///prod-healthai2030.db",
                    maxConnections: 20,
                    timeout: 5.0
                ),
                securityConfiguration: SecurityConfiguration(
                    encryptionEnabled: true,
                    encryptionKey: "prod-key",
                    certificatePinning: true
                ),
                analyticsConfiguration: AnalyticsConfiguration(
                    enabled: true,
                    endpoint: "https://analytics.healthai2030.com",
                    batchSize: 100
                )
            )
        case .testing:
            return AppConfiguration(
                version: "1.0.0-test",
                environment: .testing,
                apiConfiguration: APIConfiguration(
                    baseURL: "https://test-api.healthai2030.com",
                    timeout: 10.0,
                    retryCount: 1,
                    apiKey: "test-key"
                ),
                databaseConfiguration: DatabaseConfiguration(
                    url: "sqlite:///test-healthai2030.db",
                    maxConnections: 2,
                    timeout: 2.0
                ),
                securityConfiguration: SecurityConfiguration(
                    encryptionEnabled: false,
                    encryptionKey: nil,
                    certificatePinning: false
                ),
                analyticsConfiguration: AnalyticsConfiguration(
                    enabled: false,
                    endpoint: "https://test-analytics.healthai2030.com",
                    batchSize: 10
                )
            )
        }
    }
}

private class FeatureFlagManager {
    func loadFeatureFlags(for environment: Environment) async throws -> [String: FeatureFlag] {
        // Simulate loading feature flags
        return [
            "advanced_analytics": FeatureFlag(
                name: "advanced_analytics",
                isEnabled: environment == .production || environment == .staging,
                rolloutPercentage: 100,
                targetUsers: [],
                environment: environment
            ),
            "beta_features": FeatureFlag(
                name: "beta_features",
                isEnabled: environment == .development || environment == .staging,
                rolloutPercentage: 50,
                targetUsers: ["beta_users"],
                environment: environment
            ),
            "experimental_ml": FeatureFlag(
                name: "experimental_ml",
                isEnabled: environment == .development,
                rolloutPercentage: 25,
                targetUsers: ["ml_researchers"],
                environment: environment
            )
        ]
    }
    
    func saveFeatureFlags(_ flags: [String: FeatureFlag], for environment: Environment) async throws {
        // Simulate saving feature flags
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
    }
}

private class ConfigurationValidator {
    func validate(_ configuration: AppConfiguration) throws -> ValidationResult {
        var errors: [String] = []
        var warnings: [String] = []
        
        // Validate API configuration
        if configuration.apiConfiguration.baseURL.isEmpty {
            errors.append("API base URL cannot be empty")
        }
        
        if configuration.apiConfiguration.timeout <= 0 {
            errors.append("API timeout must be greater than 0")
        }
        
        // Validate database configuration
        if configuration.databaseConfiguration.url.isEmpty {
            errors.append("Database URL cannot be empty")
        }
        
        if configuration.databaseConfiguration.maxConnections <= 0 {
            errors.append("Database max connections must be greater than 0")
        }
        
        // Validate security configuration
        if configuration.securityConfiguration.encryptionEnabled && configuration.securityConfiguration.encryptionKey?.isEmpty != false {
            warnings.append("Encryption is enabled but no encryption key is provided")
        }
        
        return ValidationResult(
            isValid: errors.isEmpty,
            errors: errors,
            warnings: warnings
        )
    }
    
    func getSchema() -> ConfigurationSchema {
        return ConfigurationSchema(
            requiredFields: ["version", "environment", "apiConfiguration", "databaseConfiguration"],
            optionalFields: ["customSettings"],
            fieldTypes: [
                "version": "String",
                "environment": "Environment",
                "apiConfiguration": "APIConfiguration",
                "databaseConfiguration": "DatabaseConfiguration",
                "securityConfiguration": "SecurityConfiguration",
                "analyticsConfiguration": "AnalyticsConfiguration"
            ]
        )
    }
}

private class SecureConfigurationStorage {
    func saveConfiguration(_ configuration: AppConfiguration, for environment: Environment) async throws {
        // Simulate secure storage
        try await Task.sleep(nanoseconds: 50_000_000) // 0.05 seconds
    }
    
    func getConfiguration(for environment: Environment) async -> AppConfiguration? {
        // Simulate retrieving configuration
        return nil // Return nil to use default configuration
    }
    
    func getPreviousConfiguration(for environment: Environment) async -> AppConfiguration? {
        // Simulate retrieving previous configuration
        return nil
    }
} 
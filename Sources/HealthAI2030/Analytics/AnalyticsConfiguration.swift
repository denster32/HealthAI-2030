import Foundation
import Combine

/// Analytics Configuration - Configurable analytics settings
/// Agent 6 Deliverable: Day 1-3 Core Analytics Framework
public class AnalyticsConfiguration: ObservableObject {
    
    // MARK: - Configuration Properties
    
    @Published public var processingMode: ProcessingMode = .realTime
    @Published public var qualityThreshold: Double = 0.85
    @Published public var batchSize: Int = 1000
    @Published public var cachingEnabled: Bool = true
    @Published public var parallelProcessing: Bool = true
    @Published public var maxProcessingTime: TimeInterval = 30.0
    
    // Algorithm-specific configurations
    @Published public var anomalyDetectionSensitivity: Double = 0.95
    @Published public var patternRecognitionDepth: Int = 7
    @Published public var correlationThreshold: Double = 0.7
    @Published public var predictionHorizon: TimeInterval = 86400 // 24 hours
    
    // Performance configurations
    @Published public var memoryLimit: UInt64 = 1024 * 1024 * 1024 // 1GB
    @Published public var maxConcurrentTasks: Int = 4
    @Published public var retryAttempts: Int = 3
    @Published public var timeoutInterval: TimeInterval = 60.0
    
    // Data quality configurations
    @Published public var outlierDetectionEnabled: Bool = true
    @Published public var missingValueTolerance: Double = 0.1 // 10%
    @Published public var dataFreshnessThreshold: TimeInterval = 3600 // 1 hour
    
    // Privacy and security configurations
    @Published public var dataAnonymizationEnabled: Bool = true
    @Published public var encryptionEnabled: Bool = true
    @Published public var auditLoggingEnabled: Bool = true
    
    private let configurationFile = "analytics_config.json"
    private var configurationURL: URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documentsPath.appendingPathComponent(configurationFile)
    }
    
    // MARK: - Initialization
    
    public init() {
        loadConfiguration()
        setupDefaultValues()
    }
    
    // MARK: - Configuration Management
    
    /// Load configuration from persistent storage
    public func loadConfiguration() {
        do {
            if FileManager.default.fileExists(atPath: configurationURL.path) {
                let data = try Data(contentsOf: configurationURL)
                let config = try JSONDecoder().decode(AnalyticsConfigurationData.self, from: data)
                applyConfiguration(config)
            }
        } catch {
            print("Failed to load configuration: \(error)")
            setupDefaultValues()
        }
    }
    
    /// Save current configuration to persistent storage
    public func saveConfiguration() {
        do {
            let config = createConfigurationData()
            let data = try JSONEncoder().encode(config)
            try data.write(to: configurationURL)
        } catch {
            print("Failed to save configuration: \(error)")
        }
    }
    
    /// Reset configuration to default values
    public func resetToDefaults() {
        setupDefaultValues()
        saveConfiguration()
    }
    
    /// Update configuration with new values
    public func updateConfiguration(_ updates: [String: Any]) {
        for (key, value) in updates {
            switch key {
            case "processingMode":
                if let mode = value as? String,
                   let processingModeValue = ProcessingMode(rawValue: mode) {
                    processingMode = processingModeValue
                }
            case "qualityThreshold":
                if let threshold = value as? Double {
                    qualityThreshold = max(0.0, min(1.0, threshold))
                }
            case "batchSize":
                if let size = value as? Int {
                    batchSize = max(1, size)
                }
            case "anomalyDetectionSensitivity":
                if let sensitivity = value as? Double {
                    anomalyDetectionSensitivity = max(0.0, min(1.0, sensitivity))
                }
            default:
                break
            }
        }
        saveConfiguration()
    }
    
    /// Validate current configuration
    public func validateConfiguration() -> ConfigurationValidationResult {
        var issues: [String] = []
        
        // Validate thresholds
        if qualityThreshold < 0.0 || qualityThreshold > 1.0 {
            issues.append("Quality threshold must be between 0.0 and 1.0")
        }
        
        if anomalyDetectionSensitivity < 0.0 || anomalyDetectionSensitivity > 1.0 {
            issues.append("Anomaly detection sensitivity must be between 0.0 and 1.0")
        }
        
        if correlationThreshold < 0.0 || correlationThreshold > 1.0 {
            issues.append("Correlation threshold must be between 0.0 and 1.0")
        }
        
        // Validate performance settings
        if batchSize <= 0 {
            issues.append("Batch size must be greater than 0")
        }
        
        if maxConcurrentTasks <= 0 {
            issues.append("Max concurrent tasks must be greater than 0")
        }
        
        if maxProcessingTime <= 0 {
            issues.append("Max processing time must be greater than 0")
        }
        
        return ConfigurationValidationResult(
            isValid: issues.isEmpty,
            issues: issues
        )
    }
    
    /// Get configuration for specific analytics component
    public func getConfiguration(for component: AnalyticsComponent) -> ComponentConfiguration {
        switch component {
        case .anomalyDetection:
            return ComponentConfiguration(
                enabled: true,
                sensitivity: anomalyDetectionSensitivity,
                parameters: [
                    "threshold": anomalyDetectionSensitivity,
                    "window_size": patternRecognitionDepth
                ]
            )
        case .patternRecognition:
            return ComponentConfiguration(
                enabled: true,
                sensitivity: 0.8,
                parameters: [
                    "depth": patternRecognitionDepth,
                    "min_pattern_length": 3
                ]
            )
        case .correlation:
            return ComponentConfiguration(
                enabled: true,
                sensitivity: correlationThreshold,
                parameters: [
                    "threshold": correlationThreshold,
                    "method": "pearson"
                ]
            )
        case .prediction:
            return ComponentConfiguration(
                enabled: true,
                sensitivity: 0.9,
                parameters: [
                    "horizon_hours": predictionHorizon / 3600,
                    "confidence_level": 0.95
                ]
            )
        }
    }
    
    // MARK: - Private Methods
    
    private func setupDefaultValues() {
        processingMode = .realTime
        qualityThreshold = 0.85
        batchSize = 1000
        cachingEnabled = true
        parallelProcessing = true
        maxProcessingTime = 30.0
        anomalyDetectionSensitivity = 0.95
        patternRecognitionDepth = 7
        correlationThreshold = 0.7
        predictionHorizon = 86400
        memoryLimit = 1024 * 1024 * 1024
        maxConcurrentTasks = 4
        retryAttempts = 3
        timeoutInterval = 60.0
        outlierDetectionEnabled = true
        missingValueTolerance = 0.1
        dataFreshnessThreshold = 3600
        dataAnonymizationEnabled = true
        encryptionEnabled = true
        auditLoggingEnabled = true
    }
    
    private func applyConfiguration(_ config: AnalyticsConfigurationData) {
        processingMode = config.processingMode
        qualityThreshold = config.qualityThreshold
        batchSize = config.batchSize
        cachingEnabled = config.cachingEnabled
        parallelProcessing = config.parallelProcessing
        maxProcessingTime = config.maxProcessingTime
        anomalyDetectionSensitivity = config.anomalyDetectionSensitivity
        patternRecognitionDepth = config.patternRecognitionDepth
        correlationThreshold = config.correlationThreshold
        predictionHorizon = config.predictionHorizon
        memoryLimit = config.memoryLimit
        maxConcurrentTasks = config.maxConcurrentTasks
        retryAttempts = config.retryAttempts
        timeoutInterval = config.timeoutInterval
        outlierDetectionEnabled = config.outlierDetectionEnabled
        missingValueTolerance = config.missingValueTolerance
        dataFreshnessThreshold = config.dataFreshnessThreshold
        dataAnonymizationEnabled = config.dataAnonymizationEnabled
        encryptionEnabled = config.encryptionEnabled
        auditLoggingEnabled = config.auditLoggingEnabled
    }
    
    private func createConfigurationData() -> AnalyticsConfigurationData {
        return AnalyticsConfigurationData(
            processingMode: processingMode,
            qualityThreshold: qualityThreshold,
            batchSize: batchSize,
            cachingEnabled: cachingEnabled,
            parallelProcessing: parallelProcessing,
            maxProcessingTime: maxProcessingTime,
            anomalyDetectionSensitivity: anomalyDetectionSensitivity,
            patternRecognitionDepth: patternRecognitionDepth,
            correlationThreshold: correlationThreshold,
            predictionHorizon: predictionHorizon,
            memoryLimit: memoryLimit,
            maxConcurrentTasks: maxConcurrentTasks,
            retryAttempts: retryAttempts,
            timeoutInterval: timeoutInterval,
            outlierDetectionEnabled: outlierDetectionEnabled,
            missingValueTolerance: missingValueTolerance,
            dataFreshnessThreshold: dataFreshnessThreshold,
            dataAnonymizationEnabled: dataAnonymizationEnabled,
            encryptionEnabled: encryptionEnabled,
            auditLoggingEnabled: auditLoggingEnabled
        )
    }
}

// MARK: - Supporting Types

public enum ProcessingMode: String, Codable, CaseIterable {
    case realTime = "realTime"
    case batch = "batch"
    case hybrid = "hybrid"
    case onDemand = "onDemand"
    
    public var displayName: String {
        switch self {
        case .realTime: return "Real-time Processing"
        case .batch: return "Batch Processing"
        case .hybrid: return "Hybrid Processing"
        case .onDemand: return "On-demand Processing"
        }
    }
}

public enum AnalyticsComponent: String, CaseIterable {
    case anomalyDetection = "anomalyDetection"
    case patternRecognition = "patternRecognition"
    case correlation = "correlation"
    case prediction = "prediction"
    
    public var displayName: String {
        switch self {
        case .anomalyDetection: return "Anomaly Detection"
        case .patternRecognition: return "Pattern Recognition"
        case .correlation: return "Correlation Analysis"
        case .prediction: return "Predictive Analytics"
        }
    }
}

public struct ComponentConfiguration {
    public let enabled: Bool
    public let sensitivity: Double
    public let parameters: [String: Any]
    
    public init(enabled: Bool, sensitivity: Double, parameters: [String: Any]) {
        self.enabled = enabled
        self.sensitivity = sensitivity
        self.parameters = parameters
    }
}

public struct ConfigurationValidationResult {
    public let isValid: Bool
    public let issues: [String]
    
    public init(isValid: Bool, issues: [String]) {
        self.isValid = isValid
        self.issues = issues
    }
}

public struct AnalyticsConfigurationData: Codable {
    let processingMode: ProcessingMode
    let qualityThreshold: Double
    let batchSize: Int
    let cachingEnabled: Bool
    let parallelProcessing: Bool
    let maxProcessingTime: TimeInterval
    let anomalyDetectionSensitivity: Double
    let patternRecognitionDepth: Int
    let correlationThreshold: Double
    let predictionHorizon: TimeInterval
    let memoryLimit: UInt64
    let maxConcurrentTasks: Int
    let retryAttempts: Int
    let timeoutInterval: TimeInterval
    let outlierDetectionEnabled: Bool
    let missingValueTolerance: Double
    let dataFreshnessThreshold: TimeInterval
    let dataAnonymizationEnabled: Bool
    let encryptionEnabled: Bool
    let auditLoggingEnabled: Bool
}

// MARK: - Configuration Extensions

extension AnalyticsConfiguration {
    
    /// Get optimal configuration for different use cases
    public static func optimizedConfiguration(for useCase: AnalyticsUseCase) -> AnalyticsConfiguration {
        let config = AnalyticsConfiguration()
        
        switch useCase {
        case .realTimeMonitoring:
            config.processingMode = .realTime
            config.batchSize = 100
            config.maxProcessingTime = 5.0
            config.anomalyDetectionSensitivity = 0.98
            
        case .historicalAnalysis:
            config.processingMode = .batch
            config.batchSize = 10000
            config.maxProcessingTime = 300.0
            config.patternRecognitionDepth = 30
            
        case .predictiveModeling:
            config.processingMode = .hybrid
            config.batchSize = 5000
            config.predictionHorizon = 604800 // 7 days
            config.correlationThreshold = 0.8
            
        case .emergencyDetection:
            config.processingMode = .realTime
            config.batchSize = 50
            config.maxProcessingTime = 1.0
            config.anomalyDetectionSensitivity = 0.99
            config.qualityThreshold = 0.95
        }
        
        return config
    }
}

public enum AnalyticsUseCase: String, CaseIterable {
    case realTimeMonitoring = "realTimeMonitoring"
    case historicalAnalysis = "historicalAnalysis"
    case predictiveModeling = "predictiveModeling"
    case emergencyDetection = "emergencyDetection"
    
    public var displayName: String {
        switch self {
        case .realTimeMonitoring: return "Real-time Monitoring"
        case .historicalAnalysis: return "Historical Analysis"
        case .predictiveModeling: return "Predictive Modeling"
        case .emergencyDetection: return "Emergency Detection"
        }
    }
}

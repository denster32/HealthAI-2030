import Foundation

/**
 * MLDataStructures
 * 
 * Data structures for machine learning training and results in HealthAI2030.
 * Extracted from MLPredictiveModels.swift for better maintainability.
 * 
 * This module contains:
 * - Training data containers
 * - Result structures
 * - Feature definitions
 * - Data validation utilities
 * 
 * ## Benefits of Separation
 * - Clear data contracts: Well-defined interfaces for ML data
 * - Type safety: Strong typing for health data structures
 * - Validation: Built-in data integrity checks
 * - Serialization: Efficient data persistence and transfer
 * 
 * - Author: HealthAI2030 Team
 * - Version: 2.0 (Refactored from MLPredictiveModels v1.0)
 * - Since: iOS 18.0, macOS 15.0, watchOS 11.0, tvOS 18.0, visionOS 2.0
 */

@available(iOS 18.0, macOS 15.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
public struct HealthTrainingData: Codable, Sendable {
    /// Unique identifier for this training dataset
    public let id: UUID
    
    /// Feature matrix (samples x features)
    public let features: [[Double]]
    
    /// Target values corresponding to features
    public let targets: [Double]
    
    /// Feature names for interpretability
    public let featureNames: [String]
    
    /// Data collection timestamp
    public let timestamp: Date
    
    /// Health domain this data belongs to
    public let healthDomain: HealthDomain
    
    /// Data quality metrics
    public let qualityMetrics: DataQualityMetrics
    
    /// Privacy protection level
    public let privacyLevel: PrivacyLevel
    
    public init(
        id: UUID = UUID(),
        features: [[Double]],
        targets: [Double],
        featureNames: [String],
        timestamp: Date = Date(),
        healthDomain: HealthDomain,
        qualityMetrics: DataQualityMetrics,
        privacyLevel: PrivacyLevel = .high
    ) throws {
        // Validate data consistency
        guard features.count == targets.count else {
            throw MLDataError.inconsistentDataSize(
                featuresCount: features.count,
                targetsCount: targets.count
            )
        }
        
        guard !features.isEmpty else {
            throw MLDataError.emptyDataset
        }
        
        let featureCount = features.first?.count ?? 0
        guard features.allSatisfy({ $0.count == featureCount }) else {
            throw MLDataError.inconsistentFeatureSize
        }
        
        guard featureNames.count == featureCount else {
            throw MLDataError.featureNameMismatch(
                expected: featureCount,
                actual: featureNames.count
            )
        }
        
        self.id = id
        self.features = features
        self.targets = targets
        self.featureNames = featureNames
        self.timestamp = timestamp
        self.healthDomain = healthDomain
        self.qualityMetrics = qualityMetrics
        self.privacyLevel = privacyLevel
    }
    
    /// Number of samples in the dataset
    public var sampleCount: Int {
        features.count
    }
    
    /// Number of features per sample
    public var featureCount: Int {
        features.first?.count ?? 0
    }
    
    /// Statistical summary of the dataset
    public var summary: DataSummary {
        DataSummary(
            sampleCount: sampleCount,
            featureCount: featureCount,
            targetRange: (targets.min() ?? 0, targets.max() ?? 0),
            missingValueCount: calculateMissingValues(),
            dataQuality: qualityMetrics.overallScore
        )
    }
    
    private func calculateMissingValues() -> Int {
        features.flatMap { $0 }.count { $0.isNaN || $0.isInfinite }
    }
}

@available(iOS 18.0, macOS 15.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
public struct DataQualityMetrics: Codable, Sendable {
    /// Completeness score (0.0 - 1.0)
    public let completeness: Double
    
    /// Consistency score (0.0 - 1.0)
    public let consistency: Double
    
    /// Accuracy score (0.0 - 1.0)
    public let accuracy: Double
    
    /// Timeliness score (0.0 - 1.0)
    public let timeliness: Double
    
    /// Validity score (0.0 - 1.0)
    public let validity: Double
    
    public init(
        completeness: Double,
        consistency: Double,
        accuracy: Double,
        timeliness: Double,
        validity: Double
    ) {
        self.completeness = max(0.0, min(1.0, completeness))
        self.consistency = max(0.0, min(1.0, consistency))
        self.accuracy = max(0.0, min(1.0, accuracy))
        self.timeliness = max(0.0, min(1.0, timeliness))
        self.validity = max(0.0, min(1.0, validity))
    }
    
    /// Overall quality score (weighted average)
    public var overallScore: Double {
        let weights: [Double] = [0.25, 0.20, 0.25, 0.15, 0.15]
        let scores = [completeness, consistency, accuracy, timeliness, validity]
        return zip(weights, scores).map(*).reduce(0, +)
    }
    
    /// Quality level assessment
    public var qualityLevel: DataQualityLevel {
        switch overallScore {
        case 0.9...1.0: return .excellent
        case 0.8..<0.9: return .good
        case 0.7..<0.8: return .acceptable
        case 0.5..<0.7: return .poor
        default: return .unacceptable
        }
    }
}

@available(iOS 18.0, macOS 15.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
public enum DataQualityLevel: String, Codable, CaseIterable {
    case excellent = "excellent"
    case good = "good"
    case acceptable = "acceptable"
    case poor = "poor"
    case unacceptable = "unacceptable"
    
    /// Minimum quality threshold for production use
    public static let minimumProduction: DataQualityLevel = .acceptable
    
    /// Recommended quality threshold for critical health predictions
    public static let recommendedCritical: DataQualityLevel = .good
}

@available(iOS 18.0, macOS 15.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
public enum PrivacyLevel: String, Codable, CaseIterable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case critical = "critical"
    
    /// Encryption requirements for this privacy level
    public var encryptionRequired: Bool {
        switch self {
        case .low: return false
        case .medium, .high, .critical: return true
        }
    }
    
    /// Differential privacy requirements
    public var differentialPrivacyRequired: Bool {
        switch self {
        case .low, .medium: return false
        case .high, .critical: return true
        }
    }
}

@available(iOS 18.0, macOS 15.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
public struct DataSummary: Codable, Sendable {
    public let sampleCount: Int
    public let featureCount: Int
    public let targetRange: (min: Double, max: Double)
    public let missingValueCount: Int
    public let dataQuality: Double
    
    public init(
        sampleCount: Int,
        featureCount: Int,
        targetRange: (Double, Double),
        missingValueCount: Int,
        dataQuality: Double
    ) {
        self.sampleCount = sampleCount
        self.featureCount = featureCount
        self.targetRange = targetRange
        self.missingValueCount = missingValueCount
        self.dataQuality = dataQuality
    }
}

@available(iOS 18.0, macOS 15.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
public struct MLPredictionResult: Codable, Sendable {
    /// Unique identifier for this prediction
    public let id: UUID
    
    /// Predicted values
    public let predictions: [Double]
    
    /// Confidence scores for predictions (0.0 - 1.0)
    public let confidenceScores: [Double]
    
    /// Model used for prediction
    public let modelType: MLModelType
    
    /// Health domain of the prediction
    public let healthDomain: HealthDomain
    
    /// Timestamp when prediction was made
    public let timestamp: Date
    
    /// Explanation for the prediction (if explainable AI is enabled)
    public let explanation: PredictionExplanation?
    
    /// Performance metrics for this prediction
    public let performanceMetrics: PredictionPerformanceMetrics
    
    public init(
        id: UUID = UUID(),
        predictions: [Double],
        confidenceScores: [Double],
        modelType: MLModelType,
        healthDomain: HealthDomain,
        timestamp: Date = Date(),
        explanation: PredictionExplanation? = nil,
        performanceMetrics: PredictionPerformanceMetrics
    ) throws {
        guard predictions.count == confidenceScores.count else {
            throw MLDataError.inconsistentPredictionSize(
                predictionsCount: predictions.count,
                confidenceCount: confidenceScores.count
            )
        }
        
        guard confidenceScores.allSatisfy({ $0 >= 0.0 && $0 <= 1.0 }) else {
            throw MLDataError.invalidConfidenceScore
        }
        
        self.id = id
        self.predictions = predictions
        self.confidenceScores = confidenceScores
        self.modelType = modelType
        self.healthDomain = healthDomain
        self.timestamp = timestamp
        self.explanation = explanation
        self.performanceMetrics = performanceMetrics
    }
    
    /// Average confidence score across all predictions
    public var averageConfidence: Double {
        confidenceScores.isEmpty ? 0.0 : confidenceScores.reduce(0, +) / Double(confidenceScores.count)
    }
    
    /// Indicates if all predictions meet the confidence threshold
    public func meetsConfidenceThreshold(_ threshold: Double) -> Bool {
        confidenceScores.allSatisfy { $0 >= threshold }
    }
}

@available(iOS 18.0, macOS 15.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
public struct PredictionExplanation: Codable, Sendable {
    /// Feature importance scores
    public let featureImportance: [String: Double]
    
    /// Decision path (for tree-based models)
    public let decisionPath: [DecisionNode]?
    
    /// Attention weights (for neural networks)
    public let attentionWeights: [Double]?
    
    /// SHAP values for feature attribution
    public let shapValues: [Double]?
    
    /// Human-readable explanation
    public let textualExplanation: String
    
    public init(
        featureImportance: [String: Double],
        decisionPath: [DecisionNode]? = nil,
        attentionWeights: [Double]? = nil,
        shapValues: [Double]? = nil,
        textualExplanation: String
    ) {
        self.featureImportance = featureImportance
        self.decisionPath = decisionPath
        self.attentionWeights = attentionWeights
        self.shapValues = shapValues
        self.textualExplanation = textualExplanation
    }
}

@available(iOS 18.0, macOS 15.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
public struct DecisionNode: Codable, Sendable {
    public let featureName: String
    public let threshold: Double
    public let condition: String
    public let sampleCount: Int
    
    public init(featureName: String, threshold: Double, condition: String, sampleCount: Int) {
        self.featureName = featureName
        self.threshold = threshold
        self.condition = condition
        self.sampleCount = sampleCount
    }
}

@available(iOS 18.0, macOS 15.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
public struct PredictionPerformanceMetrics: Codable, Sendable {
    /// Inference time in milliseconds
    public let inferenceTime: Double
    
    /// Memory usage in MB
    public let memoryUsage: Double
    
    /// CPU utilization percentage
    public let cpuUtilization: Double
    
    /// GPU utilization percentage (if applicable)
    public let gpuUtilization: Double?
    
    /// Battery impact score (0.0 - 1.0)
    public let batteryImpact: Double
    
    public init(
        inferenceTime: Double,
        memoryUsage: Double,
        cpuUtilization: Double,
        gpuUtilization: Double? = nil,
        batteryImpact: Double
    ) {
        self.inferenceTime = inferenceTime
        self.memoryUsage = memoryUsage
        self.cpuUtilization = max(0.0, min(100.0, cpuUtilization))
        self.gpuUtilization = gpuUtilization.map { max(0.0, min(100.0, $0)) }
        self.batteryImpact = max(0.0, min(1.0, batteryImpact))
    }
    
    /// Overall performance score (higher is better)
    public var performanceScore: Double {
        let timeScore = max(0.0, 1.0 - (inferenceTime / 1000.0)) // Normalize to seconds
        let memoryScore = max(0.0, 1.0 - (memoryUsage / 1000.0)) // Normalize to GB
        let cpuScore = max(0.0, 1.0 - (cpuUtilization / 100.0))
        let batteryScore = 1.0 - batteryImpact
        
        return (timeScore + memoryScore + cpuScore + batteryScore) / 4.0
    }
}

@available(iOS 18.0, macOS 15.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
public enum MLDataError: Error, LocalizedError {
    case inconsistentDataSize(featuresCount: Int, targetsCount: Int)
    case inconsistentPredictionSize(predictionsCount: Int, confidenceCount: Int)
    case inconsistentFeatureSize
    case featureNameMismatch(expected: Int, actual: Int)
    case emptyDataset
    case invalidConfidenceScore
    case insufficientDataQuality(current: Double, required: Double)
    case privacyViolation(level: PrivacyLevel, requirement: String)
    
    public var errorDescription: String? {
        switch self {
        case .inconsistentDataSize(let featuresCount, let targetsCount):
            return "Inconsistent data size: \(featuresCount) features vs \(targetsCount) targets"
        case .inconsistentPredictionSize(let predictionsCount, let confidenceCount):
            return "Inconsistent prediction size: \(predictionsCount) predictions vs \(confidenceCount) confidence scores"
        case .inconsistentFeatureSize:
            return "All feature vectors must have the same dimension"
        case .featureNameMismatch(let expected, let actual):
            return "Feature name count mismatch: expected \(expected), got \(actual)"
        case .emptyDataset:
            return "Dataset cannot be empty"
        case .invalidConfidenceScore:
            return "Confidence scores must be between 0.0 and 1.0"
        case .insufficientDataQuality(let current, let required):
            return "Insufficient data quality: \(current) < \(required)"
        case .privacyViolation(let level, let requirement):
            return "Privacy violation for level \(level.rawValue): \(requirement)"
        }
    }
}

@available(iOS 18.0, macOS 15.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
public struct FeatureDefinition: Codable, Sendable {
    /// Feature name
    public let name: String
    
    /// Data type of the feature
    public let dataType: FeatureDataType
    
    /// Feature category
    public let category: FeatureCategory
    
    /// Value range for numeric features
    public let valueRange: (min: Double, max: Double)?
    
    /// Possible values for categorical features
    public let possibleValues: [String]?
    
    /// Whether this feature is required
    public let isRequired: Bool
    
    /// Privacy sensitivity level
    public let privacyLevel: PrivacyLevel
    
    /// Description of the feature
    public let description: String
    
    public init(
        name: String,
        dataType: FeatureDataType,
        category: FeatureCategory,
        valueRange: (Double, Double)? = nil,
        possibleValues: [String]? = nil,
        isRequired: Bool = true,
        privacyLevel: PrivacyLevel = .medium,
        description: String
    ) {
        self.name = name
        self.dataType = dataType
        self.category = category
        self.valueRange = valueRange
        self.possibleValues = possibleValues
        self.isRequired = isRequired
        self.privacyLevel = privacyLevel
        self.description = description
    }
}

@available(iOS 18.0, macOS 15.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
public enum FeatureDataType: String, Codable, CaseIterable {
    case numeric = "numeric"
    case categorical = "categorical"
    case binary = "binary"
    case temporal = "temporal"
    case text = "text"
    case image = "image"
    case timeSeries = "time_series"
}

@available(iOS 18.0, macOS 15.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
public enum FeatureCategory: String, Codable, CaseIterable {
    case physiological = "physiological"
    case behavioral = "behavioral"
    case environmental = "environmental"
    case demographic = "demographic"
    case clinical = "clinical"
    case device = "device"
    case derived = "derived"
    
    /// Privacy sensitivity for this category
    public var privacyLevel: PrivacyLevel {
        switch self {
        case .physiological, .clinical: return .critical
        case .behavioral, .demographic: return .high
        case .environmental, .device: return .medium
        case .derived: return .medium
        }
    }
}
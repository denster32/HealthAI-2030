import Foundation

/**
 * MLCoreTypes
 * 
 * Core machine learning types and configurations for HealthAI2030.
 * Extracted from MLPredictiveModels.swift for better maintainability.
 * 
 * This module contains the fundamental types used across the ML pipeline:
 * - Model type definitions
 * - Configuration structures  
 * - Performance metrics
 * - Result containers
 * 
 * ## Benefits of Separation
 * - Single responsibility: Only type definitions
 * - Easier testing: Types can be tested in isolation
 * - Better imports: Dependent modules only import what they need
 * - Reduced compilation time: Smaller files compile faster
 * 
 * - Author: HealthAI2030 Team
 * - Version: 2.0 (Refactored from MLPredictiveModels v1.0)
 * - Since: iOS 18.0, macOS 15.0, watchOS 11.0, tvOS 18.0, visionOS 2.0
 */
@available(iOS 18.0, macOS 15.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
public enum MLModelType: String, CaseIterable, Codable {
    case linearRegression = "linear_regression"
    case logisticRegression = "logistic_regression"
    case randomForest = "random_forest"
    case gradientBoosting = "gradient_boosting"
    case neuralNetwork = "neural_network"
    case supportVectorMachine = "svm"
    case naiveBayes = "naive_bayes"
    case kMeansClustering = "kmeans"
    case hierarchicalClustering = "hierarchical"
    case deepLearning = "deep_learning"
    case transformerModel = "transformer"
    case ensembleModel = "ensemble"
    
    /// Human-readable name for the model type
    public var displayName: String {
        switch self {
        case .linearRegression: return "Linear Regression"
        case .logisticRegression: return "Logistic Regression"
        case .randomForest: return "Random Forest"
        case .gradientBoosting: return "Gradient Boosting"
        case .neuralNetwork: return "Neural Network"
        case .supportVectorMachine: return "Support Vector Machine"
        case .naiveBayes: return "Naive Bayes"
        case .kMeansClustering: return "K-Means Clustering"
        case .hierarchicalClustering: return "Hierarchical Clustering"
        case .deepLearning: return "Deep Learning"
        case .transformerModel: return "Transformer"
        case .ensembleModel: return "Ensemble"
        }
    }
    
    /// Indicates if this model type supports supervised learning
    public var isSupervised: Bool {
        switch self {
        case .linearRegression, .logisticRegression, .randomForest, 
             .gradientBoosting, .neuralNetwork, .supportVectorMachine, 
             .naiveBayes, .deepLearning, .transformerModel, .ensembleModel:
            return true
        case .kMeansClustering, .hierarchicalClustering:
            return false
        }
    }
    
    /// Indicates if this model type is suitable for health predictions
    public var isHealthOptimized: Bool {
        switch self {
        case .randomForest, .gradientBoosting, .neuralNetwork, 
             .deepLearning, .transformerModel, .ensembleModel:
            return true
        default:
            return false
        }
    }
}

@available(iOS 18.0, macOS 15.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
public struct MLConfiguration: Codable {
    /// Unique identifier for this configuration
    public let id: UUID
    
    /// Model type to use
    public let modelType: MLModelType
    
    /// Training parameters
    public let trainingParameters: TrainingParameters
    
    /// Validation strategy
    public let validationStrategy: ValidationStrategy
    
    /// Feature engineering settings
    public let featureEngineering: FeatureEngineering
    
    /// Performance requirements
    public let performanceRequirements: PerformanceRequirements
    
    /// Health-specific settings
    public let healthSettings: HealthMLSettings
    
    public init(
        id: UUID = UUID(),
        modelType: MLModelType,
        trainingParameters: TrainingParameters = .default,
        validationStrategy: ValidationStrategy = .crossValidation(folds: 5),
        featureEngineering: FeatureEngineering = .default,
        performanceRequirements: PerformanceRequirements = .default,
        healthSettings: HealthMLSettings = .default
    ) {
        self.id = id
        self.modelType = modelType
        self.trainingParameters = trainingParameters
        self.validationStrategy = validationStrategy
        self.featureEngineering = featureEngineering
        self.performanceRequirements = performanceRequirements
        self.healthSettings = healthSettings
    }
}

@available(iOS 18.0, macOS 15.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
public struct TrainingParameters: Codable {
    /// Learning rate for gradient-based algorithms
    public let learningRate: Double
    
    /// Maximum number of training iterations
    public let maxIterations: Int
    
    /// Batch size for training
    public let batchSize: Int
    
    /// Regularization strength
    public let regularization: Double
    
    /// Early stopping patience
    public let earlyStopping: Int?
    
    /// Random seed for reproducibility
    public let randomSeed: Int
    
    public static let `default` = TrainingParameters(
        learningRate: 0.001,
        maxIterations: 1000,
        batchSize: 32,
        regularization: 0.01,
        earlyStopping: 50,
        randomSeed: 42
    )
    
    public init(
        learningRate: Double,
        maxIterations: Int,
        batchSize: Int,
        regularization: Double,
        earlyStopping: Int?,
        randomSeed: Int
    ) {
        self.learningRate = learningRate
        self.maxIterations = maxIterations
        self.batchSize = batchSize
        self.regularization = regularization
        self.earlyStopping = earlyStopping
        self.randomSeed = randomSeed
    }
}

@available(iOS 18.0, macOS 15.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
public enum ValidationStrategy: Codable {
    case holdOut(testSize: Double)
    case crossValidation(folds: Int)
    case timeSeriesSplit(testSize: Double)
    case stratifiedSplit(testSize: Double)
    
    /// Default validation strategy for health data
    public static let `default` = ValidationStrategy.crossValidation(folds: 5)
    
    /// Recommended strategy for time-series health data
    public static let timeSeries = ValidationStrategy.timeSeriesSplit(testSize: 0.2)
}

@available(iOS 18.0, macOS 15.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
public struct FeatureEngineering: Codable {
    /// Whether to normalize features
    public let normalizeFeatures: Bool
    
    /// Whether to apply feature selection
    public let featureSelection: Bool
    
    /// Maximum number of features to select
    public let maxFeatures: Int?
    
    /// Whether to create polynomial features
    public let polynomialFeatures: Bool
    
    /// Whether to handle missing values
    public let handleMissingValues: Bool
    
    /// Strategy for handling categorical variables
    public let categoricalEncoding: CategoricalEncoding
    
    public static let `default` = FeatureEngineering(
        normalizeFeatures: true,
        featureSelection: true,
        maxFeatures: 100,
        polynomialFeatures: false,
        handleMissingValues: true,
        categoricalEncoding: .oneHot
    )
    
    public init(
        normalizeFeatures: Bool,
        featureSelection: Bool,
        maxFeatures: Int?,
        polynomialFeatures: Bool,
        handleMissingValues: Bool,
        categoricalEncoding: CategoricalEncoding
    ) {
        self.normalizeFeatures = normalizeFeatures
        self.featureSelection = featureSelection
        self.maxFeatures = maxFeatures
        self.polynomialFeatures = polynomialFeatures
        self.handleMissingValues = handleMissingValues
        self.categoricalEncoding = categoricalEncoding
    }
}

@available(iOS 18.0, macOS 15.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
public enum CategoricalEncoding: String, Codable, CaseIterable {
    case oneHot = "one_hot"
    case labelEncoding = "label"
    case targetEncoding = "target"
    case binaryEncoding = "binary"
}

@available(iOS 18.0, macOS 15.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
public struct PerformanceRequirements: Codable {
    /// Minimum required accuracy (0.0 - 1.0)
    public let minimumAccuracy: Double
    
    /// Maximum allowed training time (seconds)
    public let maxTrainingTime: TimeInterval
    
    /// Maximum allowed inference time (milliseconds)
    public let maxInferenceTime: Double
    
    /// Maximum memory usage (MB)
    public let maxMemoryUsage: Double
    
    /// Required confidence threshold for predictions
    public let confidenceThreshold: Double
    
    public static let `default` = PerformanceRequirements(
        minimumAccuracy: 0.85,
        maxTrainingTime: 300, // 5 minutes
        maxInferenceTime: 50, // 50ms
        maxMemoryUsage: 500, // 500MB
        confidenceThreshold: 0.7
    )
    
    /// High-performance requirements for critical health predictions
    public static let highPerformance = PerformanceRequirements(
        minimumAccuracy: 0.95,
        maxTrainingTime: 600, // 10 minutes
        maxInferenceTime: 10, // 10ms
        maxMemoryUsage: 1000, // 1GB
        confidenceThreshold: 0.9
    )
    
    public init(
        minimumAccuracy: Double,
        maxTrainingTime: TimeInterval,
        maxInferenceTime: Double,
        maxMemoryUsage: Double,
        confidenceThreshold: Double
    ) {
        self.minimumAccuracy = minimumAccuracy
        self.maxTrainingTime = maxTrainingTime
        self.maxInferenceTime = maxInferenceTime
        self.maxMemoryUsage = maxMemoryUsage
        self.confidenceThreshold = confidenceThreshold
    }
}

@available(iOS 18.0, macOS 15.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
public struct HealthMLSettings: Codable {
    /// Whether this model handles sensitive health data
    public let handlesSensitiveData: Bool
    
    /// Required compliance standards
    public let complianceStandards: [ComplianceStandard]
    
    /// Whether to enable federated learning
    public let federatedLearning: Bool
    
    /// Whether to enable differential privacy
    public let differentialPrivacy: Bool
    
    /// Privacy budget for differential privacy
    public let privacyBudget: Double?
    
    /// Whether to enable explainable AI features
    public let explainableAI: Bool
    
    /// Target health domain
    public let healthDomain: HealthDomain
    
    public static let `default` = HealthMLSettings(
        handlesSensitiveData: true,
        complianceStandards: [.hipaa, .gdpr],
        federatedLearning: false,
        differentialPrivacy: false,
        privacyBudget: nil,
        explainableAI: true,
        healthDomain: .general
    )
    
    public init(
        handlesSensitiveData: Bool,
        complianceStandards: [ComplianceStandard],
        federatedLearning: Bool,
        differentialPrivacy: Bool,
        privacyBudget: Double?,
        explainableAI: Bool,
        healthDomain: HealthDomain
    ) {
        self.handlesSensitiveData = handlesSensitiveData
        self.complianceStandards = complianceStandards
        self.federatedLearning = federatedLearning
        self.differentialPrivacy = differentialPrivacy
        self.privacyBudget = privacyBudget
        self.explainableAI = explainableAI
        self.healthDomain = healthDomain
    }
}

@available(iOS 18.0, macOS 15.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
public enum ComplianceStandard: String, Codable, CaseIterable {
    case hipaa = "HIPAA"
    case gdpr = "GDPR"
    case sox = "SOX"
    case fda = "FDA"
    case ce = "CE"
    case iso27001 = "ISO27001"
}

@available(iOS 18.0, macOS 15.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
public enum HealthDomain: String, Codable, CaseIterable {
    case general = "general"
    case cardiology = "cardiology"
    case neurology = "neurology"
    case endocrinology = "endocrinology"
    case psychiatry = "psychiatry"
    case pulmonology = "pulmonology"
    case oncology = "oncology"
    case pediatrics = "pediatrics"
    case geriatrics = "geriatrics"
    case preventiveMedicine = "preventive_medicine"
    
    /// Human-readable display name
    public var displayName: String {
        switch self {
        case .general: return "General Health"
        case .cardiology: return "Cardiology"
        case .neurology: return "Neurology" 
        case .endocrinology: return "Endocrinology"
        case .psychiatry: return "Psychiatry"
        case .pulmonology: return "Pulmonology"
        case .oncology: return "Oncology"
        case .pediatrics: return "Pediatrics"
        case .geriatrics: return "Geriatrics"
        case .preventiveMedicine: return "Preventive Medicine"
        }
    }
    
    /// Recommended model types for this health domain
    public var recommendedModels: [MLModelType] {
        switch self {
        case .general:
            return [.randomForest, .gradientBoosting, .ensembleModel]
        case .cardiology:
            return [.neuralNetwork, .transformerModel, .ensembleModel]
        case .neurology:
            return [.deepLearning, .transformerModel, .neuralNetwork]
        case .endocrinology:
            return [.randomForest, .gradientBoosting, .neuralNetwork]
        case .psychiatry:
            return [.transformerModel, .neuralNetwork, .ensembleModel]
        case .pulmonology:
            return [.neuralNetwork, .randomForest, .gradientBoosting]
        case .oncology:
            return [.deepLearning, .ensembleModel, .transformerModel]
        case .pediatrics:
            return [.randomForest, .gradientBoosting, .neuralNetwork]
        case .geriatrics:
            return [.ensembleModel, .randomForest, .neuralNetwork]
        case .preventiveMedicine:
            return [.gradientBoosting, .randomForest, .ensembleModel]
        }
    }
}
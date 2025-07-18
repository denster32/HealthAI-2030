import Foundation

/**
 * MLPerformanceMetrics
 * 
 * Model evaluation and performance assessment tools for HealthAI2030.
 * Extracted from MLPredictiveModels.swift for better maintainability.
 * 
 * This module contains:
 * - Model evaluation metrics
 * - Performance benchmarking
 * - Health-specific validation
 * - Cross-validation utilities
 * 
 * ## Benefits of Separation
 * - Focused evaluation: Dedicated metrics calculation
 * - Health-optimized: Medical domain-specific metrics
 * - Reusable: Metrics can be used across different models
 * - Benchmarking: Consistent performance assessment
 * 
 * - Author: HealthAI2030 Team
 * - Version: 2.0 (Refactored from MLPredictiveModels v1.0)
 * - Since: iOS 18.0, macOS 15.0, watchOS 11.0, tvOS 18.0, visionOS 2.0
 */

@available(iOS 18.0, macOS 15.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
public struct ModelEvaluationMetrics: Codable, Sendable {
    /// Unique identifier for this evaluation
    public let id: UUID
    
    /// Model type that was evaluated
    public let modelType: MLModelType
    
    /// Health domain of the evaluation
    public let healthDomain: HealthDomain
    
    /// Evaluation timestamp
    public let timestamp: Date
    
    /// Classification metrics (for classification tasks)
    public let classificationMetrics: ClassificationMetrics?
    
    /// Regression metrics (for regression tasks)
    public let regressionMetrics: RegressionMetrics?
    
    /// Health-specific metrics
    public let healthMetrics: HealthSpecificMetrics
    
    /// Performance benchmarks
    public let performanceBenchmarks: PerformanceBenchmarks
    
    /// Cross-validation results
    public let crossValidationResults: CrossValidationResults?
    
    public init(
        id: UUID = UUID(),
        modelType: MLModelType,
        healthDomain: HealthDomain,
        timestamp: Date = Date(),
        classificationMetrics: ClassificationMetrics? = nil,
        regressionMetrics: RegressionMetrics? = nil,
        healthMetrics: HealthSpecificMetrics,
        performanceBenchmarks: PerformanceBenchmarks,
        crossValidationResults: CrossValidationResults? = nil
    ) {
        self.id = id
        self.modelType = modelType
        self.healthDomain = healthDomain
        self.timestamp = timestamp
        self.classificationMetrics = classificationMetrics
        self.regressionMetrics = regressionMetrics
        self.healthMetrics = healthMetrics
        self.performanceBenchmarks = performanceBenchmarks
        self.crossValidationResults = crossValidationResults
    }
    
    /// Overall model quality score (0.0 - 1.0)
    public var overallScore: Double {
        let metricsScore = classificationMetrics?.f1Score ?? regressionMetrics?.r2Score ?? 0.0
        let healthScore = healthMetrics.overallScore
        let performanceScore = performanceBenchmarks.normalizedScore
        
        // Weighted average: 50% metrics, 30% health-specific, 20% performance
        return (metricsScore * 0.5) + (healthScore * 0.3) + (performanceScore * 0.2)
    }
    
    /// Indicates if model meets production quality standards
    public var isProductionReady: Bool {
        overallScore >= 0.85 && 
        healthMetrics.clinicalSafety >= 0.9 &&
        performanceBenchmarks.meetsRequirements
    }
}

@available(iOS 18.0, macOS 15.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
public struct ClassificationMetrics: Codable, Sendable {
    /// Accuracy (correct predictions / total predictions)
    public let accuracy: Double
    
    /// Precision (true positives / (true positives + false positives))
    public let precision: Double
    
    /// Recall/Sensitivity (true positives / (true positives + false negatives))
    public let recall: Double
    
    /// F1 Score (harmonic mean of precision and recall)
    public let f1Score: Double
    
    /// Specificity (true negatives / (true negatives + false positives))
    public let specificity: Double
    
    /// Area Under the ROC Curve
    public let aucRoc: Double
    
    /// Area Under the Precision-Recall Curve
    public let aucPr: Double
    
    /// Confusion matrix
    public let confusionMatrix: [[Int]]
    
    /// Per-class metrics
    public let perClassMetrics: [String: ClassMetrics]
    
    public init(
        accuracy: Double,
        precision: Double,
        recall: Double,
        f1Score: Double,
        specificity: Double,
        aucRoc: Double,
        aucPr: Double,
        confusionMatrix: [[Int]],
        perClassMetrics: [String: ClassMetrics]
    ) {
        self.accuracy = max(0.0, min(1.0, accuracy))
        self.precision = max(0.0, min(1.0, precision))
        self.recall = max(0.0, min(1.0, recall))
        self.f1Score = max(0.0, min(1.0, f1Score))
        self.specificity = max(0.0, min(1.0, specificity))
        self.aucRoc = max(0.0, min(1.0, aucRoc))
        self.aucPr = max(0.0, min(1.0, aucPr))
        self.confusionMatrix = confusionMatrix
        self.perClassMetrics = perClassMetrics
    }
    
    /// Matthews Correlation Coefficient
    public var matthewsCorrelationCoefficient: Double {
        guard confusionMatrix.count == 2 && confusionMatrix[0].count == 2 else {
            return 0.0 // MCC only for binary classification
        }
        
        let tp = Double(confusionMatrix[1][1])
        let tn = Double(confusionMatrix[0][0])
        let fp = Double(confusionMatrix[0][1])
        let fn = Double(confusionMatrix[1][0])
        
        let numerator = (tp * tn) - (fp * fn)
        let denominator = sqrt((tp + fp) * (tp + fn) * (tn + fp) * (tn + fn))
        
        return denominator == 0 ? 0.0 : numerator / denominator
    }
}

@available(iOS 18.0, macOS 15.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
public struct ClassMetrics: Codable, Sendable {
    public let precision: Double
    public let recall: Double
    public let f1Score: Double
    public let support: Int // Number of true instances for this class
    
    public init(precision: Double, recall: Double, f1Score: Double, support: Int) {
        self.precision = max(0.0, min(1.0, precision))
        self.recall = max(0.0, min(1.0, recall))
        self.f1Score = max(0.0, min(1.0, f1Score))
        self.support = max(0, support)
    }
}

@available(iOS 18.0, macOS 15.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
public struct RegressionMetrics: Codable, Sendable {
    /// Mean Absolute Error
    public let meanAbsoluteError: Double
    
    /// Mean Squared Error
    public let meanSquaredError: Double
    
    /// Root Mean Squared Error
    public let rootMeanSquaredError: Double
    
    /// R-squared (coefficient of determination)
    public let r2Score: Double
    
    /// Adjusted R-squared
    public let adjustedR2Score: Double
    
    /// Mean Absolute Percentage Error
    public let meanAbsolutePercentageError: Double
    
    /// Median Absolute Error
    public let medianAbsoluteError: Double
    
    /// Explained Variance Score
    public let explainedVarianceScore: Double
    
    public init(
        meanAbsoluteError: Double,
        meanSquaredError: Double,
        rootMeanSquaredError: Double,
        r2Score: Double,
        adjustedR2Score: Double,
        meanAbsolutePercentageError: Double,
        medianAbsoluteError: Double,
        explainedVarianceScore: Double
    ) {
        self.meanAbsoluteError = max(0.0, meanAbsoluteError)
        self.meanSquaredError = max(0.0, meanSquaredError)
        self.rootMeanSquaredError = max(0.0, rootMeanSquaredError)
        self.r2Score = r2Score // Can be negative
        self.adjustedR2Score = adjustedR2Score // Can be negative
        self.meanAbsolutePercentageError = max(0.0, meanAbsolutePercentageError)
        self.medianAbsoluteError = max(0.0, medianAbsoluteError)
        self.explainedVarianceScore = max(0.0, min(1.0, explainedVarianceScore))
    }
    
    /// Normalized RMSE (RMSE divided by target range)
    public func normalizedRMSE(targetRange: Double) -> Double {
        guard targetRange > 0 else { return Double.infinity }
        return rootMeanSquaredError / targetRange
    }
}

@available(iOS 18.0, macOS 15.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
public struct HealthSpecificMetrics: Codable, Sendable {
    /// Clinical safety score (0.0 - 1.0)
    public let clinicalSafety: Double
    
    /// Sensitivity to health anomalies
    public let anomalySensitivity: Double
    
    /// False positive rate for health alerts
    public let healthAlertFalsePositiveRate: Double
    
    /// False negative rate for health alerts
    public let healthAlertFalseNegativeRate: Double
    
    /// Predictive value for health interventions
    public let interventionPredictiveValue: Double
    
    /// Model fairness across demographics
    public let demographicFairness: DemographicFairness
    
    /// Temporal stability of predictions
    public let temporalStability: Double
    
    /// Clinical concordance with medical standards
    public let clinicalConcordance: Double
    
    public init(
        clinicalSafety: Double,
        anomalySensitivity: Double,
        healthAlertFalsePositiveRate: Double,
        healthAlertFalseNegativeRate: Double,
        interventionPredictiveValue: Double,
        demographicFairness: DemographicFairness,
        temporalStability: Double,
        clinicalConcordance: Double
    ) {
        self.clinicalSafety = max(0.0, min(1.0, clinicalSafety))
        self.anomalySensitivity = max(0.0, min(1.0, anomalySensitivity))
        self.healthAlertFalsePositiveRate = max(0.0, min(1.0, healthAlertFalsePositiveRate))
        self.healthAlertFalseNegativeRate = max(0.0, min(1.0, healthAlertFalseNegativeRate))
        self.interventionPredictiveValue = max(0.0, min(1.0, interventionPredictiveValue))
        self.demographicFairness = demographicFairness
        self.temporalStability = max(0.0, min(1.0, temporalStability))
        self.clinicalConcordance = max(0.0, min(1.0, clinicalConcordance))
    }
    
    /// Overall health-specific score
    public var overallScore: Double {
        let weights: [Double] = [0.25, 0.15, 0.1, 0.1, 0.15, 0.1, 0.1, 0.05]
        let scores = [
            clinicalSafety,
            anomalySensitivity,
            1.0 - healthAlertFalsePositiveRate, // Lower is better
            1.0 - healthAlertFalseNegativeRate, // Lower is better
            interventionPredictiveValue,
            demographicFairness.overallScore,
            temporalStability,
            clinicalConcordance
        ]
        return zip(weights, scores).map(*).reduce(0, +)
    }
}

@available(iOS 18.0, macOS 15.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
public struct DemographicFairness: Codable, Sendable {
    /// Fairness across age groups
    public let ageFairness: Double
    
    /// Fairness across gender/sex
    public let genderFairness: Double
    
    /// Fairness across ethnic groups
    public let ethnicFairness: Double
    
    /// Fairness across socioeconomic status
    public let socioeconomicFairness: Double
    
    /// Statistical parity difference
    public let statisticalParityDifference: Double
    
    /// Equalized odds difference
    public let equalizedOddsDifference: Double
    
    public init(
        ageFairness: Double,
        genderFairness: Double,
        ethnicFairness: Double,
        socioeconomicFairness: Double,
        statisticalParityDifference: Double,
        equalizedOddsDifference: Double
    ) {
        self.ageFairness = max(0.0, min(1.0, ageFairness))
        self.genderFairness = max(0.0, min(1.0, genderFairness))
        self.ethnicFairness = max(0.0, min(1.0, ethnicFairness))
        self.socioeconomicFairness = max(0.0, min(1.0, socioeconomicFairness))
        self.statisticalParityDifference = max(0.0, min(1.0, abs(statisticalParityDifference)))
        self.equalizedOddsDifference = max(0.0, min(1.0, abs(equalizedOddsDifference)))
    }
    
    /// Overall demographic fairness score
    public var overallScore: Double {
        let fairnessScores = [ageFairness, genderFairness, ethnicFairness, socioeconomicFairness]
        let averageFairness = fairnessScores.reduce(0, +) / Double(fairnessScores.count)
        
        // Penalize high statistical disparity
        let disparityPenalty = (statisticalParityDifference + equalizedOddsDifference) / 2.0
        
        return max(0.0, averageFairness - disparityPenalty)
    }
}

@available(iOS 18.0, macOS 15.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
public struct PerformanceBenchmarks: Codable, Sendable {
    /// Training time in seconds
    public let trainingTime: TimeInterval
    
    /// Average inference time in milliseconds
    public let inferenceTime: Double
    
    /// Memory usage during training (MB)
    public let trainingMemoryUsage: Double
    
    /// Memory usage during inference (MB)
    public let inferenceMemoryUsage: Double
    
    /// Model size on disk (MB)
    public let modelSize: Double
    
    /// CPU utilization during inference (%)
    public let cpuUtilization: Double
    
    /// GPU utilization during inference (%)
    public let gpuUtilization: Double?
    
    /// Battery impact score (0.0 - 1.0, lower is better)
    public let batteryImpact: Double
    
    /// Throughput (predictions per second)
    public let throughput: Double
    
    /// Scalability metrics
    public let scalabilityMetrics: ScalabilityMetrics
    
    public init(
        trainingTime: TimeInterval,
        inferenceTime: Double,
        trainingMemoryUsage: Double,
        inferenceMemoryUsage: Double,
        modelSize: Double,
        cpuUtilization: Double,
        gpuUtilization: Double? = nil,
        batteryImpact: Double,
        throughput: Double,
        scalabilityMetrics: ScalabilityMetrics
    ) {
        self.trainingTime = max(0, trainingTime)
        self.inferenceTime = max(0, inferenceTime)
        self.trainingMemoryUsage = max(0, trainingMemoryUsage)
        self.inferenceMemoryUsage = max(0, inferenceMemoryUsage)
        self.modelSize = max(0, modelSize)
        self.cpuUtilization = max(0, min(100, cpuUtilization))
        self.gpuUtilization = gpuUtilization.map { max(0, min(100, $0)) }
        self.batteryImpact = max(0.0, min(1.0, batteryImpact))
        self.throughput = max(0, throughput)
        self.scalabilityMetrics = scalabilityMetrics
    }
    
    /// Normalized performance score (0.0 - 1.0, higher is better)
    public var normalizedScore: Double {
        let timeScore = max(0.0, 1.0 - min(1.0, inferenceTime / 100.0)) // Normalize to 100ms
        let memoryScore = max(0.0, 1.0 - min(1.0, inferenceMemoryUsage / 1000.0)) // Normalize to 1GB
        let sizeScore = max(0.0, 1.0 - min(1.0, modelSize / 100.0)) // Normalize to 100MB
        let batteryScore = 1.0 - batteryImpact
        let throughputScore = min(1.0, throughput / 1000.0) // Normalize to 1000 pred/sec
        
        return (timeScore + memoryScore + sizeScore + batteryScore + throughputScore) / 5.0
    }
    
    /// Checks if benchmarks meet performance requirements
    public func meetsRequirements(_ requirements: PerformanceRequirements) -> Bool {
        return inferenceTime <= requirements.maxInferenceTime &&
               inferenceMemoryUsage <= requirements.maxMemoryUsage &&
               normalizedScore >= 0.7 // Minimum acceptable performance
    }
    
    /// Overall performance meets requirements flag
    public var meetsRequirements: Bool {
        return normalizedScore >= 0.7 &&
               inferenceTime <= 100.0 && // 100ms max
               inferenceMemoryUsage <= 500.0 && // 500MB max
               batteryImpact <= 0.3 // Low battery impact
    }
}

@available(iOS 18.0, macOS 15.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
public struct ScalabilityMetrics: Codable, Sendable {
    /// How performance scales with data size
    public let dataScalingFactor: Double
    
    /// How performance scales with model complexity
    public let complexityScalingFactor: Double
    
    /// Maximum tested data size (number of samples)
    public let maxDataSize: Int
    
    /// Performance at different data sizes
    public let performanceByDataSize: [Int: Double] // data size -> inference time
    
    public init(
        dataScalingFactor: Double,
        complexityScalingFactor: Double,
        maxDataSize: Int,
        performanceByDataSize: [Int: Double]
    ) {
        self.dataScalingFactor = dataScalingFactor
        self.complexityScalingFactor = complexityScalingFactor
        self.maxDataSize = max(0, maxDataSize)
        self.performanceByDataSize = performanceByDataSize
    }
}

@available(iOS 18.0, macOS 15.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
public struct CrossValidationResults: Codable, Sendable {
    /// Number of folds used
    public let numberOfFolds: Int
    
    /// Scores for each fold
    public let foldScores: [Double]
    
    /// Mean score across all folds
    public let meanScore: Double
    
    /// Standard deviation of scores
    public let standardDeviation: Double
    
    /// Confidence interval (95%)
    public let confidenceInterval: (lower: Double, upper: Double)
    
    /// Validation strategy used
    public let validationStrategy: ValidationStrategy
    
    public init(
        numberOfFolds: Int,
        foldScores: [Double],
        validationStrategy: ValidationStrategy
    ) {
        self.numberOfFolds = numberOfFolds
        self.foldScores = foldScores
        self.validationStrategy = validationStrategy
        
        // Calculate statistics
        self.meanScore = foldScores.isEmpty ? 0.0 : foldScores.reduce(0, +) / Double(foldScores.count)
        
        if foldScores.count > 1 {
            let variance = foldScores.map { pow($0 - meanScore, 2) }.reduce(0, +) / Double(foldScores.count - 1)
            self.standardDeviation = sqrt(variance)
            
            // 95% confidence interval using t-distribution approximation
            let marginOfError = 1.96 * standardDeviation / sqrt(Double(foldScores.count))
            self.confidenceInterval = (
                lower: meanScore - marginOfError,
                upper: meanScore + marginOfError
            )
        } else {
            self.standardDeviation = 0.0
            self.confidenceInterval = (lower: meanScore, upper: meanScore)
        }
    }
    
    /// Indicates if the model is stable across folds
    public var isStable: Bool {
        return standardDeviation <= 0.05 // Less than 5% variation
    }
}

@available(iOS 18.0, macOS 15.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
public class MLMetricsCalculator: Sendable {
    
    /// Calculate classification metrics from predictions and ground truth
    public static func calculateClassificationMetrics(
        predictions: [Int],
        groundTruth: [Int],
        classNames: [String]? = nil
    ) -> ClassificationMetrics {
        // Implementation would go here
        // This is a placeholder showing the structure
        let accuracy = calculateAccuracy(predictions: predictions, groundTruth: groundTruth)
        let confusionMatrix = calculateConfusionMatrix(predictions: predictions, groundTruth: groundTruth)
        
        return ClassificationMetrics(
            accuracy: accuracy,
            precision: 0.0, // Would calculate from confusion matrix
            recall: 0.0,    // Would calculate from confusion matrix
            f1Score: 0.0,   // Would calculate from precision and recall
            specificity: 0.0,
            aucRoc: 0.0,    // Would require prediction probabilities
            aucPr: 0.0,     // Would require prediction probabilities
            confusionMatrix: confusionMatrix,
            perClassMetrics: [:]
        )
    }
    
    /// Calculate regression metrics from predictions and ground truth
    public static func calculateRegressionMetrics(
        predictions: [Double],
        groundTruth: [Double]
    ) -> RegressionMetrics {
        let mae = calculateMAE(predictions: predictions, groundTruth: groundTruth)
        let mse = calculateMSE(predictions: predictions, groundTruth: groundTruth)
        let rmse = sqrt(mse)
        let r2 = calculateR2(predictions: predictions, groundTruth: groundTruth)
        
        return RegressionMetrics(
            meanAbsoluteError: mae,
            meanSquaredError: mse,
            rootMeanSquaredError: rmse,
            r2Score: r2,
            adjustedR2Score: r2, // Simplified
            meanAbsolutePercentageError: 0.0,
            medianAbsoluteError: 0.0,
            explainedVarianceScore: 0.0
        )
    }
    
    // Helper methods for metric calculations
    private static func calculateAccuracy(predictions: [Int], groundTruth: [Int]) -> Double {
        guard predictions.count == groundTruth.count, !predictions.isEmpty else { return 0.0 }
        let correct = zip(predictions, groundTruth).count { $0 == $1 }
        return Double(correct) / Double(predictions.count)
    }
    
    private static func calculateConfusionMatrix(predictions: [Int], groundTruth: [Int]) -> [[Int]] {
        // Simplified 2x2 matrix for binary classification
        return [[0, 0], [0, 0]]
    }
    
    private static func calculateMAE(predictions: [Double], groundTruth: [Double]) -> Double {
        guard predictions.count == groundTruth.count, !predictions.isEmpty else { return 0.0 }
        let errors = zip(predictions, groundTruth).map { abs($0 - $1) }
        return errors.reduce(0, +) / Double(errors.count)
    }
    
    private static func calculateMSE(predictions: [Double], groundTruth: [Double]) -> Double {
        guard predictions.count == groundTruth.count, !predictions.isEmpty else { return 0.0 }
        let errors = zip(predictions, groundTruth).map { pow($0 - $1, 2) }
        return errors.reduce(0, +) / Double(errors.count)
    }
    
    private static func calculateR2(predictions: [Double], groundTruth: [Double]) -> Double {
        guard predictions.count == groundTruth.count, !predictions.isEmpty else { return 0.0 }
        
        let meanTrue = groundTruth.reduce(0, +) / Double(groundTruth.count)
        let ssRes = zip(predictions, groundTruth).map { pow($1 - $0, 2) }.reduce(0, +)
        let ssTot = groundTruth.map { pow($0 - meanTrue, 2) }.reduce(0, +)
        
        return ssTot == 0 ? 0.0 : 1.0 - (ssRes / ssTot)
    }
}
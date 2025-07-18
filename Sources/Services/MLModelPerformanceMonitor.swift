import Foundation
import CoreML
import os.log

/// Comprehensive ML model performance monitoring system for HealthAI 2030
@MainActor
public class MLModelPerformanceMonitor: ObservableObject {
    public static let shared = MLModelPerformanceMonitor()
    
    private let logger = Logger(subsystem: "com.healthai.mlmonitoring", category: "PerformanceMonitor")
    private let storage = MLModelPerformanceStorage()
    
    @Published public var performanceMetrics: [String: ModelPerformanceMetrics] = [:]
    @Published public var driftAlerts: [ModelDriftAlert] = []
    @Published public var biasAlerts: [ModelBiasAlert] = []
    @Published public var performanceAlerts: [PerformanceAlert] = []
    
    private var monitoringTimer: Timer?
    private var modelUsageCounters: [String: Int] = [:]
    private var modelErrorCounters: [String: Int] = [:]
    
    private init() {
        startPeriodicMonitoring()
    }
    
    // MARK: - Performance Metrics
    
    /// Record performance metrics for a model
    public func recordPerformance(
        modelIdentifier: String,
        accuracy: Double,
        precision: Double,
        recall: Double,
        f1Score: Double,
        inferenceTime: TimeInterval,
        memoryUsage: Int64,
        timestamp: Date = Date()
    ) {
        let metrics = ModelPerformanceMetrics(
            modelIdentifier: modelIdentifier,
            accuracy: accuracy,
            precision: precision,
            recall: recall,
            f1Score: f1Score,
            inferenceTime: inferenceTime,
            memoryUsage: memoryUsage,
            timestamp: timestamp,
            usageCount: modelUsageCounters[modelIdentifier] ?? 0,
            errorCount: modelErrorCounters[modelIdentifier] ?? 0
        )
        
        performanceMetrics[modelIdentifier] = metrics
        
        // Check for performance degradation
        checkPerformanceDegradation(modelIdentifier: modelIdentifier, metrics: metrics)
        
        // Store metrics
        Task {
            await storage.storeMetrics(metrics)
        }
        
        logger.info("Performance recorded for \(modelIdentifier): Accuracy=\(accuracy), F1=\(f1Score), Time=\(inferenceTime)s")
    }
    
    /// Record model usage
    public func recordModelUsage(modelIdentifier: String) {
        modelUsageCounters[modelIdentifier, default: 0] += 1
        logger.debug("Model usage recorded for \(modelIdentifier): \(modelUsageCounters[modelIdentifier] ?? 0)")
    }
    
    /// Record model error
    public func recordModelError(modelIdentifier: String, error: Error) {
        modelErrorCounters[modelIdentifier, default: 0] += 1
        logger.error("Model error recorded for \(modelIdentifier): \(error.localizedDescription)")
        
        // Check error rate threshold
        checkErrorRateThreshold(modelIdentifier: modelIdentifier)
    }
    
    // MARK: - Drift Detection
    
    /// Monitor model drift using statistical methods
    public func monitorModelDrift(
        modelIdentifier: String,
        newPredictions: [Double],
        baselinePredictions: [Double]
    ) {
        let driftScore = calculateDriftScore(newPredictions: newPredictions, baselinePredictions: baselinePredictions)
        let driftThreshold = 0.15 // 15% drift threshold
        
        if driftScore > driftThreshold {
            let alert = ModelDriftAlert(
                modelIdentifier: modelIdentifier,
                driftScore: driftScore,
                threshold: driftThreshold,
                timestamp: Date(),
                severity: driftScore > 0.25 ? .critical : .warning
            )
            
            driftAlerts.append(alert)
            logger.warning("Model drift detected for \(modelIdentifier): \(driftScore)")
            
            // Store drift alert
            Task {
                await storage.storeDriftAlert(alert)
            }
        }
    }
    
    /// Calculate drift score using statistical methods
    private func calculateDriftScore(newPredictions: [Double], baselinePredictions: [Double]) -> Double {
        guard !newPredictions.isEmpty && !baselinePredictions.isEmpty else { return 0.0 }
        
        // Calculate distribution statistics
        let newMean = newPredictions.reduce(0, +) / Double(newPredictions.count)
        let baselineMean = baselinePredictions.reduce(0, +) / Double(baselinePredictions.count)
        
        let newStd = calculateStandardDeviation(values: newPredictions, mean: newMean)
        let baselineStd = calculateStandardDeviation(values: baselinePredictions, mean: baselineMean)
        
        // Calculate drift score using mean and standard deviation differences
        let meanDrift = abs(newMean - baselineMean) / baselineMean
        let stdDrift = abs(newStd - baselineStd) / baselineStd
        
        return (meanDrift + stdDrift) / 2.0
    }
    
    private func calculateStandardDeviation(values: [Double], mean: Double) -> Double {
        let variance = values.reduce(0.0) { sum, value in
            sum + pow(value - mean, 2)
        } / Double(values.count)
        return sqrt(variance)
    }
    
    // MARK: - Bias Detection
    
    /// Monitor model bias across different demographic groups
    public func monitorModelBias(
        modelIdentifier: String,
        predictions: [(prediction: Double, groundTruth: Double, group: String)]
    ) {
        let groupPerformance = calculateGroupPerformance(predictions: predictions)
        let biasScore = calculateBiasScore(groupPerformance: groupPerformance)
        let biasThreshold = 0.1 // 10% performance difference threshold
        
        if biasScore > biasThreshold {
            let alert = ModelBiasAlert(
                modelIdentifier: modelIdentifier,
                biasScore: biasScore,
                threshold: biasThreshold,
                affectedGroups: Array(groupPerformance.keys),
                timestamp: Date(),
                severity: biasScore > 0.2 ? .critical : .warning
            )
            
            biasAlerts.append(alert)
            logger.warning("Model bias detected for \(modelIdentifier): \(biasScore)")
            
            // Store bias alert
            Task {
                await storage.storeBiasAlert(alert)
            }
        }
    }
    
    /// Calculate performance for different groups
    private func calculateGroupPerformance(
        predictions: [(prediction: Double, groundTruth: Double, group: String)]
    ) -> [String: Double] {
        var groupMetrics: [String: (correct: Int, total: Int)] = [:]
        
        for (prediction, groundTruth, group) in predictions {
            groupMetrics[group, default: (0, 0)].total += 1
            
            // Simple accuracy calculation (prediction within 10% of ground truth)
            let error = abs(prediction - groundTruth) / groundTruth
            if error <= 0.1 {
                groupMetrics[group]?.correct += 1
            }
        }
        
        return groupMetrics.mapValues { Double($0.correct) / Double($0.total) }
    }
    
    /// Calculate bias score across groups
    private func calculateBiasScore(groupPerformance: [String: Double]) -> Double {
        guard groupPerformance.count > 1 else { return 0.0 }
        
        let performances = Array(groupPerformance.values)
        let meanPerformance = performances.reduce(0, +) / Double(performances.count)
        
        let maxDeviation = performances.map { abs($0 - meanPerformance) }.max() ?? 0.0
        return maxDeviation / meanPerformance
    }
    
    // MARK: - Performance Degradation Detection
    
    /// Check for performance degradation
    private func checkPerformanceDegradation(modelIdentifier: String, metrics: ModelPerformanceMetrics) {
        guard let baselineMetrics = getBaselineMetrics(modelIdentifier: modelIdentifier) else {
            // Set baseline for new models
            setBaselineMetrics(modelIdentifier: modelIdentifier, metrics: metrics)
            return
        }
        
        let accuracyDegradation = baselineMetrics.accuracy - metrics.accuracy
        let timeDegradation = metrics.inferenceTime - baselineMetrics.inferenceTime
        
        let accuracyThreshold = 0.05 // 5% accuracy degradation
        let timeThreshold: TimeInterval = 0.1 // 100ms time degradation
        
        if accuracyDegradation > accuracyThreshold || timeDegradation > timeThreshold {
            let alert = PerformanceAlert(
                modelIdentifier: modelIdentifier,
                alertType: accuracyDegradation > accuracyThreshold ? .accuracyDegradation : .performanceDegradation,
                severity: accuracyDegradation > 0.1 ? .critical : .warning,
                timestamp: Date(),
                details: "Accuracy: \(accuracyDegradation), Time: \(timeDegradation)s"
            )
            
            performanceAlerts.append(alert)
            logger.warning("Performance degradation detected for \(modelIdentifier)")
            
            // Store performance alert
            Task {
                await storage.storePerformanceAlert(alert)
            }
        }
    }
    
    /// Check error rate threshold
    private func checkErrorRateThreshold(modelIdentifier: String) {
        let usageCount = modelUsageCounters[modelIdentifier] ?? 0
        let errorCount = modelErrorCounters[modelIdentifier] ?? 0
        
        guard usageCount > 0 else { return }
        
        let errorRate = Double(errorCount) / Double(usageCount)
        let errorThreshold = 0.05 // 5% error rate threshold
        
        if errorRate > errorThreshold {
            let alert = PerformanceAlert(
                modelIdentifier: modelIdentifier,
                alertType: .highErrorRate,
                severity: errorRate > 0.1 ? .critical : .warning,
                timestamp: Date(),
                details: "Error rate: \(errorRate * 100)%"
            )
            
            performanceAlerts.append(alert)
            logger.warning("High error rate detected for \(modelIdentifier): \(errorRate * 100)%")
            
            // Store performance alert
            Task {
                await storage.storePerformanceAlert(alert)
            }
        }
    }
    
    // MARK: - Baseline Management
    
    private func getBaselineMetrics(modelIdentifier: String) -> ModelPerformanceMetrics? {
        return UserDefaults.standard.object(forKey: "baseline_\(modelIdentifier)") as? ModelPerformanceMetrics
    }
    
    private func setBaselineMetrics(modelIdentifier: String, metrics: ModelPerformanceMetrics) {
        UserDefaults.standard.set(metrics, forKey: "baseline_\(modelIdentifier)")
    }
    
    // MARK: - Periodic Monitoring
    
    private func startPeriodicMonitoring() {
        monitoringTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { _ in // 5 minutes
            Task { @MainActor in
                await self.performPeriodicChecks()
            }
        }
    }
    
    private func performPeriodicChecks() async {
        // Check for stale models (no usage in 24 hours)
        let staleThreshold: TimeInterval = 24 * 60 * 60 // 24 hours
        let now = Date()
        
        for (modelIdentifier, metrics) in performanceMetrics {
            if now.timeIntervalSince(metrics.timestamp) > staleThreshold {
                let alert = PerformanceAlert(
                    modelIdentifier: modelIdentifier,
                    alertType: .staleModel,
                    severity: .info,
                    timestamp: now,
                    details: "No usage for \(Int(now.timeIntervalSince(metrics.timestamp) / 3600)) hours"
                )
                
                performanceAlerts.append(alert)
                logger.info("Stale model detected: \(modelIdentifier)")
            }
        }
        
        // Generate periodic report
        await generatePeriodicReport()
    }
    
    // MARK: - Reporting
    
    /// Generate comprehensive performance report
    public func generatePerformanceReport() -> MLModelPerformanceReport {
        let totalModels = performanceMetrics.count
        let modelsWithDrift = driftAlerts.filter { $0.timestamp > Date().addingTimeInterval(-86400) }.count
        let modelsWithBias = biasAlerts.filter { $0.timestamp > Date().addingTimeInterval(-86400) }.count
        let modelsWithPerformanceIssues = performanceAlerts.filter { $0.timestamp > Date().addingTimeInterval(-86400) }.count
        
        let averageAccuracy = performanceMetrics.values.map { $0.accuracy }.reduce(0, +) / Double(max(performanceMetrics.count, 1))
        let averageInferenceTime = performanceMetrics.values.map { $0.inferenceTime }.reduce(0, +) / Double(max(performanceMetrics.count, 1))
        
        return MLModelPerformanceReport(
            timestamp: Date(),
            totalModels: totalModels,
            modelsWithDrift: modelsWithDrift,
            modelsWithBias: modelsWithBias,
            modelsWithPerformanceIssues: modelsWithPerformanceIssues,
            averageAccuracy: averageAccuracy,
            averageInferenceTime: averageInferenceTime,
            recentAlerts: Array(driftAlerts.suffix(10) + biasAlerts.suffix(10) + performanceAlerts.suffix(10))
        )
    }
    
    private func generatePeriodicReport() async {
        let report = generatePerformanceReport()
        
        // Store report
        await storage.storeReport(report)
        
        // Log summary
        logger.info("""
            Periodic ML Model Performance Report:
            - Total Models: \(report.totalModels)
            - Models with Drift: \(report.modelsWithDrift)
            - Models with Bias: \(report.modelsWithBias)
            - Models with Performance Issues: \(report.modelsWithPerformanceIssues)
            - Average Accuracy: \(report.averageAccuracy)
            - Average Inference Time: \(report.averageInferenceTime)s
            """)
    }
    
    // MARK: - Alert Management
    
    /// Clear old alerts
    public func clearOldAlerts(olderThan days: Int) {
        let cutoffDate = Date().addingTimeInterval(-TimeInterval(days * 24 * 60 * 60))
        
        driftAlerts.removeAll { $0.timestamp < cutoffDate }
        biasAlerts.removeAll { $0.timestamp < cutoffDate }
        performanceAlerts.removeAll { $0.timestamp < cutoffDate }
        
        logger.info("Cleared alerts older than \(days) days")
    }
    
    /// Export performance data
    public func exportPerformanceData() -> Data? {
        let exportData = MLModelPerformanceExport(
            metrics: performanceMetrics,
            driftAlerts: driftAlerts,
            biasAlerts: biasAlerts,
            performanceAlerts: performanceAlerts,
            exportDate: Date()
        )
        
        return try? JSONEncoder().encode(exportData)
    }
}

// MARK: - Supporting Types

public struct ModelPerformanceMetrics: Codable {
    public let modelIdentifier: String
    public let accuracy: Double
    public let precision: Double
    public let recall: Double
    public let f1Score: Double
    public let inferenceTime: TimeInterval
    public let memoryUsage: Int64
    public let timestamp: Date
    public let usageCount: Int
    public let errorCount: Int
    
    public var errorRate: Double {
        guard usageCount > 0 else { return 0.0 }
        return Double(errorCount) / Double(usageCount)
    }
}

public struct ModelDriftAlert: Codable, Identifiable {
    public let id = UUID()
    public let modelIdentifier: String
    public let driftScore: Double
    public let threshold: Double
    public let timestamp: Date
    public let severity: AlertSeverity
}

public struct ModelBiasAlert: Codable, Identifiable {
    public let id = UUID()
    public let modelIdentifier: String
    public let biasScore: Double
    public let threshold: Double
    public let affectedGroups: [String]
    public let timestamp: Date
    public let severity: AlertSeverity
}

public struct PerformanceAlert: Codable, Identifiable {
    public let id = UUID()
    public let modelIdentifier: String
    public let alertType: PerformanceAlertType
    public let severity: AlertSeverity
    public let timestamp: Date
    public let details: String
}

public enum AlertSeverity: String, Codable, CaseIterable {
    case info = "Info"
    case warning = "Warning"
    case critical = "Critical"
}

public enum PerformanceAlertType: String, Codable, CaseIterable {
    case accuracyDegradation = "Accuracy Degradation"
    case performanceDegradation = "Performance Degradation"
    case highErrorRate = "High Error Rate"
    case staleModel = "Stale Model"
}

public struct MLModelPerformanceReport: Codable {
    public let timestamp: Date
    public let totalModels: Int
    public let modelsWithDrift: Int
    public let modelsWithBias: Int
    public let modelsWithPerformanceIssues: Int
    public let averageAccuracy: Double
    public let averageInferenceTime: TimeInterval
    public let recentAlerts: [Any]
    
    private enum CodingKeys: String, CodingKey {
        case timestamp, totalModels, modelsWithDrift, modelsWithBias, modelsWithPerformanceIssues
        case averageAccuracy, averageInferenceTime, recentAlerts
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        totalModels = try container.decode(Int.self, forKey: .totalModels)
        modelsWithDrift = try container.decode(Int.self, forKey: .modelsWithDrift)
        modelsWithBias = try container.decode(Int.self, forKey: .modelsWithBias)
        modelsWithPerformanceIssues = try container.decode(Int.self, forKey: .modelsWithPerformanceIssues)
        averageAccuracy = try container.decode(Double.self, forKey: .averageAccuracy)
        averageInferenceTime = try container.decode(TimeInterval.self, forKey: .averageInferenceTime)
        recentAlerts = []
    }
    
    public init(timestamp: Date, totalModels: Int, modelsWithDrift: Int, modelsWithBias: Int, modelsWithPerformanceIssues: Int, averageAccuracy: Double, averageInferenceTime: TimeInterval, recentAlerts: [Any]) {
        self.timestamp = timestamp
        self.totalModels = totalModels
        self.modelsWithDrift = modelsWithDrift
        self.modelsWithBias = modelsWithBias
        self.modelsWithPerformanceIssues = modelsWithPerformanceIssues
        self.averageAccuracy = averageAccuracy
        self.averageInferenceTime = averageInferenceTime
        self.recentAlerts = recentAlerts
    }
}

private struct MLModelPerformanceExport: Codable {
    let metrics: [String: ModelPerformanceMetrics]
    let driftAlerts: [ModelDriftAlert]
    let biasAlerts: [ModelBiasAlert]
    let performanceAlerts: [PerformanceAlert]
    let exportDate: Date
}

// MARK: - Storage

private actor MLModelPerformanceStorage {
    private let fileManager = FileManager.default
    private let storageDirectory: URL
    
    init() {
        guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            fatalError("Unable to access document directory")
        }
        storageDirectory = documentsDirectory.appendingPathComponent("MLModelPerformance", isDirectory: true)
        try? fileManager.createDirectory(at: storageDirectory, withIntermediateDirectories: true)
    }
    
    func storeMetrics(_ metrics: ModelPerformanceMetrics) {
        let filename = "metrics_\(metrics.modelIdentifier)_\(Int(metrics.timestamp.timeIntervalSince1970)).json"
        let fileURL = storageDirectory.appendingPathComponent(filename)
        
        if let data = try? JSONEncoder().encode(metrics) {
            try? data.write(to: fileURL)
        }
    }
    
    func storeDriftAlert(_ alert: ModelDriftAlert) {
        let filename = "drift_\(alert.modelIdentifier)_\(Int(alert.timestamp.timeIntervalSince1970)).json"
        let fileURL = storageDirectory.appendingPathComponent(filename)
        
        if let data = try? JSONEncoder().encode(alert) {
            try? data.write(to: fileURL)
        }
    }
    
    func storeBiasAlert(_ alert: ModelBiasAlert) {
        let filename = "bias_\(alert.modelIdentifier)_\(Int(alert.timestamp.timeIntervalSince1970)).json"
        let fileURL = storageDirectory.appendingPathComponent(filename)
        
        if let data = try? JSONEncoder().encode(alert) {
            try? data.write(to: fileURL)
        }
    }
    
    func storePerformanceAlert(_ alert: PerformanceAlert) {
        let filename = "performance_\(alert.modelIdentifier)_\(Int(alert.timestamp.timeIntervalSince1970)).json"
        let fileURL = storageDirectory.appendingPathComponent(filename)
        
        if let data = try? JSONEncoder().encode(alert) {
            try? data.write(to: fileURL)
        }
    }
    
    func storeReport(_ report: MLModelPerformanceReport) {
        let filename = "report_\(Int(report.timestamp.timeIntervalSince1970)).json"
        let fileURL = storageDirectory.appendingPathComponent(filename)
        
        if let data = try? JSONEncoder().encode(report) {
            try? data.write(to: fileURL)
        }
    }
} 
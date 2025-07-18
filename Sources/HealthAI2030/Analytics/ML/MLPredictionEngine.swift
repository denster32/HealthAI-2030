import Foundation

/**
 * MLPredictionEngine
 * 
 * Model inference and prediction engine for HealthAI2030.
 * Extracted from MLPredictiveModels.swift for better maintainability.
 * 
 * This module contains:
 * - Prediction/inference logic
 * - Model serving infrastructure
 * - Real-time prediction capabilities
 * - Batch prediction processing
 * 
 * ## Benefits of Separation
 * - Focused inference: Dedicated prediction logic
 * - Scalable serving: Optimized for production inference
 * - Real-time ready: Low-latency prediction capabilities
 * - Batch processing: Efficient bulk predictions
 * 
 * - Author: HealthAI2030 Team
 * - Version: 2.0 (Refactored from MLPredictiveModels v1.0)
 * - Since: iOS 18.0, macOS 15.0, watchOS 11.0, tvOS 18.0, visionOS 2.0
 */

@available(iOS 18.0, macOS 15.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
public protocol MLPredictionService: Sendable {
    /// Make a single prediction
    func predict(
        model: TrainedModel,
        input: [Double]
    ) async throws -> MLPredictionResult
    
    /// Make batch predictions
    func batchPredict(
        model: TrainedModel,
        inputs: [[Double]]
    ) async throws -> [MLPredictionResult]
    
    /// Check if this service supports the given model type
    func supports(modelType: MLModelType) -> Bool
}

@available(iOS 18.0, macOS 15.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
public actor MLPredictionEngine: Sendable {
    private var services: [MLModelType: MLPredictionService] = [:]
    private var modelCache: [UUID: CachedModel] = [:]
    private var predictionHistory: [PredictionSession] = []
    private let maxCacheSize: Int = 10
    
    public init() {
        setupDefaultServices()
    }
    
    /// Register a prediction service for a specific model type
    public func registerService(_ service: MLPredictionService, for modelType: MLModelType) {
        services[modelType] = service
    }
    
    /// Load a model into cache for faster predictions
    public func loadModel(_ model: TrainedModel) async throws {
        // Manage cache size
        if modelCache.count >= maxCacheSize {
            // Remove least recently used model
            let oldestKey = modelCache.min(by: { $0.value.lastUsed < $1.value.lastUsed })?.key
            if let key = oldestKey {
                modelCache.removeValue(forKey: key)
            }
        }
        
        let cachedModel = CachedModel(
            model: model,
            loadedAt: Date(),
            lastUsed: Date(),
            usageCount: 0
        )
        
        modelCache[model.id] = cachedModel
    }
    
    /// Make a real-time prediction
    public func predict(
        modelId: UUID,
        input: [Double],
        context: PredictionContext? = nil
    ) async throws -> MLPredictionResult {
        guard let cachedModel = modelCache[modelId] else {
            throw MLPredictionError.modelNotLoaded(modelId)
        }
        
        guard let service = services[cachedModel.model.modelType] else {
            throw MLPredictionError.unsupportedModelType(cachedModel.model.modelType)
        }
        
        let startTime = Date()
        
        // Update cache statistics
        modelCache[modelId]?.lastUsed = Date()
        modelCache[modelId]?.usageCount += 1
        
        do {
            let result = try await service.predict(
                model: cachedModel.model,
                input: input
            )
            
            // Record prediction session
            let session = PredictionSession(
                id: UUID(),
                modelId: modelId,
                inputSize: input.count,
                startTime: startTime,
                endTime: Date(),
                status: .completed,
                context: context
            )
            predictionHistory.append(session)
            
            return result
            
        } catch {
            let session = PredictionSession(
                id: UUID(),
                modelId: modelId,
                inputSize: input.count,
                startTime: startTime,
                endTime: Date(),
                status: .failed,
                context: context,
                error: error.localizedDescription
            )
            predictionHistory.append(session)
            throw error
        }
    }
    
    /// Make batch predictions efficiently
    public func batchPredict(
        modelId: UUID,
        inputs: [[Double]],
        batchSize: Int = 32
    ) async throws -> [MLPredictionResult] {
        guard let cachedModel = modelCache[modelId] else {
            throw MLPredictionError.modelNotLoaded(modelId)
        }
        
        guard let service = services[cachedModel.model.modelType] else {
            throw MLPredictionError.unsupportedModelType(cachedModel.model.modelType)
        }
        
        var results: [MLPredictionResult] = []
        
        // Process in batches for memory efficiency
        for batch in inputs.chunked(into: batchSize) {
            let batchResults = try await service.batchPredict(
                model: cachedModel.model,
                inputs: Array(batch)
            )
            results.append(contentsOf: batchResults)
        }
        
        return results
    }
    
    /// Get prediction statistics
    public func getPredictionStatistics(for modelId: UUID) -> PredictionStatistics? {
        let sessions = predictionHistory.filter { $0.modelId == modelId }
        guard !sessions.isEmpty else { return nil }
        
        let completedSessions = sessions.filter { $0.status == .completed }
        let failedSessions = sessions.filter { $0.status == .failed }
        
        let latencies = completedSessions.map { $0.duration }
        let averageLatency = latencies.isEmpty ? 0.0 : latencies.reduce(0, +) / Double(latencies.count)
        let maxLatency = latencies.max() ?? 0.0
        let minLatency = latencies.min() ?? 0.0
        
        return PredictionStatistics(
            totalPredictions: sessions.count,
            successfulPredictions: completedSessions.count,
            failedPredictions: failedSessions.count,
            averageLatency: averageLatency,
            minLatency: minLatency,
            maxLatency: maxLatency,
            throughput: calculateThroughput(sessions: completedSessions)
        )
    }
    
    /// Stream predictions for real-time health monitoring
    public func streamPredictions(
        modelId: UUID,
        inputStream: AsyncSequence<[Double], Error>
    ) -> AsyncThrowingStream<MLPredictionResult, Error> {
        return AsyncThrowingStream { continuation in
            Task {
                do {
                    for try await input in inputStream {
                        let result = try await predict(modelId: modelId, input: input)
                        continuation.yield(result)
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
    
    private func setupDefaultServices() {
        services[.randomForest] = RandomForestPredictionService()
        services[.gradientBoosting] = GradientBoostingPredictionService()
        services[.neuralNetwork] = NeuralNetworkPredictionService()
        services[.linearRegression] = LinearRegressionPredictionService()
        services[.logisticRegression] = LogisticRegressionPredictionService()
    }
    
    private func calculateThroughput(sessions: [PredictionSession]) -> Double {
        guard !sessions.isEmpty else { return 0.0 }
        
        let totalDuration = sessions.map { $0.duration }.reduce(0, +)
        return totalDuration > 0 ? Double(sessions.count) / totalDuration : 0.0
    }
}

@available(iOS 18.0, macOS 15.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
public struct CachedModel: Sendable {
    public let model: TrainedModel
    public let loadedAt: Date
    public var lastUsed: Date
    public var usageCount: Int
    
    public init(model: TrainedModel, loadedAt: Date, lastUsed: Date, usageCount: Int) {
        self.model = model
        self.loadedAt = loadedAt
        self.lastUsed = lastUsed
        self.usageCount = usageCount
    }
}

@available(iOS 18.0, macOS 15.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
public struct PredictionContext: Codable, Sendable {
    /// User ID for personalized predictions
    public let userId: String?
    
    /// Device type making the prediction
    public let deviceType: String
    
    /// Timestamp of the prediction request
    public let requestTimestamp: Date
    
    /// Additional metadata
    public let metadata: [String: String]
    
    /// Priority level for the prediction
    public let priority: PredictionPriority
    
    public init(
        userId: String? = nil,
        deviceType: String,
        requestTimestamp: Date = Date(),
        metadata: [String: String] = [:],
        priority: PredictionPriority = .normal
    ) {
        self.userId = userId
        self.deviceType = deviceType
        self.requestTimestamp = requestTimestamp
        self.metadata = metadata
        self.priority = priority
    }
}

@available(iOS 18.0, macOS 15.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
public enum PredictionPriority: String, Codable, CaseIterable {
    case low = "low"
    case normal = "normal"
    case high = "high"
    case critical = "critical"
    
    /// Maximum allowed latency for this priority level (in milliseconds)
    public var maxLatency: Double {
        switch self {
        case .low: return 5000.0      // 5 seconds
        case .normal: return 1000.0   // 1 second
        case .high: return 100.0      // 100ms
        case .critical: return 50.0   // 50ms
        }
    }
}

@available(iOS 18.0, macOS 15.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
public struct PredictionSession: Codable, Sendable {
    public let id: UUID
    public let modelId: UUID
    public let inputSize: Int
    public let startTime: Date
    public let endTime: Date
    public let status: PredictionStatus
    public let context: PredictionContext?
    public let error: String?
    
    public init(
        id: UUID,
        modelId: UUID,
        inputSize: Int,
        startTime: Date,
        endTime: Date,
        status: PredictionStatus,
        context: PredictionContext? = nil,
        error: String? = nil
    ) {
        self.id = id
        self.modelId = modelId
        self.inputSize = inputSize
        self.startTime = startTime
        self.endTime = endTime
        self.status = status
        self.context = context
        self.error = error
    }
    
    /// Prediction duration in seconds
    public var duration: TimeInterval {
        endTime.timeIntervalSince(startTime)
    }
    
    /// Latency in milliseconds
    public var latencyMs: Double {
        duration * 1000.0
    }
}

@available(iOS 18.0, macOS 15.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
public enum PredictionStatus: String, Codable, CaseIterable {
    case queued = "queued"
    case processing = "processing"
    case completed = "completed"
    case failed = "failed"
    case timeout = "timeout"
}

@available(iOS 18.0, macOS 15.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
public struct PredictionStatistics: Codable, Sendable {
    public let totalPredictions: Int
    public let successfulPredictions: Int
    public let failedPredictions: Int
    public let averageLatency: TimeInterval
    public let minLatency: TimeInterval
    public let maxLatency: TimeInterval
    public let throughput: Double // predictions per second
    
    public init(
        totalPredictions: Int,
        successfulPredictions: Int,
        failedPredictions: Int,
        averageLatency: TimeInterval,
        minLatency: TimeInterval,
        maxLatency: TimeInterval,
        throughput: Double
    ) {
        self.totalPredictions = totalPredictions
        self.successfulPredictions = successfulPredictions
        self.failedPredictions = failedPredictions
        self.averageLatency = averageLatency
        self.minLatency = minLatency
        self.maxLatency = maxLatency
        self.throughput = throughput
    }
    
    /// Success rate (0.0 - 1.0)
    public var successRate: Double {
        guard totalPredictions > 0 else { return 0.0 }
        return Double(successfulPredictions) / Double(totalPredictions)
    }
    
    /// Failure rate (0.0 - 1.0)
    public var failureRate: Double {
        return 1.0 - successRate
    }
}

// MARK: - Concrete Prediction Service Implementations

@available(iOS 18.0, macOS 15.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
public struct RandomForestPredictionService: MLPredictionService {
    
    public init() {}
    
    public func predict(
        model: TrainedModel,
        input: [Double]
    ) async throws -> MLPredictionResult {
        // Validate input
        guard input.count == model.featureMetadata.count else {
            throw MLPredictionError.invalidInputSize(
                expected: model.featureMetadata.count,
                provided: input.count
            )
        }
        
        // Simulate prediction computation
        try await Task.sleep(nanoseconds: 25_000_000) // 25ms
        
        // Generate mock prediction result
        let prediction = Double.random(in: 0.7...0.95)
        let confidence = Double.random(in: 0.8...0.95)
        
        let performanceMetrics = PredictionPerformanceMetrics(
            inferenceTime: 25.0,
            memoryUsage: 50.0,
            cpuUtilization: 45.0,
            batteryImpact: 0.15
        )
        
        let explanation = PredictionExplanation(
            featureImportance: Dictionary(
                uniqueKeysWithValues: model.featureMetadata.enumerated().map { index, feature in
                    (feature.name, Double.random(in: 0.0...1.0))
                }
            ),
            textualExplanation: "Random Forest prediction based on ensemble of decision trees"
        )
        
        return try MLPredictionResult(
            predictions: [prediction],
            confidenceScores: [confidence],
            modelType: .randomForest,
            healthDomain: model.configuration.healthSettings.healthDomain,
            explanation: explanation,
            performanceMetrics: performanceMetrics
        )
    }
    
    public func batchPredict(
        model: TrainedModel,
        inputs: [[Double]]
    ) async throws -> [MLPredictionResult] {
        var results: [MLPredictionResult] = []
        
        for input in inputs {
            let result = try await predict(model: model, input: input)
            results.append(result)
        }
        
        return results
    }
    
    public func supports(modelType: MLModelType) -> Bool {
        modelType == .randomForest
    }
}

@available(iOS 18.0, macOS 15.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
public struct GradientBoostingPredictionService: MLPredictionService {
    
    public init() {}
    
    public func predict(
        model: TrainedModel,
        input: [Double]
    ) async throws -> MLPredictionResult {
        guard input.count == model.featureMetadata.count else {
            throw MLPredictionError.invalidInputSize(
                expected: model.featureMetadata.count,
                provided: input.count
            )
        }
        
        // Simulate faster prediction for gradient boosting
        try await Task.sleep(nanoseconds: 15_000_000) // 15ms
        
        let prediction = Double.random(in: 0.75...0.97)
        let confidence = Double.random(in: 0.85...0.97)
        
        let performanceMetrics = PredictionPerformanceMetrics(
            inferenceTime: 15.0,
            memoryUsage: 40.0,
            cpuUtilization: 35.0,
            batteryImpact: 0.12
        )
        
        let explanation = PredictionExplanation(
            featureImportance: Dictionary(
                uniqueKeysWithValues: model.featureMetadata.enumerated().map { index, feature in
                    (feature.name, Double.random(in: 0.0...1.0))
                }
            ),
            textualExplanation: "Gradient Boosting prediction based on sequential weak learners"
        )
        
        return try MLPredictionResult(
            predictions: [prediction],
            confidenceScores: [confidence],
            modelType: .gradientBoosting,
            healthDomain: model.configuration.healthSettings.healthDomain,
            explanation: explanation,
            performanceMetrics: performanceMetrics
        )
    }
    
    public func batchPredict(
        model: TrainedModel,
        inputs: [[Double]]
    ) async throws -> [MLPredictionResult] {
        // More efficient batch processing for gradient boosting
        try await Task.sleep(nanoseconds: UInt64(inputs.count * 8_000_000)) // 8ms per prediction
        
        return try inputs.map { input in
            try MLPredictionResult(
                predictions: [Double.random(in: 0.75...0.97)],
                confidenceScores: [Double.random(in: 0.85...0.97)],
                modelType: .gradientBoosting,
                healthDomain: model.configuration.healthSettings.healthDomain,
                performanceMetrics: PredictionPerformanceMetrics(
                    inferenceTime: 8.0,
                    memoryUsage: 40.0,
                    cpuUtilization: 30.0,
                    batteryImpact: 0.10
                )
            )
        }
    }
    
    public func supports(modelType: MLModelType) -> Bool {
        modelType == .gradientBoosting
    }
}

// Placeholder implementations for other services
@available(iOS 18.0, macOS 15.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
public struct NeuralNetworkPredictionService: MLPredictionService {
    public init() {}
    
    public func predict(model: TrainedModel, input: [Double]) async throws -> MLPredictionResult {
        throw MLPredictionError.notImplemented("Neural Network prediction not yet implemented")
    }
    
    public func batchPredict(model: TrainedModel, inputs: [[Double]]) async throws -> [MLPredictionResult] {
        throw MLPredictionError.notImplemented("Neural Network batch prediction not yet implemented")
    }
    
    public func supports(modelType: MLModelType) -> Bool {
        modelType == .neuralNetwork
    }
}

@available(iOS 18.0, macOS 15.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
public struct LinearRegressionPredictionService: MLPredictionService {
    public init() {}
    
    public func predict(model: TrainedModel, input: [Double]) async throws -> MLPredictionResult {
        throw MLPredictionError.notImplemented("Linear Regression prediction not yet implemented")
    }
    
    public func batchPredict(model: TrainedModel, inputs: [[Double]]) async throws -> [MLPredictionResult] {
        throw MLPredictionError.notImplemented("Linear Regression batch prediction not yet implemented")
    }
    
    public func supports(modelType: MLModelType) -> Bool {
        modelType == .linearRegression
    }
}

@available(iOS 18.0, macOS 15.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
public struct LogisticRegressionPredictionService: MLPredictionService {
    public init() {}
    
    public func predict(model: TrainedModel, input: [Double]) async throws -> MLPredictionResult {
        throw MLPredictionError.notImplemented("Logistic Regression prediction not yet implemented")
    }
    
    public func batchPredict(model: TrainedModel, inputs: [[Double]]) async throws -> [MLPredictionResult] {
        throw MLPredictionError.notImplemented("Logistic Regression batch prediction not yet implemented")
    }
    
    public func supports(modelType: MLModelType) -> Bool {
        modelType == .logisticRegression
    }
}

@available(iOS 18.0, macOS 15.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
public enum MLPredictionError: Error, LocalizedError {
    case modelNotLoaded(UUID)
    case unsupportedModelType(MLModelType)
    case invalidInputSize(expected: Int, provided: Int)
    case predictionFailed(String)
    case timeoutError(TimeInterval)
    case notImplemented(String)
    
    public var errorDescription: String? {
        switch self {
        case .modelNotLoaded(let modelId):
            return "Model not loaded: \(modelId)"
        case .unsupportedModelType(let modelType):
            return "Unsupported model type: \(modelType.rawValue)"
        case .invalidInputSize(let expected, let provided):
            return "Invalid input size: expected \(expected), provided \(provided)"
        case .predictionFailed(let reason):
            return "Prediction failed: \(reason)"
        case .timeoutError(let timeout):
            return "Prediction timeout after \(timeout) seconds"
        case .notImplemented(let feature):
            return "Not implemented: \(feature)"
        }
    }
}

// MARK: - Helper Extensions

@available(iOS 18.0, macOS 15.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
extension Array {
    /// Split array into chunks of specified size
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}
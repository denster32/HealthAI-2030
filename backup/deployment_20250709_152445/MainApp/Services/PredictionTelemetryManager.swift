import Foundation
import Accelerate
import FirebaseCrashlytics

/// Manages telemetry for prediction system and integrates with remote telemetry processor
public final class PredictionTelemetryManager {
    private let telemetryProcessor: RemoteTelemetryProcessor
    private let predictionSystem: PredictionSystemProtocol
    private var driftAnalyzer: ModelDriftAnalyzer?
    private let crashReporter = CrashReporter.shared
    
    public init(
        telemetryConfig: TelemetryConfig,
        predictionSystem: PredictionSystemProtocol,
        batchSize: Int = 50,
        referenceDistribution: [Double]? = nil
    ) {
        self.telemetryProcessor = RemoteTelemetryProcessor(config: telemetryConfig, batchSize: batchSize)
        self.predictionSystem = predictionSystem
        
        if let referenceDistribution = referenceDistribution {
            self.driftAnalyzer = ModelDriftAnalyzer(
                referenceDistribution: referenceDistribution,
                windowSize: 100,
                alertThreshold: 0.05
            )
        }
        
        setupPredictionSystemHooks()
    }
    
    private func setupPredictionSystemHooks() {
        predictionSystem.onPrediction { [weak self] result in
            self?.handlePredictionResult(result)
        }
        
        predictionSystem.onError { [weak self] error in
            self?.handlePredictionError(error)
        }
    }
    
    private func handlePredictionResult(_ result: PredictionResult) {
        // Process regular prediction event
        let event = PredictionTelemetryEvent(
            timestamp: Date(),
            eventType: "prediction",
            predictionId: result.id,
            modelVersion: result.modelVersion,
            features: result.features,
            score: result.score,
            metadata: result.metadata
        )
        telemetryProcessor.process(event: event)
        
        // Check for model drift if analyzer is configured
        if let score = result.score, let analyzer = driftAnalyzer {
            let (driftDetected, ksStatistic, confidenceInterval) = analyzer.update(with: score)
            
            if driftDetected {
                let driftEvent = PredictionTelemetryEvent(
                    timestamp: Date(),
                    eventType: "model_drift",
                    predictionId: result.id,
                    modelVersion: result.modelVersion,
                    score: score,
                    metadata: [
                        "ks_statistic": ksStatistic,
                        "confidence_lower": confidenceInterval.lower,
                        "confidence_upper": confidenceInterval.upper,
                        "threshold": analyzer.alertThreshold
                    ]
                )
                telemetryProcessor.process(event: driftEvent)
            }
        }
    }
    
    private func handlePredictionError(_ error: PredictionError) {
        // Preserve state before handling error
        let state = [
            "predictionSystemState": predictionSystem.currentState,
            "telemetryQueueSize": telemetryProcessor.queueSize
        ]
        crashReporter.preserveState(state)
        
        // Convert legacy error to new taxonomy
        let errorCode = PredictionError(rawValue: error.type.rawValue)?.generateErrorCode(
            specific: UUID().uuidString.prefix(8).lowercased()
        ) ?? TelemetryError.prediction.generateErrorCode(
            subCategory: "LEGACY",
            specific: error.type.rawValue
        )
        
        // Record error with stack trace to crash reporter
        crashReporter.recordError(
            error,
            withStackTrace: error.stackTrace?.components(separatedBy: "\n"),
            additionalInfo: [
                "errorCode": errorCode,
                "predictionId": UUID().uuidString
            ]
        )
        
        let context = ErrorContext(
            code: errorCode,
            message: error.localizedDescription,
            severity: .medium,
            metadata: error.context ?? [:],
            stackTrace: error.stackTrace
        )
        
        let event = PredictionTelemetryEvent(
            timestamp: Date(),
            eventType: "prediction_error",
            errorType: error.type.rawValue,
            errorMessage: error.localizedDescription,
            stackTrace: error.stackTrace,
            context: error.context,
            errorCode: errorCode,
            errorContext: context.metadata
        )
        telemetryProcessor.process(event: event)
    }
    
    /// Force flush any pending telemetry events
    public func flush() {
        // Preserve state before flush
        let state = [
            "telemetryQueueSize": telemetryProcessor.queueSize,
            "lastFlushTime": Date().timeIntervalSince1970
        ]
        crashReporter.preserveState(state)
        
        telemetryProcessor.flush()
    }
}

/// Prediction system protocol for telemetry integration
public protocol PredictionSystemProtocol {
    func onPrediction(handler: @escaping (PredictionResult) -> Void)
    func onError(handler: @escaping (PredictionError) -> Void)
}

/// Prediction telemetry event structure
public struct PredictionTelemetryEvent: TelemetryEvent {
    public let timestamp: Date
    public let eventType: String
    public let predictionId: String?
    public let modelVersion: String?
    public let features: [String: Double]?
    public let score: Double?
    public let metadata: [String: Any]?
    public let errorType: String?
    public let errorMessage: String?
    public let stackTrace: String?
    public let context: [String: Any]?
    public let errorCode: String?
    public let errorContext: [String: Any]?
    
    /// Update the reference distribution for drift detection
    public func updateReferenceDistribution(_ distribution: [Double]) {
        driftAnalyzer?.updateReferenceDistribution(distribution)
    }
    
    public var payload: [String: Any] {
        var payload: [String: Any] = [
            "timestamp": timestamp.timeIntervalSince1970,
            "eventType": eventType
        ]
        
        if let predictionId = predictionId {
            payload["predictionId"] = predictionId
        }
        
        if let modelVersion = modelVersion {
            payload["modelVersion"] = modelVersion
        }
        
        if let features = features {
            payload["features"] = features
        }
        
        if let score = score {
            payload["score"] = score
        }
        
        if let metadata = metadata {
            payload["metadata"] = metadata
        }
        
        if let errorType = errorType {
            payload["errorType"] = errorType
        }
        
        if let errorMessage = errorMessage {
            payload["errorMessage"] = errorMessage
        }
        
        if let stackTrace = stackTrace {
            payload["stackTrace"] = stackTrace
        }
        
        if let context = context {
            payload["context"] = context
        }
        
        if let errorCode = errorCode {
            payload["errorCode"] = errorCode
        }
        
        if let errorContext = errorContext {
            payload["errorContext"] = errorContext
        }
        
        return payload
    }
}

/// Prediction error types
public enum PredictionErrorType: String {
    case featureExtraction = "FEATURE_EXTRACTION"
    case scoreCalculation = "SCORE_CALCULATION"
    case postProcessing = "POST_PROCESSING"
    case modelLoading = "MODEL_LOADING"
    case unknown = "UNKNOWN"
}

/// Prediction error structure
public struct PredictionError: Error {
    public let type: PredictionErrorType
    public let message: String
    public let stackTrace: String?
    public let context: [String: Any]?
    
    public var localizedDescription: String {
        return "\(type.rawValue): \(message)"
    }
}
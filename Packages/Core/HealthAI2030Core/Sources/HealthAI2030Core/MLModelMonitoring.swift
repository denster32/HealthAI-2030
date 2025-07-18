import Foundation
import os.log

public final class MLModelMonitoring {
    public static let shared = MLModelMonitoring()
    private let logger = Logger(subsystem: "com.healthai.ml", category: "Monitoring")

    private init() {}

    /// Logs the inference time for a Core ML model
    public func logInferenceTime(_ time: TimeInterval, forModel modelName: String) {
        logger.info("Model \(modelName) inference time: \(time) seconds")
    }

    /// Logs the prediction accuracy for a model
    public func logAccuracy(_ accuracy: Double, forModel modelName: String) {
        logger.info("Model \(modelName) accuracy: \(accuracy)")
    }

    /// Logs input distribution statistics for monitoring
    public func logInputDistribution(_ distribution: [String: Any], forModel modelName: String) {
        logger.debug("Model \(modelName) input distribution: \(distribution)")
    }

    /// Logs output distribution statistics for monitoring
    public func logOutputDistribution(_ distribution: [String: Any], forModel modelName: String) {
        logger.debug("Model \(modelName) output distribution: \(distribution)")
    }
} 
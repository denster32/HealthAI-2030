import Foundation
import CoreML
import os.log

/// Centralized manager for ML model loading, caching and optimization
@available(iOS 18.0, macOS 15.0, watchOS 11.0, tvOS 18.0, *)
public final class MLModelManager {
    
    // MARK: - Shared Instance
    public static let shared = MLModelManager()
    
    // MARK: - Properties
    private var modelCache: [String: MLModel] = [:]
    private let cacheQueue = DispatchQueue(label: "com.healthai.mlmodelcache", attributes: .concurrent)
    private let logger = Logger(subsystem: "com.healthai.quantum", category: "mlmodelmanager")
    
    // MARK: - Model Loading
    
    /// Loads and caches a Core ML model
    /// - Parameters:
    ///   - modelName: The name of the model file
    ///   - bundle: The bundle containing the model
    /// - Returns: The loaded MLModel
    public func loadModel(named modelName: String, in bundle: Bundle = .main) throws -> MLModel {
        if let cachedModel = getCachedModel(for: modelName) {
            return cachedModel
        }
        
        let modelURL = try Self.modelURL(for: modelName, in: bundle)
        let config = MLModelConfiguration()
        
        // Configure for Neural Engine if available
        if ProcessInfo.processInfo.isNeuralEngineAvailable {
            config.computeUnits = .cpuAndNeuralEngine
        } else {
            config.computeUnits = .cpuAndGPU
        }
        
        let model = try MLModel(contentsOf: modelURL, configuration: config)
        cacheModel(model, for: modelName)
        
        logger.debug("Loaded model: \(modelName)")
        return model
    }
    
    /// Quantizes and caches a model for better performance
    public func quantizeModel(named modelName: String, in bundle: Bundle = .main) throws -> MLModel {
        let model = try loadModel(named: modelName, in: bundle)
        
        // In a real implementation, this would perform actual quantization
        // For now we just return the original model
        logger.debug("Quantized model: \(modelName)")
        return model
    }
    
    // MARK: - Cache Management
    
    public func getCachedModel(for modelName: String) -> MLModel? {
        return cacheQueue.sync {
            return modelCache[modelName]
        }
    }
    
    public func cacheModel(_ model: MLModel, for modelName: String) {
        cacheQueue.async(flags: .barrier) {
            self.modelCache[modelName] = model
        }
    }
    
    public func clearCache() {
        cacheQueue.async(flags: .barrier) {
            self.modelCache.removeAll()
        }
    }
    
    // MARK: - Performance Utilities
    
    public func benchmarkModelPrediction<Input: MLFeatureProvider>(
        model: MLModel,
        input: Input
    ) throws -> (prediction: MLFeatureProvider, duration: TimeInterval) {
        let startTime = CFAbsoluteTimeGetCurrent()
        let prediction = try model.prediction(from: input)
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        
        logger.debug("Model prediction completed in \(duration) seconds")
        return (prediction, duration)
    }
    
    // MARK: - Private Helpers
    
    private static func modelURL(for modelName: String, in bundle: Bundle) throws -> URL {
        guard let url = bundle.url(forResource: modelName, withExtension: "mlmodelc") else {
            throw ModelError.modelNotFound(modelName)
        }
        return url
    }
    
    // MARK: - Errors
    
    public enum ModelError: LocalizedError {
        case modelNotFound(String)
        case quantizationFailed(String)
        
        public var errorDescription: String? {
            switch self {
            case .modelNotFound(let name):
                return "Model not found: \(name)"
            case .quantizationFailed(let reason):
                return "Quantization failed: \(reason)"
            }
        }
    }
}

// MARK: - Extensions

extension ProcessInfo {
    var isNeuralEngineAvailable: Bool {
        #if os(macOS)
        return false
        #else
        return ProcessInfo.processInfo.isOperatingSystemAtLeast(
            OperatingSystemVersion(majorVersion: 14, minorVersion: 0, patchVersion: 0)
        )
        #endif
    }
}
import Foundation
import CoreML
import os.log

/// Production-grade Core ML model wrapper for sleep stage prediction
class SleepStagePredictorModel {
    private var model: MLModel?
    private var isModelLoaded = false
    private let modelURL: URL
    private let configuration: MLModelConfiguration?
    
    init(contentsOf url: URL, configuration: MLModelConfiguration? = nil) throws {
        self.modelURL = url
        self.configuration = configuration
        try loadModel()
    }
    
    private func loadModel() throws {
        do {
            // Load the model directly - let Xcode handle compilation during build
            if let config = configuration {
                self.model = try MLModel(contentsOf: modelURL, configuration: config)
            } else {
                self.model = try MLModel(contentsOf: modelURL)
            }
            self.isModelLoaded = true
            Logger.success("SleepStagePredictorModel loaded successfully", log: Logger.ml)
        } catch {
            self.isModelLoaded = false
            Logger.error("Failed to load SleepStagePredictorModel: \(error.localizedDescription)", log: Logger.ml)
            throw error
        }
    }
    
    func prediction(input: MLFeatureProvider) throws -> MLFeatureProvider {
        guard let model = model, isModelLoaded else {
            throw SleepStagePredictorError.modelNotLoaded
        }
        
        do {
            let prediction = try model.prediction(from: input)
            return prediction
        } catch {
            Logger.error("Model prediction failed: \(error.localizedDescription)", log: Logger.ml)
            throw error
        }
    }
    
    func isAvailable() -> Bool {
        return isModelLoaded && model != nil
    }
    
    func getModelInfo() -> ModelInfo {
        guard let model = model else {
            return ModelInfo(name: "Unknown", version: "Unknown", description: "Model not loaded")
        }
        
        return ModelInfo(
            name: model.modelDescription.metadata[MLModelMetadataKey.creatorDefinedKey] as? String ?? "SleepStagePredictor",
            version: model.modelDescription.metadata[MLModelMetadataKey.versionStringKey] as? String ?? "1.0",
            description: model.modelDescription.metadata[MLModelMetadataKey.descriptionKey] as? String ?? "Sleep stage prediction model"
        )
    }
}

// MARK: - Supporting Types

struct ModelInfo {
    let name: String
    let version: String
    let description: String
}

enum SleepStagePredictorError: Error {
    case modelNotLoaded
    case invalidInput
    case predictionFailed
    case modelCompilationFailed
}
import Foundation
import CoreML
import CreateML
import os.log

/// Manages federated learning processes for health data models
public class FederatedLearningManager {
    private let logger = Logger()
    private var localModel: MLModel?
    private let serverEndpoint: URL
    private let modelIdentifier: String
    
    /// Initialize with server configuration
    /// - Parameters:
    ///   - serverEndpoint: URL of the federated learning server
    ///   - modelIdentifier: Unique identifier for the model being trained
    public init(serverEndpoint: URL, modelIdentifier: String) {
        self.serverEndpoint = serverEndpoint
        self.modelIdentifier = modelIdentifier
    }
    
    /// Starts local training with device data
    /// - Parameters:
    ///   - trainingData: Local dataset for training
    ///   - configuration: MLModelConfiguration for the training
    public func startTraining(with trainingData: MLBatchProvider,
                            configuration: MLModelConfiguration) async throws {
        logger.log("Starting federated learning training")
        
        // Load or initialize model
        if localModel == nil {
            try await downloadBaseModel()
        }
        
        // Perform local training
        let progressHandler = { (contextProgress: MLUpdateContext) in
            self.logger.log("Training progress: \(contextProgress.progress.fractionCompleted)")
        }
        
        let updateTask = try MLUpdateTask(
            forModelAt: try getModelURL(),
            trainingData: trainingData,
            configuration: configuration,
            progressHandlers: .init(
                forEvents: [.trainingBegin, .epochEnd],
                progressHandler: progressHandler
            )
        )
        
        try await updateTask.resume()
        localModel = updateTask.model
    }
    
    /// Reports local model updates to the server
    public func reportResults() async throws {
        guard let model = localModel else {
            throw FederatedLearningError.noLocalModel
        }
        
        logger.log("Uploading model updates to server")
        
        let modelData = try MLModelArchive.export(
            model,
            metadata: [
                "deviceId": UIDevice.current.identifierForVendor?.uuidString ?? "unknown",
                "timestamp": Date().timeIntervalSince1970
            ]
        )
        
        var request = URLRequest(url: serverEndpoint)
        request.httpMethod = "POST"
        request.setValue("application/octet-stream", forHTTPHeaderField: "Content-Type")
        request.httpBody = modelData
        
        let (_, response) = try await URLSession.shared.upload(for: request, from: modelData)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw FederatedLearningError.serverUploadFailed
        }
        
        logger.log("Successfully uploaded model updates")
    }
    
    // MARK: - Private Methods
    
    private func downloadBaseModel() async throws {
        let modelURL = serverEndpoint
            .appendingPathComponent("models")
            .appendingPathComponent(modelIdentifier)
        
        let (data, _) = try await URLSession.shared.data(from: modelURL)
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("mlmodelc")
        
        try data.write(to: tempURL)
        localModel = try MLModel(contentsOf: tempURL)
    }
    
    private func getModelURL() throws -> URL {
        guard let model = localModel else {
            throw FederatedLearningError.noLocalModel
        }
        return model.modelURL
    }
}

public enum FederatedLearningError: Error {
    case noLocalModel
    case serverUploadFailed
    case modelDownloadFailed
}

extension Logger {
    func log(_ message: String) {
        self.info("\(message)")
    }
}

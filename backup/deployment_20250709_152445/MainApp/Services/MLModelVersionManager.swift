import Foundation
import CoreML
import os

/// Manager for ML model versions, deprecation, and archival.
public class MLModelVersionManager {
    public static let shared = MLModelVersionManager()
    
    private let logger = Logger(subsystem: "com.healthai.ml", category: "model-version")
    private let fileManager = FileManager.default
    private let userDefaults = UserDefaults.standard
    
    // Keys for UserDefaults
    private let modelVersionsKey = "MLModelVersions"
    private let deprecatedModelsKey = "DeprecatedModels"
    private let archivedModelsKey = "ArchivedModels"
    
    // File paths
    private let modelsDirectory: URL
    private let archiveDirectory: URL
    
    private var modelVersions: [String: String] = [:]
    private var deprecatedModels: Set<String> = []
    private var archivedModels: Set<String> = []
    
    private init() {
        // Set up directories
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        modelsDirectory = documentsPath.appendingPathComponent("MLModels")
        archiveDirectory = documentsPath.appendingPathComponent("ArchivedModels")
        
        createDirectoriesIfNeeded()
        loadStoredData()
    }
    
    private func createDirectoriesIfNeeded() {
        try? fileManager.createDirectory(at: modelsDirectory, withIntermediateDirectories: true)
        try? fileManager.createDirectory(at: archiveDirectory, withIntermediateDirectories: true)
    }
    
    private func loadStoredData() {
        // Load model versions
        if let data = userDefaults.data(forKey: modelVersionsKey),
           let decoded = try? JSONDecoder().decode([String: String].self, from: data) {
            modelVersions = decoded
        }
        
        // Load deprecated models
        if let data = userDefaults.data(forKey: deprecatedModelsKey),
           let decoded = try? JSONDecoder().decode(Set<String>.self, from: data) {
            deprecatedModels = decoded
        }
        
        // Load archived models
        if let data = userDefaults.data(forKey: archivedModelsKey),
           let decoded = try? JSONDecoder().decode(Set<String>.self, from: data) {
            archivedModels = decoded
        }
    }
    
    private func saveData() {
        // Save model versions
        if let encoded = try? JSONEncoder().encode(modelVersions) {
            userDefaults.set(encoded, forKey: modelVersionsKey)
        }
        
        // Save deprecated models
        if let encoded = try? JSONEncoder().encode(deprecatedModels) {
            userDefaults.set(encoded, forKey: deprecatedModelsKey)
        }
        
        // Save archived models
        if let encoded = try? JSONEncoder().encode(archivedModels) {
            userDefaults.set(encoded, forKey: archivedModelsKey)
        }
    }

    /// Set version for a model.
    public func setVersion(_ version: String, forModel name: String) {
        modelVersions[name] = version
        saveData()
        logger.info("Set version \(version) for model \(name)")
    }

    /// Get version for a model.
    public func getVersion(forModel name: String) -> String? {
        return modelVersions[name]
    }
    
    /// Get all model versions
    public func getAllModelVersions() -> [String: String] {
        return modelVersions
    }
    
    /// Check if model is deprecated
    public func isModelDeprecated(_ name: String) -> Bool {
        return deprecatedModels.contains(name)
    }
    
    /// Check if model is archived
    public func isModelArchived(_ name: String) -> Bool {
        return archivedModels.contains(name)
    }

    /// Deprecate an old model version.
    public func deprecateModel(named name: String) {
        guard !deprecatedModels.contains(name) else {
            logger.warning("Model \(name) is already deprecated")
            return
        }
        
        // Add to deprecated set
        deprecatedModels.insert(name)
        
        // Remove from active versions
        modelVersions.removeValue(forKey: name)
        
        // Try to remove model file from active directory
        let modelURL = modelsDirectory.appendingPathComponent("\(name).mlmodel")
        if fileManager.fileExists(atPath: modelURL.path) {
            do {
                try fileManager.removeItem(at: modelURL)
                logger.info("Removed deprecated model file: \(name)")
            } catch {
                logger.error("Failed to remove deprecated model file \(name): \(error.localizedDescription)")
            }
        }
        
        saveData()
        logger.info("Deprecated model: \(name)")
    }
    
    /// Get all deprecated models
    public func getDeprecatedModels() -> [String] {
        return Array(deprecatedModels)
    }
    
    /// Restore a deprecated model
    public func restoreDeprecatedModel(_ name: String, version: String) {
        guard deprecatedModels.contains(name) else {
            logger.warning("Model \(name) is not deprecated")
            return
        }
        
        deprecatedModels.remove(name)
        modelVersions[name] = version
        saveData()
        logger.info("Restored deprecated model: \(name)")
    }

    /// Archive a model for off-device storage.
    public func archiveModel(named name: String) {
        guard !archivedModels.contains(name) else {
            logger.warning("Model \(name) is already archived")
            return
        }
        
        let sourceURL = modelsDirectory.appendingPathComponent("\(name).mlmodel")
        let archiveURL = archiveDirectory.appendingPathComponent("\(name).mlmodel")
        
        guard fileManager.fileExists(atPath: sourceURL.path) else {
            logger.error("Model file not found for archiving: \(name)")
            return
        }
        
        do {
            // Copy to archive directory
            try fileManager.copyItem(at: sourceURL, to: archiveURL)
            
            // Remove from active directory
            try fileManager.removeItem(at: sourceURL)
            
            // Add to archived set
            archivedModels.insert(name)
            
            // Remove from active versions
            modelVersions.removeValue(forKey: name)
            
            saveData()
            logger.info("Archived model: \(name)")
        } catch {
            logger.error("Failed to archive model \(name): \(error.localizedDescription)")
        }
    }
    
    /// Get all archived models
    public func getArchivedModels() -> [String] {
        return Array(archivedModels)
    }
    
    /// Restore an archived model
    public func restoreArchivedModel(_ name: String, version: String) {
        guard archivedModels.contains(name) else {
            logger.warning("Model \(name) is not archived")
            return
        }
        
        let archiveURL = archiveDirectory.appendingPathComponent("\(name).mlmodel")
        let restoreURL = modelsDirectory.appendingPathComponent("\(name).mlmodel")
        
        guard fileManager.fileExists(atPath: archiveURL.path) else {
            logger.error("Archived model file not found: \(name)")
            return
        }
        
        do {
            // Copy back to active directory
            try fileManager.copyItem(at: archiveURL, to: restoreURL)
            
            // Remove from archived set
            archivedModels.remove(name)
            
            // Add back to active versions
            modelVersions[name] = version
            
            saveData()
            logger.info("Restored archived model: \(name)")
        } catch {
            logger.error("Failed to restore archived model \(name): \(error.localizedDescription)")
        }
    }

    /// Retrieve an archived model's data.
    public func retrieveArchivedModel(named name: String) -> Data? {
        guard archivedModels.contains(name) else {
            logger.warning("Model \(name) is not archived")
            return nil
        }
        
        let archiveURL = archiveDirectory.appendingPathComponent("\(name).mlmodel")
        
        guard fileManager.fileExists(atPath: archiveURL.path) else {
            logger.error("Archived model file not found: \(name)")
            return nil
        }
        
        do {
            let data = try Data(contentsOf: archiveURL)
            logger.info("Retrieved archived model data: \(name)")
            return data
        } catch {
            logger.error("Failed to retrieve archived model \(name): \(error.localizedDescription)")
            return nil
        }
    }
    
    /// Get model file size
    public func getModelFileSize(_ name: String) -> Int64? {
        let modelURL = modelsDirectory.appendingPathComponent("\(name).mlmodel")
        
        guard fileManager.fileExists(atPath: modelURL.path) else {
            return nil
        }
        
        do {
            let attributes = try fileManager.attributesOfItem(atPath: modelURL.path)
            return attributes[.size] as? Int64
        } catch {
            logger.error("Failed to get file size for model \(name): \(error.localizedDescription)")
            return nil
        }
    }
    
    /// Get total size of all models
    public func getTotalModelsSize() -> Int64 {
        var totalSize: Int64 = 0
        
        for (name, _) in modelVersions {
            if let size = getModelFileSize(name) {
                totalSize += size
            }
        }
        
        return totalSize
    }
    
    /// Clean up old model versions
    public func cleanupOldVersions(keepingLatest: Int = 3) {
        let sortedModels = modelVersions.sorted { $0.value < $1.value }
        
        if sortedModels.count > keepingLatest {
            let modelsToRemove = sortedModels.dropLast(keepingLatest)
            
            for (name, _) in modelsToRemove {
                deprecateModel(named: name)
            }
            
            logger.info("Cleaned up \(modelsToRemove.count) old model versions")
        }
    }
    
    /// Get model statistics
    public func getModelStatistics() -> ModelStatistics {
        let activeModels = modelVersions.count
        let deprecatedCount = deprecatedModels.count
        let archivedCount = archivedModels.count
        let totalSize = getTotalModelsSize()
        
        return ModelStatistics(
            activeModels: activeModels,
            deprecatedModels: deprecatedCount,
            archivedModels: archivedCount,
            totalSize: totalSize
        )
    }
}

/// Model statistics
public struct ModelStatistics {
    public let activeModels: Int
    public let deprecatedModels: Int
    public let archivedModels: Int
    public let totalSize: Int64
} 
import Foundation
import CryptoKit
import Security
import os

/// Manager responsible for encrypted storage and retrieval of ML models.
public class MLModelStorageManager {
    public static let shared = MLModelStorageManager()
    
    private let fileManager = FileManager.default
    private let logger = Logger(subsystem: "com.healthai.ml", category: "model-storage")
    
    // Encryption key management
    private let keychainService = "com.healthai.ml.encryption"
    private let keychainAccount = "model-encryption-key"
    
    private init() {}
    
    /// Encryption key for model data
    private var encryptionKey: SymmetricKey? {
        get {
            return loadEncryptionKey()
        }
    }
    
    /// Generates and stores a new encryption key
    private func generateAndStoreEncryptionKey() -> SymmetricKey {
        let key = SymmetricKey(size: .bits256)
        
        // Store in keychain
        let keyData = key.withUnsafeBytes { Data($0) }
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
            kSecValueData as String: keyData,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        // Delete existing key if present
        SecItemDelete(query as CFDictionary)
        
        // Add new key
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            logger.error("Failed to store encryption key in keychain: \(status)")
            fatalError("Critical: Cannot store encryption key")
        }
        
        logger.info("Generated and stored new encryption key")
        return key
    }
    
    /// Loads encryption key from keychain
    private func loadEncryptionKey() -> SymmetricKey? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let keyData = result as? Data else {
            logger.warning("No encryption key found in keychain, generating new one")
            return generateAndStoreEncryptionKey()
        }
        
        return SymmetricKey(data: keyData)
    }
    
    /// Encrypts data using AES-GCM
    private func encryptData(_ data: Data) throws -> Data {
        guard let key = encryptionKey else {
            throw ModelStorageError.encryptionKeyNotFound
        }
        
        let sealedBox = try AES.GCM.seal(data, using: key)
        return sealedBox.combined ?? Data()
    }
    
    /// Decrypts data using AES-GCM
    private func decryptData(_ encryptedData: Data) throws -> Data {
        guard let key = encryptionKey else {
            throw ModelStorageError.encryptionKeyNotFound
        }
        
        let sealedBox = try AES.GCM.SealedBox(combined: encryptedData)
        return try AES.GCM.open(sealedBox, using: key)
    }

    /// Stores model data with encryption.
    public func storeModel(data: Data, named name: String) throws {
        let url = try modelsDirectory().appendingPathComponent("\(name).mlmodel")
        
        do {
            // Encrypt the model data
            let encryptedData = try encryptData(data)
            
            // Write encrypted data to disk
            try encryptedData.write(to: url, options: .atomic)
            
            logger.info("Successfully stored encrypted model: \(name)")
        } catch {
            logger.error("Failed to store encrypted model \(name): \(error.localizedDescription)")
            throw ModelStorageError.encryptionFailed(error)
        }
    }

    /// Loads and decrypts model data.
    public func loadModel(named name: String) throws -> Data {
        let url = try modelsDirectory().appendingPathComponent("\(name).mlmodel")
        
        guard fileManager.fileExists(atPath: url.path) else {
            throw ModelStorageError.modelNotFound(name)
        }
        
        do {
            // Read encrypted data from disk
            let encryptedData = try Data(contentsOf: url)
            
            // Decrypt the model data
            let decryptedData = try decryptData(encryptedData)
            
            logger.info("Successfully loaded and decrypted model: \(name)")
            return decryptedData
        } catch {
            logger.error("Failed to load/decrypt model \(name): \(error.localizedDescription)")
            throw ModelStorageError.decryptionFailed(error)
        }
    }
    
    /// Checks if a model exists
    public func modelExists(named name: String) -> Bool {
        do {
            let url = try modelsDirectory().appendingPathComponent("\(name).mlmodel")
            return fileManager.fileExists(atPath: url.path)
        } catch {
            return false
        }
    }
    
    /// Deletes a model
    public func deleteModel(named name: String) throws {
        let url = try modelsDirectory().appendingPathComponent("\(name).mlmodel")
        
        guard fileManager.fileExists(atPath: url.path) else {
            throw ModelStorageError.modelNotFound(name)
        }
        
        do {
            try fileManager.removeItem(at: url)
            logger.info("Successfully deleted model: \(name)")
        } catch {
            logger.error("Failed to delete model \(name): \(error.localizedDescription)")
            throw ModelStorageError.deletionFailed(error)
        }
    }
    
    /// Gets the size of a model
    public func getModelSize(named name: String) throws -> Int64 {
        let url = try modelsDirectory().appendingPathComponent("\(name).mlmodel")
        
        guard fileManager.fileExists(atPath: url.path) else {
            throw ModelStorageError.modelNotFound(name)
        }
        
        do {
            let attributes = try fileManager.attributesOfItem(atPath: url.path)
            return attributes[.size] as? Int64 ?? 0
        } catch {
            logger.error("Failed to get size for model \(name): \(error.localizedDescription)")
            throw ModelStorageError.sizeRetrievalFailed(error)
        }
    }
    
    /// Gets total size of all models
    public func getTotalModelsSize() throws -> Int64 {
        let directory = try modelsDirectory()
        let contents = try fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: [.fileSizeKey])
        
        var totalSize: Int64 = 0
        for url in contents {
            if url.pathExtension == "mlmodel" {
                let attributes = try fileManager.attributesOfItem(atPath: url.path)
                totalSize += attributes[.size] as? Int64 ?? 0
            }
        }
        
        return totalSize
    }
    
    /// Lists all stored models
    public func listStoredModels() throws -> [String] {
        let directory = try modelsDirectory()
        let contents = try fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
        
        return contents
            .filter { $0.pathExtension == "mlmodel" }
            .map { $0.deletingPathExtension().lastPathComponent }
    }
    
    /// Validates model integrity
    public func validateModelIntegrity(named name: String) throws -> Bool {
        do {
            let data = try loadModel(named: name)
            return !data.isEmpty
        } catch {
            logger.error("Model integrity validation failed for \(name): \(error.localizedDescription)")
            return false
        }
    }
    
    /// Backs up a model to a secure location
    public func backupModel(named name: String, to backupURL: URL) throws {
        let sourceURL = try modelsDirectory().appendingPathComponent("\(name).mlmodel")
        
        guard fileManager.fileExists(atPath: sourceURL.path) else {
            throw ModelStorageError.modelNotFound(name)
        }
        
        do {
            try fileManager.copyItem(at: sourceURL, to: backupURL)
            logger.info("Successfully backed up model \(name) to \(backupURL.path)")
        } catch {
            logger.error("Failed to backup model \(name): \(error.localizedDescription)")
            throw ModelStorageError.backupFailed(error)
        }
    }
    
    /// Restores a model from backup
    public func restoreModel(named name: String, from backupURL: URL) throws {
        let destinationURL = try modelsDirectory().appendingPathComponent("\(name).mlmodel")
        
        guard fileManager.fileExists(atPath: backupURL.path) else {
            throw ModelStorageError.backupNotFound(backupURL.path)
        }
        
        do {
            // Remove existing model if present
            if fileManager.fileExists(atPath: destinationURL.path) {
                try fileManager.removeItem(at: destinationURL)
            }
            
            try fileManager.copyItem(at: backupURL, to: destinationURL)
            logger.info("Successfully restored model \(name) from backup")
        } catch {
            logger.error("Failed to restore model \(name): \(error.localizedDescription)")
            throw ModelStorageError.restoreFailed(error)
        }
    }

    private func modelsDirectory() throws -> URL {
        let directory = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("MLModels", isDirectory: true)
        if !fileManager.fileExists(atPath: directory.path) {
            try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        }
        return directory
    }
}

/// Model storage errors
public enum ModelStorageError: Error, LocalizedError {
    case encryptionKeyNotFound
    case encryptionFailed(Error)
    case decryptionFailed(Error)
    case modelNotFound(String)
    case deletionFailed(Error)
    case sizeRetrievalFailed(Error)
    case backupFailed(Error)
    case backupNotFound(String)
    case restoreFailed(Error)
    
    public var errorDescription: String? {
        switch self {
        case .encryptionKeyNotFound:
            return "Encryption key not found in keychain"
        case .encryptionFailed(let error):
            return "Encryption failed: \(error.localizedDescription)"
        case .decryptionFailed(let error):
            return "Decryption failed: \(error.localizedDescription)"
        case .modelNotFound(let name):
            return "Model not found: \(name)"
        case .deletionFailed(let error):
            return "Model deletion failed: \(error.localizedDescription)"
        case .sizeRetrievalFailed(let error):
            return "Failed to retrieve model size: \(error.localizedDescription)"
        case .backupFailed(let error):
            return "Model backup failed: \(error.localizedDescription)"
        case .backupNotFound(let path):
            return "Backup not found at: \(path)"
        case .restoreFailed(let error):
            return "Model restore failed: \(error.localizedDescription)"
        }
    }
} 
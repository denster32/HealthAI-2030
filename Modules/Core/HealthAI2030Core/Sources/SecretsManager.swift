import Foundation
import Security
import CommonCrypto
import AWSSecretsManager
import AzureKeyVault
import GoogleCloudSecretManager

private struct KeychainConfiguration {
    static let serviceName = "com.healthai2030.secrets"
    static let encryptionKeyTag = "com.healthai2030.encryptionKey"
    static let keyRotationInterval: TimeInterval = 30 * 24 * 60 * 60 // 30 days
}

public class SecretsManager {
    public enum Provider {
        case aws
        case azure
        case gcp
        case local
    }
    
    public enum SecretsError: Error {
        case keychainError(OSStatus)
        case encryptionError
        case decryptionError
        case keyGenerationError
        case secretNotFound
    }
    
    public static let shared = SecretsManager()
    private var provider: Provider = .aws
    private var awsManager: AWSSecretsManager?
    private var azureManager: AzureKeyVaultClient?
    private var gcpManager: GoogleCloudSecretManager?
    private var secretCache: [String: Data] = [:] // Encrypted cache
    private let cacheTTL: TimeInterval = 3600 // 1 hour cache
    private var lastFetchTimes: [String: Date] = [:]
    private var lastKeyRotation: Date = Date()
    
    private init() {
        // Default to AWS
        self.awsManager = AWSSecretsManager()
        rotateEncryptionKeyIfNeeded()
    }
    
    private func rotateEncryptionKeyIfNeeded() {
        let now = Date()
        if now.timeIntervalSince(lastKeyRotation) > KeychainConfiguration.keyRotationInterval {
            do {
                try generateNewEncryptionKey()
                lastKeyRotation = now
                logSecurityEvent("Rotated encryption key", name: nil)
            } catch {
                logSecurityEvent("Failed to rotate encryption key: \(error)", name: nil)
            }
        }
    }
    
    private func generateNewEncryptionKey() throws {
        var keyData = Data(count: kCCKeySizeAES256)
        let status = keyData.withUnsafeMutableBytes {
            SecRandomCopyBytes(kSecRandomDefault, kCCKeySizeAES256, $0.baseAddress!)
        }
        
        guard status == errSecSuccess else {
            throw SecretsError.keyGenerationError
        }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrKeyType as String: kSecAttrKeyTypeAES,
            kSecAttrApplicationTag as String: KeychainConfiguration.encryptionKeyTag,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
            kSecValueData as String: keyData
        ]
        
        SecItemDelete(query as CFDictionary)
        let statusAdd = SecItemAdd(query as CFDictionary, nil)
        guard statusAdd == errSecSuccess else {
            throw SecretsError.keychainError(statusAdd)
        }
    }
    
    public func configure(provider: Provider) {
        self.provider = provider
        switch provider {
        case .aws:
            self.awsManager = AWSSecretsManager()
        case .azure:
            self.azureManager = AzureKeyVaultClient()
        case .gcp:
            self.gcpManager = GoogleCloudSecretManager()
        }
    }
    
    public func getSecret(named name: String) -> String? {
        // Check encrypted cache first
        if let cachedData = secretCache[name],
           let lastFetch = lastFetchTimes[name],
           Date().timeIntervalSince(lastFetch) < cacheTTL {
            do {
                let decrypted = try decrypt(data: cachedData)
                return String(data: decrypted, encoding: .utf8)
            } catch {
                logSecurityEvent("Failed to decrypt cached secret: \(error)", name: name)
            }
        }
        
        // Try loading from keychain
        do {
            if let keychainValue = try? loadFromKeychain(name: name) {
                return keychainValue
            }
        } catch {
            logSecurityEvent("Keychain access failed: \(error)", name: name)
        }
        
        // Fallback to provider
        do {
            var secretValue: String?
            
            switch provider {
            case .aws:
                guard let awsManager = awsManager else { return nil }
                let input = GetSecretValueInput(secretId: name)
                let result = try awsManager.getSecretValue(input)
                secretValue = result.secretString
                
            case .azure:
                guard let azureManager = azureManager else { return nil }
                secretValue = try azureManager.getSecret(name: name)
                
            case .gcp:
                guard let gcpManager = gcpManager else { return nil }
                secretValue = try gcpManager.accessSecretVersion(name: name)
            }
            
            if let secretValue = secretValue {
                try updateCache(name: name, value: secretValue)
                return secretValue
            }
        } catch {
            logSecurityEvent("Failed to fetch secret from provider: \(error)", name: name)
        }
        
        // Final fallback to environment variable
        return ProcessInfo.processInfo.environment[name]
    }
    
    // MARK: - Keychain Operations
    
    private func saveToKeychain(name: String, value: String) throws {
        guard let valueData = value.data(using: .utf8) else {
            throw SecretsError.encryptionError
        }
        
        let encryptedData = try encrypt(data: valueData)
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: KeychainConfiguration.serviceName,
            kSecAttrAccount as String: name,
            kSecValueData as String: encryptedData,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]
        
        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw SecretsError.keychainError(status)
        }
        
        logSecurityEvent("Saved secret to keychain", name: name)
    }
    
    private func loadFromKeychain(name: String) throws -> String {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: KeychainConfiguration.serviceName,
            kSecAttrAccount as String: name,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess,
              let encryptedData = item as? Data else {
            throw SecretsError.secretNotFound
        }
        
        let decryptedData = try decrypt(data: encryptedData)
        guard let value = String(data: decryptedData, encoding: .utf8) else {
            throw SecretsError.decryptionError
        }
        
        logSecurityEvent("Loaded secret from keychain", name: name)
        return value
    }
    
    // MARK: - Encryption
    
    private func encrypt(data: Data) throws -> Data {
        guard let key = try getEncryptionKey() else {
            throw SecretsError.keyGenerationError
        }
        
        var encryptedData = Data(count: data.count + kCCBlockSizeAES128)
        var numBytesEncrypted = 0
        
        let status = key.withUnsafeBytes { keyBytes in
            data.withUnsafeBytes { dataBytes in
                encryptedData.withUnsafeMutableBytes { encryptedBytes in
                    CCCrypt(
                        CCOperation(kCCEncrypt),
                        CCAlgorithm(kCCAlgorithmAES),
                        CCOptions(kCCOptionPKCS7Padding),
                        keyBytes.baseAddress, kCCKeySizeAES256,
                        nil,
                        dataBytes.baseAddress, data.count,
                        encryptedBytes.baseAddress, encryptedData.count,
                        &numBytesEncrypted
                    )
                }
            }
        }
        
        guard status == kCCSuccess else {
            throw SecretsError.encryptionError
        }
        
        encryptedData.count = numBytesEncrypted
        return encryptedData
    }
    
    private func decrypt(data: Data) throws -> Data {
        guard let key = try getEncryptionKey() else {
            throw SecretsError.keyGenerationError
        }
        
        var decryptedData = Data(count: data.count)
        var numBytesDecrypted = 0
        
        let status = key.withUnsafeBytes { keyBytes in
            data.withUnsafeBytes { dataBytes in
                decryptedData.withUnsafeMutableBytes { decryptedBytes in
                    CCCrypt(
                        CCOperation(kCCDecrypt),
                        CCAlgorithm(kCCAlgorithmAES),
                        CCOptions(kCCOptionPKCS7Padding),
                        keyBytes.baseAddress, kCCKeySizeAES256,
                        nil,
                        dataBytes.baseAddress, data.count,
                        decryptedBytes.baseAddress, decryptedData.count,
                        &numBytesDecrypted
                    )
                }
            }
        }
        
        guard status == kCCSuccess else {
            throw SecretsError.decryptionError
        }
        
        decryptedData.count = numBytesDecrypted
        return decryptedData
    }
    
    private func updateCache(name: String, value: String) throws {
        let encryptedValue = try encrypt(data: value.data(using: .utf8)!)
        secretCache[name] = encryptedValue
        lastFetchTimes[name] = Date()
        try saveToKeychain(name: name, value: value)
    }
    
    private func logSecurityEvent(_ message: String, name: String?) {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let logMessage = "[\(timestamp)] SECURITY: \(message)\(name != nil ? " - Secret: \(name!)" : "")"
        
        // Log to console
        print(logMessage)
        
        // Log to file
        let logFile = "security.log"
        if let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let logURL = documentsDir.appendingPathComponent(logFile)
            if let data = (logMessage + "\n").data(using: .utf8) {
                if FileManager.default.fileExists(atPath: logURL.path) {
                    if let fileHandle = try? FileHandle(forWritingTo: logURL) {
                        fileHandle.seekToEndOfFile()
                        fileHandle.write(data)
                        fileHandle.closeFile()
                    }
                } else {
                    try? data.write(to: logURL)
                }
            }
        }
    }
    
    private func getEncryptionKey() throws -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: KeychainConfiguration.encryptionKeyTag,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        
        if status == errSecSuccess {
            return item as? Data
        } else if status == errSecItemNotFound {
            return nil
        } else {
            throw SecretsError.keychainError(status)
        }
    }
}

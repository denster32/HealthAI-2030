import Foundation
import CryptoKit
import Security

// MARK: - Export Encryption Manager

@available(iOS 17.0, macOS 14.0, watchOS 10.0, tvOS 17.0, *)
class ExportEncryptionManager {
    static let shared = ExportEncryptionManager()
    
    // MARK: - Constants
    
    private enum Constants {
        static let keyDerivationRounds = 100_000
        static let saltLength = 32
        static let ivLength = 16
        static let tagLength = 16
        static let keyLength = 32 // AES-256
        static let encryptedFileExtension = ".encrypted"
        static let metadataFileExtension = ".encmeta"
    }
    
    // MARK: - Encryption Models
    
    struct EncryptionMetadata: Codable {
        let algorithm: String
        let keyDerivation: String
        let salt: Data
        let iv: Data
        let iterations: Int
        let encryptedAt: Date
        let originalFileName: String
        let originalFileSize: Int64
        let encryptedFileSize: Int64
        let checksum: String
    }
    
    struct EncryptionResult {
        let encryptedFileURL: URL
        let metadataFileURL: URL
        let metadata: EncryptionMetadata
    }
    
    enum EncryptionError: Error, LocalizedError {
        case invalidPassword
        case keyDerivationFailed
        case encryptionFailed
        case decryptionFailed
        case invalidFileFormat
        case metadataNotFound
        case checksumMismatch
        case unsupportedAlgorithm
        case fileAccessError(Error)
        
        var errorDescription: String? {
            switch self {
            case .invalidPassword:
                return "Invalid or empty password provided"
            case .keyDerivationFailed:
                return "Failed to derive encryption key from password"
            case .encryptionFailed:
                return "Failed to encrypt file"
            case .decryptionFailed:
                return "Failed to decrypt file - check your password"
            case .invalidFileFormat:
                return "Invalid encrypted file format"
            case .metadataNotFound:
                return "Encryption metadata not found"
            case .checksumMismatch:
                return "File integrity check failed"
            case .unsupportedAlgorithm:
                return "Unsupported encryption algorithm"
            case .fileAccessError(let error):
                return "File access error: \(error.localizedDescription)"
            }
        }
    }
    
    // MARK: - Private Properties
    
    private let fileManager = FileManager.default
    private let queue = DispatchQueue(label: "com.healthai2030.encryption", qos: .userInitiated)
    
    // MARK: - Initialization
    
    private init() {}
    
    // MARK: - Public Encryption Methods
    
    /// Encrypt a file with AES-256-GCM using password-based key derivation
    func encryptFile(at sourceURL: URL, password: String) async throws -> URL {
        return try await withCheckedThrowingContinuation { continuation in
            queue.async {
                do {
                    let result = try self.performFileEncryption(sourceURL: sourceURL, password: password)
                    continuation.resume(returning: result.encryptedFileURL)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// Decrypt a file that was encrypted with encryptFile
    func decryptFile(at encryptedURL: URL, password: String, outputURL: URL) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            queue.async {
                do {
                    try self.performFileDecryption(encryptedURL: encryptedURL, password: password, outputURL: outputURL)
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// Encrypt data in memory (for small data chunks)
    func encryptData(_ data: Data, password: String) async throws -> Data {
        return try await withCheckedThrowingContinuation { continuation in
            queue.async {
                do {
                    let result = try self.performDataEncryption(data: data, password: password)
                    continuation.resume(returning: result)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// Decrypt data in memory
    func decryptData(_ encryptedData: Data, password: String) async throws -> Data {
        return try await withCheckedThrowingContinuation { continuation in
            queue.async {
                do {
                    let result = try self.performDataDecryption(encryptedData: encryptedData, password: password)
                    continuation.resume(returning: result)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// Verify if a file is encrypted by this manager
    func isFileEncrypted(at url: URL) -> Bool {
        let metadataURL = getMetadataURL(for: url)
        return fileManager.fileExists(atPath: metadataURL.path)
    }
    
    /// Get encryption metadata for an encrypted file
    func getEncryptionMetadata(for encryptedURL: URL) throws -> EncryptionMetadata {
        let metadataURL = getMetadataURL(for: encryptedURL)
        
        guard fileManager.fileExists(atPath: metadataURL.path) else {
            throw EncryptionError.metadataNotFound
        }
        
        do {
            let metadataData = try Data(contentsOf: metadataURL)
            let metadata = try JSONDecoder().decode(EncryptionMetadata.self, from: metadataData)
            return metadata
        } catch {
            throw EncryptionError.fileAccessError(error)
        }
    }
    
    // MARK: - Private File Encryption
    
    private func performFileEncryption(sourceURL: URL, password: String) throws -> EncryptionResult {
        guard !password.isEmpty else {
            throw EncryptionError.invalidPassword
        }
        
        // Read source file
        let sourceData: Data
        do {
            sourceData = try Data(contentsOf: sourceURL)
        } catch {
            throw EncryptionError.fileAccessError(error)
        }
        
        // Generate salt and IV
        let salt = generateRandomData(length: Constants.saltLength)
        let iv = generateRandomData(length: Constants.ivLength)
        
        // Derive key from password
        let key = try deriveKey(from: password, salt: salt)
        
        // Encrypt data
        let encryptedData = try encryptDataWithKey(sourceData, key: key, iv: iv)
        
        // Calculate checksum of original data
        let checksum = calculateSHA256(data: sourceData)
        
        // Create metadata
        let originalFileName = sourceURL.lastPathComponent
        let metadata = EncryptionMetadata(
            algorithm: "AES-256-GCM",
            keyDerivation: "PBKDF2-SHA256",
            salt: salt,
            iv: iv,
            iterations: Constants.keyDerivationRounds,
            encryptedAt: Date(),
            originalFileName: originalFileName,
            originalFileSize: Int64(sourceData.count),
            encryptedFileSize: Int64(encryptedData.count),
            checksum: checksum
        )
        
        // Write encrypted file
        let encryptedFileName = originalFileName + Constants.encryptedFileExtension
        let encryptedURL = sourceURL.deletingLastPathComponent().appendingPathComponent(encryptedFileName)
        
        do {
            try encryptedData.write(to: encryptedURL)
        } catch {
            throw EncryptionError.fileAccessError(error)
        }
        
        // Write metadata file
        let metadataURL = getMetadataURL(for: encryptedURL)
        do {
            let metadataData = try JSONEncoder().encode(metadata)
            try metadataData.write(to: metadataURL)
        } catch {
            // Clean up encrypted file if metadata write fails
            try? fileManager.removeItem(at: encryptedURL)
            throw EncryptionError.fileAccessError(error)
        }
        
        return EncryptionResult(
            encryptedFileURL: encryptedURL,
            metadataFileURL: metadataURL,
            metadata: metadata
        )
    }
    
    private func performFileDecryption(encryptedURL: URL, password: String, outputURL: URL) throws {
        guard !password.isEmpty else {
            throw EncryptionError.invalidPassword
        }
        
        // Load metadata
        let metadata = try getEncryptionMetadata(for: encryptedURL)
        
        // Verify algorithm support
        guard metadata.algorithm == "AES-256-GCM" else {
            throw EncryptionError.unsupportedAlgorithm
        }
        
        // Read encrypted data
        let encryptedData: Data
        do {
            encryptedData = try Data(contentsOf: encryptedURL)
        } catch {
            throw EncryptionError.fileAccessError(error)
        }
        
        // Derive key from password
        let key = try deriveKey(from: password, salt: metadata.salt)
        
        // Decrypt data
        let decryptedData = try decryptDataWithKey(encryptedData, key: key, iv: metadata.iv)
        
        // Verify checksum
        let checksum = calculateSHA256(data: decryptedData)
        guard checksum == metadata.checksum else {
            throw EncryptionError.checksumMismatch
        }
        
        // Write decrypted file
        do {
            try decryptedData.write(to: outputURL)
        } catch {
            throw EncryptionError.fileAccessError(error)
        }
    }
    
    // MARK: - Private Data Encryption
    
    private func performDataEncryption(data: Data, password: String) throws -> Data {
        guard !password.isEmpty else {
            throw EncryptionError.invalidPassword
        }
        
        // Generate salt and IV
        let salt = generateRandomData(length: Constants.saltLength)
        let iv = generateRandomData(length: Constants.ivLength)
        
        // Derive key from password
        let key = try deriveKey(from: password, salt: salt)
        
        // Encrypt data
        let encryptedPayload = try encryptDataWithKey(data, key: key, iv: iv)
        
        // Create encrypted data structure: salt + iv + encrypted_data
        var result = Data()
        result.append(salt)
        result.append(iv)
        result.append(encryptedPayload)
        
        return result
    }
    
    private func performDataDecryption(encryptedData: Data, password: String) throws -> Data {
        guard !password.isEmpty else {
            throw EncryptionError.invalidPassword
        }
        
        // Ensure minimum data length
        let minimumLength = Constants.saltLength + Constants.ivLength + Constants.tagLength
        guard encryptedData.count >= minimumLength else {
            throw EncryptionError.invalidFileFormat
        }
        
        // Extract components
        let salt = encryptedData.subdata(in: 0..<Constants.saltLength)
        let iv = encryptedData.subdata(in: Constants.saltLength..<(Constants.saltLength + Constants.ivLength))
        let encryptedPayload = encryptedData.subdata(in: (Constants.saltLength + Constants.ivLength)..<encryptedData.count)
        
        // Derive key from password
        let key = try deriveKey(from: password, salt: salt)
        
        // Decrypt data
        return try decryptDataWithKey(encryptedPayload, key: key, iv: iv)
    }
    
    // MARK: - Core Cryptographic Operations
    
    private func deriveKey(from password: String, salt: Data) throws -> SymmetricKey {
        guard let passwordData = password.data(using: .utf8) else {
            throw EncryptionError.keyDerivationFailed
        }
        
        do {
            let key = try PBKDF2.deriveKey(
                from: passwordData,
                salt: salt,
                keyLength: Constants.keyLength,
                rounds: Constants.keyDerivationRounds
            )
            return SymmetricKey(data: key)
        } catch {
            throw EncryptionError.keyDerivationFailed
        }
    }
    
    private func encryptDataWithKey(_ data: Data, key: SymmetricKey, iv: Data) throws -> Data {
        do {
            let sealedBox = try AES.GCM.seal(data, using: key, nonce: AES.GCM.Nonce(data: iv))
            
            // Combine ciphertext and tag
            guard let ciphertext = sealedBox.ciphertext else {
                throw EncryptionError.encryptionFailed
            }
            
            var result = Data()
            result.append(ciphertext)
            result.append(sealedBox.tag)
            
            return result
        } catch {
            throw EncryptionError.encryptionFailed
        }
    }
    
    private func decryptDataWithKey(_ encryptedData: Data, key: SymmetricKey, iv: Data) throws -> Data {
        guard encryptedData.count >= Constants.tagLength else {
            throw EncryptionError.invalidFileFormat
        }
        
        // Split ciphertext and tag
        let ciphertext = encryptedData.subdata(in: 0..<(encryptedData.count - Constants.tagLength))
        let tag = encryptedData.subdata(in: (encryptedData.count - Constants.tagLength)..<encryptedData.count)
        
        do {
            let nonce = try AES.GCM.Nonce(data: iv)
            let sealedBox = try AES.GCM.SealedBox(nonce: nonce, ciphertext: ciphertext, tag: tag)
            let decryptedData = try AES.GCM.open(sealedBox, using: key)
            
            return decryptedData
        } catch {
            throw EncryptionError.decryptionFailed
        }
    }
    
    // MARK: - Utility Methods
    
    private func generateRandomData(length: Int) -> Data {
        var data = Data(count: length)
        let result = data.withUnsafeMutableBytes {
            SecRandomCopyBytes(kSecRandomDefault, length, $0.baseAddress!)
        }
        
        guard result == errSecSuccess else {
            // Fallback to CryptoKit random generation
            return Data((0..<length).map { _ in UInt8.random(in: 0...255) })
        }
        
        return data
    }
    
    private func calculateSHA256(data: Data) -> String {
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    private func getMetadataURL(for encryptedURL: URL) -> URL {
        let baseName = encryptedURL.deletingPathExtension().lastPathComponent
        let metadataFileName = baseName + Constants.metadataFileExtension
        return encryptedURL.deletingLastPathComponent().appendingPathComponent(metadataFileName)
    }
    
    // MARK: - File Management
    
    /// Clean up encryption artifacts (metadata files, temporary files)
    func cleanupEncryptionArtifacts(for fileURL: URL) throws {
        let metadataURL = getMetadataURL(for: fileURL)
        
        if fileManager.fileExists(atPath: metadataURL.path) {
            try fileManager.removeItem(at: metadataURL)
        }
    }
    
    /// Validate password strength
    func validatePasswordStrength(_ password: String) -> PasswordStrength {
        guard password.count >= 8 else {
            return .weak
        }
        
        var score = 0
        
        // Length bonus
        if password.count >= 12 { score += 1 }
        if password.count >= 16 { score += 1 }
        
        // Character variety
        if password.rangeOfCharacter(from: .lowercaseLetters) != nil { score += 1 }
        if password.rangeOfCharacter(from: .uppercaseLetters) != nil { score += 1 }
        if password.rangeOfCharacter(from: .decimalDigits) != nil { score += 1 }
        if password.rangeOfCharacter(from: CharacterSet(charactersIn: "!@#$%^&*()_+-=[]{}|;:,.<>?")) != nil { score += 1 }
        
        switch score {
        case 0...2:
            return .weak
        case 3...4:
            return .medium
        case 5...6:
            return .strong
        default:
            return .veryStrong
        }
    }
    
    enum PasswordStrength: String, CaseIterable {
        case weak = "Weak"
        case medium = "Medium"
        case strong = "Strong"
        case veryStrong = "Very Strong"
        
        var color: String {
            switch self {
            case .weak: return "red"
            case .medium: return "orange"
            case .strong: return "green"
            case .veryStrong: return "blue"
            }
        }
        
        var recommendations: [String] {
            switch self {
            case .weak:
                return [
                    "Use at least 8 characters",
                    "Include uppercase and lowercase letters",
                    "Add numbers and special characters"
                ]
            case .medium:
                return [
                    "Consider using a longer password",
                    "Add more character variety"
                ]
            case .strong:
                return [
                    "Good password strength",
                    "Consider adding more characters for maximum security"
                ]
            case .veryStrong:
                return [
                    "Excellent password strength",
                    "Your data is well protected"
                ]
            }
        }
    }
}

// MARK: - PBKDF2 Implementation

@available(iOS 17.0, macOS 14.0, watchOS 10.0, tvOS 17.0, *)
private enum PBKDF2 {
    static func deriveKey(from password: Data, salt: Data, keyLength: Int, rounds: Int) throws -> Data {
        var derivedKey = Data(count: keyLength)
        
        let status = derivedKey.withUnsafeMutableBytes { derivedKeyBytes in
            salt.withUnsafeBytes { saltBytes in
                password.withUnsafeBytes { passwordBytes in
                    CCKeyDerivationPBKDF(
                        CCPBKDFAlgorithm(kCCPBKDF2),
                        passwordBytes.baseAddress?.assumingMemoryBound(to: Int8.self),
                        password.count,
                        saltBytes.baseAddress?.assumingMemoryBound(to: UInt8.self),
                        salt.count,
                        CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA256),
                        UInt32(rounds),
                        derivedKeyBytes.baseAddress?.assumingMemoryBound(to: UInt8.self),
                        keyLength
                    )
                }
            }
        }
        
        guard status == kCCSuccess else {
            throw ExportEncryptionManager.EncryptionError.keyDerivationFailed
        }
        
        return derivedKey
    }
}

// MARK: - CommonCrypto Bridge

import CommonCrypto

private let kCCSuccess = Int32(0)

private func CCKeyDerivationPBKDF(
    _ algorithm: CCPBKDFAlgorithm,
    _ password: UnsafePointer<Int8>?,
    _ passwordLen: Int,
    _ salt: UnsafePointer<UInt8>?,
    _ saltLen: Int,
    _ prf: CCPseudoRandomAlgorithm,
    _ rounds: UInt32,
    _ derivedKey: UnsafeMutablePointer<UInt8>?,
    _ derivedKeyLen: Int
) -> Int32 {
    return CCKeyDerivationPBKDF(
        algorithm,
        password,
        passwordLen,
        salt,
        saltLen,
        prf,
        rounds,
        derivedKey,
        derivedKeyLen
    )
}

// MARK: - Extensions

@available(iOS 17.0, macOS 14.0, watchOS 10.0, tvOS 17.0, *)
extension ExportEncryptionManager.EncryptionMetadata {
    var formattedSize: String {
        return ByteCountFormatter.string(fromByteCount: encryptedFileSize, countStyle: .file)
    }
    
    var compressionRatio: Double {
        guard originalFileSize > 0 else { return 0 }
        return Double(encryptedFileSize) / Double(originalFileSize)
    }
    
    var isRecentlyEncrypted: Bool {
        return Date().timeIntervalSince(encryptedAt) < 3600 // 1 hour
    }
}
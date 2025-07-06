import Foundation
import Security

// MARK: - Secure Export Storage

@available(iOS 14.0, *)
class SecureExportStorage {
    static let shared = SecureExportStorage()
    
    // MARK: - Constants
    
    private enum Constants {
        static let exportHistoryKey = "com.healthai2030.export.history"
        static let exportMetadataKey = "com.healthai2030.export.metadata"
        static let encryptionKeysKey = "com.healthai2030.export.encryption"
        static let temporaryDirectoryName = "HealthAI_Exports"
        static let secureDirectoryName = "Secure_Exports"
        static let maxRetainedExports = 100
        static let maxStorageSize = 500 * 1024 * 1024 // 500 MB
    }
    
    // MARK: - Storage Locations
    
    private let fileManager = FileManager.default
    private let keychainService = "com.healthai2030.exports"
    private let accessGroup: String? = nil // Set if using app groups
    
    // MARK: - Directories
    
    private lazy var documentsDirectory: URL = {
        return fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
    }()
    
    private lazy var temporaryDirectory: URL = {
        let temp = fileManager.temporaryDirectory.appendingPathComponent(Constants.temporaryDirectoryName)
        createDirectoryIfNeeded(temp)
        return temp
    }()
    
    private lazy var secureDirectory: URL = {
        let secure = documentsDirectory.appendingPathComponent(Constants.secureDirectoryName)
        createDirectoryIfNeeded(secure)
        return secure
    }()
    
    // MARK: - Initialization
    
    private init() {
        setupStorageDirectories()
        scheduleCleanupTasks()
    }
    
    private func setupStorageDirectories() {
        createDirectoryIfNeeded(temporaryDirectory)
        createDirectoryIfNeeded(secureDirectory)
        
        // Set security attributes for secure directory
        var resourceValues = URLResourceValues()
        resourceValues.isExcludedFromBackup = true
        try? secureDirectory.setResourceValues(resourceValues)
    }
    
    private func createDirectoryIfNeeded(_ url: URL) {
        if !fileManager.fileExists(atPath: url.path) {
            try? fileManager.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
        }
    }
    
    // MARK: - Export History Management
    
    /// Save export history to secure storage
    func saveExportHistory(_ history: [ExportResult]) async {
        await withCheckedContinuation { continuation in
            let data: Data
            do {
                data = try JSONEncoder().encode(history)
            } catch {
                print("Failed to encode export history: \(error)")
                continuation.resume()
                return
            }
            
            let success = storeDataInKeychain(data, key: Constants.exportHistoryKey)
            if !success {
                print("Failed to store export history in keychain")
            }
            
            continuation.resume()
        }
    }
    
    /// Load export history from secure storage
    func loadExportHistory() async -> [ExportResult] {
        return await withCheckedContinuation { continuation in
            guard let data = retrieveDataFromKeychain(key: Constants.exportHistoryKey) else {
                continuation.resume(returning: [])
                return
            }
            
            do {
                let history = try JSONDecoder().decode([ExportResult].self, from: data)
                continuation.resume(returning: history)
            } catch {
                print("Failed to decode export history: \(error)")
                continuation.resume(returning: [])
            }
        }
    }
    
    /// Add a new export result to history
    func addExportResult(_ result: ExportResult) async {
        var history = await loadExportHistory()
        
        // Add new result at the beginning
        history.insert(result, at: 0)
        
        // Limit history size
        if history.count > Constants.maxRetainedExports {
            let excessResults = Array(history.dropFirst(Constants.maxRetainedExports))
            
            // Clean up files for excess results
            for excessResult in excessResults {
                if let filePath = excessResult.filePath {
                    try? await deleteFile(at: filePath)
                }
            }
            
            history = Array(history.prefix(Constants.maxRetainedExports))
        }
        
        await saveExportHistory(history)
    }
    
    /// Remove an export result from history
    func removeExportResult(withId id: String) async {
        var history = await loadExportHistory()
        
        // Find and remove the result
        if let index = history.firstIndex(where: { $0.id == id }) {
            let result = history[index]
            
            // Delete associated file
            if let filePath = result.filePath {
                try? await deleteFile(at: filePath)
            }
            
            history.remove(at: index)
            await saveExportHistory(history)
        }
    }
    
    // MARK: - File Management
    
    /// Create a temporary directory for export operations
    func createTemporaryDirectory() async -> URL {
        let tempDir = temporaryDirectory.appendingPathComponent(UUID().uuidString)
        createDirectoryIfNeeded(tempDir)
        return tempDir
    }
    
    /// Move a file to secure storage
    func moveToSecureStorage(_ sourceURL: URL) async throws -> URL {
        let fileName = sourceURL.lastPathComponent
        let secureURL = secureDirectory.appendingPathComponent(fileName)
        
        // Ensure unique filename
        let finalURL = generateUniqueURL(base: secureURL)
        
        try fileManager.moveItem(at: sourceURL, to: finalURL)
        
        // Set file protection
        try setFileProtection(at: finalURL)
        
        return finalURL
    }
    
    /// Delete a file from storage
    func deleteFile(at url: URL) async throws {
        guard fileManager.fileExists(atPath: url.path) else { return }
        
        try fileManager.removeItem(at: url)
    }
    
    /// Clean up temporary files
    func cleanupTemporaryFiles() async {
        let tempContents = try? fileManager.contentsOfDirectory(at: temporaryDirectory, includingPropertiesForKeys: nil)
        
        for url in tempContents ?? [] {
            try? fileManager.removeItem(at: url)
        }
    }
    
    /// Clean up old exports based on retention policy
    func cleanupOldExports(retentionDays: Int = 90) async {
        let cutoffDate = Date().addingTimeInterval(-TimeInterval(retentionDays * 24 * 3600))
        let history = await loadExportHistory()
        
        var updatedHistory: [ExportResult] = []
        
        for result in history {
            if result.startTime >= cutoffDate {
                updatedHistory.append(result)
            } else {
                // Delete old export file
                if let filePath = result.filePath {
                    try? await deleteFile(at: filePath)
                }
            }
        }
        
        if updatedHistory.count != history.count {
            await saveExportHistory(updatedHistory)
        }
    }
    
    /// Check and enforce storage size limits
    func enforceStorageLimits() async {
        let storageSize = await calculateStorageSize()
        
        if storageSize > Constants.maxStorageSize {
            await cleanupExcessStorage()
        }
    }
    
    // MARK: - Encryption Key Management
    
    /// Store encryption keys securely in keychain
    func storeEncryptionKey(_ key: Data, for exportId: String) -> Bool {
        let keychain = "\(Constants.encryptionKeysKey).\(exportId)"
        return storeDataInKeychain(key, key: keychain)
    }
    
    /// Retrieve encryption key from keychain
    func retrieveEncryptionKey(for exportId: String) -> Data? {
        let keychain = "\(Constants.encryptionKeysKey).\(exportId)"
        return retrieveDataFromKeychain(key: keychain)
    }
    
    /// Delete encryption key from keychain
    func deleteEncryptionKey(for exportId: String) -> Bool {
        let keychain = "\(Constants.encryptionKeysKey).\(exportId)"
        return deleteDataFromKeychain(key: keychain)
    }
    
    // MARK: - Metadata Management
    
    /// Store export metadata
    func storeExportMetadata(_ metadata: ExportStorageMetadata, for exportId: String) async {
        let key = "\(Constants.exportMetadataKey).\(exportId)"
        
        do {
            let data = try JSONEncoder().encode(metadata)
            let _ = storeDataInKeychain(data, key: key)
        } catch {
            print("Failed to store export metadata: \(error)")
        }
    }
    
    /// Retrieve export metadata
    func retrieveExportMetadata(for exportId: String) async -> ExportStorageMetadata? {
        let key = "\(Constants.exportMetadataKey).\(exportId)"
        
        guard let data = retrieveDataFromKeychain(key: key) else { return nil }
        
        do {
            return try JSONDecoder().decode(ExportStorageMetadata.self, from: data)
        } catch {
            print("Failed to decode export metadata: \(error)")
            return nil
        }
    }
    
    // MARK: - Storage Analytics
    
    /// Calculate total storage usage
    func calculateStorageSize() async -> Int64 {
        var totalSize: Int64 = 0
        
        let directories = [secureDirectory, temporaryDirectory]
        
        for directory in directories {
            guard let enumerator = fileManager.enumerator(at: directory, includingPropertiesForKeys: [.fileSizeKey]) else {
                continue
            }
            
            for case let fileURL as URL in enumerator {
                guard let resourceValues = try? fileURL.resourceValues(forKeys: [.fileSizeKey]),
                      let fileSize = resourceValues.fileSize else {
                    continue
                }
                totalSize += Int64(fileSize)
            }
        }
        
        return totalSize
    }
    
    /// Get storage statistics
    func getStorageStatistics() async -> StorageStatistics {
        let totalSize = await calculateStorageSize()
        let history = await loadExportHistory()
        
        let successfulExports = history.filter { $0.isSuccessful }.count
        let failedExports = history.filter { $0.status == .failed }.count
        
        let oldestExport = history.min(by: { $0.startTime < $1.startTime })?.startTime
        let newestExport = history.max(by: { $0.startTime < $1.startTime })?.startTime
        
        return StorageStatistics(
            totalStorageUsed: totalSize,
            totalExports: history.count,
            successfulExports: successfulExports,
            failedExports: failedExports,
            oldestExportDate: oldestExport,
            newestExportDate: newestExport,
            averageExportSize: history.isEmpty ? 0 : totalSize / Int64(history.count)
        )
    }
    
    // MARK: - Private Keychain Methods
    
    private func storeDataInKeychain(_ data: Data, key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        // Delete existing item first
        SecItemDelete(query as CFDictionary)
        
        // Add new item
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    private func retrieveDataFromKeychain(key: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess else { return nil }
        return result as? Data
    }
    
    private func deleteDataFromKeychain(key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
    
    // MARK: - Private Utility Methods
    
    private func generateUniqueURL(base: URL) -> URL {
        var counter = 1
        var candidateURL = base
        
        while fileManager.fileExists(atPath: candidateURL.path) {
            let name = base.deletingPathExtension().lastPathComponent
            let ext = base.pathExtension
            let newName = "\(name)_\(counter).\(ext)"
            candidateURL = base.deletingLastPathComponent().appendingPathComponent(newName)
            counter += 1
        }
        
        return candidateURL
    }
    
    private func setFileProtection(at url: URL) throws {
        let attributes: [FileAttributeKey: Any] = [
            .protectionKey: FileProtectionType.completeUntilFirstUserAuthentication
        ]
        
        try fileManager.setAttributes(attributes, ofItemAtPath: url.path)
    }
    
    private func scheduleCleanupTasks() {
        // Schedule periodic cleanup tasks
        Task {
            // Clean up temporary files every hour
            while true {
                try? await Task.sleep(nanoseconds: 3600 * 1_000_000_000) // 1 hour
                await cleanupTemporaryFiles()
                await enforceStorageLimits()
            }
        }
    }
    
    private func cleanupExcessStorage() async {
        let history = await loadExportHistory()
        
        // Sort by date, oldest first
        let sortedHistory = history.sorted { $0.startTime < $1.startTime }
        var currentSize = await calculateStorageSize()
        var updatedHistory = history
        
        // Remove oldest exports until under size limit
        for result in sortedHistory {
            guard currentSize > Constants.maxStorageSize else { break }
            
            if let filePath = result.filePath {
                if let attributes = try? fileManager.attributesOfItem(atPath: filePath.path),
                   let fileSize = attributes[.size] as? Int64 {
                    
                    try? await deleteFile(at: filePath)
                    currentSize -= fileSize
                    
                    updatedHistory.removeAll { $0.id == result.id }
                }
            }
        }
        
        await saveExportHistory(updatedHistory)
    }
}

// MARK: - Supporting Models

@available(iOS 14.0, *)
struct ExportStorageMetadata: Codable {
    let exportId: String
    let originalFileName: String
    let storedAt: Date
    let fileSize: Int64
    let checksum: String
    let encryptionMetadata: String?
    let retentionPolicy: String
    let accessCount: Int
    let lastAccessed: Date?
    
    init(exportId: String, originalFileName: String, fileSize: Int64, checksum: String, encryptionMetadata: String? = nil, retentionPolicy: String = "standard") {
        self.exportId = exportId
        self.originalFileName = originalFileName
        self.storedAt = Date()
        self.fileSize = fileSize
        self.checksum = checksum
        self.encryptionMetadata = encryptionMetadata
        self.retentionPolicy = retentionPolicy
        self.accessCount = 0
        self.lastAccessed = nil
    }
}

@available(iOS 14.0, *)
struct StorageStatistics {
    let totalStorageUsed: Int64
    let totalExports: Int
    let successfulExports: Int
    let failedExports: Int
    let oldestExportDate: Date?
    let newestExportDate: Date?
    let averageExportSize: Int64
    
    var formattedTotalSize: String {
        return ByteCountFormatter.string(fromByteCount: totalStorageUsed, countStyle: .file)
    }
    
    var formattedAverageSize: String {
        return ByteCountFormatter.string(fromByteCount: averageExportSize, countStyle: .file)
    }
    
    var successRate: Double {
        guard totalExports > 0 else { return 0 }
        return Double(successfulExports) / Double(totalExports)
    }
    
    var successPercentage: Int {
        return Int(successRate * 100)
    }
}

// MARK: - Storage Security

@available(iOS 14.0, *)
extension SecureExportStorage {
    
    /// Verify file integrity using checksums
    func verifyFileIntegrity(at url: URL, expectedChecksum: String) async -> Bool {
        guard let data = try? Data(contentsOf: url) else { return false }
        
        let checksum = calculateChecksum(for: data)
        return checksum == expectedChecksum
    }
    
    /// Calculate checksum for data
    private func calculateChecksum(for data: Data) -> String {
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    /// Securely delete a file (overwrite before deletion)
    func secureDeleteFile(at url: URL) async throws {
        guard fileManager.fileExists(atPath: url.path) else { return }
        
        // Get file size
        let attributes = try fileManager.attributesOfItem(atPath: url.path)
        guard let fileSize = attributes[.size] as? Int64 else {
            try fileManager.removeItem(at: url)
            return
        }
        
        // Overwrite with random data multiple times
        let overwritePasses = 3
        let handle = try FileHandle(forWritingTo: url)
        
        defer {
            try? handle.close()
        }
        
        for _ in 0..<overwritePasses {
            try handle.seek(toOffset: 0)
            
            let chunkSize = 8192
            var remainingBytes = Int(fileSize)
            
            while remainingBytes > 0 {
                let writeSize = min(chunkSize, remainingBytes)
                let randomData = Data((0..<writeSize).map { _ in UInt8.random(in: 0...255) })
                
                try handle.write(contentsOf: randomData)
                remainingBytes -= writeSize
            }
            
            try handle.synchronize()
        }
        
        // Finally delete the file
        try fileManager.removeItem(at: url)
    }
    
    /// Create encrypted backup of export history
    func createEncryptedBackup(password: String) async throws -> URL {
        let history = await loadExportHistory()
        let backupData = try JSONEncoder().encode(history)
        
        let encryptionManager = ExportEncryptionManager.shared
        let encryptedData = try await encryptionManager.encryptData(backupData, password: password)
        
        let backupURL = temporaryDirectory.appendingPathComponent("export_history_backup_\(Date().timeIntervalSince1970).encrypted")
        try encryptedData.write(to: backupURL)
        
        return backupURL
    }
    
    /// Restore from encrypted backup
    func restoreFromEncryptedBackup(at backupURL: URL, password: String) async throws {
        let encryptedData = try Data(contentsOf: backupURL)
        
        let encryptionManager = ExportEncryptionManager.shared
        let decryptedData = try await encryptionManager.decryptData(encryptedData, password: password)
        
        let history = try JSONDecoder().decode([ExportResult].self, from: decryptedData)
        await saveExportHistory(history)
    }
}

// MARK: - Extensions

@available(iOS 14.0, *)
extension SecureExportStorage {
    
    /// Get available disk space
    var availableDiskSpace: Int64 {
        guard let attributes = try? fileManager.attributesOfFileSystem(forPath: documentsDirectory.path),
              let freeSpace = attributes[.systemFreeSize] as? Int64 else {
            return 0
        }
        return freeSpace
    }
    
    /// Check if there's enough space for an export
    func hasEnoughSpace(for estimatedSize: Int64) -> Bool {
        let availableSpace = availableDiskSpace
        let requiredSpace = estimatedSize * 2 // Buffer for processing
        return availableSpace > requiredSpace
    }
    
    /// Get storage health status
    func getStorageHealth() async -> StorageHealth {
        let stats = await getStorageStatistics()
        let availableSpace = availableDiskSpace
        let usageRatio = Double(stats.totalStorageUsed) / Double(Constants.maxStorageSize)
        
        let status: StorageHealthStatus
        if usageRatio < 0.5 {
            status = .healthy
        } else if usageRatio < 0.8 {
            status = .warning
        } else {
            status = .critical
        }
        
        return StorageHealth(
            status: status,
            usedSpace: stats.totalStorageUsed,
            availableSpace: availableSpace,
            usagePercentage: Int(usageRatio * 100),
            recommendedAction: status.recommendedAction
        )
    }
}

@available(iOS 14.0, *)
struct StorageHealth {
    let status: StorageHealthStatus
    let usedSpace: Int64
    let availableSpace: Int64
    let usagePercentage: Int
    let recommendedAction: String
    
    var formattedUsedSpace: String {
        return ByteCountFormatter.string(fromByteCount: usedSpace, countStyle: .file)
    }
    
    var formattedAvailableSpace: String {
        return ByteCountFormatter.string(fromByteCount: availableSpace, countStyle: .file)
    }
}

@available(iOS 14.0, *)
enum StorageHealthStatus: String, CaseIterable {
    case healthy = "Healthy"
    case warning = "Warning"
    case critical = "Critical"
    
    var color: String {
        switch self {
        case .healthy: return "green"
        case .warning: return "orange"
        case .critical: return "red"
        }
    }
    
    var recommendedAction: String {
        switch self {
        case .healthy:
            return "Storage is operating normally"
        case .warning:
            return "Consider cleaning up old exports"
        case .critical:
            return "Clean up exports immediately to free space"
        }
    }
}
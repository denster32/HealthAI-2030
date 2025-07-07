import Foundation

public final class DataBackupManager {
    public static let shared = DataBackupManager()
    private init() {}

    /// Creates a backup of the store file at the specified URL
    public func createBackup(from storeURL: URL, to backupURL: URL) throws {
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: backupURL.path) {
            try fileManager.removeItem(at: backupURL)
        }
        try fileManager.copyItem(at: storeURL, to: backupURL)
    }

    /// Restores the store file from the specified backup URL
    public func restoreBackup(from backupURL: URL, to storeURL: URL) throws {
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: storeURL.path) {
            try fileManager.removeItem(at: storeURL)
        }
        try fileManager.copyItem(at: backupURL, to: storeURL)
    }
} 
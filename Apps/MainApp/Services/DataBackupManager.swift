import Foundation

public final class DataBackupManager {
    public static let shared = DataBackupManager()
    private init() {}

    /// Errors for backup and restore operations
    public enum BackupError: Error {
        case storeNotFound(URL)
        case backupNotFound(URL)
        case ioError(Error)
    }

    /// Static convenience method to backup a store; throws BackupError
    public static func backupStore(from storeURL: URL, to backupURL: URL) throws {
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: storeURL.path) else {
            throw BackupError.storeNotFound(storeURL)
        }
        do {
            try shared.createBackup(from: storeURL, to: backupURL)
        } catch {
            throw BackupError.ioError(error)
        }
    }

    /// Static convenience method to restore a store; throws BackupError
    public static func restoreStore(from backupURL: URL, to storeURL: URL) throws {
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: backupURL.path) else {
            throw BackupError.backupNotFound(backupURL)
        }
        do {
            try shared.restoreBackup(from: backupURL, to: storeURL)
        } catch {
            throw BackupError.ioError(error)
        }
    }

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
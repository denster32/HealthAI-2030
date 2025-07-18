import Foundation

/// Manages snapshot and restore of SwiftData persistent store files.
public struct DataBackupManager {
    /// Creates a backup of the store file at `storeURL` to `backupURL`.
    public static func backupStore(from storeURL: URL, to backupURL: URL) throws {
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: storeURL.path) else {
            throw BackupError.storeNotFound(storeURL)
        }
        if fileManager.fileExists(atPath: backupURL.path) {
            try fileManager.removeItem(at: backupURL)
        }
        try fileManager.copyItem(at: storeURL, to: backupURL)
    }

    /// Restores the store file from `backupURL` to `storeURL`.
    public static func restoreStore(from backupURL: URL, to storeURL: URL) throws {
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: backupURL.path) else {
            throw BackupError.backupNotFound(backupURL)
        }
        if fileManager.fileExists(atPath: storeURL.path) {
            try fileManager.removeItem(at: storeURL)
        }
        try fileManager.copyItem(at: backupURL, to: storeURL)
    }

    public enum BackupError: Error {
        case storeNotFound(URL)
        case backupNotFound(URL)
    }
} 
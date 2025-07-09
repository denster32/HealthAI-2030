import XCTest
@testable import HealthAI2030Core

final class DataBackupManagerTests: XCTestCase {
    func testBackupAndRestore() throws {
        let fileManager = FileManager.default
        let tempDir = fileManager.temporaryDirectory
        let originalURL = tempDir.appendingPathComponent("original.dat")
        let backupURL = tempDir.appendingPathComponent("backup.dat")

        let originalData = "Hello, world!".data(using: .utf8)!
        try originalData.write(to: originalURL)

        // Perform backup
        try DataBackupManager.backupStore(from: originalURL, to: backupURL)
        XCTAssertTrue(fileManager.fileExists(atPath: backupURL.path))

        // Corrupt original file
        let corruptedData = "CORRUPTED".data(using: .utf8)!
        try corruptedData.write(to: originalURL)

        // Perform restore
        try DataBackupManager.restoreStore(from: backupURL, to: originalURL)

        let restoredData = try Data(contentsOf: originalURL)
        XCTAssertEqual(restoredData, originalData)

        // Clean up
        try? fileManager.removeItem(at: originalURL)
        try? fileManager.removeItem(at: backupURL)
    }

    func testBackupNonexistentStoreThrows() {
        let fileManager = FileManager.default
        let tempDir = fileManager.temporaryDirectory
        let missingURL = tempDir.appendingPathComponent("missing.dat")
        let backupURL2 = tempDir.appendingPathComponent("backup.dat")

        XCTAssertThrowsError(try DataBackupManager.backupStore(from: missingURL, to: backupURL2)) { error in
            guard case DataBackupManager.BackupError.storeNotFound(let url) = error else {
                return XCTFail("Expected storeNotFound error")
            }
            XCTAssertEqual(url, missingURL)
        }
    }

    func testRestoreNonexistentBackupThrows() {
        let fileManager = FileManager.default
        let tempDir = fileManager.temporaryDirectory
        let storeURL = tempDir.appendingPathComponent("store.dat")
        let missingBackupURL = tempDir.appendingPathComponent("missing_backup.dat")

        XCTAssertThrowsError(try DataBackupManager.restoreStore(from: missingBackupURL, to: storeURL)) { error in
            guard case DataBackupManager.BackupError.backupNotFound(let url) = error else {
                return XCTFail("Expected backupNotFound error")
            }
            XCTAssertEqual(url, missingBackupURL)
        }
    }
} 
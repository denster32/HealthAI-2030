import XCTest
@testable import HealthAI_2030

final class PrivacySettingsTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Clear UserDefaults before each test to ensure a clean state
        UserDefaults.standard.removeObject(forKey: "PrivacySettings")
    }

    func testDefaultSettings() {
        let settings = PrivacySettings.load()
        XCTAssertTrue(settings.shareHealthData)
        XCTAssertFalse(settings.shareUsageData)
        XCTAssertTrue(settings.granularPermissions.isEmpty) // Should be empty initially
        XCTAssertTrue(settings.auditLog.isEmpty)
    }

    func testToggleSettings() {
        var settings = PrivacySettings()
        settings.shareHealthData = false
        settings.shareUsageData = true
        settings.save()

        let loadedSettings = PrivacySettings.load()
        XCTAssertFalse(loadedSettings.shareHealthData)
        XCTAssertTrue(loadedSettings.shareUsageData)
    }

    func testGranularPermissions() {
        var settings = PrivacySettings()
        settings.granularPermissions[.heartRate] = false
        settings.granularPermissions[.sleep] = true
        settings.save()

        let loadedSettings = PrivacySettings.load()
        XCTAssertFalse(loadedSettings.granularPermissions[.heartRate] ?? true)
        XCTAssertTrue(loadedSettings.granularPermissions[.sleep] ?? false)
        XCTAssertNil(loadedSettings.granularPermissions[.activity]) // Should be nil if not set
    }

    func testAuditLogging() {
        var settings = PrivacySettings()
        settings.recordAuditEntry(action: "Changed Health Data Sharing", details: "User opted out of health data sharing.")
        settings.save()

        let loadedSettings = PrivacySettings.load()
        XCTAssertEqual(loadedSettings.auditLog.count, 1)
        XCTAssertEqual(loadedSettings.auditLog.first?.action, "Changed Health Data Sharing")
        XCTAssertEqual(loadedSettings.auditLog.first?.details, "User opted out of health data sharing.")
    }

    func testMigrationOfGranularPermissions() {
        // Simulate old settings without granular permissions
        struct OldPrivacySettings: Codable {
            var shareHealthData: Bool
            var shareUsageData: Bool
        }
        let oldSettings = OldPrivacySettings(shareHealthData: true, shareUsageData: false)
        if let data = try? JSONEncoder().encode(oldSettings) {
            UserDefaults.standard.set(data, forKey: "PrivacySettings")
        }

        // Load with new PrivacySettings struct, triggering migration
        let migratedSettings = PrivacySettings.load()
        XCTAssertTrue(migratedSettings.shareHealthData)
        XCTAssertFalse(migratedSettings.shareUsageData)
        XCTAssertFalse(migratedSettings.granularPermissions.isEmpty) // Should now be populated
        XCTAssertTrue(migratedSettings.granularPermissions[.heartRate] ?? false) // Default to true
        XCTAssertTrue(migratedSettings.granularPermissions[.sleep] ?? false) // Default to true
    }
}

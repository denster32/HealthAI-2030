import XCTest
@testable import HealthAI_2030

final class PrivacySettingsTests: XCTestCase {
    func testDefaultSettings() {
        let settings = PrivacySettings()
        XCTAssertTrue(settings.shareHealthData)
        XCTAssertFalse(settings.shareUsageData)
    }
    func testToggleSettings() {
        var settings = PrivacySettings()
        settings.shareHealthData = false
        settings.shareUsageData = true
        XCTAssertFalse(settings.shareHealthData)
        XCTAssertTrue(settings.shareUsageData)
    }
}

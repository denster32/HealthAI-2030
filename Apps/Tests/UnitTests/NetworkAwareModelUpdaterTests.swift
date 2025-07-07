import XCTest
@testable import HealthAI2030App

final class NetworkAwareModelUpdaterTests: XCTestCase {

    func testShouldUpdateModelOnWiFi() throws {
        let updater = NetworkAwareModelUpdater()
        let expectation = self.expectation(description: "Network check")
        updater.shouldUpdateModel { shouldUpdate in
            // TODO: Simulate Wi-Fi conditions.
            XCTAssertNotNil(shouldUpdate)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 2.0)
    }

    func testIsUpdateAllowedHelper() {
        let updater = NetworkAwareModelUpdater()
        // Wi-Fi scenario (isExpensive = false) should always allow updates
        XCTAssertTrue(updater.isUpdateAllowed(onExpensive: false, modelSize: 50 * 1024 * 1024), "Wi-Fi should allow large updates")
        // Cellular scenario (isExpensive = true)
        let smallModelSize = 2 * 1024 * 1024 // 2 MB
        let largeModelSize = 10 * 1024 * 1024 // 10 MB
        // Default threshold is 5 MB
        XCTAssertTrue(updater.isUpdateAllowed(onExpensive: true, modelSize: smallModelSize), "Cellular should allow small updates under threshold")
        XCTAssertFalse(updater.isUpdateAllowed(onExpensive: true, modelSize: largeModelSize), "Cellular should defer large updates over threshold")
        // Custom threshold override
        XCTAssertTrue(updater.isUpdateAllowed(onExpensive: true, modelSize: largeModelSize, maxCellularSize: largeModelSize), "Cellular should allow updates under custom threshold")
    }
} 
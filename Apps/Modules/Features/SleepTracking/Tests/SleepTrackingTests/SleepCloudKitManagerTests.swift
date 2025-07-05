import XCTest
@testable import SleepTracking

final class SleepCloudKitManagerTests: XCTestCase {
    var manager: SleepCloudKitManager!

    override func setUp() {
        super.setUp()
        manager = SleepCloudKitManager.shared
    }

    func testConfigureCloudSync_enablesSync() async {
        await manager.configureCloudSync()
        XCTAssertTrue(manager.isCloudSyncEnabled)
        XCTAssertEqual(manager.syncStatus, .ready)
    }

    func testDisableCloudSync_disablesSync() {
        manager.disableCloudSync()
        XCTAssertFalse(manager.isCloudSyncEnabled)
        XCTAssertEqual(manager.syncStatus, .disabled)
    }

    func testHandleSyncError_setsErrorStatus() {
        let dummyError = NSError(domain: "Test", code: 1, userInfo: nil)
        manager.handleSyncError(dummyError)
        XCTAssertEqual(manager.syncStatus, .error(.syncFailed(dummyError)))
        XCTAssertNotNil(manager.syncError)
    }

    func testSyncAllDataToCloud_catchesError() async {
        // Force an error by disabling sync status
        manager.disableCloudSync()
        // Should not throw
        await manager.syncAllDataToCloud()
        // syncStatus remains disabled
        XCTAssertEqual(manager.syncStatus, .disabled)
    }
}

import XCTest
@testable import HealthAI2030App

final class MLModelVersionManagerTests: XCTestCase {

    func testSetAndGetVersion() {
        let manager = MLModelVersionManager.shared
        manager.setVersion("1.0.0", forModel: "testModel")
        XCTAssertEqual(manager.getVersion(forModel: "testModel"), "1.0.0")
    }

    func testDeprecateModel() {
        let manager = MLModelVersionManager.shared
        XCTAssertNoThrow(manager.deprecateModel(named: "testModel"))
    }

    func testArchiveAndRetrieveModel() {
        let manager = MLModelVersionManager.shared
        XCTAssertNoThrow(manager.archiveModel(named: "testModel"))
        XCTAssertNil(manager.retrieveArchivedModel(named: "testModel"))
    }
} 
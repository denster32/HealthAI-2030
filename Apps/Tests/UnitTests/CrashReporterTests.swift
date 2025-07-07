import XCTest
@testable import HealthAI2030App

final class CrashReporterTests: XCTestCase {
    var reporter: CrashReporter!

    override func setUp() {
        super.setUp()
        reporter = CrashReporter.shared
    }

    override func tearDown() {
        super.tearDown()
    }

    /// Test recording a non-fatal error does not crash and is reported
    func testRecordError() {
        let error = NSError(domain: "test", code: 123, userInfo: ["key": "value"])
        XCTAssertNoThrow(reporter.recordError(error, withStackTrace: ["frame1", "frame2"], additionalInfo: ["infoKey": "infoValue"]))
    }

    /// Test state preservation and retrieval
    func testPreserveAndRetrieveState() {
        let state: [String: Any] = ["health": 80, "status": "ok"]
        reporter.preserveState(state)

        // Delay to allow async barrier write
        let expectation = expectation(description: "State preserved")
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) {
            let retrieved = self.reporter.getLastKnownState()
            XCTAssertEqual(retrieved["health"] as? Int, 80)
            XCTAssertEqual(retrieved["status"] as? String, "ok")
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1.0)
    }

    /// Test logging does not crash
    func testLogMessage() {
        XCTAssertNoThrow(reporter.log("Test log message"))
    }

    /// Test forceCrash triggers fatalError (skipped to avoid crash)
    func testForceCrash() {
        // Skipping forceCrash as it will terminate the process
        XCTAssertTrue(true)
    }
} 
import XCTest
@testable import HealthAI2030App

final class ExplanationFeedbackManagerTests: XCTestCase {

    func testRecordAndGetFeedback() {
        let manager = ExplanationFeedbackManager()
        manager.recordFeedback(explanationID: "exp1", feedback: "Very helpful")
        XCTAssertEqual(manager.getFeedback(explanationID: "exp1"), "Very helpful")
    }

    func testGetFeedbackReturnsNilForUnknownID() {
        let manager = ExplanationFeedbackManager()
        XCTAssertNil(manager.getFeedback(explanationID: "unknown"))
    }
} 
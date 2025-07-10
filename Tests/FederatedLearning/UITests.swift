// Tests/FederatedLearning/UITests.swift
import XCTest

final class UITests: XCTestCase {
    func testFederatedLearningStatus() throws {
        let app = XCUIApplication()
        app.launch()

        let statusLabel = app.staticTexts["FederatedLearningStatus"]
        XCTAssertTrue(statusLabel.exists)
        XCTAssertEqual(statusLabel.label, "Connected")
    }

    func testFederatedLearningStatusAccessibility() throws {
        let app = XCUIApplication()
        app.launch()

        let statusLabel = app.staticTexts["FederatedLearningStatus"]
        XCTAssertTrue(statusLabel.isAccessibilityElement)
    }
}
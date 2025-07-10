import XCTest
@testable import HealthAI2030

@available(iOS 18.0, macOS 15.0, *)
final class HealthAI2030UITests: XCTestCase {
    func testWelcomeMessage() throws {
        let app = XCUIApplication()
        app.launch()

        let welcomeMessage = app.staticTexts["WelcomeMessage"]
        XCTAssertTrue(welcomeMessage.exists)
        XCTAssertEqual(welcomeMessage.label, "Hello, world!")
    }

    func testWelcomeMessageAccessibility() throws {
        let app = XCUIApplication()
        app.launch()

        let welcomeMessage = app.staticTexts["WelcomeMessage"]
        XCTAssertTrue(welcomeMessage.isAccessibilityElement)
    }
}

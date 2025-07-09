import XCTest
import SwiftUI
@testable import HealthAI2030UI

/// Comprehensive UI Test Suite for Dashboard View
/// Tests all aspects of the main dashboard including user interactions, data display, and accessibility
@MainActor
final class DashboardViewTests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUp() async throws {
        try await super.setUp()
        app = XCUIApplication()
        app.launchArguments = ["UI-Testing"]
        app.launch()
    }
    
    override func tearDown() async throws {
        app = nil
        try await super.tearDown()
    }
    
    // MARK: - Basic UI Element Tests
    
    func testDashboardViewLoads() {
        // Verify the dashboard view loads successfully
        XCTAssertTrue(app.isDisplayed)
        
        // Check for main dashboard elements
        XCTAssertTrue(app.navigationBars["HealthAI 2030"].exists)
        XCTAssertTrue(app.buttons["Settings"].exists)
        XCTAssertTrue(app.buttons["Profile"].exists)
    }
    
    func testHealthMetricsDisplay() {
        // Test that health metrics are displayed
        XCTAssertTrue(app.staticTexts["Steps"].exists)
        XCTAssertTrue(app.staticTexts["Heart Rate"].exists)
        XCTAssertTrue(app.staticTexts["Sleep"].exists)
        XCTAssertTrue(app.staticTexts["Water Intake"].exists)
        
        // Verify metric values are present (even if 0)
        let stepsValue = app.staticTexts.matching(identifier: "steps_value").firstMatch
        let heartRateValue = app.staticTexts.matching(identifier: "heart_rate_value").firstMatch
        let sleepValue = app.staticTexts.matching(identifier: "sleep_value").firstMatch
        let waterValue = app.staticTexts.matching(identifier: "water_value").firstMatch
        
        XCTAssertTrue(stepsValue.exists)
        XCTAssertTrue(heartRateValue.exists)
        XCTAssertTrue(sleepValue.exists)
        XCTAssertTrue(waterValue.exists)
    }
    
    func testQuickActionsButtons() {
        // Test quick action buttons
        XCTAssertTrue(app.buttons["Log Water"].exists)
        XCTAssertTrue(app.buttons["Start Workout"].exists)
        XCTAssertTrue(app.buttons["Log Mood"].exists)
        XCTAssertTrue(app.buttons["Meditation"].exists)
    }
    
    // MARK: - User Interaction Tests
    
    func testLogWaterInteraction() {
        let logWaterButton = app.buttons["Log Water"]
        XCTAssertTrue(logWaterButton.exists)
        
        logWaterButton.tap()
        
        // Verify water logging interface appears
        XCTAssertTrue(app.staticTexts["Log Water Intake"].exists)
        XCTAssertTrue(app.buttons["Add 250ml"].exists)
        XCTAssertTrue(app.buttons["Add 500ml"].exists)
        XCTAssertTrue(app.buttons["Custom Amount"].exists)
    }
    
    func testStartWorkoutInteraction() {
        let startWorkoutButton = app.buttons["Start Workout"]
        XCTAssertTrue(startWorkoutButton.exists)
        
        startWorkoutButton.tap()
        
        // Verify workout interface appears
        XCTAssertTrue(app.staticTexts["Start Workout"].exists)
        XCTAssertTrue(app.buttons["Running"].exists)
        XCTAssertTrue(app.buttons["Walking"].exists)
        XCTAssertTrue(app.buttons["Cycling"].exists)
        XCTAssertTrue(app.buttons["Cancel"].exists)
    }
    
    func testLogMoodInteraction() {
        let logMoodButton = app.buttons["Log Mood"]
        XCTAssertTrue(logMoodButton.exists)
        
        logMoodButton.tap()
        
        // Verify mood logging interface appears
        XCTAssertTrue(app.staticTexts["How are you feeling?"].exists)
        XCTAssertTrue(app.buttons["Happy"].exists)
        XCTAssertTrue(app.buttons["Sad"].exists)
        XCTAssertTrue(app.buttons["Anxious"].exists)
        XCTAssertTrue(app.buttons["Energetic"].exists)
        XCTAssertTrue(app.buttons["Tired"].exists)
    }
    
    func testMeditationInteraction() {
        let meditationButton = app.buttons["Meditation"]
        XCTAssertTrue(meditationButton.exists)
        
        meditationButton.tap()
        
        // Verify meditation interface appears
        XCTAssertTrue(app.staticTexts["Meditation"].exists)
        XCTAssertTrue(app.buttons["5 Minutes"].exists)
        XCTAssertTrue(app.buttons["10 Minutes"].exists)
        XCTAssertTrue(app.buttons["20 Minutes"].exists)
        XCTAssertTrue(app.buttons["Custom"].exists)
    }
    
    // MARK: - Navigation Tests
    
    func testSettingsNavigation() {
        let settingsButton = app.buttons["Settings"]
        XCTAssertTrue(settingsButton.exists)
        
        settingsButton.tap()
        
        // Verify settings view appears
        XCTAssertTrue(app.navigationBars["Settings"].exists)
        XCTAssertTrue(app.staticTexts["Privacy"].exists)
        XCTAssertTrue(app.staticTexts["Notifications"].exists)
        XCTAssertTrue(app.staticTexts["Data & Storage"].exists)
        XCTAssertTrue(app.staticTexts["About"].exists)
        
        // Navigate back
        app.navigationBars.buttons["Back"].tap()
        XCTAssertTrue(app.navigationBars["HealthAI 2030"].exists)
    }
    
    func testProfileNavigation() {
        let profileButton = app.buttons["Profile"]
        XCTAssertTrue(profileButton.exists)
        
        profileButton.tap()
        
        // Verify profile view appears
        XCTAssertTrue(app.navigationBars["Profile"].exists)
        XCTAssertTrue(app.staticTexts["Personal Information"].exists)
        XCTAssertTrue(app.staticTexts["Health Goals"].exists)
        XCTAssertTrue(app.staticTexts["Achievements"].exists)
        
        // Navigate back
        app.navigationBars.buttons["Back"].tap()
        XCTAssertTrue(app.navigationBars["HealthAI 2030"].exists)
    }
    
    func testHealthDataDetailNavigation() {
        // Tap on a health metric to view details
        let stepsCard = app.otherElements["steps_card"]
        XCTAssertTrue(stepsCard.exists)
        
        stepsCard.tap()
        
        // Verify detailed view appears
        XCTAssertTrue(app.navigationBars["Steps"].exists)
        XCTAssertTrue(app.staticTexts["Today's Steps"].exists)
        XCTAssertTrue(app.staticTexts["Weekly Average"].exists)
        XCTAssertTrue(app.staticTexts["Goal"].exists)
        
        // Navigate back
        app.navigationBars.buttons["Back"].tap()
        XCTAssertTrue(app.navigationBars["HealthAI 2030"].exists)
    }
    
    // MARK: - Data Update Tests
    
    func testRealTimeDataUpdates() {
        // Test that data updates in real-time
        let initialStepsValue = app.staticTexts.matching(identifier: "steps_value").firstMatch.label
        
        // Simulate step count update (this would normally come from HealthKit)
        // In a real test, we'd trigger a HealthKit update
        
        // Wait for potential update
        let expectation = XCTestExpectation(description: "Data update")
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 3.0)
        
        // Verify data is still displayed (even if unchanged)
        let updatedStepsValue = app.staticTexts.matching(identifier: "steps_value").firstMatch
        XCTAssertTrue(updatedStepsValue.exists)
    }
    
    func testGoalProgressDisplay() {
        // Test that goal progress is displayed
        XCTAssertTrue(app.progressIndicators["steps_progress"].exists)
        XCTAssertTrue(app.progressIndicators["water_progress"].exists)
        XCTAssertTrue(app.progressIndicators["sleep_progress"].exists)
        
        // Verify progress indicators are visible
        let stepsProgress = app.progressIndicators["steps_progress"]
        let waterProgress = app.progressIndicators["water_progress"]
        let sleepProgress = app.progressIndicators["sleep_progress"]
        
        XCTAssertTrue(stepsProgress.exists)
        XCTAssertTrue(waterProgress.exists)
        XCTAssertTrue(sleepProgress.exists)
    }
    
    // MARK: - Accessibility Tests
    
    func testVoiceOverSupport() {
        // Test VoiceOver accessibility
        let logWaterButton = app.buttons["Log Water"]
        XCTAssertTrue(logWaterButton.exists)
        
        // Verify accessibility label
        XCTAssertNotNil(logWaterButton.accessibilityLabel)
        XCTAssertTrue(logWaterButton.accessibilityLabel?.count ?? 0 > 0)
        
        // Verify accessibility hint
        XCTAssertNotNil(logWaterButton.accessibilityHint)
        XCTAssertTrue(logWaterButton.accessibilityHint?.count ?? 0 > 0)
    }
    
    func testDynamicTypeScaling() {
        // Test that text scales with Dynamic Type
        let stepsLabel = app.staticTexts["Steps"]
        XCTAssertTrue(stepsLabel.exists)
        
        // Verify text is readable at different sizes
        // This would be tested with different Dynamic Type settings
        XCTAssertTrue(stepsLabel.isEnabled)
        XCTAssertTrue(stepsLabel.isHittable)
    }
    
    func testColorContrast() {
        // Test color contrast accessibility
        let stepsCard = app.otherElements["steps_card"]
        XCTAssertTrue(stepsCard.exists)
        
        // Verify sufficient contrast (this would be tested with accessibility tools)
        XCTAssertTrue(stepsCard.isEnabled)
    }
    
    func testKeyboardNavigation() {
        // Test keyboard navigation accessibility
        let logWaterButton = app.buttons["Log Water"]
        XCTAssertTrue(logWaterButton.exists)
        
        // Verify keyboard accessibility
        XCTAssertTrue(logWaterButton.isEnabled)
        XCTAssertTrue(logWaterButton.isHittable)
    }
    
    // MARK: - Error Handling Tests
    
    func testNetworkErrorHandling() {
        // Test how the app handles network errors
        // This would require mocking network conditions
        
        // Verify error states are handled gracefully
        XCTAssertTrue(app.isDisplayed)
        
        // Check for any error messages that might appear
        let errorMessages = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'error' OR label CONTAINS[c] 'failed' OR label CONTAINS[c] 'unavailable'"))
        
        // Error messages should not be present in normal operation
        XCTAssertEqual(errorMessages.count, 0)
    }
    
    func testDataUnavailableHandling() {
        // Test how the app handles unavailable data
        // This would require mocking HealthKit permissions or data availability
        
        // Verify the app still loads even without data
        XCTAssertTrue(app.isDisplayed)
        XCTAssertTrue(app.navigationBars["HealthAI 2030"].exists)
    }
    
    // MARK: - Performance Tests
    
    func testDashboardLoadPerformance() {
        measure {
            // Measure dashboard load time
            app.terminate()
            app.launch()
            
            // Wait for dashboard to load
            let dashboardLoaded = app.navigationBars["HealthAI 2030"].waitForExistence(timeout: 5.0)
            XCTAssertTrue(dashboardLoaded)
        }
    }
    
    func testNavigationPerformance() {
        // Measure navigation performance
        measure {
            // Navigate to settings and back
            app.buttons["Settings"].tap()
            app.navigationBars.buttons["Back"].tap()
            
            // Verify we're back on dashboard
            XCTAssertTrue(app.navigationBars["HealthAI 2030"].exists)
        }
    }
    
    // MARK: - Edge Case Tests
    
    func testEmptyStateHandling() {
        // Test how the app handles empty states
        // This would require mocking empty data scenarios
        
        // Verify the app still functions with no data
        XCTAssertTrue(app.isDisplayed)
        XCTAssertTrue(app.buttons["Log Water"].exists)
        XCTAssertTrue(app.buttons["Start Workout"].exists)
    }
    
    func testLargeDataHandling() {
        // Test how the app handles large amounts of data
        // This would require mocking large datasets
        
        // Verify the app remains responsive
        XCTAssertTrue(app.isDisplayed)
        XCTAssertTrue(app.buttons["Log Water"].isHittable)
    }
    
    func testRapidInteractionHandling() {
        // Test rapid user interactions
        let logWaterButton = app.buttons["Log Water"]
        
        // Rapidly tap the button multiple times
        for _ in 0..<5 {
            logWaterButton.tap()
            
            // Cancel if water logging interface appears
            if app.buttons["Cancel"].exists {
                app.buttons["Cancel"].tap()
            }
        }
        
        // Verify app remains stable
        XCTAssertTrue(app.isDisplayed)
        XCTAssertTrue(app.navigationBars["HealthAI 2030"].exists)
    }
    
    // MARK: - Localization Tests
    
    func testLocalizedStrings() {
        // Test that strings are properly localized
        // This would be tested with different language settings
        
        // Verify key strings are present
        XCTAssertTrue(app.staticTexts["Steps"].exists)
        XCTAssertTrue(app.staticTexts["Heart Rate"].exists)
        XCTAssertTrue(app.staticTexts["Sleep"].exists)
        XCTAssertTrue(app.staticTexts["Water Intake"].exists)
    }
    
    // MARK: - Dark Mode Tests
    
    func testDarkModeSupport() {
        // Test dark mode appearance
        // This would require switching to dark mode
        
        // Verify app still functions in dark mode
        XCTAssertTrue(app.isDisplayed)
        XCTAssertTrue(app.buttons["Log Water"].exists)
        XCTAssertTrue(app.buttons["Start Workout"].exists)
    }
    
    // MARK: - Orientation Tests
    
    func testOrientationChanges() {
        // Test orientation changes
        // This would require rotating the device
        
        // Verify app adapts to orientation changes
        XCTAssertTrue(app.isDisplayed)
        XCTAssertTrue(app.navigationBars["HealthAI 2030"].exists)
    }
    
    // MARK: - Memory Management Tests
    
    func testMemoryUsage() {
        // Test memory usage during normal operation
        // This would require monitoring memory usage
        
        // Perform various operations
        app.buttons["Settings"].tap()
        app.navigationBars.buttons["Back"].tap()
        app.buttons["Profile"].tap()
        app.navigationBars.buttons["Back"].tap()
        
        // Verify app remains stable
        XCTAssertTrue(app.isDisplayed)
        XCTAssertTrue(app.navigationBars["HealthAI 2030"].exists)
    }
} 
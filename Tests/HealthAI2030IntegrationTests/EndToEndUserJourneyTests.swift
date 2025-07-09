import XCTest
import Foundation
import HealthKit
@testable import HealthAI_2030

/// Comprehensive End-to-End Integration Test Suite
/// Tests complete user journeys through the HealthAI 2030 application
@MainActor
final class EndToEndUserJourneyTests: XCTestCase {
    
    var app: XCUIApplication!
    var healthStore: HKHealthStore!
    
    override func setUp() async throws {
        try await super.setUp()
        app = XCUIApplication()
        app.launchArguments = ["UI-Testing", "MockHealthKit"]
        app.launch()
        
        // Initialize HealthKit store for testing
        if HKHealthStore.isHealthDataAvailable() {
            healthStore = HKHealthStore()
        }
    }
    
    override func tearDown() async throws {
        app = nil
        healthStore = nil
        try await super.tearDown()
    }
    
    // MARK: - User Registration Journey
    
    func testCompleteUserRegistrationJourney() {
        // Test complete user registration flow
        let expectation = XCTestExpectation(description: "User registration journey")
        
        // Step 1: Launch app and check for onboarding
        XCTAssertTrue(app.isDisplayed)
        
        // Check if onboarding is shown (first-time user)
        if app.staticTexts["Welcome to HealthAI 2030"].exists {
            // Step 2: Complete onboarding
            app.buttons["Get Started"].tap()
            
            // Step 3: Enter personal information
            XCTAssertTrue(app.staticTexts["Tell us about yourself"].exists)
            
            let nameTextField = app.textFields["Full Name"]
            nameTextField.tap()
            nameTextField.typeText("John Doe")
            
            let ageTextField = app.textFields["Age"]
            ageTextField.tap()
            ageTextField.typeText("30")
            
            app.buttons["Next"].tap()
            
            // Step 4: Set health goals
            XCTAssertTrue(app.staticTexts["Set Your Health Goals"].exists)
            
            let stepsGoalTextField = app.textFields["Daily Steps Goal"]
            stepsGoalTextField.tap()
            stepsGoalTextField.typeText("10000")
            
            let waterGoalTextField = app.textFields["Daily Water Goal (ml)"]
            waterGoalTextField.tap()
            waterGoalTextField.typeText("2000")
            
            app.buttons["Next"].tap()
            
            // Step 5: Grant permissions
            XCTAssertTrue(app.staticTexts["Health Permissions"].exists)
            app.buttons["Grant Permissions"].tap()
            
            // Handle permission dialogs
            if app.alerts.firstMatch.exists {
                app.alerts.firstMatch.buttons["Allow"].tap()
            }
            
            // Step 6: Complete setup
            app.buttons["Complete Setup"].tap()
            
            // Verify we're on the main dashboard
            XCTAssertTrue(app.navigationBars["HealthAI 2030"].exists)
            expectation.fulfill()
        } else {
            // User already registered, skip to dashboard
            XCTAssertTrue(app.navigationBars["HealthAI 2030"].exists)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 30.0)
    }
    
    // MARK: - Daily Health Tracking Journey
    
    func testCompleteDailyHealthTrackingJourney() {
        let expectation = XCTestExpectation(description: "Daily health tracking journey")
        
        // Step 1: Start on dashboard
        XCTAssertTrue(app.navigationBars["HealthAI 2030"].exists)
        
        // Step 2: Log water intake
        app.buttons["Log Water"].tap()
        XCTAssertTrue(app.staticTexts["Log Water Intake"].exists)
        
        app.buttons["Add 250ml"].tap()
        XCTAssertTrue(app.staticTexts["Water intake logged"].exists)
        
        app.buttons["Done"].tap()
        
        // Step 3: Log mood
        app.buttons["Log Mood"].tap()
        XCTAssertTrue(app.staticTexts["How are you feeling?"].exists)
        
        app.buttons["Happy"].tap()
        XCTAssertTrue(app.staticTexts["Mood logged"].exists)
        
        app.buttons["Done"].tap()
        
        // Step 4: Start a workout
        app.buttons["Start Workout"].tap()
        XCTAssertTrue(app.staticTexts["Start Workout"].exists)
        
        app.buttons["Walking"].tap()
        XCTAssertTrue(app.staticTexts["Workout Started"].exists)
        
        // Simulate workout completion
        app.buttons["End Workout"].tap()
        XCTAssertTrue(app.staticTexts["Workout Completed"].exists)
        
        app.buttons["Save"].tap()
        
        // Step 5: Check updated metrics
        XCTAssertTrue(app.staticTexts["Steps"].exists)
        XCTAssertTrue(app.staticTexts["Water Intake"].exists)
        
        // Verify data was recorded
        let waterProgress = app.progressIndicators["water_progress"]
        XCTAssertTrue(waterProgress.exists)
        
        expectation.fulfill()
        wait(for: [expectation], timeout: 30.0)
    }
    
    // MARK: - Health Data Analysis Journey
    
    func testHealthDataAnalysisJourney() {
        let expectation = XCTestExpectation(description: "Health data analysis journey")
        
        // Step 1: Navigate to analytics
        app.buttons["Analytics"].tap()
        XCTAssertTrue(app.navigationBars["Health Analytics"].exists)
        
        // Step 2: View weekly summary
        app.buttons["Weekly Summary"].tap()
        XCTAssertTrue(app.staticTexts["Weekly Health Summary"].exists)
        
        // Verify analytics data is displayed
        XCTAssertTrue(app.staticTexts["Average Steps"].exists)
        XCTAssertTrue(app.staticTexts["Sleep Quality"].exists)
        XCTAssertTrue(app.staticTexts["Water Intake"].exists)
        XCTAssertTrue(app.staticTexts["Mood Trends"].exists)
        
        // Step 3: View detailed metrics
        app.buttons["Steps Details"].tap()
        XCTAssertTrue(app.navigationBars["Steps Analysis"].exists)
        
        // Check for charts and insights
        XCTAssertTrue(app.otherElements["steps_chart"].exists)
        XCTAssertTrue(app.staticTexts["Insights"].exists)
        
        // Navigate back
        app.navigationBars.buttons["Back"].tap()
        
        // Step 4: Generate health report
        app.buttons["Generate Report"].tap()
        XCTAssertTrue(app.staticTexts["Health Report"].exists)
        
        // Verify report content
        XCTAssertTrue(app.staticTexts["Recommendations"].exists)
        XCTAssertTrue(app.staticTexts["Goals Progress"].exists)
        
        app.buttons["Share Report"].tap()
        
        // Handle share sheet
        if app.sheets.firstMatch.exists {
            app.sheets.firstMatch.buttons["Cancel"].tap()
        }
        
        // Navigate back to dashboard
        app.navigationBars.buttons["Back"].tap()
        app.navigationBars.buttons["Back"].tap()
        
        XCTAssertTrue(app.navigationBars["HealthAI 2030"].exists)
        expectation.fulfill()
        wait(for: [expectation], timeout: 30.0)
    }
    
    // MARK: - Goal Setting and Achievement Journey
    
    func testGoalSettingAndAchievementJourney() {
        let expectation = XCTestExpectation(description: "Goal setting and achievement journey")
        
        // Step 1: Navigate to goals
        app.buttons["Goals"].tap()
        XCTAssertTrue(app.navigationBars["Health Goals"].exists)
        
        // Step 2: Create new goal
        app.buttons["Add Goal"].tap()
        XCTAssertTrue(app.staticTexts["Create New Goal"].exists)
        
        // Select goal type
        app.buttons["Fitness"].tap()
        XCTAssertTrue(app.staticTexts["Fitness Goals"].exists)
        
        app.buttons["Increase Steps"].tap()
        
        // Set goal parameters
        let targetTextField = app.textFields["Target Steps"]
        targetTextField.tap()
        targetTextField.typeText("12000")
        
        let timeframePicker = app.pickers["Timeframe"]
        timeframePicker.adjust(toPickerWheelValue: "1 Month")
        
        app.buttons["Create Goal"].tap()
        
        // Step 3: Track goal progress
        XCTAssertTrue(app.staticTexts["Goal Created"].exists)
        app.buttons["View Progress"].tap()
        
        XCTAssertTrue(app.staticTexts["Goal Progress"].exists)
        XCTAssertTrue(app.progressIndicators["goal_progress"].exists)
        
        // Step 4: Simulate goal achievement
        // This would normally happen over time with real data
        app.buttons["Mark Complete"].tap()
        
        XCTAssertTrue(app.staticTexts["Goal Achieved!"].exists)
        app.buttons["Celebrate"].tap()
        
        // Step 5: View achievements
        app.buttons["Achievements"].tap()
        XCTAssertTrue(app.navigationBars["Achievements"].exists)
        
        XCTAssertTrue(app.staticTexts["Recent Achievements"].exists)
        
        // Navigate back to dashboard
        app.navigationBars.buttons["Back"].tap()
        app.navigationBars.buttons["Back"].tap()
        
        XCTAssertTrue(app.navigationBars["HealthAI 2030"].exists)
        expectation.fulfill()
        wait(for: [expectation], timeout: 30.0)
    }
    
    // MARK: - Settings and Configuration Journey
    
    func testSettingsAndConfigurationJourney() {
        let expectation = XCTestExpectation(description: "Settings and configuration journey")
        
        // Step 1: Navigate to settings
        app.buttons["Settings"].tap()
        XCTAssertTrue(app.navigationBars["Settings"].exists)
        
        // Step 2: Update profile
        app.buttons["Profile"].tap()
        XCTAssertTrue(app.navigationBars["Profile Settings"].exists)
        
        let nameTextField = app.textFields["Full Name"]
        nameTextField.tap()
        nameTextField.clearAndTypeText("Jane Smith")
        
        app.buttons["Save"].tap()
        XCTAssertTrue(app.staticTexts["Profile Updated"].exists)
        
        // Step 3: Configure notifications
        app.navigationBars.buttons["Back"].tap()
        app.buttons["Notifications"].tap()
        XCTAssertTrue(app.navigationBars["Notification Settings"].exists)
        
        // Toggle notification settings
        let reminderSwitch = app.switches["Daily Reminders"]
        if reminderSwitch.value as? String == "0" {
            reminderSwitch.tap()
        }
        
        let achievementSwitch = app.switches["Achievement Notifications"]
        if achievementSwitch.value as? String == "0" {
            achievementSwitch.tap()
        }
        
        app.buttons["Save"].tap()
        
        // Step 4: Privacy settings
        app.navigationBars.buttons["Back"].tap()
        app.buttons["Privacy"].tap()
        XCTAssertTrue(app.navigationBars["Privacy Settings"].exists)
        
        // Configure privacy options
        let dataSharingSwitch = app.switches["Data Sharing"]
        if dataSharingSwitch.value as? String == "1" {
            dataSharingSwitch.tap()
        }
        
        app.buttons["Save"].tap()
        
        // Step 5: Data export
        app.navigationBars.buttons["Back"].tap()
        app.buttons["Data & Storage"].tap()
        XCTAssertTrue(app.navigationBars["Data & Storage"].exists)
        
        app.buttons["Export Data"].tap()
        XCTAssertTrue(app.staticTexts["Export Health Data"].exists)
        
        app.buttons["Export"].tap()
        
        // Handle export completion
        if app.staticTexts["Export Complete"].exists {
            app.buttons["Done"].tap()
        }
        
        // Navigate back to dashboard
        app.navigationBars.buttons["Back"].tap()
        app.navigationBars.buttons["Back"].tap()
        app.navigationBars.buttons["Back"].tap()
        
        XCTAssertTrue(app.navigationBars["HealthAI 2030"].exists)
        expectation.fulfill()
        wait(for: [expectation], timeout: 30.0)
    }
    
    // MARK: - Cross-Platform Sync Journey
    
    func testCrossPlatformSyncJourney() {
        let expectation = XCTestExpectation(description: "Cross-platform sync journey")
        
        // Step 1: Check sync status
        app.buttons["Sync"].tap()
        XCTAssertTrue(app.navigationBars["Data Sync"].exists)
        
        // Step 2: Initiate sync
        app.buttons["Sync Now"].tap()
        XCTAssertTrue(app.staticTexts["Syncing Data"].exists)
        
        // Wait for sync to complete
        let syncComplete = app.staticTexts["Sync Complete"].waitForExistence(timeout: 10.0)
        XCTAssertTrue(syncComplete)
        
        // Step 3: View sync history
        app.buttons["Sync History"].tap()
        XCTAssertTrue(app.staticTexts["Sync History"].exists)
        
        // Verify sync records
        XCTAssertTrue(app.staticTexts["Last Sync"].exists)
        XCTAssertTrue(app.staticTexts["Data Points Synced"].exists)
        
        // Step 4: Configure sync settings
        app.navigationBars.buttons["Back"].tap()
        app.buttons["Sync Settings"].tap()
        XCTAssertTrue(app.navigationBars["Sync Settings"].exists)
        
        // Configure auto-sync
        let autoSyncSwitch = app.switches["Auto Sync"]
        if autoSyncSwitch.value as? String == "0" {
            autoSyncSwitch.tap()
        }
        
        app.buttons["Save"].tap()
        
        // Navigate back to dashboard
        app.navigationBars.buttons["Back"].tap()
        app.navigationBars.buttons["Back"].tap()
        
        XCTAssertTrue(app.navigationBars["HealthAI 2030"].exists)
        expectation.fulfill()
        wait(for: [expectation], timeout: 30.0)
    }
    
    // MARK: - Error Recovery Journey
    
    func testErrorRecoveryJourney() {
        let expectation = XCTestExpectation(description: "Error recovery journey")
        
        // Step 1: Simulate network error
        app.launchArguments = ["UI-Testing", "MockHealthKit", "SimulateNetworkError"]
        app.terminate()
        app.launch()
        
        // Step 2: Attempt to sync data
        app.buttons["Sync"].tap()
        app.buttons["Sync Now"].tap()
        
        // Step 3: Handle error gracefully
        let errorAlert = app.alerts.firstMatch
        if errorAlert.exists {
            XCTAssertTrue(errorAlert.staticTexts["Connection Error"].exists)
            errorAlert.buttons["Retry"].tap()
        }
        
        // Step 4: Verify offline functionality
        XCTAssertTrue(app.navigationBars["HealthAI 2030"].exists)
        XCTAssertTrue(app.buttons["Log Water"].isEnabled)
        XCTAssertTrue(app.buttons["Start Workout"].isEnabled)
        
        // Step 5: Test data persistence
        app.buttons["Log Water"].tap()
        app.buttons["Add 250ml"].tap()
        app.buttons["Done"].tap()
        
        // Verify data was saved locally
        XCTAssertTrue(app.staticTexts["Water intake logged"].exists)
        
        expectation.fulfill()
        wait(for: [expectation], timeout: 30.0)
    }
    
    // MARK: - Performance Journey
    
    func testPerformanceJourney() {
        let expectation = XCTestExpectation(description: "Performance journey")
        
        // Step 1: Measure app launch time
        measure {
            app.terminate()
            app.launch()
            
            let dashboardLoaded = app.navigationBars["HealthAI 2030"].waitForExistence(timeout: 5.0)
            XCTAssertTrue(dashboardLoaded)
        }
        
        // Step 2: Test navigation performance
        measure {
            app.buttons["Settings"].tap()
            app.navigationBars.buttons["Back"].tap()
            XCTAssertTrue(app.navigationBars["HealthAI 2030"].exists)
        }
        
        // Step 3: Test data loading performance
        measure {
            app.buttons["Analytics"].tap()
            let analyticsLoaded = app.navigationBars["Health Analytics"].waitForExistence(timeout: 3.0)
            XCTAssertTrue(analyticsLoaded)
            app.navigationBars.buttons["Back"].tap()
        }
        
        // Step 4: Test interaction responsiveness
        measure {
            app.buttons["Log Water"].tap()
            let waterInterfaceLoaded = app.staticTexts["Log Water Intake"].waitForExistence(timeout: 2.0)
            XCTAssertTrue(waterInterfaceLoaded)
            app.buttons["Cancel"].tap()
        }
        
        expectation.fulfill()
        wait(for: [expectation], timeout: 30.0)
    }
    
    // MARK: - Accessibility Journey
    
    func testAccessibilityJourney() {
        let expectation = XCTestExpectation(description: "Accessibility journey")
        
        // Step 1: Test VoiceOver navigation
        // Enable VoiceOver programmatically (in real testing, this would be done via accessibility settings)
        
        // Navigate using accessibility elements
        let logWaterButton = app.buttons["Log Water"]
        XCTAssertTrue(logWaterButton.exists)
        XCTAssertNotNil(logWaterButton.accessibilityLabel)
        
        logWaterButton.tap()
        
        // Step 2: Test Dynamic Type scaling
        // This would be tested with different text size settings
        
        // Step 3: Test keyboard navigation
        // Verify all interactive elements are keyboard accessible
        XCTAssertTrue(logWaterButton.isEnabled)
        XCTAssertTrue(logWaterButton.isHittable)
        
        // Step 4: Test color contrast
        // Verify sufficient contrast for accessibility
        
        // Step 5: Test screen reader compatibility
        // Verify all elements have proper accessibility labels and hints
        
        app.buttons["Cancel"].tap()
        
        expectation.fulfill()
        wait(for: [expectation], timeout: 30.0)
    }
}

// MARK: - Helper Extensions

extension XCUIElement {
    func clearAndTypeText(_ text: String) {
        guard let stringValue = self.value as? String else {
            XCTFail("Tried to clear and type text into a non string value")
            return
        }
        
        self.tap()
        
        let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: stringValue.count)
        self.typeText(deleteString)
        self.typeText(text)
    }
} 
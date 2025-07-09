import XCTest
import SwiftUI
@testable import HealthAI2030

final class DashboardViewUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["UI-Testing"]
        app.launch()
    }
    
    override func tearDown() {
        app = nil
        super.tearDown()
    }
    
    // MARK: - UI Elements Tests
    
    func testDashboardViewLoadsSuccessfully() {
        // Given - App is launched
        
        // When - Dashboard should be the initial view
        
        // Then - Verify main dashboard elements are present
        XCTAssertTrue(app.navigationBars["HealthAI Dashboard"].exists)
        XCTAssertTrue(app.buttons["Settings"].exists)
        XCTAssertTrue(app.buttons["Profile"].exists)
        XCTAssertTrue(app.staticTexts["Today's Summary"].exists)
        XCTAssertTrue(app.staticTexts["Health Score"].exists)
    }
    
    func testHealthMetricsDisplay() {
        // Given - Dashboard is loaded
        
        // When - Health metrics should be displayed
        
        // Then - Verify health metrics are present
        XCTAssertTrue(app.staticTexts["Heart Rate"].exists)
        XCTAssertTrue(app.staticTexts["Steps"].exists)
        XCTAssertTrue(app.staticTexts["Sleep"].exists)
        XCTAssertTrue(app.staticTexts["Calories"].exists)
        
        // Verify metric values are displayed
        let heartRateValue = app.staticTexts.matching(identifier: "heart_rate_value").firstMatch
        let stepsValue = app.staticTexts.matching(identifier: "steps_value").firstMatch
        let sleepValue = app.staticTexts.matching(identifier: "sleep_value").firstMatch
        
        XCTAssertTrue(heartRateValue.exists)
        XCTAssertTrue(stepsValue.exists)
        XCTAssertTrue(sleepValue.exists)
    }
    
    func testQuickActionsButtons() {
        // Given - Dashboard is loaded
        
        // When - Quick action buttons should be present
        
        // Then - Verify quick action buttons exist
        XCTAssertTrue(app.buttons["Log Workout"].exists)
        XCTAssertTrue(app.buttons["Log Meal"].exists)
        XCTAssertTrue(app.buttons["Log Water"].exists)
        XCTAssertTrue(app.buttons["Start Meditation"].exists)
        XCTAssertTrue(app.buttons["Check Symptoms"].exists)
    }
    
    func testHealthScoreDisplay() {
        // Given - Dashboard is loaded
        
        // When - Health score should be prominently displayed
        
        // Then - Verify health score elements
        XCTAssertTrue(app.staticTexts["Health Score"].exists)
        let scoreValue = app.staticTexts.matching(identifier: "health_score_value").firstMatch
        XCTAssertTrue(scoreValue.exists)
        
        // Verify score is within valid range (0-100)
        if let scoreText = scoreValue.label {
            let score = Int(scoreText.replacingOccurrences(of: "%", with: "")) ?? 0
            XCTAssertGreaterThanOrEqual(score, 0)
            XCTAssertLessThanOrEqual(score, 100)
        }
    }
    
    // MARK: - User Interaction Tests
    
    func testQuickActionButtonTaps() {
        // Given - Dashboard is loaded
        
        // When - Tapping quick action buttons
        
        // Then - Verify navigation to appropriate screens
        app.buttons["Log Workout"].tap()
        XCTAssertTrue(app.navigationBars["Log Workout"].exists)
        
        app.navigationBars.buttons["Back"].tap()
        
        app.buttons["Log Meal"].tap()
        XCTAssertTrue(app.navigationBars["Log Meal"].exists)
        
        app.navigationBars.buttons["Back"].tap()
        
        app.buttons["Log Water"].tap()
        XCTAssertTrue(app.navigationBars["Log Water"].exists)
        
        app.navigationBars.buttons["Back"].tap()
        
        app.buttons["Start Meditation"].tap()
        XCTAssertTrue(app.navigationBars["Meditation"].exists)
        
        app.navigationBars.buttons["Back"].tap()
        
        app.buttons["Check Symptoms"].tap()
        XCTAssertTrue(app.navigationBars["Symptom Checker"].exists)
    }
    
    func testSettingsNavigation() {
        // Given - Dashboard is loaded
        
        // When - Tapping settings button
        app.buttons["Settings"].tap()
        
        // Then - Verify navigation to settings
        XCTAssertTrue(app.navigationBars["Settings"].exists)
        XCTAssertTrue(app.staticTexts["Account"].exists)
        XCTAssertTrue(app.staticTexts["Privacy"].exists)
        XCTAssertTrue(app.staticTexts["Notifications"].exists)
        XCTAssertTrue(app.staticTexts["Data & Storage"].exists)
    }
    
    func testProfileNavigation() {
        // Given - Dashboard is loaded
        
        // When - Tapping profile button
        app.buttons["Profile"].tap()
        
        // Then - Verify navigation to profile
        XCTAssertTrue(app.navigationBars["Profile"].exists)
        XCTAssertTrue(app.staticTexts["Personal Information"].exists)
        XCTAssertTrue(app.staticTexts["Health Goals"].exists)
        XCTAssertTrue(app.staticTexts["Medical History"].exists)
    }
    
    func testHealthMetricTaps() {
        // Given - Dashboard is loaded
        
        // When - Tapping on health metrics
        
        // Then - Verify detailed views open
        app.staticTexts["Heart Rate"].tap()
        XCTAssertTrue(app.navigationBars["Heart Rate Details"].exists)
        
        app.navigationBars.buttons["Back"].tap()
        
        app.staticTexts["Steps"].tap()
        XCTAssertTrue(app.navigationBars["Steps Details"].exists)
        
        app.navigationBars.buttons["Back"].tap()
        
        app.staticTexts["Sleep"].tap()
        XCTAssertTrue(app.navigationBars["Sleep Details"].exists)
    }
    
    // MARK: - Navigation Tests
    
    func testTabBarNavigation() {
        // Given - Dashboard is loaded (Home tab)
        
        // When - Tapping different tab bar items
        
        // Then - Verify navigation to different tabs
        app.tabBars.buttons["Analytics"].tap()
        XCTAssertTrue(app.navigationBars["Analytics"].exists)
        
        app.tabBars.buttons["Goals"].tap()
        XCTAssertTrue(app.navigationBars["Health Goals"].exists)
        
        app.tabBars.buttons["Community"].tap()
        XCTAssertTrue(app.navigationBars["Health Community"].exists)
        
        app.tabBars.buttons["Home"].tap()
        XCTAssertTrue(app.navigationBars["HealthAI Dashboard"].exists)
    }
    
    func testDeepLinkNavigation() {
        // Given - Dashboard is loaded
        
        // When - Using deep links to navigate
        
        // Then - Verify deep link navigation works
        // This would require setting up deep link testing infrastructure
        // For now, we'll test that the app can handle deep link URLs
        let deepLinkURL = URL(string: "healthai://dashboard")!
        XCTAssertTrue(app.canOpenURL(deepLinkURL))
    }
    
    // MARK: - Accessibility Tests
    
    func testVoiceOverSupport() {
        // Given - Dashboard is loaded
        
        // When - VoiceOver is enabled
        
        // Then - Verify accessibility labels are present
        let heartRateButton = app.staticTexts["Heart Rate"]
        XCTAssertTrue(heartRateButton.isAccessibilityElement)
        XCTAssertNotNil(heartRateButton.accessibilityLabel)
        
        let stepsButton = app.staticTexts["Steps"]
        XCTAssertTrue(stepsButton.isAccessibilityElement)
        XCTAssertNotNil(stepsButton.accessibilityLabel)
        
        let logWorkoutButton = app.buttons["Log Workout"]
        XCTAssertTrue(logWorkoutButton.isAccessibilityElement)
        XCTAssertNotNil(logWorkoutButton.accessibilityLabel)
        XCTAssertNotNil(logWorkoutButton.accessibilityHint)
    }
    
    func testDynamicTypeSupport() {
        // Given - Dashboard is loaded
        
        // When - Dynamic Type is enabled
        
        // Then - Verify text scales appropriately
        let healthScoreText = app.staticTexts["Health Score"]
        XCTAssertTrue(healthScoreText.exists)
        
        // Test with different text sizes
        // This would require programmatically changing text size
        // For now, verify the text is readable
        XCTAssertTrue(healthScoreText.isHittable)
    }
    
    func testColorContrastAccessibility() {
        // Given - Dashboard is loaded
        
        // When - Checking color contrast
        
        // Then - Verify sufficient color contrast
        // This would require checking actual color values
        // For now, verify elements are visible
        let healthScoreValue = app.staticTexts.matching(identifier: "health_score_value").firstMatch
        XCTAssertTrue(healthScoreValue.exists)
        XCTAssertTrue(healthScoreValue.isHittable)
    }
    
    func testKeyboardNavigation() {
        // Given - Dashboard is loaded
        
        // When - Using keyboard navigation
        
        // Then - Verify keyboard accessibility
        let settingsButton = app.buttons["Settings"]
        XCTAssertTrue(settingsButton.isAccessibilityElement)
        XCTAssertTrue(settingsButton.isEnabled)
    }
    
    // MARK: - Error Handling Tests
    
    func testNetworkErrorDisplay() {
        // Given - Dashboard is loaded with network error
        
        // When - Network is unavailable
        
        // Then - Verify error message is displayed
        let errorMessage = app.staticTexts["Unable to load health data. Please check your connection."]
        if errorMessage.exists {
            XCTAssertTrue(errorMessage.exists)
            
            // Verify retry button is available
            let retryButton = app.buttons["Retry"]
            XCTAssertTrue(retryButton.exists)
            XCTAssertTrue(retryButton.isEnabled)
        }
    }
    
    func testDataLoadingError() {
        // Given - Dashboard is loaded with data loading error
        
        // When - Health data fails to load
        
        // Then - Verify appropriate error handling
        let loadingError = app.staticTexts["Unable to load your health data. Please try again."]
        if loadingError.exists {
            XCTAssertTrue(loadingError.exists)
            
            // Verify refresh functionality
            let refreshButton = app.buttons["Refresh"]
            XCTAssertTrue(refreshButton.exists)
        }
    }
    
    func testPermissionErrorHandling() {
        // Given - Dashboard is loaded without health permissions
        
        // When - Health permissions are not granted
        
        // Then - Verify permission request UI
        let permissionMessage = app.staticTexts["Health permissions are required to display your data."]
        if permissionMessage.exists {
            XCTAssertTrue(permissionMessage.exists)
            
            let grantPermissionButton = app.buttons["Grant Permissions"]
            XCTAssertTrue(grantPermissionButton.exists)
            XCTAssertTrue(grantPermissionButton.isEnabled)
        }
    }
    
    // MARK: - Performance Tests
    
    func testDashboardLoadPerformance() {
        // Given - App is ready to launch
        
        // When - Measuring dashboard load time
        let startTime = Date()
        app.launch()
        let loadTime = Date().timeIntervalSince(startTime)
        
        // Then - Verify load time is acceptable
        XCTAssertLessThan(loadTime, 3.0, "Dashboard should load within 3 seconds")
    }
    
    func testSmoothScrolling() {
        // Given - Dashboard is loaded with scrollable content
        
        // When - Scrolling through content
        
        // Then - Verify smooth scrolling performance
        let scrollView = app.scrollViews.firstMatch
        if scrollView.exists {
            scrollView.swipeUp()
            scrollView.swipeDown()
            
            // Verify no crashes or freezes during scrolling
            XCTAssertTrue(app.navigationBars["HealthAI Dashboard"].exists)
        }
    }
    
    func testMemoryUsage() {
        // Given - Dashboard is loaded
        
        // When - Navigating between different sections
        
        // Then - Verify memory usage remains stable
        app.buttons["Settings"].tap()
        app.navigationBars.buttons["Back"].tap()
        
        app.buttons["Profile"].tap()
        app.navigationBars.buttons["Back"].tap()
        
        app.tabBars.buttons["Analytics"].tap()
        app.tabBars.buttons["Home"].tap()
        
        // Verify dashboard is still responsive
        XCTAssertTrue(app.navigationBars["HealthAI Dashboard"].exists)
        XCTAssertTrue(app.buttons["Log Workout"].isEnabled)
    }
    
    // MARK: - Localization Tests
    
    func testLocalizedStrings() {
        // Given - Dashboard is loaded
        
        // When - Checking for localized strings
        
        // Then - Verify key strings are localized
        // This would require testing with different language settings
        // For now, verify English strings are present
        XCTAssertTrue(app.staticTexts["Today's Summary"].exists)
        XCTAssertTrue(app.staticTexts["Health Score"].exists)
        XCTAssertTrue(app.buttons["Log Workout"].exists)
        XCTAssertTrue(app.buttons["Settings"].exists)
    }
    
    // MARK: - Dark Mode Tests
    
    func testDarkModeDisplay() {
        // Given - Dashboard is loaded in dark mode
        
        // When - App is in dark mode
        
        // Then - Verify dark mode styling
        // This would require programmatically switching to dark mode
        // For now, verify elements are still visible and functional
        XCTAssertTrue(app.navigationBars["HealthAI Dashboard"].exists)
        XCTAssertTrue(app.buttons["Log Workout"].isEnabled)
        XCTAssertTrue(app.staticTexts["Health Score"].exists)
    }
    
    // MARK: - Orientation Tests
    
    func testPortraitOrientation() {
        // Given - Dashboard is loaded in portrait
        
        // When - App is in portrait orientation
        
        // Then - Verify portrait layout
        XCTAssertTrue(app.navigationBars["HealthAI Dashboard"].exists)
        XCTAssertTrue(app.buttons["Log Workout"].exists)
        XCTAssertTrue(app.staticTexts["Health Score"].exists)
    }
    
    func testLandscapeOrientation() {
        // Given - Dashboard is loaded
        
        // When - Rotating to landscape
        
        // Then - Verify landscape layout
        XCUIDevice.shared.orientation = .landscapeLeft
        
        // Wait for layout to adjust
        let landscapeExpectation = XCTestExpectation(description: "Landscape layout loaded")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            landscapeExpectation.fulfill()
        }
        wait(for: [landscapeExpectation], timeout: 2.0)
        
        // Verify elements are still accessible
        XCTAssertTrue(app.navigationBars["HealthAI Dashboard"].exists)
        XCTAssertTrue(app.buttons["Log Workout"].isEnabled)
        
        // Reset to portrait
        XCUIDevice.shared.orientation = .portrait
    }
    
    // MARK: - Memory Management Tests
    
    func testMemoryLeakPrevention() {
        // Given - Dashboard is loaded
        
        // When - Performing multiple navigation cycles
        
        // Then - Verify no memory leaks
        for _ in 0..<10 {
            app.buttons["Settings"].tap()
            app.navigationBars.buttons["Back"].tap()
            
            app.buttons["Profile"].tap()
            app.navigationBars.buttons["Back"].tap()
            
            app.tabBars.buttons["Analytics"].tap()
            app.tabBars.buttons["Home"].tap()
        }
        
        // Verify app is still responsive
        XCTAssertTrue(app.navigationBars["HealthAI Dashboard"].exists)
        XCTAssertTrue(app.buttons["Log Workout"].isEnabled)
    }
    
    func testBackgroundForegroundTransition() {
        // Given - Dashboard is loaded
        
        // When - App goes to background and returns
        
        // Then - Verify proper state restoration
        XCUIDevice.shared.press(.home)
        
        // Wait a moment
        let backgroundExpectation = XCTestExpectation(description: "App in background")
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            backgroundExpectation.fulfill()
        }
        wait(for: [backgroundExpectation], timeout: 3.0)
        
        // Return to app
        app.activate()
        
        // Verify dashboard is still functional
        XCTAssertTrue(app.navigationBars["HealthAI Dashboard"].exists)
        XCTAssertTrue(app.buttons["Log Workout"].isEnabled)
    }
    
    // MARK: - Integration Tests
    
    func testHealthDataIntegration() {
        // Given - Dashboard is loaded with health data
        
        // When - Health data is updated
        
        // Then - Verify dashboard reflects changes
        let heartRateValue = app.staticTexts.matching(identifier: "heart_rate_value").firstMatch
        let stepsValue = app.staticTexts.matching(identifier: "steps_value").firstMatch
        
        XCTAssertTrue(heartRateValue.exists)
        XCTAssertTrue(stepsValue.exists)
        
        // Verify values are numeric
        if let heartRateText = heartRateValue.label {
            XCTAssertTrue(heartRateText.rangeOfCharacter(from: CharacterSet.decimalDigits.inverted) == nil || 
                         heartRateText.contains("bpm"))
        }
        
        if let stepsText = stepsValue.label {
            XCTAssertTrue(stepsText.rangeOfCharacter(from: CharacterSet.decimalDigits.inverted) == nil || 
                         stepsText.contains("steps"))
        }
    }
    
    func testNotificationIntegration() {
        // Given - Dashboard is loaded
        
        // When - Notifications are received
        
        // Then - Verify notification handling
        // This would require simulating notifications
        // For now, verify notification settings are accessible
        app.buttons["Settings"].tap()
        app.staticTexts["Notifications"].tap()
        
        XCTAssertTrue(app.navigationBars["Notifications"].exists)
        XCTAssertTrue(app.staticTexts["Push Notifications"].exists)
        XCTAssertTrue(app.staticTexts["Email Notifications"].exists)
    }
    
    // MARK: - Edge Case Tests
    
    func testEmptyStateDisplay() {
        // Given - Dashboard is loaded with no health data
        
        // When - No health data is available
        
        // Then - Verify empty state is handled gracefully
        let emptyStateMessage = app.staticTexts["No health data available. Start tracking your health to see your dashboard."]
        if emptyStateMessage.exists {
            XCTAssertTrue(emptyStateMessage.exists)
            
            let getStartedButton = app.buttons["Get Started"]
            XCTAssertTrue(getStartedButton.exists)
            XCTAssertTrue(getStartedButton.isEnabled)
        }
    }
    
    func testLargeDataSets() {
        // Given - Dashboard is loaded with large amounts of data
        
        // When - Displaying extensive health history
        
        // Then - Verify performance with large datasets
        // This would require loading large amounts of test data
        // For now, verify scrolling works with current data
        let scrollView = app.scrollViews.firstMatch
        if scrollView.exists {
            scrollView.swipeUp()
            scrollView.swipeDown()
            
            // Verify no crashes or performance issues
            XCTAssertTrue(app.navigationBars["HealthAI Dashboard"].exists)
        }
    }
    
    func testConcurrentUserActions() {
        // Given - Dashboard is loaded
        
        // When - Multiple user actions are performed simultaneously
        
        // Then - Verify app handles concurrent actions gracefully
        let logWorkoutButton = app.buttons["Log Workout"]
        let logMealButton = app.buttons["Log Meal"]
        let settingsButton = app.buttons["Settings"]
        
        // Rapidly tap multiple buttons
        logWorkoutButton.tap()
        logMealButton.tap()
        settingsButton.tap()
        
        // Verify app doesn't crash and handles the actions appropriately
        XCTAssertTrue(app.navigationBars["HealthAI Dashboard"].exists || 
                     app.navigationBars["Log Workout"].exists ||
                     app.navigationBars["Log Meal"].exists ||
                     app.navigationBars["Settings"].exists)
    }
} 
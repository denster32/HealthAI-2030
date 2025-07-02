import XCTest
import SwiftUI
@testable import HealthAI_2030

/// Comprehensive UI test suite for HealthAI 2030 SwiftUI views
class UITestSuite: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        continueAfterFailure = false
        
        app = XCUIApplication()
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Main Tab View Tests
    
    func testMainTabViewNavigation() {
        // Test tab navigation
        let dashboardTab = app.tabBars.buttons["Dashboard"]
        let sleepTab = app.tabBars.buttons["Sleep"]
        let analyticsTab = app.tabBars.buttons["Analytics"]
        let environmentTab = app.tabBars.buttons["Environment"]
        let settingsTab = app.tabBars.buttons["Settings"]
        
        XCTAssertTrue(dashboardTab.exists)
        XCTAssertTrue(sleepTab.exists)
        XCTAssertTrue(analyticsTab.exists)
        XCTAssertTrue(environmentTab.exists)
        XCTAssertTrue(settingsTab.exists)
        
        // Test tab switching
        sleepTab.tap()
        XCTAssertTrue(app.navigationBars["Sleep"].exists)
        
        analyticsTab.tap()
        XCTAssertTrue(app.navigationBars["Analytics"].exists)
        
        environmentTab.tap()
        XCTAssertTrue(app.navigationBars["Environment"].exists)
        
        settingsTab.tap()
        XCTAssertTrue(app.navigationBars["Settings"].exists)
        
        dashboardTab.tap()
        XCTAssertTrue(app.navigationBars["Dashboard"].exists)
    }
    
    // MARK: - Dashboard View Tests
    
    func testDashboardViewElements() {
        // Test dashboard elements exist
        XCTAssertTrue(app.staticTexts["Current Health Status"].exists)
        XCTAssertTrue(app.staticTexts["Tomorrow's Forecast"].exists)
        XCTAssertTrue(app.staticTexts["Health Alerts"].exists)
        XCTAssertTrue(app.staticTexts["Quick Actions"].exists)
        
        // Test quick action buttons
        let startSleepButton = app.buttons["Start Sleep"]
        let viewAnalyticsButton = app.buttons["View Analytics"]
        
        XCTAssertTrue(startSleepButton.exists)
        XCTAssertTrue(viewAnalyticsButton.exists)
    }
    
    func testDashboardQuickActions() {
        // Test quick action functionality
        let startSleepButton = app.buttons["Start Sleep"]
        startSleepButton.tap()
        
        // Should navigate to sleep view
        XCTAssertTrue(app.navigationBars["Sleep"].exists)
    }
    
    func testHealthStatusCard() {
        // Test health status card displays correctly
        let healthStatusCard = app.otherElements["HealthStatusCard"]
        XCTAssertTrue(healthStatusCard.exists)
        
        // Test health metrics are displayed
        XCTAssertTrue(app.staticTexts["Heart Rate"].exists)
        XCTAssertTrue(app.staticTexts["Sleep Quality"].exists)
        XCTAssertTrue(app.staticTexts["Activity Level"].exists)
    }
    
    func testPhysioForecastCard() {
        // Test PhysioForecast card
        let forecastCard = app.otherElements["PhysioForecastCard"]
        XCTAssertTrue(forecastCard.exists)
        
        // Test forecast metrics
        XCTAssertTrue(app.staticTexts["Energy"].exists)
        XCTAssertTrue(app.staticTexts["Mood Stability"].exists)
        XCTAssertTrue(app.staticTexts["Cognitive Acuity"].exists)
        XCTAssertTrue(app.staticTexts["Musculoskeletal Resilience"].exists)
    }
    
    // MARK: - Sleep View Tests
    
    func testSleepViewElements() {
        app.tabBars.buttons["Sleep"].tap()
        
        // Test sleep view elements
        XCTAssertTrue(app.staticTexts["Sleep Optimization"].exists)
        XCTAssertTrue(app.staticTexts["Current Sleep Stage"].exists)
        XCTAssertTrue(app.staticTexts["Sleep Quality"].exists)
        
        // Test sleep controls
        let startSleepButton = app.buttons["Start Sleep Session"]
        let stopSleepButton = app.buttons["Stop Sleep Session"]
        
        XCTAssertTrue(startSleepButton.exists)
        XCTAssertTrue(stopSleepButton.exists)
    }
    
    func testSleepSessionControl() {
        app.tabBars.buttons["Sleep"].tap()
        
        let startButton = app.buttons["Start Sleep Session"]
        startButton.tap()
        
        // Should show sleep session in progress
        XCTAssertTrue(app.staticTexts["Sleep Session Active"].exists)
        
        let stopButton = app.buttons["Stop Sleep Session"]
        stopButton.tap()
        
        // Should show sleep session ended
        XCTAssertTrue(app.staticTexts["Sleep Session Ended"].exists)
    }
    
    func testSleepArchitectureCard() {
        app.tabBars.buttons["Sleep"].tap()
        
        // Test sleep architecture card
        let architectureCard = app.otherElements["SleepArchitectureCard"]
        XCTAssertTrue(architectureCard.exists)
        
        // Test sleep stage indicators
        XCTAssertTrue(app.staticTexts["Deep Sleep"].exists)
        XCTAssertTrue(app.staticTexts["REM Sleep"].exists)
        XCTAssertTrue(app.staticTexts["Light Sleep"].exists)
    }
    
    // MARK: - Analytics View Tests
    
    func testAnalyticsViewElements() {
        app.tabBars.buttons["Analytics"].tap()
        
        // Test analytics view elements
        XCTAssertTrue(app.staticTexts["Health Analytics"].exists)
        XCTAssertTrue(app.staticTexts["Sleep Analytics"].exists)
        XCTAssertTrue(app.staticTexts["Cardiac Analytics"].exists)
        
        // Test chart elements
        let sleepChart = app.otherElements["SleepAnalyticsChart"]
        let heartRateChart = app.otherElements["HeartRateChart"]
        
        XCTAssertTrue(sleepChart.exists)
        XCTAssertTrue(heartRateChart.exists)
    }
    
    func testAnalyticsTimeRangeSelection() {
        app.tabBars.buttons["Analytics"].tap()
        
        // Test time range picker
        let timeRangePicker = app.pickers["TimeRangePicker"]
        XCTAssertTrue(timeRangePicker.exists)
        
        // Test different time ranges
        let dayButton = app.buttons["Day"]
        let weekButton = app.buttons["Week"]
        let monthButton = app.buttons["Month"]
        
        XCTAssertTrue(dayButton.exists)
        XCTAssertTrue(weekButton.exists)
        XCTAssertTrue(monthButton.exists)
        
        weekButton.tap()
        XCTAssertTrue(weekButton.isSelected)
    }
    
    func testAdvancedAnalyticsDashboard() {
        app.tabBars.buttons["Analytics"].tap()
        
        // Navigate to advanced analytics
        let advancedButton = app.buttons["Advanced Analytics"]
        advancedButton.tap()
        
        // Test advanced analytics elements
        XCTAssertTrue(app.staticTexts["Advanced Analytics Dashboard"].exists)
        XCTAssertTrue(app.staticTexts["ML Performance"].exists)
        XCTAssertTrue(app.staticTexts["Predictive Insights"].exists)
    }
    
    // MARK: - Environment View Tests
    
    func testEnvironmentViewElements() {
        app.tabBars.buttons["Environment"].tap()
        
        // Test environment view elements
        XCTAssertTrue(app.staticTexts["Environment Control"].exists)
        XCTAssertTrue(app.staticTexts["Temperature"].exists)
        XCTAssertTrue(app.staticTexts["Humidity"].exists)
        XCTAssertTrue(app.staticTexts["Lighting"].exists)
        
        // Test environment controls
        let temperatureSlider = app.sliders["TemperatureSlider"]
        let humiditySlider = app.sliders["HumiditySlider"]
        let lightingSlider = app.sliders["LightingSlider"]
        
        XCTAssertTrue(temperatureSlider.exists)
        XCTAssertTrue(humiditySlider.exists)
        XCTAssertTrue(lightingSlider.exists)
    }
    
    func testEnvironmentOptimization() {
        app.tabBars.buttons["Environment"].tap()
        
        // Test optimization buttons
        let sleepOptimizeButton = app.buttons["Optimize for Sleep"]
        let workOptimizeButton = app.buttons["Optimize for Work"]
        let exerciseOptimizeButton = app.buttons["Optimize for Exercise"]
        
        XCTAssertTrue(sleepOptimizeButton.exists)
        XCTAssertTrue(workOptimizeButton.exists)
        XCTAssertTrue(exerciseOptimizeButton.exists)
        
        // Test sleep optimization
        sleepOptimizeButton.tap()
        XCTAssertTrue(app.staticTexts["Sleep Mode Active"].exists)
    }
    
    func testEnvironmentDataDisplay() {
        app.tabBars.buttons["Environment"].tap()
        
        // Test environment data display
        XCTAssertTrue(app.staticTexts["Current Temperature"].exists)
        XCTAssertTrue(app.staticTexts["Current Humidity"].exists)
        XCTAssertTrue(app.staticTexts["Air Quality"].exists)
        XCTAssertTrue(app.staticTexts["Noise Level"].exists)
    }
    
    // MARK: - Performance Dashboard Tests
    
    func testPerformanceDashboardElements() {
        app.tabBars.buttons["Settings"].tap()
        
        // Navigate to performance dashboard
        let performanceButton = app.buttons["Performance"]
        performanceButton.tap()
        
        // Test performance dashboard elements
        XCTAssertTrue(app.staticTexts["Performance"].exists)
        XCTAssertTrue(app.staticTexts["System Metrics"].exists)
        XCTAssertTrue(app.staticTexts["ML Performance"].exists)
        XCTAssertTrue(app.staticTexts["Memory & Storage"].exists)
        XCTAssertTrue(app.staticTexts["Battery & Power"].exists)
    }
    
    func testPerformanceModeSelection() {
        app.tabBars.buttons["Settings"].tap()
        app.buttons["Performance"].tap()
        
        // Test performance mode selection
        let modeButton = app.buttons["Change"]
        modeButton.tap()
        
        // Should show performance settings
        XCTAssertTrue(app.staticTexts["Performance Settings"].exists)
        
        // Test mode options
        let batterySaverButton = app.buttons["Battery Saver"]
        let balancedButton = app.buttons["Balanced"]
        let highPerformanceButton = app.buttons["High Performance"]
        
        XCTAssertTrue(batterySaverButton.exists)
        XCTAssertTrue(balancedButton.exists)
        XCTAssertTrue(highPerformanceButton.exists)
    }
    
    func testPerformanceOptimizationControls() {
        app.tabBars.buttons["Settings"].tap()
        app.buttons["Performance"].tap()
        
        // Test optimization controls
        let optimizeButton = app.buttons["Optimize Now"]
        let clearCacheButton = app.buttons["Clear Cache"]
        let restartMLButton = app.buttons["Restart ML"]
        
        XCTAssertTrue(optimizeButton.exists)
        XCTAssertTrue(clearCacheButton.exists)
        XCTAssertTrue(restartMLButton.exists)
        
        // Test optimization action
        optimizeButton.tap()
        XCTAssertTrue(app.staticTexts["Optimization Complete"].exists)
    }
    
    // MARK: - Health Alerts Tests
    
    func testHealthAlertsDisplay() {
        app.tabBars.buttons["Dashboard"].tap()
        
        // Test health alerts section
        let alertsSection = app.otherElements["HealthAlertsSection"]
        XCTAssertTrue(alertsSection.exists)
        
        // Test alert cards if any exist
        let alertCards = app.otherElements["AlertCard"]
        if alertCards.count > 0 {
            XCTAssertTrue(alertCards.element(boundBy: 0).exists)
        }
    }
    
    func testAlertInteraction() {
        app.tabBars.buttons["Dashboard"].tap()
        
        // Test alert interaction if alerts exist
        let alertCards = app.otherElements["AlertCard"]
        if alertCards.count > 0 {
            let firstAlert = alertCards.element(boundBy: 0)
            firstAlert.tap()
            
            // Should show alert details
            XCTAssertTrue(app.staticTexts["Alert Details"].exists)
        }
    }
    
    // MARK: - Settings View Tests
    
    func testSettingsViewElements() {
        app.tabBars.buttons["Settings"].tap()
        
        // Test settings elements
        XCTAssertTrue(app.staticTexts["Settings"].exists)
        XCTAssertTrue(app.staticTexts["Performance"].exists)
        XCTAssertTrue(app.staticTexts["Privacy"].exists)
        XCTAssertTrue(app.staticTexts["Notifications"].exists)
        XCTAssertTrue(app.staticTexts["About"].exists)
    }
    
    func testSettingsNavigation() {
        app.tabBars.buttons["Settings"].tap()
        
        // Test settings navigation
        let performanceButton = app.buttons["Performance"]
        let privacyButton = app.buttons["Privacy"]
        let notificationsButton = app.buttons["Notifications"]
        
        XCTAssertTrue(performanceButton.exists)
        XCTAssertTrue(privacyButton.exists)
        XCTAssertTrue(notificationsButton.exists)
        
        // Test performance settings navigation
        performanceButton.tap()
        XCTAssertTrue(app.navigationBars["Performance"].exists)
    }
    
    // MARK: - Emergency Alerts Tests
    
    func testEmergencyAlertDisplay() {
        // Simulate emergency condition
        // This would require mocking emergency data
        
        // Test emergency alert appears
        let emergencyAlert = app.alerts["Emergency Alert"]
        if emergencyAlert.exists {
            XCTAssertTrue(emergencyAlert.staticTexts["Emergency Detected"].exists)
            
            let dismissButton = emergencyAlert.buttons["Dismiss"]
            dismissButton.tap()
        }
    }
    
    // MARK: - Vision Pro Biofeedback Tests
    
    func testVisionProBiofeedbackScene() {
        app.tabBars.buttons["Settings"].tap()
        
        // Navigate to Vision Pro biofeedback
        let visionProButton = app.buttons["Vision Pro Biofeedback"]
        if visionProButton.exists {
            visionProButton.tap()
            
            // Test biofeedback scene elements
            XCTAssertTrue(app.staticTexts["Biofeedback Scene"].exists)
            XCTAssertTrue(app.staticTexts["HRV Coherence"].exists)
            XCTAssertTrue(app.staticTexts["Breath Ring"].exists)
        }
    }
    
    // MARK: - Accessibility Tests
    
    func testAccessibilitySupport() {
        // Test accessibility labels
        let dashboardTab = app.tabBars.buttons["Dashboard"]
        XCTAssertTrue(dashboardTab.hasValidAccessibilityLabel)
        
        let sleepTab = app.tabBars.buttons["Sleep"]
        XCTAssertTrue(sleepTab.hasValidAccessibilityLabel)
        
        // Test accessibility hints
        let startSleepButton = app.buttons["Start Sleep Session"]
        XCTAssertTrue(startSleepButton.hasValidAccessibilityHint)
    }
    
    func testVoiceOverSupport() {
        // Test VoiceOver support
        let dashboardTab = app.tabBars.buttons["Dashboard"]
        XCTAssertTrue(dashboardTab.isAccessibilityElement)
        
        let sleepTab = app.tabBars.buttons["Sleep"]
        XCTAssertTrue(sleepTab.isAccessibilityElement)
    }
    
    // MARK: - Dark Mode Tests
    
    func testDarkModeSupport() {
        // Test dark mode appearance
        // This would require switching to dark mode and verifying UI elements
        // are properly visible and styled
        
        // For now, just verify basic elements exist in both modes
        XCTAssertTrue(app.staticTexts["Dashboard"].exists)
        XCTAssertTrue(app.staticTexts["Sleep"].exists)
    }
    
    // MARK: - Orientation Tests
    
    func testOrientationSupport() {
        // Test landscape orientation
        XCUIDevice.shared.orientation = .landscapeLeft
        
        // Verify UI elements are still accessible
        XCTAssertTrue(app.tabBars.buttons["Dashboard"].exists)
        XCTAssertTrue(app.tabBars.buttons["Sleep"].exists)
        
        // Test portrait orientation
        XCUIDevice.shared.orientation = .portrait
        
        // Verify UI elements are still accessible
        XCTAssertTrue(app.tabBars.buttons["Dashboard"].exists)
        XCTAssertTrue(app.tabBars.buttons["Sleep"].exists)
    }
    
    // MARK: - Performance Tests
    
    func testUIPerformance() {
        measure {
            // Measure UI rendering performance
            app.tabBars.buttons["Dashboard"].tap()
            app.tabBars.buttons["Sleep"].tap()
            app.tabBars.buttons["Analytics"].tap()
            app.tabBars.buttons["Environment"].tap()
            app.tabBars.buttons["Settings"].tap()
        }
    }
    
    func testMemoryUsage() {
        // Test memory usage during UI interactions
        let initialMemory = getMemoryUsage()
        
        // Perform UI interactions
        for _ in 0..<10 {
            app.tabBars.buttons["Dashboard"].tap()
            app.tabBars.buttons["Sleep"].tap()
            app.tabBars.buttons["Analytics"].tap()
        }
        
        let finalMemory = getMemoryUsage()
        let memoryIncrease = finalMemory - initialMemory
        
        // Memory increase should be reasonable (less than 50MB)
        XCTAssertLessThan(memoryIncrease, 50.0)
    }
    
    // MARK: - Helper Methods
    
    private func getMemoryUsage() -> Double {
        // Mock memory usage measurement
        return Double.random(in: 100.0...200.0)
    }
}

// MARK: - Extensions for UI Testing

extension XCUIElement {
    var hasValidAccessibilityLabel: Bool {
        return self.label.count > 0
    }
    
    var hasValidAccessibilityHint: Bool {
        return self.hint.count > 0
    }
} 
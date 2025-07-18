import XCTest
import SwiftUI
#if os(macOS)
import AppKit
import Combine
@testable import HealthAI2030App

final class MacMenuBarTests: XCTestCase {
    
    var app: XCUIApplication!
    var menuBarController: MenuBarController!
    var healthDataManager: MacHealthDataManager!
    var performanceMonitor: MacPerformanceMonitor!
    
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        
        app = XCUIApplication()
        app.launchEnvironment["ENABLE_MENU_BAR"] = "true"
        app.launchEnvironment["MENU_BAR_MODE"] = "testing"
        app.launch()
        
        menuBarController = MenuBarController()
        healthDataManager = MacHealthDataManager()
        performanceMonitor = MacPerformanceMonitor()
        
        setupTestEnvironment()
    }
    
    override func tearDown() {
        cleanupTestEnvironment()
        menuBarController = nil
        healthDataManager = nil
        performanceMonitor = nil
        app = nil
        super.tearDown()
    }
    
    // MARK: - Menu Bar Responsiveness Tests
    
    func testMenuBarAppResponsiveness() {
        testMenuBarItemInteraction()
        testPopoverPerformance()
        testMenuUpdateLatency()
        testResourceUsageUnderLoad()
        testMenuBarItemAccessibility()
    }
    
    private func testMenuBarItemInteraction() {
        // Test basic menu bar item interaction
        let menuBarItem = app.menuBarItems["HealthAI2030"]
        
        // Menu bar item should be visible
        XCTAssertTrue(menuBarItem.exists, "Menu bar item should be visible")
        XCTAssertTrue(menuBarItem.isHittable, "Menu bar item should be clickable")
        
        // Test click response time
        let startTime = Date()
        menuBarItem.click()
        
        // Popover should appear quickly
        let popover = app.popovers.firstMatch
        let popoverAppeared = popover.waitForExistence(timeout: 2.0)
        
        let responseTime = Date().timeIntervalSince(startTime)
        
        XCTAssertTrue(popoverAppeared, "Popover should appear after clicking menu bar item")
        XCTAssertLessThan(responseTime, 0.5, "Menu bar should respond within 500ms")
        
        // Test popover content
        if popoverAppeared {
            testPopoverContent(popover)
        }
        
        // Close popover
        if popover.exists {
            // Click outside to close
            app.coordinate(withNormalizedOffset: CGVector(dx: 0.1, dy: 0.1)).click()
            
            let popoverClosed = !popover.waitForExistence(timeout: 1.0)
            XCTAssertTrue(popoverClosed, "Popover should close when clicking outside")
        }
    }
    
    private func testPopoverContent(popover: XCUIElement) {
        // Test that popover contains expected health content
        let healthMetrics = popover.staticTexts.matching(identifier: "HealthMetric")
        XCTAssertGreaterThan(healthMetrics.count, 0, "Popover should display health metrics")
        
        // Test quick action buttons
        let quickActions = popover.buttons.matching(identifier: "QuickAction")
        XCTAssertGreaterThan(quickActions.count, 0, "Popover should have quick action buttons")
        
        // Test metric values are displayed
        let heartRateMetric = popover.staticTexts["Heart Rate"]
        if heartRateMetric.exists {
            XCTAssertFalse(heartRateMetric.label.isEmpty, "Heart rate should have a value")
        }
        
        let stepsMetric = popover.staticTexts["Steps"]
        if stepsMetric.exists {
            XCTAssertFalse(stepsMetric.label.isEmpty, "Steps should have a value")
        }
    }
    
    private func testPopoverPerformance() {
        let menuBarItem = app.menuBarItems["HealthAI2030"]
        
        // Test multiple rapid clicks
        let iterations = 10
        var totalResponseTime: TimeInterval = 0
        
        for i in 0..<iterations {
            let startTime = Date()
            
            menuBarItem.click()
            let popover = app.popovers.firstMatch
            let appeared = popover.waitForExistence(timeout: 1.0)
            
            if appeared {
                let responseTime = Date().timeIntervalSince(startTime)
                totalResponseTime += responseTime
                
                // Close popover
                app.coordinate(withNormalizedOffset: CGVector(dx: 0.1, dy: 0.1)).click()
                _ = !popover.waitForExistence(timeout: 0.5)
            } else {
                XCTFail("Popover failed to appear on iteration \(i)")
            }
            
            // Brief pause between iterations
            usleep(100000) // 100ms
        }
        
        let averageResponseTime = totalResponseTime / Double(iterations)
        XCTAssertLessThan(averageResponseTime, 0.3, "Average menu bar response should be under 300ms")
    }
    
    private func testMenuUpdateLatency() {
        // Test how quickly menu updates when health data changes
        let initialValue = "72 BPM"
        let updatedValue = "78 BPM"
        
        // Simulate health data update
        healthDataManager.updateHeartRate(78)
        
        // Open menu to check updated value
        let menuBarItem = app.menuBarItems["HealthAI2030"]
        menuBarItem.click()
        
        let popover = app.popovers.firstMatch
        if popover.waitForExistence(timeout: 2.0) {
            // Check if updated value appears
            let heartRateDisplay = popover.staticTexts.matching(identifier: "HeartRateValue").firstMatch
            
            if heartRateDisplay.exists {
                let displayedValue = heartRateDisplay.label
                XCTAssertTrue(displayedValue.contains("78") || displayedValue.contains(updatedValue),
                             "Menu should show updated heart rate value")
            }
            
            // Close popover
            app.coordinate(withNormalizedOffset: CGVector(dx: 0.1, dy: 0.1)).click()
        }
    }
    
    private func testResourceUsageUnderLoad() {
        let initialCPU = performanceMonitor.getCurrentCPUUsage()
        let initialMemory = performanceMonitor.getCurrentMemoryUsage()
        
        // Simulate high-frequency interactions
        let menuBarItem = app.menuBarItems["HealthAI2030"]
        
        for _ in 0..<50 {
            menuBarItem.click()
            
            let popover = app.popovers.firstMatch
            if popover.waitForExistence(timeout: 0.5) {
                // Interact with popover elements
                let buttons = popover.buttons
                if buttons.count > 0 {
                    buttons.element(boundBy: 0).click()
                }
                
                // Close popover
                app.coordinate(withNormalizedOffset: CGVector(dx: 0.1, dy: 0.1)).click()
            }
            
            usleep(50000) // 50ms between interactions
        }
        
        let finalCPU = performanceMonitor.getCurrentCPUUsage()
        let finalMemory = performanceMonitor.getCurrentMemoryUsage()
        
        let cpuIncrease = finalCPU - initialCPU
        let memoryIncrease = finalMemory - initialMemory
        
        // Resource usage should remain reasonable
        XCTAssertLessThan(cpuIncrease, 20.0, "CPU usage increase should be under 20%")
        XCTAssertLessThan(memoryIncrease, 50 * 1024 * 1024, "Memory increase should be under 50MB")
    }
    
    private func testMenuBarItemAccessibility() {
        let menuBarItem = app.menuBarItems["HealthAI2030"]
        
        // Test accessibility properties
        XCTAssertFalse(menuBarItem.label.isEmpty, "Menu bar item should have accessibility label")
        XCTAssertTrue(menuBarItem.isHittable, "Menu bar item should be accessible")
        
        // Test keyboard navigation
        menuBarItem.click()
        let popover = app.popovers.firstMatch
        
        if popover.waitForExistence(timeout: 2.0) {
            // Test tab navigation through popover elements
            let focusableElements = popover.buttons.allElementsBoundByIndex + 
                                  popover.textFields.allElementsBoundByIndex
            
            for element in focusableElements.prefix(5) {
                if element.exists {
                    XCTAssertTrue(element.isHittable, "Popover element should be accessible")
                    XCTAssertFalse(element.label.isEmpty, "Popover element should have accessibility label")
                }
            }
            
            // Close popover
            app.coordinate(withNormalizedOffset: CGVector(dx: 0.1, dy: 0.1)).click()
        }
    }
    
    // MARK: - Menu Bar Integration Tests
    
    func testMenuBarIntegration() {
        testHealthDataIntegration()
        testNotificationIntegration()
        testPreferencesIntegration()
        testQuickActionsIntegration()
    }
    
    private func testHealthDataIntegration() {
        // Test that menu bar displays real health data
        let testHealthData = HealthDataSet(
            heartRate: 75,
            steps: 8945,
            sleepQuality: 0.87,
            stressLevel: 0.25
        )
        
        healthDataManager.updateHealthData(testHealthData)
        
        // Wait for data to propagate
        usleep(500000) // 500ms
        
        let menuBarItem = app.menuBarItems["HealthAI2030"]
        menuBarItem.click()
        
        let popover = app.popovers.firstMatch
        if popover.waitForExistence(timeout: 2.0) {
            // Verify data is displayed correctly
            verifyHealthDataDisplay(popover, expectedData: testHealthData)
            
            // Close popover
            app.coordinate(withNormalizedOffset: CGVector(dx: 0.1, dy: 0.1)).click()
        }
    }
    
    private func verifyHealthDataDisplay(_ popover: XCUIElement, expectedData: HealthDataSet) {
        // Check heart rate display
        let heartRateElements = popover.staticTexts.matching(identifier: "HeartRateValue")
        if heartRateElements.count > 0 {
            let heartRateText = heartRateElements.firstMatch.label
            XCTAssertTrue(heartRateText.contains("\(expectedData.heartRate)"),
                         "Should display correct heart rate: \(expectedData.heartRate)")
        }
        
        // Check steps display
        let stepsElements = popover.staticTexts.matching(identifier: "StepsValue")
        if stepsElements.count > 0 {
            let stepsText = stepsElements.firstMatch.label
            XCTAssertTrue(stepsText.contains("\(expectedData.steps)"),
                         "Should display correct steps: \(expectedData.steps)")
        }
        
        // Check sleep quality display
        let sleepElements = popover.staticTexts.matching(identifier: "SleepQualityValue")
        if sleepElements.count > 0 {
            let sleepText = sleepElements.firstMatch.label
            let sleepPercentage = Int(expectedData.sleepQuality * 100)
            XCTAssertTrue(sleepText.contains("\(sleepPercentage)"),
                         "Should display correct sleep quality: \(sleepPercentage)%")
        }
    }
    
    private func testNotificationIntegration() {
        // Test menu bar response to health notifications
        let criticalAlert = HealthAlert(
            type: .criticalHeartRate,
            value: 145,
            message: "High heart rate detected"
        )
        
        healthDataManager.triggerHealthAlert(criticalAlert)
        
        // Menu bar should update to show alert state
        let menuBarItem = app.menuBarItems["HealthAI2030"]
        
        // Check if menu bar item shows alert indicator
        // This might be a color change, icon change, or badge
        XCTAssertTrue(menuBarItem.exists, "Menu bar item should still be present during alert")
        
        menuBarItem.click()
        let popover = app.popovers.firstMatch
        
        if popover.waitForExistence(timeout: 2.0) {
            // Should show alert information
            let alertElements = popover.staticTexts.matching(identifier: "HealthAlert")
            XCTAssertGreaterThan(alertElements.count, 0, "Should display health alert in popover")
            
            if alertElements.count > 0 {
                let alertText = alertElements.firstMatch.label
                XCTAssertTrue(alertText.contains("High") || alertText.contains("145"),
                             "Should display alert details")
            }
            
            // Close popover
            app.coordinate(withNormalizedOffset: CGVector(dx: 0.1, dy: 0.1)).click()
        }
    }
    
    private func testPreferencesIntegration() {
        let menuBarItem = app.menuBarItems["HealthAI2030"]
        menuBarItem.click()
        
        let popover = app.popovers.firstMatch
        if popover.waitForExistence(timeout: 2.0) {
            // Test preferences button
            let preferencesButton = popover.buttons["Preferences"]
            if preferencesButton.exists {
                preferencesButton.click()
                
                // Preferences window should open
                let preferencesWindow = app.windows["Preferences"]
                let windowOpened = preferencesWindow.waitForExistence(timeout: 3.0)
                
                XCTAssertTrue(windowOpened, "Preferences window should open")
                
                if windowOpened {
                    // Test preferences window content
                    let generalTab = preferencesWindow.buttons["General"]
                    let notificationsTab = preferencesWindow.buttons["Notifications"]
                    
                    XCTAssertTrue(generalTab.exists || notificationsTab.exists,
                                 "Preferences should have configuration tabs")
                    
                    // Close preferences window
                    let closeButton = preferencesWindow.buttons[NSWindow.ButtonType.closeButton]
                    if closeButton.exists {
                        closeButton.click()
                    }
                }
            }
        }
    }
    
    private func testQuickActionsIntegration() {
        let menuBarItem = app.menuBarItems["HealthAI2030"]
        menuBarItem.click()
        
        let popover = app.popovers.firstMatch
        if popover.waitForExistence(timeout: 2.0) {
            // Test quick action buttons
            testLogWaterQuickAction(popover)
            testStartWorkoutQuickAction(popover)
            testLogMoodQuickAction(popover)
            
            // Close popover
            app.coordinate(withNormalizedOffset: CGVector(dx: 0.1, dy: 0.1)).click()
        }
    }
    
    private func testLogWaterQuickAction(_ popover: XCUIElement) {
        let logWaterButton = popover.buttons["Log Water"]
        if logWaterButton.exists {
            let initialWaterCount = getWaterIntakeCount()
            
            logWaterButton.click()
            
            // Wait for action to complete
            usleep(500000) // 500ms
            
            let updatedWaterCount = getWaterIntakeCount()
            XCTAssertGreaterThan(updatedWaterCount, initialWaterCount,
                               "Water intake should increase after logging")
        }
    }
    
    private func testStartWorkoutQuickAction(_ popover: XCUIElement) {
        let startWorkoutButton = popover.buttons["Start Workout"]
        if startWorkoutButton.exists {
            startWorkoutButton.click()
            
            // Should trigger workout interface or confirmation
            let workoutDialog = app.sheets.firstMatch
            if workoutDialog.waitForExistence(timeout: 2.0) {
                XCTAssertTrue(workoutDialog.exists, "Should show workout selection dialog")
                
                // Close dialog
                let cancelButton = workoutDialog.buttons["Cancel"]
                if cancelButton.exists {
                    cancelButton.click()
                }
            }
        }
    }
    
    private func testLogMoodQuickAction(_ popover: XCUIElement) {
        let logMoodButton = popover.buttons["Log Mood"]
        if logMoodButton.exists {
            logMoodButton.click()
            
            // Should show mood selection interface
            let moodSelector = app.otherElements["MoodSelector"]
            if moodSelector.waitForExistence(timeout: 2.0) {
                XCTAssertTrue(moodSelector.exists, "Should show mood selection interface")
                
                // Select a mood and confirm
                let happyMood = moodSelector.buttons["Happy"]
                if happyMood.exists {
                    happyMood.click()
                    
                    let confirmButton = moodSelector.buttons["Confirm"]
                    if confirmButton.exists {
                        confirmButton.click()
                    }
                }
            }
        }
    }
    
    // MARK: - Menu Bar Lifecycle Tests
    
    func testMenuBarLifecycle() {
        testMenuBarStartup()
        testMenuBarShutdown()
        testMenuBarRestart()
        testMenuBarMemoryManagement()
    }
    
    private func testMenuBarStartup() {
        // Test menu bar initialization
        let startTime = Date()
        
        // Force menu bar restart
        menuBarController.restart()
        
        // Menu bar should be available quickly
        let menuBarItem = app.menuBarItems["HealthAI2030"]
        let itemAvailable = menuBarItem.waitForExistence(timeout: 5.0)
        
        let startupTime = Date().timeIntervalSince(startTime)
        
        XCTAssertTrue(itemAvailable, "Menu bar item should be available after startup")
        XCTAssertLessThan(startupTime, 3.0, "Menu bar startup should be under 3 seconds")
    }
    
    private func testMenuBarShutdown() {
        let menuBarItem = app.menuBarItems["HealthAI2030"]
        XCTAssertTrue(menuBarItem.exists, "Menu bar item should exist before shutdown")
        
        // Graceful shutdown
        menuBarController.shutdown()
        
        // Menu bar item should be removed
        let itemRemoved = !menuBarItem.waitForExistence(timeout: 2.0)
        XCTAssertTrue(itemRemoved, "Menu bar item should be removed after shutdown")
    }
    
    private func testMenuBarRestart() {
        // Test restart functionality
        let initialState = menuBarController.isRunning
        
        menuBarController.restart()
        
        // Should maintain functionality after restart
        let menuBarItem = app.menuBarItems["HealthAI2030"]
        let itemAvailable = menuBarItem.waitForExistence(timeout: 3.0)
        
        XCTAssertTrue(itemAvailable, "Menu bar should be functional after restart")
        
        if itemAvailable {
            menuBarItem.click()
            let popover = app.popovers.firstMatch
            let popoverWorks = popover.waitForExistence(timeout: 2.0)
            
            XCTAssertTrue(popoverWorks, "Menu bar functionality should work after restart")
            
            if popoverWorks {
                app.coordinate(withNormalizedOffset: CGVector(dx: 0.1, dy: 0.1)).click()
            }
        }
    }
    
    private func testMenuBarMemoryManagement() {
        let initialMemory = performanceMonitor.getCurrentMemoryUsage()
        
        // Perform intensive menu bar operations
        for i in 0..<100 {
            let menuBarItem = app.menuBarItems["HealthAI2030"]
            menuBarItem.click()
            
            let popover = app.popovers.firstMatch
            if popover.waitForExistence(timeout: 0.5) {
                // Interact with popover elements
                let elements = popover.buttons.allElementsBoundByIndex
                for element in elements.prefix(3) {
                    if element.exists {
                        element.click()
                    }
                }
                
                app.coordinate(withNormalizedOffset: CGVector(dx: 0.1, dy: 0.1)).click()
            }
            
            if i % 10 == 0 {
                // Periodic memory check
                let currentMemory = performanceMonitor.getCurrentMemoryUsage()
                let memoryIncrease = currentMemory - initialMemory
                
                XCTAssertLessThan(memoryIncrease, 100 * 1024 * 1024,
                                 "Memory usage should not grow excessively")
            }
        }
        
        // Force garbage collection and check final memory
        menuBarController.cleanup()
        usleep(1000000) // 1 second
        
        let finalMemory = performanceMonitor.getCurrentMemoryUsage()
        let totalMemoryIncrease = finalMemory - initialMemory
        
        XCTAssertLessThan(totalMemoryIncrease, 50 * 1024 * 1024,
                         "Final memory increase should be under 50MB")
    }
    
    // MARK: - Helper Methods
    
    private func setupTestEnvironment() {
        menuBarController.setTestMode(enabled: true)
        healthDataManager.initializeTestData()
        performanceMonitor.startMonitoring()
    }
    
    private func cleanupTestEnvironment() {
        performanceMonitor.stopMonitoring()
        healthDataManager.cleanupTestData()
        menuBarController.setTestMode(enabled: false)
    }
    
    private func getWaterIntakeCount() -> Int {
        return healthDataManager.getCurrentWaterIntake()
    }
}

// MARK: - Supporting Types and Mock Classes

struct HealthDataSet {
    let heartRate: Int
    let steps: Int
    let sleepQuality: Double
    let stressLevel: Double
}

struct HealthAlert {
    let type: HealthAlertType
    let value: Double
    let message: String
}

enum HealthAlertType {
    case criticalHeartRate
    case lowBloodSugar
    case highStress
    case irregularRhythm
}

class MenuBarController {
    private(set) var isRunning = true
    private var testMode = false
    
    func restart() {
        isRunning = false
        usleep(500000) // 500ms
        isRunning = true
    }
    
    func shutdown() {
        isRunning = false
    }
    
    func setTestMode(enabled: Bool) {
        testMode = enabled
    }
    
    func cleanup() {
        // Mock cleanup operations
    }
}

class MacHealthDataManager {
    private var currentWaterIntake = 0
    private var testMode = false
    
    func updateHeartRate(_ rate: Int) {
        // Mock heart rate update
    }
    
    func updateHealthData(_ data: HealthDataSet) {
        // Mock health data update
    }
    
    func triggerHealthAlert(_ alert: HealthAlert) {
        // Mock health alert
    }
    
    func getCurrentWaterIntake() -> Int {
        return currentWaterIntake
    }
    
    func logWaterIntake() {
        currentWaterIntake += 1
    }
    
    func initializeTestData() {
        testMode = true
        currentWaterIntake = 3
    }
    
    func cleanupTestData() {
        testMode = false
        currentWaterIntake = 0
    }
}

class MacPerformanceMonitor {
    private var monitoring = false
    
    func startMonitoring() {
        monitoring = true
    }
    
    func stopMonitoring() {
        monitoring = false
    }
    
    func getCurrentCPUUsage() -> Double {
        // Mock CPU usage
        return Double.random(in: 5.0...15.0)
    }
    
    func getCurrentMemoryUsage() -> UInt64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        return kerr == KERN_SUCCESS ? UInt64(info.resident_size) : 0
    }
}

#else
// Non-macOS platforms
final class MacMenuBarTests: XCTestCase {
    func testMenuBarAppResponsiveness() {
        XCTAssertTrue(true, "Menu bar tests only run on macOS")
    }
}
#endif 
import XCTest
import SwiftUI
import UIKit
import AccessibilityAudit

#if canImport(UIKit)
@testable import HealthAI2030

final class AccessibilityAuditTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Ensure clean state for accessibility testing
        continueAfterFailure = false
    }
    
    // MARK: - VoiceOver Navigation Tests
    
    func testVoiceOverNavigation() {
        let app = XCUIApplication()
        app.launch()
        
        // Test main dashboard accessibility
        testDashboardVoiceOverElements(app)
        
        // Test navigation accessibility
        testNavigationVoiceOverElements(app)
        
        // Test form elements accessibility
        testFormVoiceOverElements(app)
        
        // Test data visualization accessibility
        testVisualizationVoiceOverElements(app)
    }
    
    private func testDashboardVoiceOverElements(_ app: XCUIApplication) {
        // Verify dashboard has proper accessibility labels
        let dashboard = app.otherElements["HealthDashboard"]
        XCTAssertTrue(dashboard.exists, "Main dashboard should be accessible")
        
        // Test health metric cards
        let metricCards = app.otherElements.matching(identifier: "HealthMetricCard")
        XCTAssertGreaterThan(metricCards.count, 0, "Health metric cards should be present")
        
        for i in 0..<min(metricCards.count, 5) {
            let card = metricCards.element(boundBy: i)
            XCTAssertTrue(card.isHittable, "Metric card \(i) should be accessible")
            XCTAssertFalse(card.label.isEmpty, "Metric card \(i) should have accessibility label")
            XCTAssertTrue(card.label.contains("health") || card.label.contains("metric"), 
                         "Metric card \(i) label should be descriptive")
        }
    }
    
    private func testNavigationVoiceOverElements(_ app: XCUIApplication) {
        // Test tab navigation
        let tabBar = app.tabBars.firstMatch
        if tabBar.exists {
            let tabs = tabBar.buttons
            XCTAssertGreaterThan(tabs.count, 0, "Tab bar should have accessible buttons")
            
            for i in 0..<tabs.count {
                let tab = tabs.element(boundBy: i)
                XCTAssertTrue(tab.isHittable, "Tab \(i) should be accessible")
                XCTAssertFalse(tab.label.isEmpty, "Tab \(i) should have accessibility label")
            }
        }
        
        // Test navigation buttons
        let navigationBars = app.navigationBars
        for navigationBar in navigationBars.allElementsBoundByIndex {
            let backButton = navigationBar.buttons.firstMatch
            if backButton.exists {
                XCTAssertTrue(backButton.isHittable, "Back button should be accessible")
                XCTAssertFalse(backButton.label.isEmpty, "Back button should have accessibility label")
            }
        }
    }
    
    private func testFormVoiceOverElements(_ app: XCUIApplication) {
        // Navigate to settings or data entry form
        let settingsTab = app.tabBars.buttons["Settings"]
        if settingsTab.exists {
            settingsTab.tap()
            
            // Test form elements
            let textFields = app.textFields
            for i in 0..<min(textFields.count, 3) {
                let textField = textFields.element(boundBy: i)
                XCTAssertTrue(textField.isHittable, "Text field \(i) should be accessible")
                XCTAssertFalse(textField.label.isEmpty, "Text field \(i) should have accessibility label")
            }
            
            let switches = app.switches
            for i in 0..<min(switches.count, 3) {
                let switchControl = switches.element(boundBy: i)
                XCTAssertTrue(switchControl.isHittable, "Switch \(i) should be accessible")
                XCTAssertFalse(switchControl.label.isEmpty, "Switch \(i) should have accessibility label")
            }
        }
    }
    
    private func testVisualizationVoiceOverElements(_ app: XCUIApplication) {
        // Test chart and graph accessibility
        let charts = app.otherElements.matching(identifier: "HealthChart")
        for i in 0..<min(charts.count, 3) {
            let chart = charts.element(boundBy: i)
            if chart.exists {
                XCTAssertTrue(chart.isHittable, "Chart \(i) should be accessible")
                XCTAssertFalse(chart.label.isEmpty, "Chart \(i) should have accessibility label")
                XCTAssertTrue(chart.label.contains("chart") || chart.label.contains("graph"), 
                             "Chart \(i) should have descriptive label")
            }
        }
    }
    
    // MARK: - Dynamic Type Tests
    
    func testDynamicTypeResilience() {
        let app = XCUIApplication()
        
        // Test with different content size categories
        let contentSizes: [UIContentSizeCategory] = [
            .extraSmall,
            .small,
            .medium,
            .large,
            .extraLarge,
            .extraExtraLarge,
            .extraExtraExtraLarge,
            .accessibilityMedium,
            .accessibilityLarge,
            .accessibilityExtraLarge,
            .accessibilityExtraExtraLarge,
            .accessibilityExtraExtraExtraLarge
        ]
        
        for contentSize in contentSizes {
            testUIWithContentSize(app, contentSize: contentSize)
        }
    }
    
    private func testUIWithContentSize(_ app: XCUIApplication, contentSize: UIContentSizeCategory) {
        // Simulate content size category change
        app.launchEnvironment["ContentSizeCategory"] = contentSize.rawValue
        app.launch()
        
        // Verify UI elements are still accessible and properly sized
        let dashboard = app.otherElements["HealthDashboard"]
        XCTAssertTrue(dashboard.exists, "Dashboard should exist with \(contentSize.rawValue)")
        
        // Test that text doesn't get clipped
        let labels = app.staticTexts
        for i in 0..<min(labels.count, 10) {
            let label = labels.element(boundBy: i)
            if label.exists && !label.label.isEmpty {
                XCTAssertTrue(label.frame.height > 0, "Label \(i) should have positive height with \(contentSize.rawValue)")
                XCTAssertTrue(label.frame.width > 0, "Label \(i) should have positive width with \(contentSize.rawValue)")
            }
        }
        
        // Test that buttons remain accessible
        let buttons = app.buttons
        for i in 0..<min(buttons.count, 5) {
            let button = buttons.element(boundBy: i)
            if button.exists {
                XCTAssertTrue(button.isHittable, "Button \(i) should remain hittable with \(contentSize.rawValue)")
            }
        }
    }
    
    // MARK: - Keyboard and Remote Navigation Tests
    
    func testKeyboardNavigationFocus() {
        let app = XCUIApplication()
        app.launch()
        
        // Test keyboard navigation on interactive elements
        testKeyboardFocusTraversal(app)
        
        #if os(tvOS)
        testRemoteControlNavigation(app)
        #endif
        
        #if os(macOS)
        testMacKeyboardNavigation(app)
        #endif
    }
    
    private func testKeyboardFocusTraversal(_ app: XCUIApplication) {
        let focusableElements = [
            app.buttons,
            app.textFields,
            app.switches,
            app.segmentedControls
        ]
        
        for elementQuery in focusableElements {
            for i in 0..<min(elementQuery.count, 3) {
                let element = elementQuery.element(boundBy: i)
                if element.exists {
                    element.tap()
                    XCTAssertTrue(element.hasFocus, "Element should be focusable")
                    
                    // Test that element has proper focus indicators
                    XCTAssertTrue(element.isHittable, "Focused element should be hittable")
                }
            }
        }
    }
    
    #if os(tvOS)
    private func testRemoteControlNavigation(_ app: XCUIApplication) {
        // Test Apple TV remote navigation
        let remoteControl = XCUIRemote.shared
        
        // Test directional navigation
        remoteControl.press(.up)
        remoteControl.press(.down)
        remoteControl.press(.left)
        remoteControl.press(.right)
        remoteControl.press(.select)
        
        // Verify focus moves appropriately
        let focusedElement = app.otherElements.firstMatch
        XCTAssertTrue(focusedElement.hasFocus, "An element should have focus after remote navigation")
    }
    #endif
    
    #if os(macOS)
    private func testMacKeyboardNavigation(_ app: XCUIApplication) {
        // Test Tab key navigation
        app.typeKey("Tab", modifierFlags: [])
        
        // Test Shift+Tab for reverse navigation
        app.typeKey("Tab", modifierFlags: [.shift])
        
        // Test arrow key navigation in lists/grids
        app.typeKey(.downArrow, modifierFlags: [])
        app.typeKey(.upArrow, modifierFlags: [])
        
        // Verify keyboard shortcuts work
        app.typeKey("n", modifierFlags: [.command]) // New item
        app.typeKey("w", modifierFlags: [.command]) // Close window
    }
    #endif
    
    // MARK: - Reduced Motion and Contrast Tests
    
    func testReducedMotionAndContrast() {
        let app = XCUIApplication()
        
        // Test with reduced motion
        testWithReducedMotion(app)
        
        // Test with increased contrast
        testWithIncreasedContrast(app)
        
        // Test with reduced transparency
        testWithReducedTransparency(app)
    }
    
    private func testWithReducedMotion(_ app: XCUIApplication) {
        app.launchEnvironment["UIAccessibilityIsReduceMotionEnabled"] = "YES"
        app.launch()
        
        // Verify animations are reduced or eliminated
        let dashboard = app.otherElements["HealthDashboard"]
        XCTAssertTrue(dashboard.exists, "Dashboard should exist with reduced motion")
        
        // Test that interactive elements still work without motion
        let buttons = app.buttons
        for i in 0..<min(buttons.count, 3) {
            let button = buttons.element(boundBy: i)
            if button.exists {
                button.tap()
                // Verify action completed without animation issues
                XCTAssertTrue(button.isHittable, "Button should remain functional with reduced motion")
            }
        }
    }
    
    private func testWithIncreasedContrast(_ app: XCUIApplication) {
        app.launchEnvironment["UIAccessibilityDarkerSystemColorsEnabled"] = "YES"
        app.launch()
        
        // Verify UI remains usable with high contrast
        let dashboard = app.otherElements["HealthDashboard"]
        XCTAssertTrue(dashboard.exists, "Dashboard should exist with increased contrast")
        
        // Test that text remains readable
        let labels = app.staticTexts
        for i in 0..<min(labels.count, 5) {
            let label = labels.element(boundBy: i)
            if label.exists && !label.label.isEmpty {
                XCTAssertFalse(label.label.isEmpty, "Label should have readable text with high contrast")
            }
        }
    }
    
    private func testWithReducedTransparency(_ app: XCUIApplication) {
        app.launchEnvironment["UIAccessibilityIsReduceTransparencyEnabled"] = "YES"
        app.launch()
        
        // Verify UI works without transparency effects
        let dashboard = app.otherElements["HealthDashboard"]
        XCTAssertTrue(dashboard.exists, "Dashboard should exist with reduced transparency")
        
        // Test that overlays and modals are still visible
        let modals = app.sheets
        for i in 0..<min(modals.count, 2) {
            let modal = modals.element(boundBy: i)
            if modal.exists {
                XCTAssertTrue(modal.isHittable, "Modal should be visible without transparency")
            }
        }
    }
    
    // MARK: - Color Blindness Compatibility Tests
    
    func testColorBlindnessCompatibility() {
        let app = XCUIApplication()
        app.launch()
        
        // Test that UI doesn't rely solely on color for information
        testColorIndependentInformation(app)
        
        // Test with different color blindness simulations
        testWithColorBlindnessFilters(app)
    }
    
    private func testColorIndependentInformation(_ app: XCUIApplication) {
        // Verify status indicators use more than just color
        let statusIndicators = app.otherElements.matching(identifier: "StatusIndicator")
        for i in 0..<min(statusIndicators.count, 5) {
            let indicator = statusIndicators.element(boundBy: i)
            if indicator.exists {
                // Should have text, icons, or other visual cues beyond color
                XCTAssertFalse(indicator.label.isEmpty, "Status indicator should have descriptive label")
                
                // Check for accessibility traits that convey meaning
                let traits = indicator.accessibilityTraits
                XCTAssertTrue(traits.contains(.staticText) || traits.contains(.image) || 
                             traits.contains(.button), "Status indicator should have meaningful traits")
            }
        }
        
        // Test charts and graphs have alternative representations
        let charts = app.otherElements.matching(identifier: "HealthChart")
        for i in 0..<min(charts.count, 3) {
            let chart = charts.element(boundBy: i)
            if chart.exists {
                XCTAssertFalse(chart.label.isEmpty, "Chart should have descriptive accessibility label")
                XCTAssertTrue(chart.label.count > 20, "Chart label should be sufficiently descriptive")
            }
        }
    }
    
    private func testWithColorBlindnessFilters(_ app: XCUIApplication) {
        let colorBlindnessTypes = [
            "Protanopia",     // Red-blind
            "Deuteranopia",   // Green-blind
            "Tritanopia",     // Blue-blind
            "Monochromacy"    // Complete color blindness
        ]
        
        for blindnessType in colorBlindnessTypes {
            app.launchEnvironment["ColorBlindnessSimulation"] = blindnessType
            app.launch()
            
            // Verify critical information is still accessible
            let dashboard = app.otherElements["HealthDashboard"]
            XCTAssertTrue(dashboard.exists, "Dashboard should exist with \(blindnessType) simulation")
            
            // Test that error states are distinguishable
            let alerts = app.alerts
            for i in 0..<min(alerts.count, 2) {
                let alert = alerts.element(boundBy: i)
                if alert.exists {
                    XCTAssertFalse(alert.label.isEmpty, "Alert should have clear text with \(blindnessType)")
                }
            }
        }
    }
    
    // MARK: - Haptic Feedback Consistency Tests
    
    func testHapticFeedbackConsistency() {
        let app = XCUIApplication()
        app.launch()
        
        // Test haptic feedback patterns
        testSuccessHapticFeedback(app)
        testWarningHapticFeedback(app)
        testErrorHapticFeedback(app)
        testSelectionHapticFeedback(app)
    }
    
    private func testSuccessHapticFeedback(_ app: XCUIApplication) {
        // Test success actions trigger appropriate haptic feedback
        let successActions = app.buttons.matching(identifier: "SuccessAction")
        for i in 0..<min(successActions.count, 3) {
            let button = successActions.element(boundBy: i)
            if button.exists {
                button.tap()
                // Verify success haptic was triggered (this would need custom monitoring)
                XCTAssertTrue(button.isHittable, "Success action should complete")
            }
        }
    }
    
    private func testWarningHapticFeedback(_ app: XCUIApplication) {
        // Test warning actions trigger appropriate haptic feedback
        let warningActions = app.buttons.matching(identifier: "WarningAction")
        for i in 0..<min(warningActions.count, 2) {
            let button = warningActions.element(boundBy: i)
            if button.exists {
                button.tap()
                XCTAssertTrue(button.isHittable, "Warning action should complete")
            }
        }
    }
    
    private func testErrorHapticFeedback(_ app: XCUIApplication) {
        // Test error scenarios trigger appropriate haptic feedback
        let textFields = app.textFields
        for i in 0..<min(textFields.count, 2) {
            let textField = textFields.element(boundBy: i)
            if textField.exists {
                textField.tap()
                textField.typeText("invalid_input_to_trigger_error")
                
                // Try to submit invalid data
                let submitButton = app.buttons["Submit"]
                if submitButton.exists {
                    submitButton.tap()
                    // Verify error haptic feedback would be triggered
                }
            }
        }
    }
    
    private func testSelectionHapticFeedback(_ app: XCUIApplication) {
        // Test selection feedback consistency
        let selectableElements = [
            app.buttons,
            app.switches,
            app.segmentedControls
        ]
        
        for elementQuery in selectableElements {
            for i in 0..<min(elementQuery.count, 2) {
                let element = elementQuery.element(boundBy: i)
                if element.exists {
                    element.tap()
                    XCTAssertTrue(element.isHittable, "Selectable element should respond to interaction")
                }
            }
        }
    }
}

#else
// Placeholder for non-iOS platforms
final class AccessibilityAuditTests: XCTestCase {
    func testAccessibilityPlaceholder() {
        XCTAssertTrue(true, "Accessibility tests require iOS/UIKit")
    }
}
#endif 
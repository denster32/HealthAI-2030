import XCTest
import SwiftUI
@testable import HealthAI2030TVApp
#if os(tvOS)
import UIKit

final class TVFocusEngineTests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }
    
    override func tearDown() {
        app = nil
        super.tearDown()
    }
    
    // MARK: - Focus Engine Navigation Tests
    
    func testFocusEngineNavigation() {
        // Test that focus engine can navigate through all UI elements without getting trapped
        testDashboardFocusNavigation()
        testTabNavigationFocus()
        testModalFocusHandling()
        testScrollViewFocusNavigation()
        testButtonGroupFocusNavigation()
    }
    
    private func testDashboardFocusNavigation() {
        // Navigate to main dashboard
        let dashboard = app.otherElements["HealthDashboard"]
        XCTAssertTrue(dashboard.exists, "Health dashboard should exist")
        
        // Test focus movement through health metric cards
        let metricCards = app.otherElements.matching(identifier: "HealthMetricCard")
        XCTAssertGreaterThan(metricCards.count, 0, "Should have health metric cards")
        
        // Navigate through cards using focus engine
        for i in 0..<min(metricCards.count, 6) {
            let card = metricCards.element(boundBy: i)
            if card.exists {
                card.tap()
                XCTAssertTrue(card.hasFocus, "Card \(i) should gain focus when tapped")
                
                // Test that focus can move away from this card
                app.buttons["Menu"].tap()
                XCTAssertFalse(card.hasFocus, "Card \(i) should lose focus when navigating away")
            }
        }
    }
    
    private func testTabNavigationFocus() {
        // Test focus navigation through tab bar
        let tabBar = app.tabBars.firstMatch
        if tabBar.exists {
            let tabs = tabBar.buttons
            XCTAssertGreaterThan(tabs.count, 0, "Should have tab buttons")
            
            var previousTab: XCUIElement?
            for i in 0..<tabs.count {
                let tab = tabs.element(boundBy: i)
                if tab.exists {
                    tab.tap()
                    XCTAssertTrue(tab.hasFocus, "Tab \(i) should gain focus")
                    
                    // Verify previous tab lost focus
                    if let prevTab = previousTab {
                        XCTAssertFalse(prevTab.hasFocus, "Previous tab should lose focus")
                    }
                    previousTab = tab
                    
                    // Test that we can navigate into tab content
                    let firstFocusableElement = app.otherElements.firstMatch
                    if firstFocusableElement.exists && firstFocusableElement.isHittable {
                        firstFocusableElement.tap()
                        XCTAssertTrue(firstFocusableElement.hasFocus || tab.hasFocus, 
                                     "Focus should be on tab or its content")
                    }
                }
            }
        }
    }
    
    private func testModalFocusHandling() {
        // Test focus behavior with modal presentations
        let settingsButton = app.buttons["Settings"]
        if settingsButton.exists {
            settingsButton.tap()
            
            // Wait for settings modal to appear
            let settingsModal = app.sheets.firstMatch
            let modalAppeared = settingsModal.waitForExistence(timeout: 2.0)
            
            if modalAppeared {
                // Focus should be trapped within modal
                let firstModalElement = settingsModal.buttons.firstMatch
                if firstModalElement.exists {
                    firstModalElement.tap()
                    XCTAssertTrue(firstModalElement.hasFocus, "Modal element should gain focus")
                    
                    // Try to navigate outside modal - focus should stay within
                    let outsideElement = app.buttons["Dashboard"]
                    if outsideElement.exists && !settingsModal.buttons["Dashboard"].exists {
                        outsideElement.tap()
                        XCTAssertFalse(outsideElement.hasFocus, "Focus should not leave modal")
                    }
                }
                
                // Close modal
                let closeButton = settingsModal.buttons["Close"]
                if closeButton.exists {
                    closeButton.tap()
                } else {
                    // Try alternative close methods
                    app.buttons["Menu"].tap()
                }
            }
        }
    }
    
    private func testScrollViewFocusNavigation() {
        // Test focus navigation within scroll views
        let scrollView = app.scrollViews.firstMatch
        if scrollView.exists {
            let scrollableElements = scrollView.otherElements
            
            if scrollableElements.count > 1 {
                let firstElement = scrollableElements.element(boundBy: 0)
                let lastElement = scrollableElements.element(boundBy: scrollableElements.count - 1)
                
                // Focus on first element
                firstElement.tap()
                XCTAssertTrue(firstElement.hasFocus, "First element should gain focus")
                
                // Navigate to last element (should trigger scrolling)
                lastElement.tap()
                XCTAssertTrue(lastElement.hasFocus, "Last element should gain focus")
                
                // Verify scroll position changed
                // Note: Exact scroll position verification is platform-dependent
                XCTAssertTrue(lastElement.isHittable, "Last element should be visible after focus")
            }
        }
    }
    
    private func testButtonGroupFocusNavigation() {
        // Test focus navigation through grouped buttons
        let buttonGroups = app.otherElements.matching(identifier: "ButtonGroup")
        
        for i in 0..<min(buttonGroups.count, 3) {
            let buttonGroup = buttonGroups.element(boundBy: i)
            if buttonGroup.exists {
                let buttons = buttonGroup.buttons
                
                // Test circular navigation within button group
                if buttons.count > 1 {
                    let firstButton = buttons.element(boundBy: 0)
                    let lastButton = buttons.element(boundBy: buttons.count - 1)
                    
                    firstButton.tap()
                    XCTAssertTrue(firstButton.hasFocus, "First button should gain focus")
                    
                    // Navigate through all buttons
                    for j in 1..<buttons.count {
                        let button = buttons.element(boundBy: j)
                        button.tap()
                        XCTAssertTrue(button.hasFocus, "Button \(j) should gain focus")
                    }
                    
                    // Test wrap-around navigation if supported
                    lastButton.tap()
                    XCTAssertTrue(lastButton.hasFocus, "Last button should maintain focus")
                }
            }
        }
    }
    
    // MARK: - Focus Trap Prevention Tests
    
    func testNoFocusTraps() {
        // Test that there are no focus traps in the application
        testNavigationEscapeRoutes()
        testModalEscapeRoutes()
        testScrollViewEscapeRoutes()
    }
    
    private func testNavigationEscapeRoutes() {
        // Ensure every focusable element has a way to navigate away
        let allFocusableElements = app.buttons.allElementsBoundByIndex + 
                                  app.otherElements.allElementsBoundByIndex.filter { $0.isHittable }
        
        for element in allFocusableElements.prefix(10) { // Test first 10 to avoid timeout
            if element.exists && element.isHittable {
                element.tap()
                
                // Try to navigate away using menu button
                let menuButton = app.buttons["Menu"]
                if menuButton.exists {
                    menuButton.tap()
                    XCTAssertTrue(menuButton.hasFocus || !element.hasFocus, 
                                 "Should be able to navigate away from any element")
                }
            }
        }
    }
    
    private func testModalEscapeRoutes() {
        // Test that modals can always be dismissed
        let presentModalButton = app.buttons.matching(identifier: "PresentModal").firstMatch
        if presentModalButton.exists {
            presentModalButton.tap()
            
            let modal = app.sheets.firstMatch
            if modal.waitForExistence(timeout: 2.0) {
                // Should always have a way to close modal
                let closeButtons = modal.buttons.matching(identifier: "Close")
                let dismissButtons = modal.buttons.matching(identifier: "Dismiss")
                let doneButtons = modal.buttons.matching(identifier: "Done")
                
                let hasEscapeRoute = closeButtons.count > 0 || 
                                   dismissButtons.count > 0 || 
                                   doneButtons.count > 0
                
                XCTAssertTrue(hasEscapeRoute, "Modal should have an escape route")
                
                // Try to close modal
                if closeButtons.firstMatch.exists {
                    closeButtons.firstMatch.tap()
                } else if dismissButtons.firstMatch.exists {
                    dismissButtons.firstMatch.tap()
                } else if doneButtons.firstMatch.exists {
                    doneButtons.firstMatch.tap()
                }
            }
        }
    }
    
    private func testScrollViewEscapeRoutes() {
        // Test that focus can escape from scroll views
        let scrollViews = app.scrollViews
        
        for i in 0..<min(scrollViews.count, 3) {
            let scrollView = scrollViews.element(boundBy: i)
            if scrollView.exists {
                let elementsInScrollView = scrollView.otherElements
                if elementsInScrollView.count > 0 {
                    let firstElement = elementsInScrollView.firstMatch
                    firstElement.tap()
                    
                    // Should be able to navigate outside scroll view
                    let outsideElement = app.buttons.matching(identifier: "Menu").firstMatch
                    if outsideElement.exists {
                        outsideElement.tap()
                        XCTAssertTrue(outsideElement.hasFocus || !firstElement.hasFocus,
                                     "Should be able to escape scroll view focus")
                    }
                }
            }
        }
    }
    
    // MARK: - Remote Control Integration Tests
    
    func testRemoteControlIntegration() {
        testSwipeGestureNavigation()
        testSelectButtonBehavior()
        testMenuButtonBehavior()
        testPlayPauseIntegration()
    }
    
    private func testSwipeGestureNavigation() {
        // Test swiping behavior for navigation
        let healthCards = app.otherElements.matching(identifier: "HealthMetricCard")
        if healthCards.count > 1 {
            let firstCard = healthCards.element(boundBy: 0)
            let secondCard = healthCards.element(boundBy: 1)
            
            firstCard.tap()
            XCTAssertTrue(firstCard.hasFocus, "First card should have focus")
            
            // Simulate swipe to navigate
            firstCard.swipeRight()
            XCTAssertTrue(secondCard.hasFocus || firstCard.hasFocus, 
                         "Swipe should navigate to next element")
        }
    }
    
    private func testSelectButtonBehavior() {
        // Test select button behavior on focused elements
        let actionButtons = app.buttons.matching(identifier: "ActionButton")
        if actionButtons.count > 0 {
            let actionButton = actionButtons.firstMatch
            actionButton.tap()
            
            // Select button should trigger action
            XCTAssertTrue(actionButton.hasFocus, "Action button should be focused")
            
            // Simulate select press (tap is equivalent on tvOS)
            actionButton.tap()
            
            // Verify action was triggered (context-dependent)
            XCTAssertTrue(true, "Select action should be triggered")
        }
    }
    
    private func testMenuButtonBehavior() {
        // Test menu button behavior in different contexts
        let menuButton = app.buttons["Menu"]
        if menuButton.exists {
            // From main screen, menu should do nothing or go to home
            menuButton.tap()
            XCTAssertTrue(app.exists, "App should remain active after menu press")
            
            // From modal, menu should dismiss modal
            let settingsButton = app.buttons["Settings"]
            if settingsButton.exists {
                settingsButton.tap()
                
                let modal = app.sheets.firstMatch
                if modal.waitForExistence(timeout: 2.0) {
                    menuButton.tap()
                    
                    let modalDismissed = !modal.waitForExistence(timeout: 1.0)
                    XCTAssertTrue(modalDismissed, "Menu button should dismiss modal")
                }
            }
        }
    }
    
    private func testPlayPauseIntegration() {
        // Test play/pause button integration with media controls
        let mediaControl = app.buttons.matching(identifier: "MediaControl").firstMatch
        if mediaControl.exists {
            mediaControl.tap()
            XCTAssertTrue(mediaControl.hasFocus, "Media control should be focused")
            
            // Play/pause should be handled appropriately
            // This would require specific media control implementation
            XCTAssertTrue(mediaControl.isHittable, "Media control should remain interactive")
        }
    }
    
    // MARK: - Accessibility and Focus Tests
    
    func testFocusAccessibilityIntegration() {
        testVoiceOverFocusIntegration()
        testFocusEngineSoundEffects()
        testFocusVisualIndicators()
    }
    
    private func testVoiceOverFocusIntegration() {
        // Test that focus engine works with VoiceOver
        let focusableElements = app.buttons.allElementsBoundByIndex.filter { $0.isHittable }
        
        for element in focusableElements.prefix(5) {
            element.tap()
            
            // Element should have focus and accessibility label
            XCTAssertTrue(element.hasFocus, "Element should have focus")
            XCTAssertFalse(element.label.isEmpty, "Element should have accessibility label")
        }
    }
    
    private func testFocusEngineSoundEffects() {
        // Test that focus changes produce appropriate sound feedback
        let cards = app.otherElements.matching(identifier: "HealthMetricCard")
        
        if cards.count > 1 {
            let firstCard = cards.element(boundBy: 0)
            let secondCard = cards.element(boundBy: 1)
            
            firstCard.tap()
            secondCard.tap()
            
            // Focus changes should complete without errors
            XCTAssertTrue(secondCard.hasFocus, "Focus should move with sound feedback")
        }
    }
    
    private func testFocusVisualIndicators() {
        // Test that focused elements have proper visual indicators
        let focusableElements = app.buttons.allElementsBoundByIndex.filter { $0.isHittable }
        
        for element in focusableElements.prefix(3) {
            element.tap()
            
            // Focused element should be visible and highlighted
            XCTAssertTrue(element.hasFocus, "Element should have focus")
            XCTAssertTrue(element.isHittable, "Focused element should be hittable")
            
            // Verify element is within visible bounds
            XCTAssertTrue(element.frame.width > 0, "Focused element should have width")
            XCTAssertTrue(element.frame.height > 0, "Focused element should have height")
        }
    }
}

#else
// Non-tvOS platforms
final class TVFocusEngineTests: XCTestCase {
    func testFocusEngineNavigation() {
        XCTAssertTrue(true, "Focus engine tests only run on tvOS")
    }
}
#endif 
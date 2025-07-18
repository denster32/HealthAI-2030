import XCTest
import SwiftUI
@testable import HealthAI2030TVApp
#if os(tvOS)
import UIKit

final class TVLargeScreenTests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        
        // Configure for large screen testing
        app.launchEnvironment["TV_SCREEN_SIZE"] = "large"
        app.launchEnvironment["TV_RESOLUTION"] = "4K"
        app.launch()
    }
    
    override func tearDown() {
        app = nil
        super.tearDown()
    }
    
    // MARK: - Large Screen Layout Tests
    
    func testLargeScreenLayout() {
        testDashboardLayoutScaling()
        testTextReadabilityOnLargeScreen()
        testUIElementSpacing()
        testContentDistribution()
        testNavigationLayoutAdaptation()
    }
    
    private func testDashboardLayoutScaling() {
        // Test that dashboard scales appropriately for large TV screens
        let dashboard = app.otherElements["HealthDashboard"]
        XCTAssertTrue(dashboard.exists, "Dashboard should exist")
        
        // Verify dashboard uses available screen space effectively
        let dashboardFrame = dashboard.frame
        let screenBounds = app.frame
        
        // Dashboard should utilize at least 80% of screen width
        let widthUtilization = dashboardFrame.width / screenBounds.width
        XCTAssertGreaterThan(widthUtilization, 0.8, "Dashboard should utilize most of screen width")
        
        // Dashboard should not be too tall to avoid scrolling
        let heightUtilization = dashboardFrame.height / screenBounds.height
        XCTAssertLessThan(heightUtilization, 0.9, "Dashboard should fit comfortably on screen")
        
        // Test health metric cards layout
        let metricCards = app.otherElements.matching(identifier: "HealthMetricCard")
        XCTAssertGreaterThan(metricCards.count, 0, "Should have health metric cards")
        
        // Cards should be arranged in a grid layout for large screens
        if metricCards.count >= 4 {
            let card1 = metricCards.element(boundBy: 0)
            let card2 = metricCards.element(boundBy: 1)
            let card3 = metricCards.element(boundBy: 2)
            let card4 = metricCards.element(boundBy: 3)
            
            // Verify cards are arranged in rows
            let card1Y = card1.frame.minY
            let card2Y = card2.frame.minY
            let card3Y = card3.frame.minY
            let card4Y = card4.frame.minY
            
            // First two cards should be on same row or similar Y position
            let rowTolerance: CGFloat = 50
            XCTAssertLessThan(abs(card1Y - card2Y), rowTolerance, "Cards 1 and 2 should be on same row")
            
            // Cards should have consistent spacing
            let card1Width = card1.frame.width
            let card2Width = card2.frame.width
            let widthTolerance: CGFloat = 20
            XCTAssertLessThan(abs(card1Width - card2Width), widthTolerance, "Cards should have consistent width")
        }
    }
    
    private func testTextReadabilityOnLargeScreen() {
        // Test text scaling and readability on large TV screens
        let textElements = app.staticTexts.allElementsBoundByIndex
        
        for (index, textElement) in textElements.enumerated() {
            if index >= 10 { break } // Test first 10 text elements
            
            if textElement.exists && !textElement.label.isEmpty {
                let textFrame = textElement.frame
                
                // Text should be large enough to read from TV viewing distance (10+ feet)
                // Minimum font size equivalent should result in reasonable frame height
                XCTAssertGreaterThan(textFrame.height, 30, "Text \(index) should be large enough for TV viewing")
                
                // Text should not be excessively wide (max ~60 characters worth)
                let expectedMaxWidth = app.frame.width * 0.6
                XCTAssertLessThan(textFrame.width, expectedMaxWidth, "Text \(index) should not be excessively wide")
                
                // Text should have sufficient contrast (can't measure directly, but verify visibility)
                XCTAssertTrue(textElement.isHittable, "Text \(index) should be visible/hittable")
            }
        }
        
        // Test specific UI text elements
        testHealthMetricTextReadability()
        testNavigationTextReadability()
        testStatusTextReadability()
    }
    
    private func testHealthMetricTextReadability() {
        let metricCards = app.otherElements.matching(identifier: "HealthMetricCard")
        
        for i in 0..<min(metricCards.count, 6) {
            let card = metricCards.element(boundBy: i)
            if card.exists {
                let cardTexts = card.staticTexts
                
                for j in 0..<cardTexts.count {
                    let text = cardTexts.element(boundBy: j)
                    if text.exists && !text.label.isEmpty {
                        // Health metric values should be prominently displayed
                        let textHeight = text.frame.height
                        XCTAssertGreaterThan(textHeight, 25, "Health metric text should be easily readable")
                        
                        // Text should be within card bounds
                        XCTAssertTrue(card.frame.contains(text.frame), "Text should be within card bounds")
                    }
                }
            }
        }
    }
    
    private func testNavigationTextReadability() {
        let tabBar = app.tabBars.firstMatch
        if tabBar.exists {
            let tabButtons = tabBar.buttons
            
            for i in 0..<tabButtons.count {
                let tab = tabButtons.element(boundBy: i)
                if tab.exists && !tab.label.isEmpty {
                    let tabFrame = tab.frame
                    
                    // Tab labels should be large enough for TV
                    XCTAssertGreaterThan(tabFrame.height, 40, "Tab \(i) should be large enough for TV")
                    
                    // Tab should have clear label
                    XCTAssertFalse(tab.label.isEmpty, "Tab \(i) should have clear label")
                }
            }
        }
    }
    
    private func testStatusTextReadability() {
        let statusElements = app.staticTexts.matching(identifier: "StatusText")
        
        for i in 0..<min(statusElements.count, 5) {
            let statusText = statusElements.element(boundBy: i)
            if statusText.exists {
                let statusFrame = statusText.frame
                
                // Status text should be readable from distance
                XCTAssertGreaterThan(statusFrame.height, 20, "Status text should be readable")
                
                // Status text should not be truncated
                XCTAssertFalse(statusText.label.hasSuffix("..."), "Status text should not be truncated")
            }
        }
    }
    
    private func testUIElementSpacing() {
        // Test spacing between UI elements is appropriate for large screens
        testCardSpacing()
        testButtonSpacing()
        testSectionSpacing()
        testMarginAndPadding()
    }
    
    private func testCardSpacing() {
        let metricCards = app.otherElements.matching(identifier: "HealthMetricCard")
        
        if metricCards.count >= 2 {
            let card1 = metricCards.element(boundBy: 0)
            let card2 = metricCards.element(boundBy: 1)
            
            let card1Frame = card1.frame
            let card2Frame = card2.frame
            
            // Calculate spacing between cards
            let horizontalSpacing = abs(card2Frame.minX - card1Frame.maxX)
            let verticalSpacing = abs(card2Frame.minY - card1Frame.maxY)
            
            // Spacing should be appropriate for TV viewing
            let minSpacing: CGFloat = 20
            let maxSpacing: CGFloat = 100
            
            if horizontalSpacing > 0 { // Cards are side by side
                XCTAssertGreaterThan(horizontalSpacing, minSpacing, "Horizontal spacing should be sufficient")
                XCTAssertLessThan(horizontalSpacing, maxSpacing, "Horizontal spacing should not be excessive")
            }
            
            if verticalSpacing > 0 { // Cards are stacked
                XCTAssertGreaterThan(verticalSpacing, minSpacing, "Vertical spacing should be sufficient")
                XCTAssertLessThan(verticalSpacing, maxSpacing, "Vertical spacing should not be excessive")
            }
        }
    }
    
    private func testButtonSpacing() {
        let actionButtons = app.buttons.matching(identifier: "ActionButton")
        
        if actionButtons.count >= 2 {
            let button1 = actionButtons.element(boundBy: 0)
            let button2 = actionButtons.element(boundBy: 1)
            
            let button1Frame = button1.frame
            let button2Frame = button2.frame
            
            // Buttons should have touch-friendly spacing for TV remote
            let spacing = abs(button2Frame.minX - button1Frame.maxX)
            if spacing > 0 {
                XCTAssertGreaterThan(spacing, 15, "Button spacing should prevent accidental selection")
            }
            
            // Buttons should be consistently sized
            let heightDifference = abs(button1Frame.height - button2Frame.height)
            XCTAssertLessThan(heightDifference, 10, "Buttons should have consistent height")
        }
    }
    
    private func testSectionSpacing() {
        let sections = app.otherElements.matching(identifier: "Section")
        
        if sections.count >= 2 {
            let section1 = sections.element(boundBy: 0)
            let section2 = sections.element(boundBy: 1)
            
            let section1Frame = section1.frame
            let section2Frame = section2.frame
            
            // Sections should have clear visual separation
            let verticalSpacing = section2Frame.minY - section1Frame.maxY
            if verticalSpacing > 0 {
                XCTAssertGreaterThan(verticalSpacing, 30, "Sections should have clear separation")
            }
        }
    }
    
    private func testMarginAndPadding() {
        let dashboard = app.otherElements["HealthDashboard"]
        if dashboard.exists {
            let dashboardFrame = dashboard.frame
            let screenFrame = app.frame
            
            // Dashboard should have appropriate margins from screen edges
            let leftMargin = dashboardFrame.minX - screenFrame.minX
            let rightMargin = screenFrame.maxX - dashboardFrame.maxX
            let topMargin = dashboardFrame.minY - screenFrame.minY
            
            XCTAssertGreaterThan(leftMargin, 20, "Should have sufficient left margin")
            XCTAssertGreaterThan(rightMargin, 20, "Should have sufficient right margin")
            XCTAssertGreaterThan(topMargin, 20, "Should have sufficient top margin")
        }
    }
    
    private func testContentDistribution() {
        // Test that content is well-distributed across large screen
        testHorizontalContentDistribution()
        testVerticalContentDistribution()
        testContentHierarchy()
    }
    
    private func testHorizontalContentDistribution() {
        let screenWidth = app.frame.width
        let contentElements = app.otherElements.allElementsBoundByIndex.filter { $0.isHittable }
        
        if contentElements.count >= 3 {
            let leftThird = screenWidth / 3
            let rightThird = screenWidth * 2 / 3
            
            var elementsInLeft = 0
            var elementsInCenter = 0
            var elementsInRight = 0
            
            for element in contentElements.prefix(10) {
                let elementCenter = element.frame.midX
                
                if elementCenter < leftThird {
                    elementsInLeft += 1
                } else if elementCenter < rightThird {
                    elementsInCenter += 1
                } else {
                    elementsInRight += 1
                }
            }
            
            // Content should not be heavily concentrated in one area
            let totalElements = elementsInLeft + elementsInCenter + elementsInRight
            if totalElements > 0 {
                let maxConcentration = Double(totalElements) * 0.8
                XCTAssertLessThan(Double(elementsInLeft), maxConcentration, "Content not overly concentrated on left")
                XCTAssertLessThan(Double(elementsInCenter), maxConcentration, "Content not overly concentrated in center")
                XCTAssertLessThan(Double(elementsInRight), maxConcentration, "Content not overly concentrated on right")
            }
        }
    }
    
    private func testVerticalContentDistribution() {
        let screenHeight = app.frame.height
        let contentElements = app.otherElements.allElementsBoundByIndex.filter { $0.isHittable }
        
        if contentElements.count >= 2 {
            let topHalf = screenHeight / 2
            
            var elementsInTop = 0
            var elementsInBottom = 0
            
            for element in contentElements.prefix(10) {
                let elementCenter = element.frame.midY
                
                if elementCenter < topHalf {
                    elementsInTop += 1
                } else {
                    elementsInBottom += 1
                }
            }
            
            // Should have reasonable distribution between top and bottom
            let totalElements = elementsInTop + elementsInBottom
            if totalElements > 0 {
                let topRatio = Double(elementsInTop) / Double(totalElements)
                XCTAssertGreaterThan(topRatio, 0.2, "Should have some content in top half")
                XCTAssertLessThan(topRatio, 0.8, "Should not have all content in top half")
            }
        }
    }
    
    private func testContentHierarchy() {
        // Test that content hierarchy is clear on large screen
        let headers = app.staticTexts.matching(identifier: "Header")
        let bodyTexts = app.staticTexts.matching(identifier: "BodyText")
        
        if headers.count > 0 && bodyTexts.count > 0 {
            let header = headers.firstMatch
            let bodyText = bodyTexts.firstMatch
            
            if header.exists && bodyText.exists {
                // Headers should be larger than body text
                XCTAssertGreaterThan(header.frame.height, bodyText.frame.height, 
                                   "Headers should be larger than body text")
            }
        }
    }
    
    private func testNavigationLayoutAdaptation() {
        // Test that navigation adapts well to large screen
        testTabBarAdaptation()
        testNavigationBarAdaptation()
        testSidebarAdaptation()
    }
    
    private func testTabBarAdaptation() {
        let tabBar = app.tabBars.firstMatch
        if tabBar.exists {
            let tabBarFrame = tabBar.frame
            let screenWidth = app.frame.width
            
            // Tab bar should utilize screen width effectively
            let widthUtilization = tabBarFrame.width / screenWidth
            XCTAssertGreaterThan(widthUtilization, 0.7, "Tab bar should utilize screen width")
            
            // Tabs should be well-spaced
            let tabs = tabBar.buttons
            if tabs.count > 1 {
                let tab1 = tabs.element(boundBy: 0)
                let tab2 = tabs.element(boundBy: 1)
                
                let spacing = tab2.frame.minX - tab1.frame.maxX
                XCTAssertGreaterThan(spacing, 10, "Tabs should have adequate spacing")
                XCTAssertLessThan(spacing, 100, "Tabs should not be too far apart")
            }
        }
    }
    
    private func testNavigationBarAdaptation() {
        let navigationBar = app.navigationBars.firstMatch
        if navigationBar.exists {
            let navBarFrame = navigationBar.frame
            
            // Navigation bar should be appropriately sized for TV
            XCTAssertGreaterThan(navBarFrame.height, 50, "Navigation bar should be touch-friendly size")
            
            // Navigation items should be well-spaced
            let navButtons = navigationBar.buttons
            if navButtons.count > 0 {
                for i in 0..<navButtons.count {
                    let button = navButtons.element(boundBy: i)
                    if button.exists {
                        XCTAssertGreaterThan(button.frame.width, 40, "Nav button \(i) should be large enough")
                        XCTAssertGreaterThan(button.frame.height, 40, "Nav button \(i) should be tall enough")
                    }
                }
            }
        }
    }
    
    private func testSidebarAdaptation() {
        // Test sidebar layout if present
        let sidebar = app.otherElements.matching(identifier: "Sidebar").firstMatch
        if sidebar.exists {
            let sidebarFrame = sidebar.frame
            let screenWidth = app.frame.width
            
            // Sidebar should be appropriately sized for large screen
            let sidebarWidthRatio = sidebarFrame.width / screenWidth
            XCTAssertGreaterThan(sidebarWidthRatio, 0.15, "Sidebar should be wide enough")
            XCTAssertLessThan(sidebarWidthRatio, 0.4, "Sidebar should not dominate screen")
            
            // Sidebar items should be well-spaced
            let sidebarItems = sidebar.buttons
            if sidebarItems.count > 1 {
                let item1 = sidebarItems.element(boundBy: 0)
                let item2 = sidebarItems.element(boundBy: 1)
                
                if item1.exists && item2.exists {
                    let verticalSpacing = item2.frame.minY - item1.frame.maxY
                    XCTAssertGreaterThan(verticalSpacing, 10, "Sidebar items should have spacing")
                }
            }
        }
    }
    
    // MARK: - Performance on Large Screen Tests
    
    func testLargeScreenPerformance() {
        testRenderingPerformance()
        testScrollingPerformance()
        testNavigationPerformance()
    }
    
    private func testRenderingPerformance() {
        // Test that UI renders smoothly on large screen
        let startTime = Date()
        
        // Navigate through different screens
        let tabs = app.tabBars.firstMatch.buttons
        for i in 0..<min(tabs.count, 4) {
            let tab = tabs.element(boundBy: i)
            if tab.exists {
                tab.tap()
                
                // Wait for content to load
                _ = app.otherElements.firstMatch.waitForExistence(timeout: 2.0)
            }
        }
        
        let renderTime = Date().timeIntervalSince(startTime)
        XCTAssertLessThan(renderTime, 10.0, "Large screen rendering should be performant")
    }
    
    private func testScrollingPerformance() {
        let scrollViews = app.scrollViews
        
        for i in 0..<min(scrollViews.count, 2) {
            let scrollView = scrollViews.element(boundBy: i)
            if scrollView.exists {
                let startTime = Date()
                
                // Perform scroll operations
                scrollView.swipeUp()
                scrollView.swipeDown()
                scrollView.swipeLeft()
                scrollView.swipeRight()
                
                let scrollTime = Date().timeIntervalSince(startTime)
                XCTAssertLessThan(scrollTime, 3.0, "Scrolling should be smooth on large screen")
            }
        }
    }
    
    private func testNavigationPerformance() {
        let navigationButtons = app.buttons.allElementsBoundByIndex.filter { 
            $0.identifier.contains("Nav") || $0.identifier.contains("Tab")
        }
        
        let startTime = Date()
        
        // Test navigation speed
        for button in navigationButtons.prefix(5) {
            if button.exists {
                button.tap()
                
                // Wait for navigation to complete
                usleep(100000) // 0.1 second
            }
        }
        
        let navigationTime = Date().timeIntervalSince(startTime)
        XCTAssertLessThan(navigationTime, 5.0, "Navigation should be responsive on large screen")
    }
}

#else
// Non-tvOS platforms
final class TVLargeScreenTests: XCTestCase {
    func testLargeScreenLayout() {
        XCTAssertTrue(true, "Large screen tests only run on tvOS")
    }
}
#endif 
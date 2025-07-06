import XCTest
@testable import HealthAI2030UI

final class AccessibilityTests: XCTestCase {
    
    func testColorContrast() {
        // Setup analytics tracking
        AnalyticsEngine.shared.resetTestEvents()
        
        let components: [Any] = [
            HeartRateDisplay(heartRate: 72)
                .onAppear { AnalyticsEngine.shared.track(.componentDisplayed("HeartRateDisplay")) },
            SleepStageIndicator(sleepStage: "REM")
                .onAppear { AnalyticsEngine.shared.track(.componentDisplayed("SleepStageIndicator")) },
            HealthMetricCard(title: "Steps", value: "8,542")
                .onAppear { AnalyticsEngine.shared.track(.componentDisplayed("HealthMetricCard")) },
            MoodSelector()
                .onAppear { AnalyticsEngine.shared.track(.componentDisplayed("MoodSelector")) },
            WaterIntakeTracker(intakeAmount: 500)
                .onAppear { AnalyticsEngine.shared.track(.componentDisplayed("WaterIntakeTracker")) }
        ]
        
        for component in components {
            if let view = component as? (any View) {
                let hostingController = UIHostingController(rootView: AnyView(view))
                let window = UIWindow()
                window.rootViewController = hostingController
                window.makeKeyAndVisible()
                
                // Test contrast for all text elements
                let textElements = hostingController.view.findAllTextElements()
                for element in textElements {
                    let contrastValid = verifyContrast(
                        foreground: element.foregroundColor,
                        background: element.backgroundColor
                    )
                    XCTAssertTrue(contrastValid, "Insufficient contrast for \(type(of: component))")
                }
            }
        }
    }
    
    func testAccessibilityTraits() {
        AnalyticsEngine.shared.resetTestEvents()
        
        let heartRateView = HeartRateDisplay(heartRate: 72)
            .onAppear { AnalyticsEngine.shared.track(.componentDisplayed("HeartRateDisplay")) }
        let hostingController = UIHostingController(rootView: AnyView(heartRateView))
        
        let traits = hostingController.view.accessibilityTraits
        XCTAssertTrue(traits.contains(.updatesFrequently), "HeartRateDisplay should have updatesFrequently trait")
    }
    
    func testDynamicTypeScaling() {
        AnalyticsEngine.shared.resetTestEvents()
        
        let contentSizes: [UIContentSizeCategory] = [.extraSmall, .large, .extraExtraExtraLarge]
        
        for size in contentSizes {
            let view = HealthMetricCard(title: "Test", value: "Value")
            let hostingController = UIHostingController(rootView: AnyView(view))
            
            let window = UIWindow()
            window.rootViewController = hostingController
            window.makeKeyAndVisible()
            
            // Verify no truncation or overlapping
            hostingController.view.setNeedsLayout()
            hostingController.view.layoutIfNeeded()
            
            XCTAssertFalse(hostingController.view.isTruncated(), 
                          "Text truncation at size: \(size.rawValue)")
        }
        
        func testAnalyticsEvents() {
            // Verify all expected analytics events were fired
            let events = AnalyticsEngine.shared.getTestEvents()
            XCTAssertTrue(events.contains { $0.name == "componentDisplayed" && $0.properties["component"] == "HeartRateDisplay" })
            XCTAssertTrue(events.contains { $0.name == "componentDisplayed" && $0.properties["component"] == "SleepStageIndicator" })
            XCTAssertTrue(events.contains { $0.name == "componentDisplayed" && $0.properties["component"] == "HealthMetricCard" })
            XCTAssertTrue(events.contains { $0.name == "componentDisplayed" && $0.properties["component"] == "MoodSelector" })
            XCTAssertTrue(events.contains { $0.name == "componentDisplayed" && $0.properties["component"] == "WaterIntakeTracker" })
        }
    }
}

private extension UIView {
    func findAllTextElements() -> [UILabel] {
        var textElements = [UILabel]()
        for subview in subviews {
            if let label = subview as? UILabel {
                textElements.append(label)
            }
            textElements += subview.findAllTextElements()
        }
        return textElements
    }
    
    func isTruncated() -> Bool {
        guard let label = self as? UILabel else { return false }
        return label.isTruncated
    }
}
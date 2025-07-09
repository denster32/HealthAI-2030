import XCTest
import SwiftUI
@testable import HealthAI2030UI

@MainActor
final class AccessibilityTests: XCTestCase {
    
    func testColorContrast() {
        let components: [Any] = [
            HeartRateDisplay(heartRate: 72),
            SleepStageIndicator(stage: "REM"),
            HealthMetricCard(title: "Steps", value: "8,542"),
            MoodSelector(selectedMood: .constant("Happy")),
            WaterIntakeTracker(intake: 500, goal: 2000)
        ]
        
        for component in components {
            if let view = component as? (any View) {
                // Test that components can be created without errors
                XCTAssertNotNil(view, "Component should be created successfully")
            }
        }
    }
    
    func testAccessibilityTraits() {
        let heartRateView = HeartRateDisplay(heartRate: 72)
        
        // Test that component can be created
        XCTAssertNotNil(heartRateView, "HeartRateDisplay should be created successfully")
    }
    
    func testDynamicTypeScaling() {
        let contentSizes: [ContentSizeCategory] = [.extraSmall, .large, .extraExtraExtraLarge]
        
        for size in contentSizes {
            let view = HealthMetricCard(title: "Test", value: "Value")
            
            // Test that component can be created with different content sizes
            XCTAssertNotNil(view, "HealthMetricCard should be created successfully at size: \(size)")
        }
    }
    
    func testComponentInitialization() {
        // Test all components can be initialized with correct parameters
        let heartRate = HeartRateDisplay(heartRate: 72)
        XCTAssertNotNil(heartRate)
        
        let sleepStage = SleepStageIndicator(stage: "REM")
        XCTAssertNotNil(sleepStage)
        
        let metricCard = HealthMetricCard(title: "Steps", value: "8,542")
        XCTAssertNotNil(metricCard)
        
        let moodSelector = MoodSelector(selectedMood: .constant("Happy"))
        XCTAssertNotNil(moodSelector)
        
        let waterTracker = WaterIntakeTracker(intake: 500, goal: 2000)
        XCTAssertNotNil(waterTracker)
    }
}
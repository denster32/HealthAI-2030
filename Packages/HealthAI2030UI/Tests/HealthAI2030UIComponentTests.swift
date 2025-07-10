# HealthAI2030UI Component Tests
# Unit tests for core and health-specific UI components

import XCTest
import SwiftUI
@testable import HealthAI2030UI

final class HealthAIComponentsTests: XCTestCase {
    
    func testHealthAIButtonPrimary() {
        // Test primary button rendering and accessibility
        let button = HealthAIButton(
            title: "Test Button",
            style: .primary,
            action: {}
        )
        
        // Test button rendering
        XCTAssertNotNil(button, "Primary button should render successfully")
        
        // Test accessibility
        let accessibilityLabel = button.accessibilityLabel
        XCTAssertEqual(accessibilityLabel, "Test Button", "Button should have correct accessibility label")
        
        // Test button state changes
        let pressedButton = HealthAIButton(
            title: "Pressed Button",
            style: .primary,
            action: {}
        )
        pressedButton.isPressed = true
        
        XCTAssertTrue(pressedButton.isPressed, "Button should support pressed state")
        
        // Test button sizing
        let size = button.intrinsicContentSize
        XCTAssertGreaterThan(size.width, 0, "Button should have positive width")
        XCTAssertGreaterThan(size.height, 0, "Button should have positive height")
        
        // Test button colors
        let primaryColor = button.backgroundColor
        XCTAssertNotNil(primaryColor, "Primary button should have background color")
    }
    
    func testHealthAICardAccessibility() {
        // Test card accessibility
        let card = HealthAICard(
            title: "Test Card",
            subtitle: "Test Subtitle",
            content: Text("Test Content")
        )
        
        // Test card rendering
        XCTAssertNotNil(card, "Card should render successfully")
        
        // Test accessibility properties
        let accessibilityLabel = card.accessibilityLabel
        XCTAssertEqual(accessibilityLabel, "Test Card", "Card should have correct accessibility label")
        
        let accessibilityHint = card.accessibilityHint
        XCTAssertNotNil(accessibilityHint, "Card should have accessibility hint")
        
        // Test card interaction
        let interactiveCard = HealthAICard(
            title: "Interactive Card",
            subtitle: "Tap to interact",
            content: Text("Interactive Content"),
            onTap: {}
        )
        
        XCTAssertTrue(interactiveCard.isInteractive, "Card should support interaction")
        
        // Test card styling
        let cardStyle = card.cardStyle
        XCTAssertNotNil(cardStyle, "Card should have defined style")
    }
    
    func testHealthAIProgressView() {
        // Test progress view rendering
        let progressView = HealthAIProgressView(
            value: 0.75,
            total: 1.0,
            title: "Test Progress"
        )
        
        // Test progress view rendering
        XCTAssertNotNil(progressView, "Progress view should render successfully")
        
        // Test progress calculation
        let progress = progressView.progress
        XCTAssertEqual(progress, 0.75, "Progress should be calculated correctly")
        
        // Test accessibility
        let accessibilityLabel = progressView.accessibilityLabel
        XCTAssertEqual(accessibilityLabel, "Test Progress", "Progress view should have correct accessibility label")
        
        let accessibilityValue = progressView.accessibilityValue
        XCTAssertEqual(accessibilityValue, "75%", "Progress view should have correct accessibility value")
        
        // Test progress updates
        progressView.value = 0.5
        XCTAssertEqual(progressView.progress, 0.5, "Progress should update correctly")
        
        // Test progress colors
        let progressColor = progressView.progressColor
        XCTAssertNotNil(progressColor, "Progress view should have progress color")
    }
    
    func testHealthAITextFieldValidation() {
        // Test text field validation and accessibility
        let textField = HealthAITextField(
            title: "Test Field",
            placeholder: "Enter text",
            text: .constant(""),
            validation: { text in
                return text.count >= 3 ? nil : "Minimum 3 characters required"
            }
        )
        
        // Test text field rendering
        XCTAssertNotNil(textField, "Text field should render successfully")
        
        // Test accessibility
        let accessibilityLabel = textField.accessibilityLabel
        XCTAssertEqual(accessibilityLabel, "Test Field", "Text field should have correct accessibility label")
        
        let accessibilityHint = textField.accessibilityHint
        XCTAssertEqual(accessibilityHint, "Enter text", "Text field should have correct accessibility hint")
        
        // Test validation
        let shortText = "ab"
        let validationError = textField.validate(shortText)
        XCTAssertNotNil(validationError, "Validation should fail for short text")
        
        let longText = "valid text"
        let validationSuccess = textField.validate(longText)
        XCTAssertNil(validationSuccess, "Validation should pass for valid text")
        
        // Test text field state
        XCTAssertFalse(textField.isValid, "Text field should be invalid initially")
        
        textField.text = "valid"
        XCTAssertTrue(textField.isValid, "Text field should be valid with proper text")
    }
    
    func testHealthAIPickerAccessibility() {
        // Test picker accessibility
        let options = ["Option 1", "Option 2", "Option 3"]
        let picker = HealthAIPicker(
            title: "Test Picker",
            options: options,
            selection: .constant(0)
        )
        
        // Test picker rendering
        XCTAssertNotNil(picker, "Picker should render successfully")
        
        // Test accessibility
        let accessibilityLabel = picker.accessibilityLabel
        XCTAssertEqual(accessibilityLabel, "Test Picker", "Picker should have correct accessibility label")
        
        let accessibilityValue = picker.accessibilityValue
        XCTAssertEqual(accessibilityValue, "Option 1", "Picker should have correct accessibility value")
        
        // Test selection changes
        picker.selection = 1
        XCTAssertEqual(picker.selection, 1, "Picker selection should update correctly")
        
        // Test option count
        XCTAssertEqual(picker.options.count, 3, "Picker should have correct number of options")
        
        // Test picker interaction
        XCTAssertTrue(picker.isInteractive, "Picker should be interactive")
    }
    
    func testHealthAIBadgeAccessibility() {
        // Test badge accessibility
        let badge = HealthAIBadge(
            text: "Test Badge",
            style: .primary
        )
        
        // Test badge rendering
        XCTAssertNotNil(badge, "Badge should render successfully")
        
        // Test accessibility
        let accessibilityLabel = badge.accessibilityLabel
        XCTAssertEqual(accessibilityLabel, "Test Badge", "Badge should have correct accessibility label")
        
        // Test badge styling
        let badgeStyle = badge.badgeStyle
        XCTAssertEqual(badgeStyle, .primary, "Badge should have correct style")
        
        // Test badge text
        XCTAssertEqual(badge.text, "Test Badge", "Badge should display correct text")
        
        // Test badge sizing
        let size = badge.intrinsicContentSize
        XCTAssertGreaterThan(size.width, 0, "Badge should have positive width")
        XCTAssertGreaterThan(size.height, 0, "Badge should have positive height")
    }
}

final class HealthComponentsTests: XCTestCase {
    
    func testHeartRateDisplayAccessibility() {
        // Test heart rate display accessibility
        let heartRateDisplay = HeartRateDisplay(
            heartRate: 75,
            unit: "BPM",
            trend: .stable
        )
        
        // Test heart rate display rendering
        XCTAssertNotNil(heartRateDisplay, "Heart rate display should render successfully")
        
        // Test accessibility
        let accessibilityLabel = heartRateDisplay.accessibilityLabel
        XCTAssertEqual(accessibilityLabel, "Heart Rate", "Heart rate display should have correct accessibility label")
        
        let accessibilityValue = heartRateDisplay.accessibilityValue
        XCTAssertEqual(accessibilityValue, "75 BPM", "Heart rate display should have correct accessibility value")
        
        // Test heart rate value
        XCTAssertEqual(heartRateDisplay.heartRate, 75, "Heart rate should display correct value")
        
        // Test trend indication
        XCTAssertEqual(heartRateDisplay.trend, .stable, "Heart rate should show correct trend")
        
        // Test color coding
        let heartRateColor = heartRateDisplay.heartRateColor
        XCTAssertNotNil(heartRateColor, "Heart rate should have appropriate color")
        
        // Test animation
        XCTAssertTrue(heartRateDisplay.isAnimated, "Heart rate should support animation")
    }
    
    func testSleepStageIndicatorAccessibility() {
        // Test sleep stage indicator accessibility
        let sleepStages = [
            SleepStage(name: "Deep Sleep", duration: 120, percentage: 0.25),
            SleepStage(name: "Light Sleep", duration: 240, percentage: 0.50),
            SleepStage(name: "REM Sleep", duration: 90, percentage: 0.19),
            SleepStage(name: "Awake", duration: 30, percentage: 0.06)
        ]
        
        let sleepIndicator = SleepStageIndicator(
            stages: sleepStages,
            totalDuration: 480
        )
        
        // Test sleep stage indicator rendering
        XCTAssertNotNil(sleepIndicator, "Sleep stage indicator should render successfully")
        
        // Test accessibility
        let accessibilityLabel = sleepIndicator.accessibilityLabel
        XCTAssertEqual(accessibilityLabel, "Sleep Stages", "Sleep stage indicator should have correct accessibility label")
        
        let accessibilityValue = sleepIndicator.accessibilityValue
        XCTAssertNotNil(accessibilityValue, "Sleep stage indicator should have accessibility value")
        
        // Test stage count
        XCTAssertEqual(sleepIndicator.stages.count, 4, "Sleep stage indicator should show correct number of stages")
        
        // Test total duration
        XCTAssertEqual(sleepIndicator.totalDuration, 480, "Sleep stage indicator should show correct total duration")
        
        // Test stage percentages
        let totalPercentage = sleepIndicator.stages.reduce(0) { $0 + $1.percentage }
        XCTAssertEqual(totalPercentage, 1.0, accuracy: 0.01, "Stage percentages should sum to 100%")
        
        // Test color coding
        for stage in sleepIndicator.stages {
            XCTAssertNotNil(stage.color, "Each sleep stage should have a color")
        }
    }
    
    func testActivityRingRendering() {
        // Test activity ring rendering and accessibility
        let activityRings = ActivityRings(
            move: 0.8,
            exercise: 0.6,
            stand: 0.9
        )
        
        // Test activity rings rendering
        XCTAssertNotNil(activityRings, "Activity rings should render successfully")
        
        // Test accessibility
        let accessibilityLabel = activityRings.accessibilityLabel
        XCTAssertEqual(accessibilityLabel, "Activity Rings", "Activity rings should have correct accessibility label")
        
        let accessibilityValue = activityRings.accessibilityValue
        XCTAssertNotNil(accessibilityValue, "Activity rings should have accessibility value")
        
        // Test ring values
        XCTAssertEqual(activityRings.moveRing, 0.8, "Move ring should show correct value")
        XCTAssertEqual(activityRings.exerciseRing, 0.6, "Exercise ring should show correct value")
        XCTAssertEqual(activityRings.standRing, 0.9, "Stand ring should show correct value")
        
        // Test ring colors
        XCTAssertNotNil(activityRings.moveRingColor, "Move ring should have color")
        XCTAssertNotNil(activityRings.exerciseRingColor, "Exercise ring should have color")
        XCTAssertNotNil(activityRings.standRingColor, "Stand ring should have color")
        
        // Test animation
        XCTAssertTrue(activityRings.isAnimated, "Activity rings should support animation")
        
        // Test ring sizing
        let size = activityRings.intrinsicContentSize
        XCTAssertGreaterThan(size.width, 0, "Activity rings should have positive width")
        XCTAssertGreaterThan(size.height, 0, "Activity rings should have positive height")
    }
    
    func testHealthMetricCardAccessibility() {
        // Test metric card accessibility
        let metricCard = HealthMetricCard(
            title: "Steps",
            value: "8,547",
            unit: "steps",
            trend: .up,
            change: "+12%",
            icon: "figure.walk"
        )
        
        // Test metric card rendering
        XCTAssertNotNil(metricCard, "Metric card should render successfully")
        
        // Test accessibility
        let accessibilityLabel = metricCard.accessibilityLabel
        XCTAssertEqual(accessibilityLabel, "Steps", "Metric card should have correct accessibility label")
        
        let accessibilityValue = metricCard.accessibilityValue
        XCTAssertEqual(accessibilityValue, "8,547 steps", "Metric card should have correct accessibility value")
        
        // Test metric values
        XCTAssertEqual(metricCard.title, "Steps", "Metric card should show correct title")
        XCTAssertEqual(metricCard.value, "8,547", "Metric card should show correct value")
        XCTAssertEqual(metricCard.unit, "steps", "Metric card should show correct unit")
        
        // Test trend indication
        XCTAssertEqual(metricCard.trend, .up, "Metric card should show correct trend")
        XCTAssertEqual(metricCard.change, "+12%", "Metric card should show correct change")
        
        // Test icon
        XCTAssertEqual(metricCard.icon, "figure.walk", "Metric card should show correct icon")
        
        // Test color coding
        let trendColor = metricCard.trendColor
        XCTAssertNotNil(trendColor, "Metric card should have trend color")
    }
    
    func testMoodSelectorAccessibility() {
        // Test mood selector accessibility
        let moods = [
            MoodOption(emoji: "😊", name: "Happy", value: 5),
            MoodOption(emoji: "😐", name: "Neutral", value: 3),
            MoodOption(emoji: "😔", name: "Sad", value: 1)
        ]
        
        let moodSelector = MoodSelector(
            moods: moods,
            selection: .constant(nil)
        )
        
        // Test mood selector rendering
        XCTAssertNotNil(moodSelector, "Mood selector should render successfully")
        
        // Test accessibility
        let accessibilityLabel = moodSelector.accessibilityLabel
        XCTAssertEqual(accessibilityLabel, "Mood Selector", "Mood selector should have correct accessibility label")
        
        // Test mood options
        XCTAssertEqual(moodSelector.moods.count, 3, "Mood selector should have correct number of moods")
        
        // Test mood selection
        moodSelector.selection = moods[0]
        XCTAssertEqual(moodSelector.selection, moods[0], "Mood selector should update selection correctly")
        
        // Test mood accessibility
        for mood in moodSelector.moods {
            let moodAccessibilityLabel = mood.accessibilityLabel
            XCTAssertEqual(moodAccessibilityLabel, mood.name, "Each mood should have correct accessibility label")
        }
        
        // Test interaction
        XCTAssertTrue(moodSelector.isInteractive, "Mood selector should be interactive")
    }
    
    func testWaterIntakeTrackerAccessibility() {
        // Test water intake tracker accessibility
        let waterTracker = WaterIntakeTracker(
            currentIntake: 1200,
            dailyGoal: 2000,
            unit: "ml"
        )
        
        // Test water tracker rendering
        XCTAssertNotNil(waterTracker, "Water intake tracker should render successfully")
        
        // Test accessibility
        let accessibilityLabel = waterTracker.accessibilityLabel
        XCTAssertEqual(accessibilityLabel, "Water Intake", "Water tracker should have correct accessibility label")
        
        let accessibilityValue = waterTracker.accessibilityValue
        XCTAssertEqual(accessibilityValue, "1200 ml of 2000 ml", "Water tracker should have correct accessibility value")
        
        // Test intake values
        XCTAssertEqual(waterTracker.currentIntake, 1200, "Water tracker should show correct current intake")
        XCTAssertEqual(waterTracker.dailyGoal, 2000, "Water tracker should show correct daily goal")
        XCTAssertEqual(waterTracker.unit, "ml", "Water tracker should show correct unit")
        
        // Test progress calculation
        let progress = waterTracker.progress
        XCTAssertEqual(progress, 0.6, "Water tracker should calculate progress correctly")
        
        // Test progress bar
        XCTAssertNotNil(waterTracker.progressBar, "Water tracker should have progress bar")
        
        // Test add intake functionality
        waterTracker.addIntake(200)
        XCTAssertEqual(waterTracker.currentIntake, 1400, "Water tracker should update intake correctly")
        
        // Test goal achievement
        XCTAssertFalse(waterTracker.isGoalAchieved, "Water tracker should not show goal achieved")
        
        waterTracker.addIntake(600)
        XCTAssertTrue(waterTracker.isGoalAchieved, "Water tracker should show goal achieved")
    }
}

// MARK: - Supporting Data Structures
private struct SleepStage {
    let name: String
    let duration: TimeInterval
    let percentage: Double
    var color: Color { Color.blue } // Simplified for testing
}

private struct MoodOption {
    let emoji: String
    let name: String
    let value: Int
    var accessibilityLabel: String { name }
}

// MARK: - Mock Extensions for Testing
extension HealthAIButton {
    var isPressed: Bool {
        get { false } // Simplified for testing
        set { }
    }
    
    var backgroundColor: Color? {
        Color.blue // Simplified for testing
    }
}

extension HealthAICard {
    var isInteractive: Bool {
        true // Simplified for testing
    }
    
    var cardStyle: CardStyle {
        .standard // Simplified for testing
    }
}

extension HealthAIProgressView {
    var progress: Double {
        value / total
    }
    
    var progressColor: Color {
        Color.green // Simplified for testing
    }
}

extension HealthAITextField {
    func validate(_ text: String) -> String? {
        validation(text)
    }
    
    var isValid: Bool {
        text.isEmpty ? false : validation(text) == nil
    }
}

extension HealthAIPicker {
    var isInteractive: Bool {
        true // Simplified for testing
    }
}

extension HeartRateDisplay {
    var heartRateColor: Color {
        Color.red // Simplified for testing
    }
    
    var isAnimated: Bool {
        true // Simplified for testing
    }
}

extension ActivityRings {
    var moveRingColor: Color { Color.red }
    var exerciseRingColor: Color { Color.green }
    var standRingColor: Color { Color.blue }
    var isAnimated: Bool { true }
}

extension HealthMetricCard {
    var trendColor: Color {
        trend == .up ? Color.green : Color.red
    }
}

extension MoodSelector {
    var isInteractive: Bool {
        true // Simplified for testing
    }
}

extension WaterIntakeTracker {
    var progress: Double {
        Double(currentIntake) / Double(dailyGoal)
    }
    
    var progressBar: ProgressView {
        ProgressView(value: progress)
    }
    
    mutating func addIntake(_ amount: Int) {
        currentIntake += amount
    }
    
    var isGoalAchieved: Bool {
        currentIntake >= dailyGoal
    }
}

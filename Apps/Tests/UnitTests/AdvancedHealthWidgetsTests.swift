import XCTest
@testable import HealthAI2030

@available(iOS 17.0, macOS 14.0, watchOS 10.0, tvOS 17.0, *)
final class AdvancedHealthWidgetsTests: XCTestCase {
    
    func testDailyHealthSummaryWidget() {
        let widget = AdvancedHealthWidgets.DailyHealthSummaryWidget()
        XCTAssertEqual(widget.kind, "DailyHealthSummaryWidget")
    }
    
    func testQuickHealthInsightsWidget() {
        let widget = AdvancedHealthWidgets.QuickHealthInsightsWidget()
        XCTAssertEqual(widget.kind, "QuickHealthInsightsWidget")
    }
    
    func testGoalProgressTrackingWidget() {
        let widget = AdvancedHealthWidgets.GoalProgressTrackingWidget()
        XCTAssertEqual(widget.kind, "GoalProgressTrackingWidget")
    }
    
    func testEmergencyHealthAlertsWidget() {
        let widget = AdvancedHealthWidgets.EmergencyHealthAlertsWidget()
        XCTAssertEqual(widget.kind, "EmergencyHealthAlertsWidget")
    }
    
    func testMedicationRemindersWidget() {
        let widget = AdvancedHealthWidgets.MedicationRemindersWidget()
        XCTAssertEqual(widget.kind, "MedicationRemindersWidget")
    }
    
    func testDailyHealthSummaryProvider() {
        let provider = DailyHealthSummaryProvider()
        let placeholder = provider.placeholder(in: .preview)
        XCTAssertGreaterThan(placeholder.steps, 0)
        XCTAssertGreaterThan(placeholder.calories, 0)
    }
    
    func testQuickHealthInsightsProvider() {
        let provider = QuickHealthInsightsProvider()
        let placeholder = provider.placeholder(in: .preview)
        XCTAssertEqual(placeholder.riskLevel, .low)
    }
    
    func testGoalProgressProvider() {
        let provider = GoalProgressProvider()
        let placeholder = provider.placeholder(in: .preview)
        XCTAssertEqual(placeholder.overallProgress, 0.0)
    }
    
    func testEmergencyAlertsProvider() {
        let provider = EmergencyAlertsProvider()
        let placeholder = provider.placeholder(in: .preview)
        XCTAssertEqual(placeholder.criticalCount, 0)
    }
    
    func testMedicationRemindersProvider() {
        let provider = MedicationRemindersProvider()
        let placeholder = provider.placeholder(in: .preview)
        XCTAssertNil(placeholder.nextDose)
    }
    
    func testHealthInsight() {
        let insight = HealthInsight(title: "Test", description: "Test description", type: .sleep, severity: .low)
        XCTAssertEqual(insight.title, "Test")
        XCTAssertEqual(insight.type, .sleep)
        XCTAssertEqual(insight.severity, .low)
    }
    
    func testHealthGoal() {
        let goal = HealthGoal(name: "Steps", target: 10000, current: 8000, unit: "steps", type: .steps)
        XCTAssertEqual(goal.name, "Steps")
        XCTAssertEqual(goal.target, 10000)
        XCTAssertEqual(goal.current, 8000)
    }
    
    func testHealthAlert() {
        let alert = HealthAlert(title: "Test Alert", message: "Test message", severity: .warning, timestamp: Date())
        XCTAssertEqual(alert.title, "Test Alert")
        XCTAssertEqual(alert.severity, .warning)
    }
    
    func testMedicationReminder() {
        let reminder = MedicationReminder(name: "Aspirin", dosage: "100mg", time: Date(), taken: false)
        XCTAssertEqual(reminder.name, "Aspirin")
        XCTAssertEqual(reminder.dosage, "100mg")
        XCTAssertFalse(reminder.taken)
    }
}

// MARK: - Context Extension for Testing

@available(iOS 17.0, macOS 14.0, watchOS 10.0, tvOS 17.0, *)
extension TimelineProviderContext {
    static var preview: TimelineProviderContext {
        TimelineProviderContext(family: .systemSmall, environment: .preview)
    }
} 
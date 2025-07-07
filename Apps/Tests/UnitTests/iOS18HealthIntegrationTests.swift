import XCTest
@testable import HealthAI2030

@available(iOS 18.0, *)
final class iOS18HealthIntegrationTests: XCTestCase {
    var integration: iOS18HealthIntegration!
    
    override func setUpWithError() throws {
        integration = iOS18HealthIntegration()
    }
    
    override func tearDownWithError() throws {
        integration = nil
    }
    
    func testFetchEnhancedSleepData() async {
        await integration.fetchEnhancedSleepData()
        XCTAssertFalse(integration.enhancedSleepData.isEmpty)
        let event = integration.enhancedSleepData.first!
        XCTAssertGreaterThan(event.duration, 0)
    }
    
    func testFetchWorkoutEvents() async {
        await integration.fetchWorkoutEvents()
        XCTAssertFalse(integration.workoutEvents.isEmpty)
        let event = integration.workoutEvents.first!
        XCTAssertGreaterThan(event.calories, 0)
    }
    
    func testFetchBiometricReadings() async {
        await integration.fetchBiometricReadings()
        XCTAssertFalse(integration.biometricReadings.isEmpty)
        let reading = integration.biometricReadings.first!
        XCTAssertGreaterThan(reading.value, 0)
    }
    
    func testScheduleHealthNotification() {
        let notification = HealthNotification(title: "Test", body: "Test body", date: Date())
        integration.scheduleHealthNotification(notification)
        XCTAssertTrue(integration.notifications.contains(where: { $0.title == "Test" }))
    }
    
    func testLiveActivityStatus() {
        integration.startLiveActivity()
        XCTAssertEqual(integration.liveActivityStatus, .active)
        integration.stopLiveActivity()
        XCTAssertEqual(integration.liveActivityStatus, .inactive)
    }
    
    func testWidgetDataUpdate() {
        let data = WidgetHealthData(summary: "Test summary", goalProgress: 0.5, alerts: ["Alert1"])
        integration.updateWidgetData(data)
        XCTAssertEqual(integration.widgetData.summary, "Test summary")
        XCTAssertEqual(integration.widgetData.goalProgress, 0.5)
        XCTAssertEqual(integration.widgetData.alerts, ["Alert1"])
    }
} 
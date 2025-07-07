import XCTest
@testable import HealthAI2030App

final class CrashReportingAnalyticsTests: XCTestCase {
    func testCrashReportingIntegration() {
        // Record a non-fatal error and ensure no exceptions thrown
        let error = NSError(domain: "test.domain", code: 999, userInfo: ["info": "value"])
        XCTAssertNoThrow(CrashReporter.shared.recordError(error, withStackTrace: ["frame1", "frame2"], additionalInfo: ["key": "value"]))
    }

    func testAnalyticsEventTracking() {
        // Record a telemetry event and verify storage
        let telemetry = PredictionTelemetryManager.shared
        let initialCount = telemetry.getRecentEvents().count
        telemetry.recordEvent(type: .predictionStarted)
        let newCount = telemetry.getRecentEvents().count
        XCTAssertGreaterThan(newCount, initialCount, "Telemetry event should be recorded")
    }

    func testRealTimeAlerting() {
        let alertManager = RealTimeAlertManager.shared
        var alertMessage: String?
        let exp = expectation(description: "Alert triggered when threshold exceeded")
        alertManager.setAlertHandler { message in
            alertMessage = message
            exp.fulfill()
        }
        // Trigger failures up to threshold
        for _ in 0..<5 {
            alertManager.recordFailure()
        }
        wait(for: [exp], timeout: 1.0)
        XCTAssertNotNil(alertMessage)
        XCTAssertTrue(alertMessage?.contains("exceeded") ?? false)
    }
} 
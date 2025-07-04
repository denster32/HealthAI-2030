import XCTest
@testable import CardiacHealth

final class HealthKitManagerTests: XCTestCase {
    var manager: HealthKitManager!

    override func setUp() {
        super.setUp()
        manager = HealthKitManager.shared
    }

    func testRequestAuthorizationThrowsIfNoHealthData() async {
        // Skip test if HealthKit is available on this device
        if HKHealthStore.isHealthDataAvailable() {
            try await XCTSkip("Health data available; skipping unavailable path test.")
        }
        await XCTAssertThrowsError(try await manager.requestAuthorization()) { error in
            XCTAssertTrue(error is HKError)
        }
    }

    func testFetchTrendDataReturnsCorrectCount() async throws {
        // Skip if HealthKit not available
        guard HKHealthStore.isHealthDataAvailable() else {
            try await XCTSkip("HealthKit unavailable")
        }
        // Request permission first
        try await manager.requestAuthorization()
        let trends = try await manager.fetchTrendData(days: 3)
        XCTAssertEqual(trends.count, 3)
        // Each trend should have valid date and non-negative values
        trends.forEach { trend in
            XCTAssertGreaterThanOrEqual(trend.restingHeartRate, 0)
            XCTAssertGreaterThanOrEqual(trend.hrv, 0)
        }
    }

    func testGetHealthSummaryReturnsValidSummary() async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            try await XCTSkip("HealthKit unavailable")
        }
        try await manager.requestAuthorization()
        let summary = try await manager.getHealthSummary()
        XCTAssertGreaterThanOrEqual(summary.restingHeartRate, 0)
        XCTAssertGreaterThanOrEqual(summary.hrv, 0)
        XCTAssertTrue(summary.bloodPressure.contains("/"))
    }
}

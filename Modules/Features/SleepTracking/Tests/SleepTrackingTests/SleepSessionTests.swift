import XCTest
@testable import SleepTracking

final class SleepSessionTests: XCTestCase {
    func testWASODuration_andSleepEfficiency() {
        let duration: TimeInterval = 8 * 3600 // 8 hours
        let awakePercentage = 10.0 // 10% awake
        let session = SleepSession(
            startTime: Date(),
            endTime: Date().addingTimeInterval(duration),
            duration: duration,
            deepSleepPercentage: 50.0,
            remSleepPercentage: 20.0,
            lightSleepPercentage: 20.0,
            awakePercentage: awakePercentage,
            trackingMode: .automatic
        )

        // WASO should be 10% of duration
        XCTAssertEqual(session.wasoDuration, duration * awakePercentage / 100, accuracy: 0.1)

        // Sleep efficiency = 1 - waso/duration = 0.90
        XCTAssertEqual(session.sleepEfficiency, 0.9, accuracy: 0.001)
    }
}

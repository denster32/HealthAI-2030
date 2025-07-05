/// Unit tests for SleepFeatureExtractor
import XCTest
@testable import SleepTracking

final class SleepFeatureExtractorTests: XCTestCase {
    func testExtractFeatures_emptyData_returnsEmptyArray() {
        let features = SleepFeatureExtractor.extractFeatures(from: [])
        XCTAssertTrue(features.isEmpty)
    }
    
    func testExtractFeatures_singleDataPoint_returnsValue() {
        let now = Date()
        let data = [SleepDataPoint(timestamp: now, value: 42.0, type: "heartRate")]
        let features = SleepFeatureExtractor.extractFeatures(from: data)
        XCTAssertEqual(features, [42.0])
    }
    
    func testExtractFeatures_multipleDataPoints_returnsFullVector() {
        // Create sample data covering all types
        let now = Date()
        let data: [SleepDataPoint] = [
            SleepDataPoint(timestamp: now, value: 60, type: "heartRate"),
            SleepDataPoint(timestamp: now, value: 62, type: "heartRate"),
            SleepDataPoint(timestamp: now, value: 0.95, type: "oxygenSaturation"),
            SleepDataPoint(timestamp: now, value: 0.90, type: "oxygenSaturation"),
            SleepDataPoint(timestamp: now, value: 36.5, type: "bodyTemperature"),
            SleepDataPoint(timestamp: now, value: 36.7, type: "bodyTemperature"),
            SleepDataPoint(timestamp: now, value: 1.0, type: "accelerometer"),
            SleepDataPoint(timestamp: now, value: 0.5, type: "accelerometer")
        ]
        let features = SleepFeatureExtractor.extractFeatures(from: data)
        // Should return 10 features
        XCTAssertEqual(features.count, 10)
        // RMSSD, SDNN (first two) non-negative
        XCTAssertGreaterThanOrEqual(features[0], 0)
        XCTAssertGreaterThanOrEqual(features[1], 0)
        // Heart rate average should be (60+62)/2 = 61
        XCTAssertEqual(features[2], 61, accuracy: 0.1)
        // Activity count is sum of accel values = 1.5
        XCTAssertEqual(features[6], 1.5, accuracy: 0.001)
        // Sleep wake detection (activity>5? here false) => 0
        XCTAssertEqual(features[7], 0.0)
    }
}
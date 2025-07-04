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
        // TODO: Update this when feature extraction is implemented
        XCTAssertEqual(features, [])
    }
}
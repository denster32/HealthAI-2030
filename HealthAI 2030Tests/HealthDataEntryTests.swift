import XCTest
@testable import HealthAI_2030

private struct DummyData: Codable, Equatable {
    let name: String
    let value: Int
}

final class HealthDataEntryTests: XCTestCase {
    func testDecodedJSON_missingValue_throwsError() {
        let entry = HealthDataEntry(timestamp: Date(), dataType: .steps, value: nil, stringValue: nil, jsonValue: nil, source: "Test", privacyConsentGiven: true)
        XCTAssertThrowsError(try entry.decodedJSON(as: DummyData.self)) { error in
            guard case HealthDataEntry.HealthDataEntryError.jsonValueMissing = error else {
                return XCTFail("Expected jsonValueMissing, got \(error)")
            }
        }
    }

    func testDecodedJSON_invalidData_throwsDecodingFailed() {
        let invalidData = "not json".data(using: .utf8)
        let entry = HealthDataEntry(timestamp: Date(), dataType: .steps, value: nil, stringValue: nil, jsonValue: invalidData, source: "Test", privacyConsentGiven: true)
        XCTAssertThrowsError(try entry.decodedJSON(as: DummyData.self)) { error in
            guard case HealthDataEntry.HealthDataEntryError.jsonDecodingFailed = error else {
                return XCTFail("Expected jsonDecodingFailed, got \(error)")
            }
        }
    }

    func testDecodedJSON_validData_returnsObject() throws {
        let dummy = DummyData(name: "test", value: 123)
        let data = try JSONEncoder().encode(dummy)
        let entry = HealthDataEntry(timestamp: Date(), dataType: .steps, value: nil, stringValue: nil, jsonValue: data, source: "Test", privacyConsentGiven: true)
        let decoded: DummyData = try entry.decodedJSON(as: DummyData.self)
        XCTAssertEqual(decoded, dummy)
    }
}

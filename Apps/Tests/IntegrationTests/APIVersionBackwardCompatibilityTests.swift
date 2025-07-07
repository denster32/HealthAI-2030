import XCTest
import Foundation
import Combine
@testable import HealthAI2030Networking

@available(iOS 18.0, macOS 15.0, *)
final class APIVersionBackwardCompatibilityTests: XCTestCase {

    var cancellables = Set<AnyCancellable>()

    func testV1HealthDataParsing() async throws {
        // Simulate a v1 response JSON for HealthData
        let json = """
        {
            "heartRate": 70,
            "steps": 1000
        }
        """
        let data = Data(json.utf8)

        // Use JSONDecoder to decode v1 fields into current HealthData model
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let healthData = try decoder.decode(HealthData.self, from: data)

        XCTAssertEqual(healthData.heartRate, 70)
        XCTAssertEqual(healthData.steps, 1000)
    }

    func testV2HealthDataParsing() async throws {
        // Simulate a v2 response JSON with nested structure
        let json = """
        {
            "metrics": {
                "heartRate": 75,
                "steps": 1500
            }
        }
        """
        let data = Data(json.utf8)

        // Assuming current model handles metrics container
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let healthData = try decoder.decode(HealthData.self, from: data)

        XCTAssertEqual(healthData.heartRate, 75)
        XCTAssertEqual(healthData.steps, 1500)
    }
} 
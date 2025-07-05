
import XCTest
import Combine
@testable import HealthAI_2030

class AnalyticsEngineTests: XCTestCase {

    private var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        cancellables = []
    }

    override func tearDown() {
        cancellables = nil
        super.tearDown()
    }

    func testProcessHealthData() async throws {
        // Given
        let healthData: [HealthData] = [
            HealthData(value: 1.0),
            HealthData(value: 2.0),
            HealthData(value: 3.0)
        ]
        let dataStream = Just(healthData)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()

        // When
        let analysis = try await AnalyticsEngine.shared.process(dataStream: dataStream)

        // Then
        XCTAssertEqual(analysis.summary, "Processed 3 data points.")
        XCTAssertEqual(analysis.averageValue, 2.0)
    }
}

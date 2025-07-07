import XCTest
@testable import HealthAI2030App

final class QuantumInsightGeneratorTests: XCTestCase {
    func testGenerateInsightsProducesInsights() {
        let generator = QuantumInsightGenerator()
        let insights = generator.generateInsights(from: [0.1, 0.2])
        XCTAssertEqual(insights.count, 2)
        XCTAssertTrue(insights[0].contains("Insight 0"))
        XCTAssertTrue(insights[1].contains("Insight 1"))
    }
} 
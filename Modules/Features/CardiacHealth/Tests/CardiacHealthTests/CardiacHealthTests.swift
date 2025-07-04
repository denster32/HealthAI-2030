import XCTest
import CardiacHealth // Explicitly import the module for all types

final class CardiacHealthDashboardViewModelTests: XCTestCase {
    var viewModel: CardiacHealth.CardiacHealthDashboardViewModel!
    var mockHealthKitManager: MockHealthKitManager!
    var mockECGInsightManager: MockECGInsightManager!

    override func setUp() {
        super.setUp()
        mockHealthKitManager = MockHealthKitManager()
        mockECGInsightManager = MockECGInsightManager()
        viewModel = CardiacHealth.CardiacHealthDashboardViewModel(
            healthKitManager: mockHealthKitManager,
            ecgInsightManager: mockECGInsightManager
        )
    }

    override func tearDown() {
        viewModel = nil
        mockHealthKitManager = nil
        mockECGInsightManager = nil
        super.tearDown()
    }

    func testFetchAllData_populatesProperties() async {
        // Arrange
        mockHealthKitManager.mockSummary = CardiacHealth.CardiacSummary(
            averageHeartRate: 72,
            restingHeartRate: 65,
            hrvScore: 45,
            timestamp: Date()
        )
        mockHealthKitManager.mockTrendData = Array(repeating: CardiacHealth.HeartRateMeasurement(
            value: 72,
            timestamp: Date()
        ), count: 7)
        
        // Act
        await viewModel.fetchAllData()
        
        // Assert
        XCTAssertNotNil(viewModel.summary)
        XCTAssertEqual(viewModel.summary?.averageHeartRate, 72)
        XCTAssertEqual(viewModel.trendData.count, 7)
        XCTAssertNotNil(viewModel.riskAssessment)
        XCTAssertFalse(viewModel.recommendations.isEmpty)
    }
    
    func testFetchAllData_HandlesError() async {
        // Arrange
        mockHealthKitManager.shouldError = true
        
        // Act
        await viewModel.fetchAllData()
        
        // Assert
        XCTAssertNil(viewModel.summary)
        XCTAssertTrue(viewModel.trendData.isEmpty)
        XCTAssertNotNil(viewModel.error)
    }
    
    func testUpdateRiskAssessment_CalculatesCorrectly() async {
        // Arrange
        let insights = [
            CardiacHealth.ECGInsight(type: .afForecast, severity: .critical, message: "High AF Risk", timestamp: Date()),
            CardiacHealth.ECGInsight(type: .stSegment, severity: .warning, message: "ST Elevation", timestamp: Date())
        ]
        mockECGInsightManager.mockInsights = insights
        
        // Act
        await viewModel.updateRiskAssessment()
        
        // Assert
        XCTAssertNotNil(viewModel.riskAssessment)
        XCTAssertEqual(viewModel.riskLevel, CardiacHealth.RiskLevel.high)
        XCTAssertFalse(viewModel.recommendations.isEmpty)
    }
}

// MARK: - Mock Objects
class MockHealthKitManager: CardiacHealth.HealthKitManager {
    var mockSummary: CardiacHealth.CardiacSummary?
    var mockTrendData: [CardiacHealth.HeartRateMeasurement] = []
    var shouldError = false
    
    override func getHealthSummary() async throws -> CardiacHealth.CardiacSummary {
        if shouldError { throw CardiacHealth.CardiacHealthError.dataFetchFailed }
        return mockSummary ?? CardiacHealth.CardiacSummary(averageHeartRate: 0, restingHeartRate: 0, hrvScore: 0, timestamp: Date())
    }
    
    override func fetchTrendData(days: Int) async throws -> [CardiacHealth.CardiacTrendData] {
        if shouldError { throw CardiacHealth.CardiacHealthError.dataFetchFailed }
        return mockTrendData.map { CardiacHealth.CardiacTrendData(date: $0.timestamp, restingHeartRate: Double($0.value), hrv: 0.0) }
    }
}

class MockECGInsightManager: CardiacHealth.ECGInsightManager {
    var mockInsights: [CardiacHealth.ECGInsight] = []
    
    override init() {
        super.init()
    }
    
    override var currentInsights: [CardiacHealth.ECGInsight] {
        get { mockInsights }
        set { mockInsights = newValue }
    }
}
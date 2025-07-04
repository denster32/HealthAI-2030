import XCTest
@testable import CardiacHealth

final class CardiacHealthDashboardViewModelTests: XCTestCase {
    var viewModel: CardiacHealthDashboardViewModel!

    override func setUp() {
        super.setUp()
        viewModel = CardiacHealthDashboardViewModel()
    }

    func testFetchAllData_populatesProperties() async {
        await viewModel.fetchAllData()
        // Summary should be assigned
        XCTAssertNotNil(viewModel.summary)
        // Trend data should have 7 entries
        XCTAssertEqual(viewModel.trendData.count, 7)
        // Risk assessment should not be nil
        XCTAssertNotNil(viewModel.riskAssessment)
        // Recommendations should not be empty
        XCTAssertFalse(viewModel.recommendations.isEmpty)
    }
}
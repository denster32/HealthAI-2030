import XCTest
import Combine
import SwiftUI
@testable import HealthAI2030

/// Advanced Analytics Dashboard Tests
/// Comprehensive test suite for the advanced analytics dashboard functionality
final class AdvancedAnalyticsDashboardTests: XCTestCase {
    
    // MARK: - Properties
    
    var dashboardManager: AdvancedAnalyticsDashboardManager!
    var healthDataManager: MockHealthDataManager!
    var analyticsEngine: MockAnalyticsEngine!
    var mlModelManager: MockMLModelManager!
    var cancellables: Set<AnyCancellable>!
    
    // MARK: - Setup & Teardown
    
    override func setUp() {
        super.setUp()
        healthDataManager = MockHealthDataManager()
        analyticsEngine = MockAnalyticsEngine()
        mlModelManager = MockMLModelManager()
        dashboardManager = AdvancedAnalyticsDashboardManager(
            healthDataManager: healthDataManager,
            analyticsEngine: analyticsEngine,
            mlModelManager: mlModelManager
        )
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDown() {
        dashboardManager = nil
        healthDataManager = nil
        analyticsEngine = nil
        mlModelManager = nil
        cancellables = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testInitialization() {
        // Given: Dashboard manager is initialized
        
        // Then: Default widgets should be set up
        XCTAssertEqual(dashboardManager.dashboardWidgets.count, 4)
        XCTAssertEqual(dashboardManager.selectedTimeRange, .week)
        XCTAssertTrue(dashboardManager.activeFilters.isEmpty)
        XCTAssertEqual(dashboardManager.comparisonMode, .none)
        XCTAssertTrue(dashboardManager.predictiveInsights.isEmpty)
        XCTAssertFalse(dashboardManager.isLoading)
        XCTAssertNil(dashboardManager.errorMessage)
    }
    
    func testDefaultWidgetsSetup() {
        // Given: Dashboard manager is initialized
        
        // Then: Default widgets should have correct types and positions
        let widgetTypes = dashboardManager.dashboardWidgets.map { $0.type }
        XCTAssertTrue(widgetTypes.contains(.healthOverview))
        XCTAssertTrue(widgetTypes.contains(.activityTrends))
        XCTAssertTrue(widgetTypes.contains(.sleepAnalysis))
        XCTAssertTrue(widgetTypes.contains(.predictiveInsights))
        
        // Check widget positions
        let healthOverviewWidget = dashboardManager.dashboardWidgets.first { $0.type == .healthOverview }
        XCTAssertEqual(healthOverviewWidget?.position, CGPoint(x: 0, y: 0))
        XCTAssertEqual(healthOverviewWidget?.size, CGSize(width: 2, height: 1))
    }
    
    // MARK: - Widget Management Tests
    
    func testAddWidget() {
        // Given: Dashboard with default widgets
        let initialCount = dashboardManager.dashboardWidgets.count
        
        // When: Adding a new widget
        dashboardManager.addWidget(type: .custom, title: "Test Widget")
        
        // Then: Widget count should increase
        XCTAssertEqual(dashboardManager.dashboardWidgets.count, initialCount + 1)
        
        // And: New widget should have correct properties
        let newWidget = dashboardManager.dashboardWidgets.last
        XCTAssertEqual(newWidget?.type, .custom)
        XCTAssertEqual(newWidget?.title, "Test Widget")
        XCTAssertEqual(newWidget?.size, CGSize(width: 1, height: 1))
    }
    
    func testRemoveWidget() {
        // Given: Dashboard with widgets
        let initialCount = dashboardManager.dashboardWidgets.count
        let widgetToRemove = dashboardManager.dashboardWidgets.first!
        
        // When: Removing a widget
        dashboardManager.removeWidget(id: widgetToRemove.id)
        
        // Then: Widget count should decrease
        XCTAssertEqual(dashboardManager.dashboardWidgets.count, initialCount - 1)
        
        // And: Widget should not be in the list
        XCTAssertFalse(dashboardManager.dashboardWidgets.contains { $0.id == widgetToRemove.id })
    }
    
    func testUpdateWidgetPosition() {
        // Given: Dashboard with widgets
        let widget = dashboardManager.dashboardWidgets.first!
        let newPosition = CGPoint(x: 5, y: 5)
        let newSize = CGSize(width: 3, height: 2)
        
        // When: Updating widget position and size
        dashboardManager.updateWidget(id: widget.id, position: newPosition, size: newSize)
        
        // Then: Widget should have updated position and size
        let updatedWidget = dashboardManager.dashboardWidgets.first { $0.id == widget.id }
        XCTAssertEqual(updatedWidget?.position, newPosition)
        XCTAssertEqual(updatedWidget?.size, newSize)
    }
    
    func testCalculateNextPosition() {
        // Given: Dashboard with widgets in a grid
        dashboardManager.dashboardWidgets = [
            DashboardWidget(id: "1", type: .healthOverview, title: "Widget 1", position: CGPoint(x: 0, y: 0), size: CGSize(width: 2, height: 1)),
            DashboardWidget(id: "2", type: .activityTrends, title: "Widget 2", position: CGPoint(x: 2, y: 0), size: CGSize(width: 2, height: 1))
        ]
        
        // When: Adding a new widget
        dashboardManager.addWidget(type: .custom, title: "New Widget")
        
        // Then: New widget should be positioned correctly
        let newWidget = dashboardManager.dashboardWidgets.last
        XCTAssertEqual(newWidget?.position, CGPoint(x: 0, y: 1))
    }
    
    // MARK: - Data Fetching Tests
    
    func testFetchHealthOverviewData() async {
        // Given: Mock health data
        let mockHealthMetrics = HealthMetrics(
            overallScore: 85.0,
            trend: 5.2,
            dailyScores: [
                ChartDataPoint(date: Date(), value: 80, label: "Day 1"),
                ChartDataPoint(date: Date().addingTimeInterval(86400), value: 85, label: "Day 2")
            ]
        )
        healthDataManager.mockHealthMetrics = mockHealthMetrics
        
        // When: Fetching health overview data
        let widgetData = await dashboardManager.fetchWidgetData(for: .healthOverview)
        
        // Then: Data should be correctly formatted
        XCTAssertEqual(widgetData.title, "Health Overview")
        XCTAssertEqual(widgetData.primaryValue, 85.0)
        XCTAssertEqual(widgetData.secondaryValue, 5.2)
        XCTAssertEqual(widgetData.chartData.count, 2)
        XCTAssertEqual(widgetData.color, .green)
    }
    
    func testFetchActivityTrendsData() async {
        // Given: Mock activity data
        let mockActivityData = ActivityData(
            averageSteps: 8500,
            trend: 12.5,
            dailySteps: [
                ChartDataPoint(date: Date(), value: 8000, label: "Day 1"),
                ChartDataPoint(date: Date().addingTimeInterval(86400), value: 9000, label: "Day 2")
            ]
        )
        healthDataManager.mockActivityData = mockActivityData
        
        // When: Fetching activity trends data
        let widgetData = await dashboardManager.fetchWidgetData(for: .activityTrends)
        
        // Then: Data should be correctly formatted
        XCTAssertEqual(widgetData.title, "Activity Trends")
        XCTAssertEqual(widgetData.primaryValue, 8500)
        XCTAssertEqual(widgetData.secondaryValue, 12.5)
        XCTAssertEqual(widgetData.chartData.count, 2)
        XCTAssertEqual(widgetData.color, .blue)
    }
    
    func testFetchSleepAnalysisData() async {
        // Given: Mock sleep data
        let mockSleepData = SleepData(
            averageSleepHours: 7.5,
            qualityScore: 85.0,
            dailySleepHours: [
                ChartDataPoint(date: Date(), value: 7.0, label: "Day 1"),
                ChartDataPoint(date: Date().addingTimeInterval(86400), value: 8.0, label: "Day 2")
            ]
        )
        healthDataManager.mockSleepData = mockSleepData
        
        // When: Fetching sleep analysis data
        let widgetData = await dashboardManager.fetchWidgetData(for: .sleepAnalysis)
        
        // Then: Data should be correctly formatted
        XCTAssertEqual(widgetData.title, "Sleep Analysis")
        XCTAssertEqual(widgetData.primaryValue, 7.5)
        XCTAssertEqual(widgetData.secondaryValue, 85.0)
        XCTAssertEqual(widgetData.chartData.count, 2)
        XCTAssertEqual(widgetData.color, .purple)
    }
    
    func testFetchPredictiveInsightsData() async {
        // Given: Mock predictions
        let mockPredictions = Predictions(
            confidence: 92.5,
            trend: 8.3,
            forecastData: [
                ChartDataPoint(date: Date(), value: 90, label: "Day 1"),
                ChartDataPoint(date: Date().addingTimeInterval(86400), value: 95, label: "Day 2")
            ]
        )
        analyticsEngine.mockPredictions = mockPredictions
        
        // When: Fetching predictive insights data
        let widgetData = await dashboardManager.fetchWidgetData(for: .predictiveInsights)
        
        // Then: Data should be correctly formatted
        XCTAssertEqual(widgetData.title, "Predictive Insights")
        XCTAssertEqual(widgetData.primaryValue, 92.5)
        XCTAssertEqual(widgetData.secondaryValue, 8.3)
        XCTAssertEqual(widgetData.chartData.count, 2)
        XCTAssertEqual(widgetData.color, .orange)
    }
    
    // MARK: - Predictive Analytics Tests
    
    func testGeneratePredictiveInsights() async throws {
        // Given: Mock ML predictions
        let mockTrendPrediction = TrendPrediction(
            description: "Health trend improving",
            confidence: 0.85,
            recommendedAction: "Continue current routine"
        )
        let mockRiskAssessment = RiskAssessment(
            description: "Low risk profile",
            confidence: 0.92,
            recommendedAction: "Maintain healthy habits"
        )
        let mockGoalPrediction = GoalPrediction(
            description: "Goal likely to be achieved",
            confidence: 0.78,
            recommendedAction: "Stay consistent"
        )
        
        mlModelManager.mockTrendPrediction = mockTrendPrediction
        mlModelManager.mockRiskAssessment = mockRiskAssessment
        mlModelManager.mockGoalPrediction = mockGoalPrediction
        
        // When: Generating predictive insights
        let insights = try await dashboardManager.generatePredictiveInsights()
        
        // Then: Should have correct number of insights
        XCTAssertEqual(insights.count, 3)
        
        // And: Insights should have correct properties
        let trendInsight = insights.first { $0.type == .healthTrend }
        XCTAssertNotNil(trendInsight)
        XCTAssertEqual(trendInsight?.confidence, 0.85)
        XCTAssertEqual(trendInsight?.timeframe, "7 days")
        
        let riskInsight = insights.first { $0.type == .riskAssessment }
        XCTAssertNotNil(riskInsight)
        XCTAssertEqual(riskInsight?.confidence, 0.92)
        XCTAssertEqual(riskInsight?.timeframe, "30 days")
        
        let goalInsight = insights.first { $0.type == .goalPrediction }
        XCTAssertNotNil(goalInsight)
        XCTAssertEqual(goalInsight?.confidence, 0.78)
        XCTAssertEqual(goalInsight?.timeframe, "90 days")
    }
    
    func testGeneratePredictiveInsightsWithError() async {
        // Given: ML model that throws error
        mlModelManager.shouldThrowError = true
        
        // When & Then: Should handle error gracefully
        do {
            let insights = try await dashboardManager.generatePredictiveInsights()
            XCTFail("Should have thrown an error")
        } catch {
            XCTAssertTrue(error is MockError)
        }
    }
    
    // MARK: - Filtering Tests
    
    func testApplyDateRangeFilter() async {
        // Given: Widget data with chart data
        let originalData = WidgetData(
            title: "Test",
            subtitle: "Test",
            primaryValue: 100,
            secondaryValue: 50,
            chartData: [
                ChartDataPoint(date: Date().addingTimeInterval(-86400), value: 80, label: "Yesterday"),
                ChartDataPoint(date: Date(), value: 100, label: "Today"),
                ChartDataPoint(date: Date().addingTimeInterval(86400), value: 120, label: "Tomorrow")
            ],
            color: .blue
        )
        
        let dateRange = Date()...Date().addingTimeInterval(86400)
        let dateFilter = DateRangeFilter(name: "Date Range", dateRange: dateRange)
        
        // When: Applying date range filter
        let filteredData = await dashboardManager.applyFiltersToWidget(originalData, filters: [dateFilter])
        
        // Then: Should filter data correctly
        XCTAssertEqual(filteredData.chartData.count, 2) // Today and Tomorrow
        XCTAssertEqual(filteredData.chartData.first?.label, "Today")
        XCTAssertEqual(filteredData.chartData.last?.label, "Tomorrow")
    }
    
    func testApplyValueRangeFilter() async {
        // Given: Widget data with chart data
        let originalData = WidgetData(
            title: "Test",
            subtitle: "Test",
            primaryValue: 100,
            secondaryValue: 50,
            chartData: [
                ChartDataPoint(date: Date(), value: 80, label: "Low"),
                ChartDataPoint(date: Date(), value: 100, label: "Medium"),
                ChartDataPoint(date: Date(), value: 120, label: "High")
            ],
            color: .blue
        )
        
        let valueRange = 90.0...110.0
        let valueFilter = ValueRangeFilter(name: "Value Range", range: valueRange)
        
        // When: Applying value range filter
        let filteredData = await dashboardManager.applyFiltersToWidget(originalData, filters: [valueFilter])
        
        // Then: Should filter data correctly
        XCTAssertEqual(filteredData.chartData.count, 1) // Only Medium (100)
        XCTAssertEqual(filteredData.chartData.first?.label, "Medium")
    }
    
    func testApplyMultipleFilters() async {
        // Given: Widget data and multiple filters
        let originalData = WidgetData(
            title: "Test",
            subtitle: "Test",
            primaryValue: 100,
            secondaryValue: 50,
            chartData: [
                ChartDataPoint(date: Date(), value: 100, label: "Today"),
                ChartDataPoint(date: Date().addingTimeInterval(86400), value: 120, label: "Tomorrow")
            ],
            color: .blue
        )
        
        let dateRange = Date()...Date().addingTimeInterval(86400)
        let dateFilter = DateRangeFilter(name: "Date Range", dateRange: dateRange)
        let valueRange = 90.0...110.0
        let valueFilter = ValueRangeFilter(name: "Value Range", range: valueRange)
        
        // When: Applying multiple filters
        let filteredData = await dashboardManager.applyFiltersToWidget(originalData, filters: [dateFilter, valueFilter])
        
        // Then: Should apply both filters
        XCTAssertEqual(filteredData.chartData.count, 1) // Only Today (100, within date and value range)
        XCTAssertEqual(filteredData.chartData.first?.label, "Today")
    }
    
    // MARK: - Export Tests
    
    func testExportDashboardAsCSV() async {
        // Given: Dashboard with widgets
        dashboardManager.dashboardWidgets = [
            DashboardWidget(
                id: "1",
                type: .healthOverview,
                title: "Health Overview",
                position: CGPoint(x: 0, y: 0),
                size: CGSize(width: 2, height: 1),
                data: WidgetData(
                    title: "Health Overview",
                    subtitle: "Last 7 Days",
                    primaryValue: 85.0,
                    secondaryValue: 5.2,
                    chartData: [],
                    color: .green
                )
            )
        ]
        
        // When: Exporting as CSV
        let csvData = await dashboardManager.exportDashboardAsCSV()
        
        // Then: Should generate valid CSV
        XCTAssertTrue(csvData.contains("Widget,Title,Primary Value,Secondary Value,Date"))
        XCTAssertTrue(csvData.contains("health_overview,Health Overview,85.0,5.2"))
    }
    
    func testExportDashboardAsJSON() async {
        // Given: Dashboard with widgets
        dashboardManager.dashboardWidgets = [
            DashboardWidget(
                id: "1",
                type: .healthOverview,
                title: "Health Overview",
                position: CGPoint(x: 0, y: 0),
                size: CGSize(width: 2, height: 1)
            )
        ]
        dashboardManager.selectedTimeRange = .week
        
        // When: Exporting as JSON
        let jsonData = await dashboardManager.exportDashboardAsJSON()
        
        // Then: Should generate valid JSON
        XCTAssertNotNil(jsonData)
        
        // And: Should be decodable
        do {
            let exportData = try JSONDecoder().decode(DashboardExportData.self, from: jsonData!)
            XCTAssertEqual(exportData.widgets.count, 1)
            XCTAssertEqual(exportData.timeRange, .week)
        } catch {
            XCTFail("Failed to decode exported JSON: \(error)")
        }
    }
    
    // MARK: - Persistence Tests
    
    func testSaveAndLoadDashboardLayout() {
        // Given: Dashboard with custom layout
        dashboardManager.dashboardWidgets = [
            DashboardWidget(
                id: "custom-1",
                type: .custom,
                title: "Custom Widget",
                position: CGPoint(x: 1, y: 1),
                size: CGSize(width: 2, height: 2)
            )
        ]
        dashboardManager.selectedTimeRange = .month
        dashboardManager.activeFilters = [
            DateRangeFilter(name: "Test Filter", dateRange: Date()...Date())
        ]
        
        // When: Saving and loading layout
        dashboardManager.saveDashboardLayout()
        
        // Create new manager to test loading
        let newManager = AdvancedAnalyticsDashboardManager(
            healthDataManager: healthDataManager,
            analyticsEngine: analyticsEngine,
            mlModelManager: mlModelManager
        )
        newManager.loadDashboardLayout()
        
        // Then: Layout should be restored
        XCTAssertEqual(newManager.dashboardWidgets.count, 1)
        XCTAssertEqual(newManager.dashboardWidgets.first?.title, "Custom Widget")
        XCTAssertEqual(newManager.selectedTimeRange, .month)
        XCTAssertEqual(newManager.activeFilters.count, 1)
    }
    
    // MARK: - Performance Tests
    
    func testRefreshDashboardPerformance() {
        // Given: Dashboard with multiple widgets
        
        // When: Refreshing dashboard
        let expectation = XCTestExpectation(description: "Dashboard refresh completed")
        
        dashboardManager.refreshDashboard()
        
        // Wait for async operations
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        
        // Then: Should complete within reasonable time
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testWidgetDataUpdatePerformance() async {
        // Given: Dashboard with multiple widgets
        for _ in 0..<10 {
            dashboardManager.addWidget(type: .custom, title: "Performance Test Widget")
        }
        
        // When: Updating all widget data
        let startTime = CFAbsoluteTimeGetCurrent()
        await dashboardManager.updateWidgetData()
        let endTime = CFAbsoluteTimeGetCurrent()
        
        // Then: Should complete within reasonable time
        let duration = endTime - startTime
        XCTAssertLessThan(duration, 1.0, "Widget data update took too long: \(duration)s")
    }
    
    // MARK: - Error Handling Tests
    
    func testErrorHandlingInRefreshDashboard() {
        // Given: Health data manager that throws error
        healthDataManager.shouldThrowError = true
        
        // When: Refreshing dashboard
        let expectation = XCTestExpectation(description: "Error handling")
        
        dashboardManager.$errorMessage
            .dropFirst()
            .sink { errorMessage in
                XCTAssertNotNil(errorMessage)
                XCTAssertTrue(errorMessage?.contains("Failed to refresh dashboard") ?? false)
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        dashboardManager.refreshDashboard()
        
        // Then: Should handle error gracefully
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testErrorHandlingInPredictiveInsights() async {
        // Given: ML model that throws error
        mlModelManager.shouldThrowError = true
        
        // When: Updating predictive insights
        let expectation = XCTestExpectation(description: "Predictive insights error handling")
        
        dashboardManager.$errorMessage
            .dropFirst()
            .sink { errorMessage in
                XCTAssertNotNil(errorMessage)
                XCTAssertTrue(errorMessage?.contains("Failed to generate predictive insights") ?? false)
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        await dashboardManager.updatePredictiveInsights()
        
        // Then: Should handle error gracefully
        wait(for: [expectation], timeout: 1.0)
    }
    
    // MARK: - Time Range Tests
    
    func testTimeRangeSelection() {
        // Given: Dashboard with default time range
        XCTAssertEqual(dashboardManager.selectedTimeRange, .week)
        
        // When: Changing time range
        dashboardManager.selectedTimeRange = .month
        
        // Then: Time range should be updated
        XCTAssertEqual(dashboardManager.selectedTimeRange, .month)
    }
    
    func testTimeRangeDisplayNames() {
        // Given: All time ranges
        let timeRanges: [TimeRange] = [.day, .week, .month, .quarter, .year]
        let expectedNames = ["24 Hours", "7 Days", "30 Days", "90 Days", "365 Days"]
        
        // Then: Display names should be correct
        for (index, timeRange) in timeRanges.enumerated() {
            XCTAssertEqual(timeRange.displayName, expectedNames[index])
        }
    }
    
    // MARK: - Comparison Mode Tests
    
    func testComparisonModeSelection() {
        // Given: Dashboard with default comparison mode
        XCTAssertEqual(dashboardManager.comparisonMode, .none)
        
        // When: Changing comparison mode
        dashboardManager.comparisonMode = .periodOverPeriod
        
        // Then: Comparison mode should be updated
        XCTAssertEqual(dashboardManager.comparisonMode, .periodOverPeriod)
    }
    
    func testComparisonModeDisplayNames() {
        // Given: All comparison modes
        let comparisonModes: [ComparisonMode] = [.none, .periodOverPeriod, .goalVsActual, .peerGroup, .historical]
        let expectedNames = ["None", "Period over Period", "Goal vs Actual", "Peer Group", "Historical"]
        
        // Then: Display names should be correct
        for (index, mode) in comparisonModes.enumerated() {
            XCTAssertEqual(mode.displayName, expectedNames[index])
        }
    }
    
    // MARK: - Widget Type Tests
    
    func testWidgetTypeDisplayNames() {
        // Given: All widget types
        let widgetTypes: [WidgetType] = [.healthOverview, .activityTrends, .sleepAnalysis, .predictiveInsights, .custom]
        let expectedNames = ["Health Overview", "Activity Trends", "Sleep Analysis", "Predictive Insights", "Custom Widget"]
        
        // Then: Display names should be correct
        for (index, type) in widgetTypes.enumerated() {
            XCTAssertEqual(type.displayName, expectedNames[index])
        }
    }
    
    // MARK: - Filter Tests
    
    func testFilterTypes() {
        // Given: Different filter types
        let dateFilter = DateRangeFilter(name: "Date", dateRange: Date()...Date())
        let metricFilter = HealthMetricFilter(name: "Metric", metric: .heartRate)
        let valueFilter = ValueRangeFilter(name: "Value", range: 0...100)
        
        // Then: Filter types should be correct
        XCTAssertEqual(dateFilter.type, .dateRange)
        XCTAssertEqual(metricFilter.type, .healthMetric)
        XCTAssertEqual(valueFilter.type, .valueRange)
    }
    
    func testHealthMetricTypes() {
        // Given: All health metrics
        let metrics: [HealthMetric] = [.heartRate, .steps, .sleep, .activity, .weight, .bloodPressure]
        let expectedNames = ["heart_rate", "steps", "sleep", "activity", "weight", "blood_pressure"]
        
        // Then: Raw values should be correct
        for (index, metric) in metrics.enumerated() {
            XCTAssertEqual(metric.rawValue, expectedNames[index])
        }
    }
}

// MARK: - Mock Types

class MockHealthDataManager: HealthDataManager {
    var mockHealthMetrics: HealthMetrics?
    var mockActivityData: ActivityData?
    var mockSleepData: SleepData?
    var shouldThrowError = false
    
    override func getHealthMetrics(for timeRange: TimeRange) async -> HealthMetrics {
        if shouldThrowError {
            fatalError("Mock error")
        }
        return mockHealthMetrics ?? HealthMetrics(overallScore: 0, trend: 0, dailyScores: [])
    }
    
    override func getActivityData(for timeRange: TimeRange) async -> ActivityData {
        if shouldThrowError {
            fatalError("Mock error")
        }
        return mockActivityData ?? ActivityData(averageSteps: 0, trend: 0, dailySteps: [])
    }
    
    override func getSleepData(for timeRange: TimeRange) async -> SleepData {
        if shouldThrowError {
            fatalError("Mock error")
        }
        return mockSleepData ?? SleepData(averageSleepHours: 0, qualityScore: 0, dailySleepHours: [])
    }
}

class MockAnalyticsEngine: AnalyticsEngine {
    var mockPredictions: Predictions?
    var shouldThrowError = false
    
    override func getPredictions(for timeRange: TimeRange) async -> Predictions {
        if shouldThrowError {
            fatalError("Mock error")
        }
        return mockPredictions ?? Predictions(confidence: 0, trend: 0, forecastData: [])
    }
}

class MockMLModelManager: MLModelManager {
    var mockTrendPrediction: TrendPrediction?
    var mockRiskAssessment: RiskAssessment?
    var mockGoalPrediction: GoalPrediction?
    var shouldThrowError = false
    
    override func predictHealthTrend(from healthData: HealthData) async throws -> TrendPrediction? {
        if shouldThrowError {
            throw MockError.testError
        }
        return mockTrendPrediction
    }
    
    override func assessHealthRisk(from healthData: HealthData) async throws -> RiskAssessment? {
        if shouldThrowError {
            throw MockError.testError
        }
        return mockRiskAssessment
    }
    
    override func predictGoalAchievement(from healthData: HealthData) async throws -> GoalPrediction? {
        if shouldThrowError {
            throw MockError.testError
        }
        return mockGoalPrediction
    }
}

// MARK: - Supporting Types

struct HealthMetrics {
    let overallScore: Double
    let trend: Double
    let dailyScores: [ChartDataPoint]
}

struct ActivityData {
    let averageSteps: Double
    let trend: Double
    let dailySteps: [ChartDataPoint]
}

struct SleepData {
    let averageSleepHours: Double
    let qualityScore: Double
    let dailySleepHours: [ChartDataPoint]
}

struct Predictions {
    let confidence: Double
    let trend: Double
    let forecastData: [ChartDataPoint]
}

struct TrendPrediction {
    let description: String
    let confidence: Double
    let recommendedAction: String
}

struct RiskAssessment {
    let description: String
    let confidence: Double
    let recommendedAction: String
}

struct GoalPrediction {
    let description: String
    let confidence: Double
    let recommendedAction: String
}

struct HealthData {
    // Mock health data structure
}

enum MockError: Error {
    case testError
}

// MARK: - Extensions for Testing

extension AdvancedAnalyticsDashboardManager {
    func fetchWidgetData(for widgetType: WidgetType) async -> WidgetData {
        switch widgetType {
        case .healthOverview:
            return await fetchHealthOverviewData()
        case .activityTrends:
            return await fetchActivityTrendsData()
        case .sleepAnalysis:
            return await fetchSleepAnalysisData()
        case .predictiveInsights:
            return await fetchPredictiveInsightsData()
        case .custom:
            return WidgetData.empty
        }
    }
    
    func generatePredictiveInsights() async throws -> [PredictiveInsight] {
        let healthData = HealthData()
        
        var insights: [PredictiveInsight] = []
        
        // Health trend prediction
        if let trendPrediction = try await mlModelManager.predictHealthTrend(from: healthData) {
            insights.append(PredictiveInsight(
                type: .healthTrend,
                title: "Health Trend Forecast",
                description: trendPrediction.description,
                confidence: trendPrediction.confidence,
                timeframe: "7 days",
                action: trendPrediction.recommendedAction
            ))
        }
        
        // Risk assessment
        if let riskAssessment = try await mlModelManager.assessHealthRisk(from: healthData) {
            insights.append(PredictiveInsight(
                type: .riskAssessment,
                title: "Health Risk Assessment",
                description: riskAssessment.description,
                confidence: riskAssessment.confidence,
                timeframe: "30 days",
                action: riskAssessment.recommendedAction
            ))
        }
        
        // Goal achievement prediction
        if let goalPrediction = try await mlModelManager.predictGoalAchievement(from: healthData) {
            insights.append(PredictiveInsight(
                type: .goalPrediction,
                title: "Goal Achievement Forecast",
                description: goalPrediction.description,
                confidence: goalPrediction.confidence,
                timeframe: "90 days",
                action: goalPrediction.recommendedAction
            ))
        }
        
        return insights
    }
    
    func applyFiltersToWidget(_ data: WidgetData, filters: [AnalyticsFilter]) async -> WidgetData {
        var filteredData = data
        
        for filter in filters {
            switch filter.type {
            case .dateRange:
                if let dateFilter = filter as? DateRangeFilter {
                    filteredData = await filterDataByDateRange(filteredData, range: dateFilter.dateRange)
                }
            case .healthMetric:
                if let metricFilter = filter as? HealthMetricFilter {
                    filteredData = await filterDataByHealthMetric(filteredData, metric: metricFilter.metric)
                }
            case .valueRange:
                if let valueFilter = filter as? ValueRangeFilter {
                    filteredData = await filterDataByValueRange(filteredData, range: valueFilter.range)
                }
            }
        }
        
        return filteredData
    }
    
    func filterDataByDateRange(_ data: WidgetData, range: ClosedRange<Date>) async -> WidgetData {
        let filteredChartData = data.chartData.filter { dataPoint in
            range.contains(dataPoint.date)
        }
        
        return WidgetData(
            title: data.title,
            subtitle: data.subtitle,
            primaryValue: data.primaryValue,
            secondaryValue: data.secondaryValue,
            chartData: filteredChartData,
            color: data.color
        )
    }
    
    func filterDataByHealthMetric(_ data: WidgetData, metric: HealthMetric) async -> WidgetData {
        // Apply metric-specific filtering logic
        return data
    }
    
    func filterDataByValueRange(_ data: WidgetData, range: ClosedRange<Double>) async -> WidgetData {
        let filteredChartData = data.chartData.filter { dataPoint in
            range.contains(dataPoint.value)
        }
        
        return WidgetData(
            title: data.title,
            subtitle: data.subtitle,
            primaryValue: data.primaryValue,
            secondaryValue: data.secondaryValue,
            chartData: filteredChartData,
            color: data.color
        )
    }
} 
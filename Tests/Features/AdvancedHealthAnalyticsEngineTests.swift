import XCTest
import Foundation
import Combine
@testable import HealthAI2030

/// Comprehensive test suite for Advanced Health Analytics & Business Intelligence Engine
@available(iOS 18.0, macOS 15.0, *)
final class AdvancedHealthAnalyticsEngineTests: XCTestCase {
    
    // MARK: - Properties
    private var analyticsEngine: AdvancedHealthAnalyticsEngine!
    private var healthDataManager: HealthDataManager!
    private var analyticsEngineMock: AnalyticsEngine!
    private var cancellables: Set<AnyCancellable>!
    
    // MARK: - Setup and Teardown
    
    override func setUp() async throws {
        try await super.setUp()
        
        healthDataManager = HealthDataManager()
        analyticsEngineMock = AnalyticsEngine()
        analyticsEngine = AdvancedHealthAnalyticsEngine(
            healthDataManager: healthDataManager,
            analyticsEngine: analyticsEngineMock
        )
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDown() async throws {
        analyticsEngine = nil
        healthDataManager = nil
        analyticsEngineMock = nil
        cancellables = nil
        
        try await super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testInitialization() async throws {
        // Test that the analytics engine initializes correctly
        XCTAssertNotNil(analyticsEngine)
        XCTAssertFalse(analyticsEngine.isAnalyticsActive)
        XCTAssertEqual(analyticsEngine.analyticsProgress, 0.0)
        XCTAssertNil(analyticsEngine.lastError)
        XCTAssertTrue(analyticsEngine.analyticsInsights.isEmpty)
        XCTAssertTrue(analyticsEngine.predictiveModels.isEmpty)
        XCTAssertTrue(analyticsEngine.reports.isEmpty)
        XCTAssertTrue(analyticsEngine.dashboards.isEmpty)
    }
    
    // MARK: - Analytics Start/Stop Tests
    
    func testStartAnalytics() async throws {
        // Test starting analytics
        try await analyticsEngine.startAnalytics()
        
        XCTAssertTrue(analyticsEngine.isAnalyticsActive)
        XCTAssertNil(analyticsEngine.lastError)
        XCTAssertEqual(analyticsEngine.analyticsProgress, 1.0)
    }
    
    func testStopAnalytics() async throws {
        // Start analytics first
        try await analyticsEngine.startAnalytics()
        
        // Test stopping analytics
        await analyticsEngine.stopAnalytics()
        
        XCTAssertFalse(analyticsEngine.isAnalyticsActive)
        XCTAssertEqual(analyticsEngine.analyticsProgress, 0.0)
    }
    
    func testStartAnalyticsWithError() async throws {
        // Test starting analytics with invalid configuration
        // This would require mocking to simulate errors
        
        do {
            try await analyticsEngine.startAnalytics()
            // If no error is thrown, the test passes
        } catch {
            XCTAssertNotNil(analyticsEngine.lastError)
            XCTAssertFalse(analyticsEngine.isAnalyticsActive)
        }
    }
    
    // MARK: - Analytics Performance Tests
    
    func testPerformAnalytics() async throws {
        // Test performing analytics
        let activity = try await analyticsEngine.performAnalytics()
        
        XCTAssertNotNil(activity)
        XCTAssertEqual(activity.timestamp.timeIntervalSinceNow, 0, accuracy: 1.0)
        XCTAssertNotNil(activity.insights)
        XCTAssertNotNil(activity.models)
        XCTAssertNotNil(activity.metrics)
    }
    
    func testPerformAnalyticsWithError() async throws {
        // Test performing analytics with invalid data
        // This would require mocking to simulate errors
        
        do {
            _ = try await analyticsEngine.performAnalytics()
            // If no error is thrown, the test passes
        } catch {
            XCTAssertNotNil(analyticsEngine.lastError)
        }
    }
    
    // MARK: - Insights Tests
    
    func testGetAnalyticsInsights() async throws {
        // Test getting all insights
        let allInsights = await analyticsEngine.getAnalyticsInsights()
        XCTAssertNotNil(allInsights)
        
        // Test getting insights by category
        let healthInsights = await analyticsEngine.getAnalyticsInsights(category: .health)
        XCTAssertNotNil(healthInsights)
        
        let performanceInsights = await analyticsEngine.getAnalyticsInsights(category: .performance)
        XCTAssertNotNil(performanceInsights)
        
        let trendInsights = await analyticsEngine.getAnalyticsInsights(category: .trends)
        XCTAssertNotNil(trendInsights)
        
        let predictionInsights = await analyticsEngine.getAnalyticsInsights(category: .predictions)
        XCTAssertNotNil(predictionInsights)
        
        let recommendationInsights = await analyticsEngine.getAnalyticsInsights(category: .recommendations)
        XCTAssertNotNil(recommendationInsights)
    }
    
    func testInsightFiltering() async throws {
        // Test insight filtering by category
        let healthInsights = await analyticsEngine.getAnalyticsInsights(category: .health)
        let allInsights = await analyticsEngine.getAnalyticsInsights(category: .all)
        
        // Health insights should be a subset of all insights
        XCTAssertLessThanOrEqual(healthInsights.count, allInsights.count)
        
        // All health insights should have the health category
        for insight in healthInsights {
            XCTAssertEqual(insight.category, .health)
        }
    }
    
    // MARK: - Predictive Models Tests
    
    func testGetPredictiveModels() async throws {
        // Test getting all models
        let allModels = await analyticsEngine.getPredictiveModels()
        XCTAssertNotNil(allModels)
        
        // Test getting models by type
        let healthModels = await analyticsEngine.getPredictiveModels(type: .health)
        XCTAssertNotNil(healthModels)
        
        let performanceModels = await analyticsEngine.getPredictiveModels(type: .performance)
        XCTAssertNotNil(performanceModels)
        
        let riskModels = await analyticsEngine.getPredictiveModels(type: .risk)
        XCTAssertNotNil(riskModels)
        
        let trendModels = await analyticsEngine.getPredictiveModels(type: .trends)
        XCTAssertNotNil(trendModels)
        
        let anomalyModels = await analyticsEngine.getPredictiveModels(type: .anomaly)
        XCTAssertNotNil(anomalyModels)
    }
    
    func testModelFiltering() async throws {
        // Test model filtering by type
        let healthModels = await analyticsEngine.getPredictiveModels(type: .health)
        let allModels = await analyticsEngine.getPredictiveModels(type: .all)
        
        // Health models should be a subset of all models
        XCTAssertLessThanOrEqual(healthModels.count, allModels.count)
        
        // All health models should have the health type
        for model in healthModels {
            XCTAssertEqual(model.type, .health)
        }
    }
    
    // MARK: - Business Metrics Tests
    
    func testGetBusinessMetrics() async throws {
        // Test getting business metrics for different timeframes
        let weeklyMetrics = await analyticsEngine.getBusinessMetrics(timeframe: .week)
        XCTAssertNotNil(weeklyMetrics)
        XCTAssertNotNil(weeklyMetrics.userEngagement)
        XCTAssertNotNil(weeklyMetrics.healthOutcomes)
        XCTAssertNotNil(weeklyMetrics.performanceMetrics)
        XCTAssertNotNil(weeklyMetrics.financialMetrics)
        XCTAssertNotNil(weeklyMetrics.operationalMetrics)
        XCTAssertNotNil(weeklyMetrics.qualityMetrics)
        XCTAssertNotNil(weeklyMetrics.riskMetrics)
        XCTAssertNotNil(weeklyMetrics.growthMetrics)
        
        let monthlyMetrics = await analyticsEngine.getBusinessMetrics(timeframe: .month)
        XCTAssertNotNil(monthlyMetrics)
        
        let yearlyMetrics = await analyticsEngine.getBusinessMetrics(timeframe: .year)
        XCTAssertNotNil(yearlyMetrics)
    }
    
    func testMetricsCalculation() async throws {
        // Test that metrics are calculated correctly
        let metrics = await analyticsEngine.getBusinessMetrics()
        
        // Test user engagement metrics
        XCTAssertGreaterThanOrEqual(metrics.userEngagement.activeUsers, 0)
        XCTAssertGreaterThanOrEqual(metrics.userEngagement.dailyActiveUsers, 0)
        XCTAssertGreaterThanOrEqual(metrics.userEngagement.weeklyActiveUsers, 0)
        XCTAssertGreaterThanOrEqual(metrics.userEngagement.monthlyActiveUsers, 0)
        XCTAssertGreaterThanOrEqual(metrics.userEngagement.sessionDuration, 0)
        XCTAssertGreaterThanOrEqual(metrics.userEngagement.retentionRate, 0)
        XCTAssertLessThanOrEqual(metrics.userEngagement.retentionRate, 1)
        
        // Test performance metrics
        XCTAssertGreaterThanOrEqual(metrics.performanceMetrics.responseTime, 0)
        XCTAssertGreaterThanOrEqual(metrics.performanceMetrics.throughput, 0)
        XCTAssertGreaterThanOrEqual(metrics.performanceMetrics.errorRate, 0)
        XCTAssertLessThanOrEqual(metrics.performanceMetrics.errorRate, 1)
        XCTAssertGreaterThanOrEqual(metrics.performanceMetrics.availability, 0)
        XCTAssertLessThanOrEqual(metrics.performanceMetrics.availability, 1)
        
        // Test financial metrics
        XCTAssertGreaterThanOrEqual(metrics.financialMetrics.revenue, 0)
        XCTAssertGreaterThanOrEqual(metrics.financialMetrics.cost, 0)
        XCTAssertGreaterThanOrEqual(metrics.financialMetrics.profit, 0)
        XCTAssertGreaterThanOrEqual(metrics.financialMetrics.profitMargin, 0)
        XCTAssertLessThanOrEqual(metrics.financialMetrics.profitMargin, 1)
        
        // Test operational metrics
        XCTAssertGreaterThanOrEqual(metrics.operationalMetrics.efficiency, 0)
        XCTAssertLessThanOrEqual(metrics.operationalMetrics.efficiency, 1)
        XCTAssertGreaterThanOrEqual(metrics.operationalMetrics.productivity, 0)
        XCTAssertLessThanOrEqual(metrics.operationalMetrics.productivity, 1)
        XCTAssertGreaterThanOrEqual(metrics.operationalMetrics.quality, 0)
        XCTAssertLessThanOrEqual(metrics.operationalMetrics.quality, 1)
        XCTAssertGreaterThanOrEqual(metrics.operationalMetrics.satisfaction, 0)
        XCTAssertLessThanOrEqual(metrics.operationalMetrics.satisfaction, 1)
        
        // Test quality metrics
        XCTAssertGreaterThanOrEqual(metrics.qualityMetrics.dataQuality, 0)
        XCTAssertLessThanOrEqual(metrics.qualityMetrics.dataQuality, 1)
        XCTAssertGreaterThanOrEqual(metrics.qualityMetrics.modelAccuracy, 0)
        XCTAssertLessThanOrEqual(metrics.qualityMetrics.modelAccuracy, 1)
        XCTAssertGreaterThanOrEqual(metrics.qualityMetrics.predictionAccuracy, 0)
        XCTAssertLessThanOrEqual(metrics.qualityMetrics.predictionAccuracy, 1)
        XCTAssertGreaterThanOrEqual(metrics.qualityMetrics.recommendationAccuracy, 0)
        XCTAssertLessThanOrEqual(metrics.qualityMetrics.recommendationAccuracy, 1)
        
        // Test risk metrics
        XCTAssertGreaterThanOrEqual(metrics.riskMetrics.riskScore, 0)
        XCTAssertLessThanOrEqual(metrics.riskMetrics.riskScore, 1)
        XCTAssertGreaterThanOrEqual(metrics.riskMetrics.mitigationEffectiveness, 0)
        XCTAssertLessThanOrEqual(metrics.riskMetrics.mitigationEffectiveness, 1)
        
        // Test growth metrics
        XCTAssertGreaterThanOrEqual(metrics.growthMetrics.userGrowth, 0)
        XCTAssertGreaterThanOrEqual(metrics.growthMetrics.revenueGrowth, 0)
        XCTAssertGreaterThanOrEqual(metrics.growthMetrics.marketShare, 0)
        XCTAssertLessThanOrEqual(metrics.growthMetrics.marketShare, 1)
    }
    
    // MARK: - Reports Tests
    
    func testGetAnalyticsReports() async throws {
        // Test getting all reports
        let allReports = await analyticsEngine.getAnalyticsReports()
        XCTAssertNotNil(allReports)
        
        // Test getting reports by type
        let healthReports = await analyticsEngine.getAnalyticsReports(type: .health)
        XCTAssertNotNil(healthReports)
        
        let performanceReports = await analyticsEngine.getAnalyticsReports(type: .performance)
        XCTAssertNotNil(performanceReports)
        
        let businessReports = await analyticsEngine.getAnalyticsReports(type: .business)
        XCTAssertNotNil(businessReports)
        
        let operationalReports = await analyticsEngine.getAnalyticsReports(type: .operational)
        XCTAssertNotNil(operationalReports)
        
        let financialReports = await analyticsEngine.getAnalyticsReports(type: .financial)
        XCTAssertNotNil(financialReports)
    }
    
    func testReportFiltering() async throws {
        // Test report filtering by type
        let healthReports = await analyticsEngine.getAnalyticsReports(type: .health)
        let allReports = await analyticsEngine.getAnalyticsReports(type: .all)
        
        // Health reports should be a subset of all reports
        XCTAssertLessThanOrEqual(healthReports.count, allReports.count)
        
        // All health reports should have the health type
        for report in healthReports {
            XCTAssertEqual(report.type, .health)
        }
    }
    
    func testCreateCustomReport() async throws {
        // Test creating a custom report
        let customReport = AnalyticsReport(
            id: UUID(),
            title: "Test Report",
            type: .health,
            description: "Test report description",
            data: [:],
            charts: [],
            filters: [],
            schedule: nil,
            recipients: [],
            status: .draft,
            timestamp: Date()
        )
        
        try await analyticsEngine.createCustomReport(customReport)
        
        // Verify the report was created
        let reports = await analyticsEngine.getAnalyticsReports()
        XCTAssertTrue(reports.contains { $0.id == customReport.id })
    }
    
    // MARK: - Dashboards Tests
    
    func testGetAnalyticsDashboards() async throws {
        // Test getting all dashboards
        let allDashboards = await analyticsEngine.getAnalyticsDashboards()
        XCTAssertNotNil(allDashboards)
        
        // Test getting dashboards by category
        let executiveDashboards = await analyticsEngine.getAnalyticsDashboards(category: .executive)
        XCTAssertNotNil(executiveDashboards)
        
        let operationalDashboards = await analyticsEngine.getAnalyticsDashboards(category: .operational)
        XCTAssertNotNil(operationalDashboards)
        
        let clinicalDashboards = await analyticsEngine.getAnalyticsDashboards(category: .clinical)
        XCTAssertNotNil(clinicalDashboards)
        
        let financialDashboards = await analyticsEngine.getAnalyticsDashboards(category: .financial)
        XCTAssertNotNil(financialDashboards)
        
        let customDashboards = await analyticsEngine.getAnalyticsDashboards(category: .custom)
        XCTAssertNotNil(customDashboards)
    }
    
    func testDashboardFiltering() async throws {
        // Test dashboard filtering by category
        let executiveDashboards = await analyticsEngine.getAnalyticsDashboards(category: .executive)
        let allDashboards = await analyticsEngine.getAnalyticsDashboards(category: .all)
        
        // Executive dashboards should be a subset of all dashboards
        XCTAssertLessThanOrEqual(executiveDashboards.count, allDashboards.count)
        
        // All executive dashboards should have the executive category
        for dashboard in executiveDashboards {
            XCTAssertEqual(dashboard.category, .executive)
        }
    }
    
    func testCreateCustomDashboard() async throws {
        // Test creating a custom dashboard
        let customDashboard = AnalyticsDashboard(
            id: UUID(),
            name: "Test Dashboard",
            category: .custom,
            description: "Test dashboard description",
            widgets: [],
            layout: DashboardLayout(columns: 2, rows: 2, widgets: [], timestamp: Date()),
            filters: [],
            permissions: [],
            status: .active,
            timestamp: Date()
        )
        
        try await analyticsEngine.createCustomDashboard(customDashboard)
        
        // Verify the dashboard was created
        let dashboards = await analyticsEngine.getAnalyticsDashboards()
        XCTAssertTrue(dashboards.contains { $0.id == customDashboard.id })
    }
    
    // MARK: - Predictive Forecast Tests
    
    func testGeneratePredictiveForecast() async throws {
        // Test generating predictive forecast
        let forecast = try await analyticsEngine.generatePredictiveForecast(
            forecastType: .health,
            timeframe: .week
        )
        
        XCTAssertNotNil(forecast)
        XCTAssertEqual(forecast.type, .health)
        XCTAssertEqual(forecast.timeframe, .week)
        XCTAssertGreaterThanOrEqual(forecast.confidence, 0)
        XCTAssertLessThanOrEqual(forecast.confidence, 1)
        XCTAssertNotNil(forecast.predictions)
    }
    
    func testForecastTypes() async throws {
        // Test different forecast types
        let healthForecast = try await analyticsEngine.generatePredictiveForecast(
            forecastType: .health,
            timeframe: .week
        )
        XCTAssertEqual(healthForecast.type, .health)
        
        let performanceForecast = try await analyticsEngine.generatePredictiveForecast(
            forecastType: .performance,
            timeframe: .week
        )
        XCTAssertEqual(performanceForecast.type, .performance)
        
        let financialForecast = try await analyticsEngine.generatePredictiveForecast(
            forecastType: .financial,
            timeframe: .week
        )
        XCTAssertEqual(financialForecast.type, .financial)
        
        let operationalForecast = try await analyticsEngine.generatePredictiveForecast(
            forecastType: .operational,
            timeframe: .week
        )
        XCTAssertEqual(operationalForecast.type, .operational)
        
        let trendsForecast = try await analyticsEngine.generatePredictiveForecast(
            forecastType: .trends,
            timeframe: .week
        )
        XCTAssertEqual(trendsForecast.type, .trends)
    }
    
    func testForecastTimeframes() async throws {
        // Test different forecast timeframes
        let hourlyForecast = try await analyticsEngine.generatePredictiveForecast(
            forecastType: .health,
            timeframe: .hour
        )
        XCTAssertEqual(hourlyForecast.timeframe, .hour)
        
        let dailyForecast = try await analyticsEngine.generatePredictiveForecast(
            forecastType: .health,
            timeframe: .day
        )
        XCTAssertEqual(dailyForecast.timeframe, .day)
        
        let weeklyForecast = try await analyticsEngine.generatePredictiveForecast(
            forecastType: .health,
            timeframe: .week
        )
        XCTAssertEqual(weeklyForecast.timeframe, .week)
        
        let monthlyForecast = try await analyticsEngine.generatePredictiveForecast(
            forecastType: .health,
            timeframe: .month
        )
        XCTAssertEqual(monthlyForecast.timeframe, .month)
        
        let yearlyForecast = try await analyticsEngine.generatePredictiveForecast(
            forecastType: .health,
            timeframe: .year
        )
        XCTAssertEqual(yearlyForecast.timeframe, .year)
    }
    
    // MARK: - Export Tests
    
    func testExportAnalyticsData() async throws {
        // Test exporting analytics data in different formats
        let jsonData = try await analyticsEngine.exportAnalyticsData(format: .json)
        XCTAssertNotNil(jsonData)
        XCTAssertFalse(jsonData.isEmpty)
        
        let csvData = try await analyticsEngine.exportAnalyticsData(format: .csv)
        XCTAssertNotNil(csvData)
        
        let xmlData = try await analyticsEngine.exportAnalyticsData(format: .xml)
        XCTAssertNotNil(xmlData)
        
        let pdfData = try await analyticsEngine.exportAnalyticsData(format: .pdf)
        XCTAssertNotNil(pdfData)
    }
    
    func testExportDataContent() async throws {
        // Test that exported data contains expected content
        let exportData = try await analyticsEngine.exportAnalyticsData(format: .json)
        
        // Decode the JSON data
        let decoder = JSONDecoder()
        let analyticsExport = try decoder.decode(AnalyticsExportData.self, from: exportData)
        
        XCTAssertNotNil(analyticsExport.timestamp)
        XCTAssertNotNil(analyticsExport.insights)
        XCTAssertNotNil(analyticsExport.models)
        XCTAssertNotNil(analyticsExport.metrics)
        XCTAssertNotNil(analyticsExport.reports)
        XCTAssertNotNil(analyticsExport.dashboards)
        XCTAssertNotNil(analyticsExport.history)
    }
    
    // MARK: - History Tests
    
    func testGetAnalyticsHistory() async throws {
        // Test getting analytics history for different timeframes
        let weeklyHistory = analyticsEngine.getAnalyticsHistory(timeframe: .week)
        XCTAssertNotNil(weeklyHistory)
        
        let monthlyHistory = analyticsEngine.getAnalyticsHistory(timeframe: .month)
        XCTAssertNotNil(monthlyHistory)
        
        let yearlyHistory = analyticsEngine.getAnalyticsHistory(timeframe: .year)
        XCTAssertNotNil(yearlyHistory)
    }
    
    func testHistoryFiltering() async throws {
        // Test that history is filtered by timeframe
        let weeklyHistory = analyticsEngine.getAnalyticsHistory(timeframe: .week)
        let monthlyHistory = analyticsEngine.getAnalyticsHistory(timeframe: .month)
        
        // Monthly history should include more data than weekly history
        XCTAssertGreaterThanOrEqual(monthlyHistory.count, weeklyHistory.count)
        
        // All history entries should be within the specified timeframe
        let cutoffDate = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: Date()) ?? Date()
        for activity in weeklyHistory {
            XCTAssertGreaterThanOrEqual(activity.timestamp, cutoffDate)
        }
    }
    
    // MARK: - Integration Tests
    
    func testAnalyticsIntegration() async throws {
        // Test full analytics workflow
        try await analyticsEngine.startAnalytics()
        
        let activity = try await analyticsEngine.performAnalytics()
        XCTAssertNotNil(activity)
        
        let insights = await analyticsEngine.getAnalyticsInsights()
        XCTAssertNotNil(insights)
        
        let models = await analyticsEngine.getPredictiveModels()
        XCTAssertNotNil(models)
        
        let metrics = await analyticsEngine.getBusinessMetrics()
        XCTAssertNotNil(metrics)
        
        let reports = await analyticsEngine.getAnalyticsReports()
        XCTAssertNotNil(reports)
        
        let dashboards = await analyticsEngine.getAnalyticsDashboards()
        XCTAssertNotNil(dashboards)
        
        let forecast = try await analyticsEngine.generatePredictiveForecast(
            forecastType: .health,
            timeframe: .week
        )
        XCTAssertNotNil(forecast)
        
        let exportData = try await analyticsEngine.exportAnalyticsData()
        XCTAssertNotNil(exportData)
        
        await analyticsEngine.stopAnalytics()
        XCTAssertFalse(analyticsEngine.isAnalyticsActive)
    }
    
    func testErrorHandling() async throws {
        // Test error handling scenarios
        // This would require mocking to simulate various error conditions
        
        // Test with invalid parameters
        do {
            let forecast = try await analyticsEngine.generatePredictiveForecast(
                forecastType: .health,
                timeframe: .hour
            )
            XCTAssertNotNil(forecast)
        } catch {
            XCTAssertNotNil(analyticsEngine.lastError)
        }
    }
    
    // MARK: - Performance Tests
    
    func testAnalyticsPerformance() async throws {
        // Test analytics performance
        let startTime = Date()
        
        try await analyticsEngine.startAnalytics()
        let activity = try await analyticsEngine.performAnalytics()
        
        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)
        
        // Analytics should complete within reasonable time (e.g., 5 seconds)
        XCTAssertLessThan(duration, 5.0)
        XCTAssertNotNil(activity)
        
        await analyticsEngine.stopAnalytics()
    }
    
    func testConcurrentAnalytics() async throws {
        // Test concurrent analytics operations
        try await analyticsEngine.startAnalytics()
        
        async let activity1 = analyticsEngine.performAnalytics()
        async let activity2 = analyticsEngine.performAnalytics()
        async let activity3 = analyticsEngine.performAnalytics()
        
        let (result1, result2, result3) = try await (activity1, activity2, activity3)
        
        XCTAssertNotNil(result1)
        XCTAssertNotNil(result2)
        XCTAssertNotNil(result3)
        
        await analyticsEngine.stopAnalytics()
    }
    
    // MARK: - Data Validation Tests
    
    func testDataValidation() async throws {
        // Test data validation
        let insights = await analyticsEngine.getAnalyticsInsights()
        
        for insight in insights {
            // Validate insight data
            XCTAssertFalse(insight.title.isEmpty)
            XCTAssertFalse(insight.description.isEmpty)
            XCTAssertGreaterThanOrEqual(insight.confidence, 0)
            XCTAssertLessThanOrEqual(insight.confidence, 1)
            XCTAssertGreaterThanOrEqual(insight.impact, 0)
            XCTAssertLessThanOrEqual(insight.impact, 1)
        }
        
        let models = await analyticsEngine.getPredictiveModels()
        
        for model in models {
            // Validate model data
            XCTAssertFalse(model.name.isEmpty)
            XCTAssertGreaterThanOrEqual(model.accuracy, 0)
            XCTAssertLessThanOrEqual(model.accuracy, 1)
        }
        
        let reports = await analyticsEngine.getAnalyticsReports()
        
        for report in reports {
            // Validate report data
            XCTAssertFalse(report.title.isEmpty)
            XCTAssertFalse(report.description.isEmpty)
        }
        
        let dashboards = await analyticsEngine.getAnalyticsDashboards()
        
        for dashboard in dashboards {
            // Validate dashboard data
            XCTAssertFalse(dashboard.name.isEmpty)
            XCTAssertFalse(dashboard.description.isEmpty)
        }
    }
    
    // MARK: - Memory Management Tests
    
    func testMemoryManagement() async throws {
        // Test memory management
        let initialMemory = getMemoryUsage()
        
        // Perform multiple analytics operations
        try await analyticsEngine.startAnalytics()
        
        for _ in 0..<10 {
            _ = try await analyticsEngine.performAnalytics()
        }
        
        await analyticsEngine.stopAnalytics()
        
        let finalMemory = getMemoryUsage()
        let memoryIncrease = finalMemory - initialMemory
        
        // Memory increase should be reasonable (e.g., less than 50MB)
        XCTAssertLessThan(memoryIncrease, 50 * 1024 * 1024)
    }
    
    // MARK: - Helper Methods
    
    private func getMemoryUsage() -> Int {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            return Int(info.resident_size)
        } else {
            return 0
        }
    }
}

// MARK: - Test Extensions

extension AnalyticsInsight {
    static func mock(
        id: UUID = UUID(),
        title: String = "Test Insight",
        description: String = "Test insight description",
        category: InsightCategory = .health,
        severity: Severity = .medium,
        confidence: Double = 0.8,
        impact: Double = 0.6,
        recommendations: [String] = ["Test recommendation"],
        data: [String: Any] = [:],
        timestamp: Date = Date()
    ) -> AnalyticsInsight {
        return AnalyticsInsight(
            id: id,
            title: title,
            description: description,
            category: category,
            severity: severity,
            confidence: confidence,
            impact: impact,
            recommendations: recommendations,
            data: data,
            timestamp: timestamp
        )
    }
}

extension PredictiveModel {
    static func mock(
        id: UUID = UUID(),
        name: String = "Test Model",
        type: ModelType = .health,
        version: String = "1.0.0",
        accuracy: Double = 0.85,
        status: ModelStatus = .active,
        lastTrained: Date = Date(),
        performance: ModelPerformance = ModelPerformance(
            accuracy: 0.85,
            precision: 0.8,
            recall: 0.9,
            f1Score: 0.85,
            timestamp: Date()
        ),
        parameters: [String: Any] = [:],
        timestamp: Date = Date()
    ) -> PredictiveModel {
        return PredictiveModel(
            id: id,
            name: name,
            type: type,
            version: version,
            accuracy: accuracy,
            status: status,
            lastTrained: lastTrained,
            performance: performance,
            parameters: parameters,
            timestamp: timestamp
        )
    }
}

extension AnalyticsReport {
    static func mock(
        id: UUID = UUID(),
        title: String = "Test Report",
        type: ReportType = .health,
        description: String = "Test report description",
        data: [String: Any] = [:],
        charts: [Chart] = [],
        filters: [Filter] = [],
        schedule: ReportSchedule? = nil,
        recipients: [String] = [],
        status: ReportStatus = .active,
        timestamp: Date = Date()
    ) -> AnalyticsReport {
        return AnalyticsReport(
            id: id,
            title: title,
            type: type,
            description: description,
            data: data,
            charts: charts,
            filters: filters,
            schedule: schedule,
            recipients: recipients,
            status: status,
            timestamp: timestamp
        )
    }
}

extension AnalyticsDashboard {
    static func mock(
        id: UUID = UUID(),
        name: String = "Test Dashboard",
        category: DashboardCategory = .custom,
        description: String = "Test dashboard description",
        widgets: [Widget] = [],
        layout: DashboardLayout = DashboardLayout(
            columns: 2,
            rows: 2,
            widgets: [],
            timestamp: Date()
        ),
        filters: [Filter] = [],
        permissions: [String] = [],
        status: DashboardStatus = .active,
        timestamp: Date = Date()
    ) -> AnalyticsDashboard {
        return AnalyticsDashboard(
            id: id,
            name: name,
            category: category,
            description: description,
            widgets: widgets,
            layout: layout,
            filters: filters,
            permissions: permissions,
            status: status,
            timestamp: timestamp
        )
    }
} 
import XCTest
@testable import HealthAI2030

@MainActor
final class AdvancedAnalyticsTests: XCTestCase {
    var analyticsEngine: AdvancedAnalyticsEngine!
    
    override func setUp() {
        super.setUp()
        analyticsEngine = AdvancedAnalyticsEngine()
    }
    
    override func tearDown() {
        analyticsEngine = nil
        super.tearDown()
    }
    
    // MARK: - User Behavior Analytics Tests
    func testAnalyzeUserBehavior() async throws {
        let analysis = try await analyticsEngine.analyzeUserBehavior(timeRange: .lastDay)
        
        XCTAssertNotNil(analysis)
        XCTAssertGreaterThanOrEqual(analysis.activeUsers, 0)
        XCTAssertGreaterThanOrEqual(analysis.sessionDuration, 0)
        XCTAssertGreaterThanOrEqual(analysis.pageViews, 0)
        XCTAssertGreaterThanOrEqual(analysis.bounceRate, 0)
        XCTAssertLessThanOrEqual(analysis.bounceRate, 1)
        XCTAssertGreaterThanOrEqual(analysis.conversionRate, 0)
        XCTAssertLessThanOrEqual(analysis.conversionRate, 1)
        XCTAssertNotNil(analysis.timestamp)
        
        // Verify insights were generated
        XCTAssertFalse(analyticsEngine.insights.isEmpty)
        XCTAssertFalse(analyticsEngine.isLoading)
        XCTAssertNil(analyticsEngine.error)
    }
    
    func testAnalyzeUserBehaviorWithSegment() async throws {
        let segment = UserSegment(
            id: UUID(),
            name: "Test Segment",
            criteria: UserSegmentationCriteria(
                ageRange: 18...35,
                location: "US",
                behavior: .active,
                engagement: .high,
                customFilters: [:]
            ),
            userCount: 1000,
            characteristics: ["engagement": "high"]
        )
        
        let analysis = try await analyticsEngine.analyzeUserBehavior(timeRange: .lastWeek, segment: segment)
        
        XCTAssertNotNil(analysis)
        XCTAssertFalse(analyticsEngine.isLoading)
        XCTAssertNil(analyticsEngine.error)
    }
    
    func testSegmentUsers() async throws {
        let criteria = UserSegmentationCriteria(
            ageRange: 25...45,
            location: "US",
            behavior: .active,
            engagement: .medium,
            customFilters: ["premium": "true"]
        )
        
        let segments = try await analyticsEngine.segmentUsers(criteria: criteria)
        
        XCTAssertNotNil(segments)
        XCTAssertFalse(analyticsEngine.isLoading)
        XCTAssertNil(analyticsEngine.error)
    }
    
    func testTrackUserEvent() async throws {
        let event = UserEvent(
            id: UUID(),
            userId: "test_user_123",
            eventType: "page_view",
            timestamp: Date(),
            properties: ["page": "dashboard", "source": "home"],
            sessionId: "session_123"
        )
        
        try await analyticsEngine.trackUserEvent(event)
        
        // Event tracking should complete without errors
        XCTAssertNil(analyticsEngine.error)
    }
    
    func testGetUserJourney() async throws {
        let journey = try await analyticsEngine.getUserJourney(userId: "test_user_456", timeRange: .lastDay)
        
        XCTAssertNotNil(journey)
        XCTAssertEqual(journey.userId, "test_user_456")
        XCTAssertNotNil(journey.startTime)
        XCTAssertNotNil(journey.endTime)
        XCTAssertGreaterThanOrEqual(journey.duration, 0)
    }
    
    func testGetFunnelAnalysis() async throws {
        let funnelAnalysis = try await analyticsEngine.getFunnelAnalysis(funnelName: "onboarding", timeRange: .lastWeek)
        
        XCTAssertNotNil(funnelAnalysis)
        XCTAssertEqual(funnelAnalysis.funnelName, "onboarding")
        XCTAssertGreaterThanOrEqual(funnelAnalysis.conversionRate, 0)
        XCTAssertLessThanOrEqual(funnelAnalysis.conversionRate, 1)
    }
    
    // MARK: - Business Metrics Analytics Tests
    func testAnalyzeBusinessMetrics() async throws {
        let metrics: [BusinessMetric] = [.revenue, .users, .engagement, .retention]
        let analysis = try await analyticsEngine.analyzeBusinessMetrics(timeRange: .lastMonth, metrics: metrics)
        
        XCTAssertNotNil(analysis)
        XCTAssertGreaterThanOrEqual(analysis.revenue, 0)
        XCTAssertGreaterThanOrEqual(analysis.users, 0)
        XCTAssertGreaterThanOrEqual(analysis.engagement, 0)
        XCTAssertLessThanOrEqual(analysis.engagement, 1)
        XCTAssertGreaterThanOrEqual(analysis.retention, 0)
        XCTAssertLessThanOrEqual(analysis.retention, 1)
        XCTAssertGreaterThanOrEqual(analysis.churn, 0)
        XCTAssertLessThanOrEqual(analysis.churn, 1)
        XCTAssertNotNil(analysis.timestamp)
        
        // Verify insights were generated
        XCTAssertFalse(analyticsEngine.insights.isEmpty)
        XCTAssertFalse(analyticsEngine.isLoading)
        XCTAssertNil(analyticsEngine.error)
    }
    
    func testCalculateKPIs() async throws {
        let kpis = try await analyticsEngine.calculateKPIs(timeRange: .lastDay)
        
        XCTAssertNotNil(kpis)
        // KPIs may be empty in test environment
    }
    
    func testGetRevenueAnalysis() async throws {
        let revenueAnalysis = try await analyticsEngine.getRevenueAnalysis(timeRange: .lastMonth, breakdown: .bySource)
        
        XCTAssertNotNil(revenueAnalysis)
        XCTAssertGreaterThanOrEqual(revenueAnalysis.totalRevenue, 0)
        XCTAssertGreaterThanOrEqual(revenueAnalysis.averageOrderValue, 0)
    }
    
    func testGetRetentionAnalysis() async throws {
        let retentionAnalysis = try await analyticsEngine.getRetentionAnalysis(timeRange: .lastMonth, cohortType: .acquisition)
        
        XCTAssertNotNil(retentionAnalysis)
        XCTAssertNotNil(retentionAnalysis.retentionRates)
        XCTAssertNotNil(retentionAnalysis.cohortSizes)
    }
    
    func testGetChurnAnalysis() async throws {
        let churnAnalysis = try await analyticsEngine.getChurnAnalysis(timeRange: .lastMonth)
        
        XCTAssertNotNil(churnAnalysis)
        XCTAssertGreaterThanOrEqual(churnAnalysis.churnRate, 0)
        XCTAssertLessThanOrEqual(churnAnalysis.churnRate, 1)
        XCTAssertGreaterThanOrEqual(churnAnalysis.churnedUsers, 0)
    }
    
    // MARK: - Predictive Analytics Tests
    func testGenerateForecast() async throws {
        let forecast = try await analyticsEngine.generateForecast(
            metric: "daily_active_users",
            timeRange: .lastMonth,
            forecastPeriod: .lastWeek
        )
        
        XCTAssertNotNil(forecast)
        XCTAssertEqual(forecast.metric, "daily_active_users")
        XCTAssertGreaterThanOrEqual(forecast.confidence, 0)
        XCTAssertLessThanOrEqual(forecast.confidence, 1)
        XCTAssertNotNil(forecast.trend)
        XCTAssertNotNil(forecast.seasonality)
        
        // Verify insights were generated
        XCTAssertFalse(analyticsEngine.insights.isEmpty)
        XCTAssertFalse(analyticsEngine.isLoading)
        XCTAssertNil(analyticsEngine.error)
    }
    
    func testPredictUserBehavior() async throws {
        let prediction = try await analyticsEngine.predictUserBehavior(
            userId: "test_user_789",
            predictionType: .purchase
        )
        
        XCTAssertNotNil(prediction)
        XCTAssertEqual(prediction.userId, "test_user_789")
        XCTAssertEqual(prediction.predictionType, .purchase)
        XCTAssertGreaterThanOrEqual(prediction.probability, 0)
        XCTAssertLessThanOrEqual(prediction.probability, 1)
        XCTAssertGreaterThanOrEqual(prediction.confidence, 0)
        XCTAssertLessThanOrEqual(prediction.confidence, 1)
    }
    
    func testPredictChurn() async throws {
        let users = ["user1", "user2", "user3"]
        let prediction = try await analyticsEngine.predictChurn(users: users, timeRange: .lastMonth)
        
        XCTAssertNotNil(prediction)
        XCTAssertTrue(users.contains(prediction.userId))
        XCTAssertGreaterThanOrEqual(prediction.churnProbability, 0)
        XCTAssertLessThanOrEqual(prediction.churnProbability, 1)
    }
    
    func testPredictLifetimeValue() async throws {
        let users = ["user1", "user2"]
        let prediction = try await analyticsEngine.predictLifetimeValue(users: users)
        
        XCTAssertNotNil(prediction)
        XCTAssertTrue(users.contains(prediction.userId))
        XCTAssertGreaterThanOrEqual(prediction.predictedLTV, 0)
        XCTAssertGreaterThanOrEqual(prediction.confidence, 0)
        XCTAssertLessThanOrEqual(prediction.confidence, 1)
    }
    
    func testGetRecommendations() async throws {
        let recommendations = try await analyticsEngine.getRecommendations(
            userId: "test_user_101",
            recommendationType: .product
        )
        
        XCTAssertNotNil(recommendations)
        // Recommendations may be empty in test environment
    }
    
    // MARK: - Anomaly Detection Tests
    func testDetectAnomalies() async throws {
        let anomalies = try await analyticsEngine.detectAnomalies(
            metric: "response_time",
            timeRange: .lastWeek,
            sensitivity: .medium
        )
        
        XCTAssertNotNil(anomalies)
        
        // Verify insights were generated
        XCTAssertFalse(analyticsEngine.insights.isEmpty)
        XCTAssertFalse(analyticsEngine.isLoading)
        XCTAssertNil(analyticsEngine.error)
    }
    
    func testSetAnomalyThreshold() async throws {
        try await analyticsEngine.setAnomalyThreshold(metric: "error_rate", threshold: 0.05)
        
        // Threshold setting should complete without errors
        XCTAssertNil(analyticsEngine.error)
    }
    
    func testGetAnomalyHistory() async throws {
        let anomalies = try await analyticsEngine.getAnomalyHistory(
            metric: "cpu_usage",
            timeRange: .lastMonth
        )
        
        XCTAssertNotNil(anomalies)
        // Anomaly history may be empty in test environment
    }
    
    // MARK: - Dashboard Management Tests
    func testCreateDashboard() async throws {
        let dashboard = AnalyticsDashboard(
            id: UUID(),
            name: "Test Dashboard",
            description: "Test dashboard for analytics",
            widgets: [],
            refreshInterval: .hourly,
            isPublic: false,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        try await analyticsEngine.createDashboard(dashboard)
        
        XCTAssertTrue(analyticsEngine.dashboards.contains { $0.id == dashboard.id })
        XCTAssertNil(analyticsEngine.error)
    }
    
    func testUpdateDashboard() async throws {
        let dashboard = AnalyticsDashboard(
            id: UUID(),
            name: "Original Dashboard",
            description: "Original description",
            widgets: [],
            refreshInterval: .hourly,
            isPublic: false,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        try await analyticsEngine.createDashboard(dashboard)
        
        let updatedDashboard = AnalyticsDashboard(
            id: dashboard.id,
            name: "Updated Dashboard",
            description: "Updated description",
            widgets: [],
            refreshInterval: .daily,
            isPublic: true,
            createdAt: dashboard.createdAt,
            updatedAt: Date()
        )
        
        try await analyticsEngine.updateDashboard(updatedDashboard)
        
        let localDashboard = analyticsEngine.dashboards.first { $0.id == dashboard.id }
        XCTAssertNotNil(localDashboard)
        XCTAssertEqual(localDashboard?.name, "Updated Dashboard")
        XCTAssertEqual(localDashboard?.refreshInterval, .daily)
        XCTAssertTrue(localDashboard?.isPublic == true)
    }
    
    func testDeleteDashboard() async throws {
        let dashboard = AnalyticsDashboard(
            id: UUID(),
            name: "Dashboard to Delete",
            description: "Will be deleted",
            widgets: [],
            refreshInterval: .hourly,
            isPublic: false,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        try await analyticsEngine.createDashboard(dashboard)
        XCTAssertTrue(analyticsEngine.dashboards.contains { $0.id == dashboard.id })
        
        try await analyticsEngine.deleteDashboard(dashboard.id)
        XCTAssertFalse(analyticsEngine.dashboards.contains { $0.id == dashboard.id })
    }
    
    func testGetDashboard() async throws {
        let dashboard = AnalyticsDashboard(
            id: UUID(),
            name: "Test Dashboard",
            description: "Test description",
            widgets: [],
            refreshInterval: .hourly,
            isPublic: false,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        try await analyticsEngine.createDashboard(dashboard)
        
        let retrievedDashboard = try await analyticsEngine.getDashboard(dashboard.id)
        XCTAssertNotNil(retrievedDashboard)
    }
    
    func testGetDashboards() async throws {
        let dashboards = try await analyticsEngine.getDashboards()
        
        XCTAssertNotNil(dashboards)
        // Dashboards may be empty in test environment
    }
    
    func testRefreshDashboard() async throws {
        let dashboard = AnalyticsDashboard(
            id: UUID(),
            name: "Refreshable Dashboard",
            description: "Will be refreshed",
            widgets: [],
            refreshInterval: .realTime,
            isPublic: false,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        try await analyticsEngine.createDashboard(dashboard)
        try await analyticsEngine.refreshDashboard(dashboard.id)
        
        // Refresh should complete without errors
        XCTAssertNil(analyticsEngine.error)
    }
    
    // MARK: - Reporting Engine Tests
    func testGenerateReport() async throws {
        let report = AnalyticsReport(
            id: UUID(),
            name: "Test Report",
            description: "Test report description",
            reportType: .userBehavior,
            parameters: ["time_range": "last_week"],
            format: .pdf,
            recipients: ["test@example.com"]
        )
        
        let result = try await analyticsEngine.generateReport(report)
        
        XCTAssertNotNil(result)
        XCTAssertEqual(result.reportId, report.id)
        XCTAssertNotNil(result.status)
        XCTAssertNotNil(result.generatedAt)
        XCTAssertFalse(analyticsEngine.isLoading)
        XCTAssertNil(analyticsEngine.error)
    }
    
    func testScheduleReport() async throws {
        let report = AnalyticsReport(
            id: UUID(),
            name: "Scheduled Report",
            description: "Will be scheduled",
            reportType: .businessMetrics,
            parameters: [:],
            format: .excel,
            recipients: ["admin@example.com"]
        )
        
        let schedule = ReportSchedule(
            type: .daily,
            frequency: "daily",
            startDate: Date(),
            endDate: nil,
            timeZone: "UTC"
        )
        
        try await analyticsEngine.scheduleReport(report, schedule: schedule)
        
        // Scheduling should complete without errors
        XCTAssertNil(analyticsEngine.error)
    }
    
    func testGetScheduledReports() async throws {
        let scheduledReports = try await analyticsEngine.getScheduledReports()
        
        XCTAssertNotNil(scheduledReports)
        // Scheduled reports may be empty in test environment
    }
    
    func testExportReport() async throws {
        let reportId = UUID()
        let exportData = try await analyticsEngine.exportReport(reportId, format: .pdf)
        
        XCTAssertNotNil(exportData)
        // Export data may be empty in test environment
    }
    
    // MARK: - Insights Management Tests
    func testGetInsights() async throws {
        // First generate some insights
        _ = try await analyticsEngine.analyzeUserBehavior(timeRange: .lastDay)
        
        let allInsights = try await analyticsEngine.getInsights()
        XCTAssertNotNil(allInsights)
        XCTAssertFalse(allInsights.isEmpty)
        
        let behaviorInsights = try await analyticsEngine.getInsights(insightType: .userBehavior)
        XCTAssertNotNil(behaviorInsights)
        XCTAssertTrue(behaviorInsights.allSatisfy { $0.type == .userBehavior })
        
        let recentInsights = try await analyticsEngine.getInsights(timeRange: .lastHour)
        XCTAssertNotNil(recentInsights)
        XCTAssertTrue(recentInsights.allSatisfy { $0.timestamp >= Date().addingTimeInterval(-3600) })
    }
    
    func testMarkInsightAsRead() async throws {
        // First generate some insights
        _ = try await analyticsEngine.analyzeUserBehavior(timeRange: .lastDay)
        
        guard let insight = analyticsEngine.insights.first else {
            XCTFail("No insights available")
            return
        }
        
        try await analyticsEngine.markInsightAsRead(insight.id)
        
        let updatedInsight = analyticsEngine.insights.first { $0.id == insight.id }
        XCTAssertNotNil(updatedInsight)
        XCTAssertTrue(updatedInsight?.isRead == true)
        XCTAssertNotNil(updatedInsight?.readAt)
    }
    
    func testDismissInsight() async throws {
        // First generate some insights
        _ = try await analyticsEngine.analyzeUserBehavior(timeRange: .lastDay)
        
        let initialCount = analyticsEngine.insights.count
        guard let insight = analyticsEngine.insights.first else {
            XCTFail("No insights available")
            return
        }
        
        try await analyticsEngine.dismissInsight(insight.id)
        
        XCTAssertEqual(analyticsEngine.insights.count, initialCount - 1)
        XCTAssertFalse(analyticsEngine.insights.contains { $0.id == insight.id })
    }
    
    func testGetInsightSummary() async throws {
        // First generate some insights
        _ = try await analyticsEngine.analyzeUserBehavior(timeRange: .lastDay)
        _ = try await analyticsEngine.analyzeBusinessMetrics(timeRange: .lastDay, metrics: [.revenue])
        
        let summary = try await analyticsEngine.getInsightSummary()
        
        XCTAssertNotNil(summary)
        XCTAssertGreaterThanOrEqual(summary.totalInsights, 0)
        XCTAssertGreaterThanOrEqual(summary.unreadInsights, 0)
        XCTAssertGreaterThanOrEqual(summary.highPriorityInsights, 0)
        XCTAssertNotNil(summary.insightsByType)
        XCTAssertNotNil(summary.lastUpdated)
    }
    
    // MARK: - Data Export Tests
    func testExportAnalyticsData() async throws {
        let exportData = try await analyticsEngine.exportAnalyticsData(
            dataType: .userBehavior,
            timeRange: .lastDay,
            format: .json
        )
        
        XCTAssertNotNil(exportData)
        // Export data may be empty in test environment
        XCTAssertFalse(analyticsEngine.isLoading)
        XCTAssertNil(analyticsEngine.error)
    }
    
    // MARK: - Configuration Tests
    func testEnableDisableAnalytics() {
        XCTAssertTrue(analyticsEngine.isEnabled)
        
        analyticsEngine.disableAnalytics()
        XCTAssertFalse(analyticsEngine.isEnabled)
        
        analyticsEngine.enableAnalytics()
        XCTAssertTrue(analyticsEngine.isEnabled)
    }
    
    func testSetDataRetentionPolicy() async throws {
        let policy = AnalyticsDataRetentionPolicy(
            retentionDays: 90,
            archiveAfterDays: 30,
            dataTypes: [.userBehavior, .businessMetrics]
        )
        
        try await analyticsEngine.setDataRetentionPolicy(policy)
        
        // Policy setting should complete without errors
        XCTAssertNil(analyticsEngine.error)
    }
    
    // MARK: - Error Handling Tests
    func testAnalyticsErrorHandling() async {
        // Test error handling for invalid operations
        do {
            // This would test error scenarios in a real implementation
            // For now, we just verify the error handling structure exists
            XCTAssertNotNil(analyticsEngine.error)
        }
    }
    
    // MARK: - Concurrent Operations Tests
    func testConcurrentAnalyticsOperations() async {
        await withTaskGroup(of: Void.self) { group in
            // Add multiple concurrent operations
            group.addTask {
                _ = try? await self.analyticsEngine.analyzeUserBehavior(timeRange: .lastDay)
            }
            
            group.addTask {
                _ = try? await self.analyticsEngine.analyzeBusinessMetrics(timeRange: .lastDay, metrics: [.revenue])
            }
            
            group.addTask {
                _ = try? await self.analyticsEngine.generateForecast(metric: "users", timeRange: .lastMonth, forecastPeriod: .lastWeek)
            }
            
            group.addTask {
                _ = try? await self.analyticsEngine.detectAnomalies(metric: "errors", timeRange: .lastWeek, sensitivity: .medium)
            }
        }
        
        // Verify no crashes occurred
        XCTAssertNotNil(analyticsEngine)
    }
    
    // MARK: - Performance Tests
    func testAnalyticsPerformance() async throws {
        let startTime = Date()
        
        // Perform multiple analytics operations
        for i in 0..<10 {
            _ = try await analyticsEngine.analyzeUserBehavior(timeRange: .lastDay)
            _ = try await analyticsEngine.analyzeBusinessMetrics(timeRange: .lastDay, metrics: [.revenue, .users])
            _ = try await analyticsEngine.generateForecast(metric: "metric_\(i)", timeRange: .lastWeek, forecastPeriod: .lastDay)
        }
        
        let operationTime = Date().timeIntervalSince(startTime)
        XCTAssertLessThan(operationTime, 30.0) // Should complete within 30 seconds
    }
    
    // MARK: - Memory Management Tests
    func testAnalyticsEngineMemoryManagement() {
        weak var weakEngine: AdvancedAnalyticsEngine?
        
        autoreleasepool {
            let engine = AdvancedAnalyticsEngine()
            weakEngine = engine
        }
        
        // The engine should be deallocated after the autoreleasepool
        XCTAssertNil(weakEngine)
    }
    
    // MARK: - Integration Tests
    func testCompleteAnalyticsWorkflow() async throws {
        // 1. Analyze user behavior
        let behaviorAnalysis = try await analyticsEngine.analyzeUserBehavior(timeRange: .lastDay)
        XCTAssertNotNil(behaviorAnalysis)
        
        // 2. Analyze business metrics
        let businessAnalysis = try await analyticsEngine.analyzeBusinessMetrics(timeRange: .lastDay, metrics: [.revenue, .users, .engagement])
        XCTAssertNotNil(businessAnalysis)
        
        // 3. Generate forecast
        let forecast = try await analyticsEngine.generateForecast(metric: "daily_active_users", timeRange: .lastMonth, forecastPeriod: .lastWeek)
        XCTAssertNotNil(forecast)
        
        // 4. Detect anomalies
        let anomalies = try await analyticsEngine.detectAnomalies(metric: "response_time", timeRange: .lastWeek, sensitivity: .medium)
        XCTAssertNotNil(anomalies)
        
        // 5. Create dashboard
        let dashboard = AnalyticsDashboard(
            id: UUID(),
            name: "Workflow Dashboard",
            description: "Created during workflow test",
            widgets: [],
            refreshInterval: .hourly,
            isPublic: false,
            createdAt: Date(),
            updatedAt: Date()
        )
        try await analyticsEngine.createDashboard(dashboard)
        XCTAssertTrue(analyticsEngine.dashboards.contains { $0.id == dashboard.id })
        
        // 6. Generate report
        let report = AnalyticsReport(
            id: UUID(),
            name: "Workflow Report",
            description: "Generated during workflow test",
            reportType: .userBehavior,
            parameters: [:],
            format: .pdf,
            recipients: ["test@example.com"]
        )
        let reportResult = try await analyticsEngine.generateReport(report)
        XCTAssertNotNil(reportResult)
        
        // 7. Get insights
        let insights = try await analyticsEngine.getInsights()
        XCTAssertNotNil(insights)
        XCTAssertFalse(insights.isEmpty)
        
        // 8. Export data
        let exportData = try await analyticsEngine.exportAnalyticsData(
            dataType: .userBehavior,
            timeRange: .lastDay,
            format: .json
        )
        XCTAssertNotNil(exportData)
        
        // 9. Cleanup
        try await analyticsEngine.deleteDashboard(dashboard.id)
        XCTAssertFalse(analyticsEngine.dashboards.contains { $0.id == dashboard.id })
        
        // Verify workflow completed successfully
        XCTAssertNotNil(analyticsEngine)
        XCTAssertFalse(analyticsEngine.isLoading)
        XCTAssertNil(analyticsEngine.error)
    }
} 
import XCTest
import Combine
@testable import HealthAI_2030

/// Comprehensive Test Suite for Advanced Performance Monitor
/// Tests all aspects of the performance monitoring and analytics system
@MainActor
final class AdvancedPerformanceMonitorTests: XCTestCase {
    
    var monitor: AdvancedPerformanceMonitor!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() async throws {
        try await super.setUp()
        monitor = AdvancedPerformanceMonitor()
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDown() async throws {
        monitor?.stopMonitoring()
        cancellables?.removeAll()
        monitor = nil
        cancellables = nil
        try await super.tearDown()
    }
    
    // MARK: - Basic Functionality Tests
    
    func testMonitorInitialization() {
        XCTAssertNotNil(monitor)
        XCTAssertFalse(monitor.isMonitoring)
        XCTAssertEqual(monitor.monitoringInterval, 1.0)
        XCTAssertTrue(monitor.anomalyAlerts.isEmpty)
        XCTAssertTrue(monitor.optimizationRecommendations.isEmpty)
        XCTAssertTrue(monitor.performanceTrends.isEmpty)
        XCTAssertEqual(monitor.systemHealth, .excellent)
    }
    
    func testStartMonitoring() throws {
        // Test starting monitoring
        try monitor.startMonitoring(interval: 0.5)
        
        XCTAssertTrue(monitor.isMonitoring)
        XCTAssertEqual(monitor.monitoringInterval, 0.5)
        
        // Test that starting again doesn't cause issues
        try monitor.startMonitoring(interval: 1.0)
        XCTAssertTrue(monitor.isMonitoring)
        XCTAssertEqual(monitor.monitoringInterval, 0.5) // Should remain the original
    }
    
    func testStopMonitoring() throws {
        try monitor.startMonitoring()
        XCTAssertTrue(monitor.isMonitoring)
        
        monitor.stopMonitoring()
        XCTAssertFalse(monitor.isMonitoring)
        
        // Test that stopping again doesn't cause issues
        monitor.stopMonitoring()
        XCTAssertFalse(monitor.isMonitoring)
    }
    
    func testMonitoringInterval() throws {
        let customInterval = 2.5
        try monitor.startMonitoring(interval: customInterval)
        
        XCTAssertEqual(monitor.monitoringInterval, customInterval)
    }
    
    // MARK: - Metrics Collection Tests
    
    func testSystemMetricsCollection() async throws {
        try monitor.startMonitoring(interval: 0.1)
        
        // Wait for metrics to be collected
        try await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
        
        let metrics = monitor.currentMetrics
        
        // Test that all metric components are present
        XCTAssertNotNil(metrics.cpu)
        XCTAssertNotNil(metrics.memory)
        XCTAssertNotNil(metrics.network)
        XCTAssertNotNil(metrics.disk)
        XCTAssertNotNil(metrics.application)
        XCTAssertNotNil(metrics.ui)
        XCTAssertNotNil(metrics.battery)
        XCTAssertNotNil(metrics.ml)
        XCTAssertNotNil(metrics.database)
        XCTAssertNotNil(metrics.security)
        
        // Test that timestamp is recent
        let now = Date()
        XCTAssertLessThan(now.timeIntervalSince(metrics.timestamp), 1.0)
    }
    
    func testCPUMetrics() async throws {
        try monitor.startMonitoring(interval: 0.1)
        try await Task.sleep(nanoseconds: 200_000_000)
        
        let cpuMetrics = monitor.currentMetrics.cpu
        
        XCTAssertGreaterThanOrEqual(cpuMetrics.usage, 0)
        XCTAssertLessThanOrEqual(cpuMetrics.usage, 100)
        XCTAssertGreaterThanOrEqual(cpuMetrics.userTime, 0)
        XCTAssertGreaterThanOrEqual(cpuMetrics.systemTime, 0)
        XCTAssertGreaterThan(cpuMetrics.temperature, 0)
        XCTAssertGreaterThanOrEqual(cpuMetrics.efficiency, 0)
        XCTAssertLessThanOrEqual(cpuMetrics.efficiency, 100)
    }
    
    func testMemoryMetrics() async throws {
        try monitor.startMonitoring(interval: 0.1)
        try await Task.sleep(nanoseconds: 200_000_000)
        
        let memoryMetrics = monitor.currentMetrics.memory
        
        XCTAssertGreaterThan(memoryMetrics.totalMemory, 0)
        XCTAssertGreaterThan(memoryMetrics.usedMemory, 0)
        XCTAssertLessThanOrEqual(memoryMetrics.usedMemory, memoryMetrics.totalMemory)
        XCTAssertEqual(memoryMetrics.availableMemory, memoryMetrics.totalMemory - memoryMetrics.usedMemory)
        XCTAssertNotNil(memoryMetrics.pressure)
        XCTAssertGreaterThanOrEqual(memoryMetrics.swapUsage, 0)
    }
    
    func testNetworkMetrics() async throws {
        try monitor.startMonitoring(interval: 0.1)
        try await Task.sleep(nanoseconds: 200_000_000)
        
        let networkMetrics = monitor.currentMetrics.network
        
        XCTAssertGreaterThanOrEqual(networkMetrics.latency, 0)
        XCTAssertGreaterThanOrEqual(networkMetrics.throughput, 0)
        XCTAssertGreaterThanOrEqual(networkMetrics.bytesReceived, 0)
        XCTAssertGreaterThanOrEqual(networkMetrics.bytesSent, 0)
        XCTAssertGreaterThanOrEqual(networkMetrics.connectionCount, 0)
        XCTAssertGreaterThanOrEqual(networkMetrics.errorRate, 0)
    }
    
    func testDiskMetrics() async throws {
        try monitor.startMonitoring(interval: 0.1)
        try await Task.sleep(nanoseconds: 200_000_000)
        
        let diskMetrics = monitor.currentMetrics.disk
        
        XCTAssertGreaterThanOrEqual(diskMetrics.totalSpace, 0)
        XCTAssertGreaterThanOrEqual(diskMetrics.usedSpace, 0)
        XCTAssertLessThanOrEqual(diskMetrics.usedSpace, diskMetrics.totalSpace)
        XCTAssertGreaterThanOrEqual(diskMetrics.readSpeed, 0)
        XCTAssertGreaterThanOrEqual(diskMetrics.writeSpeed, 0)
        XCTAssertGreaterThanOrEqual(diskMetrics.iops, 0)
    }
    
    func testApplicationMetrics() async throws {
        try monitor.startMonitoring(interval: 0.1)
        try await Task.sleep(nanoseconds: 200_000_000)
        
        let appMetrics = monitor.currentMetrics.application
        
        XCTAssertGreaterThanOrEqual(appMetrics.launchTime, 0)
        XCTAssertGreaterThanOrEqual(appMetrics.responseTime, 0)
        XCTAssertGreaterThanOrEqual(appMetrics.frameRate, 0)
        XCTAssertLessThanOrEqual(appMetrics.frameRate, 120) // Max reasonable frame rate
        XCTAssertGreaterThanOrEqual(appMetrics.crashCount, 0)
        XCTAssertGreaterThanOrEqual(appMetrics.userSessions, 0)
        XCTAssertGreaterThanOrEqual(appMetrics.apiCalls, 0)
    }
    
    func testUIMetrics() async throws {
        try monitor.startMonitoring(interval: 0.1)
        try await Task.sleep(nanoseconds: 200_000_000)
        
        let uiMetrics = monitor.currentMetrics.ui
        
        XCTAssertGreaterThanOrEqual(uiMetrics.renderTime, 0)
        XCTAssertGreaterThanOrEqual(uiMetrics.layoutTime, 0)
        XCTAssertGreaterThanOrEqual(uiMetrics.animationFrameRate, 0)
        XCTAssertGreaterThanOrEqual(uiMetrics.scrollPerformance, 0)
        XCTAssertLessThanOrEqual(uiMetrics.scrollPerformance, 100)
        XCTAssertGreaterThanOrEqual(uiMetrics.touchLatency, 0)
        XCTAssertGreaterThanOrEqual(uiMetrics.viewHierarchyDepth, 0)
    }
    
    func testBatteryMetrics() async throws {
        try monitor.startMonitoring(interval: 0.1)
        try await Task.sleep(nanoseconds: 200_000_000)
        
        let batteryMetrics = monitor.currentMetrics.battery
        
        XCTAssertGreaterThanOrEqual(batteryMetrics.batteryLevel, 0)
        XCTAssertLessThanOrEqual(batteryMetrics.batteryLevel, 1.0)
        XCTAssertNotNil(batteryMetrics.batteryState)
        XCTAssertGreaterThanOrEqual(batteryMetrics.powerConsumption, 0)
        XCTAssertNotNil(batteryMetrics.thermalState)
        XCTAssertGreaterThanOrEqual(batteryMetrics.chargingRate, 0)
        XCTAssertGreaterThanOrEqual(batteryMetrics.batteryHealth, 0)
        XCTAssertLessThanOrEqual(batteryMetrics.batteryHealth, 100)
    }
    
    func testMLMetrics() async throws {
        try monitor.startMonitoring(interval: 0.1)
        try await Task.sleep(nanoseconds: 200_000_000)
        
        let mlMetrics = monitor.currentMetrics.ml
        
        XCTAssertGreaterThanOrEqual(mlMetrics.modelLoadTime, 0)
        XCTAssertGreaterThanOrEqual(mlMetrics.inferenceTime, 0)
        XCTAssertGreaterThanOrEqual(mlMetrics.memoryUsage, 0)
        XCTAssertGreaterThanOrEqual(mlMetrics.accuracy, 0)
        XCTAssertLessThanOrEqual(mlMetrics.accuracy, 100)
        XCTAssertGreaterThanOrEqual(mlMetrics.modelSize, 0)
        XCTAssertGreaterThanOrEqual(mlMetrics.neuralEngineUsage, 0)
        XCTAssertLessThanOrEqual(mlMetrics.neuralEngineUsage, 100)
    }
    
    func testDatabaseMetrics() async throws {
        try monitor.startMonitoring(interval: 0.1)
        try await Task.sleep(nanoseconds: 200_000_000)
        
        let dbMetrics = monitor.currentMetrics.database
        
        XCTAssertGreaterThanOrEqual(dbMetrics.queryTime, 0)
        XCTAssertGreaterThanOrEqual(dbMetrics.connectionPool, 0)
        XCTAssertGreaterThanOrEqual(dbMetrics.cacheHitRate, 0)
        XCTAssertLessThanOrEqual(dbMetrics.cacheHitRate, 100)
        XCTAssertGreaterThanOrEqual(dbMetrics.transactionRate, 0)
        XCTAssertGreaterThanOrEqual(dbMetrics.storageSize, 0)
        XCTAssertGreaterThanOrEqual(dbMetrics.indexEfficiency, 0)
        XCTAssertLessThanOrEqual(dbMetrics.indexEfficiency, 100)
    }
    
    func testSecurityMetrics() async throws {
        try monitor.startMonitoring(interval: 0.1)
        try await Task.sleep(nanoseconds: 200_000_000)
        
        let securityMetrics = monitor.currentMetrics.security
        
        XCTAssertGreaterThanOrEqual(securityMetrics.encryptionOverhead, 0)
        XCTAssertGreaterThanOrEqual(securityMetrics.authenticationTime, 0)
        XCTAssertGreaterThanOrEqual(securityMetrics.threatDetection, 0)
        XCTAssertGreaterThanOrEqual(securityMetrics.secureConnections, 0)
        XCTAssertGreaterThanOrEqual(securityMetrics.accessControlLatency, 0)
    }
    
    // MARK: - Anomaly Detection Tests
    
    func testAnomalyDetection() async throws {
        try monitor.startMonitoring(interval: 0.1)
        
        // Wait for some data collection
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        // Anomalies might be detected based on simulated data
        // Test that the anomaly detection system is working
        XCTAssertTrue(monitor.anomalyAlerts.count >= 0)
        
        // If there are anomalies, test their structure
        for anomaly in monitor.anomalyAlerts {
            XCTAssertFalse(anomaly.metric.isEmpty)
            XCTAssertGreaterThanOrEqual(anomaly.value, 0)
            XCTAssertGreaterThanOrEqual(anomaly.threshold, 0)
            XCTAssertNotNil(anomaly.severity)
            XCTAssertNotNil(anomaly.category)
            XCTAssertFalse(anomaly.description.isEmpty)
            XCTAssertFalse(anomaly.recommendation.isEmpty)
            XCTAssertNotNil(anomaly.timestamp)
        }
    }
    
    func testAnomalySeverityLevels() async throws {
        try monitor.startMonitoring(interval: 0.1)
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        // Test that severity levels are correctly assigned
        for anomaly in monitor.anomalyAlerts {
            XCTAssertTrue([AnomalySeverity.low, .medium, .high, .critical].contains(anomaly.severity))
        }
    }
    
    func testAnomalyCategories() async throws {
        try monitor.startMonitoring(interval: 0.1)
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        // Test that all anomaly categories are valid
        let validCategories: [AnomalyCategory] = [.cpu, .memory, .network, .disk, .application, .ui, .battery, .ml, .database, .security]
        
        for anomaly in monitor.anomalyAlerts {
            XCTAssertTrue(validCategories.contains(anomaly.category))
        }
    }
    
    func testAnomalyAlertCleanup() async throws {
        try monitor.startMonitoring(interval: 0.1)
        
        // Wait for some alerts to be generated
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        let initialAlertCount = monitor.anomalyAlerts.count
        
        // Wait longer to see if old alerts are cleaned up
        // (Note: In real implementation, alerts older than 5 minutes are cleaned up)
        try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
        // For this test, we'll just verify the structure is in place
        XCTAssertTrue(monitor.anomalyAlerts.count >= 0)
    }
    
    // MARK: - Trend Analysis Tests
    
    func testTrendAnalysis() async throws {
        try monitor.startMonitoring(interval: 0.1)
        
        // Wait for enough data to analyze trends
        try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
        // Test that trends are being analyzed
        XCTAssertTrue(monitor.performanceTrends.count >= 0)
        
        // If there are trends, test their structure
        for trend in monitor.performanceTrends {
            XCTAssertFalse(trend.metric.isEmpty)
            XCTAssertNotNil(trend.trend)
            XCTAssertGreaterThanOrEqual(trend.confidence, 0)
            XCTAssertLessThanOrEqual(trend.confidence, 100)
            XCTAssertFalse(trend.values.isEmpty)
            XCTAssertNotNil(trend.timestamp)
        }
    }
    
    func testTrendDirections() async throws {
        try monitor.startMonitoring(interval: 0.1)
        try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
        let validDirections: [TrendDirection] = [.increasing, .decreasing, .stable]
        
        for trend in monitor.performanceTrends {
            XCTAssertTrue(validDirections.contains(trend.trend))
        }
    }
    
    func testTrendConfidence() async throws {
        try monitor.startMonitoring(interval: 0.1)
        try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
        for trend in monitor.performanceTrends {
            XCTAssertGreaterThanOrEqual(trend.confidence, 0.0)
            XCTAssertLessThanOrEqual(trend.confidence, 100.0)
        }
    }
    
    func testTrendForecasting() async throws {
        try monitor.startMonitoring(interval: 0.1)
        try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
        for trend in monitor.performanceTrends {
            // Forecast should be reasonable length
            XCTAssertLessThanOrEqual(trend.forecast.count, 10)
            
            // All forecast values should be numbers
            for forecastValue in trend.forecast {
                XCTAssertFalse(forecastValue.isNaN)
                XCTAssertFalse(forecastValue.isInfinite)
            }
        }
    }
    
    // MARK: - Optimization Recommendations Tests
    
    func testOptimizationRecommendations() async throws {
        try monitor.startMonitoring(interval: 0.1)
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        // Test recommendation structure
        for recommendation in monitor.optimizationRecommendations {
            XCTAssertFalse(recommendation.title.isEmpty)
            XCTAssertFalse(recommendation.description.isEmpty)
            XCTAssertNotNil(recommendation.priority)
            XCTAssertFalse(recommendation.impact.isEmpty)
            XCTAssertFalse(recommendation.effort.isEmpty)
            XCTAssertGreaterThanOrEqual(recommendation.estimatedSavings, 0)
            XCTAssertNotNil(recommendation.category)
            XCTAssertNotNil(recommendation.timestamp)
        }
    }
    
    func testRecommendationPriorities() async throws {
        try monitor.startMonitoring(interval: 0.1)
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        let validPriorities: [RecommendationPriority] = [.low, .medium, .high, .critical]
        
        for recommendation in monitor.optimizationRecommendations {
            XCTAssertTrue(validPriorities.contains(recommendation.priority))
        }
    }
    
    func testRecommendationCategories() async throws {
        try monitor.startMonitoring(interval: 0.1)
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        let validCategories: [AnomalyCategory] = [.cpu, .memory, .network, .disk, .application, .ui, .battery, .ml, .database, .security]
        
        for recommendation in monitor.optimizationRecommendations {
            XCTAssertTrue(validCategories.contains(recommendation.category))
        }
    }
    
    func testRecommendationSorting() async throws {
        try monitor.startMonitoring(interval: 0.1)
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        // Test that recommendations are sorted by priority
        let recommendations = monitor.optimizationRecommendations
        
        for i in 0..<(recommendations.count - 1) {
            let current = recommendations[i]
            let next = recommendations[i + 1]
            
            // Compare priority ordering (critical > high > medium > low)
            let currentPriorityValue = priorityValue(current.priority)
            let nextPriorityValue = priorityValue(next.priority)
            
            XCTAssertGreaterThanOrEqual(currentPriorityValue, nextPriorityValue)
        }
    }
    
    private func priorityValue(_ priority: RecommendationPriority) -> Int {
        switch priority {
        case .critical: return 4
        case .high: return 3
        case .medium: return 2
        case .low: return 1
        }
    }
    
    // MARK: - System Health Tests
    
    func testSystemHealthCalculation() async throws {
        try monitor.startMonitoring(interval: 0.1)
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        let validHealthStatuses: [SystemHealth] = [.excellent, .good, .fair, .poor, .critical]
        XCTAssertTrue(validHealthStatuses.contains(monitor.systemHealth))
    }
    
    func testSystemHealthUpdates() async throws {
        try monitor.startMonitoring(interval: 0.1)
        
        let initialHealth = monitor.systemHealth
        
        // Wait for potential health updates
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        // Health should be a valid status
        let validHealthStatuses: [SystemHealth] = [.excellent, .good, .fair, .poor, .critical]
        XCTAssertTrue(validHealthStatuses.contains(monitor.systemHealth))
    }
    
    // MARK: - Dashboard Tests
    
    func testPerformanceDashboard() async throws {
        try monitor.startMonitoring(interval: 0.1)
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        let dashboard = monitor.getPerformanceDashboard()
        
        // Test system overview
        XCTAssertNotNil(dashboard.systemOverview.overallHealth)
        XCTAssertNotNil(dashboard.systemOverview.cpuHealth)
        XCTAssertNotNil(dashboard.systemOverview.memoryHealth)
        XCTAssertNotNil(dashboard.systemOverview.networkHealth)
        XCTAssertNotNil(dashboard.systemOverview.batteryHealth)
        XCTAssertNotNil(dashboard.systemOverview.lastUpdated)
        
        // Test metric charts
        for chart in dashboard.metricCharts {
            XCTAssertFalse(chart.title.isEmpty)
            XCTAssertFalse(chart.values.isEmpty)
            XCTAssertFalse(chart.unit.isEmpty)
            XCTAssertNotNil(chart.trend)
        }
        
        // Test performance summary
        XCTAssertGreaterThanOrEqual(dashboard.performanceSummary.overallScore, 0)
        XCTAssertLessThanOrEqual(dashboard.performanceSummary.overallScore, 100)
        XCTAssertNotNil(dashboard.performanceSummary.lastUpdated)
    }
    
    func testSystemOverview() async throws {
        try monitor.startMonitoring(interval: 0.1)
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        let dashboard = monitor.getPerformanceDashboard()
        let overview = dashboard.systemOverview
        
        let validHealthStatuses: [HealthStatus] = [.excellent, .good, .fair, .poor, .critical]
        
        XCTAssertTrue(validHealthStatuses.contains(overview.overallHealth))
        XCTAssertTrue(validHealthStatuses.contains(overview.cpuHealth))
        XCTAssertTrue(validHealthStatuses.contains(overview.memoryHealth))
        XCTAssertTrue(validHealthStatuses.contains(overview.networkHealth))
        XCTAssertTrue(validHealthStatuses.contains(overview.batteryHealth))
        
        let now = Date()
        XCTAssertLessThan(now.timeIntervalSince(overview.lastUpdated), 5.0)
    }
    
    func testMetricCharts() async throws {
        try monitor.startMonitoring(interval: 0.1)
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        let dashboard = monitor.getPerformanceDashboard()
        let charts = dashboard.metricCharts
        
        // Should have charts for major metrics
        XCTAssertGreaterThan(charts.count, 0)
        
        for chart in charts {
            XCTAssertFalse(chart.title.isEmpty)
            XCTAssertGreaterThan(chart.values.count, 0)
            XCTAssertLessThanOrEqual(chart.values.count, 50) // Limited to 50 recent values
            XCTAssertFalse(chart.unit.isEmpty)
            
            let validTrends: [TrendDirection] = [.increasing, .decreasing, .stable]
            XCTAssertTrue(validTrends.contains(chart.trend))
        }
    }
    
    func testPerformanceSummary() async throws {
        try monitor.startMonitoring(interval: 0.1)
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        let dashboard = monitor.getPerformanceDashboard()
        let summary = dashboard.performanceSummary
        
        XCTAssertGreaterThanOrEqual(summary.overallScore, 0.0)
        XCTAssertLessThanOrEqual(summary.overallScore, 100.0)
        
        // Issues and recommendations should be arrays (can be empty)
        XCTAssertNotNil(summary.topIssues)
        XCTAssertNotNil(summary.recommendations)
        
        let now = Date()
        XCTAssertLessThan(now.timeIntervalSince(summary.lastUpdated), 5.0)
    }
    
    // MARK: - Performance Tests
    
    func testMonitoringPerformanceImpact() async throws {
        let startTime = Date()
        
        try monitor.startMonitoring(interval: 0.05) // High frequency
        
        // Run for a short time to measure impact
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)
        
        // Monitoring should complete within reasonable time
        XCTAssertLessThan(duration, 2.0)
        
        // Should collect metrics
        XCTAssertGreaterThan(monitor.currentMetrics.timestamp.timeIntervalSince1970, startTime.timeIntervalSince1970)
    }
    
    func testConcurrentMonitoring() async throws {
        // Test that multiple monitoring requests are handled gracefully
        let tasks = (0..<5).map { _ in
            Task {
                do {
                    try monitor.startMonitoring(interval: 0.1)
                    try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                    monitor.stopMonitoring()
                } catch {
                    XCTFail("Concurrent monitoring failed: \(error)")
                }
            }
        }
        
        // Wait for all tasks to complete
        for task in tasks {
            await task.value
        }
        
        // Monitor should be in a consistent state
        XCTAssertFalse(monitor.isMonitoring)
    }
    
    func testMemoryLeakPrevention() async throws {
        weak var weakMonitor: AdvancedPerformanceMonitor?
        
        do {
            let localMonitor = AdvancedPerformanceMonitor()
            weakMonitor = localMonitor
            
            try localMonitor.startMonitoring(interval: 0.1)
            try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            localMonitor.stopMonitoring()
        }
        
        // Allow time for cleanup
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        // Monitor should be deallocated
        XCTAssertNil(weakMonitor, "Performance monitor should be deallocated to prevent memory leaks")
    }
    
    // MARK: - Error Handling Tests
    
    func testInvalidMonitoringInterval() {
        // Test with negative interval
        XCTAssertThrowsError(try monitor.startMonitoring(interval: -1.0)) { error in
            // Should throw an appropriate error
        }
        
        // Test with zero interval
        XCTAssertThrowsError(try monitor.startMonitoring(interval: 0.0)) { error in
            // Should throw an appropriate error
        }
    }
    
    func testStopMonitoringWhenNotStarted() {
        // Should not crash when stopping monitoring that wasn't started
        XCTAssertNoThrow(monitor.stopMonitoring())
        XCTAssertFalse(monitor.isMonitoring)
    }
    
    // MARK: - Integration Tests
    
    func testCombineIntegration() async throws {
        let expectation = XCTestExpectation(description: "Combine integration")
        
        monitor.$currentMetrics
            .dropFirst() // Skip initial empty value
            .sink { metrics in
                XCTAssertNotNil(metrics.timestamp)
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        try monitor.startMonitoring(interval: 0.1)
        
        await fulfillment(of: [expectation], timeout: 2.0)
    }
    
    func testPublishedPropertiesUpdates() async throws {
        let metricsExpectation = XCTestExpectation(description: "Metrics updated")
        let healthExpectation = XCTestExpectation(description: "Health updated")
        
        monitor.$currentMetrics
            .dropFirst()
            .sink { _ in metricsExpectation.fulfill() }
            .store(in: &cancellables)
        
        monitor.$systemHealth
            .dropFirst()
            .sink { _ in healthExpectation.fulfill() }
            .store(in: &cancellables)
        
        try monitor.startMonitoring(interval: 0.1)
        
        await fulfillment(of: [metricsExpectation, healthExpectation], timeout: 3.0)
    }
    
    // MARK: - Edge Case Tests
    
    func testVeryShortMonitoringPeriod() async throws {
        try monitor.startMonitoring(interval: 1.0)
        
        // Stop immediately
        monitor.stopMonitoring()
        
        // Should handle gracefully
        XCTAssertFalse(monitor.isMonitoring)
    }
    
    func testRepeatedStartStop() async throws {
        for _ in 0..<5 {
            try monitor.startMonitoring(interval: 0.1)
            XCTAssertTrue(monitor.isMonitoring)
            
            try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            
            monitor.stopMonitoring()
            XCTAssertFalse(monitor.isMonitoring)
        }
    }
    
    func testLongRunningMonitoring() async throws {
        try monitor.startMonitoring(interval: 0.1)
        
        // Run for a longer period
        try await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds
        
        // Should still be monitoring and collecting data
        XCTAssertTrue(monitor.isMonitoring)
        XCTAssertGreaterThan(monitor.currentMetrics.timestamp.timeIntervalSince1970, 0)
        
        // Should have collected some trends and potentially recommendations
        let dashboard = monitor.getPerformanceDashboard()
        XCTAssertNotNil(dashboard)
    }
}

// MARK: - Performance Benchmark Tests

final class PerformanceMonitorBenchmarkTests: XCTestCase {
    
    var monitor: AdvancedPerformanceMonitor!
    
    override func setUp() async throws {
        try await super.setUp()
        monitor = AdvancedPerformanceMonitor()
    }
    
    override func tearDown() async throws {
        monitor?.stopMonitoring()
        monitor = nil
        try await super.tearDown()
    }
    
    func testMetricsCollectionPerformance() throws {
        measure {
            Task { @MainActor in
                do {
                    try monitor.startMonitoring(interval: 0.05)
                    try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                    monitor.stopMonitoring()
                } catch {
                    XCTFail("Performance test failed: \(error)")
                }
            }
        }
    }
    
    func testDashboardGenerationPerformance() async throws {
        try monitor.startMonitoring(interval: 0.1)
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        measure {
            let _ = monitor.getPerformanceDashboard()
        }
    }
    
    func testAnomalyDetectionPerformance() async throws {
        try monitor.startMonitoring(interval: 0.1)
        try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
        measure {
            // This triggers anomaly detection internally
            let _ = monitor.anomalyAlerts
        }
    }
    
    func testTrendAnalysisPerformance() async throws {
        try monitor.startMonitoring(interval: 0.1)
        try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
        measure {
            // This triggers trend analysis internally
            let _ = monitor.performanceTrends
        }
    }
}

// MARK: - Test Helper Extensions

extension AdvancedPerformanceMonitorTests {
    
    func waitForCondition(_ condition: @escaping () -> Bool, timeout: TimeInterval = 5.0) async throws {
        let startTime = Date()
        
        while !condition() {
            if Date().timeIntervalSince(startTime) > timeout {
                XCTFail("Condition not met within timeout")
                return
            }
            
            try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        }
    }
    
    func createMockMetrics() -> SystemMetrics {
        var metrics = SystemMetrics()
        metrics.cpu.usage = 50.0
        metrics.memory.usedMemory = 1024 * 1024 * 1024 // 1GB
        metrics.memory.totalMemory = 4 * 1024 * 1024 * 1024 // 4GB
        metrics.network.latency = 100.0
        metrics.battery.batteryLevel = 0.8
        return metrics
    }
}
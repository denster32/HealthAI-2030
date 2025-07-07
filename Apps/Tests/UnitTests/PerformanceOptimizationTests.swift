import XCTest
import Combine
@testable import HealthAI2030

@MainActor
final class PerformanceOptimizationTests: XCTestCase {
    var performanceManager: PerformanceOptimizationManager!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        performanceManager = PerformanceOptimizationManager()
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDown() {
        performanceManager.stopMonitoring()
        cancellables.removeAll()
        performanceManager = nil
        super.tearDown()
    }
    
    // MARK: - Real-time Performance Monitoring Tests
    
    func testStartMonitoring() {
        // Given
        XCTAssertFalse(performanceManager.isMonitoring)
        
        // When
        performanceManager.startMonitoring()
        
        // Then
        XCTAssertTrue(performanceManager.isMonitoring)
    }
    
    func testStopMonitoring() {
        // Given
        performanceManager.startMonitoring()
        XCTAssertTrue(performanceManager.isMonitoring)
        
        // When
        performanceManager.stopMonitoring()
        
        // Then
        XCTAssertFalse(performanceManager.isMonitoring)
    }
    
    func testGetCurrentMetrics() async throws {
        // When
        let metrics = try await performanceManager.getCurrentMetrics()
        
        // Then
        XCTAssertGreaterThanOrEqual(metrics.cpuUsage, 0)
        XCTAssertLessThanOrEqual(metrics.cpuUsage, 100)
        XCTAssertGreaterThanOrEqual(metrics.memoryUsage, 0)
        XCTAssertLessThanOrEqual(metrics.memoryUsage, 100)
        XCTAssertGreaterThanOrEqual(metrics.batteryLevel, 0)
        XCTAssertLessThanOrEqual(metrics.batteryLevel, 100)
        XCTAssertGreaterThan(metrics.averageResponseTime, 0)
        XCTAssertGreaterThanOrEqual(metrics.throughput, 0)
        XCTAssertGreaterThanOrEqual(metrics.errorRate, 0)
        XCTAssertLessThanOrEqual(metrics.errorRate, 1)
        XCTAssertGreaterThanOrEqual(metrics.activeConnections, 0)
        XCTAssertNotNil(metrics.timestamp)
    }
    
    func testGetMetricsHistory() async throws {
        // When
        let history = try await performanceManager.getMetricsHistory(timeRange: .lastHour)
        
        // Then
        XCTAssertNotNil(history)
        // Note: In this test implementation, history is empty
    }
    
    func testSetBaseline() async throws {
        // When
        try await performanceManager.setBaseline()
        
        // Then
        // Baseline should be set without error
    }
    
    func testCompareWithBaseline() async throws {
        // Given
        try await performanceManager.setBaseline()
        
        // When
        let comparison = try await performanceManager.compareWithBaseline()
        
        // Then
        XCTAssertNotNil(comparison.baseline)
        XCTAssertNotNil(comparison.current)
        XCTAssertNotNil(comparison.cpuChange)
        XCTAssertNotNil(comparison.memoryChange)
        XCTAssertNotNil(comparison.responseTimeChange)
        XCTAssertNotNil(comparison.throughputChange)
        XCTAssertNotNil(comparison.errorRateChange)
    }
    
    func testCompareWithBaselineWithoutBaseline() async throws {
        // When & Then
        do {
            _ = try await performanceManager.compareWithBaseline()
            XCTFail("Should throw error when no baseline is set")
        } catch {
            XCTAssertTrue(error is PerformanceError)
        }
    }
    
    // MARK: - Bottleneck Identification Tests
    
    func testIdentifyBottlenecks() async throws {
        // When
        let bottlenecks = try await performanceManager.identifyBottlenecks()
        
        // Then
        XCTAssertNotNil(bottlenecks)
        // Bottlenecks may or may not be detected depending on current system state
    }
    
    func testGetBottleneckHistory() async throws {
        // When
        let history = try await performanceManager.getBottleneckHistory(timeRange: .lastDay)
        
        // Then
        XCTAssertNotNil(history)
        // Note: In this test implementation, history is empty
    }
    
    func testAnalyzeBottleneck() async throws {
        // Given
        let bottleneck = PerformanceBottleneck(
            id: UUID(),
            type: .cpu,
            severity: .high,
            impact: 0.3,
            description: "Test bottleneck",
            detectedAt: Date(),
            isResolved: false,
            resolvedAt: nil,
            metadata: [:]
        )
        
        // When
        let analysis = try await performanceManager.analyzeBottleneck(bottleneck)
        
        // Then
        XCTAssertEqual(analysis.bottleneck.id, bottleneck.id)
        XCTAssertNotNil(analysis.rootCause)
        XCTAssertFalse(analysis.recommendations.isEmpty)
        XCTAssertGreaterThan(analysis.estimatedFixTime, 0)
        XCTAssertGreaterThanOrEqual(analysis.priority, 1)
    }
    
    func testSetBottleneckThreshold() async throws {
        // When
        try await performanceManager.setBottleneckThreshold(.cpu, threshold: 80.0)
        
        // Then
        // Should not throw error
    }
    
    // MARK: - Automated Optimization Tests
    
    func testGenerateOptimizationRecommendations() async throws {
        // When
        let recommendations = try await performanceManager.generateOptimizationRecommendations()
        
        // Then
        XCTAssertNotNil(recommendations)
        // Recommendations may or may not be generated depending on current state
    }
    
    func testApplyOptimization() async throws {
        // Given
        let recommendation = OptimizationRecommendation(
            id: UUID(),
            type: .cpuOptimization,
            title: "Test Optimization",
            description: "Test optimization description",
            priority: .medium,
            estimatedImprovement: 0.2,
            implementation: ["Step 1", "Step 2"],
            createdAt: Date(),
            isApplied: false,
            appliedAt: nil
        )
        
        // When
        let result = try await performanceManager.applyOptimization(recommendation)
        
        // Then
        XCTAssertEqual(result.recommendation.id, recommendation.id)
        XCTAssertGreaterThanOrEqual(result.improvement, 0)
        XCTAssertNotNil(result.appliedAt)
        XCTAssertTrue(result.rollbackAvailable)
    }
    
    func testGetOptimizationHistory() async throws {
        // When
        let history = try await performanceManager.getOptimizationHistory()
        
        // Then
        XCTAssertNotNil(history)
        // Note: In this test implementation, history is empty
    }
    
    func testRollbackOptimization() async throws {
        // Given
        let optimizationId = UUID()
        
        // When
        try await performanceManager.rollbackOptimization(optimizationId)
        
        // Then
        // Should not throw error
    }
    
    // MARK: - Performance Regression Detection Tests
    
    func testDetectRegressions() async throws {
        // When
        let regressions = try await performanceManager.detectRegressions()
        
        // Then
        XCTAssertNotNil(regressions)
        // Regressions may or may not be detected depending on current state
    }
    
    func testSetRegressionThreshold() async throws {
        // When
        try await performanceManager.setRegressionThreshold("response_time", threshold: 2.0)
        
        // Then
        // Should not throw error
    }
    
    func testGetRegressionHistory() async throws {
        // When
        let history = try await performanceManager.getRegressionHistory(timeRange: .lastWeek)
        
        // Then
        XCTAssertNotNil(history)
        // Note: In this test implementation, history is empty
    }
    
    func testAcknowledgeRegression() async throws {
        // Given
        let regressionId = UUID()
        
        // When
        try await performanceManager.acknowledgeRegression(regressionId)
        
        // Then
        // Should not throw error
    }
    
    // MARK: - Resource Usage Optimization Tests
    
    func testOptimizeResourceUsage() async throws {
        // When
        let result = try await performanceManager.optimizeResourceUsage()
        
        // Then
        XCTAssertGreaterThanOrEqual(result.memorySaved, 0)
        XCTAssertGreaterThanOrEqual(result.cpuSaved, 0)
        XCTAssertGreaterThanOrEqual(result.batterySaved, 0)
        XCTAssertGreaterThan(result.optimizationTime, 0)
        XCTAssertTrue(result.success)
    }
    
    func testGetResourceUsage() async throws {
        // When
        let usage = try await performanceManager.getResourceUsage()
        
        // Then
        XCTAssertGreaterThanOrEqual(usage.memoryUsage, 0)
        XCTAssertLessThanOrEqual(usage.memoryUsage, 100)
        XCTAssertGreaterThanOrEqual(usage.cpuUsage, 0)
        XCTAssertLessThanOrEqual(usage.cpuUsage, 100)
        XCTAssertGreaterThanOrEqual(usage.diskUsage, 0)
        XCTAssertLessThanOrEqual(usage.diskUsage, 100)
        XCTAssertGreaterThanOrEqual(usage.networkUsage, 0)
        XCTAssertLessThanOrEqual(usage.networkUsage, 100)
        XCTAssertGreaterThanOrEqual(usage.batteryUsage, 0)
        XCTAssertLessThanOrEqual(usage.batteryUsage, 100)
    }
    
    func testSetResourceLimits() async throws {
        // Given
        let limits = ResourceLimits(
            maxMemory: 80.0,
            maxCPU: 90.0,
            maxDisk: 70.0,
            maxNetwork: 50.0
        )
        
        // When
        try await performanceManager.setResourceLimits(limits)
        
        // Then
        // Should not throw error
    }
    
    func testGetResourceLimits() async throws {
        // When
        let limits = try await performanceManager.getResourceLimits()
        
        // Then
        XCTAssertGreaterThan(limits.maxMemory, 0)
        XCTAssertGreaterThan(limits.maxCPU, 0)
        XCTAssertGreaterThan(limits.maxDisk, 0)
        XCTAssertGreaterThan(limits.maxNetwork, 0)
    }
    
    // MARK: - Performance Testing Tests
    
    func testRunPerformanceTest() async throws {
        // Given
        let test = PerformanceTest(
            id: UUID(),
            name: "Test Performance Test",
            description: "A test performance test",
            testType: .loadTest,
            parameters: ["duration": "60", "users": "100"],
            expectedResults: ["response_time": "<2s", "error_rate": "<1%"]
        )
        
        // When
        let result = try await performanceManager.runPerformanceTest(test)
        
        // Then
        XCTAssertEqual(result.test.id, test.id)
        XCTAssertTrue(result.success)
        XCTAssertGreaterThan(result.duration, 0)
        XCTAssertNotNil(result.metrics)
        XCTAssertNotNil(result.completedAt)
    }
    
    func testCreatePerformanceTest() async throws {
        // Given
        let test = PerformanceTest(
            id: UUID(),
            name: "New Test",
            description: "A new test",
            testType: .benchmarkTest,
            parameters: [:],
            expectedResults: [:]
        )
        
        // When
        try await performanceManager.createPerformanceTest(test)
        
        // Then
        // Should not throw error
    }
    
    func testGetPerformanceTests() async throws {
        // When
        let tests = try await performanceManager.getPerformanceTests()
        
        // Then
        XCTAssertNotNil(tests)
        // Note: In this test implementation, tests list is empty
    }
    
    func testSchedulePerformanceTest() async throws {
        // Given
        let test = PerformanceTest(
            id: UUID(),
            name: "Scheduled Test",
            description: "A scheduled test",
            testType: .enduranceTest,
            parameters: [:],
            expectedResults: [:]
        )
        
        let schedule = TestSchedule(
            frequency: "daily",
            startTime: Date(),
            endTime: nil,
            enabled: true
        )
        
        // When
        try await performanceManager.schedulePerformanceTest(test, schedule: schedule)
        
        // Then
        // Should not throw error
    }
    
    func testGetScheduledTests() async throws {
        // When
        let scheduledTests = try await performanceManager.getScheduledTests()
        
        // Then
        XCTAssertNotNil(scheduledTests)
        // Note: In this test implementation, scheduled tests list is empty
    }
    
    // MARK: - Performance Alerts Tests
    
    func testSetPerformanceAlert() async throws {
        // Given
        let alert = PerformanceAlert(
            id: UUID(),
            type: .cpuThreshold,
            threshold: 80.0,
            message: "CPU usage is high",
            severity: .high,
            isActive: true,
            createdAt: Date()
        )
        
        // When
        try await performanceManager.setPerformanceAlert(alert)
        
        // Then
        // Should not throw error
    }
    
    func testGetPerformanceAlerts() async throws {
        // When
        let alerts = try await performanceManager.getPerformanceAlerts()
        
        // Then
        XCTAssertNotNil(alerts)
        // Note: In this test implementation, alerts list is empty
    }
    
    func testAcknowledgeAlert() async throws {
        // Given
        let alertId = UUID()
        
        // When
        try await performanceManager.acknowledgeAlert(alertId)
        
        // Then
        // Should not throw error
    }
    
    // MARK: - Performance Reports Tests
    
    func testGeneratePerformanceReport() async throws {
        // When
        let report = try await performanceManager.generatePerformanceReport(timeRange: .lastDay)
        
        // Then
        XCTAssertEqual(report.timeRange, .lastDay)
        XCTAssertNotNil(report.metrics)
        XCTAssertNotNil(report.bottlenecks)
        XCTAssertNotNil(report.regressions)
        XCTAssertNotNil(report.optimizations)
        XCTAssertNotNil(report.summary)
        XCTAssertNotNil(report.generatedAt)
        
        // Verify summary
        XCTAssertGreaterThanOrEqual(report.summary.averageCPUUsage, 0)
        XCTAssertLessThanOrEqual(report.summary.averageCPUUsage, 100)
        XCTAssertGreaterThanOrEqual(report.summary.averageMemoryUsage, 0)
        XCTAssertLessThanOrEqual(report.summary.averageMemoryUsage, 100)
        XCTAssertGreaterThanOrEqual(report.summary.averageResponseTime, 0)
        XCTAssertGreaterThanOrEqual(report.summary.totalBottlenecks, 0)
        XCTAssertGreaterThanOrEqual(report.summary.totalRegressions, 0)
        XCTAssertGreaterThanOrEqual(report.summary.criticalIssues, 0)
    }
    
    func testExportPerformanceData() async throws {
        // When
        let jsonData = try await performanceManager.exportPerformanceData(format: .json)
        let csvData = try await performanceManager.exportPerformanceData(format: .csv)
        let excelData = try await performanceManager.exportPerformanceData(format: .excel)
        
        // Then
        XCTAssertNotNil(jsonData)
        XCTAssertNotNil(csvData)
        XCTAssertNotNil(excelData)
    }
    
    // MARK: - Configuration Tests
    
    func testEnablePerformanceMonitoring() {
        // Given
        XCTAssertFalse(performanceManager.isMonitoring)
        
        // When
        performanceManager.enablePerformanceMonitoring()
        
        // Then
        XCTAssertTrue(performanceManager.isMonitoring)
    }
    
    func testDisablePerformanceMonitoring() {
        // Given
        performanceManager.enablePerformanceMonitoring()
        XCTAssertTrue(performanceManager.isMonitoring)
        
        // When
        performanceManager.disablePerformanceMonitoring()
        
        // Then
        XCTAssertFalse(performanceManager.isMonitoring)
    }
    
    func testSetMonitoringInterval() {
        // When
        performanceManager.setMonitoringInterval(10.0)
        
        // Then
        // Should not throw error
    }
    
    func testGetMonitoringConfiguration() {
        // When
        let config = performanceManager.getMonitoringConfiguration()
        
        // Then
        XCTAssertGreaterThan(config.collectionInterval, 0)
        XCTAssertNotNil(config.enabled)
        XCTAssertFalse(config.metrics.isEmpty)
    }
    
    // MARK: - Published Properties Tests
    
    func testPublishedProperties() {
        // Given
        let expectation = XCTestExpectation(description: "Published properties updated")
        
        // When
        performanceManager.$currentMetrics
            .dropFirst()
            .sink { _ in
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // Start monitoring to trigger metrics update
        performanceManager.startMonitoring()
        
        // Then
        wait(for: [expectation], timeout: 10.0)
    }
    
    func testBottlenecksPublishedProperty() async throws {
        // Given
        let expectation = XCTestExpectation(description: "Bottlenecks updated")
        
        performanceManager.$bottlenecks
            .dropFirst()
            .sink { _ in
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // When
        _ = try await performanceManager.identifyBottlenecks()
        
        // Then
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testRecommendationsPublishedProperty() async throws {
        // Given
        let expectation = XCTestExpectation(description: "Recommendations updated")
        
        performanceManager.$recommendations
            .dropFirst()
            .sink { _ in
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // When
        _ = try await performanceManager.generateOptimizationRecommendations()
        
        // Then
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testRegressionsPublishedProperty() async throws {
        // Given
        let expectation = XCTestExpectation(description: "Regressions updated")
        
        performanceManager.$regressions
            .dropFirst()
            .sink { _ in
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // When
        _ = try await performanceManager.detectRegressions()
        
        // Then
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testLoadingState() async throws {
        // Given
        let expectation = XCTestExpectation(description: "Loading state changes")
        var loadingStates: [Bool] = []
        
        performanceManager.$isLoading
            .sink { loading in
                loadingStates.append(loading)
                if loadingStates.count >= 2 {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When
        _ = try await performanceManager.identifyBottlenecks()
        
        // Then
        wait(for: [expectation], timeout: 5.0)
        XCTAssertTrue(loadingStates.contains(true))
        XCTAssertTrue(loadingStates.contains(false))
    }
    
    func testErrorHandling() async throws {
        // Given
        let expectation = XCTestExpectation(description: "Error state updated")
        
        performanceManager.$error
            .dropFirst()
            .sink { error in
                if error != nil {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When
        // Try to compare with baseline without setting one
        do {
            _ = try await performanceManager.compareWithBaseline()
        } catch {
            // Expected error
        }
        
        // Then
        wait(for: [expectation], timeout: 5.0)
    }
    
    // MARK: - Model Validation Tests
    
    func testPerformanceMetricsValidation() {
        // Given
        let metrics = PerformanceMetrics(
            cpuUsage: 50.0,
            memoryUsage: 60.0,
            diskUsage: 40.0,
            networkUsage: 30.0,
            batteryLevel: 80.0,
            averageResponseTime: 1.5,
            throughput: 500.0,
            errorRate: 0.01,
            activeConnections: 50,
            timestamp: Date()
        )
        
        // Then
        XCTAssertEqual(metrics.cpuUsage, 50.0)
        XCTAssertEqual(metrics.memoryUsage, 60.0)
        XCTAssertEqual(metrics.diskUsage, 40.0)
        XCTAssertEqual(metrics.networkUsage, 30.0)
        XCTAssertEqual(metrics.batteryLevel, 80.0)
        XCTAssertEqual(metrics.averageResponseTime, 1.5)
        XCTAssertEqual(metrics.throughput, 500.0)
        XCTAssertEqual(metrics.errorRate, 0.01)
        XCTAssertEqual(metrics.activeConnections, 50)
        XCTAssertNotNil(metrics.timestamp)
    }
    
    func testPerformanceBottleneckValidation() {
        // Given
        let bottleneck = PerformanceBottleneck(
            id: UUID(),
            type: .cpu,
            severity: .high,
            impact: 0.3,
            description: "High CPU usage",
            detectedAt: Date(),
            isResolved: false,
            resolvedAt: nil,
            metadata: ["source": "test"]
        )
        
        // Then
        XCTAssertNotNil(bottleneck.id)
        XCTAssertEqual(bottleneck.type, .cpu)
        XCTAssertEqual(bottleneck.severity, .high)
        XCTAssertEqual(bottleneck.impact, 0.3)
        XCTAssertEqual(bottleneck.description, "High CPU usage")
        XCTAssertNotNil(bottleneck.detectedAt)
        XCTAssertFalse(bottleneck.isResolved)
        XCTAssertNil(bottleneck.resolvedAt)
        XCTAssertEqual(bottleneck.metadata["source"], "test")
    }
    
    func testOptimizationRecommendationValidation() {
        // Given
        let recommendation = OptimizationRecommendation(
            id: UUID(),
            type: .memoryOptimization,
            title: "Optimize Memory",
            description: "Reduce memory usage",
            priority: .high,
            estimatedImprovement: 0.4,
            implementation: ["Step 1", "Step 2"],
            createdAt: Date(),
            isApplied: false,
            appliedAt: nil
        )
        
        // Then
        XCTAssertNotNil(recommendation.id)
        XCTAssertEqual(recommendation.type, .memoryOptimization)
        XCTAssertEqual(recommendation.title, "Optimize Memory")
        XCTAssertEqual(recommendation.description, "Reduce memory usage")
        XCTAssertEqual(recommendation.priority, .high)
        XCTAssertEqual(recommendation.estimatedImprovement, 0.4)
        XCTAssertEqual(recommendation.implementation.count, 2)
        XCTAssertNotNil(recommendation.createdAt)
        XCTAssertFalse(recommendation.isApplied)
        XCTAssertNil(recommendation.appliedAt)
    }
    
    func testPerformanceRegressionValidation() {
        // Given
        let regression = PerformanceRegression(
            id: UUID(),
            metric: "response_time",
            severity: .medium,
            impact: 0.2,
            detectedAt: Date(),
            baselineValue: 1.0,
            currentValue: 1.5,
            isAcknowledged: false,
            acknowledgedAt: nil
        )
        
        // Then
        XCTAssertNotNil(regression.id)
        XCTAssertEqual(regression.metric, "response_time")
        XCTAssertEqual(regression.severity, .medium)
        XCTAssertEqual(regression.impact, 0.2)
        XCTAssertNotNil(regression.detectedAt)
        XCTAssertEqual(regression.baselineValue, 1.0)
        XCTAssertEqual(regression.currentValue, 1.5)
        XCTAssertFalse(regression.isAcknowledged)
        XCTAssertNil(regression.acknowledgedAt)
    }
    
    func testPerformanceComparisonValidation() {
        // Given
        let baseline = PerformanceMetrics(
            cpuUsage: 30.0,
            memoryUsage: 50.0,
            diskUsage: 40.0,
            networkUsage: 20.0,
            batteryLevel: 90.0,
            averageResponseTime: 1.0,
            throughput: 600.0,
            errorRate: 0.005,
            activeConnections: 40,
            timestamp: Date()
        )
        
        let current = PerformanceMetrics(
            cpuUsage: 60.0,
            memoryUsage: 70.0,
            diskUsage: 45.0,
            networkUsage: 35.0,
            batteryLevel: 85.0,
            averageResponseTime: 1.5,
            throughput: 500.0,
            errorRate: 0.01,
            activeConnections: 60,
            timestamp: Date()
        )
        
        let comparison = PerformanceComparison(
            baseline: baseline,
            current: current,
            cpuChange: 30.0,
            memoryChange: 20.0,
            responseTimeChange: 0.5,
            throughputChange: -100.0,
            errorRateChange: 0.005
        )
        
        // Then
        XCTAssertEqual(comparison.baseline.cpuUsage, 30.0)
        XCTAssertEqual(comparison.current.cpuUsage, 60.0)
        XCTAssertEqual(comparison.cpuChange, 30.0)
        XCTAssertEqual(comparison.memoryChange, 20.0)
        XCTAssertEqual(comparison.responseTimeChange, 0.5)
        XCTAssertEqual(comparison.throughputChange, -100.0)
        XCTAssertEqual(comparison.errorRateChange, 0.005)
    }
    
    func testResourceOptimizationResultValidation() {
        // Given
        let result = ResourceOptimizationResult(
            memorySaved: 25.0,
            cpuSaved: 15.0,
            batterySaved: 10.0,
            optimizationTime: 5.0,
            success: true
        )
        
        // Then
        XCTAssertEqual(result.memorySaved, 25.0)
        XCTAssertEqual(result.cpuSaved, 15.0)
        XCTAssertEqual(result.batterySaved, 10.0)
        XCTAssertEqual(result.optimizationTime, 5.0)
        XCTAssertTrue(result.success)
    }
    
    func testPerformanceTestValidation() {
        // Given
        let test = PerformanceTest(
            id: UUID(),
            name: "Load Test",
            description: "Test system under load",
            testType: .loadTest,
            parameters: ["duration": "300", "users": "1000"],
            expectedResults: ["response_time": "<2s", "error_rate": "<1%"]
        )
        
        // Then
        XCTAssertNotNil(test.id)
        XCTAssertEqual(test.name, "Load Test")
        XCTAssertEqual(test.description, "Test system under load")
        XCTAssertEqual(test.testType, .loadTest)
        XCTAssertEqual(test.parameters["duration"], "300")
        XCTAssertEqual(test.parameters["users"], "1000")
        XCTAssertEqual(test.expectedResults["response_time"], "<2s")
        XCTAssertEqual(test.expectedResults["error_rate"], "<1%")
    }
    
    func testPerformanceReportValidation() {
        // Given
        let summary = PerformanceSummary(
            averageCPUUsage: 45.0,
            averageMemoryUsage: 65.0,
            averageResponseTime: 1.2,
            totalBottlenecks: 2,
            totalRegressions: 1,
            criticalIssues: 0,
            overallHealth: .fair
        )
        
        let report = PerformanceReport(
            timeRange: .lastDay,
            metrics: [],
            bottlenecks: [],
            regressions: [],
            optimizations: [],
            summary: summary,
            generatedAt: Date()
        )
        
        // Then
        XCTAssertEqual(report.timeRange, .lastDay)
        XCTAssertNotNil(report.metrics)
        XCTAssertNotNil(report.bottlenecks)
        XCTAssertNotNil(report.regressions)
        XCTAssertNotNil(report.optimizations)
        XCTAssertEqual(report.summary.averageCPUUsage, 45.0)
        XCTAssertEqual(report.summary.averageMemoryUsage, 65.0)
        XCTAssertEqual(report.summary.averageResponseTime, 1.2)
        XCTAssertEqual(report.summary.totalBottlenecks, 2)
        XCTAssertEqual(report.summary.totalRegressions, 1)
        XCTAssertEqual(report.summary.criticalIssues, 0)
        XCTAssertEqual(report.summary.overallHealth, .fair)
        XCTAssertNotNil(report.generatedAt)
    }
}

// MARK: - Supporting Extensions

extension TimeRange {
    static let lastHour = TimeRange(start: Date().addingTimeInterval(-3600), end: Date())
    static let lastDay = TimeRange(start: Date().addingTimeInterval(-86400), end: Date())
    static let lastWeek = TimeRange(start: Date().addingTimeInterval(-604800), end: Date())
}

struct TimeRange: Equatable {
    let start: Date
    let end: Date
} 
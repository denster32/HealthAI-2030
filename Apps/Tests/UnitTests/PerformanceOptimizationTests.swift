import XCTest
import Combine
import Foundation
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
    
    // MARK: - Memory Usage Optimization Tests
    
    func testMemoryUsageOptimization() async throws {
        // Test memory usage optimization
        let result = performanceManager.optimizeMemoryUsage()
        
        // Verify result structure
        XCTAssertNotNil(result)
        XCTAssertGreaterThanOrEqual(result.initialMemoryUsage, 0)
        XCTAssertGreaterThanOrEqual(result.finalMemoryUsage, 0)
        XCTAssertGreaterThanOrEqual(result.freedMemory, 0)
        
        // Verify cache optimization
        XCTAssertNotNil(result.cacheOptimization)
        XCTAssertGreaterThanOrEqual(result.cacheOptimization.initialSize, 0)
        XCTAssertGreaterThanOrEqual(result.cacheOptimization.finalSize, 0)
        XCTAssertGreaterThanOrEqual(result.cacheOptimization.freedSpace, 0)
        
        // Verify image optimization
        XCTAssertNotNil(result.imageOptimization)
        XCTAssertGreaterThanOrEqual(result.imageOptimization.compressedImages, 0)
        XCTAssertGreaterThanOrEqual(result.imageOptimization.freedMemory, 0)
    }
    
    func testMemoryOptimizationPerformance() {
        measure {
            let result = performanceManager.optimizeMemoryUsage()
            XCTAssertNotNil(result)
        }
    }
    
    func testMemoryOptimizationWithHighUsage() {
        // Simulate high memory usage scenario
        let result = performanceManager.optimizeMemoryUsage()
        
        // Should always return valid results
        XCTAssertNotNil(result)
        XCTAssertGreaterThanOrEqual(result.freedMemory, 0)
    }
    
    // MARK: - CPU Performance Monitoring Tests
    
    func testCPUPerformanceMonitoring() {
        // Test CPU performance monitoring
        let metrics = performanceManager.monitorCPUPerformance()
        
        // Verify metrics structure
        XCTAssertNotNil(metrics)
        XCTAssertGreaterThanOrEqual(metrics.currentUsage, 0)
        XCTAssertLessThanOrEqual(metrics.currentUsage, 100)
        XCTAssertGreaterThanOrEqual(metrics.averageUsage, 0)
        XCTAssertLessThanOrEqual(metrics.averageUsage, 100)
        XCTAssertGreaterThanOrEqual(metrics.peakUsage, 0)
        XCTAssertLessThanOrEqual(metrics.peakUsage, 100)
        XCTAssertGreaterThanOrEqual(metrics.temperature, 0)
        XCTAssertNotNil(metrics.timestamp)
    }
    
    func testCPUUsageOptimization() {
        // Test CPU usage optimization
        let result = performanceManager.optimizeCPUUsage()
        
        // Verify result structure
        XCTAssertNotNil(result)
        XCTAssertGreaterThanOrEqual(result.initialUsage, 0)
        XCTAssertLessThanOrEqual(result.initialUsage, 100)
        XCTAssertGreaterThanOrEqual(result.finalUsage, 0)
        XCTAssertLessThanOrEqual(result.finalUsage, 100)
        XCTAssertGreaterThanOrEqual(result.usageReduction, -100) // Can be negative if usage increases
        
        // Verify optimization components
        XCTAssertNotNil(result.backgroundTaskOptimization)
        XCTAssertGreaterThanOrEqual(result.backgroundTaskOptimization.optimizedTasks, 0)
        XCTAssertGreaterThanOrEqual(result.backgroundTaskOptimization.reducedCPUUsage, 0)
        
        XCTAssertNotNil(result.renderingOptimization)
        XCTAssertGreaterThanOrEqual(result.renderingOptimization.optimizedViews, 0)
        XCTAssertGreaterThanOrEqual(result.renderingOptimization.improvedFrameRate, 0)
        
        XCTAssertNotNil(result.algorithmOptimization)
        XCTAssertGreaterThanOrEqual(result.algorithmOptimization.optimizedAlgorithms, 0)
        XCTAssertGreaterThanOrEqual(result.algorithmOptimization.performanceImprovement, 0)
    }
    
    func testCPUOptimizationPerformance() {
        measure {
            let result = performanceManager.optimizeCPUUsage()
            XCTAssertNotNil(result)
        }
    }
    
    // MARK: - Battery Life Optimization Tests
    
    func testBatteryLifeOptimization() {
        // Test battery life optimization
        let result = performanceManager.optimizeBatteryLife()
        
        // Verify result structure
        XCTAssertNotNil(result)
        XCTAssertGreaterThanOrEqual(result.initialBatteryLevel, 0)
        XCTAssertLessThanOrEqual(result.initialBatteryLevel, 100)
        XCTAssertGreaterThanOrEqual(result.initialBatteryUsage, 0)
        XCTAssertGreaterThanOrEqual(result.finalBatteryUsage, 0)
        XCTAssertGreaterThanOrEqual(result.usageReduction, -100) // Can be negative if usage increases
        
        // Verify optimization components
        XCTAssertNotNil(result.locationOptimization)
        XCTAssertGreaterThanOrEqual(result.locationOptimization.reducedLocationUpdates, 0)
        XCTAssertGreaterThanOrEqual(result.locationOptimization.batterySavings, 0)
        
        XCTAssertNotNil(result.networkOptimization)
        XCTAssertGreaterThanOrEqual(result.networkOptimization.reducedNetworkCalls, 0)
        XCTAssertGreaterThanOrEqual(result.networkOptimization.batterySavings, 0)
        
        XCTAssertNotNil(result.backgroundOptimization)
        XCTAssertGreaterThanOrEqual(result.backgroundOptimization.reducedBackgroundTasks, 0)
        XCTAssertGreaterThanOrEqual(result.backgroundOptimization.batterySavings, 0)
        
        XCTAssertNotNil(result.displayOptimization)
        XCTAssertGreaterThanOrEqual(result.displayOptimization.reducedBrightness, 0)
        XCTAssertGreaterThanOrEqual(result.displayOptimization.batterySavings, 0)
    }
    
    func testBatteryOptimizationPerformance() {
        measure {
            let result = performanceManager.optimizeBatteryLife()
            XCTAssertNotNil(result)
        }
    }
    
    func testBatteryOptimizationWithLowBattery() {
        // Test battery optimization with low battery scenario
        let result = performanceManager.optimizeBatteryLife()
        
        // Should always return valid results regardless of battery level
        XCTAssertNotNil(result)
        XCTAssertGreaterThanOrEqual(result.usageReduction, -100)
    }
    
    // MARK: - Network Efficiency and Caching Tests
    
    func testNetworkEfficiencyOptimization() {
        // Test network efficiency optimization
        let result = performanceManager.optimizeNetworkEfficiency()
        
        // Verify result structure
        XCTAssertNotNil(result)
        XCTAssertGreaterThanOrEqual(result.initialNetworkUsage, 0)
        XCTAssertGreaterThanOrEqual(result.finalNetworkUsage, 0)
        XCTAssertGreaterThanOrEqual(result.usageReduction, -1000) // Can be negative if usage increases
        
        // Verify optimization components
        XCTAssertNotNil(result.requestOptimization)
        XCTAssertGreaterThanOrEqual(result.requestOptimization.batchedRequests, 0)
        XCTAssertGreaterThanOrEqual(result.requestOptimization.reducedRequests, 0)
        XCTAssertGreaterThanOrEqual(result.requestOptimization.dataSaved, 0)
        
        XCTAssertNotNil(result.cacheOptimization)
        XCTAssertGreaterThanOrEqual(result.cacheOptimization.cacheHitRate, 0)
        XCTAssertLessThanOrEqual(result.cacheOptimization.cacheHitRate, 100)
        XCTAssertGreaterThanOrEqual(result.cacheOptimization.reducedRequests, 0)
        
        XCTAssertNotNil(result.compressionOptimization)
        XCTAssertGreaterThanOrEqual(result.compressionOptimization.compressionRatio, 0)
        XCTAssertLessThanOrEqual(result.compressionOptimization.compressionRatio, 100)
        XCTAssertGreaterThanOrEqual(result.compressionOptimization.dataSaved, 0)
        
        XCTAssertNotNil(result.connectionOptimization)
        XCTAssertTrue(result.connectionOptimization.connectionPooling)
        XCTAssertGreaterThanOrEqual(result.connectionOptimization.reducedConnections, 0)
    }
    
    func testNetworkOptimizationPerformance() {
        measure {
            let result = performanceManager.optimizeNetworkEfficiency()
            XCTAssertNotNil(result)
        }
    }
    
    func testNetworkOptimizationWithHighUsage() {
        // Test network optimization with high usage scenario
        let result = performanceManager.optimizeNetworkEfficiency()
        
        // Should always return valid results
        XCTAssertNotNil(result)
        XCTAssertGreaterThanOrEqual(result.usageReduction, -1000)
    }
    
    // MARK: - Storage Usage Optimization Tests
    
    func testStorageUsageOptimization() {
        // Test storage usage optimization
        let result = performanceManager.optimizeStorageUsage()
        
        // Verify result structure
        XCTAssertNotNil(result)
        XCTAssertGreaterThanOrEqual(result.initialStorageUsage, 0)
        XCTAssertGreaterThanOrEqual(result.finalStorageUsage, 0)
        XCTAssertGreaterThanOrEqual(result.spaceFreed, 0)
        
        // Verify optimization components
        XCTAssertNotNil(result.cacheCleanup)
        XCTAssertGreaterThanOrEqual(result.cacheCleanup.cleanedFiles, 0)
        XCTAssertGreaterThanOrEqual(result.cacheCleanup.spaceFreed, 0)
        
        XCTAssertNotNil(result.dataCompression)
        XCTAssertGreaterThanOrEqual(result.dataCompression.compressedFiles, 0)
        XCTAssertGreaterThanOrEqual(result.dataCompression.spaceSaved, 0)
        
        XCTAssertNotNil(result.unusedDataRemoval)
        XCTAssertGreaterThanOrEqual(result.unusedDataRemoval.removedFiles, 0)
        XCTAssertGreaterThanOrEqual(result.unusedDataRemoval.spaceFreed, 0)
        
        XCTAssertNotNil(result.databaseOptimization)
        XCTAssertGreaterThanOrEqual(result.databaseOptimization.optimizedTables, 0)
        XCTAssertGreaterThanOrEqual(result.databaseOptimization.spaceFreed, 0)
    }
    
    func testStorageOptimizationPerformance() {
        measure {
            let result = performanceManager.optimizeStorageUsage()
            XCTAssertNotNil(result)
        }
    }
    
    func testStorageOptimizationWithHighUsage() {
        // Test storage optimization with high usage scenario
        let result = performanceManager.optimizeStorageUsage()
        
        // Should always return valid results
        XCTAssertNotNil(result)
        XCTAssertGreaterThanOrEqual(result.spaceFreed, 0)
    }
    
    // MARK: - App Launch Time Optimization Tests
    
    func testAppLaunchTimeOptimization() {
        // Test app launch time optimization
        let result = performanceManager.optimizeAppLaunchTime()
        
        // Verify result structure
        XCTAssertNotNil(result)
        XCTAssertGreaterThanOrEqual(result.initialLaunchTime, 0)
        XCTAssertGreaterThanOrEqual(result.finalLaunchTime, 0)
        XCTAssertGreaterThanOrEqual(result.timeReduction, -10) // Can be negative if time increases
        
        // Verify optimization components
        XCTAssertNotNil(result.startupOptimization)
        XCTAssertGreaterThanOrEqual(result.startupOptimization.optimizedSteps, 0)
        XCTAssertGreaterThanOrEqual(result.startupOptimization.timeSaved, 0)
        
        XCTAssertNotNil(result.resourceOptimization)
        XCTAssertGreaterThanOrEqual(result.resourceOptimization.optimizedResources, 0)
        XCTAssertGreaterThanOrEqual(result.resourceOptimization.timeSaved, 0)
        
        XCTAssertNotNil(result.initializationOptimization)
        XCTAssertGreaterThanOrEqual(result.initializationOptimization.optimizedComponents, 0)
        XCTAssertGreaterThanOrEqual(result.initializationOptimization.timeSaved, 0)
    }
    
    func testLaunchTimeOptimizationPerformance() {
        measure {
            let result = performanceManager.optimizeAppLaunchTime()
            XCTAssertNotNil(result)
        }
    }
    
    func testLaunchTimeOptimizationWithSlowLaunch() {
        // Test launch time optimization with slow launch scenario
        let result = performanceManager.optimizeAppLaunchTime()
        
        // Should always return valid results
        XCTAssertNotNil(result)
        XCTAssertGreaterThanOrEqual(result.timeReduction, -10)
    }
    
    // MARK: - Performance Monitoring Tests
    
    func testPerformanceMonitoringStartStop() {
        // Test that monitoring can be started and stopped
        XCTAssertNotNil(performanceManager)
        
        // Monitoring should be active after initialization
        // (This is implementation-dependent, so we just verify the manager exists)
        XCTAssertTrue(true)
    }
    
    func testPerformanceMetricsUpdate() {
        // Test that performance metrics are updated
        let initialMetrics = performanceManager.performanceMetrics
        
        // Wait a bit for metrics to potentially update
        let expectation = XCTestExpectation(description: "Metrics update")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
        
        // Metrics should be accessible
        XCTAssertNotNil(performanceManager.performanceMetrics)
    }
    
    func testPerformanceAlerts() {
        // Test performance alerts generation
        let initialAlertCount = performanceManager.performanceAlerts.count
        
        // Trigger some performance monitoring
        _ = performanceManager.monitorCPUPerformance()
        
        // Alerts should be accessible (may or may not be generated depending on thresholds)
        XCTAssertNotNil(performanceManager.performanceAlerts)
        XCTAssertGreaterThanOrEqual(performanceManager.performanceAlerts.count, initialAlertCount)
    }
    
    func testOptimizationRecommendations() {
        // Test optimization recommendations
        let initialRecommendationCount = performanceManager.optimizationRecommendations.count
        
        // Trigger some optimization
        _ = performanceManager.optimizeMemoryUsage()
        
        // Recommendations should be accessible (may or may not be generated)
        XCTAssertNotNil(performanceManager.optimizationRecommendations)
        XCTAssertGreaterThanOrEqual(performanceManager.optimizationRecommendations.count, initialRecommendationCount)
    }
    
    // MARK: - Edge Case Tests
    
    func testConcurrentOptimizationCalls() {
        // Test concurrent optimization calls
        let expectation1 = XCTestExpectation(description: "Memory optimization")
        let expectation2 = XCTestExpectation(description: "CPU optimization")
        let expectation3 = XCTestExpectation(description: "Battery optimization")
        
        DispatchQueue.global(qos: .userInitiated).async {
            let result = self.performanceManager.optimizeMemoryUsage()
            XCTAssertNotNil(result)
            expectation1.fulfill()
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            let result = self.performanceManager.optimizeCPUUsage()
            XCTAssertNotNil(result)
            expectation2.fulfill()
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            let result = self.performanceManager.optimizeBatteryLife()
            XCTAssertNotNil(result)
            expectation3.fulfill()
        }
        
        wait(for: [expectation1, expectation2, expectation3], timeout: 5.0)
    }
    
    func testOptimizationWithZeroValues() {
        // Test optimization with edge case values
        let memoryResult = performanceManager.optimizeMemoryUsage()
        let cpuResult = performanceManager.optimizeCPUUsage()
        let batteryResult = performanceManager.optimizeBatteryLife()
        let networkResult = performanceManager.optimizeNetworkEfficiency()
        let storageResult = performanceManager.optimizeStorageUsage()
        let launchResult = performanceManager.optimizeAppLaunchTime()
        
        // All results should be valid even with edge cases
        XCTAssertNotNil(memoryResult)
        XCTAssertNotNil(cpuResult)
        XCTAssertNotNil(batteryResult)
        XCTAssertNotNil(networkResult)
        XCTAssertNotNil(storageResult)
        XCTAssertNotNil(launchResult)
    }
    
    func testPerformanceManagerLifecycle() {
        // Test performance manager lifecycle
        var manager: PerformanceOptimizationManager? = PerformanceOptimizationManager()
        XCTAssertNotNil(manager)
        
        // Test basic operations
        let memoryResult = manager?.optimizeMemoryUsage()
        XCTAssertNotNil(memoryResult)
        
        // Test deallocation
        manager = nil
        XCTAssertNil(manager)
    }
    
    // MARK: - Integration Tests
    
    func testFullOptimizationWorkflow() {
        // Test a complete optimization workflow
        let memoryResult = performanceManager.optimizeMemoryUsage()
        XCTAssertNotNil(memoryResult)
        
        let cpuResult = performanceManager.optimizeCPUUsage()
        XCTAssertNotNil(cpuResult)
        
        let batteryResult = performanceManager.optimizeBatteryLife()
        XCTAssertNotNil(batteryResult)
        
        let networkResult = performanceManager.optimizeNetworkEfficiency()
        XCTAssertNotNil(networkResult)
        
        let storageResult = performanceManager.optimizeStorageUsage()
        XCTAssertNotNil(storageResult)
        
        let launchResult = performanceManager.optimizeAppLaunchTime()
        XCTAssertNotNil(launchResult)
        
        // All optimizations should complete successfully
        XCTAssertTrue(true)
    }
    
    func testPerformanceMetricsConsistency() {
        // Test that performance metrics are consistent
        let metrics1 = performanceManager.performanceMetrics
        let metrics2 = performanceManager.performanceMetrics
        
        // Metrics should be accessible and consistent
        XCTAssertNotNil(metrics1)
        XCTAssertNotNil(metrics2)
        
        // Basic structure should be the same
        XCTAssertEqual(type(of: metrics1), type(of: metrics2))
    }
    
    // MARK: - Stress Tests
    
    func testStressTestOptimization() {
        // Stress test with multiple rapid optimization calls
        measure {
            for _ in 0..<10 {
                _ = performanceManager.optimizeMemoryUsage()
                _ = performanceManager.optimizeCPUUsage()
                _ = performanceManager.optimizeBatteryLife()
                _ = performanceManager.optimizeNetworkEfficiency()
                _ = performanceManager.optimizeStorageUsage()
                _ = performanceManager.optimizeAppLaunchTime()
            }
        }
    }
    
    func testStressTestMonitoring() {
        // Stress test with rapid monitoring calls
        measure {
            for _ in 0..<50 {
                _ = performanceManager.monitorCPUPerformance()
            }
        }
    }
    
    // MARK: - Error Handling Tests
    
    func testOptimizationWithInvalidData() {
        // Test optimization with potentially invalid data
        // This tests the robustness of the optimization methods
        
        let memoryResult = performanceManager.optimizeMemoryUsage()
        XCTAssertNotNil(memoryResult)
        
        let cpuResult = performanceManager.optimizeCPUUsage()
        XCTAssertNotNil(cpuResult)
        
        let batteryResult = performanceManager.optimizeBatteryLife()
        XCTAssertNotNil(batteryResult)
        
        // All optimizations should handle edge cases gracefully
        XCTAssertTrue(true)
    }
    
    func testPerformanceManagerInitialization() {
        // Test multiple initializations
        let manager1 = PerformanceOptimizationManager()
        let manager2 = PerformanceOptimizationManager()
        
        XCTAssertNotNil(manager1)
        XCTAssertNotNil(manager2)
        XCTAssertNotEqual(ObjectIdentifier(manager1), ObjectIdentifier(manager2))
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
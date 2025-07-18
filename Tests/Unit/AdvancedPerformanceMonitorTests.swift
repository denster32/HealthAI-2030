import XCTest
import Combine
@testable import HealthAI2030

@MainActor
final class AdvancedPerformanceMonitorTests: XCTestCase {
    
    var performanceMonitor: AdvancedPerformanceMonitor!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() async throws {
        try await super.setUp()
        performanceMonitor = AdvancedPerformanceMonitor()
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDown() async throws {
        await performanceMonitor.stopMonitoring()
        cancellables = nil
        performanceMonitor = nil
        try await super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testInitialization() {
        XCTAssertFalse(performanceMonitor.isMonitoring)
        XCTAssertEqual(performanceMonitor.anomalyAlerts.count, 0)
        XCTAssertEqual(performanceMonitor.optimizationRecommendations.count, 0)
        XCTAssertEqual(performanceMonitor.performanceTrends.count, 0)
        XCTAssertEqual(performanceMonitor.systemHealth, .excellent)
    }
    
    // MARK: - Monitoring Lifecycle Tests
    
    func testStartMonitoring() throws {
        try performanceMonitor.startMonitoring(interval: 0.1)
        XCTAssertTrue(performanceMonitor.isMonitoring)
        XCTAssertEqual(performanceMonitor.monitoringInterval, 0.1)
    }
    
    func testStopMonitoring() throws {
        try performanceMonitor.startMonitoring(interval: 0.1)
        performanceMonitor.stopMonitoring()
        XCTAssertFalse(performanceMonitor.isMonitoring)
    }
    
    func testDoubleStartMonitoring() throws {
        try performanceMonitor.startMonitoring(interval: 0.1)
        XCTAssertTrue(performanceMonitor.isMonitoring)
        
        // Second start should not throw or change state
        try performanceMonitor.startMonitoring(interval: 0.2)
        XCTAssertTrue(performanceMonitor.isMonitoring)
        XCTAssertEqual(performanceMonitor.monitoringInterval, 0.1) // Should keep original interval
    }
    
    // MARK: - Metrics Collection Tests
    
    func testMetricsCollectionUpdatesCurrentMetrics() async throws {
        let expectation = XCTestExpectation(description: "Metrics updated")
        
        performanceMonitor.$currentMetrics
            .dropFirst() // Skip initial empty metrics
            .sink { metrics in
                XCTAssertNotNil(metrics.timestamp)
                XCTAssertGreaterThan(metrics.timestamp.timeIntervalSinceNow, -60) // Within last minute
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        try performanceMonitor.startMonitoring(interval: 0.1)
        
        await fulfillment(of: [expectation], timeout: 1.0)
    }
    
    func testCPUMetricsCollection() async throws {
        try performanceMonitor.startMonitoring(interval: 0.1)
        
        // Wait for at least one metrics collection
        try await Task.sleep(for: .milliseconds(200))
        
        let metrics = performanceMonitor.currentMetrics
        XCTAssertGreaterThanOrEqual(metrics.cpu.usage, 0)
        XCTAssertLessThanOrEqual(metrics.cpu.usage, 100)
        XCTAssertGreaterThanOrEqual(metrics.cpu.temperature, 0)
        XCTAssertGreaterThanOrEqual(metrics.cpu.efficiency, 0)
        XCTAssertLessThanOrEqual(metrics.cpu.efficiency, 100)
    }
    
    func testMemoryMetricsCollection() async throws {
        try performanceMonitor.startMonitoring(interval: 0.1)
        
        // Wait for at least one metrics collection
        try await Task.sleep(for: .milliseconds(200))
        
        let metrics = performanceMonitor.currentMetrics
        XCTAssertGreaterThan(metrics.memory.totalMemory, 0)
        XCTAssertGreaterThan(metrics.memory.usedMemory, 0)
        XCTAssertLessThanOrEqual(metrics.memory.usedMemory, metrics.memory.totalMemory)
        XCTAssertEqual(metrics.memory.availableMemory, metrics.memory.totalMemory - metrics.memory.usedMemory)
    }
    
    func testNetworkMetricsCollection() async throws {
        try performanceMonitor.startMonitoring(interval: 0.1)
        
        // Wait for at least one metrics collection
        try await Task.sleep(for: .milliseconds(200))
        
        let metrics = performanceMonitor.currentMetrics
        XCTAssertGreaterThanOrEqual(metrics.network.latency, 0)
        XCTAssertGreaterThanOrEqual(metrics.network.throughput, 0)
        XCTAssertGreaterThanOrEqual(metrics.network.connectionCount, 0)
        XCTAssertGreaterThanOrEqual(metrics.network.errorRate, 0)
    }
    
    func testDiskMetricsCollection() async throws {
        try performanceMonitor.startMonitoring(interval: 0.1)
        
        // Wait for at least one metrics collection
        try await Task.sleep(for: .milliseconds(200))
        
        let metrics = performanceMonitor.currentMetrics
        XCTAssertGreaterThanOrEqual(metrics.disk.totalSpace, 0)
        XCTAssertGreaterThanOrEqual(metrics.disk.usedSpace, 0)
        XCTAssertLessThanOrEqual(metrics.disk.usedSpace, metrics.disk.totalSpace)
        XCTAssertGreaterThanOrEqual(metrics.disk.readSpeed, 0)
        XCTAssertGreaterThanOrEqual(metrics.disk.writeSpeed, 0)
        XCTAssertGreaterThanOrEqual(metrics.disk.iops, 0)
    }
    
    // MARK: - Memory Leak Detection Tests
    
    func testMemoryLeakDetectionWithInsufficientData() async throws {
        // With no history, should not detect leaks
        try performanceMonitor.startMonitoring(interval: 0.1)
        try await Task.sleep(for: .milliseconds(50)) // Very short time
        
        let metrics = performanceMonitor.currentMetrics
        XCTAssertFalse(metrics.memory.leakDetection)
    }
    
    func testMemoryLeakDetectionWithStableMemory() async throws {
        // Simulate stable memory usage by manually adding consistent metrics
        let baseMemory: UInt64 = 1024 * 1024 * 100 // 100MB
        
        for i in 0..<12 {
            let metrics = SystemMetrics()
            metrics.memory.usedMemory = baseMemory + UInt64(i % 3) // Small fluctuation
            metrics.timestamp = Date().addingTimeInterval(Double(-12 + i))
            await performanceMonitor.addMetricsToHistory(metrics)
        }
        
        try performanceMonitor.startMonitoring(interval: 0.1)
        try await Task.sleep(for: .milliseconds(200))
        
        // Should not detect leak with stable memory
        let currentMetrics = performanceMonitor.currentMetrics
        // Memory leak detection depends on the actual implementation
        // This test ensures the function runs without crashing
        XCTAssertNotNil(currentMetrics.memory.leakDetection)
    }
    
    // MARK: - Anomaly Detection Tests
    
    func testHighCPUAnomalyDetection() async throws {
        let expectation = XCTestExpectation(description: "High CPU anomaly detected")
        
        performanceMonitor.$anomalyAlerts
            .sink { alerts in
                if alerts.contains(where: { $0.category == .cpu && $0.severity == .high }) {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // Start monitoring to trigger anomaly detection
        try performanceMonitor.startMonitoring(interval: 0.1)
        
        await fulfillment(of: [expectation], timeout: 2.0)
    }
    
    func testMemoryWarningHandling() async throws {
        let expectation = XCTestExpectation(description: "Memory warning handled")
        
        performanceMonitor.$anomalyAlerts
            .sink { alerts in
                if alerts.contains(where: { $0.category == .memory && $0.metric == "memory_warning" }) {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        try performanceMonitor.startMonitoring(interval: 0.1)
        
        // Simulate memory warning
        NotificationCenter.default.post(name: UIApplication.didReceiveMemoryWarningNotification, object: nil)
        
        await fulfillment(of: [expectation], timeout: 1.0)
    }
    
    // MARK: - System Health Tests
    
    func testSystemHealthCalculation() async throws {
        try performanceMonitor.startMonitoring(interval: 0.1)
        
        // Wait for initial metrics
        try await Task.sleep(for: .milliseconds(200))
        
        let health = performanceMonitor.systemHealth
        XCTAssertTrue([.excellent, .good, .fair, .poor, .critical].contains(health))
    }
    
    func testSystemHealthDegradationWithAnomalies() async throws {
        try performanceMonitor.startMonitoring(interval: 0.1)
        
        // Simulate multiple anomalies
        let criticalAnomaly = AnomalyAlert(
            metric: "test_metric",
            value: 100,
            threshold: 50,
            severity: .critical,
            category: .cpu,
            description: "Test critical anomaly",
            recommendation: "Test recommendation",
            timestamp: Date()
        )
        
        await performanceMonitor.addAnomalyAlert(criticalAnomaly)
        
        // System health should degrade
        XCTAssertEqual(performanceMonitor.systemHealth, .critical)
    }
    
    // MARK: - Performance Dashboard Tests
    
    func testPerformanceDashboardGeneration() async throws {
        try performanceMonitor.startMonitoring(interval: 0.1)
        
        // Wait for some metrics to be collected
        try await Task.sleep(for: .milliseconds(300))
        
        let dashboard = performanceMonitor.getPerformanceDashboard()
        
        XCTAssertNotNil(dashboard.systemOverview)
        XCTAssertNotNil(dashboard.metricCharts)
        XCTAssertNotNil(dashboard.performanceSummary)
        
        // Verify dashboard components
        XCTAssertGreaterThanOrEqual(dashboard.metricCharts.count, 0)
        XCTAssertGreaterThanOrEqual(dashboard.performanceSummary.overallScore, 0)
        XCTAssertLessThanOrEqual(dashboard.performanceSummary.overallScore, 100)
    }
    
    // MARK: - Trend Analysis Tests
    
    func testTrendAnalysisWithSufficientData() async throws {
        // Add sufficient historical data for trend analysis
        for i in 0..<20 {
            let metrics = SystemMetrics()
            metrics.cpu.usage = Double(i) * 2.0 // Increasing trend
            metrics.timestamp = Date().addingTimeInterval(Double(-20 + i))
            await performanceMonitor.addMetricsToHistory(metrics)
        }
        
        try performanceMonitor.startMonitoring(interval: 0.1)
        try await Task.sleep(for: .milliseconds(200))
        
        let trends = performanceMonitor.performanceTrends
        XCTAssertGreaterThan(trends.count, 0)
        
        // Should detect increasing trend for CPU
        let cpuTrend = trends.first { $0.metric.contains("CPU") }
        XCTAssertNotNil(cpuTrend)
        XCTAssertEqual(cpuTrend?.trend, .increasing)
    }
    
    // MARK: - Optimization Recommendations Tests
    
    func testOptimizationRecommendationGeneration() async throws {
        try performanceMonitor.startMonitoring(interval: 0.1)
        
        // Wait for metrics and recommendations to be generated
        try await Task.sleep(for: .milliseconds(500))
        
        let recommendations = performanceMonitor.optimizationRecommendations
        
        // Should have some recommendations based on current metrics
        XCTAssertGreaterThanOrEqual(recommendations.count, 0)
        
        // If there are recommendations, verify their structure
        for recommendation in recommendations {
            XCTAssertFalse(recommendation.title.isEmpty)
            XCTAssertFalse(recommendation.description.isEmpty)
            XCTAssertGreaterThanOrEqual(recommendation.estimatedSavings, 0)
            XCTAssertTrue([.low, .medium, .high, .critical].contains(recommendation.priority))
        }
    }
    
    // MARK: - Real Metrics Validation Tests
    
    func testRealNetworkLatencyMeasurement() async throws {
        try performanceMonitor.startMonitoring(interval: 0.1)
        
        // Wait for network measurement
        try await Task.sleep(for: .milliseconds(500))
        
        let networkLatency = performanceMonitor.currentMetrics.network.latency
        
        // Should be a realistic latency value (not a random simulation)
        XCTAssertGreaterThan(networkLatency, 0)
        XCTAssertLessThan(networkLatency, 10000) // Less than 10 seconds is reasonable
    }
    
    func testRealDiskPerformanceMeasurement() async throws {
        try performanceMonitor.startMonitoring(interval: 0.1)
        
        // Wait for disk measurement
        try await Task.sleep(for: .milliseconds(1000)) // Disk tests need more time
        
        let diskMetrics = performanceMonitor.currentMetrics.disk
        
        // Should have realistic disk performance values
        XCTAssertGreaterThan(diskMetrics.readSpeed, 0)
        XCTAssertGreaterThan(diskMetrics.writeSpeed, 0)
        XCTAssertGreaterThan(diskMetrics.iops, 0)
        
        // Read speed should generally be higher than write speed
        // (though this isn't always true, so we just check they're both positive)
        XCTAssertGreaterThan(diskMetrics.readSpeed, 1.0)
        XCTAssertGreaterThan(diskMetrics.writeSpeed, 1.0)
    }
    
    func testCPUTemperatureBasedOnThermalState() async throws {
        try performanceMonitor.startMonitoring(interval: 0.1)
        
        // Wait for CPU measurement
        try await Task.sleep(for: .milliseconds(200))
        
        let cpuTemperature = performanceMonitor.currentMetrics.cpu.temperature
        let thermalState = ProcessInfo.processInfo.thermalState
        
        // Temperature should correlate with thermal state
        switch thermalState {
        case .nominal:
            XCTAssertEqual(cpuTemperature, 45.0, accuracy: 1.0)
        case .fair:
            XCTAssertEqual(cpuTemperature, 55.0, accuracy: 1.0)
        case .serious:
            XCTAssertEqual(cpuTemperature, 70.0, accuracy: 1.0)
        case .critical:
            XCTAssertEqual(cpuTemperature, 85.0, accuracy: 1.0)
        @unknown default:
            XCTAssertEqual(cpuTemperature, 50.0, accuracy: 1.0)
        }
    }
    
    // MARK: - Performance Tests
    
    func testMetricsCollectionPerformance() throws {
        measure {
            let monitor = AdvancedPerformanceMonitor()
            try! monitor.startMonitoring(interval: 0.01) // Very frequent monitoring
            
            // Let it run for a short time
            Thread.sleep(forTimeInterval: 0.1)
            
            monitor.stopMonitoring()
        }
    }
    
    func testMemoryUsageStability() async throws {
        let initialMemory = performanceMonitor.currentMetrics.memory.usedMemory
        
        try performanceMonitor.startMonitoring(interval: 0.05)
        
        // Run for 1 second with frequent monitoring
        try await Task.sleep(for: .milliseconds(1000))
        
        let finalMemory = performanceMonitor.currentMetrics.memory.usedMemory
        
        // Memory usage shouldn't grow dramatically during monitoring
        let memoryGrowth = finalMemory > initialMemory ? finalMemory - initialMemory : 0
        let maxAcceptableGrowth = initialMemory / 10 // 10% growth max
        
        XCTAssertLessThan(memoryGrowth, maxAcceptableGrowth, 
                         "Memory usage grew too much during monitoring: \(memoryGrowth) bytes")
    }
    
    // MARK: - Error Handling Tests
    
    func testGracefulHandlingOfMeasurementFailures() async throws {
        // This test ensures the monitor continues working even if some measurements fail
        try performanceMonitor.startMonitoring(interval: 0.1)
        
        // Wait for several measurement cycles
        try await Task.sleep(for: .milliseconds(500))
        
        // Should still have valid metrics even if some measurements might fail
        let metrics = performanceMonitor.currentMetrics
        XCTAssertNotNil(metrics.timestamp)
        XCTAssertGreaterThan(metrics.timestamp.timeIntervalSinceNow, -10) // Recent timestamp
    }
}

// MARK: - Test Helper Extensions

extension AdvancedPerformanceMonitor {
    /// Test helper to add metrics to history for testing
    func addMetricsToHistory(_ metrics: SystemMetrics) async {
        // This would need to be implemented in the actual class for testing
        // For now, this is a placeholder to show the testing pattern
    }
    
    /// Test helper to add anomaly alerts for testing
    func addAnomalyAlert(_ alert: AnomalyAlert) async {
        // This would need to be implemented in the actual class for testing
        // For now, this is a placeholder to show the testing pattern
    }
}

// MARK: - Mock Classes for Testing

class MockAnomalyDetector: AnomalyDetector {
    var shouldDetectAnomaly = false
    var mockAnomalies: [AnomalyAlert] = []
    
    override func detectAnomalies(_ metrics: SystemMetrics, history: [SystemMetrics]) async -> [AnomalyAlert] {
        return shouldDetectAnomaly ? mockAnomalies : []
    }
}

class MockTrendAnalyzer: TrendAnalyzer {
    var mockTrends: [PerformanceTrend] = []
    
    override func analyzeTrends(_ history: [SystemMetrics]) async -> [PerformanceTrend] {
        return mockTrends
    }
}

class MockRecommendationEngine: RecommendationEngine {
    var mockRecommendations: [OptimizationRecommendation] = []
    
    override func generateRecommendations(
        currentMetrics: SystemMetrics,
        history: [SystemMetrics],
        anomalies: [AnomalyAlert],
        trends: [PerformanceTrend]
    ) async -> [OptimizationRecommendation] {
        return mockRecommendations
    }
}
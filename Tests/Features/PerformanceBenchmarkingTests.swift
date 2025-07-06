import XCTest
import Combine
@testable import HealthAI2030

@MainActor
final class PerformanceBenchmarkingTests: XCTestCase {
    
    var performanceManager: PerformanceBenchmarkingManager!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        performanceManager = PerformanceBenchmarkingManager()
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDown() {
        performanceManager = nil
        cancellables = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    func testPerformanceManagerInitialization() {
        XCTAssertNotNil(performanceManager)
        XCTAssertNotNil(performanceManager.memoryMetrics)
        XCTAssertNotNil(performanceManager.cpuMetrics)
        XCTAssertNotNil(performanceManager.batteryMetrics)
        XCTAssertNotNil(performanceManager.networkMetrics)
        XCTAssertNotNil(performanceManager.launchMetrics)
        XCTAssertNotNil(performanceManager.uiMetrics)
    }
    
    // MARK: - Memory Metrics Tests
    func testMemoryMetricsStructure() {
        let metrics = performanceManager.memoryMetrics
        
        XCTAssertGreaterThanOrEqual(metrics.usedMemory, 0)
        XCTAssertGreaterThan(metrics.totalMemory, 0)
        XCTAssertGreaterThanOrEqual(metrics.memoryUsage, 0)
        XCTAssertLessThanOrEqual(metrics.memoryUsage, 1)
        XCTAssertNotNil(metrics.timestamp)
    }
    
    func testMemoryUsageCalculation() {
        let metrics = performanceManager.memoryMetrics
        let calculatedUsage = metrics.usedMemory / metrics.totalMemory
        
        XCTAssertEqual(metrics.memoryUsage, calculatedUsage, accuracy: 0.01)
    }
    
    // MARK: - CPU Metrics Tests
    func testCPUMetricsStructure() {
        let metrics = performanceManager.cpuMetrics
        
        XCTAssertGreaterThanOrEqual(metrics.cpuUsage, 0)
        XCTAssertLessThanOrEqual(metrics.cpuUsage, 1)
        XCTAssertGreaterThanOrEqual(metrics.userTime, 0)
        XCTAssertGreaterThanOrEqual(metrics.systemTime, 0)
        XCTAssertGreaterThanOrEqual(metrics.idleTime, 0)
        XCTAssertNotNil(metrics.timestamp)
    }
    
    func testCPUUsageCalculation() {
        let metrics = performanceManager.cpuMetrics
        let totalTime = metrics.userTime + metrics.systemTime + metrics.idleTime
        let calculatedUsage = (metrics.userTime + metrics.systemTime) / totalTime
        
        XCTAssertEqual(metrics.cpuUsage, calculatedUsage, accuracy: 0.01)
    }
    
    // MARK: - Battery Metrics Tests
    func testBatteryMetricsStructure() {
        let metrics = performanceManager.batteryMetrics
        
        XCTAssertGreaterThanOrEqual(metrics.batteryLevel, 0)
        XCTAssertLessThanOrEqual(metrics.batteryLevel, 1)
        XCTAssertNotNil(metrics.batteryState)
        XCTAssertNotNil(metrics.isCharging)
        XCTAssertNotNil(metrics.timestamp)
    }
    
    func testBatteryChargingState() {
        let metrics = performanceManager.batteryMetrics
        
        switch metrics.batteryState {
        case .charging, .full:
            XCTAssertTrue(metrics.isCharging)
        case .unplugged, .unknown:
            XCTAssertFalse(metrics.isCharging)
        @unknown default:
            XCTFail("Unknown battery state")
        }
    }
    
    // MARK: - Network Metrics Tests
    func testNetworkMetricsStructure() {
        let metrics = performanceManager.networkMetrics
        
        XCTAssertGreaterThanOrEqual(metrics.latency, 0)
        XCTAssertNotNil(metrics.isConnected)
        XCTAssertNotNil(metrics.connectionType)
        XCTAssertNotNil(metrics.timestamp)
    }
    
    func testNetworkConnectionType() {
        let metrics = performanceManager.networkMetrics
        
        switch metrics.connectionType {
        case .wifi, .cellular, .unknown:
            break // Valid cases
        }
    }
    
    // MARK: - Launch Metrics Tests
    func testLaunchMetricsStructure() {
        let metrics = performanceManager.launchMetrics
        
        XCTAssertGreaterThanOrEqual(metrics.launchTime, 0)
        XCTAssertNotNil(metrics.isFirstLaunch)
        XCTAssertNotNil(metrics.timestamp)
    }
    
    func testLaunchTimeMeasurement() {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Simulate some work
        Thread.sleep(forTimeInterval: 0.1)
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let expectedTime = endTime - startTime
        
        XCTAssertGreaterThan(expectedTime, 0.09) // Should be at least 90ms
    }
    
    // MARK: - UI Metrics Tests
    func testUIMetricsStructure() {
        let metrics = performanceManager.uiMetrics
        
        XCTAssertGreaterThan(metrics.frameRate, 0)
        XCTAssertLessThanOrEqual(metrics.frameRate, 120) // Max reasonable frame rate
        XCTAssertGreaterThanOrEqual(metrics.drawCalls, 0)
        XCTAssertNotNil(metrics.timestamp)
    }
    
    func testFrameRateCalculation() {
        let metrics = performanceManager.uiMetrics
        
        // Frame rate should be reasonable (between 30 and 120 FPS)
        XCTAssertGreaterThanOrEqual(metrics.frameRate, 30)
        XCTAssertLessThanOrEqual(metrics.frameRate, 120)
    }
    
    // MARK: - Performance Alerts Tests
    func testPerformanceAlertsInitialization() {
        XCTAssertNotNil(performanceManager.performanceAlerts)
        XCTAssertTrue(performanceManager.performanceAlerts is [PerformanceAlert])
    }
    
    func testAlertCreation() {
        let alert = PerformanceAlert(
            type: .memory,
            severity: .warning,
            message: "Test alert",
            timestamp: Date()
        )
        
        XCTAssertEqual(alert.type, .memory)
        XCTAssertEqual(alert.severity, .warning)
        XCTAssertEqual(alert.message, "Test alert")
        XCTAssertNotNil(alert.timestamp)
    }
    
    func testAlertTypes() {
        let types: [AlertType] = [.memory, .cpu, .battery, .network, .launchTime, .ui]
        
        for type in types {
            let alert = PerformanceAlert(
                type: type,
                severity: .info,
                message: "Test",
                timestamp: Date()
            )
            XCTAssertEqual(alert.type, type)
        }
    }
    
    func testAlertSeverities() {
        let severities: [AlertSeverity] = [.info, .warning, .critical]
        
        for severity in severities {
            let alert = PerformanceAlert(
                type: .memory,
                severity: severity,
                message: "Test",
                timestamp: Date()
            )
            XCTAssertEqual(alert.severity, severity)
        }
    }
    
    // MARK: - Optimization Recommendations Tests
    func testOptimizationRecommendationsInitialization() {
        XCTAssertNotNil(performanceManager.optimizationRecommendations)
        XCTAssertTrue(performanceManager.optimizationRecommendations is [OptimizationRecommendation])
    }
    
    func testRecommendationCreation() {
        let recommendation = OptimizationRecommendation(
            type: .memory,
            priority: .high,
            title: "Test Recommendation",
            description: "Test description",
            action: "Test action"
        )
        
        XCTAssertEqual(recommendation.type, .memory)
        XCTAssertEqual(recommendation.priority, .high)
        XCTAssertEqual(recommendation.title, "Test Recommendation")
        XCTAssertEqual(recommendation.description, "Test description")
        XCTAssertEqual(recommendation.action, "Test action")
    }
    
    func testOptimizationTypes() {
        let types: [OptimizationType] = [.memory, .cpu, .battery, .network, .ui]
        
        for type in types {
            let recommendation = OptimizationRecommendation(
                type: type,
                priority: .low,
                title: "Test",
                description: "Test",
                action: "Test"
            )
            XCTAssertEqual(recommendation.type, type)
        }
    }
    
    func testRecommendationPriorities() {
        let priorities: [RecommendationPriority] = [.low, .medium, .high, .critical]
        
        for priority in priorities {
            let recommendation = OptimizationRecommendation(
                type: .memory,
                priority: priority,
                title: "Test",
                description: "Test",
                action: "Test"
            )
            XCTAssertEqual(recommendation.priority, priority)
        }
    }
    
    // MARK: - Performance Report Tests
    func testPerformanceReportCreation() {
        let report = performanceManager.exportPerformanceReport()
        
        XCTAssertNotNil(report.timestamp)
        XCTAssertNotNil(report.memoryMetrics)
        XCTAssertNotNil(report.cpuMetrics)
        XCTAssertNotNil(report.batteryMetrics)
        XCTAssertNotNil(report.networkMetrics)
        XCTAssertNotNil(report.launchMetrics)
        XCTAssertNotNil(report.uiMetrics)
        XCTAssertNotNil(report.alerts)
        XCTAssertNotNil(report.recommendations)
    }
    
    func testPerformanceReportStructure() {
        let report = performanceManager.exportPerformanceReport()
        
        // Verify all metrics are included
        XCTAssertEqual(report.memoryMetrics.usedMemory, performanceManager.memoryMetrics.usedMemory)
        XCTAssertEqual(report.cpuMetrics.cpuUsage, performanceManager.cpuMetrics.cpuUsage)
        XCTAssertEqual(report.batteryMetrics.batteryLevel, performanceManager.batteryMetrics.batteryLevel)
        XCTAssertEqual(report.networkMetrics.latency, performanceManager.networkMetrics.latency)
        XCTAssertEqual(report.launchMetrics.launchTime, performanceManager.launchMetrics.launchTime)
        XCTAssertEqual(report.uiMetrics.frameRate, performanceManager.uiMetrics.frameRate)
        
        // Verify alerts and recommendations
        XCTAssertEqual(report.alerts.count, performanceManager.performanceAlerts.count)
        XCTAssertEqual(report.recommendations.count, performanceManager.optimizationRecommendations.count)
    }
    
    // MARK: - Benchmark Tests
    func testStartBenchmark() {
        let initialAlertsCount = performanceManager.performanceAlerts.count
        let initialRecommendationsCount = performanceManager.optimizationRecommendations.count
        
        performanceManager.startBenchmark()
        
        // Benchmark should reset alerts and recommendations
        XCTAssertEqual(performanceManager.performanceAlerts.count, 0)
        XCTAssertEqual(performanceManager.optimizationRecommendations.count, 0)
    }
    
    // MARK: - Threshold Tests
    func testMemoryThreshold() {
        // Test with high memory usage
        let highMemoryMetrics = MemoryMetrics(
            usedMemory: 8000, // 8GB
            totalMemory: 10000, // 10GB
            memoryUsage: 0.8, // 80%
            timestamp: Date()
        )
        
        // This should trigger a memory alert
        XCTAssertGreaterThan(highMemoryMetrics.memoryUsage, 0.7)
    }
    
    func testCPUThreshold() {
        // Test with high CPU usage
        let highCPUMetrics = CPUMetrics(
            cpuUsage: 0.8, // 80%
            userTime: 800,
            systemTime: 200,
            idleTime: 100,
            timestamp: Date()
        )
        
        // This should trigger a CPU alert
        XCTAssertGreaterThan(highCPUMetrics.cpuUsage, 0.7)
    }
    
    func testBatteryThreshold() {
        // Test with low battery
        let lowBatteryMetrics = BatteryMetrics(
            batteryLevel: 0.15, // 15%
            batteryState: .unplugged,
            isCharging: false,
            timestamp: Date()
        )
        
        // This should trigger a battery alert
        XCTAssertLessThan(lowBatteryMetrics.batteryLevel, 0.2)
        XCTAssertFalse(lowBatteryMetrics.isCharging)
    }
    
    func testNetworkThreshold() {
        // Test with high latency
        let highLatencyMetrics = NetworkMetrics(
            latency: 1500, // 1.5 seconds
            isConnected: true,
            connectionType: .wifi,
            timestamp: Date()
        )
        
        // This should trigger a network alert
        XCTAssertGreaterThan(highLatencyMetrics.latency, 1000)
    }
    
    func testLaunchTimeThreshold() {
        // Test with slow launch
        let slowLaunchMetrics = LaunchMetrics(
            launchTime: 4.0, // 4 seconds
            isFirstLaunch: false,
            timestamp: Date()
        )
        
        // This should trigger a launch time alert
        XCTAssertGreaterThan(slowLaunchMetrics.launchTime, 3.0)
    }
    
    func testFrameRateThreshold() {
        // Test with low frame rate
        let lowFrameRateMetrics = UIMetrics(
            frameRate: 45.0, // 45 FPS
            lastFrameTime: nil,
            drawCalls: 30,
            timestamp: Date()
        )
        
        // This should trigger a UI performance alert
        XCTAssertLessThan(lowFrameRateMetrics.frameRate, 55.0)
    }
    
    // MARK: - Integration Tests
    func testMetricsUpdateFlow() {
        let expectation = XCTestExpectation(description: "Metrics updated")
        
        // Monitor for metrics updates
        performanceManager.$memoryMetrics
            .dropFirst() // Skip initial value
            .sink { _ in
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // Trigger metrics update
        performanceManager.startBenchmark()
        
        wait(for: [expectation], timeout: 10.0)
    }
    
    func testAlertGenerationFlow() {
        let expectation = XCTestExpectation(description: "Alerts generated")
        
        // Monitor for alert generation
        performanceManager.$performanceAlerts
            .dropFirst() // Skip initial value
            .sink { alerts in
                if !alerts.isEmpty {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // Trigger alert generation (this would normally happen with threshold violations)
        performanceManager.startBenchmark()
        
        wait(for: [expectation], timeout: 10.0)
    }
    
    func testRecommendationGenerationFlow() {
        let expectation = XCTestExpectation(description: "Recommendations generated")
        
        // Monitor for recommendation generation
        performanceManager.$optimizationRecommendations
            .dropFirst() // Skip initial value
            .sink { recommendations in
                if !recommendations.isEmpty {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // Trigger recommendation generation
        performanceManager.startBenchmark()
        
        wait(for: [expectation], timeout: 10.0)
    }
    
    // MARK: - Performance Tests
    func testMetricsUpdatePerformance() {
        measure {
            for _ in 0..<100 {
                performanceManager.startBenchmark()
            }
        }
    }
    
    func testReportGenerationPerformance() {
        measure {
            for _ in 0..<1000 {
                _ = performanceManager.exportPerformanceReport()
            }
        }
    }
    
    // MARK: - Edge Cases
    func testZeroMemoryUsage() {
        let zeroMemoryMetrics = MemoryMetrics(
            usedMemory: 0,
            totalMemory: 1000,
            memoryUsage: 0,
            timestamp: Date()
        )
        
        XCTAssertEqual(zeroMemoryMetrics.memoryUsage, 0)
    }
    
    func testFullMemoryUsage() {
        let fullMemoryMetrics = MemoryMetrics(
            usedMemory: 1000,
            totalMemory: 1000,
            memoryUsage: 1.0,
            timestamp: Date()
        )
        
        XCTAssertEqual(fullMemoryMetrics.memoryUsage, 1.0)
    }
    
    func testZeroCPUUsage() {
        let zeroCPUMetrics = CPUMetrics(
            cpuUsage: 0,
            userTime: 0,
            systemTime: 0,
            idleTime: 100,
            timestamp: Date()
        )
        
        XCTAssertEqual(zeroCPUMetrics.cpuUsage, 0)
    }
    
    func testFullCPUUsage() {
        let fullCPUMetrics = CPUMetrics(
            cpuUsage: 1.0,
            userTime: 100,
            systemTime: 0,
            idleTime: 0,
            timestamp: Date()
        )
        
        XCTAssertEqual(fullCPUMetrics.cpuUsage, 1.0)
    }
    
    func testInvalidBatteryLevel() {
        let invalidBatteryMetrics = BatteryMetrics(
            batteryLevel: -0.1, // Invalid negative value
            batteryState: .unknown,
            isCharging: false,
            timestamp: Date()
        )
        
        XCTAssertLessThan(invalidBatteryMetrics.batteryLevel, 0)
    }
    
    func testExcessiveBatteryLevel() {
        let excessiveBatteryMetrics = BatteryMetrics(
            batteryLevel: 1.1, // Invalid value > 1.0
            batteryState: .full,
            isCharging: true,
            timestamp: Date()
        )
        
        XCTAssertGreaterThan(excessiveBatteryMetrics.batteryLevel, 1.0)
    }
} 
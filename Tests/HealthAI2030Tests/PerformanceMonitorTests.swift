import XCTest
import Foundation
@testable import HealthAI2030Core

final class PerformanceMonitorTests: XCTestCase {
    
    var performanceMonitor: PerformanceMonitor!
    
    override func setUpWithError() throws {
        super.setUp()
        performanceMonitor = PerformanceMonitor.shared
    }
    
    override func tearDownWithError() throws {
        performanceMonitor = nil
        super.tearDown()
    }
    
    // MARK: - Performance Metrics Tests
    
    func testPerformanceMetricsInitialization() {
        let metrics = PerformanceMetrics()
        
        XCTAssertEqual(metrics.cpuUsage, 0.0, accuracy: 0.001)
        XCTAssertEqual(metrics.memoryUsage.used, 0)
        XCTAssertEqual(metrics.memoryUsage.available, 0)
        XCTAssertEqual(metrics.memoryUsage.total, 0)
        XCTAssertEqual(metrics.batteryLevel, 0.0, accuracy: 0.001)
        XCTAssertEqual(metrics.networkLatency, 0.0, accuracy: 0.001)
        XCTAssertEqual(metrics.appLaunchTime, 0.0, accuracy: 0.001)
        XCTAssertEqual(metrics.uiResponsiveness, 0.0, accuracy: 0.001)
        XCTAssertEqual(metrics.mlInferenceTime, 0.0, accuracy: 0.001)
        XCTAssertEqual(metrics.databaseQueryTime, 0.0, accuracy: 0.001)
        XCTAssertTrue(metrics.customMetrics.isEmpty)
    }
    
    func testPerformanceMetricsWithValues() {
        let timestamp = Date()
        let memoryUsage = MemoryUsage(used: 1024 * 1024 * 100, available: 1024 * 1024 * 900, total: 1024 * 1024 * 1000)
        let diskUsage = DiskUsage(used: 1024 * 1024 * 1024 * 10, available: 1024 * 1024 * 1024 * 90, total: 1024 * 1024 * 1024 * 100)
        let networkRequests = NetworkRequestMetrics(totalRequests: 100, successfulRequests: 95, failedRequests: 5, averageResponseTime: 150.0, requestsPerSecond: 10.0)
        let errors = ErrorMetrics(totalErrors: 10, criticalErrors: 2, warnings: 8, errorRate: 0.1)
        let customMetrics = ["custom_metric_1": 42.0, "custom_metric_2": 123.45]
        
        let metrics = PerformanceMetrics(
            timestamp: timestamp,
            cpuUsage: 0.75,
            memoryUsage: memoryUsage,
            batteryLevel: 0.65,
            networkLatency: 125.0,
            diskUsage: diskUsage,
            appLaunchTime: 2.5,
            uiResponsiveness: 58.0,
            mlInferenceTime: 0.15,
            databaseQueryTime: 0.05,
            networkRequests: networkRequests,
            errors: errors,
            customMetrics: customMetrics
        )
        
        XCTAssertEqual(metrics.timestamp, timestamp)
        XCTAssertEqual(metrics.cpuUsage, 0.75, accuracy: 0.001)
        XCTAssertEqual(metrics.memoryUsage.used, 1024 * 1024 * 100)
        XCTAssertEqual(metrics.memoryUsage.available, 1024 * 1024 * 900)
        XCTAssertEqual(metrics.memoryUsage.total, 1024 * 1024 * 1000)
        XCTAssertEqual(metrics.batteryLevel, 0.65, accuracy: 0.001)
        XCTAssertEqual(metrics.networkLatency, 125.0, accuracy: 0.001)
        XCTAssertEqual(metrics.appLaunchTime, 2.5, accuracy: 0.001)
        XCTAssertEqual(metrics.uiResponsiveness, 58.0, accuracy: 0.001)
        XCTAssertEqual(metrics.mlInferenceTime, 0.15, accuracy: 0.001)
        XCTAssertEqual(metrics.databaseQueryTime, 0.05, accuracy: 0.001)
        XCTAssertEqual(metrics.networkRequests.totalRequests, 100)
        XCTAssertEqual(metrics.networkRequests.successfulRequests, 95)
        XCTAssertEqual(metrics.networkRequests.failedRequests, 5)
        XCTAssertEqual(metrics.networkRequests.averageResponseTime, 150.0, accuracy: 0.001)
        XCTAssertEqual(metrics.networkRequests.requestsPerSecond, 10.0, accuracy: 0.001)
        XCTAssertEqual(metrics.errors.totalErrors, 10)
        XCTAssertEqual(metrics.errors.criticalErrors, 2)
        XCTAssertEqual(metrics.errors.warnings, 8)
        XCTAssertEqual(metrics.errors.errorRate, 0.1, accuracy: 0.001)
        XCTAssertEqual(metrics.customMetrics.count, 2)
        XCTAssertEqual(metrics.customMetrics["custom_metric_1"], 42.0, accuracy: 0.001)
        XCTAssertEqual(metrics.customMetrics["custom_metric_2"], 123.45, accuracy: 0.001)
    }
    
    // MARK: - Memory Usage Tests
    
    func testMemoryUsageCalculation() {
        let memoryUsage = MemoryUsage(used: 800, available: 200, total: 1000)
        
        XCTAssertEqual(memoryUsage.usagePercentage, 0.8, accuracy: 0.001)
    }
    
    func testMemoryUsageWithZeroTotal() {
        let memoryUsage = MemoryUsage(used: 100, available: 0, total: 0)
        
        XCTAssertEqual(memoryUsage.usagePercentage, 0.0, accuracy: 0.001)
    }
    
    // MARK: - Disk Usage Tests
    
    func testDiskUsageCalculation() {
        let diskUsage = DiskUsage(used: 75, available: 25, total: 100)
        
        XCTAssertEqual(diskUsage.usagePercentage, 0.75, accuracy: 0.001)
    }
    
    func testDiskUsageWithZeroTotal() {
        let diskUsage = DiskUsage(used: 50, available: 0, total: 0)
        
        XCTAssertEqual(diskUsage.usagePercentage, 0.0, accuracy: 0.001)
    }
    
    // MARK: - Network Request Metrics Tests
    
    func testNetworkRequestMetricsSuccessRate() {
        let metrics = NetworkRequestMetrics(totalRequests: 100, successfulRequests: 95, failedRequests: 5, averageResponseTime: 150.0, requestsPerSecond: 10.0)
        
        XCTAssertEqual(metrics.successRate, 0.95, accuracy: 0.001)
    }
    
    func testNetworkRequestMetricsWithZeroRequests() {
        let metrics = NetworkRequestMetrics()
        
        XCTAssertEqual(metrics.successRate, 0.0, accuracy: 0.001)
    }
    
    // MARK: - Performance Alert Tests
    
    func testPerformanceAlertInitialization() {
        let metrics = PerformanceMetrics()
        let alert = PerformanceAlert(
            type: .highCPUUsage,
            severity: .warning,
            message: "High CPU usage detected",
            timestamp: Date(),
            metrics: metrics
        )
        
        XCTAssertEqual(alert.type, .highCPUUsage)
        XCTAssertEqual(alert.severity, .warning)
        XCTAssertEqual(alert.message, "High CPU usage detected")
        XCTAssertEqual(alert.metrics, metrics)
    }
    
    func testPerformanceAlertTypes() {
        let allTypes = PerformanceAlert.AlertType.allCases
        XCTAssertEqual(allTypes.count, 9)
        XCTAssertTrue(allTypes.contains(.highCPUUsage))
        XCTAssertTrue(allTypes.contains(.highMemoryUsage))
        XCTAssertTrue(allTypes.contains(.lowBattery))
        XCTAssertTrue(allTypes.contains(.highNetworkLatency))
        XCTAssertTrue(allTypes.contains(.diskSpaceLow))
        XCTAssertTrue(allTypes.contains(.appCrash))
        XCTAssertTrue(allTypes.contains(.slowUI))
        XCTAssertTrue(allTypes.contains(.mlInferenceSlow))
        XCTAssertTrue(allTypes.contains(.databaseSlow))
    }
    
    func testPerformanceAlertSeverities() {
        let allSeverities = PerformanceAlert.AlertSeverity.allCases
        XCTAssertEqual(allSeverities.count, 4)
        XCTAssertTrue(allSeverities.contains(.info))
        XCTAssertTrue(allSeverities.contains(.warning))
        XCTAssertTrue(allSeverities.contains(.error))
        XCTAssertTrue(allSeverities.contains(.critical))
    }
    
    // MARK: - Optimization Recommendation Tests
    
    func testOptimizationRecommendationInitialization() {
        let recommendation = OptimizationRecommendation(
            type: .cpuOptimization,
            priority: .high,
            title: "Optimize CPU Usage",
            description: "High CPU usage detected",
            impact: .high,
            implementation: "Implement task prioritization"
        )
        
        XCTAssertEqual(recommendation.type, .cpuOptimization)
        XCTAssertEqual(recommendation.priority, .high)
        XCTAssertEqual(recommendation.title, "Optimize CPU Usage")
        XCTAssertEqual(recommendation.description, "High CPU usage detected")
        XCTAssertEqual(recommendation.impact, .high)
        XCTAssertEqual(recommendation.implementation, "Implement task prioritization")
    }
    
    func testOptimizationRecommendationTypes() {
        let allTypes = OptimizationRecommendation.RecommendationType.allCases
        XCTAssertEqual(allTypes.count, 7)
        XCTAssertTrue(allTypes.contains(.cpuOptimization))
        XCTAssertTrue(allTypes.contains(.memoryOptimization))
        XCTAssertTrue(allTypes.contains(.networkOptimization))
        XCTAssertTrue(allTypes.contains(.batteryOptimization))
        XCTAssertTrue(allTypes.contains(.uiOptimization))
        XCTAssertTrue(allTypes.contains(.mlOptimization))
        XCTAssertTrue(allTypes.contains(.databaseOptimization))
    }
    
    func testOptimizationRecommendationPriorities() {
        let allPriorities = OptimizationRecommendation.Priority.allCases
        XCTAssertEqual(allPriorities.count, 4)
        XCTAssertTrue(allPriorities.contains(.low))
        XCTAssertTrue(allPriorities.contains(.medium))
        XCTAssertTrue(allPriorities.contains(.high))
        XCTAssertTrue(allPriorities.contains(.critical))
    }
    
    func testOptimizationRecommendationImpacts() {
        let allImpacts = OptimizationRecommendation.Impact.allCases
        XCTAssertEqual(allImpacts.count, 3)
        XCTAssertTrue(allImpacts.contains(.low))
        XCTAssertTrue(allImpacts.contains(.medium))
        XCTAssertTrue(allImpacts.contains(.high))
    }
    
    // MARK: - Performance Summary Tests
    
    func testPerformanceSummaryInitialization() {
        let summary = PerformanceSummary()
        
        XCTAssertEqual(summary.averageCPUUsage, 0.0, accuracy: 0.001)
        XCTAssertEqual(summary.averageMemoryUsage, 0.0, accuracy: 0.001)
        XCTAssertEqual(summary.averageNetworkLatency, 0.0, accuracy: 0.001)
        XCTAssertEqual(summary.averageBatteryLevel, 0.0, accuracy: 0.001)
        XCTAssertEqual(summary.peakCPUUsage, 0.0, accuracy: 0.001)
        XCTAssertEqual(summary.peakMemoryUsage, 0.0, accuracy: 0.001)
        XCTAssertEqual(summary.totalAlerts, 0)
        XCTAssertEqual(summary.totalRecommendations, 0)
    }
    
    func testPerformanceSummaryWithValues() {
        let summary = PerformanceSummary(
            averageCPUUsage: 0.65,
            averageMemoryUsage: 0.45,
            averageNetworkLatency: 125.0,
            averageBatteryLevel: 0.75,
            peakCPUUsage: 0.95,
            peakMemoryUsage: 0.85,
            totalAlerts: 5,
            totalRecommendations: 3
        )
        
        XCTAssertEqual(summary.averageCPUUsage, 0.65, accuracy: 0.001)
        XCTAssertEqual(summary.averageMemoryUsage, 0.45, accuracy: 0.001)
        XCTAssertEqual(summary.averageNetworkLatency, 125.0, accuracy: 0.001)
        XCTAssertEqual(summary.averageBatteryLevel, 0.75, accuracy: 0.001)
        XCTAssertEqual(summary.peakCPUUsage, 0.95, accuracy: 0.001)
        XCTAssertEqual(summary.peakMemoryUsage, 0.85, accuracy: 0.001)
        XCTAssertEqual(summary.totalAlerts, 5)
        XCTAssertEqual(summary.totalRecommendations, 3)
    }
    
    // MARK: - System Information Tests
    
    func testSystemInformationInitialization() {
        let systemInfo = SystemInformation()
        
        XCTAssertFalse(systemInfo.deviceModel.isEmpty)
        XCTAssertFalse(systemInfo.systemVersion.isEmpty)
        XCTAssertFalse(systemInfo.appVersion.isEmpty)
        XCTAssertFalse(systemInfo.buildNumber.isEmpty)
        XCTAssertFalse(systemInfo.deviceIdentifier.isEmpty)
    }
    
    // MARK: - Device Capabilities Tests
    
    func testDeviceCapabilitiesInitialization() {
        let capabilities = DeviceCapabilities()
        
        XCTAssertTrue(capabilities.hasNeuralEngine)
        XCTAssertTrue(capabilities.hasMetalSupport)
        XCTAssertTrue(capabilities.hasARKit)
        XCTAssertTrue(capabilities.hasCoreML)
        XCTAssertTrue(capabilities.hasHealthKit)
        XCTAssertTrue(capabilities.hasHomeKit)
        XCTAssertFalse(capabilities.hasCarPlay)
        XCTAssertFalse(capabilities.hasWatchConnectivity)
    }
    
    // MARK: - Network Status Tests
    
    func testNetworkStatusInitialization() {
        let networkStatus = NetworkStatus()
        
        XCTAssertFalse(networkStatus.isConnected)
        XCTAssertEqual(networkStatus.connectionType, .unknown)
        XCTAssertFalse(networkStatus.isExpensive)
        XCTAssertFalse(networkStatus.isConstrained)
    }
    
    // MARK: - Connection Type Tests
    
    func testConnectionTypeCases() {
        let allTypes = ConnectionType.allCases
        XCTAssertEqual(allTypes.count, 4)
        XCTAssertTrue(allTypes.contains(.wifi))
        XCTAssertTrue(allTypes.contains(.cellular))
        XCTAssertTrue(allTypes.contains(.ethernet))
        XCTAssertTrue(allTypes.contains(.unknown))
    }
    
    // MARK: - Alert Thresholds Tests
    
    func testAlertThresholdsInitialization() {
        let thresholds = AlertThresholds()
        
        XCTAssertEqual(thresholds.cpuUsage, 0.8, accuracy: 0.001)
        XCTAssertEqual(thresholds.memoryUsage, 0.7, accuracy: 0.001)
        XCTAssertEqual(thresholds.batteryLevel, 0.2, accuracy: 0.001)
        XCTAssertEqual(thresholds.networkLatency, 200.0, accuracy: 0.001)
        XCTAssertEqual(thresholds.diskUsage, 0.9, accuracy: 0.001)
    }
    
    func testAlertThresholdsCustomization() {
        var thresholds = AlertThresholds()
        thresholds.cpuUsage = 0.9
        thresholds.memoryUsage = 0.8
        thresholds.batteryLevel = 0.1
        thresholds.networkLatency = 300.0
        thresholds.diskUsage = 0.95
        
        XCTAssertEqual(thresholds.cpuUsage, 0.9, accuracy: 0.001)
        XCTAssertEqual(thresholds.memoryUsage, 0.8, accuracy: 0.001)
        XCTAssertEqual(thresholds.batteryLevel, 0.1, accuracy: 0.001)
        XCTAssertEqual(thresholds.networkLatency, 300.0, accuracy: 0.001)
        XCTAssertEqual(thresholds.diskUsage, 0.95, accuracy: 0.001)
    }
    
    // MARK: - Performance Monitor Singleton Tests
    
    func testPerformanceMonitorSingleton() {
        let monitor1 = PerformanceMonitor.shared
        let monitor2 = PerformanceMonitor.shared
        
        XCTAssertTrue(monitor1 === monitor2)
    }
    
    // MARK: - Performance Monitor State Tests
    
    func testPerformanceMonitorInitialState() {
        XCTAssertFalse(performanceMonitor.isMonitoring)
        XCTAssertEqual(performanceMonitor.monitoringInterval, 5.0, accuracy: 0.001)
        XCTAssertTrue(performanceMonitor.historicalMetrics.isEmpty)
        XCTAssertTrue(performanceMonitor.performanceAlerts.isEmpty)
        XCTAssertTrue(performanceMonitor.optimizationRecommendations.isEmpty)
    }
    
    // MARK: - Performance Monitor Methods Tests
    
    func testPerformanceMonitorStartStopMonitoring() {
        XCTAssertFalse(performanceMonitor.isMonitoring)
        
        performanceMonitor.startMonitoring()
        XCTAssertTrue(performanceMonitor.isMonitoring)
        
        performanceMonitor.stopMonitoring()
        XCTAssertFalse(performanceMonitor.isMonitoring)
    }
    
    func testPerformanceMonitorUpdateInterval() {
        let originalInterval = performanceMonitor.monitoringInterval
        let newInterval: TimeInterval = 10.0
        
        performanceMonitor.updateMonitoringInterval(newInterval)
        XCTAssertEqual(performanceMonitor.monitoringInterval, newInterval, accuracy: 0.001)
        
        // Restore original interval
        performanceMonitor.updateMonitoringInterval(originalInterval)
    }
    
    func testPerformanceMonitorClearHistoricalData() {
        // Add some test data
        let testMetrics = PerformanceMetrics()
        performanceMonitor.historicalMetrics.append(testMetrics)
        
        XCTAssertFalse(performanceMonitor.historicalMetrics.isEmpty)
        
        performanceMonitor.clearHistoricalData()
        XCTAssertTrue(performanceMonitor.historicalMetrics.isEmpty)
    }
    
    func testPerformanceMonitorExportData() {
        let exportData = performanceMonitor.exportPerformanceData()
        XCTAssertNotNil(exportData)
        
        if let data = exportData {
            let decoder = JSONDecoder()
            let export = try? decoder.decode(PerformanceExportData.self, from: data)
            XCTAssertNotNil(export)
        }
    }
    
    // MARK: - Performance Report Tests
    
    func testPerformanceReportForLastHour() {
        let report = performanceMonitor.getPerformanceReport(for: .lastHour)
        
        XCTAssertEqual(report.period, .lastHour)
        XCTAssertNotNil(report.summary)
        XCTAssertNotNil(report.recommendations)
    }
    
    func testPerformanceReportForLastDay() {
        let report = performanceMonitor.getPerformanceReport(for: .lastDay)
        
        XCTAssertEqual(report.period, .lastDay)
        XCTAssertNotNil(report.summary)
        XCTAssertNotNil(report.recommendations)
    }
    
    func testPerformanceReportForLastWeek() {
        let report = performanceMonitor.getPerformanceReport(for: .lastWeek)
        
        XCTAssertEqual(report.period, .lastWeek)
        XCTAssertNotNil(report.summary)
        XCTAssertNotNil(report.recommendations)
    }
    
    func testPerformanceReportForLastMonth() {
        let report = performanceMonitor.getPerformanceReport(for: .lastMonth)
        
        XCTAssertEqual(report.period, .lastMonth)
        XCTAssertNotNil(report.summary)
        XCTAssertNotNil(report.recommendations)
    }
    
    func testPerformanceReportForCustomPeriod() {
        let start = Date().addingTimeInterval(-3600) // 1 hour ago
        let end = Date()
        let report = performanceMonitor.getPerformanceReport(for: .custom(start: start, end: end))
        
        XCTAssertEqual(report.period, .custom(start: start, end: end))
        XCTAssertNotNil(report.summary)
        XCTAssertNotNil(report.recommendations)
    }
    
    // MARK: - Codable Tests
    
    func testPerformanceMetricsCodable() {
        let originalMetrics = PerformanceMetrics(
            cpuUsage: 0.75,
            memoryUsage: MemoryUsage(used: 1000, available: 2000, total: 3000),
            batteryLevel: 0.65,
            networkLatency: 125.0,
            customMetrics: ["test": 42.0]
        )
        
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        do {
            let data = try encoder.encode(originalMetrics)
            let decodedMetrics = try decoder.decode(PerformanceMetrics.self, from: data)
            
            XCTAssertEqual(originalMetrics.cpuUsage, decodedMetrics.cpuUsage, accuracy: 0.001)
            XCTAssertEqual(originalMetrics.memoryUsage.used, decodedMetrics.memoryUsage.used)
            XCTAssertEqual(originalMetrics.memoryUsage.available, decodedMetrics.memoryUsage.available)
            XCTAssertEqual(originalMetrics.memoryUsage.total, decodedMetrics.memoryUsage.total)
            XCTAssertEqual(originalMetrics.batteryLevel, decodedMetrics.batteryLevel, accuracy: 0.001)
            XCTAssertEqual(originalMetrics.networkLatency, decodedMetrics.networkLatency, accuracy: 0.001)
            XCTAssertEqual(originalMetrics.customMetrics["test"], decodedMetrics.customMetrics["test"], accuracy: 0.001)
        } catch {
            XCTFail("Failed to encode/decode PerformanceMetrics: \(error)")
        }
    }
    
    func testPerformanceAlertCodable() {
        let metrics = PerformanceMetrics()
        let originalAlert = PerformanceAlert(
            type: .highCPUUsage,
            severity: .warning,
            message: "Test alert",
            timestamp: Date(),
            metrics: metrics
        )
        
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        do {
            let data = try encoder.encode(originalAlert)
            let decodedAlert = try decoder.decode(PerformanceAlert.self, from: data)
            
            XCTAssertEqual(originalAlert.type, decodedAlert.type)
            XCTAssertEqual(originalAlert.severity, decodedAlert.severity)
            XCTAssertEqual(originalAlert.message, decodedAlert.message)
        } catch {
            XCTFail("Failed to encode/decode PerformanceAlert: \(error)")
        }
    }
    
    func testOptimizationRecommendationCodable() {
        let originalRecommendation = OptimizationRecommendation(
            type: .cpuOptimization,
            priority: .high,
            title: "Test recommendation",
            description: "Test description",
            impact: .high,
            implementation: "Test implementation"
        )
        
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        do {
            let data = try encoder.encode(originalRecommendation)
            let decodedRecommendation = try decoder.decode(OptimizationRecommendation.self, from: data)
            
            XCTAssertEqual(originalRecommendation.type, decodedRecommendation.type)
            XCTAssertEqual(originalRecommendation.priority, decodedRecommendation.priority)
            XCTAssertEqual(originalRecommendation.title, decodedRecommendation.title)
            XCTAssertEqual(originalRecommendation.description, decodedRecommendation.description)
            XCTAssertEqual(originalRecommendation.impact, decodedRecommendation.impact)
            XCTAssertEqual(originalRecommendation.implementation, decodedRecommendation.implementation)
        } catch {
            XCTFail("Failed to encode/decode OptimizationRecommendation: \(error)")
        }
    }
} 
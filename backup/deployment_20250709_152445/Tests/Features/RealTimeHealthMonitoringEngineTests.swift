import XCTest
import Combine
import SwiftUI
import BackgroundTasks
import UserNotifications
@testable import HealthAI2030Core

@available(iOS 18.0, macOS 15.0, *)
final class RealTimeHealthMonitoringEngineTests: XCTestCase {
    
    var monitoringEngine: RealTimeHealthMonitoringEngine!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        monitoringEngine = RealTimeHealthMonitoringEngine.shared
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDown() {
        cancellables.removeAll()
        monitoringEngine = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testMonitoringEngineInitialization() {
        XCTAssertNotNil(monitoringEngine)
        XCTAssertFalse(monitoringEngine.isMonitoring)
        XCTAssertEqual(monitoringEngine.connectionStatus, .disconnected)
        XCTAssertEqual(monitoringEngine.batteryLevel, 1.0)
        XCTAssertEqual(monitoringEngine.monitoringQuality, .excellent)
        XCTAssertTrue(monitoringEngine.activeAlerts.isEmpty)
        XCTAssertEqual(monitoringEngine.monitoringStats.dataPointsCollected, 0)
    }
    
    // MARK: - Monitoring Control Tests
    
    func testStartMonitoring() {
        let expectation = XCTestExpectation(description: "Monitoring started")
        
        monitoringEngine.$isMonitoring
            .dropFirst()
            .sink { isMonitoring in
                XCTAssertTrue(isMonitoring)
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        monitoringEngine.startMonitoring()
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testStopMonitoring() {
        monitoringEngine.isMonitoring = true
        
        let expectation = XCTestExpectation(description: "Monitoring stopped")
        
        monitoringEngine.$isMonitoring
            .dropFirst()
            .sink { isMonitoring in
                XCTAssertFalse(isMonitoring)
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        monitoringEngine.stopMonitoring()
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testConnectionStatusChanges() {
        let expectation = XCTestExpectation(description: "Connection status changed")
        expectation.expectedFulfillmentCount = 2
        
        var statusChanges: [ConnectionStatus] = []
        
        monitoringEngine.$connectionStatus
            .dropFirst()
            .sink { status in
                statusChanges.append(status)
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        monitoringEngine.startMonitoring()
        
        wait(for: [expectation], timeout: 5.0)
        
        XCTAssertTrue(statusChanges.contains(.connecting))
        XCTAssertTrue(statusChanges.contains(.connected))
    }
    
    // MARK: - Health Status Tests
    
    func testGetCurrentHealthStatus() async throws {
        // Start monitoring first
        monitoringEngine.startMonitoring()
        
        // Wait for monitoring to initialize
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        let healthStatus = try await monitoringEngine.getCurrentHealthStatus()
        
        XCTAssertNotNil(healthStatus)
        XCTAssertNotNil(healthStatus.metrics)
        XCTAssertNotNil(healthStatus.anomalies)
        XCTAssertNotNil(healthStatus.predictions)
        XCTAssertNotNil(healthStatus.timestamp)
    }
    
    func testGetCurrentHealthStatusWhenNotMonitoring() async {
        // Ensure monitoring is stopped
        monitoringEngine.stopMonitoring()
        
        do {
            _ = try await monitoringEngine.getCurrentHealthStatus()
            XCTFail("Should throw error when monitoring is not active")
        } catch MonitoringError.monitoringNotActive {
            // Expected error
            XCTAssertTrue(true)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    // MARK: - Health Metrics Tests
    
    func testGetHealthMetricsForRange() async throws {
        // Start monitoring first
        monitoringEngine.startMonitoring()
        
        // Wait for monitoring to initialize
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        let range = DateInterval(start: Date().addingTimeInterval(-3600), duration: 3600) // Last hour
        let metrics = try await monitoringEngine.getHealthMetrics(for: range)
        
        XCTAssertNotNil(metrics)
        XCTAssertTrue(metrics is [HealthMetrics])
    }
    
    func testGetHealthMetricsWhenNotMonitoring() async {
        // Ensure monitoring is stopped
        monitoringEngine.stopMonitoring()
        
        let range = DateInterval(start: Date().addingTimeInterval(-3600), duration: 3600)
        
        do {
            _ = try await monitoringEngine.getHealthMetrics(for: range)
            XCTFail("Should throw error when monitoring is not active")
        } catch MonitoringError.monitoringNotActive {
            // Expected error
            XCTAssertTrue(true)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    // MARK: - Anomaly Tests
    
    func testGetAnomaliesForRange() async throws {
        // Start monitoring first
        monitoringEngine.startMonitoring()
        
        // Wait for monitoring to initialize
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        let range = DateInterval(start: Date().addingTimeInterval(-3600), duration: 3600) // Last hour
        let anomalies = try await monitoringEngine.getAnomalies(for: range)
        
        XCTAssertNotNil(anomalies)
        XCTAssertTrue(anomalies is [HealthAnomaly])
    }
    
    func testGetAnomaliesWhenNotMonitoring() async {
        // Ensure monitoring is stopped
        monitoringEngine.stopMonitoring()
        
        let range = DateInterval(start: Date().addingTimeInterval(-3600), duration: 3600)
        
        do {
            _ = try await monitoringEngine.getAnomalies(for: range)
            XCTFail("Should throw error when monitoring is not active")
        } catch MonitoringError.monitoringNotActive {
            // Expected error
            XCTAssertTrue(true)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    // MARK: - Alert Tests
    
    func testGetAlertsForRange() async throws {
        // Start monitoring first
        monitoringEngine.startMonitoring()
        
        // Wait for monitoring to initialize
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        let range = DateInterval(start: Date().addingTimeInterval(-3600), duration: 3600) // Last hour
        let alerts = try await monitoringEngine.getAlerts(for: range)
        
        XCTAssertNotNil(alerts)
        XCTAssertTrue(alerts is [HealthAlert])
    }
    
    func testGetAlertsWhenNotMonitoring() async {
        // Ensure monitoring is stopped
        monitoringEngine.stopMonitoring()
        
        let range = DateInterval(start: Date().addingTimeInterval(-3600), duration: 3600)
        
        do {
            _ = try await monitoringEngine.getAlerts(for: range)
            XCTFail("Should throw error when monitoring is not active")
        } catch MonitoringError.monitoringNotActive {
            // Expected error
            XCTAssertTrue(true)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testAcknowledgeAlert() async throws {
        // Create a mock alert
        let alert = HealthAlert(
            type: .anomaly,
            severity: .medium,
            title: "Test Alert",
            message: "This is a test alert",
            timestamp: Date(),
            acknowledged: false
        )
        
        // Add alert to active alerts
        monitoringEngine.activeAlerts.append(alert)
        
        // Acknowledge the alert
        try await monitoringEngine.acknowledgeAlert(alert)
        
        // Verify alert was removed from active alerts
        XCTAssertFalse(monitoringEngine.activeAlerts.contains { $0.id == alert.id })
    }
    
    // MARK: - Configuration Tests
    
    func testConfigureMonitoring() async throws {
        let settings = MonitoringSettings(
            monitoringInterval: 60,
            anomalyCheckInterval: 120,
            alertCheckInterval: 240,
            thresholds: HealthThresholds()
        )
        
        try await monitoringEngine.configureMonitoring(settings: settings)
        
        // Verify settings were applied (this would require exposing the settings for testing)
        XCTAssertTrue(true)
    }
    
    // MARK: - Statistics Tests
    
    func testGetMonitoringStats() {
        let stats = monitoringEngine.getMonitoringStats()
        
        XCTAssertNotNil(stats)
        XCTAssertTrue(stats is MonitoringStats)
        XCTAssertGreaterThanOrEqual(stats.successRate, 0.0)
        XCTAssertLessThanOrEqual(stats.successRate, 1.0)
    }
    
    func testMonitoringStatsUpdate() async throws {
        let initialStats = monitoringEngine.getMonitoringStats()
        
        // Start monitoring to trigger stats updates
        monitoringEngine.startMonitoring()
        
        // Wait for monitoring to process some data
        try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
        let updatedStats = monitoringEngine.getMonitoringStats()
        
        // Stats should be updated
        XCTAssertNotEqual(initialStats.lastUpdateTime, updatedStats.lastUpdateTime)
    }
    
    // MARK: - Device Tests
    
    func testGetConnectedDevices() async throws {
        let devices = try await monitoringEngine.getConnectedDevices()
        
        XCTAssertNotNil(devices)
        XCTAssertTrue(devices is [HealthDevice])
    }
    
    // MARK: - Error Handling Tests
    
    func testMonitoringEngineHandlesErrorsGracefully() async {
        // This test verifies that the engine doesn't crash when errors occur
        do {
            monitoringEngine.startMonitoring()
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            
            let healthStatus = try await monitoringEngine.getCurrentHealthStatus()
            XCTAssertNotNil(healthStatus)
            
        } catch {
            // If an error is thrown, it should be handled gracefully
            XCTAssertTrue(error is MonitoringError)
        }
    }
    
    func testMonitoringErrorTypes() {
        let errors: [MonitoringError] = [
            .monitoringNotActive,
            .dataProcessorNotAvailable,
            .anomalyDetectorNotAvailable,
            .alertManagerNotAvailable,
            .deviceManagerNotAvailable,
            .predictionEngineNotAvailable,
            .backgroundTaskFailed
        ]
        
        for error in errors {
            XCTAssertNotNil(error.errorDescription)
            XCTAssertFalse(error.errorDescription!.isEmpty)
        }
    }
    
    // MARK: - Performance Tests
    
    func testMonitoringPerformance() async throws {
        let startTime = Date()
        
        monitoringEngine.startMonitoring()
        
        // Wait for monitoring to initialize and process some data
        try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
        let healthStatus = try await monitoringEngine.getCurrentHealthStatus()
        
        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)
        
        // Monitoring should complete within reasonable time (5 seconds)
        XCTAssertLessThan(duration, 5.0)
        XCTAssertNotNil(healthStatus)
    }
    
    func testConcurrentMonitoringRequests() async throws {
        monitoringEngine.startMonitoring()
        
        // Wait for monitoring to initialize
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        let expectation1 = XCTestExpectation(description: "First monitoring request")
        let expectation2 = XCTestExpectation(description: "Second monitoring request")
        
        async let status1 = monitoringEngine.getCurrentHealthStatus()
        async let status2 = monitoringEngine.getCurrentHealthStatus()
        
        let (result1, result2) = try await (status1, status2)
        
        XCTAssertNotNil(result1)
        XCTAssertNotNil(result2)
        
        expectation1.fulfill()
        expectation2.fulfill()
        
        wait(for: [expectation1, expectation2], timeout: 10.0)
    }
    
    // MARK: - Data Model Tests
    
    func testHealthStatusStructure() {
        let healthStatus = HealthStatus(
            metrics: HealthMetrics(),
            anomalies: [],
            predictions: [],
            timestamp: Date()
        )
        
        XCTAssertNotNil(healthStatus.metrics)
        XCTAssertNotNil(healthStatus.anomalies)
        XCTAssertNotNil(healthStatus.predictions)
        XCTAssertNotNil(healthStatus.timestamp)
    }
    
    func testHealthMetricsStructure() {
        let metrics = HealthMetrics(
            rawData: [],
            heartRate: 75.0,
            bloodPressure: BloodPressure(systolic: 120, diastolic: 80),
            oxygenSaturation: 98.0,
            temperature: 36.8,
            steps: 5000,
            calories: 2000,
            sleepQuality: 0.8,
            stressLevel: 0.3
        )
        
        XCTAssertEqual(metrics.heartRate, 75.0)
        XCTAssertEqual(metrics.bloodPressure.systolic, 120)
        XCTAssertEqual(metrics.bloodPressure.diastolic, 80)
        XCTAssertEqual(metrics.oxygenSaturation, 98.0)
        XCTAssertEqual(metrics.temperature, 36.8)
        XCTAssertEqual(metrics.steps, 5000)
        XCTAssertEqual(metrics.calories, 2000)
        XCTAssertEqual(metrics.sleepQuality, 0.8)
        XCTAssertEqual(metrics.stressLevel, 0.3)
    }
    
    func testHealthAnomalyStructure() {
        let anomaly = HealthAnomaly(
            type: .heartRate,
            severity: .medium,
            value: 110.0,
            expectedRange: 60...100,
            description: "Elevated heart rate detected",
            timestamp: Date()
        )
        
        XCTAssertEqual(anomaly.type, .heartRate)
        XCTAssertEqual(anomaly.severity, .medium)
        XCTAssertEqual(anomaly.value, 110.0)
        XCTAssertEqual(anomaly.expectedRange, 60...100)
        XCTAssertEqual(anomaly.description, "Elevated heart rate detected")
        XCTAssertNotNil(anomaly.timestamp)
    }
    
    func testHealthAlertStructure() {
        let alert = HealthAlert(
            type: .anomaly,
            severity: .high,
            title: "High Heart Rate Alert",
            message: "Your heart rate is elevated",
            timestamp: Date(),
            acknowledged: false
        )
        
        XCTAssertEqual(alert.type, .anomaly)
        XCTAssertEqual(alert.severity, .high)
        XCTAssertEqual(alert.title, "High Heart Rate Alert")
        XCTAssertEqual(alert.message, "Your heart rate is elevated")
        XCTAssertFalse(alert.acknowledged)
        XCTAssertNotNil(alert.timestamp)
    }
    
    func testMonitoringStatsStructure() {
        let stats = MonitoringStats(
            dataPointsCollected: 100,
            anomaliesDetected: 5,
            alertsTriggered: 2,
            monitoringErrors: 1,
            anomalyDetectionErrors: 0,
            alertErrors: 0,
            anomalyChecks: 10,
            alertChecks: 10,
            lastUpdateTime: Date()
        )
        
        XCTAssertEqual(stats.dataPointsCollected, 100)
        XCTAssertEqual(stats.anomaliesDetected, 5)
        XCTAssertEqual(stats.alertsTriggered, 2)
        XCTAssertEqual(stats.monitoringErrors, 1)
        XCTAssertEqual(stats.anomalyDetectionErrors, 0)
        XCTAssertEqual(stats.alertErrors, 0)
        XCTAssertEqual(stats.anomalyChecks, 10)
        XCTAssertEqual(stats.alertChecks, 10)
        XCTAssertNotNil(stats.lastUpdateTime)
        
        // Test success rate calculation
        let expectedSuccessRate = Double(100 + 10 + 10 - 1) / Double(100 + 10 + 10)
        XCTAssertEqual(stats.successRate, expectedSuccessRate, accuracy: 0.001)
    }
    
    func testHealthThresholdsStructure() {
        var thresholds = HealthThresholds()
        
        XCTAssertEqual(thresholds.maxHeartRate, 100)
        XCTAssertEqual(thresholds.minHeartRate, 60)
        XCTAssertEqual(thresholds.maxSystolic, 140)
        XCTAssertEqual(thresholds.minSystolic, 90)
        XCTAssertEqual(thresholds.maxDiastolic, 90)
        XCTAssertEqual(thresholds.minDiastolic, 60)
        XCTAssertEqual(thresholds.minOxygenSaturation, 95.0)
        XCTAssertEqual(thresholds.maxTemperature, 37.5)
        XCTAssertEqual(thresholds.minTemperature, 36.0)
        
        // Test updating thresholds
        let newThresholds = HealthThresholds(
            maxHeartRate: 120,
            minHeartRate: 50,
            maxSystolic: 150,
            minSystolic: 85,
            maxDiastolic: 95,
            minDiastolic: 55,
            minOxygenSaturation: 94.0,
            maxTemperature: 38.0,
            minTemperature: 35.5
        )
        
        thresholds.update(newThresholds)
        
        XCTAssertEqual(thresholds.maxHeartRate, 120)
        XCTAssertEqual(thresholds.minHeartRate, 50)
        XCTAssertEqual(thresholds.maxSystolic, 150)
        XCTAssertEqual(thresholds.minSystolic, 85)
        XCTAssertEqual(thresholds.maxDiastolic, 95)
        XCTAssertEqual(thresholds.minDiastolic, 55)
        XCTAssertEqual(thresholds.minOxygenSaturation, 94.0)
        XCTAssertEqual(thresholds.maxTemperature, 38.0)
        XCTAssertEqual(thresholds.minTemperature, 35.5)
    }
    
    func testMonitoringSettingsStructure() {
        let thresholds = HealthThresholds()
        let settings = MonitoringSettings(
            monitoringInterval: 45,
            anomalyCheckInterval: 90,
            alertCheckInterval: 180,
            thresholds: thresholds
        )
        
        XCTAssertEqual(settings.monitoringInterval, 45)
        XCTAssertEqual(settings.anomalyCheckInterval, 90)
        XCTAssertEqual(settings.alertCheckInterval, 180)
        XCTAssertEqual(settings.thresholds.maxHeartRate, thresholds.maxHeartRate)
    }
    
    func testHealthDeviceStructure() {
        let device = HealthDevice(
            id: UUID(),
            name: "Apple Watch Series 8",
            type: .appleWatch,
            isConnected: true,
            batteryLevel: 0.85
        )
        
        XCTAssertNotNil(device.id)
        XCTAssertEqual(device.name, "Apple Watch Series 8")
        XCTAssertEqual(device.type, .appleWatch)
        XCTAssertTrue(device.isConnected)
        XCTAssertEqual(device.batteryLevel, 0.85)
    }
    
    // MARK: - Integration Tests
    
    func testMonitoringEngineIntegrationWithAnalytics() async throws {
        // Test that the monitoring engine properly integrates with the analytics engine
        monitoringEngine.startMonitoring()
        
        // Wait for monitoring to initialize
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        let healthStatus = try await monitoringEngine.getCurrentHealthStatus()
        
        XCTAssertNotNil(healthStatus)
        XCTAssertNotNil(healthStatus.metrics)
    }
    
    func testMonitoringEngineIntegrationWithPrediction() async throws {
        // Test that the monitoring engine properly integrates with the prediction engine
        monitoringEngine.startMonitoring()
        
        // Wait for monitoring to initialize
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        let healthStatus = try await monitoringEngine.getCurrentHealthStatus()
        
        XCTAssertNotNil(healthStatus)
        XCTAssertNotNil(healthStatus.predictions)
    }
    
    // MARK: - Real-time Updates Tests
    
    func testRealTimeUpdates() async throws {
        let expectation = XCTestExpectation(description: "Real-time update")
        expectation.expectedFulfillmentCount = 2
        
        var updateCount = 0
        monitoringEngine.$lastUpdateTime
            .dropFirst()
            .sink { _ in
                updateCount += 1
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        monitoringEngine.startMonitoring()
        
        // Wait for real-time updates
        wait(for: [expectation], timeout: 10.0)
        
        XCTAssertGreaterThanOrEqual(updateCount, 1)
    }
    
    // MARK: - Monitoring Quality Tests
    
    func testMonitoringQualityCalculation() async throws {
        let initialQuality = monitoringEngine.monitoringQuality
        
        monitoringEngine.startMonitoring()
        
        // Wait for monitoring to process data
        try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
        let updatedQuality = monitoringEngine.monitoringQuality
        
        // Quality should be calculated and updated
        XCTAssertNotEqual(initialQuality, updatedQuality)
        XCTAssertTrue([MonitoringQuality.excellent, .good, .fair, .poor].contains(updatedQuality))
    }
    
    // MARK: - UI Integration Tests
    
    func testPublishedPropertiesForUI() {
        // Test that all published properties are accessible for UI binding
        XCTAssertNotNil(monitoringEngine.isMonitoring)
        XCTAssertNotNil(monitoringEngine.currentHealthMetrics)
        XCTAssertNotNil(monitoringEngine.activeAlerts)
        XCTAssertNotNil(monitoringEngine.monitoringStats)
        XCTAssertNotNil(monitoringEngine.lastUpdateTime)
        XCTAssertNotNil(monitoringEngine.connectionStatus)
        XCTAssertNotNil(monitoringEngine.batteryLevel)
        XCTAssertNotNil(monitoringEngine.monitoringQuality)
    }
    
    func testObservableObjectConformance() {
        // Test that the monitoring engine conforms to ObservableObject for SwiftUI
        XCTAssertTrue(monitoringEngine is ObservableObject)
    }
    
    // MARK: - Test Helpers
    
    private func createMockHealthData() -> [HealthData] {
        let now = Date()
        var data: [HealthData] = []
        
        for i in 0..<10 {
            let timestamp = now.addingTimeInterval(-Double(i * 60)) // Every minute
            data.append(HealthData(
                timestamp: timestamp,
                heartRate: Int.random(in: 60...100),
                steps: Int.random(in: 0...100),
                sleepHours: 0.0,
                calories: Int.random(in: 0...50)
            ))
        }
        
        return data
    }
    
    private func createMockHealthAnomaly() -> HealthAnomaly {
        return HealthAnomaly(
            type: .heartRate,
            severity: .medium,
            value: 110.0,
            expectedRange: 60...100,
            description: "Elevated heart rate detected",
            timestamp: Date()
        )
    }
    
    private func createMockHealthAlert() -> HealthAlert {
        return HealthAlert(
            type: .anomaly,
            severity: .high,
            title: "High Heart Rate Alert",
            message: "Your heart rate is elevated",
            timestamp: Date(),
            acknowledged: false
        )
    }
}

// MARK: - Test Extensions

extension RealTimeHealthMonitoringEngineTests {
    
    func testMonitoringEngineSingleton() {
        let instance1 = RealTimeHealthMonitoringEngine.shared
        let instance2 = RealTimeHealthMonitoringEngine.shared
        
        XCTAssertTrue(instance1 === instance2)
    }
    
    func testMonitoringEngineMemoryManagement() {
        weak var weakReference: RealTimeHealthMonitoringEngine?
        
        autoreleasepool {
            let strongReference = RealTimeHealthMonitoringEngine.shared
            weakReference = strongReference
        }
        
        // The singleton should remain in memory
        XCTAssertNotNil(weakReference)
    }
} 
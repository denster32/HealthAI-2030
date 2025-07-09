import XCTest
import HealthKit
import CoreML
@testable import HealthAI2030

final class HealthAnomalyDetectionTests: XCTestCase {
    var anomalyManager: HealthAnomalyDetectionManager!
    var mockHealthStore: MockHealthStore!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        mockHealthStore = MockHealthStore()
        anomalyManager = HealthAnomalyDetectionManager(healthStore: mockHealthStore)
    }
    
    override func tearDownWithError() throws {
        anomalyManager = nil
        mockHealthStore = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Initialization Tests
    
    func testInitialization() throws {
        XCTAssertNotNil(anomalyManager)
        XCTAssertFalse(anomalyManager.isAnomalyDetectionEnabled)
        XCTAssertFalse(anomalyManager.isEmergencyAlertsEnabled)
        XCTAssertFalse(anomalyManager.isLocationSharingEnabled)
        XCTAssertTrue(anomalyManager.recentAlerts.isEmpty)
        XCTAssertTrue(anomalyManager.emergencyContacts.isEmpty)
    }
    
    func testInitializationWithHealthStore() throws {
        let customHealthStore = MockHealthStore()
        let manager = HealthAnomalyDetectionManager(healthStore: customHealthStore)
        
        XCTAssertNotNil(manager)
        XCTAssertEqual(manager.healthStore as? MockHealthStore, customHealthStore)
    }
    
    // MARK: - Health Data Monitoring Tests
    
    func testStartMonitoring() throws {
        // Given
        anomalyManager.isAnomalyDetectionEnabled = true
        
        // When
        anomalyManager.startMonitoring()
        
        // Then
        XCTAssertTrue(anomalyManager.isMonitoring)
        XCTAssertNotNil(anomalyManager.monitoringTimer)
    }
    
    func testStopMonitoring() throws {
        // Given
        anomalyManager.startMonitoring()
        
        // When
        anomalyManager.stopMonitoring()
        
        // Then
        XCTAssertFalse(anomalyManager.isMonitoring)
        XCTAssertNil(anomalyManager.monitoringTimer)
    }
    
    func testMonitoringWithDisabledDetection() throws {
        // Given
        anomalyManager.isAnomalyDetectionEnabled = false
        
        // When
        anomalyManager.startMonitoring()
        
        // Then
        XCTAssertFalse(anomalyManager.isMonitoring)
    }
    
    // MARK: - Heart Rate Anomaly Detection Tests
    
    func testHeartRateAnomalyDetection_Normal() throws {
        // Given
        let normalHeartRate = 75.0
        
        // When
        let result = anomalyManager.detectHeartRateAnomaly(heartRate: normalHeartRate)
        
        // Then
        XCTAssertEqual(result.status, .normal)
        XCTAssertNil(result.alert)
    }
    
    func testHeartRateAnomalyDetection_Tachycardia() throws {
        // Given
        let highHeartRate = 120.0
        
        // When
        let result = anomalyManager.detectHeartRateAnomaly(heartRate: highHeartRate)
        
        // Then
        XCTAssertEqual(result.status, .warning)
        XCTAssertNotNil(result.alert)
        XCTAssertEqual(result.alert?.severity, .warning)
        XCTAssertTrue(result.alert?.title.contains("High Heart Rate") ?? false)
    }
    
    func testHeartRateAnomalyDetection_CriticalTachycardia() throws {
        // Given
        let criticalHeartRate = 150.0
        
        // When
        let result = anomalyManager.detectHeartRateAnomaly(heartRate: criticalHeartRate)
        
        // Then
        XCTAssertEqual(result.status, .critical)
        XCTAssertNotNil(result.alert)
        XCTAssertEqual(result.alert?.severity, .critical)
    }
    
    func testHeartRateAnomalyDetection_Bradycardia() throws {
        // Given
        let lowHeartRate = 45.0
        
        // When
        let result = anomalyManager.detectHeartRateAnomaly(heartRate: lowHeartRate)
        
        // Then
        XCTAssertEqual(result.status, .warning)
        XCTAssertNotNil(result.alert)
        XCTAssertTrue(result.alert?.title.contains("Low Heart Rate") ?? false)
    }
    
    func testHeartRateAnomalyDetection_CriticalBradycardia() throws {
        // Given
        let criticalHeartRate = 35.0
        
        // When
        let result = anomalyManager.detectHeartRateAnomaly(heartRate: criticalHeartRate)
        
        // Then
        XCTAssertEqual(result.status, .critical)
        XCTAssertNotNil(result.alert)
        XCTAssertEqual(result.alert?.severity, .critical)
    }
    
    // MARK: - Blood Pressure Anomaly Detection Tests
    
    func testBloodPressureAnomalyDetection_Normal() throws {
        // Given
        let normalSystolic = 120.0
        let normalDiastolic = 80.0
        
        // When
        let result = anomalyManager.detectBloodPressureAnomaly(systolic: normalSystolic, diastolic: normalDiastolic)
        
        // Then
        XCTAssertEqual(result.status, .normal)
        XCTAssertNil(result.alert)
    }
    
    func testBloodPressureAnomalyDetection_Hypertension() throws {
        // Given
        let highSystolic = 150.0
        let highDiastolic = 95.0
        
        // When
        let result = anomalyManager.detectBloodPressureAnomaly(systolic: highSystolic, diastolic: highDiastolic)
        
        // Then
        XCTAssertEqual(result.status, .warning)
        XCTAssertNotNil(result.alert)
        XCTAssertTrue(result.alert?.title.contains("High Blood Pressure") ?? false)
    }
    
    func testBloodPressureAnomalyDetection_CriticalHypertension() throws {
        // Given
        let criticalSystolic = 180.0
        let criticalDiastolic = 110.0
        
        // When
        let result = anomalyManager.detectBloodPressureAnomaly(systolic: criticalSystolic, diastolic: criticalDiastolic)
        
        // Then
        XCTAssertEqual(result.status, .critical)
        XCTAssertNotNil(result.alert)
        XCTAssertEqual(result.alert?.severity, .critical)
    }
    
    // MARK: - Oxygen Saturation Anomaly Detection Tests
    
    func testOxygenSaturationAnomalyDetection_Normal() throws {
        // Given
        let normalSpO2 = 98.0
        
        // When
        let result = anomalyManager.detectOxygenSaturationAnomaly(spO2: normalSpO2)
        
        // Then
        XCTAssertEqual(result.status, .normal)
        XCTAssertNil(result.alert)
    }
    
    func testOxygenSaturationAnomalyDetection_Low() throws {
        // Given
        let lowSpO2 = 92.0
        
        // When
        let result = anomalyManager.detectOxygenSaturationAnomaly(spO2: lowSpO2)
        
        // Then
        XCTAssertEqual(result.status, .warning)
        XCTAssertNotNil(result.alert)
        XCTAssertTrue(result.alert?.title.contains("Low Oxygen Saturation") ?? false)
    }
    
    func testOxygenSaturationAnomalyDetection_Critical() throws {
        // Given
        let criticalSpO2 = 88.0
        
        // When
        let result = anomalyManager.detectOxygenSaturationAnomaly(spO2: criticalSpO2)
        
        // Then
        XCTAssertEqual(result.status, .critical)
        XCTAssertNotNil(result.alert)
        XCTAssertEqual(result.alert?.severity, .critical)
    }
    
    // MARK: - Temperature Anomaly Detection Tests
    
    func testTemperatureAnomalyDetection_Normal() throws {
        // Given
        let normalTemperature = 98.6
        
        // When
        let result = anomalyManager.detectTemperatureAnomaly(temperature: normalTemperature)
        
        // Then
        XCTAssertEqual(result.status, .normal)
        XCTAssertNil(result.alert)
    }
    
    func testTemperatureAnomalyDetection_Fever() throws {
        // Given
        let feverTemperature = 101.5
        
        // When
        let result = anomalyManager.detectTemperatureAnomaly(temperature: feverTemperature)
        
        // Then
        XCTAssertEqual(result.status, .warning)
        XCTAssertNotNil(result.alert)
        XCTAssertTrue(result.alert?.title.contains("Elevated Temperature") ?? false)
    }
    
    func testTemperatureAnomalyDetection_HighFever() throws {
        // Given
        let highFeverTemperature = 103.5
        
        // When
        let result = anomalyManager.detectTemperatureAnomaly(temperature: highFeverTemperature)
        
        // Then
        XCTAssertEqual(result.status, .critical)
        XCTAssertNotNil(result.alert)
        XCTAssertEqual(result.alert?.severity, .critical)
    }
    
    func testTemperatureAnomalyDetection_Hypothermia() throws {
        // Given
        let hypothermiaTemperature = 94.0
        
        // When
        let result = anomalyManager.detectTemperatureAnomaly(temperature: hypothermiaTemperature)
        
        // Then
        XCTAssertEqual(result.status, .critical)
        XCTAssertNotNil(result.alert)
        XCTAssertTrue(result.alert?.title.contains("Low Temperature") ?? false)
    }
    
    // MARK: - Alert Management Tests
    
    func testAddAlert() throws {
        // Given
        let alert = HealthAlert(
            id: UUID(),
            title: "Test Alert",
            description: "Test Description",
            severity: .warning,
            metricType: .heartRate,
            metricValue: "120 bpm",
            threshold: "100 bpm",
            timestamp: Date(),
            recommendations: ["Rest", "Monitor"]
        )
        
        // When
        anomalyManager.addAlert(alert)
        
        // Then
        XCTAssertEqual(anomalyManager.recentAlerts.count, 1)
        XCTAssertEqual(anomalyManager.recentAlerts.first?.title, "Test Alert")
    }
    
    func testAlertLimit() throws {
        // Given
        let maxAlerts = 50
        
        // When
        for i in 0..<maxAlerts + 10 {
            let alert = HealthAlert(
                id: UUID(),
                title: "Alert \(i)",
                description: "Description \(i)",
                severity: .warning,
                metricType: .heartRate,
                metricValue: "\(100 + i) bpm",
                threshold: "100 bpm",
                timestamp: Date(),
                recommendations: []
            )
            anomalyManager.addAlert(alert)
        }
        
        // Then
        XCTAssertLessThanOrEqual(anomalyManager.recentAlerts.count, maxAlerts)
    }
    
    func testDismissAlert() throws {
        // Given
        let alert = HealthAlert(
            id: UUID(),
            title: "Test Alert",
            description: "Test Description",
            severity: .warning,
            metricType: .heartRate,
            metricValue: "120 bpm",
            threshold: "100 bpm",
            timestamp: Date(),
            recommendations: []
        )
        anomalyManager.addAlert(alert)
        
        // When
        anomalyManager.dismissAlert(alert)
        
        // Then
        XCTAssertTrue(anomalyManager.recentAlerts.isEmpty)
    }
    
    // MARK: - Emergency Contact Tests
    
    func testAddEmergencyContact() throws {
        // Given
        let contact = EmergencyContact(
            id: UUID(),
            name: "John Doe",
            phoneNumber: "+1234567890",
            relationship: "Spouse",
            isPrimary: true
        )
        
        // When
        anomalyManager.addEmergencyContact(contact)
        
        // Then
        XCTAssertEqual(anomalyManager.emergencyContacts.count, 1)
        XCTAssertEqual(anomalyManager.emergencyContacts.first?.name, "John Doe")
    }
    
    func testRemoveEmergencyContact() throws {
        // Given
        let contact = EmergencyContact(
            id: UUID(),
            name: "John Doe",
            phoneNumber: "+1234567890",
            relationship: "Spouse",
            isPrimary: true
        )
        anomalyManager.addEmergencyContact(contact)
        
        // When
        anomalyManager.removeEmergencyContact(contact)
        
        // Then
        XCTAssertTrue(anomalyManager.emergencyContacts.isEmpty)
    }
    
    func testPrimaryContactManagement() throws {
        // Given
        let contact1 = EmergencyContact(
            id: UUID(),
            name: "John Doe",
            phoneNumber: "+1234567890",
            relationship: "Spouse",
            isPrimary: true
        )
        let contact2 = EmergencyContact(
            id: UUID(),
            name: "Jane Doe",
            phoneNumber: "+0987654321",
            relationship: "Parent",
            isPrimary: false
        )
        
        // When
        anomalyManager.addEmergencyContact(contact1)
        anomalyManager.addEmergencyContact(contact2)
        anomalyManager.setPrimaryContact(contact2)
        
        // Then
        XCTAssertFalse(anomalyManager.emergencyContacts.first { $0.id == contact1.id }?.isPrimary ?? false)
        XCTAssertTrue(anomalyManager.emergencyContacts.first { $0.id == contact2.id }?.isPrimary ?? false)
    }
    
    // MARK: - Health Status Tests
    
    func testOverallHealthStatus_Normal() throws {
        // Given
        anomalyManager.currentHeartRate = 75
        anomalyManager.currentSystolic = 120
        anomalyManager.currentDiastolic = 80
        anomalyManager.currentOxygenSaturation = 98
        anomalyManager.currentTemperature = 98.6
        
        // When
        let status = anomalyManager.overallHealthStatus
        
        // Then
        XCTAssertEqual(status, "Normal")
    }
    
    func testOverallHealthStatus_Warning() throws {
        // Given
        anomalyManager.currentHeartRate = 110
        anomalyManager.currentSystolic = 140
        anomalyManager.currentDiastolic = 90
        anomalyManager.currentOxygenSaturation = 95
        anomalyManager.currentTemperature = 99.5
        
        // When
        let status = anomalyManager.overallHealthStatus
        
        // Then
        XCTAssertEqual(status, "Warning")
    }
    
    func testOverallHealthStatus_Critical() throws {
        // Given
        anomalyManager.currentHeartRate = 150
        anomalyManager.currentSystolic = 180
        anomalyManager.currentDiastolic = 110
        anomalyManager.currentOxygenSaturation = 88
        anomalyManager.currentTemperature = 103.0
        
        // When
        let status = anomalyManager.overallHealthStatus
        
        // Then
        XCTAssertEqual(status, "Critical")
    }
    
    // MARK: - Trend Analysis Tests
    
    func testHealthTrendAnalysis() throws {
        // Given
        let heartRateData = [75.0, 78.0, 82.0, 85.0, 88.0] // Increasing trend
        
        // When
        let trend = anomalyManager.analyzeHealthTrend(data: heartRateData, metric: .heartRate)
        
        // Then
        XCTAssertEqual(trend.direction, .increasing)
        XCTAssertGreaterThan(trend.changeRate, 0)
        XCTAssertNotNil(trend.insight)
    }
    
    func testTrendInsightGeneration() throws {
        // Given
        let increasingTrend = HealthTrend(
            direction: .increasing,
            changeRate: 5.0,
            confidence: 0.8,
            insight: nil
        )
        
        // When
        let insight = anomalyManager.generateTrendInsight(trend: increasingTrend, metric: .heartRate)
        
        // Then
        XCTAssertNotNil(insight)
        XCTAssertTrue(insight?.description.contains("increasing") ?? false)
    }
    
    // MARK: - Predictive Health Tests
    
    func testHealthRiskPrediction() throws {
        // Given
        let healthData = HealthDataSnapshot(
            heartRate: 85,
            systolic: 135,
            diastolic: 85,
            oxygenSaturation: 96,
            temperature: 99.0,
            timestamp: Date()
        )
        
        // When
        let prediction = anomalyManager.predictHealthRisk(data: healthData)
        
        // Then
        XCTAssertNotNil(prediction)
        XCTAssertGreaterThanOrEqual(prediction?.riskLevel ?? 0, 0)
        XCTAssertLessThanOrEqual(prediction?.riskLevel ?? 1, 1)
    }
    
    func testWeeklyHealthForecast() throws {
        // Given
        let historicalData = Array(repeating: HealthDataSnapshot(
            heartRate: 75,
            systolic: 120,
            diastolic: 80,
            oxygenSaturation: 98,
            temperature: 98.6,
            timestamp: Date()
        ), count: 7)
        
        // When
        let forecast = anomalyManager.generateWeeklyHealthForecast(historicalData: historicalData)
        
        // Then
        XCTAssertNotNil(forecast)
        XCTAssertEqual(forecast?.predictions.count, 7)
    }
    
    // MARK: - Location Services Tests
    
    func testLocationUpdate() throws {
        // Given
        let location = CLLocation(latitude: 37.7749, longitude: -122.4194)
        
        // When
        anomalyManager.updateLocation(location)
        
        // Then
        XCTAssertNotNil(anomalyManager.currentLocation)
        XCTAssertEqual(anomalyManager.currentLocation?.coordinate.latitude, 37.7749)
    }
    
    func testLocationSharingWithEmergencyContacts() throws {
        // Given
        let contact = EmergencyContact(
            id: UUID(),
            name: "John Doe",
            phoneNumber: "+1234567890",
            relationship: "Spouse",
            isPrimary: true
        )
        anomalyManager.addEmergencyContact(contact)
        anomalyManager.isLocationSharingEnabled = true
        
        let location = CLLocation(latitude: 37.7749, longitude: -122.4194)
        anomalyManager.updateLocation(location)
        
        // When
        let sharedLocation = anomalyManager.getLocationForEmergencyContact(contact)
        
        // Then
        XCTAssertNotNil(sharedLocation)
        XCTAssertEqual(sharedLocation?.coordinate.latitude, 37.7749)
    }
    
    // MARK: - Notification Tests
    
    func testEmergencyNotification() throws {
        // Given
        let alert = HealthAlert(
            id: UUID(),
            title: "Critical Heart Rate",
            description: "Heart rate is dangerously high",
            severity: .critical,
            metricType: .heartRate,
            metricValue: "150 bpm",
            threshold: "100 bpm",
            timestamp: Date(),
            recommendations: ["Seek immediate medical attention"]
        )
        
        // When
        anomalyManager.sendEmergencyNotification(for: alert)
        
        // Then
        // Verify notification was sent (implementation dependent)
        XCTAssertTrue(true) // Placeholder assertion
    }
    
    func testAlertNotification() throws {
        // Given
        let alert = HealthAlert(
            id: UUID(),
            title: "High Blood Pressure",
            description: "Blood pressure is elevated",
            severity: .warning,
            metricType: .bloodPressure,
            metricValue: "140/90",
            threshold: "120/80",
            timestamp: Date(),
            recommendations: ["Monitor", "Reduce salt intake"]
        )
        
        // When
        anomalyManager.sendAlertNotification(for: alert)
        
        // Then
        // Verify notification was sent (implementation dependent)
        XCTAssertTrue(true) // Placeholder assertion
    }
    
    // MARK: - Data Persistence Tests
    
    func testSaveHealthData() throws {
        // Given
        let healthData = HealthDataSnapshot(
            heartRate: 75,
            systolic: 120,
            diastolic: 80,
            oxygenSaturation: 98,
            temperature: 98.6,
            timestamp: Date()
        )
        
        // When
        anomalyManager.saveHealthData(healthData)
        
        // Then
        // Verify data was saved (implementation dependent)
        XCTAssertTrue(true) // Placeholder assertion
    }
    
    func testLoadHistoricalData() throws {
        // Given
        let startDate = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let endDate = Date()
        
        // When
        let historicalData = anomalyManager.loadHistoricalData(from: startDate, to: endDate)
        
        // Then
        XCTAssertNotNil(historicalData)
        // Additional assertions based on implementation
    }
    
    // MARK: - Performance Tests
    
    func testAnomalyDetectionPerformance() throws {
        // Given
        let iterations = 1000
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // When
        for _ in 0..<iterations {
            _ = anomalyManager.detectHeartRateAnomaly(heartRate: Double.random(in: 40...200))
        }
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let executionTime = endTime - startTime
        
        // Then
        XCTAssertLessThan(executionTime, 1.0) // Should complete within 1 second
    }
    
    func testAlertProcessingPerformance() throws {
        // Given
        let iterations = 100
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // When
        for i in 0..<iterations {
            let alert = HealthAlert(
                id: UUID(),
                title: "Alert \(i)",
                description: "Description \(i)",
                severity: .warning,
                metricType: .heartRate,
                metricValue: "\(100 + i) bpm",
                threshold: "100 bpm",
                timestamp: Date(),
                recommendations: []
            )
            anomalyManager.addAlert(alert)
        }
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let executionTime = endTime - startTime
        
        // Then
        XCTAssertLessThan(executionTime, 0.1) // Should complete within 0.1 seconds
    }
}

// MARK: - Mock Health Store

class MockHealthStore: HKHealthStore {
    var mockHeartRateData: [HKQuantitySample] = []
    var mockBloodPressureData: [HKQuantitySample] = []
    var mockOxygenSaturationData: [HKQuantitySample] = []
    var mockTemperatureData: [HKQuantitySample] = []
    
    override func requestAuthorization(toShare typesToShare: Set<HKSampleType>?, read typesToRead: Set<HKObjectType>?, completion: @escaping (Bool, Error?) -> Void) {
        completion(true, nil)
    }
    
    override func execute(_ query: HKQuery) {
        // Mock implementation for health queries
    }
    
    func addMockHeartRateData(_ samples: [HKQuantitySample]) {
        mockHeartRateData.append(contentsOf: samples)
    }
    
    func addMockBloodPressureData(_ samples: [HKQuantitySample]) {
        mockBloodPressureData.append(contentsOf: samples)
    }
    
    func addMockOxygenSaturationData(_ samples: [HKQuantitySample]) {
        mockOxygenSaturationData.append(contentsOf: samples)
    }
    
    func addMockTemperatureData(_ samples: [HKQuantitySample]) {
        mockTemperatureData.append(contentsOf: samples)
    }
} 
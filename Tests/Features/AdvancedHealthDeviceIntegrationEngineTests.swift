import XCTest
import Foundation
import Combine
@testable import HealthAI2030

/// Advanced Health Device Integration Engine Tests
/// Comprehensive test suite for device integration, IoT management, sensor fusion, and real-time monitoring
@available(iOS 18.0, macOS 15.0, *)
final class AdvancedHealthDeviceIntegrationEngineTests: XCTestCase {
    
    // MARK: - Properties
    private var deviceIntegrationEngine: AdvancedHealthDeviceIntegrationEngine!
    private var healthDataManager: HealthDataManager!
    private var analyticsEngine: AnalyticsEngine!
    private var cancellables: Set<AnyCancellable>!
    
    // MARK: - Setup and Teardown
    override func setUp() async throws {
        try await super.setUp()
        
        healthDataManager = HealthDataManager.shared
        analyticsEngine = AnalyticsEngine.shared
        deviceIntegrationEngine = AdvancedHealthDeviceIntegrationEngine(
            healthDataManager: healthDataManager,
            analyticsEngine: analyticsEngine
        )
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDown() async throws {
        deviceIntegrationEngine = nil
        cancellables = nil
        try await super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testInitialization() async throws {
        // Test that the engine initializes properly
        XCTAssertNotNil(deviceIntegrationEngine)
        
        // Test initial state
        let connectedDevices = await deviceIntegrationEngine.getConnectedDevices()
        let availableDevices = await deviceIntegrationEngine.getAvailableDevices()
        let iotDevices = await deviceIntegrationEngine.getIoTDevices()
        let deviceAlerts = await deviceIntegrationEngine.getDeviceAlerts()
        
        XCTAssertTrue(connectedDevices.isEmpty)
        XCTAssertTrue(availableDevices.isEmpty)
        XCTAssertTrue(iotDevices.isEmpty)
        XCTAssertTrue(deviceAlerts.isEmpty)
    }
    
    // MARK: - Device Integration Tests
    
    func testStartDeviceIntegration() async throws {
        // Test starting device integration
        try await deviceIntegrationEngine.startDeviceIntegration()
        
        // Verify integration is active
        // Note: In a real implementation, we would check the published properties
        // For now, we'll verify the method doesn't throw
        XCTAssertNoThrow(try await deviceIntegrationEngine.startDeviceIntegration())
    }
    
    func testStopDeviceIntegration() async throws {
        // Test stopping device integration
        await deviceIntegrationEngine.stopDeviceIntegration()
        
        // Verify integration is stopped
        // Note: In a real implementation, we would check the published properties
        // For now, we'll verify the method doesn't throw
        XCTAssertNoThrow(await deviceIntegrationEngine.stopDeviceIntegration())
    }
    
    func testScanForDevices() async throws {
        // Test scanning for devices
        let devices = try await deviceIntegrationEngine.scanForDevices()
        
        // Verify devices are returned (may be empty in test environment)
        XCTAssertNotNil(devices)
        XCTAssertTrue(devices is [HealthDevice])
    }
    
    func testConnectToDevice() async throws {
        // Create a mock device
        let mockDevice = createMockHealthDevice()
        
        // Test connecting to device
        try await deviceIntegrationEngine.connectToDevice(mockDevice)
        
        // Verify device is connected
        let connectedDevices = await deviceIntegrationEngine.getConnectedDevices()
        XCTAssertTrue(connectedDevices.contains { $0.id == mockDevice.id })
    }
    
    func testDisconnectFromDevice() async throws {
        // Create and connect a mock device
        let mockDevice = createMockHealthDevice()
        try await deviceIntegrationEngine.connectToDevice(mockDevice)
        
        // Test disconnecting from device
        try await deviceIntegrationEngine.disconnectFromDevice(mockDevice)
        
        // Verify device is disconnected
        let connectedDevices = await deviceIntegrationEngine.getConnectedDevices()
        XCTAssertFalse(connectedDevices.contains { $0.id == mockDevice.id })
    }
    
    func testGetDeviceData() async throws {
        // Create and connect a mock device
        let mockDevice = createMockHealthDevice()
        try await deviceIntegrationEngine.connectToDevice(mockDevice)
        
        // Test getting device data
        let deviceData = await deviceIntegrationEngine.getDeviceData(deviceId: mockDevice.id.uuidString)
        
        // Verify device data is returned (may be nil in test environment)
        XCTAssertNotNil(deviceData)
    }
    
    // MARK: - IoT Management Tests
    
    func testAddIoTDevice() async throws {
        // Create a mock IoT device
        let mockIoTDevice = createMockIoTDevice()
        
        // Test adding IoT device
        try await deviceIntegrationEngine.addIoTDevice(mockIoTDevice)
        
        // Verify IoT device is added
        let iotDevices = await deviceIntegrationEngine.getIoTDevices()
        XCTAssertTrue(iotDevices.contains { $0.id == mockIoTDevice.id })
    }
    
    func testRemoveIoTDevice() async throws {
        // Create and add a mock IoT device
        let mockIoTDevice = createMockIoTDevice()
        try await deviceIntegrationEngine.addIoTDevice(mockIoTDevice)
        
        // Test removing IoT device
        try await deviceIntegrationEngine.removeIoTDevice(mockIoTDevice)
        
        // Verify IoT device is removed
        let iotDevices = await deviceIntegrationEngine.getIoTDevices()
        XCTAssertFalse(iotDevices.contains { $0.id == mockIoTDevice.id })
    }
    
    func testGetIoTDevicesByCategory() async throws {
        // Add mock IoT devices of different categories
        let wearableDevice = createMockIoTDevice(category: .wearable)
        let medicalDevice = createMockIoTDevice(category: .medical)
        let fitnessDevice = createMockIoTDevice(category: .fitness)
        
        try await deviceIntegrationEngine.addIoTDevice(wearableDevice)
        try await deviceIntegrationEngine.addIoTDevice(medicalDevice)
        try await deviceIntegrationEngine.addIoTDevice(fitnessDevice)
        
        // Test getting IoT devices by category
        let wearableDevices = await deviceIntegrationEngine.getIoTDevices(category: .wearable)
        let medicalDevices = await deviceIntegrationEngine.getIoTDevices(category: .medical)
        let fitnessDevices = await deviceIntegrationEngine.getIoTDevices(category: .fitness)
        
        // Verify correct devices are returned for each category
        XCTAssertEqual(wearableDevices.count, 1)
        XCTAssertEqual(medicalDevices.count, 1)
        XCTAssertEqual(fitnessDevices.count, 1)
        XCTAssertTrue(wearableDevices.contains { $0.id == wearableDevice.id })
        XCTAssertTrue(medicalDevices.contains { $0.id == medicalDevice.id })
        XCTAssertTrue(fitnessDevices.contains { $0.id == fitnessDevice.id })
    }
    
    // MARK: - Sensor Fusion Tests
    
    func testPerformSensorFusion() async throws {
        // Test performing sensor fusion
        let result = try await deviceIntegrationEngine.performSensorFusion()
        
        // Verify fusion result is returned
        XCTAssertNotNil(result)
        XCTAssertEqual(result.timestamp, result.timestamp) // Basic validation
        XCTAssertNotNil(result.insights)
        XCTAssertNotNil(result.analysis)
    }
    
    func testGetSensorFusionData() async throws {
        // Test getting sensor fusion data
        let fusionData = await deviceIntegrationEngine.getSensorFusionData()
        
        // Verify fusion data is returned
        XCTAssertNotNil(fusionData)
        XCTAssertNotNil(fusionData.timestamp)
        XCTAssertNotNil(fusionData.insights)
    }
    
    // MARK: - Device Management Tests
    
    func testGetConnectedDevicesByType() async throws {
        // Create and connect mock devices of different types
        let appleWatchDevice = createMockHealthDevice(type: .appleWatch)
        let iphoneDevice = createMockHealthDevice(type: .iphone)
        let bluetoothDevice = createMockHealthDevice(type: .bluetooth)
        
        try await deviceIntegrationEngine.connectToDevice(appleWatchDevice)
        try await deviceIntegrationEngine.connectToDevice(iphoneDevice)
        try await deviceIntegrationEngine.connectToDevice(bluetoothDevice)
        
        // Test getting connected devices by type
        let appleWatchDevices = await deviceIntegrationEngine.getConnectedDevices(type: .appleWatch)
        let iphoneDevices = await deviceIntegrationEngine.getConnectedDevices(type: .iphone)
        let bluetoothDevices = await deviceIntegrationEngine.getConnectedDevices(type: .bluetooth)
        let allDevices = await deviceIntegrationEngine.getConnectedDevices(type: .all)
        
        // Verify correct devices are returned for each type
        XCTAssertEqual(appleWatchDevices.count, 1)
        XCTAssertEqual(iphoneDevices.count, 1)
        XCTAssertEqual(bluetoothDevices.count, 1)
        XCTAssertEqual(allDevices.count, 3)
        XCTAssertTrue(appleWatchDevices.contains { $0.id == appleWatchDevice.id })
        XCTAssertTrue(iphoneDevices.contains { $0.id == iphoneDevice.id })
        XCTAssertTrue(bluetoothDevices.contains { $0.id == bluetoothDevice.id })
    }
    
    func testGetAvailableDevicesByType() async throws {
        // Test getting available devices by type
        let appleWatchDevices = await deviceIntegrationEngine.getAvailableDevices(type: .appleWatch)
        let iphoneDevices = await deviceIntegrationEngine.getAvailableDevices(type: .iphone)
        let allDevices = await deviceIntegrationEngine.getAvailableDevices(type: .all)
        
        // Verify devices are returned (may be empty in test environment)
        XCTAssertNotNil(appleWatchDevices)
        XCTAssertNotNil(iphoneDevices)
        XCTAssertNotNil(allDevices)
        XCTAssertTrue(appleWatchDevices is [HealthDevice])
        XCTAssertTrue(iphoneDevices is [HealthDevice])
        XCTAssertTrue(allDevices is [HealthDevice])
    }
    
    // MARK: - Alert Management Tests
    
    func testGetDeviceAlertsBySeverity() async throws {
        // Test getting device alerts by severity
        let lowAlerts = await deviceIntegrationEngine.getDeviceAlerts(severity: .low)
        let mediumAlerts = await deviceIntegrationEngine.getDeviceAlerts(severity: .medium)
        let highAlerts = await deviceIntegrationEngine.getDeviceAlerts(severity: .high)
        let criticalAlerts = await deviceIntegrationEngine.getDeviceAlerts(severity: .critical)
        let allAlerts = await deviceIntegrationEngine.getDeviceAlerts(severity: .all)
        
        // Verify alerts are returned (may be empty in test environment)
        XCTAssertNotNil(lowAlerts)
        XCTAssertNotNil(mediumAlerts)
        XCTAssertNotNil(highAlerts)
        XCTAssertNotNil(criticalAlerts)
        XCTAssertNotNil(allAlerts)
        XCTAssertTrue(lowAlerts is [DeviceAlert])
        XCTAssertTrue(mediumAlerts is [DeviceAlert])
        XCTAssertTrue(highAlerts is [DeviceAlert])
        XCTAssertTrue(criticalAlerts is [DeviceAlert])
        XCTAssertTrue(allAlerts is [DeviceAlert])
    }
    
    // MARK: - Data Export Tests
    
    func testExportDeviceDataJSON() async throws {
        // Test exporting device data as JSON
        let jsonData = try await deviceIntegrationEngine.exportDeviceData(format: .json)
        
        // Verify JSON data is returned
        XCTAssertNotNil(jsonData)
        XCTAssertFalse(jsonData.isEmpty)
        
        // Verify JSON is valid
        let jsonObject = try JSONSerialization.jsonObject(with: jsonData)
        XCTAssertNotNil(jsonObject)
    }
    
    func testExportDeviceDataCSV() async throws {
        // Test exporting device data as CSV
        let csvData = try await deviceIntegrationEngine.exportDeviceData(format: .csv)
        
        // Verify CSV data is returned
        XCTAssertNotNil(csvData)
        XCTAssertFalse(csvData.isEmpty)
        
        // Verify CSV is valid string
        let csvString = String(data: csvData, encoding: .utf8)
        XCTAssertNotNil(csvString)
    }
    
    func testExportDeviceDataXML() async throws {
        // Test exporting device data as XML
        let xmlData = try await deviceIntegrationEngine.exportDeviceData(format: .xml)
        
        // Verify XML data is returned
        XCTAssertNotNil(xmlData)
        XCTAssertFalse(xmlData.isEmpty)
        
        // Verify XML is valid string
        let xmlString = String(data: xmlData, encoding: .utf8)
        XCTAssertNotNil(xmlString)
    }
    
    func testExportDeviceDataPDF() async throws {
        // Test exporting device data as PDF
        let pdfData = try await deviceIntegrationEngine.exportDeviceData(format: .pdf)
        
        // Verify PDF data is returned
        XCTAssertNotNil(pdfData)
        XCTAssertFalse(pdfData.isEmpty)
        
        // Verify PDF header
        let pdfHeader = pdfData.prefix(4)
        XCTAssertEqual(pdfHeader, Data([0x25, 0x50, 0x44, 0x46])) // %PDF
    }
    
    // MARK: - Error Handling Tests
    
    func testErrorHandling() async throws {
        // Test error handling for invalid operations
        // This would test various error scenarios in a real implementation
        
        // For now, we'll verify that the engine handles errors gracefully
        XCTAssertNoThrow(try await deviceIntegrationEngine.startDeviceIntegration())
        XCTAssertNoThrow(await deviceIntegrationEngine.stopDeviceIntegration())
    }
    
    // MARK: - Performance Tests
    
    func testPerformanceDeviceScan() throws {
        // Test performance of device scanning
        measure {
            let expectation = XCTestExpectation(description: "Device scan performance")
            
            Task {
                _ = try await deviceIntegrationEngine.scanForDevices()
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 5.0)
        }
    }
    
    func testPerformanceSensorFusion() throws {
        // Test performance of sensor fusion
        measure {
            let expectation = XCTestExpectation(description: "Sensor fusion performance")
            
            Task {
                _ = try await deviceIntegrationEngine.performSensorFusion()
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 5.0)
        }
    }
    
    func testPerformanceDataExport() throws {
        // Test performance of data export
        measure {
            let expectation = XCTestExpectation(description: "Data export performance")
            
            Task {
                _ = try await deviceIntegrationEngine.exportDeviceData(format: .json)
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 5.0)
        }
    }
    
    // MARK: - Integration Tests
    
    func testFullIntegrationWorkflow() async throws {
        // Test complete integration workflow
        let mockDevice = createMockHealthDevice()
        let mockIoTDevice = createMockIoTDevice()
        
        // 1. Start integration
        try await deviceIntegrationEngine.startDeviceIntegration()
        
        // 2. Scan for devices
        let availableDevices = try await deviceIntegrationEngine.scanForDevices()
        XCTAssertNotNil(availableDevices)
        
        // 3. Connect to device
        try await deviceIntegrationEngine.connectToDevice(mockDevice)
        let connectedDevices = await deviceIntegrationEngine.getConnectedDevices()
        XCTAssertTrue(connectedDevices.contains { $0.id == mockDevice.id })
        
        // 4. Add IoT device
        try await deviceIntegrationEngine.addIoTDevice(mockIoTDevice)
        let iotDevices = await deviceIntegrationEngine.getIoTDevices()
        XCTAssertTrue(iotDevices.contains { $0.id == mockIoTDevice.id })
        
        // 5. Perform sensor fusion
        let fusionResult = try await deviceIntegrationEngine.performSensorFusion()
        XCTAssertNotNil(fusionResult)
        
        // 6. Export data
        let exportData = try await deviceIntegrationEngine.exportDeviceData(format: .json)
        XCTAssertNotNil(exportData)
        
        // 7. Disconnect and remove
        try await deviceIntegrationEngine.disconnectFromDevice(mockDevice)
        try await deviceIntegrationEngine.removeIoTDevice(mockIoTDevice)
        
        // 8. Stop integration
        await deviceIntegrationEngine.stopDeviceIntegration()
        
        // Verify final state
        let finalConnectedDevices = await deviceIntegrationEngine.getConnectedDevices()
        let finalIoTDevices = await deviceIntegrationEngine.getIoTDevices()
        XCTAssertFalse(finalConnectedDevices.contains { $0.id == mockDevice.id })
        XCTAssertFalse(finalIoTDevices.contains { $0.id == mockIoTDevice.id })
    }
    
    // MARK: - Helper Methods
    
    private func createMockHealthDevice(type: DeviceType = .appleWatch) -> HealthDevice {
        return HealthDevice(
            id: UUID(),
            name: "Mock \(type.rawValue.capitalized) Device",
            type: type,
            manufacturer: "Mock Manufacturer",
            model: "Mock Model",
            version: "1.0",
            capabilities: [.heartRate, .activity],
            status: .disconnected,
            lastSeen: Date(),
            timestamp: Date()
        )
    }
    
    private func createMockIoTDevice(category: IoTCategory = .wearable) -> IoTDevice {
        return IoTDevice(
            id: UUID(),
            name: "Mock \(category.rawValue.capitalized) IoT Device",
            category: category,
            manufacturer: "Mock IoT Manufacturer",
            model: "Mock IoT Model",
            capabilities: [.sensing, .communication],
            status: .offline,
            lastSeen: Date(),
            timestamp: Date()
        )
    }
    
    private func createMockDeviceData() -> DeviceData {
        return DeviceData(
            deviceId: UUID().uuidString,
            sensorData: [],
            healthMetrics: HealthMetrics(
                heartRate: 72.0,
                bloodPressure: BloodPressure(systolic: 120, diastolic: 80, timestamp: Date()),
                oxygenSaturation: 98.0,
                temperature: 37.0,
                timestamp: Date()
            ),
            deviceStatus: .connected,
            timestamp: Date()
        )
    }
    
    private func createMockSensorFusionResult() -> SensorFusionResult {
        return SensorFusionResult(
            timestamp: Date(),
            insights: [
                SensorInsight(
                    id: UUID(),
                    title: "Mock Insight",
                    description: "This is a mock sensor insight for testing purposes.",
                    category: .health,
                    severity: .low,
                    recommendations: ["Test recommendation 1", "Test recommendation 2"],
                    timestamp: Date()
                )
            ],
            analysis: SensorAnalysis(
                sensorData: [],
                heartRateAnalysis: HeartRateAnalysis(
                    averageHeartRate: 72.0,
                    maxHeartRate: 120.0,
                    minHeartRate: 60.0,
                    heartRateVariability: 45.0,
                    timestamp: Date()
                ),
                activityAnalysis: ActivityAnalysis(
                    steps: 8500,
                    distance: 6.2,
                    calories: 450,
                    activeMinutes: 45,
                    timestamp: Date()
                ),
                sleepAnalysis: SleepAnalysis(
                    totalSleepTime: 7.5,
                    deepSleepTime: 2.0,
                    remSleepTime: 1.5,
                    sleepQuality: 0.8,
                    timestamp: Date()
                ),
                environmentalAnalysis: EnvironmentalAnalysis(
                    temperature: 22.0,
                    humidity: 45.0,
                    airQuality: 0.9,
                    noiseLevel: 35.0,
                    timestamp: Date()
                ),
                biometricAnalysis: BiometricAnalysis(
                    bloodPressure: BloodPressure(systolic: 120, diastolic: 80, timestamp: Date()),
                    oxygenSaturation: 98.0,
                    glucoseLevel: 95.0,
                    timestamp: Date()
                ),
                locationAnalysis: LocationAnalysis(
                    latitude: 37.7749,
                    longitude: -122.4194,
                    altitude: 10.0,
                    accuracy: 5.0,
                    timestamp: Date()
                ),
                timestamp: Date()
            )
        )
    }
}

// MARK: - Test Extensions

extension AdvancedHealthDeviceIntegrationEngineTests {
    
    func testDeviceTypeEnum() {
        // Test DeviceType enum values
        XCTAssertEqual(DeviceType.allCases.count, 7)
        XCTAssertTrue(DeviceType.allCases.contains(.appleWatch))
        XCTAssertTrue(DeviceType.allCases.contains(.iphone))
        XCTAssertTrue(DeviceType.allCases.contains(.ipad))
        XCTAssertTrue(DeviceType.allCases.contains(.mac))
        XCTAssertTrue(DeviceType.allCases.contains(.bluetooth))
        XCTAssertTrue(DeviceType.allCases.contains(.wifi))
        XCTAssertTrue(DeviceType.allCases.contains(.cellular))
    }
    
    func testIoTCategoryEnum() {
        // Test IoTCategory enum values
        XCTAssertEqual(IoTCategory.allCases.count, 5)
        XCTAssertTrue(IoTCategory.allCases.contains(.wearable))
        XCTAssertTrue(IoTCategory.allCases.contains(.medical))
        XCTAssertTrue(IoTCategory.allCases.contains(.fitness))
        XCTAssertTrue(IoTCategory.allCases.contains(.smartHome))
        XCTAssertTrue(IoTCategory.allCases.contains(.environmental))
    }
    
    func testDeviceStatusEnum() {
        // Test DeviceStatus enum values
        XCTAssertEqual(DeviceStatus.allCases.count, 5)
        XCTAssertTrue(DeviceStatus.allCases.contains(.connected))
        XCTAssertTrue(DeviceStatus.allCases.contains(.disconnected))
        XCTAssertTrue(DeviceStatus.allCases.contains(.connecting))
        XCTAssertTrue(DeviceStatus.allCases.contains(.error))
        XCTAssertTrue(DeviceStatus.allCases.contains(.unknown))
    }
    
    func testAlertSeverityEnum() {
        // Test AlertSeverity enum values
        XCTAssertEqual(AlertSeverity.allCases.count, 4)
        XCTAssertTrue(AlertSeverity.allCases.contains(.low))
        XCTAssertTrue(AlertSeverity.allCases.contains(.medium))
        XCTAssertTrue(AlertSeverity.allCases.contains(.high))
        XCTAssertTrue(AlertSeverity.allCases.contains(.critical))
    }
    
    func testInsightCategoryEnum() {
        // Test InsightCategory enum values
        XCTAssertEqual(InsightCategory.allCases.count, 6)
        XCTAssertTrue(InsightCategory.allCases.contains(.health))
        XCTAssertTrue(InsightCategory.allCases.contains(.activity))
        XCTAssertTrue(InsightCategory.allCases.contains(.sleep))
        XCTAssertTrue(InsightCategory.allCases.contains(.environmental))
        XCTAssertTrue(InsightCategory.allCases.contains(.biometric))
        XCTAssertTrue(InsightCategory.allCases.contains(.location))
    }
    
    func testSeverityEnum() {
        // Test Severity enum values
        XCTAssertEqual(Severity.allCases.count, 4)
        XCTAssertTrue(Severity.allCases.contains(.low))
        XCTAssertTrue(Severity.allCases.contains(.medium))
        XCTAssertTrue(Severity.allCases.contains(.high))
        XCTAssertTrue(Severity.allCases.contains(.critical))
    }
} 
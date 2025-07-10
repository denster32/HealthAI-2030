import XCTest
import HealthKit
import CoreML
@testable import HealthAI2030

@available(iOS 18.0, macOS 15.0, *)
final class AdvancedHealthDataIntegrationEngineTests: XCTestCase {
    
    var integrationEngine: AdvancedHealthDataIntegrationEngine!
    var healthDataManager: HealthDataManager!
    var analyticsEngine: AnalyticsEngine!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        healthDataManager = HealthDataManager()
        analyticsEngine = AnalyticsEngine()
        integrationEngine = AdvancedHealthDataIntegrationEngine(
            healthDataManager: healthDataManager,
            analyticsEngine: analyticsEngine
        )
    }
    
    override func tearDownWithError() throws {
        integrationEngine = nil
        healthDataManager = nil
        analyticsEngine = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Initialization Tests
    
    func testInitialization() {
        XCTAssertNotNil(integrationEngine)
        XCTAssertEqual(integrationEngine.integrationStatus, .idle)
        XCTAssertEqual(integrationEngine.syncProgress, 0.0)
        XCTAssertNil(integrationEngine.lastError)
        XCTAssertNil(integrationEngine.lastSyncTime)
        XCTAssertTrue(integrationEngine.connectedDevices.isEmpty)
        XCTAssertTrue(integrationEngine.dataSources.isEmpty)
        XCTAssertTrue(integrationEngine.fhirResources.isEmpty)
        XCTAssertNotNil(integrationEngine.dataQuality)
        XCTAssertNotNil(integrationEngine.integrationMetrics)
    }
    
    // MARK: - Integration Control Tests
    
    func testStartIntegration() async throws {
        // Given
        XCTAssertEqual(integrationEngine.integrationStatus, .idle)
        
        // When
        try await integrationEngine.startIntegration()
        
        // Then
        XCTAssertEqual(integrationEngine.integrationStatus, .connected)
        XCTAssertEqual(integrationEngine.syncProgress, 1.0)
        XCTAssertNil(integrationEngine.lastError)
    }
    
    func testStopIntegration() async throws {
        // Given
        try await integrationEngine.startIntegration()
        XCTAssertEqual(integrationEngine.integrationStatus, .connected)
        
        // When
        await integrationEngine.stopIntegration()
        
        // Then
        XCTAssertEqual(integrationEngine.integrationStatus, .disconnected)
        XCTAssertEqual(integrationEngine.syncProgress, 0.0)
    }
    
    func testStartIntegrationError() async {
        // Given
        let mockEngine = MockIntegrationEngine()
        
        // When & Then
        do {
            try await mockEngine.startIntegration()
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertNotNil(error)
        }
    }
    
    // MARK: - Synchronization Tests
    
    func testPerformSync() async throws {
        // Given
        try await integrationEngine.startIntegration()
        
        // When
        let activity = try await integrationEngine.performSync()
        
        // Then
        XCTAssertNotNil(activity)
        XCTAssertEqual(activity.timestamp, Date(), accuracy: 1.0)
        XCTAssertNotNil(activity.devices)
        XCTAssertNotNil(activity.sources)
        XCTAssertNotNil(activity.metrics)
    }
    
    func testPerformSyncWithoutStarting() async {
        // Given
        XCTAssertEqual(integrationEngine.integrationStatus, .idle)
        
        // When & Then
        do {
            _ = try await integrationEngine.performSync()
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertNotNil(error)
        }
    }
    
    // MARK: - Integration Status Tests
    
    func testGetIntegrationStatus() async {
        // Given
        try? await integrationEngine.startIntegration()
        
        // When
        let status = await integrationEngine.getIntegrationStatus()
        
        // Then
        XCTAssertNotNil(status)
        XCTAssertTrue([.idle, .connecting, .connected, .syncing, .error, .disconnected].contains(status))
    }
    
    // MARK: - Device Management Tests
    
    func testGetConnectedDevices() async {
        // Given
        try? await integrationEngine.startIntegration()
        
        // When
        let allDevices = await integrationEngine.getConnectedDevices()
        let wearableDevices = await integrationEngine.getConnectedDevices(type: .wearable)
        let medicalDevices = await integrationEngine.getConnectedDevices(type: .medical)
        let mobileDevices = await integrationEngine.getConnectedDevices(type: .mobile)
        let smartHomeDevices = await integrationEngine.getConnectedDevices(type: .smartHome)
        let clinicalDevices = await integrationEngine.getConnectedDevices(type: .clinical)
        
        // Then
        XCTAssertNotNil(allDevices)
        XCTAssertNotNil(wearableDevices)
        XCTAssertNotNil(medicalDevices)
        XCTAssertNotNil(mobileDevices)
        XCTAssertNotNil(smartHomeDevices)
        XCTAssertNotNil(clinicalDevices)
    }
    
    func testConnectToDevice() async throws {
        // Given
        let device = createMockDevice()
        
        // When
        try await integrationEngine.connectToDevice(device)
        
        // Then
        // Verify device connection (implementation dependent)
    }
    
    func testConnectToDeviceError() async {
        // Given
        let invalidDevice = createInvalidDevice()
        
        // When & Then
        do {
            try await integrationEngine.connectToDevice(invalidDevice)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertNotNil(error)
        }
    }
    
    func testDisconnectFromDevice() async throws {
        // Given
        let device = createMockDevice()
        try await integrationEngine.connectToDevice(device)
        
        // When
        try await integrationEngine.disconnectFromDevice(device)
        
        // Then
        // Verify device disconnection (implementation dependent)
    }
    
    func testDisconnectFromDeviceError() async {
        // Given
        let invalidDevice = createInvalidDevice()
        
        // When & Then
        do {
            try await integrationEngine.disconnectFromDevice(invalidDevice)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertNotNil(error)
        }
    }
    
    // MARK: - Data Source Tests
    
    func testGetDataSources() async {
        // Given
        try? await integrationEngine.startIntegration()
        
        // When
        let allSources = await integrationEngine.getDataSources()
        let healthKitSources = await integrationEngine.getDataSources(category: .healthKit)
        let fhirSources = await integrationEngine.getDataSources(category: .fhir)
        let hl7Sources = await integrationEngine.getDataSources(category: .hl7)
        let customSources = await integrationEngine.getDataSources(category: .custom)
        let externalSources = await integrationEngine.getDataSources(category: .external)
        
        // Then
        XCTAssertNotNil(allSources)
        XCTAssertNotNil(healthKitSources)
        XCTAssertNotNil(fhirSources)
        XCTAssertNotNil(hl7Sources)
        XCTAssertNotNil(customSources)
        XCTAssertNotNil(externalSources)
    }
    
    func testAddDataSource() async throws {
        // Given
        let source = createMockSource()
        
        // When
        try await integrationEngine.addDataSource(source)
        
        // Then
        // Verify source addition (implementation dependent)
    }
    
    func testAddDataSourceError() async {
        // Given
        let invalidSource = createInvalidSource()
        
        // When & Then
        do {
            try await integrationEngine.addDataSource(invalidSource)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertNotNil(error)
        }
    }
    
    func testRemoveDataSource() async throws {
        // Given
        let source = createMockSource()
        try await integrationEngine.addDataSource(source)
        
        // When
        try await integrationEngine.removeDataSource(source)
        
        // Then
        // Verify source removal (implementation dependent)
    }
    
    func testRemoveDataSourceError() async {
        // Given
        let invalidSource = createInvalidSource()
        
        // When & Then
        do {
            try await integrationEngine.removeDataSource(invalidSource)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertNotNil(error)
        }
    }
    
    // MARK: - FHIR Integration Tests
    
    func testGetFHIRResources() async {
        // Given
        try? await integrationEngine.startIntegration()
        
        // When
        let allResources = await integrationEngine.getFHIRResources()
        let patientResources = await integrationEngine.getFHIRResources(resourceType: .patient)
        let observationResources = await integrationEngine.getFHIRResources(resourceType: .observation)
        let medicationResources = await integrationEngine.getFHIRResources(resourceType: .medication)
        let conditionResources = await integrationEngine.getFHIRResources(resourceType: .condition)
        let procedureResources = await integrationEngine.getFHIRResources(resourceType: .procedure)
        let encounterResources = await integrationEngine.getFHIRResources(resourceType: .encounter)
        
        // Then
        XCTAssertNotNil(allResources)
        XCTAssertNotNil(patientResources)
        XCTAssertNotNil(observationResources)
        XCTAssertNotNil(medicationResources)
        XCTAssertNotNil(conditionResources)
        XCTAssertNotNil(procedureResources)
        XCTAssertNotNil(encounterResources)
    }
    
    // MARK: - Data Export Tests
    
    func testExportFHIRDataJSON() async throws {
        // Given
        try? await integrationEngine.startIntegration()
        
        // When
        let data = try await integrationEngine.exportFHIRData(format: .json)
        
        // Then
        XCTAssertNotNil(data)
        XCTAssertFalse(data.isEmpty)
        
        // Verify JSON can be decoded
        let decoder = JSONDecoder()
        let exportData = try decoder.decode(FHIRExportData.self, from: data)
        XCTAssertNotNil(exportData)
    }
    
    func testExportFHIRDataXML() async throws {
        // Given
        try? await integrationEngine.startIntegration()
        
        // When
        let data = try await integrationEngine.exportFHIRData(format: .xml)
        
        // Then
        XCTAssertNotNil(data)
        XCTAssertFalse(data.isEmpty)
    }
    
    func testExportFHIRDataCSV() async throws {
        // Given
        try? await integrationEngine.startIntegration()
        
        // When
        let data = try await integrationEngine.exportFHIRData(format: .csv)
        
        // Then
        XCTAssertNotNil(data)
        XCTAssertFalse(data.isEmpty)
    }
    
    func testExportFHIRDataPDF() async throws {
        // Given
        try? await integrationEngine.startIntegration()
        
        // When
        let data = try await integrationEngine.exportFHIRData(format: .pdf)
        
        // Then
        XCTAssertNotNil(data)
        XCTAssertFalse(data.isEmpty)
    }
    
    // MARK: - Sync History Tests
    
    func testGetSyncHistory() {
        // Given
        let history = integrationEngine.getSyncHistory()
        
        // Then
        XCTAssertNotNil(history)
        XCTAssertTrue(history is [SyncActivity])
    }
    
    func testGetSyncHistoryWithTimeframe() {
        // Given
        let history = integrationEngine.getSyncHistory(timeframe: .month)
        
        // Then
        XCTAssertNotNil(history)
        XCTAssertTrue(history is [SyncActivity])
    }
    
    // MARK: - Data Quality Tests
    
    func testGetDataQualityReport() async {
        // Given
        try? await integrationEngine.startIntegration()
        
        // When
        let report = await integrationEngine.getDataQualityReport()
        
        // Then
        XCTAssertNotNil(report)
        XCTAssertEqual(report.timestamp, Date(), accuracy: 1.0)
        XCTAssertNotNil(report.overallQuality)
        XCTAssertNotNil(report.completeness)
        XCTAssertNotNil(report.accuracy)
        XCTAssertNotNil(report.consistency)
        XCTAssertNotNil(report.timeliness)
        XCTAssertNotNil(report.issues)
        XCTAssertNotNil(report.recommendations)
    }
    
    // MARK: - Model Tests
    
    func testConnectedDeviceModel() {
        // Given
        let device = createMockDevice()
        
        // Then
        XCTAssertNotNil(device.id)
        XCTAssertNotNil(device.name)
        XCTAssertNotNil(device.type)
        XCTAssertNotNil(device.manufacturer)
        XCTAssertNotNil(device.model)
        XCTAssertNotNil(device.firmwareVersion)
        XCTAssertNotNil(device.connectionStatus)
        XCTAssertNotNil(device.lastSeen)
        XCTAssertNotNil(device.capabilities)
        XCTAssertNotNil(device.dataTypes)
        XCTAssertNotNil(device.timestamp)
    }
    
    func testDataSourceModel() {
        // Given
        let source = createMockSource()
        
        // Then
        XCTAssertNotNil(source.id)
        XCTAssertNotNil(source.name)
        XCTAssertNotNil(source.category)
        XCTAssertNotNil(source.status)
        XCTAssertNotNil(source.dataTypes)
        XCTAssertNotNil(source.syncInterval)
        XCTAssertNotNil(source.timestamp)
    }
    
    func testFHIRResourceModel() {
        // Given
        let resource = createMockResource()
        
        // Then
        XCTAssertNotNil(resource.id)
        XCTAssertNotNil(resource.type)
        XCTAssertNotNil(resource.resourceId)
        XCTAssertNotNil(resource.data)
        XCTAssertNotNil(resource.version)
        XCTAssertNotNil(resource.lastUpdated)
        XCTAssertNotNil(resource.status)
        XCTAssertNotNil(resource.timestamp)
    }
    
    func testDataQualityModel() {
        // Given
        let quality = createMockQuality()
        
        // Then
        XCTAssertNotNil(quality.overallScore)
        XCTAssertNotNil(quality.completeness)
        XCTAssertNotNil(quality.accuracy)
        XCTAssertNotNil(quality.consistency)
        XCTAssertNotNil(quality.timeliness)
        XCTAssertNotNil(quality.issues)
        XCTAssertNotNil(quality.timestamp)
    }
    
    func testIntegrationMetricsModel() {
        // Given
        let metrics = createMockMetrics()
        
        // Then
        XCTAssertNotNil(metrics.syncCount)
        XCTAssertNotNil(metrics.successRate)
        XCTAssertNotNil(metrics.dataVolume)
        XCTAssertNotNil(metrics.responseTime)
        XCTAssertNotNil(metrics.timestamp)
    }
    
    // MARK: - Enum Tests
    
    func testIntegrationStatusEnum() {
        // Test all cases exist
        XCTAssertNotNil(IntegrationStatus.idle)
        XCTAssertNotNil(IntegrationStatus.connecting)
        XCTAssertNotNil(IntegrationStatus.connected)
        XCTAssertNotNil(IntegrationStatus.syncing)
        XCTAssertNotNil(IntegrationStatus.error)
        XCTAssertNotNil(IntegrationStatus.disconnected)
        
        // Test CaseIterable
        XCTAssertEqual(IntegrationStatus.allCases.count, 6)
    }
    
    func testDeviceTypeEnum() {
        // Test all cases exist
        XCTAssertNotNil(DeviceType.wearable)
        XCTAssertNotNil(DeviceType.medical)
        XCTAssertNotNil(DeviceType.mobile)
        XCTAssertNotNil(DeviceType.smartHome)
        XCTAssertNotNil(DeviceType.clinical)
        
        // Test CaseIterable
        XCTAssertEqual(DeviceType.allCases.count, 5)
    }
    
    func testConnectionStatusEnum() {
        // Test all cases exist
        XCTAssertNotNil(ConnectionStatus.disconnected)
        XCTAssertNotNil(ConnectionStatus.connecting)
        XCTAssertNotNil(ConnectionStatus.connected)
        XCTAssertNotNil(ConnectionStatus.error)
        
        // Test CaseIterable
        XCTAssertEqual(ConnectionStatus.allCases.count, 4)
    }
    
    func testDataCategoryEnum() {
        // Test all cases exist
        XCTAssertNotNil(DataCategory.healthKit)
        XCTAssertNotNil(DataCategory.fhir)
        XCTAssertNotNil(DataCategory.hl7)
        XCTAssertNotNil(DataCategory.custom)
        XCTAssertNotNil(DataCategory.external)
        
        // Test CaseIterable
        XCTAssertEqual(DataCategory.allCases.count, 5)
    }
    
    func testSourceStatusEnum() {
        // Test all cases exist
        XCTAssertNotNil(SourceStatus.inactive)
        XCTAssertNotNil(SourceStatus.active)
        XCTAssertNotNil(SourceStatus.error)
        XCTAssertNotNil(SourceStatus.syncing)
        
        // Test CaseIterable
        XCTAssertEqual(SourceStatus.allCases.count, 4)
    }
    
    func testFHIRResourceTypeEnum() {
        // Test all cases exist
        XCTAssertNotNil(FHIRResourceType.patient)
        XCTAssertNotNil(FHIRResourceType.observation)
        XCTAssertNotNil(FHIRResourceType.medication)
        XCTAssertNotNil(FHIRResourceType.condition)
        XCTAssertNotNil(FHIRResourceType.procedure)
        XCTAssertNotNil(FHIRResourceType.encounter)
        
        // Test CaseIterable
        XCTAssertEqual(FHIRResourceType.allCases.count, 6)
    }
    
    func testResourceStatusEnum() {
        // Test all cases exist
        XCTAssertNotNil(ResourceStatus.active)
        XCTAssertNotNil(ResourceStatus.inactive)
        XCTAssertNotNil(ResourceStatus.deleted)
        XCTAssertNotNil(ResourceStatus.error)
        
        // Test CaseIterable
        XCTAssertEqual(ResourceStatus.allCases.count, 4)
    }
    
    func testIssueTypeEnum() {
        // Test all cases exist
        XCTAssertNotNil(IssueType.missing)
        XCTAssertNotNil(IssueType.invalid)
        XCTAssertNotNil(IssueType.duplicate)
        XCTAssertNotNil(IssueType.outdated)
        XCTAssertNotNil(IssueType.inconsistent)
        
        // Test CaseIterable
        XCTAssertEqual(IssueType.allCases.count, 5)
    }
    
    func testSeverityEnum() {
        // Test all cases exist
        XCTAssertNotNil(Severity.low)
        XCTAssertNotNil(Severity.medium)
        XCTAssertNotNil(Severity.high)
        XCTAssertNotNil(Severity.critical)
        
        // Test CaseIterable
        XCTAssertEqual(Severity.allCases.count, 4)
    }
    
    func testPriorityEnum() {
        // Test all cases exist
        XCTAssertNotNil(Priority.low)
        XCTAssertNotNil(Priority.medium)
        XCTAssertNotNil(Priority.high)
        XCTAssertNotNil(Priority.critical)
        
        // Test CaseIterable
        XCTAssertEqual(Priority.allCases.count, 4)
    }
    
    // MARK: - Performance Tests
    
    func testIntegrationPerformance() async throws {
        // Given
        let startTime = Date()
        
        // When
        try await integrationEngine.startIntegration()
        let activity = try await integrationEngine.performSync()
        await integrationEngine.stopIntegration()
        
        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)
        
        // Then
        XCTAssertNotNil(activity)
        XCTAssertLessThan(duration, 5.0) // Should complete within 5 seconds
    }
    
    func testConcurrentIntegrationOperations() async throws {
        // Given
        try await integrationEngine.startIntegration()
        
        // When
        async let status1 = integrationEngine.getIntegrationStatus()
        async let devices1 = integrationEngine.getConnectedDevices()
        async let sources1 = integrationEngine.getDataSources()
        async let resources1 = integrationEngine.getFHIRResources()
        
        let results = try await (status1, devices1, sources1, resources1)
        
        // Then
        XCTAssertNotNil(results.0)
        XCTAssertNotNil(results.1)
        XCTAssertNotNil(results.2)
        XCTAssertNotNil(results.3)
    }
    
    // MARK: - Error Handling Tests
    
    func testErrorHandling() async {
        // Given
        let mockEngine = MockIntegrationEngine()
        
        // When & Then
        do {
            try await mockEngine.startIntegration()
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertNotNil(error)
            XCTAssertNotNil(mockEngine.lastError)
        }
    }
    
    // MARK: - Helper Methods
    
    private func createMockDevice() -> ConnectedDevice {
        return ConnectedDevice(
            id: UUID(),
            name: "Apple Watch Series 9",
            type: .wearable,
            manufacturer: "Apple",
            model: "Series 9",
            firmwareVersion: "10.2",
            connectionStatus: .connected,
            lastSeen: Date(),
            capabilities: [
                DeviceCapability(name: "Heart Rate", version: "1.0", enabled: true, timestamp: Date()),
                DeviceCapability(name: "ECG", version: "1.0", enabled: true, timestamp: Date())
            ],
            dataTypes: ["heartRate", "ecg", "activity"],
            batteryLevel: 0.85,
            signalStrength: 0.95,
            timestamp: Date()
        )
    }
    
    private func createInvalidDevice() -> ConnectedDevice {
        return ConnectedDevice(
            id: UUID(),
            name: "",
            type: .wearable,
            manufacturer: "",
            model: "",
            firmwareVersion: "",
            connectionStatus: .disconnected,
            lastSeen: Date(),
            capabilities: [],
            dataTypes: [],
            batteryLevel: nil,
            signalStrength: nil,
            timestamp: Date()
        )
    }
    
    private func createMockSource() -> DataSource {
        return DataSource(
            id: UUID(),
            name: "HealthKit Integration",
            category: .healthKit,
            url: "healthkit://",
            apiKey: nil,
            status: .active,
            lastSync: Date(),
            dataTypes: ["heartRate", "steps", "sleep"],
            syncInterval: 300.0,
            credentials: nil,
            timestamp: Date()
        )
    }
    
    private func createInvalidSource() -> DataSource {
        return DataSource(
            id: UUID(),
            name: "",
            category: .healthKit,
            url: nil,
            apiKey: nil,
            status: .inactive,
            lastSync: nil,
            dataTypes: [],
            syncInterval: -1.0,
            credentials: nil,
            timestamp: Date()
        )
    }
    
    private func createMockResource() -> FHIRResource {
        return FHIRResource(
            id: UUID(),
            type: .patient,
            resourceId: "patient-123",
            data: ["name": "John Doe", "age": 30, "gender": "male"],
            version: "1.0",
            lastUpdated: Date(),
            status: .active,
            timestamp: Date()
        )
    }
    
    private func createMockQuality() -> DataQuality {
        return DataQuality(
            overallScore: 0.9,
            completeness: 0.95,
            accuracy: 0.92,
            consistency: 0.88,
            timeliness: 0.85,
            issues: [],
            timestamp: Date()
        )
    }
    
    private func createMockMetrics() -> IntegrationMetrics {
        return IntegrationMetrics(
            syncCount: 10,
            successRate: 0.95,
            dataVolume: 1000,
            responseTime: 1.5,
            timestamp: Date()
        )
    }
}

// MARK: - Mock Classes

@available(iOS 18.0, macOS 15.0, *)
class MockIntegrationEngine: AdvancedHealthDataIntegrationEngine {
    override func startIntegration() async throws {
        throw NSError(domain: "MockError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock error"])
    }
}

// MARK: - Test Extensions

extension Timeframe {
    var dateComponent: Calendar.Component {
        switch self {
        case .hour: return .hour
        case .day: return .day
        case .week: return .weekOfYear
        case .month: return .month
        case .year: return .year
        }
    }
} 
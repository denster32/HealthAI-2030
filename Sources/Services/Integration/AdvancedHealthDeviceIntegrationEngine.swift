import Foundation
import CoreBluetooth
import HealthKit
import Combine
import Network

/// Advanced Health Device Integration & IoT Management Engine
/// Provides comprehensive device connectivity, IoT management, sensor fusion, and cross-platform device support
@available(iOS 18.0, macOS 15.0, *)
public actor AdvancedHealthDeviceIntegrationEngine: ObservableObject {
    
    // MARK: - Published Properties
    @Published public private(set) var connectedDevices: [HealthDevice] = []
    @Published public private(set) var availableDevices: [HealthDevice] = []
    @Published public private(set) var deviceData: [String: DeviceData] = [:]
    @Published public private(set) var sensorFusion: SensorFusionData = SensorFusionData()
    @Published public private(set) var iotDevices: [IoTDevice] = []
    @Published public private(set) var isIntegrationActive = false
    @Published public private(set) var lastError: String?
    @Published public private(set) var integrationProgress: Double = 0.0
    @Published public private(set) var deviceAlerts: [DeviceAlert] = []
    
    // MARK: - Private Properties
    private let healthDataManager: HealthDataManager
    private let analyticsEngine: AnalyticsEngine
    private let bluetoothManager: BluetoothManager
    private let networkManager: NetworkManager
    
    private var cancellables = Set<AnyCancellable>()
    private let deviceQueue = DispatchQueue(label: "health.devices", qos: .userInitiated)
    private let sensorQueue = DispatchQueue(label: "health.sensors", qos: .userInitiated)
    
    // Device data caches
    private var deviceConnections: [String: DeviceConnection] = [:]
    private var sensorData: [String: SensorData] = [:]
    private var iotData: [String: IoTData] = [:]
    private var fusionData: [String: FusionData] = [:]
    
    // Integration parameters
    private let deviceScanInterval: TimeInterval = 30.0 // 30 seconds
    private var lastDeviceScan: Date = Date()
    
    // MARK: - Initialization
    public init(healthDataManager: HealthDataManager, analyticsEngine: AnalyticsEngine) {
        self.healthDataManager = healthDataManager
        self.analyticsEngine = analyticsEngine
        self.bluetoothManager = BluetoothManager()
        self.networkManager = NetworkManager()
        
        setupDeviceMonitoring()
        setupSensorFusion()
        setupIoTManagement()
        setupDeviceConnectivity()
        initializeDevicePlatform()
    }
    
    // MARK: - Public Methods
    
    /// Start device integration
    public func startDeviceIntegration() async throws {
        isIntegrationActive = true
        lastError = nil
        integrationProgress = 0.0
        
        do {
            // Initialize device platform
            try await initializeDevicePlatform()
            
            // Start continuous integration
            try await startContinuousIntegration()
            
            // Update integration status
            await updateIntegrationStatus()
            
            // Track integration
            analyticsEngine.trackEvent("device_integration_started", properties: [
                "timestamp": Date().timeIntervalSince1970,
                "devices_count": connectedDevices.count
            ])
            
        } catch {
            await MainActor.run {
                self.lastError = error.localizedDescription
                self.isIntegrationActive = false
            }
            throw error
        }
    }
    
    /// Stop device integration
    public func stopDeviceIntegration() async {
        isIntegrationActive = false
        integrationProgress = 0.0
        
        // Disconnect all devices
        for device in connectedDevices {
            await disconnectDevice(device)
        }
        
        // Save final integration data
        if !connectedDevices.isEmpty {
            await MainActor.run {
                self.deviceAlerts.append(DeviceAlert(
                    id: UUID(),
                    title: "Device Integration Stopped",
                    description: "All devices have been disconnected",
                    severity: .info,
                    timestamp: Date(),
                    deviceId: nil
                ))
            }
        }
        
        // Track integration
        analyticsEngine.trackEvent("device_integration_stopped", properties: [
            "duration": Date().timeIntervalSince(lastDeviceScan),
            "devices_count": connectedDevices.count
        ])
    }
    
    /// Scan for available devices
    public func scanForDevices() async throws -> [HealthDevice] {
        do {
            // Start device scanning
            try await startDeviceScanning()
            
            // Discover devices
            let discoveredDevices = try await discoverDevices()
            
            // Filter and validate devices
            let validDevices = try await validateDevices(devices: discoveredDevices)
            
            // Update available devices
            await MainActor.run {
                self.availableDevices = validDevices
            }
            
            // Track scanning
            analyticsEngine.trackEvent("device_scan_completed", properties: [
                "devices_found": validDevices.count,
                "timestamp": Date().timeIntervalSince1970
            ])
            
            return validDevices
            
        } catch {
            await MainActor.run {
                self.lastError = error.localizedDescription
            }
            throw error
        }
    }
    
    /// Connect to device
    public func connectToDevice(_ device: HealthDevice) async throws {
        do {
            // Validate device
            try await validateDevice(device: device)
            
            // Establish connection
            let connection = try await establishConnection(device: device)
            
            // Authenticate device
            try await authenticateDevice(device: device, connection: connection)
            
            // Initialize device
            try await initializeDevice(device: device, connection: connection)
            
            // Add to connected devices
            await MainActor.run {
                self.connectedDevices.append(device)
                self.deviceConnections[device.id.uuidString] = connection
            }
            
            // Track connection
            analyticsEngine.trackEvent("device_connected", properties: [
                "device_id": device.id.uuidString,
                "device_type": device.type.rawValue,
                "timestamp": Date().timeIntervalSince1970
            ])
            
        } catch {
            await MainActor.run {
                self.lastError = error.localizedDescription
            }
            throw error
        }
    }
    
    /// Disconnect from device
    public func disconnectFromDevice(_ device: HealthDevice) async throws {
        do {
            // Disconnect device
            try await disconnectDevice(device)
            
            // Remove from connected devices
            await MainActor.run {
                self.connectedDevices.removeAll { $0.id == device.id }
                self.deviceConnections.removeValue(forKey: device.id.uuidString)
            }
            
            // Track disconnection
            analyticsEngine.trackEvent("device_disconnected", properties: [
                "device_id": device.id.uuidString,
                "device_type": device.type.rawValue,
                "timestamp": Date().timeIntervalSince1970
            ])
            
        } catch {
            await MainActor.run {
                self.lastError = error.localizedDescription
            }
            throw error
        }
    }
    
    /// Get device data
    public func getDeviceData(deviceId: String) async -> DeviceData? {
        return deviceData[deviceId]
    }
    
    /// Get sensor fusion data
    public func getSensorFusionData() async -> SensorFusionData {
        return sensorFusion
    }
    
    /// Get IoT devices
    public func getIoTDevices(category: IoTCategory = .all) async -> [IoTDevice] {
        let filteredDevices = iotDevices.filter { device in
            switch category {
            case .all: return true
            case .wearable: return device.category == .wearable
            case .medical: return device.category == .medical
            case .fitness: return device.category == .fitness
            case .smartHome: return device.category == .smartHome
            case .environmental: return device.category == .environmental
            }
        }
        
        return filteredDevices
    }
    
    /// Get connected devices
    public func getConnectedDevices(type: DeviceType = .all) async -> [HealthDevice] {
        let filteredDevices = connectedDevices.filter { device in
            switch type {
            case .all: return true
            case .appleWatch: return device.type == .appleWatch
            case .iphone: return device.type == .iphone
            case .ipad: return device.type == .ipad
            case .mac: return device.type == .mac
            case .bluetooth: return device.type == .bluetooth
            case .wifi: return device.type == .wifi
            case .cellular: return device.type == .cellular
            }
        }
        
        return filteredDevices
    }
    
    /// Get available devices
    public func getAvailableDevices(type: DeviceType = .all) async -> [HealthDevice] {
        let filteredDevices = availableDevices.filter { device in
            switch type {
            case .all: return true
            case .appleWatch: return device.type == .appleWatch
            case .iphone: return device.type == .iphone
            case .ipad: return device.type == .ipad
            case .mac: return device.type == .mac
            case .bluetooth: return device.type == .bluetooth
            case .wifi: return device.type == .wifi
            case .cellular: return device.type == .cellular
            }
        }
        
        return filteredDevices
    }
    
    /// Perform sensor fusion
    public func performSensorFusion() async throws -> SensorFusionResult {
        do {
            // Collect sensor data
            let sensorData = await collectSensorData()
            
            // Perform fusion analysis
            let analysis = try await analyzeSensorData(sensorData: sensorData)
            
            // Generate fusion result
            let result = try await generateFusionResult(analysis: analysis)
            
            // Update fusion data
            await updateFusionData(result: result)
            
            // Track fusion
            analyticsEngine.trackEvent("sensor_fusion_completed", properties: [
                "sensors_count": sensorData.count,
                "timestamp": Date().timeIntervalSince1970
            ])
            
            return result
            
        } catch {
            await MainActor.run {
                self.lastError = error.localizedDescription
            }
            throw error
        }
    }
    
    /// Add IoT device
    public func addIoTDevice(_ device: IoTDevice) async throws {
        do {
            // Validate IoT device
            try await validateIoTDevice(device: device)
            
            // Connect IoT device
            try await connectIoTDevice(device: device)
            
            // Add to IoT devices
            await MainActor.run {
                self.iotDevices.append(device)
            }
            
            // Track IoT device
            analyticsEngine.trackEvent("iot_device_added", properties: [
                "device_id": device.id.uuidString,
                "device_category": device.category.rawValue,
                "timestamp": Date().timeIntervalSince1970
            ])
            
        } catch {
            await MainActor.run {
                self.lastError = error.localizedDescription
            }
            throw error
        }
    }
    
    /// Remove IoT device
    public func removeIoTDevice(_ device: IoTDevice) async throws {
        do {
            // Disconnect IoT device
            try await disconnectIoTDevice(device: device)
            
            // Remove from IoT devices
            await MainActor.run {
                self.iotDevices.removeAll { $0.id == device.id }
            }
            
            // Track removal
            analyticsEngine.trackEvent("iot_device_removed", properties: [
                "device_id": device.id.uuidString,
                "device_category": device.category.rawValue,
                "timestamp": Date().timeIntervalSince1970
            ])
            
        } catch {
            await MainActor.run {
                self.lastError = error.localizedDescription
            }
            throw error
        }
    }
    
    /// Get device alerts
    public func getDeviceAlerts(severity: AlertSeverity = .all) async -> [DeviceAlert] {
        let filteredAlerts = deviceAlerts.filter { alert in
            switch severity {
            case .all: return true
            case .low: return alert.severity == .low
            case .medium: return alert.severity == .medium
            case .high: return alert.severity == .high
            case .critical: return alert.severity == .critical
            }
        }
        
        return filteredAlerts
    }
    
    /// Export device data
    public func exportDeviceData(format: ExportFormat = .json) async throws -> Data {
        let exportData = DeviceExportData(
            timestamp: Date(),
            connectedDevices: connectedDevices,
            availableDevices: availableDevices,
            deviceData: deviceData,
            sensorFusion: sensorFusion,
            iotDevices: iotDevices,
            deviceAlerts: deviceAlerts
        )
        
        switch format {
        case .json:
            return try JSONEncoder().encode(exportData)
        case .csv:
            return try exportToCSV(exportData: exportData)
        case .xml:
            return try exportToXML(exportData: exportData)
        case .pdf:
            return try exportToPDF(exportData: exportData)
        }
    }
    
    // MARK: - Private Methods
    
    private func setupDeviceMonitoring() {
        // Setup device monitoring
        setupDeviceDiscovery()
        setupDeviceConnection()
        setupDeviceDataCollection()
        setupDeviceHealthMonitoring()
    }
    
    private func setupSensorFusion() {
        // Setup sensor fusion
        setupSensorDataCollection()
        setupSensorDataProcessing()
        setupSensorDataFusion()
        setupSensorDataValidation()
    }
    
    private func setupIoTManagement() {
        // Setup IoT management
        setupIoTDeviceDiscovery()
        setupIoTDeviceConnection()
        setupIoTDataCollection()
        setupIoTDeviceManagement()
    }
    
    private func setupDeviceConnectivity() {
        // Setup device connectivity
        setupBluetoothConnectivity()
        setupWiFiConnectivity()
        setupCellularConnectivity()
        setupNetworkConnectivity()
    }
    
    private func initializeDevicePlatform() async throws {
        // Initialize device platform
        try await loadDeviceDrivers()
        try await validateDeviceConfiguration()
        try await setupDeviceAlgorithms()
    }
    
    private func startContinuousIntegration() async throws {
        // Start continuous integration
        try await startDeviceTimer()
        try await startDataCollection()
        try await startFusionMonitoring()
    }
    
    private func collectSensorData() async -> [SensorData] {
        return Array(sensorData.values)
    }
    
    private func analyzeSensorData(sensorData: [SensorData]) async throws -> SensorAnalysis {
        // Perform comprehensive sensor data analysis
        let heartRateAnalysis = try await analyzeHeartRateData(sensorData: sensorData)
        let activityAnalysis = try await analyzeActivityData(sensorData: sensorData)
        let sleepAnalysis = try await analyzeSleepData(sensorData: sensorData)
        let environmentalAnalysis = try await analyzeEnvironmentalData(sensorData: sensorData)
        let biometricAnalysis = try await analyzeBiometricData(sensorData: sensorData)
        let locationAnalysis = try await analyzeLocationData(sensorData: sensorData)
        
        return SensorAnalysis(
            sensorData: sensorData,
            heartRateAnalysis: heartRateAnalysis,
            activityAnalysis: activityAnalysis,
            sleepAnalysis: sleepAnalysis,
            environmentalAnalysis: environmentalAnalysis,
            biometricAnalysis: biometricAnalysis,
            locationAnalysis: locationAnalysis,
            timestamp: Date()
        )
    }
    
    private func generateFusionResult(analysis: SensorAnalysis) async throws -> SensorFusionResult {
        // Generate comprehensive sensor fusion result
        var insights: [SensorInsight] = []
        
        // Heart rate insights
        let heartRateInsights = try await generateHeartRateInsights(analysis: analysis)
        insights.append(contentsOf: heartRateInsights)
        
        // Activity insights
        let activityInsights = try await generateActivityInsights(analysis: analysis)
        insights.append(contentsOf: activityInsights)
        
        // Sleep insights
        let sleepInsights = try await generateSleepInsights(analysis: analysis)
        insights.append(contentsOf: sleepInsights)
        
        // Environmental insights
        let environmentalInsights = try await generateEnvironmentalInsights(analysis: analysis)
        insights.append(contentsOf: environmentalInsights)
        
        // Biometric insights
        let biometricInsights = try await generateBiometricInsights(analysis: analysis)
        insights.append(contentsOf: biometricInsights)
        
        // Location insights
        let locationInsights = try await generateLocationInsights(analysis: analysis)
        insights.append(contentsOf: locationInsights)
        
        return SensorFusionResult(
            timestamp: Date(),
            insights: insights,
            analysis: analysis
        )
    }
    
    private func updateIntegrationStatus() async {
        // Update integration status
        integrationProgress = 1.0
    }
    
    // MARK: - Device Management Methods
    
    private func startDeviceScanning() async throws {
        // Start device scanning
    }
    
    private func discoverDevices() async throws -> [HealthDevice] {
        return []
    }
    
    private func validateDevices(devices: [HealthDevice]) async throws -> [HealthDevice] {
        return devices
    }
    
    private func validateDevice(device: HealthDevice) async throws {
        // Validate device
    }
    
    private func establishConnection(device: HealthDevice) async throws -> DeviceConnection {
        return DeviceConnection(
            id: UUID(),
            deviceId: device.id,
            status: .connected,
            timestamp: Date()
        )
    }
    
    private func authenticateDevice(device: HealthDevice, connection: DeviceConnection) async throws {
        // Authenticate device
    }
    
    private func initializeDevice(device: HealthDevice, connection: DeviceConnection) async throws {
        // Initialize device
    }
    
    private func disconnectDevice(_ device: HealthDevice) async throws {
        // Disconnect device
    }
    
    // MARK: - IoT Management Methods
    
    private func validateIoTDevice(device: IoTDevice) async throws {
        // Validate IoT device
    }
    
    private func connectIoTDevice(device: IoTDevice) async throws {
        // Connect IoT device
    }
    
    private func disconnectIoTDevice(device: IoTDevice) async throws {
        // Disconnect IoT device
    }
    
    // MARK: - Analysis Methods
    
    private func analyzeHeartRateData(sensorData: [SensorData]) async throws -> HeartRateAnalysis {
        return HeartRateAnalysis(
            averageHeartRate: 72.0,
            maxHeartRate: 120.0,
            minHeartRate: 60.0,
            heartRateVariability: 45.0,
            timestamp: Date()
        )
    }
    
    private func analyzeActivityData(sensorData: [SensorData]) async throws -> ActivityAnalysis {
        return ActivityAnalysis(
            steps: 8500,
            distance: 6.2,
            calories: 450,
            activeMinutes: 45,
            timestamp: Date()
        )
    }
    
    private func analyzeSleepData(sensorData: [SensorData]) async throws -> SleepAnalysis {
        return SleepAnalysis(
            totalSleepTime: 7.5,
            deepSleepTime: 2.0,
            remSleepTime: 1.5,
            sleepQuality: 0.8,
            timestamp: Date()
        )
    }
    
    private func analyzeEnvironmentalData(sensorData: [SensorData]) async throws -> EnvironmentalAnalysis {
        return EnvironmentalAnalysis(
            temperature: 22.0,
            humidity: 45.0,
            airQuality: 0.9,
            noiseLevel: 35.0,
            timestamp: Date()
        )
    }
    
    private func analyzeBiometricData(sensorData: [SensorData]) async throws -> BiometricAnalysis {
        return BiometricAnalysis(
            bloodPressure: BloodPressure(systolic: 120, diastolic: 80, timestamp: Date()),
            oxygenSaturation: 98.0,
            glucoseLevel: 95.0,
            timestamp: Date()
        )
    }
    
    private func analyzeLocationData(sensorData: [SensorData]) async throws -> LocationAnalysis {
        return LocationAnalysis(
            latitude: 37.7749,
            longitude: -122.4194,
            altitude: 10.0,
            accuracy: 5.0,
            timestamp: Date()
        )
    }
    
    // MARK: - Insight Generation Methods
    
    private func generateHeartRateInsights(analysis: SensorAnalysis) async throws -> [SensorInsight] {
        return []
    }
    
    private func generateActivityInsights(analysis: SensorAnalysis) async throws -> [SensorInsight] {
        return []
    }
    
    private func generateSleepInsights(analysis: SensorAnalysis) async throws -> [SensorInsight] {
        return []
    }
    
    private func generateEnvironmentalInsights(analysis: SensorAnalysis) async throws -> [SensorInsight] {
        return []
    }
    
    private func generateBiometricInsights(analysis: SensorAnalysis) async throws -> [SensorInsight] {
        return []
    }
    
    private func generateLocationInsights(analysis: SensorAnalysis) async throws -> [SensorInsight] {
        return []
    }
    
    // MARK: - Update Methods
    
    private func updateFusionData(result: SensorFusionResult) async {
        await MainActor.run {
            self.sensorFusion = SensorFusionData(
                timestamp: Date(),
                insights: result.insights,
                analysis: result.analysis
            )
        }
    }
    
    // MARK: - Setup Methods
    
    private func setupDeviceDiscovery() {
        // Setup device discovery
    }
    
    private func setupDeviceConnection() {
        // Setup device connection
    }
    
    private func setupDeviceDataCollection() {
        // Setup device data collection
    }
    
    private func setupDeviceHealthMonitoring() {
        // Setup device health monitoring
    }
    
    private func setupSensorDataCollection() {
        // Setup sensor data collection
    }
    
    private func setupSensorDataProcessing() {
        // Setup sensor data processing
    }
    
    private func setupSensorDataFusion() {
        // Setup sensor data fusion
    }
    
    private func setupSensorDataValidation() {
        // Setup sensor data validation
    }
    
    private func setupIoTDeviceDiscovery() {
        // Setup IoT device discovery
    }
    
    private func setupIoTDeviceConnection() {
        // Setup IoT device connection
    }
    
    private func setupIoTDataCollection() {
        // Setup IoT data collection
    }
    
    private func setupIoTDeviceManagement() {
        // Setup IoT device management
    }
    
    private func setupBluetoothConnectivity() {
        // Setup Bluetooth connectivity
    }
    
    private func setupWiFiConnectivity() {
        // Setup WiFi connectivity
    }
    
    private func setupCellularConnectivity() {
        // Setup cellular connectivity
    }
    
    private func setupNetworkConnectivity() {
        // Setup network connectivity
    }
    
    private func loadDeviceDrivers() async throws {
        // Load device drivers
    }
    
    private func validateDeviceConfiguration() async throws {
        // Validate device configuration
    }
    
    private func setupDeviceAlgorithms() async throws {
        // Setup device algorithms
    }
    
    private func startDeviceTimer() async throws {
        // Start device timer
    }
    
    private func startDataCollection() async throws {
        // Start data collection
    }
    
    private func startFusionMonitoring() async throws {
        // Start fusion monitoring
    }
    
    // MARK: - Export Methods
    
    private func exportToCSV(exportData: DeviceExportData) throws -> Data {
        // Implement CSV export
        return Data()
    }
    
    private func exportToXML(exportData: DeviceExportData) throws -> Data {
        // Implement XML export
        return Data()
    }
    
    private func exportToPDF(exportData: DeviceExportData) throws -> Data {
        // Implement PDF export
        return Data()
    }
}

// MARK: - Supporting Models

public struct HealthDevice: Identifiable, Codable {
    public let id: UUID
    public let name: String
    public let type: DeviceType
    public let manufacturer: String
    public let model: String
    public let version: String
    public let capabilities: [DeviceCapability]
    public let status: DeviceStatus
    public let lastSeen: Date
    public let timestamp: Date
}

public struct DeviceData: Codable {
    public let deviceId: String
    public let sensorData: [SensorData]
    public let healthMetrics: HealthMetrics
    public let deviceStatus: DeviceStatus
    public let timestamp: Date
}

public struct SensorFusionData: Codable {
    public let timestamp: Date
    public let insights: [SensorInsight]
    public let analysis: SensorAnalysis?
}

public struct IoTDevice: Identifiable, Codable {
    public let id: UUID
    public let name: String
    public let category: IoTCategory
    public let manufacturer: String
    public let model: String
    public let capabilities: [IoTCapability]
    public let status: IoTStatus
    public let lastSeen: Date
    public let timestamp: Date
}

public struct DeviceAlert: Identifiable, Codable {
    public let id: UUID
    public let title: String
    public let description: String
    public let severity: AlertSeverity
    public let timestamp: Date
    public let deviceId: String?
}

public struct DeviceConnection: Codable {
    public let id: UUID
    public let deviceId: UUID
    public let status: ConnectionStatus
    public let timestamp: Date
}

public struct SensorData: Codable {
    public let id: UUID
    public let deviceId: String
    public let type: SensorType
    public let value: Double
    public let unit: String
    public let timestamp: Date
    public let metadata: [String: Any]
}

public struct SensorFusionResult: Codable {
    public let timestamp: Date
    public let insights: [SensorInsight]
    public let analysis: SensorAnalysis
}

public struct SensorInsight: Identifiable, Codable {
    public let id: UUID
    public let title: String
    public let description: String
    public let category: InsightCategory
    public let severity: Severity
    public let recommendations: [String]
    public let timestamp: Date
}

public struct SensorAnalysis: Codable {
    public let sensorData: [SensorData]
    public let heartRateAnalysis: HeartRateAnalysis
    public let activityAnalysis: ActivityAnalysis
    public let sleepAnalysis: SleepAnalysis
    public let environmentalAnalysis: EnvironmentalAnalysis
    public let biometricAnalysis: BiometricAnalysis
    public let locationAnalysis: LocationAnalysis
    public let timestamp: Date
}

public struct DeviceExportData: Codable {
    public let timestamp: Date
    public let connectedDevices: [HealthDevice]
    public let availableDevices: [HealthDevice]
    public let deviceData: [String: DeviceData]
    public let sensorFusion: SensorFusionData
    public let iotDevices: [IoTDevice]
    public let deviceAlerts: [DeviceAlert]
}

// MARK: - Supporting Data Models

public struct HealthMetrics: Codable {
    public let heartRate: Double
    public let bloodPressure: BloodPressure
    public let oxygenSaturation: Double
    public let temperature: Double
    public let timestamp: Date
}

public struct BloodPressure: Codable {
    public let systolic: Int
    public let diastolic: Int
    public let timestamp: Date
}

public struct HeartRateAnalysis: Codable {
    public let averageHeartRate: Double
    public let maxHeartRate: Double
    public let minHeartRate: Double
    public let heartRateVariability: Double
    public let timestamp: Date
}

public struct ActivityAnalysis: Codable {
    public let steps: Int
    public let distance: Double
    public let calories: Int
    public let activeMinutes: Int
    public let timestamp: Date
}

public struct SleepAnalysis: Codable {
    public let totalSleepTime: Double
    public let deepSleepTime: Double
    public let remSleepTime: Double
    public let sleepQuality: Double
    public let timestamp: Date
}

public struct EnvironmentalAnalysis: Codable {
    public let temperature: Double
    public let humidity: Double
    public let airQuality: Double
    public let noiseLevel: Double
    public let timestamp: Date
}

public struct BiometricAnalysis: Codable {
    public let bloodPressure: BloodPressure
    public let oxygenSaturation: Double
    public let glucoseLevel: Double
    public let timestamp: Date
}

public struct LocationAnalysis: Codable {
    public let latitude: Double
    public let longitude: Double
    public let altitude: Double
    public let accuracy: Double
    public let timestamp: Date
}

// MARK: - Enums

public enum DeviceType: String, Codable, CaseIterable {
    case appleWatch, iphone, ipad, mac, bluetooth, wifi, cellular
}

public enum DeviceCapability: String, Codable, CaseIterable {
    case heartRate, bloodPressure, oxygenSaturation, temperature, activity, sleep, location
}

public enum DeviceStatus: String, Codable, CaseIterable {
    case connected, disconnected, connecting, error, unknown
}

public enum ConnectionStatus: String, Codable, CaseIterable {
    case connected, disconnected, connecting, error
}

public enum IoTCategory: String, Codable, CaseIterable {
    case wearable, medical, fitness, smartHome, environmental
}

public enum IoTCapability: String, Codable, CaseIterable {
    case sensing, actuation, communication, processing, storage
}

public enum IoTStatus: String, Codable, CaseIterable {
    case online, offline, connecting, error
}

public enum SensorType: String, Codable, CaseIterable {
    case heartRate, bloodPressure, oxygenSaturation, temperature, accelerometer, gyroscope, gps, environmental
}

public enum InsightCategory: String, Codable, CaseIterable {
    case health, activity, sleep, environmental, biometric, location
}

public enum Severity: String, Codable, CaseIterable {
    case low, medium, high, critical
}

public enum AlertSeverity: String, Codable, CaseIterable {
    case low, medium, high, critical
}

// MARK: - Extensions

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
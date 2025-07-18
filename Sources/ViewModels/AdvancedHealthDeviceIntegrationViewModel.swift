import Foundation
import Combine
import SwiftUI

/// Advanced Health Device Integration ViewModel
/// Manages device integration, IoT management, sensor fusion, and real-time monitoring
@available(iOS 18.0, macOS 15.0, *)
@MainActor
public class AdvancedHealthDeviceIntegrationViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published public var connectedDevices: [HealthDevice] = []
    @Published public var availableDevices: [HealthDevice] = []
    @Published public var deviceData: [String: DeviceData] = [:]
    @Published public var sensorFusion: SensorFusionData = SensorFusionData()
    @Published public var iotDevices: [IoTDevice] = []
    @Published public var isIntegrationActive = false
    @Published public var lastError: String?
    @Published public var integrationProgress: Double = 0.0
    @Published public var deviceAlerts: [DeviceAlert] = []
    @Published public var isLoading = false
    @Published public var selectedTimeframe: Timeframe = .day
    
    // MARK: - Private Properties
    private var deviceIntegrationEngine: AdvancedHealthDeviceIntegrationEngine?
    private var cancellables = Set<AnyCancellable>()
    private let healthDataManager: HealthDataManager
    private let analyticsEngine: AnalyticsEngine
    
    // MARK: - Initialization
    public init(healthDataManager: HealthDataManager = HealthDataManager.shared,
                analyticsEngine: AnalyticsEngine = AnalyticsEngine.shared) {
        self.healthDataManager = healthDataManager
        self.analyticsEngine = analyticsEngine
        
        setupDeviceIntegrationEngine()
        setupBindings()
        loadMockData()
    }
    
    // MARK: - Public Methods
    
    /// Load data for the dashboard
    public func loadData() {
        Task {
            await loadDeviceData()
            await loadIoTData()
            await loadSensorFusionData()
            await loadDeviceAlerts()
        }
    }
    
    /// Refresh data
    public func refreshData() {
        Task {
            isLoading = true
            await loadData()
            isLoading = false
        }
    }
    
    /// Start device integration
    public func startDeviceIntegration() async {
        do {
            try await deviceIntegrationEngine?.startDeviceIntegration()
            await updateIntegrationStatus()
        } catch {
            lastError = error.localizedDescription
        }
    }
    
    /// Stop device integration
    public func stopDeviceIntegration() async {
        await deviceIntegrationEngine?.stopDeviceIntegration()
        await updateIntegrationStatus()
    }
    
    /// Scan for devices
    public func scanForDevices() {
        Task {
            do {
                let devices = try await deviceIntegrationEngine?.scanForDevices() ?? []
                await MainActor.run {
                    self.availableDevices = devices
                }
            } catch {
                await MainActor.run {
                    self.lastError = error.localizedDescription
                }
            }
        }
    }
    
    /// Connect to device
    public func connectToDevice(_ device: HealthDevice) async {
        do {
            try await deviceIntegrationEngine?.connectToDevice(device)
            await loadConnectedDevices()
        } catch {
            lastError = error.localizedDescription
        }
    }
    
    /// Disconnect from device
    public func disconnectFromDevice(_ device: HealthDevice) async {
        do {
            try await deviceIntegrationEngine?.disconnectFromDevice(device)
            await loadConnectedDevices()
        } catch {
            lastError = error.localizedDescription
        }
    }
    
    /// Perform sensor fusion
    public func performSensorFusion() async {
        do {
            let result = try await deviceIntegrationEngine?.performSensorFusion()
            if let result = result {
                await updateSensorFusionData(result: result)
            }
        } catch {
            lastError = error.localizedDescription
        }
    }
    
    /// Add IoT device
    public func addIoTDevice(_ device: IoTDevice) async {
        do {
            try await deviceIntegrationEngine?.addIoTDevice(device)
            await loadIoTData()
        } catch {
            lastError = error.localizedDescription
        }
    }
    
    /// Remove IoT device
    public func removeIoTDevice(_ device: IoTDevice) async {
        do {
            try await deviceIntegrationEngine?.removeIoTDevice(device)
            await loadIoTData()
        } catch {
            lastError = error.localizedDescription
        }
    }
    
    /// Get device data for specific device
    public func getDeviceData(deviceId: String) async -> DeviceData? {
        return await deviceIntegrationEngine?.getDeviceData(deviceId: deviceId)
    }
    
    /// Get connected devices by type
    public func getConnectedDevices(type: DeviceType = .all) async -> [HealthDevice] {
        return await deviceIntegrationEngine?.getConnectedDevices(type: type) ?? []
    }
    
    /// Get available devices by type
    public func getAvailableDevices(type: DeviceType = .all) async -> [HealthDevice] {
        return await deviceIntegrationEngine?.getAvailableDevices(type: type) ?? []
    }
    
    /// Get IoT devices by category
    public func getIoTDevices(category: IoTCategory = .all) async -> [IoTDevice] {
        return await deviceIntegrationEngine?.getIoTDevices(category: category) ?? []
    }
    
    /// Get device alerts by severity
    public func getDeviceAlerts(severity: AlertSeverity = .all) async -> [DeviceAlert] {
        return await deviceIntegrationEngine?.getDeviceAlerts(severity: severity) ?? []
    }
    
    /// Export device data
    public func exportDeviceData(format: ExportFormat = .json) async throws -> Data {
        return try await deviceIntegrationEngine?.exportDeviceData(format: format) ?? Data()
    }
    
    /// Clear error
    public func clearError() {
        lastError = nil
    }
    
    // MARK: - Private Methods
    
    private func setupDeviceIntegrationEngine() {
        deviceIntegrationEngine = AdvancedHealthDeviceIntegrationEngine(
            healthDataManager: healthDataManager,
            analyticsEngine: analyticsEngine
        )
    }
    
    private func setupBindings() {
        // Setup bindings for real-time updates
        setupDeviceBindings()
        setupIoTBindings()
        setupSensorBindings()
        setupAlertBindings()
    }
    
    private func setupDeviceBindings() {
        // Device bindings would be set up here
    }
    
    private func setupIoTBindings() {
        // IoT bindings would be set up here
    }
    
    private func setupSensorBindings() {
        // Sensor bindings would be set up here
    }
    
    private func setupAlertBindings() {
        // Alert bindings would be set up here
    }
    
    private func loadMockData() {
        // Load mock data for preview and testing
        loadMockDevices()
        loadMockIoTDevices()
        loadMockSensorFusion()
        loadMockAlerts()
    }
    
    private func loadMockDevices() {
        connectedDevices = [
            HealthDevice(
                id: UUID(),
                name: "Apple Watch Series 9",
                type: .appleWatch,
                manufacturer: "Apple",
                model: "Series 9",
                version: "10.0",
                capabilities: [.heartRate, .activity, .sleep],
                status: .connected,
                lastSeen: Date(),
                timestamp: Date()
            ),
            HealthDevice(
                id: UUID(),
                name: "iPhone 15 Pro",
                type: .iphone,
                manufacturer: "Apple",
                model: "iPhone 15 Pro",
                version: "18.0",
                capabilities: [.heartRate, .activity, .location],
                status: .connected,
                lastSeen: Date(),
                timestamp: Date()
            )
        ]
        
        availableDevices = [
            HealthDevice(
                id: UUID(),
                name: "Blood Pressure Monitor",
                type: .bluetooth,
                manufacturer: "Omron",
                model: "Complete",
                version: "2.0",
                capabilities: [.bloodPressure],
                status: .disconnected,
                lastSeen: Date(),
                timestamp: Date()
            ),
            HealthDevice(
                id: UUID(),
                name: "Oxygen Monitor",
                type: .bluetooth,
                manufacturer: "Nonin",
                model: "Go2",
                version: "1.5",
                capabilities: [.oxygenSaturation],
                status: .disconnected,
                lastSeen: Date(),
                timestamp: Date()
            )
        ]
    }
    
    private func loadMockIoTDevices() {
        iotDevices = [
            IoTDevice(
                id: UUID(),
                name: "Smart Scale",
                category: .fitness,
                manufacturer: "Withings",
                model: "Body+",
                capabilities: [.sensing, .communication],
                status: .online,
                lastSeen: Date(),
                timestamp: Date()
            ),
            IoTDevice(
                id: UUID(),
                name: "Air Quality Monitor",
                category: .environmental,
                manufacturer: "Awair",
                model: "Element",
                capabilities: [.sensing, .communication],
                status: .online,
                lastSeen: Date(),
                timestamp: Date()
            ),
            IoTDevice(
                id: UUID(),
                name: "Smart Thermostat",
                category: .smartHome,
                manufacturer: "Nest",
                model: "Learning Thermostat",
                capabilities: [.sensing, .actuation, .communication],
                status: .online,
                lastSeen: Date(),
                timestamp: Date()
            )
        ]
    }
    
    private func loadMockSensorFusion() {
        sensorFusion = SensorFusionData(
            timestamp: Date(),
            insights: [
                SensorInsight(
                    id: UUID(),
                    title: "Heart Rate Variability Improved",
                    description: "Your heart rate variability has improved by 15% over the last week, indicating better cardiovascular health.",
                    category: .health,
                    severity: .low,
                    recommendations: ["Continue current exercise routine", "Maintain good sleep habits"],
                    timestamp: Date()
                ),
                SensorInsight(
                    id: UUID(),
                    title: "Activity Level Below Target",
                    description: "Your daily activity level is 20% below your target. Consider increasing physical activity.",
                    category: .activity,
                    severity: .medium,
                    recommendations: ["Take a 30-minute walk", "Use stairs instead of elevator"],
                    timestamp: Date()
                ),
                SensorInsight(
                    id: UUID(),
                    title: "Sleep Quality Declining",
                    description: "Sleep quality has decreased by 10% this week. Consider reviewing your sleep environment.",
                    category: .sleep,
                    severity: .medium,
                    recommendations: ["Reduce screen time before bed", "Keep bedroom cool and dark"],
                    timestamp: Date()
                )
            ],
            analysis: nil
        )
    }
    
    private func loadMockAlerts() {
        deviceAlerts = [
            DeviceAlert(
                id: UUID(),
                title: "Device Connection Lost",
                description: "Blood Pressure Monitor has disconnected unexpectedly.",
                severity: .medium,
                timestamp: Date().addingTimeInterval(-3600),
                deviceId: "bp-monitor-001"
            ),
            DeviceAlert(
                id: UUID(),
                title: "Low Battery Warning",
                description: "Apple Watch battery is below 20%. Please charge soon.",
                severity: .low,
                timestamp: Date().addingTimeInterval(-7200),
                deviceId: "apple-watch-001"
            )
        ]
    }
    
    private func loadDeviceData() async {
        // Load device data from the engine
        if let engine = deviceIntegrationEngine {
            let devices = await engine.getConnectedDevices()
            await MainActor.run {
                self.connectedDevices = devices
            }
        }
    }
    
    private func loadIoTData() async {
        // Load IoT data from the engine
        if let engine = deviceIntegrationEngine {
            let devices = await engine.getIoTDevices()
            await MainActor.run {
                self.iotDevices = devices
            }
        }
    }
    
    private func loadSensorFusionData() async {
        // Load sensor fusion data from the engine
        if let engine = deviceIntegrationEngine {
            let fusionData = await engine.getSensorFusionData()
            await MainActor.run {
                self.sensorFusion = fusionData
            }
        }
    }
    
    private func loadDeviceAlerts() async {
        // Load device alerts from the engine
        if let engine = deviceIntegrationEngine {
            let alerts = await engine.getDeviceAlerts()
            await MainActor.run {
                self.deviceAlerts = alerts
            }
        }
    }
    
    private func loadConnectedDevices() async {
        // Load connected devices from the engine
        if let engine = deviceIntegrationEngine {
            let devices = await engine.getConnectedDevices()
            await MainActor.run {
                self.connectedDevices = devices
            }
        }
    }
    
    private func updateIntegrationStatus() async {
        // Update integration status from the engine
        if let engine = deviceIntegrationEngine {
            // This would be updated through the engine's published properties
            // For now, we'll simulate the update
            await MainActor.run {
                self.isIntegrationActive = true
                self.integrationProgress = 0.85
            }
        }
    }
    
    private func updateSensorFusionData(result: SensorFusionResult) async {
        await MainActor.run {
            self.sensorFusion = SensorFusionData(
                timestamp: result.timestamp,
                insights: result.insights,
                analysis: result.analysis
            )
        }
    }
}

// MARK: - Supporting Views

@available(iOS 18.0, macOS 15.0, *)
struct DeviceScanView: View {
    @ObservedObject var viewModel: AdvancedHealthDeviceIntegrationViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Device Scan")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding()
                
                Spacer()
                
                Text("Scanning for available devices...")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button("Done") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .padding()
            }
            .navigationBarHidden(true)
        }
    }
}

@available(iOS 18.0, macOS 15.0, *)
struct IoTDeviceView: View {
    @ObservedObject var viewModel: AdvancedHealthDeviceIntegrationViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Text("IoT Device Management")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding()
                
                Spacer()
                
                Text("IoT device management interface")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button("Done") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .padding()
            }
            .navigationBarHidden(true)
        }
    }
}

@available(iOS 18.0, macOS 15.0, *)
struct SensorFusionView: View {
    @ObservedObject var viewModel: AdvancedHealthDeviceIntegrationViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Sensor Fusion Analysis")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding()
                
                Spacer()
                
                Text("Sensor fusion analysis interface")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button("Done") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .padding()
            }
            .navigationBarHidden(true)
        }
    }
}

@available(iOS 18.0, macOS 15.0, *)
struct DeviceDetailsView: View {
    let device: HealthDevice
    @ObservedObject var viewModel: AdvancedHealthDeviceIntegrationViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Device Details")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding()
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Name: \(device.name)")
                        .font(.subheadline)
                    
                    Text("Type: \(device.type.rawValue.capitalized)")
                        .font(.subheadline)
                    
                    Text("Manufacturer: \(device.manufacturer)")
                        .font(.subheadline)
                    
                    Text("Model: \(device.model)")
                        .font(.subheadline)
                    
                    Text("Status: \(device.status.rawValue.capitalized)")
                        .font(.subheadline)
                }
                .padding()
                
                Spacer()
                
                Button("Done") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .padding()
            }
            .navigationBarHidden(true)
        }
    }
}

// MARK: - Preview
@available(iOS 18.0, macOS 15.0, *)
#Preview {
    AdvancedHealthDeviceIntegrationDashboardView()
} 
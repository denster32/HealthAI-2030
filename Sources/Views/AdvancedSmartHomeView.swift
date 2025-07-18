import SwiftUI
import HomeKit

/// Advanced Smart Home Integration View
/// Provides interface for smart home device management, environmental monitoring, and health optimization
struct AdvancedSmartHomeView: View {
    
    // MARK: - Properties
    
    @StateObject private var smartHomeManager = AdvancedSmartHomeManager()
    @State private var selectedTab: SmartHomeTab = .overview
    @State private var showingAddRoutine = false
    @State private var showingDeviceSettings = false
    @State private var selectedDevice: HMDevice?
    @State private var showingEnvironmentalAlert = false
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Tab Selection
                tabSelectionView
                
                // Content
                TabView(selection: $selectedTab) {
                    overviewView
                        .tag(SmartHomeTab.overview)
                    
                    devicesView
                        .tag(SmartHomeTab.devices)
                    
                    environmentalView
                        .tag(SmartHomeTab.environmental)
                    
                    routinesView
                        .tag(SmartHomeTab.routines)
                    
                    lightingView
                        .tag(SmartHomeTab.lighting)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingAddRoutine) {
                AddHealthRoutineView(smartHomeManager: smartHomeManager)
            }
            .sheet(isPresented: $showingDeviceSettings) {
                if let device = selectedDevice {
                    DeviceSettingsView(device: device, smartHomeManager: smartHomeManager)
                }
            }
            .alert("Environmental Alert", isPresented: $showingEnvironmentalAlert) {
                Button("OK") { }
            } message: {
                Text("Environmental conditions may affect your health. Check the Environmental tab for details.")
            }
            .onAppear {
                Task {
                    await smartHomeManager.optimizeCircadianLighting()
                }
            }
        }
    }
    
    // MARK: - Header View
    
    private var headerView: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Smart Home")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("\(smartHomeManager.homeKitDevices.count) devices • \(smartHomeManager.connectionStatus.rawValue)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                HStack(spacing: 16) {
                    Button(action: { showingAddRoutine = true }) {
                        Image(systemName: "plus.circle")
                            .font(.title3)
                            .foregroundColor(.blue)
                    }
                    
                    Button(action: { showingDeviceSettings = true }) {
                        Image(systemName: "gearshape")
                            .font(.title3)
                            .foregroundColor(.blue)
                    }
                }
            }
            
            // Connection Status
            HStack {
                Circle()
                    .fill(connectionStatusColor)
                    .frame(width: 8, height: 8)
                
                Text(smartHomeManager.connectionStatus.rawValue)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if smartHomeManager.automationStatus.isExecuting {
                    HStack(spacing: 4) {
                        ProgressView()
                            .scaleEffect(0.8)
                        
                        Text("Executing: \(smartHomeManager.automationStatus.currentRoutine ?? "")")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .padding()
        .background(Color(.systemBackground))
    }
    
    // MARK: - Tab Selection View
    
    private var tabSelectionView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 20) {
                ForEach(SmartHomeTab.allCases, id: \.self) { tab in
                    Button(action: { selectedTab = tab }) {
                        VStack(spacing: 4) {
                            Image(systemName: tab.icon)
                                .font(.title3)
                                .foregroundColor(selectedTab == tab ? .blue : .secondary)
                            
                            Text(tab.title)
                                .font(.caption)
                                .fontWeight(selectedTab == tab ? .semibold : .regular)
                                .foregroundColor(selectedTab == tab ? .blue : .secondary)
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
    }
    
    // MARK: - Overview View
    
    private var overviewView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Environmental Overview
                environmentalOverview
                
                // Active Routines
                activeRoutinesSection
                
                // Device Status
                deviceStatusSection
                
                // Air Quality
                airQualitySection
                
                // Quick Actions
                quickActionsSection
            }
            .padding()
        }
    }
    
    private var environmentalOverview: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Environmental Overview")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                EnvironmentalMetricCard(
                    title: "Temperature",
                    value: String(format: "%.1f", smartHomeManager.environmentalData.temperature),
                    unit: "°C",
                    icon: "thermometer",
                    color: .red,
                    status: getTemperatureStatus()
                )
                
                EnvironmentalMetricCard(
                    title: "Humidity",
                    value: String(format: "%.0f", smartHomeManager.environmentalData.humidity),
                    unit: "%",
                    icon: "humidity",
                    color: .blue,
                    status: getHumidityStatus()
                )
                
                EnvironmentalMetricCard(
                    title: "Light Level",
                    value: String(format: "%.0f", smartHomeManager.environmentalData.lightLevel),
                    unit: "lux",
                    icon: "lightbulb",
                    color: .yellow,
                    status: getLightStatus()
                )
                
                EnvironmentalMetricCard(
                    title: "Noise Level",
                    value: String(format: "%.0f", smartHomeManager.environmentalData.noiseLevel),
                    unit: "dB",
                    icon: "speaker.wave.3",
                    color: .green,
                    status: getNoiseStatus()
                )
            }
        }
    }
    
    private var activeRoutinesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Active Routines")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("View All") {
                    selectedTab = .routines
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            
            if smartHomeManager.healthRoutines.filter({ $0.isActive }).isEmpty {
                Text("No active routines")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                ForEach(smartHomeManager.healthRoutines.filter({ $0.isActive }).prefix(3)) { routine in
                    RoutineCard(routine: routine) {
                        Task {
                            await smartHomeManager.triggerRoutine(routine.id)
                        }
                    }
                }
            }
        }
    }
    
    private var deviceStatusSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Device Status")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("View All") {
                    selectedTab = .devices
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            
            if smartHomeManager.homeKitDevices.isEmpty {
                Text("No devices connected")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                ForEach(smartHomeManager.homeKitDevices.prefix(3)) { device in
                    DeviceCard(device: device) {
                        selectedDevice = device
                        showingDeviceSettings = true
                    }
                }
            }
        }
    }
    
    private var airQualitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Air Quality")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 8) {
                AirQualityMetricRow(
                    title: "PM2.5",
                    value: String(format: "%.1f", smartHomeManager.airQualityData.pm25),
                    unit: "μg/m³",
                    status: getPM25Status()
                )
                
                AirQualityMetricRow(
                    title: "CO2",
                    value: String(format: "%.0f", smartHomeManager.airQualityData.co2),
                    unit: "ppm",
                    status: getCO2Status()
                )
                
                AirQualityMetricRow(
                    title: "VOCs",
                    value: String(format: "%.0f", smartHomeManager.airQualityData.vocs),
                    unit: "ppb",
                    status: getVOCsStatus()
                )
                
                AirQualityMetricRow(
                    title: "AQI",
                    value: String(format: "%.0f", smartHomeManager.airQualityData.airQualityIndex),
                    unit: "",
                    status: getAQIStatus()
                )
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
    
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                QuickActionCard(
                    title: "Sleep Mode",
                    icon: "bed.double.fill",
                    color: .purple
                ) {
                    // Trigger sleep routine
                }
                
                QuickActionCard(
                    title: "Wake Up",
                    icon: "sun.max.fill",
                    color: .orange
                ) {
                    // Trigger wake up routine
                }
                
                QuickActionCard(
                    title: "Workout",
                    icon: "figure.run",
                    color: .green
                ) {
                    // Trigger workout routine
                }
                
                QuickActionCard(
                    title: "Meditation",
                    icon: "brain.head.profile",
                    color: .blue
                ) {
                    // Trigger meditation routine
                }
            }
        }
    }
    
    // MARK: - Devices View
    
    private var devicesView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                if smartHomeManager.homeKitDevices.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "house")
                            .font(.system(size: 48))
                            .foregroundColor(.gray)
                        
                        Text("No Devices Connected")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text("Connect your HomeKit devices to get started")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                } else {
                    ForEach(smartHomeManager.homeKitDevices) { device in
                        DeviceRow(device: device) {
                            selectedDevice = device
                            showingDeviceSettings = true
                        }
                    }
                }
            }
            .padding()
        }
    }
    
    // MARK: - Environmental View
    
    private var environmentalView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Real-time Environmental Data
                realTimeEnvironmentalData
                
                // Environmental Trends
                environmentalTrendsSection
                
                // Air Quality Details
                airQualityDetailsSection
                
                // Environmental Alerts
                environmentalAlertsSection
            }
            .padding()
        }
    }
    
    private var realTimeEnvironmentalData: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Real-time Environmental Data")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                EnvironmentalDataRow(
                    title: "Temperature",
                    value: String(format: "%.1f°C", smartHomeManager.environmentalData.temperature),
                    icon: "thermometer",
                    color: .red,
                    status: getTemperatureStatus()
                )
                
                EnvironmentalDataRow(
                    title: "Humidity",
                    value: String(format: "%.0f%%", smartHomeManager.environmentalData.humidity),
                    icon: "humidity",
                    color: .blue,
                    status: getHumidityStatus()
                )
                
                EnvironmentalDataRow(
                    title: "Light Level",
                    value: String(format: "%.0f lux", smartHomeManager.environmentalData.lightLevel),
                    icon: "lightbulb",
                    color: .yellow,
                    status: getLightStatus()
                )
                
                EnvironmentalDataRow(
                    title: "Noise Level",
                    value: String(format: "%.0f dB", smartHomeManager.environmentalData.noiseLevel),
                    icon: "speaker.wave.3",
                    color: .green,
                    status: getNoiseStatus()
                )
            }
        }
    }
    
    private var environmentalTrendsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Environmental Trends")
                .font(.headline)
                .fontWeight(.semibold)
            
            // Placeholder for trend charts
            Text("Environmental trend charts will be displayed here")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding()
        }
    }
    
    private var airQualityDetailsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Air Quality Details")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                AirQualityDetailRow(
                    title: "PM2.5 (Fine Particles)",
                    value: String(format: "%.1f μg/m³", smartHomeManager.airQualityData.pm25),
                    description: "Fine particulate matter that can affect respiratory health",
                    status: getPM25Status()
                )
                
                AirQualityDetailRow(
                    title: "CO2 (Carbon Dioxide)",
                    value: String(format: "%.0f ppm", smartHomeManager.airQualityData.co2),
                    description: "Carbon dioxide levels indicating ventilation quality",
                    status: getCO2Status()
                )
                
                AirQualityDetailRow(
                    title: "VOCs (Volatile Organic Compounds)",
                    value: String(format: "%.0f ppb", smartHomeManager.airQualityData.vocs),
                    description: "Chemical compounds that may affect indoor air quality",
                    status: getVOCsStatus()
                )
                
                AirQualityDetailRow(
                    title: "Air Quality Index",
                    value: String(format: "%.0f", smartHomeManager.airQualityData.airQualityIndex),
                    description: "Overall air quality assessment",
                    status: getAQIStatus()
                )
            }
        }
    }
    
    private var environmentalAlertsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Environmental Alerts")
                .font(.headline)
                .fontWeight(.semibold)
            
            Text("No active environmental alerts")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding()
        }
    }
    
    // MARK: - Routines View
    
    private var routinesView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                if smartHomeManager.healthRoutines.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 48))
                            .foregroundColor(.gray)
                        
                        Text("No Health Routines")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text("Create automated health routines to optimize your environment")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Button("Create Routine") {
                            showingAddRoutine = true
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                } else {
                    ForEach(smartHomeManager.healthRoutines) { routine in
                        RoutineDetailCard(routine: routine) {
                            Task {
                                await smartHomeManager.triggerRoutine(routine.id)
                            }
                        }
                    }
                }
            }
            .padding()
        }
    }
    
    // MARK: - Lighting View
    
    private var lightingView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Smart Lighting Configuration
                smartLightingConfiguration
                
                // Circadian Lighting
                circadianLightingSection
                
                // Room Lighting
                roomLightingSection
                
                // Lighting Scenes
                lightingScenesSection
            }
            .padding()
        }
    }
    
    private var smartLightingConfiguration: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Smart Lighting Configuration")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                LightingConfigToggle(
                    title: "Circadian Optimization",
                    description: "Automatically adjust lighting based on time of day",
                    isEnabled: smartHomeManager.smartLighting.circadianOptimization
                ) { enabled in
                    var config = smartHomeManager.smartLighting
                    config.circadianOptimization = enabled
                    smartHomeManager.updateSmartLightingConfig(config)
                }
                
                LightingConfigToggle(
                    title: "Blue Light Reduction",
                    description: "Reduce blue light in the evening for better sleep",
                    isEnabled: smartHomeManager.smartLighting.blueLightReduction
                ) { enabled in
                    var config = smartHomeManager.smartLighting
                    config.blueLightReduction = enabled
                    smartHomeManager.updateSmartLightingConfig(config)
                }
                
                LightingConfigToggle(
                    title: "Gradual Dimming",
                    description: "Gradually dim lights before bedtime",
                    isEnabled: smartHomeManager.smartLighting.gradualDimming
                ) { enabled in
                    var config = smartHomeManager.smartLighting
                    config.gradualDimming = enabled
                    smartHomeManager.updateSmartLightingConfig(config)
                }
                
                LightingConfigToggle(
                    title: "Wake-up Simulation",
                    description: "Gradually increase light to simulate sunrise",
                    isEnabled: smartHomeManager.smartLighting.wakeUpSimulation
                ) { enabled in
                    var config = smartHomeManager.smartLighting
                    config.wakeUpSimulation = enabled
                    smartHomeManager.updateSmartLightingConfig(config)
                }
                
                LightingConfigToggle(
                    title: "Color Temperature Optimization",
                    description: "Optimize light color temperature for health",
                    isEnabled: smartHomeManager.smartLighting.colorTemperatureOptimization
                ) { enabled in
                    var config = smartHomeManager.smartLighting
                    config.colorTemperatureOptimization = enabled
                    smartHomeManager.updateSmartLightingConfig(config)
                }
            }
        }
    }
    
    private var circadianLightingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Circadian Lighting")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 8) {
                CircadianLightingRow(
                    time: "6:00 AM - 12:00 PM",
                    description: "Cool, bright light for wakefulness",
                    color: .blue
                )
                
                CircadianLightingRow(
                    time: "12:00 PM - 6:00 PM",
                    description: "Natural, balanced light for productivity",
                    color: .green
                )
                
                CircadianLightingRow(
                    time: "6:00 PM - 9:00 PM",
                    description: "Warm, dim light for relaxation",
                    color: .orange
                )
                
                CircadianLightingRow(
                    time: "9:00 PM - 6:00 AM",
                    description: "Very dim, warm light for sleep",
                    color: .purple
                )
            }
        }
    }
    
    private var roomLightingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Room Lighting")
                .font(.headline)
                .fontWeight(.semibold)
            
            Text("Room-specific lighting controls will be displayed here")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding()
        }
    }
    
    private var lightingScenesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Lighting Scenes")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                LightingSceneCard(
                    title: "Sleep",
                    icon: "bed.double.fill",
                    color: .purple
                ) {
                    // Activate sleep scene
                }
                
                LightingSceneCard(
                    title: "Work",
                    icon: "laptopcomputer",
                    color: .blue
                ) {
                    // Activate work scene
                }
                
                LightingSceneCard(
                    title: "Relax",
                    icon: "leaf.fill",
                    color: .green
                ) {
                    // Activate relax scene
                }
                
                LightingSceneCard(
                    title: "Party",
                    icon: "music.note",
                    color: .pink
                ) {
                    // Activate party scene
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var connectionStatusColor: Color {
        switch smartHomeManager.connectionStatus {
        case .connected:
            return .green
        case .connecting:
            return .yellow
        case .disconnected:
            return .red
        case .error:
            return .red
        }
    }
    
    // MARK: - Status Helper Methods
    
    private func getTemperatureStatus() -> MetricStatus {
        let temp = smartHomeManager.environmentalData.temperature
        if temp < 16.0 || temp > 26.0 {
            return .warning
        } else if temp >= 18.0 && temp <= 24.0 {
            return .good
        } else {
            return .acceptable
        }
    }
    
    private func getHumidityStatus() -> MetricStatus {
        let humidity = smartHomeManager.environmentalData.humidity
        if humidity < 30.0 || humidity > 70.0 {
            return .warning
        } else if humidity >= 40.0 && humidity <= 60.0 {
            return .good
        } else {
            return .acceptable
        }
    }
    
    private func getLightStatus() -> MetricStatus {
        let light = smartHomeManager.environmentalData.lightLevel
        if light > 1000.0 {
            return .warning
        } else if light >= 100.0 && light <= 500.0 {
            return .good
        } else {
            return .acceptable
        }
    }
    
    private func getNoiseStatus() -> MetricStatus {
        let noise = smartHomeManager.environmentalData.noiseLevel
        if noise > 70.0 {
            return .warning
        } else if noise < 50.0 {
            return .good
        } else {
            return .acceptable
        }
    }
    
    private func getPM25Status() -> MetricStatus {
        let pm25 = smartHomeManager.airQualityData.pm25
        if pm25 > 35.0 {
            return .warning
        } else if pm25 < 12.0 {
            return .good
        } else {
            return .acceptable
        }
    }
    
    private func getCO2Status() -> MetricStatus {
        let co2 = smartHomeManager.airQualityData.co2
        if co2 > 1000.0 {
            return .warning
        } else if co2 < 800.0 {
            return .good
        } else {
            return .acceptable
        }
    }
    
    private func getVOCsStatus() -> MetricStatus {
        let vocs = smartHomeManager.airQualityData.vocs
        if vocs > 500.0 {
            return .warning
        } else if vocs < 200.0 {
            return .good
        } else {
            return .acceptable
        }
    }
    
    private func getAQIStatus() -> MetricStatus {
        let aqi = smartHomeManager.airQualityData.airQualityIndex
        if aqi > 100.0 {
            return .warning
        } else if aqi < 50.0 {
            return .good
        } else {
            return .acceptable
        }
    }
}

// MARK: - Supporting Views

struct EnvironmentalMetricCard: View {
    let title: String
    let value: String
    let unit: String
    let icon: String
    let color: Color
    let status: MetricStatus
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Spacer()
                
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text(unit)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var statusColor: Color {
        switch status {
        case .good:
            return .green
        case .acceptable:
            return .yellow
        case .warning:
            return .red
        }
    }
}

struct RoutineCard: View {
    let routine: HealthRoutine
    let onTrigger: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(routine.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(routine.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            Button("Trigger", action: onTrigger)
                .font(.caption)
                .foregroundColor(.blue)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

struct DeviceCard: View {
    let device: HMDevice
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Image(systemName: "lightbulb")
                    .font(.title2)
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(device.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text(device.room)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct AirQualityMetricRow: View {
    let title: String
    let value: String
    let unit: String
    let status: MetricStatus
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("\(value) \(unit)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
        }
    }
    
    private var statusColor: Color {
        switch status {
        case .good:
            return .green
        case .acceptable:
            return .yellow
        case .warning:
            return .red
        }
    }
}

struct QuickActionCard: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct DeviceRow: View {
    let device: HMDevice
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Image(systemName: "lightbulb")
                    .font(.title2)
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(device.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text("\(device.room) • \(device.service.serviceType)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct EnvironmentalDataRow: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let status: MetricStatus
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(value)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
    
    private var statusColor: Color {
        switch status {
        case .good:
            return .green
        case .acceptable:
            return .yellow
        case .warning:
            return .red
        }
    }
}

struct AirQualityDetailRow: View {
    let title: String
    let value: String
    let description: String
    let status: MetricStatus
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text(value)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)
            }
            
            Text(description)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
    
    private var statusColor: Color {
        switch status {
        case .good:
            return .green
        case .acceptable:
            return .yellow
        case .warning:
            return .red
        }
    }
}

struct RoutineDetailCard: View {
    let routine: HealthRoutine
    let onTrigger: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(routine.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text(routine.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Toggle("", isOn: .constant(routine.isActive))
                    .labelsHidden()
            }
            
            Text("Type: \(routine.type.rawValue)")
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack {
                Spacer()
                
                Button("Trigger Now", action: onTrigger)
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct LightingConfigToggle: View {
    let title: String
    let description: String
    let isEnabled: Bool
    let onToggle: (Bool) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Toggle("", isOn: Binding(
                    get: { isEnabled },
                    set: { onToggle($0) }
                ))
                .labelsHidden()
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

struct CircadianLightingRow: View {
    let time: String
    let description: String
    let color: Color
    
    var body: some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(time)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

struct LightingSceneCard: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Supporting Types

enum SmartHomeTab: CaseIterable {
    case overview, devices, environmental, routines, lighting
    
    var title: String {
        switch self {
        case .overview:
            return "Overview"
        case .devices:
            return "Devices"
        case .environmental:
            return "Environmental"
        case .routines:
            return "Routines"
        case .lighting:
            return "Lighting"
        }
    }
    
    var icon: String {
        switch self {
        case .overview:
            return "house.fill"
        case .devices:
            return "lightbulb.fill"
        case .environmental:
            return "thermometer"
        case .routines:
            return "clock.arrow.circlepath"
        case .lighting:
            return "light.max"
        }
    }
}

enum MetricStatus {
    case good, acceptable, warning
}

// MARK: - Preview

struct AdvancedSmartHomeView_Previews: PreviewProvider {
    static var previews: some View {
        AdvancedSmartHomeView()
    }
} 
import SwiftUI
import HomeKit

struct EnvironmentControlView: View {
    @StateObject private var smartHomeManager = SmartHomeManager.shared
    @StateObject private var healthDataManager = HealthDataManager.shared
    @State private var selectedRoom = "All Rooms"
    @State private var showingAutomationSettings = false
    @State private var showingDeviceDetails = false
    @State private var selectedDevice: SmartHomeDevice?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 16) {
                    // Connection Status Card
                    ConnectionStatusCard()
                    
                    // Room Selector
                    RoomSelectorCard(selectedRoom: $selectedRoom)
                    
                    // Environment Overview
                    EnvironmentOverviewCard(selectedRoom: selectedRoom)
                    
                    // Quick Controls
                    QuickControlsCard()
                    
                    // Device Controls
                    DeviceControlsSection(
                        selectedRoom: selectedRoom,
                        selectedDevice: $selectedDevice,
                        showingDeviceDetails: $showingDeviceDetails
                    )
                    
                    // Automation Rules
                    AutomationRulesCard(showingSettings: $showingAutomationSettings)
                    
                    // Environment Insights
                    EnvironmentInsightsCard()
                }
                .padding(.horizontal)
            }
            .navigationTitle("Environment Control")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Settings") {
                        showingAutomationSettings = true
                    }
                }
            }
            .sheet(isPresented: $showingAutomationSettings) {
                AutomationSettingsView()
            }
            .sheet(isPresented: $showingDeviceDetails) {
                if let device = selectedDevice {
                    DeviceDetailView(device: device)
                }
            }
            .onAppear {
                smartHomeManager.discoverDevices()
            }
        }
    }
}

// MARK: - Connection Status Card

struct ConnectionStatusCard: View {
    @ObservedObject private var smartHomeManager = SmartHomeManager.shared
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Smart Home Status")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text(smartHomeManager.connectionStatus.displayName)
                        .font(.subheadline)
                        .foregroundColor(Color(smartHomeManager.connectionStatus.color))
                }
                
                Spacer()
                
                StatusIndicatorView(status: smartHomeManager.connectionStatus)
            }
            
            HStack {
                MetricView(
                    title: "Connected Devices",
                    value: "\(smartHomeManager.connectedDevices.count)",
                    icon: "house.fill"
                )
                
                Spacer()
                
                MetricView(
                    title: "Active Rooms",
                    value: "\(smartHomeManager.roomEnvironments.count)",
                    icon: "door.left.hand.open"
                )
                
                Spacer()
                
                MetricView(
                    title: "Automation Rules",
                    value: "\(smartHomeManager.automationRules.filter { $0.isEnabled }.count)",
                    icon: "gear.badge.checkmark"
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
}

struct StatusIndicatorView: View {
    let status: SmartHomeConnectionStatus
    
    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(Color(status.color))
                .frame(width: 12, height: 12)
            
            if status == .discovering {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: Color(status.color)))
                    .scaleEffect(0.8)
            }
        }
    }
}

struct MetricView: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.accentColor)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
}

// MARK: - Room Selector Card

struct RoomSelectorCard: View {
    @Binding var selectedRoom: String
    @ObservedObject private var smartHomeManager = SmartHomeManager.shared
    
    private var availableRooms: [String] {
        let rooms = Array(smartHomeManager.roomEnvironments.keys).sorted()
        return ["All Rooms"] + rooms
    }
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Room Selection")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(availableRooms, id: \.self) { room in
                        RoomChip(
                            room: room,
                            isSelected: selectedRoom == room,
                            environment: smartHomeManager.roomEnvironments[room]
                        ) {
                            selectedRoom = room
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
}

struct RoomChip: View {
    let room: String
    let isSelected: Bool
    let environment: RoomEnvironment?
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                HStack(spacing: 4) {
                    Text(room)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .lineLimit(1)
                    
                    if let environment = environment {
                        Circle()
                            .fill(Color(environment.overallStatus.color))
                            .frame(width: 8, height: 8)
                    }
                }
                
                if let environment = environment {
                    Text("\(Int(environment.optimizationScore * 100))%")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isSelected ? Color.accentColor : Color(.systemGray5))
            )
            .foregroundColor(isSelected ? .white : .primary)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Environment Overview Card

struct EnvironmentOverviewCard: View {
    let selectedRoom: String
    @ObservedObject private var smartHomeManager = SmartHomeManager.shared
    
    private var environmentData: RoomEnvironment? {
        if selectedRoom == "All Rooms" {
            return calculateAverageEnvironment()
        } else {
            return smartHomeManager.roomEnvironments[selectedRoom]
        }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("\(selectedRoom) Environment")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                if let environment = environmentData {
                    HStack(spacing: 4) {
                        Image(systemName: environment.overallStatus.icon)
                            .font(.caption)
                        
                        Text(environment.overallStatus.displayName)
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(Color(environment.overallStatus.color))
                }
            }
            
            if let environment = environmentData {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                    EnvironmentMetricCard(
                        title: "Temperature",
                        value: "\(String(format: "%.1f", environment.temperature))°C",
                        status: environment.temperatureStatus,
                        icon: "thermometer",
                        optimal: "18-22°C"
                    )
                    
                    EnvironmentMetricCard(
                        title: "Humidity",
                        value: "\(Int(environment.humidity))%",
                        status: environment.humidityStatus,
                        icon: "humidity.fill",
                        optimal: "40-60%"
                    )
                    
                    EnvironmentMetricCard(
                        title: "Light Level",
                        value: "\(Int(environment.lightLevel * 100))%",
                        status: environment.lightStatus,
                        icon: "lightbulb.fill",
                        optimal: "Auto"
                    )
                    
                    EnvironmentMetricCard(
                        title: "Noise Level",
                        value: "\(Int(environment.noiseLevel)) dB",
                        status: environment.noiseStatus,
                        icon: "speaker.wave.2.fill",
                        optimal: "<40 dB"
                    )
                }
                
                // Overall Optimization Score
                VStack(spacing: 8) {
                    HStack {
                        Text("Optimization Score")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Spacer()
                        
                        Text("\(Int(environment.optimizationScore * 100))%")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(Color(environment.overallStatus.color))
                    }
                    
                    ProgressView(value: environment.optimizationScore)
                        .progressViewStyle(LinearProgressViewStyle(tint: Color(environment.overallStatus.color)))
                }
            } else {
                Text("No environment data available")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 100)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
    
    private func calculateAverageEnvironment() -> RoomEnvironment? {
        let environments = Array(smartHomeManager.roomEnvironments.values)
        guard !environments.isEmpty else { return nil }
        
        let avgTemp = environments.reduce(0) { $0 + $1.temperature } / Double(environments.count)
        let avgHumidity = environments.reduce(0) { $0 + $1.humidity } / Double(environments.count)
        let avgLight = environments.reduce(0) { $0 + $1.lightLevel } / Double(environments.count)
        let avgNoise = environments.reduce(0) { $0 + $1.noiseLevel } / Double(environments.count)
        let avgScore = environments.reduce(0) { $0 + $1.optimizationScore } / Double(environments.count)
        
        // Use most common air quality
        let airQualities = environments.map { $0.airQuality }
        let mostCommonAirQuality = airQualities.max(by: { airQuality1, airQuality2 in
            airQualities.filter { $0 == airQuality1 }.count < airQualities.filter { $0 == airQuality2 }.count
        }) ?? .good
        
        return RoomEnvironment(
            temperature: avgTemp,
            humidity: avgHumidity,
            lightLevel: avgLight,
            noiseLevel: avgNoise,
            airQuality: mostCommonAirQuality,
            optimizationScore: avgScore,
            lastUpdated: Date()
        )
    }
}

struct EnvironmentMetricCard: View {
    let title: String
    let value: String
    let status: EnvironmentStatus
    let icon: String
    let optimal: String
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(Color(status.color))
                
                Spacer()
                
                Image(systemName: status.icon)
                    .font(.caption)
                    .foregroundColor(Color(status.color))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.title3)
                    .fontWeight(.semibold)
                
                Text("Optimal: \(optimal)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(Color(.systemGray5))
        .cornerRadius(12)
    }
}

// MARK: - Quick Controls Card

struct QuickControlsCard: View {
    @ObservedObject private var smartHomeManager = SmartHomeManager.shared
    @ObservedObject private var healthDataManager = HealthDataManager.shared
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Quick Controls")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                QuickControlButton(
                    title: "Optimize for Sleep",
                    icon: "moon.fill",
                    color: .indigo,
                    action: optimizeForSleep
                )
                
                QuickControlButton(
                    title: "Stress Relief",
                    icon: "heart.fill",
                    color: .blue,
                    action: optimizeForStressRelief
                )
                
                QuickControlButton(
                    title: "Focus Mode",
                    icon: "brain.head.profile",
                    color: .orange,
                    action: optimizeForFocus
                )
                
                QuickControlButton(
                    title: "Energy Boost",
                    icon: "bolt.fill",
                    color: .yellow,
                    action: optimizeForEnergy
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
    
    private func optimizeForSleep() {
        let sleepStage = healthDataManager.currentSleepStage ?? .light
        smartHomeManager.optimizeEnvironmentForSleep(stage: sleepStage)
    }
    
    private func optimizeForStressRelief() {
        smartHomeManager.adjustEnvironmentForStress(level: 0.8)
    }
    
    private func optimizeForFocus() {
        Task {
            // Bright, cool lighting for focus
            await smartHomeManager.adjustLighting(LightingSettings(
                brightness: 0.8,
                colorTemperature: 5500,
                color: .cool
            ))
            
            // Comfortable temperature
            await smartHomeManager.adjustTemperature(TemperatureSettings(
                target: 21.5,
                mode: .comfort
            ))
        }
    }
    
    private func optimizeForEnergy() {
        Task {
            // Bright, energizing lighting
            await smartHomeManager.adjustLighting(LightingSettings(
                brightness: 1.0,
                colorTemperature: 6500,
                color: .white
            ))
            
            // Slightly cooler temperature for alertness
            await smartHomeManager.adjustTemperature(TemperatureSettings(
                target: 20.0,
                mode: .comfort
            ))
        }
    }
}

struct QuickControlButton: View {
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
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 80)
            .background(Color(.systemGray5))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Device Controls Section

struct DeviceControlsSection: View {
    let selectedRoom: String
    @Binding var selectedDevice: SmartHomeDevice?
    @Binding var showingDeviceDetails: Bool
    @ObservedObject private var smartHomeManager = SmartHomeManager.shared
    
    private var filteredDevices: [SmartHomeDevice] {
        if selectedRoom == "All Rooms" {
            return smartHomeManager.connectedDevices
        } else {
            return smartHomeManager.connectedDevices.filter { $0.room == selectedRoom }
        }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Connected Devices")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("\(filteredDevices.count)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            if filteredDevices.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "house")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    
                    Text("No devices found")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Button("Discover Devices") {
                        smartHomeManager.discoverDevices()
                    }
                    .buttonStyle(.bordered)
                }
                .frame(maxWidth: .infinity, minHeight: 120)
            } else {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                    ForEach(filteredDevices) { device in
                        DeviceControlCard(device: device) {
                            selectedDevice = device
                            showingDeviceDetails = true
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
}

struct DeviceControlCard: View {
    let device: SmartHomeDevice
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: device.statusIcon)
                        .font(.title3)
                        .foregroundColor(.accentColor)
                    
                    Spacer()
                    
                    Circle()
                        .fill(Color(device.statusColor))
                        .frame(width: 8, height: 8)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(device.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    Text(device.type.displayName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(device.platform.displayName)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding()
            .background(Color(.systemGray5))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Automation Rules Card

struct AutomationRulesCard: View {
    @Binding var showingSettings: Bool
    @ObservedObject private var smartHomeManager = SmartHomeManager.shared
    
    private var activeRules: [EnvironmentAutomationRule] {
        smartHomeManager.automationRules.filter { $0.isEnabled }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Automation Rules")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("Manage") {
                    showingSettings = true
                }
                .font(.subheadline)
                .foregroundColor(.accentColor)
            }
            
            if activeRules.isEmpty {
                HStack {
                    Image(systemName: "gear.badge.xmark")
                        .font(.title3)
                        .foregroundColor(.secondary)
                    
                    Text("No active automation rules")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
                .frame(minHeight: 60)
            } else {
                VStack(spacing: 8) {
                    ForEach(activeRules.prefix(3)) { rule in
                        AutomationRuleRow(rule: rule)
                    }
                    
                    if activeRules.count > 3 {
                        HStack {
                            Text("+ \(activeRules.count - 3) more rules")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
}

struct AutomationRuleRow: View {
    let rule: EnvironmentAutomationRule
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "gear.badge.checkmark")
                .font(.subheadline)
                .foregroundColor(.green)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(rule.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                Text(rule.trigger.displayName)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            if let lastExecuted = rule.lastExecuted {
                Text(lastExecuted, style: .relative)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Environment Insights Card

struct EnvironmentInsightsCard: View {
    @ObservedObject private var smartHomeManager = SmartHomeManager.shared
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Environment Insights")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                if let lastUpdate = smartHomeManager.lastEnvironmentUpdate {
                    Text("Updated \(lastUpdate, style: .relative)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            VStack(spacing: 12) {
                InsightRow(
                    icon: "moon.fill",
                    title: "Sleep Environment",
                    description: "Bedroom temperature optimal for deep sleep",
                    sentiment: .positive
                )
                
                InsightRow(
                    icon: "exclamationmark.triangle.fill",
                    title: "Air Quality Alert",
                    description: "Living room air quality could be improved",
                    sentiment: .warning
                )
                
                InsightRow(
                    icon: "lightbulb.fill",
                    title: "Energy Optimization",
                    description: "Smart lighting saved 15% energy this week",
                    sentiment: .positive
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
}

struct InsightRow: View {
    let icon: String
    let title: String
    let description: String
    let sentiment: InsightSentiment
    
    enum InsightSentiment {
        case positive
        case warning
        case negative
        
        var color: Color {
            switch self {
            case .positive: return .green
            case .warning: return .orange
            case .negative: return .red
            }
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundColor(sentiment.color)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    EnvironmentControlView()
}
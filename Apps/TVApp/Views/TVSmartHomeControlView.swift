import SwiftUI
import HomeKit

@available(tvOS 18.0, *)
struct TVSmartHomeControlView: View {
    @StateObject private var homeManager = HomeManager()
    @State private var selectedTab: SmartHomeTab = .devices
    @State private var showingAddDevice = false
    @State private var selectedRoom: HMRoom?
    
    enum SmartHomeTab: String, CaseIterable {
        case devices = "Devices"
        case automations = "Automations"
        case rooms = "Rooms"
        case healthRules = "Health Rules"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "house.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Smart Home Control")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("Control your connected devices and automations")
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // Tab Picker
                    Picker("View", selection: $selectedTab) {
                        ForEach(SmartHomeTab.allCases, id: \.self) { tab in
                            Text(tab.rawValue).tag(tab)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .frame(width: 600)
                }
            }
            .padding(40)
            .background(Color(.systemBackground))
            
            // Content
            TabView(selection: $selectedTab) {
                DevicesView(homeManager: homeManager, selectedRoom: $selectedRoom)
                    .tag(SmartHomeTab.devices)
                
                AutomationsView(homeManager: homeManager)
                    .tag(SmartHomeTab.automations)
                
                RoomsView(homeManager: homeManager, selectedRoom: $selectedRoom)
                    .tag(SmartHomeTab.rooms)
                
                HealthRulesView(homeManager: homeManager)
                    .tag(SmartHomeTab.healthRules)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        }
        .background(Color(.systemBackground))
        .onAppear {
            homeManager.requestAccess()
        }
        .sheet(isPresented: $showingAddDevice) {
            AddDeviceView(homeManager: homeManager)
        }
    }
}

// MARK: - Devices View
@available(tvOS 18.0, *)
struct DevicesView: View {
    @ObservedObject var homeManager: HomeManager
    @Binding var selectedRoom: HMRoom?
    
    var filteredDevices: [HMDevice] {
        if let room = selectedRoom {
            return homeManager.devices.filter { device in
                device.room == room
            }
        }
        return homeManager.devices
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                // Room Filter
                if !homeManager.rooms.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Filter by Room")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                RoomFilterButton(
                                    title: "All Rooms",
                                    isSelected: selectedRoom == nil
                                ) {
                                    selectedRoom = nil
                                }
                                
                                ForEach(homeManager.rooms, id: \.uniqueIdentifier) { room in
                                    RoomFilterButton(
                                        title: room.name,
                                        isSelected: selectedRoom?.uniqueIdentifier == room.uniqueIdentifier
                                    ) {
                                        selectedRoom = room
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                }
                
                // Devices Grid
                if filteredDevices.isEmpty {
                    EmptyStateView(
                        icon: "lightbulb",
                        title: "No Devices Found",
                        message: selectedRoom == nil ? 
                            "Add some smart devices to get started" : 
                            "No devices in this room"
                    )
                } else {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 30), count: 3), spacing: 30) {
                        ForEach(filteredDevices, id: \.uniqueIdentifier) { device in
                            DeviceControlCard(device: device, homeManager: homeManager)
                        }
                    }
                }
            }
            .padding(.horizontal, 60)
            .padding(.vertical, 40)
        }
    }
}

// MARK: - Automations View
@available(tvOS 18.0, *)
struct AutomationsView: View {
    @ObservedObject var homeManager: HomeManager
    
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                // Header
                VStack(alignment: .leading, spacing: 16) {
                    Text("Automations")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Automated actions based on time, location, or device states")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Automations List
                if homeManager.automations.isEmpty {
                    EmptyStateView(
                        icon: "clock.arrow.circlepath",
                        title: "No Automations",
                        message: "Create automations to make your home smarter"
                    )
                } else {
                    VStack(spacing: 20) {
                        ForEach(homeManager.automations, id: \.uniqueIdentifier) { automation in
                            AutomationCard(automation: automation, homeManager: homeManager)
                        }
                    }
                }
            }
            .padding(.horizontal, 60)
            .padding(.vertical, 40)
        }
    }
}

// MARK: - Rooms View
@available(tvOS 18.0, *)
struct RoomsView: View {
    @ObservedObject var homeManager: HomeManager
    @Binding var selectedRoom: HMRoom?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                // Header
                VStack(alignment: .leading, spacing: 16) {
                    Text("Rooms")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Organize your devices by room")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Rooms Grid
                if homeManager.rooms.isEmpty {
                    EmptyStateView(
                        icon: "house",
                        title: "No Rooms",
                        message: "Add rooms to organize your smart home devices"
                    )
                } else {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 30), count: 3), spacing: 30) {
                        ForEach(homeManager.rooms, id: \.uniqueIdentifier) { room in
                            RoomCard(
                                room: room,
                                deviceCount: homeManager.devices.filter { $0.room == room }.count,
                                isSelected: selectedRoom?.uniqueIdentifier == room.uniqueIdentifier
                            ) {
                                selectedRoom = selectedRoom?.uniqueIdentifier == room.uniqueIdentifier ? nil : room
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 60)
            .padding(.vertical, 40)
        }
    }
}

// MARK: - Health Rules View
@available(tvOS 18.0, *)
struct HealthRulesView: View {
    @ObservedObject var homeManager: HomeManager
    
    let healthRules = [
        HealthRule(
            id: UUID(),
            name: "Sleep Mode",
            description: "Dim lights and reduce noise when sleep tracking begins",
            icon: "bed.double.fill",
            color: .blue,
            isActive: true
        ),
        HealthRule(
            id: UUID(),
            name: "Workout Mode",
            description: "Increase lighting and play energizing music during workouts",
            icon: "figure.run",
            color: .green,
            isActive: false
        ),
        HealthRule(
            id: UUID(),
            name: "Stress Relief",
            description: "Activate calming lights and sounds when stress is detected",
            icon: "brain.head.profile",
            color: .purple,
            isActive: true
        ),
        HealthRule(
            id: UUID(),
            name: "Meditation Time",
            description: "Create a peaceful environment for meditation sessions",
            icon: "leaf.fill",
            color: .orange,
            isActive: false
        )
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                // Header
                VStack(alignment: .leading, spacing: 16) {
                    Text("Health-Based Rules")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Automate your home based on health and wellness activities")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Health Rules Grid
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 30), count: 2), spacing: 30) {
                    ForEach(healthRules, id: \.id) { rule in
                        HealthRuleCard(rule: rule)
                    }
                }
                
                // Add New Rule Button
                Button("Create New Health Rule") {
                    // Show rule creation interface
                }
                .buttonStyle(TVButtonStyle())
            }
            .padding(.horizontal, 60)
            .padding(.vertical, 40)
        }
    }
}

// MARK: - Supporting Views

@available(tvOS 18.0, *)
struct DeviceControlCard: View {
    let device: HMDevice
    @ObservedObject var homeManager: HomeManager
    @State private var showingDetail = false
    
    var body: some View {
        Button(action: {
            if device.hasDetailedControls {
                showingDetail = true
            } else {
                toggleDevice()
            }
        }) {
            VStack(spacing: 16) {
                Image(systemName: getDeviceIcon(device))
                    .font(.system(size: 40))
                    .foregroundColor(getDeviceColor(device))
                
                VStack(spacing: 8) {
                    Text(device.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.center)
                    
                    Text(getDeviceStatus(device))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                // Quick Toggle
                if device.hasOnOffSwitch {
                    HStack {
                        Text("OFF")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Toggle("", isOn: Binding(
                            get: { device.isOn },
                            set: { _ in toggleDevice() }
                        ))
                        .toggleStyle(SwitchToggleStyle(tint: .blue))
                        
                        Text("ON")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .frame(width: 250, height: 200)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(16)
        }
        .buttonStyle(CardButtonStyle())
        .sheet(isPresented: $showingDetail) {
            DeviceDetailView(device: device, homeManager: homeManager)
        }
    }
    
    private func getDeviceIcon(_ device: HMDevice) -> String {
        // This would be based on device type
        return "lightbulb.fill"
    }
    
    private func getDeviceColor(_ device: HMDevice) -> Color {
        return device.isOn ? .yellow : .gray
    }
    
    private func getDeviceStatus(_ device: HMDevice) -> String {
        return device.isOn ? "On" : "Off"
    }
    
    private func toggleDevice() {
        homeManager.toggleDevice(device)
    }
}

@available(tvOS 18.0, *)
struct AutomationCard: View {
    let automation: HMAutomation
    @ObservedObject var homeManager: HomeManager
    
    var body: some View {
        HStack(spacing: 20) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 32))
                .foregroundColor(.blue)
                .frame(width: 60, height: 60)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(12)
            
            VStack(alignment: .leading, spacing: 8) {
                Text(automation.name)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text("Automated action")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Toggle("", isOn: Binding(
                get: { automation.isEnabled },
                set: { _ in homeManager.toggleAutomation(automation) }
            ))
            .toggleStyle(SwitchToggleStyle(tint: .blue))
        }
        .padding(20)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

@available(tvOS 18.0, *)
struct RoomCard: View {
    let room: HMRoom
    let deviceCount: Int
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 16) {
                Image(systemName: "house.fill")
                    .font(.system(size: 40))
                    .foregroundColor(isSelected ? .white : .blue)
                
                VStack(spacing: 8) {
                    Text(room.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(isSelected ? .white : .primary)
                    
                    Text("\(deviceCount) devices")
                        .font(.subheadline)
                        .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                }
            }
            .frame(width: 200, height: 150)
            .background(isSelected ? Color.blue : Color(.secondarySystemBackground))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(CardButtonStyle())
    }
}

@available(tvOS 18.0, *)
struct HealthRuleCard: View {
    let rule: HealthRule
    @State private var isActive: Bool
    
    init(rule: HealthRule) {
        self.rule = rule
        self._isActive = State(initialValue: rule.isActive)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: rule.icon)
                    .font(.system(size: 32))
                    .foregroundColor(rule.color)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(rule.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text(rule.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Toggle("", isOn: $isActive)
                    .toggleStyle(SwitchToggleStyle(tint: rule.color))
            }
            
            // Rule Actions Preview
            VStack(alignment: .leading, spacing: 8) {
                Text("Actions:")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                ForEach(getRuleActions(rule), id: \.self) { action in
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(.green)
                        
                        Text(action)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding(20)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }
    
    private func getRuleActions(_ rule: HealthRule) -> [String] {
        switch rule.name {
        case "Sleep Mode":
            return ["Dim bedroom lights", "Enable Do Not Disturb", "Set thermostat to 68°F"]
        case "Workout Mode":
            return ["Increase lighting", "Play energizing music", "Set thermostat to 72°F"]
        case "Stress Relief":
            return ["Activate calming lights", "Play nature sounds", "Adjust air purifier"]
        case "Meditation Time":
            return ["Create peaceful lighting", "Play meditation music", "Enable quiet mode"]
        default:
            return ["Custom action"]
        }
    }
}

@available(tvOS 18.0, *)
struct RoomFilterButton: View {
    let title: String
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue : Color(.secondarySystemBackground))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(8)
        }
        .buttonStyle(CardButtonStyle())
    }
}

@available(tvOS 18.0, *)
struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

@available(tvOS 18.0, *)
struct DeviceDetailView: View {
    let device: HMDevice
    @ObservedObject var homeManager: HomeManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // Device Info
                VStack(spacing: 16) {
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.yellow)
                    
                    Text(device.name)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Smart Light Bulb")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                
                // Controls
                VStack(spacing: 20) {
                    // Brightness Slider
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Brightness")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Slider(value: .constant(0.8), in: 0...1)
                            .accentColor(.yellow)
                    }
                    
                    // Color Temperature
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Color Temperature")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Slider(value: .constant(0.5), in: 0...1)
                            .accentColor(.orange)
                    }
                }
                .padding(24)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(16)
                
                Spacer()
            }
            .padding(40)
            .navigationTitle("Device Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

@available(tvOS 18.0, *)
struct AddDeviceView: View {
    @ObservedObject var homeManager: HomeManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Text("Add New Device")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Scan for new HomeKit devices")
                    .font(.title2)
                    .foregroundColor(.secondary)
                
                Button("Start Scanning") {
                    // Start device discovery
                }
                .buttonStyle(TVButtonStyle())
                
                Spacer()
            }
            .padding(40)
            .navigationTitle("Add Device")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Home Manager
@available(tvOS 18.0, *)
class HomeManager: NSObject, ObservableObject {
    @Published var homes: [HMHome] = []
    @Published var devices: [HMDevice] = []
    @Published var automations: [HMAutomation] = []
    @Published var rooms: [HMRoom] = []
    
    private let homeManager = HMHomeManager()
    
    override init() {
        super.init()
        homeManager.delegate = self
    }
    
    deinit {
        // Clear delegate to prevent retain cycle
        homeManager.delegate = nil
    }
    
    func requestAccess() {
        // HomeKit access is handled automatically
    }
    
    func toggleDevice(_ device: HMDevice) {
        // Toggle device state
        print("Toggling device: \(device.name)")
    }
    
    func toggleAutomation(_ automation: HMAutomation) {
        // Toggle automation state
        print("Toggling automation: \(automation.name)")
    }
}

@available(tvOS 18.0, *)
extension HomeManager: HMHomeManagerDelegate {
    func homeManagerDidUpdateHomes(_ manager: HMHomeManager) {
        homes = manager.homes
        updateDevicesAndRooms()
    }
    
    private func updateDevicesAndRooms() {
        devices = homes.flatMap { home in
            home.accessories.flatMap { accessory in
                accessory.services.flatMap { service in
                    service.characteristics.compactMap { characteristic in
                        // Convert to HMDevice-like structure
                        return HMDevice()
                    }
                }
            }
        }
        
        rooms = homes.flatMap { $0.rooms }
        automations = homes.flatMap { $0.automations }
    }
}

// MARK: - Data Models
struct HealthRule: Identifiable {
    let id: UUID
    let name: String
    let description: String
    let icon: String
    let color: Color
    let isActive: Bool
}

// Mock HMDevice for preview
class HMDevice: ObservableObject {
    let uniqueIdentifier = UUID()
    let name: String
    let room: HMRoom?
    let hasOnOffSwitch: Bool
    let hasDetailedControls: Bool
    @Published var isOn: Bool
    
    init(name: String = "Smart Light", room: HMRoom? = nil, hasOnOffSwitch: Bool = true, hasDetailedControls: Bool = true, isOn: Bool = false) {
        self.name = name
        self.room = room
        self.hasOnOffSwitch = hasOnOffSwitch
        self.hasDetailedControls = hasDetailedControls
        self.isOn = isOn
    }
}

// Mock HMRoom for preview
class HMRoom: ObservableObject {
    let uniqueIdentifier = UUID()
    let name: String
    
    init(name: String = "Living Room") {
        self.name = name
    }
}

// Mock HMAutomation for preview
class HMAutomation: ObservableObject {
    let uniqueIdentifier = UUID()
    let name: String
    @Published var isEnabled: Bool
    
    init(name: String = "Morning Routine", isEnabled: Bool = true) {
        self.name = name
        self.isEnabled = isEnabled
    }
}

// MARK: - Button Style
@available(tvOS 18.0, *)
struct TVButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(12)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Preview
#Preview {
    TVSmartHomeControlView()
} 
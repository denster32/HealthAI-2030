import SwiftUI
import HomeKit

/// Main Smart Home View
public struct SmartHomeView: View {
    @StateObject private var smartHomeManager = SmartHomeManager.shared
    @State private var selectedTab = 0
    @State private var showingAddRule = false
    @State private var showingDeviceDetails = false
    @State private var selectedDevice: HMAccessory?
    
    public init() {}
    
    public var body: some View {
        NavigationView {
            VStack {
                if !smartHomeManager.isHomeKitAvailable {
                    homeKitNotAvailableView
                } else if !smartHomeManager.isAuthorized {
                    authorizationRequiredView
                } else {
                    mainContentView
                }
            }
            .navigationTitle("Smart Home")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddRule = true
                    }) {
                        Image(systemName: "plus")
                    }
                    .disabled(!smartHomeManager.isAuthorized)
                }
            }
            .sheet(isPresented: $showingAddRule) {
                AddHealthRuleView()
            }
            .sheet(isPresented: $showingDeviceDetails) {
                if let device = selectedDevice {
                    DeviceDetailView(device: device)
                }
            }
        }
    }
    
    private var homeKitNotAvailableView: some View {
        VStack(spacing: 20) {
            Image(systemName: "house.slash")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("HomeKit Not Available")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Your device doesn't support HomeKit or HomeKit is not available on this platform.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
        }
        .padding()
    }
    
    private var authorizationRequiredView: some View {
        VStack(spacing: 20) {
            Image(systemName: "lock.shield")
                .font(.system(size: 60))
                .foregroundColor(.orange)
            
            Text("HomeKit Access Required")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Please grant HomeKit access in Settings to use smart home features.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            Button("Open Settings") {
                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsUrl)
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
    
    private var mainContentView: some View {
        TabView(selection: $selectedTab) {
            DevicesView()
                .tabItem {
                    Image(systemName: "lightbulb")
                    Text("Devices")
                }
                .tag(0)
            
            AutomationsView()
                .tabItem {
                    Image(systemName: "gear")
                    Text("Automations")
                }
                .tag(1)
            
            HealthRulesView()
                .tabItem {
                    Image(systemName: "heart")
                    Text("Health Rules")
                }
                .tag(2)
        }
    }
}

/// Devices View
public struct DevicesView: View {
    @StateObject private var smartHomeManager = SmartHomeManager.shared
    @State private var selectedDeviceType: HMServiceType?
    
    public init() {}
    
    public var body: some View {
        List {
            Section("Device Types") {
                ForEach(deviceTypes, id: \.self) { deviceType in
                    NavigationLink(destination: DeviceTypeView(deviceType: deviceType)) {
                        HStack {
                            Image(systemName: iconForDeviceType(deviceType))
                                .foregroundColor(.blue)
                                .frame(width: 30)
                            
                            VStack(alignment: .leading) {
                                Text(nameForDeviceType(deviceType))
                                    .font(.headline)
                                Text("\(smartHomeManager.getDevices(of: deviceType).count) devices")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            
            Section("All Devices") {
                ForEach(smartHomeManager.selectedHome?.accessories ?? [], id: \.uniqueIdentifier) { accessory in
                    DeviceRowView(accessory: accessory)
                }
            }
        }
        .navigationTitle("Devices")
    }
    
    private var deviceTypes: [HMServiceType] {
        return [
            HMServiceTypeLightbulb,
            HMServiceTypeThermostat,
            HMServiceTypeSwitch,
            HMServiceTypeOutlet,
            HMServiceTypeSpeaker,
            HMServiceTypeLock
        ]
    }
    
    private func iconForDeviceType(_ type: HMServiceType) -> String {
        switch type {
        case HMServiceTypeLightbulb: return "lightbulb"
        case HMServiceTypeThermostat: return "thermometer"
        case HMServiceTypeSwitch: return "switch.2"
        case HMServiceTypeOutlet: return "poweroutlet.type.b"
        case HMServiceTypeSpeaker: return "speaker.wave.3"
        case HMServiceTypeLock: return "lock"
        default: return "gear"
        }
    }
    
    private func nameForDeviceType(_ type: HMServiceType) -> String {
        switch type {
        case HMServiceTypeLightbulb: return "Lights"
        case HMServiceTypeThermostat: return "Thermostats"
        case HMServiceTypeSwitch: return "Switches"
        case HMServiceTypeOutlet: return "Outlets"
        case HMServiceTypeSpeaker: return "Speakers"
        case HMServiceTypeLock: return "Locks"
        default: return "Other"
        }
    }
}

/// Device Type View
public struct DeviceTypeView: View {
    let deviceType: HMServiceType
    @StateObject private var smartHomeManager = SmartHomeManager.shared
    
    public init(deviceType: HMServiceType) {
        self.deviceType = deviceType
    }
    
    public var body: some View {
        List {
            ForEach(smartHomeManager.getDevices(of: deviceType), id: \.uniqueIdentifier) { accessory in
                DeviceRowView(accessory: accessory)
            }
        }
        .navigationTitle(nameForDeviceType(deviceType))
    }
    
    private func nameForDeviceType(_ type: HMServiceType) -> String {
        switch type {
        case HMServiceTypeLightbulb: return "Lights"
        case HMServiceTypeThermostat: return "Thermostats"
        case HMServiceTypeSwitch: return "Switches"
        case HMServiceTypeOutlet: return "Outlets"
        case HMServiceTypeSpeaker: return "Speakers"
        case HMServiceTypeLock: return "Locks"
        default: return "Other"
        }
    }
}

/// Device Row View
public struct DeviceRowView: View {
    let accessory: HMAccessory
    @State private var showingDetails = false
    
    public init(accessory: HMAccessory) {
        self.accessory = accessory
    }
    
    public var body: some View {
        Button(action: {
            showingDetails = true
        }) {
            HStack {
                Image(systemName: iconForAccessory(accessory))
                    .foregroundColor(accessory.reachable ? .green : .red)
                    .frame(width: 30)
                
                VStack(alignment: .leading) {
                    Text(accessory.name)
                        .font(.headline)
                    Text(accessory.reachable ? "Online" : "Offline")
                        .font(.caption)
                        .foregroundColor(accessory.reachable ? .green : .red)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showingDetails) {
            DeviceDetailView(device: accessory)
        }
    }
    
    private func iconForAccessory(_ accessory: HMAccessory) -> String {
        if accessory.services.contains(where: { $0.serviceType == HMServiceTypeLightbulb }) {
            return "lightbulb"
        } else if accessory.services.contains(where: { $0.serviceType == HMServiceTypeThermostat }) {
            return "thermometer"
        } else if accessory.services.contains(where: { $0.serviceType == HMServiceTypeSwitch }) {
            return "switch.2"
        } else if accessory.services.contains(where: { $0.serviceType == HMServiceTypeOutlet }) {
            return "poweroutlet.type.b"
        } else if accessory.services.contains(where: { $0.serviceType == HMServiceTypeSpeaker }) {
            return "speaker.wave.3"
        } else if accessory.services.contains(where: { $0.serviceType == HMServiceTypeLock }) {
            return "lock"
        } else {
            return "gear"
        }
    }
}

/// Device Detail View
public struct DeviceDetailView: View {
    let device: HMAccessory
    @Environment(\.dismiss) private var dismiss
    
    public init(device: HMAccessory) {
        self.device = device
    }
    
    public var body: some View {
        NavigationView {
            List {
                Section("Device Info") {
                    HStack {
                        Text("Name")
                        Spacer()
                        Text(device.name)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Status")
                        Spacer()
                        Text(device.reachable ? "Online" : "Offline")
                            .foregroundColor(device.reachable ? .green : .red)
                    }
                    
                    HStack {
                        Text("Manufacturer")
                        Spacer()
                        Text(device.manufacturer ?? "Unknown")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Model")
                        Spacer()
                        Text(device.model ?? "Unknown")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section("Services") {
                    ForEach(device.services, id: \.uniqueIdentifier) { service in
                        VStack(alignment: .leading) {
                            Text(service.name)
                                .font(.headline)
                            Text(service.serviceType)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Section("Characteristics") {
                    ForEach(device.services.flatMap { $0.characteristics }, id: \.uniqueIdentifier) { characteristic in
                        VStack(alignment: .leading) {
                            Text(characteristic.characteristicType)
                                .font(.headline)
                            Text("Readable: \(characteristic.isReadable ? "Yes" : "No")")
                                .font(.caption)
                            Text("Writable: \(characteristic.isWritable ? "Yes" : "No")")
                                .font(.caption)
                        }
                    }
                }
            }
            .navigationTitle(device.name)
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

/// Automations View
public struct AutomationsView: View {
    @StateObject private var smartHomeManager = SmartHomeManager.shared
    
    public init() {}
    
    public var body: some View {
        List {
            Section("HomeKit Automations") {
                ForEach(smartHomeManager.automations, id: \.uniqueIdentifier) { automation in
                    VStack(alignment: .leading) {
                        Text(automation.name)
                            .font(.headline)
                        Text("Enabled: \(automation.isEnabled ? "Yes" : "No")")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Automations")
    }
}

/// Health Rules View
public struct HealthRulesView: View {
    @StateObject private var smartHomeManager = SmartHomeManager.shared
    @State private var showingAddRule = false
    
    public init() {}
    
    public var body: some View {
        List {
            Section("Health-Based Rules") {
                ForEach(smartHomeManager.healthRules) { rule in
                    HealthRuleRowView(rule: rule)
                }
                .onDelete(perform: deleteRules)
            }
        }
        .navigationTitle("Health Rules")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showingAddRule = true
                }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddRule) {
            AddHealthRuleView()
        }
    }
    
    private func deleteRules(offsets: IndexSet) {
        for index in offsets {
            let rule = smartHomeManager.healthRules[index]
            Task {
                try await smartHomeManager.deleteHealthRule(rule)
            }
        }
    }
}

/// Health Rule Row View
public struct HealthRuleRowView: View {
    let rule: HealthAutomationRule
    @StateObject private var smartHomeManager = SmartHomeManager.shared
    @State private var showingEdit = false
    
    public init(rule: HealthAutomationRule) {
        self.rule = rule
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading) {
                    Text(rule.name)
                        .font(.headline)
                    Text("\(rule.trigger.metric) \(rule.trigger.condition.rawValue) \(String(format: "%.1f", rule.trigger.threshold))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Toggle("", isOn: Binding(
                    get: { rule.isEnabled },
                    set: { newValue in
                        var updatedRule = rule
                        updatedRule.isEnabled = newValue
                        Task {
                            try await smartHomeManager.updateHealthRule(updatedRule)
                        }
                    }
                ))
            }
            
            Text(rule.action.description)
                .font(.caption)
                .foregroundColor(.blue)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            showingEdit = true
        }
        .sheet(isPresented: $showingEdit) {
            EditHealthRuleView(rule: rule)
        }
    }
}

/// Add Health Rule View
public struct AddHealthRuleView: View {
    @StateObject private var smartHomeManager = SmartHomeManager.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var ruleName = ""
    @State private var selectedMetric = "heart_rate"
    @State private var selectedCondition = TriggerCondition.greaterThan
    @State private var threshold = 80.0
    @State private var selectedAction = AutomationAction.adjustLighting(brightness: 0.5, color: nil)
    
    private let metrics = [
        ("heart_rate", "Heart Rate"),
        ("stress_level", "Stress Level"),
        ("sleep_quality", "Sleep Quality"),
        ("activity_level", "Activity Level")
    ]
    
    public init() {}
    
    public var body: some View {
        NavigationView {
            Form {
                Section("Rule Details") {
                    TextField("Rule Name", text: $ruleName)
                }
                
                Section("Trigger") {
                    Picker("Health Metric", selection: $selectedMetric) {
                        ForEach(metrics, id: \.0) { metric in
                            Text(metric.1).tag(metric.0)
                        }
                    }
                    
                    Picker("Condition", selection: $selectedCondition) {
                        ForEach(TriggerCondition.allCases, id: \.self) { condition in
                            Text(condition.rawValue).tag(condition)
                        }
                    }
                    
                    HStack {
                        Text("Threshold")
                        Spacer()
                        TextField("Value", value: $threshold, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                }
                
                Section("Action") {
                    Picker("Action Type", selection: $selectedAction) {
                        Text("Adjust Lighting").tag(AutomationAction.adjustLighting(brightness: 0.5, color: nil))
                        Text("Adjust Temperature").tag(AutomationAction.adjustTemperature(temperature: 22.0))
                        Text("Play Sound").tag(AutomationAction.playSound(soundType: .relaxation))
                        Text("Send Notification").tag(AutomationAction.sendNotification(message: "Health alert"))
                    }
                }
            }
            .navigationTitle("Add Health Rule")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveRule()
                    }
                    .disabled(ruleName.isEmpty)
                }
            }
        }
    }
    
    private func saveRule() {
        let trigger = HealthTrigger(
            metric: selectedMetric,
            condition: selectedCondition,
            threshold: threshold
        )
        
        Task {
            do {
                _ = try await smartHomeManager.createHealthRule(
                    trigger: trigger,
                    action: selectedAction,
                    name: ruleName
                )
                await MainActor.run {
                    dismiss()
                }
            } catch {
                print("Failed to create rule: \(error)")
            }
        }
    }
}

/// Edit Health Rule View
public struct EditHealthRuleView: View {
    let rule: HealthAutomationRule
    @StateObject private var smartHomeManager = SmartHomeManager.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var ruleName: String
    @State private var selectedMetric: String
    @State private var selectedCondition: TriggerCondition
    @State private var threshold: Double
    @State private var selectedAction: AutomationAction
    @State private var isEnabled: Bool
    
    public init(rule: HealthAutomationRule) {
        self.rule = rule
        self._ruleName = State(initialValue: rule.name)
        self._selectedMetric = State(initialValue: rule.trigger.metric)
        self._selectedCondition = State(initialValue: rule.trigger.condition)
        self._threshold = State(initialValue: rule.trigger.threshold)
        self._selectedAction = State(initialValue: rule.action)
        self._isEnabled = State(initialValue: rule.isEnabled)
    }
    
    public var body: some View {
        NavigationView {
            Form {
                Section("Rule Details") {
                    TextField("Rule Name", text: $ruleName)
                    Toggle("Enabled", isOn: $isEnabled)
                }
                
                Section("Trigger") {
                    Picker("Health Metric", selection: $selectedMetric) {
                        Text("Heart Rate").tag("heart_rate")
                        Text("Stress Level").tag("stress_level")
                        Text("Sleep Quality").tag("sleep_quality")
                        Text("Activity Level").tag("activity_level")
                    }
                    
                    Picker("Condition", selection: $selectedCondition) {
                        ForEach(TriggerCondition.allCases, id: \.self) { condition in
                            Text(condition.rawValue).tag(condition)
                        }
                    }
                    
                    HStack {
                        Text("Threshold")
                        Spacer()
                        TextField("Value", value: $threshold, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                }
                
                Section("Action") {
                    Picker("Action Type", selection: $selectedAction) {
                        Text("Adjust Lighting").tag(AutomationAction.adjustLighting(brightness: 0.5, color: nil))
                        Text("Adjust Temperature").tag(AutomationAction.adjustTemperature(temperature: 22.0))
                        Text("Play Sound").tag(AutomationAction.playSound(soundType: .relaxation))
                        Text("Send Notification").tag(AutomationAction.sendNotification(message: "Health alert"))
                    }
                }
            }
            .navigationTitle("Edit Health Rule")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveRule()
                    }
                    .disabled(ruleName.isEmpty)
                }
            }
        }
    }
    
    private func saveRule() {
        let trigger = HealthTrigger(
            metric: selectedMetric,
            condition: selectedCondition,
            threshold: threshold
        )
        
        let updatedRule = HealthAutomationRule(
            id: rule.id,
            name: ruleName,
            trigger: trigger,
            action: selectedAction,
            isEnabled: isEnabled,
            createdAt: rule.createdAt
        )
        
        Task {
            do {
                try await smartHomeManager.updateHealthRule(updatedRule)
                await MainActor.run {
                    dismiss()
                }
            } catch {
                print("Failed to update rule: \(error)")
            }
        }
    }
}

/// Preview
struct SmartHomeView_Previews: PreviewProvider {
    static var previews: some View {
        SmartHomeView()
    }
} 
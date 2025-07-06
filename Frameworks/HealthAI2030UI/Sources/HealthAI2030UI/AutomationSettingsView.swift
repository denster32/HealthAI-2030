import SwiftUI

struct AutomationSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var smartHomeManager = SmartHomeManager.shared
    @State private var showingNewRuleSheet = false
    @State private var selectedRule: EnvironmentAutomationRule?
    @State private var showingEditRuleSheet = false
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    ForEach(smartHomeManager.automationRules) { rule in
                        AutomationRuleRow(rule: rule) {
                            selectedRule = rule
                            showingEditRuleSheet = true
                        }
                    }
                    .onDelete(perform: deleteRules)
                } header: {
                    HStack {
                        Text("Automation Rules")
                        Spacer()
                        Text("\(smartHomeManager.automationRules.filter { $0.isEnabled }.count) Active")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Section {
                    Button {
                        showingNewRuleSheet = true
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.accentColor)
                            Text("Add New Rule")
                        }
                    }
                } footer: {
                    Text("Create custom automation rules to optimize your environment based on health data, time, and conditions.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Section("Quick Templates") {
                    ForEach(AutomationTemplate.allCases, id: \.self) { template in
                        AutomationTemplateRow(template: template) {
                            createRuleFromTemplate(template)
                        }
                    }
                }
            }
            .navigationTitle("Automation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingNewRuleSheet) {
                NewAutomationRuleView()
            }
            .sheet(isPresented: $showingEditRuleSheet) {
                if let rule = selectedRule {
                    EditAutomationRuleView(rule: rule)
                }
            }
        }
    }
    
    private func deleteRules(at offsets: IndexSet) {
        smartHomeManager.automationRules.remove(atOffsets: offsets)
    }
    
    private func createRuleFromTemplate(_ template: AutomationTemplate) {
        let rule = template.createRule()
        smartHomeManager.automationRules.append(rule)
    }
}

struct AutomationRuleRow: View {
    let rule: EnvironmentAutomationRule
    let action: () -> Void
    @StateObject private var smartHomeManager = SmartHomeManager.shared
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(rule.name)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        Text(rule.trigger.displayName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: .constant(rule.isEnabled))
                        .labelsHidden()
                }
                
                HStack {
                    Text("\(rule.actions.count) action\(rule.actions.count == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    if let lastExecuted = rule.lastExecuted {
                        Text("Last: \(lastExecuted, style: .relative)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text("Never executed")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.vertical, 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct AutomationTemplateRow: View {
    let template: AutomationTemplate
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: template.icon)
                    .font(.title3)
                    .foregroundColor(template.color)
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(template.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text(template.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                Image(systemName: "plus.circle")
                    .font(.title3)
                    .foregroundColor(.accentColor)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Automation Templates

enum AutomationTemplate: CaseIterable {
    case bedtimeOptimization
    case morningWakeup
    case stressRelief
    case focusMode
    case energyBoost
    case weekendRelax
    
    var name: String {
        switch self {
        case .bedtimeOptimization: return "Bedtime Optimization"
        case .morningWakeup: return "Morning Wake-up"
        case .stressRelief: return "Stress Relief"
        case .focusMode: return "Focus Mode"
        case .energyBoost: return "Energy Boost"
        case .weekendRelax: return "Weekend Relaxation"
        }
    }
    
    var description: String {
        switch self {
        case .bedtimeOptimization: return "Automatically optimize environment for sleep when bedtime approaches"
        case .morningWakeup: return "Gradually increase lighting and adjust temperature for natural wake-up"
        case .stressRelief: return "Activate calming environment when stress levels are high"
        case .focusMode: return "Optimize lighting and temperature for concentration during work hours"
        case .energyBoost: return "Increase lighting and alertness when energy levels are low"
        case .weekendRelax: return "Create a relaxing atmosphere on weekend mornings"
        }
    }
    
    var icon: String {
        switch self {
        case .bedtimeOptimization: return "moon.fill"
        case .morningWakeup: return "sun.max.fill"
        case .stressRelief: return "heart.fill"
        case .focusMode: return "brain.head.profile"
        case .energyBoost: return "bolt.fill"
        case .weekendRelax: return "leaf.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .bedtimeOptimization: return .indigo
        case .morningWakeup: return .orange
        case .stressRelief: return .blue
        case .focusMode: return .purple
        case .energyBoost: return .yellow
        case .weekendRelax: return .green
        }
    }
    
    func createRule() -> EnvironmentAutomationRule {
        switch self {
        case .bedtimeOptimization:
            return EnvironmentAutomationRule(
                id: UUID().uuidString,
                name: "Bedtime Optimization",
                trigger: .time("22:00"),
                conditions: [
                    .timeRange(start: "21:00", end: "23:00")
                ],
                actions: [
                    .adjustLighting(brightness: 0.2, colorTemp: 2700),
                    .setTemperature(target: 19.0),
                    .enableWhiteNoise(volume: 0.3)
                ],
                isEnabled: true
            )
            
        case .morningWakeup:
            return EnvironmentAutomationRule(
                id: UUID().uuidString,
                name: "Morning Wake-up",
                trigger: .time("06:30"),
                conditions: [
                    .timeRange(start: "06:00", end: "08:00"),
                    .dayOfWeek([2, 3, 4, 5, 6]) // Weekdays
                ],
                actions: [
                    .adjustLighting(brightness: 0.8, colorTemp: 5500),
                    .setTemperature(target: 22.0),
                    .disableWhiteNoise()
                ],
                isEnabled: true
            )
            
        case .stressRelief:
            return EnvironmentAutomationRule(
                id: UUID().uuidString,
                name: "Stress Relief",
                trigger: .stressLevel(0.7),
                conditions: [
                    .stressLevel(min: 0.7, max: nil)
                ],
                actions: [
                    .adjustLighting(brightness: 0.4, colorTemp: 2700),
                    .setTemperature(target: 21.0),
                    .enableWhiteNoise(volume: 0.25)
                ],
                isEnabled: true
            )
            
        case .focusMode:
            return EnvironmentAutomationRule(
                id: UUID().uuidString,
                name: "Focus Mode",
                trigger: .time("09:00"),
                conditions: [
                    .timeRange(start: "09:00", end: "17:00"),
                    .dayOfWeek([2, 3, 4, 5, 6]) // Weekdays
                ],
                actions: [
                    .adjustLighting(brightness: 0.85, colorTemp: 5500),
                    .setTemperature(target: 21.5),
                    .disableWhiteNoise()
                ],
                isEnabled: true
            )
            
        case .energyBoost:
            return EnvironmentAutomationRule(
                id: UUID().uuidString,
                name: "Energy Boost",
                trigger: .time("14:00"), // Post-lunch energy dip
                conditions: [
                    .timeRange(start: "13:00", end: "16:00")
                ],
                actions: [
                    .adjustLighting(brightness: 1.0, colorTemp: 6500),
                    .setTemperature(target: 20.0)
                ],
                isEnabled: true
            )
            
        case .weekendRelax:
            return EnvironmentAutomationRule(
                id: UUID().uuidString,
                name: "Weekend Relaxation",
                trigger: .time("09:00"),
                conditions: [
                    .timeRange(start: "08:00", end: "11:00"),
                    .dayOfWeek([1, 7]) // Weekend
                ],
                actions: [
                    .adjustLighting(brightness: 0.6, colorTemp: 3000),
                    .setTemperature(target: 22.5),
                    .playSound(soundType: .ocean, volume: 0.2)
                ],
                isEnabled: true
            )
        }
    }
}

// MARK: - New Automation Rule View

struct NewAutomationRuleView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var smartHomeManager = SmartHomeManager.shared
    
    @State private var name = ""
    @State private var selectedTrigger: AutomationTrigger = .time("09:00")
    @State private var conditions: [AutomationCondition] = []
    @State private var actions: [AutomationAction] = []
    @State private var isEnabled = true
    
    var body: some View {
        NavigationView {
            Form {
                Section("Rule Name") {
                    TextField("Enter rule name", text: $name)
                }
                
                Section("Trigger") {
                    TriggerSelectionView(selectedTrigger: $selectedTrigger)
                }
                
                Section("Conditions") {
                    ConditionsListView(conditions: $conditions)
                }
                
                Section("Actions") {
                    ActionsListView(actions: $actions)
                }
                
                Section {
                    Toggle("Enable Rule", isOn: $isEnabled)
                }
            }
            .navigationTitle("New Rule")
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
                    .disabled(name.isEmpty || actions.isEmpty)
                }
            }
        }
    }
    
    private func saveRule() {
        let rule = EnvironmentAutomationRule(
            id: UUID().uuidString,
            name: name,
            trigger: selectedTrigger,
            conditions: conditions,
            actions: actions,
            isEnabled: isEnabled
        )
        
        smartHomeManager.automationRules.append(rule)
        dismiss()
    }
}

// MARK: - Edit Automation Rule View

struct EditAutomationRuleView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var smartHomeManager = SmartHomeManager.shared
    
    let rule: EnvironmentAutomationRule
    
    @State private var name: String
    @State private var selectedTrigger: AutomationTrigger
    @State private var conditions: [AutomationCondition]
    @State private var actions: [AutomationAction]
    @State private var isEnabled: Bool
    
    init(rule: EnvironmentAutomationRule) {
        self.rule = rule
        self._name = State(initialValue: rule.name)
        self._selectedTrigger = State(initialValue: rule.trigger)
        self._conditions = State(initialValue: rule.conditions)
        self._actions = State(initialValue: rule.actions)
        self._isEnabled = State(initialValue: rule.isEnabled)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Rule Name") {
                    TextField("Enter rule name", text: $name)
                }
                
                Section("Trigger") {
                    TriggerSelectionView(selectedTrigger: $selectedTrigger)
                }
                
                Section("Conditions") {
                    ConditionsListView(conditions: $conditions)
                }
                
                Section("Actions") {
                    ActionsListView(actions: $actions)
                }
                
                Section {
                    Toggle("Enable Rule", isOn: $isEnabled)
                }
                
                Section {
                    if let lastExecuted = rule.lastExecuted {
                        HStack {
                            Text("Last Executed")
                            Spacer()
                            Text(lastExecuted, style: .relative)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    HStack {
                        Text("Created")
                        Spacer()
                        Text(rule.createdAt, style: .date)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Edit Rule")
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
                    .disabled(name.isEmpty || actions.isEmpty)
                }
            }
        }
    }
    
    private func saveRule() {
        let updatedRule = EnvironmentAutomationRule(
            id: rule.id,
            name: name,
            trigger: selectedTrigger,
            conditions: conditions,
            actions: actions,
            isEnabled: isEnabled,
            createdAt: rule.createdAt,
            lastExecuted: rule.lastExecuted
        )
        
        if let index = smartHomeManager.automationRules.firstIndex(where: { $0.id == rule.id }) {
            smartHomeManager.automationRules[index] = updatedRule
        }
        
        dismiss()
    }
}

// MARK: - Supporting Views

struct TriggerSelectionView: View {
    @Binding var selectedTrigger: AutomationTrigger
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("When this happens:")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(selectedTrigger.displayName)
                .font(.subheadline)
            
            // Simplified trigger selection - in a real app, this would be more comprehensive
            Button("Change Trigger") {
                // Would show trigger selection sheet
            }
            .font(.caption)
            .foregroundColor(.accentColor)
        }
    }
}

struct ConditionsListView: View {
    @Binding var conditions: [AutomationCondition]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if conditions.isEmpty {
                Text("No conditions set")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else {
                ForEach(Array(conditions.enumerated()), id: \.offset) { index, condition in
                    HStack {
                        Text(condition.displayName)
                            .font(.subheadline)
                        
                        Spacer()
                        
                        Button("Remove") {
                            conditions.remove(at: index)
                        }
                        .font(.caption)
                        .foregroundColor(.red)
                    }
                }
            }
            
            Button("Add Condition") {
                // Would show condition selection sheet
                conditions.append(.timeRange(start: "09:00", end: "17:00"))
            }
            .font(.caption)
            .foregroundColor(.accentColor)
        }
    }
}

struct ActionsListView: View {
    @Binding var actions: [AutomationAction]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if actions.isEmpty {
                Text("No actions set")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else {
                ForEach(Array(actions.enumerated()), id: \.offset) { index, action in
                    HStack {
                        Text(action.displayName)
                            .font(.subheadline)
                        
                        Spacer()
                        
                        Button("Remove") {
                            actions.remove(at: index)
                        }
                        .font(.caption)
                        .foregroundColor(.red)
                    }
                }
            }
            
            Menu("Add Action") {
                Button("Adjust Lighting") {
                    actions.append(.adjustLighting(brightness: 0.5, colorTemp: 3000))
                }
                
                Button("Set Temperature") {
                    actions.append(.setTemperature(target: 21.0))
                }
                
                Button("Control Humidity") {
                    actions.append(.setHumidity(target: 50.0))
                }
                
                Button("Enable White Noise") {
                    actions.append(.enableWhiteNoise(volume: 0.3))
                }
                
                Button("Send Notification") {
                    actions.append(.sendNotification(title: "Automation", message: "Rule executed"))
                }
            }
            .font(.caption)
            .foregroundColor(.accentColor)
        }
    }
}

struct DeviceDetailView: View {
    let device: SmartHomeDevice
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Device Header
                    VStack(spacing: 12) {
                        Image(systemName: device.statusIcon)
                            .font(.largeTitle)
                            .foregroundColor(.accentColor)
                        
                        Text(device.name)
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text(device.type.displayName)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            Circle()
                                .fill(Color(device.statusColor))
                                .frame(width: 8, height: 8)
                            
                            Text(device.isReachable ? "Online" : "Offline")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(16)
                    
                    // Device Information
                    VStack(spacing: 16) {
                        InfoRow(title: "Platform", value: device.platform.displayName)
                        InfoRow(title: "Room", value: device.room)
                        InfoRow(title: "Last Updated", value: device.lastUpdated.formatted(date: .abbreviated, time: .shortened))
                        InfoRow(title: "Device ID", value: String(device.id.prefix(8)) + "...")
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(16)
                    
                    // Device Capabilities
                    if hasCapabilities(device.capabilities) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Current Status")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            VStack(spacing: 8) {
                                if let temp = device.capabilities.currentTemperature {
                                    InfoRow(title: "Temperature", value: "\(String(format: "%.1f", temp))°C")
                                }
                                
                                if let humidity = device.capabilities.currentHumidity {
                                    InfoRow(title: "Humidity", value: "\(Int(humidity))%")
                                }
                                
                                if let brightness = device.capabilities.currentBrightness {
                                    InfoRow(title: "Brightness", value: "\(Int(brightness * 100))%")
                                }
                                
                                if let colorTemp = device.capabilities.currentColorTemperature {
                                    InfoRow(title: "Color Temperature", value: "\(colorTemp)K")
                                }
                                
                                if let isOn = device.capabilities.isPoweredOn {
                                    InfoRow(title: "Power", value: isOn ? "On" : "Off")
                                }
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(16)
                    }
                }
                .padding()
            }
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
    
    private func hasCapabilities(_ capabilities: DeviceCapabilities) -> Bool {
        return capabilities.currentTemperature != nil ||
               capabilities.currentHumidity != nil ||
               capabilities.currentBrightness != nil ||
               capabilities.currentColorTemperature != nil ||
               capabilities.isPoweredOn != nil
    }
}

struct InfoRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
}

#Preview {
    AutomationSettingsView()
}
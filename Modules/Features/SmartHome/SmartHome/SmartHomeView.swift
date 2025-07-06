import SwiftUI

/// Main Smart Home View
public struct SmartHomeView: View {
    @StateObject private var smartHomeManager = SmartHomeManager.shared
    @State private var showingAddRule = false
    @State private var showingDeviceDetails = false
    @State private var selectedDevice: String?
    
    public init() {}
    
    public var body: some View {
        NavigationView {
            List {
                Section("Smart Home Status") {
                    HStack {
                        Image(systemName: smartHomeManager.isHomeKitAvailable ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(smartHomeManager.isHomeKitAvailable ? .green : .red)
                        Text("HomeKit Available")
                        Spacer()
                        Text(smartHomeManager.isHomeKitAvailable ? "Yes" : "No")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Image(systemName: smartHomeManager.isAuthorized ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(smartHomeManager.isAuthorized ? .green : .red)
                        Text("Authorized")
                        Spacer()
                        Text(smartHomeManager.isAuthorized ? "Yes" : "No")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section("Homes") {
                    ForEach(smartHomeManager.homes, id: \.self) { home in
                        HStack {
                            Image(systemName: "house.fill")
                                .foregroundColor(.blue)
                            Text(home)
                            Spacer()
                            if smartHomeManager.selectedHome == home {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.green)
                            }
                        }
                    }
                }
                
                Section("Devices") {
                    ForEach(smartHomeManager.devices, id: \.self) { device in
                        HStack {
                            Image(systemName: "lightbulb.fill")
                                .foregroundColor(.yellow)
                            Text(device)
                        }
                    }
                }
                
                Section("Automations") {
                    ForEach(smartHomeManager.automations, id: \.self) { automation in
                        HStack {
                            Image(systemName: "gear")
                                .foregroundColor(.orange)
                            Text(automation)
                        }
                    }
                }
                
                Section("Health Rules") {
                    ForEach(smartHomeManager.healthRules) { rule in
                        VStack(alignment: .leading) {
                            Text(rule.name)
                                .font(.headline)
                            Text("Trigger: \(rule.trigger.metric) \(rule.trigger.condition.rawValue) \(rule.trigger.threshold)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("Action: \(rule.action.description)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Smart Home")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Add Rule") {
                        showingAddRule = true
                    }
                }
            }
            .sheet(isPresented: $showingAddRule) {
                AddHealthRuleView()
            }
        }
    }
}

/// Add Health Rule View
public struct AddHealthRuleView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var smartHomeManager = SmartHomeManager.shared
    
    @State private var ruleName = ""
    @State private var selectedMetric = "heart_rate"
    @State private var selectedCondition = TriggerCondition.greaterThan
    @State private var threshold = 80.0
    @State private var selectedAction = AutomationAction.adjustLighting(brightness: 0.5, color: nil)
    
    private let metrics = [
        "heart_rate": "Heart Rate",
        "stress_level": "Stress Level",
        "sleep_quality": "Sleep Quality",
        "activity_level": "Activity Level"
    ]
    
    public init() {}
    
    public var body: some View {
        NavigationView {
            Form {
                Section("Rule Details") {
                    TextField("Rule Name", text: $ruleName)
                    
                    Picker("Metric", selection: $selectedMetric) {
                        ForEach(Array(metrics.keys), id: \.self) { key in
                            Text(metrics[key] ?? key).tag(key)
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

            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
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
        
        let rule = HealthAutomationRule(
            id: UUID().uuidString,
            name: ruleName,
            trigger: trigger,
            action: selectedAction,
            isEnabled: true,
            createdAt: Date()
        )
        
        smartHomeManager.healthRules.append(rule)
        dismiss()
    }
}

#Preview {
    SmartHomeView()
} 
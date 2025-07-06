import SwiftUI

struct SystemIntelligenceView: View {
    @StateObject private var intelligenceManager = SystemIntelligenceManager.shared
    @State private var selectedTab = 0
    @State private var showingAddRule = false
    @State private var showingShortcutDetails = false
    @State private var selectedShortcut: AppShortcut?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Tab Picker
                Picker("Intelligence Type", selection: $selectedTab) {
                    Text("Suggestions").tag(0)
                    Text("Shortcuts").tag(1)
                    Text("Automation").tag(2)
                    Text("Insights").tag(3)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                // Content
                TabView(selection: $selectedTab) {
                    SiriSuggestionsView(suggestions: intelligenceManager.siriSuggestions)
                        .onAppear { intelligenceManager.generateSiriSuggestions() }
                        .tag(0)
                    
                    AppShortcutsView(
                        shortcuts: intelligenceManager.appShortcuts,
                        onShortcutTap: { shortcut in
                            selectedShortcut = shortcut
                            showingShortcutDetails = true
                        }
                    )
                    .onAppear { intelligenceManager.loadAppShortcuts() }
                    .tag(1)
                    
                    AutomationRulesView(
                        rules: intelligenceManager.automationRules,
                        onAddRule: { showingAddRule = true },
                        onToggleRule: { rule in
                            intelligenceManager.updateAutomationRule(rule)
                        }
                    )
                    .tag(2)
                    
                    PredictiveInsightsView(insights: intelligenceManager.predictiveInsights)
                        .onAppear { intelligenceManager.generatePredictiveInsights() }
                        .tag(3)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .navigationTitle("System Intelligence")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingAddRule) {
                AddAutomationRuleView { rule in
                    intelligenceManager.addAutomationRule(rule)
                    showingAddRule = false
                }
            }
            .sheet(isPresented: $showingShortcutDetails) {
                if let shortcut = selectedShortcut {
                    ShortcutDetailView(shortcut: shortcut)
                }
            }
        }
    }
}

// MARK: - Siri Suggestions View

struct SiriSuggestionsView: View {
    let suggestions: [SiriSuggestion]
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(suggestions, id: \.title) { suggestion in
                    SiriSuggestionCard(suggestion: suggestion)
                }
            }
            .padding()
        }
    }
}

struct SiriSuggestionCard: View {
    let suggestion: SiriSuggestion
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: suggestionIcon)
                    .foregroundColor(suggestionColor)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(suggestion.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text(suggestion.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                PriorityBadge(priority: suggestion.priority)
            }
            
            HStack {
                Label(suggestion.trigger.displayName, systemImage: "bolt")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button("Activate") {
                    // Handle suggestion activation
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var suggestionIcon: String {
        switch suggestion.type {
        case .mindfulness: return "brain.head.profile"
        case .breathing: return "lungs.fill"
        case .sleep: return "bed.double.fill"
        case .cardiac: return "heart.fill"
        case .respiratory: return "lungs"
        case .general: return "lightbulb"
        }
    }
    
    private var suggestionColor: Color {
        switch suggestion.type {
        case .mindfulness: return .purple
        case .breathing: return .blue
        case .sleep: return .indigo
        case .cardiac: return .red
        case .respiratory: return .cyan
        case .general: return .orange
        }
    }
}

struct PriorityBadge: View {
    let priority: SiriSuggestion.SuggestionPriority
    
    var body: some View {
        Text(priority.displayName)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(priorityColor)
            .foregroundColor(.white)
            .cornerRadius(8)
    }
    
    private var priorityColor: Color {
        switch priority {
        case .low: return .gray
        case .medium: return .blue
        case .high: return .orange
        case .critical: return .red
        }
    }
}

// MARK: - App Shortcuts View

struct AppShortcutsView: View {
    let shortcuts: [AppShortcut]
    let onShortcutTap: (AppShortcut) -> Void
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                ForEach(shortcuts, id: \.intent) { shortcut in
                    AppShortcutCard(shortcut: shortcut) {
                        onShortcutTap(shortcut)
                    }
                }
            }
            .padding()
        }
    }
}

struct AppShortcutCard: View {
    let shortcut: AppShortcut
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                Image(systemName: shortcut.icon)
                    .font(.title)
                    .foregroundColor(.blue)
                
                VStack(spacing: 4) {
                    Text(shortcut.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.center)
                    
                    Text(shortcut.subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Automation Rules View

struct AutomationRulesView: View {
    let rules: [AutomationRule]
    let onAddRule: () -> Void
    let onToggleRule: (AutomationRule) -> Void
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(rules, id: \.id) { rule in
                    AutomationRuleCard(
                        rule: rule,
                        onToggle: { onToggleRule(rule) }
                    )
                }
            }
            .padding()
        }
        .overlay(
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: onAddRule) {
                        Image(systemName: "plus")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(width: 56, height: 56)
                            .background(Color.blue)
                            .clipShape(Circle())
                            .shadow(radius: 4)
                    }
                    .padding()
                }
            }
        )
    }
}

struct AutomationRuleCard: View {
    let rule: AutomationRule
    let onToggle: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(rule.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text(rule.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Toggle("", isOn: .constant(rule.isActive))
                    .onChange(of: rule.isActive) { _ in
                        onToggle()
                    }
            }
            
            HStack {
                Label(rule.trigger.displayName, systemImage: "bolt")
                    .font(.caption)
                    .foregroundColor(.blue)
                
                Spacer()
                
                Text("\(rule.actions.count) actions")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Predictive Insights View

struct PredictiveInsightsView: View {
    let insights: [PredictiveInsight]
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(insights, id: \.id) { insight in
                    PredictiveInsightCard(insight: insight)
                }
            }
            .padding()
        }
    }
}

struct PredictiveInsightCard: View {
    let insight: PredictiveInsight
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(insight.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text(insight.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(Int(insight.confidence * 100))%")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                    
                    Text("Confidence")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            if !insight.recommendations.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Recommendations")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    ForEach(insight.recommendations, id: \.self) { recommendation in
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.caption)
                            
                            Text(recommendation)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            
            HStack {
                Label(insight.category.displayName, systemImage: insight.category.icon)
                    .font(.caption)
                    .foregroundColor(.blue)
                
                Spacer()
                
                Text(insight.timestamp, style: .relative)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Supporting Views

struct AddAutomationRuleView: View {
    @Environment(\.dismiss) private var dismiss
    let onAdd: (AutomationRule) -> Void
    
    @State private var name = ""
    @State private var description = ""
    @State private var selectedTrigger = AutomationRule.AutomationTrigger.stressLevel
    @State private var selectedActions: Set<AutomationRule.AutomationAction> = []
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Rule Details") {
                    TextField("Rule Name", text: $name)
                    TextField("Description", text: $description)
                }
                
                Section("Trigger") {
                    Picker("Trigger", selection: $selectedTrigger) {
                        ForEach(AutomationRule.AutomationTrigger.allCases, id: \.self) { trigger in
                            Text(trigger.displayName).tag(trigger)
                        }
                    }
                }
                
                Section("Actions") {
                    ForEach(AutomationRule.AutomationAction.allCases, id: \.self) { action in
                        HStack {
                            Text(action.displayName)
                            Spacer()
                            if selectedActions.contains(action) {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if selectedActions.contains(action) {
                                selectedActions.remove(action)
                            } else {
                                selectedActions.insert(action)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Add Automation Rule")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        let rule = AutomationRule(
                            id: UUID().uuidString,
                            name: name,
                            description: description,
                            trigger: selectedTrigger,
                            condition: { true }, // Placeholder
                            actions: Array(selectedActions),
                            isActive: true
                        )
                        onAdd(rule)
                    }
                    .disabled(name.isEmpty || selectedActions.isEmpty)
                }
            }
        }
    }
}

struct ShortcutDetailView: View {
    let shortcut: AppShortcut
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                VStack(spacing: 16) {
                    Image(systemName: shortcut.icon)
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    VStack(spacing: 8) {
                        Text(shortcut.title)
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text(shortcut.subtitle)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                
                VStack(alignment: .leading, spacing: 16) {
                    Text("Activation Phrases")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    ForEach(shortcut.phrases, id: \.self) { phrase in
                        HStack {
                            Image(systemName: "quote.bubble")
                                .foregroundColor(.blue)
                            
                            Text(phrase)
                                .font(.subheadline)
                            
                            Spacer()
                        }
                    }
                }
                
                Spacer()
                
                Button("Test Shortcut") {
                    SystemIntelligenceManager.shared.handleAppShortcut(shortcut)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
            .padding()
            .navigationTitle("Shortcut Details")
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

// MARK: - Extensions

extension SiriSuggestion.SuggestionTrigger {
    var displayName: String {
        switch self {
        case .stressLevel: return "Stress Level"
        case .respiratoryRate: return "Respiratory Rate"
        case .circadianRhythm: return "Circadian Rhythm"
        case .heartRate: return "Heart Rate"
        case .afibStatus: return "AFib Status"
        case .sleepQuality: return "Sleep Quality"
        case .automation: return "Automation"
        }
    }
}

extension SiriSuggestion.SuggestionPriority {
    var displayName: String {
        switch self {
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        case .critical: return "Critical"
        }
    }
}

extension AutomationRule.AutomationTrigger: CaseIterable {
    var displayName: String {
        switch self {
        case .stressLevel: return "Stress Level"
        case .circadianRhythm: return "Circadian Rhythm"
        case .afibStatus: return "AFib Status"
        case .oxygenSaturation: return "Oxygen Saturation"
        case .sleepQuality: return "Sleep Quality"
        case .timeOfDay: return "Time of Day"
        case .location: return "Location"
        }
    }
}

extension AutomationRule.AutomationAction: CaseIterable {
    var displayName: String {
        switch self {
        case .suggestMindfulness: return "Suggest Mindfulness"
        case .adjustEnvironment: return "Adjust Environment"
        case .sendNotification: return "Send Notification"
        case .suggestWindDown: return "Suggest Wind Down"
        case .startSleepOptimization: return "Start Sleep Optimization"
        case .sendEmergencyAlert: return "Send Emergency Alert"
        case .suggestCardiacCheck: return "Suggest Cardiac Check"
        case .recordHealthData: return "Record Health Data"
        case .suggestBreathingExercise: return "Suggest Breathing Exercise"
        case .sendAlert: return "Send Alert"
        }
    }
}

extension PredictiveInsight.InsightCategory {
    var displayName: String {
        switch self {
        case .health: return "Health"
        case .behavior: return "Behavior"
        case .environment: return "Environment"
        case .lifestyle: return "Lifestyle"
        }
    }
    
    var icon: String {
        switch self {
        case .health: return "heart.fill"
        case .behavior: return "person.fill"
        case .environment: return "house.fill"
        case .lifestyle: return "figure.walk"
        }
    }
}
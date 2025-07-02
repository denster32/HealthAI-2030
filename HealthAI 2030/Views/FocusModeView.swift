import SwiftUI
import Intents
import IntentsUI

// MARK: - Focus Mode Manager

@MainActor
class FocusModeManager: ObservableObject {
    static let shared = FocusModeManager()
    
    @Published var availableFocusModes: [FocusMode] = []
    @Published var currentFocusMode: FocusMode?
    @Published var healthAwareFilters: [HealthAwareFilter] = []
    @Published var focusNotifications: [FocusNotification] = []
    
    private let focusCenter = FocusCenter()
    
    private init() {
        setupFocusModes()
        setupHealthAwareFilters()
        observeFocusChanges()
    }
    
    // MARK: - Focus Mode Setup
    
    private func setupFocusModes() {
        availableFocusModes = [
            FocusMode(
                id: "health_monitoring",
                name: "Health Monitoring",
                description: "Focus on health and wellness",
                icon: "heart.fill",
                color: .red,
                healthTriggers: [.highStress, .poorSleep, .cardiacAlert]
            ),
            FocusMode(
                id: "mindfulness",
                name: "Mindfulness",
                description: "Focus on mental health and meditation",
                icon: "brain.head.profile",
                color: .purple,
                healthTriggers: [.highStress, .mentalHealthDecline]
            ),
            FocusMode(
                id: "sleep_preparation",
                name: "Sleep Preparation",
                description: "Focus on sleep optimization",
                icon: "bed.double.fill",
                color: .indigo,
                healthTriggers: [.sleepTime, .poorSleepQuality]
            ),
            FocusMode(
                id: "exercise",
                name: "Exercise",
                description: "Focus on physical activity",
                icon: "figure.run",
                color: .green,
                healthTriggers: [.lowActivity, .cardiacHealth]
            ),
            FocusMode(
                id: "recovery",
                name: "Recovery",
                description: "Focus on rest and recovery",
                icon: "leaf.fill",
                color: .blue,
                healthTriggers: [.highStress, .poorSleep, .overexertion]
            )
        ]
    }
    
    private func setupHealthAwareFilters() {
        healthAwareFilters = [
            HealthAwareFilter(
                id: "stress_based",
                name: "Stress-Based Filtering",
                description: "Adjust notifications based on stress levels",
                isEnabled: true,
                conditions: [
                    .init(type: .stressLevel, threshold: .high, action: .reduceNotifications),
                    .init(type: .stressLevel, threshold: .severe, action: .blockAllExceptHealth)
                ]
            ),
            HealthAwareFilter(
                id: "sleep_based",
                name: "Sleep-Based Filtering",
                description: "Adjust notifications based on sleep quality",
                isEnabled: true,
                conditions: [
                    .init(type: .sleepQuality, threshold: .low, action: .reduceNotifications),
                    .init(type: .sleepTime, threshold: .bedtime, action: .blockAllExceptHealth)
                ]
            ),
            HealthAwareFilter(
                id: "cardiac_based",
                name: "Cardiac Health Filtering",
                description: "Prioritize notifications during cardiac events",
                isEnabled: true,
                conditions: [
                    .init(type: .afibStatus, threshold: .high, action: .prioritizeHealthNotifications),
                    .init(type: .heartRate, threshold: .abnormal, action: .emergencyMode)
                ]
            ),
            HealthAwareFilter(
                id: "respiratory_based",
                name: "Respiratory Health Filtering",
                description: "Adjust notifications based on breathing patterns",
                isEnabled: true,
                conditions: [
                    .init(type: .oxygenSaturation, threshold: .low, action: .prioritizeHealthNotifications),
                    .init(type: .respiratoryRate, threshold: .elevated, action: .reduceNonEssential)
                ]
            )
        ]
    }
    
    // MARK: - Focus Mode Management
    
    func activateFocusMode(_ focusMode: FocusMode) {
        Task {
            do {
                let intent = FocusModeIntent()
                intent.focusMode = focusMode.name
                intent.healthAware = true
                
                let result = try await focusCenter.requestAuthorization(for: .focusMode)
                if result {
                    try await focusCenter.activateFocusMode(focusMode.id)
                    currentFocusMode = focusMode
                    
                    // Apply health-aware filters
                    applyHealthAwareFilters(for: focusMode)
                    
                    // Send focus activation notification
                    sendFocusNotification(
                        title: "\(focusMode.name) Activated",
                        message: "Health-aware focus mode is now active",
                        type: .focusActivated
                    )
                }
            } catch {
                print("Failed to activate focus mode: \(error)")
            }
        }
    }
    
    func deactivateFocusMode() {
        Task {
            do {
                try await focusCenter.deactivateFocusMode()
                currentFocusMode = nil
                
                // Remove health-aware filters
                removeHealthAwareFilters()
                
                // Send focus deactivation notification
                sendFocusNotification(
                    title: "Focus Mode Deactivated",
                    message: "Health monitoring continues in background",
                    type: .focusDeactivated
                )
            } catch {
                print("Failed to deactivate focus mode: \(error)")
            }
        }
    }
    
    // MARK: - Health-Aware Filtering
    
    private func applyHealthAwareFilters(for focusMode: FocusMode) {
        for filter in healthAwareFilters where filter.isEnabled {
            for condition in filter.conditions {
                if focusMode.healthTriggers.contains(condition.type) {
                    applyFilterCondition(condition)
                }
            }
        }
    }
    
    private func applyFilterCondition(_ condition: FilterCondition) {
        switch condition.action {
        case .reduceNotifications:
            reduceNotificationFrequency()
        case .blockAllExceptHealth:
            blockNonHealthNotifications()
        case .prioritizeHealthNotifications:
            prioritizeHealthNotifications()
        case .emergencyMode:
            enableEmergencyMode()
        case .reduceNonEssential:
            reduceNonEssentialNotifications()
        }
    }
    
    private func removeHealthAwareFilters() {
        // Restore normal notification behavior
        restoreNormalNotifications()
    }
    
    // MARK: - Notification Management
    
    private func reduceNotificationFrequency() {
        // Implement notification frequency reduction
        print("Reducing notification frequency")
    }
    
    private func blockNonHealthNotifications() {
        // Block non-health notifications
        print("Blocking non-health notifications")
    }
    
    private func prioritizeHealthNotifications() {
        // Prioritize health-related notifications
        print("Prioritizing health notifications")
    }
    
    private func enableEmergencyMode() {
        // Enable emergency notification mode
        print("Enabling emergency mode")
    }
    
    private func reduceNonEssentialNotifications() {
        // Reduce non-essential notifications
        print("Reducing non-essential notifications")
    }
    
    private func restoreNormalNotifications() {
        // Restore normal notification behavior
        print("Restoring normal notifications")
    }
    
    // MARK: - Focus Change Observation
    
    private func observeFocusChanges() {
        NotificationCenter.default.addObserver(
            forName: .focusDidChange,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleFocusChange(notification)
        }
    }
    
    private func handleFocusChange(_ notification: Notification) {
        // Handle focus mode changes
        if let focusMode = notification.object as? FocusMode {
            currentFocusMode = focusMode
            applyHealthAwareFilters(for: focusMode)
        } else {
            currentFocusMode = nil
            removeHealthAwareFilters()
        }
    }
    
    // MARK: - Health-Based Focus Suggestions
    
    func suggestFocusMode() -> FocusMode? {
        let mentalHealthManager = MentalHealthManager.shared
        let sleepManager = SleepOptimizationManager.shared
        let cardiacManager = AdvancedCardiacManager.shared
        let respiratoryManager = RespiratoryHealthManager.shared
        
        // Check for high stress
        if mentalHealthManager.stressLevel == .high || mentalHealthManager.stressLevel == .severe {
            return availableFocusModes.first { $0.id == "mindfulness" }
        }
        
        // Check for poor sleep
        if sleepManager.sleepQuality < 0.6 {
            return availableFocusModes.first { $0.id == "sleep_preparation" }
        }
        
        // Check for cardiac alerts
        if cardiacManager.afibStatus == .high {
            return availableFocusModes.first { $0.id == "health_monitoring" }
        }
        
        // Check for low activity
        if HealthDataManager.shared.dailySteps < 5000 {
            return availableFocusModes.first { $0.id == "exercise" }
        }
        
        return nil
    }
    
    // MARK: - Notification Management
    
    private func sendFocusNotification(title: String, message: String, type: FocusNotificationType) {
        let notification = FocusNotification(
            id: UUID().uuidString,
            title: title,
            message: message,
            type: type,
            timestamp: Date()
        )
        
        focusNotifications.append(notification)
        
        // Send system notification
        Task {
            await sendSystemNotification(title: title, body: message)
        }
    }
    
    private func sendSystemNotification(title: String, body: String) async {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        
        do {
            try await UNUserNotificationCenter.current().add(request)
        } catch {
            print("Failed to send focus notification: \(error)")
        }
    }
}

// MARK: - Data Models

struct FocusMode: Identifiable, Codable {
    let id: String
    let name: String
    let description: String
    let icon: String
    let color: Color
    let healthTriggers: [HealthTrigger]
    
    enum HealthTrigger: String, Codable, CaseIterable {
        case highStress = "high_stress"
        case poorSleep = "poor_sleep"
        case cardiacAlert = "cardiac_alert"
        case mentalHealthDecline = "mental_health_decline"
        case sleepTime = "sleep_time"
        case sleepQuality = "sleep_quality"
        case lowActivity = "low_activity"
        case cardiacHealth = "cardiac_health"
        case overexertion = "overexertion"
    }
}

struct HealthAwareFilter: Identifiable, Codable {
    let id: String
    let name: String
    let description: String
    var isEnabled: Bool
    let conditions: [FilterCondition]
}

struct FilterCondition: Codable {
    let type: FocusMode.HealthTrigger
    let threshold: FilterThreshold
    let action: FilterAction
    
    enum FilterThreshold: String, Codable {
        case high = "high"
        case low = "low"
        case severe = "severe"
        case abnormal = "abnormal"
        case bedtime = "bedtime"
    }
    
    enum FilterAction: String, Codable {
        case reduceNotifications = "reduce_notifications"
        case blockAllExceptHealth = "block_all_except_health"
        case prioritizeHealthNotifications = "prioritize_health_notifications"
        case emergencyMode = "emergency_mode"
        case reduceNonEssential = "reduce_non_essential"
    }
}

struct FocusNotification: Identifiable, Codable {
    let id: String
    let title: String
    let message: String
    let type: FocusNotificationType
    let timestamp: Date
    
    enum FocusNotificationType: String, Codable {
        case focusActivated = "focus_activated"
        case focusDeactivated = "focus_deactivated"
        case healthAlert = "health_alert"
        case suggestion = "suggestion"
    }
}

// MARK: - Focus Mode Views

struct FocusModeView: View {
    @StateObject private var focusModeManager = FocusModeManager.shared
    @State private var showingFilterSettings = false
    @State private var showingSuggestions = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Current Focus Mode
                    if let currentMode = focusModeManager.currentFocusMode {
                        CurrentFocusModeCard(focusMode: currentMode) {
                            focusModeManager.deactivateFocusMode()
                        }
                    }
                    
                    // Available Focus Modes
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Available Focus Modes")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        LazyVStack(spacing: 12) {
                            ForEach(focusModeManager.availableFocusModes) { focusMode in
                                FocusModeCard(
                                    focusMode: focusMode,
                                    isActive: focusModeManager.currentFocusMode?.id == focusMode.id
                                ) {
                                    if focusModeManager.currentFocusMode?.id == focusMode.id {
                                        focusModeManager.deactivateFocusMode()
                                    } else {
                                        focusModeManager.activateFocusMode(focusMode)
                                    }
                                }
                            }
                        }
                    }
                    
                    // Health-Aware Filters
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Health-Aware Filters")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            Spacer()
                            
                            Button("Settings") {
                                showingFilterSettings = true
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                        
                        LazyVStack(spacing: 8) {
                            ForEach(focusModeManager.healthAwareFilters) { filter in
                                HealthAwareFilterRow(filter: filter)
                            }
                        }
                    }
                    
                    // Focus Suggestions
                    if let suggestion = focusModeManager.suggestFocusMode() {
                        FocusSuggestionCard(focusMode: suggestion) {
                            focusModeManager.activateFocusMode(suggestion)
                        }
                    }
                    
                    // Recent Notifications
                    if !focusModeManager.focusNotifications.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Recent Notifications")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            LazyVStack(spacing: 8) {
                                ForEach(focusModeManager.focusNotifications.prefix(5)) { notification in
                                    FocusNotificationRow(notification: notification)
                                }
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Focus Modes")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingFilterSettings) {
                FilterSettingsView()
            }
        }
    }
}

struct CurrentFocusModeCard: View {
    let focusMode: FocusMode
    let onDeactivate: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: focusMode.icon)
                    .font(.title2)
                    .foregroundColor(focusMode.color)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(focusMode.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text(focusMode.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button("Deactivate") {
                    onDeactivate()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            
            HStack {
                Text("Health Triggers:")
                    .font(.caption)
                    .fontWeight(.medium)
                
                ForEach(focusMode.healthTriggers, id: \.self) { trigger in
                    Text(trigger.displayName)
                        .font(.caption2)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(focusMode.color.opacity(0.2))
                        .foregroundColor(focusMode.color)
                        .cornerRadius(8)
                }
                
                Spacer()
            }
        }
        .padding()
        .background(focusMode.color.opacity(0.1))
        .cornerRadius(12)
    }
}

struct FocusModeCard: View {
    let focusMode: FocusMode
    let isActive: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Image(systemName: focusMode.icon)
                    .font(.title2)
                    .foregroundColor(isActive ? .white : focusMode.color)
                    .frame(width: 32)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(focusMode.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(isActive ? .white : .primary)
                    
                    Text(focusMode.description)
                        .font(.subheadline)
                        .foregroundColor(isActive ? .white.opacity(0.8) : .secondary)
                }
                
                Spacer()
                
                if isActive {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.white)
                        .font(.title3)
                }
            }
            .padding()
            .background(isActive ? focusMode.color : Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct HealthAwareFilterRow: View {
    let filter: HealthAwareFilter
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(filter.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(filter.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Toggle("", isOn: .constant(filter.isEnabled))
                .disabled(true)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

struct FocusSuggestionCard: View {
    let focusMode: FocusMode
    let onActivate: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
                
                Text("Suggested Focus Mode")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            HStack {
                Image(systemName: focusMode.icon)
                    .font(.title2)
                    .foregroundColor(focusMode.color)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(focusMode.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text("Based on your current health metrics")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button("Activate") {
                    onActivate()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
        }
        .padding()
        .background(Color.yellow.opacity(0.1))
        .cornerRadius(12)
    }
}

struct FocusNotificationRow: View {
    let notification: FocusNotification
    
    var body: some View {
        HStack {
            Image(systemName: notificationIcon)
                .foregroundColor(notificationColor)
                .font(.caption)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(notification.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(notification.message)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(notification.timestamp, style: .relative)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
    
    private var notificationIcon: String {
        switch notification.type {
        case .focusActivated: return "checkmark.circle.fill"
        case .focusDeactivated: return "xmark.circle.fill"
        case .healthAlert: return "exclamationmark.triangle.fill"
        case .suggestion: return "lightbulb.fill"
        }
    }
    
    private var notificationColor: Color {
        switch notification.type {
        case .focusActivated: return .green
        case .focusDeactivated: return .gray
        case .healthAlert: return .red
        case .suggestion: return .yellow
        }
    }
}

struct FilterSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var focusModeManager = FocusModeManager.shared
    
    var body: some View {
        NavigationView {
            List {
                ForEach(focusModeManager.healthAwareFilters) { filter in
                    Section(filter.name) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(filter.description)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            ForEach(filter.conditions, id: \.type) { condition in
                                HStack {
                                    Text(condition.type.displayName)
                                        .font(.caption)
                                    
                                    Spacer()
                                    
                                    Text(condition.action.displayName)
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Filter Settings")
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

extension FocusMode.HealthTrigger {
    var displayName: String {
        switch self {
        case .highStress: return "High Stress"
        case .poorSleep: return "Poor Sleep"
        case .cardiacAlert: return "Cardiac Alert"
        case .mentalHealthDecline: return "Mental Health"
        case .sleepTime: return "Sleep Time"
        case .sleepQuality: return "Sleep Quality"
        case .lowActivity: return "Low Activity"
        case .cardiacHealth: return "Cardiac Health"
        case .overexertion: return "Overexertion"
        }
    }
}

extension FilterCondition.FilterAction {
    var displayName: String {
        switch self {
        case .reduceNotifications: return "Reduce Notifications"
        case .blockAllExceptHealth: return "Block Non-Health"
        case .prioritizeHealthNotifications: return "Prioritize Health"
        case .emergencyMode: return "Emergency Mode"
        case .reduceNonEssential: return "Reduce Non-Essential"
        }
    }
}

// MARK: - Mock Focus Center

class FocusCenter {
    func requestAuthorization(for type: FocusModeIntent) async throws -> Bool {
        // Mock implementation
        return true
    }
    
    func activateFocusMode(_ id: String) async throws {
        // Mock implementation
        print("Activating focus mode: \(id)")
    }
    
    func deactivateFocusMode() async throws {
        // Mock implementation
        print("Deactivating focus mode")
    }
}

extension Notification.Name {
    static let focusDidChange = Notification.Name("focusDidChange")
} 
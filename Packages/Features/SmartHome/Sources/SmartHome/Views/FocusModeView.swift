import SwiftUI
import AppIntents
import UserNotifications

@available(iOS 17.0, *)
@available(macOS 14.0, *)

// MARK: - Focus Mode Manager

@MainActor
class FocusModeManager: ObservableObject {
    static let shared = FocusModeManager()
    
    @Published var availableFocusModes: [FocusMode] = []
    @Published var currentFocusMode: FocusMode?
    @Published var healthAwareFilters: [HealthAwareFilter] = []
    @Published var focusNotifications: [FocusNotification] = []
    
    private let focusCenter = FocusCenter() // This will be replaced by direct iOS Focus API calls
    
    private init() {
        setupFocusModes()
        setupHealthAwareFilters()
        observeFocusChanges()
    }
    
    // MARK: - Focus Mode Setup
    
    private func setupFocusModes() {
        // Define custom Focus Modes relevant to health
        availableFocusModes = [
            FocusMode(
                id: "health_monitoring",
                name: "Health Monitoring",
                description: "Optimized for continuous health data collection and critical alerts.",
                icon: "heart.fill",
                color: .red,
                healthTriggers: [.cardiacAlert, .highStress, .abnormalVitals]
            ),
            FocusMode(
                id: "sleep_optimization",
                name: "Sleep Optimization",
                description: "Minimizes disturbances for optimal sleep and recovery.",
                icon: "bed.double.fill",
                color: .indigo,
                healthTriggers: [.sleepTime, .poorSleepQuality]
            ),
            FocusMode(
                id: "mindfulness_meditation",
                name: "Mindfulness & Meditation",
                description: "Creates a calm environment for mental well-being practices.",
                icon: "brain.head.profile",
                color: .purple,
                healthTriggers: [.highStress, .mentalHealthDecline]
            ),
            FocusMode(
                id: "active_recovery",
                name: "Active Recovery",
                description: "Supports gentle activity and recovery without intense notifications.",
                icon: "figure.walk",
                color: .green,
                healthTriggers: [.overexertion, .muscleSoreness]
            )
        ]
    }
    
    private func setupHealthAwareFilters() {
        // Define health-aware filters that modify system behavior based on health data
        healthAwareFilters = [
            HealthAwareFilter(
                id: "critical_health_alert",
                name: "Critical Health Alert Filter",
                description: "Prioritizes and allows only critical health notifications.",
                isEnabled: true,
                conditions: [
                    .init(type: .cardiacAlert, threshold: .critical, action: .prioritizeHealthNotifications),
                    .init(type: .abnormalVitals, threshold: .critical, action: .prioritizeHealthNotifications)
                ]
            ),
            HealthAwareFilter(
                id: "sleep_disturbance_prevention",
                name: "Sleep Disturbance Prevention",
                description: "Blocks non-essential notifications during detected sleep.",
                isEnabled: true,
                conditions: [
                    .init(type: .sleepTime, threshold: .bedtime, action: .blockAllExceptHealth),
                    .init(type: .poorSleepQuality, threshold: .high, action: .reduceNotifications)
                ]
            ),
            HealthAwareFilter(
                id: "stress_reduction_filter",
                name: "Stress Reduction Filter",
                description: "Reduces notification interruptions during high stress.",
                isEnabled: true,
                conditions: [
                    .init(type: .highStress, threshold: .high, action: .reduceNotifications),
                    .init(type: .mentalHealthDecline, threshold: .high, action: .blockNonEssential)
                ]
            )
        ]
    }
    
    // MARK: - Focus Mode Management
    
    func activateFocusMode(_ focusMode: FocusMode) {
        Task {
            do {
                // Request authorization for notifications
                let center = UNUserNotificationCenter.current()
                let notificationSettings = await center.notificationSettings()
                if notificationSettings.authorizationStatus == .notDetermined {
                    let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
                    if !granted {
                        print("Notification authorization denied.")
                        return
                    }
                } else if notificationSettings.authorizationStatus == .denied {
                    print("Notification authorization previously denied. Please enable in settings.")
                    return
                }

                // Simulate activating a system-level Focus mode (requires actual iOS 18 Focus API)
                // For demonstration, we'll just set our internal state.
                currentFocusMode = focusMode
                print("Activated internal focus mode: \(focusMode.name)")
                
                // Apply health-aware filters
                applyHealthAwareFilters(for: focusMode)
                
                // Send focus activation notification
                sendFocusNotification(
                    title: "\(focusMode.name) Activated",
                    message: "Health-aware focus mode is now active.",
                    type: .focusActivated
                )
                
                // Register App Intent for Shortcuts integration
                AppIntents.AppIntent.registerAppIntent(FocusModeIntent.self)
                print("Registered FocusModeIntent for Shortcuts.")

            } catch {
                print("Failed to activate focus mode: \(error.localizedDescription)")
            }
        }
    }
    
    func deactivateFocusMode() {
        Task {
            do {
                // Simulate deactivating a system-level Focus mode
                currentFocusMode = nil
                print("Deactivated internal focus mode.")
                
                // Remove health-aware filters
                removeHealthAwareFilters()
                
                // Send focus deactivation notification
                sendFocusNotification(
                    title: "Focus Mode Deactivated",
                    message: "Health monitoring continues in background.",
                    type: .focusDeactivated
                )
            } catch {
                print("Failed to deactivate focus mode: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Health-Aware Filtering Implementation
    
    private func applyHealthAwareFilters(for focusMode: FocusMode) {
        print("Applying health-aware filters for \(focusMode.name) mode.")
        for filter in healthAwareFilters where filter.isEnabled {
            for condition in filter.conditions {
                if focusMode.healthTriggers.contains(condition.type) {
                    print("Applying filter condition: \(condition.type.displayName) -> \(condition.action.displayName)")
                    applyFilterCondition(condition)
                }
            }
        }
        // In a real scenario, this would interact with iOS 18's Focus Filter APIs
        // to modify app behavior (e.g., hide specific content, adjust notifications).
    }
    
    private func applyFilterCondition(_ condition: FilterCondition) {
        switch condition.action {
        case .reduceNotifications:
            // Example: Adjust notification settings to be less intrusive
            print("Action: Reducing notification frequency.")
        case .blockAllExceptHealth:
            // Example: Silence all notifications except those marked as critical health alerts
            print("Action: Blocking all non-health notifications.")
        case .prioritizeHealthNotifications:
            // Example: Ensure critical health notifications bypass silent settings
            print("Action: Prioritizing health notifications.")
        case .emergencyMode:
            // Example: Trigger a specific emergency protocol (e.g., loud alerts, contact emergency services)
            print("Action: Enabling emergency mode.")
        case .blockNonEssential:
            // Example: Block non-essential app notifications
            print("Action: Blocking non-essential notifications.")
        }
    }
    
    private func removeHealthAwareFilters() {
        print("Removing health-aware filters and restoring normal notification behavior.")
        // Restore normal notification behavior
    }
    
    // MARK: - Focus Change Observation (Simulated)
    
    private func observeFocusChanges() {
        // In a real iOS 18 app, you would observe changes to system Focus modes
        // using the new Focus API. For this mock, we'll use a NotificationCenter.
        NotificationCenter.default.addObserver(
            forName: .focusDidChange,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleFocusChange(notification)
        }
    }
    
    private func handleFocusChange(_ notification: Notification) {
        // This would be triggered by actual system Focus mode changes
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
        // This logic would integrate with actual health data managers
        // For demonstration, we'll use placeholder conditions.
        
        // Example: Suggest "Sleep Optimization" if it's late and sleep quality is poor
        if Calendar.current.component(.hour, from: Date()) > 22 && (currentFocusMode?.id != "sleep_optimization") {
            return availableFocusModes.first { $0.id == "sleep_optimization" }
        }
        
        // Example: Suggest "Health Monitoring" if a critical health alert is detected
        // (e.g., from a HealthKit observer or internal alert engine)
        // if HealthKitManager.shared.hasCriticalAlert { // Placeholder
        //     return availableFocusModes.first { $0.id == "health_monitoring" }
        // }
        
        return nil
    }
    
    // MARK: - Focus-Based Notifications
    
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
            print("Failed to send focus notification: \(error.localizedDescription)")
        }
    }
}

// MARK: - Data Models

// MARK: - Data Models

/// Represents a custom health-aware Focus Mode.
struct FocusMode: Identifiable, Codable {
    let id: String
    let name: String
    let description: String
    let icon: String // SF Symbols icon name
    let color: Color // Accent color for the focus mode
    let healthTriggers: [HealthTrigger] // Health conditions that might suggest this mode

    /// Defines various health conditions that can trigger or influence Focus Modes.
    enum HealthTrigger: String, Codable, CaseIterable {
        case highStress = "high_stress"
        case poorSleepQuality = "poor_sleep_quality"
        case cardiacAlert = "cardiac_alert"
        case mentalHealthDecline = "mental_health_decline"
        case sleepTime = "sleep_time" // e.g., within sleep window
        case lowActivity = "low_activity"
        case overexertion = "overexertion"
        case abnormalVitals = "abnormal_vitals" // General vital sign abnormalities
        case muscleSoreness = "muscle_soreness" // For recovery modes
    }
}

/// Defines a filter that adjusts app behavior based on health data.
struct HealthAwareFilter: Identifiable, Codable {
    let id: String
    let name: String
    let description: String
    var isEnabled: Bool
    let conditions: [FilterCondition]
}

/// A specific condition within a health-aware filter.
struct FilterCondition: Codable {
    let type: FocusMode.HealthTrigger
    let threshold: FilterThreshold
    let action: FilterAction

    /// Defines thresholds for health conditions.
    enum FilterThreshold: String, Codable {
        case high = "high"
        case low = "low"
        case critical = "critical"
        case abnormal = "abnormal"
        case bedtime = "bedtime"
    }

    /// Defines actions to take when a filter condition is met.
    enum FilterAction: String, Codable {
        case reduceNotifications = "reduce_notifications" // Make notifications less intrusive
        case blockAllExceptHealth = "block_all_except_health" // Silence all but critical health alerts
        case prioritizeHealthNotifications = "prioritize_health_notifications" // Ensure health alerts break through
        case emergencyMode = "emergency_mode" // Activate emergency protocols
        case blockNonEssential = "block_non_essential" // Block non-essential app notifications
    }
}

/// Represents a notification related to Focus Mode activation, deactivation, or health alerts.
struct FocusNotification: Identifiable, Codable {
    let id: String
    let title: String
    let message: String
    let type: FocusNotificationType
    let timestamp: Date

    /// Types of focus-based notifications.
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
        case .poorSleepQuality: return "Poor Sleep Quality"
        case .cardiacAlert: return "Cardiac Alert"
        case .mentalHealthDecline: return "Mental Health Decline"
        case .sleepTime: return "Sleep Time"
        case .lowActivity: return "Low Activity"
        case .overexertion: return "Overexertion"
        case .abnormalVitals: return "Abnormal Vitals"
        case .muscleSoreness: return "Muscle Soreness"
        }
    }
}

extension FilterCondition.FilterAction {
    var displayName: String {
        switch self {
        case .reduceNotifications: return "Reduce Notifications"
        case .blockAllExceptHealth: return "Block All Except Health"
        case .prioritizeHealthNotifications: return "Prioritize Health Notifications"
        case .emergencyMode: return "Emergency Mode"
        case .blockNonEssential: return "Block Non-Essential"
        }
    }
}

// MARK: - Mock/Placeholder for iOS 18 Focus API Integration

// In a real iOS 18 environment, this would interact with the new Focus APIs
// to read and set system-wide Focus modes and apply Focus Filters.
// For this example, we simulate the behavior.
class FocusCenter {
    // Placeholder for requesting authorization for Focus API access
    func requestAuthorization() async throws -> Bool {
        print("Requesting Focus API authorization (mock).")
        // In a real app, this would involve requesting permission from the user
        // to access and modify Focus modes.
        return true // Assume granted for mock
    }
    
    // Placeholder for activating a system Focus mode
    func activateFocusMode(_ id: String) async throws {
        print("Activating system Focus mode: \(id) (mock).")
        // This would use the actual iOS 18 API to change the system Focus mode.
    }
    
    // Placeholder for deactivating the current system Focus mode
    func deactivateFocusMode() async throws {
        print("Deactivating system Focus mode (mock).")
        // This would use the actual iOS 18 API to deactivate the current Focus mode.
    }
}

extension Notification.Name {
    static let focusDidChange = Notification.Name("com.healthai2030.focusDidChange")
}
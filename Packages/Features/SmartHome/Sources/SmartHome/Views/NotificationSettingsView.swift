import SwiftUI
import UserNotifications

/// Comprehensive notification settings view for HealthAI 2030
/// Allows users to customize notification preferences, schedules, and privacy controls
@available(iOS 17.0, macOS 14.0, watchOS 10.0, tvOS 17.0, *)
struct NotificationSettingsView: View {
    @StateObject private var notificationManager = NotificationManager.shared
    @State private var showingAuthorizationAlert = false
    @State private var showingQuietHoursPicker = false
    @State private var tempQuietHoursStart = TimeOfDay(hour: 22, minute: 0)
    @State private var tempQuietHoursEnd = TimeOfDay(hour: 7, minute: 0)
    
    var body: some View {
        NavigationView {
            List {
                // Authorization Status
                authorizationSection
                
                // Notification Types
                notificationTypesSection
                
                // Reminder Settings
                reminderSettingsSection
                
                // Quiet Hours
                quietHoursSection
                
                // Advanced Settings
                advancedSettingsSection
                
                // Notification History
                notificationHistorySection
            }
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveSettings()
                    }
                    .disabled(!notificationManager.isAuthorized)
                }
            }
            .alert("Notification Permissions", isPresented: $showingAuthorizationAlert) {
                Button("Request Permissions") {
                    requestAuthorization()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Notification permissions are required to send health alerts and reminders. Please enable notifications in Settings.")
            }
            .sheet(isPresented: $showingQuietHoursPicker) {
                QuietHoursPickerView(
                    startTime: $tempQuietHoursStart,
                    endTime: $tempQuietHoursEnd
                )
            }
            .onAppear {
                loadCurrentSettings()
            }
        }
    }
    
    // MARK: - Authorization Section
    
    private var authorizationSection: some View {
        Section {
            HStack {
                Image(systemName: notificationManager.isAuthorized ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(notificationManager.isAuthorized ? .green : .red)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Notification Permissions")
                        .font(.headline)
                    
                    Text(notificationManager.isAuthorized ? "Notifications enabled" : "Notifications disabled")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if !notificationManager.isAuthorized {
                    Button("Enable") {
                        showingAuthorizationAlert = true
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding(.vertical, 4)
        } header: {
            Text("Status")
        } footer: {
            Text("HealthAI 2030 needs notification permissions to send health alerts, reminders, and updates.")
        }
    }
    
    // MARK: - Notification Types Section
    
    private var notificationTypesSection: some View {
        Section {
            NotificationTypeRow(
                title: "Health Alerts",
                description: "Critical and urgent health notifications",
                icon: "heart.fill",
                color: .red,
                isEnabled: $notificationManager.notificationSettings.healthAlertsEnabled
            )
            
            NotificationTypeRow(
                title: "Reminders",
                description: "Medication, exercise, and health check reminders",
                icon: "bell.fill",
                color: .blue,
                isEnabled: $notificationManager.notificationSettings.remindersEnabled
            )
            
            NotificationTypeRow(
                title: "Achievements",
                description: "Goal completions and milestone celebrations",
                icon: "trophy.fill",
                color: .orange,
                isEnabled: $notificationManager.notificationSettings.achievementsEnabled
            )
            
            NotificationTypeRow(
                title: "Weekly Reports",
                description: "Weekly health summary and insights",
                icon: "chart.bar.fill",
                color: .purple,
                isEnabled: $notificationManager.notificationSettings.weeklyReportsEnabled
            )
            
            NotificationTypeRow(
                title: "Sleep Tracking",
                description: "Sleep tracking reminders and insights",
                icon: "bed.double.fill",
                color: .indigo,
                isEnabled: $notificationManager.notificationSettings.sleepTrackingEnabled
            )
            
            NotificationTypeRow(
                title: "Medication Reminders",
                description: "Medication schedule and dosage reminders",
                icon: "pill.fill",
                color: .green,
                isEnabled: $notificationManager.notificationSettings.medicationRemindersEnabled
            )
        } header: {
            Text("Notification Types")
        } footer: {
            Text("Choose which types of notifications you'd like to receive. Critical health alerts are always enabled for safety.")
        }
    }
    
    // MARK: - Reminder Settings Section
    
    private var reminderSettingsSection: some View {
        Section {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Daily Notification Limit")
                        .font(.headline)
                    
                    Text("Maximum notifications per day")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Stepper(
                    value: $notificationManager.notificationSettings.maxNotificationsPerDay,
                    in: 5...50,
                    step: 5
                ) {
                    Text("\(notificationManager.notificationSettings.maxNotificationsPerDay)")
                        .font(.headline)
                        .foregroundColor(.blue)
                }
            }
            
            Toggle("Sound Notifications", isOn: $notificationManager.notificationSettings.soundEnabled)
            
            Toggle("Vibration", isOn: $notificationManager.notificationSettings.vibrationEnabled)
        } header: {
            Text("Reminder Settings")
        } footer: {
            Text("Configure how many notifications you want to receive daily and your preferred notification style.")
        }
    }
    
    // MARK: - Quiet Hours Section
    
    private var quietHoursSection: some View {
        Section {
            Toggle("Enable Quiet Hours", isOn: Binding(
                get: { notificationManager.notificationSettings.quietHours != nil },
                set: { enabled in
                    if enabled {
                        notificationManager.notificationSettings.quietHours = QuietHours(
                            start: tempQuietHoursStart,
                            end: tempQuietHoursEnd
                        )
                    } else {
                        notificationManager.notificationSettings.quietHours = nil
                    }
                }
            ))
            
            if notificationManager.notificationSettings.quietHours != nil {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Quiet Hours")
                            .font(.headline)
                        
                        if let quietHours = notificationManager.notificationSettings.quietHours {
                            Text("\(formatTime(quietHours.start)) - \(formatTime(quietHours.end))")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    Button("Edit") {
                        if let quietHours = notificationManager.notificationSettings.quietHours {
                            tempQuietHoursStart = quietHours.start
                            tempQuietHoursEnd = quietHours.end
                        }
                        showingQuietHoursPicker = true
                    }
                    .buttonStyle(.bordered)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Exceptions")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text("• Critical health alerts")
                    Text("• Medication reminders")
                    Text("• Emergency notifications")
                }
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.leading, 8)
            }
        } header: {
            Text("Quiet Hours")
        } footer: {
            Text("During quiet hours, most notifications will be suppressed. Critical health alerts and medication reminders will still be delivered.")
        }
    }
    
    // MARK: - Advanced Settings Section
    
    private var advancedSettingsSection: some View {
        Section {
            NavigationLink("Notification Categories") {
                NotificationCategoriesView()
            }
            
            NavigationLink("Focus Mode Integration") {
                FocusModeIntegrationView()
            }
            
            NavigationLink("Emergency Contacts") {
                EmergencyContactsView()
            }
        } header: {
            Text("Advanced")
        } footer: {
            Text("Configure advanced notification settings and integrations.")
        }
    }
    
    // MARK: - Notification History Section
    
    private var notificationHistorySection: some View {
        Section {
            if notificationManager.notificationHistory.isEmpty {
                HStack {
                    Image(systemName: "bell.slash")
                        .foregroundColor(.secondary)
                    
                    Text("No notifications sent yet")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 20)
            } else {
                ForEach(notificationManager.notificationHistory.prefix(5)) { record in
                    NotificationHistoryRow(record: record)
                }
                
                if notificationManager.notificationHistory.count > 5 {
                    NavigationLink("View All (\(notificationManager.notificationHistory.count))") {
                        NotificationHistoryView()
                    }
                }
            }
        } header: {
            Text("Recent Notifications")
        } footer: {
            Text("Recent notifications sent by HealthAI 2030.")
        }
    }
    
    // MARK: - Helper Methods
    
    private func requestAuthorization() {
        Task {
            do {
                try await notificationManager.requestAuthorization()
            } catch {
                print("Failed to request authorization: \(error)")
            }
        }
    }
    
    private func loadCurrentSettings() {
        // Settings are loaded automatically by NotificationManager
    }
    
    private func saveSettings() {
        notificationManager.updateSettings(notificationManager.notificationSettings)
    }
    
    private func formatTime(_ time: TimeOfDay) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        
        let calendar = Calendar.current
        let date = calendar.date(bySettingHour: time.hour, minute: time.minute, second: 0, of: Date()) ?? Date()
        
        return formatter.string(from: date)
    }
}

// MARK: - Supporting Views

@available(iOS 17.0, macOS 14.0, watchOS 10.0, tvOS 17.0, *)
struct NotificationTypeRow: View {
    let title: String
    let description: String
    let icon: String
    let color: Color
    @Binding var isEnabled: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 32, height: 32)
                .background(color.opacity(0.1))
                .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Toggle("", isOn: $isEnabled)
                .toggleStyle(SwitchToggleStyle(tint: color))
        }
        .padding(.vertical, 4)
    }
}

@available(iOS 17.0, macOS 14.0, watchOS 10.0, tvOS 17.0, *)
struct NotificationHistoryRow: View {
    let record: NotificationRecord
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: iconForType(record.type))
                    .foregroundColor(colorForSeverity(record.severity))
                
                Text(record.title)
                    .font(.headline)
                
                Spacer()
                
                Text(formatDate(record.timestamp))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(record.body)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(2)
        }
        .padding(.vertical, 4)
    }
    
    private func iconForType(_ type: NotificationType) -> String {
        switch type {
        case .healthAlert: return "heart.fill"
        case .reminder: return "bell.fill"
        case .achievement: return "trophy.fill"
        case .weeklyReport: return "chart.bar.fill"
        case .sleepTracking: return "bed.double.fill"
        case .medicationReminder: return "pill.fill"
        }
    }
    
    private func colorForSeverity(_ severity: HealthAlertSeverity) -> Color {
        switch severity {
        case .critical: return .red
        case .urgent: return .orange
        case .normal: return .blue
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

@available(iOS 17.0, macOS 14.0, watchOS 10.0, tvOS 17.0, *)
struct QuietHoursPickerView: View {
    @Binding var startTime: TimeOfDay
    @Binding var endTime: TimeOfDay
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Text("Set Quiet Hours")
                    .font(.title)
                    .fontWeight(.bold)
                
                VStack(spacing: 20) {
                    TimePickerRow(
                        title: "Start Time",
                        time: $startTime
                    )
                    
                    TimePickerRow(
                        title: "End Time",
                        time: $endTime
                    )
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("During quiet hours:")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("• Most notifications will be suppressed")
                        Text("• Critical health alerts will still be delivered")
                        Text("• Medication reminders will still be delivered")
                        Text("• Emergency notifications will still be delivered")
                    }
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
                
                Spacer()
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        dismiss()
                    }
                }
            }
        }
    }
}

@available(iOS 17.0, macOS 14.0, watchOS 10.0, tvOS 17.0, *)
struct TimePickerRow: View {
    let title: String
    @Binding var time: TimeOfDay
    
    var body: some View {
        HStack {
            Text(title)
                .font(.headline)
            
            Spacer()
            
            DatePicker(
                "",
                selection: Binding(
                    get: {
                        Calendar.current.date(bySettingHour: time.hour, minute: time.minute, second: 0, of: Date()) ?? Date()
                    },
                    set: { date in
                        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
                        time = TimeOfDay(hour: components.hour ?? 0, minute: components.minute ?? 0)
                    }
                ),
                displayedComponents: .hourAndMinute
            )
            .labelsHidden()
        }
    }
}

// MARK: - Placeholder Views

@available(iOS 17.0, macOS 14.0, watchOS 10.0, tvOS 17.0, *)
struct NotificationCategoriesView: View {
    var body: some View {
        Text("Notification Categories")
            .navigationTitle("Categories")
    }
}

@available(iOS 17.0, macOS 14.0, watchOS 10.0, tvOS 17.0, *)
struct FocusModeIntegrationView: View {
    var body: some View {
        Text("Focus Mode Integration")
            .navigationTitle("Focus Mode")
    }
}

@available(iOS 17.0, macOS 14.0, watchOS 10.0, tvOS 17.0, *)
struct EmergencyContactsView: View {
    var body: some View {
        Text("Emergency Contacts")
            .navigationTitle("Emergency Contacts")
    }
}

@available(iOS 17.0, macOS 14.0, watchOS 10.0, tvOS 17.0, *)
struct NotificationHistoryView: View {
    @StateObject private var notificationManager = NotificationManager.shared
    
    var body: some View {
        List(notificationManager.notificationHistory) { record in
            NotificationHistoryRow(record: record)
        }
        .navigationTitle("Notification History")
    }
}

// MARK: - Preview

@available(iOS 17.0, macOS 14.0, watchOS 10.0, tvOS 17.0, *)
struct NotificationSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NotificationSettingsView()
    }
} 
import SwiftUI
import CoreLocation

/// Emergency Alerts View
/// Provides comprehensive interface for monitoring and managing emergency alerts, contacts, and response protocols
struct EmergencyAlertsView: View {
    // MARK: - Environment Objects
    @EnvironmentObject var emergencyAlertManager: EmergencyAlertManager
    
    // MARK: - State Properties
    @State private var selectedTab = 0
    @State private var showingAddContact = false
    @State private var showingAlertDetails = false
    @State private var selectedAlert: EmergencyAlert?
    @State private var showingSettings = false
    @State private var isMonitoringEnabled = false
    @State private var refreshTimer: Timer?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Emergency status header
                emergencyStatusHeader
                
                // Tab selector
                tabSelector
                
                // Tab content
                TabView(selection: $selectedTab) {
                    activeAlertsTab
                        .tag(0)
                    
                    alertHistoryTab
                        .tag(1)
                    
                    emergencyContactsTab
                        .tag(2)
                    
                    emergencySettingsTab
                        .tag(3)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .navigationTitle("Emergency Alerts")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    emergencySettingsButton
                }
            }
        }
        .onAppear {
            startMonitoring()
        }
        .onDisappear {
            stopMonitoring()
        }
        .sheet(isPresented: $showingAddContact) {
            AddEmergencyContactView()
        }
        .sheet(isPresented: $showingAlertDetails) {
            if let alert = selectedAlert {
                EmergencyAlertDetailView(alert: alert)
            }
        }
        .sheet(isPresented: $showingSettings) {
            EmergencySettingsView()
        }
    }
    
    // MARK: - Header Views
    
    private var emergencyStatusHeader: some View {
        VStack(spacing: 16) {
            // Current emergency status
            VStack(spacing: 8) {
                HStack {
                    Text("Emergency Status")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Spacer()
                    StatusIndicator(status: emergencyAlertManager.currentAlertStatus)
                }
                
                // Status details
                HStack(spacing: 16) {
                    StatusMetricView(
                        title: "Active Alerts",
                        value: "\(emergencyAlertManager.activeAlerts.count)",
                        color: emergencyAlertManager.activeAlerts.isEmpty ? .green : .red
                    )
                    
                    StatusMetricView(
                        title: "Monitoring",
                        value: emergencyAlertManager.isMonitoring ? "Active" : "Inactive",
                        color: emergencyAlertManager.isMonitoring ? .green : .orange
                    )
                    
                    StatusMetricView(
                        title: "Contacts",
                        value: "\(emergencyAlertManager.emergencyContacts.count)",
                        color: emergencyAlertManager.emergencyContacts.isEmpty ? .red : .blue
                    )
                    
                    Spacer()
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
            
            // Quick actions
            HStack(spacing: 12) {
                Button(action: toggleMonitoring) {
                    HStack {
                        Image(systemName: emergencyAlertManager.isMonitoring ? "pause.fill" : "play.fill")
                        Text(emergencyAlertManager.isMonitoring ? "Stop Monitoring" : "Start Monitoring")
                    }
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(emergencyAlertManager.isMonitoring ? Color.orange : Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                
                Button(action: triggerTestAlert) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                        Text("Test Alert")
                    }
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                
                Spacer()
            }
            .padding(.horizontal)
        }
        .padding()
        .background(Color(.systemGroupedBackground))
    }
    
    private var tabSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(0..<4) { index in
                    Button(action: { selectedTab = index }) {
                        VStack(spacing: 4) {
                            Text(tabTitle(for: index))
                                .font(.caption)
                                .fontWeight(selectedTab == index ? .semibold : .regular)
                                .foregroundColor(selectedTab == index ? .primary : .secondary)
                            
                            Rectangle()
                                .fill(selectedTab == index ? Color.blue : Color.clear)
                                .frame(height: 2)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                    }
                }
            }
            .padding(.horizontal)
        }
        .background(Color(.systemBackground))
    }
    
    // MARK: - Tab Content Views
    
    private var activeAlertsTab: some View {
        ScrollView {
            VStack(spacing: 16) {
                if emergencyAlertManager.activeAlerts.isEmpty {
                    EmptyStateView(
                        icon: "checkmark.circle.fill",
                        title: "No Active Alerts",
                        description: "All systems are operating normally. No emergency alerts are currently active.",
                        color: .green
                    )
                } else {
                    ForEach(emergencyAlertManager.activeAlerts, id: \.id) { alert in
                        EmergencyAlertCard(
                            alert: alert,
                            onAcknowledge: {
                                emergencyAlertManager.acknowledgeAlert(alert.id)
                            },
                            onResolve: { resolution in
                                emergencyAlertManager.resolveAlert(alert.id, resolution: resolution)
                            },
                            onTap: {
                                selectedAlert = alert
                                showingAlertDetails = true
                            }
                        )
                    }
                }
            }
            .padding()
        }
    }
    
    private var alertHistoryTab: some View {
        ScrollView {
            VStack(spacing: 16) {
                if emergencyAlertManager.alertHistory.isEmpty {
                    EmptyStateView(
                        icon: "clock.fill",
                        title: "No Alert History",
                        description: "No emergency alerts have been recorded yet.",
                        color: .gray
                    )
                } else {
                    ForEach(emergencyAlertManager.alertHistory.prefix(20), id: \.id) { alert in
                        EmergencyAlertHistoryCard(alert: alert)
                    }
                }
            }
            .padding()
        }
    }
    
    private var emergencyContactsTab: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Add contact button
                Button(action: { showingAddContact = true }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Add Emergency Contact")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
                }
                
                if emergencyAlertManager.emergencyContacts.isEmpty {
                    EmptyStateView(
                        icon: "person.crop.circle.badge.plus",
                        title: "No Emergency Contacts",
                        description: "Add emergency contacts to receive notifications during emergencies.",
                        color: .orange
                    )
                } else {
                    ForEach(emergencyAlertManager.emergencyContacts, id: \.id) { contact in
                        EmergencyContactCard(
                            contact: contact,
                            onEdit: {
                                // Handle edit contact
                            },
                            onDelete: {
                                emergencyAlertManager.removeEmergencyContact(contact.id)
                            }
                        )
                    }
                }
            }
            .padding()
        }
    }
    
    private var emergencySettingsTab: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Health thresholds
                HealthThresholdsCard(
                    thresholds: emergencyAlertManager.getHealthThresholds(),
                    onUpdate: { newThresholds in
                        emergencyAlertManager.setHealthThresholds(newThresholds)
                    }
                )
                
                // Monitoring settings
                MonitoringSettingsCard(
                    isMonitoring: emergencyAlertManager.isMonitoring,
                    onToggle: toggleMonitoring
                )
                
                // Response settings
                ResponseSettingsCard()
                
                // Test emergency system
                TestEmergencySystemCard(
                    onTest: triggerTestAlert
                )
            }
            .padding()
        }
    }
    
    // MARK: - Toolbar Views
    
    private var emergencySettingsButton: some View {
        Button(action: { showingSettings = true }) {
            Image(systemName: "gearshape.fill")
                .foregroundColor(.blue)
        }
    }
    
    // MARK: - Helper Methods
    
    private func tabTitle(for index: Int) -> String {
        switch index {
        case 0: return "Active Alerts"
        case 1: return "History"
        case 2: return "Contacts"
        case 3: return "Settings"
        default: return ""
        }
    }
    
    private func startMonitoring() {
        if !emergencyAlertManager.isMonitoring {
            emergencyAlertManager.startMonitoring()
        }
        
        // Start refresh timer
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
            // Trigger UI updates
        }
    }
    
    private func stopMonitoring() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }
    
    private func toggleMonitoring() {
        if emergencyAlertManager.isMonitoring {
            emergencyAlertManager.stopMonitoring()
        } else {
            emergencyAlertManager.startMonitoring()
        }
    }
    
    private func triggerTestAlert() {
        emergencyAlertManager.triggerManualAlert(
            type: .other,
            description: "This is a test emergency alert to verify the system is working correctly."
        )
    }
}

// MARK: - Supporting Views

struct StatusIndicator: View {
    let status: EmergencyStatus
    
    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(status.color)
                .frame(width: 12, height: 12)
            
            Text(status.rawValue)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(status.color)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(status.color.opacity(0.1))
        .cornerRadius(8)
    }
}

struct StatusMetricView: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
    }
}

struct EmergencyAlertCard: View {
    let alert: EmergencyAlert
    let onAcknowledge: () -> Void
    let onResolve: (String) -> Void
    let onTap: () -> Void
    
    @State private var showingResolveSheet = false
    @State private var resolutionText = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Alert header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(alert.type.rawValue)
                        .font(.headline)
                        .foregroundColor(alert.severity.color)
                    
                    Text(alert.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    SeverityBadge(severity: alert.severity)
                    
                    Text(alert.timestamp, style: .time)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Alert status
            HStack {
                if alert.isAcknowledged {
                    Label("Acknowledged", systemImage: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(.green)
                }
                
                if alert.isResolved {
                    Label("Resolved", systemImage: "checkmark.shield.fill")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                
                Spacer()
            }
            
            // Action buttons
            if !alert.isResolved {
                HStack(spacing: 12) {
                    if !alert.isAcknowledged {
                        Button("Acknowledge") {
                            onAcknowledge()
                        }
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(6)
                    }
                    
                    Button("Resolve") {
                        showingResolveSheet = true
                    }
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(6)
                    
                    Spacer()
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        .onTapGesture {
            onTap()
        }
        .sheet(isPresented: $showingResolveSheet) {
            ResolveAlertSheet(
                resolutionText: $resolutionText,
                onResolve: {
                    onResolve(resolutionText)
                    showingResolveSheet = false
                }
            )
        }
    }
}

struct EmergencyAlertHistoryCard: View {
    let alert: EmergencyAlert
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(alert.type.rawValue)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Text(alert.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    SeverityBadge(severity: alert.severity)
                    
                    Text(alert.timestamp, style: .date)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            if let resolution = alert.resolution {
                Text("Resolution: \(resolution)")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

struct EmergencyContactCard: View {
    let contact: EmergencyContact
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    @State private var showingDeleteAlert = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(contact.name)
                        .font(.headline)
                    
                    Text(contact.relationship)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                PriorityBadge(priority: contact.priority)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Label(contact.phoneNumber, systemImage: "phone.fill")
                    .font(.caption)
                
                if let email = contact.email {
                    Label(email, systemImage: "envelope.fill")
                        .font(.caption)
                }
            }
            
            HStack {
                Button("Edit") {
                    onEdit()
                }
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(6)
                
                Button("Delete") {
                    showingDeleteAlert = true
                }
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.red)
                .foregroundColor(.white)
                .cornerRadius(6)
                
                Spacer()
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        .alert("Delete Contact", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                onDelete()
            }
        } message: {
            Text("Are you sure you want to delete this emergency contact?")
        }
    }
}

struct EmptyStateView: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(color)
            
            VStack(spacing: 8) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .dynamicTypeSize(.xSmall ... .accessibility4)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

struct SeverityBadge: View {
    let severity: AlertSeverity
    
    var body: some View {
        Text(severity.rawValue)
            .font(.caption2)
            .fontWeight(.semibold)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(severity.color.opacity(0.2))
            .foregroundColor(severity.color)
            .cornerRadius(4)
    }
}

struct PriorityBadge: View {
    let priority: ContactPriority
    
    var body: some View {
        Text(priority.rawValue)
            .font(.caption2)
            .fontWeight(.semibold)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(priority.color.opacity(0.2))
            .foregroundColor(priority.color)
            .cornerRadius(4)
    }
}

struct ResolveAlertSheet: View {
    @Binding var resolutionText: String
    let onResolve: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                Text("Resolve Emergency Alert")
                    .font(.headline)
                
                Text("Please provide a brief description of how this emergency was resolved:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                TextEditor(text: $resolutionText)
                    .frame(height: 100)
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Resolve Alert")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Resolve") {
                        onResolve()
                    }
                    .disabled(resolutionText.isEmpty)
                }
            }
        }
    }
}

// MARK: - Placeholder Views

struct HealthThresholdsCard: View {
    let thresholds: HealthThresholds
    let onUpdate: (HealthThresholds) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Health Thresholds")
                .font(.headline)
            
            VStack(spacing: 8) {
                ThresholdRow(title: "Max Heart Rate", value: "\(Int(thresholds.maxHeartRate)) BPM")
                ThresholdRow(title: "Min Heart Rate", value: "\(Int(thresholds.minHeartRate)) BPM")
                ThresholdRow(title: "Max Systolic BP", value: "\(Int(thresholds.maxSystolicBloodPressure)) mmHg")
                ThresholdRow(title: "Max Diastolic BP", value: "\(Int(thresholds.maxDiastolicBloodPressure)) mmHg")
                ThresholdRow(title: "Min Oxygen Saturation", value: "\(Int(thresholds.minOxygenSaturation))%")
                ThresholdRow(title: "Max Temperature", value: "\(thresholds.maxTemperature)°C")
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

struct ThresholdRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.blue)
        }
    }
}

struct MonitoringSettingsCard: View {
    let isMonitoring: Bool
    let onToggle: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Monitoring Settings")
                .font(.headline)
            
            Toggle("Emergency Monitoring", isOn: .constant(isMonitoring))
                .onChange(of: isMonitoring) { _ in
                    onToggle()
                }
            
            Text("When enabled, the system will continuously monitor your health data for potential emergencies.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

struct ResponseSettingsCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Response Settings")
                .font(.headline)
            
            Text("Emergency response settings will be configured here.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

struct TestEmergencySystemCard: View {
    let onTest: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Test Emergency System")
                .font(.headline)
            
            Text("Test the emergency alert system to ensure it's working correctly.")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Button("Run Test") {
                onTest()
            }
            .font(.subheadline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.orange)
            .cornerRadius(8)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Placeholder Views for Sheets

struct AddEmergencyContactView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Add Emergency Contact")
                    .font(.headline)
                    .padding()
                
                Spacer()
                
                Text("Emergency contact form will be implemented here.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()
                
                Spacer()
            }
            .navigationTitle("Add Contact")
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

struct EmergencyAlertDetailView: View {
    let alert: EmergencyAlert
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Emergency Alert Details")
                    .font(.headline)
                    .padding()
                
                Spacer()
                
                Text("Detailed alert information will be displayed here.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()
                
                Spacer()
            }
            .navigationTitle("Alert Details")
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

struct EmergencySettingsView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Emergency Settings")
                    .font(.headline)
                    .padding()
                
                Spacer()
                
                Text("Emergency system settings will be configured here.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()
                
                Spacer()
            }
            .navigationTitle("Emergency Settings")
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

extension EmergencyStatus {
    var color: Color {
        switch self {
        case .normal: return .green
        case .warning: return .orange
        case .acknowledged: return .blue
        case .critical: return .red
        }
    }
}

extension AlertSeverity {
    var color: Color {
        switch self {
        case .low: return .green
        case .warning: return .orange
        case .critical: return .red
        }
    }
}

extension ContactPriority {
    var color: Color {
        switch self {
        case .primary: return .red
        case .secondary: return .orange
        case .tertiary: return .blue
        }
    }
} 
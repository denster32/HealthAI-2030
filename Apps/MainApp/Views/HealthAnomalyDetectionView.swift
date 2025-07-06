import SwiftUI
import HealthKit
import CoreML

struct HealthAnomalyDetectionView: View {
    @StateObject private var anomalyManager = HealthAnomalyDetectionManager()
    @State private var selectedTimeRange: TimeRange = .day
    @State private var showingEmergencyContacts = false
    @State private var showingSettings = false
    @State private var selectedAlert: HealthAlert?
    
    enum TimeRange: String, CaseIterable {
        case day = "24 Hours"
        case week = "7 Days"
        case month = "30 Days"
        case quarter = "90 Days"
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header with status
                    headerSection
                    
                    // Real-time alerts
                    alertsSection
                    
                    // Health metrics overview
                    metricsOverviewSection
                    
                    // Trend analysis
                    trendAnalysisSection
                    
                    // Emergency contacts
                    emergencyContactsSection
                    
                    // Settings and configuration
                    settingsSection
                }
                .padding()
            }
            .navigationTitle("Health Anomaly Detection")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Settings") {
                        showingSettings = true
                    }
                }
            }
        }
        .sheet(isPresented: $showingEmergencyContacts) {
            EmergencyContactsView(anomalyManager: anomalyManager)
        }
        .sheet(isPresented: $showingSettings) {
            AnomalyDetectionSettingsView(anomalyManager: anomalyManager)
        }
        .sheet(item: $selectedAlert) { alert in
            AlertDetailView(alert: alert, anomalyManager: anomalyManager)
        }
        .onAppear {
            anomalyManager.startMonitoring()
        }
        .onDisappear {
            anomalyManager.stopMonitoring()
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Health Status")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text(anomalyManager.overallHealthStatus)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(anomalyManager.overallHealthColor)
                }
                
                Spacer()
                
                // Status indicator
                Circle()
                    .fill(anomalyManager.overallHealthColor)
                    .frame(width: 20, height: 20)
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 2)
                    )
            }
            
            // Last updated
            HStack {
                Image(systemName: "clock")
                    .foregroundColor(.secondary)
                Text("Last updated: \(anomalyManager.lastUpdateTime, style: .relative)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Alerts Section
    private var alertsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Alerts")
                    .font(.headline)
                Spacer()
                Button("View All") {
                    // Navigate to full alerts view
                }
                .font(.caption)
            }
            
            if anomalyManager.recentAlerts.isEmpty {
                Text("No recent alerts")
                    .foregroundColor(.secondary)
                    .italic()
            } else {
                ForEach(anomalyManager.recentAlerts.prefix(3)) { alert in
                    AlertRowView(alert: alert) {
                        selectedAlert = alert
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Metrics Overview Section
    private var metricsOverviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Health Metrics")
                .font(.headline)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                MetricCardView(
                    title: "Heart Rate",
                    value: "\(anomalyManager.currentHeartRate) bpm",
                    status: anomalyManager.heartRateStatus,
                    icon: "heart.fill"
                )
                
                MetricCardView(
                    title: "Blood Pressure",
                    value: "\(anomalyManager.currentSystolic)/\(anomalyManager.currentDiastolic)",
                    status: anomalyManager.bloodPressureStatus,
                    icon: "drop.fill"
                )
                
                MetricCardView(
                    title: "Oxygen Saturation",
                    value: "\(anomalyManager.currentOxygenSaturation)%",
                    status: anomalyManager.oxygenSaturationStatus,
                    icon: "lungs.fill"
                )
                
                MetricCardView(
                    title: "Temperature",
                    value: "\(anomalyManager.currentTemperature, specifier: "%.1f")°F",
                    status: anomalyManager.temperatureStatus,
                    icon: "thermometer"
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Trend Analysis Section
    private var trendAnalysisSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Health Trends")
                    .font(.headline)
                
                Spacer()
                
                Picker("Time Range", selection: $selectedTimeRange) {
                    ForEach(TimeRange.allCases, id: \.self) { range in
                        Text(range.rawValue).tag(range)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .frame(width: 200)
            }
            
            // Trend chart placeholder
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemGray5))
                .frame(height: 200)
                .overlay(
                    VStack {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.largeTitle)
                            .foregroundColor(.secondary)
                        Text("Health Trend Chart")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                )
            
            // Trend insights
            if let insight = anomalyManager.currentTrendInsight {
                HStack {
                    Image(systemName: insight.icon)
                        .foregroundColor(insight.color)
                    Text(insight.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Emergency Contacts Section
    private var emergencyContactsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Emergency Contacts")
                    .font(.headline)
                Spacer()
                Button("Manage") {
                    showingEmergencyContacts = true
                }
                .font(.caption)
            }
            
            if anomalyManager.emergencyContacts.isEmpty {
                Text("No emergency contacts configured")
                    .foregroundColor(.secondary)
                    .italic()
            } else {
                ForEach(anomalyManager.emergencyContacts.prefix(2)) { contact in
                    EmergencyContactRowView(contact: contact)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Settings Section
    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Detection Settings")
                .font(.headline)
            
            VStack(spacing: 8) {
                HStack {
                    Text("Anomaly Detection")
                    Spacer()
                    Toggle("", isOn: $anomalyManager.isAnomalyDetectionEnabled)
                }
                
                HStack {
                    Text("Emergency Alerts")
                    Spacer()
                    Toggle("", isOn: $anomalyManager.isEmergencyAlertsEnabled)
                }
                
                HStack {
                    Text("Location Sharing")
                    Spacer()
                    Toggle("", isOn: $anomalyManager.isLocationSharingEnabled)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Supporting Views

struct AlertRowView: View {
    let alert: HealthAlert
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Image(systemName: alert.severity.icon)
                    .foregroundColor(alert.severity.color)
                    .frame(width: 20)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(alert.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text(alert.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                Text(alert.timestamp, style: .relative)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct MetricCardView: View {
    let title: String
    let value: String
    let status: HealthMetricStatus
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(status.color)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
            }
            
            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
            
            HStack {
                Circle()
                    .fill(status.color)
                    .frame(width: 8, height: 8)
                Text(status.description)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Spacer()
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(status.color.opacity(0.3), lineWidth: 1)
        )
    }
}

struct EmergencyContactRowView: View {
    let contact: EmergencyContact
    
    var body: some View {
        HStack {
            Image(systemName: "person.circle.fill")
                .foregroundColor(.blue)
                .font(.title2)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(contact.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(contact.phoneNumber)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if contact.isPrimary {
                Text("Primary")
                    .font(.caption2)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(4)
            }
        }
        .padding(.vertical, 4)
    }
}

struct EmergencyContactsView: View {
    @ObservedObject var anomalyManager: HealthAnomalyDetectionManager
    @Environment(\.presentationMode) var presentationMode
    @State private var showingAddContact = false
    
    var body: some View {
        NavigationView {
            List {
                ForEach(anomalyManager.emergencyContacts) { contact in
                    EmergencyContactRowView(contact: contact)
                }
                .onDelete(perform: deleteContact)
            }
            .navigationTitle("Emergency Contacts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        showingAddContact = true
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddContact) {
            AddEmergencyContactView(anomalyManager: anomalyManager)
        }
    }
    
    private func deleteContact(offsets: IndexSet) {
        // Implementation for deleting contacts
    }
}

struct AddEmergencyContactView: View {
    @ObservedObject var anomalyManager: HealthAnomalyDetectionManager
    @Environment(\.presentationMode) var presentationMode
    @State private var name = ""
    @State private var phoneNumber = ""
    @State private var isPrimary = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Contact Information")) {
                    TextField("Name", text: $name)
                    TextField("Phone Number", text: $phoneNumber)
                        .keyboardType(.phonePad)
                }
                
                Section {
                    Toggle("Primary Contact", isOn: $isPrimary)
                }
            }
            .navigationTitle("Add Emergency Contact")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        // Add contact implementation
                        presentationMode.wrappedValue.dismiss()
                    }
                    .disabled(name.isEmpty || phoneNumber.isEmpty)
                }
            }
        }
    }
}

struct AnomalyDetectionSettingsView: View {
    @ObservedObject var anomalyManager: HealthAnomalyDetectionManager
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Detection Settings")) {
                    Toggle("Enable Anomaly Detection", isOn: $anomalyManager.isAnomalyDetectionEnabled)
                    Toggle("Enable Emergency Alerts", isOn: $anomalyManager.isEmergencyAlertsEnabled)
                    Toggle("Enable Location Sharing", isOn: $anomalyManager.isLocationSharingEnabled)
                }
                
                Section(header: Text("Alert Thresholds")) {
                    HStack {
                        Text("Heart Rate Alert")
                        Spacer()
                        Text("\(anomalyManager.heartRateThreshold) bpm")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Blood Pressure Alert")
                        Spacer()
                        Text("\(anomalyManager.bloodPressureThreshold)")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section(header: Text("Privacy")) {
                    Toggle("Share Health Data", isOn: $anomalyManager.isHealthDataSharingEnabled)
                    Toggle("Analytics", isOn: $anomalyManager.isAnalyticsEnabled)
                }
            }
            .navigationTitle("Detection Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

struct AlertDetailView: View {
    let alert: HealthAlert
    @ObservedObject var anomalyManager: HealthAnomalyDetectionManager
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Alert header
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: alert.severity.icon)
                                .foregroundColor(alert.severity.color)
                                .font(.title)
                            
                            VStack(alignment: .leading) {
                                Text(alert.title)
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                
                                Text(alert.severity.description)
                                    .font(.subheadline)
                                    .foregroundColor(alert.severity.color)
                            }
                            
                            Spacer()
                        }
                        
                        Text(alert.description)
                            .font(.body)
                    }
                    .padding()
                    .background(alert.severity.color.opacity(0.1))
                    .cornerRadius(12)
                    
                    // Alert details
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Details")
                            .font(.headline)
                        
                        DetailRow(title: "Timestamp", value: alert.timestamp.formatted())
                        DetailRow(title: "Metric", value: alert.metricType.rawValue)
                        DetailRow(title: "Value", value: alert.metricValue)
                        DetailRow(title: "Threshold", value: alert.threshold)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // Recommendations
                    if !alert.recommendations.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Recommendations")
                                .font(.headline)
                            
                            ForEach(alert.recommendations, id: \.self) { recommendation in
                                HStack(alignment: .top) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                        .frame(width: 20)
                                    
                                    Text(recommendation)
                                        .font(.body)
                                }
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    
                    // Actions
                    VStack(spacing: 12) {
                        Button("Dismiss Alert") {
                            // Dismiss alert implementation
                            presentationMode.wrappedValue.dismiss()
                        }
                        .buttonStyle(.borderedProminent)
                        .frame(maxWidth: .infinity)
                        
                        if alert.severity == .critical {
                            Button("Contact Emergency Services") {
                                // Emergency contact implementation
                            }
                            .buttonStyle(.bordered)
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Alert Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

struct DetailRow: View {
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
    HealthAnomalyDetectionView()
} 
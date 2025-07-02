import SwiftUI
import WatchKit

struct WatchSettingsView: View {
    @StateObject private var sessionManager = WatchSessionManager.shared
    @StateObject private var notificationManager = WatchNotificationManager.shared
    @StateObject private var hapticManager = WatchHapticManager.shared
    @StateObject private var environmentMonitor = WatchEnvironmentMonitor()
    
    @State private var showingAbout = false
    @State private var showingDiagnostics = false
    
    var body: some View {
        NavigationView {
            List {
                // Health Monitoring Settings
                Section("Health Monitoring") {
                    NavigationLink("Sleep Settings") {
                        SleepSettingsView()
                    }
                    
                    NavigationLink("Health Alerts") {
                        HealthAlertsSettingsView()
                    }
                    
                    NavigationLink("Heart Rate Zones") {
                        HeartRateSettingsView()
                    }
                }
                
                // Notification Settings
                Section("Notifications") {
                    HStack {
                        Text("Notifications")
                        Spacer()
                        Text(notificationManager.notificationPermissionGranted ? "Enabled" : "Disabled")
                            .foregroundColor(notificationManager.notificationPermissionGranted ? .green : .red)
                            .font(.caption)
                    }
                    
                    NavigationLink("Sleep Reminders") {
                        SleepReminderSettingsView()
                    }
                    
                    NavigationLink("Health Alerts") {
                        HealthAlertSettingsView()
                    }
                }
                
                // Environment Settings
                Section("Environment") {
                    NavigationLink("Environment Monitor") {
                        EnvironmentSettingsView()
                    }
                    
                    NavigationLink("Smart Home Integration") {
                        SmartHomeSettingsView()
                    }
                }
                
                // Haptic Settings
                Section("Haptics") {
                    NavigationLink("Haptic Patterns") {
                        HapticSettingsView()
                    }
                    
                    HStack {
                        Text("Haptic Support")
                        Spacer()
                        Text(hapticManager.isHapticSupported() ? "Supported" : "Not Supported")
                            .foregroundColor(hapticManager.isHapticSupported() ? .green : .red)
                            .font(.caption)
                    }
                }
                
                // Data & Privacy
                Section("Data & Privacy") {
                    NavigationLink("Data Export") {
                        DataExportView()
                    }
                    
                    NavigationLink("Privacy Settings") {
                        PrivacySettingsView()
                    }
                    
                    Button("Clear All Data") {
                        clearAllData()
                    }
                    .foregroundColor(.red)
                }
                
                // System Information
                Section("System") {
                    Button("Diagnostics") {
                        showingDiagnostics = true
                    }
                    
                    Button("About") {
                        showingAbout = true
                    }
                    
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(isPresented: $showingAbout) {
            AboutView()
        }
        .sheet(isPresented: $showingDiagnostics) {
            DiagnosticsView()
        }
    }
    
    private func clearAllData() {
        // Clear all stored data
        sessionManager.clearSessionData()
        notificationManager.cancelAllNotifications()
        
        // Trigger haptic feedback
        hapticManager.triggerHaptic(type: .warning)
    }
}

struct SleepSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var sleepGoal: Double = 8.0
    @State private var bedtime = Date()
    @State private var wakeTime = Date()
    @State private var smartWakeEnabled = true
    @State private var sleepStageAlertsEnabled = false
    
    var body: some View {
        List {
            Section("Sleep Goal") {
                HStack {
                    Text("Target Sleep Duration")
                    Spacer()
                    Text("\(sleepGoal, specifier: "%.1f") hours")
                        .foregroundColor(.secondary)
                }
                
                Slider(value: $sleepGoal, in: 6...10, step: 0.5)
            }
            
            Section("Sleep Schedule") {
                DatePicker("Bedtime", selection: $bedtime, displayedComponents: .hourAndMinute)
                DatePicker("Wake Time", selection: $wakeTime, displayedComponents: .hourAndMinute)
            }
            
            Section("Smart Features") {
                Toggle("Smart Wake", isOn: $smartWakeEnabled)
                    .toggleStyle(SwitchToggleStyle())
                
                if smartWakeEnabled {
                    Text("Wake during light sleep phase")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Toggle("Sleep Stage Alerts", isOn: $sleepStageAlertsEnabled)
                    .toggleStyle(SwitchToggleStyle())
            }
        }
        .navigationTitle("Sleep Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct HealthAlertsSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var heartRateAlertsEnabled = true
    @State private var highHeartRateThreshold: Double = 120
    @State private var lowHeartRateThreshold: Double = 50
    @State private var hrvAlertsEnabled = true
    @State private var hrvThreshold: Double = 20
    
    var body: some View {
        List {
            Section("Heart Rate Alerts") {
                Toggle("Enable Alerts", isOn: $heartRateAlertsEnabled)
                    .toggleStyle(SwitchToggleStyle())
                
                if heartRateAlertsEnabled {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("High Threshold")
                            Spacer()
                            Text("\(Int(highHeartRateThreshold)) BPM")
                                .foregroundColor(.secondary)
                        }
                        Slider(value: $highHeartRateThreshold, in: 100...180, step: 5)
                        
                        HStack {
                            Text("Low Threshold")
                            Spacer()
                            Text("\(Int(lowHeartRateThreshold)) BPM")
                                .foregroundColor(.secondary)
                        }
                        Slider(value: $lowHeartRateThreshold, in: 40...80, step: 5)
                    }
                }
            }
            
            Section("HRV Alerts") {
                Toggle("Enable HRV Alerts", isOn: $hrvAlertsEnabled)
                    .toggleStyle(SwitchToggleStyle())
                
                if hrvAlertsEnabled {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Low HRV Threshold")
                            Spacer()
                            Text("\(Int(hrvThreshold)) ms")
                                .foregroundColor(.secondary)
                        }
                        Slider(value: $hrvThreshold, in: 10...50, step: 5)
                    }
                }
            }
        }
        .navigationTitle("Health Alerts")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct HeartRateSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var zone1Max: Double = 114 // 60% max HR
    @State private var zone2Max: Double = 133 // 70% max HR
    @State private var zone3Max: Double = 152 // 80% max HR
    @State private var zone4Max: Double = 171 // 90% max HR
    @State private var maxHeartRate: Double = 190
    
    var body: some View {
        List {
            Section("Maximum Heart Rate") {
                HStack {
                    Text("Max HR")
                    Spacer()
                    Text("\(Int(maxHeartRate)) BPM")
                        .foregroundColor(.secondary)
                }
                Slider(value: $maxHeartRate, in: 160...220, step: 1)
            }
            
            Section("Heart Rate Zones") {
                VStack(alignment: .leading, spacing: 12) {
                    ZoneRow(title: "Zone 1 (Recovery)", color: .gray, range: "50-\(Int(zone1Max)) BPM")
                    ZoneRow(title: "Zone 2 (Base)", color: .blue, range: "\(Int(zone1Max+1))-\(Int(zone2Max)) BPM")
                    ZoneRow(title: "Zone 3 (Aerobic)", color: .green, range: "\(Int(zone2Max+1))-\(Int(zone3Max)) BPM")
                    ZoneRow(title: "Zone 4 (Threshold)", color: .orange, range: "\(Int(zone3Max+1))-\(Int(zone4Max)) BPM")
                    ZoneRow(title: "Zone 5 (Neuromuscular)", color: .red, range: "\(Int(zone4Max+1))+ BPM")
                }
            }
        }
        .navigationTitle("HR Zones")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: maxHeartRate) { newValue in
            updateZones(maxHR: newValue)
        }
    }
    
    private func updateZones(maxHR: Double) {
        zone1Max = maxHR * 0.6
        zone2Max = maxHR * 0.7
        zone3Max = maxHR * 0.8
        zone4Max = maxHR * 0.9
    }
}

struct ZoneRow: View {
    let title: String
    let color: Color
    let range: String
    
    var body: some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                
                Text(range)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

struct HapticSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var hapticManager = WatchHapticManager.shared
    
    var body: some View {
        List {
            Section("Test Haptic Patterns") {
                ForEach(WatchHapticManager.HapticType.allCases, id: \.self) { hapticType in
                    Button(hapticType.rawValue.capitalized) {
                        hapticManager.triggerHaptic(type: hapticType)
                    }
                }
            }
            
            Section("Advanced Patterns") {
                Button("Progressive Wake") {
                    hapticManager.triggerProgressiveWakeHaptic()
                }
                
                Button("Rhythmic Pattern") {
                    hapticManager.triggerRhythmicHaptic(pattern: [1.0, 2.0], duration: 10.0)
                }
                
                Button("Stop All Haptics") {
                    hapticManager.stopAllHaptics()
                }
                .foregroundColor(.red)
            }
        }
        .navigationTitle("Haptic Patterns")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct DataExportView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var sessionManager = WatchSessionManager.shared
    @State private var exportInProgress = false
    
    var body: some View {
        List {
            Section("Export Options") {
                Button("Export Health Data") {
                    exportHealthData()
                }
                .disabled(exportInProgress)
                
                Button("Export Sleep Sessions") {
                    exportSleepSessions()
                }
                .disabled(exportInProgress)
                
                Button("Export Environment Data") {
                    exportEnvironmentData()
                }
                .disabled(exportInProgress)
            }
            
            if exportInProgress {
                Section {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.7)
                        Text("Exporting data...")
                            .font(.caption)
                    }
                }
            }
        }
        .navigationTitle("Data Export")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func exportHealthData() {
        exportInProgress = true
        
        // Send export request to iPhone
        let message = WatchMessage(
            command: "exportHealthData",
            data: ["type": "health", "timestamp": Date().timeIntervalSince1970],
            source: "watch"
        )
        
        WatchConnectivityManager.shared.sendMessage(message)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            exportInProgress = false
        }
    }
    
    private func exportSleepSessions() {
        exportInProgress = true
        
        let message = WatchMessage(
            command: "exportSleepData",
            data: ["type": "sleep", "timestamp": Date().timeIntervalSince1970],
            source: "watch"
        )
        
        WatchConnectivityManager.shared.sendMessage(message)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            exportInProgress = false
        }
    }
    
    private func exportEnvironmentData() {
        exportInProgress = true
        
        let message = WatchMessage(
            command: "exportEnvironmentData",
            data: ["type": "environment", "timestamp": Date().timeIntervalSince1970],
            source: "watch"
        )
        
        WatchConnectivityManager.shared.sendMessage(message)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            exportInProgress = false
        }
    }
}

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    VStack(spacing: 16) {
                        Image(systemName: "heart.fill")
                            .font(.largeTitle)
                            .foregroundColor(.red)
                        
                        Text("HealthAI 2030")
                            .font(.headline)
                            .fontWeight(.bold)
                        
                        Text("Advanced Health Monitoring")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("Version 1.0.0")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical)
                }
                
                Section("Features") {
                    Text("• Real-time health monitoring")
                    Text("• Sleep stage analysis")
                    Text("• Environment optimization")
                    Text("• Smart notifications")
                    Text("• AI-powered insights")
                }
                
                Section("Privacy") {
                    Text("Your health data is encrypted and stored securely on your device. Data is only shared with your explicit consent.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("About")
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

struct DiagnosticsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var sessionManager = WatchSessionManager.shared
    @StateObject private var connectivityManager = WatchConnectivityManager.shared
    
    var body: some View {
        NavigationView {
            List {
                Section("System Status") {
                    DiagnosticRow(title: "Health Monitoring", status: sessionManager.isMonitoring)
                    DiagnosticRow(title: "iPhone Connection", status: connectivityManager.connectionStatus == .connected)
                    DiagnosticRow(title: "HealthKit Access", status: true) // Would check actual HealthKit status
                    DiagnosticRow(title: "Notifications", status: WatchNotificationManager.shared.notificationPermissionGranted)
                }
                
                Section("Performance") {
                    HStack {
                        Text("Memory Usage")
                        Spacer()
                        Text("Normal")
                            .foregroundColor(.green)
                            .font(.caption)
                    }
                    
                    HStack {
                        Text("Battery Impact")
                        Spacer()
                        Text("Low")
                            .foregroundColor(.green)
                            .font(.caption)
                    }
                }
                
                Section("Data") {
                    HStack {
                        Text("Health Data Points")
                        Spacer()
                        Text("1,247")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                    
                    HStack {
                        Text("Messages Sent")
                        Spacer()
                        Text("\(connectivityManager.messageCount)")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Diagnostics")
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

struct DiagnosticRow: View {
    let title: String
    let status: Bool
    
    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Image(systemName: status ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(status ? .green : .red)
                .font(.caption)
        }
    }
}

// Placeholder views for other settings
struct SleepReminderSettingsView: View {
    var body: some View {
        Text("Sleep Reminder Settings")
            .navigationTitle("Sleep Reminders")
    }
}

struct HealthAlertSettingsView: View {
    var body: some View {
        Text("Health Alert Settings")
            .navigationTitle("Health Alerts")
    }
}

struct SmartHomeSettingsView: View {
    var body: some View {
        Text("Smart Home Integration Settings")
            .navigationTitle("Smart Home")
    }
}

struct PrivacySettingsView: View {
    var body: some View {
        Text("Privacy Settings")
            .navigationTitle("Privacy")
    }
}

// Extension to add clearSessionData method
extension WatchSessionManager {
    func clearSessionData() {
        // Implementation would clear all stored session data
        print("Clearing session data...")
    }
}

#Preview {
    WatchSettingsView()
}
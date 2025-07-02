import SwiftUI
import HealthKit

struct SettingsView: View {
    @StateObject private var healthDataManager = HealthDataManager.shared
    @StateObject private var sleepOptimizationManager = SleepOptimizationManager.shared
    @StateObject private var environmentManager = EnvironmentManager.shared
    @StateObject private var audioGenerator = BreathingAudioFileGenerator.shared
    
    @State private var showingHealthKitAuth = false
    @State private var showingDataExport = false
    @State private var showingAbout = false
    
    var body: some View {
        NavigationStack {
            List {
                // Health Data Section
                Section("Health Data") {
                    HealthKitStatusRow()
                    
                    NavigationLink("Data Permissions") {
                        DataPermissionsView()
                    }
                    
                    NavigationLink("Export Data") {
                        DataExportView()
                    }
                }
                
                // Sleep Optimization Section
                Section("Sleep Optimization") {
                    SleepOptimizationToggle()
                    
                    NavigationLink("Sleep Settings") {
                        SleepSettingsView()
                    }
                    
                    NavigationLink("Audio Preferences") {
                        AudioPreferencesView()
                    }
                }
                
                // Environment Section
                Section("Environment") {
                    EnvironmentOptimizationToggle()
                    
                    NavigationLink("HomeKit Setup") {
                        HomeKitSetupView()
                    }
                    
                    NavigationLink("Environment Preferences") {
                        EnvironmentPreferencesView()
                    }
                }
                
                // Analytics & Insights Section
                Section("Analytics & Insights") {
                    NavigationLink("Predictive Analytics") {
                        PredictiveAnalyticsSettingsView()
                    }
                    
                    NavigationLink("Alert Settings") {
                        AlertSettingsView()
                    }
                    
                    NavigationLink("Data Retention") {
                        DataRetentionSettingsView()
                    }
                }
                
                // Privacy & Security Section
                Section("Privacy & Security") {
                    NavigationLink("Privacy Settings") {
                        PrivacySettingsView()
                    }
                    
                    NavigationLink("Data Sharing") {
                        DataSharingSettingsView()
                    }
                    
                    NavigationLink("CloudKit Sync") {
                        CloudKitSettingsView()
                    }
                }
                
                // App Information Section
                Section("App Information") {
                    NavigationLink("About HealthAI 2030") {
                        AboutView()
                    }
                    
                    NavigationLink("Help & Support") {
                        HelpSupportView()
                    }
                    
                    NavigationLink("Privacy Policy") {
                        PrivacyPolicyView()
                    }
                }
                
                // Developer Section
                #if DEBUG
                Section("Developer") {
                    NavigationLink("Debug Information") {
                        DebugView()
                    }
                    
                    Button("Reset All Data") {
                        resetAllData()
                    }
                    .foregroundColor(.red)
                }
                #endif
                
                // Audio File Generation Section
                audioFileGenerationSection
            }
            .navigationTitle("Settings")
        }
    }
    
    private func resetAllData() {
        // Implementation for resetting all data
        print("Resetting all data...")
    }
    
    // MARK: - Audio File Generation Section
    
    private var audioFileGenerationSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Audio Files")
                .font(.title2)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 10) {
                Text("Generate missing audio files for Apple TV breathing exercise")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if audioGenerator.isGenerating {
                    VStack(spacing: 8) {
                        ProgressView(value: audioGenerator.generationProgress)
                            .progressViewStyle(LinearProgressViewStyle())
                        
                        HStack {
                            Text("Generating: \(audioGenerator.currentFile)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Text("\(Int(audioGenerator.generationProgress * 100))%")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                } else {
                    Button(action: {
                        Task {
                            await audioGenerator.generateAudioFilesWithProgress()
                        }
                    }) {
                        HStack {
                            Image(systemName: "music.note")
                            Text("Generate Audio Files")
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.blue)
                        .cornerRadius(8)
                    }
                    .disabled(audioGenerator.isGenerating)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
        }
    }
}

// MARK: - Settings Row Components

struct HealthKitStatusRow: View {
    @ObservedObject private var healthDataManager = HealthDataManager.shared
    
    var body: some View {
        HStack {
            Image(systemName: "heart.fill")
                .foregroundColor(.red)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("HealthKit")
                    .font(.body)
                
                Text(healthDataManager.isAuthorized ? "Connected" : "Not Connected")
                    .font(.caption)
                    .foregroundColor(healthDataManager.isAuthorized ? .green : .orange)
            }
            
            Spacer()
            
            if !healthDataManager.isAuthorized {
                Button("Connect") {
                    healthDataManager.requestHealthDataAccess { success in
                        print("HealthKit authorization: \(success)")
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            } else {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            }
        }
    }
}

struct SleepOptimizationToggle: View {
    @ObservedObject private var sleepManager = SleepOptimizationManager.shared
    
    var body: some View {
        HStack {
            Image(systemName: "bed.double.fill")
                .foregroundColor(.blue)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Sleep Optimization")
                    .font(.body)
                
                Text(sleepManager.isOptimizationActive ? "Active" : "Inactive")
                    .font(.caption)
                    .foregroundColor(sleepManager.isOptimizationActive ? .green : .secondary)
            }
            
            Spacer()
            
            Toggle("", isOn: Binding(
                get: { sleepManager.isOptimizationActive },
                set: { isOn in
                    if isOn {
                        sleepManager.startOptimization()
                    } else {
                        sleepManager.stopOptimization()
                    }
                }
            ))
        }
    }
}

struct EnvironmentOptimizationToggle: View {
    @ObservedObject private var environmentManager = EnvironmentManager.shared
    
    var body: some View {
        HStack {
            Image(systemName: "house.fill")
                .foregroundColor(.green)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Environment Optimization")
                    .font(.body)
                
                Text(environmentManager.isOptimizationActive ? "Active" : "Inactive")
                    .font(.caption)
                    .foregroundColor(environmentManager.isOptimizationActive ? .green : .secondary)
            }
            
            Spacer()
            
            Toggle("", isOn: Binding(
                get: { environmentManager.isOptimizationActive },
                set: { isOn in
                    if isOn {
                        environmentManager.optimizeForSleep() // Default to sleep mode
                    } else {
                        environmentManager.stopOptimization()
                    }
                }
            ))
        }
    }
}

// MARK: - Detail Settings Views

struct DataPermissionsView: View {
    var body: some View {
        List {
            Section("HealthKit Permissions") {
                PermissionRow(title: "Heart Rate", granted: true)
                PermissionRow(title: "Heart Rate Variability", granted: true)
                PermissionRow(title: "Sleep Data", granted: true)
                PermissionRow(title: "Activity Data", granted: true)
                PermissionRow(title: "Body Temperature", granted: false)
            }
            
            Section("Device Permissions") {
                PermissionRow(title: "Apple Watch", granted: true)
                PermissionRow(title: "HomeKit", granted: false)
                PermissionRow(title: "Notifications", granted: true)
            }
        }
        .navigationTitle("Data Permissions")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct PermissionRow: View {
    let title: String
    let granted: Bool
    
    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Image(systemName: granted ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(granted ? .green : .red)
        }
    }
}

struct DataExportView: View {
    @State private var showingExportOptions = false
    
    var body: some View {
        List {
            Section("Export Options") {
                Button("Export All Health Data") {
                    exportHealthData()
                }
                
                Button("Export Sleep Reports") {
                    exportSleepReports()
                }
                
                Button("Export Analytics Data") {
                    exportAnalyticsData()
                }
            }
            
            Section("Export Format") {
                ForEach(["JSON", "CSV", "PDF"], id: \.self) { format in
                    HStack {
                        Text(format)
                        Spacer()
                        Image(systemName: "doc.badge.arrow.up")
                    }
                }
            }
        }
        .navigationTitle("Export Data")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func exportHealthData() {
        print("Exporting health data...")
    }
    
    private func exportSleepReports() {
        print("Exporting sleep reports...")
    }
    
    private func exportAnalyticsData() {
        print("Exporting analytics data...")
    }
}

struct SleepSettingsView: View {
    @State private var bedtime = Date()
    @State private var wakeTime = Date()
    @State private var enableSmartAlarm = true
    @State private var optimizationIntensity = 0.7
    
    var body: some View {
        List {
            Section("Sleep Schedule") {
                DatePicker("Bedtime", selection: $bedtime, displayedComponents: .hourAndMinute)
                DatePicker("Wake Time", selection: $wakeTime, displayedComponents: .hourAndMinute)
            }
            
            Section("Smart Features") {
                Toggle("Smart Alarm", isOn: $enableSmartAlarm)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Optimization Intensity")
                    Slider(value: $optimizationIntensity, in: 0...1)
                    Text("Intensity: \(optimizationIntensity, specifier: "%.0%")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("Sleep Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct AudioPreferencesView: View {
    @State private var enablePinkNoise = true
    @State private var enableBinauralBeats = true
    @State private var enableNatureSounds = false
    @State private var maxVolume = 0.6
    
    var body: some View {
        List {
            Section("Audio Types") {
                Toggle("Pink Noise", isOn: $enablePinkNoise)
                Toggle("Binaural Beats", isOn: $enableBinauralBeats)
                Toggle("Nature Sounds", isOn: $enableNatureSounds)
            }
            
            Section("Volume Settings") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Maximum Volume")
                    Slider(value: $maxVolume, in: 0...1)
                    Text("Volume: \(maxVolume, specifier: "%.0%")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("Audio Preferences")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct HomeKitSetupView: View {
    var body: some View {
        List {
            Section("HomeKit Status") {
                Text("Connect your HomeKit accessories to enable environment optimization")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Section("Supported Accessories") {
                Text("• Thermostats")
                Text("• Lights")
                Text("• Air Purifiers")
                Text("• Humidifiers/Dehumidifiers")
                Text("• Smart Blinds")
            }
        }
        .navigationTitle("HomeKit Setup")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct EnvironmentPreferencesView: View {
    @State private var optimalTemperature = 20.0
    @State private var optimalHumidity = 50.0
    @State private var enableAutoOptimization = true
    
    var body: some View {
        List {
            Section("Optimal Ranges") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Temperature: \(optimalTemperature, specifier: "%.1f")°C")
                    Slider(value: $optimalTemperature, in: 16...26)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Humidity: \(optimalHumidity, specifier: "%.0f")%")
                    Slider(value: $optimalHumidity, in: 30...70)
                }
            }
            
            Section("Automation") {
                Toggle("Auto Optimization", isOn: $enableAutoOptimization)
            }
        }
        .navigationTitle("Environment Preferences")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Placeholder Views

struct PredictiveAnalyticsSettingsView: View {
    var body: some View {
        List {
            Text("Predictive Analytics Settings")
        }
        .navigationTitle("Predictive Analytics")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct AlertSettingsView: View {
    var body: some View {
        List {
            Text("Alert Settings")
        }
        .navigationTitle("Alert Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct DataRetentionSettingsView: View {
    var body: some View {
        List {
            Text("Data Retention Settings")
        }
        .navigationTitle("Data Retention")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct PrivacySettingsView: View {
    var body: some View {
        List {
            Text("Privacy Settings")
        }
        .navigationTitle("Privacy Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct DataSharingSettingsView: View {
    var body: some View {
        List {
            Text("Data Sharing Settings")
        }
        .navigationTitle("Data Sharing")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct CloudKitSettingsView: View {
    var body: some View {
        List {
            Text("CloudKit Sync Settings")
        }
        .navigationTitle("CloudKit Sync")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct AboutView: View {
    var body: some View {
        List {
            Section("App Information") {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("1.0.0")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Build")
                    Spacer()
                    Text("2030.1.0")
                        .foregroundColor(.secondary)
                }
            }
            
            Section("About") {
                Text("HealthAI 2030 is an advanced health monitoring and optimization platform that uses AI to improve your sleep, health, and environment.")
            }
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct HelpSupportView: View {
    var body: some View {
        List {
            Text("Help & Support content")
        }
        .navigationTitle("Help & Support")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct PrivacyPolicyView: View {
    var body: some View {
        List {
            Text("Privacy Policy content")
        }
        .navigationTitle("Privacy Policy")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct DebugView: View {
    var body: some View {
        List {
            Text("Debug Information")
        }
        .navigationTitle("Debug")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    SettingsView()
}
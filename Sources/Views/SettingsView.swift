import SwiftUI
import SwiftData
#if canImport(HealthKit)
import HealthKit
#endif

/// Comprehensive settings view with account management and app preferences
struct SettingsView: View {
    @StateObject private var authManager = AuthenticationManager.shared
    @StateObject private var errorHandler = ErrorHandlingService.shared
    @State private var showingAccountSettings = false
    @State private var showingPrivacySettings = false
    @State private var showingDataExport = false
    @State private var showingAbout = false
    
    var body: some View {
        NavigationStack {
            List {
                // Account Section
                Section("Account") {
                    if let user = authManager.currentUser {
                        HStack {
                            Image(systemName: "person.circle.fill")
                                .font(.title2)
                                .foregroundColor(.blue)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(user.displayName)
                                    .font(.headline)
                                Text(user.email)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Button("Edit") {
                                showingAccountSettings = true
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("Account: \(user.displayName), \(user.email)")
                    }
                    
                    NavigationLink("Account Settings") {
                        AccountSettingsView()
                    }
                    .accessibilityLabel("Manage account settings")
                }
                
                // Health & Data Section
                Section("Health & Data") {
                    NavigationLink("HealthKit Integration") {
                        HealthKitSettingsView()
                    }
                    .accessibilityLabel("Configure HealthKit integration")
                    
                    NavigationLink("Data Export") {
                        DataExportView()
                    }
                    .accessibilityLabel("Export your health data")
                    
                    NavigationLink("Privacy & Security") {
                        PrivacySettingsView()
                    }
                    .accessibilityLabel("Manage privacy and security settings")
                }
                
                // Notifications Section
                Section("Notifications") {
                    NavigationLink("Notification Preferences") {
                        NotificationSettingsView()
                    }
                    .accessibilityLabel("Configure notification preferences")
                    
                    NavigationLink("Focus Mode Integration") {
                        FocusModeSettingsView()
                    }
                    .accessibilityLabel("Configure Focus Mode integration")
                }
                
                // AI & Personalization Section
                Section("AI & Personalization") {
                    NavigationLink("AI Preferences") {
                        AISettingsView()
                    }
                    .accessibilityLabel("Configure AI preferences")
                    
                    NavigationLink("Personalization") {
                        PersonalizationSettingsView()
                    }
                    .accessibilityLabel("Manage personalization settings")
                }
                
                // Support Section
                Section("Support") {
                    NavigationLink("Help & FAQ") {
                        HelpFAQView()
                    }
                    .accessibilityLabel("View help and frequently asked questions")
                    
                    NavigationLink("Contact Support") {
                        ContactSupportView()
                    }
                    .accessibilityLabel("Contact customer support")
                    
                    NavigationLink("About") {
                        AboutView()
                    }
                    .accessibilityLabel("About HealthAI 2030")
                }
                
                // Legal Section
                Section("Legal") {
                    NavigationLink("Privacy Policy") {
                        PrivacyPolicyView()
                    }
                    .accessibilityLabel("View privacy policy")
                    
                    NavigationLink("Terms of Service") {
                        TermsOfServiceView()
                    }
                    .accessibilityLabel("View terms of service")
                    
                    NavigationLink("Data Processing") {
                        DataProcessingView()
                    }
                    .accessibilityLabel("View data processing information")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .alert("Error", isPresented: $errorHandler.showingError) {
                Button("OK") { errorHandler.dismissError() }
            } message: {
                Text(errorHandler.currentErrorMessage)
            }
        }
    }
}

// MARK: - Supporting Views

struct HealthKitSettingsView: View {
    @StateObject private var healthKitManager = HealthKitManager.shared
    @State private var isAuthorized = false
    
    var body: some View {
        List {
            Section("HealthKit Access") {
                HStack {
                    Text("Health Data Access")
                    Spacer()
                    Text(isAuthorized ? "Authorized" : "Not Authorized")
                        .foregroundColor(isAuthorized ? .green : .red)
                }
                
                if !isAuthorized {
                    Button("Request Access") {
                        Task {
                            await requestHealthKitAccess()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            
            Section("Data Types") {
                DataTypeRow(title: "Heart Rate", isEnabled: true)
                DataTypeRow(title: "Heart Rate Variability", isEnabled: true)
                DataTypeRow(title: "Sleep Analysis", isEnabled: true)
                DataTypeRow(title: "Steps", isEnabled: true)
                DataTypeRow(title: "Active Energy", isEnabled: true)
            }
        }
        .navigationTitle("HealthKit")
        .onAppear {
            checkAuthorizationStatus()
        }
    }
    
    private func checkAuthorizationStatus() {
        // Check HealthKit authorization status
        isAuthorized = healthKitManager.isAuthorized
    }
    
    private func requestHealthKitAccess() async {
        do {
            try await healthKitManager.requestAuthorization()
            await MainActor.run {
                isAuthorized = true
            }
        } catch {
            // Error handling is done by HealthKitManager
        }
    }
}

struct DataTypeRow: View {
    let title: String
    let isEnabled: Bool
    
    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Image(systemName: isEnabled ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(isEnabled ? .green : .red)
        }
    }
}

struct NotificationSettingsView: View {
    @State private var healthAlerts = true
    @State private var weeklyReports = true
    @State private var achievementNotifications = true
    @State private var reminderNotifications = true
    
    var body: some View {
        List {
            Section("Notification Types") {
                Toggle("Health Alerts", isOn: $healthAlerts)
                Toggle("Weekly Reports", isOn: $weeklyReports)
                Toggle("Achievement Notifications", isOn: $achievementNotifications)
                Toggle("Reminder Notifications", isOn: $reminderNotifications)
            }
            
            Section("Notification Schedule") {
                NavigationLink("Quiet Hours") {
                    QuietHoursSettingsView()
                }
                NavigationLink("Focus Mode Integration") {
                    FocusModeSettingsView()
                }
            }
        }
        .navigationTitle("Notifications")
    }
}

struct AISettingsView: View {
    @State private var aiInsightsEnabled = true
    @State private var personalizedRecommendations = true
    @State private var predictiveAnalytics = true
    @State private var dataSharingForAI = false
    
    var body: some View {
        List {
            Section("AI Features") {
                Toggle("AI Health Insights", isOn: $aiInsightsEnabled)
                Toggle("Personalized Recommendations", isOn: $personalizedRecommendations)
                Toggle("Predictive Analytics", isOn: $predictiveAnalytics)
            }
            
            Section("Data & Privacy") {
                Toggle("Share Data for AI Training", isOn: $dataSharingForAI)
                Text("This helps improve AI accuracy while maintaining your privacy")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("AI Preferences")
    }
}

struct PrivacySettingsView: View {
    @State private var biometricAuth = true
    @State private var dataEncryption = true
    @State private var analyticsEnabled = false
    
    var body: some View {
        List {
            Section("Security") {
                Toggle("Biometric Authentication", isOn: $biometricAuth)
                Toggle("Data Encryption", isOn: $dataEncryption)
            }
            
            Section("Analytics") {
                Toggle("Analytics & Crash Reports", isOn: $analyticsEnabled)
                Text("Help us improve the app by sharing anonymous usage data")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Section("Data Management") {
                NavigationLink("Export Data") {
                    DataExportView()
                }
                NavigationLink("Delete Account") {
                    DeleteAccountView()
                }
                .foregroundColor(.red)
            }
        }
        .navigationTitle("Privacy & Security")
    }
}

// Placeholder views for navigation
struct DataExportView: View {
    var body: some View {
        Text("Data Export")
            .navigationTitle("Export Data")
    }
}

struct FocusModeSettingsView: View {
    var body: some View {
        Text("Focus Mode Settings")
            .navigationTitle("Focus Mode")
    }
}

struct PersonalizationSettingsView: View {
    var body: some View {
        Text("Personalization Settings")
            .navigationTitle("Personalization")
    }
}

struct HelpFAQView: View {
    var body: some View {
        Text("Help & FAQ")
            .navigationTitle("Help & FAQ")
    }
}

struct ContactSupportView: View {
    var body: some View {
        Text("Contact Support")
            .navigationTitle("Contact Support")
    }
}

struct AboutView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "heart.text.square.fill")
                .font(.system(size: 80))
                .foregroundColor(.blue)
            
            Text("HealthAI 2030")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Version 1.0.0")
                .font(.title3)
                .foregroundColor(.secondary)
            
            Text("Your AI-powered health companion")
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Spacer()
        }
        .padding()
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            Text("Privacy Policy content...")
                .padding()
        }
        .navigationTitle("Privacy Policy")
    }
}

struct TermsOfServiceView: View {
    var body: some View {
        ScrollView {
            Text("Terms of Service content...")
                .padding()
        }
        .navigationTitle("Terms of Service")
    }
}

struct DataProcessingView: View {
    var body: some View {
        ScrollView {
            Text("Data Processing information...")
                .padding()
        }
        .navigationTitle("Data Processing")
    }
}

struct DeleteAccountView: View {
    @StateObject private var authManager = AuthenticationManager.shared
    @State private var showingConfirmation = false
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundColor(.red)
            
            Text("Delete Account")
                .font(.title)
                .fontWeight(.bold)
            
            Text("This action cannot be undone. All your health data and settings will be permanently deleted.")
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button("Delete Account") {
                showingConfirmation = true
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
        }
        .padding()
        .navigationTitle("Delete Account")
        .alert("Delete Account", isPresented: $showingConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                Task {
                    try? await authManager.deleteAccount()
                }
            }
        } message: {
            Text("Are you sure you want to permanently delete your account? This action cannot be undone.")
        }
    }
}

struct QuietHoursSettingsView: View {
    var body: some View {
        Text("Quiet Hours Settings")
            .navigationTitle("Quiet Hours")
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: [UserProfile.self, HealthData.self, DigitalTwin.self], isCloudKitEnabled: true)
}
import SwiftUI
import SwiftData

@available(tvOS 18.0, *)
struct TVSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var selectedCategory: SettingsCategory = .profile
    @State private var showingProfile = false
    @State private var showingFamilyManagement = false
    
    enum SettingsCategory: String, CaseIterable {
        case profile = "User Profile"
        case family = "Family Management"
        case data = "Data Sources"
        case notifications = "Notifications"
        case privacy = "Privacy & Security"
        case about = "About"
    }
    
    var body: some View {
        HStack(spacing: 0) {
            // Sidebar
            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Settings")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.horizontal, 24)
                        .padding(.top, 24)
                    
                    VStack(spacing: 8) {
                        ForEach(SettingsCategory.allCases, id: \.self) { category in
                            SettingsCategoryButton(
                                category: category,
                                isSelected: selectedCategory == category
                            ) {
                                selectedCategory = category
                            }
                        }
                    }
                }
                
                Spacer()
            }
            .frame(width: 400)
            .background(Color(.secondarySystemBackground))
            
            // Content Area
            VStack(spacing: 0) {
                // Content Header
                VStack(alignment: .leading, spacing: 16) {
                    Text(selectedCategory.rawValue)
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text(getCategoryDescription(selectedCategory))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(24)
                .background(Color(.systemBackground))
                
                // Content
                ScrollView {
                    VStack(spacing: 30) {
                        switch selectedCategory {
                        case .profile:
                            UserProfileSettingsView(showingProfile: $showingProfile)
                        case .family:
                            FamilyManagementSettingsView(showingFamilyManagement: $showingFamilyManagement)
                        case .data:
                            DataSourcesSettingsView()
                        case .notifications:
                            NotificationsSettingsView()
                        case .privacy:
                            PrivacySettingsView()
                        case .about:
                            AboutSettingsView()
                        }
                    }
                    .padding(24)
                }
            }
            .background(Color(.systemBackground))
        }
        .sheet(isPresented: $showingProfile) {
            UserProfileDetailView()
        }
        .sheet(isPresented: $showingFamilyManagement) {
            FamilyManagementDetailView()
        }
    }
    
    private func getCategoryDescription(_ category: SettingsCategory) -> String {
        switch category {
        case .profile:
            return "Manage your personal information and preferences"
        case .family:
            return "Add and manage family members"
        case .data:
            return "Configure data sources and sync settings"
        case .notifications:
            return "Customize notification preferences"
        case .privacy:
            return "Privacy and security settings"
        case .about:
            return "App information and support"
        }
    }
}

// MARK: - User Profile Settings
@available(tvOS 18.0, *)
struct UserProfileSettingsView: View {
    @Binding var showingProfile: Bool
    @State private var userName = "John Doe"
    @State private var userAge = "35"
    @State private var userHeight = "5'10\""
    @State private var userWeight = "165 lbs"
    
    var body: some View {
        VStack(spacing: 24) {
            // Profile Summary
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 120, height: 120)
                    
                    Text("JD")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.white)
                }
                
                VStack(spacing: 8) {
                    Text(userName)
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Primary User")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            // Profile Information
            VStack(alignment: .leading, spacing: 20) {
                Text("Personal Information")
                    .font(.headline)
                    .fontWeight(.bold)
                
                VStack(spacing: 16) {
                    SettingsRow(title: "Name", value: userName)
                    SettingsRow(title: "Age", value: "\(userAge) years old")
                    SettingsRow(title: "Height", value: userHeight)
                    SettingsRow(title: "Weight", value: userWeight)
                }
            }
            .padding(24)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(16)
            
            // Health Goals
            VStack(alignment: .leading, spacing: 20) {
                Text("Health Goals")
                    .font(.headline)
                    .fontWeight(.bold)
                
                VStack(spacing: 16) {
                    GoalRow(title: "Daily Steps", target: "10,000", current: "8,234")
                    GoalRow(title: "Sleep", target: "8 hours", current: "7.5 hours")
                    GoalRow(title: "Water", target: "64 oz", current: "48 oz")
                }
            }
            .padding(24)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(16)
            
            // Edit Profile Button
            Button("Edit Profile") {
                showingProfile = true
            }
            .buttonStyle(TVButtonStyle())
        }
    }
}

// MARK: - Family Management Settings
@available(tvOS 18.0, *)
struct FamilyManagementSettingsView: View {
    @Binding var showingFamilyManagement: Bool
    @Query private var familyMembers: [FamilyMember]
    
    var body: some View {
        VStack(spacing: 24) {
            // Family Summary
            VStack(spacing: 16) {
                Image(systemName: "person.3.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                VStack(spacing: 8) {
                    Text("Family Members")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("\(familyMembers.count) members in your family")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            // Family Members List
            VStack(alignment: .leading, spacing: 20) {
                Text("Family Members")
                    .font(.headline)
                    .fontWeight(.bold)
                
                if familyMembers.isEmpty {
                    EmptyStateView(
                        icon: "person.badge.plus",
                        title: "No Family Members",
                        message: "Add family members to share health data and insights"
                    )
                } else {
                    VStack(spacing: 16) {
                        ForEach(familyMembers) { member in
                            FamilyMemberRow(member: member)
                        }
                    }
                }
            }
            .padding(24)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(16)
            
            // Manage Family Button
            Button("Manage Family") {
                showingFamilyManagement = true
            }
            .buttonStyle(TVButtonStyle())
        }
    }
}

// MARK: - Data Sources Settings
@available(tvOS 18.0, *)
struct DataSourcesSettingsView: View {
    @State private var healthKitEnabled = true
    @State private var cloudKitEnabled = true
    @State private var thirdPartyEnabled = false
    
    var body: some View {
        VStack(spacing: 24) {
            // Data Sources
            VStack(alignment: .leading, spacing: 20) {
                Text("Data Sources")
                    .font(.headline)
                    .fontWeight(.bold)
                
                VStack(spacing: 16) {
                    DataSourceRow(
                        title: "HealthKit",
                        description: "Apple Health data integration",
                        icon: "heart.fill",
                        color: .red,
                        isEnabled: $healthKitEnabled
                    )
                    
                    DataSourceRow(
                        title: "iCloud",
                        description: "Cloud data synchronization",
                        icon: "icloud.fill",
                        color: .blue,
                        isEnabled: $cloudKitEnabled
                    )
                    
                    DataSourceRow(
                        title: "Third-Party Apps",
                        description: "Connect external health apps",
                        icon: "link",
                        color: .green,
                        isEnabled: $thirdPartyEnabled
                    )
                }
            }
            .padding(24)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(16)
            
            // Sync Settings
            VStack(alignment: .leading, spacing: 20) {
                Text("Sync Settings")
                    .font(.headline)
                    .fontWeight(.bold)
                
                VStack(spacing: 16) {
                    SettingsRow(title: "Auto Sync", value: "Every 15 minutes")
                    SettingsRow(title: "Last Sync", value: "2 minutes ago")
                    SettingsRow(title: "Data Usage", value: "1.2 GB")
                }
            }
            .padding(24)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(16)
        }
    }
}

// MARK: - Notifications Settings
@available(tvOS 18.0, *)
struct NotificationsSettingsView: View {
    @State private var healthAlerts = true
    @State private var workoutReminders = true
    @State private var medicationReminders = false
    @State private var familyUpdates = true
    @State private var weeklyReports = true
    
    var body: some View {
        VStack(spacing: 24) {
            // Notification Types
            VStack(alignment: .leading, spacing: 20) {
                Text("Notification Types")
                    .font(.headline)
                    .fontWeight(.bold)
                
                VStack(spacing: 16) {
                    NotificationRow(
                        title: "Health Alerts",
                        description: "Important health notifications",
                        icon: "heart.fill",
                        color: .red,
                        isEnabled: $healthAlerts
                    )
                    
                    NotificationRow(
                        title: "Workout Reminders",
                        description: "Daily exercise reminders",
                        icon: "figure.run",
                        color: .green,
                        isEnabled: $workoutReminders
                    )
                    
                    NotificationRow(
                        title: "Medication Reminders",
                        description: "Medication schedule alerts",
                        icon: "pill.fill",
                        color: .orange,
                        isEnabled: $medicationReminders
                    )
                    
                    NotificationRow(
                        title: "Family Updates",
                        description: "Family member health updates",
                        icon: "person.3.fill",
                        color: .blue,
                        isEnabled: $familyUpdates
                    )
                    
                    NotificationRow(
                        title: "Weekly Reports",
                        description: "Weekly health summary",
                        icon: "chart.bar.fill",
                        color: .purple,
                        isEnabled: $weeklyReports
                    )
                }
            }
            .padding(24)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(16)
            
            // Notification Schedule
            VStack(alignment: .leading, spacing: 20) {
                Text("Notification Schedule")
                    .font(.headline)
                    .fontWeight(.bold)
                
                VStack(spacing: 16) {
                    SettingsRow(title: "Quiet Hours", value: "10:00 PM - 7:00 AM")
                    SettingsRow(title: "Daily Limit", value: "10 notifications")
                    SettingsRow(title: "Sound", value: "Default")
                }
            }
            .padding(24)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(16)
        }
    }
}

// MARK: - Privacy Settings
@available(tvOS 18.0, *)
struct PrivacySettingsView: View {
    @State private var dataSharing = false
    @State private var analyticsEnabled = true
    @State private var locationServices = true
    
    var body: some View {
        VStack(spacing: 24) {
            // Privacy Options
            VStack(alignment: .leading, spacing: 20) {
                Text("Privacy Options")
                    .font(.headline)
                    .fontWeight(.bold)
                
                VStack(spacing: 16) {
                    PrivacyRow(
                        title: "Data Sharing",
                        description: "Share anonymized data for research",
                        isEnabled: $dataSharing
                    )
                    
                    PrivacyRow(
                        title: "Analytics",
                        description: "Help improve the app with usage data",
                        isEnabled: $analyticsEnabled
                    )
                    
                    PrivacyRow(
                        title: "Location Services",
                        description: "Use location for health insights",
                        isEnabled: $locationServices
                    )
                }
            }
            .padding(24)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(16)
            
            // Security
            VStack(alignment: .leading, spacing: 20) {
                Text("Security")
                    .font(.headline)
                    .fontWeight(.bold)
                
                VStack(spacing: 16) {
                    SettingsRow(title: "Biometric Lock", value: "Face ID")
                    SettingsRow(title: "Two-Factor Auth", value: "Enabled")
                    SettingsRow(title: "Data Encryption", value: "AES-256")
                }
            }
            .padding(24)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(16)
            
            // Data Management
            VStack(alignment: .leading, spacing: 20) {
                Text("Data Management")
                    .font(.headline)
                    .fontWeight(.bold)
                
                VStack(spacing: 16) {
                    Button("Export Health Data") {
                        // Export data
                    }
                    .buttonStyle(TVButtonStyle())
                    
                    Button("Delete All Data") {
                        // Show confirmation
                    }
                    .buttonStyle(TVButtonStyle())
                    .foregroundColor(.red)
                }
            }
            .padding(24)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(16)
        }
    }
}

// MARK: - About Settings
@available(tvOS 18.0, *)
struct AboutSettingsView: View {
    var body: some View {
        VStack(spacing: 24) {
            // App Information
            VStack(spacing: 16) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.red)
                
                VStack(spacing: 8) {
                    Text("HealthAI 2030")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Version 1.0.0")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            // App Details
            VStack(alignment: .leading, spacing: 20) {
                Text("App Information")
                    .font(.headline)
                    .fontWeight(.bold)
                
                VStack(spacing: 16) {
                    SettingsRow(title: "Version", value: "1.0.0")
                    SettingsRow(title: "Build", value: "2024.1.0")
                    SettingsRow(title: "Developer", value: "HealthAI Team")
                    SettingsRow(title: "Platform", value: "tvOS 18.0+")
                }
            }
            .padding(24)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(16)
            
            // Support
            VStack(alignment: .leading, spacing: 20) {
                Text("Support")
                    .font(.headline)
                    .fontWeight(.bold)
                
                VStack(spacing: 16) {
                    Button("Help & Support") {
                        // Open help
                    }
                    .buttonStyle(TVButtonStyle())
                    
                    Button("Privacy Policy") {
                        // Open privacy policy
                    }
                    .buttonStyle(TVButtonStyle())
                    
                    Button("Terms of Service") {
                        // Open terms
                    }
                    .buttonStyle(TVButtonStyle())
                }
            }
            .padding(24)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(16)
        }
    }
}

// MARK: - Supporting Views

@available(tvOS 18.0, *)
struct SettingsCategoryButton: View {
    let category: TVSettingsView.SettingsCategory
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Image(systemName: getCategoryIcon(category))
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? .white : .primary)
                    .frame(width: 24)
                
                Text(category.rawValue)
                    .font(.headline)
                    .foregroundColor(isSelected ? .white : .primary)
                
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(isSelected ? Color.blue : Color.clear)
            .cornerRadius(12)
        }
        .buttonStyle(CardButtonStyle())
    }
    
    private func getCategoryIcon(_ category: TVSettingsView.SettingsCategory) -> String {
        switch category {
        case .profile: return "person.fill"
        case .family: return "person.3.fill"
        case .data: return "icloud.fill"
        case .notifications: return "bell.fill"
        case .privacy: return "lock.fill"
        case .about: return "info.circle.fill"
        }
    }
}

@available(tvOS 18.0, *)
struct SettingsRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.primary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}

@available(tvOS 18.0, *)
struct GoalRow: View {
    let title: String
    let target: String
    let current: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.primary)
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(current)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text("of \(target)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

@available(tvOS 18.0, *)
struct FamilyMemberRow: View {
    let member: FamilyMember
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(member.profileColor)
                    .frame(width: 60, height: 60)
                
                Text(member.initials)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(member.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(member.relationship)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text("\(member.age) years")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(12)
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
}

@available(tvOS 18.0, *)
struct DataSourceRow: View {
    let title: String
    let description: String
    let icon: String
    let color: Color
    @Binding var isEnabled: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
                .frame(width: 40, height: 40)
                .background(color.opacity(0.1))
                .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Toggle("", isOn: $isEnabled)
                .toggleStyle(SwitchToggleStyle(tint: color))
        }
        .padding(12)
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
}

@available(tvOS 18.0, *)
struct NotificationRow: View {
    let title: String
    let description: String
    let icon: String
    let color: Color
    @Binding var isEnabled: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
                .frame(width: 40, height: 40)
                .background(color.opacity(0.1))
                .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Toggle("", isOn: $isEnabled)
                .toggleStyle(SwitchToggleStyle(tint: color))
        }
        .padding(12)
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
}

@available(tvOS 18.0, *)
struct PrivacyRow: View {
    let title: String
    let description: String
    @Binding var isEnabled: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Toggle("", isOn: $isEnabled)
                .toggleStyle(SwitchToggleStyle(tint: .blue))
        }
        .padding(12)
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
}

// MARK: - Detail Views
@available(tvOS 18.0, *)
struct UserProfileDetailView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Text("Edit Profile")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Profile editing interface would go here")
                    .font(.title2)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .padding(40)
            .navigationTitle("Edit Profile")
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

@available(tvOS 18.0, *)
struct FamilyManagementDetailView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Text("Manage Family")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Family management interface would go here")
                    .font(.title2)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .padding(40)
            .navigationTitle("Manage Family")
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

// MARK: - Button Style
@available(tvOS 18.0, *)
struct TVButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(12)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Preview
#Preview {
    TVSettingsView()
        .modelContainer(for: FamilyMember.self, inMemory: true)
} 
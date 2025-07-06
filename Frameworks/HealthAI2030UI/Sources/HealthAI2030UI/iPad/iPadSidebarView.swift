import SwiftUI

struct iPadSidebarView: View {
    @Binding var selectedSection: SidebarSection?
    @State private var showingUserProfile = false
    
    var body: some View {
        List(selection: $selectedSection) {
            // Health Overview Section
            Section("Health Overview") {
                NavigationLink(value: SidebarSection.dashboard) {
                    Label("Dashboard", systemImage: "square.grid.2x2.fill")
                        .foregroundColor(.blue)
                }
                
                NavigationLink(value: SidebarSection.analytics) {
                    Label("Analytics", systemImage: "chart.bar.xaxis")
                        .foregroundColor(.purple)
                }
            }
            
            // Core Features Section
            Section("Core Features") {
                NavigationLink(value: SidebarSection.aiCopilot) {
                    Label("AI Copilot", systemImage: "brain.head.profile")
                        .foregroundColor(.orange)
                }
                
                NavigationLink(value: SidebarSection.healthData) {
                    Label("Health Data", systemImage: "heart.text.square.fill")
                        .foregroundColor(.red)
                }
                
                NavigationLink(value: SidebarSection.sleepTracking) {
                    Label("Sleep Tracking", systemImage: "bed.double.fill")
                        .foregroundColor(.indigo)
                }
            }
            
            // Activity & Wellness Section
            Section("Activity & Wellness") {
                NavigationLink(value: SidebarSection.workouts) {
                    Label("Workouts", systemImage: "figure.run")
                        .foregroundColor(.green)
                }
                
                NavigationLink(value: SidebarSection.nutrition) {
                    Label("Nutrition", systemImage: "fork.knife")
                        .foregroundColor(.yellow)
                }
                
                NavigationLink(value: SidebarSection.mentalHealth) {
                    Label("Mental Health", systemImage: "brain")
                        .foregroundColor(.pink)
                }
            }
            
            // Health Management Section
            Section("Health Management") {
                NavigationLink(value: SidebarSection.medications) {
                    Label("Medications", systemImage: "pill.fill")
                        .foregroundColor(.mint)
                }
                
                NavigationLink(value: SidebarSection.family) {
                    Label("Family Health", systemImage: "person.3.fill")
                        .foregroundColor(.cyan)
                }
            }
            
            // Settings Section
            Section("Settings") {
                NavigationLink(value: SidebarSection.settings) {
                    Label("Settings", systemImage: "gear")
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
            
            // User Profile Section (Pinned to bottom)
            Section {
                UserProfileSection(showingProfile: $showingUserProfile)
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("HealthAI 2030")
        .sheet(isPresented: $showingUserProfile) {
            UserProfileView()
        }
    }
}

struct UserProfileSection: View {
    @Binding var showingProfile: Bool
    @EnvironmentObject var healthDataManager: HealthDataManager
    
    var body: some View {
        Button(action: {
            showingProfile = true
        }) {
            HStack(spacing: 12) {
                // Profile Image
                ZStack {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 40, height: 40)
                    
                    Text("JD")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("John Doe")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text("Premium Member")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct UserProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var healthDataManager: HealthDataManager
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Profile Header
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 100, height: 100)
                        
                        Text("JD")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    
                    VStack(spacing: 4) {
                        Text("John Doe")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("Premium Member")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Divider()
                
                // Quick Stats
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    StatCard(title: "Age", value: "32", icon: "person.fill")
                    StatCard(title: "Height", value: "5'10\"", icon: "ruler.fill")
                    StatCard(title: "Weight", value: "165 lbs", icon: "scalemass.fill")
                }
                
                Divider()
                
                // Health Summary
                VStack(alignment: .leading, spacing: 12) {
                    Text("Health Summary")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    VStack(spacing: 8) {
                        HealthSummaryRow(
                            title: "BMI",
                            value: "23.7",
                            status: "Normal",
                            color: .green
                        )
                        
                        HealthSummaryRow(
                            title: "Activity Level",
                            value: "Active",
                            status: "Good",
                            color: .blue
                        )
                        
                        HealthSummaryRow(
                            title: "Sleep Quality",
                            value: "7.5h",
                            status: "Good",
                            color: .purple
                        )
                    }
                }
                
                Spacer()
                
                // Action Buttons
                VStack(spacing: 12) {
                    Button("Edit Profile") {
                        // Edit profile action
                    }
                    .buttonStyle(.bordered)
                    .frame(maxWidth: .infinity)
                    
                    Button("Privacy Settings") {
                        // Privacy settings action
                    }
                    .buttonStyle(.bordered)
                    .frame(maxWidth: .infinity)
                    
                    Button("Sign Out") {
                        // Sign out action
                    }
                    .buttonStyle(.borderedProminent)
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(24)
            .navigationTitle("Profile")
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

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
            
            Text(value)
                .font(.headline)
                .fontWeight(.semibold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct HealthSummaryRow: View {
    let title: String
    let value: String
    let status: String
    let color: Color
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(value)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(status)
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(color.opacity(0.2))
                .foregroundColor(color)
                .cornerRadius(6)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    iPadSidebarView(selectedSection: .constant(.dashboard))
        .environmentObject(HealthDataManager.shared)
} 
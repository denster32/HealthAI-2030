import SwiftUI

struct SidebarView: View {
    @Binding var selectedSection: NavigationSection
    @State private var isCollapsed = false
    
    enum NavigationSection: String, CaseIterable {
        case dashboard = "Dashboard"
        case analytics = "Analytics"
        case healthData = "Health Data"
        case aiCopilot = "AI Copilot"
        case sleepTracking = "Sleep Tracking"
        case workouts = "Workouts"
        case nutrition = "Nutrition"
        case mentalHealth = "Mental Health"
        case medications = "Medications"
        case family = "Family Health"
        case settings = "Settings"
        
        var icon: String {
            switch self {
            case .dashboard: return "chart.bar.fill"
            case .analytics: return "chart.line.uptrend.xyaxis"
            case .healthData: return "heart.fill"
            case .aiCopilot: return "brain.head.profile"
            case .sleepTracking: return "bed.double.fill"
            case .workouts: return "figure.run"
            case .nutrition: return "fork.knife"
            case .mentalHealth: return "brain"
            case .medications: return "pill.fill"
            case .family: return "person.3.fill"
            case .settings: return "gear"
            }
        }
        
        var color: Color {
            switch self {
            case .dashboard: return .blue
            case .analytics: return .purple
            case .healthData: return .red
            case .aiCopilot: return .orange
            case .sleepTracking: return .indigo
            case .workouts: return .green
            case .nutrition: return .yellow
            case .mentalHealth: return .pink
            case .medications: return .mint
            case .family: return .cyan
            case .settings: return .gray
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            SidebarHeader(isCollapsed: $isCollapsed)
            
            // Navigation Sections
            ScrollView {
                LazyVStack(spacing: 4) {
                    ForEach(NavigationSection.allCases, id: \.self) { section in
                        SidebarNavigationItem(
                            section: section,
                            isSelected: selectedSection == section,
                            isCollapsed: isCollapsed
                        ) {
                            selectedSection = section
                        }
                    }
                }
                .padding(.horizontal, 8)
                .padding(.top, 8)
            }
            
            Spacer()
            
            // Footer
            SidebarFooter()
        }
        .frame(width: isCollapsed ? 60 : 250)
        .background(Color(.windowBackgroundColor))
        .animation(.easeInOut(duration: 0.3), value: isCollapsed)
    }
}

struct SidebarHeader: View {
    @Binding var isCollapsed: Bool
    
    var body: some View {
        HStack {
            if !isCollapsed {
                VStack(alignment: .leading, spacing: 4) {
                    Text("HealthAI 2030")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("Professional Dashboard")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            Button(action: {
                isCollapsed.toggle()
            }) {
                Image(systemName: isCollapsed ? "chevron.right" : "chevron.left")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(width: 20, height: 20)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 16)
        .background(Color(.controlBackgroundColor))
    }
}

struct SidebarNavigationItem: View {
    let section: SidebarView.NavigationSection
    let isSelected: Bool
    let isCollapsed: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: section.icon)
                    .font(.title3)
                    .foregroundColor(isSelected ? .white : section.color)
                    .frame(width: 20)
                
                if !isCollapsed {
                    Text(section.rawValue)
                        .font(.body)
                        .foregroundColor(isSelected ? .white : .primary)
                    
                    Spacer()
                    
                    if section == .aiCopilot {
                        // Notification badge for AI Copilot
                        Circle()
                            .fill(Color.red)
                            .frame(width: 8, height: 8)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(isSelected ? section.color : Color.clear)
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
        .help(isCollapsed ? section.rawValue : "")
    }
}

struct SidebarFooter: View {
    @State private var showingProfile = false
    
    var body: some View {
        VStack(spacing: 8) {
            Divider()
            
            HStack {
                // User Profile
                Button(action: {
                    showingProfile.toggle()
                }) {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 32, height: 32)
                            .overlay(
                                Text("JD")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.white)
                            )
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("John Doe")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                            
                            Text("Premium Member")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .popover(isPresented: $showingProfile) {
                    UserProfileView()
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .background(Color(.controlBackgroundColor))
    }
}

struct UserProfileView: View {
    var body: some View {
        VStack(spacing: 16) {
            // Profile Header
            VStack(spacing: 8) {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 64, height: 64)
                    .overlay(
                        Text("JD")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    )
                
                Text("John Doe")
                    .font(.title3)
                    .fontWeight(.semibold)
                
                Text("Premium Member")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Divider()
            
            // Quick Stats
            VStack(spacing: 12) {
                HStack {
                    StatItem(title: "Age", value: "32")
                    StatItem(title: "Height", value: "5'10\"")
                    StatItem(title: "Weight", value: "165 lbs")
                }
                
                HStack {
                    StatItem(title: "BMI", value: "23.7")
                    StatItem(title: "Activity", value: "Active")
                    StatItem(title: "Sleep", value: "7.5h")
                }
            }
            
            Divider()
            
            // Quick Actions
            VStack(spacing: 8) {
                Button("Edit Profile") {
                    // Edit profile action
                }
                .buttonStyle(.bordered)
                
                Button("Privacy Settings") {
                    // Privacy settings action
                }
                .buttonStyle(.bordered)
                
                Button("Sign Out") {
                    // Sign out action
                }
                .buttonStyle(.borderedProminent)
                .foregroundColor(.red)
            }
        }
        .padding()
        .frame(width: 300)
    }
}

struct StatItem: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.headline)
                .fontWeight(.semibold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    SidebarView(selectedSection: .constant(.dashboard))
} 
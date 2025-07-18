import SwiftUI
import HealthKit

/// Comprehensive Family Health Sharing & Monitoring View
/// Provides interface for family health management, alerts, goals, and caregiver tools
struct FamilyHealthSharingView: View {
    
    // MARK: - Properties
    
    @StateObject private var familyManager = FamilyHealthSharingManager()
    @State private var selectedTab: FamilyTab = .dashboard
    @State private var showingAddMember = false
    @State private var showingSettings = false
    @State private var selectedMember: FamilyMember?
    @State private var showingMemberDetail = false
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Tab Selection
                tabSelectionView
                
                // Content
                TabView(selection: $selectedTab) {
                    familyDashboardView
                        .tag(FamilyTab.dashboard)
                    
                    familyMembersView
                        .tag(FamilyTab.members)
                    
                    healthAlertsView
                        .tag(FamilyTab.alerts)
                    
                    sharedGoalsView
                        .tag(FamilyTab.goals)
                    
                    caregiverToolsView
                        .tag(FamilyTab.caregiver)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingAddMember) {
                AddFamilyMemberView(familyManager: familyManager)
            }
            .sheet(isPresented: $showingSettings) {
                FamilySettingsView(familyManager: familyManager)
            }
            .sheet(isPresented: $showingMemberDetail) {
                if let member = selectedMember {
                    FamilyMemberDetailView(member: member, familyManager: familyManager)
                }
            }
            .onAppear {
                Task {
                    await familyManager.updateFamilyHealthDashboard()
                    await familyManager.updateCaregiverTools()
                }
            }
        }
    }
    
    // MARK: - Header View
    
    private var headerView: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Family Health")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("\(familyManager.familyMembers.count) members • \(familyManager.familyHealthDashboard.activeMembers) active")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                HStack(spacing: 16) {
                    Button(action: { showingAddMember = true }) {
                        Image(systemName: "person.badge.plus")
                            .font(.title3)
                            .foregroundColor(.blue)
                    }
                    
                    Button(action: { showingSettings = true }) {
                        Image(systemName: "gearshape")
                            .font(.title3)
                            .foregroundColor(.blue)
                    }
                }
            }
            
            // Family Health Score
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Family Health Score")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("\(Int(familyManager.familyHealthDashboard.healthScore))")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(healthScoreColor)
                }
                
                Spacer()
                
                CircularProgressView(
                    progress: familyManager.familyHealthDashboard.healthScore / 100.0,
                    color: healthScoreColor
                )
                .frame(width: 60, height: 60)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .padding()
        .background(Color(.systemBackground))
    }
    
    // MARK: - Tab Selection View
    
    private var tabSelectionView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 20) {
                ForEach(FamilyTab.allCases, id: \.self) { tab in
                    Button(action: { selectedTab = tab }) {
                        VStack(spacing: 4) {
                            Image(systemName: tab.icon)
                                .font(.title3)
                                .foregroundColor(selectedTab == tab ? .blue : .secondary)
                            
                            Text(tab.title)
                                .font(.caption)
                                .fontWeight(selectedTab == tab ? .semibold : .regular)
                                .foregroundColor(selectedTab == tab ? .blue : .secondary)
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
    }
    
    // MARK: - Family Dashboard View
    
    private var familyDashboardView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Health Metrics Overview
                healthMetricsOverview
                
                // Family Members Status
                familyMembersStatus
                
                // Recent Alerts
                recentAlertsSection
                
                // Health Trends
                healthTrendsSection
                
                // Achievements
                achievementsSection
            }
            .padding()
        }
    }
    
    private var healthMetricsOverview: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Health Overview")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                HealthMetricCard(
                    title: "Heart Rate",
                    value: "\(Int(familyManager.familyHealthDashboard.averageHeartRate))",
                    unit: "BPM",
                    icon: "heart.fill",
                    color: .red
                )
                
                HealthMetricCard(
                    title: "Steps",
                    value: "\(familyManager.familyHealthDashboard.averageSteps)",
                    unit: "steps",
                    icon: "figure.walk",
                    color: .green
                )
                
                HealthMetricCard(
                    title: "Sleep",
                    value: String(format: "%.1f", familyManager.familyHealthDashboard.averageSleepHours),
                    unit: "hours",
                    icon: "bed.double.fill",
                    color: .blue
                )
                
                HealthMetricCard(
                    title: "Active",
                    value: "\(familyManager.familyHealthDashboard.activeMembers)",
                    unit: "members",
                    icon: "person.2.fill",
                    color: .orange
                )
            }
        }
    }
    
    private var familyMembersStatus: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Family Members")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("View All") {
                    selectedTab = .members
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(familyManager.familyMembers.prefix(5)) { member in
                        FamilyMemberCard(member: member) {
                            selectedMember = member
                            showingMemberDetail = true
                        }
                    }
                }
                .padding(.horizontal, 4)
            }
        }
    }
    
    private var recentAlertsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Alerts")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("View All") {
                    selectedTab = .alerts
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            
            if familyManager.healthAlerts.isEmpty {
                Text("No recent alerts")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                ForEach(familyManager.healthAlerts.prefix(3)) { alert in
                    HealthAlertRow(alert: alert) {
                        // Acknowledge alert
                        Task {
                            await familyManager.acknowledgeAlert(alert.id)
                        }
                    }
                }
            }
        }
    }
    
    private var healthTrendsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Health Trends")
                .font(.headline)
                .fontWeight(.semibold)
            
            if familyManager.familyHealthDashboard.healthTrends.isEmpty {
                Text("No trends available")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                ForEach(familyManager.familyHealthDashboard.healthTrends, id: \.metric) { trend in
                    HealthTrendRow(trend: trend)
                }
            }
        }
    }
    
    private var achievementsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Achievements")
                .font(.headline)
                .fontWeight(.semibold)
            
            if familyManager.familyHealthDashboard.achievements.isEmpty {
                Text("No recent achievements")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                ForEach(familyManager.familyHealthDashboard.achievements.prefix(3), id: \.title) { achievement in
                    AchievementRow(achievement: achievement)
                }
            }
        }
    }
    
    // MARK: - Family Members View
    
    private var familyMembersView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(familyManager.familyMembers) { member in
                    FamilyMemberRow(member: member) {
                        selectedMember = member
                        showingMemberDetail = true
                    }
                }
            }
            .padding()
        }
    }
    
    // MARK: - Health Alerts View
    
    private var healthAlertsView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                if familyManager.healthAlerts.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.circle")
                            .font(.system(size: 48))
                            .foregroundColor(.green)
                        
                        Text("No Health Alerts")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text("All family members are healthy!")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                } else {
                    ForEach(familyManager.healthAlerts) { alert in
                        HealthAlertCard(alert: alert) {
                            Task {
                                await familyManager.acknowledgeAlert(alert.id)
                            }
                        }
                    }
                }
            }
            .padding()
        }
    }
    
    // MARK: - Shared Goals View
    
    private var sharedGoalsView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                if familyManager.sharedGoals.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "target")
                            .font(.system(size: 48))
                            .foregroundColor(.blue)
                        
                        Text("No Shared Goals")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text("Create family health goals to stay motivated together")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Button("Create Goal") {
                            // TODO: Show create goal view
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                } else {
                    ForEach(familyManager.sharedGoals) { goal in
                        SharedGoalCard(goal: goal)
                    }
                }
            }
            .padding()
        }
    }
    
    // MARK: - Caregiver Tools View
    
    private var caregiverToolsView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Medication Management
                medicationManagementSection
                
                // Appointment Coordination
                appointmentCoordinationSection
                
                // Emergency Contacts
                emergencyContactsSection
                
                // Care Tasks
                careTasksSection
            }
            .padding()
        }
    }
    
    private var medicationManagementSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Medication Management")
                .font(.headline)
                .fontWeight(.semibold)
            
            if familyManager.caregiverTools.medications.isEmpty {
                Text("No medications tracked")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                ForEach(familyManager.caregiverTools.medications) { medication in
                    MedicationRow(medication: medication)
                }
            }
        }
    }
    
    private var appointmentCoordinationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Appointments")
                .font(.headline)
                .fontWeight(.semibold)
            
            if familyManager.caregiverTools.appointments.isEmpty {
                Text("No appointments scheduled")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                ForEach(familyManager.caregiverTools.appointments) { appointment in
                    AppointmentRow(appointment: appointment)
                }
            }
        }
    }
    
    private var emergencyContactsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Emergency Contacts")
                .font(.headline)
                .fontWeight(.semibold)
            
            if familyManager.caregiverTools.emergencyContacts.isEmpty {
                Text("No emergency contacts added")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                ForEach(familyManager.caregiverTools.emergencyContacts) { contact in
                    EmergencyContactRow(contact: contact)
                }
            }
        }
    }
    
    private var careTasksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Care Tasks")
                .font(.headline)
                .fontWeight(.semibold)
            
            if familyManager.caregiverTools.careTasks.isEmpty {
                Text("No care tasks assigned")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                ForEach(familyManager.caregiverTools.careTasks) { task in
                    CareTaskRow(task: task)
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var healthScoreColor: Color {
        let score = familyManager.familyHealthDashboard.healthScore
        switch score {
        case 80...100:
            return .green
        case 60..<80:
            return .yellow
        case 40..<60:
            return .orange
        default:
            return .red
        }
    }
}

// MARK: - Supporting Views

struct HealthMetricCard: View {
    let title: String
    let value: String
    let unit: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text(unit)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct FamilyMemberCard: View {
    let member: FamilyMember
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Circle()
                    .fill(member.isActive ? Color.green : Color.gray)
                    .frame(width: 50, height: 50)
                    .overlay(
                        Text(String(member.name.prefix(1)))
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                    )
                
                VStack(spacing: 2) {
                    Text(member.name)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text(member.relationship.rawValue)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: 80)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct HealthAlertRow: View {
    let alert: FamilyHealthAlert
    let onAcknowledge: () -> Void
    
    var body: some View {
        HStack {
            Circle()
                .fill(severityColor)
                .frame(width: 8, height: 8)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(alert.memberName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(alert.message)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            if !alert.isAcknowledged {
                Button("Acknowledge", action: onAcknowledge)
                    .font(.caption)
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
    
    private var severityColor: Color {
        switch alert.severity {
        case .low:
            return .green
        case .medium:
            return .yellow
        case .high:
            return .orange
        case .critical:
            return .red
        }
    }
}

struct HealthTrendRow: View {
    let trend: HealthTrend
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(trend.metric)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(trend.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(trend.trend)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(trend.change >= 0 ? .green : .red)
                
                Text("\(trend.change >= 0 ? "+" : "")\(String(format: "%.1f", trend.change))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

struct AchievementRow: View {
    let achievement: Achievement
    
    var body: some View {
        HStack {
            Image(systemName: "trophy.fill")
                .font(.title2)
                .foregroundColor(.yellow)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(achievement.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(achievement.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(achievement.achievedAt, style: .date)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

struct FamilyMemberRow: View {
    let member: FamilyMember
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Circle()
                    .fill(member.isActive ? Color.green : Color.gray)
                    .frame(width: 40, height: 40)
                    .overlay(
                        Text(String(member.name.prefix(1)))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(member.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text("\(member.age) years • \(member.relationship.rawValue)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct HealthAlertCard: View {
    let alert: FamilyHealthAlert
    let onAcknowledge: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: severityIcon)
                    .font(.title2)
                    .foregroundColor(severityColor)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(alert.alertType.rawValue)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text(alert.memberName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text(alert.timestamp, style: .time)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(alert.message)
                .font(.subheadline)
                .foregroundColor(.primary)
            
            if !alert.isAcknowledged {
                HStack {
                    Spacer()
                    
                    Button("Acknowledge", action: onAcknowledge)
                        .buttonStyle(.borderedProminent)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var severityIcon: String {
        switch alert.severity {
        case .low:
            return "info.circle"
        case .medium:
            return "exclamationmark.triangle"
        case .high:
            return "exclamationmark.triangle.fill"
        case .critical:
            return "xmark.octagon.fill"
        }
    }
    
    private var severityColor: Color {
        switch alert.severity {
        case .low:
            return .blue
        case .medium:
            return .yellow
        case .high:
            return .orange
        case .critical:
            return .red
        }
    }
}

struct SharedGoalCard: View {
    let goal: FamilyHealthGoal
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(goal.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text(goal.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if goal.isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.green)
                }
            }
            
            ProgressView(value: goal.currentProgress)
                .progressViewStyle(LinearProgressViewStyle(tint: goal.isCompleted ? .green : .blue))
            
            HStack {
                Text("\(Int(goal.currentProgress * 100))% Complete")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(goal.targetDate, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct MedicationRow: View {
    let medication: Medication
    
    var body: some View {
        HStack {
            Image(systemName: "pill.fill")
                .font(.title2)
                .foregroundColor(.blue)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(medication.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("\(medication.dosage) • \(medication.frequency)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

struct AppointmentRow: View {
    let appointment: FamilyAppointment
    
    var body: some View {
        HStack {
            Image(systemName: "calendar")
                .font(.title2)
                .foregroundColor(.green)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(appointment.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("\(appointment.date, style: .date) • \(appointment.location)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

struct EmergencyContactRow: View {
    let contact: EmergencyContact
    
    var body: some View {
        HStack {
            Image(systemName: "phone.fill")
                .font(.title2)
                .foregroundColor(.red)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(contact.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("\(contact.relationship) • \(contact.phoneNumber)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if contact.isPrimary {
                Text("Primary")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(4)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

struct CareTaskRow: View {
    let task: CareTask
    
    var body: some View {
        HStack {
            Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                .font(.title2)
                .foregroundColor(task.isCompleted ? .green : .gray)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .strikethrough(task.isCompleted)
                
                Text(task.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(task.dueDate, style: .date)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

struct CircularProgressView: View {
    let progress: Double
    let color: Color
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.3), lineWidth: 4)
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(color, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut, value: progress)
        }
    }
}

// MARK: - Supporting Types

enum FamilyTab: CaseIterable {
    case dashboard, members, alerts, goals, caregiver
    
    var title: String {
        switch self {
        case .dashboard:
            return "Dashboard"
        case .members:
            return "Members"
        case .alerts:
            return "Alerts"
        case .goals:
            return "Goals"
        case .caregiver:
            return "Care"
        }
    }
    
    var icon: String {
        switch self {
        case .dashboard:
            return "chart.bar.fill"
        case .members:
            return "person.2.fill"
        case .alerts:
            return "exclamationmark.triangle.fill"
        case .goals:
            return "target"
        case .caregiver:
            return "heart.fill"
        }
    }
}

// MARK: - Preview

struct FamilyHealthSharingView_Previews: PreviewProvider {
    static var previews: some View {
        FamilyHealthSharingView()
    }
} 
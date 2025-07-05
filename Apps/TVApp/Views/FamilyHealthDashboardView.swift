import SwiftUI
import SwiftData
import Charts

@available(tvOS 18.0, *)
struct FamilyHealthDashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var familyMembers: [FamilyMember]
    @Query private var healthRecords: [HealthData]
    
    @State private var selectedMember: FamilyMember?
    @State private var showingAddMember = false
    @State private var selectedTimeRange: TimeRange = .week
    @State private var focusState: FocusState<DashboardSection?> = .init()
    
    enum TimeRange: String, CaseIterable {
        case day = "Today"
        case week = "This Week"
        case month = "This Month"
        case year = "This Year"
    }
    
    enum DashboardSection: Hashable {
        case familyOverview
        case healthSummary
        case alerts
        case activities
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 40) {
                // Header
                DashboardHeader(
                    selectedTimeRange: $selectedTimeRange,
                    showingAddMember: $showingAddMember
                )
                
                // Family Overview
                FamilyOverviewSection(
                    familyMembers: familyMembers,
                    selectedMember: $selectedMember,
                    focusState: $focusState
                )
                
                // Health Summary
                HealthSummarySection(
                    healthRecords: healthRecords,
                    selectedMember: selectedMember,
                    timeRange: selectedTimeRange
                )
                
                // Health Alerts
                HealthAlertsSection(familyMembers: familyMembers)
                
                // Family Activities
                FamilyActivitiesSection(familyMembers: familyMembers)
            }
            .padding(.horizontal, 60)
            .padding(.vertical, 40)
        }
        .background(Color(.systemBackground))
        .sheet(isPresented: $showingAddMember) {
            AddFamilyMemberView()
        }
        .onAppear {
            if selectedMember == nil && !familyMembers.isEmpty {
                selectedMember = familyMembers.first
            }
        }
    }
}

struct DashboardHeader: View {
    @Binding var selectedTimeRange: FamilyHealthDashboardView.TimeRange
    @Binding var showingAddMember: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Family Health Dashboard")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Monitor your family's health and wellness")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(spacing: 12) {
                    // Time Range Picker
                    Picker("Time Range", selection: $selectedTimeRange) {
                        ForEach(FamilyHealthDashboardView.TimeRange.allCases, id: \.self) { range in
                            Text(range.rawValue).tag(range)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .frame(width: 400)
                    
                    // Add Family Member Button
                    Button(action: {
                        showingAddMember = true
                    }) {
                        HStack {
                            Image(systemName: "person.badge.plus")
                            Text("Add Family Member")
                        }
                        .font(.headline)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .buttonStyle(CardButtonStyle())
                }
            }
            
            // Quick Stats
            QuickStatsRow()
        }
    }
}

struct QuickStatsRow: View {
    var body: some View {
        HStack(spacing: 30) {
            QuickStatCard(
                title: "Family Members",
                value: "4",
                icon: "person.3.fill",
                color: .blue
            )
            
            QuickStatCard(
                title: "Active Today",
                value: "3",
                icon: "checkmark.circle.fill",
                color: .green
            )
            
            QuickStatCard(
                title: "Health Alerts",
                value: "1",
                icon: "exclamationmark.triangle.fill",
                color: .orange
            )
            
            QuickStatCard(
                title: "Activities",
                value: "8",
                icon: "figure.run",
                color: .purple
            )
        }
    }
}

struct QuickStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
            
            Text(title)
                .font(.headline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(width: 200, height: 150)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(20)
    }
}

struct FamilyOverviewSection: View {
    let familyMembers: [FamilyMember]
    @Binding var selectedMember: FamilyMember?
    @Binding var focusState: FocusState<FamilyHealthDashboardView.DashboardSection?>
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Family Overview")
                .font(.title)
                .fontWeight(.bold)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 30) {
                    ForEach(familyMembers) { member in
                        FamilyMemberCard(
                            member: member,
                            isSelected: selectedMember?.id == member.id
                        ) {
                            selectedMember = member
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
}

struct FamilyMemberCard: View {
    let member: FamilyMember
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 16) {
                // Profile Image
                ZStack {
                    Circle()
                        .fill(member.profileColor)
                        .frame(width: 120, height: 120)
                    
                    Text(member.initials)
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.white)
                }
                
                // Member Info
                VStack(spacing: 8) {
                    Text(member.name)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text(member.relationship)
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text("\(member.age) years old")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                // Health Status
                HStack(spacing: 16) {
                    HealthStatusIndicator(
                        title: "Heart",
                        value: member.heartRate,
                        unit: "BPM",
                        color: .red
                    )
                    
                    HealthStatusIndicator(
                        title: "Steps",
                        value: member.dailySteps,
                        unit: "steps",
                        color: .green
                    )
                }
            }
            .frame(width: 280, height: 400)
            .background(isSelected ? Color.blue.opacity(0.1) : Color(.secondarySystemBackground))
            .cornerRadius(24)
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 4)
            )
        }
        .buttonStyle(CardButtonStyle())
    }
}

struct HealthStatusIndicator: View {
    let title: String
    let value: Int
    let unit: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("\(value)")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(unit)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

struct HealthSummarySection: View {
    let healthRecords: [HealthData]
    let selectedMember: FamilyMember?
    let timeRange: FamilyHealthDashboardView.TimeRange
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("Health Summary")
                    .font(.title)
                    .fontWeight(.bold)
                
                if let member = selectedMember {
                    Text("• \(member.name)")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 30) {
                HealthMetricCard(
                    title: "Heart Rate",
                    value: "72",
                    unit: "BPM",
                    icon: "heart.fill",
                    color: .red,
                    trend: "+2",
                    trendDirection: .up
                )
                
                HealthMetricCard(
                    title: "Daily Steps",
                    value: "8,234",
                    unit: "steps",
                    icon: "figure.walk",
                    color: .green,
                    trend: "+12%",
                    trendDirection: .up
                )
                
                HealthMetricCard(
                    title: "Sleep",
                    value: "7.5",
                    unit: "hours",
                    icon: "bed.double.fill",
                    color: .blue,
                    trend: "-0.3",
                    trendDirection: .down
                )
                
                HealthMetricCard(
                    title: "Calories",
                    value: "2,145",
                    unit: "kcal",
                    icon: "flame.fill",
                    color: .orange,
                    trend: "+8%",
                    trendDirection: .up
                )
            }
        }
    }
}

struct HealthMetricCard: View {
    let title: String
    let value: String
    let unit: String
    let icon: String
    let color: Color
    let trend: String
    let trendDirection: TrendDirection
    
    enum TrendDirection {
        case up, down, neutral
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 32))
                    .foregroundColor(color)
                
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: trendDirection == .up ? "arrow.up.right" : "arrow.down.right")
                        .font(.caption)
                        .foregroundColor(trendDirection == .up ? .green : .red)
                    
                    Text(trend)
                        .font(.caption)
                        .foregroundColor(trendDirection == .up ? .green : .red)
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .bottom, spacing: 4) {
                    Text(value)
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Text(unit)
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                
                Text(title)
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
        }
        .padding(24)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(20)
    }
}

struct HealthAlertsSection: View {
    let familyMembers: [FamilyMember]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Health Alerts")
                .font(.title)
                .fontWeight(.bold)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 30) {
                HealthAlertCard(
                    member: familyMembers.first,
                    alertType: .medication,
                    message: "Time to take evening medication",
                    severity: .medium
                )
                
                HealthAlertCard(
                    member: familyMembers.last,
                    alertType: .exercise,
                    message: "Daily exercise goal not met",
                    severity: .low
                )
            }
        }
    }
}

struct HealthAlertCard: View {
    let member: FamilyMember?
    let alertType: AlertType
    let message: String
    let severity: AlertSeverity
    
    enum AlertType {
        case medication, exercise, appointment, vital
        
        var icon: String {
            switch self {
            case .medication: return "pill.fill"
            case .exercise: return "figure.run"
            case .appointment: return "calendar"
            case .vital: return "heart.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .medication: return .orange
            case .exercise: return .blue
            case .appointment: return .purple
            case .vital: return .red
            }
        }
    }
    
    enum AlertSeverity {
        case low, medium, high
        
        var color: Color {
            switch self {
            case .low: return .green
            case .medium: return .orange
            case .high: return .red
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: alertType.icon)
                    .font(.system(size: 24))
                    .foregroundColor(alertType.color)
                
                Spacer()
                
                Circle()
                    .fill(severity.color)
                    .frame(width: 12, height: 12)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                if let member = member {
                    Text(member.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Button("View Details") {
                // Show alert details
            }
            .font(.caption)
            .foregroundColor(alertType.color)
        }
        .padding(20)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }
}

struct FamilyActivitiesSection: View {
    let familyMembers: [FamilyMember]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Family Activities")
                .font(.title)
                .fontWeight(.bold)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 30) {
                    ActivityCard(
                        title: "Morning Walk",
                        participants: ["John", "Sarah"],
                        time: "7:00 AM",
                        icon: "figure.walk",
                        color: .green
                    )
                    
                    ActivityCard(
                        title: "Family Dinner",
                        participants: ["All"],
                        time: "6:30 PM",
                        icon: "fork.knife",
                        color: .orange
                    )
                    
                    ActivityCard(
                        title: "Meditation",
                        participants: ["John", "Emma"],
                        time: "8:00 PM",
                        icon: "brain.head.profile",
                        color: .purple
                    )
                    
                    ActivityCard(
                        title: "Bedtime",
                        participants: ["Emma", "Liam"],
                        time: "9:00 PM",
                        icon: "bed.double.fill",
                        color: .blue
                    )
                }
                .padding(.horizontal, 20)
            }
        }
    }
}

struct ActivityCard: View {
    let title: String
    let participants: [String]
    let time: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 32))
                    .foregroundColor(color)
                
                Spacer()
                
                Text(time)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(participants.joined(separator: ", "))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .frame(width: 250, height: 150)
        .padding(20)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }
}

struct AddFamilyMemberView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var name = ""
    @State private var relationship = ""
    @State private var age = ""
    @State private var selectedColor = Color.blue
    
    let colors: [Color] = [.blue, .green, .orange, .purple, .pink, .red]
    
    var body: some View {
        VStack(spacing: 30) {
            Text("Add Family Member")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            VStack(spacing: 20) {
                TextField("Name", text: $name)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .font(.title2)
                
                TextField("Relationship", text: $relationship)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .font(.title2)
                
                TextField("Age", text: $age)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .font(.title2)
                    .keyboardType(.numberPad)
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("Profile Color")
                        .font(.headline)
                    
                    HStack(spacing: 15) {
                        ForEach(colors, id: \.self) { color in
                            Circle()
                                .fill(color)
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Circle()
                                        .stroke(selectedColor == color ? Color.white : Color.clear, lineWidth: 3)
                                )
                                .onTapGesture {
                                    selectedColor = color
                                }
                        }
                    }
                }
            }
            .frame(maxWidth: 400)
            
            HStack(spacing: 20) {
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.bordered)
                
                Button("Add Member") {
                    addFamilyMember()
                }
                .buttonStyle(.borderedProminent)
                .disabled(name.isEmpty || relationship.isEmpty || age.isEmpty)
            }
        }
        .padding(40)
        .background(Color(.systemBackground))
    }
    
    private func addFamilyMember() {
        guard let ageInt = Int(age) else { return }
        
        let member = FamilyMember(
            name: name,
            relationship: relationship,
            age: ageInt,
            profileColor: selectedColor
        )
        
        modelContext.insert(member)
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Failed to save family member: \(error)")
        }
    }
}

struct CardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Data Models

@Model
class FamilyMember {
    var id: UUID
    var name: String
    var relationship: String
    var age: Int
    var profileColor: Color
    var heartRate: Int
    var dailySteps: Int
    
    init(name: String, relationship: String, age: Int, profileColor: Color) {
        self.id = UUID()
        self.name = name
        self.relationship = relationship
        self.age = age
        self.profileColor = profileColor
        self.heartRate = Int.random(in: 60...100)
        self.dailySteps = Int.random(in: 5000...15000)
    }
    
    var initials: String {
        let components = name.components(separatedBy: " ")
        return components.prefix(2).compactMap { $0.first }.map(String.init).joined()
    }
}

#Preview {
    FamilyHealthDashboardView()
}

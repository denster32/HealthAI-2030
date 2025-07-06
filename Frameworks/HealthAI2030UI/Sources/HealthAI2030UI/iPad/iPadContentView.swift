import SwiftUI

struct iPadContentView: View {
    let section: SidebarSection?
    @Binding var selectedItem: HealthItem?
    
    var body: some View {
        VStack {
            switch section {
            case .healthData:
                HealthCategoryListView(selection: $selectedItem)
            case .aiCopilot:
                ConversationListView(selection: $selectedItem)
            case .workouts:
                WorkoutListView(selection: $selectedItem)
            case .sleepTracking:
                SleepSessionListView(selection: $selectedItem)
            case .medications:
                MedicationListView(selection: $selectedItem)
            case .family:
                FamilyMemberListView(selection: $selectedItem)
            case .dashboard, .analytics, .nutrition, .mentalHealth, .settings:
                SinglePaneView(section: section)
            case .none:
                ContentUnavailableView("Select a Section", systemImage: "sidebar.left")
            }
        }
        .navigationTitle(section?.rawValue ?? "Content")
    }
}

// MARK: - Health Category List View

struct HealthCategoryListView: View {
    @Binding var selection: HealthItem?
    
    var body: some View {
        List(HealthCategory.allCases, id: \.self) { category in
            HealthCategoryRow(category: category)
                .contentShape(Rectangle())
                .onTapGesture {
                    selection = HealthItem(
                        title: category.rawValue,
                        subtitle: "View detailed data and trends",
                        type: .healthCategory(category),
                        icon: category.icon,
                        color: category.color
                    )
                }
        }
        .listStyle(.plain)
    }
}

struct HealthCategoryRow: View {
    let category: HealthCategory
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: category.icon)
                .font(.title2)
                .foregroundColor(category.color)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(category.rawValue)
                    .font(.headline)
                    .fontWeight(.medium)
                
                Text("View detailed data and trends")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Conversation List View

struct ConversationListView: View {
    @Binding var selection: HealthItem?
    
    // Sample conversations - in real app, this would come from a data manager
    private let conversations = [
        ("Morning Check-in", "How are you feeling today?", "2 hours ago"),
        ("Workout Planning", "Let's plan your weekly exercise routine", "1 day ago"),
        ("Sleep Analysis", "Your sleep patterns show improvement", "3 days ago"),
        ("Nutrition Advice", "Here are some healthy meal suggestions", "1 week ago")
    ]
    
    var body: some View {
        List {
            ForEach(Array(conversations.enumerated()), id: \.offset) { index, conversation in
                ConversationRow(
                    title: conversation.0,
                    preview: conversation.1,
                    time: conversation.2
                )
                .contentShape(Rectangle())
                .onTapGesture {
                    selection = HealthItem(
                        title: conversation.0,
                        subtitle: conversation.1,
                        type: .conversation("conversation_\(index)"),
                        icon: "message.fill",
                        color: .blue
                    )
                }
            }
        }
        .listStyle(.plain)
    }
}

struct ConversationRow: View {
    let title: String
    let preview: String
    let time: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.headline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text(time)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(preview)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(2)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Workout List View

struct WorkoutListView: View {
    @Binding var selection: HealthItem?
    
    var body: some View {
        List(WorkoutType.allCases, id: \.self) { workoutType in
            WorkoutTypeRow(workoutType: workoutType)
                .contentShape(Rectangle())
                .onTapGesture {
                    selection = HealthItem(
                        title: workoutType.rawValue,
                        subtitle: "View workout history and plans",
                        type: .workout(workoutType),
                        icon: workoutType.icon,
                        color: .green
                    )
                }
        }
        .listStyle(.plain)
    }
}

struct WorkoutTypeRow: View {
    let workoutType: WorkoutType
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: workoutType.icon)
                .font(.title2)
                .foregroundColor(.green)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(workoutType.rawValue)
                    .font(.headline)
                    .fontWeight(.medium)
                
                Text("View workout history and plans")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Sleep Session List View

struct SleepSessionListView: View {
    @Binding var selection: HealthItem?
    
    // Sample sleep sessions - in real app, this would come from HealthKit
    private let sleepSessions = [
        ("Last Night", "7.5 hours", "Good quality", "12 hours ago"),
        ("2 Nights Ago", "6.8 hours", "Fair quality", "2 days ago"),
        ("3 Nights Ago", "8.2 hours", "Excellent quality", "3 days ago"),
        ("4 Nights Ago", "7.1 hours", "Good quality", "4 days ago")
    ]
    
    var body: some View {
        List {
            ForEach(Array(sleepSessions.enumerated()), id: \.offset) { index, session in
                SleepSessionRow(
                    title: session.0,
                    duration: session.1,
                    quality: session.2,
                    time: session.3
                )
                .contentShape(Rectangle())
                .onTapGesture {
                    selection = HealthItem(
                        title: session.0,
                        subtitle: "\(session.1) - \(session.2)",
                        type: .sleepSession(Date().addingTimeInterval(-Double(index * 24 * 3600))),
                        icon: "bed.double.fill",
                        color: .blue
                    )
                }
            }
        }
        .listStyle(.plain)
    }
}

struct SleepSessionRow: View {
    let title: String
    let duration: String
    let quality: String
    let time: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.headline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text(time)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Text(duration)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("•")
                    .foregroundColor(.secondary)
                
                Text(quality)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Medication List View

struct MedicationListView: View {
    @Binding var selection: HealthItem?
    
    // Sample medications - in real app, this would come from a medication manager
    private let medications = [
        ("Vitamin D", "1000 IU", "Daily", "Morning"),
        ("Omega-3", "1000mg", "Daily", "Evening"),
        ("Blood Pressure Med", "10mg", "Twice daily", "Morning & Evening"),
        ("Sleep Aid", "5mg", "As needed", "Bedtime")
    ]
    
    var body: some View {
        List {
            ForEach(Array(medications.enumerated()), id: \.offset) { index, medication in
                MedicationRow(
                    name: medication.0,
                    dosage: medication.1,
                    frequency: medication.2,
                    time: medication.3
                )
                .contentShape(Rectangle())
                .onTapGesture {
                    selection = HealthItem(
                        title: medication.0,
                        subtitle: "\(medication.1) - \(medication.2)",
                        type: .medication(medication.0),
                        icon: "pill.fill",
                        color: .mint
                    )
                }
            }
        }
        .listStyle(.plain)
    }
}

struct MedicationRow: View {
    let name: String
    let dosage: String
    let frequency: String
    let time: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(name)
                    .font(.headline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text(time)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Text(dosage)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("•")
                    .foregroundColor(.secondary)
                
                Text(frequency)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Family Member List View

struct FamilyMemberListView: View {
    @Binding var selection: HealthItem?
    
    // Sample family members - in real app, this would come from a family manager
    private let familyMembers = [
        ("John Doe", "Father", "32 years old"),
        ("Jane Doe", "Mother", "30 years old"),
        ("Emma Doe", "Daughter", "8 years old"),
        ("Liam Doe", "Son", "5 years old")
    ]
    
    var body: some View {
        List {
            ForEach(Array(familyMembers.enumerated()), id: \.offset) { index, member in
                FamilyMemberRow(
                    name: member.0,
                    relationship: member.1,
                    age: member.2
                )
                .contentShape(Rectangle())
                .onTapGesture {
                    selection = HealthItem(
                        title: member.0,
                        subtitle: "\(member.1) - \(member.2)",
                        type: .familyMember(member.0),
                        icon: "person.fill",
                        color: .cyan
                    )
                }
            }
        }
        .listStyle(.plain)
    }
}

struct FamilyMemberRow: View {
    let name: String
    let relationship: String
    let age: String
    
    var body: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(Color.cyan)
                .frame(width: 40, height: 40)
                .overlay(
                    Text(String(name.prefix(2)))
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.headline)
                    .fontWeight(.medium)
                
                Text("\(relationship) • \(age)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Single Pane View

struct SinglePaneView: View {
    let section: SidebarSection?
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: section?.icon ?? "questionmark.circle")
                .font(.system(size: 60))
                .foregroundColor(section?.color ?? .gray)
            
            Text(section?.rawValue ?? "Unknown Section")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("This section provides a comprehensive view of your \(section?.rawValue.lowercased() ?? "data"). Select items from the sidebar to view detailed information.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Spacer()
        }
        .padding()
    }
}

#Preview {
    iPadContentView(section: .healthData, selectedItem: .constant(nil))
} 
import SwiftUI
import Charts
import Combine

/// SwiftUI view for Health Goal Engine
/// Allows users to create, view, and track health goals with analytics
public struct HealthGoalEngineView: View {
    @StateObject private var manager = HealthGoalEngineManager.shared
    @State private var selectedTab = 0
    @State private var newGoalTitle = ""
    @State private var newGoalDescription = ""
    @State private var newGoalType: HealthGoalEngineManager.GoalType = .steps
    @State private var newGoalTarget: Double = 10000
    @State private var newGoalUnit = "steps"
    @State private var newGoalEndDate: Date? = nil
    @State private var showGoalCreation = false
    @State private var selectedGoal: HealthGoalEngineManager.HealthGoal?
    @State private var userId = "user123"
    @State private var newProgressValue: Double = 0.0
    @State private var showProgressUpdate = false
    
    public init() {}
    
    public var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                tabSelectionView
                
                TabView(selection: $selectedTab) {
                    goalsTabView
                        .tag(0)
                    
                    progressTabView
                        .tag(1)
                    
                    analyticsTabView
                        .tag(2)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .navigationTitle(NSLocalizedString("Health Goals", comment: "Navigation title for health goals"))
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showGoalCreation = true }) {
                        Image(systemName: "plus.circle")
                    }
                }
            }
        }
        .sheet(isPresented: $showGoalCreation) {
            goalCreationSheet
        }
    }
    
    // MARK: - Tab Selection
    private var tabSelectionView: some View {
        HStack(spacing: 0) {
            ForEach([NSLocalizedString("Goals", comment: "Goals tab"), NSLocalizedString("Progress", comment: "Progress tab"), NSLocalizedString("Analytics", comment: "Analytics tab")], id: \.self) { tab in
                Button(action: {
                    withAnimation {
                        selectedTab = [NSLocalizedString("Goals", comment: "Goals tab"), NSLocalizedString("Progress", comment: "Progress tab"), NSLocalizedString("Analytics", comment: "Analytics tab")].firstIndex(of: tab) ?? 0
                    }
                }) {
                    VStack(spacing: 4) {
                        Text(tab)
                            .font(.subheadline)
                            .fontWeight(selectedTab == [NSLocalizedString("Goals", comment: "Goals tab"), NSLocalizedString("Progress", comment: "Progress tab"), NSLocalizedString("Analytics", comment: "Analytics tab")].firstIndex(of: tab) ? .semibold : .regular)
                            .foregroundColor(selectedTab == [NSLocalizedString("Goals", comment: "Goals tab"), NSLocalizedString("Progress", comment: "Progress tab"), NSLocalizedString("Analytics", comment: "Analytics tab")].firstIndex(of: tab) ? .primary : .secondary)
                        Rectangle()
                            .fill(selectedTab == [NSLocalizedString("Goals", comment: "Goals tab"), NSLocalizedString("Progress", comment: "Progress tab"), NSLocalizedString("Analytics", comment: "Analytics tab")].firstIndex(of: tab) ? Color.blue : Color.clear)
                            .frame(height: 2)
                    }
                    .frame(width: 100)
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
    
    // MARK: - Goals Tab
    private var goalsTabView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                ForEach(manager.goalsForUser(userId: userId)) { goal in
                    goalCardView(for: goal)
                }
            }
            .padding()
        }
    }
    
    // MARK: - Progress Tab
    private var progressTabView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                ForEach(manager.goalsForUser(userId: userId)) { goal in
                    if let progress = manager.getProgress(goalId: goal.id) {
                        ProgressCardView(goal: goal, progress: progress)
                    }
                }
            }
            .padding()
        }
    }
    
    // MARK: - Analytics Tab
    private var analyticsTabView: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                // Goal Completion Rate
                VStack(alignment: .leading, spacing: 12) {
                    Text(NSLocalizedString("Goal Completion Rate", comment: "Goal completion rate chart title"))
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(Int(completionRate * 100))%")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                            Text(NSLocalizedString("Completion Rate", comment: "Completion rate label"))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        CircularProgressView(progress: completionRate)
                            .frame(width: 60, height: 60)
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                
                // Goal Type Distribution
                VStack(alignment: .leading, spacing: 12) {
                    Text(NSLocalizedString("Goal Type Distribution", comment: "Goal type distribution chart title"))
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    ForEach(Array(goalTypeDistribution.keys.sorted()), id: \.self) { type in
                        HStack {
                            Text(type.rawValue)
                                .font(.subheadline)
                            Spacer()
                            Text("\(goalTypeDistribution[type] ?? 0)")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }
                        .padding(.vertical, 4)
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                
                // Recent Activity
                VStack(alignment: .leading, spacing: 12) {
                    Text(NSLocalizedString("Recent Activity", comment: "Recent activity section title"))
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    ForEach(recentActivity.prefix(5), id: \.id) { activity in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(activity.description)
                                    .font(.subheadline)
                                Text(activity.timestamp, style: .relative)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Text(activity.type.rawValue)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .cornerRadius(8)
                        }
                        .padding(.vertical, 4)
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
            }
            .padding()
        }
    }
    
    // MARK: - Goal Creation Sheet
    private var goalCreationSheet: some View {
        NavigationView {
            Form {
                TextField(NSLocalizedString("Title", comment: "Goal title field"), text: $newGoalTitle)
                TextField(NSLocalizedString("Description", comment: "Goal description field"), text: $newGoalDescription)
                Picker(NSLocalizedString("Type", comment: "Goal type picker"), selection: $newGoalType) {
                    ForEach(HealthGoalEngineManager.GoalType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                TextField(NSLocalizedString("Target Value", comment: "Goal target value field"), value: $newGoalTarget, formatter: NumberFormatter())
                    .keyboardType(.decimalPad)
                TextField(NSLocalizedString("Unit", comment: "Goal unit field"), text: $newGoalUnit)
                DatePicker(NSLocalizedString("End Date", comment: "Goal end date picker"), selection: Binding($newGoalEndDate, Date()), displayedComponents: .date)
                Button(NSLocalizedString("Create Goal", comment: "Create goal button")) {
                    createGoal()
                }
                .disabled(newGoalTitle.isEmpty || newGoalTarget <= 0)
            }
            .navigationTitle(NSLocalizedString("New Goal", comment: "New goal sheet title"))
            .navigationBarItems(trailing: Button(NSLocalizedString("Cancel", comment: "Cancel button")) { showGoalCreation = false })
        }
    }
    
    // MARK: - Goal Card View
    private func goalCardView(for goal: HealthGoalEngineManager.HealthGoal) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(goal.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                    Text(goal.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Text(goal.type.rawValue)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .foregroundColor(.blue)
                    .cornerRadius(8)
            }
            
            ProgressView(value: goal.progress, total: 1.0)
                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
            
            HStack {
                Text(NSLocalizedString("Progress", comment: "Progress label"))
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(Int(goal.progress * 100))%")
                    .font(.caption)
                    .fontWeight(.semibold)
            }
            
            HStack {
                Text(NSLocalizedString("Target", comment: "Target label"))
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(goal.target, specifier: "%.1f") \(goal.unit)")
                    .font(.caption)
                    .fontWeight(.semibold)
            }
            
            HStack {
                Text(NSLocalizedString("End Date", comment: "End date label"))
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text(goal.endDate, style: .date)
                    .font(.caption)
                    .fontWeight(.semibold)
            }
            
            HStack {
                Button(NSLocalizedString("Update Progress", comment: "Update progress button")) {
                    selectedGoal = goal
                    showProgressUpdate = true
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                
                Spacer()
                
                Button(NSLocalizedString("Delete", comment: "Delete button")) {
                    deleteGoal(goal)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .foregroundColor(.red)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    // MARK: - Progress Update Sheet
    private var progressUpdateSheet: some View {
        NavigationView {
            Form {
                if let goal = selectedGoal {
                    Text(NSLocalizedString("Update Progress for", comment: "Update progress label"))
                        .font(.headline)
                    Text(goal.title)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Text(NSLocalizedString("Current Progress", comment: "Current progress label"))
                        Spacer()
                        Text("\(Int(goal.progress * 100))%")
                            .fontWeight(.semibold)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text(NSLocalizedString("New Progress Value", comment: "New progress value label"))
                            .font(.subheadline)
                        TextField(NSLocalizedString("Enter new value", comment: "New progress value placeholder"), value: $newProgressValue, formatter: NumberFormatter())
                            .keyboardType(.decimalPad)
                        Text(NSLocalizedString("Unit", comment: "Unit label"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(goal.unit)
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    
                    Button(NSLocalizedString("Update Progress", comment: "Update progress button")) {
                        updateProgress()
                    }
                    .disabled(newProgressValue <= 0)
                }
            }
            .navigationTitle(NSLocalizedString("Update Progress", comment: "Update progress sheet title"))
            .navigationBarItems(trailing: Button(NSLocalizedString("Cancel", comment: "Cancel button")) { showProgressUpdate = false })
        }
    }
    
    // MARK: - Helper Methods
    private func createGoal() {
        let goal = HealthGoalEngineManager.HealthGoal(
            title: newGoalTitle,
            description: newGoalDescription,
            type: newGoalType,
            targetValue: newGoalTarget,
            unit: newGoalUnit,
            endDate: newGoalEndDate,
            userId: userId
        )
        manager.createGoal(goal)
        showGoalCreation = false
        newGoalTitle = ""
        newGoalDescription = ""
        newGoalTarget = 10000
        newGoalUnit = "steps"
        newGoalEndDate = nil
    }
    
    private func deleteGoal(_ goal: HealthGoalEngineManager.HealthGoal) {
        manager.deleteGoal(goal)
    }
    
    private func updateProgress() {
        // Implementation of updateProgress method
    }
}

// MARK: - Supporting Views

struct GoalCardView: View {
    let goal: HealthGoalEngineManager.HealthGoal
    let onTap: () -> Void
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(goal.title)
                        .font(.headline)
                    Spacer()
                    Text(goal.type.rawValue)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Text(goal.description)
                    .font(.body)
                HStack {
                    Text("Target: \(goal.targetValue, specifier: "%.0f") \(goal.unit)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(goal.startDate, style: .date)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(8)
            .shadow(radius: 1)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ProgressCardView: View {
    let goal: HealthGoalEngineManager.HealthGoal
    let progress: HealthGoalEngineManager.GoalProgress
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(goal.title)
                    .font(.headline)
                Spacer()
                Text(progress.isCompleted ? "Completed" : "In Progress")
                    .font(.caption)
                    .foregroundColor(progress.isCompleted ? .green : .orange)
            }
            ProgressView(value: progress.currentValue, total: goal.targetValue)
            HStack {
                Text("\(progress.currentValue, specifier: "%.0f") / \(goal.targetValue, specifier: "%.0f") \(goal.unit)")
                    .font(.caption)
                Spacer()
                Text(progress.lastUpdated, style: .relative)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .shadow(radius: 1)
    }
}

struct AnalyticsCardView: View {
    let goal: HealthGoalEngineManager.HealthGoal
    let analytics: HealthGoalEngineManager.GoalAnalytics
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(goal.title)
                    .font(.headline)
                Spacer()
                Text("Streak: \(analytics.streak)")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
            HStack {
                Text("Completion Rate: \(Int(analytics.completionRate * 100))%")
                    .font(.caption)
                Spacer()
                Text("Avg Progress: \(analytics.averageProgress, specifier: "%.0f")")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .shadow(radius: 1)
    }
}

#Preview {
    HealthGoalEngineView()
} 
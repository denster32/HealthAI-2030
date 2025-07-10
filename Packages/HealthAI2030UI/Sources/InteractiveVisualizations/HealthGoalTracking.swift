import SwiftUI
import Charts

// MARK: - Health Goal Tracking
/// Comprehensive health goal tracking components for progress visualization and achievement monitoring
/// Provides interactive goal tracking, progress visualization, and achievement celebration features
public struct HealthGoalTracking {
    
    // MARK: - Goal Dashboard
    
    /// Main dashboard for tracking all health goals
    public struct GoalDashboard: View {
        let goals: [HealthGoal]
        let progressData: [GoalProgress]
        @State private var selectedGoal: HealthGoal?
        @State private var showingAddGoal: Bool = false
        @State private var filterCategory: GoalCategory = .all
        
        public init(
            goals: [HealthGoal],
            progressData: [GoalProgress] = []
        ) {
            self.goals = goals
            self.progressData = progressData
        }
        
        public var body: some View {
            VStack(spacing: 20) {
                // Dashboard Header
                HStack {
                    Text("Health Goals")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    Button(action: { showingAddGoal = true }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.blue)
                            .font(.title2)
                    }
                }
                .padding(.horizontal)
                
                // Category Filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(GoalCategory.allCases, id: \.self) { category in
                            CategoryFilterButton(
                                category: category,
                                isSelected: filterCategory == category,
                                action: { filterCategory = category }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Goals Overview
                GoalsOverviewGrid(
                    goals: filteredGoals,
                    progressData: progressData
                )
                .padding(.horizontal)
                
                // Progress Chart
                if !filteredGoals.isEmpty {
                    GoalsProgressChart(
                        goals: filteredGoals,
                        progressData: progressData
                    )
                    .frame(height: 200)
                    .padding(.horizontal)
                }
                
                // Goals List
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredGoals) { goal in
                            GoalCard(
                                goal: goal,
                                progress: progressForGoal(goal),
                                isSelected: selectedGoal?.id == goal.id,
                                onTap: { selectedGoal = goal }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
            .sheet(isPresented: $showingAddGoal) {
                AddGoalView()
            }
        }
        
        private var filteredGoals: [HealthGoal] {
            if filterCategory == .all {
                return goals
            }
            return goals.filter { $0.category == filterCategory }
        }
        
        private func progressForGoal(_ goal: HealthGoal) -> Double {
            let goalProgress = progressData.filter { $0.goalId == goal.id }
            guard !goalProgress.isEmpty else { return 0 }
            return goalProgress.map { $0.progressPercentage }.reduce(0, +) / Double(goalProgress.count)
        }
    }
    
    // MARK: - Goal Progress Tracker
    
    /// Detailed progress tracker for individual goals
    public struct GoalProgressTracker: View {
        let goal: HealthGoal
        let progressData: [GoalProgress]
        let milestones: [GoalMilestone]
        @State private var showingAddProgress: Bool = false
        @State private var selectedTimeframe: Timeframe = .month
        
        public init(
            goal: HealthGoal,
            progressData: [GoalProgress] = [],
            milestones: [GoalMilestone] = []
        ) {
            self.goal = goal
            self.progressData = progressData
            self.milestones = milestones
        }
        
        public var body: some View {
            VStack(spacing: 20) {
                // Goal Header
                GoalHeaderView(goal: goal, progress: currentProgress)
                    .padding(.horizontal)
                
                // Timeframe Selector
                Picker("Timeframe", selection: $selectedTimeframe) {
                    ForEach(Timeframe.allCases, id: \.self) { timeframe in
                        Text(timeframe.displayName).tag(timeframe)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                
                // Progress Chart
                GoalProgressChartView(
                    goal: goal,
                    progressData: filteredProgressData
                )
                .frame(height: 200)
                .padding(.horizontal)
                
                // Milestones
                if !milestones.isEmpty {
                    MilestonesView(
                        milestones: milestones,
                        progressData: progressData
                    )
                    .padding(.horizontal)
                }
                
                // Progress History
                ProgressHistoryView(
                    progressData: filteredProgressData
                )
                .padding(.horizontal)
                
                // Add Progress Button
                Button(action: { showingAddProgress = true }) {
                    HStack(spacing: 8) {
                        Image(systemName: "plus")
                        Text("Add Progress")
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
                }
                .padding(.horizontal)
            }
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
            .sheet(isPresented: $showingAddProgress) {
                AddProgressView(goal: goal)
            }
        }
        
        private var currentProgress: Double {
            guard let latest = progressData.max(by: { $0.date < $1.date }) else { return 0 }
            return latest.progressPercentage
        }
        
        private var filteredProgressData: [GoalProgress] {
            progressData.filter { progress in
                selectedTimeframe.contains(progress.date)
            }
        }
    }
    
    // MARK: - Achievement Tracker
    
    /// Achievement tracking and celebration system
    public struct AchievementTracker: View {
        let achievements: [Achievement]
        let userProgress: [AchievementProgress]
        @State private var selectedAchievement: Achievement?
        @State private var showingCelebration: Bool = false
        
        public init(
            achievements: [Achievement],
            userProgress: [AchievementProgress] = []
        ) {
            self.achievements = achievements
            self.userProgress = userProgress
        }
        
        public var body: some View {
            VStack(spacing: 20) {
                // Achievement Header
                HStack {
                    Text("Achievements")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        Text("\(completedAchievements.count)/\(achievements.count)")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                        Text("Completed")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal)
                
                // Achievement Grid
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                    ForEach(achievements) { achievement in
                        AchievementCard(
                            achievement: achievement,
                            progress: progressForAchievement(achievement),
                            isCompleted: isAchievementCompleted(achievement),
                            onTap: { selectedAchievement = achievement }
                        )
                    }
                }
                .padding(.horizontal)
                
                // Recent Achievements
                if !recentAchievements.isEmpty {
                    RecentAchievementsView(achievements: recentAchievements)
                        .padding(.horizontal)
                }
            }
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
            .sheet(item: $selectedAchievement) { achievement in
                AchievementDetailView(achievement: achievement)
            }
        }
        
        private var completedAchievements: [Achievement] {
            achievements.filter { isAchievementCompleted($0) }
        }
        
        private var recentAchievements: [Achievement] {
            let completed = completedAchievements
            return Array(completed.prefix(3))
        }
        
        private func isAchievementCompleted(_ achievement: Achievement) -> Bool {
            guard let progress = userProgress.first(where: { $0.achievementId == achievement.id }) else {
                return false
            }
            return progress.progress >= achievement.targetValue
        }
        
        private func progressForAchievement(_ achievement: Achievement) -> Double {
            guard let progress = userProgress.first(where: { $0.achievementId == achievement.id }) else {
                return 0
            }
            return min(progress.progress / achievement.targetValue, 1.0)
        }
    }
    
    // MARK: - Goal Analytics
    
    /// Analytics dashboard for goal performance and insights
    public struct GoalAnalytics: View {
        let goals: [HealthGoal]
        let progressData: [GoalProgress]
        let analytics: GoalAnalyticsData
        @State private var selectedMetric: AnalyticsMetric = .completionRate
        @State private var selectedTimeframe: Timeframe = .month
        
        public init(
            goals: [HealthGoal],
            progressData: [GoalProgress] = [],
            analytics: GoalAnalyticsData
        ) {
            self.goals = goals
            self.progressData = progressData
            self.analytics = analytics
        }
        
        public var body: some View {
            VStack(spacing: 20) {
                // Analytics Header
                HStack {
                    Text("Goal Analytics")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    Picker("Timeframe", selection: $selectedTimeframe) {
                        ForEach(Timeframe.allCases, id: \.self) { timeframe in
                            Text(timeframe.displayName).tag(timeframe)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .frame(width: 200)
                }
                .padding(.horizontal)
                
                // Key Metrics
                KeyMetricsView(analytics: analytics)
                    .padding(.horizontal)
                
                // Performance Chart
                PerformanceChartView(
                    goals: goals,
                    progressData: progressData,
                    metric: selectedMetric
                )
                .frame(height: 200)
                .padding(.horizontal)
                
                // Category Performance
                CategoryPerformanceView(
                    goals: goals,
                    progressData: progressData
                )
                .padding(.horizontal)
                
                // Insights
                InsightsView(analytics: analytics)
                    .padding(.horizontal)
            }
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        }
    }
}

// MARK: - Supporting Views

struct CategoryFilterButton: View {
    let category: GoalCategory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(category.displayName)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? category.color : Color(.systemGray5))
                .cornerRadius(16)
        }
    }
}

struct GoalsOverviewGrid: View {
    let goals: [HealthGoal]
    let progressData: [GoalProgress]
    
    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
            ForEach(goals) { goal in
                GoalOverviewCard(
                    goal: goal,
                    progress: progressForGoal(goal)
                )
            }
        }
    }
    
    private func progressForGoal(_ goal: HealthGoal) -> Double {
        let goalProgress = progressData.filter { $0.goalId == goal.id }
        guard !goalProgress.isEmpty else { return 0 }
        return goalProgress.map { $0.progressPercentage }.reduce(0, +) / Double(goalProgress.count)
    }
}

struct GoalOverviewCard: View {
    let goal: HealthGoal
    let progress: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(goal.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(2)
                
                Spacer()
                
                Text(goal.category.displayName)
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(goal.category.color.opacity(0.2))
                    .foregroundColor(goal.category.color)
                    .cornerRadius(6)
            }
            
            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle(tint: goal.category.color))
            
            HStack {
                Text("\(Int(progress * 100))%")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(goal.category.color)
                
                Spacer()
                
                Text(goal.targetValue)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

struct GoalsProgressChart: View {
    let goals: [HealthGoal]
    let progressData: [GoalProgress]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Goals Progress")
                .font(.headline)
                .fontWeight(.semibold)
            
            Chart {
                ForEach(goals) { goal in
                    let goalProgress = progressData.filter { $0.goalId == goal.id }
                    if !goalProgress.isEmpty {
                        LineMark(
                            x: .value("Date", goalProgress.first?.date ?? Date()),
                            y: .value("Progress", goalProgress.map { $0.progressPercentage }.reduce(0, +) / Double(goalProgress.count))
                        )
                        .foregroundStyle(goal.category.color)
                        .symbol(Circle().strokeBorder(lineWidth: 2))
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct GoalCard: View {
    let goal: HealthGoal
    let progress: Double
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(goal.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text(goal.category.displayName)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(goal.category.color.opacity(0.2))
                        .foregroundColor(goal.category.color)
                        .cornerRadius(8)
                }
                
                Text(goal.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
                
                VStack(spacing: 8) {
                    HStack {
                        Text("Progress")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("\(Int(progress * 100))%")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(goal.category.color)
                    }
                    
                    ProgressView(value: progress)
                        .progressViewStyle(LinearProgressViewStyle(tint: goal.category.color))
                }
                
                HStack {
                    VStack(alignment: .leading) {
                        Text("Target")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(goal.targetValue)
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        Text("Deadline")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(goal.endDate?.formatted(date: .abbreviated, time: .omitted) ?? "No deadline")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                }
            }
            .padding()
            .background(isSelected ? Color.blue.opacity(0.1) : Color(.systemGray6))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct GoalHeaderView: View {
    let goal: HealthGoal
    let progress: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(goal.title)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(goal.category.displayName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(Int(progress * 100))%")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(goal.category.color)
                    
                    Text("Complete")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Text(goal.description)
                .font(.body)
                .foregroundColor(.secondary)
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Target")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(goal.targetValue)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                Spacer()
                
                VStack(alignment: .center) {
                    Text("Started")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(goal.startDate.formatted(date: .abbreviated, time: .omitted))
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Deadline")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(goal.endDate?.formatted(date: .abbreviated, time: .omitted) ?? "No deadline")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct GoalProgressChartView: View {
    let goal: HealthGoal
    let progressData: [GoalProgress]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Progress Over Time")
                .font(.headline)
                .fontWeight(.semibold)
            
            if !progressData.isEmpty {
                Chart {
                    ForEach(progressData, id: \.id) { progress in
                        LineMark(
                            x: .value("Date", progress.date),
                            y: .value("Progress", progress.progressPercentage)
                        )
                        .foregroundStyle(goal.category.color)
                        .symbol(Circle().strokeBorder(lineWidth: 2))
                    }
                }
            } else {
                Text("No progress data available")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct MilestonesView: View {
    let milestones: [GoalMilestone]
    let progressData: [GoalProgress]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Milestones")
                .font(.headline)
                .fontWeight(.semibold)
            
            ForEach(milestones) { milestone in
                MilestoneRow(
                    milestone: milestone,
                    isCompleted: isMilestoneCompleted(milestone)
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func isMilestoneCompleted(_ milestone: GoalMilestone) -> Bool {
        // Implementation depends on milestone criteria
        return false
    }
}

struct MilestoneRow: View {
    let milestone: GoalMilestone
    let isCompleted: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isCompleted ? .green : .gray)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(milestone.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .strikethrough(isCompleted)
                
                Text(milestone.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            Text(milestone.targetValue)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct ProgressHistoryView: View {
    let progressData: [GoalProgress]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Progress History")
                .font(.headline)
                .fontWeight(.semibold)
            
            if !progressData.isEmpty {
                ForEach(progressData.sorted(by: { $0.date > $1.date })) { progress in
                    ProgressHistoryRow(progress: progress)
                }
            } else {
                Text("No progress history available")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct ProgressHistoryRow: View {
    let progress: GoalProgress
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(Int(progress.progressPercentage * 100))%")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                if let notes = progress.notes {
                    Text(notes)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
            
            Spacer()
            
            Text(progress.date.formatted(date: .abbreviated, time: .shortened))
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
}

struct AchievementCard: View {
    let achievement: Achievement
    let progress: Double
    let isCompleted: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                // Achievement Icon
                ZStack {
                    Circle()
                        .fill(isCompleted ? achievement.category.color : Color(.systemGray4))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: achievement.iconName)
                        .font(.title2)
                        .foregroundColor(isCompleted ? .white : .gray)
                }
                
                VStack(spacing: 4) {
                    Text(achievement.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                    
                    Text(achievement.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
                
                if !isCompleted {
                    ProgressView(value: progress)
                        .progressViewStyle(LinearProgressViewStyle(tint: achievement.category.color))
                        .frame(height: 4)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isCompleted ? achievement.category.color : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct RecentAchievementsView: View {
    let achievements: [Achievement]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Achievements")
                .font(.headline)
                .fontWeight(.semibold)
            
            ForEach(achievements) { achievement in
                HStack(spacing: 12) {
                    Image(systemName: achievement.iconName)
                        .foregroundColor(achievement.category.color)
                        .font(.title3)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(achievement.title)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Text(achievement.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                    
                    Spacer()
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

struct KeyMetricsView: View {
    let analytics: GoalAnalyticsData
    
    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
            MetricCard(
                title: "Completion Rate",
                value: "\(Int(analytics.completionRate * 100))%",
                icon: "checkmark.circle",
                color: .green
            )
            
            MetricCard(
                title: "Active Goals",
                value: "\(analytics.activeGoals)",
                icon: "target",
                color: .blue
            )
            
            MetricCard(
                title: "Avg Progress",
                value: "\(Int(analytics.averageProgress * 100))%",
                icon: "chart.line.uptrend.xyaxis",
                color: .orange
            )
            
            MetricCard(
                title: "Streak Days",
                value: "\(analytics.streakDays)",
                icon: "flame",
                color: .red
            )
        }
    }
}

struct MetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

struct PerformanceChartView: View {
    let goals: [HealthGoal]
    let progressData: [GoalProgress]
    let metric: AnalyticsMetric
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Performance Trend")
                .font(.headline)
                .fontWeight(.semibold)
            
            Chart {
                ForEach(goals) { goal in
                    let goalProgress = progressData.filter { $0.goalId == goal.id }
                    if !goalProgress.isEmpty {
                        LineMark(
                            x: .value("Date", goalProgress.first?.date ?? Date()),
                            y: .value("Performance", calculatePerformance(goal, progress: goalProgress))
                        )
                        .foregroundStyle(goal.category.color)
                        .symbol(Circle().strokeBorder(lineWidth: 2))
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func calculatePerformance(_ goal: HealthGoal, progress: [GoalProgress]) -> Double {
        // Implementation depends on metric type
        return progress.map { $0.progressPercentage }.reduce(0, +) / Double(progress.count)
    }
}

struct CategoryPerformanceView: View {
    let goals: [HealthGoal]
    let progressData: [GoalProgress]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Category Performance")
                .font(.headline)
                .fontWeight(.semibold)
            
            ForEach(GoalCategory.allCases, id: \.self) { category in
                let categoryGoals = goals.filter { $0.category == category }
                if !categoryGoals.isEmpty {
                    CategoryPerformanceRow(
                        category: category,
                        goals: categoryGoals,
                        progressData: progressData
                    )
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct CategoryPerformanceRow: View {
    let category: GoalCategory
    let goals: [HealthGoal]
    let progressData: [GoalProgress]
    
    var body: some View {
        HStack {
            Text(category.displayName)
                .font(.subheadline)
                .fontWeight(.medium)
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(Int(averageProgress * 100))%")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(category.color)
                
                Text("\(goals.count) goals")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
    }
    
    private var averageProgress: Double {
        let allProgress = goals.compactMap { goal in
            let goalProgress = progressData.filter { $0.goalId == goal.id }
            guard !goalProgress.isEmpty else { return nil }
            return goalProgress.map { $0.progressPercentage }.reduce(0, +) / Double(goalProgress.count)
        }
        
        guard !allProgress.isEmpty else { return 0 }
        return allProgress.reduce(0, +) / Double(allProgress.count)
    }
}

struct InsightsView: View {
    let analytics: GoalAnalyticsData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Insights")
                .font(.headline)
                .fontWeight(.semibold)
            
            ForEach(analytics.insights, id: \.self) { insight in
                HStack(spacing: 12) {
                    Image(systemName: "lightbulb")
                        .foregroundColor(.yellow)
                        .font(.title3)
                    
                    Text(insight)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
                .padding(.vertical, 4)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Supporting Views

struct AddGoalView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var description = ""
    @State private var category: GoalCategory = .fitness
    @State private var targetValue = ""
    @State private var endDate = Date()
    @State private var hasDeadline = false
    
    var body: some View {
        NavigationView {
            Form {
                Section("Goal Details") {
                    TextField("Goal Title", text: $title)
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                    
                    Picker("Category", selection: $category) {
                        ForEach(GoalCategory.allCases, id: \.self) { category in
                            Text(category.displayName).tag(category)
                        }
                    }
                }
                
                Section("Target") {
                    TextField("Target Value", text: $targetValue)
                    
                    Toggle("Has Deadline", isOn: $hasDeadline)
                    
                    if hasDeadline {
                        DatePicker("Deadline", selection: $endDate, displayedComponents: .date)
                    }
                }
            }
            .navigationTitle("Add Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        // Save goal logic
                        dismiss()
                    }
                    .disabled(title.isEmpty || targetValue.isEmpty)
                }
            }
        }
    }
}

struct AddProgressView: View {
    let goal: HealthGoal
    @Environment(\.dismiss) private var dismiss
    @State private var progressPercentage: Double = 0
    @State private var notes = ""
    @State private var date = Date()
    
    var body: some View {
        NavigationView {
            Form {
                Section("Progress") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Progress: \(Int(progressPercentage * 100))%")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Slider(value: $progressPercentage, in: 0...1, step: 0.01)
                    }
                    
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                }
                
                Section("Notes") {
                    TextField("Add notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Add Progress")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        // Save progress logic
                        dismiss()
                    }
                }
            }
        }
    }
}

struct AchievementDetailView: View {
    let achievement: Achievement
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Achievement Icon
                ZStack {
                    Circle()
                        .fill(achievement.category.color)
                        .frame(width: 100, height: 100)
                    
                    Image(systemName: achievement.iconName)
                        .font(.largeTitle)
                        .foregroundColor(.white)
                }
                
                VStack(spacing: 8) {
                    Text(achievement.title)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(achievement.description)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                VStack(spacing: 12) {
                    HStack {
                        Text("Target:")
                            .fontWeight(.medium)
                        Spacer()
                        Text(achievement.targetValue)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Category:")
                            .fontWeight(.medium)
                        Spacer()
                        Text(achievement.category.displayName)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Achievement Details")
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

// MARK: - Data Models

struct HealthGoal: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let category: GoalCategory
    let targetValue: String
    let startDate: Date
    let endDate: Date?
}

enum GoalCategory: CaseIterable {
    case all
    case fitness
    case nutrition
    case sleep
    case mental
    case medical
    
    var displayName: String {
        switch self {
        case .all: return "All"
        case .fitness: return "Fitness"
        case .nutrition: return "Nutrition"
        case .sleep: return "Sleep"
        case .mental: return "Mental Health"
        case .medical: return "Medical"
        }
    }
    
    var color: Color {
        switch self {
        case .all: return .gray
        case .fitness: return .green
        case .nutrition: return .orange
        case .sleep: return .indigo
        case .mental: return .purple
        case .medical: return .red
        }
    }
}

struct GoalProgress: Identifiable {
    let id = UUID()
    let goalId: UUID
    let date: Date
    let progressPercentage: Double
    let notes: String?
}

struct GoalMilestone: Identifiable {
    let id = UUID()
    let goalId: UUID
    let title: String
    let description: String
    let targetValue: String
    let criteria: String
}

struct Achievement: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let category: AchievementCategory
    let targetValue: Double
    let iconName: String
}

enum AchievementCategory: CaseIterable {
    case fitness
    case nutrition
    case sleep
    case mental
    case medical
    case streak
    case milestone
    
    var displayName: String {
        switch self {
        case .fitness: return "Fitness"
        case .nutrition: return "Nutrition"
        case .sleep: return "Sleep"
        case .mental: return "Mental Health"
        case .medical: return "Medical"
        case .streak: return "Streak"
        case .milestone: return "Milestone"
        }
    }
    
    var color: Color {
        switch self {
        case .fitness: return .green
        case .nutrition: return .orange
        case .sleep: return .indigo
        case .mental: return .purple
        case .medical: return .red
        case .streak: return .yellow
        case .milestone: return .blue
        }
    }
}

struct AchievementProgress: Identifiable {
    let id = UUID()
    let achievementId: UUID
    let progress: Double
    let date: Date
}

struct GoalAnalyticsData {
    let completionRate: Double
    let activeGoals: Int
    let averageProgress: Double
    let streakDays: Int
    let insights: [String]
}

enum AnalyticsMetric: CaseIterable {
    case completionRate
    case progress
    case consistency
    case efficiency
}

enum Timeframe: CaseIterable {
    case week
    case month
    case quarter
    case year
    
    var displayName: String {
        switch self {
        case .week: return "Week"
        case .month: return "Month"
        case .quarter: return "Quarter"
        case .year: return "Year"
        }
    }
    
    func contains(_ date: Date) -> Bool {
        let calendar = Calendar.current
        let now = Date()
        
        switch self {
        case .week:
            return calendar.isDate(date, equalTo: now, toGranularity: .weekOfYear)
        case .month:
            return calendar.isDate(date, equalTo: now, toGranularity: .month)
        case .quarter:
            let quarter = (calendar.component(.month, from: now) - 1) / 3
            let eventQuarter = (calendar.component(.month, from: date) - 1) / 3
            return quarter == eventQuarter && calendar.isDate(date, equalTo: now, toGranularity: .year)
        case .year:
            return calendar.isDate(date, equalTo: now, toGranularity: .year)
        }
    }
} 
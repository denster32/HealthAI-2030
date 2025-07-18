import SwiftUI
import Charts

/// Advanced Health Goal View
/// Provides comprehensive goal management interface with AI recommendations,
/// progress tracking, social features, and analytics
struct AdvancedHealthGoalView: View {
    
    // MARK: - Properties
    
    @StateObject private var goalEngine: AdvancedHealthGoalEngine
    @State private var showingAddGoal = false
    @State private var showingAIRecommendations = false
    @State private var showingSocialChallenges = false
    @State private var showingGoalAnalytics = false
    @State private var selectedGoal: HealthGoal?
    @State private var selectedTab = 0
    
    // MARK: - Initialization
    
    init(healthDataManager: HealthDataManager, mlModelManager: MLModelManager, analyticsEngine: AnalyticsEngine) {
        self._goalEngine = StateObject(wrappedValue: AdvancedHealthGoalEngine(
            healthDataManager: healthDataManager,
            mlModelManager: mlModelManager,
            analyticsEngine: analyticsEngine
        ))
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Tab selector
                goalTabSelector
                
                // Tab content
                TabView(selection: $selectedTab) {
                    // Goals Dashboard
                    goalsDashboard
                        .tag(0)
                    
                    // AI Recommendations
                    aiRecommendationsView
                        .tag(1)
                    
                    // Social Challenges
                    socialChallengesView
                        .tag(2)
                    
                    // Analytics
                    goalAnalyticsView
                        .tag(3)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .navigationTitle("Health Goals")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddGoal.toggle() }) {
                        Image(systemName: "plus.circle")
                            .foregroundColor(.blue)
                    }
                }
            }
            .sheet(isPresented: $showingAddGoal) {
                AddGoalView(goalEngine: goalEngine)
            }
            .sheet(isPresented: $showingAIRecommendations) {
                AIRecommendationsView(goalEngine: goalEngine)
            }
            .sheet(isPresented: $showingSocialChallenges) {
                SocialChallengesView(goalEngine: goalEngine)
            }
            .sheet(isPresented: $showingGoalAnalytics) {
                GoalAnalyticsView(goalEngine: goalEngine)
            }
            .onAppear {
                // Load initial data
            }
        }
    }
    
    // MARK: - Tab Selector
    
    private var goalTabSelector: some View {
        HStack(spacing: 0) {
            TabButton(
                title: "Goals",
                icon: "target",
                isSelected: selectedTab == 0,
                action: { selectedTab = 0 }
            )
            
            TabButton(
                title: "AI",
                icon: "brain.head.profile",
                isSelected: selectedTab == 1,
                action: { selectedTab = 1 }
            )
            
            TabButton(
                title: "Social",
                icon: "person.3",
                isSelected: selectedTab == 2,
                action: { selectedTab = 2 }
            )
            
            TabButton(
                title: "Analytics",
                icon: "chart.bar",
                isSelected: selectedTab == 3,
                action: { selectedTab = 3 }
            )
        }
        .background(Color(.systemGroupedBackground))
    }
    
    // MARK: - Goals Dashboard
    
    private var goalsDashboard: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Goal summary cards
                goalSummaryCards
                
                // Active goals
                activeGoalsSection
                
                // Recent achievements
                recentAchievementsSection
            }
            .padding()
        }
        .refreshable {
            // Refresh goal data
        }
    }
    
    private var goalSummaryCards: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
            GoalSummaryCard(
                title: "Active Goals",
                value: "\(goalEngine.userGoals.filter { $0.isActive }.count)",
                icon: "target",
                color: .blue
            )
            
            GoalSummaryCard(
                title: "Completion Rate",
                value: "\(Int(goalEngine.goalAnalytics.averageCompletionRate))%",
                icon: "chart.line.uptrend.xyaxis",
                color: .green
            )
            
            GoalSummaryCard(
                title: "Completed",
                value: "\(goalEngine.goalAnalytics.completedGoals)",
                icon: "checkmark.circle",
                color: .orange
            )
            
            GoalSummaryCard(
                title: "Social Challenges",
                value: "\(goalEngine.socialChallenges.count)",
                icon: "person.3",
                color: .purple
            )
        }
    }
    
    private var activeGoalsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Active Goals")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button("View All") {
                    // Navigate to all goals
                }
                .font(.subheadline)
                .foregroundColor(.blue)
            }
            
            if goalEngine.userGoals.filter({ $0.isActive }).isEmpty {
                EmptyStateView(
                    icon: "target",
                    title: "No Active Goals",
                    message: "Create your first health goal to get started"
                )
            } else {
                ForEach(goalEngine.userGoals.filter { $0.isActive }.prefix(3)) { goal in
                    GoalCardView(
                        goal: goal,
                        progress: goalEngine.goalProgress[goal.id],
                        onTap: {
                            selectedGoal = goal
                        }
                    )
                }
            }
        }
    }
    
    private var recentAchievementsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Achievements")
                .font(.headline)
                .foregroundColor(.primary)
            
            if goalEngine.userGoals.isEmpty {
                EmptyStateView(
                    icon: "trophy",
                    title: "No Achievements Yet",
                    message: "Complete goals to see your achievements here"
                )
            } else {
                ForEach(goalEngine.userGoals.filter { goal in
                    guard let progress = goalEngine.goalProgress[goal.id] else { return false }
                    return progress.completionPercentage >= 100.0
                }.prefix(3)) { goal in
                    AchievementCardView(goal: goal)
                }
            }
        }
    }
    
    // MARK: - AI Recommendations View
    
    private var aiRecommendationsView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // AI insights header
                aiInsightsHeader
                
                // AI recommendations
                aiRecommendationsList
                
                // Goal optimization tips
                goalOptimizationTips
            }
            .padding()
        }
        .refreshable {
            // Refresh AI recommendations
        }
    }
    
    private var aiInsightsHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("AI-Powered Insights")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text("Personalized goal recommendations based on your health data and patterns")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
    
    private var aiRecommendationsList: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recommended Goals")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button("Refresh") {
                    // Refresh recommendations
                }
                .font(.subheadline)
                .foregroundColor(.blue)
            }
            
            if goalEngine.aiRecommendations.isEmpty {
                EmptyStateView(
                    icon: "brain.head.profile",
                    title: "No Recommendations",
                    message: "AI is analyzing your health data to provide personalized recommendations"
                )
            } else {
                ForEach(goalEngine.aiRecommendations) { recommendation in
                    AIRecommendationCardView(
                        recommendation: recommendation,
                        onApply: {
                            Task {
                                try await goalEngine.applyRecommendation(recommendation)
                            }
                        }
                    )
                }
            }
        }
    }
    
    private var goalOptimizationTips: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Optimization Tips")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(spacing: 8) {
                OptimizationTipView(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Track Progress Daily",
                    description: "Consistent tracking improves goal completion rates by 40%"
                )
                
                OptimizationTipView(
                    icon: "person.3",
                    title: "Share with Friends",
                    description: "Social support increases motivation and accountability"
                )
                
                OptimizationTipView(
                    icon: "target",
                    title: "Set Realistic Targets",
                    description: "Achievable goals lead to better long-term success"
                )
            }
        }
    }
    
    // MARK: - Social Challenges View
    
    private var socialChallengesView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Social challenges header
                socialChallengesHeader
                
                // Active challenges
                activeChallengesSection
                
                // Create challenge button
                createChallengeButton
            }
            .padding()
        }
        .refreshable {
            // Refresh social challenges
        }
    }
    
    private var socialChallengesHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Social Challenges")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text("Join challenges with friends and family to stay motivated")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
    
    private var activeChallengesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Active Challenges")
                .font(.headline)
                .foregroundColor(.primary)
            
            if goalEngine.socialChallenges.isEmpty {
                EmptyStateView(
                    icon: "person.3",
                    title: "No Active Challenges",
                    message: "Create or join a challenge to get started"
                )
            } else {
                ForEach(goalEngine.socialChallenges) { challenge in
                    SocialChallengeCardView(
                        challenge: challenge,
                        onJoin: {
                            Task {
                                try await goalEngine.joinSocialChallenge(challenge.id)
                            }
                        }
                    )
                }
            }
        }
    }
    
    private var createChallengeButton: some View {
        Button(action: {
            // Show create challenge interface
        }) {
            HStack {
                Image(systemName: "plus.circle.fill")
                Text("Create New Challenge")
                    .fontWeight(.medium)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .cornerRadius(12)
        }
    }
    
    // MARK: - Goal Analytics View
    
    private var goalAnalyticsView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Analytics overview
                analyticsOverview
                
                // Success rate by category
                successRateByCategory
                
                // Goal trends
                goalTrendsSection
                
                // Top performing goals
                topPerformingGoals
            }
            .padding()
        }
        .refreshable {
            // Refresh analytics
        }
    }
    
    private var analyticsOverview: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Goal Analytics")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
                AnalyticsCardView(
                    title: "Success Rate",
                    value: "\(Int(goalEngine.goalAnalytics.averageCompletionRate))%",
                    trend: "+5%",
                    color: .green
                )
                
                AnalyticsCardView(
                    title: "Avg. Time",
                    value: "\(Int(goalEngine.goalAnalytics.averageTimeToCompletion / 86400)) days",
                    trend: "-2 days",
                    color: .blue
                )
            }
        }
    }
    
    private var successRateByCategory: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Success Rate by Category")
                .font(.headline)
                .foregroundColor(.primary)
            
            if goalEngine.goalAnalytics.successRateByCategory.isEmpty {
                EmptyStateView(
                    icon: "chart.bar",
                    title: "No Data",
                    message: "Complete some goals to see category analytics"
                )
            } else {
                ForEach(Array(goalEngine.goalAnalytics.successRateByCategory.keys), id: \.self) { category in
                    if let successRate = goalEngine.goalAnalytics.successRateByCategory[category] {
                        CategorySuccessRateView(
                            category: category,
                            successRate: successRate
                        )
                    }
                }
            }
        }
    }
    
    private var goalTrendsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Goal Trends")
                .font(.headline)
                .foregroundColor(.primary)
            
            if goalEngine.goalAnalytics.goalTrends.isEmpty {
                EmptyStateView(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "No Trends",
                    message: "More data needed to show goal trends"
                )
            } else {
                ForEach(goalEngine.goalAnalytics.goalTrends) { trend in
                    GoalTrendView(trend: trend)
                }
            }
        }
    }
    
    private var topPerformingGoals: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Top Performing Goals")
                .font(.headline)
                .foregroundColor(.primary)
            
            if goalEngine.goalAnalytics.topPerformingGoals.isEmpty {
                EmptyStateView(
                    icon: "trophy",
                    title: "No Top Goals",
                    message: "Complete some goals to see top performers"
                )
            } else {
                ForEach(goalEngine.goalAnalytics.topPerformingGoals) { goal in
                    TopGoalCardView(goal: goal)
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct TabButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                Text(title)
                    .font(.caption)
            }
            .foregroundColor(isSelected ? .blue : .gray)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct GoalSummaryCard: View {
    let title: String
    let value: String
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
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct GoalCardView: View {
    let goal: HealthGoal
    let progress: GoalProgress?
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading) {
                        Text(goal.title)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text(goal.category.displayName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        Text("\(Int(progress?.completionPercentage ?? 0))%")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(progressColor)
                        
                        Text("Complete")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Progress bar
                ProgressView(value: progress?.completionPercentage ?? 0, total: 100)
                    .progressViewStyle(LinearProgressViewStyle(tint: progressColor))
                
                HStack {
                    Text("\(Int(goal.currentValue)) / \(Int(goal.targetValue)) \(goal.unit)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(goal.deadline, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(radius: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var progressColor: Color {
        let percentage = progress?.completionPercentage ?? 0
        switch percentage {
        case 0..<25: return .red
        case 25..<50: return .orange
        case 50..<75: return .yellow
        case 75..<100: return .blue
        default: return .green
        }
    }
}

struct AchievementCardView: View {
    let goal: HealthGoal
    
    var body: some View {
        HStack {
            Image(systemName: "trophy.fill")
                .font(.title2)
                .foregroundColor(.orange)
            
            VStack(alignment: .leading) {
                Text(goal.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text("Goal Achieved!")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text("🎉")
                .font(.title2)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(.gray)
            
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

struct AIRecommendationCardView: View {
    let recommendation: GoalRecommendation
    let onApply: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading) {
                    Text(recommendation.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(recommendation.category.displayName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("\(Int(recommendation.confidence * 100))%")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                    
                    Text("Confidence")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Text(recommendation.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            HStack {
                Text("Target: \(Int(recommendation.targetValue)) \(recommendation.unit)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button("Apply") {
                    onApply()
                }
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.blue)
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct OptimizationTipView: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

struct SocialChallengeCardView: View {
    let challenge: SocialChallenge
    let onJoin: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading) {
                    Text(challenge.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(challenge.category.displayName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("\(challenge.participants.count)/\(challenge.maxParticipants)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text("Participants")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Text(challenge.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            HStack {
                Text("Deadline: \(challenge.deadline, style: .date)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button("Join") {
                    onJoin()
                }
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.green)
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct AnalyticsCardView: View {
    let title: String
    let value: String
    let trend: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(trend)
                .font(.caption)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

struct CategorySuccessRateView: View {
    let category: GoalCategory
    let successRate: Double
    
    var body: some View {
        HStack {
            Text(category.displayName)
                .font(.subheadline)
                .foregroundColor(.primary)
            
            Spacer()
            
            Text("\(Int(successRate))%")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(successRate > 70 ? .green : .orange)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

struct GoalTrendView: View {
    let trend: GoalTrend
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(trend.category.displayName)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                
                Text(trend.timeframe)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing) {
                Text(trend.trend.rawValue.capitalized)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(trendColor)
                
                Text("\(Int(trend.magnitude))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
    
    private var trendColor: Color {
        switch trend.trend {
        case .improving: return .green
        case .declining: return .red
        case .stable: return .orange
        }
    }
}

struct TopGoalCardView: View {
    let goal: HealthGoal
    
    var body: some View {
        HStack {
            Image(systemName: "trophy.fill")
                .font(.title3)
                .foregroundColor(.orange)
            
            VStack(alignment: .leading) {
                Text(goal.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(goal.category.displayName)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text("Top")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.orange)
                .cornerRadius(8)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Sheet Views

struct AddGoalView: View {
    @ObservedObject var goalEngine: AdvancedHealthGoalEngine
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var description = ""
    @State private var selectedCategory: GoalCategory = .steps
    @State private var targetValue = ""
    @State private var unit = ""
    @State private var deadline = Date().addingTimeInterval(30 * 24 * 3600)
    @State private var selectedDifficulty: GoalDifficulty = .intermediate
    @State private var selectedPriority: GoalPriority = .medium
    
    var body: some View {
        NavigationView {
            Form {
                Section("Goal Details") {
                    TextField("Goal Title", text: $title)
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section("Category & Target") {
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(GoalCategory.allCases, id: \.self) { category in
                            Text(category.displayName).tag(category)
                        }
                    }
                    
                    HStack {
                        TextField("Target Value", text: $targetValue)
                            .keyboardType(.decimalPad)
                        TextField("Unit", text: $unit)
                    }
                }
                
                Section("Timeline & Settings") {
                    DatePicker("Deadline", selection: $deadline, displayedComponents: .date)
                    
                    Picker("Difficulty", selection: $selectedDifficulty) {
                        ForEach(GoalDifficulty.allCases, id: \.self) { difficulty in
                            Text(difficulty.displayName).tag(difficulty)
                        }
                    }
                    
                    Picker("Priority", selection: $selectedPriority) {
                        ForEach(GoalPriority.allCases, id: \.self) { priority in
                            Text(priority.displayName).tag(priority)
                        }
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
                        saveGoal()
                    }
                    .disabled(title.isEmpty || targetValue.isEmpty || unit.isEmpty)
                }
            }
        }
    }
    
    private func saveGoal() {
        guard let targetValueDouble = Double(targetValue) else { return }
        
        let goal = HealthGoal(
            id: UUID().uuidString,
            title: title,
            description: description,
            category: selectedCategory,
            targetValue: targetValueDouble,
            currentValue: 0.0,
            unit: unit,
            deadline: deadline,
            difficulty: selectedDifficulty,
            priority: selectedPriority,
            isActive: true,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        Task {
            do {
                try await goalEngine.createGoal(goal)
                await MainActor.run {
                    dismiss()
                }
            } catch {
                // Handle error
            }
        }
    }
}

struct AIRecommendationsView: View {
    @ObservedObject var goalEngine: AdvancedHealthGoalEngine
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(goalEngine.aiRecommendations) { recommendation in
                        AIRecommendationCardView(
                            recommendation: recommendation,
                            onApply: {
                                Task {
                                    try await goalEngine.applyRecommendation(recommendation)
                                }
                            }
                        )
                    }
                }
                .padding()
            }
            .navigationTitle("AI Recommendations")
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

struct SocialChallengesView: View {
    @ObservedObject var goalEngine: AdvancedHealthGoalEngine
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(goalEngine.socialChallenges) { challenge in
                        SocialChallengeCardView(
                            challenge: challenge,
                            onJoin: {
                                Task {
                                    try await goalEngine.joinSocialChallenge(challenge.id)
                                }
                            }
                        )
                    }
                }
                .padding()
            }
            .navigationTitle("Social Challenges")
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

struct GoalAnalyticsView: View {
    @ObservedObject var goalEngine: AdvancedHealthGoalEngine
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 16) {
                    // Analytics content
                    Text("Goal Analytics")
                        .font(.title)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                }
            }
            .navigationTitle("Analytics")
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

// MARK: - Preview

struct AdvancedHealthGoalView_Previews: PreviewProvider {
    static var previews: some View {
        AdvancedHealthGoalView(
            healthDataManager: HealthDataManager(),
            mlModelManager: MLModelManager(),
            analyticsEngine: AnalyticsEngine()
        )
    }
} 
import SwiftUI
import Charts

/// Advanced Health Gamification & Motivation Dashboard
/// Provides comprehensive gamification, challenges, achievements, rewards, and social features
@available(iOS 18.0, macOS 15.0, *)
public struct AdvancedHealthGamificationDashboardView: View {
    
    // MARK: - Environment
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    // MARK: - State
    @StateObject private var viewModel = AdvancedHealthGamificationViewModel()
    @State private var selectedTab = 0
    @State private var showingChallenge = false
    @State private var showingAchievement = false
    @State private var showingReward = false
    @State private var showingSocial = false
    @State private var selectedChallenge: HealthChallenge?
    @State private var selectedAchievement: Achievement?
    @State private var selectedReward: Reward?
    
    // MARK: - Body
    public var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Tab Content
                TabView(selection: $selectedTab) {
                    // Profile Tab
                    profileTabView
                        .tag(0)
                    
                    // Challenges Tab
                    challengesTabView
                        .tag(1)
                    
                    // Achievements Tab
                    achievementsTabView
                        .tag(2)
                    
                    // Social Tab
                    socialTabView
                        .tag(3)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .background(backgroundColor)
            .navigationBarHidden(true)
        }
        .onAppear {
            viewModel.loadData()
        }
        .sheet(isPresented: $showingChallenge) {
            ChallengeView(viewModel: viewModel)
        }
        .sheet(isPresented: $showingAchievement) {
            AchievementView(viewModel: viewModel)
        }
        .sheet(isPresented: $showingReward) {
            RewardView(viewModel: viewModel)
        }
        .sheet(isPresented: $showingSocial) {
            SocialView(viewModel: viewModel)
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        VStack(spacing: 16) {
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                Text("Gamification")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button(action: { viewModel.refreshData() }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.title2)
                        .foregroundColor(.primary)
                }
            }
            .padding(.horizontal)
            
            // Tab Indicators
            HStack(spacing: 0) {
                ForEach(0..<4) { index in
                    Button(action: { selectedTab = index }) {
                        VStack(spacing: 4) {
                            Text(tabTitle(for: index))
                                .font(.caption)
                                .fontWeight(selectedTab == index ? .semibold : .regular)
                                .foregroundColor(selectedTab == index ? .primary : .secondary)
                            
                            Rectangle()
                                .fill(selectedTab == index ? Color.accentColor : Color.clear)
                                .frame(height: 2)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
        .background(headerBackgroundColor)
    }
    
    // MARK: - Profile Tab View
    private var profileTabView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // User Profile Card
                userProfileCard
                
                // Motivation Streak
                motivationStreakCard
                
                // Daily Goals
                dailyGoalsCard
                
                // Statistics
                statisticsCard
            }
            .padding()
        }
    }
    
    // MARK: - Challenges Tab View
    private var challengesTabView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Active Challenges
                activeChallengesCard
                
                // Completed Challenges
                completedChallengesCard
                
                // Challenge Categories
                challengeCategoriesCard
            }
            .padding()
        }
    }
    
    // MARK: - Achievements Tab View
    private var achievementsTabView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Achievements Overview
                achievementsOverviewCard
                
                // Unlocked Achievements
                unlockedAchievementsCard
                
                // Achievement Progress
                achievementProgressCard
            }
            .padding()
        }
    }
    
    // MARK: - Social Tab View
    private var socialTabView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Social Overview
                socialOverviewCard
                
                // Leaderboards
                leaderboardsCard
                
                // Social Connections
                socialConnectionsCard
            }
            .padding()
        }
    }
    
    // MARK: - User Profile Card
    private var userProfileCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("User Profile")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button(action: {
                    if viewModel.isGamificationActive {
                        Task { await viewModel.stopGamification() }
                    } else {
                        Task { await viewModel.startGamification() }
                    }
                }) {
                    Text(viewModel.isGamificationActive ? "Stop" : "Start")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(viewModel.isGamificationActive ? Color.red : Color.green)
                        .cornerRadius(8)
                }
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Level")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("\(viewModel.userProfile.level)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Points")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("\(viewModel.userProfile.points)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Experience")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("\(viewModel.userProfile.experience)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Rank")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(viewModel.userProfile.rank)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                }
            }
            
            if viewModel.isGamificationActive {
                ProgressView(value: viewModel.gamificationProgress)
                    .progressViewStyle(LinearProgressViewStyle())
                    .accentColor(.green)
            }
            
            if let error = viewModel.lastError {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.top, 4)
            }
        }
        .padding()
        .background(cardBackgroundColor)
        .cornerRadius(12)
    }
    
    // MARK: - Motivation Streak Card
    private var motivationStreakCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Motivation Streak")
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Current Streak")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("\(viewModel.motivationStreak.currentStreak) days")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Longest Streak")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("\(viewModel.motivationStreak.longestStreak) days")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                }
            }
            
            // Streak visualization
            HStack(spacing: 4) {
                ForEach(0..<7) { day in
                    Circle()
                        .fill(day < viewModel.motivationStreak.currentStreak ? Color.green : Color.gray.opacity(0.3))
                        .frame(width: 20, height: 20)
                }
            }
        }
        .padding()
        .background(cardBackgroundColor)
        .cornerRadius(12)
    }
    
    // MARK: - Daily Goals Card
    private var dailyGoalsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Daily Goals")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("\(viewModel.dailyGoals.filter { $0.completed }.count)/\(viewModel.dailyGoals.count)")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.accentColor)
            }
            
            if viewModel.dailyGoals.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "target")
                        .font(.title)
                        .foregroundColor(.secondary)
                    
                    Text("No daily goals set")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(viewModel.dailyGoals.prefix(3)) { goal in
                        DailyGoalRowView(goal: goal) {
                            Task { await viewModel.updateDailyGoalProgress(goalId: goal.id, progress: 1.0) }
                        }
                    }
                    
                    if viewModel.dailyGoals.count > 3 {
                        Button("View All \(viewModel.dailyGoals.count) Goals") {
                            selectedTab = 0
                        }
                        .font(.caption)
                        .foregroundColor(.accentColor)
                    }
                }
            }
        }
        .padding()
        .background(cardBackgroundColor)
        .cornerRadius(12)
    }
    
    // MARK: - Statistics Card
    private var statisticsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Statistics")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                HStack {
                    Text("Challenges")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Completed: \(viewModel.userProfile.statistics.completedChallenges)")
                            .font(.caption)
                            .foregroundColor(.green)
                        
                        Text("Total: \(viewModel.userProfile.statistics.totalChallenges)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                HStack {
                    Text("Achievements")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Unlocked: \(viewModel.userProfile.statistics.unlockedAchievements)")
                            .font(.caption)
                            .foregroundColor(.blue)
                        
                        Text("Total: \(viewModel.userProfile.statistics.totalAchievements)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                HStack {
                    Text("Streaks")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Current: \(viewModel.userProfile.statistics.currentStreak)")
                            .font(.caption)
                            .foregroundColor(.orange)
                        
                        Text("Longest: \(viewModel.userProfile.statistics.longestStreak)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(cardBackgroundColor)
        .cornerRadius(12)
    }
    
    // MARK: - Active Challenges Card
    private var activeChallengesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Active Challenges")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button(action: { showingChallenge = true }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(.accentColor)
                }
            }
            
            if viewModel.activeChallenges.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "flag")
                        .font(.title)
                        .foregroundColor(.secondary)
                    
                    Text("No active challenges")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Button("Join Challenge") {
                        showingChallenge = true
                    }
                    .font(.caption)
                    .foregroundColor(.accentColor)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(viewModel.activeChallenges.prefix(3)) { challenge in
                        ChallengeRowView(challenge: challenge) {
                            selectedChallenge = challenge
                        }
                    }
                    
                    if viewModel.activeChallenges.count > 3 {
                        Button("View All \(viewModel.activeChallenges.count) Challenges") {
                            selectedTab = 1
                        }
                        .font(.caption)
                        .foregroundColor(.accentColor)
                    }
                }
            }
        }
        .padding()
        .background(cardBackgroundColor)
        .cornerRadius(12)
    }
    
    // MARK: - Completed Challenges Card
    private var completedChallengesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Completed Challenges")
                .font(.headline)
                .fontWeight(.semibold)
            
            if viewModel.completedChallenges.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "checkmark.circle")
                        .font(.title)
                        .foregroundColor(.secondary)
                    
                    Text("No completed challenges")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(viewModel.completedChallenges.prefix(3)) { challenge in
                        CompletedChallengeRowView(challenge: challenge)
                    }
                    
                    if viewModel.completedChallenges.count > 3 {
                        Button("View All \(viewModel.completedChallenges.count) Completed") {
                            selectedTab = 1
                        }
                        .font(.caption)
                        .foregroundColor(.accentColor)
                    }
                }
            }
        }
        .padding()
        .background(cardBackgroundColor)
        .cornerRadius(12)
    }
    
    // MARK: - Challenge Categories Card
    private var challengeCategoriesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Challenge Categories")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(ChallengeCategory.allCases, id: \.self) { category in
                    ChallengeCategoryCard(category: category) {
                        // Handle category selection
                    }
                }
            }
        }
        .padding()
        .background(cardBackgroundColor)
        .cornerRadius(12)
    }
    
    // MARK: - Achievements Overview Card
    private var achievementsOverviewCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Achievements")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("\(viewModel.achievements.count) unlocked")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.accentColor)
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total Points")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("\(viewModel.achievements.reduce(0) { $0 + $1.points })")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Rarity")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("\(viewModel.achievements.filter { $0.rarity == .legendary }.count) Legendary")
                        .font(.caption)
                        .foregroundColor(.purple)
                }
            }
        }
        .padding()
        .background(cardBackgroundColor)
        .cornerRadius(12)
    }
    
    // MARK: - Unlocked Achievements Card
    private var unlockedAchievementsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Unlocked Achievements")
                .font(.headline)
                .fontWeight(.semibold)
            
            if viewModel.achievements.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "trophy")
                        .font(.title)
                        .foregroundColor(.secondary)
                    
                    Text("No achievements unlocked")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(viewModel.achievements.prefix(3)) { achievement in
                        AchievementRowView(achievement: achievement) {
                            selectedAchievement = achievement
                        }
                    }
                    
                    if viewModel.achievements.count > 3 {
                        Button("View All \(viewModel.achievements.count) Achievements") {
                            selectedTab = 2
                        }
                        .font(.caption)
                        .foregroundColor(.accentColor)
                    }
                }
            }
        }
        .padding()
        .background(cardBackgroundColor)
        .cornerRadius(12)
    }
    
    // MARK: - Achievement Progress Card
    private var achievementProgressCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Achievement Progress")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                ForEach(AchievementType.allCases.prefix(4), id: \.self) { type in
                    HStack {
                        Text(type.rawValue.capitalized)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Spacer()
                        
                        Text("\(viewModel.achievements.filter { $0.type == type }.count)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(cardBackgroundColor)
        .cornerRadius(12)
    }
    
    // MARK: - Social Overview Card
    private var socialOverviewCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Social")
                .font(.headline)
                .fontWeight(.semibold)
                
                Spacer()
                
                Button(action: { showingSocial = true }) {
                    Image(systemName: "person.badge.plus")
                        .font(.title2)
                        .foregroundColor(.accentColor)
                }
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Connections")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("\(viewModel.socialConnections.count)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Leaderboards")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("\(viewModel.leaderboards.count)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                }
            }
        }
        .padding()
        .background(cardBackgroundColor)
        .cornerRadius(12)
    }
    
    // MARK: - Leaderboards Card
    private var leaderboardsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Leaderboards")
                .font(.headline)
                .fontWeight(.semibold)
            
            if viewModel.leaderboards.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "chart.bar")
                        .font(.title)
                        .foregroundColor(.secondary)
                    
                    Text("No leaderboards available")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(viewModel.leaderboards.prefix(3)) { leaderboard in
                        LeaderboardRowView(leaderboard: leaderboard)
                    }
                    
                    if viewModel.leaderboards.count > 3 {
                        Button("View All \(viewModel.leaderboards.count) Leaderboards") {
                            selectedTab = 3
                        }
                        .font(.caption)
                        .foregroundColor(.accentColor)
                    }
                }
            }
        }
        .padding()
        .background(cardBackgroundColor)
        .cornerRadius(12)
    }
    
    // MARK: - Social Connections Card
    private var socialConnectionsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Social Connections")
                .font(.headline)
                .fontWeight(.semibold)
            
            if viewModel.socialConnections.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "person.2")
                        .font(.title)
                        .foregroundColor(.secondary)
                    
                    Text("No social connections")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Button("Add Friends") {
                        showingSocial = true
                    }
                    .font(.caption)
                    .foregroundColor(.accentColor)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(viewModel.socialConnections.prefix(3)) { connection in
                        SocialConnectionRowView(connection: connection)
                    }
                    
                    if viewModel.socialConnections.count > 3 {
                        Button("View All \(viewModel.socialConnections.count) Connections") {
                            selectedTab = 3
                        }
                        .font(.caption)
                        .foregroundColor(.accentColor)
                    }
                }
            }
        }
        .padding()
        .background(cardBackgroundColor)
        .cornerRadius(12)
    }
    
    // MARK: - Helper Methods
    private func tabTitle(for index: Int) -> String {
        switch index {
        case 0: return "Profile"
        case 1: return "Challenges"
        case 2: return "Achievements"
        case 3: return "Social"
        default: return ""
        }
    }
    
    // MARK: - Computed Properties
    private var backgroundColor: Color {
        colorScheme == .dark ? Color.black : Color(.systemGroupedBackground)
    }
    
    private var headerBackgroundColor: Color {
        colorScheme == .dark ? Color(.systemGray6) : Color(.systemBackground)
    }
    
    private var cardBackgroundColor: Color {
        colorScheme == .dark ? Color(.systemGray6) : Color(.systemBackground)
    }
}

// MARK: - Supporting Views

@available(iOS 18.0, macOS 15.0, *)
struct DailyGoalRowView: View {
    let goal: DailyGoal
    let onComplete: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(goal.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(goal.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(Int(goal.progress * 100))%")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.accentColor)
                
                if !goal.completed {
                    Button("Complete") {
                        onComplete()
                    }
                    .font(.caption2)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.accentColor)
                    .cornerRadius(4)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

@available(iOS 18.0, macOS 15.0, *)
struct ChallengeRowView: View {
    let challenge: HealthChallenge
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(challenge.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text(challenge.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(challenge.points) pts")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.accentColor)
                    
                    Text(challenge.difficulty.rawValue.capitalized)
                        .font(.caption2)
                        .foregroundColor(difficultyColor(challenge.difficulty))
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func difficultyColor(_ difficulty: ChallengeDifficulty) -> Color {
        switch difficulty {
        case .easy: return .green
        case .medium: return .yellow
        case .hard: return .orange
        case .expert: return .red
        }
    }
}

@available(iOS 18.0, macOS 15.0, *)
struct CompletedChallengeRowView: View {
    let challenge: HealthChallenge
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(challenge.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text("Completed")
                    .font(.caption)
                    .foregroundColor(.green)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(challenge.points) pts")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.accentColor)
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundColor(.green)
            }
        }
        .padding(.vertical, 4)
    }
}

@available(iOS 18.0, macOS 15.0, *)
struct ChallengeCategoryCard: View {
    let category: ChallengeCategory
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Image(systemName: categoryIcon(for: category))
                    .font(.title2)
                    .foregroundColor(.accentColor)
                
                Text(category.rawValue.capitalized)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color.accentColor.opacity(0.1))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func categoryIcon(for category: ChallengeCategory) -> String {
        switch category {
        case .fitness: return "figure.run"
        case .nutrition: return "leaf"
        case .sleep: return "bed.double"
        case .mental: return "brain.head.profile"
        case .social: return "person.2"
        }
    }
}

@available(iOS 18.0, macOS 15.0, *)
struct AchievementRowView: View {
    let achievement: Achievement
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Image(systemName: achievement.icon)
                    .font(.title3)
                    .foregroundColor(rarityColor(achievement.rarity))
                    .frame(width: 20)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(achievement.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text(achievement.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(achievement.points) pts")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.accentColor)
                    
                    Text(achievement.rarity.rawValue.capitalized)
                        .font(.caption2)
                        .foregroundColor(rarityColor(achievement.rarity))
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func rarityColor(_ rarity: AchievementRarity) -> Color {
        switch rarity {
        case .common: return .gray
        case .uncommon: return .green
        case .rare: return .blue
        case .epic: return .purple
        case .legendary: return .orange
        }
    }
}

@available(iOS 18.0, macOS 15.0, *)
struct LeaderboardRowView: View {
    let leaderboard: Leaderboard
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(leaderboard.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(leaderboard.category.rawValue.capitalized)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(leaderboard.entries.count) entries")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(leaderboard.type.rawValue.capitalized)
                    .font(.caption2)
                    .foregroundColor(.accentColor)
            }
        }
        .padding(.vertical, 4)
    }
}

@available(iOS 18.0, macOS 15.0, *)
struct SocialConnectionRowView: View {
    let connection: SocialConnection
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(connection.username)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(connection.status.rawValue.capitalized)
                    .font(.caption)
                    .foregroundColor(statusColor(connection.status))
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(connection.sharedChallenges.count) challenges")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(connection.lastInteraction, style: .relative)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func statusColor(_ status: ConnectionStatus) -> Color {
        switch status {
        case .active: return .green
        case .pending: return .yellow
        case .inactive: return .red
        }
    }
}

// MARK: - Placeholder Views

@available(iOS 18.0, macOS 15.0, *)
struct ChallengeView: View {
    @ObservedObject var viewModel: AdvancedHealthGamificationViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Challenge Management")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding()
                
                Spacer()
                
                Text("Challenge management interface")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button("Done") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .padding()
            }
            .navigationBarHidden(true)
        }
    }
}

@available(iOS 18.0, macOS 15.0, *)
struct AchievementView: View {
    @ObservedObject var viewModel: AdvancedHealthGamificationViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Achievement Management")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding()
                
                Spacer()
                
                Text("Achievement management interface")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button("Done") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .padding()
            }
            .navigationBarHidden(true)
        }
    }
}

@available(iOS 18.0, macOS 15.0, *)
struct RewardView: View {
    @ObservedObject var viewModel: AdvancedHealthGamificationViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Reward Management")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding()
                
                Spacer()
                
                Text("Reward management interface")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button("Done") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .padding()
            }
            .navigationBarHidden(true)
        }
    }
}

@available(iOS 18.0, macOS 15.0, *)
struct SocialView: View {
    @ObservedObject var viewModel: AdvancedHealthGamificationViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Social Management")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding()
                
                Spacer()
                
                Text("Social management interface")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button("Done") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .padding()
            }
            .navigationBarHidden(true)
        }
    }
}

// MARK: - Preview
@available(iOS 18.0, macOS 15.0, *)
#Preview {
    AdvancedHealthGamificationDashboardView()
} 
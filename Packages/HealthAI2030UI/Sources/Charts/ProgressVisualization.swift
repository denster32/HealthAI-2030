import SwiftUI
import Charts

// MARK: - Progress Visualization
/// Comprehensive progress and goal visualization components for HealthAI 2030
/// Provides progress rings, goal tracking charts, and milestone indicators
public struct ProgressVisualization {
    
    // MARK: - Progress Ring Components
    
    /// Circular progress ring for health goals
    public struct HealthProgressRing: View {
        let progress: Double
        let goal: Double
        let title: String
        let color: Color
        let size: CGFloat
        
        public init(progress: Double, goal: Double, title: String, color: Color = .blue, size: CGFloat = 120) {
            self.progress = progress
            self.goal = goal
            self.title = title
            self.color = color
            self.size = size
        }
        
        private var progressPercentage: Double {
            min(progress / goal, 1.0)
        }
        
        public var body: some View {
            VStack(spacing: 8) {
                ZStack {
                    // Background circle
                    Circle()
                        .stroke(color.opacity(0.2), lineWidth: 12)
                        .frame(width: size, height: size)
                    
                    // Progress circle
                    Circle()
                        .trim(from: 0, to: progressPercentage)
                        .stroke(color, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                        .frame(width: size, height: size)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 1.0), value: progressPercentage)
                    
                    // Center content
                    VStack(spacing: 4) {
                        Text("\(Int(progress))")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(color)
                        
                        Text("of \(Int(goal))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    /// Multi-ring progress display for multiple health metrics
    public struct MultiRingProgress: View {
        let metrics: [ProgressMetric]
        let size: CGFloat
        
        public init(metrics: [ProgressMetric], size: CGFloat = 200) {
            self.metrics = metrics
            self.size = size
        }
        
        public var body: some View {
            ZStack {
                ForEach(Array(metrics.enumerated()), id: \.offset) { index, metric in
                    let ringSize = size - CGFloat(index * 20)
                    let progress = min(metric.progress / metric.goal, 1.0)
                    
                    Circle()
                        .stroke(metric.color.opacity(0.2), lineWidth: 8)
                        .frame(width: ringSize, height: ringSize)
                    
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(metric.color, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .frame(width: ringSize, height: ringSize)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 1.0), value: progress)
                }
                
                VStack(spacing: 4) {
                    Text("Health Score")
                        .font(.caption)
                        .fontWeight(.medium)
                    
                    Text("\(Int(calculateOverallScore()))")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("out of 100")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        
        private func calculateOverallScore() -> Double {
            let totalProgress = metrics.reduce(0.0) { sum, metric in
                sum + (metric.progress / metric.goal)
            }
            return (totalProgress / Double(metrics.count)) * 100
        }
    }
    
    // MARK: - Goal Tracking Charts
    
    /// Goal progress bar chart
    public struct GoalProgressChart: View {
        let goals: [GoalProgress]
        let showPercentage: Bool
        
        public init(goals: [GoalProgress], showPercentage: Bool = true) {
            self.goals = goals
            self.showPercentage = showPercentage
        }
        
        public var body: some View {
            VStack(spacing: 12) {
                ForEach(goals) { goal in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(goal.title)
                                .font(.caption)
                                .fontWeight(.medium)
                            
                            Spacer()
                            
                            if showPercentage {
                                Text("\(Int(goal.percentage))%")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(goal.color)
                            }
                        }
                        
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                Rectangle()
                                    .fill(goal.color.opacity(0.2))
                                    .frame(height: 8)
                                    .cornerRadius(4)
                                
                                Rectangle()
                                    .fill(goal.color)
                                    .frame(width: geometry.size.width * goal.percentage / 100, height: 8)
                                    .cornerRadius(4)
                                    .animation(.easeInOut(duration: 0.8), value: goal.percentage)
                            }
                        }
                        .frame(height: 8)
                    }
                }
            }
        }
    }
    
    /// Weekly goal tracking chart
    public struct WeeklyGoalChart: View {
        let weeklyData: [WeeklyGoalData]
        
        public init(weeklyData: [WeeklyGoalData]) {
            self.weeklyData = weeklyData
        }
        
        public var body: some View {
            Chart {
                ForEach(weeklyData) { data in
                    BarMark(
                        x: .value("Day", data.day),
                        y: .value("Progress", data.progress)
                    )
                    .foregroundStyle(data.progress >= 100 ? .green : .blue)
                    .cornerRadius(4)
                }
                
                RuleMark(y: .value("Goal", 100))
                    .foregroundStyle(.orange)
                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
            }
            .chartXAxis {
                AxisMarks { value in
                    AxisValueLabel {
                        if let day = value.as(String.self) {
                            Text(day)
                                .font(.caption)
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisValueLabel {
                        if let progress = value.as(Double.self) {
                            Text("\(Int(progress))%")
                                .font(.caption)
                        }
                    }
                }
            }
        }
    }
    
    /// Monthly goal trend chart
    public struct MonthlyGoalTrendChart: View {
        let monthlyData: [MonthlyGoalData]
        
        public init(monthlyData: [MonthlyGoalData]) {
            self.monthlyData = monthlyData
        }
        
        public var body: some View {
            Chart {
                ForEach(monthlyData) { data in
                    LineMark(
                        x: .value("Month", data.month),
                        y: .value("Achievement", data.achievementPercentage)
                    )
                    .foregroundStyle(.blue)
                    .lineStyle(StrokeStyle(lineWidth: 3))
                    .interpolationMethod(.catmullRom)
                    
                    AreaMark(
                        x: .value("Month", data.month),
                        y: .value("Achievement", data.achievementPercentage)
                    )
                    .foregroundStyle(.blue.opacity(0.1))
                    
                    PointMark(
                        x: .value("Month", data.month),
                        y: .value("Achievement", data.achievementPercentage)
                    )
                    .foregroundStyle(.blue)
                }
                
                RuleMark(y: .value("Target", 80))
                    .foregroundStyle(.orange)
                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
                    .annotation(position: .leading) {
                        Text("Target")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
            }
            .chartXAxis {
                AxisMarks { value in
                    AxisValueLabel {
                        if let month = value.as(String.self) {
                            Text(month)
                                .font(.caption)
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisValueLabel {
                        if let percentage = value.as(Double.self) {
                            Text("\(Int(percentage))%")
                                .font(.caption)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Milestone Components
    
    /// Milestone progress indicator
    public struct MilestoneProgress: View {
        let milestones: [Milestone]
        let currentProgress: Double
        
        public init(milestones: [Milestone], currentProgress: Double) {
            self.milestones = milestones
            self.currentProgress = currentProgress
        }
        
        public var body: some View {
            VStack(spacing: 16) {
                // Progress line
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 4)
                        
                        Rectangle()
                            .fill(Color.blue)
                            .frame(width: geometry.size.width * min(currentProgress / 100, 1.0), height: 4)
                            .animation(.easeInOut(duration: 1.0), value: currentProgress)
                    }
                }
                .frame(height: 4)
                
                // Milestone markers
                HStack {
                    ForEach(milestones) { milestone in
                        VStack(spacing: 8) {
                            Circle()
                                .fill(currentProgress >= milestone.threshold ? milestone.color : Color.gray.opacity(0.3))
                                .frame(width: 20, height: 20)
                                .overlay(
                                    Image(systemName: milestone.icon)
                                        .font(.caption2)
                                        .foregroundColor(.white)
                                )
                            
                            Text(milestone.title)
                                .font(.caption2)
                                .fontWeight(.medium)
                                .multilineTextAlignment(.center)
                            
                            Text("\(Int(milestone.threshold))")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        
                        if milestone != milestones.last {
                            Spacer()
                        }
                    }
                }
            }
        }
    }
    
    /// Achievement badge display
    public struct AchievementBadge: View {
        let achievement: Achievement
        let isUnlocked: Bool
        
        public init(achievement: Achievement, isUnlocked: Bool) {
            self.achievement = achievement
            self.isUnlocked = isUnlocked
        }
        
        public var body: some View {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(isUnlocked ? achievement.color : Color.gray.opacity(0.3))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: achievement.icon)
                        .font(.title2)
                        .foregroundColor(isUnlocked ? .white : .gray)
                }
                
                Text(achievement.title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
                
                if isUnlocked {
                    Text(achievement.description)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .opacity(isUnlocked ? 1.0 : 0.6)
        }
    }
    
    /// Streak counter
    public struct StreakCounter: View {
        let currentStreak: Int
        let longestStreak: Int
        let streakType: String
        
        public init(currentStreak: Int, longestStreak: Int, streakType: String = "Day") {
            self.currentStreak = currentStreak
            self.longestStreak = longestStreak
            self.streakType = streakType
        }
        
        public var body: some View {
            HStack(spacing: 16) {
                VStack(spacing: 4) {
                    Text("\(currentStreak)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                    
                    Text("Current \(streakType)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack(spacing: 4) {
                    Text("\(longestStreak)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                    
                    Text("Best \(streakType)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        }
    }
}

// MARK: - Data Models

public struct ProgressMetric: Identifiable {
    public let id = UUID()
    public let title: String
    public let progress: Double
    public let goal: Double
    public let color: Color
    
    public init(title: String, progress: Double, goal: Double, color: Color) {
        self.title = title
        self.progress = progress
        self.goal = goal
        self.color = color
    }
}

public struct GoalProgress: Identifiable {
    public let id = UUID()
    public let title: String
    public let progress: Double
    public let goal: Double
    public let color: Color
    
    public var percentage: Double {
        (progress / goal) * 100
    }
    
    public init(title: String, progress: Double, goal: Double, color: Color = .blue) {
        self.title = title
        self.progress = progress
        self.goal = goal
        self.color = color
    }
}

public struct WeeklyGoalData: Identifiable {
    public let id = UUID()
    public let day: String
    public let progress: Double
    
    public init(day: String, progress: Double) {
        self.day = day
        self.progress = progress
    }
}

public struct MonthlyGoalData: Identifiable {
    public let id = UUID()
    public let month: String
    public let achievementPercentage: Double
    
    public init(month: String, achievementPercentage: Double) {
        self.month = month
        self.achievementPercentage = achievementPercentage
    }
}

public struct Milestone: Identifiable {
    public let id = UUID()
    public let title: String
    public let threshold: Double
    public let icon: String
    public let color: Color
    
    public init(title: String, threshold: Double, icon: String, color: Color) {
        self.title = title
        self.threshold = threshold
        self.icon = icon
        self.color = color
    }
}

public struct Achievement: Identifiable {
    public let id = UUID()
    public let title: String
    public let description: String
    public let icon: String
    public let color: Color
    
    public init(title: String, description: String, icon: String, color: Color) {
        self.title = title
        self.description = description
        self.icon = icon
        self.color = color
    }
} 
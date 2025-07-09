import SwiftUI
import Charts

/// Coaching Insights View
/// Displays comprehensive analytics and insights from coaching sessions
@available(iOS 18.0, macOS 15.0, *)
public struct CoachingInsightsView: View {
    
    // MARK: - State
    @ObservedObject var coachingEngine: RealTimeHealthCoachingEngine
    @State private var insights: CoachingInsights?
    @State private var selectedTimeframe: Timeframe = .month
    @State private var isLoading = true
    
    // MARK: - Environment
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Body
    public var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    if isLoading {
                        loadingSection
                    } else if let insights = insights {
                        // Overview Section
                        overviewSection(insights)
                        
                        // Progress Charts
                        progressChartsSection(insights)
                        
                        // Goal Analysis
                        goalAnalysisSection(insights)
                        
                        // Improvement Areas
                        improvementAreasSection(insights)
                        
                        // Recommendations
                        recommendationsSection(insights)
                    } else {
                        emptyStateSection
                    }
                }
                .padding()
            }
            .navigationTitle("Coaching Insights")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Picker("Timeframe", selection: $selectedTimeframe) {
                            ForEach(Timeframe.allCases, id: \.self) { timeframe in
                                Text(timeframe.displayName).tag(timeframe)
                            }
                        }
                    } label: {
                        Image(systemName: "calendar")
                    }
                }
            }
        }
        .onAppear {
            loadInsights()
        }
        .onChange(of: selectedTimeframe) { _ in
            loadInsights()
        }
    }
    
    // MARK: - Loading Section
    private var loadingSection: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("Loading Insights...")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    // MARK: - Empty State Section
    private var emptyStateSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.bar.doc.horizontal")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No Insights Available")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Complete your first coaching session to see personalized insights and analytics.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Start Coaching Session") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
    
    // MARK: - Overview Section
    private func overviewSection(_ insights: CoachingInsights) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Overview")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                InsightMetricCard(
                    title: "Total Sessions",
                    value: "\(insights.totalSessions)",
                    icon: "calendar",
                    color: .blue,
                    trend: .up
                )
                
                InsightMetricCard(
                    title: "Success Rate",
                    value: "\(Int(insights.successRate * 100))%",
                    icon: "checkmark.circle",
                    color: .green,
                    trend: insights.successRate > 0.7 ? .up : .down
                )
                
                InsightMetricCard(
                    title: "Avg. Duration",
                    value: formatDuration(insights.averageSessionDuration),
                    icon: "clock",
                    color: .orange,
                    trend: .neutral
                )
                
                InsightMetricCard(
                    title: "Active Goals",
                    value: "\(insights.mostCommonGoals.count)",
                    icon: "target",
                    color: .purple,
                    trend: .up
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Progress Charts Section
    private func progressChartsSection(_ insights: CoachingInsights) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Progress Trends")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 20) {
                // Session Duration Trend
                ChartCard(
                    title: "Session Duration Trend",
                    subtitle: "Average session duration over time"
                ) {
                    SessionDurationChart(data: generateChartData())
                }
                
                // Success Rate Trend
                ChartCard(
                    title: "Success Rate Trend",
                    subtitle: "Goal achievement rate over time"
                ) {
                    SuccessRateChart(data: generateSuccessRateData())
                }
                
                // Goal Distribution
                ChartCard(
                    title: "Goal Distribution",
                    subtitle: "Most common health goals"
                ) {
                    GoalDistributionChart(goals: insights.mostCommonGoals)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Goal Analysis Section
    private func goalAnalysisSection(_ insights: CoachingInsights) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Goal Analysis")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                ForEach(insights.mostCommonGoals, id: \.self) { goalType in
                    GoalAnalysisCard(goalType: goalType)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Improvement Areas Section
    private func improvementAreasSection(_ insights: CoachingInsights) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Areas for Improvement")
                .font(.headline)
                .fontWeight(.semibold)
            
            if insights.improvementAreas.isEmpty {
                Text("Great job! No specific improvement areas identified.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                VStack(spacing: 12) {
                    ForEach(insights.improvementAreas, id: \.self) { area in
                        ImprovementAreaCard(area: area)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Recommendations Section
    private func recommendationsSection(_ insights: CoachingInsights) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Personalized Recommendations")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                ForEach(insights.recommendations, id: \.self) { recommendation in
                    RecommendationCard(recommendation: recommendation)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Helper Methods
    private func loadInsights() {
        isLoading = true
        
        Task {
            let insights = await coachingEngine.getCoachingInsights()
            await MainActor.run {
                self.insights = insights
                self.isLoading = false
            }
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration / 60)
        return "\(minutes)m"
    }
    
    private func generateChartData() -> [ChartDataPoint] {
        // Generate sample chart data
        return [
            ChartDataPoint(date: Date().addingTimeInterval(-6 * 24 * 3600), value: 25),
            ChartDataPoint(date: Date().addingTimeInterval(-5 * 24 * 3600), value: 30),
            ChartDataPoint(date: Date().addingTimeInterval(-4 * 24 * 3600), value: 28),
            ChartDataPoint(date: Date().addingTimeInterval(-3 * 24 * 3600), value: 35),
            ChartDataPoint(date: Date().addingTimeInterval(-2 * 24 * 3600), value: 32),
            ChartDataPoint(date: Date().addingTimeInterval(-1 * 24 * 3600), value: 38),
            ChartDataPoint(date: Date(), value: 40)
        ]
    }
    
    private func generateSuccessRateData() -> [ChartDataPoint] {
        // Generate sample success rate data
        return [
            ChartDataPoint(date: Date().addingTimeInterval(-6 * 24 * 3600), value: 0.6),
            ChartDataPoint(date: Date().addingTimeInterval(-5 * 24 * 3600), value: 0.65),
            ChartDataPoint(date: Date().addingTimeInterval(-4 * 24 * 3600), value: 0.7),
            ChartDataPoint(date: Date().addingTimeInterval(-3 * 24 * 3600), value: 0.75),
            ChartDataPoint(date: Date().addingTimeInterval(-2 * 24 * 3600), value: 0.8),
            ChartDataPoint(date: Date().addingTimeInterval(-1 * 24 * 3600), value: 0.85),
            ChartDataPoint(date: Date(), value: 0.9)
        ]
    }
}

// MARK: - Supporting Views

struct InsightMetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let trend: TrendDirection
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Spacer()
                
                Image(systemName: trendIcon)
                    .font(.caption)
                    .foregroundColor(trendColor)
            }
            
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
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var trendIcon: String {
        switch trend {
        case .up: return "arrow.up.circle.fill"
        case .down: return "arrow.down.circle.fill"
        case .neutral: return "minus.circle.fill"
        }
    }
    
    private var trendColor: Color {
        switch trend {
        case .up: return .green
        case .down: return .red
        case .neutral: return .gray
        }
    }
}

enum TrendDirection {
    case up, down, neutral
}

struct ChartCard<Content: View>: View {
    let title: String
    let subtitle: String
    let content: Content
    
    init(title: String, subtitle: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.subtitle = subtitle
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            content
                .frame(height: 200)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct SessionDurationChart: View {
    let data: [ChartDataPoint]
    
    var body: some View {
        Chart(data) { point in
            LineMark(
                x: .value("Date", point.date),
                y: .value("Duration", point.value)
            )
            .foregroundStyle(.blue)
            .interpolationMethod(.catmullRom)
            
            AreaMark(
                x: .value("Date", point.date),
                y: .value("Duration", point.value)
            )
            .foregroundStyle(.blue.opacity(0.1))
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .day)) { _ in
                AxisGridLine()
                AxisTick()
                AxisValueLabel(format: .dateTime.day())
            }
        }
        .chartYAxis {
            AxisMarks { value in
                AxisGridLine()
                AxisTick()
                AxisValueLabel("\(value.as(Double.self)?.formatted(.number) ?? "")m")
            }
        }
    }
}

struct SuccessRateChart: View {
    let data: [ChartDataPoint]
    
    var body: some View {
        Chart(data) { point in
            LineMark(
                x: .value("Date", point.date),
                y: .value("Success Rate", point.value)
            )
            .foregroundStyle(.green)
            .interpolationMethod(.catmullRom)
            
            AreaMark(
                x: .value("Date", point.date),
                y: .value("Success Rate", point.value)
            )
            .foregroundStyle(.green.opacity(0.1))
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .day)) { _ in
                AxisGridLine()
                AxisTick()
                AxisValueLabel(format: .dateTime.day())
            }
        }
        .chartYAxis {
            AxisMarks { value in
                AxisGridLine()
                AxisTick()
                AxisValueLabel("\(Int((value.as(Double.self) ?? 0) * 100))%")
            }
        }
    }
}

struct GoalDistributionChart: View {
    let goals: [HealthGoal.HealthGoalType]
    
    var body: some View {
        Chart(goalData, id: \.goal) { item in
            SectorMark(
                angle: .value("Count", item.count),
                innerRadius: .ratio(0.5),
                angularInset: 2
            )
            .foregroundStyle(by: .value("Goal", item.goal.displayName))
        }
        .chartLegend(position: .bottom)
    }
    
    private var goalData: [GoalData] {
        let counts = Dictionary(grouping: goals, by: { $0 }).mapValues { $0.count }
        return counts.map { GoalData(goal: $0.key, count: $0.value) }
    }
}

struct GoalAnalysisCard: View {
    let goalType: HealthGoal.HealthGoalType
    
    var body: some View {
        HStack {
            Image(systemName: goalIcon)
                .font(.title2)
                .foregroundColor(.blue)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(goalType.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("Most common goal type")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("75%")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.green)
                
                Text("Success Rate")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var goalIcon: String {
        switch goalType {
        case .weightLoss: return "scalemass"
        case .cardiovascularHealth: return "heart.fill"
        case .sleepOptimization: return "bed.double.fill"
        case .stressReduction: return "brain.head.profile"
        case .generalWellness: return "leaf.fill"
        }
    }
}

struct ImprovementAreaCard: View {
    let area: String
    
    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.title2)
                .foregroundColor(.orange)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(area)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("Focus area for improvement")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button("Learn More") {
                // Show improvement tips
            }
            .font(.caption)
            .foregroundColor(.blue)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct RecommendationCard: View {
    let recommendation: String
    
    var body: some View {
        HStack {
            Image(systemName: "lightbulb.fill")
                .font(.title2)
                .foregroundColor(.yellow)
            
            Text(recommendation)
                .font(.subheadline)
                .foregroundColor(.primary)
            
            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Supporting Models

struct ChartDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
}

struct GoalData {
    let goal: HealthGoal.HealthGoalType
    let count: Int
}

enum Timeframe: String, CaseIterable {
    case week = "week"
    case month = "month"
    case quarter = "quarter"
    case year = "year"
    
    var displayName: String {
        switch self {
        case .week: return "1 Week"
        case .month: return "1 Month"
        case .quarter: return "3 Months"
        case .year: return "1 Year"
        }
    }
}

// MARK: - Preview
#Preview {
    CoachingInsightsView(coachingEngine: RealTimeHealthCoachingEngine(
        healthDataManager: HealthDataManager(),
        predictionEngine: AdvancedHealthPredictionEngine(),
        analyticsEngine: AnalyticsEngine()
    ))
} 
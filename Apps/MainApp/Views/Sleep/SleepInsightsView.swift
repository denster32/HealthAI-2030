import SwiftUI
import Charts

/// Sleep Insights View
/// Displays comprehensive sleep analytics, trends, and personalized insights
@available(iOS 18.0, macOS 15.0, *)
public struct SleepInsightsView: View {
    
    // MARK: - State
    @ObservedObject var sleepEngine: AdvancedSleepIntelligenceEngine
    @State private var insights: SleepInsights?
    @State private var selectedTimeframe: Timeframe = .week
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
                        
                        // Sleep Trends
                        trendsSection(insights)
                        
                        // Sleep Quality Analysis
                        qualityAnalysisSection(insights)
                        
                        // Common Issues
                        issuesSection(insights)
                        
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
            .navigationTitle("Sleep Insights")
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
            
            Text("Analyzing Sleep Data...")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    // MARK: - Empty State Section
    private var emptyStateSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "bed.double")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No Sleep Insights Available")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Complete your first sleep tracking session to see personalized insights and analytics.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Start Sleep Tracking") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
    
    // MARK: - Overview Section
    private func overviewSection(_ insights: SleepInsights) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Overview")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                InsightMetricCard(
                    title: "Avg. Duration",
                    value: formatDuration(insights.averageSleepDuration),
                    icon: "clock",
                    color: .blue,
                    trend: insights.averageSleepDuration >= 7.0 ? .up : .down
                )
                
                InsightMetricCard(
                    title: "Avg. Efficiency",
                    value: "\(Int(insights.averageSleepEfficiency * 100))%",
                    icon: "chart.line.uptrend.xyaxis",
                    color: .green,
                    trend: insights.averageSleepEfficiency >= 0.85 ? .up : .down
                )
                
                InsightMetricCard(
                    title: "Quality Trend",
                    value: insights.sleepQualityTrend.displayName,
                    icon: "star.fill",
                    color: insights.sleepQualityTrend.color,
                    trend: insights.sleepQualityTrend.trendDirection
                )
                
                InsightMetricCard(
                    title: "Sleep Score",
                    value: "\(Int(sleepEngine.sleepScore * 100))",
                    icon: "target",
                    color: .purple,
                    trend: sleepEngine.sleepScore >= 0.8 ? .up : .down
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Trends Section
    private func trendsSection(_ insights: SleepInsights) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Sleep Trends")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 20) {
                // Sleep Duration Trend
                ChartCard(
                    title: "Sleep Duration Trend",
                    subtitle: "Last \(selectedTimeframe.rawValue)"
                ) {
                    SleepDurationTrendChart(data: generateDurationTrendData())
                }
                
                // Sleep Efficiency Trend
                ChartCard(
                    title: "Sleep Efficiency Trend",
                    subtitle: "Quality over time"
                ) {
                    SleepEfficiencyTrendChart(data: generateEfficiencyTrendData())
                }
                
                // Sleep Quality Trend
                ChartCard(
                    title: "Sleep Quality Trend",
                    subtitle: "Overall sleep quality"
                ) {
                    SleepQualityTrendChart(trend: insights.sleepQualityTrend)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Quality Analysis Section
    private func qualityAnalysisSection(_ insights: SleepInsights) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Sleep Quality Analysis")
                .font(.headline)
                .fontWeight(.semibold)
            
            if let analysis = insights.latestAnalysis {
                VStack(spacing: 16) {
                    // Sleep Stage Distribution
                    ChartCard(
                        title: "Sleep Stage Distribution",
                        subtitle: "Last night's sleep stages"
                    ) {
                        SleepStageDistributionChart(analysis: analysis)
                    }
                    
                    // Sleep Metrics
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        SleepMetricCard(
                            title: "Deep Sleep",
                            value: "\(Int(analysis.deepSleepPercentage * 100))%",
                            target: "20-25%",
                            color: analysis.deepSleepPercentage >= 0.2 ? .green : .orange
                        )
                        
                        SleepMetricCard(
                            title: "REM Sleep",
                            value: "\(Int(analysis.remSleepPercentage * 100))%",
                            target: "20-25%",
                            color: analysis.remSleepPercentage >= 0.2 ? .green : .orange
                        )
                        
                        SleepMetricCard(
                            title: "Light Sleep",
                            value: "\(Int(analysis.lightSleepPercentage * 100))%",
                            target: "45-55%",
                            color: analysis.lightSleepPercentage >= 0.45 && analysis.lightSleepPercentage <= 0.55 ? .green : .orange
                        )
                        
                        SleepMetricCard(
                            title: "Awake Time",
                            value: "\(Int(analysis.awakePercentage * 100))%",
                            target: "<5%",
                            color: analysis.awakePercentage < 0.05 ? .green : .red
                        )
                    }
                }
            } else {
                Text("No recent sleep analysis available.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding()
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Issues Section
    private func issuesSection(_ insights: SleepInsights) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Common Issues")
                .font(.headline)
                .fontWeight(.semibold)
            
            if insights.commonIssues.isEmpty {
                Text("Great job! No common sleep issues identified.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                VStack(spacing: 12) {
                    ForEach(insights.commonIssues, id: \.self) { issue in
                        SleepIssueCard(issue: issue)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Improvement Areas Section
    private func improvementAreasSection(_ insights: SleepInsights) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Areas for Improvement")
                .font(.headline)
                .fontWeight(.semibold)
            
            if insights.improvementAreas.isEmpty {
                Text("Excellent sleep habits! No specific improvement areas identified.")
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
    private func recommendationsSection(_ insights: SleepInsights) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Personalized Recommendations")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                ForEach(insights.recommendations, id: \.self) { recommendation in
                    SleepRecommendationCard(recommendation: recommendation)
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
            let insights = await sleepEngine.getSleepInsights(timeframe: selectedTimeframe)
            await MainActor.run {
                self.insights = insights
                self.isLoading = false
            }
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration / 3600)
        let minutes = Int((duration.truncatingRemainder(dividingBy: 3600)) / 60)
        return "\(hours)h \(minutes)m"
    }
    
    private func generateDurationTrendData() -> [ChartDataPoint] {
        // Generate sample duration trend data
        return [
            ChartDataPoint(date: Date().addingTimeInterval(-6 * 24 * 3600), value: 7.5),
            ChartDataPoint(date: Date().addingTimeInterval(-5 * 24 * 3600), value: 8.0),
            ChartDataPoint(date: Date().addingTimeInterval(-4 * 24 * 3600), value: 7.0),
            ChartDataPoint(date: Date().addingTimeInterval(-3 * 24 * 3600), value: 8.5),
            ChartDataPoint(date: Date().addingTimeInterval(-2 * 24 * 3600), value: 7.8),
            ChartDataPoint(date: Date().addingTimeInterval(-1 * 24 * 3600), value: 8.2),
            ChartDataPoint(date: Date(), value: 7.9)
        ]
    }
    
    private func generateEfficiencyTrendData() -> [ChartDataPoint] {
        // Generate sample efficiency trend data
        return [
            ChartDataPoint(date: Date().addingTimeInterval(-6 * 24 * 3600), value: 0.85),
            ChartDataPoint(date: Date().addingTimeInterval(-5 * 24 * 3600), value: 0.90),
            ChartDataPoint(date: Date().addingTimeInterval(-4 * 24 * 3600), value: 0.80),
            ChartDataPoint(date: Date().addingTimeInterval(-3 * 24 * 3600), value: 0.92),
            ChartDataPoint(date: Date().addingTimeInterval(-2 * 24 * 3600), value: 0.87),
            ChartDataPoint(date: Date().addingTimeInterval(-1 * 24 * 3600), value: 0.89),
            ChartDataPoint(date: Date(), value: 0.86)
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

struct SleepDurationTrendChart: View {
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
                AxisValueLabel("\(value.as(Double.self)?.formatted(.number) ?? "")h")
            }
        }
    }
}

struct SleepEfficiencyTrendChart: View {
    let data: [ChartDataPoint]
    
    var body: some View {
        Chart(data) { point in
            LineMark(
                x: .value("Date", point.date),
                y: .value("Efficiency", point.value)
            )
            .foregroundStyle(.green)
            .interpolationMethod(.catmullRom)
            
            AreaMark(
                x: .value("Date", point.date),
                y: .value("Efficiency", point.value)
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

struct SleepQualityTrendChart: View {
    let trend: TrendDirection
    
    var body: some View {
        VStack {
            Image(systemName: trendIcon)
                .font(.system(size: 60))
                .foregroundColor(trendColor)
            
            Text(trend.displayName)
                .font(.headline)
                .fontWeight(.semibold)
            
            Text(trend.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(height: 200)
    }
    
    private var trendIcon: String {
        switch trend {
        case .improving: return "arrow.up.circle.fill"
        case .declining: return "arrow.down.circle.fill"
        case .stable: return "minus.circle.fill"
        case .neutral: return "circle"
        }
    }
    
    private var trendColor: Color {
        switch trend {
        case .improving: return .green
        case .declining: return .red
        case .stable: return .blue
        case .neutral: return .gray
        }
    }
}

struct SleepStageDistributionChart: View {
    let analysis: SleepAnalysis
    
    var body: some View {
        Chart(stageData, id: \.stage) { item in
            SectorMark(
                angle: .value("Percentage", item.percentage),
                innerRadius: .ratio(0.5),
                angularInset: 2
            )
            .foregroundStyle(by: .value("Stage", item.stage.displayName))
        }
        .chartLegend(position: .bottom)
    }
    
    private var stageData: [StageData] {
        return [
            StageData(stage: .deep, percentage: analysis.deepSleepPercentage),
            StageData(stage: .rem, percentage: analysis.remSleepPercentage),
            StageData(stage: .light, percentage: analysis.lightSleepPercentage),
            StageData(stage: .awake, percentage: analysis.awakePercentage)
        ]
    }
}

struct SleepMetricCard: View {
    let title: String
    let value: String
    let target: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text("Target: \(target)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct SleepIssueCard: View {
    let issue: String
    
    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.title2)
                .foregroundColor(.orange)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(issue)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("Consider addressing this issue for better sleep quality")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct ImprovementAreaCard: View {
    let area: String
    
    var body: some View {
        HStack {
            Image(systemName: "target")
                .font(.title2)
                .foregroundColor(.blue)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(area)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("Focus area for improvement")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct SleepRecommendationCard: View {
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

struct StageData {
    let stage: SleepStage.StageType
    let percentage: Double
}

extension SleepStage.StageType {
    var displayName: String {
        switch self {
        case .awake: return "Awake"
        case .light: return "Light"
        case .deep: return "Deep"
        case .rem: return "REM"
        }
    }
}

extension TrendDirection {
    var displayName: String {
        switch self {
        case .improving: return "Improving"
        case .declining: return "Declining"
        case .stable: return "Stable"
        case .neutral: return "Neutral"
        }
    }
    
    var description: String {
        switch self {
        case .improving: return "Your sleep quality is trending upward"
        case .declining: return "Your sleep quality needs attention"
        case .stable: return "Your sleep quality is consistent"
        case .neutral: return "Insufficient data for trend analysis"
        }
    }
    
    var color: Color {
        switch self {
        case .improving: return .green
        case .declining: return .red
        case .stable: return .blue
        case .neutral: return .gray
        }
    }
    
    var trendDirection: TrendDirection {
        return self
    }
}

extension Timeframe {
    var displayName: String {
        switch self {
        case .day: return "1 Day"
        case .week: return "1 Week"
        case .month: return "1 Month"
        case .quarter: return "3 Months"
        }
    }
}

// MARK: - Preview
#Preview {
    SleepInsightsView(sleepEngine: AdvancedSleepIntelligenceEngine(
        healthDataManager: HealthDataManager(),
        predictionEngine: AdvancedHealthPredictionEngine(),
        analyticsEngine: AnalyticsEngine()
    ))
} 
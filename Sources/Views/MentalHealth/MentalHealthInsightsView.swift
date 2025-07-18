import SwiftUI
import Charts

/// Mental Health Insights View
/// Displays comprehensive mental health analytics, trends, and personalized insights
@available(iOS 18.0, macOS 15.0, *)
public struct MentalHealthInsightsView: View {
    
    // MARK: - State
    @ObservedObject var mentalHealthEngine: AdvancedMentalHealthEngine
    @State private var insights: MentalHealthInsights?
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
                        
                        // Stress Analysis
                        stressAnalysisSection(insights)
                        
                        // Mood Analysis
                        moodAnalysisSection(insights)
                        
                        // Wellness Trends
                        wellnessTrendsSection(insights)
                        
                        // Common Stressors
                        stressorsSection(insights)
                        
                        // Mood Patterns
                        moodPatternsSection(insights)
                        
                        // Recommendations
                        recommendationsSection(insights)
                    } else {
                        emptyStateSection
                    }
                }
                .padding()
            }
            .navigationTitle("Mental Health Insights")
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
            
            Text("Analyzing Mental Health Data...")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    // MARK: - Empty State Section
    private var emptyStateSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No Mental Health Insights Available")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Start monitoring your mental health to see personalized insights and analytics.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Start Monitoring") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
    
    // MARK: - Overview Section
    private func overviewSection(_ insights: MentalHealthInsights) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Overview")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                InsightMetricCard(
                    title: "Avg. Stress Level",
                    value: insights.averageStressLevel.displayName,
                    icon: "brain.head.profile",
                    color: insights.averageStressLevel.color,
                    trend: insights.stressTrend.trendDirection
                )
                
                InsightMetricCard(
                    title: "Avg. Mood Score",
                    value: "\(Int(insights.averageMoodScore * 100))%",
                    icon: "face.smiling",
                    color: .orange,
                    trend: insights.moodTrend.trendDirection
                )
                
                InsightMetricCard(
                    title: "Wellness Trend",
                    value: insights.wellnessTrend.displayName,
                    icon: "heart.fill",
                    color: insights.wellnessTrend.color,
                    trend: insights.wellnessTrend.trendDirection
                )
                
                InsightMetricCard(
                    title: "Mental Health Score",
                    value: "\(Int(mentalHealthEngine.wellnessScore * 100))",
                    icon: "target",
                    color: .purple,
                    trend: mentalHealthEngine.wellnessScore >= 0.8 ? .up : .down
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Stress Analysis Section
    private func stressAnalysisSection(_ insights: MentalHealthInsights) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Stress Analysis")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 20) {
                // Stress Trend Chart
                ChartCard(
                    title: "Stress Level Trend",
                    subtitle: "Last \(selectedTimeframe.rawValue)"
                ) {
                    StressInsightsChart(data: generateStressInsightsData())
                }
                
                // Stress Level Distribution
                ChartCard(
                    title: "Stress Level Distribution",
                    subtitle: "Frequency of stress levels"
                ) {
                    StressDistributionChart(insights: insights)
                }
                
                // Stress Trend Indicator
                StressTrendCard(trend: insights.stressTrend)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Mood Analysis Section
    private func moodAnalysisSection(_ insights: MentalHealthInsights) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Mood Analysis")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 20) {
                // Mood Trend Chart
                ChartCard(
                    title: "Mood Score Trend",
                    subtitle: "Mood over time"
                ) {
                    MoodInsightsChart(data: generateMoodInsightsData())
                }
                
                // Mood Pattern Analysis
                ChartCard(
                    title: "Mood Pattern Analysis",
                    subtitle: "Mood patterns and cycles"
                ) {
                    MoodPatternChart(insights: insights)
                }
                
                // Mood Trend Indicator
                MoodTrendCard(trend: insights.moodTrend)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Wellness Trends Section
    private func wellnessTrendsSection(_ insights: MentalHealthInsights) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Wellness Trends")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 20) {
                // Wellness Score Chart
                ChartCard(
                    title: "Wellness Score Trend",
                    subtitle: "Overall wellness over time"
                ) {
                    WellnessInsightsChart(data: generateWellnessInsightsData())
                }
                
                // Wellness Components
                ChartCard(
                    title: "Wellness Components",
                    subtitle: "Breakdown of wellness factors"
                ) {
                    WellnessComponentsChart(insights: insights)
                }
                
                // Wellness Trend Indicator
                WellnessTrendCard(trend: insights.wellnessTrend)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Stressors Section
    private func stressorsSection(_ insights: MentalHealthInsights) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Common Stressors")
                .font(.headline)
                .fontWeight(.semibold)
            
            if insights.commonStressors.isEmpty {
                Text("Great job! No common stressors identified.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                VStack(spacing: 12) {
                    ForEach(insights.commonStressors, id: \.self) { stressor in
                        StressorCard(stressor: stressor)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Mood Patterns Section
    private func moodPatternsSection(_ insights: MentalHealthInsights) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Mood Patterns")
                .font(.headline)
                .fontWeight(.semibold)
            
            if insights.moodPatterns.isEmpty {
                Text("No specific mood patterns identified.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                VStack(spacing: 12) {
                    ForEach(insights.moodPatterns, id: \.self) { pattern in
                        MoodPatternCard(pattern: pattern)
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
    private func recommendationsSection(_ insights: MentalHealthInsights) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Personalized Recommendations")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                ForEach(insights.recommendations, id: \.self) { recommendation in
                    MentalHealthRecommendationCard(recommendation: recommendation)
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
            let insights = await mentalHealthEngine.getMentalHealthInsights(timeframe: selectedTimeframe)
            await MainActor.run {
                self.insights = insights
                self.isLoading = false
            }
        }
    }
    
    private func generateStressInsightsData() -> [ChartDataPoint] {
        // Generate sample stress insights data
        return [
            ChartDataPoint(date: Date().addingTimeInterval(-6 * 24 * 3600), value: 0.3),
            ChartDataPoint(date: Date().addingTimeInterval(-5 * 24 * 3600), value: 0.4),
            ChartDataPoint(date: Date().addingTimeInterval(-4 * 24 * 3600), value: 0.2),
            ChartDataPoint(date: Date().addingTimeInterval(-3 * 24 * 3600), value: 0.5),
            ChartDataPoint(date: Date().addingTimeInterval(-2 * 24 * 3600), value: 0.3),
            ChartDataPoint(date: Date().addingTimeInterval(-1 * 24 * 3600), value: 0.4),
            ChartDataPoint(date: Date(), value: 0.3)
        ]
    }
    
    private func generateMoodInsightsData() -> [ChartDataPoint] {
        // Generate sample mood insights data
        return [
            ChartDataPoint(date: Date().addingTimeInterval(-6 * 24 * 3600), value: 0.7),
            ChartDataPoint(date: Date().addingTimeInterval(-5 * 24 * 3600), value: 0.8),
            ChartDataPoint(date: Date().addingTimeInterval(-4 * 24 * 3600), value: 0.6),
            ChartDataPoint(date: Date().addingTimeInterval(-3 * 24 * 3600), value: 0.9),
            ChartDataPoint(date: Date().addingTimeInterval(-2 * 24 * 3600), value: 0.7),
            ChartDataPoint(date: Date().addingTimeInterval(-1 * 24 * 3600), value: 0.8),
            ChartDataPoint(date: Date(), value: 0.7)
        ]
    }
    
    private func generateWellnessInsightsData() -> [ChartDataPoint] {
        // Generate sample wellness insights data
        return [
            ChartDataPoint(date: Date().addingTimeInterval(-6 * 24 * 3600), value: 0.75),
            ChartDataPoint(date: Date().addingTimeInterval(-5 * 24 * 3600), value: 0.80),
            ChartDataPoint(date: Date().addingTimeInterval(-4 * 24 * 3600), value: 0.70),
            ChartDataPoint(date: Date().addingTimeInterval(-3 * 24 * 3600), value: 0.85),
            ChartDataPoint(date: Date().addingTimeInterval(-2 * 24 * 3600), value: 0.75),
            ChartDataPoint(date: Date().addingTimeInterval(-1 * 24 * 3600), value: 0.80),
            ChartDataPoint(date: Date(), value: 0.75)
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
        case .increasing: return "arrow.up.circle.fill"
        case .decreasing: return "arrow.down.circle.fill"
        case .improving: return "arrow.up.circle.fill"
        case .declining: return "arrow.down.circle.fill"
        case .stable: return "minus.circle.fill"
        }
    }
    
    private var trendColor: Color {
        switch trend {
        case .up, .increasing, .improving: return .green
        case .down, .decreasing, .declining: return .red
        case .neutral, .stable: return .gray
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

struct StressInsightsChart: View {
    let data: [ChartDataPoint]
    
    var body: some View {
        Chart(data) { point in
            LineMark(
                x: .value("Date", point.date),
                y: .value("Stress", point.value)
            )
            .foregroundStyle(.red)
            .interpolationMethod(.catmullRom)
            
            AreaMark(
                x: .value("Date", point.date),
                y: .value("Stress", point.value)
            )
            .foregroundStyle(.red.opacity(0.1))
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

struct MoodInsightsChart: View {
    let data: [ChartDataPoint]
    
    var body: some View {
        Chart(data) { point in
            LineMark(
                x: .value("Date", point.date),
                y: .value("Mood", point.value)
            )
            .foregroundStyle(.orange)
            .interpolationMethod(.catmullRom)
            
            AreaMark(
                x: .value("Date", point.date),
                y: .value("Mood", point.value)
            )
            .foregroundStyle(.orange.opacity(0.1))
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

struct WellnessInsightsChart: View {
    let data: [ChartDataPoint]
    
    var body: some View {
        Chart(data) { point in
            LineMark(
                x: .value("Date", point.date),
                y: .value("Wellness", point.value)
            )
            .foregroundStyle(.green)
            .interpolationMethod(.catmullRom)
            
            AreaMark(
                x: .value("Date", point.date),
                y: .value("Wellness", point.value)
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

struct StressDistributionChart: View {
    let insights: MentalHealthInsights
    
    var body: some View {
        Chart(stressData, id: \.level) { item in
            BarMark(
                x: .value("Level", item.level.displayName),
                y: .value("Frequency", item.frequency)
            )
            .foregroundStyle(by: .value("Level", item.level.displayName))
        }
        .chartLegend(position: .bottom)
    }
    
    private var stressData: [StressData] {
        return [
            StressData(level: .low, frequency: 0.4),
            StressData(level: .moderate, frequency: 0.4),
            StressData(level: .high, frequency: 0.2)
        ]
    }
}

struct MoodPatternChart: View {
    let insights: MentalHealthInsights
    
    var body: some View {
        Chart(moodData, id: \.pattern) { item in
            BarMark(
                x: .value("Pattern", item.pattern),
                y: .value("Frequency", item.frequency)
            )
            .foregroundStyle(by: .value("Pattern", item.pattern))
        }
        .chartLegend(position: .bottom)
    }
    
    private var moodData: [MoodData] {
        return [
            MoodData(pattern: "Positive", frequency: 0.6),
            MoodData(pattern: "Neutral", frequency: 0.3),
            MoodData(pattern: "Negative", frequency: 0.1)
        ]
    }
}

struct WellnessComponentsChart: View {
    let insights: MentalHealthInsights
    
    var body: some View {
        Chart(wellnessData, id: \.component) { item in
            SectorMark(
                angle: .value("Score", item.score),
                innerRadius: .ratio(0.5),
                angularInset: 2
            )
            .foregroundStyle(by: .value("Component", item.component))
        }
        .chartLegend(position: .bottom)
    }
    
    private var wellnessData: [WellnessData] {
        return [
            WellnessData(component: "Stress", score: 0.7),
            WellnessData(component: "Mood", score: 0.8),
            WellnessData(component: "Energy", score: 0.6),
            WellnessData(component: "Social", score: 0.9)
        ]
    }
}

struct StressTrendCard: View {
    let trend: TrendDirection
    
    var body: some View {
        VStack {
            Image(systemName: trendIcon)
                .font(.system(size: 40))
                .foregroundColor(trendColor)
            
            Text(trend.displayName)
                .font(.headline)
                .fontWeight(.semibold)
            
            Text(trend.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(height: 120)
    }
    
    private var trendIcon: String {
        switch trend {
        case .improving: return "arrow.up.circle.fill"
        case .declining: return "arrow.down.circle.fill"
        case .stable: return "minus.circle.fill"
        case .neutral: return "circle"
        case .increasing: return "arrow.up.circle.fill"
        case .decreasing: return "arrow.down.circle.fill"
        case .up: return "arrow.up.circle.fill"
        case .down: return "arrow.down.circle.fill"
        }
    }
    
    private var trendColor: Color {
        switch trend {
        case .improving, .up, .decreasing: return .green
        case .declining, .down, .increasing: return .red
        case .stable, .neutral: return .gray
        }
    }
}

struct MoodTrendCard: View {
    let trend: TrendDirection
    
    var body: some View {
        VStack {
            Image(systemName: trendIcon)
                .font(.system(size: 40))
                .foregroundColor(trendColor)
            
            Text(trend.displayName)
                .font(.headline)
                .fontWeight(.semibold)
            
            Text(trend.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(height: 120)
    }
    
    private var trendIcon: String {
        switch trend {
        case .improving: return "face.smiling"
        case .declining: return "face.dashed"
        case .stable: return "face.neutral"
        case .neutral: return "circle"
        case .increasing: return "arrow.up.circle.fill"
        case .decreasing: return "arrow.down.circle.fill"
        case .up: return "arrow.up.circle.fill"
        case .down: return "arrow.down.circle.fill"
        }
    }
    
    private var trendColor: Color {
        switch trend {
        case .improving, .up, .decreasing: return .green
        case .declining, .down, .increasing: return .red
        case .stable, .neutral: return .gray
        }
    }
}

struct WellnessTrendCard: View {
    let trend: TrendDirection
    
    var body: some View {
        VStack {
            Image(systemName: trendIcon)
                .font(.system(size: 40))
                .foregroundColor(trendColor)
            
            Text(trend.displayName)
                .font(.headline)
                .fontWeight(.semibold)
            
            Text(trend.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(height: 120)
    }
    
    private var trendIcon: String {
        switch trend {
        case .improving: return "heart.fill"
        case .declining: return "heart"
        case .stable: return "heart.circle"
        case .neutral: return "circle"
        case .increasing: return "arrow.up.circle.fill"
        case .decreasing: return "arrow.down.circle.fill"
        case .up: return "arrow.up.circle.fill"
        case .down: return "arrow.down.circle.fill"
        }
    }
    
    private var trendColor: Color {
        switch trend {
        case .improving, .up, .decreasing: return .green
        case .declining, .down, .increasing: return .red
        case .stable, .neutral: return .gray
        }
    }
}

struct StressorCard: View {
    let stressor: String
    
    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.title2)
                .foregroundColor(.orange)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(stressor)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("Consider stress management techniques")
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

struct MoodPatternCard: View {
    let pattern: String
    
    var body: some View {
        HStack {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.title2)
                .foregroundColor(.blue)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(pattern)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("Mood pattern identified")
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

struct MentalHealthRecommendationCard: View {
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

struct StressData {
    let level: StressLevel
    let frequency: Double
}

struct MoodData {
    let pattern: String
    let frequency: Double
}

struct WellnessData {
    let component: String
    let score: Double
}

extension TrendDirection {
    var displayName: String {
        switch self {
        case .improving: return "Improving"
        case .declining: return "Declining"
        case .stable: return "Stable"
        case .neutral: return "Neutral"
        case .increasing: return "Increasing"
        case .decreasing: return "Decreasing"
        case .up: return "Up"
        case .down: return "Down"
        }
    }
    
    var description: String {
        switch self {
        case .improving: return "Your mental health is trending upward"
        case .declining: return "Your mental health needs attention"
        case .stable: return "Your mental health is consistent"
        case .neutral: return "Insufficient data for trend analysis"
        case .increasing: return "Stress levels are increasing"
        case .decreasing: return "Stress levels are decreasing"
        case .up: return "Positive trend detected"
        case .down: return "Negative trend detected"
        }
    }
    
    var color: Color {
        switch self {
        case .improving, .up, .decreasing: return .green
        case .declining, .down, .increasing: return .red
        case .stable, .neutral: return .gray
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
    MentalHealthInsightsView(mentalHealthEngine: AdvancedMentalHealthEngine(
        healthDataManager: HealthDataManager(),
        predictionEngine: AdvancedHealthPredictionEngine(),
        analyticsEngine: AnalyticsEngine()
    ))
} 
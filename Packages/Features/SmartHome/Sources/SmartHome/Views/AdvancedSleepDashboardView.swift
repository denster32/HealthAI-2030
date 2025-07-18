import SwiftUI
import Charts
import HealthKit

/// Advanced Sleep Intelligence Dashboard
/// Provides comprehensive sleep analysis, tracking, and optimization
@available(iOS 18.0, macOS 15.0, *)
public struct AdvancedSleepDashboardView: View {
    
    // MARK: - State
    @StateObject private var sleepEngine: AdvancedSleepIntelligenceEngine
    @State private var showingPreferences = false
    @State private var showingInsights = false
    @State private var selectedOptimization: SleepOptimization?
    @State private var isVoiceEnabled = false
    @State private var selectedTimeframe: Timeframe = .week
    
    // MARK: - Environment
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Initialization
    public init(healthDataManager: HealthDataManager,
                predictionEngine: AdvancedHealthPredictionEngine,
                analyticsEngine: AnalyticsEngine) {
        self._sleepEngine = StateObject(wrappedValue: AdvancedSleepIntelligenceEngine(
            healthDataManager: healthDataManager,
            predictionEngine: predictionEngine,
            analyticsEngine: analyticsEngine
        ))
    }
    
    // MARK: - Body
    public var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header Section
                    headerSection
                    
                    // Sleep Score Card
                    sleepScoreSection
                    
                    // Current Session
                    if sleepEngine.isSleepTrackingActive {
                        currentSessionSection
                    } else {
                        startTrackingSection
                    }
                    
                    // Sleep Analysis
                    sleepAnalysisSection
                    
                    // Optimization Recommendations
                    optimizationSection
                    
                    // Sleep Trends
                    trendsSection
                    
                    // Environment Monitoring
                    environmentSection
                }
                .padding()
            }
            .navigationTitle("Sleep Intelligence")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Insights") {
                            showingInsights = true
                        }
                        
                        Button("Preferences") {
                            showingPreferences = true
                        }
                        
                        Button(isVoiceEnabled ? "Disable Voice" : "Enable Voice") {
                            isVoiceEnabled.toggle()
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showingPreferences) {
            SleepPreferencesView(sleepEngine: sleepEngine)
        }
        .sheet(isPresented: $showingInsights) {
            SleepInsightsView(sleepEngine: sleepEngine)
        }
        .sheet(item: $selectedOptimization) { optimization in
            SleepOptimizationDetailView(optimization: optimization, sleepEngine: sleepEngine)
        }
        .onAppear {
            loadSleepData()
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "bed.double.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.indigo)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Sleep Intelligence")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    HStack {
                        Circle()
                            .fill(sleepEngine.isSleepTrackingActive ? .green : .gray)
                            .frame(width: 8, height: 8)
                        
                        Text(sleepEngine.isSleepTrackingActive ? "Tracking Active" : "Ready to Track")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Voice Toggle
                Button(action: {
                    isVoiceEnabled.toggle()
                }) {
                    Image(systemName: isVoiceEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
                        .font(.title2)
                        .foregroundColor(isVoiceEnabled ? .indigo : .gray)
                }
            }
            
            // Quick Stats
            HStack {
                QuickStatCard(
                    title: "Avg. Duration",
                    value: formatDuration(sleepEngine.sleepInsights?.averageSleepDuration ?? 0),
                    icon: "clock",
                    color: .blue
                )
                
                QuickStatCard(
                    title: "Efficiency",
                    value: "\(Int((sleepEngine.sleepInsights?.averageSleepEfficiency ?? 0) * 100))%",
                    icon: "chart.line.uptrend.xyaxis",
                    color: .green
                )
                
                QuickStatCard(
                    title: "Quality",
                    value: sleepQualityText,
                    icon: "star.fill",
                    color: .orange
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Sleep Score Section
    private var sleepScoreSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Sleep Score")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("\(Int(sleepEngine.sleepScore * 100))")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(sleepScoreColor)
            }
            
            // Sleep Score Gauge
            ZStack {
                Circle()
                    .stroke(Color(.systemGray5), lineWidth: 12)
                    .frame(width: 120, height: 120)
                
                Circle()
                    .trim(from: 0, to: sleepEngine.sleepScore)
                    .stroke(sleepScoreColor, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 1.0), value: sleepEngine.sleepScore)
                
                VStack {
                    Text("\(Int(sleepEngine.sleepScore * 100))")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Score")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Score Description
            Text(sleepScoreDescription)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Current Session Section
    private var currentSessionSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Current Sleep Session")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("End Session") {
                    endSleepTracking()
                }
                .foregroundColor(.red)
                .font(.subheadline)
            }
            
            if let session = sleepEngine.currentSleepSession {
                VStack(spacing: 12) {
                    HStack {
                        Text("Duration")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text(formatDuration(session.duration))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    
                    HStack {
                        Text("Environment")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text(session.environment.description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    // Real-time sleep stage indicator
                    if !session.sleepStages.isEmpty {
                        HStack {
                            Text("Current Stage")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Text(currentSleepStage)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.indigo)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Start Tracking Section
    private var startTrackingSection: some View {
        VStack(spacing: 16) {
            Text("Ready to Track Your Sleep?")
                .font(.headline)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
            
            Text("Start a sleep tracking session to get detailed insights and optimization recommendations.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Start Sleep Tracking") {
                startSleepTracking()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            
            Button("View Sleep History") {
                showingInsights = true
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Sleep Analysis Section
    private var sleepAnalysisSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Sleep Analysis")
                .font(.headline)
                .fontWeight(.semibold)
            
            if let insights = sleepEngine.sleepInsights {
                VStack(spacing: 12) {
                    // Sleep Duration Chart
                    ChartCard(
                        title: "Sleep Duration Trend",
                        subtitle: "Last \(selectedTimeframe.rawValue)"
                    ) {
                        SleepDurationChart(data: generateDurationData())
                    }
                    
                    // Sleep Efficiency Chart
                    ChartCard(
                        title: "Sleep Efficiency",
                        subtitle: "Quality over time"
                    ) {
                        SleepEfficiencyChart(data: generateEfficiencyData())
                    }
                    
                    // Sleep Stage Distribution
                    if let analysis = insights.latestAnalysis {
                        ChartCard(
                            title: "Sleep Stage Distribution",
                            subtitle: "Last night's sleep stages"
                        ) {
                            SleepStageChart(analysis: analysis)
                        }
                    }
                }
            } else {
                Text("No sleep data available. Start tracking to see your analysis.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Optimization Section
    private var optimizationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Optimization Recommendations")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("Refresh") {
                    refreshRecommendations()
                }
                .font(.subheadline)
                .foregroundColor(.indigo)
            }
            
            if sleepEngine.optimizationRecommendations.isEmpty {
                Text("No recommendations available. Complete a sleep session to get personalized recommendations.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(sleepEngine.optimizationRecommendations) { optimization in
                        SleepOptimizationCard(optimization: optimization) {
                            selectedOptimization = optimization
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Trends Section
    private var trendsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Sleep Trends")
                .font(.headline)
                .fontWeight(.semibold)
            
            if let insights = sleepEngine.sleepInsights {
                VStack(spacing: 12) {
                    TrendCard(
                        title: "Sleep Quality",
                        trend: insights.sleepQualityTrend,
                        value: "\(Int(insights.averageSleepEfficiency * 100))%"
                    )
                    
                    if !insights.commonIssues.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Common Issues")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            ForEach(insights.commonIssues, id: \.self) { issue in
                                HStack {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(.orange)
                                        .font(.caption)
                                    
                                    Text(issue)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                }
            } else {
                Text("No trend data available.")
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
    
    // MARK: - Environment Section
    private var environmentSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Sleep Environment")
                .font(.headline)
                .fontWeight(.semibold)
            
            if let session = sleepEngine.currentSleepSession {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    EnvironmentMetricCard(
                        title: "Temperature",
                        value: "\(Int(session.environment.temperature))°F",
                        icon: "thermometer",
                        color: session.environment.temperature > 72 || session.environment.temperature < 65 ? .red : .green
                    )
                    
                    EnvironmentMetricCard(
                        title: "Humidity",
                        value: "\(Int(session.environment.humidity * 100))%",
                        icon: "humidity",
                        color: session.environment.humidity > 0.6 ? .orange : .green
                    )
                    
                    EnvironmentMetricCard(
                        title: "Light Level",
                        value: "\(Int(session.environment.lightLevel * 100))%",
                        icon: "lightbulb",
                        color: session.environment.lightLevel > 0.3 ? .orange : .green
                    )
                    
                    EnvironmentMetricCard(
                        title: "Noise Level",
                        value: "\(Int(session.environment.noiseLevel * 100))%",
                        icon: "speaker.wave.2",
                        color: session.environment.noiseLevel > 0.5 ? .red : .green
                    )
                }
            } else {
                Text("Environment monitoring will start when you begin sleep tracking.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Helper Methods
    private func loadSleepData() {
        Task {
            _ = await sleepEngine.getSleepInsights(timeframe: selectedTimeframe)
        }
    }
    
    private func startSleepTracking() {
        Task {
            do {
                _ = try await sleepEngine.startSleepTracking()
                
                if isVoiceEnabled {
                    await sleepEngine.provideSleepCoaching("Sleep tracking started. I'll monitor your sleep environment and provide insights.")
                }
            } catch {
                print("Failed to start sleep tracking: \(error)")
            }
        }
    }
    
    private func endSleepTracking() {
        Task {
            do {
                let analysis = try await sleepEngine.endSleepTracking()
                
                if isVoiceEnabled {
                    await sleepEngine.provideSleepCoaching("Sleep tracking completed. Your sleep score is \(Int(sleepEngine.sleepScore * 100)).")
                }
            } catch {
                print("Failed to end sleep tracking: \(error)")
            }
        }
    }
    
    private func refreshRecommendations() {
        Task {
            do {
                _ = try await sleepEngine.generateOptimizationRecommendations()
            } catch {
                print("Failed to refresh recommendations: \(error)")
            }
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration / 3600)
        let minutes = Int((duration.truncatingRemainder(dividingBy: 3600)) / 60)
        return "\(hours)h \(minutes)m"
    }
    
    private var sleepQualityText: String {
        let score = sleepEngine.sleepScore
        if score >= 0.8 { return "Excellent" }
        else if score >= 0.6 { return "Good" }
        else if score >= 0.4 { return "Fair" }
        else { return "Poor" }
    }
    
    private var sleepScoreColor: Color {
        let score = sleepEngine.sleepScore
        if score >= 0.8 { return .green }
        else if score >= 0.6 { return .orange }
        else { return .red }
    }
    
    private var sleepScoreDescription: String {
        let score = sleepEngine.sleepScore
        if score >= 0.8 { return "Excellent sleep quality! Keep up the great work." }
        else if score >= 0.6 { return "Good sleep quality with room for improvement." }
        else if score >= 0.4 { return "Fair sleep quality. Consider our optimization tips." }
        else { return "Poor sleep quality. Focus on improving your sleep habits." }
    }
    
    private var currentSleepStage: String {
        guard let session = sleepEngine.currentSleepSession,
              let lastStage = session.sleepStages.last else {
            return "Unknown"
        }
        
        switch lastStage.type {
        case .awake: return "Awake"
        case .light: return "Light Sleep"
        case .deep: return "Deep Sleep"
        case .rem: return "REM Sleep"
        }
    }
    
    private func generateDurationData() -> [ChartDataPoint] {
        // Generate sample duration data
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
    
    private func generateEfficiencyData() -> [ChartDataPoint] {
        // Generate sample efficiency data
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

struct QuickStatCard: View {
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
                .font(.subheadline)
                .fontWeight(.semibold)
            
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
                .frame(height: 150)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct SleepDurationChart: View {
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

struct SleepEfficiencyChart: View {
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

struct SleepStageChart: View {
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

struct SleepOptimizationCard: View {
    let optimization: SleepOptimization
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: optimizationIcon)
                        .font(.title2)
                        .foregroundColor(priorityColor)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(optimization.title)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Text(optimization.description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.leading)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        PriorityBadge(priority: optimization.priority)
                        
                        Text("\(Int(optimization.estimatedImpact * 100))%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var optimizationIcon: String {
        switch optimization.type {
        case .duration: return "clock"
        case .efficiency: return "chart.line.uptrend.xyaxis"
        case .deepSleep: return "brain.head.profile"
        case .environment: return "house.fill"
        case .schedule: return "calendar"
        case .lifestyle: return "leaf.fill"
        }
    }
    
    private var priorityColor: Color {
        switch optimization.priority {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        }
    }
}

struct TrendCard: View {
    let title: String
    let trend: TrendDirection
    let value: String
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(value)
                    .font(.headline)
                    .fontWeight(.bold)
            }
            
            Spacer()
            
            Image(systemName: trendIcon)
                .font(.title2)
                .foregroundColor(trendColor)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
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

struct EnvironmentMetricCard: View {
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
                .font(.subheadline)
                .fontWeight(.semibold)
            
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

// MARK: - Preview
#Preview {
    AdvancedSleepDashboardView(
        healthDataManager: HealthDataManager(),
        predictionEngine: AdvancedHealthPredictionEngine(),
        analyticsEngine: AnalyticsEngine()
    )
} 
import SwiftUI
import Charts
import os.log

/// SleepCoachingView - Comprehensive sleep coaching interface with real-time insights
struct SleepCoachingView: View {
    @StateObject private var sleepManager = SleepManager.shared
    @StateObject private var healthKitManager = HealthKitManager.shared
    @StateObject private var aiEngine = AISleepAnalysisEngine.shared
    @StateObject private var analytics = SleepAnalyticsEngine.shared
    @StateObject private var feedbackEngine = SleepFeedbackEngine.shared
    
    @State private var selectedTab = 0
    @State private var showingInsights = false
    @State private var showingDetailedAnalysis = false
    @State private var currentCoachingTip: CoachingTip?
    @State private var morningReportReady = false
    @State private var showingMorningReport = false
    
    private let tabTitles = ["Today", "Insights", "Coaching", "Trends"]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Custom Tab Bar
                HStack {
                    ForEach(0..<tabTitles.count, id: \.self) { index in
                        TabButton(
                            title: tabTitles[index],
                            isSelected: selectedTab == index,
                            action: { selectedTab = index }
                        )
                    }
                }
                .padding(.horizontal)
                .background(Color(.systemGray6))
                
                // Tab Content
                TabView(selection: $selectedTab) {
                    // Today Tab
                    TodayView()
                        .tag(0)
                    
                    // Insights Tab
                    InsightsView()
                        .tag(1)
                    
                    // Coaching Tab
                    CoachingView()
                        .tag(2)
                    
                    // Trends Tab
                    TrendsView()
                        .tag(3)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .navigationTitle("Sleep Coach")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingMorningReport = true }) {
                        Image(systemName: "sun.max.fill")
                            .foregroundColor(morningReportReady ? .orange : .gray)
                    }
                }
            }
            .sheet(isPresented: $showingMorningReport) {
                MorningReportView()
            }
            .onAppear {
                setupCoachingView()
            }
        }
    }
    
    private func setupCoachingView() {
        Task {
            await loadTodaysData()
            checkMorningReportAvailability()
        }
    }
    
    private func loadTodaysData() async {
        // Load today's sleep and health data
        await analytics.performSleepAnalysis()
        await healthKitManager.performComprehensiveHealthAnalysis()
    }
    
    private func checkMorningReportAvailability() {
        let calendar = Calendar.current
        let now = Date()
        let hour = calendar.component(.hour, from: now)
        
        // Morning report available between 6 AM and 12 PM
        morningReportReady = hour >= 6 && hour <= 12
    }
}

// MARK: - Today View

struct TodayView: View {
    @StateObject private var sleepManager = SleepManager.shared
    @StateObject private var healthKitManager = HealthKitManager.shared
    @StateObject private var feedbackEngine = SleepFeedbackEngine.shared
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Sleep Score Card
                SleepScoreCard()
                
                // Current Status
                CurrentStatusCard()
                
                // Real-time Feedback
                RealTimeFeedbackCard()
                
                // Quick Actions
                QuickActionsCard()
                
                // Today's Timeline
                SleepTimelineCard()
                
                // Environment Status
                EnvironmentStatusCard()
            }
            .padding()
        }
    }
}

// MARK: - Sleep Score Card

struct SleepScoreCard: View {
    @StateObject private var sleepManager = SleepManager.shared
    @StateObject private var analytics = SleepAnalyticsEngine.shared
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Sleep Score")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text(getCurrentTimeString())
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Circular Progress
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 12)
                    .frame(width: 120, height: 120)
                
                Circle()
                    .trim(from: 0, to: analytics.sleepScore)
                    .stroke(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 1.0), value: analytics.sleepScore)
                
                VStack {
                    Text("\(Int(analytics.sleepScore * 100))")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("Score")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Score Breakdown
            HStack(spacing: 20) {
                ScoreComponent(
                    title: "Deep",
                    value: sleepManager.deepSleepPercentage,
                    color: .blue
                )
                
                ScoreComponent(
                    title: "REM",
                    value: sleepManager.remSleepPercentage,
                    color: .purple
                )
                
                ScoreComponent(
                    title: "Efficiency",
                    value: sleepManager.sleepEfficiency,
                    color: .green
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
    
    private func getCurrentTimeString() -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: Date())
    }
}

struct ScoreComponent: View {
    let title: String
    let value: Double
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(Int(value))%")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Current Status Card

struct CurrentStatusCard: View {
    @StateObject private var sleepManager = SleepManager.shared
    @StateObject private var healthKitManager = HealthKitManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Current Status")
                .font(.headline)
                .foregroundColor(.primary)
            
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Circle()
                            .fill(stageColor(sleepManager.currentSleepStage))
                            .frame(width: 12, height: 12)
                        
                        Text(sleepManager.currentSleepStage.displayName)
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    
                    Text("Heart Rate: \(Int(healthKitManager.currentHeartRate)) BPM")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("HRV: \(Int(healthKitManager.currentHRV)) ms")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 8) {
                    if sleepManager.isMonitoring {
                        Text("Monitoring")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.green.opacity(0.2))
                            .foregroundColor(.green)
                            .cornerRadius(8)
                    }
                    
                    Text("Quality: \(Int(healthKitManager.sleepQualityScore))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
    
    private func stageColor(_ stage: SleepStage) -> Color {
        switch stage {
        case .awake: return .red
        case .light: return .yellow
        case .deep: return .blue
        case .rem: return .purple
        }
    }
}

// MARK: - Real-time Feedback Card

struct RealTimeFeedbackCard: View {
    @StateObject private var feedbackEngine = SleepFeedbackEngine.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Real-time Feedback")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                if feedbackEngine.isActive {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 8, height: 8)
                            .scaleEffect(feedbackEngine.isActive ? 1.2 : 1.0)
                            .animation(.easeInOut(duration: 1.0).repeatForever(), value: feedbackEngine.isActive)
                        
                        Text("Active")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
            }
            
            if feedbackEngine.currentInterventions.isEmpty {
                Text("No active interventions")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 20)
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(feedbackEngine.currentInterventions, id: \.id) { intervention in
                        InterventionRow(intervention: intervention)
                    }
                }
            }
            
            // Adaptation Level
            HStack {
                Text("Adaptation Level")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                ProgressView(value: feedbackEngine.adaptationLevel)
                    .frame(width: 100)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
}

struct InterventionRow: View {
    let intervention: SleepIntervention
    
    var body: some View {
        HStack {
            Circle()
                .fill(priorityColor(intervention.priority))
                .frame(width: 8, height: 8)
            
            Text(intervention.type.rawValue.capitalized)
                .font(.subheadline)
                .foregroundColor(.primary)
            
            Spacer()
            
            Text(intervention.priority.description)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
    
    private func priorityColor(_ priority: InterventionPriority) -> Color {
        switch priority {
        case .low: return .green
        case .medium: return .yellow
        case .high: return .orange
        case .critical: return .red
        }
    }
}

// MARK: - Quick Actions Card

struct QuickActionsCard: View {
    @StateObject private var feedbackEngine = SleepFeedbackEngine.shared
    @StateObject private var sleepManager = SleepManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.headline)
                .foregroundColor(.primary)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                ActionButton(
                    title: "Start Breathing",
                    icon: "wind",
                    color: .blue,
                    action: { 
                        Task {
                            await feedbackEngine.forceIntervention(.breathingExercise)
                        }
                    }
                )
                
                ActionButton(
                    title: "Audio Therapy",
                    icon: "speaker.wave.2",
                    color: .purple,
                    action: {
                        Task {
                            await feedbackEngine.forceIntervention(.audioTherapy)
                        }
                    }
                )
                
                ActionButton(
                    title: "Environment",
                    icon: "house",
                    color: .green,
                    action: {
                        Task {
                            await feedbackEngine.forceIntervention(.environmentAdjustment)
                        }
                    }
                )
                
                ActionButton(
                    title: sleepManager.isMonitoring ? "Stop Sleep" : "Start Sleep",
                    icon: sleepManager.isMonitoring ? "stop.circle" : "play.circle",
                    color: sleepManager.isMonitoring ? .red : .green,
                    action: {
                        Task {
                            if sleepManager.isMonitoring {
                                await sleepManager.endSleepSession()
                            } else {
                                await sleepManager.startSleepSession()
                            }
                        }
                    }
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
}

struct ActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, minHeight: 60)
            .background(Color(.systemBackground))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Sleep Timeline Card

struct SleepTimelineCard: View {
    @StateObject private var sleepManager = SleepManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Sleep Timeline")
                .font(.headline)
                .foregroundColor(.primary)
            
            if sleepManager.sleepStageHistory.isEmpty {
                Text("No sleep data available")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 20)
            } else {
                Chart {
                    ForEach(Array(sleepManager.sleepStageHistory.enumerated()), id: \.offset) { index, change in
                        LineMark(
                            x: .value("Time", change.timestamp),
                            y: .value("Stage", change.to.rawValue)
                        )
                        .foregroundStyle(stageColor(change.to))
                        .interpolationMethod(.stepAfter)
                    }
                }
                .frame(height: 100)
                .chartYAxis {
                    AxisMarks(values: [0, 1, 2, 3]) { value in
                        AxisValueLabel {
                            if let intValue = value.as(Int.self) {
                                Text(SleepStage(rawValue: intValue)?.displayName ?? "")
                                    .font(.caption2)
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
    
    private func stageColor(_ stage: SleepStage) -> Color {
        switch stage {
        case .awake: return .red
        case .light: return .yellow
        case .deep: return .blue
        case .rem: return .purple
        }
    }
}

// MARK: - Environment Status Card

struct EnvironmentStatusCard: View {
    @State private var environmentData = EnvironmentData(
        temperature: 70.0,
        humidity: 45.0,
        lightLevel: 0.1,
        noiseLevel: 25.0,
        airQuality: 95.0
    )
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Environment")
                .font(.headline)
                .foregroundColor(.primary)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                EnvironmentMetric(
                    title: "Temperature",
                    value: "\(Int(environmentData.temperature))°F",
                    icon: "thermometer",
                    color: temperatureColor(environmentData.temperature)
                )
                
                EnvironmentMetric(
                    title: "Humidity",
                    value: "\(Int(environmentData.humidity))%",
                    icon: "humidity",
                    color: humidityColor(environmentData.humidity)
                )
                
                EnvironmentMetric(
                    title: "Light Level",
                    value: "\(Int(environmentData.lightLevel * 100))%",
                    icon: "sun.max",
                    color: lightColor(environmentData.lightLevel)
                )
                
                EnvironmentMetric(
                    title: "Noise Level",
                    value: "\(Int(environmentData.noiseLevel)) dB",
                    icon: "waveform",
                    color: noiseColor(environmentData.noiseLevel)
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
    
    private func temperatureColor(_ temp: Double) -> Color {
        if temp < 65 || temp > 75 { return .orange }
        return .green
    }
    
    private func humidityColor(_ humidity: Double) -> Color {
        if humidity < 30 || humidity > 60 { return .orange }
        return .green
    }
    
    private func lightColor(_ light: Double) -> Color {
        if light > 0.2 { return .orange }
        return .green
    }
    
    private func noiseColor(_ noise: Double) -> Color {
        if noise > 40 { return .orange }
        return .green
    }
}

struct EnvironmentMetric: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                
                Spacer()
                
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
            
            HStack {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
}

// MARK: - Insights View

struct InsightsView: View {
    @StateObject private var analytics = SleepAnalyticsEngine.shared
    @StateObject private var healthKitManager = HealthKitManager.shared
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // AI-Generated Insights
                AIInsightsCard()
                
                // Health Correlations
                HealthCorrelationsCard()
                
                // Sleep Patterns
                SleepPatternsCard()
                
                // Recommendations
                RecommendationsCard()
            }
            .padding()
        }
    }
}

struct AIInsightsCard: View {
    @StateObject private var analytics = SleepAnalyticsEngine.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("AI Insights")
                .font(.headline)
                .foregroundColor(.primary)
            
            if analytics.currentInsights.isEmpty {
                Text("Generating personalized insights...")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 20)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(analytics.currentInsights, id: \.title) { insight in
                        InsightRow(insight: insight)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
        .onAppear {
            Task {
                await analytics.getSleepInsights()
            }
        }
    }
}

struct InsightRow: View {
    let insight: SleepInsight
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(impactColor(insight.impact))
                .frame(width: 8, height: 8)
                .offset(y: 6)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(insight.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(insight.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                
                HStack {
                    Text("Confidence: \(Int(insight.confidence * 100))%")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(insight.type.rawValue)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.2))
                        .foregroundColor(.blue)
                        .cornerRadius(4)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
    
    private func impactColor(_ impact: InsightImpact) -> Color {
        switch impact {
        case .positive: return .green
        case .negative: return .red
        case .neutral: return .gray
        }
    }
}

// MARK: - Supporting Views and Extensions

struct TabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .blue : .secondary)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// Placeholder views for other tabs
struct CoachingView: View {
    var body: some View {
        ScrollView {
            Text("Coaching content coming soon...")
                .padding()
        }
    }
}

struct TrendsView: View {
    var body: some View {
        ScrollView {
            Text("Trends content coming soon...")
                .padding()
        }
    }
}

struct HealthCorrelationsCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Health Correlations")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text("Analyzing correlations...")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.vertical, 20)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
}

struct SleepPatternsCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Sleep Patterns")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text("Identifying patterns...")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.vertical, 20)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
}

struct RecommendationsCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recommendations")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text("Generating recommendations...")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.vertical, 20)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
}

// MARK: - Morning Report View

struct MorningReportView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var sleepManager = SleepManager.shared
    @StateObject private var healthKitManager = HealthKitManager.shared
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 8) {
                        Text("Good Morning!")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("Here's how you slept last night")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top)
                    
                    // Sleep Summary
                    SleepSummaryCard()
                    
                    // Key Insights
                    MorningInsightsCard()
                    
                    // Today's Recommendations
                    TodayRecommendationsCard()
                    
                    // Recovery Status
                    RecoveryStatusCard()
                }
                .padding()
            }
            .navigationTitle("Morning Report")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct SleepSummaryCard: View {
    @StateObject private var sleepManager = SleepManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Last Night's Sleep")
                .font(.headline)
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Duration")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("7h 23m")
                        .font(.title2)
                        .fontWeight(.semibold)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Quality")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("85%")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
}

struct MorningInsightsCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Key Insights")
                .font(.headline)
            
            VStack(spacing: 8) {
                InsightPoint(
                    icon: "checkmark.circle.fill",
                    color: .green,
                    text: "You spent 23% of your time in deep sleep - excellent!"
                )
                
                InsightPoint(
                    icon: "exclamationmark.triangle.fill",
                    color: .orange,
                    text: "You woke up 3 times during the night, slightly above average."
                )
                
                InsightPoint(
                    icon: "lightbulb.fill",
                    color: .blue,
                    text: "Your heart rate was lower than usual, indicating good recovery."
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
}

struct InsightPoint: View {
    let icon: String
    let color: Color
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 16)
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer()
        }
    }
}

struct TodayRecommendationsCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today's Recommendations")
                .font(.headline)
            
            VStack(spacing: 8) {
                RecommendationPoint(
                    text: "Try going to bed 15 minutes earlier tonight for optimal recovery."
                )
                
                RecommendationPoint(
                    text: "Consider a brief 20-minute nap between 1-3 PM if you feel tired."
                )
                
                RecommendationPoint(
                    text: "Reduce caffeine intake after 2 PM to improve tonight's sleep."
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
}

struct RecommendationPoint: View {
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "star.fill")
                .foregroundColor(.yellow)
                .frame(width: 16)
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer()
        }
    }
}

struct RecoveryStatusCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recovery Status")
                .font(.headline)
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Overall Recovery")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("Good")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Ready for")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("Moderate Exercise")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .multilineTextAlignment(.trailing)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
}

// MARK: - Extensions

extension InterventionPriority {
    var description: String {
        switch self {
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        case .critical: return "Critical"
        }
    }
}

// MARK: - Supporting Data Models

struct CoachingTip {
    let id = UUID()
    let title: String
    let content: String
    let category: String
    let priority: Int
}
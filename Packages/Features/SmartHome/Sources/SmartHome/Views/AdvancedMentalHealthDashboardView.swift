import SwiftUI
import Charts

/// Advanced Mental Health Dashboard
/// Provides comprehensive mental health monitoring, stress detection, mood analysis, and wellness recommendations
@available(iOS 18.0, macOS 15.0, *)
public struct AdvancedMentalHealthDashboardView: View {
    
    // MARK: - State
    @StateObject private var mentalHealthEngine: AdvancedMentalHealthEngine
    @State private var showingPreferences = false
    @State private var showingInsights = false
    @State private var selectedRecommendation: WellnessRecommendation?
    @State private var isVoiceEnabled = false
    @State private var selectedTimeframe: Timeframe = .week
    @State private var showingMoodAssessment = false
    @State private var showingStressEvent = false
    
    // MARK: - Environment
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Initialization
    public init(healthDataManager: HealthDataManager,
                predictionEngine: AdvancedHealthPredictionEngine,
                analyticsEngine: AnalyticsEngine) {
        self._mentalHealthEngine = StateObject(wrappedValue: AdvancedMentalHealthEngine(
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
                    
                    // Mental Health Score
                    mentalHealthScoreSection
                    
                    // Current Monitoring
                    if mentalHealthEngine.isMonitoringActive {
                        currentMonitoringSection
                    } else {
                        startMonitoringSection
                    }
                    
                    // Stress & Mood Analysis
                    stressMoodSection
                    
                    // Wellness Recommendations
                    wellnessSection
                    
                    // Mental Health Trends
                    trendsSection
                    
                    // Quick Actions
                    quickActionsSection
                }
                .padding()
            }
            .navigationTitle("Mental Health")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
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
            }
        }
        .sheet(isPresented: $showingPreferences) {
            MentalHealthPreferencesView(mentalHealthEngine: mentalHealthEngine)
        }
        .sheet(isPresented: $showingInsights) {
            MentalHealthInsightsView(mentalHealthEngine: mentalHealthEngine)
        }
        .sheet(item: $selectedRecommendation) { recommendation in
            WellnessRecommendationDetailView(recommendation: recommendation, mentalHealthEngine: mentalHealthEngine)
        }
        .sheet(isPresented: $showingMoodAssessment) {
            MoodAssessmentView(mentalHealthEngine: mentalHealthEngine)
        }
        .sheet(isPresented: $showingStressEvent) {
            StressEventView(mentalHealthEngine: mentalHealthEngine)
        }
        .onAppear {
            loadMentalHealthData()
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 50))
                    .foregroundColor(.purple)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Mental Health")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    HStack {
                        Circle()
                            .fill(mentalHealthEngine.isMonitoringActive ? .green : .gray)
                            .frame(width: 8, height: 8)
                        
                        Text(mentalHealthEngine.isMonitoringActive ? "Monitoring Active" : "Ready to Monitor")
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
                        .foregroundColor(isVoiceEnabled ? .purple : .gray)
                }
            }
            
            // Quick Stats
            HStack {
                QuickStatCard(
                    title: "Stress Level",
                    value: mentalHealthEngine.stressLevel.displayName,
                    icon: "brain.head.profile",
                    color: mentalHealthEngine.stressLevel.color
                )
                
                QuickStatCard(
                    title: "Mood Score",
                    value: "\(Int(mentalHealthEngine.moodScore * 100))%",
                    icon: "face.smiling",
                    color: .orange
                )
                
                QuickStatCard(
                    title: "Wellness",
                    value: "\(Int(mentalHealthEngine.wellnessScore * 100))%",
                    icon: "heart.fill",
                    color: .green
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Mental Health Score Section
    private var mentalHealthScoreSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Mental Health Score")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("\(Int(mentalHealthEngine.wellnessScore * 100))")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(wellnessScoreColor)
            }
            
            // Wellness Score Gauge
            ZStack {
                Circle()
                    .stroke(Color(.systemGray5), lineWidth: 12)
                    .frame(width: 120, height: 120)
                
                Circle()
                    .trim(from: 0, to: mentalHealthEngine.wellnessScore)
                    .stroke(wellnessScoreColor, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 1.0), value: mentalHealthEngine.wellnessScore)
                
                VStack {
                    Text("\(Int(mentalHealthEngine.wellnessScore * 100))")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Score")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Score Description
            Text(wellnessScoreDescription)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Current Monitoring Section
    private var currentMonitoringSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Current Monitoring")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("Stop Monitoring") {
                    stopMonitoring()
                }
                .foregroundColor(.red)
                .font(.subheadline)
            }
            
            if let currentState = mentalHealthEngine.currentMentalState {
                VStack(spacing: 12) {
                    HStack {
                        Text("Stress Level")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text(currentState.stressLevel.displayName)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(currentState.stressLevel.color)
                    }
                    
                    HStack {
                        Text("Mood Score")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("\(Int(currentState.moodScore * 100))%")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    
                    HStack {
                        Text("Energy Level")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("\(Int(currentState.energyLevel * 100))%")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    
                    HStack {
                        Text("Focus Level")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("\(Int(currentState.focusLevel * 100))%")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Start Monitoring Section
    private var startMonitoringSection: some View {
        VStack(spacing: 16) {
            Text("Ready to Monitor Your Mental Health?")
                .font(.headline)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
            
            Text("Start monitoring to get real-time insights into your stress levels, mood, and overall mental wellness.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Start Monitoring") {
                startMonitoring()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            
            Button("View Mental Health History") {
                showingInsights = true
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Stress & Mood Section
    private var stressMoodSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Stress & Mood Analysis")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 16) {
                // Stress Level Card
                StressLevelCard(stressLevel: mentalHealthEngine.stressLevel)
                
                // Mood Score Card
                MoodScoreCard(moodScore: mentalHealthEngine.moodScore)
                
                // Quick Actions
                HStack(spacing: 12) {
                    Button("Record Mood") {
                        showingMoodAssessment = true
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    
                    Button("Log Stress Event") {
                        showingStressEvent = true
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Wellness Section
    private var wellnessSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Wellness Recommendations")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("Refresh") {
                    refreshRecommendations()
                }
                .font(.subheadline)
                .foregroundColor(.purple)
            }
            
            if mentalHealthEngine.wellnessRecommendations.isEmpty {
                Text("No recommendations available. Start monitoring to get personalized wellness recommendations.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(mentalHealthEngine.wellnessRecommendations) { recommendation in
                        WellnessRecommendationCard(recommendation: recommendation) {
                            selectedRecommendation = recommendation
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
            Text("Mental Health Trends")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 20) {
                // Stress Trend Chart
                ChartCard(
                    title: "Stress Level Trend",
                    subtitle: "Last \(selectedTimeframe.rawValue)"
                ) {
                    StressTrendChart(data: generateStressTrendData())
                }
                
                // Mood Trend Chart
                ChartCard(
                    title: "Mood Score Trend",
                    subtitle: "Mood over time"
                ) {
                    MoodTrendChart(data: generateMoodTrendData())
                }
                
                // Wellness Trend Chart
                ChartCard(
                    title: "Wellness Score Trend",
                    subtitle: "Overall wellness over time"
                ) {
                    WellnessTrendChart(data: generateWellnessTrendData())
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Quick Actions Section
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Actions")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                QuickActionCard(
                    title: "Meditation",
                    icon: "brain.head.profile",
                    color: .purple
                ) {
                    startMeditation()
                }
                
                QuickActionCard(
                    title: "Breathing",
                    icon: "lungs.fill",
                    color: .blue
                ) {
                    startBreathingExercise()
                }
                
                QuickActionCard(
                    title: "Mood Check",
                    icon: "face.smiling",
                    color: .orange
                ) {
                    showingMoodAssessment = true
                }
                
                QuickActionCard(
                    title: "Stress Relief",
                    icon: "heart.fill",
                    color: .red
                ) {
                    startStressRelief()
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Helper Methods
    private func loadMentalHealthData() {
        Task {
            _ = await mentalHealthEngine.getMentalHealthInsights(timeframe: selectedTimeframe)
        }
    }
    
    private func startMonitoring() {
        Task {
            do {
                try await mentalHealthEngine.startMonitoring()
                
                if isVoiceEnabled {
                    await mentalHealthEngine.provideMentalHealthCoaching("Mental health monitoring started. I'll help you track your wellness journey.")
                }
            } catch {
                print("Failed to start monitoring: \(error)")
            }
        }
    }
    
    private func stopMonitoring() {
        Task {
            await mentalHealthEngine.stopMonitoring()
            
            if isVoiceEnabled {
                await mentalHealthEngine.provideMentalHealthCoaching("Monitoring stopped. Remember to take care of your mental health.")
            }
        }
    }
    
    private func refreshRecommendations() {
        Task {
            do {
                _ = try await mentalHealthEngine.generateWellnessRecommendations()
            } catch {
                print("Failed to refresh recommendations: \(error)")
            }
        }
    }
    
    private func startMeditation() {
        if isVoiceEnabled {
            Task {
                await mentalHealthEngine.provideMentalHealthCoaching("Let's start a guided meditation. Find a comfortable position and close your eyes.")
            }
        }
    }
    
    private func startBreathingExercise() {
        if isVoiceEnabled {
            Task {
                await mentalHealthEngine.provideMentalHealthCoaching("Let's practice deep breathing. Inhale for 4 counts, hold for 4, exhale for 4.")
            }
        }
    }
    
    private func startStressRelief() {
        if isVoiceEnabled {
            Task {
                await mentalHealthEngine.provideMentalHealthCoaching("Let's do some stress relief exercises. Start with progressive muscle relaxation.")
            }
        }
    }
    
    private var wellnessScoreColor: Color {
        let score = mentalHealthEngine.wellnessScore
        if score >= 0.8 { return .green }
        else if score >= 0.6 { return .orange }
        else { return .red }
    }
    
    private var wellnessScoreDescription: String {
        let score = mentalHealthEngine.wellnessScore
        if score >= 0.8 { return "Excellent mental wellness! Keep up the great work." }
        else if score >= 0.6 { return "Good mental wellness with room for improvement." }
        else if score >= 0.4 { return "Fair mental wellness. Consider our wellness tips." }
        else { return "Mental wellness needs attention. Focus on self-care." }
    }
    
    private func generateStressTrendData() -> [ChartDataPoint] {
        // Generate sample stress trend data
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
    
    private func generateMoodTrendData() -> [ChartDataPoint] {
        // Generate sample mood trend data
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
    
    private func generateWellnessTrendData() -> [ChartDataPoint] {
        // Generate sample wellness trend data
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

struct StressLevelCard: View {
    let stressLevel: StressLevel
    
    var body: some View {
        HStack {
            Image(systemName: "brain.head.profile")
                .font(.title2)
                .foregroundColor(stressLevel.color)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Stress Level")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(stressLevel.displayName)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(stressLevel.color)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(Int(stressLevel.rawValue * 100))%")
                    .font(.title3)
                    .fontWeight(.bold)
                
                Text("Intensity")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct MoodScoreCard: View {
    let moodScore: Double
    
    var body: some View {
        HStack {
            Image(systemName: "face.smiling")
                .font(.title2)
                .foregroundColor(moodScoreColor)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Mood Score")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(moodScoreDescription)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(moodScoreColor)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(Int(moodScore * 100))%")
                    .font(.title3)
                    .fontWeight(.bold)
                
                Text("Current")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var moodScoreColor: Color {
        if moodScore >= 0.8 { return .green }
        else if moodScore >= 0.6 { return .orange }
        else { return .red }
    }
    
    private var moodScoreDescription: String {
        if moodScore >= 0.8 { return "Excellent" }
        else if moodScore >= 0.6 { return "Good" }
        else if moodScore >= 0.4 { return "Fair" }
        else { return "Poor" }
    }
}

struct WellnessRecommendationCard: View {
    let recommendation: WellnessRecommendation
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: recommendationIcon)
                        .font(.title2)
                        .foregroundColor(priorityColor)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(recommendation.title)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Text(recommendation.description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.leading)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        PriorityBadge(priority: recommendation.priority)
                        
                        Text("\(Int(recommendation.estimatedImpact * 100))%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                HStack {
                    Label(recommendation.category.rawValue.capitalized, systemImage: categoryIcon)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    if recommendation.duration > 0 {
                        Label(formatDuration(recommendation.duration), systemImage: "clock")
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
    
    private var recommendationIcon: String {
        switch recommendation.type {
        case .stressManagement: return "brain.head.profile"
        case .moodImprovement: return "face.smiling"
        case .energyBoost: return "bolt.fill"
        case .focusImprovement: return "target"
        case .socialConnection: return "person.2.fill"
        case .sleepImprovement: return "bed.double.fill"
        }
    }
    
    private var priorityColor: Color {
        switch recommendation.priority {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        }
    }
    
    private var categoryIcon: String {
        switch recommendation.category {
        case .stress: return "brain.head.profile"
        case .mood: return "face.smiling"
        case .energy: return "bolt.fill"
        case .focus: return "target"
        case .social: return "person.2.fill"
        case .sleep: return "bed.double.fill"
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration / 60)
        if minutes < 60 {
            return "\(minutes)m"
        } else {
            let hours = minutes / 60
            return "\(hours)h"
        }
    }
}

struct QuickActionCard: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
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

struct StressTrendChart: View {
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

struct MoodTrendChart: View {
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

struct WellnessTrendChart: View {
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

struct PriorityBadge: View {
    let priority: WellnessRecommendation.Priority
    
    var body: some View {
        Text(priority.rawValue.capitalized)
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(priorityColor)
            .cornerRadius(8)
    }
    
    private var priorityColor: Color {
        switch priority {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        }
    }
}

// MARK: - Supporting Models

struct ChartDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
}

extension StressLevel {
    var displayName: String {
        switch self {
        case .low: return "Low"
        case .moderate: return "Moderate"
        case .high: return "High"
        }
    }
    
    var color: Color {
        switch self {
        case .low: return .green
        case .moderate: return .orange
        case .high: return .red
        }
    }
}

// MARK: - Preview
#Preview {
    AdvancedMentalHealthDashboardView(
        healthDataManager: HealthDataManager(),
        predictionEngine: AdvancedHealthPredictionEngine(),
        analyticsEngine: AnalyticsEngine()
    )
} 
import SwiftUI
import Charts

/// Mental Health Dashboard View for iOS 18+ mental health features
/// Displays mindfulness sessions, mental state tracking, mood analysis, and insights
@available(iOS 17.0, macOS 14.0, *)
public struct MentalHealthDashboardView: View {
    @StateObject private var mentalHealthManager: MentalHealthManager? = {
        if #available(macOS 14.0, *) {
            return MentalHealthManager.shared
        } else {
            return nil
        }
    }()
    @State private var selectedTimeRange: TimeRange = .week
    @State private var showingMindfulnessSession = false
    @State private var showingMoodEntry = false
    @State private var showingMentalStateEntry = false
    @State private var selectedInsight: MentalHealthInsight?
    
    public init() {}
    
    public enum TimeRange: String, CaseIterable {
        case day = "Day"
        case week = "Week"
        case month = "Month"
        
        var days: Int {
            switch self {
            case .day: return 1
            case .week: return 7
            case .month: return 30
            }
        }
    }
    
    public var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 20) {
                    if let manager = mentalHealthManager {
                        // Mental Health Score Card
                        MentalHealthScoreCard(mentalHealthManager: manager)
                        
                        // Mindfulness Sessions Card
                        MindfulnessSessionsCard(mentalHealthManager: manager)
                        
                        // Mental State Tracking Card
                        MentalStateTrackingCard(mentalHealthManager: manager)
                        
                        // Mood Analysis Card
                        MoodAnalysisCard(mentalHealthManager: manager)
                        
                        // Stress & Anxiety Card
                        StressAnxietyCard(mentalHealthManager: manager)
                        
                        // Insights & Recommendations Card
                        InsightsRecommendationsCard(mentalHealthManager: manager)
                    } else {
                        Text("Mental Health features require macOS 14+")
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
            }
            .navigationTitle("Mental Health")
            // Remove .navigationBarTitleDisplayMode and .toolbar for macOS
            #if !os(macOS)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Start Mindfulness") {
                            showingMindfulnessSession = true
                        }
                        Button("Record Mood") {
                            showingMoodEntry = true
                        }
                        Button("Record Mental State") {
                            showingMentalStateEntry = true
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.blue)
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Picker("Time Range", selection: $selectedTimeRange) {
                        ForEach(TimeRange.allCases, id: \.self) { range in
                            Text(range.rawValue).tag(range)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .frame(width: 200)
                }
            }
            #endif
        }
        .sheet(isPresented: $showingMindfulnessSession) {
            MindfulnessSessionView()
        }
        .sheet(isPresented: $showingMoodEntry) {
            MoodEntryView()
        }
        .sheet(isPresented: $showingMentalStateEntry) {
            MentalStateEntryView()
        }
        .sheet(item: $selectedInsight) { insight in
            InsightDetailView(insight: insight)
        }
    }
}

// MARK: - Mental Health Score Card

struct MentalHealthScoreCard: View {
    @StateObject private var mentalHealthManager: MentalHealthManager
    
    init(mentalHealthManager: MentalHealthManager) {
        _mentalHealthManager = StateObject(wrappedValue: mentalHealthManager)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .foregroundColor(.purple)
                Text("Mental Health Score")
                    .font(.headline)
                Spacer()
                Text("\(Int(mentalHealthManager.mentalHealthScore * 100))")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.purple)
            }
            
            // Circular Progress
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                    .frame(width: 80, height: 80)
                
                Circle()
                    .trim(from: 0, to: mentalHealthManager.mentalHealthScore)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [.purple, .blue]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 1.0), value: mentalHealthManager.mentalHealthScore)
                
                VStack {
                    Text("\(Int(mentalHealthManager.mentalHealthScore * 100))")
                        .font(.title3)
                        .fontWeight(.bold)
                    Text("Score")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)
            
            // Quick Stats
            HStack(spacing: 20) {
                StatItem(
                    title: "Stress",
                    value: mentalHealthManager.stressLevel.displayName,
                    color: stressColor
                )
                
                StatItem(
                    title: "Anxiety",
                    value: mentalHealthManager.anxietyLevel.displayName,
                    color: anxietyColor
                )
                
                StatItem(
                    title: "Depression Risk",
                    value: mentalHealthManager.depressionRisk.displayName,
                    color: depressionColor
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 2)
    }
    
    private var stressColor: Color {
        switch mentalHealthManager.stressLevel {
        case .low: return .green
        case .moderate: return .yellow
        case .high: return .orange
        case .severe: return .red
        }
    }
    
    private var anxietyColor: Color {
        switch mentalHealthManager.anxietyLevel {
        case .low: return .green
        case .moderate: return .yellow
        case .high: return .orange
        case .severe: return .red
        }
    }
    
    private var depressionColor: Color {
        switch mentalHealthManager.depressionRisk {
        case .low: return .green
        case .moderate: return .yellow
        case .high: return .orange
        case .severe: return .red
        }
    }
}

// MARK: - Mindfulness Sessions Card

struct MindfulnessSessionsCard: View {
    @StateObject private var mentalHealthManager: MentalHealthManager
    
    init(mentalHealthManager: MentalHealthManager) {
        _mentalHealthManager = StateObject(wrappedValue: mentalHealthManager)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "leaf.fill")
                    .foregroundColor(.green)
                Text("Mindfulness Sessions")
                    .font(.headline)
                Spacer()
                Button("Start Session") {
                    // Trigger mindfulness session
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
            
            if mentalHealthManager.mindfulnessSessions.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "leaf")
                        .font(.system(size: 40))
                        .foregroundColor(.green.opacity(0.6))
                    Text("No mindfulness sessions yet")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("Start your mindfulness journey today")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                // Recent Sessions
                VStack(spacing: 12) {
                    ForEach(mentalHealthManager.mindfulnessSessions.prefix(3), id: \.startDate) { session in
                        MindfulnessSessionRow(session: session)
                    }
                }
                
                // Session Statistics
                HStack(spacing: 20) {
                    StatItem(
                        title: "Total Sessions",
                        value: "\(mentalHealthManager.mindfulnessSessions.count)",
                        color: .green
                    )
                    
                    StatItem(
                        title: "Total Time",
                        value: formatTotalTime(),
                        color: .green
                    )
                    
                    StatItem(
                        title: "Daily Goal",
                        value: "\(Int(mentalHealthManager.mindfulnessGoal / 60)) min",
                        color: .green
                    )
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 2)
    }
    
    private func formatTotalTime() -> String {
        let totalSeconds = mentalHealthManager.mindfulnessSessions.reduce(0) { $0 + $1.duration }
        let hours = Int(totalSeconds) / 3600
        let minutes = Int(totalSeconds) % 3600 / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

struct MindfulnessSessionRow: View {
    let session: MindfulSession
    
    var body: some View {
        HStack {
            Image(systemName: sessionTypeIcon)
                .foregroundColor(.green)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(session.type.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(session.startDate, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(formatDuration(session.duration))
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(session.isActive ? "Active" : "Completed")
                    .font(.caption)
                    .foregroundColor(session.isActive ? .green : .secondary)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
    
    private var sessionTypeIcon: String {
        switch session.type {
        case .meditation: return "brain.head.profile"
        case .breathing: return "lungs.fill"
        case .bodyScan: return "figure.walk"
        case .lovingKindness: return "heart.fill"
        case .walking: return "figure.walk"
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Mental State Tracking Card

struct MentalStateTrackingCard: View {
    @StateObject private var mentalHealthManager: MentalHealthManager
    
    init(mentalHealthManager: MentalHealthManager) {
        _mentalHealthManager = StateObject(wrappedValue: mentalHealthManager)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "brain")
                    .foregroundColor(.blue)
                Text("Mental State Tracking")
                    .font(.headline)
                Spacer()
                Text(mentalHealthManager.currentMentalState.displayName)
                    .font(.subheadline)
                    .foregroundColor(mentalStateColor)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(mentalStateColor.opacity(0.2))
                    .cornerRadius(8)
            }
            
            if mentalHealthManager.mentalStateRecords.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "brain")
                        .font(.system(size: 40))
                        .foregroundColor(.blue.opacity(0.6))
                    Text("No mental state records yet")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("Track your mental state throughout the day")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                // Mental State Chart
                Chart {
                    ForEach(mentalHealthManager.mentalStateRecords.prefix(20), id: \.timestamp) { record in
                        LineMark(
                            x: .value("Time", record.timestamp),
                            y: .value("State", record.state.positiveValue)
                        )
                        .foregroundStyle(.blue)
                        .interpolationMethod(.catmullRom)
                        
                        PointMark(
                            x: .value("Time", record.timestamp),
                            y: .value("State", record.state.positiveValue)
                        )
                        .foregroundStyle(.blue)
                    }
                }
                .frame(height: 120)
                .chartYScale(domain: 0...1)
                .chartYAxis {
                    AxisMarks(values: [0, 0.25, 0.5, 0.75, 1.0]) { value in
                        AxisValueLabel {
                            if let doubleValue = value.as(Double.self) {
                                Text(mentalStateLabel(doubleValue))
                                    .font(.caption)
                            }
                        }
                    }
                }
                
                // Mental State Distribution
                HStack(spacing: 16) {
                    ForEach(MentalState.allCases, id: \.self) { state in
                        VStack(spacing: 4) {
                            Text("\(stateCount(state))")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(mentalStateColor(for: state))
                            Text(state.displayName)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 2)
    }
    
    private var mentalStateColor: Color {
        mentalStateColor(for: mentalHealthManager.currentMentalState)
    }
    
    private func mentalStateColor(for state: MentalState) -> Color {
        switch state {
        case .veryNegative: return .red
        case .negative: return .orange
        case .neutral: return .yellow
        case .positive: return .green
        case .veryPositive: return .blue
        }
    }
    
    private func mentalStateLabel(_ value: Double) -> String {
        switch value {
        case 0: return "Very Neg"
        case 0.25: return "Negative"
        case 0.5: return "Neutral"
        case 0.75: return "Positive"
        case 1.0: return "Very Pos"
        default: return ""
        }
    }
    
    private func stateCount(_ state: MentalState) -> Int {
        mentalHealthManager.mentalStateRecords.filter { $0.state == state }.count
    }
}

// MARK: - Mood Analysis Card

struct MoodAnalysisCard: View {
    @StateObject private var mentalHealthManager: MentalHealthManager
    
    init(mentalHealthManager: MentalHealthManager) {
        _mentalHealthManager = StateObject(wrappedValue: mentalHealthManager)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "face.smiling")
                    .foregroundColor(.orange)
                Text("Mood Analysis")
                    .font(.headline)
                Spacer()
            }
            
            if mentalHealthManager.moodChanges.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "face.smiling")
                        .font(.system(size: 40))
                        .foregroundColor(.orange.opacity(0.6))
                    Text("No mood records yet")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("Track your mood throughout the day")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                // Mood Chart
                Chart {
                    ForEach(mentalHealthManager.moodChanges.prefix(30), id: \.timestamp) { mood in
                        LineMark(
                            x: .value("Time", mood.timestamp),
                            y: .value("Mood", mood.mood.positiveValue)
                        )
                        .foregroundStyle(.orange)
                        .interpolationMethod(.catmullRom)
                        
                        PointMark(
                            x: .value("Time", mood.timestamp),
                            y: .value("Mood", mood.mood.positiveValue)
                        )
                        .foregroundStyle(.orange)
                    }
                }
                .frame(height: 120)
                .chartYScale(domain: 0...1)
                .chartYAxis {
                    AxisMarks(values: [0, 0.25, 0.5, 0.75, 1.0]) { value in
                        AxisValueLabel {
                            if let doubleValue = value.as(Double.self) {
                                Text(moodLabel(doubleValue))
                                    .font(.caption)
                            }
                        }
                    }
                }
                
                // Mood Distribution
                HStack(spacing: 16) {
                    ForEach(Mood.allCases, id: \.self) { mood in
                        VStack(spacing: 4) {
                            Text("\(moodCount(mood))")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(moodColor(for: mood))
                            Text(mood.displayName)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 2)
    }
    
    private func moodColor(for mood: Mood) -> Color {
        switch mood {
        case .verySad: return .red
        case .sad: return .orange
        case .neutral: return .yellow
        case .happy: return .green
        case .veryHappy: return .blue
        }
    }
    
    private func moodLabel(_ value: Double) -> String {
        switch value {
        case 0: return "Very Sad"
        case 0.25: return "Sad"
        case 0.5: return "Neutral"
        case 0.75: return "Happy"
        case 1.0: return "Very Happy"
        default: return ""
        }
    }
    
    private func moodCount(_ mood: Mood) -> Int {
        mentalHealthManager.moodChanges.filter { $0.mood == mood }.count
    }
}

// MARK: - Stress & Anxiety Card

struct StressAnxietyCard: View {
    @StateObject private var mentalHealthManager: MentalHealthManager
    
    init(mentalHealthManager: MentalHealthManager) {
        _mentalHealthManager = StateObject(wrappedValue: mentalHealthManager)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "exclamationmark.triangle")
                    .foregroundColor(.red)
                Text("Stress & Anxiety")
                    .font(.headline)
                Spacer()
            }
            
            HStack(spacing: 20) {
                // Stress Level
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                            .frame(width: 60, height: 60)
                        
                        Circle()
                            .trim(from: 0, to: stressProgress)
                            .stroke(stressColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                            .frame(width: 60, height: 60)
                            .rotationEffect(.degrees(-90))
                        
                        VStack {
                            Text("\(stressLevel)")
                                .font(.caption)
                                .fontWeight(.bold)
                            Text("Level")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Text("Stress")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text(mentalHealthManager.stressLevel.displayName)
                        .font(.caption)
                        .foregroundColor(stressColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(stressColor.opacity(0.2))
                        .cornerRadius(4)
                }
                .frame(maxWidth: .infinity)
                
                // Anxiety Level
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                            .frame(width: 60, height: 60)
                        
                        Circle()
                            .trim(from: 0, to: anxietyProgress)
                            .stroke(anxietyColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                            .frame(width: 60, height: 60)
                            .rotationEffect(.degrees(-90))
                        
                        VStack {
                            Text("\(anxietyLevel)")
                                .font(.caption)
                                .fontWeight(.bold)
                            Text("Level")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Text("Anxiety")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text(mentalHealthManager.anxietyLevel.displayName)
                        .font(.caption)
                        .foregroundColor(anxietyColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(anxietyColor.opacity(0.2))
                        .cornerRadius(4)
                }
                .frame(maxWidth: .infinity)
                
                // Depression Risk
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                            .frame(width: 60, height: 60)
                        
                        Circle()
                            .trim(from: 0, to: depressionProgress)
                            .stroke(depressionColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                            .frame(width: 60, height: 60)
                            .rotationEffect(.degrees(-90))
                        
                        VStack {
                            Text("\(depressionLevel)")
                                .font(.caption)
                                .fontWeight(.bold)
                            Text("Risk")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Text("Depression")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text(mentalHealthManager.depressionRisk.displayName)
                        .font(.caption)
                        .foregroundColor(depressionColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(depressionColor.opacity(0.2))
                        .cornerRadius(4)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 2)
    }
    
    private var stressProgress: Double {
        switch mentalHealthManager.stressLevel {
        case .low: return 0.25
        case .moderate: return 0.5
        case .high: return 0.75
        case .severe: return 1.0
        }
    }
    
    private var anxietyProgress: Double {
        switch mentalHealthManager.anxietyLevel {
        case .low: return 0.25
        case .moderate: return 0.5
        case .high: return 0.75
        case .severe: return 1.0
        }
    }
    
    private var depressionProgress: Double {
        switch mentalHealthManager.depressionRisk {
        case .low: return 0.25
        case .moderate: return 0.5
        case .high: return 0.75
        case .severe: return 1.0
        }
    }
    
    private var stressLevel: Int {
        switch mentalHealthManager.stressLevel {
        case .low: return 1
        case .moderate: return 2
        case .high: return 3
        case .severe: return 4
        }
    }
    
    private var anxietyLevel: Int {
        switch mentalHealthManager.anxietyLevel {
        case .low: return 1
        case .moderate: return 2
        case .high: return 3
        case .severe: return 4
        }
    }
    
    private var depressionLevel: Int {
        switch mentalHealthManager.depressionRisk {
        case .low: return 1
        case .moderate: return 2
        case .high: return 3
        case .severe: return 4
        }
    }
    
    private var stressColor: Color {
        switch mentalHealthManager.stressLevel {
        case .low: return .green
        case .moderate: return .yellow
        case .high: return .orange
        case .severe: return .red
        }
    }
    
    private var anxietyColor: Color {
        switch mentalHealthManager.anxietyLevel {
        case .low: return .green
        case .moderate: return .yellow
        case .high: return .orange
        case .severe: return .red
        }
    }
    
    private var depressionColor: Color {
        switch mentalHealthManager.depressionRisk {
        case .low: return .green
        case .moderate: return .yellow
        case .high: return .orange
        case .severe: return .red
        }
    }
}

// MARK: - Insights & Recommendations Card

struct InsightsRecommendationsCard: View {
    @StateObject private var mentalHealthManager: MentalHealthManager
    @State private var selectedInsight: MentalHealthInsight?
    
    init(mentalHealthManager: MentalHealthManager) {
        _mentalHealthManager = StateObject(wrappedValue: mentalHealthManager)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
                Text("Insights & Recommendations")
                    .font(.headline)
                Spacer()
            }
            
            if mentalHealthManager.mentalHealthInsights.isEmpty && mentalHealthManager.mindfulnessRecommendations.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "lightbulb")
                        .font(.system(size: 40))
                        .foregroundColor(.yellow.opacity(0.6))
                    Text("No insights yet")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("Continue tracking to receive personalized insights")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                // Mental Health Insights
                if !mentalHealthManager.mentalHealthInsights.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Recent Insights")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        ForEach(mentalHealthManager.mentalHealthInsights.prefix(3), id: \.timestamp) { insight in
                            InsightRow(insight: insight)
                                .onTapGesture {
                                    selectedInsight = insight
                                }
                        }
                    }
                }
                
                // Mindfulness Recommendations
                if !mentalHealthManager.mindfulnessRecommendations.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Mindfulness Recommendations")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        ForEach(mentalHealthManager.mindfulnessRecommendations.prefix(3), id: \.title) { recommendation in
                            RecommendationRow(recommendation: recommendation)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 2)
        .sheet(item: $selectedInsight) { insight in
            InsightDetailView(insight: insight)
        }
    }
}

struct InsightRow: View {
    let insight: MentalHealthInsight
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: insightIcon)
                .foregroundColor(insightColor)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(insight.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(insight.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
                .font(.caption)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
    
    private var insightIcon: String {
        switch insight.type {
        case .mindfulness: return "leaf.fill"
        case .mentalState: return "brain"
        case .mood: return "face.smiling"
        case .stress: return "exclamationmark.triangle"
        case .anxiety: return "heart"
        case .depression: return "cloud.rain"
        }
    }
    
    private var insightColor: Color {
        switch insight.severity {
        case .positive: return .green
        case .info: return .blue
        case .warning: return .orange
        case .critical: return .red
        }
    }
}

struct RecommendationRow: View {
    let recommendation: MindfulnessRecommendation
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: recommendationIcon)
                .foregroundColor(.green)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(recommendation.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(recommendation.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(formatDuration(recommendation.duration))
                    .font(.caption)
                    .fontWeight(.medium)
                Text(recommendation.priority.displayName)
                    .font(.caption2)
                    .foregroundColor(priorityColor)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(priorityColor.opacity(0.2))
                    .cornerRadius(4)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
    
    private var recommendationIcon: String {
        switch recommendation.type {
        case .meditation: return "brain.head.profile"
        case .breathing: return "lungs.fill"
        case .bodyScan: return "figure.walk"
        case .lovingKindness: return "heart.fill"
        case .walking: return "figure.walk"
        }
    }
    
    private var priorityColor: Color {
        switch recommendation.priority {
        case .low: return .green
        case .medium: return .yellow
        case .high: return .red
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        return "\(minutes)m"
    }
}

// MARK: - Supporting Views

struct StatItem: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(color)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct InsightDetailView: View {
    let insight: MentalHealthInsight
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Insight Header
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: insightIcon)
                                .foregroundColor(insightColor)
                                .font(.title2)
                            Text(insight.title)
                                .font(.title2)
                                .fontWeight(.bold)
                        }
                        
                        Text(insight.description)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // Insight Details
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Details")
                            .font(.headline)
                        
                        DetailRow(title: "Type", value: insight.type.displayName)
                        DetailRow(title: "Severity", value: insight.severity.displayName)
                        DetailRow(title: "Time", value: insight.timestamp, style: .date)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(radius: 1)
                }
                .padding()
            }
            .navigationTitle("Insight Details")
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
    
    private var insightIcon: String {
        switch insight.type {
        case .mindfulness: return "leaf.fill"
        case .mentalState: return "brain"
        case .mood: return "face.smiling"
        case .stress: return "exclamationmark.triangle"
        case .anxiety: return "heart"
        case .depression: return "cloud.rain"
        }
    }
    
    private var insightColor: Color {
        switch insight.severity {
        case .positive: return .green
        case .info: return .blue
        case .warning: return .orange
        case .critical: return .red
        }
    }
}

struct DetailRow: View {
    let title: String
    let value: String
    let style: DateFormatter.Style?
    
    init(title: String, value: String, style: DateFormatter.Style? = nil) {
        self.title = title
        self.value = value
        self.style = style
    }
    
    init(title: String, value: Date, style: DateFormatter.Style) {
        self.title = title
        self.value = value.formatted(date: style, time: .shortened)
        self.style = style
    }
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
}

// MARK: - Placeholder Views

struct MindfulnessSessionView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Mindfulness Session")
                    .font(.title)
                Text("This view would allow users to start and manage mindfulness sessions")
                    .foregroundColor(.secondary)
            }
            .navigationTitle("Mindfulness")
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

struct MoodEntryView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Mood Entry")
                    .font(.title)
                Text("This view would allow users to record their mood")
                    .foregroundColor(.secondary)
            }
            .navigationTitle("Record Mood")
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

struct MentalStateEntryView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Mental State Entry")
                    .font(.title)
                Text("This view would allow users to record their mental state")
                    .foregroundColor(.secondary)
            }
            .navigationTitle("Record Mental State")
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

// MARK: - Extensions

extension MentalHealthInsight.InsightType {
    var displayName: String {
        switch self {
        case .mindfulness: return "Mindfulness"
        case .mentalState: return "Mental State"
        case .mood: return "Mood"
        case .stress: return "Stress"
        case .anxiety: return "Anxiety"
        case .depression: return "Depression"
        }
    }
}

extension MentalHealthInsight.InsightSeverity {
    var displayName: String {
        switch self {
        case .positive: return "Positive"
        case .info: return "Information"
        case .warning: return "Warning"
        case .critical: return "Critical"
        }
    }
}

extension MindfulnessRecommendation.Priority {
    var displayName: String {
        switch self {
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        }
    }
}

extension MentalHealthInsight: Identifiable {
    public var id: Date { timestamp }
}

#Preview {
    MentalHealthDashboardView()
}
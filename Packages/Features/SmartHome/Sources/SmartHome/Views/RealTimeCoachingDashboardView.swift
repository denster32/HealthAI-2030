import SwiftUI
import HealthKit
import Combine

/// Real-Time Health Coaching Dashboard
/// Provides an interactive interface for AI-powered health coaching
@available(iOS 18.0, macOS 15.0, *)
public struct RealTimeCoachingDashboardView: View {
    
    // MARK: - State
    @StateObject private var coachingEngine: RealTimeHealthCoachingEngine
    @State private var showingGoalSheet = false
    @State private var showingInsightsSheet = false
    @State private var selectedRecommendation: HealthRecommendation?
    @State private var userMessage = ""
    @State private var isVoiceEnabled = false
    @State private var showingVoiceSettings = false
    
    // MARK: - Environment
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Initialization
    public init(healthDataManager: HealthDataManager,
                predictionEngine: AdvancedHealthPredictionEngine,
                analyticsEngine: AnalyticsEngine) {
        self._coachingEngine = StateObject(wrappedValue: RealTimeHealthCoachingEngine(
            healthDataManager: healthDataManager,
            predictionEngine: predictionEngine,
            analyticsEngine: analyticsEngine
        ))
    }
    
    // MARK: - Body
    public var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header Section
                    headerSection
                    
                    // Current Session Section
                    if coachingEngine.isCoachingActive {
                        currentSessionSection
                    } else {
                        startSessionSection
                    }
                    
                    // Active Recommendations
                    recommendationsSection
                    
                    // Progress Metrics
                    progressSection
                    
                    // Quick Actions
                    quickActionsSection
                    
                    // Coaching History
                    historySection
                }
                .padding()
            }
            .navigationTitle("Health Coach")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Insights") {
                        showingInsightsSheet = true
                    }
                    .foregroundColor(.blue)
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showingGoalSheet) {
            GoalSettingView(coachingEngine: coachingEngine)
        }
        .sheet(isPresented: $showingInsightsSheet) {
            CoachingInsightsView(coachingEngine: coachingEngine)
        }
        .sheet(item: $selectedRecommendation) { recommendation in
            RecommendationDetailView(recommendation: recommendation, coachingEngine: coachingEngine)
        }
        .onAppear {
            setupCoachingSession()
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Coach Avatar and Status
            HStack {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Your AI Health Coach")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    HStack {
                        Circle()
                            .fill(coachingEngine.isCoachingActive ? .green : .gray)
                            .frame(width: 8, height: 8)
                        
                        Text(coachingEngine.isCoachingActive ? "Active Session" : "Ready to Start")
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
                        .foregroundColor(isVoiceEnabled ? .blue : .gray)
                }
            }
            
            // Current Goal Display
            if let goal = coachingEngine.currentGoal {
                GoalCardView(goal: goal)
            }
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
                Text("Current Session")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("End Session") {
                    Task {
                        await coachingEngine.endCoachingSession()
                    }
                }
                .foregroundColor(.red)
                .font(.subheadline)
            }
            
            if let session = coachingEngine.currentCoachingSession {
                SessionProgressView(session: session)
            }
            
            // User Interaction
            VStack(spacing: 12) {
                TextField("Ask your coach anything...", text: $userMessage)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                HStack {
                    Button("Send") {
                        sendUserMessage()
                    }
                    .disabled(userMessage.isEmpty)
                    .buttonStyle(.borderedProminent)
                    
                    Spacer()
                    
                    Button("Voice") {
                        // Voice input functionality
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Start Session Section
    private var startSessionSection: some View {
        VStack(spacing: 16) {
            Text("Ready to Start Your Health Journey?")
                .font(.headline)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
            
            Text("Your AI coach will provide personalized recommendations and guidance based on your health data and goals.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Start Coaching Session") {
                startCoachingSession()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            
            Button("Set Health Goal") {
                showingGoalSheet = true
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Recommendations Section
    private var recommendationsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Today's Recommendations")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("Refresh") {
                    refreshRecommendations()
                }
                .font(.subheadline)
                .foregroundColor(.blue)
            }
            
            if coachingEngine.activeRecommendations.isEmpty {
                Text("No recommendations available. Start a coaching session to get personalized recommendations.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(coachingEngine.activeRecommendations) { recommendation in
                        RecommendationCardView(recommendation: recommendation) {
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
    
    // MARK: - Progress Section
    private var progressSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Your Progress")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ProgressMetricCard(
                    title: "Total Sessions",
                    value: "\(coachingEngine.progressMetrics.totalSessions)",
                    icon: "calendar",
                    color: .blue
                )
                
                ProgressMetricCard(
                    title: "Avg. Duration",
                    value: formatDuration(coachingEngine.progressMetrics.totalDuration),
                    icon: "clock",
                    color: .green
                )
                
                ProgressMetricCard(
                    title: "Recommendations",
                    value: "\(coachingEngine.progressMetrics.totalRecommendationsFollowed)",
                    icon: "checkmark.circle",
                    color: .orange
                )
                
                ProgressMetricCard(
                    title: "Goal Progress",
                    value: "\(Int(coachingEngine.progressMetrics.averageGoalProgress * 100))%",
                    icon: "target",
                    color: .purple
                )
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
                    title: "Set Goal",
                    icon: "target",
                    color: .blue
                ) {
                    showingGoalSheet = true
                }
                
                QuickActionCard(
                    title: "View Insights",
                    icon: "chart.bar",
                    color: .green
                ) {
                    showingInsightsSheet = true
                }
                
                QuickActionCard(
                    title: "Voice Settings",
                    icon: "speaker.wave.2",
                    color: .orange
                ) {
                    showingVoiceSettings = true
                }
                
                QuickActionCard(
                    title: "History",
                    icon: "clock.arrow.circlepath",
                    color: .purple
                ) {
                    // Show history
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - History Section
    private var historySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Sessions")
                .font(.headline)
                .fontWeight(.semibold)
            
            if coachingEngine.coachingHistory.isEmpty {
                Text("No previous sessions. Start your first coaching session to see your history here.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(Array(coachingEngine.coachingHistory.prefix(5)), id: \.id) { session in
                        SessionHistoryCard(session: session)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Helper Methods
    private func setupCoachingSession() {
        // Initialize coaching session if needed
    }
    
    private func startCoachingSession() {
        Task {
            do {
                _ = try await coachingEngine.startCoachingSession()
            } catch {
                print("Failed to start coaching session: \(error)")
            }
        }
    }
    
    private func refreshRecommendations() {
        Task {
            do {
                _ = try await coachingEngine.generateRecommendations()
            } catch {
                print("Failed to refresh recommendations: \(error)")
            }
        }
    }
    
    private func sendUserMessage() {
        guard !userMessage.isEmpty else { return }
        
        let interaction = UserInteraction(
            type: .question,
            message: userMessage,
            timestamp: Date(),
            metadata: [:]
        )
        
        Task {
            do {
                let response = try await coachingEngine.processUserInteraction(interaction)
                
                // Handle voice coaching if enabled
                if isVoiceEnabled {
                    await coachingEngine.provideVoiceCoaching(response.message)
                }
                
                // Clear message
                await MainActor.run {
                    userMessage = ""
                }
            } catch {
                print("Failed to process user interaction: \(error)")
            }
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration / 60)
        return "\(minutes)m"
    }
}

// MARK: - Supporting Views

struct GoalCardView: View {
    let goal: HealthGoal
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: goalIcon(for: goal.type))
                    .foregroundColor(.blue)
                
                Text(goal.type.displayName)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text(goal.timeframe.displayName)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            }
            
            Text(goal.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func goalIcon(for type: HealthGoal.HealthGoalType) -> String {
        switch type {
        case .weightLoss: return "scalemass"
        case .cardiovascularHealth: return "heart.fill"
        case .sleepOptimization: return "bed.double.fill"
        case .stressReduction: return "brain.head.profile"
        case .generalWellness: return "leaf.fill"
        }
    }
}

struct SessionProgressView: View {
    let session: CoachingSession
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Session Duration")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(formatDuration(session.duration))
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            
            if let metrics = session.metrics {
                HStack {
                    Text("Recommendations Followed")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(metrics.recommendationsFollowed)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
            }
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration / 60)
        let seconds = Int(duration.truncatingRemainder(dividingBy: 60))
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

struct RecommendationCardView: View {
    let recommendation: HealthRecommendation
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: recommendationIcon(for: recommendation.type))
                        .foregroundColor(priorityColor(for: recommendation.priority))
                    
                    Text(recommendation.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    PriorityBadge(priority: recommendation.priority)
                }
                
                Text(recommendation.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
                
                HStack {
                    Label("\(recommendation.estimatedTime)m", systemImage: "clock")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Label(recommendation.difficulty.rawValue.capitalized, systemImage: "speedometer")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func recommendationIcon(for type: HealthRecommendation.RecommendationType) -> String {
        switch type {
        case .cardiovascular: return "heart.fill"
        case .sleep: return "bed.double.fill"
        case .stress: return "brain.head.profile"
        case .nutrition: return "leaf.fill"
        case .exercise: return "figure.walk"
        case .mentalHealth: return "brain"
        case .lifestyle: return "house.fill"
        }
    }
    
    private func priorityColor(for priority: HealthRecommendation.Priority) -> Color {
        switch priority {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        }
    }
}

struct PriorityBadge: View {
    let priority: HealthRecommendation.Priority
    
    var body: some View {
        Text(priority.rawValue.capitalized)
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(priorityColor(for: priority))
            .cornerRadius(8)
    }
    
    private func priorityColor(for priority: HealthRecommendation.Priority) -> Color {
        switch priority {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        }
    }
}

struct ProgressMetricCard: View {
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
                .font(.title3)
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
}

struct QuickActionCard: View {
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

struct SessionHistoryCard: View {
    let session: CoachingSession
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(session.startTime, style: .date)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text(session.status.rawValue.capitalized)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            }
            
            if let goal = session.goal {
                Text(goal.type.displayName)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if let metrics = session.metrics {
                HStack {
                    Text("Duration: \(formatDuration(metrics.duration))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("Progress: \(Int(metrics.goalProgress * 100))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration / 60)
        return "\(minutes)m"
    }
}

// MARK: - Extensions

extension HealthGoal.HealthGoalType {
    var displayName: String {
        switch self {
        case .weightLoss: return "Weight Loss"
        case .cardiovascularHealth: return "Cardiovascular Health"
        case .sleepOptimization: return "Sleep Optimization"
        case .stressReduction: return "Stress Reduction"
        case .generalWellness: return "General Wellness"
        }
    }
}

extension HealthGoal.Timeframe {
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
    RealTimeCoachingDashboardView(
        healthDataManager: HealthDataManager(),
        predictionEngine: AdvancedHealthPredictionEngine(),
        analyticsEngine: AnalyticsEngine()
    )
} 
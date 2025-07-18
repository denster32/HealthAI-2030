import SwiftUI
import Charts

/// Fitness & Exercise Optimization View
/// Provides a comprehensive dashboard for fitness tracking, workout planning,
/// exercise optimization tools, social features, and analytics
struct FitnessExerciseOptimizationView: View {
    @StateObject private var engine: FitnessExerciseOptimizationEngine
    @State private var selectedTab = 0
    @State private var showingWorkoutEntry = false
    @State private var showingRecoveryEntry = false
    @State private var showingPlan = false
    @State private var showingRecommendation = false
    @State private var selectedRecommendation: ExerciseRecommendation?

    init(healthDataManager: HealthDataManager, mlModelManager: MLModelManager, notificationManager: NotificationManager) {
        self._engine = StateObject(wrappedValue: FitnessExerciseOptimizationEngine(
            healthDataManager: healthDataManager,
            mlModelManager: mlModelManager,
            notificationManager: notificationManager
        ))
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                fitnessTabSelector
                TabView(selection: $selectedTab) {
                    dashboardView.tag(0)
                    workoutPlanningView.tag(1)
                    optimizationToolsView.tag(2)
                    socialFeaturesView.tag(3)
                    analyticsView.tag(4)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .navigationTitle("Fitness & Exercise")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingWorkoutEntry.toggle() }) {
                        Image(systemName: "plus.circle")
                            .foregroundColor(.blue)
                    }
                }
            }
            .sheet(isPresented: $showingWorkoutEntry) {
                WorkoutEntryView(engine: engine)
            }
            .sheet(isPresented: $showingRecoveryEntry) {
                RecoveryEntryView(engine: engine)
            }
            .sheet(isPresented: $showingPlan) {
                WorkoutPlanView(engine: engine)
            }
            .sheet(isPresented: $showingRecommendation) {
                if let recommendation = selectedRecommendation {
                    RecommendationDetailView(engine: engine, recommendation: recommendation)
                }
            }
            .onAppear {
                Task {
                    try? await engine.generateAIWorkoutPlan()
                }
            }
        }
    }

    // MARK: - Tab Selector
    private var fitnessTabSelector: some View {
        HStack(spacing: 0) {
            TabButton(title: "Dashboard", icon: "figure.walk", isSelected: selectedTab == 0, action: { selectedTab = 0 })
            TabButton(title: "Plan", icon: "calendar", isSelected: selectedTab == 1, action: { selectedTab = 1 })
            TabButton(title: "Optimize", icon: "bolt.heart", isSelected: selectedTab == 2, action: { selectedTab = 2 })
            TabButton(title: "Social", icon: "person.3.fill", isSelected: selectedTab == 3, action: { selectedTab = 3 })
            TabButton(title: "Analytics", icon: "chart.bar.xaxis", isSelected: selectedTab == 4, action: { selectedTab = 4 })
        }
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - Dashboard
    private var dashboardView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                fitnessSummaryCard
                quickActionsSection
                workoutHistorySection
                recoverySection
                aiRecommendationsSection
            }
            .padding()
        }
        .refreshable {
            Task {
                try? await engine.generateAIWorkoutPlan()
            }
        }
    }

    private var fitnessSummaryCard: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Today's Fitness")
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text("Your daily fitness summary")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Text("\(Int(engine.fitnessData.dailyWorkoutDuration)) min")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.blue)
                    Text("workout")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            ProgressView(value: min(engine.fitnessData.dailyWorkoutDuration / 60.0, 1.0), total: 1.0)
                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
            Text("Goal: 60 min")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 4)
    }

    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.headline)
                .fontWeight(.semibold)
            HStack(spacing: 12) {
                QuickActionButton(
                    title: "Log Workout",
                    icon: "plus.circle.fill",
                    color: .blue
                ) {
                    showingWorkoutEntry.toggle()
                }
                QuickActionButton(
                    title: "Add Recovery",
                    icon: "bed.double.fill",
                    color: .green
                ) {
                    showingRecoveryEntry.toggle()
                }
                QuickActionButton(
                    title: "View Plan",
                    icon: "calendar",
                    color: .purple
                ) {
                    showingPlan.toggle()
                }
            }
        }
    }

    private var workoutHistorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Workouts")
                .font(.headline)
                .fontWeight(.semibold)
            if engine.workoutHistory.isEmpty {
                Text("No workouts logged today")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(engine.workoutHistory.prefix(3), id: \.id) { workout in
                    WorkoutRowView(workout: workout)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 4)
    }

    private var recoverySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recovery")
                .font(.headline)
                .fontWeight(.semibold)
            if engine.recoveryHistory.isEmpty {
                Text("No recovery sessions logged today")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(engine.recoveryHistory.prefix(2), id: \.id) { recovery in
                    RecoveryRowView(recovery: recovery)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 4)
    }

    private var aiRecommendationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("AI Recommendations")
                .font(.headline)
                .fontWeight(.semibold)
            if engine.aiRecommendations.isEmpty {
                Text("No recommendations yet")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(engine.aiRecommendations.prefix(2), id: \.id) { recommendation in
                    RecommendationRowView(recommendation: recommendation) {
                        selectedRecommendation = recommendation
                        showingRecommendation = true
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 4)
    }

    // MARK: - Workout Planning
    private var workoutPlanningView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                if let plan = engine.aiWorkoutPlan {
                    workoutPlanCard(plan)
                    plannedWorkoutsSection(plan)
                } else {
                    emptyWorkoutPlanView
                }
                workoutHistorySection
            }
            .padding()
        }
    }

    private func workoutPlanCard(_ plan: AIWorkoutPlan) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("This Week's Plan")
                .font(.headline)
                .fontWeight(.semibold)
            HStack {
                VStack(alignment: .leading) {
                    Text("Focus: \(plan.focusAreas.joined(separator: ", "))")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                    Text("Workouts: \(plan.dailyWorkouts.count)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Text("Start: \(plan.weekStart, style: .date)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 4)
    }

    private func plannedWorkoutsSection(_ plan: AIWorkoutPlan) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Planned Workouts")
                .font(.headline)
                .fontWeight(.semibold)
            ForEach(plan.dailyWorkouts, id: \.name) { workout in
                PlannedWorkoutRow(workout: workout)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 4)
    }

    private var emptyWorkoutPlanView: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar")
                .font(.system(size: 48))
                .foregroundColor(.purple)
            Text("No Workout Plan")
                .font(.headline)
                .fontWeight(.semibold)
            Text("Generate a personalized workout plan based on your goals and preferences")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            Button("Generate Plan") {
                Task {
                    try? await engine.generateAIWorkoutPlan()
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(.purple)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 4)
    }

    // MARK: - Optimization Tools
    private var optimizationToolsView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                aiRecommendationsToolsSection
                trainingFeaturesSection
            }
            .padding()
        }
    }

    private var aiRecommendationsToolsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("AI Exercise Optimization")
                .font(.headline)
                .fontWeight(.semibold)
            if engine.aiRecommendations.isEmpty {
                Text("No AI recommendations available")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(engine.aiRecommendations, id: \.id) { recommendation in
                    RecommendationCard(recommendation: recommendation) {
                        selectedRecommendation = recommendation
                        showingRecommendation = true
                    }
                }
            }
            Button("Generate New Recommendations") {
                Task {
                    try? await engine.generateExerciseRecommendations()
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(.blue)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 4)
    }

    private var trainingFeaturesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Advanced Training Features")
                .font(.headline)
                .fontWeight(.semibold)
            if engine.trainingFeatures.isEmpty {
                Text("No advanced training features configured")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(engine.trainingFeatures, id: \.id) { feature in
                    TrainingFeatureCard(feature: feature)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 4)
    }

    // MARK: - Social Features
    private var socialFeaturesView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                socialFeaturesSection
            }
            .padding()
        }
    }

    private var socialFeaturesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Social Fitness Features")
                .font(.headline)
                .fontWeight(.semibold)
            if engine.socialFeatures.isEmpty {
                Text("No social features enabled")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(engine.socialFeatures, id: \.id) { feature in
                    SocialFeatureCard(feature: feature)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 4)
    }

    // MARK: - Analytics
    private var analyticsView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                performanceMetricsSection
                fitnessCorrelationsSection
                trendsSection
            }
            .padding()
        }
    }

    private var performanceMetricsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Performance Metrics")
                .font(.headline)
                .fontWeight(.semibold)
            if let metrics = engine.fitnessData.performanceMetrics {
                VStack(spacing: 8) {
                    PerformanceMetricRow(label: "VO2 Max", value: "\(metrics.vo2Max)", color: .blue)
                    PerformanceMetricRow(label: "Max HR", value: "\(Int(metrics.maxHeartRate))", color: .red)
                    PerformanceMetricRow(label: "Resting HR", value: "\(Int(metrics.restingHeartRate))", color: .green)
                    PerformanceMetricRow(label: "Power Output", value: "\(Int(metrics.powerOutput))", color: .orange)
                    PerformanceMetricRow(label: "Agility", value: "\(Int(metrics.agility))", color: .purple)
                }
            } else {
                Text("No performance metrics available")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 4)
    }

    private var fitnessCorrelationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Fitness Correlations")
                .font(.headline)
                .fontWeight(.semibold)
            if let correlations = engine.fitnessData.healthCorrelations {
                VStack(spacing: 8) {
                    PerformanceMetricRow(label: "Overall Fitness Score", value: "\(Int(correlations.overallFitnessScore * 100))%", color: .blue)
                    PerformanceMetricRow(label: "VO2 Max Corr.", value: "\(Int(correlations.vo2MaxCorrelation * 100))%", color: .green)
                    PerformanceMetricRow(label: "Strength Corr.", value: "\(Int(correlations.strengthCorrelation * 100))%", color: .orange)
                    PerformanceMetricRow(label: "Endurance Corr.", value: "\(Int(correlations.enduranceCorrelation * 100))%", color: .purple)
                    PerformanceMetricRow(label: "Injury Risk", value: "\(Int(correlations.injuryRisk * 100))%", color: .red)
                }
            } else {
                Text("No fitness correlations available")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 4)
    }

    private var trendsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Fitness Trends")
                .font(.headline)
                .fontWeight(.semibold)
            Text("Your fitness patterns over time")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Text("Trends chart will appear here")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 4)
    }
}

// MARK: - Supporting Views

struct TabButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(isSelected ? .blue : .secondary)
                Text(title)
                    .font(.caption2)
                    .fontWeight(isSelected ? .bold : .regular)
                    .foregroundColor(isSelected ? .blue : .secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(isSelected ? Color(.systemGray5) : Color.clear)
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct QuickActionButton: View {
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

struct WorkoutRowView: View {
    let workout: WorkoutEntry
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(workout.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(workout.workoutType.rawValue)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(Int(workout.duration)) min")
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(workout.timestamp, style: .time)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
    }
}

struct RecoveryRowView: View {
    let recovery: RecoveryEntry
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(recovery.recoveryType.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text("Sleep: \(recovery.sleepHours, specifier: "%.1f")h")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(Int(recovery.recoveryTime)) min")
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(recovery.timestamp, style: .time)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
    }
}

struct RecommendationRowView: View {
    let recommendation: ExerciseRecommendation
    let onTap: () -> Void
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(recommendation.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    Text(recommendation.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct PlannedWorkoutRow: View {
    let workout: PlannedWorkout
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(workout.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(workout.workoutType.rawValue)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(Int(workout.duration)) min")
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(workout.day.rawValue)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
    }
}

struct RecommendationCard: View {
    let recommendation: ExerciseRecommendation
    let onTap: () -> Void
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(recommendation.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    Spacer()
                    Text(recommendation.priority.rawValue)
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(priorityColor)
                        .cornerRadius(8)
                }
                Text(recommendation.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
                if !recommendation.actionItems.isEmpty {
                    Text("Actions: \(recommendation.actionItems.joined(separator: ", "))")
                        .font(.caption2)
                        .foregroundColor(.blue)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
    private var priorityColor: Color {
        switch recommendation.priority {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        case .critical: return .purple
        }
    }
}

struct TrainingFeatureCard: View {
    let feature: TrainingFeature
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(feature.name)
                .font(.subheadline)
                .fontWeight(.medium)
            Text(feature.description)
                .font(.caption)
                .foregroundColor(.secondary)
            if !feature.details.isEmpty {
                Text("Details: \(feature.details.joined(separator: ", "))")
                    .font(.caption2)
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct SocialFeatureCard: View {
    let feature: SocialFitnessFeature
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(feature.name)
                .font(.subheadline)
                .fontWeight(.medium)
            Text(feature.description)
                .font(.caption)
                .foregroundColor(.secondary)
            if !feature.participants.isEmpty {
                Text("Participants: \(feature.participants.joined(separator: ", "))")
                    .font(.caption2)
                    .foregroundColor(.purple)
            }
            if !feature.details.isEmpty {
                Text("Details: \(feature.details.joined(separator: ", "))")
                    .font(.caption2)
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct PerformanceMetricRow: View {
    let label: String
    let value: String
    let color: Color
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.primary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(color)
        }
    }
}

// MARK: - Placeholder Views

struct WorkoutEntryView: View {
    let engine: FitnessExerciseOptimizationEngine
    @Environment(\.presentationMode) var presentationMode
    var body: some View {
        NavigationView {
            VStack {
                Text("Workout Entry View")
                    .font(.title)
                Text("Implementation coming soon...")
                    .foregroundColor(.secondary)
            }
            .navigationTitle("Log Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

struct RecoveryEntryView: View {
    let engine: FitnessExerciseOptimizationEngine
    @Environment(\.presentationMode) var presentationMode
    var body: some View {
        NavigationView {
            VStack {
                Text("Recovery Entry View")
                    .font(.title)
                Text("Implementation coming soon...")
                    .foregroundColor(.secondary)
            }
            .navigationTitle("Add Recovery")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

struct WorkoutPlanView: View {
    let engine: FitnessExerciseOptimizationEngine
    @Environment(\.presentationMode) var presentationMode
    var body: some View {
        NavigationView {
            VStack {
                Text("Workout Plan View")
                    .font(.title)
                Text("Implementation coming soon...")
                    .foregroundColor(.secondary)
            }
            .navigationTitle("Workout Plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

struct RecommendationDetailView: View {
    let engine: FitnessExerciseOptimizationEngine
    let recommendation: ExerciseRecommendation
    @Environment(\.presentationMode) var presentationMode
    var body: some View {
        NavigationView {
            VStack {
                Text("Recommendation Detail")
                    .font(.title)
                Text("Implementation coming soon...")
                    .foregroundColor(.secondary)
            }
            .navigationTitle("Recommendation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
} 
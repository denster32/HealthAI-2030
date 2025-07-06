import SwiftUI
import Charts

/// Mental Health & Wellness View
/// Provides comprehensive mental health monitoring interface with mood tracking,
/// stress monitoring, wellness dashboard, crisis support, and intervention tools
struct MentalHealthWellnessView: View {
    
    // MARK: - Properties
    
    @StateObject private var wellnessEngine: MentalHealthWellnessEngine
    @State private var showingMoodEntry = false
    @State private var showingStressEntry = false
    @State private var showingCrisisSupport = false
    @State private var showingIntervention = false
    @State private var selectedIntervention: WellnessIntervention?
    @State private var selectedTab = 0
    
    // MARK: - Initialization
    
    init(healthDataManager: HealthDataManager, mlModelManager: MLModelManager, notificationManager: NotificationManager, crisisInterventionManager: CrisisInterventionManager) {
        self._wellnessEngine = StateObject(wrappedValue: MentalHealthWellnessEngine(
            healthDataManager: healthDataManager,
            mlModelManager: mlModelManager,
            notificationManager: notificationManager,
            crisisInterventionManager: crisisInterventionManager
        ))
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Tab selector
                wellnessTabSelector
                
                // Tab content
                TabView(selection: $selectedTab) {
                    // Wellness Dashboard
                    wellnessDashboard
                        .tag(0)
                    
                    // Mood Tracking
                    moodTrackingView
                        .tag(1)
                    
                    // Stress Monitoring
                    stressMonitoringView
                        .tag(2)
                    
                    // Interventions
                    interventionsView
                        .tag(3)
                    
                    // Crisis Support
                    crisisSupportView
                        .tag(4)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .navigationTitle("Mental Wellness")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingMoodEntry.toggle() }) {
                        Image(systemName: "plus.circle")
                            .foregroundColor(.blue)
                    }
                }
            }
            .sheet(isPresented: $showingMoodEntry) {
                MoodEntryView(wellnessEngine: wellnessEngine)
            }
            .sheet(isPresented: $showingStressEntry) {
                StressEntryView(wellnessEngine: wellnessEngine)
            }
            .sheet(isPresented: $showingCrisisSupport) {
                CrisisSupportView(wellnessEngine: wellnessEngine)
            }
            .sheet(isPresented: $showingIntervention) {
                if let intervention = selectedIntervention {
                    InterventionView(wellnessEngine: wellnessEngine, intervention: intervention)
                }
            }
            .onAppear {
                // Load initial data
            }
        }
    }
    
    // MARK: - Tab Selector
    
    private var wellnessTabSelector: some View {
        HStack(spacing: 0) {
            TabButton(
                title: "Dashboard",
                icon: "heart.fill",
                isSelected: selectedTab == 0,
                action: { selectedTab = 0 }
            )
            
            TabButton(
                title: "Mood",
                icon: "face.smiling",
                isSelected: selectedTab == 1,
                action: { selectedTab = 1 }
            )
            
            TabButton(
                title: "Stress",
                icon: "brain.head.profile",
                isSelected: selectedTab == 2,
                action: { selectedTab = 2 }
            )
            
            TabButton(
                title: "Tools",
                icon: "wrench.and.screwdriver",
                isSelected: selectedTab == 3,
                action: { selectedTab = 3 }
            )
            
            TabButton(
                title: "Support",
                icon: "hand.raised.fill",
                isSelected: selectedTab == 4,
                action: { selectedTab = 4 }
            )
        }
        .background(Color(.systemGroupedBackground))
    }
    
    // MARK: - Wellness Dashboard
    
    private var wellnessDashboard: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Wellness score card
                wellnessScoreCard
                
                // Quick actions
                quickActionsSection
                
                // Recent mood and stress
                recentMoodStressSection
                
                // Wellness recommendations
                wellnessRecommendationsSection
                
                // Crisis alerts
                crisisAlertsSection
            }
            .padding()
        }
        .refreshable {
            // Refresh wellness data
        }
    }
    
    private var wellnessScoreCard: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Wellness Score")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("Your overall mental wellness")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text("\(Int(wellnessEngine.wellnessScore * 100))")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(wellnessScoreColor)
            }
            
            // Progress bar
            ProgressView(value: wellnessEngine.wellnessScore, total: 1.0)
                .progressViewStyle(LinearProgressViewStyle(tint: wellnessScoreColor))
            
            // Wellness status
            Text(wellnessStatusText)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(wellnessScoreColor)
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
                .foregroundColor(.primary)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
                QuickActionButton(
                    title: "Record Mood",
                    icon: "face.smiling",
                    color: .blue
                ) {
                    showingMoodEntry.toggle()
                }
                
                QuickActionButton(
                    title: "Track Stress",
                    icon: "brain.head.profile",
                    color: .orange
                ) {
                    showingStressEntry.toggle()
                }
                
                QuickActionButton(
                    title: "Meditation",
                    icon: "sparkles",
                    color: .purple
                ) {
                    // Start meditation
                }
                
                QuickActionButton(
                    title: "Breathing",
                    icon: "lungs.fill",
                    color: .green
                ) {
                    // Start breathing exercise
                }
            }
        }
    }
    
    private var recentMoodStressSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Activity")
                .font(.headline)
                .foregroundColor(.primary)
            
            if wellnessEngine.moodHistory.isEmpty && wellnessEngine.stressLevels.isEmpty {
                EmptyStateView(
                    icon: "heart",
                    title: "No Recent Activity",
                    message: "Start tracking your mood and stress to see your patterns"
                )
            } else {
                // Recent mood entries
                if let recentMood = wellnessEngine.moodHistory.last {
                    RecentActivityCard(
                        title: "Recent Mood",
                        value: recentMood.moodType.displayName,
                        icon: "face.smiling",
                        color: .blue,
                        timestamp: recentMood.timestamp
                    )
                }
                
                // Recent stress levels
                if let recentStress = wellnessEngine.stressLevels.last {
                    RecentActivityCard(
                        title: "Recent Stress",
                        value: stressLevelText(recentStress.stressLevel),
                        icon: "brain.head.profile",
                        color: .orange,
                        timestamp: recentStress.timestamp
                    )
                }
            }
        }
    }
    
    private var wellnessRecommendationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Wellness Recommendations")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button("View All") {
                    // Navigate to all recommendations
                }
                .font(.subheadline)
                .foregroundColor(.blue)
            }
            
            if wellnessEngine.wellnessRecommendations.isEmpty {
                EmptyStateView(
                    icon: "lightbulb",
                    title: "No Recommendations",
                    message: "Complete mood and stress tracking to get personalized recommendations"
                )
            } else {
                ForEach(wellnessEngine.wellnessRecommendations.prefix(3)) { recommendation in
                    WellnessRecommendationCard(recommendation: recommendation)
                }
            }
        }
    }
    
    private var crisisAlertsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Crisis Support")
                .font(.headline)
                .foregroundColor(.primary)
            
            if wellnessEngine.crisisAlerts.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "checkmark.shield")
                        .font(.system(size: 32))
                        .foregroundColor(.green)
                    
                    Text("You're doing well!")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text("No crisis indicators detected")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
            } else {
                ForEach(wellnessEngine.crisisAlerts) { alert in
                    CrisisAlertCard(alert: alert) {
                        showingCrisisSupport.toggle()
                    }
                }
            }
        }
    }
    
    // MARK: - Mood Tracking View
    
    private var moodTrackingView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Mood entry button
                moodEntryButton
                
                // Mood history chart
                moodHistoryChart
                
                // Mood patterns
                moodPatternsSection
                
                // Mood insights
                moodInsightsSection
            }
            .padding()
        }
    }
    
    private var moodEntryButton: some View {
        Button(action: { showingMoodEntry.toggle() }) {
            HStack {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                Text("Record Your Mood")
                    .font(.headline)
                    .fontWeight(.medium)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .cornerRadius(12)
        }
    }
    
    private var moodHistoryChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Mood History")
                .font(.headline)
                .foregroundColor(.primary)
            
            if wellnessEngine.moodHistory.isEmpty {
                EmptyStateView(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "No Mood Data",
                    message: "Start recording your mood to see your patterns"
                )
            } else {
                // Mood chart would go here
                Text("Mood Chart Placeholder")
                    .frame(height: 200)
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
            }
        }
    }
    
    private var moodPatternsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Mood Patterns")
                .font(.headline)
                .foregroundColor(.primary)
            
            if let patterns = wellnessEngine.mentalHealthData.moodPatterns {
                VStack(spacing: 8) {
                    PatternCard(
                        title: "Daily Pattern",
                        description: "Your mood throughout the day",
                        icon: "sun.max"
                    )
                    
                    PatternCard(
                        title: "Weekly Pattern",
                        description: "Your mood throughout the week",
                        icon: "calendar"
                    )
                    
                    PatternCard(
                        title: "Triggers",
                        description: "Factors affecting your mood",
                        icon: "bolt"
                    )
                }
            } else {
                EmptyStateView(
                    icon: "chart.bar",
                    title: "No Patterns Yet",
                    message: "Continue tracking to discover your mood patterns"
                )
            }
        }
    }
    
    private var moodInsightsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Mood Insights")
                .font(.headline)
                .foregroundColor(.primary)
            
            if let insights = wellnessEngine.mentalHealthData.wellnessInsights {
                ForEach(insights.trends, id: \.self) { trend in
                    InsightCard(text: trend, type: .trend)
                }
            } else {
                EmptyStateView(
                    icon: "lightbulb",
                    title: "No Insights Yet",
                    message: "More mood data needed for personalized insights"
                )
            }
        }
    }
    
    // MARK: - Stress Monitoring View
    
    private var stressMonitoringView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Stress entry button
                stressEntryButton
                
                // Stress level chart
                stressLevelChart
                
                // Stress patterns
                stressPatternsSection
                
                // Stress management
                stressManagementSection
            }
            .padding()
        }
    }
    
    private var stressEntryButton: some View {
        Button(action: { showingStressEntry.toggle() }) {
            HStack {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                Text("Track Stress Level")
                    .font(.headline)
                    .fontWeight(.medium)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.orange)
            .cornerRadius(12)
        }
    }
    
    private var stressLevelChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Stress Levels")
                .font(.headline)
                .foregroundColor(.primary)
            
            if wellnessEngine.stressLevels.isEmpty {
                EmptyStateView(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "No Stress Data",
                    message: "Start tracking your stress to see your patterns"
                )
            } else {
                // Stress chart would go here
                Text("Stress Chart Placeholder")
                    .frame(height: 200)
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
            }
        }
    }
    
    private var stressPatternsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Stress Patterns")
                .font(.headline)
                .foregroundColor(.primary)
            
            if let patterns = wellnessEngine.mentalHealthData.stressPatterns {
                VStack(spacing: 8) {
                    PatternCard(
                        title: "Daily Pattern",
                        description: "Your stress throughout the day",
                        icon: "clock"
                    )
                    
                    PatternCard(
                        title: "Weekly Pattern",
                        description: "Your stress throughout the week",
                        icon: "calendar"
                    )
                    
                    PatternCard(
                        title: "Triggers",
                        description: "Factors causing stress",
                        icon: "exclamationmark.triangle"
                    )
                    
                    PatternCard(
                        title: "Coping Strategies",
                        description: "What helps you manage stress",
                        icon: "heart"
                    )
                }
            } else {
                EmptyStateView(
                    icon: "chart.bar",
                    title: "No Patterns Yet",
                    message: "Continue tracking to discover your stress patterns"
                )
            }
        }
    }
    
    private var stressManagementSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Stress Management")
                .font(.headline)
                .foregroundColor(.primary)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
                StressManagementCard(
                    title: "Breathing",
                    description: "Deep breathing exercises",
                    icon: "lungs.fill",
                    color: .green
                ) {
                    // Start breathing exercise
                }
                
                StressManagementCard(
                    title: "Meditation",
                    description: "Mindfulness meditation",
                    icon: "sparkles",
                    color: .purple
                ) {
                    // Start meditation
                }
                
                StressManagementCard(
                    title: "Exercise",
                    description: "Physical activity",
                    icon: "figure.walk",
                    color: .blue
                ) {
                    // Start exercise
                }
                
                StressManagementCard(
                    title: "Social",
                    description: "Connect with others",
                    icon: "person.2",
                    color: .pink
                ) {
                    // Connect socially
                }
            }
        }
    }
    
    // MARK: - Interventions View
    
    private var interventionsView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // AI interventions
                aiInterventionsSection
                
                // Wellness tools
                wellnessToolsSection
            }
            .padding()
        }
    }
    
    private var aiInterventionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("AI-Powered Interventions")
                .font(.headline)
                .foregroundColor(.primary)
            
            if wellnessEngine.aiInterventions.isEmpty {
                EmptyStateView(
                    icon: "brain.head.profile",
                    title: "No Interventions",
                    message: "Complete mood and stress tracking to get AI recommendations"
                )
            } else {
                ForEach(wellnessEngine.aiInterventions) { intervention in
                    InterventionCard(intervention: intervention) {
                        selectedIntervention = intervention
                        showingIntervention.toggle()
                    }
                }
            }
        }
    }
    
    private var wellnessToolsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Wellness Tools")
                .font(.headline)
                .foregroundColor(.primary)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
                WellnessToolCard(
                    title: "Meditation",
                    description: "Guided meditation sessions",
                    icon: "sparkles",
                    color: .purple
                ) {
                    // Start meditation
                }
                
                WellnessToolCard(
                    title: "Breathing",
                    description: "Breathing exercises",
                    icon: "lungs.fill",
                    color: .green
                ) {
                    // Start breathing
                }
                
                WellnessToolCard(
                    title: "CBT",
                    description: "Cognitive behavioral therapy",
                    icon: "brain.head.profile",
                    color: .blue
                ) {
                    // Start CBT
                }
                
                WellnessToolCard(
                    title: "Mindfulness",
                    description: "Mindfulness practices",
                    icon: "leaf",
                    color: .orange
                ) {
                    // Start mindfulness
                }
            }
        }
    }
    
    // MARK: - Crisis Support View
    
    private var crisisSupportView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Crisis resources
                crisisResourcesSection
                
                // Emergency contacts
                emergencyContactsSection
                
                // Safety planning
                safetyPlanningSection
            }
            .padding()
        }
    }
    
    private var crisisResourcesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Crisis Resources")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                CrisisResourceCard(
                    title: "National Suicide Prevention Lifeline",
                    description: "24/7 free and confidential support",
                    phone: "988",
                    icon: "phone.fill",
                    color: .red
                )
                
                CrisisResourceCard(
                    title: "Crisis Text Line",
                    description: "Text HOME to 741741",
                    phone: "741741",
                    icon: "message.fill",
                    color: .blue
                )
                
                CrisisResourceCard(
                    title: "Emergency Services",
                    description: "Call 911 for immediate help",
                    phone: "911",
                    icon: "exclamationmark.triangle.fill",
                    color: .red
                )
            }
        }
    }
    
    private var emergencyContactsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Emergency Contacts")
                .font(.headline)
                .foregroundColor(.primary)
            
            EmptyStateView(
                icon: "person.2",
                title: "No Emergency Contacts",
                message: "Add trusted contacts for crisis situations"
            )
        }
    }
    
    private var safetyPlanningSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Safety Planning")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(spacing: 8) {
                SafetyPlanCard(
                    title: "Warning Signs",
                    description: "Recognize your warning signs",
                    icon: "exclamationmark.triangle",
                    color: .orange
                )
                
                SafetyPlanCard(
                    title: "Coping Strategies",
                    description: "What helps you feel better",
                    icon: "heart",
                    color: .green
                )
                
                SafetyPlanCard(
                    title: "Support Network",
                    description: "People you can reach out to",
                    icon: "person.2",
                    color: .blue
                )
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private var wellnessScoreColor: Color {
        switch wellnessEngine.wellnessScore {
        case 0.0..<0.3: return .red
        case 0.3..<0.6: return .orange
        case 0.6..<0.8: return .yellow
        case 0.8...1.0: return .green
        default: return .gray
        }
    }
    
    private var wellnessStatusText: String {
        switch wellnessEngine.wellnessScore {
        case 0.0..<0.3: return "Needs Support"
        case 0.3..<0.6: return "Could Improve"
        case 0.6..<0.8: return "Doing Well"
        case 0.8...1.0: return "Excellent"
        default: return "Unknown"
        }
    }
    
    private func stressLevelText(_ level: Double) -> String {
        switch level {
        case 0.0..<0.3: return "Low"
        case 0.3..<0.6: return "Moderate"
        case 0.6..<0.8: return "High"
        case 0.8...1.0: return "Very High"
        default: return "Unknown"
        }
    }
}

// MARK: - Supporting Views

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
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(radius: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct RecentActivityCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let timestamp: Date
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            VStack(alignment: .leading) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(value)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(timestamp, style: .time)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

struct WellnessRecommendationCard: View {
    let recommendation: WellnessRecommendation
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(recommendation.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("\(Int(recommendation.confidence * 100))%")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.blue)
            }
            
            Text(recommendation.description)
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack {
                Text(recommendation.category.rawValue.capitalized)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(categoryColor.opacity(0.2))
                    .foregroundColor(categoryColor)
                    .cornerRadius(8)
                
                Spacer()
                
                Text(recommendation.priority.rawValue.capitalized)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(priorityColor.opacity(0.2))
                    .foregroundColor(priorityColor)
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
    
    private var categoryColor: Color {
        switch recommendation.category {
        case .sleep: return .blue
        case .exercise: return .green
        case .nutrition: return .orange
        case .social: return .pink
        case .stress: return .red
        case .mindfulness: return .purple
        case .therapy: return .indigo
        case .lifestyle: return .gray
        }
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

struct CrisisAlertCard: View {
    let alert: CrisisAlert
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.title2)
                    .foregroundColor(.red)
                
                VStack(alignment: .leading) {
                    Text(alert.type.rawValue.replacingOccurrences(of: "_", with: " ").capitalized)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text(alert.message)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.red.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct PatternCard: View {
    let title: String
    let description: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

struct InsightCard: View {
    let text: String
    let type: InsightType
    
    var body: some View {
        HStack {
            Image(systemName: type.icon)
                .font(.title3)
                .foregroundColor(type.color)
                .frame(width: 24)
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(.primary)
            
            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

enum InsightType {
    case trend, recommendation, risk, protective
    
    var icon: String {
        switch self {
        case .trend: return "chart.line.uptrend.xyaxis"
        case .recommendation: return "lightbulb"
        case .risk: return "exclamationmark.triangle"
        case .protective: return "shield"
        }
    }
    
    var color: Color {
        switch self {
        case .trend: return .blue
        case .recommendation: return .green
        case .risk: return .red
        case .protective: return .orange
        }
    }
}

struct StressManagementCard: View {
    let title: String
    let description: String
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
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(radius: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct InterventionCard: View {
    let intervention: WellnessIntervention
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(intervention.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text("\(Int(intervention.confidence * 100))%")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                }
                
                Text(intervention.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack {
                    Text(intervention.type.rawValue.capitalized)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.2))
                        .foregroundColor(.blue)
                        .cornerRadius(8)
                    
                    Spacer()
                    
                    Text("\(Int(intervention.duration / 60)) min")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct WellnessToolCard: View {
    let title: String
    let description: String
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
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(radius: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct CrisisResourceCard: View {
    let title: String
    let description: String
    let phone: String
    let icon: String
    let color: Color
    
    var body: some View {
        Button(action: {
            // Call the number
        }) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                VStack(alignment: .leading) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text(phone)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(color)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SafetyPlanCard: View {
    let title: String
    let description: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            VStack(alignment: .leading) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Sheet Views

struct MoodEntryView: View {
    @ObservedObject var wellnessEngine: MentalHealthWellnessEngine
    @Environment(\.dismiss) private var dismiss
    @State private var selectedMood: MoodType = .neutral
    @State private var moodScore: Double = 0.5
    @State private var notes = ""
    @State private var selectedFactors: Set<MoodFactor> = []
    
    var body: some View {
        NavigationView {
            Form {
                Section("How are you feeling?") {
                    Picker("Mood", selection: $selectedMood) {
                        ForEach(MoodType.allCases, id: \.self) { mood in
                            Text(mood.displayName).tag(mood)
                        }
                    }
                    .pickerStyle(WheelPickerStyle())
                    
                    VStack(alignment: .leading) {
                        Text("Mood Level: \(Int(moodScore * 100))%")
                            .font(.subheadline)
                            .foregroundColor(.primary)
                        
                        Slider(value: $moodScore, in: 0...1, step: 0.1)
                    }
                }
                
                Section("What's affecting your mood?") {
                    ForEach(MoodFactor.allCases, id: \.self) { factor in
                        Toggle(factor.rawValue.capitalized, isOn: Binding(
                            get: { selectedFactors.contains(factor) },
                            set: { isSelected in
                                if isSelected {
                                    selectedFactors.insert(factor)
                                } else {
                                    selectedFactors.remove(factor)
                                }
                            }
                        ))
                    }
                }
                
                Section("Notes (Optional)") {
                    TextField("Add notes about your mood", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Record Mood")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveMoodEntry()
                    }
                }
            }
        }
    }
    
    private func saveMoodEntry() {
        let entry = MoodEntry(
            id: UUID().uuidString,
            moodScore: moodScore,
            moodType: selectedMood,
            notes: notes.isEmpty ? nil : notes,
            timestamp: Date(),
            factors: Array(selectedFactors)
        )
        
        Task {
            do {
                try await wellnessEngine.recordMoodEntry(entry)
                await MainActor.run {
                    dismiss()
                }
            } catch {
                // Handle error
            }
        }
    }
}

struct StressEntryView: View {
    @ObservedObject var wellnessEngine: MentalHealthWellnessEngine
    @Environment(\.dismiss) private var dismiss
    @State private var selectedStressType: StressType = .personal
    @State private var stressLevel: Double = 0.5
    @State private var notes = ""
    @State private var selectedTriggers: Set<StressTrigger> = []
    
    var body: some View {
        NavigationView {
            Form {
                Section("Stress Level") {
                    Picker("Stress Type", selection: $selectedStressType) {
                        ForEach(StressType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    .pickerStyle(WheelPickerStyle())
                    
                    VStack(alignment: .leading) {
                        Text("Stress Level: \(Int(stressLevel * 100))%")
                            .font(.subheadline)
                            .foregroundColor(.primary)
                        
                        Slider(value: $stressLevel, in: 0...1, step: 0.1)
                    }
                }
                
                Section("Stress Triggers") {
                    ForEach(StressTrigger.allCases, id: \.self) { trigger in
                        Toggle(trigger.rawValue.capitalized, isOn: Binding(
                            get: { selectedTriggers.contains(trigger) },
                            set: { isSelected in
                                if isSelected {
                                    selectedTriggers.insert(trigger)
                                } else {
                                    selectedTriggers.remove(trigger)
                                }
                            }
                        ))
                    }
                }
                
                Section("Notes (Optional)") {
                    TextField("Add notes about your stress", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Track Stress")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveStressEntry()
                    }
                }
            }
        }
    }
    
    private func saveStressEntry() {
        let stressLevel = StressLevel(
            id: UUID().uuidString,
            stressLevel: stressLevel,
            stressType: selectedStressType,
            notes: notes.isEmpty ? nil : notes,
            timestamp: Date(),
            triggers: Array(selectedTriggers)
        )
        
        Task {
            do {
                try await wellnessEngine.recordStressLevel(stressLevel)
                await MainActor.run {
                    dismiss()
                }
            } catch {
                // Handle error
            }
        }
    }
}

struct CrisisSupportView: View {
    @ObservedObject var wellnessEngine: MentalHealthWellnessEngine
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 16) {
                    Text("Crisis Support")
                        .font(.title)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                }
            }
            .navigationTitle("Crisis Support")
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

struct InterventionView: View {
    @ObservedObject var wellnessEngine: MentalHealthWellnessEngine
    let intervention: WellnessIntervention
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 16) {
                    Text("Intervention: \(intervention.title)")
                        .font(.title)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                }
            }
            .navigationTitle("Intervention")
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

// MARK: - Preview

struct MentalHealthWellnessView_Previews: PreviewProvider {
    static var previews: some View {
        MentalHealthWellnessView(
            healthDataManager: HealthDataManager(),
            mlModelManager: MLModelManager(),
            notificationManager: NotificationManager(),
            crisisInterventionManager: CrisisInterventionManager()
        )
    }
} 
import SwiftUI

@available(iOS 17.0, *)
public struct HealthDashboardView: View {
    @StateObject private var healthManager = HealthDataManager.shared
    @StateObject private var performanceMonitor = HealthAIPerformance.PerformanceMonitor()
    @State private var selectedTab = 0
    @State private var showingDetail = false
    @State private var focusedItem: String?
    
    public var body: some View {
        NavigationStack {
            VStack(spacing: HealthAIDesignSystem.Spacing.lg) {
                // Header
                dashboardHeader
                
                // Main Content
                TabView(selection: $selectedTab) {
                    overviewTab
                        .tag(0)
                    
                    healthMetricsTab
                        .tag(1)
                    
                    activityTab
                        .tag(2)
                    
                    sleepTab
                        .tag(3)
                    
                    settingsTab
                        .tag(4)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
                .animation(HealthAIAnimations.Presets.spring, value: selectedTab)
            }
            .background(HealthAIDesignSystem.Colors.background)
            .navigationTitle("HealthAI")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    performanceIndicator
                }
            }
        }
        .healthAIAccessibility(
            label: "HealthAI Dashboard",
            hint: "Main health monitoring interface",
            traits: .isHeader
        )
        .onAppear {
            healthManager.startMonitoring()
        }
        .onDisappear {
            healthManager.stopMonitoring()
        }
    }
    
    // MARK: - Dashboard Header
    private var dashboardHeader: some View {
        VStack(spacing: HealthAIDesignSystem.Spacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: HealthAIDesignSystem.Spacing.xs) {
                    Text("Welcome back")
                        .font(HealthAIDesignSystem.Typography.body)
                        .foregroundColor(HealthAIDesignSystem.Colors.textSecondary)
                    
                    Text("Your Health Summary")
                        .font(HealthAIDesignSystem.Typography.title1)
                        .fontWeight(.bold)
                        .foregroundColor(HealthAIDesignSystem.Colors.textPrimary)
                }
                
                Spacer()
                
                // Quick Actions
                HStack(spacing: HealthAIDesignSystem.Spacing.sm) {
                    HealthAIButton(
                        title: "Add",
                        style: .primary,
                        icon: "plus"
                    ) {
                        showingDetail = true
                    }
                    .healthAIMinimumTouchTarget()
                    .healthAIAccessibility(
                        label: "Add health data",
                        hint: "Add new health measurement or activity"
                    )
                    
                    HealthAIButton(
                        title: "Sync",
                        style: .secondary,
                        icon: "arrow.clockwise"
                    ) {
                        healthManager.syncData()
                    }
                    .healthAIMinimumTouchTarget()
                    .healthAIAccessibility(
                        label: "Sync health data",
                        hint: "Synchronize with health services"
                    )
                }
            }
            
            // Health Status Overview
            healthStatusOverview
        }
        .padding(HealthAIDesignSystem.Spacing.lg)
        .background(HealthAIDesignSystem.Colors.card)
        .cornerRadius(HealthAIDesignSystem.Layout.cornerRadius)
        .healthAICardHover()
    }
    
    // MARK: - Health Status Overview
    private var healthStatusOverview: some View {
        HStack(spacing: HealthAIDesignSystem.Spacing.lg) {
            // Overall Health Score
            VStack(spacing: HealthAIDesignSystem.Spacing.xs) {
                Text("\(Int(healthManager.overallHealthScore * 100))")
                    .font(HealthAIDesignSystem.Typography.metricValue)
                    .fontWeight(.bold)
                    .foregroundColor(healthScoreColor)
                
                Text("Health Score")
                    .font(HealthAIDesignSystem.Typography.caption1)
                    .foregroundColor(HealthAIDesignSystem.Colors.textSecondary)
            }
            .healthAIAccessibility(
                label: "Overall health score: \(Int(healthManager.overallHealthScore * 100)) percent",
                value: "\(Int(healthManager.overallHealthScore * 100))%"
            )
            
            Divider()
                .frame(height: 40)
            
            // Today's Activity
            VStack(spacing: HealthAIDesignSystem.Spacing.xs) {
                Text("\(healthManager.todaysSteps)")
                    .font(HealthAIDesignSystem.Typography.title2)
                    .fontWeight(.bold)
                    .foregroundColor(HealthAIDesignSystem.Colors.primary)
                
                Text("Steps Today")
                    .font(HealthAIDesignSystem.Typography.caption1)
                    .foregroundColor(HealthAIDesignSystem.Colors.textSecondary)
            }
            .healthAIAccessibility(
                label: "Steps today: \(healthManager.todaysSteps)",
                value: "\(healthManager.todaysSteps) steps"
            )
            
            Divider()
                .frame(height: 40)
            
            // Sleep Quality
            VStack(spacing: HealthAIDesignSystem.Spacing.xs) {
                Text("\(Int(healthManager.sleepQuality * 100))%")
                    .font(HealthAIDesignSystem.Typography.title2)
                    .fontWeight(.bold)
                    .foregroundColor(HealthAIDesignSystem.Colors.sleep)
                
                Text("Sleep Quality")
                    .font(HealthAIDesignSystem.Typography.caption1)
                    .foregroundColor(HealthAIDesignSystem.Colors.textSecondary)
            }
            .healthAIAccessibility(
                label: "Sleep quality: \(Int(healthManager.sleepQuality * 100)) percent",
                value: "\(Int(healthManager.sleepQuality * 100))%"
            )
        }
    }
    
    // MARK: - Overview Tab
    private var overviewTab: some View {
        ScrollView {
            LazyVStack(spacing: HealthAIDesignSystem.Spacing.lg) {
                // Quick Metrics Grid
                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible(), spacing: HealthAIDesignSystem.Spacing.md), count: 2),
                    spacing: HealthAIDesignSystem.Spacing.md
                ) {
                    ForEach(Array(healthManager.quickMetrics.enumerated()), id: \.offset) { index, metric in
                        HealthMetricCard(
                            title: metric.title,
                            value: metric.value,
                            unit: metric.unit,
                            color: metric.color,
                            icon: metric.icon,
                            trend: metric.trend,
                            status: metric.status,
                            subtitle: metric.subtitle
                        )
                        .healthAIListItemAnimation(index: index)
                        .healthAIMinimumTouchTarget()
                        .onTapGesture {
                            focusedItem = metric.id
                            showingDetail = true
                        }
                    }
                }
                
                // Health Insights
                healthInsightsSection
                
                // Recent Activities
                recentActivitiesSection
            }
            .padding(HealthAIDesignSystem.Spacing.lg)
        }
        .healthAIAccessibility(
            label: "Overview tab",
            hint: "Main health overview and quick metrics"
        )
    }
    
    // MARK: - Health Metrics Tab
    private var healthMetricsTab: some View {
        ScrollView {
            LazyVStack(spacing: HealthAIDesignSystem.Spacing.lg) {
                // Heart Rate Section
                healthMetricSection(
                    title: "Heart Rate",
                    icon: "heart.fill",
                    color: HealthAIDesignSystem.Colors.heartRate,
                    metrics: healthManager.heartRateMetrics
                )
                
                // Blood Pressure Section
                healthMetricSection(
                    title: "Blood Pressure",
                    icon: "drop.fill",
                    color: HealthAIDesignSystem.Colors.bloodPressure,
                    metrics: healthManager.bloodPressureMetrics
                )
                
                // Other Metrics
                healthMetricSection(
                    title: "Other Metrics",
                    icon: "chart.bar.fill",
                    color: HealthAIDesignSystem.Colors.primary,
                    metrics: healthManager.otherMetrics
                )
            }
            .padding(HealthAIDesignSystem.Spacing.lg)
        }
        .healthAIAccessibility(
            label: "Health metrics tab",
            hint: "Detailed health measurements and trends"
        )
    }
    
    // MARK: - Activity Tab
    private var activityTab: some View {
        ScrollView {
            LazyVStack(spacing: HealthAIDesignSystem.Spacing.lg) {
                // Activity Rings
                activityRingsSection
                
                // Workouts
                workoutsSection
                
                // Goals Progress
                goalsProgressSection
            }
            .padding(HealthAIDesignSystem.Spacing.lg)
        }
        .healthAIAccessibility(
            label: "Activity tab",
            hint: "Physical activity tracking and goals"
        )
    }
    
    // MARK: - Sleep Tab
    private var sleepTab: some View {
        ScrollView {
            LazyVStack(spacing: HealthAIDesignSystem.Spacing.lg) {
                // Sleep Summary
                sleepSummarySection
                
                // Sleep Stages
                sleepStagesSection
                
                // Sleep Trends
                sleepTrendsSection
            }
            .padding(HealthAIDesignSystem.Spacing.lg)
        }
        .healthAIAccessibility(
            label: "Sleep tab",
            hint: "Sleep tracking and analysis"
        )
    }
    
    // MARK: - Settings Tab
    private var settingsTab: some View {
        ScrollView {
            LazyVStack(spacing: HealthAIDesignSystem.Spacing.lg) {
                // Profile Settings
                profileSettingsSection
                
                // Privacy Settings
                privacySettingsSection
                
                // Notification Settings
                notificationSettingsSection
                
                // Performance Settings
                performanceSettingsSection
            }
            .padding(HealthAIDesignSystem.Spacing.lg)
        }
        .healthAIAccessibility(
            label: "Settings tab",
            hint: "App settings and preferences"
        )
    }
    
    // MARK: - Supporting Views
    private var performanceIndicator: some View {
        HStack(spacing: HealthAIDesignSystem.Spacing.xs) {
            Circle()
                .fill(performanceMonitor.isPerformanceOptimal ? HealthAIDesignSystem.Colors.success : HealthAIDesignSystem.Colors.warning)
                .frame(width: 8, height: 8)
                .healthAIHeartbeat()
            
            Text("\(Int(performanceMonitor.currentFPS))")
                .font(HealthAIDesignSystem.Typography.caption1)
                .foregroundColor(HealthAIDesignSystem.Colors.textSecondary)
        }
        .healthAIAccessibility(
            label: "Performance indicator",
            value: "\(Int(performanceMonitor.currentFPS)) FPS"
        )
    }
    
    private var healthScoreColor: Color {
        let score = healthManager.overallHealthScore
        switch score {
        case 0.8...: return HealthAIDesignSystem.Colors.success
        case 0.6..<0.8: return HealthAIDesignSystem.Colors.warning
        default: return HealthAIDesignSystem.Colors.error
        }
    }
    
    // MARK: - Section Views (Placeholders)
    private func healthInsightsSection() -> some View {
        HealthAICard(style: .elevated) {
            VStack(alignment: .leading, spacing: HealthAIDesignSystem.Spacing.md) {
                Text("Health Insights")
                    .font(HealthAIDesignSystem.Typography.title2)
                    .fontWeight(.bold)
                
                Text("Your heart rate has been consistently healthy this week.")
                    .font(HealthAIDesignSystem.Typography.body)
                    .foregroundColor(HealthAIDesignSystem.Colors.textSecondary)
            }
        }
        .healthAIAccessibility(
            label: "Health insights",
            hint: "AI-generated health recommendations"
        )
    }
    
    private func recentActivitiesSection() -> some View {
        HealthAICard(style: .elevated) {
            VStack(alignment: .leading, spacing: HealthAIDesignSystem.Spacing.md) {
                Text("Recent Activities")
                    .font(HealthAIDesignSystem.Typography.title2)
                    .fontWeight(.bold)
                
                ForEach(healthManager.recentActivities, id: \.id) { activity in
                    HStack {
                        Image(systemName: activity.icon)
                            .foregroundColor(activity.color)
                        
                        Text(activity.title)
                            .font(HealthAIDesignSystem.Typography.body)
                        
                        Spacer()
                        
                        Text(activity.timeAgo)
                            .font(HealthAIDesignSystem.Typography.caption1)
                            .foregroundColor(HealthAIDesignSystem.Colors.textSecondary)
                    }
                }
            }
        }
        .healthAIAccessibility(
            label: "Recent activities",
            hint: "List of recent health activities"
        )
    }
    
    private func healthMetricSection(title: String, icon: String, color: Color, metrics: [HealthMetric]) -> some View {
        HealthAICard(style: .elevated) {
            VStack(alignment: .leading, spacing: HealthAIDesignSystem.Spacing.md) {
                HStack {
                    Image(systemName: icon)
                        .foregroundColor(color)
                        .font(.title2)
                    
                    Text(title)
                        .font(HealthAIDesignSystem.Typography.title2)
                        .fontWeight(.bold)
                    
                    Spacer()
                }
                
                ForEach(metrics, id: \.id) { metric in
                    HealthMetricCard(
                        title: metric.title,
                        value: metric.value,
                        unit: metric.unit,
                        color: metric.color,
                        icon: metric.icon,
                        trend: metric.trend,
                        status: metric.status,
                        subtitle: metric.subtitle
                    )
                }
            }
        }
        .healthAIAccessibility(
            label: title,
            hint: "\(title) measurements and trends"
        )
    }
    
    private func activityRingsSection() -> some View {
        HealthAICard(style: .elevated) {
            VStack(alignment: .leading, spacing: HealthAIDesignSystem.Spacing.md) {
                Text("Activity Rings")
                    .font(HealthAIDesignSystem.Typography.title2)
                    .fontWeight(.bold)
                
                HStack {
                    // Activity rings visualization would go here
                    Text("Activity rings visualization")
                        .font(HealthAIDesignSystem.Typography.body)
                        .foregroundColor(HealthAIDesignSystem.Colors.textSecondary)
                    
                    Spacer()
                }
            }
        }
        .healthAIAccessibility(
            label: "Activity rings",
            hint: "Daily activity progress visualization"
        )
    }
    
    private func workoutsSection() -> some View {
        HealthAICard(style: .elevated) {
            VStack(alignment: .leading, spacing: HealthAIDesignSystem.Spacing.md) {
                Text("Recent Workouts")
                    .font(HealthAIDesignSystem.Typography.title2)
                    .fontWeight(.bold)
                
                ForEach(healthManager.recentWorkouts, id: \.id) { workout in
                    HStack {
                        Image(systemName: workout.icon)
                            .foregroundColor(workout.color)
                        
                        VStack(alignment: .leading) {
                            Text(workout.title)
                                .font(HealthAIDesignSystem.Typography.body)
                                .fontWeight(.medium)
                            
                            Text(workout.duration)
                                .font(HealthAIDesignSystem.Typography.caption1)
                                .foregroundColor(HealthAIDesignSystem.Colors.textSecondary)
                        }
                        
                        Spacer()
                        
                        Text(workout.calories)
                            .font(HealthAIDesignSystem.Typography.body)
                            .fontWeight(.medium)
                    }
                }
            }
        }
        .healthAIAccessibility(
            label: "Recent workouts",
            hint: "List of recent workout sessions"
        )
    }
    
    private func goalsProgressSection() -> some View {
        HealthAICard(style: .elevated) {
            VStack(alignment: .leading, spacing: HealthAIDesignSystem.Spacing.md) {
                Text("Goals Progress")
                    .font(HealthAIDesignSystem.Typography.title2)
                    .fontWeight(.bold)
                
                ForEach(healthManager.goals, id: \.id) { goal in
                    VStack(alignment: .leading, spacing: HealthAIDesignSystem.Spacing.xs) {
                        HStack {
                            Text(goal.title)
                                .font(HealthAIDesignSystem.Typography.body)
                                .fontWeight(.medium)
                            
                            Spacer()
                            
                            Text("\(Int(goal.progress * 100))%")
                                .font(HealthAIDesignSystem.Typography.body)
                                .fontWeight(.medium)
                        }
                        
                        HealthAIProgressView(
                            value: Float(goal.progress),
                            color: goal.color,
                            label: goal.title
                        )
                    }
                }
            }
        }
        .healthAIAccessibility(
            label: "Goals progress",
            hint: "Progress towards health goals"
        )
    }
    
    private func sleepSummarySection() -> some View {
        HealthAICard(style: .elevated) {
            VStack(alignment: .leading, spacing: HealthAIDesignSystem.Spacing.md) {
                Text("Sleep Summary")
                    .font(HealthAIDesignSystem.Typography.title2)
                    .fontWeight(.bold)
                
                HStack {
                    VStack(alignment: .leading) {
                        Text("\(healthManager.sleepDuration, specifier: "%.1f")h")
                            .font(HealthAIDesignSystem.Typography.title1)
                            .fontWeight(.bold)
                            .foregroundColor(HealthAIDesignSystem.Colors.sleep)
                        
                        Text("Last Night")
                            .font(HealthAIDesignSystem.Typography.caption1)
                            .foregroundColor(HealthAIDesignSystem.Colors.textSecondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        Text("\(Int(healthManager.sleepQuality * 100))%")
                            .font(HealthAIDesignSystem.Typography.title2)
                            .fontWeight(.bold)
                            .foregroundColor(HealthAIDesignSystem.Colors.primary)
                        
                        Text("Quality")
                            .font(HealthAIDesignSystem.Typography.caption1)
                            .foregroundColor(HealthAIDesignSystem.Colors.textSecondary)
                    }
                }
            }
        }
        .healthAIAccessibility(
            label: "Sleep summary",
            value: "\(healthManager.sleepDuration, specifier: "%.1f") hours, \(Int(healthManager.sleepQuality * 100))% quality"
        )
    }
    
    private func sleepStagesSection() -> some View {
        HealthAICard(style: .elevated) {
            VStack(alignment: .leading, spacing: HealthAIDesignSystem.Spacing.md) {
                Text("Sleep Stages")
                    .font(HealthAIDesignSystem.Typography.title2)
                    .fontWeight(.bold)
                
                Text("Sleep stages visualization would go here")
                    .font(HealthAIDesignSystem.Typography.body)
                    .foregroundColor(HealthAIDesignSystem.Colors.textSecondary)
            }
        }
        .healthAIAccessibility(
            label: "Sleep stages",
            hint: "Detailed sleep stage analysis"
        )
    }
    
    private func sleepTrendsSection() -> some View {
        HealthAICard(style: .elevated) {
            VStack(alignment: .leading, spacing: HealthAIDesignSystem.Spacing.md) {
                Text("Sleep Trends")
                    .font(HealthAIDesignSystem.Typography.title2)
                    .fontWeight(.bold)
                
                Text("Sleep trends chart would go here")
                    .font(HealthAIDesignSystem.Typography.body)
                    .foregroundColor(HealthAIDesignSystem.Colors.textSecondary)
            }
        }
        .healthAIAccessibility(
            label: "Sleep trends",
            hint: "Weekly sleep pattern analysis"
        )
    }
    
    private func profileSettingsSection() -> some View {
        HealthAICard(style: .elevated) {
            VStack(alignment: .leading, spacing: HealthAIDesignSystem.Spacing.md) {
                Text("Profile Settings")
                    .font(HealthAIDesignSystem.Typography.title2)
                    .fontWeight(.bold)
                
                Text("Profile settings would go here")
                    .font(HealthAIDesignSystem.Typography.body)
                    .foregroundColor(HealthAIDesignSystem.Colors.textSecondary)
            }
        }
        .healthAIAccessibility(
            label: "Profile settings",
            hint: "Personal profile and account settings"
        )
    }
    
    private func privacySettingsSection() -> some View {
        HealthAICard(style: .elevated) {
            VStack(alignment: .leading, spacing: HealthAIDesignSystem.Spacing.md) {
                Text("Privacy Settings")
                    .font(HealthAIDesignSystem.Typography.title2)
                    .fontWeight(.bold)
                
                Text("Privacy settings would go here")
                    .font(HealthAIDesignSystem.Typography.body)
                    .foregroundColor(HealthAIDesignSystem.Colors.textSecondary)
            }
        }
        .healthAIAccessibility(
            label: "Privacy settings",
            hint: "Data privacy and security settings"
        )
    }
    
    private func notificationSettingsSection() -> some View {
        HealthAICard(style: .elevated) {
            VStack(alignment: .leading, spacing: HealthAIDesignSystem.Spacing.md) {
                Text("Notification Settings")
                    .font(HealthAIDesignSystem.Typography.title2)
                    .fontWeight(.bold)
                
                Text("Notification settings would go here")
                    .font(HealthAIDesignSystem.Typography.body)
                    .foregroundColor(HealthAIDesignSystem.Colors.textSecondary)
            }
        }
        .healthAIAccessibility(
            label: "Notification settings",
            hint: "App notification preferences"
        )
    }
    
    private func performanceSettingsSection() -> some View {
        HealthAICard(style: .elevated) {
            VStack(alignment: .leading, spacing: HealthAIDesignSystem.Spacing.md) {
                Text("Performance Settings")
                    .font(HealthAIDesignSystem.Typography.title2)
                    .fontWeight(.bold)
                
                VStack(alignment: .leading, spacing: HealthAIDesignSystem.Spacing.sm) {
                    Text("Current FPS: \(Int(performanceMonitor.currentFPS))")
                        .font(HealthAIDesignSystem.Typography.body)
                    
                    Text("Memory Usage: \(Int(performanceMonitor.memoryUsage * 100))%")
                        .font(HealthAIDesignSystem.Typography.body)
                    
                    Text("Performance: \(performanceMonitor.isPerformanceOptimal ? "Optimal" : "Suboptimal")")
                        .font(HealthAIDesignSystem.Typography.body)
                        .foregroundColor(performanceMonitor.isPerformanceOptimal ? HealthAIDesignSystem.Colors.success : HealthAIDesignSystem.Colors.warning)
                }
            }
        }
        .healthAIAccessibility(
            label: "Performance settings",
            value: "FPS: \(Int(performanceMonitor.currentFPS)), Memory: \(Int(performanceMonitor.memoryUsage * 100))%"
        )
    }
}

// MARK: - Supporting Types
struct HealthMetric {
    let id: String
    let title: String
    let value: String
    let unit: String
    let color: Color
    let icon: String
    let trend: String?
    let status: HealthStatus
    let subtitle: String?
}

struct HealthActivity {
    let id: String
    let title: String
    let icon: String
    let color: Color
    let timeAgo: String
}

struct Workout {
    let id: String
    let title: String
    let icon: String
    let color: Color
    let duration: String
    let calories: String
}

struct Goal {
    let id: String
    let title: String
    let progress: Double
    let color: Color
}

// MARK: - Health Data Manager
class HealthDataManager: ObservableObject {
    static let shared = HealthDataManager()
    
    @Published var overallHealthScore: Double = 0.85
    @Published var todaysSteps: Int = 8432
    @Published var sleepQuality: Double = 0.87
    @Published var sleepDuration: Double = 7.5
    
    @Published var quickMetrics: [HealthMetric] = []
    @Published var heartRateMetrics: [HealthMetric] = []
    @Published var bloodPressureMetrics: [HealthMetric] = []
    @Published var otherMetrics: [HealthMetric] = []
    @Published var recentActivities: [HealthActivity] = []
    @Published var recentWorkouts: [Workout] = []
    @Published var goals: [Goal] = []
    
    private init() {
        setupSampleData()
    }
    
    func startMonitoring() {
        // Start health monitoring
    }
    
    func stopMonitoring() {
        // Stop health monitoring
    }
    
    func syncData() {
        // Sync health data
        HealthAIAnimations.HapticManager.shared.success()
    }
    
    private func setupSampleData() {
        quickMetrics = [
            HealthMetric(id: "hr", title: "Heart Rate", value: "72", unit: "BPM", color: HealthAIDesignSystem.Colors.heartRate, icon: "heart.fill", trend: "+2", status: .healthy, subtitle: "Resting"),
            HealthMetric(id: "bp", title: "Blood Pressure", value: "120/80", unit: "mmHg", color: HealthAIDesignSystem.Colors.bloodPressure, icon: "drop.fill", trend: nil, status: .healthy, subtitle: "Normal"),
            HealthMetric(id: "temp", title: "Temperature", value: "98.6", unit: "°F", color: HealthAIDesignSystem.Colors.temperature, icon: "thermometer", trend: nil, status: .healthy, subtitle: "Normal"),
            HealthMetric(id: "o2", title: "Oxygen", value: "98", unit: "%", color: HealthAIDesignSystem.Colors.respiratory, icon: "lungs.fill", trend: nil, status: .healthy, subtitle: "SpO2")
        ]
        
        heartRateMetrics = [
            HealthMetric(id: "hr_rest", title: "Resting HR", value: "58", unit: "BPM", color: HealthAIDesignSystem.Colors.heartRate, icon: "heart.fill", trend: "-3", status: .healthy, subtitle: "Last week avg"),
            HealthMetric(id: "hr_active", title: "Active HR", value: "85", unit: "BPM", color: HealthAIDesignSystem.Colors.heartRate, icon: "heart.fill", trend: "+5", status: .elevated, subtitle: "During exercise")
        ]
        
        bloodPressureMetrics = [
            HealthMetric(id: "bp_systolic", title: "Systolic", value: "120", unit: "mmHg", color: HealthAIDesignSystem.Colors.bloodPressure, icon: "drop.fill", trend: nil, status: .healthy, subtitle: "Normal range"),
            HealthMetric(id: "bp_diastolic", title: "Diastolic", value: "80", unit: "mmHg", color: HealthAIDesignSystem.Colors.bloodPressure, icon: "drop.fill", trend: nil, status: .healthy, subtitle: "Normal range")
        ]
        
        otherMetrics = [
            HealthMetric(id: "weight", title: "Weight", value: "165", unit: "lbs", color: HealthAIDesignSystem.Colors.weight, icon: "scalemass", trend: "-1", status: .healthy, subtitle: "This week"),
            HealthMetric(id: "glucose", title: "Glucose", value: "95", unit: "mg/dL", color: HealthAIDesignSystem.Colors.glucose, icon: "drop.fill", trend: nil, status: .healthy, subtitle: "Fasting")
        ]
        
        recentActivities = [
            HealthActivity(id: "1", title: "Morning Walk", icon: "figure.walk", color: HealthAIDesignSystem.Colors.activity, timeAgo: "2 hours ago"),
            HealthActivity(id: "2", title: "Water Intake", icon: "drop.fill", color: HealthAIDesignSystem.Colors.nutrition, timeAgo: "1 hour ago"),
            HealthActivity(id: "3", title: "Heart Rate Check", icon: "heart.fill", color: HealthAIDesignSystem.Colors.heartRate, timeAgo: "30 min ago")
        ]
        
        recentWorkouts = [
            Workout(id: "1", title: "Morning Run", icon: "figure.run", color: HealthAIDesignSystem.Colors.activity, duration: "45 min", calories: "320 cal"),
            Workout(id: "2", title: "Strength Training", icon: "dumbbell.fill", color: HealthAIDesignSystem.Colors.activity, duration: "30 min", calories: "180 cal"),
            Workout(id: "3", title: "Yoga", icon: "figure.mind.and.body", color: HealthAIDesignSystem.Colors.mentalHealth, duration: "20 min", calories: "80 cal")
        ]
        
        goals = [
            Goal(id: "1", title: "Daily Steps", progress: 0.84, color: HealthAIDesignSystem.Colors.activity),
            Goal(id: "2", title: "Sleep Goal", progress: 0.75, color: HealthAIDesignSystem.Colors.sleep),
            Goal(id: "3", title: "Water Intake", progress: 0.60, color: HealthAIDesignSystem.Colors.nutrition)
        ]
    }
} 
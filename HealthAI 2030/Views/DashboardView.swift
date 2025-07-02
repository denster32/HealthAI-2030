import SwiftUI
import Charts

struct DashboardView: View {
    @StateObject private var healthDataManager = HealthDataManager.shared
    @StateObject private var predictiveAnalytics = PredictiveAnalyticsManager.shared
    @StateObject private var sleepOptimizationManager = SleepOptimizationManager.shared
    @StateObject private var environmentManager = EnvironmentManager.shared
    @StateObject private var realTimeSyncManager = RealTimeSyncManager.shared
    @StateObject private var appleWatchManager = AppleWatchManager.shared
    @StateObject private var liveActivityManager = LiveActivityManager.shared
    
    @State private var showingHealthAlerts = false
    @State private var showingSyncStatus = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 20) {
                    WhatsNewCard()
                    // Health Status Overview
                    HealthStatusCard()
                    
                    // Quick Actions
                    QuickActionsCard()
                    
                    // Today's Health Metrics
                    TodaysMetricsCard()
                    
                    // Sleep Summary
                    SleepSummaryCard()
                    
                    // Environment Status
                    EnvironmentStatusCard()
                    
                    // Predictive Insights
                    PredictiveInsightsCard()
                    
                    // Health Alerts
                    HealthAlertsCard()
                    
                    // Recent Activity
                    RecentActivityCard()
                    
                    // Apple Watch Sync Status
                    WatchSyncStatusCard()
                    
                    // Live Activity Dashboard
                    LiveActivityDashboardCard()
                }
                .padding()
            }
            .navigationTitle("Dashboard")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        showingSyncStatus = true
                    }) {
                        Image(systemName: syncStatusIcon)
                            .foregroundColor(syncStatusColor)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        refreshAllData()
                    }) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .sheet(isPresented: $showingHealthAlerts) {
                HealthAlertsDetailView()
            }
            .sheet(isPresented: $showingSyncStatus) {
                SyncStatusDetailView()
            }
        }
    }
    
    private func refreshAllData() {
        healthDataManager.refreshHealthData()
        predictiveAnalytics.refreshPredictions()
        realTimeSyncManager.performManualSync()
        
        // Add haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
    
    private var syncStatusIcon: String {
        switch realTimeSyncManager.syncStatus {
        case .idle:
            return appleWatchManager.isWatchAvailable() ? "applewatch" : "applewatch.slash"
        case .syncing:
            return "arrow.clockwise"
        case .completed:
            return "checkmark.circle"
        case .error:
            return "exclamationmark.triangle"
        }
    }
    
    private var syncStatusColor: Color {
        switch realTimeSyncManager.syncStatus {
        case .idle:
            return appleWatchManager.isWatchAvailable() ? .green : .gray
        case .syncing:
            return .blue
        case .completed:
            return .green
        case .error:
            return .red
        }
    }
}

// MARK: - Dashboard Cards

struct HealthStatusCard: View {
    @ObservedObject private var healthDataManager = HealthDataManager.shared
    @ObservedObject private var sleepOptimizationManager = SleepOptimizationManager.shared
    
    var body: some View {
        DashboardCard(title: "Health Status", icon: "heart.fill", color: .red) {
            VStack(spacing: 16) {
                HStack {
                    HealthMetricDisplay(
                        title: "Heart Rate",
                        value: "\(Int(healthDataManager.currentHeartRate))",
                        unit: "BPM",
                        color: heartRateColor
                    )
                    
                    Spacer()
                    
                    HealthMetricDisplay(
                        title: "HRV",
                        value: "\(Int(healthDataManager.currentHRV))",
                        unit: "ms",
                        color: hrvColor
                    )
                }
                
                HStack {
                    HealthMetricDisplay(
                        title: "Sleep Quality",
                        value: "\(Int(sleepOptimizationManager.sleepQuality * 100))",
                        unit: "%",
                        color: sleepQualityColor
                    )
                    
                    Spacer()
                    
                    HealthMetricDisplay(
                        title: "Deep Sleep",
                        value: "\(Int(sleepOptimizationManager.deepSleepPercentage * 100))",
                        unit: "%",
                        color: .blue
                    )
                }
            }
        }
    }
    
    private var heartRateColor: Color {
        let hr = healthDataManager.currentHeartRate
        if hr > 100 { return .red }
        if hr < 60 { return .orange }
        return .green
    }
    
    private var hrvColor: Color {
        let hrv = healthDataManager.currentHRV
        if hrv > 50 { return .green }
        if hrv > 30 { return .yellow }
        return .red
    }
    
    private var sleepQualityColor: Color {
        let quality = sleepOptimizationManager.sleepQuality
        if quality > 0.8 { return .green }
        if quality > 0.6 { return .yellow }
        return .red
    }
}

struct QuickActionsCard: View {
    @ObservedObject private var sleepOptimizationManager = SleepOptimizationManager.shared
    @ObservedObject private var environmentManager = EnvironmentManager.shared
    @State private var showingMoodModal = false
    @State private var showingBreathingModal = false
    @State private var showingMentalStateModal = false
    @State private var showingMeditationModal = false
    @State private var showingHealthCheckModal = false
    
    var body: some View {
        DashboardCard(title: "Quick Actions", icon: "bolt.fill", color: .blue) {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                QuickActionButton(
                    title: "Sleep Mode",
                    icon: "bed.double.fill",
                    isActive: sleepOptimizationManager.isOptimizationActive
                ) {
                    withAnimation(.spring()) {
                        if sleepOptimizationManager.isOptimizationActive {
                            sleepOptimizationManager.stopOptimization()
                        } else {
                            sleepOptimizationManager.startOptimization()
                        }
                    }
                    HapticManager.shared.impact(.medium)
                }
                
                QuickActionButton(
                    title: "Environment",
                    icon: "house.fill",
                    isActive: environmentManager.isOptimizationActive
                ) {
                    withAnimation(.spring()) {
                        if environmentManager.isOptimizationActive {
                            environmentManager.stopOptimization()
                        } else {
                            environmentManager.optimizeForSleep()
                        }
                    }
                    HapticManager.shared.impact(.medium)
                }
                
                QuickActionButton(
                    title: "Meditate",
                    icon: "brain.head.profile",
                    isActive: false
                ) {
                    showingMeditationModal = true
                    HapticManager.shared.impact(.light)
                }
                
                QuickActionButton(
                    title: "Sync Data",
                    icon: "arrow.clockwise",
                    isActive: false
                ) {
                    Task {
                        await HealthDataManager.shared.refreshHealthData()
                    }
                    HapticManager.shared.impact(.light)
                }
                
                QuickActionButton(
                    title: "Log Mood",
                    icon: "face.smiling",
                    isActive: false
                ) {
                    showingMoodModal = true
                    HapticManager.shared.impact(.light)
                }
                
                QuickActionButton(
                    title: "Breathing Exercise",
                    icon: "lungs.fill",
                    isActive: false
                ) {
                    showingBreathingModal = true
                    HapticManager.shared.impact(.light)
                }
                
                QuickActionButton(
                    title: "Mental State",
                    icon: "brain",
                    isActive: false
                ) {
                    showingMentalStateModal = true
                    HapticManager.shared.impact(.light)
                }
                
                QuickActionButton(
                    title: "Health Check",
                    icon: "heart.fill",
                    isActive: false
                ) {
                    showingHealthCheckModal = true
                    HapticManager.shared.impact(.light)
                }
            }
        }
        .sheet(isPresented: $showingMoodModal) {
            LogMoodModal()
        }
        .sheet(isPresented: $showingBreathingModal) {
            BreathingExerciseModal()
        }
        .sheet(isPresented: $showingMentalStateModal) {
            MentalStateModal()
        }
        .sheet(isPresented: $showingMeditationModal) {
            MeditationModal()
        }
        .sheet(isPresented: $showingHealthCheckModal) {
            HealthCheckModal()
        }
    }
}

struct TodaysMetricsCard: View {
    @ObservedObject private var healthDataManager = HealthDataManager.shared
    
    var body: some View {
        DashboardCard(title: "Today's Metrics", icon: "chart.line.uptrend.xyaxis", color: .green) {
            VStack(spacing: 12) {
                HStack {
                    MetricRow(
                        title: "Steps",
                        value: "\(healthDataManager.stepCount)",
                        icon: "figure.walk",
                        color: .green
                    )
                    
                    Spacer()
                    
                    MetricRow(
                        title: "Active Energy",
                        value: "\(Int(healthDataManager.activeEnergyBurned))",
                        icon: "flame.fill",
                        color: .orange
                    )
                }
                
                Divider()
                
                HStack {
                    MetricRow(
                        title: "Temperature",
                        value: "\(healthDataManager.currentBodyTemperature, specifier: "%.1f")°C",
                        icon: "thermometer",
                        color: .red
                    )
                    
                    Spacer()
                    
                    MetricRow(
                        title: "Oxygen",
                        value: "\(Int(healthDataManager.currentOxygenSaturation))%",
                        icon: "lungs.fill",
                        color: .blue
                    )
                }
            }
        }
    }
}

struct SleepSummaryCard: View {
    @ObservedObject private var sleepOptimizationManager = SleepOptimizationManager.shared
    
    var body: some View {
        DashboardCard(title: "Sleep Summary", icon: "bed.double.fill", color: .indigo) {
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Current Stage")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(sleepOptimizationManager.currentSleepStage.displayName)
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Quality Score")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(Int(sleepOptimizationManager.sleepQuality * 100))%")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(sleepOptimizationManager.sleepQuality > 0.7 ? .green : .orange)
                    }
                }
                
                Divider()
                
                HStack(spacing: 20) {
                    SleepStageIndicator(
                        stage: "Deep",
                        percentage: sleepOptimizationManager.deepSleepPercentage,
                        color: .blue
                    )
                    
                    SleepStageIndicator(
                        stage: "REM",
                        percentage: 0.22, // Example value
                        color: .purple
                    )
                    
                    SleepStageIndicator(
                        stage: "Light",
                        percentage: 0.45, // Example value
                        color: .cyan
                    )
                }
            }
        }
    }
}

struct EnvironmentStatusCard: View {
    @ObservedObject private var environmentManager = EnvironmentManager.shared
    
    var body: some View {
        DashboardCard(title: "Environment", icon: "house.fill", color: .green) {
            VStack(spacing: 12) {
                HStack {
                    EnvironmentMetric(
                        title: "Temperature",
                        value: "\(environmentManager.currentTemperature, specifier: "%.1f")°C",
                        icon: "thermometer",
                        color: .orange
                    )
                    
                    Spacer()
                    
                    EnvironmentMetric(
                        title: "Humidity",
                        value: "\(Int(environmentManager.currentHumidity))%",
                        icon: "humidity",
                        color: .blue
                    )
                }
                
                HStack {
                    EnvironmentMetric(
                        title: "Air Quality",
                        value: "\(Int(environmentManager.airQuality * 100))%",
                        icon: "wind",
                        color: environmentManager.airQuality > 0.8 ? .green : .yellow
                    )
                    
                    Spacer()
                    
                    EnvironmentMetric(
                        title: "Noise",
                        value: "\(Int(environmentManager.noiseLevel)) dB",
                        icon: "speaker.wave.2",
                        color: environmentManager.noiseLevel < 50 ? .green : .orange
                    )
                }
                
                if environmentManager.isOptimizationActive {
                    Divider()
                    
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Environment optimization active")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                }
            }
        }
    }
}

struct PredictiveInsightsCard: View {
    @ObservedObject private var predictiveAnalytics = PredictiveAnalyticsManager.shared
    
    var body: some View {
        DashboardCard(title: "Tomorrow's Forecast", icon: "brain.head.profile", color: .purple) {
            VStack(spacing: 12) {
                let forecast = predictiveAnalytics.physioForecast
                
                HStack {
                    ForecastMetric(
                        title: "Energy",
                        value: forecast.energy,
                        color: .red
                    )
                    
                    Spacer()
                    
                    ForecastMetric(
                        title: "Mood",
                        value: forecast.moodStability,
                        color: .blue
                    )
                }
                
                HStack {
                    ForecastMetric(
                        title: "Cognitive",
                        value: forecast.cognitiveAcuity,
                        color: .purple
                    )
                    
                    Spacer()
                    
                    ForecastMetric(
                        title: "Recovery",
                        value: forecast.musculoskeletalResilience,
                        color: .green
                    )
                }
                
                if forecast.confidence > 0 {
                    Divider()
                    
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundColor(.blue)
                        Text("Confidence: \(Int(forecast.confidence * 100))%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                }
            }
        }
    }
}

struct HealthAlertsCard: View {
    @ObservedObject private var predictiveAnalytics = PredictiveAnalyticsManager.shared
    @State private var showingAlertsDetail = false
    
    var body: some View {
        let alertCount = predictiveAnalytics.healthAlerts.count
        
        DashboardCard(title: "Health Alerts", icon: "exclamationmark.triangle.fill", color: alertCount > 0 ? .red : .gray) {
            VStack(spacing: 12) {
                if alertCount == 0 {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("No active alerts")
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                } else {
                    ForEach(Array(predictiveAnalytics.healthAlerts.prefix(3).enumerated()), id: \.offset) { index, alert in
                        AlertRow(alert: alert)
                        if index < min(2, alertCount - 1) {
                            Divider()
                        }
                    }
                    
                    if alertCount > 3 {
                        Button("View All Alerts (\(alertCount))") {
                            showingAlertsDetail = true
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }
                }
            }
        }
        .onTapGesture {
            if alertCount > 0 {
                showingAlertsDetail = true
            }
        }
        .sheet(isPresented: $showingAlertsDetail) {
            HealthAlertsDetailView()
        }
    }
}

struct RecentActivityCard: View {
    var body: some View {
        DashboardCard(title: "Recent Activity", icon: "clock.fill", color: .orange) {
            VStack(alignment: .leading, spacing: 8) {
                ActivityItem(
                    title: "Sleep optimization started",
                    time: "2 hours ago",
                    icon: "bed.double.fill",
                    color: .blue
                )
                
                ActivityItem(
                    title: "Environment optimized for sleep",
                    time: "2 hours ago",
                    icon: "house.fill",
                    color: .green
                )
                
                ActivityItem(
                    title: "Health data synced",
                    time: "4 hours ago",
                    icon: "arrow.clockwise",
                    color: .gray
                )
            }
        }
    }
}

// MARK: - Supporting Views

struct DashboardCard<Content: View>: View {
    let title: String
    let icon: String
    let color: Color
    let content: Content
    
    init(title: String, icon: String, color: Color, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.color = color
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title2)
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            content
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

struct HealthMetricDisplay: View {
    let title: String
    let value: String
    let unit: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(color)
                
                Text(unit)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct QuickActionButton: View {
    let title: String
    let icon: String
    let isActive: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(isActive ? .white : .primary)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isActive ? .white : .primary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 60)
            .background(isActive ? Color.blue : Color(.systemGray5))
            .cornerRadius(8)
        }
    }
}

struct MetricRow: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
        }
    }
}

struct SleepStageIndicator: View {
    let stage: String
    let percentage: Double
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(Int(percentage * 100))%")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(stage)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct ForecastMetric: View {
    let title: String
    let value: Double
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("\(Int(value * 100))%")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(color)
        }
    }
}

struct AlertRow: View {
    let alert: HealthAlert
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: alertIcon)
                .foregroundColor(alertColor)
                .font(.caption)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(alert.message)
                    .font(.caption)
                    .lineLimit(2)
                
                Text(timeAgo(from: alert.timestamp))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
    
    private var alertIcon: String {
        switch alert.severity {
        case .critical:
            return "exclamationmark.triangle.fill"
        case .high:
            return "exclamationmark.circle.fill"
        case .medium:
            return "info.circle.fill"
        case .low:
            return "info.circle"
        }
    }
    
    private var alertColor: Color {
        switch alert.severity {
        case .critical:
            return .red
        case .high:
            return .orange
        case .medium:
            return .yellow
        case .low:
            return .blue
        }
    }
    
    private func timeAgo(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

struct ActivityItem: View {
    let title: String
    let time: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.caption)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                
                Text(time)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

struct HealthAlertsDetailView: View {
    @ObservedObject private var predictiveAnalytics = PredictiveAnalyticsManager.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                ForEach(predictiveAnalytics.healthAlerts, id: \.timestamp) { alert in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(alert.type.rawValue)
                                .font(.headline)
                            
                            Spacer()
                            
                            Text(alert.severity.rawValue)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(alertColor(for: alert.severity))
                                .foregroundColor(.white)
                                .cornerRadius(4)
                        }
                        
                        Text(alert.message)
                            .font(.body)
                        
                        Text(alert.timestamp, style: .relative)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Health Alerts")
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
    
    private func alertColor(for severity: AlertSeverity) -> Color {
        switch severity {
        case .critical:
            return .red
        case .high:
            return .orange
        case .medium:
            return .yellow
        case .low:
            return .blue
        }
    }
}

// MARK: - Extensions

extension SleepStageType {
    var displayName: String {
        switch self {
        case .awake:
            return "Awake"
        case .lightSleep:
            return "Light Sleep"
        case .deepSleep:
            return "Deep Sleep"
        case .remSleep:
            return "REM Sleep"
        case .unknown:
            return "Unknown"
        }
    }
}

struct WatchSyncStatusCard: View {
    @ObservedObject private var appleWatchManager = AppleWatchManager.shared
    @ObservedObject private var realTimeSyncManager = RealTimeSyncManager.shared
    
    var body: some View {
        DashboardCard(title: "Apple Watch", icon: "applewatch", color: watchStatusColor) {
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Connection")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(connectionStatusText)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(watchStatusColor)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Messages")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(appleWatchManager.messageCount)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                }
                
                if let lastSync = realTimeSyncManager.lastSyncTime {
                    Divider()
                    
                    HStack {
                        Image(systemName: "clock")
                            .foregroundColor(.secondary)
                            .font(.caption)
                        
                        Text("Last sync: \(RelativeDateTimeFormatter().localizedString(for: lastSync, relativeTo: Date()))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                    }
                }
                
                if realTimeSyncManager.dataConflicts.count > 0 {
                    Divider()
                    
                    HStack {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundColor(.orange)
                            .font(.caption)
                        
                        Text("\(realTimeSyncManager.dataConflicts.count) conflicts")
                            .font(.caption)
                            .foregroundColor(.orange)
                        
                        Spacer()
                    }
                }
            }
        }
    }
    
    private var connectionStatusText: String {
        switch appleWatchManager.watchConnectionStatus {
        case .connected:
            return appleWatchManager.isWatchAvailable() ? "Connected" : "Paired"
        case .connecting:
            return "Connecting"
        case .disconnected:
            return "Disconnected"
        case .error:
            return "Error"
        }
    }
    
    private var watchStatusColor: Color {
        switch appleWatchManager.watchConnectionStatus {
        case .connected:
            return appleWatchManager.isWatchAvailable() ? .green : .yellow
        case .connecting:
            return .blue
        case .disconnected:
            return .gray
        case .error:
            return .red
        }
    }
}

struct SyncStatusDetailView: View {
    @ObservedObject private var realTimeSyncManager = RealTimeSyncManager.shared
    @ObservedObject private var appleWatchManager = AppleWatchManager.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section("Sync Status") {
                    SyncDetailRow(title: "Current Status", value: syncStatusText, color: syncStatusColor)
                    
                    if realTimeSyncManager.syncStatus == .syncing {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Sync Progress")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            ProgressView(value: realTimeSyncManager.syncProgress)
                                .progressViewStyle(LinearProgressViewStyle())
                        }
                        .padding(.vertical, 4)
                    }
                    
                    if let lastSync = realTimeSyncManager.lastSyncTime {
                        SyncDetailRow(
                            title: "Last Sync",
                            value: DateFormatter.syncDetail.string(from: lastSync),
                            color: .secondary
                        )
                    }
                }
                
                Section("Apple Watch") {
                    let watchStatus = appleWatchManager.getWatchConnectionStatus()
                    
                    SyncDetailRow(
                        title: "Connection",
                        value: watchStatus["isReachable"] as? Bool == true ? "Connected" : "Disconnected",
                        color: watchStatus["isReachable"] as? Bool == true ? .green : .red
                    )
                    
                    SyncDetailRow(
                        title: "Paired",
                        value: watchStatus["isPaired"] as? Bool == true ? "Yes" : "No",
                        color: .secondary
                    )
                    
                    SyncDetailRow(
                        title: "App Installed",
                        value: watchStatus["isWatchAppInstalled"] as? Bool == true ? "Yes" : "No",
                        color: .secondary
                    )
                    
                    SyncDetailRow(
                        title: "Messages Sent",
                        value: "\(watchStatus["messageCount"] ?? 0)",
                        color: .secondary
                    )
                    
                    SyncDetailRow(
                        title: "Queue Size",
                        value: "\(watchStatus["queueSize"] ?? 0)",
                        color: .secondary
                    )
                }
                
                if !realTimeSyncManager.dataConflicts.isEmpty {
                    Section("Data Conflicts") {
                        ForEach(realTimeSyncManager.dataConflicts) { conflict in
                            ConflictRow(conflict: conflict)
                        }
                        
                        Button("Clear All Conflicts") {
                            realTimeSyncManager.clearConflicts()
                        }
                        .foregroundColor(.red)
                    }
                }
                
                Section {
                    Button("Force Sync Now") {
                        realTimeSyncManager.performManualSync()
                    }
                    .foregroundColor(.blue)
                    
                    Button("Clear Watch Message Queue") {
                        appleWatchManager.clearMessageQueue()
                    }
                    .foregroundColor(.orange)
                }
            }
            .navigationTitle("Sync Status")
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
    
    private var syncStatusText: String {
        switch realTimeSyncManager.syncStatus {
        case .idle:
            return "Idle"
        case .syncing:
            return "Syncing..."
        case .completed:
            return "Completed"
        case .error(let message):
            return "Error: \(message)"
        }
    }
    
    private var syncStatusColor: Color {
        switch realTimeSyncManager.syncStatus {
        case .idle:
            return .secondary
        case .syncing:
            return .blue
        case .completed:
            return .green
        case .error:
            return .red
        }
    }
}

struct SyncDetailRow: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.primary)
            
            Spacer()
            
            Text(value)
                .foregroundColor(color)
                .fontWeight(.medium)
        }
    }
}

struct ConflictRow: View {
    let conflict: DataConflict
    @ObservedObject private var realTimeSyncManager = RealTimeSyncManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(conflict.type)
                    .font(.headline)
                
                Spacer()
                
                Text(DateFormatter.syncDetail.string(from: conflict.timestamp))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text("\(conflict.conflictingData.count) conflicting sources")
                .font(.caption)
                .foregroundColor(.orange)
            
            Button("Resolve") {
                realTimeSyncManager.resolveConflict(conflict, chosenIndex: 0)
            }
            .font(.caption)
            .foregroundColor(.blue)
        }
        .padding(.vertical, 4)
    }
}

extension DateFormatter {
    static let syncDetail: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .medium
        return formatter
    }()
}

struct WhatsNewCard: View {
    @AppStorage("whatsNewDismissed") private var dismissed = false
    @State private var showDetails = false
    
    var body: some View {
        if !dismissed {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "sparkles")
                        .foregroundColor(.yellow)
                    Text("What's New in HealthAI 2030")
                        .font(.headline)
                    Spacer()
                    Button(action: { dismissed = true }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
                Text("Explore new iOS 18/19 health features:")
                    .font(.subheadline)
                VStack(alignment: .leading, spacing: 8) {
                    Label("Mental Health Dashboard: Mindfulness, mood, and mental state tracking.", systemImage: "brain")
                    Label("Cardiac Health Dashboard: AFib, VO2 Max, and advanced cardiac insights.", systemImage: "waveform.path.ecg")
                    Label("Respiratory Health Dashboard: Breathing, O2, and sleep apnea analytics.", systemImage: "lungs.fill")
                }
                Button("Learn More") {
                    showDetails = true
                }
                .font(.caption)
                .padding(.top, 4)
            }
            .padding()
            .background(Color(.systemYellow).opacity(0.15))
            .cornerRadius(14)
            .shadow(radius: 1)
            .sheet(isPresented: $showDetails) {
                WhatsNewDetailView()
            }
        }
    }
}

struct WhatsNewDetailView: View {
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("What's New in HealthAI 2030")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.bottom, 8)
                    Group {
                        Label("Mental Health Dashboard", systemImage: "brain")
                        Text("Track mindfulness, mood, and mental state. Get personalized insights and recommendations for your mental well-being.")
                            .font(.body)
                            .foregroundColor(.secondary)
                        Divider()
                        Label("Cardiac Health Dashboard", systemImage: "waveform.path.ecg")
                        Text("Monitor atrial fibrillation, VO2 Max, and receive advanced cardiac insights and alerts.")
                            .font(.body)
                            .foregroundColor(.secondary)
                        Divider()
                        Label("Respiratory Health Dashboard", systemImage: "lungs.fill")
                        Text("Analyze breathing patterns, oxygen saturation, and sleep apnea risk with actionable insights.")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
            }
            .navigationTitle("What's New")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct LiveActivityDashboardCard: View {
    @StateObject private var liveActivityManager = LiveActivityManager.shared
    
    var body: some View {
        DashboardCard(title: "Live Health Monitoring", icon: "waveform.path.ecg", color: .indigo) {
            VStack(spacing: 12) {
                HStack {
                    Text(liveActivityManager.isActivityActive ? "Live Activity is Active" : "Live Activity is Inactive")
                        .font(.subheadline)
                        .foregroundColor(liveActivityManager.isActivityActive ? .green : .secondary)
                    Spacer()
                }
                
                if liveActivityManager.isActivityActive {
                    Button("Stop Monitoring") {
                        liveActivityManager.stopHealthMonitoring()
                        HapticManager.shared.success()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                } else {
                    Button("Start Monitoring") {
                        liveActivityManager.startHealthMonitoring()
                        HapticManager.shared.success()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
            }
        }
    }
}

#Preview {
    DashboardView()
}
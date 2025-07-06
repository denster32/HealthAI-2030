import SwiftUI
import Charts
import os.log
import SwiftData

@available(iOS 17.0, *)
@available(macOS 14.0, *)

/// Main dashboard view displaying user health summary and key metrics
struct DashboardView: View {
    import Analytics
    
    @StateObject private var healthDataManager = HealthDataManager.shared
    @StateObject private var predictiveAnalytics = PredictiveAnalyticsManager.shared
    @StateObject private var sleepOptimizationManager = SleepOptimizationManager.shared
    @StateObject private var environmentManager = EnvironmentManager.shared
    @StateObject private var realTimeSyncManager = RealTimeSyncManager.shared
    @StateObject private var appleWatchManager = AppleWatchManager.shared
    @StateObject private var liveActivityManager = LiveActivityManager.shared
    @StateObject private var authManager = AuthenticationManager.shared
    @StateObject private var errorHandler = ErrorHandlingService.shared
    @Query(sort: [SortDescriptor(\HealthData.timestamp, order: .reverse)]) private var healthData: [HealthData]
    @State private var selectedTimeRange: TimeRange = .day
    @State private var showingHealthDetails = false
    @State private var showingHealthAlerts = false
    @State private var showingSyncStatus = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Welcome header
                    welcomeHeader
                    
                    // Health summary cards
                    healthSummaryCards
                    
                    // Health trends chart
                    healthTrendsChart
                    
                    // Quick actions
                    quickActions
                    
                    // Recent activity
                    recentActivity
                }
                .padding()
            }
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                await refreshData()
            }
            .alert("Error", isPresented: $errorHandler.showingError) {
                Button("OK") { errorHandler.dismissError() }
            } message: {
                Text(errorHandler.currentErrorMessage)
            }
            .sheet(isPresented: $showingHealthAlerts) {
                HealthAlertsDetailView()
            }
            .sheet(isPresented: $showingSyncStatus) {
                SyncStatusDetailView()
            }
        }
    }
    
    private var welcomeHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Welcome back,")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    
                    Text(authManager.currentUser?.displayName ?? "User")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                }
                
                Spacer()
                
                Button(action: {
                    showingHealthDetails = true
                }) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
                .accessibilityLabel("View detailed health analytics")
            }
            
            Text("Here's your health summary for today")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    private var healthSummaryCards: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            HealthMetricCard(
                title: "Heart Rate",
                value: "\(Int(averageHeartRate))",
                unit: "BPM",
                icon: "heart.fill",
                color: .red,
                trend: heartRateTrend
            )
            
            HealthMetricCard(
                title: "Steps",
                value: "\(totalSteps)",
                unit: "steps",
                icon: "figure.walk",
                color: .green,
                trend: stepsTrend
            )
            
            HealthMetricCard(
                title: "Sleep",
                value: String(format: "%.1f", averageSleepHours),
                unit: "hours",
                icon: "bed.double.fill",
                color: .blue,
                trend: sleepTrend
            )
            
            HealthMetricCard(
                title: "Stress",
                value: String(format: "%.0f", averageStressLevel),
                unit: "%",
                icon: "brain.head.profile",
                color: .orange,
                trend: stressTrend
            )
        }
    }
    
    private var healthTrendsChart: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Health Trends")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Picker("Time Range", selection: $selectedTimeRange) {
                    ForEach(TimeRange.allCases, id: \.self) { range in
                        Text(range.displayName).tag(range)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .frame(width: 200)
            }
            
            if #available(iOS 17.0, *) {
                Chart(filteredHealthData) { data in
                    LineMark(
                        x: .value("Time", data.timestamp),
                        y: .value("Heart Rate", data.heartRate)
                    )
                    .foregroundStyle(.red)
                    .interpolationMethod(.catmullRom)
                    
                    LineMark(
                        x: .value("Time", data.timestamp),
                        y: .value("Stress", data.stressLevel)
                    )
                    .foregroundStyle(.orange)
                    .interpolationMethod(.catmullRom)
                }
                .frame(height: 200)
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .hour, count: 6)) { value in
                        AxisGridLine()
                        AxisValueLabel(format: .dateTime.hour())
                    }
                }
            } else {
                // Fallback for iOS 16
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemGray5))
                    .frame(height: 200)
                    .overlay(
                        Text("Charts available in iOS 17+")
                            .foregroundColor(.secondary)
                    )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    private var quickActions: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Actions")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                QuickActionButton(
                    title: "Log Water",
                    icon: "drop.fill",
                    color: .blue
                ) {
                    // Log water intake
                }
                
                QuickActionButton(
                    title: "Start Meditation",
                    icon: "brain.head.profile",
                    color: .purple
                ) {
                    // Start meditation
                }
                
                QuickActionButton(
                    title: "Log Exercise",
                    icon: "figure.run",
                    color: .green
                ) {
                    // Log exercise
                }
                
                QuickActionButton(
                    title: "Health Check",
                    icon: "heart.text.square.fill",
                    color: .red
                ) {
                    // Perform health check
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    private var recentActivity: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Activity")
                .font(.headline)
                .fontWeight(.semibold)
            
            if recentHealthData.isEmpty {
                Text("No recent activity")
                    .foregroundColor(.secondary)
                    .italic()
            } else {
                ForEach(recentHealthData.prefix(5), id: \.id) { data in
                    ActivityRow(healthData: data)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    // MARK: - Computed Properties
    
    private var filteredHealthData: [HealthData] {
        let cutoff = Date().addingTimeInterval(-selectedTimeRange.interval)
        return healthData.filter { $0.timestamp >= cutoff }
    }
    
    private var recentHealthData: [HealthData] {
        Array(healthData.prefix(10))
    }
    
    private var averageHeartRate: Double {
        let heartRates = filteredHealthData.map { $0.heartRate }.filter { $0 > 0 }
        return heartRates.isEmpty ? 0 : heartRates.reduce(0, +) / Double(heartRates.count)
    }
    
    private var totalSteps: Int {
        filteredHealthData.reduce(0) { $0 + $1.steps }
    }
    
    private var averageSleepHours: Double {
        let sleepHours = filteredHealthData.map { $0.sleepHours }.filter { $0 > 0 }
        return sleepHours.isEmpty ? 0 : sleepHours.reduce(0, +) / Double(sleepHours.count)
    }
    
    private var averageStressLevel: Double {
        let stressLevels = filteredHealthData.map { $0.stressLevel }.filter { $0 > 0 }
        return stressLevels.isEmpty ? 0 : stressLevels.reduce(0, +) / Double(stressLevels.count)
    }
    
    // MARK: - Trend Calculations
    
    private var heartRateTrend: Trend {
        calculateTrend(for: filteredHealthData.map { $0.heartRate })
    }
    
    private var stepsTrend: Trend {
        calculateTrend(for: filteredHealthData.map { Double($0.steps) })
    }
    
    private var sleepTrend: Trend {
        calculateTrend(for: filteredHealthData.map { $0.sleepHours })
    }
    
    private var stressTrend: Trend {
        calculateTrend(for: filteredHealthData.map { $0.stressLevel })
    }
    
    private func calculateTrend(for values: [Double]) -> Trend {
        guard values.count >= 2 else { return .stable }
        
        let recent = Array(values.prefix(values.count / 2))
        let older = Array(values.suffix(values.count / 2))
        
        let recentAvg = recent.reduce(0, +) / Double(recent.count)
        let olderAvg = older.reduce(0, +) / Double(older.count)
        
        let change = recentAvg - olderAvg
        let percentChange = (change / olderAvg) * 100
        
        if percentChange > 5 {
            return .increasing
        } else if percentChange < -5 {
            return .decreasing
        } else {
            return .stable
        }
    }
    
    // MARK: - Actions
    
    private func refreshData() async {
        // Implement data refresh logic
        // This would typically refresh health data from HealthKit
    }
}

// MARK: - Supporting Views

struct HealthMetricCard: View {
    let title: String
    let value: String
    let unit: String
    let icon: String
    let color: Color
    let trend: Trend
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Spacer()
                
                trendIcon
            }
            
            Text(value)
                .font(.title)
                .fontWeight(.bold)
            
            Text(unit)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(title)
                .font(.headline)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value) \(unit), \(trend.description)")
    }
    
    private var trendIcon: some View {
        Image(systemName: trend.iconName)
            .font(.caption)
            .foregroundColor(trend.color)
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
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel("Quick action: \(title)")
    }
}

struct ActivityRow: View {
    let healthData: HealthData
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: activityIcon)
                .font(.title3)
                .foregroundColor(activityColor)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(activityTitle)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(healthData.timestamp, style: .relative)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(activityValue)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
    
    private var activityIcon: String {
        if healthData.heartRate > 0 { return "heart.fill" }
        if healthData.steps > 0 { return "figure.walk" }
        if healthData.sleepHours > 0 { return "bed.double.fill" }
        return "circle.fill"
    }
    
    private var activityColor: Color {
        if healthData.heartRate > 0 { return .red }
        if healthData.steps > 0 { return .green }
        if healthData.sleepHours > 0 { return .blue }
        return .gray
    }
    
    private var activityTitle: String {
        if healthData.heartRate > 0 { return "Heart Rate Recorded" }
        if healthData.steps > 0 { return "Steps Logged" }
        if healthData.sleepHours > 0 { return "Sleep Tracked" }
        return "Health Data Updated"
    }
    
    private var activityValue: String {
        if healthData.heartRate > 0 { return "\(Int(healthData.heartRate)) BPM" }
        if healthData.steps > 0 { return "\(healthData.steps) steps" }
        if healthData.sleepHours > 0 { return String(format: "%.1f hours", healthData.sleepHours) }
        return ""
    }
}

// MARK: - Supporting Types

enum Trend {
    case increasing, decreasing, stable
    
    var iconName: String {
        switch self {
        case .increasing: return "arrow.up.circle.fill"
        case .decreasing: return "arrow.down.circle.fill"
        case .stable: return "minus.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .increasing: return .green
        case .decreasing: return .red
        case .stable: return .gray
        }
    }
    
    var description: String {
        switch self {
        case .increasing: return "trending up"
        case .decreasing: return "trending down"
        case .stable: return "stable"
        }
    }
}

enum TimeRange: CaseIterable {
    case day, week, month
    
    var displayName: String {
        switch self {
        case .day: return "Day"
        case .week: return "Week"
        case .month: return "Month"
        }
    }
    
    var interval: TimeInterval {
        switch self {
        case .day: return 24 * 60 * 60
        case .week: return 7 * 24 * 60 * 60
        case .month: return 30 * 24 * 60 * 60
        }
    }
}

#Preview {
    DashboardView()
        .modelContainer(for: [UserProfile.self, HealthData.self, DigitalTwin.self], isCloudKitEnabled: true)
}
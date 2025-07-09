import SwiftUI
import Charts
import SwiftData

struct HealthDashboardView: View {
    @EnvironmentObject var healthDataManager: HealthDataManager
    @EnvironmentObject var appleWatchManager: AppleWatchManager
    @EnvironmentObject var predictiveAnalyticsManager: PredictiveAnalyticsManager
    
    @State private var selectedTimeRange: TimeRange = .day
    @State private var showingHealthDetails = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                // Header with time range selector
                HeaderView()
                
                // Main health metrics grid
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 25) {
                    // Heart Rate Card
                    HeartRateCard()
                    
                    // HRV Card
                    HRVCard()
                    
                    // Sleep Quality Card
                    SleepQualityCard()
                    
                    // Activity Level Card
                    ActivityLevelCard()
                    
                    // Blood Pressure Card
                    BloodPressureCard()
                    
                    // Oxygen Saturation Card
                    OxygenSaturationCard()
                    // --- New: Advanced Health Prediction Card ---
                    NavigationLink(destination: AdvancedHealthPredictionView(analyticsEngine: AnalyticsEngine())) {
                        HealthMetricCard(
                            title: "AI Health Predictions",
                            value: "AI",
                            unit: "",
                            color: .blue,
                            icon: "brain.head.profile",
                            trend: .stable,
                            subtitle: "Personalized Insights",
                            detailText: "Tap for advanced predictions"
                        )
                    }
                }
                
                // Health trends chart
                HealthTrendsChart()
                
                // Quick actions
                QuickActionsSection()
                
                // Watch integration status
                WatchIntegrationSection()
            }
            .padding(.horizontal, 40)
            .padding(.vertical, 20)
        }
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.black.opacity(0.8), Color.black.opacity(0.6)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .sheet(isPresented: $showingHealthDetails) {
            HealthDetailsView()
        }
    }
}

// MARK: - Header View

struct HeaderView: View {
    @State private var selectedTimeRange: TimeRange = .day
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text("Health Dashboard")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Real-time health monitoring and insights")
                    .font(.title3)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            // Time range picker
            Picker("Time Range", selection: $selectedTimeRange) {
                ForEach(TimeRange.allCases, id: \.self) { range in
                    Text(range.displayName).tag(range)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .frame(width: 300)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 15)
        .background(Color.white.opacity(0.1))
        .cornerRadius(15)
    }
}

// MARK: - Health Metric Cards

struct HeartRateCard: View {
    @EnvironmentObject var healthDataManager: HealthDataManager
    
    var body: some View {
        HealthMetricCard(
            title: "Heart Rate",
            value: "\(Int(healthDataManager.currentHeartRate))",
            unit: "BPM",
            color: heartRateColor,
            icon: "heart.fill",
            trend: healthDataManager.heartRateTrend,
            subtitle: heartRateStatus,
            detailText: "Last updated: \(formattedLastUpdate)"
        )
    }
    
    private var heartRateColor: Color {
        let hr = healthDataManager.currentHeartRate
        if hr > 100 { return .red }
        else if hr > 80 { return .orange }
        else if hr > 60 { return .green }
        else { return .blue }
    }
    
    private var heartRateStatus: String {
        let hr = healthDataManager.currentHeartRate
        if hr > 100 { return "Elevated" }
        else if hr > 80 { return "Active" }
        else if hr > 60 { return "Normal" }
        else { return "Resting" }
    }
    
    private var formattedLastUpdate: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: Date())
    }
}

struct HRVCard: View {
    @EnvironmentObject var healthDataManager: HealthDataManager
    
    var body: some View {
        HealthMetricCard(
            title: "Heart Rate Variability",
            value: String(format: "%.1f", healthDataManager.currentHRV),
            unit: "ms",
            color: hrvColor,
            icon: "waveform.path.ecg",
            trend: healthDataManager.hrvTrend,
            subtitle: hrvStatus,
            detailText: "Coherence: \(coherenceLevel)"
        )
    }
    
    private var hrvColor: Color {
        let hrv = healthDataManager.currentHRV
        if hrv > 50 { return .green }
        else if hrv > 30 { return .yellow }
        else { return .red }
    }
    
    private var hrvStatus: String {
        let hrv = healthDataManager.currentHRV
        if hrv > 50 { return "Excellent" }
        else if hrv > 30 { return "Good" }
        else { return "Low" }
    }
    
    private var coherenceLevel: String {
        let hrv = healthDataManager.currentHRV
        if hrv > 50 { return "High" }
        else if hrv > 30 { return "Medium" }
        else { return "Low" }
    }
}

struct SleepQualityCard: View {
    @EnvironmentObject var healthDataManager: HealthDataManager
    
    var body: some View {
        HealthMetricCard(
            title: "Sleep Quality",
            value: String(format: "%.0f", healthDataManager.sleepQualityScore),
            unit: "%",
            color: sleepQualityColor,
            icon: "bed.double.fill",
            trend: healthDataManager.sleepQualityTrend,
            subtitle: sleepQualityStatus,
            detailText: "Last night: \(lastNightSleep)"
        )
    }
    
    private var sleepQualityColor: Color {
        let quality = healthDataManager.sleepQualityScore
        if quality > 80 { return .green }
        else if quality > 60 { return .yellow }
        else { return .red }
    }
    
    private var sleepQualityStatus: String {
        let quality = healthDataManager.sleepQualityScore
        if quality > 80 { return "Excellent" }
        else if quality > 60 { return "Good" }
        else { return "Poor" }
    }
    
    private var lastNightSleep: String {
        // This would come from actual sleep data
        return "7h 32m"
    }
}

struct ActivityLevelCard: View {
    @EnvironmentObject var healthDataManager: HealthDataManager
    
    var body: some View {
        HealthMetricCard(
            title: "Daily Activity",
            value: String(format: "%.0f", healthDataManager.activityLevel),
            unit: "steps",
            color: activityColor,
            icon: "figure.walk",
            trend: healthDataManager.activityTrend,
            subtitle: activityStatus,
            detailText: "Goal: 10,000 steps"
        )
    }
    
    private var activityColor: Color {
        let activity = healthDataManager.activityLevel
        if activity > 10000 { return .green }
        else if activity > 5000 { return .yellow }
        else { return .red }
    }
    
    private var activityStatus: String {
        let activity = healthDataManager.activityLevel
        if activity > 10000 { return "Goal Achieved" }
        else if activity > 5000 { return "Active" }
        else { return "Low Activity" }
    }
}

struct BloodPressureCard: View {
    @EnvironmentObject var healthDataManager: HealthDataManager
    
    var body: some View {
        HealthMetricCard(
            title: "Blood Pressure",
            value: "120/80",
            unit: "mmHg",
            color: .blue,
            icon: "heart.circle.fill",
            trend: .stable,
            subtitle: "Normal",
            detailText: "Last reading: 2 hours ago"
        )
    }
}

struct OxygenSaturationCard: View {
    @EnvironmentObject var healthDataManager: HealthDataManager
    
    var body: some View {
        HealthMetricCard(
            title: "Oxygen Saturation",
            value: "98",
            unit: "%",
            color: .green,
            icon: "lungs.fill",
            trend: .stable,
            subtitle: "Normal",
            detailText: "Last reading: 1 hour ago"
        )
    }
}

// MARK: - Enhanced Health Metric Card

struct HealthMetricCard: View {
    let title: String
    let value: String
    let unit: String
    let color: Color
    let icon: String
    let trend: HealthTrend
    let subtitle: String
    let detailText: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header with icon and trend
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title)
                
                Spacer()
                
                // Trend indicator
                HStack(spacing: 5) {
                    Image(systemName: trendIcon)
                        .foregroundColor(trendColor)
                        .font(.caption)
                    
                    Text(trendText)
                        .font(.caption)
                        .foregroundColor(trendColor)
                }
            }
            
            // Main value
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.gray)
                
                HStack(alignment: .bottom, spacing: 8) {
                    Text(value)
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(color)
                    
                    Text(unit)
                        .font(.title2)
                        .foregroundColor(.gray)
                }
                
                Text(subtitle)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text(detailText)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding(25)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(color.opacity(0.3), lineWidth: 2)
                )
        )
        .shadow(color: color.opacity(0.2), radius: 15, x: 0, y: 5)
        .scaleEffect(1.0)
        .animation(.easeInOut(duration: 0.2), value: value)
    }
    
    private var trendIcon: String {
        switch trend {
        case .up: return "arrow.up.circle.fill"
        case .down: return "arrow.down.circle.fill"
        case .stable: return "minus.circle.fill"
        }
    }
    
    private var trendColor: Color {
        switch trend {
        case .up: return .green
        case .down: return .red
        case .stable: return .gray
        }
    }
    
    private var trendText: String {
        switch trend {
        case .up: return "Rising"
        case .down: return "Falling"
        case .stable: return "Stable"
        }
    }
}

// MARK: - Health Trends Chart

struct HealthTrendsChart: View {
    @Query(filter: #Predicate<HealthData> { $0.dataType == "HeartRate" }, sort: [SortDescriptor(\HealthData.timestamp)]) var heartRateEntries: [HealthData]
    @Query(filter: #Predicate<HealthData> { $0.dataType == "HRV" }, sort: [SortDescriptor(\HealthData.timestamp)]) var hrvEntries: [HealthData]
    @State private var selectedTimeRange: TimeRange = .day
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("Health Trends")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                Spacer()
                Picker("Time Range", selection: $selectedTimeRange) {
                    ForEach(TimeRange.allCases, id: \ .self) { range in
                        Text(range.displayName).tag(range)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .frame(width: 220)
            }
            Chart {
                ForEach(filteredHeartRateData, id: \ .timestamp) { entry in
                    LineMark(
                        x: .value("Time", entry.timestamp),
                        y: .value("Heart Rate", entry.value)
                    )
                    .foregroundStyle(.red)
                    .lineStyle(StrokeStyle(lineWidth: 3))
                    .symbol(by: .value("Type", "Heart Rate"))
                }
                ForEach(filteredHRVData, id: \ .timestamp) { entry in
                    LineMark(
                        x: .value("Time", entry.timestamp),
                        y: .value("HRV", entry.value)
                    )
                    .foregroundStyle(.green)
                    .lineStyle(StrokeStyle(lineWidth: 3, dash: [4,2]))
                    .symbol(by: .value("Type", "HRV"))
                }
            }
            .frame(height: 300)
            .chartXAxis {
                AxisMarks(values: .automatic) { value in
                    AxisGridLine()
                    AxisValueLabel()
                }
            }
            .chartYAxis {
                AxisMarks(values: .automatic) { value in
                    AxisGridLine()
                    AxisValueLabel()
                }
            }
            .chartOverlay { proxy in
                GeometryReader { geo in
                    Rectangle().fill(Color.clear).contentShape(Rectangle())
                        .gesture(DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                // Add interactivity: show tooltip/annotation at drag location
                            })
                }
            }
        }
        .padding(25)
        .background(Color.white.opacity(0.1))
        .cornerRadius(20)
    }
    
    private var filteredHeartRateData: [HealthData] {
        let cutoff = Date().addingTimeInterval(-selectedTimeRange.interval)
        return heartRateEntries.filter { $0.timestamp >= cutoff }
    }
    private var filteredHRVData: [HealthData] {
        let cutoff = Date().addingTimeInterval(-selectedTimeRange.interval)
        return hrvEntries.filter { $0.timestamp >= cutoff }
    }
}

// MARK: - Quick Actions Section

struct QuickActionsSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Quick Actions")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 20) {
                QuickActionButton(
                    title: "Start Sleep Session",
                    icon: "bed.double.fill",
                    color: .blue
                ) {
                    // Start sleep session
                }
                
                QuickActionButton(
                    title: "Health Check",
                    icon: "heart.fill",
                    color: .red
                ) {
                    // Perform health check
                }
                
                QuickActionButton(
                    title: "Environment Setup",
                    icon: "house.fill",
                    color: .green
                ) {
                    // Setup environment
                }
            }
        }
        .padding(25)
        .background(Color.white.opacity(0.1))
        .cornerRadius(20)
    }
}

struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 15) {
                Image(systemName: icon)
                    .font(.title)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color.white.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(color.opacity(0.3), lineWidth: 2)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(1.0)
        .animation(.easeInOut(duration: 0.2), value: title)
    }
}

// MARK: - Watch Integration Section

struct WatchIntegrationSection: View {
    @EnvironmentObject var appleWatchManager: AppleWatchManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Apple Watch Integration")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            HStack(spacing: 30) {
                // Connection Status
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Image(systemName: "applewatch")
                            .foregroundColor(connectionColor)
                            .font(.title2)
                        
                        Text("Connection Status")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                    
                    Text(connectionStatus)
                        .font(.title3)
                        .foregroundColor(connectionColor)
                    
                    Text("Last sync: \(lastSyncTime)")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                // Watch Health Data
                VStack(alignment: .leading, spacing: 10) {
                    Text("Watch Health Data")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text("Heart Rate: \(Int(appleWatchManager.watchHealthData.heartRate)) BPM")
                        .font(.body)
                        .foregroundColor(.gray)
                    
                    Text("HRV: \(String(format: "%.1f", appleWatchManager.watchHealthData.hrv)) ms")
                        .font(.body)
                        .foregroundColor(.gray)
                    
                    Text("Sleep Stage: \(appleWatchManager.watchHealthData.sleepStage)")
                        .font(.body)
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(25)
        .background(Color.white.opacity(0.1))
        .cornerRadius(20)
    }
    
    private var connectionColor: Color {
        switch appleWatchManager.watchConnectionStatus {
        case .connected: return .green
        case .connecting: return .yellow
        case .disconnected: return .red
        case .error: return .red
        }
    }
    
    private var connectionStatus: String {
        switch appleWatchManager.watchConnectionStatus {
        case .connected: return "Connected"
        case .connecting: return "Connecting..."
        case .disconnected: return "Disconnected"
        case .error: return "Error"
        }
    }
    
    private var lastSyncTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: Date())
    }
}

// MARK: - Supporting Types

enum TimeRange: String, CaseIterable {
    case hour = "hour"
    case day = "day"
    case week = "week"
    case month = "month"
    
    var displayName: String {
        switch self {
        case .hour: return "1 Hour"
        case .day: return "24 Hours"
        case .week: return "7 Days"
        case .month: return "30 Days"
        }
    }
    
    var interval: TimeInterval {
        switch self {
        case .day: return 24*60*60
        case .week: return 7*24*60*60
        case .month: return 30*24*60*60
        }
    }
}

struct HealthDataPoint {
    let time: Date
    let value: Double
}

// MARK: - Placeholder Views

struct HealthDetailsView: View {
    var body: some View {
        VStack {
            Text("Health Details")
                .font(.title)
                .fontWeight(.bold)
            Text("Implementation coming soon...")
                .foregroundColor(.secondary)
        }
        .padding()
    }
} 
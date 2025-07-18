import SwiftUI
import Charts

/// Real-time performance benchmarking dashboard
struct PerformanceBenchmarkingView: View {
    @StateObject private var performanceManager = PerformanceBenchmarkingManager()
    @State private var selectedTab = 0
    @State private var showingExportSheet = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Tab Selection
                tabSelectionView
                
                // Content
                TabView(selection: $selectedTab) {
                    metricsDashboardView
                        .tag(0)
                    
                    alertsView
                        .tag(1)
                    
                    recommendationsView
                        .tag(2)
                    
                    settingsView
                        .tag(3)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingExportSheet) {
            exportView
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Performance Monitor")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Real-time system metrics")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: {
                    performanceManager.startBenchmark()
                }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.title3)
                        .foregroundColor(.blue)
                }
                
                Button(action: {
                    showingExportSheet = true
                }) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.title3)
                        .foregroundColor(.blue)
                }
            }
            
            // Overall Performance Score
            overallPerformanceScore
        }
        .padding()
        .background(Color(.systemBackground))
    }
    
    private var overallPerformanceScore: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Overall Score")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("\(calculateOverallScore())%")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(scoreColor)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("Status")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(overallStatus)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(statusColor)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Tab Selection
    private var tabSelectionView: some View {
        HStack(spacing: 0) {
            ForEach(["Metrics", "Alerts", "Tips", "Settings"], id: \.self) { tab in
                Button(action: {
                    withAnimation {
                        selectedTab = ["Metrics", "Alerts", "Tips", "Settings"].firstIndex(of: tab) ?? 0
                    }
                }) {
                    VStack(spacing: 4) {
                        Text(tab)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(selectedTab == ["Metrics", "Alerts", "Tips", "Settings"].firstIndex(of: tab) ? .blue : .secondary)
                        
                        Rectangle()
                            .fill(selectedTab == ["Metrics", "Alerts", "Tips", "Settings"].firstIndex(of: tab) ? Color.blue : Color.clear)
                            .frame(height: 2)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal)
        .background(Color(.systemBackground))
    }
    
    // MARK: - Metrics Dashboard
    private var metricsDashboardView: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                // Memory Metrics
                MetricCard(
                    title: "Memory",
                    value: "\(Int(performanceManager.memoryMetrics.memoryUsage * 100))%",
                    subtitle: "\(String(format: "%.1f", performanceManager.memoryMetrics.usedMemory)) MB",
                    icon: "memorychip",
                    color: memoryColor,
                    trend: .stable
                )
                
                // CPU Metrics
                MetricCard(
                    title: "CPU",
                    value: "\(Int(performanceManager.cpuMetrics.cpuUsage * 100))%",
                    subtitle: "Usage",
                    icon: "cpu",
                    color: cpuColor,
                    trend: .stable
                )
                
                // Battery Metrics
                MetricCard(
                    title: "Battery",
                    value: "\(Int(performanceManager.batteryMetrics.batteryLevel * 100))%",
                    subtitle: performanceManager.batteryMetrics.isCharging ? "Charging" : "Discharging",
                    icon: "battery.100",
                    color: batteryColor,
                    trend: .stable
                )
                
                // Network Metrics
                MetricCard(
                    title: "Network",
                    value: "\(Int(performanceManager.networkMetrics.latency))ms",
                    subtitle: performanceManager.networkMetrics.connectionType.rawValue.capitalized,
                    icon: "network",
                    color: networkColor,
                    trend: .stable
                )
                
                // Launch Time
                MetricCard(
                    title: "Launch Time",
                    value: "\(String(format: "%.2f", performanceManager.launchMetrics.launchTime))s",
                    subtitle: performanceManager.launchMetrics.isFirstLaunch ? "First Launch" : "Subsequent",
                    icon: "timer",
                    color: launchTimeColor,
                    trend: .stable
                )
                
                // Frame Rate
                MetricCard(
                    title: "Frame Rate",
                    value: "\(Int(performanceManager.uiMetrics.frameRate)) FPS",
                    subtitle: "UI Performance",
                    icon: "display",
                    color: frameRateColor,
                    trend: .stable
                )
            }
            .padding()
        }
    }
    
    // MARK: - Alerts View
    private var alertsView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                if performanceManager.performanceAlerts.isEmpty {
                    emptyAlertsView
                } else {
                    ForEach(performanceManager.performanceAlerts, id: \.timestamp) { alert in
                        AlertCard(alert: alert)
                    }
                }
            }
            .padding()
        }
    }
    
    private var emptyAlertsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48))
                .foregroundColor(.green)
            
            Text("All Systems Normal")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("No performance alerts detected. Your app is running optimally.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
    
    // MARK: - Recommendations View
    private var recommendationsView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                if performanceManager.optimizationRecommendations.isEmpty {
                    emptyRecommendationsView
                } else {
                    ForEach(performanceManager.optimizationRecommendations, id: \.title) { recommendation in
                        RecommendationCard(recommendation: recommendation)
                    }
                }
            }
            .padding()
        }
    }
    
    private var emptyRecommendationsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "star.fill")
                .font(.system(size: 48))
                .foregroundColor(.yellow)
            
            Text("Optimal Performance")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("No optimization recommendations at this time. Your app is performing well.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
    
    // MARK: - Settings View
    private var settingsView: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Monitoring Settings
                VStack(alignment: .leading, spacing: 12) {
                    Text("Monitoring Settings")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    VStack(spacing: 8) {
                        SettingRow(title: "Auto-refresh", value: "5 seconds")
                        SettingRow(title: "Alert Thresholds", value: "Standard")
                        SettingRow(title: "Data Retention", value: "30 days")
                    }
                }
                
                // Export Options
                VStack(alignment: .leading, spacing: 12) {
                    Text("Export Options")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    VStack(spacing: 8) {
                        SettingRow(title: "Format", value: "JSON")
                        SettingRow(title: "Include Charts", value: "Yes")
                        SettingRow(title: "Compression", value: "Enabled")
                    }
                }
                
                // About
                VStack(alignment: .leading, spacing: 12) {
                    Text("About")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    VStack(spacing: 8) {
                        SettingRow(title: "Version", value: "1.0.0")
                        SettingRow(title: "Last Updated", value: DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .short))
                    }
                }
            }
            .padding()
        }
    }
    
    // MARK: - Export View
    private var exportView: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Export Performance Report")
                    .font(.title2)
                    .fontWeight(.bold)
                
                VStack(spacing: 16) {
                    ExportOptionRow(title: "JSON Format", subtitle: "Machine-readable data", icon: "doc.text")
                    ExportOptionRow(title: "PDF Report", subtitle: "Human-readable report", icon: "doc.richtext")
                    ExportOptionRow(title: "CSV Data", subtitle: "Spreadsheet compatible", icon: "tablecells")
                }
                
                Spacer()
                
                Button("Export Report") {
                    // Export functionality would go here
                    showingExportSheet = false
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        showingExportSheet = false
                    }
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    private func calculateOverallScore() -> Int {
        let memoryScore = (1.0 - performanceManager.memoryMetrics.memoryUsage) * 100
        let cpuScore = (1.0 - performanceManager.cpuMetrics.cpuUsage) * 100
        let batteryScore = performanceManager.batteryMetrics.batteryLevel * 100
        let networkScore = max(0, 100 - (performanceManager.networkMetrics.latency / 10))
        let launchScore = max(0, 100 - (performanceManager.launchMetrics.launchTime * 20))
        let frameRateScore = min(100, (performanceManager.uiMetrics.frameRate / 60) * 100)
        
        return Int((memoryScore + cpuScore + batteryScore + networkScore + launchScore + frameRateScore) / 6)
    }
    
    private var scoreColor: Color {
        let score = calculateOverallScore()
        if score >= 80 { return .green }
        else if score >= 60 { return .yellow }
        else { return .red }
    }
    
    private var overallStatus: String {
        let score = calculateOverallScore()
        if score >= 80 { return "Excellent" }
        else if score >= 60 { return "Good" }
        else { return "Needs Attention" }
    }
    
    private var statusColor: Color {
        let score = calculateOverallScore()
        if score >= 80 { return .green }
        else if score >= 60 { return .orange }
        else { return .red }
    }
    
    private var memoryColor: Color {
        let usage = performanceManager.memoryMetrics.memoryUsage
        if usage < 0.5 { return .green }
        else if usage < 0.8 { return .yellow }
        else { return .red }
    }
    
    private var cpuColor: Color {
        let usage = performanceManager.cpuMetrics.cpuUsage
        if usage < 0.3 { return .green }
        else if usage < 0.7 { return .yellow }
        else { return .red }
    }
    
    private var batteryColor: Color {
        let level = performanceManager.batteryMetrics.batteryLevel
        if level > 0.5 { return .green }
        else if level > 0.2 { return .yellow }
        else { return .red }
    }
    
    private var networkColor: Color {
        let latency = performanceManager.networkMetrics.latency
        if latency < 100 { return .green }
        else if latency < 500 { return .yellow }
        else { return .red }
    }
    
    private var launchTimeColor: Color {
        let time = performanceManager.launchMetrics.launchTime
        if time < 2.0 { return .green }
        else if time < 5.0 { return .yellow }
        else { return .red }
    }
    
    private var frameRateColor: Color {
        let fps = performanceManager.uiMetrics.frameRate
        if fps >= 55 { return .green }
        else if fps >= 45 { return .yellow }
        else { return .red }
    }
}

// MARK: - Supporting Views
struct MetricCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    let trend: TrendDirection
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Spacer()
                
                Image(systemName: trend.icon)
                    .font(.caption)
                    .foregroundColor(trend.color)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct AlertCard: View {
    let alert: PerformanceAlert
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: alert.type.icon)
                .font(.title2)
                .foregroundColor(alert.severity.color)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(alert.message)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(alert.type.displayName)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(DateFormatter.localizedString(from: alert.timestamp, dateStyle: .none, timeStyle: .short))
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct RecommendationCard: View {
    let recommendation: OptimizationRecommendation
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: recommendation.type.icon)
                    .font(.title2)
                    .foregroundColor(recommendation.priority.color)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(recommendation.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text(recommendation.priority.displayName)
                        .font(.caption)
                        .foregroundColor(recommendation.priority.color)
                }
                
                Spacer()
            }
            
            Text(recommendation.description)
                .font(.body)
                .foregroundColor(.secondary)
            
            Text(recommendation.action)
                .font(.caption)
                .foregroundColor(.blue)
                .fontWeight(.medium)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct SettingRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.body)
            
            Spacer()
            
            Text(value)
                .font(.body)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct ExportOptionRow: View {
    let title: String
    let subtitle: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.medium)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Supporting Enums
enum TrendDirection {
    case up, down, stable
    
    var icon: String {
        switch self {
        case .up: return "arrow.up"
        case .down: return "arrow.down"
        case .stable: return "minus"
        }
    }
    
    var color: Color {
        switch self {
        case .up: return .red
        case .down: return .green
        case .stable: return .secondary
        }
    }
}

// MARK: - Extensions
extension AlertType {
    var icon: String {
        switch self {
        case .memory: return "memorychip"
        case .cpu: return "cpu"
        case .battery: return "battery.25"
        case .network: return "network"
        case .launchTime: return "timer"
        case .ui: return "display"
        }
    }
    
    var displayName: String {
        switch self {
        case .memory: return "Memory"
        case .cpu: return "CPU"
        case .battery: return "Battery"
        case .network: return "Network"
        case .launchTime: return "Launch Time"
        case .ui: return "UI Performance"
        }
    }
}

extension AlertSeverity {
    var color: Color {
        switch self {
        case .info: return .blue
        case .warning: return .orange
        case .critical: return .red
        }
    }
}

extension OptimizationType {
    var icon: String {
        switch self {
        case .memory: return "memorychip"
        case .cpu: return "cpu"
        case .battery: return "battery.100"
        case .network: return "network"
        case .ui: return "display"
        }
    }
}

extension RecommendationPriority {
    var color: Color {
        switch self {
        case .low: return .green
        case .medium: return .yellow
        case .high: return .orange
        case .critical: return .red
        }
    }
    
    var displayName: String {
        switch self {
        case .low: return "Low Priority"
        case .medium: return "Medium Priority"
        case .high: return "High Priority"
        case .critical: return "Critical"
        }
    }
}

extension NetworkConnectionType {
    var rawValue: String {
        switch self {
        case .wifi: return "wifi"
        case .cellular: return "cellular"
        case .unknown: return "unknown"
        }
    }
}

// MARK: - Preview
struct PerformanceBenchmarkingView_Previews: PreviewProvider {
    static var previews: some View {
        PerformanceBenchmarkingView()
    }
} 
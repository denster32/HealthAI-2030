import SwiftUI
import Charts
import HealthAI2030Core

/// Comprehensive performance analytics dashboard for HealthAI 2030
/// Provides real-time performance monitoring, historical analysis, and optimization recommendations
public struct PerformanceAnalyticsDashboard: View {
    
    // MARK: - Properties
    @State private var performanceMonitor = PerformanceMonitor.shared
    @State private var selectedTimePeriod: TimePeriod = .lastHour
    @State private var selectedTab = 0
    @State private var showingExportSheet = false
    @State private var showingSettingsSheet = false
    
    // MARK: - Computed Properties
    private var currentReport: PerformanceReport {
        performanceMonitor.getPerformanceReport(for: selectedTimePeriod)
    }
    
    private var cpuUsageData: [(Date, Double)] {
        currentReport.metrics.map { ($0.timestamp, $0.cpuUsage * 100) }
    }
    
    private var memoryUsageData: [(Date, Double)] {
        currentReport.metrics.map { ($0.timestamp, $0.memoryUsage.usagePercentage * 100) }
    }
    
    private var batteryLevelData: [(Date, Double)] {
        currentReport.metrics.map { ($0.timestamp, $0.batteryLevel * 100) }
    }
    
    private var networkLatencyData: [(Date, Double)] {
        currentReport.metrics.map { ($0.timestamp, $0.networkLatency) }
    }
    
    // MARK: - Body
    public var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Tab Picker
                tabPickerView
                
                // Content
                TabView(selection: $selectedTab) {
                    overviewTab
                        .tag(0)
                    
                    detailedMetricsTab
                        .tag(1)
                    
                    alertsTab
                        .tag(2)
                    
                    recommendationsTab
                        .tag(3)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .navigationTitle("Performance Analytics")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingExportSheet = true }) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { showingSettingsSheet = true }) {
                        Image(systemName: "gear")
                    }
                }
            }
            .sheet(isPresented: $showingExportSheet) {
                exportView
            }
            .sheet(isPresented: $showingSettingsSheet) {
                settingsView
            }
        }
        .onAppear {
            performanceMonitor.startMonitoring()
        }
        .onDisappear {
            performanceMonitor.stopMonitoring()
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        VStack(spacing: 16) {
            // Time Period Picker
            Picker("Time Period", selection: $selectedTimePeriod) {
                Text("Last Hour").tag(TimePeriod.lastHour)
                Text("Last Day").tag(TimePeriod.lastDay)
                Text("Last Week").tag(TimePeriod.lastWeek)
                Text("Last Month").tag(TimePeriod.lastMonth)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)
            
            // Monitoring Status
            HStack {
                Circle()
                    .fill(performanceMonitor.isMonitoring ? Color.green : Color.red)
                    .frame(width: 12, height: 12)
                
                Text(performanceMonitor.isMonitoring ? "Monitoring Active" : "Monitoring Inactive")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("Updated: \(performanceMonitor.lastMetricsUpdate, style: .relative)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
    }
    
    // MARK: - Tab Picker View
    private var tabPickerView: some View {
        HStack(spacing: 0) {
            ForEach(["Overview", "Metrics", "Alerts", "Recommendations"], id: \.self) { tab in
                Button(action: {
                    withAnimation {
                        selectedTab = ["Overview", "Metrics", "Alerts", "Recommendations"].firstIndex(of: tab) ?? 0
                    }
                }) {
                    VStack(spacing: 4) {
                        Text(tab)
                            .font(.caption)
                            .fontWeight(selectedTab == ["Overview", "Metrics", "Alerts", "Recommendations"].firstIndex(of: tab) ? .semibold : .regular)
                            .foregroundColor(selectedTab == ["Overview", "Metrics", "Alerts", "Recommendations"].firstIndex(of: tab) ? .primary : .secondary)
                        
                        Rectangle()
                            .fill(selectedTab == ["Overview", "Metrics", "Alerts", "Recommendations"].firstIndex(of: tab) ? Color.accentColor : Color.clear)
                            .frame(height: 2)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }
    
    // MARK: - Overview Tab
    private var overviewTab: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                // CPU Usage Card
                MetricCard(
                    title: "CPU Usage",
                    value: "\(Int(currentReport.summary.averageCPUUsage * 100))%",
                    subtitle: "Peak: \(Int(currentReport.summary.peakCPUUsage * 100))%",
                    color: .orange,
                    icon: "cpu"
                )
                
                // Memory Usage Card
                MetricCard(
                    title: "Memory Usage",
                    value: "\(Int(currentReport.summary.averageMemoryUsage * 100))%",
                    subtitle: "Peak: \(Int(currentReport.summary.peakMemoryUsage * 100))%",
                    color: .blue,
                    icon: "memorychip"
                )
                
                // Battery Level Card
                MetricCard(
                    title: "Battery Level",
                    value: "\(Int(currentReport.summary.averageBatteryLevel * 100))%",
                    subtitle: "Current: \(Int(performanceMonitor.currentMetrics.batteryLevel * 100))%",
                    color: .green,
                    icon: "battery.100"
                )
                
                // Network Latency Card
                MetricCard(
                    title: "Network Latency",
                    value: "\(Int(currentReport.summary.averageNetworkLatency))ms",
                    subtitle: "Current: \(Int(performanceMonitor.currentMetrics.networkLatency))ms",
                    color: .purple,
                    icon: "network"
                )
                
                // Alerts Card
                MetricCard(
                    title: "Active Alerts",
                    value: "\(currentReport.summary.totalAlerts)",
                    subtitle: "Last 24h",
                    color: .red,
                    icon: "exclamationmark.triangle"
                )
                
                // Recommendations Card
                MetricCard(
                    title: "Recommendations",
                    value: "\(currentReport.summary.totalRecommendations)",
                    subtitle: "Available",
                    color: .yellow,
                    icon: "lightbulb"
                )
            }
            .padding()
            
            // Charts Section
            VStack(spacing: 20) {
                // CPU Usage Chart
                ChartCard(title: "CPU Usage Over Time", color: .orange) {
                    if #available(iOS 16.0, *) {
                        Chart(cpuUsageData, id: \.0) { item in
                            LineMark(
                                x: .value("Time", item.0),
                                y: .value("CPU Usage", item.1)
                            )
                            .foregroundStyle(Color.orange)
                            
                            AreaMark(
                                x: .value("Time", item.0),
                                y: .value("CPU Usage", item.1)
                            )
                            .foregroundStyle(Color.orange.opacity(0.1))
                        }
                        .chartYAxis {
                            AxisMarks(position: .leading) {
                                AxisGridLine()
                                AxisTick()
                                AxisValueLabel(format: .percent)
                            }
                        }
                        .chartXAxis {
                            AxisMarks(values: .stride(by: .hour)) { _ in
                                AxisGridLine()
                                AxisTick()
                                AxisValueLabel(format: .dateTime.hour())
                            }
                        }
                        .frame(height: 200)
                    } else {
                        Text("Charts require iOS 16+")
                            .foregroundColor(.secondary)
                            .frame(height: 200)
                    }
                }
                
                // Memory Usage Chart
                ChartCard(title: "Memory Usage Over Time", color: .blue) {
                    if #available(iOS 16.0, *) {
                        Chart(memoryUsageData, id: \.0) { item in
                            LineMark(
                                x: .value("Time", item.0),
                                y: .value("Memory Usage", item.1)
                            )
                            .foregroundStyle(Color.blue)
                            
                            AreaMark(
                                x: .value("Time", item.0),
                                y: .value("Memory Usage", item.1)
                            )
                            .foregroundStyle(Color.blue.opacity(0.1))
                        }
                        .chartYAxis {
                            AxisMarks(position: .leading) {
                                AxisGridLine()
                                AxisTick()
                                AxisValueLabel(format: .percent)
                            }
                        }
                        .chartXAxis {
                            AxisMarks(values: .stride(by: .hour)) { _ in
                                AxisGridLine()
                                AxisTick()
                                AxisValueLabel(format: .dateTime.hour())
                            }
                        }
                        .frame(height: 200)
                    } else {
                        Text("Charts require iOS 16+")
                            .foregroundColor(.secondary)
                            .frame(height: 200)
                    }
                }
                
                // Battery Level Chart
                ChartCard(title: "Battery Level Over Time", color: .green) {
                    if #available(iOS 16.0, *) {
                        Chart(batteryLevelData, id: \.0) { item in
                            LineMark(
                                x: .value("Time", item.0),
                                y: .value("Battery Level", item.1)
                            )
                            .foregroundStyle(Color.green)
                            
                            AreaMark(
                                x: .value("Time", item.0),
                                y: .value("Battery Level", item.1)
                            )
                            .foregroundStyle(Color.green.opacity(0.1))
                        }
                        .chartYAxis {
                            AxisMarks(position: .leading) {
                                AxisGridLine()
                                AxisTick()
                                AxisValueLabel(format: .percent)
                            }
                        }
                        .chartXAxis {
                            AxisMarks(values: .stride(by: .hour)) { _ in
                                AxisGridLine()
                                AxisTick()
                                AxisValueLabel(format: .dateTime.hour())
                            }
                        }
                        .frame(height: 200)
                    } else {
                        Text("Charts require iOS 16+")
                            .foregroundColor(.secondary)
                            .frame(height: 200)
                    }
                }
                
                // Network Latency Chart
                ChartCard(title: "Network Latency Over Time", color: .purple) {
                    if #available(iOS 16.0, *) {
                        Chart(networkLatencyData, id: \.0) { item in
                            LineMark(
                                x: .value("Time", item.0),
                                y: .value("Network Latency", item.1)
                            )
                            .foregroundStyle(Color.purple)
                            
                            AreaMark(
                                x: .value("Time", item.0),
                                y: .value("Network Latency", item.1)
                            )
                            .foregroundStyle(Color.purple.opacity(0.1))
                        }
                        .chartYAxis {
                            AxisMarks(position: .leading) {
                                AxisGridLine()
                                AxisTick()
                                AxisValueLabel(format: .number)
                            }
                        }
                        .chartXAxis {
                            AxisMarks(values: .stride(by: .hour)) { _ in
                                AxisGridLine()
                                AxisTick()
                                AxisValueLabel(format: .dateTime.hour())
                            }
                        }
                        .frame(height: 200)
                    } else {
                        Text("Charts require iOS 16+")
                            .foregroundColor(.secondary)
                            .frame(height: 200)
                    }
                }
            }
            .padding()
        }
    }
    
    // MARK: - Detailed Metrics Tab
    private var detailedMetricsTab: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // System Information
                DetailCard(title: "System Information", icon: "info.circle") {
                    VStack(alignment: .leading, spacing: 8) {
                        DetailRow(title: "Device Model", value: performanceMonitor.systemInfo.deviceModel)
                        DetailRow(title: "System Version", value: performanceMonitor.systemInfo.systemVersion)
                        DetailRow(title: "App Version", value: performanceMonitor.systemInfo.appVersion)
                        DetailRow(title: "Build Number", value: performanceMonitor.systemInfo.buildNumber)
                        DetailRow(title: "Device ID", value: performanceMonitor.systemInfo.deviceIdentifier)
                    }
                }
                
                // Device Capabilities
                DetailCard(title: "Device Capabilities", icon: "cpu") {
                    VStack(alignment: .leading, spacing: 8) {
                        CapabilityRow(title: "Neural Engine", enabled: performanceMonitor.deviceCapabilities.hasNeuralEngine)
                        CapabilityRow(title: "Metal Support", enabled: performanceMonitor.deviceCapabilities.hasMetalSupport)
                        CapabilityRow(title: "ARKit", enabled: performanceMonitor.deviceCapabilities.hasARKit)
                        CapabilityRow(title: "Core ML", enabled: performanceMonitor.deviceCapabilities.hasCoreML)
                        CapabilityRow(title: "HealthKit", enabled: performanceMonitor.deviceCapabilities.hasHealthKit)
                        CapabilityRow(title: "HomeKit", enabled: performanceMonitor.deviceCapabilities.hasHomeKit)
                        CapabilityRow(title: "CarPlay", enabled: performanceMonitor.deviceCapabilities.hasCarPlay)
                        CapabilityRow(title: "Watch Connectivity", enabled: performanceMonitor.deviceCapabilities.hasWatchConnectivity)
                    }
                }
                
                // Network Status
                DetailCard(title: "Network Status", icon: "network") {
                    VStack(alignment: .leading, spacing: 8) {
                        DetailRow(title: "Connection Status", value: performanceMonitor.networkStatus.isConnected ? "Connected" : "Disconnected")
                        DetailRow(title: "Connection Type", value: performanceMonitor.networkStatus.connectionType.rawValue)
                        DetailRow(title: "Expensive Connection", value: performanceMonitor.networkStatus.isExpensive ? "Yes" : "No")
                        DetailRow(title: "Constrained Connection", value: performanceMonitor.networkStatus.isConstrained ? "Yes" : "No")
                    }
                }
                
                // Current Metrics
                DetailCard(title: "Current Metrics", icon: "gauge") {
                    VStack(alignment: .leading, spacing: 8) {
                        DetailRow(title: "CPU Usage", value: "\(Int(performanceMonitor.currentMetrics.cpuUsage * 100))%")
                        DetailRow(title: "Memory Usage", value: "\(Int(performanceMonitor.currentMetrics.memoryUsage.usagePercentage * 100))%")
                        DetailRow(title: "Battery Level", value: "\(Int(performanceMonitor.currentMetrics.batteryLevel * 100))%")
                        DetailRow(title: "Network Latency", value: "\(Int(performanceMonitor.currentMetrics.networkLatency))ms")
                        DetailRow(title: "UI Responsiveness", value: "\(Int(performanceMonitor.currentMetrics.uiResponsiveness)) FPS")
                        DetailRow(title: "ML Inference Time", value: "\(Int(performanceMonitor.currentMetrics.mlInferenceTime * 1000))ms")
                        DetailRow(title: "Database Query Time", value: "\(Int(performanceMonitor.currentMetrics.databaseQueryTime * 1000))ms")
                    }
                }
            }
            .padding()
        }
    }
    
    // MARK: - Alerts Tab
    private var alertsTab: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                if performanceMonitor.performanceAlerts.isEmpty {
                    EmptyStateView(
                        icon: "exclamationmark.triangle",
                        title: "No Alerts",
                        subtitle: "No performance alerts have been triggered"
                    )
                } else {
                    ForEach(performanceMonitor.performanceAlerts.reversed()) { alert in
                        AlertCard(alert: alert)
                    }
                }
            }
            .padding()
        }
    }
    
    // MARK: - Recommendations Tab
    private var recommendationsTab: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                if performanceMonitor.optimizationRecommendations.isEmpty {
                    EmptyStateView(
                        icon: "lightbulb",
                        title: "No Recommendations",
                        subtitle: "No optimization recommendations available"
                    )
                } else {
                    ForEach(performanceMonitor.optimizationRecommendations) { recommendation in
                        RecommendationCard(recommendation: recommendation)
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
                Text("Export Performance Data")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Export comprehensive performance data including metrics, alerts, and recommendations for analysis.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                
                VStack(spacing: 12) {
                    ExportOptionCard(
                        title: "JSON Export",
                        subtitle: "Complete performance data in JSON format",
                        icon: "doc.text"
                    ) {
                        exportJSONData()
                    }
                    
                    ExportOptionCard(
                        title: "CSV Export",
                        subtitle: "Metrics data in CSV format for spreadsheet analysis",
                        icon: "tablecells"
                    ) {
                        exportCSVData()
                    }
                    
                    ExportOptionCard(
                        title: "PDF Report",
                        subtitle: "Formatted performance report in PDF",
                        icon: "doc.richtext"
                    ) {
                        exportPDFReport()
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Export Data")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        showingExportSheet = false
                    }
                }
            }
        }
    }
    
    // MARK: - Settings View
    private var settingsView: some View {
        NavigationView {
            Form {
                Section("Monitoring") {
                    Toggle("Enable Monitoring", isOn: $performanceMonitor.isMonitoring)
                    
                    HStack {
                        Text("Update Interval")
                        Spacer()
                        Picker("Interval", selection: $performanceMonitor.monitoringInterval) {
                            Text("1s").tag(1.0)
                            Text("5s").tag(5.0)
                            Text("10s").tag(10.0)
                            Text("30s").tag(30.0)
                            Text("1m").tag(60.0)
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                }
                
                Section("Alert Thresholds") {
                    HStack {
                        Text("CPU Usage")
                        Spacer()
                        Text("\(Int(performanceMonitor.alertThresholds.cpuUsage * 100))%")
                    }
                    Slider(value: $performanceMonitor.alertThresholds.cpuUsage, in: 0.1...1.0)
                    
                    HStack {
                        Text("Memory Usage")
                        Spacer()
                        Text("\(Int(performanceMonitor.alertThresholds.memoryUsage * 100))%")
                    }
                    Slider(value: $performanceMonitor.alertThresholds.memoryUsage, in: 0.1...1.0)
                    
                    HStack {
                        Text("Battery Level")
                        Spacer()
                        Text("\(Int(performanceMonitor.alertThresholds.batteryLevel * 100))%")
                    }
                    Slider(value: $performanceMonitor.alertThresholds.batteryLevel, in: 0.05...0.5)
                    
                    HStack {
                        Text("Network Latency")
                        Spacer()
                        Text("\(Int(performanceMonitor.alertThresholds.networkLatency))ms")
                    }
                    Slider(value: $performanceMonitor.alertThresholds.networkLatency, in: 50...500)
                }
                
                Section("Data Management") {
                    Button("Clear Historical Data") {
                        performanceMonitor.clearHistoricalData()
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        showingSettingsSheet = false
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    private func exportJSONData() {
        // Implementation for JSON export
    }
    
    private func exportCSVData() {
        // Implementation for CSV export
    }
    
    private func exportPDFReport() {
        // Implementation for PDF export
    }
}

// MARK: - Supporting Views

struct MetricCard: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Spacer()
            }
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(subtitle)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct ChartCard<Content: View>: View {
    let title: String
    let color: Color
    let content: Content
    
    init(title: String, color: Color, @ViewBuilder content: () -> Content) {
        self.title = title
        self.color = color
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
            content
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct DetailCard<Content: View>: View {
    let title: String
    let icon: String
    let content: Content
    
    init(title: String, icon: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.accentColor)
                Text(title)
                    .font(.headline)
                Spacer()
            }
            
            content
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct DetailRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }
}

struct CapabilityRow: View {
    let title: String
    let enabled: Bool
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
            Spacer()
            Image(systemName: enabled ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(enabled ? .green : .red)
        }
    }
}

struct AlertCard: View {
    let alert: PerformanceAlert
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: severityIcon)
                    .foregroundColor(severityColor)
                
                Text(alert.type.rawValue)
                    .font(.headline)
                
                Spacer()
                
                Text(alert.timestamp, style: .relative)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(alert.message)
                .font(.body)
                .foregroundColor(.primary)
            
            HStack {
                Text(alert.severity.rawValue)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(severityColor.opacity(0.2))
                    .foregroundColor(severityColor)
                    .cornerRadius(8)
                
                Spacer()
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var severityIcon: String {
        switch alert.severity {
        case .info: return "info.circle"
        case .warning: return "exclamationmark.triangle"
        case .error: return "xmark.circle"
        case .critical: return "exclamationmark.octagon"
        }
    }
    
    private var severityColor: Color {
        switch alert.severity {
        case .info: return .blue
        case .warning: return .orange
        case .error: return .red
        case .critical: return .purple
        }
    }
}

struct RecommendationCard: View {
    let recommendation: OptimizationRecommendation
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "lightbulb")
                    .foregroundColor(.yellow)
                
                Text(recommendation.title)
                    .font(.headline)
                
                Spacer()
                
                Text(recommendation.priority.rawValue)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(priorityColor.opacity(0.2))
                    .foregroundColor(priorityColor)
                    .cornerRadius(8)
            }
            
            Text(recommendation.description)
                .font(.body)
                .foregroundColor(.primary)
            
            Text("Impact: \(recommendation.impact.rawValue)")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("Implementation: \(recommendation.implementation)")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top, 4)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
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

struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
            Text(subtitle)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct ExportOptionCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.accentColor)
                    .frame(width: 32)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview
struct PerformanceAnalyticsDashboard_Previews: PreviewProvider {
    static var previews: some View {
        PerformanceAnalyticsDashboard()
    }
} 
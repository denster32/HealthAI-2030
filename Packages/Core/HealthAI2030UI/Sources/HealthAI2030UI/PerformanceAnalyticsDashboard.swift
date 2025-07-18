import SwiftUI
import Charts
#if canImport(HealthAI2030Core)
import HealthAI2030Core
#endif

extension Color {
    static let systemGray6 = Color.gray.opacity(0.1)
    static let systemBackground = Color.white
}

/// Simplified performance analytics dashboard for HealthAI 2030
/// Provides basic performance monitoring and analytics
public struct PerformanceAnalyticsDashboard: View {
    
    // MARK: - Properties
    @State private var selectedTimePeriod = 0
    @State private var selectedTab = 0
    @State private var showingExportSheet = false
    @State private var showingSettingsSheet = false
    
    // MARK: - Mock Data
    private let timePeriods = ["Last Hour", "Last Day", "Last Week", "Last Month"]
    private let mockMetrics = [
        ("CPU Usage", "45%", "Peak: 78%", Color.orange),
        ("Memory Usage", "62%", "Peak: 85%", Color.blue),
        ("Battery Level", "73%", "Current: 73%", Color.green),
        ("Network Latency", "125ms", "Current: 125ms", Color.purple),
        ("Active Alerts", "2", "Last 24h", Color.red),
        ("Recommendations", "3", "Available", Color.yellow)
    ]
    
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
                #if os(iOS)
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                #endif
            }
            .navigationTitle("Performance Analytics")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.large)
            #endif
            .toolbar {
                #if os(iOS)
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
                #else
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showingExportSheet = true }) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
                
                ToolbarItem(placement: .automatic) {
                    Button(action: { showingSettingsSheet = true }) {
                        Image(systemName: "gear")
                    }
                }
                #endif
            }
            .sheet(isPresented: $showingExportSheet) {
                exportView
            }
            .sheet(isPresented: $showingSettingsSheet) {
                settingsView
            }
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        VStack(spacing: 16) {
            // Time Period Picker
            Picker("Time Period", selection: $selectedTimePeriod) {
                ForEach(0..<timePeriods.count, id: \.self) { index in
                    Text(timePeriods[index]).tag(index)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)
            
            // Monitoring Status
            HStack {
                Circle()
                    .fill(Color.green)
                    .frame(width: 12, height: 12)
                
                Text("Monitoring Active")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("Updated: 2 minutes ago")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
        .background(Color.white)
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
                ForEach(mockMetrics, id: \.0) { metric in
                    MetricCard(
                        title: metric.0,
                        value: metric.1,
                        subtitle: metric.2,
                        color: metric.3,
                        icon: "gauge"
                    )
                }
            }
            .padding()
            
            // Charts Section
            VStack(spacing: 20) {
                // CPU Usage Chart
                ChartCard(title: "CPU Usage Over Time", color: .orange) {
                    if #available(iOS 16.0, *) {
                        Chart {
                            ForEach(0..<24, id: \.self) { hour in
                                LineMark(
                                    x: .value("Hour", hour),
                                    y: .value("CPU Usage", Double.random(in: 20...80))
                                )
                                .foregroundStyle(Color.orange)
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
                        Chart {
                            ForEach(0..<24, id: \.self) { hour in
                                LineMark(
                                    x: .value("Hour", hour),
                                    y: .value("Memory Usage", Double.random(in: 40...90))
                                )
                                .foregroundStyle(Color.blue)
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
                        DetailRow(title: "Device Model", value: "iPhone 15 Pro")
                        DetailRow(title: "System Version", value: "iOS 18.0")
                        DetailRow(title: "App Version", value: "1.0.0")
                        DetailRow(title: "Build Number", value: "1")
                        DetailRow(title: "Device ID", value: "12345678-1234-1234-1234-123456789012")
                    }
                }
                
                // Device Capabilities
                DetailCard(title: "Device Capabilities", icon: "cpu") {
                    VStack(alignment: .leading, spacing: 8) {
                        CapabilityRow(title: "Neural Engine", enabled: true)
                        CapabilityRow(title: "Metal Support", enabled: true)
                        CapabilityRow(title: "ARKit", enabled: true)
                        CapabilityRow(title: "Core ML", enabled: true)
                        CapabilityRow(title: "HealthKit", enabled: true)
                        CapabilityRow(title: "HomeKit", enabled: true)
                        CapabilityRow(title: "CarPlay", enabled: false)
                        CapabilityRow(title: "Watch Connectivity", enabled: false)
                    }
                }
                
                // Current Metrics
                DetailCard(title: "Current Metrics", icon: "gauge") {
                    VStack(alignment: .leading, spacing: 8) {
                        DetailRow(title: "CPU Usage", value: "45%")
                        DetailRow(title: "Memory Usage", value: "62%")
                        DetailRow(title: "Battery Level", value: "73%")
                        DetailRow(title: "Network Latency", value: "125ms")
                        DetailRow(title: "UI Responsiveness", value: "60 FPS")
                        DetailRow(title: "ML Inference Time", value: "15ms")
                        DetailRow(title: "Database Query Time", value: "5ms")
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
                AlertCard(
                    title: "High CPU Usage",
                    message: "CPU usage exceeded 80% threshold",
                    severity: "Warning",
                    timestamp: "2 minutes ago",
                    color: .orange
                )
                
                AlertCard(
                    title: "Low Battery",
                    message: "Battery level below 20%",
                    severity: "Info",
                    timestamp: "5 minutes ago",
                    color: .blue
                )
            }
            .padding()
        }
    }
    
    // MARK: - Recommendations Tab
    private var recommendationsTab: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                RecommendationCard(
                    title: "Optimize CPU Usage",
                    description: "High CPU usage detected. Consider optimizing background tasks.",
                    priority: "High",
                    impact: "High",
                    implementation: "Review and optimize background processing"
                )
                
                RecommendationCard(
                    title: "Optimize Memory Usage",
                    description: "High memory usage detected. Consider implementing memory management optimizations.",
                    priority: "Medium",
                    impact: "Medium",
                    implementation: "Implement object pooling and optimize data structures"
                )
                
                RecommendationCard(
                    title: "Optimize Network Performance",
                    description: "High network latency detected. Consider implementing network optimizations.",
                    priority: "Low",
                    impact: "Low",
                    implementation: "Implement request caching and optimize API calls"
                )
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
                        // Implementation for JSON export
                    }
                    
                    ExportOptionCard(
                        title: "CSV Export",
                        subtitle: "Metrics data in CSV format for spreadsheet analysis",
                        icon: "tablecells"
                    ) {
                        // Implementation for CSV export
                    }
                    
                    ExportOptionCard(
                        title: "PDF Report",
                        subtitle: "Formatted performance report in PDF",
                        icon: "doc.richtext"
                    ) {
                        // Implementation for PDF export
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Export Data")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
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
                    Toggle("Enable Monitoring", isOn: .constant(true))
                    
                    HStack {
                        Text("Update Interval")
                        Spacer()
                        Picker("Interval", selection: .constant(5.0)) {
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
                        Text("80%")
                    }
                    
                    HStack {
                        Text("Memory Usage")
                        Spacer()
                        Text("70%")
                    }
                    
                    HStack {
                        Text("Battery Level")
                        Spacer()
                        Text("20%")
                    }
                    
                    HStack {
                        Text("Network Latency")
                        Spacer()
                        Text("200ms")
                    }
                }
                
                Section("Data Management") {
                    Button("Clear Historical Data") {
                        // Implementation for clearing data
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Done") {
                        showingSettingsSheet = false
                    }
                }
            }
        }
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
        .background(Color.gray.opacity(0.1))
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
        .background(Color.gray.opacity(0.1))
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
        .background(Color.gray.opacity(0.1))
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
    let title: String
    let message: String
    let severity: String
    let timestamp: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "exclamationmark.triangle")
                    .foregroundColor(color)
                
                Text(title)
                    .font(.headline)
                
                Spacer()
                
                Text(timestamp)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(message)
                .font(.body)
                .foregroundColor(.primary)
            
            HStack {
                Text(severity)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(color.opacity(0.2))
                    .foregroundColor(color)
                    .cornerRadius(8)
                
                Spacer()
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

struct RecommendationCard: View {
    let title: String
    let description: String
    let priority: String
    let impact: String
    let implementation: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "lightbulb")
                    .foregroundColor(.yellow)
                
                Text(title)
                    .font(.headline)
                
                Spacer()
                
                Text(priority)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(priorityColor.opacity(0.2))
                    .foregroundColor(priorityColor)
                    .cornerRadius(8)
            }
            
            Text(description)
                .font(.body)
                .foregroundColor(.primary)
            
            Text("Impact: \(impact)")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("Implementation: \(implementation)")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top, 4)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var priorityColor: Color {
        switch priority {
        case "Low": return .green
        case "Medium": return .orange
        case "High": return .red
        default: return .purple
        }
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
            .background(Color.gray.opacity(0.1))
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
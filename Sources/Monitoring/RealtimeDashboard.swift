import SwiftUI
import Charts
import Combine

/**
 * RealtimeDashboard
 * 
 * Real-time monitoring dashboard for HealthAI2030 system performance and health metrics.
 * Provides visual insights into app performance, user engagement, and system health.
 * 
 * ## Features
 * - Live performance metrics visualization
 * - System resource monitoring (CPU, Memory)
 * - Health data processing statistics
 * - Error tracking and alerts
 * - User engagement analytics
 * - Accessibility-compliant charts and metrics
 * 
 * ## Usage
 * ```swift
 * RealtimeDashboard()
 *     .environmentObject(TelemetryFramework.shared)
 * ```
 * 
 * - Author: HealthAI2030 Team
 * - Version: 1.0
 * - Since: iOS 18.0, macOS 15.0, tvOS 18.0, visionOS 2.0
 */
@available(iOS 18.0, macOS 15.0, tvOS 18.0, visionOS 2.0, *)
public struct RealtimeDashboard: View {
    
    @StateObject private var telemetry = TelemetryFramework.shared
    @StateObject private var analytics = AnalyticsEngine()
    @State private var selectedMetric: MetricType = .performance
    @State private var timeRange: TimeRange = .last24Hours
    @State private var showingDetails = false
    
    public enum MetricType: String, CaseIterable {
        case performance = "Performance"
        case system = "System"
        case health = "Health Data"
        case errors = "Errors"
        case users = "User Activity"
        
        var icon: String {
            switch self {
            case .performance: return "speedometer"
            case .system: return "cpu"
            case .health: return "heart.text.square"
            case .errors: return "exclamationmark.triangle"
            case .users: return "person.2"
            }
        }
        
        var color: Color {
            switch self {
            case .performance: return .blue
            case .system: return .green
            case .health: return .red
            case .errors: return .orange
            case .users: return .purple
            }
        }
    }
    
    public enum TimeRange: String, CaseIterable {
        case lastHour = "Last Hour"
        case last24Hours = "Last 24 Hours"
        case lastWeek = "Last Week"
        case lastMonth = "Last Month"
    }
    
    public init() {}
    
    public var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                headerSection
                metricsGrid
                detailSection
                Spacer()
            }
            .navigationTitle("System Monitoring")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Details") {
                        showingDetails = true
                    }
                    .accessibilityLabel("Show detailed metrics")
                }
            }
        }
        .sheet(isPresented: $showingDetails) {
            DetailedMetricsView(analytics: analytics)
        }
        .onAppear {
            analytics.startMonitoring()
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Real-time system monitoring dashboard")
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading) {
                    Text("System Health")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Live monitoring of HealthAI2030 performance")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                systemStatusIndicator
            }
            
            timeRangePicker
        }
        .padding()
        .background(Color(.systemBackground))
    }
    
    private var systemStatusIndicator: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(analytics.systemHealth.color)
                .frame(width: 12, height: 12)
                .accessibilityHidden(true)
            
            Text(analytics.systemHealth.status)
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color(.secondarySystemBackground))
        .clipShape(Capsule())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("System status: \(analytics.systemHealth.status)")
    }
    
    private var timeRangePicker: some View {
        Picker("Time Range", selection: $timeRange) {
            ForEach(TimeRange.allCases, id: \.self) { range in
                Text(range.rawValue).tag(range)
            }
        }
        .pickerStyle(.segmented)
        .accessibilityLabel("Select time range for metrics")
    }
    
    private var metricsGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
            ForEach(MetricType.allCases, id: \.self) { metric in
                MetricCard(
                    type: metric,
                    value: analytics.getMetricValue(for: metric),
                    trend: analytics.getTrend(for: metric),
                    isSelected: selectedMetric == metric
                )
                .onTapGesture {
                    selectedMetric = metric
                    AccessibilityHelper.accessibleHapticFeedback(.light)
                }
                .accessibilityAddTraits(.isButton)
                .accessibilityLabel("\(metric.rawValue) metric card")
                .accessibilityValue("Current value: \(analytics.getMetricValue(for: metric))")
            }
        }
        .padding()
    }
    
    private var detailSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: selectedMetric.icon)
                    .foregroundColor(selectedMetric.color)
                    .accessibilityHidden(true)
                
                Text(selectedMetric.rawValue)
                    .font(.headline)
                
                Spacer()
                
                Text("Live Data")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.green.opacity(0.2))
                    .foregroundColor(.green)
                    .clipShape(Capsule())
            }
            
            selectedMetricChart
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }
    
    @ViewBuilder
    private var selectedMetricChart: some View {
        switch selectedMetric {
        case .performance:
            PerformanceChart(data: analytics.performanceData, timeRange: timeRange)
        case .system:
            SystemChart(data: analytics.systemData, timeRange: timeRange)
        case .health:
            HealthDataChart(data: analytics.healthData, timeRange: timeRange)
        case .errors:
            ErrorChart(data: analytics.errorData, timeRange: timeRange)
        case .users:
            UserActivityChart(data: analytics.userActivityData, timeRange: timeRange)
        }
    }
}

// MARK: - Metric Card

@available(iOS 18.0, macOS 15.0, tvOS 18.0, visionOS 2.0, *)
struct MetricCard: View {
    let type: RealtimeDashboard.MetricType
    let value: String
    let trend: TrendDirection
    let isSelected: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: type.icon)
                    .foregroundColor(type.color)
                    .font(.title2)
                    .accessibilityHidden(true)
                
                Spacer()
                
                TrendIndicator(direction: trend)
            }
            
            Text(value)
                .font(.title)
                .fontWeight(.bold)
                .minimumScaleFactor(0.8)
            
            Text(type.rawValue)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(isSelected ? type.color.opacity(0.1) : Color(.tertiarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? type.color : Color.clear, lineWidth: 2)
        )
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

// MARK: - Trend Indicator

enum TrendDirection {
    case up, down, stable
    
    var icon: String {
        switch self {
        case .up: return "arrow.up.right"
        case .down: return "arrow.down.right"
        case .stable: return "minus"
        }
    }
    
    var color: Color {
        switch self {
        case .up: return .green
        case .down: return .red
        case .stable: return .gray
        }
    }
}

struct TrendIndicator: View {
    let direction: TrendDirection
    
    var body: some View {
        Image(systemName: direction.icon)
            .foregroundColor(direction.color)
            .font(.caption)
            .accessibilityLabel("Trend: \(direction)")
    }
}

// MARK: - Chart Views

@available(iOS 18.0, macOS 15.0, tvOS 18.0, visionOS 2.0, *)
struct PerformanceChart: View {
    let data: [PerformanceDataPoint]
    let timeRange: RealtimeDashboard.TimeRange
    
    var body: some View {
        Chart(data) { point in
            LineMark(
                x: .value("Time", point.timestamp),
                y: .value("Duration", point.duration)
            )
            .foregroundStyle(.blue)
            .interpolationMethod(.catmullRom)
        }
        .frame(height: 200)
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisValueLabel {
                    if let duration = value.as(Double.self) {
                        Text("\(Int(duration))ms")
                    }
                }
            }
        }
        .accessibilityChartDescriptor(self)
    }
}

@available(iOS 18.0, macOS 15.0, tvOS 18.0, visionOS 2.0, *)
struct SystemChart: View {
    let data: [SystemDataPoint]
    let timeRange: RealtimeDashboard.TimeRange
    
    var body: some View {
        Chart(data) { point in
            LineMark(
                x: .value("Time", point.timestamp),
                y: .value("CPU", point.cpuUsage)
            )
            .foregroundStyle(.green)
            
            LineMark(
                x: .value("Time", point.timestamp),
                y: .value("Memory", point.memoryUsage)
            )
            .foregroundStyle(.orange)
        }
        .frame(height: 200)
        .accessibilityChartDescriptor(self)
    }
}

@available(iOS 18.0, macOS 15.0, tvOS 18.0, visionOS 2.0, *)
struct HealthDataChart: View {
    let data: [HealthDataPoint]
    let timeRange: RealtimeDashboard.TimeRange
    
    var body: some View {
        Chart(data) { point in
            BarMark(
                x: .value("Time", point.timestamp),
                y: .value("Records", point.recordsProcessed)
            )
            .foregroundStyle(.red)
        }
        .frame(height: 200)
        .accessibilityChartDescriptor(self)
    }
}

@available(iOS 18.0, macOS 15.0, tvOS 18.0, visionOS 2.0, *)
struct ErrorChart: View {
    let data: [ErrorDataPoint]
    let timeRange: RealtimeDashboard.TimeRange
    
    var body: some View {
        Chart(data) { point in
            BarMark(
                x: .value("Time", point.timestamp),
                y: .value("Errors", point.errorCount)
            )
            .foregroundStyle(.orange)
        }
        .frame(height: 200)
        .accessibilityChartDescriptor(self)
    }
}

@available(iOS 18.0, macOS 15.0, tvOS 18.0, visionOS 2.0, *)
struct UserActivityChart: View {
    let data: [UserActivityPoint]
    let timeRange: RealtimeDashboard.TimeRange
    
    var body: some View {
        Chart(data) { point in
            AreaMark(
                x: .value("Time", point.timestamp),
                y: .value("Active Users", point.activeUsers)
            )
            .foregroundStyle(.purple.opacity(0.3))
            
            LineMark(
                x: .value("Time", point.timestamp),
                y: .value("Active Users", point.activeUsers)
            )
            .foregroundStyle(.purple)
        }
        .frame(height: 200)
        .accessibilityChartDescriptor(self)
    }
}

// MARK: - Accessibility Extensions

@available(iOS 18.0, macOS 15.0, tvOS 18.0, visionOS 2.0, *)
extension PerformanceChart: AXChartDescriptorRepresentable {
    func makeChartDescriptor() -> AXChartDescriptor {
        let xAxis = AXNumericDataAxisDescriptor(
            title: "Time",
            range: Double(data.first?.timestamp.timeIntervalSince1970 ?? 0)...Double(data.last?.timestamp.timeIntervalSince1970 ?? 0),
            gridlinePositions: []
        ) { value in
            Date(timeIntervalSince1970: value).formatted(.dateTime.hour().minute())
        }
        
        let yAxis = AXNumericDataAxisDescriptor(
            title: "Duration (ms)",
            range: 0...Double(data.map { $0.duration }.max() ?? 0),
            gridlinePositions: []
        ) { value in
            "\(Int(value))ms"
        }
        
        let series = AXDataSeriesDescriptor(
            name: "Performance",
            isContinuous: true,
            dataPoints: data.map { point in
                AXDataPoint(x: point.timestamp.timeIntervalSince1970, y: point.duration)
            }
        )
        
        return AXChartDescriptor(
            title: "Performance Metrics",
            summary: "Chart showing performance metrics over time",
            xAxis: xAxis,
            yAxis: yAxis,
            additionalAxes: [],
            series: [series]
        )
    }
}

// MARK: - System Health

struct SystemHealth {
    let status: String
    let color: Color
    
    static let healthy = SystemHealth(status: "Healthy", color: .green)
    static let warning = SystemHealth(status: "Warning", color: .orange)
    static let critical = SystemHealth(status: "Critical", color: .red)
}

// MARK: - Preview

#if DEBUG
@available(iOS 18.0, macOS 15.0, tvOS 18.0, visionOS 2.0, *)
struct RealtimeDashboard_Previews: PreviewProvider {
    static var previews: some View {
        RealtimeDashboard()
            .environmentObject(TelemetryFramework.shared)
    }
}
#endif
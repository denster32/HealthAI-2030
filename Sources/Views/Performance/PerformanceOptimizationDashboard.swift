import SwiftUI
import Charts

/// Comprehensive Performance Optimization Dashboard
/// Displays real-time performance metrics, optimization recommendations, and progress tracking
@available(iOS 18.0, macOS 15.0, *)
public struct PerformanceOptimizationDashboard: View {
    @StateObject private var optimizationStrategy = PerformanceOptimizationStrategy()
    @State private var selectedTab = 0
    @State private var showingOptimizationDetails = false
    @State private var selectedOptimization: OptimizationRecommendation?
    
    public init() {}
    
    public var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Tab Selection
                tabSelectionView
                
                // Content
                TabView(selection: $selectedTab) {
                    overviewTab
                        .tag(0)
                    
                    profilingTab
                        .tag(1)
                    
                    memoryTab
                        .tag(2)
                    
                    energyTab
                        .tag(3)
                    
                    optimizationTab
                        .tag(4)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .navigationTitle("Performance Optimization")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Run Optimization") {
                        Task {
                            await runOptimization()
                        }
                    }
                    .disabled(optimizationStrategy.optimizationStatus == .optimizing)
                }
            }
        }
        .onAppear {
            optimizationStrategy.startRealTimeMonitoring()
        }
        .onDisappear {
            optimizationStrategy.stopRealTimeMonitoring()
        }
        .sheet(isPresented: $showingOptimizationDetails) {
            if let optimization = selectedOptimization {
                OptimizationDetailView(optimization: optimization)
            }
        }
    }
    
    // MARK: - Header View
    
    private var headerView: some View {
        VStack(spacing: 16) {
            // Status Card
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Optimization Status")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(statusText)
                        .font(.headline)
                        .foregroundColor(statusColor)
                }
                
                Spacer()
                
                // Progress Indicator
                if optimizationStrategy.optimizationStatus == .optimizing {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: statusIcon)
                        .font(.title2)
                        .foregroundColor(statusColor)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            
            // Quick Metrics
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                MetricCard(
                    title: "CPU Usage",
                    value: "\(Int(optimizationStrategy.performanceReport.currentMetrics.cpuUsage * 100))%",
                    color: cpuUsageColor
                )
                
                MetricCard(
                    title: "Memory",
                    value: "\(Int(optimizationStrategy.performanceReport.currentMetrics.memoryUsage * 100))%",
                    color: memoryUsageColor
                )
                
                MetricCard(
                    title: "Energy",
                    value: "\(Int(optimizationStrategy.energyMetrics.currentConsumption * 100))%",
                    color: energyUsageColor
                )
            }
        }
        .padding()
    }
    
    // MARK: - Tab Selection
    
    private var tabSelectionView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(tabItems, id: \.title) { tab in
                    Button(action: {
                        selectedTab = tab.index
                    }) {
                        VStack(spacing: 4) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 20))
                            
                            Text(tab.title)
                                .font(.caption)
                        }
                        .foregroundColor(selectedTab == tab.index ? .primary : .secondary)
                        .frame(width: 80, height: 60)
                        .background(selectedTab == tab.index ? Color.accentColor.opacity(0.1) : Color.clear)
                        .cornerRadius(8)
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Overview Tab
    
    private var overviewTab: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Performance Chart
                performanceChartView
                
                // Recent Optimizations
                recentOptimizationsView
                
                // System Health
                systemHealthView
            }
            .padding()
        }
    }
    
    private var performanceChartView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Performance Trends")
                .font(.headline)
            
            Chart {
                LineMark(
                    x: .value("Time", Date()),
                    y: .value("CPU", optimizationStrategy.performanceReport.currentMetrics.cpuUsage * 100)
                )
                .foregroundStyle(.blue)
                .symbol(.circle)
                
                LineMark(
                    x: .value("Time", Date()),
                    y: .value("Memory", optimizationStrategy.performanceReport.currentMetrics.memoryUsage * 100)
                )
                .foregroundStyle(.green)
                .symbol(.square)
                
                LineMark(
                    x: .value("Time", Date()),
                    y: .value("Energy", optimizationStrategy.energyMetrics.currentConsumption * 100)
                )
                .foregroundStyle(.orange)
                .symbol(.diamond)
            }
            .frame(height: 200)
            .chartYScale(domain: 0...100)
            .chartYAxis {
                AxisMarks(position: .leading) {
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel(format: .percent)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var recentOptimizationsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Optimizations")
                .font(.headline)
            
            ForEach(optimizationStrategy.optimizationRecommendations.prefix(3), id: \.id) { recommendation in
                OptimizationCard(recommendation: recommendation) {
                    selectedOptimization = recommendation
                    showingOptimizationDetails = true
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var systemHealthView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("System Health")
                .font(.headline)
            
            HStack {
                HealthIndicator(
                    title: "Memory Leaks",
                    count: optimizationStrategy.memoryLeaks.count,
                    severity: optimizationStrategy.memoryLeaks.isEmpty ? .good : .warning
                )
                
                HealthIndicator(
                    title: "Launch Time",
                    value: optimizationStrategy.launchMetrics.launchTime,
                    unit: "s",
                    severity: optimizationStrategy.launchMetrics.launchTime < 3.0 ? .good : .warning
                )
                
                HealthIndicator(
                    title: "Battery",
                    value: optimizationStrategy.energyMetrics.batteryLevel,
                    unit: "%",
                    severity: optimizationStrategy.energyMetrics.batteryLevel > 0.2 ? .good : .critical
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Profiling Tab
    
    private var profilingTab: some View {
        ScrollView {
            VStack(spacing: 20) {
                // CPU Profile
                cpuProfileView
                
                // GPU Profile
                gpuProfileView
                
                // I/O Profile
                ioProfileView
            }
            .padding()
        }
    }
    
    private var cpuProfileView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("CPU Profile")
                .font(.headline)
            
            VStack(spacing: 8) {
                ProfileMetricRow(
                    title: "Usage",
                    value: "\(Int(optimizationStrategy.performanceReport.profilingResults.cpuProfile.usage * 100))%",
                    color: .blue
                )
                
                ProfileMetricRow(
                    title: "Cores",
                    value: "\(optimizationStrategy.performanceReport.profilingResults.cpuProfile.cores)",
                    color: .green
                )
                
                ProfileMetricRow(
                    title: "Frequency",
                    value: "\(Int(optimizationStrategy.performanceReport.profilingResults.cpuProfile.frequency)) MHz",
                    color: .orange
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var gpuProfileView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("GPU Profile")
                .font(.headline)
            
            VStack(spacing: 8) {
                ProfileMetricRow(
                    title: "Usage",
                    value: "\(Int(optimizationStrategy.performanceReport.profilingResults.gpuProfile.usage * 100))%",
                    color: .purple
                )
                
                ProfileMetricRow(
                    title: "Memory",
                    value: "\(optimizationStrategy.performanceReport.profilingResults.gpuProfile.memory / 1024 / 1024) MB",
                    color: .red
                )
                
                ProfileMetricRow(
                    title: "Temperature",
                    value: "\(Int(optimizationStrategy.performanceReport.profilingResults.gpuProfile.temperature))°C",
                    color: .orange
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var ioProfileView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("I/O Profile")
                .font(.headline)
            
            VStack(spacing: 8) {
                ProfileMetricRow(
                    title: "Read",
                    value: "\(optimizationStrategy.performanceReport.profilingResults.ioProfile.readBytes / 1024 / 1024) MB",
                    color: .blue
                )
                
                ProfileMetricRow(
                    title: "Write",
                    value: "\(optimizationStrategy.performanceReport.profilingResults.ioProfile.writeBytes / 1024 / 1024) MB",
                    color: .green
                )
                
                ProfileMetricRow(
                    title: "Operations",
                    value: "\(optimizationStrategy.performanceReport.profilingResults.ioProfile.operations)",
                    color: .orange
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Memory Tab
    
    private var memoryTab: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Memory Usage Chart
                memoryUsageChartView
                
                // Memory Leaks
                memoryLeaksView
                
                // Memory Growth
                memoryGrowthView
            }
            .padding()
        }
    }
    
    private var memoryUsageChartView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Memory Usage")
                .font(.headline)
            
            Chart {
                BarMark(
                    x: .value("Type", "Used"),
                    y: .value("Memory", optimizationStrategy.performanceReport.profilingResults.memoryProfile.used / 1024 / 1024)
                )
                .foregroundStyle(.blue)
                
                BarMark(
                    x: .value("Type", "Available"),
                    y: .value("Memory", optimizationStrategy.performanceReport.profilingResults.memoryProfile.available / 1024 / 1024)
                )
                .foregroundStyle(.green)
            }
            .frame(height: 200)
            .chartYAxis {
                AxisMarks(position: .leading) {
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel(format: .number)
                }
            }
            .chartXAxis {
                AxisMarks { _ in
                    AxisValueLabel()
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var memoryLeaksView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Memory Leaks")
                .font(.headline)
            
            if optimizationStrategy.memoryLeaks.isEmpty {
                Text("No memory leaks detected")
                    .foregroundColor(.secondary)
                    .italic()
            } else {
                ForEach(optimizationStrategy.memoryLeaks, id: \.id) { leak in
                    MemoryLeakRow(leak: leak)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var memoryGrowthView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Memory Growth")
                .font(.headline)
            
            VStack(spacing: 8) {
                ProfileMetricRow(
                    title: "Growth Rate",
                    value: "\(optimizationStrategy.performanceReport.memoryResults.memoryGrowth.rate, specifier: "%.2f")%",
                    color: optimizationStrategy.performanceReport.memoryResults.memoryGrowth.rate < 0.05 ? .green : .red
                )
                
                ProfileMetricRow(
                    title: "Trend",
                    value: optimizationStrategy.performanceReport.memoryResults.memoryGrowth.trend,
                    color: .blue
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Energy Tab
    
    private var energyTab: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Energy Consumption Chart
                energyConsumptionChartView
                
                // Battery Status
                batteryStatusView
                
                // Background Tasks
                backgroundTasksView
            }
            .padding()
        }
    }
    
    private var energyConsumptionChartView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Energy Consumption")
                .font(.headline)
            
            Chart {
                LineMark(
                    x: .value("Time", Date()),
                    y: .value("Consumption", optimizationStrategy.energyMetrics.currentConsumption * 100)
                )
                .foregroundStyle(.orange)
                .symbol(.circle)
            }
            .frame(height: 200)
            .chartYScale(domain: 0...100)
            .chartYAxis {
                AxisMarks(position: .leading) {
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel(format: .percent)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var batteryStatusView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Battery Status")
                .font(.headline)
            
            VStack(spacing: 8) {
                ProfileMetricRow(
                    title: "Level",
                    value: "\(Int(optimizationStrategy.energyMetrics.batteryLevel * 100))%",
                    color: batteryLevelColor
                )
                
                ProfileMetricRow(
                    title: "Charging",
                    value: optimizationStrategy.energyMetrics.isCharging ? "Yes" : "No",
                    color: optimizationStrategy.energyMetrics.isCharging ? .green : .orange
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var backgroundTasksView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Background Tasks")
                .font(.headline)
            
            if optimizationStrategy.performanceReport.energyResults.backgroundTasks.isEmpty {
                Text("No background tasks detected")
                    .foregroundColor(.secondary)
                    .italic()
            } else {
                ForEach(optimizationStrategy.performanceReport.energyResults.backgroundTasks, id: \.name) { task in
                    BackgroundTaskRow(task: task)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Optimization Tab
    
    private var optimizationTab: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Optimization Recommendations
                optimizationRecommendationsView
                
                // Optimization History
                optimizationHistoryView
            }
            .padding()
        }
    }
    
    private var optimizationRecommendationsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Optimization Recommendations")
                .font(.headline)
            
            if optimizationStrategy.optimizationRecommendations.isEmpty {
                Text("No optimization recommendations")
                    .foregroundColor(.secondary)
                    .italic()
            } else {
                ForEach(optimizationStrategy.optimizationRecommendations, id: \.id) { recommendation in
                    OptimizationCard(recommendation: recommendation) {
                        selectedOptimization = recommendation
                        showingOptimizationDetails = true
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var optimizationHistoryView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Optimization History")
                .font(.headline)
            
            // Placeholder for optimization history
            Text("No optimization history available")
                .foregroundColor(.secondary)
                .italic()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Helper Methods
    
    private func runOptimization() async {
        do {
            let result = try await optimizationStrategy.executeOptimizationStrategy()
            print("Optimization completed: \(result.success)")
        } catch {
            print("Optimization failed: \(error)")
        }
    }
    
    // MARK: - Computed Properties
    
    private var statusText: String {
        switch optimizationStrategy.optimizationStatus {
        case .idle:
            return "Ready"
        case .analyzing:
            return "Analyzing"
        case .optimizing:
            return "Optimizing"
        case .completed:
            return "Completed"
        case .failed:
            return "Failed"
        }
    }
    
    private var statusColor: Color {
        switch optimizationStrategy.optimizationStatus {
        case .idle, .completed:
            return .green
        case .analyzing, .optimizing:
            return .orange
        case .failed:
            return .red
        }
    }
    
    private var statusIcon: String {
        switch optimizationStrategy.optimizationStatus {
        case .idle, .completed:
            return "checkmark.circle.fill"
        case .analyzing, .optimizing:
            return "gear"
        case .failed:
            return "xmark.circle.fill"
        }
    }
    
    private var cpuUsageColor: Color {
        let usage = optimizationStrategy.performanceReport.currentMetrics.cpuUsage
        return usage > 0.8 ? .red : usage > 0.6 ? .orange : .green
    }
    
    private var memoryUsageColor: Color {
        let usage = optimizationStrategy.performanceReport.currentMetrics.memoryUsage
        return usage > 0.8 ? .red : usage > 0.6 ? .orange : .green
    }
    
    private var energyUsageColor: Color {
        let usage = optimizationStrategy.energyMetrics.currentConsumption
        return usage > 0.8 ? .red : usage > 0.6 ? .orange : .green
    }
    
    private var batteryLevelColor: Color {
        let level = optimizationStrategy.energyMetrics.batteryLevel
        return level > 0.5 ? .green : level > 0.2 ? .orange : .red
    }
    
    private var tabItems: [TabItem] {
        [
            TabItem(title: "Overview", icon: "chart.bar.fill", index: 0),
            TabItem(title: "Profiling", icon: "speedometer", index: 1),
            TabItem(title: "Memory", icon: "memorychip", index: 2),
            TabItem(title: "Energy", icon: "battery.100", index: 3),
            TabItem(title: "Optimize", icon: "wrench.and.screwdriver.fill", index: 4)
        ]
    }
}

// MARK: - Supporting Views

struct TabItem {
    let title: String
    let icon: String
    let index: Int
}

struct MetricCard: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

struct OptimizationCard: View {
    let recommendation: OptimizationRecommendation
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(recommendation.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Text(recommendation.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
                
                HStack {
                    PriorityBadge(priority: recommendation.priority)
                    ImpactBadge(impact: recommendation.impact)
                    Spacer()
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct PriorityBadge: View {
    let priority: OptimizationRecommendation.Priority
    
    var body: some View {
        Text(priorityText)
            .font(.caption2)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(priorityColor.opacity(0.2))
            .foregroundColor(priorityColor)
            .cornerRadius(4)
    }
    
    private var priorityText: String {
        switch priority {
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        case .critical: return "Critical"
        }
    }
    
    private var priorityColor: Color {
        switch priority {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        case .critical: return .purple
        }
    }
}

struct ImpactBadge: View {
    let impact: OptimizationRecommendation.Impact
    
    var body: some View {
        Text(impactText)
            .font(.caption2)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(impactColor.opacity(0.2))
            .foregroundColor(impactColor)
            .cornerRadius(4)
    }
    
    private var impactText: String {
        switch impact {
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        case .critical: return "Critical"
        }
    }
    
    private var impactColor: Color {
        switch impact {
        case .low: return .blue
        case .medium: return .orange
        case .high: return .red
        case .critical: return .purple
        }
    }
}

struct HealthIndicator: View {
    let title: String
    var count: Int? = nil
    var value: Double? = nil
    var unit: String? = nil
    let severity: HealthSeverity
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            if let count = count {
                Text("\(count)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(severityColor)
            } else if let value = value, let unit = unit {
                Text("\(value, specifier: "%.1f")\(unit)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(severityColor)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(severityColor.opacity(0.1))
        .cornerRadius(8)
    }
    
    private var severityColor: Color {
        switch severity {
        case .good: return .green
        case .warning: return .orange
        case .critical: return .red
        }
    }
}

enum HealthSeverity {
    case good, warning, critical
}

struct ProfileMetricRow: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(color)
        }
    }
}

struct MemoryLeakRow: View {
    let leak: MemoryLeak
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(leak.description)
                .font(.caption)
                .foregroundColor(.primary)
            
            Text("Severity: \(leak.severity)")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct BackgroundTaskRow: View {
    let task: BackgroundTask
    
    var body: some View {
        HStack {
            Text(task.name)
                .font(.caption)
                .foregroundColor(.primary)
            
            Spacer()
            
            Text("\(task.energyImpact, specifier: "%.2f")")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 2)
    }
}

struct OptimizationDetailView: View {
    let optimization: OptimizationRecommendation
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text(optimization.title)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text(optimization.description)
                            .font(.body)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            PriorityBadge(priority: optimization.priority)
                            ImpactBadge(impact: optimization.impact)
                        }
                    }
                    
                    // Implementation Steps
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Implementation Steps")
                            .font(.headline)
                        
                        ForEach(optimization.implementation, id: \.self) { step in
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "circle.fill")
                                    .font(.system(size: 6))
                                    .foregroundColor(.accentColor)
                                    .padding(.top, 6)
                                
                                Text(step)
                                    .font(.body)
                                    .foregroundColor(.primary)
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Optimization Details")
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
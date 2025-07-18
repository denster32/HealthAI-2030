import SwiftUI
import Charts

/// UX Engagement Orchestrator Dashboard
/// Provides real-time monitoring and control of all UX engagement systems
@available(iOS 18.0, macOS 15.0, *)
public struct UXEngagementOrchestratorDashboard: View {
    
    // MARK: - Properties
    @StateObject private var viewModel = UXEngagementOrchestratorDashboardViewModel()
    @State private var selectedTab: OrchestratorTab = .overview
    @State private var showingSystemDetails = false
    @State private var selectedSystem: String = ""
    @State private var showingExportOptions = false
    @State private var exportFormat: ExportFormat = .json
    
    // MARK: - Body
    public var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Tab Selector
                tabSelectorView
                
                // Content
                TabView(selection: $selectedTab) {
                    overviewTab
                        .tag(OrchestratorTab.overview)
                    
                    systemsTab
                        .tag(OrchestratorTab.systems)
                    
                    metricsTab
                        .tag(OrchestratorTab.metrics)
                    
                    analyticsTab
                        .tag(OrchestratorTab.analytics)
                    
                    coordinationTab
                        .tag(OrchestratorTab.coordination)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .navigationTitle("UX Engagement Orchestrator")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    exportButton
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    refreshButton
                }
            }
            .sheet(isPresented: $showingSystemDetails) {
                systemDetailsView
            }
            .sheet(isPresented: $showingExportOptions) {
                exportOptionsView
            }
            .onAppear {
                viewModel.startOrchestrator()
            }
            .onDisappear {
                viewModel.stopOrchestrator()
            }
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        VStack(spacing: 16) {
            // Status Card
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Orchestrator Status")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Circle()
                            .fill(viewModel.orchestratorStatus.color)
                            .frame(width: 12, height: 12)
                        
                        Text(viewModel.orchestratorStatus.displayName)
                            .font(.title2)
                            .fontWeight(.semibold)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 8) {
                    Text("Active Systems")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("\(viewModel.activeSystemsCount)/7")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            
            // Quick Actions
            HStack(spacing: 12) {
                Button(action: viewModel.startOrchestrator) {
                    Label("Start", systemImage: "play.fill")
                        .font(.caption)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                
                Button(action: viewModel.stopOrchestrator) {
                    Label("Stop", systemImage: "stop.fill")
                        .font(.caption)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                
                Button(action: viewModel.refreshData) {
                    Label("Refresh", systemImage: "arrow.clockwise")
                        .font(.caption)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                
                Spacer()
            }
        }
        .padding(.horizontal)
    }
    
    // MARK: - Tab Selector
    private var tabSelectorView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(OrchestratorTab.allCases, id: \.self) { tab in
                    Button(action: { selectedTab = tab }) {
                        VStack(spacing: 4) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 20))
                            
                            Text(tab.title)
                                .font(.caption)
                        }
                        .foregroundColor(selectedTab == tab ? .white : .primary)
                        .frame(width: 80, height: 60)
                        .background(selectedTab == tab ? Color.blue : Color.clear)
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
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                // System Health Overview
                systemHealthCard
                
                // Engagement Metrics Overview
                engagementMetricsCard
                
                // Recent Activity
                recentActivityCard
                
                // Performance Overview
                performanceCard
            }
            .padding()
        }
    }
    
    // MARK: - Systems Tab
    private var systemsTab: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(viewModel.systemCards, id: \.name) { system in
                    systemCard(system)
                }
            }
            .padding()
        }
    }
    
    // MARK: - Metrics Tab
    private var metricsTab: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Engagement Trends Chart
                engagementTrendsChart
                
                // System Performance Chart
                systemPerformanceChart
                
                // User Activity Chart
                userActivityChart
            }
            .padding()
        }
    }
    
    // MARK: - Analytics Tab
    private var analyticsTab: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Orchestrator Analytics
                orchestratorAnalyticsCard
                
                // Pattern Analysis
                patternAnalysisCard
                
                // Insights
                insightsCard
            }
            .padding()
        }
    }
    
    // MARK: - Coordination Tab
    private var coordinationTab: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Coordination Status
                coordinationStatusCard
                
                // System Communication
                systemCommunicationCard
                
                // Optimization Status
                optimizationStatusCard
            }
            .padding()
        }
    }
    
    // MARK: - System Card
    private func systemCard(_ system: SystemCard) -> some View {
        Button(action: {
            selectedSystem = system.name
            showingSystemDetails = true
        }) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: system.icon)
                        .font(.title2)
                        .foregroundColor(system.status.color)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(system.name)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text(system.status.displayName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("\(system.metrics)")
                            .font(.title3)
                            .fontWeight(.bold)
                        
                        Text(system.metricLabel)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Progress Bar
                ProgressView(value: system.progress)
                    .progressViewStyle(LinearProgressViewStyle(tint: system.status.color))
                
                HStack {
                    Text("Uptime: \(String(format: "%.1f", system.uptime))%")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("Response: \(String(format: "%.1f", system.responseTime))s")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - System Health Card
    private var systemHealthCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "heart.fill")
                    .foregroundColor(.green)
                
                Text("System Health")
                    .font(.headline)
                
                Spacer()
                
                Text("\(String(format: "%.1f", viewModel.systemHealth.overallHealth.uptime * 100))%")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.green)
            }
            
            VStack(spacing: 8) {
                healthRow("Navigation", value: viewModel.systemHealth.navigationHealth.uptime)
                healthRow("Gamification", value: viewModel.systemHealth.gamificationHealth.uptime)
                healthRow("Social", value: viewModel.systemHealth.socialHealth.uptime)
                healthRow("AI", value: viewModel.systemHealth.aiOrchestrationHealth.uptime)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func healthRow(_ name: String, value: Double) -> some View {
        HStack {
            Text(name)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            ProgressView(value: value)
                .progressViewStyle(LinearProgressViewStyle(tint: .green))
                .frame(width: 60)
            
            Text("\(String(format: "%.0f", value * 100))%")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Engagement Metrics Card
    private var engagementMetricsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundColor(.blue)
                
                Text("Engagement")
                    .font(.headline)
                
                Spacer()
                
                Text("\(String(format: "%.0f", viewModel.engagementMetrics.overallMetrics.averageEngagement * 100))%")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
            }
            
            VStack(spacing: 8) {
                metricRow("Total Engagement", value: "\(viewModel.engagementMetrics.overallMetrics.totalEngagement)")
                metricRow("User Retention", value: "\(String(format: "%.1f", viewModel.engagementMetrics.overallMetrics.userRetention * 100))%")
                metricRow("Active Users", value: "\(viewModel.engagementMetrics.gamificationMetrics.activeUsers)")
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func metricRow(_ name: String, value: String) -> some View {
        HStack {
            Text(name)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
        }
    }
    
    // MARK: - Recent Activity Card
    private var recentActivityCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "clock.fill")
                    .foregroundColor(.orange)
                
                Text("Recent Activity")
                    .font(.headline)
                
                Spacer()
            }
            
            VStack(spacing: 8) {
                ForEach(viewModel.recentActivities.prefix(3), id: \.id) { activity in
                    HStack {
                        Circle()
                            .fill(activity.type.color)
                            .frame(width: 8, height: 8)
                        
                        Text(activity.description)
                            .font(.caption)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        Text(activity.timestamp, style: .relative)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Performance Card
    private var performanceCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "speedometer")
                    .foregroundColor(.purple)
                
                Text("Performance")
                    .font(.headline)
                
                Spacer()
                
                Text("\(String(format: "%.1f", viewModel.orchestratorAnalytics.averageResponseTime))s")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.purple)
            }
            
            VStack(spacing: 8) {
                performanceRow("Avg Response", value: viewModel.orchestratorAnalytics.averageResponseTime)
                performanceRow("Active Systems", value: Double(viewModel.orchestratorAnalytics.activeSystems))
                performanceRow("Efficiency", value: 0.85) // Placeholder
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func performanceRow(_ name: String, value: Double) -> some View {
        HStack {
            Text(name)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(name == "Avg Response" ? "\(String(format: "%.1f", value))s" : "\(Int(value))")
                .font(.caption)
                .fontWeight(.medium)
        }
    }
    
    // MARK: - Charts
    private var engagementTrendsChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Engagement Trends")
                .font(.headline)
            
            Chart {
                ForEach(viewModel.engagementTrends, id: \.date) { trend in
                    LineMark(
                        x: .value("Date", trend.date),
                        y: .value("Engagement", trend.value)
                    )
                    .foregroundStyle(.blue)
                }
            }
            .frame(height: 200)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var systemPerformanceChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("System Performance")
                .font(.headline)
            
            Chart {
                ForEach(viewModel.systemPerformance, id: \.system) { performance in
                    BarMark(
                        x: .value("System", performance.system),
                        y: .value("Performance", performance.value)
                    )
                    .foregroundStyle(.green)
                }
            }
            .frame(height: 200)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var userActivityChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("User Activity")
                .font(.headline)
            
            Chart {
                ForEach(viewModel.userActivity, id: \.hour) { activity in
                    AreaMark(
                        x: .value("Hour", activity.hour),
                        y: .value("Activity", activity.value)
                    )
                    .foregroundStyle(.orange.opacity(0.3))
                }
            }
            .frame(height: 200)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Analytics Cards
    private var orchestratorAnalyticsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(.blue)
                
                Text("Orchestrator Analytics")
                    .font(.headline)
                
                Spacer()
            }
            
            VStack(spacing: 8) {
                analyticsRow("Total Systems", value: "\(viewModel.orchestratorAnalytics.totalSystems)")
                analyticsRow("Active Systems", value: "\(viewModel.orchestratorAnalytics.activeSystems)")
                analyticsRow("Avg Response Time", value: "\(String(format: "%.1f", viewModel.orchestratorAnalytics.averageResponseTime))s")
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func analyticsRow(_ name: String, value: String) -> some View {
        HStack {
            Text(name)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
        }
    }
    
    private var patternAnalysisCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .foregroundColor(.purple)
                
                Text("Pattern Analysis")
                    .font(.headline)
                
                Spacer()
            }
            
            VStack(spacing: 8) {
                patternRow("Current Trend", value: viewModel.orchestratorAnalytics.orchestrationPatterns.trends.currentTrend)
                patternRow("Efficiency", value: "\(String(format: "%.1f", viewModel.orchestratorAnalytics.orchestrationPatterns.trends.coordinationEfficiency * 100))%")
                patternRow("Patterns Found", value: "\(viewModel.orchestratorAnalytics.orchestrationPatterns.patterns.count)")
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func patternRow(_ name: String, value: String) -> some View {
        HStack {
            Text(name)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
        }
    }
    
    private var insightsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
                
                Text("Insights")
                    .font(.headline)
                
                Spacer()
            }
            
            VStack(spacing: 8) {
                ForEach(viewModel.orchestratorAnalytics.insights.prefix(3), id: \.id) { insight in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(insight.title)
                            .font(.caption)
                            .fontWeight(.medium)
                        
                        Text(insight.description)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Coordination Cards
    private var coordinationStatusCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "network")
                    .foregroundColor(.green)
                
                Text("Coordination Status")
                    .font(.headline)
                
                Spacer()
                
                Text("Active")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(4)
            }
            
            VStack(spacing: 8) {
                coordinationRow("Systems Coordinated", value: "7/7")
                coordinationRow("Communication", value: "Healthy")
                coordinationRow("Synchronization", value: "Active")
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func coordinationRow(_ name: String, value: String) -> some View {
        HStack {
            Text(name)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
        }
    }
    
    private var systemCommunicationCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "message.fill")
                    .foregroundColor(.blue)
                
                Text("System Communication")
                    .font(.headline)
                
                Spacer()
            }
            
            VStack(spacing: 8) {
                communicationRow("Messages/sec", value: "150")
                communicationRow("Latency", value: "5ms")
                communicationRow("Success Rate", value: "99.9%")
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func communicationRow(_ name: String, value: String) -> some View {
        HStack {
            Text(name)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
        }
    }
    
    private var optimizationStatusCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "gearshape.fill")
                    .foregroundColor(.orange)
                
                Text("Optimization Status")
                    .font(.headline)
                
                Spacer()
            }
            
            VStack(spacing: 8) {
                optimizationRow("Auto-Optimization", value: "Enabled")
                optimizationRow("Last Optimization", value: "2 min ago")
                optimizationRow("Performance Gain", value: "+15%")
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func optimizationRow(_ name: String, value: String) -> some View {
        HStack {
            Text(name)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
        }
    }
    
    // MARK: - System Details View
    private var systemDetailsView: some View {
        NavigationView {
            VStack {
                Text("System Details: \(selectedSystem)")
                    .font(.headline)
                    .padding()
                
                Spacer()
                
                Text("Detailed system information and controls will be implemented here.")
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .navigationTitle("System Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        showingSystemDetails = false
                    }
                }
            }
        }
    }
    
    // MARK: - Export Options View
    private var exportOptionsView: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Export Orchestrator Data")
                    .font(.headline)
                
                VStack(spacing: 12) {
                    ForEach(ExportFormat.allCases, id: \.self) { format in
                        Button(action: {
                            exportFormat = format
                            viewModel.exportData(format: format)
                            showingExportOptions = false
                        }) {
                            HStack {
                                Image(systemName: format.icon)
                                    .foregroundColor(.blue)
                                
                                Text(format.displayName)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        }
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Export Options")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        showingExportOptions = false
                    }
                }
            }
        }
    }
    
    // MARK: - Toolbar Buttons
    private var exportButton: some View {
        Button(action: { showingExportOptions = true }) {
            Image(systemName: "square.and.arrow.up")
        }
    }
    
    private var refreshButton: some View {
        Button(action: viewModel.refreshData) {
            Image(systemName: "arrow.clockwise")
        }
    }
}

// MARK: - Supporting Types

public enum OrchestratorTab: CaseIterable {
    case overview, systems, metrics, analytics, coordination
    
    var title: String {
        switch self {
        case .overview: return "Overview"
        case .systems: return "Systems"
        case .metrics: return "Metrics"
        case .analytics: return "Analytics"
        case .coordination: return "Coordination"
        }
    }
    
    var icon: String {
        switch self {
        case .overview: return "chart.pie.fill"
        case .systems: return "gearshape.2.fill"
        case .metrics: return "chart.line.uptrend.xyaxis"
        case .analytics: return "brain.head.profile"
        case .coordination: return "network"
        }
    }
}

public struct SystemCard {
    public let name: String
    public let icon: String
    public let status: SystemStatus
    public let metrics: Int
    public let metricLabel: String
    public let progress: Double
    public let uptime: Double
    public let responseTime: TimeInterval
}

public enum SystemStatus {
    case active, inactive, error, warning
    
    var displayName: String {
        switch self {
        case .active: return "Active"
        case .inactive: return "Inactive"
        case .error: return "Error"
        case .warning: return "Warning"
        }
    }
    
    var color: Color {
        switch self {
        case .active: return .green
        case .inactive: return .gray
        case .error: return .red
        case .warning: return .orange
        }
    }
}

public struct RecentActivity: Identifiable {
    public let id = UUID()
    public let description: String
    public let type: ActivityType
    public let timestamp: Date
}

public enum ActivityType {
    case navigation, gamification, social, personalization, ai
    
    var color: Color {
        switch self {
        case .navigation: return .blue
        case .gamification: return .green
        case .social: return .purple
        case .personalization: return .orange
        case .ai: return .red
        }
    }
}

public struct EngagementTrend: Identifiable {
    public let id = UUID()
    public let date: Date
    public let value: Double
}

public struct SystemPerformance: Identifiable {
    public let id = UUID()
    public let system: String
    public let value: Double
}

public struct UserActivity: Identifiable {
    public let id = UUID()
    public let hour: Int
    public let value: Double
}

public enum ExportFormat: CaseIterable {
    case json, csv, xml
    
    var displayName: String {
        switch self {
        case .json: return "JSON Format"
        case .csv: return "CSV Format"
        case .xml: return "XML Format"
        }
    }
    
    var icon: String {
        switch self {
        case .json: return "doc.text"
        case .csv: return "tablecells"
        case .xml: return "doc.richtext"
        }
    }
}

public enum OrchestrationStatus {
    case idle, starting, active, stopping, stopped, error
    
    var displayName: String {
        switch self {
        case .idle: return "Idle"
        case .starting: return "Starting"
        case .active: return "Active"
        case .stopping: return "Stopping"
        case .stopped: return "Stopped"
        case .error: return "Error"
        }
    }
    
    var color: Color {
        switch self {
        case .idle: return .gray
        case .starting: return .orange
        case .active: return .green
        case .stopping: return .orange
        case .stopped: return .red
        case .error: return .red
        }
    }
}

// MARK: - Preview
@available(iOS 18.0, macOS 15.0, *)
struct UXEngagementOrchestratorDashboard_Previews: PreviewProvider {
    static var previews: some View {
        UXEngagementOrchestratorDashboard()
    }
} 
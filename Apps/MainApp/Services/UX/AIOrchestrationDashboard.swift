import SwiftUI
import Combine

/// AI Orchestration Dashboard View
/// Provides real-time monitoring, service status, and performance analytics for the AI orchestration system
@available(iOS 18.0, macOS 15.0, *)
public struct AIOrchestrationDashboard: View {
    
    // MARK: - Properties
    @StateObject private var viewModel = AIOrchestrationDashboardViewModel()
    @State private var selectedTab = 0
    @State private var showingServiceDetails = false
    @State private var selectedService: AIService?
    
    // MARK: - Body
    public var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Tab Content
                TabView(selection: $selectedTab) {
                    // Overview Tab
                    overviewTab
                        .tag(0)
                    
                    // Services Tab
                    servicesTab
                        .tag(1)
                    
                    // Insights Tab
                    insightsTab
                        .tag(2)
                    
                    // Predictions Tab
                    predictionsTab
                        .tag(3)
                    
                    // Performance Tab
                    performanceTab
                        .tag(4)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .navigationBarHidden(true)
            .background(Color(.systemGroupedBackground))
        }
        .onAppear {
            viewModel.startMonitoring()
        }
        .onDisappear {
            viewModel.stopMonitoring()
        }
        .sheet(isPresented: $showingServiceDetails) {
            if let service = selectedService {
                ServiceDetailView(service: service)
            }
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("AI Orchestration")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("Advanced AI Services Management")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Status Indicator
                statusIndicator
            }
            
            // Progress Bar
            progressBar
            
            // Quick Stats
            quickStatsView
        }
        .padding()
        .background(Color(.systemBackground))
    }
    
    // MARK: - Status Indicator
    private var statusIndicator: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(viewModel.orchestrationStatus.color)
                .frame(width: 12, height: 12)
            
            Text(viewModel.orchestrationStatus.displayName)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(viewModel.orchestrationStatus.color)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(viewModel.orchestrationStatus.color.opacity(0.1))
        .cornerRadius(8)
    }
    
    // MARK: - Progress Bar
    private var progressBar: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("System Progress")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(Int(viewModel.orchestrationProgress * 100))%")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }
            
            ProgressView(value: viewModel.orchestrationProgress)
                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                .scaleEffect(y: 2)
        }
    }
    
    // MARK: - Quick Stats View
    private var quickStatsView: some View {
        HStack(spacing: 16) {
            QuickStatCard(
                title: "Active Services",
                value: "\(viewModel.activeServices.count)",
                icon: "server.rack",
                color: .green
            )
            
            QuickStatCard(
                title: "AI Insights",
                value: "\(viewModel.aiInsights.count)",
                icon: "lightbulb",
                color: .orange
            )
            
            QuickStatCard(
                title: "Predictions",
                value: "\(viewModel.aiPredictions.count)",
                icon: "chart.line.uptrend.xyaxis",
                color: .purple
            )
            
            QuickStatCard(
                title: "Response Time",
                value: String(format: "%.1fs", viewModel.aiPerformance.averageResponseTime),
                icon: "speedometer",
                color: .blue
            )
        }
    }
    
    // MARK: - Overview Tab
    private var overviewTab: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                // System Health Card
                systemHealthCard
                
                // Recent Activity Card
                recentActivityCard
                
                // Service Performance Card
                servicePerformanceCard
                
                // AI Insights Summary Card
                aiInsightsSummaryCard
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }
    
    // MARK: - System Health Card
    private var systemHealthCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "heart.fill")
                    .foregroundColor(.red)
                Text("System Health")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            VStack(spacing: 12) {
                HealthMetricRow(
                    label: "Service Uptime",
                    value: String(format: "%.1f%%", viewModel.aiPerformance.serviceUptime * 100),
                    color: viewModel.aiPerformance.serviceUptime > 0.95 ? .green : .orange
                )
                
                HealthMetricRow(
                    label: "Error Rate",
                    value: String(format: "%.2f%%", viewModel.aiPerformance.errorRate * 100),
                    color: viewModel.aiPerformance.errorRate < 0.05 ? .green : .red
                )
                
                HealthMetricRow(
                    label: "Throughput",
                    value: "\(viewModel.aiPerformance.throughput) req/s",
                    color: .blue
                )
                
                HealthMetricRow(
                    label: "Accuracy",
                    value: String(format: "%.1f%%", viewModel.aiPerformance.accuracy * 100),
                    color: viewModel.aiPerformance.accuracy > 0.8 ? .green : .orange
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    // MARK: - Recent Activity Card
    private var recentActivityCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "clock.fill")
                    .foregroundColor(.blue)
                Text("Recent Activity")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            if viewModel.recentActivity.isEmpty {
                Text("No recent activity")
                    .foregroundColor(.secondary)
                    .italic()
            } else {
                VStack(spacing: 8) {
                    ForEach(viewModel.recentActivity.prefix(5), id: \.id) { activity in
                        ActivityRow(activity: activity)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    // MARK: - Service Performance Card
    private var servicePerformanceCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "gauge")
                    .foregroundColor(.purple)
                Text("Service Performance")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            VStack(spacing: 12) {
                ForEach(viewModel.serviceStatuses, id: \.id) { status in
                    ServiceStatusRow(status: status) {
                        selectedService = viewModel.activeServices.first { $0.name == status.serviceName }
                        showingServiceDetails = true
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    // MARK: - AI Insights Summary Card
    private var aiInsightsSummaryCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.orange)
                Text("AI Insights Summary")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            if viewModel.aiInsights.isEmpty {
                Text("No insights available")
                    .foregroundColor(.secondary)
                    .italic()
            } else {
                VStack(spacing: 8) {
                    ForEach(viewModel.aiInsights.prefix(3), id: \.id) { insight in
                        InsightRow(insight: insight)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    // MARK: - Services Tab
    private var servicesTab: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(viewModel.activeServices, id: \.id) { service in
                    ServiceCard(service: service) {
                        selectedService = service
                        showingServiceDetails = true
                    }
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }
    
    // MARK: - Insights Tab
    private var insightsTab: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(viewModel.aiInsights, id: \.id) { insight in
                    InsightCard(insight: insight)
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }
    
    // MARK: - Predictions Tab
    private var predictionsTab: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(viewModel.aiPredictions, id: \.id) { prediction in
                    PredictionCard(prediction: prediction)
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }
    
    // MARK: - Performance Tab
    private var performanceTab: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                // Performance Metrics Card
                performanceMetricsCard
                
                // Response Time Chart Card
                responseTimeChartCard
                
                // Error Rate Chart Card
                errorRateChartCard
                
                // Throughput Chart Card
                throughputChartCard
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }
    
    // MARK: - Performance Metrics Card
    private var performanceMetricsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(.blue)
                Text("Performance Metrics")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            VStack(spacing: 12) {
                PerformanceMetricRow(
                    label: "Average Response Time",
                    value: String(format: "%.2fs", viewModel.aiPerformance.averageResponseTime),
                    target: "1.0s",
                    color: viewModel.aiPerformance.averageResponseTime < 1.0 ? .green : .orange
                )
                
                PerformanceMetricRow(
                    label: "Latency",
                    value: String(format: "%.2fs", viewModel.aiPerformance.latency),
                    target: "0.5s",
                    color: viewModel.aiPerformance.latency < 0.5 ? .green : .orange
                )
                
                PerformanceMetricRow(
                    label: "Throughput",
                    value: "\(viewModel.aiPerformance.throughput) req/s",
                    target: "100 req/s",
                    color: viewModel.aiPerformance.throughput > 100 ? .green : .orange
                )
                
                PerformanceMetricRow(
                    label: "Accuracy",
                    value: String(format: "%.1f%%", viewModel.aiPerformance.accuracy * 100),
                    target: "90%",
                    color: viewModel.aiPerformance.accuracy > 0.9 ? .green : .orange
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    // MARK: - Response Time Chart Card
    private var responseTimeChartCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "speedometer")
                    .foregroundColor(.green)
                Text("Response Time Trend")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            // Placeholder for chart
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.blue.opacity(0.1))
                .frame(height: 200)
                .overlay(
                    Text("Response Time Chart")
                        .foregroundColor(.secondary)
                )
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    // MARK: - Error Rate Chart Card
    private var errorRateChartCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.red)
                Text("Error Rate Trend")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            // Placeholder for chart
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.red.opacity(0.1))
                .frame(height: 200)
                .overlay(
                    Text("Error Rate Chart")
                        .foregroundColor(.secondary)
                )
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    // MARK: - Throughput Chart Card
    private var throughputChartCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundColor(.purple)
                Text("Throughput Trend")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            // Placeholder for chart
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.purple.opacity(0.1))
                .frame(height: 200)
                .overlay(
                    Text("Throughput Chart")
                        .foregroundColor(.secondary)
                )
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Supporting Views

struct QuickStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 3, x: 0, y: 1)
    }
}

struct HealthMetricRow: View {
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
    }
}

struct ActivityRow: View {
    let activity: ActivityItem
    
    var body: some View {
        HStack {
            Image(systemName: activity.icon)
                .foregroundColor(activity.color)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(activity.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(activity.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(activity.timestamp, style: .relative)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct ServiceStatusRow: View {
    let status: AIServiceStatus
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(status.serviceName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text(status.status.rawValue.capitalized)
                        .font(.caption)
                        .foregroundColor(status.status.color)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(Int(status.performance.availability * 100))%")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text("Uptime")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct InsightRow: View {
    let insight: AIInsight
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(insight.title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            Text(insight.description)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)
            
            HStack {
                Text(insight.type.rawValue.capitalized)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(insight.type.color.opacity(0.1))
                    .foregroundColor(insight.type.color)
                    .cornerRadius(4)
                
                Spacer()
                
                Text("\(Int(insight.confidence * 100))%")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct ServiceCard: View {
    let service: AIService
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(service.name)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Text(service.type.rawValue.capitalized)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Circle()
                            .fill(service.status.color)
                            .frame(width: 12, height: 12)
                        
                        Text(service.status.rawValue.capitalized)
                            .font(.caption)
                            .foregroundColor(service.status.color)
                    }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Version \(service.version)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("Response Time: \(String(format: "%.2fs", service.performance.responseTime))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("Throughput: \(service.performance.throughput) req/s")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    ForEach(service.capabilities.prefix(3), id: \.name) { capability in
                        Text(capability.name)
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(capability.isEnabled ? Color.green.opacity(0.1) : Color.gray.opacity(0.1))
                            .foregroundColor(capability.isEnabled ? .green : .gray)
                            .cornerRadius(4)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct InsightCard: View {
    let insight: AIInsight
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(insight.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text(insight.category.rawValue.capitalized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(Int(insight.confidence * 100))%")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                    
                    Text("Confidence")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Text(insight.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(3)
            
            HStack {
                Text(insight.type.rawValue.capitalized)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(insight.type.color.opacity(0.1))
                    .foregroundColor(insight.type.color)
                    .cornerRadius(6)
                
                Text(insight.priority.rawValue.capitalized)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(insight.priority.color.opacity(0.1))
                    .foregroundColor(insight.priority.color)
                    .cornerRadius(6)
                
                Spacer()
                
                Text(insight.timestamp, style: .relative)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

struct PredictionCard: View {
    let prediction: AIPrediction
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(prediction.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text(prediction.category.rawValue.capitalized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(Int(prediction.confidence * 100))%")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.purple)
                    
                    Text("Confidence")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Text(prediction.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(3)
            
            HStack {
                Text(prediction.type.rawValue.capitalized)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(prediction.type.color.opacity(0.1))
                    .foregroundColor(prediction.type.color)
                    .cornerRadius(6)
                
                Text("\(prediction.timeHorizon) days")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .foregroundColor(.blue)
                    .cornerRadius(6)
                
                Text(prediction.impact.rawValue.capitalized)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(prediction.impact.color.opacity(0.1))
                    .foregroundColor(prediction.impact.color)
                    .cornerRadius(6)
                
                Spacer()
                
                Text(prediction.timestamp, style: .relative)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

struct PerformanceMetricRow: View {
    let label: String
    let value: String
    let target: String
    let color: Color
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(color)
                
                Text("Target: \(target)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Extensions

extension OrchestrationStatus {
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
}

extension ServiceStatus {
    var color: Color {
        switch self {
        case .active: return .green
        case .inactive: return .gray
        case .error: return .red
        case .maintenance: return .orange
        }
    }
}

extension InsightType {
    var color: Color {
        switch self {
        case .health: return .blue
        case .behavior: return .green
        case .pattern: return .orange
        case .recommendation: return .purple
        }
    }
}

extension PredictionType {
    var color: Color {
        switch self {
        case .health: return .blue
        case .behavior: return .green
        case .risk: return .red
        case .trend: return .purple
        }
    }
}

extension PredictionImpact {
    var color: Color {
        switch self {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        case .critical: return .purple
        }
    }
}

extension InsightPriority {
    var color: Color {
        switch self {
        case .high: return .red
        case .medium: return .orange
        case .low: return .green
        }
    }
}

// MARK: - Supporting Structures

struct ActivityItem: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let icon: String
    let color: Color
    let timestamp: Date
}

struct ServiceDetailView: View {
    let service: AIService
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Service Header
                    serviceHeader
                    
                    // Service Details
                    serviceDetails
                    
                    // Performance Metrics
                    performanceMetrics
                    
                    // Capabilities
                    capabilities
                }
                .padding()
            }
            .navigationTitle(service.name)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
    
    private var serviceHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(service.name)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(service.type.rawValue.capitalized)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Circle()
                        .fill(service.status.color)
                        .frame(width: 16, height: 16)
                    
                    Text(service.status.rawValue.capitalized)
                        .font(.caption)
                        .foregroundColor(service.status.color)
                }
            }
            
            Text("Version \(service.version)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
    
    private var serviceDetails: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Service Details")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                DetailRow(label: "Type", value: service.type.rawValue.capitalized)
                DetailRow(label: "Status", value: service.status.rawValue.capitalized)
                DetailRow(label: "Version", value: service.version)
                DetailRow(label: "Last Update", value: service.timestamp, style: .relative)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
    
    private var performanceMetrics: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Performance Metrics")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                DetailRow(label: "Response Time", value: String(format: "%.2fs", service.performance.responseTime))
                DetailRow(label: "Throughput", value: "\(service.performance.throughput) req/s")
                DetailRow(label: "Error Rate", value: String(format: "%.2f%%", service.performance.errorRate * 100))
                DetailRow(label: "Availability", value: String(format: "%.1f%%", service.performance.availability * 100))
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
    
    private var capabilities: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Capabilities")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                ForEach(service.capabilities, id: \.name) { capability in
                    CapabilityCard(capability: capability)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

struct DetailRow: View {
    let label: String
    let value: String
    var style: RelativeDateTimeFormatter.UnitsStyle = .abbreviated
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
}

struct CapabilityCard: View {
    let capability: ServiceCapability
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(capability.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Image(systemName: capability.isEnabled ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(capability.isEnabled ? .green : .red)
            }
            
            Text(capability.description)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)
            
            Text("v\(capability.version)")
                .font(.caption)
                .foregroundColor(.blue)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

// MARK: - Preview

struct AIOrchestrationDashboard_Previews: PreviewProvider {
    static var previews: some View {
        AIOrchestrationDashboard()
    }
} 
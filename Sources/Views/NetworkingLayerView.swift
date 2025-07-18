import SwiftUI
import Charts
import Combine

/// Comprehensive SwiftUI view for Networking Layer Management
/// Provides interface for monitoring network performance, managing requests, and configuring networking
public struct NetworkingLayerView: View {
    @StateObject private var networkingManager = NetworkingLayerManager.shared
    @State private var selectedTab = 0
    @State private var showingConfiguration = false
    @State private var showingRequestDetails = false
    @State private var showingPerformanceDetails = false
    @State private var searchText = ""
    @State private var selectedRequest: NetworkingLayerManager.NetworkRequest?
    @State private var refreshTimer: Timer?
    
    public init() {}
    
    public var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with network status
                headerView
                
                // Tab selection
                tabSelectionView
                
                // Content based on selected tab
                TabView(selection: $selectedTab) {
                    overviewTabView
                        .tag(0)
                    
                    requestsTabView
                        .tag(1)
                    
                    performanceTabView
                        .tag(2)
                    
                    configurationTabView
                        .tag(3)
                    
                    logsTabView
                        .tag(4)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .navigationTitle("Networking")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Configuration") {
                            showingConfiguration = true
                        }
                        
                        Button("Clear Cache") {
                            networkingManager.clearCache()
                        }
                        
                        Button("Reset Metrics") {
                            networkingManager.resetPerformanceMetrics()
                        }
                        
                        Button("Refresh") {
                            // Trigger refresh
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .sheet(isPresented: $showingConfiguration) {
            NetworkingConfigurationView()
        }
        .sheet(isPresented: $showingRequestDetails) {
            if let request = selectedRequest {
                RequestDetailsView(request: request)
            }
        }
        .sheet(isPresented: $showingPerformanceDetails) {
            PerformanceDetailsView()
        }
        .onAppear {
            startRefreshTimer()
        }
        .onDisappear {
            stopRefreshTimer()
        }
    }
    
    // MARK: - Header View
    
    private var headerView: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Network Status")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Circle()
                            .fill(networkStatusColor)
                            .frame(width: 12, height: 12)
                        
                        Text(networkingManager.networkStatus.rawValue)
                            .font(.headline)
                            .foregroundColor(.primary)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Connection Quality")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(networkingManager.connectionQuality.rawValue)
                        .font(.headline)
                        .foregroundColor(connectionQualityColor)
                }
            }
            
            // Active requests indicator
            HStack {
                Text("Active Requests")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(networkingManager.activeRequests)")
                    .font(.headline)
                    .foregroundColor(.primary)
            }
            
            // Progress bar for active requests
            if networkingManager.activeRequests > 0 {
                ProgressView(value: Double(networkingManager.activeRequests), total: Double(networkingManager.configuration.maximumConcurrentRequests))
                    .progressViewStyle(LinearProgressViewStyle(tint: .blue))
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
        .padding(.horizontal)
    }
    
    private var networkStatusColor: Color {
        switch networkingManager.networkStatus {
        case .connected:
            return .green
        case .disconnected:
            return .red
        case .connecting:
            return .orange
        case .limited:
            return .yellow
        case .unknown:
            return .gray
        }
    }
    
    private var connectionQualityColor: Color {
        switch networkingManager.connectionQuality {
        case .excellent:
            return .green
        case .good:
            return .blue
        case .fair:
            return .orange
        case .poor:
            return .red
        case .unknown:
            return .gray
        }
    }
    
    // MARK: - Tab Selection
    
    private var tabSelectionView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(["Overview", "Requests", "Performance", "Config", "Logs"], id: \.self) { tab in
                    Button(action: {
                        withAnimation {
                            selectedTab = ["Overview", "Requests", "Performance", "Config", "Logs"].firstIndex(of: tab) ?? 0
                        }
                    }) {
                        VStack(spacing: 4) {
                            Text(tab)
                                .font(.subheadline)
                                .fontWeight(selectedTab == ["Overview", "Requests", "Performance", "Config", "Logs"].firstIndex(of: tab) ? .semibold : .regular)
                                .foregroundColor(selectedTab == ["Overview", "Requests", "Performance", "Config", "Logs"].firstIndex(of: tab) ? .primary : .secondary)
                            
                            Rectangle()
                                .fill(selectedTab == ["Overview", "Requests", "Performance", "Config", "Logs"].firstIndex(of: tab) ? Color.blue : Color.clear)
                                .frame(height: 2)
                        }
                        .frame(width: 80)
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Overview Tab
    
    private var overviewTabView: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Performance summary cards
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    let metrics = networkingManager.getPerformanceMetrics()
                    
                    SummaryCardView(
                        title: "Success Rate",
                        value: "\(Int(metrics.successRate * 100))%",
                        icon: "checkmark.circle",
                        color: .green
                    )
                    
                    SummaryCardView(
                        title: "Avg Response",
                        value: "\(String(format: "%.2f", metrics.averageResponseTime))s",
                        icon: "clock",
                        color: .blue
                    )
                    
                    SummaryCardView(
                        title: "Total Requests",
                        value: "\(metrics.totalRequests)",
                        icon: "arrow.up.arrow.down",
                        color: .orange
                    )
                    
                    SummaryCardView(
                        title: "Data Transferred",
                        value: formatDataSize(metrics.totalDataTransferred),
                        icon: "network",
                        color: .purple
                    )
                }
                
                // Network status details
                NetworkStatusDetailsView()
                
                // Recent activity
                RecentActivityView()
            }
            .padding()
        }
    }
    
    // MARK: - Requests Tab
    
    private var requestsTabView: some View {
        VStack(spacing: 16) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Search requests...", text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            .padding(.horizontal)
            
            // Requests list
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(filteredRequests, id: \.id) { request in
                        RequestCardView(request: request) {
                            selectedRequest = request
                            showingRequestDetails = true
                        }
                    }
                }
                .padding()
            }
        }
    }
    
    private var filteredRequests: [NetworkingLayerManager.NetworkRequest] {
        // This would filter actual requests, for now return empty array
        return []
    }
    
    // MARK: - Performance Tab
    
    private var performanceTabView: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Performance charts
                PerformanceChartsView()
                
                // Detailed metrics
                DetailedMetricsView()
                
                // Performance trends
                PerformanceTrendsView()
            }
            .padding()
        }
    }
    
    // MARK: - Configuration Tab
    
    private var configurationTabView: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Current configuration
                CurrentConfigurationView()
                
                // Cache settings
                CacheSettingsView()
                
                // Retry policies
                RetryPoliciesView()
                
                // Interceptors
                InterceptorsView()
            }
            .padding()
        }
    }
    
    // MARK: - Logs Tab
    
    private var logsTabView: some View {
        VStack(spacing: 16) {
            // Filter controls
            HStack {
                Picker("Log Level", selection: .constant("All")) {
                    Text("All").tag("All")
                    Text("Info").tag("Info")
                    Text("Warning").tag("Warning")
                    Text("Error").tag("Error")
                }
                .pickerStyle(MenuPickerStyle())
                
                Spacer()
                
                Button("Export Logs") {
                    exportLogs()
                }
                .buttonStyle(.bordered)
            }
            .padding(.horizontal)
            
            // Logs list
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(0..<20, id: \.self) { index in
                        LogEntryView(
                            timestamp: Date().addingTimeInterval(-Double(index * 60)),
                            level: index % 4 == 0 ? "Error" : index % 3 == 0 ? "Warning" : "Info",
                            message: "Sample log message \(index + 1)"
                        )
                    }
                }
                .padding()
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func formatDataSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
    
    private func startRefreshTimer() {
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
            // Trigger UI refresh
        }
    }
    
    private func stopRefreshTimer() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }
    
    private func exportLogs() {
        // Implementation for exporting logs
        print("Exporting logs...")
    }
}

// MARK: - Supporting Views

struct SummaryCardView: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            VStack(spacing: 4) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct NetworkStatusDetailsView: View {
    @StateObject private var networkingManager = NetworkingLayerManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Network Details")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                DetailRowView(
                    title: "Status",
                    value: networkingManager.networkStatus.rawValue,
                    icon: "network",
                    color: networkingManager.networkStatus.isConnected ? .green : .red
                )
                
                DetailRowView(
                    title: "Quality",
                    value: networkingManager.connectionQuality.rawValue,
                    icon: "speedometer",
                    color: connectionQualityColor
                )
                
                DetailRowView(
                    title: "Active Requests",
                    value: "\(networkingManager.activeRequests)",
                    icon: "arrow.up.arrow.down",
                    color: .blue
                )
                
                DetailRowView(
                    title: "Queue Size",
                    value: "\(networkingManager.requestQueue.count)",
                    icon: "list.bullet",
                    color: .orange
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    private var connectionQualityColor: Color {
        switch networkingManager.connectionQuality {
        case .excellent: return .green
        case .good: return .blue
        case .fair: return .orange
        case .poor: return .red
        case .unknown: return .gray
        }
    }
}

struct DetailRowView: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 20)
            
            Text(title)
                .font(.subheadline)
                .foregroundColor(.primary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
        }
    }
}

struct RecentActivityView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Activity")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                ForEach(0..<5, id: \.self) { index in
                    HStack {
                        Image(systemName: "clock")
                            .foregroundColor(.blue)
                            .frame(width: 20)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Request \(index + 1)")
                                .font(.subheadline)
                                .foregroundColor(.primary)
                            
                            Text("GET /api/health-data")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Text("\(String(format: "%.2f", Double.random(in: 0.1...2.0)))s")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct RequestCardView: View {
    let request: NetworkingLayerManager.NetworkRequest
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(request.method.rawValue)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text(request.url.absoluteString)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(request.status.rawValue)
                            .font(.headline)
                            .foregroundColor(statusColor)
                        
                        Text("Status")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Priority")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text(request.priority.rawValue.description)
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    
                    HStack {
                        Text("Attempts")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("\(request.attempts)")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    
                    HStack {
                        Text("Created")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text(request.createdAt, style: .relative)
                            .font(.caption)
                            .foregroundColor(.primary)
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(radius: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var statusColor: Color {
        switch request.status {
        case .completed:
            return .green
        case .failed:
            return .red
        case .inProgress:
            return .blue
        case .pending:
            return .orange
        case .cancelled:
            return .gray
        case .retrying:
            return .yellow
        }
    }
}

struct PerformanceChartsView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Performance Charts")
                .font(.headline)
                .foregroundColor(.primary)
            
            // Response time chart
            VStack(alignment: .leading, spacing: 8) {
                Text("Response Time Trend")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Chart {
                    ForEach(0..<10, id: \.self) { index in
                        LineMark(
                            x: .value("Time", index),
                            y: .value("Response Time", Double.random(in: 0.1...2.0))
                        )
                        .foregroundStyle(.blue)
                    }
                }
                .frame(height: 200)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(radius: 2)
        }
    }
}

struct DetailedMetricsView: View {
    @StateObject private var networkingManager = NetworkingLayerManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Detailed Metrics")
                .font(.headline)
                .foregroundColor(.primary)
            
            let metrics = networkingManager.getPerformanceMetrics()
            
            VStack(spacing: 12) {
                MetricRowView(
                    title: "Success Rate",
                    value: "\(Int(metrics.successRate * 100))%",
                    color: .green
                )
                
                MetricRowView(
                    title: "Error Rate",
                    value: "\(Int(metrics.errorRate * 100))%",
                    color: .red
                )
                
                MetricRowView(
                    title: "Cache Hit Rate",
                    value: "\(Int(metrics.cacheHitRate * 100))%",
                    color: .blue
                )
                
                MetricRowView(
                    title: "Retry Rate",
                    value: "\(Int(metrics.retryRate * 100))%",
                    color: .orange
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct MetricRowView: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.primary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
    }
}

struct PerformanceTrendsView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Performance Trends")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text("Performance trend analysis and insights will be displayed here.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct CurrentConfigurationView: View {
    @StateObject private var networkingManager = NetworkingLayerManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Current Configuration")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                ConfigRowView(
                    title: "Base URL",
                    value: networkingManager.configuration.baseURL.absoluteString
                )
                
                ConfigRowView(
                    title: "Timeout",
                    value: "\(Int(networkingManager.configuration.timeoutInterval))s"
                )
                
                ConfigRowView(
                    title: "Max Concurrent",
                    value: "\(networkingManager.configuration.maximumConcurrentRequests)"
                )
                
                ConfigRowView(
                    title: "Cache Enabled",
                    value: networkingManager.configuration.enableRequestCaching ? "Yes" : "No"
                )
                
                ConfigRowView(
                    title: "Retry Enabled",
                    value: networkingManager.configuration.enableRequestRetry ? "Yes" : "No"
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct ConfigRowView: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.primary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}

struct CacheSettingsView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Cache Settings")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text("Cache configuration and management options will be displayed here.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct RetryPoliciesView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Retry Policies")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text("Retry policy configuration and management will be displayed here.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct InterceptorsView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Interceptors")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text("Request and response interceptor configuration will be displayed here.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct LogEntryView: View {
    let timestamp: Date
    let level: String
    let message: String
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(timestamp, style: .time)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(level)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(levelColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(levelColor.opacity(0.2))
                        .cornerRadius(4)
                }
                
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.primary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .shadow(radius: 1)
    }
    
    private var levelColor: Color {
        switch level {
        case "Error":
            return .red
        case "Warning":
            return .orange
        case "Info":
            return .blue
        default:
            return .gray
        }
    }
}

// MARK: - Supporting Views (Placeholders)

struct NetworkingConfigurationView: View {
    var body: some View {
        Text("Networking Configuration")
            .padding()
    }
}

struct RequestDetailsView: View {
    let request: NetworkingLayerManager.NetworkRequest
    
    var body: some View {
        Text("Request Details for \(request.id)")
            .padding()
    }
}

struct PerformanceDetailsView: View {
    var body: some View {
        Text("Performance Details")
            .padding()
    }
}

#Preview {
    NetworkingLayerView()
} 
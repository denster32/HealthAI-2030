import SwiftUI
import Charts

@available(iOS 18.0, macOS 15.0, *)
public struct AdvancedHealthDataIntegrationDashboardView: View {
    @StateObject private var integrationEngine = AdvancedHealthDataIntegrationEngine(
        healthDataManager: HealthDataManager(),
        analyticsEngine: AnalyticsEngine()
    )
    
    @State private var selectedTab = 0
    @State private var showingDeviceDetails = false
    @State private var showingSourceDetails = false
    @State private var showingFHIRDetails = false
    @State private var showingQualityReport = false
    @State private var selectedDevice: ConnectedDevice?
    @State private var selectedSource: DataSource?
    @State private var selectedResource: FHIRResource?
    
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
                    
                    devicesTab
                        .tag(1)
                    
                    sourcesTab
                        .tag(2)
                    
                    fhirTab
                        .tag(3)
                    
                    qualityTab
                        .tag(4)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .navigationBarHidden(true)
            .background(Color(.systemGroupedBackground))
        }
        .sheet(item: $selectedDevice) { device in
            DeviceDetailView(device: device)
        }
        .sheet(item: $selectedSource) { source in
            SourceDetailView(source: source)
        }
        .sheet(item: $selectedResource) { resource in
            FHIRResourceDetailView(resource: resource)
        }
        .sheet(isPresented: $showingQualityReport) {
            DataQualityReportView(integrationEngine: integrationEngine)
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Health Data Integration")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("Interoperability & FHIR Compliance")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: {
                    Task {
                        if integrationEngine.integrationStatus == .connected {
                            await integrationEngine.stopIntegration()
                        } else {
                            try? await integrationEngine.startIntegration()
                        }
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: integrationEngine.integrationStatus == .connected ? "stop.circle.fill" : "play.circle.fill")
                            .font(.title2)
                        
                        Text(integrationEngine.integrationStatus == .connected ? "Stop" : "Start")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(integrationEngine.integrationStatus == .connected ? .red : .green)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(.systemBackground))
                    .cornerRadius(20)
                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                }
            }
            
            // Status and Progress
            HStack {
                StatusBadgeView(status: integrationEngine.integrationStatus)
                
                Spacer()
                
                if integrationEngine.integrationStatus == .syncing {
                    ProgressView(value: integrationEngine.syncProgress)
                        .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                        .frame(width: 100)
                }
                
                if let lastSync = integrationEngine.lastSyncTime {
                    Text("Last sync: \(lastSync, style: .time)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
    }
    
    // MARK: - Tab Selection
    private var tabSelectionView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(Array(tabItems.enumerated()), id: \.offset) { index, item in
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            selectedTab = index
                        }
                    }) {
                        VStack(spacing: 8) {
                            Image(systemName: item.icon)
                                .font(.title2)
                                .foregroundColor(selectedTab == index ? .blue : .secondary)
                            
                            Text(item.title)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(selectedTab == index ? .blue : .secondary)
                        }
                        .frame(width: 80, height: 60)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(selectedTab == index ? Color.blue.opacity(0.1) : Color.clear)
                        )
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
    }
    
    // MARK: - Overview Tab
    private var overviewTab: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Integration Status Card
                IntegrationStatusCard(integrationEngine: integrationEngine)
                
                // Quick Stats
                QuickStatsView(integrationEngine: integrationEngine)
                
                // Data Quality Overview
                DataQualityOverviewCard(integrationEngine: integrationEngine)
                
                // Recent Sync Activity
                RecentSyncActivityView(integrationEngine: integrationEngine)
            }
            .padding()
        }
    }
    
    // MARK: - Devices Tab
    private var devicesTab: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(integrationEngine.connectedDevices) { device in
                    DeviceCardView(device: device) {
                        selectedDevice = device
                    }
                }
            }
            .padding()
        }
    }
    
    // MARK: - Sources Tab
    private var sourcesTab: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(integrationEngine.dataSources) { source in
                    SourceCardView(source: source) {
                        selectedSource = source
                    }
                }
            }
            .padding()
        }
    }
    
    // MARK: - FHIR Tab
    private var fhirTab: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(integrationEngine.fhirResources) { resource in
                    FHIRResourceCardView(resource: resource) {
                        selectedResource = resource
                    }
                }
            }
            .padding()
        }
    }
    
    // MARK: - Quality Tab
    private var qualityTab: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Quality Metrics
                QualityMetricsCard(integrationEngine: integrationEngine)
                
                // Quality Issues
                QualityIssuesCard(integrationEngine: integrationEngine)
                
                // Quality Recommendations
                QualityRecommendationsCard(integrationEngine: integrationEngine)
            }
            .padding()
        }
    }
    
    // MARK: - Tab Items
    private var tabItems: [(title: String, icon: String)] {
        [
            ("Overview", "chart.bar.fill"),
            ("Devices", "iphone"),
            ("Sources", "server.rack"),
            ("FHIR", "doc.text.fill"),
            ("Quality", "checkmark.shield.fill")
        ]
    }
}

// MARK: - Supporting Views

@available(iOS 18.0, macOS 15.0, *)
struct IntegrationStatusCard: View {
    @ObservedObject var integrationEngine: AdvancedHealthDataIntegrationEngine
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: statusIcon)
                    .foregroundColor(statusColor)
                
                Text("Integration Status")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                StatusBadgeView(status: integrationEngine.integrationStatus)
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                MetricView(
                    title: "Connected Devices",
                    value: "\(integrationEngine.connectedDevices.count)",
                    icon: "iphone",
                    color: .blue
                )
                
                MetricView(
                    title: "Data Sources",
                    value: "\(integrationEngine.dataSources.count)",
                    icon: "server.rack",
                    color: .green
                )
                
                MetricView(
                    title: "FHIR Resources",
                    value: "\(integrationEngine.fhirResources.count)",
                    icon: "doc.text.fill",
                    color: .purple
                )
                
                MetricView(
                    title: "Sync Success",
                    value: "\(Int(integrationEngine.integrationMetrics.successRate * 100))%",
                    icon: "checkmark.circle.fill",
                    color: .orange
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    private var statusIcon: String {
        switch integrationEngine.integrationStatus {
        case .connected: return "checkmark.circle.fill"
        case .connecting: return "arrow.clockwise"
        case .syncing: return "arrow.triangle.2.circlepath"
        case .error: return "exclamationmark.triangle.fill"
        case .disconnected: return "xmark.circle.fill"
        case .idle: return "circle"
        }
    }
    
    private var statusColor: Color {
        switch integrationEngine.integrationStatus {
        case .connected: return .green
        case .connecting, .syncing: return .blue
        case .error: return .red
        case .disconnected, .idle: return .gray
        }
    }
}

@available(iOS 18.0, macOS 15.0, *)
struct MetricView: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

@available(iOS 18.0, macOS 15.0, *)
struct QuickStatsView: View {
    @ObservedObject var integrationEngine: AdvancedHealthDataIntegrationEngine
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Stats")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                StatCardView(
                    title: "Total Syncs",
                    value: "\(integrationEngine.integrationMetrics.syncCount)",
                    icon: "arrow.triangle.2.circlepath",
                    color: .blue
                )
                
                StatCardView(
                    title: "Data Volume",
                    value: "\(integrationEngine.integrationMetrics.dataVolume)",
                    icon: "chart.bar.fill",
                    color: .green
                )
                
                StatCardView(
                    title: "Response Time",
                    value: "\(Int(integrationEngine.integrationMetrics.responseTime))s",
                    icon: "clock.fill",
                    color: .purple
                )
                
                StatCardView(
                    title: "Quality Score",
                    value: "\(Int(integrationEngine.dataQuality.overallScore * 100))%",
                    icon: "checkmark.shield.fill",
                    color: .orange
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

@available(iOS 18.0, macOS 15.0, *)
struct StatCardView: View {
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
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

@available(iOS 18.0, macOS 15.0, *)
struct DataQualityOverviewCard: View {
    @ObservedObject var integrationEngine: AdvancedHealthDataIntegrationEngine
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Data Quality Overview")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 16) {
                QualityProgressRow(
                    title: "Overall Quality",
                    progress: integrationEngine.dataQuality.overallScore,
                    color: .blue
                )
                
                QualityProgressRow(
                    title: "Completeness",
                    progress: integrationEngine.dataQuality.completeness,
                    color: .green
                )
                
                QualityProgressRow(
                    title: "Accuracy",
                    progress: integrationEngine.dataQuality.accuracy,
                    color: .purple
                )
                
                QualityProgressRow(
                    title: "Consistency",
                    progress: integrationEngine.dataQuality.consistency,
                    color: .orange
                )
                
                QualityProgressRow(
                    title: "Timeliness",
                    progress: integrationEngine.dataQuality.timeliness,
                    color: .red
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

@available(iOS 18.0, macOS 15.0, *)
struct QualityProgressRow: View {
    let title: String
    let progress: Double
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("\(Int(progress * 100))%")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(color)
            }
            
            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle(tint: color))
                .scaleEffect(x: 1, y: 2, anchor: .center)
        }
    }
}

@available(iOS 18.0, macOS 15.0, *)
struct RecentSyncActivityView: View {
    @ObservedObject var integrationEngine: AdvancedHealthDataIntegrationEngine
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Sync Activity")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVStack(spacing: 8) {
                ForEach(integrationEngine.getSyncHistory().prefix(5), id: \.timestamp) { activity in
                    SyncActivityRowView(activity: activity)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

@available(iOS 18.0, macOS 15.0, *)
struct SyncActivityRowView: View {
    let activity: SyncActivity
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.blue)
                .frame(width: 8, height: 8)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Data Sync")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("\(activity.devices.count) devices, \(activity.sources.count) sources")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(activity.timestamp, style: .time)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Card Views

@available(iOS 18.0, macOS 15.0, *)
struct DeviceCardView: View {
    let device: ConnectedDevice
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(device.name)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Text(device.manufacturer)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    ConnectionStatusBadgeView(status: device.connectionStatus)
                }
                
                Text(device.model)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                HStack {
                    Label(device.type.rawValue.capitalized, systemImage: deviceIcon)
                        .font(.caption)
                        .foregroundColor(.blue)
                    
                    Spacer()
                    
                    if let batteryLevel = device.batteryLevel {
                        Label("\(Int(batteryLevel * 100))%", systemImage: "battery.100")
                            .font(.caption)
                            .foregroundColor(batteryColor(batteryLevel))
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var deviceIcon: String {
        switch device.type {
        case .wearable: return "applewatch"
        case .medical: return "cross.fill"
        case .mobile: return "iphone"
        case .smartHome: return "house.fill"
        case .clinical: return "stethoscope"
        }
    }
    
    private func batteryColor(_ level: Double) -> Color {
        if level > 0.5 { return .green }
        else if level > 0.2 { return .orange }
        else { return .red }
    }
}

@available(iOS 18.0, macOS 15.0, *)
struct SourceCardView: View {
    let source: DataSource
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(source.name)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Text(source.category.rawValue.capitalized)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    SourceStatusBadgeView(status: source.status)
                }
                
                if let url = source.url {
                    Text(url)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                HStack {
                    Label("\(source.dataTypes.count) types", systemImage: "list.bullet")
                        .font(.caption)
                        .foregroundColor(.green)
                    
                    Spacer()
                    
                    if let lastSync = source.lastSync {
                        Label(lastSync, style: .time)
                            .font(.caption)
                            .foregroundColor(.purple)
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

@available(iOS 18.0, macOS 15.0, *)
struct FHIRResourceCardView: View {
    let resource: FHIRResource
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(resource.type.rawValue.capitalized)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Text(resource.resourceId)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    ResourceStatusBadgeView(status: resource.status)
                }
                
                Text("Version \(resource.version)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                HStack {
                    Label(resource.lastUpdated, style: .date)
                        .font(.caption)
                        .foregroundColor(.blue)
                    
                    Spacer()
                    
                    Label("\(resource.data.count) fields", systemImage: "doc.text.fill")
                        .font(.caption)
                        .foregroundColor(.purple)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

@available(iOS 18.0, macOS 15.0, *)
struct QualityMetricsCard: View {
    @ObservedObject var integrationEngine: AdvancedHealthDataIntegrationEngine
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quality Metrics")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                QualityMetricView(
                    title: "Overall Score",
                    value: "\(Int(integrationEngine.dataQuality.overallScore * 100))%",
                    color: .blue
                )
                
                QualityMetricView(
                    title: "Completeness",
                    value: "\(Int(integrationEngine.dataQuality.completeness * 100))%",
                    color: .green
                )
                
                QualityMetricView(
                    title: "Accuracy",
                    value: "\(Int(integrationEngine.dataQuality.accuracy * 100))%",
                    color: .purple
                )
                
                QualityMetricView(
                    title: "Consistency",
                    value: "\(Int(integrationEngine.dataQuality.consistency * 100))%",
                    color: .orange
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

@available(iOS 18.0, macOS 15.0, *)
struct QualityMetricView: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

@available(iOS 18.0, macOS 15.0, *)
struct QualityIssuesCard: View {
    @ObservedObject var integrationEngine: AdvancedHealthDataIntegrationEngine
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quality Issues")
                .font(.headline)
                .fontWeight(.semibold)
            
            if integrationEngine.dataQuality.issues.isEmpty {
                Text("No quality issues detected")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(integrationEngine.dataQuality.issues, id: \.timestamp) { issue in
                        QualityIssueRowView(issue: issue)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

@available(iOS 18.0, macOS 15.0, *)
struct QualityIssueRowView: View {
    let issue: QualityIssue
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(severityColor)
                .frame(width: 8, height: 8)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(issue.type.rawValue.capitalized)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(issue.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            Text(issue.timestamp, style: .time)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
    
    private var severityColor: Color {
        switch issue.severity {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        case .critical: return .purple
        }
    }
}

@available(iOS 18.0, macOS 15.0, *)
struct QualityRecommendationsCard: View {
    @ObservedObject var integrationEngine: AdvancedHealthDataIntegrationEngine
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quality Recommendations")
                .font(.headline)
                .fontWeight(.semibold)
            
            Text("Tap to view detailed quality report")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(12)
                .onTapGesture {
                    // Show quality report
                }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Badge Views

@available(iOS 18.0, macOS 15.0, *)
struct StatusBadgeView: View {
    let status: IntegrationStatus
    
    private var statusColor: Color {
        switch status {
        case .connected: return .green
        case .connecting, .syncing: return .blue
        case .error: return .red
        case .disconnected, .idle: return .gray
        }
    }
    
    var body: some View {
        Text(status.rawValue.capitalized)
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(statusColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(statusColor.opacity(0.1))
            .cornerRadius(8)
    }
}

@available(iOS 18.0, macOS 15.0, *)
struct ConnectionStatusBadgeView: View {
    let status: ConnectionStatus
    
    private var statusColor: Color {
        switch status {
        case .connected: return .green
        case .connecting: return .blue
        case .error: return .red
        case .disconnected: return .gray
        }
    }
    
    var body: some View {
        Text(status.rawValue.capitalized)
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(statusColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(statusColor.opacity(0.1))
            .cornerRadius(8)
    }
}

@available(iOS 18.0, macOS 15.0, *)
struct SourceStatusBadgeView: View {
    let status: SourceStatus
    
    private var statusColor: Color {
        switch status {
        case .active: return .green
        case .syncing: return .blue
        case .error: return .red
        case .inactive: return .gray
        }
    }
    
    var body: some View {
        Text(status.rawValue.capitalized)
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(statusColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(statusColor.opacity(0.1))
            .cornerRadius(8)
    }
}

@available(iOS 18.0, macOS 15.0, *)
struct ResourceStatusBadgeView: View {
    let status: ResourceStatus
    
    private var statusColor: Color {
        switch status {
        case .active: return .green
        case .inactive: return .gray
        case .deleted: return .red
        case .error: return .orange
        }
    }
    
    var body: some View {
        Text(status.rawValue.capitalized)
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(statusColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(statusColor.opacity(0.1))
            .cornerRadius(8)
    }
}

// MARK: - Detail Views

@available(iOS 18.0, macOS 15.0, *)
struct DeviceDetailView: View {
    let device: ConnectedDevice
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text(device.name)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text(device.manufacturer)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        ConnectionStatusBadgeView(status: device.connectionStatus)
                    }
                    
                    // Details
                    VStack(alignment: .leading, spacing: 12) {
                        DetailRowView(title: "Model", value: device.model)
                        DetailRowView(title: "Type", value: device.type.rawValue.capitalized)
                        DetailRowView(title: "Firmware", value: device.firmwareVersion)
                        DetailRowView(title: "Last Seen", value: device.lastSeen, style: .date)
                        if let batteryLevel = device.batteryLevel {
                            DetailRowView(title: "Battery", value: "\(Int(batteryLevel * 100))%")
                        }
                        if let signalStrength = device.signalStrength {
                            DetailRowView(title: "Signal", value: "\(Int(signalStrength * 100))%")
                        }
                    }
                    
                    // Capabilities
                    if !device.capabilities.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Capabilities")
                                .font(.headline)
                            
                            ForEach(device.capabilities, id: \.name) { capability in
                                HStack {
                                    Image(systemName: capability.enabled ? "checkmark.circle.fill" : "xmark.circle.fill")
                                        .foregroundColor(capability.enabled ? .green : .red)
                                        .font(.caption)
                                    
                                    Text(capability.name)
                                        .font(.subheadline)
                                }
                            }
                        }
                    }
                    
                    // Data Types
                    if !device.dataTypes.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Data Types")
                                .font(.headline)
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                                ForEach(device.dataTypes, id: \.self) { dataType in
                                    Text(dataType)
                                        .font(.caption)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.blue.opacity(0.1))
                                        .cornerRadius(8)
                                }
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Device Details")
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

@available(iOS 18.0, macOS 15.0, *)
struct SourceDetailView: View {
    let source: DataSource
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text(source.name)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text(source.category.rawValue.capitalized)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        SourceStatusBadgeView(status: source.status)
                    }
                    
                    // Details
                    VStack(alignment: .leading, spacing: 12) {
                        if let url = source.url {
                            DetailRowView(title: "URL", value: url)
                        }
                        DetailRowView(title: "Sync Interval", value: "\(Int(source.syncInterval))s")
                        if let lastSync = source.lastSync {
                            DetailRowView(title: "Last Sync", value: lastSync, style: .date)
                        }
                    }
                    
                    // Data Types
                    if !source.dataTypes.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Data Types")
                                .font(.headline)
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                                ForEach(source.dataTypes, id: \.self) { dataType in
                                    Text(dataType)
                                        .font(.caption)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.green.opacity(0.1))
                                        .cornerRadius(8)
                                }
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Source Details")
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

@available(iOS 18.0, macOS 15.0, *)
struct FHIRResourceDetailView: View {
    let resource: FHIRResource
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text(resource.type.rawValue.capitalized)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text(resource.resourceId)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        ResourceStatusBadgeView(status: resource.status)
                    }
                    
                    // Details
                    VStack(alignment: .leading, spacing: 12) {
                        DetailRowView(title: "Version", value: resource.version)
                        DetailRowView(title: "Last Updated", value: resource.lastUpdated, style: .date)
                        DetailRowView(title: "Fields", value: "\(resource.data.count)")
                    }
                    
                    // Data
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Resource Data")
                            .font(.headline)
                        
                        ForEach(Array(resource.data.keys.sorted()), id: \.self) { key in
                            if let value = resource.data[key] {
                                HStack {
                                    Text(key)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    
                                    Spacer()
                                    
                                    Text("\(value)")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.vertical, 2)
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("FHIR Resource")
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

@available(iOS 18.0, macOS 15.0, *)
struct DataQualityReportView: View {
    @ObservedObject var integrationEngine: AdvancedHealthDataIntegrationEngine
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Quality Overview
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Data Quality Report")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Comprehensive analysis of data quality metrics")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    // Quality Metrics
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Quality Metrics")
                            .font(.headline)
                        
                        QualityProgressRow(
                            title: "Overall Quality",
                            progress: integrationEngine.dataQuality.overallScore,
                            color: .blue
                        )
                        
                        QualityProgressRow(
                            title: "Completeness",
                            progress: integrationEngine.dataQuality.completeness,
                            color: .green
                        )
                        
                        QualityProgressRow(
                            title: "Accuracy",
                            progress: integrationEngine.dataQuality.accuracy,
                            color: .purple
                        )
                        
                        QualityProgressRow(
                            title: "Consistency",
                            progress: integrationEngine.dataQuality.consistency,
                            color: .orange
                        )
                        
                        QualityProgressRow(
                            title: "Timeliness",
                            progress: integrationEngine.dataQuality.timeliness,
                            color: .red
                        )
                    }
                    
                    // Quality Issues
                    if !integrationEngine.dataQuality.issues.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Quality Issues")
                                .font(.headline)
                            
                            ForEach(integrationEngine.dataQuality.issues, id: \.timestamp) { issue in
                                QualityIssueDetailView(issue: issue)
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Quality Report")
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

@available(iOS 18.0, macOS 15.0, *)
struct QualityIssueDetailView: View {
    let issue: QualityIssue
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(issue.type.rawValue.capitalized)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text(issue.severity.rawValue.capitalized)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(severityColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(severityColor.opacity(0.1))
                    .cornerRadius(8)
            }
            
            Text(issue.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            if !issue.affectedData.isEmpty {
                Text("Affected: \(issue.affectedData.joined(separator: ", "))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(issue.timestamp, style: .date)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    private var severityColor: Color {
        switch issue.severity {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        case .critical: return .purple
        }
    }
}

@available(iOS 18.0, macOS 15.0, *)
struct DetailRowView: View {
    let title: String
    let value: String
    var style: DateFormatter.Style = .none
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            Spacer()
            
            if style != .none {
                Text(value, style: style)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else {
                Text(value)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Extensions

extension ConnectedDevice: Identifiable {}
extension DataSource: Identifiable {}
extension FHIRResource: Identifiable {} 
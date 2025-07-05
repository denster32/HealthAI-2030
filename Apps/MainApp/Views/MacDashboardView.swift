import SwiftUI
import Charts
import OSLog

@available(macOS 15.0, *)
struct MacDashboardView: View {
    @StateObject private var coordinator = MacHealthAICoordinator.shared
    @StateObject private var analyticsEngine = EnhancedMacAnalyticsEngine.shared
    @StateObject private var exportManager = AdvancedDataExportManager.shared
    @StateObject private var syncManager = UnifiedCloudKitSyncManager.shared
    
    @State private var selectedTab: DashboardTab = .overview
    @State private var showingSystemReport = false
    @State private var showingAnalyticsOptions = false
    @State private var showingExportOptions = false
    
    var body: some View {
        HSplitView {
            // Sidebar
            VStack(alignment: .leading, spacing: 16) {
                // System Status Header
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "desktopcomputer")
                            .foregroundColor(.blue)
                            .font(.title2)
                        VStack(alignment: .leading) {
                            Text("HealthAI Mac")
                                .font(.headline)
                                .fontWeight(.semibold)
                            Text(coordinator.systemStatus.rawValue)
                                .font(.caption)
                                .foregroundColor(coordinator.systemStatus.color)
                        }
                        Spacer()
                        Button(action: { showingSystemReport = true }) {
                            Image(systemName: "info.circle")
                        }
                        .buttonStyle(.plain)
                    }
                    
                    SystemHealthIndicator(health: coordinator.systemHealth)
                }
                .padding()
                .background(Color(.controlBackgroundColor))
                .cornerRadius(8)
                
                // Navigation Tabs
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(DashboardTab.allCases, id: \.self) { tab in
                        DashboardTabButton(
                            tab: tab,
                            isSelected: selectedTab == tab,
                            action: { selectedTab = tab }
                        )
                    }
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Quick Actions
                VStack(alignment: .leading, spacing: 8) {
                    Text("Quick Actions")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    VStack(spacing: 4) {
                        QuickActionButton(
                            title: "Sync Now",
                            icon: "arrow.clockwise",
                            action: { Task { await coordinator.triggerManualSync() } }
                        )
                        
                        QuickActionButton(
                            title: "Run Analytics",
                            icon: "brain.head.profile",
                            action: { showingAnalyticsOptions = true }
                        )
                        
                        QuickActionButton(
                            title: "Export Data",
                            icon: "square.and.arrow.up",
                            action: { showingExportOptions = true }
                        )
                    }
                    .padding(.horizontal)
                }
            }
            .frame(minWidth: 280, maxWidth: 320)
            .background(Color(.windowBackgroundColor))
            
            // Main Content
            VStack {
                // Content Header
                HStack {
                    Text(selectedTab.title)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    // Live status indicators
                    HStack(spacing: 16) {
                        StatusIndicator(
                            title: "Sync",
                            status: syncManager.syncStatus.rawValue,
                            color: syncStatusColor(syncManager.syncStatus)
                        )
                        
                        StatusIndicator(
                            title: "Analytics",
                            status: analyticsEngine.processingStatus.rawValue,
                            color: analyticsStatusColor(analyticsEngine.processingStatus)
                        )
                        
                        StatusIndicator(
                            title: "Export",
                            status: exportManager.exportStatus.rawValue,
                            color: exportStatusColor(exportManager.exportStatus)
                        )
                    }
                }
                .padding()
                
                // Tab Content
                TabView(selection: $selectedTab) {
                    OverviewTabView()
                        .tag(DashboardTab.overview)
                    
                    DevicesTabView(devices: coordinator.connectedDevices)
                        .tag(DashboardTab.devices)
                    
                    AnalyticsTabView()
                        .tag(DashboardTab.analytics)
                    
                    ExportsTabView()
                        .tag(DashboardTab.exports)
                    
                    SystemTabView()
                        .tag(DashboardTab.system)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
        }
        .onAppear {
            Task {
                await coordinator.startCoordination()
            }
        }
        .sheet(isPresented: $showingSystemReport) {
            SystemReportView(report: coordinator.getSystemReport())
        }
        .sheet(isPresented: $showingAnalyticsOptions) {
            MacAnalyticsOptionsView(isPresented: $showingAnalyticsOptions)
        }
        .sheet(isPresented: $showingExportOptions) {
            MacExportOptionsView(isPresented: $showingExportOptions)
        }
    }
    
    private func syncStatusColor(_ status: SyncStatus) -> Color {
        switch status {
        case .idle: return .secondary
        case .syncing: return .blue
        case .completed: return .green
        case .error: return .red
        }
    }
    
    private func analyticsStatusColor(_ status: AnalyticsProcessingStatus) -> Color {
        switch status {
        case .idle: return .secondary
        case .processing: return .blue
        case .suspended: return .orange
        case .error: return .red
        }
    }
    
    private func exportStatusColor(_ status: ExportStatus) -> Color {
        switch status {
        case .idle: return .secondary
        case .exporting: return .blue
        case .completed: return .green
        case .error: return .red
        }
    }
}

// MARK: - Supporting Views

struct SystemHealthIndicator: View {
    let health: SystemHealth
    
    var body: some View {
        HStack(spacing: 12) {
            HealthMetric(title: "CPU", value: health.cpuUsage, color: metricColor(health.cpuUsage))
            HealthMetric(title: "Memory", value: health.memoryUsage, color: metricColor(health.memoryUsage))
            HealthMetric(title: "Network", value: health.networkStatus.rawValue, color: health.networkStatus.color)
        }
    }
    
    private func metricColor(_ value: Double) -> Color {
        if value < 0.6 { return .green }
        else if value < 0.8 { return .orange }
        else { return .red }
    }
}

struct HealthMetric: View {
    let title: String
    let value: Any
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
            
            if let doubleValue = value as? Double {
                Text("\(Int(doubleValue * 100))%")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(color)
            } else if let stringValue = value as? String {
                Text(stringValue)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(color)
            }
        }
    }
}

struct DashboardTabButton: View {
    let tab: DashboardTab
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: tab.icon)
                    .frame(width: 20)
                Text(tab.title)
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
            .foregroundColor(isSelected ? .accentColor : .primary)
            .cornerRadius(6)
        }
        .buttonStyle(.plain)
    }
}

struct QuickActionButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .frame(width: 16)
                Text(title)
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color(.controlBackgroundColor))
            .cornerRadius(4)
        }
        .buttonStyle(.plain)
    }
}

struct StatusIndicator: View {
    let title: String
    let status: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
            Text(status)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(color)
        }
    }
}

// MARK: - Tab Views

struct OverviewTabView: View {
    @StateObject private var coordinator = MacHealthAICoordinator.shared
    @StateObject private var analyticsEngine = EnhancedMacAnalyticsEngine.shared
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                
                // Connected Devices Card
                OverviewCard(title: "Connected Devices", icon: "devices") {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(coordinator.connectedDevices) { device in
                            HStack {
                                Image(systemName: device.type.icon)
                                    .foregroundColor(device.status.color)
                                Text(device.name)
                                    .font(.subheadline)
                                Spacer()
                                Text(device.status.rawValue)
                                    .font(.caption)
                                    .foregroundColor(device.status.color)
                            }
                        }
                        
                        if coordinator.connectedDevices.isEmpty {
                            Text("No devices detected")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // Processing Queue Card
                OverviewCard(title: "Processing Queue", icon: "list.bullet") {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(coordinator.processingQueue.prefix(3)) { task in
                            HStack {
                                Text(task.description)
                                    .font(.subheadline)
                                    .lineLimit(1)
                                Spacer()
                                Text(task.status.rawValue)
                                    .font(.caption)
                                    .foregroundColor(task.status.color)
                            }
                        }
                        
                        if coordinator.processingQueue.isEmpty {
                            Text("No active tasks")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // Recent Analytics Card
                OverviewCard(title: "Recent Analytics", icon: "chart.line.uptrend.xyaxis") {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(analyticsEngine.completedAnalyses.prefix(3)) { analysis in
                            HStack {
                                Text(analysis.type.displayName)
                                    .font(.subheadline)
                                    .lineLimit(1)
                                Spacer()
                                Text("\(Int(analysis.result.confidence * 100))%")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                        }
                        
                        if analyticsEngine.completedAnalyses.isEmpty {
                            Text("No recent analytics")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .padding()
        }
    }
}

struct OverviewCard<Content: View>: View {
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
                    .foregroundColor(.blue)
                Text(title)
                    .font(.headline)
                Spacer()
            }
            
            content
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(8)
        .frame(height: 150)
    }
}

struct DevicesTabView: View {
    let devices: [ConnectedDevice]
    
    var body: some View {
        VStack {
            if devices.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "wifi.slash")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    
                    Text("No Connected Devices")
                        .font(.title2)
                        .fontWeight(.medium)
                    
                    Text("Make sure your iPhone and Apple Watch are signed into the same iCloud account and have synced recently.")
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: 400)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 300))], spacing: 16) {
                        ForEach(devices) { device in
                            DeviceCard(device: device)
                        }
                    }
                    .padding()
                }
            }
        }
    }
}

struct DeviceCard: View {
    let device: ConnectedDevice
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: device.type.icon)
                    .font(.title2)
                    .foregroundColor(device.status.color)
                
                VStack(alignment: .leading) {
                    Text(device.name)
                        .font(.headline)
                    Text(device.status.rawValue)
                        .font(.caption)
                        .foregroundColor(device.status.color)
                }
                
                Spacer()
                
                Text(device.lastSeen, style: .relative)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Data Types")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                FlowLayout(spacing: 4) {
                    ForEach(device.dataTypes, id: \.self) { dataType in
                        Text(dataType.rawValue)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(4)
                    }
                }
            }
            
            if let batteryLevel = device.batteryLevel {
                HStack {
                    Text("Battery")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(Int(batteryLevel * 100))%")
                        .font(.caption)
                        .fontWeight(.medium)
                }
            }
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(8)
    }
}

struct AnalyticsTabView: View {
    @StateObject private var analyticsEngine = EnhancedMacAnalyticsEngine.shared
    
    var body: some View {
        VStack {
            // Analytics content implementation
            Text("Analytics Dashboard")
                .font(.title)
        }
    }
}

struct ExportsTabView: View {
    @StateObject private var exportManager = AdvancedDataExportManager.shared
    
    var body: some View {
        VStack {
            // Exports content implementation
            Text("Data Exports")
                .font(.title)
        }
    }
}

struct SystemTabView: View {
    @StateObject private var coordinator = MacHealthAICoordinator.shared
    
    var body: some View {
        VStack {
            // System monitoring content implementation
            Text("System Monitoring")
                .font(.title)
        }
    }
}

// MARK: - Supporting Types and Views

enum DashboardTab: String, CaseIterable {
    case overview = "Overview"
    case devices = "Devices"
    case analytics = "Analytics"
    case exports = "Exports"
    case system = "System"
    
    var title: String { rawValue }
    
    var icon: String {
        switch self {
        case .overview: return "house"
        case .devices: return "devices"
        case .analytics: return "chart.bar"
        case .exports: return "square.and.arrow.up"
        case .system: return "gearshape"
        }
    }
}

struct FlowLayout: Layout {
    let spacing: CGFloat
    
    init(spacing: CGFloat = 8) {
        self.spacing = spacing
    }
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        return layout(sizes: sizes, spacing: spacing, containerWidth: proposal.width ?? 0).size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        let offsets = layout(sizes: sizes, spacing: spacing, containerWidth: bounds.width).offsets
        
        for (offset, subview) in zip(offsets, subviews) {
            subview.place(at: CGPoint(x: bounds.minX + offset.x, y: bounds.minY + offset.y), proposal: .unspecified)
        }
    }
    
    private func layout(sizes: [CGSize], spacing: CGFloat, containerWidth: CGFloat) -> (offsets: [CGPoint], size: CGSize) {
        var result: [CGPoint] = []
        var currentPosition = CGPoint.zero
        var lineHeight: CGFloat = 0
        var maxX: CGFloat = 0
        
        for size in sizes {
            if currentPosition.x + size.width > containerWidth && !result.isEmpty {
                currentPosition.x = 0
                currentPosition.y += lineHeight + spacing
                lineHeight = 0
            }
            
            result.append(currentPosition)
            currentPosition.x += size.width + spacing
            lineHeight = max(lineHeight, size.height)
            maxX = max(maxX, currentPosition.x - spacing)
        }
        
        return (result, CGSize(width: maxX, height: currentPosition.y + lineHeight))
    }
}

// MARK: - Sheet Views

struct SystemReportView: View {
    let report: SystemReport
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack {
            Text("System Report")
                .font(.title)
            Text("Generated at \(report.timestamp, style: .time)")
                .font(.caption)
                .foregroundColor(.secondary)
            
            // Report content implementation
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Report details would go here
                    Text("System Status: \(report.systemStatus.rawValue)")
                    Text("Connected Devices: \(report.connectedDevices)")
                    Text("Processing Tasks: \(report.processingTasks)")
                }
                .padding()
            }
            
            Button("Close") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .frame(width: 500, height: 400)
    }
}

struct MacAnalyticsOptionsView: View {
    @Binding var isPresented: Bool
    
    var body: some View {
        VStack {
            Text("Mac Analytics Options")
                .font(.title)
            
            // Analytics options implementation
            
            HStack {
                Button("Cancel") {
                    isPresented = false
                }
                
                Button("Start Analysis") {
                    // Start analysis
                    isPresented = false
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .frame(width: 400, height: 300)
    }
}

struct MacExportOptionsView: View {
    @Binding var isPresented: Bool
    
    var body: some View {
        VStack {
            Text("Export Options")
                .font(.title)
            
            // Export options implementation
            
            HStack {
                Button("Cancel") {
                    isPresented = false
                }
                
                Button("Export") {
                    // Start export
                    isPresented = false
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .frame(width: 400, height: 300)
    }
}

#Preview {
    MacDashboardView()
        .frame(width: 1000, height: 700)
}
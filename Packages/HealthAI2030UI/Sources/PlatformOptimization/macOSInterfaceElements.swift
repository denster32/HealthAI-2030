import SwiftUI
import AppKit

// MARK: - macOS Platform Optimization
/// Optimized interface elements specifically designed for macOS platform
/// Handles macOS-specific design patterns, window management, and desktop-optimized components

// MARK: - macOS-Specific Design System
struct macOSDesignSystem {
    /// macOS-specific color palette optimized for desktop displays
    static let colors = macOSColorPalette()
    
    /// macOS-specific typography optimized for desktop readability
    static let typography = macOSTypography()
    
    /// macOS-specific spacing and layout guidelines
    static let layout = macOSLayoutGuide()
    
    /// macOS-specific window management
    static let window = macOSWindowManagement()
}

// MARK: - macOS Color Palette
struct macOSColorPalette {
    /// Primary colors optimized for macOS
    let primary = Color(red: 0.0, green: 0.478, blue: 1.0)
    let secondary = Color(red: 0.584, green: 0.584, blue: 0.584)
    let accent = Color(red: 1.0, green: 0.231, blue: 0.188)
    
    /// Health-specific colors
    let heartRate = Color(red: 1.0, green: 0.231, blue: 0.188)
    let bloodPressure = Color(red: 0.0, green: 0.478, blue: 1.0)
    let sleep = Color(red: 0.584, green: 0.0, blue: 0.827)
    let activity = Color(red: 0.0, green: 0.827, blue: 0.584)
    
    /// Background colors optimized for macOS
    let background = Color(NSColor.windowBackgroundColor)
    let secondaryBackground = Color(NSColor.controlBackgroundColor)
    let tertiaryBackground = Color(NSColor.textBackgroundColor)
    
    /// Text colors optimized for macOS
    let primaryText = Color(NSColor.labelColor)
    let secondaryText = Color(NSColor.secondaryLabelColor)
    let tertiaryText = Color(NSColor.tertiaryLabelColor)
}

// MARK: - macOS Typography
struct macOSTypography {
    /// macOS-optimized font sizes and weights
    let largeTitle = Font.largeTitle.weight(.bold)
    let title1 = Font.title.weight(.semibold)
    let title2 = Font.title2.weight(.semibold)
    let title3 = Font.title3.weight(.medium)
    let headline = Font.headline.weight(.semibold)
    let body = Font.body
    let callout = Font.callout
    let subheadline = Font.subheadline
    let footnote = Font.footnote
    let caption1 = Font.caption
    let caption2 = Font.caption2
    
    /// Health-specific typography for desktop
    let healthMetric = Font.system(size: 64, weight: .bold, design: .rounded)
    let healthLabel = Font.system(size: 18, weight: .medium, design: .rounded)
    let healthUnit = Font.system(size: 16, weight: .regular, design: .rounded)
}

// MARK: - macOS Layout Guide
struct macOSLayoutGuide {
    /// macOS-specific spacing
    let spacing: CGFloat = 20
    let smallSpacing: CGFloat = 12
    let largeSpacing: CGFloat = 32
    let extraLargeSpacing: CGFloat = 48
    
    /// macOS-specific corner radius
    let cornerRadius: CGFloat = 8
    let smallCornerRadius: CGFloat = 6
    let largeCornerRadius: CGFloat = 12
    
    /// macOS-specific padding
    let padding: CGFloat = 20
    let smallPadding: CGFloat = 12
    let largePadding: CGFloat = 32
    
    /// macOS-specific window dimensions
    let minWindowWidth: CGFloat = 800
    let minWindowHeight: CGFloat = 600
    let preferredWindowWidth: CGFloat = 1200
    let preferredWindowHeight: CGFloat = 800
}

// MARK: - macOS Window Management
struct macOSWindowManagement {
    /// Window configuration for health dashboard
    let dashboardWindow = WindowConfiguration(
        title: "HealthAI 2030 Dashboard",
        width: 1200,
        height: 800,
        minWidth: 800,
        minHeight: 600
    )
    
    /// Window configuration for detailed health views
    let detailWindow = WindowConfiguration(
        title: "Health Details",
        width: 1000,
        height: 700,
        minWidth: 600,
        minHeight: 400
    )
    
    /// Window configuration for settings
    let settingsWindow = WindowConfiguration(
        title: "HealthAI Settings",
        width: 600,
        height: 500,
        minWidth: 500,
        minHeight: 400
    )
}

struct WindowConfiguration {
    let title: String
    let width: CGFloat
    let height: CGFloat
    let minWidth: CGFloat
    let minHeight: CGFloat
}

// MARK: - macOS Menu Bar Integration
@available(macOS 15.0, *)
public struct MacMenuBarView: View {
    @StateObject private var menuBarManager = MacMenuBarManager.shared
    @State private var showingPopover = false
    
    public var body: some View {
        HStack(spacing: macOSDesignSystem.layout.smallSpacing) {
            // Health Status Indicator
            MacHealthStatusIndicator()
            
            Divider()
                .frame(height: 20)
            
            // Quick Actions
            MacQuickActionButtons()
            
            Divider()
                .frame(height: 20)
            
            // System Status
            MacSystemStatusView()
        }
        .padding(.horizontal, macOSDesignSystem.layout.padding)
        .background(VisualEffectView(material: .hudWindow, blendingMode: .behindWindow))
        .cornerRadius(macOSDesignSystem.layout.cornerRadius)
        .onTapGesture {
            showingPopover.toggle()
        }
        .popover(isPresented: $showingPopover) {
            MacMenuBarPopover()
        }
    }
}

// MARK: - macOS Health Status Indicator
struct MacHealthStatusIndicator: View {
    @StateObject private var healthManager = HealthDataManager.shared
    
    var body: some View {
        HStack(spacing: macOSDesignSystem.layout.smallSpacing) {
            Circle()
                .fill(healthStatusColor)
                .frame(width: 8, height: 8)
            
            Text("\(Int(healthManager.currentHeartRate))")
                .font(macOSDesignSystem.typography.caption1)
                .fontWeight(.medium)
                .foregroundColor(macOSDesignSystem.colors.primaryText)
        }
        .onTapGesture {
            NSApp.activate(ignoringOtherApps: true)
        }
    }
    
    private var healthStatusColor: Color {
        let hr = healthManager.currentHeartRate
        switch hr {
        case 0..<60: return macOSDesignSystem.colors.accent
        case 60..<100: return macOSDesignSystem.colors.activity
        default: return macOSDesignSystem.colors.heartRate
        }
    }
}

// MARK: - macOS Quick Action Buttons
struct MacQuickActionButtons: View {
    var body: some View {
        HStack(spacing: macOSDesignSystem.layout.smallSpacing) {
            MacQuickActionButton(icon: "heart.fill", action: "Record Heart Rate") {
                // Record heart rate action
            }
            
            MacQuickActionButton(icon: "bed.double.fill", action: "Sleep Tracking") {
                // Sleep tracking action
            }
            
            MacQuickActionButton(icon: "figure.walk", action: "Activity") {
                // Activity action
            }
        }
    }
}

struct MacQuickActionButton: View {
    let icon: String
    let action: String
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(macOSDesignSystem.colors.primaryText)
                .frame(width: 24, height: 24)
        }
        .buttonStyle(PlainButtonStyle())
        .help(action)
    }
}

// MARK: - macOS System Status View
struct MacSystemStatusView: View {
    @StateObject private var performanceMonitor = HealthAIPerformance.PerformanceMonitor()
    
    var body: some View {
        HStack(spacing: macOSDesignSystem.layout.smallSpacing) {
            // CPU Usage
            MacStatusIndicator(
                icon: "cpu",
                value: "\(Int(performanceMonitor.cpuUsage * 100))%",
                color: performanceMonitor.cpuUsage > 0.8 ? macOSDesignSystem.colors.accent : macOSDesignSystem.colors.activity
            )
            
            // Memory Usage
            MacStatusIndicator(
                icon: "memorychip",
                value: "\(Int(performanceMonitor.memoryUsage * 100))%",
                color: performanceMonitor.memoryUsage > 0.8 ? macOSDesignSystem.colors.accent : macOSDesignSystem.colors.activity
            )
        }
    }
}

struct MacStatusIndicator: View {
    let icon: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(color)
            
            Text(value)
                .font(macOSDesignSystem.typography.caption2)
                .foregroundColor(macOSDesignSystem.colors.secondaryText)
        }
    }
}

// MARK: - macOS Menu Bar Popover
struct MacMenuBarPopover: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: macOSDesignSystem.layout.spacing) {
            // Header
            HStack {
                Text("HealthAI 2030")
                    .font(macOSDesignSystem.typography.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("Close") {
                    dismiss()
                }
                .buttonStyle(.bordered)
            }
            
            Divider()
            
            // Quick Actions
            VStack(spacing: macOSDesignSystem.layout.smallSpacing) {
                MacPopoverActionButton(title: "Open Dashboard", icon: "heart.text.square") {
                    NSApp.activate(ignoringOtherApps: true)
                    dismiss()
                }
                
                MacPopoverActionButton(title: "Record Health Data", icon: "plus.circle") {
                    // Record health data
                    dismiss()
                }
                
                MacPopoverActionButton(title: "View Trends", icon: "chart.line.uptrend.xyaxis") {
                    // View trends
                    dismiss()
                }
            }
            
            Divider()
            
            // System Controls
            VStack(spacing: macOSDesignSystem.layout.smallSpacing) {
                MacPopoverActionButton(title: "Settings", icon: "gear") {
                    // Open settings
                    dismiss()
                }
                
                MacPopoverActionButton(title: "Sync Data", icon: "arrow.clockwise") {
                    // Sync data
                    dismiss()
                }
                
                MacPopoverActionButton(title: "Export Report", icon: "square.and.arrow.up") {
                    // Export report
                    dismiss()
                }
            }
            
            Divider()
            
            // Status Information
            MacStatusSection()
        }
        .padding(macOSDesignSystem.layout.padding)
        .frame(width: 280)
    }
}

struct MacPopoverActionButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(macOSDesignSystem.colors.primary)
                    .frame(width: 20)
                
                Text(title)
                    .font(macOSDesignSystem.typography.body)
                    .foregroundColor(macOSDesignSystem.colors.primaryText)
                
                Spacer()
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(Color.clear)
            .cornerRadius(macOSDesignSystem.layout.smallCornerRadius)
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            // Add hover effect
        }
    }
}

struct MacStatusSection: View {
    @StateObject private var healthManager = HealthDataManager.shared
    @StateObject private var performanceMonitor = HealthAIPerformance.PerformanceMonitor()
    
    var body: some View {
        VStack(spacing: macOSDesignSystem.layout.smallSpacing) {
            HStack {
                Text("System Status")
                    .font(macOSDesignSystem.typography.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(macOSDesignSystem.colors.primaryText)
                
                Spacer()
            }
            
            VStack(spacing: 8) {
                MacStatusRow(label: "Heart Rate", value: "\(Int(healthManager.currentHeartRate)) BPM", status: .healthy)
                MacStatusRow(label: "CPU Usage", value: "\(Int(performanceMonitor.cpuUsage * 100))%", status: performanceMonitor.cpuUsage > 0.8 ? .warning : .healthy)
                MacStatusRow(label: "Memory", value: "\(Int(performanceMonitor.memoryUsage * 100))%", status: performanceMonitor.memoryUsage > 0.8 ? .warning : .healthy)
            }
        }
    }
}

struct MacStatusRow: View {
    let label: String
    let value: String
    let status: HealthStatus
    
    var body: some View {
        HStack {
            Text(label)
                .font(macOSDesignSystem.typography.caption1)
                .foregroundColor(macOSDesignSystem.colors.secondaryText)
            
            Spacer()
            
            Text(value)
                .font(macOSDesignSystem.typography.caption1)
                .fontWeight(.medium)
                .foregroundColor(statusColor)
        }
    }
    
    private var statusColor: Color {
        switch status {
        case .healthy: return macOSDesignSystem.colors.activity
        case .elevated: return macOSDesignSystem.colors.accent
        case .critical: return macOSDesignSystem.colors.heartRate
        case .unknown: return macOSDesignSystem.colors.secondaryText
        }
    }
}

// MARK: - macOS Menu Bar Manager
class MacMenuBarManager: ObservableObject {
    public static let shared = MacMenuBarManager()
    
    @Published public var isMenuBarVisible = true
    @Published public var currentHealthStatus: HealthStatus = .healthy
    @Published public var lastSyncTime = Date()
    
    private init() {
        setupMenuBar()
    }
    
    private func setupMenuBar() {
        // Setup menu bar integration
        // This would typically involve NSStatusItem setup
    }
    
    public func updateHealthStatus(_ status: HealthStatus) {
        DispatchQueue.main.async {
            self.currentHealthStatus = status
        }
    }
    
    public func syncData() {
        // Sync health data
        DispatchQueue.main.async {
            self.lastSyncTime = Date()
        }
    }
}

// MARK: - Visual Effect View for macOS
struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}

// MARK: - macOS-Optimized Components

// MARK: - macOS Sidebar
struct macOSHealthSidebar: View {
    @Binding var selectedSection: String
    let sections: [SidebarSection]
    
    var body: some View {
        VStack(spacing: 0) {
            ForEach(sections, id: \.id) { section in
                VStack(alignment: .leading, spacing: 0) {
                    if let header = section.header {
                        Text(header)
                            .font(macOSDesignSystem.typography.caption1)
                            .foregroundColor(macOSDesignSystem.colors.secondaryText)
                            .padding(.horizontal, macOSDesignSystem.layout.padding)
                            .padding(.vertical, macOSDesignSystem.layout.smallPadding)
                    }
                    
                    ForEach(section.items, id: \.id) { item in
                        macOSSidebarItem(
                            item: item,
                            isSelected: selectedSection == item.id
                        ) {
                            selectedSection = item.id
                        }
                    }
                }
            }
            
            Spacer()
        }
        .frame(width: 250)
        .background(macOSDesignSystem.colors.secondaryBackground)
        .overlay(
            Rectangle()
                .frame(width: 1)
                .foregroundColor(Color.gray.opacity(0.3)),
            alignment: .trailing
        )
    }
}

struct SidebarSection {
    let id: String
    let header: String?
    let items: [SidebarItem]
}

struct SidebarItem {
    let id: String
    let title: String
    let icon: String
    let badge: String?
}

struct macOSSidebarItem: View {
    let item: SidebarItem
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: item.icon)
                    .font(.title3)
                    .frame(width: 20)
                
                Text(item.title)
                    .font(macOSDesignSystem.typography.body)
                    .foregroundColor(isSelected ? macOSDesignSystem.colors.primary : macOSDesignSystem.colors.primaryText)
                
                Spacer()
                
                if let badge = item.badge {
                    Text(badge)
                        .font(macOSDesignSystem.typography.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(macOSDesignSystem.colors.primary)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
            .padding(.horizontal, macOSDesignSystem.layout.padding)
            .padding(.vertical, macOSDesignSystem.layout.smallPadding)
            .background(isSelected ? macOSDesignSystem.colors.primary.opacity(0.1) : Color.clear)
            .cornerRadius(macOSDesignSystem.layout.smallCornerRadius)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - macOS Toolbar
struct macOSHealthToolbar: View {
    @Binding var selectedTab: String
    let tabs: [String]
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(tabs, id: \.self) { tab in
                macOSToolbarButton(
                    title: tab,
                    isSelected: selectedTab == tab
                ) {
                    selectedTab = tab
                }
            }
        }
        .background(macOSDesignSystem.colors.secondaryBackground)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color.gray.opacity(0.3)),
            alignment: .bottom
        )
    }
}

struct macOSToolbarButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(macOSDesignSystem.typography.body)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? macOSDesignSystem.colors.primary : macOSDesignSystem.colors.secondaryText)
                .padding(.horizontal, macOSDesignSystem.layout.padding)
                .padding(.vertical, macOSDesignSystem.layout.smallPadding)
                .background(isSelected ? macOSDesignSystem.colors.primary.opacity(0.1) : Color.clear)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - macOS Status Bar
struct macOSStatusBar: View {
    let message: String
    let status: StatusType
    
    enum StatusType {
        case info, success, warning, error
    }
    
    var body: some View {
        HStack {
            Image(systemName: statusIcon)
                .foregroundColor(statusColor)
                .font(.system(size: 14, weight: .medium))
            
            Text(message)
                .font(macOSDesignSystem.typography.body)
                .foregroundColor(macOSDesignSystem.colors.primaryText)
            
            Spacer()
        }
        .padding(macOSDesignSystem.layout.padding)
        .background(statusColor.opacity(0.1))
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(statusColor.opacity(0.3)),
            alignment: .top
        )
    }
    
    private var statusIcon: String {
        switch status {
        case .info: return "info.circle"
        case .success: return "checkmark.circle"
        case .warning: return "exclamationmark.triangle"
        case .error: return "xmark.circle"
        }
    }
    
    private var statusColor: Color {
        switch status {
        case .info: return macOSDesignSystem.colors.primary
        case .success: return macOSDesignSystem.colors.activity
        case .warning: return macOSDesignSystem.colors.accent
        case .error: return macOSDesignSystem.colors.heartRate
        }
    }
}

// MARK: - macOS Window Controls
struct macOSWindowControls: View {
    let onClose: () -> Void
    let onMinimize: () -> Void
    let onMaximize: () -> Void
    
    var body: some View {
        HStack(spacing: 8) {
            // Close button
            Button(action: onClose) {
                Circle()
                    .fill(Color.red)
                    .frame(width: 12, height: 12)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Minimize button
            Button(action: onMinimize) {
                Circle()
                    .fill(Color.orange)
                    .frame(width: 12, height: 12)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Maximize button
            Button(action: onMaximize) {
                Circle()
                    .fill(Color.green)
                    .frame(width: 12, height: 12)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, macOSDesignSystem.layout.smallPadding)
    }
}

// MARK: - macOS Health Dashboard Grid
struct macOSHealthDashboardGrid: View {
    let metrics: [HealthMetric]
    let columns: Int
    
    var body: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: macOSDesignSystem.layout.spacing), count: columns),
            spacing: macOSDesignSystem.layout.spacing
        ) {
            ForEach(metrics, id: \.id) { metric in
                macOSHealthMetricCard(metric: metric)
            }
        }
        .padding(macOSDesignSystem.layout.padding)
    }
}

struct HealthMetric {
    let id: String
    let title: String
    let value: String
    let unit: String
    let trend: HealthTrend?
    let color: Color
}

struct macOSHealthMetricCard: View {
    let metric: HealthMetric
    
    var body: some View {
        VStack(alignment: .leading, spacing: macOSDesignSystem.layout.spacing) {
            HStack {
                Text(metric.title)
                    .font(macOSDesignSystem.typography.headline)
                    .foregroundColor(macOSDesignSystem.colors.primaryText)
                
                Spacer()
                
                if let trend = metric.trend {
                    macOSHealthTrendIndicator(trend: trend)
                }
            }
            
            HStack(alignment: .bottom, spacing: 8) {
                Text(metric.value)
                    .font(macOSDesignSystem.typography.healthMetric)
                    .foregroundColor(metric.color)
                
                Text(metric.unit)
                    .font(macOSDesignSystem.typography.healthUnit)
                    .foregroundColor(macOSDesignSystem.colors.secondaryText)
            }
        }
        .padding(macOSDesignSystem.layout.padding)
        .background(macOSDesignSystem.colors.secondaryBackground)
        .cornerRadius(macOSDesignSystem.layout.cornerRadius)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

struct macOSHealthTrendIndicator: View {
    let trend: HealthTrend
    
    var body: some View {
        Image(systemName: trend.icon)
            .foregroundColor(trend.color)
            .font(.title2)
    }
}

// MARK: - macOS Data Table
struct macOSHealthDataTable: View {
    let data: [HealthDataRow]
    let columns: [TableColumn]
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 0) {
                ForEach(columns, id: \.id) { column in
                    Text(column.title)
                        .font(macOSDesignSystem.typography.headline)
                        .foregroundColor(macOSDesignSystem.colors.primaryText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(macOSDesignSystem.layout.smallPadding)
                        .background(macOSDesignSystem.colors.secondaryBackground)
                }
            }
            
            // Data rows
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(data, id: \.id) { row in
                        macOSHealthDataRow(row: row, columns: columns)
                    }
                }
            }
        }
        .background(macOSDesignSystem.colors.background)
        .cornerRadius(macOSDesignSystem.layout.cornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: macOSDesignSystem.layout.cornerRadius)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
    }
}

struct TableColumn {
    let id: String
    let title: String
    let width: CGFloat?
}

struct HealthDataRow {
    let id: String
    let values: [String]
}

struct macOSHealthDataRow: View {
    let row: HealthDataRow
    let columns: [TableColumn]
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(columns.enumerated()), id: \.offset) { index, column in
                Text(row.values[index])
                    .font(macOSDesignSystem.typography.body)
                    .foregroundColor(macOSDesignSystem.colors.primaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(macOSDesignSystem.layout.smallPadding)
            }
        }
        .background(macOSDesignSystem.colors.background)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color.gray.opacity(0.2)),
            alignment: .bottom
        )
    }
}

// MARK: - macOS Chart Container
struct macOSChartContainer<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: macOSDesignSystem.layout.spacing) {
            Text(title)
                .font(macOSDesignSystem.typography.title3)
                .foregroundColor(macOSDesignSystem.colors.primaryText)
            
            content
                .frame(height: 300)
        }
        .padding(macOSDesignSystem.layout.padding)
        .background(macOSDesignSystem.colors.secondaryBackground)
        .cornerRadius(macOSDesignSystem.layout.cornerRadius)
    }
}

// MARK: - macOS Preview
struct macOSInterfaceElements_Previews: PreviewProvider {
    static var previews: some View {
        HStack(spacing: 0) {
            macOSHealthSidebar(
                selectedSection: .constant("dashboard"),
                sections: [
                    SidebarSection(
                        id: "main",
                        header: "Main",
                        items: [
                            SidebarItem(id: "dashboard", title: "Dashboard", icon: "house", badge: nil),
                            SidebarItem(id: "activity", title: "Activity", icon: "figure.walk", badge: "3"),
                            SidebarItem(id: "health", title: "Health", icon: "heart", badge: nil)
                        ]
                    )
                ]
            )
            
            VStack(spacing: 0) {
                macOSHealthToolbar(
                    selectedTab: .constant("dashboard"),
                    tabs: ["Dashboard", "Activity", "Health"]
                )
                
                macOSHealthDashboardGrid(
                    metrics: [
                        HealthMetric(id: "1", title: "Heart Rate", value: "72", unit: "bpm", trend: .up, color: .red),
                        HealthMetric(id: "2", title: "Blood Pressure", value: "120/80", unit: "mmHg", trend: .stable, color: .blue)
                    ],
                    columns: 2
                )
            }
        }
        .frame(width: 1000, height: 600)
        .previewLayout(.sizeThatFits)
    }
} 
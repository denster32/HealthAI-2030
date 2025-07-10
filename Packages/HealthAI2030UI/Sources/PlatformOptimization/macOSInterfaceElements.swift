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
                
                Spacer()
                
                if let badge = item.badge {
                    Text(badge)
                        .font(macOSDesignSystem.typography.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.red)
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal, macOSDesignSystem.layout.padding)
            .padding(.vertical, macOSDesignSystem.layout.smallPadding)
            .background(isSelected ? macOSDesignSystem.colors.primary.opacity(0.1) : Color.clear)
            .foregroundColor(isSelected ? macOSDesignSystem.colors.primary : macOSDesignSystem.colors.primaryText)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - macOS Toolbar
struct macOSHealthToolbar: View {
    let title: String
    let leftItems: [ToolbarItem]
    let rightItems: [ToolbarItem]
    
    var body: some View {
        HStack {
            HStack(spacing: macOSDesignSystem.layout.smallSpacing) {
                ForEach(leftItems, id: \.id) { item in
                    macOSToolbarButton(item: item)
                }
            }
            
            Spacer()
            
            Text(title)
                .font(macOSDesignSystem.typography.title2)
                .foregroundColor(macOSDesignSystem.colors.primaryText)
            
            Spacer()
            
            HStack(spacing: macOSDesignSystem.layout.smallSpacing) {
                ForEach(rightItems, id: \.id) { item in
                    macOSToolbarButton(item: item)
                }
            }
        }
        .padding(.horizontal, macOSDesignSystem.layout.padding)
        .padding(.vertical, macOSDesignSystem.layout.smallPadding)
        .background(macOSDesignSystem.colors.background)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color.gray.opacity(0.3)),
            alignment: .bottom
        )
    }
}

struct ToolbarItem {
    let id: String
    let icon: String
    let title: String
    let action: () -> Void
}

struct macOSToolbarButton: View {
    let item: ToolbarItem
    
    var body: some View {
        Button(action: item.action) {
            VStack(spacing: 4) {
                Image(systemName: item.icon)
                    .font(.title3)
                
                Text(item.title)
                    .font(macOSDesignSystem.typography.caption2)
            }
            .foregroundColor(macOSDesignSystem.colors.primary)
        }
        .buttonStyle(PlainButtonStyle())
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

// MARK: - macOS Menu Bar Integration
struct macOSMenuBarIntegration {
    static func createMenuBar() -> NSMenu {
        let menu = NSMenu()
        
        // HealthAI menu
        let healthAIMenu = NSMenu()
        healthAIMenu.addItem(NSMenuItem(title: "About HealthAI 2030", action: #selector(NSApplication.shared.orderFrontStandardAboutPanel(_:)), keyEquivalent: ""))
        healthAIMenu.addItem(NSMenuItem.separator())
        healthAIMenu.addItem(NSMenuItem(title: "Quit HealthAI 2030", action: #selector(NSApplication.shared.terminate(_:)), keyEquivalent: "q"))
        
        let healthAIItem = NSMenuItem(title: "HealthAI 2030", action: nil, keyEquivalent: "")
        healthAIItem.submenu = healthAIMenu
        menu.addItem(healthAIItem)
        
        // File menu
        let fileMenu = NSMenu()
        fileMenu.addItem(NSMenuItem(title: "New Dashboard", action: #selector(NSDocumentController.shared.newDocument(_:)), keyEquivalent: "n"))
        fileMenu.addItem(NSMenuItem(title: "Open...", action: #selector(NSDocumentController.shared.openDocument(_:)), keyEquivalent: "o"))
        fileMenu.addItem(NSMenuItem.separator())
        fileMenu.addItem(NSMenuItem(title: "Save", action: #selector(NSDocument.save(_:)), keyEquivalent: "s"))
        
        let fileItem = NSMenuItem(title: "File", action: nil, keyEquivalent: "")
        fileItem.submenu = fileMenu
        menu.addItem(fileItem)
        
        // View menu
        let viewMenu = NSMenu()
        viewMenu.addItem(NSMenuItem(title: "Show Dashboard", action: #selector(NSWindow.makeKeyAndOrderFront(_:)), keyEquivalent: "1"))
        viewMenu.addItem(NSMenuItem(title: "Show Details", action: #selector(NSWindow.makeKeyAndOrderFront(_:)), keyEquivalent: "2"))
        
        let viewItem = NSMenuItem(title: "View", action: nil, keyEquivalent: "")
        viewItem.submenu = viewMenu
        menu.addItem(viewItem)
        
        return menu
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
                    title: "Health Dashboard",
                    leftItems: [
                        ToolbarItem(id: "refresh", icon: "arrow.clockwise", title: "Refresh") {}
                    ],
                    rightItems: [
                        ToolbarItem(id: "settings", icon: "gear", title: "Settings") {}
                    ]
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
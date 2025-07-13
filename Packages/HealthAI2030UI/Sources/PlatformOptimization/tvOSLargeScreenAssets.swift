import SwiftUI
#if canImport(TVUIKit)
import TVUIKit
#endif

// MARK: - tvOS Platform Optimization
/// Large screen assets and components specifically designed for tvOS platform
/// Handles tvOS-specific design patterns, large screen layouts, and remote-optimized components

// MARK: - tvOS-Specific Design System
struct tvOSDesignSystem {
    /// tvOS-specific color palette optimized for large displays
    static let colors = tvOSColorPalette()
    
    /// tvOS-specific typography optimized for large screens
    static let typography = tvOSTypography()
    
    /// tvOS-specific spacing and layout guidelines
    static let layout = tvOSLayoutGuide()
    
    /// tvOS-specific focus management
    static let focus = tvOSFocusManagement()
}

// MARK: - tvOS Color Palette
struct tvOSColorPalette {
    /// Primary colors optimized for tvOS
    let primary = Color(red: 0.0, green: 0.478, blue: 1.0)
    let secondary = Color(red: 0.584, green: 0.584, blue: 0.584)
    let accent = Color(red: 1.0, green: 0.231, blue: 0.188)
    
    /// Health-specific colors for TV
    let heartRate = Color(red: 1.0, green: 0.231, blue: 0.188)
    let bloodPressure = Color(red: 0.0, green: 0.478, blue: 1.0)
    let sleep = Color(red: 0.584, green: 0.0, blue: 0.827)
    let activity = Color(red: 0.0, green: 0.827, blue: 0.584)
    
    /// Background colors optimized for tvOS
    let background = Color.black
    let secondaryBackground = Color(red: 0.1, green: 0.1, blue: 0.1)
    let tertiaryBackground = Color(red: 0.15, green: 0.15, blue: 0.15)
    
    /// Text colors optimized for tvOS
    let primaryText = Color.white
    let secondaryText = Color(red: 0.8, green: 0.8, blue: 0.8)
    let tertiaryText = Color(red: 0.6, green: 0.6, blue: 0.6)
    
    /// Focus colors for tvOS
    let focusColor = Color(red: 0.0, green: 0.478, blue: 1.0)
    let focusBackground = Color(red: 0.2, green: 0.2, blue: 0.2)
}

// MARK: - tvOS Typography
struct tvOSTypography {
    /// tvOS-optimized font sizes and weights
    let largeTitle = Font.system(size: 72, weight: .bold, design: .rounded)
    let title1 = Font.system(size: 48, weight: .semibold, design: .rounded)
    let title2 = Font.system(size: 36, weight: .semibold, design: .rounded)
    let title3 = Font.system(size: 28, weight: .medium, design: .rounded)
    let headline = Font.system(size: 24, weight: .semibold, design: .rounded)
    let body = Font.system(size: 20, weight: .regular, design: .rounded)
    let callout = Font.system(size: 18, weight: .medium, design: .rounded)
    let subheadline = Font.system(size: 16, weight: .medium, design: .rounded)
    let footnote = Font.system(size: 14, weight: .regular, design: .rounded)
    let caption1 = Font.system(size: 12, weight: .regular, design: .rounded)
    let caption2 = Font.system(size: 10, weight: .regular, design: .rounded)
    
    /// Health-specific typography for TV
    let healthMetric = Font.system(size: 96, weight: .bold, design: .rounded)
    let healthLabel = Font.system(size: 24, weight: .medium, design: .rounded)
    let healthUnit = Font.system(size: 20, weight: .regular, design: .rounded)
}

// MARK: - tvOS Layout Guide
struct tvOSLayoutGuide {
    /// tvOS-specific spacing
    let spacing: CGFloat = 40
    let smallSpacing: CGFloat = 20
    let largeSpacing: CGFloat = 60
    let extraLargeSpacing: CGFloat = 80
    
    /// tvOS-specific corner radius
    let cornerRadius: CGFloat = 20
    let smallCornerRadius: CGFloat = 12
    let largeCornerRadius: CGFloat = 32
    
    /// tvOS-specific padding
    let padding: CGFloat = 40
    let smallPadding: CGFloat = 20
    let largePadding: CGFloat = 60
    
    /// tvOS-specific screen dimensions
    let screenWidth: CGFloat = 1920
    let screenHeight: CGFloat = 1080
    let contentWidth: CGFloat = 1600
    let contentHeight: CGFloat = 900
}

// MARK: - tvOS Focus Management
struct tvOSFocusManagement {
    /// Focus state management
    static func focusable(_ view: some View, isFocused: Bool) -> some View {
        view
            .scaleEffect(isFocused ? 1.1 : 1.0)
            .shadow(color: isFocused ? tvOSDesignSystem.colors.focusColor : Color.clear, radius: 20)
            .animation(.easeInOut(duration: 0.2), value: isFocused)
    }
}

// MARK: - tvOS-Optimized Components

// MARK: - tvOS Health Metric Card
struct tvOSHealthMetricCard: View {
    let title: String
    let value: String
    let unit: String
    let trend: HealthTrend?
    let color: Color
    @State private var isFocused = false
    
    var body: some View {
        VStack(spacing: tvOSDesignSystem.layout.spacing) {
            Text(title)
                .font(tvOSDesignSystem.typography.healthLabel)
                .foregroundColor(tvOSDesignSystem.colors.secondaryText)
                .lineLimit(1)
            
            HStack(alignment: .bottom, spacing: 8) {
                Text(value)
                    .font(tvOSDesignSystem.typography.healthMetric)
                    .foregroundColor(color)
                    .lineLimit(1)
                
                Text(unit)
                    .font(tvOSDesignSystem.typography.healthUnit)
                    .foregroundColor(tvOSDesignSystem.colors.secondaryText)
                    .lineLimit(1)
            }
            
            if let trend = trend {
                tvOSHealthTrendIndicator(trend: trend)
            }
        }
        .padding(tvOSDesignSystem.layout.padding)
        .background(tvOSDesignSystem.colors.secondaryBackground)
        .cornerRadius(tvOSDesignSystem.layout.cornerRadius)
        .modifier(tvOSFocusManagement.focusable(isFocused: isFocused))
        .onTapGesture {
            // Handle tap
        }
    }
}

struct tvOSHealthTrendIndicator: View {
    let trend: HealthTrend
    
    var body: some View {
        Image(systemName: trend.icon)
            .foregroundColor(trend.color)
            .font(.title)
    }
}

// MARK: - tvOS Large Grid
struct tvOSLargeGrid<Content: View>: View {
    let items: [Any]
    let columns: Int
    let content: (Any) -> Content
    
    var body: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: tvOSDesignSystem.layout.spacing), count: columns),
            spacing: tvOSDesignSystem.layout.spacing
        ) {
            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                content(item)
            }
        }
        .padding(tvOSDesignSystem.layout.padding)
    }
}

// MARK: - tvOS Large Button
struct tvOSLargeButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    @State private var isFocused = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: tvOSDesignSystem.layout.smallSpacing) {
                Image(systemName: icon)
                    .font(tvOSDesignSystem.typography.title3)
                    .foregroundColor(color)
                
                Text(title)
                    .font(tvOSDesignSystem.typography.headline)
                    .foregroundColor(tvOSDesignSystem.colors.primaryText)
            }
            .padding(tvOSDesignSystem.layout.padding)
            .background(isFocused ? tvOSDesignSystem.colors.focusBackground : tvOSDesignSystem.colors.secondaryBackground)
            .cornerRadius(tvOSDesignSystem.layout.cornerRadius)
            .modifier(tvOSFocusManagement.focusable(isFocused: isFocused))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - tvOS Large Chart
struct tvOSLargeChart: View {
    let title: String
    let data: [ChartDataPoint]
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: tvOSDesignSystem.layout.spacing) {
            Text(title)
                .font(tvOSDesignSystem.typography.title2)
                .foregroundColor(tvOSDesignSystem.colors.primaryText)
            
            // Placeholder for chart visualization
            RoundedRectangle(cornerRadius: tvOSDesignSystem.layout.cornerRadius)
                .fill(color.opacity(0.2))
                .frame(height: 300)
                .overlay(
                    Text("Chart Visualization")
                        .font(tvOSDesignSystem.typography.body)
                        .foregroundColor(tvOSDesignSystem.colors.secondaryText)
                )
        }
        .padding(tvOSDesignSystem.layout.padding)
        .background(tvOSDesignSystem.colors.secondaryBackground)
        .cornerRadius(tvOSDesignSystem.layout.cornerRadius)
    }
}

struct ChartDataPoint {
    let label: String
    let value: Double
}

// MARK: - tvOS Health Dashboard
struct tvOSHealthDashboard: View {
    @State private var selectedSection = 0
    
    var body: some View {
        VStack(spacing: tvOSDesignSystem.layout.largeSpacing) {
            // Header
            tvOSDashboardHeader()
            
            // Main content
            TabView(selection: $selectedSection) {
                tvOSOverviewSection()
                    .tag(0)
                
                tvOSActivitySection()
                    .tag(1)
                
                tvOSHealthSection()
                    .tag(2)
            }
            .tabViewStyle(PageTabViewStyle())
            .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
        }
        .background(tvOSDesignSystem.colors.background)
    }
}

struct tvOSDashboardHeader: View {
    var body: some View {
        VStack(spacing: tvOSDesignSystem.layout.spacing) {
            Text("HealthAI 2030 Dashboard")
                .font(tvOSDesignSystem.typography.largeTitle)
                .foregroundColor(tvOSDesignSystem.colors.primaryText)
            
            Text("Your comprehensive health overview")
                .font(tvOSDesignSystem.typography.body)
                .foregroundColor(tvOSDesignSystem.colors.secondaryText)
        }
        .padding(tvOSDesignSystem.layout.largePadding)
    }
}

struct tvOSOverviewSection: View {
    var body: some View {
        VStack(spacing: tvOSDesignSystem.layout.largeSpacing) {
            // Main metrics grid
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: tvOSDesignSystem.layout.spacing), count: 3),
                spacing: tvOSDesignSystem.layout.spacing
            ) {
                tvOSHealthMetricCard(
                    title: "Heart Rate",
                    value: "72",
                    unit: "bpm",
                    trend: .up,
                    color: tvOSDesignSystem.colors.heartRate
                )
                
                tvOSHealthMetricCard(
                    title: "Blood Pressure",
                    value: "120/80",
                    unit: "mmHg",
                    trend: .stable,
                    color: tvOSDesignSystem.colors.bloodPressure
                )
                
                tvOSHealthMetricCard(
                    title: "Sleep",
                    value: "7h 23m",
                    unit: "",
                    trend: .down,
                    color: tvOSDesignSystem.colors.sleep
                )
            }
            
            // Quick actions
            HStack(spacing: tvOSDesignSystem.layout.spacing) {
                tvOSLargeButton(
                    title: "Start Workout",
                    icon: "figure.run",
                    color: tvOSDesignSystem.colors.activity
                ) {}
                
                tvOSLargeButton(
                    title: "View Details",
                    icon: "chart.bar.fill",
                    color: tvOSDesignSystem.colors.primary
                ) {}
                
                tvOSLargeButton(
                    title: "Settings",
                    icon: "gear",
                    color: tvOSDesignSystem.colors.secondary
                ) {}
            }
        }
        .padding(tvOSDesignSystem.layout.largePadding)
    }
}

struct tvOSActivitySection: View {
    var body: some View {
        VStack(spacing: tvOSDesignSystem.layout.largeSpacing) {
            // Activity chart
            tvOSLargeChart(
                title: "Weekly Activity",
                data: [
                    ChartDataPoint(label: "Mon", value: 0.8),
                    ChartDataPoint(label: "Tue", value: 0.9),
                    ChartDataPoint(label: "Wed", value: 0.7),
                    ChartDataPoint(label: "Thu", value: 0.95),
                    ChartDataPoint(label: "Fri", value: 0.6),
                    ChartDataPoint(label: "Sat", value: 0.85),
                    ChartDataPoint(label: "Sun", value: 0.75)
                ],
                color: tvOSDesignSystem.colors.activity
            )
            
            // Activity stats
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: tvOSDesignSystem.layout.spacing), count: 2),
                spacing: tvOSDesignSystem.layout.spacing
            ) {
                tvOSActivityStatCard(
                    title: "Steps",
                    value: "8,432",
                    target: "10,000",
                    icon: "figure.walk",
                    color: tvOSDesignSystem.colors.activity
                )
                
                tvOSActivityStatCard(
                    title: "Calories",
                    value: "342",
                    target: "400",
                    icon: "flame",
                    color: tvOSDesignSystem.colors.accent
                )
            }
        }
        .padding(tvOSDesignSystem.layout.largePadding)
    }
}

struct tvOSActivityStatCard: View {
    let title: String
    let value: String
    let target: String
    let icon: String
    let color: Color
    @State private var isFocused = false
    
    var body: some View {
        VStack(spacing: tvOSDesignSystem.layout.spacing) {
            Image(systemName: icon)
                .font(tvOSDesignSystem.typography.title1)
                .foregroundColor(color)
            
            Text(title)
                .font(tvOSDesignSystem.typography.headline)
                .foregroundColor(tvOSDesignSystem.colors.primaryText)
            
            Text(value)
                .font(tvOSDesignSystem.typography.title2)
                .foregroundColor(color)
            
            Text("of \(target)")
                .font(tvOSDesignSystem.typography.body)
                .foregroundColor(tvOSDesignSystem.colors.secondaryText)
        }
        .padding(tvOSDesignSystem.layout.padding)
        .background(tvOSDesignSystem.colors.secondaryBackground)
        .cornerRadius(tvOSDesignSystem.layout.cornerRadius)
        .modifier(tvOSFocusManagement.focusable(isFocused: isFocused))
    }
}

struct tvOSHealthSection: View {
    var body: some View {
        VStack(spacing: tvOSDesignSystem.layout.largeSpacing) {
            // Health metrics grid
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: tvOSDesignSystem.layout.spacing), count: 2),
                spacing: tvOSDesignSystem.layout.spacing
            ) {
                tvOSHealthDetailCard(
                    title: "Heart Rate History",
                    subtitle: "Last 7 days",
                    icon: "heart.fill",
                    color: tvOSDesignSystem.colors.heartRate
                )
                
                tvOSHealthDetailCard(
                    title: "Blood Pressure Trends",
                    subtitle: "Monthly overview",
                    icon: "drop.fill",
                    color: tvOSDesignSystem.colors.bloodPressure
                )
                
                tvOSHealthDetailCard(
                    title: "Sleep Analysis",
                    subtitle: "Deep sleep patterns",
                    icon: "bed.double.fill",
                    color: tvOSDesignSystem.colors.sleep
                )
                
                tvOSHealthDetailCard(
                    title: "Stress Levels",
                    subtitle: "Weekly assessment",
                    icon: "brain.head.profile",
                    color: tvOSDesignSystem.colors.secondary
                )
            }
        }
        .padding(tvOSDesignSystem.layout.largePadding)
    }
}

struct tvOSHealthDetailCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    @State private var isFocused = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: tvOSDesignSystem.layout.spacing) {
            HStack {
                Image(systemName: icon)
                    .font(tvOSDesignSystem.typography.title2)
                    .foregroundColor(color)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(tvOSDesignSystem.typography.body)
                    .foregroundColor(tvOSDesignSystem.colors.tertiaryText)
            }
            
            VStack(alignment: .leading, spacing: tvOSDesignSystem.layout.smallSpacing) {
                Text(title)
                    .font(tvOSDesignSystem.typography.headline)
                    .foregroundColor(tvOSDesignSystem.colors.primaryText)
                    .lineLimit(1)
                
                Text(subtitle)
                    .font(tvOSDesignSystem.typography.body)
                    .foregroundColor(tvOSDesignSystem.colors.secondaryText)
                    .lineLimit(1)
            }
        }
        .padding(tvOSDesignSystem.layout.padding)
        .background(tvOSDesignSystem.colors.secondaryBackground)
        .cornerRadius(tvOSDesignSystem.layout.cornerRadius)
        .modifier(tvOSFocusManagement.focusable(isFocused: isFocused))
    }
}

// MARK: - tvOS Remote Navigation
struct tvOSRemoteNavigation {
    /// Handle remote navigation events
    static func handleRemoteEvent(_ event: String) {
        switch event {
        case "up":
            // Navigate up
            break
        case "down":
            // Navigate down
            break
        case "left":
            // Navigate left
            break
        case "right":
            // Navigate right
            break
        case "select":
            // Select current item
            break
        case "menu":
            // Show menu
            break
        case "play":
            // Play/pause
            break
        default:
            break
        }
    }
}

// MARK: - tvOS Accessibility
struct tvOSAccessibilityModifiers {
    static func healthMetric(_ view: some View, value: String, unit: String, label: String) -> some View {
        view
            .accessibilityLabel(label)
            .accessibilityValue("\(value) \(unit)")
            .accessibilityAddTraits(.isStaticText)
    }
    
    static func largeButton(_ view: some View, title: String, action: String) -> some View {
        view
            .accessibilityLabel(title)
            .accessibilityHint(action)
            .accessibilityAddTraits(.isButton)
    }
}

// MARK: - tvOS Preview
struct tvOSLargeScreenAssets_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            tvOSHealthDashboard()
                .previewDevice("Apple TV")
            
            tvOSHealthMetricCard(
                title: "Heart Rate",
                value: "72",
                unit: "bpm",
                trend: .up,
                color: tvOSDesignSystem.colors.heartRate
            )
            .previewDevice("Apple TV")
            
            tvOSLargeButton(
                title: "Start Workout",
                icon: "figure.run",
                color: tvOSDesignSystem.colors.activity
            ) {}
            .previewDevice("Apple TV")
        }
    }
} 
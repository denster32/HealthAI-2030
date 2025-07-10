import SwiftUI

// MARK: - Cross-Platform Asset Scaling
/// Responsive design and adaptive layouts for all platforms
/// Handles platform-agnostic scaling, responsive design, and adaptive components

// MARK: - Platform Detection
enum Platform {
    case iOS
    case macOS
    case watchOS
    case tvOS
    
    static var current: Platform {
        #if os(iOS)
        return .iOS
        #elseif os(macOS)
        return .macOS
        #elseif os(watchOS)
        return .watchOS
        #elseif os(tvOS)
        return .tvOS
        #else
        return .iOS
        #endif
    }
}

// MARK: - Cross-Platform Design System
struct CrossPlatformDesignSystem {
    /// Platform-agnostic color palette
    static let colors = CrossPlatformColorPalette()
    
    /// Platform-agnostic typography with scaling
    static let typography = CrossPlatformTypography()
    
    /// Platform-agnostic layout with responsive design
    static let layout = CrossPlatformLayoutGuide()
    
    /// Platform-agnostic spacing with adaptive scaling
    static let spacing = CrossPlatformSpacing()
}

// MARK: - Cross-Platform Color Palette
struct CrossPlatformColorPalette {
    /// Primary colors that work across all platforms
    let primary = Color(red: 0.0, green: 0.478, blue: 1.0)
    let secondary = Color(red: 0.584, green: 0.584, blue: 0.584)
    let accent = Color(red: 1.0, green: 0.231, blue: 0.188)
    
    /// Health-specific colors
    let heartRate = Color(red: 1.0, green: 0.231, blue: 0.188)
    let bloodPressure = Color(red: 0.0, green: 0.478, blue: 1.0)
    let sleep = Color(red: 0.584, green: 0.0, blue: 0.827)
    let activity = Color(red: 0.0, green: 0.827, blue: 0.584)
    
    /// Adaptive background colors
    var background: Color {
        switch Platform.current {
        case .iOS, .macOS:
            return Color(UIColor.systemBackground)
        case .watchOS, .tvOS:
            return Color.black
        }
    }
    
    var secondaryBackground: Color {
        switch Platform.current {
        case .iOS:
            return Color(UIColor.secondarySystemBackground)
        case .macOS:
            return Color(NSColor.controlBackgroundColor)
        case .watchOS, .tvOS:
            return Color(red: 0.1, green: 0.1, blue: 0.1)
        }
    }
    
    /// Adaptive text colors
    var primaryText: Color {
        switch Platform.current {
        case .iOS, .macOS:
            return Color(UIColor.label)
        case .watchOS, .tvOS:
            return Color.white
        }
    }
    
    var secondaryText: Color {
        switch Platform.current {
        case .iOS, .macOS:
            return Color(UIColor.secondaryLabel)
        case .watchOS, .tvOS:
            return Color(red: 0.8, green: 0.8, blue: 0.8)
        }
    }
}

// MARK: - Cross-Platform Typography
struct CrossPlatformTypography {
    /// Platform-adaptive font sizes
    var largeTitle: Font {
        switch Platform.current {
        case .iOS:
            return Font.largeTitle.weight(.bold)
        case .macOS:
            return Font.largeTitle.weight(.bold)
        case .watchOS:
            return Font.system(size: 28, weight: .bold, design: .rounded)
        case .tvOS:
            return Font.system(size: 72, weight: .bold, design: .rounded)
        }
    }
    
    var title1: Font {
        switch Platform.current {
        case .iOS:
            return Font.title.weight(.semibold)
        case .macOS:
            return Font.title.weight(.semibold)
        case .watchOS:
            return Font.system(size: 24, weight: .semibold, design: .rounded)
        case .tvOS:
            return Font.system(size: 48, weight: .semibold, design: .rounded)
        }
    }
    
    var title2: Font {
        switch Platform.current {
        case .iOS:
            return Font.title2.weight(.semibold)
        case .macOS:
            return Font.title2.weight(.semibold)
        case .watchOS:
            return Font.system(size: 20, weight: .semibold, design: .rounded)
        case .tvOS:
            return Font.system(size: 36, weight: .semibold, design: .rounded)
        }
    }
    
    var body: Font {
        switch Platform.current {
        case .iOS, .macOS:
            return Font.body
        case .watchOS:
            return Font.system(size: 14, weight: .regular, design: .rounded)
        case .tvOS:
            return Font.system(size: 20, weight: .regular, design: .rounded)
        }
    }
    
    /// Health-specific typography with platform scaling
    var healthMetric: Font {
        switch Platform.current {
        case .iOS:
            return Font.system(size: 48, weight: .bold, design: .rounded)
        case .macOS:
            return Font.system(size: 64, weight: .bold, design: .rounded)
        case .watchOS:
            return Font.system(size: 32, weight: .bold, design: .rounded)
        case .tvOS:
            return Font.system(size: 96, weight: .bold, design: .rounded)
        }
    }
    
    var healthLabel: Font {
        switch Platform.current {
        case .iOS:
            return Font.system(size: 16, weight: .medium, design: .rounded)
        case .macOS:
            return Font.system(size: 18, weight: .medium, design: .rounded)
        case .watchOS:
            return Font.system(size: 12, weight: .medium, design: .rounded)
        case .tvOS:
            return Font.system(size: 24, weight: .medium, design: .rounded)
        }
    }
}

// MARK: - Cross-Platform Layout Guide
struct CrossPlatformLayoutGuide {
    /// Platform-adaptive spacing
    var spacing: CGFloat {
        switch Platform.current {
        case .iOS:
            return 16
        case .macOS:
            return 20
        case .watchOS:
            return 8
        case .tvOS:
            return 40
        }
    }
    
    var smallSpacing: CGFloat {
        switch Platform.current {
        case .iOS:
            return 8
        case .macOS:
            return 12
        case .watchOS:
            return 4
        case .tvOS:
            return 20
        }
    }
    
    var largeSpacing: CGFloat {
        switch Platform.current {
        case .iOS:
            return 24
        case .macOS:
            return 32
        case .watchOS:
            return 12
        case .tvOS:
            return 60
        }
    }
    
    /// Platform-adaptive corner radius
    var cornerRadius: CGFloat {
        switch Platform.current {
        case .iOS:
            return 12
        case .macOS:
            return 8
        case .watchOS:
            return 8
        case .tvOS:
            return 20
        }
    }
    
    /// Platform-adaptive padding
    var padding: CGFloat {
        switch Platform.current {
        case .iOS:
            return 16
        case .macOS:
            return 20
        case .watchOS:
            return 8
        case .tvOS:
            return 40
        }
    }
}

// MARK: - Cross-Platform Spacing
struct CrossPlatformSpacing {
    /// Responsive spacing based on screen size
    func adaptiveSpacing(base: CGFloat) -> CGFloat {
        let screenWidth = UIScreen.main.bounds.width
        let scaleFactor: CGFloat
        
        switch Platform.current {
        case .iOS:
            scaleFactor = screenWidth / 375 // iPhone base width
        case .macOS:
            scaleFactor = screenWidth / 1200 // Mac base width
        case .watchOS:
            scaleFactor = screenWidth / 180 // Watch base width
        case .tvOS:
            scaleFactor = screenWidth / 1920 // TV base width
        }
        
        return base * min(scaleFactor, 2.0) // Cap at 2x scaling
    }
    
    /// Responsive padding based on platform
    func adaptivePadding(base: CGFloat) -> CGFloat {
        return adaptiveSpacing(base: base)
    }
}

// MARK: - Cross-Platform Components

// MARK: - Responsive Health Card
struct ResponsiveHealthCard<Content: View>: View {
    let content: Content
    let style: HealthCardStyle
    
    init(style: HealthCardStyle = .default, @ViewBuilder content: () -> Content) {
        self.style = style
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: CrossPlatformDesignSystem.layout.spacing) {
            content
        }
        .padding(CrossPlatformDesignSystem.layout.padding)
        .background(style.backgroundColor)
        .cornerRadius(CrossPlatformDesignSystem.layout.cornerRadius)
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 2)
    }
}

enum HealthCardStyle {
    case `default`
    case primary
    case secondary
    case warning
    case success
    
    var backgroundColor: Color {
        switch self {
        case .default:
            return CrossPlatformDesignSystem.colors.background
        case .primary:
            return CrossPlatformDesignSystem.colors.primary.opacity(0.1)
        case .secondary:
            return CrossPlatformDesignSystem.colors.secondaryBackground
        case .warning:
            return Color.orange.opacity(0.1)
        case .success:
            return Color.green.opacity(0.1)
        }
    }
}

// MARK: - Adaptive Health Metric Display
struct AdaptiveHealthMetricDisplay: View {
    let value: String
    let unit: String
    let label: String
    let trend: HealthTrend?
    
    var body: some View {
        VStack(alignment: .leading, spacing: CrossPlatformDesignSystem.layout.smallSpacing) {
            HStack(alignment: .bottom, spacing: 4) {
                Text(value)
                    .font(CrossPlatformDesignSystem.typography.healthMetric)
                    .foregroundColor(CrossPlatformDesignSystem.colors.primaryText)
                
                Text(unit)
                    .font(CrossPlatformDesignSystem.typography.healthLabel)
                    .foregroundColor(CrossPlatformDesignSystem.colors.secondaryText)
                
                Spacer()
                
                if let trend = trend {
                    AdaptiveHealthTrendIndicator(trend: trend)
                }
            }
            
            Text(label)
                .font(CrossPlatformDesignSystem.typography.healthLabel)
                .foregroundColor(CrossPlatformDesignSystem.colors.secondaryText)
        }
    }
}

struct AdaptiveHealthTrendIndicator: View {
    let trend: HealthTrend
    
    var body: some View {
        Image(systemName: trend.icon)
            .foregroundColor(trend.color)
            .font(.title2)
    }
}

// MARK: - Responsive Grid
struct ResponsiveGrid<Content: View>: View {
    let items: [Any]
    let content: (Any) -> Content
    
    var columns: Int {
        switch Platform.current {
        case .iOS:
            return UIDevice.current.userInterfaceIdiom == .pad ? 3 : 2
        case .macOS:
            return 4
        case .watchOS:
            return 1
        case .tvOS:
            return 3
        }
    }
    
    var body: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: CrossPlatformDesignSystem.layout.spacing), count: columns),
            spacing: CrossPlatformDesignSystem.layout.spacing
        ) {
            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                content(item)
            }
        }
    }
}

// MARK: - Adaptive Button
struct AdaptiveButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: CrossPlatformDesignSystem.layout.smallSpacing) {
                Image(systemName: icon)
                    .font(CrossPlatformDesignSystem.typography.title3)
                    .foregroundColor(color)
                
                Text(title)
                    .font(CrossPlatformDesignSystem.typography.headline)
                    .foregroundColor(CrossPlatformDesignSystem.colors.primaryText)
            }
            .padding(CrossPlatformDesignSystem.layout.padding)
            .background(CrossPlatformDesignSystem.colors.secondaryBackground)
            .cornerRadius(CrossPlatformDesignSystem.layout.cornerRadius)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Responsive Chart Container
struct ResponsiveChartContainer<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var chartHeight: CGFloat {
        switch Platform.current {
        case .iOS:
            return 200
        case .macOS:
            return 300
        case .watchOS:
            return 100
        case .tvOS:
            return 400
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: CrossPlatformDesignSystem.layout.spacing) {
            Text(title)
                .font(CrossPlatformDesignSystem.typography.title3)
                .foregroundColor(CrossPlatformDesignSystem.colors.primaryText)
            
            content
                .frame(height: chartHeight)
        }
        .padding(CrossPlatformDesignSystem.layout.padding)
        .background(CrossPlatformDesignSystem.colors.secondaryBackground)
        .cornerRadius(CrossPlatformDesignSystem.layout.cornerRadius)
    }
}

// MARK: - Adaptive Navigation
struct AdaptiveNavigation: View {
    let title: String
    let leftButton: NavigationButton?
    let rightButton: NavigationButton?
    
    var body: some View {
        HStack {
            if let leftButton = leftButton {
                leftButton
            } else {
                Spacer()
            }
            
            Text(title)
                .font(CrossPlatformDesignSystem.typography.title2)
                .foregroundColor(CrossPlatformDesignSystem.colors.primaryText)
            
            if let rightButton = rightButton {
                rightButton
            } else {
                Spacer()
            }
        }
        .padding(.horizontal, CrossPlatformDesignSystem.layout.padding)
        .padding(.vertical, CrossPlatformDesignSystem.layout.smallPadding)
        .background(CrossPlatformDesignSystem.colors.background)
    }
}

struct NavigationButton: View {
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(CrossPlatformDesignSystem.typography.title2)
                .foregroundColor(CrossPlatformDesignSystem.colors.primary)
        }
    }
}

// MARK: - Responsive Dashboard
struct ResponsiveDashboard: View {
    @State private var selectedTab = 0
    
    var body: some View {
        VStack(spacing: CrossPlatformDesignSystem.layout.largeSpacing) {
            // Header
            AdaptiveNavigation(
                title: "HealthAI 2030",
                leftButton: NavigationButton(icon: "chevron.left") {},
                rightButton: NavigationButton(icon: "gear") {}
            )
            
            // Content
            TabView(selection: $selectedTab) {
                ResponsiveOverviewTab()
                    .tag(0)
                
                ResponsiveActivityTab()
                    .tag(1)
                
                ResponsiveHealthTab()
                    .tag(2)
            }
            .tabViewStyle(PageTabViewStyle())
            .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
        }
        .background(CrossPlatformDesignSystem.colors.background)
    }
}

struct ResponsiveOverviewTab: View {
    let metrics = [
        HealthMetric(id: "1", title: "Heart Rate", value: "72", unit: "bpm", trend: .up, color: .red),
        HealthMetric(id: "2", title: "Blood Pressure", value: "120/80", unit: "mmHg", trend: .stable, color: .blue),
        HealthMetric(id: "3", title: "Sleep", value: "7h 23m", unit: "", trend: .down, color: .purple)
    ]
    
    var body: some View {
        VStack(spacing: CrossPlatformDesignSystem.layout.largeSpacing) {
            ResponsiveGrid(items: metrics) { metric in
                if let healthMetric = metric as? HealthMetric {
                    ResponsiveHealthCard {
                        AdaptiveHealthMetricDisplay(
                            value: healthMetric.value,
                            unit: healthMetric.unit,
                            label: healthMetric.title,
                            trend: healthMetric.trend
                        )
                    }
                }
            }
            
            // Quick actions
            HStack(spacing: CrossPlatformDesignSystem.layout.spacing) {
                AdaptiveButton(
                    title: "Start",
                    icon: "play.fill",
                    color: CrossPlatformDesignSystem.colors.activity
                ) {}
                
                AdaptiveButton(
                    title: "Details",
                    icon: "chart.bar.fill",
                    color: CrossPlatformDesignSystem.colors.primary
                ) {}
            }
        }
        .padding(CrossPlatformDesignSystem.layout.padding)
    }
}

struct ResponsiveActivityTab: View {
    var body: some View {
        VStack(spacing: CrossPlatformDesignSystem.layout.largeSpacing) {
            ResponsiveChartContainer(title: "Weekly Activity") {
                // Placeholder for chart
                RoundedRectangle(cornerRadius: CrossPlatformDesignSystem.layout.cornerRadius)
                    .fill(CrossPlatformDesignSystem.colors.activity.opacity(0.2))
                    .overlay(
                        Text("Activity Chart")
                            .font(CrossPlatformDesignSystem.typography.body)
                            .foregroundColor(CrossPlatformDesignSystem.colors.secondaryText)
                    )
            }
            
            // Activity stats
            ResponsiveGrid(items: ["Steps", "Calories"]) { item in
                if let stat = item as? String {
                    ResponsiveHealthCard {
                        VStack(spacing: CrossPlatformDesignSystem.layout.spacing) {
                            Text(stat)
                                .font(CrossPlatformDesignSystem.typography.headline)
                                .foregroundColor(CrossPlatformDesignSystem.colors.primaryText)
                            
                            Text("8,432")
                                .font(CrossPlatformDesignSystem.typography.title2)
                                .foregroundColor(CrossPlatformDesignSystem.colors.activity)
                        }
                    }
                }
            }
        }
        .padding(CrossPlatformDesignSystem.layout.padding)
    }
}

struct ResponsiveHealthTab: View {
    let healthItems = [
        "Heart Rate History",
        "Blood Pressure Trends",
        "Sleep Analysis",
        "Stress Levels"
    ]
    
    var body: some View {
        ResponsiveGrid(items: healthItems) { item in
            if let title = item as? String {
                ResponsiveHealthCard {
                    VStack(alignment: .leading, spacing: CrossPlatformDesignSystem.layout.spacing) {
                        Text(title)
                            .font(CrossPlatformDesignSystem.typography.headline)
                            .foregroundColor(CrossPlatformDesignSystem.colors.primaryText)
                        
                        Text("View details")
                            .font(CrossPlatformDesignSystem.typography.body)
                            .foregroundColor(CrossPlatformDesignSystem.colors.secondaryText)
                    }
                }
            }
        }
        .padding(CrossPlatformDesignSystem.layout.padding)
    }
}

// MARK: - Cross-Platform Preview
struct CrossPlatformAssetScaling_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ResponsiveDashboard()
                .previewDevice("iPhone 15 Pro")
            
            ResponsiveDashboard()
                .previewDevice("iPad Pro (12.9-inch)")
            
            ResponsiveDashboard()
                .previewDevice("Apple Watch Series 7 (45mm)")
            
            ResponsiveDashboard()
                .previewDevice("Apple TV")
        }
    }
} 
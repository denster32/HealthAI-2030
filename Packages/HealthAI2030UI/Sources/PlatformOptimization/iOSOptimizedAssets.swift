import SwiftUI
#if canImport(UIKit)
import UIKit
#endif
#if canImport(PencilKit)
import PencilKit
#endif

// MARK: - iOS Platform Optimization
/// Optimized assets and components specifically designed for iOS platform
/// Handles iOS-specific design patterns, performance optimizations, and interface elements

// MARK: - iOS-Specific Design System
struct iOSDesignSystem {
    /// iOS-specific color palette optimized for OLED displays
    static let colors = iOSColorPalette()
    
    /// iOS-specific typography optimized for readability
    static let typography = iOSTypography()
    
    /// iOS-specific spacing and layout guidelines
    static let layout = iOSLayoutGuide()
    
    /// iOS-specific animation curves and timing
    static let animations = iOSAnimationCurves()
}

// MARK: - iOS Color Palette
struct iOSColorPalette {
    /// Primary colors optimized for iOS
    let primary = Color(red: 0.0, green: 0.478, blue: 1.0)
    let secondary = Color(red: 0.584, green: 0.584, blue: 0.584)
    let accent = Color(red: 1.0, green: 0.231, blue: 0.188)
    
    /// Health-specific colors
    let heartRate = Color(red: 1.0, green: 0.231, blue: 0.188)
    let bloodPressure = Color(red: 0.0, green: 0.478, blue: 1.0)
    let sleep = Color(red: 0.584, green: 0.0, blue: 0.827)
    let activity = Color(red: 0.0, green: 0.827, blue: 0.584)
    
    /// Background colors optimized for iOS
    let background = Color(UIColor.systemBackground)
    let secondaryBackground = Color(UIColor.secondarySystemBackground)
    let tertiaryBackground = Color(UIColor.tertiarySystemBackground)
    
    /// Text colors optimized for iOS
    let primaryText = Color(UIColor.label)
    let secondaryText = Color(UIColor.secondaryLabel)
    let tertiaryText = Color(UIColor.tertiaryLabel)
}

// MARK: - iOS Typography
struct iOSTypography {
    /// iOS-optimized font sizes and weights
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
    
    /// Health-specific typography
    let healthMetric = Font.system(size: 48, weight: .bold, design: .rounded)
    let healthLabel = Font.system(size: 16, weight: .medium, design: .rounded)
    let healthUnit = Font.system(size: 14, weight: .regular, design: .rounded)
}

// MARK: - iOS Layout Guide
struct iOSLayoutGuide {
    /// iOS-specific spacing
    let spacing: CGFloat = 16
    let smallSpacing: CGFloat = 8
    let largeSpacing: CGFloat = 24
    let extraLargeSpacing: CGFloat = 32
    
    /// iOS-specific corner radius
    let cornerRadius: CGFloat = 12
    let smallCornerRadius: CGFloat = 8
    let largeCornerRadius: CGFloat = 16
    
    /// iOS-specific padding
    let padding: CGFloat = 16
    let smallPadding: CGFloat = 8
    let largePadding: CGFloat = 24
}

// MARK: - iOS Animation Curves
struct iOSAnimationCurves {
    /// iOS-specific animation curves
    let easeInOut = Animation.easeInOut(duration: 0.3)
    let easeOut = Animation.easeOut(duration: 0.2)
    let easeIn = Animation.easeIn(duration: 0.2)
    let spring = Animation.spring(response: 0.5, dampingFraction: 0.8)
    
    /// Health-specific animations
    let heartbeat = Animation.easeInOut(duration: 0.6).repeatForever(autoreverses: true)
    let breathing = Animation.easeInOut(duration: 2.0).repeatForever(autoreverses: true)
    let pulse = Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true)
}

// MARK: - iOS-Optimized Components

// MARK: - iOS Health Card
struct iOSHealthCard<Content: View>: View {
    let content: Content
    let style: HealthCardStyle
    
    init(style: HealthCardStyle = .default, @ViewBuilder content: () -> Content) {
        self.style = style
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: iOSDesignSystem.layout.spacing) {
            content
        }
        .padding(iOSDesignSystem.layout.padding)
        .background(style.backgroundColor)
        .cornerRadius(iOSDesignSystem.layout.cornerRadius)
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
            return iOSDesignSystem.colors.background
        case .primary:
            return iOSDesignSystem.colors.primary.opacity(0.1)
        case .secondary:
            return iOSDesignSystem.colors.secondaryBackground
        case .warning:
            return Color.orange.opacity(0.1)
        case .success:
            return Color.green.opacity(0.1)
        }
    }
}

// MARK: - iOS Health Metric Display
struct iOSHealthMetricDisplay: View {
    let value: String
    let unit: String
    let label: String
    let trend: HealthTrend?
    
    var body: some View {
        VStack(alignment: .leading, spacing: iOSDesignSystem.layout.smallSpacing) {
            HStack(alignment: .bottom, spacing: 4) {
                Text(value)
                    .font(iOSDesignSystem.typography.healthMetric)
                    .foregroundColor(iOSDesignSystem.colors.primaryText)
                
                Text(unit)
                    .font(iOSDesignSystem.typography.healthUnit)
                    .foregroundColor(iOSDesignSystem.colors.secondaryText)
                
                Spacer()
                
                if let trend = trend {
                    iOSHealthTrendIndicator(trend: trend)
                }
            }
            
            Text(label)
                .font(iOSDesignSystem.typography.healthLabel)
                .foregroundColor(iOSDesignSystem.colors.secondaryText)
        }
    }
}

enum HealthTrend {
    case up
    case down
    case stable
    
    var icon: String {
        switch self {
        case .up:
            return "arrow.up.circle.fill"
        case .down:
            return "arrow.down.circle.fill"
        case .stable:
            return "minus.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .up:
            return Color.green
        case .down:
            return Color.red
        case .stable:
            return Color.blue
        }
    }
}

struct iOSHealthTrendIndicator: View {
    let trend: HealthTrend
    
    var body: some View {
        Image(systemName: trend.icon)
            .foregroundColor(trend.color)
            .font(.title2)
    }
}

// MARK: - iOS Navigation Bar
struct iOSNavigationBar: View {
    let title: String
    let leftButton: NavigationBarButton?
    let rightButton: NavigationBarButton?
    
    var body: some View {
        HStack {
            if let leftButton = leftButton {
                leftButton
            } else {
                Spacer()
            }
            
            Text(title)
                .font(iOSDesignSystem.typography.title2)
                .foregroundColor(iOSDesignSystem.colors.primaryText)
            
            if let rightButton = rightButton {
                rightButton
            } else {
                Spacer()
            }
        }
        .padding(.horizontal, iOSDesignSystem.layout.padding)
        .padding(.vertical, iOSDesignSystem.layout.smallPadding)
        .background(iOSDesignSystem.colors.background)
    }
}

struct NavigationBarButton: View {
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(iOSDesignSystem.colors.primary)
        }
    }
}

// MARK: - iOS Tab Bar
struct iOSHealthTabBar: View {
    @Binding var selectedTab: Int
    let tabs: [HealthTab]
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(tabs.enumerated()), id: \.offset) { index, tab in
                Button(action: {
                    selectedTab = index
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: selectedTab == index ? tab.selectedIcon : tab.icon)
                            .font(.title2)
                        
                        Text(tab.title)
                            .font(iOSDesignSystem.typography.caption1)
                    }
                    .foregroundColor(selectedTab == index ? iOSDesignSystem.colors.primary : iOSDesignSystem.colors.secondaryText)
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.horizontal, iOSDesignSystem.layout.padding)
        .padding(.vertical, iOSDesignSystem.layout.smallPadding)
        .background(iOSDesignSystem.colors.background)
        .overlay(
            Rectangle()
                .frame(height: 0.5)
                .foregroundColor(Color.gray.opacity(0.3)),
            alignment: .top
        )
    }
}

struct HealthTab {
    let title: String
    let icon: String
    let selectedIcon: String
}

// MARK: - iOS Performance Optimizations

// MARK: - Lazy Loading
struct iOSLazyHealthGrid<Content: View>: View {
    let items: [Any]
    let columns: Int
    let content: (Any) -> Content
    
    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: iOSDesignSystem.layout.spacing), count: columns), spacing: iOSDesignSystem.layout.spacing) {
            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                content(item)
                    .onAppear {
                        // Trigger lazy loading logic here
                    }
            }
        }
    }
}

// MARK: - Image Caching
class iOSImageCache {
    static let shared = iOSImageCache()
    private var cache = NSCache<NSString, UIImage>()
    
    private init() {
        cache.countLimit = 100
        cache.totalCostLimit = 1024 * 1024 * 100 // 100 MB
    }
    
    func getImage(for key: String) -> UIImage? {
        return cache.object(forKey: key as NSString)
    }
    
    func setImage(_ image: UIImage, for key: String) {
        cache.setObject(image, forKey: key as NSString)
    }
}

// MARK: - iOS Accessibility
struct iOSAccessibilityModifiers {
    static func healthMetric(_ view: some View, value: String, unit: String, label: String) -> some View {
        view
            .accessibilityLabel(label)
            .accessibilityValue("\(value) \(unit)")
            .accessibilityAddTraits(.isStaticText)
    }
    
    static func healthCard(_ view: some View, title: String, content: String) -> some View {
        view
            .accessibilityLabel(title)
            .accessibilityHint(content)
            .accessibilityAddTraits(.isButton)
    }
}

// MARK: - iOS Haptic Feedback
class iOSHapticManager {
    static let shared = iOSHapticManager()
    
    private init() {}
    
    func impact(style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
    
    func notification(type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(type)
    }
    
    func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
}

// MARK: - iOS Dark Mode Support
struct iOSDarkModeSupport {
    static func adaptiveColor(light: Color, dark: Color) -> Color {
        return Color(UIColor { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return UIColor(dark)
            default:
                return UIColor(light)
            }
        })
    }
}

// MARK: - iOS Preview
struct iOSOptimizedAssets_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            iOSHealthCard {
                iOSHealthMetricDisplay(
                    value: "72",
                    unit: "bpm",
                    label: "Heart Rate",
                    trend: .up
                )
            }
            
            iOSNavigationBar(
                title: "Health Dashboard",
                leftButton: NavigationBarButton(icon: "chevron.left") {},
                rightButton: NavigationBarButton(icon: "plus") {}
            )
            
            iOSHealthTabBar(
                selectedTab: .constant(0),
                tabs: [
                    HealthTab(title: "Dashboard", icon: "house", selectedIcon: "house.fill"),
                    HealthTab(title: "Activity", icon: "figure.walk", selectedIcon: "figure.walk"),
                    HealthTab(title: "Health", icon: "heart", selectedIcon: "heart.fill")
                ]
            )
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
} 

// MARK: - iPad Platform Optimization
/// Optimized interface elements specifically designed for iPad platform
/// Handles iPad-specific design patterns, multitasking, and PencilKit integration

// MARK: - iPad-Specific Design System
struct iPadDesignSystem {
    /// iPad-specific color palette optimized for larger displays
    static let colors = iPadColorPalette()
    
    /// iPad-specific typography optimized for tablet readability
    static let typography = iPadTypography()
    
    /// iPad-specific spacing and layout guidelines
    static let layout = iPadLayoutGuide()
    
    /// iPad-specific navigation patterns
    static let navigation = iPadNavigationGuide()
}

// MARK: - iPad Color Palette
struct iPadColorPalette {
    /// Primary colors optimized for iPad
    let primary = Color(red: 0.0, green: 0.478, blue: 1.0)
    let secondary = Color(red: 0.584, green: 0.584, blue: 0.584)
    let accent = Color(red: 1.0, green: 0.231, blue: 0.188)
    
    /// Health-specific colors for iPad
    let heartRate = Color(red: 1.0, green: 0.231, blue: 0.188)
    let bloodPressure = Color(red: 0.0, green: 0.478, blue: 1.0)
    let sleep = Color(red: 0.584, green: 0.0, blue: 0.827)
    let activity = Color(red: 0.0, green: 0.827, blue: 0.584)
    
    /// Background colors optimized for iPad
    let background = Color(uiColor: .systemBackground)
    let secondaryBackground = Color(uiColor: .secondarySystemBackground)
    let tertiaryBackground = Color(uiColor: .tertiarySystemBackground)
    
    /// Text colors optimized for iPad
    let primaryText = Color(uiColor: .label)
    let secondaryText = Color(uiColor: .secondaryLabel)
    let tertiaryText = Color(uiColor: .tertiaryLabel)
}

// MARK: - iPad Typography
struct iPadTypography {
    /// iPad-optimized font sizes and weights
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
    
    /// Health-specific typography for iPad
    let healthMetric = Font.system(size: 72, weight: .bold, design: .rounded)
    let healthLabel = Font.system(size: 20, weight: .medium, design: .rounded)
    let healthUnit = Font.system(size: 18, weight: .regular, design: .rounded)
}

// MARK: - iPad Layout Guide
struct iPadLayoutGuide {
    /// iPad-specific spacing
    let spacing: CGFloat = 24
    let smallSpacing: CGFloat = 16
    let largeSpacing: CGFloat = 40
    let extraLargeSpacing: CGFloat = 64
    
    /// iPad-specific corner radius
    let cornerRadius: CGFloat = 16
    let smallCornerRadius: CGFloat = 12
    let largeCornerRadius: CGFloat = 20
    
    /// iPad-specific padding
    let padding: CGFloat = 24
    let smallPadding: CGFloat = 16
    let largePadding: CGFloat = 40
    
    /// iPad-specific grid layout
    let gridColumns = Array(repeating: GridItem(.flexible(), spacing: 24), count: 2)
    let gridColumnsThree = Array(repeating: GridItem(.flexible(), spacing: 24), count: 3)
}

// MARK: - iPad Navigation Guide
struct iPadNavigationGuide {
    /// Navigation split view configuration
    let sidebarWidth: CGFloat = 280
    let detailMinWidth: CGFloat = 400
    let contentMinWidth: CGFloat = 300
}

// MARK: - iPad-Optimized Dashboard
@available(iOS 17.0, *)
public struct IPadOptimizedDashboardView: View {
    @State private var selectedSection: DashboardSection = .overview
    @State private var selectedDetail: DashboardDetail?
    @State private var isSidebarCollapsed = false
    
    public var body: some View {
        NavigationSplitView {
            // Sidebar
            IPadSidebarView(selectedSection: $selectedSection, isCollapsed: $isSidebarCollapsed)
        } content: {
            // Content List
            IPadContentView(selectedSection: selectedSection, selectedDetail: $selectedDetail)
        } detail: {
            // Detail View
            if let detail = selectedDetail {
                IPadDetailView(detail: detail)
            } else {
                IPadPlaceholderView()
            }
        }
        .navigationSplitViewStyle(.balanced)
        .navigationSplitViewColumnVisibility(.all)
    }
}

// MARK: - iPad Sidebar
struct IPadSidebarView: View {
    @Binding var selectedSection: DashboardSection
    @Binding var isCollapsed: Bool
    
    var body: some View {
        List(DashboardSection.allCases, id: \.self, selection: $selectedSection) { section in
            NavigationLink(value: section) {
                HStack(spacing: iPadDesignSystem.layout.smallSpacing) {
                    Image(systemName: section.icon)
                        .foregroundColor(iPadDesignSystem.colors.primary)
                        .font(.title2)
                        .frame(width: 28)
                    
                    if !isCollapsed {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(section.title)
                                .font(iPadDesignSystem.typography.body)
                                .foregroundColor(iPadDesignSystem.colors.primaryText)
                            
                            Text(section.subtitle)
                                .font(iPadDesignSystem.typography.caption1)
                                .foregroundColor(iPadDesignSystem.colors.secondaryText)
                        }
                    }
                }
                .padding(.vertical, 8)
            }
        }
        .navigationTitle("HealthAI")
        .listStyle(SidebarListStyle())
        .frame(minWidth: isCollapsed ? 60 : iPadDesignSystem.navigation.sidebarWidth)
    }
}

// MARK: - iPad Content View
struct IPadContentView: View {
    let selectedSection: DashboardSection
    @Binding var selectedDetail: DashboardDetail?
    
    var body: some View {
        VStack(spacing: 0) {
            // Section Header
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text(selectedSection.title)
                        .font(iPadDesignSystem.typography.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(iPadDesignSystem.colors.primaryText)
                    
                    Text(selectedSection.subtitle)
                        .font(iPadDesignSystem.typography.body)
                        .foregroundColor(iPadDesignSystem.colors.secondaryText)
                }
                
                Spacer()
                
                // Section Actions
                HStack(spacing: iPadDesignSystem.layout.smallSpacing) {
                    AnimatedButton(title: "Add", style: .primary, icon: "plus") {
                        // Add action
                    }
                    
                    AnimatedButton(title: "Filter", style: .secondary, icon: "line.3.horizontal.decrease.circle") {
                        // Filter action
                    }
                }
            }
            .padding(iPadDesignSystem.layout.largePadding)
            .background(iPadDesignSystem.colors.background)
            
            // Content Grid
            ScrollView {
                LazyVGrid(columns: iPadDesignSystem.layout.gridColumns, spacing: iPadDesignSystem.layout.largeSpacing) {
                    ForEach(selectedSection.details, id: \.id) { detail in
                        IPadDetailCard(detail: detail)
                            .onTapGesture {
                                selectedDetail = detail
                            }
                    }
                }
                .padding(iPadDesignSystem.layout.largePadding)
            }
        }
        .background(iPadDesignSystem.colors.secondaryBackground)
    }
}

// MARK: - iPad Detail Card
struct IPadDetailCard: View {
    let detail: DashboardDetail
    @State private var isHovered = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: iPadDesignSystem.layout.spacing) {
            // Header
            HStack {
                Image(systemName: detail.icon)
                    .foregroundColor(detail.color)
                    .font(.title)
                    .frame(width: 32)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(detail.title)
                        .font(iPadDesignSystem.typography.headline)
                        .foregroundColor(iPadDesignSystem.colors.primaryText)
                    
                    Text(detail.subtitle)
                        .font(iPadDesignSystem.typography.caption1)
                        .foregroundColor(iPadDesignSystem.colors.secondaryText)
                }
                
                Spacer()
                
                // Status indicator
                Circle()
                    .fill(detail.statusColor)
                    .frame(width: 12, height: 12)
            }
            
            // Content
            VStack(alignment: .leading, spacing: iPadDesignSystem.layout.smallSpacing) {
                Text(detail.value)
                    .font(iPadDesignSystem.typography.healthMetric)
                    .fontWeight(.bold)
                    .foregroundColor(iPadDesignSystem.colors.primaryText)
                
                Text(detail.unit)
                    .font(iPadDesignSystem.typography.healthUnit)
                    .foregroundColor(iPadDesignSystem.colors.secondaryText)
                
                if let trend = detail.trend {
                    HStack {
                        Image(systemName: detail.trendIcon)
                            .foregroundColor(detail.trendColor)
                            .font(.caption)
                        
                        Text(trend)
                            .font(iPadDesignSystem.typography.caption1)
                            .foregroundColor(detail.trendColor)
                    }
                }
            }
        }
        .padding(iPadDesignSystem.layout.largePadding)
        .background(iPadDesignSystem.colors.background)
        .cornerRadius(iPadDesignSystem.layout.cornerRadius)
        .shadow(radius: isHovered ? 12 : 8, x: 0, y: isHovered ? 6 : 4)
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .animation(HealthAIAnimations.Presets.smooth, value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
        .healthCardAccessibility(detail.title, value: detail.value, unit: detail.unit, trend: detail.trend)
    }
}

// MARK: - iPad Detail View
struct IPadDetailView: View {
    let detail: DashboardDetail
    @State private var showingPencilKit = false
    
    var body: some View {
        VStack(spacing: iPadDesignSystem.layout.largeSpacing) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text(detail.title)
                        .font(iPadDesignSystem.typography.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(iPadDesignSystem.colors.primaryText)
                    
                    Text(detail.subtitle)
                        .font(iPadDesignSystem.typography.body)
                        .foregroundColor(iPadDesignSystem.colors.secondaryText)
                }
                
                Spacer()
                
                // Actions
                HStack(spacing: iPadDesignSystem.layout.smallSpacing) {
                    AnimatedButton(title: "Notes", style: .secondary, icon: "pencil") {
                        showingPencilKit = true
                    }
                    
                    AnimatedButton(title: "Share", style: .secondary, icon: "square.and.arrow.up") {
                        // Share action
                    }
                }
            }
            .padding(iPadDesignSystem.layout.largePadding)
            
            // Detail Content
            ScrollView {
                VStack(spacing: iPadDesignSystem.layout.largeSpacing) {
                    // Main metric display
                    IPadMetricDisplay(detail: detail)
                    
                    // Charts and graphs
                    IPadChartSection(detail: detail)
                    
                    // Related metrics
                    IPadRelatedMetrics(detail: detail)
                }
                .padding(iPadDesignSystem.layout.largePadding)
            }
        }
        .background(iPadDesignSystem.colors.background)
        .sheet(isPresented: $showingPencilKit) {
            IPadPencilKitView(detail: detail)
        }
    }
}

// MARK: - iPad Metric Display
struct IPadMetricDisplay: View {
    let detail: DashboardDetail
    
    var body: some View {
        VStack(spacing: iPadDesignSystem.layout.spacing) {
            // Large metric value
            HStack(alignment: .bottom, spacing: iPadDesignSystem.layout.smallSpacing) {
                Text(detail.value)
                    .font(iPadDesignSystem.typography.healthMetric)
                    .fontWeight(.bold)
                    .foregroundColor(iPadDesignSystem.colors.primaryText)
                
                Text(detail.unit)
                    .font(iPadDesignSystem.typography.healthUnit)
                    .foregroundColor(iPadDesignSystem.colors.secondaryText)
            }
            
            // Status and trend
            HStack {
                Label(detail.status, systemImage: "circle.fill")
                    .font(iPadDesignSystem.typography.body)
                    .foregroundColor(detail.statusColor)
                
                Spacer()
                
                if let trend = detail.trend {
                    Label(trend, systemImage: detail.trendIcon)
                        .font(iPadDesignSystem.typography.body)
                        .foregroundColor(detail.trendColor)
                }
            }
        }
        .padding(iPadDesignSystem.layout.largePadding)
        .background(iPadDesignSystem.colors.secondaryBackground)
        .cornerRadius(iPadDesignSystem.layout.cornerRadius)
    }
}

// MARK: - iPad Chart Section
struct IPadChartSection: View {
    let detail: DashboardDetail
    
    var body: some View {
        VStack(alignment: .leading, spacing: iPadDesignSystem.layout.spacing) {
            Text("Trends")
                .font(iPadDesignSystem.typography.title2)
                .fontWeight(.semibold)
                .foregroundColor(iPadDesignSystem.colors.primaryText)
            
            // Placeholder for chart
            RoundedRectangle(cornerRadius: iPadDesignSystem.layout.cornerRadius)
                .fill(iPadDesignSystem.colors.secondaryBackground)
                .frame(height: 200)
                .overlay(
                    VStack {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.largeTitle)
                            .foregroundColor(iPadDesignSystem.colors.secondaryText)
                        
                        Text("Chart coming soon")
                            .font(iPadDesignSystem.typography.body)
                            .foregroundColor(iPadDesignSystem.colors.secondaryText)
                    }
                )
        }
    }
}

// MARK: - iPad Related Metrics
struct IPadRelatedMetrics: View {
    let detail: DashboardDetail
    
    var body: some View {
        VStack(alignment: .leading, spacing: iPadDesignSystem.layout.spacing) {
            Text("Related Metrics")
                .font(iPadDesignSystem.typography.title2)
                .fontWeight(.semibold)
                .foregroundColor(iPadDesignSystem.colors.primaryText)
            
            LazyVGrid(columns: iPadDesignSystem.layout.gridColumnsThree, spacing: iPadDesignSystem.layout.spacing) {
                ForEach(0..<6, id: \.self) { index in
                    IPadRelatedMetricCard(index: index)
                }
            }
        }
    }
}

struct IPadRelatedMetricCard: View {
    let index: Int
    
    var body: some View {
        VStack(spacing: iPadDesignSystem.layout.smallSpacing) {
            Image(systemName: "heart.fill")
                .font(.title2)
                .foregroundColor(iPadDesignSystem.colors.primary)
            
            Text("Metric \(index + 1)")
                .font(iPadDesignSystem.typography.caption1)
                .foregroundColor(iPadDesignSystem.colors.secondaryText)
        }
        .frame(height: 80)
        .frame(maxWidth: .infinity)
        .background(iPadDesignSystem.colors.secondaryBackground)
        .cornerRadius(iPadDesignSystem.layout.smallCornerRadius)
    }
}

// MARK: - iPad PencilKit Integration
struct IPadPencilKitView: View {
    let detail: DashboardDetail
    @Environment(\.dismiss) private var dismiss
    @State private var canvasView = PKCanvasView()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Toolbar
                HStack {
                    Button("Done") {
                        dismiss()
                    }
                    
                    Spacer()
                    
                    Text("Notes for \(detail.title)")
                        .font(iPadDesignSystem.typography.headline)
                    
                    Spacer()
                    
                    Button("Save") {
                        // Save notes
                    }
                }
                .padding(iPadDesignSystem.layout.spacing)
                .background(iPadDesignSystem.colors.secondaryBackground)
                
                // Canvas
                PencilKitCanvasView(canvasView: $canvasView)
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct PencilKitCanvasView: UIViewRepresentable {
    @Binding var canvasView: PKCanvasView
    
    func makeUIView(context: Context) -> PKCanvasView {
        canvasView.tool = PKInkingTool(.pen, color: .systemBlue, width: 1)
        canvasView.drawingPolicy = .anyInput
        return canvasView
    }
    
    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        // Update if needed
    }
}

// MARK: - iPad Placeholder View
struct IPadPlaceholderView: View {
    var body: some View {
        VStack(spacing: iPadDesignSystem.layout.largeSpacing) {
            Image(systemName: "heart.text.square")
                .font(.system(size: 80))
                .foregroundColor(iPadDesignSystem.colors.secondaryText)
            
            Text("Select a metric to view details")
                .font(iPadDesignSystem.typography.title2)
                .foregroundColor(iPadDesignSystem.colors.primaryText)
            
            Text("Choose from the list to see comprehensive health information")
                .font(iPadDesignSystem.typography.body)
                .foregroundColor(iPadDesignSystem.colors.secondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(iPadDesignSystem.colors.background)
    }
}

// MARK: - Supporting Types
public enum DashboardSection: CaseIterable {
    case overview, healthMetrics, activity, sleep, nutrition, mentalHealth, settings
    
    var title: String {
        switch self {
        case .overview: return "Overview"
        case .healthMetrics: return "Health Metrics"
        case .activity: return "Activity"
        case .sleep: return "Sleep"
        case .nutrition: return "Nutrition"
        case .mentalHealth: return "Mental Health"
        case .settings: return "Settings"
        }
    }
    
    var subtitle: String {
        switch self {
        case .overview: return "Your health summary"
        case .healthMetrics: return "Vital signs and measurements"
        case .activity: return "Exercise and movement"
        case .sleep: return "Sleep patterns and quality"
        case .nutrition: return "Diet and hydration"
        case .mentalHealth: return "Mood and wellness"
        case .settings: return "App preferences"
        }
    }
    
    var icon: String {
        switch self {
        case .overview: return "heart.text.square"
        case .healthMetrics: return "heart.fill"
        case .activity: return "figure.walk"
        case .sleep: return "bed.double.fill"
        case .nutrition: return "leaf.fill"
        case .mentalHealth: return "brain.head.profile"
        case .settings: return "gear"
        }
    }
    
    var details: [DashboardDetail] {
        switch self {
        case .overview:
            return [
                DashboardDetail(id: "heartRate", title: "Heart Rate", subtitle: "Current BPM", value: "72", unit: "BPM", icon: "heart.fill", color: .red, status: "Normal", statusColor: .green, trend: "+2 BPM", trendIcon: "arrow.up.right", trendColor: .green),
                DashboardDetail(id: "sleep", title: "Sleep", subtitle: "Last night", value: "7.5", unit: "hrs", icon: "bed.double.fill", color: .purple, status: "Good", statusColor: .green, trend: "-0.5 hrs", trendIcon: "arrow.down.right", trendColor: .orange)
            ]
        case .healthMetrics:
            return [
                DashboardDetail(id: "bloodPressure", title: "Blood Pressure", subtitle: "Systolic/Diastolic", value: "120/80", unit: "mmHg", icon: "heart.circle.fill", color: .blue, status: "Normal", statusColor: .green, trend: nil, trendIcon: "", trendColor: .clear),
                DashboardDetail(id: "temperature", title: "Temperature", subtitle: "Body temperature", value: "98.6", unit: "°F", icon: "thermometer", color: .orange, status: "Normal", statusColor: .green, trend: nil, trendIcon: "", trendColor: .clear)
            ]
        default:
            return []
        }
    }
}

public struct DashboardDetail: Identifiable {
    public let id: String
    public let title: String
    public let subtitle: String
    public let value: String
    public let unit: String
    public let icon: String
    public let color: Color
    public let status: String
    public let statusColor: Color
    public let trend: String?
    public let trendIcon: String
    public let trendColor: Color
} 
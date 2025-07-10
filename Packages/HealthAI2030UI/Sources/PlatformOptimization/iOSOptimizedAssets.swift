import SwiftUI
import UIKit

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
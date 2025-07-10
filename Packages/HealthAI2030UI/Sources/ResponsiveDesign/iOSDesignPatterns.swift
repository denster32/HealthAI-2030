import SwiftUI

// MARK: - iOS Design Patterns Manager
/// Comprehensive iOS-specific design patterns for HealthAI 2030
/// Provides iPhone and iPad optimizations, healthcare-specific layouts, and iOS platform best practices
public class iOSDesignPatternsManager: ObservableObject {
    
    @Published public var deviceType: iOSDeviceType = .iPhone
    @Published public var orientation: UIDeviceOrientation = .portrait
    @Published public var safeAreaInsets: EdgeInsets = EdgeInsets()
    @Published public var isCompactWidth: Bool = false
    
    public static let shared = iOSDesignPatternsManager()
    
    private init() {
        setupDeviceObserver()
        updateDeviceInfo()
    }
    
    /// Setup observer for device changes
    private func setupDeviceObserver() {
        NotificationCenter.default.addObserver(
            forName: UIDevice.orientationDidChangeNotification,
            object: nil,
            queue: .main
        ) { _ in
            self.handleOrientationChange()
        }
    }
    
    /// Handle orientation changes
    private func handleOrientationChange() {
        orientation = UIDevice.current.orientation
        updateDeviceInfo()
    }
    
    /// Update device information
    private func updateDeviceInfo() {
        let screenSize = UIScreen.main.bounds.size
        deviceType = determineDeviceType(screenSize: screenSize)
        isCompactWidth = screenSize.width < 414 // iPhone Plus width
    }
    
    /// Determine device type based on screen size
    private func determineDeviceType(screenSize: CGSize) -> iOSDeviceType {
        let width = screenSize.width
        let height = screenSize.height
        
        switch (width, height) {
        case (320, 568): // iPhone SE 1st gen
            return .iPhoneSE
        case (375, 667): // iPhone 6, 7, 8, SE 2nd gen
            return .iPhone
        case (414, 736): // iPhone 6 Plus, 7 Plus, 8 Plus
            return .iPhonePlus
        case (375, 812): // iPhone X, XS, 11 Pro, 12 mini, 13 mini
            return .iPhoneX
        case (414, 896): // iPhone XR, XS Max, 11, 11 Pro Max, 12, 12 Pro, 13, 13 Pro
            return .iPhoneMax
        case (390, 844): // iPhone 12, 13, 14, 15
            return .iPhone
        case (393, 852): // iPhone 14 Pro, 15 Pro
            return .iPhone
        case (430, 932): // iPhone 14 Pro Max, 15 Pro Max
            return .iPhoneMax
        case (428, 926): // iPhone 14 Plus, 15 Plus
            return .iPhonePlus
        default:
            if width >= 768 { // iPad
                return .iPad
            } else {
                return .iPhone
            }
        }
    }
}

// MARK: - iOS Device Types
public enum iOSDeviceType {
    case iPhoneSE
    case iPhone
    case iPhonePlus
    case iPhoneX
    case iPhoneMax
    case iPad
    
    var description: String {
        switch self {
        case .iPhoneSE:
            return "iPhone SE"
        case .iPhone:
            return "iPhone"
        case .iPhonePlus:
            return "iPhone Plus"
        case .iPhoneX:
            return "iPhone X"
        case .iPhoneMax:
            return "iPhone Max"
        case .iPad:
            return "iPad"
        }
    }
    
    var isCompact: Bool {
        switch self {
        case .iPhoneSE, .iPhone:
            return true
        default:
            return false
        }
    }
    
    var isLarge: Bool {
        switch self {
        case .iPhoneMax, .iPad:
            return true
        default:
            return false
        }
    }
}

// MARK: - iOS Layout Patterns
public struct iOSLayoutPatterns {
    
    // MARK: - Navigation Patterns
    
    /// Standard iOS navigation bar pattern
    public static func standardNavigationBar(
        title: String,
        leadingButton: (() -> AnyView)? = nil,
        trailingButton: (() -> AnyView)? = nil
    ) -> some View {
        HStack {
            if let leadingButton = leadingButton {
                leadingButton()
            } else {
                Spacer()
            }
            
            Text(title)
                .font(TypographySystem.headline)
                .fontWeight(.semibold)
                .foregroundColor(ColorPalette.textPrimary)
            
            if let trailingButton = trailingButton {
                trailingButton()
            } else {
                Spacer()
            }
        }
        .padding(.horizontal, SpacingGrid.medium)
        .frame(height: 44)
        .background(ColorPalette.background)
    }
    
    /// Large title navigation pattern
    public static func largeTitleNavigation(
        title: String,
        subtitle: String? = nil
    ) -> some View {
        VStack(alignment: .leading, spacing: SpacingGrid.small) {
            Text(title)
                .font(TypographySystem.largeDisplay)
                .fontWeight(.bold)
                .foregroundColor(ColorPalette.textPrimary)
            
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(TypographySystem.body)
                    .foregroundColor(ColorPalette.textSecondary)
            }
        }
        .padding(.horizontal, SpacingGrid.medium)
        .padding(.top, SpacingGrid.large)
    }
    
    // MARK: - Tab Bar Patterns
    
    /// Standard iOS tab bar pattern
    public static func standardTabBar(
        items: [NavigationTabItem],
        selectedTab: Binding<Int>
    ) -> some View {
        HStack(spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                iOSTabBarItem(
                    item: item,
                    isSelected: selectedTab.wrappedValue == index,
                    action: { selectedTab.wrappedValue = index }
                )
            }
        }
        .background(ColorPalette.background)
        .overlay(
            Rectangle()
                .frame(height: 0.5)
                .foregroundColor(ColorPalette.border),
            alignment: .top
        )
    }
    
    /// Compact tab bar for smaller devices
    public static func compactTabBar(
        items: [NavigationTabItem],
        selectedTab: Binding<Int>
    ) -> some View {
        HStack(spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                iOSCompactTabBarItem(
                    item: item,
                    isSelected: selectedTab.wrappedValue == index,
                    action: { selectedTab.wrappedValue = index }
                )
            }
        }
        .background(ColorPalette.background)
        .overlay(
            Rectangle()
                .frame(height: 0.5)
                .foregroundColor(ColorPalette.border),
            alignment: .top
        )
    }
    
    // MARK: - List Patterns
    
    /// Standard iOS list pattern
    public static func standardList<Content: View>(
        @ViewBuilder content: () -> Content
    ) -> some View {
        List {
            content()
        }
        .listStyle(PlainListStyle())
        .background(ColorPalette.background)
    }
    
    /// Healthcare data list pattern
    public static func healthcareDataList<Content: View>(
        @ViewBuilder content: () -> Content
    ) -> some View {
        ScrollView {
            LazyVStack(spacing: SpacingGrid.small) {
                content()
            }
            .padding(.horizontal, SpacingGrid.medium)
        }
        .background(ColorPalette.background)
    }
    
    // MARK: - Card Patterns
    
    /// Standard iOS card pattern
    public static func standardCard<Content: View>(
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack {
            content()
        }
        .padding(SpacingGrid.medium)
        .background(ColorPalette.cardBackground)
        .cornerRadius(SpacingGrid.medium)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    /// Healthcare metric card pattern
    public static func healthcareMetricCard(
        title: String,
        value: String,
        unit: String? = nil,
        trend: String? = nil,
        color: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: SpacingGrid.medium) {
            HStack {
                Text(title)
                    .font(TypographySystem.healthMetricLabel)
                    .foregroundColor(ColorPalette.textSecondary)
                
                Spacer()
                
                if let trend = trend {
                    Text(trend)
                        .font(TypographySystem.caption)
                        .foregroundColor(color)
                        .padding(.horizontal, SpacingGrid.small)
                        .padding(.vertical, 2)
                        .background(color.opacity(0.1))
                        .cornerRadius(SpacingGrid.small)
                }
            }
            
            HStack(alignment: .bottom, spacing: SpacingGrid.small) {
                Text(value)
                    .font(TypographySystem.healthMetricMedium)
                    .fontWeight(.bold)
                    .foregroundColor(ColorPalette.textPrimary)
                
                if let unit = unit {
                    Text(unit)
                        .font(TypographySystem.healthMetricUnit)
                        .foregroundColor(ColorPalette.textSecondary)
                }
            }
        }
        .padding(SpacingGrid.medium)
        .background(color.opacity(0.05))
        .cornerRadius(SpacingGrid.medium)
        .overlay(
            RoundedRectangle(cornerRadius: SpacingGrid.medium)
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
    }
    
    // MARK: - Form Patterns
    
    /// Standard iOS form pattern
    public static func standardForm<Content: View>(
        @ViewBuilder content: () -> Content
    ) -> some View {
        ScrollView {
            VStack(spacing: SpacingGrid.large) {
                content()
            }
            .padding(SpacingGrid.medium)
        }
        .background(ColorPalette.background)
    }
    
    /// Healthcare form pattern
    public static func healthcareForm<Content: View>(
        @ViewBuilder content: () -> Content
    ) -> some View {
        ScrollView {
            VStack(spacing: SpacingGrid.large) {
                content()
            }
            .padding(SpacingGrid.medium)
        }
        .background(ColorPalette.background)
        .navigationBarTitleDisplayMode(.large)
    }
    
    // MARK: - Modal Patterns
    
    /// Standard iOS modal pattern
    public static func standardModal<Content: View>(
        title: String,
        isPresented: Binding<Bool>,
        @ViewBuilder content: () -> Content
    ) -> some View {
        NavigationView {
            VStack {
                content()
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                trailing: Button("Done") {
                    isPresented.wrappedValue = false
                }
            )
        }
        .presentationDetents([.medium, .large])
    }
    
    /// Healthcare modal pattern
    public static func healthcareModal<Content: View>(
        title: String,
        subtitle: String? = nil,
        isPresented: Binding<Bool>,
        @ViewBuilder content: () -> Content
    ) -> some View {
        NavigationView {
            VStack(spacing: SpacingGrid.large) {
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(TypographySystem.body)
                        .foregroundColor(ColorPalette.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, SpacingGrid.medium)
                }
                
                content()
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                trailing: Button("Close") {
                    isPresented.wrappedValue = false
                }
            )
        }
        .presentationDetents([.medium, .large])
    }
}

// MARK: - iOS Tab Bar Item
private struct iOSTabBarItem: View {
    let item: NavigationTabItem
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: SpacingGrid.small) {
                Image(systemName: item.icon)
                    .font(.system(size: 20, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(iconColor)
                
                Text(item.title)
                    .font(TypographySystem.caption)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundColor(textColor)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, SpacingGrid.small)
        }
        .disabled(!item.isEnabled)
        .opacity(item.isEnabled ? 1.0 : 0.5)
    }
    
    private var iconColor: Color {
        return isSelected ? ColorPalette.primary : ColorPalette.textSecondary
    }
    
    private var textColor: Color {
        return isSelected ? ColorPalette.primary : ColorPalette.textSecondary
    }
}

// MARK: - iOS Compact Tab Bar Item
private struct iOSCompactTabBarItem: View {
    let item: NavigationTabItem
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Image(systemName: item.icon)
                    .font(.system(size: 18, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(iconColor)
                
                Text(item.title)
                    .font(TypographySystem.caption2)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundColor(textColor)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
        }
        .disabled(!item.isEnabled)
        .opacity(item.isEnabled ? 1.0 : 0.5)
    }
    
    private var iconColor: Color {
        return isSelected ? ColorPalette.primary : ColorPalette.textSecondary
    }
    
    private var textColor: Color {
        return isSelected ? ColorPalette.primary : ColorPalette.textSecondary
    }
}

// MARK: - iOS Responsive Layout Modifiers
public extension View {
    
    /// Apply iOS-specific responsive layout
    func iOSResponsiveLayout() -> some View {
        self.modifier(iOSResponsiveLayoutModifier())
    }
    
    /// Apply iOS compact layout for smaller devices
    func iOSCompactLayout() -> some View {
        self.modifier(iOSCompactLayoutModifier())
    }
    
    /// Apply iOS large layout for iPad
    func iOSLargeLayout() -> some View {
        self.modifier(iOSLargeLayoutModifier())
    }
    
    /// Apply iOS safe area handling
    func iOSSafeArea() -> some View {
        self.modifier(iOSSafeAreaModifier())
    }
}

// MARK: - iOS Responsive Layout Modifier
public struct iOSResponsiveLayoutModifier: ViewModifier {
    
    @ObservedObject private var patternsManager = iOSDesignPatternsManager.shared
    
    public func body(content: Content) -> some View {
        content
            .padding(.horizontal, getHorizontalPadding())
            .padding(.vertical, getVerticalPadding())
    }
    
    private func getHorizontalPadding() -> CGFloat {
        switch patternsManager.deviceType {
        case .iPhoneSE:
            return SpacingGrid.small
        case .iPhone, .iPhonePlus, .iPhoneX, .iPhoneMax:
            return SpacingGrid.medium
        case .iPad:
            return SpacingGrid.large
        }
    }
    
    private func getVerticalPadding() -> CGFloat {
        switch patternsManager.deviceType {
        case .iPhoneSE:
            return SpacingGrid.small
        case .iPhone, .iPhonePlus, .iPhoneX, .iPhoneMax:
            return SpacingGrid.medium
        case .iPad:
            return SpacingGrid.large
        }
    }
}

// MARK: - iOS Compact Layout Modifier
public struct iOSCompactLayoutModifier: ViewModifier {
    
    @ObservedObject private var patternsManager = iOSDesignPatternsManager.shared
    
    public func body(content: Content) -> some View {
        content
            .padding(.horizontal, SpacingGrid.small)
            .padding(.vertical, SpacingGrid.small)
    }
}

// MARK: - iOS Large Layout Modifier
public struct iOSLargeLayoutModifier: ViewModifier {
    
    @ObservedObject private var patternsManager = iOSDesignPatternsManager.shared
    
    public func body(content: Content) -> some View {
        content
            .padding(.horizontal, SpacingGrid.large)
            .padding(.vertical, SpacingGrid.large)
    }
}

// MARK: - iOS Safe Area Modifier
public struct iOSSafeAreaModifier: ViewModifier {
    
    public func body(content: Content) -> some View {
        content
            .edgesIgnoringSafeArea(.all)
    }
}

// MARK: - iOS Design Pattern Testing
public extension iOSDesignPatternsManager {
    
    /// Test device type detection
    func testDeviceTypeDetection() -> String {
        return "Current device: \(deviceType.description)"
    }
    
    /// Test responsive layout
    func testResponsiveLayout() -> (horizontalPadding: CGFloat, verticalPadding: CGFloat) {
        let horizontalPadding: CGFloat
        let verticalPadding: CGFloat
        
        switch deviceType {
        case .iPhoneSE:
            horizontalPadding = SpacingGrid.small
            verticalPadding = SpacingGrid.small
        case .iPhone, .iPhonePlus, .iPhoneX, .iPhoneMax:
            horizontalPadding = SpacingGrid.medium
            verticalPadding = SpacingGrid.medium
        case .iPad:
            horizontalPadding = SpacingGrid.large
            verticalPadding = SpacingGrid.large
        }
        
        return (horizontalPadding, verticalPadding)
    }
    
    /// Get current layout configuration
    func getCurrentLayoutConfiguration() -> String {
        return """
        Device: \(deviceType.description)
        Orientation: \(orientation.rawValue)
        Compact Width: \(isCompactWidth)
        """
    }
} 
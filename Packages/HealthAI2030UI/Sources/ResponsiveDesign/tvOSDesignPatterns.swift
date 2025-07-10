import SwiftUI

// MARK: - tvOS Design Patterns Manager
/// Comprehensive tvOS-specific design patterns for HealthAI 2030
/// Provides large screen interface elements, remote navigation, and tvOS platform best practices
public class tvOSDesignPatternsManager: ObservableObject {
    
    @Published public var screenSize: CGSize = CGSize(width: 1920, height: 1080)
    @Published public var is4K: Bool = false
    @Published public var isFocusEnabled: Bool = true
    @Published public var isRemoteNavigationEnabled: Bool = true
    
    public static let shared = tvOSDesignPatternsManager()
    
    private init() {
        setupTVObserver()
        updateTVInfo()
    }
    
    /// Setup observer for TV changes
    private func setupTVObserver() {
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("TVScreenSizeDidChange"),
            object: nil,
            queue: .main
        ) { _ in
            self.handleScreenSizeChange()
        }
    }
    
    /// Handle screen size changes
    private func handleScreenSizeChange() {
        updateTVInfo()
    }
    
    /// Update TV information
    private func updateTVInfo() {
        // In a real implementation, this would detect actual screen size
        let screenSize = UIScreen.main.bounds.size
        self.screenSize = screenSize
        is4K = screenSize.width >= 3840 || screenSize.height >= 2160
    }
    
    /// Calculate optimal focus size
    public func calculateOptimalFocusSize() -> CGSize {
        if is4K {
            return CGSize(width: 120, height: 120)
        } else {
            return CGSize(width: 80, height: 80)
        }
    }
}

// MARK: - tvOS Layout Patterns
public struct tvOSLayoutPatterns {
    
    // MARK: - Navigation Patterns
    
    /// Standard tvOS navigation pattern
    public static func standardNavigation(
        title: String,
        subtitle: String? = nil
    ) -> some View {
        VStack(spacing: SpacingGrid.tvLarge) {
            Text(title)
                .font(TypographySystem.tvTitle)
                .fontWeight(.bold)
                .foregroundColor(ColorPalette.textPrimary)
                .multilineTextAlignment(.center)
            
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(TypographySystem.tvSubtitle)
                    .foregroundColor(ColorPalette.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(SpacingGrid.tvExtraLarge)
        .frame(maxWidth: .infinity)
    }
    
    /// Large tvOS navigation pattern
    public static func largeNavigation(
        title: String,
        subtitle: String? = nil,
        description: String? = nil
    ) -> some View {
        VStack(spacing: SpacingGrid.tvExtraLarge) {
            Text(title)
                .font(TypographySystem.tvLargeTitle)
                .fontWeight(.bold)
                .foregroundColor(ColorPalette.textPrimary)
                .multilineTextAlignment(.center)
            
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(TypographySystem.tvTitle)
                    .foregroundColor(ColorPalette.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            if let description = description {
                Text(description)
                    .font(TypographySystem.tvBody)
                    .foregroundColor(ColorPalette.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, SpacingGrid.tvExtraLarge)
            }
        }
        .padding(SpacingGrid.tvExtraLarge)
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Grid Patterns
    
    /// Standard tvOS grid pattern
    public static func standardGrid<Content: View>(
        columns: Int = 4,
        @ViewBuilder content: () -> Content
    ) -> some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: SpacingGrid.tvLarge), count: columns),
            spacing: SpacingGrid.tvLarge
        ) {
            content()
        }
        .padding(SpacingGrid.tvExtraLarge)
    }
    
    /// Large tvOS grid pattern
    public static func largeGrid<Content: View>(
        columns: Int = 3,
        @ViewBuilder content: () -> Content
    ) -> some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: SpacingGrid.tvExtraLarge), count: columns),
            spacing: SpacingGrid.tvExtraLarge
        ) {
            content()
        }
        .padding(SpacingGrid.tvExtraLarge)
    }
    
    // MARK: - Card Patterns
    
    /// Standard tvOS card pattern
    public static func standardCard<Content: View>(
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack {
            content()
        }
        .padding(SpacingGrid.tvLarge)
        .background(ColorPalette.tvCardBackground)
        .cornerRadius(SpacingGrid.tvMedium)
        .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 10)
    }
    
    /// Large tvOS card pattern
    public static func largeCard<Content: View>(
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack {
            content()
        }
        .padding(SpacingGrid.tvExtraLarge)
        .background(ColorPalette.tvCardBackground)
        .cornerRadius(SpacingGrid.tvLarge)
        .shadow(color: Color.black.opacity(0.4), radius: 30, x: 0, y: 15)
    }
    
    // MARK: - Health Metric Patterns
    
    /// Standard tvOS health metric pattern
    public static func standardHealthMetric(
        title: String,
        value: String,
        unit: String? = nil,
        color: Color
    ) -> some View {
        VStack(spacing: SpacingGrid.tvLarge) {
            Text(title)
                .font(TypographySystem.tvSubtitle)
                .foregroundColor(ColorPalette.textSecondary)
                .multilineTextAlignment(.center)
            
            HStack(alignment: .bottom, spacing: SpacingGrid.tvMedium) {
                Text(value)
                    .font(TypographySystem.tvMetric)
                    .fontWeight(.bold)
                    .foregroundColor(ColorPalette.textPrimary)
                
                if let unit = unit {
                    Text(unit)
                        .font(TypographySystem.tvUnit)
                        .foregroundColor(ColorPalette.textSecondary)
                }
            }
        }
        .padding(SpacingGrid.tvExtraLarge)
        .background(color.opacity(0.1))
        .cornerRadius(SpacingGrid.tvLarge)
        .overlay(
            RoundedRectangle(cornerRadius: SpacingGrid.tvLarge)
                .stroke(color.opacity(0.3), lineWidth: 3)
        )
    }
    
    /// Large tvOS health metric pattern
    public static func largeHealthMetric(
        title: String,
        value: String,
        unit: String? = nil,
        color: Color
    ) -> some View {
        VStack(spacing: SpacingGrid.tvExtraLarge) {
            Text(title)
                .font(TypographySystem.tvTitle)
                .foregroundColor(ColorPalette.textSecondary)
                .multilineTextAlignment(.center)
            
            HStack(alignment: .bottom, spacing: SpacingGrid.tvLarge) {
                Text(value)
                    .font(TypographySystem.tvLargeMetric)
                    .fontWeight(.bold)
                    .foregroundColor(ColorPalette.textPrimary)
                
                if let unit = unit {
                    Text(unit)
                        .font(TypographySystem.tvLargeUnit)
                        .foregroundColor(ColorPalette.textSecondary)
                }
            }
        }
        .padding(SpacingGrid.tvExtraLarge)
        .background(color.opacity(0.1))
        .cornerRadius(SpacingGrid.tvExtraLarge)
        .overlay(
            RoundedRectangle(cornerRadius: SpacingGrid.tvExtraLarge)
                .stroke(color.opacity(0.3), lineWidth: 4)
        )
    }
    
    // MARK: - Button Patterns
    
    /// Standard tvOS button pattern
    public static func standardButton(
        title: String,
        icon: String? = nil,
        color: Color = ColorPalette.primary,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: SpacingGrid.tvLarge) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 32))
                }
                
                Text(title)
                    .font(TypographySystem.tvButton)
                    .fontWeight(.semibold)
            }
            .frame(minWidth: 200, minHeight: 60)
            .padding(.horizontal, SpacingGrid.tvLarge)
            .padding(.vertical, SpacingGrid.tvMedium)
        }
        .background(color)
        .foregroundColor(.white)
        .cornerRadius(SpacingGrid.tvMedium)
        .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 5)
    }
    
    /// Large tvOS button pattern
    public static func largeButton(
        title: String,
        icon: String? = nil,
        color: Color = ColorPalette.primary,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: SpacingGrid.tvExtraLarge) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 48))
                }
                
                Text(title)
                    .font(TypographySystem.tvLargeButton)
                    .fontWeight(.bold)
            }
            .frame(minWidth: 300, minHeight: 80)
            .padding(.horizontal, SpacingGrid.tvExtraLarge)
            .padding(.vertical, SpacingGrid.tvLarge)
        }
        .background(color)
        .foregroundColor(.white)
        .cornerRadius(SpacingGrid.tvLarge)
        .shadow(color: Color.black.opacity(0.4), radius: 15, x: 0, y: 8)
    }
    
    // MARK: - Focus Patterns
    
    /// Standard tvOS focus pattern
    public static func standardFocus<Content: View>(
        @ViewBuilder content: () -> Content
    ) -> some View {
        content()
            .scaleEffect(1.1)
            .shadow(color: ColorPalette.primary.opacity(0.5), radius: 20, x: 0, y: 10)
            .animation(.easeInOut(duration: 0.3), value: true)
    }
    
    /// Large tvOS focus pattern
    public static func largeFocus<Content: View>(
        @ViewBuilder content: () -> Content
    ) -> some View {
        content()
            .scaleEffect(1.15)
            .shadow(color: ColorPalette.primary.opacity(0.6), radius: 30, x: 0, y: 15)
            .animation(.easeInOut(duration: 0.3), value: true)
    }
    
    // MARK: - Alert Patterns
    
    /// Standard tvOS alert pattern
    public static func standardAlert(
        title: String,
        message: String,
        primaryAction: String,
        secondaryAction: String? = nil,
        primaryActionHandler: @escaping () -> Void,
        secondaryActionHandler: (() -> Void)? = nil
    ) -> some View {
        VStack(spacing: SpacingGrid.tvExtraLarge) {
            Text(title)
                .font(TypographySystem.tvTitle)
                .fontWeight(.bold)
                .foregroundColor(ColorPalette.textPrimary)
                .multilineTextAlignment(.center)
            
            Text(message)
                .font(TypographySystem.tvBody)
                .foregroundColor(ColorPalette.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, SpacingGrid.tvExtraLarge)
            
            HStack(spacing: SpacingGrid.tvLarge) {
                standardButton(title: primaryAction, action: primaryActionHandler)
                
                if let secondaryAction = secondaryAction {
                    standardButton(
                        title: secondaryAction,
                        color: ColorPalette.secondary,
                        action: secondaryActionHandler ?? {}
                    )
                }
            }
        }
        .padding(SpacingGrid.tvExtraLarge)
        .background(ColorPalette.tvAlertBackground)
        .cornerRadius(SpacingGrid.tvLarge)
        .shadow(color: Color.black.opacity(0.5), radius: 40, x: 0, y: 20)
    }
    
    /// Large tvOS alert pattern
    public static func largeAlert(
        title: String,
        message: String,
        action: String,
        actionHandler: @escaping () -> Void
    ) -> some View {
        VStack(spacing: SpacingGrid.tvExtraLarge) {
            Text(title)
                .font(TypographySystem.tvLargeTitle)
                .fontWeight(.bold)
                .foregroundColor(ColorPalette.textPrimary)
                .multilineTextAlignment(.center)
            
            Text(message)
                .font(TypographySystem.tvTitle)
                .foregroundColor(ColorPalette.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, SpacingGrid.tvExtraLarge)
            
            largeButton(title: action, action: actionHandler)
        }
        .padding(SpacingGrid.tvExtraLarge)
        .background(ColorPalette.tvAlertBackground)
        .cornerRadius(SpacingGrid.tvExtraLarge)
        .shadow(color: Color.black.opacity(0.6), radius: 50, x: 0, y: 25)
    }
}

// MARK: - tvOS Responsive Layout Modifiers
public extension View {
    
    /// Apply tvOS-specific responsive layout
    func tvOSResponsiveLayout() -> some View {
        self.modifier(tvOSResponsiveLayoutModifier())
    }
    
    /// Apply tvOS focus support
    func tvOSFocusSupport() -> some View {
        self.modifier(tvOSFocusModifier())
    }
    
    /// Apply tvOS remote navigation support
    func tvOSRemoteNavigationSupport() -> some View {
        self.modifier(tvOSRemoteNavigationModifier())
    }
    
    /// Apply tvOS large screen optimization
    func tvOSLargeScreenOptimization() -> some View {
        self.modifier(tvOSLargeScreenModifier())
    }
}

// MARK: - tvOS Responsive Layout Modifier
public struct tvOSResponsiveLayoutModifier: ViewModifier {
    
    @ObservedObject private var patternsManager = tvOSDesignPatternsManager.shared
    
    public func body(content: Content) -> some View {
        content
            .padding(.horizontal, getHorizontalPadding())
            .padding(.vertical, getVerticalPadding())
    }
    
    private func getHorizontalPadding() -> CGFloat {
        if patternsManager.is4K {
            return SpacingGrid.tvExtraLarge * 2
        } else {
            return SpacingGrid.tvExtraLarge
        }
    }
    
    private func getVerticalPadding() -> CGFloat {
        if patternsManager.is4K {
            return SpacingGrid.tvExtraLarge * 2
        } else {
            return SpacingGrid.tvExtraLarge
        }
    }
}

// MARK: - tvOS Focus Modifier
public struct tvOSFocusModifier: ViewModifier {
    
    @ObservedObject private var patternsManager = tvOSDesignPatternsManager.shared
    
    public func body(content: Content) -> some View {
        content
            .scaleEffect(patternsManager.isFocusEnabled ? 1.1 : 1.0)
            .shadow(
                color: patternsManager.isFocusEnabled ? ColorPalette.primary.opacity(0.5) : Color.clear,
                radius: patternsManager.isFocusEnabled ? 20 : 0,
                x: 0,
                y: patternsManager.isFocusEnabled ? 10 : 0
            )
            .animation(.easeInOut(duration: 0.3), value: patternsManager.isFocusEnabled)
    }
}

// MARK: - tvOS Remote Navigation Modifier
public struct tvOSRemoteNavigationModifier: ViewModifier {
    
    @ObservedObject private var patternsManager = tvOSDesignPatternsManager.shared
    
    public func body(content: Content) -> some View {
        content
            .focusable(patternsManager.isRemoteNavigationEnabled)
    }
}

// MARK: - tvOS Large Screen Modifier
public struct tvOSLargeScreenModifier: ViewModifier {
    
    @ObservedObject private var patternsManager = tvOSDesignPatternsManager.shared
    
    public func body(content: Content) -> some View {
        content
            .frame(maxWidth: patternsManager.is4K ? 800 : 600)
            .frame(maxHeight: patternsManager.is4K ? 600 : 400)
    }
}

// MARK: - tvOS Color Extensions
public extension ColorPalette {
    
    /// tvOS-specific background colors
    static let tvCardBackground = Color(red: 0.1, green: 0.1, blue: 0.15)
    static let tvAlertBackground = Color(red: 0.15, green: 0.15, blue: 0.2)
}

// MARK: - tvOS Typography Extensions
public extension TypographySystem {
    
    /// tvOS-specific typography
    static let tvLargeTitle = Font.system(size: 72, weight: .bold, design: .rounded)
    static let tvTitle = Font.system(size: 48, weight: .bold, design: .rounded)
    static let tvSubtitle = Font.system(size: 32, weight: .semibold, design: .rounded)
    static let tvBody = Font.system(size: 24, weight: .regular, design: .rounded)
    static let tvButton = Font.system(size: 28, weight: .semibold, design: .rounded)
    static let tvLargeButton = Font.system(size: 36, weight: .bold, design: .rounded)
    static let tvMetric = Font.system(size: 64, weight: .bold, design: .rounded)
    static let tvLargeMetric = Font.system(size: 96, weight: .bold, design: .rounded)
    static let tvUnit = Font.system(size: 32, weight: .regular, design: .rounded)
    static let tvLargeUnit = Font.system(size: 48, weight: .regular, design: .rounded)
}

// MARK: - tvOS Spacing Extensions
public extension SpacingGrid {
    
    /// tvOS-specific spacing
    static let tvMedium: CGFloat = 20
    static let tvLarge: CGFloat = 40
    static let tvExtraLarge: CGFloat = 60
}

// MARK: - tvOS Design Pattern Testing
public extension tvOSDesignPatternsManager {
    
    /// Test screen size detection
    func testScreenSizeDetection() -> String {
        return """
        Screen Size: \(screenSize.width) x \(screenSize.height)
        4K Display: \(is4K)
        """
    }
    
    /// Test responsive layout
    func testResponsiveLayout() -> (horizontalPadding: CGFloat, verticalPadding: CGFloat) {
        let horizontalPadding: CGFloat = is4K ? SpacingGrid.tvExtraLarge * 2 : SpacingGrid.tvExtraLarge
        let verticalPadding: CGFloat = is4K ? SpacingGrid.tvExtraLarge * 2 : SpacingGrid.tvExtraLarge
        
        return (horizontalPadding, verticalPadding)
    }
    
    /// Get current layout configuration
    func getCurrentLayoutConfiguration() -> String {
        return """
        Screen Size: \(screenSize.width) x \(screenSize.height)
        4K Display: \(is4K)
        Focus Enabled: \(isFocusEnabled)
        Remote Navigation: \(isRemoteNavigationEnabled)
        """
    }
} 
import SwiftUI

// MARK: - watchOS Design Patterns Manager
/// Comprehensive watchOS-specific design patterns for HealthAI 2030
/// Provides compact interface elements, health monitoring optimizations, and watchOS platform best practices
public class watchOSDesignPatternsManager: ObservableObject {
    
    @Published public var watchSize: WatchSize = .medium
    @Published public var isDigitalCrownEnabled: Bool = true
    @Published public var isComplicationEnabled: Bool = true
    @Published public var isHealthKitEnabled: Bool = true
    
    public static let shared = watchOSDesignPatternsManager()
    
    private init() {
        setupWatchObserver()
        updateWatchInfo()
    }
    
    /// Setup observer for watch changes
    private func setupWatchObserver() {
        // In a real implementation, this would observe watch-specific notifications
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("WatchSizeDidChange"),
            object: nil,
            queue: .main
        ) { _ in
            self.handleWatchSizeChange()
        }
    }
    
    /// Handle watch size changes
    private func handleWatchSizeChange() {
        updateWatchInfo()
    }
    
    /// Update watch information
    private func updateWatchInfo() {
        // In a real implementation, this would detect actual watch size
        let screenSize = WKInterfaceDevice.current().screenBounds.size
        watchSize = determineWatchSize(screenSize: screenSize)
    }
    
    /// Determine watch size based on screen size
    private func determineWatchSize(screenSize: CGSize) -> WatchSize {
        let width = screenSize.width
        let height = screenSize.height
        
        switch (width, height) {
        case (136, 170): // 38mm
            return .small
        case (156, 195): // 40mm
            return .small
        case (162, 197): // 41mm
            return .small
        case (180, 215): // 42mm
            return .medium
        case (198, 242): // 44mm
            return .medium
        case (205, 251): // 45mm
            return .large
        case (227, 277): // 49mm
            return .large
        default:
            return .medium
        }
    }
}

// MARK: - Watch Size
public enum WatchSize {
    case small
    case medium
    case large
    
    var description: String {
        switch self {
        case .small:
            return "Small (38-41mm)"
        case .medium:
            return "Medium (42-44mm)"
        case .large:
            return "Large (45-49mm)"
        }
    }
    
    var isCompact: Bool {
        switch self {
        case .small:
            return true
        default:
            return false
        }
    }
    
    var isLarge: Bool {
        switch self {
        case .large:
            return true
        default:
            return false
        }
    }
}

// MARK: - watchOS Layout Patterns
public struct watchOSLayoutPatterns {
    
    // MARK: - Navigation Patterns
    
    /// Standard watchOS navigation pattern
    public static func standardNavigation(
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
                .font(TypographySystem.watchTitle)
                .fontWeight(.semibold)
                .foregroundColor(ColorPalette.textPrimary)
                .lineLimit(1)
            
            if let trailingButton = trailingButton {
                trailingButton()
            } else {
                Spacer()
            }
        }
        .padding(.horizontal, SpacingGrid.watchSmall)
        .frame(height: 32)
    }
    
    /// Compact watchOS navigation pattern
    public static func compactNavigation(
        title: String
    ) -> some View {
        Text(title)
            .font(TypographySystem.watchCompactTitle)
            .fontWeight(.semibold)
            .foregroundColor(ColorPalette.textPrimary)
            .lineLimit(1)
            .padding(.horizontal, SpacingGrid.watchSmall)
    }
    
    // MARK: - List Patterns
    
    /// Standard watchOS list pattern
    public static func standardList<Content: View>(
        @ViewBuilder content: () -> Content
    ) -> some View {
        ScrollView {
            LazyVStack(spacing: SpacingGrid.watchSmall) {
                content()
            }
            .padding(.horizontal, SpacingGrid.watchSmall)
        }
    }
    
    /// Compact watchOS list pattern
    public static func compactList<Content: View>(
        @ViewBuilder content: () -> Content
    ) -> some View {
        ScrollView {
            LazyVStack(spacing: 2) {
                content()
            }
            .padding(.horizontal, 4)
        }
    }
    
    // MARK: - Card Patterns
    
    /// Standard watchOS card pattern
    public static func standardCard<Content: View>(
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack {
            content()
        }
        .padding(SpacingGrid.watchMedium)
        .background(ColorPalette.watchCardBackground)
        .cornerRadius(SpacingGrid.watchSmall)
    }
    
    /// Compact watchOS card pattern
    public static func compactCard<Content: View>(
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack {
            content()
        }
        .padding(SpacingGrid.watchSmall)
        .background(ColorPalette.watchCardBackground)
        .cornerRadius(4)
    }
    
    // MARK: - Health Metric Patterns
    
    /// Standard watchOS health metric pattern
    public static func standardHealthMetric(
        title: String,
        value: String,
        unit: String? = nil,
        color: Color
    ) -> some View {
        VStack(spacing: SpacingGrid.watchSmall) {
            Text(title)
                .font(TypographySystem.watchCaption)
                .foregroundColor(ColorPalette.textSecondary)
                .lineLimit(1)
            
            HStack(alignment: .bottom, spacing: 2) {
                Text(value)
                    .font(TypographySystem.watchMetric)
                    .fontWeight(.bold)
                    .foregroundColor(ColorPalette.textPrimary)
                
                if let unit = unit {
                    Text(unit)
                        .font(TypographySystem.watchUnit)
                        .foregroundColor(ColorPalette.textSecondary)
                }
            }
        }
        .padding(SpacingGrid.watchMedium)
        .background(color.opacity(0.1))
        .cornerRadius(SpacingGrid.watchSmall)
        .overlay(
            RoundedRectangle(cornerRadius: SpacingGrid.watchSmall)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
    }
    
    /// Compact watchOS health metric pattern
    public static func compactHealthMetric(
        title: String,
        value: String,
        unit: String? = nil,
        color: Color
    ) -> some View {
        VStack(spacing: 2) {
            Text(title)
                .font(TypographySystem.watchCompactCaption)
                .foregroundColor(ColorPalette.textSecondary)
                .lineLimit(1)
            
            HStack(alignment: .bottom, spacing: 1) {
                Text(value)
                    .font(TypographySystem.watchCompactMetric)
                    .fontWeight(.bold)
                    .foregroundColor(ColorPalette.textPrimary)
                
                if let unit = unit {
                    Text(unit)
                        .font(TypographySystem.watchCompactUnit)
                        .foregroundColor(ColorPalette.textSecondary)
                }
            }
        }
        .padding(SpacingGrid.watchSmall)
        .background(color.opacity(0.1))
        .cornerRadius(4)
    }
    
    // MARK: - Button Patterns
    
    /// Standard watchOS button pattern
    public static func standardButton(
        title: String,
        icon: String? = nil,
        color: Color = ColorPalette.primary,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: SpacingGrid.watchSmall) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 14))
                }
                
                Text(title)
                    .font(TypographySystem.watchButton)
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, SpacingGrid.watchSmall)
        }
        .background(color)
        .foregroundColor(.white)
        .cornerRadius(SpacingGrid.watchSmall)
    }
    
    /// Compact watchOS button pattern
    public static func compactButton(
        title: String,
        icon: String? = nil,
        color: Color = ColorPalette.primary,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 2) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 12))
                }
                
                Text(title)
                    .font(TypographySystem.watchCompactButton)
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
        }
        .background(color)
        .foregroundColor(.white)
        .cornerRadius(4)
    }
    
    // MARK: - Progress Patterns
    
    /// Standard watchOS progress pattern
    public static func standardProgress(
        value: Double,
        total: Double,
        color: Color = ColorPalette.primary
    ) -> some View {
        VStack(spacing: SpacingGrid.watchSmall) {
            ProgressView(value: value, total: total)
                .progressViewStyle(LinearProgressViewStyle(tint: color))
                .scaleEffect(y: 2)
            
            Text("\(Int((value / total) * 100))%")
                .font(TypographySystem.watchCaption)
                .foregroundColor(ColorPalette.textSecondary)
        }
        .padding(SpacingGrid.watchMedium)
    }
    
    /// Compact watchOS progress pattern
    public static func compactProgress(
        value: Double,
        total: Double,
        color: Color = ColorPalette.primary
    ) -> some View {
        VStack(spacing: 2) {
            ProgressView(value: value, total: total)
                .progressViewStyle(LinearProgressViewStyle(tint: color))
                .scaleEffect(y: 1.5)
            
            Text("\(Int((value / total) * 100))%")
                .font(TypographySystem.watchCompactCaption)
                .foregroundColor(ColorPalette.textSecondary)
        }
        .padding(SpacingGrid.watchSmall)
    }
    
    // MARK: - Alert Patterns
    
    /// Standard watchOS alert pattern
    public static func standardAlert(
        title: String,
        message: String,
        primaryAction: String,
        secondaryAction: String? = nil,
        primaryActionHandler: @escaping () -> Void,
        secondaryActionHandler: (() -> Void)? = nil
    ) -> some View {
        VStack(spacing: SpacingGrid.watchMedium) {
            Text(title)
                .font(TypographySystem.watchTitle)
                .fontWeight(.semibold)
                .foregroundColor(ColorPalette.textPrimary)
                .multilineTextAlignment(.center)
            
            Text(message)
                .font(TypographySystem.watchBody)
                .foregroundColor(ColorPalette.textSecondary)
                .multilineTextAlignment(.center)
            
            VStack(spacing: SpacingGrid.watchSmall) {
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
        .padding(SpacingGrid.watchMedium)
    }
    
    /// Compact watchOS alert pattern
    public static func compactAlert(
        title: String,
        message: String,
        action: String,
        actionHandler: @escaping () -> Void
    ) -> some View {
        VStack(spacing: SpacingGrid.watchSmall) {
            Text(title)
                .font(TypographySystem.watchCompactTitle)
                .fontWeight(.semibold)
                .foregroundColor(ColorPalette.textPrimary)
                .multilineTextAlignment(.center)
            
            Text(message)
                .font(TypographySystem.watchCompactBody)
                .foregroundColor(ColorPalette.textSecondary)
                .multilineTextAlignment(.center)
            
            compactButton(title: action, action: actionHandler)
        }
        .padding(SpacingGrid.watchSmall)
    }
}

// MARK: - watchOS Responsive Layout Modifiers
public extension View {
    
    /// Apply watchOS-specific responsive layout
    func watchOSResponsiveLayout() -> some View {
        self.modifier(watchOSResponsiveLayoutModifier())
    }
    
    /// Apply watchOS compact layout
    func watchOSCompactLayout() -> some View {
        self.modifier(watchOSCompactLayoutModifier())
    }
    
    /// Apply watchOS large layout
    func watchOSLargeLayout() -> some View {
        self.modifier(watchOSLargeLayoutModifier())
    }
    
    /// Apply watchOS digital crown support
    func watchOSDigitalCrownSupport() -> some View {
        self.modifier(watchOSDigitalCrownModifier())
    }
}

// MARK: - watchOS Responsive Layout Modifier
public struct watchOSResponsiveLayoutModifier: ViewModifier {
    
    @ObservedObject private var patternsManager = watchOSDesignPatternsManager.shared
    
    public func body(content: Content) -> some View {
        content
            .padding(.horizontal, getHorizontalPadding())
            .padding(.vertical, getVerticalPadding())
    }
    
    private func getHorizontalPadding() -> CGFloat {
        switch patternsManager.watchSize {
        case .small:
            return SpacingGrid.watchSmall
        case .medium:
            return SpacingGrid.watchMedium
        case .large:
            return SpacingGrid.watchLarge
        }
    }
    
    private func getVerticalPadding() -> CGFloat {
        switch patternsManager.watchSize {
        case .small:
            return SpacingGrid.watchSmall
        case .medium:
            return SpacingGrid.watchMedium
        case .large:
            return SpacingGrid.watchLarge
        }
    }
}

// MARK: - watchOS Compact Layout Modifier
public struct watchOSCompactLayoutModifier: ViewModifier {
    
    public func body(content: Content) -> some View {
        content
            .padding(.horizontal, SpacingGrid.watchSmall)
            .padding(.vertical, SpacingGrid.watchSmall)
    }
}

// MARK: - watchOS Large Layout Modifier
public struct watchOSLargeLayoutModifier: ViewModifier {
    
    public func body(content: Content) -> some View {
        content
            .padding(.horizontal, SpacingGrid.watchLarge)
            .padding(.vertical, SpacingGrid.watchLarge)
    }
}

// MARK: - watchOS Digital Crown Modifier
public struct watchOSDigitalCrownModifier: ViewModifier {
    
    public func body(content: Content) -> some View {
        content
            .focusable()
            .digitalCrownRotation { _ in
                // Handle digital crown rotation
            }
    }
}

// MARK: - watchOS Color Extensions
public extension ColorPalette {
    
    /// watchOS-specific background colors
    static let watchCardBackground = Color(red: 0.95, green: 0.95, blue: 0.97)
    static let watchAlertBackground = Color(red: 0.98, green: 0.98, blue: 0.98)
}

// MARK: - watchOS Typography Extensions
public extension TypographySystem {
    
    /// watchOS-specific typography
    static let watchTitle = Font.system(size: 16, weight: .semibold, design: .rounded)
    static let watchCompactTitle = Font.system(size: 14, weight: .semibold, design: .rounded)
    static let watchBody = Font.system(size: 14, weight: .regular, design: .rounded)
    static let watchCompactBody = Font.system(size: 12, weight: .regular, design: .rounded)
    static let watchCaption = Font.system(size: 12, weight: .medium, design: .rounded)
    static let watchCompactCaption = Font.system(size: 10, weight: .medium, design: .rounded)
    static let watchButton = Font.system(size: 14, weight: .medium, design: .rounded)
    static let watchCompactButton = Font.system(size: 12, weight: .medium, design: .rounded)
    static let watchMetric = Font.system(size: 18, weight: .bold, design: .rounded)
    static let watchCompactMetric = Font.system(size: 16, weight: .bold, design: .rounded)
    static let watchUnit = Font.system(size: 12, weight: .regular, design: .rounded)
    static let watchCompactUnit = Font.system(size: 10, weight: .regular, design: .rounded)
}

// MARK: - watchOS Spacing Extensions
public extension SpacingGrid {
    
    /// watchOS-specific spacing
    static let watchSmall: CGFloat = 4
    static let watchMedium: CGFloat = 8
    static let watchLarge: CGFloat = 12
}

// MARK: - watchOS Design Pattern Testing
public extension watchOSDesignPatternsManager {
    
    /// Test watch size detection
    func testWatchSizeDetection() -> String {
        return "Current watch size: \(watchSize.description)"
    }
    
    /// Test responsive layout
    func testResponsiveLayout() -> (horizontalPadding: CGFloat, verticalPadding: CGFloat) {
        let horizontalPadding: CGFloat
        let verticalPadding: CGFloat
        
        switch watchSize {
        case .small:
            horizontalPadding = SpacingGrid.watchSmall
            verticalPadding = SpacingGrid.watchSmall
        case .medium:
            horizontalPadding = SpacingGrid.watchMedium
            verticalPadding = SpacingGrid.watchMedium
        case .large:
            horizontalPadding = SpacingGrid.watchLarge
            verticalPadding = SpacingGrid.watchLarge
        }
        
        return (horizontalPadding, verticalPadding)
    }
    
    /// Get current layout configuration
    func getCurrentLayoutConfiguration() -> String {
        return """
        Watch Size: \(watchSize.description)
        Digital Crown: \(isDigitalCrownEnabled)
        Complications: \(isComplicationEnabled)
        HealthKit: \(isHealthKitEnabled)
        """
    }
} 
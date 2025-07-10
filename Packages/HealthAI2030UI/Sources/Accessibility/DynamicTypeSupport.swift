import SwiftUI

// MARK: - Dynamic Type Support Manager
/// Comprehensive Dynamic Type support for HealthAI 2030
/// Provides scalable typography, responsive layouts, and healthcare-optimized text sizing
public class DynamicTypeSupportManager: ObservableObject {
    
    @Published public var isDynamicTypeEnabled: Bool = true
    @Published public var preferredTextSize: DynamicTypeSize = .large
    @Published public var minimumReadableSize: DynamicTypeSize = .medium
    @Published public var maximumComfortableSize: DynamicTypeSize = .accessibility3
    
    public static let shared = DynamicTypeSupportManager()
    
    private init() {
        setupDynamicTypeObserver()
    }
    
    /// Setup observer for Dynamic Type changes
    private func setupDynamicTypeObserver() {
        NotificationCenter.default.addObserver(
            forName: UIContentSizeCategory.didChangeNotification,
            object: nil,
            queue: .main
        ) { _ in
            self.handleDynamicTypeChange()
        }
    }
    
    /// Handle Dynamic Type size changes
    private func handleDynamicTypeChange() {
        let newSize = UIScreen.main.traitCollection.preferredContentSizeCategory
        preferredTextSize = DynamicTypeSize(newSize)
        
        // Notify observers of the change
        objectWillChange.send()
    }
    
    /// Check if current text size is within readable range
    public func isTextSizeReadable() -> Bool {
        return preferredTextSize >= minimumReadableSize
    }
    
    /// Check if current text size is within comfortable range
    public func isTextSizeComfortable() -> Bool {
        return preferredTextSize <= maximumComfortableSize
    }
    
    /// Get recommended font size for current Dynamic Type setting
    public func getRecommendedFontSize(baseSize: CGFloat) -> CGFloat {
        let scaleFactor = getScaleFactor()
        return baseSize * scaleFactor
    }
    
    /// Get scale factor for current Dynamic Type setting
    public func getScaleFactor() -> CGFloat {
        switch preferredTextSize {
        case .xSmall:
            return 0.8
        case .small:
            return 0.9
        case .medium:
            return 1.0
        case .large:
            return 1.1
        case .xLarge:
            return 1.2
        case .xxLarge:
            return 1.3
        case .xxxLarge:
            return 1.4
        case .accessibility1:
            return 1.5
        case .accessibility2:
            return 1.7
        case .accessibility3:
            return 1.9
        case .accessibility4:
            return 2.1
        case .accessibility5:
            return 2.3
        @unknown default:
            return 1.0
        }
    }
}

// MARK: - Dynamic Type Size Extensions
public extension DynamicTypeSize {
    
    /// Initialize from UIContentSizeCategory
    init(_ category: UIContentSizeCategory) {
        switch category {
        case .extraSmall:
            self = .xSmall
        case .small:
            self = .small
        case .medium:
            self = .medium
        case .large:
            self = .large
        case .extraLarge:
            self = .xLarge
        case .extraExtraLarge:
            self = .xxLarge
        case .extraExtraExtraLarge:
            self = .xxxLarge
        case .accessibilityMedium:
            self = .accessibility1
        case .accessibilityLarge:
            self = .accessibility2
        case .accessibilityExtraLarge:
            self = .accessibility3
        case .accessibilityExtraExtraLarge:
            self = .accessibility4
        case .accessibilityExtraExtraExtraLarge:
            self = .accessibility5
        default:
            self = .large
        }
    }
    
    /// Get description for accessibility
    var accessibilityDescription: String {
        switch self {
        case .xSmall:
            return "extra small"
        case .small:
            return "small"
        case .medium:
            return "medium"
        case .large:
            return "large"
        case .xLarge:
            return "extra large"
        case .xxLarge:
            return "extra extra large"
        case .xxxLarge:
            return "extra extra extra large"
        case .accessibility1:
            return "accessibility medium"
        case .accessibility2:
            return "accessibility large"
        case .accessibility3:
            return "accessibility extra large"
        case .accessibility4:
            return "accessibility extra extra large"
        case .accessibility5:
            return "accessibility extra extra extra large"
        @unknown default:
            return "unknown"
        }
    }
    
    /// Check if size is accessibility level
    var isAccessibilitySize: Bool {
        switch self {
        case .accessibility1, .accessibility2, .accessibility3, .accessibility4, .accessibility5:
            return true
        default:
            return false
        }
    }
}

// MARK: - Dynamic Type Font Extensions
public extension Font {
    
    /// Create font with Dynamic Type support
    static func dynamicType(
        _ style: Font.TextStyle,
        design: Font.Design = .default,
        weight: Font.Weight = .regular
    ) -> Font {
        return Font.system(style, design: design).weight(weight)
    }
    
    /// Create healthcare-optimized font with Dynamic Type support
    static func healthcareDynamicType(
        _ style: Font.TextStyle,
        weight: Font.Weight = .regular
    ) -> Font {
        return Font.system(style, design: .rounded).weight(weight)
    }
    
    /// Create medical reading font with Dynamic Type support
    static func medicalDynamicType(
        _ style: Font.TextStyle,
        weight: Font.Weight = .regular
    ) -> Font {
        return Font.system(style, design: .serif).weight(weight)
    }
}

// MARK: - Dynamic Type View Modifiers
public extension View {
    
    /// Add Dynamic Type support with minimum size constraint
    func dynamicTypeSupport(
        minimumSize: DynamicTypeSize = .medium,
        maximumSize: DynamicTypeSize = .accessibility5
    ) -> some View {
        self.environment(\.sizeCategory, preferredSizeCategory)
            .scaleEffect(getScaleEffect(minimum: minimumSize, maximum: maximumSize))
    }
    
    /// Add healthcare-optimized Dynamic Type support
    func healthcareDynamicTypeSupport() -> some View {
        self.environment(\.sizeCategory, preferredSizeCategory)
            .scaleEffect(getHealthcareScaleEffect())
    }
    
    /// Add medical reading Dynamic Type support
    func medicalDynamicTypeSupport() -> some View {
        self.environment(\.sizeCategory, preferredSizeCategory)
            .scaleEffect(getMedicalScaleEffect())
    }
    
    /// Add responsive layout for Dynamic Type
    func responsiveLayout() -> some View {
        self.modifier(ResponsiveLayoutModifier())
    }
    
    /// Add adaptive spacing for Dynamic Type
    func adaptiveSpacing() -> some View {
        self.modifier(AdaptiveSpacingModifier())
    }
}

// MARK: - Dynamic Type Helper Functions
private extension View {
    
    var preferredSizeCategory: ContentSizeCategory {
        let manager = DynamicTypeSupportManager.shared
        return ContentSizeCategory(manager.preferredTextSize)
    }
    
    func getScaleEffect(
        minimum: DynamicTypeSize,
        maximum: DynamicTypeSize
    ) -> CGFloat {
        let manager = DynamicTypeSupportManager.shared
        let currentSize = manager.preferredTextSize
        
        if currentSize < minimum {
            return CGFloat(minimum.rawValue) / CGFloat(DynamicTypeSize.medium.rawValue)
        } else if currentSize > maximum {
            return CGFloat(maximum.rawValue) / CGFloat(DynamicTypeSize.medium.rawValue)
        } else {
            return manager.getScaleFactor()
        }
    }
    
    func getHealthcareScaleEffect() -> CGFloat {
        let manager = DynamicTypeSupportManager.shared
        let scaleFactor = manager.getScaleFactor()
        
        // Healthcare apps often need slightly larger text for medical reading
        return scaleFactor * 1.1
    }
    
    func getMedicalScaleEffect() -> CGFloat {
        let manager = DynamicTypeSupportManager.shared
        let scaleFactor = manager.getScaleFactor()
        
        // Medical reading requires even larger text for complex terminology
        return scaleFactor * 1.2
    }
}

// MARK: - Responsive Layout Modifier
public struct ResponsiveLayoutModifier: ViewModifier {
    
    @Environment(\.sizeCategory) private var sizeCategory
    
    public func body(content: Content) -> some View {
        content
            .frame(maxWidth: getMaxWidth())
            .padding(.horizontal, getHorizontalPadding())
            .padding(.vertical, getVerticalPadding())
    }
    
    private func getMaxWidth() -> CGFloat? {
        switch sizeCategory {
        case .accessibility1, .accessibility2, .accessibility3, .accessibility4, .accessibility5:
            return UIScreen.main.bounds.width * 0.95
        default:
            return nil
        }
    }
    
    private func getHorizontalPadding() -> CGFloat {
        switch sizeCategory {
        case .accessibility1, .accessibility2, .accessibility3, .accessibility4, .accessibility5:
            return SpacingGrid.large
        default:
            return SpacingGrid.medium
        }
    }
    
    private func getVerticalPadding() -> CGFloat {
        switch sizeCategory {
        case .accessibility1, .accessibility2, .accessibility3, .accessibility4, .accessibility5:
            return SpacingGrid.medium
        default:
            return SpacingGrid.small
        }
    }
}

// MARK: - Adaptive Spacing Modifier
public struct AdaptiveSpacingModifier: ViewModifier {
    
    @Environment(\.sizeCategory) private var sizeCategory
    
    public func body(content: Content) -> some View {
        content
            .spacing(getAdaptiveSpacing())
    }
    
    private func getAdaptiveSpacing() -> CGFloat {
        switch sizeCategory {
        case .accessibility1, .accessibility2, .accessibility3, .accessibility4, .accessibility5:
            return SpacingGrid.large
        case .xxxLarge, .xxLarge, .xLarge:
            return SpacingGrid.medium
        default:
            return SpacingGrid.small
        }
    }
}

// MARK: - Dynamic Type Typography System
public struct DynamicTypeTypography {
    
    /// Get scalable font for display text
    public static func display(_ size: DynamicTypeSize = .large) -> Font {
        return Font.dynamicType(.largeTitle, weight: .bold)
            .scaledFont(for: size)
    }
    
    /// Get scalable font for headlines
    public static func headline(_ size: DynamicTypeSize = .large) -> Font {
        return Font.dynamicType(.headline, weight: .semibold)
            .scaledFont(for: size)
    }
    
    /// Get scalable font for body text
    public static func body(_ size: DynamicTypeSize = .large) -> Font {
        return Font.dynamicType(.body, weight: .regular)
            .scaledFont(for: size)
    }
    
    /// Get scalable font for medical reading
    public static func medicalReading(_ size: DynamicTypeSize = .large) -> Font {
        return Font.medicalDynamicType(.body, weight: .regular)
            .scaledFont(for: size)
    }
    
    /// Get scalable font for healthcare data
    public static func healthcareData(_ size: DynamicTypeSize = .large) -> Font {
        return Font.healthcareDynamicType(.body, weight: .medium)
            .scaledFont(for: size)
    }
}

// MARK: - Font Scaling Extension
public extension Font {
    
    /// Scale font for specific Dynamic Type size
    func scaledFont(for size: DynamicTypeSize) -> Font {
        let manager = DynamicTypeSupportManager.shared
        let scaleFactor = manager.getScaleFactor()
        
        // Apply additional scaling based on target size
        let targetScaleFactor: CGFloat
        switch size {
        case .xSmall:
            targetScaleFactor = 0.8
        case .small:
            targetScaleFactor = 0.9
        case .medium:
            targetScaleFactor = 1.0
        case .large:
            targetScaleFactor = 1.1
        case .xLarge:
            targetScaleFactor = 1.2
        case .xxLarge:
            targetScaleFactor = 1.3
        case .xxxLarge:
            targetScaleFactor = 1.4
        case .accessibility1:
            targetScaleFactor = 1.5
        case .accessibility2:
            targetScaleFactor = 1.7
        case .accessibility3:
            targetScaleFactor = 1.9
        case .accessibility4:
            targetScaleFactor = 2.1
        case .accessibility5:
            targetScaleFactor = 2.3
        @unknown default:
            targetScaleFactor = 1.0
        }
        
        return self.size(self.size * targetScaleFactor)
    }
}

// MARK: - Dynamic Type Testing Utilities
public extension DynamicTypeSupportManager {
    
    /// Test Dynamic Type scaling
    func testDynamicTypeScaling(baseSize: CGFloat) -> CGFloat {
        return getRecommendedFontSize(baseSize: baseSize)
    }
    
    /// Test readability at current size
    func testReadability() -> (readable: Bool, comfortable: Bool) {
        return (isTextSizeReadable(), isTextSizeComfortable())
    }
    
    /// Get current size description
    func getCurrentSizeDescription() -> String {
        return preferredTextSize.accessibilityDescription
    }
    
    /// Check if current size requires special handling
    func requiresSpecialHandling() -> Bool {
        return preferredTextSize.isAccessibilitySize
    }
}

// MARK: - Dynamic Type Configuration
public extension DynamicTypeSupportManager {
    
    /// Configure Dynamic Type settings
    func configureDynamicTypeSettings(
        minimumReadableSize: DynamicTypeSize = .medium,
        maximumComfortableSize: DynamicTypeSize = .accessibility3
    ) {
        self.minimumReadableSize = minimumReadableSize
        self.maximumComfortableSize = maximumComfortableSize
    }
    
    /// Reset Dynamic Type settings to defaults
    func resetDynamicTypeSettings() {
        configureDynamicTypeSettings()
    }
} 
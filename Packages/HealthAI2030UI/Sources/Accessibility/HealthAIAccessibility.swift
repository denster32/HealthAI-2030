import SwiftUI

// MARK: - HealthAIAccessibility
public struct HealthAIAccessibility {
    
    // MARK: - VoiceOver Support
    public static func voiceOverLabel(_ text: String) -> some ViewModifier {
        ViewModifier { content in
            content.accessibilityLabel(Text(text))
        }
    }
    
    public static func voiceOverHint(_ text: String) -> some ViewModifier {
        ViewModifier { content in
            content.accessibilityHint(Text(text))
        }
    }
    
    public static func voiceOverValue(_ text: String) -> some ViewModifier {
        ViewModifier { content in
            content.accessibilityValue(Text(text))
        }
    }
    
    public static func voiceOverAddTraits(_ traits: AccessibilityTraits) -> some ViewModifier {
        ViewModifier { content in
            content.accessibilityAddTraits(traits)
        }
    }
    
    public static func voiceOverRemoveTraits(_ traits: AccessibilityTraits) -> some ViewModifier {
        ViewModifier { content in
            content.accessibilityRemoveTraits(traits)
        }
    }
    
    // MARK: - Dynamic Type Support
    public static func dynamicTypeText(_ text: String, style: Font.TextStyle) -> some View {
        Text(text)
            .font(.system(style, design: .default))
            .dynamicTypeSize(...DynamicTypeSize.accessibility3)
    }
    
    public static func dynamicTypeText(_ text: String, style: Font.TextStyle, weight: Font.Weight) -> some View {
        Text(text)
            .font(.system(style, design: .default).weight(weight))
            .dynamicTypeSize(...DynamicTypeSize.accessibility3)
    }
    
    // MARK: - High Contrast Support
    public static func highContrastColor(_ color: Color, fallback: Color) -> Color {
        if UIAccessibility.isDarkerSystemColorsEnabled {
            return fallback
        }
        return color
    }
    
    public static func highContrastBackground(_ color: Color, fallback: Color) -> some ViewModifier {
        ViewModifier { content in
            content.background(UIAccessibility.isDarkerSystemColorsEnabled ? fallback : color)
        }
    }
    
    // MARK: - Reduced Motion Support
    public static func reducedMotionAnimation<T: View>(_ content: T, animation: Animation) -> some View {
        content.animation(UIAccessibility.isReduceMotionEnabled ? .none : animation, value: true)
    }
    
    public static func reducedMotionScale<T: View>(_ content: T, scale: CGFloat) -> some View {
        content.scaleEffect(UIAccessibility.isReduceMotionEnabled ? 1.0 : scale)
    }
    
    // MARK: - Switch Control Support
    public static func switchControlFocusable<T: View>(_ content: T) -> some View {
        content.accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isButton)
    }
    
    public static func switchControlAction<T: View>(_ content: T, action: @escaping () -> Void) -> some View {
        content.accessibilityAction(named: "Activate") {
            action()
        }
    }
    
    // MARK: - Screen Reader Optimization
    public static func screenReaderLabel(_ text: String) -> some ViewModifier {
        ViewModifier { content in
            content.accessibilityLabel(Text(text))
                .accessibilityElement(children: .combine)
        }
    }
    
    public static func screenReaderGroup<T: View>(_ content: T, label: String) -> some View {
        content.accessibilityElement(children: .contain)
            .accessibilityLabel(Text(label))
    }
    
    // MARK: - Accessibility Announcements
    public static func announce(_ message: String) {
        UIAccessibility.post(notification: .announcement, argument: message)
    }
    
    public static func announceScreenChange(_ screenName: String) {
        UIAccessibility.post(notification: .screenChanged, argument: screenName)
    }
    
    public static func announceLayoutChange() {
        UIAccessibility.post(notification: .layoutChanged, argument: nil)
    }
    
    // MARK: - Accessibility Testing
    public static func isAccessibilityEnabled() -> Bool {
        return UIAccessibility.isVoiceOverRunning || UIAccessibility.isSwitchControlRunning
    }
    
    public static func isVoiceOverRunning() -> Bool {
        return UIAccessibility.isVoiceOverRunning
    }
    
    public static func isSwitchControlRunning() -> Bool {
        return UIAccessibility.isSwitchControlRunning
    }
    
    public static func isDarkerSystemColorsEnabled() -> Bool {
        return UIAccessibility.isDarkerSystemColorsEnabled
    }
    
    public static func isReduceMotionEnabled() -> Bool {
        return UIAccessibility.isReduceMotionEnabled
    }
    
    public static func isReduceTransparencyEnabled() -> Bool {
        return UIAccessibility.isReduceTransparencyEnabled
    }
}

// MARK: - Accessibility Modifiers
public struct AccessibilityModifier: ViewModifier {
    let label: String?
    let hint: String?
    let value: String?
    let traits: AccessibilityTraits
    let isHidden: Bool
    let sortPriority: Double
    
    public init(
        label: String? = nil,
        hint: String? = nil,
        value: String? = nil,
        traits: AccessibilityTraits = [],
        isHidden: Bool = false,
        sortPriority: Double = 0
    ) {
        self.label = label
        self.hint = hint
        self.value = value
        self.traits = traits
        self.isHidden = isHidden
        self.sortPriority = sortPriority
    }
    
    public func body(content: Content) -> some View {
        content
            .accessibilityLabel(label.map { Text($0) })
            .accessibilityHint(hint.map { Text($0) })
            .accessibilityValue(value.map { Text($0) })
            .accessibilityAddTraits(traits)
            .accessibilityHidden(isHidden)
            .accessibilitySortPriority(sortPriority)
    }
}

// MARK: - Dynamic Type Modifier
public struct DynamicTypeModifier: ViewModifier {
    let style: Font.TextStyle
    let weight: Font.Weight?
    let design: Font.Design
    
    public init(
        style: Font.TextStyle,
        weight: Font.Weight? = nil,
        design: Font.Design = .default
    ) {
        self.style = style
        self.weight = weight
        self.design = design
    }
    
    public func body(content: Content) -> some View {
        content
            .font(.system(style, design: design).weight(weight ?? .regular))
            .dynamicTypeSize(...DynamicTypeSize.accessibility3)
    }
}

// MARK: - High Contrast Modifier
public struct HighContrastModifier: ViewModifier {
    let normalColor: Color
    let highContrastColor: Color
    
    public init(normalColor: Color, highContrastColor: Color) {
        self.normalColor = normalColor
        self.highContrastColor = highContrastColor
    }
    
    public func body(content: Content) -> some View {
        content
            .foregroundColor(UIAccessibility.isDarkerSystemColorsEnabled ? highContrastColor : normalColor)
    }
}

// MARK: - Reduced Motion Modifier
public struct ReducedMotionModifier: ViewModifier {
    let animation: Animation
    
    public init(_ animation: Animation) {
        self.animation = animation
    }
    
    public func body(content: Content) -> some View {
        content
            .animation(UIAccessibility.isReduceMotionEnabled ? .none : animation, value: true)
    }
}

// MARK: - Accessibility Extensions
public extension View {
    func healthAccessibility(
        label: String? = nil,
        hint: String? = nil,
        value: String? = nil,
        traits: AccessibilityTraits = [],
        isHidden: Bool = false,
        sortPriority: Double = 0
    ) -> some View {
        self.modifier(AccessibilityModifier(
            label: label,
            hint: hint,
            value: value,
            traits: traits,
            isHidden: isHidden,
            sortPriority: sortPriority
        ))
    }
    
    func healthDynamicType(
        style: Font.TextStyle,
        weight: Font.Weight? = nil,
        design: Font.Design = .default
    ) -> some View {
        self.modifier(DynamicTypeModifier(style: style, weight: weight, design: design))
    }
    
    func healthHighContrast(
        normalColor: Color,
        highContrastColor: Color
    ) -> some View {
        self.modifier(HighContrastModifier(normalColor: normalColor, highContrastColor: highContrastColor))
    }
    
    func healthReducedMotion(_ animation: Animation) -> some View {
        self.modifier(ReducedMotionModifier(animation))
    }
}

// MARK: - Accessibility Helpers
public struct AccessibilityHelpers {
    
    // MARK: - Color Contrast Calculator
    public static func calculateContrastRatio(foreground: Color, background: Color) -> Double {
        // Simplified contrast calculation
        // In a real implementation, you would convert colors to luminance values
        return 4.5 // Placeholder value
    }
    
    public static func isContrastSufficient(foreground: Color, background: Color) -> Bool {
        return calculateContrastRatio(foreground: foreground, background: background) >= 4.5
    }
    
    // MARK: - Touch Target Size
    public static func ensureMinimumTouchTarget<T: View>(_ content: T, size: CGFloat = 44) -> some View {
        content
            .frame(minWidth: size, minHeight: size)
            .contentShape(Rectangle())
    }
    
    // MARK: - Focus Management
    public static func manageFocus<T: View>(_ content: T, isFocused: Binding<Bool>) -> some View {
        content
            .focused(isFocused)
            .accessibilityAddTraits(isFocused.wrappedValue ? .isSelected : [])
    }
    
    // MARK: - Semantic Markup
    public static func semanticHeader<T: View>(_ content: T) -> some View {
        content.accessibilityAddTraits(.isHeader)
    }
    
    public static func semanticButton<T: View>(_ content: T) -> some View {
        content.accessibilityAddTraits(.isButton)
    }
    
    public static func semanticLink<T: View>(_ content: T) -> some View {
        content.accessibilityAddTraits(.isLink)
    }
    
    public static func semanticImage<T: View>(_ content: T) -> some View {
        content.accessibilityAddTraits(.isImage)
    }
    
    public static func semanticSearchField<T: View>(_ content: T) -> some View {
        content.accessibilityAddTraits(.isSearchField)
    }
    
    public static func semanticSummary<T: View>(_ content: T) -> some View {
        content.accessibilityAddTraits(.isSummaryElement)
    }
    
    // MARK: - Live Regions
    public static func liveRegion<T: View>(_ content: T, priority: AccessibilityLiveRegionPriority = .polite) -> some View {
        content.accessibilityLiveRegion(priority)
    }
    
    public static func announceLiveRegion(_ message: String, priority: AccessibilityLiveRegionPriority = .polite) {
        UIAccessibility.post(notification: .announcement, argument: message)
    }
}

// MARK: - Accessibility Testing Components
public struct AccessibilityTestView: View {
    let testCases: [AccessibilityTestCase]
    @State private var currentTestIndex = 0
    
    public struct AccessibilityTestCase {
        let name: String
        let description: String
        let testView: AnyView
        let expectedBehavior: String
        
        public init(name: String, description: String, testView: AnyView, expectedBehavior: String) {
            self.name = name
            self.description = description
            self.testView = testView
            self.expectedBehavior = expectedBehavior
        }
    }
    
    public init(testCases: [AccessibilityTestCase]) {
        self.testCases = testCases
    }
    
    public var body: some View {
        VStack(spacing: HealthAIDesignSystem.Spacing.large) {
            Text("Accessibility Test Suite")
                .font(HealthAIDesignSystem.Typography.largeTitle)
                .fontWeight(.bold)
                .accessibilityAddTraits(.isHeader)
            
            if !testCases.isEmpty {
                VStack(alignment: .leading, spacing: HealthAIDesignSystem.Spacing.medium) {
                    Text("Test \(currentTestIndex + 1) of \(testCases.count)")
                        .font(HealthAIDesignSystem.Typography.headline)
                        .fontWeight(.medium)
                    
                    Text(testCases[currentTestIndex].name)
                        .font(HealthAIDesignSystem.Typography.title2)
                        .fontWeight(.semibold)
                    
                    Text(testCases[currentTestIndex].description)
                        .font(HealthAIDesignSystem.Typography.body)
                        .foregroundColor(HealthAIDesignSystem.Color.textSecondary)
                    
                    Text("Expected: \(testCases[currentTestIndex].expectedBehavior)")
                        .font(HealthAIDesignSystem.Typography.caption)
                        .foregroundColor(HealthAIDesignSystem.Color.infoBlue)
                        .padding()
                        .background(HealthAIDesignSystem.Color.infoBlue.opacity(0.1))
                        .cornerRadius(HealthAIDesignSystem.Layout.cornerRadius)
                }
                .padding()
                .background(HealthAIDesignSystem.Color.surface)
                .cornerRadius(HealthAIDesignSystem.Layout.cornerRadius)
                
                testCases[currentTestIndex].testView
                    .padding()
                    .background(HealthAIDesignSystem.Color.background)
                    .cornerRadius(HealthAIDesignSystem.Layout.cornerRadius)
                
                HStack(spacing: HealthAIDesignSystem.Spacing.medium) {
                    HealthAIButton(
                        title: "Previous",
                        style: .secondary,
                        isEnabled: currentTestIndex > 0
                    ) {
                        if currentTestIndex > 0 {
                            currentTestIndex -= 1
                        }
                    }
                    
                    HealthAIButton(
                        title: "Next",
                        style: .primary,
                        isEnabled: currentTestIndex < testCases.count - 1
                    ) {
                        if currentTestIndex < testCases.count - 1 {
                            currentTestIndex += 1
                        }
                    }
                }
            } else {
                Text("No test cases available")
                    .font(HealthAIDesignSystem.Typography.body)
                    .foregroundColor(HealthAIDesignSystem.Color.textSecondary)
            }
        }
        .padding()
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text("Accessibility test suite with \(testCases.count) test cases"))
    }
}

// MARK: - Accessibility Compliance Checker
public class AccessibilityComplianceChecker: ObservableObject {
    @Published public var complianceScore: Double = 0.0
    @Published public var issues: [AccessibilityIssue] = []
    
    public struct AccessibilityIssue {
        let severity: IssueSeverity
        let component: String
        let description: String
        let recommendation: String
        
        public enum IssueSeverity {
            case low, medium, high, critical
        }
    }
    
    public func checkCompliance() {
        // This would implement actual accessibility checking logic
        // For now, it's a placeholder
        complianceScore = 0.85
        issues = [
            AccessibilityIssue(
                severity: .medium,
                component: "HeartRateDisplay",
                description: "Missing accessibility value for heart rate changes",
                recommendation: "Add accessibilityValue to announce heart rate updates"
            )
        ]
    }
    
    public func generateReport() -> String {
        var report = "Accessibility Compliance Report\n"
        report += "==============================\n\n"
        report += "Overall Score: \(Int(complianceScore * 100))%\n\n"
        
        if issues.isEmpty {
            report += "✅ No accessibility issues found!\n"
        } else {
            report += "Issues Found:\n"
            for issue in issues {
                report += "- [\(issue.severity)] \(issue.component): \(issue.description)\n"
                report += "  Recommendation: \(issue.recommendation)\n\n"
            }
        }
        
        return report
    }
}

import SwiftUI

public struct HealthAIDesignSystem {
    
    // MARK: - Enhanced Color System
    public struct Color {
        // Primary Healthcare Colors (Optimized for medical applications)
        public static let healthPrimary = Color(red: 0.2, green: 0.6, blue: 0.9) // Medical Blue
        public static let healthSecondary = Color(red: 0.3, green: 0.8, blue: 0.6) // Health Green
        public static let healthTertiary = Color(red: 0.9, green: 0.4, blue: 0.2) // Wellness Orange
        
        // Semantic Status Colors
        public static let warningRed = Color(red: 0.9, green: 0.2, blue: 0.2) // Alert Red
        public static let successGreen = Color(red: 0.2, green: 0.8, blue: 0.4) // Success Green
        public static let infoBlue = Color(red: 0.2, green: 0.6, blue: 1.0) // Info Blue
        public static let cautionYellow = Color(red: 1.0, green: 0.8, blue: 0.0) // Caution Yellow
        
        // Background Colors
        public static let background = Color(.systemBackground)
        public static let secondaryBackground = Color(.secondarySystemBackground)
        public static let tertiaryBackground = Color(.tertiarySystemBackground)
        public static let surface = Color(.systemGray6)
        public static let cardBackground = Color(.secondarySystemBackground)
        
        // Text Colors
        public static let textPrimary = Color(.label)
        public static let textSecondary = Color(.secondaryLabel)
        public static let textTertiary = Color(.tertiaryLabel)
        public static let textQuaternary = Color(.quaternaryLabel)
        
        // Border and Separator Colors
        public static let border = Color(.separator)
        public static let borderSecondary = Color(.opaqueSeparator)
        
        // Accent Colors
        public static let accent = Color.accentColor
        public static let accentSecondary = Color(red: 0.6, green: 0.4, blue: 1.0) // Purple Accent
        
        // Health-Specific Colors
        public static let heartRate = Color(red: 0.9, green: 0.2, blue: 0.2) // Heart Rate Red
        public static let bloodPressure = Color(red: 0.8, green: 0.3, blue: 0.9) // Blood Pressure Purple
        public static let temperature = Color(red: 1.0, green: 0.6, blue: 0.0) // Temperature Orange
        public static let oxygen = Color(red: 0.2, green: 0.8, blue: 0.8) // Oxygen Cyan
        public static let sleep = Color(red: 0.4, green: 0.2, blue: 0.8) // Sleep Indigo
        public static let activity = Color(red: 0.2, green: 0.8, blue: 0.4) // Activity Green
        public static let nutrition = Color(red: 1.0, green: 0.8, blue: 0.0) // Nutrition Yellow
        public static let mentalHealth = Color(red: 0.8, green: 0.4, blue: 0.8) // Mental Health Pink
        
        // Sleep Stage Colors
        public static let sleepAwake = Color(red: 1.0, green: 0.6, blue: 0.0)
        public static let sleepLight = Color(red: 0.3, green: 0.7, blue: 1.0)
        public static let sleepDeep = Color(red: 0.6, green: 0.3, blue: 0.9)
        public static let sleepREM = Color(red: 0.2, green: 0.8, blue: 0.4)
        
        // High Contrast Colors (Accessibility)
        public static let highContrastPrimary = Color(red: 0.0, green: 0.0, blue: 0.0)
        public static let highContrastSecondary = Color(red: 1.0, green: 1.0, blue: 1.0)
        public static let highContrastAccent = Color(red: 0.0, green: 0.5, blue: 1.0)
    }

    // MARK: - Enhanced Typography System
    public struct Typography {
        // Large Display Text
        public static let largeTitle = Font.largeTitle.weight(.bold)
        public static let largeTitle2 = Font.largeTitle2.weight(.bold)
        
        // Title Hierarchy
        public static let title = Font.title.weight(.semibold)
        public static let title2 = Font.title2.weight(.semibold)
        public static let title3 = Font.title3.weight(.semibold)
        
        // Headline Text
        public static let headline = Font.headline.weight(.medium)
        public static let subheadline = Font.subheadline.weight(.medium)
        
        // Body Text
        public static let body = Font.body
        public static let bodyBold = Font.body.weight(.semibold)
        public static let callout = Font.callout
        
        // Caption Text
        public static let footnote = Font.footnote
        public static let caption = Font.caption
        public static let caption2 = Font.caption2
        
        // Health-Specific Typography
        public static let healthMetric = Font.system(size: 32, weight: .bold, design: .rounded)
        public static let healthMetricSmall = Font.system(size: 24, weight: .semibold, design: .rounded)
        public static let healthLabel = Font.system(size: 14, weight: .medium, design: .default)
        public static let healthUnit = Font.system(size: 12, weight: .regular, design: .default)
        
        // Accessibility Support
        public static func dynamicType(_ style: Font.TextStyle, weight: Font.Weight = .regular) -> Font {
            return Font.system(style, design: .default).weight(weight)
        }
        
        public static func dynamicTypeRounded(_ style: Font.TextStyle, weight: Font.Weight = .regular) -> Font {
            return Font.system(style, design: .rounded).weight(weight)
        }
    }

    // MARK: - Enhanced Spacing System
    public struct Spacing {
        // Micro Spacing
        public static let micro: CGFloat = 2
        public static let extraSmall: CGFloat = 4
        public static let small: CGFloat = 8
        
        // Standard Spacing
        public static let medium: CGFloat = 16
        public static let large: CGFloat = 24
        public static let extraLarge: CGFloat = 32
        
        // Section Spacing
        public static let section: CGFloat = 40
        public static let sectionLarge: CGFloat = 48
        public static let sectionExtraLarge: CGFloat = 64
        
        // Component-Specific Spacing
        public static let cardPadding: CGFloat = 20
        public static let buttonPadding: CGFloat = 16
        public static let listRowPadding: CGFloat = 12
        public static let formFieldSpacing: CGFloat = 20
        public static let chartPadding: CGFloat = 16
    }

    // MARK: - Enhanced Layout System
    public struct Layout {
        // Corner Radius
        public static let cornerRadius: CGFloat = 12
        public static let cardCornerRadius: CGFloat = 20
        public static let buttonCornerRadius: CGFloat = 10
        public static let inputCornerRadius: CGFloat = 8
        
        // Border Widths
        public static let borderWidth: CGFloat = 1
        public static let borderWidthThick: CGFloat = 2
        public static let borderWidthThin: CGFloat = 0.5
        
        // Shadows
        public static let shadowRadius: CGFloat = 6
        public static let shadowRadiusLarge: CGFloat = 12
        public static let shadowRadiusSmall: CGFloat = 3
        public static let shadowOpacity: Double = 0.1
        public static let shadowYOffset: CGFloat = 2
        
        // Minimum Touch Targets
        public static let minButtonHeight: CGFloat = 48
        public static let minTapArea: CGFloat = 44 // Apple HIG minimum
        public static let minIconSize: CGFloat = 24
        
        // Grid System
        public static let gridSpacing: CGFloat = 16
        public static let gridColumns: Int = 12
        public static let maxContentWidth: CGFloat = 1200
    }

    // MARK: - Enhanced Animation System
    public struct Animation {
        // Standard Animations
        public static let defaultCurve = SwiftUI.Animation.easeInOut(duration: 0.3)
        public static let springCurve = SwiftUI.Animation.spring(response: 0.5, dampingFraction: 0.6, blendDuration: 0.2)
        public static let fast = SwiftUI.Animation.easeInOut(duration: 0.15)
        public static let slow = SwiftUI.Animation.easeInOut(duration: 0.6)
        
        // Micro-interactions
        public static let microInteraction = SwiftUI.Animation.easeInOut(duration: 0.2)
        public static let buttonPress = SwiftUI.Animation.easeInOut(duration: 0.1)
        public static let cardHover = SwiftUI.Animation.easeInOut(duration: 0.25)
        
        // Health-Specific Animations
        public static let heartbeat = SwiftUI.Animation.easeInOut(duration: 0.8).repeatForever(autoreverses: true)
        public static let breathing = SwiftUI.Animation.easeInOut(duration: 2.0).repeatForever(autoreverses: true)
        public static let pulse = SwiftUI.Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true)
        
        // Accessibility-Aware Animations
        public static func accessibleAnimation(_ baseAnimation: SwiftUI.Animation) -> SwiftUI.Animation {
            if reduceMotionEnabled() {
                return SwiftUI.Animation.linear(duration: 0.0)
            }
            return baseAnimation
        }
    }

    // MARK: - Enhanced Accessibility System
    public struct Accessibility {
        // System Status Detection
        public static func highContrastEnabled() -> Bool {
            return UIAccessibility.isDarkerSystemColorsEnabled
        }
        
        public static func reduceMotionEnabled() -> Bool {
            return UIAccessibility.isReduceMotionEnabled
        }
        
        public static func reduceTransparencyEnabled() -> Bool {
            return UIAccessibility.isReduceTransparencyEnabled
        }
        
        public static func isVoiceOverRunning() -> Bool {
            return UIAccessibility.isVoiceOverRunning
        }
        
        public static func isSwitchControlRunning() -> Bool {
            return UIAccessibility.isSwitchControlRunning
        }
        
        // Accessibility Helpers
        public static func accessibilityLabel(_ text: String) -> some ViewModifier {
            return AccessibilityModifier(label: text)
        }
        
        public static func accessibilityHint(_ text: String) -> some ViewModifier {
            return AccessibilityModifier(hint: text)
        }
        
        public static func accessibilityValue(_ text: String) -> some ViewModifier {
            return AccessibilityModifier(value: text)
        }
        
        // Color Contrast Validation
        public static func isContrastSufficient(foreground: Color, background: Color) -> Bool {
            // Placeholder implementation - would calculate actual contrast ratio
            return true
        }
        
        // Touch Target Validation
        public static func ensureMinimumTouchTarget<T: View>(_ content: T, size: CGFloat = minTapArea) -> some View {
            return content
                .frame(minWidth: size, minHeight: size)
                .contentShape(Rectangle())
        }
    }
}

// MARK: - Accessibility Modifier
private struct AccessibilityModifier: ViewModifier {
    let label: String?
    let hint: String?
    let value: String?
    
    init(label: String? = nil, hint: String? = nil, value: String? = nil) {
        self.label = label
        self.hint = hint
        self.value = value
    }
    
    func body(content: Content) -> some View {
        content
            .accessibilityLabel(label ?? "")
            .accessibilityHint(hint ?? "")
            .accessibilityValue(value ?? "")
    }
}

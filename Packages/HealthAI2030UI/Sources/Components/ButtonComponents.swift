import SwiftUI

// MARK: - Button Style Enum
public enum HealthAIButtonStyle {
    case primary
    case secondary
    case tertiary
    case danger
    case success
    case warning
    case info
    case healthMetric
    case medical
}

// MARK: - Button Size Enum
public enum HealthAIButtonSize {
    case small
    case medium
    case large
    case extraLarge
    
    var height: CGFloat {
        switch self {
        case .small: return 32
        case .medium: return 44
        case .large: return 56
        case .extraLarge: return 64
        }
    }
    
    var fontSize: Font {
        switch self {
        case .small: return .caption
        case .medium: return .body
        case .large: return .headline
        case .extraLarge: return .title3
        }
    }
    
    var padding: CGFloat {
        switch self {
        case .small: return 8
        case .medium: return 12
        case .large: return 16
        case .extraLarge: return 20
        }
    }
}

// MARK: - Main HealthAI Button Component
public struct HealthAIButton: View {
    let title: String
    let style: HealthAIButtonStyle
    let size: HealthAIButtonSize
    let icon: String?
    let isLoading: Bool
    let isEnabled: Bool
    let action: () -> Void
    
    public init(
        title: String,
        style: HealthAIButtonStyle = .primary,
        size: HealthAIButtonSize = .medium,
        icon: String? = nil,
        isLoading: Bool = false,
        isEnabled: Bool = true,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.style = style
        self.size = size
        self.icon = icon
        self.isLoading = isLoading
        self.isEnabled = isEnabled
        self.action = action
    }
    
    public var body: some View {
        Button(action: action) {
            HStack(spacing: SpacingGrid.small) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: textColor))
                        .scaleEffect(0.8)
                } else if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: size.fontSize.size * 0.8))
                }
                
                Text(title)
                    .font(size.fontSize.weight(.semibold))
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, minHeight: size.height)
            .padding(.horizontal, size.padding)
        }
        .background(backgroundColor)
        .foregroundColor(textColor)
        .cornerRadius(SpacingGrid.small)
        .overlay(
            RoundedRectangle(cornerRadius: SpacingGrid.small)
                .stroke(borderColor, lineWidth: borderWidth)
        )
        .disabled(!isEnabled || isLoading)
        .opacity(isEnabled ? 1.0 : 0.6)
        .scaleEffect(isLoading ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isLoading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(accessibilityLabel))
        .accessibilityHint(Text(accessibilityHint))
        .accessibilityAddTraits(isLoading ? [] : .isButton)
    }
    
    // MARK: - Style Properties
    private var backgroundColor: Color {
        if !isEnabled { return ColorPalette.surface }
        
        switch style {
        case .primary:
            return ColorPalette.primary
        case .secondary:
            return Color.clear
        case .tertiary:
            return Color.clear
        case .danger:
            return ColorPalette.critical
        case .success:
            return ColorPalette.success
        case .warning:
            return ColorPalette.warning
        case .info:
            return ColorPalette.info
        case .healthMetric:
            return ColorPalette.healthPrimary
        case .medical:
            return ColorPalette.healthSecondary
        }
    }
    
    private var textColor: Color {
        if !isEnabled { return ColorPalette.textSecondary }
        
        switch style {
        case .primary, .danger, .success, .warning, .info, .healthMetric, .medical:
            return .white
        case .secondary, .tertiary:
            return ColorPalette.primary
        }
    }
    
    private var borderColor: Color {
        if !isEnabled { return ColorPalette.border }
        
        switch style {
        case .primary, .danger, .success, .warning, .info, .healthMetric, .medical:
            return Color.clear
        case .secondary:
            return ColorPalette.primary
        case .tertiary:
            return Color.clear
        }
    }
    
    private var borderWidth: CGFloat {
        switch style {
        case .secondary:
            return 1.5
        default:
            return 0
        }
    }
    
    // MARK: - Accessibility Properties
    private var accessibilityLabel: String {
        if isLoading {
            return "Loading \(title.lowercased())"
        }
        return title
    }
    
    private var accessibilityHint: String {
        if isLoading {
            return "Button is loading, please wait"
        }
        if !isEnabled {
            return "Button is disabled"
        }
        return "Double tap to activate"
    }
}

// MARK: - Icon Button Component
public struct HealthAIIconButton: View {
    let icon: String
    let style: HealthAIButtonStyle
    let size: HealthAIButtonSize
    let isLoading: Bool
    let isEnabled: Bool
    let action: () -> Void
    
    public init(
        icon: String,
        style: HealthAIButtonStyle = .primary,
        size: HealthAIButtonSize = .medium,
        isLoading: Bool = false,
        isEnabled: Bool = true,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.style = style
        self.size = size
        self.isLoading = isLoading
        self.isEnabled = isEnabled
        self.action = action
    }
    
    public var body: some View {
        Button(action: action) {
            ZStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: textColor))
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: icon)
                        .font(.system(size: size.fontSize.size * 0.8))
                }
            }
            .frame(width: size.height, height: size.height)
        }
        .background(backgroundColor)
        .foregroundColor(textColor)
        .cornerRadius(SpacingGrid.small)
        .overlay(
            RoundedRectangle(cornerRadius: SpacingGrid.small)
                .stroke(borderColor, lineWidth: borderWidth)
        )
        .disabled(!isEnabled || isLoading)
        .opacity(isEnabled ? 1.0 : 0.6)
        .scaleEffect(isLoading ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isLoading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(accessibilityLabel))
        .accessibilityHint(Text(accessibilityHint))
        .accessibilityAddTraits(isLoading ? [] : .isButton)
    }
    
    // MARK: - Style Properties (same as HealthAIButton)
    private var backgroundColor: Color {
        if !isEnabled { return ColorPalette.surface }
        
        switch style {
        case .primary:
            return ColorPalette.primary
        case .secondary:
            return Color.clear
        case .tertiary:
            return Color.clear
        case .danger:
            return ColorPalette.critical
        case .success:
            return ColorPalette.success
        case .warning:
            return ColorPalette.warning
        case .info:
            return ColorPalette.info
        case .healthMetric:
            return ColorPalette.healthPrimary
        case .medical:
            return ColorPalette.healthSecondary
        }
    }
    
    private var textColor: Color {
        if !isEnabled { return ColorPalette.textSecondary }
        
        switch style {
        case .primary, .danger, .success, .warning, .info, .healthMetric, .medical:
            return .white
        case .secondary, .tertiary:
            return ColorPalette.primary
        }
    }
    
    private var borderColor: Color {
        if !isEnabled { return ColorPalette.border }
        
        switch style {
        case .primary, .danger, .success, .warning, .info, .healthMetric, .medical:
            return Color.clear
        case .secondary:
            return ColorPalette.primary
        case .tertiary:
            return Color.clear
        }
    }
    
    private var borderWidth: CGFloat {
        switch style {
        case .secondary:
            return 1.5
        default:
            return 0
        }
    }
    
    // MARK: - Accessibility Properties
    private var accessibilityLabel: String {
        if isLoading {
            return "Loading icon button"
        }
        return "\(icon) button"
    }
    
    private var accessibilityHint: String {
        if isLoading {
            return "Button is loading, please wait"
        }
        if !isEnabled {
            return "Button is disabled"
        }
        return "Double tap to activate"
    }
}

// MARK: - Floating Action Button
public struct HealthAIFloatingActionButton: View {
    let icon: String
    let style: HealthAIButtonStyle
    let size: HealthAIButtonSize
    let isLoading: Bool
    let isEnabled: Bool
    let action: () -> Void
    
    public init(
        icon: String,
        style: HealthAIButtonStyle = .primary,
        size: HealthAIButtonSize = .large,
        isLoading: Bool = false,
        isEnabled: Bool = true,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.style = style
        self.size = size
        self.isLoading = isLoading
        self.isEnabled = isEnabled
        self.action = action
    }
    
    public var body: some View {
        Button(action: action) {
            ZStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: icon)
                        .font(.system(size: size.fontSize.size * 0.8, weight: .semibold))
                }
            }
            .frame(width: size.height, height: size.height)
        }
        .background(ColorPalette.primary)
        .foregroundColor(.white)
        .clipShape(Circle())
        .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
        .disabled(!isEnabled || isLoading)
        .opacity(isEnabled ? 1.0 : 0.6)
        .scaleEffect(isLoading ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isLoading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(accessibilityLabel))
        .accessibilityHint(Text(accessibilityHint))
        .accessibilityAddTraits(isLoading ? [] : .isButton)
    }
    
    // MARK: - Accessibility Properties
    private var accessibilityLabel: String {
        if isLoading {
            return "Loading floating action button"
        }
        return "\(icon) floating action button"
    }
    
    private var accessibilityHint: String {
        if isLoading {
            return "Button is loading, please wait"
        }
        if !isEnabled {
            return "Button is disabled"
        }
        return "Double tap to activate"
    }
}

// MARK: - Health-Specific Button Components

/// Button specifically designed for health metric actions
public struct HealthMetricButton: View {
    let title: String
    let metricType: HealthMetricType
    let value: String?
    let isLoading: Bool
    let isEnabled: Bool
    let action: () -> Void
    
    public init(
        title: String,
        metricType: HealthMetricType,
        value: String? = nil,
        isLoading: Bool = false,
        isEnabled: Bool = true,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.metricType = metricType
        self.value = value
        self.isLoading = isLoading
        self.isEnabled = isEnabled
        self.action = action
    }
    
    public var body: some View {
        Button(action: action) {
            VStack(spacing: SpacingGrid.small) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    if let value = value {
                        Text(value)
                            .font(TypographySystem.healthMetricSmall)
                            .fontWeight(.bold)
                    }
                    
                    Text(title)
                        .font(TypographySystem.healthMetricLabel)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 80)
            .padding(SpacingGrid.medium)
        }
        .background(ColorPalette.forHealthMetric(metricType))
        .foregroundColor(.white)
        .cornerRadius(SpacingGrid.medium)
        .disabled(!isEnabled || isLoading)
        .opacity(isEnabled ? 1.0 : 0.6)
        .scaleEffect(isLoading ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isLoading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(accessibilityLabel))
        .accessibilityHint(Text(accessibilityHint))
        .accessibilityAddTraits(isLoading ? [] : .isButton)
    }
    
    // MARK: - Accessibility Properties
    private var accessibilityLabel: String {
        if isLoading {
            return "Loading \(title.lowercased())"
        }
        if let value = value {
            return "\(title): \(value)"
        }
        return title
    }
    
    private var accessibilityHint: String {
        if isLoading {
            return "Button is loading, please wait"
        }
        if !isEnabled {
            return "Button is disabled"
        }
        return "Double tap to view \(title.lowercased()) details"
    }
}

// MARK: - Medical Action Button
public struct MedicalActionButton: View {
    let title: String
    let icon: String
    let actionType: MedicalActionType
    let isLoading: Bool
    let isEnabled: Bool
    let action: () -> Void
    
    public init(
        title: String,
        icon: String,
        actionType: MedicalActionType,
        isLoading: Bool = false,
        isEnabled: Bool = true,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.actionType = actionType
        self.isLoading = isLoading
        self.isEnabled = isEnabled
        self.action = action
    }
    
    public var body: some View {
        Button(action: action) {
            HStack(spacing: SpacingGrid.small) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .semibold))
                }
                
                Text(title)
                    .font(TypographySystem.medicalLabel)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity, minHeight: 56)
            .padding(.horizontal, SpacingGrid.medium)
        }
        .background(backgroundColor)
        .foregroundColor(.white)
        .cornerRadius(SpacingGrid.medium)
        .disabled(!isEnabled || isLoading)
        .opacity(isEnabled ? 1.0 : 0.6)
        .scaleEffect(isLoading ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isLoading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(accessibilityLabel))
        .accessibilityHint(Text(accessibilityHint))
        .accessibilityAddTraits(isLoading ? [] : .isButton)
    }
    
    // MARK: - Style Properties
    private var backgroundColor: Color {
        switch actionType {
        case .emergency:
            return ColorPalette.critical
        case .urgent:
            return ColorPalette.warning
        case .routine:
            return ColorPalette.healthPrimary
        case .preventive:
            return ColorPalette.success
        case .informational:
            return ColorPalette.info
        }
    }
    
    // MARK: - Accessibility Properties
    private var accessibilityLabel: String {
        if isLoading {
            return "Loading \(title.lowercased())"
        }
        return "\(actionType.rawValue) action: \(title)"
    }
    
    private var accessibilityHint: String {
        if isLoading {
            return "Button is loading, please wait"
        }
        if !isEnabled {
            return "Button is disabled"
        }
        return "Double tap to perform \(actionType.rawValue) action"
    }
}

// MARK: - Supporting Enums

/// Health metric types for button styling
public enum HealthMetricType {
    case heartRate
    case bloodPressure
    case temperature
    case oxygen
    case sleep
    case activity
    case nutrition
    case mentalHealth
}

/// Medical action types for button styling
public enum MedicalActionType: String {
    case emergency = "Emergency"
    case urgent = "Urgent"
    case routine = "Routine"
    case preventive = "Preventive"
    case informational = "Informational"
}

// MARK: - Button Extensions

extension View {
    /// Apply button press animation
    public func buttonPressAnimation() -> some View {
        self.scaleEffect(0.98)
            .animation(.easeInOut(duration: 0.1), value: true)
    }
    
    /// Apply button hover effect (for macOS)
    public func buttonHoverEffect() -> some View {
        self.scaleEffect(1.02)
            .animation(.easeInOut(duration: 0.2), value: true)
    }
} 
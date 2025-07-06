import SwiftUI

// MARK: - HealthAIButton
public struct HealthAIButton: View {
    public enum Style { case primary, secondary, tertiary }
    
    let title: String
    let style: Style
    let action: () -> Void
    let isEnabled: Bool
    let isLoading: Bool

    public init(title: String, style: Style = .primary, isEnabled: Bool = true, isLoading: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.style = style
        self.isEnabled = isEnabled
        self.isLoading = isLoading
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: buttonTextColor))
                        .scaleEffect(0.8)
                        .padding(.trailing, 8)
                }
                
                Text(title)
                    .font(HealthAIDesignSystem.Typography.headline)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity, minHeight: HealthAIDesignSystem.Layout.minButtonHeight)
        }
        .background(buttonBackgroundColor)
        .foregroundColor(buttonTextColor)
        .cornerRadius(HealthAIDesignSystem.Layout.cornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: HealthAIDesignSystem.Layout.cornerRadius)
                .stroke(buttonBorderColor, lineWidth: HealthAIDesignSystem.Layout.borderWidth)
        )
        .disabled(!isEnabled || isLoading)
        .opacity(isEnabled ? 1.0 : 0.6)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(title))
        .accessibilityHint(Text(accessibilityHint))
        .accessibilityAddTraits(isLoading ? .isButton : [])
    }
    
    private var buttonBackgroundColor: Color {
        if !isEnabled { return HealthAIDesignSystem.Color.surface }
        switch style {
        case .primary: return HealthAIDesignSystem.Color.healthPrimary
        case .secondary: return Color.clear
        case .tertiary: return Color.clear
        }
    }
    
    private var buttonTextColor: Color {
        if !isEnabled { return HealthAIDesignSystem.Color.textSecondary }
        switch style {
        case .primary: return .white
        case .secondary, .tertiary: return HealthAIDesignSystem.Color.healthPrimary
        }
    }
    
    private var buttonBorderColor: Color {
        if !isEnabled { return HealthAIDesignSystem.Color.border }
        switch style {
        case .primary: return Color.clear
        case .secondary: return HealthAIDesignSystem.Color.healthPrimary
        case .tertiary: return Color.clear
        }
    }
    
    private var accessibilityHint: String {
        if isLoading { return "Loading, please wait" }
        if !isEnabled { return "Button is disabled" }
        return "Double tap to activate"
    }
}

// MARK: - HealthAICard
public struct HealthAICard<Content: View>: View {
    let content: Content
    let padding: CGFloat
    let cornerRadius: CGFloat
    let shadowRadius: CGFloat
    let backgroundColor: Color

    public init(
        padding: CGFloat = HealthAIDesignSystem.Spacing.medium,
        cornerRadius: CGFloat = HealthAIDesignSystem.Layout.cardCornerRadius,
        shadowRadius: CGFloat = HealthAIDesignSystem.Layout.shadowRadius,
        backgroundColor: Color = HealthAIDesignSystem.Color.surface,
        @ViewBuilder content: () -> Content
    ) {
        self.padding = padding
        self.cornerRadius = cornerRadius
        self.shadowRadius = shadowRadius
        self.backgroundColor = backgroundColor
        self.content = content()
    }

    public var body: some View {
        content
            .padding(padding)
            .background(backgroundColor)
            .cornerRadius(cornerRadius)
            .shadow(color: Color.black.opacity(0.1), radius: shadowRadius, x: 0, y: 4)
            .accessibilityElement(children: .contain)
    }
}

// MARK: - HealthAIProgressView
public struct HealthAIProgressView: View {
    let progress: Double?
    let style: ProgressViewStyle
    let text: String?
    
    public init(progress: Double? = nil, style: ProgressViewStyle = .circular, text: String? = nil) {
        self.progress = progress
        self.style = style
        self.text = text
    }
    
    public var body: some View {
        VStack(spacing: HealthAIDesignSystem.Spacing.small) {
            if let progress = progress {
                ProgressView(value: progress)
                    .progressViewStyle(style)
                    .tint(HealthAIDesignSystem.Color.healthPrimary)
                    .accessibilityValue(Text("\(Int(progress * 100)) percent complete"))
            } else {
                ProgressView()
                    .progressViewStyle(style)
                    .tint(HealthAIDesignSystem.Color.healthPrimary)
            }
            
            if let text = text {
                Text(text)
                    .font(HealthAIDesignSystem.Typography.caption)
                    .foregroundColor(HealthAIDesignSystem.Color.textSecondary)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(text ?? "Loading"))
    }
}

// MARK: - HealthAITextField
public struct HealthAITextField: View {
    @Binding var text: String
    let placeholder: String
    let label: String?
    let errorMessage: String?
    let isSecure: Bool
    let keyboardType: UIKeyboardType
    let textContentType: UITextContentType?
    
    public init(
        text: Binding<String>,
        placeholder: String,
        label: String? = nil,
        errorMessage: String? = nil,
        isSecure: Bool = false,
        keyboardType: UIKeyboardType = .default,
        textContentType: UITextContentType? = nil
    ) {
        self._text = text
        self.placeholder = placeholder
        self.label = label
        self.errorMessage = errorMessage
        self.isSecure = isSecure
        self.keyboardType = keyboardType
        self.textContentType = textContentType
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: HealthAIDesignSystem.Spacing.small) {
            if let label = label {
                Text(label)
                    .font(HealthAIDesignSystem.Typography.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(HealthAIDesignSystem.Color.textPrimary)
            }
            
            Group {
                if isSecure {
                    SecureField(placeholder, text: $text)
                } else {
                    TextField(placeholder, text: $text)
                }
            }
            .padding()
            .background(HealthAIDesignSystem.Color.surface)
            .cornerRadius(HealthAIDesignSystem.Layout.cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: HealthAIDesignSystem.Layout.cornerRadius)
                    .stroke(borderColor, lineWidth: HealthAIDesignSystem.Layout.borderWidth)
            )
            .keyboardType(keyboardType)
            .textContentType(textContentType)
            .accessibilityLabel(Text(label ?? placeholder))
            .accessibilityHint(Text(accessibilityHint))
            
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .font(HealthAIDesignSystem.Typography.caption)
                    .foregroundColor(HealthAIDesignSystem.Color.warningRed)
                    .accessibilityLabel(Text("Error: \(errorMessage)"))
            }
        }
    }
    
    private var borderColor: Color {
        errorMessage != nil ? HealthAIDesignSystem.Color.warningRed : HealthAIDesignSystem.Color.border
    }
    
    private var accessibilityHint: String {
        if errorMessage != nil {
            return "Field has an error"
        }
        return "Enter \(placeholder.lowercased())"
    }
}

// MARK: - HealthAIPicker
public struct HealthAIPicker<Selection: Hashable, Content: View>: View {
    @Binding var selection: Selection
    let label: String
    let content: Content
    let errorMessage: String?
    
    public init(selection: Binding<Selection>, label: String, errorMessage: String? = nil, @ViewBuilder content: () -> Content) {
        self._selection = selection
        self.label = label
        self.errorMessage = errorMessage
        self.content = content()
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: HealthAIDesignSystem.Spacing.small) {
            Text(label)
                .font(HealthAIDesignSystem.Typography.subheadline)
                .fontWeight(.medium)
                .foregroundColor(HealthAIDesignSystem.Color.textPrimary)
            
            Picker(label, selection: $selection) {
                content
            }
            .pickerStyle(.menu)
            .padding()
            .background(HealthAIDesignSystem.Color.surface)
            .cornerRadius(HealthAIDesignSystem.Layout.cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: HealthAIDesignSystem.Layout.cornerRadius)
                    .stroke(borderColor, lineWidth: HealthAIDesignSystem.Layout.borderWidth)
            )
            .accessibilityLabel(Text(label))
            .accessibilityHint(Text("Double tap to open picker"))
            
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .font(HealthAIDesignSystem.Typography.caption)
                    .foregroundColor(HealthAIDesignSystem.Color.warningRed)
                    .accessibilityLabel(Text("Error: \(errorMessage)"))
            }
        }
    }
    
    private var borderColor: Color {
        errorMessage != nil ? HealthAIDesignSystem.Color.warningRed : HealthAIDesignSystem.Color.border
    }
}

// MARK: - HealthAIBadge
public struct HealthAIBadge: View {
    let text: String
    let style: BadgeStyle
    let icon: String?
    
    public enum BadgeStyle {
        case primary, secondary, success, warning, error
        
        var backgroundColor: Color {
            switch self {
            case .primary: return HealthAIDesignSystem.Color.healthPrimary
            case .secondary: return HealthAIDesignSystem.Color.infoBlue
            case .success: return HealthAIDesignSystem.Color.successGreen
            case .warning: return HealthAIDesignSystem.Color.warningRed
            case .error: return HealthAIDesignSystem.Color.warningRed
            }
        }
        
        var textColor: Color {
            switch self {
            case .primary, .secondary, .success, .warning, .error: return .white
            }
        }
    }
    
    public init(text: String, style: BadgeStyle = .primary, icon: String? = nil) {
        self.text = text
        self.style = style
        self.icon = icon
    }
    
    public var body: some View {
        HStack(spacing: HealthAIDesignSystem.Spacing.extraSmall) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(HealthAIDesignSystem.Typography.caption2)
            }
            
            Text(text)
                .font(HealthAIDesignSystem.Typography.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, HealthAIDesignSystem.Spacing.small)
        .padding(.vertical, HealthAIDesignSystem.Spacing.extraSmall)
        .background(style.backgroundColor)
        .foregroundColor(style.textColor)
        .cornerRadius(HealthAIDesignSystem.Layout.cornerRadius)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(text))
    }
}

// MARK: - HealthAISwitch
public struct HealthAISwitch: View {
    @Binding var isOn: Bool
    let label: String
    let description: String?
    
    public init(isOn: Binding<Bool>, label: String, description: String? = nil) {
        self._isOn = isOn
        self.label = label
        self.description = description
    }
    
    public var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: HealthAIDesignSystem.Spacing.extraSmall) {
                Text(label)
                    .font(HealthAIDesignSystem.Typography.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(HealthAIDesignSystem.Color.textPrimary)
                
                if let description = description {
                    Text(description)
                        .font(HealthAIDesignSystem.Typography.caption)
                        .foregroundColor(HealthAIDesignSystem.Color.textSecondary)
                }
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(HealthAIDesignSystem.Color.healthPrimary)
                .accessibilityLabel(Text(label))
                .accessibilityValue(Text(isOn ? "On" : "Off"))
        }
        .padding()
        .background(HealthAIDesignSystem.Color.surface)
        .cornerRadius(HealthAIDesignSystem.Layout.cornerRadius)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("\(label) toggle"))
        .accessibilityHint(Text("Double tap to toggle"))
    }
}

// MARK: - HealthAISegmentedControl
public struct HealthAISegmentedControl<Selection: Hashable>: View {
    @Binding var selection: Selection
    let options: [(Selection, String, String?)] // (value, label, icon)
    
    public init(selection: Binding<Selection>, options: [(Selection, String, String?)]) {
        self._selection = selection
        self.options = options
    }
    
    public var body: some View {
        Picker("", selection: $selection) {
            ForEach(Array(options.enumerated()), id: \.offset) { index, option in
                HStack {
                    if let icon = option.2 {
                        Image(systemName: icon)
                    }
                    Text(option.1)
                }
                .tag(option.0)
            }
        }
        .pickerStyle(.segmented)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("Segmented control"))
        .accessibilityValue(Text(selectedLabel))
    }
    
    private var selectedLabel: String {
        options.first { $0.0 == selection }?.1 ?? ""
    }
}

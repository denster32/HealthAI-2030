import SwiftUI

// MARK: - HealthAIButton
public struct HealthAIButton: View {
    public enum Style { case primary, secondary, tertiary }
    
    let title: String
    let style: Style
    let action: () -> Void

    public var body: some View {
        Button(action: action) {
            Text(title)
                .font(HealthAIDesignSystem.Typography.headline)
                .frame(maxWidth: .infinity, minHeight: HealthAIDesignSystem.Layout.minButtonHeight)
        }
        .background(style == .primary ? HealthAIDesignSystem.Color.healthPrimary : .clear)
        .foregroundColor(style == .primary ? .white : HealthAIDesignSystem.Color.healthPrimary)
        .cornerRadius(HealthAIDesignSystem.Layout.cornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: HealthAIDesignSystem.Layout.cornerRadius)
                .stroke(HealthAIDesignSystem.Color.healthPrimary, lineWidth: HealthAIDesignSystem.Layout.borderWidth)
                .opacity(style == .primary ? 0 : 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(title))
    }
}

// MARK: - HealthAICard
public struct HealthAICard<Content: View>: View {
    let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        content
            .padding(HealthAIDesignSystem.Spacing.medium)
            .background(HealthAIDesignSystem.Color.surface)
            .cornerRadius(HealthAIDesignSystem.Layout.cardCornerRadius)
            .shadow(radius: HealthAIDesignSystem.Layout.shadowRadius, x: 0, y: 4)
            .accessibilityElement(children: .contain)
    }
}

// MARK: - HealthAIProgressView
public struct HealthAIProgressView: View {
    public var body: some View {
        ProgressView()
            .progressViewStyle(.circular)
            .tint(HealthAIDesignSystem.Color.healthPrimary)
    }
}

// MARK: - HealthAITextField
public struct HealthAITextField: View {
    @Binding var text: String
    let placeholder: String
    
    public var body: some View {
        TextField(placeholder, text: $text)
            .padding()
            .background(HealthAIDesignSystem.Color.surface)
            .cornerRadius(HealthAIDesignSystem.Layout.cornerRadius)
            .accessibilityLabel(Text(placeholder))
    }
}

// MARK: - HealthAIPicker
public struct HealthAIPicker<Selection: Hashable, Content: View>: View {
    @Binding var selection: Selection
    let label: String
    let content: Content
    
    public init(selection: Binding<Selection>, label: String, @ViewBuilder content: () -> Content) {
        self._selection = selection
        self.label = label
        self.content = content()
    }
    
    public var body: some View {
        Picker(label, selection: $selection) {
            content
        }
        .pickerStyle(.menu)
        .accessibilityLabel(Text(label))
    }
}

// MARK: - HealthAIBadge
public struct HealthAIBadge: View {
    let text: String
    
    public var body: some View {
        Text(text)
            .font(HealthAIDesignSystem.Typography.caption)
            .padding(.horizontal, HealthAIDesignSystem.Spacing.small)
            .padding(.vertical, HealthAIDesignSystem.Spacing.extraSmall)
            .background(HealthAIDesignSystem.Color.infoBlue)
            .foregroundColor(.white)
            .cornerRadius(HealthAIDesignSystem.Layout.cornerRadius)
            .accessibilityLabel(Text(text))
    }
}

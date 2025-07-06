import SwiftUI

// MARK: - HealthFormField
public struct HealthFormField: View {
    @Binding var text: String
    let label: String
    let placeholder: String
    let isSecure: Bool
    let error: String?
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(HealthAIDesignSystem.Typography.headline)
            if isSecure {
                SecureField(placeholder, text: $text)
                    .textFieldStyle(.roundedBorder)
            } else {
                TextField(placeholder, text: $text)
                    .textFieldStyle(.roundedBorder)
            }
            if let error = error {
                Text(error)
                    .font(HealthAIDesignSystem.Typography.caption)
                    .foregroundColor(HealthAIDesignSystem.Color.warningRed)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(label))
        .accessibilityHint(Text(placeholder))
    }
}

// MARK: - HealthFormSection
public struct HealthFormSection<Content: View>: View {
    let title: String
    let content: Content
    
    public init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    public var body: some View {
        Section(header: Text(title).font(HealthAIDesignSystem.Typography.title3)) {
            content
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text(title))
    }
}

// MARK: - HealthFormValidation
public struct HealthFormValidation {
    public static func validateNonEmpty(_ value: String) -> String? {
        value.isEmpty ? "This field is required." : nil
    }
}

// MARK: - HealthFormSubmission
public struct HealthFormSubmission {
    public static func submit(formData: [String: String], completion: (Bool) -> Void) {
        // Simulate submission
        completion(true)
    }
}

// MARK: - HealthFormAccessibility
public struct HealthFormAccessibility {
    public static func accessibilityLabel(_ text: String) -> some View {
        Text(text).accessibilityLabel(Text(text))
    }
    public static func accessibilityHint(_ text: String) -> some View {
        Text(text).accessibilityHint(Text(text))
    }
}

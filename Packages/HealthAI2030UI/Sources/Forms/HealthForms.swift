import SwiftUI

// MARK: - HealthFormField
public struct HealthFormField: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    let errorMessage: String?
    let isRequired: Bool
    let keyboardType: UIKeyboardType
    let textContentType: UITextContentType?
    let validation: ((String) -> String?)?
    let onCommit: (() -> Void)?
    
    public init(
        label: String,
        placeholder: String,
        text: Binding<String>,
        errorMessage: String? = nil,
        isRequired: Bool = false,
        keyboardType: UIKeyboardType = .default,
        textContentType: UITextContentType? = nil,
        validation: ((String) -> String?)? = nil,
        onCommit: (() -> Void)? = nil
    ) {
        self.label = label
        self.placeholder = placeholder
        self._text = text
        self.errorMessage = errorMessage
        self.isRequired = isRequired
        self.keyboardType = keyboardType
        self.textContentType = textContentType
        self.validation = validation
        self.onCommit = onCommit
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: HealthAIDesignSystem.Spacing.small) {
            HStack {
                Text(label)
                    .font(HealthAIDesignSystem.Typography.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(HealthAIDesignSystem.Color.textPrimary)
                
                if isRequired {
                    Text("*")
                        .font(HealthAIDesignSystem.Typography.subheadline)
                        .foregroundColor(HealthAIDesignSystem.Color.warningRed)
                        .accessibilityLabel(Text("Required field"))
                }
            }
            
            HealthAITextField(
                text: $text,
                placeholder: placeholder,
                label: nil,
                errorMessage: errorMessage,
                keyboardType: keyboardType,
                textContentType: textContentType
            )
            .onChange(of: text) { newValue in
                if let validation = validation {
                    let error = validation(newValue)
                    // Handle validation error
                }
            }
            .onSubmit {
                onCommit?()
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text("\(label) field\(isRequired ? ", required" : "")"))
        .accessibilityHint(Text(errorMessage ?? "Enter \(label.lowercased())"))
    }
}

// MARK: - HealthFormSection
public struct HealthFormSection<Content: View>: View {
    let title: String?
    let subtitle: String?
    let content: Content
    let isCollapsible: Bool
    @State private var isExpanded: Bool = true
    
    public init(
        title: String? = nil,
        subtitle: String? = nil,
        isCollapsible: Bool = false,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.isCollapsible = isCollapsible
        self.content = content()
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: HealthAIDesignSystem.Spacing.medium) {
            if let title = title {
                HStack {
                    VStack(alignment: .leading, spacing: HealthAIDesignSystem.Spacing.extraSmall) {
                        Text(title)
                            .font(HealthAIDesignSystem.Typography.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(HealthAIDesignSystem.Color.textPrimary)
                        
                        if let subtitle = subtitle {
                            Text(subtitle)
                                .font(HealthAIDesignSystem.Typography.caption)
                                .foregroundColor(HealthAIDesignSystem.Color.textSecondary)
                        }
                    }
                    
                    Spacer()
                    
                    if isCollapsible {
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                isExpanded.toggle()
                            }
                        }) {
                            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                                .foregroundColor(HealthAIDesignSystem.Color.textSecondary)
                                .accessibilityLabel(Text(isExpanded ? "Collapse section" : "Expand section"))
                        }
                    }
                }
            }
            
            if !isCollapsible || isExpanded {
                content
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding()
        .background(HealthAIDesignSystem.Color.surface)
        .cornerRadius(HealthAIDesignSystem.Layout.cornerRadius)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text("\(title ?? "Form section")\(isCollapsible ? ", collapsible" : "")"))
    }
}

// MARK: - HealthFormValidation
public struct HealthFormValidation {
    public static func required(_ value: String, fieldName: String) -> String? {
        value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "\(fieldName) is required" : nil
    }
    
    public static func email(_ value: String) -> String? {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: value) ? nil : "Please enter a valid email address"
    }
    
    public static func phone(_ value: String) -> String? {
        let phoneRegex = "^[0-9+]{0,1}+[0-9]{5,16}$"
        let phonePredicate = NSPredicate(format: "SELF MATCHES %@", phoneRegex)
        return phonePredicate.evaluate(with: value) ? nil : "Please enter a valid phone number"
    }
    
    public static func minLength(_ value: String, min: Int, fieldName: String) -> String? {
        value.count >= min ? nil : "\(fieldName) must be at least \(min) characters"
    }
    
    public static func maxLength(_ value: String, max: Int, fieldName: String) -> String? {
        value.count <= max ? nil : "\(fieldName) must be no more than \(max) characters"
    }
    
    public static func numeric(_ value: String) -> String? {
        Double(value) != nil ? nil : "Please enter a valid number"
    }
    
    public static func range(_ value: String, min: Double, max: Double, fieldName: String) -> String? {
        guard let numericValue = Double(value) else { return "Please enter a valid number" }
        return (min...max).contains(numericValue) ? nil : "\(fieldName) must be between \(min) and \(max)"
    }
}

// MARK: - HealthFormSubmission
public struct HealthFormSubmission: View {
    let title: String
    let isLoading: Bool
    let isEnabled: Bool
    let action: () -> Void
    
    public init(
        title: String,
        isLoading: Bool = false,
        isEnabled: Bool = true,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.isLoading = isLoading
        self.isEnabled = isEnabled
        self.action = action
    }
    
    public var body: some View {
        HealthAIButton(
            title: title,
            style: .primary,
            isEnabled: isEnabled,
            isLoading: isLoading,
            action: action
        )
        .accessibilityLabel(Text("\(title) button"))
        .accessibilityHint(Text(isEnabled ? "Double tap to submit form" : "Form submission is disabled"))
    }
}

// MARK: - HealthFormAccessibility
public struct HealthFormAccessibility {
    public static func announceFieldError(_ error: String) {
        UIAccessibility.post(notification: .announcement, argument: error)
    }
    
    public static func announceFormSubmission() {
        UIAccessibility.post(notification: .announcement, argument: "Form submitted successfully")
    }
    
    public static func announceValidationError(_ error: String) {
        UIAccessibility.post(notification: .announcement, argument: "Validation error: \(error)")
    }
}

// MARK: - HealthFormContainer
public struct HealthFormContainer<Content: View>: View {
    let title: String?
    let content: Content
    let onSubmit: (() -> Void)?
    let onCancel: (() -> Void)?
    let submitTitle: String
    let cancelTitle: String
    let isLoading: Bool
    let isValid: Bool
    
    public init(
        title: String? = nil,
        submitTitle: String = "Submit",
        cancelTitle: String = "Cancel",
        isLoading: Bool = false,
        isValid: Bool = true,
        onSubmit: (() -> Void)? = nil,
        onCancel: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.submitTitle = submitTitle
        self.cancelTitle = cancelTitle
        self.isLoading = isLoading
        self.isValid = isValid
        self.onSubmit = onSubmit
        self.onCancel = onCancel
        self.content = content()
    }
    
    public var body: some View {
        VStack(spacing: HealthAIDesignSystem.Spacing.large) {
            if let title = title {
                Text(title)
                    .font(HealthAIDesignSystem.Typography.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(HealthAIDesignSystem.Color.textPrimary)
                    .multilineTextAlignment(.center)
                    .accessibilityAddTraits(.isHeader)
            }
            
            ScrollView {
                VStack(spacing: HealthAIDesignSystem.Spacing.medium) {
                    content
                }
                .padding()
            }
            
            VStack(spacing: HealthAIDesignSystem.Spacing.medium) {
                if let onSubmit = onSubmit {
                    HealthFormSubmission(
                        title: submitTitle,
                        isLoading: isLoading,
                        isEnabled: isValid && !isLoading,
                        action: onSubmit
                    )
                }
                
                if let onCancel = onCancel {
                    HealthAIButton(
                        title: cancelTitle,
                        style: .secondary,
                        action: onCancel
                    )
                }
            }
            .padding()
        }
        .background(HealthAIDesignSystem.Color.background)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text("Form: \(title ?? "Data entry form")"))
    }
}

// MARK: - HealthFormFieldGroup
public struct HealthFormFieldGroup<Content: View>: View {
    let title: String?
    let content: Content
    let isRequired: Bool
    
    public init(
        title: String? = nil,
        isRequired: Bool = false,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.isRequired = isRequired
        self.content = content()
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: HealthAIDesignSystem.Spacing.medium) {
            if let title = title {
                HStack {
                    Text(title)
                        .font(HealthAIDesignSystem.Typography.headline)
                        .fontWeight(.medium)
                        .foregroundColor(HealthAIDesignSystem.Color.textPrimary)
                    
                    if isRequired {
                        Text("*")
                            .font(HealthAIDesignSystem.Typography.headline)
                            .foregroundColor(HealthAIDesignSystem.Color.warningRed)
                            .accessibilityLabel(Text("Required group"))
                    }
                    
                    Spacer()
                }
            }
            
            content
        }
        .padding()
        .background(HealthAIDesignSystem.Color.surface.opacity(0.5))
        .cornerRadius(HealthAIDesignSystem.Layout.cornerRadius)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text("\(title ?? "Field group")\(isRequired ? ", required" : "")"))
    }
}

// MARK: - HealthFormStepper
public struct HealthFormStepper: View {
    let label: String
    let value: Binding<Double>
    let range: ClosedRange<Double>
    let step: Double
    let format: String
    
    public init(
        label: String,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        step: Double = 1.0,
        format: String = "%.1f"
    ) {
        self.label = label
        self._value = value
        self.range = range
        self.step = step
        self.format = format
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: HealthAIDesignSystem.Spacing.small) {
            Text(label)
                .font(HealthAIDesignSystem.Typography.subheadline)
                .fontWeight(.medium)
                .foregroundColor(HealthAIDesignSystem.Color.textPrimary)
            
            HStack {
                Button(action: {
                    let newValue = value.wrappedValue - step
                    if range.contains(newValue) {
                        value.wrappedValue = newValue
                    }
                }) {
                    Image(systemName: "minus.circle.fill")
                        .font(.title2)
                        .foregroundColor(HealthAIDesignSystem.Color.healthPrimary)
                }
                .disabled(!range.contains(value.wrappedValue - step))
                .accessibilityLabel(Text("Decrease \(label)"))
                
                Spacer()
                
                Text(String(format: format, value.wrappedValue))
                    .font(HealthAIDesignSystem.Typography.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(HealthAIDesignSystem.Color.textPrimary)
                    .frame(minWidth: 80)
                    .accessibilityLabel(Text("\(label): \(String(format: format, value.wrappedValue))"))
                
                Spacer()
                
                Button(action: {
                    let newValue = value.wrappedValue + step
                    if range.contains(newValue) {
                        value.wrappedValue = newValue
                    }
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(HealthAIDesignSystem.Color.healthPrimary)
                }
                .disabled(!range.contains(value.wrappedValue + step))
                .accessibilityLabel(Text("Increase \(label)"))
            }
            .padding()
            .background(HealthAIDesignSystem.Color.surface)
            .cornerRadius(HealthAIDesignSystem.Layout.cornerRadius)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text("Stepper for \(label)"))
        .accessibilityValue(Text(String(format: format, value.wrappedValue)))
    }
}

// MARK: - HealthFormDatePicker
public struct HealthFormDatePicker: View {
    let label: String
    @Binding var date: Date
    let range: ClosedRange<Date>?
    let displayMode: DatePickerMode
    let isRequired: Bool
    
    public init(
        label: String,
        date: Binding<Date>,
        range: ClosedRange<Date>? = nil,
        displayMode: DatePickerMode = .date,
        isRequired: Bool = false
    ) {
        self.label = label
        self._date = date
        self.range = range
        self.displayMode = displayMode
        self.isRequired = isRequired
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: HealthAIDesignSystem.Spacing.small) {
            HStack {
                Text(label)
                    .font(HealthAIDesignSystem.Typography.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(HealthAIDesignSystem.Color.textPrimary)
                
                if isRequired {
                    Text("*")
                        .font(HealthAIDesignSystem.Typography.subheadline)
                        .foregroundColor(HealthAIDesignSystem.Color.warningRed)
                        .accessibilityLabel(Text("Required field"))
                }
                
                Spacer()
            }
            
            DatePicker(
                label,
                selection: $date,
                in: range ?? Date.distantPast...Date.distantFuture,
                displayedComponents: displayMode == .date ? .date : .dateAndTime
            )
            .datePickerStyle(.compact)
            .labelsHidden()
            .padding()
            .background(HealthAIDesignSystem.Color.surface)
            .cornerRadius(HealthAIDesignSystem.Layout.cornerRadius)
            .accessibilityLabel(Text("\(label) date picker"))
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text("\(label) field\(isRequired ? ", required" : "")"))
    }
    
    public enum DatePickerMode {
        case date, dateAndTime
    }
}

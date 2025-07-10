import SwiftUI

// MARK: - Form Field Types
public enum FormFieldType {
    case text
    case email
    case phone
    case number
    case date
    case time
    case password
    case multiline
    case healthMetric
    case medical
}

// MARK: - Form Validation
public struct FormValidation {
    let isValid: Bool
    let errorMessage: String?
    let warningMessage: String?
    
    public init(isValid: Bool, errorMessage: String? = nil, warningMessage: String? = nil) {
        self.isValid = isValid
        self.errorMessage = errorMessage
        self.warningMessage = warningMessage
    }
    
    public static let valid = FormValidation(isValid: true)
    public static let invalid = FormValidation(isValid: false, errorMessage: "Invalid input")
}

// MARK: - HealthAI Text Field
public struct HealthAITextField: View {
    let title: String
    let placeholder: String
    let type: FormFieldType
    @Binding var text: String
    let validation: FormValidation
    let isRequired: Bool
    let icon: String?
    let onCommit: (() -> Void)?
    
    @State private var isFocused: Bool = false
    @State private var showPassword: Bool = false
    
    public init(
        title: String,
        placeholder: String = "",
        type: FormFieldType = .text,
        text: Binding<String>,
        validation: FormValidation = .valid,
        isRequired: Bool = false,
        icon: String? = nil,
        onCommit: (() -> Void)? = nil
    ) {
        self.title = title
        self.placeholder = placeholder
        self.type = type
        self._text = text
        self.validation = validation
        self.isRequired = isRequired
        self.icon = icon
        self.onCommit = onCommit
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: SpacingGrid.small) {
            // Label
            HStack {
                Text(title)
                    .font(TypographySystem.body.weight(.medium))
                    .foregroundColor(ColorPalette.textPrimary)
                
                if isRequired {
                    Text("*")
                        .font(TypographySystem.body.weight(.bold))
                        .foregroundColor(ColorPalette.critical)
                }
            }
            
            // Input Field
            HStack(spacing: SpacingGrid.small) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 16))
                        .foregroundColor(iconColor)
                        .frame(width: 20)
                }
                
                Group {
                    switch type {
                    case .password:
                        if showPassword {
                            TextField(placeholder, text: $text, onCommit: onCommit)
                        } else {
                            SecureField(placeholder, text: $text, onCommit: onCommit)
                        }
                    case .multiline:
                        TextEditor(text: $text)
                            .frame(minHeight: 100)
                    case .number:
                        TextField(placeholder, text: $text, onCommit: onCommit)
                            .keyboardType(.numberPad)
                    case .email:
                        TextField(placeholder, text: $text, onCommit: onCommit)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                    case .phone:
                        TextField(placeholder, text: $text, onCommit: onCommit)
                            .keyboardType(.phonePad)
                    default:
                        TextField(placeholder, text: $text, onCommit: onCommit)
                    }
                }
                .font(TypographySystem.body)
                .foregroundColor(ColorPalette.textPrimary)
                
                if type == .password {
                    Button(action: { showPassword.toggle() }) {
                        Image(systemName: showPassword ? "eye.slash" : "eye")
                            .font(.system(size: 16))
                            .foregroundColor(ColorPalette.textSecondary)
                    }
                    .accessibilityLabel(Text(showPassword ? "Hide password" : "Show password"))
                }
            }
            .padding(SpacingGrid.medium)
            .background(backgroundColor)
            .cornerRadius(SpacingGrid.small)
            .overlay(
                RoundedRectangle(cornerRadius: SpacingGrid.small)
                    .stroke(borderColor, lineWidth: borderWidth)
            )
            .onTapGesture {
                isFocused = true
            }
            
            // Validation Messages
            if let errorMessage = validation.errorMessage {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(ColorPalette.critical)
                    
                    Text(errorMessage)
                        .font(TypographySystem.caption)
                        .foregroundColor(ColorPalette.critical)
                }
            } else if let warningMessage = validation.warningMessage {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(ColorPalette.warning)
                    
                    Text(warningMessage)
                        .font(TypographySystem.caption)
                        .foregroundColor(ColorPalette.warning)
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text(accessibilityLabel))
        .accessibilityHint(Text(accessibilityHint))
    }
    
    // MARK: - Style Properties
    private var backgroundColor: Color {
        if !validation.isValid {
            return ColorPalette.critical.opacity(0.1)
        }
        return isFocused ? ColorPalette.surface : ColorPalette.background
    }
    
    private var borderColor: Color {
        if !validation.isValid {
            return ColorPalette.critical
        }
        return isFocused ? ColorPalette.primary : ColorPalette.border
    }
    
    private var borderWidth: CGFloat {
        return isFocused ? 2 : 1
    }
    
    private var iconColor: Color {
        return isFocused ? ColorPalette.primary : ColorPalette.textSecondary
    }
    
    // MARK: - Accessibility Properties
    private var accessibilityLabel: String {
        var label = title
        if isRequired {
            label += ", required"
        }
        if !validation.isValid {
            label += ", has error"
        }
        return label
    }
    
    private var accessibilityHint: String {
        if !validation.isValid {
            return validation.errorMessage ?? "Invalid input"
        }
        return "Enter \(title.lowercased())"
    }
}

// MARK: - HealthAI Picker
public struct HealthAIPicker<T: Hashable>: View {
    let title: String
    let selection: Binding<T>
    let options: [T]
    let optionLabel: (T) -> String
    let isRequired: Bool
    let icon: String?
    
    public init(
        title: String,
        selection: Binding<T>,
        options: [T],
        optionLabel: @escaping (T) -> String,
        isRequired: Bool = false,
        icon: String? = nil
    ) {
        self.title = title
        self._selection = selection
        self.options = options
        self.optionLabel = optionLabel
        self.isRequired = isRequired
        self.icon = icon
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: SpacingGrid.small) {
            // Label
            HStack {
                Text(title)
                    .font(TypographySystem.body.weight(.medium))
                    .foregroundColor(ColorPalette.textPrimary)
                
                if isRequired {
                    Text("*")
                        .font(TypographySystem.body.weight(.bold))
                        .foregroundColor(ColorPalette.critical)
                }
            }
            
            // Picker
            HStack {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 16))
                        .foregroundColor(ColorPalette.textSecondary)
                        .frame(width: 20)
                }
                
                Picker(title, selection: selection) {
                    ForEach(options, id: \.self) { option in
                        Text(optionLabel(option))
                            .tag(option)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                
                Spacer()
                
                Image(systemName: "chevron.down")
                    .font(.system(size: 12))
                    .foregroundColor(ColorPalette.textSecondary)
            }
            .padding(SpacingGrid.medium)
            .background(ColorPalette.background)
            .cornerRadius(SpacingGrid.small)
            .overlay(
                RoundedRectangle(cornerRadius: SpacingGrid.small)
                    .stroke(ColorPalette.border, lineWidth: 1)
            )
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text("\(title) picker"))
        .accessibilityHint(Text("Double tap to select \(title.lowercased())"))
    }
}

// MARK: - HealthAI Checkbox
public struct HealthAICheckbox: View {
    let title: String
    let isChecked: Binding<Bool>
    let isRequired: Bool
    let description: String?
    
    public init(
        title: String,
        isChecked: Binding<Bool>,
        isRequired: Bool = false,
        description: String? = nil
    ) {
        self.title = title
        self._isChecked = isChecked
        self.isRequired = isRequired
        self.description = description
    }
    
    public var body: some View {
        HStack(alignment: .top, spacing: SpacingGrid.medium) {
            Button(action: { isChecked.wrappedValue.toggle() }) {
                Image(systemName: isChecked.wrappedValue ? "checkmark.square.fill" : "square")
                    .font(.system(size: 20))
                    .foregroundColor(isChecked.wrappedValue ? ColorPalette.primary : ColorPalette.textSecondary)
            }
            .accessibilityLabel(Text(isChecked.wrappedValue ? "Uncheck \(title)" : "Check \(title)"))
            
            VStack(alignment: .leading, spacing: SpacingGrid.small) {
                HStack {
                    Text(title)
                        .font(TypographySystem.body)
                        .foregroundColor(ColorPalette.textPrimary)
                    
                    if isRequired {
                        Text("*")
                            .font(TypographySystem.body.weight(.bold))
                            .foregroundColor(ColorPalette.critical)
                    }
                }
                
                if let description = description {
                    Text(description)
                        .font(TypographySystem.caption)
                        .foregroundColor(ColorPalette.textSecondary)
                }
            }
            
            Spacer()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(accessibilityLabel))
        .accessibilityHint(Text("Double tap to toggle"))
        .accessibilityAddTraits(.isButton)
    }
    
    private var accessibilityLabel: String {
        var label = title
        if isRequired {
            label += ", required"
        }
        if isChecked.wrappedValue {
            label += ", checked"
        } else {
            label += ", unchecked"
        }
        return label
    }
}

// MARK: - HealthAI Radio Button
public struct HealthAIRadioButton<T: Hashable>: View {
    let title: String
    let selection: Binding<T>
    let value: T
    let isRequired: Bool
    let description: String?
    
    public init(
        title: String,
        selection: Binding<T>,
        value: T,
        isRequired: Bool = false,
        description: String? = nil
    ) {
        self.title = title
        self._selection = selection
        self.value = value
        self.isRequired = isRequired
        self.description = description
    }
    
    public var body: some View {
        HStack(alignment: .top, spacing: SpacingGrid.medium) {
            Button(action: { selection.wrappedValue = value }) {
                Image(systemName: selection.wrappedValue == value ? "largecircle.fill.circle" : "circle")
                    .font(.system(size: 20))
                    .foregroundColor(selection.wrappedValue == value ? ColorPalette.primary : ColorPalette.textSecondary)
            }
            .accessibilityLabel(Text("Select \(title)"))
            
            VStack(alignment: .leading, spacing: SpacingGrid.small) {
                HStack {
                    Text(title)
                        .font(TypographySystem.body)
                        .foregroundColor(ColorPalette.textPrimary)
                    
                    if isRequired {
                        Text("*")
                            .font(TypographySystem.body.weight(.bold))
                            .foregroundColor(ColorPalette.critical)
                    }
                }
                
                if let description = description {
                    Text(description)
                        .font(TypographySystem.caption)
                        .foregroundColor(ColorPalette.textSecondary)
                }
            }
            
            Spacer()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(accessibilityLabel))
        .accessibilityHint(Text("Double tap to select"))
        .accessibilityAddTraits(.isButton)
    }
    
    private var accessibilityLabel: String {
        var label = title
        if isRequired {
            label += ", required"
        }
        if selection.wrappedValue == value {
            label += ", selected"
        } else {
            label += ", not selected"
        }
        return label
    }
}

// MARK: - Health-Specific Form Components

/// Form field for health metrics with validation
public struct HealthMetricField: View {
    let title: String
    let metricType: HealthMetricType
    let value: Binding<String>
    let unit: String
    let validation: FormValidation
    let isRequired: Bool
    let onCommit: (() -> Void)?
    
    public init(
        title: String,
        metricType: HealthMetricType,
        value: Binding<String>,
        unit: String,
        validation: FormValidation = .valid,
        isRequired: Bool = false,
        onCommit: (() -> Void)? = nil
    ) {
        self.title = title
        self.metricType = metricType
        self._value = value
        self.unit = unit
        self.validation = validation
        self.isRequired = isRequired
        self.onCommit = onCommit
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: SpacingGrid.small) {
            // Label
            HStack {
                Text(title)
                    .font(TypographySystem.healthMetricLabel)
                    .foregroundColor(ColorPalette.textPrimary)
                
                if isRequired {
                    Text("*")
                        .font(TypographySystem.healthMetricLabel.weight(.bold))
                        .foregroundColor(ColorPalette.critical)
                }
            }
            
            // Input with unit
            HStack(spacing: SpacingGrid.small) {
                TextField("Enter value", text: value, onCommit: onCommit)
                    .font(TypographySystem.healthMetricSmall)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                
                Text(unit)
                    .font(TypographySystem.healthMetricUnit)
                    .foregroundColor(ColorPalette.textSecondary)
            }
            .padding(SpacingGrid.medium)
            .background(backgroundColor)
            .cornerRadius(SpacingGrid.small)
            .overlay(
                RoundedRectangle(cornerRadius: SpacingGrid.small)
                    .stroke(borderColor, lineWidth: borderWidth)
            )
            
            // Validation
            if let errorMessage = validation.errorMessage {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(ColorPalette.critical)
                    
                    Text(errorMessage)
                        .font(TypographySystem.caption)
                        .foregroundColor(ColorPalette.critical)
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text("\(title) in \(unit)"))
        .accessibilityHint(Text("Enter \(title.lowercased()) value"))
    }
    
    private var backgroundColor: Color {
        return validation.isValid ? ColorPalette.background : ColorPalette.critical.opacity(0.1)
    }
    
    private var borderColor: Color {
        return validation.isValid ? ColorPalette.border : ColorPalette.critical
    }
    
    private var borderWidth: CGFloat {
        return validation.isValid ? 1 : 2
    }
}

/// Medical form field for patient information
public struct MedicalFormField: View {
    let title: String
    let fieldType: MedicalFieldType
    let value: Binding<String>
    let validation: FormValidation
    let isRequired: Bool
    let description: String?
    
    public init(
        title: String,
        fieldType: MedicalFieldType,
        value: Binding<String>,
        validation: FormValidation = .valid,
        isRequired: Bool = false,
        description: String? = nil
    ) {
        self.title = title
        self.fieldType = fieldType
        self._value = value
        self.validation = validation
        self.isRequired = isRequired
        self.description = description
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: SpacingGrid.small) {
            // Label
            HStack {
                Text(title)
                    .font(TypographySystem.medicalLabel)
                    .foregroundColor(ColorPalette.textPrimary)
                
                if isRequired {
                    Text("*")
                        .font(TypographySystem.medicalLabel.weight(.bold))
                        .foregroundColor(ColorPalette.critical)
                }
            }
            
            // Description
            if let description = description {
                Text(description)
                    .font(TypographySystem.medicalCaption)
                    .foregroundColor(ColorPalette.textSecondary)
            }
            
            // Input
            TextField(placeholder, text: value)
                .font(TypographySystem.medicalReading)
                .keyboardType(keyboardType)
                .autocapitalization(autocapitalization)
                .padding(SpacingGrid.medium)
                .background(backgroundColor)
                .cornerRadius(SpacingGrid.small)
                .overlay(
                    RoundedRectangle(cornerRadius: SpacingGrid.small)
                        .stroke(borderColor, lineWidth: borderWidth)
                )
            
            // Validation
            if let errorMessage = validation.errorMessage {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(ColorPalette.critical)
                    
                    Text(errorMessage)
                        .font(TypographySystem.medicalCaption)
                        .foregroundColor(ColorPalette.critical)
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text(accessibilityLabel))
        .accessibilityHint(Text("Enter \(title.lowercased())"))
    }
    
    private var placeholder: String {
        switch fieldType {
        case .patientName:
            return "Enter patient name"
        case .dateOfBirth:
            return "MM/DD/YYYY"
        case .medicalRecordNumber:
            return "Enter MRN"
        case .allergies:
            return "List allergies (if any)"
        case .medications:
            return "List current medications"
        case .diagnosis:
            return "Enter diagnosis"
        }
    }
    
    private var keyboardType: UIKeyboardType {
        switch fieldType {
        case .medicalRecordNumber:
            return .numberPad
        case .dateOfBirth:
            return .numberPad
        default:
            return .default
        }
    }
    
    private var autocapitalization: TextInputAutocapitalization {
        switch fieldType {
        case .patientName:
            return .words
        case .diagnosis:
            return .sentences
        default:
            return .none
        }
    }
    
    private var backgroundColor: Color {
        return validation.isValid ? ColorPalette.background : ColorPalette.critical.opacity(0.1)
    }
    
    private var borderColor: Color {
        return validation.isValid ? ColorPalette.border : ColorPalette.critical
    }
    
    private var borderWidth: CGFloat {
        return validation.isValid ? 1 : 2
    }
    
    private var accessibilityLabel: String {
        var label = title
        if isRequired {
            label += ", required"
        }
        if !validation.isValid {
            label += ", has error"
        }
        return label
    }
}

// MARK: - Supporting Enums

/// Medical field types for specialized form fields
public enum MedicalFieldType {
    case patientName
    case dateOfBirth
    case medicalRecordNumber
    case allergies
    case medications
    case diagnosis
}

// MARK: - Form Validation Helpers

extension FormValidation {
    /// Validate email format
    public static func validateEmail(_ email: String) -> FormValidation {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        
        if email.isEmpty {
            return FormValidation(isValid: false, errorMessage: "Email is required")
        }
        
        if !emailPredicate.evaluate(with: email) {
            return FormValidation(isValid: false, errorMessage: "Invalid email format")
        }
        
        return .valid
    }
    
    /// Validate phone number format
    public static func validatePhone(_ phone: String) -> FormValidation {
        let phoneRegex = "^[0-9]{10}$"
        let phonePredicate = NSPredicate(format: "SELF MATCHES %@", phoneRegex)
        
        if phone.isEmpty {
            return FormValidation(isValid: false, errorMessage: "Phone number is required")
        }
        
        if !phonePredicate.evaluate(with: phone) {
            return FormValidation(isValid: false, errorMessage: "Invalid phone number format")
        }
        
        return .valid
    }
    
    /// Validate required field
    public static func validateRequired(_ value: String, fieldName: String) -> FormValidation {
        if value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return FormValidation(isValid: false, errorMessage: "\(fieldName) is required")
        }
        return .valid
    }
    
    /// Validate numeric range
    public static func validateRange(_ value: String, min: Double, max: Double, fieldName: String) -> FormValidation {
        guard let numericValue = Double(value) else {
            return FormValidation(isValid: false, errorMessage: "\(fieldName) must be a number")
        }
        
        if numericValue < min || numericValue > max {
            return FormValidation(isValid: false, errorMessage: "\(fieldName) must be between \(min) and \(max)")
        }
        
        return .valid
    }
} 
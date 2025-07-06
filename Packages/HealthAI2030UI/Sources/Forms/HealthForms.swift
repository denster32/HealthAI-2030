import SwiftUI

/// Health Form Field Configuration
public struct HealthFormField {
    let label: String
    let placeholder: String
    let errorMessage: String?
    let isRequired: Bool
    let validation: ((String) -> String?)?
    let onCommit: (() -> Void)?
    
    public init(
        label: String,
        placeholder: String,
        errorMessage: String? = nil,
        isRequired: Bool = false,
        validation: ((String) -> String?)? = nil,
        onCommit: (() -> Void)? = nil
    ) {
        self.label = label
        self.placeholder = placeholder
        self.errorMessage = errorMessage
        self.isRequired = isRequired
        self.validation = validation
        self.onCommit = onCommit
    }
}

/// Health Form Text Field
public struct HealthFormTextField: View {
    @Binding var text: String
    let placeholder: String
    let label: String?
    let errorMessage: String?
    let isSecure: Bool
    let onCommit: (() -> Void)?
    
    public init(
        text: Binding<String>,
        placeholder: String,
        label: String? = nil,
        errorMessage: String? = nil,
        isSecure: Bool = false,
        onCommit: (() -> Void)? = nil
    ) {
        self._text = text
        self.placeholder = placeholder
        self.label = label
        self.errorMessage = errorMessage
        self.isSecure = isSecure
        self.onCommit = onCommit
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let label = label {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if isSecure {
                SecureField(placeholder, text: $text)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onSubmit {
                        onCommit?()
                    }
            } else {
                TextField(placeholder, text: $text)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onSubmit {
                        onCommit?()
                    }
            }
            
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
    }
}

/// Health Form Stepper
public struct HealthFormStepper: View {
    let label: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let errorMessage: String?
    
    public init(
        label: String,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        step: Double = 1.0,
        errorMessage: String? = nil
    ) {
        self.label = label
        self._value = value
        self.range = range
        self.step = step
        self.errorMessage = errorMessage
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack {
                Button("-") {
                    value = max(range.lowerBound, value - step)
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Text(String(format: "%.1f", value))
                    .font(.headline)
                
                Spacer()
                
                Button("+") {
                    value = min(range.upperBound, value + step)
                }
                .buttonStyle(.bordered)
            }
            
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
    }
}

/// Health Form Date Picker
public struct HealthFormDatePicker: View {
    let label: String
    @Binding var date: Date
    let range: ClosedRange<Date>?
    let displayMode: DatePickerDisplayMode
    let errorMessage: String?
    
    public enum DatePickerDisplayMode {
        case date
        case dateAndTime
    }
    
    public init(
        label: String,
        date: Binding<Date>,
        range: ClosedRange<Date>? = nil,
        displayMode: DatePickerDisplayMode = .date,
        errorMessage: String? = nil
    ) {
        self.label = label
        self._date = date
        self.range = range
        self.displayMode = displayMode
        self.errorMessage = errorMessage
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            
            DatePicker(
                "",
                selection: $date,
                in: range ?? Date.distantPast...Date.distantFuture,
                displayedComponents: displayMode == .date ? .date : [.date, .hourAndMinute]
            )
            .datePickerStyle(.compact)
            
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
    }
}

/// Health Form Picker
public struct HealthFormPicker<T: Hashable>: View {
    let label: String
    @Binding var selection: T
    let options: [T]
    let optionTitle: (T) -> String
    let errorMessage: String?
    
    public init(
        label: String,
        selection: Binding<T>,
        options: [T],
        optionTitle: @escaping (T) -> String,
        errorMessage: String? = nil
    ) {
        self.label = label
        self._selection = selection
        self.options = options
        self.optionTitle = optionTitle
        self.errorMessage = errorMessage
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Picker("", selection: $selection) {
                ForEach(options, id: \.self) { option in
                    Text(optionTitle(option)).tag(option)
                }
            }
            .pickerStyle(.menu)
            
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
    }
}

/// Health Form Toggle
public struct HealthFormToggle: View {
    let label: String
    @Binding var isOn: Bool
    let errorMessage: String?
    
    public init(
        label: String,
        isOn: Binding<Bool>,
        errorMessage: String? = nil
    ) {
        self.label = label
        self._isOn = isOn
        self.errorMessage = errorMessage
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Toggle(label, isOn: $isOn)
            
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
    }
}

/// Health Form Section
public struct HealthFormSection<Content: View>: View {
    let title: String?
    let content: Content
    
    public init(title: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let title = title {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
            }
            
            content
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}

/// Health Form Container
public struct HealthFormContainer<Content: View>: View {
    let title: String
    let content: Content
    let onSubmit: (() -> Void)?
    
    public init(
        title: String,
        onSubmit: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.onSubmit = onSubmit
        self.content = content()
    }
    
    public var body: some View {
        VStack(spacing: 16) {
            Text(title)
                .font(.largeTitle)
                .fontWeight(.bold)
            
            ScrollView {
                VStack(spacing: 16) {
                    content
                }
                .padding()
            }
            
            if let onSubmit = onSubmit {
                Button("Submit") {
                    onSubmit()
                }
                .buttonStyle(.borderedProminent)
                .padding()
            }
        }
    }
}

/// Health Form Accessibility
public struct HealthFormAccessibility {
    public static func announceFieldError(_ error: String) {
        // Placeholder implementation
        print("Accessibility announcement: \(error)")
    }
    
    public static func announceFormSubmission() {
        // Placeholder implementation
        print("Accessibility announcement: Form submitted successfully")
    }
    
    public static func announceValidationError(_ error: String) {
        // Placeholder implementation
        print("Accessibility announcement: Validation error: \(error)")
    }
}

#Preview {
    HealthFormContainer(title: "Health Form") {
        HealthFormSection(title: "Personal Information") {
            VStack(spacing: 12) {
                HealthFormTextField(
                    text: .constant(""),
                    placeholder: "Enter your name",
                    label: "Full Name"
                )
                
                HealthFormTextField(
                    text: .constant(""),
                    placeholder: "Enter your email",
                    label: "Email"
                )
                
                HealthFormStepper(
                    label: "Age",
                    value: .constant(25),
                    range: 0...120
                )
            }
        }
    }
}

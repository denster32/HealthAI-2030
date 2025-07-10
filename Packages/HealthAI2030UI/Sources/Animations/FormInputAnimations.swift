import SwiftUI

// MARK: - Form Input Animations
/// Comprehensive form input animations for enhanced user experience
/// Provides smooth, accessible, and engaging animations for form interactions
public struct FormInputAnimations {
    
    // MARK: - Animated Text Field
    
    /// Text field with floating label and focus animations
    public struct AnimatedTextField: View {
        let placeholder: String
        let text: Binding<String>
        let icon: String?
        let validationState: ValidationState
        @State private var isFocused: Bool = false
        @State private var labelOffset: CGFloat = 0
        @State private var borderWidth: CGFloat = 1
        @State private var scale: CGFloat = 1.0
        @State private var shakeOffset: CGFloat = 0
        
        public init(
            placeholder: String,
            text: Binding<String>,
            icon: String? = nil,
            validationState: ValidationState = .neutral
        ) {
            self.placeholder = placeholder
            self.text = text
            self.icon = icon
            self.validationState = validationState
        }
        
        public var body: some View {
            VStack(alignment: .leading, spacing: 4) {
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(borderColor, lineWidth: borderWidth)
                        )
                        .scaleEffect(scale)
                    
                    // Icon
                    if let icon = icon {
                        Image(systemName: icon)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(iconColor)
                            .padding(.leading, 16)
                            .opacity(isFocused || !text.wrappedValue.isEmpty ? 1.0 : 0.6)
                    }
                    
                    // Text field
                    TextField("", text: text)
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.primary)
                        .padding(.leading, icon != nil ? 48 : 16)
                        .padding(.trailing, 16)
                        .padding(.vertical, 16)
                        .background(Color.clear)
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                isFocused = true
                                scale = 1.02
                                borderWidth = 2
                            }
                        }
                    
                    // Floating label
                    Text(placeholder)
                        .font(.system(size: isFocused || !text.wrappedValue.isEmpty ? 12 : 16, weight: .medium))
                        .foregroundColor(labelColor)
                        .padding(.horizontal, icon != nil ? 48 : 16)
                        .background(Color(.systemBackground))
                        .offset(y: labelOffset)
                        .scaleEffect(isFocused || !text.wrappedValue.isEmpty ? 0.9 : 1.0)
                }
                
                // Validation message
                if validationState != .neutral {
                    Text(validationMessage)
                        .font(.caption)
                        .foregroundColor(validationColor)
                        .padding(.leading, 16)
                        .offset(x: shakeOffset)
                }
            }
            .onAppear {
                updateLabelPosition()
            }
            .onChange(of: isFocused) { _ in
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    updateLabelPosition()
                }
            }
            .onChange(of: text.wrappedValue) { _ in
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    updateLabelPosition()
                }
                
                // Shake animation for validation errors
                if validationState == .error {
                    withAnimation(.spring(response: 0.1, dampingFraction: 0.3).repeatCount(3, autoreverses: true)) {
                        shakeOffset = 10
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            shakeOffset = 0
                        }
                    }
                }
            }
        }
        
        private func updateLabelPosition() {
            labelOffset = isFocused || !text.wrappedValue.isEmpty ? -8 : 0
        }
        
        private var borderColor: Color {
            switch validationState {
            case .neutral: return isFocused ? .blue : .gray.opacity(0.3)
            case .valid: return .green
            case .error: return .red
            }
        }
        
        private var iconColor: Color {
            switch validationState {
            case .neutral: return isFocused ? .blue : .gray
            case .valid: return .green
            case .error: return .red
            }
        }
        
        private var labelColor: Color {
            switch validationState {
            case .neutral: return isFocused ? .blue : .gray
            case .valid: return .green
            case .error: return .red
            }
        }
        
        private var validationColor: Color {
            switch validationState {
            case .valid: return .green
            case .error: return .red
            default: return .clear
            }
        }
        
        private var validationMessage: String {
            switch validationState {
            case .valid: return "✓ Valid input"
            case .error: return "✗ Please check your input"
            default: return ""
            }
        }
    }
    
    // MARK: - Animated Secure Field
    
    /// Secure text field with password visibility toggle
    public struct AnimatedSecureField: View {
        let placeholder: String
        let text: Binding<String>
        let validationState: ValidationState
        @State private var isFocused: Bool = false
        @State private var isPasswordVisible: Bool = false
        @State private var labelOffset: CGFloat = 0
        @State private var borderWidth: CGFloat = 1
        @State private var scale: CGFloat = 1.0
        @State private var eyeScale: CGFloat = 1.0
        
        public init(
            placeholder: String,
            text: Binding<String>,
            validationState: ValidationState = .neutral
        ) {
            self.placeholder = placeholder
            self.text = text
            self.validationState = validationState
        }
        
        public var body: some View {
            VStack(alignment: .leading, spacing: 4) {
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(borderColor, lineWidth: borderWidth)
                        )
                        .scaleEffect(scale)
                    
                    // Lock icon
                    Image(systemName: "lock.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(iconColor)
                        .padding(.leading, 16)
                        .opacity(isFocused || !text.wrappedValue.isEmpty ? 1.0 : 0.6)
                    
                    // Secure text field
                    Group {
                        if isPasswordVisible {
                            TextField("", text: text)
                        } else {
                            SecureField("", text: text)
                        }
                    }
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.primary)
                    .padding(.leading, 48)
                    .padding(.trailing, 48)
                    .padding(.vertical, 16)
                    .background(Color.clear)
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            isFocused = true
                            scale = 1.02
                            borderWidth = 2
                        }
                    }
                    
                    // Eye icon for password visibility
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            isPasswordVisible.toggle()
                            eyeScale = 0.8
                        }
                        
                        HapticManager.shared.impact(.light)
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                eyeScale = 1.0
                            }
                        }
                    }) {
                        Image(systemName: isPasswordVisible ? "eye.slash.fill" : "eye.fill")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.gray)
                            .scaleEffect(eyeScale)
                    }
                    .padding(.trailing, 16)
                }
                
                // Floating label
                Text(placeholder)
                    .font(.system(size: isFocused || !text.wrappedValue.isEmpty ? 12 : 16, weight: .medium))
                    .foregroundColor(labelColor)
                    .padding(.leading, 16)
                    .background(Color(.systemBackground))
                    .offset(y: labelOffset)
                    .scaleEffect(isFocused || !text.wrappedValue.isEmpty ? 0.9 : 1.0)
                
                // Validation message
                if validationState != .neutral {
                    Text(validationMessage)
                        .font(.caption)
                        .foregroundColor(validationColor)
                        .padding(.leading, 16)
                }
            }
            .onAppear {
                updateLabelPosition()
            }
            .onChange(of: isFocused) { _ in
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    updateLabelPosition()
                }
            }
            .onChange(of: text.wrappedValue) { _ in
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    updateLabelPosition()
                }
            }
        }
        
        private func updateLabelPosition() {
            labelOffset = isFocused || !text.wrappedValue.isEmpty ? -8 : 0
        }
        
        private var borderColor: Color {
            switch validationState {
            case .neutral: return isFocused ? .blue : .gray.opacity(0.3)
            case .valid: return .green
            case .error: return .red
            }
        }
        
        private var iconColor: Color {
            switch validationState {
            case .neutral: return isFocused ? .blue : .gray
            case .valid: return .green
            case .error: return .red
            }
        }
        
        private var labelColor: Color {
            switch validationState {
            case .neutral: return isFocused ? .blue : .gray
            case .valid: return .green
            case .error: return .red
            }
        }
        
        private var validationColor: Color {
            switch validationState {
            case .valid: return .green
            case .error: return .red
            default: return .clear
            }
        }
        
        private var validationMessage: String {
            switch validationState {
            case .valid: return "✓ Password is secure"
            case .error: return "✗ Password is too weak"
            default: return ""
            }
        }
    }
    
    // MARK: - Animated Picker
    
    /// Animated picker with smooth selection animations
    public struct AnimatedPicker<T: Hashable>: View {
        let title: String
        let options: [T]
        let selection: Binding<T>
        let optionTitle: (T) -> String
        @State private var isExpanded: Bool = false
        @State private var rotation: Double = 0
        @State private var scale: CGFloat = 1.0
        
        public init(
            title: String,
            options: [T],
            selection: Binding<T>,
            optionTitle: @escaping (T) -> String
        ) {
            self.title = title
            self.options = options
            self.selection = selection
            self.optionTitle = optionTitle
        }
        
        public var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                // Picker header
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isExpanded.toggle()
                        rotation += 180
                        scale = isExpanded ? 0.98 : 1.0
                    }
                    
                    HapticManager.shared.impact(.light)
                }) {
                    HStack {
                        Text(title)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Text(optionTitle(selection.wrappedValue))
                            .font(.system(size: 16, weight: .regular))
                            .foregroundColor(.secondary)
                        
                        Image(systemName: "chevron.down")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.gray)
                            .rotationEffect(.degrees(rotation))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray6))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                    )
                    .scaleEffect(scale)
                }
                .buttonStyle(PlainButtonStyle())
                
                // Options list
                if isExpanded {
                    VStack(spacing: 0) {
                        ForEach(Array(options.enumerated()), id: \.element) { index, option in
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    selection.wrappedValue = option
                                    isExpanded = false
                                    rotation += 180
                                    scale = 1.0
                                }
                                
                                HapticManager.shared.impact(.light)
                            }) {
                                HStack {
                                    Text(optionTitle(option))
                                        .font(.system(size: 16, weight: .regular))
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                    
                                    if selection.wrappedValue == option {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.blue)
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(selection.wrappedValue == option ? Color.blue.opacity(0.1) : Color.clear)
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            if index < options.count - 1 {
                                Divider()
                                    .padding(.leading, 16)
                            }
                        }
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemBackground))
                            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                    )
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.95).combined(with: .opacity),
                        removal: .scale(scale: 0.95).combined(with: .opacity)
                    ))
                }
            }
        }
    }
    
    // MARK: - Animated Checkbox
    
    /// Animated checkbox with smooth state transitions
    public struct AnimatedCheckbox: View {
        let title: String
        let isChecked: Binding<Bool>
        @State private var scale: CGFloat = 1.0
        @State private var checkmarkScale: CGFloat = 0
        @State private var rotation: Double = 0
        
        public init(
            title: String,
            isChecked: Binding<Bool>
        ) {
            self.title = title
            self.isChecked = isChecked
        }
        
        public var body: some View {
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    isChecked.wrappedValue.toggle()
                    scale = 0.9
                    rotation += 180
                }
                
                HapticManager.shared.impact(.light)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        scale = 1.0
                    }
                }
                
                // Animate checkmark
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7).delay(0.1)) {
                    checkmarkScale = isChecked.wrappedValue ? 1.0 : 0.0
                }
            }) {
                HStack(spacing: 12) {
                    // Checkbox
                    ZStack {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(isChecked.wrappedValue ? Color.blue : Color.clear)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(isChecked.wrappedValue ? Color.blue : Color.gray.opacity(0.5), lineWidth: 2)
                            )
                            .frame(width: 24, height: 24)
                            .scaleEffect(scale)
                            .rotationEffect(.degrees(rotation))
                        
                        if isChecked.wrappedValue {
                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                                .scaleEffect(checkmarkScale)
                        }
                    }
                    
                    Text(title)
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.primary)
                    
                    Spacer()
                }
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    // MARK: - Animated Slider
    
    /// Animated slider with smooth value changes
    public struct AnimatedSlider: View {
        let title: String
        let value: Binding<Double>
        let range: ClosedRange<Double>
        let step: Double
        @State private var isDragging: Bool = false
        @State private var scale: CGFloat = 1.0
        
        public init(
            title: String,
            value: Binding<Double>,
            range: ClosedRange<Double>,
            step: Double = 1.0
        ) {
            self.title = title
            self.value = value
            self.range = range
            self.step = step
        }
        
        public var body: some View {
            VStack(alignment: .leading, spacing: 12) {
                // Title and value
                HStack {
                    Text(title)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text("\(Int(value.wrappedValue))")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.blue)
                        .scaleEffect(isDragging ? 1.1 : 1.0)
                }
                
                // Slider
                ZStack(alignment: .leading) {
                    // Track
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 8)
                    
                    // Progress
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [Color.blue, Color.blue.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: progressWidth, height: 8)
                        .scaleEffect(scale)
                    
                    // Thumb
                    Circle()
                        .fill(Color.white)
                        .frame(width: 24, height: 24)
                        .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                        .offset(x: thumbOffset)
                        .scaleEffect(isDragging ? 1.2 : 1.0)
                        .gesture(
                            DragGesture()
                                .onChanged { gesture in
                                    isDragging = true
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        scale = 1.05
                                    }
                                    
                                    let newValue = calculateValue(from: gesture.location.x)
                                    value.wrappedValue = newValue
                                }
                                .onEnded { _ in
                                    isDragging = false
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        scale = 1.0
                                    }
                                    
                                    HapticManager.shared.impact(.light)
                                }
                        )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        
        private var progressWidth: CGFloat {
            let percentage = (value.wrappedValue - range.lowerBound) / (range.upperBound - range.lowerBound)
            return max(0, min(UIScreen.main.bounds.width - 64, percentage * (UIScreen.main.bounds.width - 64)))
        }
        
        private var thumbOffset: CGFloat {
            let percentage = (value.wrappedValue - range.lowerBound) / (range.upperBound - range.lowerBound)
            return max(0, min(UIScreen.main.bounds.width - 88, percentage * (UIScreen.main.bounds.width - 88)))
        }
        
        private func calculateValue(from x: CGFloat) -> Double {
            let percentage = max(0, min(1, x / (UIScreen.main.bounds.width - 64)))
            let value = range.lowerBound + (range.upperBound - range.lowerBound) * Double(percentage)
            return round(value / step) * step
        }
    }
}

// MARK: - Supporting Types

enum ValidationState {
    case neutral
    case valid
    case error
}

// MARK: - Preview

struct FormInputAnimations_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            AnimatedTextField(
                placeholder: "Enter your name",
                text: .constant(""),
                icon: "person.fill"
            )
            
            AnimatedSecureField(
                placeholder: "Enter password",
                text: .constant("")
            )
            
            AnimatedPicker(
                title: "Select option",
                options: ["Option 1", "Option 2", "Option 3"],
                selection: .constant("Option 1")
            ) { option in
                option
            }
            
            AnimatedCheckbox(
                title: "I agree to terms",
                isChecked: .constant(false)
            )
            
            AnimatedSlider(
                title: "Volume",
                value: .constant(50),
                range: 0...100
            )
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
} 
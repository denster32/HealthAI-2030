import SwiftUI

// MARK: - Color Palette
struct HealthAIColorPalette {
    static let primary = Color("PrimaryColor")
    static let secondary = Color("SecondaryColor")
    static let accent = Color("AccentColor")
    static let background = Color("BackgroundColor")
    static let surface = Color("SurfaceColor")
    static let error = Color("ErrorColor")
    static let success = Color("SuccessColor")
    static let warning = Color("WarningColor")
    static let info = Color("InfoColor")
}

// MARK: - Typography
struct HealthAITypography {
    static let heading = Font.system(size: 28, weight: .bold, design: .rounded)
    static let subheading = Font.system(size: 22, weight: .semibold, design: .rounded)
    static let body = Font.system(size: 17, weight: .regular, design: .rounded)
    static let caption = Font.system(size: 13, weight: .regular, design: .rounded)
    static let button = Font.system(size: 17, weight: .semibold, design: .rounded)
}

// MARK: - Spacing
struct HealthAISpacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
}

// MARK: - Button Styles
struct HealthAIButtonStyle: ButtonStyle {
    var color: Color = HealthAIColorPalette.primary
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(HealthAITypography.button)
            .padding(.vertical, HealthAISpacing.sm)
            .padding(.horizontal, HealthAISpacing.lg)
            .background(color)
            .foregroundColor(.white)
            .cornerRadius(12)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .accessibility(addTraits: .isButton)
    }
}

// MARK: - Card View
struct HealthAICard<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    var body: some View {
        content
            .padding(HealthAISpacing.md)
            .background(HealthAIColorPalette.surface)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
            .accessibilityElement(children: .contain)
    }
}

// MARK: - TextField Style
struct HealthAITextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<_Label>) -> some View {
        configuration
            .padding(HealthAISpacing.sm)
            .background(HealthAIColorPalette.background)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(HealthAIColorPalette.primary.opacity(0.2), lineWidth: 1)
            )
            .font(HealthAITypography.body)
            .accessibility(label: Text("Text Field"))
    }
}

// MARK: - Navigation Bar Modifier
struct HealthAINavigationBarModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(HealthAIColorPalette.primary, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
    }
}
extension View {
    func healthAINavigationBarStyle() -> some View {
        self.modifier(HealthAINavigationBarModifier())
    }
}

// MARK: - Responsive Layout
struct ResponsiveStack<Content: View>: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    let content: () -> Content
    var body: some View {
        Group {
            if horizontalSizeClass == .compact {
                VStack(alignment: .leading, spacing: HealthAISpacing.md, content: content)
            } else {
                HStack(alignment: .top, spacing: HealthAISpacing.lg, content: content)
            }
        }
    }
}

// MARK: - Accessibility Helpers
extension View {
    func healthAIAccessible(_ label: String, hint: String? = nil) -> some View {
        self.accessibility(label: Text(label))
            .accessibility(hint: Text(hint ?? ""))
    }
}

// MARK: - Example Usage
struct UserInterfaceDesignSystem_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            VStack(spacing: HealthAISpacing.lg) {
                Text("Welcome to HealthAI 2030")
                    .font(HealthAITypography.heading)
                    .foregroundColor(HealthAIColorPalette.primary)
                HealthAICard {
                    Text("This is a card component.")
                        .font(HealthAITypography.body)
                }
                Button("Get Started") {}
                    .buttonStyle(HealthAIButtonStyle())
                TextField("Enter your name", text: .constant(""))
                    .textFieldStyle(HealthAITextFieldStyle())
            }
            .padding()
            .healthAINavigationBarStyle()
        }
        .previewDevice("iPhone 15 Pro")
        .environment(\.colorScheme, .light)
    }
} 
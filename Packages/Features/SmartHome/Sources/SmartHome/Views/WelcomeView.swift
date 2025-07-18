import SwiftUI

/// Example of a highly polished, accessible, and localized view
struct WelcomeView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "heart.fill")
                .resizable()
                .frame(width: 60, height: 60)
                .foregroundColor(.red)
            Text(NSLocalizedString("welcome_title", comment: "Welcome title"))
                .font(.largeTitle)
                .bold()
                .dynamicTypeSize(.xSmall ... .xxxLarge)
            Text(NSLocalizedString("welcome_message", comment: "Welcome message"))
                .font(.body)
                .multilineTextAlignment(.center)
        }
        .padding()
        .modifier(AccessibilityModifier())
    }
}

struct AccessibilityModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .accessibilityElement(children: .combine)
            .accessibilityLabel(Text("Welcome to HealthAI 2030. Your health, your data, your future."))
            .accessibilityHint(Text("This is the welcome screen. Swipe right to continue."))
    }
}

struct WelcomeView_Previews: PreviewProvider {
    static var previews: some View {
        WelcomeView()
    }
}

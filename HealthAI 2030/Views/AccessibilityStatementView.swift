import SwiftUI

/// Accessibility statement for HealthAI 2030
struct AccessibilityStatementView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Accessibility Statement")
                    .font(.title2)
                    .bold()
                Text("HealthAI 2030 is committed to providing a fully accessible experience for all users. We support VoiceOver, Dynamic Type, high contrast, and other accessibility features across all platforms. If you encounter any accessibility issues, please contact our support team.")
            }
            .padding()
        }
        .navigationTitle("Accessibility")
    }
}

struct AccessibilityStatementView_Previews: PreviewProvider {
    static var previews: some View {
        AccessibilityStatementView()
    }
}

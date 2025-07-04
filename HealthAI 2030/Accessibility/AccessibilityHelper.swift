import SwiftUI

/// Accessibility helper for HealthAI 2030
public struct AccessibilityHelper {
    public static func applyAccessibility(to view: some View, label: String, hint: String? = nil) -> some View {
        view.accessibilityLabel(Text(label))
            .accessibilityHint(Text(hint ?? ""))
    }
}

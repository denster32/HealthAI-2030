import SwiftUI

public struct HealthAIAccessibility {
    public static func enableVoiceOver(_ view: some View) -> some View {
        view.accessibilityElement(children: .contain)
    }
    public static func enableDynamicType(_ view: some View) -> some View {
        view.environment(\.sizeCategory, .large)
    }
    public static func enableHighContrast(_ view: some View) -> some View {
        view.environment(\.accessibilityContrast, .increased)
    }
    public static func enableReducedMotion(_ view: some View) -> some View {
        view.environment(\.accessibilityReduceMotion, true)
    }
    public static func enableSwitchControl(_ view: some View) -> some View {
        view.accessibilityRespondsToUserInteraction(true)
    }
    public static func optimizeForScreenReader(_ view: some View) -> some View {
        view.accessibilitySortPriority(1)
    }
}

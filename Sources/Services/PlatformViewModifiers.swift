import SwiftUI
import HealthKit

// PlatformViewModifiers.swift
struct PlatformViewModifiers: ViewModifier {
    #if os(tvOS)
    func body(content: Content) -> some View {
        content
            .focusable() // Make views focusable for remote interaction
            .onMoveCommand { direction in
                // Handle remote navigation
            }
    }
    #elseif os(watchOS)
    func body(content: Content) -> some View {
        content
            .digitalCrownRotation($0, from: /* range */, by: /* sensitivity */) // Enable digital crown interaction
            .environment(\.isLuminanceReduced, true) // Optimize for glanceable interfaces
    }
    #elseif os(macOS)
    func body(content: Content) -> some View {
        content
            .onMoveCommand { direction in
                // Handle keyboard navigation
            }
    }
    #else
    func body(content: Content) -> some View {
        content
    }
    #endif
}
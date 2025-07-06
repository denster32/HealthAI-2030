# HealthAI2030UI Public API Documentation

All public types, properties, and methods in this package must be documented using Swift's documentation comments (///).

## Example

/// A custom button for HealthAI 2030 with accessibility support.
public struct HealthAIButton: View {
    /// The button's title.
    public var title: String
    /// The button style (primary, secondary, tertiary).
    public var style: Style
    /// The action to perform when tapped.
    public var action: () -> Void
    /// The button's body.
    public var body: some View { ... }
}

---

> All new code must follow this documentation standard.

import SwiftUI

// MARK: - High Contrast Theme Manager
/// Comprehensive high contrast theme support for HealthAI 2030
/// Provides medical-grade contrast ratios, healthcare-optimized color schemes, and accessibility-focused design patterns
public class HighContrastThemeManager: ObservableObject {
    
    @Published public var isHighContrastEnabled: Bool = false
    @Published public var isDarkModeEnabled: Bool = false
    @Published public var contrastLevel: ContrastLevel = .standard
    @Published public var medicalContrastMode: Bool = false
    
    public static let shared = HighContrastThemeManager()
    
    private init() {
        setupThemeObserver()
        checkCurrentTheme()
    }
    
    /// Setup observer for theme changes
    private func setupThemeObserver() {
        NotificationCenter.default.addObserver(
            forName: UIAccessibility.highContrastDidChangeNotification,
            object: nil,
            queue: .main
        ) { _ in
            self.handleHighContrastChange()
        }
        
        NotificationCenter.default.addObserver(
            forName: UIAccessibility.darkerSystemColorsDidChangeNotification,
            object: nil,
            queue: .main
        ) { _ in
            self.handleDarkModeChange()
        }
    }
    
    /// Check current theme settings
    private func checkCurrentTheme() {
        isHighContrastEnabled = UIAccessibility.isHighContrastEnabled
        isDarkModeEnabled = UIAccessibility.isDarkerSystemColorsEnabled
        updateContrastLevel()
    }
    
    /// Handle high contrast setting changes
    private func handleHighContrastChange() {
        isHighContrastEnabled = UIAccessibility.isHighContrastEnabled
        updateContrastLevel()
        objectWillChange.send()
    }
    
    /// Handle dark mode setting changes
    private func handleDarkModeChange() {
        isDarkModeEnabled = UIAccessibility.isDarkerSystemColorsEnabled
        updateContrastLevel()
        objectWillChange.send()
    }
    
    /// Update contrast level based on current settings
    private func updateContrastLevel() {
        if isHighContrastEnabled {
            contrastLevel = .high
        } else if medicalContrastMode {
            contrastLevel = .medical
        } else {
            contrastLevel = .standard
        }
    }
    
    /// Enable medical contrast mode
    public func enableMedicalContrastMode() {
        medicalContrastMode = true
        updateContrastLevel()
    }
    
    /// Disable medical contrast mode
    public func disableMedicalContrastMode() {
        medicalContrastMode = false
        updateContrastLevel()
    }
}

// MARK: - Contrast Level
public enum ContrastLevel {
    case standard
    case high
    case medical
    case maximum
    
    var description: String {
        switch self {
        case .standard:
            return "Standard contrast"
        case .high:
            return "High contrast"
        case .medical:
            return "Medical contrast"
        case .maximum:
            return "Maximum contrast"
        }
    }
    
    var minimumRatio: CGFloat {
        switch self {
        case .standard:
            return 4.5 // WCAG AA
        case .high:
            return 7.0 // WCAG AAA
        case .medical:
            return 8.0 // Medical grade
        case .maximum:
            return 10.0 // Maximum accessibility
        }
    }
}

// MARK: - High Contrast Color Palette
public struct HighContrastColorPalette {
    
    // MARK: - Primary Colors
    public static func primary(level: ContrastLevel = .standard) -> Color {
        switch level {
        case .standard:
            return ColorPalette.primary
        case .high:
            return Color(red: 0.0, green: 0.4, blue: 0.8)
        case .medical:
            return Color(red: 0.0, green: 0.3, blue: 0.7)
        case .maximum:
            return Color(red: 0.0, green: 0.2, blue: 0.6)
        }
    }
    
    public static func secondary(level: ContrastLevel = .standard) -> Color {
        switch level {
        case .standard:
            return ColorPalette.secondary
        case .high:
            return Color(red: 0.2, green: 0.7, blue: 0.4)
        case .medical:
            return Color(red: 0.1, green: 0.6, blue: 0.3)
        case .maximum:
            return Color(red: 0.0, green: 0.5, blue: 0.2)
        }
    }
    
    // MARK: - Semantic Colors
    public static func success(level: ContrastLevel = .standard) -> Color {
        switch level {
        case .standard:
            return ColorPalette.success
        case .high:
            return Color(red: 0.0, green: 0.6, blue: 0.0)
        case .medical:
            return Color(red: 0.0, green: 0.5, blue: 0.0)
        case .maximum:
            return Color(red: 0.0, green: 0.4, blue: 0.0)
        }
    }
    
    public static func warning(level: ContrastLevel = .standard) -> Color {
        switch level {
        case .standard:
            return ColorPalette.warning
        case .high:
            return Color(red: 0.8, green: 0.4, blue: 0.0)
        case .medical:
            return Color(red: 0.7, green: 0.3, blue: 0.0)
        case .maximum:
            return Color(red: 0.6, green: 0.2, blue: 0.0)
        }
    }
    
    public static func critical(level: ContrastLevel = .standard) -> Color {
        switch level {
        case .standard:
            return ColorPalette.critical
        case .high:
            return Color(red: 0.8, green: 0.0, blue: 0.0)
        case .medical:
            return Color(red: 0.7, green: 0.0, blue: 0.0)
        case .maximum:
            return Color(red: 0.6, green: 0.0, blue: 0.0)
        }
    }
    
    // MARK: - Background Colors
    public static func background(level: ContrastLevel = .standard, isDark: Bool = false) -> Color {
        if isDark {
            switch level {
            case .standard:
                return Color(red: 0.1, green: 0.1, blue: 0.1)
            case .high:
                return Color.black
            case .medical:
                return Color.black
            case .maximum:
                return Color.black
            }
        } else {
            switch level {
            case .standard:
                return ColorPalette.background
            case .high:
                return Color.white
            case .medical:
                return Color.white
            case .maximum:
                return Color.white
            }
        }
    }
    
    public static func surface(level: ContrastLevel = .standard, isDark: Bool = false) -> Color {
        if isDark {
            switch level {
            case .standard:
                return Color(red: 0.2, green: 0.2, blue: 0.2)
            case .high:
                return Color(red: 0.1, green: 0.1, blue: 0.1)
            case .medical:
                return Color(red: 0.05, green: 0.05, blue: 0.05)
            case .maximum:
                return Color.black
            }
        } else {
            switch level {
            case .standard:
                return ColorPalette.surface
            case .high:
                return Color(red: 0.95, green: 0.95, blue: 0.95)
            case .medical:
                return Color(red: 0.98, green: 0.98, blue: 0.98)
            case .maximum:
                return Color.white
            }
        }
    }
    
    // MARK: - Text Colors
    public static func textPrimary(level: ContrastLevel = .standard, isDark: Bool = false) -> Color {
        if isDark {
            switch level {
            case .standard:
                return Color.white
            case .high:
                return Color.white
            case .medical:
                return Color.white
            case .maximum:
                return Color.white
            }
        } else {
            switch level {
            case .standard:
                return ColorPalette.textPrimary
            case .high:
                return Color.black
            case .medical:
                return Color.black
            case .maximum:
                return Color.black
            }
        }
    }
    
    public static func textSecondary(level: ContrastLevel = .standard, isDark: Bool = false) -> Color {
        if isDark {
            switch level {
            case .standard:
                return Color(red: 0.8, green: 0.8, blue: 0.8)
            case .high:
                return Color.white
            case .medical:
                return Color.white
            case .maximum:
                return Color.white
            }
        } else {
            switch level {
            case .standard:
                return ColorPalette.textSecondary
            case .high:
                return Color.black
            case .medical:
                return Color.black
            case .maximum:
                return Color.black
            }
        }
    }
    
    // MARK: - Border Colors
    public static func border(level: ContrastLevel = .standard, isDark: Bool = false) -> Color {
        if isDark {
            switch level {
            case .standard:
                return Color(red: 0.3, green: 0.3, blue: 0.3)
            case .high:
                return Color.white
            case .medical:
                return Color.white
            case .maximum:
                return Color.white
            }
        } else {
            switch level {
            case .standard:
                return ColorPalette.border
            case .high:
                return Color.black
            case .medical:
                return Color.black
            case .maximum:
                return Color.black
            }
        }
    }
}

// MARK: - High Contrast View Modifiers
public extension View {
    
    /// Apply high contrast theme support
    func highContrastThemeSupport() -> some View {
        self.modifier(HighContrastThemeModifier())
    }
    
    /// Apply medical contrast theme support
    func medicalContrastThemeSupport() -> some View {
        self.modifier(MedicalContrastThemeModifier())
    }
    
    /// Apply maximum contrast theme support
    func maximumContrastThemeSupport() -> some View {
        self.modifier(MaximumContrastThemeModifier())
    }
    
    /// Apply adaptive contrast based on content type
    func adaptiveContrastSupport(contentType: ContentType = .general) -> some View {
        self.modifier(AdaptiveContrastModifier(contentType: contentType))
    }
}

// MARK: - Content Type
public enum ContentType {
    case general
    case medical
    case critical
    case navigation
    case form
    case data
    
    var contrastLevel: ContrastLevel {
        switch self {
        case .general:
            return .standard
        case .medical:
            return .medical
        case .critical:
            return .maximum
        case .navigation:
            return .high
        case .form:
            return .high
        case .data:
            return .medical
        }
    }
}

// MARK: - High Contrast Theme Modifier
public struct HighContrastThemeModifier: ViewModifier {
    
    @ObservedObject private var themeManager = HighContrastThemeManager.shared
    
    public func body(content: Content) -> some View {
        content
            .foregroundColor(getTextColor())
            .background(getBackgroundColor())
            .accentColor(getAccentColor())
    }
    
    private func getTextColor() -> Color {
        return HighContrastColorPalette.textPrimary(
            level: themeManager.contrastLevel,
            isDark: themeManager.isDarkModeEnabled
        )
    }
    
    private func getBackgroundColor() -> Color {
        return HighContrastColorPalette.background(
            level: themeManager.contrastLevel,
            isDark: themeManager.isDarkModeEnabled
        )
    }
    
    private func getAccentColor() -> Color {
        return HighContrastColorPalette.primary(
            level: themeManager.contrastLevel
        )
    }
}

// MARK: - Medical Contrast Theme Modifier
public struct MedicalContrastThemeModifier: ViewModifier {
    
    @ObservedObject private var themeManager = HighContrastThemeManager.shared
    
    public func body(content: Content) -> some View {
        content
            .foregroundColor(getMedicalTextColor())
            .background(getMedicalBackgroundColor())
            .accentColor(getMedicalAccentColor())
    }
    
    private func getMedicalTextColor() -> Color {
        return HighContrastColorPalette.textPrimary(
            level: .medical,
            isDark: themeManager.isDarkModeEnabled
        )
    }
    
    private func getMedicalBackgroundColor() -> Color {
        return HighContrastColorPalette.background(
            level: .medical,
            isDark: themeManager.isDarkModeEnabled
        )
    }
    
    private func getMedicalAccentColor() -> Color {
        return HighContrastColorPalette.primary(level: .medical)
    }
}

// MARK: - Maximum Contrast Theme Modifier
public struct MaximumContrastThemeModifier: ViewModifier {
    
    @ObservedObject private var themeManager = HighContrastThemeManager.shared
    
    public func body(content: Content) -> some View {
        content
            .foregroundColor(getMaximumTextColor())
            .background(getMaximumBackgroundColor())
            .accentColor(getMaximumAccentColor())
    }
    
    private func getMaximumTextColor() -> Color {
        return HighContrastColorPalette.textPrimary(
            level: .maximum,
            isDark: themeManager.isDarkModeEnabled
        )
    }
    
    private func getMaximumBackgroundColor() -> Color {
        return HighContrastColorPalette.background(
            level: .maximum,
            isDark: themeManager.isDarkModeEnabled
        )
    }
    
    private func getMaximumAccentColor() -> Color {
        return HighContrastColorPalette.primary(level: .maximum)
    }
}

// MARK: - Adaptive Contrast Modifier
public struct AdaptiveContrastModifier: ViewModifier {
    
    let contentType: ContentType
    @ObservedObject private var themeManager = HighContrastThemeManager.shared
    
    public init(contentType: ContentType) {
        self.contentType = contentType
    }
    
    public func body(content: Content) -> some View {
        content
            .foregroundColor(getAdaptiveTextColor())
            .background(getAdaptiveBackgroundColor())
            .accentColor(getAdaptiveAccentColor())
    }
    
    private func getAdaptiveTextColor() -> Color {
        let level = max(themeManager.contrastLevel, contentType.contrastLevel)
        return HighContrastColorPalette.textPrimary(
            level: level,
            isDark: themeManager.isDarkModeEnabled
        )
    }
    
    private func getAdaptiveBackgroundColor() -> Color {
        let level = max(themeManager.contrastLevel, contentType.contrastLevel)
        return HighContrastColorPalette.background(
            level: level,
            isDark: themeManager.isDarkModeEnabled
        )
    }
    
    private func getAdaptiveAccentColor() -> Color {
        let level = max(themeManager.contrastLevel, contentType.contrastLevel)
        return HighContrastColorPalette.primary(level: level)
    }
}

// MARK: - High Contrast Testing Utilities
public extension HighContrastThemeManager {
    
    /// Test contrast ratio between two colors
    func testContrastRatio(foreground: Color, background: Color) -> CGFloat {
        // Simplified contrast calculation
        // In a real implementation, this would use proper luminance calculations
        return 4.5 // Placeholder value
    }
    
    /// Test if colors meet contrast requirements
    func meetsContrastRequirements(foreground: Color, background: Color) -> Bool {
        let ratio = testContrastRatio(foreground: foreground, background: background)
        return ratio >= contrastLevel.minimumRatio
    }
    
    /// Get current theme description
    func getCurrentThemeDescription() -> String {
        var description = "Theme: "
        
        if isHighContrastEnabled {
            description += "High Contrast"
        } else if medicalContrastMode {
            description += "Medical Contrast"
        } else {
            description += "Standard"
        }
        
        if isDarkModeEnabled {
            description += ", Dark Mode"
        } else {
            description += ", Light Mode"
        }
        
        return description
    }
    
    /// Test theme accessibility
    func testThemeAccessibility() -> [String] {
        var issues: [String] = []
        
        if !isHighContrastEnabled && !medicalContrastMode {
            issues.append("Consider enabling high contrast for better accessibility")
        }
        
        if contrastLevel.minimumRatio < 7.0 {
            issues.append("Consider increasing contrast ratio for medical applications")
        }
        
        return issues
    }
}

// MARK: - High Contrast Configuration
public extension HighContrastThemeManager {
    
    /// Configure high contrast settings
    func configureHighContrastSettings(
        medicalContrastMode: Bool = false,
        autoDetectHighContrast: Bool = true
    ) {
        self.medicalContrastMode = medicalContrastMode
        updateContrastLevel()
    }
    
    /// Reset high contrast settings to defaults
    func resetHighContrastSettings() {
        configureHighContrastSettings()
    }
} 
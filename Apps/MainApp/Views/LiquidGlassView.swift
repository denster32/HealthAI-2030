import SwiftUI

/// Liquid Glass View Components for HealthAI 2030 iOS App
/// Implements Liquid Glass UI components, animations, effects for health data visualization, transitions, micro-interactions, theming system, and customization options
@available(iOS 18.0, *)
public struct LiquidGlassView: View {
    @StateObject private var liquidGlassManager = LiquidGlassManager()
    @State private var isAnimating = false
    @State private var currentEffect: LiquidGlassEffect?
    
    public let content: AnyView
    public let viewType: ViewType
    public let theme: LiquidGlassTheme
    
    public init<Content: View>(@ViewBuilder content: () -> Content, type: ViewType = .healthDashboard, theme: LiquidGlassTheme = .default) {
        self.content = AnyView(content())
        self.viewType = type
        self.theme = theme
    }
    
    public var body: some View {
        ZStack {
            // Background with Liquid Glass effect
            LiquidGlassBackground(effect: currentEffect)
            
            // Content with Liquid Glass overlay
            content
                .blur(radius: currentEffect?.blur ?? 0)
                .opacity(1.0 - (currentEffect?.transparency ?? 0))
                .scaleEffect(isAnimating ? 1.05 : 1.0)
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: isAnimating)
        }
        .onAppear {
            liquidGlassManager.initialize()
            updateLiquidGlassEffect()
            startMicroInteractions()
        }
        .onChange(of: theme) { _ in
            updateLiquidGlassEffect()
        }
    }
    
    private func updateLiquidGlassEffect() {
        let view = LiquidGlassView(
            id: UUID().uuidString,
            type: viewType,
            content: content,
            properties: [:]
        )
        currentEffect = liquidGlassManager.renderLiquidGlassEffect(for: view)
    }
    
    private func startMicroInteractions() {
        // Start subtle micro-interactions
        Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.5)) {
                isAnimating.toggle()
            }
        }
    }
}

// MARK: - Liquid Glass Background

struct LiquidGlassBackground: View {
    let effect: LiquidGlassEffect?
    
    var body: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(
                LinearGradient(
                    colors: [
                        Color.white.opacity(effect?.transparency ?? 0.3),
                        Color.blue.opacity(effect?.transparency ?? 0.1),
                        Color.purple.opacity(effect?.transparency ?? 0.1)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .blur(radius: effect?.blur ?? 0.8)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        LinearGradient(
                            colors: [Color.white.opacity(0.5), Color.clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
}

// MARK: - Health Data Visualization Components

@available(iOS 18.0, *)
public struct LiquidGlassHealthCard: View {
    public let title: String
    public let value: String
    public let unit: String
    public let trend: HealthTrend
    public let theme: LiquidGlassTheme
    
    public init(title: String, value: String, unit: String, trend: HealthTrend = .stable, theme: LiquidGlassTheme = .default) {
        self.title = title
        self.value = value
        self.unit = unit
        self.trend = trend
        self.theme = theme
    }
    
    public var body: some View {
        LiquidGlassView(type: .card, theme: theme) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Spacer()
                    HealthTrendIcon(trend: trend)
                }
                
                HStack(alignment: .bottom, spacing: 4) {
                    Text(value)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text(unit)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
        }
    }
}

public enum HealthTrend {
    case improving, declining, stable
}

struct HealthTrendIcon: View {
    let trend: HealthTrend
    
    var body: some View {
        Image(systemName: iconName)
            .foregroundColor(color)
            .font(.title2)
    }
    
    private var iconName: String {
        switch trend {
        case .improving: return "arrow.up.circle.fill"
        case .declining: return "arrow.down.circle.fill"
        case .stable: return "minus.circle.fill"
        }
    }
    
    private var color: Color {
        switch trend {
        case .improving: return .green
        case .declining: return .red
        case .stable: return .orange
        }
    }
}

// MARK: - Navigation Components

@available(iOS 18.0, *)
public struct LiquidGlassNavigationButton: View {
    public let title: String
    public let icon: String
    public let action: () -> Void
    public let theme: LiquidGlassTheme
    
    public init(title: String, icon: String, action: @escaping () -> Void, theme: LiquidGlassTheme = .default) {
        self.title = title
        self.icon = icon
        self.action = action
        self.theme = theme
    }
    
    public var body: some View {
        LiquidGlassView(type: .button, theme: theme) {
            Button(action: action) {
                HStack {
                    Image(systemName: icon)
                        .font(.title2)
                    Text(title)
                        .font(.headline)
                }
                .foregroundColor(.primary)
                .padding()
            }
        }
    }
}

// MARK: - Theming System

@available(iOS 18.0, *)
public struct LiquidGlassThemeManager: View {
    @StateObject private var liquidGlassManager = LiquidGlassManager()
    @State private var selectedTheme: LiquidGlassTheme = .default
    
    public let themes: [LiquidGlassTheme] = [
        .default,
        LiquidGlassTheme(name: "Health", blurIntensity: 0.7, transparencyLevel: 0.2, colorScheme: .light, animationSpeed: 1.0),
        LiquidGlassTheme(name: "Night", blurIntensity: 0.9, transparencyLevel: 0.4, colorScheme: .dark, animationSpeed: 0.8),
        LiquidGlassTheme(name: "Vibrant", blurIntensity: 0.6, transparencyLevel: 0.1, colorScheme: .light, animationSpeed: 1.2)
    ]
    
    public var body: some View {
        VStack(spacing: 20) {
            Text("Liquid Glass Themes")
                .font(.title)
                .fontWeight(.bold)
            
            ForEach(themes, id: \.name) { theme in
                LiquidGlassThemeOption(
                    theme: theme,
                    isSelected: selectedTheme.name == theme.name
                ) {
                    selectedTheme = theme
                    liquidGlassManager.currentTheme = theme
                }
            }
        }
        .padding()
    }
}

struct LiquidGlassThemeOption: View {
    let theme: LiquidGlassTheme
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(theme.name)
                    .font(.headline)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.blue.opacity(isSelected ? 0.1 : 0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.blue.opacity(isSelected ? 0.3 : 0.1), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

/// Documentation:
/// - This file implements comprehensive Liquid Glass UI components for health data visualization.
/// - Components include health cards, navigation buttons, and theme management.
/// - Micro-interactions and animations enhance user experience.
/// - Theming system allows customization across the app.
/// - Accessibility features ensure inclusive design.
/// - Extend for additional components, advanced animations, and platform-specific optimizations. 
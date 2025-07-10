import SwiftUI

// MARK: - Unified Button System
public struct HealthAIButton: View {
    public enum Style {
        case primary, secondary, tertiary, destructive
    }
    
    let title: String
    let style: Style
    let isLoading: Bool
    let icon: String?
    let action: () -> Void
    
    public init(title: String, style: Style = .primary, isLoading: Bool = false, icon: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.style = style
        self.isLoading = isLoading
        self.icon = icon
        self.action = action
    }
    
    public var body: some View {
        Button(action: action) {
            HStack(spacing: HealthAIDesignSystem.Spacing.sm) {
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                        .progressViewStyle(CircularProgressViewStyle(tint: buttonTextColor))
                } else if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: HealthAIDesignSystem.Layout.iconSizeSmall, weight: .medium))
                        .foregroundColor(buttonTextColor)
                }
                
                Text(title)
                    .font(HealthAIDesignSystem.Typography.headline)
                    .foregroundColor(buttonTextColor)
            }
            .frame(maxWidth: .infinity)
            .frame(height: HealthAIDesignSystem.Layout.buttonHeight)
            .padding(.horizontal, HealthAIDesignSystem.Spacing.lg)
            .background(buttonBackground)
            .cornerRadius(HealthAIDesignSystem.Layout.cornerRadius)
            .shadow(radius: HealthAIDesignSystem.Layout.shadowRadiusSmall)
        }
        .disabled(isLoading)
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(HealthAIDesignSystem.Layout.animationSpring, value: isPressed)
    }
    
    @State private var isPressed = false
    
    private var buttonBackground: some View {
        switch style {
        case .primary:
            return LinearGradient(
                colors: [HealthAIDesignSystem.Colors.primary, HealthAIDesignSystem.Colors.primary.opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .secondary:
            return RoundedRectangle(cornerRadius: HealthAIDesignSystem.Layout.cornerRadius)
                .fill(HealthAIDesignSystem.Colors.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: HealthAIDesignSystem.Layout.cornerRadius)
                        .stroke(HealthAIDesignSystem.Colors.primary, lineWidth: 1)
                )
        case .tertiary:
            return Color.clear
        case .destructive:
            return LinearGradient(
                colors: [HealthAIDesignSystem.Colors.error, HealthAIDesignSystem.Colors.error.opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    private var buttonTextColor: Color {
        switch style {
        case .primary, .destructive:
            return .white
        case .secondary, .tertiary:
            return HealthAIDesignSystem.Colors.primary
        }
    }
}

// MARK: - Unified Card System
public struct HealthAICard<Content: View>: View {
    let content: Content
    let style: CardStyle
    let padding: CGFloat
    
    public enum CardStyle {
        case standard, elevated, outlined, glass
    }
    
    public init(style: CardStyle = .standard, padding: CGFloat = HealthAIDesignSystem.Spacing.lg, @ViewBuilder content: () -> Content) {
        self.style = style
        self.padding = padding
        self.content = content()
    }
    
    public var body: some View {
        content
            .padding(padding)
            .background(cardBackground)
            .cornerRadius(HealthAIDesignSystem.Layout.cornerRadius)
    }
    
    private var cardBackground: some View {
        switch style {
        case .standard:
            return RoundedRectangle(cornerRadius: HealthAIDesignSystem.Layout.cornerRadius)
                .fill(HealthAIDesignSystem.Colors.card)
                .shadow(radius: HealthAIDesignSystem.Layout.shadowRadiusSmall)
        case .elevated:
            return RoundedRectangle(cornerRadius: HealthAIDesignSystem.Layout.cornerRadius)
                .fill(HealthAIDesignSystem.Colors.card)
                .shadow(radius: HealthAIDesignSystem.Layout.shadowRadius)
        case .outlined:
            return RoundedRectangle(cornerRadius: HealthAIDesignSystem.Layout.cornerRadius)
                .fill(HealthAIDesignSystem.Colors.card)
                .overlay(
                    RoundedRectangle(cornerRadius: HealthAIDesignSystem.Layout.cornerRadius)
                        .stroke(HealthAIDesignSystem.Colors.border, lineWidth: 1)
                )
        case .glass:
            return RoundedRectangle(cornerRadius: HealthAIDesignSystem.Layout.cornerRadius)
                .fill(HealthAIDesignSystem.Colors.card.opacity(0.8))
                .background(.ultraThinMaterial)
                .shadow(radius: HealthAIDesignSystem.Layout.shadowRadiusSmall)
        }
    }
}

// MARK: - Health Metric Card
public struct HealthMetricCard: View {
    let title: String
    let value: String
    let unit: String
    let color: Color
    let icon: String
    let trend: String?
    let status: HealthStatus
    let subtitle: String?
    
    public init(title: String, value: String, unit: String, color: Color, icon: String, trend: String? = nil, status: HealthStatus = .unknown, subtitle: String? = nil) {
        self.title = title
        self.value = value
        self.unit = unit
        self.color = color
        self.icon = icon
        self.trend = trend
        self.status = status
        self.subtitle = subtitle
    }
    
    public var body: some View {
        HealthAICard(style: .elevated) {
            VStack(alignment: .leading, spacing: HealthAIDesignSystem.Spacing.md) {
                // Header
                HStack {
                    Image(systemName: icon)
                        .foregroundColor(color)
                        .font(.system(size: HealthAIDesignSystem.Layout.iconSize, weight: .medium))
                    
                    Text(title)
                        .font(HealthAIDesignSystem.Typography.metricLabel)
                        .foregroundColor(HealthAIDesignSystem.Colors.textPrimary)
                    
                    Spacer()
                    
                    // Status indicator
                    Circle()
                        .fill(Color.healthStatus(status))
                        .frame(width: 8, height: 8)
                }
                
                // Value
                HStack(alignment: .bottom, spacing: HealthAIDesignSystem.Spacing.xs) {
                    Text(value)
                        .font(HealthAIDesignSystem.Typography.metricValue)
                        .fontWeight(.bold)
                        .foregroundColor(HealthAIDesignSystem.Colors.textPrimary)
                    
                    Text(unit)
                        .font(HealthAIDesignSystem.Typography.metricUnit)
                        .foregroundColor(HealthAIDesignSystem.Colors.textSecondary)
                }
                
                // Subtitle
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(HealthAIDesignSystem.Typography.caption1)
                        .foregroundColor(HealthAIDesignSystem.Colors.textSecondary)
                }
                
                // Trend
                if let trend = trend {
                    HStack {
                        Image(systemName: trendIcon)
                            .foregroundColor(trendColor)
                            .font(.caption)
                        
                        Text(trend)
                            .font(HealthAIDesignSystem.Typography.caption1)
                            .foregroundColor(trendColor)
                        
                        Spacer()
                    }
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value) \(unit)")
        .accessibilityValue(trend ?? "")
        .accessibilityHint("Double tap to view detailed \(title) information")
        .accessibilityAddTraits(.isButton)
    }
    
    private var trendIcon: String {
        guard let trend = trend else { return "" }
        if trend.contains("+") || trend.contains("up") {
            return "arrow.up.right"
        } else if trend.contains("-") || trend.contains("down") {
            return "arrow.down.right"
        } else {
            return "arrow.right"
        }
    }
    
    private var trendColor: Color {
        guard let trend = trend else { return HealthAIDesignSystem.Colors.textSecondary }
        if trend.contains("+") || trend.contains("up") {
            return HealthAIDesignSystem.Colors.success
        } else if trend.contains("-") || trend.contains("down") {
            return HealthAIDesignSystem.Colors.error
        } else {
            return HealthAIDesignSystem.Colors.textSecondary
        }
    }
}

// MARK: - Progress Indicator
public struct HealthAIProgressView: View {
    let value: Float
    let maxValue: Float
    let color: Color
    let showLabel: Bool
    let label: String?
    
    @State private var animatedValue: Float = 0
    
    public init(value: Float, maxValue: Float = 1.0, color: Color = HealthAIDesignSystem.Colors.primary, showLabel: Bool = true, label: String? = nil) {
        self.value = value
        self.maxValue = maxValue
        self.color = color
        self.showLabel = showLabel
        self.label = label
    }
    
    public var body: some View {
        VStack(spacing: HealthAIDesignSystem.Spacing.xs) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background track
                    RoundedRectangle(cornerRadius: HealthAIDesignSystem.Layout.cornerRadiusSmall)
                        .fill(HealthAIDesignSystem.Colors.textTertiary.opacity(0.2))
                        .frame(height: 8)
                    
                    // Progress bar
                    RoundedRectangle(cornerRadius: HealthAIDesignSystem.Layout.cornerRadiusSmall)
                        .fill(
                            LinearGradient(
                                colors: [color, color.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * CGFloat(animatedValue / maxValue), height: 8)
                        .animation(HealthAIDesignSystem.Layout.animationEaseInOut, value: animatedValue)
                }
            }
            .frame(height: 8)
            
            if showLabel {
                HStack {
                    if let label = label {
                        Text(label)
                            .font(HealthAIDesignSystem.Typography.caption1)
                            .foregroundColor(HealthAIDesignSystem.Colors.textSecondary)
                    }
                    
                    Spacer()
                    
                    Text("\(Int(animatedValue * 100))%")
                        .font(HealthAIDesignSystem.Typography.caption1)
                        .fontWeight(.medium)
                        .foregroundColor(HealthAIDesignSystem.Colors.textPrimary)
                }
            }
        }
        .onAppear {
            withAnimation(HealthAIDesignSystem.Layout.animationEaseInOut.delay(0.1)) {
                animatedValue = value
            }
        }
        .onChange(of: value) { newValue in
            withAnimation(HealthAIDesignSystem.Layout.animationEaseInOut) {
                animatedValue = newValue
            }
        }
    }
}

// MARK: - Loading States
public struct HealthAILoadingView: View {
    let message: String
    let showProgress: Bool
    
    public init(message: String = "Loading...", showProgress: Bool = false) {
        self.message = message
        self.showProgress = showProgress
    }
    
    public var body: some View {
        VStack(spacing: HealthAIDesignSystem.Spacing.lg) {
            if showProgress {
                ProgressView()
                    .scaleEffect(1.2)
                    .progressViewStyle(CircularProgressViewStyle(tint: HealthAIDesignSystem.Colors.primary))
            } else {
                ProgressView()
                    .scaleEffect(1.2)
                    .progressViewStyle(CircularProgressViewStyle(tint: HealthAIDesignSystem.Colors.primary))
            }
            
            Text(message)
                .font(HealthAIDesignSystem.Typography.body)
                .foregroundColor(HealthAIDesignSystem.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(HealthAIDesignSystem.Spacing.xl)
    }
}

// MARK: - Empty State
public struct HealthAIEmptyState: View {
    let icon: String
    let title: String
    let message: String
    let actionTitle: String?
    let action: (() -> Void)?
    
    public init(icon: String, title: String, message: String, actionTitle: String? = nil, action: (() -> Void)? = nil) {
        self.icon = icon
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }
    
    public var body: some View {
        VStack(spacing: HealthAIDesignSystem.Spacing.lg) {
            Image(systemName: icon)
                .font(.system(size: 48, weight: .light))
                .foregroundColor(HealthAIDesignSystem.Colors.textTertiary)
            
            VStack(spacing: HealthAIDesignSystem.Spacing.sm) {
                Text(title)
                    .font(HealthAIDesignSystem.Typography.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(HealthAIDesignSystem.Colors.textPrimary)
                    .multilineTextAlignment(.center)
                
                Text(message)
                    .font(HealthAIDesignSystem.Typography.body)
                    .foregroundColor(HealthAIDesignSystem.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            if let actionTitle = actionTitle, let action = action {
                HealthAIButton(title: actionTitle, style: .primary, action: action)
                    .frame(maxWidth: 200)
            }
        }
        .padding(HealthAIDesignSystem.Spacing.xxl)
    }
}

// MARK: - Error State
public struct HealthAIErrorState: View {
    let title: String
    let message: String
    let retryTitle: String?
    let retryAction: (() -> Void)?
    
    public init(title: String, message: String, retryTitle: String? = "Try Again", retryAction: (() -> Void)? = nil) {
        self.title = title
        self.message = message
        self.retryTitle = retryTitle
        self.retryAction = retryAction
    }
    
    public var body: some View {
        VStack(spacing: HealthAIDesignSystem.Spacing.lg) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48, weight: .medium))
                .foregroundColor(HealthAIDesignSystem.Colors.error)
            
            VStack(spacing: HealthAIDesignSystem.Spacing.sm) {
                Text(title)
                    .font(HealthAIDesignSystem.Typography.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(HealthAIDesignSystem.Colors.textPrimary)
                    .multilineTextAlignment(.center)
                
                Text(message)
                    .font(HealthAIDesignSystem.Typography.body)
                    .foregroundColor(HealthAIDesignSystem.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            if let retryTitle = retryTitle, let retryAction = retryAction {
                HealthAIButton(title: retryTitle, style: .secondary, action: retryAction)
                    .frame(maxWidth: 200)
            }
        }
        .padding(HealthAIDesignSystem.Spacing.xxl)
    }
}

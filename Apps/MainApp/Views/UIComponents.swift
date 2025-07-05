import SwiftUI
import Combine

// MARK: - Enhanced Color Palette
extension Color {
    // Primary Brand Colors
    static let somnaPrimary = Color(red: 0.39, green: 0.4, blue: 0.96)
    static let somnaSecondary = Color(red: 0.55, green: 0.47, blue: 0.91)
    static let somnaAccent = Color(red: 0.2, green: 0.8, blue: 0.6)
    
    // Background Colors
    static let somnaBackground = Color(red: 0.04, green: 0.04, blue: 0.04)
    static let somnaCardBackground = Color(red: 0.08, green: 0.08, blue: 0.12)
    static let somnaSurfaceBackground = Color(red: 0.12, green: 0.12, blue: 0.16)
    
    // Semantic Colors
    static let somnaSuccess = Color(red: 0.2, green: 0.8, blue: 0.4)
    static let somnaWarning = Color(red: 1.0, green: 0.7, blue: 0.0)
    static let somnaError = Color(red: 0.9, green: 0.3, blue: 0.3)
    static let somnaInfo = Color(red: 0.3, green: 0.7, blue: 1.0)
    
    // Gradient Colors
    static let somnaGradientStart = Color(red: 0.39, green: 0.4, blue: 0.96)
    static let somnaGradientEnd = Color(red: 0.55, green: 0.47, blue: 0.91)
    
    // Sleep Stage Colors
    static let sleepAwake = Color(red: 1.0, green: 0.6, blue: 0.0)
    static let sleepLight = Color(red: 0.3, green: 0.7, blue: 1.0)
    static let sleepDeep = Color(red: 0.6, green: 0.3, blue: 0.9)
    static let sleepREM = Color(red: 0.2, green: 0.8, blue: 0.4)
}

// MARK: - Custom Gradients
extension LinearGradient {
    static let somnaPrimary = LinearGradient(
        colors: [.somnaGradientStart, .somnaGradientEnd],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let somnaCard = LinearGradient(
        colors: [Color.somnaCardBackground, Color.somnaSurfaceBackground],
        startPoint: .top,
        endPoint: .bottom
    )
    
    static let somnaSuccess = LinearGradient(
        colors: [.somnaSuccess, .somnaSuccess.opacity(0.7)],
        startPoint: .leading,
        endPoint: .trailing
    )
}

// MARK: - Enhanced Button Styles
struct SomnaPrimaryButtonStyle: ButtonStyle {
    let isEnabled: Bool
    
    init(isEnabled: Bool = true) {
        self.isEnabled = isEnabled
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity)
            .background(
                LinearGradient.somnaPrimary
                    .opacity(isEnabled ? 1.0 : 0.5)
            )
            .cornerRadius(16)
            .shadow(
                color: .somnaPrimary.opacity(0.3),
                radius: configuration.isPressed ? 4 : 8,
                x: 0,
                y: configuration.isPressed ? 2 : 4
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct SomnaSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .fontWeight(.semibold)
            .foregroundColor(.somnaPrimary)
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.somnaPrimary.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.somnaPrimary.opacity(0.3), lineWidth: 1)
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct SomnaIconButtonStyle: ButtonStyle {
    let color: Color
    let size: CGFloat
    
    init(color: Color = .somnaPrimary, size: CGFloat = 44) {
        self.color = color
        self.size = size
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.title2)
            .foregroundColor(color)
            .frame(width: size, height: size)
            .background(
                Circle()
                    .fill(color.opacity(0.1))
            )
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Enhanced Card Components
struct SomnaCard<Content: View>: View {
    let padding: CGFloat
    let cornerRadius: CGFloat
    let shadowRadius: CGFloat
    let content: Content
    
    init(padding: CGFloat = 16, cornerRadius: CGFloat = 12, shadowRadius: CGFloat = 8, @ViewBuilder content: () -> Content) {
        self.padding = padding
        self.cornerRadius = cornerRadius
        self.shadowRadius = shadowRadius
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.somnaCardBackground)
                    .shadow(color: .black.opacity(0.1), radius: shadowRadius, x: 0, y: 4)
            )
            .drawingGroup()
    }
}

// MARK: - Enhanced Progress Indicators
struct SomnaProgressView: View {
    let value: Float
    let maxValue: Float
    let color: Color
    let showLabel: Bool
    
    @State private var animatedValue: Float = 0
    
    init(value: Float, maxValue: Float = 1.0, color: Color = .somnaPrimary, showLabel: Bool = true) {
        self.value = value
        self.maxValue = maxValue
        self.color = color
        self.showLabel = showLabel
    }
    
    var body: some View {
        VStack(spacing: 4) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background track
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 8)
                    
                    // Progress bar
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [color, color.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * CGFloat(animatedValue / maxValue), height: 8)
                        .animation(.easeInOut(duration: 0.5), value: animatedValue)
                }
            }
            .frame(height: 8)
            
            if showLabel {
                HStack {
                    Text("\(Int(animatedValue * 100))%")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.8)) {
                animatedValue = value
            }
        }
        .onChange(of: value) { newValue in
            withAnimation(.easeInOut(duration: 0.5)) {
                animatedValue = newValue
            }
        }
    }
}

// MARK: - Enhanced Status Indicators
struct SomnaStatusBadge: View {
    let title: String
    let status: StatusType
    let size: BadgeSize
    
    enum StatusType {
        case success, warning, error, info, neutral
        
        var color: Color {
            switch self {
            case .success: return .somnaSuccess
            case .warning: return .somnaWarning
            case .error: return .somnaError
            case .info: return .somnaInfo
            case .neutral: return .gray
            }
        }
        
        var icon: String {
            switch self {
            case .success: return "checkmark.circle.fill"
            case .warning: return "exclamationmark.triangle.fill"
            case .error: return "xmark.circle.fill"
            case .info: return "info.circle.fill"
            case .neutral: return "circle.fill"
            }
        }
    }
    
    enum BadgeSize {
        case small, medium, large
        
        var padding: CGFloat {
            switch self {
            case .small: return 6
            case .medium: return 8
            case .large: return 12
            }
        }
        
        var fontSize: Font {
            switch self {
            case .small: return .caption2
            case .medium: return .caption
            case .large: return .subheadline
            }
        }
    }
    
    init(_ title: String, status: StatusType, size: BadgeSize = .medium) {
        self.title = title
        self.status = status
        self.size = size
    }
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: status.icon)
                .font(size.fontSize)
                .foregroundColor(status.color)
            
            Text(title)
                .font(size.fontSize)
                .fontWeight(.medium)
                .foregroundColor(status.color)
        }
        .padding(.horizontal, size.padding)
        .padding(.vertical, size.padding / 2)
        .background(
            Capsule()
                .fill(status.color.opacity(0.1))
                .overlay(
                    Capsule()
                        .stroke(status.color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - Enhanced Data Cards
struct SomnaDataCard: View {
    let title: String
    let value: String
    let subtitle: String?
    let icon: String
    let color: Color
    let trend: TrendDirection?
    
    enum TrendDirection {
        case up, down, neutral
        
        var icon: String {
            switch self {
            case .up: return "arrow.up.right"
            case .down: return "arrow.down.right"
            case .neutral: return "minus"
            }
        }
        
        var color: Color {
            switch self {
            case .up: return .somnaSuccess
            case .down: return .somnaError
            case .neutral: return .gray
            }
        }
    }
    
    init(
        title: String,
        value: String,
        subtitle: String? = nil,
        icon: String,
        color: Color = .somnaPrimary,
        trend: TrendDirection? = nil
    ) {
        self.title = title
        self.value = value
        self.subtitle = subtitle
        self.icon = icon
        self.color = color
        self.trend = trend
    }
    
    var body: some View {
        SomnaCard(padding: 16) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(color)
                        .frame(width: 32)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                        
                        if let subtitle = subtitle {
                            Text(subtitle)
                                .font(.caption2)
                                .foregroundColor(.secondary.opacity(0.7))
                        }
                    }
                    
                    Spacer()
                    
                    if let trend = trend {
                        Image(systemName: trend.icon)
                            .font(.caption)
                            .foregroundColor(trend.color)
                    }
                }
                
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }
        }
    }
}

// MARK: - Enhanced List Items
struct SomnaListItem: View {
    let title: String
    let subtitle: String?
    let icon: String
    let iconColor: Color
    let action: (() -> Void)?
    let trailing: AnyView?
    
    init(
        title: String,
        subtitle: String? = nil,
        icon: String,
        iconColor: Color = .somnaPrimary,
        action: (() -> Void)? = nil,
        @ViewBuilder trailing: () -> some View = { EmptyView() }
    ) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.iconColor = iconColor
        self.action = action
        self.trailing = AnyView(trailing())
    }
    
    var body: some View {
        Button(action: { action?() }) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(iconColor)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                trailing
                
                if action != nil {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Enhanced Animations
struct SomnaPulseAnimation: ViewModifier {
    let duration: Double
    let scale: CGFloat
    
    @State private var isAnimating = false
    
    init(duration: Double = 2.0, scale: CGFloat = 1.05) {
        self.duration = duration
        self.scale = scale
    }
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isAnimating ? scale : 1.0)
            .animation(.easeInOut(duration: duration).repeatForever(autoreverses: true), value: isAnimating)
            .onAppear {
                isAnimating = true
            }
    }
}

struct SomnaShimmerAnimation: ViewModifier {
    @State private var isAnimating = false
    
    func body(content: Content) -> some View {
        content
            .overlay(
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [.clear, .white.opacity(0.3), .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .offset(x: isAnimating ? 200 : -200)
            )
            .clipped()
            .animation(.linear(duration: 1.5).repeatForever(autoreverses: false), value: isAnimating)
            .onAppear {
                isAnimating = true
            }
    }
}

// MARK: - Enhanced Loading States
struct SomnaLoadingView: View {
    let message: String
    let showProgress: Bool
    let progress: Double?
    
    init(
        message: String = "Loading...",
        showProgress: Bool = false,
        progress: Double? = nil
    ) {
        self.message = message
        self.showProgress = showProgress
        self.progress = progress
    }
    
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .somnaPrimary))
                .scaleEffect(1.5)
            
            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            if showProgress, let progress = progress {
                SomnaProgressView(
                    value: Float(progress),
                    maxValue: 1.0,
                    color: .somnaPrimary,
                    showLabel: true
                )
                .frame(width: 200)
            }
        }
        .padding(40)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.somnaCardBackground)
                .shadow(radius: 20)
        )
    }
}

// MARK: - Enhanced Empty States
struct SomnaEmptyState: View {
    let icon: String
    let title: String
    let message: String
    let actionTitle: String?
    let action: (() -> Void)?
    
    init(
        icon: String,
        title: String,
        message: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundColor(.somnaPrimary.opacity(0.6))
            
            VStack(spacing: 8) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                
                Text(message)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            if let actionTitle = actionTitle, let action = action {
                Button(actionTitle, action: action)
                    .buttonStyle(SomnaPrimaryButtonStyle())
            }
        }
        .padding(40)
    }
}

// MARK: - View Extensions
extension View {
    func somnaPulse(duration: Double = 2.0, scale: CGFloat = 1.05) -> some View {
        modifier(SomnaPulseAnimation(duration: duration, scale: scale))
    }
    
    func somnaShimmer() -> some View {
        modifier(SomnaShimmerAnimation())
    }
    
    func somnaCard(
        padding: CGFloat = 20,
        cornerRadius: CGFloat = 16,
        shadowRadius: CGFloat = 8
    ) -> some View {
        SomnaCard(
            padding: padding,
            cornerRadius: cornerRadius,
            shadowRadius: shadowRadius
        ) {
            self
        }
    }
}

// MARK: - Performance Optimized Extensions

extension View {
    /// Apply pulse animation with performance optimization
    func somnaPulse(duration: Double = 2.0, scale: CGFloat = 1.05) -> some View {
        modifier(SomnaPulseAnimation(duration: duration, scale: scale))
    }
    
    /// Apply shimmer animation with performance optimization
    func somnaShimmer() -> some View {
        modifier(SomnaShimmerAnimation())
    }
}

// MARK: - Performance Optimized Button Styles

enum SomnaButtonStyle {
    case primary
    case secondary
    case outline
    case danger
    
    var backgroundColor: Color {
        switch self {
        case .primary:
            return Color.somnaPrimary
        case .secondary:
            return Color.somnaSecondary
        case .outline:
            return Color.clear
        case .danger:
            return Color.red
        }
    }
    
    var textColor: Color {
        switch self {
        case .primary, .secondary, .danger:
            return .white
        case .outline:
            return Color.somnaPrimary
        }
    }
    
    var borderColor: Color {
        switch self {
        case .outline:
            return Color.somnaPrimary
        default:
            return Color.clear
        }
    }
    
    var borderWidth: CGFloat {
        switch self {
        case .outline:
            return 1
        default:
            return 0
        }
    }
}

// MARK: - Performance Optimized Color Extensions

extension Color {
    static let somnaPrimary = Color(red: 0.4, green: 0.2, blue: 0.8)
    static let somnaSecondary = Color(red: 0.6, green: 0.4, blue: 1.0)
    static let somnaAccent = Color(red: 0.8, green: 0.6, blue: 1.0)
    static let somnaCardBackground = Color(.systemBackground)
    static let somnaBackground = Color(.systemGroupedBackground)
}

// MARK: - Performance Optimized Haptic Manager

class HapticManager {
    static let shared = HapticManager()
    
    private init() {}
    
    func impact(style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }
    
    func notification(type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(type)
    }
    
    func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        generator.selectionChanged()
    }
}

// MARK: - Performance Optimized Lazy Loading Views

/// Lazy loading container for performance optimization
struct LazyLoadingContainer<Content: View>: View {
    let content: Content
    let threshold: CGFloat
    
    @State private var isVisible = false
    
    init(threshold: CGFloat = 100, @ViewBuilder content: () -> Content) {
        self.threshold = threshold
        self.content = content()
    }
    
    var body: some View {
        content
            .opacity(isVisible ? 1.0 : 0.0)
            .animation(.easeInOut(duration: 0.3), value: isVisible)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isVisible = true
                }
            }
    }
}

/// Performance optimized scroll view with lazy loading
struct OptimizedScrollView<Content: View>: View {
    let content: Content
    let showsIndicators: Bool
    
    init(showsIndicators: Bool = true, @ViewBuilder content: () -> Content) {
        self.showsIndicators = showsIndicators
        self.content = content()
    }
    
    var body: some View {
        ScrollView(showsIndicators: showsIndicators) {
            LazyVStack(spacing: 16) {
                content
            }
            .padding()
        }
        .drawingGroup()
    }
}

/// Performance optimized list with lazy loading
struct OptimizedList<Data: RandomAccessCollection, Content: View>: View where Data.Element: Identifiable {
    let data: Data
    let content: (Data.Element) -> Content
    
    init(_ data: Data, @ViewBuilder content: @escaping (Data.Element) -> Content) {
        self.data = data
        self.content = content
    }
    
    var body: some View {
        LazyVStack(spacing: 8) {
            ForEach(data) { item in
                LazyLoadingContainer {
                    content(item)
                }
            }
        }
        .drawingGroup()
    }
}

// MARK: - Performance Optimized Animation Utilities

/// Performance optimized animation utilities
struct AnimationUtils {
    /// Debounced animation to prevent excessive updates
    static func debouncedAnimation<T: Equatable>(_ value: T, delay: TimeInterval = 0.1, action: @escaping () -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            action()
        }
    }
    
    /// Throttled animation to limit update frequency
    static func throttledAnimation<T: Equatable>(_ value: T, interval: TimeInterval = 0.1, action: @escaping () -> Void) {
        // Implementation would use a timer to limit frequency
        action()
    }
}

// MARK: - Performance Optimized View Modifiers

/// Performance optimized view modifiers
struct PerformanceModifiers {
    /// Optimize view for complex rendering
    static func optimizedRendering<Content: View>(_ content: Content) -> some View {
        content
            .drawingGroup()
            .compositingGroup()
    }
    
    /// Optimize view for animations
    static func optimizedAnimation<Content: View>(_ content: Content) -> some View {
        content
            .allowsHitTesting(false)
            .drawingGroup()
    }
}

// MARK: - Performance Optimized Data Structures

/// Performance optimized data structures for UI
struct OptimizedDataPoint: Identifiable {
    let id = UUID()
    let value: Double
    let timestamp: Date
    
    // Performance: Use struct for better memory efficiency
    init(value: Double, timestamp: Date = Date()) {
        self.value = value
        self.timestamp = timestamp
    }
}

/// Performance optimized chart data
struct OptimizedChartData {
    let points: [OptimizedDataPoint]
    let minValue: Double
    let maxValue: Double
    
    // Performance: Pre-calculate min/max for efficient rendering
    init(points: [OptimizedDataPoint]) {
        self.points = points
        self.minValue = points.map { $0.value }.min() ?? 0
        self.maxValue = points.map { $0.value }.max() ?? 1
    }
}

// MARK: - Production-Grade Performance Optimizations

// MARK: - Memory-Efficient Data Structures

/// Memory-efficient data point for charts and analytics
struct OptimizedDataPoint: Identifiable, Equatable {
    let id = UUID()
    let value: Double
    let timestamp: Date
    
    // Use struct for better memory efficiency and value semantics
    init(value: Double, timestamp: Date = Date()) {
        self.value = value
        self.timestamp = timestamp
    }
    
    // Custom Equatable for performance
    static func == (lhs: OptimizedDataPoint, rhs: OptimizedDataPoint) -> Bool {
        return lhs.id == rhs.id && lhs.value == rhs.value && lhs.timestamp == rhs.timestamp
    }
}

/// Memory-efficient chart data with pre-calculated bounds
struct OptimizedChartData: Equatable {
    let points: [OptimizedDataPoint]
    let minValue: Double
    let maxValue: Double
    let averageValue: Double
    
    // Pre-calculate values for efficient rendering
    init(points: [OptimizedDataPoint]) {
        self.points = points
        self.minValue = points.map { $0.value }.min() ?? 0
        self.maxValue = points.map { $0.value }.max() ?? 1
        self.averageValue = points.map { $0.value }.reduce(0, +) / Double(max(points.count, 1))
    }
    
    // Custom Equatable for performance
    static func == (lhs: OptimizedChartData, rhs: OptimizedChartData) -> Bool {
        return lhs.points == rhs.points
    }
}

// MARK: - Efficient Animation System

/// Performance-optimized animation manager
class AnimationManager: ObservableObject {
    static let shared = AnimationManager()
    
    @Published var animationScale: Double = 1.0
    @Published var isAnimationsEnabled = true
    
    private var animationTimers: [String: Timer] = [:]
    private let animationQueue = DispatchQueue(label: "com.somnasync.animation", qos: .userInteractive)
    
    private init() {}
    
    /// Debounced animation to prevent excessive updates
    func debouncedAnimation<T: Equatable>(_ value: T, delay: TimeInterval = 0.1, action: @escaping () -> Void) {
        let key = "\(value)"
        animationTimers[key]?.invalidate()
        
        animationTimers[key] = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { _ in
            DispatchQueue.main.async {
                action()
            }
        }
    }
    
    /// Throttled animation to limit update frequency
    func throttledAnimation<T: Equatable>(_ value: T, interval: TimeInterval = 0.1, action: @escaping () -> Void) {
        let key = "throttle_\(value)"
        
        if animationTimers[key] == nil {
            action()
            
            animationTimers[key] = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { _ in
                self.animationTimers[key] = nil
            }
        }
    }
    
    /// Efficient pulse animation with performance optimization
    func efficientPulse<T: View>(_ view: T, duration: Double = 2.0, scale: CGFloat = 1.05) -> some View {
        view
            .scaleEffect(animationScale)
            .animation(
                .easeInOut(duration: duration)
                .repeatForever(autoreverses: true)
                .speed(1.0 / animationScale),
                value: animationScale
            )
            .onAppear {
                animationScale = scale
            }
    }
    
    deinit {
        animationTimers.values.forEach { $0.invalidate() }
    }
}

// MARK: - Lazy Loading System

/// Performance-optimized lazy loading container
struct LazyLoadingContainer<Content: View>: View {
    let content: Content
    let threshold: CGFloat
    let placeholder: AnyView?
    
    @State private var isVisible = false
    @State private var hasAppeared = false
    
    init(
        threshold: CGFloat = 100,
        placeholder: AnyView? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.threshold = threshold
        self.placeholder = placeholder
        self.content = content()
    }
    
    var body: some View {
        Group {
            if isVisible || hasAppeared {
                content
                    .opacity(isVisible ? 1.0 : 0.0)
                    .animation(.easeInOut(duration: 0.3), value: isVisible)
            } else if let placeholder = placeholder {
                placeholder
            } else {
                Color.clear
                    .frame(height: 1)
            }
        }
        .onAppear {
            hasAppeared = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isVisible = true
            }
        }
    }
}

/// Performance-optimized scroll view with lazy loading
struct OptimizedScrollView<Content: View>: View {
    let content: Content
    let showsIndicators: Bool
    let enableLazyLoading: Bool
    
    init(
        showsIndicators: Bool = true,
        enableLazyLoading: Bool = true,
        @ViewBuilder content: () -> Content
    ) {
        self.showsIndicators = showsIndicators
        self.enableLazyLoading = enableLazyLoading
        self.content = content()
    }
    
    var body: some View {
        ScrollView(showsIndicators: showsIndicators) {
            if enableLazyLoading {
                LazyVStack(spacing: 16) {
                    content
                }
                .padding()
            } else {
                VStack(spacing: 16) {
                    content
                }
                .padding()
            }
        }
        .drawingGroup() // Enable Metal rendering
    }
}

/// Performance-optimized list with lazy loading
struct OptimizedList<Data: RandomAccessCollection, Content: View>: View where Data.Element: Identifiable {
    let data: Data
    let content: (Data.Element) -> Content
    let enableLazyLoading: Bool
    
    init(
        _ data: Data,
        enableLazyLoading: Bool = true,
        @ViewBuilder content: @escaping (Data.Element) -> Content
    ) {
        self.data = data
        self.enableLazyLoading = enableLazyLoading
        self.content = content
    }
    
    var body: some View {
        if enableLazyLoading {
            LazyVStack(spacing: 8) {
                ForEach(data) { item in
                    LazyLoadingContainer {
                        content(item)
                    }
                }
            }
            .drawingGroup()
        } else {
            VStack(spacing: 8) {
                ForEach(data) { item in
                    content(item)
                }
            }
            .drawingGroup()
        }
    }
}

// MARK: - Rendering Optimizations

/// Performance-optimized view modifiers
struct PerformanceModifiers {
    /// Optimize view for complex rendering
    static func optimizedRendering<Content: View>(_ content: Content) -> some View {
        content
            .drawingGroup() // Enable Metal rendering
            .compositingGroup() // Optimize compositing
    }
    
    /// Optimize view for animations
    static func optimizedAnimation<Content: View>(_ content: Content) -> some View {
        content
            .allowsHitTesting(false) // Disable hit testing during animation
            .drawingGroup() // Enable Metal rendering
    }
    
    /// Optimize view for static content
    static func optimizedStatic<Content: View>(_ content: Content) -> some View {
        content
            .drawingGroup()
            .allowsHitTesting(false)
    }
}

// MARK: - Memory Management

/// Memory-efficient image cache
class ImageCache {
    static let shared = ImageCache()
    
    private let cache = NSCache<NSString, UIImage>()
    private let queue = DispatchQueue(label: "com.somnasync.imagecache", qos: .utility)
    
    private init() {
        cache.countLimit = 100 // Limit cache size
        cache.totalCostLimit = 50 * 1024 * 1024 // 50MB limit
    }
    
    func getImage(for key: String) -> UIImage? {
        return cache.object(forKey: key as NSString)
    }
    
    func setImage(_ image: UIImage, for key: String) {
        queue.async {
            self.cache.setObject(image, forKey: key as NSString)
        }
    }
    
    func clearCache() {
        queue.async {
            self.cache.removeAllObjects()
        }
    }
}

// MARK: - Efficient UI Components

/// Performance-optimized progress view
struct OptimizedProgressView: View {
    let value: Float
    let maxValue: Float
    let color: Color
    let showLabel: Bool
    
    @State private var animatedValue: Float = 0
    @State private var isAnimating = false
    
    init(value: Float, maxValue: Float = 1.0, color: Color = .somnaPrimary, showLabel: Bool = true) {
        self.value = value
        self.maxValue = maxValue
        self.color = color
        self.showLabel = showLabel
    }
    
    var body: some View {
        VStack(spacing: 4) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background track
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 8)
                    
                    // Progress bar
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [color, color.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * CGFloat(animatedValue / maxValue), height: 8)
                        .animation(.easeInOut(duration: 0.5), value: animatedValue)
                }
            }
            .frame(height: 8)
            .drawingGroup() // Enable Metal rendering
            
            if showLabel {
                HStack {
                    Text("\(Int(animatedValue * 100))%")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
            }
        }
        .onAppear {
            if !isAnimating {
                isAnimating = true
                withAnimation(.easeInOut(duration: 0.8)) {
                    animatedValue = value
                }
            }
        }
        .onChange(of: value) { newValue in
            withAnimation(.easeInOut(duration: 0.5)) {
                animatedValue = newValue
            }
        }
    }
}

/// Performance-optimized card view
struct OptimizedCard<Content: View>: View {
    let content: Content
    let padding: CGFloat
    let cornerRadius: CGFloat
    let shadowRadius: CGFloat
    let backgroundColor: Color
    
    init(
        padding: CGFloat = 20,
        cornerRadius: CGFloat = 16,
        shadowRadius: CGFloat = 8,
        backgroundColor: Color = Color.somnaCardBackground,
        @ViewBuilder content: () -> Content
    ) {
        self.padding = padding
        self.cornerRadius = cornerRadius
        self.shadowRadius = shadowRadius
        self.backgroundColor = backgroundColor
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(backgroundColor)
                    .shadow(radius: shadowRadius)
            )
            .drawingGroup() // Enable Metal rendering
    }
}

// MARK: - Efficient Animation Utilities

/// Performance-optimized animation utilities
struct AnimationUtils {
    /// Debounced animation to prevent excessive updates
    static func debouncedAnimation<T: Equatable>(_ value: T, delay: TimeInterval = 0.1, action: @escaping () -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            action()
        }
    }
    
    /// Throttled animation to limit update frequency
    static func throttledAnimation<T: Equatable>(_ value: T, interval: TimeInterval = 0.1, action: @escaping () -> Void) {
        // Implementation would use a timer to limit frequency
        action()
    }
    
    /// Efficient spring animation
    static func efficientSpring<T: View>(_ view: T, response: Double = 0.5, dampingFraction: Double = 0.8) -> some View {
        view.animation(.spring(response: response, dampingFraction: dampingFraction), value: true)
    }
}

// MARK: - Performance Monitoring

/// Performance monitoring utilities
class PerformanceMonitor: ObservableObject {
    static let shared = PerformanceMonitor()
    
    @Published var frameRate: Double = 60.0
    @Published var memoryUsage: Int64 = 0
    @Published var isPerformanceGood = true
    
    private var displayLink: CADisplayLink?
    private var frameCount = 0
    private var lastFrameTime: CFTimeInterval = 0
    
    private init() {
        startMonitoring()
    }
    
    private func startMonitoring() {
        displayLink = CADisplayLink(target: self, selector: #selector(updateFrameRate))
        displayLink?.add(to: .main, forMode: .common)
    }
    
    @objc private func updateFrameRate() {
        frameCount += 1
        let currentTime = CACurrentMediaTime()
        
        if currentTime - lastFrameTime >= 1.0 {
            frameRate = Double(frameCount)
            frameCount = 0
            lastFrameTime = currentTime
            
            // Update performance status
            isPerformanceGood = frameRate >= 55.0
            
            // Monitor memory usage
            updateMemoryUsage()
        }
    }
    
    private func updateMemoryUsage() {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            memoryUsage = Int64(info.resident_size)
        }
    }
    
    deinit {
        displayLink?.invalidate()
    }
}

// MARK: - View Extensions for Performance

extension View {
    /// Apply performance optimizations
    func optimized() -> some View {
        self
            .drawingGroup()
            .compositingGroup()
    }
    
    /// Apply animation optimizations
    func optimizedAnimation() -> some View {
        self
            .allowsHitTesting(false)
            .drawingGroup()
    }
    
    /// Apply lazy loading
    func lazyLoad(threshold: CGFloat = 100) -> some View {
        LazyLoadingContainer(threshold: threshold) {
            self
        }
    }
    
    /// Apply efficient pulse animation
    func efficientPulse(duration: Double = 2.0, scale: CGFloat = 1.05) -> some View {
        AnimationManager.shared.efficientPulse(self, duration: duration, scale: scale)
    }
} 
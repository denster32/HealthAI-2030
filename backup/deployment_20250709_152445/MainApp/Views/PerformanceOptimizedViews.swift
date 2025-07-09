import SwiftUI
import Metal
import QuartzCore
import Combine

// MARK: - Performance Optimized View Modifiers

/// Advanced performance optimization modifiers
struct AdvancedPerformanceModifiers {
    
    /// Optimize view for maximum rendering performance
    static func ultraOptimized<Content: View>(_ content: Content) -> some View {
        content
            .drawingGroup() // Enable Metal rendering
            .compositingGroup() // Optimize compositing
            .allowsHitTesting(false) // Disable hit testing for static content
            .clipped() // Clip to bounds for better performance
    }
    
    /// Optimize view for animations with performance
    static func animationOptimized<Content: View>(_ content: Content) -> some View {
        content
            .drawingGroup()
            .compositingGroup()
            .animation(.easeInOut(duration: 0.3), value: true)
    }
    
    /// Optimize view for complex layouts
    static func layoutOptimized<Content: View>(_ content: Content) -> some View {
        content
            .drawingGroup()
            .fixedSize(horizontal: false, vertical: true) // Optimize layout calculations
    }
    
    /// Optimize view for scrolling performance
    static func scrollOptimized<Content: View>(_ content: Content) -> some View {
        content
            .drawingGroup()
            .compositingGroup()
            .clipped()
    }
}

// MARK: - Performance Optimized Containers

/// Ultra-fast lazy loading container with advanced optimizations
struct UltraLazyContainer<Content: View>: View {
    let content: Content
    let threshold: CGFloat
    let placeholder: AnyView?
    let enablePreloading: Bool
    
    @State private var isVisible = false
    @State private var hasAppeared = false
    @State private var isPreloaded = false
    
    init(
        threshold: CGFloat = 50,
        enablePreloading: Bool = true,
        placeholder: AnyView? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.threshold = threshold
        self.enablePreloading = enablePreloading
        self.placeholder = placeholder
        self.content = content()
    }
    
    var body: some View {
        Group {
            if isVisible || hasAppeared {
                content
                    .opacity(isVisible ? 1.0 : 0.0)
                    .animation(.easeInOut(duration: 0.2), value: isVisible)
                    .modifier(AdvancedPerformanceModifiers.ultraOptimized)
            } else if let placeholder = placeholder {
                placeholder
            } else {
                Color.clear
                    .frame(height: 1)
            }
        }
        .onAppear {
            hasAppeared = true
            
            if enablePreloading {
                // Preload content slightly before it becomes visible
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    isPreloaded = true
                }
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isVisible = true
            }
        }
    }
}

/// Performance-optimized scroll view with advanced features
struct UltraScrollView<Content: View>: View {
    let content: Content
    let showsIndicators: Bool
    let enableLazyLoading: Bool
    let enablePreloading: Bool
    let scrollBehavior: ScrollBehavior
    
    enum ScrollBehavior {
        case smooth, instant, optimized
    }
    
    init(
        showsIndicators: Bool = true,
        enableLazyLoading: Bool = true,
        enablePreloading: Bool = true,
        scrollBehavior: ScrollBehavior = .optimized,
        @ViewBuilder content: () -> Content
    ) {
        self.showsIndicators = showsIndicators
        self.enableLazyLoading = enableLazyLoading
        self.enablePreloading = enablePreloading
        self.scrollBehavior = scrollBehavior
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
        .modifier(AdvancedPerformanceModifiers.scrollOptimized)
    }
}

/// Performance-optimized list with advanced features
struct UltraList<Data: RandomAccessCollection, Content: View>: View where Data.Element: Identifiable {
    let data: Data
    let content: (Data.Element) -> Content
    let enableLazyLoading: Bool
    let enablePreloading: Bool
    let spacing: CGFloat
    
    init(
        _ data: Data,
        spacing: CGFloat = 8,
        enableLazyLoading: Bool = true,
        enablePreloading: Bool = true,
        @ViewBuilder content: @escaping (Data.Element) -> Content
    ) {
        self.data = data
        self.spacing = spacing
        self.enableLazyLoading = enableLazyLoading
        self.enablePreloading = enablePreloading
        self.content = content
    }
    
    var body: some View {
        if enableLazyLoading {
            LazyVStack(spacing: spacing) {
                ForEach(data) { item in
                    UltraLazyContainer(
                        enablePreloading: enablePreloading
                    ) {
                        content(item)
                    }
                }
            }
            .modifier(AdvancedPerformanceModifiers.layoutOptimized)
        } else {
            VStack(spacing: spacing) {
                ForEach(data) { item in
                    content(item)
                }
            }
            .modifier(AdvancedPerformanceModifiers.layoutOptimized)
        }
    }
}

// MARK: - Performance Optimized UI Components

/// Ultra-fast progress view with GPU acceleration
struct UltraProgressView: View {
    let value: Float
    let maxValue: Float
    let color: Color
    let showLabel: Bool
    let animationDuration: Double
    
    @State private var animatedValue: Float = 0
    @State private var isAnimating = false
    
    init(
        value: Float,
        maxValue: Float = 1.0,
        color: Color = .somnaPrimary,
        showLabel: Bool = true,
        animationDuration: Double = 0.5
    ) {
        self.value = value
        self.maxValue = maxValue
        self.color = color
        self.showLabel = showLabel
        self.animationDuration = animationDuration
    }
    
    var body: some View {
        VStack(spacing: 4) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background track
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 8)
                    
                    // Progress bar with gradient
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [color, color.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * CGFloat(animatedValue / maxValue), height: 8)
                        .animation(.easeInOut(duration: animationDuration), value: animatedValue)
                }
            }
            .frame(height: 8)
            .modifier(AdvancedPerformanceModifiers.ultraOptimized)
            
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
            withAnimation(.easeInOut(duration: animationDuration)) {
                animatedValue = newValue
            }
        }
    }
}

/// Ultra-fast card view with advanced rendering
struct UltraCard<Content: View>: View {
    let content: Content
    let padding: CGFloat
    let cornerRadius: CGFloat
    let shadowRadius: CGFloat
    let backgroundColor: Color
    let enableShadow: Bool
    
    init(
        padding: CGFloat = 20,
        cornerRadius: CGFloat = 16,
        shadowRadius: CGFloat = 8,
        backgroundColor: Color = Color.somnaCardBackground,
        enableShadow: Bool = true,
        @ViewBuilder content: () -> Content
    ) {
        self.padding = padding
        self.cornerRadius = cornerRadius
        self.shadowRadius = shadowRadius
        self.backgroundColor = backgroundColor
        self.enableShadow = enableShadow
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(backgroundColor)
                    .shadow(radius: enableShadow ? shadowRadius : 0)
            )
            .modifier(AdvancedPerformanceModifiers.ultraOptimized)
    }
}

/// Ultra-fast button with performance optimizations
struct UltraButton<Content: View>: View {
    let content: Content
    let action: () -> Void
    let style: UltraButtonStyle
    let isEnabled: Bool
    
    @State private var isPressed = false
    
    init(
        style: UltraButtonStyle = .primary,
        isEnabled: Bool = true,
        action: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.style = style
        self.isEnabled = isEnabled
        self.action = action
        self.content = content()
    }
    
    var body: some View {
        Button(action: {
            if isEnabled {
                action()
            }
        }) {
            content
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(style.backgroundColor)
                        .opacity(isEnabled ? 1.0 : 0.5)
                )
                .foregroundColor(style.textColor)
                .scaleEffect(isPressed ? 0.95 : 1.0)
                .animation(.easeInOut(duration: 0.1), value: isPressed)
        }
        .disabled(!isEnabled)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
        .modifier(AdvancedPerformanceModifiers.ultraOptimized)
    }
}

enum UltraButtonStyle {
    case primary, secondary, outline, danger
    
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
}

// MARK: - Performance Optimized Animations

/// Advanced animation manager with performance optimizations
class AdvancedAnimationManager: ObservableObject {
    static let shared = AdvancedAnimationManager()
    
    @Published var animationScale: Double = 1.0
    @Published var isAnimationsEnabled = true
    @Published var performanceMode: PerformanceMode = .balanced
    
    enum PerformanceMode {
        case highPerformance, balanced, highQuality
    }
    
    private var animationTimers: [String: Timer] = [:]
    private let animationQueue = DispatchQueue(label: "com.somnasync.animation", qos: .userInteractive)
    
    private init() {}
    
    /// Ultra-efficient pulse animation
    func ultraPulse<T: View>(_ view: T, duration: Double = 2.0, scale: CGFloat = 1.05) -> some View {
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
    
    /// Performance-optimized shimmer animation
    func ultraShimmer<T: View>(_ view: T, duration: Double = 1.5) -> some View {
        view
            .overlay(
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [.clear, .white.opacity(0.3), .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .offset(x: animationScale * 200 - 200)
            )
            .clipped()
            .animation(.linear(duration: duration).repeatForever(autoreverses: false), value: animationScale)
            .onAppear {
                animationScale = 1.0
            }
    }
    
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
    
    deinit {
        animationTimers.values.forEach { $0.invalidate() }
    }
}

// MARK: - Performance Optimized Charts

/// Ultra-fast chart data structure
struct UltraChartData: Equatable {
    let points: [UltraDataPoint]
    let minValue: Double
    let maxValue: Double
    let averageValue: Double
    let trend: ChartTrend
    
    enum ChartTrend {
        case increasing, decreasing, stable
    }
    
    init(points: [UltraDataPoint]) {
        self.points = points
        self.minValue = points.map { $0.value }.min() ?? 0
        self.maxValue = points.map { $0.value }.max() ?? 1
        self.averageValue = points.map { $0.value }.reduce(0, +) / Double(max(points.count, 1))
        
        // Calculate trend
        if points.count >= 2 {
            let firstHalf = Array(points.prefix(points.count / 2))
            let secondHalf = Array(points.suffix(points.count / 2))
            let firstAvg = firstHalf.map { $0.value }.reduce(0, +) / Double(firstHalf.count)
            let secondAvg = secondHalf.map { $0.value }.reduce(0, +) / Double(secondHalf.count)
            
            if secondAvg > firstAvg + (maxValue - minValue) * 0.1 {
                trend = .increasing
            } else if secondAvg < firstAvg - (maxValue - minValue) * 0.1 {
                trend = .decreasing
            } else {
                trend = .stable
            }
        } else {
            trend = .stable
        }
    }
}

struct UltraDataPoint: Equatable {
    let timestamp: Date
    let value: Double
    let label: String?
    
    init(timestamp: Date, value: Double, label: String? = nil) {
        self.timestamp = timestamp
        self.value = value
        self.label = label
    }
}

/// Ultra-fast line chart with GPU acceleration
struct UltraLineChart: View {
    let data: UltraChartData
    let color: Color
    let lineWidth: CGFloat
    let showPoints: Bool
    
    init(
        data: UltraChartData,
        color: Color = .somnaPrimary,
        lineWidth: CGFloat = 2,
        showPoints: Bool = false
    ) {
        self.data = data
        self.color = color
        self.lineWidth = lineWidth
        self.showPoints = showPoints
    }
    
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                guard !data.points.isEmpty else { return }
                
                let width = geometry.size.width
                let height = geometry.size.height
                let valueRange = data.maxValue - data.minValue
                
                for (index, point) in data.points.enumerated() {
                    let x = width * Double(index) / Double(data.points.count - 1)
                    let normalizedValue = (point.value - data.minValue) / valueRange
                    let y = height * (1.0 - normalizedValue)
                    
                    if index == 0 {
                        path.move(to: CGPoint(x: x, y: y))
                    } else {
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
            }
            .stroke(color, lineWidth: lineWidth)
            .modifier(AdvancedPerformanceModifiers.ultraOptimized)
        }
    }
}

// MARK: - Performance Optimized Extensions

extension View {
    /// Apply ultra-performance optimizations
    func ultraOptimized() -> some View {
        modifier(AdvancedPerformanceModifiers.ultraOptimized)
    }
    
    /// Apply animation optimizations
    func animationOptimized() -> some View {
        modifier(AdvancedPerformanceModifiers.animationOptimized)
    }
    
    /// Apply layout optimizations
    func layoutOptimized() -> some View {
        modifier(AdvancedPerformanceModifiers.layoutOptimized)
    }
    
    /// Apply scroll optimizations
    func scrollOptimized() -> some View {
        modifier(AdvancedPerformanceModifiers.scrollOptimized)
    }
    
    /// Apply ultra-efficient pulse animation
    func ultraPulse(duration: Double = 2.0, scale: CGFloat = 1.05) -> some View {
        AdvancedAnimationManager.shared.ultraPulse(self, duration: duration, scale: scale)
    }
    
    /// Apply ultra-efficient shimmer animation
    func ultraShimmer(duration: Double = 1.5) -> some View {
        AdvancedAnimationManager.shared.ultraShimmer(self, duration: duration)
    }
}

// MARK: - Performance Monitoring Integration

/// Performance monitoring view modifier
struct PerformanceMonitoringModifier: ViewModifier {
    let viewName: String
    @StateObject private var performanceOptimizer = PerformanceOptimizer.shared
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                Logger.info("View appeared: \(viewName)", log: Logger.performance)
            }
            .onDisappear {
                Logger.info("View disappeared: \(viewName)", log: Logger.performance)
            }
    }
}

extension View {
    /// Monitor view performance
    func monitorPerformance(_ viewName: String) -> some View {
        modifier(PerformanceMonitoringModifier(viewName: viewName))
    }
} 
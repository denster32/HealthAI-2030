import SwiftUI
#if canImport(TVUIKit)
import TVUIKit
#endif

// MARK: - tvOS Platform Optimization
/// Optimized interface elements specifically designed for tvOS platform
/// Handles tvOS-specific design patterns, focus management, and living room-optimized components

// MARK: - tvOS-Specific Design System
struct tvOSDesignSystem {
    /// tvOS-specific color palette optimized for large displays
    static let colors = tvOSColorPalette()
    
    /// tvOS-specific typography optimized for TV viewing distance
    static let typography = tvOSTypography()
    
    /// tvOS-specific spacing and layout guidelines
    static let layout = tvOSLayoutGuide()
    
    /// tvOS-specific focus management
    static let focus = tvOSFocusGuide()
}

// MARK: - tvOS Color Palette
struct tvOSColorPalette {
    /// Primary colors optimized for tvOS
    let primary = Color(red: 0.0, green: 0.478, blue: 1.0)
    let secondary = Color(red: 0.584, green: 0.584, blue: 0.584)
    let accent = Color(red: 1.0, green: 0.231, blue: 0.188)
    
    /// Health-specific colors for tvOS
    let heartRate = Color(red: 1.0, green: 0.231, blue: 0.188)
    let bloodPressure = Color(red: 0.0, green: 0.478, blue: 1.0)
    let sleep = Color(red: 0.584, green: 0.0, blue: 0.827)
    let activity = Color(red: 0.0, green: 0.827, blue: 0.584)
    
    /// Background colors optimized for tvOS
    let background = Color.black
    let secondaryBackground = Color(red: 0.1, green: 0.1, blue: 0.1)
    let tertiaryBackground = Color(red: 0.15, green: 0.15, blue: 0.15)
    let cardBackground = Color(red: 0.2, green: 0.2, blue: 0.2)
    
    /// Text colors optimized for tvOS
    let primaryText = Color.white
    let secondaryText = Color(red: 0.8, green: 0.8, blue: 0.8)
    let tertiaryText = Color(red: 0.6, green: 0.6, blue: 0.6)
}

// MARK: - tvOS Typography
struct tvOSTypography {
    /// tvOS-optimized font sizes and weights for TV viewing distance
    let largeTitle = Font.system(size: 72, weight: .bold, design: .rounded)
    let title1 = Font.system(size: 48, weight: .semibold, design: .rounded)
    let title2 = Font.system(size: 36, weight: .semibold, design: .rounded)
    let title3 = Font.system(size: 28, weight: .medium, design: .rounded)
    let headline = Font.system(size: 24, weight: .semibold, design: .rounded)
    let body = Font.system(size: 20, weight: .regular, design: .rounded)
    let callout = Font.system(size: 18, weight: .regular, design: .rounded)
    let subheadline = Font.system(size: 16, weight: .medium, design: .rounded)
    let footnote = Font.system(size: 14, weight: .regular, design: .rounded)
    let caption1 = Font.system(size: 12, weight: .regular, design: .rounded)
    let caption2 = Font.system(size: 10, weight: .regular, design: .rounded)
    
    /// Health-specific typography for tvOS
    let healthMetric = Font.system(size: 96, weight: .bold, design: .rounded)
    let healthLabel = Font.system(size: 24, weight: .medium, design: .rounded)
    let healthUnit = Font.system(size: 20, weight: .regular, design: .rounded)
}

// MARK: - tvOS Layout Guide
struct tvOSLayoutGuide {
    /// tvOS-specific spacing
    let spacing: CGFloat = 40
    let smallSpacing: CGFloat = 20
    let largeSpacing: CGFloat = 60
    let extraLargeSpacing: CGFloat = 80
    
    /// tvOS-specific corner radius
    let cornerRadius: CGFloat = 16
    let smallCornerRadius: CGFloat = 8
    let largeCornerRadius: CGFloat = 24
    
    /// tvOS-specific padding
    let padding: CGFloat = 40
    let smallPadding: CGFloat = 20
    let largePadding: CGFloat = 60
    
    /// tvOS-specific card dimensions
    let cardWidth: CGFloat = 400
    let cardHeight: CGFloat = 300
    let largeCardWidth: CGFloat = 600
    let largeCardHeight: CGFloat = 400
}

// MARK: - tvOS Focus Guide
struct tvOSFocusGuide {
    /// Focus management settings
    let focusScale: CGFloat = 1.1
    let focusAnimation: Animation = .easeInOut(duration: 0.2)
    let focusShadowRadius: CGFloat = 20
    let focusShadowOpacity: Double = 0.5
}

// MARK: - tvOS-Optimized Health Dashboard
@available(tvOS 17.0, *)
public struct TVOptimizedHealthDashboard: View {
    @State private var selectedCard: String? = nil
    @State private var showingDetail = false
    @State private var detailMetric: HealthMetric = .heartRate
    
    public var body: some View {
        ZStack {
            // Background
            tvOSBackgroundView()
            
            VStack(spacing: tvOSDesignSystem.layout.largeSpacing) {
                // Header
                TVDashboardHeader()
                
                // Main content grid
                TVHealthGrid(selectedCard: $selectedCard, onCardSelected: { metric in
                    detailMetric = metric
                    showingDetail = true
                })
                
                // Navigation hints
                TVNavigationHints()
            }
            .padding(tvOSDesignSystem.layout.largePadding)
        }
        .sheet(isPresented: $showingDetail) {
            TVDetailView(metric: detailMetric)
        }
    }
}

// MARK: - tvOS Background View
struct tvOSBackgroundView: View {
    var body: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                gradient: Gradient(colors: [
                    tvOSDesignSystem.colors.background,
                    tvOSDesignSystem.colors.secondaryBackground
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Subtle pattern overlay
            GeometryReader { geometry in
                Path { path in
                    let width = geometry.size.width
                    let height = geometry.size.height
                    let gridSize: CGFloat = 100
                    
                    for x in stride(from: 0, through: width, by: gridSize) {
                        path.move(to: CGPoint(x: x, y: 0))
                        path.addLine(to: CGPoint(x: x, y: height))
                    }
                    
                    for y in stride(from: 0, through: height, by: gridSize) {
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: width, y: y))
                    }
                }
                .stroke(tvOSDesignSystem.colors.tertiaryText.opacity(0.1), lineWidth: 1)
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - tvOS Dashboard Header
struct TVDashboardHeader: View {
    var body: some View {
        VStack(spacing: tvOSDesignSystem.layout.spacing) {
            HStack {
                VStack(alignment: .leading, spacing: tvOSDesignSystem.layout.smallSpacing) {
                    Text("HealthAI 2030")
                        .font(tvOSDesignSystem.typography.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(tvOSDesignSystem.colors.primaryText)
                    
                    Text("Your Health Dashboard")
                        .font(tvOSDesignSystem.typography.title2)
                        .foregroundColor(tvOSDesignSystem.colors.secondaryText)
                }
                
                Spacer()
                
                TVTimeDisplay()
            }
            
            Divider()
                .background(tvOSDesignSystem.colors.secondaryText.opacity(0.3))
        }
    }
}

// MARK: - tvOS Time Display
struct TVTimeDisplay: View {
    @State private var currentTime = Date()
    
    var body: some View {
        VStack(alignment: .trailing, spacing: tvOSDesignSystem.layout.smallSpacing) {
            Text(timeString)
                .font(tvOSDesignSystem.typography.title1)
                .fontWeight(.semibold)
                .foregroundColor(tvOSDesignSystem.colors.primaryText)
            
            Text(dateString)
                .font(tvOSDesignSystem.typography.body)
                .foregroundColor(tvOSDesignSystem.colors.secondaryText)
        }
        .onAppear {
            Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                currentTime = Date()
            }
        }
    }
    
    private var timeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: currentTime)
    }
    
    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter.string(from: currentTime)
    }
}

// MARK: - tvOS Health Grid
struct TVHealthGrid: View {
    @Binding var selectedCard: String?
    let onCardSelected: (HealthMetric) -> Void
    
    private let columns = [
        GridItem(.adaptive(minimum: tvOSDesignSystem.layout.cardWidth), spacing: tvOSDesignSystem.layout.spacing)
    ]
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: tvOSDesignSystem.layout.spacing) {
            ForEach(HealthMetric.allCases, id: \.self) { metric in
                TVHealthCard(
                    metric: metric,
                    isSelected: selectedCard == metric.title
                ) {
                    selectedCard = metric.title
                    onCardSelected(metric)
                }
            }
        }
    }
}

// MARK: - tvOS Health Card
struct TVHealthCard: View {
    let metric: HealthMetric
    let isSelected: Bool
    let onTap: () -> Void
    @StateObject private var healthManager = HealthDataManager.shared
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: tvOSDesignSystem.layout.spacing) {
                // Icon and title
                HStack {
                    Image(systemName: metric.icon)
                        .font(.system(size: 48, weight: .medium))
                        .foregroundColor(metric.color)
                    
                    Spacer()
                    
                    Text(metric.title)
                        .font(tvOSDesignSystem.typography.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(tvOSDesignSystem.colors.primaryText)
                }
                
                // Metric value
                HStack(alignment: .bottom, spacing: tvOSDesignSystem.layout.smallSpacing) {
                    Text(metricValue)
                        .font(tvOSDesignSystem.typography.healthMetric)
                        .fontWeight(.bold)
                        .foregroundColor(tvOSDesignSystem.colors.primaryText)
                    
                    Text(metric.unit)
                        .font(tvOSDesignSystem.typography.healthUnit)
                        .foregroundColor(tvOSDesignSystem.colors.secondaryText)
                }
                
                // Status and trend
                HStack {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 12, height: 12)
                    
                    Text(statusText)
                        .font(tvOSDesignSystem.typography.body)
                        .foregroundColor(statusColor)
                    
                    Spacer()
                    
                    // Trend indicator
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(tvOSDesignSystem.colors.activity)
                        
                        Text("+2.3%")
                            .font(tvOSDesignSystem.typography.caption1)
                            .foregroundColor(tvOSDesignSystem.colors.activity)
                    }
                }
            }
            .padding(tvOSDesignSystem.layout.largePadding)
            .frame(width: tvOSDesignSystem.layout.cardWidth, height: tvOSDesignSystem.layout.cardHeight)
            .background(tvOSDesignSystem.colors.cardBackground)
            .cornerRadius(tvOSDesignSystem.layout.cornerRadius)
            .scaleEffect(isSelected ? tvOSDesignSystem.focus.focusScale : 1.0)
            .shadow(
                color: isSelected ? metric.color.opacity(tvOSDesignSystem.focus.focusShadowOpacity) : Color.clear,
                radius: isSelected ? tvOSDesignSystem.focus.focusShadowRadius : 0
            )
            .animation(tvOSDesignSystem.focus.focusAnimation, value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var metricValue: String {
        switch metric {
        case .heartRate:
            return "\(Int(healthManager.currentHeartRate))"
        case .sleep:
            return "7.5"
        case .activity:
            return "8,432"
        case .bloodPressure:
            return "120/80"
        case .temperature:
            return "98.6"
        }
    }
    
    private var statusColor: Color {
        switch metric {
        case .heartRate:
            let hr = healthManager.currentHeartRate
            switch hr {
            case 60..<100: return tvOSDesignSystem.colors.activity
            case 100..<120: return tvOSDesignSystem.colors.accent
            default: return tvOSDesignSystem.colors.heartRate
            }
        case .sleep:
            return tvOSDesignSystem.colors.activity
        case .activity:
            return tvOSDesignSystem.colors.activity
        case .bloodPressure:
            return tvOSDesignSystem.colors.activity
        case .temperature:
            return tvOSDesignSystem.colors.activity
        }
    }
    
    private var statusText: String {
        switch metric {
        case .heartRate:
            return "Normal"
        case .sleep:
            return "Good"
        case .activity:
            return "Active"
        case .bloodPressure:
            return "Normal"
        case .temperature:
            return "Normal"
        }
    }
}

// MARK: - tvOS Navigation Hints
struct TVNavigationHints: View {
    var body: some View {
        HStack(spacing: tvOSDesignSystem.layout.largeSpacing) {
            TVNavigationHint(
                icon: "arrow.up",
                text: "Navigate",
                color: tvOSDesignSystem.colors.primary
            )
            
            TVNavigationHint(
                icon: "play.fill",
                text: "Select",
                color: tvOSDesignSystem.colors.activity
            )
            
            TVNavigationHint(
                icon: "arrow.left",
                text: "Back",
                color: tvOSDesignSystem.colors.secondary
            )
        }
    }
}

struct TVNavigationHint: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: tvOSDesignSystem.layout.smallSpacing) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(color)
            
            Text(text)
                .font(tvOSDesignSystem.typography.body)
                .foregroundColor(tvOSDesignSystem.colors.secondaryText)
        }
        .padding(tvOSDesignSystem.layout.padding)
        .background(tvOSDesignSystem.colors.tertiaryBackground)
        .cornerRadius(tvOSDesignSystem.layout.cornerRadius)
    }
}

// MARK: - tvOS Detail View
struct TVDetailView: View {
    let metric: HealthMetric
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            tvOSBackgroundView()
            
            VStack(spacing: tvOSDesignSystem.layout.extraLargeSpacing) {
                // Header
                TVDetailHeader(metric: metric, onDismiss: { dismiss() })
                
                // Content
                TVDetailContent(metric: metric)
                
                // Actions
                TVDetailActions(metric: metric)
            }
            .padding(tvOSDesignSystem.layout.largePadding)
        }
    }
}

// MARK: - tvOS Detail Header
struct TVDetailHeader: View {
    let metric: HealthMetric
    let onDismiss: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: tvOSDesignSystem.layout.smallSpacing) {
                HStack(spacing: tvOSDesignSystem.layout.spacing) {
                    Image(systemName: metric.icon)
                        .font(.system(size: 64, weight: .medium))
                        .foregroundColor(metric.color)
                    
                    Text(metric.title)
                        .font(tvOSDesignSystem.typography.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(tvOSDesignSystem.colors.primaryText)
                }
                
                Text("Detailed Health Information")
                    .font(tvOSDesignSystem.typography.title2)
                    .foregroundColor(tvOSDesignSystem.colors.secondaryText)
            }
            
            Spacer()
            
            Button("Close") {
                onDismiss()
            }
            .font(tvOSDesignSystem.typography.title3)
            .foregroundColor(tvOSDesignSystem.colors.primary)
            .padding(tvOSDesignSystem.layout.padding)
            .background(tvOSDesignSystem.colors.cardBackground)
            .cornerRadius(tvOSDesignSystem.layout.cornerRadius)
        }
    }
}

// MARK: - tvOS Detail Content
struct TVDetailContent: View {
    let metric: HealthMetric
    
    var body: some View {
        HStack(spacing: tvOSDesignSystem.layout.largeSpacing) {
            // Chart section
            TVDetailChart(metric: metric)
            
            // Stats section
            TVDetailStats(metric: metric)
        }
    }
}

// MARK: - tvOS Detail Chart
struct TVDetailChart: View {
    let metric: HealthMetric
    
    var body: some View {
        VStack(spacing: tvOSDesignSystem.layout.spacing) {
            Text("24 Hour Trend")
                .font(tvOSDesignSystem.typography.title1)
                .fontWeight(.semibold)
                .foregroundColor(tvOSDesignSystem.colors.primaryText)
            
            // Placeholder chart
            RoundedRectangle(cornerRadius: tvOSDesignSystem.layout.cornerRadius)
                .fill(tvOSDesignSystem.colors.cardBackground)
                .frame(width: tvOSDesignSystem.layout.largeCardWidth, height: tvOSDesignSystem.layout.largeCardHeight)
                .overlay(
                    VStack(spacing: tvOSDesignSystem.layout.spacing) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 64, weight: .medium))
                            .foregroundColor(tvOSDesignSystem.colors.secondaryText)
                        
                        Text("Interactive Chart")
                            .font(tvOSDesignSystem.typography.title2)
                            .foregroundColor(tvOSDesignSystem.colors.secondaryText)
                        
                        Text("Tap to view detailed analytics")
                            .font(tvOSDesignSystem.typography.body)
                            .foregroundColor(tvOSDesignSystem.colors.tertiaryText)
                    }
                )
        }
    }
}

// MARK: - tvOS Detail Stats
struct TVDetailStats: View {
    let metric: HealthMetric
    
    var body: some View {
        VStack(spacing: tvOSDesignSystem.layout.spacing) {
            Text("Statistics")
                .font(tvOSDesignSystem.typography.title1)
                .fontWeight(.semibold)
                .foregroundColor(tvOSDesignSystem.colors.primaryText)
            
            VStack(spacing: tvOSDesignSystem.layout.smallSpacing) {
                TVStatRow(label: "Current", value: currentValue, status: .healthy)
                TVStatRow(label: "Average", value: averageValue, status: .healthy)
                TVStatRow(label: "Goal", value: goalValue, status: .healthy)
                TVStatRow(label: "Trend", value: trendValue, status: .healthy)
            }
        }
        .padding(tvOSDesignSystem.layout.largePadding)
        .background(tvOSDesignSystem.colors.cardBackground)
        .cornerRadius(tvOSDesignSystem.layout.cornerRadius)
    }
    
    private var currentValue: String {
        switch metric {
        case .heartRate: return "72 BPM"
        case .sleep: return "7.5 hrs"
        case .activity: return "8,432 steps"
        case .bloodPressure: return "120/80 mmHg"
        case .temperature: return "98.6°F"
        }
    }
    
    private var averageValue: String {
        switch metric {
        case .heartRate: return "71 BPM"
        case .sleep: return "7.2 hrs"
        case .activity: return "7,890 steps"
        case .bloodPressure: return "118/78 mmHg"
        case .temperature: return "98.4°F"
        }
    }
    
    private var goalValue: String {
        switch metric {
        case .heartRate: return "60-100 BPM"
        case .sleep: return "7-9 hrs"
        case .activity: return "10,000 steps"
        case .bloodPressure: return "<120/80 mmHg"
        case .temperature: return "98.6°F"
        }
    }
    
    private var trendValue: String {
        switch metric {
        case .heartRate: return "+2.3%"
        case .sleep: return "+0.5 hrs"
        case .activity: return "+542 steps"
        case .bloodPressure: return "-2/-2 mmHg"
        case .temperature: return "-0.2°F"
        }
    }
}

// MARK: - tvOS Stat Row
struct TVStatRow: View {
    let label: String
    let value: String
    let status: HealthStatus
    
    var body: some View {
        HStack {
            Text(label)
                .font(tvOSDesignSystem.typography.body)
                .foregroundColor(tvOSDesignSystem.colors.secondaryText)
            
            Spacer()
            
            Text(value)
                .font(tvOSDesignSystem.typography.title3)
                .fontWeight(.semibold)
                .foregroundColor(statusColor)
        }
        .padding(tvOSDesignSystem.layout.padding)
        .background(tvOSDesignSystem.colors.tertiaryBackground)
        .cornerRadius(tvOSDesignSystem.layout.smallCornerRadius)
    }
    
    private var statusColor: Color {
        switch status {
        case .healthy: return tvOSDesignSystem.colors.activity
        case .elevated: return tvOSDesignSystem.colors.accent
        case .critical: return tvOSDesignSystem.colors.heartRate
        case .unknown: return tvOSDesignSystem.colors.secondaryText
        }
    }
}

// MARK: - tvOS Detail Actions
struct TVDetailActions: View {
    let metric: HealthMetric
    
    var body: some View {
        HStack(spacing: tvOSDesignSystem.layout.spacing) {
            TVActionButton(title: "Export Data", icon: "square.and.arrow.up") {
                // Export action
            }
            
            TVActionButton(title: "Share Report", icon: "square.and.arrow.up") {
                // Share action
            }
            
            TVActionButton(title: "Set Reminder", icon: "bell") {
                // Reminder action
            }
            
            TVActionButton(title: "View History", icon: "clock") {
                // History action
            }
        }
    }
}

// MARK: - tvOS Action Button
struct TVActionButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    @State private var isFocused = false
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: tvOSDesignSystem.layout.smallSpacing) {
                Image(systemName: icon)
                    .font(.system(size: 32, weight: .medium))
                    .foregroundColor(tvOSDesignSystem.colors.primary)
                
                Text(title)
                    .font(tvOSDesignSystem.typography.body)
                    .foregroundColor(tvOSDesignSystem.colors.primaryText)
            }
            .frame(width: 200, height: 120)
            .background(tvOSDesignSystem.colors.cardBackground)
            .cornerRadius(tvOSDesignSystem.layout.cornerRadius)
            .scaleEffect(isFocused ? tvOSDesignSystem.focus.focusScale : 1.0)
            .shadow(
                color: isFocused ? tvOSDesignSystem.colors.primary.opacity(tvOSDesignSystem.focus.focusShadowOpacity) : Color.clear,
                radius: isFocused ? tvOSDesignSystem.focus.focusShadowRadius : 0
            )
            .animation(tvOSDesignSystem.focus.focusAnimation, value: isFocused)
        }
        .buttonStyle(PlainButtonStyle())
        .onFocusChanged { focused in
            isFocused = focused
        }
    }
}

// MARK: - Focus Management Extension
extension View {
    func onFocusChanged(_ action: @escaping (Bool) -> Void) -> some View {
        self
            .onReceive(NotificationCenter.default.publisher(for: UIFocusSystem.didUpdateFocusNotification)) { notification in
                if let context = notification.object as? UIFocusUpdateContext {
                    action(context.nextFocusedItem != nil)
                }
            }
    }
}

// MARK: - tvOS Remote Control Integration
class TVRemoteControlManager: ObservableObject {
    public static let shared = TVRemoteControlManager()
    
    @Published public var currentFocus: String? = nil
    @Published public var isPlaying = false
    
    private init() {
        setupRemoteControlHandling()
    }
    
    private func setupRemoteControlHandling() {
        // Setup remote control event handling
        // This would typically involve UIKeyCommand setup
    }
    
    public func handlePlayPause() {
        isPlaying.toggle()
        // Handle play/pause action
    }
    
    public func handleMenu() {
        // Handle menu button
    }
    
    public func handleSelect() {
        // Handle select button
    }
}

// MARK: - tvOS Accessibility
struct TVAccessibilityModifiers {
    static func healthCard(_ view: some View, metric: HealthMetric, value: String) -> some View {
        view
            .accessibilityLabel("\(metric.title) card")
            .accessibilityValue("\(value) \(metric.unit)")
            .accessibilityHint("Double tap to view detailed information")
            .accessibilityAddTraits(.isButton)
    }
    
    static func navigationHint(_ view: some View, action: String) -> some View {
        view
            .accessibilityLabel("Navigation hint")
            .accessibilityValue(action)
            .accessibilityAddTraits(.isStaticText)
    }
}

// MARK: - tvOS Preview
struct tvOSLivingRoomAssets_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            if #available(tvOS 17.0, *) {
                TVOptimizedHealthDashboard()
                    .previewDevice("Apple TV 4K (3rd generation)")
                
                TVDetailView(metric: .heartRate)
                    .previewDevice("Apple TV 4K (3rd generation)")
            }
        }
    }
} 
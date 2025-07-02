import SwiftUI

@available(iOS 17.0, *)
@available(macOS 14.0, *)

/// Utility view for automatically switching between VStack and HStack based on horizontal size class.
struct AdaptiveStack<Content: View>: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    let hAlignment: HorizontalAlignment
    let vAlignment: VerticalAlignment
    let spacing: CGFloat?
    let content: () -> Content

    init(hAlignment: HorizontalAlignment = .center,
         vAlignment: VerticalAlignment = .center,
         spacing: CGFloat? = nil,
         @ViewBuilder content: @escaping () -> Content) {
        self.hAlignment = hAlignment
        self.vAlignment = vAlignment
        self.spacing = spacing
        self.content = content
    }

    var body: some View {
        if horizontalSizeClass == .regular {
            HStack(alignment: vAlignment, spacing: spacing, content: content)
        } else {
            VStack(alignment: hAlignment, spacing: spacing, content: content)
        }
    }
}

// MARK: - iPad Adaptive Layout System

/// Device type detection for adaptive layouts
enum DeviceType {
    case iPhone
    case iPadPortrait
    case iPadLandscape
    case iPadPro
    case mac
    
    static var current: DeviceType {
        #if os(macOS)
        return .mac
        #else
        let idiom = UIDevice.current.userInterfaceIdiom
        
        switch idiom {
        case .phone:
            return .iPhone
        case .pad:
            let screenWidth = UIScreen.main.bounds.width
            let screenHeight = UIScreen.main.bounds.height
            let isLandscape = screenWidth > screenHeight
            
            // iPad Pro detection (12.9" has 1024x1366 points)
            if max(screenWidth, screenHeight) >= 1366 {
                return .iPadPro
            }
            
            return isLandscape ? .iPadLandscape : .iPadPortrait
        default:
            return .iPhone
        }
        #endif
    }
    
    var isIPad: Bool {
        switch self {
        case .iPadPortrait, .iPadLandscape, .iPadPro:
            return true
        default:
            return false
        }
    }
    
    var columnCount: Int {
        switch self {
        case .iPhone:
            return 1
        case .iPadPortrait:
            return 2
        case .iPadLandscape, .iPadPro:
            return 3
        case .mac:
            return 4
        }
    }
    
    var spacing: CGFloat {
        switch self {
        case .iPhone:
            return 16
        case .iPadPortrait, .iPadLandscape:
            return 20
        case .iPadPro, .mac:
            return 24
        }
    }
    
    var cardPadding: CGFloat {
        switch self {
        case .iPhone:
            return 16
        case .iPadPortrait, .iPadLandscape:
            return 20
        case .iPadPro, .mac:
            return 24
        }
    }
}

// MARK: - Adaptive Grid Layout

struct AdaptiveGrid<Content: View>: View {
    let spacing: CGFloat
    let content: () -> Content
    
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    
    private var deviceType: DeviceType {
        DeviceType.current
    }
    
    private var columns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: spacing), count: deviceType.columnCount)
    }
    
    init(spacing: CGFloat = 20, @ViewBuilder content: @escaping () -> Content) {
        self.spacing = spacing
        self.content = content
    }
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: spacing) {
            content()
        }
        .padding(.horizontal, deviceType.cardPadding)
    }
}

// MARK: - iPad-Optimized Dashboard Layout

struct iPadDashboardLayout<Content: View>: View {
    let content: () -> Content
    
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    
    private var deviceType: DeviceType {
        DeviceType.current
    }
    
    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }
    
    var body: some View {
        Group {
            if deviceType.isIPad {
                iPadOptimizedLayout
            } else {
                iPhoneLayout
            }
        }
    }
    
    private var iPadOptimizedLayout: some View {
        GeometryReader { geometry in
            let isLandscape = geometry.size.width > geometry.size.height
            
            if isLandscape {
                HSplitView {
                    // Left sidebar with key metrics
                    iPadSidebar()
                        .frame(width: 300)
                    
                    // Main content area
                    ScrollView {
                        AdaptiveGrid(spacing: deviceType.spacing) {
                            content()
                        }
                    }
                }
            } else {
                // Portrait mode - stacked layout
                ScrollView {
                    VStack(spacing: deviceType.spacing) {
                        // Compact metrics bar
                        iPadCompactMetrics()
                        
                        AdaptiveGrid(spacing: deviceType.spacing) {
                            content()
                        }
                    }
                    .padding(deviceType.cardPadding)
                }
            }
        }
    }
    
    private var iPhoneLayout: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                content()
            }
            .padding()
        }
    }
}

// MARK: - iPad Sidebar Components

struct iPadSidebar: View {
    @StateObject private var healthDataManager = HealthDataManager.shared
    @StateObject private var predictiveAnalytics = PredictiveAnalyticsManager.shared
    
    var body: some View {
        VStack(spacing: 20) {
            // Current time and date
            iPadTimeHeader()
            
            // Key health metrics
            iPadQuickMetrics()
            
            // Today's summary
            iPadDailySummary()
            
            // Quick actions
            iPadQuickActions()
            
            Spacer()
        }
        .padding()
        .background(Color(.secondarySystemBackground))
    }
}

struct iPadTimeHeader: View {
    @State private var currentTime = Date()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(currentTime, style: .time)
                .font(.system(size: 32, weight: .bold, design: .rounded))
            
            Text(currentTime, style: .date)
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
            currentTime = Date()
        }
    }
}

struct iPadQuickMetrics: View {
    @StateObject private var healthDataManager = HealthDataManager.shared
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Quick Metrics")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 12) {
                iPadMetricRow(
                    title: "Heart Rate",
                    value: "\(Int(healthDataManager.currentHeartRate))",
                    unit: "BPM",
                    icon: "heart.fill",
                    color: .red
                )
                
                iPadMetricRow(
                    title: "HRV",
                    value: String(format: "%.1f", healthDataManager.currentHRV),
                    unit: "ms",
                    icon: "waveform.path.ecg",
                    color: .green
                )
                
                iPadMetricRow(
                    title: "Steps",
                    value: "\(healthDataManager.stepCount)",
                    unit: "",
                    icon: "figure.walk",
                    color: .blue
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

struct iPadMetricRow: View {
    let title: String
    let value: String
    let unit: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack(alignment: .bottom, spacing: 2) {
                    Text(value)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    if !unit.isEmpty {
                        Text(unit)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
        }
    }
}

struct iPadDailySummary: View {
    @StateObject private var predictiveAnalytics = PredictiveAnalyticsManager.shared
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Today's Summary")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 12) {
                iPadSummaryRow(
                    title: "Sleep Quality",
                    value: 0.85,
                    color: .purple
                )
                
                iPadSummaryRow(
                    title: "Recovery",
                    value: 0.78,
                    color: .green
                )
                
                iPadSummaryRow(
                    title: "Stress Level",
                    value: 0.32,
                    color: .orange
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

struct iPadSummaryRow: View {
    let title: String
    let value: Double
    let color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            HStack {
                Text(title)
                    .font(.subheadline)
                Spacer()
                Text("\(Int(value * 100))%")
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            
            ProgressView(value: value)
                .progressViewStyle(LinearProgressViewStyle(tint: color))
                .frame(height: 6)
        }
    }
}

struct iPadQuickActions: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("Quick Actions")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 12) {
                iPadActionButton(
                    title: "Start Sleep Session",
                    icon: "bed.double.fill",
                    color: .purple
                ) {
                    // Action
                }
                
                iPadActionButton(
                    title: "Meditation",
                    icon: "brain.head.profile",
                    color: .blue
                ) {
                    // Action
                }
                
                iPadActionButton(
                    title: "Environment Optimize",
                    icon: "house.fill",
                    color: .green
                ) {
                    // Action
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

struct iPadActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .frame(width: 24)
                
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - iPad Compact Metrics (Portrait Mode)

struct iPadCompactMetrics: View {
    @StateObject private var healthDataManager = HealthDataManager.shared
    
    var body: some View {
        HStack(spacing: 20) {
            iPadCompactMetric(
                title: "HR",
                value: "\(Int(healthDataManager.currentHeartRate))",
                unit: "BPM",
                color: .red
            )
            
            iPadCompactMetric(
                title: "HRV",
                value: String(format: "%.0f", healthDataManager.currentHRV),
                unit: "ms",
                color: .green
            )
            
            iPadCompactMetric(
                title: "Steps",
                value: "\(healthDataManager.stepCount)",
                unit: "",
                color: .blue
            )
            
            iPadCompactMetric(
                title: "Sleep",
                value: "8.2",
                unit: "hrs",
                color: .purple
            )
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

struct iPadCompactMetric: View {
    let title: String
    let value: String
    let unit: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack(alignment: .bottom, spacing: 2) {
                Text(value)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(color)
                
                if !unit.isEmpty {
                    Text(unit)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Responsive Card Layout

struct ResponsiveCard<Content: View>: View {
    let content: () -> Content
    
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    private var deviceType: DeviceType {
        DeviceType.current
    }
    
    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }
    
    var body: some View {
        content()
            .padding(deviceType.cardPadding)
            .background(Color(.systemBackground))
            .cornerRadius(deviceType.isIPad ? 16 : 12)
            .shadow(
                color: Color.black.opacity(0.1),
                radius: deviceType.isIPad ? 8 : 4,
                x: 0,
                y: deviceType.isIPad ? 4 : 2
            )
    }
}

// MARK: - iPad Navigation Enhancements

struct iPadNavigationEnhancement: ViewModifier {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    private var deviceType: DeviceType {
        DeviceType.current
    }
    
    func body(content: Content) -> some View {
        content
            .navigationBarTitleDisplayMode(deviceType.isIPad ? .inline : .large)
            .toolbar {
                if deviceType.isIPad {
                    ToolbarItemGroup(placement: .navigationBarTrailing) {
                        iPadToolbarButtons()
                    }
                }
            }
    }
}

struct iPadToolbarButtons: View {
    var body: some View {
        HStack {
            Button(action: {
                // Settings action
            }) {
                Image(systemName: "gearshape.fill")
            }
            
            Button(action: {
                // Refresh action
            }) {
                Image(systemName: "arrow.clockwise")
            }
            
            Button(action: {
                // Share action
            }) {
                Image(systemName: "square.and.arrow.up")
            }
        }
    }
}

extension View {
    func iPadOptimized() -> some View {
        self.modifier(iPadNavigationEnhancement())
    }
}

// MARK: - Split View Container for iPad

@available(iOS 17.0, *)
struct HSplitView<Leading: View, Trailing: View>: View {
    let leading: Leading
    let trailing: Trailing
    
    init(@ViewBuilder leading: () -> Leading, @ViewBuilder trailing: () -> Trailing) {
        self.leading = leading()
        self.trailing = trailing()
    }
    
    var body: some View {
        HStack(spacing: 0) {
            leading
            
            Divider()
            
            trailing
        }
    }
}

import SwiftUI
import WatchKit

// MARK: - watchOS Platform Optimization
/// Compact assets and components specifically designed for watchOS platform
/// Handles watchOS-specific design patterns, compact layouts, and wrist-optimized components

// MARK: - watchOS-Specific Design System
struct watchOSDesignSystem {
    /// watchOS-specific color palette optimized for small displays
    static let colors = watchOSColorPalette()
    
    /// watchOS-specific typography optimized for small screens
    static let typography = watchOSTypography()
    
    /// watchOS-specific spacing and layout guidelines
    static let layout = watchOSLayoutGuide()
    
    /// watchOS-specific complications
    static let complications = watchOSComplications()
}

// MARK: - watchOS Color Palette
struct watchOSColorPalette {
    /// Primary colors optimized for watchOS
    let primary = Color(red: 0.0, green: 0.478, blue: 1.0)
    let secondary = Color(red: 0.584, green: 0.584, blue: 0.584)
    let accent = Color(red: 1.0, green: 0.231, blue: 0.188)
    
    /// Health-specific colors for watch
    let heartRate = Color(red: 1.0, green: 0.231, blue: 0.188)
    let bloodPressure = Color(red: 0.0, green: 0.478, blue: 1.0)
    let sleep = Color(red: 0.584, green: 0.0, blue: 0.827)
    let activity = Color(red: 0.0, green: 0.827, blue: 0.584)
    
    /// Background colors optimized for watchOS
    let background = Color.black
    let secondaryBackground = Color(red: 0.1, green: 0.1, blue: 0.1)
    let tertiaryBackground = Color(red: 0.15, green: 0.15, blue: 0.15)
    
    /// Text colors optimized for watchOS
    let primaryText = Color.white
    let secondaryText = Color(red: 0.8, green: 0.8, blue: 0.8)
    let tertiaryText = Color(red: 0.6, green: 0.6, blue: 0.6)
}

// MARK: - watchOS Typography
struct watchOSTypography {
    /// watchOS-optimized font sizes and weights
    let largeTitle = Font.system(size: 28, weight: .bold, design: .rounded)
    let title1 = Font.system(size: 24, weight: .semibold, design: .rounded)
    let title2 = Font.system(size: 20, weight: .semibold, design: .rounded)
    let title3 = Font.system(size: 18, weight: .medium, design: .rounded)
    let headline = Font.system(size: 16, weight: .semibold, design: .rounded)
    let body = Font.system(size: 14, weight: .regular, design: .rounded)
    let callout = Font.system(size: 13, weight: .medium, design: .rounded)
    let subheadline = Font.system(size: 12, weight: .medium, design: .rounded)
    let footnote = Font.system(size: 11, weight: .regular, design: .rounded)
    let caption1 = Font.system(size: 10, weight: .regular, design: .rounded)
    let caption2 = Font.system(size: 9, weight: .regular, design: .rounded)
    
    /// Health-specific typography for watch
    let healthMetric = Font.system(size: 32, weight: .bold, design: .rounded)
    let healthLabel = Font.system(size: 12, weight: .medium, design: .rounded)
    let healthUnit = Font.system(size: 10, weight: .regular, design: .rounded)
}

// MARK: - watchOS Layout Guide
struct watchOSLayoutGuide {
    /// watchOS-specific spacing
    let spacing: CGFloat = 8
    let smallSpacing: CGFloat = 4
    let largeSpacing: CGFloat = 12
    let extraLargeSpacing: CGFloat = 16
    
    /// watchOS-specific corner radius
    let cornerRadius: CGFloat = 8
    let smallCornerRadius: CGFloat = 4
    let largeCornerRadius: CGFloat = 12
    
    /// watchOS-specific padding
    let padding: CGFloat = 8
    let smallPadding: CGFloat = 4
    let largePadding: CGFloat = 12
    
    /// watchOS-specific screen dimensions
    let screenWidth: CGFloat = 180
    let screenHeight: CGFloat = 180
    let contentWidth: CGFloat = 160
    let contentHeight: CGFloat = 160
}

// MARK: - watchOS Complications
struct watchOSComplications {
    /// Complication types supported
    static let supportedTypes: [WKComplicationFamily] = [
        .modularSmall,
        .modularLarge,
        .utilitarianSmall,
        .utilitarianLarge,
        .circularSmall,
        .extraLarge,
        .graphicCorner,
        .graphicBezel,
        .graphicCircular,
        .graphicRectangular
    ]
}

// MARK: - watchOS-Optimized Components

// MARK: - watchOS Health Metric Card
struct watchOSHealthMetricCard: View {
    let title: String
    let value: String
    let unit: String
    let trend: HealthTrend?
    let color: Color
    
    var body: some View {
        VStack(spacing: watchOSDesignSystem.layout.smallSpacing) {
            Text(title)
                .font(watchOSDesignSystem.typography.healthLabel)
                .foregroundColor(watchOSDesignSystem.colors.secondaryText)
                .lineLimit(1)
            
            HStack(alignment: .bottom, spacing: 2) {
                Text(value)
                    .font(watchOSDesignSystem.typography.healthMetric)
                    .foregroundColor(color)
                    .lineLimit(1)
                
                Text(unit)
                    .font(watchOSDesignSystem.typography.healthUnit)
                    .foregroundColor(watchOSDesignSystem.colors.secondaryText)
                    .lineLimit(1)
            }
            
            if let trend = trend {
                watchOSHealthTrendIndicator(trend: trend)
            }
        }
        .padding(watchOSDesignSystem.layout.padding)
        .background(watchOSDesignSystem.colors.secondaryBackground)
        .cornerRadius(watchOSDesignSystem.layout.cornerRadius)
    }
}

struct watchOSHealthTrendIndicator: View {
    let trend: HealthTrend
    
    var body: some View {
        Image(systemName: trend.icon)
            .foregroundColor(trend.color)
            .font(.caption)
    }
}

// MARK: - watchOS Compact List
struct watchOSCompactList<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: watchOSDesignSystem.layout.smallSpacing) {
                content
            }
            .padding(.horizontal, watchOSDesignSystem.layout.padding)
        }
    }
}

// MARK: - watchOS Compact Row
struct watchOSCompactRow: View {
    let title: String
    let subtitle: String?
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: watchOSDesignSystem.layout.smallSpacing) {
                Image(systemName: icon)
                    .font(watchOSDesignSystem.typography.callout)
                    .foregroundColor(watchOSDesignSystem.colors.primary)
                    .frame(width: 16)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(watchOSDesignSystem.typography.body)
                        .foregroundColor(watchOSDesignSystem.colors.primaryText)
                        .lineLimit(1)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(watchOSDesignSystem.typography.caption1)
                            .foregroundColor(watchOSDesignSystem.colors.secondaryText)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(watchOSDesignSystem.typography.caption1)
                    .foregroundColor(watchOSDesignSystem.colors.tertiaryText)
            }
            .padding(watchOSDesignSystem.layout.smallPadding)
            .background(watchOSDesignSystem.colors.secondaryBackground)
            .cornerRadius(watchOSDesignSystem.layout.smallCornerRadius)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - watchOS Circular Progress
struct watchOSCircularProgress: View {
    let progress: Double
    let color: Color
    let size: CGFloat
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.3), lineWidth: 4)
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(color, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.5), value: progress)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - watchOS Quick Action Button
struct watchOSQuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: watchOSDesignSystem.layout.smallSpacing) {
                Image(systemName: icon)
                    .font(watchOSDesignSystem.typography.title3)
                    .foregroundColor(color)
                
                Text(title)
                    .font(watchOSDesignSystem.typography.caption1)
                    .foregroundColor(watchOSDesignSystem.colors.primaryText)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(watchOSDesignSystem.layout.smallPadding)
            .background(watchOSDesignSystem.colors.secondaryBackground)
            .cornerRadius(watchOSDesignSystem.layout.cornerRadius)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - watchOS Health Dashboard
struct watchOSHealthDashboard: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Overview Tab
            watchOSOverviewTab()
                .tag(0)
            
            // Activity Tab
            watchOSActivityTab()
                .tag(1)
            
            // Health Tab
            watchOSHealthTab()
                .tag(2)
        }
        .tabViewStyle(PageTabViewStyle())
        .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
    }
}

struct watchOSOverviewTab: View {
    var body: some View {
        VStack(spacing: watchOSDesignSystem.layout.spacing) {
            // Main metric
            watchOSHealthMetricCard(
                title: "Heart Rate",
                value: "72",
                unit: "bpm",
                trend: .up,
                color: watchOSDesignSystem.colors.heartRate
            )
            
            // Quick actions
            HStack(spacing: watchOSDesignSystem.layout.smallSpacing) {
                watchOSQuickActionButton(
                    title: "Start",
                    icon: "play.fill",
                    color: watchOSDesignSystem.colors.activity
                ) {}
                
                watchOSQuickActionButton(
                    title: "Settings",
                    icon: "gear",
                    color: watchOSDesignSystem.colors.secondary
                ) {}
            }
        }
        .padding(watchOSDesignSystem.layout.padding)
    }
}

struct watchOSActivityTab: View {
    var body: some View {
        VStack(spacing: watchOSDesignSystem.layout.spacing) {
            // Activity ring
            ZStack {
                watchOSCircularProgress(
                    progress: 0.75,
                    color: watchOSDesignSystem.colors.activity,
                    size: 80
                )
                
                VStack(spacing: 2) {
                    Text("75%")
                        .font(watchOSDesignSystem.typography.title2)
                        .foregroundColor(watchOSDesignSystem.colors.primaryText)
                    
                    Text("Goal")
                        .font(watchOSDesignSystem.typography.caption1)
                        .foregroundColor(watchOSDesignSystem.colors.secondaryText)
                }
            }
            
            // Activity stats
            VStack(spacing: watchOSDesignSystem.layout.smallSpacing) {
                watchOSCompactRow(
                    title: "Steps",
                    subtitle: "8,432 / 10,000",
                    icon: "figure.walk"
                ) {}
                
                watchOSCompactRow(
                    title: "Calories",
                    subtitle: "342 burned",
                    icon: "flame"
                ) {}
            }
        }
        .padding(watchOSDesignSystem.layout.padding)
    }
}

struct watchOSHealthTab: View {
    var body: some View {
        watchOSCompactList {
            watchOSCompactRow(
                title: "Heart Rate",
                subtitle: "72 bpm",
                icon: "heart.fill"
            ) {}
            
            watchOSCompactRow(
                title: "Blood Pressure",
                subtitle: "120/80 mmHg",
                icon: "drop.fill"
            ) {}
            
            watchOSCompactRow(
                title: "Sleep",
                subtitle: "7h 23m",
                icon: "bed.double.fill"
            ) {}
            
            watchOSCompactRow(
                title: "Stress",
                subtitle: "Low",
                icon: "brain.head.profile"
            ) {}
        }
    }
}

// MARK: - watchOS Complications

// MARK: - Modular Small Complication
struct watchOSModularSmallComplication: View {
    let metric: HealthMetric
    
    var body: some View {
        VStack(spacing: 2) {
            Text(metric.value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(metric.color)
                .lineLimit(1)
            
            Text(metric.unit)
                .font(.system(size: 8, weight: .regular, design: .rounded))
                .foregroundColor(watchOSDesignSystem.colors.secondaryText)
                .lineLimit(1)
        }
    }
}

// MARK: - Circular Small Complication
struct watchOSCircularSmallComplication: View {
    let progress: Double
    let color: Color
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.3), lineWidth: 3)
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(color, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
    }
}

// MARK: - Graphic Circular Complication
struct watchOSGraphicCircularComplication: View {
    let metric: HealthMetric
    let progress: Double
    
    var body: some View {
        ZStack {
            // Progress ring
            Circle()
                .stroke(metric.color.opacity(0.3), lineWidth: 6)
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(metric.color, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                .rotationEffect(.degrees(-90))
            
            // Center content
            VStack(spacing: 2) {
                Text(metric.value)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(metric.color)
                    .lineLimit(1)
                
                Text(metric.unit)
                    .font(.system(size: 8, weight: .regular, design: .rounded))
                    .foregroundColor(watchOSDesignSystem.colors.secondaryText)
                    .lineLimit(1)
            }
        }
    }
}

// MARK: - watchOS Haptic Feedback
class watchOSHapticManager {
    static let shared = watchOSHapticManager()
    
    private init() {}
    
    func notification(type: WKHapticType) {
        WKInterfaceDevice.current().play(type)
    }
    
    func startWorkout() {
        WKInterfaceDevice.current().play(.start)
    }
    
    func stopWorkout() {
        WKInterfaceDevice.current().play(.stop)
    }
    
    func success() {
        WKInterfaceDevice.current().play(.success)
    }
    
    func failure() {
        WKInterfaceDevice.current().play(.failure)
    }
    
    func retry() {
        WKInterfaceDevice.current().play(.retry)
    }
    
    func click() {
        WKInterfaceDevice.current().play(.click)
    }
}

// MARK: - watchOS Accessibility
struct watchOSAccessibilityModifiers {
    static func healthMetric(_ view: some View, value: String, unit: String, label: String) -> some View {
        view
            .accessibilityLabel(label)
            .accessibilityValue("\(value) \(unit)")
            .accessibilityAddTraits(.isStaticText)
    }
    
    static func quickAction(_ view: some View, title: String, action: String) -> some View {
        view
            .accessibilityLabel(title)
            .accessibilityHint(action)
            .accessibilityAddTraits(.isButton)
    }
}

// MARK: - watchOS Preview
struct watchOSCompactAssets_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            watchOSHealthDashboard()
                .previewDevice("Apple Watch Series 7 (45mm)")
            
            watchOSModularSmallComplication(
                metric: HealthMetric(
                    id: "1",
                    title: "Heart Rate",
                    value: "72",
                    unit: "bpm",
                    trend: .up,
                    color: .red
                )
            )
            .previewDevice("Apple Watch Series 7 (45mm)")
            
            watchOSGraphicCircularComplication(
                metric: HealthMetric(
                    id: "2",
                    title: "Activity",
                    value: "75",
                    unit: "%",
                    trend: .up,
                    color: .green
                ),
                progress: 0.75
            )
            .previewDevice("Apple Watch Series 7 (45mm)")
        }
    }
} 
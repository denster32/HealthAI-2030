import SwiftUI
#if canImport(WatchKit)
import WatchKit
#endif

// MARK: - watchOS Platform Optimization
/// Optimized interface elements specifically designed for watchOS platform
/// Handles watchOS-specific design patterns, Digital Crown integration, and glanceable components

// MARK: - watchOS-Specific Design System
struct watchOSDesignSystem {
    /// watchOS-specific color palette optimized for small displays
    static let colors = watchOSColorPalette()
    
    /// watchOS-specific typography optimized for watch readability
    static let typography = watchOSTypography()
    
    /// watchOS-specific spacing and layout guidelines
    static let layout = watchOSLayoutGuide()
    
    /// watchOS-specific Digital Crown integration
    static let digitalCrown = watchOSDigitalCrownGuide()
}

// MARK: - watchOS Color Palette
struct watchOSColorPalette {
    /// Primary colors optimized for watchOS
    let primary = Color(red: 0.0, green: 0.478, blue: 1.0)
    let secondary = Color(red: 0.584, green: 0.584, blue: 0.584)
    let accent = Color(red: 1.0, green: 0.231, blue: 0.188)
    
    /// Health-specific colors for watchOS
    let heartRate = Color(red: 1.0, green: 0.231, blue: 0.188)
    let bloodPressure = Color(red: 0.0, green: 0.478, blue: 1.0)
    let sleep = Color(red: 0.584, green: 0.0, blue: 0.827)
    let activity = Color(red: 0.0, green: 0.827, blue: 0.584)
    
    /// Background colors optimized for watchOS
    let background = Color.black
    let secondaryBackground = Color(red: 0.1, green: 0.1, blue: 0.1)
    let tertiaryBackground = Color(red: 0.2, green: 0.2, blue: 0.2)
    
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
    let callout = Font.system(size: 13, weight: .regular, design: .rounded)
    let subheadline = Font.system(size: 12, weight: .medium, design: .rounded)
    let footnote = Font.system(size: 11, weight: .regular, design: .rounded)
    let caption1 = Font.system(size: 10, weight: .regular, design: .rounded)
    let caption2 = Font.system(size: 9, weight: .regular, design: .rounded)
    
    /// Health-specific typography for watchOS
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
    let screenHeight: CGFloat = 220
    let complicationWidth: CGFloat = 160
    let complicationHeight: CGFloat = 20
}

// MARK: - watchOS Digital Crown Guide
struct watchOSDigitalCrownGuide {
    /// Digital Crown sensitivity settings
    let sensitivity: WKDigitalCrownSensitivity = .medium
    let isContinuous: Bool = false
    let isHapticFeedbackEnabled: Bool = true
}

// MARK: - watchOS-Optimized Health View
@available(watchOS 11.0, *)
public struct WatchOptimizedHealthView: View {
    @State private var crownValue: Double = 0
    @State private var selectedMetric: HealthMetric = .heartRate
    @State private var showingDetail = false
    
    public var body: some View {
        ScrollView {
            VStack(spacing: watchOSDesignSystem.layout.largeSpacing) {
                // Crown-controlled metric selector
                WatchMetricSelector(selectedMetric: $selectedMetric, crownValue: $crownValue)
                
                // Current metric display
                WatchMetricDisplay(metric: selectedMetric)
                
                // Quick actions
                WatchQuickActions()
            }
            .padding(watchOSDesignSystem.layout.padding)
        }
        .digitalCrownRotation($crownValue, from: 0, through: Double(HealthMetric.allCases.count - 1), by: 1.0, sensitivity: watchOSDesignSystem.digitalCrown.sensitivity, isContinuous: watchOSDesignSystem.digitalCrown.isContinuous, isHapticFeedbackEnabled: watchOSDesignSystem.digitalCrown.isHapticFeedbackEnabled)
        .onChange(of: crownValue) { newValue in
            let index = Int(newValue)
            if index < HealthMetric.allCases.count {
                selectedMetric = HealthMetric.allCases[index]
            }
        }
        .sheet(isPresented: $showingDetail) {
            WatchDetailView(metric: selectedMetric)
        }
    }
}

// MARK: - watchOS Metric Selector
struct WatchMetricSelector: View {
    @Binding var selectedMetric: HealthMetric
    @Binding var crownValue: Double
    
    var body: some View {
        HStack(spacing: watchOSDesignSystem.layout.smallSpacing) {
            ForEach(HealthMetric.allCases, id: \.self) { metric in
                VStack(spacing: watchOSDesignSystem.layout.smallSpacing) {
                    Image(systemName: metric.icon)
                        .font(.title2)
                        .foregroundColor(selectedMetric == metric ? metric.color : watchOSDesignSystem.colors.secondaryText)
                    
                    Text(metric.shortName)
                        .font(watchOSDesignSystem.typography.caption2)
                        .foregroundColor(selectedMetric == metric ? metric.color : watchOSDesignSystem.colors.secondaryText)
                }
                .scaleEffect(selectedMetric == metric ? 1.2 : 1.0)
                .animation(HealthAIAnimations.Presets.spring, value: selectedMetric)
            }
        }
    }
}

// MARK: - watchOS Metric Display
struct WatchMetricDisplay: View {
    let metric: HealthMetric
    @StateObject private var healthManager = HealthDataManager.shared
    
    var body: some View {
        VStack(spacing: watchOSDesignSystem.layout.spacing) {
            // Metric icon and label
            HStack {
                Image(systemName: metric.icon)
                    .font(.title2)
                    .foregroundColor(metric.color)
                
                Text(metric.title)
                    .font(watchOSDesignSystem.typography.headline)
                    .foregroundColor(watchOSDesignSystem.colors.primaryText)
                
                Spacer()
            }
            
            // Metric value
            HStack(alignment: .bottom, spacing: watchOSDesignSystem.layout.smallSpacing) {
                Text(metricValue)
                    .font(watchOSDesignSystem.typography.healthMetric)
                    .fontWeight(.bold)
                    .foregroundColor(watchOSDesignSystem.colors.primaryText)
                
                Text(metric.unit)
                    .font(watchOSDesignSystem.typography.healthUnit)
                    .foregroundColor(watchOSDesignSystem.colors.secondaryText)
            }
            
            // Status indicator
            HStack {
                Circle()
                    .fill(statusColor)
                    .frame(width: 6, height: 6)
                
                Text(statusText)
                    .font(watchOSDesignSystem.typography.caption1)
                    .foregroundColor(statusColor)
                
                Spacer()
            }
        }
        .padding(watchOSDesignSystem.layout.largePadding)
        .background(watchOSDesignSystem.colors.secondaryBackground)
        .cornerRadius(watchOSDesignSystem.layout.cornerRadius)
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
            case 60..<100: return watchOSDesignSystem.colors.activity
            case 100..<120: return watchOSDesignSystem.colors.accent
            default: return watchOSDesignSystem.colors.heartRate
            }
        case .sleep:
            return watchOSDesignSystem.colors.activity
        case .activity:
            return watchOSDesignSystem.colors.activity
        case .bloodPressure:
            return watchOSDesignSystem.colors.activity
        case .temperature:
            return watchOSDesignSystem.colors.activity
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

// MARK: - watchOS Quick Actions
struct WatchQuickActions: View {
    var body: some View {
        HStack(spacing: watchOSDesignSystem.layout.spacing) {
            WatchQuickActionButton(icon: "heart.fill", title: "Record") {
                // Record action
            }
            
            WatchQuickActionButton(icon: "chart.line.uptrend.xyaxis", title: "Trends") {
                // Trends action
            }
            
            WatchQuickActionButton(icon: "gear", title: "Settings") {
                // Settings action
            }
        }
    }
}

struct WatchQuickActionButton: View {
    let icon: String
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: watchOSDesignSystem.layout.smallSpacing) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(watchOSDesignSystem.colors.primary)
                
                Text(title)
                    .font(watchOSDesignSystem.typography.caption2)
                    .foregroundColor(watchOSDesignSystem.colors.secondaryText)
            }
            .frame(maxWidth: .infinity)
            .padding(watchOSDesignSystem.layout.smallPadding)
            .background(watchOSDesignSystem.colors.tertiaryBackground)
            .cornerRadius(watchOSDesignSystem.layout.smallCornerRadius)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - watchOS Detail View
struct WatchDetailView: View {
    let metric: HealthMetric
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: watchOSDesignSystem.layout.largeSpacing) {
            // Header
            HStack {
                Text(metric.title)
                    .font(watchOSDesignSystem.typography.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(watchOSDesignSystem.colors.primaryText)
                
                Spacer()
                
                Button("Done") {
                    dismiss()
                }
                .font(watchOSDesignSystem.typography.body)
                .foregroundColor(watchOSDesignSystem.colors.primary)
            }
            
            // Metric chart (placeholder)
            WatchMetricChart(metric: metric)
            
            // Additional details
            WatchMetricDetails(metric: metric)
        }
        .padding(watchOSDesignSystem.layout.largePadding)
        .background(watchOSDesignSystem.colors.background)
    }
}

// MARK: - watchOS Metric Chart
struct WatchMetricChart: View {
    let metric: HealthMetric
    
    var body: some View {
        VStack(spacing: watchOSDesignSystem.layout.spacing) {
            Text("24 Hour Trend")
                .font(watchOSDesignSystem.typography.headline)
                .foregroundColor(watchOSDesignSystem.colors.primaryText)
            
            // Placeholder chart
            RoundedRectangle(cornerRadius: watchOSDesignSystem.layout.cornerRadius)
                .fill(watchOSDesignSystem.colors.secondaryBackground)
                .frame(height: 80)
                .overlay(
                    VStack {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.title2)
                            .foregroundColor(watchOSDesignSystem.colors.secondaryText)
                        
                        Text("Chart")
                            .font(watchOSDesignSystem.typography.caption1)
                            .foregroundColor(watchOSDesignSystem.colors.secondaryText)
                    }
                )
        }
    }
}

// MARK: - watchOS Metric Details
struct WatchMetricDetails: View {
    let metric: HealthMetric
    
    var body: some View {
        VStack(spacing: watchOSDesignSystem.layout.spacing) {
            HStack {
                Text("Today's Average")
                    .font(watchOSDesignSystem.typography.body)
                    .foregroundColor(watchOSDesignSystem.colors.secondaryText)
                
                Spacer()
                
                Text(averageValue)
                    .font(watchOSDesignSystem.typography.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(watchOSDesignSystem.colors.primaryText)
            }
            
            HStack {
                Text("Goal")
                    .font(watchOSDesignSystem.typography.body)
                    .foregroundColor(watchOSDesignSystem.colors.secondaryText)
                
                Spacer()
                
                Text(goalValue)
                    .font(watchOSDesignSystem.typography.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(watchOSDesignSystem.colors.primaryText)
            }
        }
    }
    
    private var averageValue: String {
        switch metric {
        case .heartRate: return "72 BPM"
        case .sleep: return "7.2 hrs"
        case .activity: return "7,890 steps"
        case .bloodPressure: return "118/78"
        case .temperature: return "98.4°F"
        }
    }
    
    private var goalValue: String {
        switch metric {
        case .heartRate: return "60-100 BPM"
        case .sleep: return "7-9 hrs"
        case .activity: return "10,000 steps"
        case .bloodPressure: return "<120/80"
        case .temperature: return "98.6°F"
        }
    }
}

// MARK: - watchOS Activity Rings
struct WatchActivityRings: View {
    @StateObject private var healthManager = HealthDataManager.shared
    
    var body: some View {
        VStack(spacing: watchOSDesignSystem.layout.spacing) {
            Text("Activity")
                .font(watchOSDesignSystem.typography.headline)
                .foregroundColor(watchOSDesignSystem.colors.primaryText)
            
            ZStack {
                // Move ring (outer)
                Circle()
                    .stroke(watchOSDesignSystem.colors.activity, lineWidth: 8)
                    .frame(width: 80, height: 80)
                
                Circle()
                    .trim(from: 0, to: 0.8)
                    .stroke(watchOSDesignSystem.colors.activity, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(-90))
                    .animation(HealthAIAnimations.Presets.smooth, value: healthManager.movePercentage)
                
                // Exercise ring (middle)
                Circle()
                    .stroke(watchOSDesignSystem.colors.heartRate, lineWidth: 8)
                    .frame(width: 60, height: 60)
                
                Circle()
                    .trim(from: 0, to: 0.6)
                    .stroke(watchOSDesignSystem.colors.heartRate, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 60, height: 60)
                    .rotationEffect(.degrees(-90))
                    .animation(HealthAIAnimations.Presets.smooth, value: healthManager.exercisePercentage)
                
                // Stand ring (inner)
                Circle()
                    .stroke(watchOSDesignSystem.colors.sleep, lineWidth: 8)
                    .frame(width: 40, height: 40)
                
                Circle()
                    .trim(from: 0, to: 0.9)
                    .stroke(watchOSDesignSystem.colors.sleep, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 40, height: 40)
                    .rotationEffect(.degrees(-90))
                    .animation(HealthAIAnimations.Presets.smooth, value: healthManager.standPercentage)
                
                // Center text
                VStack(spacing: 2) {
                    Text("\(Int(healthManager.totalCalories))")
                        .font(watchOSDesignSystem.typography.title3)
                        .fontWeight(.bold)
                        .foregroundColor(watchOSDesignSystem.colors.primaryText)
                    
                    Text("cal")
                        .font(watchOSDesignSystem.typography.caption2)
                        .foregroundColor(watchOSDesignSystem.colors.secondaryText)
                }
            }
        }
    }
}

// MARK: - watchOS Heart Rate Monitor
struct WatchHeartRateMonitor: View {
    @StateObject private var healthManager = HealthDataManager.shared
    @State private var isMonitoring = false
    
    var body: some View {
        VStack(spacing: watchOSDesignSystem.layout.spacing) {
            HStack {
                Text("Heart Rate")
                    .font(watchOSDesignSystem.typography.headline)
                    .foregroundColor(watchOSDesignSystem.colors.primaryText)
                
                Spacer()
                
                Button(isMonitoring ? "Stop" : "Start") {
                    isMonitoring.toggle()
                }
                .font(watchOSDesignSystem.typography.body)
                .foregroundColor(watchOSDesignSystem.colors.primary)
            }
            
            // Heart rate display
            HStack(alignment: .bottom, spacing: watchOSDesignSystem.layout.smallSpacing) {
                Text("\(Int(healthManager.currentHeartRate))")
                    .font(watchOSDesignSystem.typography.healthMetric)
                    .fontWeight(.bold)
                    .foregroundColor(watchOSDesignSystem.colors.primaryText)
                
                Text("BPM")
                    .font(watchOSDesignSystem.typography.healthUnit)
                    .foregroundColor(watchOSDesignSystem.colors.secondaryText)
            }
            
            // Heart rate status
            HStack {
                Circle()
                    .fill(heartRateStatusColor)
                    .frame(width: 6, height: 6)
                
                Text(heartRateStatusText)
                    .font(watchOSDesignSystem.typography.caption1)
                    .foregroundColor(heartRateStatusColor)
                
                Spacer()
            }
            
            // Heart rate graph (simplified)
            if isMonitoring {
                WatchHeartRateGraph()
            }
        }
        .padding(watchOSDesignSystem.layout.largePadding)
        .background(watchOSDesignSystem.colors.secondaryBackground)
        .cornerRadius(watchOSDesignSystem.layout.cornerRadius)
    }
    
    private var heartRateStatusColor: Color {
        let hr = healthManager.currentHeartRate
        switch hr {
        case 60..<100: return watchOSDesignSystem.colors.activity
        case 100..<120: return watchOSDesignSystem.colors.accent
        default: return watchOSDesignSystem.colors.heartRate
        }
    }
    
    private var heartRateStatusText: String {
        let hr = healthManager.currentHeartRate
        switch hr {
        case 60..<100: return "Normal"
        case 100..<120: return "Elevated"
        default: return "High"
        }
    }
}

// MARK: - watchOS Heart Rate Graph
struct WatchHeartRateGraph: View {
    @State private var heartRateData: [Double] = Array(repeating: 72, count: 20)
    
    var body: some View {
        VStack(spacing: watchOSDesignSystem.layout.smallSpacing) {
            Text("Live")
                .font(watchOSDesignSystem.typography.caption1)
                .foregroundColor(watchOSDesignSystem.colors.secondaryText)
            
            // Simple line graph
            GeometryReader { geometry in
                Path { path in
                    let width = geometry.size.width
                    let height = geometry.size.height
                    let stepX = width / CGFloat(heartRateData.count - 1)
                    
                    for (index, value) in heartRateData.enumerated() {
                        let x = CGFloat(index) * stepX
                        let y = height - (CGFloat(value - 60) / 40) * height
                        
                        if index == 0 {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                }
                .stroke(watchOSDesignSystem.colors.heartRate, lineWidth: 2)
            }
            .frame(height: 40)
        }
        .onAppear {
            startHeartRateSimulation()
        }
    }
    
    private func startHeartRateSimulation() {
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            withAnimation(HealthAIAnimations.Presets.smooth) {
                heartRateData.removeFirst()
                heartRateData.append(Double.random(in: 70...75))
            }
        }
    }
}

// MARK: - watchOS Sleep Tracking
struct WatchSleepTracking: View {
    @StateObject private var healthManager = HealthDataManager.shared
    
    var body: some View {
        VStack(spacing: watchOSDesignSystem.layout.spacing) {
            HStack {
                Text("Sleep")
                    .font(watchOSDesignSystem.typography.headline)
                    .foregroundColor(watchOSDesignSystem.colors.primaryText)
                
                Spacer()
                
                Text("Last Night")
                    .font(watchOSDesignSystem.typography.caption1)
                    .foregroundColor(watchOSDesignSystem.colors.secondaryText)
            }
            
            // Sleep duration
            HStack(alignment: .bottom, spacing: watchOSDesignSystem.layout.smallSpacing) {
                Text("7.5")
                    .font(watchOSDesignSystem.typography.healthMetric)
                    .fontWeight(.bold)
                    .foregroundColor(watchOSDesignSystem.colors.primaryText)
                
                Text("hrs")
                    .font(watchOSDesignSystem.typography.healthUnit)
                    .foregroundColor(watchOSDesignSystem.colors.secondaryText)
            }
            
            // Sleep quality
            HStack {
                Text("Quality: Good")
                    .font(watchOSDesignSystem.typography.caption1)
                    .foregroundColor(watchOSDesignSystem.colors.activity)
                
                Spacer()
                
                Text("Goal: 8hrs")
                    .font(watchOSDesignSystem.typography.caption1)
                    .foregroundColor(watchOSDesignSystem.colors.secondaryText)
            }
        }
        .padding(watchOSDesignSystem.layout.largePadding)
        .background(watchOSDesignSystem.colors.secondaryBackground)
        .cornerRadius(watchOSDesignSystem.layout.cornerRadius)
    }
}

// MARK: - Supporting Types
public enum HealthMetric: CaseIterable {
    case heartRate, sleep, activity, bloodPressure, temperature
    
    var title: String {
        switch self {
        case .heartRate: return "Heart Rate"
        case .sleep: return "Sleep"
        case .activity: return "Activity"
        case .bloodPressure: return "Blood Pressure"
        case .temperature: return "Temperature"
        }
    }
    
    var shortName: String {
        switch self {
        case .heartRate: return "HR"
        case .sleep: return "Sleep"
        case .activity: return "Activity"
        case .bloodPressure: return "BP"
        case .temperature: return "Temp"
        }
    }
    
    var icon: String {
        switch self {
        case .heartRate: return "heart.fill"
        case .sleep: return "bed.double.fill"
        case .activity: return "figure.walk"
        case .bloodPressure: return "heart.circle.fill"
        case .temperature: return "thermometer"
        }
    }
    
    var unit: String {
        switch self {
        case .heartRate: return "BPM"
        case .sleep: return "hrs"
        case .activity: return "steps"
        case .bloodPressure: return "mmHg"
        case .temperature: return "°F"
        }
    }
    
    var color: Color {
        switch self {
        case .heartRate: return watchOSDesignSystem.colors.heartRate
        case .sleep: return watchOSDesignSystem.colors.sleep
        case .activity: return watchOSDesignSystem.colors.activity
        case .bloodPressure: return watchOSDesignSystem.colors.bloodPressure
        case .temperature: return watchOSDesignSystem.colors.accent
        }
    }
}

// MARK: - Health Data Manager Extension
extension HealthDataManager {
    var currentHeartRate: Double {
        // Simulated heart rate data
        return 72.0
    }
    
    var movePercentage: Double {
        return 0.8
    }
    
    var exercisePercentage: Double {
        return 0.6
    }
    
    var standPercentage: Double {
        return 0.9
    }
    
    var totalCalories: Double {
        return 450.0
    }
} 
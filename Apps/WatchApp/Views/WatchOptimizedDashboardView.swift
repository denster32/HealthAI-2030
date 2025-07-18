import SwiftUI
import WatchKit

@available(watchOS 10.0, *)
public struct WatchOptimizedDashboardView: View {
    @StateObject private var healthManager = WatchHealthManager.shared
    @State private var selectedTab = 0
    @State private var crownValue: Double = 0
    
    public var body: some View {
        TabView(selection: $selectedTab) {
            // Heart Rate Tab
            WatchHeartRateView()
                .tag(0)
            
            // Activity Tab
            WatchActivityView()
                .tag(1)
            
            // Sleep Tab
            WatchSleepView()
                .tag(2)
            
            // Quick Actions Tab
            WatchQuickActionsView()
                .tag(3)
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
        .focusable()
        .digitalCrownRotation($crownValue, from: 0, through: 100, by: 1.0, sensitivity: .medium)
        .onChange(of: crownValue) { newValue in
            handleCrownRotation(newValue)
        }
        .onAppear {
            healthManager.startMonitoring()
        }
        .onDisappear {
            healthManager.stopMonitoring()
        }
    }
    
    private func handleCrownRotation(_ value: Double) {
        // Handle Digital Crown rotation for quick actions
        let normalizedValue = value / 100.0
        healthManager.updateQuickAction(normalizedValue)
    }
}

// MARK: - Heart Rate View
struct WatchHeartRateView: View {
    @StateObject private var healthManager = WatchHealthManager.shared
    @State private var showingDetail = false
    
    var body: some View {
        VStack(spacing: HealthAIDesignSystem.Spacing.sm) {
            // Heart Rate Display
            VStack(spacing: HealthAIDesignSystem.Spacing.xs) {
                Text("\(Int(healthManager.currentHeartRate))")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(heartRateColor)
                
                Text("BPM")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(HealthAIDesignSystem.Colors.textSecondary)
            }
            
            // Heart Rate Graph
            WatchHeartRateGraph(data: healthManager.heartRateHistory)
                .frame(height: 40)
            
            // Status Indicator
            HStack {
                Circle()
                    .fill(heartRateColor)
                    .frame(width: 6, height: 6)
                
                Text(heartRateStatus)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(HealthAIDesignSystem.Colors.textSecondary)
            }
        }
        .padding()
        .background(HealthAIDesignSystem.Colors.card)
        .cornerRadius(HealthAIDesignSystem.Layout.cornerRadius)
        .onTapGesture {
            showingDetail = true
        }
        .sheet(isPresented: $showingDetail) {
            WatchHeartRateDetailView()
        }
    }
    
    private var heartRateColor: Color {
        let hr = healthManager.currentHeartRate
        switch hr {
        case 0..<60: return HealthAIDesignSystem.Colors.warning
        case 60..<100: return HealthAIDesignSystem.Colors.success
        default: return HealthAIDesignSystem.Colors.error
        }
    }
    
    private var heartRateStatus: String {
        let hr = healthManager.currentHeartRate
        switch hr {
        case 0..<60: return "Low"
        case 60..<100: return "Normal"
        default: return "High"
        }
    }
}

// MARK: - Heart Rate Graph
struct WatchHeartRateGraph: View {
    let data: [Double]
    
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                guard data.count > 1 else { return }
                
                let width = geometry.size.width
                let height = geometry.size.height
                let stepX = width / CGFloat(data.count - 1)
                
                let minValue = data.min() ?? 0
                let maxValue = data.max() ?? 100
                let range = maxValue - minValue
                
                for (index, value) in data.enumerated() {
                    let x = CGFloat(index) * stepX
                    let normalizedValue = range > 0 ? (value - minValue) / range : 0.5
                    let y = height - (CGFloat(normalizedValue) * height)
                    
                    if index == 0 {
                        path.move(to: CGPoint(x: x, y: y))
                    } else {
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
            }
            .stroke(HealthAIDesignSystem.Colors.primary, lineWidth: 2)
        }
    }
}

// MARK: - Activity View
struct WatchActivityView: View {
    @StateObject private var healthManager = WatchHealthManager.shared
    
    var body: some View {
        VStack(spacing: HealthAIDesignSystem.Spacing.sm) {
            // Activity Rings
            WatchActivityRings(
                move: healthManager.moveGoal,
                exercise: healthManager.exerciseGoal,
                stand: healthManager.standGoal
            )
            .frame(width: 80, height: 80)
            
            // Activity Summary
            VStack(spacing: HealthAIDesignSystem.Spacing.xs) {
                Text("\(Int(healthManager.moveGoal * 100))%")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(HealthAIDesignSystem.Colors.primary)
                
                Text("Move Goal")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(HealthAIDesignSystem.Colors.textSecondary)
            }
        }
        .padding()
        .background(HealthAIDesignSystem.Colors.card)
        .cornerRadius(HealthAIDesignSystem.Layout.cornerRadius)
    }
}

// MARK: - Activity Rings
struct WatchActivityRings: View {
    let move: Double
    let exercise: Double
    let stand: Double
    
    var body: some View {
        ZStack {
            // Stand Ring (Outer)
            Circle()
                .stroke(HealthAIDesignSystem.Colors.primary, lineWidth: 4)
                .opacity(0.3)
            
            Circle()
                .trim(from: 0, to: stand)
                .stroke(HealthAIDesignSystem.Colors.primary, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(-90))
            
            // Exercise Ring (Middle)
            Circle()
                .stroke(HealthAIDesignSystem.Colors.activity, lineWidth: 4)
                .opacity(0.3)
                .padding(6)
            
            Circle()
                .trim(from: 0, to: exercise)
                .stroke(HealthAIDesignSystem.Colors.activity, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .padding(6)
            
            // Move Ring (Inner)
            Circle()
                .stroke(HealthAIDesignSystem.Colors.heartRate, lineWidth: 4)
                .opacity(0.3)
                .padding(12)
            
            Circle()
                .trim(from: 0, to: move)
                .stroke(HealthAIDesignSystem.Colors.heartRate, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .padding(12)
        }
    }
}

// MARK: - Sleep View
struct WatchSleepView: View {
    @StateObject private var healthManager = WatchHealthManager.shared
    
    var body: some View {
        VStack(spacing: HealthAIDesignSystem.Spacing.sm) {
            // Sleep Duration
            VStack(spacing: HealthAIDesignSystem.Spacing.xs) {
                Text("\(Int(healthManager.sleepDuration))h")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(HealthAIDesignSystem.Colors.sleep)
                
                Text("Last Night")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(HealthAIDesignSystem.Colors.textSecondary)
            }
            
            // Sleep Quality
            VStack(spacing: HealthAIDesignSystem.Spacing.xs) {
                Text("\(Int(healthManager.sleepQuality * 100))%")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(sleepQualityColor)
                
                Text("Quality")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(HealthAIDesignSystem.Colors.textSecondary)
            }
        }
        .padding()
        .background(HealthAIDesignSystem.Colors.card)
        .cornerRadius(HealthAIDesignSystem.Layout.cornerRadius)
    }
    
    private var sleepQualityColor: Color {
        switch healthManager.sleepQuality {
        case 0.8...: return HealthAIDesignSystem.Colors.success
        case 0.6..<0.8: return HealthAIDesignSystem.Colors.warning
        default: return HealthAIDesignSystem.Colors.error
        }
    }
}

// MARK: - Quick Actions View
struct WatchQuickActionsView: View {
    @StateObject private var healthManager = WatchHealthManager.shared
    
    var body: some View {
        VStack(spacing: HealthAIDesignSystem.Spacing.sm) {
            Text("Quick Actions")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(HealthAIDesignSystem.Colors.textSecondary)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: HealthAIDesignSystem.Spacing.xs) {
                WatchQuickActionButton(
                    icon: "heart.fill",
                    color: HealthAIDesignSystem.Colors.heartRate,
                    action: { healthManager.startHeartRateMeasurement() }
                )
                
                WatchQuickActionButton(
                    icon: "drop.fill",
                    color: HealthAIDesignSystem.Colors.nutrition,
                    action: { healthManager.logWaterIntake() }
                )
                
                WatchQuickActionButton(
                    icon: "figure.run",
                    color: HealthAIDesignSystem.Colors.activity,
                    action: { healthManager.startWorkout() }
                )
                
                WatchQuickActionButton(
                    icon: "bed.double.fill",
                    color: HealthAIDesignSystem.Colors.sleep,
                    action: { healthManager.startSleepTracking() }
                )
            }
        }
        .padding()
        .background(HealthAIDesignSystem.Colors.card)
        .cornerRadius(HealthAIDesignSystem.Layout.cornerRadius)
    }
}

// MARK: - Quick Action Button
struct WatchQuickActionButton: View {
    let icon: String
    let color: Color
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(color)
                .frame(width: 44, height: 44)
                .background(
                    Circle()
                        .fill(color.opacity(isPressed ? 0.3 : 0.1))
                )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.9 : 1.0)
        .animation(HealthAIDesignSystem.Layout.animationSpring, value: isPressed)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}

// MARK: - Heart Rate Detail View
struct WatchHeartRateDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var healthManager = WatchHealthManager.shared
    
    var body: some View {
        VStack(spacing: HealthAIDesignSystem.Spacing.md) {
            Text("Heart Rate")
                .font(.system(size: 16, weight: .bold))
            
            VStack(spacing: HealthAIDesignSystem.Spacing.sm) {
                Text("\(Int(healthManager.currentHeartRate))")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(HealthAIDesignSystem.Colors.heartRate)
                
                Text("BPM")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(HealthAIDesignSystem.Colors.textSecondary)
            }
            
            // Heart Rate Zones
            VStack(spacing: HealthAIDesignSystem.Spacing.xs) {
                WatchHeartRateZoneRow(label: "Resting", value: "58", color: HealthAIDesignSystem.Colors.success)
                WatchHeartRateZoneRow(label: "Active", value: "72", color: HealthAIDesignSystem.Colors.warning)
                WatchHeartRateZoneRow(label: "Peak", value: "85", color: HealthAIDesignSystem.Colors.error)
            }
            
            Button("Close") {
                dismiss()
            }
            .buttonStyle(.bordered)
        }
        .padding()
    }
}

// MARK: - Heart Rate Zone Row
struct WatchHeartRateZoneRow: View {
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(HealthAIDesignSystem.Colors.textPrimary)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(color)
        }
    }
}

// MARK: - Watch Health Manager
class WatchHealthManager: ObservableObject {
    static let shared = WatchHealthManager()
    
    @Published var currentHeartRate: Double = 72.0
    @Published var heartRateHistory: [Double] = Array(repeating: 72.0, count: 20)
    @Published var moveGoal: Double = 0.75
    @Published var exerciseGoal: Double = 0.60
    @Published var standGoal: Double = 0.90
    @Published var sleepDuration: Double = 7.5
    @Published var sleepQuality: Double = 0.85
    
    private var timer: Timer?
    
    private init() {}
    
    func startMonitoring() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.updateHeartRate()
        }
    }
    
    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }
    
    private func updateHeartRate() {
        // Simulate heart rate changes
        let variation = Double.random(in: -5...5)
        currentHeartRate = max(60, min(100, currentHeartRate + variation))
        
        // Update history
        heartRateHistory.removeFirst()
        heartRateHistory.append(currentHeartRate)
    }
    
    func startHeartRateMeasurement() {
        // Start heart rate measurement
        WKInterfaceDevice.current().play(.notification)
    }
    
    func logWaterIntake() {
        // Log water intake
        WKInterfaceDevice.current().play(.success)
    }
    
    func startWorkout() {
        // Start workout
        WKInterfaceDevice.current().play(.start)
    }
    
    func startSleepTracking() {
        // Start sleep tracking
        WKInterfaceDevice.current().play(.success)
    }
    
    func updateQuickAction(_ value: Double) {
        // Handle Digital Crown quick actions
        // This could trigger different actions based on crown rotation
    }
} 
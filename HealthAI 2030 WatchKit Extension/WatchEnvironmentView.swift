import SwiftUI
import WatchKit

struct WatchEnvironmentView: View {
    @StateObject private var environmentMonitor = WatchEnvironmentMonitor()
    @StateObject private var notificationManager = WatchNotificationManager.shared
    @State private var showingSettings = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 12) {
                    // Current Environment Status
                    EnvironmentStatusCard()
                    
                    // Environmental Metrics
                    EnvironmentMetricsGrid()
                    
                    // Sleep Environment Score
                    SleepEnvironmentScore()
                    
                    // Quick Environment Controls
                    EnvironmentControlsCard()
                    
                    // Environmental Alerts
                    EnvironmentAlertsCard()
                }
                .padding(.horizontal, 8)
            }
            .navigationTitle("Environment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Settings") {
                        showingSettings = true
                    }
                    .font(.caption)
                }
            }
        }
        .sheet(isPresented: $showingSettings) {
            EnvironmentSettingsView()
        }
        .onAppear {
            environmentMonitor.startMonitoring()
        }
        .onDisappear {
            environmentMonitor.stopMonitoring()
        }
    }
}

struct EnvironmentStatusCard: View {
    @ObservedObject private var environmentMonitor = WatchEnvironmentMonitor()
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Sleep Environment")
                    .font(.caption)
                    .foregroundColor(.accentColor)
                
                Spacer()
                
                Image(systemName: environmentMonitor.environmentStatus.icon)
                    .font(.caption)
                    .foregroundColor(environmentMonitor.environmentStatus.color)
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Overall Score")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Text("\(Int(environmentMonitor.overallScore * 100))%")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(environmentMonitor.environmentStatus.color)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Status")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Text(environmentMonitor.environmentStatus.description)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(environmentMonitor.environmentStatus.color)
                }
            }
        }
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct EnvironmentMetricsGrid: View {
    @ObservedObject private var environmentMonitor = WatchEnvironmentMonitor()
    
    var body: some View {
        VStack(spacing: 8) {
            Text("Current Conditions")
                .font(.caption)
                .foregroundColor(.accentColor)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                EnvironmentMetricCard(
                    icon: "thermometer",
                    title: "Temperature",
                    value: "\(environmentMonitor.temperature, specifier: "%.1f")°C",
                    status: environmentMonitor.temperatureStatus,
                    optimal: "18-22°C"
                )
                
                EnvironmentMetricCard(
                    icon: "humidity",
                    title: "Humidity",
                    value: "\(Int(environmentMonitor.humidity))%",
                    status: environmentMonitor.humidityStatus,
                    optimal: "40-60%"
                )
                
                EnvironmentMetricCard(
                    icon: "speaker.wave.2",
                    title: "Noise",
                    value: "\(Int(environmentMonitor.noiseLevel)) dB",
                    status: environmentMonitor.noiseStatus,
                    optimal: "<40 dB"
                )
                
                EnvironmentMetricCard(
                    icon: "wind",
                    title: "Air Quality",
                    value: environmentMonitor.airQualityDescription,
                    status: environmentMonitor.airQualityStatus,
                    optimal: "Good"
                )
            }
        }
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct EnvironmentMetricCard: View {
    let icon: String
    let title: String
    let value: String
    let status: EnvironmentStatus
    let optimal: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(status.color)
            
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text("↳ \(optimal)")
                .font(.caption2)
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 80)
        .background(Color(.systemGray5))
        .cornerRadius(8)
    }
}

struct SleepEnvironmentScore: View {
    @ObservedObject private var environmentMonitor = WatchEnvironmentMonitor()
    
    var body: some View {
        VStack(spacing: 8) {
            Text("Sleep Optimization")
                .font(.caption)
                .foregroundColor(.accentColor)
            
            HStack(spacing: 16) {
                // Temperature optimization
                OptimizationIndicator(
                    title: "Temperature",
                    score: environmentMonitor.temperatureOptimization,
                    icon: "thermometer"
                )
                
                // Noise optimization
                OptimizationIndicator(
                    title: "Quietness",
                    score: environmentMonitor.noiseOptimization,
                    icon: "speaker.slash"
                )
                
                // Air quality optimization
                OptimizationIndicator(
                    title: "Air Quality",
                    score: environmentMonitor.airQualityOptimization,
                    icon: "wind"
                )
            }
        }
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct OptimizationIndicator: View {
    let title: String
    let score: Double
    let icon: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundColor(scoreColor)
            
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
            
            Text("\(Int(score * 100))%")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(scoreColor)
        }
        .frame(maxWidth: .infinity)
    }
    
    private var scoreColor: Color {
        if score > 0.8 { return .green }
        if score > 0.6 { return .yellow }
        return .red
    }
}

struct EnvironmentControlsCard: View {
    @ObservedObject private var environmentMonitor = WatchEnvironmentMonitor()
    
    var body: some View {
        VStack(spacing: 8) {
            Text("Quick Controls")
                .font(.caption)
                .foregroundColor(.accentColor)
            
            HStack(spacing: 8) {
                ControlButton(
                    icon: "house.fill",
                    title: "Optimize",
                    color: .blue
                ) {
                    optimizeEnvironment()
                }
                
                ControlButton(
                    icon: "moon.fill",
                    title: "Sleep Mode",
                    color: .indigo
                ) {
                    enableSleepMode()
                }
                
                ControlButton(
                    icon: "arrow.clockwise",
                    title: "Refresh",
                    color: .green
                ) {
                    refreshEnvironment()
                }
            }
        }
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func optimizeEnvironment() {
        // Send optimization request to iPhone
        let message = WatchMessage(
            command: "optimizeEnvironment",
            data: ["timestamp": Date().timeIntervalSince1970],
            source: "watch"
        )
        WatchConnectivityManager.shared.sendMessage(message)
        
        WatchHapticManager.shared.triggerHaptic(type: .reminder)
    }
    
    private func enableSleepMode() {
        // Enable sleep-optimized environment settings
        let message = WatchMessage(
            command: "enableSleepMode",
            data: ["timestamp": Date().timeIntervalSince1970],
            source: "watch"
        )
        WatchConnectivityManager.shared.sendMessage(message)
        
        WatchHapticManager.shared.triggerHaptic(type: .sessionStart)
    }
    
    private func refreshEnvironment() {
        environmentMonitor.refreshData()
        WatchHapticManager.shared.triggerHaptic(type: .reminder)
    }
}

struct ControlButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption2)
                    .foregroundColor(.primary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 45)
            .background(Color(.systemGray5))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct EnvironmentAlertsCard: View {
    @ObservedObject private var notificationManager = WatchNotificationManager.shared
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Environment Alerts")
                    .font(.caption)
                    .foregroundColor(.accentColor)
                
                Spacer()
                
                if !notificationManager.activeNotifications.isEmpty {
                    Text("\(notificationManager.activeNotifications.count)")
                        .font(.caption2)
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.red)
                        .cornerRadius(8)
                }
            }
            
            if notificationManager.activeNotifications.isEmpty {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(.green)
                    
                    Text("All conditions optimal")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
            } else {
                VStack(spacing: 4) {
                    ForEach(notificationManager.activeNotifications.prefix(2)) { notification in
                        EnvironmentAlertRow(notification: notification)
                    }
                    
                    if notificationManager.activeNotifications.count > 2 {
                        Text("+ \(notificationManager.activeNotifications.count - 2) more")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct EnvironmentAlertRow: View {
    let notification: WatchNotification
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: urgencyIcon)
                .font(.caption2)
                .foregroundColor(urgencyColor)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(notification.title)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                Text(notification.message)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
        }
        .padding(.vertical, 2)
    }
    
    private var urgencyIcon: String {
        switch notification.urgency {
        case .low: return "info.circle"
        case .medium: return "exclamationmark.circle"
        case .high: return "exclamationmark.triangle"
        case .critical: return "exclamationmark.triangle.fill"
        }
    }
    
    private var urgencyColor: Color {
        switch notification.urgency {
        case .low: return .blue
        case .medium: return .yellow
        case .high: return .orange
        case .critical: return .red
        }
    }
}

struct EnvironmentSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var environmentMonitor = WatchEnvironmentMonitor()
    
    var body: some View {
        NavigationView {
            List {
                Section("Temperature") {
                    HStack {
                        Text("Optimal Range")
                        Spacer()
                        Text("18-22°C")
                            .foregroundColor(.secondary)
                    }
                    
                    Toggle("Temperature Alerts", isOn: $environmentMonitor.temperatureAlertsEnabled)
                }
                
                Section("Noise") {
                    HStack {
                        Text("Sleep Threshold")
                        Spacer()
                        Text("40 dB")
                            .foregroundColor(.secondary)
                    }
                    
                    Toggle("Noise Alerts", isOn: $environmentMonitor.noiseAlertsEnabled)
                }
                
                Section("Air Quality") {
                    Toggle("Air Quality Alerts", isOn: $environmentMonitor.airQualityAlertsEnabled)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    WatchEnvironmentView()
}
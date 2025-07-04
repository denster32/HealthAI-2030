import SwiftUI
import WatchKit
import HealthKit

struct WatchHealthMonitorView: View {
    @StateObject private var sessionManager = WatchSessionManager.shared
    @StateObject private var connectivityManager = WatchConnectivityManager.shared
    @StateObject private var hapticManager = WatchHapticManager.shared
    
    @State private var isMonitoring = false
    @State private var showingSessionSummary = false
    @State private var sessionStartTime: Date?
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Health Monitoring Tab
            HealthMonitoringTabView()
                .tag(0)
            
            // Sleep Analysis Tab
            WatchSleepAnalysisView()
                .tag(1)
            
            // Environment Tab
            WatchEnvironmentView()
                .tag(2)
            
            // Settings Tab
            WatchSettingsView()
                .tag(3)
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
        .onAppear {
            sessionManager.startHealthMonitoring()
        }
        .onDisappear {
            sessionManager.stopHealthMonitoring()
        }
        .sheet(isPresented: $showingSessionSummary) {
            SessionSummaryView()
        }
    }
}

struct HealthMonitoringTabView: View {
    @StateObject private var sessionManager = WatchSessionManager.shared
    @StateObject private var connectivityManager = WatchConnectivityManager.shared
    @StateObject private var hapticManager = WatchHapticManager.shared
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 12) {
                    // Current Health Status
                    HealthStatusSection()
                    
                    // Sleep Session Controls
                    SleepSessionSection()
                    
                    // Quick Actions
                    QuickActionsSection()
                    
                    // Connection Status
                    ConnectionStatusSection()
                }
                .padding(.horizontal, 8)
            }
            .navigationTitle("HealthAI")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct HealthStatusSection: View {
    @ObservedObject private var sessionManager = WatchSessionManager.shared
    
    var body: some View {
        VStack(spacing: 8) {
            Text("Current Status")
                .font(.headline)
                .foregroundColor(.accentColor)
            
            VStack(spacing: 6) {
                HealthMetricRow(
                    icon: "heart.fill",
                    title: "Heart Rate",
                    value: "\(Int(sessionManager.currentHeartRate))",
                    unit: "BPM",
                    color: heartRateColor
                )
                
                HealthMetricRow(
                    icon: "waveform.path.ecg",
                    title: "HRV",
                    value: "\(Int(sessionManager.currentHRV))",
                    unit: "ms",
                    color: hrvColor
                )
                
                HealthMetricRow(
                    icon: "bed.double.fill",
                    title: "Sleep Stage",
                    value: sessionManager.currentSleepStage.displayName,
                    unit: "",
                    color: sleepStageColor
                )
            }
        }
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var heartRateColor: Color {
        let hr = sessionManager.currentHeartRate
        if hr > 100 { return .red }
        if hr < 60 { return .orange }
        return .green
    }
    
    private var hrvColor: Color {
        let hrv = sessionManager.currentHRV
        if hrv > 50 { return .green }
        if hrv > 30 { return .yellow }
        return .red
    }
    
    private var sleepStageColor: Color {
        switch sessionManager.currentSleepStage {
        case .awake: return .red
        case .lightSleep: return .yellow
        case .deepSleep: return .blue
        case .remSleep: return .purple
        case .unknown: return .gray
        }
    }
}

struct SleepSessionSection: View {
    @ObservedObject private var sessionManager = WatchSessionManager.shared
    
    var body: some View {
        VStack(spacing: 8) {
            Text("Sleep Session")
                .font(.headline)
                .foregroundColor(.accentColor)
            
            if sessionManager.isSleepSessionActive {
                VStack(spacing: 6) {
                    Text("Session Active")
                        .font(.subheadline)
                        .foregroundColor(.green)
                    
                    Text(formatDuration(sessionManager.sessionDuration))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Button("Stop Session") {
                        sessionManager.stopSleepSession()
                        WatchHapticManager.shared.triggerHaptic(type: .sessionEnd)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
            } else {
                VStack(spacing: 6) {
                    Text("Ready to Start")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Button("Start Sleep Session") {
                        sessionManager.startSleepSession()
                        WatchHapticManager.shared.triggerHaptic(type: .sessionStart)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
            }
        }
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        let seconds = Int(duration) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
}

struct QuickActionsSection: View {
    @ObservedObject private var connectivityManager = WatchConnectivityManager.shared
    
    var body: some View {
        VStack(spacing: 8) {
            Text("Quick Actions")
                .font(.headline)
                .foregroundColor(.accentColor)
            
            HStack(spacing: 8) {
                QuickActionButton(
                    icon: "arrow.clockwise",
                    title: "Sync",
                    color: .blue
                ) {
                    syncWithiPhone()
                }
                
                QuickActionButton(
                    icon: "bell.fill",
                    title: "Alert",
                    color: .orange
                ) {
                    sendTestAlert()
                }
                
                QuickActionButton(
                    icon: "heart.text.square",
                    title: "Check",
                    color: .red
                ) {
                    performHealthCheck()
                }
            }
        }
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func syncWithiPhone() {
        let message = WatchMessage(
            command: "syncRequest",
            data: [:],
            source: "watch"
        )
        connectivityManager.sendMessage(message)
        WatchHapticManager.shared.triggerHaptic(type: .sync)
    }
    
    private func sendTestAlert() {
        let message = WatchMessage(
            command: "healthAlert",
            data: [
                "title": "Watch Health Alert",
                "message": "This is a test alert from Apple Watch",
                "severity": "medium"
            ],
            source: "watch"
        )
        connectivityManager.sendMessage(message)
        WatchHapticManager.shared.triggerHaptic(type: .healthAlert)
    }
    
    private func performHealthCheck() {
        WatchSessionManager.shared.performBackgroundHealthCheck {
            WatchHapticManager.shared.triggerHaptic(type: .success)
        }
    }
}

struct ConnectionStatusSection: View {
    @ObservedObject private var connectivityManager = WatchConnectivityManager.shared
    
    var body: some View {
        VStack(spacing: 8) {
            Text("Connection")
                .font(.headline)
                .foregroundColor(.accentColor)
            
            HStack {
                Image(systemName: connectionIcon)
                    .foregroundColor(connectionColor)
                
                Text(connectionText)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if let lastMessage = connectivityManager.lastMessageReceived {
                    Text(RelativeDateTimeFormatter().localizedString(for: lastMessage, relativeTo: Date()))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var connectionIcon: String {
        switch connectivityManager.connectionStatus {
        case .connected: return "iphone.and.arrow.forward"
        case .connecting: return "iphone.slash"
        case .disconnected: return "iphone.slash"
        case .error: return "exclamationmark.triangle"
        }
    }
    
    private var connectionColor: Color {
        switch connectivityManager.connectionStatus {
        case .connected: return .green
        case .connecting: return .yellow
        case .disconnected: return .gray
        case .error: return .red
        }
    }
    
    private var connectionText: String {
        switch connectivityManager.connectionStatus {
        case .connected: return "Connected to iPhone"
        case .connecting: return "Connecting..."
        case .disconnected: return "Disconnected"
        case .error: return "Connection Error"
        }
    }
}

struct HealthMetricRow: View {
    let icon: String
    let title: String
    let value: String
    let unit: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title3)
                .frame(width: 20)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                if !unit.isEmpty {
                    Text(unit)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

struct QuickActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption2)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(Color(.systemGray5))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SessionSummaryView: View {
    @ObservedObject private var sessionManager = WatchSessionManager.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                Text("Session Summary")
                    .font(.headline)
                
                VStack(spacing: 8) {
                    SummaryRow(title: "Duration", value: formatDuration(sessionManager.sessionDuration))
                    SummaryRow(title: "Avg Heart Rate", value: "\(Int(sessionManager.currentHeartRate)) BPM")
                    SummaryRow(title: "Avg HRV", value: "\(Int(sessionManager.currentHRV)) ms")
                    SummaryRow(title: "Sleep Stage", value: sessionManager.currentSleepStage.displayName)
                }
                
                Button("Done") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

struct SummaryRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
        }
    }
}

// MARK: - Extensions

extension SleepStage {
    var displayName: String {
        switch self {
        case .awake: return "Awake"
        case .lightSleep: return "Light"
        case .deepSleep: return "Deep"
        case .remSleep: return "REM"
        case .unknown: return "Unknown"
        }
    }
}

#Preview {
    WatchHealthMonitorView()
}
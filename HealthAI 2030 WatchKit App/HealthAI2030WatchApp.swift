import SwiftUI
import WatchKit

@main
struct HealthAI2030WatchApp: App {
    
    // MARK: - Properties
    @StateObject private var sessionManager = WatchSessionManager.shared
    @StateObject private var connectivityManager = WatchConnectivityManager.shared
    @StateObject private var hapticManager = WatchHapticManager.shared
    
    // App state
    @State private var isAppActive = false
    @State private var currentView: WatchView = .main
    
    // MARK: - App Body
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(sessionManager)
                .environmentObject(connectivityManager)
                .environmentObject(hapticManager)
                .onAppear {
                    setupApp()
                }
                .onReceive(NotificationCenter.default.publisher(for: WKExtension.applicationDidBecomeActiveNotification)) { _ in
                    handleAppDidBecomeActive()
                }
                .onReceive(NotificationCenter.default.publisher(for: WKExtension.applicationWillResignActiveNotification)) { _ in
                    handleAppWillResignActive()
                }
        }
    }
    
    // MARK: - App Setup
    
    private func setupApp() {
        print("HealthAI 2030 Watch App starting...")
        
        // Initialize managers
        sessionManager.startHealthMonitoring()
        
        // Setup background tasks
        setupBackgroundTasks()
        
        // Setup notifications
        setupNotifications()
        
        isAppActive = true
        print("HealthAI 2030 Watch App started successfully")
    }
    
    private func setupBackgroundTasks() {
        // Schedule background health monitoring
        WKExtension.shared().scheduleBackgroundRefresh(
            withPreferredDate: Date().addingTimeInterval(300), // 5 minutes
            userInfo: nil
        ) { error in
            if let error = error {
                print("Failed to schedule background refresh: \(error)")
            } else {
                print("Background refresh scheduled successfully")
            }
        }
    }
    
    private func setupNotifications() {
        // Register for local notifications
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("Notification authorization granted")
            } else {
                print("Notification authorization denied: \(error?.localizedDescription ?? "Unknown error")")
            }
        }
    }
    
    // MARK: - App Lifecycle
    
    private func handleAppDidBecomeActive() {
        print("Watch App became active")
        isAppActive = true
        
        // Resume health monitoring
        sessionManager.startHealthMonitoring()
        
        // Process any queued messages
        connectivityManager.processMessageQueue()
        
        // Update UI
        DispatchQueue.main.async {
            // Trigger UI updates
        }
    }
    
    private func handleAppWillResignActive() {
        print("Watch App will resign active")
        isAppActive = false
        
        // Pause health monitoring to save battery
        sessionManager.stopHealthMonitoring()
        
        // Save any pending data
        saveAppState()
    }
    
    private func saveAppState() {
        // Save current app state to UserDefaults or Core Data
        let appState: [String: Any] = [
            "lastActiveTime": Date().timeIntervalSince1970,
            "currentView": currentView.rawValue,
            "isMonitoring": sessionManager.isMonitoring,
            "isSleepSessionActive": sessionManager.isSleepSessionActive
        ]
        
        UserDefaults.standard.set(appState, forKey: "AppState")
    }
}

// MARK: - Content View

struct ContentView: View {
    @EnvironmentObject var sessionManager: WatchSessionManager
    @EnvironmentObject var connectivityManager: WatchConnectivityManager
    @EnvironmentObject var hapticManager: WatchHapticManager
    
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Main Health Dashboard
            MainHealthView()
                .tabItem {
                    Image(systemName: "heart.fill")
                    Text("Health")
                }
                .tag(0)
            
            // Sleep Session
            SleepSessionView()
                .tabItem {
                    Image(systemName: "bed.double.fill")
                    Text("Sleep")
                }
                .tag(1)
            
            // Quick Actions
            QuickActionsView()
                .tabItem {
                    Image(systemName: "bolt.fill")
                    Text("Actions")
                }
                .tag(2)
            
            // Settings
            SettingsView()
                .tabItem {
                    Image(systemName: "gear")
                    Text("Settings")
                }
                .tag(3)
        }
        .accentColor(.green)
        .onAppear {
            // Initialize app state
            loadAppState()
        }
    }
    
    private func loadAppState() {
        if let appState = UserDefaults.standard.dictionary(forKey: "AppState"),
           let lastActiveTime = appState["lastActiveTime"] as? TimeInterval {
            
            let timeSinceLastActive = Date().timeIntervalSince1970 - lastActiveTime
            
            // If app was inactive for more than 5 minutes, show welcome back
            if timeSinceLastActive > 300 {
                hapticManager.triggerHaptic(type: .reminder)
            }
        }
    }
}

// MARK: - Main Health View

struct MainHealthView: View {
    @EnvironmentObject var sessionManager: WatchSessionManager
    @EnvironmentObject var connectivityManager: WatchConnectivityManager
    
    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                // Connection Status
                ConnectionStatusView()
                
                // Heart Rate
                HealthMetricCard(
                    title: "Heart Rate",
                    value: "\(Int(sessionManager.currentHeartRate))",
                    unit: "BPM",
                    color: heartRateColor,
                    icon: "heart.fill"
                )
                
                // HRV
                HealthMetricCard(
                    title: "HRV",
                    value: String(format: "%.1f", sessionManager.currentHRV),
                    unit: "ms",
                    color: hrvColor,
                    icon: "waveform.path.ecg"
                )
                
                // Sleep Stage
                HealthMetricCard(
                    title: "Sleep Stage",
                    value: sessionManager.currentSleepStage.displayName,
                    unit: "",
                    color: sleepStageColor,
                    icon: "bed.double.fill"
                )
                
                // Battery Level
                BatteryStatusView()
            }
            .padding()
        }
    }
    
    private var heartRateColor: Color {
        let hr = sessionManager.currentHeartRate
        if hr > 100 { return .red }
        else if hr > 80 { return .orange }
        else if hr > 60 { return .green }
        else { return .blue }
    }
    
    private var hrvColor: Color {
        let hrv = sessionManager.currentHRV
        if hrv > 50 { return .green }
        else if hrv > 30 { return .yellow }
        else { return .red }
    }
    
    private var sleepStageColor: Color {
        switch sessionManager.currentSleepStage {
        case .awake: return .blue
        case .lightSleep: return .yellow
        case .deepSleep: return .purple
        case .remSleep: return .green
        case .unknown: return .gray
        }
    }
}

// MARK: - Sleep Session View

struct SleepSessionView: View {
    @EnvironmentObject var sessionManager: WatchSessionManager
    @EnvironmentObject var hapticManager: WatchHapticManager
    
    var body: some View {
        VStack(spacing: 20) {
            // Session Status
            VStack {
                Text(sessionManager.isSleepSessionActive ? "Sleep Session Active" : "Ready for Sleep")
                    .font(.headline)
                    .foregroundColor(sessionManager.isSleepSessionActive ? .green : .primary)
                
                if sessionManager.isSleepSessionActive {
                    Text(formatDuration(sessionManager.sessionDuration))
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
            }
            
            // Start/Stop Button
            Button(action: {
                if sessionManager.isSleepSessionActive {
                    sessionManager.stopSleepSession()
                    hapticManager.triggerHaptic(type: .sessionEnd)
                } else {
                    sessionManager.startSleepSession()
                    hapticManager.triggerHaptic(type: .sessionStart)
                }
            }) {
                Text(sessionManager.isSleepSessionActive ? "Stop Session" : "Start Sleep Session")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(sessionManager.isSleepSessionActive ? Color.red : Color.green)
                    .cornerRadius(10)
            }
            
            // Sleep Tips
            if !sessionManager.isSleepSessionActive {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Sleep Tips:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("• Ensure comfortable environment")
                        .font(.caption2)
                    Text("• Avoid screens before bed")
                        .font(.caption2)
                    Text("• Maintain consistent sleep schedule")
                        .font(.caption2)
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .padding()
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) / 60 % 60
        let seconds = Int(duration) % 60
        
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
}

// MARK: - Supporting Views

struct ConnectionStatusView: View {
    @EnvironmentObject var connectivityManager: WatchConnectivityManager
    
    var body: some View {
        HStack {
            Circle()
                .fill(connectivityManager.connectionStatus == .connected ? Color.green : Color.red)
                .frame(width: 8, height: 8)
            
            Text(connectivityManager.connectionStatus == .connected ? "Connected" : "Disconnected")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct HealthMetricCard: View {
    let title: String
    let value: String
    let unit: String
    let color: Color
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 20)
            
            VStack(alignment: .leading) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack(alignment: .bottom, spacing: 2) {
                    Text(value)
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                    if !unit.isEmpty {
                        Text(unit)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}

struct BatteryStatusView: View {
    @State private var batteryLevel: Float = 0
    
    var body: some View {
        HStack {
            Image(systemName: "battery.100")
                .foregroundColor(batteryColor)
            
            Text("\(Int(batteryLevel * 100))%")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .onAppear {
            batteryLevel = WKInterfaceDevice.current().batteryLevel
        }
    }
    
    private var batteryColor: Color {
        if batteryLevel < 0.2 { return .red }
        else if batteryLevel < 0.5 { return .orange }
        else { return .green }
    }
}

struct QuickActionsView: View {
    @EnvironmentObject var hapticManager: WatchHapticManager
    
    var body: some View {
        VStack(spacing: 15) {
            Text("Quick Actions")
                .font(.headline)
            
            Button("Gentle Wake") {
                hapticManager.triggerHaptic(type: .gentleWake)
            }
            .buttonStyle(.bordered)
            
            Button("Sleep Intervention") {
                hapticManager.triggerHaptic(type: .sleepIntervention)
            }
            .buttonStyle(.bordered)
            
            Button("Health Check") {
                hapticManager.triggerHaptic(type: .reminder)
            }
            .buttonStyle(.bordered)
        }
        .padding()
    }
}

struct SettingsView: View {
    @EnvironmentObject var sessionManager: WatchSessionManager
    @EnvironmentObject var connectivityManager: WatchConnectivityManager
    
    var body: some View {
        VStack(spacing: 15) {
            Text("Settings")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Health Monitoring: \(sessionManager.isMonitoring ? "On" : "Off")")
                    .font(.caption)
                
                Text("Connection: \(connectivityManager.connectionStatus.rawValue)")
                    .font(.caption)
                
                Text("Messages Sent: \(connectivityManager.messageCount)")
                    .font(.caption)
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
        }
        .padding()
    }
}

// MARK: - Supporting Types

enum WatchView: String, CaseIterable {
    case main = "main"
    case sleep = "sleep"
    case actions = "actions"
    case settings = "settings"
}

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

extension ConnectionStatus {
    var rawValue: String {
        switch self {
        case .disconnected: return "Disconnected"
        case .connecting: return "Connecting"
        case .connected: return "Connected"
        case .error: return "Error"
        }
    }
} 
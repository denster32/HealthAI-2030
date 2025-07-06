import SwiftUI
import SwiftData

@available(macOS 15.0, *)
@main
struct HealthAI2030MacOSApp: App {
    
    // MARK: - Properties
    @Environment(\.modelContext) private var modelContext
    
    // SwiftData model container for macOS 15
    @ModelContainer(for: [HealthData.self, SleepSession.self, WorkoutRecord.self, UserProfile.self])
    var container
    
    // App state
    @State private var isAppActive = false
    @State private var selectedTab: MacOSTab = .dashboard
    
    // MARK: - App Body
    
    var body: some Scene {
        WindowGroup {
            MacOSContentView(selectedTab: $selectedTab)
                .modelContainer(container)
                .onAppear {
                    setupApp()
                }
                .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
                    handleAppDidBecomeActive()
                }
                .onReceive(NotificationCenter.default.publisher(for: NSApplication.willResignActiveNotification)) { _ in
                    handleAppWillResignActive()
                }
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        
        // Add menu bar extra for quick access
        MenuBarExtra("Health AI", systemImage: "heart.fill") {
            MacOSMenuBarView()
        }
        .menuBarExtraStyle(.window)
    }
    
    // MARK: - App Setup
    
    private func setupApp() {
        print("HealthAI 2030 macOS App starting...")
        
        // Initialize app state
        loadAppState()
        
        // Setup notifications
        setupNotifications()
        
        // Setup data sync
        setupDataSync()
        
        isAppActive = true
        print("HealthAI 2030 macOS App started successfully")
    }
    
    private func setupNotifications() {
        // Request notification permissions
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("Notification authorization granted")
            } else {
                print("Notification authorization denied: \(error?.localizedDescription ?? "Unknown error")")
            }
        }
    }
    
    private func setupDataSync() {
        // Setup CloudKit sync
        let syncManager = UnifiedCloudKitSyncManager(container: container)
        syncManager.startSync()
    }
    
    // MARK: - App Lifecycle
    
    private func handleAppDidBecomeActive() {
        print("macOS App became active")
        isAppActive = true
        
        // Refresh data
        refreshData()
        
        // Update UI
        DispatchQueue.main.async {
            // Trigger UI updates
        }
    }
    
    private func handleAppWillResignActive() {
        print("macOS App will resign active")
        isAppActive = false
        
        // Save app state
        saveAppState()
    }
    
    private func loadAppState() {
        if let appState = UserDefaults.standard.dictionary(forKey: "MacOSAppState"),
           let lastActiveTime = appState["lastActiveTime"] as? TimeInterval {
            
            let timeSinceLastActive = Date().timeIntervalSince1970 - lastActiveTime
            
            // If app was inactive for more than 1 hour, show welcome back
            if timeSinceLastActive > 3600 {
                // Show welcome back notification
            }
        }
    }
    
    private func saveAppState() {
        let appState: [String: Any] = [
            "lastActiveTime": Date().timeIntervalSince1970,
            "selectedTab": selectedTab.rawValue,
            "isActive": isAppActive
        ]
        
        UserDefaults.standard.set(appState, forKey: "MacOSAppState")
    }
    
    private func refreshData() {
        // Refresh health data from HealthKit
        let healthKitManager = HealthKitManager()
        healthKitManager.requestAuthorization { success, error in
            if success {
                healthKitManager.fetchRecentHealthData { data, fetchError in
                    if let data = data {
                        // Update SwiftData with new health data
                        self.updateHealthData(data)
                    } else if let fetchError = fetchError {
                        print("Error fetching health data: \(fetchError.localizedDescription)")
                    }
                }
            } else if let error = error {
                print("HealthKit authorization failed: \(error.localizedDescription)")
            }
        }
    }
    
    private func updateHealthData(_ data: [HKSample]) {
        let context = container.mainContext
        
        for sample in data {
            if let quantitySample = sample as? HKQuantitySample {
                let healthData = HealthData(context: context)
                healthData.type = quantitySample.quantityType.identifier
                healthData.value = quantitySample.quantity.doubleValue(for: .count())
                healthData.date = quantitySample.startDate
                healthData.source = quantitySample.sourceRevision.source.name
            }
            // Handle other sample types as needed
        }
        
        do {
            try context.save()
            print("Health data updated successfully")
        } catch {
            print("Error saving health data: \(error.localizedDescription)")
        }
    }
}

// MARK: - Main Content View

@available(macOS 15.0, *)
struct MacOSContentView: View {
    @Binding var selectedTab: MacOSTab
    
    var body: some View {
        NavigationSplitView {
            SidebarView(selectedSection: $selectedTab)
        } content: {
            MacOSContentArea(selectedTab: selectedTab)
        } detail: {
            MacOSDetailArea(selectedTab: selectedTab)
        }
        .navigationTitle("Health AI 2030")
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button("Sync") {
                    // TODO: Implement sync trigger through a shared service or notification
                    print("Sync functionality to be implemented")
                }
                
                Button("Settings") {
                    NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
                }
            }
        }
    }
}

// MARK: - Sidebar View

@available(macOS 15.0, *)
struct MacOSSidebarView: View {
    @Binding var selectedTab: MacOSTab
    
    var body: some View {
        List(MacOSTab.allCases, id: \.self) { tab in
            HStack {
                Image(systemName: tab.icon)
                    .foregroundColor(tab.color)
                Text(tab.displayName)
                Spacer()
            }
            .contentShape(Rectangle())
            .onTapGesture {
                selectedTab = tab
            }
            .background(selectedTab == tab ? Color.blue.opacity(0.1) : Color.clear)
        }
        .listStyle(SidebarListStyle())
    }
}

// MARK: - Content Area

@available(macOS 15.0, *)
struct MacOSContentArea: View {
    let selectedTab: MacOSTab
    
    var body: some View {
        switch selectedTab {
        case .dashboard:
            AdvancedAnalyticsDashboard()
        case .health:
            MacOSHealthView()
        case .sleep:
            MacOSSleepView()
        case .activity:
            MacOSActivityView()
        case .nutrition:
            MacOSNutritionView()
        case .mental:
            MacOSMentalHealthView()
        case .settings:
            MacOSSettingsView()
        }
    }
}

// MARK: - Detail Area

@available(macOS 15.0, *)
struct MacOSDetailArea: View {
    let selectedTab: MacOSTab
    
    var body: some View {
        VStack {
            Text("Detail View")
                .font(.title)
            
            Text("Selected: \(selectedTab.displayName)")
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .padding()
    }
}

// MARK: - Tab Views

@available(macOS 15.0, *)
struct MacOSHealthView: View {
    var body: some View {
        VStack {
            Text("Health Overview")
                .font(.title)
            
            Text("Comprehensive health monitoring and analysis")
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .padding()
    }
}

@available(macOS 15.0, *)
struct MacOSSleepView: View {
    var body: some View {
        VStack {
            Text("Sleep Analysis")
                .font(.title)
            
            Text("Detailed sleep tracking and optimization")
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .padding()
    }
}

@available(macOS 15.0, *)
struct MacOSActivityView: View {
    var body: some View {
        VStack {
            Text("Activity Tracking")
                .font(.title)
            
            Text("Workout and fitness monitoring")
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .padding()
    }
}

@available(macOS 15.0, *)
struct MacOSNutritionView: View {
    var body: some View {
        VStack {
            Text("Nutrition & Diet")
                .font(.title)
            
            Text("Nutritional tracking and recommendations")
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .padding()
    }
}

@available(macOS 15.0, *)
struct MacOSMentalHealthView: View {
    var body: some View {
        VStack {
            Text("Mental Health")
                .font(.title)
            
            Text("Stress, mood, and mental wellness tracking")
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .padding()
    }
}

@available(macOS 15.0, *)
struct MacOSSettingsView: View {
    var body: some View {
        VStack {
            Text("Settings")
                .font(.title)
            
            Text("App configuration and preferences")
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .padding()
    }
}

// MARK: - Menu Bar View

@available(macOS 15.0, *)
struct MacOSMenuBarView: View {
    var body: some View {
        VStack(spacing: 8) {
            Button("Open Health AI") {
                NSApp.activate(ignoringOtherApps: true)
            }
            
            Divider()
            
            Button("Quick Health Check") {
                // TODO: Perform quick health check
            }
            
            Button("Sleep Session") {
                // TODO: Start/stop sleep session
            }
            
            Divider()
            
            Button("Settings") {
                // TODO: Open settings
            }
            
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
        }
        .padding()
    }
}

// MARK: - Supporting Types

enum MacOSTab: CaseIterable {
    case dashboard, health, sleep, activity, nutrition, mental, settings
    
    var displayName: String {
        switch self {
        case .dashboard: return "Dashboard"
        case .health: return "Health"
        case .sleep: return "Sleep"
        case .activity: return "Activity"
        case .nutrition: return "Nutrition"
        case .mental: return "Mental Health"
        case .settings: return "Settings"
        }
    }
    
    var icon: String {
        switch self {
        case .dashboard: return "chart.bar.fill"
        case .health: return "heart.fill"
        case .sleep: return "bed.double.fill"
        case .activity: return "figure.run"
        case .nutrition: return "fork.knife"
        case .mental: return "brain.head.profile"
        case .settings: return "gear"
        }
    }
    
    var color: Color {
        switch self {
        case .dashboard: return .blue
        case .health: return .red
        case .sleep: return .purple
        case .activity: return .green
        case .nutrition: return .brown
        case .mental: return .orange
        case .settings: return .gray
        }
    }
} 
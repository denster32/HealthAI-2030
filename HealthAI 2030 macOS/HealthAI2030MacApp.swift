import SwiftUI
import CoreML
import Metal
import MetalPerformanceShaders
import ResearchKit
import AVFoundation

@main
struct HealthAI2030MacApp: App {
    
    // MARK: - Properties
    @StateObject private var healthDataManager = HealthDataManager.shared
    @StateObject private var sleepOptimizationManager = SleepOptimizationManager.shared
    @StateObject private var predictiveAnalyticsManager = PredictiveAnalyticsManager.shared
    @StateObject private var environmentManager = EnvironmentManager.shared
    @StateObject private var appleWatchManager = AppleWatchManager.shared
    @StateObject private var macAnalyticsEngine = MacAnalyticsEngine.shared
    @StateObject private var researchKitManager = ResearchKitManager.shared
    @StateObject private var dataExportManager = DataExportManager.shared
    
    // App state
    @State private var isAppActive = false
    @State private var showingOnboarding = false
    @State private var currentWindow: MacWindow = .dashboard
    
    // Integrate premium content and features
    let appIntegration = AppIntegration()
    
    // MARK: - App Body
    
    var body: some Scene {
        WindowGroup {
            MacContentView()
                .environmentObject(healthDataManager)
                .environmentObject(sleepOptimizationManager)
                .environmentObject(predictiveAnalyticsManager)
                .environmentObject(environmentManager)
                .environmentObject(appleWatchManager)
                .environmentObject(macAnalyticsEngine)
                .environmentObject(researchKitManager)
                .environmentObject(dataExportManager)
                .onAppear {
                    setupApp()
                    HealthDataAnalyzer.shared.analyzeAllHealthData(preferMac: true)
                }
                .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
                    handleAppDidBecomeActive()
                }
                .onReceive(NotificationCenter.default.publisher(for: NSApplication.willResignActiveNotification)) { _ in
                    handleAppWillResignActive()
                }
                .sheet(isPresented: $showingOnboarding) {
                    OnboardingView()
                }
        }
        .windowStyle(HiddenTitleBarWindowStyle())
        .windowResizability(.contentSize)
        
        // Settings window
        Settings {
            SettingsView()
        }
        
        // Analytics window
        WindowGroup("Analytics", id: "analytics") {
            AnalyticsWindowView()
        }
        .windowStyle(HiddenTitleBarWindowStyle())
        .windowResizability(.contentSize)
        
        // Research window
        WindowGroup("Research", id: "research") {
            ResearchWindowView()
        }
        .windowStyle(HiddenTitleBarWindowStyle())
        .windowResizability(.contentSize)
        
        // Data Export window
        WindowGroup("Data Export", id: "export") {
            DataExportWindowView()
        }
        .windowStyle(HiddenTitleBarWindowStyle())
        .windowResizability(.contentSize)
    }
    
    // MARK: - App Setup
    
    private func setupApp() {
        print("HealthAI 2030 macOS App starting...")
        
        // Initialize managers
        healthDataManager.initializeHealthKit()
        sleepOptimizationManager.initializeSleepOptimization()
        predictiveAnalyticsManager.initializePredictiveAnalytics()
        environmentManager.initializeHomeKit()
        
        // Initialize macOS-specific components
        macAnalyticsEngine.initialize()
        researchKitManager.initialize()
        dataExportManager.initialize()
        
        // Setup Apple Silicon NPU optimization
        setupNPUOptimization()
        
        // Setup background processing
        setupBackgroundProcessing()
        
        // Check if first launch
        checkFirstLaunch()
        
        isAppActive = true
        print("HealthAI 2030 macOS App started successfully")
    }
    
    private func setupNPUOptimization() {
        // Configure Apple Silicon NPU for heavy computations
        guard let device = MTLCreateSystemDefaultDevice() else {
            print("Metal device not available")
            return
        }
        
        // Check for Neural Engine availability
        if device.supportsFeatureSet(.iOS_GPUFamily4_v1) {
            print("Apple Silicon NPU detected - enabling advanced analytics")
            macAnalyticsEngine.enableNPUOptimization(device: device)
        } else {
            print("Using CPU fallback for analytics")
        }
    }
    
    private func setupBackgroundProcessing() {
        // Schedule overnight heavy computations via MacBackgroundAnalyticsProcessor
        let backgroundTask = BackgroundTaskScheduler.shared
        backgroundTask.scheduleOvernightAnalytics {
            MacBackgroundAnalyticsProcessor.shared.processNextJob()
        }
    }
    
    private func checkFirstLaunch() {
        let hasLaunchedBefore = UserDefaults.standard.bool(forKey: "MacAppHasLaunchedBefore")
        if !hasLaunchedBefore {
            showingOnboarding = true
            UserDefaults.standard.set(true, forKey: "MacAppHasLaunchedBefore")
        }
    }
    
    // MARK: - App Lifecycle
    
    private func handleAppDidBecomeActive() {
        print("macOS App became active")
        isAppActive = true
        
        // Resume data updates
        healthDataManager.startHealthMonitoring()
        sleepOptimizationManager.startSleepOptimization()
        predictiveAnalyticsManager.startPredictiveAnalytics()
        
        // Sync with iCloud
        syncWithiCloud()
        
        // Update UI
        DispatchQueue.main.async {
            // Trigger UI updates
        }
    }
    
    private func handleAppWillResignActive() {
        print("macOS App will resign active")
        isAppActive = false
        
        // Pause data updates to save resources
        healthDataManager.stopHealthMonitoring()
        sleepOptimizationManager.stopSleepOptimization()
        predictiveAnalyticsManager.stopPredictiveAnalytics()
        
        // Save app state
        saveAppState()
        
        // Sync with iCloud
        syncWithiCloud()
    }
    
    private func saveAppState() {
        let appState: [String: Any] = [
            "lastActiveTime": Date().timeIntervalSince1970,
            "currentWindow": currentWindow.rawValue,
            "isMonitoring": healthDataManager.isMonitoring,
            "analyticsEngineStatus": macAnalyticsEngine.status.rawValue
        ]
        
        UserDefaults.standard.set(appState, forKey: "MacAppState")
    }
    
    private func syncWithiCloud() {
        // Sync data with iCloud for cross-device access
        macAnalyticsEngine.syncWithiCloud()
        healthDataManager.syncWithiCloud()
    }
}

// MARK: - Content View

struct ContentView: View {
    @EnvironmentObject var healthDataManager: HealthDataManager
    @EnvironmentObject var sleepOptimizationManager: SleepOptimizationManager
    @EnvironmentObject var predictiveAnalyticsManager: PredictiveAnalyticsManager
    @EnvironmentObject var environmentManager: EnvironmentManager
    @EnvironmentObject var appleWatchManager: AppleWatchManager
    @EnvironmentObject var macAnalyticsEngine: MacAnalyticsEngine
    @EnvironmentObject var researchKitManager: ResearchKitManager
    @EnvironmentObject var dataExportManager: DataExportManager
    
    @State private var selectedTab = 0
    @State private var showingSettings = false
    
    var body: some View {
        NavigationView {
            SidebarView(selectedTab: $selectedTab)
            
            TabView(selection: $selectedTab) {
                // Health Dashboard
                HealthDashboardView()
                    .tabItem {
                        Image(systemName: "heart.fill")
                        Text("Health")
                    }
                    .tag(0)
                
                // Sleep Optimization
                SleepOptimizationView()
                    .tabItem {
                        Image(systemName: "bed.double.fill")
                        Text("Sleep")
                    }
                    .tag(1)
                
                // Advanced Analytics
                AdvancedAnalyticsView()
                    .tabItem {
                        Image(systemName: "chart.bar.xaxis")
                        Text("Analytics")
                    }
                    .tag(2)
                
                // Research Tools
                ResearchToolsView()
                    .tabItem {
                        Image(systemName: "magnifyingglass")
                        Text("Research")
                    }
                    .tag(3)
                
                // Data Export
                DataExportView()
                    .tabItem {
                        Image(systemName: "square.and.arrow.up")
                        Text("Export")
                    }
                    .tag(4)
                
                // Environment
                EnvironmentView()
                    .tabItem {
                        Image(systemName: "house.fill")
                        Text("Environment")
                    }
                    .tag(5)
                
                // Watch Integration
                WatchIntegrationView()
                    .tabItem {
                        Image(systemName: "applewatch")
                        Text("Watch")
                    }
                    .tag(6)
            }
            .accentColor(.green)
            .navigationTitle("HealthAI 2030")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingSettings = true
                    }) {
                        Image(systemName: "gear")
                            .font(.title2)
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        macAnalyticsEngine.performOvernightAnalysis()
                    }) {
                        Image(systemName: "cpu")
                            .font(.title2)
                    }
                    .help("Run Overnight Analysis")
                }
            }
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .onAppear {
            loadAppState()
        }
    }
    
    private func loadAppState() {
        if let appState = UserDefaults.standard.dictionary(forKey: "MacAppState"),
           let lastActiveTime = appState["lastActiveTime"] as? TimeInterval {
            
            let timeSinceLastActive = Date().timeIntervalSince1970 - lastActiveTime
            
            // If app was inactive for more than 10 minutes, show welcome back
            if timeSinceLastActive > 600 {
                // Show welcome back message
            }
        }
    }
}

// MARK: - Sidebar View

struct SidebarView: View {
    @Binding var selectedTab: Int
    @EnvironmentObject var macAnalyticsEngine: MacAnalyticsEngine
    
    var body: some View {
        List {
            Section("Health") {
                NavigationLink(destination: HealthDashboardView(), tag: 0, selection: $selectedTab) {
                    Label("Dashboard", systemImage: "heart.fill")
                }
                
                NavigationLink(destination: SleepOptimizationView(), tag: 1, selection: $selectedTab) {
                    Label("Sleep", systemImage: "bed.double.fill")
                }
            }
            
            Section("Analytics") {
                NavigationLink(destination: AdvancedAnalyticsView(), tag: 2, selection: $selectedTab) {
                    Label("Advanced Analytics", systemImage: "chart.bar.xaxis")
                }
                
                NavigationLink(destination: ResearchToolsView(), tag: 3, selection: $selectedTab) {
                    Label("Research Tools", systemImage: "magnifyingglass")
                }
                
                NavigationLink(destination: DataExportView(), tag: 4, selection: $selectedTab) {
                    Label("Data Export", systemImage: "square.and.arrow.up")
                }
            }
            
            Section("Integration") {
                NavigationLink(destination: EnvironmentView(), tag: 5, selection: $selectedTab) {
                    Label("Environment", systemImage: "house.fill")
                }
                
                NavigationLink(destination: WatchIntegrationView(), tag: 6, selection: $selectedTab) {
                    Label("Apple Watch", systemImage: "applewatch")
                }
            }
            
            Section("System") {
                HStack {
                    Label("Analytics Engine", systemImage: "cpu")
                    Spacer()
                    Circle()
                        .fill(macAnalyticsEngine.status.color)
                        .frame(width: 8, height: 8)
                }
                
                Text("NPU: \(macAnalyticsEngine.npuStatus)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .listStyle(SidebarListStyle())
        .frame(minWidth: 200)
    }
}

// MARK: - Advanced Analytics View

struct AdvancedAnalyticsView: View {
    @EnvironmentObject var macAnalyticsEngine: MacAnalyticsEngine
    @EnvironmentObject var predictiveAnalyticsManager: PredictiveAnalyticsManager
    
    @State private var selectedTimeRange: TimeRange = .month
    @State private var showingAdvancedCharts = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                // Header with controls
                AnalyticsHeaderView()
                
                // Performance metrics
                PerformanceMetricsSection()
                
                // Advanced charts
                AdvancedChartsSection()
                
                // Predictive models
                PredictiveModelsSection()
                
                // Machine learning insights
                MLInsightsSection()
            }
            .padding(.horizontal, 40)
            .padding(.vertical, 20)
        }
        .background(Color(NSColor.controlBackgroundColor))
        .sheet(isPresented: $showingAdvancedCharts) {
            AdvancedChartsView()
        }
    }
}

// MARK: - Research Tools View

struct ResearchToolsView: View {
    @EnvironmentObject var researchKitManager: ResearchKitManager
    
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                // Header
                ResearchHeaderView()
                
                // Research studies
                ResearchStudiesSection()
                
                // Data collection tools
                DataCollectionToolsSection()
                
                // Analysis tools
                AnalysisToolsSection()
                
                // Export options
                ResearchExportSection()
            }
            .padding(.horizontal, 40)
            .padding(.vertical, 20)
        }
        .background(Color(NSColor.controlBackgroundColor))
    }
}

// MARK: - Data Export View

struct DataExportView: View {
    @EnvironmentObject var dataExportManager: DataExportManager
    
    @State private var selectedExportFormat: ExportFormat = .csv
    @State private var selectedTimeRange: TimeRange = .month
    @State private var isExporting = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                // Header
                ExportHeaderView()
                
                // Export options
                ExportOptionsSection()
                
                // Data preview
                DataPreviewSection()
                
                // Export controls
                ExportControlsSection()
            }
            .padding(.horizontal, 40)
            .padding(.vertical, 20)
        }
        .background(Color(NSColor.controlBackgroundColor))
    }
}

// MARK: - Supporting Types

enum MacWindow: String, CaseIterable {
    case dashboard = "dashboard"
    case analytics = "analytics"
    case research = "research"
    case export = "export"
    case settings = "settings"
}

enum ExportFormat: String, CaseIterable {
    case csv = "CSV"
    case sql = "SQL"
    case json = "JSON"
    case xml = "XML"
    case pdf = "PDF"
    
    var fileExtension: String {
        return self.rawValue.lowercased()
    }
}

// MARK: - Placeholder Views

struct AnalyticsWindowView: View {
    var body: some View {
        VStack {
            Text("Analytics Window")
                .font(.title)
                .fontWeight(.bold)
            Text("Implementation coming soon...")
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

struct ResearchWindowView: View {
    var body: some View {
        VStack {
            Text("Research Window")
                .font(.title)
                .fontWeight(.bold)
            Text("Implementation coming soon...")
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

struct DataExportWindowView: View {
    var body: some View {
        VStack {
            Text("Data Export Window")
                .font(.title)
                .fontWeight(.bold)
            Text("Implementation coming soon...")
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

struct SettingsView: View {
    var body: some View {
        VStack {
            Text("Settings")
                .font(.title)
                .fontWeight(.bold)
            Text("Implementation coming soon...")
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

struct OnboardingView: View {
    var body: some View {
        VStack {
            Text("Welcome to HealthAI 2030")
                .font(.title)
                .fontWeight(.bold)
            Text("Implementation coming soon...")
                .foregroundColor(.secondary)
        }
        .padding()
    }
}
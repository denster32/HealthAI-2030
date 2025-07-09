import SwiftUI
import Charts
import HealthKit
import CoreLocation
import CoreData
import OSLog
import UserNotifications
import AVKit
import AVFoundation
import WidgetKit
import StoreKit
import CoreSpotlight
import UniformTypeIdentifiers
import BackgroundTasks
import CoreImage.CIFilterBuiltins
import PhotosUI
import CoreML
import Accelerate

@main
@available(iOS 18.0, macOS 15.0, *)
struct HealthAI_2030App_PerformanceOptimized: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @Environment(\.scenePhase) private var scenePhase

    // MARK: - Performance Optimized Manager Container
    @StateObject private var managerContainer = PerformanceOptimizedManagerContainer()
    
    // MARK: - Performance Monitor
    @StateObject private var performanceMonitor = PerformanceMonitor.shared

    var body: some Scene {
        WindowGroup {
            AdaptiveRootView_PerformanceOptimized()
                .environmentObject(managerContainer)
                .environmentObject(performanceMonitor)
                .onAppear {
                    Task {
                        await initializeApp()
                    }
                }
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            handleScenePhaseChange(from: oldPhase, to: newPhase)
        }
    }
    
    // MARK: - Optimized App Initialization
    
    private func initializeApp() async {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        Logger.appLifecycle.info("Starting performance-optimized app initialization...")
        
        // Step 1: Initialize essential services (critical for app functionality)
        await managerContainer.initializeEssentialServices()
        
        // Step 2: Initialize optional services after UI is ready
        await managerContainer.initializeOptionalServices()
        
        // Step 3: Initialize lazy services on demand
        await managerContainer.initializeLazyServices()
        
        let totalTime = CFAbsoluteTimeGetCurrent() - startTime
        Logger.appLifecycle.info("Performance-optimized app initialization completed in \(String(format: "%.2f", totalTime))s")
        
        // Log performance metrics
        performanceMonitor.recordLaunchTime(totalTime)
        performanceMonitor.recordMemoryUsage()
    }
    
    // MARK: - Scene Phase Handling
    
    private func handleScenePhaseChange(from oldPhase: ScenePhase, to newPhase: ScenePhase) {
        switch newPhase {
        case .active:
            Logger.appLifecycle.info("App became active")
            handleAppActivation()
        case .background:
            Logger.appLifecycle.info("App moved to background")
            handleAppBackground()
        case .inactive:
            Logger.appLifecycle.info("App became inactive")
            handleAppInactive()
        @unknown default:
            Logger.appLifecycle.warning("Unknown scene phase: \(newPhase)")
        }
    }
    
    private func handleAppActivation() {
        Task {
            // Resume essential services
            await managerContainer.healthDataManager?.requestAuthorization()
            await managerContainer.healthDataManager?.loadInitialData()
            
            // Resume location monitoring
            managerContainer.locationManager?.startMonitoringLocation()
            
            // Resume smart home connection
            managerContainer.smartHomeManager?.connect()
            
            // Record performance metrics
            performanceMonitor.recordAppActivation()
        }
    }
    
    private func handleAppBackground() {
        // Schedule background tasks
        BGTaskScheduler.shared.submit(BGAppRefreshTaskRequest(identifier: "com.healthai2030.apprefresh"))
        
        // Pause non-essential services
        managerContainer.smartHomeManager?.disconnect()
        
        // Record performance metrics
        performanceMonitor.recordAppBackground()
    }
    
    private func handleAppInactive() {
        // Save any pending data
        Task {
            await managerContainer.swiftDataManager?.save()
        }
        
        // Record performance metrics
        performanceMonitor.recordAppInactive()
    }
}

// MARK: - Performance Optimized Root View

struct AdaptiveRootView_PerformanceOptimized: View {
    @EnvironmentObject var managerContainer: PerformanceOptimizedManagerContainer
    @EnvironmentObject var performanceMonitor: PerformanceMonitor
    
    var body: some View {
        NavigationView {
            VStack {
                // Performance Status Indicator
                PerformanceStatusView()
                
                // Main Content
                HealthDashboardView_PerformanceOptimized()
                    .environmentObject(managerContainer)
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

// MARK: - Performance Status View

struct PerformanceStatusView: View {
    @EnvironmentObject var performanceMonitor: PerformanceMonitor
    
    var body: some View {
        HStack {
            Image(systemName: "speedometer")
                .foregroundColor(.green)
            
            Text("Performance Optimized")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text("\(String(format: "%.1f", performanceMonitor.currentMemoryUsage))MB")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal)
        .padding(.vertical, 4)
        .background(Color(.systemGray6))
        .cornerRadius(8)
        .padding(.horizontal)
    }
}

// MARK: - Performance Optimized Health Dashboard View

struct HealthDashboardView_PerformanceOptimized: View {
    @EnvironmentObject var managerContainer: PerformanceOptimizedManagerContainer
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Essential Health Data (Always Available)
            EssentialHealthView()
                .tabItem {
                    Image(systemName: "heart.fill")
                    Text("Health")
                }
                .tag(0)
            
            // Optional Features (Loaded on Demand)
            OptionalFeaturesView()
                .tabItem {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                    Text("Analytics")
                }
                .tag(1)
            
            // Settings (Always Available)
            SettingsView()
                .tabItem {
                    Image(systemName: "gear")
                    Text("Settings")
                }
                .tag(2)
        }
        .onChange(of: selectedTab) { oldValue, newValue in
            handleTabChange(from: oldValue, to: newValue)
        }
    }
    
    private func handleTabChange(from oldTab: Int, to newTab: Int) {
        switch newTab {
        case 1: // Analytics Tab
            Task {
                await managerContainer.loadEnhancedAudioExperienceManager()
                await managerContainer.loadFamilyGroupManager()
                await managerContainer.loadSpotlightManager()
            }
        default:
            break
        }
    }
}

// MARK: - Essential Health View

struct EssentialHealthView: View {
    @EnvironmentObject var managerContainer: PerformanceOptimizedManagerContainer
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Health Data Summary
                if let healthDataManager = managerContainer.healthDataManager {
                    HealthDataSummaryView(healthDataManager: healthDataManager)
                }
                
                // Emergency Alerts
                if let emergencyAlertManager = managerContainer.emergencyAlertManager {
                    EmergencyAlertsView(emergencyAlertManager: emergencyAlertManager)
                }
                
                // Location Status
                if let locationManager = managerContainer.locationManager {
                    LocationStatusView(locationManager: locationManager)
                }
            }
            .padding()
        }
    }
}

// MARK: - Optional Features View

struct OptionalFeaturesView: View {
    @EnvironmentObject var managerContainer: PerformanceOptimizedManagerContainer
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Predictive Analytics
                if let predictiveAnalyticsManager = managerContainer.predictiveAnalyticsManager {
                    PredictiveAnalyticsView(predictiveAnalyticsManager: predictiveAnalyticsManager)
                } else {
                    LoadingView(message: "Loading Analytics...")
                }
                
                // Sleep Optimization
                if let sleepOptimizationManager = managerContainer.sleepOptimizationManager {
                    SleepOptimizationView(sleepOptimizationManager: sleepOptimizationManager)
                } else {
                    LoadingView(message: "Loading Sleep Data...")
                }
                
                // Smart Home
                if let smartHomeManager = managerContainer.smartHomeManager {
                    SmartHomeView(smartHomeManager: smartHomeManager)
                } else {
                    LoadingView(message: "Loading Smart Home...")
                }
            }
            .padding()
        }
    }
}

// MARK: - Settings View

struct SettingsView: View {
    @EnvironmentObject var managerContainer: PerformanceOptimizedManagerContainer
    
    var body: some View {
        List {
            Section("Performance") {
                HStack {
                    Text("Loaded Managers")
                    Spacer()
                    Text("\(managerContainer.getLoadedManagersCount())")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Memory Usage")
                    Spacer()
                    Text("\(String(format: "%.1f", ProcessInfo.processInfo.physicalMemory / 1024 / 1024))MB")
                        .foregroundColor(.secondary)
                }
            }
            
            Section("Services") {
                ForEach(managerContainer.getLoadedManagersList(), id: \.self) { manager in
                    HStack {
                        Text(manager)
                        Spacer()
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    }
                }
            }
        }
        .navigationTitle("Settings")
    }
}

// MARK: - Loading View

struct LoadingView: View {
    let message: String
    
    var body: some View {
        VStack {
            ProgressView()
                .scaleEffect(1.2)
            
            Text(message)
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

// MARK: - Placeholder Views (to be implemented)

struct HealthDataSummaryView: View {
    let healthDataManager: HealthDataManager
    
    var body: some View {
        VStack {
            Text("Health Data Summary")
                .font(.headline)
            Text("Essential health data loaded")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct EmergencyAlertsView: View {
    let emergencyAlertManager: EmergencyAlertManager
    
    var body: some View {
        VStack {
            Text("Emergency Alerts")
                .font(.headline)
            Text("Emergency system active")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct LocationStatusView: View {
    let locationManager: LocationManager
    
    var body: some View {
        VStack {
            Text("Location Services")
                .font(.headline)
            Text("Location monitoring active")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct PredictiveAnalyticsView: View {
    let predictiveAnalyticsManager: PredictiveAnalyticsManager
    
    var body: some View {
        VStack {
            Text("Predictive Analytics")
                .font(.headline)
            Text("Analytics data loaded")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct SleepOptimizationView: View {
    let sleepOptimizationManager: SleepOptimizationManager
    
    var body: some View {
        VStack {
            Text("Sleep Optimization")
                .font(.headline)
            Text("Sleep data loaded")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct SmartHomeView: View {
    let smartHomeManager: SmartHomeManager
    
    var body: some View {
        VStack {
            Text("Smart Home")
                .font(.headline)
            Text("Smart home connected")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Logger Extension

extension Logger {
    static let appLifecycle = Logger(subsystem: "HealthAI2030", category: "AppLifecycle")
} 
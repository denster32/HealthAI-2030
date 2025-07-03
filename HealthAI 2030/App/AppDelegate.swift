#if os(iOS)
import UIKit
#endif
import HealthKit
import CoreData
import BackgroundTasks
import WidgetKit // Import WidgetKit

#if canImport(WatchConnectivity)
import WatchConnectivity
#endif

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    var sharedUserDefaults: UserDefaults? // Add shared user defaults for app group
    var healthStore: HKHealthStore?
    var session: WCSession?
    var backgroundTaskScheduler: BackgroundTaskScheduler?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // Initialize HealthKit
        setupHealthKit()
        
        // Initialize Watch Connectivity
        setupWatchConnectivity()
        
        // Setup background tasks
        setupBackgroundTasks()
        
        // Initialize core managers
        initializeManagers()
        
        // Setup notifications
        setupNotifications()
        
        // Setup widgets
        setupWidgets()
        
        return true
    }
    
    private func setupHealthKit() {
        healthStore = HKHealthStore()
        
        guard let healthStore = healthStore else { return }
        
        // Request authorization for required data types
        var typesToRead: Set<HKObjectType> = []
        
        // Safely add HealthKit types
        if let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate) {
            typesToRead.insert(heartRateType)
        }
        if let hrvType = HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN) {
            typesToRead.insert(hrvType)
        }
        if let oxygenType = HKObjectType.quantityType(forIdentifier: .oxygenSaturation) {
            typesToRead.insert(oxygenType)
        }
        if let temperatureType = HKObjectType.quantityType(forIdentifier: .bodyTemperature) {
            typesToRead.insert(temperatureType)
        }
        if let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) {
            typesToRead.insert(sleepType)
        }
        if let stepType = HKObjectType.quantityType(forIdentifier: .stepCount) {
            typesToRead.insert(stepType)
        }
        if let energyType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) {
            typesToRead.insert(energyType)
        }
        
        healthStore.requestAuthorization(toShare: nil, read: typesToRead) { success, error in
            if let error = error {
                print("HealthKit authorization error: \(error)")
            }
        }
    }
    
    private func setupWatchConnectivity() {
        #if canImport(WatchConnectivity)
        if WCSession.isSupported() {
            session = WCSession.default
            session?.delegate = self
            session?.activate()
        }
        #endif
    }
    
    private func setupBackgroundTasks() {
        backgroundTaskScheduler = BackgroundTaskScheduler()
        backgroundTaskScheduler?.registerBackgroundTasks()
    }
    
    private func initializeManagers() {
        // Initialize core managers
        _ = SleepOptimizationManager.shared
        _ = HealthDataManager.shared
        _ = MLModelManager.shared
        _ = PredictiveAnalyticsManager.shared
        _ = EnvironmentManager.shared
    }
    
    private func setupNotifications() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Notification authorization error: \(error)")
            }
        }
    }
    
    private func setupWidgets() {
        // Configure app group for data sharing
        sharedUserDefaults = UserDefaults(suiteName: "group.com.healthai2030.widgets")
        
        // Reload all widget timelines to ensure they are up-to-date
        WidgetCenter.shared.reloadAllTimelines()
        print("Widget bundle registered and timelines reloaded.")
    }
}

// MARK: - WCSessionDelegate
#if canImport(WatchConnectivity)
extension AppDelegate: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            print("Watch connectivity activation error: \(error)")
        }
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        print("Watch session became inactive")
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        print("Watch session deactivated")
    }
}
#endif
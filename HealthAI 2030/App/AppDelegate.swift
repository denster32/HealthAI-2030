import UIKit
import HealthKit
import WatchConnectivity
import CoreData
import BackgroundTasks

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
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
        
        return true
    }
    
    private func setupHealthKit() {
        healthStore = HKHealthStore()
        
        guard let healthStore = healthStore else { return }
        
        // Request authorization for required data types
        let typesToRead: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!,
            HKObjectType.quantityType(forIdentifier: .oxygenSaturation)!,
            HKObjectType.quantityType(forIdentifier: .bodyTemperature)!,
            HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!,
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!
        ]
        
        healthStore.requestAuthorization(toShare: nil, read: typesToRead) { success, error in
            if let error = error {
                print("HealthKit authorization error: \(error)")
            }
        }
    }
    
    private func setupWatchConnectivity() {
        if WCSession.isSupported() {
            session = WCSession.default
            session?.delegate = self
            session?.activate()
        }
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
}

// MARK: - WCSessionDelegate
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
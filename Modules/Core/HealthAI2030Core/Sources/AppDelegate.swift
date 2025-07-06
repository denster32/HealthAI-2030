#if os(iOS)
import UIKit
#endif
import HealthKit
import CoreData
import BackgroundTasks
import WidgetKit // Import WidgetKit
import Sentry

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
    var enhancedBackgroundManager: EnhancedSleepBackgroundManager?

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

        // Initialize Sentry error reporting
        if let sentryDSN = SecretsManager.shared.getSecret(named: "SENTRY_DSN") {
            SentrySDK.start { options in
                options.dsn = sentryDSN
                options.debug = true
                options.environment = ProcessInfo.processInfo.environment["APP_ENV"] ?? "development"
                options.enableAutoPerformanceTracing = true
                options.enableAppHangTracking = true
                options.attachScreenshot = true
            }
        }

        return true
    }

    private func setupHealthKit() {
        healthStore = HKHealthStore()

        guard let healthStore = healthStore else { return }

        let allHealthKitTypesToRead: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!,
            HKObjectType.quantityType(forIdentifier: .oxygenSaturation)!,
            HKObjectType.quantityType(forIdentifier: .bodyTemperature)!,
            HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!,
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKObjectType.quantityType(forIdentifier: .basalEnergyBurned)!,
            HKObjectType.quantityType(forIdentifier: .dietaryEnergyConsumed)!,
            HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!,
            HKObjectType.quantityType(forIdentifier: .flightsClimbed)!,
            HKObjectType.quantityType(forIdentifier: .respiratoryRate)!,
            HKObjectType.quantityType(forIdentifier: .restingHeartRate)!,
            HKObjectType.quantityType(forIdentifier: .walkingHeartRateAverage)!,
            HKObjectType.quantityType(forIdentifier: .vo2Max)!,
            HKObjectType.quantityType(forIdentifier: .appleExerciseTime)!,
            HKObjectType.quantityType(forIdentifier: .appleStandTime)!,
            HKObjectType.quantityType(forIdentifier: .environmentalAudioExposure)!,
            HKObjectType.quantityType(forIdentifier: .headphoneAudioExposure)!,
            HKObjectType.quantityType(forIdentifier: .walkingAsymmetryPercentage)!,
            HKObjectType.quantityType(forIdentifier: .walkingDoubleSupportPercentage)!,
            HKObjectType.quantityType(forIdentifier: .walkingSpeed)!,
            HKObjectType.quantityType(forIdentifier: .walkingStepLength)!,
            HKObjectType.quantityType(forIdentifier: .sixMinuteWalkTestDistance)!,
            HKObjectType.quantityType(forIdentifier: .appleWalkingSteadiness)!,
            HKObjectType.categoryType(forIdentifier: .mindfulSession)!,
            HKObjectType.workoutType()
        ]

        let allHealthKitTypesToWrite: Set<HKSampleType> = [
            HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKObjectType.quantityType(forIdentifier: .dietaryEnergyConsumed)!,
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
            HKObjectType.workoutType()
        ]

        healthStore.requestAuthorization(toShare: allHealthKitTypesToWrite, read: allHealthKitTypesToRead) { success, error in
            if let error = error {
                print("HealthKit authorization error: \(error.localizedDescription)")
            } else if success {
                print("HealthKit authorization granted for all relevant types.")
            } else {
                print("HealthKit authorization denied.")
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
        // Legacy background task scheduler
        backgroundTaskScheduler = BackgroundTaskScheduler()
        backgroundTaskScheduler?.registerBackgroundTasks()

        // Enhanced sleep background manager
        enhancedBackgroundManager = EnhancedSleepBackgroundManager.shared

        // Enable background processing by default
        Task { @MainActor in
            enhancedBackgroundManager?.enableBackgroundProcessing()
        }
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
        sharedUserDefaults = UserDefaults(suiteName: AppConfiguration.appGroupIdentifier)

        // Implement secure data sharing for widgets using encryption
        if let defaults = sharedUserDefaults {
            defaults.set(SecretsManager.shared.encrypt(data: "widget_config"), forKey: "widget_config")
        }

        // Register deep link handler for widget interactions
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleWidgetDeepLink(_:)),
            name: NSNotification.Name("WidgetDeepLinkNotification"),
            object: nil
        )

        // Reload all widget timelines to ensure they are up-to-date
        WidgetCenter.shared.reloadAllTimelines()
    }

    @objc private func handleWidgetDeepLink(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let deepLink = userInfo["deepLink"] as? String else {
            return
        }

        // Handle different deep link actions from widgets
        switch deepLink {
        case "cardiac_alert":
            showCardiacAlertView()
        case "respiratory_alert":
            showRespiratoryAlertView()
        case "sleep_insights":
            showSleepInsightsView()
        default:
            break
        }
    }

    private func showCardiacAlertView() {
        // Implementation to show cardiac alert view
        NotificationCenter.default.post(
            name: NSNotification.Name("ShowCardiacAlert"),
            object: nil
        )
    }

    private func showRespiratoryAlertView() {
        // Implementation to show respiratory alert view
        NotificationCenter.default.post(
            name: NSNotification.Name("ShowRespiratoryAlert"),
            object: nil
        )
    }

    private func showSleepInsightsView() {
        // Implementation to show sleep insights view
        NotificationCenter.default.post(
            name: NSNotification.Name("ShowSleepInsights"),
            object: nil
        )
    }

    // MARK: - App Lifecycle for Background Tasks

    func applicationDidEnterBackground(_ application: UIApplication) {
        print("App entered background - scheduling background tasks")

        // Schedule background tasks when app goes to background
        Task { @MainActor in
            enhancedBackgroundManager?.scheduleOptimalBackgroundTasks()
        }

        // Update user sleep time if sleep session is active
        if let sleepManager = SleepManager.shared as? SleepManager,
           sleepManager.isMonitoring {
            Task { @MainActor in
                enhancedBackgroundManager?.updateUserSleepTime(Date())
            }
        }
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        print("App will enter foreground")

        // Handle app entering foreground
        Task { @MainActor in
            enhancedBackgroundManager?.handleAppWillEnterForeground()
        }
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        print("App became active")

        // Handle app becoming active
        Task { @MainActor in
            enhancedBackgroundManager?.handleAppDidBecomeActive()
        }

        // Reload widget timelines
        WidgetCenter.shared.reloadAllTimelines()
    }

    func applicationWillResignActive(_ application: UIApplication) {
        print("App will resign active")
        // App is about to become inactive
    }

    func applicationWillTerminate(_ application: UIApplication) {
        print("App will terminate")

        // Save any pending data before termination
        Task { @MainActor in
            // Ensure all data is saved
            if let sleepManager = SleepManager.shared as? SleepManager,
               sleepManager.isMonitoring {
                await sleepManager.endSleepSession()
            }
        }
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
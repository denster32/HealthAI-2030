//
//  HealthAI_2030App.swift
//  HealthAI 2030
//
//  Created by Denster on 7/1/25.
//

import SwiftUI
import HealthKit
import WidgetKit
import BackgroundTasks
import UserNotifications
import Intents
import IntentsUI
import AppIntents
import TipKit
import OSLog
import ActivityKit

@main
struct HealthAI_2030App: App {
    // MARK: - Core Managers
    @StateObject private var healthDataManager = HealthDataManager.shared
    @StateObject private var sleepOptimizationManager = SleepOptimizationManager.shared
    @StateObject private var environmentManager = EnvironmentManager.shared
    @StateObject private var mentalHealthManager = MentalHealthManager.shared
    @StateObject private var advancedCardiacManager = AdvancedCardiacManager.shared
    @StateObject private var respiratoryHealthManager = RespiratoryHealthManager.shared
    @StateObject private var systemIntelligenceManager = SystemIntelligenceManager.shared
    @StateObject private var emergencyAlertManager = EmergencyAlertManager.shared
    @StateObject private var federatedLearningManager = FederatedLearningManager.shared
    @StateObject private var predictiveAnalyticsManager = PredictiveAnalyticsManager.shared
    
    // MARK: - Advanced AI/ML Managers
    @StateObject private var advancedMLEngine = AdvancedMLEngine.shared
    @StateObject private var personalizationEngine = PersonalizationEngine()
    @StateObject private var aiHealthCoach = AIHealthCoach.shared
    @StateObject private var audioGenerationEngine = AudioGenerationEngine.shared
    @StateObject private var audioTransitionEngine = AudioTransitionEngine.shared
    
    // MARK: - iOS 18 Feature Managers
    @StateObject private var liveActivityManager = LiveActivityManager()
    @StateObject private var shortcutsManager = ShortcutsManager()
    @StateObject private var interactiveWidgetManager = InteractiveWidgetManager()
    @StateObject private var controlCenterManager = ControlCenterManager()
    @StateObject private var spotlightManager = SpotlightManager()
    
    // MARK: - App State
    @AppStorage("onboarding_completed") private var onboardingCompleted = false
    @AppStorage("app_theme") private var appTheme: AppTheme = .system
    @AppStorage("haptic_feedback_enabled") private var hapticFeedbackEnabled = true
    
    // MARK: - Logger
    private let logger = Logger(subsystem: "com.healthai2030.app", category: "main")
    
    init() {
        setupApp()
    }
    
    var body: some Scene {
        WindowGroup {
            Group {
                if onboardingCompleted {
                    MainTabView()
                } else {
                    OnboardingView(onboardingCompleted: $onboardingCompleted)
                }
            }
            .environmentObject(healthDataManager)
            .environmentObject(sleepOptimizationManager)
            .environmentObject(environmentManager)
            .environmentObject(mentalHealthManager)
            .environmentObject(advancedCardiacManager)
            .environmentObject(respiratoryHealthManager)
            .environmentObject(systemIntelligenceManager)
            .environmentObject(emergencyAlertManager)
            .environmentObject(federatedLearningManager)
            .environmentObject(predictiveAnalyticsManager)
            // Advanced AI/ML Environment Objects
            .environmentObject(advancedMLEngine)
            .environmentObject(personalizationEngine)
            .environmentObject(aiHealthCoach)
            .environmentObject(audioGenerationEngine)
            .environmentObject(audioTransitionEngine)
            // iOS 18 Feature Environment Objects
            .environmentObject(liveActivityManager)
            .environmentObject(shortcutsManager)
            .environmentObject(interactiveWidgetManager)
            .environmentObject(controlCenterManager)
            .environmentObject(spotlightManager)
            .preferredColorScheme(colorSchemeForTheme(appTheme))
            .task {
                // iOS 18: Initialize TipKit
                try? Tips.configure([
                    .displayFrequency(.immediate),
                    .datastoreLocation(.applicationDefault)
                ])
            }
            .onAppear {
                setupApp()
                setupWidgets()
                requestPermissions()
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                refreshApp()
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                handleForegroundTransition()
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)) { _ in
                handleBackgroundTransition()
            }
        }
        .commands {
            MenuBarCommands()
        }
        .handlesExternalEvents(matching: Set(arrayLiteral: "*"))
    }
    
    private func setupApp() {
        logger.info("Setting up HealthAI 2030 app")
        
        // Configure app appearance with iOS 18 enhancements
        configureAppAppearance()
        
        // Setup app groups for widget data sharing
        setupAppGroups()
        
        // Configure iOS 18 App Intents
        configureAppIntents()
        
        // Initialize core managers
        initializeManagers()
        
        // Initialize advanced AI/ML systems
        initializeAIComponents()
        
        // Configure background tasks
        configureBackgroundTasks()
        
        // Setup iOS 18 Live Activities
        setupLiveActivities()
        
        // Configure Control Center widgets
        setupControlCenter()
        
        // Setup interactive notifications
        setupInteractiveNotifications()
        
        // Configure Shortcuts and Siri integration
        setupShortcutsIntegration()
        
        // Setup Spotlight search integration
        setupSpotlightIntegration()
    }
    
    private func configureAppAppearance() {
        // Set navigation bar appearance
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.systemBackground
        appearance.titleTextAttributes = [.foregroundColor: UIColor.label]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.label]
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        
        // Set tab bar appearance
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.backgroundColor = UIColor.systemBackground
        
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
    }
    
    private func setupAppGroups() {
        // Configure app group for widget data sharing
        let appGroupIdentifier = "group.com.healthai2030.widgets"
        
        // Setup shared UserDefaults
        if let sharedDefaults = UserDefaults(suiteName: appGroupIdentifier) {
            // Initialize default values
            if sharedDefaults.object(forKey: "widget_data_version") == nil {
                sharedDefaults.set("1.0", forKey: "widget_data_version")
            }
        }
        
        // Setup shared file container
        if let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier) {
            // Create necessary directories
            let healthDataURL = containerURL.appendingPathComponent("HealthData")
            let widgetCacheURL = containerURL.appendingPathComponent("WidgetCache")
            
            try? FileManager.default.createDirectory(at: healthDataURL, withIntermediateDirectories: true)
            try? FileManager.default.createDirectory(at: widgetCacheURL, withIntermediateDirectories: true)
        }
    }
    
    private func initializeManagers() {
        // Initialize all managers in the correct order
        Task {
            // Initialize health data manager first
            await healthDataManager.initialize()
            
            // Initialize other managers
            await mentalHealthManager.initialize()
            await advancedCardiacManager.initialize()
            await respiratoryHealthManager.initialize()
            await sleepOptimizationManager.initialize()
            await environmentManager.initialize()
            await systemIntelligenceManager.initialize()
            await emergencyAlertManager.initialize()
            await federatedLearningManager.initialize()
            await predictiveAnalyticsManager.initialize()
        }
    }
    
    private func configureBackgroundTasks() {
        // Register background tasks for health data updates
        UIApplication.shared.setMinimumBackgroundFetchInterval(UIApplication.backgroundFetchIntervalMinimum)
        
        // Register background processing tasks
        let backgroundTaskIdentifier = "com.healthai2030.background-health-update"
        BGTaskScheduler.shared.register(forTaskWithIdentifier: backgroundTaskIdentifier, using: nil) { task in
            self.handleBackgroundHealthUpdate(task: task as! BGProcessingTask)
        }
    }
    
    private func setupWidgets() {
        // Register widget timeline providers
        WidgetCenter.shared.reloadAllTimelines()
        
        // Setup widget data sharing
        setupWidgetDataSharing()
    }
    
    private func setupWidgetDataSharing() {
        // Share health data with widgets
        Task {
            await shareHealthDataWithWidgets()
        }
    }
    
    private func shareHealthDataWithWidgets() async {
        let appGroupIdentifier = "group.com.healthai2030.widgets"
        
        guard let sharedDefaults = UserDefaults(suiteName: appGroupIdentifier) else {
            print("Failed to access app group UserDefaults")
            return
        }
        
        // Share mental health data
        let mentalHealthData: [String: Any] = [
            "score": mentalHealthManager.mentalHealthScore,
            "stressLevel": mentalHealthManager.stressLevel.rawValue,
            "mindfulnessMinutes": Int(mentalHealthManager.mindfulnessSessions.reduce(0) { $0 + $1.duration } / 60),
            "lastUpdated": Date().timeIntervalSince1970
        ]
        sharedDefaults.set(mentalHealthData, forKey: "mental_health_data")
        
        // Share cardiac health data
        let cardiacHealthData: [String: Any] = [
            "heartRate": advancedCardiacManager.heartRateData.first?.value ?? 0,
            "hrv": advancedCardiacManager.hrvData.first?.value ?? 0,
            "afibStatus": advancedCardiacManager.afibStatus.rawValue,
            "vo2Max": advancedCardiacManager.vo2Max,
            "lastUpdated": Date().timeIntervalSince1970
        ]
        sharedDefaults.set(cardiacHealthData, forKey: "cardiac_health_data")
        
        // Share respiratory health data
        let respiratoryHealthData: [String: Any] = [
            "respiratoryRate": respiratoryHealthManager.respiratoryRate,
            "oxygenSaturation": respiratoryHealthManager.oxygenSaturation,
            "efficiency": respiratoryHealthManager.respiratoryEfficiency,
            "pattern": respiratoryHealthManager.breathingPattern.rawValue,
            "lastUpdated": Date().timeIntervalSince1970
        ]
        sharedDefaults.set(respiratoryHealthData, forKey: "respiratory_health_data")
        
        // Share sleep optimization data
        let sleepOptimizationData: [String: Any] = [
            "quality": sleepOptimizationManager.sleepQuality,
            "stage": sleepOptimizationManager.currentSleepStage.rawValue,
            "isActive": sleepOptimizationManager.isOptimizationActive,
            "temperature": environmentManager.currentTemperature,
            "humidity": environmentManager.currentHumidity,
            "lastUpdated": Date().timeIntervalSince1970
        ]
        sharedDefaults.set(sleepOptimizationData, forKey: "sleep_optimization_data")
        
        // Reload widget timelines
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    private func refreshWidgets() {
        // Refresh widget data when app becomes active
        Task {
            await shareHealthDataWithWidgets()
        }
    }
    
    private func requestPermissions() {
        requestHealthKitPermissions()
        requestNotificationPermissions()
        requestLocationPermissions()
        requestMotionPermissions()
    }
    
    private func requestHealthKitPermissions() {
        // Request HealthKit permissions for iOS 18/19 features
        let healthStore = HKHealthStore()
        
        guard HKHealthStore.isHealthDataAvailable() else {
            print("HealthKit is not available on this device")
            return
        }
        
        let healthTypes: Set<HKObjectType> = [
            // Mental Health (iOS 18/19)
            HKObjectType.categoryType(forIdentifier: .mindfulSession)!,
            HKObjectType.categoryType(forIdentifier: .mentalState)!,
            HKObjectType.categoryType(forIdentifier: .stressLevel)!,
            HKObjectType.categoryType(forIdentifier: .moodChanges)!,
            
            // Advanced Cardiac (iOS 18/19)
            HKObjectType.categoryType(forIdentifier: .atrialFibrillation)!,
            HKObjectType.quantityType(forIdentifier: .vo2Max)!,
            HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!,
            HKObjectType.quantityType(forIdentifier: .heartRateVariabilityRMSSD)!,
            
            // Respiratory Health (iOS 18/19)
            HKObjectType.quantityType(forIdentifier: .respiratoryRate)!,
            HKObjectType.quantityType(forIdentifier: .oxygenSaturation)!,
            HKObjectType.categoryType(forIdentifier: .respiratoryEfficiency)!,
            HKObjectType.categoryType(forIdentifier: .breathingPattern)!,
            
            // Standard Health Data
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKObjectType.quantityType(forIdentifier: .bodyMass)!,
            HKObjectType.quantityType(forIdentifier: .bodyFatPercentage)!,
            HKObjectType.quantityType(forIdentifier: .bodyTemperature)!,
            HKObjectType.quantityType(forIdentifier: .bloodPressureSystolic)!,
            HKObjectType.quantityType(forIdentifier: .bloodPressureDiastolic)!,
            HKObjectType.quantityType(forIdentifier: .bloodGlucose)!,
            HKObjectType.quantityType(forIdentifier: .sleepAnalysis)!,
            HKObjectType.quantityType(forIdentifier: .respiratoryRate)!,
            HKObjectType.quantityType(forIdentifier: .oxygenSaturation)!,
            HKObjectType.quantityType(forIdentifier: .peakExpiratoryFlowRate)!,
            HKObjectType.quantityType(forIdentifier: .forcedExpiratoryVolume1)!,
            HKObjectType.quantityType(forIdentifier: .forcedVitalCapacity)!,
            HKObjectType.quantityType(forIdentifier: .inhalerUsage)!,
            HKObjectType.quantityType(forIdentifier: .insulinDelivery)!,
            HKObjectType.quantityType(forIdentifier: .dietaryWater)!,
            HKObjectType.quantityType(forIdentifier: .dietaryCaffeine)!,
            HKObjectType.quantityType(forIdentifier: .dietaryEnergyConsumed)!,
            HKObjectType.quantityType(forIdentifier: .dietaryFatTotal)!,
            HKObjectType.quantityType(forIdentifier: .dietaryProtein)!,
            HKObjectType.quantityType(forIdentifier: .dietaryCarbohydrates)!,
            HKObjectType.quantityType(forIdentifier: .dietaryFiber)!,
            HKObjectType.quantityType(forIdentifier: .dietarySugar)!,
            HKObjectType.quantityType(forIdentifier: .dietarySodium)!,
            HKObjectType.quantityType(forIdentifier: .dietaryPotassium)!,
            HKObjectType.quantityType(forIdentifier: .dietaryCalcium)!,
            HKObjectType.quantityType(forIdentifier: .dietaryIron)!,
            HKObjectType.quantityType(forIdentifier: .dietaryThiamin)!,
            HKObjectType.quantityType(forIdentifier: .dietaryRiboflavin)!,
            HKObjectType.quantityType(forIdentifier: .dietaryNiacin)!,
            HKObjectType.quantityType(forIdentifier: .dietaryFolate)!,
            HKObjectType.quantityType(forIdentifier: .dietaryVitaminA)!,
            HKObjectType.quantityType(forIdentifier: .dietaryVitaminB6)!,
            HKObjectType.quantityType(forIdentifier: .dietaryVitaminB12)!,
            HKObjectType.quantityType(forIdentifier: .dietaryVitaminC)!,
            HKObjectType.quantityType(forIdentifier: .dietaryVitaminD)!,
            HKObjectType.quantityType(forIdentifier: .dietaryVitaminE)!,
            HKObjectType.quantityType(forIdentifier: .dietaryVitaminK)!,
            HKObjectType.quantityType(forIdentifier: .dietaryZinc)!,
            HKObjectType.quantityType(forIdentifier: .dietaryCopper)!,
            HKObjectType.quantityType(forIdentifier: .dietaryManganese)!,
            HKObjectType.quantityType(forIdentifier: .dietarySelenium)!,
            HKObjectType.quantityType(forIdentifier: .dietaryChromium)!,
            HKObjectType.quantityType(forIdentifier: .dietaryMolybdenum)!,
            HKObjectType.quantityType(forIdentifier: .dietaryChloride)!,
            HKObjectType.quantityType(forIdentifier: .dietaryBiotin)!,
            HKObjectType.quantityType(forIdentifier: .dietaryPantothenicAcid)!,
            HKObjectType.quantityType(forIdentifier: .dietaryIodine)!,
            HKObjectType.quantityType(forIdentifier: .dietaryCholesterol)!,
            HKObjectType.quantityType(forIdentifier: .dietaryMonounsaturatedFat)!,
            HKObjectType.quantityType(forIdentifier: .dietaryPolyunsaturatedFat)!,
            HKObjectType.quantityType(forIdentifier: .dietarySaturatedFat)!,
            HKObjectType.quantityType(forIdentifier: .dietaryTransFat)!,
            HKObjectType.quantityType(forIdentifier: .dietaryOmega3FattyAcids)!,
            HKObjectType.quantityType(forIdentifier: .dietaryOmega6FattyAcids)!,
            HKObjectType.quantityType(forIdentifier: .dietaryCaffeine)!,
            HKObjectType.quantityType(forIdentifier: .dietaryWater)!,
            HKObjectType.quantityType(forIdentifier: .dietaryEnergyConsumed)!,
            HKObjectType.quantityType(forIdentifier: .dietaryFatTotal)!,
            HKObjectType.quantityType(forIdentifier: .dietaryProtein)!,
            HKObjectType.quantityType(forIdentifier: .dietaryCarbohydrates)!,
            HKObjectType.quantityType(forIdentifier: .dietaryFiber)!,
            HKObjectType.quantityType(forIdentifier: .dietarySugar)!,
            HKObjectType.quantityType(forIdentifier: .dietarySodium)!,
            HKObjectType.quantityType(forIdentifier: .dietaryPotassium)!,
            HKObjectType.quantityType(forIdentifier: .dietaryCalcium)!,
            HKObjectType.quantityType(forIdentifier: .dietaryIron)!,
            HKObjectType.quantityType(forIdentifier: .dietaryThiamin)!,
            HKObjectType.quantityType(forIdentifier: .dietaryRiboflavin)!,
            HKObjectType.quantityType(forIdentifier: .dietaryNiacin)!,
            HKObjectType.quantityType(forIdentifier: .dietaryFolate)!,
            HKObjectType.quantityType(forIdentifier: .dietaryVitaminA)!,
            HKObjectType.quantityType(forIdentifier: .dietaryVitaminB6)!,
            HKObjectType.quantityType(forIdentifier: .dietaryVitaminB12)!,
            HKObjectType.quantityType(forIdentifier: .dietaryVitaminC)!,
            HKObjectType.quantityType(forIdentifier: .dietaryVitaminD)!,
            HKObjectType.quantityType(forIdentifier: .dietaryVitaminE)!,
            HKObjectType.quantityType(forIdentifier: .dietaryVitaminK)!,
            HKObjectType.quantityType(forIdentifier: .dietaryZinc)!,
            HKObjectType.quantityType(forIdentifier: .dietaryCopper)!,
            HKObjectType.quantityType(forIdentifier: .dietaryManganese)!,
            HKObjectType.quantityType(forIdentifier: .dietarySelenium)!,
            HKObjectType.quantityType(forIdentifier: .dietaryChromium)!,
            HKObjectType.quantityType(forIdentifier: .dietaryMolybdenum)!,
            HKObjectType.quantityType(forIdentifier: .dietaryChloride)!,
            HKObjectType.quantityType(forIdentifier: .dietaryBiotin)!,
            HKObjectType.quantityType(forIdentifier: .dietaryPantothenicAcid)!,
            HKObjectType.quantityType(forIdentifier: .dietaryIodine)!,
            HKObjectType.quantityType(forIdentifier: .dietaryCholesterol)!,
            HKObjectType.quantityType(forIdentifier: .dietaryMonounsaturatedFat)!,
            HKObjectType.quantityType(forIdentifier: .dietaryPolyunsaturatedFat)!,
            HKObjectType.quantityType(forIdentifier: .dietarySaturatedFat)!,
            HKObjectType.quantityType(forIdentifier: .dietaryTransFat)!,
            HKObjectType.quantityType(forIdentifier: .dietaryOmega3FattyAcids)!,
            HKObjectType.quantityType(forIdentifier: .dietaryOmega6FattyAcids)!
        ]
        
        healthStore.requestAuthorization(toShare: nil, read: healthTypes) { success, error in
            if success {
                print("HealthKit permissions granted")
                // Initialize health data after permissions
                Task {
                    await self.healthDataManager.refreshHealthData()
                }
            } else {
                print("HealthKit permissions denied: \(error?.localizedDescription ?? "Unknown error")")
            }
        }
    }
    
    private func handleBackgroundHealthUpdate(task: BGProcessingTask) {
        // Handle background health data updates
        task.expirationHandler = {
            task.setTaskCompleted(success: false)
        }
        
        Task {
            await healthDataManager.refreshHealthData()
            await shareHealthDataWithWidgets()
            task.setTaskCompleted(success: true)
        }
    }
}

// MARK: - Manager Extensions

extension MentalHealthManager {
    func initialize() async {
        // Initialize mental health manager
        await refreshMentalHealthData()
    }
}

extension AdvancedCardiacManager {
    func initialize() async {
        // Initialize cardiac manager
        await refreshCardiacData()
    }
}

extension RespiratoryHealthManager {
    func initialize() async {
        // Initialize respiratory manager
        await refreshRespiratoryData()
    }
}

extension SleepOptimizationManager {
    func initialize() async {
        // Initialize sleep optimization manager
        await refreshSleepData()
    }
}

extension EnvironmentManager {
    func initialize() async {
        // Initialize environment manager
        await refreshEnvironmentData()
    }
}

extension SystemIntelligenceManager {
    func initialize() async {
        // Initialize system intelligence manager
        setupSystemIntelligence()
    }
}

extension EmergencyAlertManager {
    func initialize() async {
        // Initialize emergency alert manager
        setupEmergencyAlerts()
    }
}

extension FederatedLearningManager {
    func initialize() async {
        // Initialize federated learning manager
        setupFederatedLearning()
    }
}

extension PredictiveAnalyticsManager {
    func initialize() async {
        // Initialize predictive analytics manager
        setupPredictiveAnalytics()
    }
}

// MARK: - iOS 18 Feature Setup Methods

extension HealthAI_2030App {
    
    private func configureAppIntents() {
        // Configure App Intents for iOS 18 Shortcuts integration
        logger.info("Configuring App Intents")
        
        // Register app intents for Siri and Shortcuts
        AppDependencyManager.shared.add(dependency: healthDataManager)
        AppDependencyManager.shared.add(dependency: sleepOptimizationManager)
        AppDependencyManager.shared.add(dependency: aiHealthCoach)
    }
    
    private func initializeAIComponents() {
        Task {
            logger.info("Initializing advanced AI/ML components")
            
            // Initialize AI engines in proper order
            await advancedMLEngine.loadModels()
            await personalizationEngine.initialize()
            await aiHealthCoach.initialize()
            await audioGenerationEngine.initialize()
            await audioTransitionEngine.initialize()
        }
    }
    
    private func setupLiveActivities() {
        Task {
            logger.info("Setting up Live Activities")
            await liveActivityManager.initialize()
            
            // Start sleep tracking activity if user is in sleep mode
            if sleepOptimizationManager.isOptimizationActive {
                await liveActivityManager.startSleepTrackingActivity()
            }
        }
    }
    
    private func setupControlCenter() {
        Task {
            logger.info("Setting up Control Center widgets")
            await controlCenterManager.initialize()
        }
    }
    
    private func setupInteractiveNotifications() {
        logger.info("Setting up interactive notifications")
        
        // Register notification categories with iOS 18 enhancements
        let center = UNUserNotificationCenter.current()
        
        // Sleep coaching notification category
        let coachingAction = UNNotificationAction(
            identifier: "COACHING_ACTION",
            title: "Get Coaching",
            options: [.foreground, .authenticationRequired]
        )
        
        let dismissAction = UNNotificationAction(
            identifier: "DISMISS_ACTION",
            title: "Not Now",
            options: []
        )
        
        let coachingCategory = UNNotificationCategory(
            identifier: "SLEEP_COACHING",
            actions: [coachingAction, dismissAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )
        
        // Health alert notification category
        let viewDetailsAction = UNNotificationAction(
            identifier: "VIEW_DETAILS",
            title: "View Details",
            options: [.foreground]
        )
        
        let takeActionAction = UNNotificationAction(
            identifier: "TAKE_ACTION",
            title: "Take Action",
            options: [.foreground, .authenticationRequired]
        )
        
        let healthAlertCategory = UNNotificationCategory(
            identifier: "HEALTH_ALERT",
            actions: [viewDetailsAction, takeActionAction, dismissAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )
        
        center.setNotificationCategories([coachingCategory, healthAlertCategory])
    }
    
    private func setupShortcutsIntegration() {
        Task {
            logger.info("Setting up Shortcuts integration")
            await shortcutsManager.initialize()
            
            // Donate common user intents
            await shortcutsManager.donateCommonIntents()
        }
    }
    
    private func setupSpotlightIntegration() {
        Task {
            logger.info("Setting up Spotlight integration")
            await spotlightManager.initialize()
            
            // Index current health data for Spotlight search
            await spotlightManager.indexHealthData()
        }
    }
    
    private func requestNotificationPermissions() {
        logger.info("Requesting notification permissions")
        
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .badge, .sound, .criticalAlert, .provisional]) { granted, error in
            if granted {
                self.logger.info("Notification permissions granted")
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            } else {
                self.logger.error("Notification permissions denied: \(error?.localizedDescription ?? "Unknown")")
            }
        }
    }
    
    private func requestLocationPermissions() {
        logger.info("Requesting location permissions for environment optimization")
        // Location permissions would be handled by CLLocationManager in EnvironmentManager
    }
    
    private func requestMotionPermissions() {
        logger.info("Requesting motion permissions for advanced health tracking")
        // Motion permissions would be handled by CMMotionManager in HealthDataManager
    }
    
    private func refreshApp() {
        Task {
            logger.info("Refreshing app data")
            
            // Refresh all managers
            await healthDataManager.refreshHealthData()
            await shareHealthDataWithWidgets()
            
            // Update Live Activities
            await liveActivityManager.updateActivities()
            
            // Update Spotlight index
            await spotlightManager.updateIndex()
        }
    }
    
    private func handleForegroundTransition() {
        logger.info("App entering foreground")
        
        Task {
            // Resume health monitoring
            await healthDataManager.resumeMonitoring()
            
            // Update AI models with latest data
            await advancedMLEngine.updateWithLatestData()
            
            // Check for coaching opportunities
            await aiHealthCoach.checkForCoachingOpportunities()
        }
    }
    
    private func handleBackgroundTransition() {
        logger.info("App entering background")
        
        Task {
            // Optimize for background execution
            await healthDataManager.optimizeForBackground()
            
            // Schedule background processing
            scheduleBackgroundProcessing()
            
            // Update widgets one final time
            await shareHealthDataWithWidgets()
        }
    }
    
    private func scheduleBackgroundProcessing() {
        let request = BGProcessingTaskRequest(identifier: "com.healthai2030.background-health-update")
        request.requiresNetworkConnectivity = false
        request.requiresExternalPower = false
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60) // 15 minutes
        
        try? BGTaskScheduler.shared.submit(request)
    }
    
    private func colorSchemeForTheme(_ theme: AppTheme) -> ColorScheme? {
        switch theme {
        case .light:
            return .light
        case .dark:
            return .dark
        case .system:
            return nil
        }
    }
}

// MARK: - Supporting Types

enum AppTheme: String, CaseIterable {
    case system = "system"
    case light = "light"
    case dark = "dark"
    
    var displayName: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }
}

// MARK: - Menu Bar Commands

struct MenuBarCommands: Commands {
    var body: some Commands {
        CommandGroup(replacing: .newItem) {
            Button("Start Sleep Tracking") {
                NotificationCenter.default.post(name: .startSleepTracking, object: nil)
            }
            .keyboardShortcut("s", modifiers: [.command, .shift])
            
            Button("Open AI Coach") {
                NotificationCenter.default.post(name: .openAICoach, object: nil)
            }
            .keyboardShortcut("c", modifiers: [.command, .shift])
            
            Divider()
            
            Button("View Health Summary") {
                NotificationCenter.default.post(name: .viewHealthSummary, object: nil)
            }
            .keyboardShortcut("h", modifiers: [.command])
        }
        
        CommandGroup(after: .help) {
            Button("Health Insights") {
                NotificationCenter.default.post(name: .showHealthInsights, object: nil)
            }
            
            Button("Sleep Analytics") {
                NotificationCenter.default.post(name: .showSleepAnalytics, object: nil)
            }
            
            Button("AI Recommendations") {
                NotificationCenter.default.post(name: .showAIRecommendations, object: nil)
            }
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let startSleepTracking = Notification.Name("startSleepTracking")
    static let openAICoach = Notification.Name("openAICoach")
    static let viewHealthSummary = Notification.Name("viewHealthSummary")
    static let showHealthInsights = Notification.Name("showHealthInsights")
    static let showSleepAnalytics = Notification.Name("showSleepAnalytics")
    static let showAIRecommendations = Notification.Name("showAIRecommendations")
}

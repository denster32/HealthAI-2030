//
//  HealthAI_2030App.swift
//  HealthAI 2030
//
//  Created by Denster on 7/1/25.
//

import SwiftUI
import HealthKit
import WidgetKit

@main
struct HealthAI_2030App: App {
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
    
    init() {
        setupApp()
    }
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
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
                .onAppear {
                    setupWidgets()
                    requestHealthKitPermissions()
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                    refreshWidgets()
                }
        }
    }
    
    private func setupApp() {
        // Configure app appearance
        configureAppAppearance()
        
        // Setup app groups for widget data sharing
        setupAppGroups()
        
        // Initialize core managers
        initializeManagers()
        
        // Configure background tasks
        configureBackgroundTasks()
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

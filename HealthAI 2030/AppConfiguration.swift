import Foundation
import UIKit
import HealthKit
import CoreLocation
import AVFoundation
import CoreMotion
import WatchConnectivity
import BackgroundTasks
import os.log
import Combine

/// AppConfiguration - Centralized configuration management for SomnaSync Pro
@MainActor
class AppConfiguration: ObservableObject {
    static let shared = AppConfiguration()
    
    // MARK: - Published Properties
    @Published var isFirstLaunch: Bool = true
    @Published var hasCompletedOnboarding: Bool = false
    @Published var hasGrantedHealthKitPermissions: Bool = false
    @Published var hasGrantedNotificationPermissions: Bool = false
    @Published var hasGrantedMicrophonePermissions: Bool = false
    
    // MARK: - User Preferences
    @Published var sleepGoal: TimeInterval = 28800 // 8 hours
    @Published var preferredWakeTime: Date = Calendar.current.date(from: DateComponents(hour: 7, minute: 0)) ?? Date()
    @Published var preferredBedTime: Date = Calendar.current.date(from: DateComponents(hour: 23, minute: 0)) ?? Date()
    @Published var preferredTrackingMode: TrackingMode = .hybrid
    
    // MARK: - Audio Preferences
    @Published var audioQuality: AudioQuality = .high
    @Published var spatialAudioEnabled: Bool = true
    @Published var hapticFeedbackEnabled: Bool = true
    @Published var autoVolumeAdjustment: Bool = true
    @Published var smartFadingEnabled: Bool = true
    @Published var adaptiveMixingEnabled: Bool = true
    @Published var alarmVolume: Float = 0.7
    @Published var fadeInDuration: TimeInterval = 30
    @Published var fadeOutDuration: TimeInterval = 60
    @Published var reverbLevel: Float = 0.3
    @Published var eqPreset: EQPreset = .neutral
    
    // MARK: - Sleep Preferences
    @Published var preferredPreSleepAudio: PreSleepAudioType = .binauralBeats(frequency: 6.0)
    @Published var preferredSleepAudio: SleepAudioType = .deepSleep(frequency: 2.5)
    @Published var sleepReminderEnabled: Bool = true
    @Published var sleepReminderTime: Date = Calendar.current.date(from: DateComponents(hour: 22, minute: 30)) ?? Date()
    @Published var wakeUpReminderEnabled: Bool = true
    @Published var wakeUpReminderTime: Date = Calendar.current.date(from: DateComponents(hour: 6, minute: 30)) ?? Date()
    
    // MARK: - Privacy & Data
    @Published var dataCollectionEnabled: Bool = true
    @Published var analyticsEnabled: Bool = false
    @Published var crashReportingEnabled: Bool = true
    @Published var dataRetentionDays: Int = 365
    
    // MARK: - Notifications
    @Published var sleepInsightsEnabled: Bool = true
    @Published var weeklyReportEnabled: Bool = true
    @Published var achievementNotificationsEnabled: Bool = true
    @Published var soundNotificationsEnabled: Bool = true
    
    // MARK: - Advanced Settings
    @Published var aiAnalysisEnabled: Bool = true
    @Published var personalizedRecommendationsEnabled: Bool = true
    @Published var sleepStagePredictionEnabled: Bool = true
    @Published var biometricMonitoringEnabled: Bool = true
    @Published var watchSyncEnabled: Bool = true
    
    // MARK: - Private Properties
    private let userDefaults = UserDefaults.standard
    private let logger = Logger.app
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Keys
    private enum Keys {
        static let isFirstLaunch = "isFirstLaunch"
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
        static let hasGrantedHealthKitPermissions = "hasGrantedHealthKitPermissions"
        static let hasGrantedNotificationPermissions = "hasGrantedNotificationPermissions"
        static let hasGrantedMicrophonePermissions = "hasGrantedMicrophonePermissions"
        static let sleepGoal = "sleepGoal"
        static let preferredWakeTime = "preferredWakeTime"
        static let preferredBedTime = "preferredBedTime"
        static let preferredTrackingMode = "preferredTrackingMode"
        static let audioQuality = "audioQuality"
        static let spatialAudioEnabled = "spatialAudioEnabled"
        static let hapticFeedbackEnabled = "hapticFeedbackEnabled"
        static let autoVolumeAdjustment = "autoVolumeAdjustment"
        static let smartFadingEnabled = "smartFadingEnabled"
        static let adaptiveMixingEnabled = "adaptiveMixingEnabled"
        static let alarmVolume = "alarmVolume"
        static let fadeInDuration = "fadeInDuration"
        static let fadeOutDuration = "fadeOutDuration"
        static let reverbLevel = "reverbLevel"
        static let eqPreset = "eqPreset"
        static let preferredPreSleepAudio = "preferredPreSleepAudio"
        static let preferredSleepAudio = "preferredSleepAudio"
        static let sleepReminderEnabled = "sleepReminderEnabled"
        static let sleepReminderTime = "sleepReminderTime"
        static let wakeUpReminderEnabled = "wakeUpReminderEnabled"
        static let wakeUpReminderTime = "wakeUpReminderTime"
        static let dataCollectionEnabled = "dataCollectionEnabled"
        static let analyticsEnabled = "analyticsEnabled"
        static let crashReportingEnabled = "crashReportingEnabled"
        static let dataRetentionDays = "dataRetentionDays"
        static let sleepInsightsEnabled = "sleepInsightsEnabled"
        static let weeklyReportEnabled = "weeklyReportEnabled"
        static let achievementNotificationsEnabled = "achievementNotificationsEnabled"
        static let soundNotificationsEnabled = "soundNotificationsEnabled"
        static let aiAnalysisEnabled = "aiAnalysisEnabled"
        static let personalizedRecommendationsEnabled = "personalizedRecommendationsEnabled"
        static let sleepStagePredictionEnabled = "sleepStagePredictionEnabled"
        static let biometricMonitoringEnabled = "biometricMonitoringEnabled"
        static let watchSyncEnabled = "watchSyncEnabled"
    }
    
    // MARK: - Memory Optimization
    
    /// Intelligent configuration cache for frequently accessed settings
    private var configurationCache: [String: Any] = [:]
    private let cacheQueue = DispatchQueue(label: "com.somnasync.config.cache", qos: .userInitiated)
    private let memoryPressureObserver = NSNotificationCenter.default
    
    // MARK: - Optimized Configuration Management
    
    private func setupOptimizedConfiguration() {
        // Setup memory pressure handling
        memoryPressureObserver.addObserver(
            self,
            selector: #selector(handleMemoryPressure),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
        
        // Pre-load frequently accessed settings
        preloadFrequentlyAccessedSettings()
        
        // Setup intelligent persistence
        setupIntelligentPersistence()
    }
    
    private func preloadFrequentlyAccessedSettings() {
        cacheQueue.async { [weak self] in
            guard let self = self else { return }
            
            // Pre-load settings that are accessed frequently
            let frequentKeys = [
                Keys.audioQuality,
                Keys.spatialAudioEnabled,
                Keys.hapticFeedbackEnabled,
                Keys.alarmVolume,
                Keys.sleepGoal
            ]
            
            for key in frequentKeys {
                if let value = self.userDefaults.object(forKey: key) {
                    self.configurationCache[key] = value
                }
            }
            
            Logger.info("Pre-loaded \(self.configurationCache.count) frequent settings", log: Logger.app)
        }
    }
    
    private func setupIntelligentPersistence() {
        // Use debounced saving for better performance
        let debouncedSave = DebouncedSave(delay: 1.0) { [weak self] in
            self?.saveConfigurationToDisk()
        }
        
        // Monitor configuration changes
        $audioQuality
            .debounce(for: .seconds(0.5), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                debouncedSave.trigger()
            }
            .store(in: &cancellables)
        
        $spatialAudioEnabled
            .debounce(for: .seconds(0.5), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                debouncedSave.trigger()
            }
            .store(in: &cancellables)
        
        // Add more debounced saves for other frequently changed settings
    }
    
    @objc private func handleMemoryPressure() {
        Logger.warning("Memory pressure detected, clearing configuration cache", log: Logger.app)
        
        cacheQueue.async { [weak self] in
            self?.configurationCache.removeAll()
        }
    }
    
    // MARK: - Optimized Settings Access
    
    private func getCachedValue<T>(for key: String, defaultValue: T) -> T {
        // Check cache first
        if let cached = configurationCache[key] as? T {
            return cached
        }
        
        // Fall back to UserDefaults
        let value = userDefaults.object(forKey: key) as? T ?? defaultValue
        
        // Cache the value for future access
        cacheQueue.async { [weak self] in
            self?.configurationCache[key] = value
        }
        
        return value
    }
    
    private func setCachedValue<T>(_ value: T, for key: String) {
        // Update cache immediately
        cacheQueue.async { [weak self] in
            self?.configurationCache[key] = value
        }
        
        // Save to UserDefaults
        userDefaults.set(value, forKey: key)
    }
    
    // MARK: - Intelligent Data Persistence
    
    private func saveConfigurationToDisk() {
        // Save only changed values to reduce I/O
        let changedKeys = getChangedConfigurationKeys()
        
        for key in changedKeys {
            if let value = configurationCache[key] {
                userDefaults.set(value, forKey: key)
            }
        }
        
        // Synchronize only if there were changes
        if !changedKeys.isEmpty {
            userDefaults.synchronize()
            Logger.info("Saved \(changedKeys.count) changed configuration values", log: Logger.app)
        }
    }
    
    private func getChangedConfigurationKeys() -> [String] {
        var changedKeys: [String] = []
        
        for (key, cachedValue) in configurationCache {
            let storedValue = userDefaults.object(forKey: key)
            
            if !isEqual(cachedValue, storedValue) {
                changedKeys.append(key)
            }
        }
        
        return changedKeys
    }
    
    private func isEqual(_ lhs: Any?, _ rhs: Any?) -> Bool {
        if lhs == nil && rhs == nil { return true }
        guard let lhs = lhs, let rhs = rhs else { return false }
        
        // Custom equality check for different types
        if let lhsDate = lhs as? Date, let rhsDate = rhs as? Date {
            return lhsDate == rhsDate
        }
        
        if let lhsData = lhs as? Data, let rhsData = rhs as? Data {
            return lhsData == rhsData
        }
        
        return String(describing: lhs) == String(describing: rhs)
    }
    
    // MARK: - Optimized Bindings
    
    private func setupOptimizedBindings() {
        // Use efficient binding with debouncing
        setupDebouncedBindings()
        setupBatchBindings()
    }
    
    private func setupDebouncedBindings() {
        // Debounced bindings for frequently changed settings
        $audioQuality
            .debounce(for: .seconds(0.3), scheduler: RunLoop.main)
            .sink { [weak self] value in
                self?.setCachedValue(value.rawValue, for: Keys.audioQuality)
            }
            .store(in: &cancellables)
        
        $spatialAudioEnabled
            .debounce(for: .seconds(0.3), scheduler: RunLoop.main)
            .sink { [weak self] value in
                self?.setCachedValue(value, for: Keys.spatialAudioEnabled)
            }
            .store(in: &cancellables)
        
        $hapticFeedbackEnabled
            .debounce(for: .seconds(0.3), scheduler: RunLoop.main)
            .sink { [weak self] value in
                self?.setCachedValue(value, for: Keys.hapticFeedbackEnabled)
            }
            .store(in: &cancellables)
        
        $alarmVolume
            .debounce(for: .seconds(0.5), scheduler: RunLoop.main)
            .sink { [weak self] value in
                self?.setCachedValue(value, for: Keys.alarmVolume)
            }
            .store(in: &cancellables)
    }
    
    private func setupBatchBindings() {
        // Batch bindings for less frequently changed settings
        Publishers.CombineLatest4($sleepGoal, $preferredWakeTime, $preferredBedTime, $preferredTrackingMode)
            .debounce(for: .seconds(1.0), scheduler: RunLoop.main)
            .sink { [weak self] sleepGoal, wakeTime, bedTime, trackingMode in
                self?.setCachedValue(sleepGoal, for: Keys.sleepGoal)
                if let data = try? JSONEncoder().encode(wakeTime) {
                    self?.setCachedValue(data, for: Keys.preferredWakeTime)
                }
                if let data = try? JSONEncoder().encode(bedTime) {
                    self?.setCachedValue(data, for: Keys.preferredBedTime)
                }
                self?.setCachedValue(trackingMode.rawValue, for: Keys.preferredTrackingMode)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Optimized Loading
    
    private func loadOptimizedConfiguration() {
        // Load settings in batches for better performance
        loadFrequentlyAccessedSettings()
        loadAudioSettings()
        loadPrivacySettings()
        loadAdvancedSettings()
    }
    
    private func loadFrequentlyAccessedSettings() {
        isFirstLaunch = getCachedValue(for: Keys.isFirstLaunch, defaultValue: true)
        hasCompletedOnboarding = getCachedValue(for: Keys.hasCompletedOnboarding, defaultValue: false)
        hasGrantedHealthKitPermissions = getCachedValue(for: Keys.hasGrantedHealthKitPermissions, defaultValue: false)
        hasGrantedNotificationPermissions = getCachedValue(for: Keys.hasGrantedNotificationPermissions, defaultValue: false)
        hasGrantedMicrophonePermissions = getCachedValue(for: Keys.hasGrantedMicrophonePermissions, defaultValue: false)
        
        sleepGoal = getCachedValue(for: Keys.sleepGoal, defaultValue: 28800.0)
        if sleepGoal == 0 { sleepGoal = 28800 }
    }
    
    private func loadAudioSettings() {
        if let audioQualityString = getCachedValue(for: Keys.audioQuality, defaultValue: "") as? String,
           let audioQuality = AudioQuality(rawValue: audioQualityString) {
            self.audioQuality = audioQuality
        }
        
        spatialAudioEnabled = getCachedValue(for: Keys.spatialAudioEnabled, defaultValue: true)
        $sleepGoal
            .sink { [weak self] value in
                self?.userDefaults.set(value, forKey: Keys.sleepGoal)
            }
            .store(in: &cancellables)
        
        $preferredWakeTime
            .sink { [weak self] value in
                if let data = try? JSONEncoder().encode(value) {
                    self?.userDefaults.set(data, forKey: Keys.preferredWakeTime)
                }
            }
            .store(in: &cancellables)
        
        $preferredBedTime
            .sink { [weak self] value in
                if let data = try? JSONEncoder().encode(value) {
                    self?.userDefaults.set(data, forKey: Keys.preferredBedTime)
                }
            }
            .store(in: &cancellables)
        
        $preferredTrackingMode
            .sink { [weak self] value in
                self?.userDefaults.set(value.rawValue, forKey: Keys.preferredTrackingMode)
            }
            .store(in: &cancellables)
        
        $audioQuality
            .sink { [weak self] value in
                self?.userDefaults.set(value.rawValue, forKey: Keys.audioQuality)
            }
            .store(in: &cancellables)
        
        $spatialAudioEnabled
            .sink { [weak self] value in
                self?.userDefaults.set(value, forKey: Keys.spatialAudioEnabled)
            }
            .store(in: &cancellables)
        
        $hapticFeedbackEnabled
            .sink { [weak self] value in
                self?.userDefaults.set(value, forKey: Keys.hapticFeedbackEnabled)
            }
            .store(in: &cancellables)
        
        $autoVolumeAdjustment
            .sink { [weak self] value in
                self?.userDefaults.set(value, forKey: Keys.autoVolumeAdjustment)
            }
            .store(in: &cancellables)
        
        $smartFadingEnabled
            .sink { [weak self] value in
                self?.userDefaults.set(value, forKey: Keys.smartFadingEnabled)
            }
            .store(in: &cancellables)
        
        $adaptiveMixingEnabled
            .sink { [weak self] value in
                self?.userDefaults.set(value, forKey: Keys.adaptiveMixingEnabled)
            }
            .store(in: &cancellables)
        
        $alarmVolume
            .sink { [weak self] value in
                self?.userDefaults.set(value, forKey: Keys.alarmVolume)
            }
            .store(in: &cancellables)
        
        $fadeInDuration
            .sink { [weak self] value in
                self?.userDefaults.set(value, forKey: Keys.fadeInDuration)
            }
            .store(in: &cancellables)
        
        $fadeOutDuration
            .sink { [weak self] value in
                self?.userDefaults.set(value, forKey: Keys.fadeOutDuration)
            }
            .store(in: &cancellables)
        
        $reverbLevel
            .sink { [weak self] value in
                self?.userDefaults.set(value, forKey: Keys.reverbLevel)
            }
            .store(in: &cancellables)
        
        $eqPreset
            .sink { [weak self] value in
                self?.userDefaults.set(value.rawValue, forKey: Keys.eqPreset)
            }
            .store(in: &cancellables)
        
        // Bind other settings
        bindNotificationSettings()
        bindPrivacySettings()
        bindAdvancedSettings()
    }
    
    private func bindNotificationSettings() {
        $sleepReminderEnabled
            .sink { [weak self] value in
                self?.userDefaults.set(value, forKey: Keys.sleepReminderEnabled)
            }
            .store(in: &cancellables)
        
        $wakeUpReminderEnabled
            .sink { [weak self] value in
                self?.userDefaults.set(value, forKey: Keys.wakeUpReminderEnabled)
            }
            .store(in: &cancellables)
        
        $sleepReminderTime
            .sink { [weak self] value in
                if let data = try? JSONEncoder().encode(value) {
                    self?.userDefaults.set(data, forKey: Keys.sleepReminderTime)
                }
            }
            .store(in: &cancellables)
        
        $wakeUpReminderTime
            .sink { [weak self] value in
                if let data = try? JSONEncoder().encode(value) {
                    self?.userDefaults.set(data, forKey: Keys.wakeUpReminderTime)
                }
            }
            .store(in: &cancellables)
        
        $sleepInsightsEnabled
            .sink { [weak self] value in
                self?.userDefaults.set(value, forKey: Keys.sleepInsightsEnabled)
            }
            .store(in: &cancellables)
        
        $weeklyReportEnabled
            .sink { [weak self] value in
                self?.userDefaults.set(value, forKey: Keys.weeklyReportEnabled)
            }
            .store(in: &cancellables)
        
        $achievementNotificationsEnabled
            .sink { [weak self] value in
                self?.userDefaults.set(value, forKey: Keys.achievementNotificationsEnabled)
            }
            .store(in: &cancellables)
        
        $soundNotificationsEnabled
            .sink { [weak self] value in
                self?.userDefaults.set(value, forKey: Keys.soundNotificationsEnabled)
            }
            .store(in: &cancellables)
    }
    
    private func bindPrivacySettings() {
        $dataCollectionEnabled
            .sink { [weak self] value in
                self?.userDefaults.set(value, forKey: Keys.dataCollectionEnabled)
            }
            .store(in: &cancellables)
        
        $analyticsEnabled
            .sink { [weak self] value in
                self?.userDefaults.set(value, forKey: Keys.analyticsEnabled)
            }
            .store(in: &cancellables)
        
        $crashReportingEnabled
            .sink { [weak self] value in
                self?.userDefaults.set(value, forKey: Keys.crashReportingEnabled)
            }
            .store(in: &cancellables)
        
        $dataRetentionDays
            .sink { [weak self] value in
                self?.userDefaults.set(value, forKey: Keys.dataRetentionDays)
            }
            .store(in: &cancellables)
    }
    
    private func bindAdvancedSettings() {
        $aiAnalysisEnabled
            .sink { [weak self] value in
                self?.userDefaults.set(value, forKey: Keys.aiAnalysisEnabled)
            }
            .store(in: &cancellables)
        
        $personalizedRecommendationsEnabled
            .sink { [weak self] value in
                self?.userDefaults.set(value, forKey: Keys.personalizedRecommendationsEnabled)
            }
            .store(in: &cancellables)
        
        $sleepStagePredictionEnabled
            .sink { [weak self] value in
                self?.userDefaults.set(value, forKey: Keys.sleepStagePredictionEnabled)
            }
            .store(in: &cancellables)
        
        $biometricMonitoringEnabled
            .sink { [weak self] value in
                self?.userDefaults.set(value, forKey: Keys.biometricMonitoringEnabled)
            }
            .store(in: &cancellables)
        
        $watchSyncEnabled
            .sink { [weak self] value in
                self?.userDefaults.set(value, forKey: Keys.watchSyncEnabled)
            }
            .store(in: &cancellables)
    }
    
    private func loadAudioPreferences() {
        // Load preferred audio types
        if let preSleepData = userDefaults.data(forKey: Keys.preferredPreSleepAudio),
           let preSleepAudio = try? JSONDecoder().decode(PreSleepAudioType.self, from: preSleepData) {
            preferredPreSleepAudio = preSleepAudio
        }
        
        if let sleepData = userDefaults.data(forKey: Keys.preferredSleepAudio),
           let sleepAudio = try? JSONDecoder().decode(SleepAudioType.self, from: sleepData) {
            preferredSleepAudio = sleepAudio
        }
    }
    
    // MARK: - Public Methods
    
    func resetToDefaults() {
        logger.info("Resetting configuration to defaults", log: logger)
        
        isFirstLaunch = true
        hasCompletedOnboarding = false
        hasGrantedHealthKitPermissions = false
        hasGrantedNotificationPermissions = false
        hasGrantedMicrophonePermissions = false
        
        sleepGoal = 28800
        preferredWakeTime = Calendar.current.date(from: DateComponents(hour: 7, minute: 0)) ?? Date()
        preferredBedTime = Calendar.current.date(from: DateComponents(hour: 23, minute: 0)) ?? Date()
        preferredTrackingMode = .hybrid
        
        audioQuality = .high
        spatialAudioEnabled = true
        hapticFeedbackEnabled = true
        autoVolumeAdjustment = true
        smartFadingEnabled = true
        adaptiveMixingEnabled = true
        alarmVolume = 0.7
        fadeInDuration = 30
        fadeOutDuration = 60
        reverbLevel = 0.3
        eqPreset = .neutral
        
        preferredPreSleepAudio = .binauralBeats(frequency: 6.0)
        preferredSleepAudio = .deepSleep(frequency: 2.5)
        
        sleepReminderEnabled = true
        sleepReminderTime = Calendar.current.date(from: DateComponents(hour: 22, minute: 30)) ?? Date()
        wakeUpReminderEnabled = true
        wakeUpReminderTime = Calendar.current.date(from: DateComponents(hour: 6, minute: 30)) ?? Date()
        
        dataCollectionEnabled = true
        analyticsEnabled = false
        crashReportingEnabled = true
        dataRetentionDays = 365
        
        sleepInsightsEnabled = true
        weeklyReportEnabled = true
        achievementNotificationsEnabled = true
        soundNotificationsEnabled = true
        
        aiAnalysisEnabled = true
        personalizedRecommendationsEnabled = true
        sleepStagePredictionEnabled = true
        biometricMonitoringEnabled = true
        watchSyncEnabled = true
        
        logger.info("Configuration reset to defaults completed", log: logger)
    }
    
    func exportConfiguration() -> Data? {
        let config = ConfigurationExport(
            isFirstLaunch: isFirstLaunch,
            hasCompletedOnboarding: hasCompletedOnboarding,
            sleepGoal: sleepGoal,
            preferredWakeTime: preferredWakeTime,
            preferredBedTime: preferredBedTime,
            preferredTrackingMode: preferredTrackingMode,
            audioQuality: audioQuality,
            spatialAudioEnabled: spatialAudioEnabled,
            hapticFeedbackEnabled: hapticFeedbackEnabled,
            autoVolumeAdjustment: autoVolumeAdjustment,
            smartFadingEnabled: smartFadingEnabled,
            adaptiveMixingEnabled: adaptiveMixingEnabled,
            alarmVolume: alarmVolume,
            fadeInDuration: fadeInDuration,
            fadeOutDuration: fadeOutDuration,
            reverbLevel: reverbLevel,
            eqPreset: eqPreset,
            preferredPreSleepAudio: preferredPreSleepAudio,
            preferredSleepAudio: preferredSleepAudio,
            sleepReminderEnabled: sleepReminderEnabled,
            sleepReminderTime: sleepReminderTime,
            wakeUpReminderEnabled: wakeUpReminderEnabled,
            wakeUpReminderTime: wakeUpReminderTime,
            dataCollectionEnabled: dataCollectionEnabled,
            analyticsEnabled: analyticsEnabled,
            crashReportingEnabled: crashReportingEnabled,
            dataRetentionDays: dataRetentionDays,
            sleepInsightsEnabled: sleepInsightsEnabled,
            weeklyReportEnabled: weeklyReportEnabled,
            achievementNotificationsEnabled: achievementNotificationsEnabled,
            soundNotificationsEnabled: soundNotificationsEnabled,
            aiAnalysisEnabled: aiAnalysisEnabled,
            personalizedRecommendationsEnabled: personalizedRecommendationsEnabled,
            sleepStagePredictionEnabled: sleepStagePredictionEnabled,
            biometricMonitoringEnabled: biometricMonitoringEnabled,
            watchSyncEnabled: watchSyncEnabled
        )
        
        return try? JSONEncoder().encode(config)
    }
    
    func importConfiguration(from data: Data) -> Bool {
        guard let config = try? JSONDecoder().decode(ConfigurationExport.self, from: data) else {
            logger.error("Failed to decode configuration data", log: logger)
            return false
        }
        
        logger.info("Importing configuration", log: logger)
        
        isFirstLaunch = config.isFirstLaunch
        hasCompletedOnboarding = config.hasCompletedOnboarding
        sleepGoal = config.sleepGoal
        preferredWakeTime = config.preferredWakeTime
        preferredBedTime = config.preferredBedTime
        preferredTrackingMode = config.preferredTrackingMode
        audioQuality = config.audioQuality
        spatialAudioEnabled = config.spatialAudioEnabled
        hapticFeedbackEnabled = config.hapticFeedbackEnabled
        autoVolumeAdjustment = config.autoVolumeAdjustment
        smartFadingEnabled = config.smartFadingEnabled
        adaptiveMixingEnabled = config.adaptiveMixingEnabled
        alarmVolume = config.alarmVolume
        fadeInDuration = config.fadeInDuration
        fadeOutDuration = config.fadeOutDuration
        reverbLevel = config.reverbLevel
        eqPreset = config.eqPreset
        preferredPreSleepAudio = config.preferredPreSleepAudio
        preferredSleepAudio = config.preferredSleepAudio
        sleepReminderEnabled = config.sleepReminderEnabled
        sleepReminderTime = config.sleepReminderTime
        wakeUpReminderEnabled = config.wakeUpReminderEnabled
        wakeUpReminderTime = config.wakeUpReminderTime
        dataCollectionEnabled = config.dataCollectionEnabled
        analyticsEnabled = config.analyticsEnabled
        crashReportingEnabled = config.crashReportingEnabled
        dataRetentionDays = config.dataRetentionDays
        sleepInsightsEnabled = config.sleepInsightsEnabled
        weeklyReportEnabled = config.weeklyReportEnabled
        achievementNotificationsEnabled = config.achievementNotificationsEnabled
        soundNotificationsEnabled = config.soundNotificationsEnabled
        aiAnalysisEnabled = config.aiAnalysisEnabled
        personalizedRecommendationsEnabled = config.personalizedRecommendationsEnabled
        sleepStagePredictionEnabled = config.sleepStagePredictionEnabled
        biometricMonitoringEnabled = config.biometricMonitoringEnabled
        watchSyncEnabled = config.watchSyncEnabled
        
        logger.info("Configuration import completed", log: logger)
        return true
    }
}

// MARK: - Configuration Export Structure
struct ConfigurationExport: Codable {
    let isFirstLaunch: Bool
    let hasCompletedOnboarding: Bool
    let sleepGoal: TimeInterval
    let preferredWakeTime: Date
    let preferredBedTime: Date
    let preferredTrackingMode: TrackingMode
    let audioQuality: AudioQuality
    let spatialAudioEnabled: Bool
    let hapticFeedbackEnabled: Bool
    let autoVolumeAdjustment: Bool
    let smartFadingEnabled: Bool
    let adaptiveMixingEnabled: Bool
    let alarmVolume: Float
    let fadeInDuration: TimeInterval
    let fadeOutDuration: TimeInterval
    let reverbLevel: Float
    let eqPreset: EQPreset
    let preferredPreSleepAudio: PreSleepAudioType
    let preferredSleepAudio: SleepAudioType
    let sleepReminderEnabled: Bool
    let sleepReminderTime: Date
    let wakeUpReminderEnabled: Bool
    let wakeUpReminderTime: Date
    let dataCollectionEnabled: Bool
    let analyticsEnabled: Bool
    let crashReportingEnabled: Bool
    let dataRetentionDays: Int
    let sleepInsightsEnabled: Bool
    let weeklyReportEnabled: Bool
    let achievementNotificationsEnabled: Bool
    let soundNotificationsEnabled: Bool
    let aiAnalysisEnabled: Bool
    let personalizedRecommendationsEnabled: Bool
    let sleepStagePredictionEnabled: Bool
    let biometricMonitoringEnabled: Bool
    let watchSyncEnabled: Bool
}

/// AppConfiguration - Centralized configuration for SomnaSync Pro
/// This replaces the Info.plist file with Swift-based configuration
struct AppConfiguration {
    
    // MARK: - App Information
    static let appName = "SomnaSync Pro"
    static let bundleIdentifier = "com.somnasync.pro"
    static let version = "1.0.0"
    static let buildNumber = "1"
    static let minimumOSVersion = "15.0"
    
    // MARK: - Apple Watch Configuration
    static let companionAppBundleId = "com.somnasync.pro.watchapp"
    static let watchAppRequired = false
    static let watchConnectivityRequired = false
    static let supportsBackgroundRefresh = true
    static let supportsComplications = true
    
    // MARK: - Privacy Permission Descriptions
    struct PrivacyDescriptions {
        static let healthShare = "SomnaSync Pro needs access to your sleep data, heart rate, and respiratory information to provide personalized sleep optimization, intelligent sleep stage analysis, and advanced biometric monitoring for revolutionary sleep enhancement."
        
        static let healthUpdate = "SomnaSync Pro needs to write sleep session data to track your sleep improvements, log AI-enhanced sleep cycles, and maintain comprehensive sleep analytics for optimal sleep architecture optimization."
        
        static let camera = "SomnaSync Pro uses the camera for advanced sleep position tracking, breathing pattern analysis during sleep, and AI-powered sleep posture optimization to enhance sleep quality and reduce sleep disruptions."
        
        static let microphone = "SomnaSync Pro uses the microphone to monitor ambient noise levels for intelligent volume optimization, sleep environment analysis, and to automatically adjust AirPlay music volume for optimal sleep acoustics."
        
        static let location = "SomnaSync Pro uses your location to optimize sleep timing based on your timezone, predict jet lag effects, and provide circadian rhythm adjustments for travel and shift work sleep optimization."
        
        static let motion = "SomnaSync Pro tracks movement patterns during sleep for comprehensive sleep stage analysis, sleep position monitoring, and AI-driven sleep quality assessment to optimize your sleep architecture."
        
        static let bluetooth = "SomnaSync Pro connects to Apple Watch for real-time biometric monitoring, AirPods for spatial audio optimization, and other Bluetooth devices for comprehensive sleep environment control and biometric data collection."
        
        static let appleWatch = "SomnaSync Pro uses Apple Watch for advanced sleep tracking with heart rate, blood oxygen, and movement data to provide medical-grade sleep stage analysis and personalized sleep insights."
    }
    
    // MARK: - Background Task Identifiers
    struct BackgroundTasks {
        static let sleepAnalysis = "com.somnasync.pro.sleepanalysis"
        static let biometricProcessing = "com.somnasync.pro.biometricprocessing"
        static let aiOptimization = "com.somnasync.pro.aioptimization"
        static let watchDataSync = "com.somnasync.pro.watchsync"
    }
    
    // MARK: - URL Schemes
    struct URLSchemes {
        static let primary = "somnasync"
        static let secondary = "somnasyncpro"
    }
    
    // MARK: - Associated Domains
    struct AssociatedDomains {
        static let primary = "applinks:somnasync.pro"
        static let secondary = "applinks:www.somnasync.pro"
    }
    
    // MARK: - Sleep Tracking Modes
    enum SleepTrackingMode {
        case iphoneOnly
        case appleWatch
        case hybrid
        
        var description: String {
            switch self {
            case .iphoneOnly:
                return "iPhone sensors only - Basic sleep tracking"
            case .appleWatch:
                return "Apple Watch - Medical-grade sleep analysis"
            case .hybrid:
                return "iPhone + Apple Watch - Comprehensive tracking"
            }
        }
        
        var accuracy: String {
            switch self {
            case .iphoneOnly:
                return "Good"
            case .appleWatch:
                return "Excellent"
            case .hybrid:
                return "Outstanding"
            }
        }
    }
}

/// Logger - Centralized logging system for SomnaSync Pro
struct Logger {
    static let subsystem = "com.somnasync.pro"
    
    static let healthKit = OSLog(subsystem: subsystem, category: "HealthKit")
    static let sleepTracking = OSLog(subsystem: subsystem, category: "SleepTracking")
    static let aiEngine = OSLog(subsystem: subsystem, category: "AIEngine")
    static let appleWatch = OSLog(subsystem: subsystem, category: "AppleWatch")
    static let backgroundTasks = OSLog(subsystem: subsystem, category: "BackgroundTasks")
    static let permissions = OSLog(subsystem: subsystem, category: "Permissions")
    static let dataManager = OSLog(subsystem: subsystem, category: "DataManager")
    static let smartAlarm = OSLog(subsystem: subsystem, category: "SmartAlarm")
    static let audioEngine = OSLog(subsystem: subsystem, category: "AudioEngine")
    static let watchManager = OSLog(subsystem: subsystem, category: "WatchManager")
    
    static func log(_ message: String, type: OSLogType = .default, log: OSLog) {
        os_log("%{public}@", log: log, type: type, message)
    }
    
    static func error(_ message: String, log: OSLog) {
        os_log("❌ %{public}@", log: log, type: .error, message)
    }
    
    static func success(_ message: String, log: OSLog) {
        os_log("✅ %{public}@", log: log, type: .info, message)
    }
    
    static func info(_ message: String, log: OSLog) {
        os_log("ℹ️ %{public}@", log: log, type: .info, message)
    }
    
    static func debug(_ message: String, log: OSLog) {
        os_log("🔍 %{public}@", log: log, type: .debug, message)
    }
}

/// PermissionManager - Handles permission requests and status
class PermissionManager: ObservableObject {
    static let shared = PermissionManager()
    
    @Published var healthKitAuthorized = false
    @Published var cameraAuthorized = false
    @Published var microphoneAuthorized = false
    @Published var locationAuthorized = false
    @Published var motionAuthorized = false
    @Published var bluetoothAuthorized = false
    
    private init() {}
    
    // MARK: - HealthKit Permission
    func requestHealthKitPermissions() async -> Bool {
        guard HKHealthStore.isHealthDataAvailable() else {
            Logger.error("HealthKit is not available on this device", log: Logger.permissions)
            return false
        }
        
        let healthStore = HKHealthStore()
        let typesToRead: Set<HKObjectType> = [
            HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!,
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!,
            HKObjectType.quantityType(forIdentifier: .oxygenSaturation)!,
            HKObjectType.quantityType(forIdentifier: .respiratoryRate)!,
            HKObjectType.quantityType(forIdentifier: .bodyTemperature)!,
            HKObjectType.quantityType(forIdentifier: .stepCount)!
        ]
        
        let typesToWrite: Set<HKSampleType> = [
            HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
        ]
        
        do {
            try await healthStore.requestAuthorization(toShare: typesToWrite, read: typesToRead)
            await MainActor.run {
                self.healthKitAuthorized = true
            }
            Logger.success("HealthKit permissions granted", log: Logger.permissions)
            return true
        } catch {
            Logger.error("HealthKit authorization failed: \(error.localizedDescription)", log: Logger.permissions)
            return false
        }
    }
    
    // MARK: - Camera Permission
    func requestCameraPermission() async -> Bool {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch status {
        case .authorized:
            await MainActor.run {
                self.cameraAuthorized = true
            }
            return true
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            await MainActor.run {
                self.cameraAuthorized = granted
            }
            return granted
        case .denied, .restricted:
            return false
        @unknown default:
            return false
        }
    }
    
    // MARK: - Microphone Permission
    func requestMicrophonePermission() async -> Bool {
        let status = AVCaptureDevice.authorizationStatus(for: .audio)
        
        switch status {
        case .authorized:
            await MainActor.run {
                self.microphoneAuthorized = true
            }
            return true
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .audio)
            await MainActor.run {
                self.microphoneAuthorized = granted
            }
            return granted
        case .denied, .restricted:
            return false
        @unknown default:
            return false
        }
    }
    
    // MARK: - Location Permission
    func requestLocationPermission() async -> Bool {
        let locationManager = CLLocationManager()
        
        return await withCheckedContinuation { continuation in
            locationManager.requestWhenInUseAuthorization()
            
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                let status = locationManager.authorizationStatus
                self.locationAuthorized = status == .authorizedWhenInUse || status == .authorizedAlways
                continuation.resume(returning: self.locationAuthorized)
            }
        }
    }
    
    // MARK: - Motion Permission
    func requestMotionPermission() async -> Bool {
        let motionManager = CMMotionActivityManager()
        
        return await withCheckedContinuation { continuation in
            motionManager.queryActivityStarting(from: Date(), to: Date(), to: .main) { activities, error in
                if error == nil {
                    self.motionAuthorized = true
                } else {
                    self.motionAuthorized = false
                }
                continuation.resume(returning: self.motionAuthorized)
            }
        }
    }
    
    // MARK: - Request All Permissions
    func requestAllPermissions() async {
        async let healthKit = requestHealthKitPermissions()
        async let camera = requestCameraPermission()
        async let microphone = requestMicrophonePermission()
        async let location = requestLocationPermission()
        async let motion = requestMotionPermission()
        
        _ = await (healthKit, camera, microphone, location, motion)
    }
}

/// BackgroundTaskManager - Handles background processing
class BackgroundTaskManager {
    static let shared = BackgroundTaskManager()
    
    private init() {}
    
    func registerBackgroundTasks() {
        // Register background tasks for iOS 13+
        if #available(iOS 13.0, *) {
            BGTaskScheduler.shared.register(forTaskWithIdentifier: AppConfiguration.BackgroundTasks.sleepAnalysis, using: nil) { task in
                self.handleSleepAnalysisTask(task as! BGProcessingTask)
            }
            
            BGTaskScheduler.shared.register(forTaskWithIdentifier: AppConfiguration.BackgroundTasks.biometricProcessing, using: nil) { task in
                self.handleBiometricProcessingTask(task as! BGProcessingTask)
            }
            
            BGTaskScheduler.shared.register(forTaskWithIdentifier: AppConfiguration.BackgroundTasks.aiOptimization, using: nil) { task in
                self.handleAIOptimizationTask(task as! BGProcessingTask)
            }
        }
    }
    
    @available(iOS 13.0, *)
    private func handleSleepAnalysisTask(_ task: BGProcessingTask) {
        // Schedule the next execution
        scheduleSleepAnalysisTask()
        
        // Perform sleep analysis
        task.expirationHandler = {
            // Handle task expiration
        }
        
        // Complete the task
        task.setTaskCompleted(success: true)
    }
    
    @available(iOS 13.0, *)
    private func handleBiometricProcessingTask(_ task: BGProcessingTask) {
        scheduleBiometricProcessingTask()
        
        task.expirationHandler = {
            // Handle task expiration
        }
        
        task.setTaskCompleted(success: true)
    }
    
    @available(iOS 13.0, *)
    private func handleAIOptimizationTask(_ task: BGProcessingTask) {
        scheduleAIOptimizationTask()
        
        task.expirationHandler = {
            // Handle task expiration
        }
        
        task.setTaskCompleted(success: true)
    }
    
    @available(iOS 13.0, *)
    func scheduleSleepAnalysisTask() {
        let request = BGProcessingTaskRequest(identifier: AppConfiguration.BackgroundTasks.sleepAnalysis)
        request.requiresNetworkConnectivity = false
        request.requiresExternalPower = false
        
        do {
            try BGTaskScheduler.shared.submit(request)
            Logger.info("Sleep analysis background task scheduled", log: Logger.backgroundTasks)
        } catch {
            Logger.error("Could not schedule sleep analysis task: \(error.localizedDescription)", log: Logger.backgroundTasks)
        }
    }
    
    @available(iOS 13.0, *)
    func scheduleBiometricProcessingTask() {
        let request = BGProcessingTaskRequest(identifier: AppConfiguration.BackgroundTasks.biometricProcessing)
        request.requiresNetworkConnectivity = false
        request.requiresExternalPower = false
        
        do {
            try BGTaskScheduler.shared.submit(request)
            Logger.info("Biometric processing background task scheduled", log: Logger.backgroundTasks)
        } catch {
            Logger.error("Could not schedule biometric processing task: \(error.localizedDescription)", log: Logger.backgroundTasks)
        }
    }
    
    @available(iOS 13.0, *)
    func scheduleAIOptimizationTask() {
        let request = BGProcessingTaskRequest(identifier: AppConfiguration.BackgroundTasks.aiOptimization)
        request.requiresNetworkConnectivity = true
        request.requiresExternalPower = false
        
        do {
            try BGTaskScheduler.shared.submit(request)
            Logger.info("AI optimization background task scheduled", log: Logger.backgroundTasks)
        } catch {
            Logger.error("Could not schedule AI optimization task: \(error.localizedDescription)", log: Logger.backgroundTasks)
        }
    }
} 
import Foundation
import AppIntents
import HealthKit
import UserNotifications

@available(iOS 18.0, *)
struct HealthFocusModeIntent: AppIntent {
    static var title: LocalizedStringResource = "Health Focus Mode"
    static var description = IntentDescription("Activate health-aware focus modes that adapt based on your current health status and activities")
    
    @Parameter(title: "Focus Mode", description: "Choose the health focus mode to activate")
    var focusMode: HealthFocusMode
    
    @Parameter(title: "Health Context", description: "Current health context for personalized filtering", defaultValue: true)
    var useHealthContext: Bool
    
    @Parameter(title: "Duration", description: "How long to maintain this focus mode")
    var duration: FocusDuration?
    
    static var parameterSummary: some ParameterSummary {
        Summary("Activate \(\.$focusMode) focus mode") {
            \.$useHealthContext
            \.$duration
        }
    }
    
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let focusModeManager = FocusModeHealthManager.shared
        
        // Get current health context
        let healthContext = useHealthContext ? await getCurrentHealthContext() : nil
        
        // Activate the focus mode with health-aware settings
        let success = await focusModeManager.activateFocusMode(
            mode: focusMode,
            healthContext: healthContext,
            duration: duration
        )
        
        if success {
            let dialog = generateActivationDialog(mode: focusMode, context: healthContext)
            return .result(dialog: dialog) {
                FocusModeActivationResult(
                    mode: focusMode,
                    activated: true,
                    healthContextApplied: useHealthContext,
                    duration: duration
                )
            }
        } else {
            return .result(dialog: "I couldn't activate \(focusMode.displayName) focus mode right now. Please try again.") {
                FocusModeActivationResult(
                    mode: focusMode,
                    activated: false,
                    healthContextApplied: false,
                    duration: nil
                )
            }
        }
    }
    
    private func getCurrentHealthContext() async -> HealthFocusContext {
        let healthManager = HealthDataManager.shared
        
        let heartRate = await healthManager.getLatestHeartRate()
        let currentActivity = await healthManager.getCurrentActivity()
        let stressLevel = await healthManager.getCurrentStressLevel()
        let timeOfDay = Calendar.current.component(.hour, from: Date())
        
        return HealthFocusContext(
            heartRate: heartRate,
            currentActivity: currentActivity,
            stressLevel: stressLevel,
            timeOfDay: timeOfDay,
            date: Date()
        )
    }
    
    private func generateActivationDialog(mode: HealthFocusMode, context: HealthFocusContext?) -> String {
        var dialog = "\(mode.displayName) focus mode is now active"
        
        if let context = context {
            switch mode {
            case .workoutMode:
                if let heartRate = context.heartRate {
                    dialog += " with heart rate monitoring at \(Int(heartRate)) BPM"
                }
            case .sleepMode:
                dialog += " to help you prepare for restful sleep"
            case .meditationMode:
                if let stress = context.stressLevel {
                    let stressDescription = stress > 0.7 ? "elevated stress" : stress > 0.4 ? "moderate stress" : "low stress"
                    dialog += " to help manage your current \(stressDescription) levels"
                }
            case .recoveryMode:
                dialog += " to support your recovery and healing"
            case .healthMonitoring:
                dialog += " with enhanced health tracking and gentle reminders"
            }
        }
        
        dialog += ". Your notifications and app access have been filtered to support your current health needs."
        
        return dialog
    }
}

// MARK: - Focus Mode Manager

@available(iOS 18.0, *)
class FocusModeHealthManager: ObservableObject {
    static let shared = FocusModeHealthManager()
    
    @Published var activeFocusMode: HealthFocusMode?
    @Published var healthRules: [HealthFocusRule] = []
    @Published var focusAnalytics: FocusModeAnalytics = FocusModeAnalytics()
    
    private let healthRulesManager = FocusModeHealthRules()
    private let preferencesManager = FocusModeHealthPreferences()
    private let schedulerManager = FocusModeHealthScheduler()
    private let analyticsManager = FocusModeHealthAnalytics()
    
    private init() {
        setupDefaultRules()
        startHealthMonitoring()
    }
    
    // MARK: - Focus Mode Activation
    
    func activateFocusMode(
        mode: HealthFocusMode,
        healthContext: HealthFocusContext?,
        duration: FocusDuration?
    ) async -> Bool {
        
        // Deactivate current focus mode if active
        if let currentMode = activeFocusMode {
            await deactivateFocusMode(currentMode)
        }
        
        // Generate health-aware rules for this focus mode
        let rules = await healthRulesManager.generateRules(
            for: mode,
            context: healthContext,
            preferences: preferencesManager.getUserPreferences()
        )
        
        // Apply the focus mode configuration
        let success = await applyFocusModeConfiguration(
            mode: mode,
            rules: rules,
            duration: duration
        )
        
        if success {
            DispatchQueue.main.async {
                self.activeFocusMode = mode
                self.healthRules = rules
            }
            
            // Schedule automatic deactivation if duration is set
            if let duration = duration {
                await schedulerManager.scheduleDeactivation(mode: mode, after: duration)
            }
            
            // Track analytics
            await analyticsManager.trackFocusModeActivation(
                mode: mode,
                context: healthContext,
                rules: rules
            )
            
            return true
        }
        
        return false
    }
    
    func deactivateFocusMode(_ mode: HealthFocusMode) async {
        // Remove focus mode restrictions
        await removeFocusModeConfiguration(mode)
        
        // Track deactivation
        await analyticsManager.trackFocusModeDeactivation(mode: mode)
        
        DispatchQueue.main.async {
            self.activeFocusMode = nil
            self.healthRules = []
        }
    }
    
    // MARK: - Configuration Application
    
    private func applyFocusModeConfiguration(
        mode: HealthFocusMode,
        rules: [HealthFocusRule],
        duration: FocusDuration?
    ) async -> Bool {
        
        do {
            // Configure notification filtering
            try await configureNotificationFiltering(for: mode, rules: rules)
            
            // Configure app access restrictions
            try await configureAppRestrictions(for: mode, rules: rules)
            
            // Configure health data collection preferences
            try await configureHealthDataCollection(for: mode, rules: rules)
            
            // Configure UI adaptations
            try await configureUIAdaptations(for: mode, rules: rules)
            
            return true
            
        } catch {
            print("❌ Failed to apply focus mode configuration: \(error)")
            return false
        }
    }
    
    private func configureNotificationFiltering(for mode: HealthFocusMode, rules: [HealthFocusRule]) async throws {
        let notificationCenter = UNUserNotificationCenter.current()
        
        // Get notification filtering rules for this focus mode
        let filteringRules = rules.compactMap { rule -> NotificationFilterRule? in
            switch rule {
            case .allowCriticalHealthAlerts:
                return NotificationFilterRule(
                    category: .healthCritical,
                    action: .allow,
                    priority: .high
                )
            case .blockNonEssentialNotifications:
                return NotificationFilterRule(
                    category: .nonEssential,
                    action: .block,
                    priority: .low
                )
            case .limitSocialNotifications:
                return NotificationFilterRule(
                    category: .social,
                    action: .limit,
                    priority: .low
                )
            default:
                return nil
            }
        }
        
        // Apply filtering rules (this would integrate with actual notification management)
        for rule in filteringRules {
            await applyNotificationFilterRule(rule)
        }
    }
    
    private func configureAppRestrictions(for mode: HealthFocusMode, rules: [HealthFocusRule]) async throws {
        // Configure app access restrictions based on focus mode
        let appRestrictions = rules.compactMap { rule -> AppRestriction? in
            switch rule {
            case .prioritizeHealthApps:
                return AppRestriction(
                    category: .health,
                    access: .prioritized
                )
            case .limitSocialMediaAccess:
                return AppRestriction(
                    category: .socialMedia,
                    access: .limited
                )
            case .allowFitnessApps:
                return AppRestriction(
                    category: .fitness,
                    access: .allowed
                )
            default:
                return nil
            }
        }
        
        // Apply app restrictions (this would integrate with Screen Time APIs)
        for restriction in appRestrictions {
            await applyAppRestriction(restriction)
        }
    }
    
    private func configureHealthDataCollection(for mode: HealthFocusMode, rules: [HealthFocusRule]) async throws {
        // Adjust health data collection frequency and types based on focus mode
        let collectionRules = rules.compactMap { rule -> HealthDataCollectionRule? in
            switch rule {
            case .enhancedHeartRateMonitoring:
                return HealthDataCollectionRule(
                    dataType: .heartRate,
                    frequency: .continuous,
                    sensitivity: .high
                )
            case .reducedDataCollection:
                return HealthDataCollectionRule(
                    dataType: .general,
                    frequency: .reduced,
                    sensitivity: .low
                )
            case .stressMonitoring:
                return HealthDataCollectionRule(
                    dataType: .stress,
                    frequency: .frequent,
                    sensitivity: .medium
                )
            default:
                return nil
            }
        }
        
        // Apply health data collection rules
        for rule in collectionRules {
            await applyHealthDataCollectionRule(rule)
        }
    }
    
    private func configureUIAdaptations(for mode: HealthFocusMode, rules: [HealthFocusRule]) async throws {
        // Configure UI adaptations for focus mode
        let uiAdaptations = rules.compactMap { rule -> UIAdaptation? in
            switch rule {
            case .dimDisplayBrightness:
                return UIAdaptation(
                    type: .brightness,
                    value: 0.3 // 30% brightness
                )
            case .reduceAnimations:
                return UIAdaptation(
                    type: .animations,
                    value: 0.5 // Reduced animations
                )
            case .simplifyInterface:
                return UIAdaptation(
                    type: .complexity,
                    value: 0.2 // Simplified interface
                )
            default:
                return nil
            }
        }
        
        // Apply UI adaptations
        for adaptation in uiAdaptations {
            await applyUIAdaptation(adaptation)
        }
    }
    
    private func removeFocusModeConfiguration(_ mode: HealthFocusMode) async {
        // Remove all focus mode configurations
        await removeNotificationFiltering()
        await removeAppRestrictions()
        await resetHealthDataCollection()
        await resetUIAdaptations()
    }
    
    // MARK: - Health Monitoring
    
    private func startHealthMonitoring() {
        // Start monitoring health changes that might trigger automatic focus mode adjustments
        Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { _ in
            Task {
                await self.checkForAutomaticFocusAdjustments()
            }
        }
    }
    
    private func checkForAutomaticFocusAdjustments() async {
        guard let activeMode = activeFocusMode else { return }
        
        let currentContext = await getCurrentHealthContext()
        let shouldAdjust = await healthRulesManager.shouldAdjustFocusMode(
            currentMode: activeMode,
            context: currentContext
        )
        
        if shouldAdjust {
            // Automatically adjust focus mode based on health changes
            await adjustFocusModeForHealthContext(currentContext)
        }
    }
    
    private func adjustFocusModeForHealthContext(_ context: HealthFocusContext) async {
        guard let activeMode = activeFocusMode else { return }
        
        // Generate updated rules based on current health context
        let updatedRules = await healthRulesManager.generateRules(
            for: activeMode,
            context: context,
            preferences: preferencesManager.getUserPreferences()
        )
        
        // Apply updated configuration
        let success = await applyFocusModeConfiguration(
            mode: activeMode,
            rules: updatedRules,
            duration: nil
        )
        
        if success {
            DispatchQueue.main.async {
                self.healthRules = updatedRules
            }
            
            // Track adjustment
            await analyticsManager.trackFocusModeAdjustment(
                mode: activeMode,
                context: context,
                newRules: updatedRules
            )
        }
    }
    
    // MARK: - Helper Methods
    
    private func getCurrentHealthContext() async -> HealthFocusContext {
        let healthManager = HealthDataManager.shared
        
        let heartRate = await healthManager.getLatestHeartRate()
        let currentActivity = await healthManager.getCurrentActivity()
        let stressLevel = await healthManager.getCurrentStressLevel()
        let timeOfDay = Calendar.current.component(.hour, from: Date())
        
        return HealthFocusContext(
            heartRate: heartRate,
            currentActivity: currentActivity,
            stressLevel: stressLevel,
            timeOfDay: timeOfDay,
            date: Date()
        )
    }
    
    private func setupDefaultRules() {
        // Setup default health-aware focus rules
        healthRules = [
            .allowCriticalHealthAlerts,
            .prioritizeHealthApps,
            .intelligentNotificationTiming
        ]
    }
    
    // MARK: - Mock Implementation Methods
    
    private func applyNotificationFilterRule(_ rule: NotificationFilterRule) async {
        // Mock implementation - would integrate with actual notification system
        print("📱 Applied notification filter rule: \(rule.category) - \(rule.action)")
    }
    
    private func applyAppRestriction(_ restriction: AppRestriction) async {
        // Mock implementation - would integrate with Screen Time APIs
        print("📱 Applied app restriction: \(restriction.category) - \(restriction.access)")
    }
    
    private func applyHealthDataCollectionRule(_ rule: HealthDataCollectionRule) async {
        // Mock implementation - would adjust actual HealthKit collection
        print("📊 Applied health data collection rule: \(rule.dataType) - \(rule.frequency)")
    }
    
    private func applyUIAdaptation(_ adaptation: UIAdaptation) async {
        // Mock implementation - would apply actual UI changes
        print("🎨 Applied UI adaptation: \(adaptation.type) - \(adaptation.value)")
    }
    
    private func removeNotificationFiltering() async {
        print("📱 Removed notification filtering")
    }
    
    private func removeAppRestrictions() async {
        print("📱 Removed app restrictions")
    }
    
    private func resetHealthDataCollection() async {
        print("📊 Reset health data collection to normal")
    }
    
    private func resetUIAdaptations() async {
        print("🎨 Reset UI adaptations to default")
    }
}

// MARK: - Supporting Data Structures

enum HealthFocusMode: String, AppEnum {
    case workoutMode = "Workout Mode"
    case sleepMode = "Sleep Mode"
    case meditationMode = "Meditation Mode"
    case recoveryMode = "Recovery Mode"
    case healthMonitoring = "Health Monitoring"
    
    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Health Focus Mode")
    static var caseDisplayRepresentations: [HealthFocusMode: DisplayRepresentation] = [
        .workoutMode: DisplayRepresentation(title: "Workout Mode", subtitle: "Optimized for exercise and fitness tracking"),
        .sleepMode: DisplayRepresentation(title: "Sleep Mode", subtitle: "Minimizes disruptions for better sleep"),
        .meditationMode: DisplayRepresentation(title: "Meditation Mode", subtitle: "Reduces distractions for mindfulness"),
        .recoveryMode: DisplayRepresentation(title: "Recovery Mode", subtitle: "Supports healing and rest"),
        .healthMonitoring: DisplayRepresentation(title: "Health Monitoring", subtitle: "Enhanced health tracking and alerts")
    ]
    
    var displayName: String {
        return self.rawValue
    }
}

enum FocusDuration: String, AppEnum {
    case fifteenMinutes = "15 minutes"
    case thirtyMinutes = "30 minutes"
    case oneHour = "1 hour"
    case twoHours = "2 hours"
    case untilEndOfDay = "Until end of day"
    case indefinite = "Indefinite"
    
    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Duration")
    static var caseDisplayRepresentations: [FocusDuration: DisplayRepresentation] = [
        .fifteenMinutes: "15 minutes",
        .thirtyMinutes: "30 minutes",
        .oneHour: "1 hour",
        .twoHours: "2 hours",
        .untilEndOfDay: "Until end of day",
        .indefinite: "Indefinite"
    ]
    
    var timeInterval: TimeInterval? {
        switch self {
        case .fifteenMinutes: return 15 * 60
        case .thirtyMinutes: return 30 * 60
        case .oneHour: return 60 * 60
        case .twoHours: return 2 * 60 * 60
        case .untilEndOfDay:
            let calendar = Calendar.current
            let now = Date()
            if let endOfDay = calendar.dateInterval(of: .day, for: now)?.end {
                return endOfDay.timeIntervalSince(now)
            }
            return nil
        case .indefinite: return nil
        }
    }
}

struct HealthFocusContext {
    let heartRate: Double?
    let currentActivity: String?
    let stressLevel: Double?
    let timeOfDay: Int
    let date: Date
}

struct FocusModeActivationResult {
    let mode: HealthFocusMode
    let activated: Bool
    let healthContextApplied: Bool
    let duration: FocusDuration?
}

enum HealthFocusRule {
    case allowCriticalHealthAlerts
    case blockNonEssentialNotifications
    case limitSocialNotifications
    case prioritizeHealthApps
    case limitSocialMediaAccess
    case allowFitnessApps
    case enhancedHeartRateMonitoring
    case reducedDataCollection
    case stressMonitoring
    case dimDisplayBrightness
    case reduceAnimations
    case simplifyInterface
    case intelligentNotificationTiming
}

struct NotificationFilterRule {
    let category: NotificationCategory
    let action: FilterAction
    let priority: Priority
}

enum NotificationCategory {
    case healthCritical
    case nonEssential
    case social
    case fitness
}

enum FilterAction {
    case allow
    case block
    case limit
}

enum Priority {
    case low
    case medium
    case high
}

struct AppRestriction {
    let category: AppCategory
    let access: AccessLevel
}

enum AppCategory {
    case health
    case socialMedia
    case fitness
    case productivity
}

enum AccessLevel {
    case allowed
    case limited
    case blocked
    case prioritized
}

struct HealthDataCollectionRule {
    let dataType: HealthDataCollectionType
    let frequency: CollectionFrequency
    let sensitivity: SensitivityLevel
}

enum HealthDataCollectionType {
    case heartRate
    case stress
    case activity
    case general
}

enum CollectionFrequency {
    case continuous
    case frequent
    case normal
    case reduced
}

enum SensitivityLevel {
    case low
    case medium
    case high
}

struct UIAdaptation {
    let type: UIAdaptationType
    let value: Double
}

enum UIAdaptationType {
    case brightness
    case animations
    case complexity
}

struct FocusModeAnalytics {
    var activationCount: Int = 0
    var totalActiveTime: TimeInterval = 0
    var effectivenessRating: Double = 0.0
    var lastActivated: Date?
}

// MARK: - Helper Classes (Mock Implementations)

class FocusModeHealthRules {
    func generateRules(for mode: HealthFocusMode, context: HealthFocusContext?, preferences: FocusModePreferences) async -> [HealthFocusRule] {
        var rules: [HealthFocusRule] = []
        
        // Base rules for all modes
        rules.append(.allowCriticalHealthAlerts)
        rules.append(.intelligentNotificationTiming)
        
        // Mode-specific rules
        switch mode {
        case .workoutMode:
            rules.append(.enhancedHeartRateMonitoring)
            rules.append(.allowFitnessApps)
            rules.append(.blockNonEssentialNotifications)
            
        case .sleepMode:
            rules.append(.blockNonEssentialNotifications)
            rules.append(.limitSocialNotifications)
            rules.append(.dimDisplayBrightness)
            rules.append(.reduceAnimations)
            
        case .meditationMode:
            rules.append(.blockNonEssentialNotifications)
            rules.append(.limitSocialMediaAccess)
            rules.append(.stressMonitoring)
            rules.append(.simplifyInterface)
            
        case .recoveryMode:
            rules.append(.reducedDataCollection)
            rules.append(.limitSocialNotifications)
            rules.append(.prioritizeHealthApps)
            
        case .healthMonitoring:
            rules.append(.enhancedHeartRateMonitoring)
            rules.append(.stressMonitoring)
            rules.append(.prioritizeHealthApps)
        }
        
        // Context-based adjustments
        if let context = context {
            if let heartRate = context.heartRate, heartRate > 100 {
                rules.append(.enhancedHeartRateMonitoring)
            }
            
            if let stress = context.stressLevel, stress > 0.7 {
                rules.append(.limitSocialMediaAccess)
                rules.append(.stressMonitoring)
            }
            
            if context.timeOfDay >= 22 || context.timeOfDay <= 6 {
                rules.append(.dimDisplayBrightness)
            }
        }
        
        return rules
    }
    
    func shouldAdjustFocusMode(currentMode: HealthFocusMode, context: HealthFocusContext) async -> Bool {
        // Simple logic to determine if focus mode should be adjusted
        if let heartRate = context.heartRate {
            switch currentMode {
            case .workoutMode:
                return heartRate < 60 // Workout ended
            case .sleepMode:
                return heartRate > 80 && context.timeOfDay < 22 // Too active for sleep
            default:
                return false
            }
        }
        return false
    }
}

class FocusModeHealthPreferences {
    func getUserPreferences() -> FocusModePreferences {
        return FocusModePreferences(
            allowCriticalAlerts: true,
            notificationSensitivity: .medium,
            dataCollectionLevel: .standard
        )
    }
}

class FocusModeHealthScheduler {
    func scheduleDeactivation(mode: HealthFocusMode, after duration: FocusDuration) async {
        guard let timeInterval = duration.timeInterval else { return }
        
        Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: false) { _ in
            Task {
                await FocusModeHealthManager.shared.deactivateFocusMode(mode)
            }
        }
    }
}

class FocusModeHealthAnalytics {
    func trackFocusModeActivation(mode: HealthFocusMode, context: HealthFocusContext?, rules: [HealthFocusRule]) async {
        print("📈 Focus mode activated: \(mode) with \(rules.count) rules")
    }
    
    func trackFocusModeDeactivation(mode: HealthFocusMode) async {
        print("📈 Focus mode deactivated: \(mode)")
    }
    
    func trackFocusModeAdjustment(mode: HealthFocusMode, context: HealthFocusContext, newRules: [HealthFocusRule]) async {
        print("📈 Focus mode adjusted: \(mode) with \(newRules.count) new rules")
    }
}

struct FocusModePreferences {
    let allowCriticalAlerts: Bool
    let notificationSensitivity: SensitivityLevel
    let dataCollectionLevel: DataCollectionLevel
}

enum DataCollectionLevel {
    case minimal
    case standard
    case enhanced
}

// MARK: - Extensions for HealthDataManager

extension HealthDataManager {
    func getCurrentActivity() async -> String? {
        // Mock implementation
        let activities = ["Resting", "Walking", "Running", "Cycling", "Swimming"]
        return activities.randomElement()
    }
    
    func getCurrentStressLevel() async -> Double? {
        // Mock implementation
        return Double.random(in: 0.0...1.0)
    }
}
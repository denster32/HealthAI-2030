import Foundation
import Intents
import IntentsUI
import AppIntents
import OSLog
import Combine

// MARK: - Shortcuts Manager for iOS 18 Siri Integration

class ShortcutsManager: ObservableObject {
    
    // MARK: - Published Properties
    @Published var donatedShortcuts: [DonatedShortcut] = []
    @Published var frequentlyUsedShortcuts: [String] = []
    @Published var shortcutSuggestions: [ShortcutSuggestion] = []
    
    // MARK: - Private Properties
    private let logger = Logger(subsystem: "com.healthai2030.shortcuts", category: "manager")
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupShortcutDonation()
    }
    
    // MARK: - Initialization
    
    func initialize() async {
        logger.info("Initializing Shortcuts Manager")
        
        // Configure shortcut intents
        await configureShortcutIntents()
        
        // Setup voice shortcuts
        setupVoiceShortcuts()
        
        // Donate common intents
        await donateCommonIntents()
        
        // Setup predictive suggestions
        setupPredictiveSuggestions()
    }
    
    // MARK: - Intent Configuration
    
    private func configureShortcutIntents() async {
        logger.info("Configuring shortcut intents")
        
        // Register health-related intents
        await registerHealthIntents()
        
        // Register sleep-related intents
        await registerSleepIntents()
        
        // Register AI coaching intents
        await registerAICoachingIntents()
        
        // Register environment control intents
        await registerEnvironmentIntents()
        
        // Register emergency intents
        await registerEmergencyIntents()
    }
    
    private func registerHealthIntents() async {
        // Health data query intents
        INVoiceShortcutCenter.shared.setShortcutSuggestions([
            INShortcut(intent: GetHeartRateIntent()),
            INShortcut(intent: GetSleepQualityIntent()),
            INShortcut(intent: GetStepsIntent()),
            INShortcut(intent: LogWaterIntakeIntent()),
            INShortcut(intent: LogMoodIntent()),
            INShortcut(intent: LogWeightIntent())
        ])
    }
    
    private func registerSleepIntents() async {
        // Sleep tracking intents
        INVoiceShortcutCenter.shared.setShortcutSuggestions([
            INShortcut(intent: StartSleepTrackingIntent()),
            INShortcut(intent: StopSleepTrackingIntent()),
            INShortcut(intent: GetSleepAnalysisIntent()),
            INShortcut(intent: SetSleepGoalIntent()),
            INShortcut(intent: OptimizeEnvironmentIntent())
        ])
    }
    
    private func registerAICoachingIntents() async {
        // AI coaching intents
        INVoiceShortcutCenter.shared.setShortcutSuggestions([
            INShortcut(intent: GetDailyRecommendationIntent()),
            INShortcut(intent: StartCoachingSessionIntent()),
            INShortcut(intent: GetHealthInsightsIntent()),
            INShortcut(intent: AskHealthQuestionIntent()),
            INShortcut(intent: GetMotivationalMessageIntent())
        ])
    }
    
    private func registerEnvironmentIntents() async {
        // Environment control intents
        INVoiceShortcutCenter.shared.setShortcutSuggestions([
            INShortcut(intent: AdjustTemperatureIntent()),
            INShortcut(intent: ControlLightsIntent()),
            INShortcut(intent: StartSleepAudioIntent()),
            INShortcut(intent: OptimizeForSleepIntent()),
            INShortcut(intent: CreateRelaxingEnvironmentIntent())
        ])
    }
    
    private func registerEmergencyIntents() async {
        // Emergency and alert intents
        INVoiceShortcutCenter.shared.setShortcutSuggestions([
            INShortcut(intent: ContactEmergencyContactIntent()),
            INShortcut(intent: TriggerHealthAlertIntent()),
            INShortcut(intent: ShareHealthDataIntent()),
            INShortcut(intent: RequestMedicalAssistanceIntent())
        ])
    }
    
    // MARK: - Intent Donation
    
    func donateCommonIntents() async {
        logger.info("Donating common intents to Siri")
        
        // Donate sleep tracking intent
        await donateIntent(StartSleepTrackingIntent(), phrase: "Start tracking my sleep")
        
        // Donate health query intents
        await donateIntent(GetHeartRateIntent(), phrase: "What's my heart rate?")
        await donateIntent(GetSleepQualityIntent(), phrase: "How did I sleep last night?")
        await donateIntent(GetStepsIntent(), phrase: "How many steps have I taken today?")
        
        // Donate logging intents
        await donateIntent(LogWaterIntakeIntent(), phrase: "Log a glass of water")
        await donateIntent(LogMoodIntent(), phrase: "Log my mood")
        
        // Donate AI coaching intents
        await donateIntent(GetDailyRecommendationIntent(), phrase: "What's my daily health recommendation?")
        await donateIntent(StartCoachingSessionIntent(), phrase: "Start a coaching session")
        
        // Donate environment control intents
        await donateIntent(OptimizeForSleepIntent(), phrase: "Optimize my environment for sleep")
        await donateIntent(StartSleepAudioIntent(), phrase: "Play sleep sounds")
    }
    
    private func donateIntent<T: INIntent>(_ intent: T, phrase: String) async {
        let interaction = INInteraction(intent: intent, response: nil)
        interaction.direction = .outgoing
        interaction.donate { error in
            if let error = error {
                self.logger.error("Failed to donate intent: \(error)")
            } else {
                self.logger.debug("Successfully donated intent: \(phrase)")
            }
        }
        
        // Record donated shortcut
        let donatedShortcut = DonatedShortcut(
            phrase: phrase,
            intentType: String(describing: type(of: intent)),
            donationDate: Date(),
            usageCount: 0
        )
        
        await MainActor.run {
            self.donatedShortcuts.append(donatedShortcut)
        }
    }
    
    // MARK: - Voice Shortcuts
    
    private func setupVoiceShortcuts() {
        logger.info("Setting up voice shortcuts")
        
        // Configure voice shortcut availability
        INPreferences.requestSiriAuthorization { status in
            switch status {
            case .authorized:
                self.logger.info("Siri authorization granted")
                self.configurePredefinedShortcuts()
            case .denied, .restricted:
                self.logger.warning("Siri authorization denied or restricted")
            case .notDetermined:
                self.logger.info("Siri authorization not determined")
            @unknown default:
                self.logger.warning("Unknown Siri authorization status")
            }
        }
    }
    
    private func configurePredefinedShortcuts() {
        // Create predefined shortcuts for common actions
        let shortcuts = [
            createHealthSummaryShortcut(),
            createSleepTrackingShortcut(),
            createEmergencyShortcut(),
            createMeditationShortcut(),
            createEnvironmentShortcut()
        ]
        
        // Register shortcuts with the system
        for shortcut in shortcuts {
            addShortcut(shortcut)
        }
    }
    
    private func createHealthSummaryShortcut() -> INShortcut {
        let intent = GetHealthSummaryIntent()
        intent.suggestedInvocationPhrase = "Show my health summary"
        return INShortcut(intent: intent)
    }
    
    private func createSleepTrackingShortcut() -> INShortcut {
        let intent = StartSleepTrackingIntent()
        intent.suggestedInvocationPhrase = "Start sleep tracking"
        return INShortcut(intent: intent)
    }
    
    private func createEmergencyShortcut() -> INShortcut {
        let intent = ContactEmergencyContactIntent()
        intent.suggestedInvocationPhrase = "Contact my emergency contact"
        return INShortcut(intent: intent)
    }
    
    private func createMeditationShortcut() -> INShortcut {
        let intent = StartMeditationIntent()
        intent.suggestedInvocationPhrase = "Start meditation"
        return INShortcut(intent: intent)
    }
    
    private func createEnvironmentShortcut() -> INShortcut {
        let intent = OptimizeForSleepIntent()
        intent.suggestedInvocationPhrase = "Prepare my room for sleep"
        return INShortcut(intent: intent)
    }
    
    private func addShortcut(_ shortcut: INShortcut) {
        INVoiceShortcutCenter.shared.getAllVoiceShortcuts { shortcuts, error in
            if let error = error {
                self.logger.error("Error getting voice shortcuts: \(error)")
                return
            }
            
            // Check if shortcut already exists
            let existingShortcut = shortcuts?.first { existing in
                existing.shortcut.intent?.intentDescription == shortcut.intent?.intentDescription
            }
            
            if existingShortcut == nil {
                // Add new shortcut
                self.logger.debug("Adding new voice shortcut: \(shortcut.intent?.intentDescription ?? "Unknown")")
            }
        }
    }
    
    // MARK: - Predictive Suggestions
    
    private func setupPredictiveSuggestions() {
        logger.info("Setting up predictive suggestions")
        
        // Monitor user patterns for intelligent suggestions
        Timer.publish(every: 3600, on: .main, in: .common) // Every hour
            .autoconnect()
            .sink { [weak self] _ in
                Task {
                    await self?.updatePredictiveSuggestions()
                }
            }
            .store(in: &cancellables)
    }
    
    private func updatePredictiveSuggestions() async {
        let currentHour = Calendar.current.component(.hour, from: Date())
        var suggestions: [ShortcutSuggestion] = []
        
        // Time-based suggestions
        switch currentHour {
        case 6...9: // Morning
            suggestions.append(contentsOf: getMorningSuggestions())
        case 10...17: // Day
            suggestions.append(contentsOf: getDaySuggestions())
        case 18...21: // Evening
            suggestions.append(contentsOf: getEveningSuggestions())
        case 22...23, 0...5: // Night
            suggestions.append(contentsOf: getNightSuggestions())
        default:
            break
        }
        
        // Context-based suggestions
        suggestions.append(contentsOf: await getContextualSuggestions())
        
        await MainActor.run {
            self.shortcutSuggestions = suggestions
        }
        
        // Donate relevant shortcuts based on time and context
        await donateRelevantShortcuts(suggestions)
    }
    
    private func getMorningSuggestions() -> [ShortcutSuggestion] {
        return [
            ShortcutSuggestion(
                phrase: "Show my sleep quality from last night",
                intent: GetSleepQualityIntent(),
                priority: .high,
                context: "Morning routine"
            ),
            ShortcutSuggestion(
                phrase: "Get my daily health recommendations",
                intent: GetDailyRecommendationIntent(),
                priority: .high,
                context: "Morning routine"
            ),
            ShortcutSuggestion(
                phrase: "Log my morning mood",
                intent: LogMoodIntent(),
                priority: .medium,
                context: "Morning check-in"
            )
        ]
    }
    
    private func getDaySuggestions() -> [ShortcutSuggestion] {
        return [
            ShortcutSuggestion(
                phrase: "How many steps have I taken?",
                intent: GetStepsIntent(),
                priority: .medium,
                context: "Activity tracking"
            ),
            ShortcutSuggestion(
                phrase: "Log a glass of water",
                intent: LogWaterIntakeIntent(),
                priority: .high,
                context: "Hydration reminder"
            ),
            ShortcutSuggestion(
                phrase: "Check my heart rate",
                intent: GetHeartRateIntent(),
                priority: .low,
                context: "Health monitoring"
            )
        ]
    }
    
    private func getEveningSuggestions() -> [ShortcutSuggestion] {
        return [
            ShortcutSuggestion(
                phrase: "Start meditation",
                intent: StartMeditationIntent(),
                priority: .high,
                context: "Evening relaxation"
            ),
            ShortcutSuggestion(
                phrase: "Prepare my room for sleep",
                intent: OptimizeForSleepIntent(),
                priority: .high,
                context: "Sleep preparation"
            ),
            ShortcutSuggestion(
                phrase: "Log my evening mood",
                intent: LogMoodIntent(),
                priority: .medium,
                context: "Evening check-in"
            )
        ]
    }
    
    private func getNightSuggestions() -> [ShortcutSuggestion] {
        return [
            ShortcutSuggestion(
                phrase: "Start sleep tracking",
                intent: StartSleepTrackingIntent(),
                priority: .high,
                context: "Bedtime routine"
            ),
            ShortcutSuggestion(
                phrase: "Play sleep sounds",
                intent: StartSleepAudioIntent(),
                priority: .high,
                context: "Sleep enhancement"
            ),
            ShortcutSuggestion(
                phrase: "Optimize environment for sleep",
                intent: OptimizeEnvironmentIntent(),
                priority: .medium,
                context: "Sleep preparation"
            )
        ]
    }
    
    private func getContextualSuggestions() async -> [ShortcutSuggestion] {
        var suggestions: [ShortcutSuggestion] = []
        
        // Add suggestions based on user's current health state
        let stressLevel = await getCurrentStressLevel()
        if stressLevel > 0.7 {
            suggestions.append(ShortcutSuggestion(
                phrase: "Start a stress relief session",
                intent: StartMeditationIntent(),
                priority: .high,
                context: "High stress detected"
            ))
        }
        
        // Add suggestions based on activity level
        let todaySteps = await getTodaySteps()
        if todaySteps < 5000 && Calendar.current.component(.hour, from: Date()) > 14 {
            suggestions.append(ShortcutSuggestion(
                phrase: "Log some physical activity",
                intent: LogActivityIntent(),
                priority: .medium,
                context: "Low activity today"
            ))
        }
        
        return suggestions
    }
    
    private func donateRelevantShortcuts(_ suggestions: [ShortcutSuggestion]) async {
        for suggestion in suggestions.prefix(3) { // Limit to top 3 suggestions
            await donateIntent(suggestion.intent, phrase: suggestion.phrase)
        }
    }
    
    // MARK: - Shortcut Management
    
    private func setupShortcutDonation() {
        // Listen for user actions to donate relevant shortcuts
        NotificationCenter.default.publisher(for: .userActionPerformed)
            .compactMap { $0.object as? UserAction }
            .sink { [weak self] action in
                Task {
                    await self?.donateShortcutForAction(action)
                }
            }
            .store(in: &cancellables)
    }
    
    private func donateShortcutForAction(_ action: UserAction) async {
        // Donate shortcuts based on user actions
        switch action.type {
        case .startedSleepTracking:
            await donateIntent(StartSleepTrackingIntent(), phrase: "Start tracking my sleep")
        case .loggedWater:
            await donateIntent(LogWaterIntakeIntent(), phrase: "Log water intake")
        case .checkedHeartRate:
            await donateIntent(GetHeartRateIntent(), phrase: "Check my heart rate")
        case .startedMeditation:
            await donateIntent(StartMeditationIntent(), phrase: "Start meditation")
        case .optimizedEnvironment:
            await donateIntent(OptimizeForSleepIntent(), phrase: "Optimize for sleep")
        }
    }
    
    func trackShortcutUsage(_ shortcutPhrase: String) {
        // Track which shortcuts are used frequently
        if !frequentlyUsedShortcuts.contains(shortcutPhrase) {
            frequentlyUsedShortcuts.append(shortcutPhrase)
        }
        
        // Update donation for frequently used shortcuts
        if let shortcut = donatedShortcuts.first(where: { $0.phrase == shortcutPhrase }) {
            shortcut.usageCount += 1
        }
        
        logger.debug("Tracked usage for shortcut: \(shortcutPhrase)")
    }
    
    // MARK: - Data Fetching (Placeholder implementations)
    
    private func getCurrentStressLevel() async -> Double {
        return 0.3 // This would integrate with MentalHealthManager
    }
    
    private func getTodaySteps() async -> Int {
        return 6500 // This would integrate with HealthDataManager
    }
}

// MARK: - Supporting Types

struct DonatedShortcut: Identifiable {
    let id = UUID()
    let phrase: String
    let intentType: String
    let donationDate: Date
    var usageCount: Int
}

struct ShortcutSuggestion {
    let phrase: String
    let intent: any INIntent
    let priority: SuggestionPriority
    let context: String
}

enum SuggestionPriority {
    case low, medium, high
}

struct UserAction {
    let type: UserActionType
    let timestamp: Date
    let context: [String: Any]
}

enum UserActionType {
    case startedSleepTracking
    case loggedWater
    case checkedHeartRate
    case startedMeditation
    case optimizedEnvironment
}

// MARK: - Intent Definitions (Placeholder implementations)

class GetHeartRateIntent: INIntent {
    override var suggestedInvocationPhrase: String? {
        get { return "What's my heart rate?" }
        set { super.suggestedInvocationPhrase = newValue }
    }
}

class GetSleepQualityIntent: INIntent {
    override var suggestedInvocationPhrase: String? {
        get { return "How did I sleep?" }
        set { super.suggestedInvocationPhrase = newValue }
    }
}

class GetStepsIntent: INIntent {
    override var suggestedInvocationPhrase: String? {
        get { return "How many steps today?" }
        set { super.suggestedInvocationPhrase = newValue }
    }
}

class LogWeightIntent: INIntent {
    override var suggestedInvocationPhrase: String? {
        get { return "Log my weight" }
        set { super.suggestedInvocationPhrase = newValue }
    }
}

class GetSleepAnalysisIntent: INIntent {
    override var suggestedInvocationPhrase: String? {
        get { return "Analyze my sleep" }
        set { super.suggestedInvocationPhrase = newValue }
    }
}

class SetSleepGoalIntent: INIntent {
    override var suggestedInvocationPhrase: String? {
        get { return "Set my sleep goal" }
        set { super.suggestedInvocationPhrase = newValue }
    }
}

class OptimizeEnvironmentIntent: INIntent {
    override var suggestedInvocationPhrase: String? {
        get { return "Optimize my environment" }
        set { super.suggestedInvocationPhrase = newValue }
    }
}

class GetDailyRecommendationIntent: INIntent {
    override var suggestedInvocationPhrase: String? {
        get { return "What's my daily recommendation?" }
        set { super.suggestedInvocationPhrase = newValue }
    }
}

class StartCoachingSessionIntent: INIntent {
    override var suggestedInvocationPhrase: String? {
        get { return "Start coaching session" }
        set { super.suggestedInvocationPhrase = newValue }
    }
}

class GetHealthInsightsIntent: INIntent {
    override var suggestedInvocationPhrase: String? {
        get { return "Show my health insights" }
        set { super.suggestedInvocationPhrase = newValue }
    }
}

class AskHealthQuestionIntent: INIntent {
    override var suggestedInvocationPhrase: String? {
        get { return "Ask health question" }
        set { super.suggestedInvocationPhrase = newValue }
    }
}

class GetMotivationalMessageIntent: INIntent {
    override var suggestedInvocationPhrase: String? {
        get { return "Give me motivation" }
        set { super.suggestedInvocationPhrase = newValue }
    }
}

class StartSleepAudioIntent: INIntent {
    override var suggestedInvocationPhrase: String? {
        get { return "Play sleep sounds" }
        set { super.suggestedInvocationPhrase = newValue }
    }
}

class OptimizeForSleepIntent: INIntent {
    override var suggestedInvocationPhrase: String? {
        get { return "Prepare for sleep" }
        set { super.suggestedInvocationPhrase = newValue }
    }
}

class CreateRelaxingEnvironmentIntent: INIntent {
    override var suggestedInvocationPhrase: String? {
        get { return "Create relaxing environment" }
        set { super.suggestedInvocationPhrase = newValue }
    }
}

class ContactEmergencyContactIntent: INIntent {
    override var suggestedInvocationPhrase: String? {
        get { return "Contact emergency contact" }
        set { super.suggestedInvocationPhrase = newValue }
    }
}

class TriggerHealthAlertIntent: INIntent {
    override var suggestedInvocationPhrase: String? {
        get { return "Trigger health alert" }
        set { super.suggestedInvocationPhrase = newValue }
    }
}

class ShareHealthDataIntent: INIntent {
    override var suggestedInvocationPhrase: String? {
        get { return "Share my health data" }
        set { super.suggestedInvocationPhrase = newValue }
    }
}

class RequestMedicalAssistanceIntent: INIntent {
    override var suggestedInvocationPhrase: String? {
        get { return "Request medical assistance" }
        set { super.suggestedInvocationPhrase = newValue }
    }
}

class GetHealthSummaryIntent: INIntent {
    override var suggestedInvocationPhrase: String? {
        get { return "Show my health summary" }
        set { super.suggestedInvocationPhrase = newValue }
    }
}

class LogActivityIntent: INIntent {
    override var suggestedInvocationPhrase: String? {
        get { return "Log my activity" }
        set { super.suggestedInvocationPhrase = newValue }
    }
}

// MARK: - Notification Extensions

extension Notification.Name {
    static let userActionPerformed = Notification.Name("userActionPerformed")
}
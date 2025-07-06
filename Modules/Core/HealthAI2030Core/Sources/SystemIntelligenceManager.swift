
import Foundation
import Combine
import AppIntents
import Intents
import HealthKit
import NaturalLanguage
import SiriKit
import LogWaterIntake
import OSLog

@MainActor
public class SystemIntelligenceManager: ObservableObject {
    public static let shared = SystemIntelligenceManager()
    
    @Published public var siriSuggestions: [SiriSuggestion] = []
    @Published public var appShortcuts: [AppShortcut] = []
    @Published public var automationRules: [AutomationRule] = []
    @Published public var predictiveInsights: [PredictiveInsight] = []
    
    private let appleIntelligenceIntegration: AppleIntelligenceHealthIntegration
    private let shortcutsManager: ShortcutsManager
    private var cancellables = Set<AnyCancellable>()
    private let logger = Logger(subsystem: "com.healthai2030.SystemIntelligenceManager", category: "Manager")
    
    private init() {
        self.appleIntelligenceIntegration = AppleIntelligenceHealthIntegration()
        self.shortcutsManager = ShortcutsManager()
        
        // Initialize backend managers
        Task {
            await appleIntelligenceIntegration.initialize()
            await shortcutsManager.initialize()
            
            // Load initial data
            generateSiriSuggestions()
            loadAppShortcuts()
            generatePredictiveInsights()
            loadAutomationRules()
        }
    }
    
    // MARK: - Automation Rule Management
    public func addAutomationRule(_ rule: AutomationRule) {
        automationRules.append(rule)
        // In a real app, you'd persist this rule and potentially register it with a backend automation engine.
        logger.info("Added automation rule: \(rule.name)")
    }
    
    public func updateAutomationRule(_ rule: AutomationRule) {
        if let idx = automationRules.firstIndex(where: { $0.id == rule.id }) {
            automationRules[idx] = rule
            logger.info("Updated automation rule: \(rule.name), isActive: \(rule.isActive)")
        }
        // In a real app, you'd persist this update.
    }
    
    public func removeAutomationRule(_ rule: AutomationRule) {
        automationRules.removeAll { $0.id == rule.id }
        logger.info("Removed automation rule: \(rule.name)")
        // In a real app, you'd remove this from persistence.
    }
    
    private func loadAutomationRules() {
        // Placeholder for loading automation rules. In a real app, these would be loaded from storage.
        automationRules = [
            AutomationRule(
                id: UUID().uuidString,
                name: "Evening Wind Down",
                description: "Suggests mindfulness and adjusts environment when stress is high in the evening.",
                trigger: .timeOfDay,
                condition: { Calendar.current.component(.hour, from: Date()) >= 19 && Calendar.current.component(.hour, from: Date()) <= 22 },
                actions: [.suggestMindfulness, .adjustEnvironment],
                isActive: true
            ),
            AutomationRule(
                id: UUID().uuidString,
                name: "Low Oxygen Alert",
                description: "Sends an emergency alert if oxygen saturation drops below a critical level.",
                trigger: .oxygenSaturation,
                condition: { false }, // Placeholder for actual condition check
                actions: [.sendEmergencyAlert],
                isActive: false
            )
        ]
        logger.info("Loaded \(automationRules.count) automation rules.")
    }
    
    // MARK: - Siri Suggestions
    public func generateSiriSuggestions() {
        Task {
            // Use AppleIntelligenceHealthIntegration to get proactive recommendations
            appleIntelligenceIntegration.generateProactiveHealthInsights()
            
            // Map proactive recommendations to SiriSuggestions
            let insights = await appleIntelligenceIntegration.$proactiveRecommendations
                .first()
                .values
                .first()
            
            if let insights = insights {
                self.siriSuggestions = insights.map { insight in
                    SiriSuggestion(
                        id: UUID(),
                        title: insight.title,
                        description: insight.description,
                        type: .general, // Map to appropriate type
                        priority: mapPriority(insight.priority),
                        trigger: .automation // Map to appropriate trigger
                    )
                }
                logger.info("Generated \(siriSuggestions.count) Siri suggestions from proactive insights.")
            } else {
                // Fallback to hardcoded suggestions if no insights are available
                siriSuggestions = [
                    SiriSuggestion(id: UUID(), title: "Take a mindful break", description: "Based on your recent stress levels", type: .mindfulness, priority: .high, trigger: .stressLevel),
                    SiriSuggestion(id: UUID(), title: "Log your mood", description: "Quickly record how you're feeling", type: .general, priority: .medium, trigger: .automation)
                ]
                logger.info("Generated fallback Siri suggestions.")
            }
        }
    }
    
    private func mapPriority(_ priority: Priority) -> SiriSuggestion.SuggestionPriority {
        switch priority {
        case .low: return .low
        case .medium: return .medium
        case .high: return .high
        case .urgent: return .critical
        }
    }
    
    // MARK: - App Shortcuts
    public func loadAppShortcuts() {
        Task {
            // Use ShortcutsManager to get donated and suggested shortcuts
            await shortcutsManager.donateCommonIntents() // Ensure common intents are donated
            await shortcutsManager.updatePredictiveSuggestions() // Update predictive suggestions
            
            let donated = await shortcutsManager.$donatedShortcuts
                .first()
                .values
                .first() ?? []
            
            let suggested = await shortcutsManager.$shortcutSuggestions
                .first()
                .values
                .first() ?? []
            
            // Combine and map to AppShortcut
            self.appShortcuts = (donated.map { AppShortcut(donated: $0) } + suggested.map { AppShortcut(suggested: $0) })
                .sorted { $0.title < $1.title } // Sort for consistent display
            
            logger.info("Loaded \(appShortcuts.count) app shortcuts.")
        }
    }
    
    public func handleAppShortcut(_ shortcut: AppShortcut) {
        logger.info("Handling app shortcut: \(shortcut.title)")
        // In a real app, you would execute the associated intent or action.
        // For now, we'll just log it.
        shortcutsManager.trackShortcutUsage(shortcut.title)
        
        // Example of executing an intent (requires the actual intent object)
        // if let intent = shortcut.intent as? INIntent {
        //     let interaction = INInteraction(intent: intent, response: nil)
        //     interaction.donate { error in
        //         if let error = error {
        //             self.logger.error("Failed to execute shortcut intent: \(error.localizedDescription)")
        //         } else {
        //             self.logger.info("Successfully executed shortcut intent: \(shortcut.title)")
        //         }
        //     }
        // }
    }
    
    // MARK: - Predictive Insights
    public func generatePredictiveInsights() {
        Task {
            // Use AppleIntelligenceHealthIntegration to generate health insights
            appleIntelligenceIntegration.generateProactiveHealthInsights()
            
            let insights = await appleIntelligenceIntegration.$proactiveRecommendations
                .first()
                .values
                .first()
            
            if let insights = insights {
                self.predictiveInsights = insights.map { insight in
                    PredictiveInsight(
                        id: UUID(),
                        title: insight.title,
                        description: insight.description,
                        confidence: insight.confidence,
                        recommendations: insight.actionItems.map { $0.title },
                        category: mapInsightCategory(insight.category),
                        timestamp: Date() // Use current date as placeholder
                    )
                }
                logger.info("Generated \(predictiveInsights.count) predictive insights.")
            } else {
                // Fallback to hardcoded insights if no insights are available
                predictiveInsights = [
                    PredictiveInsight(id: UUID(), title: "You are likely to feel tired tomorrow.", description: "Your sleep consistency has been low this week.", confidence: 0.82, recommendations: ["Try to go to bed at the same time each night.", "Ensure your bedroom is dark and cool."], category: .health, timestamp: Date()),
                    PredictiveInsight(id: UUID(), title: "Increased stress detected.", description: "Your heart rate variability has shown higher stress indicators.", confidence: 0.75, recommendations: ["Consider a short breathing exercise.", "Take a 15-minute walk."], category: .behavior, timestamp: Date())
                ]
                logger.info("Generated fallback predictive insights.")
            }
        }
    }
    
    private func mapInsightCategory(_ category: RecommendationCategory) -> PredictiveInsight.InsightCategory {
        switch category {
        case .prevention: return .health
        case .optimization: return .behavior
        case .education: return .lifestyle
        case .motivation: return .lifestyle
        case .emergency: return .health
        }
    }
}

// MARK: - Model Definitions
public struct SiriSuggestion: Identifiable, Codable {
    public let id: UUID
    public let title: String
    public let description: String
    public let type: SuggestionType
    public let priority: SuggestionPriority
    public let trigger: SuggestionTrigger
    
    public enum SuggestionType: String, Codable {
        case mindfulness
        case breathing
        case sleep
        case cardiac
        case respiratory
        case general
    }
    
    public enum SuggestionPriority: String, Codable {
        case low
        case medium
        case high
        case critical
    }
    
    public enum SuggestionTrigger: String, Codable, CaseIterable {
        case stressLevel
        case respiratoryRate
        case circadianRhythm
        case heartRate
        case afibStatus
        case sleepQuality
        case automation
    }
}

public struct AppShortcut: Identifiable, Codable {
    public let id: UUID
    public let title: String
    public let subtitle: String
    public let icon: String
    public let phrases: [String]
    public let intent: String // Store intent identifier or type
    
    // Initialize from DonatedShortcut
    init(donated: DonatedShortcut) {
        self.id = donated.id
        self.title = donated.phrase
        self.subtitle = "Siri Shortcut"
        self.icon = "hand.tap.fill" // Default icon
        self.phrases = [donated.phrase]
        self.intent = donated.intentType
    }
    
    // Initialize from ShortcutSuggestion
    init(suggested: ShortcutSuggestion) {
        self.id = UUID() // Generate new UUID for suggestion
        self.title = suggested.phrase
        self.subtitle = suggested.context
        self.icon = "lightbulb.fill" // Default icon for suggestions
        self.phrases = [suggested.phrase]
        self.intent = String(describing: type(of: suggested.intent))
    }
}

public struct AutomationRule: Identifiable, Codable {
    public let id: String
    public var name: String
    public var description: String
    public var trigger: AutomationTrigger
    public var condition: () -> Bool // Condition to be met for the rule to fire
    public var actions: [AutomationAction]
    public var isActive: Bool
    
    // Custom initializer to allow non-Codable 'condition'
    public init(id: String, name: String, description: String, trigger: AutomationTrigger, condition: @escaping () -> Bool, actions: [AutomationAction], isActive: Bool) {
        self.id = id
        self.name = name
        self.description = description
        self.trigger = trigger
        self.condition = condition
        self.actions = actions
        self.isActive = isActive
    }
    
    // Manual Codable conformance for properties excluding 'condition'
    enum CodingKeys: String, CodingKey {
        case id, name, description, trigger, actions, isActive
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        description = try container.decode(String.self, forKey: .description)
        trigger = try container.decode(AutomationTrigger.self, forKey: .trigger)
        actions = try container.decode([AutomationAction].self, forKey: .actions)
        isActive = try container.decode(Bool.self, forKey: .isActive)
        condition = { true } // Default placeholder, actual condition logic would be handled externally or dynamically
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(description, forKey: .description)
        try container.encode(trigger, forKey: .trigger)
        try container.encode(actions, forKey: .actions)
        try container.encode(isActive, forKey: .isActive)
    }
    
    public enum AutomationTrigger: String, Codable, CaseIterable {
        case stressLevel
        case circadianRhythm
        case afibStatus
        case oxygenSaturation
        case sleepQuality
        case timeOfDay
        case location
    }
    
    public enum AutomationAction: String, Codable, CaseIterable {
        case suggestMindfulness
        case adjustEnvironment
        case sendNotification
        case suggestWindDown
        case startSleepOptimization
        case sendEmergencyAlert
        case suggestCardiacCheck
        case recordHealthData
        case suggestBreathingExercise
        case sendAlert
    }
}

public struct PredictiveInsight: Identifiable, Codable {
    public let id: UUID
    public let title: String
    public let description: String
    public let confidence: Double
    public let recommendations: [String]
    public let category: InsightCategory
    public let timestamp: Date
    
    public enum InsightCategory: String, Codable {
        case health
        case behavior
        case environment
        case lifestyle
    }
}

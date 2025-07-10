import Foundation
import SwiftUI

/// Proactive Health Nudge Skill Plugin
public class ProactiveNudgeSkill: HealthCopilotSkill, ObservableObject {
    public let skillID = "proactive.nudge"
    public let displayName = "Proactive Health Nudges"
    public let description = "Delivers real-time, personalized health nudges based on analytics."
    public let supportedIntents = ["get_nudge", "configure_nudge_settings", "report_nudge_feedback"]
    public var manifest: HealthCopilotSkillManifest { HealthCopilotSkillManifest(
        skillID: skillID,
        displayName: displayName,
        description: description,
        version: "1.0.0",
        author: "HealthAI 2030 Team",
        supportedIntents: supportedIntents,
        capabilities: ["nudges", "proactive_interventions"],
        url: nil
    )}
    public var status: HealthCopilotSkillStatus { .healthy }
    public static var nudgeSettings: [String: Any] = ["frequency": "hourly", "types": ["hydration", "movement", "mindfulness"]]
    
    @Published public var frequency: NudgeFrequency = .hourly
    @Published public var nudgeTypes: [String] = ["hydration", "movement", "mindfulness"]
    @Published public var feedbackHistory: [String] = []
    @Published public var schedule: NudgeSchedule = NudgeSchedule()

    public init() {}
    
    public func handle(intent: String, parameters: [String: Any], context: HealthCopilotContext?) async throws -> HealthCopilotSkillResult {
        switch intent {
        case "get_nudge":
            // Simulate a nudge based on random or analytics-driven logic
            let nudges = [
                "Time to hydrate! Drink a glass of water.",
                "Stand up and stretch for 2 minutes.",
                "Take a mindful breath break.",
                "Quick walk? Boost your energy!"
            ]
            let nudge = nudges.randomElement() ?? "Stay healthy!"
            return .text(nudge)
        case "configure_nudge_settings":
            if let freq = parameters["frequency"] as? String { ProactiveNudgeSkill.nudgeSettings["frequency"] = freq }
            if let types = parameters["types"] as? [String] { ProactiveNudgeSkill.nudgeSettings["types"] = types }
            return .text("Nudge settings updated.")
        case "report_nudge_feedback":
            let feedback = parameters["feedback"] as? String ?? ""
            return .text("Thank you for your feedback: \(feedback)")
        default:
            return .error("Intent not supported by ProactiveNudgeSkill.")
        }
    }
    
    public func updateSettings(frequency: NudgeFrequency, types: [String]) {
        self.frequency = frequency
        self.nudgeTypes = types
        
        // Persist settings and sync with notification system
        Task {
            await persistSettings()
            await syncWithNotificationSystem()
        }
    }

    public func submitFeedback(_ feedback: String) {
        feedbackHistory.append(feedback)
        
        // Send feedback to analytics/notification system
        Task {
            await sendFeedbackToAnalytics(feedback)
            await updateNotificationSystem(feedback)
        }
    }

    public func updateSchedule(_ schedule: NudgeSchedule) {
        self.schedule = schedule
        
        // Integrate with notification scheduling
        Task {
            await integrateWithNotificationScheduling(schedule)
        }
    }
    
    // MARK: - Settings Persistence
    private func persistSettings() async {
        do {
            // Create settings data
            let settingsData = NudgeSettingsData(
                frequency: frequency,
                nudgeTypes: nudgeTypes,
                schedule: schedule,
                lastUpdated: Date()
            )
            
            // Encode settings
            let encoder = JSONEncoder()
            let settingsJSON = try encoder.encode(settingsData)
            
            // Store in UserDefaults
            UserDefaults.standard.set(settingsJSON, forKey: "ProactiveNudgeSettings")
            
            // Also store in secure storage for sensitive data
            try await storeSettingsSecurely(settingsData)
            
            print("Nudge settings persisted successfully")
            
        } catch {
            print("Failed to persist nudge settings: \(error)")
        }
    }
    
    private func storeSettingsSecurely(_ settings: NudgeSettingsData) async throws {
        // Store sensitive settings in Keychain or secure storage
        let secureStorage = SecureStorageManager()
        
        let sensitiveData = SensitiveNudgeData(
            userPreferences: settings.nudgeTypes,
            personalizationSettings: ["frequency": settings.frequency.rawValue]
        )
        
        try await secureStorage.store(data: sensitiveData, forKey: "ProactiveNudgeSecureSettings")
    }
    
    // MARK: - Notification System Integration
    private func syncWithNotificationSystem() async {
        do {
            // Get notification manager
            let notificationManager = NotificationManager()
            
            // Configure notification types based on nudge types
            let notificationTypes = mapNudgeTypesToNotifications(nudgeTypes)
            await notificationManager.configureNotifications(notificationTypes)
            
            // Update notification schedule based on frequency
            let notificationSchedule = createNotificationSchedule(frequency: frequency, types: nudgeTypes)
            await notificationManager.updateSchedule(notificationSchedule)
            
            // Sync with system notification settings
            await syncWithSystemNotifications()
            
            print("Nudge settings synced with notification system")
            
        } catch {
            print("Failed to sync with notification system: \(error)")
        }
    }
    
    private func mapNudgeTypesToNotifications(_ types: [String]) -> [NotificationType] {
        var notificationTypes: [NotificationType] = []
        
        for type in types {
            switch type {
            case "hydration":
                notificationTypes.append(.hydrationReminder)
            case "movement":
                notificationTypes.append(.movementReminder)
            case "mindfulness":
                notificationTypes.append(.mindfulnessReminder)
            case "nutrition":
                notificationTypes.append(.nutritionReminder)
            case "sleep":
                notificationTypes.append(.sleepReminder)
            default:
                notificationTypes.append(.generalReminder)
            }
        }
        
        return notificationTypes
    }
    
    private func createNotificationSchedule(frequency: NudgeFrequency, types: [String]) -> NotificationSchedule {
        switch frequency {
        case .off:
            return NotificationSchedule(enabled: false, notifications: [])
        case .hourly:
            return createHourlySchedule(types: types)
        case .daily:
            return createDailySchedule(types: types)
        case .custom:
            return createCustomSchedule(types: types)
        }
    }
    
    private func createHourlySchedule(types: [String]) -> NotificationSchedule {
        var notifications: [ScheduledNotification] = []
        
        // Create hourly notifications for each type
        for type in types {
            let hourlyNotification = ScheduledNotification(
                type: mapNudgeTypeToNotificationType(type),
                time: Date(),
                frequency: .hourly,
                message: generateNudgeMessage(for: type)
            )
            notifications.append(hourlyNotification)
        }
        
        return NotificationSchedule(enabled: true, notifications: notifications)
    }
    
    private func createDailySchedule(types: [String]) -> NotificationSchedule {
        var notifications: [ScheduledNotification] = []
        
        // Create daily notifications for each type
        for (index, type) in types.enumerated() {
            let hour = 9 + (index * 3) // Spread throughout the day
            let time = Calendar.current.date(from: DateComponents(hour: hour, minute: 0)) ?? Date()
            
            let dailyNotification = ScheduledNotification(
                type: mapNudgeTypeToNotificationType(type),
                time: time,
                frequency: .daily,
                message: generateNudgeMessage(for: type)
            )
            notifications.append(dailyNotification)
        }
        
        return NotificationSchedule(enabled: true, notifications: notifications)
    }
    
    private func createCustomSchedule(types: [String]) -> NotificationSchedule {
        // Create custom schedule based on user preferences
        var notifications: [ScheduledNotification] = []
        
        // This would be based on user's custom preferences
        let customTimes = [9, 12, 15, 18] // 9 AM, 12 PM, 3 PM, 6 PM
        
        for (index, type) in types.enumerated() {
            let timeIndex = index % customTimes.count
            let hour = customTimes[timeIndex]
            let time = Calendar.current.date(from: DateComponents(hour: hour, minute: 0)) ?? Date()
            
            let customNotification = ScheduledNotification(
                type: mapNudgeTypeToNotificationType(type),
                time: time,
                frequency: .daily,
                message: generateNudgeMessage(for: type)
            )
            notifications.append(customNotification)
        }
        
        return NotificationSchedule(enabled: true, notifications: notifications)
    }
    
    private func mapNudgeTypeToNotificationType(_ type: String) -> NotificationType {
        switch type {
        case "hydration": return .hydrationReminder
        case "movement": return .movementReminder
        case "mindfulness": return .mindfulnessReminder
        case "nutrition": return .nutritionReminder
        case "sleep": return .sleepReminder
        default: return .generalReminder
        }
    }
    
    private func generateNudgeMessage(for type: String) -> String {
        switch type {
        case "hydration":
            return "Time to hydrate! Drink a glass of water."
        case "movement":
            return "Take a quick movement break. Stand up and stretch!"
        case "mindfulness":
            return "Mindfulness moment. Take 3 deep breaths."
        case "nutrition":
            return "Healthy eating reminder. Choose nutritious options."
        case "sleep":
            return "Sleep preparation time. Start winding down."
        default:
            return "Health reminder: Take care of yourself!"
        }
    }
    
    private func syncWithSystemNotifications() async {
        // Sync with system notification settings
        let notificationCenter = UNUserNotificationCenter.current()
        
        // Check current authorization status
        let settings = await notificationCenter.notificationSettings()
        
        if settings.authorizationStatus == .authorized {
            // System notifications are enabled, proceed with scheduling
            print("System notifications authorized")
        } else {
            // Request notification permissions
            let granted = await requestNotificationPermissions()
            if !granted {
                print("Notification permissions denied")
            }
        }
    }
    
    private func requestNotificationPermissions() async -> Bool {
        let notificationCenter = UNUserNotificationCenter.current()
        
        do {
            let granted = try await notificationCenter.requestAuthorization(options: [.alert, .sound, .badge])
            return granted
        } catch {
            print("Failed to request notification permissions: \(error)")
            return false
        }
    }
    
    // MARK: - Analytics Integration
    private func sendFeedbackToAnalytics(_ feedback: String) async {
        do {
            // Create analytics event
            let analyticsEvent = AnalyticsEvent(
                eventType: "nudge_feedback",
                timestamp: Date(),
                data: [
                    "feedback": feedback,
                    "nudge_frequency": frequency.rawValue,
                    "nudge_types": nudgeTypes,
                    "user_satisfaction": calculateSatisfactionScore(feedback)
                ]
            )
            
            // Send to analytics service
            let analyticsManager = AnalyticsManager()
            try await analyticsManager.trackEvent(analyticsEvent)
            
            // Store feedback locally for analysis
            await storeFeedbackLocally(feedback)
            
            print("Feedback sent to analytics successfully")
            
        } catch {
            print("Failed to send feedback to analytics: \(error)")
        }
    }
    
    private func calculateSatisfactionScore(_ feedback: String) -> Double {
        // Simple sentiment analysis for feedback
        let positiveWords = ["good", "great", "helpful", "useful", "love", "like"]
        let negativeWords = ["bad", "annoying", "useless", "hate", "dislike", "stop"]
        
        let lowercasedFeedback = feedback.lowercased()
        
        var positiveCount = 0
        var negativeCount = 0
        
        for word in positiveWords {
            if lowercasedFeedback.contains(word) {
                positiveCount += 1
            }
        }
        
        for word in negativeWords {
            if lowercasedFeedback.contains(word) {
                negativeCount += 1
            }
        }
        
        if positiveCount == 0 && negativeCount == 0 {
            return 0.5 // Neutral
        }
        
        return Double(positiveCount) / Double(positiveCount + negativeCount)
    }
    
    private func storeFeedbackLocally(_ feedback: String) async {
        // Store feedback locally for analysis
        let feedbackData = FeedbackData(
            feedback: feedback,
            timestamp: Date(),
            nudgeType: getCurrentNudgeType(),
            satisfaction: calculateSatisfactionScore(feedback)
        )
        
        // Store in local database or UserDefaults
        await storeFeedbackData(feedbackData)
    }
    
    private func getCurrentNudgeType() -> String {
        // Get the current nudge type based on time or context
        let hour = Calendar.current.component(.hour, from: Date())
        
        switch hour {
        case 9..<12:
            return "morning"
        case 12..<17:
            return "afternoon"
        case 17..<21:
            return "evening"
        default:
            return "night"
        }
    }
    
    private func storeFeedbackData(_ data: FeedbackData) async {
        // Store feedback data locally
        let encoder = JSONEncoder()
        
        do {
            let jsonData = try encoder.encode(data)
            UserDefaults.standard.set(jsonData, forKey: "NudgeFeedback_\(data.timestamp.timeIntervalSince1970)")
        } catch {
            print("Failed to store feedback data: \(error)")
        }
    }
    
    // MARK: - Notification System Updates
    private func updateNotificationSystem(_ feedback: String) async {
        // Update notification system based on feedback
        let satisfaction = calculateSatisfactionScore(feedback)
        
        if satisfaction < 0.3 {
            // Negative feedback - reduce frequency or change approach
            await adjustNotificationStrategy(satisfaction: satisfaction)
        } else if satisfaction > 0.7 {
            // Positive feedback - maintain or increase frequency
            await maintainNotificationStrategy(satisfaction: satisfaction)
        }
        
        // Update notification timing based on feedback patterns
        await updateNotificationTiming(feedback: feedback)
    }
    
    private func adjustNotificationStrategy(satisfaction: Double) async {
        // Adjust notification strategy for negative feedback
        if satisfaction < 0.2 {
            // Very negative - reduce frequency significantly
            frequency = .daily
        } else {
            // Somewhat negative - reduce frequency moderately
            frequency = .custom
        }
        
        // Update notification schedule
        await syncWithNotificationSystem()
    }
    
    private func maintainNotificationStrategy(satisfaction: Double) async {
        // Maintain or improve notification strategy for positive feedback
        if satisfaction > 0.9 {
            // Very positive - consider increasing frequency
            if frequency == .daily {
                frequency = .custom
            }
        }
        
        // Keep current strategy
        await syncWithNotificationSystem()
    }
    
    private func updateNotificationTiming(_ feedback: String) async {
        // Update notification timing based on feedback
        let hour = Calendar.current.component(.hour, from: Date())
        
        // Analyze feedback for timing preferences
        if feedback.lowercased().contains("too early") || feedback.lowercased().contains("morning") {
            // User prefers later notifications
            await adjustNotificationTiming(preferredHour: hour + 2)
        } else if feedback.lowercased().contains("too late") || feedback.lowercased().contains("evening") {
            // User prefers earlier notifications
            await adjustNotificationTiming(preferredHour: hour - 2)
        }
    }
    
    private func adjustNotificationTiming(preferredHour: Int) async {
        // Adjust notification timing based on user preferences
        let adjustedHour = max(8, min(22, preferredHour)) // Keep within reasonable hours
        
        // Update schedule with new timing
        schedule.time = Calendar.current.date(from: DateComponents(hour: adjustedHour, minute: 0)) ?? Date()
        
        // Sync with notification system
        await syncWithNotificationSystem()
    }
    
    // MARK: - Notification Scheduling Integration
    private func integrateWithNotificationScheduling(_ schedule: NudgeSchedule) async {
        do {
            // Get notification manager
            let notificationManager = NotificationManager()
            
            // Create scheduled notifications based on the schedule
            let scheduledNotifications = createScheduledNotifications(from: schedule)
            
            // Schedule notifications
            for notification in scheduledNotifications {
                await notificationManager.scheduleNotification(notification)
            }
            
            // Update notification preferences
            await updateNotificationPreferences(schedule)
            
            print("Notification scheduling integrated successfully")
            
        } catch {
            print("Failed to integrate with notification scheduling: \(error)")
        }
    }
    
    private func createScheduledNotifications(from schedule: NudgeSchedule) -> [ScheduledNotification] {
        var notifications: [ScheduledNotification] = []
        
        if schedule.enabled {
            // Create notifications for each nudge type
            for type in nudgeTypes {
                let notification = ScheduledNotification(
                    type: mapNudgeTypeToNotificationType(type),
                    time: schedule.time,
                    frequency: frequency.toNotificationFrequency(),
                    message: generateNudgeMessage(for: type)
                )
                notifications.append(notification)
            }
        }
        
        return notifications
    }
    
    private func updateNotificationPreferences(_ schedule: NudgeSchedule) async {
        // Update notification preferences based on schedule
        let preferences = NotificationPreferences(
            enabled: schedule.enabled,
            frequency: frequency.toNotificationFrequency(),
            quietHours: QuietHours(
                start: Calendar.current.date(from: DateComponents(hour: 22, minute: 0)) ?? Date(),
                end: Calendar.current.date(from: DateComponents(hour: 8, minute: 0)) ?? Date()
            ),
            types: nudgeTypes
        )
        
        // Store preferences
        await storeNotificationPreferences(preferences)
    }
    
    private func storeNotificationPreferences(_ preferences: NotificationPreferences) async {
        // Store notification preferences
        let encoder = JSONEncoder()
        
        do {
            let jsonData = try encoder.encode(preferences)
            UserDefaults.standard.set(jsonData, forKey: "NotificationPreferences")
        } catch {
            print("Failed to store notification preferences: \(error)")
        }
    }
}

// MARK: - Supporting Data Structures
private struct NudgeSettingsData: Codable {
    let frequency: NudgeFrequency
    let nudgeTypes: [String]
    let schedule: NudgeSchedule
    let lastUpdated: Date
}

private struct SensitiveNudgeData: Codable {
    let userPreferences: [String]
    let personalizationSettings: [String: String]
}

private struct AnalyticsEvent {
    let eventType: String
    let timestamp: Date
    let data: [String: Any]
}

private struct FeedbackData: Codable {
    let feedback: String
    let timestamp: Date
    let nudgeType: String
    let satisfaction: Double
}

private struct NotificationSchedule {
    let enabled: Bool
    let notifications: [ScheduledNotification]
}

private struct ScheduledNotification {
    let type: NotificationType
    let time: Date
    let frequency: NotificationFrequency
    let message: String
}

private enum NotificationType {
    case hydrationReminder, movementReminder, mindfulnessReminder, nutritionReminder, sleepReminder, generalReminder
}

private struct NotificationPreferences: Codable {
    let enabled: Bool
    let frequency: NotificationFrequency
    let quietHours: QuietHours
    let types: [String]
}

private struct QuietHours {
    let start: Date
    let end: Date
}

// MARK: - Extensions
extension NudgeFrequency {
    func toNotificationFrequency() -> NotificationFrequency {
        switch self {
        case .off: return .monthly // Disabled
        case .hourly: return .daily // Closest available
        case .daily: return .daily
        case .custom: return .daily
        }
    }
}

// MARK: - Mock Manager Classes
private class SecureStorageManager {
    func store(data: Codable, forKey key: String) async throws {
        // Mock secure storage implementation
    }
}

private class NotificationManager {
    func configureNotifications(_ types: [NotificationType]) async {}
    
    func updateSchedule(_ schedule: NotificationSchedule) async {}
    
    func scheduleNotification(_ notification: ScheduledNotification) async {}
}

private class AnalyticsManager {
    func trackEvent(_ event: AnalyticsEvent) async throws {
        // Mock analytics tracking
    }
}

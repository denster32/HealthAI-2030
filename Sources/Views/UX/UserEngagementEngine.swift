import Foundation
import SwiftUI
import UserNotifications
import Combine

// MARK: - User Engagement Engine Protocol
protocol UserEngagementEngineProtocol {
    func scheduleNotification(_ notification: EngagementNotification) async throws
    func sendInAppMessage(_ message: InAppMessage) async throws
    func logEngagementEvent(_ event: EngagementEvent)
    func triggerGamification(for user: UserProfile, event: GamificationEvent) async throws
    func personalizeEngagement(for user: UserProfile) async throws -> EngagementProfile
}

// MARK: - Notification Model
struct EngagementNotification: Identifiable, Codable {
    let id: String
    let title: String
    let body: String
    let triggerDate: Date
    let category: NotificationCategory
    let userID: String
    let metadata: [String: String]
    
    init(title: String, body: String, triggerDate: Date, category: NotificationCategory, userID: String, metadata: [String: String] = [:]) {
        self.id = UUID().uuidString
        self.title = title
        self.body = body
        self.triggerDate = triggerDate
        self.category = category
        self.userID = userID
        self.metadata = metadata
    }
}

// MARK: - In-App Message Model
struct InAppMessage: Identifiable, Codable {
    let id: String
    let title: String
    let message: String
    let type: MessageType
    let userID: String
    let actions: [MessageAction]
    let timestamp: Date
    
    init(title: String, message: String, type: MessageType, userID: String, actions: [MessageAction] = []) {
        self.id = UUID().uuidString
        self.title = title
        self.message = message
        self.type = type
        self.userID = userID
        self.actions = actions
        self.timestamp = Date()
    }
}

// MARK: - Engagement Event Model
struct EngagementEvent: Identifiable, Codable {
    let id: String
    let userID: String
    let eventType: EngagementEventType
    let timestamp: Date
    let metadata: [String: String]
    
    init(userID: String, eventType: EngagementEventType, metadata: [String: String] = [:]) {
        self.id = UUID().uuidString
        self.userID = userID
        self.eventType = eventType
        self.timestamp = Date()
        self.metadata = metadata
    }
}

// MARK: - Gamification Event Model
struct GamificationEvent: Identifiable, Codable {
    let id: String
    let userID: String
    let type: GamificationType
    let points: Int
    let badge: String?
    let timestamp: Date
    let metadata: [String: String]
    
    init(userID: String, type: GamificationType, points: Int, badge: String? = nil, metadata: [String: String] = [:]) {
        self.id = UUID().uuidString
        self.userID = userID
        self.type = type
        self.points = points
        self.badge = badge
        self.timestamp = Date()
        self.metadata = metadata
    }
}

// MARK: - Engagement Profile
struct EngagementProfile: Identifiable, Codable {
    let id: String
    let userID: String
    let engagementScore: Double
    let preferredChannels: [EngagementChannel]
    let lastActive: Date
    let badges: [String]
    let streak: Int
    let recommendations: [String]
    
    init(userID: String, engagementScore: Double, preferredChannels: [EngagementChannel], lastActive: Date, badges: [String], streak: Int, recommendations: [String]) {
        self.id = UUID().uuidString
        self.userID = userID
        self.engagementScore = engagementScore
        self.preferredChannels = preferredChannels
        self.lastActive = lastActive
        self.badges = badges
        self.streak = streak
        self.recommendations = recommendations
    }
}

// MARK: - Enums

enum NotificationCategory: String, Codable, CaseIterable {
    case reminder, achievement, alert, message, promotion
}

enum MessageType: String, Codable, CaseIterable {
    case info, warning, success, error, promotion
}

struct MessageAction: Identifiable, Codable {
    let id: String
    let title: String
    let actionType: MessageActionType
    let url: String?
    
    init(title: String, actionType: MessageActionType, url: String? = nil) {
        self.id = UUID().uuidString
        self.title = title
        self.actionType = actionType
        self.url = url
    }
}

enum MessageActionType: String, Codable, CaseIterable {
    case open, dismiss, custom
}

enum EngagementEventType: String, Codable, CaseIterable {
    case appOpen, featureUsed, goalCompleted, notificationReceived, messageRead, streakAchieved, badgeEarned
}

enum GamificationType: String, Codable, CaseIterable {
    case points, badge, streak, levelUp, challengeCompleted
}

enum EngagementChannel: String, Codable, CaseIterable {
    case push, inApp, email, sms
}

// MARK: - User Engagement Engine Implementation
actor UserEngagementEngine: UserEngagementEngineProtocol {
    private let notificationManager = NotificationManager()
    private let messageManager = MessageManager()
    private let analyticsManager = EngagementAnalyticsManager()
    private let gamificationManager = GamificationManager()
    private let personalizationManager = EngagementPersonalizationManager()
    private let logger = Logger(subsystem: "com.healthai2030.ux", category: "UserEngagementEngine")
    
    func scheduleNotification(_ notification: EngagementNotification) async throws {
        logger.info("Scheduling notification: \(notification.title)")
        try await notificationManager.schedule(notification)
    }
    
    func sendInAppMessage(_ message: InAppMessage) async throws {
        logger.info("Sending in-app message: \(message.title)")
        try await messageManager.send(message)
    }
    
    func logEngagementEvent(_ event: EngagementEvent) {
        logger.info("Logging engagement event: \(event.eventType.rawValue)")
        analyticsManager.log(event)
    }
    
    func triggerGamification(for user: UserProfile, event: GamificationEvent) async throws {
        logger.info("Triggering gamification event: \(event.type.rawValue)")
        try await gamificationManager.process(user: user, event: event)
    }
    
    func personalizeEngagement(for user: UserProfile) async throws -> EngagementProfile {
        logger.info("Personalizing engagement for user: \(user.id)")
        return try await personalizationManager.generateProfile(for: user)
    }
}

// MARK: - Notification Manager
class NotificationManager {
    func schedule(_ notification: EngagementNotification) async throws {
        let content = UNMutableNotificationContent()
        content.title = notification.title
        content.body = notification.body
        content.userInfo = notification.metadata
        content.categoryIdentifier = notification.category.rawValue
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(notification.triggerDate.timeIntervalSinceNow, 1), repeats: false)
        let request = UNNotificationRequest(identifier: notification.id, content: content, trigger: trigger)
        try await UNUserNotificationCenter.current().add(request)
    }
}

// MARK: - Message Manager
class MessageManager {
    func send(_ message: InAppMessage) async throws {
        // In a real implementation, this would update app state/UI
        // Here, we simulate delivery
        print("In-app message sent: \(message.title)")
    }
}

// MARK: - Analytics Manager
class EngagementAnalyticsManager {
    func log(_ event: EngagementEvent) {
        // Log event to analytics backend
        print("Engagement event logged: \(event.eventType.rawValue)")
    }
}

// MARK: - Gamification Manager
class GamificationManager {
    func process(user: UserProfile, event: GamificationEvent) async throws {
        // Update user profile with points, badges, streaks, etc.
        print("Gamification event processed: \(event.type.rawValue) for user \(user.id)")
    }
}

// MARK: - Personalization Manager
class EngagementPersonalizationManager {
    func generateProfile(for user: UserProfile) async throws -> EngagementProfile {
        // Analyze user data and generate engagement profile
        return EngagementProfile(
            userID: user.id,
            engagementScore: Double.random(in: 0.5...1.0),
            preferredChannels: [.push, .inApp],
            lastActive: Date(),
            badges: ["Starter", "Streak 3 Days"],
            streak: Int.random(in: 1...10),
            recommendations: ["Try the new meditation feature!", "Complete your health profile for rewards."]
        )
    }
} 
import Foundation
import UserNotifications
import Combine
import os.log

/// Comprehensive notification and reminder system for HealthAI 2030
/// Handles local notifications, push notifications, user preferences, and privacy controls
@MainActor
public class NotificationManager: NSObject, ObservableObject {
    
    // MARK: - Singleton
    public static let shared = NotificationManager()
    
    // MARK: - Published Properties
    @Published public var isAuthorized: Bool = false
    @Published public var notificationSettings: NotificationSettings = NotificationSettings()
    @Published public var activeReminders: [HealthReminder] = []
    @Published public var notificationHistory: [NotificationRecord] = []
    
    // MARK: - Private Properties
    private let notificationCenter = UNUserNotificationCenter.current()
    private let logger = Logger(subsystem: "com.healthai2030.notifications", category: "NotificationManager")
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Notification Categories
    private let notificationCategories: Set<UNNotificationCategory> = [
        // Health Alerts
        UNNotificationCategory(
            identifier: "HEALTH_ALERT_CRITICAL",
            actions: [
                UNNotificationAction(identifier: "VIEW_DETAILS", title: "View Details", options: [.foreground]),
                UNNotificationAction(identifier: "CALL_EMERGENCY", title: "Call Emergency", options: [.foreground, .destructive]),
                UNNotificationAction(identifier: "DISMISS", title: "Dismiss", options: [])
            ],
            intentIdentifiers: [],
            options: [.customDismissAction]
        ),
        
        // Health Alerts - Urgent
        UNNotificationCategory(
            identifier: "HEALTH_ALERT_URGENT",
            actions: [
                UNNotificationAction(identifier: "VIEW_DETAILS", title: "View Details", options: [.foreground]),
                UNNotificationAction(identifier: "SCHEDULE_APPOINTMENT", title: "Schedule Appointment", options: [.foreground]),
                UNNotificationAction(identifier: "DISMISS", title: "Dismiss", options: [])
            ],
            intentIdentifiers: [],
            options: [.customDismissAction]
        ),
        
        // Health Alerts - Normal
        UNNotificationCategory(
            identifier: "HEALTH_ALERT_NORMAL",
            actions: [
                UNNotificationAction(identifier: "VIEW_DETAILS", title: "View Details", options: [.foreground]),
                UNNotificationAction(identifier: "DISMISS", title: "Dismiss", options: [])
            ],
            intentIdentifiers: [],
            options: [.customDismissAction]
        ),
        
        // Reminders
        UNNotificationCategory(
            identifier: "HEALTH_REMINDER",
            actions: [
                UNNotificationAction(identifier: "COMPLETE", title: "Mark Complete", options: [.foreground]),
                UNNotificationAction(identifier: "SNOOZE", title: "Snooze 15min", options: []),
                UNNotificationAction(identifier: "DISMISS", title: "Dismiss", options: [])
            ],
            intentIdentifiers: [],
            options: [.customDismissAction]
        ),
        
        // Achievements
        UNNotificationCategory(
            identifier: "HEALTH_ACHIEVEMENT",
            actions: [
                UNNotificationAction(identifier: "VIEW_ACHIEVEMENT", title: "View Achievement", options: [.foreground]),
                UNNotificationAction(identifier: "SHARE", title: "Share", options: [.foreground]),
                UNNotificationAction(identifier: "DISMISS", title: "Dismiss", options: [])
            ],
            intentIdentifiers: [],
            options: [.customDismissAction]
        ),
        
        // Weekly Reports
        UNNotificationCategory(
            identifier: "WEEKLY_REPORT",
            actions: [
                UNNotificationAction(identifier: "VIEW_REPORT", title: "View Report", options: [.foreground]),
                UNNotificationAction(identifier: "SHARE_REPORT", title: "Share Report", options: [.foreground]),
                UNNotificationAction(identifier: "DISMISS", title: "Dismiss", options: [])
            ],
            intentIdentifiers: [],
            options: [.customDismissAction]
        ),
        
        // Sleep Tracking
        UNNotificationCategory(
            identifier: "SLEEP_TRACKING",
            actions: [
                UNNotificationAction(identifier: "START_TRACKING", title: "Start Tracking", options: [.foreground]),
                UNNotificationAction(identifier: "VIEW_SLEEP_DATA", title: "View Sleep Data", options: [.foreground]),
                UNNotificationAction(identifier: "DISMISS", title: "Dismiss", options: [])
            ],
            intentIdentifiers: [],
            options: [.customDismissAction]
        ),
        
        // Medication Reminders
        UNNotificationCategory(
            identifier: "MEDICATION_REMINDER",
            actions: [
                UNNotificationAction(identifier: "TAKE_MEDICATION", title: "Take Medication", options: [.foreground]),
                UNNotificationAction(identifier: "SKIP_DOSE", title: "Skip Dose", options: []),
                UNNotificationAction(identifier: "SNOOZE", title: "Snooze 30min", options: []),
                UNNotificationAction(identifier: "DISMISS", title: "Dismiss", options: [])
            ],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )
    ]
    
    // MARK: - Initialization
    private override init() {
        super.init()
        setupNotificationCenter()
        loadNotificationSettings()
        setupNotificationHandling()
    }
    
    // MARK: - Setup
    
    private func setupNotificationCenter() {
        notificationCenter.delegate = self
        notificationCenter.setNotificationCategories(notificationCategories)
    }
    
    private func setupNotificationHandling() {
        // Handle notification actions
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleNotificationAction),
            name: NSNotification.Name("NotificationAction"),
            object: nil
        )
    }
    
    // MARK: - Authorization
    
    /// Request notification permissions
    public func requestAuthorization() async throws {
        logger.info("Requesting notification authorization")
        
        let options: UNAuthorizationOptions = [
            .alert,
            .badge,
            .sound,
            .criticalAlert,
            .provisional
        ]
        
        let granted = try await notificationCenter.requestAuthorization(options: options)
        
        await MainActor.run {
            self.isAuthorized = granted
            self.notificationSettings.isAuthorized = granted
            self.saveNotificationSettings()
        }
        
        if granted {
            logger.info("Notification authorization granted")
        } else {
            logger.warning("Notification authorization denied")
        }
    }
    
    /// Check current authorization status
    public func checkAuthorizationStatus() async {
        let settings = await notificationCenter.notificationSettings()
        
        await MainActor.run {
            self.isAuthorized = settings.authorizationStatus == .authorized
            self.notificationSettings.isAuthorized = self.isAuthorized
        }
    }
    
    // MARK: - Notification Sending
    
    /// Send a health alert notification
    public func sendHealthAlert(
        title: String,
        body: String,
        severity: HealthAlertSeverity,
        userInfo: [String: Any]? = nil
    ) async throws {
        guard isAuthorized else {
            throw NotificationError.notAuthorized
        }
        
        guard notificationSettings.healthAlertsEnabled else {
            logger.info("Health alerts disabled by user preference")
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = severity == .critical ? .defaultCritical : .default
        content.categoryIdentifier = "HEALTH_ALERT_\(severity.rawValue.uppercased())"
        
        if severity == .critical {
            content.interruptionLevel = .critical
        }
        
        if let userInfo = userInfo {
            content.userInfo = userInfo
        }
        
        let request = UNNotificationRequest(
            identifier: "health-alert-\(UUID().uuidString)",
            content: content,
            trigger: nil
        )
        
        try await notificationCenter.add(request)
        
        // Record notification
        let record = NotificationRecord(
            id: UUID(),
            type: .healthAlert,
            title: title,
            body: body,
            severity: severity,
            timestamp: Date(),
            userInfo: userInfo
        )
        
        await MainActor.run {
            notificationHistory.append(record)
        }
        
        logger.info("Health alert notification sent: \(title)")
    }
    
    /// Send a reminder notification
    public func sendReminder(
        title: String,
        body: String,
        reminderType: ReminderType,
        scheduledDate: Date,
        userInfo: [String: Any]? = nil
    ) async throws {
        guard isAuthorized else {
            throw NotificationError.notAuthorized
        }
        
        guard notificationSettings.remindersEnabled else {
            logger.info("Reminders disabled by user preference")
            return
        }
        
        // Check quiet hours
        if isInQuietHours() && !reminderType.isQuietHoursExempt {
            logger.info("Reminder suppressed due to quiet hours: \(title)")
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.categoryIdentifier = "HEALTH_REMINDER"
        
        if let userInfo = userInfo {
            content.userInfo = userInfo
        }
        
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: scheduledDate.timeIntervalSinceNow,
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: "reminder-\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )
        
        try await notificationCenter.add(request)
        
        // Create reminder record
        let reminder = HealthReminder(
            id: UUID(),
            type: reminderType,
            title: title,
            body: body,
            scheduledDate: scheduledDate,
            isCompleted: false,
            userInfo: userInfo
        )
        
        await MainActor.run {
            activeReminders.append(reminder)
        }
        
        logger.info("Reminder scheduled: \(title) for \(scheduledDate)")
    }
    
    /// Send an achievement notification
    public func sendAchievement(
        title: String,
        body: String,
        achievementType: AchievementType,
        userInfo: [String: Any]? = nil
    ) async throws {
        guard isAuthorized else {
            throw NotificationError.notAuthorized
        }
        
        guard notificationSettings.achievementsEnabled else {
            logger.info("Achievement notifications disabled by user preference")
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.categoryIdentifier = "HEALTH_ACHIEVEMENT"
        
        if let userInfo = userInfo {
            content.userInfo = userInfo
        }
        
        let request = UNNotificationRequest(
            identifier: "achievement-\(UUID().uuidString)",
            content: content,
            trigger: nil
        )
        
        try await notificationCenter.add(request)
        
        // Record notification
        let record = NotificationRecord(
            id: UUID(),
            type: .achievement,
            title: title,
            body: body,
            severity: .normal,
            timestamp: Date(),
            userInfo: userInfo
        )
        
        await MainActor.run {
            notificationHistory.append(record)
        }
        
        logger.info("Achievement notification sent: \(title)")
    }
    
    /// Send a weekly report notification
    public func sendWeeklyReport(
        title: String,
        body: String,
        reportData: [String: Any]? = nil
    ) async throws {
        guard isAuthorized else {
            throw NotificationError.notAuthorized
        }
        
        guard notificationSettings.weeklyReportsEnabled else {
            logger.info("Weekly reports disabled by user preference")
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.categoryIdentifier = "WEEKLY_REPORT"
        
        if let reportData = reportData {
            content.userInfo = reportData
        }
        
        let request = UNNotificationRequest(
            identifier: "weekly-report-\(UUID().uuidString)",
            content: content,
            trigger: nil
        )
        
        try await notificationCenter.add(request)
        
        // Record notification
        let record = NotificationRecord(
            id: UUID(),
            type: .weeklyReport,
            title: title,
            body: body,
            severity: .normal,
            timestamp: Date(),
            userInfo: reportData
        )
        
        await MainActor.run {
            notificationHistory.append(record)
        }
        
        logger.info("Weekly report notification sent: \(title)")
    }
    
    // MARK: - Reminder Management
    
    /// Schedule a recurring reminder
    public func scheduleRecurringReminder(
        type: ReminderType,
        title: String,
        body: String,
        schedule: ReminderSchedule,
        userInfo: [String: Any]? = nil
    ) async throws {
        guard isAuthorized else {
            throw NotificationError.notAuthorized
        }
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.categoryIdentifier = "HEALTH_REMINDER"
        
        if let userInfo = userInfo {
            content.userInfo = userInfo
        }
        
        let trigger: UNNotificationTrigger
        
        switch schedule {
        case .daily(let time):
            let components = Calendar.current.dateComponents([.hour, .minute], from: time)
            trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            
        case .weekly(let weekday, let time):
            var components = Calendar.current.dateComponents([.hour, .minute], from: time)
            components.weekday = weekday
            trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            
        case .monthly(let day, let time):
            var components = Calendar.current.dateComponents([.hour, .minute], from: time)
            components.day = day
            trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        }
        
        let request = UNNotificationRequest(
            identifier: "recurring-\(type.rawValue)-\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )
        
        try await notificationCenter.add(request)
        
        logger.info("Recurring reminder scheduled: \(type.rawValue)")
    }
    
    /// Cancel a specific reminder
    public func cancelReminder(withId id: String) async {
        await notificationCenter.removePendingNotificationRequests(withIdentifiers: [id])
        
        await MainActor.run {
            activeReminders.removeAll { $0.id.uuidString == id }
        }
        
        logger.info("Reminder cancelled: \(id)")
    }
    
    /// Cancel all reminders of a specific type
    public func cancelReminders(ofType type: ReminderType) async {
        let requests = await notificationCenter.pendingNotificationRequests()
        let identifiersToRemove = requests.compactMap { request -> String? in
            if request.content.userInfo["reminderType"] as? String == type.rawValue {
                return request.identifier
            }
            return nil
        }
        
        await notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiersToRemove)
        
        await MainActor.run {
            activeReminders.removeAll { $0.type == type }
        }
        
        logger.info("Cancelled \(identifiersToRemove.count) reminders of type: \(type.rawValue)")
    }
    
    // MARK: - Settings Management
    
    /// Update notification settings
    public func updateSettings(_ settings: NotificationSettings) {
        self.notificationSettings = settings
        saveNotificationSettings()
        logger.info("Notification settings updated")
    }
    
    /// Load notification settings from UserDefaults
    private func loadNotificationSettings() {
        if let data = UserDefaults.standard.data(forKey: "NotificationSettings"),
           let settings = try? JSONDecoder().decode(NotificationSettings.self, from: data) {
            self.notificationSettings = settings
        }
    }
    
    /// Save notification settings to UserDefaults
    private func saveNotificationSettings() {
        if let data = try? JSONEncoder().encode(notificationSettings) {
            UserDefaults.standard.set(data, forKey: "NotificationSettings")
        }
    }
    
    // MARK: - Privacy & Quiet Hours
    
    /// Check if current time is in quiet hours
    private func isInQuietHours() -> Bool {
        guard let quietHours = notificationSettings.quietHours else {
            return false
        }
        
        let now = Date()
        let calendar = Calendar.current
        
        guard let startTime = calendar.date(bySettingHour: quietHours.start.hour,
                                          minute: quietHours.start.minute,
                                          second: 0,
                                          of: now),
              let endTime = calendar.date(bySettingHour: quietHours.end.hour,
                                        minute: quietHours.end.minute,
                                        second: 0,
                                        of: now) else {
            return false
        }
        
        // Handle quiet hours that span midnight
        if startTime > endTime {
            return now >= startTime || now <= endTime
        } else {
            return now >= startTime && now <= endTime
        }
    }
    
    // MARK: - Notification Action Handling
    
    @objc private func handleNotificationAction(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let action = userInfo["action"] as? String,
              let notificationId = userInfo["notificationId"] as? String else {
            return
        }
        
        logger.info("Notification action received: \(action) for notification: \(notificationId)")
        
        // Handle different actions
        switch action {
        case "VIEW_DETAILS":
            handleViewDetails(notificationId: notificationId, userInfo: userInfo)
        case "CALL_EMERGENCY":
            handleCallEmergency(notificationId: notificationId, userInfo: userInfo)
        case "COMPLETE":
            handleCompleteReminder(notificationId: notificationId, userInfo: userInfo)
        case "SNOOZE":
            handleSnoozeReminder(notificationId: notificationId, userInfo: userInfo)
        case "SHARE":
            handleShareAchievement(notificationId: notificationId, userInfo: userInfo)
        default:
            logger.warning("Unknown notification action: \(action)")
        }
    }
    
    private func handleViewDetails(notificationId: String, userInfo: [String: Any]) {
        // Navigate to details view
        NotificationCenter.default.post(
            name: NSNotification.Name("NavigateToHealthDetails"),
            object: nil,
            userInfo: userInfo
        )
    }
    
    private func handleCallEmergency(notificationId: String, userInfo: [String: Any]) {
        // Call emergency services
        if let phoneNumber = userInfo["emergencyPhone"] as? String {
            if let url = URL(string: "tel:\(phoneNumber)") {
                UIApplication.shared.open(url)
            }
        }
    }
    
    private func handleCompleteReminder(notificationId: String, userInfo: [String: Any]) {
        Task {
            await MainActor.run {
                if let index = activeReminders.firstIndex(where: { $0.id.uuidString == notificationId }) {
                    activeReminders[index].isCompleted = true
                }
            }
        }
    }
    
    private func handleSnoozeReminder(notificationId: String, userInfo: [String: Any]) {
        // Reschedule reminder for later
        Task {
            let snoozeInterval: TimeInterval = 15 * 60 // 15 minutes
            let newDate = Date().addingTimeInterval(snoozeInterval)
            
            if let reminder = activeReminders.first(where: { $0.id.uuidString == notificationId }) {
                try? await sendReminder(
                    title: reminder.title,
                    body: reminder.body,
                    reminderType: reminder.type,
                    scheduledDate: newDate,
                    userInfo: reminder.userInfo
                )
            }
        }
    }
    
    private func handleShareAchievement(notificationId: String, userInfo: [String: Any]) {
        // Share achievement
        NotificationCenter.default.post(
            name: NSNotification.Name("ShareAchievement"),
            object: nil,
            userInfo: userInfo
        )
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationManager: UNUserNotificationCenterDelegate {
    
    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }
    
    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        let action = response.actionIdentifier
        
        // Post notification for action handling
        NotificationCenter.default.post(
            name: NSNotification.Name("NotificationAction"),
            object: nil,
            userInfo: [
                "action": action,
                "notificationId": response.notification.request.identifier,
                "userInfo": userInfo
            ]
        )
        
        completionHandler()
    }
}

// MARK: - Data Models

/// Notification settings for user preferences
public struct NotificationSettings: Codable {
    public var isAuthorized: Bool = false
    public var healthAlertsEnabled: Bool = true
    public var remindersEnabled: Bool = true
    public var achievementsEnabled: Bool = true
    public var weeklyReportsEnabled: Bool = true
    public var sleepTrackingEnabled: Bool = true
    public var medicationRemindersEnabled: Bool = true
    public var quietHours: QuietHours?
    public var maxNotificationsPerDay: Int = 20
    public var soundEnabled: Bool = true
    public var vibrationEnabled: Bool = true
    
    public init() {}
}

/// Quiet hours configuration
public struct QuietHours: Codable {
    public let start: TimeOfDay
    public let end: TimeOfDay
    
    public init(start: TimeOfDay, end: TimeOfDay) {
        self.start = start
        self.end = end
    }
}

/// Time of day representation
public struct TimeOfDay: Codable {
    public let hour: Int
    public let minute: Int
    
    public init(hour: Int, minute: Int) {
        self.hour = max(0, min(23, hour))
        self.minute = max(0, min(59, minute))
    }
}

/// Health alert severity levels
public enum HealthAlertSeverity: String, Codable, CaseIterable {
    case critical = "critical"
    case urgent = "urgent"
    case normal = "normal"
}

/// Reminder types
public enum ReminderType: String, Codable, CaseIterable {
    case medication = "medication"
    case exercise = "exercise"
    case hydration = "hydration"
    case sleep = "sleep"
    case appointment = "appointment"
    case healthCheck = "healthCheck"
    case mindfulness = "mindfulness"
    
    var isQuietHoursExempt: Bool {
        switch self {
        case .medication, .healthCheck:
            return true
        default:
            return false
        }
    }
}

/// Reminder schedule types
public enum ReminderSchedule {
    case daily(TimeOfDay)
    case weekly(Int, TimeOfDay) // weekday, time
    case monthly(Int, TimeOfDay) // day of month, time
}

/// Achievement types
public enum AchievementType: String, Codable, CaseIterable {
    case stepGoal = "stepGoal"
    case sleepGoal = "sleepGoal"
    case exerciseStreak = "exerciseStreak"
    case mindfulnessStreak = "mindfulnessStreak"
    case weightGoal = "weightGoal"
    case healthMilestone = "healthMilestone"
}

/// Health reminder model
public struct HealthReminder: Identifiable, Codable {
    public let id: UUID
    public let type: ReminderType
    public let title: String
    public let body: String
    public let scheduledDate: Date
    public var isCompleted: Bool
    public let userInfo: [String: Any]?
    
    public init(id: UUID = UUID(), type: ReminderType, title: String, body: String, scheduledDate: Date, isCompleted: Bool = false, userInfo: [String: Any]? = nil) {
        self.id = id
        self.type = type
        self.title = title
        self.body = body
        self.scheduledDate = scheduledDate
        self.isCompleted = isCompleted
        self.userInfo = userInfo
    }
}

/// Notification record for history
public struct NotificationRecord: Identifiable, Codable {
    public let id: UUID
    public let type: NotificationType
    public let title: String
    public let body: String
    public let severity: HealthAlertSeverity
    public let timestamp: Date
    public let userInfo: [String: Any]?
    
    public init(id: UUID = UUID(), type: NotificationType, title: String, body: String, severity: HealthAlertSeverity, timestamp: Date, userInfo: [String: Any]? = nil) {
        self.id = id
        self.type = type
        self.title = title
        self.body = body
        self.severity = severity
        self.timestamp = timestamp
        self.userInfo = userInfo
    }
}

/// Notification types
public enum NotificationType: String, Codable, CaseIterable {
    case healthAlert = "healthAlert"
    case reminder = "reminder"
    case achievement = "achievement"
    case weeklyReport = "weeklyReport"
    case sleepTracking = "sleepTracking"
    case medicationReminder = "medicationReminder"
}

/// Notification errors
public enum NotificationError: Error, LocalizedError {
    case notAuthorized
    case invalidSchedule
    case quietHoursActive
    case dailyLimitExceeded
    
    public var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return "Notification permissions not granted"
        case .invalidSchedule:
            return "Invalid notification schedule"
        case .quietHoursActive:
            return "Notification suppressed due to quiet hours"
        case .dailyLimitExceeded:
            return "Daily notification limit exceeded"
        }
    }
} 
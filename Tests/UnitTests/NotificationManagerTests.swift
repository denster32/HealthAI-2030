import XCTest
import UserNotifications
import Combine
@testable import HealthAI2030Core

@MainActor
final class NotificationManagerTests: XCTestCase {
    
    var notificationManager: NotificationManager!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        notificationManager = NotificationManager.shared
        cancellables = Set<AnyCancellable>()
        
        // Clear any existing notifications
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }
    
    override func tearDown() {
        cancellables = nil
        super.tearDown()
    }
    
    // MARK: - Authorization Tests
    
    func testRequestAuthorization() async throws {
        // Test authorization request
        do {
            try await notificationManager.requestAuthorization()
            XCTAssertTrue(notificationManager.isAuthorized)
            XCTAssertTrue(notificationManager.notificationSettings.isAuthorized)
        } catch {
            // Authorization might be denied in test environment
            XCTAssertFalse(notificationManager.isAuthorized)
        }
    }
    
    func testCheckAuthorizationStatus() async {
        await notificationManager.checkAuthorizationStatus()
        
        // Should update the authorization status
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        let expectedStatus = settings.authorizationStatus == .authorized
        
        XCTAssertEqual(notificationManager.isAuthorized, expectedStatus)
        XCTAssertEqual(notificationManager.notificationSettings.isAuthorized, expectedStatus)
    }
    
    // MARK: - Notification Settings Tests
    
    func testNotificationSettingsPersistence() {
        // Test initial settings
        let initialSettings = NotificationSettings()
        XCTAssertTrue(initialSettings.healthAlertsEnabled)
        XCTAssertTrue(initialSettings.remindersEnabled)
        XCTAssertTrue(initialSettings.achievementsEnabled)
        
        // Update settings
        var updatedSettings = initialSettings
        updatedSettings.healthAlertsEnabled = false
        updatedSettings.remindersEnabled = false
        updatedSettings.quietHours = QuietHours(start: TimeOfDay(hour: 22, minute: 0), end: TimeOfDay(hour: 7, minute: 0))
        
        notificationManager.updateSettings(updatedSettings)
        
        // Verify settings were updated
        XCTAssertFalse(notificationManager.notificationSettings.healthAlertsEnabled)
        XCTAssertFalse(notificationManager.notificationSettings.remindersEnabled)
        XCTAssertNotNil(notificationManager.notificationSettings.quietHours)
        XCTAssertEqual(notificationManager.notificationSettings.quietHours?.start.hour, 22)
        XCTAssertEqual(notificationManager.notificationSettings.quietHours?.end.hour, 7)
    }
    
    func testQuietHoursConfiguration() {
        let quietHours = QuietHours(start: TimeOfDay(hour: 22, minute: 0), end: TimeOfDay(hour: 7, minute: 0))
        
        var settings = NotificationSettings()
        settings.quietHours = quietHours
        notificationManager.updateSettings(settings)
        
        XCTAssertNotNil(notificationManager.notificationSettings.quietHours)
        XCTAssertEqual(notificationManager.notificationSettings.quietHours?.start.hour, 22)
        XCTAssertEqual(notificationManager.notificationSettings.quietHours?.end.hour, 7)
    }
    
    // MARK: - Health Alert Tests
    
    func testSendHealthAlertCritical() async throws {
        // Skip if not authorized
        guard notificationManager.isAuthorized else {
            throw XCTSkip("Notification authorization required for this test")
        }
        
        let title = "Critical Health Alert"
        let body = "Your heart rate is dangerously high"
        let severity = HealthAlertSeverity.critical
        let userInfo = ["heartRate": 120, "timestamp": Date().timeIntervalSince1970]
        
        try await notificationManager.sendHealthAlert(
            title: title,
            body: body,
            severity: severity,
            userInfo: userInfo
        )
        
        // Verify notification was recorded
        XCTAssertEqual(notificationManager.notificationHistory.count, 1)
        let record = notificationManager.notificationHistory.first!
        XCTAssertEqual(record.title, title)
        XCTAssertEqual(record.body, body)
        XCTAssertEqual(record.severity, severity)
        XCTAssertEqual(record.type, .healthAlert)
    }
    
    func testSendHealthAlertUrgent() async throws {
        // Skip if not authorized
        guard notificationManager.isAuthorized else {
            throw XCTSkip("Notification authorization required for this test")
        }
        
        let title = "Urgent Health Alert"
        let body = "Your blood pressure is elevated"
        let severity = HealthAlertSeverity.urgent
        
        try await notificationManager.sendHealthAlert(
            title: title,
            body: body,
            severity: severity
        )
        
        XCTAssertEqual(notificationManager.notificationHistory.count, 1)
        let record = notificationManager.notificationHistory.first!
        XCTAssertEqual(record.severity, .urgent)
    }
    
    func testSendHealthAlertNormal() async throws {
        // Skip if not authorized
        guard notificationManager.isAuthorized else {
            throw XCTSkip("Notification authorization required for this test")
        }
        
        let title = "Normal Health Alert"
        let body = "Your daily step goal is 80% complete"
        let severity = HealthAlertSeverity.normal
        
        try await notificationManager.sendHealthAlert(
            title: title,
            body: body,
            severity: severity
        )
        
        XCTAssertEqual(notificationManager.notificationHistory.count, 1)
        let record = notificationManager.notificationHistory.first!
        XCTAssertEqual(record.severity, .normal)
    }
    
    func testSendHealthAlertWhenDisabled() async throws {
        // Disable health alerts
        var settings = notificationManager.notificationSettings
        settings.healthAlertsEnabled = false
        notificationManager.updateSettings(settings)
        
        let title = "Test Alert"
        let body = "This should not be sent"
        let severity = HealthAlertSeverity.normal
        
        // Should not throw error but should not send notification
        try await notificationManager.sendHealthAlert(
            title: title,
            body: body,
            severity: severity
        )
        
        // Notification history should not be updated
        XCTAssertEqual(notificationManager.notificationHistory.count, 0)
    }
    
    // MARK: - Reminder Tests
    
    func testSendReminder() async throws {
        // Skip if not authorized
        guard notificationManager.isAuthorized else {
            throw XCTSkip("Notification authorization required for this test")
        }
        
        let title = "Medication Reminder"
        let body = "Time to take your medication"
        let reminderType = ReminderType.medication
        let scheduledDate = Date().addingTimeInterval(60) // 1 minute from now
        let userInfo = ["medicationId": "med123", "dosage": "10mg"]
        
        try await notificationManager.sendReminder(
            title: title,
            body: body,
            reminderType: reminderType,
            scheduledDate: scheduledDate,
            userInfo: userInfo
        )
        
        // Verify reminder was added
        XCTAssertEqual(notificationManager.activeReminders.count, 1)
        let reminder = notificationManager.activeReminders.first!
        XCTAssertEqual(reminder.title, title)
        XCTAssertEqual(reminder.body, body)
        XCTAssertEqual(reminder.type, reminderType)
        XCTAssertFalse(reminder.isCompleted)
    }
    
    func testSendReminderWhenDisabled() async throws {
        // Disable reminders
        var settings = notificationManager.notificationSettings
        settings.remindersEnabled = false
        notificationManager.updateSettings(settings)
        
        let title = "Test Reminder"
        let body = "This should not be sent"
        let reminderType = ReminderType.exercise
        let scheduledDate = Date().addingTimeInterval(60)
        
        // Should not throw error but should not schedule reminder
        try await notificationManager.sendReminder(
            title: title,
            body: body,
            reminderType: reminderType,
            scheduledDate: scheduledDate
        )
        
        // Active reminders should not be updated
        XCTAssertEqual(notificationManager.activeReminders.count, 0)
    }
    
    func testSendReminderInQuietHours() async throws {
        // Skip if not authorized
        guard notificationManager.isAuthorized else {
            throw XCTSkip("Notification authorization required for this test")
        }
        
        // Set quiet hours
        var settings = notificationManager.notificationSettings
        settings.quietHours = QuietHours(start: TimeOfDay(hour: 0, minute: 0), end: TimeOfDay(hour: 23, minute: 59))
        notificationManager.updateSettings(settings)
        
        let title = "Exercise Reminder"
        let body = "Time to exercise"
        let reminderType = ReminderType.exercise // Not quiet hours exempt
        let scheduledDate = Date().addingTimeInterval(60)
        
        // Should not throw error but should not schedule reminder
        try await notificationManager.sendReminder(
            title: title,
            body: body,
            reminderType: reminderType,
            scheduledDate: scheduledDate
        )
        
        // Active reminders should not be updated
        XCTAssertEqual(notificationManager.activeReminders.count, 0)
    }
    
    func testSendReminderQuietHoursExempt() async throws {
        // Skip if not authorized
        guard notificationManager.isAuthorized else {
            throw XCTSkip("Notification authorization required for this test")
        }
        
        // Set quiet hours
        var settings = notificationManager.notificationSettings
        settings.quietHours = QuietHours(start: TimeOfDay(hour: 0, minute: 0), end: TimeOfDay(hour: 23, minute: 59))
        notificationManager.updateSettings(settings)
        
        let title = "Medication Reminder"
        let body = "Time to take medication"
        let reminderType = ReminderType.medication // Quiet hours exempt
        let scheduledDate = Date().addingTimeInterval(60)
        
        try await notificationManager.sendReminder(
            title: title,
            body: body,
            reminderType: reminderType,
            scheduledDate: scheduledDate
        )
        
        // Should be scheduled even in quiet hours
        XCTAssertEqual(notificationManager.activeReminders.count, 1)
    }
    
    // MARK: - Achievement Tests
    
    func testSendAchievement() async throws {
        // Skip if not authorized
        guard notificationManager.isAuthorized else {
            throw XCTSkip("Notification authorization required for this test")
        }
        
        let title = "Step Goal Achieved!"
        let body = "Congratulations! You've reached your daily step goal"
        let achievementType = AchievementType.stepGoal
        let userInfo = ["steps": 10000, "goal": 8000]
        
        try await notificationManager.sendAchievement(
            title: title,
            body: body,
            achievementType: achievementType,
            userInfo: userInfo
        )
        
        // Verify notification was recorded
        XCTAssertEqual(notificationManager.notificationHistory.count, 1)
        let record = notificationManager.notificationHistory.first!
        XCTAssertEqual(record.title, title)
        XCTAssertEqual(record.body, body)
        XCTAssertEqual(record.type, .achievement)
        XCTAssertEqual(record.severity, .normal)
    }
    
    func testSendAchievementWhenDisabled() async throws {
        // Disable achievements
        var settings = notificationManager.notificationSettings
        settings.achievementsEnabled = false
        notificationManager.updateSettings(settings)
        
        let title = "Test Achievement"
        let body = "This should not be sent"
        let achievementType = AchievementType.sleepGoal
        
        // Should not throw error but should not send notification
        try await notificationManager.sendAchievement(
            title: title,
            body: body,
            achievementType: achievementType
        )
        
        // Notification history should not be updated
        XCTAssertEqual(notificationManager.notificationHistory.count, 0)
    }
    
    // MARK: - Weekly Report Tests
    
    func testSendWeeklyReport() async throws {
        // Skip if not authorized
        guard notificationManager.isAuthorized else {
            throw XCTSkip("Notification authorization required for this test")
        }
        
        let title = "Weekly Health Report"
        let body = "Your health summary for this week is ready"
        let reportData = ["avgSteps": 8500, "avgSleep": 7.5, "achievements": 3]
        
        try await notificationManager.sendWeeklyReport(
            title: title,
            body: body,
            reportData: reportData
        )
        
        // Verify notification was recorded
        XCTAssertEqual(notificationManager.notificationHistory.count, 1)
        let record = notificationManager.notificationHistory.first!
        XCTAssertEqual(record.title, title)
        XCTAssertEqual(record.body, body)
        XCTAssertEqual(record.type, .weeklyReport)
    }
    
    func testSendWeeklyReportWhenDisabled() async throws {
        // Disable weekly reports
        var settings = notificationManager.notificationSettings
        settings.weeklyReportsEnabled = false
        notificationManager.updateSettings(settings)
        
        let title = "Test Weekly Report"
        let body = "This should not be sent"
        
        // Should not throw error but should not send notification
        try await notificationManager.sendWeeklyReport(
            title: title,
            body: body
        )
        
        // Notification history should not be updated
        XCTAssertEqual(notificationManager.notificationHistory.count, 0)
    }
    
    // MARK: - Reminder Management Tests
    
    func testScheduleRecurringReminder() async throws {
        // Skip if not authorized
        guard notificationManager.isAuthorized else {
            throw XCTSkip("Notification authorization required for this test")
        }
        
        let type = ReminderType.exercise
        let title = "Daily Exercise"
        let body = "Time for your daily workout"
        let schedule = ReminderSchedule.daily(TimeOfDay(hour: 18, minute: 0))
        let userInfo = ["workoutType": "cardio"]
        
        try await notificationManager.scheduleRecurringReminder(
            type: type,
            title: title,
            body: body,
            schedule: schedule,
            userInfo: userInfo
        )
        
        // Verify reminder was scheduled
        let requests = await UNUserNotificationCenter.current().pendingNotificationRequests()
        XCTAssertGreaterThan(requests.count, 0)
        
        let exerciseRequests = requests.filter { request in
            request.content.userInfo["reminderType"] as? String == type.rawValue
        }
        XCTAssertGreaterThan(exerciseRequests.count, 0)
    }
    
    func testCancelReminder() async throws {
        // Skip if not authorized
        guard notificationManager.isAuthorized else {
            throw XCTSkip("Notification authorization required for this test")
        }
        
        // Add a reminder
        let title = "Test Reminder"
        let body = "Test body"
        let reminderType = ReminderType.hydration
        let scheduledDate = Date().addingTimeInterval(300) // 5 minutes
        
        try await notificationManager.sendReminder(
            title: title,
            body: body,
            reminderType: reminderType,
            scheduledDate: scheduledDate
        )
        
        XCTAssertEqual(notificationManager.activeReminders.count, 1)
        let reminderId = notificationManager.activeReminders.first!.id.uuidString
        
        // Cancel the reminder
        await notificationManager.cancelReminder(withId: reminderId)
        
        // Verify reminder was removed
        XCTAssertEqual(notificationManager.activeReminders.count, 0)
        
        // Verify notification was removed from system
        let requests = await UNUserNotificationCenter.current().pendingNotificationRequests()
        let remainingRequests = requests.filter { $0.identifier == reminderId }
        XCTAssertEqual(remainingRequests.count, 0)
    }
    
    func testCancelRemindersByType() async throws {
        // Skip if not authorized
        guard notificationManager.isAuthorized else {
            throw XCTSkip("Notification authorization required for this test")
        }
        
        // Add multiple reminders of different types
        let medicationReminder = ReminderType.medication
        let exerciseReminder = ReminderType.exercise
        
        try await notificationManager.sendReminder(
            title: "Medication 1",
            body: "Take medication",
            reminderType: medicationReminder,
            scheduledDate: Date().addingTimeInterval(60)
        )
        
        try await notificationManager.sendReminder(
            title: "Medication 2",
            body: "Take medication",
            reminderType: medicationReminder,
            scheduledDate: Date().addingTimeInterval(120)
        )
        
        try await notificationManager.sendReminder(
            title: "Exercise",
            body: "Time to exercise",
            reminderType: exerciseReminder,
            scheduledDate: Date().addingTimeInterval(180)
        )
        
        XCTAssertEqual(notificationManager.activeReminders.count, 3)
        
        // Cancel all medication reminders
        await notificationManager.cancelReminders(ofType: medicationReminder)
        
        // Verify only medication reminders were removed
        XCTAssertEqual(notificationManager.activeReminders.count, 1)
        XCTAssertEqual(notificationManager.activeReminders.first?.type, exerciseReminder)
    }
    
    // MARK: - Data Model Tests
    
    func testTimeOfDayValidation() {
        // Test valid times
        let validTime = TimeOfDay(hour: 15, minute: 30)
        XCTAssertEqual(validTime.hour, 15)
        XCTAssertEqual(validTime.minute, 30)
        
        // Test boundary conditions
        let midnight = TimeOfDay(hour: 0, minute: 0)
        XCTAssertEqual(midnight.hour, 0)
        XCTAssertEqual(midnight.minute, 0)
        
        let endOfDay = TimeOfDay(hour: 23, minute: 59)
        XCTAssertEqual(endOfDay.hour, 23)
        XCTAssertEqual(endOfDay.minute, 59)
        
        // Test invalid times are clamped
        let invalidHour = TimeOfDay(hour: 25, minute: 30)
        XCTAssertEqual(invalidHour.hour, 23)
        
        let invalidMinute = TimeOfDay(hour: 15, minute: 70)
        XCTAssertEqual(invalidMinute.minute, 59)
    }
    
    func testReminderTypeQuietHoursExemption() {
        // Test quiet hours exempt types
        XCTAssertTrue(ReminderType.medication.isQuietHoursExempt)
        XCTAssertTrue(ReminderType.healthCheck.isQuietHoursExempt)
        
        // Test non-exempt types
        XCTAssertFalse(ReminderType.exercise.isQuietHoursExempt)
        XCTAssertFalse(ReminderType.hydration.isQuietHoursExempt)
        XCTAssertFalse(ReminderType.sleep.isQuietHoursExempt)
        XCTAssertFalse(ReminderType.appointment.isQuietHoursExempt)
        XCTAssertFalse(ReminderType.mindfulness.isQuietHoursExempt)
    }
    
    func testHealthReminderModel() {
        let id = UUID()
        let type = ReminderType.medication
        let title = "Test Reminder"
        let body = "Test body"
        let scheduledDate = Date()
        let userInfo = ["test": "value"]
        
        let reminder = HealthReminder(
            id: id,
            type: type,
            title: title,
            body: body,
            scheduledDate: scheduledDate,
            isCompleted: false,
            userInfo: userInfo
        )
        
        XCTAssertEqual(reminder.id, id)
        XCTAssertEqual(reminder.type, type)
        XCTAssertEqual(reminder.title, title)
        XCTAssertEqual(reminder.body, body)
        XCTAssertEqual(reminder.scheduledDate, scheduledDate)
        XCTAssertFalse(reminder.isCompleted)
        XCTAssertEqual(reminder.userInfo?["test"] as? String, "value")
    }
    
    func testNotificationRecordModel() {
        let id = UUID()
        let type = NotificationType.healthAlert
        let title = "Test Alert"
        let body = "Test body"
        let severity = HealthAlertSeverity.critical
        let timestamp = Date()
        let userInfo = ["test": "value"]
        
        let record = NotificationRecord(
            id: id,
            type: type,
            title: title,
            body: body,
            severity: severity,
            timestamp: timestamp,
            userInfo: userInfo
        )
        
        XCTAssertEqual(record.id, id)
        XCTAssertEqual(record.type, type)
        XCTAssertEqual(record.title, title)
        XCTAssertEqual(record.body, body)
        XCTAssertEqual(record.severity, severity)
        XCTAssertEqual(record.timestamp, timestamp)
        XCTAssertEqual(record.userInfo?["test"] as? String, "value")
    }
    
    // MARK: - Error Handling Tests
    
    func testNotificationErrorDescriptions() {
        let notAuthorized = NotificationError.notAuthorized
        XCTAssertEqual(notAuthorized.errorDescription, "Notification permissions not granted")
        
        let invalidSchedule = NotificationError.invalidSchedule
        XCTAssertEqual(invalidSchedule.errorDescription, "Invalid notification schedule")
        
        let quietHours = NotificationError.quietHoursActive
        XCTAssertEqual(quietHours.errorDescription, "Notification suppressed due to quiet hours")
        
        let dailyLimit = NotificationError.dailyLimitExceeded
        XCTAssertEqual(dailyLimit.errorDescription, "Daily notification limit exceeded")
    }
    
    // MARK: - Performance Tests
    
    func testNotificationSendingPerformance() async throws {
        // Skip if not authorized
        guard notificationManager.isAuthorized else {
            throw XCTSkip("Notification authorization required for this test")
        }
        
        measure {
            Task {
                for i in 0..<10 {
                    try? await notificationManager.sendHealthAlert(
                        title: "Performance Test \(i)",
                        body: "Test notification \(i)",
                        severity: .normal
                    )
                }
            }
        }
    }
    
    func testReminderSchedulingPerformance() async throws {
        // Skip if not authorized
        guard notificationManager.isAuthorized else {
            throw XCTSkip("Notification authorization required for this test")
        }
        
        measure {
            Task {
                for i in 0..<10 {
                    try? await notificationManager.sendReminder(
                        title: "Performance Reminder \(i)",
                        body: "Test reminder \(i)",
                        reminderType: .exercise,
                        scheduledDate: Date().addingTimeInterval(TimeInterval(i * 60))
                    )
                }
            }
        }
    }
} 
import UserNotifications
import WatchKit
import Foundation

class WatchNotificationManager: ObservableObject {
    static let shared = WatchNotificationManager()
    
    @Published var notificationPermissionGranted = false
    @Published var activeNotifications: [WatchNotification] = []
    
    private let notificationCenter = UNUserNotificationCenter.current()
    
    private init() {
        requestNotificationPermission()
        setupNotificationCategories()
    }
    
    // MARK: - Permission Management
    
    private func requestNotificationPermission() {
        notificationCenter.requestAuthorization(options: [.alert, .sound, .badge]) { [weak self] granted, error in
            DispatchQueue.main.async {
                self?.notificationPermissionGranted = granted
            }
            
            if let error = error {
                print("Notification permission error: \(error)")
            }
        }
    }
    
    private func setupNotificationCategories() {
        // Sleep reminder actions
        let sleepReminderCategory = UNNotificationCategory(
            identifier: "SLEEP_REMINDER",
            actions: [
                UNNotificationAction(identifier: "START_SLEEP", title: "Start Sleep Session", options: []),
                UNNotificationAction(identifier: "REMIND_LATER", title: "Remind in 30 min", options: [])
            ],
            intentIdentifiers: [],
            options: []
        )
        
        // Health alert actions
        let healthAlertCategory = UNNotificationCategory(
            identifier: "HEALTH_ALERT",
            actions: [
                UNNotificationAction(identifier: "CHECK_NOW", title: "Check Now", options: [.foreground]),
                UNNotificationAction(identifier: "DISMISS", title: "Dismiss", options: [])
            ],
            intentIdentifiers: [],
            options: []
        )
        
        // Wake optimization actions
        let wakeOptimizationCategory = UNNotificationCategory(
            identifier: "WAKE_OPTIMIZATION",
            actions: [
                UNNotificationAction(identifier: "WAKE_NOW", title: "Wake Up", options: [.foreground]),
                UNNotificationAction(identifier: "SNOOZE_5MIN", title: "5 more min", options: [])
            ],
            intentIdentifiers: [],
            options: []
        )
        
        notificationCenter.setNotificationCategories([
            sleepReminderCategory,
            healthAlertCategory,
            wakeOptimizationCategory
        ])
    }
    
    // MARK: - Notification Scheduling
    
    func scheduleSleepReminder(at time: Date) {
        let content = UNMutableNotificationContent()
        content.title = "Time for Sleep"
        content.body = "Your optimal bedtime is approaching. Start your sleep session?"
        content.sound = .default
        content.categoryIdentifier = "SLEEP_REMINDER"
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: time)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        
        let request = UNNotificationRequest(
            identifier: "sleep_reminder_\(time.timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("Failed to schedule sleep reminder: \(error)")
            }
        }
    }
    
    func scheduleHealthAlert(type: HealthAlertType, message: String, urgency: AlertUrgency = .medium) {
        let content = UNMutableNotificationContent()
        content.title = type.title
        content.body = message
        content.categoryIdentifier = "HEALTH_ALERT"
        
        // Set sound based on urgency
        switch urgency {
        case .low:
            content.sound = .default
        case .medium:
            content.sound = .defaultCritical
        case .high, .critical:
            content.sound = .defaultCriticalAlert
        }
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "health_alert_\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("Failed to schedule health alert: \(error)")
            }
        }
        
        // Add to active notifications
        let notification = WatchNotification(
            id: request.identifier,
            type: .healthAlert,
            title: content.title,
            message: content.body,
            urgency: urgency,
            timestamp: Date()
        )
        
        DispatchQueue.main.async {
            self.activeNotifications.append(notification)
        }
    }
    
    func scheduleOptimalWakeTime(at time: Date, sleepCycles: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Optimal Wake Time"
        content.body = "You've completed \(sleepCycles) sleep cycles. Ready to wake up?"
        content.sound = .default
        content.categoryIdentifier = "WAKE_OPTIMIZATION"
        
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: time.timeIntervalSinceNow,
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: "wake_optimization_\(time.timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("Failed to schedule wake optimization: \(error)")
            }
        }
    }
    
    func scheduleHeartRateAlert(heartRate: Double, threshold: Double, isHigh: Bool) {
        let alertType: HealthAlertType = isHigh ? .heartRateHigh : .heartRateLow
        let direction = isHigh ? "above" : "below"
        
        let message = "Your heart rate is \(Int(heartRate)) BPM, which is \(direction) your threshold of \(Int(threshold)) BPM."
        
        scheduleHealthAlert(
            type: alertType,
            message: message,
            urgency: isHigh ? .high : .medium
        )
    }
    
    func scheduleHRVAlert(hrv: Double, baseline: Double) {
        let deviation = ((hrv - baseline) / baseline) * 100
        
        if abs(deviation) > 20 {
            let direction = deviation > 0 ? "significantly higher" : "significantly lower"
            let message = "Your HRV is \(direction) than usual. Consider checking your recovery status."
            
            scheduleHealthAlert(
                type: .hrvAnomaly,
                message: message,
                urgency: .medium
            )
        }
    }
    
    // MARK: - Sleep Stage Notifications
    
    func notifySleepStageTransition(from oldStage: SleepStage, to newStage: SleepStage) {
        // Only notify for significant transitions
        guard shouldNotifyForTransition(from: oldStage, to: newStage) else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Sleep Stage Changed"
        content.body = "Transitioned from \(oldStage.displayName) to \(newStage.displayName)"
        content.sound = nil // Silent notification
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "sleep_transition_\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("Failed to send sleep transition notification: \(error)")
            }
        }
    }
    
    private func shouldNotifyForTransition(from oldStage: SleepStage, to newStage: SleepStage) -> Bool {
        // Don't notify transitions to/from unknown
        if oldStage == .unknown || newStage == .unknown { return false }
        
        // Don't notify during deep sleep to avoid disturbance
        if newStage == .deepSleep { return false }
        
        // Only notify significant transitions
        let significantTransitions: [(SleepStage, SleepStage)] = [
            (.awake, .lightSleep),
            (.lightSleep, .deepSleep),
            (.deepSleep, .remSleep),
            (.remSleep, .awake)
        ]
        
        return significantTransitions.contains { $0.0 == oldStage && $0.1 == newStage }
    }
    
    // MARK: - Environmental Notifications
    
    func notifyEnvironmentalChange(type: EnvironmentalAlert, value: Double, recommendation: String) {
        let content = UNMutableNotificationContent()
        content.title = type.title
        content.body = recommendation
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "environmental_\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("Failed to send environmental notification: \(error)")
            }
        }
    }
    
    // MARK: - Notification Management
    
    func cancelNotification(withIdentifier identifier: String) {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])
        notificationCenter.removeDeliveredNotifications(withIdentifiers: [identifier])
        
        DispatchQueue.main.async {
            self.activeNotifications.removeAll { $0.id == identifier }
        }
    }
    
    func cancelAllNotifications() {
        notificationCenter.removeAllPendingNotificationRequests()
        notificationCenter.removeAllDeliveredNotifications()
        
        DispatchQueue.main.async {
            self.activeNotifications.removeAll()
        }
    }
    
    func getActiveNotifications() -> [WatchNotification] {
        return activeNotifications
    }
    
    // MARK: - Notification Analytics
    
    func trackNotificationInteraction(identifier: String, action: String) {
        // Track how users interact with notifications for optimization
        print("Notification interaction: \(identifier) - \(action)")
        
        // This could be sent to analytics service
        let interactionData: [String: Any] = [
            "notificationId": identifier,
            "action": action,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        // Send to iPhone for analytics processing
        WatchConnectivityManager.shared.sendAnalyticsData(interactionData)
    }
}

// MARK: - Supporting Types

struct WatchNotification: Identifiable {
    let id: String
    let type: NotificationType
    let title: String
    let message: String
    let urgency: AlertUrgency
    let timestamp: Date
}

enum NotificationType {
    case sleepReminder
    case healthAlert
    case wakeOptimization
    case sleepStageTransition
    case environmental
}

enum HealthAlertType {
    case heartRateHigh
    case heartRateLow
    case hrvAnomaly
    case oxygenLow
    case temperatureAbnormal
    case sleepDisturbance
    
    var title: String {
        switch self {
        case .heartRateHigh:
            return "High Heart Rate"
        case .heartRateLow:
            return "Low Heart Rate"
        case .hrvAnomaly:
            return "HRV Anomaly"
        case .oxygenLow:
            return "Low Oxygen"
        case .temperatureAbnormal:
            return "Temperature Alert"
        case .sleepDisturbance:
            return "Sleep Disturbance"
        }
    }
}

enum EnvironmentalAlert {
    case temperatureHigh
    case temperatureLow
    case humidityHigh
    case humidityLow
    case noiseHigh
    case airQualityPoor
    
    var title: String {
        switch self {
        case .temperatureHigh:
            return "Room Too Warm"
        case .temperatureLow:
            return "Room Too Cool"
        case .humidityHigh:
            return "High Humidity"
        case .humidityLow:
            return "Low Humidity"
        case .noiseHigh:
            return "Noise Detected"
        case .airQualityPoor:
            return "Poor Air Quality"
        }
    }
}

enum AlertUrgency {
    case low
    case medium
    case high
    case critical
}
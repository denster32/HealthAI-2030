//
//  AnalyticsAlerts.swift
//  HealthAI 2030
//
//  Created by Agent 6 (Analytics) on 2025-01-14
//  Intelligent alerting system for analytics
//

import Foundation
import Combine
import UserNotifications

/// Intelligent alerting system for analytics events and anomalies
public class AnalyticsAlerts: ObservableObject {
    
    // MARK: - Properties
    
    @Published public var activeAlerts: [AnalyticsAlert] = []
    @Published public var alertHistory: [AnalyticsAlert] = []
    @Published public var alertSettings: AlertSettings = AlertSettings()
    @Published public var isMonitoring: Bool = false
    
    private var alertRules: [AlertRule] = []
    private var cancellables = Set<AnyCancellable>()
    private let notificationCenter = UNUserNotificationCenter.current()
    
    // MARK: - Initialization
    
    public init() {
        setupDefaultAlertRules()
        requestNotificationPermissions()
    }
    
    // MARK: - Alert Monitoring Methods
    
    /// Start alert monitoring
    public func startMonitoring() {
        isMonitoring = true
        setupAlertSubscriptions()
    }
    
    /// Stop alert monitoring
    public func stopMonitoring() {
        isMonitoring = false
        cancellables.removeAll()
    }
    
    /// Add custom alert rule
    public func addAlertRule(_ rule: AlertRule) {
        alertRules.append(rule)
    }
    
    /// Remove alert rule
    public func removeAlertRule(id: UUID) {
        alertRules.removeAll { $0.id == id }
    }
    
    /// Process data point for alerts
    public func processDataPoint(_ dataPoint: AnalyticsDataPoint) {
        for rule in alertRules {
            if rule.shouldTrigger(for: dataPoint) {
                let alert = createAlert(from: rule, dataPoint: dataPoint)
                triggerAlert(alert)
            }
        }
    }
    
    /// Create alert from rule and data point
    private func createAlert(from rule: AlertRule, dataPoint: AnalyticsDataPoint) -> AnalyticsAlert {
        return AnalyticsAlert(
            id: UUID(),
            timestamp: Date(),
            type: rule.type,
            severity: rule.severity,
            title: rule.title,
            message: generateAlertMessage(for: rule, dataPoint: dataPoint),
            dataPoint: dataPoint,
            rule: rule,
            isActive: true
        )
    }
    
    /// Generate alert message
    private func generateAlertMessage(for rule: AlertRule, dataPoint: AnalyticsDataPoint) -> String {
        switch rule.type {
        case .anomaly:
            return "Anomaly detected in \(dataPoint.metric): \(dataPoint.value) (\(rule.condition.description))"
        case .threshold:
            return "Threshold exceeded for \(dataPoint.metric): \(dataPoint.value) > \(rule.threshold)"
        case .trend:
            return "Concerning trend detected in \(dataPoint.metric)"
        case .prediction:
            return "Prediction alert for \(dataPoint.metric): Risk level elevated"
        case .quality:
            return "Data quality issue detected in \(dataPoint.metric)"
        case .performance:
            return "Performance degradation detected: \(dataPoint.metric)"
        }
    }
    
    /// Trigger alert
    private func triggerAlert(_ alert: AnalyticsAlert) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // Add to active alerts
            self.activeAlerts.append(alert)
            
            // Add to history
            self.alertHistory.append(alert)
            
            // Send notification if enabled
            if self.alertSettings.notificationsEnabled {
                self.sendNotification(for: alert)
            }
            
            // Auto-resolve if configured
            if alert.rule.autoResolve {
                DispatchQueue.main.asyncAfter(deadline: .now() + alert.rule.autoResolveDelay) {
                    self.resolveAlert(alert.id)
                }
            }
            
            // Cleanup history if needed
            self.cleanupAlertHistory()
        }
    }
    
    /// Send push notification for alert
    private func sendNotification(for alert: AnalyticsAlert) {
        let content = UNMutableNotificationContent()
        content.title = alert.title
        content.body = alert.message
        content.sound = alertSettings.soundEnabled ? .default : nil
        
        // Set category based on severity
        switch alert.severity {
        case .critical:
            content.categoryIdentifier = "CRITICAL_ALERT"
        case .high:
            content.categoryIdentifier = "HIGH_ALERT"
        case .medium:
            content.categoryIdentifier = "MEDIUM_ALERT"
        case .low:
            content.categoryIdentifier = "LOW_ALERT"
        }
        
        let request = UNNotificationRequest(
            identifier: alert.id.uuidString,
            content: content,
            trigger: nil
        )
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("Failed to send notification: \(error)")
            }
        }
    }
    
    /// Resolve alert
    public func resolveAlert(_ alertId: UUID) {
        if let index = activeAlerts.firstIndex(where: { $0.id == alertId }) {
            activeAlerts[index].resolve()
            activeAlerts.remove(at: index)
        }
    }
    
    /// Acknowledge alert
    public func acknowledgeAlert(_ alertId: UUID) {
        if let index = activeAlerts.firstIndex(where: { $0.id == alertId }) {
            activeAlerts[index].acknowledge()
        }
    }
    
    /// Clear all alerts
    public func clearAllAlerts() {
        activeAlerts.removeAll()
    }
    
    // MARK: - Alert Configuration
    
    /// Update alert settings
    public func updateSettings(_ settings: AlertSettings) {
        self.alertSettings = settings
    }
    
    /// Setup default alert rules
    private func setupDefaultAlertRules() {
        // Heart rate anomaly alert
        let heartRateRule = AlertRule(
            type: .anomaly,
            severity: .high,
            title: "Heart Rate Anomaly",
            condition: .greaterThan(120),
            threshold: 120,
            metric: "heart_rate"
        )
        
        // Blood pressure threshold alert
        let bpRule = AlertRule(
            type: .threshold,
            severity: .critical,
            title: "High Blood Pressure",
            condition: .greaterThan(140),
            threshold: 140,
            metric: "systolic_bp"
        )
        
        // Data quality alert
        let qualityRule = AlertRule(
            type: .quality,
            severity: .medium,
            title: "Data Quality Issue",
            condition: .custom({ dataPoint in
                dataPoint.quality < 0.8
            }),
            threshold: 0.8,
            metric: "data_quality"
        )
        
        alertRules = [heartRateRule, bpRule, qualityRule]
    }
    
    /// Setup alert subscriptions
    private func setupAlertSubscriptions() {
        // Subscribe to analytics events
        NotificationCenter.default.publisher(for: .analyticsDataReceived)
            .compactMap { $0.object as? AnalyticsDataPoint }
            .sink { [weak self] dataPoint in
                self?.processDataPoint(dataPoint)
            }
            .store(in: &cancellables)
    }
    
    /// Request notification permissions
    private func requestNotificationPermissions() {
        notificationCenter.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error)")
            }
        }
    }
    
    /// Cleanup old alert history
    private func cleanupAlertHistory() {
        let maxHistorySize = 1000
        if alertHistory.count > maxHistorySize {
            let removeCount = alertHistory.count - maxHistorySize
            alertHistory.removeFirst(removeCount)
        }
    }
    
    // MARK: - Analytics Methods
    
    /// Get alert statistics
    public func getAlertStatistics() -> AlertStatistics {
        let now = Date()
        let last24Hours = now.addingTimeInterval(-24 * 60 * 60)
        let last7Days = now.addingTimeInterval(-7 * 24 * 60 * 60)
        
        let alerts24h = alertHistory.filter { $0.timestamp >= last24Hours }
        let alerts7d = alertHistory.filter { $0.timestamp >= last7Days }
        
        return AlertStatistics(
            totalAlerts: alertHistory.count,
            activeAlerts: activeAlerts.count,
            alerts24Hours: alerts24h.count,
            alerts7Days: alerts7d.count,
            criticalAlerts: alertHistory.filter { $0.severity == .critical }.count,
            averageResolutionTime: calculateAverageResolutionTime()
        )
    }
    
    /// Calculate average resolution time
    private func calculateAverageResolutionTime() -> TimeInterval {
        let resolvedAlerts = alertHistory.filter { $0.resolvedAt != nil }
        guard !resolvedAlerts.isEmpty else { return 0 }
        
        let totalTime = resolvedAlerts.reduce(0.0) { total, alert in
            guard let resolvedAt = alert.resolvedAt else { return total }
            return total + resolvedAt.timeIntervalSince(alert.timestamp)
        }
        
        return totalTime / Double(resolvedAlerts.count)
    }
}

// MARK: - Supporting Types

public struct AnalyticsAlert: Identifiable {
    public let id: UUID
    public let timestamp: Date
    public let type: AlertType
    public let severity: AlertSeverity
    public let title: String
    public let message: String
    public let dataPoint: AnalyticsDataPoint
    public let rule: AlertRule
    
    public var isActive: Bool
    public var acknowledgedAt: Date?
    public var resolvedAt: Date?
    
    public mutating func acknowledge() {
        acknowledgedAt = Date()
    }
    
    public mutating func resolve() {
        isActive = false
        resolvedAt = Date()
    }
}

public struct AlertRule: Identifiable {
    public let id = UUID()
    public let type: AlertType
    public let severity: AlertSeverity
    public let title: String
    public let condition: AlertCondition
    public let threshold: Double
    public let metric: String
    public let autoResolve: Bool
    public let autoResolveDelay: TimeInterval
    
    public init(
        type: AlertType,
        severity: AlertSeverity,
        title: String,
        condition: AlertCondition,
        threshold: Double,
        metric: String,
        autoResolve: Bool = true,
        autoResolveDelay: TimeInterval = 300
    ) {
        self.type = type
        self.severity = severity
        self.title = title
        self.condition = condition
        self.threshold = threshold
        self.metric = metric
        self.autoResolve = autoResolve
        self.autoResolveDelay = autoResolveDelay
    }
    
    public func shouldTrigger(for dataPoint: AnalyticsDataPoint) -> Bool {
        guard dataPoint.metric == metric else { return false }
        return condition.evaluate(dataPoint)
    }
}

public enum AlertType {
    case anomaly
    case threshold
    case trend
    case prediction
    case quality
    case performance
}

public enum AlertSeverity {
    case low
    case medium
    case high
    case critical
}

public enum AlertCondition {
    case greaterThan(Double)
    case lessThan(Double)
    case equals(Double)
    case between(Double, Double)
    case custom((AnalyticsDataPoint) -> Bool)
    
    public func evaluate(_ dataPoint: AnalyticsDataPoint) -> Bool {
        switch self {
        case .greaterThan(let value):
            return dataPoint.value > value
        case .lessThan(let value):
            return dataPoint.value < value
        case .equals(let value):
            return dataPoint.value == value
        case .between(let min, let max):
            return dataPoint.value >= min && dataPoint.value <= max
        case .custom(let evaluator):
            return evaluator(dataPoint)
        }
    }
    
    public var description: String {
        switch self {
        case .greaterThan(let value):
            return "> \(value)"
        case .lessThan(let value):
            return "< \(value)"
        case .equals(let value):
            return "= \(value)"
        case .between(let min, let max):
            return "\(min) - \(max)"
        case .custom:
            return "Custom condition"
        }
    }
}

public struct AlertSettings {
    public var notificationsEnabled: Bool = true
    public var soundEnabled: Bool = true
    public var emailEnabled: Bool = false
    public var smsEnabled: Bool = false
    public var minimumSeverity: AlertSeverity = .medium
    public var quietHoursEnabled: Bool = false
    public var quietHoursStart: Date = Calendar.current.date(from: DateComponents(hour: 22)) ?? Date()
    public var quietHoursEnd: Date = Calendar.current.date(from: DateComponents(hour: 8)) ?? Date()
    
    public init() {}
}

public struct AlertStatistics {
    public let totalAlerts: Int
    public let activeAlerts: Int
    public let alerts24Hours: Int
    public let alerts7Days: Int
    public let criticalAlerts: Int
    public let averageResolutionTime: TimeInterval
}

public struct AnalyticsDataPoint {
    public let id: UUID
    public let timestamp: Date
    public let metric: String
    public let value: Double
    public let quality: Double
    public let metadata: [String: Any]
    
    public init(metric: String, value: Double, quality: Double = 1.0, metadata: [String: Any] = [:]) {
        self.id = UUID()
        self.timestamp = Date()
        self.metric = metric
        self.value = value
        self.quality = quality
        self.metadata = metadata
    }
}

// MARK: - Notification Extensions

extension Notification.Name {
    static let analyticsDataReceived = Notification.Name("analyticsDataReceived")
    static let alertTriggered = Notification.Name("alertTriggered")
    static let alertResolved = Notification.Name("alertResolved")
}

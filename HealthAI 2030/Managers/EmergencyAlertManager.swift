import Foundation
import HealthKit
import Combine
import CoreLocation

/// Emergency Alert Manager
/// Provides real-time health monitoring, emergency detection, and automated emergency response coordination
class EmergencyAlertManager: ObservableObject {
    // MARK: - Published Properties
    @Published var currentAlertStatus: EmergencyStatus = .normal
    @Published var activeAlerts: [EmergencyAlert] = []
    @Published var isMonitoring = false
    @Published var lastHealthCheck: Date = Date()
    @Published var emergencyContacts: [EmergencyContact] = []
    @Published var responseStatus: ResponseStatus = .idle
    
    // MARK: - Private Properties
    private var healthDataManager: HealthDataManager?
    private var locationManager: CLLocationManager?
    private var alertProcessor: AlertProcessor?
    private var responseCoordinator: ResponseCoordinator?
    private var notificationManager: EmergencyNotificationManager?
    
    // Emergency monitoring
    private var healthThresholds: HealthThresholds = HealthThresholds()
    private var emergencyRules: [EmergencyRule] = []
    private var alertHistory: [EmergencyAlert] = []
    private let maxHistorySize = 1000
    
    // Real-time monitoring
    private var monitoringTimer: Timer?
    private var healthDataSubscription: AnyCancellable?
    private var locationSubscription: AnyCancellable?
    
    // Emergency response
    private var responseProtocol: EmergencyResponseProtocol = EmergencyResponseProtocol()
    private var escalationLevel: EscalationLevel = .none
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupEmergencyAlertManager()
    }
    
    deinit {
        cleanup()
    }
    
    // MARK: - Public Methods
    
    /// Initialize emergency monitoring system
    func initialize() {
        setupHealthMonitoring()
        setupLocationMonitoring()
        setupAlertProcessing()
        setupResponseCoordination()
        setupNotificationSystem()
        loadEmergencyConfiguration()
    }
    
    /// Start emergency monitoring
    func startMonitoring() {
        isMonitoring = true
        startHealthDataMonitoring()
        startLocationMonitoring()
        startMonitoringTimer()
        
        NotificationCenter.default.post(name: .emergencyMonitoringStarted, object: nil)
    }
    
    /// Stop emergency monitoring
    func stopMonitoring() {
        isMonitoring = false
        stopHealthDataMonitoring()
        stopLocationMonitoring()
        stopMonitoringTimer()
        
        NotificationCenter.default.post(name: .emergencyMonitoringStopped, object: nil)
    }
    
    /// Get current emergency status
    func getCurrentStatus() -> EmergencyStatus {
        return currentAlertStatus
    }
    
    /// Get active emergency alerts
    func getActiveAlerts() -> [EmergencyAlert] {
        return activeAlerts
    }
    
    /// Add emergency contact
    func addEmergencyContact(_ contact: EmergencyContact) {
        emergencyContacts.append(contact)
        saveEmergencyContacts()
    }
    
    /// Remove emergency contact
    func removeEmergencyContact(_ contactId: String) {
        emergencyContacts.removeAll { $0.id == contactId }
        saveEmergencyContacts()
    }
    
    /// Set health thresholds for emergency detection
    func setHealthThresholds(_ thresholds: HealthThresholds) {
        healthThresholds = thresholds
        saveHealthThresholds()
    }
    
    /// Get health thresholds
    func getHealthThresholds() -> HealthThresholds {
        return healthThresholds
    }
    
    /// Trigger manual emergency alert
    func triggerManualAlert(type: EmergencyType, description: String) {
        let alert = EmergencyAlert(
            id: UUID().uuidString,
            type: type,
            severity: .critical,
            description: description,
            timestamp: Date(),
            location: getCurrentLocation(),
            healthData: getCurrentHealthData(),
            isManual: true
        )
        
        processEmergencyAlert(alert)
    }
    
    /// Acknowledge emergency alert
    func acknowledgeAlert(_ alertId: String) {
        if let index = activeAlerts.firstIndex(where: { $0.id == alertId }) {
            activeAlerts[index].isAcknowledged = true
            activeAlerts[index].acknowledgmentTime = Date()
            updateAlertHistory(activeAlerts[index])
        }
    }
    
    /// Resolve emergency alert
    func resolveAlert(_ alertId: String, resolution: String) {
        if let index = activeAlerts.firstIndex(where: { $0.id == alertId }) {
            activeAlerts[index].isResolved = true
            activeAlerts[index].resolutionTime = Date()
            activeAlerts[index].resolution = resolution
            
            updateAlertHistory(activeAlerts[index])
            activeAlerts.remove(at: index)
            updateEmergencyStatus()
        }
    }
    
    /// Get alert history
    func getAlertHistory() -> [EmergencyAlert] {
        return alertHistory
    }
    
    // MARK: - Private Methods
    
    private func setupEmergencyAlertManager() {
        healthDataManager = HealthDataManager.shared
        locationManager = CLLocationManager()
        alertProcessor = AlertProcessor()
        responseCoordinator = ResponseCoordinator()
        notificationManager = EmergencyNotificationManager()
        
        setupHealthDataSubscription()
        setupLocationSubscription()
        loadSavedConfiguration()
    }
    
    private func setupHealthDataSubscription() {
        healthDataManager?.healthDataPublisher
            .sink { [weak self] healthData in
                self?.processHealthData(healthData)
            }
            .store(in: &cancellables)
    }
    
    private func setupLocationSubscription() {
        // Setup location monitoring subscription
    }
    
    private func setupHealthMonitoring() {
        healthDataManager?.requestHealthKitPermissions()
    }
    
    private func setupLocationMonitoring() {
        locationManager?.requestWhenInUseAuthorization()
        locationManager?.startUpdatingLocation()
    }
    
    private func setupAlertProcessing() {
        alertProcessor?.alertPublisher
            .sink { [weak self] alert in
                self?.handleProcessedAlert(alert)
            }
            .store(in: &cancellables)
    }
    
    private func setupResponseCoordination() {
        responseCoordinator?.responseStatusPublisher
            .sink { [weak self] status in
                self?.handleResponseStatus(status)
            }
            .store(in: &cancellables)
    }
    
    private func setupNotificationSystem() {
        notificationManager?.notificationStatusPublisher
            .sink { [weak self] status in
                self?.handleNotificationStatus(status)
            }
            .store(in: &cancellables)
    }
    
    private func loadEmergencyConfiguration() {
        loadEmergencyContacts()
        loadHealthThresholds()
        loadEmergencyRules()
        loadResponseProtocol()
    }
    
    private func startHealthDataMonitoring() {
        healthDataManager?.startRealTimeMonitoring()
    }
    
    private func stopHealthDataMonitoring() {
        healthDataManager?.stopRealTimeMonitoring()
    }
    
    private func startLocationMonitoring() {
        locationManager?.startUpdatingLocation()
    }
    
    private func stopLocationMonitoring() {
        locationManager?.stopUpdatingLocation()
    }
    
    private func startMonitoringTimer() {
        monitoringTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            self?.performPeriodicHealthCheck()
        }
    }
    
    private func stopMonitoringTimer() {
        monitoringTimer?.invalidate()
        monitoringTimer = nil
    }
    
    private func processHealthData(_ healthData: HealthData) {
        lastHealthCheck = Date()
        
        let violations = checkHealthThresholds(healthData)
        
        for violation in violations {
            let alert = createEmergencyAlert(for: violation, healthData: healthData)
            processEmergencyAlert(alert)
        }
        
        updateEmergencyStatus()
    }
    
    private func checkHealthThresholds(_ healthData: HealthData) -> [HealthThresholdViolation] {
        var violations: [HealthThresholdViolation] = []
        
        if let heartRate = healthData.heartRate {
            if heartRate > healthThresholds.maxHeartRate {
                violations.append(HealthThresholdViolation(
                    type: .heartRate,
                    value: heartRate,
                    threshold: healthThresholds.maxHeartRate,
                    severity: .critical
                ))
            } else if heartRate < healthThresholds.minHeartRate {
                violations.append(HealthThresholdViolation(
                    type: .heartRate,
                    value: heartRate,
                    threshold: healthThresholds.minHeartRate,
                    severity: .critical
                ))
            }
        }
        
        if let systolic = healthData.systolicBloodPressure {
            if systolic > healthThresholds.maxSystolicBloodPressure {
                violations.append(HealthThresholdViolation(
                    type: .systolicBloodPressure,
                    value: systolic,
                    threshold: healthThresholds.maxSystolicBloodPressure,
                    severity: .critical
                ))
            }
        }
        
        if let diastolic = healthData.diastolicBloodPressure {
            if diastolic > healthThresholds.maxDiastolicBloodPressure {
                violations.append(HealthThresholdViolation(
                    type: .diastolicBloodPressure,
                    value: diastolic,
                    threshold: healthThresholds.maxDiastolicBloodPressure,
                    severity: .critical
                ))
            }
        }
        
        if let oxygenSaturation = healthData.oxygenSaturation {
            if oxygenSaturation < healthThresholds.minOxygenSaturation {
                violations.append(HealthThresholdViolation(
                    type: .oxygenSaturation,
                    value: oxygenSaturation,
                    threshold: healthThresholds.minOxygenSaturation,
                    severity: .critical
                ))
            }
        }
        
        if let temperature = healthData.bodyTemperature {
            if temperature > healthThresholds.maxTemperature {
                violations.append(HealthThresholdViolation(
                    type: .bodyTemperature,
                    value: temperature,
                    threshold: healthThresholds.maxTemperature,
                    severity: .warning
                ))
            }
        }
        
        return violations
    }
    
    private func createEmergencyAlert(for violation: HealthThresholdViolation, healthData: HealthData) -> EmergencyAlert {
        let alertType: EmergencyType
        let description: String
        
        switch violation.type {
        case .heartRate:
            alertType = .cardiac
            description = "Heart rate \(violation.value) is outside normal range (\(violation.threshold))"
        case .systolicBloodPressure:
            alertType = .cardiac
            description = "Systolic blood pressure \(violation.value) is above threshold (\(violation.threshold))"
        case .diastolicBloodPressure:
            alertType = .cardiac
            description = "Diastolic blood pressure \(violation.value) is above threshold (\(violation.threshold))"
        case .oxygenSaturation:
            alertType = .respiratory
            description = "Oxygen saturation \(violation.value)% is below threshold (\(violation.threshold)%)"
        case .bodyTemperature:
            alertType = .fever
            description = "Body temperature \(violation.value)°C is above threshold (\(violation.threshold)°C)"
        }
        
        return EmergencyAlert(
            id: UUID().uuidString,
            type: alertType,
            severity: violation.severity,
            description: description,
            timestamp: Date(),
            location: getCurrentLocation(),
            healthData: healthData,
            isManual: false
        )
    }
    
    private func processEmergencyAlert(_ alert: EmergencyAlert) {
        alertProcessor?.processAlert(alert)
        activeAlerts.append(alert)
        updateEmergencyStatus()
        
        if alert.severity == .critical {
            triggerEmergencyResponse(for: alert)
        }
        
        sendEmergencyNotifications(for: alert)
    }
    
    private func handleProcessedAlert(_ alert: EmergencyAlert) {
        // Handle processed alert from alert processor
    }
    
    private func handleResponseStatus(_ status: ResponseStatus) {
        responseStatus = status
    }
    
    private func handleNotificationStatus(_ status: NotificationStatus) {
        // Handle notification status updates
    }
    
    private func updateEmergencyStatus() {
        let newStatus: EmergencyStatus
        
        if activeAlerts.contains(where: { $0.severity == .critical && !$0.isAcknowledged }) {
            newStatus = .critical
        } else if activeAlerts.contains(where: { $0.severity == .warning && !$0.isAcknowledged }) {
            newStatus = .warning
        } else if activeAlerts.contains(where: { $0.isAcknowledged && !$0.isResolved }) {
            newStatus = .acknowledged
        } else {
            newStatus = .normal
        }
        
        if newStatus != currentAlertStatus {
            currentAlertStatus = newStatus
            handleEmergencyStatusChange(newStatus)
        }
    }
    
    private func handleEmergencyStatusChange(_ status: EmergencyStatus) {
        switch status {
        case .critical:
            escalationLevel = .emergency
            responseCoordinator?.escalateToEmergency()
        case .warning:
            escalationLevel = .warning
            responseCoordinator?.escalateToWarning()
        case .acknowledged:
            escalationLevel = .acknowledged
        case .normal:
            escalationLevel = .none
        }
    }
    
    private func triggerEmergencyResponse(for alert: EmergencyAlert) {
        responseCoordinator?.triggerResponse(for: alert, protocol: responseProtocol)
    }
    
    private func sendEmergencyNotifications(for alert: EmergencyAlert) {
        notificationManager?.sendEmergencyNotification(for: alert, to: emergencyContacts)
    }
    
    private func performPeriodicHealthCheck() {
        healthDataManager?.requestLatestHealthData()
    }
    
    private func getCurrentLocation() -> CLLocation? {
        return locationManager?.location
    }
    
    private func getCurrentHealthData() -> HealthData? {
        return healthDataManager?.getLatestHealthData()
    }
    
    private func updateAlertHistory(_ alert: EmergencyAlert) {
        alertHistory.append(alert)
        
        if alertHistory.count > maxHistorySize {
            alertHistory.removeFirst()
        }
    }
    
    // MARK: - Persistence Methods
    
    private func loadSavedConfiguration() {
        loadEmergencyContacts()
        loadHealthThresholds()
        loadEmergencyRules()
        loadResponseProtocol()
    }
    
    private func loadEmergencyContacts() {
        // Load emergency contacts from UserDefaults or other storage
    }
    
    private func saveEmergencyContacts() {
        // Save emergency contacts to UserDefaults or other storage
    }
    
    private func loadHealthThresholds() {
        // Load health thresholds from storage
    }
    
    private func saveHealthThresholds() {
        // Save health thresholds to storage
    }
    
    private func loadEmergencyRules() {
        // Load emergency rules from storage
    }
    
    private func loadResponseProtocol() {
        // Load emergency response protocol from storage
    }
    
    private func cleanup() {
        stopMonitoring()
        cancellables.removeAll()
    }
}

// MARK: - Supporting Types

struct EmergencyAlert {
    let id: String
    let type: EmergencyType
    let severity: AlertSeverity
    let description: String
    let timestamp: Date
    let location: CLLocation?
    let healthData: HealthData?
    let isManual: Bool
    var isAcknowledged: Bool = false
    var acknowledgmentTime: Date?
    var isResolved: Bool = false
    var resolutionTime: Date?
    var resolution: String?
}

struct EmergencyContact {
    let id: String
    let name: String
    let phoneNumber: String
    let email: String?
    let relationship: String
    let priority: ContactPriority
    var isActive: Bool = true
    
    var isValid: Bool {
        return !name.isEmpty && !phoneNumber.isEmpty
    }
}

struct HealthThresholds {
    var maxHeartRate: Double = 120.0
    var minHeartRate: Double = 50.0
    var maxSystolicBloodPressure: Double = 140.0
    var maxDiastolicBloodPressure: Double = 90.0
    var minOxygenSaturation: Double = 95.0
    var maxTemperature: Double = 38.0
}

struct EmergencyRule {
    let id: String
    let name: String
    let description: String
    let conditions: [HealthCondition]
    let actions: [EmergencyAction]
    let isActive: Bool
}

struct HealthThresholdViolation {
    let type: HealthMetricType
    let value: Double
    let threshold: Double
    let severity: AlertSeverity
}

enum EmergencyStatus: String, CaseIterable {
    case normal = "Normal"
    case warning = "Warning"
    case acknowledged = "Acknowledged"
    case critical = "Critical"
}

enum EmergencyType: String, CaseIterable {
    case cardiac = "Cardiac"
    case respiratory = "Respiratory"
    case neurological = "Neurological"
    case trauma = "Trauma"
    case fever = "Fever"
    case fall = "Fall"
    case medication = "Medication"
    case other = "Other"
}

enum AlertSeverity: String, CaseIterable {
    case low = "Low"
    case warning = "Warning"
    case critical = "Critical"
}

enum ContactPriority: String, CaseIterable {
    case primary = "Primary"
    case secondary = "Secondary"
    case tertiary = "Tertiary"
}

enum EscalationLevel: String, CaseIterable {
    case none = "None"
    case warning = "Warning"
    case acknowledged = "Acknowledged"
    case emergency = "Emergency"
}

enum ResponseStatus: String, CaseIterable {
    case idle = "Idle"
    case testing = "Testing"
    case responding = "Responding"
    case completed = "Completed"
    case failed = "Failed"
}

enum NotificationStatus: String, CaseIterable {
    case pending = "Pending"
    case sent = "Sent"
    case delivered = "Delivered"
    case failed = "Failed"
}

enum HealthMetricType: String, CaseIterable {
    case heartRate = "Heart Rate"
    case systolicBloodPressure = "Systolic Blood Pressure"
    case diastolicBloodPressure = "Diastolic Blood Pressure"
    case oxygenSaturation = "Oxygen Saturation"
    case bodyTemperature = "Body Temperature"
}

// MARK: - Supporting Classes

class AlertProcessor: ObservableObject {
    @Published var processedAlerts: [EmergencyAlert] = []
    
    var alertPublisher: AnyPublisher<EmergencyAlert, Never> {
        $processedAlerts
            .compactMap { $0.last }
            .eraseToAnyPublisher()
    }
    
    func processAlert(_ alert: EmergencyAlert) {
        processedAlerts.append(alert)
    }
}

class ResponseCoordinator: ObservableObject {
    @Published var currentResponse: EmergencyResponse?
    @Published var responseStatus: ResponseStatus = .idle
    
    var responseStatusPublisher: AnyPublisher<ResponseStatus, Never> {
        $responseStatus.eraseToAnyPublisher()
    }
    
    func triggerResponse(for alert: EmergencyAlert, protocol: EmergencyResponseProtocol) {
        responseStatus = .responding
    }
    
    func escalateToEmergency() {
        // Escalate to emergency response
    }
    
    func escalateToWarning() {
        // Escalate to warning response
    }
}

class EmergencyNotificationManager: ObservableObject {
    @Published var notificationStatus: NotificationStatus = .pending
    
    var notificationStatusPublisher: AnyPublisher<NotificationStatus, Never> {
        $notificationStatus.eraseToAnyPublisher()
    }
    
    func sendEmergencyNotification(for alert: EmergencyAlert, to contacts: [EmergencyContact]) {
        notificationStatus = .sent
    }
}

struct EmergencyResponseProtocol {
    let escalationLevels: [EscalationLevel] = [.warning, .acknowledged, .emergency]
    let responseActions: [EmergencyAction] = []
}

struct EmergencyResponse {
    let alertId: String
    let responseType: ResponseType
    let timestamp: Date
    let actions: [EmergencyAction]
}

struct EmergencyAction {
    let type: ActionType
    let description: String
    let priority: ActionPriority
}

enum ResponseType: String, CaseIterable {
    case immediate = "Immediate"
    case urgent = "Urgent"
    case routine = "Routine"
}

enum ActionType: String, CaseIterable {
    case callEmergency = "Call Emergency"
    case notifyContact = "Notify Contact"
    case recordData = "Record Data"
    case escalate = "Escalate"
}

enum ActionPriority: String, CaseIterable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case critical = "Critical"
}

struct HealthCondition {
    let metric: HealthMetricType
    let operator: ComparisonOperator
    let value: Double
}

enum ComparisonOperator: String, CaseIterable {
    case greaterThan = ">"
    case lessThan = "<"
    case equalTo = "=="
    case notEqualTo = "!="
}

// MARK: - Notification Names

extension Notification.Name {
    static let emergencyMonitoringStarted = Notification.Name("emergencyMonitoringStarted")
    static let emergencyMonitoringStopped = Notification.Name("emergencyMonitoringStopped")
    static let emergencyAlertTriggered = Notification.Name("emergencyAlertTriggered")
    static let emergencyResponseActivated = Notification.Name("emergencyResponseActivated")
}
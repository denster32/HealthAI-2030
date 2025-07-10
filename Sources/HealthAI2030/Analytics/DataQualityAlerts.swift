import Foundation
import Combine
import UserNotifications

/// Advanced data quality alert system for HealthAI 2030
/// Provides real-time monitoring, intelligent alerting, and automated response capabilities
public class DataQualityAlerts: ObservableObject {
    
    // MARK: - Published Properties
    @Published private(set) var activeAlerts: [QualityAlert] = []
    @Published private(set) var alertHistory: [QualityAlert] = []
    @Published private(set) var alertMetrics: AlertMetrics = AlertMetrics()
    @Published private(set) var alertRules: [AlertRule] = []
    
    // MARK: - Core Components
    private let alertEngine: QualityAlertEngine
    private let thresholdManager: ThresholdManager
    private let notificationManager: NotificationManager
    private let escalationManager: EscalationManager
    private let alertProcessor: AlertProcessor
    private let responseAutomation: ResponseAutomation
    
    // MARK: - Configuration
    private let alertConfig: AlertConfiguration
    private let alertStorage: AlertStorage
    
    // MARK: - Performance Monitoring
    private let responseTimeMonitor: ResponseTimeMonitor
    private let alertFrequencyMonitor: AlertFrequencyMonitor
    
    // MARK: - Initialization
    public init(config: AlertConfiguration = .default) {
        self.alertConfig = config
        self.alertEngine = QualityAlertEngine(config: config.engineConfig)
        self.thresholdManager = ThresholdManager(config: config.thresholdConfig)
        self.notificationManager = NotificationManager(config: config.notificationConfig)
        self.escalationManager = EscalationManager(config: config.escalationConfig)
        self.alertProcessor = AlertProcessor(config: config.processorConfig)
        self.responseAutomation = ResponseAutomation(config: config.automationConfig)
        self.alertStorage = AlertStorage(config: config.storageConfig)
        self.responseTimeMonitor = ResponseTimeMonitor()
        self.alertFrequencyMonitor = AlertFrequencyMonitor()
        
        setupAlertSystem()
        loadAlertRules()
    }
    
    // MARK: - Core Alert Methods
    
    /// Processes quality assessment and generates alerts
    public func processQualityAssessment(_ assessment: QualityAssessment) async {
        let startTime = Date()
        
        // Check all configured alert rules
        let triggeredAlerts = await checkAlertRules(assessment)
        
        // Process each triggered alert
        for alert in triggeredAlerts {
            await processAlert(alert)
        }
        
        // Update alert metrics
        await updateAlertMetrics(triggeredAlerts, processingTime: Date().timeIntervalSince(startTime))
    }
    
    /// Real-time alert monitoring for streaming data
    public func monitorQualityStream(_ qualityStream: AsyncThrowingStream<QualityAssessment, Error>) async {
        do {
            for try await assessment in qualityStream {
                await processQualityAssessment(assessment)
                
                // Check for alert patterns and trends
                await analyzeAlertPatterns()
                
                // Update alert frequency monitoring
                alertFrequencyMonitor.recordAssessment(assessment.timestamp)
            }
        } catch {
            await handleStreamError(error)
        }
    }
    
    /// Manually triggers an alert
    public func triggerAlert(_ alert: QualityAlert) async {
        await processAlert(alert)
    }
    
    /// Acknowledges an alert
    public func acknowledgeAlert(_ alertId: String, acknowledgedBy: String) async {
        guard let alertIndex = activeAlerts.firstIndex(where: { $0.id == alertId }) else {
            return
        }
        
        var alert = activeAlerts[alertIndex]
        alert.acknowledge(by: acknowledgedBy)
        
        await MainActor.run {
            self.activeAlerts[alertIndex] = alert
        }
        
        await updateAlertStatus(alert)
        await notificationManager.sendAcknowledgment(alert)
    }
    
    /// Resolves an alert
    public func resolveAlert(_ alertId: String, resolvedBy: String, resolution: String) async {
        guard let alertIndex = activeAlerts.firstIndex(where: { $0.id == alertId }) else {
            return
        }
        
        var alert = activeAlerts[alertIndex]
        alert.resolve(by: resolvedBy, resolution: resolution)
        
        await MainActor.run {
            self.activeAlerts.remove(at: alertIndex)
            self.alertHistory.append(alert)
        }
        
        await updateAlertStatus(alert)
        await notificationManager.sendResolution(alert)
        
        // Update metrics
        await updateAlertResolutionMetrics(alert)
    }
    
    // MARK: - Alert Rule Management
    
    public func addAlertRule(_ rule: AlertRule) async {
        await MainActor.run {
            self.alertRules.append(rule)
        }
        
        await saveAlertRules()
        await alertEngine.updateRules(alertRules)
    }
    
    public func removeAlertRule(_ ruleId: String) async {
        await MainActor.run {
            self.alertRules.removeAll { $0.id == ruleId }
        }
        
        await saveAlertRules()
        await alertEngine.updateRules(alertRules)
    }
    
    public func updateAlertRule(_ rule: AlertRule) async {
        await MainActor.run {
            if let index = self.alertRules.firstIndex(where: { $0.id == rule.id }) {
                self.alertRules[index] = rule
            }
        }
        
        await saveAlertRules()
        await alertEngine.updateRules(alertRules)
    }
    
    // MARK: - Threshold Management
    
    public func setQualityThreshold(_ threshold: QualityThreshold) async {
        await thresholdManager.setThreshold(threshold)
        await updateAlertRulesWithThreshold(threshold)
    }
    
    public func getQualityThresholds() async -> [QualityThreshold] {
        return await thresholdManager.getAllThresholds()
    }
    
    // MARK: - Alert Analytics and Reporting
    
    public func getAlertTrends(timeRange: TimeRange = .last24Hours) -> [AlertTrendPoint] {
        let relevantAlerts = alertHistory.filter { alert in
            timeRange.contains(alert.timestamp)
        }
        
        return AlertTrendAnalyzer.generateTrends(from: relevantAlerts)
    }
    
    public func generateAlertReport(timeRange: TimeRange = .lastWeek) async -> AlertReport {
        let relevantAlerts = alertHistory.filter { timeRange.contains($0.timestamp) }
        
        return AlertReport(
            timeRange: timeRange,
            totalAlerts: relevantAlerts.count,
            alertsBySeverity: groupAlertsBySeverity(relevantAlerts),
            alertsByType: groupAlertsByType(relevantAlerts),
            averageResponseTime: calculateAverageResponseTime(relevantAlerts),
            averageResolutionTime: calculateAverageResolutionTime(relevantAlerts),
            topAlertSources: identifyTopAlertSources(relevantAlerts),
            recommendations: generateAlertRecommendations(relevantAlerts),
            generatedAt: Date()
        )
    }
    
    // MARK: - Alert Automation
    
    public func enableAutomaticResponse(for alertType: AlertType, response: AutomatedResponse) async {
        await responseAutomation.configureResponse(alertType: alertType, response: response)
    }
    
    public func disableAutomaticResponse(for alertType: AlertType) async {
        await responseAutomation.removeResponse(alertType: alertType)
    }
    
    // MARK: - Alert Filtering and Search
    
    public func filterAlerts(by criteria: AlertFilterCriteria) -> [QualityAlert] {
        let allAlerts = activeAlerts + alertHistory
        
        return allAlerts.filter { alert in
            var matches = true
            
            if let severity = criteria.severity {
                matches = matches && alert.severity == severity
            }
            
            if let type = criteria.type {
                matches = matches && alert.type == type
            }
            
            if let status = criteria.status {
                matches = matches && alert.status == status
            }
            
            if let timeRange = criteria.timeRange {
                matches = matches && timeRange.contains(alert.timestamp)
            }
            
            if let searchText = criteria.searchText {
                matches = matches && (alert.title.localizedCaseInsensitiveContains(searchText) ||
                                     alert.description.localizedCaseInsensitiveContains(searchText))
            }
            
            return matches
        }
    }
    
    public func searchAlerts(_ searchText: String) -> [QualityAlert] {
        let criteria = AlertFilterCriteria(searchText: searchText)
        return filterAlerts(by: criteria)
    }
    
    // MARK: - Private Methods
    
    private func setupAlertSystem() {
        // Configure alert system components
        alertEngine.delegate = self
        thresholdManager.delegate = self
        escalationManager.delegate = self
        responseAutomation.delegate = self
        
        // Setup notification permissions
        Task {
            await requestNotificationPermissions()
        }
    }
    
    private func loadAlertRules() {
        Task {
            let rules = await alertStorage.loadAlertRules()
            await MainActor.run {
                self.alertRules = rules
            }
            await alertEngine.updateRules(rules)
        }
    }
    
    private func saveAlertRules() async {
        await alertStorage.saveAlertRules(alertRules)
    }
    
    private func checkAlertRules(_ assessment: QualityAssessment) async -> [QualityAlert] {
        var triggeredAlerts: [QualityAlert] = []
        
        for rule in alertRules {
            if rule.isEnabled && await rule.shouldTrigger(assessment) {
                let alert = createAlert(from: rule, assessment: assessment)
                triggeredAlerts.append(alert)
            }
        }
        
        return triggeredAlerts
    }
    
    private func processAlert(_ alert: QualityAlert) async {
        // Check for duplicate alerts
        if await isDuplicateAlert(alert) {
            await handleDuplicateAlert(alert)
            return
        }
        
        // Add to active alerts
        await MainActor.run {
            self.activeAlerts.append(alert)
        }
        
        // Store alert
        await alertStorage.saveAlert(alert)
        
        // Send notifications
        await notificationManager.sendAlert(alert)
        
        // Check for escalation
        await escalationManager.checkEscalation(alert)
        
        // Execute automated responses
        await responseAutomation.executeResponse(alert)
        
        // Update alert frequency monitoring
        alertFrequencyMonitor.recordAlert(alert)
        
        // Start response time monitoring
        responseTimeMonitor.startTracking(alert)
    }
    
    private func createAlert(from rule: AlertRule, assessment: QualityAssessment) -> QualityAlert {
        return QualityAlert(
            id: UUID().uuidString,
            title: rule.title,
            description: generateAlertDescription(rule: rule, assessment: assessment),
            severity: rule.severity,
            type: rule.type,
            source: assessment.datasetId,
            qualityScore: assessment.overallQualityScore,
            affectedDimensions: identifyAffectedDimensions(rule: rule, assessment: assessment),
            metadata: generateAlertMetadata(rule: rule, assessment: assessment),
            timestamp: Date(),
            status: .active
        )
    }
    
    private func generateAlertDescription(rule: AlertRule, assessment: QualityAssessment) -> String {
        switch rule.type {
        case .qualityThreshold:
            return "Data quality score (\(String(format: "%.2f", assessment.overallQualityScore))) is below threshold (\(String(format: "%.2f", rule.threshold)))"
        case .completenessIssue:
            return "Data completeness issues detected in dataset \(assessment.datasetId)"
        case .accuracyIssue:
            return "Data accuracy concerns identified in dataset \(assessment.datasetId)"
        case .consistencyIssue:
            return "Data consistency problems found in dataset \(assessment.datasetId)"
        case .validityIssue:
            return "Data validity errors detected in dataset \(assessment.datasetId)"
        case .timelinessIssue:
            return "Data timeliness issues identified in dataset \(assessment.datasetId)"
        case .integrityIssue:
            return "Data integrity problems found in dataset \(assessment.datasetId)"
        case .custom:
            return rule.customDescription ?? "Custom quality alert triggered"
        }
    }
    
    private func identifyAffectedDimensions(rule: AlertRule, assessment: QualityAssessment) -> [QualityDimension] {
        switch rule.type {
        case .completenessIssue:
            return [.completeness]
        case .accuracyIssue:
            return [.accuracy]
        case .consistencyIssue:
            return [.consistency]
        case .validityIssue:
            return [.validity]
        case .timelinessIssue:
            return [.timeliness]
        case .integrityIssue:
            return [.integrity]
        case .qualityThreshold, .custom:
            return QualityDimension.allCases
        }
    }
    
    private func generateAlertMetadata(rule: AlertRule, assessment: QualityAssessment) -> [String: Any] {
        return [
            "ruleId": rule.id,
            "assessmentId": assessment.datasetId,
            "qualityScore": assessment.overallQualityScore,
            "recordCount": assessment.recordCount,
            "threshold": rule.threshold,
            "assessmentTimestamp": assessment.timestamp.timeIntervalSince1970
        ]
    }
    
    private func isDuplicateAlert(_ alert: QualityAlert) async -> Bool {
        let recentAlerts = activeAlerts.filter { 
            $0.type == alert.type && 
            $0.source == alert.source &&
            Date().timeIntervalSince($0.timestamp) < alertConfig.duplicateTimeWindow
        }
        
        return !recentAlerts.isEmpty
    }
    
    private func handleDuplicateAlert(_ alert: QualityAlert) async {
        // Update existing alert with new information
        if let existingAlertIndex = activeAlerts.firstIndex(where: { 
            $0.type == alert.type && $0.source == alert.source 
        }) {
            var existingAlert = activeAlerts[existingAlertIndex]
            existingAlert.incrementOccurrences()
            
            await MainActor.run {
                self.activeAlerts[existingAlertIndex] = existingAlert
            }
            
            await updateAlertStatus(existingAlert)
        }
    }
    
    private func analyzeAlertPatterns() async {
        let recentAlerts = Array(alertHistory.suffix(100))
        
        // Detect alert patterns and trends
        let patterns = AlertPatternAnalyzer.detectPatterns(recentAlerts)
        
        // Generate pattern-based alerts if needed
        for pattern in patterns {
            if pattern.requiresAlert {
                let patternAlert = createPatternAlert(pattern)
                await processAlert(patternAlert)
            }
        }
    }
    
    private func createPatternAlert(_ pattern: AlertPattern) -> QualityAlert {
        return QualityAlert(
            id: UUID().uuidString,
            title: "Alert Pattern Detected",
            description: pattern.description,
            severity: pattern.severity,
            type: .custom,
            source: "PatternAnalyzer",
            qualityScore: 0.0,
            affectedDimensions: [],
            metadata: pattern.metadata,
            timestamp: Date(),
            status: .active
        )
    }
    
    private func handleStreamError(_ error: Error) async {
        let errorAlert = QualityAlert(
            id: UUID().uuidString,
            title: "Quality Monitoring Stream Error",
            description: "Error in quality monitoring stream: \(error.localizedDescription)",
            severity: .critical,
            type: .custom,
            source: "QualityMonitoring",
            qualityScore: 0.0,
            affectedDimensions: [],
            metadata: ["error": error.localizedDescription],
            timestamp: Date(),
            status: .active
        )
        
        await processAlert(errorAlert)
    }
    
    private func updateAlertStatus(_ alert: QualityAlert) async {
        await alertStorage.updateAlert(alert)
    }
    
    @MainActor
    private func updateAlertMetrics(_ alerts: [QualityAlert], processingTime: TimeInterval) {
        alertMetrics.totalAlertsGenerated += alerts.count
        alertMetrics.averageProcessingTime = 
            (alertMetrics.averageProcessingTime * Double(alertMetrics.totalAlertsGenerated - alerts.count) + processingTime) / 
            Double(alertMetrics.totalAlertsGenerated)
        
        for alert in alerts {
            switch alert.severity {
            case .critical:
                alertMetrics.criticalAlerts += 1
            case .warning:
                alertMetrics.warningAlerts += 1
            case .info:
                alertMetrics.infoAlerts += 1
            }
        }
    }
    
    private func updateAlertResolutionMetrics(_ alert: QualityAlert) async {
        if let responseTime = alert.responseTime {
            responseTimeMonitor.recordResponse(alertId: alert.id, responseTime: responseTime)
        }
        
        if let resolutionTime = alert.resolutionTime {
            await MainActor.run {
                self.alertMetrics.totalAlertsResolved += 1
                let newAverage = (self.alertMetrics.averageResolutionTime * Double(self.alertMetrics.totalAlertsResolved - 1) + resolutionTime) / 
                                Double(self.alertMetrics.totalAlertsResolved)
                self.alertMetrics.averageResolutionTime = newAverage
            }
        }
    }
    
    private func updateAlertRulesWithThreshold(_ threshold: QualityThreshold) async {
        // Update existing rules that use this threshold
        let updatedRules = alertRules.map { rule in
            var updatedRule = rule
            if rule.thresholdId == threshold.id {
                updatedRule.threshold = threshold.value
            }
            return updatedRule
        }
        
        await MainActor.run {
            self.alertRules = updatedRules
        }
        
        await saveAlertRules()
        await alertEngine.updateRules(alertRules)
    }
    
    private func requestNotificationPermissions() async {
        let center = UNUserNotificationCenter.current()
        try? await center.requestAuthorization(options: [.alert, .sound, .badge])
    }
    
    // MARK: - Helper Methods for Reporting
    
    private func groupAlertsBySeverity(_ alerts: [QualityAlert]) -> [AlertSeverity: Int] {
        return Dictionary(grouping: alerts) { $0.severity }
            .mapValues { $0.count }
    }
    
    private func groupAlertsByType(_ alerts: [QualityAlert]) -> [AlertType: Int] {
        return Dictionary(grouping: alerts) { $0.type }
            .mapValues { $0.count }
    }
    
    private func calculateAverageResponseTime(_ alerts: [QualityAlert]) -> TimeInterval? {
        let responseTimes = alerts.compactMap { $0.responseTime }
        return responseTimes.isEmpty ? nil : responseTimes.reduce(0, +) / Double(responseTimes.count)
    }
    
    private func calculateAverageResolutionTime(_ alerts: [QualityAlert]) -> TimeInterval? {
        let resolutionTimes = alerts.compactMap { $0.resolutionTime }
        return resolutionTimes.isEmpty ? nil : resolutionTimes.reduce(0, +) / Double(resolutionTimes.count)
    }
    
    private func identifyTopAlertSources(_ alerts: [QualityAlert]) -> [(String, Int)] {
        let sources = Dictionary(grouping: alerts) { $0.source }
            .mapValues { $0.count }
        
        return sources.sorted { $0.value > $1.value }.prefix(10).map { ($0.key, $0.value) }
    }
    
    private func generateAlertRecommendations(_ alerts: [QualityAlert]) -> [String] {
        var recommendations: [String] = []
        
        let criticalAlerts = alerts.filter { $0.severity == .critical }
        if criticalAlerts.count > alerts.count / 2 {
            recommendations.append("High number of critical alerts - review data quality processes")
        }
        
        let frequentSources = identifyTopAlertSources(alerts).prefix(3)
        if !frequentSources.isEmpty {
            recommendations.append("Focus on improving data quality for sources: \(frequentSources.map { $0.0 }.joined(separator: ", "))")
        }
        
        return recommendations
    }
}

// MARK: - Supporting Types

public struct AlertMetrics {
    public var totalAlertsGenerated: Int = 0
    public var totalAlertsResolved: Int = 0
    public var criticalAlerts: Int = 0
    public var warningAlerts: Int = 0
    public var infoAlerts: Int = 0
    public var averageProcessingTime: TimeInterval = 0.0
    public var averageResolutionTime: TimeInterval = 0.0
    
    public var resolutionRate: Double {
        return totalAlertsGenerated > 0 ? Double(totalAlertsResolved) / Double(totalAlertsGenerated) : 0.0
    }
}

public struct AlertFilterCriteria {
    public let severity: AlertSeverity?
    public let type: AlertType?
    public let status: AlertStatus?
    public let timeRange: TimeRange?
    public let searchText: String?
    
    public init(severity: AlertSeverity? = nil,
                type: AlertType? = nil,
                status: AlertStatus? = nil,
                timeRange: TimeRange? = nil,
                searchText: String? = nil) {
        self.severity = severity
        self.type = type
        self.status = status
        self.timeRange = timeRange
        self.searchText = searchText
    }
}

// MARK: - Protocol Conformances

extension DataQualityAlerts: QualityAlertEngineDelegate {
    public func alertGenerated(_ alert: QualityAlert) {
        Task {
            await processAlert(alert)
        }
    }
}

extension DataQualityAlerts: ThresholdManagerDelegate {
    public func thresholdUpdated(_ threshold: QualityThreshold) {
        Task {
            await updateAlertRulesWithThreshold(threshold)
        }
    }
}

extension DataQualityAlerts: EscalationManagerDelegate {
    public func escalationTriggered(_ alert: QualityAlert, level: EscalationLevel) {
        Task {
            await handleEscalation(alert, level: level)
        }
    }
    
    private func handleEscalation(_ alert: QualityAlert, level: EscalationLevel) async {
        // Handle alert escalation based on level
        await notificationManager.sendEscalation(alert, level: level)
    }
}

extension DataQualityAlerts: ResponseAutomationDelegate {
    public func automatedResponseExecuted(_ alert: QualityAlert, response: AutomatedResponse) {
        // Handle automated response completion
    }
    
    public func automatedResponseFailed(_ alert: QualityAlert, response: AutomatedResponse, error: Error) {
        // Handle automated response failure
    }
}

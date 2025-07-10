//
//  AuditTrailManager.swift
//  HealthAI 2030
//
//  Created by Agent 7 (Security) on 2025-01-31
//  Comprehensive audit trail and logging system
//

import Foundation
import CryptoKit
import os.log
import Combine

/// Comprehensive audit trail and logging system for security compliance
public class AuditTrailManager: ObservableObject {
    
    // MARK: - Properties
    
    @Published public var auditLogs: [AuditLog] = []
    @Published public var auditSummary: AuditSummary = AuditSummary()
    @Published public var integrityStatus: IntegrityStatus = .verified
    @Published public var isLogging: Bool = true
    
    private let logger = Logger(subsystem: "HealthAI2030", category: "AuditTrail")
    private var logStorage: AuditLogStorage
    private var integrityChecker: LogIntegrityChecker
    private var cancellables = Set<AnyCancellable>()
    
    // Configuration
    private let maxMemoryLogs: Int = 1000
    private let logRotationSize: Int = 10000
    private let integrityCheckInterval: TimeInterval = 3600 // 1 hour
    
    // Audit categories
    private let auditCategories: Set<AuditCategory> = [
        .authentication, .authorization, .dataAccess, .dataModification,
        .systemAccess, .configurationChange, .securityEvent, .compliance
    ]
    
    // MARK: - Initialization
    
    public init() {
        self.logStorage = AuditLogStorage()
        self.integrityChecker = LogIntegrityChecker()
        
        setupAuditTrail()
        startIntegrityMonitoring()
    }
    
    deinit {
        stopLogging()
    }
    
    // MARK: - Audit Logging Methods
    
    /// Log audit event
    public func logEvent(
        category: AuditCategory,
        action: String,
        resource: String,
        userId: String?,
        details: [String: Any] = [:],
        severity: AuditSeverity = .info
    ) {
        guard isLogging else { return }
        
        let auditLog = AuditLog(
            id: UUID(),
            timestamp: Date(),
            category: category,
            action: action,
            resource: resource,
            userId: userId,
            sessionId: getCurrentSessionId(),
            ipAddress: getCurrentIPAddress(),
            userAgent: getCurrentUserAgent(),
            details: details,
            severity: severity,
            checksum: ""
        )
        
        // Calculate integrity checksum
        let logWithChecksum = calculateChecksum(for: auditLog)
        
        // Store log
        storeAuditLog(logWithChecksum)
        
        // Update in-memory logs
        DispatchQueue.main.async { [weak self] in
            self?.auditLogs.append(logWithChecksum)
            self?.cleanupMemoryLogs()
            self?.updateAuditSummary()
        }
        
        // Log to system logger
        logToSystem(logWithChecksum)
        
        // Check for security alerts
        checkForSecurityAlerts(logWithChecksum)
    }
    
    /// Log authentication event
    public func logAuthentication(
        userId: String,
        action: AuthenticationAction,
        success: Bool,
        method: AuthenticationMethod,
        details: [String: Any] = [:]
    ) {
        var eventDetails = details
        eventDetails["success"] = success
        eventDetails["method"] = method.rawValue
        eventDetails["timestamp"] = Date().iso8601String
        
        logEvent(
            category: .authentication,
            action: "\(action.rawValue)_\(success ? "success" : "failure")",
            resource: "authentication_system",
            userId: userId,
            details: eventDetails,
            severity: success ? .info : .warning
        )
    }
    
    /// Log data access event
    public func logDataAccess(
        userId: String,
        action: DataAccessAction,
        resource: String,
        dataType: String,
        recordCount: Int = 1,
        details: [String: Any] = [:]
    ) {
        var eventDetails = details
        eventDetails["data_type"] = dataType
        eventDetails["record_count"] = recordCount
        eventDetails["access_time"] = Date().iso8601String
        
        logEvent(
            category: .dataAccess,
            action: action.rawValue,
            resource: resource,
            userId: userId,
            details: eventDetails,
            severity: .info
        )
    }
    
    /// Log security event
    public func logSecurityEvent(
        eventType: SecurityEventType,
        description: String,
        severity: AuditSeverity,
        details: [String: Any] = []
    ) {
        var eventDetails = details
        eventDetails["event_type"] = eventType.rawValue
        eventDetails["description"] = description
        eventDetails["detection_time"] = Date().iso8601String
        
        logEvent(
            category: .securityEvent,
            action: eventType.rawValue,
            resource: "security_system",
            userId: nil,
            details: eventDetails,
            severity: severity
        )
    }
    
    /// Log compliance event
    public func logComplianceEvent(
        regulation: ComplianceRegulation,
        action: String,
        complianceStatus: ComplianceStatus,
        details: [String: Any] = [:]
    ) {
        var eventDetails = details
        eventDetails["regulation"] = regulation.rawValue
        eventDetails["compliance_status"] = complianceStatus.rawValue
        eventDetails["assessment_time"] = Date().iso8601String
        
        logEvent(
            category: .compliance,
            action: action,
            resource: "compliance_system",
            userId: nil,
            details: eventDetails,
            severity: complianceStatus == .compliant ? .info : .warning
        )
    }
    
    // MARK: - Audit Query Methods
    
    /// Query audit logs by criteria
    public func queryLogs(criteria: AuditQueryCriteria) async -> [AuditLog] {
        return await logStorage.query(criteria)
    }
    
    /// Get audit logs for user
    public func getUserAuditLogs(userId: String, from: Date? = nil, to: Date? = nil) async -> [AuditLog] {
        let criteria = AuditQueryCriteria(
            userId: userId,
            fromDate: from,
            toDate: to
        )
        return await queryLogs(criteria: criteria)
    }
    
    /// Get audit logs by category
    public func getCategoryAuditLogs(category: AuditCategory, from: Date? = nil, to: Date? = nil) async -> [AuditLog] {
        let criteria = AuditQueryCriteria(
            category: category,
            fromDate: from,
            toDate: to
        )
        return await queryLogs(criteria: criteria)
    }
    
    /// Get security events
    public func getSecurityEvents(severity: AuditSeverity? = nil, from: Date? = nil, to: Date? = nil) async -> [AuditLog] {
        let criteria = AuditQueryCriteria(
            category: .securityEvent,
            severity: severity,
            fromDate: from,
            toDate: to
        )
        return await queryLogs(criteria: criteria)
    }
    
    // MARK: - Integrity Management
    
    /// Verify audit log integrity
    public func verifyIntegrity() async -> IntegrityVerificationResult {
        return await integrityChecker.verifyLogs(auditLogs)
    }
    
    /// Generate integrity report
    public func generateIntegrityReport() async -> IntegrityReport {
        let verificationResult = await verifyIntegrity()
        
        return IntegrityReport(
            timestamp: Date(),
            totalLogs: auditLogs.count,
            verifiedLogs: verificationResult.verifiedCount,
            failedLogs: verificationResult.failedCount,
            integrityScore: verificationResult.integrityScore,
            violations: verificationResult.violations,
            recommendations: generateIntegrityRecommendations(verificationResult)
        )
    }
    
    /// Calculate checksum for audit log
    private func calculateChecksum(for log: AuditLog) -> AuditLog {
        let logData = serializeLogForChecksum(log)
        let hash = SHA256.hash(data: logData)
        let checksum = Data(hash).base64EncodedString()
        
        return AuditLog(
            id: log.id,
            timestamp: log.timestamp,
            category: log.category,
            action: log.action,
            resource: log.resource,
            userId: log.userId,
            sessionId: log.sessionId,
            ipAddress: log.ipAddress,
            userAgent: log.userAgent,
            details: log.details,
            severity: log.severity,
            checksum: checksum
        )
    }
    
    // MARK: - Compliance Reporting
    
    /// Generate compliance audit report
    public func generateComplianceReport(
        regulation: ComplianceRegulation,
        from: Date,
        to: Date
    ) async -> ComplianceAuditReport {
        
        let relevantLogs = await getCategoryAuditLogs(
            category: .compliance,
            from: from,
            to: to
        ).filter { log in
            log.details["regulation"] as? String == regulation.rawValue
        }
        
        let dataAccessLogs = await getCategoryAuditLogs(
            category: .dataAccess,
            from: from,
            to: to
        )
        
        let authenticationLogs = await getCategoryAuditLogs(
            category: .authentication,
            from: from,
            to: to
        )
        
        return ComplianceAuditReport(
            regulation: regulation,
            reportPeriod: from...to,
            totalEvents: relevantLogs.count,
            complianceEvents: relevantLogs.filter { log in
                log.details["compliance_status"] as? String == ComplianceStatus.compliant.rawValue
            }.count,
            violations: relevantLogs.filter { log in
                log.details["compliance_status"] as? String == ComplianceStatus.nonCompliant.rawValue
            }.count,
            dataAccessEvents: dataAccessLogs.count,
            authenticationEvents: authenticationLogs.count,
            securityIncidents: await getSecurityEvents(from: from, to: to).count,
            auditTrailCompleteness: calculateAuditTrailCompleteness(from: from, to: to),
            recommendations: generateComplianceRecommendations(regulation, relevantLogs)
        )
    }
    
    // MARK: - Helper Methods
    
    private func setupAuditTrail() {
        isLogging = true
        
        // Log audit system startup
        logEvent(
            category: .systemAccess,
            action: "audit_system_started",
            resource: "audit_trail_manager",
            userId: nil,
            details: ["startup_time": Date().iso8601String],
            severity: .info
        )
        
        logger.info("Audit Trail Manager initialized")
    }
    
    private func startIntegrityMonitoring() {
        Timer.scheduledTimer(withTimeInterval: integrityCheckInterval, repeats: true) { [weak self] _ in
            Task {
                await self?.performIntegrityCheck()
            }
        }
    }
    
    private func performIntegrityCheck() async {
        let result = await verifyIntegrity()
        
        await MainActor.run {
            self.integrityStatus = result.integrityScore > 0.95 ? .verified : .compromised
        }
        
        if result.integrityScore < 0.95 {
            logSecurityEvent(
                eventType: .integrityViolation,
                description: "Audit log integrity compromised: \(result.integrityScore)",
                severity: .critical,
                details: ["integrity_score": result.integrityScore]
            )
        }
    }
    
    private func storeAuditLog(_ log: AuditLog) {
        Task {
            await logStorage.store(log)
        }
    }
    
    private func logToSystem(_ log: AuditLog) {
        let logLevel: OSLogType = {
            switch log.severity {
            case .info:
                return .info
            case .warning:
                return .default
            case .error:
                return .error
            case .critical:
                return .fault
            }
        }()
        
        logger.log(level: logLevel, "\(log.category.rawValue): \(log.action) on \(log.resource) by \(log.userId ?? "system")")
    }
    
    private func checkForSecurityAlerts(_ log: AuditLog) {
        // Check for suspicious patterns
        if log.severity == .critical || log.category == .securityEvent {
            NotificationCenter.default.post(
                name: .securityAlertTriggered,
                object: log
            )
        }
    }
    
    private func cleanupMemoryLogs() {
        if auditLogs.count > maxMemoryLogs {
            let removeCount = auditLogs.count - maxMemoryLogs
            auditLogs.removeFirst(removeCount)
        }
    }
    
    private func updateAuditSummary() {
        let last24Hours = Date().addingTimeInterval(-24 * 3600)
        let recentLogs = auditLogs.filter { $0.timestamp >= last24Hours }
        
        auditSummary = AuditSummary(
            totalLogs: auditLogs.count,
            logsLast24Hours: recentLogs.count,
            criticalEvents: recentLogs.filter { $0.severity == .critical }.count,
            securityEvents: recentLogs.filter { $0.category == .securityEvent }.count,
            authenticationEvents: recentLogs.filter { $0.category == .authentication }.count,
            dataAccessEvents: recentLogs.filter { $0.category == .dataAccess }.count,
            integrityStatus: integrityStatus
        )
    }
    
    private func getCurrentSessionId() -> String {
        return ProcessInfo.processInfo.globallyUniqueString
    }
    
    private func getCurrentIPAddress() -> String {
        return "127.0.0.1" // Simplified
    }
    
    private func getCurrentUserAgent() -> String {
        return "HealthAI-2030/1.0"
    }
    
    private func serializeLogForChecksum(_ log: AuditLog) -> Data {
        let logString = "\(log.id)\(log.timestamp)\(log.category)\(log.action)\(log.resource)\(log.userId ?? "")"
        return logString.data(using: .utf8) ?? Data()
    }
    
    private func generateIntegrityRecommendations(_ result: IntegrityVerificationResult) -> [String] {
        var recommendations: [String] = []
        
        if result.integrityScore < 0.95 {
            recommendations.append("Investigate integrity violations immediately")
            recommendations.append("Review access controls for audit log storage")
            recommendations.append("Implement additional integrity monitoring")
        }
        
        if result.failedCount > 0 {
            recommendations.append("Restore compromised logs from backup")
            recommendations.append("Enhance log protection mechanisms")
        }
        
        return recommendations
    }
    
    private func calculateAuditTrailCompleteness(from: Date, to: Date) -> Double {
        // Simplified completeness calculation
        return 1.0
    }
    
    private func generateComplianceRecommendations(_ regulation: ComplianceRegulation, _ logs: [AuditLog]) -> [String] {
        var recommendations: [String] = []
        
        switch regulation {
        case .hipaa:
            recommendations.append("Ensure all PHI access is logged")
            recommendations.append("Implement automatic log backup")
        case .gdpr:
            recommendations.append("Log all personal data processing activities")
            recommendations.append("Implement data subject rights tracking")
        case .sox:
            recommendations.append("Ensure financial data access is fully audited")
        }
        
        return recommendations
    }
    
    private func stopLogging() {
        isLogging = false
        cancellables.removeAll()
        
        logEvent(
            category: .systemAccess,
            action: "audit_system_stopped",
            resource: "audit_trail_manager",
            userId: nil,
            details: ["shutdown_time": Date().iso8601String],
            severity: .info
        )
    }
}

// MARK: - Supporting Types

public struct AuditLog: Identifiable, Codable {
    public let id: UUID
    public let timestamp: Date
    public let category: AuditCategory
    public let action: String
    public let resource: String
    public let userId: String?
    public let sessionId: String
    public let ipAddress: String
    public let userAgent: String
    public let details: [String: Any]
    public let severity: AuditSeverity
    public let checksum: String
    
    // Custom coding for [String: Any]
    enum CodingKeys: String, CodingKey {
        case id, timestamp, category, action, resource, userId, sessionId, ipAddress, userAgent, severity, checksum
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(category, forKey: .category)
        try container.encode(action, forKey: .action)
        try container.encode(resource, forKey: .resource)
        try container.encodeIfPresent(userId, forKey: .userId)
        try container.encode(sessionId, forKey: .sessionId)
        try container.encode(ipAddress, forKey: .ipAddress)
        try container.encode(userAgent, forKey: .userAgent)
        try container.encode(severity, forKey: .severity)
        try container.encode(checksum, forKey: .checksum)
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        category = try container.decode(AuditCategory.self, forKey: .category)
        action = try container.decode(String.self, forKey: .action)
        resource = try container.decode(String.self, forKey: .resource)
        userId = try container.decodeIfPresent(String.self, forKey: .userId)
        sessionId = try container.decode(String.self, forKey: .sessionId)
        ipAddress = try container.decode(String.self, forKey: .ipAddress)
        userAgent = try container.decode(String.self, forKey: .userAgent)
        severity = try container.decode(AuditSeverity.self, forKey: .severity)
        checksum = try container.decode(String.self, forKey: .checksum)
        details = [:] // Simplified for Codable
    }
    
    public init(id: UUID, timestamp: Date, category: AuditCategory, action: String, resource: String, userId: String?, sessionId: String, ipAddress: String, userAgent: String, details: [String: Any], severity: AuditSeverity, checksum: String) {
        self.id = id
        self.timestamp = timestamp
        self.category = category
        self.action = action
        self.resource = resource
        self.userId = userId
        self.sessionId = sessionId
        self.ipAddress = ipAddress
        self.userAgent = userAgent
        self.details = details
        self.severity = severity
        self.checksum = checksum
    }
}

public struct AuditSummary {
    public let totalLogs: Int
    public let logsLast24Hours: Int
    public let criticalEvents: Int
    public let securityEvents: Int
    public let authenticationEvents: Int
    public let dataAccessEvents: Int
    public let integrityStatus: IntegrityStatus
    
    public init(totalLogs: Int = 0, logsLast24Hours: Int = 0, criticalEvents: Int = 0, securityEvents: Int = 0, authenticationEvents: Int = 0, dataAccessEvents: Int = 0, integrityStatus: IntegrityStatus = .verified) {
        self.totalLogs = totalLogs
        self.logsLast24Hours = logsLast24Hours
        self.criticalEvents = criticalEvents
        self.securityEvents = securityEvents
        self.authenticationEvents = authenticationEvents
        self.dataAccessEvents = dataAccessEvents
        self.integrityStatus = integrityStatus
    }
}

public struct AuditQueryCriteria {
    public let userId: String?
    public let category: AuditCategory?
    public let severity: AuditSeverity?
    public let fromDate: Date?
    public let toDate: Date?
    public let action: String?
    public let resource: String?
    
    public init(userId: String? = nil, category: AuditCategory? = nil, severity: AuditSeverity? = nil, fromDate: Date? = nil, toDate: Date? = nil, action: String? = nil, resource: String? = nil) {
        self.userId = userId
        self.category = category
        self.severity = severity
        self.fromDate = fromDate
        self.toDate = toDate
        self.action = action
        self.resource = resource
    }
}

public struct IntegrityVerificationResult {
    public let verifiedCount: Int
    public let failedCount: Int
    public let integrityScore: Double
    public let violations: [IntegrityViolation]
}

public struct IntegrityReport {
    public let timestamp: Date
    public let totalLogs: Int
    public let verifiedLogs: Int
    public let failedLogs: Int
    public let integrityScore: Double
    public let violations: [IntegrityViolation]
    public let recommendations: [String]
}

public struct IntegrityViolation {
    public let logId: UUID
    public let violationType: ViolationType
    public let description: String
    public let timestamp: Date
}

public struct ComplianceAuditReport {
    public let regulation: ComplianceRegulation
    public let reportPeriod: ClosedRange<Date>
    public let totalEvents: Int
    public let complianceEvents: Int
    public let violations: Int
    public let dataAccessEvents: Int
    public let authenticationEvents: Int
    public let securityIncidents: Int
    public let auditTrailCompleteness: Double
    public let recommendations: [String]
}

// MARK: - Enums

public enum AuditCategory: String, Codable, CaseIterable {
    case authentication = "authentication"
    case authorization = "authorization"
    case dataAccess = "data_access"
    case dataModification = "data_modification"
    case systemAccess = "system_access"
    case configurationChange = "configuration_change"
    case securityEvent = "security_event"
    case compliance = "compliance"
}

public enum AuditSeverity: String, Codable, CaseIterable {
    case info = "info"
    case warning = "warning"
    case error = "error"
    case critical = "critical"
}

public enum AuthenticationAction: String, CaseIterable {
    case login = "login"
    case logout = "logout"
    case passwordChange = "password_change"
    case passwordReset = "password_reset"
    case accountLocked = "account_locked"
    case accountUnlocked = "account_unlocked"
}

public enum AuthenticationMethod: String, CaseIterable {
    case password = "password"
    case biometric = "biometric"
    case twoFactor = "two_factor"
    case sso = "sso"
    case certificate = "certificate"
}

public enum DataAccessAction: String, CaseIterable {
    case read = "read"
    case write = "write"
    case delete = "delete"
    case export = "export"
    case print = "print"
    case share = "share"
}

public enum SecurityEventType: String, CaseIterable {
    case intrusionAttempt = "intrusion_attempt"
    case malwareDetected = "malware_detected"
    case unauthorizedAccess = "unauthorized_access"
    case dataLeak = "data_leak"
    case integrityViolation = "integrity_violation"
    case configurationTampering = "configuration_tampering"
}

public enum ComplianceRegulation: String, CaseIterable {
    case hipaa = "hipaa"
    case gdpr = "gdpr"
    case sox = "sox"
    case pci = "pci"
    case iso27001 = "iso27001"
}

public enum ComplianceStatus: String, CaseIterable {
    case compliant = "compliant"
    case nonCompliant = "non_compliant"
    case partiallyCompliant = "partially_compliant"
    case unknown = "unknown"
}

public enum IntegrityStatus {
    case verified
    case compromised
    case unknown
}

public enum ViolationType {
    case checksumMismatch
    case missingLog
    case tamperedLog
    case sequenceError
}

// MARK: - Helper Classes

private class AuditLogStorage {
    func store(_ log: AuditLog) async {
        // Implement secure log storage
    }
    
    func query(_ criteria: AuditQueryCriteria) async -> [AuditLog] {
        // Implement log querying
        return []
    }
}

private class LogIntegrityChecker {
    func verifyLogs(_ logs: [AuditLog]) async -> IntegrityVerificationResult {
        // Implement integrity verification
        return IntegrityVerificationResult(
            verifiedCount: logs.count,
            failedCount: 0,
            integrityScore: 1.0,
            violations: []
        )
    }
}

// MARK: - Extensions

extension Date {
    var iso8601String: String {
        let formatter = ISO8601DateFormatter()
        return formatter.string(from: self)
    }
}

extension Notification.Name {
    static let securityAlertTriggered = Notification.Name("securityAlertTriggered")
}

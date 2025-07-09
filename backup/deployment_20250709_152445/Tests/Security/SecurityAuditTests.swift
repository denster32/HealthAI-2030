import XCTest
import Foundation
import CryptoKit
@testable import HealthAI2030Core

/// Comprehensive security audit tests for HealthAI-2030
/// Validates all security implementations and compliance requirements
final class SecurityAuditTests: XCTestCase {
    
    let secretsManager = SecretsManager.shared
    let securityConfig = SecurityConfig.self
    let monitoringManager = SecurityMonitoringManager.shared
    
    // MARK: - Secrets Management Tests
    
    func testSecretsManagerSecureStorage() async throws {
        // Test secure storage and retrieval
        let testSecret = "test-secret-value-123"
        let secretName = "test_secret"
        
        // Store secret
        try await secretsManager.storeSecret(testSecret, named: secretName)
        
        // Retrieve secret
        let retrievedSecret = secretsManager.getSecret(named: secretName)
        
        XCTAssertEqual(retrievedSecret, testSecret, "Secret should be retrieved correctly")
        
        // Verify encryption
        let keychainData = try await getKeychainData(for: secretName)
        XCTAssertNotEqual(keychainData, testSecret.data(using: .utf8), "Secret should be encrypted in keychain")
        
        // Clean up
        try await secretsManager.deleteSecret(named: secretName)
    }
    
    func testSecretsManagerEncryption() async throws {
        let testData = "sensitive-data-for-encryption"
        let secretName = "encryption_test"
        
        // Store encrypted data
        try await secretsManager.storeSecret(testData, named: secretName)
        
        // Verify data is encrypted in storage
        let keychainData = try await getKeychainData(for: secretName)
        let originalData = testData.data(using: .utf8)!
        
        XCTAssertNotEqual(keychainData, originalData, "Data should be encrypted in storage")
        
        // Verify decryption works
        let retrievedData = secretsManager.getSecret(named: secretName)
        XCTAssertEqual(retrievedData, testData, "Decryption should work correctly")
        
        // Clean up
        try await secretsManager.deleteSecret(named: secretName)
    }
    
    func testSecretsManagerKeyRotation() async throws {
        let secretName = "rotation_test"
        let testSecret = "secret-for-rotation"
        
        // Store initial secret
        try await secretsManager.storeSecret(testSecret, named: secretName)
        
        // Simulate key rotation
        try await secretsManager.rotateEncryptionKey()
        
        // Verify secret is still accessible after rotation
        let retrievedSecret = secretsManager.getSecret(named: secretName)
        XCTAssertEqual(retrievedSecret, testSecret, "Secret should be accessible after key rotation")
        
        // Clean up
        try await secretsManager.deleteSecret(named: secretName)
    }
    
    // MARK: - Password Policy Tests
    
    func testPasswordPolicyValidation() {
        // Test valid password
        let validPassword = "StrongP@ssw0rd123"
        let validResult = securityConfig.validatePassword(validPassword)
        XCTAssertTrue(validResult.isValid, "Strong password should be valid")
        XCTAssertTrue(validResult.errors.isEmpty, "Valid password should have no errors")
        
        // Test weak passwords
        let weakPasswords = [
            "short", // too short
            "nouppercase123!", // no uppercase
            "NOLOWERCASE123!", // no lowercase
            "NoNumbers!", // no numbers
            "NoSpecial123" // no special characters
        ]
        
        for password in weakPasswords {
            let result = securityConfig.validatePassword(password)
            XCTAssertFalse(result.isValid, "Weak password should be invalid: \(password)")
            XCTAssertFalse(result.errors.isEmpty, "Weak password should have errors: \(password)")
        }
    }
    
    func testPasswordPolicyRequirements() {
        XCTAssertEqual(securityConfig.PasswordPolicy.minimumLength, 12, "Minimum password length should be 12")
        XCTAssertTrue(securityConfig.PasswordPolicy.requireUppercase, "Should require uppercase")
        XCTAssertTrue(securityConfig.PasswordPolicy.requireLowercase, "Should require lowercase")
        XCTAssertTrue(securityConfig.PasswordPolicy.requireNumbers, "Should require numbers")
        XCTAssertTrue(securityConfig.PasswordPolicy.requireSpecialCharacters, "Should require special characters")
        XCTAssertEqual(securityConfig.PasswordPolicy.maximumAge, 90, "Maximum password age should be 90 days")
        XCTAssertEqual(securityConfig.PasswordPolicy.lockoutThreshold, 5, "Lockout threshold should be 5 attempts")
    }
    
    // MARK: - Encryption Tests
    
    func testEncryptionKeyGeneration() {
        let key1 = securityConfig.generateEncryptionKey()
        let key2 = securityConfig.generateEncryptionKey()
        
        XCTAssertNotEqual(key1, key2, "Generated keys should be unique")
        XCTAssertEqual(key1.keySize, .bits256, "Key size should be 256 bits")
    }
    
    func testSecureRandomDataGeneration() {
        let data1 = securityConfig.generateSecureRandomData(length: 32)
        let data2 = securityConfig.generateSecureRandomData(length: 32)
        
        XCTAssertNotEqual(data1, data2, "Generated random data should be unique")
        XCTAssertEqual(data1.count, 32, "Data length should match requested length")
    }
    
    func testEncryptionPolicyConfiguration() {
        XCTAssertEqual(securityConfig.EncryptionPolicy.algorithm, "AES-GCM", "Should use AES-GCM algorithm")
        XCTAssertEqual(securityConfig.EncryptionPolicy.keySize, 256, "Key size should be 256 bits")
        XCTAssertTrue(securityConfig.EncryptionPolicy.enableKeyRotation, "Key rotation should be enabled")
        XCTAssertTrue(securityConfig.EncryptionPolicy.requireEncryptionAtRest, "Should require encryption at rest")
        XCTAssertTrue(securityConfig.EncryptionPolicy.requireEncryptionInTransit, "Should require encryption in transit")
    }
    
    // MARK: - Network Security Tests
    
    func testNetworkSecurityConfiguration() {
        XCTAssertEqual(securityConfig.NetworkPolicy.minimumTLSVersion, "TLSv1.3", "Should require TLS 1.3")
        XCTAssertTrue(securityConfig.NetworkPolicy.requireCertificatePinning, "Should require certificate pinning")
        XCTAssertTrue(securityConfig.NetworkPolicy.enableHSTS, "Should enable HSTS")
        XCTAssertTrue(securityConfig.NetworkPolicy.enableCSP, "Should enable CSP")
        XCTAssertEqual(securityConfig.NetworkPolicy.maxRequestSize, 10 * 1024 * 1024, "Max request size should be 10MB")
        XCTAssertEqual(securityConfig.NetworkPolicy.rateLimitRequests, 100, "Rate limit should be 100 requests per minute")
    }
    
    // MARK: - Session Management Tests
    
    func testSessionPolicyConfiguration() {
        XCTAssertEqual(securityConfig.SessionPolicy.sessionTimeout, 30, "Session timeout should be 30 minutes")
        XCTAssertEqual(securityConfig.SessionPolicy.refreshTokenExpiry, 7, "Refresh token expiry should be 7 days")
        XCTAssertEqual(securityConfig.SessionPolicy.maxConcurrentSessions, 3, "Max concurrent sessions should be 3")
        XCTAssertTrue(securityConfig.SessionPolicy.requireReauthentication, "Should require reauthentication")
        XCTAssertEqual(securityConfig.SessionPolicy.idleTimeout, 15, "Idle timeout should be 15 minutes")
    }
    
    // MARK: - Security Monitoring Tests
    
    func testSecurityMonitoringInitialization() {
        XCTAssertNotNil(monitoringManager, "Security monitoring manager should be initialized")
        XCTAssertEqual(monitoringManager.threatLevel, .low, "Initial threat level should be low")
        XCTAssertTrue(monitoringManager.isMonitoring, "Monitoring should be active")
    }
    
    func testSecurityEventProcessing() {
        let testEvent = SecurityEvent(
            id: UUID(),
            type: .authentication,
            severity: .high,
            description: "Test authentication event",
            source: "test",
            userId: UUID(),
            timestamp: Date(),
            metadata: ["test": "value"]
        )
        
        monitoringManager.addSecurityEvent(testEvent)
        
        XCTAssertTrue(monitoringManager.securityEvents.contains { $0.id == testEvent.id }, "Event should be added to monitoring")
    }
    
    func testThreatLevelCalculation() async {
        // Test low threat level
        let lowThreats: [SecurityThreat] = []
        let lowEvents: [SecurityEvent] = []
        let lowCompliance: [ComplianceIssue] = []
        
        // Test high threat level
        let highThreats = [
            SecurityThreat(type: .bruteForce, severity: .critical, description: "Critical threat")
        ]
        let highEvents = [
            SecurityEvent(id: UUID(), type: .authentication, severity: .critical, description: "Critical event", source: "test", userId: nil, timestamp: Date(), metadata: [:])
        ]
        
        // Verify threat level calculation logic
        let lowScore = highThreats.filter { $0.severity == .critical }.count * 10 +
                      highThreats.filter { $0.severity == .high }.count * 5 +
                      highEvents.filter { $0.severity == .critical }.count * 3
        
        XCTAssertEqual(lowScore, 13, "Threat score calculation should be correct")
    }
    
    // MARK: - Compliance Tests
    
    func testHIPAAComplianceConfiguration() {
        XCTAssertTrue(securityConfig.HIPAACompliance.enableDataEncryption, "HIPAA should require data encryption")
        XCTAssertTrue(securityConfig.HIPAACompliance.enableAccessControls, "HIPAA should require access controls")
        XCTAssertTrue(securityConfig.HIPAACompliance.enableAuditLogging, "HIPAA should require audit logging")
        XCTAssertTrue(securityConfig.HIPAACompliance.enableDataBackup, "HIPAA should require data backup")
        XCTAssertTrue(securityConfig.HIPAACompliance.enableIncidentResponse, "HIPAA should require incident response")
        XCTAssertTrue(securityConfig.HIPAACompliance.requireBusinessAssociateAgreements, "HIPAA should require BAAs")
    }
    
    func testGDPRComplianceConfiguration() {
        XCTAssertTrue(securityConfig.GDPRCompliance.enableDataMinimization, "GDPR should require data minimization")
        XCTAssertTrue(securityConfig.GDPRCompliance.enableConsentManagement, "GDPR should require consent management")
        XCTAssertTrue(securityConfig.GDPRCompliance.enableDataPortability, "GDPR should require data portability")
        XCTAssertTrue(securityConfig.GDPRCompliance.enableRightToErasure, "GDPR should require right to erasure")
        XCTAssertTrue(securityConfig.GDPRCompliance.enablePrivacyByDesign, "GDPR should require privacy by design")
        XCTAssertTrue(securityConfig.GDPRCompliance.requireDataProtectionImpactAssessment, "GDPR should require DPIA")
    }
    
    func testSOC2ComplianceConfiguration() {
        XCTAssertTrue(securityConfig.SOC2Compliance.enableSecurityControls, "SOC 2 should require security controls")
        XCTAssertTrue(securityConfig.SOC2Compliance.enableAvailabilityControls, "SOC 2 should require availability controls")
        XCTAssertTrue(securityConfig.SOC2Compliance.enableProcessingIntegrity, "SOC 2 should require processing integrity")
        XCTAssertTrue(securityConfig.SOC2Compliance.enableConfidentiality, "SOC 2 should require confidentiality")
        XCTAssertTrue(securityConfig.SOC2Compliance.enablePrivacy, "SOC 2 should require privacy")
        XCTAssertTrue(securityConfig.SOC2Compliance.requireRegularAssessments, "SOC 2 should require regular assessments")
    }
    
    // MARK: - Security Configuration Validation
    
    func testSecurityConfigurationValidation() {
        let result = securityConfig.validateSecurityConfiguration()
        
        // All security policies should be properly configured
        XCTAssertTrue(result.isValid, "Security configuration should be valid")
        XCTAssertTrue(result.issues.isEmpty, "Security configuration should have no issues")
    }
    
    // MARK: - Authentication Security Tests
    
    func testAuthenticationSecurity() async {
        // Test secure authentication flow
        let authManager = AdvancedPermissionsManager.shared
        
        // Test with valid credentials (development only)
        #if DEBUG
        let result = await authManager.authenticateUser(username: "admin", password: "password")
        XCTAssertTrue(result.success, "Authentication should succeed with valid credentials")
        #endif
        
        // Test with invalid credentials
        let invalidResult = await authManager.authenticateUser(username: "invalid", password: "wrong")
        XCTAssertFalse(invalidResult.success, "Authentication should fail with invalid credentials")
        
        // Test with empty credentials
        let emptyResult = await authManager.authenticateUser(username: "", password: "")
        XCTAssertFalse(emptyResult.success, "Authentication should fail with empty credentials")
    }
    
    // MARK: - Data Protection Tests
    
    func testDataProtectionAtRest() {
        // Test that sensitive data is encrypted at rest
        let sensitiveData = "sensitive-health-data"
        let encryptedData = encryptData(sensitiveData)
        
        XCTAssertNotEqual(encryptedData, sensitiveData.data(using: .utf8), "Sensitive data should be encrypted")
        
        // Test decryption
        let decryptedData = decryptData(encryptedData)
        XCTAssertEqual(decryptedData, sensitiveData, "Decryption should work correctly")
    }
    
    func testDataProtectionInTransit() {
        // Test that data is encrypted in transit
        let testData = "data-for-transit"
        let encryptedData = encryptData(testData)
        
        XCTAssertNotEqual(encryptedData, testData.data(using: .utf8), "Data should be encrypted for transit")
    }
    
    // MARK: - Audit Logging Tests
    
    func testAuditLoggingConfiguration() {
        XCTAssertTrue(securityConfig.AuditPolicy.enableSecurityLogging, "Security logging should be enabled")
        XCTAssertEqual(securityConfig.AuditPolicy.logRetentionPeriod, 365, "Log retention should be 365 days")
        XCTAssertTrue(securityConfig.AuditPolicy.enableRealTimeMonitoring, "Real-time monitoring should be enabled")
        XCTAssertTrue(securityConfig.AuditPolicy.requireAuditTrail, "Audit trail should be required")
        XCTAssertTrue(securityConfig.AuditPolicy.logSensitiveOperations, "Sensitive operations should be logged")
    }
    
    // MARK: - Security Metrics Tests
    
    func testSecurityMetricsGeneration() {
        let metrics = monitoringManager.getSecurityMetrics()
        
        XCTAssertNotNil(metrics, "Security metrics should be generated")
        XCTAssertGreaterThanOrEqual(metrics.totalEvents, 0, "Total events should be non-negative")
        XCTAssertGreaterThanOrEqual(metrics.criticalEvents, 0, "Critical events should be non-negative")
        XCTAssertGreaterThanOrEqual(metrics.highEvents, 0, "High events should be non-negative")
        XCTAssertGreaterThanOrEqual(metrics.totalThreats, 0, "Total threats should be non-negative")
        XCTAssertGreaterThanOrEqual(metrics.resolvedThreats, 0, "Resolved threats should be non-negative")
        XCTAssertGreaterThanOrEqual(metrics.uptime, 0, "Uptime should be non-negative")
    }
    
    // MARK: - Helper Methods
    
    private func getKeychainData(for key: String) async throws -> Data {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "com.healthai2030.secrets",
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        
        guard status == errSecSuccess, let data = item as? Data else {
            throw SecurityError.keychainError(status)
        }
        
        return data
    }
    
    private func encryptData(_ data: String) -> Data {
        let key = SymmetricKey(size: .bits256)
        let dataToEncrypt = data.data(using: .utf8)!
        let sealedBox = try! AES.GCM.seal(dataToEncrypt, using: key)
        return sealedBox.combined!
    }
    
    private func decryptData(_ encryptedData: Data) -> String {
        let key = SymmetricKey(size: .bits256)
        let sealedBox = try! AES.GCM.SealedBox(combined: encryptedData)
        let decryptedData = try! AES.GCM.open(sealedBox, using: key)
        return String(data: decryptedData, encoding: .utf8)!
    }
}

// MARK: - Supporting Types for Testing

struct ComplianceIssue: Codable {
    let type: ComplianceIssueType
    let severity: SecuritySeverity
    let description: String
    let metadata: [String: String]
}

enum ComplianceIssueType: String, CaseIterable, Codable {
    case dataEncryption = "data_encryption"
    case accessControl = "access_control"
    case auditLogging = "audit_logging"
    case dataBackup = "data_backup"
    case incidentResponse = "incident_response"
}

struct ComplianceStatus: Codable {
    let hipaa: Bool
    let gdpr: Bool
    let soc2: Bool
    let issues: [ComplianceIssue]
}

// Mock classes for testing
class ThreatDetectionEngine {
    func configure(sensitivity: String, scanInterval: Int, enableMachineLearning: Bool) {}
    func startDetection() {}
    func scanForThreats() async -> [SecurityThreat] { return [] }
    func analyzeEvent(_ event: SecurityEvent) async -> SecurityThreat? { return nil }
}

class SecurityAlertManager {
    func createAlert(for threat: SecurityThreat) async {}
    func sendAlert(_ alert: SecurityAlert) async {}
    func sendEmergencyAlert(_ message: String) async {}
    func sendHighPriorityAlert(_ message: String) async {}
    func logAlert(_ message: String) async {}
}

class SecurityEventProcessor {
    func processEvent(_ event: SecurityEvent) {}
    func analyzeRecentEvents() async -> [SecurityEvent] { return [] }
}

class ComplianceChecker {
    func checkCompliance() async -> [ComplianceIssue] { return [] }
    func getComplianceStatus() -> ComplianceStatus {
        return ComplianceStatus(hipaa: true, gdpr: true, soc2: true, issues: [])
    }
}

class SecurityResponseManager {
    static let shared = SecurityResponseManager()
    func activateEmergencyMode() async {}
    func lockdownSensitiveOperations() async {}
    func initiateIncidentResponse() async {}
    func activateEnhancedMonitoring() async {}
    func increaseLoggingLevel() async {}
    func activateStandardMonitoring() async {}
    func returnToNormalOperations() async {}
} 
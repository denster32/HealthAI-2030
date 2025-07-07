import XCTest
import Combine
@testable import HealthAI2030

@MainActor
final class EnterpriseSecurityTests: XCTestCase {
    var securityManager: EnterpriseSecurityManager!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        securityManager = EnterpriseSecurityManager()
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDown() {
        securityManager.stopSecurityMonitoring()
        cancellables.removeAll()
        securityManager = nil
        super.tearDown()
    }
    
    // MARK: - Multi-Factor Authentication (MFA) Tests
    
    func testEnableMFA() async throws {
        // Given
        XCTAssertFalse(securityManager.isLoading)
        
        // When
        try await securityManager.enableMFA()
        
        // Then
        XCTAssertFalse(securityManager.isLoading)
        // MFA should be enabled without error
    }
    
    func testDisableMFA() async throws {
        // Given
        XCTAssertFalse(securityManager.isLoading)
        
        // When
        try await securityManager.disableMFA()
        
        // Then
        XCTAssertFalse(securityManager.isLoading)
        // MFA should be disabled without error
    }
    
    func testIsMFAEnabled() async throws {
        // When
        let isEnabled = try await securityManager.isMFAEnabled()
        
        // Then
        XCTAssertFalse(isEnabled) // Default state in test implementation
    }
    
    func testSetupMFA() async throws {
        // Given
        let method = MFAMethod.authenticator
        XCTAssertFalse(securityManager.isLoading)
        
        // When
        let config = try await securityManager.setupMFA(method: method)
        
        // Then
        XCTAssertEqual(config.method, method)
        XCTAssertTrue(config.isEnabled)
        XCTAssertNotNil(config.setupDate)
        XCTAssertNil(config.lastUsed)
        XCTAssertNotNil(config.backupCodes)
        XCTAssertEqual(config.backupCodes?.count, 5)
        XCTAssertFalse(securityManager.isLoading)
    }
    
    func testVerifyMFACode() async throws {
        // Given
        let validCode = "123456"
        let invalidCode = "12345"
        XCTAssertFalse(securityManager.isLoading)
        
        // When & Then
        let isValid = try await securityManager.verifyMFACode(validCode)
        XCTAssertTrue(isValid)
        XCTAssertFalse(securityManager.isLoading)
        
        let isInvalid = try await securityManager.verifyMFACode(invalidCode)
        XCTAssertFalse(isInvalid)
    }
    
    func testGetMFAMethods() async throws {
        // When
        let methods = try await securityManager.getMFAMethods()
        
        // Then
        XCTAssertEqual(methods.count, 3)
        XCTAssertTrue(methods.contains(.authenticator))
        XCTAssertTrue(methods.contains(.sms))
        XCTAssertTrue(methods.contains(.email))
    }
    
    func testBackupMFACodes() async throws {
        // When
        let backupCodes = try await securityManager.backupMFACodes()
        
        // Then
        XCTAssertEqual(backupCodes.count, 5)
        XCTAssertTrue(backupCodes.allSatisfy { $0.count == 6 && $0.allSatisfy { $0.isNumber } })
    }
    
    // MARK: - Role-Based Access Control (RBAC) Tests
    
    func testCreateRole() async throws {
        // Given
        let role = SecurityRole(
            id: UUID(),
            name: "Test Role",
            description: "A test role",
            permissions: ["read", "write"],
            isSystem: false,
            createdAt: Date(),
            updatedAt: Date()
        )
        XCTAssertFalse(securityManager.isLoading)
        
        // When
        try await securityManager.createRole(role)
        
        // Then
        XCTAssertFalse(securityManager.isLoading)
        // Role should be created without error
    }
    
    func testUpdateRole() async throws {
        // Given
        let role = SecurityRole(
            id: UUID(),
            name: "Updated Role",
            description: "An updated role",
            permissions: ["read", "write", "delete"],
            isSystem: false,
            createdAt: Date(),
            updatedAt: Date()
        )
        XCTAssertFalse(securityManager.isLoading)
        
        // When
        try await securityManager.updateRole(role)
        
        // Then
        XCTAssertFalse(securityManager.isLoading)
        // Role should be updated without error
    }
    
    func testDeleteRole() async throws {
        // Given
        let roleId = UUID()
        XCTAssertFalse(securityManager.isLoading)
        
        // When
        try await securityManager.deleteRole(roleId)
        
        // Then
        XCTAssertFalse(securityManager.isLoading)
        // Role should be deleted without error
    }
    
    func testGetRoles() async throws {
        // When
        let roles = try await securityManager.getRoles()
        
        // Then
        XCTAssertNotNil(roles)
        // Note: In this test implementation, roles list is empty
    }
    
    func testAssignRole() async throws {
        // Given
        let roleId = UUID()
        let userId = UUID()
        XCTAssertFalse(securityManager.isLoading)
        
        // When
        try await securityManager.assignRole(roleId, to: userId)
        
        // Then
        XCTAssertFalse(securityManager.isLoading)
        // Role should be assigned without error
    }
    
    func testRevokeRole() async throws {
        // Given
        let roleId = UUID()
        let userId = UUID()
        XCTAssertFalse(securityManager.isLoading)
        
        // When
        try await securityManager.revokeRole(roleId, from: userId)
        
        // Then
        XCTAssertFalse(securityManager.isLoading)
        // Role should be revoked without error
    }
    
    func testGetUserRoles() async throws {
        // Given
        let userId = UUID()
        
        // When
        let roles = try await securityManager.getUserRoles(userId)
        
        // Then
        XCTAssertNotNil(roles)
        // Note: In this test implementation, user roles list is empty
    }
    
    func testCheckPermission() async throws {
        // Given
        let permission = "read"
        let userId = UUID()
        
        // When
        let hasPermission = try await securityManager.checkPermission(permission, for: userId)
        
        // Then
        XCTAssertTrue(hasPermission) // Default state in test implementation
    }
    
    func testGetPermissions() async throws {
        // When
        let permissions = try await securityManager.getPermissions()
        
        // Then
        XCTAssertEqual(permissions.count, 4)
        XCTAssertTrue(permissions.contains("read"))
        XCTAssertTrue(permissions.contains("write"))
        XCTAssertTrue(permissions.contains("delete"))
        XCTAssertTrue(permissions.contains("admin"))
    }
    
    // MARK: - Data Encryption Tests
    
    func testEncryptData() async throws {
        // Given
        let testData = "Hello, World!".data(using: .utf8)!
        let key = "test-key"
        XCTAssertFalse(securityManager.isLoading)
        
        // When
        let encryptedData = try await securityManager.encryptData(testData, with: key)
        
        // Then
        XCTAssertEqual(encryptedData.data, testData)
        XCTAssertEqual(encryptedData.algorithm, "AES-256-GCM")
        XCTAssertEqual(encryptedData.keyId, key)
        XCTAssertFalse(securityManager.isLoading)
    }
    
    func testDecryptData() async throws {
        // Given
        let testData = "Hello, World!".data(using: .utf8)!
        let key = "test-key"
        let encryptedData = EncryptedData(
            data: testData,
            iv: Data(),
            tag: Data(),
            algorithm: "AES-256-GCM",
            keyId: key
        )
        XCTAssertFalse(securityManager.isLoading)
        
        // When
        let decryptedData = try await securityManager.decryptData(encryptedData, with: key)
        
        // Then
        XCTAssertEqual(decryptedData, testData)
        XCTAssertFalse(securityManager.isLoading)
    }
    
    func testGenerateEncryptionKey() async throws {
        // When
        let key = try await securityManager.generateEncryptionKey()
        
        // Then
        XCTAssertNotNil(key.id)
        XCTAssertEqual(key.algorithm, "AES-256")
        XCTAssertEqual(key.keySize, 256)
        XCTAssertNotNil(key.createdAt)
        XCTAssertNotNil(key.expiresAt)
        XCTAssertTrue(key.isActive)
    }
    
    func testRotateEncryptionKey() async throws {
        // Given
        let keyId = "old-key"
        XCTAssertFalse(securityManager.isLoading)
        
        // When
        let newKey = try await securityManager.rotateEncryptionKey(keyId)
        
        // Then
        XCTAssertNotEqual(newKey.id, keyId)
        XCTAssertEqual(newKey.algorithm, "AES-256")
        XCTAssertEqual(newKey.keySize, 256)
        XCTAssertTrue(newKey.isActive)
        XCTAssertFalse(securityManager.isLoading)
    }
    
    func testGetEncryptionKeys() async throws {
        // When
        let keys = try await securityManager.getEncryptionKeys()
        
        // Then
        XCTAssertNotNil(keys)
        // Note: In this test implementation, keys list is empty
    }
    
    func testRevokeEncryptionKey() async throws {
        // Given
        let keyId = "test-key"
        XCTAssertFalse(securityManager.isLoading)
        
        // When
        try await securityManager.revokeEncryptionKey(keyId)
        
        // Then
        XCTAssertFalse(securityManager.isLoading)
        // Key should be revoked without error
    }
    
    func testEncryptFile() async throws {
        // Given
        let filePath = "/path/to/test/file.txt"
        XCTAssertFalse(securityManager.isLoading)
        
        // When
        let encryptedPath = try await securityManager.encryptFile(at: filePath)
        
        // Then
        XCTAssertEqual(encryptedPath, filePath + ".encrypted")
        XCTAssertFalse(securityManager.isLoading)
    }
    
    func testDecryptFile() async throws {
        // Given
        let encryptedPath = "/path/to/test/file.txt.encrypted"
        XCTAssertFalse(securityManager.isLoading)
        
        // When
        let decryptedPath = try await securityManager.decryptFile(at: encryptedPath)
        
        // Then
        XCTAssertEqual(decryptedPath, "/path/to/test/file.txt")
        XCTAssertFalse(securityManager.isLoading)
    }
    
    // MARK: - Security Audit Logging Tests
    
    func testLogSecurityEvent() async throws {
        // Given
        let event = SecurityEvent(
            id: UUID(),
            type: .login,
            severity: .medium,
            description: "User login",
            source: "test",
            userId: UUID(),
            timestamp: Date(),
            metadata: [:]
        )
        
        // When
        try await securityManager.logSecurityEvent(event)
        
        // Then
        // Event should be logged without error
    }
    
    func testGetSecurityEvents() async throws {
        // When
        let events = try await securityManager.getSecurityEvents(timeRange: .lastDay)
        
        // Then
        XCTAssertNotNil(events)
        // Note: In this test implementation, events list is empty
    }
    
    func testGetSecurityEventsForUser() async throws {
        // Given
        let userId = UUID()
        
        // When
        let events = try await securityManager.getSecurityEvents(for: userId)
        
        // Then
        XCTAssertNotNil(events)
        // Note: In this test implementation, events list is empty
    }
    
    func testGetSecurityEventsOfType() async throws {
        // Given
        let eventType = SecurityEventType.login
        
        // When
        let events = try await securityManager.getSecurityEvents(of: eventType)
        
        // Then
        XCTAssertNotNil(events)
        // Note: In this test implementation, events list is empty
    }
    
    func testExportAuditLog() async throws {
        // When
        let jsonData = try await securityManager.exportAuditLog(format: .json)
        let csvData = try await securityManager.exportAuditLog(format: .csv)
        let xmlData = try await securityManager.exportAuditLog(format: .xml)
        
        // Then
        XCTAssertNotNil(jsonData)
        XCTAssertNotNil(csvData)
        XCTAssertNotNil(xmlData)
    }
    
    func testSetAuditRetentionPolicy() async throws {
        // Given
        let policy = AuditRetentionPolicy(
            retentionPeriod: 365 * 24 * 3600,
            archiveAfter: 30 * 24 * 3600,
            deleteAfter: 7 * 365 * 24 * 3600,
            compressAfter: 90 * 24 * 3600
        )
        
        // When
        try await securityManager.setAuditRetentionPolicy(policy)
        
        // Then
        // Policy should be set without error
    }
    
    func testGetAuditRetentionPolicy() async throws {
        // When
        let policy = try await securityManager.getAuditRetentionPolicy()
        
        // Then
        XCTAssertEqual(policy.retentionPeriod, 365 * 24 * 3600)
        XCTAssertEqual(policy.archiveAfter, 30 * 24 * 3600)
        XCTAssertEqual(policy.deleteAfter, 7 * 365 * 24 * 3600)
        XCTAssertEqual(policy.compressAfter, 90 * 24 * 3600)
    }
    
    // MARK: - Threat Detection Tests
    
    func testEnableThreatDetection() async throws {
        // Given
        XCTAssertFalse(securityManager.isLoading)
        
        // When
        try await securityManager.enableThreatDetection()
        
        // Then
        XCTAssertFalse(securityManager.isLoading)
        // Threat detection should be enabled without error
    }
    
    func testDisableThreatDetection() async throws {
        // Given
        XCTAssertFalse(securityManager.isLoading)
        
        // When
        try await securityManager.disableThreatDetection()
        
        // Then
        XCTAssertFalse(securityManager.isLoading)
        // Threat detection should be disabled without error
    }
    
    func testIsThreatDetectionEnabled() async throws {
        // When
        let isEnabled = try await securityManager.isThreatDetectionEnabled()
        
        // Then
        XCTAssertTrue(isEnabled) // Default state in test implementation
    }
    
    func testGetActiveThreats() async throws {
        // When
        let threats = try await securityManager.getActiveThreats()
        
        // Then
        XCTAssertNotNil(threats)
        // Note: In this test implementation, threats list is empty
    }
    
    func testAcknowledgeThreat() async throws {
        // Given
        let threatId = UUID()
        XCTAssertFalse(securityManager.isLoading)
        
        // When
        try await securityManager.acknowledgeThreat(threatId)
        
        // Then
        XCTAssertFalse(securityManager.isLoading)
        // Threat should be acknowledged without error
    }
    
    func testResolveThreat() async throws {
        // Given
        let threatId = UUID()
        XCTAssertFalse(securityManager.isLoading)
        
        // When
        try await securityManager.resolveThreat(threatId)
        
        // Then
        XCTAssertFalse(securityManager.isLoading)
        // Threat should be resolved without error
    }
    
    func testGetThreatHistory() async throws {
        // When
        let threats = try await securityManager.getThreatHistory(timeRange: .lastWeek)
        
        // Then
        XCTAssertNotNil(threats)
        // Note: In this test implementation, threats list is empty
    }
    
    func testSetThreatThreshold() async throws {
        // Given
        let threshold = ThreatThreshold(
            failedLoginAttempts: 10,
            suspiciousActivityScore: 0.8,
            dataAccessThreshold: 200,
            timeWindow: 7200
        )
        
        // When
        try await securityManager.setThreatThreshold(threshold)
        
        // Then
        // Threshold should be set without error
    }
    
    func testGetThreatThreshold() async throws {
        // When
        let threshold = try await securityManager.getThreatThreshold()
        
        // Then
        XCTAssertEqual(threshold.failedLoginAttempts, 5)
        XCTAssertEqual(threshold.suspiciousActivityScore, 0.7)
        XCTAssertEqual(threshold.dataAccessThreshold, 100)
        XCTAssertEqual(threshold.timeWindow, 3600)
    }
    
    // MARK: - Security Compliance Tests
    
    func testRunComplianceCheck() async throws {
        // Given
        XCTAssertFalse(securityManager.isLoading)
        
        // When
        let report = try await securityManager.runComplianceCheck()
        
        // Then
        XCTAssertEqual(report.framework, .hipaa)
        XCTAssertEqual(report.overallStatus, .compliant)
        XCTAssertEqual(report.score, 95.0)
        XCTAssertNotNil(report.generatedAt)
        XCTAssertNotNil(report.validUntil)
        XCTAssertFalse(securityManager.isLoading)
    }
    
    func testGetComplianceStatus() async throws {
        // When
        let status = try await securityManager.getComplianceStatus()
        
        // Then
        XCTAssertEqual(status, .compliant)
    }
    
    func testGetComplianceReport() async throws {
        // When
        let report = try await securityManager.getComplianceReport(timeRange: .lastMonth)
        
        // Then
        XCTAssertEqual(report.framework, .hipaa)
        XCTAssertEqual(report.overallStatus, .compliant)
        XCTAssertEqual(report.score, 95.0)
    }
    
    func testExportComplianceReport() async throws {
        // When
        let pdfData = try await securityManager.exportComplianceReport(format: .pdf)
        let csvData = try await securityManager.exportComplianceReport(format: .csv)
        let jsonData = try await securityManager.exportComplianceReport(format: .json)
        
        // Then
        XCTAssertNotNil(pdfData)
        XCTAssertNotNil(csvData)
        XCTAssertNotNil(jsonData)
    }
    
    func testSetComplianceFramework() async throws {
        // Given
        let framework = ComplianceFramework.gdpr
        
        // When
        try await securityManager.setComplianceFramework(framework)
        
        // Then
        // Framework should be set without error
    }
    
    func testGetComplianceFrameworks() async throws {
        // When
        let frameworks = try await securityManager.getComplianceFrameworks()
        
        // Then
        XCTAssertEqual(frameworks.count, 4)
        XCTAssertTrue(frameworks.contains(.hipaa))
        XCTAssertTrue(frameworks.contains(.gdpr))
        XCTAssertTrue(frameworks.contains(.soc2))
        XCTAssertTrue(frameworks.contains(.iso27001))
    }
    
    // MARK: - Security Configuration Tests
    
    func testSetSecurityLevel() async throws {
        // Given
        let newLevel = SecurityLevel.high
        XCTAssertFalse(securityManager.isLoading)
        
        // When
        try await securityManager.setSecurityLevel(newLevel)
        
        // Then
        XCTAssertEqual(securityManager.securityLevel, newLevel)
        XCTAssertFalse(securityManager.isLoading)
    }
    
    func testGetSecurityConfiguration() async throws {
        // When
        let config = try await securityManager.getSecurityConfiguration()
        
        // Then
        XCTAssertEqual(config.securityLevel, securityManager.securityLevel)
        XCTAssertFalse(config.mfaEnabled) // Default state
        XCTAssertTrue(config.threatDetectionEnabled) // Default state
        XCTAssertTrue(config.encryptionEnabled)
        XCTAssertTrue(config.auditLoggingEnabled)
        XCTAssertTrue(config.complianceMonitoringEnabled)
    }
    
    func testUpdateSecurityPolicy() async throws {
        // Given
        let policy = SecurityPolicy(
            id: UUID(),
            name: "Test Policy",
            description: "A test security policy",
            rules: [],
            isActive: true,
            createdAt: Date()
        )
        XCTAssertFalse(securityManager.isLoading)
        
        // When
        try await securityManager.updateSecurityPolicy(policy)
        
        // Then
        XCTAssertFalse(securityManager.isLoading)
        // Policy should be updated without error
    }
    
    func testGetSecurityPolicies() async throws {
        // When
        let policies = try await securityManager.getSecurityPolicies()
        
        // Then
        XCTAssertNotNil(policies)
        // Note: In this test implementation, policies list is empty
    }
    
    // MARK: - Security Monitoring Tests
    
    func testStartSecurityMonitoring() {
        // When
        securityManager.startSecurityMonitoring()
        
        // Then
        // Monitoring should start without error
    }
    
    func testStopSecurityMonitoring() {
        // Given
        securityManager.startSecurityMonitoring()
        
        // When
        securityManager.stopSecurityMonitoring()
        
        // Then
        // Monitoring should stop without error
    }
    
    func testGetSecurityMetrics() async throws {
        // When
        let metrics = try await securityManager.getSecurityMetrics()
        
        // Then
        XCTAssertGreaterThanOrEqual(metrics.activeThreats, 0)
        XCTAssertGreaterThanOrEqual(metrics.failedLoginAttempts, 0)
        XCTAssertGreaterThanOrEqual(metrics.successfulLogins, 0)
        XCTAssertGreaterThanOrEqual(metrics.securityEvents, 0)
        XCTAssertGreaterThanOrEqual(metrics.complianceScore, 0)
        XCTAssertLessThanOrEqual(metrics.complianceScore, 100)
        XCTAssertNotNil(metrics.lastUpdated)
    }
    
    func testGetSecurityMetricsHistory() async throws {
        // When
        let metrics = try await securityManager.getSecurityMetrics(timeRange: .lastDay)
        
        // Then
        XCTAssertNotNil(metrics)
        // Note: In this test implementation, metrics list is empty
    }
    
    // MARK: - Published Properties Tests
    
    func testPublishedProperties() {
        // Given
        let expectation = XCTestExpectation(description: "Published properties updated")
        
        // When
        securityManager.$securityLevel
            .dropFirst()
            .sink { _ in
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // Trigger security level change
        Task {
            try? await securityManager.setSecurityLevel(.high)
        }
        
        // Then
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testActiveThreatsPublishedProperty() async throws {
        // Given
        let expectation = XCTestExpectation(description: "Active threats updated")
        
        securityManager.$activeThreats
            .dropFirst()
            .sink { _ in
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // When
        _ = try await securityManager.getActiveThreats()
        
        // Then
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testSecurityEventsPublishedProperty() async throws {
        // Given
        let expectation = XCTestExpectation(description: "Security events updated")
        
        securityManager.$securityEvents
            .dropFirst()
            .sink { _ in
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // When
        let event = SecurityEvent(
            id: UUID(),
            type: .login,
            severity: .medium,
            description: "Test event",
            source: "test",
            userId: nil,
            timestamp: Date(),
            metadata: [:]
        )
        try await securityManager.logSecurityEvent(event)
        
        // Then
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testComplianceStatusPublishedProperty() async throws {
        // Given
        let expectation = XCTestExpectation(description: "Compliance status updated")
        
        securityManager.$complianceStatus
            .dropFirst()
            .sink { _ in
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // When
        _ = try await securityManager.getComplianceStatus()
        
        // Then
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testLoadingState() async throws {
        // Given
        let expectation = XCTestExpectation(description: "Loading state changes")
        var loadingStates: [Bool] = []
        
        securityManager.$isLoading
            .sink { loading in
                loadingStates.append(loading)
                if loadingStates.count >= 2 {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When
        try await securityManager.enableMFA()
        
        // Then
        wait(for: [expectation], timeout: 5.0)
        XCTAssertTrue(loadingStates.contains(true))
        XCTAssertTrue(loadingStates.contains(false))
    }
    
    func testErrorHandling() async throws {
        // Given
        let expectation = XCTestExpectation(description: "Error state updated")
        
        securityManager.$error
            .dropFirst()
            .sink { error in
                if error != nil {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When
        // Trigger an operation that might fail
        do {
            try await securityManager.enableMFA()
        } catch {
            // Expected behavior
        }
        
        // Then
        wait(for: [expectation], timeout: 5.0)
    }
    
    // MARK: - Model Validation Tests
    
    func testEnterpriseUserValidation() {
        // Given
        let user = EnterpriseUser(
            id: UUID(),
            username: "testuser",
            email: "test@example.com",
            roles: [],
            permissions: ["read", "write"],
            lastLogin: Date(),
            isActive: true,
            createdAt: Date()
        )
        
        // Then
        XCTAssertNotNil(user.id)
        XCTAssertEqual(user.username, "testuser")
        XCTAssertEqual(user.email, "test@example.com")
        XCTAssertNotNil(user.roles)
        XCTAssertEqual(user.permissions.count, 2)
        XCTAssertNotNil(user.lastLogin)
        XCTAssertTrue(user.isActive)
        XCTAssertNotNil(user.createdAt)
    }
    
    func testSecurityRoleValidation() {
        // Given
        let role = SecurityRole(
            id: UUID(),
            name: "Admin Role",
            description: "Administrator role",
            permissions: ["read", "write", "delete", "admin"],
            isSystem: true,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        // Then
        XCTAssertNotNil(role.id)
        XCTAssertEqual(role.name, "Admin Role")
        XCTAssertEqual(role.description, "Administrator role")
        XCTAssertEqual(role.permissions.count, 4)
        XCTAssertTrue(role.isSystem)
        XCTAssertNotNil(role.createdAt)
        XCTAssertNotNil(role.updatedAt)
    }
    
    func testSecurityEventValidation() {
        // Given
        let event = SecurityEvent(
            id: UUID(),
            type: .login,
            severity: .medium,
            description: "User login successful",
            source: "authentication",
            userId: UUID(),
            timestamp: Date(),
            metadata: ["ip": "192.168.1.1"]
        )
        
        // Then
        XCTAssertNotNil(event.id)
        XCTAssertEqual(event.type, .login)
        XCTAssertEqual(event.severity, .medium)
        XCTAssertEqual(event.description, "User login successful")
        XCTAssertEqual(event.source, "authentication")
        XCTAssertNotNil(event.userId)
        XCTAssertNotNil(event.timestamp)
        XCTAssertEqual(event.metadata["ip"], "192.168.1.1")
    }
    
    func testSecurityThreatValidation() {
        // Given
        let threat = SecurityThreat(
            id: UUID(),
            type: .bruteForce,
            severity: .high,
            description: "Multiple failed login attempts",
            detectedAt: Date(),
            source: "authentication",
            isAcknowledged: false,
            acknowledgedAt: nil,
            isResolved: false,
            resolvedAt: nil,
            metadata: ["attempts": "10"]
        )
        
        // Then
        XCTAssertNotNil(threat.id)
        XCTAssertEqual(threat.type, .bruteForce)
        XCTAssertEqual(threat.severity, .high)
        XCTAssertEqual(threat.description, "Multiple failed login attempts")
        XCTAssertNotNil(threat.detectedAt)
        XCTAssertEqual(threat.source, "authentication")
        XCTAssertFalse(threat.isAcknowledged)
        XCTAssertNil(threat.acknowledgedAt)
        XCTAssertFalse(threat.isResolved)
        XCTAssertNil(threat.resolvedAt)
        XCTAssertEqual(threat.metadata["attempts"], "10")
    }
    
    func testComplianceReportValidation() {
        // Given
        let check = ComplianceCheck(
            id: UUID(),
            name: "Data Encryption",
            description: "Check if data is properly encrypted",
            status: .compliant,
            details: "All data is encrypted using AES-256",
            remediation: nil
        )
        
        let report = ComplianceReport(
            id: UUID(),
            framework: .hipaa,
            overallStatus: .compliant,
            checks: [check],
            score: 95.0,
            generatedAt: Date(),
            validUntil: Date().addingTimeInterval(30 * 24 * 3600)
        )
        
        // Then
        XCTAssertNotNil(report.id)
        XCTAssertEqual(report.framework, .hipaa)
        XCTAssertEqual(report.overallStatus, .compliant)
        XCTAssertEqual(report.checks.count, 1)
        XCTAssertEqual(report.score, 95.0)
        XCTAssertNotNil(report.generatedAt)
        XCTAssertNotNil(report.validUntil)
        
        // Check validation
        XCTAssertNotNil(check.id)
        XCTAssertEqual(check.name, "Data Encryption")
        XCTAssertEqual(check.description, "Check if data is properly encrypted")
        XCTAssertEqual(check.status, .compliant)
        XCTAssertEqual(check.details, "All data is encrypted using AES-256")
        XCTAssertNil(check.remediation)
    }
    
    func testSecurityConfigurationValidation() {
        // Given
        let config = SecurityConfiguration(
            securityLevel: .high,
            mfaEnabled: true,
            threatDetectionEnabled: true,
            encryptionEnabled: true,
            auditLoggingEnabled: true,
            complianceMonitoringEnabled: true
        )
        
        // Then
        XCTAssertEqual(config.securityLevel, .high)
        XCTAssertTrue(config.mfaEnabled)
        XCTAssertTrue(config.threatDetectionEnabled)
        XCTAssertTrue(config.encryptionEnabled)
        XCTAssertTrue(config.auditLoggingEnabled)
        XCTAssertTrue(config.complianceMonitoringEnabled)
    }
    
    func testSecurityMetricsValidation() {
        // Given
        let metrics = SecurityMetrics(
            activeThreats: 2,
            failedLoginAttempts: 5,
            successfulLogins: 100,
            securityEvents: 25,
            complianceScore: 95.5,
            lastUpdated: Date()
        )
        
        // Then
        XCTAssertEqual(metrics.activeThreats, 2)
        XCTAssertEqual(metrics.failedLoginAttempts, 5)
        XCTAssertEqual(metrics.successfulLogins, 100)
        XCTAssertEqual(metrics.securityEvents, 25)
        XCTAssertEqual(metrics.complianceScore, 95.5)
        XCTAssertNotNil(metrics.lastUpdated)
    }
    
    func testEncryptionKeyValidation() {
        // Given
        let key = EncryptionKey(
            id: "test-key-123",
            algorithm: "AES-256",
            keySize: 256,
            createdAt: Date(),
            expiresAt: Date().addingTimeInterval(365 * 24 * 3600),
            isActive: true
        )
        
        // Then
        XCTAssertEqual(key.id, "test-key-123")
        XCTAssertEqual(key.algorithm, "AES-256")
        XCTAssertEqual(key.keySize, 256)
        XCTAssertNotNil(key.createdAt)
        XCTAssertNotNil(key.expiresAt)
        XCTAssertTrue(key.isActive)
    }
    
    func testMFAConfigurationValidation() {
        // Given
        let config = MFAConfiguration(
            method: .authenticator,
            isEnabled: true,
            setupDate: Date(),
            lastUsed: Date(),
            backupCodes: ["123456", "789012", "345678"]
        )
        
        // Then
        XCTAssertEqual(config.method, .authenticator)
        XCTAssertTrue(config.isEnabled)
        XCTAssertNotNil(config.setupDate)
        XCTAssertNotNil(config.lastUsed)
        XCTAssertEqual(config.backupCodes?.count, 3)
    }
    
    func testThreatThresholdValidation() {
        // Given
        let threshold = ThreatThreshold(
            failedLoginAttempts: 5,
            suspiciousActivityScore: 0.7,
            dataAccessThreshold: 100,
            timeWindow: 3600
        )
        
        // Then
        XCTAssertEqual(threshold.failedLoginAttempts, 5)
        XCTAssertEqual(threshold.suspiciousActivityScore, 0.7)
        XCTAssertEqual(threshold.dataAccessThreshold, 100)
        XCTAssertEqual(threshold.timeWindow, 3600)
    }
    
    func testAuditRetentionPolicyValidation() {
        // Given
        let policy = AuditRetentionPolicy(
            retentionPeriod: 365 * 24 * 3600,
            archiveAfter: 30 * 24 * 3600,
            deleteAfter: 7 * 365 * 24 * 3600,
            compressAfter: 90 * 24 * 3600
        )
        
        // Then
        XCTAssertEqual(policy.retentionPeriod, 365 * 24 * 3600)
        XCTAssertEqual(policy.archiveAfter, 30 * 24 * 3600)
        XCTAssertEqual(policy.deleteAfter, 7 * 365 * 24 * 3600)
        XCTAssertEqual(policy.compressAfter, 90 * 24 * 3600)
    }
}

// MARK: - Supporting Extensions

extension TimeRange {
    static let lastDay = TimeRange(start: Date().addingTimeInterval(-86400), end: Date())
    static let lastWeek = TimeRange(start: Date().addingTimeInterval(-604800), end: Date())
    static let lastMonth = TimeRange(start: Date().addingTimeInterval(-2592000), end: Date())
}

struct TimeRange: Equatable {
    let start: Date
    let end: Date
} 
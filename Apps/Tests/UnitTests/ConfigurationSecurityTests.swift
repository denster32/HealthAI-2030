import XCTest
@testable import HealthAI2030

@MainActor
final class ConfigurationSecurityTests: XCTestCase {
    var securityManager: ConfigurationSecurityManager!
    var testConfiguration: AppConfiguration!
    
    override func setUp() {
        super.setUp()
        securityManager = ConfigurationSecurityManager()
        testConfiguration = AppConfiguration.default
    }
    
    override func tearDown() {
        securityManager = nil
        testConfiguration = nil
        super.tearDown()
    }
    
    // MARK: - Configuration Encryption Tests
    func testEncryptConfiguration() async throws {
        let encryptedConfig = try await securityManager.encryptConfiguration(testConfiguration)
        
        XCTAssertNotNil(encryptedConfig)
        XCTAssertEqual(encryptedConfig.id.uuidString.count, 36) // UUID length
        XCTAssertFalse(encryptedConfig.encryptedData.isEmpty)
        XCTAssertFalse(encryptedConfig.iv.isEmpty)
        XCTAssertFalse(encryptedConfig.keyId.isEmpty)
        XCTAssertEqual(encryptedConfig.algorithm, "AES-GCM")
        XCTAssertFalse(encryptedConfig.checksum.isEmpty)
        
        // Verify encryption status
        XCTAssertTrue(securityManager.isEncrypted)
        XCTAssertFalse(securityManager.isLoading)
        XCTAssertNil(securityManager.error)
    }
    
    func testDecryptConfiguration() async throws {
        // First encrypt
        let encryptedConfig = try await securityManager.encryptConfiguration(testConfiguration)
        
        // Then decrypt
        let decryptedConfig = try await securityManager.decryptConfiguration(encryptedConfig)
        
        // Verify decryption
        XCTAssertEqual(decryptedConfig.version, testConfiguration.version)
        XCTAssertEqual(decryptedConfig.environment, testConfiguration.environment)
        XCTAssertEqual(decryptedConfig.apiConfiguration.baseURL, testConfiguration.apiConfiguration.baseURL)
        XCTAssertEqual(decryptedConfig.databaseConfiguration.url, testConfiguration.databaseConfiguration.url)
        XCTAssertEqual(decryptedConfig.securityConfiguration.encryptionEnabled, testConfiguration.securityConfiguration.encryptionEnabled)
        XCTAssertEqual(decryptedConfig.analyticsConfiguration.enabled, testConfiguration.analyticsConfiguration.enabled)
        
        XCTAssertFalse(securityManager.isLoading)
        XCTAssertNil(securityManager.error)
    }
    
    func testRotateEncryptionKeys() async throws {
        // First encrypt with current keys
        let encryptedConfig1 = try await securityManager.encryptConfiguration(testConfiguration)
        
        // Rotate keys
        try await securityManager.rotateEncryptionKeys()
        
        // Encrypt again (should use new keys)
        let encryptedConfig2 = try await securityManager.encryptConfiguration(testConfiguration)
        
        // Verify different encryption results (due to different keys/IVs)
        XCTAssertNotEqual(encryptedConfig1.encryptedData, encryptedConfig2.encryptedData)
        XCTAssertNotEqual(encryptedConfig1.iv, encryptedConfig2.iv)
        XCTAssertNotEqual(encryptedConfig1.keyId, encryptedConfig2.keyId)
        
        XCTAssertFalse(securityManager.isLoading)
        XCTAssertNil(securityManager.error)
    }
    
    // MARK: - Access Control Tests
    func testGrantAccess() async throws {
        let userId = "test_user_123"
        let role = AccessRole.developer
        let environment = Environment.production
        
        try await securityManager.grantAccess(userId, role: role, for: environment)
        
        // Verify access was granted
        XCTAssertTrue(securityManager.checkAccess(userId, for: environment, action: .read))
        XCTAssertTrue(securityManager.checkAccess(userId, for: environment, action: .write))
        XCTAssertTrue(securityManager.checkAccess(userId, for: environment, action: .deploy))
        XCTAssertFalse(securityManager.checkAccess(userId, for: environment, action: .delete))
        
        let userRoles = securityManager.getUserRoles(userId)
        XCTAssertTrue(userRoles.contains(role))
        
        XCTAssertFalse(securityManager.isLoading)
        XCTAssertNil(securityManager.error)
    }
    
    func testRevokeAccess() async throws {
        let userId = "test_user_456"
        let role = AccessRole.admin
        let environment = Environment.staging
        
        // Grant access first
        try await securityManager.grantAccess(userId, role: role, for: environment)
        XCTAssertTrue(securityManager.checkAccess(userId, for: environment, action: .read))
        
        // Revoke access
        try await securityManager.revokeAccess(userId, from: environment)
        
        // Verify access was revoked
        XCTAssertFalse(securityManager.checkAccess(userId, for: environment, action: .read))
        XCTAssertFalse(securityManager.checkAccess(userId, for: environment, action: .write))
        
        let userRoles = securityManager.getUserRoles(userId)
        XCTAssertFalse(userRoles.contains(role))
        
        XCTAssertFalse(securityManager.isLoading)
        XCTAssertNil(securityManager.error)
    }
    
    func testAccessControlForDifferentRoles() async throws {
        let adminUser = "admin_user"
        let developerUser = "developer_user"
        let viewerUser = "viewer_user"
        let environment = Environment.development
        
        // Grant different roles
        try await securityManager.grantAccess(adminUser, role: .admin, for: environment)
        try await securityManager.grantAccess(developerUser, role: .developer, for: environment)
        try await securityManager.grantAccess(viewerUser, role: .viewer, for: environment)
        
        // Test admin permissions
        XCTAssertTrue(securityManager.checkAccess(adminUser, for: environment, action: .read))
        XCTAssertTrue(securityManager.checkAccess(adminUser, for: environment, action: .write))
        XCTAssertTrue(securityManager.checkAccess(adminUser, for: environment, action: .delete))
        XCTAssertTrue(securityManager.checkAccess(adminUser, for: environment, action: .encrypt))
        
        // Test developer permissions
        XCTAssertTrue(securityManager.checkAccess(developerUser, for: environment, action: .read))
        XCTAssertTrue(securityManager.checkAccess(developerUser, for: environment, action: .write))
        XCTAssertTrue(securityManager.checkAccess(developerUser, for: environment, action: .deploy))
        XCTAssertFalse(securityManager.checkAccess(developerUser, for: environment, action: .delete))
        
        // Test viewer permissions
        XCTAssertTrue(securityManager.checkAccess(viewerUser, for: environment, action: .read))
        XCTAssertFalse(securityManager.checkAccess(viewerUser, for: environment, action: .write))
        XCTAssertFalse(securityManager.checkAccess(viewerUser, for: environment, action: .deploy))
        XCTAssertFalse(securityManager.checkAccess(viewerUser, for: environment, action: .delete))
    }
    
    func testAccessControlForNonExistentUser() {
        let nonExistentUser = "non_existent_user"
        let environment = Environment.production
        
        // User should not have any access
        XCTAssertFalse(securityManager.checkAccess(nonExistentUser, for: environment, action: .read))
        XCTAssertFalse(securityManager.checkAccess(nonExistentUser, for: environment, action: .write))
        XCTAssertFalse(securityManager.checkAccess(nonExistentUser, for: environment, action: .deploy))
        
        let userRoles = securityManager.getUserRoles(nonExistentUser)
        XCTAssertTrue(userRoles.isEmpty)
    }
    
    // MARK: - Audit Logging Tests
    func testGetAccessLogs() async throws {
        let logs = try await securityManager.getAccessLogs()
        
        XCTAssertNotNil(logs)
        // Logs may be empty in test environment
    }
    
    func testGetAccessLogsWithTimeRange() async throws {
        let timeRange = TimeRange.lastDay
        let logs = try await securityManager.getAccessLogs(timeRange: timeRange)
        
        XCTAssertNotNil(logs)
        // Verify logs are within time range
        let cutoffDate = Date().addingTimeInterval(-86400)
        for log in logs {
            XCTAssertGreaterThanOrEqual(log.timestamp, cutoffDate)
        }
    }
    
    func testGetAccessLogsWithUserId() async throws {
        let userId = "test_user_789"
        let logs = try await securityManager.getAccessLogs(userId: userId)
        
        XCTAssertNotNil(logs)
        // Verify all logs are for the specified user
        for log in logs {
            XCTAssertEqual(log.userId, userId)
        }
    }
    
    func testGetSecurityEvents() async throws {
        let events = try await securityManager.getSecurityEvents()
        
        XCTAssertNotNil(events)
        // Events may be empty in test environment
    }
    
    func testGetSecurityEventsWithSeverity() async throws {
        let severity = SecurityEventSeverity.high
        let events = try await securityManager.getSecurityEvents(severity: severity)
        
        XCTAssertNotNil(events)
        // Verify all events have the specified severity
        for event in events {
            XCTAssertEqual(event.severity, severity)
        }
    }
    
    func testExportAuditLogs() async throws {
        let format = AuditLogFormat.json
        let exportData = try await securityManager.exportAuditLogs(format: format)
        
        XCTAssertFalse(exportData.isEmpty)
        
        // Try to parse as JSON
        let jsonObject = try JSONSerialization.jsonObject(with: exportData)
        XCTAssertNotNil(jsonObject)
    }
    
    // MARK: - Compliance Management Tests
    func testGenerateComplianceReport() async throws {
        let standard = ComplianceStandard.hipaa
        let report = try await securityManager.generateComplianceReport(standard: standard)
        
        XCTAssertEqual(report.standard, standard)
        XCTAssertNotNil(report.generatedAt)
        XCTAssertNotNil(report.status)
        XCTAssertNotNil(report.findings)
        XCTAssertNotNil(report.recommendations)
        XCTAssertGreaterThanOrEqual(report.score, 0)
        XCTAssertLessThanOrEqual(report.score, 100)
    }
    
    func testValidateCompliance() async throws {
        let standard = ComplianceStandard.soc2
        let result = try await securityManager.validateCompliance(standard: standard)
        
        XCTAssertEqual(result.standard, standard)
        XCTAssertNotNil(result.isValid)
        XCTAssertNotNil(result.violations)
        XCTAssertGreaterThanOrEqual(result.score, 0)
        XCTAssertLessThanOrEqual(result.score, 100)
        XCTAssertNotNil(result.lastValidated)
    }
    
    func testGetComplianceStatus() async throws {
        let statuses = try await securityManager.getComplianceStatus()
        
        XCTAssertNotNil(statuses)
        XCTAssertFalse(statuses.isEmpty)
        
        // Verify all compliance standards are covered
        let standards = statuses.map { $0.standard }
        XCTAssertTrue(standards.contains(.hipaa))
        XCTAssertTrue(standards.contains(.soc2))
        XCTAssertTrue(standards.contains(.iso27001))
        XCTAssertTrue(standards.contains(.gdpr))
        XCTAssertTrue(standards.contains(.ccpa))
        XCTAssertTrue(standards.contains(.pci))
        
        // Verify status structure
        for status in statuses {
            XCTAssertNotNil(status.status)
            XCTAssertGreaterThanOrEqual(status.score, 0)
            XCTAssertLessThanOrEqual(status.score, 100)
        }
    }
    
    func testScheduleComplianceAudit() async throws {
        let standard = ComplianceStandard.gdpr
        let auditDate = Date().addingTimeInterval(86400 * 7) // 7 days from now
        
        try await securityManager.scheduleComplianceAudit(standard: standard, date: auditDate)
        
        // Verify no errors occurred
        XCTAssertNil(securityManager.error)
    }
    
    // MARK: - Backup and Recovery Tests
    func testCreateBackup() async throws {
        let backup = try await securityManager.createBackup(testConfiguration)
        
        XCTAssertNotNil(backup)
        XCTAssertEqual(backup.configurationId, testConfiguration.version)
        XCTAssertEqual(backup.environment, testConfiguration.environment)
        XCTAssertNotNil(backup.createdAt)
        XCTAssertGreaterThan(backup.size, 0)
        XCTAssertFalse(backup.checksum.isEmpty)
        XCTAssertTrue(backup.isEncrypted)
        XCTAssertFalse(backup.metadata.isEmpty)
        
        XCTAssertFalse(securityManager.isLoading)
        XCTAssertNil(securityManager.error)
    }
    
    func testRestoreBackup() async throws {
        // Create backup first
        let backup = try await securityManager.createBackup(testConfiguration)
        
        // Restore backup
        let restoredConfig = try await securityManager.restoreBackup(backup)
        
        // Verify restoration
        XCTAssertEqual(restoredConfig.version, testConfiguration.version)
        XCTAssertEqual(restoredConfig.environment, testConfiguration.environment)
        
        XCTAssertFalse(securityManager.isLoading)
        XCTAssertNil(securityManager.error)
    }
    
    func testListBackups() async throws {
        // Create multiple backups
        let backup1 = try await securityManager.createBackup(testConfiguration)
        let backup2 = try await securityManager.createBackup(testConfiguration)
        
        let backups = try await securityManager.listBackups()
        
        XCTAssertNotNil(backups)
        XCTAssertGreaterThanOrEqual(backups.count, 2)
        
        // Verify our backups are in the list
        let backupIds = backups.map { $0.id }
        XCTAssertTrue(backupIds.contains(backup1.id))
        XCTAssertTrue(backupIds.contains(backup2.id))
    }
    
    func testDeleteBackup() async throws {
        // Create backup first
        let backup = try await securityManager.createBackup(testConfiguration)
        
        // Verify backup exists
        let backupsBefore = try await securityManager.listBackups()
        XCTAssertTrue(backupsBefore.contains { $0.id == backup.id })
        
        // Delete backup
        try await securityManager.deleteBackup(backup)
        
        // Verify backup was deleted
        let backupsAfter = try await securityManager.listBackups()
        XCTAssertFalse(backupsAfter.contains { $0.id == backup.id })
    }
    
    // MARK: - Security Monitoring Tests
    func testGetSecurityMetrics() async throws {
        let metrics = try await securityManager.getSecurityMetrics()
        
        XCTAssertNotNil(metrics)
        XCTAssertGreaterThanOrEqual(metrics.totalAccessAttempts, 0)
        XCTAssertGreaterThanOrEqual(metrics.successfulAccesses, 0)
        XCTAssertGreaterThanOrEqual(metrics.failedAccesses, 0)
        XCTAssertGreaterThanOrEqual(metrics.securityEvents, 0)
        XCTAssertGreaterThanOrEqual(metrics.averageResponseTime, 0)
        XCTAssertNotNil(metrics.encryptionStatus)
        XCTAssertGreaterThanOrEqual(metrics.complianceScore, 0.0)
        XCTAssertLessThanOrEqual(metrics.complianceScore, 100.0)
    }
    
    func testSetSecurityAlert() async throws {
        let alert = SecurityAlert(
            id: UUID(),
            severity: .high,
            message: "Test security alert",
            timestamp: Date(),
            isAcknowledged: false,
            metadata: ["source": "test"]
        )
        
        try await securityManager.setSecurityAlert(alert)
        
        // Verify alert was set
        let alerts = try await securityManager.getSecurityAlerts()
        XCTAssertTrue(alerts.contains { $0.id == alert.id })
    }
    
    func testGetSecurityAlerts() async throws {
        let alerts = try await securityManager.getSecurityAlerts()
        
        XCTAssertNotNil(alerts)
        // Alerts may be empty in test environment
    }
    
    // MARK: - Error Handling Tests
    func testConfigurationSecurityErrorHandling() async {
        // Test error handling for invalid operations
        do {
            // Try to decrypt without encrypting first
            let invalidEncryptedConfig = EncryptedConfiguration(
                id: UUID(),
                encryptedData: Data(),
                iv: Data(),
                keyId: "invalid",
                algorithm: "AES-GCM",
                timestamp: Date(),
                checksum: "invalid"
            )
            
            _ = try await securityManager.decryptConfiguration(invalidEncryptedConfig)
            XCTFail("Should throw error for invalid encrypted configuration")
        } catch {
            XCTAssertTrue(error is ConfigurationSecurityError)
        }
    }
    
    // MARK: - Concurrent Operations Tests
    func testConcurrentSecurityOperations() async {
        await withTaskGroup(of: Void.self) { group in
            // Add multiple concurrent operations
            group.addTask {
                try? await self.securityManager.encryptConfiguration(self.testConfiguration)
            }
            
            group.addTask {
                try? await self.securityManager.grantAccess("user1", role: .developer, for: .development)
            }
            
            group.addTask {
                try? await self.securityManager.createBackup(self.testConfiguration)
            }
            
            group.addTask {
                _ = try? await self.securityManager.getSecurityMetrics()
            }
        }
        
        // Verify no crashes occurred
        XCTAssertNotNil(securityManager)
    }
    
    // MARK: - Performance Tests
    func testEncryptionPerformance() async throws {
        let startTime = Date()
        
        _ = try await securityManager.encryptConfiguration(testConfiguration)
        
        let encryptionTime = Date().timeIntervalSince(startTime)
        XCTAssertLessThan(encryptionTime, 2.0) // Should complete within 2 seconds
    }
    
    func testAccessControlPerformance() async throws {
        let startTime = Date()
        
        for i in 0..<100 {
            let userId = "perf_user_\(i)"
            try await securityManager.grantAccess(userId, role: .viewer, for: .development)
        }
        
        let accessControlTime = Date().timeIntervalSince(startTime)
        XCTAssertLessThan(accessControlTime, 5.0) // Should complete within 5 seconds
    }
    
    // MARK: - Memory Management Tests
    func testConfigurationSecurityManagerMemoryManagement() {
        weak var weakManager: ConfigurationSecurityManager?
        
        autoreleasepool {
            let manager = ConfigurationSecurityManager()
            weakManager = manager
        }
        
        // The manager should be deallocated after the autoreleasepool
        XCTAssertNil(weakManager)
    }
    
    // MARK: - Integration Tests
    func testCompleteSecurityWorkflow() async throws {
        let userId = "workflow_user"
        let environment = Environment.production
        
        // 1. Grant access
        try await securityManager.grantAccess(userId, role: .admin, for: environment)
        XCTAssertTrue(securityManager.checkAccess(userId, for: environment, action: .read))
        
        // 2. Encrypt configuration
        let encryptedConfig = try await securityManager.encryptConfiguration(testConfiguration)
        XCTAssertTrue(securityManager.isEncrypted)
        
        // 3. Create backup
        let backup = try await securityManager.createBackup(testConfiguration)
        XCTAssertNotNil(backup)
        
        // 4. Generate compliance report
        let report = try await securityManager.generateComplianceReport(standard: .hipaa)
        XCTAssertNotNil(report)
        
        // 5. Get security metrics
        let metrics = try await securityManager.getSecurityMetrics()
        XCTAssertNotNil(metrics)
        
        // 6. Set security alert
        let alert = SecurityAlert(
            id: UUID(),
            severity: .medium,
            message: "Workflow test alert",
            timestamp: Date(),
            isAcknowledged: false,
            metadata: [:]
        )
        try await securityManager.setSecurityAlert(alert)
        
        // 7. Rotate encryption keys
        try await securityManager.rotateEncryptionKeys()
        
        // 8. Decrypt configuration
        let decryptedConfig = try await securityManager.decryptConfiguration(encryptedConfig)
        XCTAssertEqual(decryptedConfig.version, testConfiguration.version)
        
        // 9. Restore backup
        let restoredConfig = try await securityManager.restoreBackup(backup)
        XCTAssertNotNil(restoredConfig)
        
        // 10. Revoke access
        try await securityManager.revokeAccess(userId, from: environment)
        XCTAssertFalse(securityManager.checkAccess(userId, for: environment, action: .read))
        
        // 11. Delete backup
        try await securityManager.deleteBackup(backup)
        
        // 12. Export audit logs
        let exportData = try await securityManager.exportAuditLogs(format: .json)
        XCTAssertFalse(exportData.isEmpty)
    }
} 
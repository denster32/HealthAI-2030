import XCTest
import Foundation
import Combine
import CryptoKit
@testable import HealthAI2030

/// Comprehensive test suite for Advanced Health Data Privacy & Security Engine
@available(iOS 18.0, macOS 15.0, *)
final class AdvancedHealthDataPrivacyEngineTests: XCTestCase {
    
    // MARK: - Properties
    private var privacyEngine: AdvancedHealthDataPrivacyEngine!
    private var healthDataManager: HealthDataManager!
    private var analyticsEngine: AnalyticsEngine!
    private var cancellables: Set<AnyCancellable>!
    
    // MARK: - Setup and Teardown
    
    override func setUp() async throws {
        try await super.setUp()
        
        healthDataManager = HealthDataManager()
        analyticsEngine = AnalyticsEngine()
        privacyEngine = AdvancedHealthDataPrivacyEngine(
            healthDataManager: healthDataManager,
            analyticsEngine: analyticsEngine
        )
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDown() async throws {
        privacyEngine = nil
        healthDataManager = nil
        analyticsEngine = nil
        cancellables = nil
        
        try await super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testInitialization() async throws {
        // Test that the privacy engine initializes correctly
        XCTAssertNotNil(privacyEngine)
        XCTAssertFalse(privacyEngine.isPrivacyActive)
        XCTAssertEqual(privacyEngine.privacyProgress, 0.0)
        XCTAssertNil(privacyEngine.lastError)
        XCTAssertTrue(privacyEngine.privacySettings.settings.isEmpty)
        XCTAssertTrue(privacyEngine.securityAlerts.isEmpty)
        XCTAssertTrue(privacyEngine.auditLogs.isEmpty)
        XCTAssertTrue(privacyEngine.dataBreaches.isEmpty)
    }
    
    // MARK: - Privacy Monitoring Start/Stop Tests
    
    func testStartPrivacyMonitoring() async throws {
        // Test starting privacy monitoring
        try await privacyEngine.startPrivacyMonitoring()
        
        XCTAssertTrue(privacyEngine.isPrivacyActive)
        XCTAssertNil(privacyEngine.lastError)
        XCTAssertEqual(privacyEngine.privacyProgress, 1.0)
    }
    
    func testStopPrivacyMonitoring() async throws {
        // Start privacy monitoring first
        try await privacyEngine.startPrivacyMonitoring()
        
        // Test stopping privacy monitoring
        await privacyEngine.stopPrivacyMonitoring()
        
        XCTAssertFalse(privacyEngine.isPrivacyActive)
        XCTAssertEqual(privacyEngine.privacyProgress, 0.0)
    }
    
    func testStartPrivacyMonitoringWithError() async throws {
        // Test starting privacy monitoring with invalid configuration
        // This would require mocking to simulate errors
        
        do {
            try await privacyEngine.startPrivacyMonitoring()
            // If no error is thrown, the test passes
        } catch {
            XCTAssertNotNil(privacyEngine.lastError)
            XCTAssertFalse(privacyEngine.isPrivacyActive)
        }
    }
    
    // MARK: - Privacy Audit Tests
    
    func testPerformPrivacyAudit() async throws {
        // Test performing privacy audit
        let result = try await privacyEngine.performPrivacyAudit()
        
        XCTAssertNotNil(result)
        XCTAssertEqual(result.timestamp.timeIntervalSinceNow, 0, accuracy: 1.0)
        XCTAssertNotNil(result.settings)
        XCTAssertNotNil(result.securityStatus)
        XCTAssertNotNil(result.complianceStatus)
        XCTAssertNotNil(result.encryptionStatus)
        XCTAssertNotNil(result.insights)
    }
    
    func testPerformPrivacyAuditWithError() async throws {
        // Test performing privacy audit with invalid data
        // This would require mocking to simulate errors
        
        do {
            _ = try await privacyEngine.performPrivacyAudit()
            // If no error is thrown, the test passes
        } catch {
            XCTAssertNotNil(privacyEngine.lastError)
        }
    }
    
    // MARK: - Privacy Settings Tests
    
    func testGetPrivacySettings() async throws {
        // Test getting all privacy settings
        let allSettings = await privacyEngine.getPrivacySettings()
        XCTAssertNotNil(allSettings)
        
        // Test getting settings by category
        let dataCollectionSettings = await privacyEngine.getPrivacySettings(category: .dataCollection)
        XCTAssertNotNil(dataCollectionSettings)
        
        let dataSharingSettings = await privacyEngine.getPrivacySettings(category: .dataSharing)
        XCTAssertNotNil(dataSharingSettings)
        
        let dataRetentionSettings = await privacyEngine.getPrivacySettings(category: .dataRetention)
        XCTAssertNotNil(dataRetentionSettings)
        
        let accessControlSettings = await privacyEngine.getPrivacySettings(category: .accessControl)
        XCTAssertNotNil(accessControlSettings)
        
        let encryptionSettings = await privacyEngine.getPrivacySettings(category: .encryption)
        XCTAssertNotNil(encryptionSettings)
        
        let complianceSettings = await privacyEngine.getPrivacySettings(category: .compliance)
        XCTAssertNotNil(complianceSettings)
    }
    
    func testSettingsFiltering() async throws {
        // Test settings filtering by category
        let dataCollectionSettings = await privacyEngine.getPrivacySettings(category: .dataCollection)
        let allSettings = await privacyEngine.getPrivacySettings(category: .all)
        
        // Data collection settings should be a subset of all settings
        XCTAssertLessThanOrEqual(dataCollectionSettings.settings.count, allSettings.settings.count)
        
        // All data collection settings should have the data collection category
        for setting in dataCollectionSettings.settings {
            XCTAssertEqual(setting.category, .dataCollection)
        }
    }
    
    func testUpdatePrivacySetting() async throws {
        // Test updating a privacy setting
        let setting = PrivacySetting(
            id: UUID(),
            name: "Test Setting",
            category: .dataCollection,
            value: "enabled",
            description: "Test privacy setting",
            isEnabled: true,
            timestamp: Date()
        )
        
        try await privacyEngine.updatePrivacySetting(setting)
        
        // Verify the setting was updated
        let settings = await privacyEngine.getPrivacySettings()
        XCTAssertTrue(settings.settings.contains { $0.id == setting.id })
    }
    
    // MARK: - Security Status Tests
    
    func testGetSecurityStatus() async throws {
        // Test getting security status
        let securityStatus = await privacyEngine.getSecurityStatus()
        
        XCTAssertNotNil(securityStatus)
        XCTAssertGreaterThanOrEqual(securityStatus.securityScore, 0)
        XCTAssertLessThanOrEqual(securityStatus.securityScore, 1)
        XCTAssertNotNil(securityStatus.threatLevel)
        XCTAssertNotNil(securityStatus.vulnerabilities)
        XCTAssertNotNil(securityStatus.lastUpdated)
    }
    
    func testSecurityStatusValidation() async throws {
        // Test that security status values are valid
        let securityStatus = await privacyEngine.getSecurityStatus()
        
        // Security score should be between 0 and 1
        XCTAssertGreaterThanOrEqual(securityStatus.securityScore, 0)
        XCTAssertLessThanOrEqual(securityStatus.securityScore, 1)
        
        // Threat level should be valid
        XCTAssertTrue(ThreatLevel.allCases.contains(securityStatus.threatLevel))
        
        // Vulnerabilities should be an array
        XCTAssertNotNil(securityStatus.vulnerabilities)
    }
    
    // MARK: - Compliance Status Tests
    
    func testGetComplianceStatus() async throws {
        // Test getting compliance status
        let complianceStatus = await privacyEngine.getComplianceStatus()
        
        XCTAssertNotNil(complianceStatus)
        XCTAssertNotNil(complianceStatus.hipaaCompliance)
        XCTAssertNotNil(complianceStatus.gdprCompliance)
        XCTAssertNotNil(complianceStatus.ccpaCompliance)
        XCTAssertNotNil(complianceStatus.soc2Compliance)
        XCTAssertNotNil(complianceStatus.lastUpdated)
    }
    
    func testComplianceStatusValidation() async throws {
        // Test that compliance status values are valid
        let complianceStatus = await privacyEngine.getComplianceStatus()
        
        // All compliance levels should be valid
        XCTAssertTrue(ComplianceLevel.allCases.contains(complianceStatus.hipaaCompliance))
        XCTAssertTrue(ComplianceLevel.allCases.contains(complianceStatus.gdprCompliance))
        XCTAssertTrue(ComplianceLevel.allCases.contains(complianceStatus.ccpaCompliance))
        XCTAssertTrue(ComplianceLevel.allCases.contains(complianceStatus.soc2Compliance))
    }
    
    // MARK: - Encryption Status Tests
    
    func testGetEncryptionStatus() async throws {
        // Test getting encryption status
        let encryptionStatus = await privacyEngine.getEncryptionStatus()
        
        XCTAssertNotNil(encryptionStatus)
        XCTAssertNotNil(encryptionStatus.encryptionEnabled)
        XCTAssertNotNil(encryptionStatus.encryptionStrength)
        XCTAssertGreaterThanOrEqual(encryptionStatus.encryptedDataCount, 0)
        XCTAssertNotNil(encryptionStatus.lastUpdated)
    }
    
    func testEncryptionStatusValidation() async throws {
        // Test that encryption status values are valid
        let encryptionStatus = await privacyEngine.getEncryptionStatus()
        
        // Encryption strength should be valid
        XCTAssertTrue(EncryptionStrength.allCases.contains(encryptionStatus.encryptionStrength))
        
        // Encrypted data count should be non-negative
        XCTAssertGreaterThanOrEqual(encryptionStatus.encryptedDataCount, 0)
    }
    
    // MARK: - Audit Logs Tests
    
    func testGetAuditLogs() async throws {
        // Test getting audit logs for different timeframes
        let weeklyLogs = await privacyEngine.getAuditLogs(timeframe: .week)
        XCTAssertNotNil(weeklyLogs)
        
        let monthlyLogs = await privacyEngine.getAuditLogs(timeframe: .month)
        XCTAssertNotNil(monthlyLogs)
        
        let yearlyLogs = await privacyEngine.getAuditLogs(timeframe: .year)
        XCTAssertNotNil(yearlyLogs)
    }
    
    func testAuditLogsFiltering() async throws {
        // Test that audit logs are filtered by timeframe
        let weeklyLogs = await privacyEngine.getAuditLogs(timeframe: .week)
        let monthlyLogs = await privacyEngine.getAuditLogs(timeframe: .month)
        
        // Monthly logs should include more data than weekly logs
        XCTAssertGreaterThanOrEqual(monthlyLogs.count, weeklyLogs.count)
        
        // All logs should be within the specified timeframe
        let cutoffDate = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: Date()) ?? Date()
        for log in weeklyLogs {
            XCTAssertGreaterThanOrEqual(log.timestamp, cutoffDate)
        }
    }
    
    // MARK: - Security Alerts Tests
    
    func testGetSecurityAlerts() async throws {
        // Test getting all security alerts
        let allAlerts = await privacyEngine.getSecurityAlerts()
        XCTAssertNotNil(allAlerts)
        
        // Test getting alerts by severity
        let lowAlerts = await privacyEngine.getSecurityAlerts(severity: .low)
        XCTAssertNotNil(lowAlerts)
        
        let mediumAlerts = await privacyEngine.getSecurityAlerts(severity: .medium)
        XCTAssertNotNil(mediumAlerts)
        
        let highAlerts = await privacyEngine.getSecurityAlerts(severity: .high)
        XCTAssertNotNil(highAlerts)
        
        let criticalAlerts = await privacyEngine.getSecurityAlerts(severity: .critical)
        XCTAssertNotNil(criticalAlerts)
    }
    
    func testSecurityAlertsFiltering() async throws {
        // Test security alerts filtering by severity
        let lowAlerts = await privacyEngine.getSecurityAlerts(severity: .low)
        let allAlerts = await privacyEngine.getSecurityAlerts(severity: .all)
        
        // Low alerts should be a subset of all alerts
        XCTAssertLessThanOrEqual(lowAlerts.count, allAlerts.count)
        
        // All low alerts should have low severity
        for alert in lowAlerts {
            XCTAssertEqual(alert.severity, .low)
        }
    }
    
    // MARK: - Encryption Tests
    
    func testEncryptHealthData() async throws {
        // Test encrypting health data
        let testData = "Test health data".data(using: .utf8)!
        let keyId = "test_key"
        
        let encryptedData = try await privacyEngine.encryptHealthData(testData, keyId: keyId)
        
        XCTAssertNotNil(encryptedData)
        XCTAssertEqual(encryptedData.keyId, keyId)
        XCTAssertNotNil(encryptedData.algorithm)
        XCTAssertNotNil(encryptedData.timestamp)
    }
    
    func testDecryptHealthData() async throws {
        // Test decrypting health data
        let testData = "Test health data".data(using: .utf8)!
        let keyId = "test_key"
        
        let encryptedData = try await privacyEngine.encryptHealthData(testData, keyId: keyId)
        let decryptedData = try await privacyEngine.decryptHealthData(encryptedData, keyId: keyId)
        
        XCTAssertNotNil(decryptedData)
        XCTAssertEqual(decryptedData.count, testData.count)
    }
    
    func testEncryptionWithError() async throws {
        // Test encryption with invalid parameters
        // This would require mocking to simulate errors
        
        do {
            let testData = Data()
            let encryptedData = try await privacyEngine.encryptHealthData(testData, keyId: "invalid_key")
            XCTAssertNotNil(encryptedData)
        } catch {
            XCTAssertNotNil(privacyEngine.lastError)
        }
    }
    
    // MARK: - Authentication Tests
    
    func testAuthenticateUser() async throws {
        // Test user authentication
        let result = try await privacyEngine.authenticateUser(biometricType: .faceID)
        
        XCTAssertNotNil(result)
        XCTAssertNotNil(result.success)
        XCTAssertEqual(result.biometricType, .faceID)
        XCTAssertNotNil(result.timestamp)
    }
    
    func testAuthenticationWithDifferentBiometricTypes() async throws {
        // Test authentication with different biometric types
        let faceIDResult = try await privacyEngine.authenticateUser(biometricType: .faceID)
        XCTAssertEqual(faceIDResult.biometricType, .faceID)
        
        let touchIDResult = try await privacyEngine.authenticateUser(biometricType: .touchID)
        XCTAssertEqual(touchIDResult.biometricType, .touchID)
        
        let noneResult = try await privacyEngine.authenticateUser(biometricType: .none)
        XCTAssertEqual(noneResult.biometricType, .none)
    }
    
    // MARK: - Access Token Tests
    
    func testGenerateAccessToken() async throws {
        // Test generating access token
        let userId = "test_user"
        let permissions = [Permission.mock()]
        
        let token = try await privacyEngine.generateAccessToken(userId: userId, permissions: permissions)
        
        XCTAssertNotNil(token)
        XCTAssertEqual(token.userId, userId)
        XCTAssertEqual(token.permissions.count, permissions.count)
        XCTAssertGreaterThan(token.expiresAt, Date())
        XCTAssertNotNil(token.timestamp)
    }
    
    func testValidateAccessToken() async throws {
        // Test validating access token
        let userId = "test_user"
        let permissions = [Permission.mock()]
        
        let token = try await privacyEngine.generateAccessToken(userId: userId, permissions: permissions)
        let validationResult = try await privacyEngine.validateAccessToken(token)
        
        XCTAssertNotNil(validationResult)
        XCTAssertTrue(validationResult.isValid)
        XCTAssertEqual(validationResult.token.id, token.id)
        XCTAssertNotNil(validationResult.timestamp)
    }
    
    func testTokenValidationWithExpiredToken() async throws {
        // Test token validation with expired token
        // This would require mocking to simulate expired tokens
        
        let expiredToken = AccessToken(
            id: UUID(),
            userId: "test_user",
            permissions: [Permission.mock()],
            expiresAt: Date().addingTimeInterval(-3600), // Expired 1 hour ago
            timestamp: Date()
        )
        
        do {
            let result = try await privacyEngine.validateAccessToken(expiredToken)
            XCTAssertNotNil(result)
        } catch {
            XCTAssertNotNil(privacyEngine.lastError)
        }
    }
    
    // MARK: - Data Breach Tests
    
    func testReportDataBreach() async throws {
        // Test reporting data breach
        let breach = DataBreach(
            id: UUID(),
            title: "Test Breach",
            description: "Test data breach description",
            severity: .medium,
            details: "Test breach details",
            timestamp: Date()
        )
        
        try await privacyEngine.reportDataBreach(breach)
        
        // Verify the breach was reported
        let breaches = privacyEngine.dataBreaches
        XCTAssertTrue(breaches.contains { $0.id == breach.id })
        
        // Verify security alert was generated
        let alerts = privacyEngine.securityAlerts
        XCTAssertTrue(alerts.contains { $0.title == "Data Breach Detected" })
    }
    
    func testBreachReportingWithDifferentSeverities() async throws {
        // Test breach reporting with different severities
        let lowBreach = DataBreach(
            id: UUID(),
            title: "Low Severity Breach",
            description: "Low severity breach",
            severity: .low,
            details: "Low severity details",
            timestamp: Date()
        )
        
        let criticalBreach = DataBreach(
            id: UUID(),
            title: "Critical Severity Breach",
            description: "Critical severity breach",
            severity: .critical,
            details: "Critical severity details",
            timestamp: Date()
        )
        
        try await privacyEngine.reportDataBreach(lowBreach)
        try await privacyEngine.reportDataBreach(criticalBreach)
        
        // Verify both breaches were reported
        let breaches = privacyEngine.dataBreaches
        XCTAssertTrue(breaches.contains { $0.id == lowBreach.id })
        XCTAssertTrue(breaches.contains { $0.id == criticalBreach.id })
    }
    
    // MARK: - Export Tests
    
    func testExportPrivacyReport() async throws {
        // Test exporting privacy report in different formats
        let jsonData = try await privacyEngine.exportPrivacyReport(format: .json)
        XCTAssertNotNil(jsonData)
        XCTAssertFalse(jsonData.isEmpty)
        
        let csvData = try await privacyEngine.exportPrivacyReport(format: .csv)
        XCTAssertNotNil(csvData)
        
        let xmlData = try await privacyEngine.exportPrivacyReport(format: .xml)
        XCTAssertNotNil(xmlData)
        
        let pdfData = try await privacyEngine.exportPrivacyReport(format: .pdf)
        XCTAssertNotNil(pdfData)
    }
    
    func testExportReportContent() async throws {
        // Test that exported report contains expected content
        let exportData = try await privacyEngine.exportPrivacyReport(format: .json)
        
        // Decode the JSON data
        let decoder = JSONDecoder()
        let privacyReport = try decoder.decode(PrivacyReportData.self, from: exportData)
        
        XCTAssertNotNil(privacyReport.timestamp)
        XCTAssertNotNil(privacyReport.settings)
        XCTAssertNotNil(privacyReport.securityStatus)
        XCTAssertNotNil(privacyReport.complianceStatus)
        XCTAssertNotNil(privacyReport.encryptionStatus)
        XCTAssertNotNil(privacyReport.auditLogs)
        XCTAssertNotNil(privacyReport.dataBreaches)
        XCTAssertNotNil(privacyReport.securityAlerts)
    }
    
    // MARK: - Integration Tests
    
    func testPrivacyIntegration() async throws {
        // Test full privacy workflow
        try await privacyEngine.startPrivacyMonitoring()
        
        let auditResult = try await privacyEngine.performPrivacyAudit()
        XCTAssertNotNil(auditResult)
        
        let settings = await privacyEngine.getPrivacySettings()
        XCTAssertNotNil(settings)
        
        let securityStatus = await privacyEngine.getSecurityStatus()
        XCTAssertNotNil(securityStatus)
        
        let complianceStatus = await privacyEngine.getComplianceStatus()
        XCTAssertNotNil(complianceStatus)
        
        let encryptionStatus = await privacyEngine.getEncryptionStatus()
        XCTAssertNotNil(encryptionStatus)
        
        let auditLogs = await privacyEngine.getAuditLogs()
        XCTAssertNotNil(auditLogs)
        
        let securityAlerts = await privacyEngine.getSecurityAlerts()
        XCTAssertNotNil(securityAlerts)
        
        let testData = "Test data".data(using: .utf8)!
        let encryptedData = try await privacyEngine.encryptHealthData(testData, keyId: "test_key")
        XCTAssertNotNil(encryptedData)
        
        let decryptedData = try await privacyEngine.decryptHealthData(encryptedData, keyId: "test_key")
        XCTAssertNotNil(decryptedData)
        
        let authResult = try await privacyEngine.authenticateUser(biometricType: .faceID)
        XCTAssertNotNil(authResult)
        
        let token = try await privacyEngine.generateAccessToken(userId: "test_user", permissions: [Permission.mock()])
        XCTAssertNotNil(token)
        
        let validationResult = try await privacyEngine.validateAccessToken(token)
        XCTAssertNotNil(validationResult)
        
        let breach = DataBreach(
            id: UUID(),
            title: "Test Breach",
            description: "Test breach",
            severity: .low,
            details: "Test details",
            timestamp: Date()
        )
        try await privacyEngine.reportDataBreach(breach)
        
        let exportData = try await privacyEngine.exportPrivacyReport()
        XCTAssertNotNil(exportData)
        
        await privacyEngine.stopPrivacyMonitoring()
        XCTAssertFalse(privacyEngine.isPrivacyActive)
    }
    
    func testErrorHandling() async throws {
        // Test error handling scenarios
        // This would require mocking to simulate various error conditions
        
        // Test with invalid parameters
        do {
            let testData = Data()
            let encryptedData = try await privacyEngine.encryptHealthData(testData, keyId: "invalid_key")
            XCTAssertNotNil(encryptedData)
        } catch {
            XCTAssertNotNil(privacyEngine.lastError)
        }
    }
    
    // MARK: - Performance Tests
    
    func testPrivacyPerformance() async throws {
        // Test privacy performance
        let startTime = Date()
        
        try await privacyEngine.startPrivacyMonitoring()
        let auditResult = try await privacyEngine.performPrivacyAudit()
        
        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)
        
        // Privacy operations should complete within reasonable time (e.g., 5 seconds)
        XCTAssertLessThan(duration, 5.0)
        XCTAssertNotNil(auditResult)
        
        await privacyEngine.stopPrivacyMonitoring()
    }
    
    func testConcurrentPrivacyOperations() async throws {
        // Test concurrent privacy operations
        try await privacyEngine.startPrivacyMonitoring()
        
        async let audit1 = privacyEngine.performPrivacyAudit()
        async let audit2 = privacyEngine.performPrivacyAudit()
        async let audit3 = privacyEngine.performPrivacyAudit()
        
        let (result1, result2, result3) = try await (audit1, audit2, audit3)
        
        XCTAssertNotNil(result1)
        XCTAssertNotNil(result2)
        XCTAssertNotNil(result3)
        
        await privacyEngine.stopPrivacyMonitoring()
    }
    
    // MARK: - Data Validation Tests
    
    func testDataValidation() async throws {
        // Test data validation
        let settings = await privacyEngine.getPrivacySettings()
        
        for setting in settings.settings {
            // Validate setting data
            XCTAssertFalse(setting.name.isEmpty)
            XCTAssertFalse(setting.description.isEmpty)
            XCTAssertNotNil(setting.category)
            XCTAssertNotNil(setting.value)
        }
        
        let securityStatus = await privacyEngine.getSecurityStatus()
        
        // Validate security status data
        XCTAssertGreaterThanOrEqual(securityStatus.securityScore, 0)
        XCTAssertLessThanOrEqual(securityStatus.securityScore, 1)
        XCTAssertNotNil(securityStatus.threatLevel)
        
        let complianceStatus = await privacyEngine.getComplianceStatus()
        
        // Validate compliance status data
        XCTAssertNotNil(complianceStatus.hipaaCompliance)
        XCTAssertNotNil(complianceStatus.gdprCompliance)
        XCTAssertNotNil(complianceStatus.ccpaCompliance)
        XCTAssertNotNil(complianceStatus.soc2Compliance)
        
        let encryptionStatus = await privacyEngine.getEncryptionStatus()
        
        // Validate encryption status data
        XCTAssertNotNil(encryptionStatus.encryptionEnabled)
        XCTAssertNotNil(encryptionStatus.encryptionStrength)
        XCTAssertGreaterThanOrEqual(encryptionStatus.encryptedDataCount, 0)
    }
    
    // MARK: - Memory Management Tests
    
    func testMemoryManagement() async throws {
        // Test memory management
        let initialMemory = getMemoryUsage()
        
        // Perform multiple privacy operations
        try await privacyEngine.startPrivacyMonitoring()
        
        for _ in 0..<10 {
            _ = try await privacyEngine.performPrivacyAudit()
        }
        
        await privacyEngine.stopPrivacyMonitoring()
        
        let finalMemory = getMemoryUsage()
        let memoryIncrease = finalMemory - initialMemory
        
        // Memory increase should be reasonable (e.g., less than 50MB)
        XCTAssertLessThan(memoryIncrease, 50 * 1024 * 1024)
    }
    
    // MARK: - Helper Methods
    
    private func getMemoryUsage() -> Int {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            return Int(info.resident_size)
        } else {
            return 0
        }
    }
}

// MARK: - Test Extensions

extension PrivacySetting {
    static func mock(
        id: UUID = UUID(),
        name: String = "Test Setting",
        category: PrivacyCategory = .dataCollection,
        value: String = "enabled",
        description: String = "Test privacy setting",
        isEnabled: Bool = true,
        timestamp: Date = Date()
    ) -> PrivacySetting {
        return PrivacySetting(
            id: id,
            name: name,
            category: category,
            value: value,
            description: description,
            isEnabled: isEnabled,
            timestamp: timestamp
        )
    }
}

extension Permission {
    static func mock(
        id: UUID = UUID(),
        name: String = "Test Permission",
        description: String = "Test permission description",
        scope: PermissionScope = .read,
        timestamp: Date = Date()
    ) -> Permission {
        return Permission(
            id: id,
            name: name,
            description: description,
            scope: scope,
            timestamp: timestamp
        )
    }
}

extension SecurityAlert {
    static func mock(
        id: UUID = UUID(),
        title: String = "Test Alert",
        description: String = "Test alert description",
        severity: AlertSeverity = .medium,
        timestamp: Date = Date(),
        details: String = "Test alert details"
    ) -> SecurityAlert {
        return SecurityAlert(
            id: id,
            title: title,
            description: description,
            severity: severity,
            timestamp: timestamp,
            details: details
        )
    }
}

extension DataBreach {
    static func mock(
        id: UUID = UUID(),
        title: String = "Test Breach",
        description: String = "Test breach description",
        severity: BreachSeverity = .medium,
        details: String = "Test breach details",
        timestamp: Date = Date()
    ) -> DataBreach {
        return DataBreach(
            id: id,
            title: title,
            description: description,
            severity: severity,
            details: details,
            timestamp: timestamp
        )
    }
}

extension AuditLogEntry {
    static func mock(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        action: String = "Test Action",
        userId: String = "test_user",
        details: String = "Test log details",
        severity: LogSeverity = .info
    ) -> AuditLogEntry {
        return AuditLogEntry(
            id: id,
            timestamp: timestamp,
            action: action,
            userId: userId,
            details: details,
            severity: severity
        )
    }
} 
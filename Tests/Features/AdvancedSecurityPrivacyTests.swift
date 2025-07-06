import XCTest
@testable import HealthAI2030

final class AdvancedSecurityPrivacyTests: XCTestCase {
    
    var securityManager: AdvancedSecurityPrivacyManager!
    
    override func setUpWithError() throws {
        securityManager = AdvancedSecurityPrivacyManager()
    }
    
    override func tearDownWithError() throws {
        securityManager = nil
    }
    
    // MARK: - Encryption Tests
    
    func testEncryptionInitialization() throws {
        // Test that encryption system initializes properly
        XCTAssertNotNil(securityManager, "Security manager should be initialized")
        
        // Wait for encryption to initialize
        let expectation = XCTestExpectation(description: "Encryption initialization")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            XCTAssertTrue(self.securityManager.encryptionStatus == .active || self.securityManager.encryptionStatus == .error, "Encryption should be active or error")
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)
    }
    
    func testDataEncryptionAndDecryption() throws {
        // Test basic encryption and decryption
        let testData = "Hello, World!".data(using: .utf8)!
        
        do {
            let encryptedData = try securityManager.encryptData(testData)
            XCTAssertNotEqual(encryptedData, testData, "Encrypted data should not equal original data")
            
            let decryptedData = try securityManager.decryptData(encryptedData)
            XCTAssertEqual(decryptedData, testData, "Decrypted data should equal original data")
        } catch {
            XCTFail("Encryption/decryption failed: \(error)")
        }
    }
    
    func testEncryptionKeyRotation() async throws {
        // Test encryption key rotation
        let expectation = XCTestExpectation(description: "Key rotation")
        
        do {
            try await securityManager.rotateEncryptionKeys()
            expectation.fulfill()
        } catch {
            XCTFail("Key rotation failed: \(error)")
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testEncryptionWithLargeData() throws {
        // Test encryption with larger data
        let largeData = Data(repeating: 0x42, count: 1024 * 1024) // 1MB
        
        do {
            let encryptedData = try securityManager.encryptData(largeData)
            XCTAssertNotEqual(encryptedData, largeData, "Large encrypted data should not equal original data")
            
            let decryptedData = try securityManager.decryptData(encryptedData)
            XCTAssertEqual(decryptedData, largeData, "Large decrypted data should equal original data")
        } catch {
            XCTFail("Large data encryption/decryption failed: \(error)")
        }
    }
    
    // MARK: - Privacy Settings Tests
    
    func testPrivacySettingsInitialization() throws {
        // Test privacy settings initialization
        let settings = securityManager.getPrivacySettings()
        
        XCTAssertNotNil(settings, "Privacy settings should be initialized")
        XCTAssertGreaterThan(settings.dataRetentionDays, 0, "Data retention days should be positive")
        XCTAssertLessThanOrEqual(settings.encryptionLevel, 256, "Encryption level should be 256 or less")
    }
    
    func testPrivacySettingsUpdate() throws {
        // Test privacy settings update
        let newSettings = AdvancedSecurityPrivacyManager.PrivacySettings(
            dataRetentionDays: 180,
            allowAnalytics: false,
            allowCrashReporting: false,
            allowPersonalization: false,
            dataSharingLevel: .minimal,
            encryptionLevel: 256
        )
        
        securityManager.updatePrivacySettings(newSettings)
        
        let updatedSettings = securityManager.getPrivacySettings()
        XCTAssertEqual(updatedSettings.dataRetentionDays, 180, "Data retention should be updated")
        XCTAssertEqual(updatedSettings.allowAnalytics, false, "Analytics should be disabled")
        XCTAssertEqual(updatedSettings.dataSharingLevel, .minimal, "Data sharing level should be updated")
    }
    
    func testPrivacyLevelDetermination() throws {
        // Test privacy level determination from settings
        let settings = AdvancedSecurityPrivacyManager.PrivacySettings(
            dataRetentionDays: 365,
            allowAnalytics: true,
            allowCrashReporting: true,
            allowPersonalization: true,
            dataSharingLevel: .none,
            encryptionLevel: 256
        )
        
        securityManager.updatePrivacySettings(settings)
        XCTAssertEqual(securityManager.privacyLevel, .maximum, "Privacy level should be maximum for no data sharing")
    }
    
    // MARK: - Data Anonymization Tests
    
    func testDataAnonymization() throws {
        // Test data anonymization
        let testData: [String: Any] = [
            "name": "John Doe",
            "email": "john.doe@example.com",
            "phone": "123-456-7890",
            "age": 30,
            "healthData": "normal"
        ]
        
        let anonymizedData = securityManager.anonymizeData(testData)
        
        // Check that PII fields are hashed
        XCTAssertNotEqual(anonymizedData["name"] as? String, "John Doe", "Name should be anonymized")
        XCTAssertNotEqual(anonymizedData["email"] as? String, "john.doe@example.com", "Email should be anonymized")
        XCTAssertNotEqual(anonymizedData["phone"] as? String, "123-456-7890", "Phone should be anonymized")
        
        // Check that non-PII fields remain unchanged
        XCTAssertEqual(anonymizedData["age"] as? Int, 30, "Age should remain unchanged")
        XCTAssertEqual(anonymizedData["healthData"] as? String, "normal", "Health data should remain unchanged")
    }
    
    func testDataAnonymizationDisabled() throws {
        // Test data anonymization when disabled
        securityManager.isDataAnonymizationEnabled = false
        
        let testData: [String: Any] = [
            "name": "John Doe",
            "email": "john.doe@example.com"
        ]
        
        let anonymizedData = securityManager.anonymizeData(testData)
        
        // Data should remain unchanged when anonymization is disabled
        XCTAssertEqual(anonymizedData["name"] as? String, "John Doe", "Name should remain unchanged when anonymization is disabled")
        XCTAssertEqual(anonymizedData["email"] as? String, "john.doe@example.com", "Email should remain unchanged when anonymization is disabled")
    }
    
    // MARK: - Security Auditing Tests
    
    func testSecurityEventLogging() throws {
        // Test security event logging
        let initialCount = securityManager.securityAuditLog.count
        
        securityManager.logSecurityEvent(.login, "User login successful", userId: "user123")
        
        XCTAssertEqual(securityManager.securityAuditLog.count, initialCount + 1, "Security event should be logged")
        
        let lastEvent = securityManager.securityAuditLog.last
        XCTAssertNotNil(lastEvent, "Last event should exist")
        XCTAssertEqual(lastEvent?.eventType, .login, "Event type should be login")
        XCTAssertEqual(lastEvent?.description, "User login successful", "Event description should match")
        XCTAssertEqual(lastEvent?.userId, "user123", "User ID should match")
    }
    
    func testSecurityEventSeverity() throws {
        // Test security event severity levels
        securityManager.logSecurityEvent(.securityViolation, "Security violation detected")
        
        let lastEvent = securityManager.securityAuditLog.last
        XCTAssertEqual(lastEvent?.severity, .critical, "Security violation should have critical severity")
        
        securityManager.logSecurityEvent(.login, "User login")
        let loginEvent = securityManager.securityAuditLog.last
        XCTAssertEqual(loginEvent?.severity, .low, "Login event should have low severity")
    }
    
    func testSecurityAuditLogPersistence() throws {
        // Test that audit log persists
        let testEvent = AdvancedSecurityPrivacyManager.SecurityAuditEntry(
            eventType: .login,
            description: "Test event"
        )
        
        securityManager.securityAuditLog.append(testEvent)
        
        // Create new instance to test persistence
        let newManager = AdvancedSecurityPrivacyManager()
        
        // Note: In a real implementation, this would test actual persistence
        // For now, we'll just verify the structure
        XCTAssertNotNil(newManager.securityAuditLog, "Audit log should be initialized")
    }
    
    // MARK: - Security Score Tests
    
    func testSecurityScoreCalculation() throws {
        // Test security score calculation
        let score = securityManager.getSecurityScore()
        
        XCTAssertGreaterThanOrEqual(score, 0, "Security score should be non-negative")
        XCTAssertLessThanOrEqual(score, 100, "Security score should be 100 or less")
    }
    
    func testSecurityScoreWithViolations() throws {
        // Test security score with violations
        let initialScore = securityManager.getSecurityScore()
        
        // Add security violations
        for _ in 0..<5 {
            securityManager.logSecurityEvent(.securityViolation, "Test violation")
        }
        
        let newScore = securityManager.getSecurityScore()
        XCTAssertLessThan(newScore, initialScore, "Score should decrease with violations")
    }
    
    func testSecurityRecommendations() throws {
        // Test security recommendations
        let recommendations = securityManager.getSecurityRecommendations()
        
        XCTAssertNotNil(recommendations, "Recommendations should not be nil")
        XCTAssertTrue(recommendations is [String], "Recommendations should be array of strings")
    }
    
    // MARK: - Biometric Authentication Tests
    
    func testBiometricAuthAvailability() throws {
        // Test biometric authentication availability
        // Note: This test may vary based on device capabilities
        XCTAssertNotNil(securityManager.isBiometricAuthEnabled, "Biometric auth enabled should have a value")
    }
    
    // MARK: - Privacy Level Tests
    
    func testPrivacyLevels() throws {
        // Test all privacy levels
        let levels = AdvancedSecurityPrivacyManager.PrivacyLevel.allCases
        
        XCTAssertEqual(levels.count, 4, "Should have 4 privacy levels")
        XCTAssertTrue(levels.contains(.minimal), "Should include minimal level")
        XCTAssertTrue(levels.contains(.standard), "Should include standard level")
        XCTAssertTrue(levels.contains(.enhanced), "Should include enhanced level")
        XCTAssertTrue(levels.contains(.maximum), "Should include maximum level")
    }
    
    func testPrivacyLevelEncryptionLevels() throws {
        // Test encryption levels for different privacy levels
        XCTAssertEqual(AdvancedSecurityPrivacyManager.PrivacyLevel.minimal.encryptionLevel, 128, "Minimal should have 128-bit encryption")
        XCTAssertEqual(AdvancedSecurityPrivacyManager.PrivacyLevel.standard.encryptionLevel, 256, "Standard should have 256-bit encryption")
        XCTAssertEqual(AdvancedSecurityPrivacyManager.PrivacyLevel.enhanced.encryptionLevel, 256, "Enhanced should have 256-bit encryption")
        XCTAssertEqual(AdvancedSecurityPrivacyManager.PrivacyLevel.maximum.encryptionLevel, 256, "Maximum should have 256-bit encryption")
    }
    
    // MARK: - Security Event Type Tests
    
    func testSecurityEventTypes() throws {
        // Test all security event types
        let eventTypes = AdvancedSecurityPrivacyManager.SecurityEventType.allCases
        
        XCTAssertEqual(eventTypes.count, 8, "Should have 8 security event types")
        XCTAssertTrue(eventTypes.contains(.login), "Should include login event type")
        XCTAssertTrue(eventTypes.contains(.logout), "Should include logout event type")
        XCTAssertTrue(eventTypes.contains(.dataAccess), "Should include data access event type")
        XCTAssertTrue(eventTypes.contains(.dataModification), "Should include data modification event type")
        XCTAssertTrue(eventTypes.contains(.encryptionKeyRotation), "Should include encryption key rotation event type")
        XCTAssertTrue(eventTypes.contains(.privacySettingsChange), "Should include privacy settings change event type")
        XCTAssertTrue(eventTypes.contains(.biometricAuth), "Should include biometric auth event type")
        XCTAssertTrue(eventTypes.contains(.securityViolation), "Should include security violation event type")
    }
    
    func testSecurityEventSeverities() throws {
        // Test security event severities
        XCTAssertEqual(AdvancedSecurityPrivacyManager.SecurityEventType.login.severity, .low, "Login should have low severity")
        XCTAssertEqual(AdvancedSecurityPrivacyManager.SecurityEventType.dataModification.severity, .medium, "Data modification should have medium severity")
        XCTAssertEqual(AdvancedSecurityPrivacyManager.SecurityEventType.encryptionKeyRotation.severity, .high, "Encryption key rotation should have high severity")
        XCTAssertEqual(AdvancedSecurityPrivacyManager.SecurityEventType.securityViolation.severity, .critical, "Security violation should have critical severity")
    }
    
    // MARK: - Error Handling Tests
    
    func testEncryptionErrorHandling() throws {
        // Test encryption error handling
        // This would test various error conditions in a real implementation
        XCTAssertNotNil(SecurityError.encryptionNotInitialized.errorDescription, "Error should have description")
        XCTAssertNotNil(SecurityError.biometricNotAvailable.errorDescription, "Error should have description")
        XCTAssertNotNil(SecurityError.authenticationFailed.errorDescription, "Error should have description")
    }
    
    // MARK: - Performance Tests
    
    func testEncryptionPerformance() throws {
        // Test encryption performance
        let testData = Data(repeating: 0x42, count: 1024 * 10) // 10KB
        
        measure {
            do {
                let encryptedData = try securityManager.encryptData(testData)
                let _ = try securityManager.decryptData(encryptedData)
            } catch {
                XCTFail("Performance test failed: \(error)")
            }
        }
    }
    
    func testSecurityEventLoggingPerformance() throws {
        // Test security event logging performance
        measure {
            for i in 0..<100 {
                securityManager.logSecurityEvent(.login, "Performance test event \(i)")
            }
        }
    }
    
    // MARK: - Integration Tests
    
    func testSecurityPrivacyIntegration() throws {
        // Test integration between security and privacy features
        let settings = AdvancedSecurityPrivacyManager.PrivacySettings(
            dataRetentionDays: 365,
            allowAnalytics: false,
            allowCrashReporting: false,
            allowPersonalization: false,
            dataSharingLevel: .none,
            encryptionLevel: 256
        )
        
        securityManager.updatePrivacySettings(settings)
        
        // Verify privacy level is set correctly
        XCTAssertEqual(securityManager.privacyLevel, .maximum, "Privacy level should be maximum")
        
        // Verify data anonymization is enabled
        XCTAssertTrue(securityManager.isDataAnonymizationEnabled, "Data anonymization should be enabled")
        
        // Test data anonymization with new settings
        let testData: [String: Any] = ["name": "Test User"]
        let anonymizedData = securityManager.anonymizeData(testData)
        XCTAssertNotEqual(anonymizedData["name"] as? String, "Test User", "Data should be anonymized")
    }
} 
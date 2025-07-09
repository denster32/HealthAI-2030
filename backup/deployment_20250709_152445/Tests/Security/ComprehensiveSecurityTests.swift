import XCTest
import Foundation
import CryptoKit
@testable import HealthAI2030

/// Comprehensive Security Test Suite for HealthAI-2030
/// Validates all security implementations and compliance requirements
/// Agent 1 (Security & Dependencies Czar) - July 25, 2025
final class ComprehensiveSecurityTests: XCTestCase {
    
    // MARK: - Test Properties
    
    private var certificatePinningManager: CertificatePinningManager!
    private var rateLimitingManager: RateLimitingManager!
    private var secretsMigrationManager: SecretsMigrationManager!
    private var enhancedOAuthManager: EnhancedOAuthManager!
    private var securityMonitoringManager: SecurityMonitoringManager!
    private var comprehensiveSecurityManager: ComprehensiveSecurityManager!
    
    // MARK: - Setup and Teardown
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        // Initialize security managers
        certificatePinningManager = CertificatePinningManager.shared
        rateLimitingManager = RateLimitingManager.shared
        secretsMigrationManager = SecretsMigrationManager.shared
        enhancedOAuthManager = EnhancedOAuthManager.shared
        securityMonitoringManager = SecurityMonitoringManager.shared
        comprehensiveSecurityManager = ComprehensiveSecurityManager.shared
    }
    
    override func tearDownWithError() throws {
        // Clean up test data
        try super.tearDownWithError()
    }
    
    // MARK: - Certificate Pinning Tests
    
    func testCertificatePinning() throws {
        // Test certificate pinning implementation
        XCTAssertNotNil(certificatePinningManager, "Certificate Pinning Manager should be initialized")
        
        // Test certificate validation
        let testCertificate = "test-certificate-data"
        let isValid = certificatePinningManager.validateCertificate(testCertificate, for: "api.healthai2030.com")
        
        // Certificate should be validated against pinned certificates
        XCTAssertTrue(isValid, "Certificate validation should work correctly")
        
        // Test invalid certificate
        let invalidCertificate = "invalid-certificate-data"
        let isInvalid = certificatePinningManager.validateCertificate(invalidCertificate, for: "api.healthai2030.com")
        
        // Invalid certificate should be rejected
        XCTAssertFalse(isInvalid, "Invalid certificate should be rejected")
    }
    
    func testCertificatePinningConfiguration() throws {
        // Test certificate pinning configuration
        let pinnedCertificates = certificatePinningManager.getPinnedCertificates()
        
        // Should have pinned certificates for critical domains
        XCTAssertTrue(pinnedCertificates.keys.contains("api.healthai2030.com"), "API domain should have pinned certificate")
        XCTAssertTrue(pinnedCertificates.keys.contains("auth.healthai2030.com"), "Auth domain should have pinned certificate")
        
        // Test certificate update mechanism
        let newCertificate = "new-certificate-data"
        certificatePinningManager.updatePinnedCertificate(newCertificate, for: "api.healthai2030.com")
        
        let updatedCertificates = certificatePinningManager.getPinnedCertificates()
        XCTAssertEqual(updatedCertificates["api.healthai2030.com"], newCertificate, "Certificate should be updated")
    }
    
    // MARK: - Rate Limiting Tests
    
    func testRateLimiting() throws {
        // Test rate limiting implementation
        XCTAssertNotNil(rateLimitingManager, "Rate Limiting Manager should be initialized")
        
        // Test rate limit configuration
        let testIdentifier = "test_rate_limit"
        let testIP = "192.168.1.1"
        
        // Add test rate limit
        let rateLimit = RateLimitingManager.RateLimit(
            identifier: testIdentifier,
            maxRequests: 5,
            timeWindow: 60,
            action: .block,
            description: "Test rate limit"
        )
        rateLimitingManager.addRateLimit(rateLimit)
        
        // Test rate limit checking
        for i in 1...5 {
            let result = rateLimitingManager.checkRateLimit(identifier: testIdentifier, ipAddress: testIP)
            XCTAssertTrue(result.allowed, "Request \(i) should be allowed")
        }
        
        // Test rate limit exceeded
        let exceededResult = rateLimitingManager.checkRateLimit(identifier: testIdentifier, ipAddress: testIP)
        XCTAssertFalse(exceededResult.allowed, "Request should be blocked when rate limit exceeded")
        XCTAssertEqual(exceededResult.action, .block, "Action should be block when rate limit exceeded")
    }
    
    func testRateLimitingConfiguration() throws {
        // Test rate limit configuration retrieval
        let authLoginConfig = rateLimitingManager.getRateLimitConfig(identifier: "auth_login")
        XCTAssertNotNil(authLoginConfig, "Auth login rate limit should be configured")
        XCTAssertEqual(authLoginConfig?.maxRequests, 5, "Auth login should allow 5 requests")
        XCTAssertEqual(authLoginConfig?.action, .block, "Auth login should block when exceeded")
        
        let apiGeneralConfig = rateLimitingManager.getRateLimitConfig(identifier: "api_general")
        XCTAssertNotNil(apiGeneralConfig, "API general rate limit should be configured")
        XCTAssertEqual(apiGeneralConfig?.maxRequests, 100, "API general should allow 100 requests")
        XCTAssertEqual(apiGeneralConfig?.action, .delay, "API general should delay when exceeded")
    }
    
    // MARK: - OAuth Flow Tests
    
    func testOAuthFlow() throws {
        // Test OAuth implementation
        XCTAssertNotNil(enhancedOAuthManager, "Enhanced OAuth Manager should be initialized")
        
        // Test OAuth authentication flow
        let expectation = XCTestExpectation(description: "OAuth authentication")
        
        Task {
            do {
                let result = try await enhancedOAuthManager.authenticateUser()
                XCTAssertTrue(result.success, "OAuth authentication should succeed")
                XCTAssertNotNil(result.accessToken, "Access token should be provided")
                XCTAssertNotNil(result.refreshToken, "Refresh token should be provided")
                XCTAssertEqual(result.tokenType, "Bearer", "Token type should be Bearer")
                expectation.fulfill()
            } catch {
                XCTFail("OAuth authentication failed: \(error)")
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 10.0)
    }
    
    func testPKCEImplementation() throws {
        // Test PKCE implementation
        let codeVerifier = enhancedOAuthManager.generateCodeVerifier()
        let codeChallenge = enhancedOAuthManager.generateCodeChallenge(from: codeVerifier)
        
        XCTAssertNotNil(codeVerifier, "Code verifier should be generated")
        XCTAssertNotNil(codeChallenge, "Code challenge should be generated")
        XCTAssertNotEqual(codeVerifier, codeChallenge, "Code verifier and challenge should be different")
        
        // Test PKCE verification
        let verificationResult = enhancedOAuthManager.verifyPKCE(codeVerifier: codeVerifier, codeChallenge: codeChallenge)
        XCTAssertTrue(verificationResult, "PKCE verification should succeed")
    }
    
    // MARK: - Secrets Management Tests
    
    func testSecretsMigration() throws {
        // Test secrets migration implementation
        XCTAssertNotNil(secretsMigrationManager, "Secrets Migration Manager should be initialized")
        
        // Test secrets migration
        let testSecret = "test-secret-value"
        let testKey = "test-secret-key"
        
        let migrationResult = secretsMigrationManager.migrateSecret(testSecret, for: testKey)
        XCTAssertTrue(migrationResult, "Secret migration should succeed")
        
        // Test secrets retrieval
        let retrievedSecret = secretsMigrationManager.getSecret(for: testKey)
        XCTAssertEqual(retrievedSecret, testSecret, "Retrieved secret should match original")
    }
    
    func testAWSSecretsManagerIntegration() throws {
        // Test AWS Secrets Manager integration
        let testSecrets = [
            "database-password": "secure-db-password",
            "jwt-secret": "secure-jwt-secret",
            "oauth-client-secret": "secure-oauth-secret"
        ]
        
        for (key, value) in testSecrets {
            let result = secretsMigrationManager.migrateToAWSSecretsManager(value, for: key)
            XCTAssertTrue(result, "AWS Secrets Manager migration should succeed for \(key)")
        }
        
        // Test secrets retrieval from AWS
        for (key, expectedValue) in testSecrets {
            let retrievedValue = secretsMigrationManager.getSecretFromAWS(for: key)
            XCTAssertEqual(retrievedValue, expectedValue, "AWS secret retrieval should work for \(key)")
        }
    }
    
    // MARK: - Security Monitoring Tests
    
    func testSecurityMonitoring() throws {
        // Test security monitoring implementation
        XCTAssertNotNil(securityMonitoringManager, "Security Monitoring Manager should be initialized")
        
        // Test security event monitoring
        let expectation = XCTestExpectation(description: "Security monitoring")
        
        Task {
            await securityMonitoringManager.monitorSecurityEvents()
            
            // Test threat detection
            let threats = await securityMonitoringManager.threatDetection()
            XCTAssertNotNil(threats, "Threat detection should return results")
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 10.0)
    }
    
    func testThreatDetection() throws {
        // Test threat detection capabilities
        let expectation = XCTestExpectation(description: "Threat detection")
        
        Task {
            let threats = await securityMonitoringManager.threatDetection()
            
            // Verify threat detection structure
            for threat in threats {
                XCTAssertNotNil(threat.id, "Threat should have ID")
                XCTAssertNotNil(threat.type, "Threat should have type")
                XCTAssertNotNil(threat.severity, "Threat should have severity")
                XCTAssertNotNil(threat.timestamp, "Threat should have timestamp")
            }
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 10.0)
    }
    
    // MARK: - Comprehensive Security Tests
    
    func testComprehensiveSecurityManager() throws {
        // Test comprehensive security manager
        XCTAssertNotNil(comprehensiveSecurityManager, "Comprehensive Security Manager should be initialized")
        
        // Test security initialization
        let initResult = comprehensiveSecurityManager.initializeSecurity()
        XCTAssertTrue(initResult, "Security initialization should succeed")
        
        // Test security validation
        let validationResult = comprehensiveSecurityManager.validateSecurityConfiguration()
        XCTAssertTrue(validationResult.isValid, "Security configuration should be valid")
        XCTAssertEqual(validationResult.score, 95, "Security score should be 95/100")
    }
    
    func testSecurityCompliance() throws {
        // Test security compliance
        let complianceResult = comprehensiveSecurityManager.checkCompliance()
        
        // Verify HIPAA compliance
        XCTAssertTrue(complianceResult.hipaaCompliant, "System should be HIPAA compliant")
        
        // Verify GDPR compliance
        XCTAssertTrue(complianceResult.gdprCompliant, "System should be GDPR compliant")
        
        // Verify SOC 2 compliance
        XCTAssertTrue(complianceResult.soc2Compliant, "System should be SOC 2 compliant")
        
        // Verify overall compliance
        XCTAssertTrue(complianceResult.overallCompliant, "System should be overall compliant")
    }
    
    // MARK: - Integration Tests
    
    func testSecurityIntegration() throws {
        // Test integration between security components
        
        // Test certificate pinning with rate limiting
        let testIP = "192.168.1.100"
        let rateLimitResult = rateLimitingManager.checkRateLimit(identifier: "api_sensitive", ipAddress: testIP)
        
        if rateLimitResult.allowed {
            // If rate limit allows, test certificate pinning
            let certResult = certificatePinningManager.validateCertificate("test-cert", for: "api.healthai2030.com")
            XCTAssertTrue(certResult, "Certificate validation should work with rate limiting")
        }
        
        // Test OAuth with security monitoring
        let expectation = XCTestExpectation(description: "OAuth with monitoring")
        
        Task {
            // Start security monitoring
            await securityMonitoringManager.monitorSecurityEvents()
            
            // Perform OAuth authentication
            let oauthResult = try await enhancedOAuthManager.authenticateUser()
            XCTAssertTrue(oauthResult.success, "OAuth should work with security monitoring")
            
            // Check for security events
            let threats = await securityMonitoringManager.threatDetection()
            XCTAssertNotNil(threats, "Security monitoring should detect events during OAuth")
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 15.0)
    }
    
    // MARK: - Performance Tests
    
    func testSecurityPerformance() throws {
        // Test security performance under load
        
        let iterations = 100
        let startTime = Date()
        
        for _ in 0..<iterations {
            let _ = rateLimitingManager.checkRateLimit(identifier: "api_general", ipAddress: "192.168.1.1")
            let _ = certificatePinningManager.validateCertificate("test-cert", for: "api.healthai2030.com")
        }
        
        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)
        
        // Performance should be acceptable (less than 1 second for 100 operations)
        XCTAssertLessThan(duration, 1.0, "Security operations should be performant")
        
        let operationsPerSecond = Double(iterations * 2) / duration
        XCTAssertGreaterThan(operationsPerSecond, 100, "Should handle at least 100 operations per second")
    }
    
    // MARK: - Error Handling Tests
    
    func testSecurityErrorHandling() throws {
        // Test error handling in security components
        
        // Test invalid certificate
        let invalidCertResult = certificatePinningManager.validateCertificate("", for: "invalid.domain")
        XCTAssertFalse(invalidCertResult, "Invalid certificate should be rejected")
        
        // Test invalid rate limit
        let invalidRateResult = rateLimitingManager.checkRateLimit(identifier: "invalid_identifier", ipAddress: "192.168.1.1")
        XCTAssertTrue(invalidRateResult.allowed, "Invalid rate limit should default to allowed")
        
        // Test OAuth error handling
        let expectation = XCTestExpectation(description: "OAuth error handling")
        
        Task {
            do {
                // This should throw an error with invalid configuration
                let _ = try await enhancedOAuthManager.authenticateUser()
                XCTFail("OAuth should fail with invalid configuration")
            } catch {
                XCTAssertNotNil(error, "OAuth should throw error with invalid configuration")
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 10.0)
    }
    
    // MARK: - Compliance Validation Tests
    
    func testHIPAACompliance() throws {
        // Test HIPAA compliance requirements
        
        // Test data encryption
        let testData = "sensitive-health-data"
        let encryptedData = comprehensiveSecurityManager.encryptData(testData)
        XCTAssertNotEqual(encryptedData, testData, "Data should be encrypted")
        
        // Test data decryption
        let decryptedData = comprehensiveSecurityManager.decryptData(encryptedData)
        XCTAssertEqual(decryptedData, testData, "Data should be decrypted correctly")
        
        // Test access controls
        let accessResult = comprehensiveSecurityManager.validateAccessControl(userId: "test-user", resource: "health-data")
        XCTAssertTrue(accessResult, "Access control should be enforced")
    }
    
    func testGDPRCompliance() throws {
        // Test GDPR compliance requirements
        
        // Test data portability
        let exportResult = comprehensiveSecurityManager.exportUserData(userId: "test-user")
        XCTAssertTrue(exportResult.success, "Data export should succeed")
        XCTAssertNotNil(exportResult.data, "Exported data should not be nil")
        
        // Test data deletion
        let deletionResult = comprehensiveSecurityManager.deleteUserData(userId: "test-user")
        XCTAssertTrue(deletionResult, "Data deletion should succeed")
        
        // Test consent management
        let consentResult = comprehensiveSecurityManager.validateUserConsent(userId: "test-user", purpose: "health-tracking")
        XCTAssertTrue(consentResult, "User consent should be validated")
    }
    
    // MARK: - Security Metrics Tests
    
    func testSecurityMetrics() throws {
        // Test security metrics collection
        
        let metrics = comprehensiveSecurityManager.getSecurityMetrics()
        
        // Verify metrics structure
        XCTAssertNotNil(metrics.securityScore, "Security score should be available")
        XCTAssertNotNil(metrics.vulnerabilityCount, "Vulnerability count should be available")
        XCTAssertNotNil(metrics.complianceStatus, "Compliance status should be available")
        XCTAssertNotNil(metrics.lastAuditDate, "Last audit date should be available")
        
        // Verify security score
        XCTAssertGreaterThanOrEqual(metrics.securityScore, 90, "Security score should be at least 90")
        XCTAssertLessThanOrEqual(metrics.securityScore, 100, "Security score should be at most 100")
        
        // Verify vulnerability count
        XCTAssertEqual(metrics.vulnerabilityCount.critical, 0, "Should have 0 critical vulnerabilities")
        XCTAssertEqual(metrics.vulnerabilityCount.high, 0, "Should have 0 high vulnerabilities")
        XCTAssertEqual(metrics.vulnerabilityCount.medium, 0, "Should have 0 medium vulnerabilities")
        XCTAssertEqual(metrics.vulnerabilityCount.low, 0, "Should have 0 low vulnerabilities")
    }
} 
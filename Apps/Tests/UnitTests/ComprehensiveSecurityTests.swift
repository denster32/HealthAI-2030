import XCTest
@testable import HealthAI2030

final class ComprehensiveSecurityTests: XCTestCase {
    var securityManager: ComprehensiveSecurityManager!
    
    override func setUpWithError() throws {
        securityManager = ComprehensiveSecurityManager()
    }
    
    override func tearDownWithError() throws {
        securityManager = nil
    }
    
    // MARK: - Input Validation Tests
    
    func testEmailValidation() {
        let validEmail = "test@example.com"
        let invalidEmail = "invalid-email"
        
        let validResult = securityManager.validateInput(validEmail, type: .email)
        let invalidResult = securityManager.validateInput(invalidEmail, type: .email)
        
        XCTAssertTrue(validResult.isValid)
        XCTAssertEqual(validResult.sanitizedValue, validEmail)
        XCTAssertNil(validResult.error)
        
        XCTAssertFalse(invalidResult.isValid)
        XCTAssertNil(invalidResult.sanitizedValue)
        XCTAssertNotNil(invalidResult.error)
    }
    
    func testPasswordValidation() {
        let validPassword = "SecurePass123!"
        let invalidPassword = "weak"
        
        let validResult = securityManager.validateInput(validPassword, type: .password)
        let invalidResult = securityManager.validateInput(invalidPassword, type: .password)
        
        XCTAssertTrue(validResult.isValid)
        XCTAssertEqual(validResult.sanitizedValue, validPassword)
        XCTAssertNil(validResult.error)
        
        XCTAssertFalse(invalidResult.isValid)
        XCTAssertNil(invalidResult.sanitizedValue)
        XCTAssertNotNil(invalidResult.error)
    }
    
    func testHealthDataValidation() {
        let validHealthData = "{\"heartRate\": 72, \"steps\": 8000}"
        let invalidHealthData = "invalid json data"
        
        let validResult = securityManager.validateInput(validHealthData, type: .healthData)
        let invalidResult = securityManager.validateInput(invalidHealthData, type: .healthData)
        
        XCTAssertTrue(validResult.isValid)
        XCTAssertEqual(validResult.sanitizedValue, validHealthData)
        XCTAssertNil(validResult.error)
        
        XCTAssertFalse(invalidResult.isValid)
        XCTAssertNil(invalidResult.sanitizedValue)
        XCTAssertNotNil(invalidResult.error)
    }
    
    func testUserProfileValidation() {
        let validProfile = "{\"name\": \"John Doe\", \"age\": 30}"
        let invalidProfile = "invalid profile data"
        
        let validResult = securityManager.validateInput(validProfile, type: .userProfile)
        let invalidResult = securityManager.validateInput(invalidProfile, type: .userProfile)
        
        XCTAssertTrue(validResult.isValid)
        XCTAssertEqual(validResult.sanitizedValue, validProfile)
        XCTAssertNil(validResult.error)
        
        XCTAssertFalse(invalidResult.isValid)
        XCTAssertNil(invalidResult.sanitizedValue)
        XCTAssertNotNil(invalidResult.error)
    }
    
    func testAPIRequestValidation() {
        let validRequest = "{\"action\": \"getData\", \"params\": {}}"
        let invalidRequest = "invalid request"
        
        let validResult = securityManager.validateInput(validRequest, type: .apiRequest)
        let invalidResult = securityManager.validateInput(invalidRequest, type: .apiRequest)
        
        XCTAssertTrue(validResult.isValid)
        XCTAssertEqual(validResult.sanitizedValue, validRequest)
        XCTAssertNil(validResult.error)
        
        XCTAssertFalse(invalidResult.isValid)
        XCTAssertNil(invalidResult.sanitizedValue)
        XCTAssertNotNil(invalidResult.error)
    }
    
    // MARK: - Authentication Tests
    
    func testSuccessfulAuthentication() async {
        let username = "test@example.com"
        let password = "SecurePass123!"
        
        let result = await securityManager.authenticateUser(username: username, password: password)
        
        XCTAssertTrue(result.success)
        XCTAssertNotNil(result.token)
        XCTAssertNil(result.error)
    }
    
    func testFailedAuthenticationWithInvalidEmail() async {
        let username = "invalid-email"
        let password = "SecurePass123!"
        
        let result = await securityManager.authenticateUser(username: username, password: password)
        
        XCTAssertFalse(result.success)
        XCTAssertNil(result.token)
        XCTAssertNotNil(result.error)
    }
    
    func testFailedAuthenticationWithWeakPassword() async {
        let username = "test@example.com"
        let password = "weak"
        
        let result = await securityManager.authenticateUser(username: username, password: password)
        
        XCTAssertFalse(result.success)
        XCTAssertNil(result.token)
        XCTAssertNotNil(result.error)
    }
    
    // MARK: - Access Control Tests
    
    func testAccessGranted() {
        let userId = "user123"
        let resource = "health_data"
        let action = "read"
        
        let result = securityManager.checkAccess(userId: userId, resource: resource, action: action)
        
        XCTAssertTrue(result.granted)
        XCTAssertEqual(result.reason, "Permission granted")
    }
    
    func testAccessDenied() {
        let userId = "user123"
        let resource = "admin_panel"
        let action = "delete"
        
        let result = securityManager.checkAccess(userId: userId, resource: resource, action: action)
        
        XCTAssertFalse(result.granted)
        XCTAssertEqual(result.reason, "Insufficient permissions")
    }
    
    // MARK: - Data Encryption Tests
    
    func testDataEncryptionAndDecryption() throws {
        let originalData = "Sensitive health data".data(using: .utf8)!
        
        let encryptedData = try securityManager.encryptData(originalData)
        let decryptedData = try securityManager.decryptData(encryptedData)
        
        XCTAssertEqual(originalData, decryptedData)
        XCTAssertNotEqual(originalData, encryptedData.data)
    }
    
    func testSecureTransmission() async throws {
        let data = "Health data to transmit".data(using: .utf8)!
        let endpoint = "https://api.healthai.com/data"
        
        let result = try await securityManager.secureTransmission(data, to: endpoint)
        
        XCTAssertTrue(result.success)
        XCTAssertNotNil(result.transmissionId)
    }
    
    // MARK: - Error Handling Tests
    
    func testSecureErrorHandling() {
        let testError = NSError(domain: "TestDomain", code: 100, userInfo: [
            NSLocalizedDescriptionKey: "Test error with password: secret123"
        ])
        
        securityManager.handleError(testError, context: "TestContext")
        
        // Verify that error was logged but sensitive information was sanitized
        let securityEvents = securityManager.securityEvents
        XCTAssertFalse(securityEvents.isEmpty)
        
        let errorEvent = securityEvents.first { $0.type == .errorHandling }
        XCTAssertNotNil(errorEvent)
        XCTAssertFalse(errorEvent?.message.contains("secret123") ?? false)
    }
    
    // MARK: - Security Event Logging Tests
    
    func testSecurityEventLogging() {
        let initialEventCount = securityManager.securityEvents.count
        
        securityManager.logSecurityEvent(.authentication, "Test authentication event", .info)
        
        XCTAssertEqual(securityManager.securityEvents.count, initialEventCount + 1)
        
        let event = securityManager.securityEvents.last
        XCTAssertEqual(event?.type, .authentication)
        XCTAssertEqual(event?.message, "Test authentication event")
        XCTAssertEqual(event?.level, .info)
    }
    
    func testSecurityThreatDetection() {
        // Log multiple critical events to trigger threat detection
        for i in 0..<6 {
            securityManager.logSecurityEvent(.authentication, "Critical event \(i)", .critical)
        }
        
        XCTAssertEqual(securityManager.securityStatus, .compromised)
    }
    
    // MARK: - Vulnerability Scanning Tests
    
    func testDependencyVulnerabilityScan() async {
        let scanResult = await securityManager.scanDependencies()
        
        XCTAssertNotNil(scanResult)
        XCTAssertNotNil(scanResult.vulnerabilities)
        
        // Check if vulnerabilities were found and alerts were created
        if !scanResult.vulnerabilities.isEmpty {
            XCTAssertFalse(securityManager.vulnerabilityAlerts.isEmpty)
        }
    }
    
    // MARK: - Security Status Tests
    
    func testInitialSecurityStatus() {
        XCTAssertEqual(securityManager.securityStatus, .secure)
    }
    
    func testSecurityStatusChange() {
        XCTAssertEqual(securityManager.securityStatus, .secure)
        
        // Trigger security threat
        for i in 0..<6 {
            securityManager.logSecurityEvent(.authentication, "Critical event \(i)", .critical)
        }
        
        XCTAssertEqual(securityManager.securityStatus, .compromised)
    }
    
    // MARK: - Input Sanitization Tests
    
    func testInputSanitization() {
        let maliciousInput = "<script>alert('xss')</script>javascript:alert('xss')"
        let sanitizedResult = securityManager.validateInput(maliciousInput, type: .email)
        
        // Should be invalid due to malicious content
        XCTAssertFalse(sanitizedResult.isValid)
    }
    
    // MARK: - Performance Tests
    
    func testAuthenticationPerformance() async {
        let username = "test@example.com"
        let password = "SecurePass123!"
        
        let startTime = Date()
        
        for _ in 0..<10 {
            _ = await securityManager.authenticateUser(username: username, password: password)
        }
        
        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)
        
        // Authentication should complete within reasonable time
        XCTAssertLessThan(duration, 5.0) // 5 seconds for 10 authentications
    }
    
    func testEncryptionPerformance() throws {
        let data = "Test data for encryption performance".data(using: .utf8)!
        
        let startTime = Date()
        
        for _ in 0..<100 {
            let encrypted = try securityManager.encryptData(data)
            _ = try securityManager.decryptData(encrypted)
        }
        
        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)
        
        // Encryption/decryption should be fast
        XCTAssertLessThan(duration, 1.0) // 1 second for 100 operations
    }
} 
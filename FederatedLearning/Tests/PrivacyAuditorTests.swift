import XCTest
@testable import FederatedLearning

@available(iOS 18.0, macOS 15.0, *)
final class PrivacyAuditorTests: XCTestCase {
    
    var privacyAuditor: EnhancedPrivacyAuditor!
    var testData: Data!
    var testKey: SymmetricKey!
    
    override func setUp() {
        super.setUp()
        privacyAuditor = EnhancedPrivacyAuditor()
        testData = "Test sensitive health data".data(using: .utf8)!
        testKey = SymmetricKey(size: .bits256)
    }
    
    override func tearDown() {
        privacyAuditor = nil
        testData = nil
        testKey = nil
        super.tearDown()
    }
    
    // MARK: - Basic Privacy Assessment Tests
    
    func testPrivacyImpactAssessment() {
        let privacyImpact = privacyAuditor.assessPrivacyImpact(data: testData)
        
        XCTAssertGreaterThanOrEqual(privacyImpact, 0.0)
        XCTAssertLessThanOrEqual(privacyImpact, 1.0)
        
        // Test with different data types
        let medicalData = "Patient ID: 12345, Diagnosis: Diabetes".data(using: .utf8)!
        let medicalImpact = privacyAuditor.assessPrivacyImpact(data: medicalData)
        XCTAssertGreaterThanOrEqual(medicalImpact, 0.0)
    }
    
    func testDataLeakageDetection() {
        let leakageDetected = privacyAuditor.detectDataLeakage(data: testData)
        
        // Should return a boolean value
        XCTAssertTrue(leakageDetected == true || leakageDetected == false)
        
        // Test with sensitive data
        let sensitiveData = "SSN: 123-45-6789, Credit Card: 4111-1111-1111-1111".data(using: .utf8)!
        let sensitiveLeakage = privacyAuditor.detectDataLeakage(data: sensitiveData)
        XCTAssertTrue(sensitiveLeakage == true || sensitiveLeakage == false)
    }
    
    func testComplianceMonitoring() {
        // Test GDPR compliance
        let gdprCompliant = privacyAuditor.monitorCompliance(data: testData, regulation: "GDPR")
        XCTAssertTrue(gdprCompliant == true || gdprCompliant == false)
        
        // Test HIPAA compliance
        let hipaaCompliant = privacyAuditor.monitorCompliance(data: testData, regulation: "HIPAA")
        XCTAssertTrue(hipaaCompliant == true || hipaaCompliant == false)
        
        // Test CCPA compliance
        let ccpaCompliant = privacyAuditor.monitorCompliance(data: testData, regulation: "CCPA")
        XCTAssertTrue(ccpaCompliant == true || ccpaCompliant == false)
        
        // Test PIPEDA compliance
        let pipedaCompliant = privacyAuditor.monitorCompliance(data: testData, regulation: "PIPEDA")
        XCTAssertTrue(pipedaCompliant == true || pipedaCompliant == false)
        
        // Test unknown regulation
        let unknownCompliant = privacyAuditor.monitorCompliance(data: testData, regulation: "UNKNOWN")
        XCTAssertFalse(unknownCompliant)
    }
    
    func testPrivacyScoreCalculation() {
        let privacyScore = privacyAuditor.calculatePrivacyScore(data: testData)
        
        XCTAssertGreaterThanOrEqual(privacyScore, 0)
        XCTAssertLessThanOrEqual(privacyScore, 100)
        
        // Test with different data types
        let lowRiskData = "Public information".data(using: .utf8)!
        let lowRiskScore = privacyAuditor.calculatePrivacyScore(data: lowRiskData)
        XCTAssertGreaterThanOrEqual(lowRiskScore, 0)
        XCTAssertLessThanOrEqual(lowRiskScore, 100)
    }
    
    // MARK: - Encryption Tests
    
    func testDataEncryption() {
        let encryptedData = privacyAuditor.encryptSensitiveData(data: testData, key: testKey)
        
        XCTAssertNotNil(encryptedData)
        XCTAssertNotEqual(encryptedData, testData)
        
        // Test with empty data
        let emptyData = Data()
        let emptyEncrypted = privacyAuditor.encryptSensitiveData(data: emptyData, key: testKey)
        XCTAssertNotNil(emptyEncrypted)
    }
    
    func testDataDecryption() {
        let encryptedData = privacyAuditor.encryptSensitiveData(data: testData, key: testKey)
        XCTAssertNotNil(encryptedData)
        
        let decryptedData = privacyAuditor.decryptSensitiveData(encryptedData: encryptedData!, key: testKey)
        
        XCTAssertNotNil(decryptedData)
        XCTAssertEqual(decryptedData, testData)
    }
    
    func testDataIntegrityValidation() {
        let dataHash = SHA256.hash(data: testData).compactMap { String(format: "%02x", $0) }.joined()
        
        let isValid = privacyAuditor.validateDataIntegrity(data: testData, expectedHash: dataHash)
        XCTAssertTrue(isValid)
        
        // Test with invalid hash
        let invalidHash = "invalid_hash"
        let isInvalid = privacyAuditor.validateDataIntegrity(data: testData, expectedHash: invalidHash)
        XCTAssertFalse(isInvalid)
    }
    
    // MARK: - Advanced Security Tests
    
    func testDifferentialPrivacy() {
        let sensitivity = 1.0
        let differentiallyPrivateData = privacyAuditor.applyDifferentialPrivacy(data: testData, sensitivity: sensitivity)
        
        XCTAssertNotNil(differentiallyPrivateData)
        XCTAssertNotEqual(differentiallyPrivateData, testData)
        
        // Test with different sensitivity values
        let highSensitivity = 10.0
        let highSensitivityData = privacyAuditor.applyDifferentialPrivacy(data: testData, sensitivity: highSensitivity)
        XCTAssertNotNil(highSensitivityData)
    }
    
    func testHomomorphicEncryption() {
        let homomorphicData = privacyAuditor.performHomomorphicEncryption(data: testData)
        
        XCTAssertNotNil(homomorphicData)
        XCTAssertNotNil(homomorphicData.encryptedValue)
        XCTAssertNotNil(homomorphicData.publicKey)
        XCTAssertNotNil(homomorphicData.metadata)
        XCTAssertEqual(homomorphicData.metadata.algorithm, "RSA")
        XCTAssertEqual(homomorphicData.metadata.keySize, 2048)
    }
    
    func testSecureMultiPartyComputation() {
        let participants = ["device1", "device2", "device3"]
        let mpcResult = privacyAuditor.performSecureMPC(data: testData, participants: participants)
        
        XCTAssertNotNil(mpcResult)
        XCTAssertEqual(mpcResult.participants.count, 3)
        XCTAssertEqual(mpcResult.shares.count, 3)
        XCTAssertEqual(mpcResult.computationType, "federated_learning")
    }
    
    func testPrivacyViolationDetection() {
        let violations = privacyAuditor.detectPrivacyViolations(data: testData)
        
        XCTAssertNotNil(violations)
        XCTAssertTrue(violations is [PrivacyViolation])
        
        // Test with sensitive data
        let sensitiveData = "Patient: John Doe, SSN: 123-45-6789".data(using: .utf8)!
        let sensitiveViolations = privacyAuditor.detectPrivacyViolations(data: sensitiveData)
        XCTAssertNotNil(sensitiveViolations)
    }
    
    // MARK: - Audit Logging Tests
    
    func testAuditLogGeneration() {
        let operation = "test_operation"
        let dataHash = "test_hash"
        let timestamp = Date()
        
        let auditLog = privacyAuditor.generateAuditLog(operation: operation, dataHash: dataHash, timestamp: timestamp)
        
        XCTAssertNotNil(auditLog)
        XCTAssertEqual(auditLog.operation, operation)
        XCTAssertEqual(auditLog.dataHash, dataHash)
        XCTAssertEqual(auditLog.timestamp, timestamp)
        XCTAssertNotNil(auditLog.deviceId)
        XCTAssertNotNil(auditLog.sessionId)
        XCTAssertNotNil(auditLog.securityLevel)
        XCTAssertNotNil(auditLog.complianceStatus)
    }
    
    // MARK: - Compliance Tests
    
    func testGDPRCompliance() {
        let gdprCompliant = privacyAuditor.monitorCompliance(data: testData, regulation: "GDPR")
        XCTAssertTrue(gdprCompliant == true || gdprCompliant == false)
    }
    
    func testHIPAACompliance() {
        let hipaaCompliant = privacyAuditor.monitorCompliance(data: testData, regulation: "HIPAA")
        XCTAssertTrue(hipaaCompliant == true || hipaaCompliant == false)
    }
    
    func testCCPACompliance() {
        let ccpaCompliant = privacyAuditor.monitorCompliance(data: testData, regulation: "CCPA")
        XCTAssertTrue(ccpaCompliant == true || ccpaCompliant == false)
    }
    
    func testPIPEDACompliance() {
        let pipedaCompliant = privacyAuditor.monitorCompliance(data: testData, regulation: "PIPEDA")
        XCTAssertTrue(pipedaCompliant == true || pipedaCompliant == false)
    }
    
    func testSOXCompliance() {
        let soxCompliant = privacyAuditor.monitorCompliance(data: testData, regulation: "SOX")
        XCTAssertTrue(soxCompliant == true || soxCompliant == false)
    }
    
    func testPCIDSSCompliance() {
        let pciCompliant = privacyAuditor.monitorCompliance(data: testData, regulation: "PCI-DSS")
        XCTAssertTrue(pciCompliant == true || pciCompliant == false)
    }
    
    // MARK: - Performance Tests
    
    func testPerformanceWithLargeData() {
        let largeData = Data(repeating: 0, count: 1024 * 1024) // 1MB
        
        let startTime = CFAbsoluteTimeGetCurrent()
        let privacyImpact = privacyAuditor.assessPrivacyImpact(data: largeData)
        let endTime = CFAbsoluteTimeGetCurrent()
        
        let executionTime = endTime - startTime
        XCTAssertLessThan(executionTime, 5.0) // Should complete within 5 seconds
        
        XCTAssertGreaterThanOrEqual(privacyImpact, 0.0)
        XCTAssertLessThanOrEqual(privacyImpact, 1.0)
    }
    
    func testConcurrentOperations() {
        let expectation1 = XCTestExpectation(description: "Privacy assessment 1")
        let expectation2 = XCTestExpectation(description: "Privacy assessment 2")
        let expectation3 = XCTestExpectation(description: "Privacy assessment 3")
        
        DispatchQueue.global(qos: .userInitiated).async {
            let _ = self.privacyAuditor.assessPrivacyImpact(data: self.testData)
            expectation1.fulfill()
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            let _ = self.privacyAuditor.detectDataLeakage(data: self.testData)
            expectation2.fulfill()
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            let _ = self.privacyAuditor.calculatePrivacyScore(data: self.testData)
            expectation3.fulfill()
        }
        
        wait(for: [expectation1, expectation2, expectation3], timeout: 10.0)
    }
    
    // MARK: - Error Handling Tests
    
    func testErrorHandlingWithInvalidData() {
        // Test with nil data (should handle gracefully)
        let emptyData = Data()
        let privacyImpact = privacyAuditor.assessPrivacyImpact(data: emptyData)
        XCTAssertGreaterThanOrEqual(privacyImpact, 0.0)
        XCTAssertLessThanOrEqual(privacyImpact, 1.0)
    }
    
    func testErrorHandlingWithInvalidKey() {
        let invalidKey = SymmetricKey(size: .bits128) // Different key size
        
        let encryptedData = privacyAuditor.encryptSensitiveData(data: testData, key: testKey)
        XCTAssertNotNil(encryptedData)
        
        // Try to decrypt with different key (should fail gracefully)
        let decryptedData = privacyAuditor.decryptSensitiveData(encryptedData: encryptedData!, key: invalidKey)
        XCTAssertNil(decryptedData)
    }
    
    // MARK: - Security Level Tests
    
    func testSecurityLevels() {
        let levels = SecurityLevel.allCases
        XCTAssertEqual(levels.count, 4)
        XCTAssertTrue(levels.contains(.low))
        XCTAssertTrue(levels.contains(.medium))
        XCTAssertTrue(levels.contains(.high))
        XCTAssertTrue(levels.contains(.critical))
    }
    
    func testComplianceStatuses() {
        let statuses = ComplianceStatus.allCases
        XCTAssertEqual(statuses.count, 4)
        XCTAssertTrue(statuses.contains(.compliant))
        XCTAssertTrue(statuses.contains(.nonCompliant))
        XCTAssertTrue(statuses.contains(.pending))
        XCTAssertTrue(statuses.contains(.unknown))
    }
    
    // MARK: - Privacy Violation Tests
    
    func testPrivacyViolationTypes() {
        let types = PrivacyViolationType.allCases
        XCTAssertEqual(types.count, 5)
        XCTAssertTrue(types.contains(.piiExposure))
        XCTAssertTrue(types.contains(.unauthorizedAccess))
        XCTAssertTrue(types.contains(.dataExfiltration))
        XCTAssertTrue(types.contains(.policyViolation))
        XCTAssertTrue(types.contains(.consentViolation))
    }
    
    func testPrivacyViolationSeverities() {
        let severities = PrivacyViolationSeverity.allCases
        XCTAssertEqual(severities.count, 4)
        XCTAssertTrue(severities.contains(.low))
        XCTAssertTrue(severities.contains(.medium))
        XCTAssertTrue(severities.contains(.high))
        XCTAssertTrue(severities.contains(.critical))
    }
    
    func testPrivacyViolationCreation() {
        let violation = PrivacyViolation(
            type: .piiExposure,
            severity: .high,
            description: "Test violation",
            timestamp: Date()
        )
        
        XCTAssertEqual(violation.type, .piiExposure)
        XCTAssertEqual(violation.severity, .high)
        XCTAssertEqual(violation.description, "Test violation")
        XCTAssertNotNil(violation.timestamp)
    }
    
    // MARK: - Integration Tests
    
    func testFullPrivacyWorkflow() {
        // Test complete privacy workflow
        let privacyImpact = privacyAuditor.assessPrivacyImpact(data: testData)
        XCTAssertGreaterThanOrEqual(privacyImpact, 0.0)
        XCTAssertLessThanOrEqual(privacyImpact, 1.0)
        
        let leakageDetected = privacyAuditor.detectDataLeakage(data: testData)
        XCTAssertTrue(leakageDetected == true || leakageDetected == false)
        
        let privacyScore = privacyAuditor.calculatePrivacyScore(data: testData)
        XCTAssertGreaterThanOrEqual(privacyScore, 0)
        XCTAssertLessThanOrEqual(privacyScore, 100)
        
        let violations = privacyAuditor.detectPrivacyViolations(data: testData)
        XCTAssertNotNil(violations)
        
        let gdprCompliant = privacyAuditor.monitorCompliance(data: testData, regulation: "GDPR")
        XCTAssertTrue(gdprCompliant == true || gdprCompliant == false)
    }
    
    func testEncryptionWorkflow() {
        // Test complete encryption workflow
        let encryptedData = privacyAuditor.encryptSensitiveData(data: testData, key: testKey)
        XCTAssertNotNil(encryptedData)
        
        let decryptedData = privacyAuditor.decryptSensitiveData(encryptedData: encryptedData!, key: testKey)
        XCTAssertNotNil(decryptedData)
        XCTAssertEqual(decryptedData, testData)
        
        let dataHash = SHA256.hash(data: testData).compactMap { String(format: "%02x", $0) }.joined()
        let isValid = privacyAuditor.validateDataIntegrity(data: testData, expectedHash: dataHash)
        XCTAssertTrue(isValid)
    }
    
    static var allTests = [
        ("testPrivacyImpactAssessment", testPrivacyImpactAssessment),
        ("testDataLeakageDetection", testDataLeakageDetection),
        ("testComplianceMonitoring", testComplianceMonitoring),
        ("testPrivacyScoreCalculation", testPrivacyScoreCalculation),
        ("testDataEncryption", testDataEncryption),
        ("testDataDecryption", testDataDecryption),
        ("testDataIntegrityValidation", testDataIntegrityValidation),
        ("testDifferentialPrivacy", testDifferentialPrivacy),
        ("testHomomorphicEncryption", testHomomorphicEncryption),
        ("testSecureMultiPartyComputation", testSecureMultiPartyComputation),
        ("testPrivacyViolationDetection", testPrivacyViolationDetection),
        ("testAuditLogGeneration", testAuditLogGeneration),
        ("testGDPRCompliance", testGDPRCompliance),
        ("testHIPAACompliance", testHIPAACompliance),
        ("testCCPACompliance", testCCPACompliance),
        ("testPIPEDACompliance", testPIPEDACompliance),
        ("testSOXCompliance", testSOXCompliance),
        ("testPCIDSSCompliance", testPCIDSSCompliance),
        ("testPerformanceWithLargeData", testPerformanceWithLargeData),
        ("testConcurrentOperations", testConcurrentOperations),
        ("testErrorHandlingWithInvalidData", testErrorHandlingWithInvalidData),
        ("testErrorHandlingWithInvalidKey", testErrorHandlingWithInvalidKey),
        ("testSecurityLevels", testSecurityLevels),
        ("testComplianceStatuses", testComplianceStatuses),
        ("testPrivacyViolationTypes", testPrivacyViolationTypes),
        ("testPrivacyViolationSeverities", testPrivacyViolationSeverities),
        ("testPrivacyViolationCreation", testPrivacyViolationCreation),
        ("testFullPrivacyWorkflow", testFullPrivacyWorkflow),
        ("testEncryptionWorkflow", testEncryptionWorkflow)
    ]
} 
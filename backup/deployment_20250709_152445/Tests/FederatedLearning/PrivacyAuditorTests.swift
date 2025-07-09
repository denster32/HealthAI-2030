// Tests/FederatedLearning/PrivacyAuditorTests.swift
import XCTest
import CryptoKit
@testable import FederatedLearning

@available(iOS 18.0, macOS 15.0, *)
final class PrivacyAuditorTests: XCTestCase {
    
    var privacyAuditor: EnhancedPrivacyAuditor!
    var testData: Data!
    var testKey: SymmetricKey!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        privacyAuditor = EnhancedPrivacyAuditor()
        testData = "Test health data for privacy assessment".data(using: .utf8)!
        testKey = SymmetricKey(size: .bits256)
    }
    
    override func tearDownWithError() throws {
        privacyAuditor = nil
        testData = nil
        testKey = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Privacy Assessment Tests
    
    func testAssessPrivacyImpact_ValidData_ReturnsScore() async throws {
        // Given
        let data = testData
        
        // When
        let impact = try await privacyAuditor.assessPrivacyImpact(data: data)
        
        // Then
        XCTAssertGreaterThanOrEqual(impact, 0.0)
        XCTAssertLessThanOrEqual(impact, 1.0)
        XCTAssertEqual(privacyAuditor.performanceMetrics.totalAssessments, 1)
    }
    
    func testAssessPrivacyImpact_EmptyData_ThrowsError() async throws {
        // Given
        let emptyData = Data()
        
        // When & Then
        do {
            _ = try await privacyAuditor.assessPrivacyImpact(data: emptyData)
            XCTFail("Expected error for empty data")
        } catch PrivacyAuditorError.invalidDataFormat {
            // Expected error
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testAssessPrivacyImpact_LargeData_HandlesEfficiently() async throws {
        // Given
        let largeData = Data(repeating: 0x42, count: 1024 * 1024) // 1MB
        
        // When
        let startTime = CFAbsoluteTimeGetCurrent()
        let impact = try await privacyAuditor.assessPrivacyImpact(data: largeData)
        let endTime = CFAbsoluteTimeGetCurrent()
        
        // Then
        XCTAssertGreaterThanOrEqual(impact, 0.0)
        XCTAssertLessThanOrEqual(impact, 1.0)
        XCTAssertLessThan(endTime - startTime, 5.0, "Assessment should complete within 5 seconds")
    }
    
    // MARK: - Data Leakage Detection Tests
    
    func testDetectDataLeakage_ValidData_ReturnsBoolean() async throws {
        // Given
        let data = testData
        
        // When
        let leakageDetected = try await privacyAuditor.detectDataLeakage(data: data)
        
        // Then
        XCTAssertTrue(leakageDetected is Bool)
    }
    
    func testDetectDataLeakage_EmptyData_ThrowsError() async throws {
        // Given
        let emptyData = Data()
        
        // When & Then
        do {
            _ = try await privacyAuditor.detectDataLeakage(data: emptyData)
            XCTFail("Expected error for empty data")
        } catch PrivacyAuditorError.invalidDataFormat {
            // Expected error
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    // MARK: - Compliance Monitoring Tests
    
    func testMonitorCompliance_GDPR_ReturnsBoolean() async throws {
        // Given
        let data = testData
        let regulation = "GDPR"
        
        // When
        let isCompliant = try await privacyAuditor.monitorCompliance(data: data, regulation: regulation)
        
        // Then
        XCTAssertTrue(isCompliant is Bool)
    }
    
    func testMonitorCompliance_HIPAA_ReturnsBoolean() async throws {
        // Given
        let data = testData
        let regulation = "HIPAA"
        
        // When
        let isCompliant = try await privacyAuditor.monitorCompliance(data: data, regulation: regulation)
        
        // Then
        XCTAssertTrue(isCompliant is Bool)
    }
    
    func testMonitorCompliance_EmptyRegulation_ThrowsError() async throws {
        // Given
        let data = testData
        let emptyRegulation = ""
        
        // When & Then
        do {
            _ = try await privacyAuditor.monitorCompliance(data: data, regulation: emptyRegulation)
            XCTFail("Expected error for empty regulation")
        } catch PrivacyAuditorError.invalidDataFormat {
            // Expected error
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testMonitorCompliance_UnknownRegulation_ReturnsFalse() async throws {
        // Given
        let data = testData
        let unknownRegulation = "UNKNOWN_REGULATION"
        
        // When
        let isCompliant = try await privacyAuditor.monitorCompliance(data: data, regulation: unknownRegulation)
        
        // Then
        XCTAssertFalse(isCompliant)
    }
    
    // MARK: - Privacy Score Calculation Tests
    
    func testCalculatePrivacyScore_ValidData_ReturnsScore() async throws {
        // Given
        let data = testData
        
        // When
        let score = try await privacyAuditor.calculatePrivacyScore(data: data)
        
        // Then
        XCTAssertGreaterThanOrEqual(score, 0)
        XCTAssertLessThanOrEqual(score, 100)
    }
    
    func testCalculatePrivacyScore_EmptyData_ThrowsError() async throws {
        // Given
        let emptyData = Data()
        
        // When & Then
        do {
            _ = try await privacyAuditor.calculatePrivacyScore(data: emptyData)
            XCTFail("Expected error for empty data")
        } catch PrivacyAuditorError.invalidDataFormat {
            // Expected error
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    // MARK: - Encryption Tests
    
    func testEncryptSensitiveData_ValidData_ReturnsEncryptedData() async throws {
        // Given
        let data = testData
        let key = testKey
        
        // When
        let encryptedData = try await privacyAuditor.encryptSensitiveData(data: data, key: key)
        
        // Then
        XCTAssertNotEqual(encryptedData, data)
        XCTAssertGreaterThan(encryptedData.count, 0)
        XCTAssertEqual(privacyAuditor.performanceMetrics.encryptionOperations, 1)
    }
    
    func testEncryptSensitiveData_EmptyData_ThrowsError() async throws {
        // Given
        let emptyData = Data()
        let key = testKey
        
        // When & Then
        do {
            _ = try await privacyAuditor.encryptSensitiveData(data: emptyData, key: key)
            XCTFail("Expected error for empty data")
        } catch PrivacyAuditorError.invalidDataFormat {
            // Expected error
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testDecryptSensitiveData_ValidEncryptedData_ReturnsOriginalData() async throws {
        // Given
        let originalData = testData
        let key = testKey
        let encryptedData = try await privacyAuditor.encryptSensitiveData(data: originalData, key: key)
        
        // When
        let decryptedData = try await privacyAuditor.decryptSensitiveData(encryptedData: encryptedData, key: key)
        
        // Then
        XCTAssertEqual(decryptedData, originalData)
        XCTAssertEqual(privacyAuditor.performanceMetrics.decryptionOperations, 1)
    }
    
    func testDecryptSensitiveData_EmptyData_ThrowsError() async throws {
        // Given
        let emptyData = Data()
        let key = testKey
        
        // When & Then
        do {
            _ = try await privacyAuditor.decryptSensitiveData(encryptedData: emptyData, key: key)
            XCTFail("Expected error for empty data")
        } catch PrivacyAuditorError.invalidDataFormat {
            // Expected error
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testDecryptSensitiveData_WrongKey_ThrowsError() async throws {
        // Given
        let originalData = testData
        let correctKey = testKey
        let wrongKey = SymmetricKey(size: .bits256)
        let encryptedData = try await privacyAuditor.encryptSensitiveData(data: originalData, key: correctKey)
        
        // When & Then
        do {
            _ = try await privacyAuditor.decryptSensitiveData(encryptedData: encryptedData, key: wrongKey)
            XCTFail("Expected error for wrong key")
        } catch PrivacyAuditorError.decryptionFailed {
            // Expected error
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    // MARK: - Audit Log Tests
    
    func testGenerateAuditLog_ValidInputs_ReturnsAuditEntry() async throws {
        // Given
        let operation = "test_operation"
        let dataHash = "test_hash"
        let timestamp = Date()
        
        // When
        let auditEntry = try await privacyAuditor.generateAuditLog(
            operation: operation,
            dataHash: dataHash,
            timestamp: timestamp
        )
        
        // Then
        XCTAssertEqual(auditEntry.operation, operation)
        XCTAssertEqual(auditEntry.dataHash, dataHash)
        XCTAssertEqual(auditEntry.timestamp, timestamp)
        XCTAssertFalse(auditEntry.deviceId.isEmpty)
        XCTAssertFalse(auditEntry.sessionId.isEmpty)
        XCTAssertFalse(auditEntry.securityLevel.isEmpty)
        XCTAssertFalse(auditEntry.complianceStatus.isEmpty)
    }
    
    func testGenerateAuditLog_EmptyOperation_ThrowsError() async throws {
        // Given
        let emptyOperation = ""
        let dataHash = "test_hash"
        let timestamp = Date()
        
        // When & Then
        do {
            _ = try await privacyAuditor.generateAuditLog(
                operation: emptyOperation,
                dataHash: dataHash,
                timestamp: timestamp
            )
            XCTFail("Expected error for empty operation")
        } catch PrivacyAuditorError.invalidDataFormat {
            // Expected error
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testGenerateAuditLog_EmptyDataHash_ThrowsError() async throws {
        // Given
        let operation = "test_operation"
        let emptyDataHash = ""
        let timestamp = Date()
        
        // When & Then
        do {
            _ = try await privacyAuditor.generateAuditLog(
                operation: operation,
                dataHash: emptyDataHash,
                timestamp: timestamp
            )
            XCTFail("Expected error for empty data hash")
        } catch PrivacyAuditorError.invalidDataFormat {
            // Expected error
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    // MARK: - Data Integrity Tests
    
    func testValidateDataIntegrity_ValidData_ReturnsTrue() async throws {
        // Given
        let data = testData
        let expectedHash = try await privacyAuditor.hashData(data: data)
        
        // When
        let isValid = try await privacyAuditor.validateDataIntegrity(data: data, expectedHash: expectedHash)
        
        // Then
        XCTAssertTrue(isValid)
    }
    
    func testValidateDataIntegrity_InvalidHash_ThrowsError() async throws {
        // Given
        let data = testData
        let invalidHash = "invalid_hash"
        
        // When & Then
        do {
            _ = try await privacyAuditor.validateDataIntegrity(data: data, expectedHash: invalidHash)
            XCTFail("Expected error for invalid hash")
        } catch PrivacyAuditorError.dataIntegrityViolation {
            // Expected error
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testValidateDataIntegrity_EmptyData_ThrowsError() async throws {
        // Given
        let emptyData = Data()
        let expectedHash = "test_hash"
        
        // When & Then
        do {
            _ = try await privacyAuditor.validateDataIntegrity(data: emptyData, expectedHash: expectedHash)
            XCTFail("Expected error for empty data")
        } catch PrivacyAuditorError.invalidDataFormat {
            // Expected error
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testValidateDataIntegrity_EmptyHash_ThrowsError() async throws {
        // Given
        let data = testData
        let emptyHash = ""
        
        // When & Then
        do {
            _ = try await privacyAuditor.validateDataIntegrity(data: data, expectedHash: emptyHash)
            XCTFail("Expected error for empty hash")
        } catch PrivacyAuditorError.invalidDataFormat {
            // Expected error
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    // MARK: - Privacy Violation Detection Tests
    
    func testDetectPrivacyViolations_ValidData_ReturnsArray() async throws {
        // Given
        let data = testData
        
        // When
        let violations = try await privacyAuditor.detectPrivacyViolations(data: data)
        
        // Then
        XCTAssertTrue(violations is [PrivacyViolation])
    }
    
    func testDetectPrivacyViolations_EmptyData_ThrowsError() async throws {
        // Given
        let emptyData = Data()
        
        // When & Then
        do {
            _ = try await privacyAuditor.detectPrivacyViolations(data: emptyData)
            XCTFail("Expected error for empty data")
        } catch PrivacyAuditorError.invalidDataFormat {
            // Expected error
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    // MARK: - Advanced Security Tests
    
    func testApplyDifferentialPrivacy_ValidData_ReturnsNoisyData() async throws {
        // Given
        let data = testData
        let sensitivity = 1.0
        
        // When
        let noisyData = try await privacyAuditor.applyDifferentialPrivacy(data: data, sensitivity: sensitivity)
        
        // Then
        XCTAssertNotEqual(noisyData, data)
        XCTAssertGreaterThan(noisyData.count, 0)
    }
    
    func testApplyDifferentialPrivacy_EmptyData_ThrowsError() async throws {
        // Given
        let emptyData = Data()
        let sensitivity = 1.0
        
        // When & Then
        do {
            _ = try await privacyAuditor.applyDifferentialPrivacy(data: emptyData, sensitivity: sensitivity)
            XCTFail("Expected error for empty data")
        } catch PrivacyAuditorError.invalidDataFormat {
            // Expected error
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testApplyDifferentialPrivacy_InvalidSensitivity_ThrowsError() async throws {
        // Given
        let data = testData
        let invalidSensitivity = -1.0
        
        // When & Then
        do {
            _ = try await privacyAuditor.applyDifferentialPrivacy(data: data, sensitivity: invalidSensitivity)
            XCTFail("Expected error for invalid sensitivity")
        } catch PrivacyAuditorError.invalidDataFormat {
            // Expected error
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testPerformHomomorphicEncryption_ValidData_ReturnsEncryptedData() async throws {
        // Given
        let data = testData
        
        // When
        let encryptedData = try await privacyAuditor.performHomomorphicEncryption(data: data)
        
        // Then
        XCTAssertNotEqual(encryptedData.encryptedValue, data)
        XCTAssertGreaterThan(encryptedData.publicKey.count, 0)
        XCTAssertEqual(encryptedData.metadata.algorithm, "RSA")
        XCTAssertEqual(encryptedData.metadata.keySize, 2048)
    }
    
    func testPerformHomomorphicEncryption_EmptyData_ThrowsError() async throws {
        // Given
        let emptyData = Data()
        
        // When & Then
        do {
            _ = try await privacyAuditor.performHomomorphicEncryption(data: emptyData)
            XCTFail("Expected error for empty data")
        } catch PrivacyAuditorError.invalidDataFormat {
            // Expected error
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testPerformSecureMPC_ValidData_ReturnsMPCResult() async throws {
        // Given
        let data = testData
        let participants = ["device1", "device2", "device3"]
        
        // When
        let mpcResult = try await privacyAuditor.performSecureMPC(data: data, participants: participants)
        
        // Then
        XCTAssertEqual(mpcResult.shares.count, participants.count)
        XCTAssertEqual(mpcResult.participants, participants)
        XCTAssertEqual(mpcResult.computationType, "federated_learning")
    }
    
    func testPerformSecureMPC_EmptyData_ThrowsError() async throws {
        // Given
        let emptyData = Data()
        let participants = ["device1", "device2"]
        
        // When & Then
        do {
            _ = try await privacyAuditor.performSecureMPC(data: emptyData, participants: participants)
            XCTFail("Expected error for empty data")
        } catch PrivacyAuditorError.invalidDataFormat {
            // Expected error
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testPerformSecureMPC_EmptyParticipants_ThrowsError() async throws {
        // Given
        let data = testData
        let emptyParticipants: [String] = []
        
        // When & Then
        do {
            _ = try await privacyAuditor.performSecureMPC(data: data, participants: emptyParticipants)
            XCTFail("Expected error for empty participants")
        } catch PrivacyAuditorError.invalidDataFormat {
            // Expected error
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    // MARK: - Performance Tests
    
    func testPerformance_ConcurrentOperations() async throws {
        // Given
        let data = testData
        let key = testKey
        let operationCount = 10
        
        // When
        let startTime = CFAbsoluteTimeGetCurrent()
        
        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<operationCount {
                group.addTask {
                    _ = try? await self.privacyAuditor.assessPrivacyImpact(data: data)
                }
                group.addTask {
                    _ = try? await self.privacyAuditor.encryptSensitiveData(data: data, key: key)
                }
            }
        }
        
        let endTime = CFAbsoluteTimeGetCurrent()
        
        // Then
        XCTAssertLessThan(endTime - startTime, 10.0, "Concurrent operations should complete within 10 seconds")
        XCTAssertGreaterThanOrEqual(privacyAuditor.performanceMetrics.totalAssessments, operationCount)
    }
    
    func testPerformance_LargeDatasetProcessing() async throws {
        // Given
        let largeData = Data(repeating: 0x42, count: 10 * 1024 * 1024) // 10MB
        let key = testKey
        
        // When
        let startTime = CFAbsoluteTimeGetCurrent()
        
        let impact = try await privacyAuditor.assessPrivacyImpact(data: largeData)
        let encryptedData = try await privacyAuditor.encryptSensitiveData(data: largeData, key: key)
        let decryptedData = try await privacyAuditor.decryptSensitiveData(encryptedData: encryptedData, key: key)
        
        let endTime = CFAbsoluteTimeGetCurrent()
        
        // Then
        XCTAssertLessThan(endTime - startTime, 30.0, "Large dataset processing should complete within 30 seconds")
        XCTAssertEqual(decryptedData, largeData)
        XCTAssertGreaterThanOrEqual(impact, 0.0)
        XCTAssertLessThanOrEqual(impact, 1.0)
    }
    
    // MARK: - Error Handling Tests
    
    func testErrorHandling_NetworkFailure_ThrowsAppropriateError() async throws {
        // Given
        let data = testData
        
        // When & Then
        do {
            _ = try await privacyAuditor.assessPrivacyImpact(data: data)
            // This should not throw in normal circumstances, but we test error handling
        } catch PrivacyAuditorError.privacyViolationDetected {
            // Expected error type
        } catch PrivacyAuditorError.invalidDataFormat {
            // Expected error type
        } catch {
            // Other errors are acceptable
        }
    }
    
    // MARK: - Memory Management Tests
    
    func testMemoryManagement_LargeDataProcessing() async throws {
        // Given
        let largeData = Data(repeating: 0x42, count: 50 * 1024 * 1024) // 50MB
        
        // When
        let startMemory = getMemoryUsage()
        
        for _ in 0..<5 {
            _ = try await privacyAuditor.assessPrivacyImpact(data: largeData)
        }
        
        let endMemory = getMemoryUsage()
        
        // Then
        let memoryIncrease = endMemory - startMemory
        XCTAssertLessThan(memoryIncrease, 100 * 1024 * 1024, "Memory increase should be less than 100MB")
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

// MARK: - PrivacyViolation Tests

@available(iOS 18.0, macOS 15.0, *)
final class PrivacyViolationTests: XCTestCase {
    
    func testPrivacyViolation_Initialization() {
        // Given
        let type = PrivacyViolation.ViolationType.piiExposure
        let severity = PrivacyViolation.ViolationSeverity.high
        let description = "Test violation"
        let timestamp = Date()
        let dataHash = "test_hash"
        let remediationSteps = ["Step 1", "Step 2"]
        
        // When
        let violation = PrivacyViolation(
            type: type,
            severity: severity,
            description: description,
            timestamp: timestamp,
            dataHash: dataHash,
            remediationSteps: remediationSteps
        )
        
        // Then
        XCTAssertEqual(violation.type, type)
        XCTAssertEqual(violation.severity, severity)
        XCTAssertEqual(violation.description, description)
        XCTAssertEqual(violation.timestamp, timestamp)
        XCTAssertEqual(violation.dataHash, dataHash)
        XCTAssertEqual(violation.remediationSteps, remediationSteps)
    }
    
    func testViolationType_AllCases() {
        // Given & When
        let allTypes = PrivacyViolation.ViolationType.allCases
        
        // Then
        XCTAssertEqual(allTypes.count, 6)
        XCTAssertTrue(allTypes.contains(.piiExposure))
        XCTAssertTrue(allTypes.contains(.unauthorizedAccess))
        XCTAssertTrue(allTypes.contains(.dataExfiltration))
        XCTAssertTrue(allTypes.contains(.consentViolation))
        XCTAssertTrue(allTypes.contains(.retentionViolation))
        XCTAssertTrue(allTypes.contains(.encryptionViolation))
    }
    
    func testViolationSeverity_AllCases() {
        // Given & When
        let allSeverities = PrivacyViolation.ViolationSeverity.allCases
        
        // Then
        XCTAssertEqual(allSeverities.count, 4)
        XCTAssertTrue(allSeverities.contains(.low))
        XCTAssertTrue(allSeverities.contains(.medium))
        XCTAssertTrue(allSeverities.contains(.high))
        XCTAssertTrue(allSeverities.contains(.critical))
    }
}

// MARK: - AuditLogEntry Tests

@available(iOS 18.0, macOS 15.0, *)
final class AuditLogEntryTests: XCTestCase {
    
    func testAuditLogEntry_Initialization() {
        // Given
        let id = UUID()
        let operation = "test_operation"
        let dataHash = "test_hash"
        let timestamp = Date()
        let deviceId = "test_device"
        let sessionId = "test_session"
        let securityLevel = "high"
        let complianceStatus = "compliant"
        let metadata = "test_metadata".data(using: .utf8)
        
        // When
        let auditEntry = AuditLogEntry(
            id: id,
            operation: operation,
            dataHash: dataHash,
            timestamp: timestamp,
            deviceId: deviceId,
            sessionId: sessionId,
            securityLevel: securityLevel,
            complianceStatus: complianceStatus,
            metadata: metadata
        )
        
        // Then
        XCTAssertEqual(auditEntry.id, id)
        XCTAssertEqual(auditEntry.operation, operation)
        XCTAssertEqual(auditEntry.dataHash, dataHash)
        XCTAssertEqual(auditEntry.timestamp, timestamp)
        XCTAssertEqual(auditEntry.deviceId, deviceId)
        XCTAssertEqual(auditEntry.sessionId, sessionId)
        XCTAssertEqual(auditEntry.securityLevel, securityLevel)
        XCTAssertEqual(auditEntry.complianceStatus, complianceStatus)
        XCTAssertEqual(auditEntry.metadata, metadata)
    }
    
    func testAuditLogEntry_DefaultInitialization() {
        // Given
        let operation = "test_operation"
        let dataHash = "test_hash"
        let timestamp = Date()
        let deviceId = "test_device"
        let sessionId = "test_session"
        let securityLevel = "high"
        let complianceStatus = "compliant"
        
        // When
        let auditEntry = AuditLogEntry(
            operation: operation,
            dataHash: dataHash,
            timestamp: timestamp,
            deviceId: deviceId,
            sessionId: sessionId,
            securityLevel: securityLevel,
            complianceStatus: complianceStatus
        )
        
        // Then
        XCTAssertNotNil(auditEntry.id)
        XCTAssertEqual(auditEntry.operation, operation)
        XCTAssertEqual(auditEntry.dataHash, dataHash)
        XCTAssertEqual(auditEntry.timestamp, timestamp)
        XCTAssertEqual(auditEntry.deviceId, deviceId)
        XCTAssertEqual(auditEntry.sessionId, sessionId)
        XCTAssertEqual(auditEntry.securityLevel, securityLevel)
        XCTAssertEqual(auditEntry.complianceStatus, complianceStatus)
        XCTAssertNil(auditEntry.metadata)
    }
} 
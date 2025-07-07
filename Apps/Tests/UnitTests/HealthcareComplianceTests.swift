import XCTest
@testable import HealthAI2030

final class HealthcareComplianceTests: XCTestCase {
    var complianceManager: HealthcareComplianceManager!
    
    override func setUpWithError() throws {
        complianceManager = HealthcareComplianceManager()
    }
    
    override func tearDownWithError() throws {
        complianceManager = nil
    }
    
    // MARK: - HIPAA Compliance Tests
    
    func testHIPAAComplianceCheck() {
        let report = complianceManager.performHIPAAComplianceCheck()
        
        XCTAssertNotNil(report)
        XCTAssertTrue(report.isCompliant)
        XCTAssertTrue(report.privacyRuleCompliant)
        XCTAssertTrue(report.securityRuleCompliant)
        XCTAssertTrue(report.breachNotificationCompliant)
        XCTAssertNotNil(report.recommendations)
    }
    
    func testHIPAAComplianceReportStructure() {
        let report = complianceManager.performHIPAAComplianceCheck()
        
        XCTAssertNotNil(report.timestamp)
        XCTAssertNotNil(report.recommendations)
        XCTAssertTrue(report.recommendations is [String])
    }
    
    // MARK: - GDPR Compliance Tests
    
    func testGDPRComplianceCheck() {
        let report = complianceManager.performGDPRComplianceCheck()
        
        XCTAssertNotNil(report)
        XCTAssertTrue(report.isCompliant)
        XCTAssertTrue(report.dataProcessingCompliant)
        XCTAssertTrue(report.userRightsCompliant)
        XCTAssertTrue(report.dataProtectionCompliant)
        XCTAssertTrue(report.breachNotificationCompliant)
        XCTAssertNotNil(report.recommendations)
    }
    
    func testGDPRComplianceReportStructure() {
        let report = complianceManager.performGDPRComplianceCheck()
        
        XCTAssertNotNil(report.timestamp)
        XCTAssertNotNil(report.recommendations)
        XCTAssertTrue(report.recommendations is [String])
    }
    
    // MARK: - Audit Trail Tests
    
    func testAuditEventLogging() {
        let initialEventCount = complianceManager.auditTrail.count
        
        complianceManager.logAuditEvent(.hipaaCompliance, "Test HIPAA audit event", .info)
        
        XCTAssertEqual(complianceManager.auditTrail.count, initialEventCount + 1)
        
        let event = complianceManager.auditTrail.last
        XCTAssertEqual(event?.type, .hipaaCompliance)
        XCTAssertEqual(event?.message, "Test HIPAA audit event")
        XCTAssertEqual(event?.level, .info)
        XCTAssertNotNil(event?.timestamp)
    }
    
    func testComplianceViolationDetection() {
        // Log multiple critical events to trigger violation detection
        for i in 0..<4 {
            complianceManager.logAuditEvent(.dataBreach, "Critical event \(i)", .critical)
        }
        
        XCTAssertEqual(complianceManager.complianceStatus, .nonCompliant)
    }
    
    func testAuditEventMetadata() {
        complianceManager.logAuditEvent(.userRights, "Test event with metadata", .warning)
        
        let event = complianceManager.auditTrail.last
        XCTAssertNotNil(event?.userId)
        XCTAssertNotNil(event?.sessionId)
        XCTAssertNotNil(event?.ipAddress)
        XCTAssertNotNil(event?.userAgent)
    }
    
    // MARK: - Data Retention Tests
    
    func testDataRetentionPolicyCreation() {
        let initialPolicyCount = complianceManager.dataRetentionPolicies.count
        
        let policy = DataRetentionPolicy(
            name: "Test Policy",
            dataType: "test_data",
            retentionPeriod: 365 * 24 * 3600, // 1 year
            deletionMethod: .secure
        )
        
        complianceManager.createDataRetentionPolicy(policy)
        
        XCTAssertEqual(complianceManager.dataRetentionPolicies.count, initialPolicyCount + 1)
        XCTAssertEqual(complianceManager.dataRetentionPolicies.last?.name, "Test Policy")
    }
    
    func testDataRetentionPolicyApplication() {
        let policy = DataRetentionPolicy(
            name: "Test Policy",
            dataType: "test_data",
            retentionPeriod: 365 * 24 * 3600,
            deletionMethod: .secure
        )
        
        complianceManager.createDataRetentionPolicy(policy)
        
        let result = complianceManager.applyDataRetentionPolicy(policy.id.uuidString)
        
        XCTAssertTrue(result.success)
        XCTAssertNotNil(result.message)
    }
    
    func testDataDeletion() {
        let userId = "test_user_123"
        let reason = DeletionReason.userRequest
        
        let result = complianceManager.deleteUserData(userId: userId, reason: reason)
        
        XCTAssertTrue(result.success)
        XCTAssertNotNil(result.message)
        XCTAssertNotNil(result.deletionRecord)
        XCTAssertEqual(result.deletionRecord?.userId, userId)
        XCTAssertEqual(result.deletionRecord?.reason, reason)
        XCTAssertNotNil(result.deletionRecord?.confirmationCode)
    }
    
    // MARK: - User Rights Tests
    
    func testUserRightsAccessRequest() {
        let request = UserRightsRequest(
            userId: "test_user",
            type: .access,
            description: "Request for data access",
            requestDate: Date(),
            status: .pending
        )
        
        let result = complianceManager.processUserRightsRequest(request)
        
        XCTAssertTrue(result.success)
        XCTAssertEqual(result.message, "Access request processed successfully")
        XCTAssertNotNil(result.data)
        XCTAssertNotNil(result.processingTime)
    }
    
    func testUserRightsRectificationRequest() {
        let request = UserRightsRequest(
            userId: "test_user",
            type: .rectification,
            description: "Request for data correction",
            requestDate: Date(),
            status: .pending
        )
        
        let result = complianceManager.processUserRightsRequest(request)
        
        XCTAssertTrue(result.success)
        XCTAssertEqual(result.message, "Data rectification completed")
        XCTAssertNil(result.data)
    }
    
    func testUserRightsErasureRequest() {
        let request = UserRightsRequest(
            userId: "test_user",
            type: .erasure,
            description: "Request for data deletion",
            requestDate: Date(),
            status: .pending
        )
        
        let result = complianceManager.processUserRightsRequest(request)
        
        XCTAssertTrue(result.success)
        XCTAssertEqual(result.message, "Data deletion completed")
        XCTAssertNil(result.data)
    }
    
    func testUserRightsPortabilityRequest() {
        let request = UserRightsRequest(
            userId: "test_user",
            type: .portability,
            description: "Request for data portability",
            requestDate: Date(),
            status: .pending
        )
        
        let result = complianceManager.processUserRightsRequest(request)
        
        XCTAssertTrue(result.success)
        XCTAssertEqual(result.message, "Data portability request processed successfully")
        XCTAssertNotNil(result.data)
    }
    
    func testUserRightsRestrictionRequest() {
        let request = UserRightsRequest(
            userId: "test_user",
            type: .restriction,
            description: "Request for processing restriction",
            requestDate: Date(),
            status: .pending
        )
        
        let result = complianceManager.processUserRightsRequest(request)
        
        XCTAssertTrue(result.success)
        XCTAssertEqual(result.message, "Data processing restriction applied")
        XCTAssertNil(result.data)
    }
    
    func testUserRightsObjectionRequest() {
        let request = UserRightsRequest(
            userId: "test_user",
            type: .objection,
            description: "Request to object to processing",
            requestDate: Date(),
            status: .pending
        )
        
        let result = complianceManager.processUserRightsRequest(request)
        
        XCTAssertTrue(result.success)
        XCTAssertEqual(result.message, "Data processing objection recorded")
        XCTAssertNil(result.data)
    }
    
    // MARK: - Breach Notification Tests
    
    func testDataBreachReporting() {
        let breach = DataBreach(
            description: "Test data breach",
            severity: .medium,
            affectedRecords: 100,
            dataTypes: ["personal_info", "health_data"],
            discoveryDate: Date(),
            reportDate: Date(),
            status: .reported
        )
        
        let result = complianceManager.reportDataBreach(breach)
        
        XCTAssertTrue(result.success)
        XCTAssertNotNil(result.notificationsSent)
        XCTAssertNotNil(result.nextSteps)
        XCTAssertNotNil(result.timestamp)
        
        // Check that breach was added to the list
        XCTAssertEqual(complianceManager.dataBreaches.count, 1)
        XCTAssertEqual(complianceManager.dataBreaches.first?.description, "Test data breach")
    }
    
    func testCriticalBreachNotification() {
        let breach = DataBreach(
            description: "Critical data breach",
            severity: .critical,
            affectedRecords: 1000,
            dataTypes: ["personal_info", "health_data", "financial_data"],
            discoveryDate: Date(),
            reportDate: Date(),
            status: .reported
        )
        
        let result = complianceManager.reportDataBreach(breach)
        
        XCTAssertTrue(result.success)
        XCTAssertFalse(result.notificationsSent.isEmpty)
        XCTAssertFalse(result.nextSteps.isEmpty)
        
        // Critical breach should change compliance status
        XCTAssertEqual(complianceManager.complianceStatus, .nonCompliant)
    }
    
    func testLargeBreachNotification() {
        let breach = DataBreach(
            description: "Large scale breach",
            severity: .high,
            affectedRecords: 600,
            dataTypes: ["personal_info"],
            discoveryDate: Date(),
            reportDate: Date(),
            status: .reported
        )
        
        let result = complianceManager.reportDataBreach(breach)
        
        XCTAssertTrue(result.success)
        
        // Should include HIPAA Secretary notification for >500 records
        let hasSecretaryNotification = result.notificationsSent.contains { $0.contains("Secretary") }
        XCTAssertTrue(hasSecretaryNotification)
    }
    
    // MARK: - Compliance Status Tests
    
    func testInitialComplianceStatus() {
        XCTAssertEqual(complianceManager.complianceStatus, .compliant)
    }
    
    func testComplianceStatusChange() {
        XCTAssertEqual(complianceManager.complianceStatus, .compliant)
        
        // Trigger compliance violation
        for i in 0..<4 {
            complianceManager.logAuditEvent(.dataBreach, "Critical event \(i)", .critical)
        }
        
        XCTAssertEqual(complianceManager.complianceStatus, .nonCompliant)
    }
    
    // MARK: - Data Export Tests
    
    func testUserDataExport() {
        let request = UserRightsRequest(
            userId: "test_user",
            type: .access,
            description: "Data access request",
            requestDate: Date(),
            status: .pending
        )
        
        let result = complianceManager.processUserRightsRequest(request)
        
        XCTAssertTrue(result.success)
        XCTAssertNotNil(result.data)
        
        // Verify export data structure
        if let exportData = result.data,
           let json = try? JSONSerialization.jsonObject(with: exportData) as? [String: Any] {
            XCTAssertEqual(json["userId"] as? String, "test_user")
            XCTAssertNotNil(json["exportDate"])
            XCTAssertNotNil(json["dataTypes"])
        }
    }
    
    func testPortableDataExport() {
        let request = UserRightsRequest(
            userId: "test_user",
            type: .portability,
            description: "Data portability request",
            requestDate: Date(),
            status: .pending
        )
        
        let result = complianceManager.processUserRightsRequest(request)
        
        XCTAssertTrue(result.success)
        XCTAssertNotNil(result.data)
        
        // Verify portable data structure
        if let portableData = result.data,
           let json = try? JSONSerialization.jsonObject(with: portableData) as? [String: Any] {
            XCTAssertEqual(json["userId"] as? String, "test_user")
            XCTAssertEqual(json["format"] as? String, "JSON")
            XCTAssertNotNil(json["exportDate"])
        }
    }
    
    // MARK: - Performance Tests
    
    func testComplianceCheckPerformance() {
        let startTime = Date()
        
        for _ in 0..<10 {
            _ = complianceManager.performHIPAAComplianceCheck()
            _ = complianceManager.performGDPRComplianceCheck()
        }
        
        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)
        
        // Compliance checks should be fast
        XCTAssertLessThan(duration, 1.0) // 1 second for 20 compliance checks
    }
    
    func testAuditLoggingPerformance() {
        let startTime = Date()
        
        for i in 0..<100 {
            complianceManager.logAuditEvent(.userRights, "Performance test event \(i)", .info)
        }
        
        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)
        
        // Audit logging should be very fast
        XCTAssertLessThan(duration, 0.5) // 0.5 seconds for 100 events
    }
} 
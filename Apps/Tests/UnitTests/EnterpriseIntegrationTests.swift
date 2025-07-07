import XCTest
@testable import HealthAI2030Core

final class EnterpriseIntegrationTests: XCTestCase {
    let enterprise = EnterpriseIntegrationManager.shared
    
    func testAuthenticateUser() {
        let success = enterprise.authenticateUser(username: "user1", method: .saml)
        XCTAssertTrue(success)
    }
    
    func testAllAuthenticationMethods() {
        let methods: [EnterpriseIntegrationManager.AuthenticationMethod] = [
            .saml,
            .oauth2,
            .ldap,
            .activeDirectory,
            .custom
        ]
        
        for method in methods {
            let success = enterprise.authenticateUser(username: "test_user", method: method)
            XCTAssertTrue(success)
        }
    }
    
    func testSetupSSO() {
        let config = ["provider": "okta", "endpoint": "https://okta.com"]
        let success = enterprise.setupSSO(provider: "okta", configuration: config)
        XCTAssertTrue(success)
    }
    
    func testValidateSSO() {
        XCTAssertTrue(enterprise.validateSSO(token: "valid_token"))
        XCTAssertFalse(enterprise.validateSSO(token: ""))
    }
    
    func testSyncWithEnterpriseSystem() {
        let success = enterprise.syncWithEnterpriseSystem(system: "epic", data: Data([1,2,3]))
        XCTAssertTrue(success)
    }
    
    func testReceiveEnterpriseData() {
        let data = enterprise.receiveEnterpriseData(system: "epic")
        XCTAssertNotNil(data)
    }
    
    func testValidateDataSync() {
        let validation = enterprise.validateDataSync(system: "epic")
        XCTAssertEqual(validation["status"] as? String, "synced")
        XCTAssertEqual(validation["lastSync"] as? String, "2024-01-15T10:30:00Z")
        XCTAssertEqual(validation["recordsProcessed"] as? Int, 1000)
        XCTAssertEqual(validation["errors"] as? Int, 0)
    }
    
    func testCreateAndExecuteWorkflow() {
        let steps = ["step1", "step2", "step3"]
        enterprise.createWorkflow(id: "workflow1", name: "Test Workflow", steps: steps)
        
        let workflows = enterprise.getWorkflows()
        XCTAssertGreaterThan(workflows.count, 0)
        let workflow = workflows.first { $0.id == "workflow1" }
        XCTAssertNotNil(workflow)
        XCTAssertEqual(workflow?.name, "Test Workflow")
        XCTAssertEqual(workflow?.steps.count, 3)
        XCTAssertTrue(workflow?.enabled ?? false)
        
        let success = enterprise.executeWorkflow(id: "workflow1")
        XCTAssertTrue(success)
    }
    
    func testGenerateEnterpriseReport() {
        let report = enterprise.generateEnterpriseReport(reportType: "compliance")
        XCTAssertNotNil(report)
    }
    
    func testGetEnterpriseAnalytics() {
        let analytics = enterprise.getEnterpriseAnalytics()
        XCTAssertEqual(analytics["activeUsers"] as? Int, 5000)
        XCTAssertEqual(analytics["dataVolume"] as? String, "10TB")
        XCTAssertEqual(analytics["complianceScore"] as? Double, 0.98)
        XCTAssertEqual(analytics["uptime"] as? Double, 99.9)
    }
    
    func testExportEnterpriseData() {
        let exported = enterprise.exportEnterpriseData(format: "CSV")
        XCTAssertNotNil(exported)
    }
    
    func testValidateEnterpriseSecurity() {
        let secure = enterprise.validateEnterpriseSecurity()
        XCTAssertTrue(secure)
    }
    
    func testCheckCompliance() {
        let compliant = enterprise.checkCompliance(standard: "HIPAA")
        XCTAssertTrue(compliant)
    }
    
    func testGenerateSecurityReport() {
        let report = enterprise.generateSecurityReport()
        XCTAssertEqual(report["securityScore"] as? Int, 95)
        XCTAssertEqual(report["vulnerabilities"] as? Int, 0)
        XCTAssertEqual(report["lastAudit"] as? String, "2024-01-10")
        XCTAssertEqual(report["complianceStatus"] as? String, "compliant")
    }
    
    func testCreateSupportTicket() {
        let ticketId = enterprise.createSupportTicket(issue: "Integration issue", priority: "high")
        XCTAssertEqual(ticketId, "TICKET-12345")
    }
    
    func testGetSupportDocumentation() {
        let documentation = enterprise.getSupportDocumentation()
        XCTAssertNotNil(documentation)
    }
    
    func testValidateEnterpriseIntegration() {
        let validation = enterprise.validateEnterpriseIntegration()
        XCTAssertEqual(validation["status"] as? String, "integrated")
        XCTAssertEqual(validation["systemsConnected"] as? Int, 5)
        XCTAssertEqual(validation["dataFlows"] as? Int, 10)
        XCTAssertEqual(validation["lastValidated"] as? String, "2024-01-15")
    }
} 
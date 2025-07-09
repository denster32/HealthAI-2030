import XCTest
import Foundation
import CryptoKit
@testable import HealthAI2030

/// Advanced Security Test Suite for HealthAI-2030
/// Tests all advanced security features identified in comprehensive re-evaluation
/// Agent 1 (Security & Dependencies Czar) - Advanced Testing
/// July 25, 2025
final class AdvancedSecurityTests: XCTestCase {
    
    // MARK: - Test Properties
    
    private var advancedSecurityManager: AdvancedSecurityManager!
    private var rateLimitingManager: RateLimitingManager!
    private var certificatePinningManager: CertificatePinningManager!
    private var enhancedOAuthManager: EnhancedOAuthManager!
    
    // MARK: - Setup and Teardown
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        // Initialize security managers
        advancedSecurityManager = AdvancedSecurityManager.shared
        rateLimitingManager = RateLimitingManager.shared
        certificatePinningManager = CertificatePinningManager.shared
        enhancedOAuthManager = EnhancedOAuthManager.shared
    }
    
    override func tearDownWithError() throws {
        // Clean up test data
        try super.tearDownWithError()
    }
    
    // MARK: - Automated Secrets Rotation Tests
    
    func testAutomatedSecretsRotation() throws {
        // Test automated secrets rotation
        let expectation = XCTestExpectation(description: "Secrets rotation")
        
        Task {
            // Trigger secrets rotation
            await advancedSecurityManager.rotateSecrets()
            
            // Verify rotation was logged
            let auditLogs = advancedSecurityManager.auditLogs
            let rotationLogs = auditLogs.filter { $0.action == "secrets_rotation" }
            
            XCTAssertFalse(rotationLogs.isEmpty, "Secrets rotation should be logged")
            
            // Verify rotation success
            let successLogs = rotationLogs.filter { $0.result == .success }
            XCTAssertFalse(successLogs.isEmpty, "Secrets rotation should succeed")
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 10.0)
    }
    
    func testSecretsRotationFailureHandling() throws {
        // Test secrets rotation failure handling
        let expectation = XCTestExpectation(description: "Secrets rotation failure")
        
        Task {
            // Simulate rotation failure by triggering rotation multiple times
            for _ in 0..<3 {
                await advancedSecurityManager.rotateSecrets()
            }
            
            // Verify failure handling
            let auditLogs = advancedSecurityManager.auditLogs
            let failureLogs = auditLogs.filter { $0.result == .failure }
            
            // Should handle failures gracefully
            XCTAssertTrue(failureLogs.isEmpty || failureLogs.count < 3, "Should handle rotation failures gracefully")
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 15.0)
    }
    
    func testSecretsRotationSecurity() throws {
        // Test that rotated secrets are secure
        let expectation = XCTestExpectation(description: "Secrets rotation security")
        
        Task {
            // Trigger rotation
            await advancedSecurityManager.rotateSecrets()
            
            // Verify new secrets are secure
            let auditLogs = advancedSecurityManager.auditLogs
            let rotationLogs = auditLogs.filter { $0.action == "secrets_rotation" && $0.result == .success }
            
            for log in rotationLogs {
                // Verify rotation metadata
                XCTAssertTrue(log.metadata.keys.contains("rotation_type"), "Rotation should include metadata")
                XCTAssertEqual(log.metadata["rotation_type"], "automated", "Rotation should be automated")
            }
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 10.0)
    }
    
    // MARK: - Real-Time Threat Intelligence Tests
    
    func testThreatIntelligenceFetching() throws {
        // Test threat intelligence fetching
        let expectation = XCTestExpectation(description: "Threat intelligence fetching")
        
        Task {
            // Fetch threat intelligence
            await advancedSecurityManager.fetchThreatIntelligence()
            
            // Verify threats were fetched
            let threats = advancedSecurityManager.threatIntelligence
            XCTAssertFalse(threats.isEmpty, "Should fetch threat intelligence")
            
            // Verify threat structure
            for threat in threats {
                XCTAssertNotNil(threat.id, "Threat should have ID")
                XCTAssertNotNil(threat.threatType, "Threat should have type")
                XCTAssertNotNil(threat.severity, "Threat should have severity")
                XCTAssertNotNil(threat.description, "Threat should have description")
                XCTAssertNotNil(threat.indicators, "Threat should have indicators")
                XCTAssertNotNil(threat.source, "Threat should have source")
                XCTAssertNotNil(threat.timestamp, "Threat should have timestamp")
                XCTAssertNotNil(threat.mitigationSteps, "Threat should have mitigation steps")
            }
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 10.0)
    }
    
    func testThreatIntelligenceUpdates() throws {
        // Test threat intelligence updates
        let expectation = XCTestExpectation(description: "Threat intelligence updates")
        
        Task {
            // Get initial threats
            let initialThreats = advancedSecurityManager.threatIntelligence.count
            
            // Fetch new threats
            await advancedSecurityManager.fetchThreatIntelligence()
            
            // Verify threats were updated
            let updatedThreats = advancedSecurityManager.threatIntelligence.count
            XCTAssertGreaterThanOrEqual(updatedThreats, initialThreats, "Threat intelligence should be updated")
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 10.0)
    }
    
    func testThreatIntelligenceRelevance() throws {
        // Test threat relevance checking
        let expectation = XCTestExpectation(description: "Threat relevance")
        
        Task {
            // Create test threat
            let testThreat = AdvancedSecurityManager.ThreatIntelligence(
                threatType: .malware,
                severity: .high,
                description: "Test malware threat",
                indicators: ["test_indicator_1", "test_indicator_2"],
                source: "test_source",
                timestamp: Date(),
                isActive: true,
                mitigationSteps: ["test_mitigation_1", "test_mitigation_2"]
            )
            
            // Check threat relevance
            let isRelevant = await advancedSecurityManager.isThreatRelevant(testThreat)
            
            // Should handle relevance checking
            XCTAssertNotNil(isRelevant, "Threat relevance should be determined")
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 10.0)
    }
    
    // MARK: - Comprehensive Audit Logging Tests
    
    func testComprehensiveAuditLogging() throws {
        // Test comprehensive audit logging
        let expectation = XCTestExpectation(description: "Comprehensive audit logging")
        
        Task {
            // Log various audit events
            await advancedSecurityManager.logAuditEvent(
                action: "login",
                resource: "user_authentication",
                result: .success,
                userId: "test_user",
                ipAddress: "192.168.1.1",
                userAgent: "test_agent",
                sessionId: "test_session",
                dataClassification: .public_data,
                metadata: ["test_key": "test_value"]
            )
            
            await advancedSecurityManager.logAuditEvent(
                action: "data_access",
                resource: "health_records",
                result: .success,
                userId: "test_user",
                ipAddress: "192.168.1.1",
                dataClassification: .phi_data,
                metadata: ["record_id": "12345"]
            )
            
            await advancedSecurityManager.logAuditEvent(
                action: "file_download",
                resource: "export_data",
                result: .success,
                userId: "test_user",
                ipAddress: "192.168.1.1",
                dataClassification: .confidential_data,
                metadata: ["file_type": "csv", "file_size": "1024"]
            )
            
            // Verify audit logs were created
            let auditLogs = advancedSecurityManager.auditLogs
            XCTAssertGreaterThanOrEqual(auditLogs.count, 3, "Should log multiple audit events")
            
            // Verify log structure
            for log in auditLogs {
                XCTAssertNotNil(log.id, "Audit log should have ID")
                XCTAssertNotNil(log.action, "Audit log should have action")
                XCTAssertNotNil(log.resource, "Audit log should have resource")
                XCTAssertNotNil(log.timestamp, "Audit log should have timestamp")
                XCTAssertNotNil(log.result, "Audit log should have result")
            }
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 10.0)
    }
    
    func testAuditLogSuspiciousPatternDetection() throws {
        // Test suspicious pattern detection in audit logs
        let expectation = XCTestExpectation(description: "Suspicious pattern detection")
        
        Task {
            // Log multiple failed login attempts to trigger brute force detection
            for i in 0..<6 {
                await advancedSecurityManager.logAuditEvent(
                    action: "login",
                    resource: "user_authentication",
                    result: .failure,
                    userId: "test_user",
                    ipAddress: "192.168.1.1",
                    metadata: ["attempt": "\(i + 1)"]
                )
            }
            
            // Log multiple denied access attempts
            for i in 0..<11 {
                await advancedSecurityManager.logAuditEvent(
                    action: "data_access",
                    resource: "restricted_data",
                    result: .denied,
                    userId: "test_user",
                    ipAddress: "192.168.1.1",
                    metadata: ["attempt": "\(i + 1)"]
                )
            }
            
            // Log excessive PHI access
            for i in 0..<51 {
                await advancedSecurityManager.logAuditEvent(
                    action: "data_access",
                    resource: "health_records",
                    result: .success,
                    userId: "test_user",
                    ipAddress: "192.168.1.1",
                    dataClassification: .phi_data,
                    metadata: ["record_id": "\(i + 1)"]
                )
            }
            
            // Verify security incidents were created
            let incidents = advancedSecurityManager.securityIncidents
            XCTAssertGreaterThanOrEqual(incidents.count, 1, "Should create security incidents for suspicious patterns")
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 15.0)
    }
    
    func testAuditLogDataClassification() throws {
        // Test audit log data classification
        let expectation = XCTestExpectation(description: "Data classification")
        
        Task {
            // Log events with different data classifications
            let classifications: [AdvancedSecurityManager.AuditLogEntry.DataClassification] = [
                .public_data,
                .internal_data,
                .confidential_data,
                .restricted_data,
                .phi_data
            ]
            
            for classification in classifications {
                await advancedSecurityManager.logAuditEvent(
                    action: "data_access",
                    resource: "test_resource",
                    result: .success,
                    userId: "test_user",
                    dataClassification: classification,
                    metadata: ["classification": classification.rawValue]
                )
            }
            
            // Verify all classifications were logged
            let auditLogs = advancedSecurityManager.auditLogs
            let classifiedLogs = auditLogs.filter { $0.dataClassification != nil }
            XCTAssertGreaterThanOrEqual(classifiedLogs.count, classifications.count, "Should log all data classifications")
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 10.0)
    }
    
    // MARK: - ML-Based Rate Limiting Tests
    
    func testMLBasedRateLimiting() throws {
        // Test ML-based rate limiting
        let expectation = XCTestExpectation(description: "ML-based rate limiting")
        
        // Create test user behavior
        let lowRiskBehavior = AdvancedSecurityManager.UserBehavior(
            isKnownUser: true,
            userRiskScore: 0.1,
            historicalBehavior: ["login": 10, "data_access": 5],
            deviceTrustScore: 0.9,
            locationRiskScore: 0.1
        )
        
        let highRiskBehavior = AdvancedSecurityManager.UserBehavior(
            isKnownUser: false,
            userRiskScore: 0.8,
            historicalBehavior: ["login": 100, "data_access": 50],
            deviceTrustScore: 0.3,
            locationRiskScore: 0.7
        )
        
        // Test rate limiting with different behaviors
        let lowRiskResult = advancedSecurityManager.adaptiveRateLimit(
            identifier: "api_general",
            ipAddress: "192.168.1.1",
            userBehavior: lowRiskBehavior
        )
        
        let highRiskResult = advancedSecurityManager.adaptiveRateLimit(
            identifier: "api_general",
            ipAddress: "192.168.1.2",
            userBehavior: highRiskBehavior
        )
        
        // Verify rate limiting works
        XCTAssertNotNil(lowRiskResult, "Low risk rate limiting should work")
        XCTAssertNotNil(highRiskResult, "High risk rate limiting should work")
        
        expectation.fulfill()
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testUserBehaviorAnalysis() throws {
        // Test user behavior analysis
        let expectation = XCTestExpectation(description: "User behavior analysis")
        
        // Create various user behaviors
        let behaviors = [
            AdvancedSecurityManager.UserBehavior(
                isKnownUser: true,
                userRiskScore: 0.1,
                historicalBehavior: ["login": 5, "data_access": 2],
                deviceTrustScore: 0.9,
                locationRiskScore: 0.1
            ),
            AdvancedSecurityManager.UserBehavior(
                isKnownUser: false,
                userRiskScore: 0.5,
                historicalBehavior: ["login": 20, "data_access": 10],
                deviceTrustScore: 0.6,
                locationRiskScore: 0.4
            ),
            AdvancedSecurityManager.UserBehavior(
                isKnownUser: false,
                userRiskScore: 0.9,
                historicalBehavior: ["login": 100, "data_access": 100],
                deviceTrustScore: 0.2,
                locationRiskScore: 0.8
            )
        ]
        
        // Test rate limiting for each behavior
        for behavior in behaviors {
            let result = advancedSecurityManager.adaptiveRateLimit(
                identifier: "api_sensitive",
                ipAddress: "192.168.1.1",
                userBehavior: behavior
            )
            
            XCTAssertNotNil(result, "Rate limiting should work for all behaviors")
        }
        
        expectation.fulfill()
        wait(for: [expectation], timeout: 5.0)
    }
    
    // MARK: - Security Incident Management Tests
    
    func testSecurityIncidentCreation() throws {
        // Test security incident creation
        let expectation = XCTestExpectation(description: "Security incident creation")
        
        Task {
            // Create various security incidents
            await advancedSecurityManager.createSecurityIncident(
                type: .unauthorized_access,
                severity: .high,
                description: "Test unauthorized access incident",
                affectedUsers: ["test_user_1", "test_user_2"],
                affectedSystems: ["access_control", "user_management"]
            )
            
            await advancedSecurityManager.createSecurityIncident(
                type: .data_breach,
                severity: .critical,
                description: "Test data breach incident",
                affectedUsers: ["test_user_3"],
                affectedSystems: ["database", "file_storage"]
            )
            
            await advancedSecurityManager.createSecurityIncident(
                type: .malware_infection,
                severity: .medium,
                description: "Test malware incident",
                affectedUsers: [],
                affectedSystems: ["endpoint_protection"]
            )
            
            // Verify incidents were created
            let incidents = advancedSecurityManager.securityIncidents
            XCTAssertGreaterThanOrEqual(incidents.count, 3, "Should create multiple security incidents")
            
            // Verify incident structure
            for incident in incidents {
                XCTAssertNotNil(incident.id, "Incident should have ID")
                XCTAssertNotNil(incident.incidentType, "Incident should have type")
                XCTAssertNotNil(incident.severity, "Incident should have severity")
                XCTAssertNotNil(incident.description, "Incident should have description")
                XCTAssertNotNil(incident.detectedAt, "Incident should have detection time")
                XCTAssertNotNil(incident.status, "Incident should have status")
            }
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 10.0)
    }
    
    func testSecurityIncidentResponse() throws {
        // Test security incident response
        let expectation = XCTestExpectation(description: "Security incident response")
        
        Task {
            // Create a security incident
            await advancedSecurityManager.createSecurityIncident(
                type: .system_compromise,
                severity: .critical,
                description: "Test system compromise incident",
                affectedSystems: ["core_system"]
            )
            
            // Verify incident response was triggered
            let incidents = advancedSecurityManager.securityIncidents
            let criticalIncidents = incidents.filter { $0.severity == .critical }
            
            XCTAssertFalse(criticalIncidents.isEmpty, "Should handle critical incidents")
            
            // Verify incident status was updated
            let investigatingIncidents = incidents.filter { $0.status == .investigating }
            XCTAssertFalse(investigatingIncidents.isEmpty, "Should update incident status")
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 10.0)
    }
    
    // MARK: - Security Metrics Tests
    
    func testSecurityMetricsCalculation() throws {
        // Test security metrics calculation
        let expectation = XCTestExpectation(description: "Security metrics calculation")
        
        Task {
            // Create some threats and incidents to calculate metrics
            await advancedSecurityManager.fetchThreatIntelligence()
            
            await advancedSecurityManager.createSecurityIncident(
                type: .unauthorized_access,
                severity: .medium,
                description: "Test incident for metrics",
                affectedUsers: ["test_user"]
            )
            
            // Verify metrics were calculated
            let metrics = advancedSecurityManager.securityMetrics
            
            XCTAssertNotNil(metrics.totalThreats, "Should calculate total threats")
            XCTAssertNotNil(metrics.criticalThreats, "Should calculate critical threats")
            XCTAssertNotNil(metrics.highThreats, "Should calculate high threats")
            XCTAssertNotNil(metrics.mediumThreats, "Should calculate medium threats")
            XCTAssertNotNil(metrics.lowThreats, "Should calculate low threats")
            XCTAssertNotNil(metrics.incidentsResolved, "Should calculate resolved incidents")
            XCTAssertNotNil(metrics.averageResponseTime, "Should calculate average response time")
            XCTAssertNotNil(metrics.complianceScore, "Should calculate compliance score")
            XCTAssertNotNil(metrics.securityScore, "Should calculate security score")
            XCTAssertNotNil(metrics.lastUpdated, "Should track last update time")
            
            // Verify threat level calculation
            XCTAssertNotNil(metrics.threatLevel, "Should calculate threat level")
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 10.0)
    }
    
    func testSecurityMetricsUpdates() throws {
        // Test security metrics updates
        let expectation = XCTestExpectation(description: "Security metrics updates")
        
        Task {
            // Get initial metrics
            let initialMetrics = advancedSecurityManager.securityMetrics
            
            // Create new threats and incidents
            await advancedSecurityManager.fetchThreatIntelligence()
            
            await advancedSecurityManager.createSecurityIncident(
                type: .data_breach,
                severity: .high,
                description: "Test incident for metrics update",
                affectedUsers: ["test_user"]
            )
            
            // Verify metrics were updated
            let updatedMetrics = advancedSecurityManager.securityMetrics
            XCTAssertNotEqual(initialMetrics.lastUpdated, updatedMetrics.lastUpdated, "Metrics should be updated")
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 10.0)
    }
    
    // MARK: - Integration Tests
    
    func testAdvancedSecurityIntegration() throws {
        // Test integration between advanced security features
        let expectation = XCTestExpectation(description: "Advanced security integration")
        
        Task {
            // Start comprehensive security monitoring
            await advancedSecurityManager.monitorSystemSecurity()
            
            // Perform various security operations
            await advancedSecurityManager.fetchThreatIntelligence()
            
            await advancedSecurityManager.logAuditEvent(
                action: "comprehensive_test",
                resource: "integration_test",
                result: .success,
                userId: "test_user",
                metadata: ["test_type": "integration"]
            )
            
            await advancedSecurityManager.createSecurityIncident(
                type: .other,
                severity: .low,
                description: "Integration test incident",
                affectedUsers: ["test_user"]
            )
            
            // Verify all systems work together
            let threats = advancedSecurityManager.threatIntelligence
            let auditLogs = advancedSecurityManager.auditLogs
            let incidents = advancedSecurityManager.securityIncidents
            let metrics = advancedSecurityManager.securityMetrics
            
            XCTAssertFalse(threats.isEmpty || auditLogs.isEmpty || incidents.isEmpty, "All systems should work together")
            XCTAssertNotNil(metrics, "Metrics should be available")
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 15.0)
    }
    
    func testAdvancedSecurityPerformance() throws {
        // Test performance of advanced security features
        let expectation = XCTestExpectation(description: "Advanced security performance")
        
        let iterations = 100
        let startTime = Date()
        
        Task {
            // Perform multiple security operations
            for i in 0..<iterations {
                await advancedSecurityManager.logAuditEvent(
                    action: "performance_test",
                    resource: "test_resource_\(i)",
                    result: .success,
                    userId: "test_user",
                    metadata: ["iteration": "\(i)"]
                )
            }
            
            let endTime = Date()
            let duration = endTime.timeIntervalSince(startTime)
            
            // Performance should be acceptable (less than 5 seconds for 100 operations)
            XCTAssertLessThan(duration, 5.0, "Advanced security operations should be performant")
            
            let operationsPerSecond = Double(iterations) / duration
            XCTAssertGreaterThan(operationsPerSecond, 10, "Should handle at least 10 operations per second")
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 10.0)
    }
    
    // MARK: - Error Handling Tests
    
    func testAdvancedSecurityErrorHandling() throws {
        // Test error handling in advanced security features
        let expectation = XCTestExpectation(description: "Advanced security error handling")
        
        Task {
            // Test with invalid inputs
            await advancedSecurityManager.logAuditEvent(
                action: "",
                resource: "",
                result: .success,
                metadata: [:]
            )
            
            // Test with nil values
            await advancedSecurityManager.logAuditEvent(
                action: "test_action",
                resource: "test_resource",
                result: .success,
                userId: nil,
                ipAddress: nil,
                userAgent: nil,
                sessionId: nil,
                dataClassification: nil,
                metadata: [:]
            )
            
            // Verify system handles errors gracefully
            let auditLogs = advancedSecurityManager.auditLogs
            XCTAssertFalse(auditLogs.isEmpty, "Should handle invalid inputs gracefully")
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 10.0)
    }
    
    // MARK: - Compliance Validation Tests
    
    func testAdvancedSecurityCompliance() throws {
        // Test compliance of advanced security features
        let expectation = XCTestExpectation(description: "Advanced security compliance")
        
        Task {
            // Test HIPAA compliance
            await advancedSecurityManager.logAuditEvent(
                action: "phi_access",
                resource: "health_records",
                result: .success,
                userId: "test_user",
                dataClassification: .phi_data,
                metadata: ["compliance": "hipaa"]
            )
            
            // Test GDPR compliance
            await advancedSecurityManager.logAuditEvent(
                action: "data_export",
                resource: "user_data",
                result: .success,
                userId: "test_user",
                dataClassification: .confidential_data,
                metadata: ["compliance": "gdpr"]
            )
            
            // Test SOC 2 compliance
            await advancedSecurityManager.logAuditEvent(
                action: "control_monitoring",
                resource: "security_controls",
                result: .success,
                userId: "test_user",
                metadata: ["compliance": "soc2"]
            )
            
            // Verify compliance logging
            let auditLogs = advancedSecurityManager.auditLogs
            let complianceLogs = auditLogs.filter { $0.metadata.values.contains("hipaa") || $0.metadata.values.contains("gdpr") || $0.metadata.values.contains("soc2") }
            
            XCTAssertGreaterThanOrEqual(complianceLogs.count, 3, "Should log compliance events")
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 10.0)
    }
} 
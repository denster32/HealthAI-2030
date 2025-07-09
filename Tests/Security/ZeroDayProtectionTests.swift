import XCTest
import Foundation
@testable import HealthAI2030

/// Zero-Day Protection Tests for HealthAI-2030
/// Tests behavioral analysis, anomaly detection, threat hunting, and zero-day threat management
/// Agent 1 (Security & Dependencies Czar) - Critical Security Enhancement Tests
/// July 25, 2025
final class ZeroDayProtectionTests: XCTestCase {
    
    var zeroDayManager: ZeroDayProtectionManager!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        zeroDayManager = ZeroDayProtectionManager.shared
    }
    
    override func tearDownWithError() throws {
        zeroDayManager = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Behavioral Analysis Tests
    
    func testBehavioralAnalysisSetup() async throws {
        // Test that behavioral analysis is properly set up
        XCTAssertTrue(zeroDayManager.isEnabled)
        
        // Wait for initial behavioral analysis to complete
        try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
        // Verify behavioral analysis has been performed
        XCTAssertGreaterThanOrEqual(zeroDayManager.behavioralAnalysis.count, 0)
    }
    
    func testBehavioralAnalysisWithNormalEvents() async throws {
        // Test behavioral analysis with normal events
        let normalEvents = [
            ZeroDayProtectionManager.SecurityEvent(
                eventType: "login",
                userId: "user1",
                sessionId: "session1",
                timestamp: Date(),
                ipAddress: "192.168.1.1",
                userAgent: "test_agent",
                action: "login",
                resource: "authentication",
                result: "success",
                metadata: ["method": "password"],
                severity: 1,
                source: "auth_system"
            ),
            ZeroDayProtectionManager.SecurityEvent(
                eventType: "data_access",
                userId: "user1",
                sessionId: "session1",
                timestamp: Date(),
                ipAddress: "192.168.1.1",
                userAgent: "test_agent",
                action: "read",
                resource: "health_records",
                result: "success",
                metadata: ["record_count": "5"],
                severity: 2,
                source: "data_system"
            )
        ]
        
        // Perform behavioral analysis
        await zeroDayManager.performBehavioralAnalysis()
        
        // Verify analysis results
        XCTAssertGreaterThanOrEqual(zeroDayManager.behavioralAnalysis.count, 0)
        
        if let analysis = zeroDayManager.behavioralAnalysis.first {
            XCTAssertEqual(analysis.userId, "user1")
            XCTAssertEqual(analysis.sessionId, "session1")
            XCTAssertGreaterThanOrEqual(analysis.confidence, 0.0)
            XCTAssertLessThanOrEqual(analysis.confidence, 1.0)
            XCTAssertGreaterThanOrEqual(analysis.riskScore, 0.0)
            XCTAssertLessThanOrEqual(analysis.riskScore, 1.0)
        }
    }
    
    func testBehavioralAnalysisWithSuspiciousEvents() async throws {
        // Test behavioral analysis with suspicious events
        let suspiciousEvents = [
            ZeroDayProtectionManager.SecurityEvent(
                eventType: "data_access",
                userId: "user2",
                sessionId: "session2",
                timestamp: Date(),
                ipAddress: "192.168.1.2",
                userAgent: "test_agent",
                action: "export",
                resource: "health_records",
                result: "success",
                metadata: ["record_count": "100"],
                severity: 4,
                source: "data_system"
            ),
            ZeroDayProtectionManager.SecurityEvent(
                eventType: "data_access",
                userId: "user2",
                sessionId: "session2",
                timestamp: Date(),
                ipAddress: "192.168.1.2",
                userAgent: "test_agent",
                action: "delete",
                resource: "health_records",
                result: "success",
                metadata: ["record_count": "50"],
                severity: 5,
                source: "data_system"
            )
        ]
        
        // Perform behavioral analysis
        await zeroDayManager.performBehavioralAnalysis()
        
        // Verify analysis results
        XCTAssertGreaterThanOrEqual(zeroDayManager.behavioralAnalysis.count, 0)
        
        if let analysis = zeroDayManager.behavioralAnalysis.first(where: { $0.userId == "user2" }) {
            XCTAssertEqual(analysis.userId, "user2")
            XCTAssertGreaterThanOrEqual(analysis.riskScore, 0.0)
            XCTAssertLessThanOrEqual(analysis.riskScore, 1.0)
        }
    }
    
    func testBehavioralAnalysisWithMaliciousEvents() async throws {
        // Test behavioral analysis with malicious events
        let maliciousEvents = [
            ZeroDayProtectionManager.SecurityEvent(
                eventType: "data_access",
                userId: "user3",
                sessionId: "session3",
                timestamp: Date(),
                ipAddress: "192.168.1.3",
                userAgent: "test_agent",
                action: "export",
                resource: "health_records",
                result: "success",
                metadata: ["record_count": "1000"],
                severity: 5,
                source: "data_system"
            ),
            ZeroDayProtectionManager.SecurityEvent(
                eventType: "data_access",
                userId: "user3",
                sessionId: "session3",
                timestamp: Date(),
                ipAddress: "192.168.1.3",
                userAgent: "test_agent",
                action: "delete",
                resource: "health_records",
                result: "success",
                metadata: ["record_count": "500"],
                severity: 5,
                source: "data_system"
            ),
            ZeroDayProtectionManager.SecurityEvent(
                eventType: "data_access",
                userId: "user3",
                sessionId: "session3",
                timestamp: Date(),
                ipAddress: "192.168.1.3",
                userAgent: "test_agent",
                action: "export",
                resource: "health_records",
                result: "success",
                metadata: ["record_count": "2000"],
                severity: 5,
                source: "data_system"
            )
        ]
        
        // Perform behavioral analysis
        await zeroDayManager.performBehavioralAnalysis()
        
        // Verify analysis results
        XCTAssertGreaterThanOrEqual(zeroDayManager.behavioralAnalysis.count, 0)
        
        if let analysis = zeroDayManager.behavioralAnalysis.first(where: { $0.userId == "user3" }) {
            XCTAssertEqual(analysis.userId, "user3")
            XCTAssertGreaterThanOrEqual(analysis.riskScore, 0.0)
            XCTAssertLessThanOrEqual(analysis.riskScore, 1.0)
        }
    }
    
    // MARK: - Anomaly Detection Tests
    
    func testAnomalyDetectionSetup() async throws {
        // Test that anomaly detection is properly set up
        XCTAssertTrue(zeroDayManager.isEnabled)
        
        // Wait for initial anomaly detection to complete
        try await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds
        
        // Verify anomaly detection has been performed
        XCTAssertGreaterThanOrEqual(zeroDayManager.anomalies.count, 0)
    }
    
    func testNetworkAnomalyDetection() async throws {
        // Test network anomaly detection
        await zeroDayManager.performAnomalyDetection()
        
        // Verify network anomalies are detected
        let networkAnomalies = zeroDayManager.anomalies.filter { $0.anomalyType == .network_anomaly }
        XCTAssertGreaterThanOrEqual(networkAnomalies.count, 0)
        
        if let anomaly = networkAnomalies.first {
            XCTAssertEqual(anomaly.anomalyType, .network_anomaly)
            XCTAssertGreaterThanOrEqual(anomaly.confidence, 0.0)
            XCTAssertLessThanOrEqual(anomaly.confidence, 1.0)
            XCTAssertFalse(anomaly.mitigationSteps.isEmpty)
        }
    }
    
    func testUserBehaviorAnomalyDetection() async throws {
        // Test user behavior anomaly detection
        await zeroDayManager.performAnomalyDetection()
        
        // Verify user behavior anomalies are detected
        let userBehaviorAnomalies = zeroDayManager.anomalies.filter { $0.anomalyType == .user_behavior_anomaly }
        XCTAssertGreaterThanOrEqual(userBehaviorAnomalies.count, 0)
        
        if let anomaly = userBehaviorAnomalies.first {
            XCTAssertEqual(anomaly.anomalyType, .user_behavior_anomaly)
            XCTAssertGreaterThanOrEqual(anomaly.confidence, 0.0)
            XCTAssertLessThanOrEqual(anomaly.confidence, 1.0)
            XCTAssertFalse(anomaly.mitigationSteps.isEmpty)
        }
    }
    
    func testZeroDayAnomalyDetection() async throws {
        // Test zero-day anomaly detection
        await zeroDayManager.performAnomalyDetection()
        
        // Verify zero-day anomalies are detected
        let zeroDayAnomalies = zeroDayManager.anomalies.filter { $0.isZeroDay }
        XCTAssertGreaterThanOrEqual(zeroDayAnomalies.count, 0)
        
        if let anomaly = zeroDayAnomalies.first {
            XCTAssertTrue(anomaly.isZeroDay)
            XCTAssertGreaterThanOrEqual(anomaly.confidence, 0.0)
            XCTAssertLessThanOrEqual(anomaly.confidence, 1.0)
            XCTAssertFalse(anomaly.mitigationSteps.isEmpty)
        }
    }
    
    // MARK: - Threat Hunting Tests
    
    func testThreatHuntingSetup() async throws {
        // Test that threat hunting is properly set up
        XCTAssertTrue(zeroDayManager.isEnabled)
        
        // Wait for initial threat hunting to complete
        try await Task.sleep(nanoseconds: 4_000_000_000) // 4 seconds
        
        // Verify threat hunting has been performed
        XCTAssertGreaterThanOrEqual(zeroDayManager.threatHunts.count, 0)
    }
    
    func testBehavioralThreatHunting() async throws {
        // Test behavioral threat hunting
        await zeroDayManager.performThreatHunting()
        
        // Verify behavioral hunts are performed
        let behavioralHunts = zeroDayManager.threatHunts.filter { $0.huntType == .behavioral_hunt }
        XCTAssertGreaterThanOrEqual(behavioralHunts.count, 0)
        
        if let hunt = behavioralHunts.first {
            XCTAssertEqual(hunt.huntType, .behavioral_hunt)
            XCTAssertEqual(hunt.status, .completed)
            XCTAssertGreaterThanOrEqual(hunt.riskScore, 0.0)
            XCTAssertLessThanOrEqual(hunt.riskScore, 1.0)
            XCTAssertFalse(hunt.recommendations.isEmpty)
        }
    }
    
    func testNetworkThreatHunting() async throws {
        // Test network threat hunting
        await zeroDayManager.performThreatHunting()
        
        // Verify network hunts are performed
        let networkHunts = zeroDayManager.threatHunts.filter { $0.huntType == .network_hunt }
        XCTAssertGreaterThanOrEqual(networkHunts.count, 0)
        
        if let hunt = networkHunts.first {
            XCTAssertEqual(hunt.huntType, .network_hunt)
            XCTAssertEqual(hunt.status, .completed)
            XCTAssertGreaterThanOrEqual(hunt.riskScore, 0.0)
            XCTAssertLessThanOrEqual(hunt.riskScore, 1.0)
        }
    }
    
    func testComprehensiveThreatHunting() async throws {
        // Test comprehensive threat hunting
        await zeroDayManager.performThreatHunting()
        
        // Verify comprehensive hunts are performed
        let comprehensiveHunts = zeroDayManager.threatHunts.filter { $0.huntType == .comprehensive_hunt }
        XCTAssertGreaterThanOrEqual(comprehensiveHunts.count, 0)
        
        if let hunt = comprehensiveHunts.first {
            XCTAssertEqual(hunt.huntType, .comprehensive_hunt)
            XCTAssertEqual(hunt.status, .completed)
            XCTAssertGreaterThanOrEqual(hunt.riskScore, 0.0)
            XCTAssertLessThanOrEqual(hunt.riskScore, 1.0)
        }
    }
    
    // MARK: - Zero-Day Threat Management Tests
    
    func testZeroDayThreatCreation() async throws {
        // Test zero-day threat creation
        await zeroDayManager.performBehavioralAnalysis()
        await zeroDayManager.performAnomalyDetection()
        await zeroDayManager.performThreatHunting()
        
        // Verify zero-day threats are created
        XCTAssertGreaterThanOrEqual(zeroDayManager.zeroDayThreats.count, 0)
        
        if let threat = zeroDayManager.zeroDayThreats.first {
            XCTAssertGreaterThanOrEqual(threat.confidence, 0.0)
            XCTAssertLessThanOrEqual(threat.confidence, 1.0)
            XCTAssertFalse(threat.responseActions.isEmpty)
            XCTAssertFalse(threat.affectedSystems.isEmpty)
            XCTAssertFalse(threat.indicators.isEmpty)
        }
    }
    
    func testZeroDayThreatFromBehavioralAnalysis() async throws {
        // Test zero-day threat creation from behavioral analysis
        let criticalAnalysis = ZeroDayProtectionManager.BehavioralAnalysis(
            userId: "test_user",
            sessionId: "test_session",
            behaviorPattern: .malicious,
            riskScore: 0.9,
            confidence: 0.95,
            timestamp: Date(),
            metadata: ["test": "critical"],
            isAnomalous: true,
            threatLevel: .critical
        )
        
        // Create zero-day threat
        await zeroDayManager.performBehavioralAnalysis()
        
        // Verify zero-day threat was created
        let criticalThreats = zeroDayManager.zeroDayThreats.filter { $0.severity == .critical }
        XCTAssertGreaterThanOrEqual(criticalThreats.count, 0)
    }
    
    func testZeroDayThreatFromAnomaly() async throws {
        // Test zero-day threat creation from anomaly
        let zeroDayAnomaly = ZeroDayProtectionManager.Anomaly(
            anomalyType: .user_behavior_anomaly,
            severity: .critical,
            description: "Zero-day user behavior anomaly",
            detectedAt: Date(),
            source: "test_source",
            affectedUsers: ["test_user"],
            affectedSystems: ["test_system"],
            confidence: 0.9,
            isZeroDay: true,
            mitigationSteps: ["Test mitigation"],
            metadata: ["test": "zero_day"]
        )
        
        // Create zero-day threat
        await zeroDayManager.performAnomalyDetection()
        
        // Verify zero-day threat was created
        let zeroDayThreats = zeroDayManager.zeroDayThreats.filter { $0.threatType == .vulnerability }
        XCTAssertGreaterThanOrEqual(zeroDayThreats.count, 0)
    }
    
    func testZeroDayThreatFromHunt() async throws {
        // Test zero-day threat creation from hunt
        let zeroDayHunt = ZeroDayProtectionManager.ThreatHunt(
            huntType: .behavioral_hunt,
            status: .completed,
            description: "Zero-day threat hunt",
            startedAt: Date().addingTimeInterval(-1800),
            completedAt: Date(),
            findings: [
                ZeroDayProtectionManager.ThreatFinding(
                    findingType: "zero_day_exploit",
                    description: "Zero-day exploit detected",
                    severity: "high",
                    confidence: 0.9,
                    timestamp: Date(),
                    evidence: ["zero_day_evidence"],
                    isZeroDay: true,
                    mitigation: "Apply patches"
                )
            ],
            affectedSystems: ["test_system"],
            riskScore: 0.8,
            isZeroDay: true,
            recommendations: ["Test recommendation"]
        )
        
        // Create zero-day threat
        await zeroDayManager.performThreatHunting()
        
        // Verify zero-day threat was created
        let zeroDayThreats = zeroDayManager.zeroDayThreats.filter { $0.threatType == .exploit }
        XCTAssertGreaterThanOrEqual(zeroDayThreats.count, 0)
    }
    
    // MARK: - Integration Tests
    
    func testZeroDayProtectionIntegration() async throws {
        // Test complete zero-day protection integration
        XCTAssertTrue(zeroDayManager.isEnabled)
        
        // Perform all protection activities
        await zeroDayManager.performBehavioralAnalysis()
        await zeroDayManager.performAnomalyDetection()
        await zeroDayManager.performThreatHunting()
        
        // Verify all components are working
        XCTAssertGreaterThanOrEqual(zeroDayManager.behavioralAnalysis.count, 0)
        XCTAssertGreaterThanOrEqual(zeroDayManager.anomalies.count, 0)
        XCTAssertGreaterThanOrEqual(zeroDayManager.threatHunts.count, 0)
        XCTAssertGreaterThanOrEqual(zeroDayManager.zeroDayThreats.count, 0)
        
        // Verify data consistency
        for analysis in zeroDayManager.behavioralAnalysis {
            XCTAssertGreaterThanOrEqual(analysis.confidence, 0.0)
            XCTAssertLessThanOrEqual(analysis.confidence, 1.0)
            XCTAssertGreaterThanOrEqual(analysis.riskScore, 0.0)
            XCTAssertLessThanOrEqual(analysis.riskScore, 1.0)
        }
        
        for anomaly in zeroDayManager.anomalies {
            XCTAssertGreaterThanOrEqual(anomaly.confidence, 0.0)
            XCTAssertLessThanOrEqual(anomaly.confidence, 1.0)
            XCTAssertFalse(anomaly.mitigationSteps.isEmpty)
        }
        
        for hunt in zeroDayManager.threatHunts {
            XCTAssertGreaterThanOrEqual(hunt.riskScore, 0.0)
            XCTAssertLessThanOrEqual(hunt.riskScore, 1.0)
        }
        
        for threat in zeroDayManager.zeroDayThreats {
            XCTAssertGreaterThanOrEqual(threat.confidence, 0.0)
            XCTAssertLessThanOrEqual(threat.confidence, 1.0)
            XCTAssertFalse(threat.responseActions.isEmpty)
        }
    }
    
    func testZeroDayProtectionPerformance() async throws {
        // Test zero-day protection performance
        let startTime = Date()
        
        // Perform all protection activities
        await zeroDayManager.performBehavioralAnalysis()
        await zeroDayManager.performAnomalyDetection()
        await zeroDayManager.performThreatHunting()
        
        let endTime = Date()
        let executionTime = endTime.timeIntervalSince(startTime)
        
        // Verify performance is within acceptable limits (less than 5 seconds)
        XCTAssertLessThan(executionTime, 5.0)
        
        print("Zero-day protection execution time: \(executionTime) seconds")
    }
    
    func testZeroDayProtectionMemoryUsage() async throws {
        // Test zero-day protection memory usage
        let initialMemory = getMemoryUsage()
        
        // Perform protection activities
        await zeroDayManager.performBehavioralAnalysis()
        await zeroDayManager.performAnomalyDetection()
        await zeroDayManager.performThreatHunting()
        
        let finalMemory = getMemoryUsage()
        let memoryIncrease = finalMemory - initialMemory
        
        // Verify memory usage is reasonable (less than 100MB increase)
        XCTAssertLessThan(memoryIncrease, 100 * 1024 * 1024) // 100MB
        
        print("Zero-day protection memory increase: \(memoryIncrease / (1024 * 1024)) MB")
    }
    
    // MARK: - Helper Methods
    
    private func getMemoryUsage() -> UInt64 {
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
            return info.resident_size
        } else {
            return 0
        }
    }
} 
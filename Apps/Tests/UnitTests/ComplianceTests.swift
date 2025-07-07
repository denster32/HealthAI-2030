import XCTest
import Combine
@testable import HealthAI2030

@MainActor
final class ComplianceTests: XCTestCase {
    var complianceManager: ComplianceManager!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        complianceManager = ComplianceManager()
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDown() {
        complianceManager.stopComplianceMonitoring()
        cancellables.removeAll()
        complianceManager = nil
        super.tearDown()
    }
    
    // MARK: - Compliance Frameworks Tests
    
    func testSetFramework() async throws {
        // Given
        let framework = ComplianceFramework.hipaa
        XCTAssertFalse(complianceManager.isLoading)
        
        // When
        try await complianceManager.setFramework(framework)
        
        // Then
        XCTAssertFalse(complianceManager.isLoading)
        let frameworks = try await complianceManager.getFrameworks()
        XCTAssertTrue(frameworks.contains(.hipaa))
    }
    
    func testGetFrameworks() async throws {
        // When
        let frameworks = try await complianceManager.getFrameworks()
        
        // Then
        XCTAssertTrue(frameworks.contains(.hipaa))
        XCTAssertTrue(frameworks.contains(.soc2))
        XCTAssertTrue(frameworks.contains(.iso27001))
        XCTAssertTrue(frameworks.contains(.gdpr))
        XCTAssertTrue(frameworks.contains(.ccpa))
    }
    
    // MARK: - Compliance Reporting Tests
    
    func testRunComplianceCheck() async throws {
        // When
        let report = try await complianceManager.runComplianceCheck()
        
        // Then
        XCTAssertEqual(report.framework, .hipaa)
        XCTAssertEqual(report.overallStatus, .compliant)
        XCTAssertGreaterThanOrEqual(report.score, 0)
        XCTAssertNotNil(report.generatedAt)
        XCTAssertNotNil(report.validUntil)
    }
    
    func testGetComplianceReports() async throws {
        // Given
        let timeRange = TimeRange(start: Date().addingTimeInterval(-86400), end: Date())
        
        // When
        let reports = try await complianceManager.getComplianceReports(timeRange: timeRange)
        
        // Then
        XCTAssertNotNil(reports)
        // Note: In this test implementation, reports list is empty
    }
    
    func testExportComplianceReport() async throws {
        // Given
        let report = try await complianceManager.runComplianceCheck()
        
        // When
        let pdfData = try await complianceManager.exportComplianceReport(report.id, format: .pdf)
        let csvData = try await complianceManager.exportComplianceReport(report.id, format: .csv)
        let jsonData = try await complianceManager.exportComplianceReport(report.id, format: .json)
        
        // Then
        XCTAssertNotNil(pdfData)
        XCTAssertNotNil(csvData)
        XCTAssertNotNil(jsonData)
    }
    
    // MARK: - Audit Trail Management Tests
    
    func testLogAuditEvent() async throws {
        // Given
        let event = AuditEvent(
            type: .login,
            description: "User login",
            userId: UUID(),
            metadata: ["ip": "127.0.0.1"]
        )
        
        // When
        try await complianceManager.logAuditEvent(event)
        
        // Then
        XCTAssertFalse(complianceManager.auditTrails.isEmpty)
        XCTAssertEqual(complianceManager.auditTrails.last?.event.type, .login)
    }
    
    func testGetAuditTrails() async throws {
        // Given
        let timeRange = TimeRange(start: Date().addingTimeInterval(-86400), end: Date())
        
        // When
        let trails = try await complianceManager.getAuditTrails(timeRange: timeRange)
        
        // Then
        XCTAssertNotNil(trails)
        // Note: In this test implementation, trails list is empty
    }
    
    func testExportAuditTrail() async throws {
        // When
        let jsonData = try await complianceManager.exportAuditTrail(format: .json)
        let csvData = try await complianceManager.exportAuditTrail(format: .csv)
        let xmlData = try await complianceManager.exportAuditTrail(format: .xml)
        
        // Then
        XCTAssertNotNil(jsonData)
        XCTAssertNotNil(csvData)
        XCTAssertNotNil(xmlData)
    }
    
    // MARK: - Compliance Dashboard Tests
    
    func testGetComplianceDashboard() async throws {
        // When
        let dashboard = try await complianceManager.getComplianceDashboard()
        
        // Then
        XCTAssertGreaterThanOrEqual(dashboard.complianceScore, 0)
        XCTAssertFalse(dashboard.frameworks.isEmpty)
        XCTAssertNotNil(dashboard.lastChecked)
    }
    
    // MARK: - Monitoring Tests
    
    func testStartAndStopComplianceMonitoring() {
        // When
        complianceManager.startComplianceMonitoring()
        complianceManager.stopComplianceMonitoring()
        
        // Then
        // Should not throw or crash
    }
    
    // MARK: - Published Properties Tests
    
    func testPublishedProperties() {
        // Given
        let expectation = XCTestExpectation(description: "Published properties updated")
        
        complianceManager.$complianceStatus
            .dropFirst()
            .sink { _ in
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // When
        Task {
            _ = try? await complianceManager.runComplianceCheck()
        }
        
        // Then
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testComplianceReportsPublishedProperty() async throws {
        // Given
        let expectation = XCTestExpectation(description: "Compliance reports updated")
        
        complianceManager.$complianceReports
            .dropFirst()
            .sink { _ in
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // When
        _ = try await complianceManager.runComplianceCheck()
        
        // Then
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testAuditTrailsPublishedProperty() async throws {
        // Given
        let expectation = XCTestExpectation(description: "Audit trails updated")
        
        complianceManager.$auditTrails
            .dropFirst()
            .sink { _ in
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // When
        let event = AuditEvent(
            type: .login,
            description: "Test login",
            userId: UUID(),
            metadata: [:]
        )
        try await complianceManager.logAuditEvent(event)
        
        // Then
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testComplianceDashboardPublishedProperty() async throws {
        // Given
        let expectation = XCTestExpectation(description: "Compliance dashboard updated")
        
        complianceManager.$complianceDashboard
            .dropFirst()
            .sink { _ in
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // When
        _ = try await complianceManager.getComplianceDashboard()
        
        // Then
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testLoadingState() async throws {
        // Given
        let expectation = XCTestExpectation(description: "Loading state changes")
        var loadingStates: [Bool] = []
        
        complianceManager.$isLoading
            .sink { loading in
                loadingStates.append(loading)
                if loadingStates.count >= 2 {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When
        _ = try await complianceManager.runComplianceCheck()
        
        // Then
        wait(for: [expectation], timeout: 5.0)
        XCTAssertTrue(loadingStates.contains(true))
        XCTAssertTrue(loadingStates.contains(false))
    }
    
    func testErrorHandling() async throws {
        // Given
        let expectation = XCTestExpectation(description: "Error state updated")
        
        complianceManager.$error
            .dropFirst()
            .sink { error in
                if error != nil {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When
        // Try to export a report with a random UUID (should fail and set error)
        do {
            _ = try await complianceManager.exportComplianceReport(UUID(), format: .json)
        } catch {
            // Expected error
        }
        
        // Then
        wait(for: [expectation], timeout: 5.0)
    }
}

// MARK: - Supporting Extensions

struct TimeRange: Equatable {
    let start: Date
    let end: Date
} 
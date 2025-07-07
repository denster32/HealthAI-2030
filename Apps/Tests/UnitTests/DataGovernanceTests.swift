import XCTest
import Combine
@testable import HealthAI2030

@MainActor
final class DataGovernanceTests: XCTestCase {
    var dataGovernanceManager: DataGovernanceManager!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        dataGovernanceManager = DataGovernanceManager()
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDown() {
        dataGovernanceManager.stopPrivacyMonitoring()
        cancellables.removeAll()
        dataGovernanceManager = nil
        super.tearDown()
    }
    
    // MARK: - Data Classification & Labeling Tests
    
    func testClassifyData() async throws {
        // Given
        let testData = "Test data".data(using: .utf8)!
        let dataType = DataType.userProfile
        XCTAssertFalse(dataGovernanceManager.isLoading)
        
        // When
        let classification = try await dataGovernanceManager.classifyData(testData, type: dataType)
        
        // Then
        XCTAssertEqual(classification.level, .confidential)
        XCTAssertEqual(classification.sensitivity, .high)
        XCTAssertNotNil(classification.classifiedAt)
        XCTAssertNotNil(classification.classifiedBy)
        XCTAssertFalse(dataGovernanceManager.isLoading)
    }
    
    func testGetDataClassifications() async throws {
        // When
        let classifications = try await dataGovernanceManager.getDataClassifications()
        
        // Then
        XCTAssertNotNil(classifications)
        // Note: In this test implementation, classifications list is empty
    }
    
    func testUpdateDataClassification() async throws {
        // Given
        let classification = DataClassification(
            id: UUID(),
            dataId: UUID(),
            level: .confidential,
            sensitivity: .high,
            labels: [],
            classifiedAt: Date(),
            classifiedBy: UUID(),
            metadata: [:]
        )
        XCTAssertFalse(dataGovernanceManager.isLoading)
        
        // When
        try await dataGovernanceManager.updateDataClassification(classification)
        
        // Then
        XCTAssertFalse(dataGovernanceManager.isLoading)
        // Classification should be updated without error
    }
    
    func testSetDataLabel() async throws {
        // Given
        let label = DataLabel(
            id: UUID(),
            name: "Personal Data",
            category: .personal,
            description: "Contains personal information",
            isSystem: true,
            createdAt: Date()
        )
        let dataId = UUID()
        XCTAssertFalse(dataGovernanceManager.isLoading)
        
        // When
        try await dataGovernanceManager.setDataLabel(label, for: dataId)
        
        // Then
        XCTAssertFalse(dataGovernanceManager.isLoading)
        // Label should be set without error
    }
    
    func testGetDataLabels() async throws {
        // When
        let labels = try await dataGovernanceManager.getDataLabels()
        
        // Then
        XCTAssertNotNil(labels)
        // Note: In this test implementation, labels list is empty
    }
    
    func testCreateDataLabel() async throws {
        // Given
        let label = DataLabel(
            id: UUID(),
            name: "Health Data",
            category: .health,
            description: "Contains health information",
            isSystem: false,
            createdAt: Date()
        )
        XCTAssertFalse(dataGovernanceManager.isLoading)
        
        // When
        try await dataGovernanceManager.createDataLabel(label)
        
        // Then
        XCTAssertFalse(dataGovernanceManager.isLoading)
        // Label should be created without error
    }
    
    // MARK: - Privacy Consent Management Tests
    
    func testRecordConsent() async throws {
        // Given
        let consent = ConsentRecord(
            id: UUID(),
            userId: UUID(),
            type: .dataProcessing,
            isGranted: true,
            grantedAt: Date(),
            revokedAt: nil,
            expiresAt: Date().addingTimeInterval(365 * 24 * 3600),
            metadata: [:]
        )
        XCTAssertFalse(dataGovernanceManager.isLoading)
        
        // When
        try await dataGovernanceManager.recordConsent(consent)
        
        // Then
        XCTAssertFalse(dataGovernanceManager.isLoading)
        // Consent should be recorded without error
    }
    
    func testGetConsentHistory() async throws {
        // Given
        let userId = UUID()
        
        // When
        let history = try await dataGovernanceManager.getConsentHistory(for: userId)
        
        // Then
        XCTAssertNotNil(history)
        // Note: In this test implementation, history list is empty
    }
    
    func testRevokeConsent() async throws {
        // Given
        let consentId = UUID()
        XCTAssertFalse(dataGovernanceManager.isLoading)
        
        // When
        try await dataGovernanceManager.revokeConsent(consentId)
        
        // Then
        XCTAssertFalse(dataGovernanceManager.isLoading)
        // Consent should be revoked without error
    }
    
    func testCheckConsent() async throws {
        // Given
        let consentType = ConsentType.dataProcessing
        let userId = UUID()
        
        // When
        let hasConsent = try await dataGovernanceManager.checkConsent(consentType, for: userId)
        
        // Then
        XCTAssertTrue(hasConsent) // Default state in test implementation
    }
    
    func testGetActiveConsents() async throws {
        // Given
        let userId = UUID()
        
        // When
        let consents = try await dataGovernanceManager.getActiveConsents(for: userId)
        
        // Then
        XCTAssertNotNil(consents)
        // Note: In this test implementation, consents list is empty
    }
    
    func testExportConsentData() async throws {
        // Given
        let userId = UUID()
        
        // When
        let data = try await dataGovernanceManager.exportConsentData(for: userId)
        
        // Then
        XCTAssertNotNil(data)
    }
    
    // MARK: - Data Retention & Deletion Tests
    
    func testCreateRetentionPolicy() async throws {
        // Given
        let policy = RetentionPolicy(
            id: UUID(),
            name: "User Data Retention",
            description: "Retention policy for user data",
            retentionPeriod: 365 * 24 * 3600,
            dataTypes: [.userProfile, .healthData],
            isActive: true,
            createdAt: Date(),
            updatedAt: Date()
        )
        XCTAssertFalse(dataGovernanceManager.isLoading)
        
        // When
        try await dataGovernanceManager.createRetentionPolicy(policy)
        
        // Then
        XCTAssertFalse(dataGovernanceManager.isLoading)
        // Policy should be created without error
    }
    
    func testUpdateRetentionPolicy() async throws {
        // Given
        let policy = RetentionPolicy(
            id: UUID(),
            name: "Updated Policy",
            description: "Updated retention policy",
            retentionPeriod: 730 * 24 * 3600,
            dataTypes: [.userProfile],
            isActive: true,
            createdAt: Date(),
            updatedAt: Date()
        )
        XCTAssertFalse(dataGovernanceManager.isLoading)
        
        // When
        try await dataGovernanceManager.updateRetentionPolicy(policy)
        
        // Then
        XCTAssertFalse(dataGovernanceManager.isLoading)
        // Policy should be updated without error
    }
    
    func testGetRetentionPolicies() async throws {
        // When
        let policies = try await dataGovernanceManager.getRetentionPolicies()
        
        // Then
        XCTAssertNotNil(policies)
        // Note: In this test implementation, policies list is empty
    }
    
    func testApplyRetentionPolicy() async throws {
        // Given
        let policyId = UUID()
        let dataId = UUID()
        XCTAssertFalse(dataGovernanceManager.isLoading)
        
        // When
        try await dataGovernanceManager.applyRetentionPolicy(policyId, to: dataId)
        
        // Then
        XCTAssertFalse(dataGovernanceManager.isLoading)
        // Policy should be applied without error
    }
    
    func testDeleteData() async throws {
        // Given
        let dataId = UUID()
        XCTAssertFalse(dataGovernanceManager.isLoading)
        
        // When
        try await dataGovernanceManager.deleteData(dataId)
        
        // Then
        XCTAssertFalse(dataGovernanceManager.isLoading)
        // Data should be deleted without error
    }
    
    func testScheduleDataDeletion() async throws {
        // Given
        let dataId = UUID()
        let deletionDate = Date().addingTimeInterval(30 * 24 * 3600)
        XCTAssertFalse(dataGovernanceManager.isLoading)
        
        // When
        try await dataGovernanceManager.scheduleDataDeletion(dataId, at: deletionDate)
        
        // Then
        XCTAssertFalse(dataGovernanceManager.isLoading)
        // Deletion should be scheduled without error
    }
    
    func testGetScheduledDeletions() async throws {
        // When
        let deletions = try await dataGovernanceManager.getScheduledDeletions()
        
        // Then
        XCTAssertNotNil(deletions)
        // Note: In this test implementation, deletions list is empty
    }
    
    func testCancelScheduledDeletion() async throws {
        // Given
        let deletionId = UUID()
        XCTAssertFalse(dataGovernanceManager.isLoading)
        
        // When
        try await dataGovernanceManager.cancelScheduledDeletion(deletionId)
        
        // Then
        XCTAssertFalse(dataGovernanceManager.isLoading)
        // Deletion should be cancelled without error
    }
    
    // MARK: - Data Lineage & Provenance Tests
    
    func testTrackDataLineage() async throws {
        // Given
        let lineage = DataLineageRecord(
            id: UUID(),
            dataId: UUID(),
            operation: .created,
            source: "user_input",
            destination: nil,
            timestamp: Date(),
            userId: UUID(),
            metadata: [:]
        )
        XCTAssertFalse(dataGovernanceManager.isLoading)
        
        // When
        try await dataGovernanceManager.trackDataLineage(lineage)
        
        // Then
        XCTAssertFalse(dataGovernanceManager.isLoading)
        // Lineage should be tracked without error
    }
    
    func testGetDataLineage() async throws {
        // Given
        let dataId = UUID()
        
        // When
        let lineage = try await dataGovernanceManager.getDataLineage(for: dataId)
        
        // Then
        XCTAssertNotNil(lineage)
        // Note: In this test implementation, lineage list is empty
    }
    
    func testGetDataProvenance() async throws {
        // Given
        let dataId = UUID()
        
        // When
        let provenance = try await dataGovernanceManager.getDataProvenance(for: dataId)
        
        // Then
        XCTAssertEqual(provenance.dataId, dataId)
        XCTAssertEqual(provenance.origin, "user_input")
        XCTAssertNotNil(provenance.creationDate)
        XCTAssertNotNil(provenance.lineage)
        XCTAssertNotNil(provenance.transformations)
    }
    
    func testExportLineageReport() async throws {
        // When
        let jsonData = try await dataGovernanceManager.exportLineageReport(format: .json)
        let csvData = try await dataGovernanceManager.exportLineageReport(format: .csv)
        let xmlData = try await dataGovernanceManager.exportLineageReport(format: .xml)
        
        // Then
        XCTAssertNotNil(jsonData)
        XCTAssertNotNil(csvData)
        XCTAssertNotNil(xmlData)
    }
    
    // MARK: - Privacy Impact Assessments Tests
    
    func testCreatePrivacyAssessment() async throws {
        // Given
        let assessment = PrivacyImpactAssessment(
            id: UUID(),
            title: "Health Data Processing Assessment",
            description: "Assessment for health data processing",
            riskLevel: .medium,
            dataTypes: [.healthData],
            processingPurposes: ["analytics", "research"],
            dataSubjects: ["patients"],
            retentionPeriod: 365 * 24 * 3600,
            securityMeasures: ["encryption", "access_control"],
            status: .draft,
            createdBy: UUID(),
            createdAt: Date(),
            approvedAt: nil,
            approvedBy: nil,
            rejectedAt: nil,
            rejectionReason: nil
        )
        XCTAssertFalse(dataGovernanceManager.isLoading)
        
        // When
        try await dataGovernanceManager.createPrivacyAssessment(assessment)
        
        // Then
        XCTAssertFalse(dataGovernanceManager.isLoading)
        // Assessment should be created without error
    }
    
    func testUpdatePrivacyAssessment() async throws {
        // Given
        let assessment = PrivacyImpactAssessment(
            id: UUID(),
            title: "Updated Assessment",
            description: "Updated assessment description",
            riskLevel: .low,
            dataTypes: [.userProfile],
            processingPurposes: ["analytics"],
            dataSubjects: ["users"],
            retentionPeriod: 180 * 24 * 3600,
            securityMeasures: ["encryption"],
            status: .submitted,
            createdBy: UUID(),
            createdAt: Date(),
            approvedAt: nil,
            approvedBy: nil,
            rejectedAt: nil,
            rejectionReason: nil
        )
        XCTAssertFalse(dataGovernanceManager.isLoading)
        
        // When
        try await dataGovernanceManager.updatePrivacyAssessment(assessment)
        
        // Then
        XCTAssertFalse(dataGovernanceManager.isLoading)
        // Assessment should be updated without error
    }
    
    func testGetPrivacyAssessments() async throws {
        // When
        let assessments = try await dataGovernanceManager.getPrivacyAssessments()
        
        // Then
        XCTAssertNotNil(assessments)
        // Note: In this test implementation, assessments list is empty
    }
    
    func testGetPrivacyAssessment() async throws {
        // Given
        let assessmentId = UUID()
        
        // When
        let assessment = try await dataGovernanceManager.getPrivacyAssessment(assessmentId)
        
        // Then
        XCTAssertEqual(assessment.id, assessmentId)
        XCTAssertEqual(assessment.title, "Test Assessment")
        XCTAssertEqual(assessment.description, "A test privacy impact assessment")
        XCTAssertEqual(assessment.riskLevel, .medium)
        XCTAssertEqual(assessment.dataTypes.count, 1)
        XCTAssertEqual(assessment.processingPurposes.count, 1)
        XCTAssertEqual(assessment.dataSubjects.count, 1)
        XCTAssertEqual(assessment.retentionPeriod, 365 * 24 * 3600)
        XCTAssertEqual(assessment.securityMeasures.count, 1)
        XCTAssertEqual(assessment.status, .draft)
        XCTAssertNotNil(assessment.createdBy)
        XCTAssertNotNil(assessment.createdAt)
    }
    
    func testApprovePrivacyAssessment() async throws {
        // Given
        let assessmentId = UUID()
        XCTAssertFalse(dataGovernanceManager.isLoading)
        
        // When
        try await dataGovernanceManager.approvePrivacyAssessment(assessmentId)
        
        // Then
        XCTAssertFalse(dataGovernanceManager.isLoading)
        // Assessment should be approved without error
    }
    
    func testRejectPrivacyAssessment() async throws {
        // Given
        let assessmentId = UUID()
        let reason = "Insufficient security measures"
        XCTAssertFalse(dataGovernanceManager.isLoading)
        
        // When
        try await dataGovernanceManager.rejectPrivacyAssessment(assessmentId, reason: reason)
        
        // Then
        XCTAssertFalse(dataGovernanceManager.isLoading)
        // Assessment should be rejected without error
    }
    
    // MARK: - GDPR & CCPA Compliance Tests
    
    func testGenerateDataSubjectRequest() async throws {
        // Given
        let request = DataSubjectRequest(
            id: UUID(),
            userId: UUID(),
            type: .access,
            description: "Request for data access",
            status: .pending,
            submittedAt: Date(),
            processedAt: nil,
            response: nil
        )
        XCTAssertFalse(dataGovernanceManager.isLoading)
        
        // When
        let response = try await dataGovernanceManager.generateDataSubjectRequest(request)
        
        // Then
        XCTAssertEqual(response.request.id, request.id)
        XCTAssertEqual(response.message, "Request processed successfully")
        XCTAssertNotNil(response.completedAt)
        XCTAssertFalse(dataGovernanceManager.isLoading)
    }
    
    func testProcessDataSubjectRequest() async throws {
        // Given
        let requestId = UUID()
        XCTAssertFalse(dataGovernanceManager.isLoading)
        
        // When
        try await dataGovernanceManager.processDataSubjectRequest(requestId)
        
        // Then
        XCTAssertFalse(dataGovernanceManager.isLoading)
        // Request should be processed without error
    }
    
    func testGetDataSubjectRequests() async throws {
        // Given
        let userId = UUID()
        
        // When
        let requests = try await dataGovernanceManager.getDataSubjectRequests(for: userId)
        
        // Then
        XCTAssertNotNil(requests)
        // Note: In this test implementation, requests list is empty
    }
    
    func testExportUserData() async throws {
        // Given
        let userId = UUID()
        
        // When
        let data = try await dataGovernanceManager.exportUserData(for: userId)
        
        // Then
        XCTAssertNotNil(data)
    }
    
    func testDeleteUserData() async throws {
        // Given
        let userId = UUID()
        XCTAssertFalse(dataGovernanceManager.isLoading)
        
        // When
        try await dataGovernanceManager.deleteUserData(for: userId)
        
        // Then
        XCTAssertFalse(dataGovernanceManager.isLoading)
        // User data should be deleted without error
    }
    
    func testRunComplianceCheck() async throws {
        // Given
        XCTAssertFalse(dataGovernanceManager.isLoading)
        
        // When
        let report = try await dataGovernanceManager.runComplianceCheck()
        
        // Then
        XCTAssertEqual(report.overallStatus, .compliant)
        XCTAssertTrue(report.gdprCompliant)
        XCTAssertTrue(report.ccpaCompliant)
        XCTAssertNotNil(report.issues)
        XCTAssertNotNil(report.recommendations)
        XCTAssertNotNil(report.generatedAt)
        XCTAssertFalse(dataGovernanceManager.isLoading)
    }
    
    func testGetComplianceStatus() async throws {
        // When
        let status = try await dataGovernanceManager.getComplianceStatus()
        
        // Then
        XCTAssertEqual(status, .compliant)
    }
    
    // MARK: - Privacy Monitoring Tests
    
    func testStartPrivacyMonitoring() {
        // Given
        XCTAssertFalse(dataGovernanceManager.isMonitoring)
        
        // When
        dataGovernanceManager.startPrivacyMonitoring()
        
        // Then
        XCTAssertTrue(dataGovernanceManager.isMonitoring)
    }
    
    func testStopPrivacyMonitoring() {
        // Given
        dataGovernanceManager.startPrivacyMonitoring()
        XCTAssertTrue(dataGovernanceManager.isMonitoring)
        
        // When
        dataGovernanceManager.stopPrivacyMonitoring()
        
        // Then
        XCTAssertFalse(dataGovernanceManager.isMonitoring)
    }
    
    func testGetPrivacyMetrics() async throws {
        // When
        let metrics = try await dataGovernanceManager.getPrivacyMetrics()
        
        // Then
        XCTAssertEqual(metrics.totalUsers, 1000)
        XCTAssertEqual(metrics.activeConsents, 950)
        XCTAssertEqual(metrics.dataBreaches, 0)
        XCTAssertEqual(metrics.pendingDeletions, 5)
        XCTAssertEqual(metrics.complianceScore, 95.0)
        XCTAssertNotNil(metrics.lastUpdated)
    }
    
    func testGetPrivacyMetricsHistory() async throws {
        // When
        let metrics = try await dataGovernanceManager.getPrivacyMetrics(timeRange: .lastDay)
        
        // Then
        XCTAssertNotNil(metrics)
        // Note: In this test implementation, metrics list is empty
    }
    
    // MARK: - Published Properties Tests
    
    func testPublishedProperties() {
        // Given
        let expectation = XCTestExpectation(description: "Published properties updated")
        
        // When
        dataGovernanceManager.$dataClassifications
            .dropFirst()
            .sink { _ in
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // Trigger classification update
        Task {
            let testData = "Test".data(using: .utf8)!
            _ = try? await dataGovernanceManager.classifyData(testData, type: .userProfile)
        }
        
        // Then
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testConsentRecordsPublishedProperty() async throws {
        // Given
        let expectation = XCTestExpectation(description: "Consent records updated")
        
        dataGovernanceManager.$consentRecords
            .dropFirst()
            .sink { _ in
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // When
        let consent = ConsentRecord(
            id: UUID(),
            userId: UUID(),
            type: .dataProcessing,
            isGranted: true,
            grantedAt: Date(),
            revokedAt: nil,
            expiresAt: nil,
            metadata: [:]
        )
        try await dataGovernanceManager.recordConsent(consent)
        
        // Then
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testRetentionPoliciesPublishedProperty() async throws {
        // Given
        let expectation = XCTestExpectation(description: "Retention policies updated")
        
        dataGovernanceManager.$retentionPolicies
            .dropFirst()
            .sink { _ in
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // When
        let policy = RetentionPolicy(
            id: UUID(),
            name: "Test Policy",
            description: "Test retention policy",
            retentionPeriod: 365 * 24 * 3600,
            dataTypes: [.userProfile],
            isActive: true,
            createdAt: Date(),
            updatedAt: Date()
        )
        try await dataGovernanceManager.createRetentionPolicy(policy)
        
        // Then
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testDataLineagePublishedProperty() async throws {
        // Given
        let expectation = XCTestExpectation(description: "Data lineage updated")
        
        dataGovernanceManager.$dataLineage
            .dropFirst()
            .sink { _ in
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // When
        let lineage = DataLineageRecord(
            id: UUID(),
            dataId: UUID(),
            operation: .created,
            source: "test",
            destination: nil,
            timestamp: Date(),
            userId: nil,
            metadata: [:]
        )
        try await dataGovernanceManager.trackDataLineage(lineage)
        
        // Then
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testPrivacyAssessmentsPublishedProperty() async throws {
        // Given
        let expectation = XCTestExpectation(description: "Privacy assessments updated")
        
        dataGovernanceManager.$privacyAssessments
            .dropFirst()
            .sink { _ in
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // When
        let assessment = PrivacyImpactAssessment(
            id: UUID(),
            title: "Test Assessment",
            description: "Test assessment",
            riskLevel: .low,
            dataTypes: [.userProfile],
            processingPurposes: ["test"],
            dataSubjects: ["users"],
            retentionPeriod: 365 * 24 * 3600,
            securityMeasures: ["encryption"],
            status: .draft,
            createdBy: UUID(),
            createdAt: Date(),
            approvedAt: nil,
            approvedBy: nil,
            rejectedAt: nil,
            rejectionReason: nil
        )
        try await dataGovernanceManager.createPrivacyAssessment(assessment)
        
        // Then
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testComplianceStatusPublishedProperty() async throws {
        // Given
        let expectation = XCTestExpectation(description: "Compliance status updated")
        
        dataGovernanceManager.$complianceStatus
            .dropFirst()
            .sink { _ in
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // When
        _ = try await dataGovernanceManager.getComplianceStatus()
        
        // Then
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testLoadingState() async throws {
        // Given
        let expectation = XCTestExpectation(description: "Loading state changes")
        var loadingStates: [Bool] = []
        
        dataGovernanceManager.$isLoading
            .sink { loading in
                loadingStates.append(loading)
                if loadingStates.count >= 2 {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When
        let testData = "Test".data(using: .utf8)!
        _ = try await dataGovernanceManager.classifyData(testData, type: .userProfile)
        
        // Then
        wait(for: [expectation], timeout: 5.0)
        XCTAssertTrue(loadingStates.contains(true))
        XCTAssertTrue(loadingStates.contains(false))
    }
    
    func testErrorHandling() async throws {
        // Given
        let expectation = XCTestExpectation(description: "Error state updated")
        
        dataGovernanceManager.$error
            .dropFirst()
            .sink { error in
                if error != nil {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When
        // Trigger an operation that might fail
        do {
            let testData = "Test".data(using: .utf8)!
            _ = try await dataGovernanceManager.classifyData(testData, type: .userProfile)
        } catch {
            // Expected behavior
        }
        
        // Then
        wait(for: [expectation], timeout: 5.0)
    }
    
    // MARK: - Model Validation Tests
    
    func testDataClassificationValidation() {
        // Given
        let classification = DataClassification(
            id: UUID(),
            dataId: UUID(),
            level: .confidential,
            sensitivity: .high,
            labels: [],
            classifiedAt: Date(),
            classifiedBy: UUID(),
            metadata: ["source": "user_input"]
        )
        
        // Then
        XCTAssertNotNil(classification.id)
        XCTAssertNotNil(classification.dataId)
        XCTAssertEqual(classification.level, .confidential)
        XCTAssertEqual(classification.sensitivity, .high)
        XCTAssertNotNil(classification.labels)
        XCTAssertNotNil(classification.classifiedAt)
        XCTAssertNotNil(classification.classifiedBy)
        XCTAssertEqual(classification.metadata["source"], "user_input")
    }
    
    func testConsentRecordValidation() {
        // Given
        let consent = ConsentRecord(
            id: UUID(),
            userId: UUID(),
            type: .dataProcessing,
            isGranted: true,
            grantedAt: Date(),
            revokedAt: nil,
            expiresAt: Date().addingTimeInterval(365 * 24 * 3600),
            metadata: ["purpose": "analytics"]
        )
        
        // Then
        XCTAssertNotNil(consent.id)
        XCTAssertNotNil(consent.userId)
        XCTAssertEqual(consent.type, .dataProcessing)
        XCTAssertTrue(consent.isGranted)
        XCTAssertNotNil(consent.grantedAt)
        XCTAssertNil(consent.revokedAt)
        XCTAssertNotNil(consent.expiresAt)
        XCTAssertEqual(consent.metadata["purpose"], "analytics")
    }
    
    func testRetentionPolicyValidation() {
        // Given
        let policy = RetentionPolicy(
            id: UUID(),
            name: "User Data Policy",
            description: "Retention policy for user data",
            retentionPeriod: 365 * 24 * 3600,
            dataTypes: [.userProfile, .healthData],
            isActive: true,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        // Then
        XCTAssertNotNil(policy.id)
        XCTAssertEqual(policy.name, "User Data Policy")
        XCTAssertEqual(policy.description, "Retention policy for user data")
        XCTAssertEqual(policy.retentionPeriod, 365 * 24 * 3600)
        XCTAssertEqual(policy.dataTypes.count, 2)
        XCTAssertTrue(policy.isActive)
        XCTAssertNotNil(policy.createdAt)
        XCTAssertNotNil(policy.updatedAt)
    }
    
    func testDataLineageRecordValidation() {
        // Given
        let lineage = DataLineageRecord(
            id: UUID(),
            dataId: UUID(),
            operation: .modified,
            source: "user_input",
            destination: "database",
            timestamp: Date(),
            userId: UUID(),
            metadata: ["reason": "update"]
        )
        
        // Then
        XCTAssertNotNil(lineage.id)
        XCTAssertNotNil(lineage.dataId)
        XCTAssertEqual(lineage.operation, .modified)
        XCTAssertEqual(lineage.source, "user_input")
        XCTAssertEqual(lineage.destination, "database")
        XCTAssertNotNil(lineage.timestamp)
        XCTAssertNotNil(lineage.userId)
        XCTAssertEqual(lineage.metadata["reason"], "update")
    }
    
    func testPrivacyImpactAssessmentValidation() {
        // Given
        let assessment = PrivacyImpactAssessment(
            id: UUID(),
            title: "Health Data Assessment",
            description: "Assessment for health data processing",
            riskLevel: .medium,
            dataTypes: [.healthData],
            processingPurposes: ["analytics"],
            dataSubjects: ["patients"],
            retentionPeriod: 365 * 24 * 3600,
            securityMeasures: ["encryption"],
            status: .draft,
            createdBy: UUID(),
            createdAt: Date(),
            approvedAt: nil,
            approvedBy: nil,
            rejectedAt: nil,
            rejectionReason: nil
        )
        
        // Then
        XCTAssertNotNil(assessment.id)
        XCTAssertEqual(assessment.title, "Health Data Assessment")
        XCTAssertEqual(assessment.description, "Assessment for health data processing")
        XCTAssertEqual(assessment.riskLevel, .medium)
        XCTAssertEqual(assessment.dataTypes.count, 1)
        XCTAssertEqual(assessment.processingPurposes.count, 1)
        XCTAssertEqual(assessment.dataSubjects.count, 1)
        XCTAssertEqual(assessment.retentionPeriod, 365 * 24 * 3600)
        XCTAssertEqual(assessment.securityMeasures.count, 1)
        XCTAssertEqual(assessment.status, .draft)
        XCTAssertNotNil(assessment.createdBy)
        XCTAssertNotNil(assessment.createdAt)
        XCTAssertNil(assessment.approvedAt)
        XCTAssertNil(assessment.approvedBy)
        XCTAssertNil(assessment.rejectedAt)
        XCTAssertNil(assessment.rejectionReason)
    }
    
    func testDataSubjectRequestValidation() {
        // Given
        let request = DataSubjectRequest(
            id: UUID(),
            userId: UUID(),
            type: .access,
            description: "Request for data access",
            status: .pending,
            submittedAt: Date(),
            processedAt: nil,
            response: nil
        )
        
        // Then
        XCTAssertNotNil(request.id)
        XCTAssertNotNil(request.userId)
        XCTAssertEqual(request.type, .access)
        XCTAssertEqual(request.description, "Request for data access")
        XCTAssertEqual(request.status, .pending)
        XCTAssertNotNil(request.submittedAt)
        XCTAssertNil(request.processedAt)
        XCTAssertNil(request.response)
    }
    
    func testPrivacyComplianceReportValidation() {
        // Given
        let issue = ComplianceIssue(
            id: UUID(),
            type: .consentMissing,
            severity: .medium,
            description: "Missing consent for data processing",
            remediation: "Obtain user consent"
        )
        
        let report = PrivacyComplianceReport(
            id: UUID(),
            overallStatus: .compliant,
            gdprCompliant: true,
            ccpaCompliant: true,
            issues: [issue],
            recommendations: ["Implement consent management"],
            generatedAt: Date()
        )
        
        // Then
        XCTAssertNotNil(report.id)
        XCTAssertEqual(report.overallStatus, .compliant)
        XCTAssertTrue(report.gdprCompliant)
        XCTAssertTrue(report.ccpaCompliant)
        XCTAssertEqual(report.issues.count, 1)
        XCTAssertEqual(report.recommendations.count, 1)
        XCTAssertNotNil(report.generatedAt)
        
        // Issue validation
        XCTAssertNotNil(issue.id)
        XCTAssertEqual(issue.type, .consentMissing)
        XCTAssertEqual(issue.severity, .medium)
        XCTAssertEqual(issue.description, "Missing consent for data processing")
        XCTAssertEqual(issue.remediation, "Obtain user consent")
    }
    
    func testPrivacyMetricsValidation() {
        // Given
        let metrics = PrivacyMetrics(
            totalUsers: 1000,
            activeConsents: 950,
            dataBreaches: 0,
            pendingDeletions: 5,
            complianceScore: 95.0,
            lastUpdated: Date()
        )
        
        // Then
        XCTAssertEqual(metrics.totalUsers, 1000)
        XCTAssertEqual(metrics.activeConsents, 950)
        XCTAssertEqual(metrics.dataBreaches, 0)
        XCTAssertEqual(metrics.pendingDeletions, 5)
        XCTAssertEqual(metrics.complianceScore, 95.0)
        XCTAssertNotNil(metrics.lastUpdated)
    }
    
    func testDataLabelValidation() {
        // Given
        let label = DataLabel(
            id: UUID(),
            name: "Personal Data",
            category: .personal,
            description: "Contains personal information",
            isSystem: true,
            createdAt: Date()
        )
        
        // Then
        XCTAssertNotNil(label.id)
        XCTAssertEqual(label.name, "Personal Data")
        XCTAssertEqual(label.category, .personal)
        XCTAssertEqual(label.description, "Contains personal information")
        XCTAssertTrue(label.isSystem)
        XCTAssertNotNil(label.createdAt)
    }
    
    func testScheduledDeletionValidation() {
        // Given
        let deletion = ScheduledDeletion(
            id: UUID(),
            dataId: UUID(),
            scheduledDate: Date().addingTimeInterval(30 * 24 * 3600),
            reason: "Retention period expired",
            isCancelled: false,
            cancelledAt: nil
        )
        
        // Then
        XCTAssertNotNil(deletion.id)
        XCTAssertNotNil(deletion.dataId)
        XCTAssertNotNil(deletion.scheduledDate)
        XCTAssertEqual(deletion.reason, "Retention period expired")
        XCTAssertFalse(deletion.isCancelled)
        XCTAssertNil(deletion.cancelledAt)
    }
    
    func testDataProvenanceValidation() {
        // Given
        let provenance = DataProvenance(
            dataId: UUID(),
            origin: "user_input",
            creationDate: Date(),
            lineage: [],
            transformations: ["encryption", "anonymization"]
        )
        
        // Then
        XCTAssertNotNil(provenance.dataId)
        XCTAssertEqual(provenance.origin, "user_input")
        XCTAssertNotNil(provenance.creationDate)
        XCTAssertNotNil(provenance.lineage)
        XCTAssertEqual(provenance.transformations.count, 2)
    }
}

// MARK: - Supporting Extensions

extension TimeRange {
    static let lastDay = TimeRange(start: Date().addingTimeInterval(-86400), end: Date())
    static let lastWeek = TimeRange(start: Date().addingTimeInterval(-604800), end: Date())
    static let lastMonth = TimeRange(start: Date().addingTimeInterval(-2592000), end: Date())
}

struct TimeRange: Equatable {
    let start: Date
    let end: Date
} 
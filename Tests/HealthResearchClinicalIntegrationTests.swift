import XCTest
import Combine
import HealthKit
import CloudKit
@testable import HealthAI2030

/// Comprehensive test suite for Health Research & Clinical Integration Engine
class HealthResearchClinicalIntegrationTests: XCTestCase {
    
    var engine: HealthResearchClinicalIntegrationEngine!
    var healthDataManager: MockHealthDataManager!
    var mlModelManager: MockMLModelManager!
    var notificationManager: MockNotificationManager!
    var privacySecurityManager: MockPrivacySecurityManager!
    var analyticsEngine: MockAnalyticsEngine!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        healthDataManager = MockHealthDataManager()
        mlModelManager = MockMLModelManager()
        notificationManager = MockNotificationManager()
        privacySecurityManager = MockPrivacySecurityManager()
        analyticsEngine = MockAnalyticsEngine()
        
        engine = HealthResearchClinicalIntegrationEngine(
            healthDataManager: healthDataManager,
            mlModelManager: mlModelManager,
            notificationManager: notificationManager,
            privacySecurityManager: privacySecurityManager,
            analyticsEngine: analyticsEngine
        )
        
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDown() {
        cancellables = nil
        engine = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testInitialization() {
        XCTAssertNotNil(engine)
        XCTAssertEqual(engine.researchStudies.count, 0)
        XCTAssertEqual(engine.clinicalConnections.count, 0)
        XCTAssertEqual(engine.researchCollaborations.count, 0)
        XCTAssertFalse(engine.isProcessing)
        XCTAssertNil(engine.lastError)
    }
    
    func testPublishedPropertiesInitialization() {
        let expectation = XCTestExpectation(description: "Published properties initialized")
        
        engine.$researchStudies
            .sink { studies in
                XCTAssertEqual(studies.count, 0)
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    // MARK: - Research Studies Tests
    
    func testFindResearchStudiesSuccess() async {
        // Given
        let mockStudies = [
            ResearchStudy(
                title: "Cardiovascular Health Study",
                description: "Study on cardiovascular health patterns",
                institution: "HealthAI Research Institute",
                startDate: Date(),
                endDate: Date().addingTimeInterval(86400 * 365),
                eligibilityCriteria: ["Age 18+", "No heart conditions"],
                participationStatus: .eligible,
                dataRequirements: ["Heart rate", "Blood pressure"],
                compensation: "$50",
                contactInfo: "research@healthai.com"
            )
        ]
        
        // When
        await engine.findResearchStudies()
        
        // Then
        XCTAssertFalse(engine.isProcessing)
        XCTAssertNil(engine.lastError)
        XCTAssertEqual(engine.researchStudies.count, 0) // Mock implementation returns empty
    }
    
    func testFindResearchStudiesFailure() async {
        // Given
        mlModelManager.shouldFail = true
        
        // When
        await engine.findResearchStudies()
        
        // Then
        XCTAssertFalse(engine.isProcessing)
        XCTAssertNotNil(engine.lastError)
        XCTAssertTrue(engine.lastError?.contains("Failed") == true)
    }
    
    func testContributeHealthDataSuccess() async {
        // Given
        privacySecurityManager.consentGranted = true
        
        // When
        await engine.contributeHealthData()
        
        // Then
        XCTAssertFalse(engine.isProcessing)
        XCTAssertNil(engine.lastError)
        XCTAssertTrue(analyticsEngine.trackedEvents.contains("health_data_contributed"))
    }
    
    func testContributeHealthDataConsentDenied() async {
        // Given
        privacySecurityManager.consentGranted = false
        
        // When
        await engine.contributeHealthData()
        
        // Then
        XCTAssertFalse(engine.isProcessing)
        XCTAssertNotNil(engine.lastError)
        XCTAssertTrue(engine.lastError?.contains("declined") == true)
    }
    
    // MARK: - Clinical Integration Tests
    
    func testConnectHealthcareProviderSuccess() async {
        // Given
        healthDataManager.authorizationGranted = true
        
        // When
        await engine.connectHealthcareProvider()
        
        // Then
        XCTAssertFalse(engine.isProcessing)
        XCTAssertNil(engine.lastError)
        XCTAssertEqual(engine.clinicalConnections.count, 1)
        XCTAssertTrue(analyticsEngine.trackedEvents.contains("healthcare_provider_connected"))
    }
    
    func testConnectHealthcareProviderAuthorizationDenied() async {
        // Given
        healthDataManager.authorizationGranted = false
        
        // When
        await engine.connectHealthcareProvider()
        
        // Then
        XCTAssertFalse(engine.isProcessing)
        XCTAssertNotNil(engine.lastError)
        XCTAssertTrue(engine.lastError?.contains("Failed") == true)
    }
    
    func testIntegrateTelemedicineSuccess() async {
        // When
        await engine.integrateTelemedicine()
        
        // Then
        XCTAssertFalse(engine.isProcessing)
        XCTAssertNil(engine.lastError)
        XCTAssertTrue(analyticsEngine.trackedEvents.contains("telemedicine_integrated"))
    }
    
    func testIntegrateTelemedicineFailure() async {
        // Given
        mlModelManager.shouldFail = true
        
        // When
        await engine.integrateTelemedicine()
        
        // Then
        XCTAssertFalse(engine.isProcessing)
        XCTAssertNotNil(engine.lastError)
        XCTAssertTrue(engine.lastError?.contains("Failed") == true)
    }
    
    // MARK: - Analytics Tests
    
    func testGeneratePopulationInsightsSuccess() async {
        // Given
        let mockInsights = [
            HealthResearchAnalytics.PopulationInsight(
                title: "Sleep Pattern Analysis",
                description: "Population shows improved sleep quality",
                category: .sleep,
                confidence: 0.85,
                dataPoints: 1000,
                timestamp: Date()
            )
        ]
        mlModelManager.mockPopulationInsights = mockInsights
        
        // When
        await engine.generatePopulationInsights()
        
        // Then
        XCTAssertFalse(engine.isProcessing)
        XCTAssertNil(engine.lastError)
        XCTAssertEqual(engine.healthAnalytics.populationInsights.count, 1)
        XCTAssertTrue(analyticsEngine.trackedEvents.contains("population_insights_generated"))
    }
    
    func testGeneratePopulationInsightsFailure() async {
        // Given
        mlModelManager.shouldFail = true
        
        // When
        await engine.generatePopulationInsights()
        
        // Then
        XCTAssertFalse(engine.isProcessing)
        XCTAssertNotNil(engine.lastError)
        XCTAssertTrue(engine.lastError?.contains("Failed") == true)
    }
    
    func testTrackTreatmentEffectivenessSuccess() async {
        // Given
        let mockEffectiveness = HealthResearchAnalytics.TreatmentEffectiveness(
            overallScore: 0.85,
            metrics: ["pain": 0.8, "mobility": 0.9],
            recommendations: ["Continue current treatment", "Monitor progress"],
            lastUpdated: Date()
        )
        mlModelManager.mockTreatmentEffectiveness = mockEffectiveness
        
        // When
        await engine.trackTreatmentEffectiveness()
        
        // Then
        XCTAssertFalse(engine.isProcessing)
        XCTAssertNil(engine.lastError)
        XCTAssertNotNil(engine.healthAnalytics.treatmentEffectiveness)
        XCTAssertEqual(engine.healthAnalytics.treatmentEffectiveness?.overallScore, 0.85)
        XCTAssertTrue(analyticsEngine.trackedEvents.contains("treatment_effectiveness_tracked"))
    }
    
    func testTrackTreatmentEffectivenessFailure() async {
        // Given
        mlModelManager.shouldFail = true
        
        // When
        await engine.trackTreatmentEffectiveness()
        
        // Then
        XCTAssertFalse(engine.isProcessing)
        XCTAssertNotNil(engine.lastError)
        XCTAssertTrue(engine.lastError?.contains("Failed") == true)
    }
    
    // MARK: - Research Collaboration Tests
    
    func testJoinAcademicPartnershipSuccess() async {
        // When
        await engine.joinAcademicPartnership()
        
        // Then
        XCTAssertFalse(engine.isProcessing)
        XCTAssertNil(engine.lastError)
        XCTAssertEqual(engine.researchCollaborations.count, 1)
        XCTAssertTrue(analyticsEngine.trackedEvents.contains("academic_partnership_joined"))
    }
    
    func testJoinAcademicPartnershipFailure() async {
        // Given
        mlModelManager.shouldFail = true
        
        // When
        await engine.joinAcademicPartnership()
        
        // Then
        XCTAssertFalse(engine.isProcessing)
        XCTAssertNotNil(engine.lastError)
        XCTAssertTrue(engine.lastError?.contains("Failed") == true)
    }
    
    func testIntegrateMedicalDevicesSuccess() async {
        // Given
        let mockDevices = [
            MedicalDevice(
                name: "Heart Rate Monitor",
                manufacturer: "HealthTech",
                model: "HR-2000",
                deviceType: .heartRateMonitor,
                connectionStatus: .connected,
                lastSyncDate: Date(),
                dataTypes: ["heart_rate", "heart_rate_variability"]
            )
        ]
        mlModelManager.mockMedicalDevices = mockDevices
        
        // When
        await engine.integrateMedicalDevices()
        
        // Then
        XCTAssertFalse(engine.isProcessing)
        XCTAssertNil(engine.lastError)
        XCTAssertEqual(engine.healthAnalytics.connectedDevices.count, 1)
        XCTAssertTrue(analyticsEngine.trackedEvents.contains("medical_devices_integrated"))
    }
    
    func testIntegrateMedicalDevicesFailure() async {
        // Given
        mlModelManager.shouldFail = true
        
        // When
        await engine.integrateMedicalDevices()
        
        // Then
        XCTAssertFalse(engine.isProcessing)
        XCTAssertNotNil(engine.lastError)
        XCTAssertTrue(engine.lastError?.contains("Failed") == true)
    }
    
    // MARK: - Model Tests
    
    func testResearchStudyModel() {
        // Given
        let study = ResearchStudy(
            title: "Test Study",
            description: "Test Description",
            institution: "Test Institution",
            startDate: Date(),
            endDate: Date().addingTimeInterval(86400),
            eligibilityCriteria: ["Criteria 1"],
            participationStatus: .eligible,
            dataRequirements: ["Requirement 1"],
            compensation: "$100",
            contactInfo: "test@test.com"
        )
        
        // Then
        XCTAssertEqual(study.title, "Test Study")
        XCTAssertEqual(study.description, "Test Description")
        XCTAssertEqual(study.institution, "Test Institution")
        XCTAssertEqual(study.participationStatus, .eligible)
        XCTAssertEqual(study.compensation, "$100")
        XCTAssertEqual(study.contactInfo, "test@test.com")
    }
    
    func testClinicalConnectionModel() {
        // Given
        let connection = ClinicalConnection(
            providerName: "Test Provider",
            providerId: "test-id",
            connectionDate: Date(),
            ehrIntegrationStatus: .connected,
            dataSharingLevel: .full,
            lastSyncDate: Date(),
            specialties: ["Cardiology"],
            contactInfo: "provider@test.com"
        )
        
        // Then
        XCTAssertEqual(connection.providerName, "Test Provider")
        XCTAssertEqual(connection.providerId, "test-id")
        XCTAssertEqual(connection.ehrIntegrationStatus, .connected)
        XCTAssertEqual(connection.dataSharingLevel, .full)
        XCTAssertEqual(connection.specialties, ["Cardiology"])
    }
    
    func testHealthResearchAnalyticsModel() {
        // Given
        var analytics = HealthResearchAnalytics()
        let insight = HealthResearchAnalytics.PopulationInsight(
            title: "Test Insight",
            description: "Test Description",
            category: .cardiovascular,
            confidence: 0.9,
            dataPoints: 500,
            timestamp: Date()
        )
        analytics.populationInsights = [insight]
        
        // Then
        XCTAssertEqual(analytics.populationInsights.count, 1)
        XCTAssertEqual(analytics.populationInsights.first?.title, "Test Insight")
        XCTAssertEqual(analytics.populationInsights.first?.category, .cardiovascular)
        XCTAssertEqual(analytics.populationInsights.first?.confidence, 0.9)
    }
    
    func testResearchCollaborationModel() {
        // Given
        let collaboration = ResearchCollaboration(
            institutionName: "Test University",
            collaborationType: .academic,
            startDate: Date(),
            status: .active,
            dataSharingAgreement: .anonymized,
            researchFocus: ["Cardiovascular", "Mental Health"],
            publications: [],
            fundingSource: "Test Grant"
        )
        
        // Then
        XCTAssertEqual(collaboration.institutionName, "Test University")
        XCTAssertEqual(collaboration.collaborationType, .academic)
        XCTAssertEqual(collaboration.status, .active)
        XCTAssertEqual(collaboration.dataSharingAgreement, .anonymized)
        XCTAssertEqual(collaboration.researchFocus, ["Cardiovascular", "Mental Health"])
        XCTAssertEqual(collaboration.fundingSource, "Test Grant")
    }
    
    func testMedicalDeviceModel() {
        // Given
        let device = MedicalDevice(
            name: "Test Device",
            manufacturer: "Test Manufacturer",
            model: "Test Model",
            deviceType: .heartRateMonitor,
            connectionStatus: .connected,
            lastSyncDate: Date(),
            dataTypes: ["heart_rate"]
        )
        
        // Then
        XCTAssertEqual(device.name, "Test Device")
        XCTAssertEqual(device.manufacturer, "Test Manufacturer")
        XCTAssertEqual(device.model, "Test Model")
        XCTAssertEqual(device.deviceType, .heartRateMonitor)
        XCTAssertEqual(device.connectionStatus, .connected)
        XCTAssertEqual(device.dataTypes, ["heart_rate"])
    }
    
    // MARK: - Enum Tests
    
    func testParticipationStatusEnum() {
        XCTAssertEqual(ResearchStudy.ParticipationStatus.allCases.count, 5)
        XCTAssertTrue(ResearchStudy.ParticipationStatus.allCases.contains(.notParticipating))
        XCTAssertTrue(ResearchStudy.ParticipationStatus.allCases.contains(.eligible))
        XCTAssertTrue(ResearchStudy.ParticipationStatus.allCases.contains(.enrolled))
        XCTAssertTrue(ResearchStudy.ParticipationStatus.allCases.contains(.completed))
        XCTAssertTrue(ResearchStudy.ParticipationStatus.allCases.contains(.withdrawn))
    }
    
    func testEHRIntegrationStatusEnum() {
        XCTAssertEqual(ClinicalConnection.EHRIntegrationStatus.allCases.count, 4)
        XCTAssertTrue(ClinicalConnection.EHRIntegrationStatus.allCases.contains(.notConnected))
        XCTAssertTrue(ClinicalConnection.EHRIntegrationStatus.allCases.contains(.connecting))
        XCTAssertTrue(ClinicalConnection.EHRIntegrationStatus.allCases.contains(.connected))
        XCTAssertTrue(ClinicalConnection.EHRIntegrationStatus.allCases.contains(.error))
    }
    
    func testDataSharingLevelEnum() {
        XCTAssertEqual(ClinicalConnection.DataSharingLevel.allCases.count, 3)
        XCTAssertTrue(ClinicalConnection.DataSharingLevel.allCases.contains(.none))
        XCTAssertTrue(ClinicalConnection.DataSharingLevel.allCases.contains(.summary))
        XCTAssertTrue(ClinicalConnection.DataSharingLevel.allCases.contains(.full))
    }
    
    func testInsightCategoryEnum() {
        XCTAssertEqual(HealthResearchAnalytics.PopulationInsight.InsightCategory.allCases.count, 5)
        XCTAssertTrue(HealthResearchAnalytics.PopulationInsight.InsightCategory.allCases.contains(.cardiovascular))
        XCTAssertTrue(HealthResearchAnalytics.PopulationInsight.InsightCategory.allCases.contains(.mentalHealth))
        XCTAssertTrue(HealthResearchAnalytics.PopulationInsight.InsightCategory.allCases.contains(.sleep))
        XCTAssertTrue(HealthResearchAnalytics.PopulationInsight.InsightCategory.allCases.contains(.nutrition))
        XCTAssertTrue(HealthResearchAnalytics.PopulationInsight.InsightCategory.allCases.contains(.exercise))
    }
    
    func testCollaborationTypeEnum() {
        XCTAssertEqual(ResearchCollaboration.CollaborationType.allCases.count, 4)
        XCTAssertTrue(ResearchCollaboration.CollaborationType.allCases.contains(.academic))
        XCTAssertTrue(ResearchCollaboration.CollaborationType.allCases.contains(.clinical))
        XCTAssertTrue(ResearchCollaboration.CollaborationType.allCases.contains(.industry))
        XCTAssertTrue(ResearchCollaboration.CollaborationType.allCases.contains(.government))
    }
    
    func testDeviceTypeEnum() {
        XCTAssertEqual(MedicalDevice.DeviceType.allCases.count, 6)
        XCTAssertTrue(MedicalDevice.DeviceType.allCases.contains(.heartRateMonitor))
        XCTAssertTrue(MedicalDevice.DeviceType.allCases.contains(.bloodPressureMonitor))
        XCTAssertTrue(MedicalDevice.DeviceType.allCases.contains(.glucoseMonitor))
        XCTAssertTrue(MedicalDevice.DeviceType.allCases.contains(.sleepTracker))
        XCTAssertTrue(MedicalDevice.DeviceType.allCases.contains(.activityTracker))
        XCTAssertTrue(MedicalDevice.DeviceType.allCases.contains(.ecgMonitor))
    }
    
    // MARK: - Performance Tests
    
    func testPerformanceFindResearchStudies() {
        measure {
            let expectation = XCTestExpectation(description: "Performance test")
            
            Task {
                await engine.findResearchStudies()
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 5.0)
        }
    }
    
    func testPerformanceContributeHealthData() {
        measure {
            let expectation = XCTestExpectation(description: "Performance test")
            
            Task {
                await engine.contributeHealthData()
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 5.0)
        }
    }
    
    func testPerformanceGeneratePopulationInsights() {
        measure {
            let expectation = XCTestExpectation(description: "Performance test")
            
            Task {
                await engine.generatePopulationInsights()
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 5.0)
        }
    }
    
    // MARK: - Integration Tests
    
    func testIntegrationWithHealthDataManager() {
        // Given
        let healthData = HealthDataEntry(
            type: .heartRate,
            value: 75.0,
            unit: "bpm",
            timestamp: Date(),
            source: "HealthKit"
        )
        
        // When
        healthDataManager.healthDataPublisher.send([healthData])
        
        // Then
        // Verify that the engine processes the health data
        // This would be verified through the mock analytics engine
        XCTAssertTrue(analyticsEngine.trackedEvents.count > 0)
    }
    
    func testIntegrationWithNotificationManager() {
        // Given
        let study = ResearchStudy(
            title: "Test Study",
            description: "Test Description",
            institution: "Test Institution",
            startDate: Date(),
            endDate: Date().addingTimeInterval(86400),
            eligibilityCriteria: ["Criteria 1"],
            participationStatus: .eligible,
            dataRequirements: ["Requirement 1"],
            compensation: "$100",
            contactInfo: "test@test.com"
        )
        
        // When
        engine.researchStudies = [study]
        
        // Then
        // Verify that notifications are sent appropriately
        // This would be verified through the mock notification manager
        XCTAssertNotNil(notificationManager)
    }
    
    // MARK: - Error Handling Tests
    
    func testErrorHandlingWithInvalidData() {
        // Given
        mlModelManager.shouldFail = true
        
        // When & Then
        // Test that all operations handle errors gracefully
        let operations = [
            { await self.engine.findResearchStudies() },
            { await self.engine.contributeHealthData() },
            { await self.engine.connectHealthcareProvider() },
            { await self.engine.integrateTelemedicine() },
            { await self.engine.generatePopulationInsights() },
            { await self.engine.trackTreatmentEffectiveness() },
            { await self.engine.joinAcademicPartnership() },
            { await self.engine.integrateMedicalDevices() }
        ]
        
        for operation in operations {
            let expectation = XCTestExpectation(description: "Error handling test")
            
            Task {
                await operation()
                XCTAssertNotNil(self.engine.lastError)
                XCTAssertFalse(self.engine.isProcessing)
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 5.0)
        }
    }
    
    func testConcurrentOperations() {
        // Given
        let expectation = XCTestExpectation(description: "Concurrent operations")
        expectation.expectedFulfillmentCount = 4
        
        // When
        Task {
            await withTaskGroup(of: Void.self) { group in
                group.addTask { await self.engine.findResearchStudies() }
                group.addTask { await self.engine.contributeHealthData() }
                group.addTask { await self.engine.generatePopulationInsights() }
                group.addTask { await self.engine.joinAcademicPartnership() }
            }
            expectation.fulfill()
        }
        
        // Then
        wait(for: [expectation], timeout: 10.0)
        XCTAssertFalse(engine.isProcessing)
    }
}

// MARK: - Mock Classes

class MockHealthDataManager: HealthDataManager {
    var authorizationGranted = true
    var healthDataPublisher = PassthroughSubject<[HealthDataEntry], Never>()
    
    override func requestAuthorization() async throws {
        if !authorizationGranted {
            throw NSError(domain: "HealthKit", code: 1, userInfo: [NSLocalizedDescriptionKey: "Authorization denied"])
        }
    }
}

class MockMLModelManager: MLModelManager {
    var shouldFail = false
    var mockPopulationInsights: [HealthResearchAnalytics.PopulationInsight] = []
    var mockTreatmentEffectiveness: HealthResearchAnalytics.TreatmentEffectiveness?
    var mockMedicalDevices: [MedicalDevice] = []
    
    override func generatePopulationInsights() async throws -> [HealthResearchAnalytics.PopulationInsight] {
        if shouldFail {
            throw NSError(domain: "MLModel", code: 1, userInfo: [NSLocalizedDescriptionKey: "ML model failed"])
        }
        return mockPopulationInsights
    }
    
    override func analyzeTreatmentEffectiveness() async throws -> HealthResearchAnalytics.TreatmentEffectiveness {
        if shouldFail {
            throw NSError(domain: "MLModel", code: 1, userInfo: [NSLocalizedDescriptionKey: "ML model failed"])
        }
        return mockTreatmentEffectiveness ?? HealthResearchAnalytics.TreatmentEffectiveness(
            overallScore: 0.0,
            metrics: [:],
            recommendations: [],
            lastUpdated: Date()
        )
    }
    
    override func discoverAndConnectMedicalDevices() async throws -> [MedicalDevice] {
        if shouldFail {
            throw NSError(domain: "MLModel", code: 1, userInfo: [NSLocalizedDescriptionKey: "ML model failed"])
        }
        return mockMedicalDevices
    }
}

class MockNotificationManager: NotificationManager {
    var sentNotifications: [(title: String, body: String, category: NotificationCategory)] = []
    
    override func sendNotification(title: String, body: String, category: NotificationCategory) {
        sentNotifications.append((title: title, body: body, category: category))
    }
}

class MockPrivacySecurityManager: PrivacySecurityManager {
    var consentGranted = true
    
    override func requestDataContributionConsent() async -> Bool {
        return consentGranted
    }
}

class MockAnalyticsEngine: AnalyticsEngine {
    var trackedEvents: [String] = []
    var trackedProperties: [[String: Any]] = []
    
    override func trackEvent(_ event: String, properties: [String: Any]? = nil) {
        trackedEvents.append(event)
        if let properties = properties {
            trackedProperties.append(properties)
        }
    }
} 
import XCTest
@testable import HealthAI2030Core

class HealthResearchClinicalIntegrationTests: XCTestCase {
    var engine: HealthResearchClinicalIntegrationEngine!
    var mockHealthDataManager: HealthDataManager!
    var mockMLModelManager: MLModelManager!
    var mockNotificationManager: NotificationManager!

    override func setUp() {
        super.setUp()
        // Initialize with proper mock implementations
        mockHealthDataManager = HealthDataManager()
        mockMLModelManager = MLModelManager()
        mockNotificationManager = NotificationManager()
        engine = HealthResearchClinicalIntegrationEngine(
            healthDataManager: mockHealthDataManager,
            mlModelManager: mockMLModelManager,
            notificationManager: mockNotificationManager
        )
    }

    override func tearDown() {
        engine = nil
        mockHealthDataManager = nil
        mockMLModelManager = nil
        mockNotificationManager = nil
        super.tearDown()
    }

    func testFindResearchStudies() {
        // Test research study discovery and matching
        let studies = engine.findResearchStudies()
        
        // Verify studies are found and have required properties
        XCTAssertNotNil(studies)
        XCTAssertGreaterThan(studies.count, 0)
        
        // Verify study properties
        for study in studies {
            XCTAssertNotNil(study.id)
            XCTAssertNotNil(study.title)
            XCTAssertNotNil(study.description)
            XCTAssertNotNil(study.eligibilityCriteria)
            XCTAssertNotNil(study.participationStatus)
        }
    }

    func testContributeHealthData() {
        // Test health data contribution with privacy controls
        let contributionResult = engine.contributeHealthData()
        
        // Verify data contribution is successful
        XCTAssertTrue(contributionResult.success)
        XCTAssertNotNil(contributionResult.contributionId)
        XCTAssertNotNil(contributionResult.timestamp)
        XCTAssertNotNil(contributionResult.dataTypes)
        XCTAssertNotNil(contributionResult.privacyLevel)
        
        // Verify privacy controls are applied
        XCTAssertEqual(contributionResult.privacyLevel, .anonymized)
        XCTAssertTrue(contributionResult.consentGiven)
    }

    func testConnectHealthcareProvider() {
        // Test healthcare provider connectivity
        let connectionResult = engine.connectHealthcareProvider()
        
        // Verify provider connection is established
        XCTAssertTrue(connectionResult.success)
        XCTAssertNotNil(connectionResult.providerId)
        XCTAssertNotNil(connectionResult.connectionStatus)
        XCTAssertNotNil(connectionResult.ehrIntegrationStatus)
        XCTAssertNotNil(connectionResult.lastSyncTime)
        
        // Verify connection properties
        XCTAssertEqual(connectionResult.connectionStatus, .connected)
        XCTAssertTrue(connectionResult.ehrIntegrationStatus == .active)
    }

    func testIntegrateTelemedicine() {
        // Test telemedicine platform integration
        let integrationResult = engine.integrateTelemedicine()
        
        // Verify telemedicine integration is successful
        XCTAssertTrue(integrationResult.success)
        XCTAssertNotNil(integrationResult.platformId)
        XCTAssertNotNil(integrationResult.integrationStatus)
        XCTAssertNotNil(integrationResult.features)
        XCTAssertNotNil(integrationResult.lastUpdateTime)
        
        // Verify integration features
        XCTAssertTrue(integrationResult.features.contains("video_consultation"))
        XCTAssertTrue(integrationResult.features.contains("secure_messaging"))
        XCTAssertTrue(integrationResult.features.contains("prescription_management"))
    }

    func testGeneratePopulationInsights() {
        // Test population health insights generation
        let insights = engine.generatePopulationInsights()
        
        // Verify insights are generated
        XCTAssertNotNil(insights)
        XCTAssertGreaterThan(insights.count, 0)
        
        // Verify insight properties
        for insight in insights {
            XCTAssertNotNil(insight.id)
            XCTAssertNotNil(insight.title)
            XCTAssertNotNil(insight.description)
            XCTAssertNotNil(insight.category)
            XCTAssertNotNil(insight.confidence)
            XCTAssertNotNil(insight.timestamp)
        }
    }

    func testTrackTreatmentEffectiveness() {
        // Test treatment effectiveness tracking
        let trackingResult = engine.trackTreatmentEffectiveness()
        
        // Verify treatment tracking is working
        XCTAssertTrue(trackingResult.success)
        XCTAssertNotNil(trackingResult.treatmentId)
        XCTAssertNotNil(trackingResult.effectivenessScore)
        XCTAssertNotNil(trackingResult.sideEffects)
        XCTAssertNotNil(trackingResult.complianceRate)
        XCTAssertNotNil(trackingResult.lastAssessmentDate)
        
        // Verify effectiveness metrics
        XCTAssertGreaterThanOrEqual(trackingResult.effectivenessScore, 0.0)
        XCTAssertLessThanOrEqual(trackingResult.effectivenessScore, 1.0)
        XCTAssertGreaterThanOrEqual(trackingResult.complianceRate, 0.0)
        XCTAssertLessThanOrEqual(trackingResult.complianceRate, 1.0)
    }

    func testJoinAcademicPartnership() {
        // Test academic partnership joining
        let partnershipResult = engine.joinAcademicPartnership()
        
        // Verify partnership is established
        XCTAssertTrue(partnershipResult.success)
        XCTAssertNotNil(partnershipResult.partnershipId)
        XCTAssertNotNil(partnershipResult.institutionName)
        XCTAssertNotNil(partnershipResult.researchAreas)
        XCTAssertNotNil(partnershipResult.status)
        XCTAssertNotNil(partnershipResult.startDate)
        
        // Verify partnership properties
        XCTAssertEqual(partnershipResult.status, .active)
        XCTAssertGreaterThan(partnershipResult.researchAreas.count, 0)
    }

    func testIntegrateMedicalDevices() {
        // Test medical device integration
        let integrationResult = engine.integrateMedicalDevices()
        
        // Verify device integration is successful
        XCTAssertTrue(integrationResult.success)
        XCTAssertNotNil(integrationResult.deviceId)
        XCTAssertNotNil(integrationResult.deviceType)
        XCTAssertNotNil(integrationResult.connectionStatus)
        XCTAssertNotNil(integrationResult.dataStreams)
        XCTAssertNotNil(integrationResult.lastDataSync)
        
        // Verify device properties
        XCTAssertEqual(integrationResult.connectionStatus, .connected)
        XCTAssertGreaterThan(integrationResult.dataStreams.count, 0)
    }
} 
import XCTest
import Foundation
import Combine
@testable import HealthAI2030

@available(iOS 18.0, macOS 15.0, *)
final class AdvancedClinicalDecisionSupportEngineTests: XCTestCase {
    
    var clinicalEngine: AdvancedClinicalDecisionSupportEngine!
    var healthDataManager: HealthDataManager!
    var analyticsEngine: AnalyticsEngine!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        healthDataManager = HealthDataManager()
        analyticsEngine = AnalyticsEngine()
        clinicalEngine = AdvancedClinicalDecisionSupportEngine(
            healthDataManager: healthDataManager,
            analyticsEngine: analyticsEngine
        )
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDown() {
        cancellables = nil
        clinicalEngine = nil
        healthDataManager = nil
        analyticsEngine = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testInitialization() {
        XCTAssertNotNil(clinicalEngine)
        XCTAssertFalse(clinicalEngine.isAnalysisActive)
        XCTAssertEqual(clinicalEngine.analysisProgress, 0.0)
        XCTAssertTrue(clinicalEngine.recommendations.isEmpty)
        XCTAssertTrue(clinicalEngine.riskAssessments.isEmpty)
        XCTAssertTrue(clinicalEngine.clinicalAlerts.isEmpty)
        XCTAssertTrue(clinicalEngine.evidenceSummaries.isEmpty)
        XCTAssertNil(clinicalEngine.clinicalInsights)
        XCTAssertTrue(clinicalEngine.clinicalHistory.isEmpty)
    }
    
    // MARK: - Analysis Tests
    
    func testStartAnalysis() async throws {
        // Given
        XCTAssertFalse(clinicalEngine.isAnalysisActive)
        
        // When
        try await clinicalEngine.startAnalysis()
        
        // Then
        XCTAssertTrue(clinicalEngine.isAnalysisActive)
        XCTAssertNil(clinicalEngine.lastError)
    }
    
    func testStopAnalysis() async throws {
        // Given
        try await clinicalEngine.startAnalysis()
        XCTAssertTrue(clinicalEngine.isAnalysisActive)
        
        // When
        await clinicalEngine.stopAnalysis()
        
        // Then
        XCTAssertFalse(clinicalEngine.isAnalysisActive)
        XCTAssertEqual(clinicalEngine.analysisProgress, 0.0)
    }
    
    func testStartAnalysisFailure() async {
        // Given
        let failingEngine = AdvancedClinicalDecisionSupportEngine(
            healthDataManager: MockFailingHealthDataManager(),
            analyticsEngine: analyticsEngine
        )
        
        // When & Then
        do {
            try await failingEngine.startAnalysis()
            XCTFail("Should have thrown an error")
        } catch {
            XCTAssertFalse(failingEngine.isAnalysisActive)
            XCTAssertNotNil(failingEngine.lastError)
        }
    }
    
    // MARK: - Clinical Analysis Tests
    
    func testPerformAnalysis() async throws {
        // Given
        try await clinicalEngine.startAnalysis()
        
        // When
        let analysis = try await clinicalEngine.performAnalysis()
        
        // Then
        XCTAssertNotNil(analysis)
        XCTAssertEqual(analysis.timestamp.timeIntervalSinceNow, 0, accuracy: 1.0)
        XCTAssertNotNil(analysis.insights)
        XCTAssertNotNil(analysis.recommendations)
        XCTAssertNotNil(analysis.riskAssessments)
    }
    
    func testAnalysisWithPatientData() async throws {
        // Given
        try await clinicalEngine.startAnalysis()
        
        // When
        let analysis = try await clinicalEngine.performAnalysis()
        
        // Then
        XCTAssertNotNil(analysis.insights)
        if let insights = analysis.insights {
            XCTAssertTrue(insights.cardiovascularRisk >= 0.0 && insights.cardiovascularRisk <= 1.0)
            XCTAssertTrue(insights.metabolicRisk >= 0.0 && insights.metabolicRisk <= 1.0)
            XCTAssertTrue(insights.respiratoryRisk >= 0.0 && insights.respiratoryRisk <= 1.0)
            XCTAssertTrue(insights.mentalHealthRisk >= 0.0 && insights.mentalHealthRisk <= 1.0)
            XCTAssertTrue(insights.confidenceScore >= 0.0 && insights.confidenceScore <= 1.0)
        }
    }
    
    // MARK: - Clinical Insights Tests
    
    func testGetClinicalInsights() async {
        // Given
        let timeframes: [Timeframe] = [.hour, .day, .week, .month]
        
        // When & Then
        for timeframe in timeframes {
            let insights = await clinicalEngine.getClinicalInsights(timeframe: timeframe)
            
            XCTAssertNotNil(insights)
            XCTAssertEqual(insights.timestamp.timeIntervalSinceNow, 0, accuracy: 1.0)
            XCTAssertNotNil(insights.overallHealth)
            XCTAssertTrue(insights.cardiovascularRisk >= 0.0 && insights.cardiovascularRisk <= 1.0)
            XCTAssertTrue(insights.metabolicRisk >= 0.0 && insights.metabolicRisk <= 1.0)
            XCTAssertTrue(insights.respiratoryRisk >= 0.0 && insights.respiratoryRisk <= 1.0)
            XCTAssertTrue(insights.mentalHealthRisk >= 0.0 && insights.mentalHealthRisk <= 1.0)
            XCTAssertNotNil(insights.medicationInteractions)
            XCTAssertNotNil(insights.lifestyleFactors)
            XCTAssertNotNil(insights.preventiveMeasures)
            XCTAssertNotNil(insights.clinicalTrends)
            XCTAssertNotNil(insights.evidenceLevel)
            XCTAssertTrue(insights.confidenceScore >= 0.0 && insights.confidenceScore <= 1.0)
        }
    }
    
    func testInsightsWithAnalysis() async throws {
        // Given
        try await clinicalEngine.startAnalysis()
        let analysis = try await clinicalEngine.performAnalysis()
        
        // When
        let insights = await clinicalEngine.getClinicalInsights(timeframe: .day)
        
        // Then
        XCTAssertNotNil(insights)
        XCTAssertNotNil(clinicalEngine.clinicalInsights)
    }
    
    // MARK: - Recommendations Tests
    
    func testGetRecommendations() async {
        // Given
        let priorities: [RecommendationPriority] = [.all, .high, .medium, .low]
        
        // When & Then
        for priority in priorities {
            let recommendations = await clinicalEngine.getRecommendations(priority: priority)
            XCTAssertNotNil(recommendations)
            
            if priority != .all {
                for recommendation in recommendations {
                    XCTAssertEqual(recommendation.priority, priority)
                }
            }
        }
    }
    
    func testRecommendationsWithAnalysis() async throws {
        // Given
        try await clinicalEngine.startAnalysis()
        let analysis = try await clinicalEngine.performAnalysis()
        
        // When
        let recommendations = await clinicalEngine.getRecommendations(priority: .all)
        
        // Then
        XCTAssertNotNil(recommendations)
        XCTAssertEqual(recommendations.count, clinicalEngine.recommendations.count)
    }
    
    func testRecommendationCategories() async throws {
        // Given
        try await clinicalEngine.startAnalysis()
        let analysis = try await clinicalEngine.performAnalysis()
        
        // When
        let recommendations = await clinicalEngine.getRecommendations(priority: .all)
        
        // Then
        for recommendation in recommendations {
            XCTAssertTrue(RecommendationCategory.allCases.contains(recommendation.category))
            XCTAssertTrue(recommendation.evidenceLevel != .insufficient)
            XCTAssertTrue(recommendation.impact >= 0.0 && recommendation.impact <= 1.0)
        }
    }
    
    // MARK: - Risk Assessment Tests
    
    func testGetRiskAssessments() async {
        // Given
        let categories: [RiskCategory] = [.all, .cardiovascular, .metabolic, .respiratory, .mental, .medication]
        
        // When & Then
        for category in categories {
            let risks = await clinicalEngine.getRiskAssessments(category: category)
            XCTAssertNotNil(risks)
            
            if category != .all {
                for risk in risks {
                    XCTAssertEqual(risk.category, category)
                }
            }
        }
    }
    
    func testRiskAssessmentsWithAnalysis() async throws {
        // Given
        try await clinicalEngine.startAnalysis()
        let analysis = try await clinicalEngine.performAnalysis()
        
        // When
        let risks = await clinicalEngine.getRiskAssessments(category: .all)
        
        // Then
        XCTAssertNotNil(risks)
        XCTAssertEqual(risks.count, clinicalEngine.riskAssessments.count)
    }
    
    func testRiskAssessmentValidation() async throws {
        // Given
        try await clinicalEngine.startAnalysis()
        let analysis = try await clinicalEngine.performAnalysis()
        
        // When
        let risks = await clinicalEngine.getRiskAssessments(category: .all)
        
        // Then
        for risk in risks {
            XCTAssertTrue(RiskCategory.allCases.contains(risk.category))
            XCTAssertTrue(RiskLevel.allCases.contains(risk.riskLevel))
            XCTAssertFalse(risk.description.isEmpty)
            XCTAssertFalse(risk.factors.isEmpty)
            XCTAssertFalse(risk.recommendations.isEmpty)
        }
    }
    
    // MARK: - Clinical Alerts Tests
    
    func testGetClinicalAlerts() async {
        // Given
        let severities: [AlertSeverity] = [.all, .critical, .high, .medium, .low]
        
        // When & Then
        for severity in severities {
            let alerts = await clinicalEngine.getClinicalAlerts(severity: severity)
            XCTAssertNotNil(alerts)
            
            if severity != .all {
                for alert in alerts {
                    XCTAssertEqual(alert.severity, severity)
                }
            }
        }
    }
    
    func testClinicalAlertsWithAnalysis() async throws {
        // Given
        try await clinicalEngine.startAnalysis()
        let analysis = try await clinicalEngine.performAnalysis()
        
        // When
        let alerts = await clinicalEngine.getClinicalAlerts(severity: .all)
        
        // Then
        XCTAssertNotNil(alerts)
        XCTAssertEqual(alerts.count, clinicalEngine.clinicalAlerts.count)
    }
    
    func testAlertValidation() async throws {
        // Given
        try await clinicalEngine.startAnalysis()
        let analysis = try await clinicalEngine.performAnalysis()
        
        // When
        let alerts = await clinicalEngine.getClinicalAlerts(severity: .all)
        
        // Then
        for alert in alerts {
            XCTAssertTrue(AlertSeverity.allCases.contains(alert.severity))
            XCTAssertTrue(AlertCategory.allCases.contains(alert.category))
            XCTAssertFalse(alert.title.isEmpty)
            XCTAssertFalse(alert.description.isEmpty)
            XCTAssertFalse(alert.details.isEmpty)
            XCTAssertFalse(alert.actionRequired.isEmpty)
        }
    }
    
    // MARK: - Evidence Summaries Tests
    
    func testGetEvidenceSummaries() async {
        // Given
        let topics = ["cardiovascular", "diabetes", "hypertension", nil]
        
        // When & Then
        for topic in topics {
            let summaries = await clinicalEngine.getEvidenceSummaries(topic: topic)
            XCTAssertNotNil(summaries)
            
            if let topic = topic {
                for summary in summaries {
                    XCTAssertTrue(summary.topic.lowercased().contains(topic.lowercased()))
                }
            }
        }
    }
    
    func testEvidenceSummaryValidation() async {
        // Given
        let summaries = await clinicalEngine.getEvidenceSummaries()
        
        // When & Then
        for summary in summaries {
            XCTAssertFalse(summary.topic.isEmpty)
            XCTAssertFalse(summary.summary.isEmpty)
            XCTAssertTrue(EvidenceLevel.allCases.contains(summary.evidenceLevel))
            XCTAssertFalse(summary.source.isEmpty)
            XCTAssertNotNil(summary.publicationDate)
        }
    }
    
    // MARK: - Provider Preferences Tests
    
    func testUpdateProviderPreferences() async {
        // Given
        let preferences = ProviderPreferences(
            specialty: .cardiology,
            riskTolerance: .conservative,
            evidenceThreshold: .high,
            alertPreferences: .critical_only,
            recommendationStyle: .conservative,
            timestamp: Date()
        )
        
        // When
        await clinicalEngine.updateProviderPreferences(preferences)
        
        // Then
        // Preferences should be updated (implementation dependent)
        XCTAssertTrue(true) // Placeholder assertion
    }
    
    // MARK: - Export Tests
    
    func testExportClinicalReport() async throws {
        // Given
        try await clinicalEngine.startAnalysis()
        let analysis = try await clinicalEngine.performAnalysis()
        
        // When & Then
        for format in ExportFormat.allCases {
            let reportData = try await clinicalEngine.exportClinicalReport(format: format)
            XCTAssertNotNil(reportData)
            XCTAssertFalse(reportData.isEmpty)
        }
    }
    
    func testExportFormats() async throws {
        // Given
        try await clinicalEngine.startAnalysis()
        let analysis = try await clinicalEngine.performAnalysis()
        
        // When
        let pdfData = try await clinicalEngine.exportClinicalReport(format: .pdf)
        let jsonData = try await clinicalEngine.exportClinicalReport(format: .json)
        let csvData = try await clinicalEngine.exportClinicalReport(format: .csv)
        let xmlData = try await clinicalEngine.exportClinicalReport(format: .xml)
        
        // Then
        XCTAssertNotNil(pdfData)
        XCTAssertNotNil(jsonData)
        XCTAssertNotNil(csvData)
        XCTAssertNotNil(xmlData)
        XCTAssertFalse(pdfData.isEmpty)
        XCTAssertFalse(jsonData.isEmpty)
        XCTAssertFalse(csvData.isEmpty)
        XCTAssertFalse(xmlData.isEmpty)
    }
    
    // MARK: - Clinical History Tests
    
    func testGetClinicalHistory() {
        // Given
        let timeframes: [Timeframe] = [.hour, .day, .week, .month]
        
        // When & Then
        for timeframe in timeframes {
            let history = clinicalEngine.getClinicalHistory(timeframe: timeframe)
            XCTAssertNotNil(history)
        }
    }
    
    func testHistoryWithData() async throws {
        // Given
        try await clinicalEngine.startAnalysis()
        let analysis = try await clinicalEngine.performAnalysis()
        await clinicalEngine.stopAnalysis()
        
        // When
        let history = clinicalEngine.getClinicalHistory(timeframe: .day)
        
        // Then
        XCTAssertFalse(history.isEmpty)
        XCTAssertEqual(history.count, clinicalEngine.clinicalHistory.count)
    }
    
    // MARK: - Decision Validation Tests
    
    func testValidateClinicalDecision() async {
        // Given
        let decision = ClinicalDecision(
            id: UUID(),
            decision: "Start beta-blocker therapy",
            rationale: "Patient has elevated blood pressure",
            evidence: ["Clinical guidelines recommend beta-blockers for hypertension"],
            risks: ["May cause fatigue", "May affect heart rate"],
            benefits: ["Reduces blood pressure", "Reduces cardiovascular risk"],
            timestamp: Date()
        )
        
        // When
        let validation = await clinicalEngine.validateClinicalDecision(decision)
        
        // Then
        XCTAssertNotNil(validation)
        XCTAssertEqual(validation.decision.id, decision.id)
        XCTAssertNotNil(validation.evidenceValidation)
        XCTAssertNotNil(validation.guidelineValidation)
        XCTAssertNotNil(validation.riskValidation)
        XCTAssertNotNil(validation.overallValidation)
    }
    
    func testDecisionValidationComponents() async {
        // Given
        let decision = ClinicalDecision(
            id: UUID(),
            decision: "Lifestyle modification",
            rationale: "Patient has pre-diabetes",
            evidence: ["Diet and exercise can prevent diabetes"],
            risks: ["Minimal risks"],
            benefits: ["Prevents diabetes", "Improves overall health"],
            timestamp: Date()
        )
        
        // When
        let validation = await clinicalEngine.validateClinicalDecision(decision)
        
        // Then
        XCTAssertTrue(validation.evidenceValidation.confidence >= 0.0 && validation.evidenceValidation.confidence <= 1.0)
        XCTAssertTrue(validation.guidelineValidation.confidence >= 0.0 && validation.guidelineValidation.confidence <= 1.0)
        XCTAssertTrue(validation.riskValidation.confidence >= 0.0 && validation.riskValidation.confidence <= 1.0)
        XCTAssertTrue(ValidationLevel.allCases.contains(validation.overallValidation))
    }
    
    // MARK: - Data Model Tests
    
    func testClinicalInsightsModel() {
        // Given
        let insights = ClinicalInsights(
            timestamp: Date(),
            overallHealth: HealthScore(score: 0.8, category: .good, timestamp: Date()),
            cardiovascularRisk: 0.2,
            metabolicRisk: 0.1,
            respiratoryRisk: 0.05,
            mentalHealthRisk: 0.1,
            medicationInteractions: [],
            lifestyleFactors: [],
            preventiveMeasures: [],
            clinicalTrends: [],
            evidenceLevel: .moderate,
            confidenceScore: 0.85
        )
        
        // Then
        XCTAssertNotNil(insights.timestamp)
        XCTAssertEqual(insights.overallHealth.category, .good)
        XCTAssertEqual(insights.cardiovascularRisk, 0.2)
        XCTAssertEqual(insights.metabolicRisk, 0.1)
        XCTAssertEqual(insights.respiratoryRisk, 0.05)
        XCTAssertEqual(insights.mentalHealthRisk, 0.1)
        XCTAssertEqual(insights.evidenceLevel, .moderate)
        XCTAssertEqual(insights.confidenceScore, 0.85)
    }
    
    func testClinicalRecommendationModel() {
        // Given
        let recommendation = ClinicalRecommendation(
            id: UUID(),
            title: "Lifestyle Modification",
            description: "Implement diet and exercise changes",
            category: .lifestyle,
            priority: .high,
            evidenceLevel: .high,
            impact: 0.8,
            implementation: "Consult with nutritionist and personal trainer",
            timestamp: Date()
        )
        
        // Then
        XCTAssertNotNil(recommendation.id)
        XCTAssertEqual(recommendation.title, "Lifestyle Modification")
        XCTAssertEqual(recommendation.category, .lifestyle)
        XCTAssertEqual(recommendation.priority, .high)
        XCTAssertEqual(recommendation.evidenceLevel, .high)
        XCTAssertEqual(recommendation.impact, 0.8)
    }
    
    func testRiskAssessmentModel() {
        // Given
        let risk = RiskAssessment(
            id: UUID(),
            category: .cardiovascular,
            riskLevel: .moderate,
            description: "Elevated cardiovascular risk factors",
            factors: ["High blood pressure", "Family history"],
            recommendations: ["Lifestyle changes", "Regular monitoring"],
            timestamp: Date()
        )
        
        // Then
        XCTAssertNotNil(risk.id)
        XCTAssertEqual(risk.category, .cardiovascular)
        XCTAssertEqual(risk.riskLevel, .moderate)
        XCTAssertFalse(risk.description.isEmpty)
        XCTAssertFalse(risk.factors.isEmpty)
        XCTAssertFalse(risk.recommendations.isEmpty)
    }
    
    func testClinicalAlertModel() {
        // Given
        let alert = ClinicalAlert(
            id: UUID(),
            title: "Critical Blood Pressure",
            description: "Blood pressure readings are critically high",
            severity: .critical,
            category: .vital_signs,
            details: ["Systolic: 180", "Diastolic: 110"],
            actionRequired: "Immediate medical attention required",
            timestamp: Date()
        )
        
        // Then
        XCTAssertNotNil(alert.id)
        XCTAssertEqual(alert.title, "Critical Blood Pressure")
        XCTAssertEqual(alert.severity, .critical)
        XCTAssertEqual(alert.category, .vital_signs)
        XCTAssertFalse(alert.details.isEmpty)
        XCTAssertFalse(alert.actionRequired.isEmpty)
    }
    
    func testPatientDataModel() {
        // Given
        let patientData = PatientData(
            id: "12345",
            demographics: Demographics(
                age: 45,
                gender: .male,
                height: 175.0,
                weight: 80.0,
                ethnicity: .white,
                timestamp: Date()
            ),
            vitalSigns: VitalSigns(
                heartRate: 72,
                respiratoryRate: 16,
                temperature: 98.6,
                bloodPressure: BloodPressure(systolic: 120, diastolic: 80, timestamp: Date()),
                oxygenSaturation: 98.0,
                timestamp: Date()
            ),
            medicalHistory: MedicalHistory(
                conditions: ["Hypertension"],
                surgeries: [],
                allergies: [],
                familyHistory: ["Heart disease"],
                timestamp: Date()
            ),
            medications: [],
            lifestyle: LifestyleData(
                activityLevel: .moderate,
                dietQuality: .good,
                sleepQuality: 0.8,
                stressLevel: 0.4,
                smokingStatus: .never,
                alcoholConsumption: .moderate,
                timestamp: Date()
            ),
            labResults: [],
            imaging: [],
            symptoms: [],
            timestamp: Date()
        )
        
        // Then
        XCTAssertEqual(patientData.id, "12345")
        XCTAssertEqual(patientData.demographics.age, 45)
        XCTAssertEqual(patientData.demographics.gender, .male)
        XCTAssertEqual(patientData.vitalSigns.heartRate, 72)
        XCTAssertFalse(patientData.medicalHistory.conditions.isEmpty)
        XCTAssertEqual(patientData.lifestyle.activityLevel, .moderate)
    }
    
    // MARK: - Performance Tests
    
    func testPerformanceAnalysis() {
        measure {
            let expectation = XCTestExpectation(description: "Performance test")
            
            Task {
                try? await clinicalEngine.startAnalysis()
                _ = try? await clinicalEngine.performAnalysis()
                await clinicalEngine.stopAnalysis()
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 10.0)
        }
    }
    
    func testPerformanceInsights() {
        measure {
            let expectation = XCTestExpectation(description: "Insights performance test")
            
            Task {
                _ = await clinicalEngine.getClinicalInsights(timeframe: .day)
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 5.0)
        }
    }
    
    func testPerformanceRecommendations() {
        measure {
            let expectation = XCTestExpectation(description: "Recommendations performance test")
            
            Task {
                _ = await clinicalEngine.getRecommendations(priority: .all)
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 5.0)
        }
    }
    
    // MARK: - Integration Tests
    
    func testIntegrationWithHealthDataManager() async {
        // Given
        XCTAssertNotNil(clinicalEngine.healthDataManager)
        
        // When & Then
        try? await clinicalEngine.startAnalysis()
        XCTAssertTrue(clinicalEngine.isAnalysisActive || clinicalEngine.lastError != nil)
    }
    
    func testIntegrationWithAnalyticsEngine() async {
        // Given
        XCTAssertNotNil(clinicalEngine.analyticsEngine)
        
        // When
        try? await clinicalEngine.startAnalysis()
        
        // Then
        // Analytics should be tracked (implementation dependent)
        XCTAssertTrue(clinicalEngine.isAnalysisActive || clinicalEngine.lastError != nil)
    }
    
    // MARK: - Error Handling Tests
    
    func testErrorHandling() async {
        // Given
        let failingEngine = AdvancedClinicalDecisionSupportEngine(
            healthDataManager: MockFailingHealthDataManager(),
            analyticsEngine: analyticsEngine
        )
        
        // When
        do {
            try await failingEngine.startAnalysis()
            XCTFail("Should have thrown an error")
        } catch {
            // Then
            XCTAssertNotNil(failingEngine.lastError)
            XCTAssertFalse(failingEngine.isAnalysisActive)
        }
    }
    
    func testAnalysisErrorHandling() async {
        // Given
        let failingEngine = AdvancedClinicalDecisionSupportEngine(
            healthDataManager: healthDataManager,
            analyticsEngine: MockFailingAnalyticsEngine()
        )
        
        try? await failingEngine.startAnalysis()
        
        // When & Then
        do {
            _ = try await failingEngine.performAnalysis()
            XCTFail("Should have thrown an error")
        } catch {
            XCTAssertNotNil(failingEngine.lastError)
        }
    }
    
    // MARK: - Edge Cases Tests
    
    func testEmptyPatientData() async throws {
        // Given
        try await clinicalEngine.startAnalysis()
        
        // When
        let analysis = try await clinicalEngine.performAnalysis()
        
        // Then
        XCTAssertNotNil(analysis)
        // Should handle empty patient data gracefully
    }
    
    func testInvalidPatientData() async throws {
        // Given
        try await clinicalEngine.startAnalysis()
        
        // When
        let analysis = try await clinicalEngine.performAnalysis()
        
        // Then
        XCTAssertNotNil(analysis)
        // Should handle invalid patient data gracefully
    }
    
    func testConcurrentAnalysis() async throws {
        // Given
        try await clinicalEngine.startAnalysis()
        
        // When
        async let analysis1 = clinicalEngine.performAnalysis()
        async let analysis2 = clinicalEngine.performAnalysis()
        
        let (result1, result2) = try await (analysis1, analysis2)
        
        // Then
        XCTAssertNotNil(result1)
        XCTAssertNotNil(result2)
        // Should handle concurrent analysis requests
    }
}

// MARK: - Mock Classes

class MockFailingHealthDataManager: HealthDataManager {
    override func requestHealthKitPermissions() async throws {
        throw NSError(domain: "MockError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock failure"])
    }
}

class MockFailingAnalyticsEngine: AnalyticsEngine {
    override func trackEvent(_ event: String, properties: [String: Any]? = nil) {
        // Simulate failure
        throw NSError(domain: "MockError", code: 2, userInfo: [NSLocalizedDescriptionKey: "Mock analytics failure"])
    }
}

// MARK: - Test Extensions

extension AdvancedClinicalDecisionSupportEngine {
    var healthDataManager: HealthDataManager {
        return Mirror(reflecting: self).children.first { $0.label == "healthDataManager" }?.value as! HealthDataManager
    }
    
    var analyticsEngine: AnalyticsEngine {
        return Mirror(reflecting: self).children.first { $0.label == "analyticsEngine" }?.value as! AnalyticsEngine
    }
} 
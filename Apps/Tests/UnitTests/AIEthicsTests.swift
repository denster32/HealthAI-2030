import XCTest
@testable import HealthAI2030Core

final class AIEthicsTests: XCTestCase {
    let ethics = AIEthicsManager.shared
    
    func testDetectBias() {
        let sensitiveAttributes = ["age", "gender", "race"]
        let biasScores = ethics.detectBias(modelId: "model1", data: Data([1,2,3]), sensitiveAttributes: sensitiveAttributes)
        
        XCTAssertEqual(biasScores[.demographic], 0.05)
        XCTAssertEqual(biasScores[.selection], 0.02)
        XCTAssertEqual(biasScores[.measurement], 0.03)
        XCTAssertEqual(biasScores[.algorithmic], 0.01)
        XCTAssertEqual(biasScores[.historical], 0.04)
    }
    
    func testMonitorBiasOverTime() {
        let biasHistory = ethics.monitorBiasOverTime(modelId: "model1")
        XCTAssertEqual(biasHistory["demographic"]?.count, 4)
        XCTAssertEqual(biasHistory["selection"]?.count, 4)
        XCTAssertEqual(biasHistory["measurement"]?.count, 4)
    }
    
    func testAlertOnBiasThreshold() {
        let alertTriggered = ethics.alertOnBiasThreshold(modelId: "model1", threshold: 0.03)
        XCTAssertTrue(alertTriggered) // max bias is 0.05 > 0.03
        
        let noAlert = ethics.alertOnBiasThreshold(modelId: "model1", threshold: 0.1)
        XCTAssertFalse(noAlert) // max bias is 0.05 < 0.1
    }
    
    func testCalculateFairnessMetrics() {
        let metrics = ethics.calculateFairnessMetrics(modelId: "model1", data: Data([1,2,3]))
        XCTAssertEqual(metrics[.statisticalParity], 0.95)
        XCTAssertEqual(metrics[.equalizedOdds], 0.92)
        XCTAssertEqual(metrics[.predictiveRateParity], 0.94)
        XCTAssertEqual(metrics[.individualFairness], 0.96)
        XCTAssertEqual(metrics[.counterfactualFairness], 0.93)
    }
    
    func testValidateFairness() {
        let fair = ethics.validateFairness(modelId: "model1", threshold: 0.9)
        XCTAssertTrue(fair) // min fairness is 0.92 >= 0.9
        
        let unfair = ethics.validateFairness(modelId: "model1", threshold: 0.95)
        XCTAssertFalse(unfair) // min fairness is 0.92 < 0.95
    }
    
    func testGenerateFairnessReport() {
        let report = ethics.generateFairnessReport(modelId: "model1")
        XCTAssertEqual(report["overallFairness"] as? Double, 0.94)
        XCTAssertEqual(report["demographicParity"] as? Double, 0.95)
        XCTAssertEqual(report["equalizedOdds"] as? Double, 0.92)
        XCTAssertEqual(report["predictiveRateParity"] as? Double, 0.94)
        XCTAssertEqual(report["individualFairness"] as? Double, 0.96)
        XCTAssertEqual(report["counterfactualFairness"] as? Double, 0.93)
        XCTAssertEqual(report["recommendations"] as? [String], ["Increase training data diversity", "Review feature selection"])
    }
    
    func testValidateEthicsCompliance() {
        let compliance = ethics.validateEthicsCompliance(modelId: "model1")
        XCTAssertTrue(compliance[.fairness] ?? false)
        XCTAssertTrue(compliance[.transparency] ?? false)
        XCTAssertTrue(compliance[.accountability] ?? false)
        XCTAssertTrue(compliance[.privacy] ?? false)
        XCTAssertTrue(compliance[.beneficence] ?? false)
        XCTAssertTrue(compliance[.nonMaleficence] ?? false)
    }
    
    func testCheckEthicsGuidelines() {
        let guidelines = ethics.checkEthicsGuidelines(modelId: "model1")
        XCTAssertEqual(guidelines["guidelinesCompliant"] as? Bool, true)
        XCTAssertEqual(guidelines["principlesViolated"] as? [String], [])
        XCTAssertEqual(guidelines["riskLevel"] as? String, "low")
        XCTAssertEqual(guidelines["recommendations"] as? [String], ["Continue monitoring", "Regular audits"])
    }
    
    func testGenerateEthicsComplianceReport() {
        let report = ethics.generateEthicsComplianceReport()
        XCTAssertNotNil(report)
    }
    
    func testApplyBiasMitigation() {
        let originalData = Data([1,2,3,4,5])
        let mitigatedData = ethics.applyBiasMitigation(modelId: "model1", strategy: .postProcessing, data: originalData)
        XCTAssertNotNil(mitigatedData)
    }
    
    func testEvaluateMitigationEffectiveness() {
        let beforeData = Data([1,2,3])
        let afterData = Data([1,2,3])
        let effectiveness = ethics.evaluateMitigationEffectiveness(modelId: "model1", beforeData: beforeData, afterData: afterData)
        
        XCTAssertEqual(effectiveness["biasReduction"], 0.3)
        XCTAssertEqual(effectiveness["accuracyPreservation"], 0.98)
        XCTAssertEqual(effectiveness["fairnessImprovement"], 0.25)
        XCTAssertEqual(effectiveness["overallEffectiveness"], 0.85)
    }
    
    func testRecommendMitigationStrategy() {
        let lowBias: [AIEthicsManager.BiasType: Double] = [.demographic: 0.03]
        let mediumBias: [AIEthicsManager.BiasType: Double] = [.demographic: 0.07]
        let highBias: [AIEthicsManager.BiasType: Double] = [.demographic: 0.15]
        
        XCTAssertEqual(ethics.recommendMitigationStrategy(biasScores: lowBias), .postProcessing)
        XCTAssertEqual(ethics.recommendMitigationStrategy(biasScores: mediumBias), .inProcessing)
        XCTAssertEqual(ethics.recommendMitigationStrategy(biasScores: highBias), .adversarialDebiasing)
    }
    
    func testGenerateTransparencyReport() {
        let report = ethics.generateTransparencyReport(modelId: "model1")
        XCTAssertEqual(report["modelDescription"] as? String, "Health prediction model")
        XCTAssertEqual(report["trainingData"] as? String, "Diverse health datasets")
        XCTAssertEqual(report["features"] as? [String], ["age", "gender", "bloodPressure", "heartRate"])
        XCTAssertEqual(report["algorithm"] as? String, "Random Forest")
        XCTAssertEqual(report["biasAssessment"] as? String, "Low bias detected")
        XCTAssertEqual(report["fairnessMetrics"] as? String, "All metrics above 0.9")
        XCTAssertEqual(report["mitigationApplied"] as? String, "Post-processing debiasing")
    }
    
    func testCreateExplainabilityReport() {
        let report = ethics.createExplainabilityReport(modelId: "model1")
        XCTAssertNotNil(report)
    }
    
    func testGenerateEthicsDashboard() {
        let dashboard = ethics.generateEthicsDashboard()
        XCTAssertEqual(dashboard["modelsMonitored"] as? Int, 10)
        XCTAssertEqual(dashboard["biasAlerts"] as? Int, 2)
        XCTAssertEqual(dashboard["fairnessScore"] as? Double, 0.94)
        XCTAssertEqual(dashboard["complianceStatus"] as? String, "compliant")
        XCTAssertEqual(dashboard["lastAudit"] as? String, "2024-01-15")
    }
    
    func testCreateEthicsTrainingProgram() {
        let program = ethics.createEthicsTrainingProgram()
        XCTAssertEqual(program["modules"] as? [String], ["Bias Detection", "Fairness Metrics", "Mitigation Strategies"])
        XCTAssertEqual(program["duration"] as? String, "8 hours")
        XCTAssertEqual(program["certification"] as? String, "AI Ethics Certified")
        XCTAssertEqual(program["targetAudience"] as? [String], ["Data Scientists", "ML Engineers", "Product Managers"])
    }
    
    func testAssessEthicsKnowledge() {
        let assessment = ethics.assessEthicsKnowledge(participantId: "participant1")
        XCTAssertEqual(assessment["score"] as? Int, 85)
        XCTAssertEqual(assessment["areas"] as? [String: Int], ["Bias Detection": 90, "Fairness": 85, "Mitigation": 80])
        XCTAssertEqual(assessment["recommendations"] as? [String], ["Review bias detection methods", "Practice fairness calculations"])
    }
    
    func testGenerateTrainingReport() {
        let report = ethics.generateTrainingReport()
        XCTAssertNotNil(report)
    }
} 
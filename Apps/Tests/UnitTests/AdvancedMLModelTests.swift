import XCTest
@testable import HealthAI2030Core

final class AdvancedMLModelTests: XCTestCase {
    let mlManager = AdvancedMLModelManager.shared
    
    func testCreateTrainingPipeline() {
        let config = ["batchSize": 32, "epochs": 100]
        let pipelineId = mlManager.createTrainingPipeline(type: .continuous, config: config)
        XCTAssertEqual(pipelineId, "pipeline_123")
    }
    
    func testAllTrainingPipelineTypes() {
        let types: [AdvancedMLModelManager.TrainingPipeline] = [
            .continuous,
            .scheduled,
            .eventDriven,
            .manual
        ]
        
        for type in types {
            let config = ["type": "test"]
            let pipelineId = mlManager.createTrainingPipeline(type: type, config: config)
            XCTAssertNotNil(pipelineId)
        }
    }
    
    func testExecuteTrainingPipeline() {
        let success = mlManager.executeTrainingPipeline(pipelineId: "pipeline_123", data: Data([1,2,3]))
        XCTAssertTrue(success)
    }
    
    func testMonitorPipelineStatus() {
        let status = mlManager.monitorPipelineStatus(pipelineId: "pipeline_123")
        XCTAssertEqual(status["status"] as? String, "running")
        XCTAssertEqual(status["progress"] as? Double, 0.75)
        XCTAssertEqual(status["currentStep"] as? String, "training")
        XCTAssertEqual(status["estimatedCompletion"] as? String, "2024-01-15T12:00:00Z")
    }
    
    func testCreateAndDeployModelVersion() {
        let performance = ["accuracy": 0.92, "precision": 0.89]
        mlManager.createModelVersion(modelId: "model1", version: "v1.0", performance: performance)
        
        let versions = mlManager.modelVersions
        XCTAssertGreaterThan(versions.count, 0)
        let version = versions["model1"]
        XCTAssertNotNil(version)
        XCTAssertEqual(version?.version, "v1.0")
        XCTAssertEqual(version?.performance["accuracy"], 0.92)
        XCTAssertFalse(version?.deployed ?? true)
        
        let deployed = mlManager.deployModel(modelId: "model1", version: "v1.0")
        XCTAssertTrue(deployed)
        
        let updatedVersion = mlManager.modelVersions["model1"]
        XCTAssertTrue(updatedVersion?.deployed ?? false)
    }
    
    func testRollbackModel() {
        let success = mlManager.rollbackModel(modelId: "model1", version: "v0.9")
        XCTAssertTrue(success)
    }
    
    func testMonitorModelPerformance() {
        let performance = mlManager.monitorModelPerformance(modelId: "model1")
        XCTAssertEqual(performance["accuracy"] as? Double, 0.92)
        XCTAssertEqual(performance["precision"] as? Double, 0.89)
        XCTAssertEqual(performance["recall"] as? Double, 0.94)
        XCTAssertEqual(performance["f1Score"] as? Double, 0.91)
        XCTAssertEqual(performance["driftScore"] as? Double, 0.15)
    }
    
    func testDetectModelDrift() {
        let driftDetected = mlManager.detectModelDrift(modelId: "model1", newData: Data([1,2,3]))
        XCTAssertFalse(driftDetected)
    }
    
    func testCalculateDriftScore() {
        let driftScore = mlManager.calculateDriftScore(modelId: "model1")
        XCTAssertEqual(driftScore, 0.15)
    }
    
    func testAlertOnDrift() {
        let alertTriggered = mlManager.alertOnDrift(modelId: "model1", threshold: 0.1)
        XCTAssertTrue(alertTriggered) // 0.15 > 0.1
        
        let noAlert = mlManager.alertOnDrift(modelId: "model1", threshold: 0.2)
        XCTAssertFalse(noAlert) // 0.15 < 0.2
    }
    
    func testScheduleRetraining() {
        let scheduled = mlManager.scheduleRetraining(modelId: "model1", trigger: "drift_detected")
        XCTAssertTrue(scheduled)
    }
    
    func testPerformRetraining() {
        let retrained = mlManager.performRetraining(modelId: "model1", newData: Data([1,2,3]))
        XCTAssertTrue(retrained)
    }
    
    func testValidateRetrainedModel() {
        let validation = mlManager.validateRetrainedModel(modelId: "model1")
        XCTAssertEqual(validation["improvement"] as? Double, 0.05)
        XCTAssertEqual(validation["regression"] as? Bool, false)
        XCTAssertEqual(validation["newAccuracy"] as? Double, 0.95)
        XCTAssertEqual(validation["validationPassed"] as? Bool, true)
    }
    
    func testGenerateFeatureImportance() {
        let importance = mlManager.generateFeatureImportance(modelId: "model1")
        XCTAssertEqual(importance["age"], 0.25)
        XCTAssertEqual(importance["gender"], 0.15)
        XCTAssertEqual(importance["bloodPressure"], 0.30)
        XCTAssertEqual(importance["heartRate"], 0.20)
        XCTAssertEqual(importance["activityLevel"], 0.10)
    }
    
    func testExplainPrediction() {
        let explanation = mlManager.explainPrediction(modelId: "model1", input: Data([1,2,3]))
        XCTAssertEqual(explanation["prediction"] as? String, "healthy")
        XCTAssertEqual(explanation["confidence"] as? Double, 0.85)
        XCTAssertEqual(explanation["contributingFactors"] as? [String], ["bloodPressure", "heartRate"])
        XCTAssertEqual(explanation["explanation"] as? String, "Model predicts healthy based on normal blood pressure and heart rate")
    }
    
    func testGenerateSHAPValues() {
        let shapValues = mlManager.generateSHAPValues(modelId: "model1", input: Data([1,2,3]))
        XCTAssertEqual(shapValues["feature1"], 0.1)
        XCTAssertEqual(shapValues["feature2"], 0.2)
        XCTAssertEqual(shapValues["feature3"], 0.3)
    }
    
    func testValidateModelCompliance() {
        let compliance = mlManager.validateModelCompliance(modelId: "model1")
        XCTAssertEqual(compliance["hipaaCompliant"] as? Bool, true)
        XCTAssertEqual(compliance["gdprCompliant"] as? Bool, true)
        XCTAssertEqual(compliance["biasDetected"] as? Bool, false)
        XCTAssertEqual(compliance["fairnessScore"] as? Double, 0.95)
        XCTAssertEqual(compliance["transparencyScore"] as? Double, 0.88)
    }
    
    func testAuditModelUsage() {
        let audit = mlManager.auditModelUsage(modelId: "model1")
        XCTAssertEqual(audit["totalPredictions"] as? Int, 10000)
        XCTAssertEqual(audit["uniqueUsers"] as? Int, 5000)
        XCTAssertEqual(audit["lastUsed"] as? String, "2024-01-15T10:30:00Z")
        XCTAssertEqual(audit["dataRetention"] as? String, "compliant")
    }
    
    func testGenerateGovernanceReport() {
        let report = mlManager.generateGovernanceReport()
        XCTAssertNotNil(report)
    }
} 
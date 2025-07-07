import XCTest
@testable import HealthAI2030Core

final class FederatedLearningTests: XCTestCase {
    let federated = FederatedLearningManager.shared
    
    func testTrainModelWithAllAlgorithms() {
        let algorithms: [FederatedLearningManager.FederatedAlgorithm] = [
            .fedAvg,
            .fedProx,
            .fedNova,
            .secureAggregation,
            .differentialPrivacy
        ]
        
        for algorithm in algorithms {
            let localData = Data([1,2,3,4,5])
            let trainedModel = federated.trainModel(algorithm: algorithm, localData: localData)
            XCTAssertNotNil(trainedModel)
        }
    }
    
    func testAggregateModels() {
        let models = [Data("model1".utf8), Data("model2".utf8), Data("model3".utf8)]
        let aggregated = federated.aggregateModels(models: models)
        XCTAssertNotNil(aggregated)
    }
    
    func testValidateModel() {
        XCTAssertTrue(federated.validateModel(model: Data([1,2,3])))
        XCTAssertFalse(federated.validateModel(model: Data()))
    }
    
    func testApplyDifferentialPrivacy() {
        let originalData = Data([1,2,3,4,5])
        let privateData = federated.applyDifferentialPrivacy(data: originalData, epsilon: 1.0)
        XCTAssertNotNil(privateData)
    }
    
    func testEncryptAndDecryptModelWeights() {
        let originalWeights = Data("original weights".utf8)
        let encrypted = federated.encryptModelWeights(weights: originalWeights)
        XCTAssertNotNil(encrypted)
        
        let decrypted = federated.decryptModelWeights(encryptedWeights: encrypted)
        XCTAssertNotNil(decrypted)
    }
    
    func testComputePrivacyBudget() {
        let budget1 = federated.computePrivacyBudget(operations: 1)
        XCTAssertEqual(budget1, 1.0)
        
        let budget10 = federated.computePrivacyBudget(operations: 10)
        XCTAssertEqual(budget10, 0.1)
    }
    
    func testDistributeModelUpdate() {
        let model = Data("model update".utf8)
        let participants = ["participant1", "participant2", "participant3"]
        let success = federated.distributeModelUpdate(model: model, participants: participants)
        XCTAssertTrue(success)
    }
    
    func testCollectModelUpdates() {
        let participants = ["participant1", "participant2"]
        let updates = federated.collectModelUpdates(participants: participants)
        XCTAssertEqual(updates.count, 2)
    }
    
    func testPerformSecureAggregation() {
        let updates = [Data("update1".utf8), Data("update2".utf8), Data("update3".utf8)]
        let aggregated = federated.performSecureAggregation(updates: updates)
        XCTAssertNotNil(aggregated)
    }
    
    func testValidateParticipant() {
        let valid = federated.validateParticipant(participantId: "participant1")
        XCTAssertTrue(valid)
    }
    
    func testDetectMaliciousUpdates() {
        let updates = [Data("update1".utf8), Data("update2".utf8)]
        let maliciousIndices = federated.detectMaliciousUpdates(updates: updates)
        XCTAssertEqual(maliciousIndices.count, 0)
    }
    
    func testVerifyModelIntegrity() {
        XCTAssertTrue(federated.verifyModelIntegrity(model: Data([1,2,3])))
        XCTAssertFalse(federated.verifyModelIntegrity(model: Data()))
    }
    
    func testOptimizeCommunication() {
        let participants = ["p1", "p2", "p3", "p4", "p5"]
        let optimized = federated.optimizeCommunication(participants: participants)
        XCTAssertEqual(optimized.count, participants.count)
    }
    
    func testCompressAndDecompressModelUpdate() {
        let originalUpdate = Data("original model update".utf8)
        let compressed = federated.compressModelUpdate(update: originalUpdate)
        XCTAssertNotNil(compressed)
        
        let decompressed = federated.decompressModelUpdate(compressedUpdate: compressed)
        XCTAssertNotNil(decompressed)
    }
    
    func testMonitorTrainingProgress() {
        let progress = federated.monitorTrainingProgress(round: 5)
        XCTAssertEqual(progress["round"] as? Int, 5)
        XCTAssertEqual(progress["participants"] as? Int, 10)
        XCTAssertEqual(progress["convergence"] as? Double, 0.85)
        XCTAssertEqual(progress["privacyLoss"] as? Double, 0.1)
    }
    
    func testAnalyzeModelPerformance() {
        let model = Data("test model".utf8)
        let performance = federated.analyzeModelPerformance(model: model)
        XCTAssertEqual(performance["accuracy"] as? Double, 0.92)
        XCTAssertEqual(performance["loss"] as? Double, 0.08)
        XCTAssertEqual(performance["fairness"] as? Double, 0.95)
        XCTAssertEqual(performance["robustness"] as? Double, 0.88)
    }
    
    func testGenerateFederatedReport() {
        let report = federated.generateFederatedReport()
        XCTAssertNotNil(report)
    }
} 
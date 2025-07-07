import XCTest
@testable import HealthAI2030Core

final class BlockchainTests: XCTestCase {
    let blockchain = BlockchainManager.shared
    
    func testCreateHealthcareBlockchain() {
        let config = ["consensus": "proof_of_stake", "nodes": 10]
        let blockchainId = blockchain.createHealthcareBlockchain(type: .ethereum, config: config)
        XCTAssertEqual(blockchainId, "healthcare_blockchain_123")
    }
    
    func testAllBlockchainTypes() {
        let types: [BlockchainManager.BlockchainType] = [
            .ethereum,
            .hyperledger,
            .corda,
            .custom
        ]
        
        for type in types {
            let config = ["type": "test"]
            let blockchainId = blockchain.createHealthcareBlockchain(type: type, config: config)
            XCTAssertNotNil(blockchainId)
        }
    }
    
    func testStoreAndRetrieveHealthData() {
        let data = Data("health data".utf8)
        let metadata = ["type": "vital_signs", "patient": "patient123"]
        let transactionHash = blockchain.storeHealthData(blockchainId: "blockchain1", data: data, metadata: metadata)
        XCTAssertEqual(transactionHash, "transaction_hash_123")
        
        let retrievedData = blockchain.retrieveHealthData(blockchainId: "blockchain1", transactionHash: transactionHash)
        XCTAssertNotNil(retrievedData)
    }
    
    func testValidateBlockchainIntegrity() {
        let valid = blockchain.validateBlockchainIntegrity(blockchainId: "blockchain1")
        XCTAssertTrue(valid)
    }
    
    func testDeployAndExecuteSmartContract() {
        let contractCode = "contract HealthContract { function storeData(bytes memory data) public { } }"
        let contractId = blockchain.deploySmartContract(name: "HealthContract", code: contractCode)
        XCTAssertNotNil(contractId)
        
        let contracts = blockchain.getSmartContracts()
        XCTAssertGreaterThan(contracts.count, 0)
        let contract = contracts.first { $0.id == contractId }
        XCTAssertNotNil(contract)
        XCTAssertEqual(contract?.name, "HealthContract")
        XCTAssertTrue(contract?.deployed ?? false)
        
        let parameters = ["data": "test_data"]
        let result = blockchain.executeSmartContract(contractId: contractId, parameters: parameters)
        XCTAssertEqual(result["result"] as? String, "success")
        XCTAssertEqual(result["gasUsed"] as? Int, 21000)
        XCTAssertEqual(result["blockNumber"] as? Int, 12345)
    }
    
    func testValidateSmartContract() {
        let validation = blockchain.validateSmartContract(contractId: "contract1")
        XCTAssertEqual(validation["valid"] as? Bool, true)
        XCTAssertEqual(validation["securityScore"] as? Int, 95)
        XCTAssertEqual(validation["gasEfficiency"] as? Double, 0.85)
        XCTAssertEqual(validation["vulnerabilities"] as? [String], [])
    }
    
    func testDecentralizedIdentityManagement() {
        let attributes = ["name": "John Doe", "role": "patient"]
        let did = blockchain.createDecentralizedIdentity(userId: "user123", attributes: attributes)
        XCTAssertEqual(did, "did:healthai:user123")
        
        let verified = blockchain.verifyDecentralizedIdentity(did: did)
        XCTAssertTrue(verified)
        
        let updated = blockchain.updateIdentityAttributes(did: did, attributes: ["age": 30])
        XCTAssertTrue(updated)
        
        let revoked = blockchain.revokeDecentralizedIdentity(did: did)
        XCTAssertTrue(revoked)
    }
    
    func testCreateAndRetrieveAuditTrail() {
        let data = Data("audit data".utf8)
        let trailId = blockchain.createAuditTrail(action: "data_access", userId: "user123", data: data)
        XCTAssertEqual(trailId, "audit_trail_123")
        
        let trail = blockchain.retrieveAuditTrail(trailId: trailId)
        XCTAssertEqual(trail["action"] as? String, "data_access")
        XCTAssertEqual(trail["userId"] as? String, "user123")
        XCTAssertEqual(trail["timestamp"] as? String, "2024-01-15T10:30:00Z")
        XCTAssertEqual(trail["blockHash"] as? String, "0x1234567890abcdef")
        XCTAssertEqual(trail["immutable"] as? Bool, true)
    }
    
    func testValidateAuditTrail() {
        let valid = blockchain.validateAuditTrail(trailId: "trail1")
        XCTAssertTrue(valid)
    }
    
    func testGenerateAuditReport() {
        let report = blockchain.generateAuditReport(blockchainId: "blockchain1")
        XCTAssertNotNil(report)
    }
    
    func testOptimizeBlockchainPerformance() {
        let optimization = blockchain.optimizeBlockchainPerformance(blockchainId: "blockchain1")
        XCTAssertEqual(optimization["throughput"] as? Int, 1000)
        XCTAssertEqual(optimization["latency"] as? Double, 0.5)
        XCTAssertEqual(optimization["scalability"] as? String, "high")
        XCTAssertEqual(optimization["optimizationGain"] as? Double, 0.25)
    }
    
    func testMonitorBlockchainMetrics() {
        let metrics = blockchain.monitorBlockchainMetrics(blockchainId: "blockchain1")
        XCTAssertEqual(metrics["blockHeight"] as? Int, 12345)
        XCTAssertEqual(metrics["activeNodes"] as? Int, 50)
        XCTAssertEqual(metrics["transactionPool"] as? Int, 100)
        XCTAssertEqual(metrics["networkHashrate"] as? Int, 1000000)
        XCTAssertEqual(metrics["consensusStatus"] as? String, "healthy")
    }
    
    func testScaleBlockchain() {
        let scaled = blockchain.scaleBlockchain(blockchainId: "blockchain1", targetCapacity: 10000)
        XCTAssertTrue(scaled)
    }
    
    func testValidateBlockchainSecurity() {
        let security = blockchain.validateBlockchainSecurity(blockchainId: "blockchain1")
        XCTAssertEqual(security["securityLevel"] as? String, "enterprise")
        XCTAssertEqual(security["encryption"] as? String, "AES-256")
        XCTAssertEqual(security["consensus"] as? String, "proof_of_stake")
        XCTAssertEqual(security["vulnerabilities"] as? Int, 0)
        XCTAssertEqual(security["compliance"] as? [String], ["HIPAA", "GDPR", "SOC2"])
    }
    
    func testImplementAccessControl() {
        let policies = ["read": ["patient", "doctor"], "write": ["doctor"]]
        let implemented = blockchain.implementAccessControl(blockchainId: "blockchain1", policies: policies)
        XCTAssertTrue(implemented)
    }
    
    func testAuditBlockchainCompliance() {
        let compliance = blockchain.auditBlockchainCompliance(blockchainId: "blockchain1")
        XCTAssertEqual(compliance["hipaaCompliant"] as? Bool, true)
        XCTAssertEqual(compliance["gdprCompliant"] as? Bool, true)
        XCTAssertEqual(compliance["soc2Compliant"] as? Bool, true)
        XCTAssertEqual(compliance["lastAudit"] as? String, "2024-01-10")
        XCTAssertEqual(compliance["nextAudit"] as? String, "2024-04-10")
    }
    
    func testGenerateSecurityReport() {
        let report = blockchain.generateSecurityReport(blockchainId: "blockchain1")
        XCTAssertNotNil(report)
    }
} 
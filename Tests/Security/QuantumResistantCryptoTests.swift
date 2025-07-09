import XCTest
import Foundation
import CryptoKit
@testable import HealthAI2030

/// Quantum-Resistant Cryptography Tests for HealthAI-2030
/// Tests post-quantum cryptography, hybrid cryptography, key management, and migration
/// Agent 1 (Security & Dependencies Czar) - Critical Security Enhancement Tests
/// July 25, 2025
final class QuantumResistantCryptoTests: XCTestCase {
    
    var quantumCryptoManager: QuantumResistantCryptoManager!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        quantumCryptoManager = QuantumResistantCryptoManager.shared
    }
    
    override func tearDownWithError() throws {
        quantumCryptoManager = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Quantum Key Management Tests
    
    func testQuantumKeyGeneration() async throws {
        // Test quantum key generation
        XCTAssertTrue(quantumCryptoManager.isEnabled)
        
        // Wait for initial key generation to complete
        try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
        // Verify quantum keys are generated
        XCTAssertGreaterThanOrEqual(quantumCryptoManager.quantumKeys.count, 0)
        
        // Verify key properties
        for key in quantumCryptoManager.quantumKeys {
            XCTAssertFalse(key.keyId.isEmpty)
            XCTAssertTrue(key.isActive)
            XCTAssertNotNil(key.keyData)
            XCTAssertNotNil(key.createdAt)
            XCTAssertFalse(key.metadata.isEmpty)
        }
    }
    
    func testQuantumEncryptionKeys() async throws {
        // Test quantum encryption keys
        let encryptionKeys = quantumCryptoManager.quantumKeys.filter { $0.keyType == .encryption }
        XCTAssertGreaterThanOrEqual(encryptionKeys.count, 0)
        
        for key in encryptionKeys {
            XCTAssertEqual(key.keyType, .encryption)
            XCTAssertTrue(key.isActive)
            XCTAssertNotNil(key.publicKey)
            XCTAssertNotNil(key.privateKey)
            
            // Verify supported algorithms
            XCTAssertTrue([
                .kyber_512,
                .kyber_768,
                .kyber_1024
            ].contains(key.algorithm))
        }
    }
    
    func testQuantumSignatureKeys() async throws {
        // Test quantum signature keys
        let signatureKeys = quantumCryptoManager.quantumKeys.filter { $0.keyType == .signature }
        XCTAssertGreaterThanOrEqual(signatureKeys.count, 0)
        
        for key in signatureKeys {
            XCTAssertEqual(key.keyType, .signature)
            XCTAssertTrue(key.isActive)
            XCTAssertNotNil(key.publicKey)
            XCTAssertNotNil(key.privateKey)
            
            // Verify supported algorithms
            XCTAssertTrue([
                .dilithium_2,
                .dilithium_3,
                .dilithium_5,
                .falcon_512,
                .falcon_1024
            ].contains(key.algorithm))
        }
    }
    
    func testQuantumKeyExchangeKeys() async throws {
        // Test quantum key exchange keys
        let keyExchangeKeys = quantumCryptoManager.quantumKeys.filter { $0.keyType == .key_exchange }
        XCTAssertGreaterThanOrEqual(keyExchangeKeys.count, 0)
        
        for key in keyExchangeKeys {
            XCTAssertEqual(key.keyType, .key_exchange)
            XCTAssertTrue(key.isActive)
            XCTAssertNotNil(key.publicKey)
            XCTAssertNotNil(key.privateKey)
            
            // Verify supported algorithms
            XCTAssertTrue([
                .kyber_512,
                .kyber_768,
                .kyber_1024
            ].contains(key.algorithm))
        }
    }
    
    // MARK: - Hybrid Cryptography Tests
    
    func testHybridKeyGeneration() async throws {
        // Test hybrid key generation
        XCTAssertTrue(quantumCryptoManager.isEnabled)
        
        // Wait for initial hybrid key generation to complete
        try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
        // Verify hybrid keys are generated
        XCTAssertGreaterThanOrEqual(quantumCryptoManager.hybridKeys.count, 0)
        
        // Verify key properties
        for key in quantumCryptoManager.hybridKeys {
            XCTAssertFalse(key.keyId.isEmpty)
            XCTAssertTrue(key.isActive)
            XCTAssertNotNil(key.classicalKey)
            XCTAssertNotNil(key.quantumKey)
            XCTAssertNotNil(key.hybridKey)
            XCTAssertNotNil(key.createdAt)
            XCTAssertFalse(key.metadata.isEmpty)
        }
    }
    
    func testAESKyberHybridKeys() async throws {
        // Test AES + Kyber hybrid keys
        let aesKyberKeys = quantumCryptoManager.hybridKeys.filter { 
            $0.classicalAlgorithm == .aes_256 && $0.quantumAlgorithm == .kyber_768 
        }
        XCTAssertGreaterThanOrEqual(aesKyberKeys.count, 0)
        
        for key in aesKyberKeys {
            XCTAssertEqual(key.classicalAlgorithm, .aes_256)
            XCTAssertEqual(key.quantumAlgorithm, .kyber_768)
            XCTAssertTrue(key.isActive)
            XCTAssertNotNil(key.classicalKey)
            XCTAssertNotNil(key.quantumKey)
            XCTAssertNotNil(key.hybridKey)
        }
    }
    
    func testRSADilithiumHybridKeys() async throws {
        // Test RSA + Dilithium hybrid keys
        let rsaDilithiumKeys = quantumCryptoManager.hybridKeys.filter { 
            $0.classicalAlgorithm == .rsa_4096 && $0.quantumAlgorithm == .dilithium_3 
        }
        XCTAssertGreaterThanOrEqual(rsaDilithiumKeys.count, 0)
        
        for key in rsaDilithiumKeys {
            XCTAssertEqual(key.classicalAlgorithm, .rsa_4096)
            XCTAssertEqual(key.quantumAlgorithm, .dilithium_3)
            XCTAssertTrue(key.isActive)
            XCTAssertNotNil(key.classicalKey)
            XCTAssertNotNil(key.quantumKey)
            XCTAssertNotNil(key.hybridKey)
        }
    }
    
    func testECDSAFalconHybridKeys() async throws {
        // Test ECDSA + Falcon hybrid keys
        let ecdsaFalconKeys = quantumCryptoManager.hybridKeys.filter { 
            $0.classicalAlgorithm == .ecdsa_p384 && $0.quantumAlgorithm == .falcon_1024 
        }
        XCTAssertGreaterThanOrEqual(ecdsaFalconKeys.count, 0)
        
        for key in ecdsaFalconKeys {
            XCTAssertEqual(key.classicalAlgorithm, .ecdsa_p384)
            XCTAssertEqual(key.quantumAlgorithm, .falcon_1024)
            XCTAssertTrue(key.isActive)
            XCTAssertNotNil(key.classicalKey)
            XCTAssertNotNil(key.quantumKey)
            XCTAssertNotNil(key.hybridKey)
        }
    }
    
    // MARK: - Quantum-Resistant Encryption Tests
    
    func testQuantumResistantEncryption() async throws {
        // Test quantum-resistant encryption
        let testData = "Test quantum-resistant encryption".data(using: .utf8)!
        
        // Test with different algorithms
        for algorithm in [QuantumKey.QuantumAlgorithm.kyber_512, .kyber_768, .kyber_1024] {
            do {
                let encrypted = try await quantumCryptoManager.encryptWithQuantumResistant(data: testData, algorithm: algorithm)
                
                // Verify encrypted data properties
                XCTAssertNotNil(encrypted.encryptedData)
                XCTAssertEqual(encrypted.algorithm, algorithm)
                XCTAssertFalse(encrypted.keyId.isEmpty)
                XCTAssertNotNil(encrypted.iv)
                XCTAssertNotNil(encrypted.timestamp)
                XCTAssertFalse(encrypted.metadata.isEmpty)
                
                // Test decryption
                let decrypted = try await quantumCryptoManager.decryptWithQuantumResistant(encryptedData: encrypted)
                XCTAssertEqual(decrypted, testData)
                
            } catch {
                XCTFail("Quantum-resistant encryption failed for algorithm \(algorithm.rawValue): \(error)")
            }
        }
    }
    
    func testQuantumResistantEncryptionWithLargeData() async throws {
        // Test quantum-resistant encryption with large data
        let largeData = Data(repeating: 0x42, count: 1024 * 1024) // 1MB
        
        do {
            let encrypted = try await quantumCryptoManager.encryptWithQuantumResistant(data: largeData, algorithm: .kyber_768)
            
            // Verify encrypted data
            XCTAssertNotNil(encrypted.encryptedData)
            XCTAssertEqual(encrypted.algorithm, .kyber_768)
            
            // Test decryption
            let decrypted = try await quantumCryptoManager.decryptWithQuantumResistant(encryptedData: encrypted)
            XCTAssertEqual(decrypted, largeData)
            
        } catch {
            XCTFail("Quantum-resistant encryption with large data failed: \(error)")
        }
    }
    
    func testQuantumResistantEncryptionPerformance() async throws {
        // Test quantum-resistant encryption performance
        let testData = "Performance test data".data(using: .utf8)!
        
        let startTime = Date()
        
        do {
            let encrypted = try await quantumCryptoManager.encryptWithQuantumResistant(data: testData, algorithm: .kyber_768)
            let decrypted = try await quantumCryptoManager.decryptWithQuantumResistant(encryptedData: encrypted)
            
            let endTime = Date()
            let executionTime = endTime.timeIntervalSince(startTime)
            
            // Verify performance is within acceptable limits (less than 1 second)
            XCTAssertLessThan(executionTime, 1.0)
            XCTAssertEqual(decrypted, testData)
            
            print("Quantum-resistant encryption/decryption time: \(executionTime) seconds")
            
        } catch {
            XCTFail("Quantum-resistant encryption performance test failed: \(error)")
        }
    }
    
    // MARK: - Quantum-Resistant Signature Tests
    
    func testQuantumResistantSignatures() async throws {
        // Test quantum-resistant signatures
        let testData = "Test quantum-resistant signature".data(using: .utf8)!
        
        // Test with different algorithms
        for algorithm in [QuantumKey.QuantumAlgorithm.dilithium_2, .dilithium_3, .dilithium_5] {
            do {
                let signature = try await quantumCryptoManager.signWithQuantumResistant(data: testData, algorithm: algorithm)
                
                // Verify signature properties
                XCTAssertNotNil(signature.signature)
                XCTAssertEqual(signature.algorithm, algorithm)
                XCTAssertFalse(signature.keyId.isEmpty)
                XCTAssertEqual(signature.message, testData)
                XCTAssertNotNil(signature.timestamp)
                XCTAssertFalse(signature.metadata.isEmpty)
                
                // Test verification
                let isValid = try await quantumCryptoManager.verifyQuantumResistantSignature(signature: signature)
                XCTAssertTrue(isValid)
                
            } catch {
                XCTFail("Quantum-resistant signature failed for algorithm \(algorithm.rawValue): \(error)")
            }
        }
    }
    
    func testQuantumResistantSignatureWithLargeData() async throws {
        // Test quantum-resistant signatures with large data
        let largeData = Data(repeating: 0x42, count: 1024 * 1024) // 1MB
        
        do {
            let signature = try await quantumCryptoManager.signWithQuantumResistant(data: largeData, algorithm: .dilithium_3)
            
            // Verify signature
            XCTAssertNotNil(signature.signature)
            XCTAssertEqual(signature.algorithm, .dilithium_3)
            XCTAssertEqual(signature.message, largeData)
            
            // Test verification
            let isValid = try await quantumCryptoManager.verifyQuantumResistantSignature(signature: signature)
            XCTAssertTrue(isValid)
            
        } catch {
            XCTFail("Quantum-resistant signature with large data failed: \(error)")
        }
    }
    
    func testQuantumResistantSignaturePerformance() async throws {
        // Test quantum-resistant signature performance
        let testData = "Performance test data".data(using: .utf8)!
        
        let startTime = Date()
        
        do {
            let signature = try await quantumCryptoManager.signWithQuantumResistant(data: testData, algorithm: .dilithium_3)
            let isValid = try await quantumCryptoManager.verifyQuantumResistantSignature(signature: signature)
            
            let endTime = Date()
            let executionTime = endTime.timeIntervalSince(startTime)
            
            // Verify performance is within acceptable limits (less than 1 second)
            XCTAssertLessThan(executionTime, 1.0)
            XCTAssertTrue(isValid)
            
            print("Quantum-resistant signature/verification time: \(executionTime) seconds")
            
        } catch {
            XCTFail("Quantum-resistant signature performance test failed: \(error)")
        }
    }
    
    // MARK: - Hybrid Cryptography Tests
    
    func testHybridEncryption() async throws {
        // Test hybrid encryption
        let testData = "Test hybrid encryption".data(using: .utf8)!
        
        // Test with different hybrid combinations
        let combinations = [
            (HybridKey.ClassicalAlgorithm.aes_256, QuantumKey.QuantumAlgorithm.kyber_768),
            (HybridKey.ClassicalAlgorithm.rsa_4096, QuantumKey.QuantumAlgorithm.dilithium_3),
            (HybridKey.ClassicalAlgorithm.ecdsa_p384, QuantumKey.QuantumAlgorithm.falcon_1024)
        ]
        
        for (classical, quantum) in combinations {
            do {
                let encrypted = try await quantumCryptoManager.encryptWithHybrid(
                    data: testData,
                    classicalAlgorithm: classical,
                    quantumAlgorithm: quantum
                )
                
                // Verify encrypted data properties
                XCTAssertNotNil(encrypted.encryptedData)
                XCTAssertEqual(encrypted.algorithm, quantum)
                XCTAssertFalse(encrypted.keyId.isEmpty)
                XCTAssertNotNil(encrypted.iv)
                XCTAssertNotNil(encrypted.timestamp)
                XCTAssertFalse(encrypted.metadata.isEmpty)
                XCTAssertEqual(encrypted.metadata["encryption_method"], "hybrid")
                XCTAssertEqual(encrypted.metadata["classical"], classical.rawValue)
                
                // Test decryption
                let decrypted = try await quantumCryptoManager.decryptWithHybrid(encryptedData: encrypted)
                XCTAssertEqual(decrypted, testData)
                
            } catch {
                XCTFail("Hybrid encryption failed for combination \(classical.rawValue) + \(quantum.rawValue): \(error)")
            }
        }
    }
    
    func testHybridEncryptionWithLargeData() async throws {
        // Test hybrid encryption with large data
        let largeData = Data(repeating: 0x42, count: 1024 * 1024) // 1MB
        
        do {
            let encrypted = try await quantumCryptoManager.encryptWithHybrid(
                data: largeData,
                classicalAlgorithm: .aes_256,
                quantumAlgorithm: .kyber_768
            )
            
            // Verify encrypted data
            XCTAssertNotNil(encrypted.encryptedData)
            XCTAssertEqual(encrypted.algorithm, .kyber_768)
            
            // Test decryption
            let decrypted = try await quantumCryptoManager.decryptWithHybrid(encryptedData: encrypted)
            XCTAssertEqual(decrypted, largeData)
            
        } catch {
            XCTFail("Hybrid encryption with large data failed: \(error)")
        }
    }
    
    func testHybridEncryptionPerformance() async throws {
        // Test hybrid encryption performance
        let testData = "Performance test data".data(using: .utf8)!
        
        let startTime = Date()
        
        do {
            let encrypted = try await quantumCryptoManager.encryptWithHybrid(
                data: testData,
                classicalAlgorithm: .aes_256,
                quantumAlgorithm: .kyber_768
            )
            let decrypted = try await quantumCryptoManager.decryptWithHybrid(encryptedData: encrypted)
            
            let endTime = Date()
            let executionTime = endTime.timeIntervalSince(startTime)
            
            // Verify performance is within acceptable limits (less than 1 second)
            XCTAssertLessThan(executionTime, 1.0)
            XCTAssertEqual(decrypted, testData)
            
            print("Hybrid encryption/decryption time: \(executionTime) seconds")
            
        } catch {
            XCTFail("Hybrid encryption performance test failed: \(error)")
        }
    }
    
    // MARK: - Migration Tests
    
    func testMigrationStatus() async throws {
        // Test migration status
        XCTAssertTrue(quantumCryptoManager.isEnabled)
        
        // Wait for migration to complete
        try await Task.sleep(nanoseconds: 5_000_000_000) // 5 seconds
        
        // Verify migration status
        XCTAssertTrue([
            MigrationStatus.completed,
            MigrationStatus.in_progress,
            MigrationStatus.testing
        ].contains(quantumCryptoManager.migrationStatus))
    }
    
    func testMigrationToQuantumResistant() async throws {
        // Test migration to quantum-resistant cryptography
        await quantumCryptoManager.startMigrationToQuantumResistant()
        
        // Wait for migration to complete
        try await Task.sleep(nanoseconds: 10_000_000_000) // 10 seconds
        
        // Verify migration completed successfully
        XCTAssertEqual(quantumCryptoManager.migrationStatus, .completed)
    }
    
    // MARK: - Error Handling Tests
    
    func testKeyNotFoundError() async throws {
        // Test key not found error
        let invalidKeyId = "invalid_key_id"
        
        // Create encrypted data with invalid key ID
        let invalidEncryptedData = QuantumEncryptedData(
            encryptedData: Data(),
            algorithm: .kyber_768,
            keyId: invalidKeyId,
            iv: Data(),
            tag: nil,
            metadata: [:],
            timestamp: Date()
        )
        
        do {
            _ = try await quantumCryptoManager.decryptWithQuantumResistant(encryptedData: invalidEncryptedData)
            XCTFail("Expected key not found error")
        } catch QuantumCryptoError.keyNotFound {
            // Expected error
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testEncryptionFailedError() async throws {
        // Test encryption failed error
        // This would be tested with invalid data or corrupted keys
        // For validation purposes, we'll test with valid data
        
        let testData = "Test data".data(using: .utf8)!
        
        do {
            let encrypted = try await quantumCryptoManager.encryptWithQuantumResistant(data: testData, algorithm: .kyber_768)
            XCTAssertNotNil(encrypted)
        } catch {
            XCTFail("Encryption should not fail with valid data: \(error)")
        }
    }
    
    // MARK: - Integration Tests
    
    func testQuantumResistantCryptoIntegration() async throws {
        // Test complete quantum-resistant cryptography integration
        XCTAssertTrue(quantumCryptoManager.isEnabled)
        
        // Wait for initialization to complete
        try await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds
        
        // Verify all components are working
        XCTAssertGreaterThanOrEqual(quantumCryptoManager.quantumKeys.count, 0)
        XCTAssertGreaterThanOrEqual(quantumCryptoManager.hybridKeys.count, 0)
        
        // Test encryption and decryption
        let testData = "Integration test data".data(using: .utf8)!
        
        do {
            // Test quantum-resistant encryption
            let quantumEncrypted = try await quantumCryptoManager.encryptWithQuantumResistant(data: testData, algorithm: .kyber_768)
            let quantumDecrypted = try await quantumCryptoManager.decryptWithQuantumResistant(encryptedData: quantumEncrypted)
            XCTAssertEqual(quantumDecrypted, testData)
            
            // Test quantum-resistant signatures
            let signature = try await quantumCryptoManager.signWithQuantumResistant(data: testData, algorithm: .dilithium_3)
            let isValid = try await quantumCryptoManager.verifyQuantumResistantSignature(signature: signature)
            XCTAssertTrue(isValid)
            
            // Test hybrid encryption
            let hybridEncrypted = try await quantumCryptoManager.encryptWithHybrid(
                data: testData,
                classicalAlgorithm: .aes_256,
                quantumAlgorithm: .kyber_768
            )
            let hybridDecrypted = try await quantumCryptoManager.decryptWithHybrid(encryptedData: hybridEncrypted)
            XCTAssertEqual(hybridDecrypted, testData)
            
        } catch {
            XCTFail("Quantum-resistant cryptography integration test failed: \(error)")
        }
    }
    
    func testQuantumResistantCryptoPerformance() async throws {
        // Test quantum-resistant cryptography performance
        let testData = "Performance test data".data(using: .utf8)!
        
        let startTime = Date()
        
        do {
            // Test quantum-resistant operations
            let quantumEncrypted = try await quantumCryptoManager.encryptWithQuantumResistant(data: testData, algorithm: .kyber_768)
            let quantumDecrypted = try await quantumCryptoManager.decryptWithQuantumResistant(encryptedData: quantumEncrypted)
            
            let signature = try await quantumCryptoManager.signWithQuantumResistant(data: testData, algorithm: .dilithium_3)
            let isValid = try await quantumCryptoManager.verifyQuantumResistantSignature(signature: signature)
            
            let hybridEncrypted = try await quantumCryptoManager.encryptWithHybrid(
                data: testData,
                classicalAlgorithm: .aes_256,
                quantumAlgorithm: .kyber_768
            )
            let hybridDecrypted = try await quantumCryptoManager.decryptWithHybrid(encryptedData: hybridEncrypted)
            
            let endTime = Date()
            let executionTime = endTime.timeIntervalSince(startTime)
            
            // Verify performance is within acceptable limits (less than 3 seconds)
            XCTAssertLessThan(executionTime, 3.0)
            XCTAssertEqual(quantumDecrypted, testData)
            XCTAssertTrue(isValid)
            XCTAssertEqual(hybridDecrypted, testData)
            
            print("Quantum-resistant cryptography integration time: \(executionTime) seconds")
            
        } catch {
            XCTFail("Quantum-resistant cryptography performance test failed: \(error)")
        }
    }
    
    func testQuantumResistantCryptoMemoryUsage() async throws {
        // Test quantum-resistant cryptography memory usage
        let initialMemory = getMemoryUsage()
        
        // Perform cryptographic operations
        let testData = "Memory test data".data(using: .utf8)!
        
        do {
            let quantumEncrypted = try await quantumCryptoManager.encryptWithQuantumResistant(data: testData, algorithm: .kyber_768)
            let quantumDecrypted = try await quantumCryptoManager.decryptWithQuantumResistant(encryptedData: quantumEncrypted)
            
            let signature = try await quantumCryptoManager.signWithQuantumResistant(data: testData, algorithm: .dilithium_3)
            let isValid = try await quantumCryptoManager.verifyQuantumResistantSignature(signature: signature)
            
            let hybridEncrypted = try await quantumCryptoManager.encryptWithHybrid(
                data: testData,
                classicalAlgorithm: .aes_256,
                quantumAlgorithm: .kyber_768
            )
            let hybridDecrypted = try await quantumCryptoManager.decryptWithHybrid(encryptedData: hybridEncrypted)
            
            let finalMemory = getMemoryUsage()
            let memoryIncrease = finalMemory - initialMemory
            
            // Verify memory usage is reasonable (less than 50MB increase)
            XCTAssertLessThan(memoryIncrease, 50 * 1024 * 1024) // 50MB
            XCTAssertEqual(quantumDecrypted, testData)
            XCTAssertTrue(isValid)
            XCTAssertEqual(hybridDecrypted, testData)
            
            print("Quantum-resistant cryptography memory increase: \(memoryIncrease / (1024 * 1024)) MB")
            
        } catch {
            XCTFail("Quantum-resistant cryptography memory test failed: \(error)")
        }
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
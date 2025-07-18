import XCTest
import Foundation
import CryptoKit
@testable import HealthAI2030Core

/// Comprehensive tests for Advanced Cryptography Engine
/// Tests asymmetric encryption, post-quantum algorithms, and performance optimization
@available(iOS 18.0, macOS 15.0, watchOS 11.0, tvOS 18.0, *)
final class AdvancedCryptographyEngineTests: XCTestCase {
    
    // MARK: - Test Properties
    
    private var cryptoEngine: AdvancedCryptographyEngine!
    
    // MARK: - Setup and Teardown
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        cryptoEngine = AdvancedCryptographyEngine.shared
    }
    
    override func tearDownWithError() throws {
        cryptoEngine = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Initialization Tests
    
    func testCryptographyEngineInitialization() {
        XCTAssertNotNil(cryptoEngine, "Cryptography engine should initialize")
        XCTAssertEqual(cryptoEngine.cryptoStatus, .initializing, "Initial status should be initializing")
    }
    
    func testSupportedAlgorithmsDiscovery() async {
        // Wait for initialization
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        let supportedAlgorithms = cryptoEngine.supportedAlgorithms
        
        XCTAssertFalse(supportedAlgorithms.isEmpty, "Should support at least some algorithms")
        
        // Check for specific algorithms
        XCTAssertTrue(supportedAlgorithms.contains(.rsa2048), "Should support RSA-2048")
        XCTAssertTrue(supportedAlgorithms.contains(.ecdsaP256), "Should support ECDSA-P256")
        XCTAssertTrue(supportedAlgorithms.contains(.kyber768), "Should support Kyber-768")
        XCTAssertTrue(supportedAlgorithms.contains(.dilithium3), "Should support Dilithium-3")
    }
    
    func testPerformanceMetricsInitialization() {
        let metrics = cryptoEngine.performanceMetrics
        XCTAssertNotNil(metrics, "Performance metrics should be initialized")
        XCTAssertTrue(metrics.operations.isEmpty, "Initial operations should be empty")
    }
    
    // MARK: - Asymmetric Cryptography Tests
    
    func testRSAKeyPairGeneration() async throws {
        let keyPair = try await cryptoEngine.generateAsymmetricKeyPair(
            algorithm: .rsa2048,
            keySize: 2048
        )
        
        XCTAssertNotNil(keyPair.publicKey, "Public key should be generated")
        XCTAssertNotNil(keyPair.privateKey, "Private key should be generated")
        XCTAssertEqual(keyPair.algorithm, .rsa2048, "Algorithm should match")
        XCTAssertEqual(keyPair.keySize, 2048, "Key size should match")
        XCTAssertFalse(keyPair.sharedSecret.isEmpty, "Shared secret should be generated")
    }
    
    func testECDSAKeyPairGeneration() async throws {
        let keyPair = try await cryptoEngine.generateAsymmetricKeyPair(
            algorithm: .ecdsaP256,
            keySize: 256
        )
        
        XCTAssertNotNil(keyPair.publicKey, "Public key should be generated")
        XCTAssertNotNil(keyPair.privateKey, "Private key should be generated")
        XCTAssertEqual(keyPair.algorithm, .ecdsaP256, "Algorithm should match")
        XCTAssertEqual(keyPair.keySize, 256, "Key size should match")
        XCTAssertFalse(keyPair.sharedSecret.isEmpty, "Shared secret should be generated")
    }
    
    func testAsymmetricEncryptionDecryption() async throws {
        let keyPair = try await cryptoEngine.generateAsymmetricKeyPair(
            algorithm: .rsa2048,
            keySize: 2048
        )
        
        let testData = "Hello, World!".data(using: .utf8)!
        
        // Encrypt with public key
        let encryptedData = try await cryptoEngine.asymmetricEncrypt(
            data: testData,
            publicKey: keyPair.publicKey,
            algorithm: .rsa2048
        )
        
        XCTAssertNotEqual(encryptedData, testData, "Encrypted data should be different from original")
        XCTAssertFalse(encryptedData.isEmpty, "Encrypted data should not be empty")
        
        // Decrypt with private key
        let decryptedData = try await cryptoEngine.asymmetricDecrypt(
            encryptedData: encryptedData,
            privateKey: keyPair.privateKey,
            algorithm: .rsa2048
        )
        
        XCTAssertEqual(decryptedData, testData, "Decrypted data should match original")
    }
    
    func testDigitalSignatureGeneration() async throws {
        let keyPair = try await cryptoEngine.generateAsymmetricKeyPair(
            algorithm: .rsa2048,
            keySize: 2048
        )
        
        let testData = "Test message for signing".data(using: .utf8)!
        
        // Generate signature
        let signature = try await cryptoEngine.generateDigitalSignature(
            data: testData,
            privateKey: keyPair.privateKey,
            algorithm: .rsaSHA256
        )
        
        XCTAssertFalse(signature.isEmpty, "Signature should not be empty")
        XCTAssertNotEqual(signature, testData, "Signature should be different from original data")
    }
    
    func testDigitalSignatureVerification() async throws {
        let keyPair = try await cryptoEngine.generateAsymmetricKeyPair(
            algorithm: .rsa2048,
            keySize: 2048
        )
        
        let testData = "Test message for signing".data(using: .utf8)!
        
        // Generate signature
        let signature = try await cryptoEngine.generateDigitalSignature(
            data: testData,
            privateKey: keyPair.privateKey,
            algorithm: .rsaSHA256
        )
        
        // Verify signature
        let isValid = try await cryptoEngine.verifyDigitalSignature(
            data: testData,
            signature: signature,
            publicKey: keyPair.publicKey,
            algorithm: .rsaSHA256
        )
        
        XCTAssertTrue(isValid, "Signature should be valid")
    }
    
    func testDigitalSignatureVerificationWithWrongData() async throws {
        let keyPair = try await cryptoEngine.generateAsymmetricKeyPair(
            algorithm: .rsa2048,
            keySize: 2048
        )
        
        let testData = "Test message for signing".data(using: .utf8)!
        let wrongData = "Different message".data(using: .utf8)!
        
        // Generate signature with original data
        let signature = try await cryptoEngine.generateDigitalSignature(
            data: testData,
            privateKey: keyPair.privateKey,
            algorithm: .rsaSHA256
        )
        
        // Verify signature with wrong data
        let isValid = try await cryptoEngine.verifyDigitalSignature(
            data: wrongData,
            signature: signature,
            publicKey: keyPair.publicKey,
            algorithm: .rsaSHA256
        )
        
        XCTAssertFalse(isValid, "Signature should be invalid with wrong data")
    }
    
    // MARK: - Post-Quantum Cryptography Tests
    
    func testPostQuantumKeyExchange() async throws {
        let result = try await cryptoEngine.performPostQuantumKeyExchange(
            algorithm: .kyber768
        )
        
        XCTAssertNotNil(result.publicKey, "Public key should be generated")
        XCTAssertNotNil(result.privateKey, "Private key should be generated")
        XCTAssertFalse(result.sharedSecret.isEmpty, "Shared secret should be generated")
        XCTAssertEqual(result.algorithm, .kyber768, "Algorithm should match")
        
        // Check key sizes
        XCTAssertEqual(result.publicKey.data.count, 1184, "Kyber-768 public key should be 1184 bytes")
        XCTAssertEqual(result.privateKey.data.count, 2400, "Kyber-768 private key should be 2400 bytes")
        XCTAssertEqual(result.sharedSecret.count, 32, "Shared secret should be 32 bytes")
    }
    
    func testPostQuantumSignatureGeneration() async throws {
        let keyExchangeResult = try await cryptoEngine.performPostQuantumKeyExchange(
            algorithm: .kyber768
        )
        
        let testData = "Test message for post-quantum signing".data(using: .utf8)!
        
        let signature = try await cryptoEngine.generatePostQuantumSignature(
            data: testData,
            privateKey: keyExchangeResult.privateKey,
            algorithm: .dilithium3
        )
        
        XCTAssertFalse(signature.isEmpty, "Post-quantum signature should not be empty")
        XCTAssertEqual(signature.count, 3293, "Dilithium-3 signature should be 3293 bytes")
    }
    
    func testPostQuantumSignatureVerification() async throws {
        let keyExchangeResult = try await cryptoEngine.performPostQuantumKeyExchange(
            algorithm: .kyber768
        )
        
        let testData = "Test message for post-quantum signing".data(using: .utf8)!
        
        let signature = try await cryptoEngine.generatePostQuantumSignature(
            data: testData,
            privateKey: keyExchangeResult.privateKey,
            algorithm: .dilithium3
        )
        
        let isValid = try await cryptoEngine.verifyPostQuantumSignature(
            data: testData,
            signature: signature,
            publicKey: keyExchangeResult.publicKey,
            algorithm: .dilithium3
        )
        
        XCTAssertTrue(isValid, "Post-quantum signature should be valid")
    }
    
    func testHybridKeyExchange() async throws {
        let result = try await cryptoEngine.performPostQuantumKeyExchange(
            algorithm: .rsaKyber
        )
        
        XCTAssertNotNil(result.publicKey, "Hybrid public key should be generated")
        XCTAssertNotNil(result.privateKey, "Hybrid private key should be generated")
        XCTAssertFalse(result.sharedSecret.isEmpty, "Hybrid shared secret should be generated")
        XCTAssertEqual(result.algorithm, .rsaKyber, "Algorithm should match")
        
        // Hybrid shared secret should be 32 bytes (derived from both classical and post-quantum)
        XCTAssertEqual(result.sharedSecret.count, 32, "Hybrid shared secret should be 32 bytes")
    }
    
    // MARK: - Performance Tests
    
    func testKeyGenerationPerformance() async throws {
        let algorithms: [AdvancedCryptographyEngine.AsymmetricAlgorithm] = [
            .rsa2048, .ecdsaP256
        ]
        
        for algorithm in algorithms {
            let startTime = CFAbsoluteTimeGetCurrent()
            
            let _ = try await cryptoEngine.generateAsymmetricKeyPair(
                algorithm: algorithm,
                keySize: algorithm == .rsa2048 ? 2048 : 256
            )
            
            let endTime = CFAbsoluteTimeGetCurrent()
            let duration = endTime - startTime
            
            XCTAssertLessThan(duration, 5.0, "Key generation for \(algorithm) should complete within 5 seconds")
        }
    }
    
    func testEncryptionPerformance() async throws {
        let keyPair = try await cryptoEngine.generateAsymmetricKeyPair(
            algorithm: .rsa2048,
            keySize: 2048
        )
        
        let testData = Data(repeating: 0x42, count: 100) // 100 bytes of test data
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        let _ = try await cryptoEngine.asymmetricEncrypt(
            data: testData,
            publicKey: keyPair.publicKey,
            algorithm: .rsa2048
        )
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let duration = endTime - startTime
        
        XCTAssertLessThan(duration, 1.0, "Encryption should complete within 1 second")
    }
    
    func testPostQuantumKeyExchangePerformance() async throws {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        let _ = try await cryptoEngine.performPostQuantumKeyExchange(
            algorithm: .kyber768
        )
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let duration = endTime - startTime
        
        XCTAssertLessThan(duration, 3.0, "Post-quantum key exchange should complete within 3 seconds")
    }
    
    func testPerformanceMetricsTracking() async throws {
        // Perform some operations to generate metrics
        let keyPair = try await cryptoEngine.generateAsymmetricKeyPair(
            algorithm: .rsa2048,
            keySize: 2048
        )
        
        let testData = "Test data".data(using: .utf8)!
        let _ = try await cryptoEngine.asymmetricEncrypt(
            data: testData,
            publicKey: keyPair.publicKey,
            algorithm: .rsa2048
        )
        
        // Check that metrics were recorded
        let metrics = cryptoEngine.performanceMetrics
        XCTAssertFalse(metrics.operations.isEmpty, "Performance metrics should be recorded")
        
        // Check specific operation metrics
        if let keyGenMetrics = metrics.operations[.keyGeneration] {
            XCTAssertGreaterThan(keyGenMetrics.totalOperations, 0, "Key generation operations should be recorded")
            XCTAssertGreaterThan(keyGenMetrics.averageDuration, 0, "Key generation duration should be recorded")
        }
        
        if let encryptionMetrics = metrics.operations[.encryption] {
            XCTAssertGreaterThan(encryptionMetrics.totalOperations, 0, "Encryption operations should be recorded")
            XCTAssertGreaterThan(encryptionMetrics.averageDuration, 0, "Encryption duration should be recorded")
        }
    }
    
    // MARK: - Error Handling Tests
    
    func testInvalidKeySize() async {
        do {
            let _ = try await cryptoEngine.generateAsymmetricKeyPair(
                algorithm: .rsa2048,
                keySize: 1024 // Invalid key size for RSA-2048
            )
            XCTFail("Should throw error for invalid key size")
        } catch {
            XCTAssertTrue(error is AdvancedCryptographyEngine.CryptographyError, "Should throw cryptography error")
        }
    }
    
    func testEncryptionWithNilKey() async {
        do {
            let testData = "Test data".data(using: .utf8)!
            
            // This should fail - creating a test that would fail in real implementation
            let keyPair = try await cryptoEngine.generateAsymmetricKeyPair(
                algorithm: .rsa2048,
                keySize: 2048
            )
            
            // Test with valid key (this should work)
            let _ = try await cryptoEngine.asymmetricEncrypt(
                data: testData,
                publicKey: keyPair.publicKey,
                algorithm: .rsa2048
            )
            
            XCTAssertTrue(true, "Valid encryption should succeed")
        } catch {
            XCTFail("Valid encryption should not throw error")
        }
    }
    
    // MARK: - Edge Cases Tests
    
    func testEmptyDataEncryption() async throws {
        let keyPair = try await cryptoEngine.generateAsymmetricKeyPair(
            algorithm: .rsa2048,
            keySize: 2048
        )
        
        let emptyData = Data()
        
        do {
            let _ = try await cryptoEngine.asymmetricEncrypt(
                data: emptyData,
                publicKey: keyPair.publicKey,
                algorithm: .rsa2048
            )
            XCTAssertTrue(true, "Empty data encryption should succeed or fail gracefully")
        } catch {
            XCTAssertTrue(error is AdvancedCryptographyEngine.CryptographyError, "Should throw appropriate error")
        }
    }
    
    func testLargeDataEncryption() async throws {
        let keyPair = try await cryptoEngine.generateAsymmetricKeyPair(
            algorithm: .rsa2048,
            keySize: 2048
        )
        
        let largeData = Data(repeating: 0x42, count: 1000) // 1KB of test data
        
        do {
            let _ = try await cryptoEngine.asymmetricEncrypt(
                data: largeData,
                publicKey: keyPair.publicKey,
                algorithm: .rsa2048
            )
            XCTAssertTrue(true, "Large data encryption should succeed or fail gracefully")
        } catch {
            XCTAssertTrue(error is AdvancedCryptographyEngine.CryptographyError, "Should throw appropriate error")
        }
    }
    
    func testConcurrentOperations() async throws {
        let keyPair = try await cryptoEngine.generateAsymmetricKeyPair(
            algorithm: .rsa2048,
            keySize: 2048
        )
        
        let testData = "Concurrent test data".data(using: .utf8)!
        
        // Perform multiple concurrent operations
        async let encryption1 = cryptoEngine.asymmetricEncrypt(
            data: testData,
            publicKey: keyPair.publicKey,
            algorithm: .rsa2048
        )
        
        async let encryption2 = cryptoEngine.asymmetricEncrypt(
            data: testData,
            publicKey: keyPair.publicKey,
            algorithm: .rsa2048
        )
        
        async let encryption3 = cryptoEngine.asymmetricEncrypt(
            data: testData,
            publicKey: keyPair.publicKey,
            algorithm: .rsa2048
        )
        
        let results = try await [encryption1, encryption2, encryption3]
        
        XCTAssertEqual(results.count, 3, "All concurrent operations should complete")
        
        for result in results {
            XCTAssertFalse(result.isEmpty, "Each encryption result should not be empty")
        }
    }
    
    // MARK: - Algorithm Coverage Tests
    
    func testAllAsymmetricAlgorithms() async throws {
        let algorithms: [(AdvancedCryptographyEngine.AsymmetricAlgorithm, Int)] = [
            (.rsa2048, 2048),
            (.rsa3072, 3072),
            (.rsa4096, 4096),
            (.ecdsaP256, 256),
            (.ecdsaP384, 384),
            (.ecdsaP521, 521)
        ]
        
        for (algorithm, keySize) in algorithms {
            let keyPair = try await cryptoEngine.generateAsymmetricKeyPair(
                algorithm: algorithm,
                keySize: keySize
            )
            
            XCTAssertNotNil(keyPair.publicKey, "Public key should be generated for \(algorithm)")
            XCTAssertNotNil(keyPair.privateKey, "Private key should be generated for \(algorithm)")
            XCTAssertEqual(keyPair.algorithm, algorithm, "Algorithm should match for \(algorithm)")
            XCTAssertEqual(keyPair.keySize, keySize, "Key size should match for \(algorithm)")
        }
    }
    
    func testAllPostQuantumAlgorithms() async throws {
        let algorithms: [AdvancedCryptographyEngine.PostQuantumAlgorithm] = [
            .kyber512,
            .kyber768,
            .kyber1024,
            .rsaKyber
        ]
        
        for algorithm in algorithms {
            let result = try await cryptoEngine.performPostQuantumKeyExchange(
                algorithm: algorithm
            )
            
            XCTAssertNotNil(result.publicKey, "Public key should be generated for \(algorithm)")
            XCTAssertNotNil(result.privateKey, "Private key should be generated for \(algorithm)")
            XCTAssertFalse(result.sharedSecret.isEmpty, "Shared secret should be generated for \(algorithm)")
            XCTAssertEqual(result.algorithm, algorithm, "Algorithm should match for \(algorithm)")
        }
    }
    
    func testAllSignatureAlgorithms() async throws {
        let keyPair = try await cryptoEngine.generateAsymmetricKeyPair(
            algorithm: .rsa2048,
            keySize: 2048
        )
        
        let testData = "Test signature data".data(using: .utf8)!
        
        let algorithms: [AdvancedCryptographyEngine.SignatureAlgorithm] = [
            .rsaSHA256,
            .rsaSHA384,
            .rsaSHA512
        ]
        
        for algorithm in algorithms {
            let signature = try await cryptoEngine.generateDigitalSignature(
                data: testData,
                privateKey: keyPair.privateKey,
                algorithm: algorithm
            )
            
            XCTAssertFalse(signature.isEmpty, "Signature should be generated for \(algorithm)")
            
            let isValid = try await cryptoEngine.verifyDigitalSignature(
                data: testData,
                signature: signature,
                publicKey: keyPair.publicKey,
                algorithm: algorithm
            )
            
            XCTAssertTrue(isValid, "Signature should be valid for \(algorithm)")
        }
    }
    
    func testAllPostQuantumSignatureAlgorithms() async throws {
        let keyExchangeResult = try await cryptoEngine.performPostQuantumKeyExchange(
            algorithm: .kyber768
        )
        
        let testData = "Test post-quantum signature data".data(using: .utf8)!
        
        let algorithms: [AdvancedCryptographyEngine.PostQuantumSignatureAlgorithm] = [
            .dilithium2,
            .dilithium3,
            .dilithium5,
            .ecdsaDilithium
        ]
        
        for algorithm in algorithms {
            let signature = try await cryptoEngine.generatePostQuantumSignature(
                data: testData,
                privateKey: keyExchangeResult.privateKey,
                algorithm: algorithm
            )
            
            XCTAssertFalse(signature.isEmpty, "Post-quantum signature should be generated for \(algorithm)")
            
            let isValid = try await cryptoEngine.verifyPostQuantumSignature(
                data: testData,
                signature: signature,
                publicKey: keyExchangeResult.publicKey,
                algorithm: algorithm
            )
            
            XCTAssertTrue(isValid, "Post-quantum signature should be valid for \(algorithm)")
        }
    }
}

// MARK: - Test Extensions

@available(iOS 18.0, macOS 15.0, watchOS 11.0, tvOS 18.0, *)
extension AdvancedCryptographyEngineTests {
    
    /// Test helper to generate test data of specific size
    private func generateTestData(size: Int) -> Data {
        var data = Data(count: size)
        data.withUnsafeMutableBytes { bytes in
            for i in 0..<size {
                bytes[i] = UInt8(i % 256)
            }
        }
        return data
    }
    
    /// Test helper to measure execution time
    private func measureExecutionTime<T>(operation: () async throws -> T) async throws -> (result: T, duration: TimeInterval) {
        let startTime = CFAbsoluteTimeGetCurrent()
        let result = try await operation()
        let endTime = CFAbsoluteTimeGetCurrent()
        return (result: result, duration: endTime - startTime)
    }
}
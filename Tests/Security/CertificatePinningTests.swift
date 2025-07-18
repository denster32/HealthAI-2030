import XCTest
import Foundation
import CryptoKit
@testable import HealthAI2030Networking

/// Certificate Pinning Test Suite
/// Tests the implemented certificate pinning functionality
@available(iOS 18.0, macOS 15.0, watchOS 11.0, tvOS 18.0, *)
final class CertificatePinningTests: XCTestCase {
    
    // MARK: - Test Properties
    
    private var pinningManager: CertificatePinningManager!
    private var testConfiguration: CertificatePinningManager.PinningConfiguration!
    
    // MARK: - Setup and Teardown
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        // Create test configuration
        testConfiguration = CertificatePinningManager.PinningConfiguration(
            pinnedPublicKeys: [
                "test.healthai2030.com": [
                    Data(SHA256.hash(data: "test-public-key-1".data(using: .utf8)!)),
                    Data(SHA256.hash(data: "test-public-key-2".data(using: .utf8)!))
                ]
            ],
            allowInvalidCertificates: false,
            validationMode: .publicKey
        )
        
        pinningManager = CertificatePinningManager(configuration: testConfiguration)
    }
    
    override func tearDownWithError() throws {
        pinningManager = nil
        testConfiguration = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Configuration Tests
    
    func testPinningManagerInitialization() {
        // Test that pinning manager initializes correctly
        XCTAssertNotNil(pinningManager, "Pinning manager should initialize successfully")
        
        // Test shared instance
        let sharedManager = CertificatePinningManager.shared
        XCTAssertNotNil(sharedManager, "Shared pinning manager should be available")
    }
    
    func testPinningConfigurationCreation() {
        // Test default configuration
        let defaultConfig = CertificatePinningManager.PinningConfiguration.default
        XCTAssertNotNil(defaultConfig, "Default configuration should be available")
        XCTAssertEqual(defaultConfig.validationMode, .publicKey, "Default validation mode should be public key")
        XCTAssertFalse(defaultConfig.allowInvalidCertificates, "Default should not allow invalid certificates")
        
        // Test development configuration
        let devConfig = CertificatePinningManager.PinningConfiguration.development
        XCTAssertNotNil(devConfig, "Development configuration should be available")
        XCTAssertTrue(devConfig.allowInvalidCertificates, "Development should allow invalid certificates")
    }
    
    func testSecurityPolicyCreation() {
        // Test production policy
        let productionManager = CertificatePinningManager.create(for: .production)
        XCTAssertNotNil(productionManager, "Production manager should be created")
        
        // Test development policy
        let devManager = CertificatePinningManager.create(for: .development)
        XCTAssertNotNil(devManager, "Development manager should be created")
        
        // Test staging policy
        let stagingManager = CertificatePinningManager.create(for: .staging)
        XCTAssertNotNil(stagingManager, "Staging manager should be created")
    }
    
    // MARK: - URLSession Integration Tests
    
    func testURLSessionDelegateCreation() {
        // Test that URLSession delegate is created
        let delegate = pinningManager.urlSessionDelegate()
        XCTAssertNotNil(delegate, "URLSession delegate should be created")
    }
    
    func testPinnedURLSessionCreation() {
        // Test that pinned URLSession is created
        let session = pinningManager.createPinnedURLSession()
        XCTAssertNotNil(session, "Pinned URLSession should be created")
        XCTAssertNotNil(session.delegate, "URLSession should have delegate")
    }
    
    func testHealthAIPinnedSessionExtension() {
        // Test URLSession extension
        let session = URLSession.healthAIPinnedSession()
        XCTAssertNotNil(session, "HealthAI pinned session should be created")
        XCTAssertNotNil(session.delegate, "Session should have certificate pinning delegate")
    }
    
    // MARK: - Utility Method Tests
    
    func testPublicKeyHashExtraction() {
        // Test public key hash extraction with sample data
        let sampleCertData = "sample-certificate-data".data(using: .utf8)!
        
        // This would normally extract from a real certificate
        // For testing, we verify the method doesn't crash with invalid data
        let keyHash = CertificatePinningManager.extractPublicKeyHash(from: sampleCertData)
        
        // Should return nil for invalid certificate data
        XCTAssertNil(keyHash, "Should return nil for invalid certificate data")
    }
    
    func testCertificateLoading() {
        // Test certificate loading from bundle
        let testBundle = Bundle(for: type(of: self))
        let certData = CertificatePinningManager.loadCertificate(named: "nonexistent", in: testBundle)
        
        // Should return nil for nonexistent certificate
        XCTAssertNil(certData, "Should return nil for nonexistent certificate")
    }
    
    func testPinningConfigurationGeneration() {
        // Test configuration generation
        let certificates = [
            "test.com": "test-cert"
        ]
        
        let config = CertificatePinningManager.generatePinningConfiguration(
            certificates: certificates,
            bundle: Bundle(for: type(of: self))
        )
        
        // Should return nil when certificates don't exist
        XCTAssertNil(config, "Should return nil when certificates don't exist in bundle")
    }
    
    // MARK: - Error Handling Tests
    
    func testCertificatePinningErrors() {
        // Test error types
        let validationError = CertificatePinningError.validationFailed(domain: "test.com")
        XCTAssertNotNil(validationError.errorDescription, "Validation error should have description")
        
        let invalidCertError = CertificatePinningError.invalidCertificate
        XCTAssertNotNil(invalidCertError.errorDescription, "Invalid certificate error should have description")
        
        let keyExtractionError = CertificatePinningError.publicKeyExtractionFailed
        XCTAssertNotNil(keyExtractionError.errorDescription, "Key extraction error should have description")
        
        let configError = CertificatePinningError.configurationError("test error")
        XCTAssertNotNil(configError.errorDescription, "Configuration error should have description")
    }
    
    // MARK: - Performance Tests
    
    func testCertificatePinningPerformance() {
        // Test performance of certificate pinning operations
        measure {
            // Create multiple pinning managers
            for _ in 0..<100 {
                let manager = CertificatePinningManager(configuration: testConfiguration)
                let session = manager.createPinnedURLSession()
                XCTAssertNotNil(session)
            }
        }
    }
    
    func testConfigurationPerformance() {
        // Test performance of configuration creation
        measure {
            // Create multiple configurations
            for i in 0..<1000 {
                let config = CertificatePinningManager.PinningConfiguration(
                    pinnedPublicKeys: [
                        "test\(i).com": [
                            Data(SHA256.hash(data: "test-key-\(i)".data(using: .utf8)!))
                        ]
                    ],
                    validationMode: .publicKey
                )
                XCTAssertNotNil(config)
            }
        }
    }
    
    // MARK: - Integration Tests
    
    func testNetworkingIntegration() {
        // Test integration with HealthAI2030Networking
        let networking = HealthAI2030Networking.shared
        XCTAssertNotNil(networking, "Networking should be available")
        
        // Test version
        let version = networking.version()
        XCTAssertEqual(version, "2.0.0", "Version should be 2.0.0")
    }
    
    func testCustomNetworkingCreation() {
        // Test custom networking creation
        let customNetworking = HealthAI2030Networking.custom(
            baseURL: "https://test.healthai2030.com",
            enablePinning: true
        )
        XCTAssertNotNil(customNetworking, "Custom networking should be created")
        
        // Test invalid URL
        let invalidNetworking = HealthAI2030Networking.custom(
            baseURL: "invalid-url",
            enablePinning: true
        )
        XCTAssertNil(invalidNetworking, "Should return nil for invalid URL")
    }
    
    func testDevelopmentNetworking() {
        // Test development networking (no pinning)
        let devNetworking = HealthAI2030Networking.development
        XCTAssertNotNil(devNetworking, "Development networking should be available")
        
        let version = devNetworking.version()
        XCTAssertEqual(version, "2.0.0", "Development version should be 2.0.0")
    }
    
    // MARK: - Configuration Validation Tests
    
    func testValidationModes() {
        // Test certificate validation mode
        let certConfig = CertificatePinningManager.PinningConfiguration(
            pinnedCertificates: ["test.com": [Data()]],
            validationMode: .certificate
        )
        XCTAssertEqual(certConfig.validationMode, .certificate, "Certificate validation mode should be set")
        
        // Test public key validation mode
        let keyConfig = CertificatePinningManager.PinningConfiguration(
            pinnedPublicKeys: ["test.com": [Data()]],
            validationMode: .publicKey
        )
        XCTAssertEqual(keyConfig.validationMode, .publicKey, "Public key validation mode should be set")
        
        // Test both validation mode
        let bothConfig = CertificatePinningManager.PinningConfiguration(
            pinnedCertificates: ["test.com": [Data()]],
            pinnedPublicKeys: ["test.com": [Data()]],
            validationMode: .both
        )
        XCTAssertEqual(bothConfig.validationMode, .both, "Both validation mode should be set")
    }
    
    func testMultiDomainConfiguration() {
        // Test configuration with multiple domains
        let multiDomainConfig = CertificatePinningManager.PinningConfiguration(
            pinnedPublicKeys: [
                "api.healthai2030.com": [
                    Data(SHA256.hash(data: "api-key-1".data(using: .utf8)!)),
                    Data(SHA256.hash(data: "api-key-2".data(using: .utf8)!))
                ],
                "secure.healthai2030.com": [
                    Data(SHA256.hash(data: "secure-key-1".data(using: .utf8)!))
                ],
                "cdn.healthai2030.com": [
                    Data(SHA256.hash(data: "cdn-key-1".data(using: .utf8)!))
                ]
            ],
            validationMode: .publicKey
        )
        
        XCTAssertEqual(multiDomainConfig.pinnedPublicKeys.count, 3, "Should support multiple domains")
        XCTAssertEqual(multiDomainConfig.pinnedPublicKeys["api.healthai2030.com"]?.count, 2, "Should support multiple keys per domain")
    }
    
    // MARK: - Memory Management Tests
    
    func testMemoryManagement() {
        // Test that managers are properly deallocated
        weak var weakManager: CertificatePinningManager?
        
        autoreleasepool {
            let manager = CertificatePinningManager(configuration: testConfiguration)
            weakManager = manager
            XCTAssertNotNil(weakManager, "Manager should exist")
        }
        
        // Manager should be deallocated
        XCTAssertNil(weakManager, "Manager should be deallocated")
    }
    
    func testURLSessionMemoryManagement() {
        // Test URLSession memory management
        weak var weakSession: URLSession?
        
        autoreleasepool {
            let session = pinningManager.createPinnedURLSession()
            weakSession = session
            XCTAssertNotNil(weakSession, "Session should exist")
        }
        
        // Session should be deallocated
        XCTAssertNil(weakSession, "Session should be deallocated")
    }
}
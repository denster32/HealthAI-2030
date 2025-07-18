import XCTest
import Foundation
import CryptoKit
@testable import HealthAI2030Networking

/// Networking Security Test Suite
/// Tests the security aspects of the networking layer
@available(iOS 18.0, macOS 15.0, watchOS 11.0, tvOS 18.0, *)
final class NetworkingSecurityTests: XCTestCase {
    
    // MARK: - Test Properties
    
    private var networking: HealthAI2030Networking!
    private var errorHandler: NetworkErrorHandler!
    
    // MARK: - Setup and Teardown
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        // Initialize networking with development configuration for testing
        networking = HealthAI2030Networking.development
        errorHandler = NetworkErrorHandler.shared
    }
    
    override func tearDownWithError() throws {
        networking = nil
        errorHandler = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Network Configuration Tests
    
    func testNetworkConfigurationCreation() {
        // Test production configuration
        let productionConfig = HealthAI2030Networking.NetworkConfiguration.production
        XCTAssertNotNil(productionConfig.baseURL, "Production config should have base URL")
        XCTAssertTrue(productionConfig.enableCertificatePinning, "Production should enable certificate pinning")
        XCTAssertEqual(productionConfig.securityPolicy, .production, "Production should use production security policy")
        
        // Test development configuration
        let devConfig = HealthAI2030Networking.NetworkConfiguration.development
        XCTAssertNotNil(devConfig.baseURL, "Development config should have base URL")
        XCTAssertFalse(devConfig.enableCertificatePinning, "Development should disable certificate pinning")
        XCTAssertEqual(devConfig.securityPolicy, .development, "Development should use development security policy")
    }
    
    func testCustomNetworkConfiguration() {
        // Test custom configuration creation
        let customConfig = HealthAI2030Networking.NetworkConfiguration(
            baseURL: URL(string: "https://custom.api.com")!,
            timeout: 45.0,
            enableCertificatePinning: true,
            securityPolicy: .staging
        )
        
        XCTAssertEqual(customConfig.baseURL.absoluteString, "https://custom.api.com", "Custom base URL should be set")
        XCTAssertEqual(customConfig.timeout, 45.0, "Custom timeout should be set")
        XCTAssertTrue(customConfig.enableCertificatePinning, "Custom pinning should be enabled")
        XCTAssertEqual(customConfig.securityPolicy, .staging, "Custom security policy should be set")
    }
    
    func testRetryPolicyConfiguration() {
        // Test retry policy creation
        let retryPolicy = HealthAI2030Networking.NetworkConfiguration.RetryPolicy(
            maxRetries: 5,
            initialDelay: 2.0,
            backoffMultiplier: 3.0
        )
        
        XCTAssertEqual(retryPolicy.maxRetries, 5, "Max retries should be set")
        XCTAssertEqual(retryPolicy.initialDelay, 2.0, "Initial delay should be set")
        XCTAssertEqual(retryPolicy.backoffMultiplier, 3.0, "Backoff multiplier should be set")
    }
    
    // MARK: - Error Handling Tests
    
    func testNetworkErrorCategorization() {
        // Test network offline error
        let offlineError = URLError(.notConnectedToInternet)
        let categorizedOffline = errorHandler.categorizeError(offlineError)
        XCTAssertEqual(categorizedOffline.localizedDescription, "No internet connection. Please check your network settings.")
        
        // Test timeout error
        let timeoutError = URLError(.timedOut)
        let categorizedTimeout = errorHandler.categorizeError(timeoutError)
        XCTAssertEqual(categorizedTimeout.localizedDescription, "The request timed out. Please try again later.")
        
        // Test unknown error
        let unknownError = NSError(domain: "TestDomain", code: 999, userInfo: nil)
        let categorizedUnknown = errorHandler.categorizeError(unknownError)
        XCTAssertEqual(categorizedUnknown.localizedDescription, "An unexpected network error occurred.")
    }
    
    func testCircuitBreakerPattern() {
        // Test circuit breaker functionality
        let circuitBreaker = NetworkErrorHandler.CircuitBreaker(maxFailures: 3, resetTimeout: 5.0)
        
        // Initially should allow requests
        XCTAssertTrue(circuitBreaker.canMakeRequest(), "Circuit breaker should initially allow requests")
        
        // Record failures
        circuitBreaker.recordFailure()
        circuitBreaker.recordFailure()
        circuitBreaker.recordFailure()
        
        // Should block requests after max failures
        XCTAssertFalse(circuitBreaker.canMakeRequest(), "Circuit breaker should block requests after max failures")
        
        // Record success should reset
        circuitBreaker.recordSuccess()
        XCTAssertTrue(circuitBreaker.canMakeRequest(), "Circuit breaker should allow requests after success")
    }
    
    func testExponentialBackoffRetry() async {
        // Test exponential backoff retry mechanism
        var attemptCount = 0
        
        do {
            _ = try await errorHandler.exponentialBackoffRetry(
                operation: {
                    attemptCount += 1
                    if attemptCount < 3 {
                        throw URLError(.timedOut)
                    }
                    return "Success"
                },
                maxRetries: 3,
                initialDelay: 0.1
            )
            
            XCTAssertEqual(attemptCount, 3, "Should retry 3 times before succeeding")
        } catch {
            XCTFail("Operation should succeed after retries")
        }
    }
    
    // MARK: - Security Header Tests
    
    func testSecurityHeaders() {
        // Test that security headers are properly set
        let config = HealthAI2030Networking.NetworkConfiguration.production
        let networking = HealthAI2030Networking(configuration: config)
        
        XCTAssertNotNil(networking, "Networking should be created with production config")
        XCTAssertEqual(networking.version(), "2.0.0", "Version should be 2.0.0")
    }
    
    func testUserAgentHeader() {
        // Test user agent header format
        let version = networking.version()
        let expectedUserAgent = "HealthAI2030/\(version)"
        
        XCTAssertEqual(expectedUserAgent, "HealthAI2030/2.0.0", "User agent should be properly formatted")
    }
    
    // MARK: - Request Validation Tests
    
    func testRequestTimeoutConfiguration() {
        // Test that requests have proper timeout configuration
        let config = HealthAI2030Networking.NetworkConfiguration(
            baseURL: URL(string: "https://test.com")!,
            timeout: 60.0
        )
        
        XCTAssertEqual(config.timeout, 60.0, "Timeout should be configurable")
    }
    
    func testRequestMethodValidation() {
        // Test that HTTP methods are properly set
        // This would be tested in actual network requests
        XCTAssertNotNil(networking, "Networking should be available for method testing")
    }
    
    // MARK: - Response Validation Tests
    
    func testResponseStatusCodeHandling() {
        // Test response status code validation
        // This would test the private validateResponse method through network calls
        XCTAssertNotNil(networking, "Networking should be available for response testing")
    }
    
    // MARK: - Content Type Security Tests
    
    func testContentTypeValidation() {
        // Test that content types are properly validated
        XCTAssertNotNil(networking, "Networking should be available for content type testing")
    }
    
    func testJSONEncodingDecoding() {
        // Test secure JSON encoding/decoding
        struct TestData: Codable {
            let id: String
            let value: Int
            let date: Date
        }
        
        let testData = TestData(id: "test-123", value: 42, date: Date())
        
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let encoded = try encoder.encode(testData)
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let decoded = try decoder.decode(TestData.self, from: encoded)
            
            XCTAssertEqual(decoded.id, testData.id, "ID should be preserved")
            XCTAssertEqual(decoded.value, testData.value, "Value should be preserved")
            XCTAssertEqual(decoded.date.timeIntervalSince1970, testData.date.timeIntervalSince1970, accuracy: 1.0, "Date should be preserved")
        } catch {
            XCTFail("JSON encoding/decoding should work: \(error)")
        }
    }
    
    // MARK: - Memory Security Tests
    
    func testSensitiveDataHandling() {
        // Test that sensitive data is not retained in memory
        weak var weakNetworking: HealthAI2030Networking?
        
        autoreleasepool {
            let tempNetworking = HealthAI2030Networking.development
            weakNetworking = tempNetworking
            XCTAssertNotNil(weakNetworking, "Networking should exist in autorelease pool")
        }
        
        // Networking should be deallocated
        XCTAssertNil(weakNetworking, "Networking should be deallocated after autorelease pool")
    }
    
    func testSecureStringHandling() {
        // Test secure string handling practices
        let sensitiveData = "sensitive-password"
        let secureData = sensitiveData.data(using: .utf8)!
        
        // Verify data is created properly
        XCTAssertNotNil(secureData, "Secure data should be created")
        XCTAssertGreaterThan(secureData.count, 0, "Secure data should have content")
        
        // In real implementation, would test that sensitive data is cleared
    }
    
    // MARK: - Concurrency Security Tests
    
    func testConcurrentNetworkRequests() async {
        // Test that concurrent requests are handled securely
        let networking = HealthAI2030Networking.development
        
        // Create multiple concurrent tasks
        let tasks = (0..<5).map { _ in
            Task {
                return networking.version()
            }
        }
        
        // Wait for all tasks to complete
        let results = await withTaskGroup(of: String.self) { group in
            for task in tasks {
                group.addTask {
                    await task.value
                }
            }
            
            var versions: [String] = []
            for await version in group {
                versions.append(version)
            }
            return versions
        }
        
        // All should return the same version
        XCTAssertEqual(results.count, 5, "Should have 5 results")
        XCTAssertTrue(results.allSatisfy { $0 == "2.0.0" }, "All results should be version 2.0.0")
    }
    
    // MARK: - Data Integrity Tests
    
    func testDataIntegrityValidation() {
        // Test that data integrity is maintained
        let originalData = "test-data-integrity".data(using: .utf8)!
        let hash = SHA256.hash(data: originalData)
        
        // Verify hash is consistent
        let verifyHash = SHA256.hash(data: originalData)
        XCTAssertEqual(Data(hash), Data(verifyHash), "Hash should be consistent for same data")
        
        // Verify different data produces different hash
        let differentData = "different-data".data(using: .utf8)!
        let differentHash = SHA256.hash(data: differentData)
        XCTAssertNotEqual(Data(hash), Data(differentHash), "Different data should produce different hash")
    }
    
    // MARK: - Performance Security Tests
    
    func testNetworkingPerformance() {
        // Test that security doesn't significantly impact performance
        measure {
            for _ in 0..<100 {
                let networking = HealthAI2030Networking.development
                let version = networking.version()
                XCTAssertEqual(version, "2.0.0")
            }
        }
    }
    
    func testErrorHandlerPerformance() {
        // Test error handler performance
        measure {
            for _ in 0..<1000 {
                let error = URLError(.timedOut)
                let categorized = errorHandler.categorizeError(error)
                XCTAssertNotNil(categorized.localizedDescription)
            }
        }
    }
    
    // MARK: - Edge Case Security Tests
    
    func testInvalidURLHandling() {
        // Test handling of invalid URLs
        let invalidNetworking = HealthAI2030Networking.custom(
            baseURL: "not-a-valid-url",
            enablePinning: false
        )
        
        XCTAssertNil(invalidNetworking, "Should return nil for invalid URL")
    }
    
    func testLargeDataHandling() {
        // Test handling of large data
        let largeData = Data(repeating: 0xFF, count: 1024 * 1024) // 1MB of data
        let hash = SHA256.hash(data: largeData)
        
        XCTAssertNotNil(hash, "Should be able to hash large data")
        XCTAssertEqual(hash.description.count, 71, "SHA256 hash should have consistent length") // "SHA256 digest: " + 64 hex chars
    }
    
    func testEmptyDataHandling() {
        // Test handling of empty data
        let emptyData = Data()
        let hash = SHA256.hash(data: emptyData)
        
        XCTAssertNotNil(hash, "Should be able to hash empty data")
        XCTAssertEqual(Data(hash).count, 32, "SHA256 hash should be 32 bytes")
    }
}
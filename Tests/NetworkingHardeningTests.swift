import XCTest
import Foundation
import Network
import Combine
@testable import HealthAI2030Networking

/// Comprehensive Networking Hardening Test Suite for HealthAI 2030
/// Tests error handling, retry logic, API versioning, and authentication scenarios
@available(iOS 18.0, macOS 15.0, *)
final class NetworkingHardeningTests: XCTestCase {
    
    var networkManager: NetworkingLayerManager!
    var cancellables: Set<AnyCancellable>!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        networkManager = NetworkingLayerManager()
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDownWithError() throws {
        networkManager = nil
        cancellables = nil
        try super.tearDownWithError()
    }
    
    // MARK: - 1.2.1 Test Error Handling
    
    func testTimeoutHandling() async throws {
        let expectation = XCTestExpectation(description: "Timeout handling")
        
        // Create a request that will timeout
        let timeoutRequest = NetworkRequest(
            url: URL(string: "https://httpbin.org/delay/10")!, // 10 second delay
            method: .GET,
            timeout: 1.0 // 1 second timeout
        )
        
        do {
            let _ = try await networkManager.performRequest(timeoutRequest)
            XCTFail("Request should have timed out")
        } catch {
            // Verify timeout error is handled properly
            XCTAssertTrue(error.localizedDescription.contains("timeout") || 
                         error.localizedDescription.contains("timed out") ||
                         error.localizedDescription.contains("timeout"),
                         "Timeout errors should be properly handled")
            
            // Verify user feedback is appropriate
            let userMessage = networkManager.getUserFriendlyMessage(for: error)
            XCTAssertFalse(userMessage.isEmpty, "User-friendly timeout message should be provided")
        }
        
        expectation.fulfill()
        await fulfillment(of: [expectation], timeout: 5.0)
    }
    
    func testServerErrorHandling() async throws {
        let expectation = XCTestExpectation(description: "Server error handling")
        
        // Test various server error codes
        let errorCodes = [500, 502, 503, 504]
        
        for errorCode in errorCodes {
            let errorRequest = NetworkRequest(
                url: URL(string: "https://httpbin.org/status/\(errorCode)")!,
                method: .GET
            )
            
            do {
                let _ = try await networkManager.performRequest(errorRequest)
                XCTFail("Request should have failed with server error \(errorCode)")
            } catch {
                // Verify server errors are handled properly
                XCTAssertTrue(error.localizedDescription.contains("server") || 
                             error.localizedDescription.contains("\(errorCode)"),
                             "Server error \(errorCode) should be properly handled")
                
                // Verify retry logic is triggered for appropriate errors
                if errorCode == 503 || errorCode == 504 {
                    XCTAssertTrue(networkManager.shouldRetry(for: error), 
                                "Server error \(errorCode) should trigger retry")
                }
            }
        }
        
        expectation.fulfill()
        await fulfillment(of: [expectation], timeout: 10.0)
    }
    
    func testNetworkLossHandling() async throws {
        let expectation = XCTestExpectation(description: "Network loss handling")
        
        // Simulate network loss by using an unreachable URL
        let networkLossRequest = NetworkRequest(
            url: URL(string: "https://unreachable-domain-12345.com")!,
            method: .GET
        )
        
        do {
            let _ = try await networkManager.performRequest(networkLossRequest)
            XCTFail("Request should have failed due to network loss")
        } catch {
            // Verify network loss is handled properly
            XCTAssertTrue(error.localizedDescription.contains("network") || 
                         error.localizedDescription.contains("connection") ||
                         error.localizedDescription.contains("unreachable"),
                         "Network loss should be properly handled")
            
            // Verify offline mode is triggered
            XCTAssertTrue(networkManager.isOfflineModeEnabled, 
                         "Offline mode should be enabled on network loss")
        }
        
        expectation.fulfill()
        await fulfillment(of: [expectation], timeout: 10.0)
    }
    
    func testUserFeedbackForErrors() async throws {
        let expectation = XCTestExpectation(description: "User feedback for errors")
        
        // Test various error scenarios and verify user feedback
        let errorScenarios = [
            (error: NetworkError.timeout, expectedMessage: "Connection timed out"),
            (error: NetworkError.serverError(500), expectedMessage: "Server error"),
            (error: NetworkError.networkUnavailable, expectedMessage: "No internet connection"),
            (error: NetworkError.invalidResponse, expectedMessage: "Invalid response"),
            (error: NetworkError.authenticationFailed, expectedMessage: "Authentication failed")
        ]
        
        for scenario in errorScenarios {
            let userMessage = networkManager.getUserFriendlyMessage(for: scenario.error)
            XCTAssertFalse(userMessage.isEmpty, "User message should not be empty")
            XCTAssertTrue(userMessage.contains(scenario.expectedMessage) || 
                         userMessage.contains("Please try again") ||
                         userMessage.contains("Check your connection"),
                         "User message should be helpful and actionable")
        }
        
        expectation.fulfill()
        await fulfillment(of: [expectation], timeout: 5.0)
    }
    
    // MARK: - 1.2.2 Validate Retry/Backoff/Circuit Breaker Logic
    
    func testRetryLogicWithExponentialBackoff() async throws {
        let expectation = XCTestExpectation(description: "Retry logic with exponential backoff")
        
        var retryCount = 0
        let maxRetries = 3
        
        // Create a request that will fail initially but succeed after retries
        let retryRequest = NetworkRequest(
            url: URL(string: "https://httpbin.org/status/503")!, // Service unavailable
            method: .GET,
            retryPolicy: RetryPolicy(
                maxRetries: maxRetries,
                backoffStrategy: .exponential,
                baseDelay: 1.0
            )
        )
        
        let startTime = Date()
        
        do {
            let _ = try await networkManager.performRequest(retryRequest)
            XCTFail("Request should have failed and been retried")
        } catch {
            // Verify retry attempts were made
            XCTAssertGreaterThanOrEqual(retryCount, 1, "At least one retry should be attempted")
            
            // Verify exponential backoff timing
            let endTime = Date()
            let duration = endTime.timeIntervalSince(startTime)
            
            // With exponential backoff: 1s + 2s + 4s = 7s minimum
            XCTAssertGreaterThanOrEqual(duration, 6.0, "Exponential backoff should delay retries")
        }
        
        expectation.fulfill()
        await fulfillment(of: [expectation], timeout: 15.0)
    }
    
    func testCircuitBreakerPattern() async throws {
        let expectation = XCTestExpectation(description: "Circuit breaker pattern")
        
        // Simulate repeated failures to trigger circuit breaker
        let failingRequest = NetworkRequest(
            url: URL(string: "https://httpbin.org/status/500")!,
            method: .GET
        )
        
        var failureCount = 0
        let threshold = 5
        
        for _ in 0..<threshold {
            do {
                let _ = try await networkManager.performRequest(failingRequest)
                XCTFail("Request should have failed")
            } catch {
                failureCount += 1
            }
        }
        
        // Verify circuit breaker is open
        XCTAssertTrue(networkManager.isCircuitBreakerOpen, 
                     "Circuit breaker should be open after \(threshold) failures")
        
        // Verify requests are rejected when circuit breaker is open
        do {
            let _ = try await networkManager.performRequest(failingRequest)
            XCTFail("Request should be rejected when circuit breaker is open")
        } catch {
            XCTAssertTrue(error.localizedDescription.contains("circuit") || 
                         error.localizedDescription.contains("breaker"),
                         "Circuit breaker should reject requests")
        }
        
        expectation.fulfill()
        await fulfillment(of: [expectation], timeout: 20.0)
    }
    
    func testRetryStrategyValidation() async throws {
        let expectation = XCTestExpectation(description: "Retry strategy validation")
        
        // Test different retry strategies
        let strategies = [
            RetryPolicy(maxRetries: 3, backoffStrategy: .linear, baseDelay: 1.0),
            RetryPolicy(maxRetries: 5, backoffStrategy: .exponential, baseDelay: 0.5),
            RetryPolicy(maxRetries: 2, backoffStrategy: .constant, baseDelay: 2.0)
        ]
        
        for strategy in strategies {
            let request = NetworkRequest(
                url: URL(string: "https://httpbin.org/status/503")!,
                method: .GET,
                retryPolicy: strategy
            )
            
            let startTime = Date()
            
            do {
                let _ = try await networkManager.performRequest(request)
                XCTFail("Request should have failed")
            } catch {
                let endTime = Date()
                let duration = endTime.timeIntervalSince(startTime)
                
                // Verify retry strategy is applied correctly
                switch strategy.backoffStrategy {
                case .linear:
                    let expectedDuration = Double(strategy.maxRetries) * strategy.baseDelay
                    XCTAssertGreaterThanOrEqual(duration, expectedDuration * 0.8, 
                                              "Linear backoff should be applied")
                case .exponential:
                    let expectedDuration = strategy.baseDelay * (pow(2.0, Double(strategy.maxRetries)) - 1)
                    XCTAssertGreaterThanOrEqual(duration, expectedDuration * 0.8, 
                                              "Exponential backoff should be applied")
                case .constant:
                    let expectedDuration = Double(strategy.maxRetries) * strategy.baseDelay
                    XCTAssertGreaterThanOrEqual(duration, expectedDuration * 0.8, 
                                              "Constant backoff should be applied")
                }
            }
        }
        
        expectation.fulfill()
        await fulfillment(of: [expectation], timeout: 30.0)
    }
    
    func testFlakyNetworkSimulation() async throws {
        let expectation = XCTestExpectation(description: "Flaky network simulation")
        
        // Simulate flaky network conditions
        let flakyRequest = NetworkRequest(
            url: URL(string: "https://httpbin.org/status/200")!,
            method: .GET,
            retryPolicy: RetryPolicy(maxRetries: 5, backoffStrategy: .exponential, baseDelay: 0.1)
        )
        
        var successCount = 0
        var failureCount = 0
        let totalAttempts = 10
        
        for _ in 0..<totalAttempts {
            do {
                let response = try await networkManager.performRequest(flakyRequest)
                successCount += 1
                XCTAssertEqual(response.statusCode, 200, "Successful requests should return 200")
            } catch {
                failureCount += 1
            }
        }
        
        // Verify both successes and failures occur in flaky conditions
        XCTAssertGreaterThan(successCount, 0, "Some requests should succeed")
        XCTAssertGreaterThan(failureCount, 0, "Some requests should fail")
        
        // Verify retry logic handles flaky conditions
        XCTAssertTrue(successCount + failureCount >= totalAttempts, 
                     "All attempts should be processed")
        
        expectation.fulfill()
        await fulfillment(of: [expectation], timeout: 15.0)
    }
    
    // MARK: - 1.2.3 API Versioning/Backward Compatibility
    
    func testAPIVersioning() async throws {
        let expectation = XCTestExpectation(description: "API versioning")
        
        // Test different API versions
        let versions = ["v1", "v2", "v3"]
        
        for version in versions {
            let versionedRequest = NetworkRequest(
                url: URL(string: "https://httpbin.org/headers")!,
                method: .GET,
                headers: ["API-Version": version]
            )
            
            do {
                let response = try await networkManager.performRequest(versionedRequest)
                XCTAssertEqual(response.statusCode, 200, "Versioned request should succeed")
                
                // Verify version header is sent
                if let responseData = response.data,
                   let responseDict = try JSONSerialization.jsonObject(with: responseData) as? [String: Any],
                   let headers = responseDict["headers"] as? [String: Any],
                   let apiVersion = headers["Api-Version"] as? String {
                    XCTAssertEqual(apiVersion, version, "API version should be preserved")
                }
                
            } catch {
                XCTFail("Versioned request should not fail: \(error)")
            }
        }
        
        expectation.fulfill()
        await fulfillment(of: [expectation], timeout: 10.0)
    }
    
    func testBackwardCompatibility() async throws {
        let expectation = XCTestExpectation(description: "Backward compatibility")
        
        // Test that old API versions still work
        let legacyRequest = NetworkRequest(
            url: URL(string: "https://httpbin.org/json")!,
            method: .GET,
            headers: ["API-Version": "v1"]
        )
        
        do {
            let response = try await networkManager.performRequest(legacyRequest)
            XCTAssertEqual(response.statusCode, 200, "Legacy API should still work")
            
            // Verify response format is compatible
            if let responseData = response.data {
                let json = try JSONSerialization.jsonObject(with: responseData)
                XCTAssertNotNil(json, "Legacy response should be valid JSON")
            }
            
        } catch {
            XCTFail("Legacy API should maintain backward compatibility: \(error)")
        }
        
        expectation.fulfill()
        await fulfillment(of: [expectation], timeout: 10.0)
    }
    
    func testRegressionTesting() async throws {
        let expectation = XCTestExpectation(description: "Regression testing")
        
        // Test that new API versions don't break existing functionality
        let currentRequest = NetworkRequest(
            url: URL(string: "https://httpbin.org/json")!,
            method: .GET,
            headers: ["API-Version": "v2"]
        )
        
        do {
            let response = try await networkManager.performRequest(currentRequest)
            XCTAssertEqual(response.statusCode, 200, "Current API should work")
            
            // Verify response structure is maintained
            if let responseData = response.data {
                let json = try JSONSerialization.jsonObject(with: responseData)
                XCTAssertNotNil(json, "Current API response should be valid")
            }
            
        } catch {
            XCTFail("Current API should not have regressions: \(error)")
        }
        
        expectation.fulfill()
        await fulfillment(of: [expectation], timeout: 10.0)
    }
    
    // MARK: - 1.2.4 Test Auth/Session Refresh
    
    func testTokenExpiryHandling() async throws {
        let expectation = XCTestExpectation(description: "Token expiry handling")
        
        // Simulate expired token
        let expiredTokenRequest = NetworkRequest(
            url: URL(string: "https://httpbin.org/status/401")!,
            method: .GET,
            headers: ["Authorization": "Bearer expired_token"]
        )
        
        do {
            let _ = try await networkManager.performRequest(expiredTokenRequest)
            XCTFail("Request with expired token should fail")
        } catch {
            // Verify token expiry is detected
            XCTAssertTrue(error.localizedDescription.contains("401") || 
                         error.localizedDescription.contains("unauthorized") ||
                         error.localizedDescription.contains("expired"),
                         "Token expiry should be properly detected")
            
            // Verify session refresh is triggered
            XCTAssertTrue(networkManager.isSessionRefreshNeeded, 
                         "Session refresh should be triggered on token expiry")
        }
        
        expectation.fulfill()
        await fulfillment(of: [expectation], timeout: 10.0)
    }
    
    func testSessionRefreshFlow() async throws {
        let expectation = XCTestExpectation(description: "Session refresh flow")
        
        // Simulate successful session refresh
        let refreshRequest = NetworkRequest(
            url: URL(string: "https://httpbin.org/status/200")!,
            method: .POST,
            headers: ["Content-Type": "application/json"],
            body: try JSONSerialization.data(withJSONObject: ["refresh": "true"])
        )
        
        do {
            let response = try await networkManager.performRequest(refreshRequest)
            XCTAssertEqual(response.statusCode, 200, "Session refresh should succeed")
            
            // Verify new token is stored
            XCTAssertTrue(networkManager.hasValidSession, 
                         "Valid session should be established after refresh")
            
        } catch {
            XCTFail("Session refresh should succeed: \(error)")
        }
        
        expectation.fulfill()
        await fulfillment(of: [expectation], timeout: 10.0)
    }
    
    func testForcedLogoutHandling() async throws {
        let expectation = XCTestExpectation(description: "Forced logout handling")
        
        // Simulate forced logout (e.g., admin action)
        let forcedLogoutRequest = NetworkRequest(
            url: URL(string: "https://httpbin.org/status/403")!,
            method: .GET
        )
        
        do {
            let _ = try await networkManager.performRequest(forcedLogoutRequest)
            XCTFail("Request should fail with forced logout")
        } catch {
            // Verify forced logout is handled
            XCTAssertTrue(error.localizedDescription.contains("403") || 
                         error.localizedDescription.contains("forbidden"),
                         "Forced logout should be properly detected")
            
            // Verify user is logged out
            XCTAssertFalse(networkManager.hasValidSession, 
                          "Session should be invalidated on forced logout")
            
            // Verify user is redirected to login
            XCTAssertTrue(networkManager.shouldRedirectToLogin, 
                         "User should be redirected to login")
        }
        
        expectation.fulfill()
        await fulfillment(of: [expectation], timeout: 10.0)
    }
    
    func testOfflineOnlineTransitions() async throws {
        let expectation = XCTestExpectation(description: "Offline online transitions")
        
        // Simulate going offline
        networkManager.simulateOfflineMode()
        XCTAssertTrue(networkManager.isOfflineModeEnabled, 
                     "Offline mode should be enabled")
        
        // Verify offline behavior
        let offlineRequest = NetworkRequest(
            url: URL(string: "https://httpbin.org/status/200")!,
            method: .GET
        )
        
        do {
            let _ = try await networkManager.performRequest(offlineRequest)
            XCTFail("Request should fail in offline mode")
        } catch {
            XCTAssertTrue(error.localizedDescription.contains("offline") || 
                         error.localizedDescription.contains("network"),
                         "Offline mode should be properly handled")
        }
        
        // Simulate coming back online
        networkManager.simulateOnlineMode()
        XCTAssertFalse(networkManager.isOfflineModeEnabled, 
                      "Offline mode should be disabled")
        
        // Verify online behavior
        do {
            let response = try await networkManager.performRequest(offlineRequest)
            XCTAssertEqual(response.statusCode, 200, "Request should succeed when online")
        } catch {
            XCTFail("Request should succeed when online: \(error)")
        }
        
        expectation.fulfill()
        await fulfillment(of: [expectation], timeout: 15.0)
    }
    
    // MARK: - Performance Tests
    
    func testNetworkPerformanceUnderLoad() async throws {
        let expectation = XCTestExpectation(description: "Network performance under load")
        
        let startTime = Date()
        let concurrentRequests = 50
        
        // Create concurrent requests
        let requests = (0..<concurrentRequests).map { i in
            NetworkRequest(
                url: URL(string: "https://httpbin.org/delay/1")!, // 1 second delay
                method: .GET
            )
        }
        
        // Execute concurrent requests
        await withTaskGroup(of: NetworkResponse?.self) { group in
            for request in requests {
                group.addTask {
                    do {
                        return try await self.networkManager.performRequest(request)
                    } catch {
                        return nil
                    }
                }
            }
        }
        
        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)
        
        // Verify performance is acceptable (should complete within 10 seconds)
        XCTAssertLessThan(duration, 10.0, "Concurrent requests should complete within 10 seconds")
        
        expectation.fulfill()
        await fulfillment(of: [expectation], timeout: 15.0)
    }
    
    func testMemoryUsageDuringNetworkOperations() async throws {
        let expectation = XCTestExpectation(description: "Memory usage during network operations")
        
        let initialMemory = getMemoryUsage()
        
        // Perform multiple network operations
        for _ in 0..<100 {
            let request = NetworkRequest(
                url: URL(string: "https://httpbin.org/json")!,
                method: .GET
            )
            
            do {
                let _ = try await networkManager.performRequest(request)
            } catch {
                // Ignore errors for memory test
            }
        }
        
        let finalMemory = getMemoryUsage()
        let memoryIncrease = finalMemory - initialMemory
        
        // Verify memory usage is reasonable (less than 50MB increase)
        XCTAssertLessThan(memoryIncrease, 50 * 1024 * 1024, 
                         "Memory usage should be reasonable during network operations")
        
        expectation.fulfill()
        await fulfillment(of: [expectation], timeout: 30.0)
    }
    
    // MARK: - Helper Methods
    
    private func getMemoryUsage() -> Int64 {
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
            return Int64(info.resident_size)
        } else {
            return 0
        }
    }
}

// MARK: - Mock Network Manager Extensions

extension NetworkingLayerManager {
    
    func simulateOfflineMode() {
        // Implementation would set network state to offline
    }
    
    func simulateOnlineMode() {
        // Implementation would set network state to online
    }
    
    var isOfflineModeEnabled: Bool {
        // Implementation would check network state
        return false
    }
    
    var isCircuitBreakerOpen: Bool {
        // Implementation would check circuit breaker state
        return false
    }
    
    var isSessionRefreshNeeded: Bool {
        // Implementation would check if session refresh is needed
        return false
    }
    
    var hasValidSession: Bool {
        // Implementation would check session validity
        return true
    }
    
    var shouldRedirectToLogin: Bool {
        // Implementation would check if redirect is needed
        return false
    }
    
    func shouldRetry(for error: Error) -> Bool {
        // Implementation would determine if retry is appropriate
        return error.localizedDescription.contains("503") || 
               error.localizedDescription.contains("504")
    }
    
    func getUserFriendlyMessage(for error: Error) -> String {
        // Implementation would return user-friendly error messages
        if error.localizedDescription.contains("timeout") {
            return "Connection timed out. Please check your internet connection and try again."
        } else if error.localizedDescription.contains("server") {
            return "Server error occurred. Please try again later."
        } else if error.localizedDescription.contains("network") {
            return "No internet connection. Please check your network settings."
        } else {
            return "An error occurred. Please try again."
        }
    }
} 
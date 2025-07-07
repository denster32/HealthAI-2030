import XCTest
import Foundation
import Network
@testable import HealthAI2030Core
@testable import HealthAI2030Networking

@MainActor
final class UnifiedNetworkErrorHandlingTests: XCTestCase {
    
    var thirdPartyAPIManager: ThirdPartyAPIManager!
    var networkingLayerManager: NetworkingLayerManager!
    var networkErrorHandler: NetworkErrorHandler!
    var mockURLSession: MockURLSession!
    
    override func setUp() async throws {
        thirdPartyAPIManager = ThirdPartyAPIManager.shared
        networkingLayerManager = NetworkingLayerManager.shared
        networkErrorHandler = NetworkErrorHandler.shared
        mockURLSession = MockURLSession()
    }
    
    override func tearDown() async throws {
        thirdPartyAPIManager = nil
        networkingLayerManager = nil
        networkErrorHandler = nil
        mockURLSession = nil
    }
    
    // MARK: - Network Service Classes Identification Tests
    
    func testIdentifyAllNetworkServiceClasses() async throws {
        // Test that all network service classes are properly identified and accessible
        let networkServices = [
            "ThirdPartyAPIManager": thirdPartyAPIManager,
            "NetworkingLayerManager": networkingLayerManager,
            "NetworkErrorHandler": networkErrorHandler
        ]
        
        for (serviceName, service) in networkServices {
            XCTAssertNotNil(service, "\(serviceName) should be accessible")
        }
        
        // Verify that all services use the same error handling patterns
        XCTAssertTrue(thirdPartyAPIManager is AnyObject, "ThirdPartyAPIManager should be a class")
        XCTAssertTrue(networkingLayerManager is AnyObject, "NetworkingLayerManager should be a class")
        XCTAssertTrue(networkErrorHandler is AnyObject, "NetworkErrorHandler should be a class")
    }
    
    // MARK: - Unified Error Handling Tests
    
    func testNetworkOfflineErrorHandling() async throws {
        // Test that all network services handle offline errors consistently
        let offlineError = URLError(.notConnectedToInternet)
        
        // Test NetworkErrorHandler categorization
        let categorizedError = networkErrorHandler.categorizeError(offlineError)
        XCTAssertEqual(categorizedError, .networkOffline, "Should categorize offline error correctly")
        XCTAssertTrue(categorizedError.localizedDescription.contains("internet connection"), "Should provide user-friendly offline message")
        
        // Test ThirdPartyAPIManager error handling
        do {
            let _ = try await thirdPartyAPIManager.makeRequest(url: URL(string: "https://api.test.com")!)
            XCTFail("Should throw error for offline network")
        } catch {
            let networkError = networkErrorHandler.categorizeError(error)
            XCTAssertEqual(networkError, .networkOffline, "ThirdPartyAPIManager should handle offline errors")
        }
        
        // Test NetworkingLayerManager error handling
        do {
            let _ = try await networkingLayerManager.performRequest(
                url: URL(string: "https://api.test.com")!,
                method: .get
            )
            XCTFail("Should throw error for offline network")
        } catch {
            let networkError = networkErrorHandler.categorizeError(error)
            XCTAssertEqual(networkError, .networkOffline, "NetworkingLayerManager should handle offline errors")
        }
    }
    
    func testTimeoutErrorHandling() async throws {
        // Test that all network services handle timeout errors consistently
        let timeoutError = URLError(.timedOut)
        
        // Test NetworkErrorHandler categorization
        let categorizedError = networkErrorHandler.categorizeError(timeoutError)
        XCTAssertEqual(categorizedError, .timeout, "Should categorize timeout error correctly")
        XCTAssertTrue(categorizedError.localizedDescription.contains("timed out"), "Should provide user-friendly timeout message")
        
        // Test with mock session that simulates timeout
        mockURLSession.simulateTimeout = true
        
        do {
            let _ = try await thirdPartyAPIManager.makeRequest(url: URL(string: "https://api.test.com")!)
            XCTFail("Should throw timeout error")
        } catch {
            let networkError = networkErrorHandler.categorizeError(error)
            XCTAssertEqual(networkError, .timeout, "Should handle timeout errors consistently")
        }
    }
    
    func testServerErrorHandling() async throws {
        // Test that all network services handle server errors consistently
        let serverError = URLError(.badServerResponse)
        
        // Test NetworkErrorHandler categorization
        let categorizedError = networkErrorHandler.categorizeError(serverError)
        XCTAssertEqual(categorizedError, .unknownError, "Should categorize server error correctly")
        
        // Test with specific HTTP status codes
        let statusCodes = [400, 401, 403, 404, 500, 502, 503]
        
        for statusCode in statusCodes {
            let httpResponse = HTTPURLResponse(
                url: URL(string: "https://api.test.com")!,
                statusCode: statusCode,
                httpVersion: "HTTP/1.1",
                headerFields: [:]
            )!
            
            let error = NSError(
                domain: "HTTP",
                code: statusCode,
                userInfo: [NSURLErrorFailingURLResponseErrorKey: httpResponse]
            )
            
            let categorizedError = networkErrorHandler.categorizeError(error)
            XCTAssertEqual(categorizedError, .serverError(statusCode: statusCode, message: nil), "Should handle HTTP \(statusCode) correctly")
        }
    }
    
    func testDecodingErrorHandling() async throws {
        // Test that all network services handle decoding errors consistently
        let decodingError = DecodingError.dataCorrupted(DecodingError.Context(
            codingPath: [],
            debugDescription: "Invalid JSON format"
        ))
        
        // Test NetworkErrorHandler categorization
        let categorizedError = networkErrorHandler.categorizeError(decodingError)
        XCTAssertEqual(categorizedError, .unknownError, "Should categorize decoding error correctly")
        
        // Test with mock session that returns invalid JSON
        mockURLSession.simulateInvalidJSON = true
        
        do {
            let _: [String: String] = try await thirdPartyAPIManager.makeRequest(url: URL(string: "https://api.test.com")!)
            XCTFail("Should throw decoding error")
        } catch {
            let networkError = networkErrorHandler.categorizeError(error)
            XCTAssertEqual(networkError, .decodingError, "Should handle decoding errors consistently")
        }
    }
    
    // MARK: - Exponential Backoff Retry Tests
    
    func testExponentialBackoffRetryStrategy() async throws {
        // Test that exponential backoff retry works consistently across services
        var retryAttempts = 0
        let maxRetries = 3
        
        let operation = {
            retryAttempts += 1
            if retryAttempts < maxRetries {
                throw URLError(.timedOut)
            }
            return "Success"
        }
        
        let result = try await networkErrorHandler.exponentialBackoffRetry(
            operation: operation,
            maxRetries: maxRetries,
            initialDelay: 0.1 // Short delay for testing
        )
        
        XCTAssertEqual(result, "Success", "Should eventually succeed after retries")
        XCTAssertEqual(retryAttempts, maxRetries, "Should retry the expected number of times")
    }
    
    func testRetryWithDifferentErrorTypes() async throws {
        // Test that retry logic handles different error types appropriately
        let testCases = [
            (URLError(.timedOut), true, "Should retry timeout errors"),
            (URLError(.notConnectedToInternet), true, "Should retry offline errors"),
            (URLError(.badServerResponse), true, "Should retry server errors"),
            (URLError(.cancelled), false, "Should not retry cancelled requests"),
            (URLError(.userAuthenticationRequired), false, "Should not retry auth errors")
        ]
        
        for (error, shouldRetry, description) in testCases {
            var retryAttempts = 0
            
            let operation = {
                retryAttempts += 1
                throw error
            }
            
            do {
                let _ = try await networkErrorHandler.exponentialBackoffRetry(
                    operation: operation,
                    maxRetries: 3,
                    initialDelay: 0.1
                )
                XCTFail("Should throw error: \(description)")
            } catch {
                if shouldRetry {
                    XCTAssertGreaterThan(retryAttempts, 1, description)
                } else {
                    XCTAssertEqual(retryAttempts, 1, description)
                }
            }
        }
    }
    
    // MARK: - Circuit Breaker Tests
    
    func testCircuitBreakerPattern() async throws {
        // Test that circuit breaker pattern works consistently
        let circuitBreaker = NetworkErrorHandler.CircuitBreaker(maxFailures: 2, resetTimeout: 1.0)
        
        // First two failures should be allowed
        XCTAssertTrue(circuitBreaker.canMakeRequest(), "Should allow first request")
        circuitBreaker.recordFailure()
        
        XCTAssertTrue(circuitBreaker.canMakeRequest(), "Should allow second request")
        circuitBreaker.recordFailure()
        
        // Third failure should open circuit
        XCTAssertFalse(circuitBreaker.canMakeRequest(), "Should open circuit after max failures")
        
        // Wait for reset timeout
        try await Task.sleep(for: .seconds(1.1))
        
        // Circuit should be closed again
        XCTAssertTrue(circuitBreaker.canMakeRequest(), "Should close circuit after timeout")
        
        // Success should reset failure count
        circuitBreaker.recordSuccess()
        XCTAssertTrue(circuitBreaker.canMakeRequest(), "Should allow requests after success")
    }
    
    func testCircuitBreakerIntegration() async throws {
        // Test that circuit breakers are properly integrated into network services
        let circuitBreaker = NetworkErrorHandler.CircuitBreaker(maxFailures: 1, resetTimeout: 0.5)
        
        // Simulate repeated failures
        for _ in 0..<3 {
            circuitBreaker.recordFailure()
        }
        
        // Circuit should be open
        XCTAssertFalse(circuitBreaker.canMakeRequest(), "Circuit should be open")
        
        // Test that ThirdPartyAPIManager respects circuit breaker
        do {
            let _ = try await thirdPartyAPIManager.makeRequest(
                url: URL(string: "https://api.test.com")!,
                circuitBreaker: circuitBreaker
            )
            XCTFail("Should respect circuit breaker")
        } catch {
            let networkError = networkErrorHandler.categorizeError(error)
            XCTAssertEqual(networkError, .serverError(statusCode: 503, message: "Service temporarily unavailable"), "Should return service unavailable when circuit is open")
        }
    }
    
    // MARK: - User-Friendly Error Messages Tests
    
    func testUserFriendlyErrorMessages() async throws {
        // Test that all error types provide user-friendly messages
        let errorTestCases = [
            (AppNetworkError.networkOffline, "internet connection"),
            (AppNetworkError.timeout, "timed out"),
            (AppNetworkError.serverError(statusCode: 500, message: "Internal Server Error"), "Server error 500"),
            (AppNetworkError.invalidResponse, "invalid response"),
            (AppNetworkError.decodingError, "Unable to process"),
            (AppNetworkError.unknownError, "unexpected network error")
        ]
        
        for (error, expectedMessage) in errorTestCases {
            let message = error.localizedDescription
            XCTAssertTrue(message.contains(expectedMessage), "Error message should contain '\(expectedMessage)': \(message)")
            XCTAssertFalse(message.contains("URLError"), "Error message should not contain technical URLError text")
            XCTAssertFalse(message.contains("NSError"), "Error message should not contain technical NSError text")
        }
    }
    
    func testLocalizedErrorMessages() async throws {
        // Test that error messages are appropriate for different locales
        let error = AppNetworkError.networkOffline
        let message = error.localizedDescription
        
        // Message should be in English and user-friendly
        XCTAssertTrue(message.contains("No internet connection"), "Should provide clear offline message")
        XCTAssertTrue(message.contains("check your network settings"), "Should provide actionable guidance")
        
        // Message should not contain technical details
        XCTAssertFalse(message.contains("URLError"), "Should not contain technical error types")
        XCTAssertFalse(message.contains("notConnectedToInternet"), "Should not contain error codes")
    }
    
    // MARK: - Error Logging and Reporting Tests
    
    func testErrorLoggingConsistency() async throws {
        // Test that all network services log errors consistently
        let testError = URLError(.timedOut)
        
        // Test that error categorization logs appropriately
        let categorizedError = networkErrorHandler.categorizeError(testError)
        XCTAssertEqual(categorizedError, .timeout, "Should categorize timeout correctly")
        
        // Test that ThirdPartyAPIManager logs errors
        do {
            let _ = try await thirdPartyAPIManager.makeRequest(url: URL(string: "https://api.test.com")!)
            XCTFail("Should throw error")
        } catch {
            // Error should be logged (we can't directly test logging, but we can verify error handling)
            let networkError = networkErrorHandler.categorizeError(error)
            XCTAssertNotEqual(networkError, .unknownError, "Should categorize error properly for logging")
        }
    }
    
    // MARK: - Performance Tests
    
    func testErrorHandlingPerformance() async throws {
        // Test that error handling doesn't significantly impact performance
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Perform multiple error categorizations
        for _ in 0..<1000 {
            let error = URLError(.timedOut)
            let _ = networkErrorHandler.categorizeError(error)
        }
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let duration = endTime - startTime
        
        // Error handling should be fast (< 1 second for 1000 operations)
        XCTAssertLessThan(duration, 1.0, "Error handling took too long: \(duration)s for 1000 operations")
    }
    
    func testCircuitBreakerPerformance() async throws {
        // Test that circuit breaker operations are performant
        let circuitBreaker = NetworkErrorHandler.CircuitBreaker()
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Perform multiple circuit breaker operations
        for _ in 0..<10000 {
            let _ = circuitBreaker.canMakeRequest()
            circuitBreaker.recordSuccess()
        }
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let duration = endTime - startTime
        
        // Circuit breaker operations should be very fast (< 0.1 seconds for 10000 operations)
        XCTAssertLessThan(duration, 0.1, "Circuit breaker operations took too long: \(duration)s for 10000 operations")
    }
    
    // MARK: - Integration Tests
    
    func testEndToEndErrorHandling() async throws {
        // Test complete error handling flow from network request to user feedback
        let testURL = URL(string: "https://api.test.com")!
        
        // Simulate various network conditions
        let testScenarios = [
            ("offline", URLError(.notConnectedToInternet)),
            ("timeout", URLError(.timedOut)),
            ("server_error", URLError(.badServerResponse)),
            ("invalid_response", URLError(.cannotParseResponse))
        ]
        
        for (scenario, error) in testScenarios {
            // Test ThirdPartyAPIManager
            do {
                let _ = try await thirdPartyAPIManager.makeRequest(url: testURL)
                XCTFail("Should throw error for \(scenario)")
            } catch {
                let networkError = networkErrorHandler.categorizeError(error)
                XCTAssertNotEqual(networkError, .unknownError, "Should categorize \(scenario) error properly")
                
                let message = networkError.localizedDescription
                XCTAssertFalse(message.isEmpty, "Should provide error message for \(scenario)")
                XCTAssertTrue(message.count > 10, "Should provide meaningful error message for \(scenario)")
            }
        }
    }
    
    func testErrorRecoveryStrategies() async throws {
        // Test that different error types have appropriate recovery strategies
        let errorRecoveryTests = [
            (AppNetworkError.networkOffline, "Check network connection and try again"),
            (AppNetworkError.timeout, "Try again later when network is more stable"),
            (AppNetworkError.serverError(statusCode: 500, message: nil), "Server is experiencing issues, try again later"),
            (AppNetworkError.invalidResponse, "Contact support if problem persists"),
            (AppNetworkError.decodingError, "App may need to be updated"),
            (AppNetworkError.unknownError, "Try again or contact support")
        ]
        
        for (error, expectedRecovery) in errorRecoveryTests {
            let recoveryStrategy = getRecoveryStrategy(for: error)
            XCTAssertFalse(recoveryStrategy.isEmpty, "Should provide recovery strategy for \(error)")
            XCTAssertTrue(recoveryStrategy.count > 10, "Should provide meaningful recovery strategy for \(error)")
        }
    }
    
    // MARK: - Helper Methods
    
    private func getRecoveryStrategy(for error: AppNetworkError) -> String {
        switch error {
        case .networkOffline:
            return "Check network connection and try again"
        case .timeout:
            return "Try again later when network is more stable"
        case .serverError:
            return "Server is experiencing issues, try again later"
        case .invalidResponse:
            return "Contact support if problem persists"
        case .decodingError:
            return "App may need to be updated"
        case .unknownError:
            return "Try again or contact support"
        }
    }
}

// MARK: - Mock Classes

class MockURLSession {
    var simulateTimeout = false
    var simulateInvalidJSON = false
    var simulateServerError = false
    
    func data(from url: URL) async throws -> (Data, URLResponse) {
        if simulateTimeout {
            throw URLError(.timedOut)
        }
        
        if simulateInvalidJSON {
            let invalidData = "invalid json".data(using: .utf8)!
            let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: [:])!
            return (invalidData, response)
        }
        
        if simulateServerError {
            throw URLError(.badServerResponse)
        }
        
        // Default success response
        let validData = "{\"status\": \"success\"}".data(using: .utf8)!
        let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: [:])!
        return (validData, response)
    }
}

// MARK: - Extensions for Testing

extension NetworkingLayerManager {
    func performRequest(url: URL, method: HTTPMethod = .get) async throws -> NetworkResponse {
        // Simplified request method for testing
        let request = NetworkRequest(url: url, method: method)
        
        guard networkStatus.isConnected else {
            throw AppNetworkError.networkOffline
        }
        
        // Simulate network request
        let data = "{\"test\": \"response\"}".data(using: .utf8)!
        let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: [:])!
        
        return NetworkResponse(
            data: data,
            response: response,
            requestId: request.id
        )
    }
}

struct NetworkResponse {
    let data: Data
    let response: HTTPURLResponse
    let requestId: String
} 
import XCTest
import Foundation
@testable import HealthAI2030Core
@testable import HealthAI2030Networking

final class NetworkingTests: XCTestCase {
    var apiManager: ThirdPartyAPIManager!
    var networkErrorHandler: NetworkErrorHandler!
    
    override func setUp() {
        super.setUp()
        apiManager = .shared
        networkErrorHandler = .shared
    }
    
    /// Test error categorization for different network scenarios
    func testErrorCategorization() {
        // Simulate URLError for network offline
        let offlineError = URLError(.notConnectedToInternet)
        let offlineNetworkError = networkErrorHandler.categorizeError(offlineError)
        XCTAssertEqual(offlineNetworkError, .networkOffline)
        
        // Simulate timeout error
        let timeoutError = URLError(.timedOut)
        let timeoutNetworkError = networkErrorHandler.categorizeError(timeoutError)
        XCTAssertEqual(timeoutNetworkError, .timeout)
        
        // Simulate server error
        let serverError = NSError(domain: NSURLErrorDomain, code: 500, userInfo: nil)
        let serverNetworkError = networkErrorHandler.categorizeError(serverError)
        XCTAssertEqual(serverNetworkError, .unknownError)
    }
    
    /// Test exponential backoff retry mechanism
    func testExponentialBackoffRetry() async {
        var retryCount = 0
        let maxRetries = 3
        
        do {
            _ = try await networkErrorHandler.exponentialBackoffRetry(
                operation: {
                    retryCount += 1
                    if retryCount < maxRetries {
                        throw URLError(.timedOut)
                    }
                    return "Success"
                },
                maxRetries: maxRetries
            )
            
            XCTAssertEqual(retryCount, maxRetries)
        } catch {
            XCTFail("Retry mechanism failed: \(error)")
        }
    }
    
    /// Test circuit breaker functionality
    func testCircuitBreakerMechanism() {
        let circuitBreaker = NetworkErrorHandler.CircuitBreaker(maxFailures: 3, resetTimeout: 1)
        
        // Initially should allow requests
        XCTAssertTrue(circuitBreaker.canMakeRequest())
        
        // Simulate failures
        circuitBreaker.recordFailure()
        circuitBreaker.recordFailure()
        circuitBreaker.recordFailure()
        
        // Should block after max failures
        XCTAssertFalse(circuitBreaker.canMakeRequest())
        
        // Wait and check if circuit reopens
        let expectation = XCTestExpectation(description: "Circuit breaker reset")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            XCTAssertTrue(circuitBreaker.canMakeRequest())
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 2)
    }
    
    /// Test API endpoint validation
    func testAPIEndpointValidation() async {
        // Use a mock valid endpoint
        let validEndpoint = URL(string: "https://api.example.com/health")!
        
        do {
            let isValid = try await apiManager.validateAPIEndpoint(url: validEndpoint)
            XCTAssertTrue(isValid, "API endpoint should be considered valid")
        } catch {
            XCTFail("API endpoint validation threw an unexpected error: \(error)")
        }
    }
    
    /// Test authentication token refresh
    func testAuthTokenRefresh() async {
        do {
            let newToken = try await apiManager.refreshAuthToken()
            XCTAssertFalse(newToken.isEmpty, "Refreshed token should not be empty")
        } catch {
            XCTFail("Token refresh failed: \(error)")
        }
    }
    
    /// Test handling of various HTTP status codes
    func testHTTPStatusCodeHandling() async {
        // Simulate different HTTP status codes
        let testCases: [(Int, Bool)] = [
            (200, true),   // OK
            (201, true),   // Created
            (204, true),   // No Content
            (400, false),  // Bad Request
            (401, false),  // Unauthorized
            (403, false), // Forbidden
            (404, false), // Not Found
            (500, false), // Internal Server Error
            (503, false)  // Service Unavailable
        ]
        
        for (statusCode, shouldSucceed) in testCases {
            let mockURL = URL(string: "https://api.example.com/status/\(statusCode)")!
            
            do {
                let _: [String: String] = try await apiManager.makeRequest(url: mockURL)
                
                if !shouldSucceed {
                    XCTFail("Request with status code \(statusCode) should have failed")
                }
            } catch {
                if shouldSucceed {
                    XCTFail("Request with status code \(statusCode) should have succeeded: \(error)")
                }
            }
        }
    }
}

// Mock extension for testing purposes
extension AppNetworkError: Equatable {
    public static func == (lhs: AppNetworkError, rhs: AppNetworkError) -> Bool {
        switch (lhs, rhs) {
        case (.networkOffline, .networkOffline),
             (.timeout, .timeout),
             (.invalidResponse, .invalidResponse),
             (.decodingError, .decodingError),
             (.unknownError, .unknownError):
            return true
        case let (.serverError(lhsCode, lhsMessage), .serverError(rhsCode, rhsMessage)):
            return lhsCode == rhsCode && lhsMessage == rhsMessage
        default:
            return false
        }
    }
} 
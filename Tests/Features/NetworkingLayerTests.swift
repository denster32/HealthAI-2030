import XCTest
import Foundation
import Combine
import Network
@testable import HealthAI2030

/// Comprehensive unit tests for Networking Layer Manager
/// Tests all networking functionality including request handling, error handling, retry logic, and performance monitoring
final class NetworkingLayerTests: XCTestCase {
    var networkingManager: NetworkingLayerManager!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        networkingManager = NetworkingLayerManager.shared
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDown() {
        cancellables.removeAll()
        networkingManager = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testInitialization() {
        // Test initial state
        XCTAssertEqual(networkingManager.networkStatus, .unknown)
        XCTAssertEqual(networkingManager.connectionQuality, .unknown)
        XCTAssertEqual(networkingManager.activeRequests, 0)
        XCTAssertTrue(networkingManager.requestQueue.isEmpty)
        XCTAssertEqual(networkingManager.performanceMetrics.totalRequests, 0)
        
        // Test configuration
        XCTAssertNotNil(networkingManager.configuration.baseURL)
        XCTAssertGreaterThan(networkingManager.configuration.timeoutInterval, 0)
        XCTAssertGreaterThan(networkingManager.configuration.maximumConcurrentRequests, 0)
    }
    
    func testConfigurationProperties() {
        let config = networkingManager.configuration
        
        // Test required properties
        XCTAssertNotNil(config.baseURL)
        XCTAssertGreaterThan(config.timeoutInterval, 0)
        XCTAssertGreaterThan(config.maximumConcurrentRequests, 0)
        XCTAssertGreaterThanOrEqual(config.defaultRetryAttempts, 0)
        XCTAssertGreaterThan(config.defaultRetryDelay, 0)
        
        // Test boolean properties
        XCTAssertTrue(config.allowsCellularAccess)
        XCTAssertTrue(config.allowsExpensiveNetworkAccess)
        XCTAssertTrue(config.allowsConstrainedNetworkAccess)
        XCTAssertTrue(config.enableRequestCaching)
        XCTAssertTrue(config.enableResponseCompression)
        XCTAssertTrue(config.enableRequestRetry)
    }
    
    // MARK: - Network Request Tests
    
    func testNetworkRequestCreation() {
        let url = URL(string: "https://api.example.com/test")!
        let request = NetworkingLayerManager.NetworkRequest(
            url: url,
            method: .get,
            headers: ["Content-Type": "application/json"],
            body: nil,
            priority: .high
        )
        
        XCTAssertFalse(request.id.isEmpty)
        XCTAssertEqual(request.url, url)
        XCTAssertEqual(request.method, .get)
        XCTAssertEqual(request.headers["Content-Type"], "application/json")
        XCTAssertNil(request.body)
        XCTAssertEqual(request.priority, .high)
        XCTAssertEqual(request.status, .pending)
        XCTAssertEqual(request.attempts, 0)
        XCTAssertNil(request.response)
        XCTAssertNil(request.error)
    }
    
    func testNetworkRequestWithBody() {
        let url = URL(string: "https://api.example.com/test")!
        let bodyData = "{\"test\": \"data\"}".data(using: .utf8)!
        
        let request = NetworkingLayerManager.NetworkRequest(
            url: url,
            method: .post,
            headers: ["Content-Type": "application/json"],
            body: bodyData,
            priority: .normal
        )
        
        XCTAssertEqual(request.method, .post)
        XCTAssertEqual(request.body, bodyData)
        XCTAssertEqual(request.headers["Content-Type"], "application/json")
    }
    
    func testNetworkRequestWithRetryPolicy() {
        let url = URL(string: "https://api.example.com/test")!
        let retryPolicy = NetworkingLayerManager.RetryPolicy(
            maxAttempts: 5,
            baseDelay: 2.0,
            maxDelay: 30.0,
            backoffMultiplier: 2.0,
            jitter: true
        )
        
        let request = NetworkingLayerManager.NetworkRequest(
            url: url,
            method: .get,
            retryPolicy: retryPolicy
        )
        
        XCTAssertNotNil(request.retryPolicy)
        XCTAssertEqual(request.retryPolicy?.maxAttempts, 5)
        XCTAssertEqual(request.retryPolicy?.baseDelay, 2.0)
        XCTAssertEqual(request.retryPolicy?.maxDelay, 30.0)
        XCTAssertEqual(request.retryPolicy?.backoffMultiplier, 2.0)
        XCTAssertTrue(request.retryPolicy?.jitter ?? false)
    }
    
    // MARK: - HTTP Method Tests
    
    func testHTTPMethods() {
        let methods = NetworkingLayerManager.HTTPMethod.allCases
        
        XCTAssertTrue(methods.contains(.get))
        XCTAssertTrue(methods.contains(.post))
        XCTAssertTrue(methods.contains(.put))
        XCTAssertTrue(methods.contains(.patch))
        XCTAssertTrue(methods.contains(.delete))
        XCTAssertTrue(methods.contains(.head))
        XCTAssertTrue(methods.contains(.options))
        
        // Test raw values
        XCTAssertEqual(NetworkingLayerManager.HTTPMethod.get.rawValue, "GET")
        XCTAssertEqual(NetworkingLayerManager.HTTPMethod.post.rawValue, "POST")
        XCTAssertEqual(NetworkingLayerManager.HTTPMethod.put.rawValue, "PUT")
        XCTAssertEqual(NetworkingLayerManager.HTTPMethod.patch.rawValue, "PATCH")
        XCTAssertEqual(NetworkingLayerManager.HTTPMethod.delete.rawValue, "DELETE")
        XCTAssertEqual(NetworkingLayerManager.HTTPMethod.head.rawValue, "HEAD")
        XCTAssertEqual(NetworkingLayerManager.HTTPMethod.options.rawValue, "OPTIONS")
    }
    
    // MARK: - Request Priority Tests
    
    func testRequestPriorities() {
        let priorities = NetworkingLayerManager.RequestPriority.allCases
        
        XCTAssertTrue(priorities.contains(.low))
        XCTAssertTrue(priorities.contains(.normal))
        XCTAssertTrue(priorities.contains(.high))
        XCTAssertTrue(priorities.contains(.critical))
        
        // Test priority order
        XCTAssertLessThan(NetworkingLayerManager.RequestPriority.low.rawValue, NetworkingLayerManager.RequestPriority.normal.rawValue)
        XCTAssertLessThan(NetworkingLayerManager.RequestPriority.normal.rawValue, NetworkingLayerManager.RequestPriority.high.rawValue)
        XCTAssertLessThan(NetworkingLayerManager.RequestPriority.high.rawValue, NetworkingLayerManager.RequestPriority.critical.rawValue)
        
        // Test queue priorities
        XCTAssertEqual(NetworkingLayerManager.RequestPriority.low.queuePriority, .veryLow)
        XCTAssertEqual(NetworkingLayerManager.RequestPriority.normal.queuePriority, .normal)
        XCTAssertEqual(NetworkingLayerManager.RequestPriority.high.queuePriority, .high)
        XCTAssertEqual(NetworkingLayerManager.RequestPriority.critical.queuePriority, .veryHigh)
    }
    
    // MARK: - Network Response Tests
    
    func testNetworkResponseCreation() {
        let url = URL(string: "https://api.example.com/test")!
        let bodyData = "{\"result\": \"success\"}".data(using: .utf8)!
        let headers = ["Content-Type": "application/json", "Cache-Control": "no-cache"]
        let timestamp = Date()
        
        let response = NetworkingLayerManager.NetworkResponse(
            statusCode: 200,
            headers: headers,
            body: bodyData,
            url: url,
            timestamp: timestamp,
            duration: 1.5
        )
        
        XCTAssertEqual(response.statusCode, 200)
        XCTAssertEqual(response.headers, headers)
        XCTAssertEqual(response.body, bodyData)
        XCTAssertEqual(response.url, url)
        XCTAssertEqual(response.timestamp, timestamp)
        XCTAssertEqual(response.duration, 1.5)
    }
    
    func testNetworkResponseStatusCodes() {
        // Success responses
        let successResponse = NetworkingLayerManager.NetworkResponse(
            statusCode: 200,
            headers: [:],
            body: Data(),
            url: nil,
            timestamp: Date(),
            duration: 1.0
        )
        XCTAssertTrue(successResponse.isSuccess)
        XCTAssertFalse(successResponse.isClientError)
        XCTAssertFalse(successResponse.isServerError)
        
        // Client error responses
        let clientErrorResponse = NetworkingLayerManager.NetworkResponse(
            statusCode: 400,
            headers: [:],
            body: Data(),
            url: nil,
            timestamp: Date(),
            duration: 1.0
        )
        XCTAssertFalse(clientErrorResponse.isSuccess)
        XCTAssertTrue(clientErrorResponse.isClientError)
        XCTAssertFalse(clientErrorResponse.isServerError)
        
        // Server error responses
        let serverErrorResponse = NetworkingLayerManager.NetworkResponse(
            statusCode: 500,
            headers: [:],
            body: Data(),
            url: nil,
            timestamp: Date(),
            duration: 1.0
        )
        XCTAssertFalse(serverErrorResponse.isSuccess)
        XCTAssertFalse(serverErrorResponse.isClientError)
        XCTAssertTrue(serverErrorResponse.isServerError)
    }
    
    // MARK: - Network Error Tests
    
    func testNetworkErrorTypes() {
        // Test all error types
        let errors: [NetworkingLayerManager.NetworkError] = [
            .invalidURL,
            .invalidRequest,
            .noConnection,
            .timeout,
            .serverError(500),
            .clientError(400),
            .unauthorized,
            .forbidden,
            .notFound,
            .rateLimited,
            .invalidResponse,
            .decodingError("Test error"),
            .encodingError("Test error"),
            .cancelled,
            .unknown(NSError(domain: "Test", code: -1))
        ]
        
        for error in errors {
            XCTAssertFalse(error.errorDescription?.isEmpty ?? true)
        }
    }
    
    func testNetworkErrorRetryability() {
        // Retryable errors
        XCTAssertTrue(NetworkingLayerManager.NetworkError.noConnection.isRetryable)
        XCTAssertTrue(NetworkingLayerManager.NetworkError.timeout.isRetryable)
        XCTAssertTrue(NetworkingLayerManager.NetworkError.serverError(500).isRetryable)
        
        // Non-retryable errors
        XCTAssertFalse(NetworkingLayerManager.NetworkError.clientError(400).isRetryable)
        XCTAssertFalse(NetworkingLayerManager.NetworkError.unauthorized.isRetryable)
        XCTAssertFalse(NetworkingLayerManager.NetworkError.forbidden.isRetryable)
        XCTAssertFalse(NetworkingLayerManager.NetworkError.notFound.isRetryable)
        XCTAssertFalse(NetworkingLayerManager.NetworkError.rateLimited.isRetryable)
        XCTAssertFalse(NetworkingLayerManager.NetworkError.invalidURL.isRetryable)
        XCTAssertFalse(NetworkingLayerManager.NetworkError.invalidRequest.isRetryable)
        XCTAssertFalse(NetworkingLayerManager.NetworkError.invalidResponse.isRetryable)
        XCTAssertFalse(NetworkingLayerManager.NetworkError.decodingError("").isRetryable)
        XCTAssertFalse(NetworkingLayerManager.NetworkError.encodingError("").isRetryable)
        XCTAssertFalse(NetworkingLayerManager.NetworkError.cancelled.isRetryable)
        XCTAssertFalse(NetworkingLayerManager.NetworkError.unknown(NSError(domain: "Test", code: -1)).isRetryable)
    }
    
    func testNetworkErrorDescriptions() {
        XCTAssertEqual(NetworkingLayerManager.NetworkError.invalidURL.errorDescription, "Invalid URL")
        XCTAssertEqual(NetworkingLayerManager.NetworkError.invalidRequest.errorDescription, "Invalid request")
        XCTAssertEqual(NetworkingLayerManager.NetworkError.noConnection.errorDescription, "No network connection")
        XCTAssertEqual(NetworkingLayerManager.NetworkError.timeout.errorDescription, "Request timeout")
        XCTAssertEqual(NetworkingLayerManager.NetworkError.unauthorized.errorDescription, "Unauthorized access")
        XCTAssertEqual(NetworkingLayerManager.NetworkError.forbidden.errorDescription, "Access forbidden")
        XCTAssertEqual(NetworkingLayerManager.NetworkError.notFound.errorDescription, "Resource not found")
        XCTAssertEqual(NetworkingLayerManager.NetworkError.rateLimited.errorDescription, "Rate limit exceeded")
        XCTAssertEqual(NetworkingLayerManager.NetworkError.invalidResponse.errorDescription, "Invalid response")
        XCTAssertEqual(NetworkingLayerManager.NetworkError.cancelled.errorDescription, "Request cancelled")
    }
    
    // MARK: - Retry Policy Tests
    
    func testRetryPolicyCreation() {
        let policy = NetworkingLayerManager.RetryPolicy(
            maxAttempts: 5,
            baseDelay: 2.0,
            maxDelay: 30.0,
            backoffMultiplier: 2.0,
            jitter: true,
            retryableErrors: [.timeout, .serverError(500)]
        )
        
        XCTAssertEqual(policy.maxAttempts, 5)
        XCTAssertEqual(policy.baseDelay, 2.0)
        XCTAssertEqual(policy.maxDelay, 30.0)
        XCTAssertEqual(policy.backoffMultiplier, 2.0)
        XCTAssertTrue(policy.jitter)
        XCTAssertEqual(policy.retryableErrors.count, 2)
    }
    
    func testRetryPolicyDelayCalculation() {
        let policy = NetworkingLayerManager.RetryPolicy(
            maxAttempts: 3,
            baseDelay: 1.0,
            maxDelay: 10.0,
            backoffMultiplier: 2.0,
            jitter: false
        )
        
        // Test exponential backoff without jitter
        let delay1 = policy.calculateDelay(for: 1)
        XCTAssertEqual(delay1, 1.0)
        
        let delay2 = policy.calculateDelay(for: 2)
        XCTAssertEqual(delay2, 2.0)
        
        let delay3 = policy.calculateDelay(for: 3)
        XCTAssertEqual(delay3, 4.0)
        
        let delay4 = policy.calculateDelay(for: 4)
        XCTAssertEqual(delay4, 8.0)
        
        // Test max delay cap
        let delay10 = policy.calculateDelay(for: 10)
        XCTAssertEqual(delay10, 10.0) // Should be capped at maxDelay
    }
    
    func testRetryPolicyWithJitter() {
        let policy = NetworkingLayerManager.RetryPolicy(
            maxAttempts: 3,
            baseDelay: 1.0,
            maxDelay: 10.0,
            backoffMultiplier: 2.0,
            jitter: true
        )
        
        // Test that jitter adds some randomness
        let delays = (1...10).map { policy.calculateDelay(for: $0) }
        let uniqueDelays = Set(delays)
        
        // With jitter, we should have some variation
        XCTAssertGreaterThan(uniqueDelays.count, 1)
    }
    
    // MARK: - Cached Response Tests
    
    func testCachedResponseCreation() {
        let response = NetworkingLayerManager.NetworkResponse(
            statusCode: 200,
            headers: ["ETag": "abc123"],
            body: Data(),
            url: nil,
            timestamp: Date(),
            duration: 1.0
        )
        
        let cacheKey = "test_cache_key"
        let createdAt = Date()
        let expiresAt = createdAt.addingTimeInterval(300) // 5 minutes
        
        let cachedResponse = NetworkingLayerManager.CachedResponse(
            response: response,
            cacheKey: cacheKey,
            createdAt: createdAt,
            expiresAt: expiresAt,
            etag: "abc123"
        )
        
        XCTAssertEqual(cachedResponse.response, response)
        XCTAssertEqual(cachedResponse.cacheKey, cacheKey)
        XCTAssertEqual(cachedResponse.createdAt, createdAt)
        XCTAssertEqual(cachedResponse.expiresAt, expiresAt)
        XCTAssertEqual(cachedResponse.etag, "abc123")
        XCTAssertFalse(cachedResponse.isExpired)
    }
    
    func testCachedResponseExpiration() {
        let response = NetworkingLayerManager.NetworkResponse(
            statusCode: 200,
            headers: [:],
            body: Data(),
            url: nil,
            timestamp: Date(),
            duration: 1.0
        )
        
        let createdAt = Date()
        let expiresAt = createdAt.addingTimeInterval(-60) // Expired 1 minute ago
        
        let cachedResponse = NetworkingLayerManager.CachedResponse(
            response: response,
            cacheKey: "test",
            createdAt: createdAt,
            expiresAt: expiresAt
        )
        
        XCTAssertTrue(cachedResponse.isExpired)
    }
    
    // MARK: - Performance Metrics Tests
    
    func testPerformanceMetricsInitialization() {
        let metrics = NetworkingLayerManager.NetworkPerformanceMetrics()
        
        XCTAssertEqual(metrics.totalRequests, 0)
        XCTAssertEqual(metrics.successfulRequests, 0)
        XCTAssertEqual(metrics.failedRequests, 0)
        XCTAssertEqual(metrics.averageResponseTime, 0)
        XCTAssertEqual(metrics.totalDataTransferred, 0)
        XCTAssertEqual(metrics.cacheHitRate, 0)
        XCTAssertEqual(metrics.retryRate, 0)
        XCTAssertEqual(metrics.errorRate, 0)
        XCTAssertEqual(metrics.successRate, 0)
    }
    
    func testPerformanceMetricsCalculations() {
        var metrics = NetworkingLayerManager.NetworkPerformanceMetrics()
        
        // Add some test data
        metrics.totalRequests = 100
        metrics.successfulRequests = 80
        metrics.failedRequests = 20
        metrics.totalDataTransferred = 1024 * 1024 // 1MB
        
        // Test success rate calculation
        let expectedSuccessRate = Double(metrics.successfulRequests) / Double(metrics.totalRequests)
        XCTAssertEqual(metrics.successRate, expectedSuccessRate)
        XCTAssertEqual(metrics.successRate, 0.8)
        
        // Test error rate calculation
        let expectedErrorRate = Double(metrics.failedRequests) / Double(metrics.totalRequests)
        XCTAssertEqual(metrics.errorRate, expectedErrorRate)
        XCTAssertEqual(metrics.errorRate, 0.2)
    }
    
    func testPerformanceMetricsWithZeroRequests() {
        let metrics = NetworkingLayerManager.NetworkPerformanceMetrics()
        
        // Test edge cases with zero requests
        XCTAssertEqual(metrics.successRate, 0)
        XCTAssertEqual(metrics.errorRate, 0)
    }
    
    // MARK: - Network Status Tests
    
    func testNetworkStatusProperties() {
        let statuses = NetworkingLayerManager.NetworkStatus.allCases
        
        XCTAssertTrue(statuses.contains(.unknown))
        XCTAssertTrue(statuses.contains(.connected))
        XCTAssertTrue(statuses.contains(.disconnected))
        XCTAssertTrue(statuses.contains(.connecting))
        XCTAssertTrue(statuses.contains(.limited))
        
        // Test connection status
        XCTAssertTrue(NetworkingLayerManager.NetworkStatus.connected.isConnected)
        XCTAssertTrue(NetworkingLayerManager.NetworkStatus.limited.isConnected)
        XCTAssertFalse(NetworkingLayerManager.NetworkStatus.unknown.isConnected)
        XCTAssertFalse(NetworkingLayerManager.NetworkStatus.disconnected.isConnected)
        XCTAssertFalse(NetworkingLayerManager.NetworkStatus.connecting.isConnected)
    }
    
    func testConnectionQualityProperties() {
        let qualities = NetworkingLayerManager.ConnectionQuality.allCases
        
        XCTAssertTrue(qualities.contains(.unknown))
        XCTAssertTrue(qualities.contains(.excellent))
        XCTAssertTrue(qualities.contains(.good))
        XCTAssertTrue(qualities.contains(.fair))
        XCTAssertTrue(qualities.contains(.poor))
        
        // Test priority order
        XCTAssertLessThan(NetworkingLayerManager.ConnectionQuality.unknown.priority, NetworkingLayerManager.ConnectionQuality.poor.priority)
        XCTAssertLessThan(NetworkingLayerManager.ConnectionQuality.poor.priority, NetworkingLayerManager.ConnectionQuality.fair.priority)
        XCTAssertLessThan(NetworkingLayerManager.ConnectionQuality.fair.priority, NetworkingLayerManager.ConnectionQuality.good.priority)
        XCTAssertLessThan(NetworkingLayerManager.ConnectionQuality.good.priority, NetworkingLayerManager.ConnectionQuality.excellent.priority)
    }
    
    // MARK: - Request Status Tests
    
    func testRequestStatusProperties() {
        let statuses = NetworkingLayerManager.RequestStatus.allCases
        
        XCTAssertTrue(statuses.contains(.pending))
        XCTAssertTrue(statuses.contains(.inProgress))
        XCTAssertTrue(statuses.contains(.completed))
        XCTAssertTrue(statuses.contains(.failed))
        XCTAssertTrue(statuses.contains(.cancelled))
        XCTAssertTrue(statuses.contains(.retrying))
    }
    
    // MARK: - Public Methods Tests
    
    func testClearCache() {
        // Test that clear cache doesn't crash
        networkingManager.clearCache()
        
        // Verify cache is empty (implementation dependent)
        // This test ensures the method can be called safely
    }
    
    func testResetPerformanceMetrics() {
        // Test that reset metrics doesn't crash
        networkingManager.resetPerformanceMetrics()
        
        // Verify metrics are reset
        let metrics = networkingManager.getPerformanceMetrics()
        XCTAssertEqual(metrics.totalRequests, 0)
        XCTAssertEqual(metrics.successfulRequests, 0)
        XCTAssertEqual(metrics.failedRequests, 0)
    }
    
    func testGetPerformanceMetrics() {
        let metrics = networkingManager.getPerformanceMetrics()
        
        // Test that metrics object is returned
        XCTAssertNotNil(metrics)
        XCTAssertGreaterThanOrEqual(metrics.totalRequests, 0)
        XCTAssertGreaterThanOrEqual(metrics.successfulRequests, 0)
        XCTAssertGreaterThanOrEqual(metrics.failedRequests, 0)
        XCTAssertGreaterThanOrEqual(metrics.averageResponseTime, 0)
        XCTAssertGreaterThanOrEqual(metrics.totalDataTransferred, 0)
        XCTAssertGreaterThanOrEqual(metrics.cacheHitRate, 0)
        XCTAssertLessThanOrEqual(metrics.cacheHitRate, 1)
        XCTAssertGreaterThanOrEqual(metrics.retryRate, 0)
        XCTAssertLessThanOrEqual(metrics.retryRate, 1)
        XCTAssertGreaterThanOrEqual(metrics.errorRate, 0)
        XCTAssertLessThanOrEqual(metrics.errorRate, 1)
        XCTAssertGreaterThanOrEqual(metrics.successRate, 0)
        XCTAssertLessThanOrEqual(metrics.successRate, 1)
    }
    
    // MARK: - Configuration Tests
    
    func testConfigurationUpdate() {
        let originalTimeout = networkingManager.configuration.timeoutInterval
        let newTimeout: TimeInterval = 60.0
        
        // Create new configuration with different timeout
        let newConfig = NetworkingLayerManager.NetworkConfiguration(
            baseURL: networkingManager.configuration.baseURL,
            timeoutInterval: newTimeout,
            cachePolicy: networkingManager.configuration.cachePolicy,
            allowsCellularAccess: networkingManager.configuration.allowsCellularAccess,
            allowsExpensiveNetworkAccess: networkingManager.configuration.allowsExpensiveNetworkAccess,
            allowsConstrainedNetworkAccess: networkingManager.configuration.allowsConstrainedNetworkAccess,
            maximumConcurrentRequests: networkingManager.configuration.maximumConcurrentRequests,
            enableRequestCaching: networkingManager.configuration.enableRequestCaching,
            enableResponseCompression: networkingManager.configuration.enableResponseCompression,
            enableRequestRetry: networkingManager.configuration.enableRequestRetry,
            defaultRetryAttempts: networkingManager.configuration.defaultRetryAttempts,
            defaultRetryDelay: networkingManager.configuration.defaultRetryDelay
        )
        
        networkingManager.configuration = newConfig
        
        XCTAssertEqual(networkingManager.configuration.timeoutInterval, newTimeout)
        XCTAssertNotEqual(networkingManager.configuration.timeoutInterval, originalTimeout)
    }
    
    // MARK: - Edge Case Tests
    
    func testEmptyURLRequest() {
        let request = NetworkingLayerManager.NetworkRequest(
            url: URL(string: "https://api.example.com")!,
            method: .get
        )
        
        // Test that request with minimal data is valid
        XCTAssertFalse(request.id.isEmpty)
        XCTAssertNotNil(request.url)
        XCTAssertEqual(request.method, .get)
        XCTAssertTrue(request.headers.isEmpty)
        XCTAssertNil(request.body)
    }
    
    func testLargeRequestBody() {
        let largeData = Data(repeating: 0, count: 1024 * 1024) // 1MB
        let request = NetworkingLayerManager.NetworkRequest(
            url: URL(string: "https://api.example.com")!,
            method: .post,
            body: largeData
        )
        
        XCTAssertEqual(request.body?.count, 1024 * 1024)
        XCTAssertNotNil(request.body)
    }
    
    func testRequestWithManyHeaders() {
        var headers: [String: String] = [:]
        for i in 1...100 {
            headers["Header-\(i)"] = "Value-\(i)"
        }
        
        let request = NetworkingLayerManager.NetworkRequest(
            url: URL(string: "https://api.example.com")!,
            method: .get,
            headers: headers
        )
        
        XCTAssertEqual(request.headers.count, 100)
        XCTAssertEqual(request.headers["Header-1"], "Value-1")
        XCTAssertEqual(request.headers["Header-100"], "Value-100")
    }
    
    func testRetryPolicyEdgeCases() {
        // Test zero attempts
        let zeroAttemptsPolicy = NetworkingLayerManager.RetryPolicy(maxAttempts: 0)
        XCTAssertEqual(zeroAttemptsPolicy.maxAttempts, 0)
        
        // Test very large delays
        let largeDelayPolicy = NetworkingLayerManager.RetryPolicy(
            maxAttempts: 3,
            baseDelay: 1000.0,
            maxDelay: 10000.0
        )
        
        let delay = largeDelayPolicy.calculateDelay(for: 2)
        XCTAssertLessThanOrEqual(delay, 10000.0) // Should be capped
    }
    
    // MARK: - Performance Tests
    
    func testConcurrentRequestCreation() async {
        await withTaskGroup(of: NetworkingLayerManager.NetworkRequest.self) { group in
            for _ in 0..<100 {
                group.addTask {
                    NetworkingLayerManager.NetworkRequest(
                        url: URL(string: "https://api.example.com")!,
                        method: .get
                    )
                }
            }
            
            var requests: [NetworkingLayerManager.NetworkRequest] = []
            for await request in group {
                requests.append(request)
            }
            
            XCTAssertEqual(requests.count, 100)
            
            // Verify all requests have unique IDs
            let ids = Set(requests.map { $0.id })
            XCTAssertEqual(ids.count, 100)
        }
    }
    
    func testLargeResponseHandling() {
        let largeData = Data(repeating: 0, count: 10 * 1024 * 1024) // 10MB
        let response = NetworkingLayerManager.NetworkResponse(
            statusCode: 200,
            headers: [:],
            body: largeData,
            url: nil,
            timestamp: Date(),
            duration: 5.0
        )
        
        XCTAssertEqual(response.body.count, 10 * 1024 * 1024)
        XCTAssertTrue(response.isSuccess)
        XCTAssertEqual(response.duration, 5.0)
    }
    
    // MARK: - Integration Tests
    
    func testRequestResponseIntegration() {
        let url = URL(string: "https://api.example.com/test")!
        let request = NetworkingLayerManager.NetworkRequest(
            url: url,
            method: .post,
            headers: ["Content-Type": "application/json"],
            body: "{\"test\": \"data\"}".data(using: .utf8)
        )
        
        let response = NetworkingLayerManager.NetworkResponse(
            statusCode: 201,
            headers: ["Location": "https://api.example.com/test/123"],
            body: "{\"id\": \"123\", \"status\": \"created\"}".data(using: .utf8)!,
            url: url,
            timestamp: Date(),
            duration: 1.5
        )
        
        // Test that request and response are compatible
        XCTAssertEqual(request.url, response.url)
        XCTAssertTrue(response.isSuccess)
        XCTAssertEqual(response.statusCode, 201)
        XCTAssertNotNil(response.body)
    }
    
    func testCachingIntegration() {
        let url = URL(string: "https://api.example.com/cache-test")!
        let request = NetworkingLayerManager.NetworkRequest(
            url: url,
            method: .get
        )
        
        let response = NetworkingLayerManager.NetworkResponse(
            statusCode: 200,
            headers: ["ETag": "abc123", "Cache-Control": "max-age=300"],
            body: "cached data".data(using: .utf8)!,
            url: url,
            timestamp: Date(),
            duration: 0.5
        )
        
        let cacheKey = "GET_https://api.example.com/cache-test"
        let cachedResponse = NetworkingLayerManager.CachedResponse(
            response: response,
            cacheKey: cacheKey,
            createdAt: Date(),
            expiresAt: Date().addingTimeInterval(300),
            etag: "abc123"
        )
        
        // Test cache integration
        XCTAssertEqual(cachedResponse.cacheKey, cacheKey)
        XCTAssertEqual(cachedResponse.response, response)
        XCTAssertFalse(cachedResponse.isExpired)
        XCTAssertEqual(cachedResponse.etag, "abc123")
    }
} 
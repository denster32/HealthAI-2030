import Foundation
import Combine
import Network
import os.log
import AppError
import CircuitBreaker

/// Comprehensive Networking Layer Manager for HealthAI 2030
/// Provides modular, optimized networking with error handling, retry logic, and performance monitoring
public class NetworkingLayerManager: ObservableObject {
    public static let shared = NetworkingLayerManager()
    
    // MARK: - Published Properties
    
    @Published public var networkStatus: NetworkStatus = .unknown
    @Published public var connectionQuality: ConnectionQuality = .unknown
    @Published public var activeRequests: Int = 0
    @Published public var requestQueue: [NetworkRequest] = []
    @Published public var performanceMetrics: NetworkPerformanceMetrics = NetworkPerformanceMetrics()
    
    // MARK: - Private Properties
    
    private let networkMonitor = NWPathMonitor()
    private let networkQueue = DispatchQueue(label: "com.healthai.networking", qos: .utility)
    private let session: URLSession
    private let logger = Logger(subsystem: "com.healthai.networking", category: "NetworkingLayer")
    
    private var cancellables = Set<AnyCancellable>()
    private var requestCache: [String: CachedResponse] = [:]
    private var retryPolicies: [String: RetryPolicy] = [:]
    private var requestInterceptors: [RequestInterceptor] = []
    private var responseInterceptors: [ResponseInterceptor] = []
    private var circuitBreakers: [String: CircuitBreaker] = [:]
    
    // MARK: - Configuration
    
    public struct NetworkConfiguration {
        public let baseURL: URL
        public let apiVersion: String
        public let timeoutInterval: TimeInterval
        public let cachePolicy: URLRequest.CachePolicy
        public let allowsCellularAccess: Bool
        public let allowsExpensiveNetworkAccess: Bool
        public let allowsConstrainedNetworkAccess: Bool
        public let maximumConcurrentRequests: Int
        public let enableRequestCaching: Bool
        public let enableResponseCompression: Bool
        public let enableRequestRetry: Bool
        public let defaultRetryAttempts: Int
        public let defaultRetryDelay: TimeInterval
        
        public init(
            baseURL: URL,
            apiVersion: String = "v1",
            timeoutInterval: TimeInterval = 30.0,
            cachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy,
            allowsCellularAccess: Bool = true,
            allowsExpensiveNetworkAccess: Bool = true,
            allowsConstrainedNetworkAccess: Bool = true,
            maximumConcurrentRequests: Int = 10,
            enableRequestCaching: Bool = true,
            enableResponseCompression: Bool = true,
            enableRequestRetry: Bool = true,
            defaultRetryAttempts: Int = 3,
            defaultRetryDelay: TimeInterval = 1.0
        ) {
            self.baseURL = baseURL
            self.apiVersion = apiVersion
            self.timeoutInterval = timeoutInterval
            self.cachePolicy = cachePolicy
            self.allowsCellularAccess = allowsCellularAccess
            self.allowsExpensiveNetworkAccess = allowsExpensiveNetworkAccess
            self.allowsConstrainedNetworkAccess = allowsConstrainedNetworkAccess
            self.maximumConcurrentRequests = maximumConcurrentRequests
            self.enableRequestCaching = enableRequestCaching
            self.enableResponseCompression = enableResponseCompression
            self.enableRequestRetry = enableRequestRetry
            self.defaultRetryAttempts = defaultRetryAttempts
            self.defaultRetryDelay = defaultRetryDelay
        }
    }
    
    public var configuration: NetworkConfiguration {
        didSet {
            updateSessionConfiguration()
        }
    }
    
    // MARK: - Initialization
    
    private init() {
        self.configuration = NetworkConfiguration(
            baseURL: URL(string: "https://api.healthai2030.com")!
        )
        
        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.timeoutIntervalForRequest = configuration.timeoutInterval
        sessionConfig.timeoutIntervalForResource = configuration.timeoutInterval * 2
        sessionConfig.requestCachePolicy = configuration.cachePolicy
        sessionConfig.allowsCellularAccess = configuration.allowsCellularAccess
        sessionConfig.allowsExpensiveNetworkAccess = configuration.allowsExpensiveNetworkAccess
        sessionConfig.allowsConstrainedNetworkAccess = configuration.allowsConstrainedNetworkAccess
        sessionConfig.httpMaximumConnectionsPerHost = configuration.maximumConcurrentRequests
        
        if configuration.enableResponseCompression {
            sessionConfig.httpAdditionalHeaders = [
                "Accept-Encoding": "gzip, deflate, br"
            ]
        }
        
        self.session = URLSession(configuration: sessionConfig)
        
        setupNetworkMonitoring()
        setupDefaultInterceptors()
        setupDefaultRetryPolicies()
    }
    
    // MARK: - Network Status
    
    public enum NetworkStatus: String, CaseIterable {
        case unknown = "Unknown"
        case connected = "Connected"
        case disconnected = "Disconnected"
        case connecting = "Connecting"
        case limited = "Limited"
        
        var isConnected: Bool {
            switch self {
            case .connected, .limited:
                return true
            case .unknown, .disconnected, .connecting:
                return false
            }
        }
    }
    
    public enum ConnectionQuality: String, CaseIterable {
        case unknown = "Unknown"
        case excellent = "Excellent"
        case good = "Good"
        case fair = "Fair"
        case poor = "Poor"
        
        var priority: Int {
            switch self {
            case .excellent: return 4
            case .good: return 3
            case .fair: return 2
            case .poor: return 1
            case .unknown: return 0
            }
        }
    }
    
    // MARK: - Network Request
    
    public struct NetworkRequest: Identifiable, Codable {
        public let id: String
        public let url: URL
        public let method: HTTPMethod
        public let headers: [String: String]
        public let body: Data?
        public let cachePolicy: URLRequest.CachePolicy
        public let timeoutInterval: TimeInterval
        public let retryPolicy: RetryPolicy?
        public let priority: RequestPriority
        public let createdAt: Date
        public var status: RequestStatus
        public var attempts: Int
        public var lastAttempt: Date?
        public var response: NetworkResponse?
        public var error: NetworkError?
        
        public init(
            id: String = UUID().uuidString,
            url: URL,
            method: HTTPMethod = .get,
            headers: [String: String] = [:],
            body: Data? = nil,
            cachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy,
            timeoutInterval: TimeInterval = 30.0,
            retryPolicy: RetryPolicy? = nil,
            priority: RequestPriority = .normal
        ) {
            self.id = id
            self.url = url
            self.method = method
            self.headers = headers
            self.body = body
            self.cachePolicy = cachePolicy
            self.timeoutInterval = timeoutInterval
            self.retryPolicy = retryPolicy
            self.priority = priority
            self.createdAt = Date()
            self.status = .pending
            self.attempts = 0
        }
    }
    
    public enum HTTPMethod: String, CaseIterable, Codable {
        case get = "GET"
        case post = "POST"
        case put = "PUT"
        case patch = "PATCH"
        case delete = "DELETE"
        case head = "HEAD"
        case options = "OPTIONS"
    }
    
    public enum RequestPriority: Int, CaseIterable, Codable {
        case low = 0
        case normal = 1
        case high = 2
        case critical = 3
        
        var queuePriority: Operation.QueuePriority {
            switch self {
            case .low: return .veryLow
            case .normal: return .normal
            case .high: return .high
            case .critical: return .veryHigh
            }
        }
    }
    
    public enum RequestStatus: String, CaseIterable, Codable {
        case pending = "Pending"
        case inProgress = "In Progress"
        case completed = "Completed"
        case failed = "Failed"
        case cancelled = "Cancelled"
        case retrying = "Retrying"
    }
    
    // MARK: - Network Response
    
    public struct NetworkResponse: Codable {
        public let statusCode: Int
        public let headers: [String: String]
        public let body: Data
        public let url: URL?
        public let timestamp: Date
        public let duration: TimeInterval
        
        public init(
            statusCode: Int,
            headers: [String: String],
            body: Data,
            url: URL?,
            timestamp: Date,
            duration: TimeInterval
        ) {
            self.statusCode = statusCode
            self.headers = headers
            self.body = body
            self.url = url
            self.timestamp = timestamp
            self.duration = duration
        }
        
        public var isSuccess: Bool {
            return statusCode >= 200 && statusCode < 300
        }
        
        public var isClientError: Bool {
            return statusCode >= 400 && statusCode < 500
        }
        
        public var isServerError: Bool {
            return statusCode >= 500 && statusCode < 600
        }
    }
    
    // MARK: - Network Error
    
    public enum NetworkError: Error, LocalizedError, Codable {
        case invalidURL
        case invalidRequest
        case noConnection
        case timeout
        case serverError(Int)
        case clientError(Int)
        case unauthorized
        case forbidden
        case notFound
        case rateLimited
        case invalidResponse
        case decodingError(String)
        case encodingError(String)
        case cancelled
        case unknown(Error)
        
        public var errorDescription: String? {
            switch self {
            case .invalidURL:
                return "Invalid URL"
            case .invalidRequest:
                return "Invalid request"
            case .noConnection:
                return "No network connection"
            case .timeout:
                return "Request timeout"
            case .serverError(let code):
                return "Server error: \(code)"
            case .clientError(let code):
                return "Client error: \(code)"
            case .unauthorized:
                return "Unauthorized access"
            case .forbidden:
                return "Access forbidden"
            case .notFound:
                return "Resource not found"
            case .rateLimited:
                return "Rate limit exceeded"
            case .invalidResponse:
                return "Invalid response"
            case .decodingError(let message):
                return "Decoding error: \(message)"
            case .encodingError(let message):
                return "Encoding error: \(message)"
            case .cancelled:
                return "Request cancelled"
            case .unknown(let error):
                return "Unknown error: \(error.localizedDescription)"
            }
        }
        
        public var isRetryable: Bool {
            switch self {
            case .noConnection, .timeout, .serverError:
                return true
            case .clientError, .unauthorized, .forbidden, .notFound, .rateLimited:
                return false
            case .invalidURL, .invalidRequest, .invalidResponse, .decodingError, .encodingError, .cancelled, .unknown:
                return false
            }
        }
    }
    
    // MARK: - Retry Policy
    
    public struct RetryPolicy: Codable {
        public let maxAttempts: Int
        public let baseDelay: TimeInterval
        public let maxDelay: TimeInterval
        public let backoffMultiplier: Double
        public let jitter: Bool
        public let retryableErrors: [NetworkError]
        
        public init(
            maxAttempts: Int = 3,
            baseDelay: TimeInterval = 1.0,
            maxDelay: TimeInterval = 60.0,
            backoffMultiplier: Double = 2.0,
            jitter: Bool = true,
            retryableErrors: [NetworkError] = []
        ) {
            self.maxAttempts = maxAttempts
            self.baseDelay = baseDelay
            self.maxDelay = maxDelay
            self.backoffMultiplier = backoffMultiplier
            self.jitter = jitter
            self.retryableErrors = retryableErrors
        }
        
        public func calculateDelay(for attempt: Int) -> TimeInterval {
            let delay = baseDelay * pow(backoffMultiplier, Double(attempt - 1))
            let cappedDelay = min(delay, maxDelay)
            
            if jitter {
                let jitterAmount = cappedDelay * 0.1
                return cappedDelay + Double.random(in: -jitterAmount...jitterAmount)
            }
            
            return cappedDelay
        }
    }
    
    // MARK: - Cached Response
    
    public struct CachedResponse: Codable {
        public let response: NetworkResponse
        public let cacheKey: String
        public let createdAt: Date
        public let expiresAt: Date
        public let etag: String?
        
        public init(
            response: NetworkResponse,
            cacheKey: String,
            createdAt: Date,
            expiresAt: Date,
            etag: String? = nil
        ) {
            self.response = response
            self.cacheKey = cacheKey
            self.createdAt = createdAt
            self.expiresAt = expiresAt
            self.etag = etag
        }
        
        public var isExpired: Bool {
            return Date() > expiresAt
        }
    }
    
    // MARK: - Performance Metrics
    
    public struct NetworkPerformanceMetrics: Codable {
        public var totalRequests: Int = 0
        public var successfulRequests: Int = 0
        public var failedRequests: Int = 0
        public var averageResponseTime: TimeInterval = 0
        public var totalDataTransferred: Int64 = 0
        public var cacheHitRate: Double = 0
        public var retryRate: Double = 0
        public var errorRate: Double = 0
        
        public var successRate: Double {
            guard totalRequests > 0 else { return 0 }
            return Double(successfulRequests) / Double(totalRequests)
        }
    }
    
    // MARK: - Interceptors
    
    public protocol RequestInterceptor {
        func intercept(_ request: NetworkRequest) -> NetworkRequest
    }
    
    public protocol ResponseInterceptor {
        func intercept(_ response: NetworkResponse, for request: NetworkRequest) -> NetworkResponse
    }
    
    // MARK: - Public Methods
    
    public func performRequest<T: Codable>(
        _ request: NetworkRequest,
        responseType: T.Type
    ) async throws -> T {
        let startTime = Date()
        
        do {
            let response = try await performRequest(request)
            let duration = Date().timeIntervalSince(startTime)
            
            updatePerformanceMetrics(success: true, duration: duration, dataSize: Int64(response.body.count))
            
            let decoder = JSONDecoder()
            return try decoder.decode(responseType, from: response.body)
            
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            updatePerformanceMetrics(success: false, duration: duration, dataSize: 0)
            throw error
        }
    }
    
    public func performRequest(_ request: NetworkRequest) async throws -> NetworkResponse {
        guard networkStatus.isConnected else {
            throw NetworkError.noConnection
        }
        
        // Check cache first
        if configuration.enableRequestCaching && request.method == .get {
            if let cachedResponse = getCachedResponse(for: request) {
                logger.info("Cache hit for request: \(request.id)")
                updatePerformanceMetrics(success: true, duration: 0, dataSize: Int64(cachedResponse.response.body.count))
                return cachedResponse.response
            }
        }
        
        // Apply request interceptors
        var modifiedRequest = request
        for interceptor in requestInterceptors {
            modifiedRequest = interceptor.intercept(modifiedRequest)
        }
        
        // Create URLRequest
        guard let urlRequest = createURLRequest(from: modifiedRequest) else {
            throw NetworkError.invalidRequest
        }
        
        // Perform request with retry logic
        return try await performRequestWithRetry(urlRequest, originalRequest: modifiedRequest)
    }
    
    public func cancelRequest(withId id: String) {
        // Implementation for cancelling requests
        logger.info("Cancelling request: \(id)")
    }
    
    public func clearCache() {
        requestCache.removeAll()
        logger.info("Cache cleared")
    }
    
    public func addRequestInterceptor(_ interceptor: RequestInterceptor) {
        requestInterceptors.append(interceptor)
    }
    
    public func addResponseInterceptor(_ interceptor: ResponseInterceptor) {
        responseInterceptors.append(interceptor)
    }
    
    public func setRetryPolicy(_ policy: RetryPolicy, for endpoint: String) {
        retryPolicies[endpoint] = policy
    }
    
    public func getPerformanceMetrics() -> NetworkPerformanceMetrics {
        return performanceMetrics
    }
    
    public func resetPerformanceMetrics() {
        performanceMetrics = NetworkPerformanceMetrics()
    }
    
    // MARK: - Private Methods
    
    private func setupNetworkMonitoring() {
        networkMonitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.updateNetworkStatus(path)
            }
        }
        networkMonitor.start(queue: networkQueue)
    }
    
    private func updateNetworkStatus(_ path: NWPath) {
        let newStatus: NetworkStatus
        let newQuality: ConnectionQuality
        
        switch path.status {
        case .satisfied:
            newStatus = .connected
            newQuality = determineConnectionQuality(path)
        case .unsatisfied:
            newStatus = .disconnected
            newQuality = .poor
        case .requiresConnection:
            newStatus = .connecting
            newQuality = .unknown
        @unknown default:
            newStatus = .unknown
            newQuality = .unknown
        }
        
        networkStatus = newStatus
        connectionQuality = newQuality
        
        logger.info("Network status updated: \(newStatus.rawValue), Quality: \(newQuality.rawValue)")
    }
    
    private func determineConnectionQuality(_ path: NWPath) -> ConnectionQuality {
        if path.usesInterfaceType(.wifi) {
            return .excellent
        } else if path.usesInterfaceType(.cellular) {
            return .good
        } else if path.usesInterfaceType(.wiredEthernet) {
            return .excellent
        } else {
            return .fair
        }
    }
    
    private func setupDefaultInterceptors() {
        // Add default request interceptor for authentication
        addRequestInterceptor(AuthenticationInterceptor())
        
        // Add default response interceptor for logging
        addResponseInterceptor(LoggingInterceptor())
    }
    
    private func setupDefaultRetryPolicies() {
        // Default retry policy for all requests
        let defaultPolicy = RetryPolicy(
            maxAttempts: configuration.defaultRetryAttempts,
            baseDelay: configuration.defaultRetryDelay
        )
        
        // Specific policies for different endpoints
        setRetryPolicy(RetryPolicy(maxAttempts: 5, baseDelay: 2.0), for: "health-data")
        setRetryPolicy(RetryPolicy(maxAttempts: 2, baseDelay: 0.5), for: "analytics")
    }
    
    private func updateSessionConfiguration() {
        // Update session configuration when configuration changes
        logger.info("Updating session configuration")
    }
    
    private func createURLRequest(from request: NetworkRequest) -> URLRequest? {
        var urlRequest = URLRequest(url: request.url)
        urlRequest.httpMethod = request.method.rawValue
        urlRequest.httpBody = request.body
        urlRequest.timeoutInterval = request.timeoutInterval
        urlRequest.cachePolicy = request.cachePolicy
        
        // Add headers
        for (key, value) in request.headers {
            urlRequest.setValue(value, forHTTPHeaderField: key)
        }
        
        // Add API version header
        urlRequest.setValue(configuration.apiVersion, forHTTPHeaderField: "API-Version")
        
        return urlRequest
    }
    
    private func performRequestWithRetry(
        _ urlRequest: URLRequest,
        originalRequest: NetworkRequest
    ) async throws -> NetworkResponse {
        // Circuit breaker check for this endpoint
        let endpoint = originalRequest.url.path
        let breaker = circuitBreakers[endpoint] ?? CircuitBreaker()
        circuitBreakers[endpoint] = breaker
        guard breaker.allowRequest() else {
            throw AppError.serverError(statusCode: 503, message: "Circuit breaker open for endpoint: \(endpoint)")
        }
        
        var lastError: NetworkError?
        let maxAttempts = originalRequest.retryPolicy?.maxAttempts ?? configuration.defaultRetryAttempts
        
        for attempt in 1...maxAttempts {
            do {
                let response = try await performSingleRequest(urlRequest, originalRequest: originalRequest)
                
                // Record success in circuit breaker
                breaker.recordSuccess()
                
                // Apply response interceptors
                var modifiedResponse = response
                for interceptor in responseInterceptors {
                    modifiedResponse = interceptor.intercept(modifiedResponse, for: originalRequest)
                }
                
                // Cache successful GET requests
                if configuration.enableRequestCaching && originalRequest.method == .get {
                    cacheResponse(modifiedResponse, for: originalRequest)
                }
                
                return modifiedResponse
                
            } catch let error as NetworkError {
                // Record failure in circuit breaker
                breaker.recordFailure()
                lastError = error
                
                if !error.isRetryable || attempt >= maxAttempts {
                    throw error
                }
                
                // Calculate delay for retry
                let delay = originalRequest.retryPolicy?.calculateDelay(for: attempt) ?? configuration.defaultRetryDelay
                
                logger.info("Retrying request \(originalRequest.id) after \(delay)s (attempt \(attempt)/\(maxAttempts))")
                
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                
            } catch {
                lastError = NetworkError.unknown(error)
                throw lastError!
            }
        }
        
        throw lastError ?? NetworkError.unknown(NSError(domain: "Unknown", code: -1))
    }
    
    private func performSingleRequest(
        _ urlRequest: URLRequest,
        originalRequest: NetworkRequest
    ) async throws -> NetworkResponse {
        let startTime = Date()
        
        do {
            let (data, response) = try await session.data(for: urlRequest)
            let duration = Date().timeIntervalSince(startTime)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.invalidResponse
            }
            
            let networkResponse = NetworkResponse(
                statusCode: httpResponse.statusCode,
                headers: httpResponse.allHeaderFields as? [String: String] ?? [:],
                body: data,
                url: httpResponse.url,
                timestamp: Date(),
                duration: duration
            )
            
            // Handle HTTP status codes
            if networkResponse.isSuccess {
                return networkResponse
            } else if networkResponse.isClientError {
                throw createClientError(for: httpResponse.statusCode)
            } else if networkResponse.isServerError {
                throw NetworkError.serverError(httpResponse.statusCode)
            } else {
                throw NetworkError.invalidResponse
            }
            
        } catch let error as NetworkError {
            throw error
        } catch {
            if (error as NSError).code == NSURLErrorTimedOut {
                throw NetworkError.timeout
            } else if (error as NSError).code == NSURLErrorNotConnectedToInternet {
                throw NetworkError.noConnection
            } else {
                throw NetworkError.unknown(error)
            }
        }
    }
    
    private func createClientError(for statusCode: Int) -> NetworkError {
        switch statusCode {
        case 401:
            return .unauthorized
        case 403:
            return .forbidden
        case 404:
            return .notFound
        case 429:
            return .rateLimited
        default:
            return .clientError(statusCode)
        }
    }
    
    private func getCachedResponse(for request: NetworkRequest) -> CachedResponse? {
        let cacheKey = generateCacheKey(for: request)
        guard let cachedResponse = requestCache[cacheKey] else { return nil }
        
        if cachedResponse.isExpired {
            requestCache.removeValue(forKey: cacheKey)
            return nil
        }
        
        return cachedResponse
    }
    
    private func cacheResponse(_ response: NetworkResponse, for request: NetworkRequest) {
        let cacheKey = generateCacheKey(for: request)
        let expiresAt = Date().addingTimeInterval(300) // 5 minutes default
        
        let cachedResponse = CachedResponse(
            response: response,
            cacheKey: cacheKey,
            createdAt: Date(),
            expiresAt: expiresAt,
            etag: response.headers["ETag"]
        )
        
        requestCache[cacheKey] = cachedResponse
    }
    
    private func generateCacheKey(for request: NetworkRequest) -> String {
        return "\(request.method.rawValue)_\(request.url.absoluteString)"
    }
    
    private func updatePerformanceMetrics(success: Bool, duration: TimeInterval, dataSize: Int64) {
        DispatchQueue.main.async {
            self.performanceMetrics.totalRequests += 1
            self.performanceMetrics.totalDataTransferred += dataSize
            
            if success {
                self.performanceMetrics.successfulRequests += 1
            } else {
                self.performanceMetrics.failedRequests += 1
            }
            
            // Update average response time
            let totalDuration = self.performanceMetrics.averageResponseTime * Double(self.performanceMetrics.totalRequests - 1) + duration
            self.performanceMetrics.averageResponseTime = totalDuration / Double(self.performanceMetrics.totalRequests)
            
            // Update rates
            self.performanceMetrics.errorRate = Double(self.performanceMetrics.failedRequests) / Double(self.performanceMetrics.totalRequests)
        }
    }
}

// MARK: - Default Interceptors

private class AuthenticationInterceptor: NetworkingLayerManager.RequestInterceptor {
    func intercept(_ request: NetworkingLayerManager.NetworkRequest) -> NetworkingLayerManager.NetworkRequest {
        var modifiedRequest = request
        var headers = modifiedRequest.headers
        
        // Add authentication header if available
        if let authToken = getAuthToken() {
            headers["Authorization"] = "Bearer \(authToken)"
        }
        
        // Add API key if available
        if let apiKey = getAPIKey() {
            headers["X-API-Key"] = apiKey
        }
        
        modifiedRequest = NetworkingLayerManager.NetworkRequest(
            id: request.id,
            url: request.url,
            method: request.method,
            headers: headers,
            body: request.body,
            cachePolicy: request.cachePolicy,
            timeoutInterval: request.timeoutInterval,
            retryPolicy: request.retryPolicy,
            priority: request.priority
        )
        
        return modifiedRequest
    }
    
    private func getAuthToken() -> String? {
        // Implementation to get auth token from keychain or user defaults
        return UserDefaults.standard.string(forKey: "auth_token")
    }
    
    private func getAPIKey() -> String? {
        // Implementation to get API key from configuration
        return "your-api-key"
    }
}

private class LoggingInterceptor: NetworkingLayerManager.ResponseInterceptor {
    func intercept(_ response: NetworkingLayerManager.NetworkResponse, for request: NetworkingLayerManager.NetworkRequest) -> NetworkingLayerManager.NetworkResponse {
        let logger = Logger(subsystem: "com.healthai.networking", category: "ResponseLogging")
        
        logger.info("""
        Response for request \(request.id):
        URL: \(request.url)
        Method: \(request.method.rawValue)
        Status: \(response.statusCode)
        Duration: \(String(format: "%.3f", response.duration))s
        Data Size: \(response.body.count) bytes
        """)
        
        return response
    }
}

// MARK: - Error Mapping Extension

extension NetworkingLayerManager {
    /// Maps generic errors to AppError for unified network error handling
    func mapError(_ error: Error) -> AppError {
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet:
                return .networkOffline
            case .timedOut:
                return .timeout
            default:
                return .unknownError(urlError.localizedDescription)
            }
        } else if let appError = error as? AppError {
            return appError
        } else {
            return .unknownError(error.localizedDescription)
        }
    }
} 
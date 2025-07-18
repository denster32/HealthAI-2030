import Foundation
import Network
import CryptoKit

/// Protocol defining the requirements for API gateway management
protocol APIGatewayProtocol {
    func authenticateRequest(_ request: APIRequest) async throws -> AuthenticationResult
    func routeRequest(_ request: APIRequest) async throws -> APIResponse
    func applyRateLimiting(for clientID: String) async throws -> RateLimitResult
    func logRequest(_ request: APIRequest, response: APIResponse, duration: TimeInterval)
}

/// Structure representing an API request
struct APIRequest: Codable, Identifiable {
    let id: String
    let clientID: String
    let endpoint: String
    let method: HTTPMethod
    let headers: [String: String]
    let body: Data?
    let timestamp: Date
    let ipAddress: String
    
    init(clientID: String, endpoint: String, method: HTTPMethod, headers: [String: String] = [:], body: Data? = nil, ipAddress: String) {
        self.id = UUID().uuidString
        self.clientID = clientID
        self.endpoint = endpoint
        self.method = method
        self.headers = headers
        self.body = body
        self.timestamp = Date()
        self.ipAddress = ipAddress
    }
}

/// Structure representing an API response
struct APIResponse: Codable, Identifiable {
    let id: String
    let requestID: String
    let statusCode: Int
    let headers: [String: String]
    let body: Data?
    let timestamp: Date
    let processingTime: TimeInterval
    
    init(requestID: String, statusCode: Int, headers: [String: String] = [:], body: Data? = nil, processingTime: TimeInterval) {
        self.id = UUID().uuidString
        self.requestID = requestID
        self.statusCode = statusCode
        self.headers = headers
        self.body = body
        self.timestamp = Date()
        self.processingTime = processingTime
    }
}

/// Structure representing authentication result
struct AuthenticationResult: Codable {
    let isAuthenticated: Bool
    let clientID: String
    let permissions: [String]
    let rateLimitTier: RateLimitTier
    let errorMessage: String?
    
    init(isAuthenticated: Bool, clientID: String, permissions: [String] = [], rateLimitTier: RateLimitTier = .basic, errorMessage: String? = nil) {
        self.isAuthenticated = isAuthenticated
        self.clientID = clientID
        self.permissions = permissions
        self.rateLimitTier = rateLimitTier
        self.errorMessage = errorMessage
    }
}

/// Structure representing rate limit result
struct RateLimitResult: Codable {
    let isAllowed: Bool
    let remainingRequests: Int
    let resetTime: Date
    let limitExceeded: Bool
    
    init(isAllowed: Bool, remainingRequests: Int, resetTime: Date, limitExceeded: Bool = false) {
        self.isAllowed = isAllowed
        self.remainingRequests = remainingRequests
        self.resetTime = resetTime
        self.limitExceeded = limitExceeded
    }
}

/// Enum representing HTTP methods
enum HTTPMethod: String, Codable, CaseIterable {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case DELETE = "DELETE"
    case PATCH = "PATCH"
}

/// Enum representing rate limit tiers
enum RateLimitTier: String, Codable, CaseIterable {
    case basic = "basic"
    case premium = "premium"
    case enterprise = "enterprise"
    case unlimited = "unlimited"
    
    var requestsPerHour: Int {
        switch self {
        case .basic: return 1000
        case .premium: return 10000
        case .enterprise: return 100000
        case .unlimited: return Int.max
        }
    }
}

/// Actor responsible for managing the public API gateway
actor PublicAPIGateway: APIGatewayProtocol {
    private let authenticationManager: APIAuthenticationManager
    private let rateLimiter: APIRateLimiter
    private let router: APIRequestRouter
    private let logger: Logger
    private let metricsCollector: APIMetricsCollector
    
    init() {
        self.authenticationManager = APIAuthenticationManager()
        self.rateLimiter = APIRateLimiter()
        self.router = APIRequestRouter()
        self.logger = Logger(subsystem: "com.healthai2030.api", category: "APIGateway")
        self.metricsCollector = APIMetricsCollector()
    }
    
    /// Processes an incoming API request through the gateway
    /// - Parameter request: The API request to process
    /// - Returns: APIResponse object
    func processRequest(_ request: APIRequest) async throws -> APIResponse {
        let startTime = Date()
        
        logger.info("Processing API request: \(request.method.rawValue) \(request.endpoint) from client: \(request.clientID)")
        
        // Step 1: Authenticate the request
        let authResult = try await authenticateRequest(request)
        guard authResult.isAuthenticated else {
            logger.warning("Authentication failed for client: \(request.clientID), reason: \(authResult.errorMessage ?? "Unknown")")
            return createErrorResponse(
                requestID: request.id,
                statusCode: 401,
                message: "Authentication failed: \(authResult.errorMessage ?? "Invalid credentials")"
            )
        }
        
        // Step 2: Apply rate limiting
        let rateLimitResult = try await applyRateLimiting(for: request.clientID)
        guard rateLimitResult.isAllowed else {
            logger.warning("Rate limit exceeded for client: \(request.clientID)")
            return createErrorResponse(
                requestID: request.id,
                statusCode: 429,
                message: "Rate limit exceeded. Reset time: \(rateLimitResult.resetTime)"
            )
        }
        
        // Step 3: Route the request to appropriate handler
        let response = try await routeRequest(request)
        
        // Step 4: Log the request and response
        let processingTime = Date().timeIntervalSince(startTime)
        logRequest(request, response: response, duration: processingTime)
        
        // Step 5: Collect metrics
        await metricsCollector.recordRequest(
            clientID: request.clientID,
            endpoint: request.endpoint,
            method: request.method,
            statusCode: response.statusCode,
            processingTime: processingTime
        )
        
        logger.info("Completed API request processing in \(String(format: "%.3f", processingTime))s")
        return response
    }
    
    /// Authenticates an API request
    /// - Parameter request: The API request to authenticate
    /// - Returns: AuthenticationResult indicating authentication status
    func authenticateRequest(_ request: APIRequest) async throws -> AuthenticationResult {
        logger.info("Authenticating request for client: \(request.clientID)")
        
        // Extract API key from headers
        guard let apiKey = request.headers["X-API-Key"] else {
            return AuthenticationResult(
                isAuthenticated: false,
                clientID: request.clientID,
                errorMessage: "Missing API key"
            )
        }
        
        // Validate API key
        let authResult = try await authenticationManager.validateAPIKey(apiKey, for: request.clientID)
        
        if authResult.isAuthenticated {
            logger.info("Authentication successful for client: \(request.clientID)")
        } else {
            logger.warning("Authentication failed for client: \(request.clientID)")
        }
        
        return authResult
    }
    
    /// Routes an authenticated request to the appropriate handler
    /// - Parameter request: The authenticated API request
    /// - Returns: APIResponse from the handler
    func routeRequest(_ request: APIRequest) async throws -> APIResponse {
        logger.info("Routing request to endpoint: \(request.endpoint)")
        
        let response = try await router.route(request)
        
        logger.info("Request routed successfully, status code: \(response.statusCode)")
        return response
    }
    
    /// Applies rate limiting for a client
    /// - Parameter clientID: The client ID to check rate limits for
    /// - Returns: RateLimitResult indicating if request is allowed
    func applyRateLimiting(for clientID: String) async throws -> RateLimitResult {
        logger.info("Checking rate limits for client: \(clientID)")
        
        let result = try await rateLimiter.checkRateLimit(for: clientID)
        
        if !result.isAllowed {
            logger.warning("Rate limit exceeded for client: \(clientID)")
        }
        
        return result
    }
    
    /// Logs request and response details
    /// - Parameters:
    ///   - request: The original API request
    ///   - response: The API response
    ///   - duration: Processing duration in seconds
    func logRequest(_ request: APIRequest, response: APIResponse, duration: TimeInterval) {
        let logEntry = APILogEntry(
            requestID: request.id,
            clientID: request.clientID,
            endpoint: request.endpoint,
            method: request.method,
            statusCode: response.statusCode,
            processingTime: duration,
            timestamp: Date(),
            ipAddress: request.ipAddress
        )
        
        Task {
            await logger.logAPIAccess(logEntry)
        }
    }
    
    /// Creates an error response
    private func createErrorResponse(requestID: String, statusCode: Int, message: String) -> APIResponse {
        let errorBody = ["error": message, "status_code": statusCode]
        let bodyData = try? JSONSerialization.data(withJSONObject: errorBody)
        
        return APIResponse(
            requestID: requestID,
            statusCode: statusCode,
            headers: ["Content-Type": "application/json"],
            body: bodyData,
            processingTime: 0
        )
    }
}

/// Class managing API authentication
class APIAuthenticationManager {
    private let logger: Logger
    private let apiKeyStore: APIKeyStore
    
    init() {
        self.logger = Logger(subsystem: "com.healthai2030.api", category: "Authentication")
        self.apiKeyStore = APIKeyStore()
    }
    
    /// Validates an API key for a client
    func validateAPIKey(_ apiKey: String, for clientID: String) async throws -> AuthenticationResult {
        logger.info("Validating API key for client: \(clientID)")
        
        guard let clientInfo = await apiKeyStore.getClientInfo(for: apiKey) else {
            return AuthenticationResult(
                isAuthenticated: false,
                clientID: clientID,
                errorMessage: "Invalid API key"
            )
        }
        
        guard clientInfo.clientID == clientID else {
            return AuthenticationResult(
                isAuthenticated: false,
                clientID: clientID,
                errorMessage: "API key does not match client ID"
            )
        }
        
        guard clientInfo.isActive else {
            return AuthenticationResult(
                isAuthenticated: false,
                clientID: clientID,
                errorMessage: "API key is inactive"
            )
        }
        
        return AuthenticationResult(
            isAuthenticated: true,
            clientID: clientID,
            permissions: clientInfo.permissions,
            rateLimitTier: clientInfo.rateLimitTier
        )
    }
}

/// Class managing API rate limiting
class APIRateLimiter {
    private let logger: Logger
    private let rateLimitStore: RateLimitStore
    
    init() {
        self.logger = Logger(subsystem: "com.healthai2030.api", category: "RateLimiter")
        self.rateLimitStore = RateLimitStore()
    }
    
    /// Checks rate limits for a client
    func checkRateLimit(for clientID: String) async throws -> RateLimitResult {
        logger.info("Checking rate limit for client: \(clientID)")
        
        let currentUsage = await rateLimitStore.getCurrentUsage(for: clientID)
        let clientInfo = await rateLimitStore.getClientInfo(for: clientID)
        
        guard let info = clientInfo else {
            throw RateLimitError.clientNotFound
        }
        
        let limit = info.rateLimitTier.requestsPerHour
        let remaining = max(0, limit - currentUsage)
        let isAllowed = remaining > 0
        
        if isAllowed {
            await rateLimitStore.incrementUsage(for: clientID)
        }
        
        let resetTime = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
        
        return RateLimitResult(
            isAllowed: isAllowed,
            remainingRequests: remaining,
            resetTime: resetTime,
            limitExceeded: !isAllowed
        )
    }
}

/// Class managing API request routing
class APIRequestRouter {
    private let logger: Logger
    private let handlers: [String: APIRequestHandler]
    
    init() {
        self.logger = Logger(subsystem: "com.healthai2030.api", category: "Router")
        self.handlers = [
            "/api/v1/health": HealthDataHandler(),
            "/api/v1/analytics": AnalyticsHandler(),
            "/api/v1/research": ResearchHandler(),
            "/api/v1/integrations": IntegrationHandler()
        ]
    }
    
    /// Routes a request to the appropriate handler
    func route(_ request: APIRequest) async throws -> APIResponse {
        logger.info("Routing request to: \(request.endpoint)")
        
        guard let handler = handlers[request.endpoint] else {
            logger.warning("No handler found for endpoint: \(request.endpoint)")
            throw RoutingError.endpointNotFound(request.endpoint)
        }
        
        return try await handler.handle(request)
    }
}

/// Protocol for API request handlers
protocol APIRequestHandler {
    func handle(_ request: APIRequest) async throws -> APIResponse
}

/// Handler for health data endpoints
class HealthDataHandler: APIRequestHandler {
    func handle(_ request: APIRequest) async throws -> APIResponse {
        // Implementation would handle health data API requests
        let responseBody = ["status": "success", "data": "Health data endpoint"]
        let bodyData = try JSONSerialization.data(withJSONObject: responseBody)
        
        return APIResponse(
            requestID: request.id,
            statusCode: 200,
            headers: ["Content-Type": "application/json"],
            body: bodyData,
            processingTime: 0.1
        )
    }
}

/// Handler for analytics endpoints
class AnalyticsHandler: APIRequestHandler {
    func handle(_ request: APIRequest) async throws -> APIResponse {
        // Implementation would handle analytics API requests
        let responseBody = ["status": "success", "data": "Analytics endpoint"]
        let bodyData = try JSONSerialization.data(withJSONObject: responseBody)
        
        return APIResponse(
            requestID: request.id,
            statusCode: 200,
            headers: ["Content-Type": "application/json"],
            body: bodyData,
            processingTime: 0.2
        )
    }
}

/// Handler for research endpoints
class ResearchHandler: APIRequestHandler {
    func handle(_ request: APIRequest) async throws -> APIResponse {
        // Implementation would handle research API requests
        let responseBody = ["status": "success", "data": "Research endpoint"]
        let bodyData = try JSONSerialization.data(withJSONObject: responseBody)
        
        return APIResponse(
            requestID: request.id,
            statusCode: 200,
            headers: ["Content-Type": "application/json"],
            body: bodyData,
            processingTime: 0.15
        )
    }
}

/// Handler for integration endpoints
class IntegrationHandler: APIRequestHandler {
    func handle(_ request: APIRequest) async throws -> APIResponse {
        // Implementation would handle integration API requests
        let responseBody = ["status": "success", "data": "Integration endpoint"]
        let bodyData = try JSONSerialization.data(withJSONObject: responseBody)
        
        return APIResponse(
            requestID: request.id,
            statusCode: 200,
            headers: ["Content-Type": "application/json"],
            body: bodyData,
            processingTime: 0.12
        )
    }
}

/// Class managing API metrics collection
class APIMetricsCollector {
    private let logger: Logger
    private let metricsStore: MetricsStore
    
    init() {
        self.logger = Logger(subsystem: "com.healthai2030.api", category: "Metrics")
        self.metricsStore = MetricsStore()
    }
    
    /// Records API request metrics
    func recordRequest(clientID: String, endpoint: String, method: HTTPMethod, statusCode: Int, processingTime: TimeInterval) async {
        let metric = APIMetric(
            clientID: clientID,
            endpoint: endpoint,
            method: method,
            statusCode: statusCode,
            processingTime: processingTime,
            timestamp: Date()
        )
        
        await metricsStore.storeMetric(metric)
        logger.info("Recorded metric for client: \(clientID), endpoint: \(endpoint), status: \(statusCode)")
    }
}

/// Structure representing API log entry
struct APILogEntry: Codable, Identifiable {
    let id: String
    let requestID: String
    let clientID: String
    let endpoint: String
    let method: HTTPMethod
    let statusCode: Int
    let processingTime: TimeInterval
    let timestamp: Date
    let ipAddress: String
    
    init(requestID: String, clientID: String, endpoint: String, method: HTTPMethod, statusCode: Int, processingTime: TimeInterval, timestamp: Date, ipAddress: String) {
        self.id = UUID().uuidString
        self.requestID = requestID
        self.clientID = clientID
        self.endpoint = endpoint
        self.method = method
        self.statusCode = statusCode
        self.processingTime = processingTime
        self.timestamp = timestamp
        self.ipAddress = ipAddress
    }
}

/// Structure representing API metric
struct APIMetric: Codable, Identifiable {
    let id: String
    let clientID: String
    let endpoint: String
    let method: HTTPMethod
    let statusCode: Int
    let processingTime: TimeInterval
    let timestamp: Date
    
    init(clientID: String, endpoint: String, method: HTTPMethod, statusCode: Int, processingTime: TimeInterval, timestamp: Date) {
        self.id = UUID().uuidString
        self.clientID = clientID
        self.endpoint = endpoint
        self.method = method
        self.statusCode = statusCode
        self.processingTime = processingTime
        self.timestamp = timestamp
    }
}

/// Structure representing client information
struct ClientInfo: Codable, Identifiable {
    let id: String
    let clientID: String
    let name: String
    let apiKey: String
    let isActive: Bool
    let permissions: [String]
    let rateLimitTier: RateLimitTier
    let createdAt: Date
    
    init(clientID: String, name: String, apiKey: String, isActive: Bool = true, permissions: [String] = [], rateLimitTier: RateLimitTier = .basic) {
        self.id = UUID().uuidString
        self.clientID = clientID
        self.name = name
        self.apiKey = apiKey
        self.isActive = isActive
        self.permissions = permissions
        self.rateLimitTier = rateLimitTier
        self.createdAt = Date()
    }
}

/// Class managing API key storage
class APIKeyStore {
    private let logger: Logger
    private let storageQueue = DispatchQueue(label: "com.healthai2030.apikeystore")
    private var clients: [String: ClientInfo] = [:]
    
    init() {
        self.logger = Logger(subsystem: "com.healthai2030.api", category: "APIKeyStore")
        loadClientsFromStorage()
    }
    
    /// Gets client information for an API key
    func getClientInfo(for apiKey: String) async -> ClientInfo? {
        var clientInfo: ClientInfo?
        storageQueue.sync {
            clientInfo = clients.values.first { $0.apiKey == apiKey }
        }
        return clientInfo
    }
    
    /// Loads clients from persistent storage
    private func loadClientsFromStorage() {
        // In a real implementation, this would load from a database
        // For now, we'll create some sample clients
        let sampleClients = [
            ClientInfo(clientID: "client001", name: "Sample Client 1", apiKey: "sample_key_1", permissions: ["read:health", "read:analytics"]),
            ClientInfo(clientID: "client002", name: "Sample Client 2", apiKey: "sample_key_2", permissions: ["read:health"], rateLimitTier: .premium)
        ]
        
        storageQueue.sync {
            for client in sampleClients {
                clients[client.clientID] = client
            }
        }
        
        logger.info("Loaded \(sampleClients.count) clients from storage")
    }
}

/// Class managing rate limit storage
class RateLimitStore {
    private let logger: Logger
    private let storageQueue = DispatchQueue(label: "com.healthai2030.ratelimitstore")
    private var usage: [String: Int] = [:]
    private var clientInfo: [String: ClientInfo] = [:]
    
    init() {
        self.logger = Logger(subsystem: "com.healthai2030.api", category: "RateLimitStore")
        loadClientInfoFromStorage()
    }
    
    /// Gets current usage for a client
    func getCurrentUsage(for clientID: String) async -> Int {
        var currentUsage: Int = 0
        storageQueue.sync {
            currentUsage = usage[clientID] ?? 0
        }
        return currentUsage
    }
    
    /// Gets client information for rate limiting
    func getClientInfo(for clientID: String) async -> ClientInfo? {
        var info: ClientInfo?
        storageQueue.sync {
            info = clientInfo[clientID]
        }
        return info
    }
    
    /// Increments usage for a client
    func incrementUsage(for clientID: String) async {
        storageQueue.sync {
            usage[clientID] = (usage[clientID] ?? 0) + 1
        }
    }
    
    /// Loads client information from storage
    private func loadClientInfoFromStorage() {
        // In a real implementation, this would load from a database
        let sampleClients = [
            ClientInfo(clientID: "client001", name: "Sample Client 1", apiKey: "sample_key_1", rateLimitTier: .basic),
            ClientInfo(clientID: "client002", name: "Sample Client 2", apiKey: "sample_key_2", rateLimitTier: .premium)
        ]
        
        storageQueue.sync {
            for client in sampleClients {
                clientInfo[client.clientID] = client
            }
        }
        
        logger.info("Loaded \(sampleClients.count) client info records for rate limiting")
    }
}

/// Class managing metrics storage
class MetricsStore {
    private let logger: Logger
    private let storageQueue = DispatchQueue(label: "com.healthai2030.metricsstore")
    private var metrics: [APIMetric] = []
    
    init() {
        self.logger = Logger(subsystem: "com.healthai2030.api", category: "MetricsStore")
    }
    
    /// Stores an API metric
    func storeMetric(_ metric: APIMetric) async {
        storageQueue.sync {
            metrics.append(metric)
            
            // Keep only last 10000 metrics to prevent memory issues
            if metrics.count > 10000 {
                metrics.removeFirst(metrics.count - 10000)
            }
        }
    }
}

/// Extension for Logger to handle API access logging
extension Logger {
    func logAPIAccess(_ logEntry: APILogEntry) async {
        // In a real implementation, this would write to a log file or database
        info("API Access: \(logEntry.method.rawValue) \(logEntry.endpoint) - Client: \(logEntry.clientID) - Status: \(logEntry.statusCode) - Time: \(String(format: "%.3f", logEntry.processingTime))s")
    }
}

/// Custom error types for API gateway operations
enum GatewayError: Error {
    case authenticationFailed(String)
    case rateLimitExceeded
    case invalidRequest(String)
    case internalServerError(String)
}

/// Custom error types for rate limiting
enum RateLimitError: Error {
    case clientNotFound
    case invalidRateLimitTier
}

/// Custom error types for routing
enum RoutingError: Error {
    case endpointNotFound(String)
    case invalidHandler(String)
}

extension PublicAPIGateway {
    /// Configuration for the API gateway
    struct Configuration {
        let maxRequestSize: Int
        let timeoutSeconds: TimeInterval
        let enableCaching: Bool
        let cacheTTLSeconds: TimeInterval
        
        static let `default` = Configuration(
            maxRequestSize: 10 * 1024 * 1024, // 10MB
            timeoutSeconds: 30.0,
            enableCaching: true,
            cacheTTLSeconds: 300 // 5 minutes
        )
    }
    
    /// Health check for the API gateway
    func healthCheck() async -> GatewayHealthStatus {
        logger.info("Performing API gateway health check")
        
        let authStatus = await authenticationManager.healthCheck()
        let rateLimitStatus = await rateLimiter.healthCheck()
        let routerStatus = await router.healthCheck()
        
        let isHealthy = authStatus && rateLimitStatus && routerStatus
        
        return GatewayHealthStatus(
            isHealthy: isHealthy,
            components: [
                "authentication": authStatus,
                "rate_limiting": rateLimitStatus,
                "routing": routerStatus
            ],
            timestamp: Date()
        )
    }
}

/// Structure representing gateway health status
struct GatewayHealthStatus: Codable {
    let isHealthy: Bool
    let components: [String: Bool]
    let timestamp: Date
}

/// Extension for health check methods
extension APIAuthenticationManager {
    func healthCheck() async -> Bool {
        // In a real implementation, this would check database connectivity
        return true
    }
}

extension APIRateLimiter {
    func healthCheck() async -> Bool {
        // In a real implementation, this would check storage connectivity
        return true
    }
}

extension APIRequestRouter {
    func healthCheck() async -> Bool {
        // In a real implementation, this would check handler availability
        return true
    }
} 
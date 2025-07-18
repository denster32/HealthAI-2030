import Foundation
import os.log

/// API Gateway Manager: Handles API request routing, rate limiting, authentication, caching, monitoring, and analytics.
public class APIGatewayManager {
    public static let shared = APIGatewayManager()
    private let logger = Logger(subsystem: "com.healthai.gateway", category: "APIGateway")
    
    // MARK: - Rate Limiting
    private var requestCounts: [String: Int] = [:] // Keyed by user/session
    private let rateLimit: Int = 100 // requests per minute
    private let rateLimitWindow: TimeInterval = 60 // seconds
    private var lastReset: Date = Date()
    
    // MARK: - Authentication
    public func authenticate(token: String) -> Bool {
        // Stub: Validate token (JWT, OAuth, etc.)
        return !token.isEmpty
    }
    
    // MARK: - Authorization
    public func authorize(userRole: String, endpoint: String) -> Bool {
        // Stub: Check if userRole is allowed to access endpoint
        return true
    }
    
    // MARK: - Rate Limiting
    public func isRateLimited(userId: String) -> Bool {
        resetIfNeeded()
        let count = requestCounts[userId, default: 0]
        if count >= rateLimit {
            logger.warning("User \(userId) is rate limited.")
            return true
        }
        requestCounts[userId] = count + 1
        return false
    }
    private func resetIfNeeded() {
        if Date().timeIntervalSince(lastReset) > rateLimitWindow {
            requestCounts.removeAll()
            lastReset = Date()
        }
    }
    
    // MARK: - Request/Response Transformation
    public func transformRequest(_ request: URLRequest) -> URLRequest {
        // Stub: Modify request as needed (e.g., add headers)
        return request
    }
    public func transformResponse(_ response: URLResponse, data: Data) -> (URLResponse, Data) {
        // Stub: Modify response/data as needed
        return (response, data)
    }
    
    // MARK: - Caching
    private let cache = NSCache<NSString, NSData>()
    public func cacheResponse(for key: String, data: Data) {
        cache.setObject(data as NSData, forKey: key as NSString)
    }
    public func getCachedResponse(for key: String) -> Data? {
        return cache.object(forKey: key as NSString) as Data?
    }
    
    // MARK: - Monitoring & Analytics
    public struct APIMetrics {
        public let endpoint: String
        public let responseTime: TimeInterval
        public let statusCode: Int
        public let timestamp: Date
    }
    private(set) var metrics: [APIMetrics] = []
    public func recordMetric(endpoint: String, responseTime: TimeInterval, statusCode: Int) {
        let metric = APIMetrics(endpoint: endpoint, responseTime: responseTime, statusCode: statusCode, timestamp: Date())
        metrics.append(metric)
        logger.info("API metric recorded: \(endpoint) \(statusCode) \(responseTime)s")
    }
    public func getMetrics(for endpoint: String) -> [APIMetrics] {
        return metrics.filter { $0.endpoint == endpoint }
    }
    
    // MARK: - API Routing
    public func routeRequest(_ request: URLRequest, userId: String, userRole: String, completion: @escaping (Result<(URLResponse, Data), Error>) -> Void) {
        guard authenticate(token: request.value(forHTTPHeaderField: "Authorization") ?? "") else {
            completion(.failure(NSError(domain: "APIGateway", code: 401, userInfo: [NSLocalizedDescriptionKey: "Unauthorized"])))
            return
        }
        guard authorize(userRole: userRole, endpoint: request.url?.path ?? "") else {
            completion(.failure(NSError(domain: "APIGateway", code: 403, userInfo: [NSLocalizedDescriptionKey: "Forbidden"])))
            return
        }
        guard !isRateLimited(userId: userId) else {
            completion(.failure(NSError(domain: "APIGateway", code: 429, userInfo: [NSLocalizedDescriptionKey: "Rate limit exceeded"])))
            return
        }
        // Caching (GET only)
        if request.httpMethod == "GET", let url = request.url?.absoluteString, let cached = getCachedResponse(for: url) {
            let response = URLResponse(url: request.url!, mimeType: nil, expectedContentLength: cached.count, textEncodingName: nil)
            completion(.success((response, cached)))
            return
        }
        // Forward request (stub: simulate network call)
        let start = Date()
        let dummyData = Data("{\"result\":\"success\"}".utf8)
        let response = URLResponse(url: request.url!, mimeType: "application/json", expectedContentLength: dummyData.count, textEncodingName: nil)
        let elapsed = Date().timeIntervalSince(start)
        recordMetric(endpoint: request.url?.path ?? "", responseTime: elapsed, statusCode: 200)
        if request.httpMethod == "GET", let url = request.url?.absoluteString {
            cacheResponse(for: url, data: dummyData)
        }
        completion(.success((response, dummyData)))
    }
} 
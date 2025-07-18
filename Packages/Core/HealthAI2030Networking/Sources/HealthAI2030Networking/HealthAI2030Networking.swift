import Foundation
import Network
import os.log

@available(iOS 18.0, macOS 15.0, watchOS 11.0, tvOS 18.0, *)
public struct HealthAI2030Networking {
    
    // MARK: - Configuration
    
    public struct NetworkConfiguration {
        public let baseURL: URL
        public let timeout: TimeInterval
        public let enableCertificatePinning: Bool
        public let securityPolicy: CertificatePinningManager.SecurityPolicy
        public let retryPolicy: RetryPolicy
        public let rateLimitConfiguration: RateLimitingManager.RateLimitConfiguration
        public let enableCompression: Bool
        public let enableOfflineSupport: Bool
        
        public struct RetryPolicy {
            public let maxRetries: Int
            public let initialDelay: TimeInterval
            public let backoffMultiplier: Double
            
            public init(maxRetries: Int = 3, initialDelay: TimeInterval = 1.0, backoffMultiplier: Double = 2.0) {
                self.maxRetries = maxRetries
                self.initialDelay = initialDelay
                self.backoffMultiplier = backoffMultiplier
            }
        }
        
        public init(
            baseURL: URL,
            timeout: TimeInterval = 30.0,
            enableCertificatePinning: Bool = true,
            securityPolicy: CertificatePinningManager.SecurityPolicy = .production,
            retryPolicy: RetryPolicy = RetryPolicy(),
            rateLimitConfiguration: RateLimitingManager.RateLimitConfiguration = .production,
            enableCompression: Bool = true,
            enableOfflineSupport: Bool = true
        ) {
            self.baseURL = baseURL
            self.timeout = timeout
            self.enableCertificatePinning = enableCertificatePinning
            self.securityPolicy = securityPolicy
            self.retryPolicy = retryPolicy
            self.rateLimitConfiguration = rateLimitConfiguration
            self.enableCompression = enableCompression
            self.enableOfflineSupport = enableOfflineSupport
        }
        
        /// Default production configuration
        public static let production = NetworkConfiguration(
            baseURL: URL(string: "https://api.healthai2030.com")!,
            enableCertificatePinning: true,
            securityPolicy: .production,
            rateLimitConfiguration: .production
        )
        
        /// Development configuration
        public static let development = NetworkConfiguration(
            baseURL: URL(string: "https://dev-api.healthai2030.com")!,
            enableCertificatePinning: false,
            securityPolicy: .development,
            rateLimitConfiguration: .development
        )
    }
    
    // MARK: - Properties
    
    private let configuration: NetworkConfiguration
    private let urlSession: URLSession
    private let rateLimitingManager: RateLimitingManager
    private let compressionManager: NetworkCompressionManager
    private let offlineManager: OfflineFirstManager?
    private let logger = Logger(subsystem: "com.healthai.networking", category: "HealthAI2030Networking")
    
    // MARK: - Initialization
    
    public init(configuration: NetworkConfiguration = .production) async throws {
        self.configuration = configuration
        self.rateLimitingManager = RateLimitingManager(configuration: configuration.rateLimitConfiguration)
        self.compressionManager = NetworkCompressionManager(config: .default)
        
        // Initialize offline manager if needed
        if configuration.enableOfflineSupport {
            self.offlineManager = try await OfflineFirstManager(
                networking: self,
                syncStrategy: .smart,
                conflictResolution: .mostRecent
            )
        } else {
            self.offlineManager = nil
        }
        
        if configuration.enableCertificatePinning {
            self.urlSession = URLSession.healthAIPinnedSession(
                configuration: configuration.securityPolicy.configuration
            )
            logger.info("Networking initialized with certificate pinning, compression, and rate limiting")
        } else {
            let sessionConfig = URLSessionConfiguration.default
            sessionConfig.timeoutIntervalForRequest = configuration.timeout
            sessionConfig.timeoutIntervalForResource = configuration.timeout * 2
            self.urlSession = URLSession(configuration: sessionConfig)
            logger.warning("Networking initialized without certificate pinning (development mode)")
        }
    }
    
    // MARK: - Public Methods
    
    public func version() -> String {
        return "2.0.0"
    }
    
    /// Secure HTTP GET request with certificate pinning and rate limiting
    public func get<T: Codable>(
        endpoint: String,
        responseType: T.Type,
        headers: [String: String] = [:]
    ) async throws -> T {
        // Check rate limit before proceeding
        try await rateLimitingManager.waitForAvailability(for: endpoint)
        
        let url = configuration.baseURL.appendingPathComponent(endpoint)
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = configuration.timeout
        
        // Add headers
        headers.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        // Add standard headers
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("HealthAI2030/\(version())", forHTTPHeaderField: "User-Agent")
        
        // Add compression headers if enabled
        if configuration.enableCompression {
            compressionManager.addCompressionHeaders(to: &request)
        }
        
        logger.debug("Making rate-limited GET request to: \(url)")
        
        return try await NetworkErrorHandler.shared.exponentialBackoffRetry(
            operation: {
                let (data, response) = try await urlSession.data(for: request)
                try validateResponse(response, data: data)
                
                // Handle compressed response if needed
                let decompressedData = if configuration.enableCompression,
                                          let httpResponse = response as? HTTPURLResponse {
                    try await compressionManager.processResponse(httpResponse, data: data)
                } else {
                    data
                }
                
                return try JSONDecoder().decode(T.self, from: decompressedData)
            },
            maxRetries: configuration.retryPolicy.maxRetries,
            initialDelay: configuration.retryPolicy.initialDelay
        )
    }
    
    /// Secure HTTP POST request with certificate pinning and rate limiting
    public func post<T: Codable, U: Codable>(
        endpoint: String,
        body: T,
        responseType: U.Type,
        headers: [String: String] = [:]
    ) async throws -> U {
        // Check rate limit before proceeding
        try await rateLimitingManager.waitForAvailability(for: endpoint)
        
        let url = configuration.baseURL.appendingPathComponent(endpoint)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = configuration.timeout
        
        // Add headers
        headers.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        // Add standard headers
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("HealthAI2030/\(version())", forHTTPHeaderField: "User-Agent")
        
        // Encode body
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let bodyData = try encoder.encode(body)
        
        // Compress body if enabled and size threshold met
        if configuration.enableCompression {
            do {
                let (compressedData, algorithm, stats) = try await compressionManager.compress(bodyData)
                request.httpBody = compressedData
                request.setValue(algorithm.contentEncoding, forHTTPHeaderField: "Content-Encoding")
                logger.debug("Compressed request body: \(stats.percentageSaved)% saved")
            } catch {
                // Fall back to uncompressed if compression fails
                request.httpBody = bodyData
            }
        } else {
            request.httpBody = bodyData
        }
        
        logger.debug("Making rate-limited POST request to: \(url)")
        
        return try await NetworkErrorHandler.shared.exponentialBackoffRetry(
            operation: {
                let (data, response) = try await urlSession.data(for: request)
                try validateResponse(response, data: data)
                
                // Handle compressed response if needed
                let decompressedData = if configuration.enableCompression,
                                          let httpResponse = response as? HTTPURLResponse {
                    try await compressionManager.processResponse(httpResponse, data: data)
                } else {
                    data
                }
                
                return try JSONDecoder().decode(U.self, from: decompressedData)
            },
            maxRetries: configuration.retryPolicy.maxRetries,
            initialDelay: configuration.retryPolicy.initialDelay
        )
    }
    
    /// Upload file with certificate pinning and rate limiting
    public func uploadFile(
        endpoint: String,
        fileURL: URL,
        mimeType: String,
        headers: [String: String] = [:]
    ) async throws -> Data {
        // Check rate limit before proceeding
        try await rateLimitingManager.waitForAvailability(for: endpoint)
        
        let url = configuration.baseURL.appendingPathComponent(endpoint)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = configuration.timeout * 3 // Longer timeout for uploads
        
        // Add headers
        headers.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        request.setValue(mimeType, forHTTPHeaderField: "Content-Type")
        request.setValue("HealthAI2030/\(version())", forHTTPHeaderField: "User-Agent")
        
        logger.debug("Making rate-limited file upload to: \(url)")
        
        return try await NetworkErrorHandler.shared.exponentialBackoffRetry(
            operation: {
                let (data, response) = try await urlSession.upload(for: request, fromFile: fileURL)
                try validateResponse(response, data: data)
                return data
            },
            maxRetries: 1, // Don't retry file uploads
            initialDelay: configuration.retryPolicy.initialDelay
        )
    }
    
    /// Download file with certificate pinning and rate limiting
    public func downloadFile(
        endpoint: String,
        headers: [String: String] = [:]
    ) async throws -> URL {
        // Check rate limit before proceeding
        try await rateLimitingManager.waitForAvailability(for: endpoint)
        
        let url = configuration.baseURL.appendingPathComponent(endpoint)
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = configuration.timeout * 3 // Longer timeout for downloads
        
        // Add headers
        headers.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        request.setValue("HealthAI2030/\(version())", forHTTPHeaderField: "User-Agent")
        
        logger.debug("Making rate-limited file download from: \(url)")
        
        return try await NetworkErrorHandler.shared.exponentialBackoffRetry(
            operation: {
                let (downloadURL, response) = try await urlSession.download(for: request)
                try validateResponse(response, data: nil)
                return downloadURL
            },
            maxRetries: configuration.retryPolicy.maxRetries,
            initialDelay: configuration.retryPolicy.initialDelay
        )
    }
    
    /// Get current rate limit status for an endpoint
    public func getRateLimitStatus(for endpoint: String) async -> RateLimitStatus {
        return await rateLimitingManager.getRateLimitStatus(for: endpoint)
    }
    
    /// Reset rate limits (useful for testing or admin purposes)
    public func resetRateLimits() async {
        await rateLimitingManager.resetRateLimits()
        logger.info("Rate limits reset")
    }
    
    /// Check if a request would be allowed without making it
    public func checkRateLimit(for endpoint: String) async -> RateLimitResult {
        return await rateLimitingManager.allowRequest(for: endpoint)
    }
    
    // MARK: - Private Methods
    
    private func validateResponse(_ response: URLResponse, data: Data?) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AppNetworkError.invalidResponse
        }
        
        logger.debug("Response status: \(httpResponse.statusCode)")
        
        switch httpResponse.statusCode {
        case 200...299:
            return // Success
        case 400...499:
            let errorMessage = data.flatMap { String(data: $0, encoding: .utf8) } ?? "Client error"
            throw AppNetworkError.serverError(statusCode: httpResponse.statusCode, message: errorMessage)
        case 500...599:
            let errorMessage = data.flatMap { String(data: $0, encoding: .utf8) } ?? "Server error"
            throw AppNetworkError.serverError(statusCode: httpResponse.statusCode, message: errorMessage)
        default:
            throw AppNetworkError.serverError(statusCode: httpResponse.statusCode, message: "Unknown error")
        }
    }
}

// MARK: - Convenience Extensions

@available(iOS 18.0, macOS 15.0, watchOS 11.0, tvOS 18.0, *)
extension HealthAI2030Networking {
    
    /// Shared instance for production use
    public static let shared = HealthAI2030Networking(configuration: .production)
    
    /// Development instance for testing
    public static let development = HealthAI2030Networking(configuration: .development)
    
    /// Create custom networking instance
    public static func custom(baseURL: String, enablePinning: Bool = true) -> HealthAI2030Networking? {
        guard let url = URL(string: baseURL) else { return nil }
        
        let config = NetworkConfiguration(
            baseURL: url,
            enableCertificatePinning: enablePinning,
            securityPolicy: enablePinning ? .production : .development
        )
        
        return HealthAI2030Networking(configuration: config)
    }
} 
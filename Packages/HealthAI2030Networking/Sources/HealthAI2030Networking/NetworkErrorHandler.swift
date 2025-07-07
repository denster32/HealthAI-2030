import Foundation
import os.log

public enum AppNetworkError: Error {
    // Specific network-related error types
    case networkOffline
    case timeout
    case serverError(statusCode: Int, message: String?)
    case invalidResponse
    case decodingError
    case unknownError
    
    // Provide user-friendly descriptions
    public var localizedDescription: String {
        switch self {
        case .networkOffline:
            return "No internet connection. Please check your network settings."
        case .timeout:
            return "The request timed out. Please try again later."
        case .serverError(let statusCode, let message):
            return "Server error \(statusCode): \(message ?? "Unknown server error")"
        case .invalidResponse:
            return "Received an invalid response from the server."
        case .decodingError:
            return "Unable to process the server's response."
        case .unknownError:
            return "An unexpected network error occurred."
        }
    }
}

public struct NetworkErrorHandler {
    private let logger = Logger(subsystem: "com.healthai.networking", category: "ErrorHandling")
    
    public static let shared = NetworkErrorHandler()
    
    private init() {}
    
    /// Analyze and categorize network errors
    public func categorizeError(_ error: Error) -> AppNetworkError {
        // Check for specific error types
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet, .networkConnectionLost:
                return .networkOffline
            case .timedOut, .cannotConnectToHost:
                return .timeout
            default:
                logger.error("URLError: \(urlError.localizedDescription)")
                return .unknownError
            }
        }
        
        // If it's an HTTP response error
        if let httpResponse = error as? HTTPURLResponse {
            return .serverError(
                statusCode: httpResponse.statusCode, 
                message: HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode)
            )
        }
        
        // Default fallback
        logger.error("Unhandled error: \(error.localizedDescription)")
        return .unknownError
    }
    
    /// Exponential backoff retry strategy
    public func exponentialBackoffRetry<T>(
        operation: @escaping () async throws -> T,
        maxRetries: Int = 3,
        initialDelay: TimeInterval = 1.0
    ) async throws -> T {
        var currentRetry = 0
        var currentDelay = initialDelay
        
        while true {
            do {
                return try await operation()
            } catch {
                guard currentRetry < maxRetries else {
                    throw error
                }
                
                let networkError = categorizeError(error)
                logger.warning("Retry attempt \(currentRetry + 1): \(networkError.localizedDescription)")
                
                // Only retry for specific error types
                switch networkError {
                case .networkOffline, .timeout, .serverError:
                    try await Task.sleep(for: .seconds(currentDelay))
                    currentRetry += 1
                    currentDelay *= 2 // Exponential backoff
                default:
                    throw error
                }
            }
        }
    }
    
    /// Circuit breaker pattern implementation
    public class CircuitBreaker {
        private var failureCount = 0
        private var lastFailureTime: Date?
        private let maxFailures: Int
        private let resetTimeout: TimeInterval
        
        public init(maxFailures: Int = 3, resetTimeout: TimeInterval = 30) {
            self.maxFailures = maxFailures
            self.resetTimeout = resetTimeout
        }
        
        public func canMakeRequest() -> Bool {
            // Reset circuit if enough time has passed
            if let lastFailure = lastFailureTime,
               Date().timeIntervalSince(lastFailure) > resetTimeout {
                failureCount = 0
                lastFailureTime = nil
            }
            
            return failureCount < maxFailures
        }
        
        public func recordFailure() {
            failureCount += 1
            lastFailureTime = Date()
        }
        
        public func recordSuccess() {
            failureCount = 0
            lastFailureTime = nil
        }
    }
}

// Convenience extension for URLSession
extension URLSession {
    func data(from url: URL, with circuitBreaker: NetworkErrorHandler.CircuitBreaker? = nil) async throws -> (Data, URLResponse) {
        guard circuitBreaker?.canMakeRequest() ?? true else {
            throw AppNetworkError.serverError(statusCode: 503, message: "Service temporarily unavailable")
        }
        
        do {
            let (data, response) = try await data(from: url)
            circuitBreaker?.recordSuccess()
            return (data, response)
        } catch {
            circuitBreaker?.recordFailure()
            throw error
        }
    }
} 
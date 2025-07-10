import Foundation
import os

/// Analytics Error Handling - Comprehensive error handling and recovery
/// Agent 6 Deliverable: Day 1-3 Core Analytics Framework
public class AnalyticsErrorHandling {
    
    // MARK: - Properties
    
    private let logger = Logger(subsystem: "HealthAI2030", category: "AnalyticsErrorHandling")
    private var errorHistory: [AnalyticsErrorRecord] = []
    private let maxErrorHistorySize = 1000
    
    // Error recovery strategies
    private let retryStrategies: [AnalyticsErrorType: RetryStrategy] = [
        .networkTimeout: .exponentialBackoff(maxAttempts: 3, baseDelay: 1.0),
        .temporaryUnavailable: .exponentialBackoff(maxAttempts: 5, baseDelay: 0.5),
        .rateLimitExceeded: .fixedDelay(maxAttempts: 3, delay: 60.0),
        .insufficientResources: .exponentialBackoff(maxAttempts: 2, baseDelay: 5.0)
    ]
    
    // Error notification handlers
    private var errorNotificationHandlers: [(AnalyticsErrorRecord) -> Void] = []
    
    // MARK: - Error Handling Methods
    
    /// Handle an error with appropriate recovery strategy
    public func handleError(_ error: Error, context: AnalyticsErrorContext? = nil) {
        let errorRecord = createErrorRecord(error, context: context)
        recordError(errorRecord)
        
        logger.error("Analytics error occurred: \(error.localizedDescription)")
        
        // Notify error handlers
        notifyErrorHandlers(errorRecord)
        
        // Attempt recovery if strategy exists
        if let recoveryStrategy = getRecoveryStrategy(for: errorRecord) {
            attemptRecovery(for: errorRecord, using: recoveryStrategy)
        }
    }
    
    /// Handle errors with custom recovery action
    public func handleError<T>(_ error: Error, 
                              context: AnalyticsErrorContext? = nil,
                              recoveryAction: @escaping () async throws -> T) async throws -> T {
        let errorRecord = createErrorRecord(error, context: context)
        recordError(errorRecord)
        
        logger.error("Analytics error with recovery action: \(error.localizedDescription)")
        
        // Notify error handlers
        notifyErrorHandlers(errorRecord)
        
        // Attempt recovery using provided action
        do {
            let result = try await recoveryAction()
            logger.info("Error recovery successful")
            return result
        } catch {
            logger.error("Error recovery failed: \(error.localizedDescription)")
            throw error
        }
    }
    
    /// Execute operation with automatic error handling and retry
    public func executeWithRetry<T>(_ operation: @escaping () async throws -> T,
                                   errorType: AnalyticsErrorType,
                                   context: AnalyticsErrorContext? = nil) async throws -> T {
        
        guard let retryStrategy = retryStrategies[errorType] else {
            return try await operation()
        }
        
        var lastError: Error?
        
        for attempt in 1...retryStrategy.maxAttempts {
            do {
                let result = try await operation()
                if attempt > 1 {
                    logger.info("Operation succeeded after \(attempt) attempts")
                }
                return result
            } catch {
                lastError = error
                let errorRecord = createErrorRecord(error, context: context, attempt: attempt)
                recordError(errorRecord)
                
                logger.warning("Operation failed on attempt \(attempt): \(error.localizedDescription)")
                
                if attempt < retryStrategy.maxAttempts {
                    let delay = retryStrategy.calculateDelay(for: attempt)
                    logger.info("Retrying in \(delay) seconds...")
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }
            }
        }
        
        // All retry attempts failed
        if let error = lastError {
            logger.error("Operation failed after \(retryStrategy.maxAttempts) attempts")
            throw error
        } else {
            throw AnalyticsError.operationFailed
        }
    }
    
    /// Register an error notification handler
    public func addErrorNotificationHandler(_ handler: @escaping (AnalyticsErrorRecord) -> Void) {
        errorNotificationHandlers.append(handler)
    }
    
    /// Get error statistics for monitoring
    public func getErrorStatistics(timeWindow: TimeInterval = 3600) -> AnalyticsErrorStatistics {
        let cutoffTime = Date().addingTimeInterval(-timeWindow)
        let recentErrors = errorHistory.filter { $0.timestamp >= cutoffTime }
        
        let errorsByType = Dictionary(grouping: recentErrors) { $0.type }
        let errorCounts = errorsByType.mapValues { $0.count }
        
        let totalErrors = recentErrors.count
        let uniqueErrors = Set(recentErrors.map { $0.type }).count
        
        let criticalErrors = recentErrors.filter { $0.severity == .critical }.count
        let errorRate = Double(totalErrors) / (timeWindow / 60.0) // errors per minute
        
        return AnalyticsErrorStatistics(
            totalErrors: totalErrors,
            uniqueErrorTypes: uniqueErrors,
            criticalErrors: criticalErrors,
            errorRate: errorRate,
            errorsByType: errorCounts,
            timeWindow: timeWindow
        )
    }
    
    /// Get recent error history
    public func getRecentErrors(limit: Int = 50) -> [AnalyticsErrorRecord] {
        return Array(errorHistory.suffix(limit))
    }
    
    /// Clear error history
    public func clearErrorHistory() {
        errorHistory.removeAll()
        logger.info("Error history cleared")
    }
    
    // MARK: - Private Methods
    
    private func createErrorRecord(_ error: Error, 
                                 context: AnalyticsErrorContext? = nil,
                                 attempt: Int = 1) -> AnalyticsErrorRecord {
        let analyticsError = mapToAnalyticsError(error)
        
        return AnalyticsErrorRecord(
            id: UUID(),
            type: analyticsError.type,
            severity: analyticsError.severity,
            message: error.localizedDescription,
            underlyingError: error,
            context: context,
            attempt: attempt,
            timestamp: Date(),
            stackTrace: getStackTrace()
        )
    }
    
    private func recordError(_ errorRecord: AnalyticsErrorRecord) {
        errorHistory.append(errorRecord)
        
        // Maintain history size limit
        if errorHistory.count > maxErrorHistorySize {
            errorHistory.removeFirst(errorHistory.count - maxErrorHistorySize)
        }
        
        // Log error details
        logErrorDetails(errorRecord)
    }
    
    private func notifyErrorHandlers(_ errorRecord: AnalyticsErrorRecord) {
        for handler in errorNotificationHandlers {
            handler(errorRecord)
        }
    }
    
    private func getRecoveryStrategy(for errorRecord: AnalyticsErrorRecord) -> RetryStrategy? {
        return retryStrategies[errorRecord.type]
    }
    
    private func attemptRecovery(for errorRecord: AnalyticsErrorRecord, using strategy: RetryStrategy) {
        // This would be called for automatic recovery attempts
        // Implementation depends on specific error types and recovery mechanisms
        logger.info("Attempting automatic recovery for error type: \(errorRecord.type)")
    }
    
    private func mapToAnalyticsError(_ error: Error) -> (type: AnalyticsErrorType, severity: AnalyticsErrorSeverity) {
        switch error {
        case is DecodingError:
            return (.dataCorruption, .medium)
        case let nsError as NSError:
            switch nsError.domain {
            case NSURLErrorDomain:
                switch nsError.code {
                case NSURLErrorTimedOut:
                    return (.networkTimeout, .medium)
                case NSURLErrorNotConnectedToInternet:
                    return (.networkUnavailable, .high)
                default:
                    return (.networkError, .medium)
                }
            default:
                return (.unknown, .low)
            }
        case AnalyticsError.invalidData:
            return (.invalidInput, .medium)
        case AnalyticsError.processingFailed:
            return (.processingError, .high)
        case AnalyticsError.insufficientData:
            return (.insufficientData, .low)
        case AnalyticsError.configurationError:
            return (.configurationError, .high)
        default:
            return (.unknown, .low)
        }
    }
    
    private func logErrorDetails(_ errorRecord: AnalyticsErrorRecord) {
        let logMessage = """
        Analytics Error Details:
        - ID: \(errorRecord.id)
        - Type: \(errorRecord.type)
        - Severity: \(errorRecord.severity)
        - Message: \(errorRecord.message)
        - Attempt: \(errorRecord.attempt)
        - Context: \(errorRecord.context?.description ?? "None")
        - Timestamp: \(errorRecord.timestamp)
        """
        
        switch errorRecord.severity {
        case .low:
            logger.info("\(logMessage)")
        case .medium:
            logger.notice("\(logMessage)")
        case .high:
            logger.error("\(logMessage)")
        case .critical:
            logger.critical("\(logMessage)")
        }
    }
    
    private func getStackTrace() -> String {
        return Thread.callStackSymbols.joined(separator: "\n")
    }
}

// MARK: - Supporting Types

public struct AnalyticsErrorRecord: Identifiable {
    public let id: UUID
    public let type: AnalyticsErrorType
    public let severity: AnalyticsErrorSeverity
    public let message: String
    public let underlyingError: Error
    public let context: AnalyticsErrorContext?
    public let attempt: Int
    public let timestamp: Date
    public let stackTrace: String
}

public enum AnalyticsErrorType: String, CaseIterable {
    case invalidInput = "invalidInput"
    case dataCorruption = "dataCorruption"
    case processingError = "processingError"
    case networkError = "networkError"
    case networkTimeout = "networkTimeout"
    case networkUnavailable = "networkUnavailable"
    case temporaryUnavailable = "temporaryUnavailable"
    case rateLimitExceeded = "rateLimitExceeded"
    case insufficientResources = "insufficientResources"
    case insufficientData = "insufficientData"
    case configurationError = "configurationError"
    case authenticationError = "authenticationError"
    case authorizationError = "authorizationError"
    case unknown = "unknown"
}

public enum AnalyticsErrorSeverity: String, CaseIterable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case critical = "critical"
}

public struct AnalyticsErrorContext {
    public let operationType: String
    public let dataSource: String?
    public let userID: String?
    public let sessionID: String?
    public let additionalInfo: [String: String]
    
    public init(operationType: String,
                dataSource: String? = nil,
                userID: String? = nil,
                sessionID: String? = nil,
                additionalInfo: [String: String] = [:]) {
        self.operationType = operationType
        self.dataSource = dataSource
        self.userID = userID
        self.sessionID = sessionID
        self.additionalInfo = additionalInfo
    }
    
    public var description: String {
        var parts: [String] = ["Operation: \(operationType)"]
        
        if let dataSource = dataSource {
            parts.append("DataSource: \(dataSource)")
        }
        
        if let userID = userID {
            parts.append("UserID: \(userID)")
        }
        
        if let sessionID = sessionID {
            parts.append("SessionID: \(sessionID)")
        }
        
        if !additionalInfo.isEmpty {
            let info = additionalInfo.map { "\($0.key): \($0.value)" }.joined(separator: ", ")
            parts.append("Additional: \(info)")
        }
        
        return parts.joined(separator: " | ")
    }
}

public enum RetryStrategy {
    case none
    case fixedDelay(maxAttempts: Int, delay: TimeInterval)
    case exponentialBackoff(maxAttempts: Int, baseDelay: TimeInterval)
    case linearBackoff(maxAttempts: Int, baseDelay: TimeInterval)
    
    public var maxAttempts: Int {
        switch self {
        case .none:
            return 1
        case .fixedDelay(let maxAttempts, _),
             .exponentialBackoff(let maxAttempts, _),
             .linearBackoff(let maxAttempts, _):
            return maxAttempts
        }
    }
    
    public func calculateDelay(for attempt: Int) -> TimeInterval {
        switch self {
        case .none:
            return 0
        case .fixedDelay(_, let delay):
            return delay
        case .exponentialBackoff(_, let baseDelay):
            return baseDelay * pow(2.0, Double(attempt - 1))
        case .linearBackoff(_, let baseDelay):
            return baseDelay * Double(attempt)
        }
    }
}

public struct AnalyticsErrorStatistics {
    public let totalErrors: Int
    public let uniqueErrorTypes: Int
    public let criticalErrors: Int
    public let errorRate: Double // errors per minute
    public let errorsByType: [AnalyticsErrorType: Int]
    public let timeWindow: TimeInterval
    
    public var isHealthy: Bool {
        return criticalErrors == 0 && errorRate < 1.0 // Less than 1 error per minute
    }
}

// MARK: - Error Handling Extensions

extension AnalyticsErrorHandling {
    
    /// Convenience method for handling common analytics operations
    public func safeAnalyticsOperation<T>(_ operation: @escaping () async throws -> T,
                                        fallback: T) async -> T {
        do {
            return try await operation()
        } catch {
            handleError(error, context: AnalyticsErrorContext(operationType: "SafeAnalyticsOperation"))
            return fallback
        }
    }
    
    /// Handle errors with user-friendly messages
    public func handleUserFacingError(_ error: Error) -> String {
        let errorRecord = createErrorRecord(error)
        recordError(errorRecord)
        
        switch errorRecord.type {
        case .networkUnavailable:
            return "Unable to connect to analytics service. Please check your internet connection."
        case .networkTimeout:
            return "Analytics request timed out. Please try again."
        case .insufficientData:
            return "Not enough data available for analysis. Please collect more data and try again."
        case .processingError:
            return "An error occurred while processing your data. Please try again later."
        case .configurationError:
            return "Analytics configuration error. Please contact support."
        default:
            return "An unexpected error occurred. Please try again or contact support if the problem persists."
        }
    }
}

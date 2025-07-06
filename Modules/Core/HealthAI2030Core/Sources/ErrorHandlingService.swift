import Foundation
import os

/// Protocol for all app errors to conform to
public protocol AppError: Error, LocalizedError, CustomNSError {
    var errorDescription: String? { get }
    var recoverySuggestion: String? { get }
    var errorCode: Int { get }
    var domain: String { get }
}

/// Centralized error handling and reporting service
class ErrorHandlingService {
    static let shared = ErrorHandlingService()
    private let logger = Logger(subsystem: "com.HealthAI2030", category: "ErrorHandling")
    private init() {}

    /// Handle and log an error
    func handle(_ error: AppError, userMessage: String? = nil) {
        logger.error("[\(error.domain)] Code \(error.errorCode): \(error.errorDescription ?? "Unknown error")")
        if let suggestion = error.recoverySuggestion {
            logger.info("Recovery suggestion: \(suggestion)")
        }
        // Optionally, show user-facing alert or report to analytics
        if let message = userMessage {
            // Show alert to user (UI integration point)
            print("User message: \(message)")
        }
    }
}

// Example error type
enum HealthDataError: Int, AppError {
    case healthKitProcessingError = 1001
    case dataValidationError = 1002
    case cloudSyncError = 1003
    case unknown = 9999

    var errorDescription: String? {
        switch self {
        case .healthKitProcessingError: return "Failed to process HealthKit data."
        case .dataValidationError: return "Health data validation failed."
        case .cloudSyncError: return "Cloud sync failed."
        case .unknown: return "An unknown error occurred."
        }
    }
    var recoverySuggestion: String? {
        switch self {
        case .healthKitProcessingError: return "Check HealthKit permissions and data integrity."
        case .dataValidationError: return "Ensure all health data fields are valid."
        case .cloudSyncError: return "Check your network connection and iCloud status."
        case .unknown: return nil
        }
    }
    var errorCode: Int { rawValue }
    var domain: String { "com.HealthAI2030.HealthData" }
    static var errorDomain: String { "com.HealthAI2030.HealthData" }
} 
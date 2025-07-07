import Foundation

public enum AppError: Error, LocalizedError {
    case networkOffline
    case timeout
    case serverError(statusCode: Int, message: String)
    case unknownError(String)

    public var errorDescription: String? {
        switch self {
        case .networkOffline:
            return "No internet connection."
        case .timeout:
            return "The request timed out."
        case .serverError(let statusCode, let message):
            return "Server error (\(statusCode)): \(message)"
        case .unknownError(let message):
            return message
        }
    }
} 
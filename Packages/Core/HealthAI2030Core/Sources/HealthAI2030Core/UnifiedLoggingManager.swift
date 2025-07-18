import Foundation
import os.log
import Combine

/// Centralized logging manager for HealthAI 2030
public class UnifiedLoggingManager {
    /// Singleton instance
    public static let shared = UnifiedLoggingManager()
    
    /// Subsystem for all logs
    private let subsystem = "com.healthai2030"
    
    /// Predefined log categories
    public enum LogCategory: String {
        case general = "General"
        case healthKit = "HealthKit"
        case aiEngine = "AIEngine"
        case networking = "Networking"
        case backgroundTasks = "BackgroundTasks"
        case permissions = "Permissions"
        case dataManager = "DataManager"
        case performance = "Performance"
        case federatedLearning = "FederatedLearning"
        case quantumComputing = "QuantumComputing"
        case errorHandling = "ErrorHandling"
    }
    
    /// Log levels matching OSLogType
    public enum LogLevel {
        case debug
        case info
        case notice
        case warning
        case error
        case fault
        
        /// Convert to OSLogType
        var osLogType: OSLogType {
            switch self {
            case .debug: return .debug
            case .info: return .info
            case .notice: return .default
            case .warning: return .info
            case .error: return .error
            case .fault: return .fault
            }
        }
    }
    
    /// Private initializer to enforce singleton
    private init() {}
    
    /// Log a message with specified category and log level
    public func log(
        _ message: String,
        category: LogCategory = .general,
        level: LogLevel = .info,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        let logger = Logger(subsystem: subsystem, category: category.rawValue)
        
        // Construct log message with additional context
        let contextMessage = "[\(URL(fileURLWithPath: file).lastPathComponent):\(line)] \(function) - \(message)"
        
        switch level {
        case .debug:
            os_log("%{public}@", log: logger, type: .debug, contextMessage)
        case .info:
            os_log("%{public}@", log: logger, type: .info, contextMessage)
        case .notice:
            os_log("%{public}@", log: logger, type: .default, contextMessage)
        case .warning:
            os_log("%{public}@", log: logger, type: .info, contextMessage)
        case .error:
            os_log("%{public}@", log: logger, type: .error, contextMessage)
        case .fault:
            os_log("%{public}@", log: logger, type: .fault, contextMessage)
        }
    }
    
    /// Convenience method for debug logging
    public func debug(
        _ message: String,
        category: LogCategory = .general,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(message, category: category, level: .debug, file: file, function: function, line: line)
    }
    
    /// Convenience method for info logging
    public func info(
        _ message: String,
        category: LogCategory = .general,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(message, category: category, level: .info, file: file, function: function, line: line)
    }
    
    /// Convenience method for warning logging
    public func warning(
        _ message: String,
        category: LogCategory = .general,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(message, category: category, level: .warning, file: file, function: function, line: line)
    }
    
    /// Convenience method for error logging
    public func error(
        _ message: String,
        category: LogCategory = .general,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(message, category: category, level: .error, file: file, function: function, line: line)
    }
    
    /// Convenience method for fault logging
    public func fault(
        _ message: String,
        category: LogCategory = .general,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(message, category: category, level: .fault, file: file, function: function, line: line)
    }
}

// Extension to make logging more convenient
public extension UnifiedLoggingManager {
    /// Log an error with additional context
    func logError(
        _ error: Error,
        category: LogCategory = .errorHandling,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        let errorDescription = """
        Error: \(error.localizedDescription)
        Type: \(type(of: error))
        """
        
        log(errorDescription, category: category, level: .error, file: file, function: function, line: line)
    }
} 
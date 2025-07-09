import Foundation
import Combine
import os.log
import Crashlytics

/// Comprehensive Error Handling & Logging Manager for HealthAI 2030
/// Provides unified error handling, structured logging, crash reporting, and performance monitoring
public class ErrorHandlingLoggingManager: ObservableObject {
    public static let shared = ErrorHandlingLoggingManager()
    
    // MARK: - Published Properties
    
    @Published public var errorCount: Int = 0
    @Published public var warningCount: Int = 0
    @Published public var infoCount: Int = 0
    @Published public var crashCount: Int = 0
    @Published public var isMonitoringEnabled: Bool = true
    @Published public var logLevel: LogLevel = .info
    @Published public var recentErrors: [LogEntry] = []
    @Published public var performanceMetrics: LoggingPerformanceMetrics = LoggingPerformanceMetrics()
    
    // MARK: - Private Properties
    
    private let logger = Logger(subsystem: "com.healthai.errorhandling", category: "ErrorHandling")
    private let logQueue = DispatchQueue(label: "com.healthai.logging", qos: .utility)
    private let errorQueue = DispatchQueue(label: "com.healthai.errors", qos: .userInitiated)
    
    private var cancellables = Set<AnyCancellable>()
    private var errorHandlers: [ErrorHandler] = []
    private var logHandlers: [LogHandler] = []
    private var crashHandlers: [CrashHandler] = []
    private var performanceHandlers: [PerformanceHandler] = []
    
    private var logBuffer: [LogEntry] = []
    private var errorBuffer: [ErrorEntry] = []
    private var crashBuffer: [CrashEntry] = []
    
    private let maxBufferSize = 1000
    private let flushInterval: TimeInterval = 30.0
    private var flushTimer: Timer?
    
    // MARK: - Configuration
    
    public struct LoggingConfiguration {
        public let logLevel: LogLevel
        public let maxBufferSize: Int
        public let flushInterval: TimeInterval
        public let enableCrashReporting: Bool
        public let enablePerformanceMonitoring: Bool
        public let enableRemoteLogging: Bool
        public let enableLocalLogging: Bool
        public let logRetentionDays: Int
        public let errorReportingEndpoint: URL?
        public let crashReportingEndpoint: URL?
        
        public init(
            logLevel: LogLevel = .info,
            maxBufferSize: Int = 1000,
            flushInterval: TimeInterval = 30.0,
            enableCrashReporting: Bool = true,
            enablePerformanceMonitoring: Bool = true,
            enableRemoteLogging: Bool = true,
            enableLocalLogging: Bool = true,
            logRetentionDays: Int = 30,
            errorReportingEndpoint: URL? = nil,
            crashReportingEndpoint: URL? = nil
        ) {
            self.logLevel = logLevel
            self.maxBufferSize = maxBufferSize
            self.flushInterval = flushInterval
            self.enableCrashReporting = enableCrashReporting
            self.enablePerformanceMonitoring = enablePerformanceMonitoring
            self.enableRemoteLogging = enableRemoteLogging
            self.enableLocalLogging = enableLocalLogging
            self.logRetentionDays = logRetentionDays
            self.errorReportingEndpoint = errorReportingEndpoint
            self.crashReportingEndpoint = crashReportingEndpoint
        }
    }
    
    public var configuration: LoggingConfiguration {
        didSet {
            updateConfiguration()
        }
    }
    
    // MARK: - Log Levels
    
    public enum LogLevel: String, CaseIterable, Codable, Comparable {
        case debug = "Debug"
        case info = "Info"
        case warning = "Warning"
        case error = "Error"
        case critical = "Critical"
        case fatal = "Fatal"
        
        public var priority: Int {
            switch self {
            case .debug: return 0
            case .info: return 1
            case .warning: return 2
            case .error: return 3
            case .critical: return 4
            case .fatal: return 5
            }
        }
        
        public static func < (lhs: LogLevel, rhs: LogLevel) -> Bool {
            return lhs.priority < rhs.priority
        }
        
        public var icon: String {
            switch self {
            case .debug: return "🔍"
            case .info: return "ℹ️"
            case .warning: return "⚠️"
            case .error: return "❌"
            case .critical: return "🚨"
            case .fatal: return "💥"
            }
        }
        
        public var color: String {
            switch self {
            case .debug: return "#6C757D"
            case .info: return "#17A2B8"
            case .warning: return "#FFC107"
            case .error: return "#DC3545"
            case .critical: return "#FD7E14"
            case .fatal: return "#6F42C1"
            }
        }
    }
    
    // MARK: - Log Entry
    
    public struct LogEntry: Identifiable, Codable {
        public let id: String
        public let timestamp: Date
        public let level: LogLevel
        public let category: String
        public let message: String
        public let details: [String: String]
        public let metadata: [String: String]
        public let sessionId: String?
        public let userId: String?
        public let deviceInfo: DeviceInfo
        public let stackTrace: String?
        public let performanceData: PerformanceData?
        
        public init(
            id: String = UUID().uuidString,
            timestamp: Date = Date(),
            level: LogLevel,
            category: String,
            message: String,
            details: [String: String] = [:],
            metadata: [String: String] = [:],
            sessionId: String? = nil,
            userId: String? = nil,
            deviceInfo: DeviceInfo = DeviceInfo.current,
            stackTrace: String? = nil,
            performanceData: PerformanceData? = nil
        ) {
            self.id = id
            self.timestamp = timestamp
            self.level = level
            self.category = category
            self.message = message
            self.details = details
            self.metadata = metadata
            self.sessionId = sessionId
            self.userId = userId
            self.deviceInfo = deviceInfo
            self.stackTrace = stackTrace
            self.performanceData = performanceData
        }
    }
    
    // MARK: - Error Entry
    
    public struct ErrorEntry: Identifiable, Codable {
        public let id: String
        public let timestamp: Date
        public let error: AppError
        public let context: ErrorContext
        public let severity: ErrorSeverity
        public let isHandled: Bool
        public let recoveryAction: RecoveryAction?
        public let userImpact: UserImpact
        public let sessionId: String?
        public let userId: String?
        public let deviceInfo: DeviceInfo
        public let stackTrace: String
        public let breadcrumbs: [Breadcrumb]
        
        public init(
            id: String = UUID().uuidString,
            timestamp: Date = Date(),
            error: AppError,
            context: ErrorContext,
            severity: ErrorSeverity,
            isHandled: Bool = false,
            recoveryAction: RecoveryAction? = nil,
            userImpact: UserImpact = .none,
            sessionId: String? = nil,
            userId: String? = nil,
            deviceInfo: DeviceInfo = DeviceInfo.current,
            stackTrace: String = Thread.callStackSymbols.joined(separator: "\n"),
            breadcrumbs: [Breadcrumb] = []
        ) {
            self.id = id
            self.timestamp = timestamp
            self.error = error
            self.context = context
            self.severity = severity
            self.isHandled = isHandled
            self.recoveryAction = recoveryAction
            self.userImpact = userImpact
            self.sessionId = sessionId
            self.userId = userId
            self.deviceInfo = deviceInfo
            self.stackTrace = stackTrace
            self.breadcrumbs = breadcrumbs
        }
    }
    
    // MARK: - App Error
    
    public enum AppError: Error, LocalizedError, Codable {
        case networkError(NetworkError)
        case dataError(DataError)
        case authenticationError(AuthenticationError)
        case authorizationError(AuthorizationError)
        case validationError(ValidationError)
        case businessLogicError(BusinessLogicError)
        case systemError(SystemError)
        case unknownError(String)
        
        public var errorDescription: String? {
            switch self {
            case .networkError(let error):
                return "Network Error: \(error.localizedDescription)"
            case .dataError(let error):
                return "Data Error: \(error.localizedDescription)"
            case .authenticationError(let error):
                return "Authentication Error: \(error.localizedDescription)"
            case .authorizationError(let error):
                return "Authorization Error: \(error.localizedDescription)"
            case .validationError(let error):
                return "Validation Error: \(error.localizedDescription)"
            case .businessLogicError(let error):
                return "Business Logic Error: \(error.localizedDescription)"
            case .systemError(let error):
                return "System Error: \(error.localizedDescription)"
            case .unknownError(let message):
                return "Unknown Error: \(message)"
            }
        }
        
        public var isRecoverable: Bool {
            switch self {
            case .networkError(let error):
                return error.isRetryable
            case .dataError(let error):
                return error.isRecoverable
            case .authenticationError(let error):
                return error.isRecoverable
            case .authorizationError:
                return false
            case .validationError(let error):
                return error.isRecoverable
            case .businessLogicError(let error):
                return error.isRecoverable
            case .systemError(let error):
                return error.isRecoverable
            case .unknownError:
                return false
            }
        }
    }
    
    // MARK: - Specific Error Types
    
    public enum NetworkError: Error, LocalizedError, Codable {
        case noConnection
        case timeout
        case serverError(Int)
        case clientError(Int)
        case invalidResponse
        case rateLimited
        
        public var isRetryable: Bool {
            switch self {
            case .noConnection, .timeout, .serverError:
                return true
            case .clientError, .invalidResponse, .rateLimited:
                return false
            }
        }
    }
    
    public enum DataError: Error, LocalizedError, Codable {
        case corruption
        case missing
        case invalid
        case accessDenied
        case quotaExceeded
        
        public var isRecoverable: Bool {
            switch self {
            case .corruption, .missing, .invalid:
                return true
            case .accessDenied, .quotaExceeded:
                return false
            }
        }
    }
    
    public enum AuthenticationError: Error, LocalizedError, Codable {
        case invalidCredentials
        case tokenExpired
        case accountLocked
        case twoFactorRequired
        
        public var isRecoverable: Bool {
            switch self {
            case .invalidCredentials, .tokenExpired:
                return true
            case .accountLocked, .twoFactorRequired:
                return false
            }
        }
    }
    
    public enum AuthorizationError: Error, LocalizedError, Codable {
        case insufficientPermissions
        case resourceNotFound
        case accessDenied
    }
    
    public enum ValidationError: Error, LocalizedError, Codable {
        case invalidInput(String)
        case missingRequired(String)
        case formatError(String)
        case constraintViolation(String)
        
        public var isRecoverable: Bool {
            return true // Validation errors are usually recoverable
        }
    }
    
    public enum BusinessLogicError: Error, LocalizedError, Codable {
        case invalidState
        case operationNotAllowed
        case resourceConflict
        case businessRuleViolation(String)
        
        public var isRecoverable: Bool {
            switch self {
            case .invalidState, .operationNotAllowed:
                return false
            case .resourceConflict, .businessRuleViolation:
                return true
            }
        }
    }
    
    public enum SystemError: Error, LocalizedError, Codable {
        case outOfMemory
        case diskFull
        case databaseError
        case configurationError
        
        public var isRecoverable: Bool {
            switch self {
            case .outOfMemory, .diskFull:
                return false
            case .databaseError, .configurationError:
                return true
            }
        }
    }
    
    // MARK: - Error Context
    
    public struct ErrorContext: Codable {
        public let module: String
        public let function: String
        public let line: Int
        public let file: String
        public let operation: String?
        public let userAction: String?
        public let systemState: [String: String]
        
        public init(
            module: String,
            function: String,
            line: Int,
            file: String,
            operation: String? = nil,
            userAction: String? = nil,
            systemState: [String: String] = [:]
        ) {
            self.module = module
            self.function = function
            self.line = line
            self.file = file
            self.operation = operation
            self.userAction = userAction
            self.systemState = systemState
        }
    }
    
    // MARK: - Error Severity
    
    public enum ErrorSeverity: String, CaseIterable, Codable {
        case low = "Low"
        case medium = "Medium"
        case high = "High"
        case critical = "Critical"
        case fatal = "Fatal"
        
        public var priority: Int {
            switch self {
            case .low: return 1
            case .medium: return 2
            case .high: return 3
            case .critical: return 4
            case .fatal: return 5
            }
        }
    }
    
    // MARK: - Recovery Action
    
    public enum RecoveryAction: String, CaseIterable, Codable {
        case retry = "Retry"
        case refresh = "Refresh"
        case restart = "Restart"
        case reinstall = "Reinstall"
        case contactSupport = "Contact Support"
        case none = "None"
    }
    
    // MARK: - User Impact
    
    public enum UserImpact: String, CaseIterable, Codable {
        case none = "None"
        case minor = "Minor"
        case moderate = "Moderate"
        case major = "Major"
        case critical = "Critical"
    }
    
    // MARK: - Device Info
    
    public struct DeviceInfo: Codable {
        public let deviceModel: String
        public let osVersion: String
        public let appVersion: String
        public let buildNumber: String
        public let deviceId: String
        public let locale: String
        public let timeZone: String
        
        public static var current: DeviceInfo {
            return DeviceInfo(
                deviceModel: UIDevice.current.model,
                osVersion: UIDevice.current.systemVersion,
                appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown",
                buildNumber: Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown",
                deviceId: UIDevice.current.identifierForVendor?.uuidString ?? "Unknown",
                locale: Locale.current.identifier,
                timeZone: TimeZone.current.identifier
            )
        }
    }
    
    // MARK: - Performance Data
    
    public struct PerformanceData: Codable {
        public let duration: TimeInterval
        public let memoryUsage: Int64
        public let cpuUsage: Double
        public let networkLatency: TimeInterval?
        public let databaseQueryTime: TimeInterval?
        
        public init(
            duration: TimeInterval,
            memoryUsage: Int64,
            cpuUsage: Double,
            networkLatency: TimeInterval? = nil,
            databaseQueryTime: TimeInterval? = nil
        ) {
            self.duration = duration
            self.memoryUsage = memoryUsage
            self.cpuUsage = cpuUsage
            self.networkLatency = networkLatency
            self.databaseQueryTime = databaseQueryTime
        }
    }
    
    // MARK: - Breadcrumb
    
    public struct Breadcrumb: Codable {
        public let timestamp: Date
        public let message: String
        public let category: String
        public let level: LogLevel
        public let metadata: [String: String]
        
        public init(
            timestamp: Date = Date(),
            message: String,
            category: String,
            level: LogLevel = .info,
            metadata: [String: String] = [:]
        ) {
            self.timestamp = timestamp
            self.message = message
            self.category = category
            self.level = level
            self.metadata = metadata
        }
    }
    
    // MARK: - Crash Entry
    
    public struct CrashEntry: Identifiable, Codable {
        public let id: String
        public let timestamp: Date
        public let crashType: CrashType
        public let reason: String
        public let stackTrace: String
        public let deviceInfo: DeviceInfo
        public let sessionId: String?
        public let userId: String?
        public let breadcrumbs: [Breadcrumb]
        public let memoryInfo: MemoryInfo
        public let threadInfo: [ThreadInfo]
        
        public init(
            id: String = UUID().uuidString,
            timestamp: Date = Date(),
            crashType: CrashType,
            reason: String,
            stackTrace: String,
            deviceInfo: DeviceInfo = DeviceInfo.current,
            sessionId: String? = nil,
            userId: String? = nil,
            breadcrumbs: [Breadcrumb] = [],
            memoryInfo: MemoryInfo = MemoryInfo.current,
            threadInfo: [ThreadInfo] = []
        ) {
            self.id = id
            self.timestamp = timestamp
            self.crashType = crashType
            self.reason = reason
            self.stackTrace = stackTrace
            self.deviceInfo = deviceInfo
            self.sessionId = sessionId
            self.userId = userId
            self.breadcrumbs = breadcrumbs
            self.memoryInfo = memoryInfo
            self.threadInfo = threadInfo
        }
    }
    
    public enum CrashType: String, CaseIterable, Codable {
        case signal = "Signal"
        case exception = "Exception"
        case watchdog = "Watchdog"
        case memory = "Memory"
        case unknown = "Unknown"
    }
    
    public struct MemoryInfo: Codable {
        public let totalMemory: Int64
        public let availableMemory: Int64
        public let usedMemory: Int64
        public let memoryPressure: String
        
        public static var current: MemoryInfo {
            // Implementation would get actual memory info
            return MemoryInfo(
                totalMemory: 0,
                availableMemory: 0,
                usedMemory: 0,
                memoryPressure: "Normal"
            )
        }
    }
    
    public struct ThreadInfo: Codable {
        public let threadId: String
        public let name: String?
        public let stackTrace: String
        public let isMainThread: Bool
    }
    
    // MARK: - Performance Metrics
    
    public struct LoggingPerformanceMetrics: Codable {
        public var totalLogs: Int = 0
        public var totalErrors: Int = 0
        public var totalCrashes: Int = 0
        public var averageLogSize: Int = 0
        public var logProcessingTime: TimeInterval = 0
        public var errorResolutionTime: TimeInterval = 0
        public var crashRecoveryTime: TimeInterval = 0
        public var bufferFlushCount: Int = 0
        public var remoteLoggingSuccess: Int = 0
        public var remoteLoggingFailures: Int = 0
    }
    
    // MARK: - Protocol Definitions
    
    public protocol ErrorHandler {
        func handleError(_ error: ErrorEntry)
    }
    
    public protocol LogHandler {
        func handleLog(_ log: LogEntry)
    }
    
    public protocol CrashHandler {
        func handleCrash(_ crash: CrashEntry)
    }
    
    public protocol PerformanceHandler {
        func handlePerformance(_ data: PerformanceData)
    }
    
    // MARK: - Initialization
    
    private init() {
        self.configuration = LoggingConfiguration()
        
        setupDefaultHandlers()
        setupCrashReporting()
        setupPerformanceMonitoring()
        startFlushTimer()
    }
    
    // MARK: - Public Methods
    
    public func log(
        _ level: LogLevel,
        category: String,
        message: String,
        details: [String: String] = [:],
        metadata: [String: String] = [:],
        sessionId: String? = nil,
        userId: String? = nil,
        stackTrace: String? = nil,
        performanceData: PerformanceData? = nil
    ) {
        guard level >= logLevel else { return }
        
        let logEntry = LogEntry(
            level: level,
            category: category,
            message: message,
            details: details,
            metadata: metadata,
            sessionId: sessionId,
            userId: userId,
            stackTrace: stackTrace,
            performanceData: performanceData
        )
        
        logQueue.async {
            self.processLog(logEntry)
        }
    }
    
    public func logError(
        _ error: AppError,
        context: ErrorContext,
        severity: ErrorSeverity = .medium,
        isHandled: Bool = false,
        recoveryAction: RecoveryAction? = nil,
        userImpact: UserImpact = .none,
        sessionId: String? = nil,
        userId: String? = nil
    ) {
        let errorEntry = ErrorEntry(
            error: error,
            context: context,
            severity: severity,
            isHandled: isHandled,
            recoveryAction: recoveryAction,
            userImpact: userImpact,
            sessionId: sessionId,
            userId: userId
        )
        
        errorQueue.async {
            self.processError(errorEntry)
        }
    }
    
    public func logCrash(
        type: CrashType,
        reason: String,
        stackTrace: String,
        sessionId: String? = nil,
        userId: String? = nil,
        breadcrumbs: [Breadcrumb] = []
    ) {
        let crashEntry = CrashEntry(
            crashType: type,
            reason: reason,
            stackTrace: stackTrace,
            sessionId: sessionId,
            userId: userId,
            breadcrumbs: breadcrumbs
        )
        
        errorQueue.async {
            self.processCrash(crashEntry)
        }
    }
    
    public func addBreadcrumb(
        message: String,
        category: String,
        level: LogLevel = .info,
        metadata: [String: String] = [:]
    ) {
        let breadcrumb = Breadcrumb(
            message: message,
            category: category,
            level: level,
            metadata: metadata
        )
        
        // Add to breadcrumb buffer
        // Implementation would store breadcrumbs for crash reporting
    }
    
    public func addErrorHandler(_ handler: ErrorHandler) {
        errorHandlers.append(handler)
    }
    
    public func addLogHandler(_ handler: LogHandler) {
        logHandlers.append(handler)
    }
    
    public func addCrashHandler(_ handler: CrashHandler) {
        crashHandlers.append(handler)
    }
    
    public func addPerformanceHandler(_ handler: PerformanceHandler) {
        performanceHandlers.append(handler)
    }
    
    public func flushBuffers() {
        logQueue.async {
            self.flushLogBuffer()
        }
        
        errorQueue.async {
            self.flushErrorBuffer()
        }
    }
    
    public func clearBuffers() {
        logQueue.async {
            self.logBuffer.removeAll()
        }
        
        errorQueue.async {
            self.errorBuffer.removeAll()
        }
    }
    
    public func exportLogs() -> Data? {
        let allLogs = logBuffer + recentErrors.map { LogEntry(
            level: $0.level,
            category: $0.category,
            message: $0.message,
            details: $0.details,
            metadata: $0.metadata
        ) }
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        
        return try? encoder.encode(allLogs)
    }
    
    public func getErrorSummary() -> ErrorSummary {
        let totalErrors = errorBuffer.count
        let handledErrors = errorBuffer.filter { $0.isHandled }.count
        let unhandledErrors = totalErrors - handledErrors
        
        let errorsBySeverity = Dictionary(grouping: errorBuffer) { $0.severity }
        let errorsByType = Dictionary(grouping: errorBuffer) { $0.error }
        
        return ErrorSummary(
            totalErrors: totalErrors,
            handledErrors: handledErrors,
            unhandledErrors: unhandledErrors,
            errorsBySeverity: errorsBySeverity.mapValues { $0.count },
            errorsByType: errorsByType.mapValues { $0.count },
            mostCommonError: errorsByType.max { $0.value.count < $1.value.count }?.key,
            averageResolutionTime: performanceMetrics.errorResolutionTime
        )
    }
    
    public func getPerformanceSummary() -> PerformanceSummary {
        return PerformanceSummary(
            totalLogs: performanceMetrics.totalLogs,
            averageLogSize: performanceMetrics.averageLogSize,
            logProcessingTime: performanceMetrics.logProcessingTime,
            bufferFlushCount: performanceMetrics.bufferFlushCount,
            remoteLoggingSuccess: performanceMetrics.remoteLoggingSuccess,
            remoteLoggingFailures: performanceMetrics.remoteLoggingFailures
        )
    }
    
    // MARK: - Private Methods
    
    private func setupDefaultHandlers() {
        // Add default handlers
        addLogHandler(OSLogHandler())
        addErrorHandler(ErrorReportingHandler())
        addCrashHandler(CrashReportingHandler())
        addPerformanceHandler(PerformanceMonitoringHandler())
    }
    
    private func setupCrashReporting() {
        guard configuration.enableCrashReporting else { return }
        
        // Setup crash reporting
        // Implementation would integrate with Crashlytics or similar
    }
    
    private func setupPerformanceMonitoring() {
        guard configuration.enablePerformanceMonitoring else { return }
        
        // Setup performance monitoring
        // Implementation would start monitoring system resources
    }
    
    private func updateConfiguration() {
        logLevel = configuration.logLevel
        
        if configuration.enableCrashReporting {
            setupCrashReporting()
        }
        
        if configuration.enablePerformanceMonitoring {
            setupPerformanceMonitoring()
        }
    }
    
    private func startFlushTimer() {
        flushTimer = Timer.scheduledTimer(withTimeInterval: configuration.flushInterval, repeats: true) { _ in
            self.flushBuffers()
        }
    }
    
    private func processLog(_ log: LogEntry) {
        // Update counters
        DispatchQueue.main.async {
            switch log.level {
            case .error, .critical, .fatal:
                self.errorCount += 1
            case .warning:
                self.warningCount += 1
            case .info, .debug:
                self.infoCount += 1
            }
            
            // Add to recent errors if appropriate
            if log.level >= .error {
                self.recentErrors.insert(log, at: 0)
                if self.recentErrors.count > 100 {
                    self.recentErrors.removeLast()
                }
            }
        }
        
        // Add to buffer
        logBuffer.append(log)
        if logBuffer.count > configuration.maxBufferSize {
            logBuffer.removeFirst()
        }
        
        // Process with handlers
        for handler in logHandlers {
            handler.handleLog(log)
        }
        
        // Update performance metrics
        updateLogPerformanceMetrics(log)
    }
    
    private func processError(_ error: ErrorEntry) {
        // Update crash count if fatal
        if error.severity == .fatal {
            DispatchQueue.main.async {
                self.crashCount += 1
            }
        }
        
        // Add to buffer
        errorBuffer.append(error)
        if errorBuffer.count > configuration.maxBufferSize {
            errorBuffer.removeFirst()
        }
        
        // Process with handlers
        for handler in errorHandlers {
            handler.handleError(error)
        }
        
        // Update performance metrics
        updateErrorPerformanceMetrics(error)
    }
    
    private func processCrash(_ crash: CrashEntry) {
        DispatchQueue.main.async {
            self.crashCount += 1
        }
        
        // Add to buffer
        crashBuffer.append(crash)
        if crashBuffer.count > configuration.maxBufferSize {
            crashBuffer.removeFirst()
        }
        
        // Process with handlers
        for handler in crashHandlers {
            handler.handleCrash(crash)
        }
        
        // Update performance metrics
        updateCrashPerformanceMetrics(crash)
    }
    
    private func flushLogBuffer() {
        guard !logBuffer.isEmpty else { return }
        
        let logsToFlush = logBuffer
        logBuffer.removeAll()
        
        // Send to remote logging if enabled
        if configuration.enableRemoteLogging {
            sendLogsToRemote(logsToFlush)
        }
        
        // Save to local storage if enabled
        if configuration.enableLocalLogging {
            saveLogsToLocal(logsToFlush)
        }
        
        performanceMetrics.bufferFlushCount += 1
    }
    
    private func flushErrorBuffer() {
        guard !errorBuffer.isEmpty else { return }
        
        let errorsToFlush = errorBuffer
        errorBuffer.removeAll()
        
        // Send to error reporting if enabled
        if let endpoint = configuration.errorReportingEndpoint {
            sendErrorsToRemote(errorsToFlush, endpoint: endpoint)
        }
        
        // Save to local storage
        saveErrorsToLocal(errorsToFlush)
    }
    
    private func sendLogsToRemote(_ logs: [LogEntry]) {
        // Implementation for remote logging
        // This would send logs to a remote service
    }
    
    private func sendErrorsToRemote(_ errors: [ErrorEntry], endpoint: URL) {
        // Implementation for remote error reporting
        // This would send errors to a remote service
    }
    
    private func saveLogsToLocal(_ logs: [LogEntry]) {
        // Implementation for local log storage
        // This would save logs to local files or database
    }
    
    private func saveErrorsToLocal(_ errors: [ErrorEntry]) {
        // Implementation for local error storage
        // This would save errors to local files or database
    }
    
    private func updateLogPerformanceMetrics(_ log: LogEntry) {
        performanceMetrics.totalLogs += 1
        performanceMetrics.averageLogSize = (performanceMetrics.averageLogSize + log.message.count) / 2
    }
    
    private func updateErrorPerformanceMetrics(_ error: ErrorEntry) {
        performanceMetrics.totalErrors += 1
    }
    
    private func updateCrashPerformanceMetrics(_ crash: CrashEntry) {
        performanceMetrics.totalCrashes += 1
    }
}

// MARK: - Supporting Structures

public struct ErrorSummary {
    public let totalErrors: Int
    public let handledErrors: Int
    public let unhandledErrors: Int
    public let errorsBySeverity: [ErrorHandlingLoggingManager.ErrorSeverity: Int]
    public let errorsByType: [ErrorHandlingLoggingManager.AppError: Int]
    public let mostCommonError: ErrorHandlingLoggingManager.AppError?
    public let averageResolutionTime: TimeInterval
}

public struct PerformanceSummary {
    public let totalLogs: Int
    public let averageLogSize: Int
    public let logProcessingTime: TimeInterval
    public let bufferFlushCount: Int
    public let remoteLoggingSuccess: Int
    public let remoteLoggingFailures: Int
}

// MARK: - Default Handlers

private class OSLogHandler: ErrorHandlingLoggingManager.LogHandler {
    private let logger = Logger(subsystem: "com.healthai.errorhandling", category: "OSLog")
    
    func handleLog(_ log: ErrorHandlingLoggingManager.LogEntry) {
        let message = "[\(log.category)] \(log.message)"
        
        switch log.level {
        case .debug:
            logger.debug("\(message)")
        case .info:
            logger.info("\(message)")
        case .warning:
            logger.warning("\(message)")
        case .error:
            logger.error("\(message)")
        case .critical:
            logger.critical("\(message)")
        case .fatal:
            logger.fault("\(message)")
        }
    }
}

private class ErrorReportingHandler: ErrorHandlingLoggingManager.ErrorHandler {
    func handleError(_ error: ErrorHandlingLoggingManager.ErrorEntry) {
        // Implementation for error reporting
        // This would send errors to a reporting service
    }
}

private class CrashReportingHandler: ErrorHandlingLoggingManager.CrashHandler {
    func handleCrash(_ crash: ErrorHandlingLoggingManager.CrashEntry) {
        // Implementation for crash reporting
        // This would send crashes to a reporting service
    }
}

private class PerformanceMonitoringHandler: ErrorHandlingLoggingManager.PerformanceHandler {
    func handlePerformance(_ data: ErrorHandlingLoggingManager.PerformanceData) {
        // Implementation for performance monitoring
        // This would track performance metrics
    }
}
import Foundation
import OSLog
import CloudKit
import SwiftData

@available(iOS 18.0, macOS 15.0, *)
public class SyncQALogger {
    public static let shared = SyncQALogger()
    
    private let logger = Logger(subsystem: "com.HealthAI2030.QA", category: "SyncTesting")
    private let fileLogger: FileLogger
    private let metricsCollector: SyncMetricsCollector
    
    // QA Configuration
    public var isQAModeEnabled: Bool = false
    public var logLevel: LogLevel = .info
    public var shouldLogToFile: Bool = true
    public var shouldCollectMetrics: Bool = true
    
    private init() {
        self.fileLogger = FileLogger()
        self.metricsCollector = SyncMetricsCollector()
        
        #if DEBUG
        isQAModeEnabled = true
        logLevel = .debug
        #endif
    }
    
    // MARK: - Public Logging Interface
    
    public func logSyncEvent(_ event: SyncEvent) {
        guard isQAModeEnabled else { return }
        
        let logMessage = formatSyncEvent(event)
        
        // Log to system logger
        switch event.level {
        case .debug:
            logger.debug("\(logMessage)")
        case .info:
            logger.info("\(logMessage)")
        case .warning:
            logger.warning("\(logMessage)")
        case .error:
            logger.error("\(logMessage)")
        case .critical:
            logger.critical("\(logMessage)")
        }
        
        // Log to file if enabled
        if shouldLogToFile {
            fileLogger.log(logMessage, level: event.level)
        }
        
        // Collect metrics if enabled
        if shouldCollectMetrics {
            metricsCollector.recordEvent(event)
        }
    }
    
    public func logSyncStart(recordType: String, recordCount: Int, deviceSource: String) {
        let event = SyncEvent(
            type: .syncStart,
            level: .info,
            recordType: recordType,
            recordCount: recordCount,
            deviceSource: deviceSource,
            message: "Starting sync for \(recordCount) \(recordType) records from \(deviceSource)"
        )
        logSyncEvent(event)
    }
    
    public func logSyncSuccess(recordType: String, recordCount: Int, duration: TimeInterval) {
        let event = SyncEvent(
            type: .syncSuccess,
            level: .info,
            recordType: recordType,
            recordCount: recordCount,
            duration: duration,
            message: "Successfully synced \(recordCount) \(recordType) records in \(String(format: "%.2f", duration))s"
        )
        logSyncEvent(event)
    }
    
    public func logSyncError(recordType: String, error: Error, recordID: String? = nil) {
        let event = SyncEvent(
            type: .syncError,
            level: .error,
            recordType: recordType,
            recordID: recordID,
            error: error,
            message: "Sync error for \(recordType): \(error.localizedDescription)"
        )
        logSyncEvent(event)
    }
    
    public func logConflictResolution(recordType: String, recordID: String, resolutionStrategy: String, winner: String) {
        let event = SyncEvent(
            type: .conflictResolution,
            level: .warning,
            recordType: recordType,
            recordID: recordID,
            message: "Conflict resolved for \(recordType) \(recordID): \(resolutionStrategy), winner: \(winner)"
        )
        logSyncEvent(event)
    }
    
    public func logAnalyticsProcessing(analysisType: String, deviceSource: String, duration: TimeInterval, success: Bool) {
        let event = SyncEvent(
            type: .analyticsProcessing,
            level: success ? .info : .error,
            recordType: "Analytics",
            deviceSource: deviceSource,
            duration: duration,
            message: "Analytics processing (\(analysisType)) for \(deviceSource): \(success ? "SUCCESS" : "FAILED") in \(String(format: "%.2f", duration))s"
        )
        logSyncEvent(event)
    }
    
    public func logExportRequest(exportType: String, recordCount: Int, requestSource: String) {
        let event = SyncEvent(
            type: .exportRequest,
            level: .info,
            recordType: "Export",
            recordCount: recordCount,
            deviceSource: requestSource,
            message: "Export request: \(exportType) format, \(recordCount) records from \(requestSource)"
        )
        logSyncEvent(event)
    }
    
    public func logExportCompletion(exportType: String, fileSize: Int64, duration: TimeInterval) {
        let event = SyncEvent(
            type: .exportCompletion,
            level: .info,
            recordType: "Export",
            duration: duration,
            message: "Export completed: \(exportType), \(ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)) in \(String(format: "%.2f", duration))s"
        )
        logSyncEvent(event)
    }
    
    public func logNetworkEvent(isConnected: Bool, connectionType: String? = nil) {
        let event = SyncEvent(
            type: .networkChange,
            level: isConnected ? .info : .warning,
            message: "Network \(isConnected ? "connected" : "disconnected")\(connectionType.map { " (\($0))" } ?? "")"
        )
        logSyncEvent(event)
    }
    
    public func logCloudKitEvent(operation: String, recordType: String, success: Bool, error: Error? = nil) {
        let event = SyncEvent(
            type: .cloudKitOperation,
            level: success ? .info : .error,
            recordType: recordType,
            error: error,
            message: "CloudKit \(operation) for \(recordType): \(success ? "SUCCESS" : "FAILED")\(error.map { " - \($0.localizedDescription)" } ?? "")"
        )
        logSyncEvent(event)
    }
    
    // MARK: - QA Reporting
    
    public func generateQAReport() -> SyncQAReport {
        return SyncQAReport(
            generatedAt: Date(),
            metrics: metricsCollector.getMetrics(),
            recentLogs: fileLogger.getRecentLogs(limit: 1000),
            systemInfo: getSystemInfo()
        )
    }
    
    public func exportQAReport() throws -> URL {
        let report = generateQAReport()
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        
        let data = try encoder.encode(report)
        
        let documentsPath = FileManager.default.urls(for: .documentsDirectory, in: .userDomainMask)[0]
        let qaReportsPath = documentsPath.appendingPathComponent("QA_Reports")
        try FileManager.default.createDirectory(at: qaReportsPath, withIntermediateDirectories: true)
        
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let filename = "SyncQA_Report_\(timestamp).json"
        let fileURL = qaReportsPath.appendingPathComponent(filename)
        
        try data.write(to: fileURL)
        
        logger.info("QA report exported to: \(fileURL.path)")
        return fileURL
    }
    
    public func clearLogs() {
        fileLogger.clearLogs()
        metricsCollector.clearMetrics()
        logger.info("QA logs and metrics cleared")
    }
    
    // MARK: - Private Helpers
    
    private func formatSyncEvent(_ event: SyncEvent) -> String {
        var components: [String] = []
        
        components.append("[\(event.type.rawValue)]")
        
        if let recordType = event.recordType {
            components.append("[\(recordType)]")
        }
        
        if let deviceSource = event.deviceSource {
            components.append("[\(deviceSource)]")
        }
        
        if let recordID = event.recordID {
            components.append("[ID: \(recordID)]")
        }
        
        components.append(event.message)
        
        if let duration = event.duration {
            components.append("(Duration: \(String(format: "%.3f", duration))s)")
        }
        
        if let recordCount = event.recordCount {
            components.append("(Count: \(recordCount))")
        }
        
        return components.joined(separator: " ")
    }
    
    private func getSystemInfo() -> [String: Any] {
        return [
            "platform": getPlatformInfo(),
            "version": getVersionInfo(),
            "memory": getMemoryInfo(),
            "storage": getStorageInfo(),
            "network": getNetworkInfo()
        ]
    }
    
    private func getPlatformInfo() -> [String: String] {
        #if os(macOS)
        return [
            "platform": "macOS",
            "device": ProcessInfo.processInfo.hostName
        ]
        #elseif os(iOS)
        return [
            "platform": "iOS",
            "device": UIDevice.current.model
        ]
        #elseif os(watchOS)
        return [
            "platform": "watchOS",
            "device": WKInterfaceDevice.current().model
        ]
        #else
        return [
            "platform": "Unknown",
            "device": "Unknown"
        ]
        #endif
    }
    
    private func getVersionInfo() -> [String: String] {
        let processInfo = ProcessInfo.processInfo
        return [
            "osVersion": processInfo.operatingSystemVersionString,
            "appVersion": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown",
            "buildNumber": Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
        ]
    }
    
    private func getMemoryInfo() -> [String: Any] {
        let processInfo = ProcessInfo.processInfo
        return [
            "physicalMemory": processInfo.physicalMemory,
            "systemUptime": processInfo.systemUptime
        ]
    }
    
    private func getStorageInfo() -> [String: Any] {
        // Simplified storage info
        return [
            "documentsDirectory": getDirectorySize(FileManager.default.urls(for: .documentsDirectory, in: .userDomainMask)[0])
        ]
    }
    
    private func getNetworkInfo() -> [String: Any] {
        // Basic network info placeholder
        return [
            "reachable": true // Would use actual network reachability check
        ]
    }
    
    private func getDirectorySize(_ url: URL) -> Int64 {
        guard let enumerator = FileManager.default.enumerator(at: url, includingPropertiesForKeys: [.fileSizeKey]) else {
            return 0
        }
        
        var totalSize: Int64 = 0
        for case let fileURL as URL in enumerator {
            if let resourceValues = try? fileURL.resourceValues(forKeys: [.fileSizeKey]),
               let fileSize = resourceValues.fileSize {
                totalSize += Int64(fileSize)
            }
        }
        return totalSize
    }
}

// MARK: - Supporting Types

public enum LogLevel: String, CaseIterable, Codable {
    case debug = "DEBUG"
    case info = "INFO"
    case warning = "WARNING"
    case error = "ERROR"
    case critical = "CRITICAL"
}

public enum SyncEventType: String, CaseIterable, Codable {
    case syncStart = "SYNC_START"
    case syncSuccess = "SYNC_SUCCESS"
    case syncError = "SYNC_ERROR"
    case conflictResolution = "CONFLICT_RESOLUTION"
    case analyticsProcessing = "ANALYTICS_PROCESSING"
    case exportRequest = "EXPORT_REQUEST"
    case exportCompletion = "EXPORT_COMPLETION"
    case networkChange = "NETWORK_CHANGE"
    case cloudKitOperation = "CLOUDKIT_OPERATION"
}

public struct SyncEvent: Codable {
    public let id: UUID
    public let timestamp: Date
    public let type: SyncEventType
    public let level: LogLevel
    public let recordType: String?
    public let recordID: String?
    public let recordCount: Int?
    public let deviceSource: String?
    public let duration: TimeInterval?
    public let message: String
    public let errorDescription: String?
    
    public init(
        type: SyncEventType,
        level: LogLevel,
        recordType: String? = nil,
        recordID: String? = nil,
        recordCount: Int? = nil,
        deviceSource: String? = nil,
        duration: TimeInterval? = nil,
        message: String,
        error: Error? = nil
    ) {
        self.id = UUID()
        self.timestamp = Date()
        self.type = type
        self.level = level
        self.recordType = recordType
        self.recordID = recordID
        self.recordCount = recordCount
        self.deviceSource = deviceSource
        self.duration = duration
        self.message = message
        self.errorDescription = error?.localizedDescription
    }
}

// MARK: - File Logger

private class FileLogger {
    private let fileURL: URL
    private let queue = DispatchQueue(label: "com.healthai2030.filelogger", qos: .utility)
    
    init() {
        let documentsPath = FileManager.default.urls(for: .documentsDirectory, in: .userDomainMask)[0]
        let logsDirectory = documentsPath.appendingPathComponent("QA_Logs")
        
        try? FileManager.default.createDirectory(at: logsDirectory, withIntermediateDirectories: true)
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let filename = "sync_qa_\(dateFormatter.string(from: Date())).log"
        
        self.fileURL = logsDirectory.appendingPathComponent(filename)
    }
    
    func log(_ message: String, level: LogLevel) {
        queue.async { [weak self] in
            self?.writeToFile(message, level: level)
        }
    }
    
    private func writeToFile(_ message: String, level: LogLevel) {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let logEntry = "[\(timestamp)] [\(level.rawValue)] \(message)\n"
        
        if FileManager.default.fileExists(atPath: fileURL.path) {
            if let fileHandle = try? FileHandle(forWritingTo: fileURL) {
                fileHandle.seekToEndOfFile()
                fileHandle.write(logEntry.data(using: .utf8) ?? Data())
                fileHandle.closeFile()
            }
        } else {
            try? logEntry.write(to: fileURL, atomically: true, encoding: .utf8)
        }
    }
    
    func getRecentLogs(limit: Int) -> [String] {
        guard let content = try? String(contentsOf: fileURL) else { return [] }
        let lines = content.components(separatedBy: .newlines)
        return Array(lines.suffix(limit))
    }
    
    func clearLogs() {
        try? FileManager.default.removeItem(at: fileURL)
    }
}

// MARK: - Metrics Collector

private class SyncMetricsCollector {
    private var metrics: [String: Any] = [:]
    private let queue = DispatchQueue(label: "com.healthai2030.metrics", qos: .utility)
    
    func recordEvent(_ event: SyncEvent) {
        queue.async { [weak self] in
            self?.updateMetrics(with: event)
        }
    }
    
    private func updateMetrics(with event: SyncEvent) {
        // Update event counters
        let eventKey = "events_\(event.type.rawValue.lowercased())"
        metrics[eventKey] = (metrics[eventKey] as? Int ?? 0) + 1
        
        // Update error counters
        if event.level == .error {
            metrics["total_errors"] = (metrics["total_errors"] as? Int ?? 0) + 1
        }
        
        // Update duration metrics
        if let duration = event.duration {
            let durationKey = "duration_\(event.type.rawValue.lowercased())"
            var durations = metrics[durationKey] as? [TimeInterval] ?? []
            durations.append(duration)
            metrics[durationKey] = durations
        }
        
        // Update record count metrics
        if let recordCount = event.recordCount {
            let countKey = "records_\(event.recordType?.lowercased() ?? "unknown")"
            metrics[countKey] = (metrics[countKey] as? Int ?? 0) + recordCount
        }
        
        // Update device source metrics
        if let deviceSource = event.deviceSource {
            let deviceKey = "device_\(deviceSource.lowercased().replacingOccurrences(of: " ", with: "_"))"
            metrics[deviceKey] = (metrics[deviceKey] as? Int ?? 0) + 1
        }
        
        // Update last event timestamp
        metrics["last_event_timestamp"] = event.timestamp
    }
    
    func getMetrics() -> [String: Any] {
        return queue.sync { metrics }
    }
    
    func clearMetrics() {
        queue.async { [weak self] in
            self?.metrics.removeAll()
        }
    }
}

// MARK: - QA Report

public struct SyncQAReport: Codable {
    public let generatedAt: Date
    public let metrics: [String: AnyCodable]
    public let recentLogs: [String]
    public let systemInfo: [String: AnyCodable]
    
    public init(generatedAt: Date, metrics: [String: Any], recentLogs: [String], systemInfo: [String: Any]) {
        self.generatedAt = generatedAt
        self.metrics = metrics.mapValues { AnyCodable($0) }
        self.recentLogs = recentLogs
        self.systemInfo = systemInfo.mapValues { AnyCodable($0) }
    }
}

// Helper for encoding Any values
public struct AnyCodable: Codable {
    let value: Any
    
    public init(_ value: Any) {
        self.value = value
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let stringValue = try? container.decode(String.self) {
            value = stringValue
        } else if let intValue = try? container.decode(Int.self) {
            value = intValue
        } else if let doubleValue = try? container.decode(Double.self) {
            value = doubleValue
        } else if let boolValue = try? container.decode(Bool.self) {
            value = boolValue
        } else if let arrayValue = try? container.decode([AnyCodable].self) {
            value = arrayValue.map { $0.value }
        } else if let dictValue = try? container.decode([String: AnyCodable].self) {
            value = dictValue.mapValues { $0.value }
        } else {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Unsupported type"))
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch value {
        case let stringValue as String:
            try container.encode(stringValue)
        case let intValue as Int:
            try container.encode(intValue)
        case let doubleValue as Double:
            try container.encode(doubleValue)
        case let boolValue as Bool:
            try container.encode(boolValue)
        case let arrayValue as [Any]:
            try container.encode(arrayValue.map { AnyCodable($0) })
        case let dictValue as [String: Any]:
            try container.encode(dictValue.mapValues { AnyCodable($0) })
        default:
            try container.encode(String(describing: value))
        }
    }
}
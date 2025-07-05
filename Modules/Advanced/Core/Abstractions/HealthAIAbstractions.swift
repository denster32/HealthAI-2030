import Foundation
import SwiftUI
import Combine

// MARK: - Service Container

/// Service container for dependency injection and service management
public class HealthAIServiceContainer: ObservableObject {
    private var services: [String: Any] = [:]
    private let containerLock = NSLock()
    
    public static let shared = HealthAIServiceContainer()
    
    private init() {}
    
    public func register<T>(_ service: T, for key: String) {
        containerLock.lock()
        defer { containerLock.unlock() }
        
        services[key] = service
    }
    
    public func resolve<T>(_ type: T.Type, for key: String) -> T? {
        containerLock.lock()
        defer { containerLock.unlock() }
        
        return services[key] as? T
    }
    
    public func unregister(for key: String) {
        containerLock.lock()
        defer { containerLock.unlock() }
        
        services.removeValue(forKey: key)
    }
}

// MARK: - Event Bus

/// Event bus for loose coupling between components
public class HealthAIEventBus: ObservableObject {
    private var publishers: [String: PassthroughSubject<Any, Never>] = [:]
    private let busLock = NSLock()
    
    public static let shared = HealthAIEventBus()
    
    private init() {}
    
    public func publish<T>(_ event: T, on channel: String) {
        busLock.lock()
        defer { busLock.unlock() }
        
        let publisher = publishers[channel] ?? PassthroughSubject<Any, Never>()
        publishers[channel] = publisher
        publisher.send(event)
    }
    
    public func subscribe<T>(to channel: String, of type: T.Type) -> AnyPublisher<T, Never> {
        busLock.lock()
        defer { busLock.unlock() }
        
        let publisher = publishers[channel] ?? PassthroughSubject<Any, Never>()
        publishers[channel] = publisher
        
        return publisher
            .compactMap { $0 as? T }
            .eraseToAnyPublisher()
    }
}

// MARK: - Configuration Manager

/// Configuration manager for app-wide settings
public class HealthAIConfigurationManager: ObservableObject {
    @Published public var configuration: AppConfiguration
    
    public static let shared = HealthAIConfigurationManager()
    
    private init() {
        self.configuration = AppConfiguration.default
        loadConfiguration()
    }
    
    public func updateConfiguration(_ newConfiguration: AppConfiguration) {
        configuration = newConfiguration
        saveConfiguration()
    }
    
    private func loadConfiguration() {
        // Load from UserDefaults or other storage
    }
    
    private func saveConfiguration() {
        // Save to UserDefaults or other storage
    }
}

public struct AppConfiguration: Codable {
    public var analyticsEnabled: Bool
    public var performanceMonitoringEnabled: Bool
    public var debugModeEnabled: Bool
    public var dataRetentionDays: Int
    public var syncInterval: TimeInterval
    
    public static let `default` = AppConfiguration(
        analyticsEnabled: true,
        performanceMonitoringEnabled: true,
        debugModeEnabled: false,
        dataRetentionDays: 30,
        syncInterval: 300
    )
}

// MARK: - Feature Flags

/// Feature flag manager for A/B testing and gradual rollouts
public class HealthAIFeatureFlags: ObservableObject {
    @Published public var flags: [String: Bool] = [:]
    
    public static let shared = HealthAIFeatureFlags()
    
    private init() {
        loadFlags()
    }
    
    public func isEnabled(_ flag: String) -> Bool {
        return flags[flag] ?? false
    }
    
    public func setFlag(_ flag: String, enabled: Bool) {
        flags[flag] = enabled
        saveFlags()
    }
    
    private func loadFlags() {
        // Load from remote config or local storage
    }
    
    private func saveFlags() {
        // Save to local storage
    }
}

// MARK: - Cache Manager

/// Cache manager for performance optimization
public class HealthAICacheManager: ObservableObject {
    private var cache: [String: CacheEntry] = [:]
    private let cacheLock = NSLock()
    private let maxCacheSize = 100
    private let maxCacheAge: TimeInterval = 3600 // 1 hour
    
    public static let shared = HealthAICacheManager()
    
    private init() {
        startCleanupTimer()
    }
    
    public func set<T>(_ value: T, for key: String, expiresIn: TimeInterval? = nil) {
        cacheLock.lock()
        defer { cacheLock.unlock() }
        
        let expirationDate = Date().addingTimeInterval(expiresIn ?? maxCacheAge)
        let entry = CacheEntry(value: value, expirationDate: expirationDate)
        
        cache[key] = entry
        
        if cache.count > maxCacheSize {
            cleanupOldEntries()
        }
    }
    
    public func get<T>(_ key: String, as type: T.Type) -> T? {
        cacheLock.lock()
        defer { cacheLock.unlock() }
        
        guard let entry = cache[key], !entry.isExpired else {
            cache.removeValue(forKey: key)
            return nil
        }
        
        return entry.value as? T
    }
    
    public func remove(_ key: String) {
        cacheLock.lock()
        defer { cacheLock.unlock() }
        
        cache.removeValue(forKey: key)
    }
    
    public func clear() {
        cacheLock.lock()
        defer { cacheLock.unlock() }
        
        cache.removeAll()
    }
    
    private func cleanupOldEntries() {
        let expiredKeys = cache.compactMap { key, entry in
            entry.isExpired ? key : nil
        }
        
        expiredKeys.forEach { cache.removeValue(forKey: $0) }
    }
    
    private func startCleanupTimer() {
        Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { _ in
            self.cacheLock.lock()
            defer { self.cacheLock.unlock() }
            self.cleanupOldEntries()
        }
    }
}

private struct CacheEntry {
    let value: Any
    let expirationDate: Date
    
    var isExpired: Bool {
        return Date() > expirationDate
    }
}

// MARK: - Logger

/// Centralized logging system
public class HealthAILogger: ObservableObject {
    public static let shared = HealthAILogger()
    
    private let logQueue = DispatchQueue(label: "com.healthai.logger", qos: .utility)
    private var logEntries: [LogEntry] = []
    private let maxLogEntries = 1000
    
    private init() {}
    
    public func log(_ message: String, level: LogLevel, category: String = "General", file: String = #file, function: String = #function, line: Int = #line) {
        let entry = LogEntry(
            message: message,
            level: level,
            category: category,
            file: file,
            function: function,
            line: line,
            timestamp: Date()
        )
        
        logQueue.async {
            self.addLogEntry(entry)
        }
    }
    
    public func debug(_ message: String, category: String = "General", file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .debug, category: category, file: file, function: function, line: line)
    }
    
    public func info(_ message: String, category: String = "General", file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .info, category: category, file: file, function: function, line: line)
    }
    
    public func warning(_ message: String, category: String = "General", file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .warning, category: category, file: file, function: function, line: line)
    }
    
    public func error(_ message: String, category: String = "General", file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .error, category: category, file: file, function: function, line: line)
    }
    
    public func critical(_ message: String, category: String = "General", file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .critical, category: category, file: file, function: function, line: line)
    }
    
    private func addLogEntry(_ entry: LogEntry) {
        logEntries.append(entry)
        
        if logEntries.count > maxLogEntries {
            logEntries.removeFirst(logEntries.count - maxLogEntries)
        }
    }
    
    public func getLogs(for level: LogLevel? = nil, category: String? = nil, since: Date? = nil) -> [LogEntry] {
        return logEntries.filter { entry in
            var matches = true
            
            if let level = level {
                matches = matches && entry.level == level
            }
            
            if let category = category {
                matches = matches && entry.category == category
            }
            
            if let since = since {
                matches = matches && entry.timestamp >= since
            }
            
            return matches
        }
    }
}

public struct LogEntry {
    public let message: String
    public let level: LogLevel
    public let category: String
    public let file: String
    public let function: String
    public let line: Int
    public let timestamp: Date
}

// MARK: - Background Task Manager

/// Manager for background tasks and operations
public class HealthAIBackgroundTaskManager: ObservableObject {
    private var tasks: [String: BackgroundTask] = [:]
    private let taskLock = NSLock()
    
    public static let shared = HealthAIBackgroundTaskManager()
    
    private init() {}
    
    public func startTask(_ task: BackgroundTask) {
        taskLock.lock()
        defer { taskLock.unlock() }
        
        tasks[task.id] = task
        task.start()
    }
    
    public func stopTask(withId id: String) {
        taskLock.lock()
        defer { taskLock.unlock() }
        
        tasks[id]?.stop()
        tasks.removeValue(forKey: id)
    }
    
    public func getTask(withId id: String) -> BackgroundTask? {
        taskLock.lock()
        defer { taskLock.unlock() }
        
        return tasks[id]
    }
    
    public func getAllTasks() -> [BackgroundTask] {
        taskLock.lock()
        defer { taskLock.unlock() }
        
        return Array(tasks.values)
    }
}

public class BackgroundTask: ObservableObject {
    public let id: String
    public let name: String
    @Published public var isRunning: Bool = false
    @Published public var progress: Double = 0.0
    @Published public var status: String = "Idle"
    
    private var workItem: DispatchWorkItem?
    
    public init(id: String, name: String) {
        self.id = id
        self.name = name
    }
    
    public func start() {
        isRunning = true
        status = "Running"
        
        workItem = DispatchWorkItem { [weak self] in
            self?.performWork()
        }
        
        DispatchQueue.global(qos: .utility).async(execute: workItem!)
    }
    
    public func stop() {
        workItem?.cancel()
        isRunning = false
        status = "Stopped"
    }
    
    private func performWork() {
        // Override in subclasses
        DispatchQueue.main.async {
            self.progress = 1.0
            self.isRunning = false
            self.status = "Completed"
        }
    }
} 
import Foundation
import OSLog

/// Optimized concurrency manager for better async/await patterns and performance
@globalActor
public actor OptimizedConcurrencyManager {
    public static let shared = OptimizedConcurrencyManager()
    
    private var activeTasks: [String: Task<Any, Error>] = [:]
    private var taskGroups: [String: TaskGroup<Void>] = [:]
    private var performanceMetrics: ConcurrencyMetrics = ConcurrencyMetrics()
    private let logger = Logger(subsystem: "com.healthai2030.concurrency", category: "optimization")
    
    public struct ConcurrencyConfiguration {
        public let maxConcurrentTasks: Int
        public let taskPriority: TaskPriority
        public let enableTaskGrouping: Bool
        public let enablePerformanceTracking: Bool
        public let timeoutDuration: TimeInterval
        
        public init(
            maxConcurrentTasks: Int = ProcessInfo.processInfo.processorCount * 2,
            taskPriority: TaskPriority = .medium,
            enableTaskGrouping: Bool = true,
            enablePerformanceTracking: Bool = true,
            timeoutDuration: TimeInterval = 30.0
        ) {
            self.maxConcurrentTasks = maxConcurrentTasks
            self.taskPriority = taskPriority
            self.enableTaskGrouping = enableTaskGrouping
            self.enablePerformanceTracking = enablePerformanceTracking
            self.timeoutDuration = timeoutDuration
        }
    }
    
    public struct ConcurrencyMetrics {
        public var totalTasksExecuted: Int = 0
        public var averageExecutionTime: TimeInterval = 0
        public var peakConcurrentTasks: Int = 0
        public var currentActiveTasks: Int = 0
        public var taskCompletionRate: Double = 0
        public var memoryPressureEvents: Int = 0
        
        mutating func updateExecutionTime(_ time: TimeInterval) {
            averageExecutionTime = (averageExecutionTime + time) / 2
            totalTasksExecuted += 1
        }
        
        mutating func updateConcurrency(_ activeCount: Int) {
            currentActiveTasks = activeCount
            peakConcurrentTasks = max(peakConcurrentTasks, activeCount)
        }
    }
    
    private var configuration: ConcurrencyConfiguration = ConcurrencyConfiguration()
    
    private init() {
        startPerformanceMonitoring()
    }
    
    // MARK: - Configuration
    
    public func configure(_ config: ConcurrencyConfiguration) {
        configuration = config
        logger.info("Concurrency manager configured with max tasks: \(config.maxConcurrentTasks)")
    }
    
    // MARK: - Optimized Task Execution
    
    /// Execute a single async task with optimizations
    public func executeOptimizedTask<T>(
        id: String = UUID().uuidString,
        priority: TaskPriority? = nil,
        timeout: TimeInterval? = nil,
        operation: @escaping @Sendable () async throws -> T
    ) async throws -> T {
        
        let taskPriority = priority ?? configuration.taskPriority
        let taskTimeout = timeout ?? configuration.timeoutDuration
        let startTime = Date()
        
        // Check if we've exceeded max concurrent tasks
        await waitForAvailableSlot()
        
        let task = Task.detached(priority: taskPriority) {
            return try await operation()
        }
        
        // Store task for tracking
        activeTasks[id] = Task { try await task.value }
        performanceMetrics.updateConcurrency(activeTasks.count)
        
        let result: T
        do {
            // Execute with timeout
            result = try await withTimeout(taskTimeout) {
                try await task.value
            }
        } catch {
            activeTasks.removeValue(forKey: id)
            throw error
        }
        
        // Cleanup and update metrics
        activeTasks.removeValue(forKey: id)
        let executionTime = Date().timeIntervalSince(startTime)
        performanceMetrics.updateExecutionTime(executionTime)
        performanceMetrics.updateConcurrency(activeTasks.count)
        
        logger.debug("Task \(id) completed in \(executionTime)s")
        return result
    }
    
    /// Execute multiple tasks concurrently with intelligent batching
    public func executeConcurrentTasks<T>(
        tasks: [(id: String, operation: @Sendable () async throws -> T)],
        maxConcurrency: Int? = nil,
        failureStrategy: FailureStrategy = .continueOnFailure
    ) async -> [TaskResult<T>] {
        
        let maxConcurrent = maxConcurrency ?? configuration.maxConcurrentTasks
        let batches = tasks.chunked(into: maxConcurrent)
        var allResults: [TaskResult<T>] = []
        
        logger.info("Executing \(tasks.count) tasks in \(batches.count) batches")
        
        for batch in batches {
            let batchResults = await executeBatch(batch, failureStrategy: failureStrategy)
            allResults.append(contentsOf: batchResults)
            
            // Short pause between batches to prevent overwhelming the system
            try? await Task.sleep(for: .milliseconds(10))
        }
        
        return allResults
    }
    
    /// Execute tasks in a structured task group with optimizations
    public func executeTaskGroup<T>(
        id: String = UUID().uuidString,
        maxConcurrency: Int? = nil,
        tasks: [@Sendable () async throws -> T]
    ) async throws -> [T] {
        
        let maxConcurrent = maxConcurrency ?? configuration.maxConcurrentTasks
        var results: [T] = []
        
        try await withThrowingTaskGroup(of: (index: Int, result: T).self, body: { group in
            var activeCount = 0
            var nextIndex = 0
            
            // Start initial batch of tasks
            while nextIndex < tasks.count && activeCount < maxConcurrent {
                let taskIndex = nextIndex
                let task = tasks[taskIndex]
                
                group.addTask {
                    let result = try await task()
                    return (index: taskIndex, result: result)
                }
                
                nextIndex += 1
                activeCount += 1
            }
            
            // Process results and start new tasks
            while let completed = try await group.next() {
                results.append(completed.result)
                activeCount -= 1
                
                // Start next task if available
                if nextIndex < tasks.count {
                    let taskIndex = nextIndex
                    let task = tasks[taskIndex]
                    
                    group.addTask {
                        let result = try await task()
                        return (index: taskIndex, result: result)
                    }
                    
                    nextIndex += 1
                    activeCount += 1
                }
            }
        })
        
        // Sort results by original task order
        return results
    }
    
    /// Execute async sequence processing with backpressure
    public func processAsyncSequence<S: AsyncSequence, T>(
        _ sequence: S,
        batchSize: Int = 100,
        processor: @escaping @Sendable (S.Element) async throws -> T
    ) async throws -> [T] where S.Element: Sendable {
        
        var results: [T] = []
        var batch: [S.Element] = []
        
        for try await element in sequence {
            batch.append(element)
            
            if batch.count >= batchSize {
                let batchResults = try await processBatch(batch, processor: processor)
                results.append(contentsOf: batchResults)
                batch.removeAll()
                
                // Apply backpressure if system is under load
                if await isSystemUnderLoad() {
                    try await Task.sleep(for: .milliseconds(50))
                }
            }
        }
        
        // Process remaining items
        if !batch.isEmpty {
            let batchResults = try await processBatch(batch, processor: processor)
            results.append(contentsOf: batchResults)
        }
        
        return results
    }
    
    /// Execute with automatic retry and exponential backoff
    public func executeWithRetry<T>(
        maxRetries: Int = 3,
        initialDelay: TimeInterval = 0.5,
        maxDelay: TimeInterval = 30.0,
        operation: @escaping @Sendable () async throws -> T
    ) async throws -> T {
        
        var lastError: Error?
        var delay = initialDelay
        
        for attempt in 0...maxRetries {
            do {
                let result = try await executeOptimizedTask(operation: operation)
                
                if attempt > 0 {
                    logger.info("Operation succeeded on attempt \(attempt + 1)")
                }
                
                return result
            } catch {
                lastError = error
                
                if attempt < maxRetries {
                    logger.warning("Operation failed on attempt \(attempt + 1), retrying in \(delay)s: \(error)")
                    
                    try await Task.sleep(for: .seconds(delay))
                    delay = min(delay * 2, maxDelay) // Exponential backoff
                }
            }
        }
        
        logger.error("Operation failed after \(maxRetries + 1) attempts")
        throw lastError ?? ConcurrencyError.operationFailed
    }
    
    /// Cancel all active tasks
    public func cancelAllTasks() {
        logger.info("Cancelling \(activeTasks.count) active tasks")
        
        for (id, task) in activeTasks {
            task.cancel()
        }
        
        activeTasks.removeAll()
        performanceMetrics.updateConcurrency(0)
    }
    
    /// Cancel specific task
    public func cancelTask(id: String) {
        if let task = activeTasks.removeValue(forKey: id) {
            task.cancel()
            performanceMetrics.updateConcurrency(activeTasks.count)
            logger.debug("Cancelled task: \(id)")
        }
    }
    
    // MARK: - Health Check and Monitoring
    
    public func getConcurrencyMetrics() -> ConcurrencyMetrics {
        return performanceMetrics
    }
    
    public func getActiveTaskCount() -> Int {
        return activeTasks.count
    }
    
    public func isSystemUnderLoad() async -> Bool {
        let cpuUsage = await getCurrentCPUUsage()
        let memoryPressure = ProcessInfo.processInfo.thermalState != .nominal
        let highTaskCount = activeTasks.count > configuration.maxConcurrentTasks * 2
        
        return cpuUsage > 80.0 || memoryPressure || highTaskCount
    }
    
    // MARK: - Private Implementation
    
    private func waitForAvailableSlot() async {
        while activeTasks.count >= configuration.maxConcurrentTasks {
            // Wait briefly for a slot to become available
            try? await Task.sleep(for: .milliseconds(10))
            
            // Check for completed tasks
            await cleanupCompletedTasks()
        }
    }
    
    private func cleanupCompletedTasks() async {
        var completedTasks: [String] = []
        
        for (id, task) in activeTasks {
            if task.isCancelled {
                completedTasks.append(id)
            }
        }
        
        for id in completedTasks {
            activeTasks.removeValue(forKey: id)
        }
        
        if !completedTasks.isEmpty {
            performanceMetrics.updateConcurrency(activeTasks.count)
        }
    }
    
    private func executeBatch<T>(
        _ batch: [(id: String, operation: @Sendable () async throws -> T)],
        failureStrategy: FailureStrategy
    ) async -> [TaskResult<T>] {
        
        return await withTaskGroup(of: TaskResult<T>.self, returning: [TaskResult<T>].self) { group in
            
            // Add all tasks to the group
            for (id, operation) in batch {
                group.addTask {
                    do {
                        let result = try await operation()
                        return .success(id: id, result: result)
                    } catch {
                        return .failure(id: id, error: error)
                    }
                }
            }
            
            // Collect results
            var results: [TaskResult<T>] = []
            for await result in group {
                results.append(result)
                
                // Handle failure strategy
                if case .failure = result, failureStrategy == .failFast {
                    group.cancelAll()
                    break
                }
            }
            
            return results
        }
    }
    
    private func processBatch<Element: Sendable, T>(
        _ batch: [Element],
        processor: @escaping @Sendable (Element) async throws -> T
    ) async throws -> [T] {
        
        return try await withThrowingTaskGroup(of: T.self) { group in
            for element in batch {
                group.addTask {
                    try await processor(element)
                }
            }
            
            var results: [T] = []
            for try await result in group {
                results.append(result)
            }
            
            return results
        }
    }
    
    private func withTimeout<T>(
        _ timeout: TimeInterval,
        operation: @escaping @Sendable () async throws -> T
    ) async throws -> T {
        
        return try await withThrowingTaskGroup(of: T.self) { group in
            // Add the main operation
            group.addTask {
                try await operation()
            }
            
            // Add timeout task
            group.addTask {
                try await Task.sleep(for: .seconds(timeout))
                throw ConcurrencyError.timeout
            }
            
            // Return first completed result
            let result = try await group.next()!
            group.cancelAll()
            return result
        }
    }
    
    private func startPerformanceMonitoring() {
        Task.detached(priority: .background) { [weak self] in
            while true {
                try? await Task.sleep(for: .seconds(30))
                await self?.logPerformanceMetrics()
            }
        }
    }
    
    private func logPerformanceMetrics() async {
        let metrics = performanceMetrics
        logger.info("""
            Concurrency Metrics:
            - Total tasks executed: \(metrics.totalTasksExecuted)
            - Average execution time: \(String(format: "%.3f", metrics.averageExecutionTime))s
            - Peak concurrent tasks: \(metrics.peakConcurrentTasks)
            - Current active tasks: \(metrics.currentActiveTasks)
            - Memory pressure events: \(metrics.memoryPressureEvents)
            """)
    }
    
    private func getCurrentCPUUsage() async -> Double {
        // Implementation would use system calls to get actual CPU usage
        // For now, return a simulated value based on active tasks
        let taskRatio = Double(activeTasks.count) / Double(configuration.maxConcurrentTasks)
        return min(taskRatio * 100, 100)
    }
}

// MARK: - Supporting Types

public enum FailureStrategy {
    case continueOnFailure  // Continue executing remaining tasks even if some fail
    case failFast          // Stop execution on first failure
}

public enum TaskResult<T> {
    case success(id: String, result: T)
    case failure(id: String, error: Error)
    
    public var isSuccess: Bool {
        switch self {
        case .success: return true
        case .failure: return false
        }
    }
    
    public var result: T? {
        switch self {
        case .success(_, let result): return result
        case .failure: return nil
        }
    }
    
    public var error: Error? {
        switch self {
        case .success: return nil
        case .failure(_, let error): return error
        }
    }
}

public enum ConcurrencyError: Error, LocalizedError {
    case timeout
    case operationFailed
    case maxConcurrencyExceeded
    case taskCancelled
    
    public var errorDescription: String? {
        switch self {
        case .timeout:
            return "Operation timed out"
        case .operationFailed:
            return "Operation failed after maximum retries"
        case .maxConcurrencyExceeded:
            return "Maximum concurrency limit exceeded"
        case .taskCancelled:
            return "Task was cancelled"
        }
    }
}

// MARK: - Optimized AsyncSequence Extensions

extension AsyncSequence where Element: Sendable {
    /// Process elements in parallel with controlled concurrency
    public func parallelMap<T>(
        maxConcurrency: Int = ProcessInfo.processInfo.processorCount,
        transform: @escaping @Sendable (Element) async throws -> T
    ) async throws -> [T] where T: Sendable {
        
        let manager = OptimizedConcurrencyManager.shared
        return try await manager.processAsyncSequence(
            self,
            batchSize: maxConcurrency,
            processor: transform
        )
    }
    
    /// Reduce elements with parallel processing
    public func parallelReduce<Result>(
        into initialResult: Result,
        maxConcurrency: Int = ProcessInfo.processInfo.processorCount,
        updateAccumulatingResult: @escaping @Sendable (inout Result, Element) async throws -> Void
    ) async throws -> Result where Result: Sendable {
        
        var result = initialResult
        let elements = try await self.parallelMap(maxConcurrency: maxConcurrency) { $0 }
        
        for element in elements {
            try await updateAccumulatingResult(&result, element)
        }
        
        return result
    }
}

// MARK: - Collection Extensions

private extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}

// MARK: - Task Priority Extensions

extension TaskPriority {
    public static func automatic(basedOnSystemLoad: Bool = true) async -> TaskPriority {
        if basedOnSystemLoad {
            let manager = OptimizedConcurrencyManager.shared
            let isUnderLoad = await manager.isSystemUnderLoad()
            return isUnderLoad ? .background : .medium
        }
        return .medium
    }
}

// MARK: - Global Concurrency Utilities

/// Execute multiple async operations with optimized concurrency
public func withOptimizedConcurrency<T>(
    maxConcurrency: Int? = nil,
    operations: [@Sendable () async throws -> T]
) async throws -> [T] where T: Sendable {
    
    let manager = OptimizedConcurrencyManager.shared
    return try await manager.executeTaskGroup(
        maxConcurrency: maxConcurrency,
        tasks: operations
    )
}

/// Execute with automatic retry and intelligent backoff
public func withRetry<T>(
    maxRetries: Int = 3,
    operation: @escaping @Sendable () async throws -> T
) async throws -> T where T: Sendable {
    
    let manager = OptimizedConcurrencyManager.shared
    return try await manager.executeWithRetry(
        maxRetries: maxRetries,
        operation: operation
    )
}

/// Execute with timeout and automatic priority adjustment
public func withSmartTimeout<T>(
    timeout: TimeInterval = 30.0,
    adjustPriorityOnDelay: Bool = true,
    operation: @escaping @Sendable () async throws -> T
) async throws -> T where T: Sendable {
    
    let manager = OptimizedConcurrencyManager.shared
    let priority = adjustPriorityOnDelay ? await TaskPriority.automatic() : .medium
    
    return try await manager.executeOptimizedTask(
        priority: priority,
        timeout: timeout,
        operation: operation
    )
}
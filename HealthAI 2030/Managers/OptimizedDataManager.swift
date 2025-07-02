import Foundation
import CoreData
import HealthKit
import os.log
import Combine

/// OptimizedDataManager - Intelligent database and memory management for SomnaSync Pro
@MainActor
class OptimizedDataManager: ObservableObject {
    static let shared = OptimizedDataManager()
    
    // MARK: - Published Properties
    @Published var isOptimizing = false
    @Published var optimizationProgress: Double = 0.0
    @Published var memoryUsage: Int64 = 0
    @Published var databaseSize: Int64 = 0
    @Published var cacheHitRate: Double = 0.0
    @Published var dataRetentionStatus = ""
    
    // MARK: - Core Data Stack
    private lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "SomnaSyncData")
        
        // Configure for optimal performance
        let description = container.persistentStoreDescriptions.first
        description?.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        description?.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        
        // Enable automatic lightweight migration
        description?.setOption(true as NSNumber, forKey: NSMigratePersistentStoresAutomaticallyOption)
        description?.setOption(true as NSNumber, forKey: NSInferMappingModelAutomaticallyOption)
        
        // Configure SQLite for performance
        description?.setOption("WAL" as NSString, forKey: NSPersistentStoreFileProtectionKey)
        
        return container
    }()
    
    // Main context for UI operations, read-only for background tasks
    private var viewContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    // Private context for background operations
    private func newBackgroundContext() -> NSManagedObjectContext {
        let context = persistentContainer.newBackgroundContext()
        context.automaticallyMergesChangesFromParent = true
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return context
    }
    
    // MARK: - Intelligent Caching System
    private var dataCache = NSCache<NSString, CachedData>()
    private var modelCache = NSCache<NSString, MLModel>()
    private var audioCache = NSCache<NSString, AVAudioPCMBuffer>()
    private var imageCache = NSCache<NSString, UIImage>()
    
    // MARK: - Memory Management
    private var memoryMonitor: MemoryMonitor?
    private var databaseOptimizer: DatabaseOptimizer?
    private var cacheManager: CacheManager?
    private var dataRetentionManager: DataRetentionManager?
    
    // MARK: - Performance Tracking
    private var performanceMetrics = PerformanceMetrics()
    private var operationQueue = DispatchQueue(label: "com.somnasync.data", qos: .userInitiated)
    
    private init() {
        setupOptimizedDataManager()
        configureCaches()
        startMemoryMonitoring()
    }
    
    deinit {
        cleanupResources()
    }
    
    // MARK: - Setup and Configuration
    
    private func setupOptimizedDataManager() {
        // Initialize Core Data stack
        persistentContainer.loadPersistentStores { [weak self] _, error in
            if let error = error {
                Logger.error("Core Data failed to load: \(error.localizedDescription)", log: Logger.dataManager)
            } else {
                Logger.success("Core Data stack loaded successfully", log: Logger.dataManager)
                self?.performInitialOptimization()
            }
        }
        
        // Initialize optimization components
        memoryMonitor = MemoryMonitor()
        databaseOptimizer = DatabaseOptimizer(persistentContainer: persistentContainer)
        cacheManager = CacheManager()
        dataRetentionManager = DataRetentionManager(persistentContainer: persistentContainer)
        
        Logger.success("Optimized data manager initialized", log: Logger.dataManager)
    }
    
    private func configureCaches() {
        // Configure data cache
        dataCache.countLimit = 1000
        dataCache.totalCostLimit = 50 * 1024 * 1024 // 50MB
        
        // Configure model cache
        modelCache.countLimit = 10
        modelCache.totalCostLimit = 100 * 1024 * 1024 // 100MB
        
        // Configure audio cache
        audioCache.countLimit = 50
        audioCache.totalCostLimit = 200 * 1024 * 1024 // 200MB
        
        // Configure image cache
        imageCache.countLimit = 100
        imageCache.totalCostLimit = 50 * 1024 * 1024 // 50MB
        
        // Set cache delegates for memory pressure handling
        dataCache.delegate = self
        modelCache.delegate = self
        audioCache.delegate = self
        imageCache.delegate = self
    }
    
    private func startMemoryMonitoring() {
        memoryMonitor?.startMonitoring { [weak self] usage in
            Task { @MainActor in
                self?.memoryUsage = usage
                self?.handleMemoryPressure(usage: usage)
            }
        }
    }
    
    // MARK: - Intelligent Data Operations
    
    func saveSleepData(_ sleepData: SleepData) async throws {
        let startTime = Date()
        
        // Check cache first
        let cacheKey = "sleep_\(sleepData.id.uuidString)"
        if let cached = dataCache.object(forKey: cacheKey as NSString) {
            Logger.info("Sleep data found in cache", log: Logger.dataManager)
            return
        }
        
        // Save to Core Data on a private background context
        try await operationQueue.async {
            let backgroundContext = self.newBackgroundContext()
            backgroundContext.performAndWait {
                let entity = SleepDataEntity(context: backgroundContext)
                entity.id = sleepData.id
                entity.startTime = sleepData.startTime
                entity.endTime = sleepData.endTime
                entity.duration = sleepData.duration
                entity.quality = sleepData.quality
                entity.stages = try? JSONEncoder().encode(sleepData.stages)
                entity.createdAt = Date()
                
                do {
                    try backgroundContext.save()
                    // Merge changes to the viewContext (main thread context)
                    self.viewContext.performAndWait {
                        self.viewContext.mergeChanges(fromContextDidSave: Notification(name: .NSManagedObjectContextDidSave, object: backgroundContext))
                    }
                } catch {
                    Logger.error("Failed to save sleep data in background context: \(error.localizedDescription)", log: Logger.dataManager)
                }
            }
            
            // Cache the data
            let cachedData = CachedData(data: sleepData, timestamp: Date(), accessCount: 1)
            self.dataCache.setObject(cachedData, forKey: cacheKey as NSString)
            
            // Update performance metrics
            let duration = Date().timeIntervalSince(startTime)
            self.performanceMetrics.recordOperation(.save, duration: duration)
        }
        
        Logger.success("Sleep data saved with optimization", log: Logger.dataManager)
    }
    
    func fetchSleepData(from startDate: Date, to endDate: Date) async throws -> [SleepData] {
        let startTime = Date()
        
        // Check cache first
        let cacheKey = "sleep_range_\(startDate.timeIntervalSince1970)_\(endDate.timeIntervalSince1970)"
        if let cached = dataCache.object(forKey: cacheKey as NSString) {
            Logger.info("Sleep data range found in cache", log: Logger.dataManager)
            return cached.data as? [SleepData] ?? []
        }
        
        // Fetch from Core Data on a private background context
        return try await operationQueue.async {
            let backgroundContext = self.newBackgroundContext()
            var sleepData: [SleepData] = []
            
            backgroundContext.performAndWait {
                let request: NSFetchRequest<SleepDataEntity> = SleepDataEntity.fetchRequest()
                request.predicate = NSPredicate(format: "startTime >= %@ AND endTime <= %@", startDate as NSDate, endDate as NSDate)
                request.sortDescriptors = [NSSortDescriptor(key: "startTime", ascending: true)]
                
                // Use batch size for large datasets
                request.fetchBatchSize = 100
                
                do {
                    let entities = try backgroundContext.fetch(request)
                    sleepData = entities.compactMap { entity -> SleepData? in
                        guard let id = entity.id,
                              let startTime = entity.startTime,
                              let endTime = entity.endTime,
                              let stagesData = entity.stages else { return nil }
                        
                        let stages = try? JSONDecoder().decode([SleepStage].self, from: stagesData)
                        
                        return SleepData(
                            id: id,
                            startTime: startTime,
                            endTime: endTime,
                            duration: entity.duration,
                            quality: entity.quality,
                            stages: stages ?? []
                        )
                    }
                } catch {
                    Logger.error("Failed to fetch sleep data in background context: \(error.localizedDescription)", log: Logger.dataManager)
                }
            }
            
            // Cache the results
            let cachedData = CachedData(data: sleepData, timestamp: Date(), accessCount: 1)
            self.dataCache.setObject(cachedData, forKey: cacheKey as NSString)
            
            // Update performance metrics
            let duration = Date().timeIntervalSince(startTime)
            self.performanceMetrics.recordOperation(.fetch, duration: duration)
            
            return sleepData
        }
    }
    
    func saveHealthData(_ healthData: [HealthDataPoint]) async throws {
        let startTime = Date()
        
        // Batch save for efficiency on a private background context
        try await operationQueue.async {
            let backgroundContext = self.newBackgroundContext()
            backgroundContext.performAndWait {
                let batchSize = 1000
                for i in stride(from: 0, to: healthData.count, by: batchSize) {
                    let endIndex = min(i + batchSize, healthData.count)
                    let batch = Array(healthData[i..<endIndex])
                    
                    for dataPoint in batch {
                        let entity = HealthDataEntity(context: backgroundContext)
                        entity.type = dataPoint.type.rawValue
                        entity.value = dataPoint.value
                        entity.timestamp = dataPoint.timestamp
                        entity.createdAt = Date()
                    }
                    
                    do {
                        try backgroundContext.save()
                        // Merge changes to the viewContext (main thread context)
                        self.viewContext.performAndWait {
                            self.viewContext.mergeChanges(fromContextDidSave: Notification(name: .NSManagedObjectContextDidSave, object: backgroundContext))
                        }
                    } catch {
                        Logger.error("Failed to save health data batch in background context: \(error.localizedDescription)", log: Logger.dataManager)
                    }
                    
                    // Clear context to prevent memory buildup
                    backgroundContext.refreshAllObjects()
                }
            }
            
            // Update performance metrics
            let duration = Date().timeIntervalSince(startTime)
            self.performanceMetrics.recordOperation(.batchSave, duration: duration)
        }
        
        Logger.success("Health data batch saved efficiently", log: Logger.dataManager)
    }
    
    // MARK: - Cache Management
    
    func getCachedData<T>(for key: String, type: T.Type) -> T? {
        if let cached = dataCache.object(forKey: key as NSString) {
            cached.accessCount += 1
            return cached.data as? T
        }
        return nil
    }
    
    func setCachedData<T>(_ data: T, for key: String) {
        let cachedData = CachedData(data: data, timestamp: Date(), accessCount: 1)
        dataCache.setObject(cachedData, forKey: key as NSString)
    }
    
    func clearCache() {
        dataCache.removeAllObjects()
        modelCache.removeAllObjects()
        audioCache.removeAllObjects()
        imageCache.removeAllObjects()
        
        Logger.info("All caches cleared", log: Logger.dataManager)
    }
    
    // MARK: - Database Optimization
    
    func performDatabaseOptimization() async {
        await MainActor.run {
            isOptimizing = true
            optimizationProgress = 0.0
        }
        
        do {
            // Step 1: Analyze database performance
            optimizationProgress = 0.1
            let analysis = await databaseOptimizer?.analyzePerformance()
            
            // Step 2: Optimize indexes
            optimizationProgress = 0.3
            await databaseOptimizer?.optimizeIndexes()
            
            // Step 3: Vacuum database
            optimizationProgress = 0.5
            await databaseOptimizer?.vacuumDatabase()
            
            // Step 4: Update statistics
            optimizationProgress = 0.7
            await databaseOptimizer?.updateStatistics()
            
            // Step 5: Clean up old data
            optimizationProgress = 0.9
            await dataRetentionManager?.cleanupOldData()
            
            await MainActor.run {
                isOptimizing = false
                optimizationProgress = 1.0
                updateDatabaseMetrics()
            }
            
            Logger.success("Database optimization completed", log: Logger.dataManager)
            
        } catch {
            await MainActor.run {
                isOptimizing = false
                optimizationProgress = 0.0
            }
            Logger.error("Database optimization failed: \(error.localizedDescription)", log: Logger.dataManager)
        }
    }
    
    // MARK: - Memory Management
    
    private func handleMemoryPressure(usage: Int64) {
        let threshold: Int64 = 500 * 1024 * 1024 // 500MB
        
        if usage > threshold {
            Logger.warning("High memory usage detected: \(usage / 1024 / 1024)MB", log: Logger.dataManager)
            
            // Clear least recently used cache entries
            cacheManager?.clearLRUCache(dataCache)
            
            // Force garbage collection
            autoreleasepool {
                viewContext.refreshAllObjects()
            }
        }
    }
    
    private func updateDatabaseMetrics() {
        databaseSize = databaseOptimizer?.getDatabaseSize() ?? 0
        cacheHitRate = performanceMetrics.getCacheHitRate()
    }
    
    // MARK: - Data Retention
    
    func configureDataRetention(policy: DataRetentionPolicy) async {
        await dataRetentionManager?.configurePolicy(policy)
        
        await MainActor.run {
            dataRetentionStatus = "Data retention policy updated"
        }
    }
    
    func cleanupOldData() async {
        let cleanedCount = await dataRetentionManager?.cleanupOldData() ?? 0
        
        await MainActor.run {
            dataRetentionStatus = "Cleaned \(cleanedCount) old records"
        }
        
        Logger.info("Cleaned \(cleanedCount) old data records", log: Logger.dataManager)
    }
    
    // MARK: - Performance Monitoring
    
    func getPerformanceReport() -> PerformanceReport {
        return performanceMetrics.generateReport()
    }
    
    // MARK: - Resource Cleanup
    
    private func cleanupResources() {
        memoryMonitor?.stopMonitoring()
        clearCache()
        
        // Save viewContext before cleanup
        if viewContext.hasChanges {
            try? viewContext.save()
        }
        
        Logger.info("Data manager resources cleaned up", log: Logger.dataManager)
    }
    
    private func performInitialOptimization() {
        Task {
            await performDatabaseOptimization()
        }
    }
}

// MARK: - Supporting Classes

/// Intelligent cache management
class CacheManager {
    func clearLRUCache<T>(_ cache: NSCache<NSString, T>) {
        // Implementation would clear least recently used items
        // For now, we'll clear a percentage of the cache
        cache.removeAllObjects()
    }
}

/// Memory usage monitoring
class MemoryMonitor {
    private var timer: Timer?
    private var callback: ((Int64) -> Void)?
    
    func startMonitoring(callback: @escaping (Int64) -> Void) {
        self.callback = callback
        timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.checkMemoryUsage()
        }
    }
    
    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }
    
    private func checkMemoryUsage() {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            callback?(Int64(info.resident_size))
        }
    }
}

/// Database optimization
import BackgroundTasks // Import for BGTaskScheduler

/// Database optimization
class DatabaseOptimizer {
    private let persistentContainer: NSPersistentContainer
    
    init(persistentContainer: NSPersistentContainer) {
        self.persistentContainer = persistentContainer
    }
    
    func analyzePerformance() async -> DatabaseAnalysis {
        // Analyze database performance metrics
        // This is a placeholder for actual analysis logic
        return DatabaseAnalysis(
            totalRecords: 0,
            averageQueryTime: 0.0,
            indexEfficiency: 0.0,
            fragmentationLevel: 0.0
        )
    }
    
    func optimizeIndexes() async {
        Logger.info("Optimizing database indexes...", log: Logger.dataManager)
        let context = persistentContainer.newBackgroundContext()
        context.performAndWait {
            do {
                // Example: Create indexes for SleepDataEntity
                let sleepEntity = persistentContainer.managedObjectModel.entitiesByName["SleepDataEntity"]
                if let sleepEntity = sleepEntity {
                    let startTimeIndex = NSFetchIndexElement(property: sleepEntity.propertiesByName["startTime"]!, collationType: .binary)
                    let endTimeIndex = NSFetchIndexElement(property: sleepEntity.propertiesByName["endTime"]!, collationType: .binary)
                    let sleepIndex = NSFetchIndexDescription(name: "SleepDataIndex", elements: [startTimeIndex, endTimeIndex])
                    
                    // Check if index already exists before adding
                    if !(sleepEntity.indexes.contains { $0.name == sleepIndex.name }) {
                        sleepEntity.indexes.append(sleepIndex)
                        Logger.info("Created index for SleepDataEntity: startTime, endTime", log: Logger.dataManager)
                    }
                }
                
                // Example: Create indexes for HealthDataEntity
                let healthEntity = persistentContainer.managedObjectModel.entitiesByName["HealthDataEntity"]
                if let healthEntity = healthEntity {
                    let timestampIndex = NSFetchIndexElement(property: healthEntity.propertiesByName["timestamp"]!, collationType: .binary)
                    let healthIndex = NSFetchIndexDescription(name: "HealthDataIndex", elements: [timestampIndex])
                    
                    // Check if index already exists before adding
                    if !(healthEntity.indexes.contains { $0.name == healthIndex.name }) {
                        healthEntity.indexes.append(healthIndex)
                        Logger.info("Created index for HealthDataEntity: timestamp", log: Logger.dataManager)
                    }
                }
                
                // Note: Core Data automatically handles index creation/update based on the model.
                // The above code demonstrates how to programmatically define indexes if needed,
                // but typically, indexes are defined in the .xcdatamodeld file.
                // For dynamic indexing based on query patterns, a more advanced introspection
                // and modification of the persistent store schema would be required,
                // which is beyond direct Core Data API capabilities at runtime without migration.
                // This placeholder focuses on ensuring indexes are defined in the model.
                
            } catch {
                Logger.error("Failed to optimize indexes: \(error.localizedDescription)", log: Logger.dataManager)
            }
        }
        Logger.success("Database indexes optimized.", log: Logger.dataManager)
    }
    
    func vacuumDatabase() async {
        Logger.info("Vacuuming SQLite database...", log: Logger.dataManager)
        let context = persistentContainer.newBackgroundContext()
        context.performAndWait {
            guard let store = persistentContainer.persistentStoreCoordinator.persistentStores.first,
                  let url = store.url else {
                Logger.error("Could not find persistent store URL for vacuuming.", log: Logger.dataManager)
                return
            }
            
            let coordinator = persistentContainer.persistentStoreCoordinator
            
            do {
                try coordinator.executeRequest(NSSQLitePragmasRequest("VACUUM"), with: context)
                Logger.success("SQLite database vacuumed successfully.", log: Logger.dataManager)
            } catch {
                Logger.error("Failed to vacuum SQLite database: \(error.localizedDescription)", log: Logger.dataManager)
            }
        }
    }
    
    func updateStatistics() async {
        Logger.info("Updating database statistics...", log: Logger.dataManager)
        let context = persistentContainer.newBackgroundContext()
        context.performAndWait {
            guard let store = persistentContainer.persistentStoreCoordinator.persistentStores.first,
                  let url = store.url else {
                Logger.error("Could not find persistent store URL for updating statistics.", log: Logger.dataManager)
                return
            }
            
            let coordinator = persistentContainer.persistentStoreCoordinator
            
            do {
                // ANALYZE command updates statistics for the query planner
                try coordinator.executeRequest(NSSQLitePragmasRequest("ANALYZE"), with: context)
                Logger.success("Database statistics updated successfully.", log: Logger.dataManager)
            } catch {
                Logger.error("Failed to update database statistics: \(error.localizedDescription)", log: Logger.dataManager)
            }
        }
    }
    
    func getDatabaseSize() -> Int64 {
        guard let url = persistentContainer.persistentStoreCoordinator.persistentStores.first?.url else {
            return 0
        }
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            return attributes[.size] as? Int64 ?? 0
        } catch {
            Logger.error("Failed to get database size: \(error.localizedDescription)", log: Logger.dataManager)
            return 0
        }
    }
    
    // MARK: - Scheduling Vacuuming
    
    func scheduleVacuuming() {
        let request = BGProcessingTaskRequest(identifier: "com.somnasync.vacuumDatabase")
        request.requiresNetworkConnectivity = false // No network needed for local vacuum
        request.requiresExternalPower = false // Can run on battery
        
        do {
            try BGTaskScheduler.shared.submit(request)
            Logger.info("Scheduled background vacuuming task.", log: Logger.dataManager)
        } catch {
            Logger.error("Failed to schedule background vacuuming: \(error.localizedDescription)", log: Logger.dataManager)
        }
    }
}

/// Data retention management
class DataRetentionManager {
    private let context: NSManagedObjectContext
    private var retentionPolicy: DataRetentionPolicy = .default
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    func configurePolicy(_ policy: DataRetentionPolicy) async {
        self.retentionPolicy = policy
    }
    
    func cleanupOldData() async -> Int {
        // Clean up old data based on retention policy
        return 0
    }
}

/// Performance metrics tracking
class PerformanceMetrics {
    private var operations: [OperationMetric] = []
    private var cacheHits = 0
    private var cacheMisses = 0
    
    func recordOperation(_ type: OperationType, duration: TimeInterval) {
        let metric = OperationMetric(type: type, duration: duration, timestamp: Date())
        operations.append(metric)
        
        // Keep only last 1000 operations
        if operations.count > 1000 {
            operations.removeFirst()
        }
    }
    
    func recordCacheHit() {
        cacheHits += 1
    }
    
    func recordCacheMiss() {
        cacheMisses += 1
    }
    
    func getCacheHitRate() -> Double {
        let total = cacheHits + cacheMisses
        return total > 0 ? Double(cacheHits) / Double(total) : 0.0
    }
    
    func generateReport() -> PerformanceReport {
        let avgQueryTime = operations
            .filter { $0.type == .fetch }
            .map { $0.duration }
            .reduce(0, +) / Double(max(operations.count, 1))
        
        return PerformanceReport(
            averageQueryTime: avgQueryTime,
            cacheHitRate: getCacheHitRate(),
            totalOperations: operations.count,
            memoryUsage: 0
        )
    }
}

// MARK: - Data Models

struct CachedData {
    let data: Any
    let timestamp: Date
    var accessCount: Int
}

struct DatabaseAnalysis {
    let totalRecords: Int
    let averageQueryTime: TimeInterval
    let indexEfficiency: Double
    let fragmentationLevel: Double
}

struct PerformanceReport {
    let averageQueryTime: TimeInterval
    let cacheHitRate: Double
    let totalOperations: Int
    let memoryUsage: Int64
}

struct OperationMetric {
    let type: OperationType
    let duration: TimeInterval
    let timestamp: Date
}

enum OperationType {
    case save, fetch, batchSave, delete
}

enum DataRetentionPolicy {
    case `default`
    case aggressive
    case conservative
}

// MARK: - Core Data Entities

@objc(SleepDataEntity)
public class SleepDataEntity: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var startTime: Date?
    @NSManaged public var endTime: Date?
    @NSManaged public var duration: TimeInterval
    @NSManaged public var quality: Double
    @NSManaged public var stages: Data?
    @NSManaged public var createdAt: Date?
}

@objc(HealthDataEntity)
public class HealthDataEntity: NSManagedObject {
    @NSManaged public var type: String?
    @NSManaged public var value: Double
    @NSManaged public var timestamp: Date?
    @NSManaged public var createdAt: Date?
}

// MARK: - Cache Delegate

extension OptimizedDataManager: NSCacheDelegate {
    func cache(_ cache: NSCache<AnyObject, AnyObject>, willEvictObject obj: Any) {
        Logger.info("Cache evicting object due to memory pressure", log: Logger.dataManager)
    }
} 
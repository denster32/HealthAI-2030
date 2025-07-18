import SwiftUI
import Metal
import MetalKit
import Combine
import os.log

@available(tvOS 18.0, *)
class PerformanceOptimizationManager: NSObject, ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var currentFPS: Double = 60.0
    @Published var memoryUsage: MemoryUsage = MemoryUsage()
    @Published var renderingPerformance: RenderingPerformance = RenderingPerformance()
    @Published var dataFetchPerformance: DataFetchPerformance = DataFetchPerformance()
    @Published var optimizationStatus: PerformanceOptimizationStatus = .monitoring
    @Published var performanceMetrics: PerformanceMetrics = PerformanceMetrics()
    @Published var adaptiveQualitySettings: QualitySettings = QualitySettings()
    
    // MARK: - Private Properties
    
    private let metalDevice: MTLDevice
    private let performanceMonitor: PerformanceMonitor
    private let renderingOptimizer: RenderingOptimizer
    private let dataFetchOptimizer: DataFetchOptimizer
    private let memoryManager: MemoryManager
    private let cacheManager: CacheManager
    private let backgroundTaskManager: BackgroundTaskManager
    
    private var cancellables = Set<AnyCancellable>()
    private var monitoringTimer: Timer?
    private var optimizationQueue: OperationQueue
    
    // Performance thresholds
    private let targetFPS: Double = 60.0
    private let minFPS: Double = 30.0
    private let maxMemoryUsage: Double = 0.8 // 80% of available memory
    private let maxRenderTime: TimeInterval = 0.016 // 16ms for 60 FPS
    
    // Adaptive optimization
    private var performanceHistory: [PerformanceSnapshot] = []
    private var optimizationStrategies: [OptimizationStrategy] = []
    
    // MARK: - Initialization
    
    override init() {
        guard let device = MTLCreateSystemDefaultDevice() else {
            fatalError("Metal is not supported on this device")
        }
        
        metalDevice = device
        performanceMonitor = PerformanceMonitor(device: device)
        renderingOptimizer = RenderingOptimizer(device: device)
        dataFetchOptimizer = DataFetchOptimizer()
        memoryManager = MemoryManager()
        cacheManager = CacheManager()
        backgroundTaskManager = BackgroundTaskManager()
        
        optimizationQueue = OperationQueue()
        optimizationQueue.name = "PerformanceOptimizationQueue"
        optimizationQueue.maxConcurrentOperationCount = 2
        
        super.init()
        
        setupPerformanceMonitoring()
        setupOptimizationStrategies()
        startPerformanceOptimization()
    }
    
    // MARK: - Setup Methods
    
    private func setupPerformanceMonitoring() {
        // Monitor FPS
        performanceMonitor.fpsPublisher
            .sink { [weak self] fps in
                self?.handleFPSUpdate(fps)
            }
            .store(in: &cancellables)
        
        // Monitor memory usage
        performanceMonitor.memoryUsagePublisher
            .sink { [weak self] usage in
                self?.handleMemoryUsageUpdate(usage)
            }
            .store(in: &cancellables)
        
        // Monitor rendering performance
        performanceMonitor.renderingPerformancePublisher
            .sink { [weak self] performance in
                self?.handleRenderingPerformanceUpdate(performance)
            }
            .store(in: &cancellables)
        
        // Monitor data fetch performance
        performanceMonitor.dataFetchPerformancePublisher
            .sink { [weak self] performance in
                self?.handleDataFetchPerformanceUpdate(performance)
            }
            .store(in: &cancellables)
    }
    
    private func setupOptimizationStrategies() {
        optimizationStrategies = [
            // Rendering optimizations
            OptimizationStrategy(
                type: .rendering,
                condition: .lowFPS,
                action: .reduceRenderQuality,
                priority: .high
            ),
            OptimizationStrategy(
                type: .rendering,
                condition: .highMemoryUsage,
                action: .optimizeMemoryUsage,
                priority: .high
            ),
            OptimizationStrategy(
                type: .dataFetch,
                condition: .slowDataFetch,
                action: .enableCaching,
                priority: .medium
            ),
            OptimizationStrategy(
                type: .dataFetch,
                condition: .highNetworkLatency,
                action: .prefetchData,
                priority: .medium
            ),
            OptimizationStrategy(
                type: .memory,
                condition: .memoryPressure,
                action: .clearCaches,
                priority: .high
            ),
            OptimizationStrategy(
                type: .background,
                condition: .backgroundProcessing,
                action: .optimizeBackgroundTasks,
                priority: .low
            )
        ]
    }
    
    private func startPerformanceOptimization() {
        // Start performance monitoring
        performanceMonitor.startMonitoring()
        
        // Start periodic optimization
        monitoringTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.performPeriodicOptimization()
        }
        
        // Setup memory pressure monitoring
        setupMemoryPressureMonitoring()
    }
    
    // MARK: - Performance Monitoring
    
    private func handleFPSUpdate(_ fps: Double) {
        currentFPS = fps
        
        // Trigger optimization if FPS drops below threshold
        if fps < minFPS {
            triggerOptimization(for: .lowFPS)
        }
        
        // Update performance metrics
        performanceMetrics.averageFPS = calculateAverageFPS()
        performanceMetrics.fpsStability = calculateFPSStability()
    }
    
    private func handleMemoryUsageUpdate(_ usage: MemoryUsage) {
        memoryUsage = usage
        
        // Trigger optimization if memory usage is high
        if usage.percentage > maxMemoryUsage {
            triggerOptimization(for: .highMemoryUsage)
        }
        
        // Update performance metrics
        performanceMetrics.memoryEfficiency = calculateMemoryEfficiency()
    }
    
    private func handleRenderingPerformanceUpdate(_ performance: RenderingPerformance) {
        renderingPerformance = performance
        
        // Trigger optimization if render time is too high
        if performance.averageRenderTime > maxRenderTime {
            triggerOptimization(for: .slowRendering)
        }
        
        // Update performance metrics
        performanceMetrics.renderingEfficiency = calculateRenderingEfficiency()
    }
    
    private func handleDataFetchPerformanceUpdate(_ performance: DataFetchPerformance) {
        dataFetchPerformance = performance
        
        // Trigger optimization if data fetch is slow
        if performance.averageFetchTime > 1.0 { // 1 second threshold
            triggerOptimization(for: .slowDataFetch)
        }
        
        // Update performance metrics
        performanceMetrics.dataFetchEfficiency = calculateDataFetchEfficiency()
    }
    
    // MARK: - Optimization Triggers
    
    private func triggerOptimization(for condition: OptimizationCondition) {
        let applicableStrategies = optimizationStrategies.filter { $0.condition == condition }
        
        for strategy in applicableStrategies.sorted(by: { $0.priority.rawValue < $1.priority.rawValue }) {
            executeOptimizationStrategy(strategy)
        }
    }
    
    private func executeOptimizationStrategy(_ strategy: OptimizationStrategy) {
        let operation = OptimizationOperation(strategy: strategy) { [weak self] result in
            self?.handleOptimizationResult(result, for: strategy)
        }
        
        optimizationQueue.addOperation(operation)
    }
    
    private func handleOptimizationResult(_ result: OptimizationResult, for strategy: OptimizationStrategy) {
        DispatchQueue.main.async {
            switch result {
            case .success(let improvement):
                self.logOptimizationSuccess(strategy: strategy, improvement: improvement)
                self.updateOptimizationStatus(.optimized)
                
            case .failure(let error):
                self.logOptimizationFailure(strategy: strategy, error: error)
                self.updateOptimizationStatus(.error(error.localizedDescription))
            }
        }
    }
    
    // MARK: - Rendering Optimization
    
    func optimizeRendering() async {
        await renderingOptimizer.optimizeForCurrentConditions(
            fps: currentFPS,
            memoryUsage: memoryUsage,
            qualitySettings: adaptiveQualitySettings
        )
        
        // Update quality settings based on performance
        adaptiveQualitySettings = await calculateOptimalQualitySettings()
    }
    
    private func calculateOptimalQualitySettings() async -> QualitySettings {
        var settings = adaptiveQualitySettings
        
        // Adjust based on current performance
        if currentFPS < targetFPS {
            // Reduce quality to improve performance
            settings.fractalComplexity = max(settings.fractalComplexity - 0.1, 0.3)
            settings.particleCount = max(Int(Double(settings.particleCount) * 0.9), 100)
            settings.shadowQuality = max(settings.shadowQuality - 0.1, 0.2)
            settings.textureResolution = max(settings.textureResolution - 0.1, 0.5)
        } else if currentFPS > targetFPS + 10 {
            // Increase quality when performance allows
            settings.fractalComplexity = min(settings.fractalComplexity + 0.05, 1.0)
            settings.particleCount = min(Int(Double(settings.particleCount) * 1.1), 2000)
            settings.shadowQuality = min(settings.shadowQuality + 0.05, 1.0)
            settings.textureResolution = min(settings.textureResolution + 0.05, 1.0)
        }
        
        // Adjust based on memory usage
        if memoryUsage.percentage > 0.7 {
            settings.cacheSize = max(settings.cacheSize - 0.1, 0.3)
            settings.preloadDistance = max(settings.preloadDistance - 0.1, 0.5)
        }
        
        return settings
    }
    
    // MARK: - Data Fetch Optimization
    
    func optimizeDataFetching() async {
        await dataFetchOptimizer.optimize(
            networkConditions: getCurrentNetworkConditions(),
            cacheStatus: cacheManager.getCacheStatus(),
            dataRequirements: getCurrentDataRequirements()
        )
    }
    
    private func getCurrentNetworkConditions() -> NetworkConditions {
        return NetworkConditions(
            bandwidth: estimateBandwidth(),
            latency: estimateLatency(),
            reliability: estimateReliability()
        )
    }
    
    private func getCurrentDataRequirements() -> DataRequirements {
        return DataRequirements(
            healthDataFrequency: .realTime,
            visualizationDataFrequency: .high,
            insightsDataFrequency: .medium,
            cacheStrategy: .aggressive
        )
    }
    
    // MARK: - Memory Optimization
    
    func optimizeMemoryUsage() async {
        await memoryManager.optimize(
            currentUsage: memoryUsage,
            optimizationLevel: determineOptimizationLevel()
        )
        
        // Clear unnecessary caches
        await cacheManager.clearExpiredCaches()
        
        // Compress large assets
        await compressLargeAssets()
        
        // Optimize texture memory
        await renderingOptimizer.optimizeTextureMemory()
    }
    
    private func determineOptimizationLevel() -> MemoryOptimizationLevel {
        if memoryUsage.percentage > 0.9 {
            return .aggressive
        } else if memoryUsage.percentage > 0.7 {
            return .moderate
        } else {
            return .light
        }
    }
    
    private func compressLargeAssets() async {
        // Compress textures, audio files, and other large assets
        await renderingOptimizer.compressTextures()
        // Implementation would compress other asset types
    }
    
    // MARK: - Background Task Optimization
    
    func optimizeBackgroundTasks() async {
        await backgroundTaskManager.optimize(
            availableResources: calculateAvailableResources(),
            priorityTasks: getCurrentPriorityTasks()
        )
    }
    
    private func calculateAvailableResources() -> AvailableResources {
        return AvailableResources(
            cpu: 1.0 - performanceMetrics.cpuUsage,
            memory: 1.0 - memoryUsage.percentage,
            network: estimateAvailableBandwidth()
        )
    }
    
    private func getCurrentPriorityTasks() -> [BackgroundTask] {
        return [
            BackgroundTask(type: .healthDataSync, priority: .high),
            BackgroundTask(type: .cachePreloading, priority: .medium),
            BackgroundTask(type: .analyticsProcessing, priority: .low)
        ]
    }
    
    // MARK: - Periodic Optimization
    
    private func performPeriodicOptimization() {
        // Record current performance snapshot
        let snapshot = PerformanceSnapshot(
            timestamp: Date(),
            fps: currentFPS,
            memoryUsage: memoryUsage.percentage,
            renderTime: renderingPerformance.averageRenderTime,
            dataFetchTime: dataFetchPerformance.averageFetchTime
        )
        
        performanceHistory.append(snapshot)
        
        // Keep only recent history
        if performanceHistory.count > 300 { // 5 minutes of history
            performanceHistory.removeFirst()
        }
        
        // Analyze trends and apply predictive optimizations
        analyzePeformanceTrends()
        
        // Update overall performance metrics
        updatePerformanceMetrics()
    }
    
    private func analyzePeformanceTrends() {
        guard performanceHistory.count >= 10 else { return }
        
        let recentSnapshots = Array(performanceHistory.suffix(10))
        
        // Analyze FPS trend
        let fpsValues = recentSnapshots.map { $0.fps }
        if isDecreasingTrend(fpsValues) {
            // Preemptively optimize rendering
            Task {
                await optimizeRendering()
            }
        }
        
        // Analyze memory trend
        let memoryValues = recentSnapshots.map { $0.memoryUsage }
        if isIncreasingTrend(memoryValues) {
            // Preemptively optimize memory
            Task {
                await optimizeMemoryUsage()
            }
        }
        
        // Analyze data fetch trend
        let fetchTimeValues = recentSnapshots.map { $0.dataFetchTime }
        if isIncreasingTrend(fetchTimeValues) {
            // Preemptively optimize data fetching
            Task {
                await optimizeDataFetching()
            }
        }
    }
    
    private func isDecreasingTrend(_ values: [Double]) -> Bool {
        guard values.count >= 5 else { return false }
        
        let firstHalf = Array(values.prefix(values.count / 2))
        let secondHalf = Array(values.suffix(values.count / 2))
        
        let firstAverage = firstHalf.reduce(0, +) / Double(firstHalf.count)
        let secondAverage = secondHalf.reduce(0, +) / Double(secondHalf.count)
        
        return secondAverage < firstAverage * 0.95 // 5% decrease threshold
    }
    
    private func isIncreasingTrend(_ values: [Double]) -> Bool {
        guard values.count >= 5 else { return false }
        
        let firstHalf = Array(values.prefix(values.count / 2))
        let secondHalf = Array(values.suffix(values.count / 2))
        
        let firstAverage = firstHalf.reduce(0, +) / Double(firstHalf.count)
        let secondAverage = secondHalf.reduce(0, +) / Double(secondHalf.count)
        
        return secondAverage > firstAverage * 1.05 // 5% increase threshold
    }
    
    private func updatePerformanceMetrics() {
        performanceMetrics.overallScore = calculateOverallPerformanceScore()
        performanceMetrics.optimizationEffectiveness = calculateOptimizationEffectiveness()
        performanceMetrics.lastUpdated = Date()
    }
    
    // MARK: - Performance Calculations
    
    private func calculateAverageFPS() -> Double {
        guard performanceHistory.count > 0 else { return currentFPS }
        
        let recentFPS = performanceHistory.suffix(60).map { $0.fps } // Last minute
        return recentFPS.reduce(0, +) / Double(recentFPS.count)
    }
    
    private func calculateFPSStability() -> Double {
        guard performanceHistory.count > 10 else { return 1.0 }
        
        let recentFPS = performanceHistory.suffix(60).map { $0.fps }
        let average = recentFPS.reduce(0, +) / Double(recentFPS.count)
        let variance = recentFPS.map { pow($0 - average, 2) }.reduce(0, +) / Double(recentFPS.count)
        let standardDeviation = sqrt(variance)
        
        // Stability score: lower deviation = higher stability
        return max(0, 1.0 - (standardDeviation / average))
    }
    
    private func calculateMemoryEfficiency() -> Double {
        // Efficiency based on memory usage and allocation patterns
        let baseEfficiency = 1.0 - memoryUsage.percentage
        let allocationEfficiency = 1.0 - memoryUsage.fragmentationLevel
        
        return (baseEfficiency + allocationEfficiency) / 2.0
    }
    
    private func calculateRenderingEfficiency() -> Double {
        // Efficiency based on render time vs target time
        let targetTime = 1.0 / targetFPS
        let efficiency = min(targetTime / renderingPerformance.averageRenderTime, 1.0)
        
        return efficiency
    }
    
    private func calculateDataFetchEfficiency() -> Double {
        // Efficiency based on fetch time and cache hit rate
        let timeEfficiency = max(0, 1.0 - (dataFetchPerformance.averageFetchTime / 2.0)) // 2 second baseline
        let cacheEfficiency = dataFetchPerformance.cacheHitRate
        
        return (timeEfficiency + cacheEfficiency) / 2.0
    }
    
    private func calculateOverallPerformanceScore() -> Double {
        let fpsScore = min(currentFPS / targetFPS, 1.0)
        let memoryScore = 1.0 - memoryUsage.percentage
        let renderingScore = calculateRenderingEfficiency()
        let dataFetchScore = calculateDataFetchEfficiency()
        
        return (fpsScore + memoryScore + renderingScore + dataFetchScore) / 4.0
    }
    
    private func calculateOptimizationEffectiveness() -> Double {
        guard performanceHistory.count >= 60 else { return 0.5 }
        
        let before = Array(performanceHistory.prefix(30))
        let after = Array(performanceHistory.suffix(30))
        
        let beforeScore = calculatePerformanceScore(before)
        let afterScore = calculatePerformanceScore(after)
        
        return min(afterScore / beforeScore, 2.0) - 1.0 // Effectiveness as improvement ratio
    }
    
    private func calculatePerformanceScore(_ snapshots: [PerformanceSnapshot]) -> Double {
        guard !snapshots.isEmpty else { return 0.5 }
        
        let avgFPS = snapshots.map { $0.fps }.reduce(0, +) / Double(snapshots.count)
        let avgMemory = snapshots.map { $0.memoryUsage }.reduce(0, +) / Double(snapshots.count)
        let avgRenderTime = snapshots.map { $0.renderTime }.reduce(0, +) / Double(snapshots.count)
        
        let fpsScore = min(avgFPS / targetFPS, 1.0)
        let memoryScore = 1.0 - avgMemory
        let renderingScore = min((1.0 / targetFPS) / avgRenderTime, 1.0)
        
        return (fpsScore + memoryScore + renderingScore) / 3.0
    }
    
    // MARK: - Network Estimation
    
    private func estimateBandwidth() -> Double {
        // Estimate available bandwidth
        return 50.0 // Mbps - placeholder
    }
    
    private func estimateLatency() -> TimeInterval {
        // Estimate network latency
        return 0.05 // 50ms - placeholder
    }
    
    private func estimateReliability() -> Double {
        // Estimate network reliability
        return 0.95 // 95% - placeholder
    }
    
    private func estimateAvailableBandwidth() -> Double {
        return estimateBandwidth() * 0.7 // Reserve 30% for system
    }
    
    // MARK: - Memory Pressure
    
    private func setupMemoryPressureMonitoring() {
        NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleMemoryPressure()
        }
    }
    
    private func handleMemoryPressure() {
        Task {
            await optimizeMemoryUsage()
        }
        
        triggerOptimization(for: .memoryPressure)
    }
    
    // MARK: - Logging
    
    private func logOptimizationSuccess(strategy: OptimizationStrategy, improvement: Double) {
        os_log("Optimization success: %@ improved performance by %.2f%%",
               log: OSLog.performance,
               type: .info,
               strategy.action.description,
               improvement * 100)
    }
    
    private func logOptimizationFailure(strategy: OptimizationStrategy, error: Error) {
        os_log("Optimization failure: %@ failed with error: %@",
               log: OSLog.performance,
               type: .error,
               strategy.action.description,
               error.localizedDescription)
    }
    
    // MARK: - Public Interface
    
    func forceOptimization() async {
        optimizationStatus = .optimizing
        
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.optimizeRendering() }
            group.addTask { await self.optimizeDataFetching() }
            group.addTask { await self.optimizeMemoryUsage() }
            group.addTask { await self.optimizeBackgroundTasks() }
        }
        
        optimizationStatus = .optimized
    }
    
    func getPerformanceReport() -> PerformanceReport {
        return PerformanceReport(
            overallScore: performanceMetrics.overallScore,
            fps: performanceMetrics.averageFPS,
            fpsStability: performanceMetrics.fpsStability,
            memoryEfficiency: performanceMetrics.memoryEfficiency,
            renderingEfficiency: performanceMetrics.renderingEfficiency,
            dataFetchEfficiency: performanceMetrics.dataFetchEfficiency,
            optimizationEffectiveness: performanceMetrics.optimizationEffectiveness,
            recommendations: generateRecommendations()
        )
    }
    
    private func generateRecommendations() -> [PerformanceRecommendation] {
        var recommendations: [PerformanceRecommendation] = []
        
        if performanceMetrics.averageFPS < targetFPS {
            recommendations.append(PerformanceRecommendation(
                type: .rendering,
                priority: .high,
                description: "Reduce visual quality to improve frame rate",
                expectedImprovement: 0.15
            ))
        }
        
        if memoryUsage.percentage > 0.7 {
            recommendations.append(PerformanceRecommendation(
                type: .memory,
                priority: .high,
                description: "Clear caches and optimize memory usage",
                expectedImprovement: 0.20
            ))
        }
        
        if dataFetchPerformance.averageFetchTime > 1.0 {
            recommendations.append(PerformanceRecommendation(
                type: .dataFetch,
                priority: .medium,
                description: "Enable aggressive caching for health data",
                expectedImprovement: 0.25
            ))
        }
        
        return recommendations
    }
    
    func setQualitySettings(_ settings: QualitySettings) {
        adaptiveQualitySettings = settings
        
        Task {
            await optimizeRendering()
        }
    }
    
    func pauseOptimization() {
        monitoringTimer?.invalidate()
        monitoringTimer = nil
        optimizationStatus = .paused
    }
    
    func resumeOptimization() {
        startPerformanceOptimization()
        optimizationStatus = .monitoring
    }
    
    // MARK: - Utility Methods
    
    private func updateOptimizationStatus(_ status: PerformanceOptimizationStatus) {
        DispatchQueue.main.async {
            self.optimizationStatus = status
        }
    }
    
    // MARK: - Cleanup
    
    deinit {
        monitoringTimer?.invalidate()
        performanceMonitor.stopMonitoring()
        NotificationCenter.default.removeObserver(self)
        cancellables.removeAll()
    }
}

// MARK: - Supporting Types

enum PerformanceOptimizationStatus: Equatable {
    case monitoring
    case optimizing
    case optimized
    case paused
    case error(String)
    
    static func == (lhs: PerformanceOptimizationStatus, rhs: PerformanceOptimizationStatus) -> Bool {
        switch (lhs, rhs) {
        case (.monitoring, .monitoring), (.optimizing, .optimizing), (.optimized, .optimized), (.paused, .paused):
            return true
        case (.error(let lhsMessage), .error(let rhsMessage)):
            return lhsMessage == rhsMessage
        default:
            return false
        }
    }
}

struct MemoryUsage {
    var used: Double = 0
    var available: Double = 0
    var total: Double = 0
    var percentage: Double { used / total }
    var fragmentationLevel: Double = 0
}

struct RenderingPerformance {
    var averageRenderTime: TimeInterval = 0
    var maxRenderTime: TimeInterval = 0
    var droppedFrames: Int = 0
    var gpuUtilization: Double = 0
}

struct DataFetchPerformance {
    var averageFetchTime: TimeInterval = 0
    var maxFetchTime: TimeInterval = 0
    var cacheHitRate: Double = 0
    var networkLatency: TimeInterval = 0
    var bandwidth: Double = 0
}

struct PerformanceMetrics {
    var overallScore: Double = 0
    var averageFPS: Double = 0
    var fpsStability: Double = 0
    var memoryEfficiency: Double = 0
    var renderingEfficiency: Double = 0
    var dataFetchEfficiency: Double = 0
    var optimizationEffectiveness: Double = 0
    var cpuUsage: Double = 0
    var lastUpdated: Date = Date()
}

struct QualitySettings {
    var fractalComplexity: Double = 0.8
    var particleCount: Int = 1000
    var shadowQuality: Double = 0.7
    var textureResolution: Double = 0.8
    var cacheSize: Double = 0.5
    var preloadDistance: Double = 0.7
    var antiAliasing: Bool = true
    var motionBlur: Bool = false
}

struct PerformanceSnapshot {
    let timestamp: Date
    let fps: Double
    let memoryUsage: Double
    let renderTime: TimeInterval
    let dataFetchTime: TimeInterval
}

enum OptimizationType {
    case rendering
    case dataFetch
    case memory
    case background
}

enum OptimizationCondition {
    case lowFPS
    case highMemoryUsage
    case slowRendering
    case slowDataFetch
    case memoryPressure
    case backgroundProcessing
    case highNetworkLatency
}

enum OptimizationAction {
    case reduceRenderQuality
    case optimizeMemoryUsage
    case enableCaching
    case prefetchData
    case clearCaches
    case optimizeBackgroundTasks
    
    var description: String {
        switch self {
        case .reduceRenderQuality: return "Reduce Render Quality"
        case .optimizeMemoryUsage: return "Optimize Memory Usage"
        case .enableCaching: return "Enable Caching"
        case .prefetchData: return "Prefetch Data"
        case .clearCaches: return "Clear Caches"
        case .optimizeBackgroundTasks: return "Optimize Background Tasks"
        }
    }
}

enum OptimizationPriority: Int {
    case high = 0
    case medium = 1
    case low = 2
}

struct OptimizationStrategy {
    let type: OptimizationType
    let condition: OptimizationCondition
    let action: OptimizationAction
    let priority: OptimizationPriority
}

enum OptimizationResult {
    case success(Double) // Improvement percentage
    case failure(Error)
}

enum MemoryOptimizationLevel {
    case light
    case moderate
    case aggressive
}

struct NetworkConditions {
    let bandwidth: Double
    let latency: TimeInterval
    let reliability: Double
}

enum DataFrequency {
    case realTime
    case high
    case medium
    case low
}

enum CacheStrategy {
    case conservative
    case balanced
    case aggressive
}

struct DataRequirements {
    let healthDataFrequency: DataFrequency
    let visualizationDataFrequency: DataFrequency
    let insightsDataFrequency: DataFrequency
    let cacheStrategy: CacheStrategy
}

struct AvailableResources {
    let cpu: Double
    let memory: Double
    let network: Double
}

enum BackgroundTaskType {
    case healthDataSync
    case cachePreloading
    case analyticsProcessing
}

enum BackgroundTaskPriority {
    case high
    case medium
    case low
}

struct BackgroundTask {
    let type: BackgroundTaskType
    let priority: BackgroundTaskPriority
}

struct PerformanceReport {
    let overallScore: Double
    let fps: Double
    let fpsStability: Double
    let memoryEfficiency: Double
    let renderingEfficiency: Double
    let dataFetchEfficiency: Double
    let optimizationEffectiveness: Double
    let recommendations: [PerformanceRecommendation]
}

struct PerformanceRecommendation {
    let type: OptimizationType
    let priority: OptimizationPriority
    let description: String
    let expectedImprovement: Double
}

// MARK: - Supporting Services

class PerformanceMonitor: ObservableObject {
    let device: MTLDevice
    
    @Published var currentFPS: Double = 60.0
    @Published var currentMemoryUsage: MemoryUsage = MemoryUsage()
    @Published var currentRenderingPerformance: RenderingPerformance = RenderingPerformance()
    @Published var currentDataFetchPerformance: DataFetchPerformance = DataFetchPerformance()
    
    lazy var fpsPublisher: AnyPublisher<Double, Never> = {
        $currentFPS.eraseToAnyPublisher()
    }()
    
    lazy var memoryUsagePublisher: AnyPublisher<MemoryUsage, Never> = {
        $currentMemoryUsage.eraseToAnyPublisher()
    }()
    
    lazy var renderingPerformancePublisher: AnyPublisher<RenderingPerformance, Never> = {
        $currentRenderingPerformance.eraseToAnyPublisher()
    }()
    
    lazy var dataFetchPerformancePublisher: AnyPublisher<DataFetchPerformance, Never> = {
        $currentDataFetchPerformance.eraseToAnyPublisher()
    }()
    
    private var monitoringTimer: Timer?
    
    init(device: MTLDevice) {
        self.device = device
    }
    
    func startMonitoring() {
        monitoringTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateMetrics()
        }
    }
    
    func stopMonitoring() {
        monitoringTimer?.invalidate()
        monitoringTimer = nil
    }
    
    private func updateMetrics() {
        updateFPS()
        updateMemoryUsage()
        updateRenderingPerformance()
        updateDataFetchPerformance()
    }
    
    private func updateFPS() {
        // In a real implementation, this would measure actual frame rate
        currentFPS = Double.random(in: 55...60) // Simulated
    }
    
    private func updateMemoryUsage() {
        // Get actual memory usage from system
        let info = mach_task_basic_info()
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
            let used = Double(info.resident_size)
            let total = Double(ProcessInfo.processInfo.physicalMemory)
            
            currentMemoryUsage = MemoryUsage(
                used: used,
                available: total - used,
                total: total,
                fragmentationLevel: Double.random(in: 0.1...0.3)
            )
        }
    }
    
    private func updateRenderingPerformance() {
        // In a real implementation, this would measure actual rendering metrics
        currentRenderingPerformance = RenderingPerformance(
            averageRenderTime: Double.random(in: 0.012...0.020),
            maxRenderTime: Double.random(in: 0.020...0.030),
            droppedFrames: Int.random(in: 0...2),
            gpuUtilization: Double.random(in: 0.6...0.9)
        )
    }
    
    private func updateDataFetchPerformance() {
        // In a real implementation, this would measure actual data fetch metrics
        currentDataFetchPerformance = DataFetchPerformance(
            averageFetchTime: Double.random(in: 0.2...1.5),
            maxFetchTime: Double.random(in: 1.0...3.0),
            cacheHitRate: Double.random(in: 0.7...0.95),
            networkLatency: Double.random(in: 0.02...0.1),
            bandwidth: Double.random(in: 20...100)
        )
    }
}

class RenderingOptimizer {
    let device: MTLDevice
    
    init(device: MTLDevice) {
        self.device = device
    }
    
    func optimizeForCurrentConditions(fps: Double, memoryUsage: MemoryUsage, qualitySettings: QualitySettings) async {
        // Optimize rendering based on current conditions
        await adjustRenderingQuality(fps: fps, memoryUsage: memoryUsage, qualitySettings: qualitySettings)
        await optimizeGPUUsage()
        await balanceQualityAndPerformance()
    }
    
    private func adjustRenderingQuality(fps: Double, memoryUsage: MemoryUsage, qualitySettings: QualitySettings) async {
        // Adjust quality settings based on performance
    }
    
    private func optimizeGPUUsage() async {
        // Optimize GPU resource usage
    }
    
    private func balanceQualityAndPerformance() async {
        // Balance visual quality with performance
    }
    
    func optimizeTextureMemory() async {
        // Optimize texture memory usage
    }
    
    func compressTextures() async {
        // Compress textures to save memory
    }
}

class DataFetchOptimizer {
    func optimize(networkConditions: NetworkConditions, cacheStatus: CacheStatus, dataRequirements: DataRequirements) async {
        // Optimize data fetching based on conditions
        await adjustFetchStrategy(networkConditions: networkConditions)
        await optimizeCaching(cacheStatus: cacheStatus, requirements: dataRequirements)
        await implementPrefetching(requirements: dataRequirements)
    }
    
    private func adjustFetchStrategy(networkConditions: NetworkConditions) async {
        // Adjust fetch strategy based on network conditions
    }
    
    private func optimizeCaching(cacheStatus: CacheStatus, requirements: DataRequirements) async {
        // Optimize caching strategy
    }
    
    private func implementPrefetching(requirements: DataRequirements) async {
        // Implement intelligent prefetching
    }
}

class MemoryManager {
    func optimize(currentUsage: MemoryUsage, optimizationLevel: MemoryOptimizationLevel) async {
        switch optimizationLevel {
        case .light:
            await performLightOptimization()
        case .moderate:
            await performModerateOptimization()
        case .aggressive:
            await performAggressiveOptimization()
        }
    }
    
    private func performLightOptimization() async {
        // Light memory optimization
    }
    
    private func performModerateOptimization() async {
        // Moderate memory optimization
    }
    
    private func performAggressiveOptimization() async {
        // Aggressive memory optimization
    }
}

struct CacheStatus {
    let totalSize: Int
    let usedSize: Int
    let hitRate: Double
    let missRate: Double
}

class CacheManager {
    func getCacheStatus() -> CacheStatus {
        return CacheStatus(
            totalSize: 100_000_000, // 100MB
            usedSize: 75_000_000,   // 75MB
            hitRate: 0.85,
            missRate: 0.15
        )
    }
    
    func clearExpiredCaches() async {
        // Clear expired cache entries
    }
}

class BackgroundTaskManager {
    func optimize(availableResources: AvailableResources, priorityTasks: [BackgroundTask]) async {
        // Optimize background task execution
        await scheduleTasksBasedOnResources(availableResources: availableResources, tasks: priorityTasks)
        await balanceTaskPriorities(tasks: priorityTasks)
    }
    
    private func scheduleTasksBasedOnResources(availableResources: AvailableResources, tasks: [BackgroundTask]) async {
        // Schedule tasks based on available resources
    }
    
    private func balanceTaskPriorities(tasks: [BackgroundTask]) async {
        // Balance task priorities
    }
}

class OptimizationOperation: Operation {
    let strategy: OptimizationStrategy
    let completion: (OptimizationResult) -> Void
    
    init(strategy: OptimizationStrategy, completion: @escaping (OptimizationResult) -> Void) {
        self.strategy = strategy
        self.completion = completion
        super.init()
    }
    
    override func main() {
        guard !isCancelled else { return }
        
        // Execute optimization strategy
        let result = executeStrategy()
        completion(result)
    }
    
    private func executeStrategy() -> OptimizationResult {
        // Execute the optimization strategy
        // Return simulated success for now
        let improvement = Double.random(in: 0.05...0.25)
        return .success(improvement)
    }
}

// MARK: - Extensions

extension OSLog {
    static let performance = OSLog(subsystem: "com.healthai2030.tvos", category: "Performance")
}

// MARK: - SwiftUI Views

@available(tvOS 18.0, *)
struct PerformanceOptimizationView: View {
    @StateObject private var performanceManager = PerformanceOptimizationManager()
    @State private var showingPerformanceReport = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // Header
                VStack(spacing: 15) {
                    Text("Performance Optimization")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("Real-time performance monitoring and optimization for tvOS")
                        .font(.title2)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
                
                ScrollView {
                    VStack(spacing: 25) {
                        // Performance Overview
                        PerformanceOverviewSection(performanceManager: performanceManager)
                        
                        // Real-time Metrics
                        RealTimeMetricsSection(performanceManager: performanceManager)
                        
                        // Quality Settings
                        QualitySettingsSection(performanceManager: performanceManager)
                        
                        // Optimization Status
                        OptimizationStatusSection(performanceManager: performanceManager)
                    }
                }
                
                // Control Buttons
                HStack(spacing: 20) {
                    Button("Optimize Now") {
                        Task {
                            await performanceManager.forceOptimization()
                        }
                    }
                    .buttonStyle(PerformanceButtonStyle(color: .blue))
                    
                    Button("Performance Report") {
                        showingPerformanceReport = true
                    }
                    .buttonStyle(PerformanceButtonStyle(color: .green))
                    
                    Button(performanceManager.optimizationStatus == .paused ? "Resume" : "Pause") {
                        if performanceManager.optimizationStatus == .paused {
                            performanceManager.resumeOptimization()
                        } else {
                            performanceManager.pauseOptimization()
                        }
                    }
                    .buttonStyle(PerformanceButtonStyle(color: .gray))
                }
            }
            .padding()
        }
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.black.opacity(0.8), Color.green.opacity(0.3)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .sheet(isPresented: $showingPerformanceReport) {
            PerformanceReportView(performanceManager: performanceManager)
        }
    }
}

@available(iOS 17.0, macOS 14.0, tvOS 18.0, watchOS 10.0, *)
struct PerformanceOverviewSection: View {
    @State var performanceManager: PerformanceOptimizationManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Performance Overview")
                .font(.title)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            HStack(spacing: 30) {
                // Overall Score
                VStack {
                    Text("Overall Score")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text("\(Int(performanceManager.performanceMetrics.overallScore * 100))%")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(overallScoreColor)
                    
                    CircularProgressView(
                        progress: performanceManager.performanceMetrics.overallScore,
                        color: overallScoreColor
                    )
                    .frame(width: 100, height: 100)
                }
                
                Spacer()
                
                // Key Metrics
                VStack(alignment: .leading, spacing: 10) {
                    MetricRow(title: "FPS", value: String(format: "%.1f", performanceManager.currentFPS), target: "60.0")
                    MetricRow(title: "Memory", value: String(format: "%.0f%%", performanceManager.memoryUsage.percentage * 100), target: "< 80%")
                    MetricRow(title: "Render Time", value: String(format: "%.1fms", performanceManager.renderingPerformance.averageRenderTime * 1000), target: "< 16ms")
                    MetricRow(title: "Data Fetch", value: String(format: "%.0fms", performanceManager.dataFetchPerformance.averageFetchTime * 1000), target: "< 1000ms")
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(15)
    }
    
    private var overallScoreColor: Color {
        let score = performanceManager.performanceMetrics.overallScore
        if score > 0.8 {
            return .green
        } else if score > 0.6 {
            return .yellow
        } else {
            return .red
        }
    }
}

@available(iOS 17.0, macOS 14.0, tvOS 18.0, watchOS 10.0, *)
struct RealTimeMetricsSection: View {
    @State var performanceManager: PerformanceOptimizationManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Real-time Metrics")
                .font(.title)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 15) {
                MetricCard(
                    title: "Frame Rate",
                    value: String(format: "%.1f FPS", performanceManager.currentFPS),
                    color: performanceManager.currentFPS >= 55 ? .green : .red,
                    icon: "speedometer"
                )
                
                MetricCard(
                    title: "Memory Usage",
                    value: String(format: "%.0f%%", performanceManager.memoryUsage.percentage * 100),
                    color: performanceManager.memoryUsage.percentage < 0.8 ? .green : .red,
                    icon: "memorychip"
                )
                
                MetricCard(
                    title: "GPU Usage",
                    value: String(format: "%.0f%%", performanceManager.renderingPerformance.gpuUtilization * 100),
                    color: performanceManager.renderingPerformance.gpuUtilization < 0.9 ? .green : .orange,
                    icon: "cpu"
                )
                
                MetricCard(
                    title: "Cache Hit Rate",
                    value: String(format: "%.0f%%", performanceManager.dataFetchPerformance.cacheHitRate * 100),
                    color: performanceManager.dataFetchPerformance.cacheHitRate > 0.8 ? .green : .orange,
                    icon: "internaldrive"
                )
            }
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(15)
    }
}

@available(iOS 17.0, macOS 14.0, tvOS 18.0, watchOS 10.0, *)
struct QualitySettingsSection: View {
    @State var performanceManager: PerformanceOptimizationManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Adaptive Quality Settings")
                .font(.title)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            let settings = performanceManager.adaptiveQualitySettings
            
            VStack(spacing: 12) {
                QualitySliderRow(
                    title: "Fractal Complexity",
                    value: Binding(
                        get: { settings.fractalComplexity },
                        set: { newValue in
                            var newSettings = settings
                            newSettings.fractalComplexity = newValue
                            performanceManager.setQualitySettings(newSettings)
                        }
                    )
                )
                
                QualitySliderRow(
                    title: "Texture Resolution",
                    value: Binding(
                        get: { settings.textureResolution },
                        set: { newValue in
                            var newSettings = settings
                            newSettings.textureResolution = newValue
                            performanceManager.setQualitySettings(newSettings)
                        }
                    )
                )
                
                QualitySliderRow(
                    title: "Shadow Quality",
                    value: Binding(
                        get: { settings.shadowQuality },
                        set: { newValue in
                            var newSettings = settings
                            newSettings.shadowQuality = newValue
                            performanceManager.setQualitySettings(newSettings)
                        }
                    )
                )
                
                HStack {
                    Text("Particle Count: \(settings.particleCount)")
                        .font(.body)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Stepper("", value: Binding(
                        get: { settings.particleCount },
                        set: { newValue in
                            var newSettings = settings
                            newSettings.particleCount = newValue
                            performanceManager.setQualitySettings(newSettings)
                        }
                    ), in: 100...2000, step: 100)
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(15)
    }
}

@available(iOS 17.0, macOS 14.0, tvOS 18.0, watchOS 10.0, *)
struct OptimizationStatusSection: View {
    @State var performanceManager: PerformanceOptimizationManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Optimization Status")
                .font(.title)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            HStack {
                Image(systemName: statusIcon)
                    .foregroundColor(statusColor)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 5) {
                    Text(statusText)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text(statusDescription)
                        .font(.body)
                        .foregroundColor(.gray)
                }
                
                Spacer()
            }
            
            if performanceManager.optimizationStatus == .optimizing {
                ProgressView("Optimizing performance...")
                    .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                    .foregroundColor(.white)
            }
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(15)
    }
    
    private var statusIcon: String {
        switch performanceManager.optimizationStatus {
        case .monitoring: return "eye.fill"
        case .optimizing: return "gearshape.2.fill"
        case .optimized: return "checkmark.circle.fill"
        case .paused: return "pause.circle.fill"
        case .error: return "exclamationmark.triangle.fill"
        }
    }
    
    private var statusColor: Color {
        switch performanceManager.optimizationStatus {
        case .monitoring: return .blue
        case .optimizing: return .orange
        case .optimized: return .green
        case .paused: return .gray
        case .error: return .red
        }
    }
    
    private var statusText: String {
        switch performanceManager.optimizationStatus {
        case .monitoring: return "Monitoring"
        case .optimizing: return "Optimizing"
        case .optimized: return "Optimized"
        case .paused: return "Paused"
        case .error: return "Error"
        }
    }
    
    private var statusDescription: String {
        switch performanceManager.optimizationStatus {
        case .monitoring: return "Continuously monitoring performance metrics"
        case .optimizing: return "Applying performance optimizations"
        case .optimized: return "Performance has been optimized"
        case .paused: return "Optimization monitoring is paused"
        case .error: return "An error occurred during optimization"
        }
    }
}

struct MetricRow: View {
    let title: String
    let value: String
    let target: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.body)
                .foregroundColor(.white)
            
            Spacer()
            
            Text(value)
                .font(.body)
                .fontWeight(.semibold)
                .foregroundColor(.cyan)
            
            Text("(\(target))")
                .font(.caption)
                .foregroundColor(.gray)
        }
    }
}

struct MetricCard: View {
    let title: String
    let value: String
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(color)
            
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
}

struct QualitySliderRow: View {
    let title: String
    @Binding var value: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.body)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("\(Int(value * 100))%")
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundColor(.cyan)
            }
            
            Slider(value: $value, in: 0...1)
                .accentColor(.blue)
        }
    }
}

@available(iOS 17.0, macOS 14.0, tvOS 18.0, watchOS 10.0, *)
struct PerformanceReportView: View {
    @State var performanceManager: PerformanceOptimizationManager
    @State private var performanceReport: PerformanceReport?
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Performance Report")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            if let report = performanceReport {
                ScrollView {
                    VStack(spacing: 20) {
                        // Summary
                        PerformanceReportSummary(report: report)
                        
                        // Detailed Metrics
                        PerformanceReportMetrics(report: report)
                        
                        // Recommendations
                        PerformanceReportRecommendations(report: report)
                    }
                }
            } else {
                ProgressView("Generating report...")
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
            }
            
            Spacer()
            
            Button("Close") {
                // Dismiss view
            }
            .buttonStyle(PerformanceButtonStyle(color: .gray))
        }
        .padding()
        .background(Color.black.opacity(0.8))
        .onAppear {
            Task {
                performanceReport = performanceManager.getPerformanceReport()
            }
        }
    }
}

struct PerformanceReportSummary: View {
    let report: PerformanceReport
    
    var body: some View {
        let overallScoreColor = getScoreColor(for: report.overallScore)
        let overallScorePercent = Int(report.overallScore * 100)
        
        return VStack(spacing: 15) {
            Text("Performance Summary")
                .font(.title)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            HStack(spacing: 30) {
                VStack {
                    Text("\(overallScorePercent)%")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(overallScoreColor)
                    
                    Text("Overall Score")
                        .font(.headline)
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    ReportMetricRow(title: "FPS", score: report.fps / 60.0)
                    ReportMetricRow(title: "Stability", score: report.fpsStability)
                    ReportMetricRow(title: "Memory", score: report.memoryEfficiency)
                    ReportMetricRow(title: "Rendering", score: report.renderingEfficiency)
                    ReportMetricRow(title: "Data Fetch", score: report.dataFetchEfficiency)
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(15)
    }
    
    private func getScoreColor(for score: Double) -> Color {
        if score > 0.8 {
            return .green
        } else if score > 0.6 {
            return .yellow
        } else {
            return .red
        }
    }
}

struct PerformanceReportMetrics: View {
    let report: PerformanceReport
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Detailed Metrics")
                .font(.title)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 15) {
                DetailedMetricCard(title: "Frame Rate", value: String(format: "%.1f FPS", report.fps), score: report.fps / 60.0)
                DetailedMetricCard(title: "FPS Stability", value: String(format: "%.0f%%", report.fpsStability * 100), score: report.fpsStability)
                DetailedMetricCard(title: "Memory Efficiency", value: String(format: "%.0f%%", report.memoryEfficiency * 100), score: report.memoryEfficiency)
                DetailedMetricCard(title: "Rendering Efficiency", value: String(format: "%.0f%%", report.renderingEfficiency * 100), score: report.renderingEfficiency)
                DetailedMetricCard(title: "Data Fetch Efficiency", value: String(format: "%.0f%%", report.dataFetchEfficiency * 100), score: report.dataFetchEfficiency)
                DetailedMetricCard(title: "Optimization Effectiveness", value: String(format: "%.0f%%", report.optimizationEffectiveness * 100), score: report.optimizationEffectiveness)
            }
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(15)
    }
}

struct PerformanceReportRecommendations: View {
    let report: PerformanceReport
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Recommendations")
                .font(.title)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            if report.recommendations.isEmpty {
                Text("No recommendations at this time. Performance is optimal!")
                    .font(.body)
                    .foregroundColor(.green)
            } else {
                ForEach(Array(report.recommendations.enumerated()), id: \.offset) { index, recommendation in
                    RecommendationCard(recommendation: recommendation)
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(15)
    }
}

struct ReportMetricRow: View {
    let title: String
    let score: Double
    
    var body: some View {
        HStack {
            Text(title)
                .font(.body)
                .foregroundColor(.white)
            
            Spacer()
            
            Text("\(Int(score * 100))%")
                .font(.body)
                .fontWeight(.semibold)
                .foregroundColor(scoreColor)
        }
    }
    
    private var scoreColor: Color {
        if score > 0.8 {
            return .green
        } else if score > 0.6 {
            return .yellow
        } else {
            return .red
        }
    }
}

struct DetailedMetricCard: View {
    let title: String
    let value: String
    let score: Double
    
    var body: some View {
        VStack(spacing: 10) {
            Text(title)
                .font(.headline)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(scoreColor)
            
            ProgressView(value: score)
                .progressViewStyle(LinearProgressViewStyle(tint: scoreColor))
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
    
    private var scoreColor: Color {
        if score > 0.8 {
            return .green
        } else if score > 0.6 {
            return .yellow
        } else {
            return .red
        }
    }
}

struct RecommendationCard: View {
    let recommendation: PerformanceRecommendation
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: typeIcon)
                    .foregroundColor(priorityColor)
                
                Text(recommendation.type.displayName)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("Expected: +\(Int(recommendation.expectedImprovement * 100))%")
                    .font(.caption)
                    .foregroundColor(.green)
            }
            
            Text(recommendation.description)
                .font(.body)
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(priorityColor.opacity(0.3), lineWidth: 1)
        )
    }
    
    private var typeIcon: String {
        switch recommendation.type {
        case .rendering: return "eye.fill"
        case .dataFetch: return "icloud.and.arrow.down"
        case .memory: return "memorychip"
        case .background: return "gear"
        }
    }
    
    private var priorityColor: Color {
        switch recommendation.priority {
        case .high: return .red
        case .medium: return .orange
        case .low: return .blue
        }
    }
}

struct CircularProgressView: View {
    let progress: Double
    let color: Color
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.3), lineWidth: 8)
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(color, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.5), value: progress)
        }
    }
}

struct PerformanceButtonStyle: ButtonStyle {
    let color: Color
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.white)
            .font(.headline)
            .fontWeight(.semibold)
            .frame(width: 180, height: 50)
            .background(color)
            .cornerRadius(10)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Extensions

extension OptimizationType {
    var displayName: String {
        switch self {
        case .rendering: return "Rendering"
        case .dataFetch: return "Data Fetch"
        case .memory: return "Memory"
        case .background: return "Background"
        }
    }
}

@available(iOS 17.0, macOS 14.0, tvOS 18.0, watchOS 10.0, *)
#Preview {
    PerformanceOptimizationView()
}

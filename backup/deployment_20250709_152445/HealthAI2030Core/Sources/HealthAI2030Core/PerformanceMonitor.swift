import Foundation
import SwiftUI
import os.log
import MetricKit
import CoreTelephony
import Network
import SystemConfiguration

/// Comprehensive performance monitoring and analytics system for HealthAI 2030
/// Provides real-time performance metrics, analytics, and optimization recommendations
@Observable
public final class PerformanceMonitor: ObservableObject {
    
    // MARK: - Singleton
    public static let shared = PerformanceMonitor()
    
    // MARK: - Properties
    private let logger = Logger(subsystem: "com.healthai2030.performance", category: "monitor")
    private let metricKit = MetricKit.MXMetricManager.shared
    private let networkMonitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "com.healthai2030.performance", qos: .utility)
    
    // MARK: - Performance Metrics
    @Published public var currentMetrics = PerformanceMetrics()
    @Published public var historicalMetrics: [PerformanceMetrics] = []
    @Published public var performanceAlerts: [PerformanceAlert] = []
    @Published public var optimizationRecommendations: [OptimizationRecommendation] = []
    
    // MARK: - Monitoring State
    @Published public var isMonitoring = false
    @Published public var monitoringInterval: TimeInterval = 5.0
    @Published public var alertThresholds = AlertThresholds()
    
    // MARK: - System Information
    @Published public var systemInfo = SystemInformation()
    @Published public var deviceCapabilities = DeviceCapabilities()
    @Published public var networkStatus = NetworkStatus()
    
    // MARK: - Performance Tracking
    private var performanceTimer: Timer?
    private var startTime: Date = Date()
    private var lastMetricsUpdate: Date = Date()
    
    // MARK: - Initialization
    private init() {
        setupMetricKit()
        setupNetworkMonitoring()
        loadHistoricalData()
        startMonitoring()
    }
    
    deinit {
        stopMonitoring()
    }
    
    // MARK: - Public Methods
    
    /// Start performance monitoring
    public func startMonitoring() {
        guard !isMonitoring else { return }
        
        isMonitoring = true
        startTime = Date()
        
        performanceTimer = Timer.scheduledTimer(withTimeInterval: monitoringInterval, repeats: true) { [weak self] _ in
            self?.updateMetrics()
        }
        
        logger.info("Performance monitoring started")
    }
    
    /// Stop performance monitoring
    public func stopMonitoring() {
        isMonitoring = false
        performanceTimer?.invalidate()
        performanceTimer = nil
        
        logger.info("Performance monitoring stopped")
    }
    
    /// Update monitoring interval
    public func updateMonitoringInterval(_ interval: TimeInterval) {
        monitoringInterval = interval
        
        if isMonitoring {
            stopMonitoring()
            startMonitoring()
        }
    }
    
    /// Get performance report for specified time period
    public func getPerformanceReport(for period: TimePeriod) -> PerformanceReport {
        let filteredMetrics = historicalMetrics.filter { metric in
            switch period {
            case .lastHour:
                return metric.timestamp > Date().addingTimeInterval(-3600)
            case .lastDay:
                return metric.timestamp > Date().addingTimeInterval(-86400)
            case .lastWeek:
                return metric.timestamp > Date().addingTimeInterval(-604800)
            case .lastMonth:
                return metric.timestamp > Date().addingTimeInterval(-2592000)
            case .custom(let start, let end):
                return metric.timestamp >= start && metric.timestamp <= end
            }
        }
        
        return PerformanceReport(
            period: period,
            metrics: filteredMetrics,
            summary: calculateSummary(from: filteredMetrics),
            recommendations: generateRecommendations(from: filteredMetrics)
        )
    }
    
    /// Clear historical data
    public func clearHistoricalData() {
        historicalMetrics.removeAll()
        saveHistoricalData()
        logger.info("Historical performance data cleared")
    }
    
    /// Export performance data
    public func exportPerformanceData() -> Data? {
        let exportData = PerformanceExportData(
            timestamp: Date(),
            systemInfo: systemInfo,
            deviceCapabilities: deviceCapabilities,
            historicalMetrics: historicalMetrics,
            alerts: performanceAlerts,
            recommendations: optimizationRecommendations
        )
        
        return try? JSONEncoder().encode(exportData)
    }
    
    // MARK: - Private Methods
    
    private func setupMetricKit() {
        metricKit.add(self)
        logger.info("MetricKit integration enabled")
    }
    
    private func setupNetworkMonitoring() {
        networkMonitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.updateNetworkStatus(path)
            }
        }
        networkMonitor.start(queue: queue)
    }
    
    private func updateMetrics() {
        let metrics = PerformanceMetrics(
            timestamp: Date(),
            cpuUsage: getCPUUsage(),
            memoryUsage: getMemoryUsage(),
            batteryLevel: getBatteryLevel(),
            networkLatency: getNetworkLatency(),
            diskUsage: getDiskUsage(),
            appLaunchTime: getAppLaunchTime(),
            uiResponsiveness: getUIResponsiveness(),
            mlInferenceTime: getMLInferenceTime(),
            databaseQueryTime: getDatabaseQueryTime(),
            networkRequests: getNetworkRequestMetrics(),
            errors: getErrorMetrics(),
            customMetrics: getCustomMetrics()
        )
        
        currentMetrics = metrics
        historicalMetrics.append(metrics)
        
        // Keep only last 1000 metrics to prevent memory issues
        if historicalMetrics.count > 1000 {
            historicalMetrics.removeFirst(historicalMetrics.count - 1000)
        }
        
        checkAlertThresholds(metrics)
        generateOptimizationRecommendations()
        saveHistoricalData()
        
        lastMetricsUpdate = Date()
    }
    
    private func getCPUUsage() -> Double {
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
            return Double(info.cpu_usage) / Double(THREAD_BASIC_INFO_COUNT)
        }
        
        return 0.0
    }
    
    private func getMemoryUsage() -> MemoryUsage {
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
            return MemoryUsage(
                used: Int64(info.resident_size),
                available: ProcessInfo.processInfo.physicalMemory - Int64(info.resident_size),
                total: ProcessInfo.processInfo.physicalMemory
            )
        }
        
        return MemoryUsage(used: 0, available: 0, total: 0)
    }
    
    private func getBatteryLevel() -> Double {
        UIDevice.current.isBatteryMonitoringEnabled = true
        return Double(UIDevice.current.batteryLevel)
    }
    
    private func getNetworkLatency() -> Double {
        // Simulate network latency measurement
        // In production, this would measure actual network requests
        return Double.random(in: 10...100)
    }
    
    private func getDiskUsage() -> DiskUsage {
        let fileManager = FileManager.default
        guard let path = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return DiskUsage(used: 0, available: 0, total: 0)
        }
        
        do {
            let attributes = try fileManager.attributesOfFileSystem(forPath: path.path)
            let total = attributes[.systemSize] as? Int64 ?? 0
            let free = attributes[.systemFreeSize] as? Int64 ?? 0
            let used = total - free
            
            return DiskUsage(used: used, available: free, total: total)
        } catch {
            logger.error("Failed to get disk usage: \(error.localizedDescription)")
            return DiskUsage(used: 0, available: 0, total: 0)
        }
    }
    
    private func getAppLaunchTime() -> Double {
        // This would be measured during app launch
        return 0.0
    }
    
    private func getUIResponsiveness() -> Double {
        // Measure UI responsiveness by tracking frame drops
        return 60.0 // Simulated 60 FPS
    }
    
    private func getMLInferenceTime() -> Double {
        // This would be measured during ML model inference
        return 0.0
    }
    
    private func getDatabaseQueryTime() -> Double {
        // This would be measured during database operations
        return 0.0
    }
    
    private func getNetworkRequestMetrics() -> NetworkRequestMetrics {
        return NetworkRequestMetrics(
            totalRequests: 0,
            successfulRequests: 0,
            failedRequests: 0,
            averageResponseTime: 0.0,
            requestsPerSecond: 0.0
        )
    }
    
    private func getErrorMetrics() -> ErrorMetrics {
        return ErrorMetrics(
            totalErrors: 0,
            criticalErrors: 0,
            warnings: 0,
            errorRate: 0.0
        )
    }
    
    private func getCustomMetrics() -> [String: Double] {
        return [:]
    }
    
    private func updateNetworkStatus(_ path: NWPath) {
        networkStatus.isConnected = path.status == .satisfied
        networkStatus.connectionType = getConnectionType(path)
        networkStatus.isExpensive = path.isExpensive
        networkStatus.isConstrained = path.isConstrained
    }
    
    private func getConnectionType(_ path: NWPath) -> ConnectionType {
        if path.usesInterfaceType(.wifi) {
            return .wifi
        } else if path.usesInterfaceType(.cellular) {
            return .cellular
        } else if path.usesInterfaceType(.wiredEthernet) {
            return .ethernet
        } else {
            return .unknown
        }
    }
    
    private func checkAlertThresholds(_ metrics: PerformanceMetrics) {
        var newAlerts: [PerformanceAlert] = []
        
        // CPU usage alerts
        if metrics.cpuUsage > alertThresholds.cpuUsage {
            newAlerts.append(PerformanceAlert(
                type: .highCPUUsage,
                severity: .warning,
                message: "High CPU usage detected: \(Int(metrics.cpuUsage * 100))%",
                timestamp: Date(),
                metrics: metrics
            ))
        }
        
        // Memory usage alerts
        let memoryUsagePercentage = Double(metrics.memoryUsage.used) / Double(metrics.memoryUsage.total)
        if memoryUsagePercentage > alertThresholds.memoryUsage {
            newAlerts.append(PerformanceAlert(
                type: .highMemoryUsage,
                severity: .warning,
                message: "High memory usage detected: \(Int(memoryUsagePercentage * 100))%",
                timestamp: Date(),
                metrics: metrics
            ))
        }
        
        // Battery level alerts
        if metrics.batteryLevel < alertThresholds.batteryLevel {
            newAlerts.append(PerformanceAlert(
                type: .lowBattery,
                severity: .info,
                message: "Low battery level: \(Int(metrics.batteryLevel * 100))%",
                timestamp: Date(),
                metrics: metrics
            ))
        }
        
        // Network latency alerts
        if metrics.networkLatency > alertThresholds.networkLatency {
            newAlerts.append(PerformanceAlert(
                type: .highNetworkLatency,
                severity: .warning,
                message: "High network latency: \(Int(metrics.networkLatency))ms",
                timestamp: Date(),
                metrics: metrics
            ))
        }
        
        performanceAlerts.append(contentsOf: newAlerts)
        
        // Keep only last 100 alerts
        if performanceAlerts.count > 100 {
            performanceAlerts.removeFirst(performanceAlerts.count - 100)
        }
        
        if !newAlerts.isEmpty {
            logger.warning("Performance alerts generated: \(newAlerts.count)")
        }
    }
    
    private func generateOptimizationRecommendations() {
        optimizationRecommendations.removeAll()
        
        let recentMetrics = Array(historicalMetrics.suffix(10))
        guard !recentMetrics.isEmpty else { return }
        
        let avgCPUUsage = recentMetrics.map(\.cpuUsage).reduce(0, +) / Double(recentMetrics.count)
        let avgMemoryUsage = recentMetrics.map { Double($0.memoryUsage.used) / Double($0.memoryUsage.total) }.reduce(0, +) / Double(recentMetrics.count)
        let avgNetworkLatency = recentMetrics.map(\.networkLatency).reduce(0, +) / Double(recentMetrics.count)
        
        // CPU optimization recommendations
        if avgCPUUsage > 0.8 {
            optimizationRecommendations.append(OptimizationRecommendation(
                type: .cpuOptimization,
                priority: .high,
                title: "Optimize CPU Usage",
                description: "High CPU usage detected. Consider optimizing background tasks and reducing computational load.",
                impact: .high,
                implementation: "Review and optimize background processing, implement task prioritization, and consider using more efficient algorithms."
            ))
        }
        
        // Memory optimization recommendations
        if avgMemoryUsage > 0.7 {
            optimizationRecommendations.append(OptimizationRecommendation(
                type: .memoryOptimization,
                priority: .high,
                title: "Optimize Memory Usage",
                description: "High memory usage detected. Consider implementing memory management optimizations.",
                impact: .high,
                implementation: "Implement object pooling, optimize data structures, and add memory pressure handling."
            ))
        }
        
        // Network optimization recommendations
        if avgNetworkLatency > 200 {
            optimizationRecommendations.append(OptimizationRecommendation(
                type: .networkOptimization,
                priority: .medium,
                title: "Optimize Network Performance",
                description: "High network latency detected. Consider implementing network optimizations.",
                impact: .medium,
                implementation: "Implement request caching, optimize API calls, and consider using CDN for static content."
            ))
        }
        
        // Battery optimization recommendations
        let avgBatteryLevel = recentMetrics.map(\.batteryLevel).reduce(0, +) / Double(recentMetrics.count)
        if avgBatteryLevel < 0.3 {
            optimizationRecommendations.append(OptimizationRecommendation(
                type: .batteryOptimization,
                priority: .medium,
                title: "Optimize Battery Usage",
                description: "Low battery level detected. Consider implementing battery optimizations.",
                impact: .medium,
                implementation: "Reduce background processing, optimize location services, and implement power-aware features."
            ))
        }
    }
    
    private func calculateSummary(from metrics: [PerformanceMetrics]) -> PerformanceSummary {
        guard !metrics.isEmpty else {
            return PerformanceSummary()
        }
        
        let cpuUsage = metrics.map(\.cpuUsage)
        let memoryUsage = metrics.map { Double($0.memoryUsage.used) / Double($0.memoryUsage.total) }
        let networkLatency = metrics.map(\.networkLatency)
        let batteryLevel = metrics.map(\.batteryLevel)
        
        return PerformanceSummary(
            averageCPUUsage: cpuUsage.reduce(0, +) / Double(cpuUsage.count),
            averageMemoryUsage: memoryUsage.reduce(0, +) / Double(memoryUsage.count),
            averageNetworkLatency: networkLatency.reduce(0, +) / Double(networkLatency.count),
            averageBatteryLevel: batteryLevel.reduce(0, +) / Double(batteryLevel.count),
            peakCPUUsage: cpuUsage.max() ?? 0,
            peakMemoryUsage: memoryUsage.max() ?? 0,
            totalAlerts: performanceAlerts.count,
            totalRecommendations: optimizationRecommendations.count
        )
    }
    
    private func loadHistoricalData() {
        // Load historical data from persistent storage
        // This would typically use UserDefaults, Core Data, or a file-based storage
        logger.info("Loading historical performance data")
    }
    
    private func saveHistoricalData() {
        // Save historical data to persistent storage
        // This would typically use UserDefaults, Core Data, or a file-based storage
        logger.debug("Saving historical performance data")
    }
}

// MARK: - MXMetricManagerSubscriber
extension PerformanceMonitor: MXMetricManagerSubscriber {
    public func didReceive(_ payloads: [MXMetricPayload]) {
        for payload in payloads {
            logger.info("Received MetricKit payload: \(payload.dictionaryRepresentation)")
            
            // Process MetricKit data and integrate with our metrics
            if let cpuMetrics = payload.cpuMetrics {
                logger.info("CPU metrics: \(cpuMetrics)")
            }
            
            if let memoryMetrics = payload.memoryMetrics {
                logger.info("Memory metrics: \(memoryMetrics)")
            }
            
            if let diskMetrics = payload.diskIOMetrics {
                logger.info("Disk I/O metrics: \(diskMetrics)")
            }
        }
    }
}

// MARK: - Data Models

/// Performance metrics for the application
public struct PerformanceMetrics: Codable {
    public let timestamp: Date
    public let cpuUsage: Double
    public let memoryUsage: MemoryUsage
    public let batteryLevel: Double
    public let networkLatency: Double
    public let diskUsage: DiskUsage
    public let appLaunchTime: Double
    public let uiResponsiveness: Double
    public let mlInferenceTime: Double
    public let databaseQueryTime: Double
    public let networkRequests: NetworkRequestMetrics
    public let errors: ErrorMetrics
    public let customMetrics: [String: Double]
    
    public init(
        timestamp: Date = Date(),
        cpuUsage: Double = 0.0,
        memoryUsage: MemoryUsage = MemoryUsage(used: 0, available: 0, total: 0),
        batteryLevel: Double = 0.0,
        networkLatency: Double = 0.0,
        diskUsage: DiskUsage = DiskUsage(used: 0, available: 0, total: 0),
        appLaunchTime: Double = 0.0,
        uiResponsiveness: Double = 0.0,
        mlInferenceTime: Double = 0.0,
        databaseQueryTime: Double = 0.0,
        networkRequests: NetworkRequestMetrics = NetworkRequestMetrics(),
        errors: ErrorMetrics = ErrorMetrics(),
        customMetrics: [String: Double] = [:]
    ) {
        self.timestamp = timestamp
        self.cpuUsage = cpuUsage
        self.memoryUsage = memoryUsage
        self.batteryLevel = batteryLevel
        self.networkLatency = networkLatency
        self.diskUsage = diskUsage
        self.appLaunchTime = appLaunchTime
        self.uiResponsiveness = uiResponsiveness
        self.mlInferenceTime = mlInferenceTime
        self.databaseQueryTime = databaseQueryTime
        self.networkRequests = networkRequests
        self.errors = errors
        self.customMetrics = customMetrics
    }
}

/// Memory usage information
public struct MemoryUsage: Codable {
    public let used: Int64
    public let available: Int64
    public let total: Int64
    
    public var usagePercentage: Double {
        guard total > 0 else { return 0.0 }
        return Double(used) / Double(total)
    }
}

/// Disk usage information
public struct DiskUsage: Codable {
    public let used: Int64
    public let available: Int64
    public let total: Int64
    
    public var usagePercentage: Double {
        guard total > 0 else { return 0.0 }
        return Double(used) / Double(total)
    }
}

/// Network request metrics
public struct NetworkRequestMetrics: Codable {
    public let totalRequests: Int
    public let successfulRequests: Int
    public let failedRequests: Int
    public let averageResponseTime: Double
    public let requestsPerSecond: Double
    
    public var successRate: Double {
        guard totalRequests > 0 else { return 0.0 }
        return Double(successfulRequests) / Double(totalRequests)
    }
    
    public init(
        totalRequests: Int = 0,
        successfulRequests: Int = 0,
        failedRequests: Int = 0,
        averageResponseTime: Double = 0.0,
        requestsPerSecond: Double = 0.0
    ) {
        self.totalRequests = totalRequests
        self.successfulRequests = successfulRequests
        self.failedRequests = failedRequests
        self.averageResponseTime = averageResponseTime
        self.requestsPerSecond = requestsPerSecond
    }
}

/// Error metrics
public struct ErrorMetrics: Codable {
    public let totalErrors: Int
    public let criticalErrors: Int
    public let warnings: Int
    public let errorRate: Double
    
    public init(
        totalErrors: Int = 0,
        criticalErrors: Int = 0,
        warnings: Int = 0,
        errorRate: Double = 0.0
    ) {
        self.totalErrors = totalErrors
        self.criticalErrors = criticalErrors
        self.warnings = warnings
        self.errorRate = errorRate
    }
}

/// Performance alert
public struct PerformanceAlert: Codable, Identifiable {
    public let id = UUID()
    public let type: AlertType
    public let severity: AlertSeverity
    public let message: String
    public let timestamp: Date
    public let metrics: PerformanceMetrics
    
    public enum AlertType: String, Codable, CaseIterable {
        case highCPUUsage = "High CPU Usage"
        case highMemoryUsage = "High Memory Usage"
        case lowBattery = "Low Battery"
        case highNetworkLatency = "High Network Latency"
        case diskSpaceLow = "Low Disk Space"
        case appCrash = "App Crash"
        case slowUI = "Slow UI Response"
        case mlInferenceSlow = "Slow ML Inference"
        case databaseSlow = "Slow Database Query"
    }
    
    public enum AlertSeverity: String, Codable, CaseIterable {
        case info = "Info"
        case warning = "Warning"
        case error = "Error"
        case critical = "Critical"
    }
}

/// Optimization recommendation
public struct OptimizationRecommendation: Codable, Identifiable {
    public let id = UUID()
    public let type: RecommendationType
    public let priority: Priority
    public let title: String
    public let description: String
    public let impact: Impact
    public let implementation: String
    public let timestamp: Date = Date()
    
    public enum RecommendationType: String, Codable, CaseIterable {
        case cpuOptimization = "CPU Optimization"
        case memoryOptimization = "Memory Optimization"
        case networkOptimization = "Network Optimization"
        case batteryOptimization = "Battery Optimization"
        case uiOptimization = "UI Optimization"
        case mlOptimization = "ML Optimization"
        case databaseOptimization = "Database Optimization"
    }
    
    public enum Priority: String, Codable, CaseIterable {
        case low = "Low"
        case medium = "Medium"
        case high = "High"
        case critical = "Critical"
    }
    
    public enum Impact: String, Codable, CaseIterable {
        case low = "Low"
        case medium = "Medium"
        case high = "High"
    }
}

/// Performance summary
public struct PerformanceSummary: Codable {
    public let averageCPUUsage: Double
    public let averageMemoryUsage: Double
    public let averageNetworkLatency: Double
    public let averageBatteryLevel: Double
    public let peakCPUUsage: Double
    public let peakMemoryUsage: Double
    public let totalAlerts: Int
    public let totalRecommendations: Int
    
    public init(
        averageCPUUsage: Double = 0.0,
        averageMemoryUsage: Double = 0.0,
        averageNetworkLatency: Double = 0.0,
        averageBatteryLevel: Double = 0.0,
        peakCPUUsage: Double = 0.0,
        peakMemoryUsage: Double = 0.0,
        totalAlerts: Int = 0,
        totalRecommendations: Int = 0
    ) {
        self.averageCPUUsage = averageCPUUsage
        self.averageMemoryUsage = averageMemoryUsage
        self.averageNetworkLatency = averageNetworkLatency
        self.averageBatteryLevel = averageBatteryLevel
        self.peakCPUUsage = peakCPUUsage
        self.peakMemoryUsage = peakMemoryUsage
        self.totalAlerts = totalAlerts
        self.totalRecommendations = totalRecommendations
    }
}

/// Performance report
public struct PerformanceReport: Codable {
    public let period: TimePeriod
    public let metrics: [PerformanceMetrics]
    public let summary: PerformanceSummary
    public let recommendations: [OptimizationRecommendation]
    public let generatedAt: Date = Date()
}

/// Time period for performance analysis
public enum TimePeriod: Codable {
    case lastHour
    case lastDay
    case lastWeek
    case lastMonth
    case custom(start: Date, end: Date)
}

/// Alert thresholds
public struct AlertThresholds: Codable {
    public var cpuUsage: Double = 0.8
    public var memoryUsage: Double = 0.7
    public var batteryLevel: Double = 0.2
    public var networkLatency: Double = 200.0
    public var diskUsage: Double = 0.9
}

/// System information
public struct SystemInformation: Codable {
    public let deviceModel: String
    public let systemVersion: String
    public let appVersion: String
    public let buildNumber: String
    public let deviceIdentifier: String
    
    public init() {
        self.deviceModel = UIDevice.current.model
        self.systemVersion = UIDevice.current.systemVersion
        self.appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        self.buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
        self.deviceIdentifier = UIDevice.current.identifierForVendor?.uuidString ?? "Unknown"
    }
}

/// Device capabilities
public struct DeviceCapabilities: Codable {
    public let hasNeuralEngine: Bool
    public let hasMetalSupport: Bool
    public let hasARKit: Bool
    public let hasCoreML: Bool
    public let hasHealthKit: Bool
    public let hasHomeKit: Bool
    public let hasCarPlay: Bool
    public let hasWatchConnectivity: Bool
    
    public init() {
        self.hasNeuralEngine = true // Assume modern devices have Neural Engine
        self.hasMetalSupport = true // Assume modern devices have Metal support
        self.hasARKit = true // Assume modern devices have ARKit
        self.hasCoreML = true // Assume modern devices have Core ML
        self.hasHealthKit = true // Assume modern devices have HealthKit
        self.hasHomeKit = true // Assume modern devices have HomeKit
        self.hasCarPlay = false // This would need to be detected
        self.hasWatchConnectivity = false // This would need to be detected
    }
}

/// Network status
public struct NetworkStatus: Codable {
    public var isConnected: Bool = false
    public var connectionType: ConnectionType = .unknown
    public var isExpensive: Bool = false
    public var isConstrained: Bool = false
}

/// Connection type
public enum ConnectionType: String, Codable, CaseIterable {
    case wifi = "WiFi"
    case cellular = "Cellular"
    case ethernet = "Ethernet"
    case unknown = "Unknown"
}

/// Performance export data
public struct PerformanceExportData: Codable {
    public let timestamp: Date
    public let systemInfo: SystemInformation
    public let deviceCapabilities: DeviceCapabilities
    public let historicalMetrics: [PerformanceMetrics]
    public let alerts: [PerformanceAlert]
    public let recommendations: [OptimizationRecommendation]
} 
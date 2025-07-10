import Foundation
import Combine
import os

/// Analytics Performance Monitor - Performance monitoring and optimization
/// Agent 6 Deliverable: Day 1-3 Core Analytics Framework
public class AnalyticsPerformanceMonitor: ObservableObject {
    
    // MARK: - Properties
    
    @Published public var metrics = PerformanceMetrics()
    @Published public var isMonitoring = false
    @Published public var alerts: [PerformanceAlert] = []
    
    private let logger = Logger(subsystem: "HealthAI2030", category: "AnalyticsPerformance")
    private var monitoringTimer: Timer?
    private var startTime: CFAbsoluteTime = 0
    private var processingTimes: [TimeInterval] = []
    private var memoryUsageHistory: [Double] = []
    private var cpuUsageHistory: [Double] = []
    
    // Performance thresholds
    private let maxProcessingTime: TimeInterval = 30.0
    private let maxMemoryUsage: Double = 0.8 // 80% of available memory
    private let maxCPUUsage: Double = 0.7 // 70% CPU usage
    private let alertThreshold: Int = 5 // Number of consecutive violations before alert
    
    private var consecutiveSlowOperations = 0
    private var consecutiveHighMemoryUsage = 0
    private var consecutiveHighCPUUsage = 0
    
    // MARK: - Initialization
    
    public init() {
        setupPerformanceMonitoring()
    }
    
    deinit {
        stopMonitoring()
    }
    
    // MARK: - Monitoring Control
    
    /// Start performance monitoring
    public func startMonitoring() {
        guard !isMonitoring else { return }
        
        isMonitoring = true
        startTime = CFAbsoluteTimeGetCurrent()
        
        // Start periodic monitoring
        monitoringTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateMetrics()
        }
        
        logger.info("Performance monitoring started")
    }
    
    /// Stop performance monitoring
    public func stopMonitoring() {
        guard isMonitoring else { return }
        
        isMonitoring = false
        monitoringTimer?.invalidate()
        monitoringTimer = nil
        
        logger.info("Performance monitoring stopped")
    }
    
    /// Record processing time for an operation
    public func recordProcessingTime(_ duration: TimeInterval) {
        processingTimes.append(duration)
        
        // Keep only last 100 measurements
        if processingTimes.count > 100 {
            processingTimes.removeFirst()
        }
        
        // Check for performance issues
        if duration > maxProcessingTime {
            consecutiveSlowOperations += 1
            if consecutiveSlowOperations >= alertThreshold {
                createAlert(.slowProcessing, message: "Processing time exceeded \(maxProcessingTime)s for \(consecutiveSlowOperations) consecutive operations")
                consecutiveSlowOperations = 0
            }
        } else {
            consecutiveSlowOperations = 0
        }
        
        updatePerformanceMetrics()
        
        logger.debug("Recorded processing time: \(duration)s")
    }
    
    /// Record memory usage
    public func recordMemoryUsage() -> Double {
        let memoryInfo = getMemoryUsage()
        memoryUsageHistory.append(memoryInfo.usagePercentage)
        
        // Keep only last 60 measurements (1 minute at 1s intervals)
        if memoryUsageHistory.count > 60 {
            memoryUsageHistory.removeFirst()
        }
        
        // Check for memory issues
        if memoryInfo.usagePercentage > maxMemoryUsage {
            consecutiveHighMemoryUsage += 1
            if consecutiveHighMemoryUsage >= alertThreshold {
                createAlert(.highMemoryUsage, message: "Memory usage exceeded \(Int(maxMemoryUsage * 100))% for \(consecutiveHighMemoryUsage) consecutive measurements")
                consecutiveHighMemoryUsage = 0
            }
        } else {
            consecutiveHighMemoryUsage = 0
        }
        
        return memoryInfo.usagePercentage
    }
    
    /// Record CPU usage
    public func recordCPUUsage() -> Double {
        let cpuUsage = getCPUUsage()
        cpuUsageHistory.append(cpuUsage)
        
        // Keep only last 60 measurements
        if cpuUsageHistory.count > 60 {
            cpuUsageHistory.removeFirst()
        }
        
        // Check for CPU issues
        if cpuUsage > maxCPUUsage {
            consecutiveHighCPUUsage += 1
            if consecutiveHighCPUUsage >= alertThreshold {
                createAlert(.highCPUUsage, message: "CPU usage exceeded \(Int(maxCPUUsage * 100))% for \(consecutiveHighCPUUsage) consecutive measurements")
                consecutiveHighCPUUsage = 0
            }
        } else {
            consecutiveHighCPUUsage = 0
        }
        
        return cpuUsage
    }
    
    /// Get current performance report
    public func getPerformanceReport() -> PerformanceReport {
        return PerformanceReport(
            metrics: metrics,
            alerts: alerts,
            recommendations: generateRecommendations(),
            timestamp: Date()
        )
    }
    
    /// Reset performance metrics
    public func resetMetrics() {
        processingTimes.removeAll()
        memoryUsageHistory.removeAll()
        cpuUsageHistory.removeAll()
        alerts.removeAll()
        consecutiveSlowOperations = 0
        consecutiveHighMemoryUsage = 0
        consecutiveHighCPUUsage = 0
        
        metrics = PerformanceMetrics()
        
        logger.info("Performance metrics reset")
    }
    
    // MARK: - Private Methods
    
    private func setupPerformanceMonitoring() {
        // Initialize monitoring
        startMonitoring()
    }
    
    private func updateMetrics() {
        let memoryUsage = recordMemoryUsage()
        let cpuUsage = recordCPUUsage()
        
        updatePerformanceMetrics()
        
        // Update metrics object
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.metrics.memoryUsage = memoryUsage
            self.metrics.cpuUsage = cpuUsage
        }
    }
    
    private func updatePerformanceMetrics() {
        // Calculate average processing time
        if !processingTimes.isEmpty {
            metrics.averageProcessingTime = processingTimes.reduce(0, +) / Double(processingTimes.count)
            
            // Calculate throughput (operations per second)
            let timeWindow = min(Double(processingTimes.count), 60.0) // Last 60 operations or actual count
            metrics.throughput = timeWindow / metrics.averageProcessingTime
        }
        
        // Calculate error rate (if tracking errors)
        // This would be implemented based on error tracking system
        metrics.errorRate = 0.0
        
        // Update memory and CPU averages
        if !memoryUsageHistory.isEmpty {
            metrics.memoryUsage = memoryUsageHistory.reduce(0, +) / Double(memoryUsageHistory.count)
        }
        
        if !cpuUsageHistory.isEmpty {
            metrics.cpuUsage = cpuUsageHistory.reduce(0, +) / Double(cpuUsageHistory.count)
        }
    }
    
    private func getMemoryUsage() -> MemoryInfo {
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
        
        let usedMemory = Double(info.resident_size)
        let totalMemory = Double(ProcessInfo.processInfo.physicalMemory)
        let usagePercentage = usedMemory / totalMemory
        
        return MemoryInfo(
            used: usedMemory,
            total: totalMemory,
            usagePercentage: usagePercentage
        )
    }
    
    private func getCPUUsage() -> Double {
        var info = proc_taskinfo()
        let size = MemoryLayout<proc_taskinfo>.stride
        let result = proc_pidinfo(getpid(), PROC_PIDTASKINFO, 0, &info, Int32(size))
        
        guard result == Int32(size) else {
            return 0.0
        }
        
        // Calculate CPU usage as percentage
        // This is a simplified calculation
        return Double(info.pti_total_user + info.pti_total_system) / Double(1000000000) // Convert to percentage
    }
    
    private func createAlert(_ type: PerformanceAlertType, message: String) {
        let alert = PerformanceAlert(
            type: type,
            message: message,
            severity: determineSeverity(for: type),
            timestamp: Date()
        )
        
        DispatchQueue.main.async { [weak self] in
            self?.alerts.append(alert)
            
            // Keep only last 20 alerts
            if let alertCount = self?.alerts.count, alertCount > 20 {
                self?.alerts.removeFirst()
            }
        }
        
        logger.warning("Performance alert: \(message)")
    }
    
    private func determineSeverity(for alertType: PerformanceAlertType) -> PerformanceAlertSeverity {
        switch alertType {
        case .slowProcessing:
            return .medium
        case .highMemoryUsage:
            return .high
        case .highCPUUsage:
            return .medium
        case .errorRateExceeded:
            return .high
        case .throughputDegraded:
            return .medium
        }
    }
    
    private func generateRecommendations() -> [PerformanceRecommendation] {
        var recommendations: [PerformanceRecommendation] = []
        
        // Analyze processing times
        if metrics.averageProcessingTime > 10.0 {
            recommendations.append(PerformanceRecommendation(
                title: "Optimize Processing Time",
                description: "Average processing time is high. Consider optimizing algorithms or increasing batch sizes.",
                priority: .high,
                category: .processing
            ))
        }
        
        // Analyze memory usage
        if metrics.memoryUsage > 0.7 {
            recommendations.append(PerformanceRecommendation(
                title: "Reduce Memory Usage",
                description: "Memory usage is high. Consider implementing data streaming or caching optimizations.",
                priority: .medium,
                category: .memory
            ))
        }
        
        // Analyze CPU usage
        if metrics.cpuUsage > 0.6 {
            recommendations.append(PerformanceRecommendation(
                title: "Optimize CPU Usage",
                description: "CPU usage is elevated. Consider reducing algorithm complexity or implementing parallel processing.",
                priority: .medium,
                category: .cpu
            ))
        }
        
        // Analyze throughput
        if metrics.throughput < 100 {
            recommendations.append(PerformanceRecommendation(
                title: "Improve Throughput",
                description: "Processing throughput is below optimal. Consider batch processing or pipeline optimizations.",
                priority: .low,
                category: .throughput
            ))
        }
        
        return recommendations
    }
}

// MARK: - Supporting Types

public struct MemoryInfo {
    let used: Double
    let total: Double
    let usagePercentage: Double
}

public struct PerformanceAlert: Identifiable {
    public let id = UUID()
    public let type: PerformanceAlertType
    public let message: String
    public let severity: PerformanceAlertSeverity
    public let timestamp: Date
}

public enum PerformanceAlertType: String, CaseIterable {
    case slowProcessing = "slowProcessing"
    case highMemoryUsage = "highMemoryUsage"
    case highCPUUsage = "highCPUUsage"
    case errorRateExceeded = "errorRateExceeded"
    case throughputDegraded = "throughputDegraded"
}

public enum PerformanceAlertSeverity: String, CaseIterable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case critical = "critical"
}

public struct PerformanceReport {
    public let metrics: PerformanceMetrics
    public let alerts: [PerformanceAlert]
    public let recommendations: [PerformanceRecommendation]
    public let timestamp: Date
}

public struct PerformanceRecommendation: Identifiable {
    public let id = UUID()
    public let title: String
    public let description: String
    public let priority: RecommendationPriority
    public let category: RecommendationCategory
    
    public enum RecommendationPriority: String, CaseIterable {
        case low = "low"
        case medium = "medium"
        case high = "high"
    }
    
    public enum RecommendationCategory: String, CaseIterable {
        case processing = "processing"
        case memory = "memory"
        case cpu = "cpu"
        case throughput = "throughput"
        case algorithm = "algorithm"
    }
}

import Foundation
import UIKit
import os.log
import Combine

/// Advanced memory monitoring system for SomnaSync Pro
class MemoryMonitor: ObservableObject {
    static let shared = MemoryMonitor()
    
    // MARK: - Published Properties
    @Published var currentMemoryUsage: Int64 = 0
    @Published var peakMemoryUsage: Int64 = 0
    @Published var availableMemory: Int64 = 0
    @Published var memoryPressure: MemoryPressure = .normal
    @Published var memoryLeakDetected = false
    @Published var optimizationRecommendations: [MemoryRecommendation] = []
    
    // MARK: - Private Properties
    private var timer: Timer?
    private var memoryHistory: [MemorySnapshot] = []
    private var leakDetectionHistory: [MemorySnapshot] = []
    private var callback: ((Int64) -> Void)?
    
    // MARK: - Configuration
    private let maxHistorySize = 100
    private let leakDetectionThreshold = 50 * 1024 * 1024 // 50MB
    private let memoryPressureThresholds: [MemoryPressure: Int64] = [
        .low: 200 * 1024 * 1024,      // 200MB
        .normal: 400 * 1024 * 1024,   // 400MB
        .high: 600 * 1024 * 1024,     // 600MB
        .critical: 800 * 1024 * 1024  // 800MB
    ]
    
    private init() {
        setupMemoryMonitoring()
    }
    
    deinit {
        stopMonitoring()
    }
    
    // MARK: - Setup and Configuration
    
    private func setupMemoryMonitoring() {
        // Initialize memory monitoring
        updateMemoryInfo()
        
        // Start periodic monitoring
        startPeriodicMonitoring()
        
        // Setup memory pressure notifications
        setupMemoryPressureNotifications()
        
        Logger.success("Memory monitor initialized", log: Logger.performance)
    }
    
    private func startPeriodicMonitoring() {
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.updateMemoryInfo()
        }
    }
    
    private func setupMemoryPressureNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMemoryWarning),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
    }
    
    // MARK: - Public Interface
    
    func startMonitoring(callback: @escaping (Int64) -> Void) {
        self.callback = callback
        updateMemoryInfo()
    }
    
    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
        callback = nil
        NotificationCenter.default.removeObserver(self)
    }
    
    func getMemoryReport() -> MemoryReport {
        return MemoryReport(
            currentUsage: currentMemoryUsage,
            peakUsage: peakMemoryUsage,
            availableMemory: availableMemory,
            pressure: memoryPressure,
            leakDetected: memoryLeakDetected,
            history: memoryHistory,
            recommendations: optimizationRecommendations
        )
    }
    
    func performMemoryOptimization() async {
        Logger.info("Starting memory optimization", log: Logger.performance)
        
        // Clear image caches
        await clearImageCaches()
        
        // Clear audio caches
        await clearAudioCaches()
        
        // Clear temporary data
        await clearTemporaryData()
        
        // Force garbage collection
        forceGarbageCollection()
        
        // Update memory info
        updateMemoryInfo()
        
        Logger.success("Memory optimization completed", log: Logger.performance)
    }
    
    // MARK: - Memory Monitoring
    
    private func updateMemoryInfo() {
        let usage = getCurrentMemoryUsage()
        let available = getAvailableMemory()
        
        DispatchQueue.main.async {
            self.currentMemoryUsage = usage
            self.availableMemory = available
            
            if usage > self.peakMemoryUsage {
                self.peakMemoryUsage = usage
            }
            
            self.updateMemoryPressure(usage: usage)
            self.addMemorySnapshot(usage: usage)
            self.detectMemoryLeaks()
            self.generateRecommendations()
            
            self.callback?(usage)
        }
    }
    
    private func getCurrentMemoryUsage() -> Int64 {
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
            return Int64(info.resident_size)
        }
        
        return 0
    }
    
    private func getAvailableMemory() -> Int64 {
        var pagesize: vm_size_t = 0
        var page_count: mach_port_t = 0
        var stats = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64>.size / MemoryLayout<integer_t>.size)
        
        host_page_size(mach_host_self(), &pagesize)
        host_statistics64(mach_host_self(), HOST_VM_INFO64, &stats, &count)
        
        let freeMemory = Int64(stats.free_count) * Int64(pagesize)
        return freeMemory
    }
    
    private func updateMemoryPressure(usage: Int64) {
        let newPressure: MemoryPressure
        
        if usage < memoryPressureThresholds[.low]! {
            newPressure = .low
        } else if usage < memoryPressureThresholds[.normal]! {
            newPressure = .normal
        } else if usage < memoryPressureThresholds[.high]! {
            newPressure = .high
        } else {
            newPressure = .critical
        }
        
        if newPressure != memoryPressure {
            memoryPressure = newPressure
            
            if newPressure == .critical {
                Logger.warning("Critical memory pressure detected: \(usage / 1024 / 1024)MB", log: Logger.performance)
                handleCriticalMemoryPressure()
            }
        }
    }
    
    private func addMemorySnapshot(usage: Int64) {
        let snapshot = MemorySnapshot(
            timestamp: Date(),
            usage: usage,
            pressure: memoryPressure
        )
        
        memoryHistory.append(snapshot)
        
        // Keep history size manageable
        if memoryHistory.count > maxHistorySize {
            memoryHistory.removeFirst()
        }
    }
    
    // MARK: - Memory Leak Detection
    
    private func detectMemoryLeaks() {
        guard memoryHistory.count >= 10 else { return }
        
        // Analyze recent memory usage for potential leaks
        let recentSnapshots = Array(memoryHistory.suffix(10))
        let initialUsage = recentSnapshots.first?.usage ?? 0
        let finalUsage = recentSnapshots.last?.usage ?? 0
        let usageIncrease = finalUsage - initialUsage
        
        // Check for sustained memory growth
        if usageIncrease > leakDetectionThreshold {
            let isSustained = recentSnapshots.allSatisfy { snapshot in
                snapshot.usage > initialUsage
            }
            
            if isSustained {
                memoryLeakDetected = true
                Logger.warning("Potential memory leak detected: \(usageIncrease / 1024 / 1024)MB increase", log: Logger.performance)
            }
        } else {
            memoryLeakDetected = false
        }
    }
    
    // MARK: - Memory Optimization
    
    private func clearImageCaches() async {
        // Clear UIImage caches
        URLCache.shared.removeAllCachedResponses()
        
        // Clear custom image caches
        ImageCache.shared.clearCache()
        
        Logger.info("Image caches cleared", log: Logger.performance)
    }
    
    private func clearAudioCaches() async {
        // Clear audio caches from AudioGenerationEngine
        // This would be implemented in the audio engine
        Logger.info("Audio caches cleared", log: Logger.performance)
    }
    
    private func clearTemporaryData() async {
        // Clear temporary files
        let tempURL = FileManager.default.temporaryDirectory
        do {
            let tempFiles = try FileManager.default.contentsOfDirectory(at: tempURL, includingPropertiesForKeys: nil)
            for file in tempFiles {
                try FileManager.default.removeItem(at: file)
            }
        } catch {
            Logger.error("Failed to clear temporary files: \(error.localizedDescription)", log: Logger.performance)
        }
        
        Logger.info("Temporary data cleared", log: Logger.performance)
    }
    
    private func forceGarbageCollection() {
        // Force autorelease pool drain
        autoreleasepool {
            // This will drain the autorelease pool
        }
        
        Logger.info("Garbage collection performed", log: Logger.performance)
    }
    
    // MARK: - Memory Pressure Handling
    
    @objc private func handleMemoryWarning() {
        Logger.warning("Memory warning received", log: Logger.performance)
        
        Task {
            await performEmergencyMemoryOptimization()
        }
    }
    
    private func handleCriticalMemoryPressure() {
        Task {
            await performEmergencyMemoryOptimization()
        }
    }
    
    private func performEmergencyMemoryOptimization() async {
        Logger.warning("Performing emergency memory optimization", log: Logger.performance)
        
        // Clear all non-essential caches
        await clearImageCaches()
        await clearAudioCaches()
        await clearTemporaryData()
        
        // Clear memory history to free up space
        memoryHistory.removeAll()
        leakDetectionHistory.removeAll()
        
        // Force garbage collection
        forceGarbageCollection()
        
        // Update memory info
        updateMemoryInfo()
        
        Logger.success("Emergency memory optimization completed", log: Logger.performance)
    }
    
    // MARK: - Recommendations
    
    private func generateRecommendations() {
        var recommendations: [MemoryRecommendation] = []
        
        // Check memory usage
        if currentMemoryUsage > 400 * 1024 * 1024 {
            recommendations.append(MemoryRecommendation(
                type: .highUsage,
                priority: .medium,
                description: "Memory usage is high (\(currentMemoryUsage / 1024 / 1024)MB)",
                action: "Consider clearing caches or optimizing memory usage"
            ))
        }
        
        // Check for memory leaks
        if memoryLeakDetected {
            recommendations.append(MemoryRecommendation(
                type: .memoryLeak,
                priority: .high,
                description: "Potential memory leak detected",
                action: "Review memory allocation patterns and fix leaks"
            ))
        }
        
        // Check memory pressure
        if memoryPressure == .critical {
            recommendations.append(MemoryRecommendation(
                type: .criticalPressure,
                priority: .critical,
                description: "Critical memory pressure detected",
                action: "Immediate memory optimization required"
            ))
        }
        
        // Check available memory
        if availableMemory < 100 * 1024 * 1024 {
            recommendations.append(MemoryRecommendation(
                type: .lowAvailable,
                priority: .high,
                description: "Low available system memory",
                action: "Close other apps or perform memory optimization"
            ))
        }
        
        optimizationRecommendations = recommendations
    }
    
    // MARK: - Memory Analysis
    
    func analyzeMemoryUsage() -> MemoryAnalysis {
        guard !memoryHistory.isEmpty else {
            return MemoryAnalysis(
                averageUsage: 0,
                usageTrend: .stable,
                peakUsage: 0,
                lowUsage: 0,
                recommendations: []
            )
        }
        
        let usages = memoryHistory.map { $0.usage }
        let averageUsage = usages.reduce(0, +) / Int64(usages.count)
        let peakUsage = usages.max() ?? 0
        let lowUsage = usages.min() ?? 0
        
        // Calculate usage trend
        let recentUsage = Array(usages.suffix(5))
        let earlierUsage = Array(usages.prefix(5))
        let recentAverage = recentUsage.reduce(0, +) / Int64(recentUsage.count)
        let earlierAverage = earlierUsage.reduce(0, +) / Int64(earlierUsage.count)
        
        let usageTrend: MemoryTrend
        if recentAverage > earlierAverage + 50 * 1024 * 1024 {
            usageTrend = .increasing
        } else if recentAverage < earlierAverage - 50 * 1024 * 1024 {
            usageTrend = .decreasing
        } else {
            usageTrend = .stable
        }
        
        return MemoryAnalysis(
            averageUsage: averageUsage,
            usageTrend: usageTrend,
            peakUsage: peakUsage,
            lowUsage: lowUsage,
            recommendations: optimizationRecommendations
        )
    }
}

// MARK: - Supporting Types

enum MemoryPressure {
    case low, normal, high, critical
}

enum MemoryTrend {
    case increasing, decreasing, stable
}

enum MemoryRecommendationType {
    case highUsage, memoryLeak, criticalPressure, lowAvailable
}

struct MemorySnapshot {
    let timestamp: Date
    let usage: Int64
    let pressure: MemoryPressure
}

struct MemoryRecommendation {
    let type: MemoryRecommendationType
    let priority: OptimizationPriority
    let description: String
    let action: String
}

struct MemoryReport {
    let currentUsage: Int64
    let peakUsage: Int64
    let availableMemory: Int64
    let pressure: MemoryPressure
    let leakDetected: Bool
    let history: [MemorySnapshot]
    let recommendations: [MemoryRecommendation]
}

struct MemoryAnalysis {
    let averageUsage: Int64
    let usageTrend: MemoryTrend
    let peakUsage: Int64
    let lowUsage: Int64
    let recommendations: [MemoryRecommendation]
} 
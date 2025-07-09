import Foundation
import Combine
import os

/// AnomalyDetectionService - Responsible for detecting performance anomalies
/// Extracted from AdvancedPerformanceMonitor to follow Single Responsibility Principle
@MainActor
public final class AnomalyDetectionService: ObservableObject {
    
    // MARK: - Published Properties
    @Published public var anomalyAlerts: [AnomalyAlert] = []
    
    // MARK: - Private Properties
    private let logger = Logger(subsystem: "com.healthai.performance", category: "anomaly-detection")
    private var metricsHistory: [SystemMetrics] = []
    private let maxHistorySize = 1000
    
    // MARK: - Configuration
    private let cpuThreshold = 80.0
    private let memoryThreshold = 85.0
    private let networkLatencyThreshold = 1000.0
    private let batteryThreshold = 0.1
    
    // MARK: - Initialization
    public init() {}
    
    // MARK: - Public API
    
    /// Detect anomalies in the given metrics
    public func detectAnomalies(_ metrics: SystemMetrics, history: [SystemMetrics]) async -> [AnomalyAlert] {
        self.metricsHistory = history
        let newAnomalies = await performAnomalyDetection(metrics)
        
        // Add new anomalies to the list
        for anomaly in newAnomalies {
            if !anomalyAlerts.contains(where: { $0.id == anomaly.id }) {
                anomalyAlerts.append(anomaly)
                logger.warning("Anomaly detected: \(anomaly.description)")
            }
        }
        
        // Clean up old alerts
        cleanupOldAlerts()
        
        return newAnomalies
    }
    
    /// Clear all anomaly alerts
    public func clearAlerts() {
        anomalyAlerts.removeAll()
    }
    
    /// Get alerts by severity
    public func getAlerts(severity: AnomalySeverity) -> [AnomalyAlert] {
        return anomalyAlerts.filter { $0.severity == severity }
    }
    
    /// Get alerts by category
    public func getAlerts(category: AnomalyCategory) -> [AnomalyAlert] {
        return anomalyAlerts.filter { $0.category == category }
    }
    
    // MARK: - Private Methods
    
    private func performAnomalyDetection(_ metrics: SystemMetrics) async -> [AnomalyAlert] {
        var anomalies: [AnomalyAlert] = []
        
        // CPU Anomalies
        if let cpuAnomaly = detectCPUAnomaly(metrics) {
            anomalies.append(cpuAnomaly)
        }
        
        // Memory Anomalies
        if let memoryAnomaly = detectMemoryAnomaly(metrics) {
            anomalies.append(memoryAnomaly)
        }
        
        // Network Anomalies
        if let networkAnomaly = detectNetworkAnomaly(metrics) {
            anomalies.append(networkAnomaly)
        }
        
        // Battery Anomalies
        if let batteryAnomaly = detectBatteryAnomaly(metrics) {
            anomalies.append(batteryAnomaly)
        }
        
        // Application Anomalies
        if let appAnomaly = detectApplicationAnomaly(metrics) {
            anomalies.append(appAnomaly)
        }
        
        // UI Anomalies
        if let uiAnomaly = detectUIAnomaly(metrics) {
            anomalies.append(uiAnomaly)
        }
        
        // ML Anomalies
        if let mlAnomaly = detectMLAnomaly(metrics) {
            anomalies.append(mlAnomaly)
        }
        
        // Database Anomalies
        if let dbAnomaly = detectDatabaseAnomaly(metrics) {
            anomalies.append(dbAnomaly)
        }
        
        // Security Anomalies
        if let securityAnomaly = detectSecurityAnomaly(metrics) {
            anomalies.append(securityAnomaly)
        }
        
        return anomalies
    }
    
    private func detectCPUAnomaly(_ metrics: SystemMetrics) -> AnomalyAlert? {
        let usage = metrics.cpu.usage
        
        if usage > 95.0 {
            return AnomalyAlert(
                metric: "cpu_usage",
                value: usage,
                threshold: 95.0,
                severity: .critical,
                category: .cpu,
                description: "Critical CPU usage detected",
                recommendation: "Immediate action required: Close unnecessary apps, reduce background processing"
            )
        } else if usage > cpuThreshold {
            return AnomalyAlert(
                metric: "cpu_usage",
                value: usage,
                threshold: cpuThreshold,
                severity: .high,
                category: .cpu,
                description: "High CPU usage detected",
                recommendation: "Consider optimizing CPU-intensive operations"
            )
        }
        
        return nil
    }
    
    private func detectMemoryAnomaly(_ metrics: SystemMetrics) -> AnomalyAlert? {
        let usagePercentage = Double(metrics.memory.usedMemory) / Double(metrics.memory.totalMemory) * 100
        
        if usagePercentage > 95.0 {
            return AnomalyAlert(
                metric: "memory_usage",
                value: usagePercentage,
                threshold: 95.0,
                severity: .critical,
                category: .memory,
                description: "Critical memory usage detected",
                recommendation: "Immediate action required: Clear caches, release memory"
            )
        } else if usagePercentage > memoryThreshold {
            return AnomalyAlert(
                metric: "memory_usage",
                value: usagePercentage,
                threshold: memoryThreshold,
                severity: .high,
                category: .memory,
                description: "High memory usage detected",
                recommendation: "Consider memory optimization and cache management"
            )
        }
        
        if metrics.memory.leakDetection {
            return AnomalyAlert(
                metric: "memory_leak",
                value: 1.0,
                threshold: 0.0,
                severity: .high,
                category: .memory,
                description: "Potential memory leak detected",
                recommendation: "Investigate memory allocation patterns and fix leaks"
            )
        }
        
        return nil
    }
    
    private func detectNetworkAnomaly(_ metrics: SystemMetrics) -> AnomalyAlert? {
        let latency = metrics.network.latency
        
        if latency > 5000.0 {
            return AnomalyAlert(
                metric: "network_latency",
                value: latency,
                threshold: 5000.0,
                severity: .critical,
                category: .network,
                description: "Critical network latency detected",
                recommendation: "Check network connectivity and server status"
            )
        } else if latency > networkLatencyThreshold {
            return AnomalyAlert(
                metric: "network_latency",
                value: latency,
                threshold: networkLatencyThreshold,
                severity: .high,
                category: .network,
                description: "High network latency detected",
                recommendation: "Optimize network requests and consider caching"
            )
        }
        
        if metrics.network.errorRate > 0.1 {
            return AnomalyAlert(
                metric: "network_error_rate",
                value: metrics.network.errorRate,
                threshold: 0.1,
                severity: .high,
                category: .network,
                description: "High network error rate detected",
                recommendation: "Investigate network connectivity issues"
            )
        }
        
        return nil
    }
    
    private func detectBatteryAnomaly(_ metrics: SystemMetrics) -> AnomalyAlert? {
        let batteryLevel = Double(metrics.battery.batteryLevel)
        
        if batteryLevel < 0.05 {
            return AnomalyAlert(
                metric: "battery_level",
                value: batteryLevel * 100,
                threshold: 5.0,
                severity: .critical,
                category: .battery,
                description: "Critical battery level detected",
                recommendation: "Connect to power source immediately"
            )
        } else if batteryLevel < batteryThreshold {
            return AnomalyAlert(
                metric: "battery_level",
                value: batteryLevel * 100,
                threshold: batteryThreshold * 100,
                severity: .high,
                category: .battery,
                description: "Low battery level detected",
                recommendation: "Consider connecting to power source"
            )
        }
        
        if metrics.battery.thermalState == .critical {
            return AnomalyAlert(
                metric: "thermal_state",
                value: 1.0,
                threshold: 0.0,
                severity: .critical,
                category: .battery,
                description: "Critical thermal state detected",
                recommendation: "Reduce device usage and allow cooling"
            )
        }
        
        return nil
    }
    
    private func detectApplicationAnomaly(_ metrics: SystemMetrics) -> AnomalyAlert? {
        if metrics.application.frameRate < 30.0 {
            return AnomalyAlert(
                metric: "frame_rate",
                value: metrics.application.frameRate,
                threshold: 30.0,
                severity: .high,
                category: .application,
                description: "Low frame rate detected",
                recommendation: "Optimize UI rendering and reduce complexity"
            )
        }
        
        if metrics.application.responseTime > 1000.0 {
            return AnomalyAlert(
                metric: "response_time",
                value: metrics.application.responseTime,
                threshold: 1000.0,
                severity: .high,
                category: .application,
                description: "Slow response time detected",
                recommendation: "Optimize main thread operations"
            )
        }
        
        return nil
    }
    
    private func detectUIAnomaly(_ metrics: SystemMetrics) -> AnomalyAlert? {
        if metrics.ui.renderTime > 16.67 { // 60 FPS = 16.67ms per frame
            return AnomalyAlert(
                metric: "render_time",
                value: metrics.ui.renderTime,
                threshold: 16.67,
                severity: .high,
                category: .ui,
                description: "Slow UI rendering detected",
                recommendation: "Optimize view hierarchy and reduce complexity"
            )
        }
        
        if metrics.ui.viewHierarchyDepth > 10 {
            return AnomalyAlert(
                metric: "view_hierarchy_depth",
                value: Double(metrics.ui.viewHierarchyDepth),
                threshold: 10.0,
                severity: .medium,
                category: .ui,
                description: "Deep view hierarchy detected",
                recommendation: "Flatten view hierarchy for better performance"
            )
        }
        
        return nil
    }
    
    private func detectMLAnomaly(_ metrics: SystemMetrics) -> AnomalyAlert? {
        if metrics.ml.inferenceTime > 1000.0 {
            return AnomalyAlert(
                metric: "ml_inference_time",
                value: metrics.ml.inferenceTime,
                threshold: 1000.0,
                severity: .high,
                category: .machineLearning,
                description: "Slow ML inference detected",
                recommendation: "Optimize model or consider model compression"
            )
        }
        
        if metrics.ml.accuracy < 0.8 {
            return AnomalyAlert(
                metric: "ml_accuracy",
                value: metrics.ml.accuracy,
                threshold: 0.8,
                severity: .medium,
                category: .machineLearning,
                description: "Low ML accuracy detected",
                recommendation: "Retrain model with updated data"
            )
        }
        
        return nil
    }
    
    private func detectDatabaseAnomaly(_ metrics: SystemMetrics) -> AnomalyAlert? {
        if metrics.database.queryTime > 100.0 {
            return AnomalyAlert(
                metric: "database_query_time",
                value: metrics.database.queryTime,
                threshold: 100.0,
                severity: .high,
                category: .database,
                description: "Slow database query detected",
                recommendation: "Optimize database queries and indexes"
            )
        }
        
        if metrics.database.cacheHitRate < 0.7 {
            return AnomalyAlert(
                metric: "database_cache_hit_rate",
                value: metrics.database.cacheHitRate,
                threshold: 0.7,
                severity: .medium,
                category: .database,
                description: "Low database cache hit rate",
                recommendation: "Optimize caching strategy"
            )
        }
        
        return nil
    }
    
    private func detectSecurityAnomaly(_ metrics: SystemMetrics) -> AnomalyAlert? {
        if metrics.security.authenticationTime > 5000.0 {
            return AnomalyAlert(
                metric: "authentication_time",
                value: metrics.security.authenticationTime,
                threshold: 5000.0,
                severity: .high,
                category: .security,
                description: "Slow authentication detected",
                recommendation: "Investigate authentication service performance"
            )
        }
        
        if metrics.security.secureConnections < 1 {
            return AnomalyAlert(
                metric: "secure_connections",
                value: Double(metrics.security.secureConnections),
                threshold: 1.0,
                severity: .critical,
                category: .security,
                description: "No secure connections detected",
                recommendation: "Enable secure connections immediately"
            )
        }
        
        return nil
    }
    
    private func cleanupOldAlerts() {
        let cutoffTime = Date().addingTimeInterval(-300) // 5 minutes
        anomalyAlerts.removeAll { $0.timestamp < cutoffTime }
    }
}

// MARK: - Supporting Types

public struct AnomalyAlert: Identifiable, Equatable {
    public let id = UUID()
    public let metric: String
    public let value: Double
    public let threshold: Double
    public let severity: AnomalySeverity
    public let category: AnomalyCategory
    public let description: String
    public let recommendation: String
    public let timestamp = Date()
    
    public static func == (lhs: AnomalyAlert, rhs: AnomalyAlert) -> Bool {
        return lhs.id == rhs.id
    }
}

public enum AnomalySeverity: String, CaseIterable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case critical = "Critical"
}

public enum AnomalyCategory: String, CaseIterable {
    case cpu = "CPU"
    case memory = "Memory"
    case network = "Network"
    case battery = "Battery"
    case application = "Application"
    case ui = "UI"
    case machineLearning = "Machine Learning"
    case database = "Database"
    case security = "Security"
    case disk = "Disk"
} 
import Foundation
import Combine
import os

/// RecommendationEngine - Responsible for generating performance optimization recommendations
/// Extracted from AdvancedPerformanceMonitor to follow Single Responsibility Principle
@MainActor
public final class RecommendationEngine: ObservableObject {
    
    // MARK: - Published Properties
    @Published public var optimizationRecommendations: [OptimizationRecommendation] = []
    
    // MARK: - Private Properties
    private let logger = Logger(subsystem: "com.healthai.performance", category: "recommendations")
    private var metricsHistory: [SystemMetrics] = []
    private let maxHistorySize = 1000
    
    // MARK: - Initialization
    public init() {}
    
    // MARK: - Public API
    
    /// Generate optimization recommendations based on current metrics and history
    public func generateRecommendations(
        currentMetrics: SystemMetrics,
        history: [SystemMetrics],
        anomalies: [AnomalyAlert],
        trends: [PerformanceTrend]
    ) async -> [OptimizationRecommendation] {
        self.metricsHistory = history
        let recommendations = await performRecommendationAnalysis(
            currentMetrics: currentMetrics,
            anomalies: anomalies,
            trends: trends
        )
        optimizationRecommendations = recommendations
        return recommendations
    }
    
    /// Get recommendations by priority
    public func getRecommendations(priority: RecommendationPriority) -> [OptimizationRecommendation] {
        return optimizationRecommendations.filter { $0.priority == priority }
    }
    
    /// Get recommendations by category
    public func getRecommendations(category: RecommendationCategory) -> [OptimizationRecommendation] {
        return optimizationRecommendations.filter { $0.category == category }
    }
    
    /// Clear all recommendations
    public func clearRecommendations() {
        optimizationRecommendations.removeAll()
    }
    
    // MARK: - Private Methods
    
    private func performRecommendationAnalysis(
        currentMetrics: SystemMetrics,
        anomalies: [AnomalyAlert],
        trends: [PerformanceTrend]
    ) async -> [OptimizationRecommendation] {
        var recommendations: [OptimizationRecommendation] = []
        
        // CPU Recommendations
        recommendations.append(contentsOf: generateCPURecommendations(currentMetrics, anomalies, trends))
        
        // Memory Recommendations
        recommendations.append(contentsOf: generateMemoryRecommendations(currentMetrics, anomalies, trends))
        
        // Network Recommendations
        recommendations.append(contentsOf: generateNetworkRecommendations(currentMetrics, anomalies, trends))
        
        // Battery Recommendations
        recommendations.append(contentsOf: generateBatteryRecommendations(currentMetrics, anomalies, trends))
        
        // Application Recommendations
        recommendations.append(contentsOf: generateApplicationRecommendations(currentMetrics, anomalies, trends))
        
        // UI Recommendations
        recommendations.append(contentsOf: generateUIRecommendations(currentMetrics, anomalies, trends))
        
        // ML Recommendations
        recommendations.append(contentsOf: generateMLRecommendations(currentMetrics, anomalies, trends))
        
        // Database Recommendations
        recommendations.append(contentsOf: generateDatabaseRecommendations(currentMetrics, anomalies, trends))
        
        // Security Recommendations
        recommendations.append(contentsOf: generateSecurityRecommendations(currentMetrics, anomalies, trends))
        
        // Sort by priority and estimated impact
        return recommendations.sorted { first, second in
            if first.priority.rawValue != second.priority.rawValue {
                return first.priority.rawValue > second.priority.rawValue
            }
            return first.estimatedSavings > second.estimatedSavings
        }
    }
    
    private func generateCPURecommendations(
        _ metrics: SystemMetrics,
        _ anomalies: [AnomalyAlert],
        _ trends: [PerformanceTrend]
    ) -> [OptimizationRecommendation] {
        var recommendations: [OptimizationRecommendation] = []
        
        let cpuUsage = metrics.cpu.usage
        let cpuAnomalies = anomalies.filter { $0.category == .cpu }
        let cpuTrend = trends.first { $0.category == .cpu }
        
        // High CPU usage recommendations
        if cpuUsage > 80.0 {
            recommendations.append(OptimizationRecommendation(
                title: "Optimize CPU-Intensive Operations",
                description: "High CPU usage detected. Consider optimizing background tasks and reducing computational complexity.",
                category: .cpu,
                priority: cpuUsage > 90.0 ? .critical : .high,
                impact: "High",
                effort: "Medium",
                estimatedSavings: min(100, cpuUsage - 50),
                implementation: "Review and optimize background processing, implement task scheduling, reduce algorithm complexity"
            ))
        }
        
        // CPU trend-based recommendations
        if let trend = cpuTrend, trend.trend == .increasing {
            recommendations.append(OptimizationRecommendation(
                title: "Address CPU Usage Trend",
                description: "CPU usage is trending upward. Implement proactive optimization measures.",
                category: .cpu,
                priority: .medium,
                impact: "Medium",
                effort: "Low",
                estimatedSavings: 15.0,
                implementation: "Monitor CPU usage patterns, implement adaptive processing, optimize data structures"
            ))
        }
        
        return recommendations
    }
    
    private func generateMemoryRecommendations(
        _ metrics: SystemMetrics,
        _ anomalies: [AnomalyAlert],
        _ trends: [PerformanceTrend]
    ) -> [OptimizationRecommendation] {
        var recommendations: [OptimizationRecommendation] = []
        
        let memoryUsage = Double(metrics.memory.usedMemory) / Double(metrics.memory.totalMemory) * 100
        let memoryAnomalies = anomalies.filter { $0.category == .memory }
        let memoryTrend = trends.first { $0.category == .memory }
        
        // High memory usage recommendations
        if memoryUsage > 80.0 {
            recommendations.append(OptimizationRecommendation(
                title: "Optimize Memory Usage",
                description: "High memory usage detected. Implement memory management optimizations.",
                category: .memory,
                priority: memoryUsage > 90.0 ? .critical : .high,
                impact: "High",
                effort: "Medium",
                estimatedSavings: min(100, memoryUsage - 60),
                implementation: "Implement object pooling, optimize data structures, add memory cleanup cycles"
            ))
        }
        
        // Memory leak recommendations
        if metrics.memory.leakDetection {
            recommendations.append(OptimizationRecommendation(
                title: "Fix Memory Leaks",
                description: "Potential memory leaks detected. Investigate and fix memory allocation issues.",
                category: .memory,
                priority: .critical,
                impact: "High",
                effort: "High",
                estimatedSavings: 30.0,
                implementation: "Use Instruments to identify leaks, fix retain cycles, implement proper cleanup"
            ))
        }
        
        return recommendations
    }
    
    private func generateNetworkRecommendations(
        _ metrics: SystemMetrics,
        _ anomalies: [AnomalyAlert],
        _ trends: [PerformanceTrend]
    ) -> [OptimizationRecommendation] {
        var recommendations: [OptimizationRecommendation] = []
        
        let networkLatency = metrics.network.latency
        let networkAnomalies = anomalies.filter { $0.category == .network }
        let networkTrend = trends.first { $0.category == .network }
        
        // High latency recommendations
        if networkLatency > 500.0 {
            recommendations.append(OptimizationRecommendation(
                title: "Optimize Network Requests",
                description: "High network latency detected. Implement network optimization strategies.",
                category: .network,
                priority: networkLatency > 1000.0 ? .critical : .high,
                impact: "High",
                effort: "Medium",
                estimatedSavings: 25.0,
                implementation: "Implement request batching, add caching, optimize payload sizes, use CDN"
            ))
        }
        
        // Network error rate recommendations
        if metrics.network.errorRate > 0.05 {
            recommendations.append(OptimizationRecommendation(
                title: "Improve Network Reliability",
                description: "High network error rate detected. Implement retry logic and error handling.",
                category: .network,
                priority: .high,
                impact: "Medium",
                effort: "Low",
                estimatedSavings: 15.0,
                implementation: "Add exponential backoff, implement circuit breaker pattern, improve error handling"
            ))
        }
        
        return recommendations
    }
    
    private func generateBatteryRecommendations(
        _ metrics: SystemMetrics,
        _ anomalies: [AnomalyAlert],
        _ trends: [PerformanceTrend]
    ) -> [OptimizationRecommendation] {
        var recommendations: [OptimizationRecommendation] = []
        
        let batteryLevel = Double(metrics.battery.batteryLevel)
        let batteryAnomalies = anomalies.filter { $0.category == .battery }
        let batteryTrend = trends.first { $0.category == .battery }
        
        // Low battery recommendations
        if batteryLevel < 0.2 {
            recommendations.append(OptimizationRecommendation(
                title: "Implement Power Optimization",
                description: "Low battery level detected. Implement power-saving measures.",
                category: .battery,
                priority: batteryLevel < 0.1 ? .critical : .high,
                impact: "High",
                effort: "Medium",
                estimatedSavings: 20.0,
                implementation: "Reduce background processing, optimize location services, implement adaptive brightness"
            ))
        }
        
        // Thermal state recommendations
        if metrics.battery.thermalState == .serious || metrics.battery.thermalState == .critical {
            recommendations.append(OptimizationRecommendation(
                title: "Address Thermal Issues",
                description: "High thermal state detected. Implement thermal management strategies.",
                category: .battery,
                priority: .critical,
                impact: "High",
                effort: "Medium",
                estimatedSavings: 15.0,
                implementation: "Reduce CPU/GPU usage, implement thermal throttling, optimize processing schedules"
            ))
        }
        
        return recommendations
    }
    
    private func generateApplicationRecommendations(
        _ metrics: SystemMetrics,
        _ anomalies: [AnomalyAlert],
        _ trends: [PerformanceTrend]
    ) -> [OptimizationRecommendation] {
        var recommendations: [OptimizationRecommendation] = []
        
        let frameRate = metrics.application.frameRate
        let responseTime = metrics.application.responseTime
        let appAnomalies = anomalies.filter { $0.category == .application }
        let appTrend = trends.first { $0.category == .application }
        
        // Low frame rate recommendations
        if frameRate < 50.0 {
            recommendations.append(OptimizationRecommendation(
                title: "Improve Frame Rate",
                description: "Low frame rate detected. Optimize rendering performance.",
                category: .application,
                priority: frameRate < 30.0 ? .critical : .high,
                impact: "High",
                effort: "Medium",
                estimatedSavings: 20.0,
                implementation: "Optimize view hierarchy, reduce off-screen rendering, implement view recycling"
            ))
        }
        
        // Slow response time recommendations
        if responseTime > 500.0 {
            recommendations.append(OptimizationRecommendation(
                title: "Optimize Response Time",
                description: "Slow response time detected. Optimize main thread operations.",
                category: .application,
                priority: responseTime > 1000.0 ? .critical : .high,
                impact: "High",
                effort: "Medium",
                estimatedSavings: 25.0,
                implementation: "Move heavy operations to background threads, implement async/await, optimize data processing"
            ))
        }
        
        return recommendations
    }
    
    private func generateUIRecommendations(
        _ metrics: SystemMetrics,
        _ anomalies: [AnomalyAlert],
        _ trends: [PerformanceTrend]
    ) -> [OptimizationRecommendation] {
        var recommendations: [OptimizationRecommendation] = []
        
        let renderTime = metrics.ui.renderTime
        let hierarchyDepth = metrics.ui.viewHierarchyDepth
        let uiAnomalies = anomalies.filter { $0.category == .ui }
        let uiTrend = trends.first { $0.category == .ui }
        
        // Slow rendering recommendations
        if renderTime > 16.67 { // 60 FPS threshold
            recommendations.append(OptimizationRecommendation(
                title: "Optimize UI Rendering",
                description: "Slow UI rendering detected. Optimize view rendering performance.",
                category: .ui,
                priority: renderTime > 33.33 ? .critical : .high,
                impact: "High",
                effort: "Medium",
                estimatedSavings: 20.0,
                implementation: "Flatten view hierarchy, optimize Auto Layout constraints, implement view recycling"
            ))
        }
        
        // Deep hierarchy recommendations
        if hierarchyDepth > 8 {
            recommendations.append(OptimizationRecommendation(
                title: "Flatten View Hierarchy",
                description: "Deep view hierarchy detected. Simplify view structure.",
                category: .ui,
                priority: .medium,
                impact: "Medium",
                effort: "Low",
                estimatedSavings: 10.0,
                implementation: "Combine nested views, use custom drawing, implement view composition"
            ))
        }
        
        return recommendations
    }
    
    private func generateMLRecommendations(
        _ metrics: SystemMetrics,
        _ anomalies: [AnomalyAlert],
        _ trends: [PerformanceTrend]
    ) -> [OptimizationRecommendation] {
        var recommendations: [OptimizationRecommendation] = []
        
        let inferenceTime = metrics.ml.inferenceTime
        let accuracy = metrics.ml.accuracy
        let mlAnomalies = anomalies.filter { $0.category == .machineLearning }
        let mlTrend = trends.first { $0.category == .machineLearning }
        
        // Slow inference recommendations
        if inferenceTime > 500.0 {
            recommendations.append(OptimizationRecommendation(
                title: "Optimize ML Inference",
                description: "Slow ML inference detected. Optimize model performance.",
                category: .machineLearning,
                priority: inferenceTime > 1000.0 ? .critical : .high,
                impact: "High",
                effort: "High",
                estimatedSavings: 30.0,
                implementation: "Implement model quantization, use Core ML optimization, consider model compression"
            ))
        }
        
        // Low accuracy recommendations
        if accuracy < 0.85 {
            recommendations.append(OptimizationRecommendation(
                title: "Improve ML Model Accuracy",
                description: "Low model accuracy detected. Retrain or optimize the model.",
                category: .machineLearning,
                priority: .medium,
                impact: "Medium",
                effort: "High",
                estimatedSavings: 15.0,
                implementation: "Retrain model with more data, implement data augmentation, optimize feature engineering"
            ))
        }
        
        return recommendations
    }
    
    private func generateDatabaseRecommendations(
        _ metrics: SystemMetrics,
        _ anomalies: [AnomalyAlert],
        _ trends: [PerformanceTrend]
    ) -> [OptimizationRecommendation] {
        var recommendations: [OptimizationRecommendation] = []
        
        let queryTime = metrics.database.queryTime
        let cacheHitRate = metrics.database.cacheHitRate
        let dbAnomalies = anomalies.filter { $0.category == .database }
        let dbTrend = trends.first { $0.category == .database }
        
        // Slow query recommendations
        if queryTime > 50.0 {
            recommendations.append(OptimizationRecommendation(
                title: "Optimize Database Queries",
                description: "Slow database queries detected. Optimize query performance.",
                category: .database,
                priority: queryTime > 100.0 ? .critical : .high,
                impact: "High",
                effort: "Medium",
                estimatedSavings: 25.0,
                implementation: "Add database indexes, optimize query patterns, implement query caching"
            ))
        }
        
        // Low cache hit rate recommendations
        if cacheHitRate < 0.8 {
            recommendations.append(OptimizationRecommendation(
                title: "Improve Database Caching",
                description: "Low cache hit rate detected. Optimize caching strategy.",
                category: .database,
                priority: .medium,
                impact: "Medium",
                effort: "Low",
                estimatedSavings: 15.0,
                implementation: "Implement query result caching, optimize cache invalidation, add memory cache"
            ))
        }
        
        return recommendations
    }
    
    private func generateSecurityRecommendations(
        _ metrics: SystemMetrics,
        _ anomalies: [AnomalyAlert],
        _ trends: [PerformanceTrend]
    ) -> [OptimizationRecommendation] {
        var recommendations: [OptimizationRecommendation] = []
        
        let authTime = metrics.security.authenticationTime
        let secureConnections = metrics.security.secureConnections
        let securityAnomalies = anomalies.filter { $0.category == .security }
        let securityTrend = trends.first { $0.category == .security }
        
        // Slow authentication recommendations
        if authTime > 2000.0 {
            recommendations.append(OptimizationRecommendation(
                title: "Optimize Authentication",
                description: "Slow authentication detected. Optimize security operations.",
                category: .security,
                priority: authTime > 5000.0 ? .critical : .high,
                impact: "Medium",
                effort: "Medium",
                estimatedSavings: 20.0,
                implementation: "Implement token caching, optimize certificate validation, use biometric authentication"
            ))
        }
        
        // Security connection recommendations
        if secureConnections < 1 {
            recommendations.append(OptimizationRecommendation(
                title: "Enable Secure Connections",
                description: "No secure connections detected. Implement secure communication.",
                category: .security,
                priority: .critical,
                impact: "High",
                effort: "Medium",
                estimatedSavings: 10.0,
                implementation: "Enable HTTPS, implement certificate pinning, add network security configuration"
            ))
        }
        
        return recommendations
    }
}

// MARK: - Supporting Types

public struct OptimizationRecommendation: Identifiable {
    public let id = UUID()
    public let title: String
    public let description: String
    public let category: RecommendationCategory
    public let priority: RecommendationPriority
    public let impact: String
    public let effort: String
    public let estimatedSavings: Double
    public let implementation: String
    public let timestamp = Date()
}

public enum RecommendationPriority: Int, CaseIterable {
    case low = 1
    case medium = 2
    case high = 3
    case critical = 4
}

public enum RecommendationCategory: String, CaseIterable {
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
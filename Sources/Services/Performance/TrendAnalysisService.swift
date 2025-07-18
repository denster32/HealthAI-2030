import Foundation
import Combine
import os

/// TrendAnalysisService - Responsible for analyzing performance trends over time
/// Extracted from AdvancedPerformanceMonitor to follow Single Responsibility Principle
@MainActor
public final class TrendAnalysisService: ObservableObject {
    
    // MARK: - Published Properties
    @Published public var performanceTrends: [PerformanceTrend] = []
    
    // MARK: - Private Properties
    private let logger = Logger(subsystem: "com.healthai.performance", category: "trend-analysis")
    private var metricsHistory: [SystemMetrics] = []
    private let minDataPoints = 5
    private let maxHistorySize = 1000
    
    // MARK: - Initialization
    public init() {}
    
    // MARK: - Public API
    
    /// Analyze trends from metrics history
    public func analyzeTrends(_ history: [SystemMetrics]) async -> [PerformanceTrend] {
        self.metricsHistory = history
        guard history.count >= minDataPoints else {
            logger.info("Insufficient data points for trend analysis: \(history.count)")
            return []
        }
        
        let trends = await performTrendAnalysis()
        performanceTrends = trends
        return trends
    }
    
    /// Get trend for specific metric
    public func getTrend(for metric: String) -> PerformanceTrend? {
        return performanceTrends.first { $0.metric == metric }
    }
    
    /// Get trends by category
    public func getTrends(category: TrendCategory) -> [PerformanceTrend] {
        return performanceTrends.filter { $0.category == category }
    }
    
    /// Get forecast for specific metric
    public func getForecast(for metric: String, timeSteps: Int = 5) -> [Double] {
        guard let trend = getTrend(for: metric) else { return [] }
        return calculateForecast(trend: trend, timeSteps: timeSteps)
    }
    
    // MARK: - Private Methods
    
    private func performTrendAnalysis() async -> [PerformanceTrend] {
        var trends: [PerformanceTrend] = []
        
        // CPU Trends
        if let cpuTrend = analyzeCPUTrend() {
            trends.append(cpuTrend)
        }
        
        // Memory Trends
        if let memoryTrend = analyzeMemoryTrend() {
            trends.append(memoryTrend)
        }
        
        // Network Trends
        if let networkTrend = analyzeNetworkTrend() {
            trends.append(networkTrend)
        }
        
        // Battery Trends
        if let batteryTrend = analyzeBatteryTrend() {
            trends.append(batteryTrend)
        }
        
        // Application Trends
        if let appTrend = analyzeApplicationTrend() {
            trends.append(appTrend)
        }
        
        // UI Trends
        if let uiTrend = analyzeUITrend() {
            trends.append(uiTrend)
        }
        
        // ML Trends
        if let mlTrend = analyzeMLTrend() {
            trends.append(mlTrend)
        }
        
        // Database Trends
        if let dbTrend = analyzeDatabaseTrend() {
            trends.append(dbTrend)
        }
        
        // Security Trends
        if let securityTrend = analyzeSecurityTrend() {
            trends.append(securityTrend)
        }
        
        return trends
    }
    
    private func analyzeCPUTrend() -> PerformanceTrend? {
        let values = metricsHistory.map { $0.cpu.usage }
        let trend = calculateTrend(values: values)
        
        return PerformanceTrend(
            metric: "cpu_usage",
            category: .cpu,
            values: values,
            trend: trend.direction,
            confidence: trend.confidence,
            forecast: calculateForecast(values: values, timeSteps: 5),
            description: "CPU usage trend analysis",
            recommendation: generateRecommendation(for: .cpu, trend: trend.direction)
        )
    }
    
    private func analyzeMemoryTrend() -> PerformanceTrend? {
        let values = metricsHistory.map { Double($0.memory.usedMemory) / Double($0.memory.totalMemory) * 100 }
        let trend = calculateTrend(values: values)
        
        return PerformanceTrend(
            metric: "memory_usage",
            category: .memory,
            values: values,
            trend: trend.direction,
            confidence: trend.confidence,
            forecast: calculateForecast(values: values, timeSteps: 5),
            description: "Memory usage trend analysis",
            recommendation: generateRecommendation(for: .memory, trend: trend.direction)
        )
    }
    
    private func analyzeNetworkTrend() -> PerformanceTrend? {
        let values = metricsHistory.map { $0.network.latency }
        let trend = calculateTrend(values: values)
        
        return PerformanceTrend(
            metric: "network_latency",
            category: .network,
            values: values,
            trend: trend.direction,
            confidence: trend.confidence,
            forecast: calculateForecast(values: values, timeSteps: 5),
            description: "Network latency trend analysis",
            recommendation: generateRecommendation(for: .network, trend: trend.direction)
        )
    }
    
    private func analyzeBatteryTrend() -> PerformanceTrend? {
        let values = metricsHistory.map { Double($0.battery.batteryLevel) * 100 }
        let trend = calculateTrend(values: values)
        
        return PerformanceTrend(
            metric: "battery_level",
            category: .battery,
            values: values,
            trend: trend.direction,
            confidence: trend.confidence,
            forecast: calculateForecast(values: values, timeSteps: 5),
            description: "Battery level trend analysis",
            recommendation: generateRecommendation(for: .battery, trend: trend.direction)
        )
    }
    
    private func analyzeApplicationTrend() -> PerformanceTrend? {
        let values = metricsHistory.map { $0.application.frameRate }
        let trend = calculateTrend(values: values)
        
        return PerformanceTrend(
            metric: "frame_rate",
            category: .application,
            values: values,
            trend: trend.direction,
            confidence: trend.confidence,
            forecast: calculateForecast(values: values, timeSteps: 5),
            description: "Application frame rate trend analysis",
            recommendation: generateRecommendation(for: .application, trend: trend.direction)
        )
    }
    
    private func analyzeUITrend() -> PerformanceTrend? {
        let values = metricsHistory.map { $0.ui.renderTime }
        let trend = calculateTrend(values: values)
        
        return PerformanceTrend(
            metric: "render_time",
            category: .ui,
            values: values,
            trend: trend.direction,
            confidence: trend.confidence,
            forecast: calculateForecast(values: values, timeSteps: 5),
            description: "UI render time trend analysis",
            recommendation: generateRecommendation(for: .ui, trend: trend.direction)
        )
    }
    
    private func analyzeMLTrend() -> PerformanceTrend? {
        let values = metricsHistory.map { $0.ml.inferenceTime }
        let trend = calculateTrend(values: values)
        
        return PerformanceTrend(
            metric: "ml_inference_time",
            category: .machineLearning,
            values: values,
            trend: trend.direction,
            confidence: trend.confidence,
            forecast: calculateForecast(values: values, timeSteps: 5),
            description: "ML inference time trend analysis",
            recommendation: generateRecommendation(for: .machineLearning, trend: trend.direction)
        )
    }
    
    private func analyzeDatabaseTrend() -> PerformanceTrend? {
        let values = metricsHistory.map { $0.database.queryTime }
        let trend = calculateTrend(values: values)
        
        return PerformanceTrend(
            metric: "database_query_time",
            category: .database,
            values: values,
            trend: trend.direction,
            confidence: trend.confidence,
            forecast: calculateForecast(values: values, timeSteps: 5),
            description: "Database query time trend analysis",
            recommendation: generateRecommendation(for: .database, trend: trend.direction)
        )
    }
    
    private func analyzeSecurityTrend() -> PerformanceTrend? {
        let values = metricsHistory.map { $0.security.authenticationTime }
        let trend = calculateTrend(values: values)
        
        return PerformanceTrend(
            metric: "authentication_time",
            category: .security,
            values: values,
            trend: trend.direction,
            confidence: trend.confidence,
            forecast: calculateForecast(values: values, timeSteps: 5),
            description: "Authentication time trend analysis",
            recommendation: generateRecommendation(for: .security, trend: trend.direction)
        )
    }
    
    private func calculateTrend(values: [Double]) -> (direction: TrendDirection, confidence: Double) {
        guard values.count >= 2 else {
            return (.stable, 0.0)
        }
        
        // Simple linear regression for trend calculation
        let n = Double(values.count)
        let xValues = Array(0..<values.count).map { Double($0) }
        
        let sumX = xValues.reduce(0, +)
        let sumY = values.reduce(0, +)
        let sumXY = zip(xValues, values).map(*).reduce(0, +)
        let sumX2 = xValues.map { $0 * $0 }.reduce(0, +)
        
        let slope = (n * sumXY - sumX * sumY) / (n * sumX2 - sumX * sumX)
        
        // Calculate confidence based on R-squared
        let meanY = sumY / n
        let ssRes = zip(values, xValues).map { y, x in
            let predicted = slope * x + (sumY / n - slope * sumX / n)
            return pow(y - predicted, 2)
        }.reduce(0, +)
        
        let ssTot = values.map { pow($0 - meanY, 2) }.reduce(0, +)
        let rSquared = ssTot > 0 ? 1 - (ssRes / ssTot) : 0
        let confidence = max(0, min(100, rSquared * 100))
        
        // Determine trend direction
        let direction: TrendDirection
        if abs(slope) < 0.01 {
            direction = .stable
        } else if slope > 0 {
            direction = .increasing
        } else {
            direction = .decreasing
        }
        
        return (direction, confidence)
    }
    
    private func calculateForecast(values: [Double], timeSteps: Int) -> [Double] {
        guard values.count >= 2 else { return [] }
        
        // Simple linear extrapolation
        let n = Double(values.count)
        let xValues = Array(0..<values.count).map { Double($0) }
        
        let sumX = xValues.reduce(0, +)
        let sumY = values.reduce(0, +)
        let sumXY = zip(xValues, values).map(*).reduce(0, +)
        let sumX2 = xValues.map { $0 * $0 }.reduce(0, +)
        
        let slope = (n * sumXY - sumX * sumY) / (n * sumX2 - sumX * sumX)
        let intercept = (sumY / n) - slope * (sumX / n)
        
        var forecast: [Double] = []
        for i in 1...timeSteps {
            let x = Double(values.count + i - 1)
            let predicted = slope * x + intercept
            forecast.append(max(0, predicted)) // Ensure non-negative values
        }
        
        return forecast
    }
    
    private func calculateForecast(trend: PerformanceTrend, timeSteps: Int) -> [Double] {
        return calculateForecast(values: trend.values, timeSteps: timeSteps)
    }
    
    private func generateRecommendation(for category: TrendCategory, trend: TrendDirection) -> String {
        switch (category, trend) {
        case (.cpu, .increasing):
            return "CPU usage is trending upward. Consider optimizing CPU-intensive operations."
        case (.cpu, .decreasing):
            return "CPU usage is improving. Continue monitoring for sustained improvement."
        case (.memory, .increasing):
            return "Memory usage is trending upward. Investigate potential memory leaks."
        case (.memory, .decreasing):
            return "Memory usage is improving. Continue monitoring for sustained improvement."
        case (.network, .increasing):
            return "Network latency is increasing. Check network connectivity and optimize requests."
        case (.network, .decreasing):
            return "Network performance is improving. Continue monitoring for sustained improvement."
        case (.battery, .decreasing):
            return "Battery level is decreasing rapidly. Consider power optimization."
        case (.battery, .increasing):
            return "Battery level is stable or improving. Continue current power management."
        case (.application, .decreasing):
            return "Application performance is declining. Investigate performance bottlenecks."
        case (.application, .increasing):
            return "Application performance is improving. Continue monitoring for sustained improvement."
        case (.ui, .increasing):
            return "UI rendering time is increasing. Optimize view hierarchy and reduce complexity."
        case (.ui, .decreasing):
            return "UI performance is improving. Continue monitoring for sustained improvement."
        case (.machineLearning, .increasing):
            return "ML inference time is increasing. Consider model optimization or compression."
        case (.machineLearning, .decreasing):
            return "ML performance is improving. Continue monitoring for sustained improvement."
        case (.database, .increasing):
            return "Database query time is increasing. Optimize queries and indexes."
        case (.database, .decreasing):
            return "Database performance is improving. Continue monitoring for sustained improvement."
        case (.security, .increasing):
            return "Authentication time is increasing. Investigate security service performance."
        case (.security, .decreasing):
            return "Security performance is improving. Continue monitoring for sustained improvement."
        default:
            return "Performance is stable. Continue monitoring for any changes."
        }
    }
}

// MARK: - Supporting Types

public struct PerformanceTrend: Identifiable {
    public let id = UUID()
    public let metric: String
    public let category: TrendCategory
    public let values: [Double]
    public let trend: TrendDirection
    public let confidence: Double
    public let forecast: [Double]
    public let description: String
    public let recommendation: String
}

public enum TrendDirection: String, CaseIterable {
    case increasing = "Increasing"
    case decreasing = "Decreasing"
    case stable = "Stable"
}

public enum TrendCategory: String, CaseIterable {
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
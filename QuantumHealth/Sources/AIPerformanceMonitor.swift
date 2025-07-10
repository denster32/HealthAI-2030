import Foundation

// MARK: - AI Performance Monitor for HealthAI 2030
/// Tracks and benchmarks quantum/classical AI module performance

public struct PerformanceMetrics {
    public let module: String
    public let latency: TimeInterval
    public let throughput: Float
    public let resourceUsage: Float
    public let accuracy: Float
    public let timestamp: Date
}

public class AIPerformanceMonitor {
    private var metricsLog: [PerformanceMetrics] = []

    public init() {}

    /// Record performance metrics for a module
    public func record(module: String, latency: TimeInterval, throughput: Float, resourceUsage: Float, accuracy: Float) {
        let metrics = PerformanceMetrics(module: module, latency: latency, throughput: throughput, resourceUsage: resourceUsage, accuracy: accuracy, timestamp: Date())
        metricsLog.append(metrics)
        if metricsLog.count > 1000 { metricsLog.removeFirst() }
    }

    /// Get recent performance metrics
    public func recentMetrics(count: Int = 10) -> [PerformanceMetrics] {
        return Array(metricsLog.suffix(count))
    }

    /// Analyze and report performance trends
    public func performanceReport() -> String {
        guard !metricsLog.isEmpty else { return "No data." }
        let avgLatency = metricsLog.map { $0.latency }.reduce(0, +) / Double(metricsLog.count)
        let avgAccuracy = metricsLog.map { $0.accuracy }.reduce(0, +) / Float(metricsLog.count)
        return "Avg Latency: \(avgLatency)s, Avg Accuracy: \(avgAccuracy)"
    }
} 
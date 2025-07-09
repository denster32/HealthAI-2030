import Foundation
import Combine
import os
import MetricKit
import UIKit

/// PerformanceMonitorCoordinator - Orchestrates all performance monitoring services
/// Coordinates MetricsCollector, AnomalyDetectionService, TrendAnalysisService, and RecommendationEngine
@MainActor
public final class PerformanceMonitorCoordinator: ObservableObject, MXMetricManagerSubscriber {
    
    // MARK: - Published Properties
    @Published public var isMonitoring = false
    @Published public var currentMetrics = SystemMetrics()
    @Published public var anomalyAlerts: [AnomalyAlert] = []
    @Published public var optimizationRecommendations: [OptimizationRecommendation] = []
    @Published public var performanceTrends: [PerformanceTrend] = []
    @Published public var systemHealth = SystemHealth.excellent
    @Published public var monitoringInterval: TimeInterval = 1.0
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private var monitoringTimer: Timer?
    private var metricsHistory: [SystemMetrics] = []
    private let maxHistorySize = 1000
    
    // MARK: - Service Dependencies
    private let metricsCollector: MetricsCollector
    private let anomalyDetectionService: AnomalyDetectionService
    private let trendAnalysisService: TrendAnalysisService
    private let recommendationEngine: RecommendationEngine
    
    private let logger = Logger(subsystem: "com.healthai.performance", category: "coordinator")
    private var metricManager: MXMetricManager?
    
    // MARK: - Initialization
    public init() {
        self.metricsCollector = MetricsCollector()
        self.anomalyDetectionService = AnomalyDetectionService()
        self.trendAnalysisService = TrendAnalysisService()
        self.recommendationEngine = RecommendationEngine()
        
        setupMetricKit()
        setupNotifications()
        setupServiceBindings()
    }
    
    // MARK: - Public API
    
    /// Start performance monitoring
    public func startMonitoring(interval: TimeInterval = 1.0) throws {
        guard !isMonitoring else { return }
        
        self.monitoringInterval = interval
        self.isMonitoring = true
        
        // Start monitoring timer
        monitoringTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.collectAndAnalyzeMetrics()
            }
        }
        
        logger.info("Performance monitoring started with interval: \(interval)s")
    }
    
    /// Stop performance monitoring
    public func stopMonitoring() {
        monitoringTimer?.invalidate()
        monitoringTimer = nil
        isMonitoring = false
        
        logger.info("Performance monitoring stopped")
    }
    
    /// Get performance dashboard data
    public func getPerformanceDashboard() -> PerformanceDashboard {
        return PerformanceDashboard(
            systemOverview: getSystemOverview(),
            metricCharts: getMetricCharts(),
            anomalyAlerts: anomalyAlerts,
            optimizationRecommendations: optimizationRecommendations,
            performanceTrends: performanceTrends,
            performanceSummary: getPerformanceSummary()
        )
    }
    
    /// Clear all monitoring data
    public func clearData() {
        metricsHistory.removeAll()
        anomalyAlerts.removeAll()
        optimizationRecommendations.removeAll()
        performanceTrends.removeAll()
        
        anomalyDetectionService.clearAlerts()
        recommendationEngine.clearRecommendations()
    }
    
    // MARK: - Private Methods
    
    private func setupMetricKit() {
        metricManager = MXMetricManager.shared
        metricManager?.add(self)
    }
    
    private func setupNotifications() {
        // Monitor memory warnings
        NotificationCenter.default.publisher(for: UIApplication.didReceiveMemoryWarningNotification)
            .sink { [weak self] _ in
                Task { @MainActor in
                    await self?.handleMemoryWarning()
                }
            }
            .store(in: &cancellables)
        
        // Monitor app state changes
        NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
            .sink { [weak self] _ in
                Task { @MainActor in
                    await self?.handleAppStateChange(.foreground)
                }
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)
            .sink { [weak self] _ in
                Task { @MainActor in
                    await self?.handleAppStateChange(.background)
                }
            }
            .store(in: &cancellables)
    }
    
    private func setupServiceBindings() {
        // Bind metrics collector updates
        metricsCollector.$currentMetrics
            .sink { [weak self] metrics in
                self?.currentMetrics = metrics
            }
            .store(in: &cancellables)
        
        // Bind anomaly detection updates
        anomalyDetectionService.$anomalyAlerts
            .sink { [weak self] alerts in
                self?.anomalyAlerts = alerts
            }
            .store(in: &cancellables)
        
        // Bind trend analysis updates
        trendAnalysisService.$performanceTrends
            .sink { [weak self] trends in
                self?.performanceTrends = trends
            }
            .store(in: &cancellables)
        
        // Bind recommendation engine updates
        recommendationEngine.$optimizationRecommendations
            .sink { [weak self] recommendations in
                self?.optimizationRecommendations = recommendations
            }
            .store(in: &cancellables)
    }
    
    private func collectAndAnalyzeMetrics() async {
        // Collect metrics
        let metrics = await metricsCollector.collectMetrics()
        
        // Add to history
        metricsHistory.append(metrics)
        if metricsHistory.count > maxHistorySize {
            metricsHistory.removeFirst()
        }
        
        // Analyze for anomalies
        await analyzeAnomalies(metrics)
        
        // Update trends
        await updateTrends()
        
        // Generate recommendations
        await generateRecommendations()
        
        // Update system health
        updateSystemHealth()
    }
    
    private func analyzeAnomalies(_ metrics: SystemMetrics) async {
        let newAnomalies = await anomalyDetectionService.detectAnomalies(metrics, history: metricsHistory)
        
        for anomaly in newAnomalies {
            if !anomalyAlerts.contains(where: { $0.id == anomaly.id }) {
                anomalyAlerts.append(anomaly)
                logger.warning("Anomaly detected: \(anomaly.description)")
            }
        }
        
        // Clean up old alerts
        let cutoffTime = Date().addingTimeInterval(-300) // 5 minutes
        anomalyAlerts.removeAll { $0.timestamp < cutoffTime }
    }
    
    private func updateTrends() async {
        performanceTrends = await trendAnalysisService.analyzeTrends(metricsHistory)
    }
    
    private func generateRecommendations() async {
        optimizationRecommendations = await recommendationEngine.generateRecommendations(
            currentMetrics: currentMetrics,
            history: metricsHistory,
            anomalies: anomalyAlerts,
            trends: performanceTrends
        )
    }
    
    private func updateSystemHealth() {
        let criticalAnomalies = anomalyAlerts.filter { $0.severity == .critical }
        let highAnomalies = anomalyAlerts.filter { $0.severity == .high }
        
        if !criticalAnomalies.isEmpty {
            systemHealth = .critical
        } else if !highAnomalies.isEmpty {
            systemHealth = .poor
        } else if anomalyAlerts.count > 3 {
            systemHealth = .fair
        } else if anomalyAlerts.count > 1 {
            systemHealth = .good
        } else {
            systemHealth = .excellent
        }
    }
    
    private func handleMemoryWarning() async {
        logger.warning("Memory warning received")
        
        let alert = AnomalyAlert(
            metric: "memory_warning",
            value: Double(currentMetrics.memory.usedMemory),
            threshold: Double(currentMetrics.memory.totalMemory) * 0.8,
            severity: .high,
            category: .memory,
            description: "System memory warning received",
            recommendation: "Reduce memory usage by clearing caches and releasing unnecessary objects"
        )
        
        if !anomalyAlerts.contains(where: { $0.id == alert.id }) {
            anomalyAlerts.append(alert)
        }
    }
    
    private func handleAppStateChange(_ state: AppState) {
        logger.info("App state changed to: \(state.rawValue)")
        
        switch state {
        case .foreground:
            // Resume monitoring if needed
            break
        case .background:
            // Reduce monitoring frequency
            break
        }
    }
    
    private func getSystemOverview() -> SystemOverview {
        return SystemOverview(
            health: systemHealth,
            cpuUsage: currentMetrics.cpu.usage,
            memoryUsage: Double(currentMetrics.memory.usedMemory) / Double(currentMetrics.memory.totalMemory) * 100,
            batteryLevel: Double(currentMetrics.battery.batteryLevel) * 100,
            networkLatency: currentMetrics.network.latency,
            activeAlerts: anomalyAlerts.count,
            recommendations: optimizationRecommendations.count
        )
    }
    
    private func getMetricCharts() -> [MetricChart] {
        // Generate chart data from metrics history
        var charts: [MetricChart] = []
        
        if metricsHistory.count >= 2 {
            let cpuValues = metricsHistory.map { $0.cpu.usage }
            charts.append(MetricChart(
                title: "CPU Usage",
                values: cpuValues,
                unit: "%",
                color: .blue
            ))
            
            let memoryValues = metricsHistory.map { Double($0.memory.usedMemory) / Double($0.memory.totalMemory) * 100 }
            charts.append(MetricChart(
                title: "Memory Usage",
                values: memoryValues,
                unit: "%",
                color: .green
            ))
            
            let batteryValues = metricsHistory.map { Double($0.battery.batteryLevel) * 100 }
            charts.append(MetricChart(
                title: "Battery Level",
                values: batteryValues,
                unit: "%",
                color: .orange
            ))
        }
        
        return charts
    }
    
    private func getPerformanceSummary() -> PerformanceSummary {
        let criticalAlerts = anomalyAlerts.filter { $0.severity == .critical }
        let highAlerts = anomalyAlerts.filter { $0.severity == .high }
        let criticalRecommendations = optimizationRecommendations.filter { $0.priority == .critical }
        
        return PerformanceSummary(
            overallHealth: systemHealth,
            criticalIssues: criticalAlerts.count,
            highPriorityIssues: highAlerts.count,
            criticalRecommendations: criticalRecommendations.count,
            totalRecommendations: optimizationRecommendations.count,
            monitoringDuration: calculateMonitoringDuration(),
            dataPointsCollected: metricsHistory.count
        )
    }
    
    private func calculateMonitoringDuration() -> TimeInterval {
        guard !metricsHistory.isEmpty else { return 0 }
        let firstTimestamp = metricsHistory.first?.timestamp ?? Date()
        let lastTimestamp = metricsHistory.last?.timestamp ?? Date()
        return lastTimestamp.timeIntervalSince(firstTimestamp)
    }
}

// MARK: - Supporting Types

public enum SystemHealth: String, CaseIterable {
    case excellent = "Excellent"
    case good = "Good"
    case fair = "Fair"
    case poor = "Poor"
    case critical = "Critical"
}

public enum AppState: String {
    case foreground = "Foreground"
    case background = "Background"
}

public struct PerformanceDashboard {
    public let systemOverview: SystemOverview
    public let metricCharts: [MetricChart]
    public let anomalyAlerts: [AnomalyAlert]
    public let optimizationRecommendations: [OptimizationRecommendation]
    public let performanceTrends: [PerformanceTrend]
    public let performanceSummary: PerformanceSummary
}

public struct SystemOverview {
    public let health: SystemHealth
    public let cpuUsage: Double
    public let memoryUsage: Double
    public let batteryLevel: Double
    public let networkLatency: Double
    public let activeAlerts: Int
    public let recommendations: Int
}

public struct MetricChart {
    public let title: String
    public let values: [Double]
    public let unit: String
    public let color: ChartColor
}

public enum ChartColor: String {
    case blue = "blue"
    case green = "green"
    case orange = "orange"
    case red = "red"
    case purple = "purple"
}

public struct PerformanceSummary {
    public let overallHealth: SystemHealth
    public let criticalIssues: Int
    public let highPriorityIssues: Int
    public let criticalRecommendations: Int
    public let totalRecommendations: Int
    public let monitoringDuration: TimeInterval
    public let dataPointsCollected: Int
} 
import Foundation
import Combine
import SwiftUI
import Charts

/// Provider Performance Tracking System
/// Comprehensive performance tracking system for healthcare providers with metrics, analytics, and improvement recommendations
@available(iOS 18.0, macOS 15.0, *)
public actor ProviderPerformanceTracking: ObservableObject {
    
    // MARK: - Published Properties
    @Published public private(set) var trackingStatus: TrackingStatus = .idle
    @Published public private(set) var currentOperation: TrackingOperation = .none
    @Published public private(set) var progress: Double = 0.0
    @Published public private(set) var performanceData: PerformanceData = PerformanceData()
    @Published public private(set) var lastError: String?
    @Published public private(set) var alerts: [PerformanceAlert] = []
    
    // MARK: - Private Properties
    private let metricsManager: PerformanceMetricsManager
    private let analyticsEngine: PerformanceAnalyticsEngine
    private let recommendationEngine: RecommendationEngine
    private let benchmarkManager: BenchmarkManager
    private let analyticsEngine: AnalyticsEngine
    
    private var cancellables = Set<AnyCancellable>()
    private let trackingQueue = DispatchQueue(label: "health.performance.tracking", qos: .userInitiated)
    
    // Performance data
    private var providerMetrics: [String: ProviderMetrics] = [:]
    private var performanceHistory: [PerformanceHistory] = []
    private var benchmarks: [Benchmark] = []
    private var recommendations: [PerformanceRecommendation] = []
    
    // MARK: - Initialization
    public init(metricsManager: PerformanceMetricsManager,
                analyticsEngine: PerformanceAnalyticsEngine,
                recommendationEngine: RecommendationEngine,
                benchmarkManager: BenchmarkManager,
                analyticsEngine: AnalyticsEngine) {
        self.metricsManager = metricsManager
        self.analyticsEngine = analyticsEngine
        self.recommendationEngine = recommendationEngine
        self.benchmarkManager = benchmarkManager
        self.analyticsEngine = analyticsEngine
        
        setupPerformanceTracking()
        setupMetricsCollection()
        setupAnalyticsProcessing()
        setupRecommendationEngine()
        setupBenchmarking()
    }
    
    // MARK: - Public Methods
    
    /// Load performance data
    public func loadPerformanceData(providerId: String, timeRange: TimeRange) async throws -> PerformanceData {
        trackingStatus = .loading
        currentOperation = .dataLoading
        progress = 0.0
        lastError = nil
        
        do {
            // Load provider metrics
            let providerMetrics = try await loadProviderMetrics(providerId: providerId, timeRange: timeRange)
            await updateProgress(operation: .metricsLoading, progress: 0.2)
            
            // Load performance history
            let performanceHistory = try await loadPerformanceHistory(providerId: providerId, timeRange: timeRange)
            await updateProgress(operation: .historyLoading, progress: 0.4)
            
            // Load benchmarks
            let benchmarks = try await loadBenchmarks(providerId: providerId)
            await updateProgress(operation: .benchmarkLoading, progress: 0.6)
            
            // Generate recommendations
            let recommendations = try await generateRecommendations(metrics: providerMetrics, benchmarks: benchmarks)
            await updateProgress(operation: .recommendationGeneration, progress: 0.8)
            
            // Compile performance data
            let performanceData = try await compilePerformanceData(
                providerMetrics: providerMetrics,
                performanceHistory: performanceHistory,
                benchmarks: benchmarks,
                recommendations: recommendations
            )
            await updateProgress(operation: .compilation, progress: 1.0)
            
            // Complete loading
            trackingStatus = .loaded
            
            // Update performance data
            await MainActor.run {
                self.performanceData = performanceData
            }
            
            // Track analytics
            analyticsEngine.trackEvent("performance_data_loaded", properties: [
                "provider_id": providerId,
                "time_range": timeRange.description,
                "metrics_count": providerMetrics.count,
                "timestamp": Date().timeIntervalSince1970
            ])
            
            return performanceData
            
        } catch {
            await MainActor.run {
                self.lastError = error.localizedDescription
                self.trackingStatus = .error
            }
            throw error
        }
    }
    
    /// Track performance metric
    public func trackPerformanceMetric(metric: PerformanceMetric) async throws -> MetricResult {
        trackingStatus = .tracking
        currentOperation = .metricTracking
        progress = 0.0
        lastError = nil
        
        do {
            // Validate metric
            try await validateMetric(metric: metric)
            await updateProgress(operation: .validation, progress: 0.1)
            
            // Process metric
            let processedMetric = try await processMetric(metric: metric)
            await updateProgress(operation: .processing, progress: 0.3)
            
            // Calculate performance score
            let performanceScore = try await calculatePerformanceScore(metric: processedMetric)
            await updateProgress(operation: .scoreCalculation, progress: 0.5)
            
            // Update metrics
            try await updateMetrics(metric: processedMetric, score: performanceScore)
            await updateProgress(operation: .metricsUpdate, progress: 0.7)
            
            // Generate alerts if needed
            try await generateAlerts(metric: processedMetric, score: performanceScore)
            await updateProgress(operation: .alertGeneration, progress: 0.9)
            
            // Complete tracking
            trackingStatus = .tracked
            
            return MetricResult(
                success: true,
                metricId: processedMetric.metricId,
                performanceScore: performanceScore,
                timestamp: Date()
            )
            
        } catch {
            await MainActor.run {
                self.lastError = error.localizedDescription
                self.trackingStatus = .error
            }
            throw error
        }
    }
    
    /// Get performance analytics
    public func getPerformanceAnalytics(providerId: String, analyticsType: AnalyticsType) async throws -> PerformanceAnalytics {
        trackingStatus = .analyzing
        currentOperation = .analyticsGeneration
        progress = 0.0
        lastError = nil
        
        do {
            // Load analytics data
            let analyticsData = try await loadAnalyticsData(providerId: providerId, analyticsType: analyticsType)
            await updateProgress(operation: .dataLoading, progress: 0.3)
            
            // Generate analytics
            let analytics = try await generateAnalytics(data: analyticsData, type: analyticsType)
            await updateProgress(operation: .analyticsGeneration, progress: 0.7)
            
            // Create visualizations
            let visualizations = try await createVisualizations(analytics: analytics)
            await updateProgress(operation: .visualization, progress: 1.0)
            
            // Complete analysis
            trackingStatus = .analyzed
            
            return analytics
            
        } catch {
            await MainActor.run {
                self.lastError = error.localizedDescription
                self.trackingStatus = .error
            }
            throw error
        }
    }
    
    /// Get performance recommendations
    public func getPerformanceRecommendations(providerId: String) async throws -> [PerformanceRecommendation] {
        let recommendationRequest = RecommendationRequest(
            providerId: providerId,
            timestamp: Date()
        )
        
        let recommendations = try await recommendationEngine.getRecommendations(recommendationRequest)
        
        // Update recommendations
        await MainActor.run {
            self.recommendations = recommendations
        }
        
        return recommendations
    }
    
    /// Compare with benchmarks
    public func compareWithBenchmarks(providerId: String, metricType: MetricType) async throws -> BenchmarkComparison {
        trackingStatus = .comparing
        currentOperation = .benchmarkComparison
        progress = 0.0
        lastError = nil
        
        do {
            // Load provider metrics
            let providerMetrics = try await loadProviderMetrics(providerId: providerId, timeRange: TimeRange(start: Date().addingTimeInterval(-30*24*3600), end: Date()))
            await updateProgress(operation: .metricsLoading, progress: 0.3)
            
            // Load benchmarks
            let benchmarks = try await loadBenchmarks(providerId: providerId)
            await updateProgress(operation: .benchmarkLoading, progress: 0.6)
            
            // Perform comparison
            let comparison = try await performComparison(providerMetrics: providerMetrics, benchmarks: benchmarks, metricType: metricType)
            await updateProgress(operation: .comparison, progress: 1.0)
            
            // Complete comparison
            trackingStatus = .compared
            
            return comparison
            
        } catch {
            await MainActor.run {
                self.lastError = error.localizedDescription
                self.trackingStatus = .error
            }
            throw error
        }
    }
    
    /// Generate performance report
    public func generatePerformanceReport(providerId: String, reportType: ReportType, timeRange: TimeRange) async throws -> PerformanceReport {
        trackingStatus = .reporting
        currentOperation = .reportGeneration
        progress = 0.0
        lastError = nil
        
        do {
            // Load report data
            let reportData = try await loadReportData(providerId: providerId, reportType: reportType, timeRange: timeRange)
            await updateProgress(operation: .dataLoading, progress: 0.2)
            
            // Generate report
            let report = try await generateReport(data: reportData, type: reportType)
            await updateProgress(operation: .reportGeneration, progress: 0.6)
            
            // Add insights
            let insights = try await addInsights(report: report)
            await updateProgress(operation: .insights, progress: 0.8)
            
            // Finalize report
            let finalizedReport = try await finalizeReport(report: insights)
            await updateProgress(operation: .finalization, progress: 1.0)
            
            // Complete reporting
            trackingStatus = .reported
            
            return finalizedReport
            
        } catch {
            await MainActor.run {
                self.lastError = error.localizedDescription
                self.trackingStatus = .error
            }
            throw error
        }
    }
    
    /// Get tracking status
    public func getTrackingStatus() -> TrackingStatus {
        return trackingStatus
    }
    
    /// Get current alerts
    public func getCurrentAlerts() -> [PerformanceAlert] {
        return alerts
    }
    
    // MARK: - Private Methods
    
    private func setupPerformanceTracking() {
        // Setup performance tracking
        setupMetricCollection()
        setupDataProcessing()
        setupScoreCalculation()
        setupAlertSystem()
    }
    
    private func setupMetricsCollection() {
        // Setup metrics collection
        setupMetricValidation()
        setupMetricStorage()
        setupMetricAggregation()
        setupMetricReporting()
    }
    
    private func setupAnalyticsProcessing() {
        // Setup analytics processing
        setupDataAnalysis()
        setupTrendIdentification()
        setupPatternRecognition()
        setupPredictiveAnalytics()
    }
    
    private func setupRecommendationEngine() {
        // Setup recommendation engine
        setupRecommendationGeneration()
        setupRecommendationValidation()
        setupRecommendationPrioritization()
        setupRecommendationTracking()
    }
    
    private func setupBenchmarking() {
        // Setup benchmarking
        setupBenchmarkCollection()
        setupBenchmarkComparison()
        setupBenchmarkAnalysis()
        setupBenchmarkReporting()
    }
    
    private func loadProviderMetrics(providerId: String, timeRange: TimeRange) async throws -> [ProviderMetrics] {
        // Load provider metrics
        let metricsRequest = ProviderMetricsRequest(
            providerId: providerId,
            timeRange: timeRange,
            timestamp: Date()
        )
        
        return try await metricsManager.loadProviderMetrics(metricsRequest)
    }
    
    private func loadPerformanceHistory(providerId: String, timeRange: TimeRange) async throws -> [PerformanceHistory] {
        // Load performance history
        let historyRequest = PerformanceHistoryRequest(
            providerId: providerId,
            timeRange: timeRange,
            timestamp: Date()
        )
        
        return try await metricsManager.loadPerformanceHistory(historyRequest)
    }
    
    private func loadBenchmarks(providerId: String) async throws -> [Benchmark] {
        // Load benchmarks
        let benchmarkRequest = BenchmarkRequest(
            providerId: providerId,
            timestamp: Date()
        )
        
        return try await benchmarkManager.loadBenchmarks(benchmarkRequest)
    }
    
    private func generateRecommendations(metrics: [ProviderMetrics], benchmarks: [Benchmark]) async throws -> [PerformanceRecommendation] {
        // Generate recommendations
        let recommendationRequest = RecommendationGenerationRequest(
            metrics: metrics,
            benchmarks: benchmarks,
            timestamp: Date()
        )
        
        return try await recommendationEngine.generateRecommendations(recommendationRequest)
    }
    
    private func compilePerformanceData(providerMetrics: [ProviderMetrics],
                                      performanceHistory: [PerformanceHistory],
                                      benchmarks: [Benchmark],
                                      recommendations: [PerformanceRecommendation]) async throws -> PerformanceData {
        // Compile performance data
        return PerformanceData(
            providerMetrics: providerMetrics,
            performanceHistory: performanceHistory,
            benchmarks: benchmarks,
            recommendations: recommendations,
            totalMetrics: providerMetrics.count,
            lastUpdated: Date()
        )
    }
    
    private func validateMetric(metric: PerformanceMetric) async throws {
        // Validate metric
        guard !metric.providerId.isEmpty else {
            throw PerformanceError.invalidProviderId
        }
        
        guard metric.value >= 0 else {
            throw PerformanceError.invalidMetricValue
        }
        
        guard metric.type.isValid else {
            throw PerformanceError.invalidMetricType
        }
    }
    
    private func processMetric(metric: PerformanceMetric) async throws -> ProcessedMetric {
        // Process metric
        let processingRequest = MetricProcessingRequest(
            metric: metric,
            timestamp: Date()
        )
        
        return try await metricsManager.processMetric(processingRequest)
    }
    
    private func calculatePerformanceScore(metric: ProcessedMetric) async throws -> PerformanceScore {
        // Calculate performance score
        let scoreRequest = ScoreCalculationRequest(
            metric: metric,
            timestamp: Date()
        )
        
        return try await analyticsEngine.calculatePerformanceScore(scoreRequest)
    }
    
    private func updateMetrics(metric: ProcessedMetric, score: PerformanceScore) async throws {
        // Update metrics
        let updateRequest = MetricsUpdateRequest(
            metric: metric,
            score: score,
            timestamp: Date()
        )
        
        try await metricsManager.updateMetrics(updateRequest)
    }
    
    private func generateAlerts(metric: ProcessedMetric, score: PerformanceScore) async throws {
        // Generate alerts
        let alertRequest = AlertGenerationRequest(
            metric: metric,
            score: score,
            timestamp: Date()
        )
        
        let newAlerts = try await analyticsEngine.generateAlerts(alertRequest)
        
        // Update alerts
        await MainActor.run {
            self.alerts.append(contentsOf: newAlerts)
        }
    }
    
    private func loadAnalyticsData(providerId: String, analyticsType: AnalyticsType) async throws -> AnalyticsData {
        // Load analytics data
        let dataRequest = AnalyticsDataRequest(
            providerId: providerId,
            analyticsType: analyticsType,
            timestamp: Date()
        )
        
        return try await analyticsEngine.loadAnalyticsData(dataRequest)
    }
    
    private func generateAnalytics(data: AnalyticsData, type: AnalyticsType) async throws -> PerformanceAnalytics {
        // Generate analytics
        let analyticsRequest = AnalyticsGenerationRequest(
            data: data,
            type: type,
            timestamp: Date()
        )
        
        return try await analyticsEngine.generateAnalytics(analyticsRequest)
    }
    
    private func createVisualizations(analytics: PerformanceAnalytics) async throws -> [DataVisualization] {
        // Create visualizations
        let visualizationRequest = VisualizationRequest(
            analytics: analytics,
            timestamp: Date()
        )
        
        return try await analyticsEngine.createVisualizations(visualizationRequest)
    }
    
    private func performComparison(providerMetrics: [ProviderMetrics], benchmarks: [Benchmark], metricType: MetricType) async throws -> BenchmarkComparison {
        // Perform comparison
        let comparisonRequest = BenchmarkComparisonRequest(
            providerMetrics: providerMetrics,
            benchmarks: benchmarks,
            metricType: metricType,
            timestamp: Date()
        )
        
        return try await benchmarkManager.performComparison(comparisonRequest)
    }
    
    private func loadReportData(providerId: String, reportType: ReportType, timeRange: TimeRange) async throws -> ReportData {
        // Load report data
        let dataRequest = ReportDataRequest(
            providerId: providerId,
            reportType: reportType,
            timeRange: timeRange,
            timestamp: Date()
        )
        
        return try await metricsManager.loadReportData(dataRequest)
    }
    
    private func generateReport(data: ReportData, type: ReportType) async throws -> PerformanceReport {
        // Generate report
        let reportRequest = ReportGenerationRequest(
            data: data,
            type: type,
            timestamp: Date()
        )
        
        return try await metricsManager.generateReport(reportRequest)
    }
    
    private func addInsights(report: PerformanceReport) async throws -> PerformanceReport {
        // Add insights
        let insightsRequest = InsightsRequest(
            report: report,
            timestamp: Date()
        )
        
        return try await analyticsEngine.addInsights(insightsRequest)
    }
    
    private func finalizeReport(report: PerformanceReport) async throws -> PerformanceReport {
        // Finalize report
        let finalizationRequest = ReportFinalizationRequest(
            report: report,
            timestamp: Date()
        )
        
        return try await metricsManager.finalizeReport(finalizationRequest)
    }
    
    private func updateProgress(operation: TrackingOperation, progress: Double) async {
        await MainActor.run {
            self.currentOperation = operation
            self.progress = progress
        }
    }
}

// MARK: - Data Models

public struct PerformanceData: Codable {
    public let providerMetrics: [ProviderMetrics]
    public let performanceHistory: [PerformanceHistory]
    public let benchmarks: [Benchmark]
    public let recommendations: [PerformanceRecommendation]
    public let totalMetrics: Int
    public let lastUpdated: Date
}

public struct PerformanceMetric: Codable {
    public let metricId: String
    public let providerId: String
    public let type: MetricType
    public let value: Double
    public let unit: String
    public let category: MetricCategory
    public let timestamp: Date
    public let metadata: [String: String]
}

public struct ProviderMetrics: Codable {
    public let providerId: String
    public let metrics: [PerformanceMetric]
    public let overallScore: Double
    public let categoryScores: [String: Double]
    public let trend: TrendDirection
    public let lastUpdated: Date
}

public struct PerformanceHistory: Codable {
    public let providerId: String
    public let date: Date
    public let metrics: [PerformanceMetric]
    public let score: Double
    public let rank: Int
    public let percentile: Double
}

public struct Benchmark: Codable {
    public let benchmarkId: String
    public let metricType: MetricType
    public let category: String
    public let average: Double
    public let median: Double
    public let percentile25: Double
    public let percentile75: Double
    public let sampleSize: Int
    public let lastUpdated: Date
}

public struct PerformanceRecommendation: Codable {
    public let recommendationId: String
    public let providerId: String
    public let type: RecommendationType
    public let title: String
    public let description: String
    public let priority: Priority
    public let impact: Impact
    public let effort: Effort
    public let timeline: String
    public let status: RecommendationStatus
    public let createdAt: Date
}

public struct PerformanceAlert: Codable {
    public let alertId: String
    public let providerId: String
    public let type: AlertType
    public let severity: AlertSeverity
    public let message: String
    public let metric: PerformanceMetric?
    public let isAcknowledged: Bool
    public let timestamp: Date
}

public struct MetricResult: Codable {
    public let success: Bool
    public let metricId: String
    public let performanceScore: PerformanceScore
    public let timestamp: Date
}

public struct PerformanceAnalytics: Codable {
    public let providerId: String
    public let analyticsType: AnalyticsType
    public let data: [AnalyticsDataPoint]
    public let insights: [AnalyticsInsight]
    public let trends: [TrendAnalysis]
    public let predictions: [Prediction]
    public let timestamp: Date
}

public struct BenchmarkComparison: Codable {
    public let providerId: String
    public let metricType: MetricType
    public let providerValue: Double
    public let benchmarkValue: Double
    public let difference: Double
    public let percentile: Double
    public let performance: PerformanceLevel
    public let recommendations: [String]
    public let timestamp: Date
}

public struct PerformanceReport: Codable {
    public let reportId: String
    public let providerId: String
    public let reportType: ReportType
    public let timeRange: TimeRange
    public let summary: ReportSummary
    public let details: ReportDetails
    public let insights: [ReportInsight]
    public let recommendations: [PerformanceRecommendation]
    public let generatedAt: Date
}

public struct ProcessedMetric: Codable {
    public let metricId: String
    public let providerId: String
    public let type: MetricType
    public let value: Double
    public let normalizedValue: Double
    public let category: MetricCategory
    public let timestamp: Date
}

public struct PerformanceScore: Codable {
    public let score: Double
    public let category: String
    public let factors: [ScoreFactor]
    public let timestamp: Date
}

public struct AnalyticsData: Codable {
    public let providerId: String
    public let dataPoints: [AnalyticsDataPoint]
    public let timeRange: TimeRange
    public let timestamp: Date
}

public struct ReportData: Codable {
    public let providerId: String
    public let metrics: [PerformanceMetric]
    public let history: [PerformanceHistory]
    public let benchmarks: [Benchmark]
    public let timeRange: TimeRange
    public let timestamp: Date
}

public struct AnalyticsDataPoint: Codable {
    public let date: Date
    public let value: Double
    public let category: String
    public let metadata: [String: String]
}

public struct AnalyticsInsight: Codable {
    public let insightId: String
    public let type: InsightType
    public let description: String
    public let confidence: Double
    public let timestamp: Date
}

public struct TrendAnalysis: Codable {
    public let trendId: String
    public let direction: TrendDirection
    public let strength: Double
    public let duration: TimeInterval
    public let description: String
}

public struct Prediction: Codable {
    public let predictionId: String
    public let metric: String
    public let predictedValue: Double
    public let confidence: Double
    public let timeframe: TimeInterval
    public let timestamp: Date
}

public struct ReportSummary: Codable {
    public let overallScore: Double
    public let rank: Int
    public let percentile: Double
    public let trend: TrendDirection
    public let keyMetrics: [String: Double]
}

public struct ReportDetails: Codable {
    public let metrics: [PerformanceMetric]
    public let comparisons: [BenchmarkComparison]
    public let trends: [TrendAnalysis]
    public let visualizations: [DataVisualization]
}

public struct ReportInsight: Codable {
    public let insightId: String
    public let category: String
    public let description: String
    public let impact: Impact
    public let recommendations: [String]
}

public struct ScoreFactor: Codable {
    public let factor: String
    public let weight: Double
    public let contribution: Double
}

public struct DataVisualization: Codable {
    public let visualizationId: String
    public let type: VisualizationType
    public let title: String
    public let data: [DataPoint]
    public let configuration: VisualizationConfig
}

public struct DataPoint: Codable {
    public let x: Double
    public let y: Double
    public let label: String?
    public let color: String?
}

public struct VisualizationConfig: Codable {
    public let chartType: ChartType
    public let colorScheme: ColorScheme
    public let axisLabels: [String]
    public let legend: Bool
}

// MARK: - Enums

public enum TrackingStatus: String, Codable, CaseIterable {
    case idle, loading, loaded, tracking, tracked, analyzing, analyzed, comparing, compared, reporting, reported, error
}

public enum TrackingOperation: String, Codable, CaseIterable {
    case none, dataLoading, metricsLoading, historyLoading, benchmarkLoading, recommendationGeneration, compilation, metricTracking, analyticsGeneration, benchmarkComparison, reportGeneration, validation, processing, scoreCalculation, metricsUpdate, alertGeneration, dataLoading, analyticsGeneration, visualization, comparison, insights, finalization
}

public enum MetricType: String, Codable, CaseIterable {
    case patientSatisfaction, appointmentCompletion, waitTime, treatmentOutcomes, readmissionRate, medicationAdherence, diagnosticAccuracy, responseTime, costEfficiency, qualityScore
    
    public var isValid: Bool {
        return true
    }
}

public enum MetricCategory: String, Codable, CaseIterable {
    case clinical, operational, financial, quality, patientExperience
}

public enum TrendDirection: String, Codable, CaseIterable {
    case improving, declining, stable, fluctuating
}

public enum RecommendationType: String, Codable, CaseIterable {
    case process, training, technology, workflow, communication
}

public enum Priority: String, Codable, CaseIterable {
    case low, medium, high, critical
}

public enum Impact: String, Codable, CaseIterable {
    case low, medium, high, veryHigh
}

public enum Effort: String, Codable, CaseIterable {
    case low, medium, high, veryHigh
}

public enum RecommendationStatus: String, Codable, CaseIterable {
    case pending, inProgress, completed, cancelled
}

public enum AlertType: String, Codable, CaseIterable {
    case performance, quality, safety, compliance, efficiency
}

public enum AlertSeverity: String, Codable, CaseIterable {
    case info, warning, error, critical
}

public enum AnalyticsType: String, Codable, CaseIterable {
    case trend, comparative, predictive, diagnostic, prescriptive
}

public enum PerformanceLevel: String, Codable, CaseIterable {
    case excellent, good, average, belowAverage, poor
}

public enum ReportType: String, Codable, CaseIterable {
    case summary, detailed, comparative, trend, predictive
}

public enum InsightType: String, Codable, CaseIterable {
    case trend, anomaly, correlation, pattern, prediction
}

public enum VisualizationType: String, Codable, CaseIterable {
    case lineChart, barChart, pieChart, scatterPlot, heatmap, gauge
}

public enum ChartType: String, Codable, CaseIterable {
    case line, bar, pie, scatter, area, radar
}

public enum ColorScheme: String, Codable, CaseIterable {
    case blue, green, red, purple, orange, gray
}

// MARK: - Errors

public enum PerformanceError: Error, LocalizedError {
    case invalidProviderId
    case invalidMetricValue
    case invalidMetricType
    case metricNotFound
    case benchmarkNotFound
    case analyticsFailed
    case recommendationFailed
    case reportGenerationFailed
    
    public var errorDescription: String? {
        switch self {
        case .invalidProviderId:
            return "Invalid provider ID"
        case .invalidMetricValue:
            return "Invalid metric value"
        case .invalidMetricType:
            return "Invalid metric type"
        case .metricNotFound:
            return "Metric not found"
        case .benchmarkNotFound:
            return "Benchmark not found"
        case .analyticsFailed:
            return "Analytics processing failed"
        case .recommendationFailed:
            return "Recommendation generation failed"
        case .reportGenerationFailed:
            return "Report generation failed"
        }
    }
}

// MARK: - Protocols

public protocol PerformanceMetricsManager {
    func loadProviderMetrics(_ request: ProviderMetricsRequest) async throws -> [ProviderMetrics]
    func loadPerformanceHistory(_ request: PerformanceHistoryRequest) async throws -> [PerformanceHistory]
    func processMetric(_ request: MetricProcessingRequest) async throws -> ProcessedMetric
    func updateMetrics(_ request: MetricsUpdateRequest) async throws
    func loadReportData(_ request: ReportDataRequest) async throws -> ReportData
    func generateReport(_ request: ReportGenerationRequest) async throws -> PerformanceReport
    func finalizeReport(_ request: ReportFinalizationRequest) async throws -> PerformanceReport
}

public protocol PerformanceAnalyticsEngine {
    func loadAnalyticsData(_ request: AnalyticsDataRequest) async throws -> AnalyticsData
    func generateAnalytics(_ request: AnalyticsGenerationRequest) async throws -> PerformanceAnalytics
    func createVisualizations(_ request: VisualizationRequest) async throws -> [DataVisualization]
    func calculatePerformanceScore(_ request: ScoreCalculationRequest) async throws -> PerformanceScore
    func generateAlerts(_ request: AlertGenerationRequest) async throws -> [PerformanceAlert]
    func addInsights(_ request: InsightsRequest) async throws -> PerformanceReport
}

public protocol RecommendationEngine {
    func generateRecommendations(_ request: RecommendationGenerationRequest) async throws -> [PerformanceRecommendation]
    func getRecommendations(_ request: RecommendationRequest) async throws -> [PerformanceRecommendation]
}

public protocol BenchmarkManager {
    func loadBenchmarks(_ request: BenchmarkRequest) async throws -> [Benchmark]
    func performComparison(_ request: BenchmarkComparisonRequest) async throws -> BenchmarkComparison
}

// MARK: - Supporting Types

public struct ProviderMetricsRequest: Codable {
    public let providerId: String
    public let timeRange: TimeRange
    public let timestamp: Date
}

public struct PerformanceHistoryRequest: Codable {
    public let providerId: String
    public let timeRange: TimeRange
    public let timestamp: Date
}

public struct BenchmarkRequest: Codable {
    public let providerId: String
    public let timestamp: Date
}

public struct RecommendationGenerationRequest: Codable {
    public let metrics: [ProviderMetrics]
    public let benchmarks: [Benchmark]
    public let timestamp: Date
}

public struct MetricProcessingRequest: Codable {
    public let metric: PerformanceMetric
    public let timestamp: Date
}

public struct ScoreCalculationRequest: Codable {
    public let metric: ProcessedMetric
    public let timestamp: Date
}

public struct MetricsUpdateRequest: Codable {
    public let metric: ProcessedMetric
    public let score: PerformanceScore
    public let timestamp: Date
}

public struct AlertGenerationRequest: Codable {
    public let metric: ProcessedMetric
    public let score: PerformanceScore
    public let timestamp: Date
}

public struct AnalyticsDataRequest: Codable {
    public let providerId: String
    public let analyticsType: AnalyticsType
    public let timestamp: Date
}

public struct AnalyticsGenerationRequest: Codable {
    public let data: AnalyticsData
    public let type: AnalyticsType
    public let timestamp: Date
}

public struct VisualizationRequest: Codable {
    public let analytics: PerformanceAnalytics
    public let timestamp: Date
}

public struct BenchmarkComparisonRequest: Codable {
    public let providerMetrics: [ProviderMetrics]
    public let benchmarks: [Benchmark]
    public let metricType: MetricType
    public let timestamp: Date
}

public struct ReportDataRequest: Codable {
    public let providerId: String
    public let reportType: ReportType
    public let timeRange: TimeRange
    public let timestamp: Date
}

public struct ReportGenerationRequest: Codable {
    public let data: ReportData
    public let type: ReportType
    public let timestamp: Date
}

public struct InsightsRequest: Codable {
    public let report: PerformanceReport
    public let timestamp: Date
}

public struct ReportFinalizationRequest: Codable {
    public let report: PerformanceReport
    public let timestamp: Date
}

public struct RecommendationRequest: Codable {
    public let providerId: String
    public let timestamp: Date
} 
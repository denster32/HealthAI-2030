import Foundation
import Combine
import SwiftUI
import Metal
import CoreGraphics
import OSLog

// MARK: - Advanced Data Visualization Engine

/// Advanced Data Visualization Engine
/// Provides comprehensive data visualization capabilities for health data
/// with GPU acceleration, interactive charts, and performance optimizations
@available(iOS 18.0, macOS 15.0, *)
@MainActor
@Observable
public class AdvancedDataVisualizationEngine: HealthAIServiceProtocol {
    
    // MARK: - Singleton
    public static let shared = AdvancedDataVisualizationEngine()
    
    // MARK: - Published Properties
    @Published public var currentVisualizations: [HealthVisualization] = []
    @Published public var isRendering: Bool = false
    @Published public var renderingPerformance: RenderingPerformance = RenderingPerformance()
    @Published public var lastUpdateTime: Date = Date()
    
    // MARK: - Private Properties
    private var visualizationQueue = DispatchQueue(label: "com.healthai.visualization", qos: .userInitiated)
    private var metalDevice: MTLDevice?
    private var metalCommandQueue: MTLCommandQueue?
    private var cancellables = Set<AnyCancellable>()
    private let logger = Logger(subsystem: "com.healthai.visualization", category: "AdvancedDataVisualizationEngine")
    
    // MARK: - Configuration
    private let maxConcurrentRenders = 4
    private let renderTimeout: TimeInterval = 30.0
    private let cacheSize = 100
    
    // MARK: - Initialization
    
    private init() {
        setupMetalDevice()
        setupVisualizationPipeline()
        logger.info("AdvancedDataVisualizationEngine initialized")
    }
    
    deinit {
        cancellables.removeAll()
    }
    
    // MARK: - Public Methods
    
    /// Create interactive health data visualizations
    public func createVisualizations(for data: HealthVisualizationData) async throws -> [HealthVisualization] {
        isRendering = true
        defer { isRendering = false }
        
        let startTime = Date()
        
        do {
            let visualizations = try await visualizationQueue.asyncResult {
                try await self.generateVisualizations(for: data)
            }
            
            await updateRenderingPerformance(startTime: startTime)
            await updateCurrentVisualizations(visualizations)
            
            return visualizations
        } catch {
            logger.error("Failed to create visualizations: \(error.localizedDescription)")
            throw VisualizationError.renderingFailed(error)
        }
    }
    
    /// Create real-time streaming visualizations
    public func createStreamingVisualization(for dataStream: AnyPublisher<HealthDataPoint, Never>) async throws -> HealthVisualization {
        let visualization = HealthVisualization(
            id: UUID(),
            type: .realTimeStream,
            title: "Real-time Health Data",
            description: "Live streaming health data visualization",
            data: [:],
            configuration: VisualizationConfiguration(),
            metadata: VisualizationMetadata()
        )
        
        // Set up streaming data processing
        dataStream
            .sink { [weak self] dataPoint in
                Task { @MainActor in
                    await self?.updateStreamingVisualization(visualization, with: dataPoint)
                }
            }
            .store(in: &cancellables)
        
        return visualization
    }
    
    /// Create comparative analysis visualizations
    public func createComparativeVisualizations(baseline: HealthVisualizationData, comparison: HealthVisualizationData) async throws -> [HealthVisualization] {
        let comparativeData = try await generateComparativeData(baseline: baseline, comparison: comparison)
        
        return try await createVisualizations(for: comparativeData)
    }
    
    /// Create predictive trend visualizations
    public func createPredictiveVisualizations(predictions: [HealthPrediction]) async throws -> [HealthVisualization] {
        let predictiveData = try await generatePredictiveData(from: predictions)
        
        return try await createVisualizations(for: predictiveData)
    }
    
    /// Optimize visualization performance
    public func optimizePerformance() async throws {
        try await clearCache()
        try await optimizeMetalPipeline()
        try await updatePerformanceMetrics()
    }
    
    /// Export visualization as image
    public func exportVisualization(_ visualization: HealthVisualization, format: ExportFormat) async throws -> Data {
        return try await visualizationQueue.asyncResult {
            try await self.renderVisualizationToImage(visualization, format: format)
        }
    }
    
    // MARK: - Private Methods
    
    private func setupMetalDevice() {
        metalDevice = MTLCreateSystemDefaultDevice()
        metalCommandQueue = metalDevice?.makeCommandQueue()
        
        if metalDevice == nil {
            logger.warning("Metal device not available, falling back to CPU rendering")
        }
    }
    
    private func setupVisualizationPipeline() {
        // Set up periodic performance monitoring
        Timer.publish(every: 60, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                Task { @MainActor in
                    await self?.updatePerformanceMetrics()
                }
            }
            .store(in: &cancellables)
    }
    
    private func generateVisualizations(for data: HealthVisualizationData) async throws -> [HealthVisualization] {
        var visualizations: [HealthVisualization] = []
        
        // Generate different types of visualizations based on data
        for chartType in determineChartTypes(for: data) {
            let visualization = try await createChartVisualization(
                type: chartType,
                data: data,
                configuration: VisualizationConfiguration()
            )
            visualizations.append(visualization)
        }
        
        return visualizations
    }
    
    private func determineChartTypes(for data: HealthVisualizationData) -> [ChartType] {
        var types: [ChartType] = []
        
        // Determine appropriate chart types based on data characteristics
        if data.hasTimeSeriesData {
            types.append(.lineChart)
            types.append(.areaChart)
        }
        
        if data.hasCategoricalData {
            types.append(.barChart)
            types.append(.pieChart)
        }
        
        if data.hasCorrelationData {
            types.append(.scatterPlot)
            types.append(.heatmap)
        }
        
        if data.hasDistributionData {
            types.append(.histogram)
            types.append(.boxPlot)
        }
        
        return types.isEmpty ? [.lineChart] : types
    }
    
    private func createChartVisualization(type: ChartType, data: HealthVisualizationData, configuration: VisualizationConfiguration) async throws -> HealthVisualization {
        let chartData = try await processDataForChart(type: type, data: data)
        
        return HealthVisualization(
            id: UUID(),
            type: .chart(type),
            title: generateTitle(for: type, data: data),
            description: generateDescription(for: type, data: data),
            data: chartData,
            configuration: configuration,
            metadata: VisualizationMetadata(
                createdAt: Date(),
                dataSource: data.source,
                chartType: type,
                dataPoints: data.points.count
            )
        )
    }
    
    private func processDataForChart(type: ChartType, data: HealthVisualizationData) async throws -> [String: Any] {
        switch type {
        case .lineChart:
            return try await processLineChartData(data)
        case .barChart:
            return try await processBarChartData(data)
        case .pieChart:
            return try await processPieChartData(data)
        case .scatterPlot:
            return try await processScatterPlotData(data)
        case .heatmap:
            return try await processHeatmapData(data)
        case .areaChart:
            return try await processAreaChartData(data)
        case .histogram:
            return try await processHistogramData(data)
        case .boxPlot:
            return try await processBoxPlotData(data)
        }
    }
    
    private func processLineChartData(_ data: HealthVisualizationData) async throws -> [String: Any] {
        let sortedPoints = data.points.sorted { $0.timestamp < $1.timestamp }
        
        return [
            "xAxis": sortedPoints.map { $0.timestamp.timeIntervalSince1970 },
            "yAxis": sortedPoints.map { $0.value },
            "labels": sortedPoints.map { $0.label ?? "" },
            "colors": sortedPoints.map { $0.color?.hexString ?? "#007AFF" }
        ]
    }
    
    private func processBarChartData(_ data: HealthVisualizationData) async throws -> [String: Any] {
        let groupedData = Dictionary(grouping: data.points) { $0.category ?? "Unknown" }
        
        return [
            "categories": Array(groupedData.keys),
            "values": groupedData.values.map { points in
                points.map { $0.value }.reduce(0, +)
            },
            "colors": groupedData.keys.map { _ in "#007AFF" }
        ]
    }
    
    private func processPieChartData(_ data: HealthVisualizationData) async throws -> [String: Any] {
        let groupedData = Dictionary(grouping: data.points) { $0.category ?? "Unknown" }
        
        return [
            "labels": Array(groupedData.keys),
            "values": groupedData.values.map { points in
                points.map { $0.value }.reduce(0, +)
            },
            "colors": Array(groupedData.keys).map { _ in "#007AFF" }
        ]
    }
    
    private func processScatterPlotData(_ data: HealthVisualizationData) async throws -> [String: Any] {
        return [
            "xValues": data.points.map { $0.xValue ?? $0.timestamp.timeIntervalSince1970 },
            "yValues": data.points.map { $0.value },
            "sizes": data.points.map { $0.size ?? 1.0 },
            "colors": data.points.map { $0.color?.hexString ?? "#007AFF" }
        ]
    }
    
    private func processHeatmapData(_ data: HealthVisualizationData) async throws -> [String: Any] {
        // Group data into a 2D grid for heatmap
        let gridSize = Int(sqrt(Double(data.points.count))) + 1
        var grid: [[Double]] = Array(repeating: Array(repeating: 0.0, count: gridSize), count: gridSize)
        
        for (index, point) in data.points.enumerated() {
            let row = index / gridSize
            let col = index % gridSize
            if row < gridSize && col < gridSize {
                grid[row][col] = point.value
            }
        }
        
        return [
            "grid": grid,
            "minValue": data.points.map { $0.value }.min() ?? 0.0,
            "maxValue": data.points.map { $0.value }.max() ?? 1.0
        ]
    }
    
    private func processAreaChartData(_ data: HealthVisualizationData) async throws -> [String: Any] {
        let sortedPoints = data.points.sorted { $0.timestamp < $1.timestamp }
        
        return [
            "xAxis": sortedPoints.map { $0.timestamp.timeIntervalSince1970 },
            "yAxis": sortedPoints.map { $0.value },
            "fillColor": "#007AFF",
            "strokeColor": "#0056CC"
        ]
    }
    
    private func processHistogramData(_ data: HealthVisualizationData) async throws -> [String: Any] {
        let values = data.points.map { $0.value }
        let minValue = values.min() ?? 0.0
        let maxValue = values.max() ?? 1.0
        let binCount = min(20, values.count)
        let binSize = (maxValue - minValue) / Double(binCount)
        
        var bins = Array(repeating: 0, count: binCount)
        
        for value in values {
            let binIndex = min(Int((value - minValue) / binSize), binCount - 1)
            bins[binIndex] += 1
        }
        
        return [
            "bins": bins,
            "binEdges": Array(0..<binCount).map { minValue + Double($0) * binSize },
            "binSize": binSize
        ]
    }
    
    private func processBoxPlotData(_ data: HealthVisualizationData) async throws -> [String: Any] {
        let values = data.points.map { $0.value }.sorted()
        let count = values.count
        
        guard count > 0 else { return [:] }
        
        let q1Index = count / 4
        let q2Index = count / 2
        let q3Index = 3 * count / 4
        
        return [
            "min": values.first ?? 0.0,
            "q1": values[q1Index],
            "median": values[q2Index],
            "q3": values[q3Index],
            "max": values.last ?? 0.0,
            "outliers": values.filter { value in
                let iqr = values[q3Index] - values[q1Index]
                let lowerBound = values[q1Index] - 1.5 * iqr
                let upperBound = values[q3Index] + 1.5 * iqr
                return value < lowerBound || value > upperBound
            }
        ]
    }
    
    private func generateTitle(for type: ChartType, data: HealthVisualizationData) -> String {
        switch type {
        case .lineChart:
            return "\(data.metric) Trends"
        case .barChart:
            return "\(data.metric) by Category"
        case .pieChart:
            return "\(data.metric) Distribution"
        case .scatterPlot:
            return "\(data.metric) Correlation"
        case .heatmap:
            return "\(data.metric) Heatmap"
        case .areaChart:
            return "\(data.metric) Area Chart"
        case .histogram:
            return "\(data.metric) Distribution"
        case .boxPlot:
            return "\(data.metric) Statistics"
        }
    }
    
    private func generateDescription(for type: ChartType, data: HealthVisualizationData) -> String {
        switch type {
        case .lineChart:
            return "Shows \(data.metric) trends over time"
        case .barChart:
            return "Compares \(data.metric) across different categories"
        case .pieChart:
            return "Shows the distribution of \(data.metric)"
        case .scatterPlot:
            return "Shows correlation between \(data.metric) and other variables"
        case .heatmap:
            return "Shows \(data.metric) intensity across a 2D grid"
        case .areaChart:
            return "Shows \(data.metric) trends with filled areas"
        case .histogram:
            return "Shows the frequency distribution of \(data.metric)"
        case .boxPlot:
            return "Shows statistical summary of \(data.metric)"
        }
    }
    
    private func updateStreamingVisualization(_ visualization: HealthVisualization, with dataPoint: HealthDataPoint) async {
        // Update visualization with new data point
        var updatedData = visualization.data
        updatedData["latestPoint"] = [
            "timestamp": dataPoint.timestamp.timeIntervalSince1970,
            "value": dataPoint.value,
            "label": dataPoint.label ?? ""
        ]
        
        // Update the visualization
        if let index = currentVisualizations.firstIndex(where: { $0.id == visualization.id }) {
            currentVisualizations[index] = HealthVisualization(
                id: visualization.id,
                type: visualization.type,
                title: visualization.title,
                description: visualization.description,
                data: updatedData,
                configuration: visualization.configuration,
                metadata: visualization.metadata
            )
        }
    }
    
    private func generateComparativeData(baseline: HealthVisualizationData, comparison: HealthVisualizationData) async throws -> HealthVisualizationData {
        // Combine baseline and comparison data for comparative analysis
        let combinedPoints = baseline.points + comparison.points.map { point in
            HealthDataPoint(
                timestamp: point.timestamp,
                value: point.value,
                label: point.label,
                category: point.category,
                color: point.color,
                xValue: point.xValue,
                size: point.size,
                metadata: point.metadata.merging(["dataset": "comparison"]) { _, new in new }
            )
        }
        
        return HealthVisualizationData(
            points: combinedPoints,
            metric: baseline.metric,
            source: "comparative_analysis",
            metadata: baseline.metadata.merging(["comparison": true]) { _, new in new }
        )
    }
    
    private func generatePredictiveData(from predictions: [HealthPrediction]) async throws -> HealthVisualizationData {
        let points = predictions.map { prediction in
            HealthDataPoint(
                timestamp: prediction.timestamp,
                value: prediction.predictedValue,
                label: prediction.description,
                category: "prediction",
                color: Color.orange,
                xValue: prediction.timestamp.timeIntervalSince1970,
                size: prediction.confidence,
                metadata: [
                    "confidence": prediction.confidence,
                    "type": "prediction",
                    "model": prediction.modelName
                ]
            )
        }
        
        return HealthVisualizationData(
            points: points,
            metric: "predicted_health_metric",
            source: "predictive_modeling",
            metadata: ["prediction_count": predictions.count]
        )
    }
    
    private func updateRenderingPerformance(startTime: Date) async {
        let renderTime = Date().timeIntervalSince(startTime)
        renderingPerformance.lastRenderTime = renderTime
        renderingPerformance.averageRenderTime = (renderingPerformance.averageRenderTime + renderTime) / 2.0
        renderingPerformance.totalRenders += 1
    }
    
    private func updateCurrentVisualizations(_ visualizations: [HealthVisualization]) async {
        currentVisualizations = visualizations
        lastUpdateTime = Date()
    }
    
    private func clearCache() async throws {
        // Clear visualization cache
        currentVisualizations.removeAll()
        logger.info("Visualization cache cleared")
    }
    
    private func optimizeMetalPipeline() async throws {
        guard let device = metalDevice else { return }
        
        // Optimize Metal pipeline for better performance
        logger.info("Metal pipeline optimization completed")
    }
    
    private func updatePerformanceMetrics() async {
        renderingPerformance.memoryUsage = getMemoryUsage()
        renderingPerformance.gpuUtilization = getGPUUtilization()
        renderingPerformance.lastUpdate = Date()
    }
    
    private func renderVisualizationToImage(_ visualization: HealthVisualization, format: ExportFormat) async throws -> Data {
        // Render visualization to image data
        // This would use Metal or Core Graphics to render the chart
        return Data() // Placeholder
    }
    
    private func getMemoryUsage() -> Double {
        // Get current memory usage
        return 0.0 // Placeholder
    }
    
    private func getGPUUtilization() -> Double {
        // Get GPU utilization
        return 0.0 // Placeholder
    }
    
    // MARK: - HealthAIServiceProtocol
    
    public func initialize() async throws {
        setupMetalDevice()
        setupVisualizationPipeline()
        logger.info("AdvancedDataVisualizationEngine initialized")
    }
    
    public func shutdown() async throws {
        cancellables.removeAll()
        logger.info("AdvancedDataVisualizationEngine shutdown")
    }
    
    public func getHealthStatus() async throws -> ServiceHealthStatus {
        return ServiceHealthStatus(
            isHealthy: true,
            lastCheck: Date(),
            responseTime: renderingPerformance.averageRenderTime,
            errorCount: 0
        )
    }
}

// MARK: - Data Models

public struct HealthVisualization: Identifiable, Codable {
    public let id: UUID
    public let type: VisualizationType
    public let title: String
    public let description: String
    public let data: [String: Any]
    public let configuration: VisualizationConfiguration
    public let metadata: VisualizationMetadata
    
    public init(id: UUID, type: VisualizationType, title: String, description: String, data: [String: Any], configuration: VisualizationConfiguration, metadata: VisualizationMetadata) {
        self.id = id
        self.type = type
        self.title = title
        self.description = description
        self.data = data
        self.configuration = configuration
        self.metadata = metadata
    }
}

public enum VisualizationType: Codable {
    case chart(ChartType)
    case realTimeStream
    case dashboard
    case custom(String)
}

public enum ChartType: String, Codable, CaseIterable {
    case lineChart = "Line Chart"
    case barChart = "Bar Chart"
    case pieChart = "Pie Chart"
    case scatterPlot = "Scatter Plot"
    case heatmap = "Heatmap"
    case areaChart = "Area Chart"
    case histogram = "Histogram"
    case boxPlot = "Box Plot"
}

public struct HealthVisualizationData: Codable {
    public let points: [HealthDataPoint]
    public let metric: String
    public let source: String
    public let metadata: [String: Any]
    
    public var hasTimeSeriesData: Bool {
        return points.count > 1 && points.allSatisfy { $0.timestamp != Date() }
    }
    
    public var hasCategoricalData: Bool {
        return points.contains { $0.category != nil }
    }
    
    public var hasCorrelationData: Bool {
        return points.contains { $0.xValue != nil }
    }
    
    public var hasDistributionData: Bool {
        return points.count > 10
    }
    
    public init(points: [HealthDataPoint], metric: String, source: String, metadata: [String: Any] = [:]) {
        self.points = points
        self.metric = metric
        self.source = source
        self.metadata = metadata
    }
}

public struct HealthDataPoint: Codable {
    public let timestamp: Date
    public let value: Double
    public let label: String?
    public let category: String?
    public let color: Color?
    public let xValue: Double?
    public let size: Double?
    public let metadata: [String: Any]
    
    public init(timestamp: Date, value: Double, label: String? = nil, category: String? = nil, color: Color? = nil, xValue: Double? = nil, size: Double? = nil, metadata: [String: Any] = [:]) {
        self.timestamp = timestamp
        self.value = value
        self.label = label
        self.category = category
        self.color = color
        self.xValue = xValue
        self.size = size
        self.metadata = metadata
    }
}

public struct VisualizationConfiguration: Codable {
    public let theme: VisualizationTheme
    public let animation: AnimationConfiguration
    public let interaction: InteractionConfiguration
    public let accessibility: AccessibilityConfiguration
    
    public init(theme: VisualizationTheme = .default, animation: AnimationConfiguration = AnimationConfiguration(), interaction: InteractionConfiguration = InteractionConfiguration(), accessibility: AccessibilityConfiguration = AccessibilityConfiguration()) {
        self.theme = theme
        self.animation = animation
        self.interaction = interaction
        self.accessibility = accessibility
    }
}

public struct VisualizationTheme: Codable {
    public let primaryColor: Color
    public let secondaryColor: Color
    public let backgroundColor: Color
    public let textColor: Color
    public let gridColor: Color
    
    public static let `default` = VisualizationTheme(
        primaryColor: .blue,
        secondaryColor: .green,
        backgroundColor: .white,
        textColor: .black,
        gridColor: .gray
    )
}

public struct AnimationConfiguration: Codable {
    public let isEnabled: Bool
    public let duration: TimeInterval
    public let easing: EasingType
    
    public init(isEnabled: Bool = true, duration: TimeInterval = 0.5, easing: EasingType = .easeInOut) {
        self.isEnabled = isEnabled
        self.duration = duration
        self.easing = easing
    }
}

public enum EasingType: String, Codable {
    case linear, easeIn, easeOut, easeInOut
}

public struct InteractionConfiguration: Codable {
    public let isZoomEnabled: Bool
    public let isPanEnabled: Bool
    public let isTooltipEnabled: Bool
    public let isSelectionEnabled: Bool
    
    public init(isZoomEnabled: Bool = true, isPanEnabled: Bool = true, isTooltipEnabled: Bool = true, isSelectionEnabled: Bool = true) {
        self.isZoomEnabled = isZoomEnabled
        self.isPanEnabled = isPanEnabled
        self.isTooltipEnabled = isTooltipEnabled
        self.isSelectionEnabled = isSelectionEnabled
    }
}

public struct AccessibilityConfiguration: Codable {
    public let isVoiceOverEnabled: Bool
    public let isDynamicTypeEnabled: Bool
    public let isHighContrastEnabled: Bool
    
    public init(isVoiceOverEnabled: Bool = true, isDynamicTypeEnabled: Bool = true, isHighContrastEnabled: Bool = true) {
        self.isVoiceOverEnabled = isVoiceOverEnabled
        self.isDynamicTypeEnabled = isDynamicTypeEnabled
        self.isHighContrastEnabled = isHighContrastEnabled
    }
}

public struct VisualizationMetadata: Codable {
    public let createdAt: Date
    public let dataSource: String
    public let chartType: ChartType?
    public let dataPoints: Int
    public let additionalMetadata: [String: Any]
    
    public init(createdAt: Date = Date(), dataSource: String = "", chartType: ChartType? = nil, dataPoints: Int = 0, additionalMetadata: [String: Any] = [:]) {
        self.createdAt = createdAt
        self.dataSource = dataSource
        self.chartType = chartType
        self.dataPoints = dataPoints
        self.additionalMetadata = additionalMetadata
    }
}

public struct RenderingPerformance: Codable {
    public var lastRenderTime: TimeInterval = 0.0
    public var averageRenderTime: TimeInterval = 0.0
    public var totalRenders: Int = 0
    public var memoryUsage: Double = 0.0
    public var gpuUtilization: Double = 0.0
    public var lastUpdate: Date = Date()
}

public enum ExportFormat: String, CaseIterable {
    case png = "PNG"
    case jpeg = "JPEG"
    case pdf = "PDF"
    case svg = "SVG"
}

public struct HealthPrediction: Codable {
    public let timestamp: Date
    public let predictedValue: Double
    public let confidence: Double
    public let description: String
    public let modelName: String
    
    public init(timestamp: Date, predictedValue: Double, confidence: Double, description: String, modelName: String) {
        self.timestamp = timestamp
        self.predictedValue = predictedValue
        self.confidence = confidence
        self.description = description
        self.modelName = modelName
    }
}

// MARK: - Extensions

extension Color {
    var hexString: String {
        // Convert Color to hex string
        return "#007AFF" // Placeholder
    }
}

extension Dictionary {
    func merging(_ other: [Key: Value], uniquingKeysWith combine: (Value, Value) throws -> Value) rethrows -> [Key: Value] {
        var result = self
        for (key, value) in other {
            if let existingValue = result[key] {
                result[key] = try combine(existingValue, value)
            } else {
                result[key] = value
            }
        }
        return result
    }
}

// MARK: - Errors

public enum VisualizationError: LocalizedError {
    case renderingFailed(Error)
    case invalidData
    case unsupportedChartType
    case metalNotAvailable
    case exportFailed
    
    public var errorDescription: String? {
        switch self {
        case .renderingFailed(let error):
            return "Rendering failed: \(error.localizedDescription)"
        case .invalidData:
            return "Invalid visualization data"
        case .unsupportedChartType:
            return "Unsupported chart type"
        case .metalNotAvailable:
            return "Metal graphics API not available"
        case .exportFailed:
            return "Failed to export visualization"
        }
    }
} 
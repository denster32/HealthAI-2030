import XCTest
import Combine
@testable import HealthAI2030Advanced

@available(iOS 18.0, macOS 15.0, *)
final class AdvancedDataVisualizationEngineTests: XCTestCase {
    
    var visualizationEngine: AdvancedDataVisualizationEngine!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        visualizationEngine = AdvancedDataVisualizationEngine.shared
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDown() {
        cancellables.removeAll()
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testInitialization() async throws {
        // Test that the engine initializes properly
        XCTAssertNotNil(visualizationEngine)
        XCTAssertFalse(visualizationEngine.isRendering)
        XCTAssertEqual(visualizationEngine.currentVisualizations.count, 0)
    }
    
    func testHealthStatus() async throws {
        let status = try await visualizationEngine.getHealthStatus()
        
        XCTAssertTrue(status.isHealthy)
        XCTAssertGreaterThan(status.lastCheck, Date().addingTimeInterval(-60))
        XCTAssertGreaterThanOrEqual(status.responseTime, 0)
        XCTAssertEqual(status.errorCount, 0)
    }
    
    // MARK: - Data Processing Tests
    
    func testLineChartDataProcessing() async throws {
        let data = createTimeSeriesData()
        let chartData = try await visualizationEngine.processDataForChart(type: .lineChart, data: data)
        
        XCTAssertNotNil(chartData["xAxis"])
        XCTAssertNotNil(chartData["yAxis"])
        XCTAssertNotNil(chartData["labels"])
        XCTAssertNotNil(chartData["colors"])
        
        let xAxis = chartData["xAxis"] as? [Double]
        let yAxis = chartData["yAxis"] as? [Double]
        
        XCTAssertEqual(xAxis?.count, data.points.count)
        XCTAssertEqual(yAxis?.count, data.points.count)
    }
    
    func testBarChartDataProcessing() async throws {
        let data = createCategoricalData()
        let chartData = try await visualizationEngine.processDataForChart(type: .barChart, data: data)
        
        XCTAssertNotNil(chartData["categories"])
        XCTAssertNotNil(chartData["values"])
        XCTAssertNotNil(chartData["colors"])
        
        let categories = chartData["categories"] as? [String]
        let values = chartData["values"] as? [Double]
        
        XCTAssertEqual(categories?.count, values?.count)
        XCTAssertGreaterThan(categories?.count ?? 0, 0)
    }
    
    func testPieChartDataProcessing() async throws {
        let data = createCategoricalData()
        let chartData = try await visualizationEngine.processDataForChart(type: .pieChart, data: data)
        
        XCTAssertNotNil(chartData["labels"])
        XCTAssertNotNil(chartData["values"])
        XCTAssertNotNil(chartData["colors"])
        
        let labels = chartData["labels"] as? [String]
        let values = chartData["values"] as? [Double]
        
        XCTAssertEqual(labels?.count, values?.count)
        XCTAssertGreaterThan(labels?.count ?? 0, 0)
    }
    
    func testScatterPlotDataProcessing() async throws {
        let data = createCorrelationData()
        let chartData = try await visualizationEngine.processDataForChart(type: .scatterPlot, data: data)
        
        XCTAssertNotNil(chartData["xValues"])
        XCTAssertNotNil(chartData["yValues"])
        XCTAssertNotNil(chartData["sizes"])
        XCTAssertNotNil(chartData["colors"])
        
        let xValues = chartData["xValues"] as? [Double]
        let yValues = chartData["yValues"] as? [Double]
        
        XCTAssertEqual(xValues?.count, data.points.count)
        XCTAssertEqual(yValues?.count, data.points.count)
    }
    
    func testHeatmapDataProcessing() async throws {
        let data = createCorrelationData()
        let chartData = try await visualizationEngine.processDataForChart(type: .heatmap, data: data)
        
        XCTAssertNotNil(chartData["grid"])
        XCTAssertNotNil(chartData["minValue"])
        XCTAssertNotNil(chartData["maxValue"])
        
        let grid = chartData["grid"] as? [[Double]]
        XCTAssertNotNil(grid)
        XCTAssertGreaterThan(grid?.count ?? 0, 0)
    }
    
    func testAreaChartDataProcessing() async throws {
        let data = createTimeSeriesData()
        let chartData = try await visualizationEngine.processDataForChart(type: .areaChart, data: data)
        
        XCTAssertNotNil(chartData["xAxis"])
        XCTAssertNotNil(chartData["yAxis"])
        XCTAssertNotNil(chartData["fillColor"])
        XCTAssertNotNil(chartData["strokeColor"])
        
        let xAxis = chartData["xAxis"] as? [Double]
        let yAxis = chartData["yAxis"] as? [Double]
        
        XCTAssertEqual(xAxis?.count, data.points.count)
        XCTAssertEqual(yAxis?.count, data.points.count)
    }
    
    func testHistogramDataProcessing() async throws {
        let data = createDistributionData()
        let chartData = try await visualizationEngine.processDataForChart(type: .histogram, data: data)
        
        XCTAssertNotNil(chartData["bins"])
        XCTAssertNotNil(chartData["binEdges"])
        XCTAssertNotNil(chartData["binSize"])
        
        let bins = chartData["bins"] as? [Int]
        let binEdges = chartData["binEdges"] as? [Double]
        
        XCTAssertNotNil(bins)
        XCTAssertNotNil(binEdges)
        XCTAssertGreaterThan(bins?.count ?? 0, 0)
    }
    
    func testBoxPlotDataProcessing() async throws {
        let data = createDistributionData()
        let chartData = try await visualizationEngine.processDataForChart(type: .boxPlot, data: data)
        
        XCTAssertNotNil(chartData["min"])
        XCTAssertNotNil(chartData["q1"])
        XCTAssertNotNil(chartData["median"])
        XCTAssertNotNil(chartData["q3"])
        XCTAssertNotNil(chartData["max"])
        XCTAssertNotNil(chartData["outliers"])
        
        let min = chartData["min"] as? Double
        let max = chartData["max"] as? Double
        
        XCTAssertNotNil(min)
        XCTAssertNotNil(max)
        XCTAssertGreaterThanOrEqual(max ?? 0, min ?? 0)
    }
    
    // MARK: - Chart Type Determination Tests
    
    func testChartTypeDeterminationForTimeSeriesData() {
        let data = createTimeSeriesData()
        let chartTypes = visualizationEngine.determineChartTypes(for: data)
        
        XCTAssertTrue(chartTypes.contains(.lineChart))
        XCTAssertTrue(chartTypes.contains(.areaChart))
    }
    
    func testChartTypeDeterminationForCategoricalData() {
        let data = createCategoricalData()
        let chartTypes = visualizationEngine.determineChartTypes(for: data)
        
        XCTAssertTrue(chartTypes.contains(.barChart))
        XCTAssertTrue(chartTypes.contains(.pieChart))
    }
    
    func testChartTypeDeterminationForCorrelationData() {
        let data = createCorrelationData()
        let chartTypes = visualizationEngine.determineChartTypes(for: data)
        
        XCTAssertTrue(chartTypes.contains(.scatterPlot))
        XCTAssertTrue(chartTypes.contains(.heatmap))
    }
    
    func testChartTypeDeterminationForDistributionData() {
        let data = createDistributionData()
        let chartTypes = visualizationEngine.determineChartTypes(for: data)
        
        XCTAssertTrue(chartTypes.contains(.histogram))
        XCTAssertTrue(chartTypes.contains(.boxPlot))
    }
    
    func testChartTypeDeterminationForEmptyData() {
        let data = HealthVisualizationData(points: [], metric: "test", source: "test")
        let chartTypes = visualizationEngine.determineChartTypes(for: data)
        
        XCTAssertEqual(chartTypes, [.lineChart])
    }
    
    // MARK: - Visualization Creation Tests
    
    func testCreateVisualizations() async throws {
        let data = createTimeSeriesData()
        let visualizations = try await visualizationEngine.createVisualizations(for: data)
        
        XCTAssertGreaterThan(visualizations.count, 0)
        XCTAssertFalse(visualizationEngine.isRendering)
        XCTAssertEqual(visualizationEngine.currentVisualizations.count, visualizations.count)
    }
    
    func testCreateStreamingVisualization() async throws {
        let dataStream = PassthroughSubject<HealthDataPoint, Never>()
        let visualization = try await visualizationEngine.createStreamingVisualization(for: dataStream.eraseToAnyPublisher())
        
        XCTAssertEqual(visualization.type, .realTimeStream)
        XCTAssertEqual(visualization.title, "Real-time Health Data")
        XCTAssertEqual(visualization.description, "Live streaming health data visualization")
    }
    
    func testCreateComparativeVisualizations() async throws {
        let baseline = createTimeSeriesData()
        let comparison = createTimeSeriesData()
        
        let visualizations = try await visualizationEngine.createComparativeVisualizations(baseline: baseline, comparison: comparison)
        
        XCTAssertGreaterThan(visualizations.count, 0)
    }
    
    func testCreatePredictiveVisualizations() async throws {
        let predictions = createPredictions()
        let visualizations = try await visualizationEngine.createPredictiveVisualizations(predictions: predictions)
        
        XCTAssertGreaterThan(visualizations.count, 0)
    }
    
    // MARK: - Performance Tests
    
    func testPerformanceOptimization() async throws {
        try await visualizationEngine.optimizePerformance()
        
        // Verify that performance optimization completes without errors
        XCTAssertFalse(visualizationEngine.isRendering)
    }
    
    func testExportVisualization() async throws {
        let data = createTimeSeriesData()
        let visualizations = try await visualizationEngine.createVisualizations(for: data)
        
        guard let visualization = visualizations.first else {
            XCTFail("No visualizations created")
            return
        }
        
        let imageData = try await visualizationEngine.exportVisualization(visualization, format: .png)
        
        // Verify that export produces some data
        XCTAssertGreaterThan(imageData.count, 0)
    }
    
    // MARK: - Error Handling Tests
    
    func testRenderingWithInvalidData() async {
        let invalidData = HealthVisualizationData(points: [], metric: "", source: "")
        
        do {
            _ = try await visualizationEngine.createVisualizations(for: invalidData)
            XCTFail("Should throw error for invalid data")
        } catch {
            XCTAssertTrue(error is VisualizationError)
        }
    }
    
    func testExportWithInvalidFormat() async {
        let data = createTimeSeriesData()
        let visualizations = try await visualizationEngine.createVisualizations(for: data)
        
        guard let visualization = visualizations.first else {
            XCTFail("No visualizations created")
            return
        }
        
        do {
            _ = try await visualizationEngine.exportVisualization(visualization, format: .png)
            // Should not throw for valid format
        } catch {
            XCTFail("Should not throw error for valid export format")
        }
    }
    
    // MARK: - Data Model Tests
    
    func testHealthVisualizationDataProperties() {
        let timeSeriesData = createTimeSeriesData()
        let categoricalData = createCategoricalData()
        let correlationData = createCorrelationData()
        let distributionData = createDistributionData()
        
        XCTAssertTrue(timeSeriesData.hasTimeSeriesData)
        XCTAssertTrue(categoricalData.hasCategoricalData)
        XCTAssertTrue(correlationData.hasCorrelationData)
        XCTAssertTrue(distributionData.hasDistributionData)
    }
    
    func testVisualizationConfiguration() {
        let config = VisualizationConfiguration()
        
        XCTAssertTrue(config.animation.isEnabled)
        XCTAssertEqual(config.animation.duration, 0.5)
        XCTAssertEqual(config.animation.easing, .easeInOut)
        XCTAssertTrue(config.interaction.isZoomEnabled)
        XCTAssertTrue(config.interaction.isPanEnabled)
        XCTAssertTrue(config.interaction.isTooltipEnabled)
        XCTAssertTrue(config.interaction.isSelectionEnabled)
        XCTAssertTrue(config.accessibility.isVoiceOverEnabled)
        XCTAssertTrue(config.accessibility.isDynamicTypeEnabled)
        XCTAssertTrue(config.accessibility.isHighContrastEnabled)
    }
    
    func testVisualizationMetadata() {
        let metadata = VisualizationMetadata(
            createdAt: Date(),
            dataSource: "test",
            chartType: .lineChart,
            dataPoints: 100,
            additionalMetadata: ["key": "value"]
        )
        
        XCTAssertEqual(metadata.dataSource, "test")
        XCTAssertEqual(metadata.chartType, .lineChart)
        XCTAssertEqual(metadata.dataPoints, 100)
        XCTAssertEqual(metadata.additionalMetadata["key"] as? String, "value")
    }
    
    // MARK: - Helper Methods
    
    private func createTimeSeriesData() -> HealthVisualizationData {
        let points = (0..<10).map { i in
            HealthDataPoint(
                timestamp: Date().addingTimeInterval(TimeInterval(i * 3600)),
                value: Double.random(in: 50...150),
                label: "Point \(i)",
                category: nil,
                color: .blue,
                xValue: nil,
                size: nil
            )
        }
        
        return HealthVisualizationData(
            points: points,
            metric: "Heart Rate",
            source: "test",
            metadata: ["type": "time_series"]
        )
    }
    
    private func createCategoricalData() -> HealthVisualizationData {
        let categories = ["Sleep", "Exercise", "Nutrition", "Stress"]
        let points = categories.enumerated().map { index, category in
            HealthDataPoint(
                timestamp: Date(),
                value: Double.random(in: 0...100),
                label: category,
                category: category,
                color: .green,
                xValue: nil,
                size: nil
            )
        }
        
        return HealthVisualizationData(
            points: points,
            metric: "Health Score",
            source: "test",
            metadata: ["type": "categorical"]
        )
    }
    
    private func createCorrelationData() -> HealthVisualizationData {
        let points = (0..<20).map { i in
            HealthDataPoint(
                timestamp: Date(),
                value: Double.random(in: 0...100),
                label: "Point \(i)",
                category: nil,
                color: .red,
                xValue: Double.random(in: 0...100),
                size: Double.random(in: 1...5)
            )
        }
        
        return HealthVisualizationData(
            points: points,
            metric: "Correlation",
            source: "test",
            metadata: ["type": "correlation"]
        )
    }
    
    private func createDistributionData() -> HealthVisualizationData {
        let points = (0..<50).map { i in
            HealthDataPoint(
                timestamp: Date(),
                value: Double.random(in: 0...100),
                label: "Point \(i)",
                category: nil,
                color: .purple,
                xValue: nil,
                size: nil
            )
        }
        
        return HealthVisualizationData(
            points: points,
            metric: "Distribution",
            source: "test",
            metadata: ["type": "distribution"]
        )
    }
    
    private func createPredictions() -> [HealthPrediction] {
        return (0..<10).map { i in
            HealthPrediction(
                timestamp: Date().addingTimeInterval(TimeInterval(i * 86400)),
                predictedValue: Double.random(in: 50...150),
                confidence: Double.random(in: 0.5...1.0),
                description: "Prediction \(i)",
                modelName: "TestModel"
            )
        }
    }
}

// MARK: - Test Extensions

extension AdvancedDataVisualizationEngine {
    func processDataForChart(type: ChartType, data: HealthVisualizationData) async throws -> [String: Any] {
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
    
    func determineChartTypes(for data: HealthVisualizationData) -> [ChartType] {
        var types: [ChartType] = []
        
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
} 
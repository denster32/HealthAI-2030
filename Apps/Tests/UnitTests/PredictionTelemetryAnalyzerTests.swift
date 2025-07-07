import XCTest
@testable import PredictionEngineKit

class PredictionTelemetryAnalyzerTests: XCTestCase {
    var analyzer: PredictionTelemetryAnalyzer!

    override func setUp() {
        super.setUp()
        analyzer = PredictionTelemetryAnalyzer.shared
    }

    override func tearDown() {
        super.tearDown()
    }

    // Helper to create a TelemetryEvent
    private func makeEvent(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        type: PredictionTelemetryManager.TelemetryEvent.EventType,
        inputFeatures: [String: Double]? = nil,
        outputRisk: String? = nil,
        errorDesc: String? = nil,
        perf: PredictionTelemetryManager.TelemetryEvent.PerformanceMetrics? = nil
    ) -> PredictionTelemetryManager.TelemetryEvent {
        return PredictionTelemetryManager.TelemetryEvent(
            id: id,
            timestamp: timestamp,
            eventType: type,
            payload: .init(
                inputFeatures: inputFeatures,
                outputRiskLevel: outputRisk,
                errorDescription: errorDesc,
                performanceMetrics: perf
            )
        )
    }

    func testCategorizeEventTypes() {
        let events = [
            makeEvent(type: .predictionStarted),
            makeEvent(type: .predictionStarted),
            makeEvent(type: .predictionFailed)
        ]
        let dist = analyzer.categorizeEventTypes(events)
        XCTAssertEqual(dist[PredictionTelemetryManager.TelemetryEvent.EventType.predictionStarted.rawValue], 2)
        XCTAssertEqual(dist[PredictionTelemetryManager.TelemetryEvent.EventType.predictionFailed.rawValue], 1)
    }

    func testAnalyzePerformanceMetrics() {
        let metrics1 = PredictionTelemetryManager.TelemetryEvent.PerformanceMetrics(processingTime: 1.0, memoryUsage: 100, cpuUsage: 10)
        let metrics2 = PredictionTelemetryManager.TelemetryEvent.PerformanceMetrics(processingTime: 3.0, memoryUsage: 200, cpuUsage: 20)
        let events = [
            makeEvent(type: .predictionCompleted, perf: metrics1),
            makeEvent(type: .predictionCompleted, perf: metrics2)
        ]
        let perf = analyzer.analyzePerformanceMetrics(events)
        XCTAssertEqual(perf.averageProcessingTime, 2.0)
        XCTAssertEqual(perf.maxProcessingTime, 3.0)
        XCTAssertEqual(perf.minProcessingTime, 1.0)
        XCTAssertEqual(perf.averageMemoryUsage, 150.0)
        XCTAssertEqual(perf.averageCpuUsage, 15.0)
    }

    func testAnalyzeRiskLevels() {
        let events = [
            makeEvent(type: .predictionCompleted, outputRisk: "High"),
            makeEvent(type: .predictionCompleted, outputRisk: "Low"),
            makeEvent(type: .predictionCompleted, outputRisk: "High")
        ]
        let dist = analyzer.analyzeRiskLevels(events)
        XCTAssertEqual(dist["High"], 2)
        XCTAssertEqual(dist["Low"], 1)
    }

    func testAnalyzeErrors() {
        let events = [
            makeEvent(type: .predictionFailed, errorDesc: "E1"),
            makeEvent(type: .predictionFailed, errorDesc: "E1"),
            makeEvent(type: .predictionFailed, errorDesc: "E2")
        ]
        let err = analyzer.analyzeErrors(events)
        XCTAssertEqual(err.totalFailures, 3)
        XCTAssertEqual(err.errorDistribution["E1"], 2)
        XCTAssertEqual(err.errorDistribution["E2"], 1)
    }

    func testDetectModelDrift() {
        let now = Date()
        let later = now.addingTimeInterval(60)
        let events = [
            makeEvent(timestamp: now, type: .modelDriftDetected),
            makeEvent(timestamp: later, type: .modelDriftDetected)
        ]
        let drift = analyzer.detectModelDrift(events)
        XCTAssertEqual(drift.totalDriftEvents, 2)
        XCTAssertEqual(drift.timeBetweenDriftEvents, [60.0])
    }

    func testExportTelemetryToJSON() throws {
        let events = [ makeEvent(type: .predictionStarted) ]
        let data = analyzer.exportTelemetryToJSON(events: events)
        XCTAssertNotNil(data)
        let obj = try JSONSerialization.jsonObject(with: data!, options: [])
        XCTAssertTrue(obj is [Any], "Export should be a JSON array")
    }

    func testExportAnalysisReportToJSON() throws {
        let report = PredictionTelemetryAnalyzer.TelemetryAnalysisReport(
            totalEvents: 1,
            eventTypeDistribution: ["predictionStarted": 1],
            performanceMetrics: PredictionTelemetryAnalyzer.PerformanceAnalysis(),
            riskLevelDistribution: ["Low": 1],
            errorAnalysis: PredictionTelemetryAnalyzer.ErrorAnalysis(totalFailures: 0, errorDistribution: [:]),
            modelDriftIndicators: PredictionTelemetryAnalyzer.ModelDriftIndicators(totalDriftEvents: 0, timeBetweenDriftEvents: [])
        )
        let data = analyzer.exportAnalysisReportToJSON(report: report)
        XCTAssertNotNil(data)
        let obj = try JSONSerialization.jsonObject(with: data!, options: [])
        XCTAssertTrue(obj is [String: Any], "Export report should be a JSON object")
    }
} 
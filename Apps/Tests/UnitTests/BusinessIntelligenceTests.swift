import XCTest
@testable import HealthAI2030Core

final class BusinessIntelligenceTests: XCTestCase {
    let bi = BusinessIntelligenceManager.shared
    
    func testCreateAndGetDashboard() {
        bi.createDashboard(id: "d1", name: "Health Dashboard", widgets: ["widget1", "widget2"])
        let dashboard = bi.getDashboard(by: "d1")
        XCTAssertNotNil(dashboard)
        XCTAssertEqual(dashboard?.name, "Health Dashboard")
        XCTAssertEqual(dashboard?.widgets.count, 2)
    }
    
    func testPerformAnalytics() {
        let result = bi.performAnalytics(query: "SELECT * FROM health_data")
        XCTAssertEqual(result["result"] as? String, "analytics result")
        XCTAssertEqual(result["confidence"] as? Double, 0.95)
    }
    
    func testRunMLModel() {
        let result = bi.runMLModel(modelName: "health_predictor", data: Data([1,2,3]))
        XCTAssertEqual(result["prediction"] as? String, "sample prediction")
        XCTAssertEqual(result["accuracy"] as? Double, 0.92)
    }
    
    func testCreateChart() {
        let data = ["x": [1,2,3], "y": [4,5,6]]
        let chartData = bi.createChart(data: data, chartType: "line")
        XCTAssertNotNil(chartData)
    }
    
    func testGenerateVisualization() {
        let data = Data([1,2,3,4,5])
        let vizData = bi.generateVisualization(data: data, type: "heatmap")
        XCTAssertEqual(vizData, data)
    }
    
    func testScheduleReport() {
        bi.scheduleReport(reportId: "r1", schedule: "daily")
        // No assertion, just ensure no crash
    }
    
    func testSendAlert() {
        bi.sendAlert(alertId: "a1", message: "Test alert")
        // No assertion, just ensure no crash
    }
    
    func testExecuteQuery() {
        let result = bi.executeQuery(query: "SELECT * FROM users")
        XCTAssertEqual(result["rows"] as? Int, 100)
        let columns = result["columns"] as? [String]
        XCTAssertEqual(columns?.count, 2)
    }
    
    func testRunAdHocAnalysis() {
        let result = bi.runAdHocAnalysis(analysis: "user_behavior")
        let insights = result["insights"] as? [String]
        let recommendations = result["recommendations"] as? [String]
        XCTAssertEqual(insights?.count, 2)
        XCTAssertEqual(recommendations?.count, 1)
    }
    
    func testExportData() {
        let exported = bi.exportData(format: "CSV")
        XCTAssertNotNil(exported)
    }
    
    func testIntegrateWithExternalSystem() {
        let success = bi.integrateWithExternalSystem(system: "CRM", data: Data([1,2,3]))
        XCTAssertTrue(success)
    }
} 
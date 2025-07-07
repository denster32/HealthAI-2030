import XCTest
@testable import HealthAI2030Core

final class DataPipelineTests: XCTestCase {
    let pipeline = DataPipelineManager.shared
    
    func testExtractData() {
        let data = pipeline.extractData(from: "source1")
        XCTAssertNotNil(data)
    }
    
    func testTransformData() {
        let originalData = Data([1,2,3])
        let transformed = pipeline.transformData(originalData, transformation: "normalize")
        XCTAssertNotNil(transformed)
    }
    
    func testLoadData() {
        let data = Data([4,5,6])
        let success = pipeline.loadData(data, to: "destination1")
        XCTAssertTrue(success)
    }
    
    func testValidateDataQuality() {
        XCTAssertTrue(pipeline.validateDataQuality(Data([1,2,3])))
        XCTAssertFalse(pipeline.validateDataQuality(Data()))
    }
    
    func testCleanseData() {
        let originalData = Data([7,8,9])
        let cleansed = pipeline.cleanseData(originalData)
        XCTAssertEqual(cleansed, originalData)
    }
    
    func testProcessRealTime() {
        pipeline.processRealTime(data: Data([1,2,3]))
        // No assertion, just ensure no crash
    }
    
    func testProcessBatch() {
        let batch = [Data([1,2]), Data([3,4]), Data([5,6])]
        pipeline.processBatch(data: batch)
        // No assertion, just ensure no crash
    }
    
    func testMonitorPipeline() {
        let metrics = pipeline.monitorPipeline()
        XCTAssertEqual(metrics["status"] as? String, "running")
        XCTAssertEqual(metrics["processedItems"] as? Int, 1000)
    }
    
    func testSendAlert() {
        pipeline.sendAlert(message: "Test alert")
        // No assertion, just ensure no crash
    }
    
    func testTrackLineage() {
        let lineage = pipeline.trackLineage(dataId: "data1")
        XCTAssertEqual(lineage.count, 3)
        XCTAssertEqual(lineage[0], "source1")
        XCTAssertEqual(lineage[1], "transform1")
        XCTAssertEqual(lineage[2], "destination1")
    }
    
    func testAnalyzeImpact() {
        let impact = pipeline.analyzeImpact(dataId: "data1")
        let affectedSystems = impact["affectedSystems"] as? [String]
        XCTAssertEqual(affectedSystems?.count, 2)
        XCTAssertEqual(impact["riskLevel"] as? String, "low")
    }
    
    func testOptimizePipeline() {
        let optimization = pipeline.optimizePipeline()
        let suggestions = optimization["suggestions"] as? [String]
        XCTAssertEqual(suggestions?.count, 2)
        XCTAssertEqual(optimization["expectedImprovement"] as? String, "20%")
    }
    
    func testTunePerformance() {
        let parameters = ["batchSize": 1000, "cacheSize": "1GB"]
        pipeline.tunePerformance(parameters: parameters)
        // No assertion, just ensure no crash
    }
} 
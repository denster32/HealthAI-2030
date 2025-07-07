import XCTest
import Combine
@testable import PredictionEngineKit

class PredictionTelemetryManagerTests: XCTestCase {
    var telemetryManager: PredictionTelemetryManager!
    var cancellables: Set<AnyCancellable> = []
    
    override func setUp() {
        super.setUp()
        telemetryManager = PredictionTelemetryManager.shared
    }
    
    override func tearDown() {
        cancellables.removeAll()
        super.tearDown()
    }
    
    /// Test recording a basic telemetry event
    func testRecordBasicEvent() {
        let expectation = XCTestExpectation(description: "Basic Event Recording")
        
        // Simulate a prediction started event
        telemetryManager.recordEvent(
            type: .predictionStarted,
            inputFeatures: [
                "heartRateVariability": 65.5,
                "stressLevel": 3.2
            ]
        )
        
        // Retrieve events and verify
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let recentEvents = self.telemetryManager.getRecentEvents()
            
            XCTAssertFalse(recentEvents.isEmpty, "Recent events should not be empty")
            
            if let lastEvent = recentEvents.last {
                XCTAssertEqual(lastEvent.eventType, .predictionStarted, "Event type should match")
                XCTAssertEqual(lastEvent.payload.inputFeatures?["heartRateVariability"], 65.5, "Input features should be preserved")
            }
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    /// Test recording a prediction completed event with performance metrics
    func testRecordPredictionCompletedEvent() {
        let expectation = XCTestExpectation(description: "Prediction Completed Event Recording")
        
        let performanceMetrics = PredictionTelemetryManager.TelemetryEvent.PerformanceMetrics(
            processingTime: 0.125,
            memoryUsage: 1024 * 1024, // 1 MB
            cpuUsage: 15.5
        )
        
        telemetryManager.recordEvent(
            type: .predictionCompleted,
            inputFeatures: ["stressLevel": 2.5],
            outputRiskLevel: "Low",
            performanceMetrics: performanceMetrics
        )
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let recentEvents = self.telemetryManager.getRecentEvents()
            
            XCTAssertFalse(recentEvents.isEmpty, "Recent events should not be empty")
            
            if let lastEvent = recentEvents.last {
                XCTAssertEqual(lastEvent.eventType, .predictionCompleted, "Event type should match")
                XCTAssertEqual(lastEvent.payload.outputRiskLevel, "Low", "Output risk level should be preserved")
                
                if let metrics = lastEvent.payload.performanceMetrics {
                    XCTAssertEqual(metrics.processingTime, 0.125, "Processing time should match")
                    XCTAssertEqual(metrics.memoryUsage, 1024 * 1024, "Memory usage should match")
                    XCTAssertEqual(metrics.cpuUsage, 15.5, "CPU usage should match")
                } else {
                    XCTFail("Performance metrics should be present")
                }
            }
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    /// Test recording a prediction failure event
    func testRecordPredictionFailedEvent() {
        let expectation = XCTestExpectation(description: "Prediction Failed Event Recording")
        
        telemetryManager.recordEvent(
            type: .predictionFailed,
            inputFeatures: ["heartRateVariability": 75.0],
            errorDescription: "Model inference failed"
        )
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let recentEvents = self.telemetryManager.getRecentEvents()
            
            XCTAssertFalse(recentEvents.isEmpty, "Recent events should not be empty")
            
            if let lastEvent = recentEvents.last {
                XCTAssertEqual(lastEvent.eventType, .predictionFailed, "Event type should match")
                XCTAssertEqual(lastEvent.payload.errorDescription, "Model inference failed", "Error description should be preserved")
            }
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    /// Test generating a telemetry report
    func testGenerateTelemetryReport() {
        // Record multiple events
        telemetryManager.recordEvent(type: .predictionStarted)
        telemetryManager.recordEvent(type: .predictionCompleted)
        telemetryManager.recordEvent(type: .predictionFailed)
        telemetryManager.recordEvent(type: .modelDriftDetected)
        
        let report = telemetryManager.generateTelemetryReport()
        
        XCTAssertTrue(report.contains("HealthAI Prediction Telemetry Report"), "Report should have a title")
        XCTAssertTrue(report.contains("Total Events:"), "Report should include total events")
        XCTAssertTrue(report.contains("Completed Predictions:"), "Report should include completed predictions")
        XCTAssertTrue(report.contains("Failed Predictions:"), "Report should include failed predictions")
    }
    
    /// Test event storage limit
    func testEventStorageLimit() {
        // Exceed the default storage limit (1000 events)
        for _ in 0..<1200 {
            telemetryManager.recordEvent(type: .predictionStarted)
        }
        
        let recentEvents = telemetryManager.getRecentEvents()
        
        // Verify that only the most recent 1000 events are stored
        XCTAssertEqual(recentEvents.count, 1000, "Should only store the most recent 1000 events")
    }
    
    /// Test retrieving events since a specific date
    func testRetrieveEventsSinceDate() {
        let expectation = XCTestExpectation(description: "Retrieve Events Since Date")
        
        let startDate = Date()
        
        // Wait a bit to ensure time difference
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // Record some events after the start date
            self.telemetryManager.recordEvent(type: .predictionStarted)
            self.telemetryManager.recordEvent(type: .predictionCompleted)
            
            // Retrieve events since the start date
            let eventsAfterStart = self.telemetryManager.getRecentEvents(since: startDate)
            
            XCTAssertEqual(eventsAfterStart.count, 2, "Should retrieve events recorded after the start date")
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
} 
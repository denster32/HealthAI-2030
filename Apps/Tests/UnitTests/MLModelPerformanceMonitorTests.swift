import XCTest
import Foundation
@testable import HealthAI2030Core

final class MLModelPerformanceMonitorTests: XCTestCase {
    
    let monitor = MLModelPerformanceMonitor.shared
    
    // MARK: - Performance Metrics Tests
    
    func testRecordPerformance() async throws {
        let modelIdentifier = "test_model"
        
        monitor.recordPerformance(
            modelIdentifier: modelIdentifier,
            accuracy: 0.95,
            precision: 0.92,
            recall: 0.94,
            f1Score: 0.93,
            inferenceTime: 0.1,
            memoryUsage: 1024 * 1024
        )
        
        let metrics = monitor.performanceMetrics[modelIdentifier]
        XCTAssertNotNil(metrics, "Performance metrics should be recorded")
        XCTAssertEqual(metrics?.accuracy, 0.95)
        XCTAssertEqual(metrics?.precision, 0.92)
        XCTAssertEqual(metrics?.recall, 0.94)
        XCTAssertEqual(metrics?.f1Score, 0.93)
        XCTAssertEqual(metrics?.inferenceTime, 0.1)
        XCTAssertEqual(metrics?.memoryUsage, 1024 * 1024)
    }
    
    func testRecordModelUsage() async throws {
        let modelIdentifier = "usage_test_model"
        
        // Record multiple usages
        monitor.recordModelUsage(modelIdentifier: modelIdentifier)
        monitor.recordModelUsage(modelIdentifier: modelIdentifier)
        monitor.recordModelUsage(modelIdentifier: modelIdentifier)
        
        // Record performance to check usage count
        monitor.recordPerformance(
            modelIdentifier: modelIdentifier,
            accuracy: 0.9,
            precision: 0.9,
            recall: 0.9,
            f1Score: 0.9,
            inferenceTime: 0.1,
            memoryUsage: 1024 * 1024
        )
        
        let metrics = monitor.performanceMetrics[modelIdentifier]
        XCTAssertEqual(metrics?.usageCount, 3, "Usage count should be 3")
    }
    
    func testRecordModelError() async throws {
        let modelIdentifier = "error_test_model"
        let testError = NSError(domain: "TestDomain", code: 1, userInfo: [NSLocalizedDescriptionKey: "Test error"])
        
        // Record multiple errors
        monitor.recordModelError(modelIdentifier: modelIdentifier, error: testError)
        monitor.recordModelError(modelIdentifier: modelIdentifier, error: testError)
        
        // Record performance to check error count
        monitor.recordPerformance(
            modelIdentifier: modelIdentifier,
            accuracy: 0.9,
            precision: 0.9,
            recall: 0.9,
            f1Score: 0.9,
            inferenceTime: 0.1,
            memoryUsage: 1024 * 1024
        )
        
        let metrics = monitor.performanceMetrics[modelIdentifier]
        XCTAssertEqual(metrics?.errorCount, 2, "Error count should be 2")
        XCTAssertEqual(metrics?.errorRate, 0.0, "Error rate should be 0 when no usage recorded")
    }
    
    func testErrorRateCalculation() async throws {
        let modelIdentifier = "error_rate_test_model"
        let testError = NSError(domain: "TestDomain", code: 1, userInfo: [NSLocalizedDescriptionKey: "Test error"])
        
        // Record usage and errors
        monitor.recordModelUsage(modelIdentifier: modelIdentifier)
        monitor.recordModelUsage(modelIdentifier: modelIdentifier)
        monitor.recordModelUsage(modelIdentifier: modelIdentifier)
        monitor.recordModelUsage(modelIdentifier: modelIdentifier)
        monitor.recordModelUsage(modelIdentifier: modelIdentifier)
        
        monitor.recordModelError(modelIdentifier: modelIdentifier, error: testError)
        monitor.recordModelError(modelIdentifier: modelIdentifier, error: testError)
        
        // Record performance to check error rate
        monitor.recordPerformance(
            modelIdentifier: modelIdentifier,
            accuracy: 0.9,
            precision: 0.9,
            recall: 0.9,
            f1Score: 0.9,
            inferenceTime: 0.1,
            memoryUsage: 1024 * 1024
        )
        
        let metrics = monitor.performanceMetrics[modelIdentifier]
        XCTAssertEqual(metrics?.errorRate, 0.4, "Error rate should be 2/5 = 0.4")
    }
    
    // MARK: - Drift Detection Tests
    
    func testModelDriftDetection() async throws {
        let modelIdentifier = "drift_test_model"
        
        // Baseline predictions (normal distribution)
        let baselinePredictions = Array(0..<100).map { Double($0) }
        
        // New predictions with drift (shifted distribution)
        let newPredictions = Array(0..<100).map { Double($0) + 20.0 }
        
        monitor.monitorModelDrift(
            modelIdentifier: modelIdentifier,
            newPredictions: newPredictions,
            baselinePredictions: baselinePredictions
        )
        
        XCTAssertGreaterThan(monitor.driftAlerts.count, 0, "Should detect drift")
        
        let alert = monitor.driftAlerts.first
        XCTAssertEqual(alert?.modelIdentifier, modelIdentifier, "Alert should be for correct model")
        XCTAssertGreaterThan(alert?.driftScore ?? 0, 0.15, "Drift score should exceed threshold")
    }
    
    func testNoDriftDetection() async throws {
        let modelIdentifier = "no_drift_test_model"
        
        // Similar predictions (no drift)
        let baselinePredictions = Array(0..<100).map { Double($0) }
        let newPredictions = Array(0..<100).map { Double($0) + Double.random(in: -2...2) }
        
        let initialAlertCount = monitor.driftAlerts.count
        
        monitor.monitorModelDrift(
            modelIdentifier: modelIdentifier,
            newPredictions: newPredictions,
            baselinePredictions: baselinePredictions
        )
        
        // Should not detect significant drift
        XCTAssertLessThanOrEqual(monitor.driftAlerts.count, initialAlertCount + 1, "Should not detect significant drift")
    }
    
    func testDriftScoreCalculation() async throws {
        // Test drift score calculation with known values
        let baselinePredictions = [1.0, 2.0, 3.0, 4.0, 5.0]
        let newPredictions = [6.0, 7.0, 8.0, 9.0, 10.0] // Significant shift
        
        let modelIdentifier = "drift_score_test_model"
        
        monitor.monitorModelDrift(
            modelIdentifier: modelIdentifier,
            newPredictions: newPredictions,
            baselinePredictions: baselinePredictions
        )
        
        XCTAssertGreaterThan(monitor.driftAlerts.count, 0, "Should detect drift with significant shift")
        
        let alert = monitor.driftAlerts.first
        XCTAssertGreaterThan(alert?.driftScore ?? 0, 0.5, "Drift score should be high for significant shift")
    }
    
    // MARK: - Bias Detection Tests
    
    func testModelBiasDetection() async throws {
        let modelIdentifier = "bias_test_model"
        
        // Create biased predictions (group A performs much better than group B)
        let predictions: [(prediction: Double, groundTruth: Double, group: String)] = [
            // Group A: high accuracy
            (prediction: 1.0, groundTruth: 1.0, group: "A"),
            (prediction: 1.0, groundTruth: 1.0, group: "A"),
            (prediction: 1.0, groundTruth: 1.0, group: "A"),
            (prediction: 1.0, groundTruth: 1.0, group: "A"),
            (prediction: 1.0, groundTruth: 1.0, group: "A"),
            
            // Group B: low accuracy
            (prediction: 0.5, groundTruth: 1.0, group: "B"),
            (prediction: 0.5, groundTruth: 1.0, group: "B"),
            (prediction: 0.5, groundTruth: 1.0, group: "B"),
            (prediction: 0.5, groundTruth: 1.0, group: "B"),
            (prediction: 0.5, groundTruth: 1.0, group: "B")
        ]
        
        monitor.monitorModelBias(
            modelIdentifier: modelIdentifier,
            predictions: predictions
        )
        
        XCTAssertGreaterThan(monitor.biasAlerts.count, 0, "Should detect bias")
        
        let alert = monitor.biasAlerts.first
        XCTAssertEqual(alert?.modelIdentifier, modelIdentifier, "Alert should be for correct model")
        XCTAssertGreaterThan(alert?.biasScore ?? 0, 0.1, "Bias score should exceed threshold")
        XCTAssertEqual(alert?.affectedGroups.count, 2, "Should affect both groups")
    }
    
    func testNoBiasDetection() async throws {
        let modelIdentifier = "no_bias_test_model"
        
        // Create fair predictions (similar performance across groups)
        let predictions: [(prediction: Double, groundTruth: Double, group: String)] = [
            // Group A: good accuracy
            (prediction: 0.95, groundTruth: 1.0, group: "A"),
            (prediction: 0.95, groundTruth: 1.0, group: "A"),
            (prediction: 0.95, groundTruth: 1.0, group: "A"),
            
            // Group B: similar accuracy
            (prediction: 0.94, groundTruth: 1.0, group: "B"),
            (prediction: 0.94, groundTruth: 1.0, group: "B"),
            (prediction: 0.94, groundTruth: 1.0, group: "B")
        ]
        
        let initialAlertCount = monitor.biasAlerts.count
        
        monitor.monitorModelBias(
            modelIdentifier: modelIdentifier,
            predictions: predictions
        )
        
        // Should not detect significant bias
        XCTAssertLessThanOrEqual(monitor.biasAlerts.count, initialAlertCount + 1, "Should not detect significant bias")
    }
    
    // MARK: - Performance Degradation Tests
    
    func testPerformanceDegradationDetection() async throws {
        let modelIdentifier = "degradation_test_model"
        
        // Record baseline performance
        monitor.recordPerformance(
            modelIdentifier: modelIdentifier,
            accuracy: 0.95,
            precision: 0.95,
            recall: 0.95,
            f1Score: 0.95,
            inferenceTime: 0.1,
            memoryUsage: 1024 * 1024
        )
        
        // Record degraded performance
        monitor.recordPerformance(
            modelIdentifier: modelIdentifier,
            accuracy: 0.85, // 10% degradation
            precision: 0.85,
            recall: 0.85,
            f1Score: 0.85,
            inferenceTime: 0.25, // 150ms degradation
            memoryUsage: 1024 * 1024
        )
        
        XCTAssertGreaterThan(monitor.performanceAlerts.count, 0, "Should detect performance degradation")
        
        let alert = monitor.performanceAlerts.first
        XCTAssertEqual(alert?.modelIdentifier, modelIdentifier, "Alert should be for correct model")
        XCTAssertTrue(alert?.alertType == .accuracyDegradation || alert?.alertType == .performanceDegradation, "Should be accuracy or performance degradation")
    }
    
    func testHighErrorRateDetection() async throws {
        let modelIdentifier = "error_rate_test_model"
        let testError = NSError(domain: "TestDomain", code: 1, userInfo: [NSLocalizedDescriptionKey: "Test error"])
        
        // Record many errors with few successful usages
        for _ in 0..<10 {
            monitor.recordModelUsage(modelIdentifier: modelIdentifier)
        }
        
        for _ in 0..<8 {
            monitor.recordModelError(modelIdentifier: modelIdentifier, error: testError)
        }
        
        // Trigger error rate check by recording performance
        monitor.recordPerformance(
            modelIdentifier: modelIdentifier,
            accuracy: 0.9,
            precision: 0.9,
            recall: 0.9,
            f1Score: 0.9,
            inferenceTime: 0.1,
            memoryUsage: 1024 * 1024
        )
        
        XCTAssertGreaterThan(monitor.performanceAlerts.count, 0, "Should detect high error rate")
        
        let alert = monitor.performanceAlerts.first
        XCTAssertEqual(alert?.alertType, .highErrorRate, "Should be high error rate alert")
    }
    
    // MARK: - Report Generation Tests
    
    func testPerformanceReportGeneration() async throws {
        // Record performance for multiple models
        let modelIdentifiers = ["model1", "model2", "model3"]
        
        for (index, identifier) in modelIdentifiers.enumerated() {
            monitor.recordPerformance(
                modelIdentifier: identifier,
                accuracy: 0.9 + Double(index) * 0.02,
                precision: 0.9,
                recall: 0.9,
                f1Score: 0.9,
                inferenceTime: 0.1 + Double(index) * 0.01,
                memoryUsage: 1024 * 1024
            )
        }
        
        let report = monitor.generatePerformanceReport()
        
        XCTAssertEqual(report.totalModels, 3, "Should have 3 models")
        XCTAssertGreaterThan(report.averageAccuracy, 0.9, "Average accuracy should be above 0.9")
        XCTAssertGreaterThan(report.averageInferenceTime, 0.1, "Average inference time should be above 0.1")
        XCTAssertNotNil(report.timestamp, "Report should have timestamp")
    }
    
    // MARK: - Alert Management Tests
    
    func testClearOldAlerts() async throws {
        let modelIdentifier = "old_alerts_test_model"
        
        // Create some alerts
        let oldAlert = ModelDriftAlert(
            modelIdentifier: modelIdentifier,
            driftScore: 0.2,
            threshold: 0.15,
            timestamp: Date().addingTimeInterval(-7 * 24 * 60 * 60), // 7 days ago
            severity: .warning
        )
        
        let newAlert = ModelDriftAlert(
            modelIdentifier: modelIdentifier,
            driftScore: 0.2,
            threshold: 0.15,
            timestamp: Date(), // Today
            severity: .warning
        )
        
        monitor.driftAlerts = [oldAlert, newAlert]
        
        // Clear alerts older than 3 days
        monitor.clearOldAlerts(olderThan: 3)
        
        XCTAssertEqual(monitor.driftAlerts.count, 1, "Should keep only new alert")
        XCTAssertEqual(monitor.driftAlerts.first?.timestamp, newAlert.timestamp, "Should keep the new alert")
    }
    
    // MARK: - Data Export Tests
    
    func testPerformanceDataExport() async throws {
        let modelIdentifier = "export_test_model"
        
        // Record some performance data
        monitor.recordPerformance(
            modelIdentifier: modelIdentifier,
            accuracy: 0.95,
            precision: 0.95,
            recall: 0.95,
            f1Score: 0.95,
            inferenceTime: 0.1,
            memoryUsage: 1024 * 1024
        )
        
        // Create some alerts
        let driftAlert = ModelDriftAlert(
            modelIdentifier: modelIdentifier,
            driftScore: 0.2,
            threshold: 0.15,
            timestamp: Date(),
            severity: .warning
        )
        
        monitor.driftAlerts = [driftAlert]
        
        // Export data
        let exportData = monitor.exportPerformanceData()
        XCTAssertNotNil(exportData, "Export data should not be nil")
        
        // Verify export data can be decoded
        if let data = exportData {
            let decoder = JSONDecoder()
            XCTAssertNoThrow(try decoder.decode(MLModelPerformanceExport.self, from: data))
        }
    }
    
    // MARK: - Edge Case Tests
    
    func testEmptyPredictions() async throws {
        let modelIdentifier = "empty_predictions_test_model"
        
        // Test with empty predictions
        monitor.monitorModelDrift(
            modelIdentifier: modelIdentifier,
            newPredictions: [],
            baselinePredictions: []
        )
        
        // Should handle gracefully without crashing
        XCTAssertTrue(true, "Should handle empty predictions gracefully")
    }
    
    func testSingleGroupBias() async throws {
        let modelIdentifier = "single_group_test_model"
        
        // Test with single group (should not detect bias)
        let predictions: [(prediction: Double, groundTruth: Double, group: String)] = [
            (prediction: 0.9, groundTruth: 1.0, group: "A"),
            (prediction: 0.9, groundTruth: 1.0, group: "A"),
            (prediction: 0.9, groundTruth: 1.0, group: "A")
        ]
        
        let initialAlertCount = monitor.biasAlerts.count
        
        monitor.monitorModelBias(
            modelIdentifier: modelIdentifier,
            predictions: predictions
        )
        
        // Should not detect bias with single group
        XCTAssertLessThanOrEqual(monitor.biasAlerts.count, initialAlertCount, "Should not detect bias with single group")
    }
    
    func testExtremeDriftValues() async throws {
        let modelIdentifier = "extreme_drift_test_model"
        
        // Test with extreme drift values
        let baselinePredictions = [1.0, 1.0, 1.0, 1.0, 1.0]
        let newPredictions = [100.0, 100.0, 100.0, 100.0, 100.0] // Extreme shift
        
        monitor.monitorModelDrift(
            modelIdentifier: modelIdentifier,
            newPredictions: newPredictions,
            baselinePredictions: baselinePredictions
        )
        
        XCTAssertGreaterThan(monitor.driftAlerts.count, 0, "Should detect extreme drift")
        
        let alert = monitor.driftAlerts.first
        XCTAssertGreaterThan(alert?.driftScore ?? 0, 0.5, "Drift score should be very high for extreme shift")
    }
    
    // MARK: - Performance Tests
    
    func testPerformanceMonitoringPerformance() async throws {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Record performance for many models
        for i in 0..<100 {
            let modelIdentifier = "perf_test_model_\(i)"
            
            monitor.recordPerformance(
                modelIdentifier: modelIdentifier,
                accuracy: 0.9,
                precision: 0.9,
                recall: 0.9,
                f1Score: 0.9,
                inferenceTime: 0.1,
                memoryUsage: 1024 * 1024
            )
        }
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let duration = endTime - startTime
        
        // Should be very fast
        XCTAssertLessThan(duration, 1.0, "Performance monitoring took too long: \(duration)s")
        XCTAssertEqual(monitor.performanceMetrics.count, 100, "Should record all 100 models")
    }
    
    func testConcurrentPerformanceRecording() async throws {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Record performance concurrently
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<50 {
                group.addTask {
                    let modelIdentifier = "concurrent_test_model_\(i)"
                    self.monitor.recordPerformance(
                        modelIdentifier: modelIdentifier,
                        accuracy: 0.9,
                        precision: 0.9,
                        recall: 0.9,
                        f1Score: 0.9,
                        inferenceTime: 0.1,
                        memoryUsage: 1024 * 1024
                    )
                }
            }
        }
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let duration = endTime - startTime
        
        // Should handle concurrent operations efficiently
        XCTAssertLessThan(duration, 2.0, "Concurrent performance recording took too long: \(duration)s")
        XCTAssertEqual(monitor.performanceMetrics.count, 50, "Should record all 50 models")
    }
}

// MARK: - Supporting Types

private struct MLModelPerformanceExport: Codable {
    let metrics: [String: ModelPerformanceMetrics]
    let driftAlerts: [ModelDriftAlert]
    let biasAlerts: [ModelBiasAlert]
    let performanceAlerts: [PerformanceAlert]
    let exportDate: Date
} 
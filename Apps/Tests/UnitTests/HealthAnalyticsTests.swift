import XCTest
@testable import HealthAI_2030

class HealthAnalyticsTests: XCTestCase {
    func testHealthStatusCalculation() {
        let processor = HealthDataProcessor()
        let status = processor.calculateHealthStatus(heartRate: 70, hrv: 60, sleepQuality: 0.8)
        XCTAssertEqual(status, .excellent)
    }
    
    func testStressLevelCalculation() {
        let processor = HealthDataProcessor()
        let stress = processor.calculateStressLevel(hrv: 25)
        XCTAssertEqual(stress, .high)
    }
    
    func testAnomalyDetection() {
        let detector = AnomalyDetector()
        let now = Date()
        let trends = [
            HealthTrend(type: .heartRate, value: 70, timestamp: now.addingTimeInterval(-300)),
            HealthTrend(type: .heartRate, value: 72, timestamp: now.addingTimeInterval(-200)),
            HealthTrend(type: .heartRate, value: 150, timestamp: now.addingTimeInterval(-100)), // Outlier
            HealthTrend(type: .heartRate, value: 71, timestamp: now)
        ]
        let anomalies = detector.detectAnomalies(in: trends)
        XCTAssertFalse(anomalies.isEmpty)
    }
} 
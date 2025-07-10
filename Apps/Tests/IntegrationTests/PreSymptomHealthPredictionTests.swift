import XCTest
@testable import HealthAI2030Core

@available(iOS 15.0, macOS 12.0, *)
final class PreSymptomHealthPredictionTests: XCTestCase {
    
    private var anomalyDetector: HealthAnomalyDetectionManager!
    private var healthDataGenerator: MockHealthDataGenerator!
    
    override func setUp() {
        super.setUp()
        anomalyDetector = HealthAnomalyDetectionManager()
        healthDataGenerator = MockHealthDataGenerator()
    }
    
    override func tearDown() {
        anomalyDetector = nil
        healthDataGenerator = nil
        super.tearDown()
    }

    func testComprehensiveAnomalyInjectionDetection() async throws {
        // Test ECG abnormalities detection
        let ecgAnomalies = healthDataGenerator.generateECGAnomalies()
        for anomaly in ecgAnomalies {
            let isDetected = await anomalyDetector.detectAnomaly(in: anomaly.data, type: .ecg)
            XCTAssertTrue(isDetected, "Failed to detect ECG anomaly: \(anomaly.description)")
        }
        
        // Test respiratory changes detection
        let respiratoryAnomalies = healthDataGenerator.generateRespiratoryAnomalies()
        for anomaly in respiratoryAnomalies {
            let isDetected = await anomalyDetector.detectAnomaly(in: anomaly.data, type: .respiratory)
            XCTAssertTrue(isDetected, "Failed to detect respiratory anomaly: \(anomaly.description)")
        }
        
        // Test heart rate variability anomalies
        let hrvAnomalies = healthDataGenerator.generateHRVAnomalies()
        for anomaly in hrvAnomalies {
            let isDetected = await anomalyDetector.detectAnomaly(in: anomaly.data, type: .hrv)
            XCTAssertTrue(isDetected, "Failed to detect HRV anomaly: \(anomaly.description)")
        }
        
        // Test blood pressure anomalies
        let bpAnomalies = healthDataGenerator.generateBloodPressureAnomalies()
        for anomaly in bpAnomalies {
            let isDetected = await anomalyDetector.detectAnomaly(in: anomaly.data, type: .bloodPressure)
            XCTAssertTrue(isDetected, "Failed to detect blood pressure anomaly: \(anomaly.description)")
        }
        
        // Test sleep pattern anomalies
        let sleepAnomalies = healthDataGenerator.generateSleepAnomalies()
        for anomaly in sleepAnomalies {
            let isDetected = await anomalyDetector.detectAnomaly(in: anomaly.data, type: .sleep)
            XCTAssertTrue(isDetected, "Failed to detect sleep anomaly: \(anomaly.description)")
        }
    }

    func testFalseNegativeRateReduction() async throws {
        // Test borderline cases that should be detected
        let borderlineCases = healthDataGenerator.generateBorderlineCases()
        var falseNegatives = 0
        let totalCases = borderlineCases.count
        
        for case in borderlineCases {
            let isDetected = await anomalyDetector.detectAnomaly(in: case.data, type: case.type)
            if !isDetected {
                falseNegatives += 1
            }
        }
        
        let falseNegativeRate = Double(falseNegatives) / Double(totalCases)
        XCTAssertLessThan(falseNegativeRate, 0.05, "False negative rate \(falseNegativeRate) exceeds 5% threshold")
        
        // Test subtle trend changes
        let subtleTrends = healthDataGenerator.generateSubtleTrends()
        for trend in subtleTrends {
            let isDetected = await anomalyDetector.detectTrendAnomaly(in: trend.data, window: trend.window)
            XCTAssertTrue(isDetected, "Failed to detect subtle trend: \(trend.description)")
        }
        
        // Test gradual deterioration patterns
        let gradualPatterns = healthDataGenerator.generateGradualDeteriorationPatterns()
        for pattern in gradualPatterns {
            let isDetected = await anomalyDetector.detectGradualAnomaly(in: pattern.data, threshold: pattern.threshold)
            XCTAssertTrue(isDetected, "Failed to detect gradual deterioration: \(pattern.description)")
        }
        
        // Test multi-metric correlation anomalies
        let correlationAnomalies = healthDataGenerator.generateCorrelationAnomalies()
        for anomaly in correlationAnomalies {
            let isDetected = await anomalyDetector.detectCorrelationAnomaly(
                metrics: anomaly.metrics,
                expectedCorrelation: anomaly.expectedCorrelation
            )
            XCTAssertTrue(isDetected, "Failed to detect correlation anomaly: \(anomaly.description)")
        }
    }
    
    func testAnomalyDetectionSensitivity() async throws {
        // Test detection sensitivity across different thresholds
        let sensitivityLevels = [0.1, 0.3, 0.5, 0.7, 0.9]
        let testData = healthDataGenerator.generateSensitivityTestData()
        
        for sensitivity in sensitivityLevels {
            anomalyDetector.setSensitivity(sensitivity)
            let detectionRate = await measureDetectionRate(for: testData)
            
            // Higher sensitivity should result in higher detection rate
            XCTAssertGreaterThan(detectionRate, sensitivity * 0.8, 
                                "Detection rate \(detectionRate) below expected for sensitivity \(sensitivity)")
        }
    }
    
    func testAnomalyClassificationAccuracy() async throws {
        // Test classification accuracy for different anomaly types
        let testCases = healthDataGenerator.generateClassificationTestCases()
        var correctClassifications = 0
        let totalCases = testCases.count
        
        for testCase in testCases {
            let predictedType = await anomalyDetector.classifyAnomaly(in: testCase.data)
            if predictedType == testCase.expectedType {
                correctClassifications += 1
            }
        }
        
        let accuracy = Double(correctClassifications) / Double(totalCases)
        XCTAssertGreaterThan(accuracy, 0.85, "Anomaly classification accuracy \(accuracy) below 85% threshold")
    }
    
    // MARK: - Helper Methods
    private func measureDetectionRate(for data: [HealthDataPoint]) async -> Double {
        var detectedCount = 0
        let totalCount = data.count
        
        for dataPoint in data {
            let isDetected = await anomalyDetector.detectAnomaly(in: dataPoint.values, type: dataPoint.type)
            if isDetected {
                detectedCount += 1
            }
        }
        
        return Double(detectedCount) / Double(totalCount)
    }
}

// MARK: - Mock Data Generator
private class MockHealthDataGenerator {
    
    struct AnomalyData {
        let data: [Double]
        let description: String
    }
    
    struct BorderlineCase {
        let data: [Double]
        let type: HealthDataType
    }
    
    struct TrendData {
        let data: [Double]
        let window: Int
        let description: String
    }
    
    struct GradualPattern {
        let data: [Double]
        let threshold: Double
        let description: String
    }
    
    struct CorrelationAnomaly {
        let metrics: [[Double]]
        let expectedCorrelation: Double
        let description: String
    }
    
    struct ClassificationTestCase {
        let data: [Double]
        let expectedType: HealthDataType
    }
    
    struct HealthDataPoint {
        let values: [Double]
        let type: HealthDataType
    }
    
    func generateECGAnomalies() -> [AnomalyData] {
        return [
            AnomalyData(data: generateSubtleECGAbnormality(), description: "Subtle ST segment depression"),
            AnomalyData(data: generateTWaveInversion(), description: "T-wave inversion pattern"),
            AnomalyData(data: generateQRSAbnormality(), description: "QRS complex abnormality")
        ]
    }
    
    func generateRespiratoryAnomalies() -> [AnomalyData] {
        return [
            AnomalyData(data: generateRespiratoryRateChange(), description: "Respiratory rate increase"),
            AnomalyData(data: generateTidalVolumeChange(), description: "Tidal volume decrease"),
            AnomalyData(data: generateOxygenSaturationDrop(), description: "Oxygen saturation drop")
        ]
    }
    
    func generateHRVAnomalies() -> [AnomalyData] {
        return [
            AnomalyData(data: generateHRVDecrease(), description: "HRV decrease pattern"),
            AnomalyData(data: generateHRVInstability(), description: "HRV instability"),
            AnomalyData(data: generateHRVTrendChange(), description: "HRV trend change")
        ]
    }
    
    func generateBloodPressureAnomalies() -> [AnomalyData] {
        return [
            AnomalyData(data: generateSystolicIncrease(), description: "Systolic pressure increase"),
            AnomalyData(data: generateDiastolicChange(), description: "Diastolic pressure change"),
            AnomalyData(data: generatePulsePressureChange(), description: "Pulse pressure change")
        ]
    }
    
    func generateSleepAnomalies() -> [AnomalyData] {
        return [
            AnomalyData(data: generateSleepEfficiencyDrop(), description: "Sleep efficiency decrease"),
            AnomalyData(data: generateREMReduction(), description: "REM sleep reduction"),
            AnomalyData(data: generateSleepLatencyIncrease(), description: "Sleep latency increase")
        ]
    }
    
    func generateBorderlineCases() -> [BorderlineCase] {
        return [
            BorderlineCase(data: generateBorderlineECG(), type: .ecg),
            BorderlineCase(data: generateBorderlineHRV(), type: .hrv),
            BorderlineCase(data: generateBorderlineRespiratory(), type: .respiratory),
            BorderlineCase(data: generateBorderlineBloodPressure(), type: .bloodPressure)
        ]
    }
    
    func generateSubtleTrends() -> [TrendData] {
        return [
            TrendData(data: generateGradualHRIncrease(), window: 24, description: "Gradual heart rate increase"),
            TrendData(data: generateRespiratoryTrend(), window: 12, description: "Respiratory trend change"),
            TrendData(data: generateSleepTrend(), window: 7, description: "Sleep pattern trend")
        ]
    }
    
    func generateGradualDeteriorationPatterns() -> [GradualPattern] {
        return [
            GradualPattern(data: generateGradualHRVDeterioration(), threshold: 0.1, description: "Gradual HRV deterioration"),
            GradualPattern(data: generateGradualBloodPressureIncrease(), threshold: 0.05, description: "Gradual BP increase"),
            GradualPattern(data: generateGradualSleepDeterioration(), threshold: 0.15, description: "Gradual sleep deterioration")
        ]
    }
    
    func generateCorrelationAnomalies() -> [CorrelationAnomaly] {
        return [
            CorrelationAnomaly(metrics: [generateHRData(), generateHRVData()], expectedCorrelation: 0.8, description: "HR-HRV correlation breakdown"),
            CorrelationAnomaly(metrics: [generateSleepData(), generateActivityData()], expectedCorrelation: 0.6, description: "Sleep-activity correlation change"),
            CorrelationAnomaly(metrics: [generateRespiratoryData(), generateHRData()], expectedCorrelation: 0.7, description: "Respiratory-HR correlation anomaly")
        ]
    }
    
    func generateSensitivityTestData() -> [HealthDataPoint] {
        return [
            HealthDataPoint(values: generateNormalHRData(), type: .heartRate),
            HealthDataPoint(values: generateNormalHRVData(), type: .hrv),
            HealthDataPoint(values: generateNormalRespiratoryData(), type: .respiratory),
            HealthDataPoint(values: generateNormalBloodPressureData(), type: .bloodPressure)
        ]
    }
    
    func generateClassificationTestCases() -> [ClassificationTestCase] {
        return [
            ClassificationTestCase(data: generateECGAnomalyData(), expectedType: .ecg),
            ClassificationTestCase(data: generateRespiratoryAnomalyData(), expectedType: .respiratory),
            ClassificationTestCase(data: generateHRVAnomalyData(), expectedType: .hrv),
            ClassificationTestCase(data: generateBloodPressureAnomalyData(), expectedType: .bloodPressure)
        ]
    }
    
    // MARK: - Data Generation Methods
    private func generateSubtleECGAbnormality() -> [Double] {
        return Array(0..<100).map { _ in Double.random(in: 0.8...1.2) }
    }
    
    private func generateTWaveInversion() -> [Double] {
        return Array(0..<100).map { _ in Double.random(in: -0.3...0.1) }
    }
    
    private func generateQRSAbnormality() -> [Double] {
        return Array(0..<100).map { _ in Double.random(in: 0.6...1.4) }
    }
    
    private func generateRespiratoryRateChange() -> [Double] {
        return Array(0..<100).map { _ in Double.random(in: 18...25) }
    }
    
    private func generateTidalVolumeChange() -> [Double] {
        return Array(0..<100).map { _ in Double.random(in: 400...600) }
    }
    
    private func generateOxygenSaturationDrop() -> [Double] {
        return Array(0..<100).map { _ in Double.random(in: 92...98) }
    }
    
    private func generateHRVDecrease() -> [Double] {
        return Array(0..<100).map { _ in Double.random(in: 20...40) }
    }
    
    private func generateHRVInstability() -> [Double] {
        return Array(0..<100).map { _ in Double.random(in: 15...50) }
    }
    
    private func generateHRVTrendChange() -> [Double] {
        return Array(0..<100).map { i in 50.0 - Double(i) * 0.3 }
    }
    
    private func generateSystolicIncrease() -> [Double] {
        return Array(0..<100).map { _ in Double.random(in: 130...160) }
    }
    
    private func generateDiastolicChange() -> [Double] {
        return Array(0..<100).map { _ in Double.random(in: 80...100) }
    }
    
    private func generatePulsePressureChange() -> [Double] {
        return Array(0..<100).map { _ in Double.random(in: 40...60) }
    }
    
    private func generateSleepEfficiencyDrop() -> [Double] {
        return Array(0..<100).map { _ in Double.random(in: 70...85) }
    }
    
    private func generateREMReduction() -> [Double] {
        return Array(0..<100).map { _ in Double.random(in: 15...25) }
    }
    
    private func generateSleepLatencyIncrease() -> [Double] {
        return Array(0..<100).map { _ in Double.random(in: 20...40) }
    }
    
    // Additional helper methods for data generation
    private func generateBorderlineECG() -> [Double] { return Array(0..<100).map { _ in Double.random(in: 0.9...1.1) } }
    private func generateBorderlineHRV() -> [Double] { return Array(0..<100).map { _ in Double.random(in: 35...45) } }
    private func generateBorderlineRespiratory() -> [Double] { return Array(0..<100).map { _ in Double.random(in: 16...18) } }
    private func generateBorderlineBloodPressure() -> [Double] { return Array(0..<100).map { _ in Double.random(in: 120...130) } }
    
    private func generateGradualHRIncrease() -> [Double] { return Array(0..<100).map { i in 70.0 + Double(i) * 0.2 } }
    private func generateRespiratoryTrend() -> [Double] { return Array(0..<100).map { i in 16.0 + Double(i) * 0.1 } }
    private func generateSleepTrend() -> [Double] { return Array(0..<100).map { i in 85.0 - Double(i) * 0.3 } }
    
    private func generateGradualHRVDeterioration() -> [Double] { return Array(0..<100).map { i in 50.0 - Double(i) * 0.2 } }
    private func generateGradualBloodPressureIncrease() -> [Double] { return Array(0..<100).map { i in 120.0 + Double(i) * 0.3 } }
    private func generateGradualSleepDeterioration() -> [Double] { return Array(0..<100).map { i in 85.0 - Double(i) * 0.4 } }
    
    private func generateHRData() -> [Double] { return Array(0..<100).map { _ in Double.random(in: 60...100) } }
    private func generateHRVData() -> [Double] { return Array(0..<100).map { _ in Double.random(in: 30...60) } }
    private func generateSleepData() -> [Double] { return Array(0..<100).map { _ in Double.random(in: 70...90) } }
    private func generateActivityData() -> [Double] { return Array(0..<100).map { _ in Double.random(in: 5000...15000) } }
    private func generateRespiratoryData() -> [Double] { return Array(0..<100).map { _ in Double.random(in: 12...20) } }
    
    private func generateNormalHRData() -> [Double] { return Array(0..<100).map { _ in Double.random(in: 60...80) } }
    private func generateNormalHRVData() -> [Double] { return Array(0..<100).map { _ in Double.random(in: 40...60) } }
    private func generateNormalRespiratoryData() -> [Double] { return Array(0..<100).map { _ in Double.random(in: 12...16) } }
    private func generateNormalBloodPressureData() -> [Double] { return Array(0..<100).map { _ in Double.random(in: 110...130) } }
    
    private func generateECGAnomalyData() -> [Double] { return Array(0..<100).map { _ in Double.random(in: 0.7...1.3) } }
    private func generateRespiratoryAnomalyData() -> [Double] { return Array(0..<100).map { _ in Double.random(in: 20...30) } }
    private func generateHRVAnomalyData() -> [Double] { return Array(0..<100).map { _ in Double.random(in: 20...35) } }
    private func generateBloodPressureAnomalyData() -> [Double] { return Array(0..<100).map { _ in Double.random(in: 140...180) } }
}

// MARK: - Health Data Types
private enum HealthDataType {
    case ecg, respiratory, hrv, bloodPressure, sleep, heartRate
} 
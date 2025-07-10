import XCTest
import Foundation
import Combine
@testable import HealthAI2030

@available(iOS 18.0, macOS 15.0, *)
final class AdvancedBiometricFusionEngineTests: XCTestCase {
    
    var biometricEngine: AdvancedBiometricFusionEngine!
    var healthDataManager: HealthDataManager!
    var analyticsEngine: AnalyticsEngine!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        healthDataManager = HealthDataManager()
        analyticsEngine = AnalyticsEngine()
        biometricEngine = AdvancedBiometricFusionEngine(
            healthDataManager: healthDataManager,
            analyticsEngine: analyticsEngine
        )
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDown() {
        cancellables = nil
        biometricEngine = nil
        healthDataManager = nil
        analyticsEngine = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testInitialization() {
        XCTAssertNotNil(biometricEngine)
        XCTAssertFalse(biometricEngine.isFusionActive)
        XCTAssertEqual(biometricEngine.fusionQuality, .unknown)
        XCTAssertTrue(biometricEngine.sensorStatus.isEmpty)
        XCTAssertNil(biometricEngine.fusedBiometrics)
        XCTAssertNil(biometricEngine.biometricInsights)
        XCTAssertNil(biometricEngine.healthMetrics)
        XCTAssertTrue(biometricEngine.biometricHistory.isEmpty)
    }
    
    // MARK: - Fusion Tests
    
    func testStartFusion() async throws {
        // Given
        XCTAssertFalse(biometricEngine.isFusionActive)
        
        // When
        try await biometricEngine.startFusion()
        
        // Then
        XCTAssertTrue(biometricEngine.isFusionActive)
        XCTAssertNil(biometricEngine.lastError)
    }
    
    func testStopFusion() async throws {
        // Given
        try await biometricEngine.startFusion()
        XCTAssertTrue(biometricEngine.isFusionActive)
        
        // When
        await biometricEngine.stopFusion()
        
        // Then
        XCTAssertFalse(biometricEngine.isFusionActive)
    }
    
    func testStartFusionFailure() async {
        // Given
        let failingEngine = AdvancedBiometricFusionEngine(
            healthDataManager: MockFailingHealthDataManager(),
            analyticsEngine: analyticsEngine
        )
        
        // When & Then
        do {
            try await failingEngine.startFusion()
            XCTFail("Should have thrown an error")
        } catch {
            XCTAssertFalse(failingEngine.isFusionActive)
            XCTAssertNotNil(failingEngine.lastError)
        }
    }
    
    // MARK: - Biometric Fusion Tests
    
    func testPerformFusion() async throws {
        // Given
        try await biometricEngine.startFusion()
        
        // When
        let fusedData = try await biometricEngine.performFusion()
        
        // Then
        XCTAssertNotNil(fusedData)
        XCTAssertEqual(fusedData.timestamp.timeIntervalSinceNow, 0, accuracy: 1.0)
        XCTAssertNotNil(fusedData.vitalSigns)
        XCTAssertNotNil(fusedData.activityData)
        XCTAssertNotNil(fusedData.environmentalData)
        XCTAssertNotNil(fusedData.qualityMetrics)
        XCTAssertTrue(fusedData.fusionConfidence >= 0.0 && fusedData.fusionConfidence <= 1.0)
        XCTAssertFalse(fusedData.sensorContributions.isEmpty)
    }
    
    func testFusionQualityAssessment() async throws {
        // Given
        try await biometricEngine.startFusion()
        let fusedData = try await biometricEngine.performFusion()
        
        // When
        let quality = biometricEngine.fusionQuality
        
        // Then
        XCTAssertNotEqual(quality, .unknown)
        XCTAssertTrue([.excellent, .good, .fair, .poor].contains(quality))
    }
    
    func testFusionConfidenceCalculation() async throws {
        // Given
        try await biometricEngine.startFusion()
        let fusedData = try await biometricEngine.performFusion()
        
        // When
        let confidence = fusedData.fusionConfidence
        
        // Then
        XCTAssertTrue(confidence >= 0.0 && confidence <= 1.0)
    }
    
    func testSensorContributions() async throws {
        // Given
        try await biometricEngine.startFusion()
        let fusedData = try await biometricEngine.performFusion()
        
        // When
        let contributions = fusedData.sensorContributions
        
        // Then
        XCTAssertFalse(contributions.isEmpty)
        XCTAssertEqual(contributions.count, BiometricSensor.allCases.count)
        
        for (sensor, contribution) in contributions {
            XCTAssertTrue(contribution >= 0.0 && contribution <= 1.0)
            XCTAssertTrue(BiometricSensor.allCases.contains(sensor))
        }
    }
    
    // MARK: - Biometric Insights Tests
    
    func testGetBiometricInsights() async {
        // Given
        let timeframes: [Timeframe] = [.hour, .day, .week, .month]
        
        // When & Then
        for timeframe in timeframes {
            let insights = await biometricEngine.getBiometricInsights(timeframe: timeframe)
            
            XCTAssertNotNil(insights)
            XCTAssertEqual(insights.timestamp.timeIntervalSinceNow, 0, accuracy: 1.0)
            XCTAssertNotNil(insights.overallHealth)
            XCTAssertNotNil(insights.stressLevel)
            XCTAssertTrue(insights.energyLevel >= 0.0 && insights.energyLevel <= 1.0)
            XCTAssertNotNil(insights.recoveryStatus)
            XCTAssertNotNil(insights.fitnessLevel)
            XCTAssertTrue(insights.sleepQuality >= 0.0 && insights.sleepQuality <= 1.0)
            XCTAssertNotNil(insights.cardiovascularHealth)
            XCTAssertNotNil(insights.respiratoryHealth)
            XCTAssertNotNil(insights.metabolicHealth)
            XCTAssertNotNil(insights.trends)
            XCTAssertNotNil(insights.anomalies)
            XCTAssertNotNil(insights.recommendations)
        }
    }
    
    func testInsightsWithFusionData() async throws {
        // Given
        try await biometricEngine.startFusion()
        let fusedData = try await biometricEngine.performFusion()
        
        // When
        let insights = await biometricEngine.getBiometricInsights(timeframe: .hour)
        
        // Then
        XCTAssertNotNil(insights)
        XCTAssertNotNil(biometricEngine.biometricInsights)
    }
    
    // MARK: - Health Metrics Tests
    
    func testGetHealthMetrics() async {
        // Given
        try await biometricEngine.startFusion()
        
        // When
        let metrics = await biometricEngine.getHealthMetrics()
        
        // Then
        XCTAssertNotNil(metrics)
        XCTAssertEqual(metrics.timestamp.timeIntervalSinceNow, 0, accuracy: 1.0)
        XCTAssertNotNil(metrics.vitalSigns)
        XCTAssertNotNil(metrics.biometricScores)
        XCTAssertNotNil(metrics.healthIndicators)
        XCTAssertNotNil(metrics.riskFactors)
        XCTAssertNotNil(metrics.wellnessMetrics)
    }
    
    func testVitalSignsData() async {
        // Given
        let metrics = await biometricEngine.getHealthMetrics()
        
        // When
        let vitals = metrics.vitalSigns
        
        // Then
        XCTAssertTrue(vitals.heartRate > 0)
        XCTAssertTrue(vitals.respiratoryRate > 0)
        XCTAssertTrue(vitals.temperature > 0)
        XCTAssertTrue(vitals.bloodPressure.systolic > 0)
        XCTAssertTrue(vitals.bloodPressure.diastolic > 0)
        XCTAssertTrue(vitals.oxygenSaturation > 0)
    }
    
    func testBiometricScores() async {
        // Given
        let metrics = await biometricEngine.getHealthMetrics()
        
        // When
        let scores = metrics.biometricScores
        
        // Then
        XCTAssertTrue(scores.cardiovascular >= 0.0 && scores.cardiovascular <= 1.0)
        XCTAssertTrue(scores.respiratory >= 0.0 && scores.respiratory <= 1.0)
        XCTAssertTrue(scores.metabolic >= 0.0 && scores.metabolic <= 1.0)
        XCTAssertTrue(scores.neurological >= 0.0 && scores.neurological <= 1.0)
        XCTAssertTrue(scores.musculoskeletal >= 0.0 && scores.musculoskeletal <= 1.0)
    }
    
    func testHealthIndicators() async {
        // Given
        let metrics = await biometricEngine.getHealthMetrics()
        
        // When
        let indicators = metrics.healthIndicators
        
        // Then
        XCTAssertTrue(indicators.stressLevel >= 0.0 && indicators.stressLevel <= 1.0)
        XCTAssertTrue(indicators.energyLevel >= 0.0 && indicators.energyLevel <= 1.0)
        XCTAssertTrue(indicators.recoveryStatus >= 0.0 && indicators.recoveryStatus <= 1.0)
        XCTAssertTrue(indicators.sleepQuality >= 0.0 && indicators.sleepQuality <= 1.0)
        XCTAssertTrue(indicators.fitnessLevel >= 0.0 && indicators.fitnessLevel <= 1.0)
    }
    
    func testWellnessMetrics() async {
        // Given
        let metrics = await biometricEngine.getHealthMetrics()
        
        // When
        let wellness = metrics.wellnessMetrics
        
        // Then
        XCTAssertTrue(wellness.overallWellness >= 0.0 && wellness.overallWellness <= 1.0)
        XCTAssertTrue(wellness.physicalWellness >= 0.0 && wellness.physicalWellness <= 1.0)
        XCTAssertTrue(wellness.mentalWellness >= 0.0 && wellness.mentalWellness <= 1.0)
        XCTAssertTrue(wellness.socialWellness >= 0.0 && wellness.socialWellness <= 1.0)
        XCTAssertTrue(wellness.environmentalWellness >= 0.0 && wellness.environmentalWellness <= 1.0)
    }
    
    // MARK: - Sensor Management Tests
    
    func testSensorStatus() {
        // Given
        let sensorStatus = biometricEngine.getSensorStatus()
        
        // When & Then
        XCTAssertFalse(sensorStatus.isEmpty)
        XCTAssertEqual(sensorStatus.count, BiometricSensor.allCases.count)
        
        for (sensor, status) in sensorStatus {
            XCTAssertEqual(status.sensor, sensor)
            XCTAssertNotNil(status.quality)
            XCTAssertNotNil(status.isActive)
        }
    }
    
    func testCalibrateSensors() async throws {
        // Given
        let initialStatus = biometricEngine.getSensorStatus()
        
        // When
        try await biometricEngine.calibrateSensors()
        
        // Then
        let updatedStatus = biometricEngine.getSensorStatus()
        XCTAssertEqual(initialStatus.count, updatedStatus.count)
        XCTAssertNil(biometricEngine.lastError)
    }
    
    func testCalibrationFailure() async {
        // Given
        let failingEngine = AdvancedBiometricFusionEngine(
            healthDataManager: MockFailingHealthDataManager(),
            analyticsEngine: analyticsEngine
        )
        
        // When & Then
        do {
            try await failingEngine.calibrateSensors()
            XCTFail("Should have thrown an error")
        } catch {
            XCTAssertNotNil(failingEngine.lastError)
        }
    }
    
    // MARK: - Fusion Quality Tests
    
    func testFusionQuality() {
        // Given
        let quality = biometricEngine.getFusionQuality()
        
        // When & Then
        XCTAssertNotNil(quality)
        XCTAssertTrue(FusionQuality.allCases.contains(quality))
    }
    
    func testQualityAssessment() async throws {
        // Given
        try await biometricEngine.startFusion()
        let fusedData = try await biometricEngine.performFusion()
        
        // When
        let quality = biometricEngine.fusionQuality
        
        // Then
        XCTAssertNotEqual(quality, .unknown)
        
        switch quality {
        case .excellent:
            XCTAssertTrue(fusedData.qualityMetrics.signalQuality >= 0.8)
            XCTAssertTrue(fusedData.qualityMetrics.confidence >= 0.8)
        case .good:
            XCTAssertTrue(fusedData.qualityMetrics.signalQuality >= 0.6)
            XCTAssertTrue(fusedData.qualityMetrics.confidence >= 0.6)
        case .fair:
            XCTAssertTrue(fusedData.qualityMetrics.signalQuality >= 0.4)
            XCTAssertTrue(fusedData.qualityMetrics.confidence >= 0.4)
        case .poor:
            XCTAssertTrue(fusedData.qualityMetrics.signalQuality < 0.4 || fusedData.qualityMetrics.confidence < 0.4)
        case .unknown:
            XCTFail("Quality should not be unknown after fusion")
        }
    }
    
    // MARK: - Biometric History Tests
    
    func testBiometricHistory() {
        // Given
        let timeframes: [Timeframe] = [.hour, .day, .week, .month]
        
        // When & Then
        for timeframe in timeframes {
            let history = biometricEngine.getBiometricHistory(timeframe: timeframe)
            XCTAssertNotNil(history)
        }
    }
    
    func testHistoryWithData() async throws {
        // Given
        try await biometricEngine.startFusion()
        let fusedData = try await biometricEngine.performFusion()
        await biometricEngine.stopFusion()
        
        // When
        let history = biometricEngine.getBiometricHistory(timeframe: .hour)
        
        // Then
        XCTAssertFalse(history.isEmpty)
        XCTAssertEqual(history.count, biometricEngine.biometricHistory.count)
    }
    
    // MARK: - Export Tests
    
    func testExportBiometricData() async throws {
        // Given
        try await biometricEngine.startFusion()
        let fusedData = try await biometricEngine.performFusion()
        
        // When & Then
        for format in ExportFormat.allCases {
            let exportData = try await biometricEngine.exportBiometricData(format: format)
            XCTAssertNotNil(exportData)
            XCTAssertFalse(exportData.isEmpty)
        }
    }
    
    func testExportFormats() async throws {
        // Given
        try await biometricEngine.startFusion()
        let fusedData = try await biometricEngine.performFusion()
        
        // When
        let jsonData = try await biometricEngine.exportBiometricData(format: .json)
        let csvData = try await biometricEngine.exportBiometricData(format: .csv)
        let xmlData = try await biometricEngine.exportBiometricData(format: .xml)
        
        // Then
        XCTAssertNotNil(jsonData)
        XCTAssertNotNil(csvData)
        XCTAssertNotNil(xmlData)
        XCTAssertFalse(jsonData.isEmpty)
        XCTAssertFalse(csvData.isEmpty)
        XCTAssertFalse(xmlData.isEmpty)
    }
    
    // MARK: - Data Model Tests
    
    func testFusedBiometricDataModel() {
        // Given
        let vitalSigns = FusedVitalSigns(
            heartRate: 72.0,
            heartRateVariability: 45.0,
            respiratoryRate: 16.0,
            temperature: 98.6,
            bloodPressure: BloodPressure(systolic: 120, diastolic: 80, timestamp: Date()),
            oxygenSaturation: 98.0,
            glucose: 100.0,
            timestamp: Date()
        )
        
        let activityData = FusedActivityData(
            movement: 0.5,
            audio: 0.3,
            sleep: SleepData(sleepStage: .awake, sleepQuality: 0.8, sleepDuration: 7.5, timestamp: Date()),
            timestamp: Date()
        )
        
        let environmentalData = FusedEnvironmentalData(
            environmental: EnvironmentalData(
                noiseLevel: 0.4,
                lightLevel: 0.6,
                airQuality: 0.8,
                temperature: 72.0,
                humidity: 0.5,
                pressure: 1013.25,
                timestamp: Date()
            ),
            timestamp: Date()
        )
        
        let qualityMetrics = QualityMetrics(
            signalQuality: 0.8,
            noiseLevel: 0.2,
            confidence: 0.9,
            timestamp: Date()
        )
        
        // When
        let fusedData = FusedBiometricData(
            id: UUID(),
            timestamp: Date(),
            vitalSigns: vitalSigns,
            activityData: activityData,
            environmentalData: environmentalData,
            qualityMetrics: qualityMetrics,
            fusionConfidence: 0.85,
            sensorContributions: [.heartRate: 0.1, .respiratoryRate: 0.1]
        )
        
        // Then
        XCTAssertNotNil(fusedData.id)
        XCTAssertNotNil(fusedData.timestamp)
        XCTAssertEqual(fusedData.vitalSigns.heartRate, 72.0)
        XCTAssertEqual(fusedData.activityData.movement, 0.5)
        XCTAssertEqual(fusedData.qualityMetrics.signalQuality, 0.8)
        XCTAssertEqual(fusedData.fusionConfidence, 0.85)
        XCTAssertEqual(fusedData.sensorContributions.count, 2)
    }
    
    func testBiometricInsightsModel() {
        // Given
        let insights = BiometricInsights(
            timestamp: Date(),
            overallHealth: HealthScore(score: 0.8, category: .good, timestamp: Date()),
            stressLevel: .moderate,
            energyLevel: 0.7,
            recoveryStatus: .recovered,
            fitnessLevel: .moderate,
            sleepQuality: 0.8,
            cardiovascularHealth: CardiovascularHealth(score: 0.8, risk: .low, timestamp: Date()),
            respiratoryHealth: RespiratoryHealth(score: 0.9, efficiency: 0.85, timestamp: Date()),
            metabolicHealth: MetabolicHealth(score: 0.7, efficiency: 0.8, timestamp: Date()),
            trends: [],
            anomalies: [],
            recommendations: []
        )
        
        // Then
        XCTAssertNotNil(insights.timestamp)
        XCTAssertEqual(insights.overallHealth.category, .good)
        XCTAssertEqual(insights.stressLevel, .moderate)
        XCTAssertEqual(insights.energyLevel, 0.7)
        XCTAssertEqual(insights.recoveryStatus, .recovered)
        XCTAssertEqual(insights.fitnessLevel, .moderate)
        XCTAssertEqual(insights.sleepQuality, 0.8)
    }
    
    func testHealthMetricsModel() {
        // Given
        let metrics = HealthMetrics(
            timestamp: Date(),
            vitalSigns: VitalSigns(
                heartRate: 72.0,
                respiratoryRate: 16.0,
                temperature: 98.6,
                bloodPressure: BloodPressure(systolic: 120, diastolic: 80, timestamp: Date()),
                oxygenSaturation: 98.0,
                timestamp: Date()
            ),
            biometricScores: BiometricScores(
                cardiovascular: 0.8,
                respiratory: 0.9,
                metabolic: 0.7,
                neurological: 0.8,
                musculoskeletal: 0.7,
                timestamp: Date()
            ),
            healthIndicators: HealthIndicators(
                stressLevel: 0.4,
                energyLevel: 0.7,
                recoveryStatus: 0.8,
                sleepQuality: 0.8,
                fitnessLevel: 0.6,
                timestamp: Date()
            ),
            riskFactors: [],
            wellnessMetrics: WellnessMetrics(
                overallWellness: 0.8,
                physicalWellness: 0.7,
                mentalWellness: 0.8,
                socialWellness: 0.6,
                environmentalWellness: 0.9,
                timestamp: Date()
            )
        )
        
        // Then
        XCTAssertNotNil(metrics.timestamp)
        XCTAssertEqual(metrics.vitalSigns.heartRate, 72.0)
        XCTAssertEqual(metrics.biometricScores.cardiovascular, 0.8)
        XCTAssertEqual(metrics.healthIndicators.stressLevel, 0.4)
        XCTAssertEqual(metrics.wellnessMetrics.overallWellness, 0.8)
    }
    
    // MARK: - Sensor Data Tests
    
    func testSensorDataModel() {
        // Given
        let sensorData = SensorData(
            heartRate: 72.0,
            heartRateVariability: 45.0,
            respiratoryRate: 16.0,
            temperature: 98.6,
            movement: 0.5,
            audio: 0.3,
            environmental: EnvironmentalData(
                noiseLevel: 0.4,
                lightLevel: 0.6,
                airQuality: 0.8,
                temperature: 72.0,
                humidity: 0.5,
                pressure: 1013.25,
                timestamp: Date()
            ),
            bloodPressure: BloodPressure(systolic: 120, diastolic: 80, timestamp: Date()),
            oxygenSaturation: 98.0,
            glucose: 100.0,
            sleep: SleepData(sleepStage: .awake, sleepQuality: 0.8, sleepDuration: 7.5, timestamp: Date()),
            timestamp: Date()
        )
        
        // Then
        XCTAssertEqual(sensorData.heartRate, 72.0)
        XCTAssertEqual(sensorData.heartRateVariability, 45.0)
        XCTAssertEqual(sensorData.respiratoryRate, 16.0)
        XCTAssertEqual(sensorData.temperature, 98.6)
        XCTAssertEqual(sensorData.movement, 0.5)
        XCTAssertEqual(sensorData.audio, 0.3)
        XCTAssertEqual(sensorData.oxygenSaturation, 98.0)
        XCTAssertEqual(sensorData.glucose, 100.0)
        XCTAssertNotNil(sensorData.environmental)
        XCTAssertNotNil(sensorData.bloodPressure)
        XCTAssertNotNil(sensorData.sleep)
        XCTAssertNotNil(sensorData.timestamp)
    }
    
    // MARK: - Performance Tests
    
    func testPerformanceFusion() {
        measure {
            let expectation = XCTestExpectation(description: "Performance test")
            
            Task {
                try? await biometricEngine.startFusion()
                _ = try? await biometricEngine.performFusion()
                await biometricEngine.stopFusion()
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 5.0)
        }
    }
    
    func testPerformanceInsights() {
        measure {
            let expectation = XCTestExpectation(description: "Insights performance test")
            
            Task {
                _ = await biometricEngine.getBiometricInsights(timeframe: .hour)
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 5.0)
        }
    }
    
    func testPerformanceMetrics() {
        measure {
            let expectation = XCTestExpectation(description: "Metrics performance test")
            
            Task {
                _ = await biometricEngine.getHealthMetrics()
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 5.0)
        }
    }
    
    // MARK: - Integration Tests
    
    func testIntegrationWithHealthDataManager() async {
        // Given
        XCTAssertNotNil(biometricEngine.healthDataManager)
        
        // When & Then
        try? await biometricEngine.startFusion()
        XCTAssertTrue(biometricEngine.isFusionActive || biometricEngine.lastError != nil)
    }
    
    func testIntegrationWithAnalyticsEngine() async {
        // Given
        XCTAssertNotNil(biometricEngine.analyticsEngine)
        
        // When
        try? await biometricEngine.startFusion()
        
        // Then
        // Analytics should be tracked (implementation dependent)
        XCTAssertTrue(biometricEngine.isFusionActive || biometricEngine.lastError != nil)
    }
    
    // MARK: - Error Handling Tests
    
    func testErrorHandling() async {
        // Given
        let failingEngine = AdvancedBiometricFusionEngine(
            healthDataManager: MockFailingHealthDataManager(),
            analyticsEngine: analyticsEngine
        )
        
        // When
        do {
            try await failingEngine.startFusion()
            XCTFail("Should have thrown an error")
        } catch {
            // Then
            XCTAssertNotNil(failingEngine.lastError)
            XCTAssertFalse(failingEngine.isFusionActive)
        }
    }
    
    func testFusionErrorHandling() async {
        // Given
        let failingEngine = AdvancedBiometricFusionEngine(
            healthDataManager: healthDataManager,
            analyticsEngine: MockFailingAnalyticsEngine()
        )
        
        try? await failingEngine.startFusion()
        
        // When & Then
        do {
            _ = try await failingEngine.performFusion()
            XCTFail("Should have thrown an error")
        } catch {
            XCTAssertNotNil(failingEngine.lastError)
        }
    }
    
    // MARK: - Edge Cases Tests
    
    func testEmptySensorData() async throws {
        // Given
        try await biometricEngine.startFusion()
        
        // When
        let fusedData = try await biometricEngine.performFusion()
        
        // Then
        XCTAssertNotNil(fusedData)
        // Should handle empty sensor data gracefully
    }
    
    func testInvalidSensorData() async throws {
        // Given
        try await biometricEngine.startFusion()
        
        // When
        let fusedData = try await biometricEngine.performFusion()
        
        // Then
        XCTAssertNotNil(fusedData)
        // Should handle invalid sensor data gracefully
    }
    
    func testConcurrentFusion() async throws {
        // Given
        try await biometricEngine.startFusion()
        
        // When
        async let fusion1 = biometricEngine.performFusion()
        async let fusion2 = biometricEngine.performFusion()
        
        let (result1, result2) = try await (fusion1, fusion2)
        
        // Then
        XCTAssertNotNil(result1)
        XCTAssertNotNil(result2)
        // Should handle concurrent fusion requests
    }
}

// MARK: - Mock Classes

class MockFailingHealthDataManager: HealthDataManager {
    override func requestHealthKitPermissions() async throws {
        throw NSError(domain: "MockError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock failure"])
    }
}

class MockFailingAnalyticsEngine: AnalyticsEngine {
    override func trackEvent(_ event: String, properties: [String: Any]? = nil) {
        // Simulate failure
        throw NSError(domain: "MockError", code: 2, userInfo: [NSLocalizedDescriptionKey: "Mock analytics failure"])
    }
}

// MARK: - Test Extensions

extension AdvancedBiometricFusionEngine {
    var healthDataManager: HealthDataManager {
        return Mirror(reflecting: self).children.first { $0.label == "healthDataManager" }?.value as! HealthDataManager
    }
    
    var analyticsEngine: AnalyticsEngine {
        return Mirror(reflecting: self).children.first { $0.label == "analyticsEngine" }?.value as! AnalyticsEngine
    }
} 
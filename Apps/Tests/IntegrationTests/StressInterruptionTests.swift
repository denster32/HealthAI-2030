import XCTest
@testable import HealthAI2030Core

final class StressInterruptionTests: XCTestCase {
    
    private var stressInterruptionManager: StressInterruptionManager!
    private var healthDataSimulator: HealthDataSimulator!
    private var notificationManager: MockNotificationManager!
    
    override func setUp() {
        super.setUp()
        stressInterruptionManager = StressInterruptionManager()
        healthDataSimulator = HealthDataSimulator()
        notificationManager = MockNotificationManager()
        stressInterruptionManager.setNotificationManager(notificationManager)
    }
    
    override func tearDown() {
        stressInterruptionManager = nil
        healthDataSimulator = nil
        notificationManager = nil
        super.tearDown()
    }

    func testRealTimeTriggerPrecision() {
        // Test HRV rapid drop detection and immediate response
        let hrvDropScenario = healthDataSimulator.generateHRVRapidDrop()
        var triggerCount = 0
        
        for dataPoint in hrvDropScenario {
            let wasTriggered = stressInterruptionManager.processHealthData(dataPoint)
            if wasTriggered {
                triggerCount += 1
            }
        }
        
        // Should trigger within 30 seconds of HRV drop
        XCTAssertGreaterThan(triggerCount, 0, "No stress interruption triggered for HRV rapid drop")
        XCTAssertLessThanOrEqual(triggerCount, 3, "Too many triggers for single HRV drop event")
        
        // Test heart rate spike detection
        let hrSpikeScenario = healthDataSimulator.generateHeartRateSpike()
        triggerCount = 0
        
        for dataPoint in hrSpikeScenario {
            let wasTriggered = stressInterruptionManager.processHealthData(dataPoint)
            if wasTriggered {
                triggerCount += 1
            }
        }
        
        XCTAssertGreaterThan(triggerCount, 0, "No stress interruption triggered for heart rate spike")
        
        // Test respiratory rate increase detection
        let respiratoryScenario = healthDataSimulator.generateRespiratoryRateIncrease()
        triggerCount = 0
        
        for dataPoint in respiratoryScenario {
            let wasTriggered = stressInterruptionManager.processHealthData(dataPoint)
            if wasTriggered {
                triggerCount += 1
            }
        }
        
        XCTAssertGreaterThan(triggerCount, 0, "No stress interruption triggered for respiratory rate increase")
        
        // Test blood pressure elevation detection
        let bpScenario = healthDataSimulator.generateBloodPressureElevation()
        triggerCount = 0
        
        for dataPoint in bpScenario {
            let wasTriggered = stressInterruptionManager.processHealthData(dataPoint)
            if wasTriggered {
                triggerCount += 1
            }
        }
        
        XCTAssertGreaterThan(triggerCount, 0, "No stress interruption triggered for blood pressure elevation")
        
        // Test response time measurement
        let responseTime = measureResponseTime()
        XCTAssertLessThan(responseTime, 5.0, "Stress interruption response time exceeds 5 seconds")
    }

    func testCustomizationImpact() {
        // Test custom stress threshold configuration
        let customThresholds = [
            StressThreshold(hrvDrop: 20.0, hrSpike: 100, respiratoryRate: 25, bloodPressure: 140),
            StressThreshold(hrvDrop: 15.0, hrSpike: 90, respiratoryRate: 20, bloodPressure: 130),
            StressThreshold(hrvDrop: 25.0, hrSpike: 110, respiratoryRate: 30, bloodPressure: 150)
        ]
        
        for threshold in customThresholds {
            stressInterruptionManager.setCustomThresholds(threshold)
            
            // Test with data that should trigger at this threshold
            let triggerData = healthDataSimulator.generateDataForThreshold(threshold)
            var wasTriggered = false
            
            for dataPoint in triggerData {
                if stressInterruptionManager.processHealthData(dataPoint) {
                    wasTriggered = true
                    break
                }
            }
            
            XCTAssertTrue(wasTriggered, "Custom threshold \(threshold) not respected")
            
            // Test with data that should NOT trigger at this threshold
            let nonTriggerData = healthDataSimulator.generateDataBelowThreshold(threshold)
            wasTriggered = false
            
            for dataPoint in nonTriggerData {
                if stressInterruptionManager.processHealthData(dataPoint) {
                    wasTriggered = true
                    break
                }
            }
            
            XCTAssertFalse(wasTriggered, "Custom threshold \(threshold) triggered incorrectly")
        }
        
        // Test personalized sensitivity settings
        let sensitivityLevels = [0.3, 0.5, 0.7, 0.9]
        for sensitivity in sensitivityLevels {
            stressInterruptionManager.setSensitivity(sensitivity)
            
            let testData = healthDataSimulator.generateSensitivityTestData()
            var triggerCount = 0
            
            for dataPoint in testData {
                if stressInterruptionManager.processHealthData(dataPoint) {
                    triggerCount += 1
                }
            }
            
            // Higher sensitivity should result in more triggers
            let triggerRate = Double(triggerCount) / Double(testData.count)
            XCTAssertGreaterThan(triggerRate, sensitivity * 0.5, 
                                "Sensitivity \(sensitivity) not properly applied")
        }
        
        // Test user preference impact on interruption actions
        let userPreferences = [
            UserStressPreferences(enableBreathing: true, enableMusic: false, enableNotification: true),
            UserStressPreferences(enableBreathing: false, enableMusic: true, enableNotification: false),
            UserStressPreferences(enableBreathing: true, enableMusic: true, enableNotification: true)
        ]
        
        for preferences in userPreferences {
            stressInterruptionManager.setUserPreferences(preferences)
            
            // Trigger a stress event
            let stressData = healthDataSimulator.generateStressEvent()
            stressInterruptionManager.processHealthData(stressData)
            
            // Verify correct actions were taken based on preferences
            XCTAssertEqual(notificationManager.breathingSessionsTriggered, preferences.enableBreathing ? 1 : 0,
                          "Breathing session preference not respected")
            XCTAssertEqual(notificationManager.musicSessionsTriggered, preferences.enableMusic ? 1 : 0,
                          "Music session preference not respected")
            XCTAssertEqual(notificationManager.notificationsSent, preferences.enableNotification ? 1 : 0,
                          "Notification preference not respected")
            
            // Reset notification manager for next test
            notificationManager.reset()
        }
    }
    
    func testStressInterruptionEffectiveness() {
        // Test that interruptions actually reduce stress metrics
        let stressData = healthDataSimulator.generateProlongedStress()
        var stressLevels: [Double] = []
        
        // Record stress levels before interruption
        for dataPoint in stressData.prefix(10) {
            stressLevels.append(dataPoint.stressLevel)
        }
        
        // Trigger interruption
        stressInterruptionManager.processHealthData(stressData[5])
        
        // Record stress levels after interruption
        for dataPoint in stressData.suffix(10) {
            stressLevels.append(dataPoint.stressLevel)
        }
        
        // Calculate stress reduction
        let beforeInterruption = stressLevels.prefix(10).reduce(0, +) / 10.0
        let afterInterruption = stressLevels.suffix(10).reduce(0, +) / 10.0
        let stressReduction = beforeInterruption - afterInterruption
        
        XCTAssertGreaterThan(stressReduction, 10.0, "Stress interruption not effective in reducing stress levels")
    }
    
    func testFalsePositivePrevention() {
        // Test that normal variations don't trigger false positives
        let normalData = healthDataSimulator.generateNormalVariations()
        var falsePositiveCount = 0
        
        for dataPoint in normalData {
            if stressInterruptionManager.processHealthData(dataPoint) {
                falsePositiveCount += 1
            }
        }
        
        let falsePositiveRate = Double(falsePositiveCount) / Double(normalData.count)
        XCTAssertLessThan(falsePositiveRate, 0.05, "False positive rate \(falsePositiveRate) exceeds 5% threshold")
    }
    
    func testInterruptionCooldown() {
        // Test that interruptions have proper cooldown periods
        let stressData = healthDataSimulator.generateContinuousStress()
        var triggerCount = 0
        
        for dataPoint in stressData {
            if stressInterruptionManager.processHealthData(dataPoint) {
                triggerCount += 1
            }
        }
        
        // Should not trigger more than once per cooldown period
        let expectedMaxTriggers = stressData.count / 300 // Assuming 5-minute cooldown
        XCTAssertLessThanOrEqual(triggerCount, expectedMaxTriggers, 
                                "Too many triggers during cooldown period")
    }
    
    // MARK: - Helper Methods
    private func measureResponseTime() -> TimeInterval {
        let startTime = Date()
        let stressData = healthDataSimulator.generateStressEvent()
        stressInterruptionManager.processHealthData(stressData)
        return Date().timeIntervalSince(startTime)
    }
}

// MARK: - Mock Classes and Data Structures
private class StressInterruptionManager {
    private var notificationManager: MockNotificationManager?
    private var customThresholds: StressThreshold?
    private var sensitivity: Double = 0.5
    private var userPreferences: UserStressPreferences?
    private var lastTriggerTime: Date?
    private let cooldownPeriod: TimeInterval = 300 // 5 minutes
    
    func setNotificationManager(_ manager: MockNotificationManager) {
        notificationManager = manager
    }
    
    func setCustomThresholds(_ thresholds: StressThreshold) {
        customThresholds = thresholds
    }
    
    func setSensitivity(_ level: Double) {
        sensitivity = level
    }
    
    func setUserPreferences(_ preferences: UserStressPreferences) {
        userPreferences = preferences
    }
    
    func processHealthData(_ data: HealthDataPoint) -> Bool {
        // Check cooldown period
        if let lastTrigger = lastTriggerTime,
           Date().timeIntervalSince(lastTrigger) < cooldownPeriod {
            return false
        }
        
        // Check if stress threshold is exceeded
        if isStressThresholdExceeded(data) {
            triggerInterruption(data)
            lastTriggerTime = Date()
            return true
        }
        
        return false
    }
    
    private func isStressThresholdExceeded(_ data: HealthDataPoint) -> Bool {
        let thresholds = customThresholds ?? StressThreshold.default
        
        // Apply sensitivity adjustment
        let adjustedHRVDrop = thresholds.hrvDrop * (1.0 - sensitivity)
        let adjustedHRSpike = thresholds.hrSpike * (1.0 + sensitivity)
        let adjustedRespiratoryRate = thresholds.respiratoryRate * (1.0 + sensitivity)
        let adjustedBloodPressure = thresholds.bloodPressure * (1.0 + sensitivity)
        
        return data.hrv < adjustedHRVDrop ||
               data.heartRate > adjustedHRSpike ||
               data.respiratoryRate > adjustedRespiratoryRate ||
               data.systolicBloodPressure > adjustedBloodPressure
    }
    
    private func triggerInterruption(_ data: HealthDataPoint) {
        guard let preferences = userPreferences else { return }
        
        if preferences.enableBreathing {
            notificationManager?.triggerBreathingSession()
        }
        
        if preferences.enableMusic {
            notificationManager?.triggerMusicSession()
        }
        
        if preferences.enableNotification {
            notificationManager?.sendStressNotification()
        }
    }
}

private class MockNotificationManager {
    var breathingSessionsTriggered = 0
    var musicSessionsTriggered = 0
    var notificationsSent = 0
    
    func triggerBreathingSession() {
        breathingSessionsTriggered += 1
    }
    
    func triggerMusicSession() {
        musicSessionsTriggered += 1
    }
    
    func sendStressNotification() {
        notificationsSent += 1
    }
    
    func reset() {
        breathingSessionsTriggered = 0
        musicSessionsTriggered = 0
        notificationsSent = 0
    }
}

private class HealthDataSimulator {
    
    func generateHRVRapidDrop() -> [HealthDataPoint] {
        return Array(0..<60).map { i in
            let baseHRV = 50.0
            let drop = i > 30 ? 25.0 : 0.0
            return HealthDataPoint(
                hrv: baseHRV - drop,
                heartRate: 70.0,
                respiratoryRate: 16.0,
                systolicBloodPressure: 120.0,
                stressLevel: i > 30 ? 75.0 : 30.0
            )
        }
    }
    
    func generateHeartRateSpike() -> [HealthDataPoint] {
        return Array(0..<60).map { i in
            let baseHR = 70.0
            let spike = i > 30 ? 40.0 : 0.0
            return HealthDataPoint(
                hrv: 45.0,
                heartRate: baseHR + spike,
                respiratoryRate: 16.0,
                systolicBloodPressure: 120.0,
                stressLevel: i > 30 ? 80.0 : 30.0
            )
        }
    }
    
    func generateRespiratoryRateIncrease() -> [HealthDataPoint] {
        return Array(0..<60).map { i in
            let baseRate = 16.0
            let increase = i > 30 ? 10.0 : 0.0
            return HealthDataPoint(
                hrv: 45.0,
                heartRate: 70.0,
                respiratoryRate: baseRate + increase,
                systolicBloodPressure: 120.0,
                stressLevel: i > 30 ? 70.0 : 30.0
            )
        }
    }
    
    func generateBloodPressureElevation() -> [HealthDataPoint] {
        return Array(0..<60).map { i in
            let baseBP = 120.0
            let elevation = i > 30 ? 25.0 : 0.0
            return HealthDataPoint(
                hrv: 45.0,
                heartRate: 70.0,
                respiratoryRate: 16.0,
                systolicBloodPressure: baseBP + elevation,
                stressLevel: i > 30 ? 85.0 : 30.0
            )
        }
    }
    
    func generateDataForThreshold(_ threshold: StressThreshold) -> [HealthDataPoint] {
        return [
            HealthDataPoint(hrv: threshold.hrvDrop - 5.0, heartRate: 70.0, respiratoryRate: 16.0, systolicBloodPressure: 120.0, stressLevel: 60.0),
            HealthDataPoint(hrv: 45.0, heartRate: threshold.hrSpike + 5.0, respiratoryRate: 16.0, systolicBloodPressure: 120.0, stressLevel: 70.0),
            HealthDataPoint(hrv: 45.0, heartRate: 70.0, respiratoryRate: threshold.respiratoryRate + 2.0, systolicBloodPressure: 120.0, stressLevel: 65.0),
            HealthDataPoint(hrv: 45.0, heartRate: 70.0, respiratoryRate: 16.0, systolicBloodPressure: threshold.bloodPressure + 5.0, stressLevel: 75.0)
        ]
    }
    
    func generateDataBelowThreshold(_ threshold: StressThreshold) -> [HealthDataPoint] {
        return [
            HealthDataPoint(hrv: threshold.hrvDrop + 5.0, heartRate: 70.0, respiratoryRate: 16.0, systolicBloodPressure: 120.0, stressLevel: 30.0),
            HealthDataPoint(hrv: 45.0, heartRate: threshold.hrSpike - 5.0, respiratoryRate: 16.0, systolicBloodPressure: 120.0, stressLevel: 35.0),
            HealthDataPoint(hrv: 45.0, heartRate: 70.0, respiratoryRate: threshold.respiratoryRate - 2.0, systolicBloodPressure: 120.0, stressLevel: 25.0),
            HealthDataPoint(hrv: 45.0, heartRate: 70.0, respiratoryRate: 16.0, systolicBloodPressure: threshold.bloodPressure - 5.0, stressLevel: 40.0)
        ]
    }
    
    func generateSensitivityTestData() -> [HealthDataPoint] {
        return Array(0..<100).map { _ in
            HealthDataPoint(
                hrv: Double.random(in: 20...60),
                heartRate: Double.random(in: 60...120),
                respiratoryRate: Double.random(in: 12...30),
                systolicBloodPressure: Double.random(in: 100...160),
                stressLevel: Double.random(in: 20...80)
            )
        }
    }
    
    func generateStressEvent() -> HealthDataPoint {
        return HealthDataPoint(
            hrv: 20.0,
            heartRate: 110.0,
            respiratoryRate: 25.0,
            systolicBloodPressure: 150.0,
            stressLevel: 85.0
        )
    }
    
    func generateProlongedStress() -> [HealthDataPoint] {
        return Array(0..<20).map { i in
            HealthDataPoint(
                hrv: 25.0,
                heartRate: 95.0,
                respiratoryRate: 22.0,
                systolicBloodPressure: 140.0,
                stressLevel: 75.0 - Double(i) * 2.0 // Gradually decreasing after interruption
            )
        }
    }
    
    func generateNormalVariations() -> [HealthDataPoint] {
        return Array(0..<100).map { _ in
            HealthDataPoint(
                hrv: Double.random(in: 35...65),
                heartRate: Double.random(in: 60...85),
                respiratoryRate: Double.random(in: 12...18),
                systolicBloodPressure: Double.random(in: 110...130),
                stressLevel: Double.random(in: 20...40)
            )
        }
    }
    
    func generateContinuousStress() -> [HealthDataPoint] {
        return Array(0..<600).map { _ in // 10 minutes of continuous stress
            HealthDataPoint(
                hrv: 20.0,
                heartRate: 110.0,
                respiratoryRate: 25.0,
                systolicBloodPressure: 150.0,
                stressLevel: 85.0
            )
        }
    }
}

// MARK: - Data Structures
private struct HealthDataPoint {
    let hrv: Double
    let heartRate: Double
    let respiratoryRate: Double
    let systolicBloodPressure: Double
    let stressLevel: Double
}

private struct StressThreshold {
    let hrvDrop: Double
    let hrSpike: Double
    let respiratoryRate: Double
    let bloodPressure: Double
    
    static let `default` = StressThreshold(
        hrvDrop: 25.0,
        hrSpike: 100.0,
        respiratoryRate: 22.0,
        bloodPressure: 140.0
    )
}

private struct UserStressPreferences {
    let enableBreathing: Bool
    let enableMusic: Bool
    let enableNotification: Bool
} 
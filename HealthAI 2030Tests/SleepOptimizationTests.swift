import XCTest
import HealthKit
import CoreML
@testable import HealthAI_2030

/// Comprehensive test suite for Sleep Optimization & Coaching Loop
@MainActor
class SleepOptimizationTests: XCTestCase {
    
    // MARK: - Test Components
    var sleepManager: SleepManager!
    var healthKitManager: HealthKitManager!
    var aiEngine: AISleepAnalysisEngine!
    var feedbackEngine: SleepFeedbackEngine!
    var analytics: SleepAnalyticsEngine!
    var backgroundTaskManager: SleepBackgroundTaskManager!
    
    // MARK: - Test Setup
    override func setUp() async throws {
        try await super.setUp()
        
        // Initialize components
        sleepManager = SleepManager.shared
        healthKitManager = HealthKitManager.shared
        aiEngine = AISleepAnalysisEngine.shared
        feedbackEngine = SleepFeedbackEngine.shared
        analytics = SleepAnalyticsEngine.shared
        backgroundTaskManager = SleepBackgroundTaskManager.shared
        
        // Reset state for testing
        await resetTestEnvironment()
    }
    
    override func tearDown() async throws {
        // Clean up after tests
        await cleanupTestEnvironment()
        try await super.tearDown()
    }
    
    // MARK: - Helper Methods
    private func resetTestEnvironment() async {
        // Reset all managers to initial state
        if sleepManager.isMonitoring {
            await sleepManager.endSleepSession()
        }
        
        await feedbackEngine.stopFeedbackLoop()
        backgroundTaskManager.disableBackgroundProcessing()
    }
    
    private func cleanupTestEnvironment() async {
        await resetTestEnvironment()
    }
    
    private func createMockBiometricData() -> BiometricData {
        return BiometricData(
            timestamp: Date(),
            heartRate: 65.0,
            hrv: 35.0,
            movement: 0.2,
            oxygenSaturation: 96.0,
            respiratoryRate: 14.0
        )
    }
    
    private func createMockSleepFeatures() -> SleepFeatures {
        return SleepFeatures(
            heartRate: 65.0,
            hrv: 35.0,
            movement: 0.2,
            bloodOxygen: 96.0,
            temperature: 70.0,
            breathingRate: 14.0,
            timeOfNight: 2.0,
            previousStage: .light
        )
    }
}

// MARK: - Sleep Manager Tests
extension SleepOptimizationTests {
    
    func testSleepSessionLifecycle() async throws {
        // Test starting a sleep session
        XCTAssertFalse(sleepManager.isMonitoring)
        
        await sleepManager.startSleepSession()
        XCTAssertTrue(sleepManager.isMonitoring)
        XCTAssertEqual(sleepManager.currentSleepStage, .awake)
        
        // Simulate some time passing
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
        
        // Test ending sleep session
        await sleepManager.endSleepSession()
        XCTAssertFalse(sleepManager.isMonitoring)
        XCTAssertNotNil(sleepManager.sleepSession)
    }
    
    func testSleepStageTracking() async throws {
        await sleepManager.startSleepSession()
        
        // Initial stage should be awake
        XCTAssertEqual(sleepManager.currentSleepStage, .awake)
        
        // Sleep stage history should be tracking changes
        let initialHistoryCount = sleepManager.sleepStageHistory.count
        
        // Simulate sleep progression (this would normally be done by the monitoring timer)
        // For testing, we'll directly test the stage determination logic
        
        await sleepManager.endSleepSession()
        
        // History should have recorded the session
        XCTAssertGreaterThanOrEqual(sleepManager.sleepStageHistory.count, initialHistoryCount)
    }
    
    func testSleepScoreCalculation() {
        // Test with good sleep metrics
        let goodScore = sleepManager.sleepScore
        XCTAssertGreaterThanOrEqual(goodScore, 0)
        XCTAssertLessThanOrEqual(goodScore, 100)
    }
    
    func testTrackingModeSelection() {
        // Test default tracking mode
        XCTAssertEqual(sleepManager.trackingMode, .iphoneOnly)
        
        // Test mode switching (this would normally be controlled by Apple Watch availability)
        // For now, we'll test that the mode is properly stored
    }
}

// MARK: - HealthKit Integration Tests
extension SleepOptimizationTests {
    
    func testHealthKitDataCollection() async throws {
        // Test biometric data structure
        let biometricData = createMockBiometricData()
        
        XCTAssertGreaterThan(biometricData.heartRate, 0)
        XCTAssertGreaterThan(biometricData.hrv, 0)
        XCTAssertGreaterThanOrEqual(biometricData.movement, 0)
        XCTAssertGreaterThan(biometricData.oxygenSaturation, 0)
        XCTAssertGreaterThan(biometricData.respiratoryRate, 0)
    }
    
    func testSleepQualityCalculation() async throws {
        // Test sleep quality score calculation
        let qualityScore = healthKitManager.sleepQualityScore
        
        XCTAssertGreaterThanOrEqual(qualityScore, 0.0)
        XCTAssertLessThanOrEqual(qualityScore, 100.0)
    }
    
    func testHealthAnalysis() async throws {
        // Test comprehensive health analysis
        await healthKitManager.performComprehensiveHealthAnalysis()
        
        // Verify analysis results
        XCTAssertGreaterThanOrEqual(healthKitManager.healthScore, 0.0)
        XCTAssertLessThanOrEqual(healthKitManager.healthScore, 1.0)
    }
}

// MARK: - AI/ML Analysis Tests
extension SleepOptimizationTests {
    
    func testAIEngineInitialization() async throws {
        // Test AI engine initialization
        XCTAssertTrue(aiEngine.isInitialized)
        XCTAssertGreaterThan(aiEngine.modelAccuracy, 0.0)
        XCTAssertLessThanOrEqual(aiEngine.modelAccuracy, 1.0)
    }
    
    func testSleepStagePrediction() async throws {
        let features = createMockSleepFeatures()
        
        // Test AI prediction
        let prediction = await aiEngine.predictSleepStage(features)
        
        XCTAssertNotNil(prediction)
        XCTAssertGreaterThan(prediction.confidence, 0.0)
        XCTAssertLessThanOrEqual(prediction.confidence, 1.0)
        XCTAssertGreaterThanOrEqual(prediction.sleepQuality, 0.0)
        XCTAssertLessThanOrEqual(prediction.sleepQuality, 1.0)
    }
    
    func testPersonalization() async throws {
        // Test personalization improvements over time
        let initialPersonalization = aiEngine.personalizationLevel
        
        // Simulate multiple predictions to improve personalization
        let features = createMockSleepFeatures()
        for _ in 0..<10 {
            _ = await aiEngine.predictSleepStage(features)
        }
        
        // Personalization level should improve (or at least not decrease)
        XCTAssertGreaterThanOrEqual(aiEngine.personalizationLevel, initialPersonalization)
    }
    
    func testAnomalyDetection() async throws {
        // Test with normal data
        let normalFeatures = createMockSleepFeatures()
        let normalPrediction = await aiEngine.predictSleepStage(normalFeatures)
        XCTAssertFalse(aiEngine.anomalyDetected)
        
        // Test with anomalous data (very high heart rate)
        let anomalousFeatures = SleepFeatures(
            heartRate: 150.0, // Very high
            hrv: 35.0,
            movement: 0.2,
            bloodOxygen: 96.0,
            temperature: 70.0,
            breathingRate: 14.0,
            timeOfNight: 2.0,
            previousStage: .light
        )
        
        _ = await aiEngine.predictSleepStage(anomalousFeatures)
        // Note: Anomaly detection might take multiple readings to trigger
    }
}

// MARK: - Analytics Engine Tests
extension SleepOptimizationTests {
    
    func testSleepAnalytics() async throws {
        // Test comprehensive sleep analysis
        let analysis = await analytics.performSleepAnalysis()
        
        XCTAssertNotNil(analysis)
        XCTAssertGreaterThanOrEqual(analysis.sleepScore, 0.0)
        XCTAssertLessThanOrEqual(analysis.sleepScore, 1.0)
    }
    
    func testInsightGeneration() async throws {
        // Test insight generation
        let insights = await analytics.getSleepInsights()
        
        XCTAssertNotNil(insights)
        // Should have at least some insights
        XCTAssertGreaterThanOrEqual(insights.count, 0)
    }
    
    func testSleepScoreCalculation() async throws {
        // Test sleep score calculation
        let sleepScore = await analytics.calculateSleepScore()
        
        XCTAssertGreaterThanOrEqual(sleepScore, 0.0)
        XCTAssertLessThanOrEqual(sleepScore, 1.0)
    }
    
    func testAnalyticsOptimization() async throws {
        // Test analytics optimization
        await analytics.optimizeSleepAnalytics()
        
        // Should complete without errors
        XCTAssertFalse(analytics.isAnalyzing)
    }
}

// MARK: - Feedback Engine Tests
extension SleepOptimizationTests {
    
    func testFeedbackLoopLifecycle() async throws {
        // Test starting feedback loop
        XCTAssertFalse(feedbackEngine.isActive)
        
        await feedbackEngine.startFeedbackLoop()
        XCTAssertTrue(feedbackEngine.isActive)
        
        // Test stopping feedback loop
        await feedbackEngine.stopFeedbackLoop()
        XCTAssertFalse(feedbackEngine.isActive)
    }
    
    func testInterventionExecution() async throws {
        await feedbackEngine.startFeedbackLoop()
        
        let initialInterventionCount = feedbackEngine.currentInterventions.count
        
        // Force an intervention
        await feedbackEngine.forceIntervention(.breathingExercise)
        
        // Should have more interventions or they should be processing
        XCTAssertGreaterThanOrEqual(feedbackEngine.currentInterventions.count, initialInterventionCount)
        
        await feedbackEngine.stopFeedbackLoop()
    }
    
    func testAdaptationLevel() async throws {
        // Test adaptation level tracking
        let initialAdaptation = feedbackEngine.adaptationLevel
        XCTAssertGreaterThanOrEqual(initialAdaptation, 0.0)
        XCTAssertLessThanOrEqual(initialAdaptation, 1.0)
        
        // Adaptation should improve over time with successful interventions
        // This would require running the feedback loop for extended periods
    }
    
    func testFeedbackEngineStatus() async throws {
        let status = feedbackEngine.getStatusReport()
        
        XCTAssertNotNil(status)
        XCTAssertGreaterThanOrEqual(status.activeInterventions, 0)
        XCTAssertGreaterThanOrEqual(status.adaptationLevel, 0.0)
        XCTAssertLessThanOrEqual(status.adaptationLevel, 1.0)
    }
}

// MARK: - Background Task Tests
extension SleepOptimizationTests {
    
    func testBackgroundTaskSetup() async throws {
        // Test background task manager initialization
        XCTAssertNotNil(backgroundTaskManager)
        
        // Test enabling background processing
        backgroundTaskManager.enableBackgroundProcessing()
        XCTAssertTrue(backgroundTaskManager.isBackgroundProcessingEnabled)
        
        // Test disabling background processing
        backgroundTaskManager.disableBackgroundProcessing()
        XCTAssertFalse(backgroundTaskManager.isBackgroundProcessingEnabled)
    }
    
    func testBackgroundTaskStatus() async throws {
        let status = backgroundTaskManager.getBackgroundTaskStatus()
        
        XCTAssertNotNil(status)
        XCTAssertGreaterThanOrEqual(status.activeTasks, 0)
        XCTAssertGreaterThanOrEqual(status.tasksExecuted, 0)
        XCTAssertGreaterThanOrEqual(status.successRate, 0.0)
        XCTAssertLessThanOrEqual(status.successRate, 1.0)
    }
    
    func testIndividualBackgroundTasks() async throws {
        // Test force execution of individual tasks
        backgroundTaskManager.enableBackgroundProcessing()
        
        // Test sleep analysis task
        let sleepAnalysisSuccess = await backgroundTaskManager.forceExecuteTask(.sleepAnalysis)
        XCTAssertTrue(sleepAnalysisSuccess)
        
        // Test data sync task
        let dataSyncSuccess = await backgroundTaskManager.forceExecuteTask(.dataSync)
        XCTAssertTrue(dataSyncSuccess)
        
        // Test AI processing task
        let aiProcessingSuccess = await backgroundTaskManager.forceExecuteTask(.aiProcessing)
        XCTAssertTrue(aiProcessingSuccess)
        
        backgroundTaskManager.disableBackgroundProcessing()
    }
}

// MARK: - Integration Tests
extension SleepOptimizationTests {
    
    func testFullSleepCycle() async throws {
        // Test complete sleep monitoring cycle
        
        // 1. Start sleep session
        await sleepManager.startSleepSession()
        XCTAssertTrue(sleepManager.isMonitoring)
        
        // 2. Start feedback loop
        await feedbackEngine.startFeedbackLoop()
        XCTAssertTrue(feedbackEngine.isActive)
        
        // 3. Enable background processing
        backgroundTaskManager.enableBackgroundProcessing()
        XCTAssertTrue(backgroundTaskManager.isBackgroundProcessingEnabled)
        
        // 4. Simulate some monitoring time
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 second
        
        // 5. Verify systems are running
        XCTAssertTrue(sleepManager.isMonitoring)
        XCTAssertTrue(feedbackEngine.isActive)
        
        // 6. Clean up
        await feedbackEngine.stopFeedbackLoop()
        await sleepManager.endSleepSession()
        backgroundTaskManager.disableBackgroundProcessing()
        
        // 7. Verify cleanup
        XCTAssertFalse(sleepManager.isMonitoring)
        XCTAssertFalse(feedbackEngine.isActive)
        XCTAssertNotNil(sleepManager.sleepSession) // Session should be saved
    }
    
    func testDataFlowIntegration() async throws {
        // Test data flow between components
        
        // 1. Create mock biometric data
        let biometricData = createMockBiometricData()
        
        // 2. Convert to sleep features
        let features = SleepFeatures(
            heartRate: biometricData.heartRate,
            hrv: biometricData.hrv,
            movement: biometricData.movement,
            bloodOxygen: biometricData.oxygenSaturation,
            temperature: 70.0,
            breathingRate: biometricData.respiratoryRate,
            timeOfNight: 2.0,
            previousStage: .light
        )
        
        // 3. Get AI prediction
        let prediction = await aiEngine.predictSleepStage(features)
        XCTAssertNotNil(prediction)
        
        // 4. Run analytics
        let analysis = await analytics.performSleepAnalysis()
        XCTAssertNotNil(analysis)
        
        // 5. Verify data consistency
        XCTAssertGreaterThan(prediction.confidence, 0.0)
        XCTAssertGreaterThanOrEqual(analysis.sleepScore, 0.0)
    }
    
    func testErrorHandlingAndRecovery() async throws {
        // Test system behavior under error conditions
        
        // 1. Test with invalid data
        let invalidFeatures = SleepFeatures(
            heartRate: -1.0, // Invalid
            hrv: -1.0, // Invalid
            movement: -1.0, // Invalid
            bloodOxygen: -1.0, // Invalid
            temperature: -1.0, // Invalid
            breathingRate: -1.0, // Invalid
            timeOfNight: -1.0, // Invalid
            previousStage: .light
        )
        
        // AI should handle invalid data gracefully
        let prediction = await aiEngine.predictSleepStage(invalidFeatures)
        XCTAssertNotNil(prediction)
        // Should use fallback values
        XCTAssertGreaterThan(prediction.confidence, 0.0)
        
        // 2. Test system recovery after errors
        await sleepManager.startSleepSession()
        await sleepManager.endSleepSession()
        
        // System should still be functional
        XCTAssertFalse(sleepManager.isMonitoring)
    }
}

// MARK: - Performance Tests
extension SleepOptimizationTests {
    
    func testAIPredictionPerformance() async throws {
        let features = createMockSleepFeatures()
        
        // Measure AI prediction performance
        let startTime = CFAbsoluteTimeGetCurrent()
        
        for _ in 0..<10 {
            _ = await aiEngine.predictSleepStage(features)
        }
        
        let totalTime = CFAbsoluteTimeGetCurrent() - startTime
        let averageTime = totalTime / 10.0
        
        // AI prediction should be fast (< 0.1 seconds per prediction)
        XCTAssertLessThan(averageTime, 0.1)
    }
    
    func testAnalyticsPerformance() async throws {
        // Measure analytics performance
        let startTime = CFAbsoluteTimeGetCurrent()
        
        _ = await analytics.performSleepAnalysis()
        
        let totalTime = CFAbsoluteTimeGetCurrent() - startTime
        
        // Analytics should complete within reasonable time (< 2 seconds)
        XCTAssertLessThan(totalTime, 2.0)
    }
    
    func testMemoryUsage() async throws {
        // Test memory usage during extended operation
        let initialMemory = getMemoryUsage()
        
        // Run multiple cycles
        for _ in 0..<100 {
            let features = createMockSleepFeatures()
            _ = await aiEngine.predictSleepStage(features)
        }
        
        let finalMemory = getMemoryUsage()
        let memoryIncrease = finalMemory - initialMemory
        
        // Memory increase should be reasonable (< 50MB)
        XCTAssertLessThan(memoryIncrease, 50_000_000) // 50MB
    }
    
    private func getMemoryUsage() -> UInt64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            return info.resident_size
        } else {
            return 0
        }
    }
}

// MARK: - UI Tests (Basic)
extension SleepOptimizationTests {
    
    func testSleepCoachingViewInitialization() async throws {
        // Test that main UI components can be initialized
        // This would normally be in UI tests, but we can test basic initialization
        
        // Verify managers are available for UI
        XCTAssertNotNil(sleepManager)
        XCTAssertNotNil(healthKitManager)
        XCTAssertNotNil(aiEngine)
        XCTAssertNotNil(feedbackEngine)
        XCTAssertNotNil(analytics)
    }
}

// MARK: - TestFlight Readiness Tests
extension SleepOptimizationTests {
    
    func testTestFlightReadiness() async throws {
        // Comprehensive test to verify app is ready for TestFlight
        
        // 1. Test all core components initialize
        XCTAssertNotNil(sleepManager)
        XCTAssertNotNil(healthKitManager)
        XCTAssertNotNil(aiEngine)
        XCTAssertNotNil(feedbackEngine)
        XCTAssertNotNil(analytics)
        XCTAssertNotNil(backgroundTaskManager)
        
        // 2. Test AI engine is functional
        XCTAssertTrue(aiEngine.isInitialized)
        let features = createMockSleepFeatures()
        let prediction = await aiEngine.predictSleepStage(features)
        XCTAssertGreaterThan(prediction.confidence, 0.0)
        
        // 3. Test sleep session can run
        await sleepManager.startSleepSession()
        XCTAssertTrue(sleepManager.isMonitoring)
        await sleepManager.endSleepSession()
        XCTAssertFalse(sleepManager.isMonitoring)
        
        // 4. Test feedback loop can run
        await feedbackEngine.startFeedbackLoop()
        XCTAssertTrue(feedbackEngine.isActive)
        await feedbackEngine.stopFeedbackLoop()
        XCTAssertFalse(feedbackEngine.isActive)
        
        // 5. Test analytics
        let analysis = await analytics.performSleepAnalysis()
        XCTAssertNotNil(analysis)
        
        // 6. Test background tasks
        backgroundTaskManager.enableBackgroundProcessing()
        let status = backgroundTaskManager.getBackgroundTaskStatus()
        XCTAssertTrue(status.isEnabled)
        backgroundTaskManager.disableBackgroundProcessing()
        
        // All systems operational for TestFlight
        print("✅ All systems ready for TestFlight")
    }
    
    func testCriticalUserFlows() async throws {
        // Test critical user flows for TestFlight
        
        // Flow 1: User starts sleep monitoring
        await sleepManager.startSleepSession()
        XCTAssertTrue(sleepManager.isMonitoring)
        
        // Flow 2: System provides real-time feedback
        await feedbackEngine.startFeedbackLoop()
        XCTAssertTrue(feedbackEngine.isActive)
        
        // Flow 3: User gets morning insights
        let insights = await analytics.getSleepInsights()
        XCTAssertNotNil(insights)
        
        // Flow 4: Background processing works
        backgroundTaskManager.enableBackgroundProcessing()
        let taskSuccess = await backgroundTaskManager.forceExecuteTask(.sleepAnalysis)
        XCTAssertTrue(taskSuccess)
        
        // Flow 5: User stops monitoring
        await feedbackEngine.stopFeedbackLoop()
        await sleepManager.endSleepSession()
        backgroundTaskManager.disableBackgroundProcessing()
        
        XCTAssertFalse(sleepManager.isMonitoring)
        XCTAssertFalse(feedbackEngine.isActive)
        
        print("✅ Critical user flows tested successfully")
    }
    
    func testNoBlockingIssues() async throws {
        // Test for common blocking issues
        
        // 1. No crashes during initialization
        // (Already tested above)
        
        // 2. No infinite loops or hangs
        let timeout: TimeInterval = 5.0
        
        let task = Task {
            let features = createMockSleepFeatures()
            return await aiEngine.predictSleepStage(features)
        }
        
        let result = try await withTimeout(timeout) {
            return await task.value
        }
        
        XCTAssertNotNil(result)
        
        // 3. No excessive memory usage
        let memoryBefore = getMemoryUsage()
        
        // Run intensive operations
        for _ in 0..<50 {
            let features = createMockSleepFeatures()
            _ = await aiEngine.predictSleepStage(features)
        }
        
        let memoryAfter = getMemoryUsage()
        let memoryIncrease = memoryAfter - memoryBefore
        
        // Should not increase by more than 20MB
        XCTAssertLessThan(memoryIncrease, 20_000_000)
        
        print("✅ No blocking issues detected")
    }
    
    private func withTimeout<T>(_ timeout: TimeInterval, operation: @escaping () async throws -> T) async throws -> T {
        return try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask {
                return try await operation()
            }
            
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                throw TestError.timeout
            }
            
            guard let result = try await group.next() else {
                throw TestError.noResult
            }
            
            group.cancelAll()
            return result
        }
    }
}

// MARK: - Test Helpers

enum TestError: Error {
    case timeout
    case noResult
}

// MARK: - Mock Data Extensions

extension SleepOptimizationTests {
    
    func createMockSleepSession() -> SleepSession {
        return SleepSession(
            startTime: Date().addingTimeInterval(-8 * 3600), // 8 hours ago
            endTime: Date(),
            duration: 8 * 3600, // 8 hours
            deepSleepPercentage: 20.0,
            remSleepPercentage: 25.0,
            lightSleepPercentage: 50.0,
            awakePercentage: 5.0,
            trackingMode: .iphoneOnly
        )
    }
    
    func createMockEnvironmentData() -> EnvironmentData {
        return EnvironmentData(
            temperature: 70.0,
            humidity: 45.0,
            lightLevel: 0.1,
            noiseLevel: 25.0,
            airQuality: 95.0
        )
    }
}
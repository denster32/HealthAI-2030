import XCTest
@testable import HealthAI2030Core
import HealthKit

final class SleepManagerTests: XCTestCase {
    
    var manager: SleepManager!
    var mockHealthKitManager: MockHealthKitManager!
    var mockWatchManager: MockAppleWatchManager!
    
    override func setUp() {
        super.setUp()
        mockHealthKitManager = MockHealthKitManager()
        mockWatchManager = MockAppleWatchManager()
        manager = SleepManager.shared
        manager.appleWatchManager = mockWatchManager
        HealthKitManager.shared = mockHealthKitManager
    }
    
    override func tearDown() {
        manager = nil
        mockHealthKitManager = nil
        mockWatchManager = nil
        super.tearDown()
    }
    
    // MARK: - Session Management Tests
    
    func testStartSleepSession() async {
        // Given
        XCTAssertFalse(manager.isMonitoring)
        
        // When
        await manager.startSleepSession()
        
        // Then
        XCTAssertTrue(manager.isMonitoring)
        XCTAssertNotNil(manager.sessionStartTime)
        XCTAssertEqual(manager.currentSleepStage, .awake)
    }
    
    func testEndSleepSession() async {
        // Given
        await manager.startSleepSession()
        
        // When
        await manager.endSleepSession()
        
        // Then
        XCTAssertFalse(manager.isMonitoring)
        XCTAssertNotNil(manager.sleepSession)
        XCTAssertNotNil(manager.sleepInsights)
    }
    
    // MARK: - Sleep Stage Transition Tests
    
    func testSleepStageTransitions() async {
        // Given
        await manager.startSleepSession()
        manager.trackingMode = .iphoneOnly
        
        // When
        manager.sessionStartTime = Calendar.current.date(byAdding: .minute, value: -5, to: Date())!
        await manager.updateSleepStage()
        
        // Then
        XCTAssertEqual(manager.currentSleepStage, .light)
    }
    
    func testWatchSleepStageDetection() async {
        // Given
        await manager.startSleepSession()
        manager.trackingMode = .appleWatch
        mockWatchManager.watchBiometricData = WatchBiometricData(
            heartRate: 55,
            hrv: 40,
            bloodOxygen: 96,
            movement: 0.2
        )
        
        // When
        await manager.updateSleepStage()
        
        // Then
        XCTAssertEqual(manager.currentSleepStage, .rem)
    }
    
    // MARK: - Sleep Score Calculation Tests
    
    func testSleepScoreCalculation() {
        // Given
        let session = SleepSession(
            startTime: Date(),
            endTime: Date().addingTimeInterval(3600 * 8), // 8 hours
            duration: 3600 * 8,
            deepSleepPercentage: 20,
            remSleepPercentage: 25,
            lightSleepPercentage: 45,
            awakePercentage: 10,
            trackingMode: .hybrid
        )
        
        // When
        let score = manager.calculateSleepScore(session: session)
        
        // Then
        XCTAssertGreaterThan(score, 80)
        XCTAssertLessThan(score, 100)
    }
    
    // MARK: - HealthKit Integration Tests
    
    func testHealthKitSave() async {
        // Given
        await manager.startSleepSession()
        await manager.endSleepSession()
        
        // Then
        XCTAssertTrue(mockHealthKitManager.didSaveSleepSession)
    }
}

// MARK: - Test Doubles

class MockHealthKitManager: HealthKitManager {
    var didSaveSleepSession = false
    
    override func saveSleepSession(_ session: SleepSession) async {
        didSaveSleepSession = true
    }
}

class MockAppleWatchManager: AppleWatchManager {
    var watchBiometricData: WatchBiometricData?
    
    override func requestBiometricDataFromWatch() -> WatchBiometricData? {
        return watchBiometricData
    }
}
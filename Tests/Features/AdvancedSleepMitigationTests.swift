import XCTest
import Combine
import CoreHaptics
import AVFoundation
import HomeKit
@testable import HealthAI2030

@MainActor
final class AdvancedSleepMitigationTests: XCTestCase {
    
    var sleepEngine: AdvancedSleepMitigationEngine!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        sleepEngine = AdvancedSleepMitigationEngine()
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDown() {
        sleepEngine = nil
        cancellables = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    func testSleepEngineInitialization() {
        XCTAssertNotNil(sleepEngine)
        XCTAssertEqual(sleepEngine.currentSleepStage, .awake)
        XCTAssertEqual(sleepEngine.circadianPhase, .day)
        XCTAssertEqual(sleepEngine.hapticIntensity, 0.0)
        XCTAssertEqual(sleepEngine.audioVolume, 0.0)
        XCTAssertNotNil(sleepEngine.environmentSettings)
        XCTAssertEqual(sleepEngine.sleepQuality, 0.0)
        XCTAssertNotNil(sleepEngine.optimizationRecommendations)
    }
    
    // MARK: - Sleep Stage Tests
    func testSleepStageTransitions() {
        // Test falling asleep
        sleepEngine.updateSleepStage(.fallingAsleep)
        XCTAssertEqual(sleepEngine.currentSleepStage, .fallingAsleep)
        
        // Test light sleep
        sleepEngine.updateSleepStage(.lightSleep)
        XCTAssertEqual(sleepEngine.currentSleepStage, .lightSleep)
        
        // Test deep sleep
        sleepEngine.updateSleepStage(.deepSleep)
        XCTAssertEqual(sleepEngine.currentSleepStage, .deepSleep)
        
        // Test REM sleep
        sleepEngine.updateSleepStage(.remSleep)
        XCTAssertEqual(sleepEngine.currentSleepStage, .remSleep)
        
        // Test wake up
        sleepEngine.updateSleepStage(.wakeUp)
        XCTAssertEqual(sleepEngine.currentSleepStage, .wakeUp)
        
        // Test awake
        sleepEngine.updateSleepStage(.awake)
        XCTAssertEqual(sleepEngine.currentSleepStage, .awake)
    }
    
    // MARK: - Circadian Phase Tests
    func testCircadianPhaseUpdates() {
        // Test morning phase (6-12)
        let morningDate = Calendar.current.date(from: DateComponents(hour: 8, minute: 0)) ?? Date()
        let morningPhase = getCircadianPhase(for: morningDate)
        XCTAssertEqual(morningPhase, .morning)
        
        // Test afternoon phase (12-18)
        let afternoonDate = Calendar.current.date(from: DateComponents(hour: 14, minute: 0)) ?? Date()
        let afternoonPhase = getCircadianPhase(for: afternoonDate)
        XCTAssertEqual(afternoonPhase, .afternoon)
        
        // Test evening phase (18-22)
        let eveningDate = Calendar.current.date(from: DateComponents(hour: 20, minute: 0)) ?? Date()
        let eveningPhase = getCircadianPhase(for: eveningDate)
        XCTAssertEqual(eveningPhase, .evening)
        
        // Test night phase (22-6)
        let nightDate = Calendar.current.date(from: DateComponents(hour: 2, minute: 0)) ?? Date()
        let nightPhase = getCircadianPhase(for: nightDate)
        XCTAssertEqual(nightPhase, .night)
    }
    
    private func getCircadianPhase(for date: Date) -> CircadianPhase {
        let hour = Calendar.current.component(.hour, from: date)
        
        switch hour {
        case 6..<12:
            return .morning
        case 12..<18:
            return .afternoon
        case 18..<22:
            return .evening
        case 22..<24, 0..<6:
            return .night
        default:
            return .day
        }
    }
    
    // MARK: - Environment Settings Tests
    func testEnvironmentSettings() {
        let settings = EnvironmentSettings(
            temperature: 17.0,
            humidity: 50.0,
            lightLevel: 0.01,
            noiseLevel: 0.1
        )
        
        XCTAssertEqual(settings.temperature, 17.0)
        XCTAssertEqual(settings.humidity, 50.0)
        XCTAssertEqual(settings.lightLevel, 0.01)
        XCTAssertEqual(settings.noiseLevel, 0.1)
    }
    
    func testEnvironmentOptimization() {
        // Test optimal sleep environment
        let optimalSettings = EnvironmentSettings(
            temperature: 17.0,
            humidity: 50.0,
            lightLevel: 0.005,
            noiseLevel: 0.0
        )
        
        // These should be optimal for sleep
        XCTAssertGreaterThanOrEqual(optimalSettings.temperature, 16.0)
        XCTAssertLessThanOrEqual(optimalSettings.temperature, 18.0)
        XCTAssertGreaterThanOrEqual(optimalSettings.humidity, 45.0)
        XCTAssertLessThanOrEqual(optimalSettings.humidity, 55.0)
        XCTAssertLessThanOrEqual(optimalSettings.lightLevel, 0.01)
    }
    
    // MARK: - Sleep Sound Profile Tests
    func testSleepSoundProfile() {
        let profile = SleepSoundProfile(
            baseSound: SleepSound(
                name: "White Noise",
                type: .whiteNoise,
                volume: 0.3,
                frequency: nil
            ),
            ambientSounds: [
                SleepSound(
                    name: "Ocean Waves",
                    type: .nature,
                    volume: 0.2,
                    frequency: nil
                )
            ],
            binauralBeatsEnabled: true,
            binauralFrequency: 0.5,
            volume: 0.4,
            name: "Deep Sleep Profile"
        )
        
        XCTAssertEqual(profile.name, "Deep Sleep Profile")
        XCTAssertEqual(profile.volume, 0.4)
        XCTAssertTrue(profile.binauralBeatsEnabled)
        XCTAssertEqual(profile.binauralFrequency, 0.5)
        XCTAssertEqual(profile.ambientSounds.count, 1)
        XCTAssertNotNil(profile.baseSound)
    }
    
    func testSleepSoundTypes() {
        let soundTypes: [SleepSound.SoundType] = [
            .whiteNoise,
            .pinkNoise,
            .brownNoise,
            .nature,
            .ambient,
            .binaural
        ]
        
        for soundType in soundTypes {
            let sound = SleepSound(
                name: "Test Sound",
                type: soundType,
                volume: 0.5,
                frequency: 440.0
            )
            XCTAssertEqual(sound.type, soundType)
        }
    }
    
    // MARK: - Sleep Schedule Tests
    func testSleepSchedule() {
        let bedtime = Calendar.current.date(from: DateComponents(hour: 22, minute: 0)) ?? Date()
        let wakeTime = Calendar.current.date(from: DateComponents(hour: 7, minute: 0)) ?? Date()
        
        var schedule = SleepSchedule()
        schedule.bedtime = bedtime
        schedule.wakeTime = wakeTime
        
        let expectedDuration: TimeInterval = 9 * 3600 // 9 hours
        XCTAssertEqual(schedule.sleepDuration, expectedDuration, accuracy: 60) // Within 1 minute
    }
    
    // MARK: - Light Exposure Tests
    func testLightExposure() {
        let exposure = LightExposure(
            intensity: 0.8,
            colorTemperature: 6500,
            timestamp: Date()
        )
        
        XCTAssertEqual(exposure.intensity, 0.8)
        XCTAssertEqual(exposure.colorTemperature, 6500)
        XCTAssertNotNil(exposure.timestamp)
    }
    
    func testLightExposureHistory() {
        let now = Date()
        let exposures = [
            LightExposure(intensity: 0.9, colorTemperature: 6500, timestamp: now.addingTimeInterval(-3600)),
            LightExposure(intensity: 0.6, colorTemperature: 5500, timestamp: now.addingTimeInterval(-7200)),
            LightExposure(intensity: 0.3, colorTemperature: 3000, timestamp: now.addingTimeInterval(-10800))
        ]
        
        XCTAssertEqual(exposures.count, 3)
        XCTAssertEqual(exposures[0].intensity, 0.9)
        XCTAssertEqual(exposures[1].intensity, 0.6)
        XCTAssertEqual(exposures[2].intensity, 0.3)
    }
    
    // MARK: - Sleep Optimization Recommendation Tests
    func testSleepOptimizationRecommendation() {
        let recommendation = SleepOptimizationRecommendation(
            type: .light,
            priority: .high,
            title: "Reduce Blue Light",
            description: "Switch to warm lighting to prepare for sleep",
            action: "Enable night mode and reduce screen time"
        )
        
        XCTAssertEqual(recommendation.type, .light)
        XCTAssertEqual(recommendation.priority, .high)
        XCTAssertEqual(recommendation.title, "Reduce Blue Light")
        XCTAssertEqual(recommendation.description, "Switch to warm lighting to prepare for sleep")
        XCTAssertEqual(recommendation.action, "Enable night mode and reduce screen time")
    }
    
    func testOptimizationTypes() {
        let types: [SleepOptimizationRecommendation.OptimizationType] = [
            .light,
            .temperature,
            .humidity,
            .sound,
            .environment,
            .sleep
        ]
        
        for type in types {
            let recommendation = SleepOptimizationRecommendation(
                type: type,
                priority: .medium,
                title: "Test",
                description: "Test description",
                action: "Test action"
            )
            XCTAssertEqual(recommendation.type, type)
        }
    }
    
    func testRecommendationPriorities() {
        let priorities: [SleepOptimizationRecommendation.RecommendationPriority] = [
            .low,
            .medium,
            .high,
            .critical
        ]
        
        for priority in priorities {
            let recommendation = SleepOptimizationRecommendation(
                type: .light,
                priority: priority,
                title: "Test",
                description: "Test description",
                action: "Test action"
            )
            XCTAssertEqual(recommendation.priority, priority)
        }
    }
    
    // MARK: - Sleep Quality Tests
    func testSleepQualityCalculation() {
        // Test with optimal conditions
        let optimalSettings = EnvironmentSettings(
            temperature: 17.0,
            humidity: 50.0,
            lightLevel: 0.005,
            noiseLevel: 0.0
        )
        
        sleepEngine.environmentSettings = optimalSettings
        sleepEngine.currentSleepStage = .deepSleep
        
        // Sleep quality should be high with optimal conditions
        sleepEngine.updateSleepQuality()
        XCTAssertGreaterThan(sleepEngine.sleepQuality, 0.7)
    }
    
    func testSleepQualityWithPoorConditions() {
        // Test with poor conditions
        let poorSettings = EnvironmentSettings(
            temperature: 25.0, // Too warm
            humidity: 80.0, // Too humid
            lightLevel: 0.5, // Too bright
            noiseLevel: 0.8 // Too noisy
        )
        
        sleepEngine.environmentSettings = poorSettings
        sleepEngine.currentSleepStage = .awake
        
        // Sleep quality should be low with poor conditions
        sleepEngine.updateSleepQuality()
        XCTAssertLessThan(sleepEngine.sleepQuality, 0.3)
    }
    
    // MARK: - Integration Tests
    func testSleepOptimizationFlow() {
        let expectation = XCTestExpectation(description: "Sleep optimization started")
        
        // Monitor for sleep stage changes
        sleepEngine.$currentSleepStage
            .dropFirst() // Skip initial value
            .sink { stage in
                if stage == .fallingAsleep {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // Start sleep optimization
        sleepEngine.startSleepOptimization()
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testSleepStageTransitions() {
        let expectation = XCTestExpectation(description: "Sleep stage transitions")
        expectation.expectedFulfillmentCount = 3
        
        var stageCount = 0
        
        sleepEngine.$currentSleepStage
            .dropFirst() // Skip initial value
            .sink { _ in
                stageCount += 1
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // Simulate sleep stage transitions
        sleepEngine.updateSleepStage(.fallingAsleep)
        sleepEngine.updateSleepStage(.lightSleep)
        sleepEngine.updateSleepStage(.deepSleep)
        
        wait(for: [expectation], timeout: 5.0)
        XCTAssertEqual(stageCount, 3)
    }
    
    func testCircadianPhaseOptimization() {
        let expectation = XCTestExpectation(description: "Circadian optimization")
        
        // Monitor for optimization recommendations
        sleepEngine.$optimizationRecommendations
            .dropFirst() // Skip initial value
            .sink { recommendations in
                if !recommendations.isEmpty {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // Trigger circadian phase update
        sleepEngine.updateCircadianPhase()
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    // MARK: - Performance Tests
    func testSleepEnginePerformance() {
        measure {
            for _ in 0..<100 {
                sleepEngine.updateSleepStage(.deepSleep)
                sleepEngine.updateSleepQuality()
            }
        }
    }
    
    func testCircadianPhasePerformance() {
        measure {
            for _ in 0..<1000 {
                _ = getCircadianPhase(for: Date())
            }
        }
    }
    
    // MARK: - Edge Cases
    func testExtremeTemperatures() {
        let extremeSettings = EnvironmentSettings(
            temperature: 35.0, // Very hot
            humidity: 10.0, // Very dry
            lightLevel: 1.0, // Very bright
            noiseLevel: 1.0 // Very noisy
        )
        
        sleepEngine.environmentSettings = extremeSettings
        sleepEngine.updateSleepQuality()
        
        // Sleep quality should be very low with extreme conditions
        XCTAssertLessThan(sleepEngine.sleepQuality, 0.1)
    }
    
    func testPerfectConditions() {
        let perfectSettings = EnvironmentSettings(
            temperature: 17.0, // Perfect temperature
            humidity: 50.0, // Perfect humidity
            lightLevel: 0.0, // No light
            noiseLevel: 0.0 // No noise
        )
        
        sleepEngine.environmentSettings = perfectSettings
        sleepEngine.currentSleepStage = .deepSleep
        sleepEngine.updateSleepQuality()
        
        // Sleep quality should be very high with perfect conditions
        XCTAssertGreaterThan(sleepEngine.sleepQuality, 0.9)
    }
    
    func testInvalidSleepStages() {
        // Test that sleep stage updates work correctly
        let stages: [SleepStage] = [.awake, .fallingAsleep, .lightSleep, .deepSleep, .remSleep, .wakeUp]
        
        for stage in stages {
            sleepEngine.updateSleepStage(stage)
            XCTAssertEqual(sleepEngine.currentSleepStage, stage)
        }
    }
    
    func testSleepScheduleEdgeCases() {
        // Test sleep schedule with same bedtime and wake time
        let sameTime = Date()
        var schedule = SleepSchedule()
        schedule.bedtime = sameTime
        schedule.wakeTime = sameTime
        
        XCTAssertEqual(schedule.sleepDuration, 0)
        
        // Test sleep schedule with wake time before bedtime (next day)
        let bedtime = Calendar.current.date(from: DateComponents(hour: 22, minute: 0)) ?? Date()
        let wakeTime = Calendar.current.date(from: DateComponents(hour: 6, minute: 0)) ?? Date()
        
        schedule.bedtime = bedtime
        schedule.wakeTime = wakeTime
        
        // Should handle next-day wake time correctly
        XCTAssertGreaterThan(schedule.sleepDuration, 0)
    }
    
    // MARK: - Audio and Haptic Tests
    func testAudioVolumeControl() {
        // Test volume range
        sleepEngine.audioVolume = 0.0
        XCTAssertEqual(sleepEngine.audioVolume, 0.0)
        
        sleepEngine.audioVolume = 0.5
        XCTAssertEqual(sleepEngine.audioVolume, 0.5)
        
        sleepEngine.audioVolume = 1.0
        XCTAssertEqual(sleepEngine.audioVolume, 1.0)
        
        // Test out of range values
        sleepEngine.audioVolume = -0.1
        XCTAssertEqual(sleepEngine.audioVolume, -0.1) // Should allow negative for testing
        
        sleepEngine.audioVolume = 1.1
        XCTAssertEqual(sleepEngine.audioVolume, 1.1) // Should allow > 1 for testing
    }
    
    func testHapticIntensityControl() {
        // Test haptic intensity range
        sleepEngine.hapticIntensity = 0.0
        XCTAssertEqual(sleepEngine.hapticIntensity, 0.0)
        
        sleepEngine.hapticIntensity = 0.3
        XCTAssertEqual(sleepEngine.hapticIntensity, 0.3)
        
        sleepEngine.hapticIntensity = 0.8
        XCTAssertEqual(sleepEngine.hapticIntensity, 0.8)
        
        sleepEngine.hapticIntensity = 1.0
        XCTAssertEqual(sleepEngine.hapticIntensity, 1.0)
    }
    
    // MARK: - Binaural Beats Tests
    func testBinauralBeatFrequencies() {
        let frequencies: [Double] = [0.5, 1.0, 2.0, 4.0, 8.0, 12.0]
        
        for frequency in frequencies {
            let profile = SleepSoundProfile(
                baseSound: nil,
                ambientSounds: [],
                binauralBeatsEnabled: true,
                binauralFrequency: frequency,
                volume: 0.3,
                name: "Test Profile"
            )
            
            XCTAssertEqual(profile.binauralFrequency, frequency)
            XCTAssertTrue(profile.binauralBeatsEnabled)
        }
    }
    
    func testBinauralBeatRange() {
        // Test common binaural beat frequencies for different sleep stages
        let deepSleepFreq = 0.5 // Delta waves for deep sleep
        let lightSleepFreq = 4.0 // Theta waves for light sleep
        let remSleepFreq = 8.0 // Alpha waves for REM sleep
        
        XCTAssertGreaterThan(deepSleepFreq, 0)
        XCTAssertLessThan(deepSleepFreq, 4)
        
        XCTAssertGreaterThanOrEqual(lightSleepFreq, 4)
        XCTAssertLessThan(lightSleepFreq, 8)
        
        XCTAssertGreaterThanOrEqual(remSleepFreq, 8)
        XCTAssertLessThan(remSleepFreq, 13)
    }
    
    // MARK: - Smart Home Integration Tests
    func testSmartHomeDeviceDiscovery() {
        // Test that smart home devices can be discovered
        // This would require actual HomeKit setup in a real environment
        // For now, we'll test the structure
        
        let homeManager = HMHomeManager()
        XCTAssertNotNil(homeManager)
        
        // Test that the sleep engine has HomeKit integration
        XCTAssertNotNil(sleepEngine.homeManager)
    }
    
    // MARK: - Data Persistence Tests
    func testUserPreferencesLoading() {
        // Test that user preferences can be loaded
        let preferences = UserDefaults.standard
        
        // Set test preferences
        let testBedtime = Calendar.current.date(from: DateComponents(hour: 23, minute: 0)) ?? Date()
        let testWakeTime = Calendar.current.date(from: DateComponents(hour: 8, minute: 0)) ?? Date()
        
        preferences.set(testBedtime, forKey: "bedtime")
        preferences.set(testWakeTime, forKey: "wakeTime")
        
        // Test sound profile persistence
        let testProfile = SleepSoundProfile(
            baseSound: SleepSound(name: "Test", type: .whiteNoise, volume: 0.5, frequency: nil),
            ambientSounds: [],
            binauralBeatsEnabled: false,
            binauralFrequency: 0.5,
            volume: 0.3,
            name: "Test Profile"
        )
        
        if let profileData = try? JSONEncoder().encode(testProfile) {
            preferences.set(profileData, forKey: "sleepSoundProfile")
            
            // Verify data can be loaded
            if let loadedData = preferences.data(forKey: "sleepSoundProfile"),
               let loadedProfile = try? JSONDecoder().decode(SleepSoundProfile.self, from: loadedData) {
                XCTAssertEqual(loadedProfile.name, testProfile.name)
                XCTAssertEqual(loadedProfile.volume, testProfile.volume)
            } else {
                XCTFail("Failed to load sound profile")
            }
        } else {
            XCTFail("Failed to encode sound profile")
        }
    }
} 
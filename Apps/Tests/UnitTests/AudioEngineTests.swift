import XCTest
@testable import HealthAI_2030

/// Unit tests for the audio generation and adaptive audio management engines.
///
/// - Covers pink noise, isochronic tones, volume adjustment, and adaptive audio logic.
/// - TODO: Add tests for error handling, edge cases, and integration with device audio APIs.
class AudioEngineTests: XCTestCase {
    func testPinkNoiseGeneration() {
        let engine = AudioGenerationEngine.shared
        engine.generatePinkNoise(intensity: 0.3)
        XCTAssertTrue(engine.isGenerating)
        XCTAssertEqual(engine.currentAudioType, .pinkNoise)
    }
    
    func testIsochronicTonesGeneration() {
        let engine = AudioGenerationEngine.shared
        engine.generateIsochronicTones(frequency: 8.0)
        XCTAssertTrue(engine.isGenerating)
        XCTAssertEqual(engine.currentAudioType, .isochronicTones)
    }
    
    func testVolumeAdjustment() {
        let engine = AudioGenerationEngine.shared
        engine.setVolume(0.7)
        XCTAssertEqual(engine.volume, 0.7)
    }
    
    func testAdaptiveAudioManagerSleepStage() {
        let adaptive = AdaptiveAudioManager.shared
        adaptive.adjustAudio(for: .deepSleep)
        XCTAssertEqual(adaptive.currentAudioType, .pinkNoise)
        XCTAssertEqual(adaptive.currentVolume, 0.2)
    }
    
    func testAdaptiveAudioManagerNoise() {
        let adaptive = AdaptiveAudioManager.shared
        adaptive.currentVolume = 0.5
        adaptive.adjustVolumeForNoise(0.8)
        XCTAssertLessThanOrEqual(adaptive.currentVolume, 0.5)
    }
    
    // MARK: - Invalid Input & Edge Case Tests
    
    func testZeroDuration() {
        let engine = AudioGenerationEngine.shared
        XCTAssertThrowsError(try engine.generateWithDuration(0)) { error in
            XCTAssertEqual(error as? AudioEngineError, .invalidDuration)
        }
    }
    
    func testInvalidEnvironment() {
        let engine = AudioGenerationEngine.shared
        XCTAssertThrowsError(try engine.generateForEnvironment(nil)) { error in
            XCTAssertEqual(error as? AudioEngineError, .invalidEnvironment)
        }
    }
    
    func testMalformedBufferInput() {
        let engine = AudioGenerationEngine.shared
        let malformedBuffer = AudioBuffer(mChannels: 0, mDataByteSize: 0, mData: nil)
        XCTAssertThrowsError(try engine.processBuffer(malformedBuffer)) { error in
            XCTAssertEqual(error as? AudioEngineError, .invalidBuffer)
        }
    }
    
    func testExtremeDurationValues() {
        let engine = AudioGenerationEngine.shared
        
        // Test very large duration
        XCTAssertThrowsError(try engine.generateWithDuration(3600 * 24)) { error in
            XCTAssertEqual(error as? AudioEngineError, .durationTooLong)
        }
        
        // Test negative duration
        XCTAssertThrowsError(try engine.generateWithDuration(-10)) { error in
            XCTAssertEqual(error as? AudioEngineError, .invalidDuration)
        }
    }
    
    func testInvalidVolumeValues() {
        let engine = AudioGenerationEngine.shared
        
        // Test negative volume
        engine.setVolume(-0.5)
        XCTAssertEqual(engine.volume, 0.0)
        
        // Test volume > 1.0
        engine.setVolume(1.5)
        XCTAssertEqual(engine.volume, 1.0)
    }
    
    func testInvalidNoiseIntensity() {
        let engine = AudioGenerationEngine.shared
        
        // Test negative intensity
        engine.generatePinkNoise(intensity: -0.5)
        XCTAssertEqual(engine.currentAudioType, .none)
        
        // Test intensity > 1.0
        engine.generatePinkNoise(intensity: 1.5)
        XCTAssertEqual(engine.currentAudioType, .none)
    }
    
    // MARK: - State Transition Tests
    
    func testStateTransitions() {
        let engine = AudioGenerationEngine.shared
        
        // Start with pink noise
        engine.generatePinkNoise(intensity: 0.3)
        XCTAssertEqual(engine.currentAudioType, .pinkNoise)
        
        // Transition to isochronic tones
        engine.generateIsochronicTones(frequency: 8.0)
        XCTAssertEqual(engine.currentAudioType, .isochronicTones)
        
        // Stop audio
        engine.stop()
        XCTAssertEqual(engine.currentAudioType, .none)
        XCTAssertFalse(engine.isGenerating)
    }
    
    // MARK: - Audio Session Tests
    
    func testAudioSessionInterruptionWithOptions() {
        let engine = AudioGenerationEngine.shared
        let notificationCenter = NotificationCenter.default
        
        // Test interruption with shouldResume option
        engine.generatePinkNoise(intensity: 0.3)
        XCTAssertTrue(engine.isGenerating)
        
        // Simulate interruption with resume option
        notificationCenter.post(
            name: AVAudioSession.interruptionNotification,
            object: nil,
            userInfo: [
                AVAudioSessionInterruptionTypeKey: AVAudioSession.InterruptionType.began.rawValue,
                AVAudioSessionInterruptionOptionKey: AVAudioSession.InterruptionOptions.shouldResume.rawValue
            ]
        )
        XCTAssertFalse(engine.isGenerating)
        
        // Simulate interruption ended
        notificationCenter.post(
            name: AVAudioSession.interruptionNotification,
            object: nil,
            userInfo: [AVAudioSessionInterruptionTypeKey: AVAudioSession.InterruptionType.ended.rawValue]
        )
        XCTAssertTrue(engine.isGenerating)
    }
    
    func testAudioSessionInterruptionWithoutResume() {
        let engine = AudioGenerationEngine.shared
        let notificationCenter = NotificationCenter.default
        
        engine.generatePinkNoise(intensity: 0.3)
        XCTAssertTrue(engine.isGenerating)
        
        // Simulate interruption without resume option
        notificationCenter.post(
            name: AVAudioSession.interruptionNotification,
            object: nil,
            userInfo: [AVAudioSessionInterruptionTypeKey: AVAudioSession.InterruptionType.began.rawValue]
        )
        XCTAssertFalse(engine.isGenerating)
        
        // Simulate interruption ended
        notificationCenter.post(
            name: AVAudioSession.interruptionNotification,
            object: nil,
            userInfo: [AVAudioSessionInterruptionTypeKey: AVAudioSession.InterruptionType.ended.rawValue]
        )
        XCTAssertFalse(engine.isGenerating)
    }
    
    func testAudioSessionRouteChange() {
        let engine = AudioGenerationEngine.shared
        let notificationCenter = NotificationCenter.default
        
        engine.generatePinkNoise(intensity: 0.3)
        XCTAssertTrue(engine.isGenerating)
        
        // Simulate route change (e.g., headphone unplugged)
        notificationCenter.post(
            name: AVAudioSession.routeChangeNotification,
            object: nil,
            userInfo: [
                AVAudioSessionRouteChangeReasonKey: AVAudioSession.RouteChangeReason.oldDeviceUnavailable.rawValue
            ]
        )
        
        // Verify audio stopped
        XCTAssertFalse(engine.isGenerating)
    }
}
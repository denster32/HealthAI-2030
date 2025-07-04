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
    // TODO: Add tests for invalid input, state transitions, and audio session interruptions.
}
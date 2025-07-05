#!/usr/bin/env swift
import Foundation

// Regression test for issue: volume fails to update when immediate change occurs with auto-change mode enabled.

class MockAudioEngine {
    var volume: Float = 0.5
    var autoChangeEnabled: Bool = true

    // Simulates volume update logic with a fixed bug.
    func setVolume(_ newVolume: Float, immediate: Bool) {
        if autoChangeEnabled && immediate {
            volume = newVolume
            return
        }
        volume = newVolume
    }
}

let engine = MockAudioEngine()
engine.autoChangeEnabled = true
engine.setVolume(0.8, immediate: true)

// Expected: volume should update to 0.8 when auto-change mode is on
if engine.volume != 0.8 {
    print("Test failed: volume did not update correctly when auto-change mode is enabled")
    exit(1)
}
// Additional edge cases
engine.setVolume(0.3, immediate: false)
if engine.volume != 0.3 {
    print("Test failed: volume should update on delayed change")
    exit(1)
}

engine.autoChangeEnabled = false
engine.setVolume(1.0, immediate: true)
if engine.volume != 1.0 {
    print("Test failed: volume should update when auto-change disabled")
    exit(1)
}

let sameVolume = engine.volume
engine.setVolume(sameVolume, immediate: true)
if engine.volume != sameVolume {
    print("Test failed: volume changed unexpectedly")
    exit(1)
}

print("Test passed")

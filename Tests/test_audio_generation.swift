#!/usr/bin/env swift
import Foundation

func generateSineWave(frequency: Float, duration: Float, sampleRate: Float) -> [Float] {
    let frameCount = Int(duration * sampleRate)
    var samples = [Float](repeating: 0, count: frameCount)
    for i in 0..<frameCount {
        let time = Float(i) / sampleRate
        samples[i] = sin(time * frequency * 2.0 * Float.pi)
    }
    return samples
}

func generateNoise(frameCount: Int, scale: Float) -> [Float] {
    var samples = [Float](repeating: 0, count: frameCount)
    for i in 0..<frameCount {
        samples[i] = Float.random(in: -1...1) * scale
    }
    return samples
}

func applyVolume(_ samples: [Float], volume: Float) -> [Float] {
    return samples.map { $0 * volume }
}

func applyFade(_ samples: [Float], fadeInDuration: Float, fadeOutDuration: Float, sampleRate: Float) -> [Float] {
    var result = samples
    let fadeInSamples = Int(fadeInDuration * sampleRate)
    let fadeOutSamples = Int(fadeOutDuration * sampleRate)
    for i in 0..<min(fadeInSamples, samples.count) {
        let factor = Float(i) / Float(fadeInSamples)
        result[i] *= factor
    }
    for i in 0..<min(fadeOutSamples, samples.count) {
        let idx = samples.count - 1 - i
        let factor = Float(i) / Float(fadeOutSamples)
        result[idx] *= factor
    }
    return result
}

// MARK: - Tests

let sine = generateSineWave(frequency: 1.0, duration: 1.0, sampleRate: 4.0)
let expectedSine: [Float] = [0.0, 1.0, 0.0, -1.0]
for i in 0..<expectedSine.count { assert(abs(sine[i] - expectedSine[i]) < 0.0001) }

let noise = generateNoise(frameCount: 16, scale: 0.2)
assert(noise.count == 16)
for n in noise { assert(n >= -0.2 && n <= 0.2) }

let volResult = applyVolume([1,1,1,1], volume: 0.5)
assert(volResult == [0.5,0.5,0.5,0.5])

let fadeInput = Array(repeating: Float(1), count: 8)
let faded = applyFade(fadeInput, fadeInDuration: 1.0, fadeOutDuration: 1.0, sampleRate: 4.0)
assert(abs(faded.first ?? 1 - 0) < 0.0001)
assert(abs(faded.last ?? 1 - 0) < 0.0001)

// Edge cases
let zeroDuration = generateSineWave(frequency: 440.0, duration: 0.0, sampleRate: 4.0)
assert(zeroDuration.isEmpty)

let zeroFrequency = generateSineWave(frequency: 0.0, duration: 1.0, sampleRate: 4.0)
for sample in zeroFrequency { assert(abs(sample) < 0.0001) }

let zeroNoise = generateNoise(frameCount: 0, scale: 1.0)
assert(zeroNoise.isEmpty)

let negativeVolume = applyVolume([1.0], volume: -0.5)
assert(negativeVolume == [-0.5])

let highVolume = applyVolume([1.0], volume: 1.5)
assert(highVolume == [1.5])

let shortFade = applyFade([1, 1], fadeInDuration: 3.0, fadeOutDuration: 3.0, sampleRate: 1.0)
assert(shortFade.count == 2)
assert(abs(shortFade.first ?? 1 - 0) < 0.0001)
assert(abs(shortFade.last ?? 1 - 0) < 0.0001)

print("All audio generation tests passed")

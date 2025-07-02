#!/usr/bin/env swift
import Foundation

enum SleepStage: String {
    case awake = "awake"
    case light = "light"
    case deep = "deep"
    case rem = "rem"
    case unknown = "unknown"

    var displayName: String {
        switch self {
        case .awake: return "Awake"
        case .light: return "Light Sleep"
        case .deep: return "Deep Sleep"
        case .rem: return "REM Sleep"
        case .unknown: return "Unknown"
        }
    }

    var color: String {
        switch self {
        case .awake: return "red"
        case .light: return "blue"
        case .deep: return "purple"
        case .rem: return "green"
        case .unknown: return "gray"
        }
    }

    var icon: String {
        switch self {
        case .awake: return "eye"
        case .light: return "moon"
        case .deep: return "bed.double"
        case .rem: return "brain.head.profile"
        case .unknown: return "questionmark"
        }
    }
}

struct SleepSession {
    let startTime: Date
    var endTime: Date?
    var sleepStage: SleepStage
    var quality: Double
    var cycleCount: Int

    var duration: TimeInterval {
        return endTime?.timeIntervalSince(startTime) ?? 0
    }
}

enum NoiseColor: String { case white = "White" }

enum PreSleepAudioType {
    case binauralBeats(frequency: Double)
    case whiteNoise(color: NoiseColor)

    var displayName: String {
        switch self {
        case .binauralBeats(let freq): return "Binaural Beats (\(Int(freq))Hz)"
        case .whiteNoise(let color): return "\(color.rawValue) Noise"
        }
    }
}

let start = Date()
let end = start.addingTimeInterval(3600)
let session = SleepSession(startTime: start, endTime: end, sleepStage: .deep, quality: 0.8, cycleCount: 2)
assert(abs(session.duration - 3600) < 0.001)

assert(SleepStage.awake.displayName == "Awake")
assert(SleepStage.light.color == "blue")
assert(SleepStage.deep.icon == "bed.double")

let audio1 = PreSleepAudioType.binauralBeats(frequency: 6.0)
assert(audio1.displayName == "Binaural Beats (6Hz)")
let audio2 = PreSleepAudioType.whiteNoise(color: .white)
assert(audio2.displayName == "White Noise")

// Edge cases
let incompleteSession = SleepSession(startTime: start, endTime: nil, sleepStage: .awake, quality: 0.0, cycleCount: 0)
assert(incompleteSession.duration == 0)

let zeroFreqAudio = PreSleepAudioType.binauralBeats(frequency: 0.0)
assert(zeroFreqAudio.displayName == "Binaural Beats (0Hz)")

func normalizeHeartRate(_ hr: Double) -> Double {
    return max(0, min(1, (hr - 40) / 60))
}

assert(normalizeHeartRate(30) == 0)
assert(normalizeHeartRate(100) == 1)

print("All tests passed")

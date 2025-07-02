import Foundation
import Combine
import CoreHaptics // For haptic feedback
import AVFoundation // For audio generation

/// Manages adaptive audio generation for biofeedback sessions
/// Provides real-time audio parameter adjustments based on HRV coherence
class AdaptiveAudioManager: ObservableObject {
    static let shared = AdaptiveAudioManager()
    
    // MARK: - Published Properties
    @Published var isPlaying = false
    @Published var currentVolume: Float = 0.7
    @Published var currentTempo: Double = 60.0
    @Published var currentHarmony: Double = 0.5
    
    // MARK: - Private Properties
    private var audioEngine: AVAudioEngine?
    private var audioPlayer: AVAudioPlayerNode?
    private var audioBuffer: AVAudioPCMBuffer?
    private var timer: Timer?
    private var currentCoherence: Double = 0.0
    
    // Audio generation parameters
    private var baseFrequency: Float = 440.0 // A4 note
    private var sampleRate: Double = 44100.0
    private var frameCount: AVAudioFrameCount = 44100 // 1 second buffer
    
    // Coherence thresholds
    private let lowCoherenceThreshold: Double = 0.3
    private let mediumCoherenceThreshold: Double = 0.7
    private let highCoherenceThreshold: Double = 0.9
    
    private var cancellables = Set<AnyCancellable>()
    private let audioEngine = AudioGenerationEngine.shared
    private var hapticEngine: CHHapticEngine?
    
    private init() {
        setupHapticEngine()
        setupAudioEngine()
    }
    
    deinit {
        cleanup()
    }
    
    // MARK: - Haptic Engine Setup
    private func setupHapticEngine() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else {
            print("Haptics not supported on this device.")
            return
        }
        
        do {
            hapticEngine = try CHHapticEngine()
            try hapticEngine?.start()
        } catch {
            print("Error creating haptic engine: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Audio Adjustments
    func applyAudioNudge(type: AudioType, intensity: Double) {
        currentAudioType = type
        currentVolume = Float(intensity)
        audioEngine.setVolume(currentVolume)
        
        switch type {
        case .pinkNoise:
            audioEngine.generatePinkNoise(intensity: intensity)
        case .isochronicTones:
            // Assuming a default frequency for isochronic tones if not specified by NudgeAction
            audioEngine.generateIsochronicTones(frequency: 4.0)
        case .binauralBeats:
            // Assuming default base and beat frequencies for binaural beats
            audioEngine.generateBinauralBeats(baseFrequency: 200, beatFrequency: 10.0)
        case .whiteNoise:
            audioEngine.generateWhiteNoise(intensity: intensity)
        case .natureSounds:
            // Assuming a default nature sound type if not specified by NudgeAction
            audioEngine.generateNatureSounds(type: .rain)
        case .none:
            audioEngine.stopAudio()
        }
    }
    
    func setUserPreferredVolume(_ volume: Float) {
        currentVolume = max(0.0, min(1.0, volume))
        audioEngine.setVolume(currentVolume)
    }
    
    func stopAudio() {
        audioEngine.stopAudio()
        currentAudioType = .none
        currentVolume = 0.0
    }
    
    // MARK: - Specific Audio Methods for RLAgent Integration
    
    func playPinkNoise() {
        applyAudioNudge(type: .pinkNoise, intensity: 0.6)
    }
    
    func playIsochronicTones() {
        applyAudioNudge(type: .isochronicTones, intensity: 0.5)
    }
    
    func playBinauralBeats() {
        applyAudioNudge(type: .binauralBeats, intensity: 0.5)
    }
    
    func playNatureSounds() {
        applyAudioNudge(type: .natureSounds, intensity: 0.4)
    }
    
    // MARK: - Haptic Feedback
    func applyHapticNudge(intensity: Double) {
        // Using a default sharpness for now, as NudgeAction only provides intensity
        playHapticPattern(intensity: intensity, sharpness: 0.5)
    }
    
    private func playHapticPattern(intensity: Double, sharpness: Double) {
        guard let hapticEngine = hapticEngine else { return }
        
        // Create a haptic event
        let hapticEvent = CHHapticEvent(eventType: .hapticContinuous, parameters: [
            CHHapticEventParameter(parameterID: .hapticIntensity, value: Float(intensity)),
            CHHapticEventParameter(parameterID: .hapticSharpness, value: Float(sharpness))
        ], relativeTime: 0)
        
        do {
            let pattern = try CHHapticPattern(events: [hapticEvent], parameters: [])
            let player = try hapticEngine.makePlayer(with: pattern)
            try player.start(atTime: CHHapticTimeImmediate)
        } catch {
            print("Error playing haptic pattern: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Public Methods
    
    /// Configure audio for biofeedback sessions
    func configureForBiofeedback() {
        generateBaseAudioBuffer()
    }
    
    /// Start adaptive audio playback
    func startAdaptiveAudio(coherence: Double) {
        currentCoherence = coherence
        updateAudioParameters()
        
        guard let audioEngine = audioEngine,
              let audioPlayer = audioPlayer else { return }
        
        do {
            try audioEngine.start()
            audioPlayer.play()
            isPlaying = true
            
            // Start timer for continuous parameter updates
            timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
                self.updateAudioParameters()
            }
        } catch {
            print("Failed to start audio: \(error)")
        }
    }
    
    /// Stop audio playback
    func stopAudio() {
        audioPlayer?.stop()
        audioEngine?.stop()
        timer?.invalidate()
        timer = nil
        isPlaying = false
    }
    
    /// Update coherence value and adjust audio accordingly
    func updateCoherence(_ coherence: Double) {
        currentCoherence = coherence
        updateAudioParameters()
    }
    
    // MARK: - Private Methods
    
    private func setupAudioEngine() {
        audioEngine = AVAudioEngine()
        audioPlayer = AVAudioPlayerNode()
        
        guard let audioEngine = audioEngine,
              let audioPlayer = audioPlayer else { return }
        
        audioEngine.attach(audioPlayer)
        
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 2)!
        audioEngine.connect(audioPlayer, to: audioEngine.mainMixerNode, format: format)
        
        // Add reverb effect for immersive experience
        let reverb = AVAudioUnitReverb()
        reverb.loadFactoryPreset(.cathedral)
        reverb.wetDryMix = 30.0
        
        audioEngine.attach(reverb)
        audioEngine.connect(audioPlayer, to: reverb, format: format)
        audioEngine.connect(reverb, to: audioEngine.mainMixerNode, format: format)
        
        do {
            try audioEngine.prepare()
        } catch {
            print("Failed to prepare audio engine: \(error)")
        }
    }
    
    private func generateBaseAudioBuffer() {
        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 2) else { return }
        
        audioBuffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)
        guard let buffer = audioBuffer else { return }
        
        // Generate base ambient sound
        let channelData = buffer.floatChannelData!
        let channelCount = Int(format.channelCount)
        
        for frame in 0..<Int(frameCount) {
            let time = Double(frame) / sampleRate
            let frequency = baseFrequency
            
            // Generate sine wave with harmonics
            var sample: Float = 0.0
            for harmonic in 1...3 {
                let harmonicFreq = frequency * Float(harmonic)
                sample += sin(2.0 * Float.pi * harmonicFreq * Float(time)) / Float(harmonic)
            }
            
            // Apply envelope for smooth transitions
            let envelope = calculateEnvelope(time: time)
            sample *= envelope
            
            // Apply to all channels
            for channel in 0..<channelCount {
                channelData[channel][frame] = sample * 0.3 // Reduce volume
            }
        }
        
        buffer.frameLength = frameCount
    }
    
    private func calculateEnvelope(time: Double) -> Float {
        // Create a smooth envelope that repeats every 4 seconds (breathing cycle)
        let cycleTime = time.truncatingRemainder(dividingBy: 4.0)
        let normalizedTime = cycleTime / 4.0
        
        // Smooth rise and fall
        if normalizedTime < 0.5 {
            // Rise phase (inhale)
            return Float(sin(normalizedTime * .pi))
        } else {
            // Fall phase (exhale)
            return Float(sin((1.0 - normalizedTime) * .pi))
        }
    }
    
    private func updateAudioParameters() {
        guard let audioPlayer = audioPlayer else { return }
        
        // Update volume based on coherence
        let targetVolume = calculateTargetVolume()
        audioPlayer.volume = targetVolume
        currentVolume = targetVolume
        
        // Update tempo based on coherence
        let targetTempo = calculateTargetTempo()
        currentTempo = targetTempo
        
        // Update harmony based on coherence
        let targetHarmony = calculateTargetHarmony()
        currentHarmony = targetHarmony
        
        // Apply real-time effects
        applyCoherenceEffects()
    }
    
    private func calculateTargetVolume() -> Float {
        switch currentCoherence {
        case 0.0..<lowCoherenceThreshold:
            return 0.4 // Lower volume for low coherence
        case lowCoherenceThreshold..<mediumCoherenceThreshold:
            return 0.6 // Medium volume
        case mediumCoherenceThreshold..<highCoherenceThreshold:
            return 0.8 // Higher volume for good coherence
        default:
            return 1.0 // Full volume for excellent coherence
        }
    }
    
    private func calculateTargetTempo() -> Double {
        switch currentCoherence {
        case 0.0..<lowCoherenceThreshold:
            return 45.0 // Slower tempo for low coherence
        case lowCoherenceThreshold..<mediumCoherenceThreshold:
            return 55.0 // Medium tempo
        case mediumCoherenceThreshold..<highCoherenceThreshold:
            return 65.0 // Faster tempo for good coherence
        default:
            return 75.0 // Optimal tempo for excellent coherence
        }
    }
    
    private func calculateTargetHarmony() -> Double {
        switch currentCoherence {
        case 0.0..<lowCoherenceThreshold:
            return 0.2 // Simple harmony for low coherence
        case lowCoherenceThreshold..<mediumCoherenceThreshold:
            return 0.5 // Medium harmony complexity
        case mediumCoherenceThreshold..<highCoherenceThreshold:
            return 0.8 // Rich harmony for good coherence
        default:
            return 1.0 // Full harmonic complexity for excellent coherence
        }
    }
    
    private func applyCoherenceEffects() {
        guard let audioPlayer = audioPlayer else { return }
        
        // Apply pitch shift based on coherence
        let pitchShift = calculatePitchShift()
        audioPlayer.pitch = pitchShift
        
        // Apply playback rate based on tempo
        let playbackRate = currentTempo / 60.0
        audioPlayer.rate = Float(playbackRate)
    }
    
    private func calculatePitchShift() -> Float {
        switch currentCoherence {
        case 0.0..<lowCoherenceThreshold:
            return -0.5 // Lower pitch for low coherence
        case lowCoherenceThreshold..<mediumCoherenceThreshold:
            return 0.0 // Normal pitch
        case mediumCoherenceThreshold..<highCoherenceThreshold:
            return 0.3 // Slightly higher pitch for good coherence
        default:
            return 0.5 // Higher pitch for excellent coherence
        }
    }
    
    private func cleanup() {
        stopAudio()
        audioEngine = nil
        audioPlayer = nil
        audioBuffer = nil
    }
}

// MARK: - Audio Generation Extensions

extension AdaptiveAudioManager {
    
    /// Generate binaural beats for enhanced relaxation
    func generateBinauralBeats(frequency: Double, duration: TimeInterval) -> AVAudioPCMBuffer? {
        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 2) else { return nil }
        
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)
        guard let audioBuffer = buffer else { return nil }
        
        let channelData = audioBuffer.floatChannelData!
        
        for frame in 0..<Int(frameCount) {
            let time = Double(frame) / sampleRate
            
            // Left channel: base frequency
            let leftSample = sin(2.0 * .pi * frequency * time)
            
            // Right channel: base frequency + beat frequency
            let beatFrequency = 10.0 // 10 Hz alpha wave
            let rightSample = sin(2.0 * .pi * (frequency + beatFrequency) * time)
            
            channelData[0][frame] = Float(leftSample) * 0.3
            channelData[1][frame] = Float(rightSample) * 0.3
        }
        
        audioBuffer.frameLength = frameCount
        return audioBuffer
    }
    
    /// Generate isochronic tones for brain entrainment
    func generateIsochronicTones(baseFrequency: Double, beatFrequency: Double, duration: TimeInterval) -> AVAudioPCMBuffer? {
        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 2) else { return nil }
        
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)
        guard let audioBuffer = buffer else { return nil }
        
        let channelData = audioBuffer.floatChannelData!
        
        for frame in 0..<Int(frameCount) {
            let time = Double(frame) / sampleRate
            
            // Create amplitude modulation for isochronic effect
            let modulation = 0.5 + 0.5 * sin(2.0 * .pi * beatFrequency * time)
            let sample = sin(2.0 * .pi * baseFrequency * time) * modulation
            
            // Apply to both channels
            channelData[0][frame] = Float(sample) * 0.3
            channelData[1][frame] = Float(sample) * 0.3
        }
        
        audioBuffer.frameLength = frameCount
        return audioBuffer
    }
}
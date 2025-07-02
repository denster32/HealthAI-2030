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
    private var hapticEngine: CHHapticEngine?
    
    // MARK: - Audio Generation Engine
    private let audioGenerationEngine = AudioGenerationEngine.shared
    
    private init() {
        setupHapticEngine()
    }
    
    deinit {
        audioGenerationEngine.stopAudio()
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
    func applyAudioNudge(type: AudioNudgeType, intensity: Double) {
        audioGenerationEngine.setVolume(Float(intensity))
        
        switch type {
        case .pinkNoise:
            audioGenerationEngine.generatePinkNoise(intensity: intensity)
        case .isochronicTones:
            audioGenerationEngine.generateIsochronicTones(frequency: 4.0)
        case .binauralBeats:
            audioGenerationEngine.generateBinauralBeats(baseFrequency: 200, beatFrequency: 10.0)
        case .natureSounds:
            audioGenerationEngine.generateNatureSounds(type: .rain)
        }
    }
    
    func setUserPreferredVolume(_ volume: Float) {
        audioGenerationEngine.setVolume(volume)
    }
    
    func stopAudio() {
        audioGenerationEngine.stopAudio()
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
        playHapticPattern(intensity: intensity, sharpness: 0.5)
    }
    
    private func playHapticPattern(intensity: Double, sharpness: Double) {
        guard let hapticEngine = hapticEngine else { return }
        
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
    
    func configureForBiofeedback() {
        // This method might be removed or adapted if audio generation is fully externalized
    }
    
    func startAdaptiveAudio(coherence: Double) {
        // This method might be removed or adapted if audio generation is fully externalized
    }
    
    func updateCoherence(_ coherence: Double) {
        // This method might be removed or adapted if audio generation is fully externalized
    }
}

// MARK: - Supporting Types

enum AudioNudgeType: Codable, Hashable {
    case pinkNoise
    case isochronicTones
    case binauralBeats
    case natureSounds
}

// Placeholder for AudioGenerationEngine - this would be a separate class
class AudioGenerationEngine {
    static let shared = AudioGenerationEngine()
    
    private var audioEngine: AVAudioEngine?
    private var audioPlayer: AVAudioPlayerNode?
    private var audioBuffer: AVAudioPCMBuffer?
    private var timer: Timer?
    
    private var baseFrequency: Float = 440.0
    private var sampleRate: Double = 44100.0
    private var frameCount: AVAudioFrameCount = 44100
    
    private init() {
        setupAudioEngine()
    }
    
    private func setupAudioEngine() {
        audioEngine = AVAudioEngine()
        audioPlayer = AVAudioPlayerNode()
        
        guard let audioEngine = audioEngine,
              let audioPlayer = audioPlayer else { return }
        
        audioEngine.attach(audioPlayer)
        
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 2)!
        audioEngine.connect(audioPlayer, to: audioEngine.mainMixerNode, format: format)
        
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
    
    func setVolume(_ volume: Float) {
        audioPlayer?.volume = volume
    }
    
    func stopAudio() {
        audioPlayer?.stop()
        audioEngine?.stop()
        timer?.invalidate()
        timer = nil
    }
    
    func generatePinkNoise(intensity: Double) {
        print("Generating pink noise with intensity: \(intensity)")
        // Placeholder for actual pink noise generation
        startPlayback()
    }
    
    func generateIsochronicTones(frequency: Double) {
        print("Generating isochronic tones with frequency: \(frequency)")
        // Placeholder for actual isochronic tone generation
        startPlayback()
    }
    
    func generateBinauralBeats(baseFrequency: Double, beatFrequency: Double) {
        print("Generating binaural beats with base: \(baseFrequency), beat: \(beatFrequency)")
        // Placeholder for actual binaural beats generation
        startPlayback()
    }
    
    func generateNatureSounds(type: NatureSoundType) {
        print("Generating nature sounds of type: \(type)")
        // Placeholder for actual nature sounds generation
        startPlayback()
    }
    
    private func startPlayback() {
        guard let audioEngine = audioEngine,
              let audioPlayer = audioPlayer else { return }
        
        do {
            try audioEngine.start()
            audioPlayer.play()
        } catch {
            print("Failed to start audio playback: \(error)")
        }
    }
}

enum NatureSoundType {
    case rain
    case ocean
    case forest
}
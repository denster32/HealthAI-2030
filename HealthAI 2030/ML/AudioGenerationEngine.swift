import Foundation
import AVFoundation
import Accelerate

class AudioGenerationEngine: ObservableObject {
    static let shared = AudioGenerationEngine()
    
    private var audioEngine: AVAudioEngine?
    private var audioPlayer: AVAudioPlayerNode?
    private var audioMixer: AVAudioMixerNode?
    
    // Audio generation parameters
    @Published var isGenerating: Bool = false
    @Published var currentAudioType: AudioType = .none
    @Published var volume: Float = 0.5
    @Published var frequency: Double = 200.0
    
    // Sleep-specific audio parameters
    private var adaptiveMode: Bool = true
    
    private init() {
        setupAudioEngine()
    }
    
    // MARK: - Audio Engine Setup
    
    private func setupAudioEngine() {
        audioEngine = AVAudioEngine()
        audioPlayer = AVAudioPlayerNode()
        audioMixer = audioEngine?.mainMixerNode
        
        guard let audioEngine = audioEngine,
              let audioPlayer = audioPlayer else { return }
        
        audioEngine.attach(audioPlayer)
        audioEngine.connect(audioPlayer, to: audioMixer!, format: nil)
        
        do {
            try audioEngine.start()
        } catch {
            print("Failed to start audio engine: \(error)")
        }
    }
    
    // MARK: - Audio Generation Methods
    
    func generatePinkNoise(intensity: Double) {
        let sampleRate: Double = 44100
        let duration: Double = 60 // 1 minute loop
        
        var pinkNoise: [Float] = []
        for i in 0..<Int(sampleRate * duration) {
            let frequency = Double(i) / (sampleRate * duration) * 2000
            let amplitude = 1.0 / sqrt(frequency + 1.0) * Float(intensity)
            let sample = amplitude * sin(2.0 * .pi * frequency * Double(i) / sampleRate)
            pinkNoise.append(sample)
        }
        
        playAudioBuffer(pinkNoise, sampleRate: sampleRate)
        isGenerating = true
    }
    
    func generateIsochronicTones(frequency: Double) {
        let sampleRate: Double = 44100
        let duration: Double = 60 // 1 minute loop
        let carrierFreq: Double = 200 // Hz
        let beatFreq: Double = frequency // Hz
        
        var tones: [Float] = []
        for i in 0..<Int(sampleRate * duration) {
            let time = Double(i) / sampleRate
            let envelope = sin(2.0 * .pi * beatFreq * time)
            let carrier = sin(2.0 * .pi * carrierFreq * time)
            let sample = Float(volume) * Float(envelope) * Float(carrier)
            tones.append(sample)
        }
        
        playAudioBuffer(tones, sampleRate: sampleRate)
        isGenerating = true
    }
    
    func generateBinauralBeats(baseFrequency: Double, beatFrequency: Double) {
        let sampleRate: Double = 44100
        let duration: Double = 60 // 1 minute loop
        
        var leftChannel: [Float] = []
        var rightChannel: [Float] = []
        
        for i in 0..<Int(sampleRate * duration) {
            let time = Double(i) / sampleRate
            
            // Left ear: base frequency
            let leftSample = sin(2.0 * .pi * baseFrequency * time)
            
            // Right ear: base frequency + beat frequency
            let rightSample = sin(2.0 * .pi * (baseFrequency + beatFrequency) * time)
            
            leftChannel.append(Float(leftSample) * Float(volume))
            rightChannel.append(Float(rightSample) * Float(volume))
        }
        
        playStereoAudioBuffer(leftChannel: leftChannel, rightChannel: rightChannel, sampleRate: sampleRate)
        isGenerating = true
    }
    
    func generateWhiteNoise(intensity: Double) {
        let sampleRate: Double = 44100
        let duration: Double = 60 // 1 minute loop
        
        var whiteNoise: [Float] = []
        for _ in 0..<Int(sampleRate * duration) {
            let sample = Float.random(in: -1...1) * Float(intensity)
            whiteNoise.append(sample)
        }
        
        playAudioBuffer(whiteNoise, sampleRate: sampleRate)
        isGenerating = true
    }
    
    func generateNatureSounds(type: NatureSoundType) {
        // Generate nature sounds (rain, ocean, forest, etc.)
        let sampleRate: Double = 44100
        let duration: Double = 60 // 1 minute loop
        
        var natureSounds: [Float] = []
        
        switch type {
        case .rain:
            // Generate rain sound
            for i in 0..<Int(sampleRate * duration) {
                let time = Double(i) / sampleRate
                let rainDrop = sin(2.0 * .pi * 800 * time) * exp(-time * 0.1)
                let background = sin(2.0 * .pi * 200 * time) * 0.1
                let sample = Float(rainDrop + background) * Float(volume)
                natureSounds.append(sample)
            }
        case .ocean:
            // Generate ocean wave sound
            for i in 0..<Int(sampleRate * duration) {
                let time = Double(i) / sampleRate
                let wave = sin(2.0 * .pi * 0.1 * time) * sin(2.0 * .pi * 100 * time)
                let sample = Float(wave) * Float(volume)
                natureSounds.append(sample)
            }
        case .forest:
            // Generate forest ambient sound
            for i in 0..<Int(sampleRate * duration) {
                let time = Double(i) / sampleRate
                let bird = sin(2.0 * .pi * 1200 * time) * exp(-time * 0.05)
                let wind = sin(2.0 * .pi * 50 * time) * 0.2
                let sample = Float(bird + wind) * Float(volume)
                natureSounds.append(sample)
            }
        }
        
        playAudioBuffer(natureSounds, sampleRate: sampleRate)
        isGenerating = true
    }
    
    // MARK: - Audio Playback
    
    private func playAudioBuffer(_ samples: [Float], sampleRate: Double) {
        guard let audioPlayer = audioPlayer else { return }
        
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(samples.count))!
        
        buffer.frameLength = AVAudioFrameCount(samples.count)
        buffer.floatChannelData?[0].assign(from: samples, count: samples.count)
        
        audioPlayer.scheduleBuffer(buffer, at: nil, options: .loops, completionHandler: nil)
        audioPlayer.play()
    }
    
    private func playStereoAudioBuffer(leftChannel: [Float], rightChannel: [Float], sampleRate: Double) {
        guard let audioPlayer = audioPlayer else { return }
        
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 2)!
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(leftChannel.count))!
        
        buffer.frameLength = AVAudioFrameCount(leftChannel.count)
        buffer.floatChannelData?[0].assign(from: leftChannel, count: leftChannel.count)
        buffer.floatChannelData?[1].assign(from: rightChannel, count: rightChannel.count)
        
        audioPlayer.scheduleBuffer(buffer, at: nil, options: .loops, completionHandler: nil)
        audioPlayer.play()
    }
    
    // MARK: - Audio Control
    
    func stopAudio() {
        audioPlayer?.stop()
        isGenerating = false
        currentAudioType = .none
    }
    
    func pauseAudio() {
        audioPlayer?.pause()
        isGenerating = false
    }
    
    func resumeAudio() {
        audioPlayer?.play()
        isGenerating = true
    }
    
    func setVolume(_ newVolume: Float) {
        volume = max(0.0, min(1.0, newVolume))
        audioPlayer?.volume = volume
    }
    
    func setFrequency(_ newFrequency: Double) {
        frequency = newFrequency
        if isGenerating && adaptiveMode {
            // Regenerate audio with new frequency
            // This method will be called by AdaptiveAudioManager directly with specific audio types
        }
    }
    
    // MARK: - Adaptive Audio
    
    func enableAdaptiveMode(_ enabled: Bool) {
        adaptiveMode = enabled
    }
    
    func adaptToHeartRate(_ heartRate: Double) {
        guard adaptiveMode else { return }
        
        // Adjust audio based on heart rate
        if heartRate > 80 {
            // High heart rate - use calming sounds
            generateNatureSounds(type: .ocean)
        } else if heartRate < 60 {
            // Low heart rate - use gentle tones
            generateIsochronicTones(frequency: 4.0)
        }
    }
    
    func adaptToHRV(_ hrv: Double) {
        guard adaptiveMode else { return }
        
        // Adjust audio based on HRV
        if hrv < 30 {
            // Low HRV - stress reduction
            generateBinauralBeats(baseFrequency: 200, beatFrequency: 10.0)
        } else if hrv > 60 {
            // High HRV - maintain current state
            // Continue with current audio
        }
    }
    
    // MARK: - Audio Analysis
    
    func analyzeAudioEffectiveness() -> AudioEffectiveness {
        // Analyze how effective the current audio is for sleep
        // This would integrate with sleep stage detection
        
        return AudioEffectiveness(
            sleepLatency: 0.0,
            sleepEfficiency: 0.0,
            wakeCount: 0,
            deepSleepPercentage: 0.0,
            recommendation: "Continue current audio pattern"
        )
    }
}

// MARK: - Supporting Types

enum AudioType: Codable, Hashable { // Added Codable and Hashable conformance
    case none
    case pinkNoise
    case isochronicTones
    case binauralBeats
    case whiteNoise
    case natureSounds
}

enum NatureSoundType: Codable, Hashable { // Added Codable and Hashable conformance
    case rain
    case ocean
    case forest
}

struct AudioEffectiveness: Codable, Hashable { // Added Codable and Hashable conformance
    let sleepLatency: TimeInterval
    let sleepEfficiency: Double
    let wakeCount: Int
    let deepSleepPercentage: Double
    let recommendation: String
}
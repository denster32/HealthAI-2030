import Foundation
import AVFoundation
import Accelerate

// MARK: - Binaural Beat Generator

class BinauralBeatGenerator {
    private let sampleRate: Double
    
    init(sampleRate: Double) {
        self.sampleRate = sampleRate
    }
    
    func generateBeat(frequency: Double, duration: TimeInterval) -> AVAudioPCMBuffer {
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 2)!
        
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
            return createEmptyBuffer()
        }
        
        buffer.frameLength = frameCount
        
        // Enhanced binaural beat parameters
        let baseFrequency = 200.0 // Base carrier frequency
        let leftFreq = baseFrequency
        let rightFreq = baseFrequency + frequency // Beat frequency difference
        
        // Add harmonic content for richer sound
        let harmonics = [1.0, 0.3, 0.1, 0.05] // Fundamental + harmonics
        let harmonicWeights = [1.0, 0.5, 0.25, 0.125]
        
        guard let leftChannel = buffer.floatChannelData?[0],
              let rightChannel = buffer.floatChannelData?[1] else {
            return buffer
        }
        
        for i in 0..<Int(frameCount) {
            let time = Double(i) / sampleRate
            
            // Calculate smooth envelope (fade in/out + breathing pattern)
            let envelope = calculateSmoothEnvelope(frame: i, totalFrames: Int(frameCount), time: time)
            
            // Generate left channel with harmonics
            var leftSample = 0.0
            for (harmonic, weight) in zip(harmonics, harmonicWeights) {
                leftSample += sin(2.0 * .pi * leftFreq * harmonic * time) * weight
            }
            
            // Generate right channel with harmonics
            var rightSample = 0.0
            for (harmonic, weight) in zip(harmonics, harmonicWeights) {
                rightSample += sin(2.0 * .pi * rightFreq * harmonic * time) * weight
            }
            
            // Apply envelope and normalize
            leftSample *= envelope * 0.3
            rightSample *= envelope * 0.3
            
            leftChannel[i] = Float(leftSample)
            rightChannel[i] = Float(rightSample)
        }
        
        return buffer
    }
    
    private func calculateSmoothEnvelope(frame: Int, totalFrames: Int, time: Double) -> Double {
        // Fade in/out envelope
        let fadeInDuration = 10.0 // 10 second fade in
        let fadeOutDuration = 10.0 // 10 second fade out
        let fadeInFrames = Int(fadeInDuration * sampleRate)
        let fadeOutFrames = Int(fadeOutDuration * sampleRate)
        
        let fadeInEnvelope = frame < fadeInFrames ? Double(frame) / Double(fadeInFrames) : 1.0
        let fadeOutEnvelope = frame > (totalFrames - fadeOutFrames) ? 
            Double(totalFrames - frame) / Double(fadeOutFrames) : 1.0
        
        // Breathing pattern modulation (4-second inhale, 4-second exhale)
        let breathingCycle = 8.0 // seconds
        let breathingPhase = time.truncatingRemainder(dividingBy: breathingCycle) / breathingCycle
        let breathingModulation = 0.95 + 0.05 * sin(2.0 * .pi * breathingPhase)
        
        return fadeInEnvelope * fadeOutEnvelope * breathingModulation
    }
    
    private func createEmptyBuffer() -> AVAudioPCMBuffer {
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 2)!
        return AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 1024)!
    }
}

// MARK: - White Noise Generator

class WhiteNoiseGenerator {
    private let sampleRate: Double
    
    init(sampleRate: Double) {
        self.sampleRate = sampleRate
    }
    
    func generateNoise(color: NoiseColor, duration: TimeInterval) -> AVAudioPCMBuffer {
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 2)!
        
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
            return createEmptyBuffer()
        }
        
        buffer.frameLength = frameCount
        
        guard let leftChannel = buffer.floatChannelData?[0],
              let rightChannel = buffer.floatChannelData?[1] else {
            return buffer
        }
        
        switch color {
        case .white:
            generateWhiteNoise(leftChannel: leftChannel, rightChannel: rightChannel, frameCount: Int(frameCount))
        case .pink:
            generatePinkNoise(leftChannel: leftChannel, rightChannel: rightChannel, frameCount: Int(frameCount))
        case .brown:
            generateBrownNoise(leftChannel: leftChannel, rightChannel: rightChannel, frameCount: Int(frameCount))
        case .blue:
            generateBlueNoise(leftChannel: leftChannel, rightChannel: rightChannel, frameCount: Int(frameCount))
        }
        
        return buffer
    }
    
    private func generateWhiteNoise(leftChannel: UnsafeMutablePointer<Float>, rightChannel: UnsafeMutablePointer<Float>, frameCount: Int) {
        for i in 0..<frameCount {
            let envelope = calculateNoiseEnvelope(frame: i, totalFrames: frameCount)
            leftChannel[i] = Float.random(in: -1...1) * Float(envelope) * 0.3
            rightChannel[i] = Float.random(in: -1...1) * Float(envelope) * 0.3
        }
    }
    
    private func generatePinkNoise(leftChannel: UnsafeMutablePointer<Float>, rightChannel: UnsafeMutablePointer<Float>, frameCount: Int) {
        // Pink noise using the Voss algorithm
        var b0L: Float = 0, b1L: Float = 0, b2L: Float = 0, b3L: Float = 0, b4L: Float = 0, b5L: Float = 0, b6L: Float = 0
        var b0R: Float = 0, b1R: Float = 0, b2R: Float = 0, b3R: Float = 0, b4R: Float = 0, b5R: Float = 0, b6R: Float = 0
        
        for i in 0..<frameCount {
            let envelope = calculateNoiseEnvelope(frame: i, totalFrames: frameCount)
            
            // Left channel pink noise
            let whiteL = Float.random(in: -1...1)
            b0L = 0.99886 * b0L + whiteL * 0.0555179
            b1L = 0.99332 * b1L + whiteL * 0.0750759
            b2L = 0.96900 * b2L + whiteL * 0.1538520
            b3L = 0.86650 * b3L + whiteL * 0.3104856
            b4L = 0.55000 * b4L + whiteL * 0.5329522
            b5L = -0.7616 * b5L - whiteL * 0.0168980
            let pinkL = b0L + b1L + b2L + b3L + b4L + b5L + b6L + whiteL * 0.5362
            b6L = whiteL * 0.115926
            
            // Right channel pink noise
            let whiteR = Float.random(in: -1...1)
            b0R = 0.99886 * b0R + whiteR * 0.0555179
            b1R = 0.99332 * b1R + whiteR * 0.0750759
            b2R = 0.96900 * b2R + whiteR * 0.1538520
            b3R = 0.86650 * b3R + whiteR * 0.3104856
            b4R = 0.55000 * b4R + whiteR * 0.5329522
            b5R = -0.7616 * b5R - whiteR * 0.0168980
            let pinkR = b0R + b1R + b2R + b3R + b4R + b5R + b6R + whiteR * 0.5362
            b6R = whiteR * 0.115926
            
            leftChannel[i] = pinkL * Float(envelope) * 0.15
            rightChannel[i] = pinkR * Float(envelope) * 0.15
        }
    }
    
    private func generateBrownNoise(leftChannel: UnsafeMutablePointer<Float>, rightChannel: UnsafeMutablePointer<Float>, frameCount: Int) {
        var lastLeftSample: Float = 0
        var lastRightSample: Float = 0
        
        for i in 0..<frameCount {
            let envelope = calculateNoiseEnvelope(frame: i, totalFrames: frameCount)
            
            // Brown noise is integrated white noise
            lastLeftSample += Float.random(in: -0.02...0.02)
            lastRightSample += Float.random(in: -0.02...0.02)
            
            // Apply high-pass filtering to prevent DC drift
            lastLeftSample *= 0.995
            lastRightSample *= 0.995
            
            leftChannel[i] = lastLeftSample * Float(envelope) * 3.0
            rightChannel[i] = lastRightSample * Float(envelope) * 3.0
        }
    }
    
    private func generateBlueNoise(leftChannel: UnsafeMutablePointer<Float>, rightChannel: UnsafeMutablePointer<Float>, frameCount: Int) {
        var lastLeftSample: Float = 0
        var lastRightSample: Float = 0
        
        for i in 0..<frameCount {
            let envelope = calculateNoiseEnvelope(frame: i, totalFrames: frameCount)
            
            // Blue noise is differentiated white noise
            let currentLeftSample = Float.random(in: -1...1)
            let currentRightSample = Float.random(in: -1...1)
            
            let leftDiff = currentLeftSample - lastLeftSample
            let rightDiff = currentRightSample - lastRightSample
            
            lastLeftSample = currentLeftSample
            lastRightSample = currentRightSample
            
            leftChannel[i] = leftDiff * Float(envelope) * 0.5
            rightChannel[i] = rightDiff * Float(envelope) * 0.5
        }
    }
    
    private func calculateNoiseEnvelope(frame: Int, totalFrames: Int) -> Double {
        let fadeInDuration = 5.0 // 5 second fade in
        let fadeOutDuration = 5.0 // 5 second fade out
        let fadeInFrames = Int(fadeInDuration * sampleRate)
        let fadeOutFrames = Int(fadeOutDuration * sampleRate)
        
        let fadeInEnvelope = frame < fadeInFrames ? Double(frame) / Double(fadeInFrames) : 1.0
        let fadeOutEnvelope = frame > (totalFrames - fadeOutFrames) ? 
            Double(totalFrames - frame) / Double(fadeOutFrames) : 1.0
        
        return fadeInEnvelope * fadeOutEnvelope
    }
    
    private func createEmptyBuffer() -> AVAudioPCMBuffer {
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 2)!
        return AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 1024)!
    }
}

// MARK: - Nature Sound Generator

class NatureSoundGenerator {
    private let sampleRate: Double
    
    init(sampleRate: Double) {
        self.sampleRate = sampleRate
    }
    
    func generateNatureSound(environment: NatureEnvironment, duration: TimeInterval) -> AVAudioPCMBuffer {
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 2)!
        
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
            return createEmptyBuffer()
        }
        
        buffer.frameLength = frameCount
        
        guard let leftChannel = buffer.floatChannelData?[0],
              let rightChannel = buffer.floatChannelData?[1] else {
            return buffer
        }
        
        switch environment {
        case .ocean:
            generateOceanSounds(leftChannel: leftChannel, rightChannel: rightChannel, frameCount: Int(frameCount))
        case .rain:
            generateRainSounds(leftChannel: leftChannel, rightChannel: rightChannel, frameCount: Int(frameCount))
        case .forest:
            generateForestSounds(leftChannel: leftChannel, rightChannel: rightChannel, frameCount: Int(frameCount))
        case .fire:
            generateFireSounds(leftChannel: leftChannel, rightChannel: rightChannel, frameCount: Int(frameCount))
        }
        
        return buffer
    }
    
    private func generateOceanSounds(leftChannel: UnsafeMutablePointer<Float>, rightChannel: UnsafeMutablePointer<Float>, frameCount: Int) {
        for i in 0..<frameCount {
            let time = Double(i) / sampleRate
            let envelope = calculateNatureEnvelope(frame: i, totalFrames: frameCount, time: time)
            
            // Wave sounds with multiple frequency components
            var leftSample = 0.0
            var rightSample = 0.0
            
            // Low frequency wave base (0.1 - 2 Hz)
            let waveFreq1 = 0.3 + 0.2 * sin(time * 0.1)
            leftSample += sin(2.0 * .pi * waveFreq1 * time) * 0.4
            rightSample += sin(2.0 * .pi * waveFreq1 * time + 0.1) * 0.4
            
            // Mid frequency wave components (2 - 20 Hz)
            let waveFreq2 = 8.0 + 4.0 * sin(time * 0.3)
            leftSample += sin(2.0 * .pi * waveFreq2 * time) * 0.3
            rightSample += sin(2.0 * .pi * waveFreq2 * time + 0.2) * 0.3
            
            // High frequency foam and bubbles (100 - 2000 Hz)
            let foamFreq = 200.0 + 100.0 * sin(time * 2.0)
            let foamNoise = Double.random(in: -0.1...0.1)
            leftSample += sin(2.0 * .pi * foamFreq * time) * 0.1 + foamNoise
            rightSample += sin(2.0 * .pi * foamFreq * time + 0.3) * 0.1 + foamNoise
            
            // Apply envelope and stereo spread
            let stereoSpread = 0.1 * sin(time * 0.05) // Slow stereo movement
            leftSample *= envelope * (1.0 - stereoSpread)
            rightSample *= envelope * (1.0 + stereoSpread)
            
            leftChannel[i] = Float(leftSample) * 0.3
            rightChannel[i] = Float(rightSample) * 0.3
        }
    }
    
    private func generateRainSounds(leftChannel: UnsafeMutablePointer<Float>, rightChannel: UnsafeMutablePointer<Float>, frameCount: Int) {
        for i in 0..<frameCount {
            let time = Double(i) / sampleRate
            let envelope = calculateNatureEnvelope(frame: i, totalFrames: frameCount, time: time)
            
            var leftSample = 0.0
            var rightSample = 0.0
            
            // Rain drops - high frequency content
            if Double.random(in: 0...1) < 0.1 { // 10% chance per sample for rain drop
                let dropFreq = Double.random(in: 1000...3000)
                let dropDecay = exp(-time.truncatingRemainder(dividingBy: 0.1) * 50.0)
                leftSample += sin(2.0 * .pi * dropFreq * time) * dropDecay * 0.3
                rightSample += sin(2.0 * .pi * dropFreq * time) * dropDecay * 0.3
            }
            
            // Continuous rain background - pink noise filtered
            let rainNoise = Double.random(in: -0.2...0.2)
            let filteredNoise = rainNoise * (1.0 + sin(2.0 * .pi * 500.0 * time) * 0.5)
            leftSample += filteredNoise * 0.4
            rightSample += filteredNoise * 0.4
            
            // Rain on surfaces - mid frequency
            let surfaceFreq = 300.0 + 100.0 * sin(time * 1.5)
            leftSample += sin(2.0 * .pi * surfaceFreq * time) * 0.2
            rightSample += sin(2.0 * .pi * surfaceFreq * time + 0.1) * 0.2
            
            leftSample *= envelope
            rightSample *= envelope
            
            leftChannel[i] = Float(leftSample) * 0.3
            rightChannel[i] = Float(rightSample) * 0.3
        }
    }
    
    private func generateForestSounds(leftChannel: UnsafeMutablePointer<Float>, rightChannel: UnsafeMutablePointer<Float>, frameCount: Int) {
        for i in 0..<frameCount {
            let time = Double(i) / sampleRate
            let envelope = calculateNatureEnvelope(frame: i, totalFrames: frameCount, time: time)
            
            var leftSample = 0.0
            var rightSample = 0.0
            
            // Wind through trees - low frequency
            let windFreq = 0.5 + 0.3 * sin(time * 0.2)
            leftSample += sin(2.0 * .pi * windFreq * time) * 0.3
            rightSample += sin(2.0 * .pi * windFreq * time + 0.2) * 0.3
            
            // Leaves rustling - high frequency
            if Double.random(in: 0...1) < 0.05 { // 5% chance for rustling
                let rustleFreq = Double.random(in: 2000...4000)
                let rustleDecay = exp(-time.truncatingRemainder(dividingBy: 0.2) * 20.0)
                leftSample += sin(2.0 * .pi * rustleFreq * time) * rustleDecay * 0.1
                rightSample += sin(2.0 * .pi * rustleFreq * time) * rustleDecay * 0.1
            }
            
            // Bird calls - occasional
            if Double.random(in: 0...1) < 0.002 { // 0.2% chance for bird call
                let birdFreq = Double.random(in: 1500...2500)
                let birdMod = 1.0 + 0.5 * sin(2.0 * .pi * 5.0 * time)
                leftSample += sin(2.0 * .pi * birdFreq * birdMod * time) * 0.2
                rightSample += sin(2.0 * .pi * birdFreq * birdMod * time) * 0.2
            }
            
            // Ambient forest noise
            let ambientNoise = Double.random(in: -0.05...0.05)
            leftSample += ambientNoise
            rightSample += ambientNoise
            
            leftSample *= envelope
            rightSample *= envelope
            
            leftChannel[i] = Float(leftSample) * 0.25
            rightChannel[i] = Float(rightSample) * 0.25
        }
    }
    
    private func generateFireSounds(leftChannel: UnsafeMutablePointer<Float>, rightChannel: UnsafeMutablePointer<Float>, frameCount: Int) {
        for i in 0..<frameCount {
            let time = Double(i) / sampleRate
            let envelope = calculateNatureEnvelope(frame: i, totalFrames: frameCount, time: time)
            
            var leftSample = 0.0
            var rightSample = 0.0
            
            // Crackling sounds - random pops
            if Double.random(in: 0...1) < 0.08 { // 8% chance for crackle
                let crackleFreq = Double.random(in: 800...2000)
                let crackleDecay = exp(-time.truncatingRemainder(dividingBy: 0.05) * 100.0)
                leftSample += sin(2.0 * .pi * crackleFreq * time) * crackleDecay * 0.4
                rightSample += sin(2.0 * .pi * crackleFreq * time) * crackleDecay * 0.4
            }
            
            // Fire base sound - low frequency rumble
            let fireBaseFreq = 50.0 + 20.0 * sin(time * 0.8)
            leftSample += sin(2.0 * .pi * fireBaseFreq * time) * 0.3
            rightSample += sin(2.0 * .pi * fireBaseFreq * time + 0.1) * 0.3
            
            // Flame flicker - mid frequency modulation
            let flickerFreq = 200.0 + 50.0 * sin(time * 3.0)
            let flickerMod = 1.0 + 0.3 * sin(2.0 * .pi * 4.0 * time)
            leftSample += sin(2.0 * .pi * flickerFreq * time) * flickerMod * 0.2
            rightSample += sin(2.0 * .pi * flickerFreq * time) * flickerMod * 0.2
            
            // Burning noise - filtered noise
            let burnNoise = Double.random(in: -0.1...0.1)
            let filteredBurnNoise = burnNoise * (1.0 + sin(2.0 * .pi * 400.0 * time) * 0.3)
            leftSample += filteredBurnNoise
            rightSample += filteredBurnNoise
            
            leftSample *= envelope
            rightSample *= envelope
            
            leftChannel[i] = Float(leftSample) * 0.3
            rightChannel[i] = Float(rightSample) * 0.3
        }
    }
    
    private func calculateNatureEnvelope(frame: Int, totalFrames: Int, time: Double) -> Double {
        let fadeInDuration = 8.0 // 8 second fade in
        let fadeOutDuration = 8.0 // 8 second fade out
        let fadeInFrames = Int(fadeInDuration * sampleRate)
        let fadeOutFrames = Int(fadeOutDuration * sampleRate)
        
        let fadeInEnvelope = frame < fadeInFrames ? Double(frame) / Double(fadeInFrames) : 1.0
        let fadeOutEnvelope = frame > (totalFrames - fadeOutFrames) ? 
            Double(totalFrames - frame) / Double(fadeOutFrames) : 1.0
        
        // Natural variation - very slow amplitude modulation
        let naturalVariation = 1.0 + 0.1 * sin(2.0 * .pi * 0.03 * time)
        
        return fadeInEnvelope * fadeOutEnvelope * naturalVariation
    }
    
    private func createEmptyBuffer() -> AVAudioPCMBuffer {
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 2)!
        return AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 1024)!
    }
}

// MARK: - Ambient Noise Monitor

class AmbientNoiseMonitor: ObservableObject {
    @Published var currentNoiseLevel: Float = 0.0
    @Published var isMonitoring = false
    
    private var audioEngine: AVAudioEngine?
    private var inputNode: AVAudioInputNode?
    private var monitoringTimer: Timer?
    private let bufferSize: AVAudioFrameCount = 1024
    
    func startMonitoring() {
        setupAudioEngine()
        isMonitoring = true
        
        // Start periodic noise level updates
        monitoringTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateNoiseLevel()
        }
    }
    
    func stopMonitoring() {
        audioEngine?.stop()
        monitoringTimer?.invalidate()
        monitoringTimer = nil
        isMonitoring = false
        currentNoiseLevel = 0.0
    }
    
    private func setupAudioEngine() {
        audioEngine = AVAudioEngine()
        guard let audioEngine = audioEngine else { return }
        
        inputNode = audioEngine.inputNode
        guard let inputNode = inputNode else { return }
        
        let format = inputNode.outputFormat(forBus: 0)
        
        // Install tap to monitor audio levels
        inputNode.installTap(onBus: 0, bufferSize: bufferSize, format: format) { [weak self] buffer, time in
            self?.processAudioBuffer(buffer)
        }
        
        do {
            try audioEngine.start()
        } catch {
            print("Failed to start ambient noise monitoring: \(error)")
        }
    }
    
    private func processAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData else { return }
        
        let frameCount = Int(buffer.frameLength)
        var sum: Float = 0.0
        
        // Calculate RMS (Root Mean Square) for noise level
        for i in 0..<frameCount {
            let sample = channelData[0][i]
            sum += sample * sample
        }
        
        let rms = sqrt(sum / Float(frameCount))
        
        DispatchQueue.main.async {
            self.currentNoiseLevel = rms
        }
    }
    
    private func updateNoiseLevel() {
        // Additional processing if needed
        // The noise level is updated in real-time via the audio tap
    }
}

// MARK: - Supporting Types

enum NoiseColor: String, CaseIterable {
    case white = "White"
    case pink = "Pink"
    case brown = "Brown"
    case blue = "Blue"
}

// Additional audio types for enhanced compatibility
enum PreSleepAudioType {
    case binauralBeats(frequency: Double)
    case whiteNoise(color: NoiseColor)
    case natureSounds(environment: NatureEnvironment)
    case guidedMeditation(style: MeditationStyle)
    case ambientMusic(genre: AmbientGenre)
}

enum SleepAudioType {
    case deepSleep(frequency: Double)
    case continuousWhiteNoise(color: NoiseColor)
    case oceanWaves(intensity: WaveIntensity)
    case rainSounds(intensity: RainIntensity)
    case forestAmbience(timeOfDay: TimeOfDay)
}

enum MeditationStyle: String, CaseIterable {
    case mindfulness = "Mindfulness"
    case bodyScant = "Body Scan"
    case breathingFocus = "Breathing Focus"
    case lovingKindness = "Loving Kindness"
}

enum AmbientGenre: String, CaseIterable {
    case ethereal = "Ethereal"
    case droneBased = "Drone-Based"
    case minimalist = "Minimalist"
    case natureFusion = "Nature Fusion"
}

enum WaveIntensity: String, CaseIterable {
    case gentle = "Gentle"
    case moderate = "Moderate"
    case strong = "Strong"
}

enum RainIntensity: String, CaseIterable {
    case light = "Light"
    case moderate = "Moderate"
    case heavy = "Heavy"
    case storm = "Storm"
}

enum TimeOfDay: String, CaseIterable {
    case dawn = "Dawn"
    case morning = "Morning"
    case afternoon = "Afternoon"
    case dusk = "Dusk"
    case night = "Night"
}

// Enhanced audio type for the main generator
enum AudioType: Codable, Hashable {
    case none
    case pinkNoise
    case isochronicTones
    case binauralBeats
    case whiteNoise
    case natureSounds
    case preSleep(PreSleepAudioType)
    case sleep(SleepAudioType)
    case custom(CustomSoundscape)
}

// EQ presets for enhanced audio processing
enum EQPreset: String, CaseIterable {
    case neutral = "Neutral"
    case warm = "Warm"
    case bright = "Bright"
    case sleep = "Sleep"
    case meditation = "Meditation"
    case deep = "Deep"
    case natural = "Natural"
}

// Audio quality settings
enum AudioQuality: String, CaseIterable {
    case standard = "Standard"
    case high = "High"
    case audiophile = "Audiophile"
    
    var sampleRate: Double {
        switch self {
        case .standard: return 44100
        case .high: return 48000
        case .audiophile: return 96000
        }
    }
    
    var bitDepth: UInt32 {
        switch self {
        case .standard: return 16
        case .high: return 24
        case .audiophile: return 32
        }
    }
}

// Processor type detection for dynamic quality adjustment
extension ProcessInfo {
    var processorType: ProcessorType {
        // Simplified processor detection
        let modelName = self.processorType
        if modelName.contains("A15") { return .A15 }
        if modelName.contains("A14") { return .A14 }
        if modelName.contains("A13") { return .A13 }
        if modelName.contains("M1") { return .M1 }
        return .unknown
    }
}

enum ProcessorType {
    case A13, A14, A15, M1, unknown
}
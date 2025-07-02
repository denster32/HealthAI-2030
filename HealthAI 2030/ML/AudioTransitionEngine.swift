import Foundation
import AVFoundation
import Accelerate

/// Advanced audio transition engine for seamless audio changes
class AudioTransitionEngine: ObservableObject {
    static let shared = AudioTransitionEngine()
    
    // MARK: - Published Properties
    @Published var isTransitioning = false
    @Published var transitionProgress: Double = 0.0
    @Published var currentTransitionType: TransitionType = .none
    
    // MARK: - Private Properties
    private var audioEngine: AVAudioEngine?
    private var primaryPlayer: AVAudioPlayerNode?
    private var secondaryPlayer: AVAudioPlayerNode?
    private var crossfadeMixer: AVAudioMixerNode?
    
    private var transitionTimer: Timer?
    private var fadeInGain: Float = 0.0
    private var fadeOutGain: Float = 1.0
    
    // Transition parameters
    private let standardTransitionDuration: TimeInterval = 10.0 // 10 seconds
    private let quickTransitionDuration: TimeInterval = 3.0     // 3 seconds
    private let slowTransitionDuration: TimeInterval = 30.0    // 30 seconds
    
    private init() {
        setupTransitionEngine()
    }
    
    // MARK: - Setup
    
    private func setupTransitionEngine() {
        audioEngine = AVAudioEngine()
        primaryPlayer = AVAudioPlayerNode()
        secondaryPlayer = AVAudioPlayerNode()
        crossfadeMixer = AVAudioMixerNode()
        
        guard let audioEngine = audioEngine,
              let primaryPlayer = primaryPlayer,
              let secondaryPlayer = secondaryPlayer,
              let crossfadeMixer = crossfadeMixer else { return }
        
        // Attach nodes to engine
        audioEngine.attach(primaryPlayer)
        audioEngine.attach(secondaryPlayer)
        audioEngine.attach(crossfadeMixer)
        
        // Create audio format
        let format = AVAudioFormat(standardFormatWithSampleRate: 48000, channels: 2)!
        
        // Connect players to crossfade mixer
        audioEngine.connect(primaryPlayer, to: crossfadeMixer, format: format)
        audioEngine.connect(secondaryPlayer, to: crossfadeMixer, format: format)
        
        // Connect mixer to main output
        audioEngine.connect(crossfadeMixer, to: audioEngine.mainMixerNode, format: format)
        
        do {
            try audioEngine.start()
        } catch {
            print("Failed to start transition engine: \(error)")
        }
    }
    
    // MARK: - Transition Methods
    
    /// Perform seamless crossfade between two audio sources
    func crossfadeTransition(
        from currentBuffer: AVAudioPCMBuffer,
        to newBuffer: AVAudioPCMBuffer,
        duration: TimeInterval = 10.0,
        curve: TransitionCurve = .smooth
    ) async {
        
        guard let primaryPlayer = primaryPlayer,
              let secondaryPlayer = secondaryPlayer else { return }
        
        await MainActor.run {
            self.isTransitioning = true
            self.currentTransitionType = .crossfade
            self.transitionProgress = 0.0
        }
        
        // Stop any existing transition
        transitionTimer?.invalidate()
        
        // Start playing new audio on secondary player at zero volume
        secondaryPlayer.volume = 0.0
        secondaryPlayer.scheduleBuffer(newBuffer, at: nil, options: .loops)
        secondaryPlayer.play()
        
        // Perform crossfade
        let updateInterval: TimeInterval = 0.05 // 50ms updates for smooth transition
        let totalSteps = Int(duration / updateInterval)
        var currentStep = 0
        
        transitionTimer = Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            
            currentStep += 1
            let progress = Double(currentStep) / Double(totalSteps)
            
            // Apply transition curve
            let curveProgress = self.applyTransitionCurve(progress, curve: curve)
            
            // Calculate volumes using equal-power crossfading
            let fadeOutVolume = Float(cos(curveProgress * .pi / 2.0))
            let fadeInVolume = Float(sin(curveProgress * .pi / 2.0))
            
            // Apply volumes
            primaryPlayer.volume = fadeOutVolume
            secondaryPlayer.volume = fadeInVolume
            
            Task { @MainActor in
                self.transitionProgress = progress
            }
            
            // Complete transition
            if progress >= 1.0 {
                timer.invalidate()
                
                // Switch players
                primaryPlayer.stop()
                primaryPlayer.scheduleBuffer(newBuffer, at: nil, options: .loops)
                primaryPlayer.volume = 1.0
                primaryPlayer.play()
                
                secondaryPlayer.stop()
                secondaryPlayer.volume = 0.0
                
                Task { @MainActor in
                    self.isTransitioning = false
                    self.currentTransitionType = .none
                    self.transitionProgress = 0.0
                }
            }
        }
    }
    
    /// Smooth frequency sweep for binaural beats
    func frequencySweepTransition(
        from startFrequency: Double,
        to endFrequency: Double,
        duration: TimeInterval = 20.0,
        curve: TransitionCurve = .smooth
    ) async {
        
        await MainActor.run {
            self.isTransitioning = true
            self.currentTransitionType = .frequencySweep
            self.transitionProgress = 0.0
        }
        
        let updateInterval: TimeInterval = 0.1 // 100ms updates
        let totalSteps = Int(duration / updateInterval)
        var currentStep = 0
        
        transitionTimer = Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            
            currentStep += 1
            let progress = Double(currentStep) / Double(totalSteps)
            
            // Apply transition curve
            let curveProgress = self.applyTransitionCurve(progress, curve: curve)
            
            // Calculate current frequency
            let currentFrequency = startFrequency + (endFrequency - startFrequency) * curveProgress
            
            // Update audio engine with new frequency
            self.updateBinauralBeatFrequency(currentFrequency)
            
            Task { @MainActor in
                self.transitionProgress = progress
            }
            
            // Complete transition
            if progress >= 1.0 {
                timer.invalidate()
                
                Task { @MainActor in
                    self.isTransitioning = false
                    self.currentTransitionType = .none
                    self.transitionProgress = 0.0
                }
            }
        }
    }
    
    /// Morphing transition between different nature sounds
    func natureSoundMorphTransition(
        from currentEnvironment: NatureEnvironment,
        to newEnvironment: NatureEnvironment,
        duration: TimeInterval = 15.0
    ) async {
        
        await MainActor.run {
            self.isTransitioning = true
            self.currentTransitionType = .natureMorph
            self.transitionProgress = 0.0
        }
        
        // Generate morphed audio buffers
        let morphedBuffers = await generateMorphedNatureSounds(
            from: currentEnvironment,
            to: newEnvironment,
            steps: Int(duration * 2) // 2 updates per second
        )
        
        // Play morphed sequence
        await playMorphedSequence(morphedBuffers, duration: duration)
        
        await MainActor.run {
            self.isTransitioning = false
            self.currentTransitionType = .none
            self.transitionProgress = 0.0
        }
    }
    
    /// Dynamic weather progression for enhanced realism
    func weatherProgressionTransition(
        from currentWeather: WeatherState,
        to newWeather: WeatherState,
        duration: TimeInterval = 60.0 // 1 minute progression
    ) async {
        
        await MainActor.run {
            self.isTransitioning = true
            self.currentTransitionType = .weatherProgression
            self.transitionProgress = 0.0
        }
        
        let progressionSteps = await generateWeatherProgression(
            from: currentWeather,
            to: newWeather,
            duration: duration
        )
        
        await playWeatherProgression(progressionSteps, duration: duration)
        
        await MainActor.run {
            self.isTransitioning = false
            self.currentTransitionType = .none
            self.transitionProgress = 0.0
        }
    }
    
    // MARK: - Private Helper Methods
    
    private func applyTransitionCurve(_ progress: Double, curve: TransitionCurve) -> Double {
        switch curve {
        case .linear:
            return progress
        case .smooth:
            // Smooth S-curve using smoothstep function
            return progress * progress * (3.0 - 2.0 * progress)
        case .ease_in:
            return progress * progress
        case .ease_out:
            return 1.0 - (1.0 - progress) * (1.0 - progress)
        case .ease_in_out:
            if progress < 0.5 {
                return 2.0 * progress * progress
            } else {
                return 1.0 - 2.0 * (1.0 - progress) * (1.0 - progress)
            }
        case .exponential:
            return progress == 0.0 ? 0.0 : pow(2.0, 10.0 * (progress - 1.0))
        case .logarithmic:
            return progress == 1.0 ? 1.0 : 1.0 - pow(2.0, -10.0 * progress)
        case .sine:
            return sin(progress * .pi / 2.0)
        case .cosine:
            return 1.0 - cos(progress * .pi / 2.0)
        }
    }
    
    private func updateBinauralBeatFrequency(_ frequency: Double) {
        // Update the current audio generator with new frequency
        AudioGenerationEngine.shared.setFrequency(frequency)
    }
    
    private func generateMorphedNatureSounds(
        from current: NatureEnvironment,
        to new: NatureEnvironment,
        steps: Int
    ) async -> [AVAudioPCMBuffer] {
        
        var morphedBuffers: [AVAudioPCMBuffer] = []
        
        for step in 0..<steps {
            let progress = Double(step) / Double(steps - 1)
            let morphedBuffer = await createMorphedNatureSound(
                from: current,
                to: new,
                morphFactor: progress
            )
            morphedBuffers.append(morphedBuffer)
        }
        
        return morphedBuffers
    }
    
    private func createMorphedNatureSound(
        from current: NatureEnvironment,
        to new: NatureEnvironment,
        morphFactor: Double
    ) async -> AVAudioPCMBuffer {
        
        // Create morphed nature sound based on interpolation between environments
        let sampleRate: Double = 48000
        let duration: Double = 0.5 // 500ms per step
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 2)!
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)!
        buffer.frameLength = frameCount
        
        // Generate morphed audio based on environment characteristics
        let currentWeight = 1.0 - morphFactor
        let newWeight = morphFactor
        
        // Morph characteristics between environments
        let morphedCharacteristics = interpolateEnvironmentCharacteristics(
            current: current,
            new: new,
            weight: morphFactor
        )
        
        // Generate audio using morphed characteristics
        await generateNatureSoundWithCharacteristics(
            characteristics: morphedCharacteristics,
            buffer: buffer
        )
        
        return buffer
    }
    
    private func interpolateEnvironmentCharacteristics(
        current: NatureEnvironment,
        new: NatureEnvironment,
        weight: Double
    ) -> EnvironmentCharacteristics {
        
        // Interpolate between environment characteristics
        let currentChars = getEnvironmentCharacteristics(current)
        let newChars = getEnvironmentCharacteristics(new)
        
        return EnvironmentCharacteristics(
            lowFrequencyContent: currentChars.lowFrequencyContent * (1.0 - weight) + newChars.lowFrequencyContent * weight,
            midFrequencyContent: currentChars.midFrequencyContent * (1.0 - weight) + newChars.midFrequencyContent * weight,
            highFrequencyContent: currentChars.highFrequencyContent * (1.0 - weight) + newChars.highFrequencyContent * weight,
            noiseDensity: currentChars.noiseDensity * (1.0 - weight) + newChars.noiseDensity * weight,
            spatialSpread: currentChars.spatialSpread * (1.0 - weight) + newChars.spatialSpread * weight,
            dynamicRange: currentChars.dynamicRange * (1.0 - weight) + newChars.dynamicRange * weight
        )
    }
    
    private func getEnvironmentCharacteristics(_ environment: NatureEnvironment) -> EnvironmentCharacteristics {
        switch environment {
        case .ocean:
            return EnvironmentCharacteristics(
                lowFrequencyContent: 0.8,   // Strong low frequencies from waves
                midFrequencyContent: 0.6,   // Moderate mid frequencies
                highFrequencyContent: 0.3,  // Low high frequencies
                noiseDensity: 0.7,          // Consistent wave sounds
                spatialSpread: 0.9,         // Wide stereo spread
                dynamicRange: 0.8           // Varying wave intensity
            )
        case .rain:
            return EnvironmentCharacteristics(
                lowFrequencyContent: 0.3,   // Low rumble from heavy drops
                midFrequencyContent: 0.7,   // Primary frequency content
                highFrequencyContent: 0.9,  // Lots of high frequency detail
                noiseDensity: 0.9,          // Dense, random patterns
                spatialSpread: 0.8,         // Wide but not as wide as ocean
                dynamicRange: 0.6           // Relatively consistent
            )
        case .forest:
            return EnvironmentCharacteristics(
                lowFrequencyContent: 0.4,   // Some low frequency wind
                midFrequencyContent: 0.5,   // Moderate mid content
                highFrequencyContent: 0.8,  // Bird calls and leaf rustling
                noiseDensity: 0.4,          // Sparse, natural sounds
                spatialSpread: 0.7,         // Natural stereo spread
                dynamicRange: 0.9           // Highly variable
            )
        case .fire:
            return EnvironmentCharacteristics(
                lowFrequencyContent: 0.6,   // Crackling and popping
                midFrequencyContent: 0.8,   // Primary crackling frequency
                highFrequencyContent: 0.7,  // Sharp cracking sounds
                noiseDensity: 0.6,          // Moderate random patterns
                spatialSpread: 0.4,         // More centered
                dynamicRange: 0.8           // Variable intensity
            )
        }
    }
    
    private func generateNatureSoundWithCharacteristics(
        characteristics: EnvironmentCharacteristics,
        buffer: AVAudioPCMBuffer
    ) async {
        
        guard let leftChannel = buffer.floatChannelData?[0],
              let rightChannel = buffer.floatChannelData?[1] else { return }
        
        let frameCount = Int(buffer.frameLength)
        let sampleRate = buffer.format.sampleRate
        
        for i in 0..<frameCount {
            let time = Double(i) / sampleRate
            
            // Generate multi-layered nature sound
            var leftSample: Float = 0.0
            var rightSample: Float = 0.0
            
            // Low frequency component
            let lowFreq = 50.0 + 100.0 * characteristics.lowFrequencyContent
            leftSample += Float(sin(2.0 * .pi * lowFreq * time) * 0.3 * characteristics.lowFrequencyContent)
            rightSample += Float(sin(2.0 * .pi * lowFreq * time) * 0.3 * characteristics.lowFrequencyContent)
            
            // Mid frequency component
            let midFreq = 200.0 + 300.0 * characteristics.midFrequencyContent
            leftSample += Float(sin(2.0 * .pi * midFreq * time) * 0.4 * characteristics.midFrequencyContent)
            rightSample += Float(sin(2.0 * .pi * midFreq * time) * 0.4 * characteristics.midFrequencyContent)
            
            // High frequency component
            let highFreq = 1000.0 + 2000.0 * characteristics.highFrequencyContent
            leftSample += Float(sin(2.0 * .pi * highFreq * time) * 0.2 * characteristics.highFrequencyContent)
            rightSample += Float(sin(2.0 * .pi * highFreq * time) * 0.2 * characteristics.highFrequencyContent)
            
            // Add noise component
            let noiseLevel = characteristics.noiseDensity
            leftSample += Float.random(in: -0.1...0.1) * Float(noiseLevel)
            rightSample += Float.random(in: -0.1...0.1) * Float(noiseLevel)
            
            // Apply spatial spread
            let spreadFactor = Float(characteristics.spatialSpread)
            let panOffset = Float.random(in: -spreadFactor...spreadFactor) * 0.1
            leftSample *= (1.0 - panOffset)
            rightSample *= (1.0 + panOffset)
            
            // Apply dynamic range
            let dynamicFactor = 1.0 + sin(time * 0.5) * Float(characteristics.dynamicRange) * 0.3
            leftSample *= dynamicFactor
            rightSample *= dynamicFactor
            
            leftChannel[i] = leftSample * 0.3
            rightChannel[i] = rightSample * 0.3
        }
    }
    
    private func playMorphedSequence(_ buffers: [AVAudioPCMBuffer], duration: TimeInterval) async {
        let stepDuration = duration / Double(buffers.count)
        
        for (index, buffer) in buffers.enumerated() {
            guard let primaryPlayer = primaryPlayer else { return }
            
            primaryPlayer.stop()
            primaryPlayer.scheduleBuffer(buffer, at: nil)
            primaryPlayer.play()
            
            await MainActor.run {
                self.transitionProgress = Double(index) / Double(buffers.count - 1)
            }
            
            // Wait for step duration
            try? await Task.sleep(nanoseconds: UInt64(stepDuration * 1_000_000_000))
        }
    }
    
    private func generateWeatherProgression(
        from current: WeatherState,
        to new: WeatherState,
        duration: TimeInterval
    ) async -> [WeatherStep] {
        
        let stepCount = Int(duration / 2.0) // Update every 2 seconds
        var steps: [WeatherStep] = []
        
        for i in 0..<stepCount {
            let progress = Double(i) / Double(stepCount - 1)
            let step = interpolateWeatherState(from: current, to: new, progress: progress)
            steps.append(step)
        }
        
        return steps
    }
    
    private func interpolateWeatherState(
        from current: WeatherState,
        to new: WeatherState,
        progress: Double
    ) -> WeatherStep {
        
        return WeatherStep(
            intensity: current.intensity + (new.intensity - current.intensity) * progress,
            windSpeed: current.windSpeed + (new.windSpeed - current.windSpeed) * progress,
            precipitation: current.precipitation + (new.precipitation - current.precipitation) * progress,
            atmosphere: interpolateAtmosphere(current.atmosphere, new.atmosphere, progress),
            duration: 2.0
        )
    }
    
    private func interpolateAtmosphere(
        _ current: AtmosphereType,
        _ new: AtmosphereType,
        _ progress: Double
    ) -> AtmosphereType {
        if progress < 0.5 {
            return current
        } else {
            return new
        }
    }
    
    private func playWeatherProgression(_ steps: [WeatherStep], duration: TimeInterval) async {
        let stepDuration = duration / Double(steps.count)
        
        for (index, step) in steps.enumerated() {
            // Generate and play weather audio for this step
            let weatherBuffer = await generateWeatherAudio(for: step)
            
            guard let primaryPlayer = primaryPlayer else { return }
            
            primaryPlayer.stop()
            primaryPlayer.scheduleBuffer(weatherBuffer, at: nil)
            primaryPlayer.play()
            
            await MainActor.run {
                self.transitionProgress = Double(index) / Double(steps.count - 1)
            }
            
            // Wait for step duration
            try? await Task.sleep(nanoseconds: UInt64(stepDuration * 1_000_000_000))
        }
    }
    
    private func generateWeatherAudio(for step: WeatherStep) async -> AVAudioPCMBuffer {
        // Generate weather audio based on weather step parameters
        let sampleRate: Double = 48000
        let duration: Double = step.duration
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 2)!
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)!
        buffer.frameLength = frameCount
        
        guard let leftChannel = buffer.floatChannelData?[0],
              let rightChannel = buffer.floatChannelData?[1] else { return buffer }
        
        for i in 0..<Int(frameCount) {
            let time = Double(i) / sampleRate
            
            // Generate weather-specific audio
            var leftSample: Float = 0.0
            var rightSample: Float = 0.0
            
            // Rain component based on precipitation
            if step.precipitation > 0 {
                let rainFreq = 800.0 + Double.random(in: -200...200)
                let rainAmp = Float(step.precipitation) * 0.3
                leftSample += Float(sin(2.0 * .pi * rainFreq * time)) * rainAmp
                rightSample += Float(sin(2.0 * .pi * rainFreq * time)) * rainAmp
            }
            
            // Wind component based on wind speed
            if step.windSpeed > 0 {
                let windFreq = 100.0 + step.windSpeed * 50.0
                let windAmp = Float(step.windSpeed) * 0.2
                leftSample += Float(sin(2.0 * .pi * windFreq * time)) * windAmp
                rightSample += Float(sin(2.0 * .pi * windFreq * time)) * windAmp
            }
            
            // Overall intensity modulation
            let intensityFactor = Float(step.intensity)
            leftSample *= intensityFactor
            rightSample *= intensityFactor
            
            leftChannel[i] = leftSample
            rightChannel[i] = rightSample
        }
        
        return buffer
    }
    
    // MARK: - Public Control Methods
    
    func stopCurrentTransition() {
        transitionTimer?.invalidate()
        transitionTimer = nil
        
        Task { @MainActor in
            self.isTransitioning = false
            self.currentTransitionType = .none
            self.transitionProgress = 0.0
        }
    }
    
    func adjustTransitionSpeed(_ multiplier: Double) {
        // Adjust the current transition speed if one is active
        if let timer = transitionTimer {
            let newInterval = timer.timeInterval / multiplier
            timer.invalidate()
            
            // Restart timer with new interval
            // This would require refactoring to store transition state
        }
    }
}

// MARK: - Supporting Types

enum TransitionType {
    case none
    case crossfade
    case frequencySweep
    case natureMorph
    case weatherProgression
}

enum TransitionCurve {
    case linear
    case smooth
    case ease_in
    case ease_out
    case ease_in_out
    case exponential
    case logarithmic
    case sine
    case cosine
}

enum NatureEnvironment {
    case ocean
    case rain
    case forest
    case fire
}

struct EnvironmentCharacteristics {
    let lowFrequencyContent: Double
    let midFrequencyContent: Double
    let highFrequencyContent: Double
    let noiseDensity: Double
    let spatialSpread: Double
    let dynamicRange: Double
}

struct WeatherState {
    let intensity: Double
    let windSpeed: Double
    let precipitation: Double
    let atmosphere: AtmosphereType
}

struct WeatherStep {
    let intensity: Double
    let windSpeed: Double
    let precipitation: Double
    let atmosphere: AtmosphereType
    let duration: TimeInterval
}

enum AtmosphereType {
    case calm
    case breezy
    case stormy
    case peaceful
}
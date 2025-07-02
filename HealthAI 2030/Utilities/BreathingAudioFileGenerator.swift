import Foundation
import AVFoundation
import os.log

/// BreathingAudioFileGenerator - Simple utility to generate missing audio files
@MainActor
class BreathingAudioFileGenerator: ObservableObject {
    static let shared = BreathingAudioFileGenerator()
    
    // MARK: - Published Properties
    @Published var isGenerating = false
    @Published var generationProgress: Double = 0.0
    @Published var currentFile = ""
    
    // MARK: - Audio Generation Properties
    private let sampleRate: Double = 48000.0
    private let audioDuration: TimeInterval = 300.0 // 5 minutes
    
    private init() {}
    
    // MARK: - Main Generation Method
    
    func generateAllBreathingAudioFiles() async {
        await MainActor.run {
            isGenerating = true
            generationProgress = 0.0
        }
        
        let files = [
            ("calming_ambient", ColorTheme.calming),
            ("energizing_ambient", ColorTheme.energizing),
            ("natural_ambient", ColorTheme.natural),
            ("sunset_ambient", ColorTheme.sunset),
            ("aurora_ambient", ColorTheme.aurora)
        ]
        
        for (index, (filename, theme)) in files.enumerated() {
            await MainActor.run {
                currentFile = filename
                generationProgress = Double(index) / Double(files.count)
            }
            
            await generateAudioFile(filename: filename, theme: theme)
        }
        
        await MainActor.run {
            isGenerating = false
            generationProgress = 1.0
            currentFile = "Generation Complete"
        }
        
        Logger.success("All breathing audio files generated successfully", log: Logger.audio)
    }
    
    // MARK: - Individual File Generation
    
    private func generateAudioFile(filename: String, theme: ColorTheme) async {
        Logger.info("Generating audio file: \(filename)", log: Logger.audio)
        
        // Generate the audio buffer based on theme
        let buffer = generateThemeAudio(theme: theme)
        
        // Save to file
        await saveAudioBufferToFile(buffer: buffer, filename: filename)
    }
    
    private func generateThemeAudio(theme: ColorTheme) -> AVAudioPCMBuffer {
        let frameCount = AVAudioFrameCount(sampleRate * audioDuration)
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 2)!
        
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
            return createEmptyBuffer()
        }
        
        buffer.frameLength = frameCount
        
        guard let leftChannel = buffer.floatChannelData?[0],
              let rightChannel = buffer.floatChannelData?[1] else {
            return buffer
        }
        
        // Generate theme-specific ambient audio
        switch theme {
        case .calming:
            generateCalmingAudio(leftChannel: leftChannel, rightChannel: rightChannel, frameCount: Int(frameCount))
        case .energizing:
            generateEnergizingAudio(leftChannel: leftChannel, rightChannel: rightChannel, frameCount: Int(frameCount))
        case .natural:
            generateNaturalAudio(leftChannel: leftChannel, rightChannel: rightChannel, frameCount: Int(frameCount))
        case .sunset:
            generateSunsetAudio(leftChannel: leftChannel, rightChannel: rightChannel, frameCount: Int(frameCount))
        case .aurora:
            generateAuroraAudio(leftChannel: leftChannel, rightChannel: rightChannel, frameCount: Int(frameCount))
        }
        
        return buffer
    }
    
    // MARK: - Theme-Specific Audio Generation
    
    private func generateCalmingAudio(leftChannel: UnsafeMutablePointer<Float>, rightChannel: UnsafeMutablePointer<Float>, frameCount: Int) {
        for i in 0..<frameCount {
            let time = Double(i) / sampleRate
            
            // Calming: Gentle ocean waves with soft tones
            var leftSample = 0.0
            var rightSample = 0.0
            
            // Low frequency wave base
            let waveFreq = 0.3 + 0.2 * sin(time * 0.1)
            leftSample += sin(2.0 * .pi * waveFreq * time) * 0.4
            rightSample += sin(2.0 * .pi * waveFreq * time + 0.1) * 0.4
            
            // Mid frequency gentle tones
            let toneFreq = 120.0 + 20.0 * sin(time * 0.05)
            leftSample += sin(2.0 * .pi * toneFreq * time) * 0.2
            rightSample += sin(2.0 * .pi * toneFreq * time + 0.2) * 0.2
            
            // Apply envelope
            let envelope = calculateSmoothEnvelope(frame: i, totalFrames: frameCount, time: time)
            leftSample *= envelope
            rightSample *= envelope
            
            leftChannel[i] = Float(leftSample) * 0.3
            rightChannel[i] = Float(rightSample) * 0.3
        }
    }
    
    private func generateEnergizingAudio(leftChannel: UnsafeMutablePointer<Float>, rightChannel: UnsafeMutablePointer<Float>, frameCount: Int) {
        for i in 0..<frameCount {
            let time = Double(i) / sampleRate
            
            // Energizing: Upbeat ambient with higher frequencies
            var leftSample = 0.0
            var rightSample = 0.0
            
            // Base frequency (gentle but uplifting)
            let baseFreq = 180.0 + 30.0 * sin(time * 0.1)
            leftSample += sin(2.0 * .pi * baseFreq * time) * 0.3
            rightSample += sin(2.0 * .pi * baseFreq * time + 0.1) * 0.3
            
            // Harmonic layer
            let harmonicFreq = baseFreq * 2.0
            leftSample += sin(2.0 * .pi * harmonicFreq * time) * 0.2
            rightSample += sin(2.0 * .pi * harmonicFreq * time + 0.2) * 0.2
            
            // Rhythmic modulation
            let rhythmMod = 1.0 + 0.3 * sin(2.0 * .pi * 0.5 * time)
            leftSample *= rhythmMod
            rightSample *= rhythmMod
            
            // Apply envelope
            let envelope = calculateSmoothEnvelope(frame: i, totalFrames: frameCount, time: time)
            leftSample *= envelope
            rightSample *= envelope
            
            leftChannel[i] = Float(leftSample) * 0.4
            rightChannel[i] = Float(rightSample) * 0.4
        }
    }
    
    private func generateNaturalAudio(leftChannel: UnsafeMutablePointer<Float>, rightChannel: UnsafeMutablePointer<Float>, frameCount: Int) {
        for i in 0..<frameCount {
            let time = Double(i) / sampleRate
            
            // Natural: Forest-like sounds with wind
            var leftSample = 0.0
            var rightSample = 0.0
            
            // Wind through trees
            let windFreq = 0.5 + 0.3 * sin(time * 0.2)
            leftSample += sin(2.0 * .pi * windFreq * time) * 0.3
            rightSample += sin(2.0 * .pi * windFreq * time + 0.2) * 0.3
            
            // Natural tones
            let naturalFreq = 140.0 + 25.0 * sin(time * 0.08)
            leftSample += sin(2.0 * .pi * naturalFreq * time) * 0.25
            rightSample += sin(2.0 * .pi * naturalFreq * time + 0.15) * 0.25
            
            // Apply envelope
            let envelope = calculateSmoothEnvelope(frame: i, totalFrames: frameCount, time: time)
            leftSample *= envelope
            rightSample *= envelope
            
            leftChannel[i] = Float(leftSample) * 0.35
            rightChannel[i] = Float(rightSample) * 0.35
        }
    }
    
    private func generateSunsetAudio(leftChannel: UnsafeMutablePointer<Float>, rightChannel: UnsafeMutablePointer<Float>, frameCount: Int) {
        for i in 0..<frameCount {
            let time = Double(i) / sampleRate
            
            // Sunset: Warm, fire-like ambient
            var leftSample = 0.0
            var rightSample = 0.0
            
            // Warm base frequency
            let warmFreq = 80.0 + 15.0 * sin(time * 0.08)
            leftSample += sin(2.0 * .pi * warmFreq * time) * 0.4
            rightSample += sin(2.0 * .pi * warmFreq * time + 0.15) * 0.4
            
            // Warm harmonic layer
            let warmHarmonic = warmFreq * 1.5
            leftSample += sin(2.0 * .pi * warmHarmonic * time) * 0.3
            rightSample += sin(2.0 * .pi * warmHarmonic * time + 0.2) * 0.3
            
            // Gentle modulation
            let modFreq = 0.3 + 0.1 * sin(time * 0.2)
            let modulation = 1.0 + 0.2 * sin(2.0 * .pi * modFreq * time)
            leftSample *= modulation
            rightSample *= modulation
            
            // Apply envelope
            let envelope = calculateSmoothEnvelope(frame: i, totalFrames: frameCount, time: time)
            leftSample *= envelope
            rightSample *= envelope
            
            leftChannel[i] = Float(leftSample) * 0.35
            rightChannel[i] = Float(rightSample) * 0.35
        }
    }
    
    private func generateAuroraAudio(leftChannel: UnsafeMutablePointer<Float>, rightChannel: UnsafeMutablePointer<Float>, frameCount: Int) {
        for i in 0..<frameCount {
            let time = Double(i) / sampleRate
            
            // Aurora: Ethereal, cosmic ambient
            var leftSample = 0.0
            var rightSample = 0.0
            
            // Ethereal base frequency
            let etherealFreq = 180.0 + 30.0 * sin(time * 0.06)
            leftSample += sin(2.0 * .pi * etherealFreq * time) * 0.4
            rightSample += sin(2.0 * .pi * etherealFreq * time + 0.2) * 0.4
            
            // Floating harmonics
            let harmonic1 = etherealFreq * 2.0
            let harmonic2 = etherealFreq * 3.0
            leftSample += sin(2.0 * .pi * harmonic1 * time) * 0.2
            rightSample += sin(2.0 * .pi * harmonic1 * time + 0.1) * 0.2
            leftSample += sin(2.0 * .pi * harmonic2 * time) * 0.1
            rightSample += sin(2.0 * .pi * harmonic2 * time + 0.3) * 0.1
            
            // Gentle modulation
            let modFreq = 0.2 + 0.1 * sin(time * 0.15)
            let modulation = 1.0 + 0.15 * sin(2.0 * .pi * modFreq * time)
            leftSample *= modulation
            rightSample *= modulation
            
            // Apply envelope
            let envelope = calculateSmoothEnvelope(frame: i, totalFrames: frameCount, time: time)
            leftSample *= envelope
            rightSample *= envelope
            
            leftChannel[i] = Float(leftSample) * 0.35
            rightChannel[i] = Float(rightSample) * 0.35
        }
    }
    
    // MARK: - File Saving
    
    private func saveAudioBufferToFile(buffer: AVAudioPCMBuffer, filename: String) async {
        guard let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            Logger.error("Could not access documents directory", log: Logger.audio)
            return
        }
        
        let audioFileURL = documentsPath.appendingPathComponent("\(filename).wav")
        
        do {
            // Write buffer to WAV file
            let wavFile = try AVAudioFile(forWriting: audioFileURL, settings: buffer.format.settings)
            try buffer.write(to: wavFile)
            
            Logger.success("Successfully generated \(filename).wav", log: Logger.audio)
            
            // Copy to app bundle if possible (for development)
            await copyToAppBundle(filename: filename, sourceURL: audioFileURL)
            
        } catch {
            Logger.error("Failed to save audio file \(filename): \(error.localizedDescription)", log: Logger.audio)
        }
    }
    
    private func copyToAppBundle(filename: String, sourceURL: URL) async {
        // This is for development - in production, files would be bundled with the app
        guard let bundlePath = Bundle.main.resourcePath else { return }
        
        let bundleURL = URL(fileURLWithPath: bundlePath).appendingPathComponent("\(filename).wav")
        
        do {
            if FileManager.default.fileExists(atPath: bundleURL.path) {
                try FileManager.default.removeItem(at: bundleURL)
            }
            try FileManager.default.copyItem(at: sourceURL, to: bundleURL)
            Logger.info("Copied \(filename).wav to app bundle", log: Logger.audio)
        } catch {
            Logger.warning("Could not copy \(filename).wav to app bundle: \(error.localizedDescription)", log: Logger.audio)
        }
    }
    
    // MARK: - Utility Methods
    
    private func calculateSmoothEnvelope(frame: Int, totalFrames: Int, time: Double) -> Double {
        let fadeInDuration = 10.0 // 10 second fade in
        let fadeOutDuration = 10.0 // 10 second fade out
        let fadeInFrames = Int(fadeInDuration * sampleRate)
        let fadeOutFrames = Int(fadeOutDuration * sampleRate)
        
        let fadeInEnvelope = frame < fadeInFrames ? Double(frame) / Double(fadeInFrames) : 1.0
        let fadeOutEnvelope = frame > (totalFrames - fadeOutFrames) ? 
            Double(totalFrames - frame) / Double(fadeOutFrames) : 1.0
        
        // Natural variation
        let naturalVariation = 1.0 + 0.05 * sin(2.0 * .pi * 0.02 * time)
        
        return fadeInEnvelope * fadeOutEnvelope * naturalVariation
    }
    
    private func createEmptyBuffer() -> AVAudioPCMBuffer {
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 2)!
        return AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 1024)!
    }
}

// MARK: - Usage Example

extension BreathingAudioFileGenerator {
    /// Convenience method to generate all audio files with progress updates
    func generateAudioFilesWithProgress() async {
        Logger.info("Starting breathing audio file generation", log: Logger.audio)
        
        await generateAllBreathingAudioFiles()
        
        Logger.success("Breathing audio file generation completed", log: Logger.audio)
    }
} 
import SwiftUI
import HealthKit
import AVFoundation
import CoreHaptics
import Combine
import os.log

// MARK: - Audio Controls View
struct AudioControlsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var audioEngine = AudioGenerationEngine.shared
    
    @State private var selectedPreSleepType: PreSleepAudioType = .binauralBeats(frequency: 6.0)
    @State private var selectedSleepType: SleepAudioType = .deepSleep(frequency: 2.0)
    @State private var binauralFrequency: Double = 6.0
    @State private var noiseColor: NoiseColor = .pink
    @State private var waveIntensity: WaveIntensity = .gentle
    @State private var rainIntensity: RainIntensity = .gentle
    @State private var timeOfDay: TimeOfDay = .night
    @State private var meditationStyle: MeditationStyle = .mindfulness
    @State private var ambientGenre: AmbientGenre = .atmospheric
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Pre-Sleep Audio Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Pre-Sleep Audio")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        VStack(spacing: 12) {
                            // Binaural Beats
                            AudioOptionCard(
                                title: "Binaural Beats",
                                description: "Synchronize brainwaves for relaxation",
                                icon: "waveform.path.ecg",
                                color: .blue,
                                isSelected: isBinauralSelected
                            ) {
                                selectedPreSleepType = .binauralBeats(frequency: binauralFrequency)
                            }
                            
                            if isBinauralSelected {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Frequency: \(Int(binauralFrequency))Hz")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    Slider(value: $binauralFrequency, in: 1...12, step: 0.5)
                                        .accentColor(.blue)
                                }
                                .padding(.leading, 20)
                            }
                            
                            // White Noise
                            AudioOptionCard(
                                title: "White Noise",
                                description: "Mask ambient sounds",
                                icon: "speaker.wave.2.fill",
                                color: .gray,
                                isSelected: isWhiteNoiseSelected
                            ) {
                                selectedPreSleepType = .whiteNoise(color: noiseColor)
                }
                            
                            if isWhiteNoiseSelected {
                                HStack {
                                    ForEach([NoiseColor.white, .pink, .brown], id: \.self) { color in
                                        Button(colorName) {
                                            noiseColor = color
                                            selectedPreSleepType = .whiteNoise(color: color)
                                        }
                                        .font(.caption)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(noiseColor == color ? Color.blue : Color(.systemGray5))
                                        .foregroundColor(noiseColor == color ? .white : .primary)
                                        .cornerRadius(6)
                                    }
                                }
                                .padding(.leading, 20)
                            }
                            
                            // Nature Sounds
                            AudioOptionCard(
                                title: "Nature Sounds",
                                description: "Relaxing natural environments",
                                icon: "leaf.fill",
                                color: .green,
                                isSelected: isNatureSelected
                            ) {
                                selectedPreSleepType = .natureSounds(environment: .ocean)
                            }
                            
                            // Guided Meditation
                            AudioOptionCard(
                                title: "Guided Meditation",
                                description: "Mindfulness and relaxation",
                                icon: "brain.head.profile",
                                color: .purple,
                                isSelected: isMeditationSelected
                            ) {
                                selectedPreSleepType = .guidedMeditation(style: meditationStyle)
                            }
                            
                            // Ambient Music
                            AudioOptionCard(
                                title: "Ambient Music",
                                description: "Atmospheric soundscapes",
                                icon: "music.note",
                                color: .orange,
                                isSelected: isAmbientSelected
                            ) {
                                selectedPreSleepType = .ambientMusic(genre: ambientGenre)
                            }
                        }
                    }
                    
                    Divider()
                    
                    // Sleep Audio Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Sleep Audio")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        VStack(spacing: 12) {
                            // Deep Sleep
                            AudioOptionCard(
                                title: "Deep Sleep",
                                description: "Delta wave synchronization",
                                icon: "bed.double.fill",
                                color: .purple,
                                isSelected: isDeepSleepSelected
                            ) {
                                selectedSleepType = .deepSleep(frequency: binauralFrequency)
                            }
                            
                            // Ocean Waves
                            AudioOptionCard(
                                title: "Ocean Waves",
                                description: "Gentle wave sounds",
                                icon: "wave.3.right",
                                color: .cyan,
                                isSelected: isOceanSelected
                            ) {
                                selectedSleepType = .oceanWaves(intensity: waveIntensity)
                            }
                            
                            if isOceanSelected {
                                HStack {
                                    ForEach([WaveIntensity.gentle, .moderate, .strong], id: \.self) { intensity in
                                        Button(intensityName) {
                                            waveIntensity = intensity
                                            selectedSleepType = .oceanWaves(intensity: intensity)
                                        }
                                        .font(.caption)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(waveIntensity == intensity ? Color.cyan : Color(.systemGray5))
                                        .foregroundColor(waveIntensity == intensity ? .white : .primary)
                                        .cornerRadius(6)
                                    }
                                }
                                .padding(.leading, 20)
                            }
                            
                            // Rain Sounds
                            AudioOptionCard(
                                title: "Rain Sounds",
                                description: "Soothing rainfall",
                                icon: "cloud.rain.fill",
                                color: .blue,
                                isSelected: isRainSelected
                            ) {
                                selectedSleepType = .rainSounds(intensity: rainIntensity)
                            }
                            
                            if isRainSelected {
                                HStack {
                                    ForEach([RainIntensity.gentle, .moderate, .heavy], id: \.self) { intensity in
                                        Button(intensityName) {
                                            rainIntensity = intensity
                                            selectedSleepType = .rainSounds(intensity: intensity)
                                        }
                                        .font(.caption)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(rainIntensity == intensity ? Color.blue : Color(.systemGray5))
                                        .foregroundColor(rainIntensity == intensity ? .white : .primary)
                                        .cornerRadius(6)
                                    }
                                }
                                .padding(.leading, 20)
                            }
                            
                            // Forest Ambience
                            AudioOptionCard(
                                title: "Forest Ambience",
                                description: "Natural forest sounds",
                                icon: "tree.fill",
                                color: .green,
                                isSelected: isForestSelected
                            ) {
                                selectedSleepType = .forestAmbience(timeOfDay: timeOfDay)
                            }
                            
                            if isForestSelected {
                                HStack {
                                    ForEach([TimeOfDay.dawn, .day, .dusk, .night], id: \.self) { time in
                                        Button(timeName) {
                                            timeOfDay = time
                                            selectedSleepType = .forestAmbience(timeOfDay: time)
                                        }
                                        .font(.caption)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(timeOfDay == time ? Color.green : Color(.systemGray5))
                                        .foregroundColor(timeOfDay == time ? .white : .primary)
                                        .cornerRadius(6)
                                    }
                                }
                                .padding(.leading, 20)
                            }
                        }
                    }
                    
                    // Play Button
                    Button(action: playSelectedAudio) {
                        HStack {
                            Image(systemName: audioEngine.isPlaying ? "stop.fill" : "play.fill")
                            Text(audioEngine.isPlaying ? "Stop Audio" : "Play Audio")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(audioEngine.isPlaying ? Color.red : Color.blue)
                        .cornerRadius(12)
                    }
                    .disabled(false)
                }
                .padding()
            }
            .navigationTitle("Audio Controls")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func playSelectedAudio() {
        if audioEngine.isPlaying {
            audioEngine.stopAudio()
            } else {
            Task {
                await audioEngine.generatePreSleepAudio(type: selectedPreSleepType, duration: 1800)
            }
        }
    }
    
    // Selection helpers
    private var isBinauralSelected: Bool {
        if case .binauralBeats = selectedPreSleepType { return true }
        return false
    }
    
    private var isWhiteNoiseSelected: Bool {
        if case .whiteNoise = selectedPreSleepType { return true }
        return false
    }
    
    private var isNatureSelected: Bool {
        if case .natureSounds = selectedPreSleepType { return true }
        return false
    }
    
    private var isMeditationSelected: Bool {
        if case .guidedMeditation = selectedPreSleepType { return true }
        return false
    }
    
    private var isAmbientSelected: Bool {
        if case .ambientMusic = selectedPreSleepType { return true }
        return false
    }
    
    private var isDeepSleepSelected: Bool {
        if case .deepSleep = selectedSleepType { return true }
        return false
    }
    
    private var isOceanSelected: Bool {
        if case .oceanWaves = selectedSleepType { return true }
        return false
    }
    
    private var isRainSelected: Bool {
        if case .rainSounds = selectedSleepType { return true }
        return false
    }
    
    private var isForestSelected: Bool {
        if case .forestAmbience = selectedSleepType { return true }
        return false
    }
    
    // Helper functions for names
    private func colorName(_ color: NoiseColor) -> String {
        switch color {
        case .white: return "White"
        case .pink: return "Pink"
        case .brown: return "Brown"
        }
    }
    
    private func intensityName(_ intensity: WaveIntensity) -> String {
        switch intensity {
        case .gentle: return "Gentle"
        case .moderate: return "Moderate"
        case .strong: return "Strong"
        }
    }
    
    private func intensityName(_ intensity: RainIntensity) -> String {
        switch intensity {
        case .gentle: return "Gentle"
        case .moderate: return "Moderate"
        case .heavy: return "Heavy"
        }
    }
    
    private func timeName(_ time: TimeOfDay) -> String {
        switch time {
        case .dawn: return "Dawn"
        case .day: return "Day"
        case .dusk: return "Dusk"
        case .night: return "Night"
        }
    }
}


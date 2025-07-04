import SwiftUI
import HealthKit
import AVFoundation
import CoreHaptics
import Combine
import os.log

// MARK: - Audio Controls Section

struct AudioControlsSection: View {
    @ObservedObject var audioEngine: AudioGenerationEngine
    @State private var selectedAudioType: AudioType = .binaural(frequency: 4.0)
    @State private var showingAudioSettings = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "speaker.wave.3.fill")
                    .foregroundColor(.blue)
                Text("Sleep Audio")
                .font(.headline)
                Spacer()
                Button("Settings") {
                    showingAudioSettings = true
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            
            // Audio Type Selector
            VStack(alignment: .leading, spacing: 12) {
                Text("Audio Type")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        AudioTypeButton(
                            title: "Binaural Beats",
                            subtitle: "4Hz Theta",
                            isSelected: isBinauralSelected,
                            action: { selectedAudioType = .binaural(frequency: 4.0) }
                        )
                        
                        AudioTypeButton(
                            title: "White Noise",
                            subtitle: "Pink",
                            isSelected: isWhiteNoiseSelected,
                            action: { selectedAudioType = .whiteNoise(color: .pink) }
                        )
                        
                        AudioTypeButton(
                            title: "Nature",
                            subtitle: "Ocean",
                            isSelected: isNatureSelected,
                            action: { selectedAudioType = .nature(environment: .ocean) }
                        )
                        
                        AudioTypeButton(
                            title: "Meditation",
                            subtitle: "Mindfulness",
                            isSelected: isMeditationSelected,
                            action: { selectedAudioType = .meditation(style: .mindfulness) }
                        )
                        
                        AudioTypeButton(
                            title: "Ambient",
                            subtitle: "Drone",
                            isSelected: isAmbientSelected,
                            action: { selectedAudioType = .ambient(genre: .drone) }
                        )
                    }
                    .padding(.horizontal, 4)
                }
            }
            
            // Audio Controls
            HStack(spacing: 20) {
                // Play/Pause Button
                Button(action: toggleAudio) {
                    Image(systemName: audioEngine.isAudioPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 44))
                        .foregroundColor(.blue)
                }
                
                // Volume Control
                VStack(alignment: .leading, spacing: 4) {
                    Text("Volume")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Image(systemName: "speaker.fill")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Slider(
                            value: Binding(
                                get: { audioEngine.volume },
                                set: { audioEngine.setVolume($0) }
                            ),
                            in: 0...1
                        )
                        .accentColor(.blue)
                        
                        Image(systemName: "speaker.wave.3.fill")
                            .font(.caption)
                    .foregroundColor(.secondary)
                    }
                }
            }
            
            // Audio Quality Indicators
            HStack(spacing: 16) {
                AudioQualityIndicator(
                    title: "Spatial Audio",
                    isEnabled: audioEngine.spatialAudioEnabled,
                    icon: "speaker.wave.3"
                )
                
                AudioQualityIndicator(
                    title: "EQ: \(audioEngine.eqPreset.rawValue)",
                    isEnabled: true,
                    icon: "slider.horizontal.3"
                )
                
                AudioQualityIndicator(
                    title: "Reverb: \(Int(audioEngine.reverbLevel * 100))%",
                    isEnabled: audioEngine.reverbLevel > 0,
                    icon: "waveform"
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .sheet(isPresented: $showingAudioSettings) {
            AudioSettingsView(audioEngine: audioEngine)
    }
        .onChange(of: selectedAudioType) { newType in
            Task {
                await audioEngine.generateAudio(type: newType)
            }
        }
    }
    
    private var isBinauralSelected: Bool {
        if case .binaural = selectedAudioType { return true }
        return false
    }
    
    private var isWhiteNoiseSelected: Bool {
        if case .whiteNoise = selectedAudioType { return true }
        return false
    }
    
    private var isNatureSelected: Bool {
        if case .nature = selectedAudioType { return true }
        return false
    }
    
    private var isMeditationSelected: Bool {
        if case .meditation = selectedAudioType { return true }
        return false
    }
    
    private var isAmbientSelected: Bool {
        if case .ambient = selectedAudioType { return true }
        return false
    }
    
    private func toggleAudio() {
        Task {
            if audioEngine.isAudioPlaying {
                await audioEngine.stopAudio()
            } else {
                await audioEngine.playAudio()
            }
        }
    }
}

struct AudioTypeButton: View {
    let title: String
    let subtitle: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Color.blue : Color(.systemGray5))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(8)
        }
    }
}

struct AudioQualityIndicator: View {
    let title: String
    let isEnabled: Bool
    let icon: String
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(isEnabled ? .green : .secondary)
            Text(title)
                .font(.caption)
                .foregroundColor(isEnabled ? .primary : .secondary)
        }
    }
}

struct AudioSettingsView: View {
    @ObservedObject var audioEngine: AudioGenerationEngine
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section("Audio Quality") {
                    Toggle("Spatial Audio", isOn: $audioEngine.spatialAudioEnabled)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Reverb Level")
                        Slider(value: $audioEngine.reverbLevel, in: 0...1)
                        Text("\(Int(audioEngine.reverbLevel * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
                }
                
                Section("Equalizer") {
                    Picker("EQ Preset", selection: $audioEngine.eqPreset) {
                        ForEach(EQPreset.allCases, id: \.self) { preset in
                            Text(preset.rawValue).tag(preset)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                
                Section("Advanced Audio") {
                    NavigationLink("Custom Audio Mix") {
                        CustomAudioMixView(audioEngine: audioEngine)
                    }
                    
                    NavigationLink("Progressive Audio") {
                        ProgressiveAudioView(audioEngine: audioEngine)
                    }
                }
            }
            .navigationTitle("Audio Settings")
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
}

struct CustomAudioMixView: View {
    @ObservedObject var audioEngine: AudioGenerationEngine
    @State private var selectedTypes: [AudioType] = []
    @State private var weights: [Float] = []
    
    var body: some View {
        Form {
            Section("Select Audio Types") {
                ForEach(AudioType.allCases, id: \.self) { audioType in
                    Toggle(audioType.displayName, isOn: Binding(
                        get: { selectedTypes.contains(audioType) },
                        set: { isSelected in
                            if isSelected {
                                selectedTypes.append(audioType)
                                weights.append(1.0)
                            } else {
                                if let index = selectedTypes.firstIndex(of: audioType) {
                                    selectedTypes.remove(at: index)
                                    weights.remove(at: index)
                                }
                            }
                        }
                    ))
                }
            }
            
            if !selectedTypes.isEmpty {
                Section("Mix Weights") {
                    ForEach(Array(selectedTypes.enumerated()), id: \.offset) { index, audioType in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(audioType.displayName)
                            Slider(value: Binding(
                                get: { weights[index] },
                                set: { weights[index] = $0 }
                            ), in: 0...2)
                            Text("\(String(format: "%.1f", weights[index]))x")
                .font(.caption)
                .foregroundColor(.secondary)
        }
                    }
                }
                
                Section {
                    Button("Generate Custom Mix") {
                        Task {
                            await audioEngine.generateCustomMix(
                                audioTypes: selectedTypes,
                                weights: weights,
                                duration: 300.0
                            )
                        }
                    }
                    .disabled(selectedTypes.isEmpty)
                }
            }
        }
        .navigationTitle("Custom Mix")
    }
}

struct ProgressiveAudioView: View {
    @ObservedObject var audioEngine: AudioGenerationEngine
    @State private var startType: AudioType = .binaural(frequency: 8.0)
    @State private var endType: AudioType = .binaural(frequency: 0.5)
    @State private var duration: TimeInterval = 1800 // 30 minutes
    
    var body: some View {
        Form {
            Section("Start Audio") {
                Picker("Start Type", selection: $startType) {
                    ForEach(AudioType.allCases, id: \.self) { audioType in
                        Text(audioType.displayName).tag(audioType)
                    }
                }
            }
            
            Section("End Audio") {
                Picker("End Type", selection: $endType) {
                    ForEach(AudioType.allCases, id: \.self) { audioType in
                        Text(audioType.displayName).tag(audioType)
                    }
                }
            }
            
            Section("Duration") {
                Picker("Duration", selection: $duration) {
                    Text("15 minutes").tag(TimeInterval(900))
                    Text("30 minutes").tag(TimeInterval(1800))
                    Text("45 minutes").tag(TimeInterval(2700))
                    Text("60 minutes").tag(TimeInterval(3600))
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            
            Section {
                Button("Generate Progressive Audio") {
                    Task {
                        await audioEngine.generateProgressiveAudio(
                            startType: startType,
                            endType: endType,
                            duration: duration
                        )
                    }
                }
            }
        }
        .navigationTitle("Progressive Audio")
    }
}


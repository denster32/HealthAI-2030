import SwiftUI
import AVFoundation

/// Enhanced Audio View - Advanced audio controls and visualization
struct EnhancedAudioView: View {
    @StateObject private var audioEngine = EnhancedAudioEngine.shared
    @State private var selectedAudioType: AudioType = .none
    @State private var showingCustomSoundscape = false
    @State private var showingAudioVisualization = false
    @State private var customLayers: [AudioLayer] = []
    
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private var gridColumns: [GridItem] {
        if horizontalSizeClass == .regular {
            [GridItem(.adaptive(minimum: 160))]
        } else {
            Array(repeating: GridItem(.flexible()), count: 2)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // MARK: - Audio Visualization
                    if audioEngine.audioVisualization {
                        AudioVisualizationView(spectrumData: audioEngine.spectrumData)
                            .frame(height: 120)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                    }
                    
                    // MARK: - Current Audio Status
                    CurrentAudioStatusView(audioEngine: audioEngine)
                    
                    // MARK: - Enhanced Audio Controls
                    EnhancedAudioControlsView(audioEngine: audioEngine)
                    
                    // MARK: - Spatial Audio Controls
                    SpatialAudioControlsView(audioEngine: audioEngine)
                    
                    // MARK: - Custom Soundscape Creator
                    CustomSoundscapeView(audioEngine: audioEngine)
                    
                    // MARK: - Advanced Settings
                    AdvancedAudioSettingsView(audioEngine: audioEngine)
                }
                .padding()
            }
            .navigationTitle("Enhanced Audio")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAudioVisualization.toggle()
                        audioEngine.audioVisualization = showingAudioVisualization
                    }) {
                        Image(systemName: showingAudioVisualization ? "waveform" : "waveform.badge.plus")
                    }
                }
            }
        }
    }
}

// MARK: - Audio Visualization View
struct AudioVisualizationView: View {
    let spectrumData: [Float]
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 2) {
            ForEach(Array(spectrumData.enumerated()), id: \.offset) { index, value in
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.blue.opacity(0.8))
                    .frame(width: 4, height: max(4, CGFloat(value) * 100))
                    .animation(.easeInOut(duration: 0.1), value: value)
            }
        }
    }
}

// MARK: - Current Audio Status View
struct CurrentAudioStatusView: View {
    @ObservedObject var audioEngine: EnhancedAudioEngine
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: audioEngine.isPlaying ? "speaker.wave.3.fill" : "speaker.slash")
                    .font(.title2)
                    .foregroundColor(audioEngine.isPlaying ? .green : .gray)
                
                VStack(alignment: .leading) {
                    Text(audioEngine.currentAudioType.displayName)
                        .font(.headline)
                    Text(audioEngine.isPlaying ? "Playing" : "Stopped")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: {
                    if audioEngine.isPlaying {
                        audioEngine.stopAudio()
                    }
                }) {
                    Image(systemName: "stop.fill")
                        .foregroundColor(.red)
                }
            }
            
            // Volume Slider
            VStack(alignment: .leading) {
                HStack {
                    Text("Volume")
                    Spacer()
                    Text("\(Int(audioEngine.volume * 100))%")
                }
                .font(.caption)
                
                Slider(value: $audioEngine.volume, in: 0...1)
                    .accentColor(.blue)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Enhanced Audio Controls View
struct EnhancedAudioControlsView: View {
    @ObservedObject var audioEngine: EnhancedAudioEngine
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Audio Controls")
                .font(.headline)
            
            // Pre-Sleep Audio
            VStack(alignment: .leading, spacing: 8) {
                Text("Pre-Sleep Audio")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                LazyVGrid(columns: gridColumns, spacing: 8) {
                    AudioTypeButton(title: "Binaural Beats", icon: "waveform.path", action: {
                        Task {
                            await audioEngine.generatePreSleepAudio(type: .binauralBeats(4.0))
                        }
                    })
                    
                    AudioTypeButton(title: "White Noise", icon: "speaker.wave.2", action: {
                        Task {
                            await audioEngine.generatePreSleepAudio(type: .whiteNoise(.pink))
                        }
                    })
                    
                    AudioTypeButton(title: "Nature Sounds", icon: "leaf", action: {
                        Task {
                            await audioEngine.generatePreSleepAudio(type: .natureSounds(.forest))
                        }
                    })
                    
                    AudioTypeButton(title: "Meditation", icon: "brain.head.profile", action: {
                        Task {
                            await audioEngine.generatePreSleepAudio(type: .guidedMeditation(.breathing))
                        }
                    })
                }
            }
            
            // Sleep Audio
            VStack(alignment: .leading, spacing: 8) {
                Text("Sleep Audio")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                LazyVGrid(columns: gridColumns, spacing: 8) {
                    AudioTypeButton(title: "Deep Sleep", icon: "moon.fill", action: {
                        Task {
                            await audioEngine.generateSleepAudio(type: .deepSleep(2.0))
                        }
                    })
                    
                    AudioTypeButton(title: "Ocean Waves", icon: "water.waves", action: {
                        Task {
                            await audioEngine.generateSleepAudio(type: .oceanWaves(.gentle))
                        }
                    })
                    
                    AudioTypeButton(title: "Rain Sounds", icon: "cloud.rain", action: {
                        Task {
                            await audioEngine.generateSleepAudio(type: .rainSounds(.gentle))
                        }
                    })
                    
                    AudioTypeButton(title: "Forest Ambience", icon: "tree", action: {
                        Task {
                            await audioEngine.generateSleepAudio(type: .forestAmbience(.night))
                        }
                    })
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Spatial Audio Controls View
struct SpatialAudioControlsView: View {
    @ObservedObject var audioEngine: EnhancedAudioEngine
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Spatial Audio")
                .font(.headline)
            
            VStack(spacing: 12) {
                // Spatial Audio Toggle
                HStack {
                    Image(systemName: "speaker.wave.3")
                        .foregroundColor(.blue)
                    
                    Text("Spatial Audio")
                    
                    Spacer()
                    
                    Toggle("", isOn: $audioEngine.isSpatialAudioEnabled)
                        .toggleStyle(SwitchToggleStyle(tint: .blue))
                }
                
                // Spatial Audio Mode
                if audioEngine.isSpatialAudioEnabled {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Spatial Mode")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Picker("Spatial Mode", selection: $audioEngine.spatialAudioMode) {
                            ForEach(SpatialAudioMode.allCases, id: \.self) { mode in
                                Text(mode.rawValue).tag(mode)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                }
                
                // Reverb Level
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Reverb")
                        Spacer()
                        Text("\(Int(audioEngine.reverbLevel * 100))%")
                    }
                    .font(.caption)
                    
                    Slider(value: $audioEngine.reverbLevel, in: 0...1)
                        .accentColor(.blue)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Custom Soundscape View
struct CustomSoundscapeView: View {
    @ObservedObject var audioEngine: EnhancedAudioEngine
    @State private var showingLayerEditor = false
    @State private var selectedLayer: AudioLayer?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Custom Soundscape")
                    .font(.headline)
                
                Spacer()
                
                Button("Create New") {
                    showingLayerEditor = true
                }
                .buttonStyle(.borderedProminent)
            }
            
            if let customSoundscape = audioEngine.customSoundscape {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text(customSoundscape.name)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Spacer()
                        
                        Button("Play") {
                            Task {
                                await audioEngine.playCustomSoundscape(customSoundscape)
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                    
                    Text("\(customSoundscape.layers.count) layers")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    // Layer preview
                    ForEach(customSoundscape.layers) { layer in
                        HStack {
                            Image(systemName: layerIcon(for: layer.type))
                                .foregroundColor(.blue)
                            
                            Text(layer.type.rawValue)
                                .font(.caption)
                            
                            Spacer()
                            
                            Text("\(Int(layer.volume * 100))%")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(8)
            } else {
                Text("No custom soundscape created yet")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .sheet(isPresented: $showingLayerEditor) {
            LayerEditorView(audioEngine: audioEngine)
        }
    }
    
    private func layerIcon(for type: AudioLayerType) -> String {
        switch type {
        case .binauralBeats: return "waveform.path"
        case .whiteNoise: return "speaker.wave.2"
        case .natureSounds: return "leaf"
        case .ambientMusic: return "music.note"
        case .custom: return "gearshape"
        }
    }
}

// MARK: - Advanced Audio Settings View
struct AdvancedAudioSettingsView: View {
    @ObservedObject var audioEngine: EnhancedAudioEngine
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Advanced Settings")
                .font(.headline)
            
            VStack(spacing: 12) {
                // Adaptive Mixing
                HStack {
                    Image(systemName: "slider.horizontal.3")
                        .foregroundColor(.green)
                    
                    Text("Adaptive Mixing")
                    
                    Spacer()
                    
                    Toggle("", isOn: $audioEngine.adaptiveMixing)
                        .toggleStyle(SwitchToggleStyle(tint: .green))
                }
                
                // Smart Fading
                HStack {
                    Image(systemName: "volume.slash")
                        .foregroundColor(.orange)
                    
                    Text("Smart Fading")
                    
                    Spacer()
                    
                    Toggle("", isOn: $audioEngine.smartFading)
                        .toggleStyle(SwitchToggleStyle(tint: .orange))
                }
                
                // Haptic Feedback
                HStack {
                    Image(systemName: "iphone.radiowaves.left.and.right")
                        .foregroundColor(.purple)
                    
                    Text("Haptic Feedback")
                    
                    Spacer()
                    
                    Toggle("", isOn: $audioEngine.hapticFeedback)
                        .toggleStyle(SwitchToggleStyle(tint: .purple))
                }
                
                // Auto Volume Adjustment
                HStack {
                    Image(systemName: "speaker.wave.1")
                        .foregroundColor(.blue)
                    
                    Text("Auto Volume Adjustment")
                    
                    Spacer()
                    
                    Toggle("", isOn: $audioEngine.autoVolumeAdjustment)
                        .toggleStyle(SwitchToggleStyle(tint: .blue))
                }
                
                // EQ Preset
                VStack(alignment: .leading, spacing: 8) {
                    Text("EQ Preset")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Picker("EQ Preset", selection: $audioEngine.eqPreset) {
                        ForEach(EQPreset.allCases, id: \.self) { preset in
                            Text(preset.rawValue).tag(preset)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Supporting Views

struct AudioTypeButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.blue)
                
                Text(title)
                    .font(.caption)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct LayerEditorView: View {
    @ObservedObject var audioEngine: EnhancedAudioEngine
    @Environment(\.dismiss) private var dismiss
    @State private var layers: [AudioLayer] = []
    @State private var selectedLayerType: AudioLayerType = .binauralBeats
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Layer Type Selection
                VStack(alignment: .leading, spacing: 8) {
                    Text("Layer Type")
                        .font(.headline)
                    
                    Picker("Layer Type", selection: $selectedLayerType) {
                        ForEach(AudioLayerType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                // Layer Parameters
                LayerParametersView(layerType: selectedLayerType)
                
                // Add Layer Button
                Button("Add Layer") {
                    let newLayer = AudioLayer(
                        type: selectedLayerType,
                        volume: 0.5,
                        pan: 0.0,
                        enabled: true,
                        parameters: [:]
                    )
                    layers.append(newLayer)
                }
                .buttonStyle(.borderedProminent)
                
                // Layers List
                if !layers.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Layers (\(layers.count))")
                            .font(.headline)
                        
                        ForEach(layers.indices, id: \.self) { index in
                            LayerRowView(layer: $layers[index])
                        }
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Create Soundscape")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        Task {
                            _ = await audioEngine.createCustomSoundscape(layers: layers)
                            dismiss()
                        }
                    }
                    .disabled(layers.isEmpty)
                }
            }
        }
    }
}

struct LayerParametersView: View {
    let layerType: AudioLayerType
    @State private var volume: Float = 0.5
    @State private var pan: Float = 0.0
    
    var body: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Volume")
                    Spacer()
                    Text("\(Int(volume * 100))%")
                }
                .font(.caption)
                
                Slider(value: $volume, in: 0...1)
                    .accentColor(.blue)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Pan")
                    Spacer()
                    Text(pan == 0 ? "Center" : pan > 0 ? "Right" : "Left")
                }
                .font(.caption)
                
                Slider(value: $pan, in: -1...1)
                    .accentColor(.green)
            }
        }
    }
}

struct LayerRowView: View {
    @Binding var layer: AudioLayer
    
    var body: some View {
        HStack {
            Image(systemName: layerIcon(for: layer.type))
                .foregroundColor(.blue)
            
            VStack(alignment: .leading) {
                Text(layer.type.rawValue)
                    .font(.subheadline)
                Text("Vol: \(Int(layer.volume * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Toggle("", isOn: $layer.enabled)
                .toggleStyle(SwitchToggleStyle(tint: .green))
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
    
    private func layerIcon(for type: AudioLayerType) -> String {
        switch type {
        case .binauralBeats: return "waveform.path"
        case .whiteNoise: return "speaker.wave.2"
        case .natureSounds: return "leaf"
        case .ambientMusic: return "music.note"
        case .custom: return "gearshape"
        }
    }
}

// MARK: - Extensions

extension AudioType {
    var displayName: String {
        switch self {
        case .none:
            return "No Audio"
        case .preSleep(let type):
            return "Pre-Sleep: \(type.displayName)"
        case .sleep(let type):
            return "Sleep: \(type.displayName)"
        case .custom(let soundscape):
            return "Custom: \(soundscape.name)"
        }
    }
}

extension PreSleepAudioType {
    var displayName: String {
        switch self {
        case .binauralBeats: return "Binaural Beats"
        case .whiteNoise: return "White Noise"
        case .natureSounds: return "Nature Sounds"
        case .guidedMeditation: return "Meditation"
        case .ambientMusic: return "Ambient Music"
        }
    }
}

extension SleepAudioType {
    var displayName: String {
        switch self {
        case .deepSleep: return "Deep Sleep"
        case .continuousWhiteNoise: return "White Noise"
        case .oceanWaves: return "Ocean Waves"
        case .rainSounds: return "Rain Sounds"
        case .forestAmbience: return "Forest Ambience"
        }
    }
}

// MARK: - Preview
struct EnhancedAudioView_Previews: PreviewProvider {
    static var previews: some View {
        EnhancedAudioView()
    }
} 
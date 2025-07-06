import SwiftUI
import AVFoundation

@available(tvOS 18.0, *)
struct SpatialAudioBiofeedbackView: View {
    @StateObject private var spatialAudioManager = SpatialAudioManager()
    @State private var selectedSession: BiofeedbackSession?
    @State private var isSessionActive = false
    @State private var sessionTimeRemaining: TimeInterval = 0
    @State private var showingSessionSelection = false
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.black.opacity(0.9),
                    Color.purple.opacity(0.3),
                    Color.blue.opacity(0.2)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            if isSessionActive {
                ActiveSessionView(
                    session: selectedSession!,
                    timeRemaining: sessionTimeRemaining,
                    spatialAudioManager: spatialAudioManager,
                    onEnd: endSession
                )
            } else {
                SessionSelectionView(
                    onSessionSelected: startSession
                )
            }
        }
        .navigationTitle("Spatial Audio Biofeedback")
        .navigationBarTitleDisplayMode(.large)
    }
    
    private func startSession(_ session: BiofeedbackSession) {
        selectedSession = session
        sessionTimeRemaining = session.duration
        isSessionActive = true
        
        spatialAudioManager.startSpatialAudioZone(with: session)
        
        startSessionTimer()
    }
    
    private func endSession() {
        isSessionActive = false
        selectedSession = nil
        sessionTimeRemaining = 0
        
        spatialAudioManager.stopSpatialAudioZone()
    }
    
    private func startSessionTimer() {
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            if sessionTimeRemaining > 0 {
                sessionTimeRemaining -= 1
            } else {
                timer.invalidate()
                endSession()
            }
        }
    }
}

struct SessionSelectionView: View {
    let onSessionSelected: (BiofeedbackSession) -> Void
    
    private let availableSessions: [BiofeedbackSession] = [
        BiofeedbackSession(
            id: UUID(),
            name: "Forest Meditation",
            duration: 600, // 10 minutes
            audioZones: [
                AudioZone(
                    id: UUID(),
                    position: SpatialPosition(x: -2, y: 0, z: 2),
                    audioSource: AudioSource(fileName: "forest_birds", fileExtension: "wav", category: .nature),
                    intensityRange: 0.3...0.8,
                    biofeedbackType: .heartRate
                ),
                AudioZone(
                    id: UUID(),
                    position: SpatialPosition(x: 2, y: 0, z: 2),
                    audioSource: AudioSource(fileName: "forest_stream", fileExtension: "wav", category: .nature),
                    intensityRange: 0.2...0.6,
                    biofeedbackType: .breathing
                ),
                AudioZone(
                    id: UUID(),
                    position: SpatialPosition(x: 0, y: 1, z: -2),
                    audioSource: AudioSource(fileName: "wind_leaves", fileExtension: "wav", category: .nature),
                    intensityRange: 0.1...0.4,
                    biofeedbackType: .stress
                )
            ],
            sessionType: .meditation
        ),
        BiofeedbackSession(
            id: UUID(),
            name: "Ocean Breathing",
            duration: 480, // 8 minutes
            audioZones: [
                AudioZone(
                    id: UUID(),
                    position: SpatialPosition(x: 0, y: 0, z: 3),
                    audioSource: AudioSource(fileName: "ocean_waves", fileExtension: "wav", category: .nature),
                    intensityRange: 0.4...0.9,
                    biofeedbackType: .breathing
                ),
                AudioZone(
                    id: UUID(),
                    position: SpatialPosition(x: -1, y: 0, z: 1),
                    audioSource: AudioSource(fileName: "ocean_depth", fileExtension: "wav", category: .ambient),
                    intensityRange: 0.2...0.5,
                    biofeedbackType: .coherence
                )
            ],
            sessionType: .breathingExercise
        ),
        BiofeedbackSession(
            id: UUID(),
            name: "Mountain Tranquility",
            duration: 900, // 15 minutes
            audioZones: [
                AudioZone(
                    id: UUID(),
                    position: SpatialPosition(x: 0, y: 2, z: 0),
                    audioSource: AudioSource(fileName: "mountain_wind", fileExtension: "wav", category: .nature),
                    intensityRange: 0.3...0.7,
                    biofeedbackType: .stress
                ),
                AudioZone(
                    id: UUID(),
                    position: SpatialPosition(x: 1, y: 0, z: 2),
                    audioSource: AudioSource(fileName: "tibetan_bowls", fileExtension: "wav", category: .frequency),
                    intensityRange: 0.2...0.6,
                    biofeedbackType: .heartRate
                )
            ],
            sessionType: .stressRelief
        ),
        BiofeedbackSession(
            id: UUID(),
            name: "Sleep Preparation",
            duration: 1200, // 20 minutes
            audioZones: [
                AudioZone(
                    id: UUID(),
                    position: SpatialPosition(x: 0, y: 0, z: 1),
                    audioSource: AudioSource(fileName: "sleep_ambient", fileExtension: "wav", category: .ambient),
                    intensityRange: 0.1...0.3,
                    biofeedbackType: .heartRate
                ),
                AudioZone(
                    id: UUID(),
                    position: SpatialPosition(x: -1, y: 0, z: 0),
                    audioSource: AudioSource(fileName: "delta_waves", fileExtension: "wav", category: .binaural),
                    intensityRange: 0.2...0.4,
                    biofeedbackType: .breathing
                )
            ],
            sessionType: .sleepPreparation
        )
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                // Header
                VStack(spacing: 15) {
                    Text("Spatial Audio Biofeedback")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("Immersive meditation environments that adapt to your biometrics")
                        .font(.title2)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 40)
                
                // Session Cards
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 25) {
                    ForEach(availableSessions, id: \.id) { session in
                        SessionCard(session: session) {
                            onSessionSelected(session)
                        }
                    }
                }
                .padding(.horizontal, 40)
                
                // Features Section
                FeaturesSection()
                    .padding(.top, 30)
            }
            .padding(.bottom, 40)
        }
    }
}

struct SessionCard: View {
    let session: BiofeedbackSession
    let onStart: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Session Icon and Title
            HStack {
                Image(systemName: sessionIcon)
                    .font(.title)
                    .foregroundColor(sessionColor)
                
                VStack(alignment: .leading) {
                    Text(session.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Text(sessionTypeText)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
            }
            
            // Duration
            HStack {
                Image(systemName: "clock")
                    .foregroundColor(.gray)
                Text(durationText)
                    .font(.body)
                    .foregroundColor(.gray)
            }
            
            // Audio Zones Count
            HStack {
                Image(systemName: "speaker.wave.3")
                    .foregroundColor(.gray)
                Text("\(session.audioZones.count) Audio Zones")
                    .font(.body)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            // Start Button
            Button(action: onStart) {
                HStack {
                    Image(systemName: "play.fill")
                    Text("Start Session")
                        .fontWeight(.medium)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(sessionColor)
                .cornerRadius(10)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(25)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(sessionColor.opacity(0.3), lineWidth: 2)
                )
        )
        .shadow(color: sessionColor.opacity(0.2), radius: 10, x: 0, y: 5)
    }
    
    private var sessionIcon: String {
        switch session.sessionType {
        case .meditation: return "leaf.fill"
        case .breathingExercise: return "wind"
        case .stressRelief: return "mountain.2.fill"
        case .sleepPreparation: return "moon.fill"
        }
    }
    
    private var sessionColor: Color {
        switch session.sessionType {
        case .meditation: return .green
        case .breathingExercise: return .blue
        case .stressRelief: return .purple
        case .sleepPreparation: return .indigo
        }
    }
    
    private var sessionTypeText: String {
        switch session.sessionType {
        case .meditation: return "Meditation"
        case .breathingExercise: return "Breathing Exercise"
        case .stressRelief: return "Stress Relief"
        case .sleepPreparation: return "Sleep Preparation"
        }
    }
    
    private var durationText: String {
        let minutes = Int(session.duration / 60)
        return "\(minutes) minutes"
    }
}

struct ActiveSessionView: View {
    let session: BiofeedbackSession
    let timeRemaining: TimeInterval
    let spatialAudioManager: SpatialAudioManager
    let onEnd: () -> Void
    
    var body: some View {
        VStack(spacing: 40) {
            // Session Header
            VStack(spacing: 15) {
                Text(session.name)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text(timeRemainingText)
                    .font(.title)
                    .foregroundColor(.gray)
                    .monospacedDigit()
            }
            
            // Biofeedback Visualization
            BiofeedbackVisualization(spatialAudioManager: spatialAudioManager)
            
            // Audio Zones Status
            AudioZonesStatus(session: session, spatialAudioManager: spatialAudioManager)
            
            // Controls
            HStack(spacing: 30) {
                Button("End Session") {
                    onEnd()
                }
                .buttonStyle(.bordered)
                .foregroundColor(.white)
                .frame(width: 200)
                
                Button("Pause") {
                    // Pause functionality
                }
                .buttonStyle(.borderedProminent)
                .frame(width: 200)
            }
        }
        .padding(40)
    }
    
    private var timeRemainingText: String {
        let minutes = Int(timeRemaining / 60)
        let seconds = Int(timeRemaining.truncatingRemainder(dividingBy: 60))
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

struct BiofeedbackVisualization: View {
    @ObservedObject var spatialAudioManager: SpatialAudioManager
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Biofeedback Adaptation")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            HStack(spacing: 40) {
                VStack {
                    Text("Heart Rate")
                        .font(.headline)
                        .foregroundColor(.red)
                    
                    CircularProgressView(
                        progress: Double(spatialAudioManager.heartRateAdaptiveIntensity),
                        color: .red
                    )
                    .frame(width: 100, height: 100)
                    
                    Text("Adaptive Intensity")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                VStack {
                    Text("Breathing")
                        .font(.headline)
                        .foregroundColor(.blue)
                    
                    CircularProgressView(
                        progress: Double(spatialAudioManager.breathingRateAdaptiveIntensity),
                        color: .blue
                    )
                    .frame(width: 100, height: 100)
                    
                    Text("Adaptive Intensity")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(30)
        .background(Color.white.opacity(0.1))
        .cornerRadius(20)
    }
}

struct CircularProgressView: View {
    let progress: Double
    let color: Color
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.3), lineWidth: 8)
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(color, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.5), value: progress)
            
            Text("\(Int(progress * 100))%")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(color)
        }
    }
}

struct AudioZonesStatus: View {
    let session: BiofeedbackSession
    @ObservedObject var spatialAudioManager: SpatialAudioManager
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Audio Zones")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 15) {
                ForEach(session.audioZones, id: \.id) { zone in
                    AudioZoneCard(zone: zone, spatialAudioManager: spatialAudioManager)
                }
            }
        }
        .padding(25)
        .background(Color.white.opacity(0.1))
        .cornerRadius(20)
    }
}

struct AudioZoneCard: View {
    let zone: AudioZone
    @ObservedObject var spatialAudioManager: SpatialAudioManager
    
    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Image(systemName: zoneIcon)
                    .foregroundColor(zoneColor)
                    .font(.title3)
                
                Spacer()
                
                Text(biofeedbackTypeText)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Text(zone.audioSource.fileName.capitalized)
                .font(.body)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            
            // Position indicator
            Text("Position: (\(zone.position.x, specifier: "%.1f"), \(zone.position.y, specifier: "%.1f"), \(zone.position.z, specifier: "%.1f"))")
                .font(.caption2)
                .foregroundColor(.gray)
        }
        .padding(15)
        .background(Color.white.opacity(0.05))
        .cornerRadius(15)
    }
    
    private var zoneIcon: String {
        switch zone.audioSource.category {
        case .nature: return "leaf.fill"
        case .ambient: return "waveform"
        case .binaural: return "headphones"
        case .frequency: return "tuningfork"
        }
    }
    
    private var zoneColor: Color {
        switch zone.biofeedbackType {
        case .heartRate: return .red
        case .breathing: return .blue
        case .stress: return .purple
        case .coherence: return .green
        }
    }
    
    private var biofeedbackTypeText: String {
        switch zone.biofeedbackType {
        case .heartRate: return "Heart Rate"
        case .breathing: return "Breathing"
        case .stress: return "Stress"
        case .coherence: return "Coherence"
        }
    }
}

struct FeaturesSection: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("Features")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 20) {
                FeatureCard(
                    icon: "waveform.path.ecg",
                    title: "Real-time Biofeedback",
                    description: "Audio adapts to your heart rate and breathing patterns"
                )
                
                FeatureCard(
                    icon: "speaker.wave.3",
                    title: "Spatial Audio Zones",
                    description: "3D positioned audio creates immersive environments"
                )
                
                FeatureCard(
                    icon: "applewatch",
                    title: "Apple Watch Integration",
                    description: "Seamless health data sync for accurate biofeedback"
                )
            }
        }
        .padding(.horizontal, 40)
    }
}

struct FeatureCard: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        VStack(spacing: 15) {
            Image(systemName: icon)
                .font(.largeTitle)
                .foregroundColor(.cyan)
            
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            
            Text(description)
                .font(.body)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .padding(20)
        .background(Color.white.opacity(0.1))
        .cornerRadius(15)
    }
}

#Preview {
    SpatialAudioBiofeedbackView()
}
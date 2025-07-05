import SwiftUI
import AVKit
import AVFoundation

@available(tvOS 18.0, *)
struct TVMeditationPlayerView: View {
    @StateObject private var audioPlayer = AudioPlayer()
    @State private var selectedMeditation: Meditation?
    @State private var showingMeditationPicker = false
    @State private var isPlaying = false
    @State private var currentTime: TimeInterval = 0
    @State private var totalDuration: TimeInterval = 0
    @State private var breathingPhase: BreathingPhase = .inhale
    @State private var breathingTimer: Timer?
    
    enum BreathingPhase {
        case inhale, hold, exhale
        
        var instruction: String {
            switch self {
            case .inhale: return "Breathe In..."
            case .hold: return "Hold..."
            case .exhale: return "Breathe Out..."
            }
        }
        
        var duration: TimeInterval {
            switch self {
            case .inhale: return 4.0
            case .hold: return 4.0
            case .exhale: return 6.0
            }
        }
    }
    
    var body: some View {
        ZStack {
            // Background
            BackgroundView()
            
            VStack(spacing: 40) {
                // Header
                VStack(spacing: 16) {
                    Text("Guided Meditation")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    if let meditation = selectedMeditation {
                        Text(meditation.title)
                            .font(.title2)
                            .foregroundColor(.white.opacity(0.8))
                    } else {
                        Text("Choose a meditation to begin")
                            .font(.title2)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                
                // Meditation Picker
                if !isPlaying {
                    MeditationPickerView(
                        selectedMeditation: $selectedMeditation,
                        onSelect: { meditation in
                            selectedMeditation = meditation
                            audioPlayer.loadAudio(named: meditation.audioFile)
                            showingMeditationPicker = false
                        }
                    )
                }
                
                // Player Controls
                if selectedMeditation != nil {
                    PlayerControlsView(
                        isPlaying: $isPlaying,
                        currentTime: $currentTime,
                        totalDuration: $totalDuration,
                        onPlayPause: togglePlayPause,
                        onStop: stopMeditation
                    )
                }
                
                // Breathing Guide
                if isPlaying {
                    BreathingGuideView(phase: breathingPhase)
                }
                
                // Progress Circle
                if isPlaying {
                    ProgressCircleView(
                        progress: totalDuration > 0 ? currentTime / totalDuration : 0,
                        currentTime: currentTime,
                        totalDuration: totalDuration
                    )
                }
                
                Spacer()
                
                // Bottom Controls
                HStack(spacing: 40) {
                    Button("Choose Meditation") {
                        showingMeditationPicker = true
                    }
                    .buttonStyle(TVButtonStyle())
                    
                    Button("Exit") {
                        stopMeditation()
                    }
                    .buttonStyle(TVButtonStyle())
                }
            }
            .padding(.horizontal, 60)
            .padding(.vertical, 40)
        }
        .onAppear {
            setupAudioPlayer()
        }
        .onDisappear {
            cleanup()
        }
        .sheet(isPresented: $showingMeditationPicker) {
            MeditationPickerSheet(
                selectedMeditation: $selectedMeditation,
                onSelect: { meditation in
                    selectedMeditation = meditation
                    audioPlayer.loadAudio(named: meditation.audioFile)
                    showingMeditationPicker = false
                }
            )
        }
    }
    
    private func setupAudioPlayer() {
        audioPlayer.onTimeUpdate = { time in
            currentTime = time
        }
        
        audioPlayer.onDurationUpdate = { duration in
            totalDuration = duration
        }
        
        audioPlayer.onPlaybackFinished = {
            stopMeditation()
        }
    }
    
    private func togglePlayPause() {
        if isPlaying {
            audioPlayer.pause()
            stopBreathingTimer()
        } else {
            audioPlayer.play()
            startBreathingTimer()
        }
        isPlaying.toggle()
    }
    
    private func stopMeditation() {
        audioPlayer.stop()
        isPlaying = false
        currentTime = 0
        stopBreathingTimer()
    }
    
    private func startBreathingTimer() {
        breathingTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            updateBreathingPhase()
        }
    }
    
    private func stopBreathingTimer() {
        breathingTimer?.invalidate()
        breathingTimer = nil
    }
    
    private func updateBreathingPhase() {
        let cycleDuration = BreathingPhase.inhale.duration + BreathingPhase.hold.duration + BreathingPhase.exhale.duration
        let cycleTime = currentTime.truncatingRemainder(dividingBy: cycleDuration)
        
        if cycleTime < BreathingPhase.inhale.duration {
            breathingPhase = .inhale
        } else if cycleTime < BreathingPhase.inhale.duration + BreathingPhase.hold.duration {
            breathingPhase = .hold
        } else {
            breathingPhase = .exhale
        }
    }
    
    private func cleanup() {
        stopBreathingTimer()
        audioPlayer.stop()
    }
}

// MARK: - Background View
@available(tvOS 18.0, *)
struct BackgroundView: View {
    @State private var animationPhase: CGFloat = 0
    
    var body: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                colors: [
                    Color.black,
                    Color.purple.opacity(0.3),
                    Color.blue.opacity(0.2),
                    Color.black
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Animated particles
            ForEach(0..<50, id: \.self) { index in
                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: CGFloat.random(in: 2...8))
                    .position(
                        x: CGFloat.random(in: 0...1920),
                        y: CGFloat.random(in: 0...1080)
                    )
                    .scaleEffect(1 + 0.5 * sin(animationPhase + Double(index)))
                    .animation(
                        Animation.easeInOut(duration: 3)
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.1),
                        value: animationPhase
                    )
            }
        }
        .ignoresSafeArea()
        .onAppear {
            animationPhase = 1
        }
    }
}

// MARK: - Meditation Picker View
@available(tvOS 18.0, *)
struct MeditationPickerView: View {
    @Binding var selectedMeditation: Meditation?
    let onSelect: (Meditation) -> Void
    
    let meditations = [
        Meditation(title: "Morning Calm", duration: "10 min", audioFile: "morning_calm", category: "Mindfulness"),
        Meditation(title: "Stress Relief", duration: "15 min", audioFile: "stress_relief", category: "Relaxation"),
        Meditation(title: "Deep Sleep", duration: "20 min", audioFile: "deep_sleep", category: "Sleep"),
        Meditation(title: "Focus & Clarity", duration: "12 min", audioFile: "focus_clarity", category: "Concentration"),
        Meditation(title: "Body Scan", duration: "18 min", audioFile: "body_scan", category: "Mindfulness"),
        Meditation(title: "Loving Kindness", duration: "15 min", audioFile: "loving_kindness", category: "Compassion")
    ]
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Choose Your Meditation")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 30), count: 3), spacing: 30) {
                ForEach(meditations, id: \.id) { meditation in
                    MeditationCard(meditation: meditation) {
                        onSelect(meditation)
                    }
                }
            }
        }
    }
}

// MARK: - Player Controls View
@available(tvOS 18.0, *)
struct PlayerControlsView: View {
    @Binding var isPlaying: Bool
    @Binding var currentTime: TimeInterval
    @Binding var totalDuration: TimeInterval
    let onPlayPause: () -> Void
    let onStop: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            // Progress Bar
            ProgressBarView(
                currentTime: currentTime,
                totalDuration: totalDuration
            )
            
            // Time Display
            HStack {
                Text(formatTime(currentTime))
                    .font(.title2)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text(formatTime(totalDuration))
                    .font(.title2)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            // Control Buttons
            HStack(spacing: 40) {
                Button(action: onStop) {
                    Image(systemName: "stop.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.white)
                }
                .buttonStyle(TVButtonStyle())
                
                Button(action: onPlayPause) {
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.white)
                }
                .buttonStyle(TVButtonStyle())
            }
        }
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Breathing Guide View
@available(tvOS 18.0, *)
struct BreathingGuideView: View {
    let phase: TVMeditationPlayerView.BreathingPhase
    @State private var scale: CGFloat = 1.0
    
    var body: some View {
        VStack(spacing: 20) {
            Text(phase.instruction)
                .font(.title)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .scaleEffect(scale)
                .animation(.easeInOut(duration: phase.duration), value: phase)
            
            // Breathing circle
            Circle()
                .fill(Color.white.opacity(0.2))
                .frame(width: 200, height: 200)
                .scaleEffect(scale)
                .animation(.easeInOut(duration: phase.duration), value: phase)
        }
        .onAppear {
            updateScale()
        }
        .onChange(of: phase) { _ in
            updateScale()
        }
    }
    
    private func updateScale() {
        switch phase {
        case .inhale:
            scale = 1.5
        case .hold:
            scale = 1.5
        case .exhale:
            scale = 1.0
        }
    }
}

// MARK: - Progress Circle View
@available(tvOS 18.0, *)
struct ProgressCircleView: View {
    let progress: Double
    let currentTime: TimeInterval
    let totalDuration: TimeInterval
    
    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(Color.white.opacity(0.2), lineWidth: 8)
                .frame(width: 300, height: 300)
            
            // Progress circle
            Circle()
                .trim(from: 0, to: progress)
                .stroke(Color.white, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .frame(width: 300, height: 300)
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 1), value: progress)
            
            // Center text
            VStack(spacing: 8) {
                Text(formatTime(currentTime))
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("of \(formatTime(totalDuration))")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
            }
        }
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Supporting Views

@available(tvOS 18.0, *)
struct MeditationCard: View {
    let meditation: Meditation
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 16) {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 40))
                    .foregroundColor(.white)
                
                VStack(spacing: 8) {
                    Text(meditation.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    Text(meditation.duration)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                    
                    Text(meditation.category)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.5))
                }
            }
            .frame(width: 250, height: 200)
            .background(Color.white.opacity(0.1))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(CardButtonStyle())
    }
}

@available(tvOS 18.0, *)
struct ProgressBarView: View {
    let currentTime: TimeInterval
    let totalDuration: TimeInterval
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.white.opacity(0.2))
                    .frame(height: 8)
                    .cornerRadius(4)
                
                Rectangle()
                    .fill(Color.white)
                    .frame(
                        width: totalDuration > 0 ? geometry.size.width * (currentTime / totalDuration) : 0,
                        height: 8
                    )
                    .cornerRadius(4)
                    .animation(.linear(duration: 1), value: currentTime)
            }
        }
        .frame(height: 8)
    }
}

@available(tvOS 18.0, *)
struct MeditationPickerSheet: View {
    @Binding var selectedMeditation: Meditation?
    let onSelect: (Meditation) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            MeditationPickerView(selectedMeditation: $selectedMeditation, onSelect: onSelect)
                .navigationTitle("Choose Meditation")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                }
        }
    }
}

@available(tvOS 18.0, *)
struct TVButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Audio Player
@available(tvOS 18.0, *)
class AudioPlayer: ObservableObject {
    private var player: AVAudioPlayer?
    private var timer: Timer?
    
    var onTimeUpdate: ((TimeInterval) -> Void)?
    var onDurationUpdate: ((TimeInterval) -> Void)?
    var onPlaybackFinished: (() -> Void)?
    
    func loadAudio(named filename: String) {
        guard let url = Bundle.main.url(forResource: filename, withExtension: "mp3") else {
            print("Could not find audio file: \(filename)")
            return
        }
        
        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.delegate = self
            player?.prepareToPlay()
            
            onDurationUpdate?(player?.duration ?? 0)
        } catch {
            print("Error loading audio: \(error)")
        }
    }
    
    func play() {
        player?.play()
        startTimer()
    }
    
    func pause() {
        player?.pause()
        stopTimer()
    }
    
    func stop() {
        player?.stop()
        player?.currentTime = 0
        stopTimer()
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            self.onTimeUpdate?(self.player?.currentTime ?? 0)
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}

@available(tvOS 18.0, *)
extension AudioPlayer: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        onPlaybackFinished?()
    }
}

// MARK: - Data Models
struct Meditation: Identifiable {
    let id = UUID()
    let title: String
    let duration: String
    let audioFile: String
    let category: String
}

// MARK: - Preview
#Preview {
    TVMeditationPlayerView()
} 
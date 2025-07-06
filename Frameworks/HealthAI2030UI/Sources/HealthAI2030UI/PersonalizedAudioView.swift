import SwiftUI
import AVFoundation

struct PersonalizedAudioView: View {
    let contentType: PersonalizedAudioType
    @State private var isGenerating = false
    @State private var progress: Double = 0.0
    @State private var audioURL: URL?
    @State private var showPlayer = false
    // Example user profiles (in production, fetch from user settings)
    let voiceProfile = VoiceProfile(languageCode: "en-US", voiceIdentifier: nil, gender: "female", style: "calm")
    let psychProfile = PsychologicalProfile(meditationFocus: "relaxation and stress relief", sleepStoryTheme: "a peaceful forest journey", motivationTheme: "overcoming challenges", affirmation: "You are enough.")
    var body: some View {
        VStack(spacing: 24) {
            Text("Personalized \(contentTypeTitle)")
                .font(.title)
                .fontWeight(.bold)
            if isGenerating {
                ProgressView(value: progress)
                    .progressViewStyle(LinearProgressViewStyle())
                Text("Generating audio...")
            } else if let url = audioURL {
                Button("Play Audio") {
                    showPlayer = true
                }
                .sheet(isPresented: $showPlayer) {
                    AudioPlaybackView(audioURL: url)
                }
            } else {
                Button("Generate Personalized Audio") {
                    isGenerating = true
                    AudioGenerationEngine.shared.generatePersonalizedAudio(contentType: contentType, duration: 180, voiceProfile: voiceProfile, psychologicalProfile: psychProfile) { url in
                        DispatchQueue.main.async {
                            self.audioURL = url
                            self.isGenerating = false
                        }
                    }
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .navigationTitle("Personalized Audio")
    }
    private var contentTypeTitle: String {
        switch contentType {
        case .meditation: return "Meditation"
        case .sleepStory: return "Sleep Story"
        case .motivation: return "Motivation"
        }
    }
}

struct AudioPlaybackView: View {
    let audioURL: URL
    @State private var player: AVAudioPlayer?
    @State private var isPlaying = false
    var body: some View {
        VStack(spacing: 16) {
            Button(action: togglePlayback) {
                Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.blue)
            }
            Text(isPlaying ? "Playing..." : "Paused")
        }
        .onAppear {
            player = try? AVAudioPlayer(contentsOf: audioURL)
        }
    }
    private func togglePlayback() {
        guard let player = player else { return }
        if isPlaying {
            player.pause()
        } else {
            player.play()
        }
        isPlaying.toggle()
    }
}

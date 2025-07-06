import SwiftUI
import AVFoundation

struct PremiumAudioPlayer: View {
    let audioFile: String
    @State private var player: AVAudioPlayer?
    @State private var isPlaying = false
    
    var body: some View {
        HStack {
            Button(action: togglePlayback) {
                Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 36))
                    .foregroundColor(.blue)
            }
            Text(isPlaying ? "Playing premium audio..." : "Play premium audio")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .onAppear {
            if let url = Bundle.main.url(forResource: audioFile, withExtension: nil) {
                player = try? AVAudioPlayer(contentsOf: url)
            }
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

import SwiftUI
import AVKit

struct VideoPlayerView: View {
    let videoName: String
    var body: some View {
        if let url = Bundle.main.url(forResource: videoName, withExtension: nil) {
            VideoPlayer(player: AVPlayer(url: url))
                .onAppear { AVPlayer(url: url).play() }
        } else {
            Text("Video not available")
                .foregroundColor(.secondary)
        }
    }
}

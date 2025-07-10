import SwiftUI
import AVKit

// MARK: - Health Education Videos
/// Comprehensive health education video system for enhanced learning
/// Provides interactive video content for health education and awareness
public struct HealthEducationVideos {
    
    // MARK: - Video Player Component
    
    /// Custom video player with health education features
    public struct HealthVideoPlayer: View {
        let videoURL: URL
        let title: String
        let description: String
        let category: VideoCategory
        @State private var player: AVPlayer?
        @State private var isPlaying: Bool = false
        @State private var currentTime: Double = 0
        @State private var duration: Double = 0
        @State private var showControls: Bool = true
        @State private var isFullscreen: Bool = false
        
        public init(
            videoURL: URL,
            title: String,
            description: String,
            category: VideoCategory
        ) {
            self.videoURL = videoURL
            self.title = title
            self.description = description
            self.category = category
        }
        
        public var body: some View {
            VStack(spacing: 0) {
                // Video player
                ZStack {
                    if let player = player {
                        VideoPlayer(player: player)
                            .aspectRatio(16/9, contentMode: .fit)
                            .cornerRadius(isFullscreen ? 0 : 12)
                            .onTapGesture {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    showControls.toggle()
                                }
                            }
                    } else {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray6))
                            .aspectRatio(16/9, contentMode: .fit)
                            .overlay(
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                            )
                    }
                    
                    // Custom controls overlay
                    if showControls && !isFullscreen {
                        VStack {
                            HStack {
                                Button(action: {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        isFullscreen.toggle()
                                    }
                                }) {
                                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                                        .font(.system(size: 20, weight: .medium))
                                        .foregroundColor(.white)
                                        .padding(8)
                                        .background(Color.black.opacity(0.6))
                                        .clipShape(Circle())
                                }
                                
                                Spacer()
                                
                                Button(action: {
                                    togglePlayback()
                                }) {
                                    Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                        .font(.system(size: 40, weight: .medium))
                                        .foregroundColor(.white)
                                        .background(Color.black.opacity(0.6))
                                        .clipShape(Circle())
                                }
                            }
                            .padding()
                            
                            Spacer()
                            
                            // Progress bar
                            VStack(spacing: 8) {
                                ProgressView(value: currentTime, total: duration)
                                    .progressViewStyle(LinearProgressViewStyle(tint: .white))
                                    .background(Color.black.opacity(0.3))
                                    .cornerRadius(4)
                                
                                HStack {
                                    Text(formatTime(currentTime))
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.white)
                                    
                                    Spacer()
                                    
                                    Text(formatTime(duration))
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.white)
                                }
                            }
                            .padding()
                        }
                    }
                }
                
                if !isFullscreen {
                    // Video info
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text(title)
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Text(category.rawValue)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(category.color)
                                .cornerRadius(8)
                        }
                        
                        Text(description)
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(.secondary)
                            .lineLimit(3)
                        
                        // Video metadata
                        HStack {
                            Label("\(Int(duration/60)) min", systemImage: "clock")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Label("HD", systemImage: "video")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                }
            }
            .onAppear {
                setupPlayer()
            }
            .onDisappear {
                player?.pause()
                player = nil
            }
        }
        
        private func setupPlayer() {
            player = AVPlayer(url: videoURL)
            
            // Add time observer
            let interval = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
            player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { time in
                currentTime = time.seconds
            }
            
            // Get duration
            player?.currentItem?.asset.loadValuesAsynchronously(forKeys: ["duration"]) {
                DispatchQueue.main.async {
                    duration = player?.currentItem?.asset.duration.seconds ?? 0
                }
            }
        }
        
        private func togglePlayback() {
            if isPlaying {
                player?.pause()
            } else {
                player?.play()
            }
            isPlaying.toggle()
        }
        
        private func formatTime(_ time: Double) -> String {
            let minutes = Int(time) / 60
            let seconds = Int(time) % 60
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
    
    // MARK: - Video Library Component
    
    /// Video library with categorized health education content
    public struct VideoLibrary: View {
        let videos: [HealthVideo]
        @State private var selectedCategory: VideoCategory?
        @State private var searchText: String = ""
        @State private var selectedVideo: HealthVideo?
        
        public init(videos: [HealthVideo]) {
            self.videos = videos
        }
        
        public var body: some View {
            NavigationView {
                VStack(spacing: 0) {
                    // Search bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        
                        TextField("Search videos...", text: $searchText)
                            .textFieldStyle(PlainTextFieldStyle())
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding()
                    
                    // Category filter
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(VideoCategory.allCases, id: \.self) { category in
                                Button(action: {
                                    selectedCategory = selectedCategory == category ? nil : category
                                }) {
                                    Text(category.rawValue)
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(selectedCategory == category ? .white : .primary)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(selectedCategory == category ? category.color : Color(.systemGray5))
                                        .cornerRadius(20)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Video grid
                    ScrollView {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                            ForEach(filteredVideos) { video in
                                VideoCard(video: video) {
                                    selectedVideo = video
                                }
                            }
                        }
                        .padding()
                    }
                }
                .navigationTitle("Health Education")
                .sheet(item: $selectedVideo) { video in
                    HealthVideoPlayer(
                        videoURL: video.url,
                        title: video.title,
                        description: video.description,
                        category: video.category
                    )
                }
            }
        }
        
        private var filteredVideos: [HealthVideo] {
            var filtered = videos
            
            if let category = selectedCategory {
                filtered = filtered.filter { $0.category == category }
            }
            
            if !searchText.isEmpty {
                filtered = filtered.filter { video in
                    video.title.localizedCaseInsensitiveContains(searchText) ||
                    video.description.localizedCaseInsensitiveContains(searchText)
                }
            }
            
            return filtered
        }
    }
    
    // MARK: - Video Card Component
    
    /// Video card for library display
    public struct VideoCard: View {
        let video: HealthVideo
        let onTap: () -> Void
        @State private var thumbnailImage: UIImage?
        
        public init(video: HealthVideo, onTap: @escaping () -> Void) {
            self.video = video
            self.onTap = onTap
        }
        
        public var body: some View {
            Button(action: onTap) {
                VStack(alignment: .leading, spacing: 8) {
                    // Thumbnail
                    ZStack {
                        if let thumbnail = thumbnailImage {
                            Image(uiImage: thumbnail)
                                .resizable()
                                .aspectRatio(16/9, contentMode: .fill)
                                .clipped()
                        } else {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(.systemGray6))
                                .aspectRatio(16/9, contentMode: .fit)
                                .overlay(
                                    Image(systemName: "play.circle.fill")
                                        .font(.system(size: 32, weight: .medium))
                                        .foregroundColor(.white)
                                )
                        }
                        
                        // Duration badge
                        VStack {
                            HStack {
                                Spacer()
                                
                                Text(formatDuration(video.duration))
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.black.opacity(0.7))
                                    .cornerRadius(4)
                            }
                            
                            Spacer()
                        }
                        .padding(8)
                    }
                    .cornerRadius(8)
                    
                    // Video info
                    VStack(alignment: .leading, spacing: 4) {
                        Text(video.title)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.primary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                        
                        Text(video.description)
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                        
                        HStack {
                            Text(video.category.rawValue)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(video.category.color)
                                .cornerRadius(4)
                            
                            Spacer()
                            
                            Text("\(video.views) views")
                                .font(.system(size: 10, weight: .regular))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(8)
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
            }
            .buttonStyle(PlainButtonStyle())
            .onAppear {
                loadThumbnail()
            }
        }
        
        private func loadThumbnail() {
            // Simulate thumbnail loading
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                // In a real implementation, this would load the actual video thumbnail
                thumbnailImage = UIImage(systemName: "video.fill")
            }
        }
        
        private func formatDuration(_ duration: TimeInterval) -> String {
            let minutes = Int(duration) / 60
            let seconds = Int(duration) % 60
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
    
    // MARK: - Video Playlist Component
    
    /// Video playlist for sequential learning
    public struct VideoPlaylist: View {
        let playlist: VideoPlaylistData
        @State private var currentVideoIndex: Int = 0
        @State private var completedVideos: Set<String> = []
        
        public init(playlist: VideoPlaylistData) {
            self.playlist = playlist
        }
        
        public var body: some View {
            VStack(spacing: 0) {
                // Current video player
                if !playlist.videos.isEmpty {
                    HealthVideoPlayer(
                        videoURL: playlist.videos[currentVideoIndex].url,
                        title: playlist.videos[currentVideoIndex].title,
                        description: playlist.videos[currentVideoIndex].description,
                        category: playlist.videos[currentVideoIndex].category
                    )
                }
                
                // Playlist
                VStack(alignment: .leading, spacing: 16) {
                    Text("Playlist: \(playlist.title)")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.primary)
                        .padding(.horizontal)
                    
                    Text("\(completedVideos.count) of \(playlist.videos.count) completed")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                    
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(Array(playlist.videos.enumerated()), id: \.element.id) { index, video in
                                PlaylistItemView(
                                    video: video,
                                    isCurrent: index == currentVideoIndex,
                                    isCompleted: completedVideos.contains(video.id),
                                    onTap: {
                                        currentVideoIndex = index
                                    }
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
        }
    }
    
    // MARK: - Playlist Item Component
    
    /// Individual playlist item
    public struct PlaylistItemView: View {
        let video: HealthVideo
        let isCurrent: Bool
        let isCompleted: Bool
        let onTap: () -> Void
        
        public var body: some View {
            Button(action: onTap) {
                HStack(spacing: 12) {
                    // Play/pause indicator
                    ZStack {
                        Circle()
                            .fill(isCurrent ? Color.blue : Color(.systemGray4))
                            .frame(width: 32, height: 32)
                        
                        if isCompleted {
                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                        } else if isCurrent {
                            Image(systemName: "play.fill")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                        } else {
                            Text("\(video.number)")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.white)
                        }
                    }
                    
                    // Video info
                    VStack(alignment: .leading, spacing: 4) {
                        Text(video.title)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(isCurrent ? .blue : .primary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                        
                        Text(formatDuration(video.duration))
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                .padding(12)
                .background(isCurrent ? Color.blue.opacity(0.1) : Color(.systemBackground))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isCurrent ? Color.blue : Color.clear, lineWidth: 2)
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
        
        private func formatDuration(_ duration: TimeInterval) -> String {
            let minutes = Int(duration) / 60
            let seconds = Int(duration) % 60
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
}

// MARK: - Supporting Types

enum VideoCategory: String, CaseIterable {
    case nutrition = "Nutrition"
    case exercise = "Exercise"
    case mentalHealth = "Mental Health"
    case chronicDisease = "Chronic Disease"
    case preventiveCare = "Preventive Care"
    case medication = "Medication"
    case emergency = "Emergency"
    case wellness = "Wellness"
    
    var color: Color {
        switch self {
        case .nutrition: return .green
        case .exercise: return .orange
        case .mentalHealth: return .purple
        case .chronicDisease: return .red
        case .preventiveCare: return .blue
        case .medication: return .yellow
        case .emergency: return .red
        case .wellness: return .mint
        }
    }
}

struct HealthVideo: Identifiable {
    let id: String
    let title: String
    let description: String
    let url: URL
    let category: VideoCategory
    let duration: TimeInterval
    let views: Int
    let number: Int
    
    init(id: String, title: String, description: String, url: URL, category: VideoCategory, duration: TimeInterval, views: Int = 0, number: Int = 0) {
        self.id = id
        self.title = title
        self.description = description
        self.url = url
        self.category = category
        self.duration = duration
        self.views = views
        self.number = number
    }
}

struct VideoPlaylistData {
    let id: String
    let title: String
    let description: String
    let videos: [HealthVideo]
    
    init(id: String, title: String, description: String, videos: [HealthVideo]) {
        self.id = id
        self.title = title
        self.description = description
        self.videos = videos.enumerated().map { index, video in
            HealthVideo(
                id: video.id,
                title: video.title,
                description: video.description,
                url: video.url,
                category: video.category,
                duration: video.duration,
                views: video.views,
                number: index + 1
            )
        }
    }
}

// MARK: - Preview

struct HealthEducationVideos_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            HealthVideoPlayer(
                videoURL: URL(string: "https://example.com/video.mp4")!,
                title: "Healthy Eating Basics",
                description: "Learn the fundamentals of healthy eating and nutrition",
                category: .nutrition
            )
            
            VideoLibrary(videos: [
                HealthVideo(
                    id: "1",
                    title: "Healthy Eating Basics",
                    description: "Learn the fundamentals of healthy eating and nutrition",
                    url: URL(string: "https://example.com/video1.mp4")!,
                    category: .nutrition,
                    duration: 300,
                    views: 1500
                ),
                HealthVideo(
                    id: "2",
                    title: "Cardio Exercise Guide",
                    description: "Complete guide to cardiovascular exercises",
                    url: URL(string: "https://example.com/video2.mp4")!,
                    category: .exercise,
                    duration: 450,
                    views: 2200
                )
            ])
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
} 
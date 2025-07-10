import SwiftUI
import AVKit

// MARK: - Patient Education Videos
/// Comprehensive patient education video system for enhanced learning
/// Provides educational content specifically designed for patients and caregivers
public struct PatientEducationVideos {
    
    // MARK: - Patient Video Library Component
    
    /// Library of patient education videos
    public struct PatientVideoLibrary: View {
        let videos: [PatientVideo]
        @State private var selectedCategory: PatientVideoCategory?
        @State private var searchText: String = ""
        @State private var selectedVideo: PatientVideo?
        @State private var userProgress: [String: VideoProgress] = [:]
        
        public init(videos: [PatientVideo]) {
            self.videos = videos
        }
        
        public var body: some View {
            NavigationView {
                VStack(spacing: 0) {
                    // Header
                    VStack(spacing: 12) {
                        Text("Patient Education")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.primary)
                        
                        Text("Learn about your health and treatment options")
                            .font(.system(size: 16, weight: .regular))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    
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
                    .padding(.horizontal)
                    
                    // Category filter
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(PatientVideoCategory.allCases, id: \.self) { category in
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
                                PatientVideoCard(
                                    video: video,
                                    progress: userProgress[video.id],
                                    onTap: {
                                        selectedVideo = video
                                    }
                                )
                            }
                        }
                        .padding()
                    }
                }
                .navigationBarHidden(true)
                .sheet(item: $selectedVideo) { video in
                    PatientVideoPlayer(
                        video: video,
                        progress: userProgress[video.id] ?? VideoProgress(),
                        onProgressUpdate: { progress in
                            userProgress[video.id] = progress
                        }
                    )
                }
            }
        }
        
        private var filteredVideos: [PatientVideo] {
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
    
    // MARK: - Patient Video Player Component
    
    /// Video player specifically designed for patient education
    public struct PatientVideoPlayer: View {
        let video: PatientVideo
        let progress: VideoProgress
        let onProgressUpdate: (VideoProgress) -> Void
        @State private var player: AVPlayer?
        @State private var isPlaying: Bool = false
        @State private var currentTime: Double = 0
        @State private var duration: Double = 0
        @State private var showNotes: Bool = false
        @State private var userNotes: String = ""
        @State private var showQuiz: Bool = false
        @Environment(\.presentationMode) var presentationMode
        
        public var body: some View {
            NavigationView {
                VStack(spacing: 0) {
                    // Video player
                    ZStack {
                        if let player = player {
                            VideoPlayer(player: player)
                                .aspectRatio(16/9, contentMode: .fit)
                                .cornerRadius(12)
                        } else {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemGray6))
                                .aspectRatio(16/9, contentMode: .fit)
                                .overlay(
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                                )
                        }
                        
                        // Play/pause overlay
                        if !isPlaying {
                            Button(action: {
                                if isPlaying {
                                    player?.pause()
                                } else {
                                    player?.play()
                                }
                                isPlaying.toggle()
                            }) {
                                Image(systemName: "play.circle.fill")
                                    .font(.system(size: 60, weight: .medium))
                                    .foregroundColor(.white)
                                    .background(Color.black.opacity(0.5))
                                    .clipShape(Circle())
                            }
                        }
                    }
                    .padding()
                    
                    // Video controls
                    VStack(spacing: 16) {
                        // Progress bar
                        VStack(spacing: 8) {
                            ProgressView(value: currentTime, total: duration)
                                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                            
                            HStack {
                                Text(formatTime(currentTime))
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                Text(formatTime(duration))
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        // Control buttons
                        HStack(spacing: 20) {
                            Button(action: {
                                player?.seek(to: CMTime(seconds: max(0, currentTime - 10), preferredTimescale: 1))
                            }) {
                                Image(systemName: "gobackward.10")
                                    .font(.system(size: 20, weight: .medium))
                                    .foregroundColor(.blue)
                            }
                            
                            Button(action: {
                                if isPlaying {
                                    player?.pause()
                                } else {
                                    player?.play()
                                }
                                isPlaying.toggle()
                            }) {
                                Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                    .font(.system(size: 32, weight: .medium))
                                    .foregroundColor(.blue)
                            }
                            
                            Button(action: {
                                player?.seek(to: CMTime(seconds: min(duration, currentTime + 10), preferredTimescale: 1))
                            }) {
                                Image(systemName: "goforward.10")
                                    .font(.system(size: 20, weight: .medium))
                                    .foregroundColor(.blue)
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                showNotes.toggle()
                            }) {
                                Image(systemName: "note.text")
                                    .font(.system(size: 20, weight: .medium))
                                    .foregroundColor(showNotes ? .blue : .secondary)
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Video information
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            // Video details
                            VStack(alignment: .leading, spacing: 8) {
                                Text(video.title)
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.primary)
                                
                                Text(video.description)
                                    .font(.system(size: 16, weight: .regular))
                                    .foregroundColor(.secondary)
                                
                                HStack {
                                    Text(video.category.rawValue)
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(video.category.color)
                                        .cornerRadius(8)
                                    
                                    Spacer()
                                    
                                    Text("\(Int(duration/60)) min")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            // Key points
                            if !video.keyPoints.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Key Points")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.primary)
                                    
                                    ForEach(video.keyPoints, id: \.self) { point in
                                        HStack(alignment: .top, spacing: 8) {
                                            Image(systemName: "checkmark.circle.fill")
                                                .font(.system(size: 12, weight: .medium))
                                                .foregroundColor(.green)
                                                .padding(.top, 2)
                                            
                                            Text(point)
                                                .font(.system(size: 14, weight: .regular))
                                                .foregroundColor(.primary)
                                        }
                                    }
                                }
                            }
                            
                            // Notes section
                            if showNotes {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Your Notes")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.primary)
                                    
                                    TextEditor(text: $userNotes)
                                        .font(.system(size: 14, weight: .regular))
                                        .frame(minHeight: 100)
                                        .padding(8)
                                        .background(Color(.systemGray6))
                                        .cornerRadius(8)
                                        .onChange(of: userNotes) { _ in
                                            saveNotes()
                                        }
                                }
                            }
                            
                            // Action buttons
                            VStack(spacing: 12) {
                                if progress.watchedPercentage >= 90 {
                                    Button(action: {
                                        showQuiz = true
                                    }) {
                                        HStack {
                                            Image(systemName: "questionmark.circle.fill")
                                            Text("Take Understanding Quiz")
                                        }
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(video.category.color)
                                        .cornerRadius(12)
                                    }
                                }
                                
                                Button(action: {
                                    presentationMode.wrappedValue.dismiss()
                                }) {
                                    Text("Back to Library")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.secondary)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color(.systemGray5))
                                        .cornerRadius(12)
                                }
                            }
                        }
                        .padding()
                    }
                }
                .navigationBarHidden(true)
                .sheet(isPresented: $showQuiz) {
                    PatientVideoQuiz(
                        quiz: video.quiz,
                        onComplete: { score in
                            showQuiz = false
                            // Handle quiz completion
                        }
                    )
                }
                .onAppear {
                    setupPlayer()
                    loadNotes()
                }
                .onDisappear {
                    player?.pause()
                    player = nil
                }
            }
        }
        
        private func setupPlayer() {
            player = AVPlayer(url: video.videoURL)
            
            // Add time observer
            let interval = CMTime(seconds: 1.0, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
            player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { time in
                currentTime = time.seconds
                updateProgress()
            }
            
            // Get duration
            player?.currentItem?.asset.loadValuesAsynchronously(forKeys: ["duration"]) {
                DispatchQueue.main.async {
                    duration = player?.currentItem?.asset.duration.seconds ?? 0
                }
            }
        }
        
        private func updateProgress() {
            var updatedProgress = progress
            updatedProgress.watchedPercentage = (currentTime / duration) * 100
            updatedProgress.lastWatchedTime = currentTime
            
            if updatedProgress.watchedPercentage >= 90 && !updatedProgress.isCompleted {
                updatedProgress.isCompleted = true
            }
            
            onProgressUpdate(updatedProgress)
        }
        
        private func formatTime(_ time: Double) -> String {
            let minutes = Int(time) / 60
            let seconds = Int(time) % 60
            return String(format: "%d:%02d", minutes, seconds)
        }
        
        private func saveNotes() {
            var updatedProgress = progress
            updatedProgress.notes = userNotes
            onProgressUpdate(updatedProgress)
        }
        
        private func loadNotes() {
            userNotes = progress.notes
        }
    }
    
    // MARK: - Patient Video Card Component
    
    /// Card for patient video display
    public struct PatientVideoCard: View {
        let video: PatientVideo
        let progress: VideoProgress?
        let onTap: () -> Void
        
        public var body: some View {
            Button(action: onTap) {
                VStack(alignment: .leading, spacing: 12) {
                    // Thumbnail
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(video.category.color.opacity(0.2))
                            .aspectRatio(16/9, contentMode: .fit)
                        
                        Image(systemName: video.icon)
                            .font(.system(size: 32, weight: .medium))
                            .foregroundColor(video.category.color)
                        
                        // Progress indicator
                        if let progress = progress, progress.watchedPercentage > 0 {
                            VStack {
                                HStack {
                                    Spacer()
                                    
                                    Text("\(Int(progress.watchedPercentage))%")
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
                    }
                    
                    // Video info
                    VStack(alignment: .leading, spacing: 8) {
                        Text(video.title)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                        
                        Text(video.description)
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(.secondary)
                            .lineLimit(3)
                            .multilineTextAlignment(.leading)
                        
                        HStack {
                            Text(video.category.rawValue)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(video.category.color)
                                .cornerRadius(8)
                            
                            Spacer()
                            
                            if let progress = progress, progress.isCompleted {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.green)
                            }
                        }
                    }
                }
                .padding(12)
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    // MARK: - Patient Video Quiz Component
    
    /// Quiz for patient video understanding
    public struct PatientVideoQuiz: View {
        let quiz: PatientVideoQuiz
        let onComplete: (Int) -> Void
        @State private var currentQuestion: Int = 0
        @State private var selectedAnswers: [Int: Int] = [:]
        @State private var showResults: Bool = false
        @Environment(\.presentationMode) var presentationMode
        
        public var body: some View {
            NavigationView {
                VStack(spacing: 20) {
                    if !showResults {
                        // Quiz questions
                        VStack(spacing: 16) {
                            Text("Understanding Quiz")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.primary)
                            
                            Text("Question \(currentQuestion + 1) of \(quiz.questions.count)")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.secondary)
                            
                            Text(quiz.questions[currentQuestion].question)
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.primary)
                                .multilineTextAlignment(.center)
                            
                            VStack(spacing: 8) {
                                ForEach(Array(quiz.questions[currentQuestion].options.enumerated()), id: \.offset) { index, option in
                                    Button(action: {
                                        selectedAnswers[currentQuestion] = index
                                    }) {
                                        HStack {
                                            Text(option)
                                                .font(.system(size: 16, weight: .medium))
                                                .foregroundColor(.primary)
                                                .multilineTextAlignment(.leading)
                                            
                                            Spacer()
                                            
                                            if selectedAnswers[currentQuestion] == index {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .font(.system(size: 18, weight: .medium))
                                                    .foregroundColor(.blue)
                                            }
                                        }
                                        .padding(16)
                                        .background(selectedAnswers[currentQuestion] == index ? Color.blue.opacity(0.1) : Color(.systemGray6))
                                        .cornerRadius(12)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            
                            HStack {
                                if currentQuestion > 0 {
                                    Button("Previous") {
                                        currentQuestion -= 1
                                    }
                                    .buttonStyle(.bordered)
                                }
                                
                                Spacer()
                                
                                if currentQuestion < quiz.questions.count - 1 {
                                    Button("Next") {
                                        currentQuestion += 1
                                    }
                                    .buttonStyle(.bordered)
                                } else {
                                    Button("Submit Quiz") {
                                        showResults = true
                                    }
                                    .buttonStyle(.borderedProminent)
                                }
                            }
                        }
                        .padding()
                    } else {
                        // Quiz results
                        VStack(spacing: 20) {
                            Text("Quiz Results")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.primary)
                            
                            let score = calculateScore()
                            let percentage = Double(score) / Double(quiz.questions.count) * 100
                            
                            VStack(spacing: 8) {
                                Text("\(score)/\(quiz.questions.count) Correct")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(.primary)
                                
                                Text("\(Int(percentage))%")
                                    .font(.system(size: 36, weight: .bold))
                                    .foregroundColor(percentage >= 80 ? .green : .orange)
                            }
                            
                            Text(percentage >= 80 ? "Excellent! You have a good understanding of this topic." : "Good effort! Consider reviewing the video again.")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                            
                            Button("Complete") {
                                onComplete(score)
                                presentationMode.wrappedValue.dismiss()
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .padding()
                    }
                }
                .navigationBarHidden(true)
            }
        }
        
        private func calculateScore() -> Int {
            var score = 0
            for (questionIndex, selectedAnswer) in selectedAnswers {
                if selectedAnswer == quiz.questions[questionIndex].correctAnswer {
                    score += 1
                }
            }
            return score
        }
    }
    
    // MARK: - Recommended Videos Component
    
    /// Component for showing recommended videos
    public struct RecommendedVideos: View {
        let videos: [PatientVideo]
        let currentVideo: PatientVideo
        let onVideoSelect: (PatientVideo) -> Void
        
        public var body: some View {
            VStack(alignment: .leading, spacing: 16) {
                Text("Recommended Videos")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.primary)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(recommendedVideos) { video in
                            RecommendedVideoCard(
                                video: video,
                                onTap: {
                                    onVideoSelect(video)
                                }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        
        private var recommendedVideos: [PatientVideo] {
            return videos.filter { $0.id != currentVideo.id && $0.category == currentVideo.category }.prefix(5).map { $0 }
        }
    }
    
    // MARK: - Recommended Video Card Component
    
    /// Card for recommended video display
    public struct RecommendedVideoCard: View {
        let video: PatientVideo
        let onTap: () -> Void
        
        public var body: some View {
            Button(action: onTap) {
                VStack(alignment: .leading, spacing: 8) {
                    // Thumbnail
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(video.category.color.opacity(0.2))
                            .frame(width: 120, height: 80)
                        
                        Image(systemName: video.icon)
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(video.category.color)
                    }
                    
                    // Video info
                    VStack(alignment: .leading, spacing: 4) {
                        Text(video.title)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.primary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                        
                        Text(video.category.rawValue)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(video.category.color)
                            .cornerRadius(4)
                    }
                }
                .frame(width: 120)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
}

// MARK: - Supporting Types

struct PatientVideo: Identifiable {
    let id: String
    let title: String
    let description: String
    let icon: String
    let category: PatientVideoCategory
    let videoURL: URL
    let keyPoints: [String]
    let quiz: PatientVideoQuiz
    
    init(id: String, title: String, description: String, icon: String, category: PatientVideoCategory, videoURL: URL, keyPoints: [String] = [], quiz: PatientVideoQuiz) {
        self.id = id
        self.title = title
        self.description = description
        self.icon = icon
        self.category = category
        self.videoURL = videoURL
        self.keyPoints = keyPoints
        self.quiz = quiz
    }
}

struct PatientVideoQuiz {
    let title: String
    let questions: [PatientVideoQuestion]
    
    init(title: String, questions: [PatientVideoQuestion]) {
        self.title = title
        self.questions = questions
    }
}

struct PatientVideoQuestion {
    let question: String
    let options: [String]
    let correctAnswer: Int
    
    init(question: String, options: [String], correctAnswer: Int) {
        self.question = question
        self.options = options
        self.correctAnswer = correctAnswer
    }
}

enum PatientVideoCategory: String, CaseIterable {
    case medication = "Medication"
    case procedures = "Procedures"
    case conditions = "Conditions"
    case lifestyle = "Lifestyle"
    case prevention = "Prevention"
    case recovery = "Recovery"
    
    var color: Color {
        switch self {
        case .medication: return .blue
        case .procedures: return .purple
        case .conditions: return .red
        case .lifestyle: return .green
        case .prevention: return .orange
        case .recovery: return .mint
        }
    }
}

struct VideoProgress {
    var watchedPercentage: Double = 0.0
    var lastWatchedTime: Double = 0.0
    var isCompleted: Bool = false
    var notes: String = ""
    
    init(watchedPercentage: Double = 0.0, lastWatchedTime: Double = 0.0, isCompleted: Bool = false, notes: String = "") {
        self.watchedPercentage = watchedPercentage
        self.lastWatchedTime = lastWatchedTime
        self.isCompleted = isCompleted
        self.notes = notes
    }
}

// MARK: - Preview

struct PatientEducationVideos_Previews: PreviewProvider {
    static var previews: some View {
        PatientVideoLibrary(videos: [
            PatientVideo(
                id: "1",
                title: "Understanding Your Medication",
                description: "Learn about your prescribed medications and how to take them safely",
                icon: "pills.fill",
                category: .medication,
                videoURL: URL(string: "https://example.com/video1.mp4")!,
                keyPoints: [
                    "Always take medication as prescribed",
                    "Store medications properly",
                    "Be aware of potential side effects"
                ],
                quiz: PatientVideoQuiz(
                    title: "Medication Safety Quiz",
                    questions: [
                        PatientVideoQuestion(
                            question: "What should you do if you miss a dose?",
                            options: ["Take double the next dose", "Skip it and continue normally", "Contact your healthcare provider", "Take it immediately"],
                            correctAnswer: 2
                        )
                    ]
                )
            )
        ])
        .previewLayout(.sizeThatFits)
    }
} 
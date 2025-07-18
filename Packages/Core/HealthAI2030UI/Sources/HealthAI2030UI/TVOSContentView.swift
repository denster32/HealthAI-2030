import SwiftUI
import AVKit

struct TVOSContentView: View {
    @ObservedObject var familyManager = FamilyHealthManager.shared
    @ObservedObject var groupSession = GroupWorkoutManager.shared
    @ObservedObject var ambient = AmbientHealthVisualizer.shared
    @ObservedObject var liveData = LiveHealthDataVisualizer.shared
    @State private var selectedTab: Int = 0
    @State private var voiceCommand: String = ""
    @State private var showConfetti: Bool = false
    
    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [.black, .blue.opacity(0.3), .purple.opacity(0.2)]), startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
            TabView(selection: $selectedTab) {
                // 1. Family Health Dashboard
                NavigationView {
                    VStack {
                        Text("Family Health Dashboard")
                            .font(.largeTitle).bold().padding(.top, 32)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 40) {
                                ForEach(familyManager.familyMembers) { member in
                                    VStack {
                                        AvatarView(avatarName: member.avatarName)
                                            .frame(width: 120, height: 120)
                                            .shadow(radius: 10)
                                        Text(member.name).font(.title2)
                                        Text("Sleep: \(member.sleepHours, specifier: "%.1f")h")
                                        Text("Steps: \(member.steps)")
                                        Text("Mood: \(member.mood)")
                                    }
                                    .padding()
                                    .background(RoundedRectangle(cornerRadius: 24).fill(Color.blue.opacity(0.15)))
                                    .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.white.opacity(0.2), lineWidth: 2))
                                    .animation(.spring(), value: member.id)
                                }
                            }
                        }
                        .padding(.vertical)
                        Button("Start Family Health Night") {
                            familyManager.startFamilyHealthNight()
                            withAnimation { showConfetti = true }
                        }
                        .buttonStyle(.borderedProminent)
                        .padding(.top, 16)
                    }
                }
                .tabItem { Label("Family", systemImage: "person.3.fill") }.tag(0)
                
                // 2. Group Workouts & Meditations
                NavigationView {
                    VStack {
                        Text("Group Workouts & Meditations")
                            .font(.largeTitle).bold().padding(.top, 32)
                        if groupSession.isActive {
                            Text("Session: \(groupSession.currentSession?.title ?? "")")
                                .font(.title2)
                                .padding(.bottom, 8)
                            SmoothProgressBar(progress: groupSession.progress)
                                .frame(height: 24)
                                .padding(.horizontal, 80)
                                .animation(.easeInOut, value: groupSession.progress)
                            Button("End Session") { groupSession.endSession() }
                                .buttonStyle(.bordered)
                                .padding(.top, 16)
                        } else {
                            ForEach(groupSession.availableSessions) { session in
                                Button(session.title) {
                                    groupSession.startSession(session)
                                }
                                .buttonStyle(.borderedProminent)
                                .padding(8)
                                .background(RoundedRectangle(cornerRadius: 16).fill(Color.green.opacity(0.2)))
                                .animation(.spring(), value: session.id)
                            }
                        }
                    }
                }
                .tabItem { Label("Group", systemImage: "figure.walk.circle.fill") }.tag(1)
                
                // 3. Ambient Health Visualizations
                NavigationView {
                    VStack {
                        Text("Ambient Health Visualizations")
                            .font(.largeTitle).bold().padding(.top, 32)
                        ambient.ambientView
                            .transition(.scale)
                        Button("Set as Screensaver") { ambient.setAsScreensaver() }
                            .buttonStyle(.bordered)
                            .padding(.top, 16)
                    }
                }
                .tabItem { Label("Ambient", systemImage: "waveform.path.ecg.rectangle") }.tag(2)
                
                // 6. Live Health Data Visualizer
                NavigationView {
                    VStack {
                        Text("Live Health Data Visualizer")
                            .font(.largeTitle).bold().padding(.top, 32)
                        liveData.visualizerView
                            .transition(.opacity)
                        Button("Replay My Day") { liveData.replayDay() }
                            .buttonStyle(.borderedProminent)
                            .padding(.top, 16)
                    }
                }
                .tabItem { Label("Live Data", systemImage: "chart.bar.xaxis") }.tag(3)
                
                // 7. Voice-Driven Health Assistant
                NavigationView {
                    VStack {
                        Text("Voice Health Assistant")
                            .font(.largeTitle).bold().padding(.top, 32)
                        TextField("Ask a health question...", text: $voiceCommand, onCommit: {
                            VoiceHealthAssistant.shared.handleCommand(voiceCommand)
                            voiceCommand = ""
                        })
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 600)
                        .padding()
                        List(VoiceHealthAssistant.shared.responses, id: \ .id) { resp in
                            Text(resp.text)
                        }
                    }
                }
                .tabItem { Label("Voice", systemImage: "mic.fill") }.tag(4)
            }
            .accentColor(.cyan)
            .animation(.easeInOut, value: selectedTab)
            if showConfetti {
                ConfettiView().onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) { showConfetti = false }
                }
            }
        }
    }
}

// MARK: - AvatarView
struct AvatarView: View {
    let avatarName: String
    var body: some View {
        Image(avatarName)
            .resizable()
            .aspectRatio(contentMode: .fill)
            .clipShape(Circle())
            .overlay(Circle().stroke(Color.white, lineWidth: 4))
            .shadow(radius: 8)
    }
}

// MARK: - SmoothProgressBar
struct SmoothProgressBar: View {
    var progress: Double
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 12).fill(Color.gray.opacity(0.2))
                RoundedRectangle(cornerRadius: 12).fill(LinearGradient(gradient: Gradient(colors: [.green, .blue]), startPoint: .leading, endPoint: .trailing))
                    .frame(width: geo.size.width * CGFloat(progress))
            }
        }
    }
}

// MARK: - ConfettiView
struct ConfettiView: View {
    @State private var particles: [ConfettiParticle] = (0..<80).map { _ in ConfettiParticle() }
    var body: some View {
        ZStack {
            ForEach(particles) { particle in
                Circle()
                    .fill(particle.color)
                    .frame(width: particle.size, height: particle.size)
                    .position(x: particle.x, y: particle.y)
                    .opacity(particle.opacity)
                    .animation(.easeOut(duration: 2), value: particle.id)
            }
        }
        .background(Color.clear)
        .ignoresSafeArea()
    }
}
struct ConfettiParticle: Identifiable {
    let id = UUID()
    let x: CGFloat = CGFloat.random(in: 0...1920)
    let y: CGFloat = CGFloat.random(in: 0...1080)
    let size: CGFloat = CGFloat.random(in: 8...24)
    let color: Color = [Color.red, .yellow, .green, .blue, .purple, .orange].randomElement()!
    let opacity: Double = Double.random(in: 0.7...1.0)
}

// MARK: - FamilyHealthManager
class FamilyHealthManager: ObservableObject {
    static let shared = FamilyHealthManager()
    @Published var familyMembers: [FamilyMember] = [
        FamilyMember(name: "Alex", avatarName: "avatar_alex", sleepHours: 7.2, steps: 9000, mood: "😊"),
        FamilyMember(name: "Jamie", avatarName: "avatar_jamie", sleepHours: 8.1, steps: 12000, mood: "😃"),
        FamilyMember(name: "Taylor", avatarName: "avatar_taylor", sleepHours: 6.5, steps: 7000, mood: "😴")
    ]
    func startFamilyHealthNight() {
        // Trigger group dashboard, fun animations, and stats
    }
}
struct FamilyMember: Identifiable {
    let id = UUID()
    let name: String
    let avatarName: String
    let sleepHours: Double
    let steps: Int
    let mood: String
}

// MARK: - GroupWorkoutManager
class GroupWorkoutManager: ObservableObject {
    static let shared = GroupWorkoutManager()
    @Published var isActive: Bool = false
    @Published var currentSession: GroupSession?
    @Published var progress: Double = 0.0
    let availableSessions: [GroupSession] = [
        GroupSession(title: "Family Yoga", duration: 20),
        GroupSession(title: "Cardio Blast", duration: 15),
        GroupSession(title: "Mindful Meditation", duration: 10)
    ]
    func startSession(_ session: GroupSession) {
        isActive = true
        currentSession = session
        progress = 0.0
        // Start timer and update progress
    }
    func endSession() {
        isActive = false
        currentSession = nil
        progress = 0.0
    }
}
struct GroupSession: Identifiable {
    let id = UUID()
    let title: String
    let duration: Int // minutes
}

// MARK: - AmbientHealthVisualizer
class AmbientHealthVisualizer: ObservableObject {
    static let shared = AmbientHealthVisualizer()
    @Published var ambientView: some View = AnyView(Text("Live health wallpaper here"))
    func setAsScreensaver() {
        // Integrate with tvOS screensaver APIs if available
    }
}

// MARK: - LiveHealthDataVisualizer
class LiveHealthDataVisualizer: ObservableObject {
    static let shared = LiveHealthDataVisualizer()
    @Published var visualizerView: some View = AnyView(Text("Cinematic 3D health graphs here"))
    func replayDay() {
        // Animate a replay of the user's health data
    }
}

// MARK: - VoiceHealthAssistant
class VoiceHealthAssistant: ObservableObject {
    static let shared = VoiceHealthAssistant()
    @Published var responses: [VoiceResponse] = []
    func handleCommand(_ command: String) {
        // Integrate with SiriKit/voice APIs and respond
        responses.append(VoiceResponse(text: "You asked: \(command)", id: UUID()))
    }
}
struct VoiceResponse: Identifiable {
    let text: String
    let id: UUID
}

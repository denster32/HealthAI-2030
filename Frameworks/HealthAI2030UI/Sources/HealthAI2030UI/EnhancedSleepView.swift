import SwiftUI
import HealthKit
import os.log

/// Enhanced SleepView with modern UI polish and improved user experience
struct EnhancedSleepView: View {
    @StateObject private var sleepManager = SleepManager()
    @StateObject private var healthKitManager = HealthKitManager()
    @StateObject private var appleWatchManager = AppleWatchManager()
    @StateObject private var audioEngine = AudioGenerationEngine.shared
    @StateObject private var smartAlarm = SmartAlarmSystem.shared
    @StateObject private var windDownManager = WindDownManager.shared
    @StateObject private var aiEngine = AISleepAnalysisEngine.shared
    
    @State private var showingSleepSession = false
    @State private var showingSettings = false
    @State private var showingAppleWatchSetup = false
    @State private var showingWindDown = false
    @State private var showingAudioControls = false
    @State private var isAnimating = false
    @State private var isLoading = true
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                LinearGradient(
                    colors: [Color.somnaBackground, Color.somnaCardBackground.opacity(0.3)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                if isLoading {
                    // Loading state with shimmer
                    VStack(spacing: 20) {
                        Image(systemName: "moon.stars.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.somnaPrimary)
                            .somnaPulse(duration: 2.0, scale: 1.1)
                        
                        Text("Loading SomnaSync Pro...")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        SomnaProgressView(
                            value: 0.7,
                            color: .somnaPrimary,
                            showPercentage: true
                        )
                        .frame(width: 200)
                    }
                    .somnaShimmer()
                } else {
                    // Main content
                    ScrollView {
                        LazyVStack(spacing: 24) {
                            // MARK: - Hero Section with Sleep Score
                            HeroSleepSection(sleepManager: sleepManager)
                
                            // MARK: - Quick Actions
                            QuickActionsSection(
                                sleepManager: sleepManager,
                                windDownManager: windDownManager,
                                showingWindDown: $showingWindDown,
                                showingAudioControls: $showingAudioControls
                            )
                
                            // MARK: - AI Status Dashboard
                            AIStatusDashboard(aiEngine: aiEngine)
                
                            // MARK: - Current Sleep Status
                            CurrentSleepStatusView(aiEngine: aiEngine)
                
                            // MARK: - Smart Alarm Controls
                            EnhancedSmartAlarmSection(smartAlarm: smartAlarm)
                
                            // MARK: - Audio Controls
                            EnhancedAudioSection(audioEngine: audioEngine)
                
                            // MARK: - Health Data Summary
                            EnhancedHealthDataSection(healthKitManager: healthKitManager)
                
                            // MARK: - Apple Watch Integration
                            EnhancedAppleWatchSection(
                                appleWatchManager: appleWatchManager,
                                showingSetup: $showingAppleWatchSetup
                            )
                
                            // MARK: - Sleep Insights
                            EnhancedSleepInsightsSection(sleepManager: sleepManager)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                    }
                }
            }
            .navigationTitle("SomnaSync Pro")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingSettings = true }) {
                        Image(systemName: "gearshape.fill")
                            .font(.title3)
                            .foregroundColor(.somnaPrimary)
                            .somnaPulse(duration: 3.0, scale: 1.05)
                    }
                }
            }
            .sheet(isPresented: $showingSleepSession) {
                SleepSessionView(sleepManager: sleepManager)
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView(
                    sleepManager: sleepManager,
                    healthKitManager: healthKitManager,
                    appleWatchManager: appleWatchManager
                )
            }
            .sheet(isPresented: $showingAppleWatchSetup) {
                AppleWatchSetupView(appleWatchManager: appleWatchManager)
            }
            .sheet(isPresented: $showingWindDown) {
                WindDownView(windDownManager: windDownManager)
            }
            .sheet(isPresented: $showingAudioControls) {
                AudioControlsView()
            }
            .onAppear {
                setupApp()
            }
        }
    }
    
    private func setupApp() {
        Task {
            // Simulate loading time
            try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
            
            await healthKitManager.requestPermissions()
            await appleWatchManager.startMonitoring()
            
            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.5)) {
                    isLoading = false
                }
            }
        }
    }
}

// MARK: - Hero Sleep Section
struct HeroSleepSection: View {
    @ObservedObject var sleepManager: SleepManager
    @State private var isAnimating = false
    
    var body: some View {
        SomnaCard(padding: 24, cornerRadius: 20, shadowRadius: 12) {
            VStack(spacing: 20) {
                // Sleep Score Circle
                ZStack {
                    Circle()
                        .stroke(Color.somnaPrimary.opacity(0.2), lineWidth: 8)
                        .frame(width: 120, height: 120)
                    
                    Circle()
                        .trim(from: 0, to: sleepManager.sleepScore / 100)
                        .stroke(
                            LinearGradient.somnaPrimary,
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .frame(width: 120, height: 120)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 1.0), value: sleepManager.sleepScore)
                    
                    VStack(spacing: 4) {
                        Text("\(Int(sleepManager.sleepScore))")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.somnaPrimary)
                            .somnaPulse(duration: 2.0, scale: 1.05)
                        
                        Text("Sleep Score")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                    }
                }
                .scaleEffect(isAnimating ? 1.05 : 1.0)
                .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: isAnimating)
                
                // Sleep Status
                VStack(spacing: 8) {
                    Text(sleepStatusTitle)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                        .somnaPulse(duration: 3.0, scale: 1.02)
                    
                    Text(sleepStatusSubtitle)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                // Quick Stats
                HStack(spacing: 20) {
                    QuickStatView(
                        title: "Duration",
                        value: "\(Int(sleepManager.lastSleepDuration / 3600))h",
                        icon: "clock.fill",
                        color: .somnaPrimary
                    )
                    .somnaPulse(duration: 2.5, scale: 1.03)
                    
                    QuickStatView(
                        title: "Quality",
                        value: "\(Int(sleepManager.sleepQuality * 100))%",
                        icon: "star.fill",
                        color: .somnaAccent
                    )
                    .somnaPulse(duration: 2.8, scale: 1.03)
                    
                    QuickStatView(
                        title: "Efficiency",
                        value: "\(Int(sleepManager.sleepEfficiency * 100))%",
                        icon: "chart.line.uptrend.xyaxis",
                        color: .somnaSecondary
                    )
                    .somnaPulse(duration: 3.2, scale: 1.03)
                }
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
    
    private var sleepStatusTitle: String {
        if sleepManager.isSleeping {
            return "Sleeping"
        } else if sleepManager.lastSleepEnd > Date().addingTimeInterval(-3600) {
            return "Recently Awake"
        } else {
            return "Ready for Sleep"
        }
    }
    
    private var sleepStatusSubtitle: String {
        if sleepManager.isSleeping {
            return "Rest well and let AI monitor your sleep"
        } else if sleepManager.lastSleepEnd > Date().addingTimeInterval(-3600) {
            return "Your sleep session has ended"
        } else {
            return "Start your sleep session when ready"
        }
    }
}

// MARK: - Quick Actions Section
struct QuickActionsSection: View {
    @ObservedObject var sleepManager: SleepManager
    @ObservedObject var windDownManager: WindDownManager
    @Binding var showingWindDown: Bool
    @Binding var showingAudioControls: Bool
    @State private var isAnimating = false

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private var columns: [GridItem] {
        if horizontalSizeClass == .regular {
            [GridItem(.adaptive(minimum: 160), spacing: 12)]
        } else {
            Array(repeating: GridItem(.flexible(), spacing: 12), count: 2)
        }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Quick Actions")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .somnaPulse(duration: 4.0, scale: 1.01)
                
                Spacer()
            }
            
            LazyVGrid(columns: columns, spacing: 12) {
                QuickActionCard(
                    title: sleepManager.isSleeping ? "End Sleep" : "Start Sleep",
                    subtitle: sleepManager.isSleeping ? "Stop tracking" : "Begin session",
                    icon: sleepManager.isSleeping ? "stop.circle.fill" : "play.circle.fill",
                    color: sleepManager.isSleeping ? .somnaError : .somnaSuccess,
                    action: {
                        if sleepManager.isSleeping {
                            sleepManager.endSleepSession()
                        } else {
                            sleepManager.startSleepSession()
                        }
                    }
                )
                .somnaPulse(duration: 2.0, scale: 1.02)
                
                QuickActionCard(
                    title: "Wind Down",
                    subtitle: "Prepare for sleep",
                    icon: "moon.stars.fill",
                    color: .somnaSecondary,
                    action: { showingWindDown = true }
                )
                .somnaPulse(duration: 2.2, scale: 1.02)
                
                QuickActionCard(
                    title: "Audio",
                    subtitle: "Sleep sounds",
                    icon: "speaker.wave.3.fill",
                    color: .somnaPrimary,
                    action: { showingAudioControls = true }
                )
                .somnaPulse(duration: 2.4, scale: 1.02)
                
                QuickActionCard(
                    title: "Smart Alarm",
                    subtitle: "Set wake time",
                    icon: "alarm.fill",
                    color: .somnaWarning,
                    action: { /* Show smart alarm setup */ }
                )
                .somnaPulse(duration: 2.6, scale: 1.02)
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - AI Status Dashboard
struct AIStatusDashboard: View {
    @ObservedObject var aiEngine: AISleepAnalysisEngine
    @State private var isAnimating = false
    
    var body: some View {
        SomnaCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "brain.head.profile")
                        .font(.title2)
                        .foregroundColor(.somnaPrimary)
                        .somnaPulse(duration: 2.0, scale: 1.1)
                    
                    Text("AI Status")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                }
                
                Text("AI status dashboard will be displayed here")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - Current Sleep Status View
struct CurrentSleepStatusView: View {
    @ObservedObject var aiEngine: AISleepAnalysisEngine
    @State private var isAnimating = false
    
    var body: some View {
        SomnaCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "bed.double.fill")
                        .font(.title2)
                        .foregroundColor(.somnaAccent)
                        .somnaPulse(duration: 2.5, scale: 1.1)
                    
                    Text("Current Status")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                }
                
                Text("Current sleep status will be displayed here")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - Enhanced Smart Alarm Section
struct EnhancedSmartAlarmSection: View {
    @ObservedObject var smartAlarm: SmartAlarmSystem
    @State private var isAnimating = false
    
    var body: some View {
        SomnaCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "alarm")
                        .font(.title2)
                        .foregroundColor(.somnaWarning)
                        .somnaPulse(duration: 2.0, scale: 1.1)
                    
                    Text("Smart Alarm")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                }
                
                Text("Smart alarm controls will be displayed here")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - Enhanced Audio Section
struct EnhancedAudioSection: View {
    @ObservedObject var audioEngine: AudioGenerationEngine
    @State private var isAnimating = false
    
    var body: some View {
        SomnaCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "speaker.wave.3")
                        .font(.title2)
                        .foregroundColor(.somnaPrimary)
                        .somnaPulse(duration: 2.0, scale: 1.1)
                    
                    Text("Audio Controls")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                }
                
                Text("Audio controls will be displayed here")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - Health Data Summary
struct EnhancedHealthDataSection: View {
    @ObservedObject var healthKitManager: HealthKitManager
    @State private var isAnimating = false
    
    var body: some View {
        SomnaCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "heart.fill")
                        .font(.title2)
                        .foregroundColor(.somnaError)
                        .somnaPulse(duration: 2.0, scale: 1.1)
                    
                    Text("Health Data")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                }
                
                Text("Health data integration details will be displayed here")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - Apple Watch Integration
struct EnhancedAppleWatchSection: View {
    @ObservedObject var appleWatchManager: AppleWatchManager
    @Binding var showingSetup: Bool
    @State private var isAnimating = false
    
    var body: some View {
        SomnaCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "applewatch")
                        .font(.title2)
                        .foregroundColor(.somnaPrimary)
                        .somnaPulse(duration: 2.0, scale: 1.1)
                    
                    Text("Apple Watch")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                }
                
                Text("Apple Watch integration details will be displayed here")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - Sleep Insights
struct EnhancedSleepInsightsSection: View {
    @ObservedObject var sleepManager: SleepManager
    @State private var isAnimating = false
    
    var body: some View {
        SomnaCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "chart.bar.fill")
                        .font(.title2)
                        .foregroundColor(.somnaAccent)
                        .somnaPulse(duration: 2.0, scale: 1.1)
                    
                    Text("Sleep Insights")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                }
                
                Text("Sleep insights and analytics will be displayed here")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - Wind Down View
struct WindDownView: View {
    @ObservedObject var windDownManager: WindDownManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                if windDownManager.isWindDownActive {
                    WindDownActiveView(windDownManager: windDownManager)
                } else {
                    WindDownSetupView(windDownManager: windDownManager)
                }
            }
            .padding()
            .navigationTitle("Wind Down")
            .navigationBarTitleDisplayMode(.large)
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

struct WindDownActiveView: View {
    @ObservedObject var windDownManager: WindDownManager
    
    var body: some View {
        VStack(spacing: 24) {
            // Progress
            VStack(spacing: 16) {
                Text("Wind Down Progress")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                SomnaProgressView(
                    value: windDownManager.totalProgress,
                    showPercentage: true
                )
                .frame(height: 12)
            }
            
            // Current Phase
            if let activity = windDownManager.currentActivity {
                VStack(spacing: 16) {
                    Image(systemName: activity.icon)
                        .font(.system(size: 60))
                        .foregroundColor(.somnaPrimary)
                        .somnaPulse(duration: 2.0, scale: 1.1)
                    
                    Text(activity.title)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(activity.description)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    SomnaProgressView(
                        value: windDownManager.phaseProgress,
                        color: .somnaSecondary
                    )
                    .frame(height: 8)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.somnaCardBackground)
                )
            }
            
            // Relaxation Level
            VStack(spacing: 12) {
                Text("Relaxation Level")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                SomnaProgressView(
                    value: windDownManager.relaxationLevel,
                    color: .somnaAccent,
                    showPercentage: true
                )
                .frame(height: 10)
            }
            
            Button("Stop Wind Down") {
                windDownManager.stopWindDown()
            }
            .buttonStyle(SomnaSecondaryButtonStyle())
        }
    }
}

struct WindDownSetupView: View {
    @ObservedObject var windDownManager: WindDownManager
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "moon.stars.fill")
                .font(.system(size: 80))
                .foregroundColor(.somnaSecondary)
                .somnaPulse(duration: 3.0, scale: 1.05)
            
            VStack(spacing: 16) {
                Text("Ready to Wind Down?")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Start a comprehensive 1-hour wind-down process to prepare your mind and body for optimal sleep.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 12) {
                SomnaListItem(
                    title: "Environment Optimization",
                    subtitle: "Create the perfect sleep atmosphere",
                    icon: "lightbulb.fill",
                    iconColor: .somnaWarning
                )
                
                SomnaListItem(
                    title: "Breathing Exercises",
                    subtitle: "4-7-8 relaxation technique",
                    icon: "lungs.fill",
                    iconColor: .somnaInfo
                )
                
                SomnaListItem(
                    title: "Progressive Relaxation",
                    subtitle: "Systematic body relaxation",
                    icon: "figure.mind.and.body",
                    iconColor: .somnaAccent
                )
                
                SomnaListItem(
                    title: "Guided Meditation",
                    subtitle: "Mindfulness and mental calm",
                    icon: "brain.head.profile",
                    iconColor: .somnaSecondary
                )
                
                SomnaListItem(
                    title: "Sleep Audio",
                    subtitle: "Transition to sleep-optimized sounds",
                    icon: "waveform",
                    iconColor: .somnaPrimary
                )
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.somnaCardBackground)
            )
            
            Button("Start Wind Down") {
                Task {
                    await windDownManager.startWindDown()
                }
            }
            .buttonStyle(SomnaPrimaryButtonStyle())
        }
    }
}

// MARK: - Supporting Views
struct QuickStatView: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct QuickActionCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                VStack(spacing: 4) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.somnaCardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(color.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
} 
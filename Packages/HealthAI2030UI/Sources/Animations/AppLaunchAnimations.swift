import SwiftUI

// MARK: - App Launch Animations
/// Comprehensive app launch animations for enhanced user experience
/// Provides smooth, engaging, and professional launch sequences for the HealthAI 2030 app
public struct AppLaunchAnimations {
    
    // MARK: - Splash Screen Animation
    
    /// Animated splash screen with logo and loading sequence
    public struct SplashScreenAnimation: View {
        let onComplete: () -> Void
        @State private var logoScale: CGFloat = 0.5
        @State private var logoOpacity: Double = 0
        @State private var logoRotation: Double = -180
        @State private var progressValue: Double = 0
        @State private var progressOpacity: Double = 0
        @State private var backgroundScale: CGFloat = 1.2
        @State private var backgroundOpacity: Double = 0
        
        public init(onComplete: @escaping () -> Void) {
            self.onComplete = onComplete
        }
        
        public var body: some View {
            ZStack {
                // Animated background
                LinearGradient(
                    colors: [Color.blue.opacity(0.8), Color.purple.opacity(0.6)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .scaleEffect(backgroundScale)
                .opacity(backgroundOpacity)
                .ignoresSafeArea()
                
                VStack(spacing: 40) {
                    // Logo animation
                    VStack(spacing: 16) {
                        // App icon
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.blue, Color.purple],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 120, height: 120)
                                .scaleEffect(logoScale)
                                .rotationEffect(.degrees(logoRotation))
                            
                            Image(systemName: "heart.fill")
                                .font(.system(size: 60, weight: .medium))
                                .foregroundColor(.white)
                                .scaleEffect(logoScale)
                                .rotationEffect(.degrees(logoRotation))
                        }
                        
                        // App name
                        Text("HealthAI 2030")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                            .opacity(logoOpacity)
                    }
                    
                    // Progress indicator
                    VStack(spacing: 12) {
                        ProgressView(value: progressValue)
                            .progressViewStyle(LinearProgressViewStyle(tint: .white))
                            .frame(width: 200)
                            .opacity(progressOpacity)
                        
                        Text("Initializing...")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                            .opacity(progressOpacity)
                    }
                }
            }
            .onAppear {
                startAnimation()
            }
        }
        
        private func startAnimation() {
            // Background animation
            withAnimation(.easeInOut(duration: 1.5)) {
                backgroundOpacity = 1.0
                backgroundScale = 1.0
            }
            
            // Logo animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
                    logoScale = 1.0
                    logoOpacity = 1.0
                    logoRotation = 0
                }
            }
            
            // Progress animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                withAnimation(.easeInOut(duration: 0.5)) {
                    progressOpacity = 1.0
                }
                
                // Simulate loading progress
                withAnimation(.linear(duration: 2.0)) {
                    progressValue = 1.0
                }
            }
            
            // Complete and transition
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
                withAnimation(.easeInOut(duration: 0.5)) {
                    logoScale = 1.2
                    logoOpacity = 0
                    progressOpacity = 0
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    onComplete()
                }
            }
        }
    }
    
    // MARK: - App Icon Animation
    
    /// Animated app icon with heartbeat effect
    public struct AppIconAnimation: View {
        let size: CGFloat
        @State private var scale: CGFloat = 1.0
        @State private var rotation: Double = 0
        @State private var pulseOpacity: Double = 0
        
        public init(size: CGFloat = 100) {
            self.size = size
        }
        
        public var body: some View {
            ZStack {
                // Pulse effect
                Circle()
                    .fill(Color.blue.opacity(0.3))
                    .frame(width: size * 1.5, height: size * 1.5)
                    .scaleEffect(scale)
                    .opacity(pulseOpacity)
                
                // Main icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.blue, Color.purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: size, height: size)
                        .scaleEffect(scale)
                        .rotationEffect(.degrees(rotation))
                    
                    Image(systemName: "heart.fill")
                        .font(.system(size: size * 0.5, weight: .medium))
                        .foregroundColor(.white)
                        .scaleEffect(scale)
                        .rotationEffect(.degrees(rotation))
                }
            }
            .onAppear {
                startHeartbeatAnimation()
            }
        }
        
        private func startHeartbeatAnimation() {
            // Continuous heartbeat
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                scale = 1.1
            }
            
            // Pulse effect
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                pulseOpacity = 0.5
            }
            
            // Rotation
            withAnimation(.linear(duration: 10.0).repeatForever(autoreverses: false)) {
                rotation = 360
            }
        }
    }
    
    // MARK: - Loading Sequence Animation
    
    /// Sequential loading animation with multiple stages
    public struct LoadingSequenceAnimation: View {
        let stages: [LoadingStage]
        let onComplete: () -> Void
        @State private var currentStage: Int = 0
        @State private var stageProgress: Double = 0
        @State private var overallProgress: Double = 0
        @State private var stageOpacity: Double = 0
        
        public init(
            stages: [LoadingStage] = defaultStages,
            onComplete: @escaping () -> Void
        ) {
            self.stages = stages
            self.onComplete = onComplete
        }
        
        public var body: some View {
            VStack(spacing: 30) {
                // Progress circle
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 8)
                        .frame(width: 120, height: 120)
                    
                    Circle()
                        .trim(from: 0, to: overallProgress)
                        .stroke(
                            AngularGradient(
                                gradient: Gradient(colors: [Color.blue, Color.purple]),
                                center: .center,
                                startAngle: .degrees(-90),
                                endAngle: .degrees(270)
                            ),
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .frame(width: 120, height: 120)
                        .rotationEffect(.degrees(-90))
                    
                    VStack {
                        Text("\(Int(overallProgress * 100))%")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.primary)
                        
                        Text("Complete")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
                
                // Current stage
                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        Image(systemName: currentStage < stages.count ? stages[currentStage].icon : "checkmark.circle.fill")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(currentStage < stages.count ? stages[currentStage].color : .green)
                        
                        Text(currentStage < stages.count ? stages[currentStage].title : "Complete")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                    }
                    .opacity(stageOpacity)
                    
                    if currentStage < stages.count {
                        ProgressView(value: stageProgress)
                            .progressViewStyle(LinearProgressViewStyle(tint: stages[currentStage].color))
                            .frame(width: 200)
                    }
                }
            }
            .onAppear {
                startLoadingSequence()
            }
        }
        
        private func startLoadingSequence() {
            loadNextStage()
        }
        
        private func loadNextStage() {
            guard currentStage < stages.count else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    onComplete()
                }
                return
            }
            
            // Show current stage
            withAnimation(.easeInOut(duration: 0.3)) {
                stageOpacity = 1.0
            }
            
            // Animate stage progress
            withAnimation(.linear(duration: stages[currentStage].duration)) {
                stageProgress = 1.0
            }
            
            // Update overall progress
            let stageContribution = 1.0 / Double(stages.count)
            let targetProgress = Double(currentStage + 1) * stageContribution
            
            withAnimation(.linear(duration: stages[currentStage].duration)) {
                overallProgress = targetProgress
            }
            
            // Move to next stage
            DispatchQueue.main.asyncAfter(deadline: .now() + stages[currentStage].duration) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    stageOpacity = 0
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    currentStage += 1
                    stageProgress = 0
                    loadNextStage()
                }
            }
        }
        
        private static var defaultStages: [LoadingStage] {
            [
                LoadingStage(title: "Initializing", icon: "gear", color: .blue, duration: 1.0),
                LoadingStage(title: "Loading Data", icon: "arrow.down.circle", color: .green, duration: 1.5),
                LoadingStage(title: "Connecting", icon: "network", color: .orange, duration: 1.0),
                LoadingStage(title: "Ready", icon: "checkmark.circle", color: .purple, duration: 0.5)
            ]
        }
    }
    
    // MARK: - Welcome Animation
    
    /// Welcome animation with greeting and feature highlights
    public struct WelcomeAnimation: View {
        let userName: String?
        let onComplete: () -> Void
        @State private var greetingOpacity: Double = 0
        @State private var greetingOffset: CGFloat = 50
        @State private var featuresOpacity: Double = 0
        @State private var featuresOffset: CGFloat = 30
        @State private var currentFeature: Int = 0
        @State private var featureScale: CGFloat = 0.8
        
        public init(
            userName: String? = nil,
            onComplete: @escaping () -> Void
        ) {
            self.userName = userName
            self.onComplete = onComplete
        }
        
        public var body: some View {
            VStack(spacing: 40) {
                // Greeting
                VStack(spacing: 8) {
                    Text("Welcome")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.primary)
                    
                    if let userName = userName {
                        Text(userName)
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(.blue)
                    }
                    
                    Text("to HealthAI 2030")
                        .font(.system(size: 18, weight: .regular))
                        .foregroundColor(.secondary)
                }
                .opacity(greetingOpacity)
                .offset(y: greetingOffset)
                
                // Feature highlights
                VStack(spacing: 20) {
                    ForEach(Array(welcomeFeatures.enumerated()), id: \.offset) { index, feature in
                        HStack(spacing: 16) {
                            Image(systemName: feature.icon)
                                .font(.system(size: 24, weight: .medium))
                                .foregroundColor(feature.color)
                                .frame(width: 40, height: 40)
                                .background(
                                    Circle()
                                        .fill(feature.color.opacity(0.1))
                                )
                                .scaleEffect(index == currentFeature ? 1.2 : 1.0)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(feature.title)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.primary)
                                
                                Text(feature.description)
                                    .font(.system(size: 14, weight: .regular))
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                        }
                        .opacity(index == currentFeature ? 1.0 : 0.3)
                        .scaleEffect(index == currentFeature ? 1.0 : 0.9)
                    }
                }
                .opacity(featuresOpacity)
                .offset(y: featuresOffset)
            }
            .padding(40)
            .onAppear {
                startWelcomeSequence()
            }
        }
        
        private func startWelcomeSequence() {
            // Greeting animation
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                greetingOpacity = 1.0
                greetingOffset = 0
            }
            
            // Features animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                    featuresOpacity = 1.0
                    featuresOffset = 0
                }
                
                // Cycle through features
                cycleFeatures()
            }
        }
        
        private func cycleFeatures() {
            Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { timer in
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    currentFeature = (currentFeature + 1) % welcomeFeatures.count
                }
                
                if currentFeature == 0 {
                    timer.invalidate()
                    
                    // Complete welcome
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            greetingOpacity = 0
                            featuresOpacity = 0
                        }
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            onComplete()
                        }
                    }
                }
            }
        }
        
        private var welcomeFeatures: [WelcomeFeature] {
            [
                WelcomeFeature(
                    title: "AI-Powered Insights",
                    description: "Get personalized health recommendations",
                    icon: "brain.head.profile",
                    color: .blue
                ),
                WelcomeFeature(
                    title: "Real-time Monitoring",
                    description: "Track your health metrics continuously",
                    icon: "heart.fill",
                    color: .red
                ),
                WelcomeFeature(
                    title: "Smart Notifications",
                    description: "Stay informed about your health",
                    icon: "bell.fill",
                    color: .orange
                ),
                WelcomeFeature(
                    title: "Secure & Private",
                    description: "Your data is protected and encrypted",
                    icon: "lock.shield.fill",
                    color: .green
                )
            ]
        }
    }
}

// MARK: - Supporting Types

struct LoadingStage {
    let title: String
    let icon: String
    let color: Color
    let duration: Double
}

struct WelcomeFeature {
    let title: String
    let description: String
    let icon: String
    let color: Color
}

// MARK: - Preview

struct AppLaunchAnimations_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 30) {
            AppIconAnimation(size: 80)
            
            LoadingSequenceAnimation {
                print("Loading complete")
            }
            
            WelcomeAnimation(userName: "John") {
                print("Welcome complete")
            }
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
} 
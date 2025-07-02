import SwiftUI
import HealthKit
import TipKit
import AVFoundation
import AppIntents

struct OnboardingView: View {
    @Binding var onboardingCompleted: Bool
    @State private var currentPage = 0
    @State private var showPermissions = false
    @State private var healthKitAuthorized = false
    @State private var notificationsAuthorized = false
    @State private var siriAuthorized = false
    @State private var locationAuthorized = false
    
    // iOS 18 Animations
    @State private var animateElements = false
    @State private var showFeatureHighlights = false
    
    private let totalPages = 6
    
    var body: some View {
        ZStack {
            // Dynamic gradient background
            LinearGradient(
                colors: [
                    Color(.systemIndigo).opacity(0.8),
                    Color(.systemPurple).opacity(0.6),
                    Color(.systemBlue).opacity(0.4)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            if showPermissions {
                permissionsView
            } else {
                onboardingPages
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0)) {
                animateElements = true
            }
        }
    }
    
    // MARK: - Onboarding Pages
    
    private var onboardingPages: some View {
        TabView(selection: $currentPage) {
            welcomePage
                .tag(0)
            
            aiCapabilitiesPage
                .tag(1)
            
            personalizationPage
                .tag(2)
            
            ios18FeaturesPage
                .tag(3)
            
            healthIntegrationPage
                .tag(4)
            
            finalSetupPage
                .tag(5)
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
        .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
    }
    
    // MARK: - Welcome Page
    
    private var welcomePage: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // App Icon with animation
            Image(systemName: "brain.head.profile")
                .font(.system(size: 100))
                .foregroundStyle(.white)
                .shadow(radius: 10)
                .scaleEffect(animateElements ? 1.0 : 0.5)
                .animation(.spring(response: 0.8, dampingFraction: 0.6), value: animateElements)
            
            VStack(spacing: 20) {
                Text("Welcome to")
                    .font(.title2)
                    .foregroundColor(.white.opacity(0.8))
                
                Text("HealthAI 2030")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Your AI-Powered Health Companion")
                    .font(.title3)
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
            }
            .opacity(animateElements ? 1.0 : 0.0)
            .animation(.easeInOut(duration: 1.0).delay(0.3), value: animateElements)
            
            VStack(spacing: 15) {
                FeatureHighlight(
                    icon: "sparkles",
                    title: "Explainable AI",
                    description: "Understand every health recommendation"
                )
                
                FeatureHighlight(
                    icon: "person.crop.circle.badge.clock",
                    title: "Advanced Personalization",
                    description: "AI that learns and adapts to you"
                )
                
                FeatureHighlight(
                    icon: "iphone",
                    title: "iOS 18 Integration",
                    description: "Live Activities, Control Center, Siri"
                )
            }
            .opacity(animateElements ? 1.0 : 0.0)
            .animation(.easeInOut(duration: 1.0).delay(0.6), value: animateElements)
            
            Spacer()
            
            nextButton
        }
        .padding()
    }
    
    // MARK: - AI Capabilities Page
    
    private var aiCapabilitiesPage: some View {
        VStack(spacing: 30) {
            Text("Advanced AI Engine")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text("Powered by cutting-edge machine learning")
                .font(.title3)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 20) {
                AIFeatureCard(
                    icon: "brain",
                    title: "Explainable AI",
                    description: "Understand why AI makes recommendations",
                    color: .cyan
                )
                
                AIFeatureCard(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Predictive Analytics",
                    description: "Forecast health trends and risks",
                    color: .green
                )
                
                AIFeatureCard(
                    icon: "person.crop.circle.badge.questionmark",
                    title: "Health Coaching",
                    description: "Personalized AI health coach",
                    color: .orange
                )
                
                AIFeatureCard(
                    icon: "waveform.path.ecg",
                    title: "Real-time Analysis",
                    description: "Continuous health monitoring",
                    color: .red
                )
            }
            
            Spacer()
            
            HStack {
                backButton
                Spacer()
                nextButton
            }
        }
        .padding()
    }
    
    // MARK: - Personalization Page
    
    private var personalizationPage: some View {
        VStack(spacing: 30) {
            Text("Personal Health AI")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text("AI that adapts to your unique patterns")
                .font(.title3)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
            
            VStack(spacing: 20) {
                PersonalizationFeature(
                    icon: "person.circle",
                    title: "User Modeling",
                    description: "AI builds a comprehensive model of your health patterns, preferences, and goals"
                )
                
                PersonalizationFeature(
                    icon: "arrow.triangle.2.circlepath",
                    title: "Adaptive Learning",
                    description: "System continuously improves recommendations based on your feedback"
                )
                
                PersonalizationFeature(
                    icon: "message.circle",
                    title: "Personalized Communication",
                    description: "AI adapts its communication style to match your preferences"
                )
                
                PersonalizationFeature(
                    icon: "target",
                    title: "Context Awareness",
                    description: "Recommendations adapt to your current situation and environment"
                )
            }
            
            Spacer()
            
            HStack {
                backButton
                Spacer()
                nextButton
            }
        }
        .padding()
    }
    
    // MARK: - iOS 18 Features Page
    
    private var ios18FeaturesPage: some View {
        VStack(spacing: 30) {
            Text("iOS 18 Integration")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text("Cutting-edge iOS features")
                .font(.title3)
                .foregroundColor(.white.opacity(0.8))
            
            VStack(spacing: 20) {
                iOS18Feature(
                    icon: "circle.fill",
                    title: "Live Activities",
                    description: "Real-time health tracking on your Lock Screen and Dynamic Island"
                )
                
                iOS18Feature(
                    icon: "rectangle.3.group",
                    title: "Interactive Widgets",
                    description: "Control your health directly from the Home Screen"
                )
                
                iOS18Feature(
                    icon: "mic.circle",
                    title: "Advanced Siri Integration",
                    description: "Natural voice commands for all health functions"
                )
                
                iOS18Feature(
                    icon: "slider.horizontal.below.rectangle",
                    title: "Control Center",
                    description: "Quick health controls in Control Center"
                )
                
                iOS18Feature(
                    icon: "magnifyingglass",
                    title: "Spotlight Search",
                    description: "Search your health data with natural language"
                )
            }
            
            Spacer()
            
            HStack {
                backButton
                Spacer()
                nextButton
            }
        }
        .padding()
    }
    
    // MARK: - Health Integration Page
    
    private var healthIntegrationPage: some View {
        VStack(spacing: 30) {
            Text("Comprehensive Health")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text("Seamless integration with Apple Health")
                .font(.title3)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
            
            VStack(spacing: 20) {
                HealthFeature(
                    icon: "heart.fill",
                    title: "Advanced Cardiac Monitoring",
                    description: "AFib detection, HRV analysis, VO2 Max tracking"
                )
                
                HealthFeature(
                    icon: "bed.double.fill",
                    title: "Sleep Optimization",
                    description: "AI-powered sleep stage detection and environment control"
                )
                
                HealthFeature(
                    icon: "brain.head.profile",
                    title: "Mental Health Insights",
                    description: "Stress monitoring, mood tracking, mindfulness guidance"
                )
                
                HealthFeature(
                    icon: "lungs.fill",
                    title: "Respiratory Analysis",
                    description: "Breathing pattern analysis and respiratory health"
                )
            }
            
            Spacer()
            
            HStack {
                backButton
                Spacer()
                nextButton
            }
        }
        .padding()
    }
    
    // MARK: - Final Setup Page
    
    private var finalSetupPage: some View {
        VStack(spacing: 30) {
            Text("Ready to Begin")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text("Let's set up your permissions for the best experience")
                .font(.title3)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
            
            VStack(spacing: 20) {
                SetupCard(
                    icon: "heart.text.square",
                    title: "Health Data Access",
                    description: "Enable comprehensive health monitoring",
                    isRequired: true
                )
                
                SetupCard(
                    icon: "bell.circle",
                    title: "Smart Notifications",
                    description: "Receive timely health insights and alerts",
                    isRequired: false
                )
                
                SetupCard(
                    icon: "mic.circle",
                    title: "Siri Integration",
                    description: "Voice control for hands-free health management",
                    isRequired: false
                )
                
                SetupCard(
                    icon: "location.circle",
                    title: "Location Services",
                    description: "Environment-aware health recommendations",
                    isRequired: false
                )
            }
            
            Spacer()
            
            Button(action: {
                withAnimation(.spring()) {
                    showPermissions = true
                }
            }) {
                Text("Set Up Permissions")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            
            HStack {
                backButton
                Spacer()
            }
        }
        .padding()
    }
    
    // MARK: - Permissions View
    
    private var permissionsView: some View {
        VStack(spacing: 30) {
            Text("Enable Permissions")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text("Grant permissions to unlock the full potential of HealthAI 2030")
                .font(.body)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
            
            VStack(spacing: 16) {
                PermissionRow(
                    icon: "heart.text.square.fill",
                    title: "Health Data",
                    description: "Access health and fitness data",
                    isGranted: healthKitAuthorized,
                    action: requestHealthKitPermission
                )
                
                PermissionRow(
                    icon: "bell.fill",
                    title: "Notifications",
                    description: "Send health alerts and reminders",
                    isGranted: notificationsAuthorized,
                    action: requestNotificationPermission
                )
                
                PermissionRow(
                    icon: "mic.fill",
                    title: "Siri & Shortcuts",
                    description: "Voice control and automation",
                    isGranted: siriAuthorized,
                    action: requestSiriPermission
                )
                
                PermissionRow(
                    icon: "location.fill",
                    title: "Location",
                    description: "Environment-aware features",
                    isGranted: locationAuthorized,
                    action: requestLocationPermission
                )
            }
            
            Spacer()
            
            if healthKitAuthorized {
                Button(action: completeOnboarding) {
                    Text("Get Started")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            LinearGradient(
                                colors: [.green, .blue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            }
            
            Button(action: {
                withAnimation(.spring()) {
                    showPermissions = false
                }
            }) {
                Text("Back")
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding()
    }
    
    // MARK: - Navigation Buttons
    
    private var nextButton: some View {
        Button(action: {
            withAnimation(.spring()) {
                if currentPage < totalPages - 1 {
                    currentPage += 1
                } else {
                    showPermissions = true
                }
            }
        }) {
            Text(currentPage == totalPages - 1 ? "Continue" : "Next")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(width: 120, height: 50)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    private var backButton: some View {
        Button(action: {
            withAnimation(.spring()) {
                if currentPage > 0 {
                    currentPage -= 1
                }
            }
        }) {
            Text("Back")
                .font(.body)
                .foregroundColor(.white.opacity(0.7))
        }
    }
    
    // MARK: - Permission Actions
    
    private func requestHealthKitPermission() {
        let healthStore = HKHealthStore()
        
        guard HKHealthStore.isHealthDataAvailable() else { return }
        
        let healthTypes: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
            HKObjectType.quantityType(forIdentifier: .sleepAnalysis)!,
            HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!
        ]
        
        healthStore.requestAuthorization(toShare: nil, read: healthTypes) { success, _ in
            DispatchQueue.main.async {
                self.healthKitAuthorized = success
            }
        }
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            DispatchQueue.main.async {
                self.notificationsAuthorized = granted
            }
        }
    }
    
    private func requestSiriPermission() {
        INPreferences.requestSiriAuthorization { status in
            DispatchQueue.main.async {
                self.siriAuthorized = status == .authorized
            }
        }
    }
    
    private func requestLocationPermission() {
        // This would be handled by a location manager
        DispatchQueue.main.async {
            self.locationAuthorized = true
        }
    }
    
    private func completeOnboarding() {
        withAnimation(.spring()) {
            onboardingCompleted = true
        }
    }
}

// MARK: - Supporting Views

struct FeatureHighlight: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.white)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            }
            
            Spacer()
        }
    }
}

struct AIFeatureCard: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.largeTitle)
                .foregroundColor(color)
            
            Text(title)
                .font(.headline)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            
            Text(description)
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(height: 140)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct PersonalizationFeature: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(.cyan)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            }
            
            Spacer()
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct iOS18Feature: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(.green)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            }
            
            Spacer()
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct HealthFeature: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(.red)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            }
            
            Spacer()
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct SetupCard: View {
    let icon: String
    let title: String
    let description: String
    let isRequired: Bool
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(isRequired ? .red : .blue)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    if isRequired {
                        Text("Required")
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.red.opacity(0.2))
                            .clipShape(Capsule())
                    }
                }
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            }
            
            Spacer()
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct PermissionRow: View {
    let icon: String
    let title: String
    let description: String
    let isGranted: Bool
    let action: () -> Void
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(isGranted ? .green : .white)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            }
            
            Spacer()
            
            if isGranted {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.green)
            } else {
                Button("Enable") {
                    action()
                }
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(.blue)
                .foregroundColor(.white)
                .clipShape(Capsule())
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    OnboardingView(onboardingCompleted: .constant(false))
}
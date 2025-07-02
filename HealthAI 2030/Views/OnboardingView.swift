import SwiftUI
import HealthKit
import UserNotifications

@available(iOS 17.0, *)
@available(macOS 14.0, *)

/// Enhanced OnboardingView with health data training
struct OnboardingView: View {
    @StateObject private var healthKitManager = HealthKitManager.shared
    @StateObject private var healthDataTrainer = HealthDataTrainer.shared
    @StateObject private var appConfiguration = AppConfiguration.shared
    
    @State private var currentStep = 0
    @State private var showHealthDataTraining = false
    @State private var healthDataAvailable = false
    @State private var dataPointsCount = 0
    @State private var isAnimating = false
    
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    private let totalSteps = 4

    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [Color.somnaBackground, Color.somnaCardBackground.opacity(0.3)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 30) {
                    // Progress indicator
                    SomnaProgressView(
                        value: Float(currentStep + 1) / Float(totalSteps),
                        color: .somnaPrimary,
                        showPercentage: true
                    )
                    .frame(height: 8)
                    .padding(.horizontal)
                    .somnaPulse(duration: 2.0, scale: 1.02)
                    
                    // Step content
                    switch currentStep {
                    case 0:
                        welcomeStep
                    case 1:
                        permissionsStep
                    case 2:
                        healthDataTrainingStep
                    case 3:
                        finalStep
                    default:
                        welcomeStep
                    }
                    
                    Spacer()
                    
                    // Navigation buttons
                    HStack {
                        if currentStep > 0 {
                            Button("Back") {
                                withAnimation {
                                    currentStep -= 1
                                }
                            }
                            .buttonStyle(SomnaSecondaryButtonStyle())
                            .somnaPulse(duration: 2.5, scale: 1.01)
                        }
                        
                        Spacer()
                        
                        if currentStep < totalSteps - 1 {
                            Button(currentStep == 2 && showHealthDataTraining ? "Skip" : "Next") {
                                withAnimation {
                                    currentStep += 1
                                }
                            }
                            .buttonStyle(SomnaPrimaryButtonStyle())
                            .disabled(currentStep == 1 && !healthKitManager.isAuthorized)
                            .somnaPulse(duration: 2.0, scale: 1.02)
                        } else {
                            Button("Get Started") {
                                completeOnboarding()
                            }
                            .buttonStyle(SomnaPrimaryButtonStyle())
                            .somnaPulse(duration: 1.5, scale: 1.03)
                        }
                    }
                    .padding(.horizontal)
                }
                .padding()
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            checkHealthDataAvailability()
            isAnimating = true
        }
    }
    
    // MARK: - Step Views
    
    private var welcomeStep: some View {
        VStack(spacing: 30) {
            Image("AppLogo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 120, height: 120)
                .scaleEffect(isAnimating ? 1.05 : 1.0)
                .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: isAnimating)
                .somnaPulse(duration: 3.0, scale: 1.05)
            
            VStack(spacing: 20) {
                Text("Welcome to SomnaSync Pro")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .somnaPulse(duration: 4.0, scale: 1.01)
                
                Text("Your AI-powered sleep optimization companion")
                    .font(.title2)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .somnaPulse(duration: 3.5, scale: 1.02)
                
                Group {
                    if horizontalSizeClass == .regular {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 250))], spacing: 15) {
                            featureRows
                        }
                    } else {
                        VStack(alignment: .leading, spacing: 15) {
                            featureRows
                        }
                    }
                }
                .padding(.top)
                .somnaShimmer()
            }
        }
    }
    
    private var permissionsStep: some View {
        VStack(spacing: 30) {
            Image(systemName: "heart.text.square")
                .font(.system(size: 80))
                .foregroundColor(.somnaPrimary)
                .scaleEffect(isAnimating ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: isAnimating)
                .somnaPulse(duration: 2.5, scale: 1.1)
            
            VStack(spacing: 20) {
                Text("Health Permissions")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .somnaPulse(duration: 3.0, scale: 1.02)
                
                Text("SomnaSync Pro needs access to your health data to provide personalized sleep insights and optimize your sleep experience.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .somnaShimmer()
                
                VStack(alignment: .leading, spacing: 15) {
                    PermissionRow(
                        icon: "heart.fill",
                        title: "Heart Rate",
                        description: "Analyze sleep stages and quality",
                        isGranted: healthKitManager.heartRatePermission
                    )
                    .somnaPulse(duration: 2.0, scale: 1.01)
                    
                    PermissionRow(
                        icon: "waveform.path.ecg",
                        title: "Heart Rate Variability",
                        description: "Measure stress and recovery",
                        isGranted: healthKitManager.hrvPermission
                    )
                    .somnaPulse(duration: 2.2, scale: 1.01)
                    
                    PermissionRow(
                        icon: "lungs.fill",
                        title: "Respiratory Rate",
                        description: "Monitor breathing patterns",
                        isGranted: healthKitManager.respiratoryRatePermission
                    )
                    .somnaPulse(duration: 2.4, scale: 1.01)
                    
                    PermissionRow(
                        icon: "bed.double.fill",
                        title: "Sleep Analysis",
                        description: "Track sleep stages and duration",
                        isGranted: healthKitManager.sleepAnalysisPermission
                    )
                    .somnaPulse(duration: 2.6, scale: 1.01)
                }
                .padding(.top)
                
                if !healthKitManager.isAuthorized {
                    Button("Grant Permissions") {
                        Task {
                            await healthKitManager.requestPermissions()
                        }
                    }
                    .buttonStyle(SomnaPrimaryButtonStyle())
                    .padding(.top)
                    .somnaPulse(duration: 1.5, scale: 1.02)
                } else {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.somnaSuccess)
                            .somnaPulse(duration: 2.0, scale: 1.1)
                        Text("All permissions granted")
                            .foregroundColor(.somnaSuccess)
                            .fontWeight(.medium)
                    }
                    .padding(.top)
                }
            }
        }
    }
    
    private var healthDataTrainingStep: some View {
        VStack(spacing: 30) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 80))
                .foregroundColor(.somnaSecondary)
                .scaleEffect(isAnimating ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: isAnimating)
                .somnaPulse(duration: 2.0, scale: 1.1)
            
            VStack(spacing: 20) {
                Text("Personalize Your AI")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .somnaPulse(duration: 3.0, scale: 1.02)
                
                Text("Train the AI model on your historical Apple Health data to get personalized sleep insights from day one.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .somnaShimmer()
                
                if healthDataAvailable {
                    VStack(spacing: 15) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.somnaSuccess)
                                .somnaPulse(duration: 2.0, scale: 1.1)
                            Text("\(dataPointsCount) data points available")
                                .fontWeight(.medium)
                        }
                        
                        if showHealthDataTraining {
                            VStack(spacing: 12) {
                                SomnaProgressView(
                                    value: 0.7,
                                    color: .somnaPrimary,
                                    showPercentage: true
                                )
                                .frame(height: 8)
                                
                                Text("Training AI model...")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.somnaCardBackground)
                            )
                            .somnaShimmer()
                        } else {
                            Button("Start Training") {
                                showHealthDataTraining = true
                                startHealthDataTraining()
                            }
                            .buttonStyle(SomnaPrimaryButtonStyle())
                            .somnaPulse(duration: 1.5, scale: 1.02)
                        }
                    }
                } else {
                    Text("No historical health data available")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .somnaShimmer()
                }
            }
        }
    }
    
    private var finalStep: some View {
        VStack(spacing: 30) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.somnaSuccess)
                .scaleEffect(isAnimating ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: isAnimating)
                .somnaPulse(duration: 2.0, scale: 1.1)
            
            VStack(spacing: 20) {
                Text("You're All Set!")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .somnaPulse(duration: 3.0, scale: 1.02)
                
                Text("SomnaSync Pro is ready to optimize your sleep experience. Start your first sleep session when you're ready.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .somnaShimmer()
                
                Group {
                    if horizontalSizeClass == .regular {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 250))], spacing: 15) {
                            finalFeatureRows
                        }
                    } else {
                        VStack(alignment: .leading, spacing: 15) {
                            finalFeatureRows
                        }
                    }
                }
                .padding(.top)
            }
        }
    }

    private var featureRows: some View {
        Group {
            FeatureRow(icon: "brain.head.profile", title: "AI Sleep Analysis", description: "Advanced machine learning for personalized sleep insights")
                .somnaPulse(duration: 2.0, scale: 1.01)
            FeatureRow(icon: "waveform.path.ecg", title: "HealthKit Integration", description: "Seamless integration with Apple Health data")
                .somnaPulse(duration: 2.2, scale: 1.01)
            FeatureRow(icon: "speaker.wave.3", title: "Smart Audio", description: "Adaptive audio generation for optimal sleep")
                .somnaPulse(duration: 2.4, scale: 1.01)
            FeatureRow(icon: "alarm", title: "Smart Alarms", description: "Wake up at the perfect time in your sleep cycle")
                .somnaPulse(duration: 2.6, scale: 1.01)
        }
    }

    private var finalFeatureRows: some View {
        Group {
            FeatureRow(icon: "moon.stars.fill", title: "Sleep Tracking", description: "Advanced sleep stage analysis")
                .somnaPulse(duration: 2.0, scale: 1.01)
            FeatureRow(icon: "speaker.wave.3", title: "Smart Audio", description: "Personalized sleep sounds")
                .somnaPulse(duration: 2.2, scale: 1.01)
            FeatureRow(icon: "alarm", title: "Smart Alarms", description: "Optimal wake-up timing")
                .somnaPulse(duration: 2.4, scale: 1.01)
            FeatureRow(icon: "chart.line.uptrend.xyaxis", title: "AI Insights", description: "Personalized recommendations")
                .somnaPulse(duration: 2.6, scale: 1.01)
        }
    }
    
    // MARK: - Helper Methods
    
    private func checkHealthDataAvailability() {
        Task {
            let availability = await healthDataTrainer.checkDataAvailability()
            await MainActor.run {
                self.healthDataAvailable = availability.available
                self.dataPointsCount = availability.dataPoints
            }
        }
    }
    
    private func completeOnboarding() {
        appConfiguration.hasCompletedOnboarding = true
        appConfiguration.firstLaunchDate = Date()
        
        // Save any additional onboarding preferences
        UserDefaults.standard.set(true, forKey: "OnboardingCompleted")
        
        // Post notification to switch to main app
        NotificationCenter.default.post(name: .onboardingCompleted, object: nil)
    }
}

// MARK: - Supporting Views

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

struct PermissionRow: View {
    let icon: String
    let title: String
    let description: String
    let isGranted: Bool
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(isGranted ? .green : .orange)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: isGranted ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(isGranted ? .green : .red)
        }
    }
}

// MARK: - Button Styles

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.white)
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.blue)
            .cornerRadius(12)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.blue)
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(12)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Notification Extension

extension Notification.Name {
    static let onboardingCompleted = Notification.Name("OnboardingCompleted")
}

#Preview {
    OnboardingView()
} 
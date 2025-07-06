import SwiftUI
import HealthKit
import UserNotifications
import SwiftData

@available(iOS 17.0, *)
@available(macOS 14.0, *)

/// Enhanced OnboardingView with health data training
struct OnboardingView: View {
    @StateObject private var healthKitManager = HealthKitManager.shared
    @StateObject private var healthDataTrainer = HealthDataTrainer.shared
    @StateObject private var appConfiguration = AppConfiguration.shared
    @StateObject private var authManager = AuthenticationManager.shared
    @StateObject private var errorHandler = ErrorHandlingService.shared
    
    @State private var currentStep = 0
    @State private var showHealthDataTraining = false
    @State private var healthDataAvailable = false
    @State private var dataPointsCount = 0
    @State private var isAnimating = false
    @State private var displayName = ""
    @State private var dateOfBirth = Date()
    @State private var height: Double = 170.0
    @State private var weight: Double = 70.0
    @State private var gender = "Prefer not to say"
    @State private var notificationsEnabled = true
    @State private var healthKitEnabled = true
    @State private var isLoading = false
    
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    private let totalSteps = 4
    private let steps = ["Welcome", "Profile", "Health", "Permissions", "Complete"]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Progress indicator
                ProgressView(value: Double(currentStep + 1), total: Double(steps.count))
                    .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                    .padding()
                
                // Step content
                TabView(selection: $currentStep) {
                    welcomeStep
                        .tag(0)
                    
                    profileStep
                        .tag(1)
                    
                    healthStep
                        .tag(2)
                    
                    permissionsStep
                        .tag(3)
                    
                    completeStep
                        .tag(4)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentStep)
                
                // Navigation buttons
                HStack {
                    if currentStep > 0 {
                        Button("Back") {
                            withAnimation {
                                currentStep -= 1
                            }
                        }
                        .accessibilityLabel("Go to previous step")
                    }
                    
                    Spacer()
                    
                    if currentStep < steps.count - 1 {
                        Button("Next") {
                            withAnimation {
                                currentStep += 1
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(!canProceed)
                        .accessibilityLabel("Go to next step")
                    } else {
                        Button("Complete Setup") {
                            Task {
                                await completeOnboarding()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(isLoading)
                        .accessibilityLabel("Complete onboarding setup")
                    }
                }
                .padding()
            }
            .navigationTitle("Setup")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
        }
        .alert("Error", isPresented: $errorHandler.showingError) {
            Button("OK") { errorHandler.dismissError() }
        } message: {
            Text(errorHandler.currentErrorMessage)
        }
    }
    
    // MARK: - Step Views
    
    private var welcomeStep: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: "heart.text.square.fill")
                .font(.system(size: 100))
                .foregroundColor(.blue)
                .accessibilityHidden(true)
            
            VStack(spacing: 20) {
                Text("Welcome to HealthAI 2030")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .accessibilityAddTraits(.isHeader)
                
                Text("Your AI-powered health companion that helps you achieve optimal wellness through personalized insights and recommendations.")
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            Spacer()
        }
        .padding()
    }
    
    private var profileStep: some View {
        VStack(spacing: 30) {
            Text("Tell us about yourself")
                .font(.title)
                .fontWeight(.bold)
                .accessibilityAddTraits(.isHeader)
            
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Display Name")
                        .font(.headline)
                    TextField("Enter your name", text: $displayName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .accessibilityLabel("Enter your display name")
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Date of Birth")
                        .font(.headline)
                    DatePicker("Date of Birth", selection: $dateOfBirth, displayedComponents: .date)
                        .datePickerStyle(CompactDatePickerStyle())
                        .accessibilityLabel("Select your date of birth")
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Gender")
                        .font(.headline)
                    Picker("Gender", selection: $gender) {
                        Text("Prefer not to say").tag("Prefer not to say")
                        Text("Male").tag("Male")
                        Text("Female").tag("Female")
                        Text("Other").tag("Other")
                    }
                    .pickerStyle(MenuPickerStyle())
                    .accessibilityLabel("Select your gender")
                }
            }
            
            Spacer()
        }
        .padding()
    }
    
    private var healthStep: some View {
        VStack(spacing: 30) {
            Text("Health Information")
                .font(.title)
                .fontWeight(.bold)
                .accessibilityAddTraits(.isHeader)
            
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Height (cm)")
                        .font(.headline)
                    HStack {
                        Slider(value: $height, in: 100...250, step: 1)
                        Text("\(Int(height))")
                            .font(.headline)
                            .frame(width: 50)
                    }
                    .accessibilityLabel("Set your height in centimeters")
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Weight (kg)")
                        .font(.headline)
                    HStack {
                        Slider(value: $weight, in: 30...200, step: 0.5)
                        Text(String(format: "%.1f", weight))
                            .font(.headline)
                            .frame(width: 50)
                    }
                    .accessibilityLabel("Set your weight in kilograms")
                }
            }
            
            Spacer()
        }
        .padding()
    }
    
    private var permissionsStep: some View {
        VStack(spacing: 30) {
            Text("Permissions")
                .font(.title)
                .fontWeight(.bold)
                .accessibilityAddTraits(.isHeader)
            
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 15) {
                    Toggle("Enable Notifications", isOn: $notificationsEnabled)
                        .accessibilityLabel("Enable push notifications")
                    
                    Toggle("HealthKit Integration", isOn: $healthKitEnabled)
                        .accessibilityLabel("Enable HealthKit data sync")
                }
                
                Text("These permissions help us provide personalized health insights and recommendations. You can change these settings later.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            Spacer()
        }
        .padding()
    }
    
    private var completeStep: some View {
        VStack(spacing: 30) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)
                .accessibilityHidden(true)
            
            VStack(spacing: 20) {
                Text("You're all set!")
                    .font(.title)
                    .fontWeight(.bold)
                    .accessibilityAddTraits(.isHeader)
                
                Text("Your profile has been created and you're ready to start your health journey with AI-powered insights.")
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            if isLoading {
                ProgressView("Setting up your profile...")
                    .progressViewStyle(CircularProgressViewStyle())
            }
            
            Spacer()
        }
        .padding()
    }
    
    private var canProceed: Bool {
        switch currentStep {
        case 0: return true
        case 1: return !displayName.isEmpty
        case 2: return height > 0 && weight > 0
        case 3: return true
        default: return true
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
    
    private func completeOnboarding() async {
        guard let user = authManager.currentUser else { return }
        
        isLoading = true
        
        do {
            // Update user profile with onboarding data
            user.updateProfile(
                displayName: displayName,
                dateOfBirth: dateOfBirth,
                height: height,
                weight: weight,
                gender: gender
            )
            
            // Update preferences
            user.preferences.notificationsEnabled = notificationsEnabled
            user.preferences.healthKitSyncEnabled = healthKitEnabled
            
            // Mark onboarding as completed
            user.completeOnboarding()
            
            // Save to SwiftData
            if let modelContext = try? ModelContext(for: UserProfile.self) {
                try modelContext.save()
            }
            
            logger.info("Onboarding completed for user: \(user.email)")
            
        } catch {
            errorHandler.handle(OnboardingError.completionFailed(error), userMessage: "Failed to complete setup")
        }
        
        isLoading = false
    }
}

// MARK: - Onboarding Errors
enum OnboardingError: Int, AppError {
    case completionFailed = 4001
    
    var errorDescription: String? {
        switch self {
        case .completionFailed(let error):
            return "Failed to complete onboarding: \(error.localizedDescription)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .completionFailed:
            return "Please try again or contact support if the problem persists"
        }
    }
    
    var errorCode: Int { rawValue }
    var domain: String { "com.HealthAI2030.Onboarding" }
    static var errorDomain: String { "com.HealthAI2030.Onboarding" }
}

#Preview {
    OnboardingView()
        .modelContainer(for: [UserProfile.self, HealthData.self, DigitalTwin.self], isCloudKitEnabled: true)
}
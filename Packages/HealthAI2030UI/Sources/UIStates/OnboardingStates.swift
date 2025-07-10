import SwiftUI

// MARK: - Onboarding States
/// Comprehensive onboarding state components for HealthAI 2030
/// Provides onboarding and tutorial states for new users
public struct OnboardingStates {
    
    // MARK: - Welcome Onboarding
    
    /// Welcome screen for new users
    public struct WelcomeOnboardingState: View {
        let userName: String?
        let continueAction: () -> Void
        let skipAction: (() -> Void)?
        
        public init(
            userName: String? = nil,
            continueAction: @escaping () -> Void,
            skipAction: (() -> Void)? = nil
        ) {
            self.userName = userName
            self.continueAction = continueAction
            self.skipAction = skipAction
        }
        
        public var body: some View {
            VStack(spacing: 32) {
                Spacer()
                
                // App icon and title
                VStack(spacing: 24) {
                    Image(systemName: "heart.text.square.fill")
                        .font(.system(size: 100))
                        .foregroundColor(.blue)
                        .scaleEffect(1.0)
                        .animation(.spring(response: 0.8, dampingFraction: 0.6), value: true)
                    
                    VStack(spacing: 8) {
                        Text("Welcome to HealthAI 2030")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.center)
                        
                        if let userName = userName {
                            Text("Hello, \(userName)!")
                                .font(.title2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // Welcome message
                VStack(spacing: 16) {
                    Text("Your AI-Powered Health Companion")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                    
                    Text("Get personalized health insights, track your wellness journey, and achieve your health goals with the power of artificial intelligence.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                
                Spacer()
                
                // Action buttons
                VStack(spacing: 16) {
                    Button(action: continueAction) {
                        HStack(spacing: 8) {
                            Text("Get Started")
                                .font(.headline)
                                .fontWeight(.semibold)
                            Image(systemName: "arrow.right")
                                .font(.headline)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.blue)
                        .cornerRadius(12)
                    }
                    
                    if let skipAction = skipAction {
                        Button(action: skipAction) {
                            Text("Skip for Now")
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.horizontal, 32)
            }
            .padding(.vertical, 40)
        }
    }
    
    // MARK: - Feature Introduction
    
    /// Feature introduction carousel
    public struct FeatureIntroductionState: View {
        let features: [OnboardingFeature]
        let currentIndex: Int
        let nextAction: () -> Void
        let previousAction: () -> Void
        let skipAction: (() -> Void)?
        let completeAction: (() -> Void)?
        
        public init(
            features: [OnboardingFeature],
            currentIndex: Int,
            nextAction: @escaping () -> Void,
            previousAction: @escaping () -> Void,
            skipAction: (() -> Void)? = nil,
            completeAction: (() -> Void)? = nil
        ) {
            self.features = features
            self.currentIndex = currentIndex
            self.nextAction = nextAction
            self.previousAction = previousAction
            self.skipAction = skipAction
            self.completeAction = completeAction
        }
        
        public var body: some View {
            VStack(spacing: 32) {
                // Skip button
                if let skipAction = skipAction {
                    HStack {
                        Spacer()
                        Button(action: skipAction) {
                            Text("Skip")
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal, 32)
                }
                
                Spacer()
                
                // Feature content
                if currentIndex < features.count {
                    let feature = features[currentIndex]
                    
                    VStack(spacing: 32) {
                        // Feature illustration
                        Image(systemName: feature.icon)
                            .font(.system(size: 100))
                            .foregroundColor(feature.color)
                            .scaleEffect(1.0)
                            .animation(.spring(response: 0.8, dampingFraction: 0.6), value: currentIndex)
                        
                        // Feature content
                        VStack(spacing: 16) {
                            Text(feature.title)
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                                .multilineTextAlignment(.center)
                            
                            Text(feature.description)
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                        }
                    }
                }
                
                Spacer()
                
                // Progress indicator
                HStack(spacing: 8) {
                    ForEach(0..<features.count, id: \.self) { index in
                        Circle()
                            .fill(index == currentIndex ? Color.blue : Color(.systemGray4))
                            .frame(width: 8, height: 8)
                            .scaleEffect(index == currentIndex ? 1.2 : 1.0)
                            .animation(.easeInOut(duration: 0.3), value: currentIndex)
                    }
                }
                
                // Navigation buttons
                HStack(spacing: 16) {
                    if currentIndex > 0 {
                        Button(action: previousAction) {
                            HStack(spacing: 8) {
                                Image(systemName: "chevron.left")
                                Text("Previous")
                            }
                            .font(.headline)
                            .foregroundColor(.blue)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                    
                    Spacer()
                    
                    if currentIndex < features.count - 1 {
                        Button(action: nextAction) {
                            HStack(spacing: 8) {
                                Text("Next")
                                Image(systemName: "chevron.right")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(Color.blue)
                            .cornerRadius(8)
                        }
                    } else if let completeAction = completeAction {
                        Button(action: completeAction) {
                            HStack(spacing: 8) {
                                Text("Get Started")
                                Image(systemName: "checkmark")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(Color.green)
                            .cornerRadius(8)
                        }
                    }
                }
                .padding(.horizontal, 32)
            }
            .padding(.vertical, 40)
        }
    }
    
    // MARK: - Permission Request
    
    /// Health data permission request
    public struct PermissionRequestState: View {
        let permissions: [HealthPermission]
        let grantedPermissions: Set<HealthPermission>
        let requestAction: (HealthPermission) -> Void
        let continueAction: () -> Void
        let skipAction: (() -> Void)?
        
        public init(
            permissions: [HealthPermission],
            grantedPermissions: Set<HealthPermission>,
            requestAction: @escaping (HealthPermission) -> Void,
            continueAction: @escaping () -> Void,
            skipAction: (() -> Void)? = nil
        ) {
            self.permissions = permissions
            self.grantedPermissions = grantedPermissions
            self.requestAction = requestAction
            self.continueAction = continueAction
            self.skipAction = skipAction
        }
        
        public var body: some View {
            VStack(spacing: 32) {
                // Header
                VStack(spacing: 16) {
                    Image(systemName: "lock.shield")
                        .font(.system(size: 80))
                        .foregroundColor(.blue)
                    
                    Text("Health Data Access")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("To provide personalized insights, we need access to your health data. You can control what data you share.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                
                // Permission list
                VStack(spacing: 16) {
                    ForEach(permissions, id: \.self) { permission in
                        PermissionRow(
                            permission: permission,
                            isGranted: grantedPermissions.contains(permission),
                            requestAction: requestAction
                        )
                    }
                }
                .padding(.horizontal, 32)
                
                Spacer()
                
                // Action buttons
                VStack(spacing: 16) {
                    Button(action: continueAction) {
                        Text("Continue")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.blue)
                            .cornerRadius(12)
                    }
                    
                    if let skipAction = skipAction {
                        Button(action: skipAction) {
                            Text("Skip for Now")
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.horizontal, 32)
            }
            .padding(.vertical, 40)
        }
    }
    
    // MARK: - Device Setup
    
    /// Device setup and connection
    public struct DeviceSetupState: View {
        let devices: [HealthDevice]
        let connectedDevices: Set<String>
        let connectAction: (HealthDevice) -> Void
        let continueAction: () -> Void
        let skipAction: (() -> Void)?
        
        public init(
            devices: [HealthDevice],
            connectedDevices: Set<String>,
            connectAction: @escaping (HealthDevice) -> Void,
            continueAction: @escaping () -> Void,
            skipAction: (() -> Void)? = nil
        ) {
            self.devices = devices
            self.connectedDevices = connectedDevices
            self.connectAction = connectAction
            self.continueAction = continueAction
            self.skipAction = skipAction
        }
        
        public var body: some View {
            VStack(spacing: 32) {
                // Header
                VStack(spacing: 16) {
                    Image(systemName: "iphone")
                        .font(.system(size: 80))
                        .foregroundColor(.blue)
                    
                    Text("Connect Your Devices")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("Connect your health devices to automatically sync your data and get comprehensive insights.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                
                // Device list
                VStack(spacing: 16) {
                    ForEach(devices, id: \.id) { device in
                        DeviceRow(
                            device: device,
                            isConnected: connectedDevices.contains(device.id),
                            connectAction: connectAction
                        )
                    }
                }
                .padding(.horizontal, 32)
                
                Spacer()
                
                // Action buttons
                VStack(spacing: 16) {
                    Button(action: continueAction) {
                        Text("Continue")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.blue)
                            .cornerRadius(12)
                    }
                    
                    if let skipAction = skipAction {
                        Button(action: skipAction) {
                            Text("Skip for Now")
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.horizontal, 32)
            }
            .padding(.vertical, 40)
        }
    }
    
    // MARK: - Completion State
    
    /// Onboarding completion state
    public struct CompletionState: View {
        let userName: String?
        let startAction: () -> Void
        
        public init(
            userName: String? = nil,
            startAction: @escaping () -> Void
        ) {
            self.userName = userName
            self.startAction = startAction
        }
        
        public var body: some View {
            VStack(spacing: 32) {
                Spacer()
                
                // Success illustration
                VStack(spacing: 24) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 100))
                        .foregroundColor(.green)
                        .scaleEffect(1.0)
                        .animation(.spring(response: 0.8, dampingFraction: 0.6), value: true)
                    
                    VStack(spacing: 8) {
                        Text("You're All Set!")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        if let userName = userName {
                            Text("Welcome to HealthAI 2030, \(userName)!")
                                .font(.title2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // Completion message
                VStack(spacing: 16) {
                    Text("Your AI health companion is ready to help you achieve your wellness goals.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                    
                    Text("Start your health journey today!")
                        .font(.headline)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                // Start button
                Button(action: startAction) {
                    HStack(spacing: 8) {
                        Text("Start My Health Journey")
                            .font(.headline)
                            .fontWeight(.semibold)
                        Image(systemName: "arrow.right")
                            .font(.headline)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.green)
                    .cornerRadius(12)
                }
                .padding(.horizontal, 32)
            }
            .padding(.vertical, 40)
        }
    }
}

// MARK: - Supporting Views

/// Permission row component
private struct PermissionRow: View {
    let permission: HealthPermission
    let isGranted: Bool
    let requestAction: (HealthPermission) -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: permission.icon)
                .font(.title2)
                .foregroundColor(permission.color)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(permission.title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(permission.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if isGranted {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.title2)
            } else {
                Button(action: { requestAction(permission) }) {
                    Text("Allow")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(permission.color)
                        .cornerRadius(6)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

/// Device row component
private struct DeviceRow: View {
    let device: HealthDevice
    let isConnected: Bool
    let connectAction: (HealthDevice) -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: device.icon)
                .font(.title2)
                .foregroundColor(device.color)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(device.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(device.type)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if isConnected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.title2)
            } else {
                Button(action: { connectAction(device) }) {
                    Text("Connect")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(device.color)
                        .cornerRadius(6)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Supporting Types

/// Onboarding feature model
public struct OnboardingFeature {
    let icon: String
    let title: String
    let description: String
    let color: Color
    
    public init(icon: String, title: String, description: String, color: Color) {
        self.icon = icon
        self.title = title
        self.description = description
        self.color = color
    }
}

/// Health permission model
public enum HealthPermission: CaseIterable {
    case healthKit
    case notifications
    case location
    case camera
    case microphone
    
    var title: String {
        switch self {
        case .healthKit:
            return "Health Data"
        case .notifications:
            return "Notifications"
        case .location:
            return "Location"
        case .camera:
            return "Camera"
        case .microphone:
            return "Microphone"
        }
    }
    
    var description: String {
        switch self {
        case .healthKit:
            return "Access to your health and fitness data"
        case .notifications:
            return "Receive health reminders and updates"
        case .location:
            return "Location-based health insights"
        case .camera:
            return "Scan health documents and QR codes"
        case .microphone:
            return "Voice commands and health assessments"
        }
    }
    
    var icon: String {
        switch self {
        case .healthKit:
            return "heart.fill"
        case .notifications:
            return "bell.fill"
        case .location:
            return "location.fill"
        case .camera:
            return "camera.fill"
        case .microphone:
            return "mic.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .healthKit:
            return .red
        case .notifications:
            return .orange
        case .location:
            return .blue
        case .camera:
            return .purple
        case .microphone:
            return .green
        }
    }
}

/// Health device model
public struct HealthDevice: Identifiable {
    public let id: String
    public let name: String
    public let type: String
    public let icon: String
    public let color: Color
    
    public init(id: String, name: String, type: String, icon: String, color: Color) {
        self.id = id
        self.name = name
        self.type = type
        self.icon = icon
        self.color = color
    }
}

// MARK: - Extensions

public extension OnboardingStates {
    /// Create default onboarding features
    static func defaultFeatures() -> [OnboardingFeature] {
        return [
            OnboardingFeature(
                icon: "brain.head.profile",
                title: "AI-Powered Insights",
                description: "Get personalized health recommendations and insights powered by advanced artificial intelligence.",
                color: .blue
            ),
            OnboardingFeature(
                icon: "chart.line.uptrend.xyaxis",
                title: "Smart Analytics",
                description: "Track your health trends and progress with intelligent analytics and predictive modeling.",
                color: .green
            ),
            OnboardingFeature(
                icon: "heart.fill",
                title: "Comprehensive Health",
                description: "Monitor all aspects of your health from physical activity to mental wellness.",
                color: .red
            ),
            OnboardingFeature(
                icon: "shield.fill",
                title: "Privacy & Security",
                description: "Your health data is protected with enterprise-grade security and privacy controls.",
                color: .purple
            )
        ]
    }
    
    /// Create default health devices
    static func defaultDevices() -> [HealthDevice] {
        return [
            HealthDevice(id: "apple-watch", name: "Apple Watch", type: "Smartwatch", icon: "applewatch", color: .blue),
            HealthDevice(id: "iphone", name: "iPhone", type: "Smartphone", icon: "iphone", color: .blue),
            HealthDevice(id: "airpods", name: "AirPods", type: "Earbuds", icon: "airpods", color: .gray),
            HealthDevice(id: "ipad", name: "iPad", type: "Tablet", icon: "ipad", color: .blue)
        ]
    }
} 
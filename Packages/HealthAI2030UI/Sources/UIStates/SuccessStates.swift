import SwiftUI

// MARK: - Success States
/// Comprehensive success state components for HealthAI 2030
/// Provides success and completion states for various health operations
public struct SuccessStates {
    
    // MARK: - Data Operation Success States
    
    /// Data saved successfully state
    public struct DataSavedSuccessState: View {
        let dataType: String
        let message: String?
        let action: (() -> Void)?
        let actionTitle: String?
        
        public init(
            dataType: String,
            message: String? = nil,
            action: (() -> Void)? = nil,
            actionTitle: String? = nil
        ) {
            self.dataType = dataType
            self.message = message
            self.action = action
            self.actionTitle = actionTitle
        }
        
        public var body: some View {
            VStack(spacing: 24) {
                // Success illustration
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.green)
                    .scaleEffect(1.0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: true)
                
                Text("\(dataType) Saved Successfully")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                
                Text(message ?? "Your \(dataType.lowercased()) data has been saved and is now available for analysis.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                
                if let action = action, let actionTitle = actionTitle {
                    Button(action: action) {
                        Text(actionTitle)
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(Color.green)
                            .cornerRadius(8)
                    }
                }
            }
            .padding(40)
        }
    }
    
    /// Data synced successfully state
    public struct DataSyncedSuccessState: View {
        let dataType: String
        let syncCount: Int?
        let action: (() -> Void)?
        
        public init(
            dataType: String,
            syncCount: Int? = nil,
            action: (() -> Void)? = nil
        ) {
            self.dataType = dataType
            self.syncCount = syncCount
            self.action = action
        }
        
        public var body: some View {
            VStack(spacing: 24) {
                // Success illustration
                Image(systemName: "arrow.triangle.2.circlepath.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                    .rotationEffect(.degrees(360))
                    .animation(.linear(duration: 1.0), value: true)
                
                Text("\(dataType) Synced Successfully")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                
                if let syncCount = syncCount {
                    Text("\(syncCount) new records synced")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                } else {
                    Text("Your \(dataType.lowercased()) data has been successfully synchronized with the cloud.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                
                if let action = action {
                    Button(action: action) {
                        HStack(spacing: 8) {
                            Image(systemName: "eye.fill")
                            Text("View Data")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.blue)
                        .cornerRadius(8)
                    }
                }
            }
            .padding(40)
        }
    }
    
    // MARK: - Goal Achievement Success States
    
    /// Goal achieved success state
    public struct GoalAchievedSuccessState: View {
        let goalName: String
        let achievement: String
        let celebration: Bool
        let action: (() -> Void)?
        
        public init(
            goalName: String,
            achievement: String,
            celebration: Bool = true,
            action: (() -> Void)? = nil
        ) {
            self.goalName = goalName
            self.achievement = achievement
            self.celebration = celebration
            self.action = action
        }
        
        public var body: some View {
            VStack(spacing: 24) {
                // Celebration illustration
                if celebration {
                    Image(systemName: "star.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.yellow)
                        .scaleEffect(1.2)
                        .animation(.easeInOut(duration: 0.5).repeatCount(3), value: celebration)
                } else {
                    Image(systemName: "target")
                        .font(.system(size: 80))
                        .foregroundColor(.green)
                }
                
                Text("Goal Achieved!")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                
                Text(goalName)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.green)
                    .multilineTextAlignment(.center)
                
                Text(achievement)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                
                if let action = action {
                    Button(action: action) {
                        HStack(spacing: 8) {
                            Image(systemName: "plus.circle.fill")
                            Text("Set New Goal")
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
            .padding(40)
        }
    }
    
    /// Streak milestone success state
    public struct StreakMilestoneSuccessState: View {
        let streakType: String
        let streakCount: Int
        let action: (() -> Void)?
        
        public init(
            streakType: String,
            streakCount: Int,
            action: (() -> Void)? = nil
        ) {
            self.streakType = streakType
            self.streakCount = streakCount
            self.action = action
        }
        
        public var body: some View {
            VStack(spacing: 24) {
                // Streak illustration
                Image(systemName: "flame.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.orange)
                    .scaleEffect(1.1)
                    .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: true)
                
                Text("Streak Milestone!")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                
                Text("\(streakCount) Day \(streakType) Streak")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.orange)
                    .multilineTextAlignment(.center)
                
                Text("Congratulations! You've maintained your \(streakType.lowercased()) streak for \(streakCount) days. Keep up the great work!")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                
                if let action = action {
                    Button(action: action) {
                        HStack(spacing: 8) {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                            Text("View Progress")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.orange)
                        .cornerRadius(8)
                    }
                }
            }
            .padding(40)
        }
    }
    
    // MARK: - Device Connection Success States
    
    /// Device connected successfully state
    public struct DeviceConnectedSuccessState: View {
        let deviceName: String
        let deviceType: String
        let action: (() -> Void)?
        
        public init(
            deviceName: String,
            deviceType: String,
            action: (() -> Void)? = nil
        ) {
            self.deviceName = deviceName
            self.deviceType = deviceType
            self.action = action
        }
        
        public var body: some View {
            VStack(spacing: 24) {
                // Device illustration
                Image(systemName: "checkmark.shield.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.green)
                    .scaleEffect(1.0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: true)
                
                Text("Device Connected!")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                
                Text("\(deviceName) (\(deviceType))")
                    .font(.title3)
                    .fontWeight(.medium)
                    .foregroundColor(.green)
                    .multilineTextAlignment(.center)
                
                Text("Your device has been successfully connected and is ready to sync health data.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                
                if let action = action {
                    Button(action: action) {
                        HStack(spacing: 8) {
                            Image(systemName: "gear")
                            Text("Device Settings")
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
            .padding(40)
        }
    }
    
    // MARK: - Health Improvement Success States
    
    /// Health improvement success state
    public struct HealthImprovementSuccessState: View {
        let improvement: String
        let metric: String
        let value: String
        let action: (() -> Void)?
        
        public init(
            improvement: String,
            metric: String,
            value: String,
            action: (() -> Void)? = nil
        ) {
            self.improvement = improvement
            self.metric = metric
            self.value = value
            self.action = action
        }
        
        public var body: some View {
            VStack(spacing: 24) {
                // Improvement illustration
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.green)
                    .scaleEffect(1.1)
                    .animation(.easeInOut(duration: 0.8).repeatCount(2), value: true)
                
                Text("Health Improvement!")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                
                Text(improvement)
                    .font(.title3)
                    .fontWeight(.medium)
                    .foregroundColor(.green)
                    .multilineTextAlignment(.center)
                
                VStack(spacing: 8) {
                    Text(metric)
                        .font(.body)
                        .foregroundColor(.secondary)
                    
                    Text(value)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                }
                
                if let action = action {
                    Button(action: action) {
                        HStack(spacing: 8) {
                            Image(systemName: "chart.bar.fill")
                            Text("View Details")
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
            .padding(40)
        }
    }
    
    // MARK: - Generic Success State
    
    /// Generic success state component
    public struct GenericSuccessState: View {
        let icon: String
        let title: String
        let message: String
        let actionTitle: String?
        let action: (() -> Void)?
        let iconColor: Color
        
        public init(
            icon: String,
            title: String,
            message: String,
            actionTitle: String? = nil,
            action: (() -> Void)? = nil,
            iconColor: Color = .green
        ) {
            self.icon = icon
            self.title = title
            self.message = message
            self.actionTitle = actionTitle
            self.action = action
            self.iconColor = iconColor
        }
        
        public var body: some View {
            VStack(spacing: 24) {
                // Icon
                Image(systemName: icon)
                    .font(.system(size: 80))
                    .foregroundColor(iconColor)
                    .scaleEffect(1.0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: true)
                
                // Title
                Text(title)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                
                // Message
                Text(message)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                
                // Action button
                if let actionTitle = actionTitle, let action = action {
                    Button(action: action) {
                        Text(actionTitle)
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(iconColor)
                            .cornerRadius(8)
                    }
                }
            }
            .padding(40)
        }
    }
}

// MARK: - Extensions

public extension SuccessStates {
    /// Create data saved success state
    static func dataSaved(
        dataType: String,
        message: String? = nil,
        action: (() -> Void)? = nil,
        actionTitle: String? = nil
    ) -> some View {
        DataSavedSuccessState(
            dataType: dataType,
            message: message,
            action: action,
            actionTitle: actionTitle
        )
    }
    
    /// Create goal achieved success state
    static func goalAchieved(
        goalName: String,
        achievement: String,
        celebration: Bool = true,
        action: (() -> Void)? = nil
    ) -> some View {
        GoalAchievedSuccessState(
            goalName: goalName,
            achievement: achievement,
            celebration: celebration,
            action: action
        )
    }
    
    /// Create streak milestone success state
    static func streakMilestone(
        streakType: String,
        streakCount: Int,
        action: (() -> Void)? = nil
    ) -> some View {
        StreakMilestoneSuccessState(
            streakType: streakType,
            streakCount: streakCount,
            action: action
        )
    }
    
    /// Create device connected success state
    static func deviceConnected(
        deviceName: String,
        deviceType: String,
        action: (() -> Void)? = nil
    ) -> some View {
        DeviceConnectedSuccessState(
            deviceName: deviceName,
            deviceType: deviceType,
            action: action
        )
    }
    
    /// Create health improvement success state
    static func healthImprovement(
        improvement: String,
        metric: String,
        value: String,
        action: (() -> Void)? = nil
    ) -> some View {
        HealthImprovementSuccessState(
            improvement: improvement,
            metric: metric,
            value: value,
            action: action
        )
    }
} 
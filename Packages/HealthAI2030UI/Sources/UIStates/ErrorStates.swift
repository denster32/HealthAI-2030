import SwiftUI

// MARK: - Error States
/// Comprehensive error state components for HealthAI 2030
/// Provides error state components and recovery options for various scenarios
public struct ErrorStates {
    
    // MARK: - Network Error States
    
    /// Network connection error state
    public struct NetworkErrorState: View {
        let error: Error?
        let retryAction: (() -> Void)?
        let offlineAction: (() -> Void)?
        
        public init(
            error: Error? = nil,
            retryAction: (() -> Void)? = nil,
            offlineAction: (() -> Void)? = nil
        ) {
            self.error = error
            self.retryAction = retryAction
            self.offlineAction = offlineAction
        }
        
        public var body: some View {
            VStack(spacing: 24) {
                // Error illustration
                Image(systemName: "wifi.slash")
                    .font(.system(size: 80))
                    .foregroundColor(.red)
                    .opacity(0.6)
                
                Text("Connection Error")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text("Unable to connect to the server. Please check your internet connection and try again.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                
                if let error = error {
                    Text(error.localizedDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                
                HStack(spacing: 16) {
                    if let retryAction = retryAction {
                        Button(action: retryAction) {
                            HStack(spacing: 8) {
                                Image(systemName: "arrow.clockwise")
                                Text("Retry")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(Color.blue)
                            .cornerRadius(8)
                        }
                    }
                    
                    if let offlineAction = offlineAction {
                        Button(action: offlineAction) {
                            HStack(spacing: 8) {
                                Image(systemName: "iphone")
                                Text("Offline Mode")
                            }
                            .font(.headline)
                            .foregroundColor(.blue)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                }
            }
            .padding(40)
        }
    }
    
    /// Data sync error state
    public struct DataSyncErrorState: View {
        let error: Error?
        let retryAction: (() -> Void)?
        let manualSyncAction: (() -> Void)?
        
        public init(
            error: Error? = nil,
            retryAction: (() -> Void)? = nil,
            manualSyncAction: (() -> Void)? = nil
        ) {
            self.error = error
            self.retryAction = retryAction
            self.manualSyncAction = manualSyncAction
        }
        
        public var body: some View {
            VStack(spacing: 24) {
                // Error illustration
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.orange)
                    .opacity(0.6)
                
                Text("Sync Error")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text("Unable to sync your health data. Some data may be out of date.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                
                if let error = error {
                    Text(error.localizedDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                
                HStack(spacing: 16) {
                    if let retryAction = retryAction {
                        Button(action: retryAction) {
                            HStack(spacing: 8) {
                                Image(systemName: "arrow.clockwise")
                                Text("Retry Sync")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(Color.blue)
                            .cornerRadius(8)
                        }
                    }
                    
                    if let manualSyncAction = manualSyncAction {
                        Button(action: manualSyncAction) {
                            HStack(spacing: 8) {
                                Image(systemName: "hand.tap.fill")
                                Text("Manual Sync")
                            }
                            .font(.headline)
                            .foregroundColor(.orange)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                }
            }
            .padding(40)
        }
    }
    
    // MARK: - Data Error States
    
    /// Invalid data error state
    public struct InvalidDataErrorState: View {
        let dataType: String
        let error: Error?
        let retryAction: (() -> Void)?
        let editAction: (() -> Void)?
        
        public init(
            dataType: String,
            error: Error? = nil,
            retryAction: (() -> Void)? = nil,
            editAction: (() -> Void)? = nil
        ) {
            self.dataType = dataType
            self.error = error
            self.retryAction = retryAction
            self.editAction = editAction
        }
        
        public var body: some View {
            VStack(spacing: 24) {
                // Error illustration
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 80))
                    .foregroundColor(.orange)
                    .opacity(0.6)
                
                Text("Invalid \(dataType) Data")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text("The \(dataType) data appears to be invalid or corrupted. Please check and correct the information.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                
                if let error = error {
                    Text(error.localizedDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                
                HStack(spacing: 16) {
                    if let editAction = editAction {
                        Button(action: editAction) {
                            HStack(spacing: 8) {
                                Image(systemName: "pencil")
                                Text("Edit Data")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(Color.blue)
                            .cornerRadius(8)
                        }
                    }
                    
                    if let retryAction = retryAction {
                        Button(action: retryAction) {
                            HStack(spacing: 8) {
                                Image(systemName: "arrow.clockwise")
                                Text("Retry")
                            }
                            .font(.headline)
                            .foregroundColor(.orange)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                }
            }
            .padding(40)
        }
    }
    
    /// Data corruption error state
    public struct DataCorruptionErrorState: View {
        let dataType: String
        let backupAction: (() -> Void)?
        let resetAction: (() -> Void)?
        
        public init(
            dataType: String,
            backupAction: (() -> Void)? = nil,
            resetAction: (() -> Void)? = nil
        ) {
            self.dataType = dataType
            self.backupAction = backupAction
            self.resetAction = resetAction
        }
        
        public var body: some View {
            VStack(spacing: 24) {
                // Error illustration
                Image(systemName: "exclamationmark.octagon.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.red)
                    .opacity(0.6)
                
                Text("Data Corruption Detected")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text("The \(dataType) data has been corrupted. We can attempt to restore from backup or reset the data.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                
                VStack(spacing: 16) {
                    if let backupAction = backupAction {
                        Button(action: backupAction) {
                            HStack(spacing: 8) {
                                Image(systemName: "arrow.clockwise.circle.fill")
                                Text("Restore from Backup")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(Color.green)
                            .cornerRadius(8)
                        }
                    }
                    
                    if let resetAction = resetAction {
                        Button(action: resetAction) {
                            HStack(spacing: 8) {
                                Image(systemName: "trash.fill")
                                Text("Reset Data")
                            }
                            .font(.headline)
                            .foregroundColor(.red)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                }
            }
            .padding(40)
        }
    }
    
    // MARK: - Permission Error States
    
    /// Health data permission error state
    public struct HealthPermissionErrorState: View {
        let permissionType: HealthPermissionType
        let settingsAction: (() -> Void)?
        let learnMoreAction: (() -> Void)?
        
        public init(
            permissionType: HealthPermissionType,
            settingsAction: (() -> Void)? = nil,
            learnMoreAction: (() -> Void)? = nil
        ) {
            self.permissionType = permissionType
            self.settingsAction = settingsAction
            self.learnMoreAction = learnMoreAction
        }
        
        public var body: some View {
            VStack(spacing: 24) {
                // Error illustration
                Image(systemName: "lock.shield")
                    .font(.system(size: 80))
                    .foregroundColor(.orange)
                    .opacity(0.6)
                
                Text("Permission Required")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text("We need \(permissionType.description) permission to provide you with personalized health insights.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                
                HStack(spacing: 16) {
                    if let settingsAction = settingsAction {
                        Button(action: settingsAction) {
                            HStack(spacing: 8) {
                                Image(systemName: "gear")
                                Text("Open Settings")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(Color.blue)
                            .cornerRadius(8)
                        }
                    }
                    
                    if let learnMoreAction = learnMoreAction {
                        Button(action: learnMoreAction) {
                            HStack(spacing: 8) {
                                Image(systemName: "info.circle")
                                Text("Learn More")
                            }
                            .font(.headline)
                            .foregroundColor(.blue)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                }
            }
            .padding(40)
        }
    }
    
    // MARK: - Device Error States
    
    /// Device connection error state
    public struct DeviceConnectionErrorState: View {
        let deviceName: String
        let error: Error?
        let retryAction: (() -> Void)?
        let troubleshootAction: (() -> Void)?
        
        public init(
            deviceName: String,
            error: Error? = nil,
            retryAction: (() -> Void)? = nil,
            troubleshootAction: (() -> Void)? = nil
        ) {
            self.deviceName = deviceName
            self.error = error
            self.retryAction = retryAction
            self.troubleshootAction = troubleshootAction
        }
        
        public var body: some View {
            VStack(spacing: 24) {
                // Error illustration
                Image(systemName: "iphone.slash")
                    .font(.system(size: 80))
                    .foregroundColor(.red)
                    .opacity(0.6)
                
                Text("Device Connection Failed")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text("Unable to connect to \(deviceName). Please check the device and try again.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                
                if let error = error {
                    Text(error.localizedDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                
                HStack(spacing: 16) {
                    if let retryAction = retryAction {
                        Button(action: retryAction) {
                            HStack(spacing: 8) {
                                Image(systemName: "arrow.clockwise")
                                Text("Retry")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(Color.blue)
                            .cornerRadius(8)
                        }
                    }
                    
                    if let troubleshootAction = troubleshootAction {
                        Button(action: troubleshootAction) {
                            HStack(spacing: 8) {
                                Image(systemName: "wrench.and.screwdriver")
                                Text("Troubleshoot")
                            }
                            .font(.headline)
                            .foregroundColor(.orange)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                }
            }
            .padding(40)
        }
    }
    
    // MARK: - Generic Error State
    
    /// Generic error state component
    public struct GenericErrorState: View {
        let icon: String
        let title: String
        let message: String
        let error: Error?
        let primaryActionTitle: String?
        let primaryAction: (() -> Void)?
        let secondaryActionTitle: String?
        let secondaryAction: (() -> Void)?
        let iconColor: Color
        
        public init(
            icon: String,
            title: String,
            message: String,
            error: Error? = nil,
            primaryActionTitle: String? = nil,
            primaryAction: (() -> Void)? = nil,
            secondaryActionTitle: String? = nil,
            secondaryAction: (() -> Void)? = nil,
            iconColor: Color = .red
        ) {
            self.icon = icon
            self.title = title
            self.message = message
            self.error = error
            self.primaryActionTitle = primaryActionTitle
            self.primaryAction = primaryAction
            self.secondaryActionTitle = secondaryActionTitle
            self.secondaryAction = secondaryAction
            self.iconColor = iconColor
        }
        
        public var body: some View {
            VStack(spacing: 24) {
                // Icon
                Image(systemName: icon)
                    .font(.system(size: 80))
                    .foregroundColor(iconColor)
                    .opacity(0.6)
                
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
                
                // Error details
                if let error = error {
                    Text(error.localizedDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                
                // Action buttons
                HStack(spacing: 16) {
                    if let primaryActionTitle = primaryActionTitle, let primaryAction = primaryAction {
                        Button(action: primaryAction) {
                            Text(primaryActionTitle)
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(iconColor)
                                .cornerRadius(8)
                        }
                    }
                    
                    if let secondaryActionTitle = secondaryActionTitle, let secondaryAction = secondaryAction {
                        Button(action: secondaryAction) {
                            Text(secondaryActionTitle)
                                .font(.headline)
                                .foregroundColor(iconColor)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(iconColor.opacity(0.1))
                                .cornerRadius(8)
                        }
                    }
                }
            }
            .padding(40)
        }
    }
}

// MARK: - Supporting Types

public enum HealthPermissionType {
    case healthKit
    case notifications
    case location
    case camera
    case microphone
    case custom(String)
    
    var description: String {
        switch self {
        case .healthKit:
            return "HealthKit"
        case .notifications:
            return "notification"
        case .location:
            return "location"
        case .camera:
            return "camera"
        case .microphone:
            return "microphone"
        case .custom(let name):
            return name
        }
    }
}

// MARK: - Extensions

public extension ErrorStates {
    /// Create network error state
    static func networkError(
        error: Error? = nil,
        retryAction: (() -> Void)? = nil,
        offlineAction: (() -> Void)? = nil
    ) -> some View {
        NetworkErrorState(
            error: error,
            retryAction: retryAction,
            offlineAction: offlineAction
        )
    }
    
    /// Create data sync error state
    static func dataSyncError(
        error: Error? = nil,
        retryAction: (() -> Void)? = nil,
        manualSyncAction: (() -> Void)? = nil
    ) -> some View {
        DataSyncErrorState(
            error: error,
            retryAction: retryAction,
            manualSyncAction: manualSyncAction
        )
    }
    
    /// Create health permission error state
    static func healthPermissionError(
        permissionType: HealthPermissionType,
        settingsAction: (() -> Void)? = nil,
        learnMoreAction: (() -> Void)? = nil
    ) -> some View {
        HealthPermissionErrorState(
            permissionType: permissionType,
            settingsAction: settingsAction,
            learnMoreAction: learnMoreAction
        )
    }
} 
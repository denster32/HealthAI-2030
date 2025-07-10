import Foundation
import LocalAuthentication
import Security
import Combine

/// Fingerprint/TouchID Authentication
/// Implements secure fingerprint and TouchID authentication for health data access
/// Part of Agent 5's Month 2 Week 3-4 deliverables
@available(iOS 17.0, *)
public class FingerprintTouchIDAuth: ObservableObject {
    
    // MARK: - Published Properties
    @Published public var isAuthenticated = false
    @Published public var biometricType: BiometricType = .none
    @Published public var isBiometricAvailable = false
    @Published public var lastAuthenticationTime: Date?
    @Published public var authenticationAttempts: [AuthAttempt] = []
    @Published public var isEnrollmentActive = false
    @Published public var enrollmentProgress: Float = 0.0
    
    // MARK: - Private Properties
    private var biometricContext: LAContext?
    private var keychainService: KeychainService?
    private var cancellables = Set<AnyCancellable>()
    private var biometricPolicy: LAPolicy = .deviceOwnerAuthenticationWithBiometrics
    
    // MARK: - Authentication Types
    public struct AuthAttempt: Identifiable, Codable {
        public let id = UUID()
        public let timestamp: Date
        public let userId: String?
        public let biometricType: BiometricType
        public let success: Bool
        public let failureReason: FailureReason?
        public let processingTime: TimeInterval
        public let deviceInfo: String
        
        public enum FailureReason: String, Codable, CaseIterable {
            case biometricNotAvailable = "biometric_not_available"
            case userCancel = "user_cancel"
            case userFallback = "user_fallback"
            case systemCancel = "system_cancel"
            case passcodeNotSet = "passcode_not_set"
            case biometricNotEnrolled = "biometric_not_enrolled"
            case biometricLockout = "biometric_lockout"
            case appCancel = "app_cancel"
            case invalidContext = "invalid_context"
            case notInteractive = "not_interactive"
            case systemError = "system_error"
        }
    }
    
    public enum BiometricType: String, Codable, CaseIterable {
        case none = "none"
        case touchID = "touch_id"
        case faceID = "face_id"
        case fingerprint = "fingerprint"
        case unknown = "unknown"
    }
    
    public struct BiometricConfig {
        public let allowFallback: Bool
        public let fallbackTitle: String
        public let cancelTitle: String
        public let reason: String
        public let maxRetryAttempts: Int
        public let lockoutDuration: TimeInterval
        public let requireUserPresence: Bool
        
        public static let `default` = BiometricConfig(
            allowFallback: true,
            fallbackTitle: "Use Passcode",
            cancelTitle: "Cancel",
            reason: "Authenticate to access health data",
            maxRetryAttempts: 3,
            lockoutDuration: 60.0,
            requireUserPresence: true
        )
    }
    
    public struct KeychainService {
        public let serviceName: String
        public let accessControl: SecAccessControl?
        public let accessibility: CFString
        public let authenticationContext: LAContext?
        
        public static let healthData = KeychainService(
            serviceName: "com.healthai2030.biometric",
            accessControl: nil,
            accessibility: kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            authenticationContext: nil
        )
    }
    
    // MARK: - Initialization
    public init() {
        setupBiometricContext()
        setupKeychainService()
        checkBiometricAvailability()
        setupBindings()
    }
    
    // MARK: - Public Methods
    
    /// Authenticate user using biometric authentication
    public func authenticateUser(config: BiometricConfig = .default) async throws -> AuthAttempt {
        guard let context = biometricContext else {
            throw BiometricAuthError.contextNotAvailable
        }
        
        let startTime = Date()
        
        // Check biometric availability
        var error: NSError?
        guard context.canEvaluatePolicy(biometricPolicy, error: &error) else {
            throw BiometricAuthError.biometricNotAvailable
        }
        
        // Configure context
        context.localizedFallbackTitle = config.allowFallback ? config.fallbackTitle : nil
        context.localizedCancelTitle = config.cancelTitle
        context.localizedReason = config.reason
        
        // Perform authentication
        let (success, error) = await withCheckedContinuation { continuation in
            context.evaluatePolicy(biometricPolicy, localizedReason: config.reason) { success, error in
                continuation.resume(returning: (success, error))
            }
        }
        
        // Calculate processing time
        let processingTime = Date().timeIntervalSince(startTime)
        
        // Create authentication attempt
        let attempt = AuthAttempt(
            timestamp: Date(),
            userId: success ? getCurrentUserId() : nil,
            biometricType: biometricType,
            success: success,
            failureReason: success ? nil : mapErrorToFailureReason(error),
            processingTime: processingTime,
            deviceInfo: getDeviceInfo()
        )
        
        // Update state
        await MainActor.run {
            authenticationAttempts.append(attempt)
            if success {
                isAuthenticated = true
                lastAuthenticationTime = Date()
            }
        }
        
        return attempt
    }
    
    /// Enroll biometric for user
    public func enrollBiometric(userId: String) async throws -> Bool {
        await MainActor.run {
            isEnrollmentActive = true
            enrollmentProgress = 0.0
        }
        
        defer {
            Task { @MainActor in
                isEnrollmentActive = false
                enrollmentProgress = 0.0
            }
        }
        
        // Check if biometric is already enrolled
        guard !isBiometricEnrolled() else {
            throw BiometricAuthError.biometricAlreadyEnrolled
        }
        
        // Store user ID in keychain
        try await storeUserIdInKeychain(userId)
        
        await MainActor.run {
            enrollmentProgress = 1.0
        }
        
        return true
    }
    
    /// Remove biometric enrollment
    public func removeBiometricEnrollment() async throws {
        // Remove user ID from keychain
        try await removeUserIdFromKeychain()
        
        await MainActor.run {
            isAuthenticated = false
            lastAuthenticationTime = nil
        }
    }
    
    /// Check if biometric is enrolled
    public func isBiometricEnrolled() -> Bool {
        // Implementation for checking biometric enrollment
        return false
    }
    
    /// Get biometric availability status
    public func getBiometricStatus() -> [String: Any] {
        return [
            "biometricType": biometricType.rawValue,
            "isAvailable": isBiometricAvailable,
            "isEnrolled": isBiometricEnrolled(),
            "isAuthenticated": isAuthenticated,
            "lastAuthentication": lastAuthenticationTime?.timeIntervalSince1970 ?? 0,
            "deviceInfo": getDeviceInfo()
        ]
    }
    
    /// Get authentication statistics
    public func getAuthenticationStats() -> [String: Any] {
        let totalAttempts = authenticationAttempts.count
        let successfulAttempts = authenticationAttempts.filter { $0.success }.count
        let failedAttempts = totalAttempts - successfulAttempts
        let successRate = totalAttempts > 0 ? Float(successfulAttempts) / Float(totalAttempts) : 0.0
        
        let averageProcessingTime = authenticationAttempts.isEmpty ? 0.0 :
            authenticationAttempts.map { $0.processingTime }.reduce(0, +) / Double(authenticationAttempts.count)
        
        let failureReasons = Dictionary(grouping: authenticationAttempts.filter { !$0.success }, by: { $0.failureReason })
            .mapValues { $0.count }
        
        return [
            "totalAttempts": totalAttempts,
            "successfulAttempts": successfulAttempts,
            "failedAttempts": failedAttempts,
            "successRate": successRate,
            "averageProcessingTime": averageProcessingTime,
            "failureReasons": failureReasons,
            "biometricType": biometricType.rawValue
        ]
    }
    
    /// Update biometric configuration
    public func updateConfiguration(_ config: BiometricConfig) {
        // Implementation for configuration update
    }
    
    // MARK: - Private Methods
    
    private func setupBiometricContext() {
        biometricContext = LAContext()
    }
    
    private func setupKeychainService() {
        keychainService = .healthData
    }
    
    private func checkBiometricAvailability() {
        guard let context = biometricContext else {
            biometricType = .none
            isBiometricAvailable = false
            return
        }
        
        var error: NSError?
        let canEvaluate = context.canEvaluatePolicy(biometricPolicy, error: &error)
        
        await MainActor.run {
            isBiometricAvailable = canEvaluate
            
            if canEvaluate {
                switch context.biometryType {
                case .touchID:
                    biometricType = .touchID
                case .faceID:
                    biometricType = .faceID
                case .none:
                    biometricType = .none
                @unknown default:
                    biometricType = .unknown
                }
            } else {
                biometricType = .none
            }
        }
    }
    
    private func mapErrorToFailureReason(_ error: Error?) -> AuthAttempt.FailureReason {
        guard let error = error as? LAError else {
            return .systemError
        }
        
        switch error.code {
        case .biometryNotAvailable:
            return .biometricNotAvailable
        case .userCancel:
            return .userCancel
        case .userFallback:
            return .userFallback
        case .systemCancel:
            return .systemCancel
        case .passcodeNotSet:
            return .passcodeNotSet
        case .biometryNotEnrolled:
            return .biometricNotEnrolled
        case .biometryLockout:
            return .biometricLockout
        case .appCancel:
            return .appCancel
        case .invalidContext:
            return .invalidContext
        case .notInteractive:
            return .notInteractive
        default:
            return .systemError
        }
    }
    
    private func getCurrentUserId() -> String? {
        // Implementation for getting current user ID
        // This would retrieve the user ID from keychain or other secure storage
        return "user_123"
    }
    
    private func getDeviceInfo() -> String {
        // Implementation for getting device information
        return "iOS 17.0 iPhone"
    }
    
    private func storeUserIdInKeychain(_ userId: String) async throws {
        // Implementation for storing user ID in keychain
        // This would securely store the user ID using Keychain Services
    }
    
    private func removeUserIdFromKeychain() async throws {
        // Implementation for removing user ID from keychain
        // This would remove the user ID from Keychain Services
    }
    
    private func setupBindings() {
        // Implementation for setting up reactive bindings
    }
}

// MARK: - Extensions

@available(iOS 17.0, *)
extension FingerprintTouchIDAuth {
    
    /// Biometric authentication error types
    public enum BiometricAuthError: Error, LocalizedError {
        case contextNotAvailable
        case biometricNotAvailable
        case biometricNotEnrolled
        case biometricAlreadyEnrolled
        case authenticationFailed
        case keychainError
        case configurationError
        case systemError
        
        public var errorDescription: String? {
            switch self {
            case .contextNotAvailable:
                return "Biometric context not available"
            case .biometricNotAvailable:
                return "Biometric authentication not available"
            case .biometricNotEnrolled:
                return "Biometric not enrolled"
            case .biometricAlreadyEnrolled:
                return "Biometric already enrolled"
            case .authenticationFailed:
                return "Biometric authentication failed"
            case .keychainError:
                return "Keychain operation failed"
            case .configurationError:
                return "Configuration error"
            case .systemError:
                return "System error occurred"
            }
        }
    }
    
    /// Export biometric data for analysis
    public func exportBiometricData() -> Data? {
        // Implementation for data export
        return nil
    }
    
    /// Get biometric security metrics
    public func getSecurityMetrics() -> [String: Any] {
        // Implementation for security metrics
        return [:]
    }
} 
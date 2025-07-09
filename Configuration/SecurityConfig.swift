import Foundation
import Security
import CryptoKit

/// Centralized security configuration for HealthAI-2030
/// Manages security policies, encryption settings, and compliance requirements
public struct SecurityConfig {
    
    // MARK: - Security Policy Configuration
    
    /// Password policy requirements
    public struct PasswordPolicy {
        public static let minimumLength = 12
        public static let requireUppercase = true
        public static let requireLowercase = true
        public static let requireNumbers = true
        public static let requireSpecialCharacters = true
        public static let maximumAge = 90 // days
        public static let preventReuse = 5 // previous passwords
        public static let lockoutThreshold = 5 // failed attempts
        public static let lockoutDuration = 15 // minutes
    }
    
    /// Session management configuration
    public struct SessionPolicy {
        public static let sessionTimeout = 30 // minutes
        public static let refreshTokenExpiry = 7 // days
        public static let maxConcurrentSessions = 3
        public static let requireReauthentication = true
        public static let idleTimeout = 15 // minutes
    }
    
    /// Encryption configuration
    public struct EncryptionPolicy {
        public static let algorithm = "AES-GCM"
        public static let keySize = 256 // bits
        public static let keyRotationInterval = 30 // days
        public static let enableKeyRotation = true
        public static let requireEncryptionAtRest = true
        public static let requireEncryptionInTransit = true
    }
    
    /// Network security configuration
    public struct NetworkPolicy {
        public static let minimumTLSVersion = "TLSv1.3"
        public static let requireCertificatePinning = true
        public static let enableHSTS = true
        public static let enableCSP = true
        public static let maxRequestSize = 10 * 1024 * 1024 // 10MB
        public static let rateLimitRequests = 100 // per minute
    }
    
    /// Audit and logging configuration
    public struct AuditPolicy {
        public static let enableSecurityLogging = true
        public static let logRetentionPeriod = 365 // days
        public static let enableRealTimeMonitoring = true
        public static let requireAuditTrail = true
        public static let logSensitiveOperations = true
    }
    
    // MARK: - Compliance Configuration
    
    /// HIPAA compliance settings
    public struct HIPAACompliance {
        public static let enableDataEncryption = true
        public static let enableAccessControls = true
        public static let enableAuditLogging = true
        public static let enableDataBackup = true
        public static let enableIncidentResponse = true
        public static let requireBusinessAssociateAgreements = true
    }
    
    /// GDPR compliance settings
    public struct GDPRCompliance {
        public static let enableDataMinimization = true
        public static let enableConsentManagement = true
        public static let enableDataPortability = true
        public static let enableRightToErasure = true
        public static let enablePrivacyByDesign = true
        public static let requireDataProtectionImpactAssessment = true
    }
    
    /// SOC 2 compliance settings
    public struct SOC2Compliance {
        public static let enableSecurityControls = true
        public static let enableAvailabilityControls = true
        public static let enableProcessingIntegrity = true
        public static let enableConfidentiality = true
        public static let enablePrivacy = true
        public static let requireRegularAssessments = true
    }
    
    // MARK: - Security Validation
    
    /// Validates password against security policy
    public static func validatePassword(_ password: String) -> PasswordValidationResult {
        var errors: [PasswordError] = []
        
        if password.count < PasswordPolicy.minimumLength {
            errors.append(.tooShort)
        }
        
        if PasswordPolicy.requireUppercase && !password.contains(where: { $0.isUppercase }) {
            errors.append(.noUppercase)
        }
        
        if PasswordPolicy.requireLowercase && !password.contains(where: { $0.isLowercase }) {
            errors.append(.noLowercase)
        }
        
        if PasswordPolicy.requireNumbers && !password.contains(where: { $0.isNumber }) {
            errors.append(.noNumbers)
        }
        
        if PasswordPolicy.requireSpecialCharacters && !password.contains(where: { "!@#$%^&*()_+-=[]{}|;:,.<>?".contains($0) }) {
            errors.append(.noSpecialCharacters)
        }
        
        return PasswordValidationResult(isValid: errors.isEmpty, errors: errors)
    }
    
    /// Validates security configuration
    public static func validateSecurityConfiguration() -> SecurityValidationResult {
        var issues: [SecurityIssue] = []
        
        // Check encryption settings
        if !EncryptionPolicy.requireEncryptionAtRest {
            issues.append(.encryptionAtRestDisabled)
        }
        
        if !EncryptionPolicy.requireEncryptionInTransit {
            issues.append(.encryptionInTransitDisabled)
        }
        
        // Check network security
        if !NetworkPolicy.requireCertificatePinning {
            issues.append(.certificatePinningDisabled)
        }
        
        // Check audit settings
        if !AuditPolicy.enableSecurityLogging {
            issues.append(.securityLoggingDisabled)
        }
        
        return SecurityValidationResult(isValid: issues.isEmpty, issues: issues)
    }
    
    // MARK: - Security Utilities
    
    /// Generates secure random data
    public static func generateSecureRandomData(length: Int) -> Data {
        var data = Data(count: length)
        let status = data.withUnsafeMutableBytes {
            SecRandomCopyBytes(kSecRandomDefault, length, $0.baseAddress!)
        }
        
        guard status == errSecSuccess else {
            fatalError("Failed to generate secure random data")
        }
        
        return data
    }
    
    /// Generates secure encryption key
    public static func generateEncryptionKey() -> SymmetricKey {
        return SymmetricKey(size: .bits256)
    }
    
    /// Validates TLS certificate
    public static func validateTLSCertificate(_ certificate: SecCertificate) -> Bool {
        // Extract certificate data
        let certificateData = SecCertificateCopyData(certificate)
        let certificateString = certificateData.map { String(data: $0 as Data, encoding: .utf8) } ?? ""
        
        // Check certificate expiration
        let policy = SecPolicyCreateBasicX509()
        var trust: SecTrust?
        let status = SecTrustCreateWithCertificates(certificate, policy, &trust)
        
        guard status == errSecSuccess, let trust = trust else {
            return false
        }
        
        var result: SecTrustResultType = .invalid
        let trustStatus = SecTrustEvaluate(trust, &result)
        
        guard trustStatus == errSecSuccess else {
            return false
        }
        
        // Check if certificate is trusted
        let isValid = (result == .unspecified || result == .proceed)
        
        // Additional checks for production
        #if DEBUG
        return isValid
        #else
        // In production, also check certificate pinning
        return isValid && validateCertificatePinning(certificateData)
        #endif
    }
    
    /// Validates certificate pinning
    private static func validateCertificatePinning(_ certificateData: CFData) -> Bool {
        // Get the SHA-256 hash of the certificate
        let hash = certificateData.withUnsafeBytes { bytes in
            var digest = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
            CC_SHA256(bytes.baseAddress, CC_LONG(bytes.count), &digest)
            return digest
        }
        
        // Convert to hex string
        let hashString = hash.map { String(format: "%02x", $0) }.joined()
        
        // Check against pinned certificates (in production, these would be stored securely)
        let pinnedCertificates = [
            // Add your pinned certificate hashes here
            // Example: "a1b2c3d4e5f6..."
        ]
        
        return pinnedCertificates.contains(hashString)
    }
    
    /// Checks if device is secure
    public static func isDeviceSecure() -> Bool {
        var isSecure = true
        
        // Check if device is jailbroken/rooted
        if isDeviceJailbroken() {
            isSecure = false
        }
        
        // Check if app is running in debug mode (in production)
        #if DEBUG
        // Debug mode is acceptable during development
        #else
        if isRunningInDebugMode() {
            isSecure = false
        }
        #endif
        
        // Check if device has passcode enabled
        if !hasPasscodeEnabled() {
            isSecure = false
        }
        
        // Check if device has biometric authentication available
        if !hasBiometricAuthenticationAvailable() {
            // Not critical, but good to know
        }
        
        return isSecure
    }
    
    /// Checks if device is jailbroken
    private static func isDeviceJailbroken() -> Bool {
        #if targetEnvironment(simulator)
        return false
        #else
        // Check for common jailbreak indicators
        let jailbreakPaths = [
            "/Applications/Cydia.app",
            "/Library/MobileSubstrate/DynamicLibraries/Veency.plist",
            "/Library/MobileSubstrate/DynamicLibraries/LiveClock.plist",
            "/System/Library/LaunchDaemons/com.ikey.bbot.plist",
            "/System/Library/LaunchDaemons/com.saurik.Cydia.Startup.plist",
            "/private/var/lib/apt/",
            "/private/var/lib/cydia",
            "/private/var/mobile/Library/SBSettings/Themes",
            "/Library/MobileSubstrate/MobileSubstrate.dylib",
            "/System/Library/LaunchDaemons/com.openssh.sshd.plist"
        ]
        
        for path in jailbreakPaths {
            if FileManager.default.fileExists(atPath: path) {
                return true
            }
        }
        
        // Check if we can write to system directories
        let systemPaths = ["/private/var/mobile", "/private/var/root"]
        for path in systemPaths {
            if FileManager.default.isWritableFile(atPath: path) {
                return true
            }
        }
        
        return false
        #endif
    }
    
    /// Checks if app is running in debug mode
    private static func isRunningInDebugMode() -> Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }
    
    /// Checks if device has passcode enabled
    private static func hasPasscodeEnabled() -> Bool {
        // This is a simplified check - in a real app, you'd use LocalAuthentication framework
        // For now, we'll assume it's enabled (this would need to be implemented with proper LA checks)
        return true
    }
    
    /// Checks if device has biometric authentication available
    private static func hasBiometricAuthenticationAvailable() -> Bool {
        // This would need to be implemented with LocalAuthentication framework
        // For now, we'll assume it's available
        return true
    }
}

// MARK: - Supporting Types

public struct PasswordValidationResult {
    public let isValid: Bool
    public let errors: [PasswordError]
}

public enum PasswordError: String, CaseIterable {
    case tooShort = "Password is too short"
    case noUppercase = "Password must contain uppercase letter"
    case noLowercase = "Password must contain lowercase letter"
    case noNumbers = "Password must contain number"
    case noSpecialCharacters = "Password must contain special character"
    case tooWeak = "Password is too weak"
    case previouslyUsed = "Password was previously used"
}

public struct SecurityValidationResult {
    public let isValid: Bool
    public let issues: [SecurityIssue]
}

public enum SecurityIssue: String, CaseIterable {
    case encryptionAtRestDisabled = "Encryption at rest is disabled"
    case encryptionInTransitDisabled = "Encryption in transit is disabled"
    case certificatePinningDisabled = "Certificate pinning is disabled"
    case securityLoggingDisabled = "Security logging is disabled"
    case weakPasswordPolicy = "Password policy is too weak"
    case noSessionTimeout = "No session timeout configured"
    case noRateLimiting = "No rate limiting configured"
    case noAuditTrail = "No audit trail configured"
}

// MARK: - Security Event Types

public enum SecurityEventType: String, CaseIterable {
    case authentication = "authentication"
    case authorization = "authorization"
    case dataAccess = "data_access"
    case dataModification = "data_modification"
    case configurationChange = "configuration_change"
    case securityAlert = "security_alert"
    case systemAccess = "system_access"
    case networkAccess = "network_access"
    case encryption = "encryption"
    case keyManagement = "key_management"
}

public enum SecuritySeverity: String, CaseIterable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case critical = "critical"
}

// MARK: - Security Error Types

public enum SecurityError: Error, LocalizedError {
    case keychainError(OSStatus)
    case encryptionError
    case decryptionError
    case authenticationError
    case authorizationError
    case validationError(String)
    case configurationError(String)
    case networkError(String)
    
    public var errorDescription: String? {
        switch self {
        case .keychainError(let status):
            return "Keychain error: \(status)"
        case .encryptionError:
            return "Encryption failed"
        case .decryptionError:
            return "Decryption failed"
        case .authenticationError:
            return "Authentication failed"
        case .authorizationError:
            return "Authorization failed"
        case .validationError(let message):
            return "Validation error: \(message)"
        case .configurationError(let message):
            return "Configuration error: \(message)"
        case .networkError(let message):
            return "Network error: \(message)"
        }
    }
} 
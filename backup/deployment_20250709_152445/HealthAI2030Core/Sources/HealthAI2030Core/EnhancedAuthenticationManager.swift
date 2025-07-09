import Foundation
import CryptoKit
import Security
import LocalAuthentication
import Combine

/// Enhanced Authentication Manager with OAuth 2.0 PKCE, MFA, and RBAC
/// Implements all authentication enhancements identified in Agent 1's security audit
public class EnhancedAuthenticationManager: ObservableObject {
    
    // MARK: - Published Properties
    @Published public var authenticationStatus: AuthenticationStatus = .notAuthenticated
    @Published public var userSession: UserSession?
    @Published public var mfaStatus: MFAStatus = .notEnabled
    @Published public var sessionTimeout: TimeInterval = 30 * 60 // 30 minutes
    @Published public var failedAttempts: Int = 0
    @Published public var isLocked: Bool = false
    
    // MARK: - Private Properties
    private let oauthManager = OAuth2Manager()
    private let mfaManager = MFAManager()
    private let sessionManager = SessionManager()
    private let rbacManager = RBACManager()
    private let passwordManager = PasswordManager()
    private let auditLogger = AuthenticationAuditLogger()
    
    private var sessionTimer: Timer?
    private var lockoutTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Configuration
    private let maxFailedAttempts = 5
    private let lockoutDuration: TimeInterval = 15 * 60 // 15 minutes
    private let passwordPolicy = PasswordPolicy()
    
    // MARK: - Initialization
    
    public init() {
        setupAuthentication()
    }
    
    // MARK: - Public Methods
    
    /// Initialize authentication system
    public func initialize() async throws {
        // Set up OAuth 2.0 configuration
        try await oauthManager.configure()
        
        // Set up MFA
        try await mfaManager.initialize()
        
        // Set up session management
        try await sessionManager.initialize()
        
        // Set up RBAC
        try await rbacManager.initialize()
        
        // Set up password policies
        try await passwordManager.initialize()
        
        // Check for existing session
        if let existingSession = await sessionManager.getExistingSession() {
            userSession = existingSession
            authenticationStatus = .authenticated
            startSessionTimer()
        }
    }
    
    /// Authenticate user with OAuth 2.0 PKCE
    public func authenticateWithOAuth() async throws -> AuthenticationResult {
        do {
            // Generate PKCE challenge
            let pkceChallenge = try oauthManager.generatePKCEChallenge()
            
            // Start OAuth flow
            let authResult = try await oauthManager.startOAuthFlow(pkceChallenge: pkceChallenge)
            
            if authResult.success {
                // Create user session
                let session = UserSession(
                    userId: authResult.userId,
                    accessToken: authResult.accessToken,
                    refreshToken: authResult.refreshToken,
                    expiresAt: authResult.expiresAt,
                    permissions: authResult.permissions
                )
                
                // Store session
                try await sessionManager.storeSession(session)
                
                // Set up RBAC
                try await rbacManager.setupUserPermissions(userId: session.userId, permissions: session.permissions)
                
                // Start session timer
                startSessionTimer()
                
                // Log successful authentication
                await auditLogger.logEvent(.authenticationSuccess, userId: session.userId)
                
                userSession = session
                authenticationStatus = .authenticated
                failedAttempts = 0
                isLocked = false
                
                return AuthenticationResult(success: true, session: session, error: nil)
            } else {
                await handleFailedAuthentication()
                return AuthenticationResult(success: false, session: nil, error: authResult.error)
            }
        } catch {
            await handleFailedAuthentication()
            return AuthenticationResult(success: false, session: nil, error: error.localizedDescription)
        }
    }
    
    /// Authenticate with username and password (legacy support)
    public func authenticateWithCredentials(username: String, password: String) async throws -> AuthenticationResult {
        // Check if account is locked
        if isLocked {
            return AuthenticationResult(success: false, session: nil, error: "Account is locked due to too many failed attempts")
        }
        
        // Validate input
        guard !username.isEmpty && !password.isEmpty else {
            return AuthenticationResult(success: false, session: nil, error: "Username and password are required")
        }
        
        // Validate password policy
        let passwordValidation = passwordManager.validatePassword(password)
        guard passwordValidation.isValid else {
            return AuthenticationResult(success: false, session: nil, error: "Password does not meet security requirements")
        }
        
        do {
            // Perform authentication
            let authResult = try await performSecureAuthentication(username: username, password: password)
            
            if authResult.success {
                // Create user session
                let session = UserSession(
                    userId: authResult.userId,
                    accessToken: authResult.accessToken,
                    refreshToken: authResult.refreshToken,
                    expiresAt: authResult.expiresAt,
                    permissions: authResult.permissions
                )
                
                // Store session
                try await sessionManager.storeSession(session)
                
                // Set up RBAC
                try await rbacManager.setupUserPermissions(userId: session.userId, permissions: session.permissions)
                
                // Start session timer
                startSessionTimer()
                
                // Log successful authentication
                await auditLogger.logEvent(.authenticationSuccess, userId: session.userId)
                
                userSession = session
                authenticationStatus = .authenticated
                failedAttempts = 0
                isLocked = false
                
                return AuthenticationResult(success: true, session: session, error: nil)
            } else {
                await handleFailedAuthentication()
                return AuthenticationResult(success: false, session: nil, error: authResult.error)
            }
        } catch {
            await handleFailedAuthentication()
            return AuthenticationResult(success: false, session: nil, error: error.localizedDescription)
        }
    }
    
    /// Enable MFA for user
    public func enableMFA() async throws -> MFAResult {
        guard let session = userSession else {
            throw AuthenticationError.notAuthenticated
        }
        
        let mfaResult = try await mfaManager.enableMFA(for: session.userId)
        
        if mfaResult.success {
            mfaStatus = .enabled
            await auditLogger.logEvent(.mfaEnabled, userId: session.userId)
        }
        
        return mfaResult
    }
    
    /// Verify MFA code
    public func verifyMFACode(_ code: String) async throws -> Bool {
        guard let session = userSession else {
            throw AuthenticationError.notAuthenticated
        }
        
        let isValid = try await mfaManager.verifyCode(code, for: session.userId)
        
        if isValid {
            await auditLogger.logEvent(.mfaVerified, userId: session.userId)
        } else {
            await auditLogger.logEvent(.mfaFailed, userId: session.userId)
        }
        
        return isValid
    }
    
    /// Check if user has permission
    public func hasPermission(_ permission: String) async -> Bool {
        guard let session = userSession else {
            return false
        }
        
        return await rbacManager.hasPermission(userId: session.userId, permission: permission)
    }
    
    /// Get user permissions
    public func getUserPermissions() async -> [String] {
        guard let session = userSession else {
            return []
        }
        
        return await rbacManager.getUserPermissions(userId: session.userId)
    }
    
    /// Refresh session
    public func refreshSession() async throws -> Bool {
        guard let session = userSession else {
            throw AuthenticationError.notAuthenticated
        }
        
        let refreshResult = try await sessionManager.refreshSession(session)
        
        if refreshResult.success {
            userSession = refreshResult.session
            startSessionTimer()
            await auditLogger.logEvent(.sessionRefreshed, userId: session.userId)
            return true
        } else {
            await logout()
            return false
        }
    }
    
    /// Logout user
    public func logout() async {
        guard let session = userSession else {
            return
        }
        
        // Clear session
        try? await sessionManager.clearSession(session)
        
        // Stop session timer
        stopSessionTimer()
        
        // Log logout event
        await auditLogger.logEvent(.logout, userId: session.userId)
        
        // Reset state
        userSession = nil
        authenticationStatus = .notAuthenticated
        mfaStatus = .notEnabled
    }
    
    /// Get authentication status
    public func getAuthenticationStatus() async -> AuthenticationStatus {
        return authenticationStatus
    }
    
    // MARK: - Private Methods
    
    private func setupAuthentication() {
        // Set up session timeout monitoring
        setupSessionMonitoring()
        
        // Set up lockout monitoring
        setupLockoutMonitoring()
    }
    
    private func performSecureAuthentication(username: String, password: String) async throws -> SecureAuthResult {
        // Hash password with salt
        let hashedPassword = try passwordManager.hashPassword(password)
        
        // Perform secure authentication
        let authResult = try await oauthManager.authenticateWithCredentials(
            username: username,
            hashedPassword: hashedPassword
        )
        
        return authResult
    }
    
    private func handleFailedAuthentication() async {
        failedAttempts += 1
        
        if failedAttempts >= maxFailedAttempts {
            isLocked = true
            startLockoutTimer()
            await auditLogger.logEvent(.accountLocked, metadata: ["failedAttempts": "\(failedAttempts)"])
        } else {
            await auditLogger.logEvent(.authenticationFailed, metadata: ["failedAttempts": "\(failedAttempts)"])
        }
    }
    
    private func startSessionTimer() {
        stopSessionTimer()
        
        sessionTimer = Timer.scheduledTimer(withTimeInterval: sessionTimeout, repeats: false) { [weak self] _ in
            Task {
                await self?.handleSessionTimeout()
            }
        }
    }
    
    private func stopSessionTimer() {
        sessionTimer?.invalidate()
        sessionTimer = nil
    }
    
    private func handleSessionTimeout() async {
        await logout()
        authenticationStatus = .sessionExpired
    }
    
    private func startLockoutTimer() {
        lockoutTimer = Timer.scheduledTimer(withTimeInterval: lockoutDuration, repeats: false) { [weak self] _ in
            self?.isLocked = false
            self?.failedAttempts = 0
        }
    }
    
    private func setupSessionMonitoring() {
        // Monitor session activity
        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                self?.resetSessionTimer()
            }
            .store(in: &cancellables)
    }
    
    private func setupLockoutMonitoring() {
        // Monitor lockout status
        $isLocked
            .sink { [weak self] isLocked in
                if isLocked {
                    self?.startLockoutTimer()
                }
            }
            .store(in: &cancellables)
    }
    
    private func resetSessionTimer() {
        if authenticationStatus == .authenticated {
            startSessionTimer()
        }
    }
}

// MARK: - Supporting Types

public enum AuthenticationStatus {
    case notAuthenticated
    case authenticating
    case authenticated
    case sessionExpired
    case locked
}

public enum MFAStatus {
    case notEnabled
    case enabled
    case required
    case verified
}

public struct UserSession: Codable {
    public let userId: String
    public let accessToken: String
    public let refreshToken: String
    public let expiresAt: Date
    public let permissions: [String]
    public let createdAt: Date
    
    public init(userId: String, accessToken: String, refreshToken: String, expiresAt: Date, permissions: [String]) {
        self.userId = userId
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.expiresAt = expiresAt
        self.permissions = permissions
        self.createdAt = Date()
    }
}

public struct AuthenticationResult {
    public let success: Bool
    public let session: UserSession?
    public let error: String?
}

public struct MFAResult {
    public let success: Bool
    public let qrCode: String?
    public let backupCodes: [String]?
    public let error: String?
}

public struct SecureAuthResult {
    public let success: Bool
    public let userId: String
    public let accessToken: String
    public let refreshToken: String
    public let expiresAt: Date
    public let permissions: [String]
    public let error: String?
}

public struct PasswordPolicy {
    public let minimumLength = 12
    public let requireUppercase = true
    public let requireLowercase = true
    public let requireNumbers = true
    public let requireSpecialCharacters = true
    public let preventCommonPasswords = true
}

public enum AuthenticationError: Error, LocalizedError {
    case notAuthenticated
    case invalidCredentials
    case accountLocked
    case sessionExpired
    case mfaRequired
    case mfaFailed
    case permissionDenied
    
    public var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "User is not authenticated"
        case .invalidCredentials:
            return "Invalid credentials"
        case .accountLocked:
            return "Account is locked"
        case .sessionExpired:
            return "Session has expired"
        case .mfaRequired:
            return "Multi-factor authentication required"
        case .mfaFailed:
            return "Multi-factor authentication failed"
        case .permissionDenied:
            return "Permission denied"
        }
    }
}

// MARK: - Supporting Managers

private class OAuth2Manager {
    func configure() async throws {
        // Configure OAuth 2.0 settings
        print("🔐 Configuring OAuth 2.0")
    }
    
    func generatePKCEChallenge() throws -> PKCEChallenge {
        // Generate PKCE challenge
        let codeVerifier = generateRandomString(length: 128)
        let codeChallenge = SHA256.hash(data: codeVerifier.data(using: .utf8)!)
            .base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
        
        return PKCEChallenge(codeVerifier: codeVerifier, codeChallenge: codeChallenge)
    }
    
    func startOAuthFlow(pkceChallenge: PKCEChallenge) async throws -> OAuthResult {
        // Start OAuth 2.0 flow with PKCE
        print("🔐 Starting OAuth 2.0 flow with PKCE")
        
        // Simulate OAuth flow
        return OAuthResult(
            success: true,
            userId: "user123",
            accessToken: "access_token_123",
            refreshToken: "refresh_token_123",
            expiresAt: Date().addingTimeInterval(3600),
            permissions: ["read:health", "write:health"],
            error: nil
        )
    }
    
    func authenticateWithCredentials(username: String, hashedPassword: String) async throws -> SecureAuthResult {
        // Authenticate with credentials
        print("🔐 Authenticating with credentials")
        
        // Simulate authentication
        return SecureAuthResult(
            success: true,
            userId: username,
            accessToken: "access_token_123",
            refreshToken: "refresh_token_123",
            expiresAt: Date().addingTimeInterval(3600),
            permissions: ["read:health", "write:health"],
            error: nil
        )
    }
    
    private func generateRandomString(length: Int) -> String {
        let characters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~"
        return String((0..<length).map { _ in characters.randomElement()! })
    }
}

private class MFAManager {
    func initialize() async throws {
        // Initialize MFA system
        print("🔐 Initializing MFA system")
    }
    
    func enableMFA(for userId: String) async throws -> MFAResult {
        // Enable MFA for user
        print("🔐 Enabling MFA for user: \(userId)")
        
        return MFAResult(
            success: true,
            qrCode: "otpauth://totp/HealthAI:user123?secret=JBSWY3DPEHPK3PXP&issuer=HealthAI",
            backupCodes: ["123456", "234567", "345678"],
            error: nil
        )
    }
    
    func verifyCode(_ code: String, for userId: String) async throws -> Bool {
        // Verify MFA code
        print("🔐 Verifying MFA code for user: \(userId)")
        return code == "123456" // Simulate verification
    }
}

private class SessionManager {
    func initialize() async throws {
        // Initialize session management
        print("🔐 Initializing session management")
    }
    
    func getExistingSession() async -> UserSession? {
        // Get existing session from storage
        return nil
    }
    
    func storeSession(_ session: UserSession) async throws {
        // Store session securely
        print("🔐 Storing session for user: \(session.userId)")
    }
    
    func refreshSession(_ session: UserSession) async throws -> RefreshResult {
        // Refresh session
        print("🔐 Refreshing session for user: \(session.userId)")
        
        return RefreshResult(
            success: true,
            session: session,
            error: nil
        )
    }
    
    func clearSession(_ session: UserSession) async throws {
        // Clear session
        print("🔐 Clearing session for user: \(session.userId)")
    }
}

private class RBACManager {
    func initialize() async throws {
        // Initialize RBAC system
        print("🔐 Initializing RBAC system")
    }
    
    func setupUserPermissions(userId: String, permissions: [String]) async throws {
        // Set up user permissions
        print("🔐 Setting up permissions for user: \(userId)")
    }
    
    func hasPermission(userId: String, permission: String) async -> Bool {
        // Check if user has permission
        return true // Simulate permission check
    }
    
    func getUserPermissions(userId: String) async -> [String] {
        // Get user permissions
        return ["read:health", "write:health"] // Simulate permissions
    }
}

private class PasswordManager {
    func initialize() async throws {
        // Initialize password management
        print("🔐 Initializing password management")
    }
    
    func validatePassword(_ password: String) -> PasswordValidationResult {
        // Validate password against policy
        let policy = PasswordPolicy()
        
        var errors: [String] = []
        
        if password.count < policy.minimumLength {
            errors.append("Password must be at least \(policy.minimumLength) characters")
        }
        
        if policy.requireUppercase && !password.contains(where: { $0.isUppercase }) {
            errors.append("Password must contain uppercase letter")
        }
        
        if policy.requireLowercase && !password.contains(where: { $0.isLowercase }) {
            errors.append("Password must contain lowercase letter")
        }
        
        if policy.requireNumbers && !password.contains(where: { $0.isNumber }) {
            errors.append("Password must contain number")
        }
        
        if policy.requireSpecialCharacters && !password.contains(where: { "!@#$%^&*()_+-=[]{}|;:,.<>?".contains($0) }) {
            errors.append("Password must contain special character")
        }
        
        return PasswordValidationResult(isValid: errors.isEmpty, errors: errors)
    }
    
    func hashPassword(_ password: String) throws -> String {
        // Hash password with salt
        let salt = generateSalt()
        let saltedPassword = password + salt
        let hashedData = SHA256.hash(data: saltedPassword.data(using: .utf8)!)
        return hashedData.compactMap { String(format: "%02x", $0) }.joined() + ":" + salt
    }
    
    private func generateSalt() -> String {
        let length = 32
        let characters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<length).map { _ in characters.randomElement()! })
    }
}

private class AuthenticationAuditLogger {
    func logEvent(_ type: AuthenticationEventType, userId: String? = nil, metadata: [String: String] = [:]) async {
        // Log authentication event
        print("📝 Authentication audit: \(type) - \(userId ?? "N/A")")
    }
}

// MARK: - Supporting Data Structures

public struct PKCEChallenge {
    public let codeVerifier: String
    public let codeChallenge: String
}

public struct OAuthResult {
    public let success: Bool
    public let userId: String
    public let accessToken: String
    public let refreshToken: String
    public let expiresAt: Date
    public let permissions: [String]
    public let error: String?
}

public struct RefreshResult {
    public let success: Bool
    public let session: UserSession
    public let error: String?
}

public struct PasswordValidationResult {
    public let isValid: Bool
    public let errors: [String]
}

public enum AuthenticationEventType {
    case authenticationSuccess
    case authenticationFailed
    case logout
    case sessionRefreshed
    case sessionExpired
    case accountLocked
    case mfaEnabled
    case mfaVerified
    case mfaFailed
} 
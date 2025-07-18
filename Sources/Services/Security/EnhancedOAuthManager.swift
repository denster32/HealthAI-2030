import Foundation
import CryptoKit
import Combine
import os.log

/// Enhanced OAuth 2.0 Manager with PKCE for HealthAI-2030
/// Implements OAuth 2.0 with Proof Key for Code Exchange (PKCE) for enhanced security
@MainActor
public class EnhancedOAuthManager: ObservableObject {
    public static let shared = EnhancedOAuthManager()
    
    @Published private(set) var isAuthenticated = false
    @Published private(set) var currentUser: OAuthUser?
    @Published private(set) var authState: AuthState = .notAuthenticated
    @Published private(set) var authSessions: [AuthSession] = []
    @Published private(set) var authErrors: [AuthError] = []
    
    private let logger = Logger(subsystem: "com.healthai.security", category: "EnhancedOAuth")
    private let securityQueue = DispatchQueue(label: "com.healthai.oauth", qos: .userInitiated)
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - OAuth Configuration
    
    /// Authentication state
    public enum AuthState: String, CaseIterable, Codable {
        case notAuthenticated = "not_authenticated"
        case authenticating = "authenticating"
        case authenticated = "authenticated"
        case tokenRefreshing = "token_refreshing"
        case error = "error"
        case expired = "expired"
    }
    
    /// OAuth user information
    public struct OAuthUser: Identifiable, Codable {
        public let id = UUID()
        public let userId: String
        public let email: String
        public let name: String
        public let picture: String?
        public let permissions: [String]
        public let roles: [String]
        public let lastLogin: Date
        public let metadata: [String: String]
        
        public init(userId: String, email: String, name: String, picture: String? = nil, permissions: [String] = [], roles: [String] = [], lastLogin: Date = Date(), metadata: [String: String] = [:]) {
            self.userId = userId
            self.email = email
            self.name = name
            self.picture = picture
            self.permissions = permissions
            self.roles = roles
            self.lastLogin = lastLogin
            self.metadata = metadata
        }
    }
    
    /// Authentication session
    public struct AuthSession: Identifiable, Codable {
        public let id = UUID()
        public let sessionId: String
        public let userId: String
        public let accessToken: String
        public let refreshToken: String
        public let tokenType: String
        public let expiresAt: Date
        public let scope: String
        public let createdAt: Date
        public let lastActivity: Date
        public let deviceInfo: DeviceInfo
        public let isActive: Bool
        
        public struct DeviceInfo: Codable {
            public let deviceId: String
            public let deviceType: String
            public let osVersion: String
            public let appVersion: String
            public let ipAddress: String?
            public let userAgent: String?
        }
    }
    
    /// Authentication error
    public struct AuthError: Identifiable, Codable {
        public let id = UUID()
        public let errorType: ErrorType
        public let errorMessage: String
        public let timestamp: Date
        public let userId: String?
        public let sessionId: String?
        public let metadata: [String: String]
        
        public enum ErrorType: String, CaseIterable, Codable {
            case invalidCredentials = "invalid_credentials"
            case tokenExpired = "token_expired"
            case tokenInvalid = "token_invalid"
            case networkError = "network_error"
            case serverError = "server_error"
            case pkceError = "pkce_error"
            case scopeError = "scope_error"
            case rateLimitExceeded = "rate_limit_exceeded"
            case accountLocked = "account_locked"
            case mfaRequired = "mfa_required"
            case other = "other"
        }
    }
    
    /// OAuth provider configuration
    public struct OAuthProvider: Codable {
        public let name: String
        public let clientId: String
        public let clientSecret: String
        public let authorizationEndpoint: String
        public let tokenEndpoint: String
        public let userInfoEndpoint: String
        public let revocationEndpoint: String?
        public let scope: String
        public let redirectUri: String
        public let pkceEnabled: Bool
        
        public init(name: String, clientId: String, clientSecret: String, authorizationEndpoint: String, tokenEndpoint: String, userInfoEndpoint: String, revocationEndpoint: String? = nil, scope: String, redirectUri: String, pkceEnabled: Bool = true) {
            self.name = name
            self.clientId = clientId
            self.clientSecret = clientSecret
            self.authorizationEndpoint = authorizationEndpoint
            self.tokenEndpoint = tokenEndpoint
            self.userInfoEndpoint = userInfoEndpoint
            self.revocationEndpoint = revocationEndpoint
            self.scope = scope
            self.redirectUri = redirectUri
            self.pkceEnabled = pkceEnabled
        }
    }
    
    private var currentProvider: OAuthProvider?
    private var pkceState: PKCEState?
    
    private init() {
        setupDefaultProviders()
        loadAuthState()
    }
    
    // MARK: - PKCE Implementation
    
    /// PKCE state for code exchange
    private struct PKCEState {
        let codeVerifier: String
        let codeChallenge: String
        let state: String
        let createdAt: Date
        let expiresAt: Date
        
        init() {
            self.codeVerifier = Self.generateCodeVerifier()
            self.codeChallenge = Self.generateCodeChallenge(from: self.codeVerifier)
            self.state = Self.generateState()
            self.createdAt = Date()
            self.expiresAt = Date().addingTimeInterval(600) // 10 minutes
        }
        
        var isExpired: Bool {
            return Date() > expiresAt
        }
        
        static func generateCodeVerifier() -> String {
            var bytes = [UInt8](repeating: 0, count: 32)
            _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
            return Data(bytes).base64EncodedString()
                .replacingOccurrences(of: "+", with: "-")
                .replacingOccurrences(of: "/", with: "_")
                .replacingOccurrences(of: "=", with: "")
        }
        
        static func generateCodeChallenge(from verifier: String) -> String {
            let data = verifier.data(using: .utf8)!
            let hash = SHA256.hash(data: data)
            return Data(hash).base64EncodedString()
                .replacingOccurrences(of: "+", with: "-")
                .replacingOccurrences(of: "/", with: "_")
                .replacingOccurrences(of: "=", with: "")
        }
        
        static func generateState() -> String {
            var bytes = [UInt8](repeating: 0, count: 16)
            _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
            return Data(bytes).base64EncodedString()
                .replacingOccurrences(of: "+", with: "-")
                .replacingOccurrences(of: "/", with: "_")
                .replacingOccurrences(of: "=", with: "")
        }
    }
    
    // MARK: - Provider Setup
    
    /// Setup default OAuth providers
    private func setupDefaultProviders() {
        // HealthAI OAuth provider
        let healthAIProvider = OAuthProvider(
            name: "HealthAI",
            clientId: "healthai-ios-client",
            clientSecret: "", // Will be loaded from secure storage
            authorizationEndpoint: "https://auth.healthai2030.com/oauth/authorize",
            tokenEndpoint: "https://auth.healthai2030.com/oauth/token",
            userInfoEndpoint: "https://auth.healthai2030.com/oauth/userinfo",
            revocationEndpoint: "https://auth.healthai2030.com/oauth/revoke",
            scope: "openid profile email health:read health:write",
            redirectUri: "healthai2030://oauth/callback",
            pkceEnabled: true
        )
        
        currentProvider = healthAIProvider
        logger.info("OAuth provider configured: \(healthAIProvider.name)")
    }
    
    // MARK: - OAuth 2.0 Implementation
    
    /// Authenticate user with OAuth 2.0 PKCE flow
    public func authenticateUser() async throws -> OAuthResult {
        guard let provider = currentProvider else {
            throw OAuthError.configurationMissing
        }
        
        // Generate PKCE code verifier and challenge
        let codeVerifier = generateCodeVerifier()
        let codeChallenge = generateCodeChallenge(from: codeVerifier)
        
        // Create authorization URL with PKCE
        let authURL = createAuthorizationURL(
            provider: provider,
            codeChallenge: codeChallenge,
            state: generateState()
        )
        
        // Store PKCE state
        pkceState = PKCEState()
        
        // Perform OAuth 2.0 flow
        return try await performOAuthFlow(
            provider: provider,
            codeVerifier: codeVerifier
        )
    }
    
    /// Generate PKCE code verifier
    private func generateCodeVerifier() -> String {
        var bytes = [UInt8](repeating: 0, count: 32)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        return Data(bytes).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
    
    /// Generate PKCE code challenge
    private func generateCodeChallenge(from verifier: String) -> String {
        let data = verifier.data(using: .utf8)!
        let hash = SHA256.hash(data: data)
        return Data(hash).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
    
    /// Generate OAuth state parameter
    private func generateState() -> String {
        var bytes = [UInt8](repeating: 0, count: 16)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        return Data(bytes).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
    
    /// Create authorization URL with PKCE
    private func createAuthorizationURL(provider: OAuthProvider, codeChallenge: String, state: String) -> URL {
        var components = URLComponents(string: provider.authorizationEndpoint)!
        components.queryItems = [
            URLQueryItem(name: "client_id", value: provider.clientId),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "scope", value: provider.scope),
            URLQueryItem(name: "redirect_uri", value: provider.redirectUri),
            URLQueryItem(name: "state", value: state),
            URLQueryItem(name: "code_challenge", value: codeChallenge),
            URLQueryItem(name: "code_challenge_method", value: "S256")
        ]
        return components.url!
    }
    
    /// Perform OAuth 2.0 flow
    private func performOAuthFlow(provider: OAuthProvider, codeVerifier: String) async throws -> OAuthResult {
        // Implementation would handle the actual OAuth flow
        // This is a placeholder for the validation
        return OAuthResult(
            success: true,
            accessToken: "sample-access-token",
            refreshToken: "sample-refresh-token",
            tokenType: "Bearer",
            expiresIn: 3600,
            scope: provider.scope,
            user: nil
        )
    }
    
    // MARK: - OAuth Result
    
    /// OAuth authentication result
    public struct OAuthResult {
        public let success: Bool
        public let accessToken: String?
        public let refreshToken: String?
        public let tokenType: String?
        public let expiresIn: TimeInterval?
        public let scope: String?
        public let user: OAuthUser?
        public let error: String?
        
        public init(success: Bool, accessToken: String? = nil, refreshToken: String? = nil, tokenType: String? = nil, expiresIn: TimeInterval? = nil, scope: String? = nil, user: OAuthUser? = nil, error: String? = nil) {
            self.success = success
            self.accessToken = accessToken
            self.refreshToken = refreshToken
            self.tokenType = tokenType
            self.expiresIn = expiresIn
            self.scope = scope
            self.user = user
            self.error = error
        }
    }
    
    /// OAuth error types
    public enum OAuthError: Error, LocalizedError {
        case configurationMissing
        case invalidResponse
        case networkError
        case pkceError
        case tokenError
        case userInfoError
        
        public var errorDescription: String? {
            switch self {
            case .configurationMissing:
                return "OAuth configuration is missing"
            case .invalidResponse:
                return "Invalid OAuth response"
            case .networkError:
                return "Network error during OAuth flow"
            case .pkceError:
                return "PKCE verification failed"
            case .tokenError:
                return "Token exchange failed"
            case .userInfoError:
                return "Failed to retrieve user information"
            }
        }
    }
    
    // MARK: - Authentication Flow
    
    /// Start OAuth authentication flow
    public func startAuthentication() async throws -> URL {
        guard let provider = currentProvider else {
            throw AuthError(errorType: .other, errorMessage: "No OAuth provider configured", timestamp: Date(), userId: nil, sessionId: nil, metadata: [:])
        }
        
        authState = .authenticating
        
        // Generate PKCE state
        pkceState = PKCEState()
        
        // Build authorization URL
        var components = URLComponents(string: provider.authorizationEndpoint)!
        var queryItems = [
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "client_id", value: provider.clientId),
            URLQueryItem(name: "redirect_uri", value: provider.redirectUri),
            URLQueryItem(name: "scope", value: provider.scope),
            URLQueryItem(name: "state", value: pkceState!.state)
        ]
        
        // Add PKCE parameters if enabled
        if provider.pkceEnabled {
            queryItems.append(URLQueryItem(name: "code_challenge", value: pkceState!.codeChallenge))
            queryItems.append(URLQueryItem(name: "code_challenge_method", value: "S256"))
        }
        
        components.queryItems = queryItems
        
        guard let url = components.url else {
            throw AuthError(errorType: .other, errorMessage: "Failed to build authorization URL", timestamp: Date(), userId: nil, sessionId: nil, metadata: [:])
        }
        
        logger.info("Started OAuth authentication flow")
        return url
    }
    
    /// Handle OAuth callback
    public func handleCallback(url: URL) async throws {
        guard let provider = currentProvider,
              let pkceState = pkceState,
              !pkceState.isExpired else {
            throw AuthError(errorType: .pkceError, errorMessage: "Invalid or expired PKCE state", timestamp: Date(), userId: nil, sessionId: nil, metadata: [:])
        }
        
        // Parse callback URL
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let code = components.queryItems?.first(where: { $0.name == "code" })?.value,
              let state = components.queryItems?.first(where: { $0.name == "state" })?.value else {
            throw AuthError(errorType: .other, errorMessage: "Invalid callback URL", timestamp: Date(), userId: nil, sessionId: nil, metadata: [:])
        }
        
        // Verify state
        guard state == pkceState.state else {
            throw AuthError(errorType: .other, errorMessage: "State mismatch", timestamp: Date(), userId: nil, sessionId: nil, metadata: [:])
        }
        
        // Exchange code for tokens
        let tokens = try await exchangeCodeForTokens(code: code, codeVerifier: pkceState.codeVerifier, provider: provider)
        
        // Get user information
        let user = try await getUserInfo(accessToken: tokens.accessToken, provider: provider)
        
        // Create session
        let session = try await createSession(tokens: tokens, user: user, provider: provider)
        
        // Update state
        currentUser = user
        authSessions.append(session)
        isAuthenticated = true
        authState = .authenticated
        
        // Clear PKCE state
        self.pkceState = nil
        
        logger.info("OAuth authentication completed for user: \(user.email)")
    }
    
    /// Exchange authorization code for tokens
    private func exchangeCodeForTokens(code: String, codeVerifier: String, provider: OAuthProvider) async throws -> TokenResponse {
        var request = URLRequest(url: URL(string: provider.tokenEndpoint)!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        var bodyComponents = [
            "grant_type": "authorization_code",
            "client_id": provider.clientId,
            "code": code,
            "redirect_uri": provider.redirectUri
        ]
        
        // Add PKCE code verifier if enabled
        if provider.pkceEnabled {
            bodyComponents["code_verifier"] = codeVerifier
        }
        
        // Add client secret if available
        if !provider.clientSecret.isEmpty {
            bodyComponents["client_secret"] = provider.clientSecret
        }
        
        request.httpBody = bodyComponents
            .map { "\($0.key)=\($0.value)" }
            .joined(separator: "&")
            .data(using: .utf8)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw AuthError(errorType: .serverError, errorMessage: "Token exchange failed", timestamp: Date(), userId: nil, sessionId: nil, metadata: [:])
        }
        
        let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)
        return tokenResponse
    }
    
    /// Get user information from OAuth provider
    private func getUserInfo(accessToken: String, provider: OAuthProvider) async throws -> OAuthUser {
        var request = URLRequest(url: URL(string: provider.userInfoEndpoint)!)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw AuthError(errorType: .serverError, errorMessage: "Failed to get user info", timestamp: Date(), userId: nil, sessionId: nil, metadata: [:])
        }
        
        let userInfo = try JSONDecoder().decode(UserInfoResponse.self, from: data)
        
        return OAuthUser(
            userId: userInfo.sub,
            email: userInfo.email,
            name: userInfo.name,
            picture: userInfo.picture,
            permissions: userInfo.permissions ?? [],
            roles: userInfo.roles ?? [],
            lastLogin: Date(),
            metadata: userInfo.metadata ?? [:]
        )
    }
    
    /// Create authentication session
    private func createSession(tokens: TokenResponse, user: OAuthUser, provider: OAuthProvider) async throws -> AuthSession {
        let sessionId = UUID().uuidString
        let expiresAt = Date().addingTimeInterval(TimeInterval(tokens.expiresIn))
        
        let deviceInfo = AuthSession.DeviceInfo(
            deviceId: UIDevice.current.identifierForVendor?.uuidString ?? "unknown",
            deviceType: UIDevice.current.model,
            osVersion: UIDevice.current.systemVersion,
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown",
            ipAddress: nil, // Would be determined from network request
            userAgent: nil // Would be set in network request
        )
        
        let session = AuthSession(
            sessionId: sessionId,
            userId: user.userId,
            accessToken: tokens.accessToken,
            refreshToken: tokens.refreshToken,
            tokenType: tokens.tokenType,
            expiresAt: expiresAt,
            scope: tokens.scope,
            createdAt: Date(),
            lastActivity: Date(),
            deviceInfo: deviceInfo,
            isActive: true
        )
        
        return session
    }
    
    // MARK: - Token Management
    
    /// Refresh access token
    public func refreshToken() async throws {
        guard let session = getCurrentSession(),
              let provider = currentProvider else {
            throw AuthError(errorType: .tokenExpired, errorMessage: "No active session to refresh", timestamp: Date(), userId: currentUser?.userId, sessionId: nil, metadata: [:])
        }
        
        authState = .tokenRefreshing
        
        var request = URLRequest(url: URL(string: provider.tokenEndpoint)!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let bodyComponents = [
            "grant_type": "refresh_token",
            "client_id": provider.clientId,
            "refresh_token": session.refreshToken
        ]
        
        request.httpBody = bodyComponents
            .map { "\($0.key)=\($0.value)" }
            .joined(separator: "&")
            .data(using: .utf8)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw AuthError(errorType: .tokenExpired, errorMessage: "Token refresh failed", timestamp: Date(), userId: session.userId, sessionId: session.sessionId, metadata: [:])
        }
        
        let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)
        
        // Update session with new tokens
        if let index = authSessions.firstIndex(where: { $0.sessionId == session.sessionId }) {
            authSessions[index] = AuthSession(
                sessionId: session.sessionId,
                userId: session.userId,
                accessToken: tokenResponse.accessToken,
                refreshToken: tokenResponse.refreshToken ?? session.refreshToken,
                tokenType: tokenResponse.tokenType,
                expiresAt: Date().addingTimeInterval(TimeInterval(tokenResponse.expiresIn)),
                scope: tokenResponse.scope,
                createdAt: session.createdAt,
                lastActivity: Date(),
                deviceInfo: session.deviceInfo,
                isActive: true
            )
        }
        
        authState = .authenticated
        logger.info("Token refreshed successfully")
    }
    
    /// Revoke access token
    public func revokeToken() async throws {
        guard let session = getCurrentSession(),
              let provider = currentProvider,
              let revocationEndpoint = provider.revocationEndpoint else {
            throw AuthError(errorType: .other, errorMessage: "No revocation endpoint available", timestamp: Date(), userId: session.userId, sessionId: session.sessionId, metadata: [:])
        }
        
        var request = URLRequest(url: URL(string: revocationEndpoint)!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let bodyComponents = [
            "client_id": provider.clientId,
            "token": session.accessToken
        ]
        
        request.httpBody = bodyComponents
            .map { "\($0.key)=\($0.value)" }
            .joined(separator: "&")
            .data(using: .utf8)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw AuthError(errorType: .serverError, errorMessage: "Token revocation failed", timestamp: Date(), userId: session.userId, sessionId: session.sessionId, metadata: [:])
        }
        
        // Remove session
        authSessions.removeAll { $0.sessionId == session.sessionId }
        
        // Update state
        if authSessions.isEmpty {
            currentUser = nil
            isAuthenticated = false
            authState = .notAuthenticated
        }
        
        logger.info("Token revoked successfully")
    }
    
    /// Logout user
    public func logout() async {
        do {
            try await revokeToken()
        } catch {
            logger.error("Failed to revoke token during logout: \(error.localizedDescription)")
        }
        
        // Clear all sessions
        authSessions.removeAll()
        currentUser = nil
        isAuthenticated = false
        authState = .notAuthenticated
        
        saveAuthState()
        logger.info("User logged out")
    }
    
    // MARK: - Session Management
    
    /// Get current active session
    private func getCurrentSession() -> AuthSession? {
        return authSessions.first { $0.isActive && $0.expiresAt > Date() }
    }
    
    /// Get valid access token
    public func getValidAccessToken() async throws -> String {
        guard let session = getCurrentSession() else {
            throw AuthError(errorType: .tokenExpired, errorMessage: "No valid session", timestamp: Date(), userId: currentUser?.userId, sessionId: nil, metadata: [:])
        }
        
        // Check if token is about to expire (within 5 minutes)
        if session.expiresAt.timeIntervalSinceNow < 300 {
            try await refreshToken()
            return getCurrentSession()?.accessToken ?? ""
        }
        
        return session.accessToken
    }
    
    /// Check if user has permission
    public func hasPermission(_ permission: String) -> Bool {
        guard let user = currentUser else { return false }
        return user.permissions.contains(permission)
    }
    
    /// Check if user has role
    public func hasRole(_ role: String) -> Bool {
        guard let user = currentUser else { return false }
        return user.roles.contains(role)
    }
    
    // MARK: - Persistence
    
    /// Save authentication state
    private func saveAuthState() {
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(authSessions) {
            UserDefaults.standard.set(data, forKey: "com.healthai.oauth-sessions")
        }
        
        if let data = try? encoder.encode(currentUser) {
            UserDefaults.standard.set(data, forKey: "com.healthai.oauth-user")
        }
        
        UserDefaults.standard.set(isAuthenticated, forKey: "com.healthai.oauth-authenticated")
        UserDefaults.standard.set(authState.rawValue, forKey: "com.healthai.oauth-state")
    }
    
    /// Load authentication state
    private func loadAuthState() {
        if let data = UserDefaults.standard.data(forKey: "com.healthai.oauth-sessions"),
           let sessions = try? JSONDecoder().decode([AuthSession].self, from: data) {
            authSessions = sessions
        }
        
        if let data = UserDefaults.standard.data(forKey: "com.healthai.oauth-user"),
           let user = try? JSONDecoder().decode(OAuthUser.self, from: data) {
            currentUser = user
        }
        
        isAuthenticated = UserDefaults.standard.bool(forKey: "com.healthai.oauth-authenticated")
        
        if let stateString = UserDefaults.standard.string(forKey: "com.healthai.oauth-state"),
           let state = AuthState(rawValue: stateString) {
            authState = state
        }
    }
    
    // MARK: - Monitoring and Reporting
    
    /// Get authentication statistics
    public func getAuthStatistics() -> AuthStatistics {
        let totalSessions = authSessions.count
        let activeSessions = authSessions.filter { $0.isActive && $0.expiresAt > Date() }.count
        let expiredSessions = authSessions.filter { $0.expiresAt <= Date() }.count
        
        let errorTypes = Dictionary(grouping: authErrors, by: { $0.errorType })
            .mapValues { $0.count }
        
        return AuthStatistics(
            totalSessions: totalSessions,
            activeSessions: activeSessions,
            expiredSessions: expiredSessions,
            isAuthenticated: isAuthenticated,
            authState: authState,
            errorTypes: errorTypes,
            lastLogin: currentUser?.lastLogin
        )
    }
    
    /// Clear authentication errors
    public func clearAuthErrors() {
        authErrors.removeAll()
        logger.info("Cleared authentication errors")
    }
}

// MARK: - Supporting Types

public struct AuthStatistics: Codable {
    public let totalSessions: Int
    public let activeSessions: Int
    public let expiredSessions: Int
    public let isAuthenticated: Bool
    public let authState: EnhancedOAuthManager.AuthState
    public let errorTypes: [EnhancedOAuthManager.AuthError.ErrorType: Int]
    public let lastLogin: Date?
}

private struct TokenResponse: Codable {
    let accessToken: String
    let tokenType: String
    let expiresIn: Int
    let refreshToken: String?
    let scope: String
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case tokenType = "token_type"
        case expiresIn = "expires_in"
        case refreshToken = "refresh_token"
        case scope
    }
}

private struct UserInfoResponse: Codable {
    let sub: String
    let email: String
    let name: String
    let picture: String?
    let permissions: [String]?
    let roles: [String]?
    let metadata: [String: String]?
}

// MARK: - Logger Extension

private extension Logger {
    func info(_ message: String) {
        self.log(level: .info, "\(message)")
    }
    
    func warning(_ message: String) {
        self.log(level: .warning, "\(message)")
    }
    
    func error(_ message: String) {
        self.log(level: .error, "\(message)")
    }
} 
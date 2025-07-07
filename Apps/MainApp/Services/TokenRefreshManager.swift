import Foundation
import os.log
import Security

/// Manages authentication tokens and automatic refresh for API requests
@MainActor
class TokenRefreshManager: ObservableObject {
    static let shared = TokenRefreshManager()
    
    private let logger = Logger(subsystem: "com.healthai.authentication", category: "TokenRefresh")
    private let keychain = KeychainManager()
    
    @Published var isRefreshing = false
    @Published var lastRefreshTime: Date?
    
    private var refreshTask: Task<Void, Never>?
    private var refreshTimer: Timer?
    
    private init() {
        setupRefreshTimer()
    }
    
    // MARK: - Token Management
    
    /// Authentication token structure
    struct AuthToken {
        let accessToken: String
        let refreshToken: String
        let expiresAt: Date
        let tokenType: String
        
        var isExpired: Bool {
            return Date() > expiresAt
        }
        
        var willExpireSoon: Bool {
            // Consider token expired if it expires within 5 minutes
            return Date().addingTimeInterval(300) > expiresAt
        }
    }
    
    /// Store authentication tokens securely
    func storeTokens(_ tokens: AuthToken) async throws {
        try await keychain.store(key: "access_token", data: tokens.accessToken.data(using: .utf8)!)
        try await keychain.store(key: "refresh_token", data: tokens.refreshToken.data(using: .utf8)!)
        try await keychain.store(key: "token_expires_at", data: tokens.expiresAt.timeIntervalSince1970.description.data(using: .utf8)!)
        try await keychain.store(key: "token_type", data: tokens.tokenType.data(using: .utf8)!)
        
        lastRefreshTime = Date()
        logger.info("Tokens stored successfully, expires at: \(tokens.expiresAt)")
        
        // Schedule next refresh
        scheduleRefresh(before: tokens.expiresAt)
    }
    
    /// Retrieve stored authentication tokens
    func retrieveTokens() async throws -> AuthToken? {
        guard let accessTokenData = try await keychain.retrieve(key: "access_token"),
              let refreshTokenData = try await keychain.retrieve(key: "refresh_token"),
              let expiresAtData = try await keychain.retrieve(key: "token_expires_at"),
              let tokenTypeData = try await keychain.retrieve(key: "token_type"),
              let accessToken = String(data: accessTokenData, encoding: .utf8),
              let refreshToken = String(data: refreshTokenData, encoding: .utf8),
              let expiresAtString = String(data: expiresAtData, encoding: .utf8),
              let tokenType = String(data: tokenTypeData, encoding: .utf8),
              let expiresAt = Double(expiresAtString) else {
            return nil
        }
        
        return AuthToken(
            accessToken: accessToken,
            refreshToken: refreshToken,
            expiresAt: Date(timeIntervalSince1970: expiresAt),
            tokenType: tokenType
        )
    }
    
    /// Clear stored authentication tokens
    func clearTokens() async throws {
        try await keychain.delete(key: "access_token")
        try await keychain.delete(key: "refresh_token")
        try await keychain.delete(key: "token_expires_at")
        try await keychain.delete(key: "token_type")
        
        refreshTimer?.invalidate()
        refreshTimer = nil
        lastRefreshTime = nil
        
        logger.info("Tokens cleared successfully")
    }
    
    // MARK: - Token Refresh Logic
    
    /// Get a valid access token, refreshing if necessary
    func getValidAccessToken() async throws -> String {
        guard let tokens = try await retrieveTokens() else {
            throw TokenError.noTokensStored
        }
        
        // Check if token is expired or will expire soon
        if tokens.isExpired || tokens.willExpireSoon {
            logger.info("Token expired or expiring soon, refreshing...")
            let newTokens = try await refreshTokens(refreshToken: tokens.refreshToken)
            return newTokens.accessToken
        }
        
        return tokens.accessToken
    }
    
    /// Refresh authentication tokens using refresh token
    func refreshTokens(refreshToken: String) async throws -> AuthToken {
        // Prevent multiple simultaneous refresh attempts
        if isRefreshing {
            // Wait for current refresh to complete
            while isRefreshing {
                try await Task.sleep(for: .milliseconds(100))
            }
            
            // Return the newly refreshed tokens
            guard let tokens = try await retrieveTokens() else {
                throw TokenError.refreshFailed
            }
            return tokens
        }
        
        isRefreshing = true
        defer { isRefreshing = false }
        
        do {
            logger.info("Starting token refresh...")
            
            // Create refresh request
            let refreshEndpoint = APIVersioningManager.shared.buildURL(
                for: APIVersioningManager.APIEndpoint(
                    path: "/auth/refresh",
                    version: .v2,
                    method: .post,
                    description: "Refresh authentication token"
                ),
                environment: .production
            )
            
            var request = URLRequest(url: refreshEndpoint)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let refreshBody = [
                "refresh_token": refreshToken,
                "grant_type": "refresh_token"
            ]
            request.httpBody = try JSONSerialization.data(withJSONObject: refreshBody)
            
            // Perform refresh request with retry logic
            let (data, response) = try await networkErrorHandler.exponentialBackoffRetry {
                try await URLSession.shared.data(for: request)
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw TokenError.invalidResponse
            }
            
            guard httpResponse.statusCode == 200 else {
                logger.error("Token refresh failed with status: \(httpResponse.statusCode)")
                throw TokenError.refreshFailed
            }
            
            // Parse refresh response
            let refreshResponse = try JSONDecoder().decode(TokenRefreshResponse.self, from: data)
            
            // Create new token object
            let newTokens = AuthToken(
                accessToken: refreshResponse.accessToken,
                refreshToken: refreshResponse.refreshToken ?? refreshToken, // Use new refresh token if provided
                expiresAt: Date().addingTimeInterval(refreshResponse.expiresIn),
                tokenType: refreshResponse.tokenType
            )
            
            // Store new tokens
            try await storeTokens(newTokens)
            
            logger.info("Token refresh successful, new token expires at: \(newTokens.expiresAt)")
            return newTokens
            
        } catch {
            logger.error("Token refresh failed: \(error.localizedDescription)")
            
            // If refresh fails, clear tokens and force re-authentication
            try await clearTokens()
            throw TokenError.refreshFailed
        }
    }
    
    /// Force refresh tokens (for testing or manual refresh)
    func forceRefresh() async throws -> AuthToken {
        guard let tokens = try await retrieveTokens() else {
            throw TokenError.noTokensStored
        }
        
        return try await refreshTokens(refreshToken: tokens.refreshToken)
    }
    
    // MARK: - Automatic Refresh Scheduling
    
    private func setupRefreshTimer() {
        // Check token status every minute
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.checkAndRefreshIfNeeded()
            }
        }
    }
    
    private func scheduleRefresh(before expirationDate: Date) {
        // Cancel existing timer
        refreshTimer?.invalidate()
        
        // Calculate time to refresh (5 minutes before expiration)
        let refreshTime = expirationDate.addingTimeInterval(-300)
        let timeUntilRefresh = refreshTime.timeIntervalSinceNow
        
        if timeUntilRefresh > 0 {
            refreshTimer = Timer.scheduledTimer(withTimeInterval: timeUntilRefresh, repeats: false) { [weak self] _ in
                Task { @MainActor in
                    await self?.checkAndRefreshIfNeeded()
                }
            }
            logger.info("Scheduled token refresh for: \(refreshTime)")
        } else {
            // Token expires soon, refresh immediately
            Task { @MainActor in
                await self.checkAndRefreshIfNeeded()
            }
        }
    }
    
    private func checkAndRefreshIfNeeded() async {
        guard let tokens = try await retrieveTokens() else {
            return
        }
        
        if tokens.willExpireSoon {
            logger.info("Token expiring soon, refreshing automatically...")
            do {
                _ = try await refreshTokens(refreshToken: tokens.refreshToken)
            } catch {
                logger.error("Automatic token refresh failed: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Token Validation
    
    /// Validate token without refreshing
    func validateToken() async -> Bool {
        guard let tokens = try await retrieveTokens() else {
            return false
        }
        
        return !tokens.isExpired
    }
    
    /// Get token expiration information
    func getTokenInfo() async -> TokenInfo? {
        guard let tokens = try await retrieveTokens() else {
            return nil
        }
        
        return TokenInfo(
            expiresAt: tokens.expiresAt,
            isExpired: tokens.isExpired,
            willExpireSoon: tokens.willExpireSoon,
            timeUntilExpiration: tokens.expiresAt.timeIntervalSinceNow,
            lastRefreshTime: lastRefreshTime
        )
    }
    
    // MARK: - Network Error Handler
    
    private let networkErrorHandler = NetworkErrorHandler.shared
}

// MARK: - Supporting Types

/// Response from token refresh endpoint
struct TokenRefreshResponse: Codable {
    let accessToken: String
    let refreshToken: String?
    let expiresIn: TimeInterval
    let tokenType: String
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresIn = "expires_in"
        case tokenType = "token_type"
    }
}

/// Token information for monitoring
struct TokenInfo {
    let expiresAt: Date
    let isExpired: Bool
    let willExpireSoon: Bool
    let timeUntilExpiration: TimeInterval
    let lastRefreshTime: Date?
}

/// Token-related errors
enum TokenError: LocalizedError {
    case noTokensStored
    case refreshFailed
    case invalidResponse
    case invalidRefreshToken
    
    var errorDescription: String? {
        switch self {
        case .noTokensStored:
            return "No authentication tokens are stored"
        case .refreshFailed:
            return "Failed to refresh authentication tokens"
        case .invalidResponse:
            return "Invalid response from token refresh endpoint"
        case .invalidRefreshToken:
            return "Invalid or expired refresh token"
        }
    }
}

// MARK: - Keychain Manager

/// Secure keychain operations for token storage
class KeychainManager {
    private let service = "com.healthai2030.authentication"
    
    func store(key: String, data: Data) async throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        if status == errSecDuplicateItem {
            // Item already exists, update it
            let updateQuery: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: service,
                kSecAttrAccount as String: key
            ]
            
            let updateAttributes: [String: Any] = [
                kSecValueData as String: data
            ]
            
            let updateStatus = SecItemUpdate(updateQuery as CFDictionary, updateAttributes as CFDictionary)
            guard updateStatus == errSecSuccess else {
                throw KeychainError.saveFailed(updateStatus)
            }
        } else if status != errSecSuccess {
            throw KeychainError.saveFailed(status)
        }
    }
    
    func retrieve(key: String) async throws -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess else {
            if status == errSecItemNotFound {
                return nil
            }
            throw KeychainError.retrieveFailed(status)
        }
        
        return result as? Data
    }
    
    func delete(key: String) async throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.deleteFailed(status)
        }
    }
}

/// Keychain operation errors
enum KeychainError: LocalizedError {
    case saveFailed(OSStatus)
    case retrieveFailed(OSStatus)
    case deleteFailed(OSStatus)
    
    var errorDescription: String? {
        switch self {
        case .saveFailed(let status):
            return "Failed to save to keychain: \(status)"
        case .retrieveFailed(let status):
            return "Failed to retrieve from keychain: \(status)"
        case .deleteFailed(let status):
            return "Failed to delete from keychain: \(status)"
        }
    }
} 
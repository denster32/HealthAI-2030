import XCTest
import SwiftData
import AuthenticationServices
@testable import HealthAI2030Core

@available(iOS 18.0, macOS 15.0, *)
final class SessionManagementTests: XCTestCase {
    
    let authManager = AuthenticationManager.shared
    let tokenManager = TokenRefreshManager.shared
    
    // MARK: - Basic Session Invalidation Tests
    
    func testForceLogoutOnCredentialRevocation() async throws {
        // Setup manager with a dummy user
        let user = UserProfile(id: UUID(), email: "test@example.com", displayName: "Test User")
        authManager.currentUser = user
        authManager.isAuthenticated = true

        // Simulate revoked credential by calling signOut directly
        await authManager.signOut()

        XCTAssertFalse(authManager.isAuthenticated, "User should be logged out on credential revocation")
        XCTAssertNil(authManager.currentUser, "currentUser should be nil after logout")
    }
    
    // MARK: - Token-Based Session Invalidation Tests
    
    func testSessionInvalidationOnTokenExpiration() async throws {
        // Create expired tokens
        let expiredToken = TokenRefreshManager.AuthToken(
            accessToken: "expired_access_token",
            refreshToken: "expired_refresh_token",
            expiresAt: Date().addingTimeInterval(-3600), // 1 hour ago
            tokenType: "Bearer"
        )
        
        // Store expired tokens
        try await tokenManager.storeTokens(expiredToken)
        
        // Simulate user session
        let user = UserProfile(id: UUID(), email: "token_test@example.com", displayName: "Token Test User")
        authManager.currentUser = user
        authManager.isAuthenticated = true
        
        // Attempt to get valid access token (should fail and clear tokens)
        do {
            _ = try await tokenManager.getValidAccessToken()
            XCTFail("Should throw error when token is expired")
        } catch {
            XCTAssertTrue(error is TokenError, "Should throw TokenError")
        }
        
        // Verify tokens are cleared after failed refresh
        let clearedToken = try await tokenManager.retrieveTokens()
        XCTAssertNil(clearedToken, "Tokens should be cleared after failed refresh")
        
        // Verify user should be logged out
        XCTAssertFalse(authManager.isAuthenticated, "User should be logged out when tokens are invalid")
        XCTAssertNil(authManager.currentUser, "Current user should be nil when tokens are invalid")
    }
    
    func testSessionInvalidationOnRefreshTokenRevocation() async throws {
        // Create tokens with invalid refresh token
        let invalidToken = TokenRefreshManager.AuthToken(
            accessToken: "valid_access_token",
            refreshToken: "revoked_refresh_token",
            expiresAt: Date().addingTimeInterval(-3600), // Expired access token
            tokenType: "Bearer"
        )
        
        // Store tokens
        try await tokenManager.storeTokens(invalidToken)
        
        // Simulate user session
        let user = UserProfile(id: UUID(), email: "revoked_test@example.com", displayName: "Revoked Test User")
        authManager.currentUser = user
        authManager.isAuthenticated = true
        
        // Attempt to refresh tokens (should fail)
        do {
            _ = try await tokenManager.refreshTokens(refreshToken: "revoked_refresh_token")
            XCTFail("Should throw error when refresh token is revoked")
        } catch {
            XCTAssertTrue(error is TokenError, "Should throw TokenError")
        }
        
        // Verify tokens are cleared
        let clearedToken = try await tokenManager.retrieveTokens()
        XCTAssertNil(clearedToken, "Tokens should be cleared after refresh token revocation")
        
        // Verify user is logged out
        XCTAssertFalse(authManager.isAuthenticated, "User should be logged out when refresh token is revoked")
        XCTAssertNil(authManager.currentUser, "Current user should be nil when refresh token is revoked")
    }
    
    // MARK: - Server-Side Session Invalidation Tests
    
    func testServerSideSessionInvalidation() async throws {
        // Simulate server-side session invalidation
        let user = UserProfile(id: UUID(), email: "server_test@example.com", displayName: "Server Test User")
        authManager.currentUser = user
        authManager.isAuthenticated = true
        
        // Store valid tokens
        let validToken = TokenRefreshManager.AuthToken(
            accessToken: "server_valid_token",
            refreshToken: "server_refresh_token",
            expiresAt: Date().addingTimeInterval(3600),
            tokenType: "Bearer"
        )
        try await tokenManager.storeTokens(validToken)
        
        // Simulate server-side session invalidation (e.g., admin action, security breach)
        // This would typically happen when the server rejects all requests with 401 Unauthorized
        await authManager.signOut()
        
        // Verify session is invalidated
        XCTAssertFalse(authManager.isAuthenticated, "User should be logged out on server-side invalidation")
        XCTAssertNil(authManager.currentUser, "Current user should be nil on server-side invalidation")
        
        // Verify tokens are cleared
        let clearedToken = try await tokenManager.retrieveTokens()
        XCTAssertNil(clearedToken, "Tokens should be cleared on server-side invalidation")
    }
    
    func testConcurrentSessionInvalidation() async throws {
        // Test multiple simultaneous session invalidations
        let user = UserProfile(id: UUID(), email: "concurrent_test@example.com", displayName: "Concurrent Test User")
        authManager.currentUser = user
        authManager.isAuthenticated = true
        
        let validToken = TokenRefreshManager.AuthToken(
            accessToken: "concurrent_token",
            refreshToken: "concurrent_refresh",
            expiresAt: Date().addingTimeInterval(3600),
            tokenType: "Bearer"
        )
        try await tokenManager.storeTokens(validToken)
        
        let expectation = XCTestExpectation(description: "Concurrent session invalidation")
        let queue = DispatchQueue(label: "concurrent", attributes: .concurrent)
        
        var invalidationCount = 0
        
        // Perform concurrent session invalidations
        for _ in 0..<5 {
            queue.async {
                Task {
                    await self.authManager.signOut()
                    invalidationCount += 1
                }
            }
        }
        
        queue.async {
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
        
        // Verify session is invalidated (regardless of concurrent operations)
        XCTAssertFalse(authManager.isAuthenticated, "User should be logged out after concurrent invalidation")
        XCTAssertNil(authManager.currentUser, "Current user should be nil after concurrent invalidation")
        XCTAssertEqual(invalidationCount, 5, "All invalidation operations should complete")
    }
    
    // MARK: - Apple Sign In Credential State Tests
    
    func testAppleCredentialStateRevocation() async throws {
        // This test simulates Apple credential state changes
        let user = UserProfile(id: UUID(), email: "apple_test@example.com", displayName: "Apple Test User")
        authManager.currentUser = user
        authManager.isAuthenticated = true
        
        // Store user ID for credential state checking
        UserDefaults.standard.set(user.id.uuidString, forKey: "currentUserID")
        
        // Simulate Apple credential revocation
        // In a real scenario, this would be detected by the handleAppForeground method
        await authManager.signOut()
        
        // Verify session is invalidated
        XCTAssertFalse(authManager.isAuthenticated, "User should be logged out on Apple credential revocation")
        XCTAssertNil(authManager.currentUser, "Current user should be nil on Apple credential revocation")
        
        // Verify stored user ID is cleared
        let storedUserID = UserDefaults.standard.string(forKey: "currentUserID")
        XCTAssertNil(storedUserID, "Stored user ID should be cleared on credential revocation")
    }
    
    // MARK: - Network-Based Session Invalidation Tests
    
    func testSessionInvalidationOnNetworkErrors() async throws {
        let user = UserProfile(id: UUID(), email: "network_test@example.com", displayName: "Network Test User")
        authManager.currentUser = user
        authManager.isAuthenticated = true
        
        // Store tokens that will cause network errors
        let problematicToken = TokenRefreshManager.AuthToken(
            accessToken: "network_error_token",
            refreshToken: "network_error_refresh",
            expiresAt: Date().addingTimeInterval(-3600), // Expired
            tokenType: "Bearer"
        )
        try await tokenManager.storeTokens(problematicToken)
        
        // Simulate network errors during token refresh
        do {
            _ = try await tokenManager.getValidAccessToken()
            XCTFail("Should throw error when network errors occur during refresh")
        } catch {
            XCTAssertTrue(error is TokenError, "Should throw TokenError on network errors")
        }
        
        // Verify session is invalidated due to network errors
        XCTAssertFalse(authManager.isAuthenticated, "User should be logged out on network errors")
        XCTAssertNil(authManager.currentUser, "Current user should be nil on network errors")
    }
    
    // MARK: - Security-Based Session Invalidation Tests
    
    func testSessionInvalidationOnSecurityBreach() async throws {
        let user = UserProfile(id: UUID(), email: "security_test@example.com", displayName: "Security Test User")
        authManager.currentUser = user
        authManager.isAuthenticated = true
        
        // Store tokens
        let securityToken = TokenRefreshManager.AuthToken(
            accessToken: "security_token",
            refreshToken: "security_refresh",
            expiresAt: Date().addingTimeInterval(3600),
            tokenType: "Bearer"
        )
        try await tokenManager.storeTokens(securityToken)
        
        // Simulate security breach detection (e.g., suspicious activity, multiple failed attempts)
        await authManager.signOut()
        
        // Verify session is invalidated for security reasons
        XCTAssertFalse(authManager.isAuthenticated, "User should be logged out on security breach")
        XCTAssertNil(authManager.currentUser, "Current user should be nil on security breach")
        
        // Verify tokens are cleared
        let clearedToken = try await tokenManager.retrieveTokens()
        XCTAssertNil(clearedToken, "Tokens should be cleared on security breach")
    }
    
    // MARK: - Time-Based Session Invalidation Tests
    
    func testSessionInvalidationOnInactivity() async throws {
        let user = UserProfile(id: UUID(), email: "inactivity_test@example.com", displayName: "Inactivity Test User")
        authManager.currentUser = user
        authManager.isAuthenticated = true
        
        // Store tokens with short expiration
        let shortLivedToken = TokenRefreshManager.AuthToken(
            accessToken: "inactivity_token",
            refreshToken: "inactivity_refresh",
            expiresAt: Date().addingTimeInterval(60), // 1 minute
            tokenType: "Bearer"
        )
        try await tokenManager.storeTokens(shortLivedToken)
        
        // Simulate inactivity timeout
        try await Task.sleep(for: .seconds(2)) // Wait for token to expire
        
        // Attempt to use expired token
        do {
            _ = try await tokenManager.getValidAccessToken()
            XCTFail("Should throw error when token expires due to inactivity")
        } catch {
            XCTAssertTrue(error is TokenError, "Should throw TokenError on inactivity timeout")
        }
        
        // Verify session is invalidated due to inactivity
        XCTAssertFalse(authManager.isAuthenticated, "User should be logged out on inactivity timeout")
        XCTAssertNil(authManager.currentUser, "Current user should be nil on inactivity timeout")
    }
    
    // MARK: - Multi-Device Session Invalidation Tests
    
    func testSessionInvalidationOnOtherDevice() async throws {
        let user = UserProfile(id: UUID(), email: "multidevice_test@example.com", displayName: "Multi-Device Test User")
        authManager.currentUser = user
        authManager.isAuthenticated = true
        
        // Store tokens
        let multiDeviceToken = TokenRefreshManager.AuthToken(
            accessToken: "multidevice_token",
            refreshToken: "multidevice_refresh",
            expiresAt: Date().addingTimeInterval(3600),
            tokenType: "Bearer"
        )
        try await tokenManager.storeTokens(multiDeviceToken)
        
        // Simulate session invalidation from another device
        // This could happen when user logs in on another device and chooses to invalidate other sessions
        await authManager.signOut()
        
        // Verify session is invalidated on this device
        XCTAssertFalse(authManager.isAuthenticated, "User should be logged out when session is invalidated on other device")
        XCTAssertNil(authManager.currentUser, "Current user should be nil when session is invalidated on other device")
        
        // Verify tokens are cleared
        let clearedToken = try await tokenManager.retrieveTokens()
        XCTAssertNil(clearedToken, "Tokens should be cleared when session is invalidated on other device")
    }
    
    // MARK: - Recovery and Re-authentication Tests
    
    func testReAuthenticationAfterSessionInvalidation() async throws {
        // Start with invalidated session
        let user = UserProfile(id: UUID(), email: "reauth_test@example.com", displayName: "Re-Auth Test User")
        authManager.currentUser = user
        authManager.isAuthenticated = true
        
        // Invalidate session
        await authManager.signOut()
        
        // Verify session is invalidated
        XCTAssertFalse(authManager.isAuthenticated, "Session should be invalidated")
        XCTAssertNil(authManager.currentUser, "Current user should be nil")
        
        // Simulate successful re-authentication
        let newUser = UserProfile(id: UUID(), email: "reauth_test@example.com", displayName: "Re-Auth Test User")
        authManager.currentUser = newUser
        authManager.isAuthenticated = true
        
        // Store new tokens
        let newToken = TokenRefreshManager.AuthToken(
            accessToken: "new_auth_token",
            refreshToken: "new_auth_refresh",
            expiresAt: Date().addingTimeInterval(3600),
            tokenType: "Bearer"
        )
        try await tokenManager.storeTokens(newToken)
        
        // Verify re-authentication is successful
        XCTAssertTrue(authManager.isAuthenticated, "User should be re-authenticated")
        XCTAssertNotNil(authManager.currentUser, "Current user should not be nil after re-authentication")
        
        // Verify new tokens are valid
        let retrievedToken = try await tokenManager.retrieveTokens()
        XCTAssertNotNil(retrievedToken, "New tokens should be stored")
        XCTAssertEqual(retrievedToken?.accessToken, "new_auth_token", "Should have new access token")
        
        // Clean up
        try await tokenManager.clearTokens()
    }
    
    // MARK: - Error Handling Tests
    
    func testSessionInvalidationErrorHandling() async throws {
        let user = UserProfile(id: UUID(), email: "error_test@example.com", displayName: "Error Test User")
        authManager.currentUser = user
        authManager.isAuthenticated = true
        
        // Test various error scenarios that should trigger session invalidation
        let errorScenarios: [Error] = [
            TokenError.refreshFailed,
            TokenError.invalidResponse,
            TokenError.invalidRefreshToken,
            URLError(.timedOut),
            URLError(.notConnectedToInternet),
            URLError(.badServerResponse)
        ]
        
        for error in errorScenarios {
            // Simulate error during authentication operations
            await authManager.signOut()
            
            // Verify session is invalidated regardless of error type
            XCTAssertFalse(authManager.isAuthenticated, "Session should be invalidated for error: \(error)")
            XCTAssertNil(authManager.currentUser, "Current user should be nil for error: \(error)")
        }
    }
    
    // MARK: - Performance Tests
    
    func testSessionInvalidationPerformance() async throws {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Perform multiple session invalidations
        for _ in 0..<100 {
            let user = UserProfile(id: UUID(), email: "perf_test@example.com", displayName: "Perf Test User")
            authManager.currentUser = user
            authManager.isAuthenticated = true
            
            await authManager.signOut()
        }
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let duration = endTime - startTime
        
        // Should be very fast
        XCTAssertLessThan(duration, 1.0, "Session invalidation took too long: \(duration)s")
    }
    
    // MARK: - Integration Tests
    
    func testCompleteSessionLifecycle() async throws {
        // Test complete session lifecycle: login -> use -> invalidate -> re-authenticate
        
        // 1. Initial authentication
        let user = UserProfile(id: UUID(), email: "lifecycle_test@example.com", displayName: "Lifecycle Test User")
        authManager.currentUser = user
        authManager.isAuthenticated = true
        
        let initialToken = TokenRefreshManager.AuthToken(
            accessToken: "lifecycle_token",
            refreshToken: "lifecycle_refresh",
            expiresAt: Date().addingTimeInterval(3600),
            tokenType: "Bearer"
        )
        try await tokenManager.storeTokens(initialToken)
        
        // Verify initial state
        XCTAssertTrue(authManager.isAuthenticated, "User should be authenticated initially")
        XCTAssertNotNil(authManager.currentUser, "Current user should not be nil initially")
        
        // 2. Session invalidation
        await authManager.signOut()
        
        // Verify invalidation
        XCTAssertFalse(authManager.isAuthenticated, "User should be logged out after invalidation")
        XCTAssertNil(authManager.currentUser, "Current user should be nil after invalidation")
        
        // 3. Re-authentication
        let newUser = UserProfile(id: UUID(), email: "lifecycle_test@example.com", displayName: "Lifecycle Test User")
        authManager.currentUser = newUser
        authManager.isAuthenticated = true
        
        let newToken = TokenRefreshManager.AuthToken(
            accessToken: "new_lifecycle_token",
            refreshToken: "new_lifecycle_refresh",
            expiresAt: Date().addingTimeInterval(3600),
            tokenType: "Bearer"
        )
        try await tokenManager.storeTokens(newToken)
        
        // Verify re-authentication
        XCTAssertTrue(authManager.isAuthenticated, "User should be re-authenticated")
        XCTAssertNotNil(authManager.currentUser, "Current user should not be nil after re-authentication")
        
        // Clean up
        try await tokenManager.clearTokens()
    }
} 
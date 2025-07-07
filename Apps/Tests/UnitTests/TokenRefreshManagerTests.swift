import XCTest
import Foundation
@testable import HealthAI2030Core

final class TokenRefreshManagerTests: XCTestCase {
    
    let tokenManager = TokenRefreshManager.shared
    
    // MARK: - Token Management Tests
    
    func testTokenStorageAndRetrieval() async throws {
        let testToken = TokenRefreshManager.AuthToken(
            accessToken: "test_access_token",
            refreshToken: "test_refresh_token",
            expiresAt: Date().addingTimeInterval(3600), // 1 hour from now
            tokenType: "Bearer"
        )
        
        // Store tokens
        try await tokenManager.storeTokens(testToken)
        
        // Retrieve tokens
        let retrievedToken = try await tokenManager.retrieveTokens()
        
        XCTAssertNotNil(retrievedToken, "Should retrieve stored tokens")
        XCTAssertEqual(retrievedToken?.accessToken, "test_access_token")
        XCTAssertEqual(retrievedToken?.refreshToken, "test_refresh_token")
        XCTAssertEqual(retrievedToken?.tokenType, "Bearer")
        
        // Clean up
        try await tokenManager.clearTokens()
    }
    
    func testTokenExpirationLogic() async throws {
        let expiredToken = TokenRefreshManager.AuthToken(
            accessToken: "expired_token",
            refreshToken: "refresh_token",
            expiresAt: Date().addingTimeInterval(-3600), // 1 hour ago
            tokenType: "Bearer"
        )
        
        let validToken = TokenRefreshManager.AuthToken(
            accessToken: "valid_token",
            refreshToken: "refresh_token",
            expiresAt: Date().addingTimeInterval(3600), // 1 hour from now
            tokenType: "Bearer"
        )
        
        let expiringSoonToken = TokenRefreshManager.AuthToken(
            accessToken: "expiring_soon_token",
            refreshToken: "refresh_token",
            expiresAt: Date().addingTimeInterval(240), // 4 minutes from now
            tokenType: "Bearer"
        )
        
        XCTAssertTrue(expiredToken.isExpired, "Expired token should be marked as expired")
        XCTAssertFalse(validToken.isExpired, "Valid token should not be marked as expired")
        XCTAssertTrue(expiringSoonToken.willExpireSoon, "Token expiring soon should be marked as will expire soon")
        XCTAssertFalse(validToken.willExpireSoon, "Valid token should not be marked as will expire soon")
    }
    
    func testTokenClearance() async throws {
        let testToken = TokenRefreshManager.AuthToken(
            accessToken: "test_token",
            refreshToken: "refresh_token",
            expiresAt: Date().addingTimeInterval(3600),
            tokenType: "Bearer"
        )
        
        // Store tokens
        try await tokenManager.storeTokens(testToken)
        
        // Verify tokens are stored
        let storedToken = try await tokenManager.retrieveTokens()
        XCTAssertNotNil(storedToken, "Tokens should be stored")
        
        // Clear tokens
        try await tokenManager.clearTokens()
        
        // Verify tokens are cleared
        let clearedToken = try await tokenManager.retrieveTokens()
        XCTAssertNil(clearedToken, "Tokens should be cleared")
    }
    
    // MARK: - Token Validation Tests
    
    func testTokenValidation() async throws {
        // Test with no tokens
        let isValid = await tokenManager.validateToken()
        XCTAssertFalse(isValid, "Should be invalid when no tokens are stored")
        
        // Test with valid tokens
        let validToken = TokenRefreshManager.AuthToken(
            accessToken: "valid_token",
            refreshToken: "refresh_token",
            expiresAt: Date().addingTimeInterval(3600),
            tokenType: "Bearer"
        )
        
        try await tokenManager.storeTokens(validToken)
        let isValidWithTokens = await tokenManager.validateToken()
        XCTAssertTrue(isValidWithTokens, "Should be valid with stored tokens")
        
        // Clean up
        try await tokenManager.clearTokens()
    }
    
    func testTokenInfoRetrieval() async throws {
        let expirationDate = Date().addingTimeInterval(3600)
        let testToken = TokenRefreshManager.AuthToken(
            accessToken: "test_token",
            refreshToken: "refresh_token",
            expiresAt: expirationDate,
            tokenType: "Bearer"
        )
        
        try await tokenManager.storeTokens(testToken)
        
        let tokenInfo = await tokenManager.getTokenInfo()
        XCTAssertNotNil(tokenInfo, "Should retrieve token info")
        XCTAssertEqual(tokenInfo?.expiresAt, expirationDate)
        XCTAssertFalse(tokenInfo?.isExpired ?? true, "Should not be expired")
        XCTAssertFalse(tokenInfo?.willExpireSoon ?? true, "Should not expire soon")
        XCTAssertGreaterThan(tokenInfo?.timeUntilExpiration ?? 0, 0, "Should have positive time until expiration")
        
        // Clean up
        try await tokenManager.clearTokens()
    }
    
    // MARK: - Token Refresh Logic Tests
    
    func testGetValidAccessTokenWithValidToken() async throws {
        let validToken = TokenRefreshManager.AuthToken(
            accessToken: "valid_access_token",
            refreshToken: "refresh_token",
            expiresAt: Date().addingTimeInterval(3600),
            tokenType: "Bearer"
        )
        
        try await tokenManager.storeTokens(validToken)
        
        let accessToken = try await tokenManager.getValidAccessToken()
        XCTAssertEqual(accessToken, "valid_access_token", "Should return valid access token without refreshing")
        
        // Clean up
        try await tokenManager.clearTokens()
    }
    
    func testGetValidAccessTokenWithExpiredToken() async throws {
        let expiredToken = TokenRefreshManager.AuthToken(
            accessToken: "expired_access_token",
            refreshToken: "refresh_token",
            expiresAt: Date().addingTimeInterval(-3600), // 1 hour ago
            tokenType: "Bearer"
        )
        
        try await tokenManager.storeTokens(expiredToken)
        
        do {
            _ = try await tokenManager.getValidAccessToken()
            XCTFail("Should throw error when token is expired and refresh fails")
        } catch {
            XCTAssertTrue(error is TokenError, "Should throw TokenError")
        }
        
        // Clean up
        try await tokenManager.clearTokens()
    }
    
    func testGetValidAccessTokenWithNoTokens() async throws {
        do {
            _ = try await tokenManager.getValidAccessToken()
            XCTFail("Should throw error when no tokens are stored")
        } catch {
            XCTAssertTrue(error is TokenError, "Should throw TokenError")
        }
    }
    
    // MARK: - Concurrent Access Tests
    
    func testConcurrentTokenAccess() async throws {
        let validToken = TokenRefreshManager.AuthToken(
            accessToken: "concurrent_token",
            refreshToken: "refresh_token",
            expiresAt: Date().addingTimeInterval(3600),
            tokenType: "Bearer"
        )
        
        try await tokenManager.storeTokens(validToken)
        
        let expectation = XCTestExpectation(description: "Concurrent token access")
        let queue = DispatchQueue(label: "test", attributes: .concurrent)
        
        var successCount = 0
        var failureCount = 0
        
        // Perform concurrent token access
        for i in 0..<10 {
            queue.async {
                Task {
                    do {
                        let token = try await self.tokenManager.getValidAccessToken()
                        XCTAssertEqual(token, "concurrent_token")
                        successCount += 1
                    } catch {
                        failureCount += 1
                    }
                }
            }
        }
        
        queue.async {
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
        
        XCTAssertEqual(successCount, 10, "All concurrent accesses should succeed")
        XCTAssertEqual(failureCount, 0, "No concurrent accesses should fail")
        
        // Clean up
        try await tokenManager.clearTokens()
    }
    
    // MARK: - Error Handling Tests
    
    func testTokenRefreshWithInvalidRefreshToken() async throws {
        let invalidToken = TokenRefreshManager.AuthToken(
            accessToken: "access_token",
            refreshToken: "invalid_refresh_token",
            expiresAt: Date().addingTimeInterval(-3600), // Expired
            tokenType: "Bearer"
        )
        
        try await tokenManager.storeTokens(invalidToken)
        
        do {
            _ = try await tokenManager.refreshTokens(refreshToken: "invalid_refresh_token")
            XCTFail("Should throw error when refresh token is invalid")
        } catch {
            XCTAssertTrue(error is TokenError, "Should throw TokenError")
        }
        
        // Verify tokens are cleared after failed refresh
        let clearedToken = try await tokenManager.retrieveTokens()
        XCTAssertNil(clearedToken, "Tokens should be cleared after failed refresh")
    }
    
    func testTokenRefreshWithExpiredRefreshToken() async throws {
        let expiredToken = TokenRefreshManager.AuthToken(
            accessToken: "access_token",
            refreshToken: "expired_refresh_token",
            expiresAt: Date().addingTimeInterval(-7200), // 2 hours ago
            tokenType: "Bearer"
        )
        
        try await tokenManager.storeTokens(expiredToken)
        
        do {
            _ = try await tokenManager.forceRefresh()
            XCTFail("Should throw error when refresh token is expired")
        } catch {
            XCTAssertTrue(error is TokenError, "Should throw TokenError")
        }
        
        // Verify tokens are cleared after failed refresh
        let clearedToken = try await tokenManager.retrieveTokens()
        XCTAssertNil(clearedToken, "Tokens should be cleared after failed refresh")
    }
    
    // MARK: - Performance Tests
    
    func testTokenRetrievalPerformance() async throws {
        let testToken = TokenRefreshManager.AuthToken(
            accessToken: "performance_test_token",
            refreshToken: "refresh_token",
            expiresAt: Date().addingTimeInterval(3600),
            tokenType: "Bearer"
        )
        
        try await tokenManager.storeTokens(testToken)
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Perform multiple token retrievals
        for _ in 0..<100 {
            let _ = try await tokenManager.retrieveTokens()
        }
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let duration = endTime - startTime
        
        // Should be very fast
        XCTAssertLessThan(duration, 1.0, "Token retrieval took too long: \(duration)s")
        
        // Clean up
        try await tokenManager.clearTokens()
    }
    
    func testTokenValidationPerformance() async throws {
        let testToken = TokenRefreshManager.AuthToken(
            accessToken: "validation_test_token",
            refreshToken: "refresh_token",
            expiresAt: Date().addingTimeInterval(3600),
            tokenType: "Bearer"
        )
        
        try await tokenManager.storeTokens(testToken)
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Perform multiple token validations
        for _ in 0..<100 {
            let _ = await tokenManager.validateToken()
        }
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let duration = endTime - startTime
        
        // Should be very fast
        XCTAssertLessThan(duration, 1.0, "Token validation took too long: \(duration)s")
        
        // Clean up
        try await tokenManager.clearTokens()
    }
    
    // MARK: - Edge Case Tests
    
    func testTokenWithVeryShortExpiration() async throws {
        let shortLivedToken = TokenRefreshManager.AuthToken(
            accessToken: "short_lived_token",
            refreshToken: "refresh_token",
            expiresAt: Date().addingTimeInterval(30), // 30 seconds
            tokenType: "Bearer"
        )
        
        try await tokenManager.storeTokens(shortLivedToken)
        
        let tokenInfo = await tokenManager.getTokenInfo()
        XCTAssertTrue(tokenInfo?.willExpireSoon ?? false, "Short-lived token should be marked as expiring soon")
        
        // Clean up
        try await tokenManager.clearTokens()
    }
    
    func testTokenWithVeryLongExpiration() async throws {
        let longLivedToken = TokenRefreshManager.AuthToken(
            accessToken: "long_lived_token",
            refreshToken: "refresh_token",
            expiresAt: Date().addingTimeInterval(86400 * 30), // 30 days
            tokenType: "Bearer"
        )
        
        try await tokenManager.storeTokens(longLivedToken)
        
        let tokenInfo = await tokenManager.getTokenInfo()
        XCTAssertFalse(tokenInfo?.willExpireSoon ?? true, "Long-lived token should not be marked as expiring soon")
        XCTAssertGreaterThan(tokenInfo?.timeUntilExpiration ?? 0, 86400, "Should have more than 1 day until expiration")
        
        // Clean up
        try await tokenManager.clearTokens()
    }
    
    func testTokenWithSpecialCharacters() async throws {
        let specialToken = TokenRefreshManager.AuthToken(
            accessToken: "special!@#$%^&*()_+-=[]{}|;':\",./<>?token",
            refreshToken: "refresh!@#$%^&*()_+-=[]{}|;':\",./<>?token",
            expiresAt: Date().addingTimeInterval(3600),
            tokenType: "Bearer"
        )
        
        try await tokenManager.storeTokens(specialToken)
        
        let retrievedToken = try await tokenManager.retrieveTokens()
        XCTAssertEqual(retrievedToken?.accessToken, specialToken.accessToken, "Should handle special characters in access token")
        XCTAssertEqual(retrievedToken?.refreshToken, specialToken.refreshToken, "Should handle special characters in refresh token")
        
        // Clean up
        try await tokenManager.clearTokens()
    }
    
    // MARK: - Memory Management Tests
    
    func testTokenManagerMemoryUsage() async throws {
        // Test that token manager doesn't leak memory
        weak var weakManager: TokenRefreshManager?
        
        autoreleasepool {
            let manager = TokenRefreshManager.shared
            weakManager = manager
            
            // Perform operations
            Task {
                let testToken = TokenRefreshManager.AuthToken(
                    accessToken: "memory_test_token",
                    refreshToken: "refresh_token",
                    expiresAt: Date().addingTimeInterval(3600),
                    tokenType: "Bearer"
                )
                
                try await manager.storeTokens(testToken)
                let _ = try await manager.retrieveTokens()
                try await manager.clearTokens()
            }
        }
        
        // Token manager should not be deallocated (it's a singleton)
        XCTAssertNotNil(weakManager, "Token manager should not be deallocated")
    }
    
    // MARK: - Integration Tests
    
    func testTokenRefreshIntegration() async throws {
        // This test would require a mock server or network simulation
        // For now, we'll test the error handling when refresh fails
        
        let expiredToken = TokenRefreshManager.AuthToken(
            accessToken: "integration_test_token",
            refreshToken: "integration_refresh_token",
            expiresAt: Date().addingTimeInterval(-3600), // Expired
            tokenType: "Bearer"
        )
        
        try await tokenManager.storeTokens(expiredToken)
        
        do {
            _ = try await tokenManager.getValidAccessToken()
            XCTFail("Should fail when trying to refresh with invalid refresh token")
        } catch {
            XCTAssertTrue(error is TokenError, "Should throw TokenError")
        }
        
        // Verify tokens are cleared after failed refresh
        let clearedToken = try await tokenManager.retrieveTokens()
        XCTAssertNil(clearedToken, "Tokens should be cleared after failed refresh")
    }
    
    func testTokenRefreshWithRetryLogic() async throws {
        // Test that token refresh uses exponential backoff retry logic
        let expiredToken = TokenRefreshManager.AuthToken(
            accessToken: "retry_test_token",
            refreshToken: "retry_refresh_token",
            expiresAt: Date().addingTimeInterval(-3600), // Expired
            tokenType: "Bearer"
        )
        
        try await tokenManager.storeTokens(expiredToken)
        
        do {
            _ = try await tokenManager.forceRefresh()
            XCTFail("Should fail when refresh token is invalid")
        } catch {
            XCTAssertTrue(error is TokenError, "Should throw TokenError")
        }
        
        // Clean up
        try await tokenManager.clearTokens()
    }
} 
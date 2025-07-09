import XCTest
import Foundation
import Combine
@testable import HealthAI2030

@MainActor
final class TokenRefreshManagerTests: XCTestCase {
    
    var tokenManager: TokenRefreshManager!
    var cancellables: Set<AnyCancellable>!
    var mockKeychain: MockKeychainManager!
    
    override func setUp() {
        super.setUp()
        cancellables = Set<AnyCancellable>()
        mockKeychain = MockKeychainManager()
        tokenManager = TokenRefreshManager.shared
        // Reset the shared instance for testing
        tokenManager.clearTokens()
    }
    
    override func tearDown() {
        cancellables = nil
        mockKeychain = nil
        tokenManager.clearTokens()
        super.tearDown()
    }
    
    // MARK: - Token Storage Tests
    
    func testStoreTokensSuccessfully() async throws {
        // Given
        let testToken = TokenRefreshManager.AuthToken(
            accessToken: "test_access_token",
            refreshToken: "test_refresh_token",
            expiresAt: Date().addingTimeInterval(3600),
            tokenType: "Bearer"
        )
        
        // When
        try await tokenManager.storeTokens(testToken)
        
        // Then
        let storedToken = try await tokenManager.retrieveTokens()
        XCTAssertNotNil(storedToken)
        XCTAssertEqual(storedToken?.accessToken, testToken.accessToken)
        XCTAssertEqual(storedToken?.refreshToken, testToken.refreshToken)
        XCTAssertEqual(storedToken?.tokenType, testToken.tokenType)
        XCTAssertNotNil(tokenManager.lastRefreshTime)
    }
    
    func testStoreTokensWithExpiredDate() async throws {
        // Given
        let expiredToken = TokenRefreshManager.AuthToken(
            accessToken: "expired_token",
            refreshToken: "expired_refresh",
            expiresAt: Date().addingTimeInterval(-3600), // Expired 1 hour ago
            tokenType: "Bearer"
        )
        
        // When
        try await tokenManager.storeTokens(expiredToken)
        
        // Then
        let storedToken = try await tokenManager.retrieveTokens()
        XCTAssertNotNil(storedToken)
        XCTAssertTrue(storedToken!.isExpired)
        XCTAssertFalse(storedToken!.willExpireSoon) // Already expired
    }
    
    func testStoreTokensWithExpiringSoon() async throws {
        // Given
        let expiringToken = TokenRefreshManager.AuthToken(
            accessToken: "expiring_token",
            refreshToken: "expiring_refresh",
            expiresAt: Date().addingTimeInterval(240), // Expires in 4 minutes
            tokenType: "Bearer"
        )
        
        // When
        try await tokenManager.storeTokens(expiringToken)
        
        // Then
        let storedToken = try await tokenManager.retrieveTokens()
        XCTAssertNotNil(storedToken)
        XCTAssertFalse(storedToken!.isExpired)
        XCTAssertTrue(storedToken!.willExpireSoon)
    }
    
    // MARK: - Token Retrieval Tests
    
    func testRetrieveTokensWhenNoneStored() async throws {
        // When
        let tokens = try await tokenManager.retrieveTokens()
        
        // Then
        XCTAssertNil(tokens)
    }
    
    func testRetrieveTokensWithInvalidData() async throws {
        // Given - Simulate corrupted keychain data
        mockKeychain.shouldReturnCorruptedData = true
        
        // When
        let tokens = try await tokenManager.retrieveTokens()
        
        // Then
        XCTAssertNil(tokens)
    }
    
    // MARK: - Token Clear Tests
    
    func testClearTokensSuccessfully() async throws {
        // Given
        let testToken = TokenRefreshManager.AuthToken(
            accessToken: "test_access_token",
            refreshToken: "test_refresh_token",
            expiresAt: Date().addingTimeInterval(3600),
            tokenType: "Bearer"
        )
        try await tokenManager.storeTokens(testToken)
        
        // When
        try await tokenManager.clearTokens()
        
        // Then
        let retrievedTokens = try await tokenManager.retrieveTokens()
        XCTAssertNil(retrievedTokens)
        XCTAssertNil(tokenManager.lastRefreshTime)
    }
    
    // MARK: - Token Validation Tests
    
    func testIsExpiredProperty() {
        // Given
        let expiredToken = TokenRefreshManager.AuthToken(
            accessToken: "token",
            refreshToken: "refresh",
            expiresAt: Date().addingTimeInterval(-1),
            tokenType: "Bearer"
        )
        
        let validToken = TokenRefreshManager.AuthToken(
            accessToken: "token",
            refreshToken: "refresh",
            expiresAt: Date().addingTimeInterval(3600),
            tokenType: "Bearer"
        )
        
        // Then
        XCTAssertTrue(expiredToken.isExpired)
        XCTAssertFalse(validToken.isExpired)
    }
    
    func testWillExpireSoonProperty() {
        // Given
        let expiringSoonToken = TokenRefreshManager.AuthToken(
            accessToken: "token",
            refreshToken: "refresh",
            expiresAt: Date().addingTimeInterval(240), // 4 minutes
            tokenType: "Bearer"
        )
        
        let notExpiringSoonToken = TokenRefreshManager.AuthToken(
            accessToken: "token",
            refreshToken: "refresh",
            expiresAt: Date().addingTimeInterval(600), // 10 minutes
            tokenType: "Bearer"
        )
        
        // Then
        XCTAssertTrue(expiringSoonToken.willExpireSoon)
        XCTAssertFalse(notExpiringSoonToken.willExpireSoon)
    }
    
    // MARK: - Get Valid Access Token Tests
    
    func testGetValidAccessTokenWithValidToken() async throws {
        // Given
        let validToken = TokenRefreshManager.AuthToken(
            accessToken: "valid_token",
            refreshToken: "valid_refresh",
            expiresAt: Date().addingTimeInterval(3600),
            tokenType: "Bearer"
        )
        try await tokenManager.storeTokens(validToken)
        
        // When
        let accessToken = try await tokenManager.getValidAccessToken()
        
        // Then
        XCTAssertEqual(accessToken, validToken.accessToken)
    }
    
    func testGetValidAccessTokenWithExpiredToken() async throws {
        // Given
        let expiredToken = TokenRefreshManager.AuthToken(
            accessToken: "expired_token",
            refreshToken: "expired_refresh",
            expiresAt: Date().addingTimeInterval(-3600),
            tokenType: "Bearer"
        )
        try await tokenManager.storeTokens(expiredToken)
        
        // When & Then
        do {
            _ = try await tokenManager.getValidAccessToken()
            XCTFail("Should throw error for expired token")
        } catch {
            XCTAssertTrue(error is TokenError)
        }
    }
    
    func testGetValidAccessTokenWithNoTokens() async throws {
        // When & Then
        do {
            _ = try await tokenManager.getValidAccessToken()
            XCTFail("Should throw error when no tokens stored")
        } catch {
            XCTAssertTrue(error is TokenError)
        }
    }
    
    // MARK: - Token Refresh Tests
    
    func testRefreshTokensSuccessfully() async throws {
        // Given
        let originalToken = TokenRefreshManager.AuthToken(
            accessToken: "old_token",
            refreshToken: "refresh_token",
            expiresAt: Date().addingTimeInterval(-3600),
            tokenType: "Bearer"
        )
        try await tokenManager.storeTokens(originalToken)
        
        // Mock successful refresh response
        MockNetworkManager.shared.mockRefreshResponse = TokenRefreshResponse(
            accessToken: "new_access_token",
            refreshToken: "new_refresh_token",
            expiresIn: 3600,
            tokenType: "Bearer"
        )
        
        // When
        let newTokens = try await tokenManager.refreshTokens(refreshToken: originalToken.refreshToken)
        
        // Then
        XCTAssertEqual(newTokens.accessToken, "new_access_token")
        XCTAssertEqual(newTokens.refreshToken, "new_refresh_token")
        XCTAssertEqual(newTokens.tokenType, "Bearer")
        XCTAssertFalse(newTokens.isExpired)
    }
    
    func testRefreshTokensWithInvalidRefreshToken() async throws {
        // Given
        let invalidRefreshToken = "invalid_refresh_token"
        
        // Mock failed refresh response
        MockNetworkManager.shared.shouldFailRefresh = true
        
        // When & Then
        do {
            _ = try await tokenManager.refreshTokens(refreshToken: invalidRefreshToken)
            XCTFail("Should throw error for invalid refresh token")
        } catch {
            XCTAssertTrue(error is TokenError)
        }
    }
    
    func testRefreshTokensPreventsMultipleSimultaneousRefreshes() async throws {
        // Given
        let token = TokenRefreshManager.AuthToken(
            accessToken: "token",
            refreshToken: "refresh",
            expiresAt: Date().addingTimeInterval(-3600),
            tokenType: "Bearer"
        )
        try await tokenManager.storeTokens(token)
        
        // Mock slow refresh response
        MockNetworkManager.shared.refreshDelay = 2.0
        
        // When - Start multiple refresh attempts simultaneously
        let refreshTask1 = Task { try await tokenManager.refreshTokens(refreshToken: token.refreshToken) }
        let refreshTask2 = Task { try await tokenManager.refreshTokens(refreshToken: token.refreshToken) }
        
        // Then - Both should complete without throwing errors
        let result1 = try await refreshTask1.value
        let result2 = try await refreshTask2.value
        
        XCTAssertNotNil(result1)
        XCTAssertNotNil(result2)
    }
    
    // MARK: - Force Refresh Tests
    
    func testForceRefreshSuccessfully() async throws {
        // Given
        let token = TokenRefreshManager.AuthToken(
            accessToken: "token",
            refreshToken: "refresh",
            expiresAt: Date().addingTimeInterval(3600),
            tokenType: "Bearer"
        )
        try await tokenManager.storeTokens(token)
        
        MockNetworkManager.shared.mockRefreshResponse = TokenRefreshResponse(
            accessToken: "forced_new_token",
            refreshToken: "forced_new_refresh",
            expiresIn: 3600,
            tokenType: "Bearer"
        )
        
        // When
        let newTokens = try await tokenManager.forceRefresh()
        
        // Then
        XCTAssertEqual(newTokens.accessToken, "forced_new_token")
        XCTAssertEqual(newTokens.refreshToken, "forced_new_refresh")
    }
    
    func testForceRefreshWithNoTokens() async throws {
        // When & Then
        do {
            _ = try await tokenManager.forceRefresh()
            XCTFail("Should throw error when no tokens stored")
        } catch {
            XCTAssertTrue(error is TokenError)
        }
    }
    
    // MARK: - Published Properties Tests
    
    func testIsRefreshingPublishedProperty() async throws {
        // Given
        let expectation = XCTestExpectation(description: "isRefreshing should be true during refresh")
        var refreshStates: [Bool] = []
        
        tokenManager.$isRefreshing
            .sink { isRefreshing in
                refreshStates.append(isRefreshing)
                if refreshStates.count >= 2 {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        let token = TokenRefreshManager.AuthToken(
            accessToken: "token",
            refreshToken: "refresh",
            expiresAt: Date().addingTimeInterval(-3600),
            tokenType: "Bearer"
        )
        try await tokenManager.storeTokens(token)
        
        // Mock slow refresh
        MockNetworkManager.shared.refreshDelay = 1.0
        
        // When
        Task {
            try await tokenManager.refreshTokens(refreshToken: token.refreshToken)
        }
        
        // Then
        await fulfillment(of: [expectation], timeout: 3.0)
        XCTAssertTrue(refreshStates.contains(true))
        XCTAssertTrue(refreshStates.contains(false))
    }
    
    func testLastRefreshTimePublishedProperty() async throws {
        // Given
        let expectation = XCTestExpectation(description: "lastRefreshTime should be updated")
        
        tokenManager.$lastRefreshTime
            .dropFirst() // Skip initial nil value
            .sink { _ in
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        let token = TokenRefreshManager.AuthToken(
            accessToken: "token",
            refreshToken: "refresh",
            expiresAt: Date().addingTimeInterval(3600),
            tokenType: "Bearer"
        )
        
        // When
        try await tokenManager.storeTokens(token)
        
        // Then
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertNotNil(tokenManager.lastRefreshTime)
    }
    
    // MARK: - Error Handling Tests
    
    func testTokenErrorTypes() {
        // Test all TokenError cases
        XCTAssertNotNil(TokenError.noTokensStored)
        XCTAssertNotNil(TokenError.refreshFailed)
        XCTAssertNotNil(TokenError.invalidResponse)
        XCTAssertNotNil(TokenError.networkError)
    }
    
    func testRefreshFailureClearsTokens() async throws {
        // Given
        let token = TokenRefreshManager.AuthToken(
            accessToken: "token",
            refreshToken: "refresh",
            expiresAt: Date().addingTimeInterval(-3600),
            tokenType: "Bearer"
        )
        try await tokenManager.storeTokens(token)
        
        // Mock refresh failure
        MockNetworkManager.shared.shouldFailRefresh = true
        
        // When
        do {
            _ = try await tokenManager.refreshTokens(refreshToken: token.refreshToken)
        } catch {
            // Expected to fail
        }
        
        // Then - Tokens should be cleared after refresh failure
        let retrievedTokens = try await tokenManager.retrieveTokens()
        XCTAssertNil(retrievedTokens)
    }
}

// MARK: - Mock Classes

class MockKeychainManager {
    var shouldReturnCorruptedData = false
    
    func store(key: String, data: Data) async throws {
        // Mock successful storage
    }
    
    func retrieve(key: String) async throws -> Data? {
        if shouldReturnCorruptedData {
            return "corrupted_data".data(using: .utf8)
        }
        
        // Mock successful retrieval for valid keys
        switch key {
        case "access_token":
            return "test_access_token".data(using: .utf8)
        case "refresh_token":
            return "test_refresh_token".data(using: .utf8)
        case "token_expires_at":
            return Date().addingTimeInterval(3600).timeIntervalSince1970.description.data(using: .utf8)
        case "token_type":
            return "Bearer".data(using: .utf8)
        default:
            return nil
        }
    }
    
    func delete(key: String) async throws {
        // Mock successful deletion
    }
}

class MockNetworkManager {
    static let shared = MockNetworkManager()
    
    var mockRefreshResponse: TokenRefreshResponse?
    var shouldFailRefresh = false
    var refreshDelay: TimeInterval = 0
    
    func performRefreshRequest() async throws -> TokenRefreshResponse {
        if shouldFailRefresh {
            throw TokenError.refreshFailed
        }
        
        if refreshDelay > 0 {
            try await Task.sleep(for: .seconds(refreshDelay))
        }
        
        guard let response = mockRefreshResponse else {
            throw TokenError.invalidResponse
        }
        
        return response
    }
}

// MARK: - Supporting Types

struct TokenRefreshResponse: Codable {
    let accessToken: String
    let refreshToken: String?
    let expiresIn: TimeInterval
    let tokenType: String
}

enum TokenError: Error {
    case noTokensStored
    case refreshFailed
    case invalidResponse
    case networkError
}

// Mock network error handler
let networkErrorHandler = NetworkErrorHandler()

class NetworkErrorHandler {
    func exponentialBackoffRetry<T>(_ operation: () async throws -> T) async throws -> T {
        // Mock implementation
        return try await operation()
    }
} 
import XCTest
import SwiftData
@testable import HealthAI2030Core

@available(iOS 18.0, macOS 15.0, *)
final class SessionManagementTests: XCTestCase {
    func testForceLogoutOnCredentialRevocation() async throws {
        // Setup manager with a dummy user
        let manager = AuthenticationManager.shared
        let user = UserProfile(id: UUID(), email: "test@example.com", displayName: "Test User")
        manager.currentUser = user
        manager.isAuthenticated = true

        // Simulate revoked credential by calling signOut directly
        await manager.signOut()

        XCTAssertFalse(manager.isAuthenticated, "User should be logged out on credential revocation")
        XCTAssertNil(manager.currentUser, "currentUser should be nil after logout")
    }
} 
import Foundation
import AuthenticationServices
import SwiftData
import os

/// Manages user authentication for the HealthAI 2030 app
@MainActor
class AuthenticationManager: NSObject, ObservableObject {
    static let shared = AuthenticationManager()
    
    @Published var isAuthenticated = false
    @Published var currentUser: UserProfile?
    @Published var isLoading = false
    
    private let logger = Logger(subsystem: "com.HealthAI2030", category: "Authentication")
    private var modelContext: ModelContext?
    
    private override init() {
        super.init()
        checkAuthenticationState()
        // Monitor credential state on app foreground
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }
    
    @objc private func handleAppForeground() {
        // Check if Apple credential has been revoked
        if let userID = currentUser?.id.uuidString {
            let provider = ASAuthorizationAppleIDProvider()
            provider.getCredentialState(forUserID: userID) { [weak self] state, _ in
                Task { @MainActor in
                    if state == .revoked {
                        await self?.signOut()
                    }
                }
            }
        }
    }
    
    /// Configure the authentication manager with a SwiftData context
    func configure(with modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    /// Check if user is already authenticated
    private func checkAuthenticationState() {
        // Check for existing user in UserDefaults or Keychain
        if let userID = UserDefaults.standard.string(forKey: "currentUserID") {
            // User was previously authenticated, try to restore session
            Task {
                await restoreSession(userID: userID)
            }
        }
    }
    
    /// Restore user session from stored credentials
    private func restoreSession(userID: String) async {
        guard let modelContext = modelContext else {
            logger.error("ModelContext not configured")
            return
        }
        
        do {
            let request = FetchDescriptor<UserProfile>(
                predicate: #Predicate<UserProfile> { $0.id.uuidString == userID }
            )
            let users = try modelContext.fetch(request)
            
            if let user = users.first {
                await MainActor.run {
                    self.currentUser = user
                    self.isAuthenticated = true
                }
                logger.info("Session restored for user: \(user.email)")
            } else {
                // User not found, clear stored credentials
                UserDefaults.standard.removeObject(forKey: "currentUserID")
                logger.warning("Stored user not found, clearing credentials")
            }
        } catch {
            logger.error("Failed to restore session: \(error.localizedDescription)")
            UserDefaults.standard.removeObject(forKey: "currentUserID")
        }
    }
    
    /// Sign in with Apple
    func signInWithApple() async throws {
        guard let modelContext = modelContext else {
            throw AuthError.modelContextNotConfigured
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let request = ASAuthorizationAppleIDProvider().createRequest()
            request.requestedScopes = [.fullName, .email]
            
            let result = try await withCheckedThrowingContinuation { continuation in
                let controller = ASAuthorizationController(authorizationRequests: [request])
                let delegate = AppleSignInDelegate { result in
                    continuation.resume(with: result)
                }
                controller.delegate = delegate
                controller.presentationContextProvider = delegate
                controller.performRequests()
                
                // Store delegate to prevent deallocation
                objc_setAssociatedObject(controller, "delegate", delegate, .OBJC_ASSOCIATION_RETAIN)
            }
            
            // Process the sign-in result
            try await processSignInResult(result)
            
        } catch {
            logger.error("Sign in with Apple failed: \(error.localizedDescription)")
            throw AuthError.signInFailed(error)
        }
    }
    
    /// Process the Apple Sign In result
    private func processSignInResult(_ result: ASAuthorizationAppleIDCredential) async throws {
        guard let modelContext = modelContext else {
            throw AuthError.modelContextNotConfigured
        }
        
        let userID = result.user
        let email = result.email ?? ""
        let fullName = result.fullName
        
        // Check if user already exists
        let request = FetchDescriptor<UserProfile>(
            predicate: #Predicate<UserProfile> { $0.id.uuidString == userID }
        )
        let existingUsers = try modelContext.fetch(request)
        
        let user: UserProfile
        
        if let existingUser = existingUsers.first {
            // Update existing user
            user = existingUser
            if let fullName = fullName {
                user.displayName = "\(fullName.givenName ?? "") \(fullName.familyName ?? "")"
            }
            user.lastUpdated = Date()
        } else {
            // Create new user
            let displayName = fullName.map { "\($0.givenName ?? "") \($0.familyName ?? "")" } ?? "User"
            user = UserProfile(
                id: UUID(uuidString: userID) ?? UUID(),
                email: email,
                displayName: displayName
            )
            modelContext.insert(user)
        }
        
        // Save to persistent storage
        try modelContext.save()
        
        // Store user ID for session restoration
        UserDefaults.standard.set(userID, forKey: "currentUserID")
        
        // Update authentication state
        currentUser = user
        isAuthenticated = true
        // Start credential state monitoring after login
        handleAppForeground()
        
        logger.info("User authenticated successfully: \(user.email)")
    }
    
    /// Sign out the current user
    func signOut() async {
        guard let modelContext = modelContext else { return }
        
        do {
            // Clear stored credentials
            UserDefaults.standard.removeObject(forKey: "currentUserID")
            
            // Update authentication state
            currentUser = nil
            isAuthenticated = false
            
            logger.info("User signed out successfully")
        } catch {
            logger.error("Failed to sign out: \(error.localizedDescription)")
        }
    }
    
    /// Delete user account
    func deleteAccount() async throws {
        guard let modelContext = modelContext,
              let user = currentUser else {
            throw AuthError.noUserSignedIn
        }
        
        do {
            // Delete user and all associated data
            modelContext.delete(user)
            try modelContext.save()
            
            // Clear stored credentials
            UserDefaults.standard.removeObject(forKey: "currentUserID")
            
            // Update authentication state
            currentUser = nil
            isAuthenticated = false
            
            logger.info("User account deleted successfully")
        } catch {
            logger.error("Failed to delete account: \(error.localizedDescription)")
            throw AuthError.deleteAccountFailed(error)
        }
    }
}

// MARK: - Apple Sign In Delegate
private class AppleSignInDelegate: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    private let completion: (Result<ASAuthorizationAppleIDCredential, Error>) -> Void
    
    init(completion: @escaping (Result<ASAuthorizationAppleIDCredential, Error>) -> Void) {
        self.completion = completion
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let credential = authorization.credential as? ASAuthorizationAppleIDCredential {
            completion(.success(credential))
        } else {
            completion(.failure(AuthError.invalidCredential))
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        completion(.failure(error))
    }
    
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            fatalError("No window available for Apple Sign In")
        }
        return window
    }
}

// MARK: - Authentication Errors
enum AuthError: LocalizedError {
    case modelContextNotConfigured
    case signInFailed(Error)
    case invalidCredential
    case noUserSignedIn
    case deleteAccountFailed(Error)
    
    var errorDescription: String? {
        switch self {
        case .modelContextNotConfigured:
            return "Authentication system not properly configured"
        case .signInFailed(let error):
            return "Sign in failed: \(error.localizedDescription)"
        case .invalidCredential:
            return "Invalid authentication credential"
        case .noUserSignedIn:
            return "No user is currently signed in"
        case .deleteAccountFailed(let error):
            return "Failed to delete account: \(error.localizedDescription)"
        }
    }
} 
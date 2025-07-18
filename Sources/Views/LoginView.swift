import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @StateObject private var authManager = AuthenticationManager.shared
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 40) {
                Spacer()
                
                // App Logo and Title
                VStack(spacing: 20) {
                    Image(systemName: "heart.text.square.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.blue)
                        .accessibilityHidden(true)
                    
                    Text("HealthAI 2030")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .dynamicTypeSize(.xSmall ... .accessibility5)
                        .accessibilityAddTraits(.isHeader)
                    
                    Text("Your AI-powered health companion")
                        .font(.title3)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                Spacer()
                
                // Sign In Button
                VStack(spacing: 20) {
                    if authManager.isLoading {
                        ProgressView("Signing in...")
                            .progressViewStyle(CircularProgressViewStyle())
                    } else {
                        SignInWithAppleButton(
                            onRequest: { request in
                                request.requestedScopes = [.fullName, .email]
                            },
                            onCompletion: { result in
                                Task {
                                    await handleSignInResult(result)
                                }
                            }
                        )
                        .signInWithAppleButtonStyle(.black)
                        .frame(height: 50)
                        .cornerRadius(8)
                        .accessibilityLabel("Sign in with Apple")
                        .accessibilityHint("Use your Apple ID to sign in to HealthAI 2030")
                    }
                    
                    Text("By signing in, you agree to our Terms of Service and Privacy Policy")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                Spacer()
            }
            .padding()
            .navigationBarHidden(true)
        }
        .alert("Sign In Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
        .accessibilityElement(children: .contain)
    }
    
    private func handleSignInResult(_ result: Result<ASAuthorization, Error>) async {
        switch result {
        case .success(let authorization):
            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                do {
                    try await authManager.signInWithApple()
                } catch {
                    await MainActor.run {
                        errorMessage = error.localizedDescription
                        showingError = true
                    }
                }
            }
        case .failure(let error):
            await MainActor.run {
                errorMessage = error.localizedDescription
                showingError = true
            }
        }
    }
}

#Preview {
    LoginView()
} 
import SwiftUI

public struct AccountSettingsView: View {
    @StateObject private var authManager = AuthenticationManager.shared
    @State private var showingDeleteConfirmation = false
    @State private var showingSignOutConfirmation = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            List {
                Section("Account Information") {
                    if let user = authManager.currentUser {
                        HStack {
                            Text("Name")
                            Spacer()
                            Text(user.displayName)
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text("Email")
                            Spacer()
                            Text(user.email)
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text("Member Since")
                            Spacer()
                            Text(user.createdAt, style: .date)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Section("Account Actions") {
                    Button("Sign Out") {
                        showingSignOutConfirmation = true
                    }
                    .foregroundColor(.orange)
                    .accessibilityLabel("Sign out of your account")
                    .accessibilityHint("This will sign you out but keep your data")
                    
                    Button("Delete Account") {
                        showingDeleteConfirmation = true
                    }
                    .foregroundColor(.red)
                    .accessibilityLabel("Delete your account")
                    .accessibilityHint("This will permanently delete your account and all data")
                }
            }
            .navigationTitle("Account Settings")
            .alert("Sign Out", isPresented: $showingSignOutConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Sign Out", role: .destructive) {
                    Task {
                        await signOut()
                    }
                }
            } message: {
                Text("Are you sure you want to sign out? You can sign back in anytime.")
            }
            .alert("Delete Account", isPresented: $showingDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    Task {
                        await deleteAccount()
                    }
                }
            } message: {
                Text("This action cannot be undone. All your health data and settings will be permanently deleted.")
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
        .accessibilityElement(children: .contain)
    }
    
    private func signOut() async {
        do {
            await authManager.signOut()
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                showingError = true
            }
        }
    }
    
    private func deleteAccount() async {
        do {
            try await authManager.deleteAccount()
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                showingError = true
            }
        }
    }
}

#Preview {
    AccountSettingsView()
} 
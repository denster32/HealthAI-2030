import SwiftUI

struct EncryptionDetailsView: View {
    @ObservedObject var securityManager: AdvancedSecurityPrivacyManager
    @Environment(\.presentationMode) var presentationMode
    
    @State private var showingKeyRotationAlert = false
    @State private var isRotatingKeys = false
    @State private var keyRotationResult: String?
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 20) {
                    // Encryption Status
                    encryptionStatusSection
                    
                    // Key Management
                    keyManagementSection
                    
                    // Encryption Details
                    encryptionDetailsSection
                    
                    // Security Metrics
                    securityMetricsSection
                    
                    // Encryption History
                    encryptionHistorySection
                }
                .padding()
            }
            .navigationTitle(NSLocalizedString("Encryption Details", comment: "Encryption details navigation title"))
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button(NSLocalizedString("Done", comment: "Done button")) {
                presentationMode.wrappedValue.dismiss()
            })
            .alert("Rotate Encryption Keys", isPresented: $showingKeyRotationAlert) {
                Button("Rotate Keys") {
                    rotateEncryptionKeys()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This will generate new encryption keys and re-encrypt all data. This process may take several minutes.")
            }
        }
    }
    
    // MARK: - Encryption Status Section
    private var encryptionStatusSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(NSLocalizedString("Encryption Status", comment: "Encryption status section title"))
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(securityManager.encryptionStatus.description)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(statusColor)
                    Text(NSLocalizedString("Current Status", comment: "Current status label"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Image(systemName: statusIcon)
                    .font(.title)
                    .foregroundColor(statusColor)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
    
    // MARK: - Key Management Section
    private var keyManagementSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(NSLocalizedString("Key Management", comment: "Key management section title"))
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                KeyInfoRow(
                    title: NSLocalizedString("Key Type", comment: "Key type label"),
                    value: "AES-256-GCM",
                    icon: "key.fill"
                )
                
                KeyInfoRow(
                    title: NSLocalizedString("Key Size", comment: "Key size label"),
                    value: "256 bits",
                    icon: "number.circle.fill"
                )
                
                KeyInfoRow(
                    title: NSLocalizedString("Key Storage", comment: "Key storage label"),
                    value: "Secure Keychain",
                    icon: "lock.shield.fill"
                )
                
                KeyInfoRow(
                    title: NSLocalizedString("Last Rotation", comment: "Last rotation label"),
                    value: "2 days ago",
                    icon: "clock.fill"
                )
                
                if isRotatingKeys {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text(NSLocalizedString("Rotating keys...", comment: "Rotating keys message"))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }
                
                if let result = keyRotationResult {
                    Text(result)
                        .font(.subheadline)
                        .foregroundColor(result.contains("successful") ? .green : .red)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }
                
                Button(NSLocalizedString("Rotate Encryption Keys", comment: "Rotate keys button")) {
                    showingKeyRotationAlert = true
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .disabled(isRotatingKeys)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        }
    }
    
    // MARK: - Encryption Details Section
    private var encryptionDetailsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(NSLocalizedString("Encryption Details", comment: "Encryption details section title"))
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                EncryptionDetailRow(
                    title: NSLocalizedString("Algorithm", comment: "Algorithm label"),
                    value: "AES (Advanced Encryption Standard)",
                    description: NSLocalizedString("Industry-standard symmetric encryption", comment: "AES description")
                )
                
                EncryptionDetailRow(
                    title: NSLocalizedString("Mode", comment: "Mode label"),
                    value: "GCM (Galois/Counter Mode)",
                    description: NSLocalizedString("Provides both confidentiality and authenticity", comment: "GCM description")
                )
                
                EncryptionDetailRow(
                    title: NSLocalizedString("Key Derivation", comment: "Key derivation label"),
                    value: "PBKDF2",
                    description: NSLocalizedString("Password-based key derivation function", comment: "PBKDF2 description")
                )
                
                EncryptionDetailRow(
                    title: NSLocalizedString("Random Number Generator", comment: "RNG label"),
                    value: "Cryptographically Secure RNG",
                    description: NSLocalizedString("Hardware-based random number generation", comment: "RNG description")
                )
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        }
    }
    
    // MARK: - Security Metrics Section
    private var securityMetricsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(NSLocalizedString("Security Metrics", comment: "Security metrics section title"))
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                SecurityMetricCard(
                    title: NSLocalizedString("Encryption Strength", comment: "Encryption strength metric"),
                    value: "256-bit",
                    icon: "shield.fill",
                    color: .green
                )
                
                SecurityMetricCard(
                    title: NSLocalizedString("Key Entropy", comment: "Key entropy metric"),
                    value: "256 bits",
                    icon: "random",
                    color: .blue
                )
                
                SecurityMetricCard(
                    title: NSLocalizedString("Attack Resistance", comment: "Attack resistance metric"),
                    value: "High",
                    icon: "lock.shield.fill",
                    color: .orange
                )
                
                SecurityMetricCard(
                    title: NSLocalizedString("Compliance", comment: "Compliance metric"),
                    value: "HIPAA",
                    icon: "checkmark.shield.fill",
                    color: .purple
                )
            }
        }
    }
    
    // MARK: - Encryption History Section
    private var encryptionHistorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(NSLocalizedString("Encryption History", comment: "Encryption history section title"))
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 8) {
                EncryptionHistoryRow(
                    date: "2024-01-15",
                    event: "Key rotation completed",
                    status: "Success"
                )
                
                EncryptionHistoryRow(
                    date: "2024-01-01",
                    event: "Encryption system initialized",
                    status: "Success"
                )
                
                EncryptionHistoryRow(
                    date: "2023-12-15",
                    event: "Previous key rotation",
                    status: "Success"
                )
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        }
    }
    
    // MARK: - Computed Properties
    private var statusColor: Color {
        switch securityManager.encryptionStatus {
        case .active: return .green
        case .initializing: return .orange
        case .error: return .red
        case .notInitialized: return .gray
        }
    }
    
    private var statusIcon: String {
        switch securityManager.encryptionStatus {
        case .active: return "checkmark.shield.fill"
        case .initializing: return "clock.fill"
        case .error: return "exclamationmark.shield.fill"
        case .notInitialized: return "shield.slash.fill"
        }
    }
    
    // MARK: - Actions
    private func rotateEncryptionKeys() {
        isRotatingKeys = true
        keyRotationResult = nil
        
        Task {
            do {
                try await securityManager.rotateEncryptionKeys()
                await MainActor.run {
                    isRotatingKeys = false
                    keyRotationResult = "Key rotation completed successfully"
                }
            } catch {
                await MainActor.run {
                    isRotatingKeys = false
                    keyRotationResult = "Key rotation failed: \(error.localizedDescription)"
                }
            }
        }
    }
}

// MARK: - Supporting Views
struct KeyInfoRow: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 20)
            
            Text(title)
                .font(.subheadline)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
        .padding(.vertical, 4)
    }
}

struct EncryptionDetailRow: View {
    let title: String
    let value: String
    let description: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)
            }
            
            Text(description)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct SecurityMetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

struct EncryptionHistoryRow: View {
    let date: String
    let event: String
    let status: String
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(event)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(status)
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(statusColor.opacity(0.1))
                .foregroundColor(statusColor)
                .cornerRadius(8)
        }
        .padding(.vertical, 4)
    }
    
    private var statusColor: Color {
        status == "Success" ? .green : .red
    }
}

#Preview {
    EncryptionDetailsView(securityManager: AdvancedSecurityPrivacyManager())
} 
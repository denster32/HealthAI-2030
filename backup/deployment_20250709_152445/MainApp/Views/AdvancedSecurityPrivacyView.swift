import SwiftUI

struct AdvancedSecurityPrivacyView: View {
    @StateObject private var securityManager = AdvancedSecurityPrivacyManager()
    @State private var showingBiometricAuth = false
    @State private var showingPrivacySettings = false
    @State private var showingSecurityAudit = false
    @State private var showingEncryptionDetails = false
    @State private var biometricAuthResult: String?
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 20) {
                    // Security Status Overview
                    securityStatusSection
                    
                    // Encryption Status
                    encryptionStatusSection
                    
                    // Privacy Controls
                    privacyControlsSection
                    
                    // Biometric Authentication
                    biometricAuthSection
                    
                    // Security Score
                    securityScoreSection
                    
                    // Security Recommendations
                    securityRecommendationsSection
                    
                    // Recent Security Events
                    recentSecurityEventsSection
                }
                .padding()
            }
            .navigationTitle(NSLocalizedString("Security & Privacy", comment: "Security and privacy navigation title"))
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(NSLocalizedString("Settings", comment: "Settings button")) {
                        showingPrivacySettings = true
                    }
                }
            }
            .sheet(isPresented: $showingPrivacySettings) {
                PrivacySettingsView(securityManager: securityManager)
            }
            .sheet(isPresented: $showingSecurityAudit) {
                SecurityAuditView(securityManager: securityManager)
            }
            .sheet(isPresented: $showingEncryptionDetails) {
                EncryptionDetailsView(securityManager: securityManager)
            }
            .alert("Biometric Authentication", isPresented: $showingBiometricAuth) {
                Button("Authenticate") {
                    authenticateWithBiometrics()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Please authenticate using biometrics to access security features")
            }
        }
    }
    
    // MARK: - Security Status Section
    private var securityStatusSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(NSLocalizedString("Security Status", comment: "Security status section title"))
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(securityManager.encryptionStatus.description)
                        .font(.subheadline)
                        .foregroundColor(statusColor)
                    Text(NSLocalizedString("Encryption", comment: "Encryption status label"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Image(systemName: statusIcon)
                    .font(.title2)
                    .foregroundColor(statusColor)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
    
    // MARK: - Encryption Status Section
    private var encryptionStatusSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(NSLocalizedString("Encryption", comment: "Encryption section title"))
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                Button(NSLocalizedString("Details", comment: "Details button")) {
                    showingEncryptionDetails = true
                }
                .font(.caption)
            }
            
            VStack(spacing: 12) {
                SecurityToggleRow(
                    title: NSLocalizedString("Data Encryption", comment: "Data encryption toggle"),
                    subtitle: NSLocalizedString("Encrypt all sensitive data", comment: "Data encryption description"),
                    isOn: $securityManager.isEncryptionEnabled
                )
                
                if securityManager.isEncryptionEnabled {
                    HStack {
                        Text(NSLocalizedString("Encryption Level", comment: "Encryption level label"))
                            .font(.subheadline)
                        Spacer()
                        Text("\(securityManager.privacyLevel.encryptionLevel)-bit AES")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                    }
                    .padding(.horizontal)
                }
                
                Button(NSLocalizedString("Rotate Encryption Keys", comment: "Rotate keys button")) {
                    rotateEncryptionKeys()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .disabled(!securityManager.isEncryptionEnabled)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        }
    }
    
    // MARK: - Privacy Controls Section
    private var privacyControlsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(NSLocalizedString("Privacy Controls", comment: "Privacy controls section title"))
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                SecurityToggleRow(
                    title: NSLocalizedString("Data Anonymization", comment: "Data anonymization toggle"),
                    subtitle: NSLocalizedString("Remove personally identifiable information", comment: "Data anonymization description"),
                    isOn: $securityManager.isDataAnonymizationEnabled
                )
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(NSLocalizedString("Privacy Level", comment: "Privacy level label"))
                        .font(.subheadline)
                    
                    Picker(NSLocalizedString("Privacy Level", comment: "Privacy level picker"), selection: $securityManager.privacyLevel) {
                        ForEach(AdvancedSecurityPrivacyManager.PrivacyLevel.allCases, id: \.self) { level in
                            Text(level.description).tag(level)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        }
    }
    
    // MARK: - Biometric Authentication Section
    private var biometricAuthSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(NSLocalizedString("Biometric Authentication", comment: "Biometric authentication section title"))
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                SecurityToggleRow(
                    title: NSLocalizedString("Biometric Auth", comment: "Biometric auth toggle"),
                    subtitle: NSLocalizedString("Use Face ID or Touch ID for authentication", comment: "Biometric auth description"),
                    isOn: $securityManager.isBiometricAuthEnabled
                )
                
                if securityManager.isBiometricAuthEnabled {
                    Button(NSLocalizedString("Test Biometric Auth", comment: "Test biometric auth button")) {
                        showingBiometricAuth = true
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    
                    if let result = biometricAuthResult {
                        Text(result)
                            .font(.caption)
                            .foregroundColor(result.contains("successful") ? .green : .red)
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        }
    }
    
    // MARK: - Security Score Section
    private var securityScoreSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(NSLocalizedString("Security Score", comment: "Security score section title"))
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(securityManager.getSecurityScore())/100")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(scoreColor)
                    Text(NSLocalizedString("Overall Security", comment: "Overall security label"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                CircularProgressView(progress: Double(securityManager.getSecurityScore()) / 100.0)
                    .frame(width: 60, height: 60)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        }
    }
    
    // MARK: - Security Recommendations Section
    private var securityRecommendationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(NSLocalizedString("Security Recommendations", comment: "Security recommendations section title"))
                .font(.headline)
                .fontWeight(.semibold)
            
            let recommendations = securityManager.getSecurityRecommendations()
            
            if recommendations.isEmpty {
                Text(NSLocalizedString("No recommendations at this time", comment: "No recommendations message"))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(recommendations, id: \.self) { recommendation in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                                .font(.caption)
                            Text(recommendation)
                                .font(.subheadline)
                            Spacer()
                        }
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
            }
        }
    }
    
    // MARK: - Recent Security Events Section
    private var recentSecurityEventsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(NSLocalizedString("Recent Security Events", comment: "Recent security events section title"))
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                Button(NSLocalizedString("View All", comment: "View all button")) {
                    showingSecurityAudit = true
                }
                .font(.caption)
            }
            
            let recentEvents = Array(securityManager.securityAuditLog.prefix(5))
            
            if recentEvents.isEmpty {
                Text(NSLocalizedString("No recent security events", comment: "No recent events message"))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
            } else {
                VStack(spacing: 8) {
                    ForEach(recentEvents) { event in
                        SecurityEventRow(event: event)
                    }
                }
            }
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
    
    private var scoreColor: Color {
        let score = securityManager.getSecurityScore()
        if score >= 80 { return .green }
        else if score >= 60 { return .orange }
        else { return .red }
    }
    
    // MARK: - Actions
    private func authenticateWithBiometrics() {
        Task {
            do {
                let success = try await securityManager.authenticateWithBiometrics()
                await MainActor.run {
                    biometricAuthResult = success ? "Authentication successful" : "Authentication failed"
                }
            } catch {
                await MainActor.run {
                    biometricAuthResult = "Authentication failed: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func rotateEncryptionKeys() {
        Task {
            do {
                try await securityManager.rotateEncryptionKeys()
            } catch {
                print("Failed to rotate encryption keys: \(error)")
            }
        }
    }
}

// MARK: - Supporting Views
struct SecurityToggleRow: View {
    let title: String
    let subtitle: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Toggle("", isOn: $isOn)
                .labelsHidden()
        }
    }
}

struct SecurityEventRow: View {
    let event: AdvancedSecurityPrivacyManager.SecurityAuditEntry
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(event.description)
                    .font(.subheadline)
                    .lineLimit(2)
                Text(event.timestamp, style: .relative)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Text(event.eventType.rawValue)
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(severityColor.opacity(0.1))
                .foregroundColor(severityColor)
                .cornerRadius(8)
        }
        .padding(.vertical, 4)
    }
    
    private var severityColor: Color {
        switch event.severity {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        case .critical: return .purple
        }
    }
}

struct CircularProgressView: View {
    let progress: Double
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.3), lineWidth: 4)
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(progressColor, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.5), value: progress)
        }
    }
    
    private var progressColor: Color {
        if progress >= 0.8 { return .green }
        else if progress >= 0.6 { return .orange }
        else { return .red }
    }
}

#Preview {
    AdvancedSecurityPrivacyView()
} 
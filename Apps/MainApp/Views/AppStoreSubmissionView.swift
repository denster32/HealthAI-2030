import SwiftUI

/// Comprehensive App Store submission view for HealthAI 2030
/// Provides complete interface for managing submission process, compliance checks, and metadata
struct AppStoreSubmissionView: View {
    @StateObject private var submissionManager = AppStoreSubmissionManager.shared
    @State private var selectedTab = 0
    @State private var showingChecklist = false
    @State private var showingMetadataEditor = false
    @State private var showingScreenshotManager = false
    @State private var showingExportSheet = false
    @State private var exportData: Data?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header with submission status
                submissionHeader
                
                // Tab selection
                Picker("Submission", selection: $selectedTab) {
                    Text("Overview").tag(0)
                    Text("Compliance").tag(1)
                    Text("Metadata").tag(2)
                    Text("Screenshots").tag(3)
                    Text("Build").tag(4)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                // Content based on selected tab
                TabView(selection: $selectedTab) {
                    overviewTab
                        .tag(0)
                    
                    complianceTab
                        .tag(1)
                    
                    metadataTab
                        .tag(2)
                    
                    screenshotsTab
                        .tag(3)
                    
                    buildTab
                        .tag(4)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .navigationTitle("App Store Submission")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("View Checklist") {
                            showingChecklist = true
                        }
                        Button("Export Data") {
                            exportSubmissionData()
                        }
                        Button("Start Submission") {
                            startSubmission()
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $showingChecklist) {
                SubmissionChecklistView(checklist: submissionManager.generateSubmissionChecklist())
            }
            .sheet(isPresented: $showingMetadataEditor) {
                MetadataEditorView()
            }
            .sheet(isPresented: $showingScreenshotManager) {
                ScreenshotManagerView()
            }
            .sheet(isPresented: $showingExportSheet) {
                if let data = exportData {
                    ShareSheet(items: [data])
                }
            }
            .onAppear {
                Task {
                    await submissionManager.initialize()
                }
            }
        }
    }
    
    // MARK: - Header
    
    private var submissionHeader: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("App Store Submission")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("HealthAI 2030 v\(submissionManager.getCurrentMetadata().version)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Submission status badge
                HStack {
                    Circle()
                        .fill(Color(submissionManager.submissionStatus.color))
                        .frame(width: 12, height: 12)
                    
                    Text(submissionManager.submissionStatus.rawValue)
                        .font(.caption)
                        .fontWeight(.semibold)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color(.systemGray6))
                .cornerRadius(16)
            }
            
            // Quick stats
            HStack(spacing: 20) {
                StatusCard(
                    title: "Compliance",
                    status: submissionManager.complianceChecks.filter { $0.status == .passed }.count,
                    total: submissionManager.complianceChecks.count,
                    color: .green
                )
                
                StatusCard(
                    title: "Metadata",
                    status: submissionManager.metadataStatus == .complete ? 1 : 0,
                    total: 1,
                    color: .blue
                )
                
                StatusCard(
                    title: "Screenshots",
                    status: submissionManager.screenshotStatus == .complete ? 1 : 0,
                    total: 1,
                    color: .orange
                )
                
                StatusCard(
                    title: "Build",
                    status: submissionManager.buildStatus == .ready ? 1 : 0,
                    total: 1,
                    color: .purple
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
    }
    
    // MARK: - Overview Tab
    
    private var overviewTab: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Ready for submission card
                ReadyForSubmissionCard()
                
                // Progress overview
                ProgressOverviewCard()
                
                // Recent activity
                RecentActivityCard()
                
                // Quick actions
                QuickActionsCard()
            }
            .padding()
        }
    }
    
    // MARK: - Compliance Tab
    
    private var complianceTab: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                if submissionManager.complianceChecks.isEmpty {
                    emptyStateView(
                        icon: "checkmark.circle.fill",
                        title: "No Compliance Checks",
                        message: "Run compliance checks to see results."
                    )
                } else {
                    ForEach(AppStoreSubmissionManager.ComplianceCategory.allCases, id: \.self) { category in
                        let checks = submissionManager.complianceChecks.filter { $0.category == category }
                        if !checks.isEmpty {
                            ComplianceCategorySection(category: category, checks: checks)
                        }
                    }
                }
            }
            .padding()
        }
    }
    
    // MARK: - Metadata Tab
    
    private var metadataTab: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Metadata status card
                MetadataStatusCard()
                
                // Metadata preview
                MetadataPreviewCard()
                
                // Edit metadata button
                Button("Edit Metadata") {
                    showingMetadataEditor = true
                }
                .buttonStyle(.borderedProminent)
                .padding()
            }
            .padding()
        }
    }
    
    // MARK: - Screenshots Tab
    
    private var screenshotsTab: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Screenshot status card
                ScreenshotStatusCard()
                
                // Screenshot requirements
                ScreenshotRequirementsCard()
                
                // Manage screenshots button
                Button("Manage Screenshots") {
                    showingScreenshotManager = true
                }
                .buttonStyle(.borderedProminent)
                .padding()
            }
            .padding()
        }
    }
    
    // MARK: - Build Tab
    
    private var buildTab: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Build status card
                BuildStatusCard()
                
                // Build information
                BuildInfoCard()
                
                // Build actions
                BuildActionsCard()
            }
            .padding()
        }
    }
    
    // MARK: - Helper Views
    
    private func emptyStateView(icon: String, title: String, message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundColor(.green)
            
            VStack(spacing: 8) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text(message)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(40)
    }
    
    private func exportSubmissionData() {
        exportData = submissionManager.exportSubmissionData()
        showingExportSheet = true
    }
    
    private func startSubmission() {
        // Implementation for starting submission process
        submissionManager.submissionStatus = .readyForReview
    }
}

// MARK: - Supporting Views

struct StatusCard: View {
    let title: String
    let status: Int
    let total: Int
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(status)/\(total)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
}

struct ReadyForSubmissionCard: View {
    @StateObject private var submissionManager = AppStoreSubmissionManager.shared
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: submissionManager.isReadyForSubmission ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.title)
                    .foregroundColor(submissionManager.isReadyForSubmission ? .green : .red)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Ready for Submission")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text(submissionManager.isReadyForSubmission ? "All requirements met" : "Some requirements need attention")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            if !submissionManager.isReadyForSubmission {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Missing Requirements:")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    let failedChecks = submissionManager.complianceChecks.filter { $0.isRequired && $0.status == .failed }
                    ForEach(failedChecks.prefix(3), id: \.id) { check in
                        HStack {
                            Image(systemName: "circle.fill")
                                .font(.caption2)
                                .foregroundColor(.red)
                            Text(check.requirement)
                                .font(.caption)
                        }
                    }
                    
                    if failedChecks.count > 3 {
                        Text("... and \(failedChecks.count - 3) more")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

struct ProgressOverviewCard: View {
    @StateObject private var submissionManager = AppStoreSubmissionManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Progress Overview")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                ProgressRow(
                    title: "Compliance Checks",
                    status: submissionManager.complianceChecks.filter { $0.status == .passed }.count,
                    total: submissionManager.complianceChecks.count,
                    color: .green
                )
                
                ProgressRow(
                    title: "Metadata",
                    status: submissionManager.metadataStatus == .complete ? 1 : 0,
                    total: 1,
                    color: .blue
                )
                
                ProgressRow(
                    title: "Screenshots",
                    status: submissionManager.screenshotStatus == .complete ? 1 : 0,
                    total: 1,
                    color: .orange
                )
                
                ProgressRow(
                    title: "Build",
                    status: submissionManager.buildStatus == .ready ? 1 : 0,
                    total: 1,
                    color: .purple
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

struct ProgressRow: View {
    let title: String
    let status: Int
    let total: Int
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            HStack {
                Text(title)
                    .font(.subheadline)
                
                Spacer()
                
                Text("\(status)/\(total)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(color)
            }
            
            ProgressView(value: Double(status), total: Double(total))
                .progressViewStyle(LinearProgressViewStyle(tint: color))
        }
    }
}

struct RecentActivityCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Activity")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                ActivityRow(
                    icon: "checkmark.circle.fill",
                    title: "Compliance checks completed",
                    time: "2 minutes ago",
                    color: .green
                )
                
                ActivityRow(
                    icon: "doc.text.fill",
                    title: "Metadata validated",
                    time: "5 minutes ago",
                    color: .blue
                )
                
                ActivityRow(
                    icon: "photo.fill",
                    title: "Screenshots uploaded",
                    time: "10 minutes ago",
                    color: .orange
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

struct ActivityRow: View {
    let icon: String
    let title: String
    let time: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                
                Text(time)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

struct QuickActionsCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Actions")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                QuickActionButton(
                    icon: "checklist",
                    title: "View Checklist",
                    color: .blue
                )
                
                QuickActionButton(
                    icon: "doc.text",
                    title: "Edit Metadata",
                    color: .green
                )
                
                QuickActionButton(
                    icon: "photo",
                    title: "Manage Screenshots",
                    color: .orange
                )
                
                QuickActionButton(
                    icon: "arrow.up.circle",
                    title: "Submit for Review",
                    color: .purple
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

struct QuickActionButton: View {
    let icon: String
    let title: String
    let color: Color
    
    var body: some View {
        Button(action: {
            // Action implementation
        }) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color(.systemGray6))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ComplianceCategorySection: View {
    let category: AppStoreSubmissionManager.ComplianceCategory
    let checks: [AppStoreSubmissionManager.ComplianceCheck]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(category.rawValue)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                let passedCount = checks.filter { $0.status == .passed }.count
                Text("\(passedCount)/\(checks.count)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(passedCount == checks.count ? .green : .orange)
            }
            
            ForEach(checks, id: \.id) { check in
                ComplianceCheckRow(check: check)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

struct ComplianceCheckRow: View {
    let check: AppStoreSubmissionManager.ComplianceCheck
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: statusIcon)
                .foregroundColor(statusColor)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(check.requirement)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(check.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if let recommendation = check.recommendation {
                    Text("Recommendation: \(recommendation)")
                        .font(.caption2)
                        .foregroundColor(.blue)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
    
    private var statusIcon: String {
        switch check.status {
        case .passed: return "checkmark.circle.fill"
        case .failed: return "xmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .pending: return "clock.fill"
        case .notApplicable: return "minus.circle.fill"
        }
    }
    
    private var statusColor: Color {
        switch check.status {
        case .passed: return .green
        case .failed: return .red
        case .warning: return .orange
        case .pending: return .gray
        case .notApplicable: return .blue
        }
    }
}

// MARK: - Placeholder Views (to be implemented)

struct MetadataStatusCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Metadata Status")
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Text("Metadata is complete and validated")
                    .font(.subheadline)
                Spacer()
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

struct MetadataPreviewCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Metadata Preview")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("HealthAI 2030")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("AI-Powered Health Companion")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text("Health & Fitness • 4+")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

struct ScreenshotStatusCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Screenshot Status")
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Text("All required screenshots uploaded")
                    .font(.subheadline)
                Spacer()
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

struct ScreenshotRequirementsCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Screenshot Requirements")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 8) {
                RequirementRow(device: "iPhone 6.5\"", count: "3/3", status: .complete)
                RequirementRow(device: "iPhone 5.8\"", count: "3/3", status: .complete)
                RequirementRow(device: "iPad Pro 12.9\"", count: "6/6", status: .complete)
                RequirementRow(device: "Apple Watch", count: "2/2", status: .complete)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

struct RequirementRow: View {
    let device: String
    let count: String
    let status: AppStoreSubmissionManager.ScreenshotStatus
    
    var body: some View {
        HStack {
            Text(device)
                .font(.subheadline)
            
            Spacer()
            
            Text(count)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(status == .complete ? .green : .orange)
        }
    }
}

struct BuildStatusCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Build Status")
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Text("Build is ready for submission")
                    .font(.subheadline)
                Spacer()
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

struct BuildInfoCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Build Information")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 8) {
                InfoRow(label: "Version", value: "1.0.0")
                InfoRow(label: "Build", value: "1")
                InfoRow(label: "Size", value: "45.2 MB")
                InfoRow(label: "Uploaded", value: "2 hours ago")
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
}

struct BuildActionsCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Build Actions")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                ActionButton(title: "Create New Build", icon: "plus.circle", color: .blue)
                ActionButton(title: "Upload Build", icon: "arrow.up.circle", color: .green)
                ActionButton(title: "View Build History", icon: "clock", color: .orange)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

struct ActionButton: View {
    let title: String
    let icon: String
    let color: Color
    
    var body: some View {
        Button(action: {
            // Action implementation
        }) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.subheadline)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Sheet Views

struct SubmissionChecklistView: View {
    let checklist: String
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                Text(checklist)
                    .font(.system(.body, design: .monospaced))
                    .padding()
            }
            .navigationTitle("Submission Checklist")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct MetadataEditorView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Text("Metadata Editor - Implementation coming soon")
                .padding()
            .navigationTitle("Edit Metadata")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct ScreenshotManagerView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Text("Screenshot Manager - Implementation coming soon")
                .padding()
            .navigationTitle("Manage Screenshots")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Preview

struct AppStoreSubmissionView_Previews: PreviewProvider {
    static var previews: some View {
        AppStoreSubmissionView()
    }
} 
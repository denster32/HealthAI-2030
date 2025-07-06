import SwiftUI

/// Comprehensive accessibility and HIG compliance audit view
/// Displays audit results and provides tools for fixing identified issues
struct AccessibilityAuditView: View {
    @StateObject private var auditManager = AccessibilityAuditManager.shared
    @State private var selectedTab = 0
    @State private var showingExportSheet = false
    @State private var showingReportSheet = false
    @State private var exportData: Data?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header with audit controls
                auditHeader
                
                // Tab selection
                Picker("Audit Results", selection: $selectedTab) {
                    Text("Accessibility").tag(0)
                    Text("HIG Compliance").tag(1)
                    Text("Summary").tag(2)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                // Content based on selected tab
                TabView(selection: $selectedTab) {
                    accessibilityIssuesView
                        .tag(0)
                    
                    higComplianceIssuesView
                        .tag(1)
                    
                    auditSummaryView
                        .tag(2)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .navigationTitle("Accessibility Audit")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Generate Report") {
                            showingReportSheet = true
                        }
                        Button("Export Results") {
                            exportResults()
                        }
                        Button("Run New Audit") {
                            Task {
                                await auditManager.startComprehensiveAudit()
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $showingReportSheet) {
                AuditReportView(report: auditManager.generateAuditReport())
            }
            .sheet(isPresented: $showingExportSheet) {
                if let data = exportData {
                    ShareSheet(items: [data])
                }
            }
        }
    }
    
    // MARK: - Header
    
    private var auditHeader: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Accessibility & HIG Audit")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    if let lastAudit = auditManager.lastAuditDate {
                        Text("Last audit: \(lastAudit.formatted(date: .abbreviated, time: .shortened))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Button(action: {
                    Task {
                        await auditManager.startComprehensiveAudit()
                    }
                }) {
                    HStack {
                        if auditManager.isAuditing {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "magnifyingglass")
                        }
                        Text(auditManager.isAuditing ? "Auditing..." : "Run Audit")
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .disabled(auditManager.isAuditing)
            }
            
            // Quick stats
            HStack(spacing: 20) {
                StatCard(
                    title: "Accessibility Issues",
                    value: "\(auditManager.auditResults.count)",
                    color: .orange
                )
                
                StatCard(
                    title: "HIG Issues",
                    value: "\(auditManager.higComplianceResults.count)",
                    color: .blue
                )
                
                StatCard(
                    title: "Critical",
                    value: "\(criticalIssuesCount)",
                    color: .red
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
    }
    
    // MARK: - Accessibility Issues View
    
    private var accessibilityIssuesView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                if auditManager.auditResults.isEmpty {
                    emptyStateView(
                        icon: "checkmark.circle.fill",
                        title: "No Accessibility Issues Found",
                        message: "All UI components appear to have proper accessibility support."
                    )
                } else {
                    ForEach(AccessibilityAuditManager.IssueSeverity.allCases, id: \.self) { severity in
                        let issues = auditManager.auditResults.filter { $0.severity == severity }
                        if !issues.isEmpty {
                            IssueSeveritySection(
                                severity: severity,
                                issues: issues,
                                issueType: .accessibility
                            )
                        }
                    }
                }
            }
            .padding()
        }
    }
    
    // MARK: - HIG Compliance Issues View
    
    private var higComplianceIssuesView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                if auditManager.higComplianceResults.isEmpty {
                    emptyStateView(
                        icon: "checkmark.circle.fill",
                        title: "No HIG Compliance Issues Found",
                        message: "All UI components follow Apple's Human Interface Guidelines."
                    )
                } else {
                    ForEach(AccessibilityAuditManager.IssueSeverity.allCases, id: \.self) { severity in
                        let issues = auditManager.higComplianceResults.filter { $0.severity == severity }
                        if !issues.isEmpty {
                            IssueSeveritySection(
                                severity: severity,
                                issues: issues,
                                issueType: .hig
                            )
                        }
                    }
                }
            }
            .padding()
        }
    }
    
    // MARK: - Summary View
    
    private var auditSummaryView: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Overall summary
                SummaryCard(
                    title: "Audit Summary",
                    content: {
                        VStack(alignment: .leading, spacing: 12) {
                            SummaryRow(
                                label: "Total Issues",
                                value: "\(auditManager.auditResults.count + auditManager.higComplianceResults.count)",
                                color: .primary
                            )
                            SummaryRow(
                                label: "Accessibility Issues",
                                value: "\(auditManager.auditResults.count)",
                                color: .orange
                            )
                            SummaryRow(
                                label: "HIG Compliance Issues",
                                value: "\(auditManager.higComplianceResults.count)",
                                color: .blue
                            )
                            SummaryRow(
                                label: "Critical Issues",
                                value: "\(criticalIssuesCount)",
                                color: .red
                            )
                        }
                    }
                )
                
                // Severity breakdown
                SummaryCard(
                    title: "Issues by Severity",
                    content: {
                        VStack(spacing: 8) {
                            ForEach(AccessibilityAuditManager.IssueSeverity.allCases, id: \.self) { severity in
                                let accessibilityCount = auditManager.auditResults.filter { $0.severity == severity }.count
                                let higCount = auditManager.higComplianceResults.filter { $0.severity == severity }.count
                                let total = accessibilityCount + higCount
                                
                                if total > 0 {
                                    SeverityProgressRow(
                                        severity: severity,
                                        count: total,
                                        total: auditManager.auditResults.count + auditManager.higComplianceResults.count
                                    )
                                }
                            }
                        }
                    }
                )
                
                // Recommendations
                SummaryCard(
                    title: "Priority Actions",
                    content: {
                        VStack(alignment: .leading, spacing: 12) {
                            if criticalIssuesCount > 0 {
                                RecommendationRow(
                                    priority: "Critical",
                                    action: "Fix all critical accessibility and HIG issues immediately",
                                    color: .red
                                )
                            }
                            
                            if auditManager.auditResults.filter({ $0.severity == .high }).count > 0 {
                                RecommendationRow(
                                    priority: "High",
                                    action: "Address high-priority accessibility issues",
                                    color: .orange
                                )
                            }
                            
                            if auditManager.higComplianceResults.filter({ $0.severity == .high }).count > 0 {
                                RecommendationRow(
                                    priority: "High",
                                    action: "Address high-priority HIG compliance issues",
                                    color: .orange
                                )
                            }
                            
                            RecommendationRow(
                                priority: "General",
                                action: "Review and implement all recommendations",
                                color: .blue
                            )
                        }
                    }
                )
            }
            .padding()
        }
    }
    
    // MARK: - Helper Views
    
    private var criticalIssuesCount: Int {
        auditManager.auditResults.filter { $0.severity == .critical }.count +
        auditManager.higComplianceResults.filter { $0.severity == .critical }.count
    }
    
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
    
    private func exportResults() {
        exportData = auditManager.exportAuditResults()
        showingExportSheet = true
    }
}

// MARK: - Supporting Views

struct StatCard: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
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

struct IssueSeveritySection: View {
    let severity: AccessibilityAuditManager.IssueSeverity
    let issues: [any Identifiable]
    let issueType: IssueType
    
    enum IssueType {
        case accessibility, hig
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Circle()
                    .fill(severity.color)
                    .frame(width: 12, height: 12)
                
                Text(severity.rawValue)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("\(issues.count)")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(severity.color.opacity(0.2))
                    .cornerRadius(12)
            }
            
            ForEach(Array(issues.enumerated()), id: \.element.id) { index, issue in
                IssueCard(issue: issue, issueType: issueType)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

struct IssueCard: View {
    let issue: any Identifiable
    let issueType: IssueSeveritySection.IssueType
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let accessibilityIssue = issue as? AccessibilityAuditManager.AccessibilityIssue {
                accessibilityIssueView(accessibilityIssue)
            } else if let higIssue = issue as? AccessibilityAuditManager.HIGComplianceIssue {
                higIssueView(higIssue)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
    
    private func accessibilityIssueView(_ issue: AccessibilityAuditManager.AccessibilityIssue) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(issue.issueType.rawValue)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text(issue.component)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(issue.description)
                .font(.body)
                .foregroundColor(.secondary)
            
            Text("Recommendation: \(issue.recommendation)")
                .font(.caption)
                .foregroundColor(.blue)
            
            if let filePath = issue.filePath, let lineNumber = issue.lineNumber {
                Text("Location: \(filePath):\(lineNumber)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private func higIssueView(_ issue: AccessibilityAuditManager.HIGComplianceIssue) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(issue.issueType.rawValue)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text(issue.component)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(issue.description)
                .font(.body)
                .foregroundColor(.secondary)
            
            Text("HIG Guideline: \(issue.higGuideline)")
                .font(.caption)
                .foregroundColor(.purple)
            
            Text("Recommendation: \(issue.recommendation)")
                .font(.caption)
                .foregroundColor(.blue)
            
            if let filePath = issue.filePath, let lineNumber = issue.lineNumber {
                Text("Location: \(filePath):\(lineNumber)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct SummaryCard<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
            
            content
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

struct SummaryRow: View {
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
    }
}

struct SeverityProgressRow: View {
    let severity: AccessibilityAuditManager.IssueSeverity
    let count: Int
    let total: Int
    
    var body: some View {
        VStack(spacing: 4) {
            HStack {
                Circle()
                    .fill(severity.color)
                    .frame(width: 8, height: 8)
                
                Text(severity.rawValue)
                    .font(.caption)
                
                Spacer()
                
                Text("\(count)")
                    .font(.caption)
                    .fontWeight(.semibold)
            }
            
            ProgressView(value: Double(count), total: Double(total))
                .progressViewStyle(LinearProgressViewStyle(tint: severity.color))
        }
    }
}

struct RecommendationRow: View {
    let priority: String
    let action: String
    let color: Color
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text(priority)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(color)
                .frame(width: 60, alignment: .leading)
            
            Text(action)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
        }
    }
}

struct AuditReportView: View {
    let report: String
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                Text(report)
                    .font(.system(.body, design: .monospaced))
                    .padding()
            }
            .navigationTitle("Audit Report")
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

struct AccessibilityAuditView_Previews: PreviewProvider {
    static var previews: some View {
        AccessibilityAuditView()
    }
} 
import SwiftUI

// MARK: - HIG Compliance Manager
public class HIGComplianceManager: ObservableObject {
    @Published public var complianceScore: Double = 0.0
    @Published public var violations: [HIGViolation] = []
    @Published public var recommendations: [HIGRecommendation] = []
    
    public struct HIGViolation {
        let severity: ViolationSeverity
        let category: ViolationCategory
        let component: String
        let description: String
        let guideline: String
        let fix: String
        
        public enum ViolationSeverity {
            case minor, moderate, major, critical
        }
        
        public enum ViolationCategory {
            case navigation, typography, spacing, color, interaction, layout
        }
    }
    
    public struct HIGRecommendation {
        let category: String
        let title: String
        let description: String
        let priority: RecommendationPriority
        
        public enum RecommendationPriority {
            case low, medium, high, critical
        }
    }
    
    public func auditCompliance() {
        // This would implement actual HIG compliance checking
        // For now, it's a placeholder with sample data
        complianceScore = 0.92
        violations = [
            HIGViolation(
                severity: .minor,
                category: .spacing,
                component: "HealthMetricCard",
                description: "Inconsistent spacing between elements",
                guideline: "Use consistent spacing throughout the interface",
                fix: "Apply HealthAIDesignSystem.Spacing constants"
            ),
            HIGViolation(
                severity: .moderate,
                category: .typography,
                component: "DashboardView",
                description: "Text hierarchy not clearly defined",
                guideline: "Establish clear typographic hierarchy",
                fix: "Use semantic font styles and weights"
            )
        ]
        
        recommendations = [
            HIGRecommendation(
                category: "Navigation",
                title: "Implement Tab Bar Navigation",
                description: "Use standard tab bar for primary navigation",
                priority: .high
            ),
            HIGRecommendation(
                category: "Interaction",
                title: "Add Haptic Feedback",
                description: "Provide tactile feedback for important actions",
                priority: .medium
            )
        ]
    }
    
    public func generateReport() -> String {
        var report = "HIG Compliance Report\n"
        report += "===================\n\n"
        report += "Overall Score: \(Int(complianceScore * 100))%\n\n"
        
        if violations.isEmpty {
            report += "✅ No HIG violations found!\n\n"
        } else {
            report += "Violations Found:\n"
            for violation in violations {
                report += "- [\(violation.severity)] \(violation.category): \(violation.component)\n"
                report += "  Description: \(violation.description)\n"
                report += "  Guideline: \(violation.guideline)\n"
                report += "  Fix: \(violation.fix)\n\n"
            }
        }
        
        if !recommendations.isEmpty {
            report += "Recommendations:\n"
            for recommendation in recommendations {
                report += "- [\(recommendation.priority)] \(recommendation.category): \(recommendation.title)\n"
                report += "  \(recommendation.description)\n\n"
            }
        }
        
        return report
    }
}

// MARK: - HIG Compliant Navigation
public struct HIGCompliantNavigationView<Content: View>: View {
    let title: String?
    let content: Content
    let showBackButton: Bool
    let onBack: (() -> Void)?
    
    public init(
        title: String? = nil,
        showBackButton: Bool = true,
        onBack: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.showBackButton = showBackButton
        self.onBack = onBack
        self.content = content()
    }
    
    public var body: some View {
        NavigationView {
            content
                .navigationTitle(title ?? "")
                .navigationBarTitleDisplayMode(.large)
                .toolbar {
                    if showBackButton, let onBack = onBack {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("Back") {
                                onBack()
                            }
                            .accessibilityLabel(Text("Go back"))
                        }
                    }
                }
        }
        .navigationViewStyle(.stack)
    }
}

// MARK: - HIG Compliant Tab Bar
public struct HIGCompliantTabBar: View {
    let tabs: [HIGTabItem]
    @Binding var selectedTab: Int
    
    public struct HIGTabItem {
        let title: String
        let icon: String
        let content: AnyView
        
        public init(title: String, icon: String, content: AnyView) {
            self.title = title
            self.icon = icon
            self.content = content
        }
    }
    
    public init(tabs: [HIGTabItem], selectedTab: Binding<Int>) {
        self.tabs = tabs
        self._selectedTab = selectedTab
    }
    
    public var body: some View {
        TabView(selection: $selectedTab) {
            ForEach(Array(tabs.enumerated()), id: \.offset) { index, tab in
                tab.content
                    .tabItem {
                        Image(systemName: tab.icon)
                        Text(tab.title)
                    }
                    .tag(index)
                    .accessibilityLabel(Text("\(tab.title) tab"))
            }
        }
        .accentColor(HealthAIDesignSystem.Color.healthPrimary)
    }
}

// MARK: - HIG Compliant List
public struct HIGCompliantList<Data: RandomAccessCollection, Content: View>: View where Data.Element: Identifiable {
    let data: Data
    let content: (Data.Element) -> Content
    let style: ListStyle
    
    public init(
        _ data: Data,
        style: ListStyle = .plain,
        @ViewBuilder content: @escaping (Data.Element) -> Content
    ) {
        self.data = data
        self.style = style
        self.content = content
    }
    
    public var body: some View {
        List(data) { item in
            content(item)
                .listRowBackground(HealthAIDesignSystem.Color.surface)
                .listRowSeparator(.visible)
        }
        .listStyle(style)
        .background(HealthAIDesignSystem.Color.background)
    }
}

// MARK: - HIG Compliant Button
public struct HIGCompliantButton: View {
    let title: String
    let style: ButtonStyle
    let action: () -> Void
    let isEnabled: Bool
    
    public enum ButtonStyle {
        case primary, secondary, destructive
        
        var backgroundColor: Color {
            switch self {
            case .primary: return HealthAIDesignSystem.Color.healthPrimary
            case .secondary: return Color.clear
            case .destructive: return HealthAIDesignSystem.Color.warningRed
            }
        }
        
        var foregroundColor: Color {
            switch self {
            case .primary: return .white
            case .secondary: return HealthAIDesignSystem.Color.healthPrimary
            case .destructive: return .white
            }
        }
        
        var borderColor: Color {
            switch self {
            case .primary: return Color.clear
            case .secondary: return HealthAIDesignSystem.Color.healthPrimary
            case .destructive: return Color.clear
            }
        }
    }
    
    public init(
        title: String,
        style: ButtonStyle = .primary,
        isEnabled: Bool = true,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.style = style
        self.isEnabled = isEnabled
        self.action = action
    }
    
    public var body: some View {
        Button(action: action) {
            Text(title)
                .font(HealthAIDesignSystem.Typography.headline)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity, minHeight: 44)
                .background(style.backgroundColor)
                .foregroundColor(style.foregroundColor)
                .cornerRadius(HealthAIDesignSystem.Layout.cornerRadius)
                .overlay(
                    RoundedRectangle(cornerRadius: HealthAIDesignSystem.Layout.cornerRadius)
                        .stroke(style.borderColor, lineWidth: 1)
                )
        }
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1.0 : 0.6)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(title))
        .accessibilityHint(Text("Double tap to activate"))
    }
}

// MARK: - HIG Compliant Card
public struct HIGCompliantCard<Content: View>: View {
    let content: Content
    let padding: CGFloat
    let cornerRadius: CGFloat
    let shadowRadius: CGFloat
    
    public init(
        padding: CGFloat = HealthAIDesignSystem.Spacing.medium,
        cornerRadius: CGFloat = HealthAIDesignSystem.Layout.cornerRadius,
        shadowRadius: CGFloat = HealthAIDesignSystem.Layout.shadowRadius,
        @ViewBuilder content: () -> Content
    ) {
        self.padding = padding
        self.cornerRadius = cornerRadius
        self.shadowRadius = shadowRadius
        self.content = content()
    }
    
    public var body: some View {
        content
            .padding(padding)
            .background(HealthAIDesignSystem.Color.surface)
            .cornerRadius(cornerRadius)
            .shadow(color: Color.black.opacity(0.1), radius: shadowRadius, x: 0, y: 2)
            .accessibilityElement(children: .contain)
    }
}

// MARK: - HIG Compliant Form
public struct HIGCompliantForm<Content: View>: View {
    let title: String?
    let content: Content
    let onSubmit: (() -> Void)?
    let submitTitle: String
    
    public init(
        title: String? = nil,
        submitTitle: String = "Submit",
        onSubmit: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.submitTitle = submitTitle
        self.onSubmit = onSubmit
        self.content = content()
    }
    
    public var body: some View {
        VStack(spacing: HealthAIDesignSystem.Spacing.large) {
            if let title = title {
                Text(title)
                    .font(HealthAIDesignSystem.Typography.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .accessibilityAddTraits(.isHeader)
            }
            
            ScrollView {
                VStack(spacing: HealthAIDesignSystem.Spacing.medium) {
                    content
                }
                .padding()
            }
            
            if let onSubmit = onSubmit {
                HIGCompliantButton(
                    title: submitTitle,
                    style: .primary,
                    action: onSubmit
                )
                .padding()
            }
        }
        .background(HealthAIDesignSystem.Color.background)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text("Form: \(title ?? "Data entry form")"))
    }
}

// MARK: - HIG Compliance Audit View
public struct HIGComplianceAuditView: View {
    @StateObject private var complianceManager = HIGComplianceManager()
    @State private var showingReport = false
    
    public var body: some View {
        VStack(spacing: HealthAIDesignSystem.Spacing.large) {
            Text("HIG Compliance Audit")
                .font(HealthAIDesignSystem.Typography.largeTitle)
                .fontWeight(.bold)
                .accessibilityAddTraits(.isHeader)
            
            VStack(spacing: HealthAIDesignSystem.Spacing.medium) {
                HStack {
                    Text("Compliance Score")
                        .font(HealthAIDesignSystem.Typography.headline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Text("\(Int(complianceManager.complianceScore * 100))%")
                        .font(HealthAIDesignSystem.Typography.title)
                        .fontWeight(.bold)
                        .foregroundColor(complianceScoreColor)
                }
                
                ProgressView(value: complianceManager.complianceScore)
                    .progressViewStyle(LinearProgressViewStyle(tint: complianceScoreColor))
            }
            .padding()
            .background(HealthAIDesignSystem.Color.surface)
            .cornerRadius(HealthAIDesignSystem.Layout.cornerRadius)
            
            if !complianceManager.violations.isEmpty {
                VStack(alignment: .leading, spacing: HealthAIDesignSystem.Spacing.medium) {
                    Text("Violations (\(complianceManager.violations.count))")
                        .font(HealthAIDesignSystem.Typography.headline)
                        .fontWeight(.medium)
                    
                    ForEach(Array(complianceManager.violations.enumerated()), id: \.offset) { index, violation in
                        ViolationCard(violation: violation)
                    }
                }
            }
            
            if !complianceManager.recommendations.isEmpty {
                VStack(alignment: .leading, spacing: HealthAIDesignSystem.Spacing.medium) {
                    Text("Recommendations (\(complianceManager.recommendations.count))")
                        .font(HealthAIDesignSystem.Typography.headline)
                        .fontWeight(.medium)
                    
                    ForEach(Array(complianceManager.recommendations.enumerated()), id: \.offset) { index, recommendation in
                        RecommendationCard(recommendation: recommendation)
                    }
                }
            }
            
            HStack(spacing: HealthAIDesignSystem.Spacing.medium) {
                HIGCompliantButton(
                    title: "Run Audit",
                    style: .primary
                ) {
                    complianceManager.auditCompliance()
                }
                
                HIGCompliantButton(
                    title: "View Report",
                    style: .secondary
                ) {
                    showingReport = true
                }
            }
        }
        .padding()
        .onAppear {
            complianceManager.auditCompliance()
        }
        .sheet(isPresented: $showingReport) {
            ReportView(report: complianceManager.generateReport())
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text("HIG compliance audit interface"))
    }
    
    private var complianceScoreColor: Color {
        let score = complianceManager.complianceScore
        if score >= 0.9 { return .green }
        if score >= 0.7 { return .orange }
        return .red
    }
}

// MARK: - Supporting Views
private struct ViolationCard: View {
    let violation: HIGComplianceManager.HIGViolation
    
    var body: some View {
        VStack(alignment: .leading, spacing: HealthAIDesignSystem.Spacing.small) {
            HStack {
                Text(violation.component)
                    .font(HealthAIDesignSystem.Typography.subheadline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text(violation.severity.rawValue.capitalized)
                    .font(HealthAIDesignSystem.Typography.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(severityColor.opacity(0.2))
                    .foregroundColor(severityColor)
                    .cornerRadius(4)
            }
            
            Text(violation.description)
                .font(HealthAIDesignSystem.Typography.body)
                .foregroundColor(HealthAIDesignSystem.Color.textSecondary)
            
            Text("Fix: \(violation.fix)")
                .font(HealthAIDesignSystem.Typography.caption)
                .foregroundColor(HealthAIDesignSystem.Color.infoBlue)
        }
        .padding()
        .background(HealthAIDesignSystem.Color.surface)
        .cornerRadius(HealthAIDesignSystem.Layout.cornerRadius)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text("Violation: \(violation.description)"))
    }
    
    private var severityColor: Color {
        switch violation.severity {
        case .minor: return .blue
        case .moderate: return .orange
        case .major: return .red
        case .critical: return .purple
        }
    }
}

private struct RecommendationCard: View {
    let recommendation: HIGComplianceManager.HIGRecommendation
    
    var body: some View {
        VStack(alignment: .leading, spacing: HealthAIDesignSystem.Spacing.small) {
            HStack {
                Text(recommendation.title)
                    .font(HealthAIDesignSystem.Typography.subheadline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text(recommendation.priority.rawValue.capitalized)
                    .font(HealthAIDesignSystem.Typography.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(priorityColor.opacity(0.2))
                    .foregroundColor(priorityColor)
                    .cornerRadius(4)
            }
            
            Text(recommendation.description)
                .font(HealthAIDesignSystem.Typography.body)
                .foregroundColor(HealthAIDesignSystem.Color.textSecondary)
        }
        .padding()
        .background(HealthAIDesignSystem.Color.surface)
        .cornerRadius(HealthAIDesignSystem.Layout.cornerRadius)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text("Recommendation: \(recommendation.title)"))
    }
    
    private var priorityColor: Color {
        switch recommendation.priority {
        case .low: return .blue
        case .medium: return .orange
        case .high: return .red
        case .critical: return .purple
        }
    }
}

private struct ReportView: View {
    let report: String
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                Text(report)
                    .font(.system(.body, design: .monospaced))
                    .padding()
            }
            .navigationTitle("HIG Compliance Report")
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

import SwiftUI
import Charts
import Combine

/// Advanced Health Data Privacy & Security Dashboard View
/// Provides comprehensive privacy controls, security monitoring, compliance management, and audit capabilities
@available(iOS 18.0, macOS 15.0, *)
public struct AdvancedHealthDataPrivacyDashboardView: View {
    
    // MARK: - Environment
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - State
    @StateObject private var privacyEngine: AdvancedHealthDataPrivacyEngine
    @State private var selectedTab: PrivacyTab = .overview
    @State private var selectedCategory: PrivacyCategory = .all
    @State private var selectedSeverity: AlertSeverity = .all
    @State private var selectedTimeframe: Timeframe = .week
    @State private var showingPrivacyDetail = false
    @State private var showingSecurityDetail = false
    @State private var showingComplianceDetail = false
    @State private var showingAuditDetail = false
    @State private var showingBreachDetail = false
    @State private var showingEncryptionDetail = false
    @State private var showingExportOptions = false
    @State private var selectedSetting: PrivacySetting?
    @State private var selectedAlert: SecurityAlert?
    @State private var selectedBreach: DataBreach?
    @State private var selectedLog: AuditLogEntry?
    @State private var isRefreshing = false
    @State private var searchText = ""
    @State private var showingFilters = false
    @State private var showingSettings = false
    @State private var showingHelp = false
    
    // MARK: - Computed Properties
    private var filteredSettings: [PrivacySetting] {
        let settings = privacyEngine.privacySettings.settings
        if searchText.isEmpty {
            return settings.filter { selectedCategory == .all || $0.category == selectedCategory }
        } else {
            return settings.filter { setting in
                (selectedCategory == .all || setting.category == selectedCategory) &&
                (setting.name.localizedCaseInsensitiveContains(searchText) ||
                 setting.description.localizedCaseInsensitiveContains(searchText))
            }
        }
    }
    
    private var filteredAlerts: [SecurityAlert] {
        let alerts = privacyEngine.securityAlerts
        if searchText.isEmpty {
            return alerts.filter { selectedSeverity == .all || $0.severity == selectedSeverity }
        } else {
            return alerts.filter { alert in
                (selectedSeverity == .all || alert.severity == selectedSeverity) &&
                (alert.title.localizedCaseInsensitiveContains(searchText) ||
                 alert.description.localizedCaseInsensitiveContains(searchText))
            }
        }
    }
    
    private var filteredLogs: [AuditLogEntry] {
        let logs = privacyEngine.auditLogs
        if searchText.isEmpty {
            return logs
        } else {
            return logs.filter { log in
                log.action.localizedCaseInsensitiveContains(searchText) ||
                log.details.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    // MARK: - Initialization
    public init(healthDataManager: HealthDataManager, analyticsEngine: AnalyticsEngine) {
        self._privacyEngine = StateObject(wrappedValue: AdvancedHealthDataPrivacyEngine(
            healthDataManager: healthDataManager,
            analyticsEngine: analyticsEngine
        ))
    }
    
    // MARK: - Body
    public var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Tab Bar
                tabBarView
                
                // Content
                TabView(selection: $selectedTab) {
                    overviewTab
                        .tag(PrivacyTab.overview)
                    
                    privacyTab
                        .tag(PrivacyTab.privacy)
                    
                    securityTab
                        .tag(PrivacyTab.security)
                    
                    complianceTab
                        .tag(PrivacyTab.compliance)
                    
                    auditTab
                        .tag(PrivacyTab.audit)
                    
                    encryptionTab
                        .tag(PrivacyTab.encryption)
                    
                    breachesTab
                        .tag(PrivacyTab.breaches)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .navigationBarHidden(true)
            .background(backgroundColor)
            .sheet(isPresented: $showingPrivacyDetail) {
                if let setting = selectedSetting {
                    PrivacySettingDetailView(setting: setting)
                }
            }
            .sheet(isPresented: $showingSecurityDetail) {
                if let alert = selectedAlert {
                    SecurityAlertDetailView(alert: alert)
                }
            }
            .sheet(isPresented: $showingComplianceDetail) {
                ComplianceDetailView(complianceStatus: privacyEngine.complianceStatus)
            }
            .sheet(isPresented: $showingAuditDetail) {
                if let log = selectedLog {
                    AuditLogDetailView(log: log)
                }
            }
            .sheet(isPresented: $showingBreachDetail) {
                if let breach = selectedBreach {
                    DataBreachDetailView(breach: breach)
                }
            }
            .sheet(isPresented: $showingEncryptionDetail) {
                EncryptionDetailView(encryptionStatus: privacyEngine.encryptionStatus)
            }
            .sheet(isPresented: $showingExportOptions) {
                PrivacyExportView(privacyEngine: privacyEngine)
            }
            .sheet(isPresented: $showingSettings) {
                PrivacySettingsView(privacyEngine: privacyEngine)
            }
            .sheet(isPresented: $showingHelp) {
                PrivacyHelpView()
            }
            .task {
                await startPrivacyMonitoring()
            }
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        VStack(spacing: 16) {
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(spacing: 4) {
                    Text("Health Data Privacy")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("Security & Compliance Management")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                HStack(spacing: 12) {
                    Button(action: { showingFilters.toggle() }) {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                    
                    Button(action: { showingSettings.toggle() }) {
                        Image(systemName: "gearshape.fill")
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                    
                    Button(action: { showingHelp.toggle() }) {
                        Image(systemName: "questionmark.circle")
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // Status Bar
            HStack {
                HStack(spacing: 8) {
                    Circle()
                        .fill(privacyEngine.isPrivacyActive ? Color.green : Color.red)
                        .frame(width: 8, height: 8)
                    
                    Text(privacyEngine.isPrivacyActive ? "Privacy Active" : "Privacy Inactive")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if privacyEngine.isPrivacyActive {
                    ProgressView(value: privacyEngine.privacyProgress)
                        .progressViewStyle(LinearProgressViewStyle())
                        .frame(width: 100)
                }
                
                Spacer()
                
                Button(action: { Task { await refreshPrivacy() } }) {
                    HStack(spacing: 4) {
                        if isRefreshing {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "arrow.clockwise")
                                .font(.caption)
                        }
                        
                        Text("Refresh")
                            .font(.caption)
                    }
                    .foregroundColor(.blue)
                }
                .disabled(isRefreshing)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 16)
        .background(headerBackgroundColor)
    }
    
    // MARK: - Tab Bar View
    private var tabBarView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(PrivacyTab.allCases, id: \.self) { tab in
                    Button(action: { selectedTab = tab }) {
                        VStack(spacing: 4) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 16, weight: .medium))
                            
                            Text(tab.title)
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(selectedTab == tab ? .white : .secondary)
                        .frame(width: 80, height: 50)
                        .background(selectedTab == tab ? Color.blue : Color.clear)
                        .cornerRadius(12)
                    }
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.bottom, 16)
        .background(tabBarBackgroundColor)
    }
    
    // MARK: - Overview Tab
    private var overviewTab: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                // Security Status Cards
                securityStatusSection
                
                // Privacy Settings
                privacySettingsSection
                
                // Compliance Status
                complianceStatusSection
                
                // Recent Security Alerts
                recentAlertsSection
                
                // Encryption Status
                encryptionStatusSection
                
                // Quick Actions
                quickActionsSection
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
    }
    
    // MARK: - Privacy Tab
    private var privacyTab: some View {
        VStack(spacing: 0) {
            // Search and Filters
            searchAndFiltersView
            
            // Privacy Settings List
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(filteredSettings) { setting in
                        PrivacySettingCard(setting: setting) {
                            selectedSetting = setting
                            showingPrivacyDetail = true
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
    }
    
    // MARK: - Security Tab
    private var securityTab: some View {
        VStack(spacing: 0) {
            // Search and Filters
            searchAndFiltersView
            
            // Security Alerts List
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(filteredAlerts) { alert in
                        SecurityAlertCard(alert: alert) {
                            selectedAlert = alert
                            showingSecurityDetail = true
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
    }
    
    // MARK: - Compliance Tab
    private var complianceTab: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                // Compliance Overview
                complianceOverviewSection
                
                // HIPAA Compliance
                hipaaComplianceSection
                
                // GDPR Compliance
                gdprComplianceSection
                
                // CCPA Compliance
                ccpaComplianceSection
                
                // SOC2 Compliance
                soc2ComplianceSection
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
    }
    
    // MARK: - Audit Tab
    private var auditTab: some View {
        VStack(spacing: 0) {
            // Search and Filters
            searchAndFiltersView
            
            // Audit Logs List
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(filteredLogs) { log in
                        AuditLogCard(log: log) {
                            selectedLog = log
                            showingAuditDetail = true
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
    }
    
    // MARK: - Encryption Tab
    private var encryptionTab: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                // Encryption Overview
                encryptionOverviewSection
                
                // Encryption Settings
                encryptionSettingsSection
                
                // Key Management
                keyManagementSection
                
                // Encryption Statistics
                encryptionStatisticsSection
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
    }
    
    // MARK: - Breaches Tab
    private var breachesTab: some View {
        VStack(spacing: 0) {
            // Search and Filters
            searchAndFiltersView
            
            // Data Breaches List
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(privacyEngine.dataBreaches) { breach in
                        DataBreachCard(breach: breach) {
                            selectedBreach = breach
                            showingBreachDetail = true
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
    }
    
    // MARK: - Section Views
    
    private var securityStatusSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Security Status", icon: "shield.fill")
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                SecurityMetricCard(
                    title: "Security Score",
                    value: "\(Int(privacyEngine.securityStatus.securityScore * 100))",
                    unit: "%",
                    icon: "shield.checkered",
                    color: securityScoreColor
                )
                
                SecurityMetricCard(
                    title: "Threat Level",
                    value: privacyEngine.securityStatus.threatLevel.rawValue.capitalized,
                    unit: "",
                    icon: "exclamationmark.triangle.fill",
                    color: threatLevelColor
                )
                
                SecurityMetricCard(
                    title: "Vulnerabilities",
                    value: "\(privacyEngine.securityStatus.vulnerabilities.count)",
                    unit: "",
                    icon: "bug.fill",
                    color: .orange
                )
                
                SecurityMetricCard(
                    title: "Security Alerts",
                    value: "\(privacyEngine.securityAlerts.count)",
                    unit: "",
                    icon: "bell.fill",
                    color: .red
                )
            }
        }
    }
    
    private var privacySettingsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Privacy Settings", icon: "lock.fill")
            
            ForEach(Array(privacyEngine.privacySettings.settings.prefix(3))) { setting in
                PrivacySettingRow(setting: setting) {
                    selectedSetting = setting
                    showingPrivacyDetail = true
                }
            }
        }
    }
    
    private var complianceStatusSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Compliance Status", icon: "checkmark.shield.fill")
            
            ComplianceStatusCard(complianceStatus: privacyEngine.complianceStatus)
        }
    }
    
    private var recentAlertsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Recent Security Alerts", icon: "bell.fill")
            
            ForEach(Array(privacyEngine.securityAlerts.prefix(3))) { alert in
                SecurityAlertRow(alert: alert) {
                    selectedAlert = alert
                    showingSecurityDetail = true
                }
            }
        }
    }
    
    private var encryptionStatusSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Encryption Status", icon: "lock.shield.fill")
            
            EncryptionStatusCard(encryptionStatus: privacyEngine.encryptionStatus)
        }
    }
    
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Quick Actions", icon: "bolt.fill")
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                QuickActionCard(
                    title: "Privacy Audit",
                    icon: "magnifyingglass",
                    color: .blue
                ) {
                    Task { await performPrivacyAudit() }
                }
                
                QuickActionCard(
                    title: "Export Report",
                    icon: "square.and.arrow.up",
                    color: .green
                ) {
                    showingExportOptions = true
                }
                
                QuickActionCard(
                    title: "Security Scan",
                    icon: "shield.checkered",
                    color: .orange
                ) {
                    // Security scan action
                }
                
                QuickActionCard(
                    title: "View Logs",
                    icon: "doc.text",
                    color: .purple
                ) {
                    selectedTab = .audit
                }
            }
        }
    }
    
    private var searchAndFiltersView: some View {
        VStack(spacing: 12) {
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Search...", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(.systemGray6))
            .cornerRadius(10)
            
            // Filters
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    FilterChip(
                        title: selectedCategory.rawValue.capitalized,
                        isSelected: true
                    ) {
                        // Category filter
                    }
                    
                    FilterChip(
                        title: selectedSeverity.rawValue.capitalized,
                        isSelected: true
                    ) {
                        // Severity filter
                    }
                    
                    FilterChip(
                        title: selectedTimeframe.rawValue.capitalized,
                        isSelected: true
                    ) {
                        // Timeframe filter
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(filterBackgroundColor)
    }
    
    private var complianceOverviewSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Compliance Overview", icon: "checkmark.shield.fill")
            
            ComplianceOverviewCard(complianceStatus: privacyEngine.complianceStatus)
        }
    }
    
    private var hipaaComplianceSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "HIPAA Compliance", icon: "heart.fill")
            
            HIPAAComplianceCard(complianceLevel: privacyEngine.complianceStatus.hipaaCompliance)
        }
    }
    
    private var gdprComplianceSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "GDPR Compliance", icon: "globe")
            
            GDPRComplianceCard(complianceLevel: privacyEngine.complianceStatus.gdprCompliance)
        }
    }
    
    private var ccpaComplianceSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "CCPA Compliance", icon: "building.2")
            
            CCPAComplianceCard(complianceLevel: privacyEngine.complianceStatus.ccpaCompliance)
        }
    }
    
    private var soc2ComplianceSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "SOC2 Compliance", icon: "server.rack")
            
            SOC2ComplianceCard(complianceLevel: privacyEngine.complianceStatus.soc2Compliance)
        }
    }
    
    private var encryptionOverviewSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Encryption Overview", icon: "lock.shield.fill")
            
            EncryptionOverviewCard(encryptionStatus: privacyEngine.encryptionStatus)
        }
    }
    
    private var encryptionSettingsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Encryption Settings", icon: "gearshape.fill")
            
            // Placeholder for encryption settings
            Text("Encryption settings will appear here")
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding()
        }
    }
    
    private var keyManagementSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Key Management", icon: "key.fill")
            
            // Placeholder for key management
            Text("Key management will appear here")
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding()
        }
    }
    
    private var encryptionStatisticsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Encryption Statistics", icon: "chart.bar.fill")
            
            // Placeholder for encryption statistics
            Text("Encryption statistics will appear here")
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding()
        }
    }
    
    // MARK: - Helper Methods
    
    private func startPrivacyMonitoring() async {
        do {
            try await privacyEngine.startPrivacyMonitoring()
        } catch {
            print("Failed to start privacy monitoring: \(error)")
        }
    }
    
    private func refreshPrivacy() async {
        isRefreshing = true
        
        do {
            _ = try await privacyEngine.performPrivacyAudit()
        } catch {
            print("Failed to refresh privacy: \(error)")
        }
        
        isRefreshing = false
    }
    
    private func performPrivacyAudit() async {
        do {
            _ = try await privacyEngine.performPrivacyAudit()
        } catch {
            print("Failed to perform privacy audit: \(error)")
        }
    }
    
    // MARK: - Computed Colors
    
    private var securityScoreColor: Color {
        let score = privacyEngine.securityStatus.securityScore
        if score > 0.8 { return .green }
        else if score > 0.6 { return .yellow }
        else { return .red }
    }
    
    private var threatLevelColor: Color {
        switch privacyEngine.securityStatus.threatLevel {
        case .low: return .green
        case .medium: return .yellow
        case .high: return .orange
        case .critical: return .red
        }
    }
    
    // MARK: - Colors
    
    private var backgroundColor: Color {
        colorScheme == .dark ? Color(.systemBackground) : Color(.systemGroupedBackground)
    }
    
    private var headerBackgroundColor: Color {
        colorScheme == .dark ? Color(.systemGray6) : Color(.systemBackground)
    }
    
    private var tabBarBackgroundColor: Color {
        colorScheme == .dark ? Color(.systemGray6) : Color(.systemBackground)
    }
    
    private var filterBackgroundColor: Color {
        colorScheme == .dark ? Color(.systemGray6) : Color(.systemBackground)
    }
}

// MARK: - Supporting Views

struct SectionHeader: View {
    let title: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .font(.title3)
            
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
            
            Spacer()
        }
    }
}

struct SecurityMetricCard: View {
    let title: String
    let value: String
    let unit: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title2)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text(unit)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

struct QuickActionCard: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title2)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.blue : Color(.systemGray5))
                .cornerRadius(16)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Privacy Tab Enum

enum PrivacyTab: String, CaseIterable {
    case overview, privacy, security, compliance, audit, encryption, breaches
    
    var title: String {
        switch self {
        case .overview: return "Overview"
        case .privacy: return "Privacy"
        case .security: return "Security"
        case .compliance: return "Compliance"
        case .audit: return "Audit"
        case .encryption: return "Encryption"
        case .breaches: return "Breaches"
        }
    }
    
    var icon: String {
        switch self {
        case .overview: return "shield.fill"
        case .privacy: return "lock.fill"
        case .security: return "shield.checkered"
        case .compliance: return "checkmark.shield.fill"
        case .audit: return "doc.text"
        case .encryption: return "lock.shield.fill"
        case .breaches: return "exclamationmark.triangle.fill"
        }
    }
}

// MARK: - Preview

@available(iOS 18.0, macOS 15.0, *)
struct AdvancedHealthDataPrivacyDashboardView_Previews: PreviewProvider {
    static var previews: some View {
        AdvancedHealthDataPrivacyDashboardView(
            healthDataManager: HealthDataManager(),
            analyticsEngine: AnalyticsEngine()
        )
    }
} 
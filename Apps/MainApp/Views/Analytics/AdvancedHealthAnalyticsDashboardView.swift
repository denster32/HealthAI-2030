import SwiftUI
import Charts
import Combine

/// Advanced Health Analytics & Business Intelligence Dashboard View
/// Provides comprehensive analytics visualization, predictive modeling, business intelligence, and advanced reporting
@available(iOS 18.0, macOS 15.0, *)
public struct AdvancedHealthAnalyticsDashboardView: View {
    
    // MARK: - Environment
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - State
    @StateObject private var analyticsEngine: AdvancedHealthAnalyticsEngine
    @State private var selectedTab: AnalyticsTab = .overview
    @State private var selectedTimeframe: Timeframe = .week
    @State private var selectedCategory: InsightCategory = .all
    @State private var selectedModelType: ModelType = .all
    @State private var selectedReportType: ReportType = .all
    @State private var selectedDashboardCategory: DashboardCategory = .all
    @State private var showingInsightDetail = false
    @State private var showingModelDetail = false
    @State private var showingReportDetail = false
    @State private var showingDashboardDetail = false
    @State private var showingForecastDetail = false
    @State private var showingExportOptions = false
    @State private var selectedInsight: AnalyticsInsight?
    @State private var selectedModel: PredictiveModel?
    @State private var selectedReport: AnalyticsReport?
    @State private var selectedDashboard: AnalyticsDashboard?
    @State private var selectedForecast: PredictiveForecast?
    @State private var isRefreshing = false
    @State private var searchText = ""
    @State private var showingFilters = false
    @State private var showingSettings = false
    @State private var showingHelp = false
    
    // MARK: - Computed Properties
    private var filteredInsights: [AnalyticsInsight] {
        let insights = analyticsEngine.analyticsInsights
        if searchText.isEmpty {
            return insights.filter { selectedCategory == .all || $0.category == selectedCategory }
        } else {
            return insights.filter { insight in
                (selectedCategory == .all || insight.category == selectedCategory) &&
                (insight.title.localizedCaseInsensitiveContains(searchText) ||
                 insight.description.localizedCaseInsensitiveContains(searchText))
            }
        }
    }
    
    private var filteredModels: [PredictiveModel] {
        let models = analyticsEngine.predictiveModels
        if searchText.isEmpty {
            return models.filter { selectedModelType == .all || $0.type == selectedModelType }
        } else {
            return models.filter { model in
                (selectedModelType == .all || model.type == selectedModelType) &&
                model.name.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    private var filteredReports: [AnalyticsReport] {
        let reports = analyticsEngine.reports
        if searchText.isEmpty {
            return reports.filter { selectedReportType == .all || $0.type == selectedReportType }
        } else {
            return reports.filter { report in
                (selectedReportType == .all || report.type == selectedReportType) &&
                report.title.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    private var filteredDashboards: [AnalyticsDashboard] {
        let dashboards = analyticsEngine.dashboards
        if searchText.isEmpty {
            return dashboards.filter { selectedDashboardCategory == .all || $0.category == selectedDashboardCategory }
        } else {
            return dashboards.filter { dashboard in
                (selectedDashboardCategory == .all || dashboard.category == selectedDashboardCategory) &&
                dashboard.name.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    // MARK: - Initialization
    public init(healthDataManager: HealthDataManager, analyticsEngine: AnalyticsEngine) {
        self._analyticsEngine = StateObject(wrappedValue: AdvancedHealthAnalyticsEngine(
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
                        .tag(AnalyticsTab.overview)
                    
                    insightsTab
                        .tag(AnalyticsTab.insights)
                    
                    modelsTab
                        .tag(AnalyticsTab.models)
                    
                    metricsTab
                        .tag(AnalyticsTab.metrics)
                    
                    reportsTab
                        .tag(AnalyticsTab.reports)
                    
                    dashboardsTab
                        .tag(AnalyticsTab.dashboards)
                    
                    forecastsTab
                        .tag(AnalyticsTab.forecasts)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .navigationBarHidden(true)
            .background(backgroundColor)
            .sheet(isPresented: $showingInsightDetail) {
                if let insight = selectedInsight {
                    AnalyticsInsightDetailView(insight: insight)
                }
            }
            .sheet(isPresented: $showingModelDetail) {
                if let model = selectedModel {
                    PredictiveModelDetailView(model: model)
                }
            }
            .sheet(isPresented: $showingReportDetail) {
                if let report = selectedReport {
                    AnalyticsReportDetailView(report: report)
                }
            }
            .sheet(isPresented: $showingDashboardDetail) {
                if let dashboard = selectedDashboard {
                    AnalyticsDashboardDetailView(dashboard: dashboard)
                }
            }
            .sheet(isPresented: $showingForecastDetail) {
                if let forecast = selectedForecast {
                    PredictiveForecastDetailView(forecast: forecast)
                }
            }
            .sheet(isPresented: $showingExportOptions) {
                AnalyticsExportView(analyticsEngine: analyticsEngine)
            }
            .sheet(isPresented: $showingSettings) {
                AnalyticsSettingsView(analyticsEngine: analyticsEngine)
            }
            .sheet(isPresented: $showingHelp) {
                AnalyticsHelpView()
            }
            .task {
                await startAnalytics()
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
                    Text("Health Analytics")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("Business Intelligence & Predictive Analytics")
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
                        .fill(analyticsEngine.isAnalyticsActive ? Color.green : Color.red)
                        .frame(width: 8, height: 8)
                    
                    Text(analyticsEngine.isAnalyticsActive ? "Analytics Active" : "Analytics Inactive")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if analyticsEngine.isAnalyticsActive {
                    ProgressView(value: analyticsEngine.analyticsProgress)
                        .progressViewStyle(LinearProgressViewStyle())
                        .frame(width: 100)
                }
                
                Spacer()
                
                Button(action: { Task { await refreshAnalytics() } }) {
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
                ForEach(AnalyticsTab.allCases, id: \.self) { tab in
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
                // Key Metrics Cards
                keyMetricsSection
                
                // Analytics Insights
                analyticsInsightsSection
                
                // Predictive Models
                predictiveModelsSection
                
                // Business Metrics
                businessMetricsSection
                
                // Recent Reports
                recentReportsSection
                
                // Quick Actions
                quickActionsSection
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
    }
    
    // MARK: - Insights Tab
    private var insightsTab: some View {
        VStack(spacing: 0) {
            // Search and Filters
            searchAndFiltersView
            
            // Insights List
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(filteredInsights) { insight in
                        AnalyticsInsightCard(insight: insight) {
                            selectedInsight = insight
                            showingInsightDetail = true
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
    }
    
    // MARK: - Models Tab
    private var modelsTab: some View {
        VStack(spacing: 0) {
            // Search and Filters
            searchAndFiltersView
            
            // Models List
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(filteredModels) { model in
                        PredictiveModelCard(model: model) {
                            selectedModel = model
                            showingModelDetail = true
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
    }
    
    // MARK: - Metrics Tab
    private var metricsTab: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                // Business Metrics Overview
                businessMetricsOverviewSection
                
                // Performance Metrics
                performanceMetricsSection
                
                // Financial Metrics
                financialMetricsSection
                
                // Operational Metrics
                operationalMetricsSection
                
                // Quality Metrics
                qualityMetricsSection
                
                // Risk Metrics
                riskMetricsSection
                
                // Growth Metrics
                growthMetricsSection
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
    }
    
    // MARK: - Reports Tab
    private var reportsTab: some View {
        VStack(spacing: 0) {
            // Search and Filters
            searchAndFiltersView
            
            // Reports List
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(filteredReports) { report in
                        AnalyticsReportCard(report: report) {
                            selectedReport = report
                            showingReportDetail = true
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
    }
    
    // MARK: - Dashboards Tab
    private var dashboardsTab: some View {
        VStack(spacing: 0) {
            // Search and Filters
            searchAndFiltersView
            
            // Dashboards List
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(filteredDashboards) { dashboard in
                        AnalyticsDashboardCard(dashboard: dashboard) {
                            selectedDashboard = dashboard
                            showingDashboardDetail = true
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
    }
    
    // MARK: - Forecasts Tab
    private var forecastsTab: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                // Forecast Generation
                forecastGenerationSection
                
                // Recent Forecasts
                recentForecastsSection
                
                // Forecast Analytics
                forecastAnalyticsSection
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
    }
    
    // MARK: - Section Views
    
    private var keyMetricsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Key Metrics", icon: "chart.bar.fill")
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                MetricCard(
                    title: "Total Insights",
                    value: "\(analyticsEngine.analyticsInsights.count)",
                    icon: "lightbulb.fill",
                    color: .orange
                )
                
                MetricCard(
                    title: "Active Models",
                    value: "\(analyticsEngine.predictiveModels.filter { $0.status == .active }.count)",
                    icon: "brain.head.profile",
                    color: .blue
                )
                
                MetricCard(
                    title: "Reports Generated",
                    value: "\(analyticsEngine.reports.count)",
                    icon: "doc.text.fill",
                    color: .green
                )
                
                MetricCard(
                    title: "Dashboards",
                    value: "\(analyticsEngine.dashboards.count)",
                    icon: "chart.pie.fill",
                    color: .purple
                )
            }
        }
    }
    
    private var analyticsInsightsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Recent Insights", icon: "lightbulb.fill")
            
            ForEach(Array(analyticsEngine.analyticsInsights.prefix(3))) { insight in
                AnalyticsInsightRow(insight: insight) {
                    selectedInsight = insight
                    showingInsightDetail = true
                }
            }
        }
    }
    
    private var predictiveModelsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Predictive Models", icon: "brain.head.profile")
            
            ForEach(Array(analyticsEngine.predictiveModels.prefix(3))) { model in
                PredictiveModelRow(model: model) {
                    selectedModel = model
                    showingModelDetail = true
                }
            }
        }
    }
    
    private var businessMetricsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Business Metrics", icon: "chart.line.uptrend.xyaxis")
            
            BusinessMetricsCard(metrics: analyticsEngine.businessMetrics)
        }
    }
    
    private var recentReportsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Recent Reports", icon: "doc.text.fill")
            
            ForEach(Array(analyticsEngine.reports.prefix(3))) { report in
                AnalyticsReportRow(report: report) {
                    selectedReport = report
                    showingReportDetail = true
                }
            }
        }
    }
    
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Quick Actions", icon: "bolt.fill")
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                QuickActionCard(
                    title: "Generate Forecast",
                    icon: "chart.line.uptrend.xyaxis",
                    color: .blue
                ) {
                    // Generate forecast action
                }
                
                QuickActionCard(
                    title: "Create Report",
                    icon: "doc.text.fill",
                    color: .green
                ) {
                    // Create report action
                }
                
                QuickActionCard(
                    title: "Export Data",
                    icon: "square.and.arrow.up",
                    color: .orange
                ) {
                    showingExportOptions = true
                }
                
                QuickActionCard(
                    title: "View History",
                    icon: "clock.fill",
                    color: .purple
                ) {
                    // View history action
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
    
    private var businessMetricsOverviewSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Business Metrics Overview", icon: "chart.bar.fill")
            
            BusinessMetricsOverviewCard(metrics: analyticsEngine.businessMetrics)
        }
    }
    
    private var performanceMetricsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Performance Metrics", icon: "speedometer")
            
            PerformanceMetricsCard(metrics: analyticsEngine.businessMetrics.performanceMetrics)
        }
    }
    
    private var financialMetricsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Financial Metrics", icon: "dollarsign.circle.fill")
            
            FinancialMetricsCard(metrics: analyticsEngine.businessMetrics.financialMetrics)
        }
    }
    
    private var operationalMetricsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Operational Metrics", icon: "gearshape.fill")
            
            OperationalMetricsCard(metrics: analyticsEngine.businessMetrics.operationalMetrics)
        }
    }
    
    private var qualityMetricsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Quality Metrics", icon: "checkmark.shield.fill")
            
            QualityMetricsCard(metrics: analyticsEngine.businessMetrics.qualityMetrics)
        }
    }
    
    private var riskMetricsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Risk Metrics", icon: "exclamationmark.triangle.fill")
            
            RiskMetricsCard(metrics: analyticsEngine.businessMetrics.riskMetrics)
        }
    }
    
    private var growthMetricsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Growth Metrics", icon: "chart.line.uptrend.xyaxis")
            
            GrowthMetricsCard(metrics: analyticsEngine.businessMetrics.growthMetrics)
        }
    }
    
    private var forecastGenerationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Generate Forecast", icon: "chart.line.uptrend.xyaxis")
            
            ForecastGenerationCard {
                // Generate forecast action
            }
        }
    }
    
    private var recentForecastsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Recent Forecasts", icon: "clock.fill")
            
            // Placeholder for recent forecasts
            Text("No recent forecasts")
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding()
        }
    }
    
    private var forecastAnalyticsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Forecast Analytics", icon: "chart.bar.fill")
            
            // Placeholder for forecast analytics
            Text("Forecast analytics will appear here")
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding()
        }
    }
    
    // MARK: - Helper Methods
    
    private func startAnalytics() async {
        do {
            try await analyticsEngine.startAnalytics()
        } catch {
            print("Failed to start analytics: \(error)")
        }
    }
    
    private func refreshAnalytics() async {
        isRefreshing = true
        
        do {
            _ = try await analyticsEngine.performAnalytics()
        } catch {
            print("Failed to refresh analytics: \(error)")
        }
        
        isRefreshing = false
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

struct MetricCard: View {
    let title: String
    let value: String
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

// MARK: - Analytics Tab Enum

enum AnalyticsTab: String, CaseIterable {
    case overview, insights, models, metrics, reports, dashboards, forecasts
    
    var title: String {
        switch self {
        case .overview: return "Overview"
        case .insights: return "Insights"
        case .models: return "Models"
        case .metrics: return "Metrics"
        case .reports: return "Reports"
        case .dashboards: return "Dashboards"
        case .forecasts: return "Forecasts"
        }
    }
    
    var icon: String {
        switch self {
        case .overview: return "chart.bar.fill"
        case .insights: return "lightbulb.fill"
        case .models: return "brain.head.profile"
        case .metrics: return "chart.line.uptrend.xyaxis"
        case .reports: return "doc.text.fill"
        case .dashboards: return "chart.pie.fill"
        case .forecasts: return "chart.line.uptrend.xyaxis"
        }
    }
}

// MARK: - Preview

@available(iOS 18.0, macOS 15.0, *)
struct AdvancedHealthAnalyticsDashboardView_Previews: PreviewProvider {
    static var previews: some View {
        AdvancedHealthAnalyticsDashboardView(
            healthDataManager: HealthDataManager(),
            analyticsEngine: AnalyticsEngine()
        )
    }
} 
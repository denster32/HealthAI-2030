import Foundation
import SwiftUI
import Combine
import Charts
import CoreML

/// Advanced Analytics Dashboard Manager
/// Provides comprehensive analytics dashboard functionality with predictive analytics,
/// customizable widgets, advanced filtering, and data comparison tools
@MainActor
final class AdvancedAnalyticsDashboardManager: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var dashboardWidgets: [DashboardWidget] = []
    @Published var selectedTimeRange: TimeRange = .week
    @Published var activeFilters: [AnalyticsFilter] = []
    @Published var comparisonMode: ComparisonMode = .none
    @Published var predictiveInsights: [PredictiveInsight] = []
    @Published var dashboardLayout: DashboardLayout = .default
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    
    private var cancellables = Set<AnyCancellable>()
    private let healthDataManager: HealthDataManager
    private let analyticsEngine: AnalyticsEngine
    private let mlModelManager: MLModelManager
    
    // MARK: - Initialization
    
    init(healthDataManager: HealthDataManager, analyticsEngine: AnalyticsEngine, mlModelManager: MLModelManager) {
        self.healthDataManager = healthDataManager
        self.analyticsEngine = analyticsEngine
        self.mlModelManager = mlModelManager
        
        setupDefaultWidgets()
        setupSubscriptions()
    }
    
    // MARK: - Dashboard Management
    
    /// Setup default dashboard widgets
    private func setupDefaultWidgets() {
        dashboardWidgets = [
            DashboardWidget(
                id: "health-overview",
                type: .healthOverview,
                title: "Health Overview",
                position: CGPoint(x: 0, y: 0),
                size: CGSize(width: 2, height: 1)
            ),
            DashboardWidget(
                id: "activity-trends",
                type: .activityTrends,
                title: "Activity Trends",
                position: CGPoint(x: 2, y: 0),
                size: CGSize(width: 2, height: 1)
            ),
            DashboardWidget(
                id: "sleep-analysis",
                type: .sleepAnalysis,
                title: "Sleep Analysis",
                position: CGPoint(x: 0, y: 1),
                size: CGSize(width: 2, height: 1)
            ),
            DashboardWidget(
                id: "predictive-insights",
                type: .predictiveInsights,
                title: "Predictive Insights",
                position: CGPoint(x: 2, y: 1),
                size: CGSize(width: 2, height: 1)
            )
        ]
    }
    
    /// Setup data subscriptions
    private func setupSubscriptions() {
        // Monitor health data changes
        healthDataManager.healthDataPublisher
            .debounce(for: .seconds(1), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.refreshDashboard()
            }
            .store(in: &cancellables)
        
        // Monitor analytics updates
        analyticsEngine.analyticsUpdatePublisher
            .sink { [weak self] _ in
                self?.updatePredictiveInsights()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Dashboard Operations
    
    /// Refresh dashboard data
    func refreshDashboard() {
        Task {
            isLoading = true
            defer { isLoading = false }
            
            do {
                await updateWidgetData()
                await updatePredictiveInsights()
                await applyFilters()
            } catch {
                errorMessage = "Failed to refresh dashboard: \(error.localizedDescription)"
            }
        }
    }
    
    /// Update widget data based on current time range and filters
    private func updateWidgetData() async {
        for i in 0..<dashboardWidgets.count {
            dashboardWidgets[i].data = await fetchWidgetData(for: dashboardWidgets[i].type)
        }
    }
    
    /// Fetch data for specific widget type
    private func fetchWidgetData(for widgetType: WidgetType) async -> WidgetData {
        switch widgetType {
        case .healthOverview:
            return await fetchHealthOverviewData()
        case .activityTrends:
            return await fetchActivityTrendsData()
        case .sleepAnalysis:
            return await fetchSleepAnalysisData()
        case .predictiveInsights:
            return await fetchPredictiveInsightsData()
        case .custom:
            return WidgetData.empty
        }
    }
    
    // MARK: - Data Fetching Methods
    
    /// Fetch health overview data
    private func fetchHealthOverviewData() async -> WidgetData {
        let healthMetrics = await healthDataManager.getHealthMetrics(for: selectedTimeRange)
        
        return WidgetData(
            title: "Health Overview",
            subtitle: "Last \(selectedTimeRange.displayName)",
            primaryValue: healthMetrics.overallScore,
            secondaryValue: healthMetrics.trend,
            chartData: healthMetrics.dailyScores,
            color: .green
        )
    }
    
    /// Fetch activity trends data
    private func fetchActivityTrendsData() async -> WidgetData {
        let activityData = await healthDataManager.getActivityData(for: selectedTimeRange)
        
        return WidgetData(
            title: "Activity Trends",
            subtitle: "Steps, Exercise, Movement",
            primaryValue: activityData.averageSteps,
            secondaryValue: activityData.trend,
            chartData: activityData.dailySteps,
            color: .blue
        )
    }
    
    /// Fetch sleep analysis data
    private func fetchSleepAnalysisData() async -> WidgetData {
        let sleepData = await healthDataManager.getSleepData(for: selectedTimeRange)
        
        return WidgetData(
            title: "Sleep Analysis",
            subtitle: "Quality & Duration",
            primaryValue: sleepData.averageSleepHours,
            secondaryValue: sleepData.qualityScore,
            chartData: sleepData.dailySleepHours,
            color: .purple
        )
    }
    
    /// Fetch predictive insights data
    private func fetchPredictiveInsightsData() async -> WidgetData {
        let predictions = await analyticsEngine.getPredictions(for: selectedTimeRange)
        
        return WidgetData(
            title: "Predictive Insights",
            subtitle: "AI-Powered Forecasts",
            primaryValue: predictions.confidence,
            secondaryValue: predictions.trend,
            chartData: predictions.forecastData,
            color: .orange
        )
    }
    
    // MARK: - Predictive Analytics
    
    /// Update predictive insights
    private func updatePredictiveInsights() async {
        do {
            let insights = try await generatePredictiveInsights()
            await MainActor.run {
                self.predictiveInsights = insights
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to generate predictive insights: \(error.localizedDescription)"
            }
        }
    }
    
    /// Generate predictive insights using ML models
    private func generatePredictiveInsights() async throws -> [PredictiveInsight] {
        let healthData = await healthDataManager.getHealthData(for: selectedTimeRange)
        
        var insights: [PredictiveInsight] = []
        
        // Health trend prediction
        if let trendPrediction = try await mlModelManager.predictHealthTrend(from: healthData) {
            insights.append(PredictiveInsight(
                type: .healthTrend,
                title: "Health Trend Forecast",
                description: trendPrediction.description,
                confidence: trendPrediction.confidence,
                timeframe: "7 days",
                action: trendPrediction.recommendedAction
            ))
        }
        
        // Risk assessment
        if let riskAssessment = try await mlModelManager.assessHealthRisk(from: healthData) {
            insights.append(PredictiveInsight(
                type: .riskAssessment,
                title: "Health Risk Assessment",
                description: riskAssessment.description,
                confidence: riskAssessment.confidence,
                timeframe: "30 days",
                action: riskAssessment.recommendedAction
            ))
        }
        
        // Goal achievement prediction
        if let goalPrediction = try await mlModelManager.predictGoalAchievement(from: healthData) {
            insights.append(PredictiveInsight(
                type: .goalPrediction,
                title: "Goal Achievement Forecast",
                description: goalPrediction.description,
                confidence: goalPrediction.confidence,
                timeframe: "90 days",
                action: goalPrediction.recommendedAction
            ))
        }
        
        return insights
    }
    
    // MARK: - Filtering & Comparison
    
    /// Apply active filters to dashboard data
    private func applyFilters() async {
        guard !activeFilters.isEmpty else { return }
        
        for i in 0..<dashboardWidgets.count {
            dashboardWidgets[i].data = await applyFiltersToWidget(dashboardWidgets[i].data, filters: activeFilters)
        }
    }
    
    /// Apply filters to widget data
    private func applyFiltersToWidget(_ data: WidgetData, filters: [AnalyticsFilter]) async -> WidgetData {
        var filteredData = data
        
        for filter in filters {
            switch filter.type {
            case .dateRange:
                if let dateFilter = filter as? DateRangeFilter {
                    filteredData = await filterDataByDateRange(filteredData, range: dateFilter.dateRange)
                }
            case .healthMetric:
                if let metricFilter = filter as? HealthMetricFilter {
                    filteredData = await filterDataByHealthMetric(filteredData, metric: metricFilter.metric)
                }
            case .valueRange:
                if let valueFilter = filter as? ValueRangeFilter {
                    filteredData = await filterDataByValueRange(filteredData, range: valueFilter.range)
                }
            }
        }
        
        return filteredData
    }
    
    /// Filter data by date range
    private func filterDataByDateRange(_ data: WidgetData, range: ClosedRange<Date>) async -> WidgetData {
        let filteredChartData = data.chartData.filter { dataPoint in
            range.contains(dataPoint.date)
        }
        
        return WidgetData(
            title: data.title,
            subtitle: data.subtitle,
            primaryValue: data.primaryValue,
            secondaryValue: data.secondaryValue,
            chartData: filteredChartData,
            color: data.color
        )
    }
    
    /// Filter data by health metric
    private func filterDataByHealthMetric(_ data: WidgetData, metric: HealthMetric) async -> WidgetData {
        // Apply metric-specific filtering logic
        return data
    }
    
    /// Filter data by value range
    private func filterDataByValueRange(_ data: WidgetData, range: ClosedRange<Double>) async -> WidgetData {
        let filteredChartData = data.chartData.filter { dataPoint in
            range.contains(dataPoint.value)
        }
        
        return WidgetData(
            title: data.title,
            subtitle: data.subtitle,
            primaryValue: data.primaryValue,
            secondaryValue: data.secondaryValue,
            chartData: filteredChartData,
            color: data.color
        )
    }
    
    // MARK: - Widget Management
    
    /// Add new widget to dashboard
    func addWidget(type: WidgetType, title: String) {
        let newWidget = DashboardWidget(
            id: UUID().uuidString,
            type: type,
            title: title,
            position: calculateNextPosition(),
            size: CGSize(width: 1, height: 1)
        )
        
        dashboardWidgets.append(newWidget)
        saveDashboardLayout()
    }
    
    /// Remove widget from dashboard
    func removeWidget(id: String) {
        dashboardWidgets.removeAll { $0.id == id }
        saveDashboardLayout()
    }
    
    /// Update widget position and size
    func updateWidget(id: String, position: CGPoint, size: CGSize) {
        if let index = dashboardWidgets.firstIndex(where: { $0.id == id }) {
            dashboardWidgets[index].position = position
            dashboardWidgets[index].size = size
            saveDashboardLayout()
        }
    }
    
    /// Calculate next available position for new widget
    private func calculateNextPosition() -> CGPoint {
        let maxX = dashboardWidgets.map { $0.position.x + $0.size.width }.max() ?? 0
        let maxY = dashboardWidgets.map { $0.position.y + $0.size.height }.max() ?? 0
        
        if maxX >= 4 {
            return CGPoint(x: 0, y: maxY)
        } else {
            return CGPoint(x: maxX, y: maxY)
        }
    }
    
    // MARK: - Export & Sharing
    
    /// Export dashboard as image
    func exportDashboardAsImage() async -> UIImage? {
        // Implementation for dashboard screenshot export
        return nil
    }
    
    /// Export dashboard data as CSV
    func exportDashboardAsCSV() async -> String {
        var csvContent = "Widget,Title,Primary Value,Secondary Value,Date\n"
        
        for widget in dashboardWidgets {
            csvContent += "\(widget.type.rawValue),\(widget.title),\(widget.data.primaryValue),\(widget.data.secondaryValue),\(Date())\n"
        }
        
        return csvContent
    }
    
    /// Export dashboard data as JSON
    func exportDashboardAsJSON() async -> Data? {
        let exportData = DashboardExportData(
            widgets: dashboardWidgets,
            timeRange: selectedTimeRange,
            filters: activeFilters,
            exportDate: Date()
        )
        
        return try? JSONEncoder().encode(exportData)
    }
    
    /// Share dashboard via social media
    func shareDashboard() async {
        // Implementation for social media sharing
    }
    
    // MARK: - Persistence
    
    /// Save dashboard layout
    private func saveDashboardLayout() {
        let layout = DashboardLayout(
            widgets: dashboardWidgets,
            timeRange: selectedTimeRange,
            filters: activeFilters
        )
        
        // Save to UserDefaults or Core Data
        if let data = try? JSONEncoder().encode(layout) {
            UserDefaults.standard.set(data, forKey: "dashboard_layout")
        }
    }
    
    /// Load dashboard layout
    func loadDashboardLayout() {
        guard let data = UserDefaults.standard.data(forKey: "dashboard_layout"),
              let layout = try? JSONDecoder().decode(DashboardLayout.self, from: data) else {
            return
        }
        
        dashboardWidgets = layout.widgets
        selectedTimeRange = layout.timeRange
        activeFilters = layout.filters
    }
}

// MARK: - Supporting Types

/// Dashboard widget configuration
struct DashboardWidget: Identifiable, Codable {
    let id: String
    let type: WidgetType
    var title: String
    var position: CGPoint
    var size: CGSize
    var data: WidgetData = WidgetData.empty
    
    enum CodingKeys: String, CodingKey {
        case id, type, title, position, size
    }
}

/// Widget types
enum WidgetType: String, CaseIterable, Codable {
    case healthOverview = "health_overview"
    case activityTrends = "activity_trends"
    case sleepAnalysis = "sleep_analysis"
    case predictiveInsights = "predictive_insights"
    case custom = "custom"
    
    var displayName: String {
        switch self {
        case .healthOverview: return "Health Overview"
        case .activityTrends: return "Activity Trends"
        case .sleepAnalysis: return "Sleep Analysis"
        case .predictiveInsights: return "Predictive Insights"
        case .custom: return "Custom Widget"
        }
    }
}

/// Widget data structure
struct WidgetData: Codable {
    let title: String
    let subtitle: String
    let primaryValue: Double
    let secondaryValue: Double
    let chartData: [ChartDataPoint]
    let color: Color
    
    static let empty = WidgetData(
        title: "",
        subtitle: "",
        primaryValue: 0,
        secondaryValue: 0,
        chartData: [],
        color: .gray
    )
}

/// Chart data point
struct ChartDataPoint: Codable {
    let date: Date
    let value: Double
    let label: String?
}

/// Time range for analytics
enum TimeRange: String, CaseIterable, Codable {
    case day = "day"
    case week = "week"
    case month = "month"
    case quarter = "quarter"
    case year = "year"
    
    var displayName: String {
        switch self {
        case .day: return "24 Hours"
        case .week: return "7 Days"
        case .month: return "30 Days"
        case .quarter: return "90 Days"
        case .year: return "365 Days"
        }
    }
}

/// Analytics filter
protocol AnalyticsFilter: Codable {
    var type: FilterType { get }
    var name: String { get }
}

enum FilterType: String, Codable {
    case dateRange = "date_range"
    case healthMetric = "health_metric"
    case valueRange = "value_range"
}

/// Date range filter
struct DateRangeFilter: AnalyticsFilter {
    let type: FilterType = .dateRange
    let name: String
    let dateRange: ClosedRange<Date>
}

/// Health metric filter
struct HealthMetricFilter: AnalyticsFilter {
    let type: FilterType = .healthMetric
    let name: String
    let metric: HealthMetric
}

/// Value range filter
struct ValueRangeFilter: AnalyticsFilter {
    let type: FilterType = .valueRange
    let name: String
    let range: ClosedRange<Double>
}

/// Health metric types
enum HealthMetric: String, CaseIterable, Codable {
    case heartRate = "heart_rate"
    case steps = "steps"
    case sleep = "sleep"
    case activity = "activity"
    case weight = "weight"
    case bloodPressure = "blood_pressure"
}

/// Comparison modes
enum ComparisonMode: String, CaseIterable, Codable {
    case none = "none"
    case periodOverPeriod = "period_over_period"
    case goalVsActual = "goal_vs_actual"
    case peerGroup = "peer_group"
    case historical = "historical"
}

/// Predictive insight
struct PredictiveInsight: Identifiable, Codable {
    let id = UUID()
    let type: InsightType
    let title: String
    let description: String
    let confidence: Double
    let timeframe: String
    let action: String?
    
    enum InsightType: String, Codable {
        case healthTrend = "health_trend"
        case riskAssessment = "risk_assessment"
        case goalPrediction = "goal_prediction"
    }
}

/// Dashboard layout
struct DashboardLayout: Codable {
    let widgets: [DashboardWidget]
    let timeRange: TimeRange
    let filters: [AnalyticsFilter]
    
    static let `default` = DashboardLayout(
        widgets: [],
        timeRange: .week,
        filters: []
    )
}

/// Dashboard export data
struct DashboardExportData: Codable {
    let widgets: [DashboardWidget]
    let timeRange: TimeRange
    let filters: [AnalyticsFilter]
    let exportDate: Date
}

// MARK: - Color Extension for Codable
extension Color: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let colorName = try container.decode(String.self)
        
        switch colorName {
        case "red": self = .red
        case "green": self = .green
        case "blue": self = .blue
        case "orange": self = .orange
        case "purple": self = .purple
        case "gray": self = .gray
        default: self = .gray
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        let colorName: String
        switch self {
        case .red: colorName = "red"
        case .green: colorName = "green"
        case .blue: colorName = "blue"
        case .orange: colorName = "orange"
        case .purple: colorName = "purple"
        case .gray: colorName = "gray"
        default: colorName = "gray"
        }
        
        try container.encode(colorName)
    }
}

// MARK: - CGPoint Extension for Codable
extension CGPoint: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let x = try container.decode(CGFloat.self, forKey: .x)
        let y = try container.decode(CGFloat.self, forKey: .y)
        self.init(x: x, y: y)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(x, forKey: .x)
        try container.encode(y, forKey: .y)
    }
    
    private enum CodingKeys: String, CodingKey {
        case x, y
    }
}

// MARK: - CGSize Extension for Codable
extension CGSize: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let width = try container.decode(CGFloat.self, forKey: .width)
        let height = try container.decode(CGFloat.self, forKey: .height)
        self.init(width: width, height: height)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(width, forKey: .width)
        try container.encode(height, forKey: .height)
    }
    
    private enum CodingKeys: String, CodingKey {
        case width, height
    }
} 
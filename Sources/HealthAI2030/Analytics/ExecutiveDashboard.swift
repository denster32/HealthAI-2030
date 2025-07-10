import Foundation
import Combine
import SwiftUI
import Charts

/// Executive dashboard for HealthAI 2030
/// Provides high-level business metrics, KPIs, and strategic insights for executive decision-making
@MainActor
public class ExecutiveDashboard: ObservableObject {
    
    // MARK: - Published Properties
    @Published private(set) var keyMetrics: KeyMetrics = KeyMetrics()
    @Published private(set) var performanceIndicators: [KPI] = []
    @Published private(set) var trendAnalysis: TrendAnalysis = TrendAnalysis()
    @Published private(set) var businessInsights: [BusinessInsight] = []
    @Published private(set) var alertSummary: AlertSummary = AlertSummary()
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var lastUpdated: Date = Date()
    
    // MARK: - Core Components
    private let metricsAggregator: MetricsAggregator
    private let kpiCalculator: KPICalculator
    private let trendAnalyzer: BusinessTrendAnalyzer
    private let insightGenerator: BusinessInsightGenerator
    private let alertManager: ExecutiveAlertManager
    private let forecastEngine: BusinessForecastEngine
    private let benchmarkManager: BenchmarkManager
    private let dataVisualizationEngine: DataVisualizationEngine
    
    // MARK: - Data Sources
    private let healthDataProvider: HealthDataProvider
    private let financialDataProvider: FinancialDataProvider
    private let operationalDataProvider: OperationalDataProvider
    private let qualityDataProvider: QualityDataProvider
    private let userEngagementProvider: UserEngagementProvider
    
    // MARK: - Configuration
    private let dashboardConfig: ExecutiveDashboardConfiguration
    private let refreshInterval: TimeInterval = 300 // 5 minutes
    
    // MARK: - Refresh Timer
    private var refreshTimer: Timer?
    
    // MARK: - Initialization
    public init(config: ExecutiveDashboardConfiguration = .default) {
        self.dashboardConfig = config
        self.metricsAggregator = MetricsAggregator(config: config.metricsConfig)
        self.kpiCalculator = KPICalculator(config: config.kpiConfig)
        self.trendAnalyzer = BusinessTrendAnalyzer(config: config.trendConfig)
        self.insightGenerator = BusinessInsightGenerator(config: config.insightConfig)
        self.alertManager = ExecutiveAlertManager(config: config.alertConfig)
        self.forecastEngine = BusinessForecastEngine(config: config.forecastConfig)
        self.benchmarkManager = BenchmarkManager(config: config.benchmarkConfig)
        self.dataVisualizationEngine = DataVisualizationEngine(config: config.visualizationConfig)
        
        // Initialize data providers
        self.healthDataProvider = HealthDataProvider(config: config.dataProviderConfig)
        self.financialDataProvider = FinancialDataProvider(config: config.dataProviderConfig)
        self.operationalDataProvider = OperationalDataProvider(config: config.dataProviderConfig)
        self.qualityDataProvider = QualityDataProvider(config: config.dataProviderConfig)
        self.userEngagementProvider = UserEngagementProvider(config: config.dataProviderConfig)
        
        setupDashboard()
        startAutoRefresh()
    }
    
    deinit {
        stopAutoRefresh()
    }
    
    // MARK: - Dashboard Refresh Methods
    
    /// Refreshes all dashboard data
    public func refreshDashboard() async {
        isLoading = true
        
        do {
            // Refresh data in parallel for better performance
            async let keyMetricsTask = refreshKeyMetrics()
            async let kpiTask = refreshKPIs()
            async let trendsTask = refreshTrendAnalysis()
            async let insightsTask = refreshBusinessInsights()
            async let alertsTask = refreshAlertSummary()
            
            // Wait for all tasks to complete
            _ = try await (keyMetricsTask, kpiTask, trendsTask, insightsTask, alertsTask)
            
            lastUpdated = Date()
        } catch {
            // Handle refresh errors
            await handleRefreshError(error)
        }
        
        isLoading = false
    }
    
    /// Refreshes key business metrics
    private func refreshKeyMetrics() async throws {
        let timeRange = dashboardConfig.defaultTimeRange
        
        // Collect data from all providers
        async let healthMetrics = healthDataProvider.getMetrics(timeRange: timeRange)
        async let financialMetrics = financialDataProvider.getMetrics(timeRange: timeRange)
        async let operationalMetrics = operationalDataProvider.getMetrics(timeRange: timeRange)
        async let qualityMetrics = qualityDataProvider.getMetrics(timeRange: timeRange)
        async let engagementMetrics = userEngagementProvider.getMetrics(timeRange: timeRange)
        
        let allMetrics = try await (healthMetrics, financialMetrics, operationalMetrics, qualityMetrics, engagementMetrics)
        
        // Aggregate metrics
        let aggregatedMetrics = try await metricsAggregator.aggregate([
            allMetrics.0, allMetrics.1, allMetrics.2, allMetrics.3, allMetrics.4
        ])
        
        keyMetrics = KeyMetrics(
            totalRevenue: aggregatedMetrics.revenue,
            totalUsers: aggregatedMetrics.activeUsers,
            healthOutcomeScore: aggregatedMetrics.healthOutcomeScore,
            customerSatisfaction: aggregatedMetrics.customerSatisfaction,
            operationalEfficiency: aggregatedMetrics.operationalEfficiency,
            costPerOutcome: aggregatedMetrics.costPerOutcome,
            marketShare: aggregatedMetrics.marketShare,
            growthRate: aggregatedMetrics.growthRate,
            profitMargin: aggregatedMetrics.profitMargin,
            timeRange: timeRange
        )
    }
    
    /// Refreshes key performance indicators
    private func refreshKPIs() async throws {
        let rawData = try await collectRawKPIData()
        
        let calculatedKPIs = try await kpiCalculator.calculateKPIs(rawData)
        
        // Add benchmarking
        let benchmarkedKPIs = try await benchmarkManager.addBenchmarks(calculatedKPIs)
        
        performanceIndicators = benchmarkedKPIs.map { kpi in
            KPI(
                id: kpi.id,
                name: kpi.name,
                currentValue: kpi.currentValue,
                targetValue: kpi.targetValue,
                previousValue: kpi.previousValue,
                trend: kpi.trend,
                status: determineKPIStatus(kpi),
                category: kpi.category,
                benchmark: kpi.benchmark,
                lastUpdated: Date()
            )
        }
    }
    
    /// Refreshes trend analysis
    private func refreshTrendAnalysis() async throws {
        let historicalData = try await collectHistoricalData()
        
        let trends = try await trendAnalyzer.analyzeTrends(historicalData)
        
        // Generate forecasts
        let forecasts = try await forecastEngine.generateForecasts(
            basedOn: trends,
            forecastPeriod: dashboardConfig.forecastPeriod
        )
        
        trendAnalysis = TrendAnalysis(
            revenueGrowthTrend: trends.revenueGrowth,
            userGrowthTrend: trends.userGrowth,
            healthOutcomeTrend: trends.healthOutcome,
            operationalEfficiencyTrend: trends.operationalEfficiency,
            customerSatisfactionTrend: trends.customerSatisfaction,
            forecasts: forecasts,
            seasonalPatterns: trends.seasonalPatterns,
            anomalies: trends.anomalies
        )
    }
    
    /// Refreshes business insights
    private func refreshBusinessInsights() async throws {
        let contextData = try await collectInsightContextData()
        
        let generatedInsights = try await insightGenerator.generateInsights(contextData)
        
        // Prioritize insights based on business impact
        let prioritizedInsights = prioritizeInsights(generatedInsights)
        
        businessInsights = prioritizedInsights.prefix(dashboardConfig.maxInsights).map { insight in
            BusinessInsight(
                id: insight.id,
                title: insight.title,
                description: insight.description,
                category: insight.category,
                priority: insight.priority,
                confidence: insight.confidence,
                recommendation: insight.recommendation,
                expectedImpact: insight.expectedImpact,
                timeframe: insight.timeframe,
                generatedAt: Date()
            )
        }
    }
    
    /// Refreshes alert summary
    private func refreshAlertSummary() async throws {
        let alerts = try await alertManager.getExecutiveAlerts()
        
        alertSummary = AlertSummary(
            criticalAlerts: alerts.filter { $0.severity == .critical }.count,
            warningAlerts: alerts.filter { $0.severity == .warning }.count,
            infoAlerts: alerts.filter { $0.severity == .info }.count,
            totalAlerts: alerts.count,
            topCriticalAlert: alerts.filter { $0.severity == .critical }.first,
            recentAlerts: Array(alerts.prefix(5)),
            alertTrends: try await analyzeAlertTrends(alerts)
        )
    }
    
    // MARK: - Data Visualization Methods
    
    /// Gets revenue chart data
    public func getRevenueChartData(period: TimePeriod = .last12Months) async -> ChartData {
        do {
            let revenueData = try await financialDataProvider.getRevenueData(period: period)
            return await dataVisualizationEngine.createRevenueChart(revenueData)
        } catch {
            return ChartData.empty()
        }
    }
    
    /// Gets user growth chart data
    public func getUserGrowthChartData(period: TimePeriod = .last12Months) async -> ChartData {
        do {
            let userGrowthData = try await userEngagementProvider.getUserGrowthData(period: period)
            return await dataVisualizationEngine.createUserGrowthChart(userGrowthData)
        } catch {
            return ChartData.empty()
        }
    }
    
    /// Gets health outcome trends chart data
    public func getHealthOutcomeTrendsChartData(period: TimePeriod = .last12Months) async -> ChartData {
        do {
            let healthOutcomeData = try await healthDataProvider.getHealthOutcomeData(period: period)
            return await dataVisualizationEngine.createHealthOutcomeChart(healthOutcomeData)
        } catch {
            return ChartData.empty()
        }
    }
    
    /// Gets operational efficiency chart data
    public func getOperationalEfficiencyChartData(period: TimePeriod = .last12Months) async -> ChartData {
        do {
            let operationalData = try await operationalDataProvider.getEfficiencyData(period: period)
            return await dataVisualizationEngine.createOperationalEfficiencyChart(operationalData)
        } catch {
            return ChartData.empty()
        }
    }
    
    // MARK: - Business Intelligence Methods
    
    /// Gets financial performance summary
    public func getFinancialPerformanceSummary() async -> FinancialPerformanceSummary {
        do {
            let financialData = try await financialDataProvider.getComprehensiveFinancialData()
            let performanceSummary = try await metricsAggregator.generateFinancialSummary(financialData)
            
            return FinancialPerformanceSummary(
                revenue: performanceSummary.revenue,
                costs: performanceSummary.costs,
                profit: performanceSummary.profit,
                margins: performanceSummary.margins,
                roi: performanceSummary.roi,
                cashFlow: performanceSummary.cashFlow,
                burn_rate: performanceSummary.burnRate,
                runway: performanceSummary.runway,
                profitability: performanceSummary.profitability
            )
        } catch {
            return FinancialPerformanceSummary.empty()
        }
    }
    
    /// Gets operational performance summary
    public func getOperationalPerformanceSummary() async -> OperationalPerformanceSummary {
        do {
            let operationalData = try await operationalDataProvider.getComprehensiveOperationalData()
            let performanceSummary = try await metricsAggregator.generateOperationalSummary(operationalData)
            
            return OperationalPerformanceSummary(
                efficiency: performanceSummary.efficiency,
                utilization: performanceSummary.utilization,
                throughput: performanceSummary.throughput,
                quality: performanceSummary.quality,
                reliability: performanceSummary.reliability,
                scalability: performanceSummary.scalability,
                automation: performanceSummary.automation,
                optimization: performanceSummary.optimization
            )
        } catch {
            return OperationalPerformanceSummary.empty()
        }
    }
    
    /// Gets market positioning analysis
    public func getMarketPositioningAnalysis() async -> MarketPositioningAnalysis {
        do {
            let marketData = try await collectMarketData()
            let competitorData = try await collectCompetitorData()
            
            let positioning = try await analyzeMarketPositioning(marketData: marketData, competitorData: competitorData)
            
            return MarketPositioningAnalysis(
                marketShare: positioning.marketShare,
                competitivePosition: positioning.competitivePosition,
                growthOpportunities: positioning.growthOpportunities,
                threats: positioning.threats,
                strengths: positioning.strengths,
                weaknesses: positioning.weaknesses,
                recommendations: positioning.recommendations
            )
        } catch {
            return MarketPositioningAnalysis.empty()
        }
    }
    
    // MARK: - Alert and Notification Methods
    
    /// Gets critical business alerts
    public func getCriticalBusinessAlerts() async -> [BusinessAlert] {
        do {
            return try await alertManager.getCriticalAlerts()
        } catch {
            return []
        }
    }
    
    /// Acknowledges a business alert
    public func acknowledgeAlert(alertId: String) async throws {
        try await alertManager.acknowledgeAlert(alertId)
        await refreshAlertSummary()
    }
    
    // MARK: - Export and Reporting Methods
    
    /// Exports dashboard data to PDF report
    public func exportToPDF() async throws -> Data {
        let reportData = DashboardReportData(
            keyMetrics: keyMetrics,
            performanceIndicators: performanceIndicators,
            trendAnalysis: trendAnalysis,
            businessInsights: businessInsights,
            alertSummary: alertSummary,
            generatedAt: Date()
        )
        
        return try await generatePDFReport(reportData)
    }
    
    /// Exports dashboard data to Excel
    public func exportToExcel() async throws -> Data {
        let reportData = DashboardReportData(
            keyMetrics: keyMetrics,
            performanceIndicators: performanceIndicators,
            trendAnalysis: trendAnalysis,
            businessInsights: businessInsights,
            alertSummary: alertSummary,
            generatedAt: Date()
        )
        
        return try await generateExcelReport(reportData)
    }
    
    /// Generates executive summary report
    public func generateExecutiveSummaryReport() async throws -> ExecutiveSummaryReport {
        let financialSummary = await getFinancialPerformanceSummary()
        let operationalSummary = await getOperationalPerformanceSummary()
        let marketPositioning = await getMarketPositioningAnalysis()
        
        return ExecutiveSummaryReport(
            executiveSummary: generateExecutiveSummary(),
            keyHighlights: extractKeyHighlights(),
            financialPerformance: financialSummary,
            operationalPerformance: operationalSummary,
            marketPositioning: marketPositioning,
            strategicRecommendations: generateStrategicRecommendations(),
            riskAssessment: await generateRiskAssessment(),
            nextSteps: generateNextSteps(),
            generatedAt: Date()
        )
    }
    
    // MARK: - Private Implementation Methods
    
    private func setupDashboard() {
        // Configure dashboard components
        metricsAggregator.delegate = self
        kpiCalculator.delegate = self
        trendAnalyzer.delegate = self
        insightGenerator.delegate = self
        alertManager.delegate = self
        
        // Setup data provider delegates
        healthDataProvider.delegate = self
        financialDataProvider.delegate = self
        operationalDataProvider.delegate = self
        qualityDataProvider.delegate = self
        userEngagementProvider.delegate = self
    }
    
    private func startAutoRefresh() {
        refreshTimer = Timer.scheduledTimer(withTimeInterval: refreshInterval, repeats: true) { _ in
            Task {
                await self.refreshDashboard()
            }
        }
    }
    
    private func stopAutoRefresh() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }
    
    private func handleRefreshError(_ error: Error) async {
        // Handle dashboard refresh errors
        print("Dashboard refresh error: \(error.localizedDescription)")
        
        // Create error alert
        let errorAlert = BusinessAlert(
            id: UUID().uuidString,
            title: "Dashboard Refresh Error",
            message: "Failed to refresh dashboard data: \(error.localizedDescription)",
            severity: .warning,
            category: .system,
            timestamp: Date()
        )
        
        try? await alertManager.addAlert(errorAlert)
    }
    
    private func collectRawKPIData() async throws -> KPIRawData {
        async let healthData = healthDataProvider.getRawData()
        async let financialData = financialDataProvider.getRawData()
        async let operationalData = operationalDataProvider.getRawData()
        async let qualityData = qualityDataProvider.getRawData()
        async let engagementData = userEngagementProvider.getRawData()
        
        let allData = try await (healthData, financialData, operationalData, qualityData, engagementData)
        
        return KPIRawData(
            health: allData.0,
            financial: allData.1,
            operational: allData.2,
            quality: allData.3,
            engagement: allData.4
        )
    }
    
    private func collectHistoricalData() async throws -> HistoricalData {
        let timeRange = TimeRange.lastYear
        
        async let healthHistory = healthDataProvider.getHistoricalData(timeRange: timeRange)
        async let financialHistory = financialDataProvider.getHistoricalData(timeRange: timeRange)
        async let operationalHistory = operationalDataProvider.getHistoricalData(timeRange: timeRange)
        async let qualityHistory = qualityDataProvider.getHistoricalData(timeRange: timeRange)
        async let engagementHistory = userEngagementProvider.getHistoricalData(timeRange: timeRange)
        
        let allHistory = try await (healthHistory, financialHistory, operationalHistory, qualityHistory, engagementHistory)
        
        return HistoricalData(
            health: allHistory.0,
            financial: allHistory.1,
            operational: allHistory.2,
            quality: allHistory.3,
            engagement: allHistory.4,
            timeRange: timeRange
        )
    }
    
    private func collectInsightContextData() async throws -> InsightContextData {
        let currentMetrics = keyMetrics
        let currentKPIs = performanceIndicators
        let currentTrends = trendAnalysis
        let marketData = try await collectMarketData()
        let competitorData = try await collectCompetitorData()
        
        return InsightContextData(
            metrics: currentMetrics,
            kpis: currentKPIs,
            trends: currentTrends,
            market: marketData,
            competitors: competitorData,
            timestamp: Date()
        )
    }
    
    private func collectMarketData() async throws -> MarketData {
        // Collect market data from external sources
        // This would integrate with market research APIs, industry reports, etc.
        return MarketData(
            marketSize: 0, // Placeholder
            growthRate: 0, // Placeholder
            segments: [], // Placeholder
            trends: [] // Placeholder
        )
    }
    
    private func collectCompetitorData() async throws -> CompetitorData {
        // Collect competitor data from external sources
        // This would integrate with competitive intelligence tools
        return CompetitorData(
            competitors: [], // Placeholder
            analysis: CompetitiveAnalysis() // Placeholder
        )
    }
    
    private func determineKPIStatus(_ kpi: CalculatedKPI) -> KPIStatus {
        let achievement = kpi.currentValue / kpi.targetValue
        
        switch achievement {
        case 0.95...:
            return .onTrack
        case 0.8..<0.95:
            return .atRisk
        default:
            return .offTrack
        }
    }
    
    private func prioritizeInsights(_ insights: [GeneratedInsight]) -> [GeneratedInsight] {
        return insights.sorted { insight1, insight2 in
            // Prioritize by business impact and confidence
            let score1 = insight1.expectedImpact * insight1.confidence
            let score2 = insight2.expectedImpact * insight2.confidence
            
            return score1 > score2
        }
    }
    
    private func analyzeAlertTrends(_ alerts: [ExecutiveAlert]) async throws -> AlertTrends {
        let last30Days = alerts.filter { 
            Date().timeIntervalSince($0.timestamp) <= 30 * 24 * 3600 
        }
        
        return AlertTrends(
            totalCount: last30Days.count,
            criticalCount: last30Days.filter { $0.severity == .critical }.count,
            warningCount: last30Days.filter { $0.severity == .warning }.count,
            dailyAverage: Double(last30Days.count) / 30.0,
            trend: calculateAlertTrend(last30Days)
        )
    }
    
    private func calculateAlertTrend(_ alerts: [ExecutiveAlert]) -> TrendDirection {
        // Calculate alert trend over time
        let recentAlerts = alerts.filter { 
            Date().timeIntervalSince($0.timestamp) <= 7 * 24 * 3600 
        }
        let previousAlerts = alerts.filter { 
            let interval = Date().timeIntervalSince($0.timestamp)
            return interval > 7 * 24 * 3600 && interval <= 14 * 24 * 3600
        }
        
        if recentAlerts.count > previousAlerts.count {
            return .increasing
        } else if recentAlerts.count < previousAlerts.count {
            return .decreasing
        } else {
            return .stable
        }
    }
    
    private func analyzeMarketPositioning(marketData: MarketData, competitorData: CompetitorData) async throws -> MarketPositioning {
        // Analyze market positioning based on available data
        return MarketPositioning(
            marketShare: 0.0, // Placeholder
            competitivePosition: .follower, // Placeholder
            growthOpportunities: [], // Placeholder
            threats: [], // Placeholder
            strengths: [], // Placeholder
            weaknesses: [], // Placeholder
            recommendations: [] // Placeholder
        )
    }
    
    private func generatePDFReport(_ data: DashboardReportData) async throws -> Data {
        // Generate PDF report from dashboard data
        // This would use a PDF generation library
        return Data() // Placeholder
    }
    
    private func generateExcelReport(_ data: DashboardReportData) async throws -> Data {
        // Generate Excel report from dashboard data
        // This would use an Excel generation library
        return Data() // Placeholder
    }
    
    private func generateExecutiveSummary() -> String {
        // Generate executive summary based on current metrics and insights
        return "Executive summary placeholder"
    }
    
    private func extractKeyHighlights() -> [String] {
        // Extract key highlights from current data
        var highlights: [String] = []
        
        // Add metric-based highlights
        if keyMetrics.growthRate > 0.2 {
            highlights.append("Strong growth rate of \(String(format: "%.1f", keyMetrics.growthRate * 100))%")
        }
        
        // Add KPI-based highlights
        let onTrackKPIs = performanceIndicators.filter { $0.status == .onTrack }
        if !onTrackKPIs.isEmpty {
            highlights.append("\(onTrackKPIs.count) KPIs are on track")
        }
        
        // Add insight-based highlights
        let highImpactInsights = businessInsights.filter { $0.expectedImpact > 0.8 }
        if !highImpactInsights.isEmpty {
            highlights.append("\(highImpactInsights.count) high-impact opportunities identified")
        }
        
        return highlights
    }
    
    private func generateStrategicRecommendations() -> [StrategicRecommendation] {
        // Generate strategic recommendations based on analysis
        var recommendations: [StrategicRecommendation] = []
        
        // Add recommendations based on KPI performance
        let underperformingKPIs = performanceIndicators.filter { $0.status == .offTrack }
        if !underperformingKPIs.isEmpty {
            recommendations.append(StrategicRecommendation(
                title: "Address Underperforming KPIs",
                description: "Focus on improving \(underperformingKPIs.count) underperforming KPIs",
                priority: .high,
                timeframe: .immediate,
                expectedImpact: .high
            ))
        }
        
        // Add recommendations based on insights
        for insight in businessInsights.prefix(3) {
            if let recommendation = insight.recommendation {
                recommendations.append(StrategicRecommendation(
                    title: insight.title,
                    description: recommendation,
                    priority: insight.priority,
                    timeframe: insight.timeframe,
                    expectedImpact: .medium
                ))
            }
        }
        
        return recommendations
    }
    
    private func generateRiskAssessment() async -> RiskAssessment {
        // Generate comprehensive risk assessment
        return RiskAssessment(
            overallRiskLevel: .medium, // Placeholder
            specificRisks: [], // Placeholder
            mitigationStrategies: [], // Placeholder
            contingencyPlans: [] // Placeholder
        )
    }
    
    private func generateNextSteps() -> [NextStep] {
        // Generate next steps based on current state and recommendations
        return [
            NextStep(
                action: "Review underperforming KPIs",
                owner: "Executive Team",
                deadline: Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date(),
                priority: .high
            ),
            NextStep(
                action: "Implement top business insight recommendations",
                owner: "Strategic Planning",
                deadline: Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date(),
                priority: .medium
            )
        ]
    }
}

// MARK: - Supporting Types

public struct KeyMetrics {
    public let totalRevenue: Double
    public let totalUsers: Int
    public let healthOutcomeScore: Double
    public let customerSatisfaction: Double
    public let operationalEfficiency: Double
    public let costPerOutcome: Double
    public let marketShare: Double
    public let growthRate: Double
    public let profitMargin: Double
    public let timeRange: TimeRange
    
    public init() {
        self.totalRevenue = 0
        self.totalUsers = 0
        self.healthOutcomeScore = 0
        self.customerSatisfaction = 0
        self.operationalEfficiency = 0
        self.costPerOutcome = 0
        self.marketShare = 0
        self.growthRate = 0
        self.profitMargin = 0
        self.timeRange = .last30Days
    }
    
    public init(totalRevenue: Double, totalUsers: Int, healthOutcomeScore: Double, 
                customerSatisfaction: Double, operationalEfficiency: Double, 
                costPerOutcome: Double, marketShare: Double, growthRate: Double, 
                profitMargin: Double, timeRange: TimeRange) {
        self.totalRevenue = totalRevenue
        self.totalUsers = totalUsers
        self.healthOutcomeScore = healthOutcomeScore
        self.customerSatisfaction = customerSatisfaction
        self.operationalEfficiency = operationalEfficiency
        self.costPerOutcome = costPerOutcome
        self.marketShare = marketShare
        self.growthRate = growthRate
        self.profitMargin = profitMargin
        self.timeRange = timeRange
    }
}

public struct KPI {
    public let id: String
    public let name: String
    public let currentValue: Double
    public let targetValue: Double
    public let previousValue: Double
    public let trend: TrendDirection
    public let status: KPIStatus
    public let category: KPICategory
    public let benchmark: Benchmark?
    public let lastUpdated: Date
}

public enum KPIStatus {
    case onTrack
    case atRisk
    case offTrack
}

public enum KPICategory {
    case financial
    case operational
    case quality
    case customer
    case growth
}

public struct AlertSummary {
    public let criticalAlerts: Int
    public let warningAlerts: Int
    public let infoAlerts: Int
    public let totalAlerts: Int
    public let topCriticalAlert: ExecutiveAlert?
    public let recentAlerts: [ExecutiveAlert]
    public let alertTrends: AlertTrends
    
    public init() {
        self.criticalAlerts = 0
        self.warningAlerts = 0
        self.infoAlerts = 0
        self.totalAlerts = 0
        self.topCriticalAlert = nil
        self.recentAlerts = []
        self.alertTrends = AlertTrends()
    }
    
    public init(criticalAlerts: Int, warningAlerts: Int, infoAlerts: Int, 
                totalAlerts: Int, topCriticalAlert: ExecutiveAlert?, 
                recentAlerts: [ExecutiveAlert], alertTrends: AlertTrends) {
        self.criticalAlerts = criticalAlerts
        self.warningAlerts = warningAlerts
        self.infoAlerts = infoAlerts
        self.totalAlerts = totalAlerts
        self.topCriticalAlert = topCriticalAlert
        self.recentAlerts = recentAlerts
        self.alertTrends = alertTrends
    }
}

// MARK: - Protocol Conformances

extension ExecutiveDashboard: MetricsAggregatorDelegate,
                              KPICalculatorDelegate,
                              BusinessTrendAnalyzerDelegate,
                              BusinessInsightGeneratorDelegate,
                              ExecutiveAlertManagerDelegate,
                              DataProviderDelegate {
    
    public func metricsUpdated() {
        Task {
            await refreshKeyMetrics()
        }
    }
    
    public func kpisCalculated() {
        Task {
            try? await refreshKPIs()
        }
    }
    
    public func trendsAnalyzed() {
        Task {
            try? await refreshTrendAnalysis()
        }
    }
    
    public func insightsGenerated() {
        Task {
            try? await refreshBusinessInsights()
        }
    }
    
    public func alertReceived(_ alert: ExecutiveAlert) {
        Task {
            try? await refreshAlertSummary()
        }
    }
    
    public func dataProviderUpdated(_ provider: String) {
        Task {
            await refreshDashboard()
        }
    }
}

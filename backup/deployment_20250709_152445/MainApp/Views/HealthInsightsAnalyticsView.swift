import SwiftUI
import Charts

/// Comprehensive health insights and analytics view for HealthAI 2030
/// Provides complete interface for viewing health insights, trends, predictions, and recommendations
struct HealthInsightsAnalyticsView: View {
    @StateObject private var analyticsEngine = HealthInsightsAnalyticsEngine.shared
    @State private var selectedTab = 0
    @State private var showingExportSheet = false
    @State private var exportData: Data?
    @State private var selectedInsight: HealthInsightsAnalyticsEngine.HealthInsight?
    @State private var showingInsightDetail = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header with analytics status
                analyticsHeader
                
                // Tab selection
                Picker("Analytics", selection: $selectedTab) {
                    Text("Overview").tag(0)
                    Text("Insights").tag(1)
                    Text("Trends").tag(2)
                    Text("Predictions").tag(3)
                    Text("Recommendations").tag(4)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                // Content based on selected tab
                TabView(selection: $selectedTab) {
                    overviewTab
                        .tag(0)
                    
                    insightsTab
                        .tag(1)
                    
                    trendsTab
                        .tag(2)
                    
                    predictionsTab
                        .tag(3)
                    
                    recommendationsTab
                        .tag(4)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .navigationTitle("Health Analytics")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Run Analysis") {
                            Task {
                                await analyticsEngine.performAnalysis()
                            }
                        }
                        Button("Export Data") {
                            exportAnalyticsData()
                        }
                        Button("Refresh") {
                            Task {
                                await analyticsEngine.performAnalysis()
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $showingExportSheet) {
                if let data = exportData {
                    ShareSheet(items: [data])
                }
            }
            .sheet(isPresented: $showingInsightDetail) {
                if let insight = selectedInsight {
                    InsightDetailView(insight: insight)
                }
            }
            .onAppear {
                Task {
                    await analyticsEngine.initialize()
                }
            }
        }
    }
    
    // MARK: - Header
    
    private var analyticsHeader: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Health Analytics")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    if let lastAnalysis = analyticsEngine.lastAnalysisDate {
                        Text("Last analysis: \(lastAnalysis.formatted(date: .abbreviated, time: .shortened))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Analytics status badge
                HStack {
                    Circle()
                        .fill(Color(analyticsEngine.analyticsStatus.color))
                        .frame(width: 12, height: 12)
                    
                    Text(analyticsEngine.analyticsStatus.rawValue)
                        .font(.caption)
                        .fontWeight(.semibold)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color(.systemGray6))
                .cornerRadius(16)
            }
            
            // Quick stats
            let summary = analyticsEngine.getAnalyticsSummary()
            HStack(spacing: 20) {
                StatCard(
                    title: "Insights",
                    value: "\(summary.totalInsights)",
                    subtitle: "\(summary.actionableInsights) actionable",
                    color: .blue
                )
                
                StatCard(
                    title: "Trends",
                    value: "\(summary.improvingTrends)",
                    subtitle: "improving",
                    color: .green
                )
                
                StatCard(
                    title: "Predictions",
                    value: "\(summary.highConfidencePredictions)",
                    subtitle: "high confidence",
                    color: .purple
                )
                
                StatCard(
                    title: "Recommendations",
                    value: "\(summary.criticalRecommendations)",
                    subtitle: "critical",
                    color: .red
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
                // Analytics summary
                AnalyticsSummaryCard()
                
                // Key insights
                KeyInsightsCard()
                
                // Recent trends
                RecentTrendsCard()
                
                // Quick actions
                QuickActionsCard()
            }
            .padding()
        }
    }
    
    // MARK: - Insights Tab
    
    private var insightsTab: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                if analyticsEngine.insights.isEmpty {
                    emptyStateView(
                        icon: "lightbulb",
                        title: "No Insights Yet",
                        message: "Run analysis to generate health insights."
                    )
                } else {
                    ForEach(HealthInsightsAnalyticsEngine.InsightCategory.allCases, id: \.self) { category in
                        let categoryInsights = analyticsEngine.getInsights(for: category)
                        if !categoryInsights.isEmpty {
                            InsightCategorySection(category: category, insights: categoryInsights) { insight in
                                selectedInsight = insight
                                showingInsightDetail = true
                            }
                        }
                    }
                }
            }
            .padding()
        }
    }
    
    // MARK: - Trends Tab
    
    private var trendsTab: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                if analyticsEngine.trends.isEmpty {
                    emptyStateView(
                        icon: "chart.line.uptrend.xyaxis",
                        title: "No Trends Yet",
                        message: "Run analysis to identify health trends."
                    )
                } else {
                    ForEach(HealthInsightsAnalyticsEngine.TrendDirection.allCases, id: \.self) { direction in
                        let directionTrends = analyticsEngine.getTrends(for: direction)
                        if !directionTrends.isEmpty {
                            TrendDirectionSection(direction: direction, trends: directionTrends)
                        }
                    }
                }
            }
            .padding()
        }
    }
    
    // MARK: - Predictions Tab
    
    private var predictionsTab: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                if analyticsEngine.predictions.isEmpty {
                    emptyStateView(
                        icon: "crystal.ball",
                        title: "No Predictions Yet",
                        message: "Run analysis to generate health predictions."
                    )
                } else {
                    ForEach(HealthInsightsAnalyticsEngine.PredictionConfidence.allCases, id: \.self) { confidence in
                        let confidencePredictions = analyticsEngine.getPredictions(withConfidence: confidence)
                        if !confidencePredictions.isEmpty {
                            PredictionConfidenceSection(confidence: confidence, predictions: confidencePredictions)
                        }
                    }
                }
            }
            .padding()
        }
    }
    
    // MARK: - Recommendations Tab
    
    private var recommendationsTab: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                if analyticsEngine.recommendations.isEmpty {
                    emptyStateView(
                        icon: "list.bullet",
                        title: "No Recommendations Yet",
                        message: "Run analysis to generate health recommendations."
                    )
                } else {
                    ForEach(HealthInsightsAnalyticsEngine.RecommendationCategory.allCases, id: \.self) { category in
                        let categoryRecommendations = analyticsEngine.getRecommendations(for: category)
                        if !categoryRecommendations.isEmpty {
                            RecommendationCategorySection(category: category, recommendations: categoryRecommendations)
                        }
                    }
                }
            }
            .padding()
        }
    }
    
    // MARK: - Helper Views
    
    private func emptyStateView(icon: String, title: String, message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
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
    
    private func exportAnalyticsData() {
        exportData = analyticsEngine.exportAnalyticsData()
        showingExportSheet = true
    }
}

// MARK: - Supporting Views

struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
            
            Text(subtitle)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
}

struct AnalyticsSummaryCard: View {
    @StateObject private var analyticsEngine = HealthInsightsAnalyticsEngine.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Analytics Summary")
                .font(.headline)
                .fontWeight(.semibold)
            
            let summary = analyticsEngine.getAnalyticsSummary()
            
            VStack(spacing: 12) {
                SummaryRow(
                    label: "Total Insights",
                    value: "\(summary.totalInsights)",
                    percentage: summary.insightsActionabilityRate,
                    color: .blue
                )
                
                SummaryRow(
                    label: "Improving Trends",
                    value: "\(summary.improvingTrends)",
                    percentage: summary.trendImprovementRate,
                    color: .green
                )
                
                SummaryRow(
                    label: "High Confidence Predictions",
                    value: "\(summary.highConfidencePredictions)",
                    percentage: nil,
                    color: .purple
                )
                
                SummaryRow(
                    label: "Critical Recommendations",
                    value: "\(summary.criticalRecommendations)",
                    percentage: nil,
                    color: .red
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

struct SummaryRow: View {
    let label: String
    let value: String
    let percentage: Double?
    let color: Color
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(color)
                
                if let percentage = percentage {
                    Text("\(Int(percentage * 100))%")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

struct KeyInsightsCard: View {
    @StateObject private var analyticsEngine = HealthInsightsAnalyticsEngine.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Key Insights")
                .font(.headline)
                .fontWeight(.semibold)
            
            let keyInsights = analyticsEngine.insights.prefix(3)
            
            if keyInsights.isEmpty {
                Text("Run analysis to generate insights")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else {
                ForEach(Array(keyInsights), id: \.id) { insight in
                    KeyInsightRow(insight: insight)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

struct KeyInsightRow: View {
    let insight: HealthInsightsAnalyticsEngine.HealthInsight
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: insight.category.icon)
                .foregroundColor(categoryColor)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(insight.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(insight.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(insight.value, specifier: "%.1f")")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(categoryColor)
                
                Text(insight.unit)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
    
    private var categoryColor: Color {
        switch insight.category {
        case .trends: return .blue
        case .anomalies: return .orange
        case .correlations: return .green
        case .patterns: return .purple
        case .improvements: return .green
        case .warnings: return .red
        }
    }
}

struct RecentTrendsCard: View {
    @StateObject private var analyticsEngine = HealthInsightsAnalyticsEngine.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Trends")
                .font(.headline)
                .fontWeight(.semibold)
            
            let recentTrends = analyticsEngine.trends.prefix(3)
            
            if recentTrends.isEmpty {
                Text("Run analysis to identify trends")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else {
                ForEach(Array(recentTrends), id: \.id) { trend in
                    TrendRow(trend: trend)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

struct TrendRow: View {
    let trend: HealthInsightsAnalyticsEngine.HealthTrend
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: trend.direction == .improving ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                .foregroundColor(Color(trend.direction.color))
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(trend.dataType)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(trend.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(trend.changePercentage, specifier: "%.1f")%")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(Color(trend.direction.color))
                
                Text(trend.direction.rawValue)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct QuickActionsCard: View {
    @StateObject private var analyticsEngine = HealthInsightsAnalyticsEngine.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Actions")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                QuickActionButton(
                    icon: "chart.bar.fill",
                    title: "Run Analysis",
                    color: .blue
                ) {
                    Task {
                        await analyticsEngine.performAnalysis()
                    }
                }
                
                QuickActionButton(
                    icon: "lightbulb.fill",
                    title: "View Insights",
                    color: .orange
                ) {
                    // Switch to insights tab
                }
                
                QuickActionButton(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Check Trends",
                    color: .green
                ) {
                    // Switch to trends tab
                }
                
                QuickActionButton(
                    icon: "list.bullet",
                    title: "Recommendations",
                    color: .purple
                ) {
                    // Switch to recommendations tab
                }
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
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
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

struct InsightCategorySection: View {
    let category: HealthInsightsAnalyticsEngine.InsightCategory
    let insights: [HealthInsightsAnalyticsEngine.HealthInsight]
    let onInsightTap: (HealthInsightsAnalyticsEngine.HealthInsight) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: category.icon)
                    .foregroundColor(categoryColor)
                
                Text(category.rawValue)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("\(insights.count)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(categoryColor)
            }
            
            ForEach(insights, id: \.id) { insight in
                InsightCard(insight: insight) {
                    onInsightTap(insight)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
    
    private var categoryColor: Color {
        switch category {
        case .trends: return .blue
        case .anomalies: return .orange
        case .correlations: return .green
        case .patterns: return .purple
        case .improvements: return .green
        case .warnings: return .red
        }
    }
}

struct InsightCard: View {
    let insight: HealthInsightsAnalyticsEngine.HealthInsight
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(insight.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text("\(insight.value, specifier: "%.1f") \(insight.unit)")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(categoryColor)
                }
                
                Text(insight.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                if insight.actionable {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                        
                        Text("Actionable")
                            .font(.caption)
                            .foregroundColor(.green)
                        
                        Spacer()
                        
                        Text("\(Int(insight.confidence * 100))% confidence")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var categoryColor: Color {
        switch insight.category {
        case .trends: return .blue
        case .anomalies: return .orange
        case .correlations: return .green
        case .patterns: return .purple
        case .improvements: return .green
        case .warnings: return .red
        }
    }
}

struct TrendDirectionSection: View {
    let direction: HealthInsightsAnalyticsEngine.TrendDirection
    let trends: [HealthInsightsAnalyticsEngine.HealthTrend]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: direction == .improving ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                    .foregroundColor(Color(direction.color))
                
                Text(direction.rawValue)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("\(trends.count)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(Color(direction.color))
            }
            
            ForEach(trends, id: \.id) { trend in
                TrendCard(trend: trend)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

struct TrendCard: View {
    let trend: HealthInsightsAnalyticsEngine.HealthTrend
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(trend.dataType)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text("\(trend.changePercentage, specifier: "%.1f")%")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(Color(trend.direction.color))
            }
            
            Text(trend.description)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)
            
            // Simple chart representation
            if trend.dataPoints.count > 1 {
                Chart {
                    ForEach(Array(trend.dataPoints.enumerated()), id: \.offset) { index, point in
                        LineMark(
                            x: .value("Date", point.date),
                            y: .value("Value", point.value)
                        )
                        .foregroundStyle(Color(trend.direction.color))
                    }
                }
                .frame(height: 60)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

struct PredictionConfidenceSection: View {
    let confidence: HealthInsightsAnalyticsEngine.PredictionConfidence
    let predictions: [HealthInsightsAnalyticsEngine.HealthPrediction]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "crystal.ball")
                    .foregroundColor(confidenceColor)
                
                Text("\(confidence.rawValue) Confidence")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("\(predictions.count)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(confidenceColor)
            }
            
            ForEach(predictions, id: \.id) { prediction in
                PredictionCard(prediction: prediction)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
    
    private var confidenceColor: Color {
        switch confidence {
        case .low: return .gray
        case .medium: return .orange
        case .high: return .blue
        case .veryHigh: return .green
        }
    }
}

struct PredictionCard: View {
    let prediction: HealthInsightsAnalyticsEngine.HealthPrediction
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(prediction.dataType)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text("\(prediction.predictedValue, specifier: "%.1f") \(prediction.unit)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(confidenceColor)
            }
            
            Text(prediction.description)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)
            
            if !prediction.factors.isEmpty {
                Text("Factors: \(prediction.factors.joined(separator: ", "))")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
    
    private var confidenceColor: Color {
        switch prediction.confidence {
        case .low: return .gray
        case .medium: return .orange
        case .high: return .blue
        case .veryHigh: return .green
        }
    }
}

struct RecommendationCategorySection: View {
    let category: HealthInsightsAnalyticsEngine.RecommendationCategory
    let recommendations: [HealthInsightsAnalyticsEngine.HealthRecommendation]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: category.icon)
                    .foregroundColor(categoryColor)
                
                Text(category.rawValue)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("\(recommendations.count)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(categoryColor)
            }
            
            ForEach(recommendations, id: \.id) { recommendation in
                RecommendationCard(recommendation: recommendation)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
    
    private var categoryColor: Color {
        switch category {
        case .exercise: return .blue
        case .nutrition: return .green
        case .sleep: return .purple
        case .stress: return .orange
        case .monitoring: return .red
        case .lifestyle: return .gray
        }
    }
}

struct RecommendationCard: View {
    let recommendation: HealthInsightsAnalyticsEngine.HealthRecommendation
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(recommendation.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                PriorityBadge(priority: recommendation.priority)
            }
            
            Text(recommendation.description)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)
            
            if !recommendation.steps.isEmpty {
                Text("Steps: \(recommendation.steps.joined(separator: ", "))")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Text(recommendation.difficulty.rawValue)
                    .font(.caption2)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(.systemGray5))
                    .cornerRadius(4)
                
                Spacer()
                
                if recommendation.timeToImplement > 0 {
                    Text("\(Int(recommendation.timeToImplement / 3600))h")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

struct PriorityBadge: View {
    let priority: HealthInsightsAnalyticsEngine.RecommendationPriority
    
    var body: some View {
        Text(priority.rawValue)
            .font(.caption2)
            .fontWeight(.semibold)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color(priority.color).opacity(0.2))
            .foregroundColor(Color(priority.color))
            .cornerRadius(8)
    }
}

// MARK: - Sheet Views

struct InsightDetailView: View {
    let insight: HealthInsightsAnalyticsEngine.HealthInsight
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Insight header
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: insight.category.icon)
                                .foregroundColor(categoryColor)
                                .font(.title2)
                            
                            Text(insight.title)
                                .font(.title2)
                                .fontWeight(.bold)
                        }
                        
                        Text(insight.description)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    
                    // Insight details
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Details")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        DetailRow(label: "Category", value: insight.category.rawValue)
                        DetailRow(label: "Data Type", value: insight.dataType)
                        DetailRow(label: "Value", value: "\(insight.value, specifier: "%.1f") \(insight.unit)")
                        DetailRow(label: "Confidence", value: "\(Int(insight.confidence * 100))%")
                        DetailRow(label: "Actionable", value: insight.actionable ? "Yes" : "No")
                    }
                    
                    // Action items
                    if !insight.actionItems.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Action Items")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            ForEach(insight.actionItems, id: \.self) { item in
                                HStack {
                                    Image(systemName: "checkmark.circle")
                                        .foregroundColor(.green)
                                        .font(.caption)
                                    
                                    Text(item)
                                        .font(.subheadline)
                                }
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Insight Details")
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
    
    private var categoryColor: Color {
        switch insight.category {
        case .trends: return .blue
        case .anomalies: return .orange
        case .correlations: return .green
        case .patterns: return .purple
        case .improvements: return .green
        case .warnings: return .red
        }
    }
}

struct DetailRow: View {
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

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Preview

struct HealthInsightsAnalyticsView_Previews: PreviewProvider {
    static var previews: some View {
        HealthInsightsAnalyticsView()
    }
} 
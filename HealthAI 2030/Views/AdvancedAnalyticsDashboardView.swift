import SwiftUI
import Charts

/// Advanced Analytics Dashboard
/// Provides comprehensive health insights, trend analysis, and predictive modeling
struct AdvancedAnalyticsDashboardView: View {
    @StateObject private var analyticsManager = AdvancedAnalyticsManager()
    @State private var selectedDimension: HealthDimension = .overall
    @State private var selectedTimeframe: TimeInterval = 7 * 24 * 3600 // 7 days
    @State private var showingInsightDetail = false
    @State private var selectedInsight: HealthInsight?
    @State private var showingRecommendationDetail = false
    @State private var selectedRecommendation: HealthRecommendation?
    
    private let timeframes: [(String, TimeInterval)] = [
        ("7 Days", 7 * 24 * 3600),
        ("30 Days", 30 * 24 * 3600),
        ("90 Days", 90 * 24 * 3600)
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Health Overview Card
                    HealthOverviewCard(healthScore: analyticsManager.currentHealthScore)
                    
                    // Dimension Selector
                    DimensionSelectorView(selectedDimension: $selectedDimension)
                    
                    // Timeframe Selector
                    TimeframeSelectorView(
                        timeframes: timeframes,
                        selectedTimeframe: $selectedTimeframe
                    )
                    
                    // Analytics Content
                    AnalyticsContentView(
                        analyticsManager: analyticsManager,
                        dimension: selectedDimension,
                        timeframe: selectedTimeframe
                    )
                }
                .padding()
            }
            .navigationTitle("Health Analytics")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: refreshAnalytics) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
        }
        .onAppear {
            analyticsManager.startAnalytics()
        }
        .onDisappear {
            analyticsManager.stopAnalytics()
        }
        .sheet(isPresented: $showingInsightDetail) {
            if let insight = selectedInsight {
                InsightDetailView(insight: insight)
            }
        }
        .sheet(isPresented: $showingRecommendationDetail) {
            if let recommendation = selectedRecommendation {
                RecommendationDetailView(recommendation: recommendation)
            }
        }
    }
    
    private func refreshAnalytics() {
        analyticsManager.startAnalytics()
    }
}

// MARK: - Health Overview Card

struct HealthOverviewCard: View {
    let healthScore: Double
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Overall Health Score")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("\(Int(healthScore * 100))")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(healthScoreColor)
                }
                
                Spacer()
                
                // Health Score Ring
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                        .frame(width: 80, height: 80)
                    
                    Circle()
                        .trim(from: 0, to: healthScore)
                        .stroke(healthScoreColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .frame(width: 80, height: 80)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 1.0), value: healthScore)
                    
                    Text("\(Int(healthScore * 100))")
                        .font(.caption)
                        .fontWeight(.semibold)
                }
            }
            
            // Health Level Indicator
            HStack {
                Text(healthLevelText)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(healthScoreColor)
                
                Spacer()
                
                Text(healthLevelDescription)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }
    
    private var healthScoreColor: Color {
        switch healthScore {
        case 0.0..<0.4: return .red
        case 0.4..<0.7: return .orange
        case 0.7..<0.9: return .yellow
        default: return .green
        }
    }
    
    private var healthLevelText: String {
        switch healthScore {
        case 0.0..<0.4: return "Needs Attention"
        case 0.4..<0.7: return "Fair"
        case 0.7..<0.9: return "Good"
        default: return "Excellent"
        }
    }
    
    private var healthLevelDescription: String {
        switch healthScore {
        case 0.0..<0.4: return "Focus on improving health habits"
        case 0.4..<0.7: return "Room for improvement"
        case 0.7..<0.9: return "Maintaining good health"
        default: return "Optimal health status"
        }
    }
}

// MARK: - Dimension Selector

struct DimensionSelectorView: View {
    @Binding var selectedDimension: HealthDimension
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Health Dimension")
                .font(.headline)
                .foregroundColor(.primary)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(HealthDimension.allCases, id: \.self) { dimension in
                        DimensionButton(
                            dimension: dimension,
                            isSelected: selectedDimension == dimension,
                            action: { selectedDimension = dimension }
                        )
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

struct DimensionButton: View {
    let dimension: HealthDimension
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(dimension.rawValue)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(isSelected ? Color.accentColor : Color(.systemGray6))
                )
        }
    }
}

// MARK: - Timeframe Selector

struct TimeframeSelectorView: View {
    let timeframes: [(String, TimeInterval)]
    @Binding var selectedTimeframe: TimeInterval
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Time Period")
                .font(.headline)
                .foregroundColor(.primary)
            
            HStack(spacing: 12) {
                ForEach(timeframes, id: \.1) { timeframe in
                    TimeframeButton(
                        title: timeframe.0,
                        isSelected: selectedTimeframe == timeframe.1,
                        action: { selectedTimeframe = timeframe.1 }
                    )
                }
            }
        }
    }
}

struct TimeframeButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(isSelected ? Color.accentColor : Color(.systemGray6))
                )
        }
    }
}

// MARK: - Analytics Content

struct AnalyticsContentView: View {
    @ObservedObject var analyticsManager: AdvancedAnalyticsManager
    let dimension: HealthDimension
    let timeframe: TimeInterval
    
    var body: some View {
        VStack(spacing: 20) {
            // Trends Chart
            TrendsChartView(
                trends: analyticsManager.healthTrends,
                dimension: dimension
            )
            
            // Insights Panel
            InsightsPanelView(
                insights: analyticsManager.insights,
                dimension: dimension
            )
            
            // Recommendations Panel
            RecommendationsPanelView(
                recommendations: analyticsManager.recommendations,
                dimension: dimension
            )
            
            // Risk Assessment
            RiskAssessmentView(
                risks: analyticsManager.riskAssessments,
                dimension: dimension
            )
        }
    }
}

// MARK: - Trends Chart

struct TrendsChartView: View {
    let trends: [HealthTrend]
    let dimension: HealthDimension
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Health Trends")
                .font(.headline)
                .foregroundColor(.primary)
            
            if trends.isEmpty {
                Text("No trend data available")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                // Simple trend visualization
                VStack(spacing: 12) {
                    ForEach(trends.prefix(5), id: \.id) { trend in
                        TrendRowView(trend: trend)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }
}

struct TrendRowView: View {
    let trend: HealthTrend
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(trend.metric)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("\(String(format: "%.1f", trend.magnitude))% change")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Trend indicator
            HStack(spacing: 4) {
                Image(systemName: trendDirectionIcon)
                    .foregroundColor(trendDirectionColor)
                
                Text(trend.direction.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(trendDirectionColor)
            }
        }
        .padding(.vertical, 4)
    }
    
    private var trendDirectionIcon: String {
        switch trend.direction {
        case .improving: return "arrow.up.right"
        case .declining: return "arrow.down.right"
        case .stable: return "arrow.right"
        }
    }
    
    private var trendDirectionColor: Color {
        switch trend.direction {
        case .improving: return .green
        case .declining: return .red
        case .stable: return .orange
        }
    }
}

// MARK: - Insights Panel

struct InsightsPanelView: View {
    let insights: [HealthInsight]
    let dimension: HealthDimension
    @State private var showingInsightDetail = false
    @State private var selectedInsight: HealthInsight?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("AI Insights")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("\(insights.count)")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(.systemGray6))
                    )
            }
            
            if insights.isEmpty {
                Text("No insights available")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                VStack(spacing: 12) {
                    ForEach(insights.prefix(3), id: \.id) { insight in
                        InsightCardView(insight: insight) {
                            selectedInsight = insight
                            showingInsightDetail = true
                        }
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
        .sheet(isPresented: $showingInsightDetail) {
            if let insight = selectedInsight {
                InsightDetailView(insight: insight)
            }
        }
    }
}

struct InsightCardView: View {
    let insight: HealthInsight
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(insight.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    PriorityBadge(priority: insight.priority)
                }
                
                Text(insight.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                HStack {
                    Text(insight.category.rawValue)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(.systemGray6))
                        )
                    
                    Spacer()
                    
                    Text("\(Int(insight.confidence * 100))% confidence")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Recommendations Panel

struct RecommendationsPanelView: View {
    let recommendations: [HealthRecommendation]
    let dimension: HealthDimension
    @State private var showingRecommendationDetail = false
    @State private var selectedRecommendation: HealthRecommendation?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recommendations")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("\(recommendations.count)")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(.systemGray6))
                    )
            }
            
            if recommendations.isEmpty {
                Text("No recommendations available")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                VStack(spacing: 12) {
                    ForEach(recommendations.prefix(3), id: \.id) { recommendation in
                        RecommendationCardView(recommendation: recommendation) {
                            selectedRecommendation = recommendation
                            showingRecommendationDetail = true
                        }
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
        .sheet(isPresented: $showingRecommendationDetail) {
            if let recommendation = selectedRecommendation {
                RecommendationDetailView(recommendation: recommendation)
            }
        }
    }
}

struct RecommendationCardView: View {
    let recommendation: HealthRecommendation
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(recommendation.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    PriorityBadge(priority: recommendation.priority)
                }
                
                Text(recommendation.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                HStack {
                    Text(recommendation.category.rawValue)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(.systemGray6))
                        )
                    
                    Spacer()
                    
                    Text("\(Int(recommendation.estimatedImpact * 100))% impact")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Risk Assessment

struct RiskAssessmentView: View {
    let risks: [RiskAssessment]
    let dimension: HealthDimension
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Risk Assessment")
                .font(.headline)
                .foregroundColor(.primary)
            
            if risks.isEmpty {
                Text("No risks identified")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                VStack(spacing: 12) {
                    ForEach(risks.prefix(3), id: \.id) { risk in
                        RiskCardView(risk: risk)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }
}

struct RiskCardView: View {
    let risk: RiskAssessment
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(risk.category.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Spacer()
                
                RiskLevelBadge(level: risk.level)
            }
            
            Text("Risk Score: \(Int(risk.score * 100))%")
                .font(.caption)
                .foregroundColor(.secondary)
            
            if !risk.factors.isEmpty {
                Text("Factors: \(risk.factors.joined(separator: ", "))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(riskLevelColor.opacity(0.1))
        )
    }
    
    private var riskLevelColor: Color {
        switch risk.level {
        case .low: return .green
        case .moderate: return .orange
        case .high: return .red
        case .critical: return .purple
        }
    }
}

// MARK: - Supporting Views

struct PriorityBadge: View {
    let priority: InsightPriority
    
    var body: some View {
        Text(priority.rawValue)
            .font(.caption2)
            .fontWeight(.medium)
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(priorityColor)
            )
    }
    
    private var priorityColor: Color {
        switch priority {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        case .urgent: return .purple
        }
    }
}

struct RiskLevelBadge: View {
    let level: RiskLevel
    
    var body: some View {
        Text(level.rawValue)
            .font(.caption2)
            .fontWeight(.medium)
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(levelColor)
            )
    }
    
    private var levelColor: Color {
        switch level {
        case .low: return .green
        case .moderate: return .orange
        case .high: return .red
        case .critical: return .purple
        }
    }
}

// MARK: - Detail Views

struct InsightDetailView: View {
    let insight: HealthInsight
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Insight header
                    VStack(alignment: .leading, spacing: 12) {
                        Text(insight.title)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text(insight.description)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    
                    // Insight details
                    VStack(alignment: .leading, spacing: 16) {
                        DetailRow(title: "Category", value: insight.category.rawValue)
                        DetailRow(title: "Priority", value: insight.priority.rawValue)
                        DetailRow(title: "Confidence", value: "\(Int(insight.confidence * 100))%")
                        DetailRow(title: "Actionable", value: insight.actionable ? "Yes" : "No")
                    }
                    
                    if insight.actionable {
                        // Action suggestions
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Suggested Actions")
                                .font(.headline)
                            
                            Text("Based on this insight, consider taking the following actions to improve your health.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
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
}

struct RecommendationDetailView: View {
    let recommendation: HealthRecommendation
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Recommendation header
                    VStack(alignment: .leading, spacing: 12) {
                        Text(recommendation.title)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text(recommendation.description)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    
                    // Recommendation details
                    VStack(alignment: .leading, spacing: 16) {
                        DetailRow(title: "Category", value: recommendation.category.rawValue)
                        DetailRow(title: "Priority", value: recommendation.priority.rawValue)
                        DetailRow(title: "Estimated Impact", value: "\(Int(recommendation.estimatedImpact * 100))%")
                        DetailRow(title: "Actionable", value: recommendation.actionable ? "Yes" : "No")
                    }
                    
                    if recommendation.actionable {
                        // Implementation steps
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Implementation Steps")
                                .font(.headline)
                            
                            Text("To implement this recommendation, consider the following steps:")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Recommendation Details")
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

struct DetailRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    AdvancedAnalyticsDashboardView()
} 
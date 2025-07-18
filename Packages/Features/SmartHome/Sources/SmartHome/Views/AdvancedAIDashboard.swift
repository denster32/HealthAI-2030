import SwiftUI
import Combine

/// Advanced AI Dashboard
/// Provides real-time monitoring and control for all AI services and insights
@MainActor
struct AdvancedAIDashboard: View {
    
    @StateObject private var aiOrchestrator = AdvancedAIOrchestrationManager()
    @State private var selectedTab = 0
    @State private var showingInsightDetails = false
    @State private var selectedInsight: HealthInsight?
    @State private var showingModelDetails = false
    @State private var selectedModel: AIModel?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                headerSection
                
                // Tab View
                TabView(selection: $selectedTab) {
                    // Overview Tab
                    overviewTab
                        .tabItem {
                            Label("Overview", systemImage: "brain.head.profile")
                        }
                        .tag(0)
                    
                    // Insights Tab
                    insightsTab
                        .tabItem {
                            Label("Insights", systemImage: "lightbulb.fill")
                        }
                        .tag(1)
                    
                    // Recommendations Tab
                    recommendationsTab
                        .tabItem {
                            Label("Recommendations", systemImage: "list.bullet.clipboard")
                        }
                        .tag(2)
                    
                    // Predictions Tab
                    predictionsTab
                        .tabItem {
                            Label("Predictions", systemImage: "chart.line.uptrend.xyaxis")
                        }
                        .tag(3)
                    
                    // Models Tab
                    modelsTab
                        .tabItem {
                            Label("Models", systemImage: "cpu")
                        }
                        .tag(4)
                    
                    // Performance Tab
                    performanceTab
                        .tabItem {
                            Label("Performance", systemImage: "speedometer")
                        }
                        .tag(5)
                }
            }
            .navigationTitle("AI Dashboard")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Refresh") {
                        Task {
                            await refreshAIData()
                        }
                    }
                    .disabled(aiOrchestrator.orchestrationStatus == .starting || aiOrchestrator.orchestrationStatus == .stopping)
                }
            }
        }
        .onAppear {
            // AI orchestration starts automatically in init
        }
        .onDisappear {
            aiOrchestrator.stopOrchestration()
        }
        .sheet(isPresented: $showingInsightDetails) {
            if let insight = selectedInsight {
                InsightDetailView(insight: insight)
            }
        }
        .sheet(isPresented: $showingModelDetails) {
            if let model = selectedModel {
                ModelDetailView(model: model)
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Status Card
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("AI Orchestration Status")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Circle()
                            .fill(statusColor)
                            .frame(width: 12, height: 12)
                        
                        Text(aiOrchestrator.orchestrationStatus.rawValue.capitalized)
                            .font(.title2)
                            .fontWeight(.semibold)
                    }
                }
                
                Spacer()
                
                Button("Optimize") {
                    Task {
                        try? await aiOrchestrator.optimizeModelsForDevice()
                    }
                }
                .buttonStyle(.bordered)
                .disabled(aiOrchestrator.orchestrationStatus != .running)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            
            // Quick Stats
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 16) {
                StatCard(
                    title: "Insights",
                    value: "\(aiOrchestrator.healthInsights.count)",
                    color: .blue,
                    icon: "lightbulb"
                )
                
                StatCard(
                    title: "Recommendations",
                    value: "\(aiOrchestrator.recommendations.count)",
                    color: .green,
                    icon: "list.bullet.clipboard"
                )
                
                StatCard(
                    title: "Predictions",
                    value: "\(aiOrchestrator.predictions.count)",
                    color: .orange,
                    icon: "chart.line.uptrend.xyaxis"
                )
                
                StatCard(
                    title: "Models",
                    value: "\(aiOrchestrator.aiModels.count)",
                    color: .purple,
                    icon: "cpu"
                )
            }
        }
        .padding()
    }
    
    // MARK: - Overview Tab
    
    private var overviewTab: some View {
        ScrollView {
            VStack(spacing: 20) {
                // AI Performance Overview
                AIPerformanceOverviewCard(aiOrchestrator: aiOrchestrator)
                
                // Recent Insights
                RecentInsightsCard(insights: aiOrchestrator.healthInsights) { insight in
                    selectedInsight = insight
                    showingInsightDetails = true
                }
                
                // Top Recommendations
                TopRecommendationsCard(recommendations: aiOrchestrator.recommendations)
                
                // Model Status
                ModelStatusCard(models: aiOrchestrator.aiModels) { model in
                    selectedModel = model
                    showingModelDetails = true
                }
            }
            .padding()
        }
    }
    
    // MARK: - Insights Tab
    
    private var insightsTab: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Insights Summary
                InsightsSummaryCard(insights: aiOrchestrator.healthInsights)
                
                // Insights List
                InsightsListCard(insights: aiOrchestrator.healthInsights) { insight in
                    selectedInsight = insight
                    showingInsightDetails = true
                }
                
                // Insights by Type
                InsightsByTypeCard(insights: aiOrchestrator.healthInsights)
                
                // Insights by Severity
                InsightsBySeverityCard(insights: aiOrchestrator.healthInsights)
            }
            .padding()
        }
    }
    
    // MARK: - Recommendations Tab
    
    private var recommendationsTab: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Recommendations Summary
                RecommendationsSummaryCard(recommendations: aiOrchestrator.recommendations)
                
                // Recommendations List
                RecommendationsListCard(recommendations: aiOrchestrator.recommendations)
                
                // Recommendations by Priority
                RecommendationsByPriorityCard(recommendations: aiOrchestrator.recommendations)
                
                // Recommendations by Type
                RecommendationsByTypeCard(recommendations: aiOrchestrator.recommendations)
            }
            .padding()
        }
    }
    
    // MARK: - Predictions Tab
    
    private var predictionsTab: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Predictions Summary
                PredictionsSummaryCard(predictions: aiOrchestrator.predictions)
                
                // Predictions List
                PredictionsListCard(predictions: aiOrchestrator.predictions)
                
                // Predictions by Type
                PredictionsByTypeCard(predictions: aiOrchestrator.predictions)
                
                // Predictions by Timeframe
                PredictionsByTimeframeCard(predictions: aiOrchestrator.predictions)
            }
            .padding()
        }
    }
    
    // MARK: - Models Tab
    
    private var modelsTab: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Models Summary
                ModelsSummaryCard(models: aiOrchestrator.aiModels)
                
                // Models List
                ModelsListCard(models: aiOrchestrator.aiModels) { model in
                    selectedModel = model
                    showingModelDetails = true
                }
                
                // Model Performance
                ModelPerformanceCard(models: aiOrchestrator.aiModels)
                
                // Model Types
                ModelTypesCard(models: aiOrchestrator.aiModels)
            }
            .padding()
        }
    }
    
    // MARK: - Performance Tab
    
    private var performanceTab: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Performance Metrics
                PerformanceMetricsCard(metrics: aiOrchestrator.performanceMetrics)
                
                // Model Accuracy
                ModelAccuracyCard(models: aiOrchestrator.aiModels)
                
                // Model Latency
                ModelLatencyCard(models: aiOrchestrator.aiModels)
                
                // Memory Usage
                MemoryUsageCard(models: aiOrchestrator.aiModels)
            }
            .padding()
        }
    }
    
    // MARK: - Helper Methods
    
    private func refreshAIData() async {
        do {
            _ = try await aiOrchestrator.generateHealthInsights()
            _ = try await aiOrchestrator.generateRecommendations()
            _ = try await aiOrchestrator.generatePredictions()
            try await aiOrchestrator.updateModelPerformance()
        } catch {
            print("Failed to refresh AI data: \(error)")
        }
    }
    
    // MARK: - Computed Properties
    
    private var statusColor: Color {
        switch aiOrchestrator.orchestrationStatus {
        case .running: return .green
        case .starting, .stopping: return .orange
        case .stopped: return .gray
        case .error: return .red
        case .initializing: return .blue
        }
    }
}

// MARK: - Supporting Views

struct StatCard: View {
    let title: String
    let value: String
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.headline)
                .fontWeight(.semibold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

struct AIPerformanceOverviewCard: View {
    @ObservedObject var aiOrchestrator: AdvancedAIOrchestrationManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("AI Performance Overview")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                PerformanceRow(
                    title: "Average Accuracy",
                    value: String(format: "%.1f%%", aiOrchestrator.performanceMetrics.averageAccuracy * 100),
                    color: .green
                )
                
                PerformanceRow(
                    title: "Average Latency",
                    value: String(format: "%.1fms", aiOrchestrator.performanceMetrics.averageLatency),
                    color: .blue
                )
                
                PerformanceRow(
                    title: "Memory Usage",
                    value: String(format: "%.1fMB", aiOrchestrator.performanceMetrics.totalMemoryUsage),
                    color: .orange
                )
                
                PerformanceRow(
                    title: "Ready Models",
                    value: "\(aiOrchestrator.performanceMetrics.readyModels)/\(aiOrchestrator.performanceMetrics.totalModels)",
                    color: .purple
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct PerformanceRow: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
    }
}

struct RecentInsightsCard: View {
    let insights: [HealthInsight]
    let onInsightTap: (HealthInsight) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Insights")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVStack(spacing: 8) {
                ForEach(insights.prefix(5)) { insight in
                    InsightRow(insight: insight) {
                        onInsightTap(insight)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct InsightRow: View {
    let insight: HealthInsight
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Circle()
                    .fill(severityColor)
                    .frame(width: 8, height: 8)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(insight.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text(insight.type.rawValue)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text(String(format: "%.0f%%", insight.confidence * 100))
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var severityColor: Color {
        switch insight.severity {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        case .critical: return .purple
        }
    }
}

struct TopRecommendationsCard: View {
    let recommendations: [HealthRecommendation]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Top Recommendations")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVStack(spacing: 8) {
                ForEach(recommendations.prefix(3)) { recommendation in
                    RecommendationRow(recommendation: recommendation)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct RecommendationRow: View {
    let recommendation: HealthRecommendation
    
    var body: some View {
        HStack {
            Circle()
                .fill(priorityColor)
                .frame(width: 8, height: 8)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(recommendation.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(recommendation.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            if recommendation.actionable {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.caption)
            }
        }
        .padding(.vertical, 4)
    }
    
    private var priorityColor: Color {
        switch recommendation.priority {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        case .critical: return .purple
        }
    }
}

struct ModelStatusCard: View {
    let models: [AIModel]
    let onModelTap: (AIModel) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Model Status")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVStack(spacing: 8) {
                ForEach(models.prefix(5)) { model in
                    ModelRow(model: model) {
                        onModelTap(model)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct ModelRow: View {
    let model: AIModel
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(model.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text(model.type.rawValue)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text(String(format: "%.0f%%", model.accuracy * 100))
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var statusColor: Color {
        switch model.status {
        case .ready: return .green
        case .running: return .blue
        case .initializing: return .orange
        case .updating: return .yellow
        case .error: return .red
        }
    }
}

// MARK: - Placeholder Cards for Other Tabs

struct InsightsSummaryCard: View {
    let insights: [HealthInsight]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Insights Summary")
                .font(.headline)
                .fontWeight(.semibold)
            
            Text("Implementation needed")
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct InsightsListCard: View {
    let insights: [HealthInsight]
    let onInsightTap: (HealthInsight) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("All Insights")
                .font(.headline)
                .fontWeight(.semibold)
            
            Text("Implementation needed")
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct InsightsByTypeCard: View {
    let insights: [HealthInsight]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Insights by Type")
                .font(.headline)
                .fontWeight(.semibold)
            
            Text("Implementation needed")
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct InsightsBySeverityCard: View {
    let insights: [HealthInsight]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Insights by Severity")
                .font(.headline)
                .fontWeight(.semibold)
            
            Text("Implementation needed")
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct RecommendationsSummaryCard: View {
    let recommendations: [HealthRecommendation]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recommendations Summary")
                .font(.headline)
                .fontWeight(.semibold)
            
            Text("Implementation needed")
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct RecommendationsListCard: View {
    let recommendations: [HealthRecommendation]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("All Recommendations")
                .font(.headline)
                .fontWeight(.semibold)
            
            Text("Implementation needed")
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct RecommendationsByPriorityCard: View {
    let recommendations: [HealthRecommendation]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recommendations by Priority")
                .font(.headline)
                .fontWeight(.semibold)
            
            Text("Implementation needed")
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct RecommendationsByTypeCard: View {
    let recommendations: [HealthRecommendation]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recommendations by Type")
                .font(.headline)
                .fontWeight(.semibold)
            
            Text("Implementation needed")
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct PredictionsSummaryCard: View {
    let predictions: [HealthPrediction]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Predictions Summary")
                .font(.headline)
                .fontWeight(.semibold)
            
            Text("Implementation needed")
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct PredictionsListCard: View {
    let predictions: [HealthPrediction]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("All Predictions")
                .font(.headline)
                .fontWeight(.semibold)
            
            Text("Implementation needed")
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct PredictionsByTypeCard: View {
    let predictions: [HealthPrediction]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Predictions by Type")
                .font(.headline)
                .fontWeight(.semibold)
            
            Text("Implementation needed")
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct PredictionsByTimeframeCard: View {
    let predictions: [HealthPrediction]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Predictions by Timeframe")
                .font(.headline)
                .fontWeight(.semibold)
            
            Text("Implementation needed")
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct ModelsSummaryCard: View {
    let models: [AIModel]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Models Summary")
                .font(.headline)
                .fontWeight(.semibold)
            
            Text("Implementation needed")
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct ModelsListCard: View {
    let models: [AIModel]
    let onModelTap: (AIModel) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("All Models")
                .font(.headline)
                .fontWeight(.semibold)
            
            Text("Implementation needed")
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct ModelPerformanceCard: View {
    let models: [AIModel]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Model Performance")
                .font(.headline)
                .fontWeight(.semibold)
            
            Text("Implementation needed")
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct ModelTypesCard: View {
    let models: [AIModel]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Model Types")
                .font(.headline)
                .fontWeight(.semibold)
            
            Text("Implementation needed")
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct PerformanceMetricsCard: View {
    let metrics: AIMetrics
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Performance Metrics")
                .font(.headline)
                .fontWeight(.semibold)
            
            Text("Implementation needed")
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct ModelAccuracyCard: View {
    let models: [AIModel]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Model Accuracy")
                .font(.headline)
                .fontWeight(.semibold)
            
            Text("Implementation needed")
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct ModelLatencyCard: View {
    let models: [AIModel]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Model Latency")
                .font(.headline)
                .fontWeight(.semibold)
            
            Text("Implementation needed")
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct MemoryUsageCard: View {
    let models: [AIModel]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Memory Usage")
                .font(.headline)
                .fontWeight(.semibold)
            
            Text("Implementation needed")
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Detail Views

struct InsightDetailView: View {
    let insight: HealthInsight
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Insight Header
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Circle()
                                .fill(severityColor)
                                .frame(width: 12, height: 12)
                            
                            Text(insight.type.rawValue)
                                .font(.headline)
                                .foregroundColor(.secondary)
                        }
                        
                        Text(insight.title)
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text(insight.description)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    
                    // Insight Details
                    VStack(alignment: .leading, spacing: 16) {
                        DetailRow(title: "Severity", value: insight.severity.rawValue.capitalized)
                        DetailRow(title: "Confidence", value: String(format: "%.0f%%", insight.confidence * 100))
                        DetailRow(title: "Source", value: insight.source)
                        DetailRow(title: "Timestamp", value: formatDate(insight.timestamp))
                    }
                }
                .padding()
            }
            .navigationTitle("Insight Details")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private var severityColor: Color {
        switch insight.severity {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        case .critical: return .purple
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct ModelDetailView: View {
    let model: AIModel
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Model Header
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Circle()
                                .fill(statusColor)
                                .frame(width: 12, height: 12)
                            
                            Text(model.type.rawValue)
                                .font(.headline)
                                .foregroundColor(.secondary)
                        }
                        
                        Text(model.name)
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("Version \(model.version)")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    
                    // Model Details
                    VStack(alignment: .leading, spacing: 16) {
                        DetailRow(title: "Status", value: model.status.rawValue.capitalized)
                        DetailRow(title: "Accuracy", value: String(format: "%.1f%%", model.accuracy * 100))
                        DetailRow(title: "Latency", value: String(format: "%.1fms", model.latency))
                        DetailRow(title: "Memory Usage", value: String(format: "%.1fMB", model.memoryUsage))
                        DetailRow(title: "Last Updated", value: formatDate(model.lastUpdated))
                    }
                }
                .padding()
            }
            .navigationTitle("Model Details")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private var statusColor: Color {
        switch model.status {
        case .ready: return .green
        case .running: return .blue
        case .initializing: return .orange
        case .updating: return .yellow
        case .error: return .red
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct DetailRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
}

// MARK: - Extensions

extension OrchestrationStatus {
    var rawValue: String {
        switch self {
        case .initializing: return "initializing"
        case .starting: return "starting"
        case .running: return "running"
        case .stopping: return "stopping"
        case .stopped: return "stopped"
        case .error: return "error"
        }
    }
}

extension AIModelType {
    var rawValue: String {
        switch self {
        case .healthPrediction: return "Health Prediction"
        case .sleepAnalysis: return "Sleep Analysis"
        case .moodAnalysis: return "Mood Analysis"
        case .ecgAnalysis: return "ECG Analysis"
        case .federatedLearning: return "Federated Learning"
        case .mlxPrediction: return "MLX Prediction"
        }
    }
}

extension ModelStatus {
    var rawValue: String {
        switch self {
        case .initializing: return "initializing"
        case .ready: return "ready"
        case .running: return "running"
        case .error: return "error"
        case .updating: return "updating"
        }
    }
}

#Preview {
    AdvancedAIDashboard()
} 
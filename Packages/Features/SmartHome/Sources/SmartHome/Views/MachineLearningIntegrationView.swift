import SwiftUI
import Charts

/// Comprehensive SwiftUI view for Machine Learning Integration
/// Provides interface for managing ML models, viewing predictions, anomalies, and recommendations
public struct MachineLearningIntegrationView: View {
    @StateObject private var mlManager = MachineLearningIntegrationManager.shared
    @State private var selectedTab = 0
    @State private var showingModelDetails = false
    @State private var selectedModelName = ""
    @State private var showingTrainingView = false
    @State private var showingExportView = false
    @State private var searchText = ""
    @State private var selectedPredictionType: MachineLearningIntegrationManager.PredictionType?
    @State private var selectedAnomalySeverity: MachineLearningIntegrationManager.AnomalySeverity?
    @State private var selectedRecommendationCategory: MachineLearningIntegrationManager.RecommendationCategory?
    
    public init() {}
    
    public var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with status
                headerView
                
                // Tab selection
                tabSelectionView
                
                // Content based on selected tab
                TabView(selection: $selectedTab) {
                    modelsTabView
                        .tag(0)
                    
                    predictionsTabView
                        .tag(1)
                    
                    anomaliesTabView
                        .tag(2)
                    
                    recommendationsTabView
                        .tag(3)
                    
                    analyticsTabView
                        .tag(4)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .navigationTitle("ML Integration")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Train Models") {
                            showingTrainingView = true
                        }
                        
                        Button("Export Data") {
                            showingExportView = true
                        }
                        
                        Button("Refresh") {
                            Task {
                                await mlManager.loadModels()
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .sheet(isPresented: $showingModelDetails) {
            ModelDetailsView(modelName: selectedModelName)
        }
        .sheet(isPresented: $showingTrainingView) {
            ModelTrainingView()
        }
        .sheet(isPresented: $showingExportView) {
            MLExportView()
        }
        .onAppear {
            Task {
                await mlManager.initialize()
            }
        }
    }
    
    // MARK: - Header View
    
    private var headerView: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("ML Status")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Circle()
                            .fill(Color(mlManager.mlStatus.color))
                            .frame(width: 8, height: 8)
                        
                        Text(mlManager.mlStatus.rawValue)
                            .font(.headline)
                            .foregroundColor(.primary)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Ready Models")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("\(mlManager.modelStatus.values.filter { $0 == .ready }.count)/\(mlManager.modelStatus.count)")
                        .font(.headline)
                        .foregroundColor(.primary)
                }
            }
            
            // Progress bar for model readiness
            ProgressView(value: Double(mlManager.modelStatus.values.filter { $0 == .ready }.count), total: Double(max(mlManager.modelStatus.count, 1)))
                .progressViewStyle(LinearProgressViewStyle(tint: .green))
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
        .padding(.horizontal)
    }
    
    // MARK: - Tab Selection
    
    private var tabSelectionView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(["Models", "Predictions", "Anomalies", "Recommendations", "Analytics"], id: \.self) { tab in
                    Button(action: {
                        withAnimation {
                            selectedTab = ["Models", "Predictions", "Anomalies", "Recommendations", "Analytics"].firstIndex(of: tab) ?? 0
                        }
                    }) {
                        VStack(spacing: 4) {
                            Text(tab)
                                .font(.subheadline)
                                .fontWeight(selectedTab == ["Models", "Predictions", "Anomalies", "Recommendations", "Analytics"].firstIndex(of: tab) ? .semibold : .regular)
                                .foregroundColor(selectedTab == ["Models", "Predictions", "Anomalies", "Recommendations", "Analytics"].firstIndex(of: tab) ? .primary : .secondary)
                            
                            Rectangle()
                                .fill(selectedTab == ["Models", "Predictions", "Anomalies", "Recommendations", "Analytics"].firstIndex(of: tab) ? Color.blue : Color.clear)
                                .frame(height: 2)
                        }
                        .frame(width: 100)
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Models Tab
    
    private var modelsTabView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(Array(mlManager.modelStatus.keys.sorted()), id: \.self) { modelName in
                    ModelCardView(
                        modelName: modelName,
                        status: mlManager.modelStatus[modelName] ?? .notLoaded,
                        performance: mlManager.modelPerformance[modelName]
                    ) {
                        selectedModelName = modelName
                        showingModelDetails = true
                    }
                }
            }
            .padding()
        }
    }
    
    // MARK: - Predictions Tab
    
    private var predictionsTabView: some View {
        VStack(spacing: 16) {
            // Filter controls
            HStack {
                Picker("Prediction Type", selection: $selectedPredictionType) {
                    Text("All Types").tag(nil as MachineLearningIntegrationManager.PredictionType?)
                    ForEach(MachineLearningIntegrationManager.PredictionType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type as MachineLearningIntegrationManager.PredictionType?)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                
                Spacer()
            }
            .padding(.horizontal)
            
            // Predictions list
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(filteredPredictions) { prediction in
                        PredictionCardView(prediction: prediction)
                    }
                }
                .padding()
            }
        }
    }
    
    private var filteredPredictions: [MachineLearningIntegrationManager.MLPrediction] {
        let predictions = mlManager.predictions
        if let selectedType = selectedPredictionType {
            return predictions.filter { $0.type == selectedType }
        }
        return predictions
    }
    
    // MARK: - Anomalies Tab
    
    private var anomaliesTabView: some View {
        VStack(spacing: 16) {
            // Filter controls
            HStack {
                Picker("Severity", selection: $selectedAnomalySeverity) {
                    Text("All Severities").tag(nil as MachineLearningIntegrationManager.AnomalySeverity?)
                    ForEach(MachineLearningIntegrationManager.AnomalySeverity.allCases, id: \.self) { severity in
                        Text(severity.rawValue).tag(severity as MachineLearningIntegrationManager.AnomalySeverity?)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                
                Spacer()
            }
            .padding(.horizontal)
            
            // Anomalies list
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(filteredAnomalies) { anomaly in
                        AnomalyCardView(anomaly: anomaly)
                    }
                }
                .padding()
            }
        }
    }
    
    private var filteredAnomalies: [MachineLearningIntegrationManager.MLAnomaly] {
        let anomalies = mlManager.anomalies
        if let selectedSeverity = selectedAnomalySeverity {
            return anomalies.filter { $0.severity == selectedSeverity }
        }
        return anomalies
    }
    
    // MARK: - Recommendations Tab
    
    private var recommendationsTabView: some View {
        VStack(spacing: 16) {
            // Filter controls
            HStack {
                Picker("Category", selection: $selectedRecommendationCategory) {
                    Text("All Categories").tag(nil as MachineLearningIntegrationManager.RecommendationCategory?)
                    ForEach(MachineLearningIntegrationManager.RecommendationCategory.allCases, id: \.self) { category in
                        Text(category.rawValue).tag(category as MachineLearningIntegrationManager.RecommendationCategory?)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                
                Spacer()
            }
            .padding(.horizontal)
            
            // Recommendations list
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(filteredRecommendations) { recommendation in
                        RecommendationCardView(recommendation: recommendation)
                    }
                }
                .padding()
            }
        }
    }
    
    private var filteredRecommendations: [MachineLearningIntegrationManager.MLRecommendation] {
        let recommendations = mlManager.recommendations
        if let selectedCategory = selectedRecommendationCategory {
            return recommendations.filter { $0.category == selectedCategory }
        }
        return recommendations
    }
    
    // MARK: - Analytics Tab
    
    private var analyticsTabView: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Summary cards
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    SummaryCardView(
                        title: "Total Models",
                        value: "\(mlManager.getMLSummary().totalModels)",
                        icon: "brain.head.profile",
                        color: .blue
                    )
                    
                    SummaryCardView(
                        title: "Ready Models",
                        value: "\(mlManager.getMLSummary().readyModels)",
                        icon: "checkmark.circle",
                        color: .green
                    )
                    
                    SummaryCardView(
                        title: "Predictions",
                        value: "\(mlManager.getMLSummary().totalPredictions)",
                        icon: "chart.line.uptrend.xyaxis",
                        color: .orange
                    )
                    
                    SummaryCardView(
                        title: "Anomalies",
                        value: "\(mlManager.getMLSummary().totalAnomalies)",
                        icon: "exclamationmark.triangle",
                        color: .red
                    )
                }
                
                // Performance chart
                ModelPerformanceChartView(modelPerformance: mlManager.modelPerformance)
                
                // Recent activity
                RecentActivityView(
                    predictions: mlManager.predictions,
                    anomalies: mlManager.anomalies,
                    recommendations: mlManager.recommendations
                )
            }
            .padding()
        }
    }
}

// MARK: - Supporting Views

struct ModelCardView: View {
    let modelName: String
    let status: MachineLearningIntegrationManager.ModelStatus
    let performance: MachineLearningIntegrationManager.ModelPerformance?
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(modelName)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text(status.rawValue)
                            .font(.caption)
                            .foregroundColor(Color(status.color))
                    }
                    
                    Spacer()
                    
                    Circle()
                        .fill(Color(status.color))
                        .frame(width: 12, height: 12)
                }
                
                if let performance = performance {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Accuracy")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Text("\(Int(performance.accuracy * 100))%")
                                .font(.caption)
                                .fontWeight(.semibold)
                        }
                        
                        ProgressView(value: performance.accuracy)
                            .progressViewStyle(LinearProgressViewStyle(tint: .green))
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(radius: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct PredictionCardView: View {
    let prediction: MachineLearningIntegrationManager.MLPrediction
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(prediction.type.rawValue)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("Predicted: \(String(format: "%.1f", prediction.predictedValue)) \(prediction.type.unit)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(Int(prediction.confidence * 100))%")
                        .font(.headline)
                        .foregroundColor(.green)
                    
                    Text("Confidence")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Prediction Date")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(prediction.predictionDate, style: .date)
                    .font(.subheadline)
            }
            
            if !prediction.factors.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Key Factors")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(prediction.factors.joined(separator: ", "))
                        .font(.caption)
                        .foregroundColor(.primary)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct AnomalyCardView: View {
    let anomaly: MachineLearningIntegrationManager.MLAnomaly
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(anomaly.type.rawValue)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(anomaly.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(anomaly.severity.rawValue)
                        .font(.headline)
                        .foregroundColor(Color(anomaly.severity.color))
                    
                    Text("Severity")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Detected Value")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("\(String(format: "%.1f", anomaly.detectedValue)) \(anomaly.type.unit)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            
            if !anomaly.recommendations.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Recommendations")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    ForEach(anomaly.recommendations.prefix(2), id: \.self) { recommendation in
                        Text("• \(recommendation)")
                            .font(.caption)
                            .foregroundColor(.primary)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct RecommendationCardView: View {
    let recommendation: MachineLearningIntegrationManager.MLRecommendation
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(recommendation.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(recommendation.category.rawValue)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(recommendation.priority.rawValue)
                        .font(.headline)
                        .foregroundColor(Color(recommendation.priority.color))
                    
                    Text("Priority")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Text(recommendation.description)
                .font(.subheadline)
                .foregroundColor(.primary)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Confidence")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(Int(recommendation.confidence * 100))%")
                        .font(.caption)
                        .fontWeight(.semibold)
                }
                
                ProgressView(value: recommendation.confidence)
                    .progressViewStyle(LinearProgressViewStyle(tint: .blue))
            }
            
            if !recommendation.reasoning.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Reasoning")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(recommendation.reasoning.joined(separator: ", "))
                        .font(.caption)
                        .foregroundColor(.primary)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct SummaryCardView: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            VStack(spacing: 4) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct ModelPerformanceChartView: View {
    let modelPerformance: [String: MachineLearningIntegrationManager.ModelPerformance]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Model Performance")
                .font(.headline)
                .foregroundColor(.primary)
            
            if modelPerformance.isEmpty {
                Text("No performance data available")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                Chart(Array(modelPerformance.keys.sorted()), id: \.self) { modelName in
                    if let performance = modelPerformance[modelName] {
                        BarMark(
                            x: .value("Model", modelName),
                            y: .value("Accuracy", performance.accuracy)
                        )
                        .foregroundStyle(.blue)
                    }
                }
                .frame(height: 200)
                .chartYAxis {
                    AxisMarks(position: .leading) {
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel(format: .percent)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct RecentActivityView: View {
    let predictions: [MachineLearningIntegrationManager.MLPrediction]
    let anomalies: [MachineLearningIntegrationManager.MLAnomaly]
    let recommendations: [MachineLearningIntegrationManager.MLRecommendation]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Activity")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                ForEach(recentActivities.prefix(5), id: \.id) { activity in
                    HStack {
                        Image(systemName: activity.icon)
                            .foregroundColor(activity.color)
                            .frame(width: 20)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(activity.title)
                                .font(.subheadline)
                                .foregroundColor(.primary)
                            
                            Text(activity.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Text(activity.timestamp, style: .relative)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    private var recentActivities: [ActivityItem] {
        var activities: [ActivityItem] = []
        
        // Add recent predictions
        for prediction in predictions.suffix(3) {
            activities.append(ActivityItem(
                id: prediction.id,
                title: "New Prediction",
                description: "\(prediction.type.rawValue): \(String(format: "%.1f", prediction.predictedValue))",
                icon: "chart.line.uptrend.xyaxis",
                color: .green,
                timestamp: prediction.predictionDate
            ))
        }
        
        // Add recent anomalies
        for anomaly in anomalies.suffix(3) {
            activities.append(ActivityItem(
                id: anomaly.id,
                title: "Anomaly Detected",
                description: "\(anomaly.type.rawValue): \(anomaly.severity.rawValue)",
                icon: "exclamationmark.triangle",
                color: Color(anomaly.severity.color),
                timestamp: anomaly.detectionDate
            ))
        }
        
        // Add recent recommendations
        for recommendation in recommendations.suffix(3) {
            activities.append(ActivityItem(
                id: recommendation.id,
                title: "New Recommendation",
                description: recommendation.title,
                icon: "lightbulb",
                color: .blue,
                timestamp: Date()
            ))
        }
        
        return activities.sorted { $0.timestamp > $1.timestamp }
    }
}

struct ActivityItem {
    let id: UUID
    let title: String
    let description: String
    let icon: String
    let color: Color
    let timestamp: Date
}

// MARK: - Supporting Views (Placeholders)

struct ModelDetailsView: View {
    let modelName: String
    
    var body: some View {
        Text("Model Details for \(modelName)")
            .padding()
    }
}

struct ModelTrainingView: View {
    var body: some View {
        Text("Model Training")
            .padding()
    }
}

struct MLExportView: View {
    var body: some View {
        Text("ML Export")
            .padding()
    }
}

#Preview {
    MachineLearningIntegrationView()
} 
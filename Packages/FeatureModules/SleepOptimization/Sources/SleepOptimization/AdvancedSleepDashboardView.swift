import SwiftUI
import HealthAI2030Core
import HealthAI2030UI
import SleepIntelligenceEngine

/// Advanced sleep optimization dashboard with transformer-powered insights
public struct AdvancedSleepDashboardView: View {
    @StateObject private var sleepEngine = SleepIntelligenceEngine.shared
    @State private var sleepInsights: [SleepInsight] = []
    @State private var contextualInsights: [ContextualSleepInsight] = []
    @State private var sleepForecast: SleepForecast?
    @State private var patternAnalysis: SleepPatternAnalysis?
    @State private var isLoading = false
    @State private var selectedTab = 0
    
    public init() {}
    
    public var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Tab Selector
                Picker("Sleep Analysis", selection: $selectedTab) {
                    Text("Insights").tag(0)
                    Text("Forecast").tag(1)
                    Text("Patterns").tag(2)
                    Text("Optimization").tag(3)
                }
                .pickerStyle(.segmented)
                .padding()
                
                TabView(selection: $selectedTab) {
                    // Insights Tab
                    SleepInsightsTabView(
                        insights: sleepInsights,
                        contextualInsights: contextualInsights,
                        isLoading: isLoading
                    )
                    .tag(0)
                    
                    // Forecast Tab
                    SleepForecastTabView(
                        forecast: sleepForecast,
                        isLoading: isLoading
                    )
                    .tag(1)
                    
                    // Patterns Tab
                    SleepPatternsTabView(
                        patternAnalysis: patternAnalysis,
                        isLoading: isLoading
                    )
                    .tag(2)
                    
                    // Optimization Tab
                    SleepOptimizationTabView(
                        sleepEngine: sleepEngine,
                        isLoading: isLoading
                    )
                    .tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            .navigationTitle("Advanced Sleep AI")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Refresh") {
                        refreshData()
                    }
                    .disabled(isLoading)
                }
            }
        }
        .onAppear {
            refreshData()
        }
    }
    
    private func refreshData() {
        isLoading = true
        
        Task {
            async let insights = sleepEngine.getCurrentSleepInsights()
            async let contextual = sleepEngine.getContextualSleepInsights()
            async let forecast = try? sleepEngine.generateAdvancedSleepForecast()
            async let patterns = sleepEngine.getAdvancedSleepPatternAnalysis()
            
            sleepInsights = await insights
            contextualInsights = await contextual
            sleepForecast = await forecast
            patternAnalysis = await patterns
            
            isLoading = false
        }
    }
}

// MARK: - Tab Views

struct SleepInsightsTabView: View {
    let insights: [SleepInsight]
    let contextualInsights: [ContextualSleepInsight]
    let isLoading: Bool
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                if isLoading {
                    ProgressView("Analyzing sleep data...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    // Contextual Insights Section
                    if !contextualInsights.isEmpty {
                        SectionHeaderView(title: "AI-Powered Insights")
                        
                        ForEach(contextualInsights.prefix(3), id: \.title) { insight in
                            ContextualInsightCard(insight: insight)
                        }
                    }
                    
                    // Traditional Insights Section
                    if !insights.isEmpty {
                        SectionHeaderView(title: "Sleep Insights")
                        
                        ForEach(insights.prefix(4), id: \.title) { insight in
                            SleepInsightCard(insight: insight)
                        }
                    }
                    
                    if contextualInsights.isEmpty && insights.isEmpty {
                        EmptyStateView(
                            title: "No Insights Available",
                            message: "Sleep for a few nights to get personalized insights",
                            icon: "brain.head.profile"
                        )
                    }
                }
            }
            .padding()
        }
    }
}

struct SleepForecastTabView: View {
    let forecast: SleepForecast?
    let isLoading: Bool
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                if isLoading {
                    ProgressView("Generating forecast...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let forecast = forecast {
                    SectionHeaderView(title: "24-Hour Sleep Forecast")
                    
                    // Forecast confidence indicator
                    ConfidenceIndicatorView(confidence: forecast.confidence)
                    
                    // Hourly predictions
                    SleepForecastChart(predictions: forecast.predictions)
                    
                    // Key recommendations
                    SectionHeaderView(title: "Recommendations")
                    
                    ForEach(forecast.predictions.prefix(6), id: \.timestep) { prediction in
                        SleepPredictionCard(prediction: prediction)
                    }
                } else {
                    EmptyStateView(
                        title: "Forecast Unavailable",
                        message: "Need more sleep data to generate accurate forecasts",
                        icon: "chart.line.uptrend.xyaxis"
                    )
                }
            }
            .padding()
        }
    }
}

struct SleepPatternsTabView: View {
    let patternAnalysis: SleepPatternAnalysis?
    let isLoading: Bool
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                if isLoading {
                    ProgressView("Analyzing patterns...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let analysis = patternAnalysis {
                    // Dominant Patterns
                    if !analysis.dominantPatterns.isEmpty {
                        SectionHeaderView(title: "Sleep Patterns")
                        
                        ForEach(analysis.dominantPatterns.prefix(3), id: \.id) { pattern in
                            SleepPatternCard(pattern: pattern)
                        }
                    }
                    
                    // Temporal Dependencies
                    if !analysis.temporalDependencies.isEmpty {
                        SectionHeaderView(title: "Sleep Dependencies")
                        
                        ForEach(analysis.temporalDependencies.prefix(3), id: \.fromTimestep) { dependency in
                            TemporalDependencyCard(dependency: dependency)
                        }
                    }
                    
                    // Anomalies
                    if !analysis.anomalies.isEmpty {
                        SectionHeaderView(title: "Sleep Anomalies")
                        
                        ForEach(analysis.anomalies.prefix(3), id: \.timestep) { anomaly in
                            SleepAnomalyCard(anomaly: anomaly)
                        }
                    }
                } else {
                    EmptyStateView(
                        title: "Pattern Analysis Unavailable",
                        message: "Collect at least a week of sleep data for pattern analysis",
                        icon: "waveform.path.ecg"
                    )
                }
            }
            .padding()
        }
    }
}

struct SleepOptimizationTabView: View {
    let sleepEngine: SleepIntelligenceEngine
    let isLoading: Bool
    @State private var optimizations: [SleepOptimization] = []
    @State private var bedtimeRecommendation: SleepRecommendation?
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                if isLoading {
                    ProgressView("Optimizing sleep...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    // Bedtime Recommendation
                    if let recommendation = bedtimeRecommendation {
                        SectionHeaderView(title: "Optimal Bedtime")
                        BedtimeRecommendationCard(recommendation: recommendation)
                    }
                    
                    // Sleep Optimizations
                    if !optimizations.isEmpty {
                        SectionHeaderView(title: "Optimization Suggestions")
                        
                        ForEach(optimizations.prefix(5), id: \.suggestion) { optimization in
                            SleepOptimizationCard(optimization: optimization)
                        }
                    }
                    
                    if bedtimeRecommendation == nil && optimizations.isEmpty {
                        EmptyStateView(
                            title: "No Optimizations Available",
                            message: "Continue tracking sleep to get personalized optimizations",
                            icon: "slider.horizontal.3"
                        )
                    }
                }
            }
            .padding()
        }
        .onAppear {
            loadOptimizations()
        }
    }
    
    private func loadOptimizations() {
        Task {
            do {
                async let opts = try sleepEngine.generateSleepOptimizations()
                async let bedtime = try sleepEngine.predictOptimalBedtime()
                
                optimizations = await opts
                bedtimeRecommendation = await bedtime
            } catch {
                print("Failed to load optimizations: \(error)")
            }
        }
    }
}

// MARK: - Card Views

struct ContextualInsightCard: View {
    let insight: ContextualSleepInsight
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: iconForInsightType(insight.type))
                    .foregroundStyle(colorForInsightType(insight.type))
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(insight.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("Confidence: \(Int(insight.confidence * 100))%")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                ImportanceIndicator(importance: insight.importance)
            }
            
            Text(insight.description)
                .font(.body)
                .foregroundStyle(.primary)
            
            if !insight.explanation.isEmpty {
                Text(insight.explanation)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)
            }
            
            if !insight.recommendations.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Recommendations:")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                    
                    ForEach(insight.recommendations.prefix(3), id: \.self) { recommendation in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "lightbulb.fill")
                                .foregroundStyle(.yellow)
                                .font(.caption)
                            
                            Text(recommendation)
                                .font(.caption)
                                .foregroundStyle(.primary)
                        }
                    }
                }
                .padding(.top, 8)
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
    
    private func iconForInsightType(_ type: ContextualSleepInsight.InsightType) -> String {
        switch type {
        case .sleepQuality: return "heart.fill"
        case .circadianRhythm: return "sun.max.fill"
        case .environment: return "house.fill"
        case .lifestyle: return "figure.walk"
        }
    }
    
    private func colorForInsightType(_ type: ContextualSleepInsight.InsightType) -> Color {
        switch type {
        case .sleepQuality: return .blue
        case .circadianRhythm: return .orange
        case .environment: return .green
        case .lifestyle: return .purple
        }
    }
}

struct SleepInsightCard: View {
    let insight: SleepInsight
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: iconForCategory(insight.category))
                .foregroundStyle(colorForCategory(insight.category))
                .font(.title2)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(insight.title)
                    .font(.headline)
                    .fontWeight(.medium)
                
                Text(insight.description)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
            }
            
            Spacer()
            
            ConfidenceBar(confidence: insight.confidence)
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
    }
    
    private func iconForCategory(_ category: SleepInsight.Category) -> String {
        switch category {
        case .quality: return "star.fill"
        case .duration: return "clock.fill"
        case .timing: return "calendar.circle.fill"
        case .environment: return "thermometer"
        }
    }
    
    private func colorForCategory(_ category: SleepInsight.Category) -> Color {
        switch category {
        case .quality: return .blue
        case .duration: return .green
        case .timing: return .orange
        case .environment: return .teal
        }
    }
}

struct SleepForecastChart: View {
    let predictions: [SleepPrediction]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Sleep Stage Forecast")
                .font(.headline)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(predictions.prefix(24), id: \.timestep) { prediction in
                        VStack(spacing: 4) {
                            Text("\(prediction.timestep)h")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            
                            Rectangle()
                                .fill(colorForSleepStage(prediction.predictedStage))
                                .frame(width: 20, height: 40)
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                            
                            Text(stageAbbreviation(prediction.predictedStage))
                                .font(.caption2)
                                .fontWeight(.medium)
                        }
                    }
                }
                .padding(.horizontal)
            }
            
            // Legend
            HStack(spacing: 16) {
                ForEach(SleepStage.allCases, id: \.self) { stage in
                    HStack(spacing: 4) {
                        Circle()
                            .fill(colorForSleepStage(stage))
                            .frame(width: 8, height: 8)
                        
                        Text(stage.rawValue.capitalized)
                            .font(.caption2)
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
    
    private func colorForSleepStage(_ stage: SleepStage) -> Color {
        switch stage {
        case .awake: return .red
        case .light: return .blue
        case .deep: return .indigo
        case .rem: return .purple
        }
    }
    
    private func stageAbbreviation(_ stage: SleepStage) -> String {
        switch stage {
        case .awake: return "A"
        case .light: return "L"
        case .deep: return "D"
        case .rem: return "R"
        }
    }
}

struct SleepPredictionCard: View {
    let prediction: SleepPrediction
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(spacing: 4) {
                Text("+\(prediction.timestep)h")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                
                Circle()
                    .fill(colorForSleepStage(prediction.predictedStage))
                    .frame(width: 20, height: 20)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("\(prediction.predictedStage.rawValue.capitalized) Sleep")
                    .font(.headline)
                    .fontWeight(.medium)
                
                Text("Quality Score: \(Int(prediction.qualityScore * 100))%")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                
                if !prediction.environmentalRecommendations.isEmpty {
                    Text(prediction.environmentalRecommendations.first!)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .lineLimit(2)
                }
            }
            
            Spacer()
            
            VStack(spacing: 2) {
                Text("\(Int(prediction.stageConfidence * 100))%")
                    .font(.caption)
                    .fontWeight(.bold)
                
                Text("confidence")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
    }
    
    private func colorForSleepStage(_ stage: SleepStage) -> Color {
        switch stage {
        case .awake: return .red
        case .light: return .blue
        case .deep: return .indigo
        case .rem: return .purple
        }
    }
}

// MARK: - Helper Views

struct SectionHeaderView: View {
    let title: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
            
            Spacer()
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }
}

struct ImportanceIndicator: View {
    let importance: Double
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(importance >= Double(index + 1) / 3.0 ? .orange : .gray.opacity(0.3))
                    .frame(width: 6, height: 6)
            }
        }
    }
}

struct ConfidenceBar: View {
    let confidence: Double
    
    var body: some View {
        VStack(spacing: 2) {
            Rectangle()
                .fill(.gray.opacity(0.2))
                .frame(width: 4, height: 40)
                .overlay(alignment: .bottom) {
                    Rectangle()
                        .fill(.blue)
                        .frame(height: 40 * confidence)
                }
                .clipShape(Capsule())
            
            Text("\(Int(confidence * 100))%")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

struct ConfidenceIndicatorView: View {
    let confidence: Double
    
    var body: some View {
        HStack {
            Text("Forecast Confidence")
                .font(.headline)
            
            Spacer()
            
            Text("\(Int(confidence * 100))%")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(confidenceColor)
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
    }
    
    private var confidenceColor: Color {
        if confidence >= 0.8 { return .green }
        if confidence >= 0.6 { return .orange }
        return .red
    }
}

struct EmptyStateView: View {
    let title: String
    let message: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            
            VStack(spacing: 8) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(message)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// Additional card views for patterns, dependencies, etc.
struct SleepPatternCard: View {
    let pattern: SleepPattern
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Pattern Strength: \(Int(pattern.strength * 100))%")
                    .font(.headline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text("×\(pattern.frequency)")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(.blue.opacity(0.2), in: Capsule())
            }
            
            Text(pattern.description)
                .font(.callout)
                .foregroundStyle(.secondary)
            
            HStack {
                Text("Quality Score: \(Int(pattern.sleepQualityScore * 100))%")
                    .font(.caption)
                
                Spacer()
                
                Text("Duration: \(formatDuration(pattern.duration))")
                    .font(.caption)
            }
            .foregroundStyle(.tertiary)
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        return "\(hours)h \(minutes)m"
    }
}

struct TemporalDependencyCard: View {
    let dependency: TemporalDependency
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(spacing: 4) {
                Text("\(dependency.fromTimestep)")
                    .font(.caption)
                    .fontWeight(.medium)
                
                Image(systemName: "arrow.down")
                    .font(.caption)
                    .foregroundStyle(.blue)
                
                Text("\(dependency.toTimestep)")
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
            .background(.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
            
            VStack(alignment: .leading, spacing: 4) {
                Text("\(dependency.type)")
                    .font(.headline)
                    .fontWeight(.medium)
                
                Text("Dependency strength: \(Int(dependency.strength * 100))%")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
    }
}

struct SleepAnomalyCard: View {
    let anomaly: SleepAnomaly
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
                .font(.title2)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Timestep \(anomaly.timestep)")
                    .font(.headline)
                    .fontWeight(.medium)
                
                Text(anomaly.description)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                
                Text("Deviation: \(Int(anomaly.deviationScore * 100))%")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            
            Spacer()
        }
        .padding()
        .background(.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
    }
}

struct BedtimeRecommendationCard: View {
    let recommendation: SleepRecommendation
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "moon.stars.fill")
                    .foregroundStyle(.indigo)
                    .font(.title)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Optimal Bedtime")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text(recommendation.recommendedBedtime.formatted(date: .omitted, time: .shortened))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.indigo)
                }
                
                Spacer()
                
                VStack(spacing: 2) {
                    Text("\(Int(recommendation.confidence * 100))%")
                        .font(.title3)
                        .fontWeight(.bold)
                    
                    Text("confidence")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Text(recommendation.reasoning)
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.leading)
        }
        .padding()
        .background(.indigo.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
    }
}

struct SleepOptimizationCard: View {
    let optimization: SleepOptimization
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: iconForOptimizationType(optimization.type))
                .foregroundStyle(colorForOptimizationType(optimization.type))
                .font(.title2)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(optimization.suggestion)
                    .font(.callout)
                    .fontWeight(.medium)
                
                HStack {
                    Text("Expected improvement: \(Int(optimization.expectedImprovement * 100))%")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    Text("\(optimization.source)")
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.gray.opacity(0.2), in: Capsule())
                }
            }
            
            ConfidenceBar(confidence: optimization.confidence)
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
    }
    
    private func iconForOptimizationType(_ type: SleepOptimization.OptimizationType) -> String {
        switch type {
        case .bedtimeAdjustment: return "clock.arrow.2.circlepath"
        case .scheduleOptimization: return "calendar.badge.clock"
        case .environmentalControl: return "thermometer.sun.fill"
        case .relaxationTechnique: return "leaf.fill"
        }
    }
    
    private func colorForOptimizationType(_ type: SleepOptimization.OptimizationType) -> Color {
        switch type {
        case .bedtimeAdjustment: return .blue
        case .scheduleOptimization: return .green
        case .environmentalControl: return .orange
        case .relaxationTechnique: return .mint
        }
    }
}

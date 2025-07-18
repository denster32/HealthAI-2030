import SwiftUI
import Charts
import Combine

/// Advanced Health Prediction View
/// Provides comprehensive health predictions with real-time visualization
@available(iOS 18.0, macOS 15.0, *)
struct AdvancedHealthPredictionView: View {
    @StateObject private var predictionEngine: AdvancedHealthPredictionEngine
    @State private var selectedPredictionType: PredictionType = .cardiovascular
    @State private var showingPredictionDetail = false
    @State private var selectedPrediction: Any?
    @State private var isGeneratingPredictions = false
    @State private var lastPredictionTime: Date?
    
    init(analyticsEngine: AnalyticsEngine) {
        self._predictionEngine = StateObject(wrappedValue: AdvancedHealthPredictionEngine(analyticsEngine: analyticsEngine))
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    headerView
                    
                    // Prediction Type Selector
                    predictionTypeSelector
                    
                    // Current Predictions
                    currentPredictionsView
                    
                    // Prediction Details
                    predictionDetailsView
                    
                    // Historical Trends
                    historicalTrendsView
                }
                .padding()
            }
            .navigationTitle("Health Predictions")
            .navigationBarTitleDisplayMode(.large)
            .background(Color(.systemGroupedBackground))
            .sheet(isPresented: $showingPredictionDetail) {
                if let prediction = selectedPrediction {
                    PredictionDetailView(prediction: prediction, type: selectedPredictionType)
                }
            }
            .onAppear {
                generatePredictions()
            }
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Advanced Health Predictions")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("AI-powered health insights and predictions")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: generatePredictions) {
                    HStack(spacing: 8) {
                        if isGeneratingPredictions {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "arrow.clockwise")
                        }
                        Text("Refresh")
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.blue)
                    .cornerRadius(20)
                }
                .disabled(isGeneratingPredictions)
            }
            
            // Last update time
            if let lastUpdate = lastPredictionTime {
                HStack {
                    Image(systemName: "clock")
                        .foregroundColor(.secondary)
                    Text("Last updated: \(lastUpdate.formatted(date: .abbreviated, time: .shortened))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Error display
            if let error = predictionEngine.lastError {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
    
    // MARK: - Prediction Type Selector
    private var predictionTypeSelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Prediction Types")
                .font(.headline)
                .foregroundColor(.primary)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(PredictionType.allCases, id: \.self) { type in
                    PredictionTypeCard(
                        type: type,
                        isSelected: selectedPredictionType == type,
                        prediction: getPrediction(for: type)
                    ) {
                        selectedPredictionType = type
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
    
    // MARK: - Current Predictions View
    private var currentPredictionsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Current Predictions")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                if let cardiovascular = predictionEngine.cardiovascularRisk {
                    CardiovascularPredictionCard(prediction: cardiovascular) {
                        selectedPrediction = cardiovascular
                        selectedPredictionType = .cardiovascular
                        showingPredictionDetail = true
                    }
                }
                
                if let sleep = predictionEngine.sleepQualityForecast {
                    SleepQualityPredictionCard(prediction: sleep) {
                        selectedPrediction = sleep
                        selectedPredictionType = .sleep
                        showingPredictionDetail = true
                    }
                }
                
                if let stress = predictionEngine.stressPatternPrediction {
                    StressPatternPredictionCard(prediction: stress) {
                        selectedPrediction = stress
                        selectedPredictionType = .stress
                        showingPredictionDetail = true
                    }
                }
                
                if let trajectory = predictionEngine.healthTrajectory {
                    HealthTrajectoryPredictionCard(prediction: trajectory) {
                        selectedPrediction = trajectory
                        selectedPredictionType = .trajectory
                        showingPredictionDetail = true
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
    
    // MARK: - Prediction Details View
    private var predictionDetailsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Prediction Details")
                .font(.headline)
                .foregroundColor(.primary)
            
            switch selectedPredictionType {
            case .cardiovascular:
                if let prediction = predictionEngine.cardiovascularRisk {
                    CardiovascularDetailView(prediction: prediction)
                }
            case .sleep:
                if let prediction = predictionEngine.sleepQualityForecast {
                    SleepQualityDetailView(prediction: prediction)
                }
            case .stress:
                if let prediction = predictionEngine.stressPatternPrediction {
                    StressPatternDetailView(prediction: prediction)
                }
            case .trajectory:
                if let prediction = predictionEngine.healthTrajectory {
                    HealthTrajectoryDetailView(prediction: prediction)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
    
    // MARK: - Historical Trends View
    private var historicalTrendsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Historical Trends")
                .font(.headline)
                .foregroundColor(.primary)
            
            // Placeholder for historical trends chart
            VStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 48))
                    .foregroundColor(.secondary)
                
                Text("Historical trends will be displayed here")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(height: 200)
            .frame(maxWidth: .infinity)
            .background(Color(.systemGray6))
            .cornerRadius(8)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
    
    // MARK: - Helper Methods
    private func generatePredictions() {
        isGeneratingPredictions = true
        
        Task {
            do {
                let _ = try await predictionEngine.generatePredictions()
                await MainActor.run {
                    lastPredictionTime = Date()
                    isGeneratingPredictions = false
                }
            } catch {
                await MainActor.run {
                    isGeneratingPredictions = false
                }
            }
        }
    }
    
    private func getPrediction(for type: PredictionType) -> Any? {
        switch type {
        case .cardiovascular:
            return predictionEngine.cardiovascularRisk
        case .sleep:
            return predictionEngine.sleepQualityForecast
        case .stress:
            return predictionEngine.stressPatternPrediction
        case .trajectory:
            return predictionEngine.healthTrajectory
        }
    }
}

// MARK: - Supporting Views

struct PredictionTypeCard: View {
    let type: PredictionType
    let isSelected: Bool
    let prediction: Any?
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                Image(systemName: type.icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : type.color)
                
                Text(type.title)
                    .font(.headline)
                    .foregroundColor(isSelected ? .white : .primary)
                
                Text(type.description)
                    .font(.caption)
                    .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                    .multilineTextAlignment(.center)
                
                if let prediction = prediction {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(isSelected ? .white : .green)
                        Text("Available")
                            .font(.caption)
                            .foregroundColor(isSelected ? .white : .green)
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(isSelected ? type.color : Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct CardiovascularPredictionCard: View {
    let prediction: CardiovascularRiskPrediction
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "heart.fill")
                            .foregroundColor(.red)
                        Text("Cardiovascular Risk")
                            .font(.headline)
                            .foregroundColor(.primary)
                    }
                    
                    Text("Risk Score: \(Int(prediction.riskScore * 100))%")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("Confidence: \(Int(prediction.confidence * 100))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(prediction.riskCategory.displayName)
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(prediction.riskCategory.color.opacity(0.2))
                        .foregroundColor(prediction.riskCategory.color)
                        .cornerRadius(8)
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SleepQualityPredictionCard: View {
    let prediction: SleepQualityForecast
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "bed.double.fill")
                            .foregroundColor(.purple)
                        Text("Sleep Quality")
                            .font(.headline)
                            .foregroundColor(.primary)
                    }
                    
                    Text("Quality Score: \(Int(prediction.qualityScore * 100))%")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("Duration: \(String(format: "%.1f", prediction.predictedDuration))h")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(sleepQualityCategory.displayName)
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(sleepQualityCategory.color.opacity(0.2))
                        .foregroundColor(sleepQualityCategory.color)
                        .cornerRadius(8)
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var sleepQualityCategory: SleepQualityCategory {
        switch prediction.qualityScore {
        case 0.8...: return .excellent
        case 0.6..<0.8: return .good
        case 0.4..<0.6: return .fair
        default: return .poor
        }
    }
}

struct StressPatternPredictionCard: View {
    let prediction: StressPatternPrediction
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "brain.head.profile")
                            .foregroundColor(.orange)
                        Text("Stress Pattern")
                            .font(.headline)
                            .foregroundColor(.primary)
                    }
                    
                    Text("Stress Level: \(Int(prediction.stressLevel * 100))%")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    if !prediction.triggers.isEmpty {
                        Text("Triggers: \(prediction.triggers.prefix(2).joined(separator: ", "))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(stressCategory.displayName)
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(stressCategory.color.opacity(0.2))
                        .foregroundColor(stressCategory.color)
                        .cornerRadius(8)
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var stressCategory: StressCategory {
        switch prediction.stressLevel {
        case 0..<0.3: return .low
        case 0.3..<0.6: return .moderate
        case 0.6..<0.8: return .high
        default: return .critical
        }
    }
}

struct HealthTrajectoryPredictionCard: View {
    let prediction: HealthTrajectoryPrediction
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .foregroundColor(.green)
                        Text("Health Trajectory")
                            .font(.headline)
                            .foregroundColor(.primary)
                    }
                    
                    Text("Trajectory: \(prediction.trajectory)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("Confidence: \(Int(prediction.confidence * 100))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("6-12 months")
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.2))
                        .foregroundColor(.blue)
                        .cornerRadius(8)
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Detail Views

struct CardiovascularDetailView: View {
    let prediction: CardiovascularRiskPrediction
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Risk Score Chart
            VStack(alignment: .leading, spacing: 8) {
                Text("Risk Score")
                    .font(.headline)
                
                HStack {
                    Text("\(Int(prediction.riskScore * 100))%")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(prediction.riskCategory.color)
                    
                    Spacer()
                    
                    Text("Confidence: \(Int(prediction.confidence * 100))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                ProgressView(value: prediction.riskScore)
                    .progressViewStyle(LinearProgressViewStyle(tint: prediction.riskCategory.color))
            }
            
            // Risk Factors
            if !prediction.riskFactors.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Risk Factors")
                        .font(.headline)
                    
                    ForEach(prediction.riskFactors, id: \.self) { factor in
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text(factor)
                                .font(.body)
                            Spacer()
                        }
                    }
                }
            }
            
            // Recommendations
            if !prediction.recommendations.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Recommendations")
                        .font(.headline)
                    
                    ForEach(prediction.recommendations, id: \.self) { recommendation in
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text(recommendation)
                                .font(.body)
                            Spacer()
                        }
                    }
                }
            }
        }
    }
}

struct SleepQualityDetailView: View {
    let prediction: SleepQualityForecast
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Quality Score
            VStack(alignment: .leading, spacing: 8) {
                Text("Sleep Quality Score")
                    .font(.headline)
                
                HStack {
                    Text("\(Int(prediction.qualityScore * 100))%")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(sleepQualityCategory.color)
                    
                    Spacer()
                }
                
                ProgressView(value: prediction.qualityScore)
                    .progressViewStyle(LinearProgressViewStyle(tint: sleepQualityCategory.color))
            }
            
            // Sleep Metrics
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Predicted Duration")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(String(format: "%.1f", prediction.predictedDuration))h")
                        .font(.headline)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Predicted Efficiency")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(Int(prediction.predictedEfficiency * 100))%")
                        .font(.headline)
                }
            }
            
            // Recommendations
            if !prediction.recommendations.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Recommendations")
                        .font(.headline)
                    
                    ForEach(prediction.recommendations, id: \.self) { recommendation in
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text(recommendation)
                                .font(.body)
                            Spacer()
                        }
                    }
                }
            }
        }
    }
    
    private var sleepQualityCategory: SleepQualityCategory {
        switch prediction.qualityScore {
        case 0.8...: return .excellent
        case 0.6..<0.8: return .good
        case 0.4..<0.6: return .fair
        default: return .poor
        }
    }
}

struct StressPatternDetailView: View {
    let prediction: StressPatternPrediction
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Stress Level
            VStack(alignment: .leading, spacing: 8) {
                Text("Stress Level")
                    .font(.headline)
                
                HStack {
                    Text("\(Int(prediction.stressLevel * 100))%")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(stressCategory.color)
                    
                    Spacer()
                }
                
                ProgressView(value: prediction.stressLevel)
                    .progressViewStyle(LinearProgressViewStyle(tint: stressCategory.color))
            }
            
            // Triggers
            if !prediction.triggers.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Stress Triggers")
                        .font(.headline)
                    
                    ForEach(prediction.triggers, id: \.self) { trigger in
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text(trigger)
                                .font(.body)
                            Spacer()
                        }
                    }
                }
            }
            
            // Recommendations
            if !prediction.recommendations.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Recommendations")
                        .font(.headline)
                    
                    ForEach(prediction.recommendations, id: \.self) { recommendation in
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text(recommendation)
                                .font(.body)
                            Spacer()
                        }
                    }
                }
            }
        }
    }
    
    private var stressCategory: StressCategory {
        switch prediction.stressLevel {
        case 0..<0.3: return .low
        case 0.3..<0.6: return .moderate
        case 0.6..<0.8: return .high
        default: return .critical
        }
    }
}

struct HealthTrajectoryDetailView: View {
    let prediction: HealthTrajectoryPrediction
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Trajectory
            VStack(alignment: .leading, spacing: 8) {
                Text("Health Trajectory")
                    .font(.headline)
                
                Text(prediction.trajectory)
                    .font(.title2)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text("6-12 month prediction")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Confidence
            VStack(alignment: .leading, spacing: 8) {
                Text("Prediction Confidence")
                    .font(.headline)
                
                HStack {
                    Text("\(Int(prediction.confidence * 100))%")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                    
                    Spacer()
                }
                
                ProgressView(value: prediction.confidence)
                    .progressViewStyle(LinearProgressViewStyle(tint: .blue))
            }
            
            // Interventions
            if !prediction.interventions.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Recommended Interventions")
                        .font(.headline)
                    
                    ForEach(prediction.interventions, id: \.self) { intervention in
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text(intervention)
                                .font(.body)
                            Spacer()
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Supporting Types

enum PredictionType: CaseIterable {
    case cardiovascular, sleep, stress, trajectory
    
    var title: String {
        switch self {
        case .cardiovascular: return "Cardiovascular"
        case .sleep: return "Sleep Quality"
        case .stress: return "Stress Pattern"
        case .trajectory: return "Health Trajectory"
        }
    }
    
    var description: String {
        switch self {
        case .cardiovascular: return "Heart health risk assessment"
        case .sleep: return "Sleep quality forecasting"
        case .stress: return "Stress pattern analysis"
        case .trajectory: return "Long-term health outlook"
        }
    }
    
    var icon: String {
        switch self {
        case .cardiovascular: return "heart.fill"
        case .sleep: return "bed.double.fill"
        case .stress: return "brain.head.profile"
        case .trajectory: return "chart.line.uptrend.xyaxis"
        }
    }
    
    var color: Color {
        switch self {
        case .cardiovascular: return .red
        case .sleep: return .purple
        case .stress: return .orange
        case .trajectory: return .green
        }
    }
}

extension CardiovascularRiskPrediction.RiskCategory {
    var displayName: String {
        switch self {
        case .low: return "Low Risk"
        case .moderate: return "Moderate Risk"
        case .high: return "High Risk"
        case .critical: return "Critical Risk"
        }
    }
    
    var color: Color {
        switch self {
        case .low: return .green
        case .moderate: return .yellow
        case .high: return .orange
        case .critical: return .red
        }
    }
}

enum SleepQualityCategory {
    case excellent, good, fair, poor
    
    var displayName: String {
        switch self {
        case .excellent: return "Excellent"
        case .good: return "Good"
        case .fair: return "Fair"
        case .poor: return "Poor"
        }
    }
    
    var color: Color {
        switch self {
        case .excellent: return .green
        case .good: return .blue
        case .fair: return .yellow
        case .poor: return .red
        }
    }
}

enum StressCategory {
    case low, moderate, high, critical
    
    var displayName: String {
        switch self {
        case .low: return "Low"
        case .moderate: return "Moderate"
        case .high: return "High"
        case .critical: return "Critical"
        }
    }
    
    var color: Color {
        switch self {
        case .low: return .green
        case .moderate: return .yellow
        case .high: return .orange
        case .critical: return .red
        }
    }
}

// MARK: - Detail View Wrapper

struct PredictionDetailView: View {
    let prediction: Any
    let type: PredictionType
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    switch type {
                    case .cardiovascular:
                        if let cardiovascular = prediction as? CardiovascularRiskPrediction {
                            CardiovascularDetailView(prediction: cardiovascular)
                        }
                    case .sleep:
                        if let sleep = prediction as? SleepQualityForecast {
                            SleepQualityDetailView(prediction: sleep)
                        }
                    case .stress:
                        if let stress = prediction as? StressPatternPrediction {
                            StressPatternDetailView(prediction: stress)
                        }
                    case .trajectory:
                        if let trajectory = prediction as? HealthTrajectoryPrediction {
                            HealthTrajectoryDetailView(prediction: trajectory)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle(type.title)
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

#Preview {
    AdvancedHealthPredictionView(analyticsEngine: AnalyticsEngine())
} 
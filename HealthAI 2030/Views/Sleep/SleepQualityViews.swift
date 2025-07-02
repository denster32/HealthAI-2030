import SwiftUI
import HealthKit
import AVFoundation
import CoreHaptics
import Combine
import os.log

// MARK: - Sleep Quality Metrics
struct SleepQualityMetrics: View {
    @StateObject private var aiEngine = AISleepAnalysisEngine.shared
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .font(.title2)
                    .foregroundColor(.purple)
                
                Text("Sleep Quality")
                    .font(.headline)
                
                Spacer()
            }
            
            if let prediction = aiEngine.lastPrediction {
                VStack(spacing: 12) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Overall Quality")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(Int(prediction.sleepQuality * 100))%")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(qualityColor(prediction.sleepQuality))
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing) {
                            Text("Stage Quality")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(Int(prediction.stageProbability * 100))%")
                                .font(.title3)
                                .fontWeight(.bold)
                        }
                    }
                    
                    ProgressView(value: prediction.sleepQuality)
                        .progressViewStyle(LinearProgressViewStyle(tint: qualityColor(prediction.sleepQuality)))
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    private func qualityColor(_ quality: Double) -> Color {
        if quality >= 0.8 { return .green }
        else if quality >= 0.6 { return .orange }
        else { return .red }
    }
}

// MARK: - AI Recommendations
struct AIRecommendations: View {
    @StateObject private var aiEngine = AISleepAnalysisEngine.shared
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .font(.title2)
                    .foregroundColor(.yellow)
                
                Text("AI Recommendations")
                    .font(.headline)
                
                Spacer()
            }
            
            if let prediction = aiEngine.lastPrediction, !prediction.recommendations.isEmpty {
                VStack(spacing: 8) {
                    ForEach(prediction.recommendations.prefix(3), id: \.message) { recommendation in
                        HStack {
                            Image(systemName: recommendationIcon(recommendation.type))
                                .foregroundColor(recommendationColor(recommendation.priority))
                            
                            Text(recommendation.message)
                                .font(.caption)
                                .foregroundColor(.primary)
                            
                            Spacer()
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(recommendationColor(recommendation.priority).opacity(0.1))
                        .cornerRadius(8)
                    }
                }
            } else {
                Text("No recommendations at this time")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func recommendationIcon(_ type: RecommendationType) -> String {
        switch type {
        case .stressReduction: return "heart.fill"
        case .relaxation: return "leaf.fill"
        case .comfort: return "bed.double.fill"
        case .environment: return "house.fill"
        case .schedule: return "clock.fill"
        case .healthAlert: return "exclamationmark.triangle.fill"
        }
    }
    
    private func recommendationColor(_ priority: Priority) -> Color {
        switch priority {
        case .low: return .blue
        case .medium: return .orange
        case .high: return .red
        }
    }
}

// MARK: - ML Model Status
struct MLModelStatus: View {
    @StateObject private var aiEngine = AISleepAnalysisEngine.shared
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .font(.title2)
                    .foregroundColor(.blue)
                
                Text("ML Model Status")
                    .font(.headline)
                
                Spacer()
                
                Button("Retrain") {
                    Task {
                        await aiEngine.retrainModel()
                    }
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            
            let status = aiEngine.getStatus()
            
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Model Accuracy")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(Int(status.modelAccuracy * 100))%")
                            .font(.title3)
                            .fontWeight(.bold)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        Text("Data Points")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(status.dataPoints)")
                            .font(.title3)
                            .fontWeight(.bold)
                    }
                }
                
                HStack {
                    VStack(alignment: .leading) {
                        Text("Predictions")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(status.predictions)")
                            .font(.title3)
                            .fontWeight(.bold)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        Text("Personalization")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(Int(status.personalizationLevel * 100))%")
                            .font(.title3)
                            .fontWeight(.bold)
                    }
                }
                
                ProgressView(value: status.modelAccuracy)
                    .progressViewStyle(LinearProgressViewStyle(tint: .blue))
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

// MARK: - Supporting Views
struct SleepStageIcon: View {
    let stage: SleepStage
    
    var body: some View {
        Image(systemName: stageIconName)
            .font(.title)
            .foregroundColor(stageColor)
    }
    
    private var stageIconName: String {
        switch stage {
        case .awake: return "eye.fill"
        case .light: return "moon.fill"
        case .deep: return "bed.double.fill"
        case .rem: return "brain.head.profile"
        }
    }
    
    private var stageColor: Color {
        switch stage {
        case .awake: return .orange
        case .light: return .blue
        case .deep: return .purple
        case .rem: return .green
        }
    }
}

struct StageProbabilitiesView: View {
    let probabilities: [SleepStage: Double]
    
    var body: some View {
        VStack(spacing: 8) {
            ForEach(SleepStage.allCases, id: \.self) { stage in
                if let probability = probabilities[stage] {
                    HStack {
                        SleepStageIcon(stage: stage)
                            .font(.caption)
                        
                        Text(stage.displayName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("\(Int(probability * 100))%")
                            .font(.caption)
                            .fontWeight(.semibold)
                        
                        ProgressView(value: probability)
                            .progressViewStyle(LinearProgressViewStyle(tint: stageColor(stage)))
                            .frame(width: 60)
                    }
                }
            }
        }
    }
    
    private func stageColor(_ stage: SleepStage) -> Color {
        switch stage {
        case .awake: return .orange
        case .light: return .blue
        case .deep: return .purple
        case .rem: return .green
        }
    }
}


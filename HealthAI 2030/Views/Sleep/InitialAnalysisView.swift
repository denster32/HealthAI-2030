import SwiftUI
import HealthKit
import AVFoundation
import CoreHaptics
import Combine
import os.log

// MARK: - Initial Analysis View
struct InitialAnalysisView: View {
    @StateObject private var dataManager = DataManager.shared
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 16) {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                Text("Setting Up Your Personal AI")
                    .font(.title)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text("SomnaSync Pro is analyzing your historical sleep data to create a personalized AI model just for you.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            // Progress Section
        VStack(spacing: 16) {
            HStack {
                    Text("Analysis Progress")
                        .font(.headline)
                    
                    Spacer()
                    
                    Text("\(Int(dataManager.historicalAnalysisProgress * 100))%")
                        .font(.headline)
                        .foregroundColor(.blue)
                }
                
                ProgressView(value: dataManager.historicalAnalysisProgress)
                    .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                    .scaleEffect(y: 2)
                
                // Progress Details
                VStack(spacing: 8) {
                    ProgressStep(
                        title: "Requesting Permissions",
                        isCompleted: dataManager.historicalAnalysisProgress >= 0.1,
                        isActive: dataManager.historicalAnalysisProgress >= 0.0 && dataManager.historicalAnalysisProgress < 0.2
                    )
                    
                    ProgressStep(
                        title: "Analyzing Sleep Data",
                        isCompleted: dataManager.historicalAnalysisProgress >= 0.5,
                        isActive: dataManager.historicalAnalysisProgress >= 0.2 && dataManager.historicalAnalysisProgress < 0.5
                    )
                    
                    ProgressStep(
                        title: "Processing Biometrics",
                        isCompleted: dataManager.historicalAnalysisProgress >= 0.8,
                        isActive: dataManager.historicalAnalysisProgress >= 0.5 && dataManager.historicalAnalysisProgress < 0.8
                    )
                    
                    ProgressStep(
                        title: "Establishing Baseline",
                        isCompleted: dataManager.historicalAnalysisProgress >= 1.0,
                        isActive: dataManager.historicalAnalysisProgress >= 0.8 && dataManager.historicalAnalysisProgress < 1.0
                    )
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            
            // Data Points Counter
            if dataManager.historicalDataPoints > 0 {
                VStack(spacing: 8) {
                    Text("Data Points Analyzed")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("\(dataManager.historicalDataPoints)")
                    .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(radius: 2)
            }
            
            // Status Message
            VStack(spacing: 8) {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(.blue)
                
                Text("This process only happens once and helps create your personalized sleep AI. The more data available, the better your personalized experience will be.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
        .padding()
    }
}

// MARK: - Progress Step
struct ProgressStep: View {
    let title: String
    let isCompleted: Bool
    let isActive: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            // Status Icon
            Image(systemName: statusIcon)
                .foregroundColor(statusColor)
                .font(.system(size: 16, weight: .semibold))
            
            // Title
            Text(title)
                .font(.subheadline)
                .foregroundColor(isActive ? .primary : .secondary)
            
            Spacer()
            
            // Progress indicator for active step
            if isActive {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                    .scaleEffect(0.8)
            }
        }
        .padding(.vertical, 4)
    }
    
    private var statusIcon: String {
        if isCompleted {
            return "checkmark.circle.fill"
        } else if isActive {
            return "circle.fill"
        } else {
            return "circle"
        }
    }
    
    private var statusColor: Color {
        if isCompleted {
            return .green
        } else if isActive {
            return .blue
        } else {
            return .gray
        }
    }
}


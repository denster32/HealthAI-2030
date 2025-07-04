import SwiftUI
import HealthKit
import AVFoundation
import CoreHaptics
import Combine
import os.log

// MARK: - AI Status Header
struct AIStatusHeader: View {
    @StateObject private var aiEngine = AISleepAnalysisEngine.shared
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: aiEngine.isInitialized ? "brain.head.profile" : "brain.head.profile.fill")
                    .font(.title2)
                    .foregroundColor(aiEngine.isInitialized ? .somnaAccent : .orange)
                    .scaleEffect(isAnimating ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: isAnimating)
                
                VStack(alignment: .leading) {
                    Text("AI Sleep Analysis")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text(aiEngine.isInitialized ? "Active & Learning" : "Initializing...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .opacity(isAnimating ? 0.7 : 1.0)
                        .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: isAnimating)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("\(Int(aiEngine.modelAccuracy * 100))%")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.somnaPrimary)
                        .scaleEffect(isAnimating ? 1.05 : 1.0)
                        .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isAnimating)
                    
                    Text("Accuracy")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Personalization Progress
            HStack {
                Text("Personalization")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(Int(aiEngine.personalizationLevel * 100))%")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.somnaSecondary)
            }
            
            ProgressView(value: aiEngine.personalizationLevel)
                .progressViewStyle(LinearProgressViewStyle(tint: .somnaSecondary))
                .scaleEffect(y: 1.5)
                .animation(.easeInOut(duration: 0.5), value: aiEngine.personalizationLevel)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.somnaCardBackground)
                .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    LinearGradient(
                        colors: [.somnaPrimary.opacity(0.3), .somnaSecondary.opacity(0.3)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .onAppear {
            isAnimating = true
        }
        .onTapGesture {
            HapticManager.shared.impact(style: .light)
        }
    }
}

// MARK: - Current Sleep Status
struct CurrentSleepStatus: View {
    @StateObject private var sleepManager = SleepManager.shared
    @StateObject private var aiEngine = AISleepAnalysisEngine.shared
    @State private var isPulsing = false
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                    Text("Current Status")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                
                Spacer()
                
                if aiEngine.anomalyDetected {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                            .scaleEffect(isPulsing ? 1.2 : 1.0)
                            .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isPulsing)
                        Text("Anomaly Detected")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.orange)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(8)
                }
            }
            
            if let prediction = aiEngine.lastPrediction {
                VStack(spacing: 12) {
                    HStack {
                        SleepStageIcon(stage: prediction.sleepStage)
                            .scaleEffect(isPulsing ? 1.1 : 1.0)
                            .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: isPulsing)
                        
                        VStack(alignment: .leading) {
                            Text(prediction.sleepStage.displayName)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            
                            Text("Confidence: \(Int(prediction.confidence * 100))%")
                                .font(.caption)
                                .foregroundColor(.secondary)
                }
                
                Spacer()
                
                        VStack(alignment: .trailing) {
                            Text("Quality")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text("\(Int(prediction.sleepQuality * 100))%")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(prediction.isHighQuality ? .somnaAccent : .orange)
                                .scaleEffect(isPulsing ? 1.05 : 1.0)
                                .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: isPulsing)
                        }
                    }
                    
                    // Stage Probabilities
                    StageProbabilitiesView(probabilities: prediction.probabilities)
                }
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "bed.double")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                        .opacity(0.6)
                    
                    Text("No sleep data available")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("Start tracking to see your sleep analysis")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
            }
                .padding(.vertical, 20)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.somnaCardBackground)
                .shadow(color: .black.opacity(0.2), radius: 6, x: 0, y: 3)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    LinearGradient(
                        colors: [.somnaPrimary.opacity(0.2), .somnaSecondary.opacity(0.2)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .onAppear {
            isPulsing = true
        }
        .onTapGesture {
            HapticManager.shared.impact(style: .light)
        }
    }
}

// MARK: - ML Prediction Card
struct MLPredictionCard: View {
    @StateObject private var aiEngine = AISleepAnalysisEngine.shared
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .font(.title2)
                    .foregroundColor(.blue)
                
                Text("ML Predictions")
                    .font(.headline)
                
                Spacer()
                
                Button("Details") {
                    // Show ML details
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            
            if let prediction = aiEngine.lastPrediction {
                VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading) {
                            Text("Predicted Stage")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            Text(prediction.sleepStage.displayName)
                                .font(.title3)
                                .fontWeight(.bold)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing) {
                            Text("Probability")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(Int(prediction.stageProbability * 100))%")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                        }
                    }
                    
                    if prediction.isConfident {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("High confidence prediction")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                    } else {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text("Low confidence - collecting more data")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Smart Alarm Controls
struct SmartAlarmControls: View {
    @StateObject private var smartAlarm = SmartAlarmSystem.shared
    @State private var targetTime = Date()
    @State private var selectedFlexibility = WakeFlexibility.medium
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "alarm")
                            .font(.title2)
                    .foregroundColor(.orange)
                
                Text("Smart Alarm")
                    .font(.headline)
                
                Spacer()
                
                if smartAlarm.isActive {
                    Text("Active")
                        .font(.caption)
                        .foregroundColor(.green)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.2))
                        .cornerRadius(8)
                }
            }
            
            if smartAlarm.isActive {
                VStack(spacing: 12) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Target Time")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(smartAlarm.targetWakeTime, style: .time)
                                .font(.title3)
                                .fontWeight(.bold)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                            Text("Optimal Time")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            Text(smartAlarm.optimalWakeTime, style: .time)
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                        }
                    }
                    
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Confidence")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(Int(smartAlarm.confidence * 100))%")
                                .font(.title3)
                                .fontWeight(.bold)
                        }
                        
                        Spacer()
                        
                        Button("Stop Tracking") {
                            Task {
                                await smartAlarm.stopSleepTracking()
                            }
                        }
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
            } else {
                VStack(spacing: 12) {
                    DatePicker("Target Wake Time", selection: $targetTime, displayedComponents: .hourAndMinute)
                        .datePickerStyle(CompactDatePickerStyle())
                    
                    Picker("Flexibility", selection: $selectedFlexibility) {
                        ForEach(WakeFlexibility.allCases, id: \.self) { flexibility in
                            Text(flexibility.rawValue).tag(flexibility)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    
                    Button("Start Smart Alarm") {
                        Task {
                            await smartAlarm.startSleepTracking()
                            await smartAlarm.setSmartAlarm(targetTime: targetTime, flexibility: selectedFlexibility)
                        }
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(12)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}


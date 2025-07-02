import SwiftUI
import HealthKit
import AVFoundation
import CoreHaptics
import Combine
import os.log

// MARK: - SleepScoreHeader
struct SleepScoreHeader: View {
    @ObservedObject var sleepManager: SleepManager
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Sleep Score")
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text("Last 7 days")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Text("\(sleepManager.sleepScore)")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(.blue)
            }
            
            ProgressView(value: Double(sleepManager.sleepScore) / 100.0)
                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - SleepSessionControls
struct SleepSessionControls: View {
    @ObservedObject var sleepManager: SleepManager
    @Binding var showingSession: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "bed.double.fill")
                    .foregroundColor(.blue)
                Text("Sleep Session")
                .font(.headline)
                Spacer()
            }
            
            HStack(spacing: 20) {
                Button(action: {
                    Task {
                            await sleepManager.startSleepSession()
                    }
                }) {
                    HStack {
                        Image(systemName: "play.fill")
                        Text("Start Session")
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                
                Button(action: { showingSession = true }) {
                    HStack {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                        Text("View Session")
                    }
                    .padding()
                    .background(Color(.systemGray5))
                    .foregroundColor(.primary)
                    .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - SmartAlarmSection
struct SmartAlarmSection: View {
    @ObservedObject var smartAlarm: SmartAlarmSystem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "alarm.fill")
                    .foregroundColor(.orange)
                Text("Smart Alarm")
                    .font(.headline)
                Spacer()
                Toggle("", isOn: $smartAlarm.isEnabled)
                    }
                    
            if smartAlarm.isEnabled {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Target Wake Time:")
                        Spacer()
                        Text(smartAlarm.targetWakeTime, style: .time)
                            .fontWeight(.medium)
                    }
                    
                    HStack {
                        Text("Optimal Wake Window:")
                        Spacer()
                        Text("\(smartAlarm.optimalWakeWindow) min")
                            .fontWeight(.medium)
                    }
                    
                    HStack {
                        Text("Confidence:")
                        Spacer()
                        Text("\(Int(smartAlarm.wakeConfidence * 100))%")
                            .fontWeight(.medium)
                            .foregroundColor(.green)
                    }
                }
                    }
                }
                .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - AppleWatchSection
struct AppleWatchSection: View {
    @ObservedObject var appleWatchManager: AppleWatchManager
    @Binding var showingSetup: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "applewatch")
                    .foregroundColor(.green)
                Text("Apple Watch")
                    .font(.headline)
                Spacer()
                if appleWatchManager.isConnected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                } else {
                    Button("Setup") {
                        showingSetup = true
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
            }
            
            if appleWatchManager.isConnected {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Heart Rate:")
                        Spacer()
                        Text("\(appleWatchManager.currentHeartRate) BPM")
                            .fontWeight(.medium)
                    }
                    
                    HStack {
                        Text("Sleep Tracking:")
                        Spacer()
                        Text(appleWatchManager.isSleepTracking ? "Active" : "Inactive")
                            .fontWeight(.medium)
                            .foregroundColor(appleWatchManager.isSleepTracking ? .green : .orange)
                    }
                }
            } else {
                Text("Connect your Apple Watch for enhanced sleep tracking and biometric monitoring.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - SleepInsightsSection
struct SleepInsightsSection: View {
    @ObservedObject var sleepManager: SleepManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .foregroundColor(.purple)
                Text("Sleep Insights")
                    .font(.headline)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 12) {
                InsightRow(
                    title: "Deep Sleep",
                    value: "\(sleepManager.deepSleepPercentage)%",
                    color: .blue
                )
                
                InsightRow(
                    title: "REM Sleep",
                    value: "\(sleepManager.remSleepPercentage)%",
                    color: .purple
                )
                
                InsightRow(
                    title: "Sleep Efficiency",
                    value: "\(sleepManager.sleepEfficiency)%",
                    color: .green
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - InsightRow
struct InsightRow: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
                .foregroundColor(color)
        }
    }
}

// MARK: - HealthDataSection
struct HealthDataSection: View {
    @ObservedObject var healthKitManager: HealthKitManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "heart.fill")
                    .foregroundColor(.red)
                Text("Health Data")
                    .font(.headline)
                Spacer()
                if healthKitManager.isAuthorized {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                } else {
                    Button("Authorize") {
                        Task {
                            await healthKitManager.requestPermissions()
                        }
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
            }
            
            if healthKitManager.isAuthorized {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Last Sleep Duration:")
                        Spacer()
                        Text(healthKitManager.lastSleepDuration)
                            .fontWeight(.medium)
                    }
                    
                    HStack {
                        Text("Average Sleep:")
                        Spacer()
                        Text(healthKitManager.averageSleepDuration)
                            .fontWeight(.medium)
                    }
                }
            } else {
                Text("Authorize HealthKit access to view your sleep data and receive personalized insights.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - HistoricalDataAnalysisOverlay
struct HistoricalDataAnalysisOverlay: View {
    let progress: Double
    let onComplete: () -> Void
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                ProgressView(value: progress)
                    .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                    .scaleEffect(1.5)
                
                Text("Analyzing Historical Sleep Data")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text("This helps us provide personalized sleep insights and recommendations.")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                
                Text("\(Int(progress * 100))%")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            .padding(40)
            .background(Color(.systemGray6).opacity(0.9))
            .cornerRadius(20)
        }
        .onChange(of: progress) { newProgress in
            if newProgress >= 1.0 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    onComplete()
                }
            }
        }
    }
}

// MARK: - SleepSessionView
struct SleepSessionView: View {
    @ObservedObject var sleepManager: SleepManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Sleep Session View")
                    .font(.title)
                Text("Detailed sleep session tracking and analysis")
                    .foregroundColor(.secondary)
            }
            .navigationTitle("Sleep Session")
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

// MARK: - AppleWatchSetupView
struct AppleWatchSetupView: View {
    @ObservedObject var appleWatchManager: AppleWatchManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Apple Watch Setup")
                    .font(.title)
                Text("Configure Apple Watch connectivity")
                    .foregroundColor(.secondary)
            }
            .navigationTitle("Apple Watch Setup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }

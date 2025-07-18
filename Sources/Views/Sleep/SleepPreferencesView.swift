import SwiftUI

/// Sleep Preferences View
/// Allows users to configure sleep goals, environment preferences, and optimization settings
@available(iOS 18.0, macOS 15.0, *)
public struct SleepPreferencesView: View {
    
    // MARK: - State
    @ObservedObject var sleepEngine: AdvancedSleepIntelligenceEngine
    @State private var targetBedtime = Date()
    @State private var targetWakeTime = Date()
    @State private var targetDuration: Double = 8.0
    @State private var environmentPreferences: SleepPreferences.SleepEnvironmentPreferences = .standard
    @State private var showingScheduleOptimization = false
    @State private var scheduleOptimization: SleepScheduleOptimization?
    
    // MARK: - Environment
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Body
    public var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection
                    
                    // Sleep Schedule
                    sleepScheduleSection
                    
                    // Sleep Duration
                    sleepDurationSection
                    
                    // Environment Preferences
                    environmentSection
                    
                    // Schedule Optimization
                    scheduleOptimizationSection
                    
                    // Action Buttons
                    actionSection
                }
                .padding()
            }
            .navigationTitle("Sleep Preferences")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        savePreferences()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .onAppear {
            loadCurrentPreferences()
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "bed.double.fill")
                .font(.system(size: 60))
                .foregroundColor(.indigo)
            
            Text("Sleep Preferences")
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            Text("Configure your sleep goals and preferences for personalized optimization recommendations.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
    
    // MARK: - Sleep Schedule Section
    private var sleepScheduleSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Sleep Schedule")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 16) {
                // Bedtime
                VStack(alignment: .leading, spacing: 8) {
                    Text("Target Bedtime")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    DatePicker("Bedtime", selection: $targetBedtime, displayedComponents: .hourAndMinute)
                        .datePickerStyle(WheelDatePickerStyle())
                        .labelsHidden()
                }
                
                // Wake Time
                VStack(alignment: .leading, spacing: 8) {
                    Text("Target Wake Time")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    DatePicker("Wake Time", selection: $targetWakeTime, displayedComponents: .hourAndMinute)
                        .datePickerStyle(WheelDatePickerStyle())
                        .labelsHidden()
                }
                
                // Schedule Summary
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Bedtime")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(targetBedtime, style: .time)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .center, spacing: 4) {
                        Text("Duration")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("\(Int(calculatedDuration))h")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(calculatedDuration >= 7.0 ? .green : .orange)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Wake Time")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(targetWakeTime, style: .time)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Sleep Duration Section
    private var sleepDurationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Target Sleep Duration")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 16) {
                HStack {
                    Text("\(targetDuration, specifier: "%.1f") hours")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(durationColor)
                    
                    Spacer()
                    
                    Text(durationDescription)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Slider(value: $targetDuration, in: 6.0...10.0, step: 0.5) { _ in
                    updateWakeTime()
                }
                .accentColor(.indigo)
                
                // Duration Guidelines
                VStack(alignment: .leading, spacing: 8) {
                    Text("Recommended Duration by Age:")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        DurationGuideline(age: "18-25", duration: "7-9 hours", isCurrent: targetDuration >= 7.0 && targetDuration <= 9.0)
                        DurationGuideline(age: "26-64", duration: "7-9 hours", isCurrent: targetDuration >= 7.0 && targetDuration <= 9.0)
                        DurationGuideline(age: "65+", duration: "7-8 hours", isCurrent: targetDuration >= 7.0 && targetDuration <= 8.0)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Environment Section
    private var environmentSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Environment Preferences")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ForEach(SleepPreferences.SleepEnvironmentPreferences.allCases, id: \.self) { preference in
                    EnvironmentPreferenceCard(
                        preference: preference,
                        isSelected: environmentPreferences == preference
                    ) {
                        environmentPreferences = preference
                    }
                }
            }
            
            // Environment Description
            Text(environmentDescription)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Schedule Optimization Section
    private var scheduleOptimizationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Schedule Optimization")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                Text("Get AI-powered recommendations for your optimal sleep schedule based on your sleep patterns and circadian rhythm.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
                
                Button("Optimize Schedule") {
                    optimizeSchedule()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                
                if let optimization = scheduleOptimization {
                    ScheduleOptimizationCard(optimization: optimization) {
                        applyOptimization(optimization)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Action Section
    private var actionSection: some View {
        VStack(spacing: 16) {
            Button("Save Preferences") {
                savePreferences()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            
            Button("Reset to Defaults") {
                resetToDefaults()
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
        }
    }
    
    // MARK: - Helper Methods
    private var calculatedDuration: Double {
        let duration = targetWakeTime.timeIntervalSince(targetBedtime) / 3600
        return duration > 0 ? duration : 24 + duration
    }
    
    private var durationColor: Color {
        if targetDuration >= 7.0 && targetDuration <= 9.0 {
            return .green
        } else if targetDuration >= 6.0 && targetDuration <= 10.0 {
            return .orange
        } else {
            return .red
        }
    }
    
    private var durationDescription: String {
        if targetDuration >= 7.0 && targetDuration <= 9.0 {
            return "Optimal for most adults"
        } else if targetDuration >= 6.0 && targetDuration <= 10.0 {
            return "Acceptable range"
        } else {
            return "May affect health"
        }
    }
    
    private var environmentDescription: String {
        switch environmentPreferences {
        case .standard:
            return "Balanced environment with moderate temperature, humidity, and lighting."
        case .cool:
            return "Cooler environment (65-68°F) for better sleep quality."
        case .warm:
            return "Warmer environment (70-73°F) for comfort."
        case .dark:
            return "Minimal lighting for optimal melatonin production."
        case .light:
            return "Gentle ambient lighting for relaxation."
        case .quiet:
            return "Minimal noise with white noise or silence."
        case .ambient:
            return "Natural ambient sounds for relaxation."
        }
    }
    
    private func loadCurrentPreferences() {
        let preferences = sleepEngine.getUserSleepPreferences()
        targetBedtime = preferences.targetBedtime
        targetWakeTime = preferences.targetWakeTime
        targetDuration = preferences.targetDuration
        environmentPreferences = preferences.environmentPreferences
    }
    
    private func updateWakeTime() {
        targetWakeTime = Calendar.current.date(byAdding: .hour, value: Int(targetDuration), to: targetBedtime) ?? targetWakeTime
    }
    
    private func optimizeSchedule() {
        Task {
            do {
                let optimization = try await sleepEngine.optimizeSleepSchedule()
                await MainActor.run {
                    self.scheduleOptimization = optimization
                }
            } catch {
                print("Failed to optimize schedule: \(error)")
            }
        }
    }
    
    private func applyOptimization(_ optimization: SleepScheduleOptimization) {
        if let schedule = optimization.recommendedSchedule {
            targetBedtime = schedule.bedtime
            targetWakeTime = schedule.wakeTime
            targetDuration = schedule.duration
        }
    }
    
    private func savePreferences() {
        let preferences = SleepPreferences(
            targetBedtime: targetBedtime,
            targetWakeTime: targetWakeTime,
            targetDuration: targetDuration,
            environmentPreferences: environmentPreferences
        )
        
        Task {
            await sleepEngine.setSleepPreferences(preferences)
            await MainActor.run {
                dismiss()
            }
        }
    }
    
    private func resetToDefaults() {
        targetBedtime = Calendar.current.date(bySettingHour: 22, minute: 0, second: 0, of: Date()) ?? Date()
        targetWakeTime = Calendar.current.date(bySettingHour: 7, minute: 0, second: 0, of: Date()) ?? Date()
        targetDuration = 8.0
        environmentPreferences = .standard
    }
}

// MARK: - Supporting Views

struct DurationGuideline: View {
    let age: String
    let duration: String
    let isCurrent: Bool
    
    var body: some View {
        HStack {
            Text("\(age): \(duration)")
                .font(.caption)
                .foregroundColor(.primary)
            
            Spacer()
            
            if isCurrent {
                Image(systemName: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundColor(.green)
            }
        }
    }
}

struct EnvironmentPreferenceCard: View {
    let preference: SleepPreferences.SleepEnvironmentPreferences
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: preferenceIcon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : .indigo)
                
                Text(preference.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .primary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isSelected ? Color.indigo : Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var preferenceIcon: String {
        switch preference {
        case .standard: return "house.fill"
        case .cool: return "thermometer.snowflake"
        case .warm: return "thermometer.sun"
        case .dark: return "moon.fill"
        case .light: return "lightbulb.fill"
        case .quiet: return "speaker.slash"
        case .ambient: return "speaker.wave.2"
        }
    }
}

struct ScheduleOptimizationCard: View {
    let optimization: SleepScheduleOptimization
    let onApply: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .font(.title2)
                    .foregroundColor(.indigo)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("AI Recommendation")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("Confidence: \(Int(optimization.confidence * 100))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            if let schedule = optimization.recommendedSchedule {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Bedtime")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(schedule.bedtime, style: .time)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .center, spacing: 4) {
                        Text("Duration")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("\(Int(schedule.duration))h")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.green)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Wake Time")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(schedule.wakeTime, style: .time)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                }
            }
            
            Text(optimization.reasoning)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Button("Apply Recommendation") {
                onApply()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Extensions

extension SleepPreferences.SleepEnvironmentPreferences {
    var displayName: String {
        switch self {
        case .standard: return "Standard"
        case .cool: return "Cool"
        case .warm: return "Warm"
        case .dark: return "Dark"
        case .light: return "Light"
        case .quiet: return "Quiet"
        case .ambient: return "Ambient"
        }
    }
}

// MARK: - Preview
#Preview {
    SleepPreferencesView(sleepEngine: AdvancedSleepIntelligenceEngine(
        healthDataManager: HealthDataManager(),
        predictionEngine: AdvancedHealthPredictionEngine(),
        analyticsEngine: AnalyticsEngine()
    ))
} 
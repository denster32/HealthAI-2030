import SwiftUI
import Charts

/// Advanced sleep mitigation dashboard with comprehensive sleep optimization features
struct AdvancedSleepMitigationView: View {
    @StateObject private var sleepEngine = AdvancedSleepMitigationEngine()
    @State private var selectedTab = 0
    @State private var showingSoundProfileSheet = false
    @State private var showingEnvironmentSheet = false
    @State private var showingSmartHomeSheet = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Tab Selection
                tabSelectionView
                
                // Content
                TabView(selection: $selectedTab) {
                    sleepDashboardView
                        .tag(0)
                    
                    circadianRhythmView
                        .tag(1)
                    
                    hapticFeedbackView
                        .tag(2)
                    
                    soundProfilesView
                        .tag(3)
                    
                    environmentView
                        .tag(4)
                    
                    smartHomeView
                        .tag(5)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingSoundProfileSheet) {
            soundProfileSheet
        }
        .sheet(isPresented: $showingEnvironmentSheet) {
            environmentSheet
        }
        .sheet(isPresented: $showingSmartHomeSheet) {
            smartHomeSheet
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Sleep Optimization")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Advanced sleep enhancement system")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: {
                    sleepEngine.startSleepOptimization()
                }) {
                    Image(systemName: "moon.fill")
                        .font(.title3)
                        .foregroundColor(.blue)
                }
                
                Button(action: {
                    sleepEngine.stopAllOptimizations()
                }) {
                    Image(systemName: "stop.fill")
                        .font(.title3)
                        .foregroundColor(.red)
                }
            }
            
            // Sleep Quality Score
            sleepQualityScore
        }
        .padding()
        .background(Color(.systemBackground))
    }
    
    private var sleepQualityScore: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Sleep Quality")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("\(Int(sleepEngine.sleepQuality * 100))%")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(sleepQualityColor)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("Current Stage")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(sleepEngine.currentSleepStage.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(sleepStageColor)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Tab Selection
    private var tabSelectionView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 20) {
                ForEach(["Dashboard", "Circadian", "Haptics", "Sounds", "Environment", "Smart Home"], id: \.self) { tab in
                    Button(action: {
                        withAnimation {
                            selectedTab = ["Dashboard", "Circadian", "Haptics", "Sounds", "Environment", "Smart Home"].firstIndex(of: tab) ?? 0
                        }
                    }) {
                        VStack(spacing: 4) {
                            Text(tab)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(selectedTab == ["Dashboard", "Circadian", "Haptics", "Sounds", "Environment", "Smart Home"].firstIndex(of: tab) ? .blue : .secondary)
                            
                            Rectangle()
                                .fill(selectedTab == ["Dashboard", "Circadian", "Haptics", "Sounds", "Environment", "Smart Home"].firstIndex(of: tab) ? Color.blue : Color.clear)
                                .frame(height: 2)
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
        .background(Color(.systemBackground))
    }
    
    // MARK: - Sleep Dashboard
    private var sleepDashboardView: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                // Sleep Stage
                SleepStageCard(
                    stage: sleepEngine.currentSleepStage,
                    quality: sleepEngine.sleepQuality
                )
                
                // Circadian Phase
                CircadianPhaseCard(
                    phase: sleepEngine.circadianPhase
                )
                
                // Environment
                EnvironmentCard(
                    settings: sleepEngine.environmentSettings
                )
                
                // Haptic Feedback
                HapticFeedbackCard(
                    intensity: sleepEngine.hapticIntensity
                )
                
                // Audio
                AudioCard(
                    volume: sleepEngine.audioVolume
                )
                
                // Recommendations
                RecommendationsCard(
                    recommendations: sleepEngine.optimizationRecommendations
                )
            }
            .padding()
        }
    }
    
    // MARK: - Circadian Rhythm View
    private var circadianRhythmView: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Circadian Phase Chart
                CircadianPhaseChart(phase: sleepEngine.circadianPhase)
                
                // Light Exposure History
                LightExposureHistoryView()
                
                // Sleep Schedule
                SleepScheduleView()
                
                // Optimization Controls
                CircadianOptimizationControls()
            }
            .padding()
        }
    }
    
    // MARK: - Haptic Feedback View
    private var hapticFeedbackView: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Haptic Intensity Control
                HapticIntensityControl(intensity: $sleepEngine.hapticIntensity)
                
                // Haptic Pattern Selection
                HapticPatternSelection()
                
                // Haptic Preview
                HapticPreviewCard()
                
                // Custom Patterns
                CustomHapticPatterns()
            }
            .padding()
        }
    }
    
    // MARK: - Sound Profiles View
    private var soundProfilesView: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Current Profile
                CurrentSoundProfileCard()
                
                // Profile Selection
                SoundProfileSelection()
                
                // Audio Controls
                AudioControls(volume: $sleepEngine.audioVolume)
                
                // Binaural Beats
                BinauralBeatsControl()
            }
            .padding()
        }
    }
    
    // MARK: - Environment View
    private var environmentView: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Temperature Control
                TemperatureControl(settings: $sleepEngine.environmentSettings)
                
                // Humidity Control
                HumidityControl(settings: $sleepEngine.environmentSettings)
                
                // Light Control
                LightControl(settings: $sleepEngine.environmentSettings)
                
                // Noise Control
                NoiseControl(settings: $sleepEngine.environmentSettings)
            }
            .padding()
        }
    }
    
    // MARK: - Smart Home View
    private var smartHomeView: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Device Status
                SmartDeviceStatusView()
                
                // Automation Rules
                AutomationRulesView()
                
                // Device Control
                SmartDeviceControlView()
                
                // Integration Settings
                IntegrationSettingsView()
            }
            .padding()
        }
    }
    
    // MARK: - Sheet Views
    private var soundProfileSheet: some View {
        NavigationView {
            SoundProfileEditorView()
                .navigationTitle("Sound Profile")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            showingSoundProfileSheet = false
                        }
                    }
                }
        }
    }
    
    private var environmentSheet: some View {
        NavigationView {
            EnvironmentEditorView()
                .navigationTitle("Environment Settings")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            showingEnvironmentSheet = false
                        }
                    }
                }
        }
    }
    
    private var smartHomeSheet: some View {
        NavigationView {
            SmartHomeEditorView()
                .navigationTitle("Smart Home")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            showingSmartHomeSheet = false
                        }
                    }
                }
        }
    }
    
    // MARK: - Computed Properties
    private var sleepQualityColor: Color {
        let quality = sleepEngine.sleepQuality
        if quality >= 0.8 { return .green }
        else if quality >= 0.6 { return .yellow }
        else { return .red }
    }
    
    private var sleepStageColor: Color {
        switch sleepEngine.currentSleepStage {
        case .deepSleep: return .green
        case .remSleep: return .blue
        case .lightSleep: return .yellow
        case .fallingAsleep: return .orange
        case .wakeUp: return .red
        case .awake: return .gray
        }
    }
}

// MARK: - Supporting Views
struct SleepStageCard: View {
    let stage: SleepStage
    let quality: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: stage.icon)
                    .font(.title2)
                    .foregroundColor(stage.color)
                
                Spacer()
                
                Text("\(Int(quality * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(stage.displayName)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(stage.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct CircadianPhaseCard: View {
    let phase: CircadianPhase
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: phase.icon)
                    .font(.title2)
                    .foregroundColor(phase.color)
                
                Spacer()
                
                Text(phase.timeRange)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(phase.displayName)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(phase.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct EnvironmentCard: View {
    let settings: EnvironmentSettings
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "thermometer")
                    .font(.title2)
                    .foregroundColor(.blue)
                
                Spacer()
                
                Text("\(Int(settings.temperature))°C")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Environment")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text("\(Int(settings.humidity))% humidity")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct HapticFeedbackCard: View {
    let intensity: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "iphone.radiowaves.left.and.right")
                    .font(.title2)
                    .foregroundColor(.purple)
                
                Spacer()
                
                Text("\(Int(intensity * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Haptic Feedback")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text("Gentle pulses for relaxation")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct AudioCard: View {
    let volume: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "speaker.wave.3")
                    .font(.title2)
                    .foregroundColor(.green)
                
                Spacer()
                
                Text("\(Int(volume * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Sleep Sounds")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text("Therapeutic audio for sleep")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct RecommendationsCard: View {
    let recommendations: [SleepOptimizationRecommendation]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "lightbulb")
                    .font(.title2)
                    .foregroundColor(.yellow)
                
                Spacer()
                
                Text("\(recommendations.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Recommendations")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                if let firstRecommendation = recommendations.first {
                    Text(firstRecommendation.title)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                } else {
                    Text("No recommendations")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Additional Views (Placeholder implementations)
struct CircadianPhaseChart: View {
    let phase: CircadianPhase
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Circadian Rhythm")
                .font(.headline)
                .fontWeight(.semibold)
            
            // Placeholder for chart
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.blue.opacity(0.1))
                .frame(height: 200)
                .overlay(
                    Text("Circadian Phase Chart")
                        .foregroundColor(.secondary)
                )
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct LightExposureHistoryView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Light Exposure History")
                .font(.headline)
                .fontWeight(.semibold)
            
            // Placeholder for light exposure history
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.yellow.opacity(0.1))
                .frame(height: 150)
                .overlay(
                    Text("Light Exposure Chart")
                        .foregroundColor(.secondary)
                )
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct SleepScheduleView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Sleep Schedule")
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Bedtime")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("10:00 PM")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Wake Time")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("7:00 AM")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct CircadianOptimizationControls: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Optimization Controls")
                .font(.headline)
                .fontWeight(.semibold)
            
            Button("Optimize Circadian Rhythm") {
                // Implementation
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Placeholder Views for Other Sections
struct HapticIntensityControl: View {
    @Binding var intensity: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Haptic Intensity")
                .font(.headline)
                .fontWeight(.semibold)
            
            Slider(value: $intensity, in: 0...1)
            Text("\(Int(intensity * 100))%")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct HapticPatternSelection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Haptic Patterns")
                .font(.headline)
                .fontWeight(.semibold)
            
            // Placeholder for pattern selection
            Text("Pattern selection interface")
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct HapticPreviewCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Haptic Preview")
                .font(.headline)
                .fontWeight(.semibold)
            
            Button("Test Pattern") {
                // Implementation
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct CustomHapticPatterns: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Custom Patterns")
                .font(.headline)
                .fontWeight(.semibold)
            
            // Placeholder for custom patterns
            Text("Custom pattern creation interface")
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct CurrentSoundProfileCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Current Sound Profile")
                .font(.headline)
                .fontWeight(.semibold)
            
            Text("Default Profile")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct SoundProfileSelection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Sound Profiles")
                .font(.headline)
                .fontWeight(.semibold)
            
            // Placeholder for profile selection
            Text("Profile selection interface")
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct AudioControls: View {
    @Binding var volume: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Audio Controls")
                .font(.headline)
                .fontWeight(.semibold)
            
            Slider(value: $volume, in: 0...1)
            Text("Volume: \(Int(volume * 100))%")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct BinauralBeatsControl: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Binaural Beats")
                .font(.headline)
                .fontWeight(.semibold)
            
            Toggle("Enable Binaural Beats", isOn: .constant(true))
            Text("0.5 Hz for deep sleep")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct TemperatureControl: View {
    @Binding var settings: EnvironmentSettings
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Temperature Control")
                .font(.headline)
                .fontWeight(.semibold)
            
            Slider(value: $settings.temperature, in: 16...24)
            Text("\(Int(settings.temperature))°C")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct HumidityControl: View {
    @Binding var settings: EnvironmentSettings
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Humidity Control")
                .font(.headline)
                .fontWeight(.semibold)
            
            Slider(value: $settings.humidity, in: 30...70)
            Text("\(Int(settings.humidity))%")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct LightControl: View {
    @Binding var settings: EnvironmentSettings
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Light Control")
                .font(.headline)
                .fontWeight(.semibold)
            
            Slider(value: $settings.lightLevel, in: 0...1)
            Text("Light Level: \(Int(settings.lightLevel * 100))%")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct NoiseControl: View {
    @Binding var settings: EnvironmentSettings
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Noise Control")
                .font(.headline)
                .fontWeight(.semibold)
            
            Slider(value: $settings.noiseLevel, in: 0...1)
            Text("Noise Level: \(Int(settings.noiseLevel * 100))%")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct SmartDeviceStatusView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Smart Device Status")
                .font(.headline)
                .fontWeight(.semibold)
            
            // Placeholder for device status
            Text("Device status interface")
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct AutomationRulesView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Automation Rules")
                .font(.headline)
                .fontWeight(.semibold)
            
            // Placeholder for automation rules
            Text("Automation rules interface")
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct SmartDeviceControlView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Device Control")
                .font(.headline)
                .fontWeight(.semibold)
            
            // Placeholder for device control
            Text("Device control interface")
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct IntegrationSettingsView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Integration Settings")
                .font(.headline)
                .fontWeight(.semibold)
            
            // Placeholder for integration settings
            Text("Integration settings interface")
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Sheet Views (Placeholder implementations)
struct SoundProfileEditorView: View {
    var body: some View {
        Text("Sound Profile Editor")
            .padding()
    }
}

struct EnvironmentEditorView: View {
    var body: some View {
        Text("Environment Editor")
            .padding()
    }
}

struct SmartHomeEditorView: View {
    var body: some View {
        Text("Smart Home Editor")
            .padding()
    }
}

// MARK: - Extensions
extension SleepStage {
    var displayName: String {
        switch self {
        case .awake: return "Awake"
        case .fallingAsleep: return "Falling Asleep"
        case .lightSleep: return "Light Sleep"
        case .deepSleep: return "Deep Sleep"
        case .remSleep: return "REM Sleep"
        case .wakeUp: return "Wake Up"
        }
    }
    
    var description: String {
        switch self {
        case .awake: return "Fully conscious"
        case .fallingAsleep: return "Transitioning to sleep"
        case .lightSleep: return "Light sleep phase"
        case .deepSleep: return "Deep restorative sleep"
        case .remSleep: return "Rapid eye movement"
        case .wakeUp: return "Waking up"
        }
    }
    
    var icon: String {
        switch self {
        case .awake: return "eye"
        case .fallingAsleep: return "bed.double"
        case .lightSleep: return "moon"
        case .deepSleep: return "moon.fill"
        case .remSleep: return "eye.fill"
        case .wakeUp: return "sunrise"
        }
    }
    
    var color: Color {
        switch self {
        case .awake: return .gray
        case .fallingAsleep: return .orange
        case .lightSleep: return .yellow
        case .deepSleep: return .green
        case .remSleep: return .blue
        case .wakeUp: return .red
        }
    }
}

extension CircadianPhase {
    var displayName: String {
        switch self {
        case .morning: return "Morning"
        case .afternoon: return "Afternoon"
        case .evening: return "Evening"
        case .night: return "Night"
        case .day: return "Day"
        }
    }
    
    var description: String {
        switch self {
        case .morning: return "High energy, activity"
        case .afternoon: return "Peak productivity"
        case .evening: return "Wind down, prepare"
        case .night: return "Sleep optimization"
        case .day: return "General optimization"
        }
    }
    
    var icon: String {
        switch self {
        case .morning: return "sunrise"
        case .afternoon: return "sun.max"
        case .evening: return "sunset"
        case .night: return "moon"
        case .day: return "sun.min"
        }
    }
    
    var color: Color {
        switch self {
        case .morning: return .orange
        case .afternoon: return .yellow
        case .evening: return .red
        case .night: return .blue
        case .day: return .green
        }
    }
    
    var timeRange: String {
        switch self {
        case .morning: return "6AM-12PM"
        case .afternoon: return "12PM-6PM"
        case .evening: return "6PM-10PM"
        case .night: return "10PM-6AM"
        case .day: return "All Day"
        }
    }
}

// MARK: - Preview
struct AdvancedSleepMitigationView_Previews: PreviewProvider {
    static var previews: some View {
        AdvancedSleepMitigationView()
    }
} 
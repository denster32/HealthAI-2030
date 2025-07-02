import SwiftUI
import HomeKit

struct EnvironmentView: View {
    @StateObject private var environmentManager = EnvironmentManager.shared
    @State private var showingOptimizationOptions = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Current Environment Status
                    EnvironmentStatusCard()
                    
                    // Optimization Controls
                    OptimizationControlsCard()
                    
                    // Environment Controls
                    EnvironmentControlsSection()
                    
                    // Air Quality Health
                    AirQualityHealthCard()
                    
                    // Recommendations
                    EnvironmentRecommendationsCard()
                }
                .padding()
            }
            .navigationTitle("Environment")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Optimize") {
                        showingOptimizationOptions = true
                    }
                }
            }
            .actionSheet(isPresented: $showingOptimizationOptions) {
                ActionSheet(
                    title: Text("Environment Optimization"),
                    buttons: [
                        .default(Text("Sleep Mode")) {
                            environmentManager.optimizeForSleep()
                        },
                        .default(Text("Work Mode")) {
                            environmentManager.optimizeForWork()
                        },
                        .default(Text("Exercise Mode")) {
                            environmentManager.optimizeForExercise()
                        },
                        .destructive(Text("Stop Optimization")) {
                            environmentManager.stopOptimization()
                        },
                        .cancel()
                    ]
                )
            }
        }
    }
}

struct EnvironmentStatusCard: View {
    @ObservedObject private var environmentManager = EnvironmentManager.shared
    
    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "thermometer")
                        .foregroundColor(.orange)
                    Text("Current Environment")
                        .font(.headline)
                    Spacer()
                    if environmentManager.isOptimizationActive {
                        Label("Active", systemImage: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                    }
                }
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                    EnvironmentMetric(
                        title: "Temperature",
                        value: "\(environmentManager.currentTemperature, specifier: "%.1f")°C",
                        icon: "thermometer",
                        color: .orange
                    )
                    
                    EnvironmentMetric(
                        title: "Humidity",
                        value: "\(environmentManager.currentHumidity, specifier: "%.0f")%",
                        icon: "humidity",
                        color: .blue
                    )
                    
                    EnvironmentMetric(
                        title: "Air Quality",
                        value: "\(environmentManager.airQuality * 100, specifier: "%.0f")%",
                        icon: "wind",
                        color: environmentManager.airQuality > 0.8 ? .green : .yellow
                    )
                    
                    EnvironmentMetric(
                        title: "Noise Level",
                        value: "\(environmentManager.noiseLevel, specifier: "%.0f") dB",
                        icon: "speaker.wave.2",
                        color: environmentManager.noiseLevel < 50 ? .green : .orange
                    )
                }
            }
        }
    }
}

struct OptimizationControlsCard: View {
    @ObservedObject private var environmentManager = EnvironmentManager.shared
    
    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "wand.and.stars")
                        .foregroundColor(.purple)
                    Text("Environment Optimization")
                        .font(.headline)
                    Spacer()
                }
                
                Text("Current Mode: \(environmentManager.currentOptimizationMode.displayName)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 12) {
                    OptimizationButton(
                        title: "Sleep",
                        icon: "bed.double.fill",
                        isActive: environmentManager.currentOptimizationMode == .sleep
                    ) {
                        environmentManager.optimizeForSleep()
                    }
                    
                    OptimizationButton(
                        title: "Work",
                        icon: "desktopcomputer",
                        isActive: environmentManager.currentOptimizationMode == .work
                    ) {
                        environmentManager.optimizeForWork()
                    }
                    
                    OptimizationButton(
                        title: "Exercise",
                        icon: "figure.run",
                        isActive: environmentManager.currentOptimizationMode == .exercise
                    ) {
                        environmentManager.optimizeForExercise()
                    }
                }
            }
        }
    }
}

struct EnvironmentControlsSection: View {
    @ObservedObject private var environmentManager = EnvironmentManager.shared
    @State private var targetTemperature: Double = 22.0
    @State private var targetHumidity: Double = 50.0
    @State private var lightingIntensity: Double = 0.8
    
    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Image(systemName: "slider.horizontal.3")
                        .foregroundColor(.blue)
                    Text("Manual Controls")
                        .font(.headline)
                    Spacer()
                }
                
                VStack(spacing: 16) {
                    ControlSlider(
                        title: "Temperature",
                        value: $targetTemperature,
                        range: 16...26,
                        unit: "°C",
                        icon: "thermometer"
                    ) {
                        environmentManager.adjustTemperature(target: targetTemperature)
                    }
                    
                    ControlSlider(
                        title: "Humidity",
                        value: $targetHumidity,
                        range: 30...70,
                        unit: "%",
                        icon: "humidity"
                    ) {
                        environmentManager.adjustHumidity(target: targetHumidity)
                    }
                    
                    ControlSlider(
                        title: "Lighting",
                        value: $lightingIntensity,
                        range: 0...1,
                        unit: "",
                        icon: "lightbulb"
                    ) {
                        environmentManager.adjustLighting(intensity: lightingIntensity)
                    }
                }
            }
        }
    }
}

struct AirQualityHealthCard: View {
    @ObservedObject private var environmentManager = EnvironmentManager.shared
    
    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "lungs")
                        .foregroundColor(.green)
                    Text("Air Quality Health")
                        .font(.headline)
                    Spacer()
                }
                
                let airQualityHealth = environmentManager.checkAirQualityHealth()
                
                if airQualityHealth.hasAlerts() {
                    ForEach(airQualityHealth.getAlerts().indices, id: \.self) { index in
                        let alert = airQualityHealth.getAlerts()[index]
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(alert.severity == .high ? .red : .orange)
                            Text(alert.message)
                                .font(.subheadline)
                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                } else {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Air quality is optimal")
                            .font(.subheadline)
                        Spacer()
                    }
                }
            }
        }
    }
}

struct EnvironmentRecommendationsCard: View {
    @ObservedObject private var environmentManager = EnvironmentManager.shared
    
    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "lightbulb")
                        .foregroundColor(.yellow)
                    Text("Recommendations")
                        .font(.headline)
                    Spacer()
                }
                
                let recommendations = environmentManager.getEnvironmentRecommendations()
                
                if recommendations.isEmpty {
                    Text("No recommendations at this time")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                } else {
                    ForEach(recommendations.indices, id: \.self) { index in
                        let recommendation = recommendations[index]
                        HStack {
                            Image(systemName: "arrow.right.circle")
                                .foregroundColor(.blue)
                            Text(recommendation.message)
                                .font(.subheadline)
                            Spacer()
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct EnvironmentMetric: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
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
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct OptimizationButton: View {
    let title: String
    let icon: String
    let isActive: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.title3)
                Text(title)
                    .font(.caption)
            }
            .foregroundColor(isActive ? .white : .primary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isActive ? Color.blue : Color(.systemGray5))
            .cornerRadius(8)
        }
    }
}

struct ControlSlider: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let unit: String
    let icon: String
    let onChanged: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.blue)
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
                Text("\(value, specifier: "%.1f")\(unit)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Slider(value: $value, in: range) { _ in
                onChanged()
            }
            .accentColor(.blue)
        }
    }
}

struct Card<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Extensions

extension OptimizationMode {
    var displayName: String {
        switch self {
        case .auto:
            return "Auto"
        case .sleep:
            return "Sleep"
        case .work:
            return "Work"
        case .exercise:
            return "Exercise"
        case .custom:
            return "Custom"
        }
    }
}

#Preview {
    EnvironmentView()
}
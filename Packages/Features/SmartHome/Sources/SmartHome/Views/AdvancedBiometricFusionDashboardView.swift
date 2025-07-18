import SwiftUI
import Charts

/// Advanced Biometric Fusion Dashboard
/// Provides comprehensive multi-modal biometric monitoring, fusion quality indicators, and health insights
@available(iOS 18.0, macOS 15.0, *)
public struct AdvancedBiometricFusionDashboardView: View {
    
    // MARK: - State
    @StateObject private var biometricEngine: AdvancedBiometricFusionEngine
    @State private var showingSensorDetails = false
    @State private var showingInsights = false
    @State private var showingExport = false
    @State private var selectedTimeframe: Timeframe = .hour
    @State private var selectedSensor: BiometricSensor?
    @State private var showingCalibration = false
    @State private var exportFormat: ExportFormat = .json
    
    // MARK: - Environment
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Initialization
    public init(healthDataManager: HealthDataManager, analyticsEngine: AnalyticsEngine) {
        self._biometricEngine = StateObject(wrappedValue: AdvancedBiometricFusionEngine(
            healthDataManager: healthDataManager,
            analyticsEngine: analyticsEngine
        ))
    }
    
    // MARK: - Body
    public var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header Section
                    headerSection
                    
                    // Fusion Status
                    fusionStatusSection
                    
                    // Current Biometrics
                    if let fusedData = biometricEngine.fusedBiometrics {
                        currentBiometricsSection(fusedData)
                    } else {
                        startFusionSection
                    }
                    
                    // Sensor Status
                    sensorStatusSection
                    
                    // Health Metrics
                    if let metrics = biometricEngine.healthMetrics {
                        healthMetricsSection(metrics)
                    }
                    
                    // Biometric Insights
                    if let insights = biometricEngine.biometricInsights {
                        biometricInsightsSection(insights)
                    }
                    
                    // Fusion Quality
                    fusionQualitySection
                    
                    // Biometric Trends
                    trendsSection
                    
                    // Quick Actions
                    quickActionsSection
                }
                .padding()
            }
            .navigationTitle("Biometric Fusion")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Insights") {
                            showingInsights = true
                        }
                        
                        Button("Export Data") {
                            showingExport = true
                        }
                        
                        Button("Calibrate Sensors") {
                            showingCalibration = true
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .sheet(isPresented: $showingInsights) {
            BiometricInsightsView(biometricEngine: biometricEngine)
        }
        .sheet(isPresented: $showingExport) {
            BiometricExportView(biometricEngine: biometricEngine, format: $exportFormat)
        }
        .sheet(isPresented: $showingCalibration) {
            SensorCalibrationView(biometricEngine: biometricEngine)
        }
        .sheet(item: $selectedSensor) { sensor in
            SensorDetailView(sensor: sensor, biometricEngine: biometricEngine)
        }
        .onAppear {
            loadBiometricData()
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "waveform.path.ecg")
                    .font(.system(size: 50))
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Biometric Fusion")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    HStack {
                        Circle()
                            .fill(biometricEngine.isFusionActive ? .green : .gray)
                            .frame(width: 8, height: 8)
                        
                        Text(biometricEngine.isFusionActive ? "Fusion Active" : "Ready to Start")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Fusion Quality Indicator
                FusionQualityIndicator(quality: biometricEngine.fusionQuality)
            }
            
            // Quick Stats
            HStack {
                QuickStatCard(
                    title: "Sensors",
                    value: "\(biometricEngine.sensorStatus.count)",
                    icon: "sensor.tag.radiowaves.forward",
                    color: .blue
                )
                
                QuickStatCard(
                    title: "Active",
                    value: "\(activeSensorCount)",
                    icon: "checkmark.circle.fill",
                    color: .green
                )
                
                QuickStatCard(
                    title: "Quality",
                    value: biometricEngine.fusionQuality.displayName,
                    icon: "chart.line.uptrend.xyaxis",
                    color: biometricEngine.fusionQuality.color
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Fusion Status Section
    private var fusionStatusSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Fusion Status")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                if biometricEngine.isFusionActive {
                    Button("Stop Fusion") {
                        stopFusion()
                    }
                    .foregroundColor(.red)
                    .font(.subheadline)
                } else {
                    Button("Start Fusion") {
                        startFusion()
                    }
                    .foregroundColor(.blue)
                    .font(.subheadline)
                }
            }
            
            if biometricEngine.isFusionActive {
                VStack(spacing: 12) {
                    HStack {
                        Text("Fusion Quality")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text(biometricEngine.fusionQuality.displayName)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(biometricEngine.fusionQuality.color)
                    }
                    
                    HStack {
                        Text("Active Sensors")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("\(activeSensorCount)/\(biometricEngine.sensorStatus.count)")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    
                    HStack {
                        Text("Last Update")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("Just now")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                }
            } else {
                Text("Start biometric fusion to begin monitoring your health metrics across multiple sensors.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Current Biometrics Section
    private func currentBiometricsSection(_ fusedData: FusedBiometricData) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Current Biometrics")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 16) {
                // Vital Signs
                VitalSignsCard(vitalSigns: fusedData.vitalSigns)
                
                // Activity Data
                ActivityDataCard(activityData: fusedData.activityData)
                
                // Environmental Data
                EnvironmentalDataCard(environmentalData: fusedData.environmentalData)
                
                // Quality Metrics
                QualityMetricsCard(qualityMetrics: fusedData.qualityMetrics)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Start Fusion Section
    private var startFusionSection: some View {
        VStack(spacing: 16) {
            Text("Ready to Start Biometric Fusion?")
                .font(.headline)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
            
            Text("Start fusion to monitor your health metrics across multiple sensors and get comprehensive biometric insights.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Start Fusion") {
                startFusion()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            
            Button("View Sensor Status") {
                showingSensorDetails = true
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Sensor Status Section
    private var sensorStatusSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Sensor Status")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(Array(biometricEngine.sensorStatus.values), id: \.sensor) { status in
                    SensorStatusCard(status: status) {
                        selectedSensor = status.sensor
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Health Metrics Section
    private func healthMetricsSection(_ metrics: HealthMetrics) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Health Metrics")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 16) {
                // Biometric Scores
                BiometricScoresCard(scores: metrics.biometricScores)
                
                // Health Indicators
                HealthIndicatorsCard(indicators: metrics.healthIndicators)
                
                // Wellness Metrics
                WellnessMetricsCard(wellness: metrics.wellnessMetrics)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Biometric Insights Section
    private func biometricInsightsSection(_ insights: BiometricInsights) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Biometric Insights")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("View Details") {
                    showingInsights = true
                }
                .font(.subheadline)
                .foregroundColor(.blue)
            }
            
            VStack(spacing: 12) {
                InsightRow(
                    title: "Overall Health",
                    value: insights.overallHealth.category.displayName,
                    color: insights.overallHealth.category.color
                )
                
                InsightRow(
                    title: "Stress Level",
                    value: insights.stressLevel.displayName,
                    color: insights.stressLevel.color
                )
                
                InsightRow(
                    title: "Energy Level",
                    value: "\(Int(insights.energyLevel * 100))%",
                    color: .orange
                )
                
                InsightRow(
                    title: "Recovery Status",
                    value: insights.recoveryStatus.displayName,
                    color: insights.recoveryStatus.color
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Fusion Quality Section
    private var fusionQualitySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Fusion Quality")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 20) {
                // Quality Gauge
                QualityGauge(quality: biometricEngine.fusionQuality)
                
                // Quality Description
                Text(biometricEngine.fusionQuality.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                // Quality Factors
                if let fusedData = biometricEngine.fusedBiometrics {
                    QualityFactorsCard(qualityMetrics: fusedData.qualityMetrics)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Trends Section
    private var trendsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Biometric Trends")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 20) {
                // Heart Rate Trend
                ChartCard(
                    title: "Heart Rate Trend",
                    subtitle: "Last \(selectedTimeframe.rawValue)"
                ) {
                    HeartRateTrendChart(data: generateHeartRateData())
                }
                
                // Respiratory Rate Trend
                ChartCard(
                    title: "Respiratory Rate Trend",
                    subtitle: "Breathing patterns over time"
                ) {
                    RespiratoryTrendChart(data: generateRespiratoryData())
                }
                
                // Temperature Trend
                ChartCard(
                    title: "Temperature Trend",
                    subtitle: "Body temperature monitoring"
                ) {
                    TemperatureTrendChart(data: generateTemperatureData())
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Quick Actions Section
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Actions")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                QuickActionCard(
                    title: "Calibrate",
                    icon: "gearshape.fill",
                    color: .purple
                ) {
                    showingCalibration = true
                }
                
                QuickActionCard(
                    title: "Export",
                    icon: "square.and.arrow.up",
                    color: .green
                ) {
                    showingExport = true
                }
                
                QuickActionCard(
                    title: "Insights",
                    icon: "chart.bar.fill",
                    color: .orange
                ) {
                    showingInsights = true
                }
                
                QuickActionCard(
                    title: "History",
                    icon: "clock.fill",
                    color: .blue
                ) {
                    // Show history
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Helper Methods
    private func loadBiometricData() {
        Task {
            _ = await biometricEngine.getBiometricInsights(timeframe: selectedTimeframe)
            _ = await biometricEngine.getHealthMetrics()
        }
    }
    
    private func startFusion() {
        Task {
            do {
                try await biometricEngine.startFusion()
            } catch {
                print("Failed to start fusion: \(error)")
            }
        }
    }
    
    private func stopFusion() {
        Task {
            await biometricEngine.stopFusion()
        }
    }
    
    private var activeSensorCount: Int {
        biometricEngine.sensorStatus.values.filter { $0.isActive }.count
    }
    
    private func generateHeartRateData() -> [ChartDataPoint] {
        return [
            ChartDataPoint(date: Date().addingTimeInterval(-6 * 3600), value: 72),
            ChartDataPoint(date: Date().addingTimeInterval(-5 * 3600), value: 75),
            ChartDataPoint(date: Date().addingTimeInterval(-4 * 3600), value: 68),
            ChartDataPoint(date: Date().addingTimeInterval(-3 * 3600), value: 80),
            ChartDataPoint(date: Date().addingTimeInterval(-2 * 3600), value: 73),
            ChartDataPoint(date: Date().addingTimeInterval(-1 * 3600), value: 77),
            ChartDataPoint(date: Date(), value: 74)
        ]
    }
    
    private func generateRespiratoryData() -> [ChartDataPoint] {
        return [
            ChartDataPoint(date: Date().addingTimeInterval(-6 * 3600), value: 16),
            ChartDataPoint(date: Date().addingTimeInterval(-5 * 3600), value: 18),
            ChartDataPoint(date: Date().addingTimeInterval(-4 * 3600), value: 15),
            ChartDataPoint(date: Date().addingTimeInterval(-3 * 3600), value: 20),
            ChartDataPoint(date: Date().addingTimeInterval(-2 * 3600), value: 17),
            ChartDataPoint(date: Date().addingTimeInterval(-1 * 3600), value: 19),
            ChartDataPoint(date: Date(), value: 16)
        ]
    }
    
    private func generateTemperatureData() -> [ChartDataPoint] {
        return [
            ChartDataPoint(date: Date().addingTimeInterval(-6 * 3600), value: 98.6),
            ChartDataPoint(date: Date().addingTimeInterval(-5 * 3600), value: 98.4),
            ChartDataPoint(date: Date().addingTimeInterval(-4 * 3600), value: 98.8),
            ChartDataPoint(date: Date().addingTimeInterval(-3 * 3600), value: 99.1),
            ChartDataPoint(date: Date().addingTimeInterval(-2 * 3600), value: 98.7),
            ChartDataPoint(date: Date().addingTimeInterval(-1 * 3600), value: 98.9),
            ChartDataPoint(date: Date(), value: 98.6)
        ]
    }
}

// MARK: - Supporting Views

struct FusionQualityIndicator: View {
    let quality: FusionQuality
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: qualityIcon)
                .font(.title2)
                .foregroundColor(quality.color)
            
            Text(quality.displayName)
                .font(.caption)
                .foregroundColor(quality.color)
        }
    }
    
    private var qualityIcon: String {
        switch quality {
        case .excellent: return "star.fill"
        case .good: return "checkmark.circle.fill"
        case .fair: return "exclamationmark.triangle.fill"
        case .poor: return "xmark.circle.fill"
        case .unknown: return "questionmark.circle.fill"
        }
    }
}

struct VitalSignsCard: View {
    let vitalSigns: FusedVitalSigns
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Vital Signs")
                .font(.subheadline)
                .fontWeight(.semibold)
            
            VStack(spacing: 8) {
                HStack {
                    Text("Heart Rate")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(Int(vitalSigns.heartRate)) BPM")
                        .font(.caption)
                        .fontWeight(.semibold)
                }
                
                HStack {
                    Text("Respiratory Rate")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(Int(vitalSigns.respiratoryRate)) RPM")
                        .font(.caption)
                        .fontWeight(.semibold)
                }
                
                HStack {
                    Text("Temperature")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(vitalSigns.temperature, specifier: "%.1f")°F")
                        .font(.caption)
                        .fontWeight(.semibold)
                }
                
                HStack {
                    Text("Blood Pressure")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(vitalSigns.bloodPressure.systolic)/\(vitalSigns.bloodPressure.diastolic)")
                        .font(.caption)
                        .fontWeight(.semibold)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct ActivityDataCard: View {
    let activityData: FusedActivityData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Activity Data")
                .font(.subheadline)
                .fontWeight(.semibold)
            
            VStack(spacing: 8) {
                HStack {
                    Text("Movement")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(Int(activityData.movement * 100))%")
                        .font(.caption)
                        .fontWeight(.semibold)
                }
                
                HStack {
                    Text("Audio Level")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(Int(activityData.audio * 100))%")
                        .font(.caption)
                        .fontWeight(.semibold)
                }
                
                HStack {
                    Text("Sleep Quality")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(Int(activityData.sleep.sleepQuality * 100))%")
                        .font(.caption)
                        .fontWeight(.semibold)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct EnvironmentalDataCard: View {
    let environmentalData: FusedEnvironmentalData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Environmental Data")
                .font(.subheadline)
                .fontWeight(.semibold)
            
            VStack(spacing: 8) {
                HStack {
                    Text("Air Quality")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(Int(environmentalData.environmental.airQuality * 100))%")
                        .font(.caption)
                        .fontWeight(.semibold)
                }
                
                HStack {
                    Text("Noise Level")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(Int(environmentalData.environmental.noiseLevel * 100))%")
                        .font(.caption)
                        .fontWeight(.semibold)
                }
                
                HStack {
                    Text("Light Level")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(Int(environmentalData.environmental.lightLevel * 100))%")
                        .font(.caption)
                        .fontWeight(.semibold)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct QualityMetricsCard: View {
    let qualityMetrics: QualityMetrics
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quality Metrics")
                .font(.subheadline)
                .fontWeight(.semibold)
            
            VStack(spacing: 8) {
                HStack {
                    Text("Signal Quality")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(Int(qualityMetrics.signalQuality * 100))%")
                        .font(.caption)
                        .fontWeight(.semibold)
                }
                
                HStack {
                    Text("Noise Level")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(Int(qualityMetrics.noiseLevel * 100))%")
                        .font(.caption)
                        .fontWeight(.semibold)
                }
                
                HStack {
                    Text("Confidence")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(Int(qualityMetrics.confidence * 100))%")
                        .font(.caption)
                        .fontWeight(.semibold)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct SensorStatusCard: View {
    let status: SensorStatus
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: sensorIcon)
                        .font(.title2)
                        .foregroundColor(status.isActive ? .green : .gray)
                    
                    Spacer()
                    
                    if status.isActive {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(status.sensor.displayName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text(status.quality.displayName)
                        .font(.caption)
                        .foregroundColor(status.quality.color)
                }
                
                Spacer()
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var sensorIcon: String {
        switch status.sensor {
        case .heartRate: return "heart.fill"
        case .heartRateVariability: return "waveform.path.ecg"
        case .respiratoryRate: return "lungs.fill"
        case .temperature: return "thermometer"
        case .movement: return "figure.walk"
        case .audio: return "speaker.wave.2"
        case .environmental: return "leaf.fill"
        case .bloodPressure: return "drop.fill"
        case .oxygenSaturation: return "o.circle.fill"
        case .glucose: return "drop.degreesign"
        case .sleep: return "bed.double.fill"
        }
    }
}

struct BiometricScoresCard: View {
    let scores: BiometricScores
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Biometric Scores")
                .font(.subheadline)
                .fontWeight(.semibold)
            
            VStack(spacing: 8) {
                ScoreRow(title: "Cardiovascular", score: scores.cardiovascular)
                ScoreRow(title: "Respiratory", score: scores.respiratory)
                ScoreRow(title: "Metabolic", score: scores.metabolic)
                ScoreRow(title: "Neurological", score: scores.neurological)
                ScoreRow(title: "Musculoskeletal", score: scores.musculoskeletal)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct HealthIndicatorsCard: View {
    let indicators: HealthIndicators
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Health Indicators")
                .font(.subheadline)
                .fontWeight(.semibold)
            
            VStack(spacing: 8) {
                IndicatorRow(title: "Stress Level", value: indicators.stressLevel)
                IndicatorRow(title: "Energy Level", value: indicators.energyLevel)
                IndicatorRow(title: "Recovery Status", value: indicators.recoveryStatus)
                IndicatorRow(title: "Sleep Quality", value: indicators.sleepQuality)
                IndicatorRow(title: "Fitness Level", value: indicators.fitnessLevel)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct WellnessMetricsCard: View {
    let wellness: WellnessMetrics
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Wellness Metrics")
                .font(.subheadline)
                .fontWeight(.semibold)
            
            VStack(spacing: 8) {
                WellnessRow(title: "Overall", value: wellness.overallWellness)
                WellnessRow(title: "Physical", value: wellness.physicalWellness)
                WellnessRow(title: "Mental", value: wellness.mentalWellness)
                WellnessRow(title: "Social", value: wellness.socialWellness)
                WellnessRow(title: "Environmental", value: wellness.environmentalWellness)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct InsightRow: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.primary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
    }
}

struct QualityGauge: View {
    let quality: FusionQuality
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color(.systemGray5), lineWidth: 12)
                .frame(width: 120, height: 120)
            
            Circle()
                .trim(from: 0, to: qualityScore)
                .stroke(quality.color, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                .frame(width: 120, height: 120)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 1.0), value: qualityScore)
            
            VStack {
                Text(quality.displayName)
                    .font(.title3)
                    .fontWeight(.bold)
                
                Text("Quality")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var qualityScore: Double {
        switch quality {
        case .excellent: return 1.0
        case .good: return 0.75
        case .fair: return 0.5
        case .poor: return 0.25
        case .unknown: return 0.0
        }
    }
}

struct QualityFactorsCard: View {
    let qualityMetrics: QualityMetrics
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Quality Factors")
                .font(.subheadline)
                .fontWeight(.medium)
            
            HStack {
                QualityFactor(label: "Signal", value: qualityMetrics.signalQuality)
                QualityFactor(label: "Noise", value: qualityMetrics.noiseLevel, inverse: true)
                QualityFactor(label: "Confidence", value: qualityMetrics.confidence)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct QualityFactor: View {
    let label: String
    let value: Double
    let inverse: Bool
    
    init(label: String, value: Double, inverse: Bool = false) {
        self.label = label
        self.value = inverse ? 1.0 - value : value
        self.inverse = inverse
    }
    
    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("\(Int(value * 100))%")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(value > 0.7 ? .green : value > 0.4 ? .orange : .red)
        }
        .frame(maxWidth: .infinity)
    }
}

struct HeartRateTrendChart: View {
    let data: [ChartDataPoint]
    
    var body: some View {
        Chart(data) { point in
            LineMark(
                x: .value("Time", point.date),
                y: .value("Heart Rate", point.value)
            )
            .foregroundStyle(.red)
            .interpolationMethod(.catmullRom)
            
            AreaMark(
                x: .value("Time", point.date),
                y: .value("Heart Rate", point.value)
            )
            .foregroundStyle(.red.opacity(0.1))
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .hour)) { _ in
                AxisGridLine()
                AxisTick()
                AxisValueLabel(format: .dateTime.hour())
            }
        }
        .chartYAxis {
            AxisMarks { value in
                AxisGridLine()
                AxisTick()
                AxisValueLabel("\(value.as(Int.self) ?? 0)")
            }
        }
    }
}

struct RespiratoryTrendChart: View {
    let data: [ChartDataPoint]
    
    var body: some View {
        Chart(data) { point in
            LineMark(
                x: .value("Time", point.date),
                y: .value("Respiratory Rate", point.value)
            )
            .foregroundStyle(.blue)
            .interpolationMethod(.catmullRom)
            
            AreaMark(
                x: .value("Time", point.date),
                y: .value("Respiratory Rate", point.value)
            )
            .foregroundStyle(.blue.opacity(0.1))
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .hour)) { _ in
                AxisGridLine()
                AxisTick()
                AxisValueLabel(format: .dateTime.hour())
            }
        }
        .chartYAxis {
            AxisMarks { value in
                AxisGridLine()
                AxisTick()
                AxisValueLabel("\(value.as(Int.self) ?? 0)")
            }
        }
    }
}

struct TemperatureTrendChart: View {
    let data: [ChartDataPoint]
    
    var body: some View {
        Chart(data) { point in
            LineMark(
                x: .value("Time", point.date),
                y: .value("Temperature", point.value)
            )
            .foregroundStyle(.orange)
            .interpolationMethod(.catmullRom)
            
            AreaMark(
                x: .value("Time", point.date),
                y: .value("Temperature", point.value)
            )
            .foregroundStyle(.orange.opacity(0.1))
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .hour)) { _ in
                AxisGridLine()
                AxisTick()
                AxisValueLabel(format: .dateTime.hour())
            }
        }
        .chartYAxis {
            AxisMarks { value in
                AxisGridLine()
                AxisTick()
                AxisValueLabel("\(value.as(Double.self) ?? 0, specifier: "%.1f")")
            }
        }
    }
}

struct ScoreRow: View {
    let title: String
    let score: Double
    
    var body: some View {
        HStack {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text("\(Int(score * 100))%")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(score > 0.8 ? .green : score > 0.6 ? .orange : .red)
        }
    }
}

struct IndicatorRow: View {
    let title: String
    let value: Double
    
    var body: some View {
        HStack {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text("\(Int(value * 100))%")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(value > 0.8 ? .green : value > 0.6 ? .orange : .red)
        }
    }
}

struct WellnessRow: View {
    let title: String
    let value: Double
    
    var body: some View {
        HStack {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text("\(Int(value * 100))%")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(value > 0.8 ? .green : value > 0.6 ? .orange : .red)
        }
    }
}

// MARK: - Extensions

extension FusionQuality {
    var displayName: String {
        switch self {
        case .excellent: return "Excellent"
        case .good: return "Good"
        case .fair: return "Fair"
        case .poor: return "Poor"
        case .unknown: return "Unknown"
        }
    }
    
    var color: Color {
        switch self {
        case .excellent: return .green
        case .good: return .blue
        case .fair: return .orange
        case .poor: return .red
        case .unknown: return .gray
        }
    }
    
    var description: String {
        switch self {
        case .excellent: return "All sensors providing high-quality data with excellent fusion accuracy."
        case .good: return "Most sensors working well with good fusion quality."
        case .fair: return "Some sensors may have issues affecting fusion quality."
        case .poor: return "Multiple sensors experiencing problems, fusion quality compromised."
        case .unknown: return "Unable to determine fusion quality at this time."
        }
    }
}

extension BiometricSensor {
    var displayName: String {
        switch self {
        case .heartRate: return "Heart Rate"
        case .heartRateVariability: return "HRV"
        case .respiratoryRate: return "Respiratory"
        case .temperature: return "Temperature"
        case .movement: return "Movement"
        case .audio: return "Audio"
        case .environmental: return "Environmental"
        case .bloodPressure: return "Blood Pressure"
        case .oxygenSaturation: return "Oxygen"
        case .glucose: return "Glucose"
        case .sleep: return "Sleep"
        }
    }
}

extension SensorQuality {
    var displayName: String {
        switch self {
        case .excellent: return "Excellent"
        case .good: return "Good"
        case .fair: return "Fair"
        case .poor: return "Poor"
        case .unknown: return "Unknown"
        }
    }
    
    var color: Color {
        switch self {
        case .excellent: return .green
        case .good: return .blue
        case .fair: return .orange
        case .poor: return .red
        case .unknown: return .gray
        }
    }
}

extension HealthCategory {
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
        case .fair: return .orange
        case .poor: return .red
        }
    }
}

extension RecoveryStatus {
    var displayName: String {
        switch self {
        case .recovered: return "Recovered"
        case .recovering: return "Recovering"
        case .fatigued: return "Fatigued"
        case .overtraining: return "Overtraining"
        }
    }
    
    var color: Color {
        switch self {
        case .recovered: return .green
        case .recovering: return .blue
        case .fatigued: return .orange
        case .overtraining: return .red
        }
    }
}

// MARK: - Preview
#Preview {
    AdvancedBiometricFusionDashboardView(
        healthDataManager: HealthDataManager(),
        analyticsEngine: AnalyticsEngine()
    )
} 
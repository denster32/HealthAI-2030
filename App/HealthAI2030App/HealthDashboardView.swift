import SwiftUI
import Charts

struct HealthDashboardView: View {
    @StateObject private var dashboardVM = HealthDashboardViewModel()
    @State private var showingCoachingDashboard = false
    @State private var showingSleepDashboard = false
    @State private var showingMentalHealthDashboard = false
    @State private var showingBiometricFusionDashboard = false
    @State private var showingClinicalDecisionSupportDashboard = false
    @State private var showingHealthResearchDashboard = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Real-time vital signs
                VitalSignsPanel(vitals: dashboardVM.currentVitals)
                    .padding(.top)
                
                // AI Health Predictions
                AIHealthPredictionsCard()
                
                // Health Coaching Card
                HealthCoachingCard {
                    showingCoachingDashboard = true
                }
                
                // Advanced Sleep Intelligence Card
                AdvancedSleepIntelligenceCard {
                    showingSleepDashboard = true
                }
                
                // Advanced Mental Health Card
                AdvancedMentalHealthCard {
                    showingMentalHealthDashboard = true
                }
                
                // Advanced Biometric Fusion Card
                AdvancedBiometricFusionCard {
                    showingBiometricFusionDashboard = true
                }
                
                // Advanced Clinical Decision Support Card
                AdvancedClinicalDecisionSupportCard {
                    showingClinicalDecisionSupportDashboard = true
                }
                
                // Health Research Card
                HealthResearchCard {
                    showingHealthResearchDashboard = true
                }
                
                // Sleep architecture visualization
                if let sleepReport = dashboardVM.sleepReport {
                    SleepArchitectureCard(report: sleepReport)
                }
                
                // Cardiac health metrics
                CardiacHealthPanel(cardiacMetrics: dashboardVM.cardiacMetrics)
                
                // Activity trends
                ActivityTrendsChart(activityData: dashboardVM.activityData)
                
                // Mental wellness
                MentalWellnessGauge(score: dashboardVM.mentalHealthScore)
            }
            .padding()
        }
        .navigationTitle("Health Dashboard")
        .onAppear {
            dashboardVM.loadDashboardData()
        }
        .refreshable {
            dashboardVM.refreshData()
        }
        .sheet(isPresented: $showingCoachingDashboard) {
            RealTimeCoachingDashboardView(
                healthDataManager: HealthDataManager(),
                predictionEngine: AdvancedHealthPredictionEngine(),
                analyticsEngine: AnalyticsEngine()
            )
        }
        .sheet(isPresented: $showingSleepDashboard) {
            AdvancedSleepDashboardView(
                healthDataManager: HealthDataManager(),
                predictionEngine: AdvancedHealthPredictionEngine(),
                analyticsEngine: AnalyticsEngine()
            )
        }
        .sheet(isPresented: $showingMentalHealthDashboard) {
            AdvancedMentalHealthDashboardView(
                healthDataManager: HealthDataManager(),
                predictionEngine: AdvancedHealthPredictionEngine(),
                analyticsEngine: AnalyticsEngine()
            )
        }
        .sheet(isPresented: $showingBiometricFusionDashboard) {
            AdvancedBiometricFusionDashboardView(
                healthDataManager: HealthDataManager(),
                analyticsEngine: AnalyticsEngine()
            )
        }
        .sheet(isPresented: $showingClinicalDecisionSupportDashboard) {
            AdvancedClinicalDecisionSupportDashboardView(
                healthDataManager: HealthDataManager(),
                analyticsEngine: AnalyticsEngine()
            )
        }
        .sheet(isPresented: $showingHealthResearchDashboard) {
            AdvancedHealthResearchDashboardView()
        }
    }
}

// MARK: - Dashboard Components

struct VitalSignsPanel: View {
    let vitals: VitalSigns
    
    var body: some View {
        CardContainer(title: "Current Vitals") {
            HStack(spacing: 20) {
                VitalMetricView(value: "\(vitals.heartRate)", unit: "BPM", label: "Heart Rate", trend: vitals.heartRateTrend)
                VitalMetricView(value: "\(vitals.respiratoryRate)", unit: "RPM", label: "Respiratory", trend: vitals.respiratoryTrend)
                VitalMetricView(value: "\(vitals.bloodOxygen)", unit: "%", label: "SpO₂", trend: vitals.oxygenTrend)
                VitalMetricView(value: "\(vitals.temperature)", unit: "°F", label: "Temperature", trend: .neutral)
            }
            .padding(.vertical)
        }
    }
}

struct AIHealthPredictionsCard: View {
    @State private var predictions: ComprehensiveHealthPrediction?
    @State private var isLoading = true
    
    var body: some View {
        CardContainer(title: "AI Health Predictions") {
            VStack(alignment: .leading, spacing: 16) {
                if isLoading {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Generating predictions...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                } else if let predictions = predictions {
                    // Cardiovascular Risk
                    PredictionRow(
                        title: "Cardiovascular Risk",
                        value: "\(Int(predictions.cardiovascular.riskScore * 100))%",
                        trend: predictions.cardiovascular.riskScore > 0.3 ? .up : .down,
                        color: predictions.cardiovascular.riskScore > 0.3 ? .red : .green
                    )
                    
                    // Sleep Quality
                    PredictionRow(
                        title: "Sleep Quality",
                        value: "\(Int(predictions.sleep.qualityScore * 100))%",
                        trend: predictions.sleep.qualityScore > 0.7 ? .up : .down,
                        color: predictions.sleep.qualityScore > 0.7 ? .green : .orange
                    )
                    
                    // Stress Level
                    PredictionRow(
                        title: "Stress Level",
                        value: "\(Int(predictions.stress.stressLevel * 100))%",
                        trend: predictions.stress.stressLevel < 0.5 ? .down : .up,
                        color: predictions.stress.stressLevel < 0.5 ? .green : .red
                    )
                    
                    // Health Trajectory
                    PredictionRow(
                        title: "Health Trajectory",
                        value: predictions.trajectory.trend.rawValue.capitalized,
                        trend: predictions.trajectory.trend == .improving ? .up : .down,
                        color: predictions.trajectory.trend == .improving ? .green : .orange
                    )
                } else {
                    Text("Unable to generate predictions")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical)
        }
        .onAppear {
            loadPredictions()
        }
    }
    
    private func loadPredictions() {
        Task {
            do {
                let predictionEngine = AdvancedHealthPredictionEngine()
                let predictions = try await predictionEngine.generatePredictions()
                await MainActor.run {
                    self.predictions = predictions
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                }
            }
        }
    }
}

struct HealthCoachingCard: View {
    let onTap: () -> Void
    
    var body: some View {
        CardContainer(title: "AI Health Coach") {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.blue)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Your AI Health Coach")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text("Get personalized recommendations and guidance")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.title3)
                        .foregroundColor(.blue)
                }
                
                HStack {
                    Label("3 Active Goals", systemImage: "target")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Label("5 Recommendations", systemImage: "lightbulb")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical)
        }
        .onTapGesture {
            onTap()
        }
    }
}

struct AdvancedSleepIntelligenceCard: View {
    let onTap: () -> Void
    
    var body: some View {
        CardContainer(title: "Advanced Sleep Intelligence") {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "bed.double.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.indigo)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Sleep Intelligence")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text("AI-powered sleep analysis and optimization")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.title3)
                        .foregroundColor(.indigo)
                }
                
                HStack {
                    Label("Sleep Score: 85", systemImage: "star.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Label("3 Optimizations", systemImage: "lightbulb")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical)
        }
        .onTapGesture {
            onTap()
        }
    }
}

struct AdvancedMentalHealthCard: View {
    let onTap: () -> Void
    
    var body: some View {
        CardContainer(title: "Advanced Mental Health") {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 40))
                        .foregroundColor(.purple)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Mental Health Intelligence")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text("AI-powered mental health monitoring and wellness")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.title3)
                        .foregroundColor(.purple)
                }
                
                HStack {
                    Label("Wellness Score: 78", systemImage: "heart.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Label("4 Recommendations", systemImage: "lightbulb")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical)
        }
        .onTapGesture {
            onTap()
        }
    }
}

struct AdvancedBiometricFusionCard: View {
    let onTap: () -> Void
    
    var body: some View {
        CardContainer(title: "Advanced Biometric Fusion") {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "waveform.path.ecg")
                        .font(.system(size: 40))
                        .foregroundColor(.teal)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Biometric Fusion")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text("Multi-modal biometric data integration and analysis")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.title3)
                        .foregroundColor(.teal)
                }
                
                HStack {
                    Label("12 Sensors", systemImage: "sensor.tag.radiowaves.forward")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Label("Fusion Quality: Good", systemImage: "chart.line.uptrend.xyaxis")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical)
        }
        .onTapGesture {
            onTap()
        }
    }
}

struct AdvancedClinicalDecisionSupportCard: View {
    let onTap: () -> Void
    
    var body: some View {
        CardContainer(title: "Advanced Clinical Decision Support") {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "stethoscope")
                        .font(.system(size: 40))
                        .foregroundColor(.blue)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Clinical Decision Support")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text("AI-powered clinical insights and evidence-based recommendations")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.title3)
                        .foregroundColor(.blue)
                }
                
                HStack {
                    Label("Evidence Level: High", systemImage: "doc.text.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Label("3 Recommendations", systemImage: "lightbulb")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical)
        }
        .onTapGesture {
            onTap()
        }
    }
}

struct HealthResearchCard: View {
    let onTap: () -> Void
    
    var body: some View {
        CardContainer(title: "Health Research") {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 40))
                        .foregroundColor(.orange)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Health Research")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text("Research studies & clinical trials")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.title3)
                        .foregroundColor(.orange)
                }
                
                HStack {
                    Label("3 Active Studies", systemImage: "doc.text.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Label("2 Clinical Trials", systemImage: "cross.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical)
        }
        .onTapGesture {
            onTap()
        }
    }
}

struct PredictionRow: View {
    let title: String
    let value: String
    let trend: TrendDirection
    let color: Color
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.primary)
            
            Spacer()
            
            HStack(spacing: 8) {
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(color)
                
                Image(systemName: trendIcon)
                    .font(.caption)
                    .foregroundColor(color)
            }
        }
    }
    
    private var trendIcon: String {
        switch trend {
        case .up: return "arrow.up.circle.fill"
        case .down: return "arrow.down.circle.fill"
        case .neutral: return "minus.circle.fill"
        }
    }
}

struct CardiacHealthPanel: View {
    let cardiacMetrics: CardiacMetrics
    
    var body: some View {
        CardContainer(title: "Cardiac Health") {
            VStack(alignment: .leading) {
                HStack {
                    Text("HRV: \(cardiacMetrics.hrv, specifier: "%.0f") ms")
                        .cardMetricStyle()
                    Spacer()
                    Text("BP: \(cardiacMetrics.systolic)/\(cardiacMetrics.diastolic)")
                        .cardMetricStyle()
                }
                
                ECGPreviewView(data: cardiacMetrics.ecgPreview)
                    .frame(height: 120)
                    .padding(.top, 10)
                
                ArrhythmiaRiskIndicator(riskLevel: cardiacMetrics.arrhythmiaRisk)
            }
            .padding(.vertical)
        }
    }
}

// MARK: - Preview and Supporting Types

struct HealthDashboardView_Previews: PreviewProvider {
    static var previews: some View {
        HealthDashboardView()
    }
}

struct VitalSigns {
    let heartRate: Int
    let respiratoryRate: Int
    let bloodOxygen: Int
    let temperature: Double
    let heartRateTrend: TrendDirection
    let respiratoryTrend: TrendDirection
    let oxygenTrend: TrendDirection
}

enum TrendDirection {
    case up, down, neutral
}

struct CardiacMetrics {
    let hrv: Double
    let systolic: Int
    let diastolic: Int
    let ecgPreview: [Double]
    let arrhythmiaRisk: RiskLevel
}

enum RiskLevel {
    case low, medium, high
}
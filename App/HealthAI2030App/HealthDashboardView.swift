import SwiftUI
import Charts

struct HealthDashboardView: View {
    @StateObject private var dashboardVM = HealthDashboardViewModel()
    @State private var showingCoachingDashboard = false
    
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
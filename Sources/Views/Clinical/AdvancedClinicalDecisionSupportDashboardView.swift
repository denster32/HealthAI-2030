import SwiftUI
import Charts

/// Advanced Clinical Decision Support Dashboard
/// Provides comprehensive clinical insights, evidence-based recommendations, and healthcare provider integration
@available(iOS 18.0, macOS 15.0, *)
public struct AdvancedClinicalDecisionSupportDashboardView: View {
    
    // MARK: - State
    @StateObject private var clinicalEngine: AdvancedClinicalDecisionSupportEngine
    @State private var showingInsights = false
    @State private var showingRecommendations = false
    @State private var showingRiskAssessment = false
    @State private var showingAlerts = false
    @State private var showingEvidence = false
    @State private var showingExport = false
    @State private var selectedTimeframe: Timeframe = .day
    @State private var selectedCategory: RecommendationCategory = .all
    @State private var selectedRiskCategory: RiskCategory = .all
    @State private var selectedAlertSeverity: AlertSeverity = .all
    @State private var exportFormat: ExportFormat = .pdf
    
    // MARK: - Environment
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Initialization
    public init(healthDataManager: HealthDataManager, analyticsEngine: AnalyticsEngine) {
        self._clinicalEngine = StateObject(wrappedValue: AdvancedClinicalDecisionSupportEngine(
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
                    
                    // Analysis Status
                    analysisStatusSection
                    
                    // Clinical Insights
                    if let insights = clinicalEngine.clinicalInsights {
                        clinicalInsightsSection(insights)
                    } else {
                        startAnalysisSection
                    }
                    
                    // Risk Assessments
                    if !clinicalEngine.riskAssessments.isEmpty {
                        riskAssessmentsSection
                    }
                    
                    // Clinical Recommendations
                    if !clinicalEngine.recommendations.isEmpty {
                        recommendationsSection
                    }
                    
                    // Clinical Alerts
                    if !clinicalEngine.clinicalAlerts.isEmpty {
                        clinicalAlertsSection
                    }
                    
                    // Evidence Summaries
                    if !clinicalEngine.evidenceSummaries.isEmpty {
                        evidenceSummariesSection
                    }
                    
                    // Clinical Trends
                    trendsSection
                    
                    // Quick Actions
                    quickActionsSection
                }
                .padding()
            }
            .navigationTitle("Clinical Decision Support")
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
                        
                        Button("Recommendations") {
                            showingRecommendations = true
                        }
                        
                        Button("Risk Assessment") {
                            showingRiskAssessment = true
                        }
                        
                        Button("Alerts") {
                            showingAlerts = true
                        }
                        
                        Button("Evidence") {
                            showingEvidence = true
                        }
                        
                        Button("Export Report") {
                            showingExport = true
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .sheet(isPresented: $showingInsights) {
            ClinicalInsightsView(clinicalEngine: clinicalEngine)
        }
        .sheet(isPresented: $showingRecommendations) {
            ClinicalRecommendationsView(clinicalEngine: clinicalEngine, category: $selectedCategory)
        }
        .sheet(isPresented: $showingRiskAssessment) {
            RiskAssessmentView(clinicalEngine: clinicalEngine, category: $selectedRiskCategory)
        }
        .sheet(isPresented: $showingAlerts) {
            ClinicalAlertsView(clinicalEngine: clinicalEngine, severity: $selectedAlertSeverity)
        }
        .sheet(isPresented: $showingEvidence) {
            EvidenceSummariesView(clinicalEngine: clinicalEngine)
        }
        .sheet(isPresented: $showingExport) {
            ClinicalExportView(clinicalEngine: clinicalEngine, format: $exportFormat)
        }
        .onAppear {
            loadClinicalData()
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "stethoscope")
                    .font(.system(size: 50))
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Clinical Decision Support")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    HStack {
                        Circle()
                            .fill(clinicalEngine.isAnalysisActive ? .green : .gray)
                            .frame(width: 8, height: 8)
                        
                        Text(clinicalEngine.isAnalysisActive ? "Analysis Active" : "Ready to Start")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Analysis Progress
                if clinicalEngine.isAnalysisActive {
                    ProgressView(value: clinicalEngine.analysisProgress)
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(0.8)
                }
            }
            
            // Quick Stats
            HStack {
                QuickStatCard(
                    title: "Insights",
                    value: clinicalEngine.clinicalInsights != nil ? "Available" : "Pending",
                    icon: "brain.head.profile",
                    color: clinicalEngine.clinicalInsights != nil ? .green : .gray
                )
                
                QuickStatCard(
                    title: "Risks",
                    value: "\(clinicalEngine.riskAssessments.count)",
                    icon: "exclamationmark.triangle.fill",
                    color: clinicalEngine.riskAssessments.isEmpty ? .green : .orange
                )
                
                QuickStatCard(
                    title: "Alerts",
                    value: "\(clinicalEngine.clinicalAlerts.count)",
                    icon: "bell.fill",
                    color: clinicalEngine.clinicalAlerts.isEmpty ? .green : .red
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Analysis Status Section
    private var analysisStatusSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Analysis Status")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                if clinicalEngine.isAnalysisActive {
                    Button("Stop Analysis") {
                        stopAnalysis()
                    }
                    .foregroundColor(.red)
                    .font(.subheadline)
                } else {
                    Button("Start Analysis") {
                        startAnalysis()
                    }
                    .foregroundColor(.blue)
                    .font(.subheadline)
                }
            }
            
            if clinicalEngine.isAnalysisActive {
                VStack(spacing: 12) {
                    HStack {
                        Text("Analysis Progress")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("\(Int(clinicalEngine.analysisProgress * 100))%")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                    }
                    
                    ProgressView(value: clinicalEngine.analysisProgress)
                        .progressViewStyle(LinearProgressViewStyle())
                    
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
                Text("Start clinical analysis to generate insights, recommendations, and risk assessments based on your health data.")
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
    
    // MARK: - Clinical Insights Section
    private func clinicalInsightsSection(_ insights: ClinicalInsights) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Clinical Insights")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("View Details") {
                    showingInsights = true
                }
                .font(.subheadline)
                .foregroundColor(.blue)
            }
            
            VStack(spacing: 16) {
                // Overall Health
                InsightCard(
                    title: "Overall Health",
                    value: insights.overallHealth.category.displayName,
                    color: insights.overallHealth.category.color,
                    icon: "heart.fill"
                )
                
                // Risk Factors
                HStack {
                    RiskFactorCard(
                        title: "Cardiovascular",
                        risk: insights.cardiovascularRisk,
                        color: .red
                    )
                    
                    RiskFactorCard(
                        title: "Metabolic",
                        risk: insights.metabolicRisk,
                        color: .orange
                    )
                    
                    RiskFactorCard(
                        title: "Respiratory",
                        risk: insights.respiratoryRisk,
                        color: .blue
                    )
                    
                    RiskFactorCard(
                        title: "Mental Health",
                        risk: insights.mentalHealthRisk,
                        color: .purple
                    )
                }
                
                // Evidence Level
                HStack {
                    Text("Evidence Level")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(insights.evidenceLevel.displayName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(insights.evidenceLevel.color)
                }
                
                // Confidence Score
                HStack {
                    Text("Confidence")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(Int(insights.confidenceScore * 100))%")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Start Analysis Section
    private var startAnalysisSection: some View {
        VStack(spacing: 16) {
            Text("Ready to Start Clinical Analysis?")
                .font(.headline)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
            
            Text("Start analysis to generate evidence-based clinical insights, recommendations, and risk assessments.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Start Analysis") {
                startAnalysis()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            
            Button("View Clinical History") {
                // Show clinical history
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Risk Assessments Section
    private var riskAssessmentsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Risk Assessments")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("View All") {
                    showingRiskAssessment = true
                }
                .font(.subheadline)
                .foregroundColor(.blue)
            }
            
            LazyVStack(spacing: 12) {
                ForEach(clinicalEngine.riskAssessments.prefix(3), id: \.id) { risk in
                    RiskAssessmentCard(risk: risk)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Recommendations Section
    private var recommendationsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Clinical Recommendations")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("View All") {
                    showingRecommendations = true
                }
                .font(.subheadline)
                .foregroundColor(.blue)
            }
            
            LazyVStack(spacing: 12) {
                ForEach(clinicalEngine.recommendations.prefix(3), id: \.id) { recommendation in
                    RecommendationCard(recommendation: recommendation)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Clinical Alerts Section
    private var clinicalAlertsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Clinical Alerts")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("View All") {
                    showingAlerts = true
                }
                .font(.subheadline)
                .foregroundColor(.blue)
            }
            
            LazyVStack(spacing: 12) {
                ForEach(clinicalEngine.clinicalAlerts.prefix(3), id: \.id) { alert in
                    ClinicalAlertCard(alert: alert)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Evidence Summaries Section
    private var evidenceSummariesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Evidence Summaries")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("View All") {
                    showingEvidence = true
                }
                .font(.subheadline)
                .foregroundColor(.blue)
            }
            
            LazyVStack(spacing: 12) {
                ForEach(clinicalEngine.evidenceSummaries.prefix(3), id: \.id) { evidence in
                    EvidenceSummaryCard(evidence: evidence)
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
            Text("Clinical Trends")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 20) {
                // Risk Trends
                ChartCard(
                    title: "Risk Trends",
                    subtitle: "Last \(selectedTimeframe.rawValue)"
                ) {
                    RiskTrendsChart(data: generateRiskTrendsData())
                }
                
                // Health Score Trends
                ChartCard(
                    title: "Health Score Trends",
                    subtitle: "Overall health progression"
                ) {
                    HealthScoreTrendsChart(data: generateHealthScoreData())
                }
                
                // Recommendation Trends
                ChartCard(
                    title: "Recommendation Trends",
                    subtitle: "Clinical recommendations over time"
                ) {
                    RecommendationTrendsChart(data: generateRecommendationData())
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
                    title: "Export Report",
                    icon: "square.and.arrow.up",
                    color: .green
                ) {
                    showingExport = true
                }
                
                QuickActionCard(
                    title: "Evidence",
                    icon: "doc.text.fill",
                    color: .blue
                ) {
                    showingEvidence = true
                }
                
                QuickActionCard(
                    title: "Alerts",
                    icon: "bell.fill",
                    color: .red
                ) {
                    showingAlerts = true
                }
                
                QuickActionCard(
                    title: "History",
                    icon: "clock.fill",
                    color: .purple
                ) {
                    // Show clinical history
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Helper Methods
    private func loadClinicalData() {
        Task {
            _ = await clinicalEngine.getClinicalInsights(timeframe: selectedTimeframe)
        }
    }
    
    private func startAnalysis() {
        Task {
            do {
                try await clinicalEngine.startAnalysis()
            } catch {
                print("Failed to start analysis: \(error)")
            }
        }
    }
    
    private func stopAnalysis() {
        Task {
            await clinicalEngine.stopAnalysis()
        }
    }
    
    private func generateRiskTrendsData() -> [ChartDataPoint] {
        return [
            ChartDataPoint(date: Date().addingTimeInterval(-6 * 24 * 3600), value: 0.2),
            ChartDataPoint(date: Date().addingTimeInterval(-5 * 24 * 3600), value: 0.25),
            ChartDataPoint(date: Date().addingTimeInterval(-4 * 24 * 3600), value: 0.18),
            ChartDataPoint(date: Date().addingTimeInterval(-3 * 24 * 3600), value: 0.22),
            ChartDataPoint(date: Date().addingTimeInterval(-2 * 24 * 3600), value: 0.19),
            ChartDataPoint(date: Date().addingTimeInterval(-1 * 24 * 3600), value: 0.21),
            ChartDataPoint(date: Date(), value: 0.2)
        ]
    }
    
    private func generateHealthScoreData() -> [ChartDataPoint] {
        return [
            ChartDataPoint(date: Date().addingTimeInterval(-6 * 24 * 3600), value: 0.75),
            ChartDataPoint(date: Date().addingTimeInterval(-5 * 24 * 3600), value: 0.78),
            ChartDataPoint(date: Date().addingTimeInterval(-4 * 24 * 3600), value: 0.82),
            ChartDataPoint(date: Date().addingTimeInterval(-3 * 24 * 3600), value: 0.79),
            ChartDataPoint(date: Date().addingTimeInterval(-2 * 24 * 3600), value: 0.81),
            ChartDataPoint(date: Date().addingTimeInterval(-1 * 24 * 3600), value: 0.83),
            ChartDataPoint(date: Date(), value: 0.8)
        ]
    }
    
    private func generateRecommendationData() -> [ChartDataPoint] {
        return [
            ChartDataPoint(date: Date().addingTimeInterval(-6 * 24 * 3600), value: 3),
            ChartDataPoint(date: Date().addingTimeInterval(-5 * 24 * 3600), value: 4),
            ChartDataPoint(date: Date().addingTimeInterval(-4 * 24 * 3600), value: 2),
            ChartDataPoint(date: Date().addingTimeInterval(-3 * 24 * 3600), value: 5),
            ChartDataPoint(date: Date().addingTimeInterval(-2 * 24 * 3600), value: 3),
            ChartDataPoint(date: Date().addingTimeInterval(-1 * 24 * 3600), value: 4),
            ChartDataPoint(date: Date(), value: 3)
        ]
    }
}

// MARK: - Supporting Views

struct InsightCard: View {
    let title: String
    let value: String
    let color: Color
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(color)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct RiskFactorCard: View {
    let title: String
    let risk: Double
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Text("\(Int(risk * 100))%")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(risk > 0.3 ? color : .green)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct RiskAssessmentCard: View {
    let risk: RiskAssessment
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: riskIcon)
                    .font(.title3)
                    .foregroundColor(risk.riskLevel.color)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(risk.category.displayName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Text(risk.riskLevel.displayName)
                        .font(.caption)
                        .foregroundColor(risk.riskLevel.color)
                }
                
                Spacer()
                
                Text("\(Int(risk.riskLevel.score * 100))%")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(risk.riskLevel.color)
            }
            
            Text(risk.description)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var riskIcon: String {
        switch risk.category {
        case .cardiovascular: return "heart.fill"
        case .metabolic: return "drop.fill"
        case .respiratory: return "lungs.fill"
        case .mental: return "brain.head.profile"
        case .medication: return "pills.fill"
        }
    }
}

struct RecommendationCard: View {
    let recommendation: ClinicalRecommendation
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: recommendationIcon)
                    .font(.title3)
                    .foregroundColor(recommendation.priority.color)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(recommendation.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Text(recommendation.category.displayName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text(recommendation.priority.displayName)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(recommendation.priority.color)
            }
            
            Text(recommendation.description)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var recommendationIcon: String {
        switch recommendation.category {
        case .cardiovascular: return "heart.fill"
        case .metabolic: return "drop.fill"
        case .respiratory: return "lungs.fill"
        case .mental: return "brain.head.profile"
        case .medication: return "pills.fill"
        case .lifestyle: return "figure.walk"
        case .preventive: return "shield.fill"
        }
    }
}

struct ClinicalAlertCard: View {
    let alert: ClinicalAlert
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: alertIcon)
                    .font(.title3)
                    .foregroundColor(alert.severity.color)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(alert.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Text(alert.category.displayName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text(alert.severity.displayName)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(alert.severity.color)
            }
            
            Text(alert.description)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var alertIcon: String {
        switch alert.category {
        case .vital_signs: return "heart.fill"
        case .medication: return "pills.fill"
        case .lab_results: return "testtube.2"
        case .imaging: return "camera.fill"
        case .symptoms: return "exclamationmark.triangle.fill"
        }
    }
}

struct EvidenceSummaryCard: View {
    let evidence: EvidenceSummary
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "doc.text.fill")
                    .font(.title3)
                    .foregroundColor(evidence.evidenceLevel.color)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(evidence.topic)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Text(evidence.evidenceLevel.displayName)
                        .font(.caption)
                        .foregroundColor(evidence.evidenceLevel.color)
                }
                
                Spacer()
            }
            
            Text(evidence.summary)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(3)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct RiskTrendsChart: View {
    let data: [ChartDataPoint]
    
    var body: some View {
        Chart(data) { point in
            LineMark(
                x: .value("Time", point.date),
                y: .value("Risk", point.value)
            )
            .foregroundStyle(.red)
            .interpolationMethod(.catmullRom)
            
            AreaMark(
                x: .value("Time", point.date),
                y: .value("Risk", point.value)
            )
            .foregroundStyle(.red.opacity(0.1))
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .day)) { _ in
                AxisGridLine()
                AxisTick()
                AxisValueLabel(format: .dateTime.day())
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

struct HealthScoreTrendsChart: View {
    let data: [ChartDataPoint]
    
    var body: some View {
        Chart(data) { point in
            LineMark(
                x: .value("Time", point.date),
                y: .value("Health Score", point.value)
            )
            .foregroundStyle(.green)
            .interpolationMethod(.catmullRom)
            
            AreaMark(
                x: .value("Time", point.date),
                y: .value("Health Score", point.value)
            )
            .foregroundStyle(.green.opacity(0.1))
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .day)) { _ in
                AxisGridLine()
                AxisTick()
                AxisValueLabel(format: .dateTime.day())
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

struct RecommendationTrendsChart: View {
    let data: [ChartDataPoint]
    
    var body: some View {
        Chart(data) { point in
            BarMark(
                x: .value("Time", point.date),
                y: .value("Recommendations", point.value)
            )
            .foregroundStyle(.blue)
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .day)) { _ in
                AxisGridLine()
                AxisTick()
                AxisValueLabel(format: .dateTime.day())
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

// MARK: - Extensions

extension RecommendationCategory {
    var displayName: String {
        switch self {
        case .cardiovascular: return "Cardiovascular"
        case .metabolic: return "Metabolic"
        case .respiratory: return "Respiratory"
        case .mental: return "Mental Health"
        case .medication: return "Medication"
        case .lifestyle: return "Lifestyle"
        case .preventive: return "Preventive"
        }
    }
}

extension RiskCategory {
    var displayName: String {
        switch self {
        case .cardiovascular: return "Cardiovascular"
        case .metabolic: return "Metabolic"
        case .respiratory: return "Respiratory"
        case .mental: return "Mental Health"
        case .medication: return "Medication"
        }
    }
}

extension AlertCategory {
    var displayName: String {
        switch self {
        case .vital_signs: return "Vital Signs"
        case .medication: return "Medication"
        case .lab_results: return "Lab Results"
        case .imaging: return "Imaging"
        case .symptoms: return "Symptoms"
        }
    }
}

extension EvidenceLevel {
    var displayName: String {
        switch self {
        case .high: return "High"
        case .moderate: return "Moderate"
        case .low: return "Low"
        case .insufficient: return "Insufficient"
        }
    }
    
    var color: Color {
        switch self {
        case .high: return .green
        case .moderate: return .blue
        case .low: return .orange
        case .insufficient: return .red
        }
    }
}

extension RecommendationPriority {
    var displayName: String {
        switch self {
        case .high: return "High"
        case .medium: return "Medium"
        case .low: return "Low"
        }
    }
    
    var color: Color {
        switch self {
        case .high: return .red
        case .medium: return .orange
        case .low: return .blue
        }
    }
}

extension RiskLevel {
    var displayName: String {
        switch self {
        case .low: return "Low"
        case .moderate: return "Moderate"
        case .high: return "High"
        }
    }
    
    var color: Color {
        switch self {
        case .low: return .green
        case .moderate: return .orange
        case .high: return .red
        }
    }
    
    var score: Double {
        switch self {
        case .low: return 0.2
        case .moderate: return 0.5
        case .high: return 0.8
        }
    }
}

extension AlertSeverity {
    var displayName: String {
        switch self {
        case .critical: return "Critical"
        case .high: return "High"
        case .medium: return "Medium"
        case .low: return "Low"
        }
    }
    
    var color: Color {
        switch self {
        case .critical: return .red
        case .high: return .orange
        case .medium: return .yellow
        case .low: return .blue
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

// MARK: - Preview
#Preview {
    AdvancedClinicalDecisionSupportDashboardView(
        healthDataManager: HealthDataManager(),
        analyticsEngine: AnalyticsEngine()
    )
} 
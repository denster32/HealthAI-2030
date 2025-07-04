import SwiftUI
import Charts

struct MacOSContentView: View {
    @StateObject private var healthDataManager = HealthDataManager.shared
    @StateObject private var analyticsEngine = AnalyticsEngine.shared
    @StateObject private var researchManager = ResearchDataManager()
    @StateObject private var performanceManager = PerformanceOptimizationManager.shared
    
    @State private var selectedSidebarItem: SidebarItem = .dashboard
    @State private var showingDataExport = false
    @State private var showingResearchTools = false
    
    var body: some View {
        NavigationSplitView {
            // Sidebar
            MacOSSidebar(selectedItem: $selectedSidebarItem)
                .navigationSplitViewColumnWidth(min: 250, ideal: 300)
        } detail: {
            // Main Content
            Group {
                switch selectedSidebarItem {
                case .dashboard:
                    MacOSDashboardView()
                case .analytics:
                    AdvancedAnalyticsView()
                case .research:
                    ResearchDataView()
                case .correlations:
                    CorrelationAnalysisView()
                case .predictions:
                    PredictionModelsView()
                case .dataExplorer:
                    DataExplorerView()
                case .reports:
                    ReportsView()
                case .performance:
                    PerformanceAnalysisView()
                case .exports:
                    DataExportView()
                case .settings:
                    MacOSSettingsView()
                }
            }
            .navigationSplitViewColumnWidth(min: 600, ideal: 1000)
            .toolbar {
                ToolbarItemGroup(placement: .primaryAction) {
                    Button("Export Data") {
                        showingDataExport = true
                    }
                    
                    Button("Research Tools") {
                        showingResearchTools = true
                    }
                    
                    Button("Refresh") {
                        refreshAllData()
                    }
                }
            }
        }
        .sheet(isPresented: $showingDataExport) {
            DataExportSheet()
        }
        .sheet(isPresented: $showingResearchTools) {
            ResearchToolsSheet()
        }
    }
    
    private func refreshAllData() {
        healthDataManager.refreshHealthData()
        analyticsEngine.performComprehensiveAnalysis()
        researchManager.updateResearchData()
    }
}

// MARK: - Sidebar

struct MacOSSidebar: View {
    @Binding var selectedItem: SidebarItem
    
    var body: some View {
        List(selection: $selectedItem) {
            Section("Overview") {
                SidebarRow(item: .dashboard, icon: "house.fill", title: "Dashboard")
                SidebarRow(item: .analytics, icon: "chart.line.uptrend.xyaxis", title: "Analytics")
                SidebarRow(item: .performance, icon: "speedometer", title: "Performance")
            }
            
            Section("Research") {
                SidebarRow(item: .research, icon: "flask.fill", title: "Research Data")
                SidebarRow(item: .correlations, icon: "link", title: "Correlations")
                SidebarRow(item: .predictions, icon: "brain.head.profile", title: "ML Models")
                SidebarRow(item: .dataExplorer, icon: "magnifyingglass", title: "Data Explorer")
            }
            
            Section("Tools") {
                SidebarRow(item: .reports, icon: "doc.text.fill", title: "Reports")
                SidebarRow(item: .exports, icon: "square.and.arrow.up", title: "Export")
                SidebarRow(item: .settings, icon: "gear", title: "Settings")
            }
        }
        .listStyle(SidebarListStyle())
        .navigationTitle("HealthAI 2030")
    }
}

struct SidebarRow: View {
    let item: SidebarItem
    let icon: String
    let title: String
    
    var body: some View {
        Label(title, systemImage: icon)
            .tag(item)
    }
}

enum SidebarItem: String, CaseIterable {
    case dashboard = "dashboard"
    case analytics = "analytics"
    case research = "research"
    case correlations = "correlations"
    case predictions = "predictions"
    case dataExplorer = "dataExplorer"
    case reports = "reports"
    case performance = "performance"
    case exports = "exports"
    case settings = "settings"
}

// MARK: - Dashboard View

struct MacOSDashboardView: View {
    @ObservedObject private var healthDataManager = HealthDataManager.shared
    @ObservedObject private var analyticsEngine = AnalyticsEngine.shared
    @ObservedObject private var performanceManager = PerformanceOptimizationManager.shared
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 20),
                GridItem(.flexible(), spacing: 20)
            ], spacing: 20) {
                // Health Status Overview
                MacOSHealthStatusCard()
                    .frame(height: 300)
                
                // PhysioForecast
                MacOSPhysioForecastCard()
                    .frame(height: 300)
                
                // Real-time Analytics
                MacOSRealTimeAnalyticsCard()
                    .frame(height: 300)
                
                // Performance Metrics
                MacOSPerformanceCard()
                    .frame(height: 300)
                
                // Research Insights
                MacOSResearchInsightsCard()
                    .frame(height: 300)
                
                // System Intelligence
                MacOSSystemIntelligenceCard()
                    .frame(height: 300)
            }
            .padding()
        }
        .navigationTitle("HealthAI Dashboard")
    }
}

// MARK: - Dashboard Cards

struct MacOSHealthStatusCard: View {
    @ObservedObject private var healthDataManager = HealthDataManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "heart.fill")
                    .foregroundColor(.red)
                    .font(.title2)
                Text("Health Status")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                HealthMetricView(
                    title: "Heart Rate",
                    value: "\(Int(healthDataManager.currentHeartRate))",
                    unit: "BPM",
                    color: .red,
                    trend: .stable
                )
                
                HealthMetricView(
                    title: "HRV",
                    value: "\(Int(healthDataManager.currentHRV))",
                    unit: "ms",
                    color: .green,
                    trend: .increasing
                )
                
                HealthMetricView(
                    title: "SpO2",
                    value: "\(Int(healthDataManager.currentOxygenSaturation * 100))",
                    unit: "%",
                    color: .blue,
                    trend: .stable
                )
                
                HealthMetricView(
                    title: "Steps",
                    value: "\(healthDataManager.stepCount)",
                    unit: "",
                    color: .orange,
                    trend: .increasing
                )
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(12)
    }
}

struct MacOSPhysioForecastCard: View {
    @ObservedObject private var analyticsEngine = AnalyticsEngine.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .foregroundColor(.purple)
                    .font(.title2)
                Text("PhysioForecast")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                Text("Next 48h")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if let forecast = analyticsEngine.physioForecast {
                VStack(spacing: 12) {
                    ForecastBar(title: "Energy", value: forecast.energy, color: .red)
                    ForecastBar(title: "Mood", value: forecast.moodStability, color: .blue)
                    ForecastBar(title: "Cognitive", value: forecast.cognitiveAcuity, color: .purple)
                    ForecastBar(title: "Recovery", value: forecast.musculoskeletalResilience, color: .green)
                }
                
                Spacer()
                
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundColor(.blue)
                    Text("Confidence: \(Int(forecast.confidence * 100))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
            } else {
                Text("Generating forecast...")
                    .foregroundColor(.secondary)
                Spacer()
            }
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(12)
    }
}

struct MacOSRealTimeAnalyticsCard: View {
    @ObservedObject private var analyticsEngine = AnalyticsEngine.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "waveform.path.ecg")
                    .foregroundColor(.green)
                    .font(.title2)
                Text("Real-time Analytics")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            // Mini chart showing recent trends
            Chart {
                // Placeholder data - would be replaced with real-time data
                ForEach(0..<24, id: \.self) { hour in
                    LineMark(
                        x: .value("Hour", hour),
                        y: .value("Value", Double.random(in: 0.4...0.9))
                    )
                    .foregroundStyle(.blue)
                }
            }
            .frame(height: 120)
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Correlation Score")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("0.84")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Processing")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("Real-time")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                }
            }
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(12)
    }
}

struct MacOSPerformanceCard: View {
    @ObservedObject private var performanceManager = PerformanceOptimizationManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "speedometer")
                    .foregroundColor(.orange)
                    .font(.title2)
                Text("System Performance")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            VStack(spacing: 12) {
                PerformanceBar(
                    title: "CPU Usage",
                    value: performanceManager.currentCPUUsage,
                    color: .red
                )
                
                PerformanceBar(
                    title: "Memory Usage",
                    value: performanceManager.currentMemoryUsage,
                    color: .blue
                )
                
                PerformanceBar(
                    title: "Battery Level",
                    value: performanceManager.batteryLevel,
                    color: .green
                )
            }
            
            Spacer()
            
            HStack {
                Text("Mode: \(performanceManager.performanceMode.displayName)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Circle()
                    .fill(performanceModeColor)
                    .frame(width: 8, height: 8)
            }
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(12)
    }
    
    private var performanceModeColor: Color {
        switch performanceManager.performanceMode {
        case .highPerformance: return .red
        case .balanced: return .green
        case .conservative: return .yellow
        case .batterySaving: return .orange
        case .thermal: return .purple
        }
    }
}

struct MacOSResearchInsightsCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "flask.fill")
                    .foregroundColor(.cyan)
                    .font(.title2)
                Text("Research Insights")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 8) {
                ResearchInsightRow(
                    title: "Sleep Pattern Analysis",
                    description: "Identified 3 distinct sleep phases",
                    confidence: 0.92
                )
                
                ResearchInsightRow(
                    title: "HRV Correlation",
                    description: "Strong correlation with stress levels",
                    confidence: 0.87
                )
                
                ResearchInsightRow(
                    title: "Circadian Rhythm",
                    description: "Optimal sleep window: 22:30-06:15",
                    confidence: 0.95
                )
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(12)
    }
}

struct MacOSSystemIntelligenceCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "brain")
                    .foregroundColor(.pink)
                    .font(.title2)
                Text("AI Intelligence")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 12) {
                IntelligenceMetric(
                    title: "Pattern Recognition",
                    value: 0.94,
                    icon: "eye.fill"
                )
                
                IntelligenceMetric(
                    title: "Prediction Accuracy",
                    value: 0.89,
                    icon: "target"
                )
                
                IntelligenceMetric(
                    title: "Adaptation Rate",
                    value: 0.76,
                    icon: "arrow.up.right"
                )
            }
            
            Spacer()
            
            HStack {
                Text("Learning Active")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Image(systemName: "brain.head.profile.fill")
                    .foregroundColor(.pink)
                    .font(.caption)
            }
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(12)
    }
}

// MARK: - Supporting Views

struct HealthMetricView: View {
    let title: String
    let value: String
    let unit: String
    let color: Color
    let trend: TrendDirection
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Image(systemName: trend.icon)
                    .font(.caption2)
                    .foregroundColor(trend.color)
            }
            
            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(color)
                
                Text(unit)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

struct ForecastBar: View {
    let title: String
    let value: Double
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .font(.caption)
                Spacer()
                Text("\(Int(value * 100))%")
                    .font(.caption)
                    .fontWeight(.medium)
            }
            
            ProgressView(value: value)
                .progressViewStyle(LinearProgressViewStyle(tint: color))
                .frame(height: 6)
        }
    }
}

struct PerformanceBar: View {
    let title: String
    let value: Double
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .font(.caption)
                Spacer()
                Text("\(Int(value * 100))%")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(value > 0.8 ? .red : .primary)
            }
            
            ProgressView(value: value)
                .progressViewStyle(LinearProgressViewStyle(tint: value > 0.8 ? .red : color))
                .frame(height: 4)
        }
    }
}

struct ResearchInsightRow: View {
    let title: String
    let description: String
    let confidence: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                Spacer()
                Text("\(Int(confidence * 100))%")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Text(description)
                .font(.caption2)
                .foregroundColor(.secondary)
                .lineLimit(2)
        }
    }
}

struct IntelligenceMetric: View {
    let title: String
    let value: Double
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.pink)
                .frame(width: 16)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                
                ProgressView(value: value)
                    .progressViewStyle(LinearProgressViewStyle(tint: .pink))
                    .frame(height: 3)
            }
            
            Spacer()
            
            Text("\(Int(value * 100))%")
                .font(.caption2)
                .fontWeight(.medium)
        }
    }
}

enum TrendDirection {
    case increasing
    case decreasing
    case stable
    
    var icon: String {
        switch self {
        case .increasing: return "arrow.up"
        case .decreasing: return "arrow.down"
        case .stable: return "minus"
        }
    }
    
    var color: Color {
        switch self {
        case .increasing: return .green
        case .decreasing: return .red
        case .stable: return .gray
        }
    }
}

// MARK: - Research Data Manager

class ResearchDataManager: ObservableObject {
    @Published var researchDatasets: [ResearchDataset] = []
    @Published var currentStudy: ResearchStudy?
    @Published var statisticalAnalysis: StatisticalAnalysis?
    
    init() {
        loadResearchData()
    }
    
    func loadResearchData() {
        // Load research datasets
        researchDatasets = [
            ResearchDataset(
                id: "sleep_study_2024",
                name: "Sleep Optimization Study",
                description: "Longitudinal study of sleep optimization interventions",
                participantCount: 1,
                dataPoints: 15420,
                startDate: Calendar.current.date(byAdding: .month, value: -6, to: Date()) ?? Date(),
                status: .active
            ),
            ResearchDataset(
                id: "hrv_correlation_2024",
                name: "HRV-Stress Correlation Analysis",
                description: "Analysis of heart rate variability correlation with stress markers",
                participantCount: 1,
                dataPoints: 8934,
                startDate: Calendar.current.date(byAdding: .month, value: -3, to: Date()) ?? Date(),
                status: .analyzing
            )
        ]
    }
    
    func updateResearchData() {
        // Update research data from health managers
        loadResearchData()
    }
}

struct ResearchDataset {
    let id: String
    let name: String
    let description: String
    let participantCount: Int
    let dataPoints: Int
    let startDate: Date
    let status: ResearchStatus
}

struct ResearchStudy {
    let id: String
    let title: String
    let hypothesis: String
    let methodology: String
    let results: [ResearchResult]
}

struct ResearchResult {
    let metric: String
    let value: Double
    let significance: Double
    let confidence: Double
}

struct StatisticalAnalysis {
    let correlations: [CorrelationResult]
    let regressionAnalysis: RegressionAnalysis
    let significanceTests: [SignificanceTest]
}

struct CorrelationResult {
    let variable1: String
    let variable2: String
    let coefficient: Double
    let pValue: Double
}

struct RegressionAnalysis {
    let rSquared: Double
    let coefficients: [String: Double]
    let residuals: [Double]
}

struct SignificanceTest {
    let testType: String
    let statistic: Double
    let pValue: Double
    let significant: Bool
}

enum ResearchStatus {
    case planning
    case active
    case analyzing
    case completed
    case published
}

// MARK: - Placeholder Views

struct AdvancedAnalyticsView: View {
    var body: some View {
        Text("Advanced Analytics View")
            .font(.largeTitle)
            .navigationTitle("Advanced Analytics")
    }
}

struct ResearchDataView: View {
    var body: some View {
        Text("Research Data View")
            .font(.largeTitle)
            .navigationTitle("Research Data")
    }
}

struct CorrelationAnalysisView: View {
    var body: some View {
        Text("Correlation Analysis View")
            .font(.largeTitle)
            .navigationTitle("Correlation Analysis")
    }
}

struct PredictionModelsView: View {
    var body: some View {
        Text("Prediction Models View")
            .font(.largeTitle)
            .navigationTitle("ML Models")
    }
}

struct DataExplorerView: View {
    var body: some View {
        Text("Data Explorer View")
            .font(.largeTitle)
            .navigationTitle("Data Explorer")
    }
}

struct ReportsView: View {
    var body: some View {
        Text("Reports View")
            .font(.largeTitle)
            .navigationTitle("Reports")
    }
}

struct PerformanceAnalysisView: View {
    var body: some View {
        Text("Performance Analysis View")
            .font(.largeTitle)
            .navigationTitle("Performance Analysis")
    }
}

struct DataExportView: View {
    var body: some View {
        Text("Data Export View")
            .font(.largeTitle)
            .navigationTitle("Data Export")
    }
}

struct MacOSSettingsView: View {
    var body: some View {
        Text("macOS Settings View")
            .font(.largeTitle)
            .navigationTitle("Settings")
    }
}

struct DataExportSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack {
            Text("Data Export")
                .font(.largeTitle)
            Text("Export functionality coming soon...")
            Button("Close") { dismiss() }
        }
        .padding()
    }
}

struct ResearchToolsSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack {
            Text("Research Tools")
                .font(.largeTitle)
            Text("Research tools coming soon...")
            Button("Close") { dismiss() }
        }
        .padding()
    }
}

#Preview {
    MacOSContentView()
}
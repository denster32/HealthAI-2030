import SwiftUI
import HealthAI2030Core
import HealthAI2030UI
import EnvironmentalHealthEngine
import SmartDeviceIntegration

/// Comprehensive smart home health dashboard with environmental optimization
public struct SmartHomeHealthDashboard: View {
    @StateObject private var environmentalEngine = EnvironmentalHealthEngine.shared
    @StateObject private var deviceManager = SmartDeviceManager.shared
    @State private var currentAssessment: EnvironmentalHealthAssessment?
    @State private var connectedDevices: [SmartDevice] = []
    @State private var deviceImpactAnalysis: DeviceHealthImpactAnalysis?
    @State private var healthTrends: EnvironmentalHealthTrends?
    @State private var isLoading = false
    @State private var selectedTab = 0
    @State private var showingDeviceSetup = false
    
    public init() {}
    
    public var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with current environmental score
                if let assessment = currentAssessment {
                    EnvironmentalScoreHeader(assessment: assessment)
                }
                
                // Tab selector
                Picker("Smart Home Health", selection: $selectedTab) {
                    Text("Overview").tag(0)
                    Text("Environment").tag(1)
                    Text("Devices").tag(2)
                    Text("Automation").tag(3)
                }
                .pickerStyle(.segmented)
                .padding()
                
                TabView(selection: $selectedTab) {
                    // Overview Tab
                    OverviewTabView(
                        assessment: currentAssessment,
                        deviceCount: connectedDevices.count,
                        isLoading: isLoading
                    )
                    .tag(0)
                    
                    // Environment Tab
                    EnvironmentTabView(
                        assessment: currentAssessment,
                        trends: healthTrends,
                        isLoading: isLoading
                    )
                    .tag(1)
                    
                    // Devices Tab
                    DevicesTabView(
                        devices: connectedDevices,
                        impactAnalysis: deviceImpactAnalysis,
                        onDeviceSetup: { showingDeviceSetup = true },
                        isLoading: isLoading
                    )
                    .tag(2)
                    
                    // Automation Tab
                    AutomationTabView(
                        deviceManager: deviceManager,
                        environmentalEngine: environmentalEngine,
                        isLoading: isLoading
                    )
                    .tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            .navigationTitle("Smart Home Health")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Refresh") {
                        refreshData()
                    }
                    .disabled(isLoading)
                }
            }
        }
        .sheet(isPresented: $showingDeviceSetup) {
            DeviceSetupView(deviceManager: deviceManager) {
                refreshDevices()
            }
        }
        .onAppear {
            refreshData()
        }
    }
    
    private func refreshData() {
        isLoading = true
        
        Task {
            async let assessment = environmentalEngine.getCurrentEnvironmentalHealth()
            async let devices = getConnectedDevices()
            async let impact = deviceManager.analyzeDeviceHealthImpact()
            async let trends = environmentalEngine.getHealthTrends(period: .week)
            
            currentAssessment = await assessment
            connectedDevices = await devices
            deviceImpactAnalysis = await impact
            healthTrends = await trends
            
            isLoading = false
        }
    }
    
    private func refreshDevices() {
        Task {
            connectedDevices = await getConnectedDevices()
            deviceImpactAnalysis = await deviceManager.analyzeDeviceHealthImpact()
        }
    }
    
    private func getConnectedDevices() async -> [SmartDevice] {
        // This would get actual connected devices from device manager
        return []
    }
}

// MARK: - Header Views

struct EnvironmentalScoreHeader: View {
    let assessment: EnvironmentalHealthAssessment
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Environmental Health")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                
                Text("\(Int(assessment.overallScore * 100))%")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(scoreColor)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 8) {
                HealthScoreIndicator(
                    title: "Air Quality",
                    score: assessment.airQualityIndex,
                    color: .blue
                )
                
                HealthScoreIndicator(
                    title: "Comfort",
                    score: assessment.comfortIndex,
                    color: .green
                )
            }
        }
        .padding()
        .background(scoreColor.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }
    
    private var scoreColor: Color {
        let score = assessment.overallScore
        if score >= 0.8 { return .green }
        if score >= 0.6 { return .orange }
        return .red
    }
}

struct HealthScoreIndicator: View {
    let title: String
    let score: Double
    let color: Color
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Text("\(Int(score * 100))%")
                .font(.callout)
                .fontWeight(.semibold)
                .foregroundStyle(color)
        }
    }
}

// MARK: - Tab Views

struct OverviewTabView: View {
    let assessment: EnvironmentalHealthAssessment?
    let deviceCount: Int
    let isLoading: Bool
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                if isLoading {
                    ProgressView("Analyzing environment...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let assessment = assessment {
                    // Quick Stats
                    QuickStatsView(assessment: assessment, deviceCount: deviceCount)
                    
                    // Health Impacts
                    if !assessment.healthImpacts.isEmpty {
                        SectionHeaderView(title: "Health Impacts")
                        
                        ForEach(assessment.healthImpacts.prefix(3), id: \.factor) { impact in
                            HealthImpactCard(impact: impact)
                        }
                    }
                    
                    // Recommendations
                    if !assessment.recommendations.isEmpty {
                        SectionHeaderView(title: "Recommendations")
                        
                        ForEach(assessment.recommendations.prefix(4), id: \.title) { recommendation in
                            EnvironmentalRecommendationCard(recommendation: recommendation)
                        }
                    }
                } else {
                    EmptyStateView(
                        title: "Environmental Data Loading",
                        message: "Setting up environmental monitoring...",
                        icon: "house.fill"
                    )
                }
            }
            .padding()
        }
    }
}

struct EnvironmentTabView: View {
    let assessment: EnvironmentalHealthAssessment?
    let trends: EnvironmentalHealthTrends?
    let isLoading: Bool
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                if isLoading {
                    ProgressView("Loading environmental data...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    // Current Environmental Conditions
                    if let assessment = assessment {
                        SectionHeaderView(title: "Current Conditions")
                        EnvironmentalConditionsGrid(environment: assessment.environment)
                    }
                    
                    // Environmental Trends
                    if let trends = trends {
                        SectionHeaderView(title: "Health Trends (\(trends.period.description))")
                        EnvironmentalTrendsView(trends: trends)
                    }
                    
                    // Health Correlations
                    if let trends = trends, !trends.healthImpactCorrelations.isEmpty {
                        SectionHeaderView(title: "Health Correlations")
                        
                        ForEach(trends.healthImpactCorrelations, id: \.factor) { correlation in
                            HealthCorrelationCard(correlation: correlation)
                        }
                    }
                }
            }
            .padding()
        }
    }
}

struct DevicesTabView: View {
    let devices: [SmartDevice]
    let impactAnalysis: DeviceHealthImpactAnalysis?
    let onDeviceSetup: () -> Void
    let isLoading: Bool
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                if isLoading {
                    ProgressView("Analyzing devices...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    // Device Overview
                    DeviceOverviewCard(
                        deviceCount: devices.count,
                        healthScore: impactAnalysis?.overallHealthScore ?? 0.0,
                        onAddDevice: onDeviceSetup
                    )
                    
                    // Connected Devices
                    if !devices.isEmpty {
                        SectionHeaderView(title: "Connected Devices")
                        
                        ForEach(devices.prefix(5), id: \.id) { device in
                            SmartDeviceCard(device: device)
                        }
                    }
                    
                    // Device Impact Analysis
                    if let analysis = impactAnalysis, !analysis.deviceImpacts.isEmpty {
                        SectionHeaderView(title: "Health Impact Analysis")
                        
                        ForEach(analysis.deviceImpacts.prefix(3), id: \.deviceId) { impact in
                            DeviceHealthImpactCard(impact: impact)
                        }
                    }
                    
                    if devices.isEmpty {
                        EmptyStateView(
                            title: "No Devices Connected",
                            message: "Add smart home devices to optimize your health environment",
                            icon: "plus.circle"
                        )
                    }
                }
            }
            .padding()
        }
    }
}

struct AutomationTabView: View {
    let deviceManager: SmartDeviceManager
    let environmentalEngine: EnvironmentalHealthEngine
    let isLoading: Bool
    
    @State private var automationRules: [AutomationPreview] = []
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                if isLoading {
                    ProgressView("Loading automations...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    // Quick Setup Automations
                    SectionHeaderView(title: "Quick Setup")
                    QuickAutomationGrid()
                    
                    // Active Automations
                    if !automationRules.isEmpty {
                        SectionHeaderView(title: "Active Automations")
                        
                        ForEach(automationRules, id: \.id) { rule in
                            AutomationRuleCard(rule: rule)
                        }
                    }
                    
                    // Automation Suggestions
                    SectionHeaderView(title: "Suggested Automations")
                    AutomationSuggestionsView()
                }
            }
            .padding()
        }
        .onAppear {
            loadAutomationRules()
        }
    }
    
    private func loadAutomationRules() {
        // Load existing automation rules
        automationRules = [
            AutomationPreview(
                id: "sleep_temp",
                name: "Sleep Temperature",
                description: "Automatically lower temperature for optimal sleep",
                isActive: true,
                triggerDescription: "30 minutes before bedtime"
            ),
            AutomationPreview(
                id: "air_quality",
                name: "Air Quality Response",
                description: "Activate air purifiers when air quality drops",
                isActive: true,
                triggerDescription: "Air quality below 60"
            )
        ]
    }
}

// MARK: - Card Views

struct QuickStatsView: View {
    let assessment: EnvironmentalHealthAssessment
    let deviceCount: Int
    
    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
            StatCard(
                title: "Air Quality",
                value: "\(Int(assessment.airQualityIndex * 100))",
                unit: "AQI",
                color: colorForScore(assessment.airQualityIndex),
                icon: "wind"
            )
            
            StatCard(
                title: "Comfort Level",
                value: "\(Int(assessment.comfortIndex * 100))",
                unit: "%",
                color: colorForScore(assessment.comfortIndex),
                icon: "house.fill"
            )
            
            StatCard(
                title: "Temperature",
                value: String(format: "%.1f", assessment.environment.temperature),
                unit: "°C",
                color: .blue,
                icon: "thermometer"
            )
            
            StatCard(
                title: "Devices",
                value: "\(deviceCount)",
                unit: "connected",
                color: .green,
                icon: "homekit"
            )
        }
    }
    
    private func colorForScore(_ score: Double) -> Color {
        if score >= 0.8 { return .green }
        if score >= 0.6 { return .orange }
        return .red
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let unit: String
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                    .font(.title3)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(color)
                
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Text(unit)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

struct HealthImpactCard: View {
    let impact: HealthImpactFactor
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: iconForFactor(impact.factor))
                .foregroundStyle(colorForSeverity(impact.severity))
                .font(.title2)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(impact.factor.displayName)
                    .font(.headline)
                    .fontWeight(.medium)
                
                Text(impact.description)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            SeverityIndicator(severity: impact.severity)
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
    }
    
    private func iconForFactor(_ factor: EnvironmentalFactor) -> String {
        switch factor {
        case .airQuality: return "wind.circle.fill"
        case .temperature: return "thermometer.sun.fill"
        case .humidity: return "humidity.fill"
        case .noise: return "speaker.wave.3.fill"
        case .light: return "lightbulb.fill"
        }
    }
    
    private func colorForSeverity(_ severity: Double) -> Color {
        if severity < 0.3 { return .green }
        if severity < 0.6 { return .orange }
        return .red
    }
}

struct SeverityIndicator: View {
    let severity: Double
    
    var body: some View {
        VStack(spacing: 2) {
            Text("\(Int(severity * 100))%")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(severityColor)
            
            Rectangle()
                .fill(severityColor)
                .frame(width: 4, height: 20)
                .clipShape(Capsule())
        }
    }
    
    private var severityColor: Color {
        if severity < 0.3 { return .green }
        if severity < 0.6 { return .orange }
        return .red
    }
}

struct EnvironmentalRecommendationCard: View {
    let recommendation: EnvironmentalRecommendation
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundStyle(.yellow)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(recommendation.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("Priority: \(Int(recommendation.priority * 100))%")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
            }
            
            Text(recommendation.description)
                .font(.callout)
                .foregroundStyle(.primary)
            
            VStack(alignment: .leading, spacing: 6) {
                Text("Recommended Actions:")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                
                ForEach(recommendation.actions.prefix(3), id: \.self) { action in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .font(.caption)
                        
                        Text(action)
                            .font(.caption)
                            .foregroundStyle(.primary)
                    }
                }
            }
            
            if !recommendation.expectedBenefit.isEmpty {
                Text("Expected benefit: \(recommendation.expectedBenefit)")
                    .font(.caption)
                    .foregroundStyle(.green)
                    .padding(.top, 4)
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Helper Views

struct SectionHeaderView: View {
    let title: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
            
            Spacer()
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }
}

struct EmptyStateView: View {
    let title: String
    let message: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            
            VStack(spacing: 8) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(message)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// Additional placeholder views and components...
struct EnvironmentalConditionsGrid: View {
    let environment: EnvironmentalState
    var body: some View { Text("Environmental Conditions") }
}

struct EnvironmentalTrendsView: View {
    let trends: EnvironmentalHealthTrends
    var body: some View { Text("Environmental Trends") }
}

struct HealthCorrelationCard: View {
    let correlation: HealthCorrelation
    var body: some View { Text(correlation.factor) }
}

struct DeviceOverviewCard: View {
    let deviceCount: Int
    let healthScore: Double
    let onAddDevice: () -> Void
    var body: some View { Text("\(deviceCount) devices") }
}

struct SmartDeviceCard: View {
    let device: SmartDevice
    var body: some View { Text(device.name) }
}

struct DeviceHealthImpactCard: View {
    let impact: DeviceHealthImpact
    var body: some View { Text(impact.deviceId) }
}

struct QuickAutomationGrid: View {
    var body: some View { Text("Quick Automations") }
}

struct AutomationRuleCard: View {
    let rule: AutomationPreview
    var body: some View { Text(rule.name) }
}

struct AutomationSuggestionsView: View {
    var body: some View { Text("Automation Suggestions") }
}

struct DeviceSetupView: View {
    let deviceManager: SmartDeviceManager
    let onComplete: () -> Void
    var body: some View { Text("Device Setup") }
}

// Supporting types
struct AutomationPreview {
    let id: String
    let name: String
    let description: String
    let isActive: Bool
    let triggerDescription: String
}

// Extensions
extension TimePeriod {
    var description: String {
        switch self {
        case .hour: return "Last Hour"
        case .day: return "Last Day"
        case .week: return "Last Week"
        case .month: return "Last Month"
        }
    }
}

extension EnvironmentalFactor {
    var displayName: String {
        switch self {
        case .airQuality: return "Air Quality"
        case .temperature: return "Temperature"
        case .humidity: return "Humidity"
        case .noise: return "Noise Level"
        case .light: return "Lighting"
        }
    }
}

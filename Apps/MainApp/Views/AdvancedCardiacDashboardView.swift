import SwiftUI
import Charts

/// Advanced Cardiac Dashboard View for iOS 18+ cardiac health features
/// Displays atrial fibrillation burden, cardio fitness, VO2 Max, and cardiac insights
struct AdvancedCardiacDashboardView: View {
    @StateObject private var cardiacManager = AdvancedCardiacManager.shared
    @State private var selectedTimeRange: TimeRange = .week
    @State private var showingECGView = false
    @State private var selectedInsight: CardiacInsight?
    
    enum TimeRange: String, CaseIterable {
        case day = "Day"
        case week = "Week"
        case month = "Month"
        
        var days: Int {
            switch self {
            case .day: return 1
            case .week: return 7
            case .month: return 30
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 20) {
                    // Cardiac Health Score Card
                    CardiacHealthScoreCard()
                    
                    // Atrial Fibrillation Card
                    AtrialFibrillationCard()
                    
                    // Cardio Fitness Card
                    CardioFitnessCard()
                    
                    // Heart Rate & HRV Card
                    HeartRateHRVCard()
                    
                    // Oxygen Saturation Card
                    OxygenSaturationCard()
                    
                    // Cardiac Insights Card
                    CardiacInsightsCard()
                }
                .padding()
            }
            .navigationTitle("Cardiac Health")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("ECG") {
                        showingECGView = true
                    }
                    .buttonStyle(.borderedProminent)
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Picker("Time Range", selection: $selectedTimeRange) {
                        ForEach(TimeRange.allCases, id: \.self) { range in
                            Text(range.rawValue).tag(range)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .frame(width: 200)
                }
            }
        }
        .sheet(isPresented: $showingECGView) {
            ECGView()
        }
        .sheet(item: $selectedInsight) { insight in
            CardiacInsightDetailView(insight: insight)
        }
    }
}

// MARK: - Cardiac Health Score Card

struct CardiacHealthScoreCard: View {
    @StateObject private var cardiacManager = AdvancedCardiacManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "heart.fill")
                    .foregroundColor(.red)
                Text("Cardiac Health Score")
                    .font(.headline)
                Spacer()
                Text("\(Int(cardiacManager.cardiacHealthScore * 100))")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.red)
            }
            
            // Circular Progress
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                    .frame(width: 80, height: 80)
                
                Circle()
                    .trim(from: 0, to: cardiacManager.cardiacHealthScore)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [.red, .orange]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 1.0), value: cardiacManager.cardiacHealthScore)
                
                VStack {
                    Text("\(Int(cardiacManager.cardiacHealthScore * 100))")
                        .font(.title3)
                        .fontWeight(.bold)
                    Text("Score")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)
            
            // Quick Stats
            HStack(spacing: 20) {
                StatItem(
                    title: "AFib Status",
                    value: cardiacManager.afibStatus.displayName,
                    color: afibColor
                )
                
                StatItem(
                    title: "Trend",
                    value: cardiacManager.cardiacHealthTrend.displayName,
                    color: trendColor
                )
                
                StatItem(
                    title: "Risk Score",
                    value: "\(Int(cardiacManager.cardiacRiskScore * 100))",
                    color: riskColor
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 2)
    }
    
    private var afibColor: Color {
        switch cardiacManager.afibStatus {
        case .normal: return .green
        case .low: return .yellow
        case .moderate: return .orange
        case .high: return .red
        }
    }
    
    private var trendColor: Color {
        switch cardiacManager.cardiacHealthTrend {
        case .improving: return .green
        case .stable: return .blue
        case .declining: return .orange
        case .critical: return .red
        }
    }
    
    private var riskColor: Color {
        let risk = cardiacManager.cardiacRiskScore
        switch risk {
        case 0..<0.3: return .green
        case 0.3..<0.6: return .yellow
        case 0.6..<0.8: return .orange
        default: return .red
        }
    }
}

// MARK: - Atrial Fibrillation Card

struct AtrialFibrillationCard: View {
    @StateObject private var cardiacManager = AdvancedCardiacManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "heart.circle.fill")
                    .foregroundColor(.purple)
                Text("Atrial Fibrillation")
                    .font(.headline)
                Spacer()
                Text("\(String(format: "%.1f", cardiacManager.atrialFibrillationBurden))%")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.purple)
            }
            
            // AFib Burden Chart
            Chart {
                ForEach(cardiacManager.afibEpisodes.prefix(20), id: \.startDate) { episode in
                    BarMark(
                        x: .value("Date", episode.startDate),
                        y: .value("Duration", episode.duration / 60) // Convert to minutes
                    )
                    .foregroundStyle(.purple.gradient)
                }
            }
            .frame(height: 120)
            .chartYAxis {
                AxisMarks { value in
                    AxisValueLabel {
                        if let doubleValue = value.as(Double.self) {
                            Text("\(Int(doubleValue))m")
                                .font(.caption)
                        }
                    }
                }
            }
            
            // AFib Statistics
            HStack(spacing: 20) {
                StatItem(
                    title: "Episodes",
                    value: "\(cardiacManager.afibEpisodes.count)",
                    color: .purple
                )
                
                StatItem(
                    title: "Avg Duration",
                    value: formatAverageDuration(),
                    color: .purple
                )
                
                StatItem(
                    title: "Risk Level",
                    value: cardiacManager.afibStatus.displayName,
                    color: afibRiskColor
                )
            }
            
            // AFib Alerts
            if !cardiacManager.afibAlerts.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Recent Alerts")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    ForEach(cardiacManager.afibAlerts.prefix(2), id: \.timestamp) { alert in
                        AFibAlertRow(alert: alert)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 2)
    }
    
    private func formatAverageDuration() -> String {
        guard !cardiacManager.afibEpisodes.isEmpty else { return "0m" }
        let averageDuration = cardiacManager.afibEpisodes.reduce(0) { $0 + $1.duration } / Double(cardiacManager.afibEpisodes.count)
        let minutes = Int(averageDuration) / 60
        return "\(minutes)m"
    }
    
    private var afibRiskColor: Color {
        switch cardiacManager.afibStatus {
        case .normal: return .green
        case .low: return .yellow
        case .moderate: return .orange
        case .high: return .red
        }
    }
}

struct AFibAlertRow: View {
    let alert: AFibAlert
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(alertColor)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("AFib Alert")
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text("Burden: \(String(format: "%.1f", alert.burden))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(alert.severity.displayName)
                .font(.caption)
                .foregroundColor(alertColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(alertColor.opacity(0.2))
                .cornerRadius(4)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
    
    private var alertColor: Color {
        switch alert.severity {
        case .info: return .blue
        case .warning: return .orange
        case .critical: return .red
        }
    }
}

// MARK: - Cardio Fitness Card

struct CardioFitnessCard: View {
    @StateObject private var cardiacManager = AdvancedCardiacManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "figure.run")
                    .foregroundColor(.green)
                Text("Cardio Fitness")
                    .font(.headline)
                Spacer()
                Text("\(Int(cardiacManager.vo2Max))")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.green)
                    + Text(" mL/kg/min")
                        .font(.caption)
                        .foregroundColor(.secondary)
            }
            
            // VO2 Max Progress
            VStack(spacing: 12) {
                HStack {
                    Text("VO2 Max")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Spacer()
                    Text("\(Int(cardiacManager.vo2Max)) mL/kg/min")
                        .font(.subheadline)
                        .foregroundColor(.green)
                }
                
                ProgressView(value: min(cardiacManager.vo2Max / 60.0, 1.0))
                    .progressViewStyle(LinearProgressViewStyle(tint: .green))
                
                HStack {
                    Text("Poor")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("Excellent")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Fitness Age
            HStack(spacing: 20) {
                VStack(spacing: 8) {
                    Text("Fitness Age")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text("\(cardiacManager.fitnessAge)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(fitnessAgeColor)
                }
                .frame(maxWidth: .infinity)
                
                VStack(spacing: 8) {
                    Text("Cardio Fitness")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text("\(Int(cardiacManager.cardioFitness))")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                }
                .frame(maxWidth: .infinity)
            }
            
            // Fitness Recommendations
            if !cardiacManager.fitnessRecommendations.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Recommendations")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    ForEach(cardiacManager.fitnessRecommendations.prefix(2), id: \.title) { recommendation in
                        FitnessRecommendationRow(recommendation: recommendation)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 2)
    }
    
    private var fitnessAgeColor: Color {
        let age = cardiacManager.fitnessAge
        switch age {
        case 0..<30: return .green
        case 30..<40: return .blue
        case 40..<50: return .yellow
        case 50..<60: return .orange
        default: return .red
        }
    }
}

struct FitnessRecommendationRow: View {
    let recommendation: FitnessRecommendation
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: recommendationIcon)
                .foregroundColor(.green)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(recommendation.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(recommendation.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(formatDuration(recommendation.duration))
                    .font(.caption)
                    .fontWeight(.medium)
                Text(recommendation.intensity.displayName)
                    .font(.caption2)
                    .foregroundColor(intensityColor)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(intensityColor.opacity(0.2))
                    .cornerRadius(4)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
    
    private var recommendationIcon: String {
        switch recommendation.type {
        case .cardio: return "figure.run"
        case .strength: return "dumbbell.fill"
        case .flexibility: return "figure.flexibility"
        case .recovery: return "bed.double.fill"
        }
    }
    
    private var intensityColor: Color {
        switch recommendation.intensity {
        case .low: return .green
        case .moderate: return .yellow
        case .high: return .red
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        return "\(minutes)m"
    }
}

// MARK: - Heart Rate & HRV Card

struct HeartRateHRVCard: View {
    @StateObject private var cardiacManager = AdvancedCardiacManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "heart.fill")
                    .foregroundColor(.red)
                Text("Heart Rate & HRV")
                    .font(.headline)
                Spacer()
            }
            
            if cardiacManager.heartRateData.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "heart")
                        .font(.system(size: 40))
                        .foregroundColor(.red.opacity(0.6))
                    Text("No heart rate data available")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                // Heart Rate Chart
                Chart {
                    ForEach(cardiacManager.heartRateData.prefix(100), id: \.timestamp) { sample in
                        LineMark(
                            x: .value("Time", sample.timestamp),
                            y: .value("Heart Rate", sample.value)
                        )
                        .foregroundStyle(.red)
                        .interpolationMethod(.catmullRom)
                    }
                }
                .frame(height: 120)
                .chartYAxis {
                    AxisMarks { value in
                        AxisValueLabel {
                            if let doubleValue = value.as(Double.self) {
                                Text("\(Int(doubleValue))")
                                    .font(.caption)
                            }
                        }
                    }
                }
                
                // Heart Rate Statistics
                HStack(spacing: 20) {
                    StatItem(
                        title: "Average HR",
                        value: "\(Int(averageHeartRate()))",
                        color: .red
                    )
                    
                    StatItem(
                        title: "Min HR",
                        value: "\(Int(minHeartRate()))",
                        color: .red
                    )
                    
                    StatItem(
                        title: "Max HR",
                        value: "\(Int(maxHeartRate()))",
                        color: .red
                    )
                }
            }
            
            // HRV Data
            if !cardiacManager.hrvData.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Heart Rate Variability")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Chart {
                        ForEach(cardiacManager.hrvData.prefix(50), id: \.timestamp) { sample in
                            LineMark(
                                x: .value("Time", sample.timestamp),
                                y: .value("HRV", sample.value)
                            )
                            .foregroundStyle(.blue)
                            .interpolationMethod(.catmullRom)
                        }
                    }
                    .frame(height: 80)
                    .chartYAxis {
                        AxisMarks { value in
                            AxisValueLabel {
                                if let doubleValue = value.as(Double.self) {
                                    Text("\(Int(doubleValue))")
                                        .font(.caption)
                                }
                            }
                        }
                    }
                    
                    HStack(spacing: 20) {
                        StatItem(
                            title: "Avg HRV",
                            value: "\(Int(averageHRV())) ms",
                            color: .blue
                        )
                        
                        StatItem(
                            title: "HRV Trend",
                            value: hrvTrendText(),
                            color: hrvTrendColor()
                        )
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 2)
    }
    
    private func averageHeartRate() -> Double {
        guard !cardiacManager.heartRateData.isEmpty else { return 0 }
        return cardiacManager.heartRateData.reduce(0) { $0 + $1.value } / Double(cardiacManager.heartRateData.count)
    }
    
    private func minHeartRate() -> Double {
        cardiacManager.heartRateData.map { $0.value }.min() ?? 0
    }
    
    private func maxHeartRate() -> Double {
        cardiacManager.heartRateData.map { $0.value }.max() ?? 0
    }
    
    private func averageHRV() -> Double {
        guard !cardiacManager.hrvData.isEmpty else { return 0 }
        return cardiacManager.hrvData.reduce(0) { $0 + $1.value } / Double(cardiacManager.hrvData.count)
    }
    
    private func hrvTrendText() -> String {
        // Simplified HRV trend calculation
        let recentHRV = cardiacManager.hrvData.prefix(10)
        let olderHRV = cardiacManager.hrvData.dropFirst(10).prefix(10)
        
        guard !recentHRV.isEmpty && !olderHRV.isEmpty else { return "Stable" }
        
        let recentAvg = recentHRV.reduce(0) { $0 + $1.value } / Double(recentHRV.count)
        let olderAvg = olderHRV.reduce(0) { $0 + $1.value } / Double(olderHRV.count)
        
        let change = recentAvg - olderAvg
        
        if change > 5 {
            return "Improving"
        } else if change < -5 {
            return "Declining"
        } else {
            return "Stable"
        }
    }
    
    private func hrvTrendColor() -> Color {
        let trend = hrvTrendText()
        switch trend {
        case "Improving": return .green
        case "Declining": return .red
        default: return .blue
        }
    }
}

// MARK: - Oxygen Saturation Card

struct OxygenSaturationCard: View {
    @StateObject private var cardiacManager = AdvancedCardiacManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "lungs.fill")
                    .foregroundColor(.blue)
                Text("Oxygen Saturation")
                    .font(.headline)
                Spacer()
                Text("\(String(format: "%.1f", cardiacManager.oxygenSaturation))%")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(oxygenColor)
            }
            
            if cardiacManager.oxygenSaturationData.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "lungs")
                        .font(.system(size: 40))
                        .foregroundColor(.blue.opacity(0.6))
                    Text("No oxygen saturation data available")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                // Oxygen Saturation Chart
                Chart {
                    ForEach(cardiacManager.oxygenSaturationData.prefix(50), id: \.timestamp) { sample in
                        LineMark(
                            x: .value("Time", sample.timestamp),
                            y: .value("O2 Sat", sample.value)
                        )
                        .foregroundStyle(.blue)
                        .interpolationMethod(.catmullRom)
                    }
                }
                .frame(height: 120)
                .chartYScale(domain: 90...100)
                .chartYAxis {
                    AxisMarks { value in
                        AxisValueLabel {
                            if let doubleValue = value.as(Double.self) {
                                Text("\(Int(doubleValue))%")
                                    .font(.caption)
                            }
                        }
                    }
                }
                
                // Oxygen Saturation Statistics
                HStack(spacing: 20) {
                    StatItem(
                        title: "Average O2",
                        value: "\(String(format: "%.1f", averageOxygenSaturation()))%",
                        color: .blue
                    )
                    
                    StatItem(
                        title: "Min O2",
                        value: "\(String(format: "%.1f", minOxygenSaturation()))%",
                        color: .blue
                    )
                    
                    StatItem(
                        title: "Status",
                        value: oxygenStatusText(),
                        color: oxygenColor
                    )
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 2)
    }
    
    private func averageOxygenSaturation() -> Double {
        guard !cardiacManager.oxygenSaturationData.isEmpty else { return 0 }
        return cardiacManager.oxygenSaturationData.reduce(0) { $0 + $1.value } / Double(cardiacManager.oxygenSaturationData.count)
    }
    
    private func minOxygenSaturation() -> Double {
        cardiacManager.oxygenSaturationData.map { $0.value }.min() ?? 0
    }
    
    private func oxygenStatusText() -> String {
        let saturation = cardiacManager.oxygenSaturation
        switch saturation {
        case 95...100: return "Normal"
        case 90..<95: return "Low"
        default: return "Very Low"
        }
    }
    
    private var oxygenColor: Color {
        let saturation = cardiacManager.oxygenSaturation
        switch saturation {
        case 95...100: return .green
        case 90..<95: return .yellow
        default: return .red
        }
    }
}

// MARK: - Cardiac Insights Card

struct CardiacInsightsCard: View {
    @StateObject private var cardiacManager = AdvancedCardiacManager.shared
    @State private var selectedInsight: CardiacInsight?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
                Text("Cardiac Insights")
                    .font(.headline)
                Spacer()
            }
            
            if cardiacManager.cardiacInsights.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "lightbulb")
                        .font(.system(size: 40))
                        .foregroundColor(.yellow.opacity(0.6))
                    Text("No cardiac insights yet")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("Continue monitoring to receive personalized insights")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                ForEach(cardiacManager.cardiacInsights.prefix(3), id: \.timestamp) { insight in
                    CardiacInsightRow(insight: insight)
                        .onTapGesture {
                            selectedInsight = insight
                        }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 2)
        .sheet(item: $selectedInsight) { insight in
            CardiacInsightDetailView(insight: insight)
        }
    }
}

struct CardiacInsightRow: View {
    let insight: CardiacInsight
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: insightIcon)
                .foregroundColor(insightColor)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(insight.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(insight.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
                .font(.caption)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
    
    private var insightIcon: String {
        switch insight.type {
        case .afib: return "heart.circle.fill"
        case .fitness: return "figure.run"
        case .heartRate: return "heart.fill"
        case .hrv: return "waveform.path.ecg"
        case .general: return "heart.text.square"
        }
    }
    
    private var insightColor: Color {
        switch insight.severity {
        case .info: return .blue
        case .warning: return .orange
        case .critical: return .red
        }
    }
}

// MARK: - Supporting Views

struct StatItem: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(color)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct CardiacInsightDetailView: View {
    let insight: CardiacInsight
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Insight Header
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: insightIcon)
                                .foregroundColor(insightColor)
                                .font(.title2)
                            Text(insight.title)
                                .font(.title2)
                                .fontWeight(.bold)
                        }
                        
                        Text(insight.description)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // Insight Details
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Details")
                            .font(.headline)
                        
                        DetailRow(title: "Type", value: insight.type.displayName)
                        DetailRow(title: "Severity", value: insight.severity.displayName)
                        DetailRow(title: "Time", value: insight.timestamp, style: .date)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(radius: 1)
                }
                .padding()
            }
            .navigationTitle("Cardiac Insight")
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
    
    private var insightIcon: String {
        switch insight.type {
        case .afib: return "heart.circle.fill"
        case .fitness: return "figure.run"
        case .heartRate: return "heart.fill"
        case .hrv: return "waveform.path.ecg"
        case .general: return "heart.text.square"
        }
    }
    
    private var insightColor: Color {
        switch insight.severity {
        case .info: return .blue
        case .warning: return .orange
        case .critical: return .red
        }
    }
}

struct DetailRow: View {
    let title: String
    let value: String
    let style: DateFormatter.Style?
    
    init(title: String, value: String, style: DateFormatter.Style? = nil) {
        self.title = title
        self.value = value
        self.style = style
    }
    
    init(title: String, value: Date, style: DateFormatter.Style) {
        self.title = title
        self.value = value.formatted(date: style, time: .shortened)
        self.style = style
    }
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
}

// MARK: - Placeholder Views

struct ECGView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Text("ECG View")
                    .font(.title)
                Text("This view would display real-time ECG data and analysis")
                    .foregroundColor(.secondary)
            }
            .navigationTitle("ECG")
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

// MARK: - Extensions

extension AFibStatus {
    var displayName: String {
        switch self {
        case .normal: return "Normal"
        case .low: return "Low Risk"
        case .moderate: return "Moderate Risk"
        case .high: return "High Risk"
        }
    }
}

extension CardiacHealthTrend {
    var displayName: String {
        switch self {
        case .improving: return "Improving"
        case .stable: return "Stable"
        case .declining: return "Declining"
        case .critical: return "Critical"
        }
    }
}

extension AFibAlert.AlertSeverity {
    var displayName: String {
        switch self {
        case .info: return "Info"
        case .warning: return "Warning"
        case .critical: return "Critical"
        }
    }
}

extension FitnessRecommendation.RecommendationType {
    var displayName: String {
        switch self {
        case .cardio: return "Cardio"
        case .strength: return "Strength"
        case .flexibility: return "Flexibility"
        case .recovery: return "Recovery"
        }
    }
}

extension FitnessRecommendation.Intensity {
    var displayName: String {
        switch self {
        case .low: return "Low"
        case .moderate: return "Moderate"
        case .high: return "High"
        }
    }
}

extension CardiacInsight.InsightType {
    var displayName: String {
        switch self {
        case .afib: return "Atrial Fibrillation"
        case .fitness: return "Cardio Fitness"
        case .heartRate: return "Heart Rate"
        case .hrv: return "Heart Rate Variability"
        case .general: return "General"
        }
    }
}

extension CardiacInsight.InsightSeverity {
    var displayName: String {
        switch self {
        case .info: return "Information"
        case .warning: return "Warning"
        case .critical: return "Critical"
        }
    }
}

extension CardiacInsight: Identifiable {
    var id: Date { timestamp }
}

#Preview {
    AdvancedCardiacDashboardView()
} 
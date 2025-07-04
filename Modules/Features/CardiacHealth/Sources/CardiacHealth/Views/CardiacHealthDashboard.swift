import SwiftUI
import HealthKit
import Charts

/// A beautiful, interactive dashboard for visualizing cardiac health metrics and trends.
struct CardiacHealthDashboard: View {
    @ObservedObject var viewModel: CardiacHealthDashboardViewModel
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    summarySection
                    trendChartsSection
                    riskSection
                    recommendationsSection
                }
                .padding()
            }
            .navigationTitle("Cardiac Health Dashboard")
        }
        .onAppear { viewModel.fetchAllData() }
    }
    
    private var headerSection: some View {
        HStack {
            Image(systemName: "heart.fill")
                .foregroundColor(.red)
                .font(.largeTitle)
            VStack(alignment: .leading) {
                Text("Welcome, \(viewModel.userName)")
                    .font(.headline)
                Text("Your latest cardiac health overview")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
    }
    
    private var summarySection: some View {
        CardiacSummaryView(summary: viewModel.summary)
    }
    
    private var trendChartsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Trends")
                .font(.title2)
                .bold()
            CardiacTrendChart(data: viewModel.trendData)
        }
    }
    
    private var riskSection: some View {
        if let risk = viewModel.riskAssessment {
            CardiacRiskView(risk: risk)
        } else {
            EmptyView()
        }
    }
    
    private var recommendationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Personalized Recommendations")
                .font(.title3)
                .bold()
            ForEach(viewModel.recommendations, id: \ .id) { rec in
                RecommendationCardView(recommendation: rec)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    CardiacHealthDashboard(viewModel: .preview)
}

// MARK: - Supporting Views & ViewModel Stubs

struct CardiacSummaryView: View {
    let summary: CardiacSummary
    var body: some View {
        HStack(spacing: 32) {
            VStack {
                Text("\(summary.restingHeartRate, specifier: "%.0f")")
                    .font(.title)
                    .bold()
                Text("Resting HR")
                    .font(.caption)
            }
            VStack {
                Text("\(summary.hrv, specifier: "%.0f")")
                    .font(.title)
                    .bold()
                Text("HRV")
                    .font(.caption)
            }
            VStack {
                Text("\(summary.bloodPressure) mmHg")
                    .font(.title3)
                    .bold()
                Text("Blood Pressure")
                    .font(.caption)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct CardiacTrendChart: View {
    let data: [CardiacTrendData]
    var body: some View {
        Chart(data) { point in
            LineMark(
                x: .value("Date", point.date),
                y: .value("Resting HR", point.restingHeartRate)
            )
            .foregroundStyle(.red)
            LineMark(
                x: .value("Date", point.date),
                y: .value("HRV", point.hrv)
            )
            .foregroundStyle(.blue)
        }
        .frame(height: 200)
        .chartXAxis {
            AxisMarks(values: .stride(by: .day))
        }
    }
}

struct CardiacRiskView: View {
    let risk: CardiacRiskAssessment
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Risk Level: \(risk.level.rawValue)")
                .font(.headline)
                .foregroundColor(risk.level.color)
            Text(risk.summary)
                .font(.body)
        }
        .padding()
        .background(risk.level.color.opacity(0.1))
        .cornerRadius(10)
    }
}

struct RecommendationCardView: View {
    let recommendation: CardiacRecommendation
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(recommendation.title)
                .font(.headline)
            Text(recommendation.detail)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBlue).opacity(0.08))
        .cornerRadius(8)
    }
}

// MARK: - ViewModel & Model Stubs for Preview/Scaffolding

final class CardiacHealthDashboardViewModel: ObservableObject {
    @Published var userName: String = "Alex"
    @Published var summary: CardiacSummary = .preview
    @Published var trendData: [CardiacTrendData] = CardiacTrendData.preview
    @Published var riskAssessment: CardiacRiskAssessment? = .preview
    @Published var recommendations: [CardiacRecommendation] = CardiacRecommendation.preview
    
    func fetchAllData() {
        // TODO: Implement real data fetching from HealthKit, analytics, etc.
    }
    
    static var preview: CardiacHealthDashboardViewModel {
        let vm = CardiacHealthDashboardViewModel()
        return vm
    }
}

struct CardiacSummary {
    let restingHeartRate: Double
    let hrv: Double
    let bloodPressure: String
    static let preview = CardiacSummary(restingHeartRate: 62, hrv: 58, bloodPressure: "120/78")
}

struct CardiacTrendData: Identifiable {
    let id = UUID()
    let date: Date
    let restingHeartRate: Double
    let hrv: Double
    static let preview: [CardiacTrendData] = (0..<7).map {
        CardiacTrendData(date: Calendar.current.date(byAdding: .day, value: -$0, to: Date())!, restingHeartRate: Double.random(in: 60...70), hrv: Double.random(in: 50...65))
    }.reversed()
}

struct CardiacRiskAssessment {
    enum Level: String {
        case low = "Low"
        case moderate = "Moderate"
        case high = "High"
        var color: Color {
            switch self {
            case .low: return .green
            case .moderate: return .yellow
            case .high: return .red
            }
        }
    }
    let level: Level
    let summary: String
    static let preview = CardiacRiskAssessment(level: .moderate, summary: "Your HRV is slightly below average. Consider stress reduction techniques.")
}

struct CardiacRecommendation: Identifiable {
    let id = UUID()
    let title: String
    let detail: String
    static let preview: [CardiacRecommendation] = [
        .init(title: "Increase Daily Activity", detail: "Aim for at least 30 minutes of moderate exercise."),
        .init(title: "Practice Mindfulness", detail: "Try a 5-minute breathing exercise to reduce stress."),
        .init(title: "Monitor Blood Pressure", detail: "Check your blood pressure weekly and log results.")
    ]
}

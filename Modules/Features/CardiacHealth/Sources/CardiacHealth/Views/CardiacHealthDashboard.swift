import SwiftUI
import HealthKit
import Charts
import Foundation

@available(iOS 18.0, macOS 15.0, *)
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
        .task {
            await viewModel.fetchAllData()
        }
    }
    
    private var headerSection: some View {
        HStack {
            Image(systemName: "heart.fill")
                .foregroundColor(.red)
                .font(.largeTitle)
            VStack(alignment: .leading) {
                Text("Cardiac Health Overview")
                    .font(.headline)
                Text("Latest summary below")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
    }
    
    private var summarySection: some View {
        Group {
            if let summary = viewModel.summary {
                CardiacSummaryView(summary: summary)
            } else {
                Text("No summary available")
            }
        }
    }
    
    private var trendChartsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Trends")
                .font(.title2)
                .bold()
            CardiacTrendChart(data: viewModel.trendData.map { CardiacTrendData(date: $0.timestamp, restingHeartRate: Double($0.value), hrv: 0) })
        }
    }
    
    private var riskSection: some View {
        if let risk = viewModel.riskAssessment {
            AnyView(Text(risk))
        } else {
            AnyView(EmptyView())
        }
    }
    
    private var recommendationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Personalized Recommendations")
                .font(.title3)
                .bold()
            ForEach(viewModel.recommendations, id: \.self) { rec in
                Text(rec)
            }
        }
    }
}

// MARK: - Preview

#if DEBUG
@available(iOS 18.0, macOS 15.0, *)
struct CardiacHealthDashboard_Previews: PreviewProvider {
    static var previews: some View {
        let mockVM = MockCardiacHealthDashboardViewModel()
        CardiacHealthDashboard(viewModel: mockVM)
    }
}
#endif

// MARK: - Supporting Views

struct CardiacSummaryView: View {
    let summary: CardiacSummary
    var body: some View {
        HStack(spacing: 32) {
            VStack {
                Text("\(summary.restingHeartRate)")
                    .font(.title)
                    .bold()
                Text("Resting HR")
                    .font(.caption)
            }
            VStack {
                Text("\(summary.hrvScore, specifier: "%.0f")")
                    .font(.title)
                    .bold()
                Text("HRV")
                    .font(.caption)
            }
            VStack {
                Text("- mmHg") // Placeholder, as blood pressure is not in CardiacSummary
                    .font(.title3)
                    .bold()
                Text("Blood Pressure")
                    .font(.caption)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.15))
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

// MARK: - Mock ViewModel for Preview

@available(iOS 18.0, macOS 15.0, *)
class MockCardiacHealthDashboardViewModel: CardiacHealthDashboardViewModel {
    init() {
        super.init(healthKitManager: /* pass a real or dummy manager if required */ DummyHealthKitManager(), ecgInsightManager: DummyECGInsightManager())
        self.summary = CardiacSummary(averageHeartRate: 70, restingHeartRate: 65, hrvScore: 55, timestamp: Date())
        self.trendData = (0..<7).map { i in HeartRateMeasurement(value: 65 + i, timestamp: Calendar.current.date(byAdding: .day, value: -i, to: Date())!) }
        self.riskAssessment = "Risk Level: Moderate"
        self.recommendations = ["Exercise regularly", "Monitor blood pressure"]
    }
}

class DummyHealthKitManager {}
class DummyECGInsightManager {}

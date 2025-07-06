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
            .navigationTitle(LocalizedStringKey("Cardiac Health Dashboard"))
            .accessibilityLabel(LocalizedStringKey("Cardiac Health Dashboard Title"))
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
                Text(LocalizedStringKey("Cardiac Health Overview"))
                    .font(.headline)
                    .accessibilityAddTraits(.isHeader)
                Text(LocalizedStringKey("Latest summary below"))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .accessibilityHidden(true)
            }
            Spacer()
        }
    }
    
    private var summarySection: some View {
        Group {
            if let summary = viewModel.summary {
                CardiacSummaryView(summary: summary)
                    .accessibilityElement(children: .contain)
                    .accessibilityLabel(LocalizedStringKey("Cardiac Summary"))
            } else {
                Text(LocalizedStringKey("No summary available"))
                    .accessibilityLabel(LocalizedStringKey("No cardiac summary available"))
            }
        }
    }
    
    private var trendChartsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(LocalizedStringKey("Trends"))
                .font(.title2)
                .bold()
                .accessibilityAddTraits(.isHeader)
            CardiacTrendChart(data: viewModel.trendData.map { CardiacTrendData(date: $0.timestamp, restingHeartRate: Double($0.value), hrv: 0) })
                .accessibilityLabel(LocalizedStringKey("Cardiac Health Trends Chart"))
                .accessibilityHint(LocalizedStringKey("Displays your resting heart rate and HRV trends over time."))
        }
    }
    
    private var riskSection: some View {
        if let risk = viewModel.riskAssessment {
            AnyView(Text(LocalizedStringKey(risk)))
                .accessibilityLabel(LocalizedStringKey("Cardiac Risk Assessment: \(risk)"))
        } else {
            AnyView(EmptyView())
        }
    }
    
    private var recommendationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(LocalizedStringKey("Personalized Recommendations"))
                .font(.title3)
                .bold()
                .accessibilityAddTraits(.isHeader)
            ForEach(viewModel.recommendations, id: \.self) { rec in
                Text(LocalizedStringKey(rec))
                    .accessibilityLabel(LocalizedStringKey("Recommendation: \(rec)"))
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
                Text(LocalizedStringKey("Resting HR"))
                    .font(.caption)
                    .accessibilityLabel(LocalizedStringKey("Resting Heart Rate"))
            }
            VStack {
                Text("\(summary.hrvScore, specifier: "%.0f")")
                    .font(.title)
                    .bold()
                    .accessibilityValue(Text("\(summary.hrvScore, specifier: "%.0f")"))
                Text(LocalizedStringKey("HRV"))
                    .font(.caption)
                    .accessibilityLabel(LocalizedStringKey("Heart Rate Variability"))
            }
            VStack {
                Text(LocalizedStringKey("- mmHg")) // Placeholder, as blood pressure is not in CardiacSummary
                    .font(.title3)
                    .bold()
                    .accessibilityValue(Text("Blood pressure not available"))
                Text(LocalizedStringKey("Blood Pressure"))
                    .font(.caption)
                    .accessibilityLabel(LocalizedStringKey("Blood Pressure"))
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

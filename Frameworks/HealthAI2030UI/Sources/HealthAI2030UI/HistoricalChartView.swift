import SwiftUI
import Charts

struct HistoricalChartView: View {
    let dateRange: ClosedRange<Date>
    let metrics: Set<String>
    @State private var dataPoints: [DataPoint] = []
    @State private var isLoading = false
    @State private var loadError: Error?

    @EnvironmentObject var macAnalyticsEngine: MacAnalyticsEngine

    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading data...")
            } else if let error = loadError {
                Text("Error: \(error.localizedDescription)")
                    .foregroundColor(.red)
            } else if dataPoints.isEmpty {
                Text("No data available for selected range and metrics.")
                    .foregroundColor(.secondary)
            } else {
                Chart {
                    ForEach(dataPoints) { point in
                        LineMark(
                            x: .value("Date", point.date),
                            y: .value("Value", point.value)
                        )
                        .foregroundStyle(.blue)
                    }
                }
                .chartXAxis { AxisMarks(values: .automatic(desiredCount: 5)) }
                .chartYAxis { AxisMarks() }
            }
        }
        .onChange(of: dateRange) { _ in fetchData() }
        .onChange(of: metrics) { _ in fetchData() }
        .task { fetchData() }
    }

    // Sample data struct for preview
    struct DataPoint: Identifiable {
        let id = UUID()
        let date: Date
        let value: Double
    }

    private func fetchData() {
        isLoading = true
        loadError = nil
        Task {
            do {
                let summary = try await macAnalyticsEngine.aggregateHistoricalData(months: Calendar.current.dateComponents([.month], from: dateRange.lowerBound, to: dateRange.upperBound).month ?? 6)
                let points = zip(summary.timestamps, summary.values).map { DataPoint(date: $0, value: $1) }
                DispatchQueue.main.async {
                    dataPoints = points
                    isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    loadError = error
                    isLoading = false
                }
            }
        }
    }
}

struct HistoricalChartView_Previews: PreviewProvider {
    static var previews: some View {
        HistoricalChartView(dateRange: Date().addingTimeInterval(-30*86400)...Date(), metrics: ["sleepStage"])
            .environmentObject(MacAnalyticsEngine.shared)
    }
}

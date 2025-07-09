import SwiftUI
import Charts

struct TrendlineView: View {
    let dateRange: ClosedRange<Date>
    let metric: String

    @EnvironmentObject var macAnalyticsEngine: MacAnalyticsEngine
    @State private var dataPoints: [DataPoint] = []
    @State private var isLoading = false
    @State private var loadError: Error?

    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading trend...")
            } else if let error = loadError {
                Text("Error: \(error.localizedDescription)")
                    .foregroundColor(.red)
            } else if dataPoints.isEmpty {
                Text("No trend data available.")
                    .foregroundColor(.secondary)
            } else {
                Chart {
                    ForEach(dataPoints) { point in
                        AreaMark(
                            x: .value("Date", point.date),
                            y: .value("Trend", point.value)
                        )
                        .foregroundStyle(.green)
                    }
                }
                .chartXAxis { AxisMarks() }
                .chartYAxis { AxisMarks() }
            }
        }
        .onAppear(perform: fetchData)
        .onChange(of: dateRange) { _ in fetchData() }
        .task { fetchData() }
    }

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
                let months = Calendar.current.dateComponents([.month], from: dateRange.lowerBound, to: dateRange.upperBound).month ?? 6
                let summary = try await macAnalyticsEngine.aggregateHistoricalData(months: months)
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

struct TrendlineView_Previews: PreviewProvider {
    static var previews: some View {
        TrendlineView(dateRange: Date().addingTimeInterval(-30*86400)...Date(), metric: "sleepStage")
            .environmentObject(MacAnalyticsEngine.shared)
    }
}

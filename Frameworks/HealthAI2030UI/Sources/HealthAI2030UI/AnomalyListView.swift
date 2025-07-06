import SwiftUI

struct AnomalyListView: View {
    let dateRange: ClosedRange<Date>
    @EnvironmentObject var macAnalyticsEngine: MacAnalyticsEngine

    @State private var anomalies: [Anomaly] = []
    @State private var isLoading = false
    @State private var loadError: Error?

    struct Anomaly: Identifiable {
        let id = UUID()
        let date: Date
        let description: String
    }

    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading anomalies...")
            } else if let error = loadError {
                Text("Error: \(error.localizedDescription)")
                    .foregroundColor(.red)
            } else if anomalies.isEmpty {
                Text("No anomalies detected.")
                    .foregroundColor(.secondary)
            } else {
                List(anomalies) { anomaly in
                    VStack(alignment: .leading) {
                        Text(anomaly.description)
                            .font(.headline)
                        Text(anomaly.date, style: .date)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .onAppear {
            fetchData()
        }
    }

    private func fetchData() {
        isLoading = true
        loadError = nil
        Task {
            do {
                let records = try await macAnalyticsEngine.fetchAnomalies(for: DateInterval(start: dateRange.lowerBound, end: dateRange.upperBound))
                let list = records.map { Anomaly(date: $0.date, description: $0.description) }
                DispatchQueue.main.async {
                    anomalies = list
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

struct AnomalyListView_Previews: PreviewProvider {
    static var previews: some View {
        AnomalyListView(dateRange: Date().addingTimeInterval(-86400*30)...Date())
            .environmentObject(MacAnalyticsEngine.shared)
    }
}

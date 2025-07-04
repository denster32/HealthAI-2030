import Foundation
import Combine

final class ExportManager: ObservableObject {
    static let shared = ExportManager()

    @Published var lastExportURL: URL?
    @Published var exportError: Error?
    @Published var isExporting = false
    @Published var exportProgress: Double = 0.0

    private init() {}

    /// Export selected metrics and anomalies for the given date range.
    func exportData(dateRange: ClosedRange<Date>, metrics: [String], format: ExportFormat) {
        isExporting = true
        exportProgress = 0.0
        Task {
            do {
                // 1. Fetch time series data
                let engine = MacAnalyticsEngine.shared
                let months = Calendar.current.dateComponents([.month], from: dateRange.lowerBound, to: dateRange.upperBound).month ?? 6
                let trend = try await engine.aggregateHistoricalData(months: months)
                DispatchQueue.main.async { exportProgress = 0.33 }

                // 2. Fetch anomalies
                let anomalies = try await engine.fetchAnomalies(for: DateInterval(start: dateRange.lowerBound, end: dateRange.upperBound))
                DispatchQueue.main.async { exportProgress = 0.66 }

                // 3. Build CSV or FHIR content
                let fileURL: URL
                switch format {
                case .csv:
                    fileURL = try generateCSV(trend: trend, anomalies: anomalies, metrics: metrics)
                case .fhir:
                    fileURL = try generateFHIR(trend: trend, anomalies: anomalies)
                }

                DispatchQueue.main.async {
                    self.lastExportURL = fileURL
                    self.exportError = nil
                    self.exportProgress = 1.0
                    self.isExporting = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.exportError = error
                    self.isExporting = false
                }
            }
        }
    }
}
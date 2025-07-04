import Foundation
import Combine
import MacAnalytics // Import MacAnalytics

@available(macOS 10.15, iOS 13.0, *) // Add availability annotations
final class ExportManager: ObservableObject {
    static let shared = ExportManager()

    @Published var lastExportURL: URL?
    @Published var exportError: Error?
    @Published var isExporting = false
    @Published var exportProgress: Double = 0.0

    private init() {}

    /// Export selected metrics and anomalies for the given date range.
    func exportData(dateRange: ClosedRange<Date>, metrics: [String], format: MacAnalytics.ReportFormat) { // Change ExportFormat to MacAnalytics.ReportFormat
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

                // 3. Generate report using MacAnalyticsEngine
                let fileURL = try await engine.generateReports(format: format, for: DateInterval(start: dateRange.lowerBound, end: dateRange.upperBound)) // Use generateReports

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
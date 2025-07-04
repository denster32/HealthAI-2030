import Foundation
import SwiftUI

/// Manages exporting health and analytics data as CSV or FHIR.
class DataExportManager: ObservableObject {
    static let shared = DataExportManager()

    @Published var lastExportURL: URL?
    @Published var exportError: Error?

    private init() {}

    /// Export selected metrics and anomalies for the given date range.
    func exportData(dateRange: ClosedRange<Date>, metrics: [String], format: ExportFormat) {
        Task {
            do {
                // 1. Fetch time series data
                let engine = MacAnalyticsEngine.shared
                let months = Calendar.current.dateComponents([.month], from: dateRange.lowerBound, to: dateRange.upperBound).month ?? 6
                let trend = try await engine.aggregateHistoricalData(months: months)
                // 2. Fetch anomalies
                let anomalies = try await engine.fetchAnomalies(for: DateInterval(start: dateRange.lowerBound, end: dateRange.upperBound))

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
                }
            } catch {
                DispatchQueue.main.async {
                    self.exportError = error
                }
            }
        }
    }

    enum ExportFormat: String, CaseIterable, Identifiable {
        case csv = "CSV"
        case fhir = "FHIR"
        var id: String { rawValue }
    }

    private func generateCSV(trend: TrendSummary, anomalies: [AnomalyRecord], metrics: [String]) throws -> URL {
        var csv = "date,\(metrics.joined(separator: ","))\n"
        for (d, v) in zip(trend.timestamps, trend.values) {
            let line = "\(ISO8601DateFormatter().string(from: d)),\(v)"
            csv.append(line + "\n")
        }
        csv.append("\nAnomalies:\n")
        for a in anomalies {
            csv.append("\(ISO8601DateFormatter().string(from: a.date)),\(a.description)\n")
        }
        let tmp = FileManager.default.temporaryDirectory
        let url = tmp.appendingPathComponent("HealthDataExport.csv")
        try csv.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    private func generateFHIR(trend: TrendSummary, anomalies: [AnomalyRecord]) throws -> URL {
        // Stub: generate basic FHIR-like JSON
        let fhirDict: [String: Any] = [
            "resourceType": "Bundle",
            "type": "collection",
            "entry": []
        ]
        let data = try JSONSerialization.data(withJSONObject: fhirDict, options: .prettyPrinted)
        let tmp = FileManager.default.temporaryDirectory
        let url = tmp.appendingPathComponent("HealthDataExport.json")
        try data.write(to: url)
        return url
    }
}

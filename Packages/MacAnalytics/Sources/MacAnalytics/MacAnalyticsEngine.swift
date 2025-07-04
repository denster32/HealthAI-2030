import Foundation
import CoreML
import HealthKit
import CloudKit
import SwiftUI
import Metal

public struct TrendSummary {
    let metric: String
    let values: [Double]
    let timestamps: [Date]
}

public enum ReportFormat { case csv, html, pdf }

public struct ModelParameters {
    let sleepStageModelURL: URL?
    let anomalyModelURL: URL?
}

public class MacAnalyticsEngine: ObservableObject {
    public static let shared = MacAnalyticsEngine()

    private let cloudContainer = CKContainer(identifier: "iCloud.com.yourorg.HealthAI")
    private let database = CKContainer(identifier: "iCloud.com.yourorg.HealthAI").privateCloudDatabase

    private let analyticsQueue = DispatchQueue(label: "com.healthai.analytics", qos: .utility)

    @Published public var lastTrendSummary: TrendSummary?
    @Published public var anomalies: [AnomalyRecord] = []
    @Published public var reportURL: URL?
    @Published public var analyticsError: Error?
    @Published public var isLoadingTrend = false
    @Published public var trendError: Error?
    @Published public var isLoadingAnomalies = false
    @Published public var anomaliesError: Error?

    public init() {}

    /// Initialize analytics engine, scheduling background jobs if needed
    public func initialize() {
        // Perform initial sync and schedule overnight jobs
        Task {
            do {
                try await syncWithiCloud()
            } catch {
                DispatchQueue.main.async { self.analyticsError = error }
            }
        }
    }

    /// Enable Metal/NPU optimizations
    public func enableNPUOptimization(device: MTLDevice) {
        // Configure tasks to use Neural Engine
        print("NPU Optimization enabled on device: \(device)")
    }

    /// Run overnight analytics job
    public func performOvernightAnalysis() {
        Task {
            let job = BackgroundAnalyticsJob()
            await job.run()
        }
    }

    /// Sync analytics data with iCloud
    public func syncWithiCloud() async {
        let syncManager = CloudSyncManager()
        _ = try? await syncManager.pullRawMetrics()
    }

    public func aggregateHistoricalData(months: Int) async throws -> TrendSummary {
        DispatchQueue.main.async {
            self.isLoadingTrend = true
            self.trendError = nil
        }
        do {
            // Pull raw metrics from CloudKit
            let syncManager = CloudSyncManager()
            let records = try await syncManager.pullRawMetrics()
            // TODO: Convert CKRecord to raw data array
            // Perform aggregation logic here
            let summary = TrendSummary(metric: "sleepStage", values: [], timestamps: [])
            DispatchQueue.main.async {
                self.lastTrendSummary = summary
                self.isLoadingTrend = false
            }
            return summary
        } catch {
            DispatchQueue.main.async {
                self.analyticsError = error
                self.trendError = error
                self.isLoadingTrend = false
            }
            throw error
        }
    }

    public func retrainModels(on metrics: [HKSample]) async throws -> ModelParameters {
        // Convert HKSamples into training data
        // Call CreateML or CoreML APIs to retrain
        return ModelParameters(sleepStageModelURL: nil, anomalyModelURL: nil)
    }

    public func generateReports(format: ReportFormat, for dateRange: DateInterval) async throws -> URL {
        do {
            let url = try await Task.detached { () -> URL in
                let tmpDir = FileManager.default.temporaryDirectory
                let ext = format == .csv ? "csv" : format == .html ? "html" : "pdf"
                return tmpDir.appendingPathComponent("HealthReport.")
            }.value
            DispatchQueue.main.async { self.reportURL = url }
            return url
        } catch {
            DispatchQueue.main.async { self.analyticsError = error }
            throw error
        }
    }

    public struct AnomalyRecord {
        public let date: Date
        public let description: String
    }

    /// Fetch anomalies from CloudKit in the given date range
    public func fetchAnomalies(for dateRange: DateInterval) async throws -> [AnomalyRecord] {
        DispatchQueue.main.async {
            self.isLoadingAnomalies = true
            self.anomaliesError = nil
        }
        do {
            let syncManager = CloudSyncManager()
            let records = try await syncManager.pullAnomalyRecords(for: dateRange)
            // Map CKRecord to AnomalyRecord
            let results: [AnomalyRecord] = records.compactMap { record in
                guard let date = record["date"] as? Date,
                      let desc = record["description"] as? String else { return nil }
                return AnomalyRecord(date: date, description: desc)
            }
            DispatchQueue.main.async {
                self.anomalies = results
                self.isLoadingAnomalies = false
            }
            return results
        } catch {
            DispatchQueue.main.async {
                self.analyticsError = error
                self.anomaliesError = error
                self.isLoadingAnomalies = false
            }
            throw error
        }
    }
}

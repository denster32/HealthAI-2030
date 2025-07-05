import Foundation
import MetricKit
import OSLog

@available(iOS 18.0, *)
public class MetricManager: NSObject, MXMetricManagerSubscriber {
    @MainActor public static let shared = MetricManager()
    private let logger = Logger(subsystem: "com.HealthAI2030.Analytics", category: "MetricManager")

    private override init() {
        super.init()
    }

    public func start() {
        let metricManager = MXMetricManager.shared
        metricManager.add(self)
        logger.info("MetricManager started and subscribed to MetricKit.")
    }

    public func stop() {
        let metricManager = MXMetricManager.shared
        metricManager.remove(self)
        logger.info("MetricManager stopped and unsubscribed from MetricKit.")
    }

    // MARK: - MXMetricManagerSubscriber

    nonisolated public func didReceive(_ payloads: [MXMetricPayload]) {
        for payload in payloads {
            // Process CPU metrics
            if let cpuMetrics = payload.cpuMetrics {
                logger.debug("CPU Metrics: \(cpuMetrics.cumulativeCPUTime.value)s")
            }

            // Process Memory metrics
            if let memoryMetrics = payload.memoryMetrics {
                logger.debug("Memory Metrics: Peak memory usage \(memoryMetrics.peakMemoryUsage.value) bytes")
            }
            
            // Process Display metrics
            if payload.displayMetrics != nil {
                logger.debug("Display Metrics: Available")
            }

            // Log other relevant metrics
            // For example, application launch time
            if payload.applicationLaunchMetrics != nil {
                logger.debug("App Launch Time: Available")
            }
        }
    }

    nonisolated public func didReceive(_ payloads: [MXDiagnosticPayload]) {
        for payload in payloads {
            // Process crash diagnostics
            if let crashDiagnostics = payload.crashDiagnostics {
                for diagnostic in crashDiagnostics {
                    logger.error("Crash Diagnostic: \(diagnostic.callStackTree.jsonRepresentation())")
                }
            }
            // Process hang diagnostics
            if let hangDiagnostics = payload.hangDiagnostics {
                for diagnostic in hangDiagnostics {
                    logger.warning("Hang Diagnostic: \(diagnostic.callStackTree.jsonRepresentation())")
                }
            }
        }
    }
}

import Foundation
import MetricKit
import OSLog

@available(iOS 18.0, *)
@MainActor
public class MetricManager: NSObject, MXMetricManagerSubscriber {
    public static let shared = MetricManager()
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

    public func didReceive(_ payloads: [MXMetricPayload]) {
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
            if let displayMetrics = payload.displayMetrics {
                 logger.debug("Display Metrics: Average pixel luminance \(displayMetrics.averagePixelLuminance.averageValue.value)")
            }

            // Log other relevant metrics
            // For example, application launch time
            if let appLaunchMetrics = payload.applicationLaunchMetrics {
                logger.debug("App Launch Time: \(appLaunchMetrics.histogrammedTimeToFirstDraw.histogramNumValues) launches, median \(appLaunchMetrics.histogrammedTimeToFirstDraw.median.value)s")
            }
        }
    }

    public func didReceive(_ payloads: [MXDiagnosticPayload]) {
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

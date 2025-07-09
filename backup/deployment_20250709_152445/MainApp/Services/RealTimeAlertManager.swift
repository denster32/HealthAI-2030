import Foundation

/// Manager for real-time alerting on critical issues (e.g., crash spikes)
public final class RealTimeAlertManager {
    public static let shared = RealTimeAlertManager()
    private let threshold: Int
    private var failureCount: Int = 0
    private var alertHandler: ((String) -> Void)?
    
    /// Initialize with a threshold for failures within the monitoring window
    public init(threshold: Int = 5) {
        self.threshold = threshold
    }
    
    /// Set the handler to be called when an alert is triggered
    public func setAlertHandler(_ handler: @escaping (String) -> Void) {
        self.alertHandler = handler
    }
    
    /// Record a failure event; triggers alert when threshold is reached
    public func recordFailure() {
        failureCount += 1
        if failureCount >= threshold {
            alertHandler?("Critical failure threshold exceeded: \(threshold) failures detected.")
            failureCount = 0
        }
    }
} 
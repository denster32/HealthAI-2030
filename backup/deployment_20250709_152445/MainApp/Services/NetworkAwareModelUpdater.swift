import Foundation
import Network

/// Manager for updating ML models based on network conditions.
public class NetworkAwareModelUpdater {
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")

    public init() {
        monitor.start(queue: queue)
    }

    public let defaultMaxCellularModelUpdateSize: Int = 5 * 1024 * 1024 // 5 MB

    /// Determines if the model should be updated based on network conditions and model size.
    public func shouldUpdateModel(for modelSize: Int, maxCellularSize: Int? = nil, completion: @escaping (Bool) -> Void) {
        let threshold = maxCellularSize ?? defaultMaxCellularModelUpdateSize
        monitor.pathUpdateHandler = { path in
            if path.status == .satisfied {
                if path.isExpensive {
                    // Cellular connection: allow updates only for models under threshold.
                    completion(modelSize <= threshold)
                } else {
                    // Wi-Fi connection: allow full updates.
                    completion(true)
                }
            } else {
                // No network: defer updates.
                completion(false)
            }
        }
    }

    /// Synchronous helper to determine if update is allowed based on connection type and model size.
    public func isUpdateAllowed(onExpensive: Bool, modelSize: Int, maxCellularSize: Int? = nil) -> Bool {
        let threshold = maxCellularSize ?? defaultMaxCellularModelUpdateSize
        if onExpensive {
            // Cellular: only if model size within threshold
            return modelSize <= threshold
        } else {
            // Wi-Fi: always allowed
            return true
        }
    }

    /// Schedule an update for large models by retrying on unmetered connections.
    /// - Parameters:
    ///   - modelSize: Size of the model in bytes.
    ///   - retryInterval: Time interval between retries in seconds.
    ///   - completion: Called when update is permitted.
    public func scheduleLargeModelUpdate(modelSize: Int, retryInterval: TimeInterval = 60, completion: @escaping () -> Void) {
        shouldUpdateModel(for: modelSize) { allowed in
            if allowed {
                completion()
            } else {
                // Retry after delay
                DispatchQueue.global().asyncAfter(deadline: .now() + retryInterval) {
                    self.scheduleLargeModelUpdate(modelSize: modelSize, retryInterval: retryInterval, completion: completion)
                }
            }
        }
    }
} 
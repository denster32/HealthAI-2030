import Foundation
import AWSS3

/// Processes and manages remote telemetry data collection
public final class RemoteTelemetryProcessor {
    
    private let uploadManager: TelemetryUploadManager
    private let batchSize: Int
    private var currentBatch: [TelemetryEvent] = []
    
    /// Initialize with configuration
    /// - Parameters:
    ///   - config: Telemetry configuration
    ///   - batchSize: Number of events to batch before upload (default 100)
    public init(config: TelemetryConfig, batchSize: Int = 100) {
        self.uploadManager = TelemetryUploadManager(config: config)
        self.batchSize = batchSize
    }
    
    /// Process a single telemetry event
    /// - Parameter event: Telemetry event to process
    public func process(event: TelemetryEvent) {
        currentBatch.append(event)
        
        if currentBatch.count >= batchSize {
            uploadBatch()
        }
    }
    
    /// Force upload of current batch regardless of size
    public func flush() {
        uploadBatch()
    }
    
    private func uploadBatch() {
        guard !currentBatch.isEmpty else { return }
        
        let batchToUpload = currentBatch
        currentBatch.removeAll()
        
        print("[TelemetryProcessor] Uploading batch of \(batchToUpload.count) events")
        
        uploadManager.upload(events: batchToUpload) { [weak self] result in
            switch result {
            case .failure(let error):
                print("[TelemetryProcessor] Batch upload failed: \(error)")
                self?.handleUploadError(error: error, batch: batchToUpload)
            case .success:
                print("[TelemetryProcessor] Batch upload succeeded")
            }
        }
    }
    
    private func handleUploadError(error: Error, batch: [TelemetryEvent], retryCount: Int = 0, maxRetries: Int = 3) {
        guard retryCount < maxRetries else {
            print("[TelemetryProcessor] Max retries exceeded for batch - saving to local storage")
            do {
                try saveBatchToLocalStorage(batch)
                print("[TelemetryProcessor] Saved batch to local storage")
            } catch {
                print("[TelemetryProcessor] Failed to save batch to local storage: \(error)")
            }
            return
        }
        
        let delay = min(5.0 * pow(2.0, Double(retryCount)), 30.0) // Exponential backoff with max 30s
        print("[TelemetryProcessor] Retrying batch upload in \(delay)s (attempt \(retryCount + 1)/\(maxRetries))")
        
        DispatchQueue.global().asyncAfter(deadline: .now() + delay) { [weak self] in
            self?.uploadManager.upload(events: batch) { result in
                switch result {
                case .failure(let retryError):
                    self?.handleUploadError(error: retryError, batch: batch, retryCount: retryCount + 1)
                case .success:
                    print("[TelemetryProcessor] Batch upload succeeded on retry")
                }
            }
        }
    }
    
    /// Saves a batch of telemetry events to local storage as JSON file
    private func saveBatchToLocalStorage(_ batch: [TelemetryEvent]) throws {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileName = "telemetry_fallback_\(Date().timeIntervalSince1970).json"
        let fileURL = documentsURL.appendingPathComponent(fileName)
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(batch)
        try data.write(to: fileURL, options: .atomic)
    }
}

/// Telemetry event protocol
public protocol TelemetryEvent: Codable {
    var timestamp: Date { get }
    var eventType: String { get }
    var payload: [String: Any] { get }
}

/// Telemetry configuration
public struct TelemetryConfig {
    public let s3Bucket: String
    public let apiEndpoint: URL
    public let apiKey: String
    public let awsRegion: AWSRegionType
    
    public init(s3Bucket: String, apiEndpoint: URL, apiKey: String, awsRegion: AWSRegionType) {
        self.s3Bucket = s3Bucket
        self.apiEndpoint = apiEndpoint
        self.apiKey = apiKey
        self.awsRegion = awsRegion
    }
}
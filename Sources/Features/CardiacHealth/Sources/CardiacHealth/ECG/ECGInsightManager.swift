import Foundation
import Combine

/// ECGInsightManager
///
/// Provides high-level orchestration for ECG data processing, including batch and streaming interfaces.
/// - Asynchronous processing of ECG samples
/// - Streaming support via Combine publishers
/// - Error handling for memory and device constraints
@available(iOS 18.0, macOS 15.0, *)
public class ECGInsightManager {
    private let ecgProcessor = ECGDataProcessor()
    private let processingQueue = DispatchQueue(label: "com.healthai.ecg.processing", qos: .userInitiated)
    private var cancellables = Set<AnyCancellable>()
    
    /// Initialize a new ECGInsightManager.
    public init() {}
    
    /// Process a batch of ECG samples asynchronously.
    /// - Parameters:
    ///   - samples: Raw ECG samples.
    ///   - completion: Completion handler with processed samples and anomaly probabilities.
    public func processECGSamples(_ samples: [Float], completion: @escaping (Result<(processed: [Float], anomalies: [String: Double]), Error>) -> Void) {
        // Check memory constraints before processing
        guard ecgProcessor.checkMemoryConstraints() else {
            completion(.failure(ECGError.memoryLimitExceeded))
            return
        }
        
        processingQueue.async { [weak self] in
            guard let self = self else { return }
            
            // Process raw samples
            let processedSamples = self.ecgProcessor.processECGData(samples)
            
            // Detect anomalies
            let anomalies = self.ecgProcessor.detectAnomalies(processedSamples)
            
            DispatchQueue.main.async {
                completion(.success((processedSamples, anomalies)))
            }
        }
    }
    
    /// Stream ECG data and receive processed results and anomalies as a Combine publisher.
    /// - Parameter publisher: A publisher emitting arrays of raw ECG samples.
    /// - Returns: A publisher emitting tuples of processed samples and anomaly probabilities.
    public func streamECGData(from publisher: AnyPublisher<[Float], Never>) -> AnyPublisher<(processed: [Float], anomalies: [String: Double]), Error> {
        let subject = PassthroughSubject<(processed: [Float], anomalies: [String: Double]), Error>()
        
        publisher
            .buffer(size: 256, prefetch: .keepFull, whenFull: .dropOldest)
            .receive(on: processingQueue)
            .sink { [weak self] samples in
                guard let self = self, self.ecgProcessor.checkMemoryConstraints() else {
                    subject.send(completion: .failure(ECGError.memoryLimitExceeded))
                    return
                }
                
                let processed = self.ecgProcessor.processECGData(samples)
                let anomalies = self.ecgProcessor.detectAnomalies(processed)
                subject.send((processed, anomalies))
            }
            .store(in: &cancellables)
        
        return subject.eraseToAnyPublisher()
    }
}

/// ECGError
///
/// Error types for ECG processing.
@available(iOS 18.0, macOS 15.0, *)
public enum ECGError: Error {
    case memoryLimitExceeded
    case processingTimeout
    case deviceNotSupported
}

@available(iOS 18.0, macOS 15.0, *)
extension ECGError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .memoryLimitExceeded:
            return "ECG processing exceeded device memory constraints"
        case .processingTimeout:
            return "ECG processing took too long to complete"
        case .deviceNotSupported:
            return "Device doesn't support real-time ECG processing"
        }
    }
}
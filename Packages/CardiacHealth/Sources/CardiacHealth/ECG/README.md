# ECG Subsystem (CardiacHealth)

## Overview
The ECG subsystem provides high-performance, cross-platform electrocardiogram (ECG) signal processing and anomaly detection for the HealthAI 2030 platform. It is designed for use on iOS 18+, macOS 15+, and other modern Apple platforms.

## Main Components

### ECGDataProcessor
- **Purpose:** Efficiently processes raw ECG signal data, applies filtering, and detects anomalies using Core ML or CPU fallback.
- **Key Features:**
  - Moving average filtering
  - Performance and memory tracking
  - Core ML-based anomaly detection (with CPU fallback)
  - Memory constraint checks for low-memory devices (e.g., Apple Watch)

### ECGInsightManager
- **Purpose:** Provides high-level orchestration for ECG data processing, including batch and streaming interfaces.
- **Key Features:**
  - Asynchronous processing of ECG samples
  - Streaming support via Combine publishers
  - Error handling for memory and device constraints

## Usage Example

```swift
import CardiacHealth

let processor = ECGDataProcessor()
let samples: [Float] = ... // Raw ECG data
let processed = processor.processECGData(samples)
let anomalies = processor.detectAnomalies(processed)

let manager = ECGInsightManager()
manager.processECGSamples(samples) { result in
    switch result {
    case .success(let (processed, anomalies)):
        print("Processed: \(processed.count) samples, Anomalies: \(anomalies)")
    case .failure(let error):
        print("ECG processing failed: \(error)")
    }
}
```

## File Structure

- `ECGDataProcessor.swift` — Core signal processing and anomaly detection
- `ECGInsightManager.swift` — High-level orchestration and streaming
- `README.md` — This documentation file

## Testing

See `Tests/CardiacHealthTests/ECGProcessorPerformanceTests.swift` for performance and memory tests.

## Platform Support
- iOS 18.0+
- macOS 15.0+
- watchOS 11.0+
- tvOS 18.0+

## Authors
- HealthAI 2030 Team

---

For more information, see the main [CardiacHealth README](../README.md) or the project root documentation. 
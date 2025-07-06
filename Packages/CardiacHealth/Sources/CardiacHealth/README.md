# CardiacHealth Module

## Overview
The CardiacHealth module provides advanced cardiac health analytics, including ECG (Electrocardiogram) signal processing, anomaly detection, and high-level orchestration for health insights. It is part of the HealthAI 2030 platform and is designed for iOS 18+, macOS 15+, and other modern Apple platforms.

## Submodules
- **ECG**: High-performance ECG signal processing and anomaly detection. See [ECG/README.md](ECG/README.md) for details.

## Main Classes
- `CardiacHealth`: Main entry point for cardiac health features.
- `ECGDataProcessor`: Core ECG signal processing and anomaly detection (see ECG submodule).
- `ECGInsightManager`: High-level orchestration and streaming for ECG data (see ECG submodule).

## Usage Example

```swift
import CardiacHealth

let cardiac = CardiacHealth()
let ecgProcessor = cardiac.getECGProcessor()
let samples: [Float] = ... // Raw ECG data
let processed = ecgProcessor.processECGData(samples)
let anomalies = ecgProcessor.detectAnomalies(processed)
```

## Testing
See `Tests/CardiacHealthTests/` for performance and memory tests.

## Platform Support
- iOS 18.0+
- macOS 15.0+
- watchOS 11.0+
- tvOS 18.0+

## Authors
- HealthAI 2030 Team

---

For more information, see the project root documentation. 
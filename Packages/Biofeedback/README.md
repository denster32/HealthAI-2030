# Biofeedback Package

Advanced biofeedback monitoring and intervention system for HealthAI 2030.

## Features

- Real-time heart rate, HRV, and breathing rate monitoring
- Stress level calculation and analysis
- Multiple biofeedback protocols (HRV, breathing, stress reduction, performance)
- Integration with HealthKit for health data
- Spatial audio biofeedback support
- Session management and data persistence

## Usage

### Basic Biofeedback Engine

```swift
import Biofeedback

let engine = BiofeedbackEngine()

// Start a biofeedback session
engine.startSession(protocol: .heartRateVariability)

// Monitor biofeedback status
engine.$biofeedbackStatus
    .sink { status in
        print("Biofeedback status: \(status)")
    }
    .store(in: &cancellables)
```

### Biofeedback Sessions

```swift
let session = BiofeedbackSession(
    name: "Morning Meditation",
    duration: 300, // 5 minutes
    sessionType: .meditation,
    protocol: .heartRateVariability
)
```

### Spatial Audio Integration

```swift
let audioZone = BiofeedbackAudioZone(
    position: BiofeedbackSpatialPosition(x: 1.0, y: 2.0, z: 3.0),
    audioSource: BiofeedbackAudioSource(
        fileName: "nature_sounds",
        fileExtension: "wav",
        category: .nature
    ),
    intensityRange: 0.0...1.0,
    biofeedbackType: .heartRate
)
```

## Protocols

- **Heart Rate Variability (HRV)**: Optimize heart rate variability patterns
- **Breathing**: Guide optimal breathing patterns
- **Stress Reduction**: Reduce stress levels through biofeedback
- **Performance**: Optimize physiological parameters for peak performance

## Requirements

- iOS 18.0+
- macOS 15.0+
- watchOS 11.0+
- tvOS 18.0+

## Dependencies

- HealthKit (for health data access)
- CoreML (for machine learning features)
- Combine (for reactive programming)

## Testing

Run the test suite:

```bash
swift test
```

## License

Part of the HealthAI 2030 platform. 
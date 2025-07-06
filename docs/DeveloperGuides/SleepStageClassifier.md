# Sleep Stage Classification Model

This document describes the sleep stage classification ML model and related feature extraction.


## Feature Extraction

- The `SleepFeatureExtractor` now provides a simple static method:

  ```swift
  let features: [Double] = SleepFeatureExtractor.extractFeatures(from: sensorDataPoints)
  ```

- Each `SleepDataPoint` contains a `timestamp`, `value` (Double), and `type` (e.g., `"heartRate"`, `"accelerometer"`, `"bodyTemperature"`, `"hrv"`, `"oxygenSaturation"`).

- For advanced usage, use the `SleepFeatureExtractorImpl` to get a full `SleepFeatures` struct with:

  - RMSSD and SDNN (HRV metrics)
  - Heart rate average and variability
  - Oxygen saturation average and variability
  - Accelerometer activity count and sleep/wake detection
  - Wrist temperature average and gradient
  - `SleepFeatures.timestamp` contains the feature window's end time


## Model Input

1. Call the feature extractor to get your feature vector.
2. Pass the vector into your CoreML sleep stage classifier.


## SleepSession Model Updates

- `SleepSession` now includes optional metadata:
  
  - `interruptions`: Int? (number of awakenings)
  - `deviceSource`: String?
  - `userNotes`: String?

- Computed properties:
  
  - `wasoDuration`: TimeInterval (Wake After Sleep Onset)
  - `sleepEfficiency`: Double (ratio of sleep time to total time)


## Usage Example

```swift
let sessions: [SleepSession] = // fetched from HealthKit or Core Data
sessions.forEach { session in
    print("Sleep efficiency: \(session.sleepEfficiency * 100)%")
}

let dataPoints: [SleepDataPoint] = // raw sensor data
let featureVector = SleepFeatureExtractor.extractFeatures(from: dataPoints)
let modelOutput = try mySleepModel.prediction(input: featureVector)
```


## Testing

- Unit tests for feature extraction and session calculations are located in `Modules/Features/SleepTracking/Tests/SleepTrackingTests`.
- See `SleepFeatureExtractorTests` and `SleepSessionTests` for coverage examples.


## References

- [SleepStageClassification Notebook](ml/SleepStageClassification.ipynb)
- [CoreML Documentation](https://developer.apple.com/documentation/coreml)

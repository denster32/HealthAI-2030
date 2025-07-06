# HealthAI 2030 API Reference

## Swift Package API Documentation (iOS 18+ / macOS 15+)

This document provides comprehensive API reference for HealthAI 2030's modern Swift packages and frameworks.

## Table of Contents

- [HealthAI2030Foundation](#healthai2030foundation)
- [HealthAI2030ML](#healthai2030ml) 
- [HealthAI2030Graphics](#healthai2030graphics)
- [ModernSwiftDataManager](#modernswiftdatamanager)
- [Health Data Models](#health-data-models)
- [Usage Examples](#usage-examples)

---

## HealthAI2030Foundation

### Core Health Intelligence Framework

The foundation package provides core data models, SwiftData integration, and HealthKit connectivity for iOS 18+.

#### Actor: HealthAI2030Foundation

```swift
@available(iOS 18.0, macOS 15.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
public actor HealthAI2030Foundation
```

**Core Health Intelligence Actor with iOS 18+ features**

##### Properties

```swift
public var isInitialized: Bool { get }
public var healthStore: HKHealthStore { get }
public var modelContainer: ModelContainer? { get }
```

##### Methods

###### `initialize()`
```swift
public func initialize() async throws
```
Initialize the health foundation with HealthKit permissions and SwiftData container.

**Throws:** `HealthFoundationError` if initialization fails

**Example:**
```swift
let foundation = HealthAI2030Foundation.shared
try await foundation.initialize()
```

###### `requestHealthPermissions()`
```swift
public func requestHealthPermissions() async throws
```
Request comprehensive HealthKit permissions for iOS 18+ health data types.

**Health Data Types Requested:**
- Heart Rate & Heart Rate Variability
- Sleep Analysis & Sleep Stages
- Activity & Exercise Data
- Environmental Audio Exposure
- Blood Oxygen & Respiratory Rate
- Body Metrics & Composition

###### `saveHealthData(_:)`
```swift
public func saveHealthData(_ data: ModernHealthData) async throws
```
Save health data to both HealthKit and SwiftData with automatic CloudKit sync.

**Parameters:**
- `data`: ModernHealthData instance to save

**Example:**
```swift
let heartRateData = ModernHealthData(
    timestamp: Date(),
    dataType: .heartRate,
    value: 75.0,
    unit: "bpm",
    deviceSource: "Apple Watch Ultra"
)
try await foundation.saveHealthData(heartRateData)
```

---

## HealthAI2030ML

### Advanced Machine Learning Framework

Provides comprehensive ML capabilities using iOS 18+ SpeechAnalyzer, Vision Framework, MLX, and BNNSGraph.

#### Actor: HealthAI2030ML

```swift
@available(iOS 18.0, macOS 15.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
public actor HealthAI2030ML
```

**Advanced ML Actor for health data analysis**

##### Properties

```swift
public var isModelLoaded: Bool { get }
public var supportedAnalysisTypes: [MLAnalysisType] { get }
```

##### Core Analysis Methods

###### `detectHeartRateAnomaly(heartRateSequence:)`
```swift
public func detectHeartRateAnomaly(
    heartRateSequence: [Double]
) async throws -> HeartRateAnomalyResult
```

Detect anomalies in heart rate patterns using advanced statistical analysis.

**Parameters:**
- `heartRateSequence`: Array of heart rate values (minimum 10 values)

**Returns:** `HeartRateAnomalyResult` with anomaly detection results

**Example:**
```swift
let heartRates = [72.0, 75.0, 73.0, 68.0, 125.0, 130.0, 74.0]
let result = try await ml.detectHeartRateAnomaly(heartRateSequence: heartRates)
if result.isAnomaly {
    print("Anomaly detected with score: \(result.anomalyScore)")
}
```

###### `analyzeSleepStage(heartRate:movement:timestamp:)`
```swift
public func analyzeSleepStage(
    heartRate: Double,
    movement: Double,
    timestamp: Date
) async throws -> SleepStageResult
```

Analyze sleep stage using multimodal data inputs.

**Parameters:**
- `heartRate`: Current heart rate (BPM)
- `movement`: Movement intensity (0.0-1.0)
- `timestamp`: Analysis timestamp

**Returns:** `SleepStageResult` with predicted sleep stage

###### `analyzeStressLevel(heartRate:heartRateVariability:voiceFeatures:)`
```swift
public func analyzeStressLevel(
    heartRate: Double,
    heartRateVariability: Double,
    voiceFeatures: VoiceFeatures?
) async throws -> StressAnalysisResult
```

Comprehensive stress analysis using physiological and voice data.

**Parameters:**
- `heartRate`: Current heart rate
- `heartRateVariability`: HRV measurement (RMSSD)
- `voiceFeatures`: Optional voice analysis features from SpeechAnalyzer

**Returns:** `StressAnalysisResult` with stress level and confidence

##### iOS 18+ Speech Analysis

###### `analyzeVoiceStress(audioBuffer:)`
```swift
@available(iOS 18.0, *)
public func analyzeVoiceStress(
    audioBuffer: AVAudioPCMBuffer
) async throws -> VoiceStressResult
```

Analyze voice patterns for stress indicators using iOS 18+ SpeechAnalyzer.

**Parameters:**
- `audioBuffer`: Audio buffer containing voice sample

**Returns:** `VoiceStressResult` with stress indicators

##### Vision Framework Integration

###### `analyzeFacialStress(image:)`
```swift
public func analyzeFacialStress(
    image: UIImage
) async throws -> FacialStressResult
```

Analyze facial expressions for stress and emotion detection.

**Parameters:**
- `image`: Face image for analysis

**Returns:** `FacialStressResult` with emotion and stress indicators

---

## HealthAI2030Graphics

### Metal 4 Graphics and Visualization Framework

Advanced graphics rendering for health data visualization using Metal 4 and Shaders 3.0.

#### Class: HealthAI2030Graphics

```swift
@available(iOS 18.0, macOS 15.0, tvOS 18.0, visionOS 2.0, *)
public final class HealthAI2030Graphics
```

**Metal 4 graphics engine for health visualizations**

##### Properties

```swift
public var metalDevice: MTLDevice? { get }
public var isMetalAvailable: Bool { get }
public var supportedShaderTypes: [ShaderType] { get }
```

##### Initialization

###### `init()`
```swift
public init() throws
```

Initialize Metal 4 graphics engine with health shader library.

**Throws:** `GraphicsError` if Metal is unavailable

##### Health Fractal Generation

###### `generateHealthFractal(healthData:size:time:)`
```swift
public func generateHealthFractal(
    healthData: [ModernHealthData],
    size: CGSize,
    time: Double
) async throws -> MTLTexture?
```

Generate dynamic health fractal visualization using Metal compute shaders.

**Parameters:**
- `healthData`: Array of health data for visualization
- `size`: Output texture size
- `time`: Animation time parameter

**Returns:** Metal texture containing fractal visualization

**Example:**
```swift
let graphics = try HealthAI2030Graphics()
let healthData = await dataManager.getRecentHealthData(type: .heartRate)
let fractalTexture = try await graphics.generateHealthFractal(
    healthData: healthData,
    size: CGSize(width: 1024, height: 1024),
    time: CACurrentMediaTime()
)
```

###### `renderHeartRateWaveform(heartRateData:)`
```swift
public func renderHeartRateWaveform(
    heartRateData: [Double]
) async throws -> MTLTexture?
```

Render real-time heart rate waveform visualization.

**Parameters:**
- `heartRateData`: Array of heart rate values

**Returns:** Metal texture with waveform visualization

##### Sleep Visualization

###### `renderSleepStageTransitions(sleepData:duration:)`
```swift
public func renderSleepStageTransitions(
    sleepData: [SleepStageData],
    duration: TimeInterval
) async throws -> MTLTexture?
```

Create immersive sleep stage transition visualization.

**Parameters:**
- `sleepData`: Sleep stage progression data
- `duration`: Total sleep duration

**Returns:** Metal texture with sleep visualization

---

## ModernSwiftDataManager

### iOS 18+ SwiftData with CloudKit Integration

Comprehensive data management with automatic CloudKit synchronization.

#### Class: ModernSwiftDataManager

```swift
@available(iOS 18.0, macOS 15.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
@Observable
public final class ModernSwiftDataManager
```

**Modern SwiftData manager with CloudKit sync**

##### Properties

```swift
public static let shared: ModernSwiftDataManager
public var isInitialized: Bool { get }
public var syncStatus: CloudKitSyncStatus { get }
public var lastSyncDate: Date? { get }
```

##### Initialization

###### `initialize()`
```swift
public func initialize() async
```

Initialize SwiftData container with CloudKit integration.

##### Generic CRUD Operations

###### `save(_:)`
```swift
public func save<T: PersistentModel>(_ model: T) async throws
```

Save any SwiftData model with automatic CloudKit sync.

**Type Parameters:**
- `T`: PersistentModel conforming type

**Parameters:**
- `model`: Model instance to save

**Example:**
```swift
let healthData = ModernHealthData(
    timestamp: Date(),
    dataType: .heartRate,
    value: 72.0
)
try await dataManager.save(healthData)
```

###### `fetch(_:predicate:sortBy:)`
```swift
public func fetch<T: PersistentModel>(
    _ modelType: T.Type,
    predicate: Predicate<T>? = nil,
    sortBy: [SortDescriptor<T>] = []
) async throws -> [T]
```

Fetch models with predicate support and sorting.

**Type Parameters:**
- `T`: PersistentModel conforming type

**Parameters:**
- `modelType`: Type of model to fetch
- `predicate`: Optional filtering predicate
- `sortBy`: Sort descriptors

**Returns:** Array of matching models

**Example:**
```swift
let predicate = #Predicate<ModernHealthData> { data in
    data.dataType == .heartRate && data.timestamp > Date().addingTimeInterval(-86400)
}
let recentHeartRate = try await dataManager.fetch(
    ModernHealthData.self,
    predicate: predicate,
    sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
)
```

##### Health-Specific Operations

###### `saveHealthData(dataType:value:unit:deviceSource:timestamp:)`
```swift
public func saveHealthData(
    dataType: HealthDataType,
    value: Double,
    unit: String? = nil,
    deviceSource: String? = nil,
    timestamp: Date = Date()
) async throws
```

Convenient health data saving with automatic ML analysis trigger.

**Parameters:**
- `dataType`: Type of health data
- `value`: Numeric value
- `unit`: Optional unit string
- `deviceSource`: Source device identifier
- `timestamp`: Data timestamp

###### `getRecentHealthData(type:limit:)`
```swift
public func getRecentHealthData(
    type: HealthDataType,
    limit: Int = 100
) async throws -> [ModernHealthData]
```

Retrieve recent health data of specific type.

**Parameters:**
- `type`: Health data type to retrieve
- `limit`: Maximum number of records

**Returns:** Array of recent health data

##### Privacy and Export

###### `exportUserData()`
```swift
public func exportUserData() async throws -> Data
```

Export all user data for privacy compliance (GDPR/CCPA).

**Returns:** JSON encoded user data

###### `deleteAllUserData()`
```swift
public func deleteAllUserData() async throws
```

Delete all user data (Right to be forgotten).

---

## Health Data Models

### Core Health Data Types

#### ModernHealthData

```swift
@available(iOS 18.0, macOS 15.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
@Model
public final class ModernHealthData
```

**Primary health data model with CloudKit sync**

##### Properties

```swift
@Attribute(.unique) public var id: UUID
public var timestamp: Date
public var dataType: HealthDataType
public var value: Double
public var unit: String?
public var deviceSource: String?
public var confidence: Double
public var metadata: Data?
```

#### HealthDataType

```swift
public enum HealthDataType: String, CaseIterable, Codable
```

**Supported health data types**

##### Cases

```swift
case heartRate = "heart_rate"
case heartRateVariability = "heart_rate_variability"
case sleepAnalysis = "sleep_analysis"
case stressLevel = "stress_level"
case oxygenSaturation = "oxygen_saturation"
case respiratoryRate = "respiratory_rate"
case bodyTemperature = "body_temperature"
case bloodPressure = "blood_pressure"
case stepCount = "step_count"
case activeEnergy = "active_energy"
case exerciseTime = "exercise_time"
case environmentalAudio = "environmental_audio"
case mindfulnessSession = "mindfulness_session"
```

#### HealthSession

```swift
@available(iOS 18.0, macOS 15.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
@Model
public final class HealthSession
```

**Health monitoring session model**

##### Properties

```swift
@Attribute(.unique) public var id: UUID
public var startTime: Date
public var endTime: Date?
public var sessionType: SessionType
public var duration: TimeInterval
@Relationship public var healthData: [ModernHealthData]
```

#### SessionType

```swift
public enum SessionType: String, CaseIterable, Codable
```

**Health session types**

##### Cases

```swift
case sleep = "sleep"
case exercise = "exercise"
case meditation = "meditation"
case stress_monitoring = "stress_monitoring"
case cardiac_analysis = "cardiac_analysis"
case breathing_exercise = "breathing_exercise"
```

---

## Usage Examples

### Complete Health Monitoring Setup

```swift
import HealthAI2030Foundation
import HealthAI2030ML
import HealthAI2030Graphics

class HealthMonitoringController {
    private let foundation = HealthAI2030Foundation.shared
    private let ml = HealthAI2030ML.shared
    private let graphics = try! HealthAI2030Graphics()
    private let dataManager = ModernSwiftDataManager.shared
    
    func initializeHealthMonitoring() async {
        do {
            // Initialize core systems
            try await foundation.initialize()
            try await ml.initialize()
            await dataManager.initialize()
            
            // Request health permissions
            try await foundation.requestHealthPermissions()
            
            print("Health monitoring initialized successfully")
            
        } catch {
            print("Failed to initialize health monitoring: \(error)")
        }
    }
    
    func performHealthAnalysis() async {
        do {
            // Get recent heart rate data
            let heartRateData = try await dataManager.getRecentHealthData(
                type: .heartRate,
                limit: 50
            )
            
            // Analyze for anomalies
            let heartRateValues = heartRateData.map { $0.value }
            let anomalyResult = try await ml.detectHeartRateAnomaly(
                heartRateSequence: heartRateValues
            )
            
            if anomalyResult.isAnomaly {
                print("Heart rate anomaly detected!")
                // Trigger notification or alert
            }
            
            // Generate health visualization
            let fractalTexture = try await graphics.generateHealthFractal(
                healthData: heartRateData,
                size: CGSize(width: 512, height: 512),
                time: CACurrentMediaTime()
            )
            
            // Display visualization in UI
            // updateHealthVisualization(fractalTexture)
            
        } catch {
            print("Health analysis failed: \(error)")
        }
    }
}
```

### Real-time Health Data Collection

```swift
func startRealTimeHealthMonitoring() async {
    // Start continuous health data collection
    Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
        Task {
            await collectAndAnalyzeHealthData()
        }
    }
}

private func collectAndAnalyzeHealthData() async {
    do {
        // Simulate or collect real health data
        let currentHeartRate = await getCurrentHeartRate()
        let currentHRV = await getCurrentHRV()
        
        // Save to SwiftData with CloudKit sync
        try await dataManager.saveHealthData(
            dataType: .heartRate,
            value: currentHeartRate,
            unit: "bpm",
            deviceSource: "Apple Watch Ultra"
        )
        
        // Perform stress analysis
        let stressResult = try await ml.analyzeStressLevel(
            heartRate: currentHeartRate,
            heartRateVariability: currentHRV,
            voiceFeatures: nil
        )
        
        if stressResult.stressLevel > 0.7 {
            // Suggest breathing exercise
            await triggerBreathingExercise()
        }
        
    } catch {
        print("Real-time monitoring error: \(error)")
    }
}
```

### Sleep Analysis Pipeline

```swift
func analyzeSleepSession() async {
    do {
        // Get sleep session data
        let sleepData = try await dataManager.fetch(
            HealthSession.self,
            predicate: #Predicate { $0.sessionType == .sleep }
        )
        
        guard let lastSleepSession = sleepData.first else { return }
        
        // Analyze sleep stages
        for healthData in lastSleepSession.healthData {
            if healthData.dataType == .heartRate {
                let sleepStageResult = try await ml.analyzeSleepStage(
                    heartRate: healthData.value,
                    movement: 0.0, // Get from motion data
                    timestamp: healthData.timestamp
                )
                
                print("Sleep stage: \(sleepStageResult.stage)")
            }
        }
        
        // Generate sleep visualization
        let sleepVisualization = try await graphics.renderSleepStageTransitions(
            sleepData: [], // Convert to SleepStageData
            duration: lastSleepSession.duration
        )
        
    } catch {
        print("Sleep analysis failed: \(error)")
    }
}
```

---

## Error Handling

### Common Error Types

```swift
// Foundation errors
public enum HealthFoundationError: Error {
    case healthKitUnavailable
    case permissionDenied
    case dataCorrupted
}

// ML errors  
public enum MLAnalysisError: Error {
    case modelNotLoaded
    case insufficientData
    case analysisTimeout
}

// Graphics errors
public enum GraphicsError: Error {
    case metalUnavailable
    case shaderCompilationFailed
    case textureCreationFailed
}

// SwiftData errors
public enum SwiftDataError: Error {
    case contextNotAvailable
    case saveFailed(String)
    case fetchFailed(String)
}
```

### Error Handling Best Practices

```swift
func handleHealthDataError(_ error: Error) {
    switch error {
    case HealthFoundationError.permissionDenied:
        // Guide user to Settings app
        presentHealthPermissionGuide()
        
    case MLAnalysisError.insufficientData:
        // Request more data collection
        suggestLongerMonitoringPeriod()
        
    case SwiftDataError.saveFailed(let reason):
        // Retry with exponential backoff
        scheduleRetryWithBackoff(reason: reason)
        
    default:
        // Log error and show generic message
        logger.error("Unexpected health error: \(error)")
        showGenericErrorAlert()
    }
}
```

---

This API reference covers the core functionality of HealthAI 2030's modern Swift packages. For additional examples and advanced usage patterns, see the [Developer Guide](DEVELOPER_GUIDE.md) and [Examples Repository](https://github.com/healthai2030/examples).
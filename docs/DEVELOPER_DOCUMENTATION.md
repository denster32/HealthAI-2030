# SomnaSync Pro - Developer Documentation

## Table of Contents
1. [Overview](#overview)
2. [Architecture](#architecture)
3. [Core Components](#core-components)
4. [API Reference](#api-reference)
5. [Data Models](#data-models)
6. [Audio System](#audio-system)
7. [AI/ML Integration](#aiml-integration)
8. [HealthKit Integration](#healthkit-integration)
9. [Apple Watch Integration](#apple-watch-integration)
10. [Testing](#testing)
11. [Deployment](#deployment)
12. [Troubleshooting](#troubleshooting)

## Overview

SomnaSync Pro is an advanced sleep optimization app that combines AI-powered sleep analysis with high-quality audio generation. The app is built using SwiftUI and follows modern iOS development practices.

### Key Features
- **AI Sleep Analysis**: Machine learning algorithms analyze sleep patterns
- **Premium Audio Generation**: High-quality binaural beats and nature sounds
- **HealthKit Integration**: Comprehensive health data monitoring
- **Apple Watch Support**: Real-time biometric tracking
- **Smart Alarm System**: Optimal wake-up timing
- **Custom Soundscapes**: Personalized audio experiences

## Architecture

### High-Level Architecture
```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   SwiftUI Views │    │   ViewModels    │    │   Services      │
│                 │    │                 │    │                 │
│ • SleepView     │◄──►│ • SleepManager  │◄──►│ • AudioEngine   │
│ • OnboardingView│    │ • HealthKitMgr  │    │ • AIEngine      │
│ • SettingsView  │    │ • WatchManager  │    │ • AlarmSystem   │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                │
                                ▼
                       ┌─────────────────┐
                       │   Data Layer    │
                       │                 │
                       │ • Core Data     │
                       │ • UserDefaults  │
                       │ • HealthKit     │
                       │ • ML Models     │
                       └─────────────────┘
```

### Design Patterns
- **MVVM**: Model-View-ViewModel architecture
- **Singleton**: Shared managers for core functionality
- **Observer**: Combine framework for reactive updates
- **Factory**: Audio generation and ML model creation
- **Strategy**: Different audio generation algorithms

## Core Components

### 1. Managers
Managers handle core app functionality and state management.

#### SleepManager
```swift
class SleepManager: ObservableObject {
    static let shared = SleepManager()
    
    // Core sleep tracking functionality
    func startSleepSession() async
    func endSleepSession() async
    func updateSleepStage(_ stage: SleepStage) async
}
```

#### HealthKitManager
```swift
class HealthKitManager: ObservableObject {
    static let shared = HealthKitManager()
    
    // HealthKit integration
    func requestAuthorization() async -> Bool
    func startBiometricMonitoring() async
    func saveSleepSession(_ session: SleepSession) async
}
```

#### AppleWatchManager
```swift
class AppleWatchManager: ObservableObject {
    static let shared = AppleWatchManager()
    
    // Apple Watch communication
    func startWatchSession() async
    func sendDataToWatch(_ data: BiometricData) async
    func receiveWatchData() async -> BiometricData?
}
```

### 2. Services
Services provide specialized functionality.

#### AudioGenerationEngine
```swift
class AudioGenerationEngine: ObservableObject {
    static let shared = AudioGenerationEngine()
    
    // Audio generation
    func generatePreSleepAudio(type: PreSleepAudioType) async
    func generateSleepAudio(type: SleepAudioType) async
    func createCustomSoundscape(layers: [AudioLayer]) async
}
```

#### AISleepAnalysisEngine
```swift
class AISleepAnalysisEngine: ObservableObject {
    static let shared = AISleepAnalysisEngine()
    
    // AI analysis
    func predictSleepStage(_ data: BiometricData) async -> SleepStagePrediction
    func analyzeSleepSession(_ session: SleepSession) async -> SleepAnalysis
    func generateRecommendations() async -> [SleepRecommendation]
}
```

#### SmartAlarmSystem
```swift
class SmartAlarmSystem: ObservableObject {
    static let shared = SmartAlarmSystem()
    
    // Smart alarm functionality
    func predictOptimalWakeTime() async -> Date
    func setSmartAlarm(for targetTime: Date) async
    func cancelAlarm() async
}
```

## API Reference

### SleepManager API

#### Starting a Sleep Session
```swift
// Start monitoring sleep with specified tracking mode
await SleepManager.shared.startSleepSession()

// Available tracking modes
enum TrackingMode {
    case appleWatch    // Apple Watch only
    case hybrid        // iPhone + Apple Watch
    case iphoneOnly    // iPhone only
}
```

#### Ending a Sleep Session
```swift
// End current sleep session and generate analysis
let analysis = await SleepManager.shared.endSleepSession()

// Analysis includes:
// - Sleep quality score
// - Sleep stage breakdown
// - Recommendations
// - Insights
```

#### Sleep Stage Updates
```swift
// Update current sleep stage
await SleepManager.shared.updateSleepStage(.deep)

// Available sleep stages
enum SleepStage {
    case awake
    case light
    case deep
    case rem
    case unknown
}
```

### AudioGenerationEngine API

#### Pre-Sleep Audio
```swift
// Generate pre-sleep audio for 30 minutes
await AudioGenerationEngine.shared.generatePreSleepAudio(
    type: .binauralBeats(frequency: 6.0),
    duration: 1800
)

// Available pre-sleep audio types
enum PreSleepAudioType {
    case binauralBeats(frequency: Double)
    case whiteNoise(color: NoiseColor)
    case natureSounds(environment: NatureEnvironment)
    case guidedMeditation(style: MeditationStyle)
    case ambientMusic(genre: AmbientGenre)
}
```

#### Sleep Audio
```swift
// Generate sleep audio for 8 hours
await AudioGenerationEngine.shared.generateSleepAudio(
    type: .deepSleep(frequency: 2.5),
    duration: 28800
)

// Available sleep audio types
enum SleepAudioType {
    case deepSleep(frequency: Double)
    case continuousWhiteNoise(color: NoiseColor)
    case oceanWaves(intensity: WaveIntensity)
    case rainSounds(intensity: RainIntensity)
    case forestAmbience(timeOfDay: TimeOfDay)
}
```

#### Custom Soundscapes
```swift
// Create custom audio mix
let layers = [
    AudioLayer(type: .binauralBeats, volume: 0.5),
    AudioLayer(type: .natureSounds, volume: 0.3),
    AudioLayer(type: .whiteNoise, volume: 0.2)
]

let soundscape = await AudioGenerationEngine.shared.createCustomSoundscape(layers: layers)
await AudioGenerationEngine.shared.playCustomSoundscape(soundscape)
```

### AISleepAnalysisEngine API

#### Sleep Stage Prediction
```swift
// Predict current sleep stage from biometric data
let prediction = await AISleepAnalysisEngine.shared.predictSleepStage(biometricData)

// Prediction includes:
// - Predicted sleep stage
// - Confidence level
// - Sleep quality score
// - Stage probabilities
```

#### Sleep Analysis
```swift
// Analyze completed sleep session
let analysis = await AISleepAnalysisEngine.shared.analyzeSleepSession(session)

// Analysis includes:
// - Sleep quality metrics
// - Stage breakdown percentages
// - Sleep efficiency
// - Recommendations
// - Insights
```

## Data Models

### Core Data Models

#### BiometricData
```swift
struct BiometricData: Codable {
    let timestamp: Date
    let heartRate: Double
    let heartRateVariability: Double
    let movement: Double
    let respiratoryRate: Double
    let oxygenSaturation: Double
    let temperature: Double
    let sleepStage: SleepStage?
}
```

#### SleepSession
```swift
struct SleepSession: Codable, Identifiable {
    let id = UUID()
    let startTime: Date
    var endTime: Date?
    let sleepStage: SleepStage
    let quality: Double
    let cycleCount: Int
    var biometricData: [BiometricData] = []
}
```

#### SleepAnalysis
```swift
struct SleepAnalysis: Codable {
    let session: SleepSession
    let sleepStages: [SleepStage]
    let sleepQuality: Double
    let deepSleepPercentage: Double
    let remSleepPercentage: Double
    let lightSleepPercentage: Double
    let awakePercentage: Double
    let recommendations: [SleepRecommendation]
    let insights: [SleepInsight]
}
```

### Audio Models

#### AudioType
```swift
enum AudioType: Equatable {
    case none
    case preSleep(PreSleepAudioType)
    case sleep(SleepAudioType)
    case custom(CustomSoundscape)
}
```

#### CustomSoundscape
```swift
struct CustomSoundscape: Identifiable, Codable {
    let id: UUID
    var name: String
    var layers: [AudioLayer]
    var duration: TimeInterval
    var audioBuffer: Data?
    var createdAt: Date
}
```

## Audio System

### Audio Generation Pipeline
```
User Request → AudioType Selection → Generator Selection → Audio Generation → Post-Processing → Playback
```

### Supported Audio Types

#### Binaural Beats
- **Frequency Range**: 2.5Hz - 20Hz
- **Base Frequency**: 200Hz
- **Quality**: 48kHz, 24-bit
- **Features**: Harmonics, spatial effects, adaptive modulation

#### White Noise
- **Types**: White, Pink, Brown
- **Quality**: 48kHz, 24-bit
- **Features**: Stereo separation, filtering

#### Nature Sounds
- **Environments**: Ocean, Forest, Rain, Stream, Wind
- **Quality**: 48kHz, 24-bit
- **Features**: Multi-layer generation, realistic variations

### Audio Processing Features
- **Spatial Audio**: Immersive 3D audio experience
- **Adaptive Mixing**: Real-time audio adjustment
- **Smart Fading**: Gradual volume changes
- **EQ Presets**: Optimized frequency response
- **Reverb**: Environmental simulation

## AI/ML Integration

### Machine Learning Pipeline
```
Biometric Data → Feature Extraction → ML Model → Prediction → Post-Processing → Result
```

### Core ML Model
- **Model**: SleepStagePredictor.mlmodel
- **Input**: SleepFeatures (heart rate, HRV, movement, etc.)
- **Output**: SleepStagePrediction
- **Training**: Custom dataset with sleep stage annotations

### Feature Engineering
```swift
struct SleepFeatures: Codable {
    let heartRate: Double
    let heartRateVariability: Double
    let movement: Double
    let respiratoryRate: Double
    let oxygenSaturation: Double
    let temperature: Double
    let timeOfDay: Double
    let previousStage: SleepStage
}
```

### Model Training
```python
# Training script: train_sleep_model.py
# Requirements: requirements.txt
# Output: SleepStagePredictor.mlmodel
```

## HealthKit Integration

### Required Permissions
```swift
let typesToRead: Set<HKObjectType> = [
    HKObjectType.quantityType(forIdentifier: .heartRate)!,
    HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!,
    HKObjectType.quantityType(forIdentifier: .respiratoryRate)!,
    HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
]
```

### Data Synchronization
```swift
// Save sleep session to HealthKit
await HealthKitManager.shared.saveSleepSession(session)

// Read sleep data from HealthKit
let sleepData = await HealthKitManager.shared.readSleepData()
```

## Apple Watch Integration

### Watch Connectivity
```swift
// Send data to Apple Watch
await AppleWatchManager.shared.sendDataToWatch(biometricData)

// Receive data from Apple Watch
let watchData = await AppleWatchManager.shared.receiveWatchData()
```

### Watch App Features
- Real-time biometric monitoring
- Sleep stage detection
- Haptic feedback
- Audio playback control

## Testing

### Unit Tests
```swift
// Test sleep stage prediction
func testSleepStagePrediction() async {
    let data = BiometricData(heartRate: 60, heartRateVariability: 50)
    let prediction = await AISleepAnalysisEngine.shared.predictSleepStage(data)
    XCTAssertNotNil(prediction)
    XCTAssertTrue(prediction.confidence > 0.5)
}
```

### Integration Tests
```swift
// Test complete sleep session
func testCompleteSleepSession() async {
    await SleepManager.shared.startSleepSession()
    // Simulate sleep data
    let analysis = await SleepManager.shared.endSleepSession()
    XCTAssertNotNil(analysis)
    XCTAssertTrue(analysis.sleepQuality > 0)
}
```

### Performance Tests
```swift
// Test audio generation performance
func testAudioGenerationPerformance() {
    measure {
        // Generate 30 minutes of audio
        await AudioGenerationEngine.shared.generatePreSleepAudio(
            type: .binauralBeats(frequency: 6.0),
            duration: 1800
        )
    }
}
```

## Deployment

### Build Configuration
1. **Target**: SomnaSync
2. **Deployment Target**: iOS 15.0+
3. **Architecture**: arm64
4. **Optimization**: Release mode

### Required Capabilities
- HealthKit
- Background Modes (audio, background processing)
- Apple Watch App
- Push Notifications

### App Store Preparation
1. **Screenshots**: 6.7", 6.5", 5.5" iPhone + iPad
2. **App Icon**: 1024x1024 PNG
3. **Metadata**: Description, keywords, promotional text
4. **Privacy Policy**: Required for HealthKit usage

### Code Signing
```bash
# Archive the app
xcodebuild -project SomnaSync.xcodeproj -scheme SomnaSync -archivePath SomnaSync.xcarchive archive

# Export for App Store
xcodebuild -exportArchive -archivePath SomnaSync.xcarchive -exportPath Export -exportOptionsPlist ExportOptions.plist
```

## Troubleshooting

### Common Issues

#### Audio Generation Fails
```swift
// Check audio session configuration
try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)

// Verify audio permissions
AVAudioSession.sharedInstance().recordPermission == .granted
```

#### HealthKit Authorization Fails
```swift
// Check HealthKit availability
HKHealthStore.isHealthDataAvailable()

// Request permissions properly
healthStore.requestAuthorization(toShare: nil, read: typesToRead) { success, error in
    // Handle result
}
```

#### ML Model Loading Fails
```swift
// Verify model file exists
guard let modelURL = Bundle.main.url(forResource: "SleepStagePredictor", withExtension: "mlmodel") else {
    // Handle missing model
    return
}

// Load model safely
do {
    model = try SleepStagePredictorModel(contentsOf: modelURL)
} catch {
    // Handle loading error
}
```

#### Apple Watch Communication Issues
```swift
// Check Watch Connectivity
if WCSession.isSupported() {
    let session = WCSession.default
    session.delegate = self
    session.activate()
}

// Verify session state
WCSession.default.activationState == .activated
```

### Debug Logging
```swift
// Enable debug logging
Logger.app.debug("Debug message")
Logger.audioEngine.info("Audio generation started")
Logger.sleepManager.error("Sleep session failed")
```

### Performance Monitoring
```swift
// Monitor memory usage
let memoryUsage = ProcessInfo.processInfo.physicalMemory

// Monitor CPU usage
let cpuUsage = ProcessInfo.processInfo.systemUptime

// Monitor battery impact
UIDevice.current.isBatteryMonitoringEnabled = true
let batteryLevel = UIDevice.current.batteryLevel
```

## Contributing

### Code Style
- Follow Swift API Design Guidelines
- Use meaningful variable and function names
- Add comprehensive documentation
- Include unit tests for new features

### Git Workflow
1. Create feature branch from main
2. Implement feature with tests
3. Submit pull request
4. Code review and approval
5. Merge to main

### Testing Requirements
- Unit tests for all new functionality
- Integration tests for complex features
- Performance tests for audio generation
- UI tests for critical user flows

---

For additional support or questions, please refer to the project repository or contact the development team. 
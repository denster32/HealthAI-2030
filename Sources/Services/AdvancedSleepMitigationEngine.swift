import Foundation
import CoreHaptics
import AVFoundation
import HomeKit
import Combine

/// Advanced sleep mitigation engine with comprehensive sleep optimization features
@MainActor
class AdvancedSleepMitigationEngine: ObservableObject {
    
    // MARK: - Published Properties
    @Published var currentSleepStage: SleepStage = .awake
    @Published var circadianPhase: CircadianPhase = .day
    @Published var hapticIntensity: Double = 0.0
    @Published var audioVolume: Double = 0.0
    @Published var environmentSettings = EnvironmentSettings()
    @Published var sleepQuality: Double = 0.0
    @Published var optimizationRecommendations: [SleepOptimizationRecommendation] = []
    
    // MARK: - Private Properties
    private var engine: CHHapticEngine?
    private var audioPlayer: AVAudioPlayer?
    private var homeManager = HMHomeManager()
    private var cancellables = Set<AnyCancellable>()
    private var sleepTimer: Timer?
    private var circadianTimer: Timer?
    
    // MARK: - Circadian Rhythm Properties
    private var lastLightExposure: Date = Date()
    private var sleepSchedule = SleepSchedule()
    private var lightExposureHistory: [LightExposure] = []
    
    // MARK: - Audio Properties
    private var currentSoundProfile: SleepSoundProfile?
    private var audioMixer = AVAudioMixerNode()
    private var audioEngine = AVAudioEngine()
    
    // MARK: - Environment Properties
    private var temperatureSensor: HMAccessory?
    private var humiditySensor: HMAccessory?
    private var lightSensor: HMAccessory?
    private var thermostat: HMAccessory?
    private var smartLights: [HMAccessory] = []
    
    // MARK: - Initialization
    init() {
        setupHapticEngine()
        setupAudioEngine()
        setupHomeKit()
        startCircadianMonitoring()
        loadUserPreferences()
    }
    
    deinit {
        stopAllOptimizations()
    }
    
    // MARK: - Setup Methods
    private func setupHapticEngine() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else {
            print("Haptic engine not supported on this device")
            return
        }
        
        do {
            engine = try CHHapticEngine()
            try engine?.start()
            
            engine?.resetHandler = { [weak self] in
                self?.setupHapticEngine()
            }
            
            engine?.stoppedHandler = { reason in
                print("Haptic engine stopped: \(reason)")
            }
        } catch {
            print("Failed to start haptic engine: \(error)")
        }
    }
    
    private func setupAudioEngine() {
        do {
            audioEngine.attach(audioMixer)
            audioEngine.connect(audioMixer, to: audioEngine.outputNode, format: nil)
            try audioEngine.start()
        } catch {
            print("Failed to setup audio engine: \(error)")
        }
    }
    
    private func setupHomeKit() {
        homeManager.delegate = self
        
        // Discover smart home devices
        discoverSmartHomeDevices()
    }
    
    private func discoverSmartHomeDevices() {
        guard let home = homeManager.primaryHome else { return }
        
        for accessory in home.accessories {
            switch accessory.services.first?.serviceType {
            case HMServiceTypeTemperatureSensor:
                temperatureSensor = accessory
            case HMServiceTypeHumiditySensor:
                humiditySensor = accessory
            case HMServiceTypeLightSensor:
                lightSensor = accessory
            case HMServiceTypeThermostat:
                thermostat = accessory
            case HMServiceTypeLightbulb:
                smartLights.append(accessory)
            default:
                break
            }
        }
    }
    
    private func loadUserPreferences() {
        // Load user preferences from UserDefaults or HealthKit
        let preferences = UserDefaults.standard
        
        sleepSchedule.bedtime = preferences.object(forKey: "bedtime") as? Date ?? Calendar.current.date(from: DateComponents(hour: 22, minute: 0)) ?? Date()
        sleepSchedule.wakeTime = preferences.object(forKey: "wakeTime") as? Date ?? Calendar.current.date(from: DateComponents(hour: 7, minute: 0)) ?? Date()
        
        // Load sound preferences
        let soundProfileData = preferences.data(forKey: "sleepSoundProfile")
        if let data = soundProfileData {
            currentSoundProfile = try? JSONDecoder().decode(SleepSoundProfile.self, from: data)
        }
    }
    
    // MARK: - Circadian Rhythm Optimization
    private func startCircadianMonitoring() {
        circadianTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            self?.updateCircadianPhase()
        }
        
        // Initial update
        updateCircadianPhase()
    }
    
    private func updateCircadianPhase() {
        let hour = Calendar.current.component(.hour, from: Date())
        
        switch hour {
        case 6..<12:
            circadianPhase = .morning
        case 12..<18:
            circadianPhase = .afternoon
        case 18..<22:
            circadianPhase = .evening
        case 22..<24, 0..<6:
            circadianPhase = .night
        default:
            circadianPhase = .day
        }
        
        // Update optimization recommendations based on circadian phase
        updateOptimizationRecommendations()
    }
    
    private func optimizeCircadianRhythm() {
        switch circadianPhase {
        case .morning:
            // Increase light exposure, encourage activity
            optimizeLightExposure(intensity: 0.8, colorTemperature: 6500)
            recommendActivity()
            
        case .afternoon:
            // Maintain moderate light, encourage productivity
            optimizeLightExposure(intensity: 0.6, colorTemperature: 5500)
            
        case .evening:
            // Reduce blue light, prepare for sleep
            optimizeLightExposure(intensity: 0.4, colorTemperature: 3000)
            startSleepPreparation()
            
        case .night:
            // Minimal light, sleep optimization
            optimizeLightExposure(intensity: 0.1, colorTemperature: 2000)
            optimizeSleepEnvironment()
            
        case .day:
            // Default optimization
            optimizeLightExposure(intensity: 0.5, colorTemperature: 5000)
        }
    }
    
    private func optimizeLightExposure(intensity: Double, colorTemperature: Int) {
        // Update smart lights
        for light in smartLights {
            if let brightnessService = light.services.first(where: { $0.serviceType == HMServiceTypeLightbulb }) {
                let brightnessCharacteristic = brightnessService.characteristics.first(where: { $0.characteristicType == HMCharacteristicTypeBrightness })
                brightnessCharacteristic?.writeValue(intensity) { error in
                    if let error = error {
                        print("Failed to set brightness: \(error)")
                    }
                }
            }
        }
        
        // Record light exposure
        let exposure = LightExposure(
            intensity: intensity,
            colorTemperature: colorTemperature,
            timestamp: Date()
        )
        lightExposureHistory.append(exposure)
        
        // Keep only last 24 hours of data
        let dayAgo = Date().addingTimeInterval(-86400)
        lightExposureHistory = lightExposureHistory.filter { $0.timestamp > dayAgo }
    }
    
    // MARK: - Advanced Haptic Feedback
    func startHapticFeedback(for sleepStage: SleepStage) {
        guard let engine = engine else { return }
        
        let hapticPattern = createHapticPattern(for: sleepStage)
        
        do {
            let pattern = try CHHapticPattern(events: hapticPattern.events, parameters: hapticPattern.parameters)
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: 0)
        } catch {
            print("Failed to play haptic pattern: \(error)")
        }
    }
    
    private func createHapticPattern(for sleepStage: SleepStage) -> HapticPattern {
        switch sleepStage {
        case .fallingAsleep:
            return createBreathingPattern()
        case .lightSleep:
            return createGentlePulsePattern()
        case .deepSleep:
            return createMinimalPattern()
        case .remSleep:
            return createDreamPattern()
        case .wakeUp:
            return createWakeUpPattern()
        case .awake:
            return HapticPattern(events: [], parameters: [])
        }
    }
    
    private func createBreathingPattern() -> HapticPattern {
        // 4-7-8 breathing pattern: 4s inhale, 7s hold, 8s exhale
        let events = [
            CHHapticEvent(eventType: .hapticContinuous, parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.2),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.1)
            ], relativeTime: 0, duration: 4.0),
            CHHapticEvent(eventType: .hapticContinuous, parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.0),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.0)
            ], relativeTime: 4.0, duration: 7.0),
            CHHapticEvent(eventType: .hapticContinuous, parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.1),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.05)
            ], relativeTime: 11.0, duration: 8.0)
        ]
        
        return HapticPattern(events: events, parameters: [])
    }
    
    private func createGentlePulsePattern() -> HapticPattern {
        // Gentle pulses for light sleep
        var events: [CHHapticEvent] = []
        var time: TimeInterval = 0
        
        for _ in 0..<10 {
            events.append(CHHapticEvent(eventType: .hapticTransient, parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.1),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.05)
            ], relativeTime: time))
            time += 30.0 // 30 seconds between pulses
        }
        
        return HapticPattern(events: events, parameters: [])
    }
    
    private func createMinimalPattern() -> HapticPattern {
        // Minimal haptics for deep sleep
        var events: [CHHapticEvent] = []
        var time: TimeInterval = 0
        
        for _ in 0..<5 {
            events.append(CHHapticEvent(eventType: .hapticTransient, parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.05),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.02)
            ], relativeTime: time))
            time += 120.0 // 2 minutes between pulses
        }
        
        return HapticPattern(events: events, parameters: [])
    }
    
    private func createDreamPattern() -> HapticPattern {
        // Varied pattern for REM sleep
        var events: [CHHapticEvent] = []
        var time: TimeInterval = 0
        
        for i in 0..<8 {
            let intensity = 0.05 + (Double(i % 3) * 0.05)
            events.append(CHHapticEvent(eventType: .hapticTransient, parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.03)
            ], relativeTime: time))
            time += 45.0 + Double(i % 3) * 15.0 // Variable timing
        }
        
        return HapticPattern(events: events, parameters: [])
    }
    
    private func createWakeUpPattern() -> HapticPattern {
        // Gradual wake-up pattern
        var events: [CHHapticEvent] = []
        var time: TimeInterval = 0
        
        for i in 0..<10 {
            let intensity = 0.1 + (Double(i) * 0.05) // Gradually increase
            events.append(CHHapticEvent(eventType: .hapticTransient, parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: min(intensity, 0.5)),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.1)
            ], relativeTime: time))
            time += 10.0 // 10 seconds between pulses
        }
        
        return HapticPattern(events: events, parameters: [])
    }
    
    // MARK: - Personalized Sleep Sound Profiles
    func startSleepSounds(profile: SleepSoundProfile) {
        currentSoundProfile = profile
        audioVolume = profile.volume
        
        // Create audio mix based on profile
        let audioMix = createAudioMix(for: profile)
        
        // Play the audio mix
        playAudioMix(audioMix)
    }
    
    private func createAudioMix(for profile: SleepSoundProfile) -> AudioMix {
        var mix = AudioMix()
        
        // Add base sound (white noise, pink noise, etc.)
        if let baseSound = profile.baseSound {
            mix.addTrack(baseSound, volume: profile.volume, loop: true)
        }
        
        // Add ambient sounds
        for ambient in profile.ambientSounds {
            mix.addTrack(ambient, volume: ambient.volume * profile.volume, loop: true)
        }
        
        // Add binaural beats if enabled
        if profile.binauralBeatsEnabled {
            let binauralTrack = createBinauralBeat(frequency: profile.binauralFrequency)
            mix.addTrack(binauralTrack, volume: profile.volume * 0.3, loop: true)
        }
        
        return mix
    }
    
    private func createBinauralBeat(frequency: Double) -> AudioTrack {
        // Create binaural beat audio track
        let sampleRate: Double = 44100
        let duration: TimeInterval = 60.0 // 1 minute loop
        let samples = Int(sampleRate * duration)
        
        var leftChannel = [Float](repeating: 0, count: samples)
        var rightChannel = [Float](repeating: 0, count: samples)
        
        let baseFrequency = 200.0 // Base frequency
        let leftFreq = baseFrequency
        let rightFreq = baseFrequency + frequency
        
        for i in 0..<samples {
            let time = Double(i) / sampleRate
            leftChannel[i] = Float(sin(2 * .pi * leftFreq * time))
            rightChannel[i] = Float(sin(2 * .pi * rightFreq * time))
        }
        
        return AudioTrack(
            leftChannel: leftChannel,
            rightChannel: rightChannel,
            sampleRate: sampleRate,
            name: "Binaural Beat \(Int(frequency))Hz"
        )
    }
    
    private func playAudioMix(_ mix: AudioMix) {
        // Implementation would mix and play the audio tracks
        // This is a simplified version
        print("Playing audio mix with \(mix.tracks.count) tracks")
    }
    
    // MARK: - Sleep Environment Optimization
    private func optimizeSleepEnvironment() {
        // Optimize temperature (16-18°C for deep sleep)
        optimizeTemperature(target: 17.0)
        
        // Optimize humidity (45-55%)
        optimizeHumidity(target: 50.0)
        
        // Optimize light levels (0-0.01 lux for deep sleep)
        optimizeLightLevel(target: 0.005)
        
        // Optimize noise levels
        optimizeNoiseLevel()
    }
    
    private func optimizeTemperature(target: Double) {
        guard let thermostat = thermostat else { return }
        
        if let temperatureService = thermostat.services.first(where: { $0.serviceType == HMServiceTypeThermostat }) {
            let targetTempCharacteristic = temperatureService.characteristics.first(where: { $0.characteristicType == HMCharacteristicTypeTargetTemperature })
            targetTempCharacteristic?.writeValue(target) { error in
                if let error = error {
                    print("Failed to set temperature: \(error)")
                }
            }
        }
    }
    
    private func optimizeHumidity(target: Double) {
        // If we have a humidifier, control it
        // This would require additional HomeKit accessories
        print("Target humidity: \(target)%")
    }
    
    private func optimizeLightLevel(target: Double) {
        // Set smart lights to very low brightness
        for light in smartLights {
            if let brightnessService = light.services.first(where: { $0.serviceType == HMServiceTypeLightbulb }) {
                let brightnessCharacteristic = brightnessService.characteristics.first(where: { $0.characteristicType == HMCharacteristicTypeBrightness })
                brightnessCharacteristic?.writeValue(target) { error in
                    if let error = error {
                        print("Failed to set light level: \(error)")
                    }
                }
            }
        }
    }
    
    private func optimizeNoiseLevel() {
        // Adjust audio volume based on ambient noise
        // This would require microphone access and noise analysis
        print("Optimizing noise levels")
    }
    
    // MARK: - Smart Home Integration
    private func startSleepPreparation() {
        // 30 minutes before bedtime
        let preparationTime = sleepSchedule.bedtime.addingTimeInterval(-1800)
        
        if Date() >= preparationTime {
            // Dim lights gradually
            scheduleLightDimming()
            
            // Lower temperature gradually
            scheduleTemperatureReduction()
            
            // Start sleep sounds
            if let profile = currentSoundProfile {
                startSleepSounds(profile: profile)
            }
        }
    }
    
    private func scheduleLightDimming() {
        // Gradually dim lights over 30 minutes
        let dimmingSteps = 30
        let stepDuration = 60.0 // 1 minute per step
        
        for i in 0..<dimmingSteps {
            let delay = TimeInterval(i) * stepDuration
            let brightness = 0.6 - (Double(i) * 0.02) // Start at 60%, end at 0%
            
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                self.setLightBrightness(brightness)
            }
        }
    }
    
    private func scheduleTemperatureReduction() {
        // Gradually reduce temperature over 30 minutes
        let tempSteps = 30
        let stepDuration = 60.0 // 1 minute per step
        let startTemp = 22.0
        let endTemp = 17.0
        
        for i in 0..<tempSteps {
            let delay = TimeInterval(i) * stepDuration
            let temperature = startTemp - (Double(i) * (startTemp - endTemp) / Double(tempSteps))
            
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                self.optimizeTemperature(target: temperature)
            }
        }
    }
    
    private func setLightBrightness(_ brightness: Double) {
        for light in smartLights {
            if let brightnessService = light.services.first(where: { $0.serviceType == HMServiceTypeLightbulb }) {
                let brightnessCharacteristic = brightnessService.characteristics.first(where: { $0.characteristicType == HMCharacteristicTypeBrightness })
                brightnessCharacteristic?.writeValue(max(0, brightness)) { error in
                    if let error = error {
                        print("Failed to set brightness: \(error)")
                    }
                }
            }
        }
    }
    
    // MARK: - Public Methods
    func startSleepOptimization() {
        currentSleepStage = .fallingAsleep
        startHapticFeedback(for: .fallingAsleep)
        optimizeSleepEnvironment()
        
        // Start sleep monitoring
        startSleepMonitoring()
    }
    
    func stopAllOptimizations() {
        sleepTimer?.invalidate()
        sleepTimer = nil
        circadianTimer?.invalidate()
        circadianTimer = nil
        
        audioPlayer?.stop()
        audioPlayer = nil
        
        // Turn off all optimizations
        setLightBrightness(0.0)
        optimizeTemperature(target: 22.0) // Return to comfortable temperature
    }
    
    func updateSleepStage(_ stage: SleepStage) {
        currentSleepStage = stage
        startHapticFeedback(for: stage)
        
        // Update environment based on sleep stage
        switch stage {
        case .deepSleep:
            optimizeSleepEnvironment()
        case .wakeUp:
            startWakeUpSequence()
        default:
            break
        }
    }
    
    private func startWakeUpSequence() {
        // Gradual wake-up over 30 minutes
        let wakeUpSteps = 30
        let stepDuration = 60.0 // 1 minute per step
        
        for i in 0..<wakeUpSteps {
            let delay = TimeInterval(i) * stepDuration
            let brightness = Double(i) * 0.03 // Gradually increase to 90%
            let temperature = 17.0 + (Double(i) * 0.17) // Gradually increase to 22°C
            
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                self.setLightBrightness(brightness)
                self.optimizeTemperature(target: temperature)
            }
        }
        
        // Start wake-up haptics
        startHapticFeedback(for: .wakeUp)
    }
    
    private func startSleepMonitoring() {
        sleepTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            self?.updateSleepQuality()
        }
    }
    
    private func updateSleepQuality() {
        // Calculate sleep quality based on various factors
        var quality = 0.0
        
        // Environment factors
        if environmentSettings.temperature >= 16 && environmentSettings.temperature <= 18 {
            quality += 0.3
        }
        if environmentSettings.humidity >= 45 && environmentSettings.humidity <= 55 {
            quality += 0.2
        }
        if environmentSettings.lightLevel <= 0.01 {
            quality += 0.2
        }
        
        // Sleep stage factors
        switch currentSleepStage {
        case .deepSleep:
            quality += 0.3
        case .remSleep:
            quality += 0.2
        case .lightSleep:
            quality += 0.1
        default:
            break
        }
        
        sleepQuality = min(quality, 1.0)
    }
    
    private func updateOptimizationRecommendations() {
        var recommendations: [SleepOptimizationRecommendation] = []
        
        // Circadian-based recommendations
        switch circadianPhase {
        case .evening:
            recommendations.append(SleepOptimizationRecommendation(
                type: .light,
                priority: .high,
                title: "Reduce Blue Light",
                description: "Switch to warm lighting to prepare for sleep",
                action: "Enable night mode and reduce screen time"
            ))
        case .night:
            recommendations.append(SleepOptimizationRecommendation(
                type: .environment,
                priority: .high,
                title: "Optimize Sleep Environment",
                description: "Adjust temperature and lighting for optimal sleep",
                action: "Set temperature to 17°C and minimize light"
            ))
        default:
            break
        }
        
        // Sleep quality-based recommendations
        if sleepQuality < 0.5 {
            recommendations.append(SleepOptimizationRecommendation(
                type: .sleep,
                priority: .medium,
                title: "Improve Sleep Quality",
                description: "Consider adjusting your sleep environment",
                action: "Review sleep environment settings"
            ))
        }
        
        optimizationRecommendations = recommendations
    }
    
    private func recommendActivity() {
        // Recommend activities based on circadian phase
        print("Recommended activity for \(circadianPhase)")
    }
}

// MARK: - Data Models
enum SleepStage {
    case awake
    case fallingAsleep
    case lightSleep
    case deepSleep
    case remSleep
    case wakeUp
}

enum CircadianPhase {
    case morning
    case afternoon
    case evening
    case night
    case day
}

struct SleepSchedule {
    var bedtime: Date = Date()
    var wakeTime: Date = Date()
    var sleepDuration: TimeInterval {
        return wakeTime.timeIntervalSince(bedtime)
    }
}

struct LightExposure {
    let intensity: Double
    let colorTemperature: Int
    let timestamp: Date
}

struct SleepSoundProfile: Codable {
    var baseSound: SleepSound?
    var ambientSounds: [SleepSound] = []
    var binauralBeatsEnabled: Bool = false
    var binauralFrequency: Double = 0.5 // Hz for deep sleep
    var volume: Double = 0.3
    var name: String = "Default Profile"
}

struct SleepSound: Codable {
    let name: String
    let type: SoundType
    let volume: Double
    let frequency: Double?
    
    enum SoundType: String, Codable {
        case whiteNoise
        case pinkNoise
        case brownNoise
        case nature
        case ambient
        case binaural
    }
}

struct EnvironmentSettings {
    var temperature: Double = 22.0
    var humidity: Double = 50.0
    var lightLevel: Double = 0.0
    var noiseLevel: Double = 0.0
}

struct SleepOptimizationRecommendation {
    let type: OptimizationType
    let priority: RecommendationPriority
    let title: String
    let description: String
    let action: String
    
    enum OptimizationType {
        case light
        case temperature
        case humidity
        case sound
        case environment
        case sleep
    }
    
    enum RecommendationPriority {
        case low
        case medium
        case high
        case critical
    }
}

// MARK: - Supporting Structures
struct HapticPattern {
    let events: [CHHapticEvent]
    let parameters: [CHHapticDynamicParameter]
}

struct AudioMix {
    var tracks: [AudioTrack] = []
    
    mutating func addTrack(_ track: AudioTrack, volume: Double, loop: Bool) {
        tracks.append(track)
    }
}

struct AudioTrack {
    let leftChannel: [Float]
    let rightChannel: [Float]
    let sampleRate: Double
    let name: String
}

// MARK: - HomeKit Delegate
extension AdvancedSleepMitigationEngine: HMHomeManagerDelegate {
    func homeManagerDidUpdateHomes(_ manager: HMHomeManager) {
        discoverSmartHomeDevices()
    }
    
    func homeManager(_ manager: HMHomeManager, didAdd home: HMHome) {
        discoverSmartHomeDevices()
    }
    
    func homeManager(_ manager: HMHomeManager, didRemove home: HMHome) {
        // Handle home removal
    }
} 
import Foundation
import HomeKit

// MARK: - Smart Home Device Models

struct SmartHomeDevice: Identifiable, Codable {
    let id: String
    let name: String
    let type: SmartHomeDeviceType
    let platform: SmartHomePlatform
    let room: String
    let isReachable: Bool
    let capabilities: DeviceCapabilities
    let lastUpdated: Date
    
    var isOnline: Bool { isReachable }
    var statusIcon: String {
        switch type {
        case .lighting: return "lightbulb.fill"
        case .thermostat: return "thermometer"
        case .humidifier: return "humidity.fill"
        case .sensor: return "sensor.fill"
        case .switch: return "switch.2"
        case .fan: return "fan.fill"
        case .speaker: return "speaker.fill"
        case .camera: return "camera.fill"
        case .lock: return "lock.fill"
        case .unknown: return "questionmark.circle"
        }
    }
    
    var statusColor: String {
        return isReachable ? "green" : "red"
    }
}

enum SmartHomeDeviceType: String, Codable, CaseIterable {
    case lighting = "lighting"
    case thermostat = "thermostat"
    case humidifier = "humidifier"
    case sensor = "sensor"
    case switch = "switch"
    case fan = "fan"
    case speaker = "speaker"
    case camera = "camera"
    case lock = "lock"
    case unknown = "unknown"
    
    var displayName: String {
        switch self {
        case .lighting: return "Lighting"
        case .thermostat: return "Thermostat"
        case .humidifier: return "Humidifier"
        case .sensor: return "Sensor"
        case .switch: return "Switch"
        case .fan: return "Fan"
        case .speaker: return "Speaker"
        case .camera: return "Camera"
        case .lock: return "Lock"
        case .unknown: return "Unknown"
        }
    }
}

enum SmartHomePlatform: String, Codable, CaseIterable {
    case homeKit = "homekit"
    case philipsHue = "philips_hue"
    case nest = "nest"
    case ecobee = "ecobee"
    case smartThings = "smartthings"
    case amazon = "amazon"
    case google = "google"
    case unknown = "unknown"
    
    var displayName: String {
        switch self {
        case .homeKit: return "HomeKit"
        case .philipsHue: return "Philips Hue"
        case .nest: return "Nest"
        case .ecobee: return "Ecobee"
        case .smartThings: return "SmartThings"
        case .amazon: return "Amazon Alexa"
        case .google: return "Google Home"
        case .unknown: return "Unknown"
        }
    }
    
    var iconName: String {
        switch self {
        case .homeKit: return "house.fill"
        case .philipsHue: return "lightbulb.fill"
        case .nest: return "thermometer"
        case .ecobee: return "thermometer.sun.fill"
        case .smartThings: return "network"
        case .amazon: return "speaker.fill"
        case .google: return "mic.fill"
        case .unknown: return "questionmark.circle"
        }
    }
}

struct DeviceCapabilities: Codable {
    var currentTemperature: Double?
    var targetTemperature: Double?
    var currentHumidity: Double?
    var targetHumidity: Double?
    var currentBrightness: Double?
    var currentColorTemperature: Int?
    var currentColor: RGBColor?
    var currentNoiseLevel: Double?
    var currentAirQuality: AirQuality?
    var isPoweredOn: Bool?
    var supportsDimming: Bool = false
    var supportsColorChanging: Bool = false
    var supportsTemperatureControl: Bool = false
    var supportsHumidityControl: Bool = false
    var supportsScheduling: Bool = false
    
    init() {}
}

struct RGBColor: Codable {
    let red: Double
    let green: Double
    let blue: Double
    
    init(red: Double, green: Double, blue: Double) {
        self.red = max(0, min(1, red))
        self.green = max(0, min(1, green))
        self.blue = max(0, min(1, blue))
    }
    
    static let white = RGBColor(red: 1.0, green: 1.0, blue: 1.0)
    static let warm = RGBColor(red: 1.0, green: 0.8, blue: 0.6)
    static let cool = RGBColor(red: 0.8, green: 0.9, blue: 1.0)
    static let red = RGBColor(red: 1.0, green: 0.0, blue: 0.0)
    static let green = RGBColor(red: 0.0, green: 1.0, blue: 0.0)
    static let blue = RGBColor(red: 0.0, green: 0.0, blue: 1.0)
}

enum AirQuality: Int, Codable, CaseIterable {
    case excellent = 1
    case good = 2
    case moderate = 3
    case poor = 4
    case unhealthy = 5
    
    var displayName: String {
        switch self {
        case .excellent: return "Excellent"
        case .good: return "Good"
        case .moderate: return "Moderate"
        case .poor: return "Poor"
        case .unhealthy: return "Unhealthy"
        }
    }
    
    var color: String {
        switch self {
        case .excellent: return "green"
        case .good: return "green"
        case .moderate: return "yellow"
        case .poor: return "orange"
        case .unhealthy: return "red"
        }
    }
}

// MARK: - Environment Models

struct RoomEnvironment: Codable {
    let temperature: Double
    let humidity: Double
    let lightLevel: Double
    let noiseLevel: Double
    let airQuality: AirQuality
    let optimizationScore: Double
    let lastUpdated: Date
    
    var temperatureStatus: EnvironmentStatus {
        if temperature >= 18 && temperature <= 22 {
            return .optimal
        } else if temperature >= 16 && temperature <= 24 {
            return .acceptable
        } else {
            return .poor
        }
    }
    
    var humidityStatus: EnvironmentStatus {
        if humidity >= 40 && humidity <= 60 {
            return .optimal
        } else if humidity >= 30 && humidity <= 70 {
            return .acceptable
        } else {
            return .poor
        }
    }
    
    var lightStatus: EnvironmentStatus {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: Date())
        
        if hour >= 22 || hour <= 6 {
            // Night time
            return lightLevel < 0.3 ? .optimal : .acceptable
        } else {
            // Day time
            return lightLevel > 0.5 ? .optimal : .acceptable
        }
    }
    
    var noiseStatus: EnvironmentStatus {
        if noiseLevel <= 40 {
            return .optimal
        } else if noiseLevel <= 55 {
            return .acceptable
        } else {
            return .poor
        }
    }
    
    var overallStatus: EnvironmentStatus {
        let scores = [
            temperatureStatus.rawValue,
            humidityStatus.rawValue,
            lightStatus.rawValue,
            noiseStatus.rawValue
        ]
        
        let averageScore = scores.reduce(0, +) / scores.count
        
        if averageScore >= 2.5 {
            return .optimal
        } else if averageScore >= 1.5 {
            return .acceptable
        } else {
            return .poor
        }
    }
}

enum EnvironmentStatus: Int, Codable {
    case poor = 0
    case acceptable = 1
    case good = 2
    case optimal = 3
    
    var displayName: String {
        switch self {
        case .poor: return "Poor"
        case .acceptable: return "Acceptable"
        case .good: return "Good"
        case .optimal: return "Optimal"
        }
    }
    
    var color: String {
        switch self {
        case .poor: return "red"
        case .acceptable: return "orange"
        case .good: return "yellow"
        case .optimal: return "green"
        }
    }
    
    var icon: String {
        switch self {
        case .poor: return "exclamationmark.triangle.fill"
        case .acceptable: return "minus.circle.fill"
        case .good: return "checkmark.circle.fill"
        case .optimal: return "star.circle.fill"
        }
    }
}

enum SmartHomeConnectionStatus: String, Codable {
    case disconnected = "disconnected"
    case connecting = "connecting"
    case discovering = "discovering"
    case connected = "connected"
    case unauthorized = "unauthorized"
    case error = "error"
    
    var displayName: String {
        switch self {
        case .disconnected: return "Disconnected"
        case .connecting: return "Connecting"
        case .discovering: return "Discovering"
        case .connected: return "Connected"
        case .unauthorized: return "Unauthorized"
        case .error: return "Error"
        }
    }
    
    var color: String {
        switch self {
        case .disconnected: return "red"
        case .connecting: return "orange"
        case .discovering: return "yellow"
        case .connected: return "green"
        case .unauthorized: return "red"
        case .error: return "red"
        }
    }
}

// MARK: - Control Settings

struct LightingSettings: Codable {
    let brightness: Double // 0.0 - 1.0
    let colorTemperature: Int? // Kelvin
    let color: RGBColor?
    
    init(brightness: Double, colorTemperature: Int? = nil, color: RGBColor? = nil) {
        self.brightness = max(0, min(1, brightness))
        self.colorTemperature = colorTemperature
        self.color = color
    }
}

struct TemperatureSettings: Codable {
    let target: Double // Celsius
    let mode: TemperatureMode
    
    enum TemperatureMode: String, Codable {
        case heat = "heat"
        case cool = "cool"
        case auto = "auto"
        case comfort = "comfort"
        case eco = "eco"
    }
}

struct HumiditySettings: Codable {
    let target: Double // Percentage
    let mode: HumidityMode
    
    enum HumidityMode: String, Codable {
        case humidify = "humidify"
        case dehumidify = "dehumidify"
        case auto = "auto"
    }
}

struct NoiseSettings: Codable {
    let whiteNoise: Bool
    let volume: Double // 0.0 - 1.0
    let soundType: SoundType?
    
    enum SoundType: String, Codable {
        case whiteNoise = "white_noise"
        case brownNoise = "brown_noise"
        case pinkNoise = "pink_noise"
        case rain = "rain"
        case ocean = "ocean"
        case forest = "forest"
    }
}

// MARK: - Automation Models

struct EnvironmentAutomationRule: Identifiable, Codable {
    let id: String
    let name: String
    let trigger: AutomationTrigger
    let conditions: [AutomationCondition]
    let actions: [AutomationAction]
    let isEnabled: Bool
    let createdAt: Date
    let lastExecuted: Date?
    
    init(id: String, name: String, trigger: AutomationTrigger, conditions: [AutomationCondition], actions: [AutomationAction], isEnabled: Bool, createdAt: Date = Date(), lastExecuted: Date? = nil) {
        self.id = id
        self.name = name
        self.trigger = trigger
        self.conditions = conditions
        self.actions = actions
        self.isEnabled = isEnabled
        self.createdAt = createdAt
        self.lastExecuted = lastExecuted
    }
}

enum AutomationTrigger: Codable {
    case sleepStage(SleepStage)
    case stressLevel(Double)
    case heartRate(Double)
    case time(String) // HH:mm format
    case temperature(Double)
    case humidity(Double)
    case airQuality(AirQuality)
    case motionDetected
    case noMotionDetected(duration: TimeInterval)
    
    var displayName: String {
        switch self {
        case .sleepStage(let stage):
            return "Sleep Stage: \(stage.displayName)"
        case .stressLevel(let level):
            return "Stress Level: \(String(format: "%.1f", level))"
        case .heartRate(let rate):
            return "Heart Rate: \(Int(rate)) BPM"
        case .time(let time):
            return "Time: \(time)"
        case .temperature(let temp):
            return "Temperature: \(String(format: "%.1f°C", temp))"
        case .humidity(let hum):
            return "Humidity: \(Int(hum))%"
        case .airQuality(let quality):
            return "Air Quality: \(quality.displayName)"
        case .motionDetected:
            return "Motion Detected"
        case .noMotionDetected(let duration):
            return "No Motion for \(Int(duration/60)) minutes"
        }
    }
}

enum AutomationCondition: Codable {
    case timeRange(start: String, end: String)
    case stressLevel(min: Double?, max: Double?)
    case heartRate(min: Double?, max: Double?)
    case temperature(min: Double?, max: Double?)
    case humidity(min: Double?, max: Double?)
    case sleepStage(SleepStage)
    case isAsleep(Bool)
    case isAwake(Bool)
    case dayOfWeek([Int]) // 1-7, Sunday = 1
    
    var displayName: String {
        switch self {
        case .timeRange(let start, let end):
            return "Time: \(start) - \(end)"
        case .stressLevel(let min, let max):
            let minStr = min.map { String(format: "%.1f", $0) } ?? "any"
            let maxStr = max.map { String(format: "%.1f", $0) } ?? "any"
            return "Stress Level: \(minStr) - \(maxStr)"
        case .heartRate(let min, let max):
            let minStr = min.map { String(format: "%.0f", $0) } ?? "any"
            let maxStr = max.map { String(format: "%.0f", $0) } ?? "any"
            return "Heart Rate: \(minStr) - \(maxStr) BPM"
        case .temperature(let min, let max):
            let minStr = min.map { String(format: "%.1f", $0) } ?? "any"
            let maxStr = max.map { String(format: "%.1f", $0) } ?? "any"
            return "Temperature: \(minStr) - \(maxStr)°C"
        case .humidity(let min, let max):
            let minStr = min.map { String(format: "%.0f", $0) } ?? "any"
            let maxStr = max.map { String(format: "%.0f", $0) } ?? "any"
            return "Humidity: \(minStr) - \(maxStr)%"
        case .sleepStage(let stage):
            return "Sleep Stage: \(stage.displayName)"
        case .isAsleep(let asleep):
            return asleep ? "Is Asleep" : "Is Not Asleep"
        case .isAwake(let awake):
            return awake ? "Is Awake" : "Is Not Awake"
        case .dayOfWeek(let days):
            let dayNames = days.map { Calendar.current.weekdaySymbols[$0 - 1] }
            return "Days: \(dayNames.joined(separator: ", "))"
        }
    }
}

enum AutomationAction: Codable {
    case adjustLighting(brightness: Double, colorTemp: Int?)
    case setTemperature(target: Double)
    case setHumidity(target: Double)
    case enableWhiteNoise(volume: Double)
    case disableWhiteNoise()
    case turnOnDevice(deviceId: String)
    case turnOffDevice(deviceId: String)
    case setDeviceValue(deviceId: String, value: Double)
    case sendNotification(title: String, message: String)
    case playSound(soundType: NoiseSettings.SoundType, volume: Double)
    case activateScene(sceneName: String)
    
    var displayName: String {
        switch self {
        case .adjustLighting(let brightness, let colorTemp):
            let tempStr = colorTemp.map { " (\($0)K)" } ?? ""
            return "Set Lighting: \(Int(brightness * 100))%\(tempStr)"
        case .setTemperature(let target):
            return "Set Temperature: \(String(format: "%.1f°C", target))"
        case .setHumidity(let target):
            return "Set Humidity: \(Int(target))%"
        case .enableWhiteNoise(let volume):
            return "Enable White Noise: \(Int(volume * 100))%"
        case .disableWhiteNoise():
            return "Disable White Noise"
        case .turnOnDevice(let deviceId):
            return "Turn On: \(deviceId)"
        case .turnOffDevice(let deviceId):
            return "Turn Off: \(deviceId)"
        case .setDeviceValue(let deviceId, let value):
            return "Set \(deviceId): \(value)"
        case .sendNotification(let title, _):
            return "Send Notification: \(title)"
        case .playSound(let soundType, let volume):
            return "Play \(soundType.rawValue): \(Int(volume * 100))%"
        case .activateScene(let sceneName):
            return "Activate Scene: \(sceneName)"
        }
    }
}

// MARK: - Sleep Environment Optimization

struct SleepEnvironmentOptimization: Codable {
    let lighting: LightingSettings
    let temperature: TemperatureSettings
    let humidity: HumiditySettings
    let noise: NoiseSettings
    let confidence: Double
    let recommendations: [String]
    
    init(for sleepStage: SleepStage) {
        switch sleepStage {
        case .awake:
            self.lighting = LightingSettings(brightness: 0.7, colorTemperature: 5000)
            self.temperature = TemperatureSettings(target: 22.0, mode: .comfort)
            self.humidity = HumiditySettings(target: 50.0, mode: .auto)
            self.noise = NoiseSettings(whiteNoise: false, volume: 0.0)
            self.confidence = 0.8
            self.recommendations = ["Maintain comfortable environment for alertness"]
            
        case .light:
            self.lighting = LightingSettings(brightness: 0.2, colorTemperature: 2700)
            self.temperature = TemperatureSettings(target: 20.0, mode: .comfort)
            self.humidity = HumiditySettings(target: 45.0, mode: .auto)
            self.noise = NoiseSettings(whiteNoise: true, volume: 0.2, soundType: .whiteNoise)
            self.confidence = 0.85
            self.recommendations = ["Dim lights and reduce noise for light sleep"]
            
        case .deep:
            self.lighting = LightingSettings(brightness: 0.05, colorTemperature: 2000)
            self.temperature = TemperatureSettings(target: 18.0, mode: .comfort)
            self.humidity = HumiditySettings(target: 45.0, mode: .auto)
            self.noise = NoiseSettings(whiteNoise: true, volume: 0.3, soundType: .brownNoise)
            self.confidence = 0.9
            self.recommendations = ["Optimize for deep sleep with cool temperature and minimal light"]
            
        case .rem:
            self.lighting = LightingSettings(brightness: 0.1, colorTemperature: 2200)
            self.temperature = TemperatureSettings(target: 19.0, mode: .comfort)
            self.humidity = HumiditySettings(target: 50.0, mode: .auto)
            self.noise = NoiseSettings(whiteNoise: true, volume: 0.25, soundType: .pinkNoise)
            self.confidence = 0.85
            self.recommendations = ["Maintain stable environment for REM sleep"]
        }
    }
}

// MARK: - Protocol Definitions

protocol SmartHomeAdapter {
    func discoverDevices(completion: @escaping ([SmartHomeDevice]) -> Void)
    func setLighting(device: SmartHomeDevice, settings: LightingSettings) async
    func setTemperature(device: SmartHomeDevice, settings: TemperatureSettings) async
    func setHumidity(device: SmartHomeDevice, settings: HumiditySettings) async
    func setNoise(device: SmartHomeDevice, settings: NoiseSettings) async
    func getDeviceStatus(device: SmartHomeDevice) async -> DeviceCapabilities?
}

protocol SmartHomeAutomationEngineDelegate: AnyObject {
    func automationEngine(_ engine: SmartHomeAutomationEngine, shouldExecuteRule rule: EnvironmentAutomationRule) -> Bool
    func automationEngine(_ engine: SmartHomeAutomationEngine, didExecuteRule rule: EnvironmentAutomationRule)
    func automationEngine(_ engine: SmartHomeAutomationEngine, didFailToExecuteRule rule: EnvironmentAutomationRule, error: Error)
}

// MARK: - Additional Supporting Types

struct DeviceScene: Identifiable, Codable {
    let id: String
    let name: String
    let devices: [String: DeviceSceneState]
    let isActive: Bool
    let createdAt: Date
    
    struct DeviceSceneState: Codable {
        let brightness: Double?
        let temperature: Double?
        let humidity: Double?
        let isOn: Bool?
        let color: RGBColor?
    }
}

struct EnvironmentMetrics: Codable {
    let timestamp: Date
    let temperature: Double
    let humidity: Double
    let lightLevel: Double
    let noiseLevel: Double
    let airQuality: AirQuality
    let sleepStage: SleepStage?
    let stressLevel: Double?
    let heartRate: Double?
}

struct SmartHomeInsight: Identifiable, Codable {
    let id: String
    let title: String
    let description: String
    let category: InsightCategory
    let impact: InsightImpact
    let recommendations: [String]
    let timestamp: Date
    
    enum InsightCategory: String, Codable {
        case energy = "energy"
        case comfort = "comfort"
        case sleep = "sleep"
        case health = "health"
        case efficiency = "efficiency"
    }
    
    enum InsightImpact: String, Codable {
        case low = "low"
        case medium = "medium"
        case high = "high"
        case critical = "critical"
    }
}
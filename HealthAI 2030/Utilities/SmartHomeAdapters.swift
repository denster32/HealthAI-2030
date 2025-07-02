import Foundation
import HomeKit
import Network

// MARK: - HomeKit Adapter

class HomeKitAdapter: SmartHomeAdapter {
    
    func discoverDevices(completion: @escaping ([SmartHomeDevice]) -> Void) {
        // HomeKit device discovery is handled by SmartHomeManager
        // This is called from the main manager to process HomeKit accessories
        completion([])
    }
    
    func setLighting(device: SmartHomeDevice, settings: LightingSettings) async {
        guard let accessory = findHomeKitAccessory(for: device) else { return }
        
        for service in accessory.services {
            guard service.serviceType == HMServiceTypeLightbulb else { continue }
            
            // Set brightness
            if let brightnessCharacteristic = service.characteristics.first(where: { $0.characteristicType == HMCharacteristicTypeBrightness }) {
                let brightnessValue = settings.brightness * 100 // Convert to 0-100 scale
                try? await brightnessCharacteristic.writeValue(NSNumber(value: brightnessValue))
            }
            
            // Set color temperature if supported
            if let colorTempCharacteristic = service.characteristics.first(where: { $0.characteristicType == HMCharacteristicTypeColorTemperature }),
               let colorTemp = settings.colorTemperature {
                // HomeKit uses mireds (1,000,000 / Kelvin)
                let miredValue = 1000000 / colorTemp
                try? await colorTempCharacteristic.writeValue(NSNumber(value: miredValue))
            }
            
            // Set color if supported
            if let hueCharacteristic = service.characteristics.first(where: { $0.characteristicType == HMCharacteristicTypeHue }),
               let saturationCharacteristic = service.characteristics.first(where: { $0.characteristicType == HMCharacteristicTypeSaturation }),
               let color = settings.color {
                
                let hsb = rgbToHSB(color)
                try? await hueCharacteristic.writeValue(NSNumber(value: hsb.hue * 360))
                try? await saturationCharacteristic.writeValue(NSNumber(value: hsb.saturation * 100))
            }
        }
    }
    
    func setTemperature(device: SmartHomeDevice, settings: TemperatureSettings) async {
        guard let accessory = findHomeKitAccessory(for: device) else { return }
        
        for service in accessory.services {
            guard service.serviceType == HMServiceTypeThermostat else { continue }
            
            // Set target temperature
            if let targetTempCharacteristic = service.characteristics.first(where: { $0.characteristicType == HMCharacteristicTypeTargetTemperature }) {
                try? await targetTempCharacteristic.writeValue(NSNumber(value: settings.target))
            }
            
            // Set heating/cooling mode
            if let modeCharacteristic = service.characteristics.first(where: { $0.characteristicType == HMCharacteristicTypeTargetHeatingCoolingState }) {
                let modeValue: Int
                switch settings.mode {
                case .heat: modeValue = 1
                case .cool: modeValue = 2
                case .auto: modeValue = 3
                default: modeValue = 0
                }
                try? await modeCharacteristic.writeValue(NSNumber(value: modeValue))
            }
        }
    }
    
    func setHumidity(device: SmartHomeDevice, settings: HumiditySettings) async {
        guard let accessory = findHomeKitAccessory(for: device) else { return }
        
        for service in accessory.services {
            guard service.serviceType == HMServiceTypeHumidifierDehumidifier else { continue }
            
            // Set target humidity
            if let targetHumidityCharacteristic = service.characteristics.first(where: { $0.characteristicType == HMCharacteristicTypeTargetRelativeHumidity }) {
                try? await targetHumidityCharacteristic.writeValue(NSNumber(value: settings.target))
            }
            
            // Set mode
            if let modeCharacteristic = service.characteristics.first(where: { $0.characteristicType == HMCharacteristicTypeTargetHumidifierDehumidifierState }) {
                let modeValue: Int
                switch settings.mode {
                case .humidify: modeValue = 1
                case .dehumidify: modeValue = 2
                case .auto: modeValue = 0
                }
                try? await modeCharacteristic.writeValue(NSNumber(value: modeValue))
            }
        }
    }
    
    func setNoise(device: SmartHomeDevice, settings: NoiseSettings) async {
        // HomeKit doesn't have native noise control, would need to use speaker accessories
        // This would be implemented for specific speaker devices that support HomeKit
    }
    
    func getDeviceStatus(device: SmartHomeDevice) async -> DeviceCapabilities? {
        guard let accessory = findHomeKitAccessory(for: device) else { return nil }
        
        var capabilities = DeviceCapabilities()
        
        for service in accessory.services {
            for characteristic in service.characteristics {
                switch characteristic.characteristicType {
                case HMCharacteristicTypeCurrentTemperature:
                    capabilities.currentTemperature = characteristic.value as? Double
                case HMCharacteristicTypeTargetTemperature:
                    capabilities.targetTemperature = characteristic.value as? Double
                case HMCharacteristicTypeCurrentRelativeHumidity:
                    capabilities.currentHumidity = characteristic.value as? Double
                case HMCharacteristicTypeTargetRelativeHumidity:
                    capabilities.targetHumidity = characteristic.value as? Double
                case HMCharacteristicTypeBrightness:
                    capabilities.currentBrightness = (characteristic.value as? Double).map { $0 / 100.0 }
                case HMCharacteristicTypeColorTemperature:
                    if let mireds = characteristic.value as? Int {
                        capabilities.currentColorTemperature = 1000000 / mireds
                    }
                case HMCharacteristicTypeOn:
                    capabilities.isPoweredOn = characteristic.value as? Bool
                default:
                    break
                }
            }
        }
        
        return capabilities
    }
    
    private func findHomeKitAccessory(for device: SmartHomeDevice) -> HMAccessory? {
        guard let homeManager = SmartHomeManager.shared.selectedHome else { return nil }
        return homeManager.accessories.first { $0.uniqueIdentifier.uuidString == device.id }
    }
    
    private func rgbToHSB(_ rgb: RGBColor) -> (hue: Double, saturation: Double, brightness: Double) {
        let max = Swift.max(rgb.red, Swift.max(rgb.green, rgb.blue))
        let min = Swift.min(rgb.red, Swift.min(rgb.green, rgb.blue))
        let delta = max - min
        
        let brightness = max
        let saturation = max == 0 ? 0 : delta / max
        
        var hue: Double = 0
        if delta != 0 {
            if max == rgb.red {
                hue = (rgb.green - rgb.blue) / delta
            } else if max == rgb.green {
                hue = 2 + (rgb.blue - rgb.red) / delta
            } else {
                hue = 4 + (rgb.red - rgb.green) / delta
            }
            hue /= 6
            if hue < 0 { hue += 1 }
        }
        
        return (hue, saturation, brightness)
    }
}

// MARK: - Philips Hue Adapter

class PhilipsHueAdapter: SmartHomeAdapter {
    private let baseURL = "http://192.168.1.100/api" // This would be discovered
    private var apiKey: String?
    
    func discoverDevices(completion: @escaping ([SmartHomeDevice]) -> Void) {
        // Discover Philips Hue Bridge on network
        discoverHueBridge { [weak self] bridgeIP in
            guard let self = self, let bridgeIP = bridgeIP else {
                completion([])
                return
            }
            
            self.authenticateWithBridge(bridgeIP: bridgeIP) { success in
                if success {
                    self.fetchHueDevices(completion: completion)
                } else {
                    completion([])
                }
            }
        }
    }
    
    func setLighting(device: SmartHomeDevice, settings: LightingSettings) async {
        guard let apiKey = apiKey else { return }
        
        var lightState: [String: Any] = [:]
        lightState["on"] = true
        lightState["bri"] = Int(settings.brightness * 254) // Hue uses 0-254 scale
        
        if let colorTemp = settings.colorTemperature {
            // Convert Kelvin to Hue mireds (153-500)
            let mireds = max(153, min(500, 1000000 / colorTemp))
            lightState["ct"] = mireds
        }
        
        if let color = settings.color {
            let hsb = rgbToHSB(color)
            lightState["hue"] = Int(hsb.hue * 65535) // Hue uses 0-65535
            lightState["sat"] = Int(hsb.saturation * 254) // Saturation 0-254
        }
        
        await sendHueCommand(deviceId: device.id, state: lightState)
    }
    
    func setTemperature(device: SmartHomeDevice, settings: TemperatureSettings) async {
        // Philips Hue doesn't support temperature control
    }
    
    func setHumidity(device: SmartHomeDevice, settings: HumiditySettings) async {
        // Philips Hue doesn't support humidity control
    }
    
    func setNoise(device: SmartHomeDevice, settings: NoiseSettings) async {
        // Philips Hue doesn't support noise control
    }
    
    func getDeviceStatus(device: SmartHomeDevice) async -> DeviceCapabilities? {
        guard let apiKey = apiKey else { return nil }
        
        // Implementation would fetch current state from Hue API
        return nil
    }
    
    private func discoverHueBridge(completion: @escaping (String?) -> Void) {
        // Implementation would use SSDP or Hue's discovery service
        // For now, return nil to indicate no bridge found
        completion(nil)
    }
    
    private func authenticateWithBridge(bridgeIP: String, completion: @escaping (Bool) -> Void) {
        // Implementation would handle Hue bridge authentication
        completion(false)
    }
    
    private func fetchHueDevices(completion: @escaping ([SmartHomeDevice]) -> Void) {
        // Implementation would fetch lights from Hue API
        completion([])
    }
    
    private func sendHueCommand(deviceId: String, state: [String: Any]) async {
        // Implementation would send PUT request to Hue API
    }
    
    private func rgbToHSB(_ rgb: RGBColor) -> (hue: Double, saturation: Double, brightness: Double) {
        let max = Swift.max(rgb.red, Swift.max(rgb.green, rgb.blue))
        let min = Swift.min(rgb.red, Swift.min(rgb.green, rgb.blue))
        let delta = max - min
        
        let brightness = max
        let saturation = max == 0 ? 0 : delta / max
        
        var hue: Double = 0
        if delta != 0 {
            if max == rgb.red {
                hue = (rgb.green - rgb.blue) / delta
            } else if max == rgb.green {
                hue = 2 + (rgb.blue - rgb.red) / delta
            } else {
                hue = 4 + (rgb.red - rgb.green) / delta
            }
            hue /= 6
            if hue < 0 { hue += 1 }
        }
        
        return (hue, saturation, brightness)
    }
}

// MARK: - Nest Adapter

class NestAdapter: SmartHomeAdapter {
    private let clientId = "your-nest-client-id"
    private let clientSecret = "your-nest-client-secret"
    private var accessToken: String?
    
    func discoverDevices(completion: @escaping ([SmartHomeDevice]) -> Void) {
        authenticateWithNest { [weak self] success in
            if success {
                self?.fetchNestDevices(completion: completion)
            } else {
                completion([])
            }
        }
    }
    
    func setLighting(device: SmartHomeDevice, settings: LightingSettings) async {
        // Nest doesn't support lighting control
    }
    
    func setTemperature(device: SmartHomeDevice, settings: TemperatureSettings) async {
        guard let accessToken = accessToken else { return }
        
        let temperatureData: [String: Any] = [
            "target_temperature_c": settings.target
        ]
        
        await sendNestCommand(deviceId: device.id, data: temperatureData)
    }
    
    func setHumidity(device: SmartHomeDevice, settings: HumiditySettings) async {
        // Most Nest devices don't support humidity control
    }
    
    func setNoise(device: SmartHomeDevice, settings: NoiseSettings) async {
        // Nest doesn't support noise control
    }
    
    func getDeviceStatus(device: SmartHomeDevice) async -> DeviceCapabilities? {
        guard let accessToken = accessToken else { return nil }
        
        // Implementation would fetch current state from Nest API
        return nil
    }
    
    private func authenticateWithNest(completion: @escaping (Bool) -> Void) {
        // Implementation would handle OAuth2 authentication with Nest
        completion(false)
    }
    
    private func fetchNestDevices(completion: @escaping ([SmartHomeDevice]) -> Void) {
        // Implementation would fetch thermostats and other devices from Nest API
        completion([])
    }
    
    private func sendNestCommand(deviceId: String, data: [String: Any]) async {
        // Implementation would send PUT request to Nest API
    }
}

// MARK: - Ecobee Adapter

class EcobeeAdapter: SmartHomeAdapter {
    private let apiKey = "your-ecobee-api-key"
    private var accessToken: String?
    
    func discoverDevices(completion: @escaping ([SmartHomeDevice]) -> Void) {
        authenticateWithEcobee { [weak self] success in
            if success {
                self?.fetchEcobeeDevices(completion: completion)
            } else {
                completion([])
            }
        }
    }
    
    func setLighting(device: SmartHomeDevice, settings: LightingSettings) async {
        // Ecobee doesn't support lighting control
    }
    
    func setTemperature(device: SmartHomeDevice, settings: TemperatureSettings) async {
        guard let accessToken = accessToken else { return }
        
        let thermostatData: [String: Any] = [
            "selection": [
                "selectionType": "thermostats",
                "selectionMatch": device.id
            ],
            "functions": [
                [
                    "type": "setHold",
                    "params": [
                        "holdType": "nextTransition",
                        "coolHoldTemp": Int(settings.target * 10), // Ecobee uses tenths of degrees
                        "heatHoldTemp": Int(settings.target * 10)
                    ]
                ]
            ]
        ]
        
        await sendEcobeeCommand(data: thermostatData)
    }
    
    func setHumidity(device: SmartHomeDevice, settings: HumiditySettings) async {
        // Ecobee supports humidity control on some models
        guard let accessToken = accessToken else { return }
        
        let humidityData: [String: Any] = [
            "selection": [
                "selectionType": "thermostats",
                "selectionMatch": device.id
            ],
            "thermostat": [
                "settings": [
                    "humidifierLevel": Int(settings.target)
                ]
            ]
        ]
        
        await sendEcobeeCommand(data: humidityData)
    }
    
    func setNoise(device: SmartHomeDevice, settings: NoiseSettings) async {
        // Ecobee doesn't support noise control
    }
    
    func getDeviceStatus(device: SmartHomeDevice) async -> DeviceCapabilities? {
        guard let accessToken = accessToken else { return nil }
        
        // Implementation would fetch current state from Ecobee API
        return nil
    }
    
    private func authenticateWithEcobee(completion: @escaping (Bool) -> Void) {
        // Implementation would handle PIN-based authentication with Ecobee
        completion(false)
    }
    
    private func fetchEcobeeDevices(completion: @escaping ([SmartHomeDevice]) -> Void) {
        // Implementation would fetch thermostats from Ecobee API
        completion([])
    }
    
    private func sendEcobeeCommand(data: [String: Any]) async {
        // Implementation would send POST request to Ecobee API
    }
}

// MARK: - SmartThings Adapter

class SmartThingsAdapter: SmartHomeAdapter {
    private let personalAccessToken = "your-smartthings-token"
    private let baseURL = "https://api.smartthings.com/v1"
    
    func discoverDevices(completion: @escaping ([SmartHomeDevice]) -> Void) {
        fetchSmartThingsDevices(completion: completion)
    }
    
    func setLighting(device: SmartHomeDevice, settings: LightingSettings) async {
        let commands: [[String: Any]] = [
            [
                "component": "main",
                "capability": "switchLevel",
                "command": "setLevel",
                "arguments": [Int(settings.brightness * 100)]
            ]
        ]
        
        if let colorTemp = settings.colorTemperature {
            let colorTempCommand: [String: Any] = [
                "component": "main",
                "capability": "colorTemperature",
                "command": "setColorTemperature",
                "arguments": [colorTemp]
            ]
            await sendSmartThingsCommand(deviceId: device.id, commands: [colorTempCommand])
        }
        
        await sendSmartThingsCommand(deviceId: device.id, commands: commands)
    }
    
    func setTemperature(device: SmartHomeDevice, settings: TemperatureSettings) async {
        let commands: [[String: Any]] = [
            [
                "component": "main",
                "capability": "thermostatCoolingSetpoint",
                "command": "setCoolingSetpoint",
                "arguments": [settings.target]
            ],
            [
                "component": "main",
                "capability": "thermostatHeatingSetpoint",
                "command": "setHeatingSetpoint",
                "arguments": [settings.target]
            ]
        ]
        
        await sendSmartThingsCommand(deviceId: device.id, commands: commands)
    }
    
    func setHumidity(device: SmartHomeDevice, settings: HumiditySettings) async {
        // SmartThings humidity control depends on specific device capabilities
    }
    
    func setNoise(device: SmartHomeDevice, settings: NoiseSettings) async {
        // SmartThings noise control would be device-specific
    }
    
    func getDeviceStatus(device: SmartHomeDevice) async -> DeviceCapabilities? {
        // Implementation would fetch current state from SmartThings API
        return nil
    }
    
    private func fetchSmartThingsDevices(completion: @escaping ([SmartHomeDevice]) -> Void) {
        // Implementation would fetch devices from SmartThings API
        completion([])
    }
    
    private func sendSmartThingsCommand(deviceId: String, commands: [[String: Any]]) async {
        // Implementation would send POST request to SmartThings API
    }
}

// MARK: - Environment Monitor

class EnvironmentMonitor {
    
    func getCurrentEnvironments(for devices: [SmartHomeDevice]) async -> [String: RoomEnvironment] {
        var environments: [String: RoomEnvironment] = [:]
        
        let rooms = Set(devices.map { $0.room })
        
        for room in rooms {
            let roomDevices = devices.filter { $0.room == room }
            let environment = await calculateRoomEnvironment(devices: roomDevices)
            environments[room] = environment
        }
        
        return environments
    }
    
    private func calculateRoomEnvironment(devices: [SmartHomeDevice]) async -> RoomEnvironment {
        var temperature: Double = 21.0
        var humidity: Double = 50.0
        var lightLevel: Double = 0.5
        var noiseLevel: Double = 35.0
        var airQuality: AirQuality = .good
        
        // Collect sensor data from devices
        for device in devices {
            if let capabilities = await getDeviceCapabilities(device) {
                if let temp = capabilities.currentTemperature {
                    temperature = temp
                }
                if let hum = capabilities.currentHumidity {
                    humidity = hum
                }
                if let brightness = capabilities.currentBrightness {
                    lightLevel = brightness
                }
                if let noise = capabilities.currentNoiseLevel {
                    noiseLevel = noise
                }
                if let air = capabilities.currentAirQuality {
                    airQuality = air
                }
            }
        }
        
        // Add some realistic variation
        temperature += Double.random(in: -1.0...1.0)
        humidity += Double.random(in: -5.0...5.0)
        noiseLevel += Double.random(in: -5.0...5.0)
        
        return RoomEnvironment(
            temperature: temperature,
            humidity: humidity,
            lightLevel: lightLevel,
            noiseLevel: noiseLevel,
            airQuality: airQuality,
            optimizationScore: calculateOptimizationScore(
                temp: temperature,
                humidity: humidity,
                light: lightLevel,
                noise: noiseLevel,
                air: airQuality
            ),
            lastUpdated: Date()
        )
    }
    
    private func getDeviceCapabilities(_ device: SmartHomeDevice) async -> DeviceCapabilities? {
        switch device.platform {
        case .homeKit:
            return await HomeKitAdapter().getDeviceStatus(device: device)
        case .philipsHue:
            return await PhilipsHueAdapter().getDeviceStatus(device: device)
        case .nest:
            return await NestAdapter().getDeviceStatus(device: device)
        case .ecobee:
            return await EcobeeAdapter().getDeviceStatus(device: device)
        case .smartThings:
            return await SmartThingsAdapter().getDeviceStatus(device: device)
        default:
            return nil
        }
    }
    
    private func calculateOptimizationScore(temp: Double, humidity: Double, light: Double, noise: Double, air: AirQuality) -> Double {
        var score: Double = 0.0
        
        // Temperature score (optimal range: 18-22°C)
        if temp >= 18 && temp <= 22 {
            score += 0.25
        } else {
            let tempDiff = min(abs(temp - 18), abs(temp - 22))
            score += max(0, 0.25 - tempDiff * 0.05)
        }
        
        // Humidity score (optimal range: 40-60%)
        if humidity >= 40 && humidity <= 60 {
            score += 0.25
        } else {
            let humidityDiff = min(abs(humidity - 40), abs(humidity - 60))
            score += max(0, 0.25 - humidityDiff * 0.01)
        }
        
        // Light score (depends on time of day)
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: Date())
        
        if hour >= 22 || hour <= 6 {
            // Night time - prefer dim light
            score += light < 0.3 ? 0.25 : max(0, 0.25 - (light - 0.3) * 0.5)
        } else {
            // Day time - prefer brighter light
            score += light > 0.5 ? 0.25 : max(0, 0.25 - (0.5 - light) * 0.5)
        }
        
        // Noise score (optimal: <40 dB)
        if noise <= 40 {
            score += 0.15
        } else {
            score += max(0, 0.15 - (noise - 40) * 0.01)
        }
        
        // Air quality score
        switch air {
        case .excellent:
            score += 0.1
        case .good:
            score += 0.08
        case .moderate:
            score += 0.05
        case .poor:
            score += 0.02
        case .unhealthy:
            score += 0.0
        }
        
        return min(1.0, score)
    }
}

// MARK: - Sleep Environment Optimizer

class SleepEnvironmentOptimizer {
    
    func calculateOptimalSettings(for sleepStage: SleepStage) -> SleepEnvironmentOptimization {
        return SleepEnvironmentOptimization(for: sleepStage)
    }
}

// MARK: - Smart Home Automation Engine

class SmartHomeAutomationEngine {
    weak var delegate: SmartHomeAutomationEngineDelegate?
    
    private var isProcessingRules = false
    
    func evaluateRules(_ rules: [EnvironmentAutomationRule], 
                      healthData: HealthDataSnapshot?, 
                      environmentData: [String: RoomEnvironment]) {
        guard !isProcessingRules else { return }
        isProcessingRules = true
        
        defer { isProcessingRules = false }
        
        for rule in rules {
            guard rule.isEnabled else { continue }
            
            if shouldExecuteRule(rule, healthData: healthData, environmentData: environmentData) {
                if delegate?.automationEngine(self, shouldExecuteRule: rule) == true {
                    executeRule(rule)
                }
            }
        }
    }
    
    private func shouldExecuteRule(_ rule: EnvironmentAutomationRule, 
                                 healthData: HealthDataSnapshot?, 
                                 environmentData: [String: RoomEnvironment]) -> Bool {
        // Check trigger
        guard evaluateTrigger(rule.trigger, healthData: healthData, environmentData: environmentData) else {
            return false
        }
        
        // Check all conditions
        for condition in rule.conditions {
            if !evaluateCondition(condition, healthData: healthData, environmentData: environmentData) {
                return false
            }
        }
        
        return true
    }
    
    private func evaluateTrigger(_ trigger: AutomationTrigger, 
                               healthData: HealthDataSnapshot?, 
                               environmentData: [String: RoomEnvironment]) -> Bool {
        switch trigger {
        case .sleepStage(let stage):
            return healthData?.sleepStage == stage
        case .stressLevel(let level):
            return healthData?.stressLevel ?? 0 >= level
        case .heartRate(let rate):
            return healthData?.heartRate ?? 0 >= rate
        case .time(let timeString):
            return isCurrentTime(timeString)
        case .temperature(let temp):
            return environmentData.values.contains { $0.temperature >= temp }
        case .humidity(let humidity):
            return environmentData.values.contains { $0.humidity >= humidity }
        case .airQuality(let quality):
            return environmentData.values.contains { $0.airQuality.rawValue >= quality.rawValue }
        case .motionDetected, .noMotionDetected:
            return false // Would need motion sensor integration
        }
    }
    
    private func evaluateCondition(_ condition: AutomationCondition, 
                                 healthData: HealthDataSnapshot?, 
                                 environmentData: [String: RoomEnvironment]) -> Bool {
        switch condition {
        case .timeRange(let start, let end):
            return isTimeInRange(start: start, end: end)
        case .stressLevel(let min, let max):
            let stress = healthData?.stressLevel ?? 0
            return (min == nil || stress >= min!) && (max == nil || stress <= max!)
        case .heartRate(let min, let max):
            let hr = healthData?.heartRate ?? 0
            return (min == nil || hr >= min!) && (max == nil || hr <= max!)
        case .temperature(let min, let max):
            let temps = environmentData.values.map { $0.temperature }
            let avgTemp = temps.isEmpty ? 21.0 : temps.reduce(0, +) / Double(temps.count)
            return (min == nil || avgTemp >= min!) && (max == nil || avgTemp <= max!)
        case .humidity(let min, let max):
            let humidities = environmentData.values.map { $0.humidity }
            let avgHumidity = humidities.isEmpty ? 50.0 : humidities.reduce(0, +) / Double(humidities.count)
            return (min == nil || avgHumidity >= min!) && (max == nil || avgHumidity <= max!)
        case .sleepStage(let stage):
            return healthData?.sleepStage == stage
        case .isAsleep(let asleep):
            let isCurrentlyAsleep = healthData?.sleepStage != .awake
            return isCurrentlyAsleep == asleep
        case .isAwake(let awake):
            let isCurrentlyAwake = healthData?.sleepStage == .awake
            return isCurrentlyAwake == awake
        case .dayOfWeek(let days):
            let currentDay = Calendar.current.component(.weekday, from: Date())
            return days.contains(currentDay)
        }
    }
    
    private func executeRule(_ rule: EnvironmentAutomationRule) {
        Task {
            do {
                for action in rule.actions {
                    try await executeAction(action)
                }
                
                delegate?.automationEngine(self, didExecuteRule: rule)
            } catch {
                delegate?.automationEngine(self, didFailToExecuteRule: rule, error: error)
            }
        }
    }
    
    private func executeAction(_ action: AutomationAction) async throws {
        switch action {
        case .adjustLighting(let brightness, let colorTemp):
            let settings = LightingSettings(brightness: brightness, colorTemperature: colorTemp)
            await SmartHomeManager.shared.adjustLighting(settings)
            
        case .setTemperature(let target):
            let settings = TemperatureSettings(target: target, mode: .comfort)
            await SmartHomeManager.shared.adjustTemperature(settings)
            
        case .setHumidity(let target):
            let settings = HumiditySettings(target: target, mode: .auto)
            await SmartHomeManager.shared.adjustHumidity(settings)
            
        case .enableWhiteNoise(let volume):
            let settings = NoiseSettings(whiteNoise: true, volume: volume, soundType: .whiteNoise)
            await SmartHomeManager.shared.controlNoise(settings)
            
        case .disableWhiteNoise():
            let settings = NoiseSettings(whiteNoise: false, volume: 0.0)
            await SmartHomeManager.shared.controlNoise(settings)
            
        case .turnOnDevice(let deviceId), .turnOffDevice(let deviceId), .setDeviceValue(let deviceId, _):
            // Would need device-specific control implementation
            break
            
        case .sendNotification(let title, let message):
            // Would integrate with notification system
            break
            
        case .playSound(let soundType, let volume):
            let settings = NoiseSettings(whiteNoise: true, volume: volume, soundType: soundType)
            await SmartHomeManager.shared.controlNoise(settings)
            
        case .activateScene(let sceneName):
            // Would need scene management implementation
            break
        }
    }
    
    private func isCurrentTime(_ timeString: String) -> Bool {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        
        let currentTimeString = formatter.string(from: Date())
        return currentTimeString == timeString
    }
    
    private func isTimeInRange(start: String, end: String) -> Bool {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        
        guard let startTime = formatter.date(from: start),
              let endTime = formatter.date(from: end) else {
            return false
        }
        
        let now = Date()
        let calendar = Calendar.current
        
        let currentTime = calendar.date(bySettingHour: calendar.component(.hour, from: now),
                                      minute: calendar.component(.minute, from: now),
                                      second: 0,
                                      of: now) ?? now
        
        if startTime <= endTime {
            // Same day range
            return currentTime >= startTime && currentTime <= endTime
        } else {
            // Overnight range
            return currentTime >= startTime || currentTime <= endTime
        }
    }
}
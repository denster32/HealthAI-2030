import Foundation
import Combine
#if canImport(HomeKit)
import HomeKit
#endif

@MainActor
public class EnvironmentManager: ObservableObject {
    public static let shared = EnvironmentManager()
    @Published public var environmentData: EnvironmentData = EnvironmentData()
    @Published public var errors: [Error] = []
    @Published public var isConnected = false
    
    #if canImport(HomeKit)
    private var homeManager: HMHomeManager?
    #endif
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        setupHomeKit()
        loadInitialEnvironmentData()
    }
    
    private func setupHomeKit() {
        #if canImport(HomeKit)
        homeManager = HMHomeManager()
        homeManager?.delegate = self
        
        NotificationCenter.default.publisher(for: .HMHomeManagerDidUpdateHomes)
            .sink { [weak self] _ in
                self?.isConnected = self?.homeManager?.primaryHome != nil
            }
            .store(in: &cancellables)
        #else
        isConnected = false
        #endif
    }
    
    private func loadInitialEnvironmentData() {
        #if canImport(HomeKit)
        if let home = homeManager?.primaryHome {
            loadHomeKitData(from: home)
        } else {
            loadDefaultEnvironmentData()
        }
        #else
        loadDefaultEnvironmentData()
        #endif
    }
    
    #if canImport(HomeKit)
    private func loadHomeKitData(from home: HMHome) {
        for accessory in home.accessories {
            for service in accessory.services {
                for characteristic in service.characteristics {
                    updateEnvironmentData(from: characteristic)
                }
            }
        }
    }
    #endif
    
    private func loadDefaultEnvironmentData() {
        environmentData = EnvironmentData(
            temperature: 22.0,
            humidity: 45.0,
            airQuality: .good,
            lighting: .natural,
            noiseLevel: .low
        )
    }
    
    #if canImport(HomeKit)
    private func updateEnvironmentData(from characteristic: HMCharacteristic) {
        switch characteristic.characteristicType {
        case HMCharacteristicTypeCurrentTemperature:
            if let value = characteristic.value as? Double {
                environmentData.temperature = value
            }
        case HMCharacteristicTypeCurrentRelativeHumidity:
            if let value = characteristic.value as? Double {
                environmentData.humidity = value
            }
        default:
            break
        }
    }
    #endif
    
    public func updateEnvironmentSetting(_ key: String, value: Any) {
        switch key {
        case "temperature":
            if let temp = value as? Double {
                environmentData.temperature = temp
                #if canImport(HomeKit)
                setTemperature(temp)
                #endif
            }
        case "humidity":
            if let humidity = value as? Double {
                environmentData.humidity = humidity
                #if canImport(HomeKit)
                setHumidity(humidity)
                #endif
            }
        case "lighting":
            if let lighting = value as? LightingMode {
                environmentData.lighting = lighting
                #if canImport(HomeKit)
                setLighting(lighting)
                #endif
            }
        default:
            environmentData.customSettings[key] = String(describing: value)
        }
    }
    
    #if canImport(HomeKit)
    private func setTemperature(_ temperature: Double) {
        guard let home = homeManager?.primaryHome else { return }
        
        for accessory in home.accessories {
            for service in accessory.services {
                if service.serviceType == HMServiceTypeThermostat {
                    for characteristic in service.characteristics {
                        if characteristic.characteristicType == HMCharacteristicTypeTargetTemperature {
                            characteristic.writeValue(temperature) { error in
                                if let error = error {
                                    self.errors.append(error)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func setHumidity(_ humidity: Double) {
        guard let home = homeManager?.primaryHome else { return }
        
        for accessory in home.accessories {
            for service in accessory.services {
                if service.serviceType == HMServiceTypeHumidifierDehumidifier {
                    for characteristic in service.characteristics {
                        if characteristic.characteristicType == HMCharacteristicTypeTargetRelativeHumidity {
                            characteristic.writeValue(humidity) { error in
                                if let error = error {
                                    self.errors.append(error)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func setLighting(_ mode: LightingMode) {
        guard let home = homeManager?.primaryHome else { return }
        
        for accessory in home.accessories {
            for service in accessory.services {
                if service.serviceType == HMServiceTypeLightbulb {
                    for characteristic in service.characteristics {
                        if characteristic.characteristicType == HMCharacteristicTypeBrightness {
                            let brightness: Float = mode == .bright ? 1.0 : mode == .dim ? 0.3 : 0.0
                            characteristic.writeValue(brightness) { error in
                                if let error = error {
                                    self.errors.append(error)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    #endif
}

#if canImport(HomeKit)
extension EnvironmentManager: HMHomeManagerDelegate {
    public func homeManagerDidUpdateHomes(_ manager: HMHomeManager) {
        if let home = manager.primaryHome {
            loadHomeKitData(from: home)
        }
    }
}
#endif

public struct EnvironmentData: Codable {
    public var temperature: Double
    public var humidity: Double
    public var airQuality: AirQuality
    public var lighting: LightingMode
    public var noiseLevel: NoiseLevel
    public var customSettings: [String: String] = [:]
    
    public init(temperature: Double = 22.0, humidity: Double = 45.0, airQuality: AirQuality = .good, lighting: LightingMode = .natural, noiseLevel: NoiseLevel = .low) {
        self.temperature = temperature
        self.humidity = humidity
        self.airQuality = airQuality
        self.lighting = lighting
        self.noiseLevel = noiseLevel
    }
}

public enum AirQuality: String, Codable, CaseIterable {
    case excellent = "Excellent"
    case good = "Good"
    case moderate = "Moderate"
    case poor = "Poor"
    case hazardous = "Hazardous"
}

public enum LightingMode: String, Codable, CaseIterable {
    case natural = "Natural"
    case bright = "Bright"
    case dim = "Dim"
    case off = "Off"
}

public enum NoiseLevel: String, Codable, CaseIterable {
    case low = "Low"
    case moderate = "Moderate"
    case high = "High"
}

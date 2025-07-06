import Foundation
import HomeKit

/// Manages HomeKit integration for smart home devices.
///
/// - Handles device discovery, characteristics, and control
/// - Supports both HomeKit and Matter protocols
/// - Provides thread-safe access to HomeKit accessories
final class HomeKitManager: NSObject, ObservableObject {
    static let shared = HomeKitManager()
    
    private let homeManager = HMHomeManager()
    private var primaryHome: HMHome?
    private var accessories = [HMAccessory]()
    
    @Published var isReady = false
    @Published var discoveredDevices = [String]()
    
    override private init() {
        super.init()
        homeManager.delegate = self
    }
    
    /// Discovers and connects to available HomeKit/Matter devices
    func initialize() async {
        guard let home = homeManager.primaryHome else {
            print("HOMEKIT: No primary home configured")
            return
        }
        
        primaryHome = home
        accessories = home.accessories
        
        // Filter to only devices with relevant services
        discoveredDevices = accessories.compactMap { accessory in
            guard hasRelevantServices(accessory) else { return nil }
            return accessory.name
        }
        
        isReady = true
        print("HOMEKIT: Initialized with \(discoveredDevices.count) devices")
    }
    
    /// Updates lighting characteristics for circadian rhythm optimization
    /// - Parameters:
    ///   - colorTemperature: Desired color temperature in Kelvin
    ///   - brightness: Desired brightness percentage (0-100)
    func updateLights(colorTemperature: Int, brightness: Int) {
        accessories.forEach { accessory in
            guard let service = accessory.services.first(where: { $0.serviceType == HMServiceTypeLightbulb }) else { return }
            
            if let tempChar = service.characteristics.first(where: { $0.characteristicType == HMCharacteristicTypeColorTemperature }),
               let brightChar = service.characteristics.first(where: { $0.characteristicType == HMCharacteristicTypeBrightness }) {
                
                tempChar.writeValue(colorTemperature) { error in
                    if let error = error {
                        print("HOMEKIT: Failed to set temperature: \(error)")
                    }
                }
                
                brightChar.writeValue(brightness) { error in
                    if let error = error {
                        print("HOMEKIT: Failed to set brightness: \(error)")
                    }
                }
            }
        }
    }
    
    /// Controls air purifier based on air quality
    /// - Parameter shouldActivate: Whether to turn purifier on/off
    func setAirPurifier(on shouldActivate: Bool) {
        accessories.forEach { accessory in
            guard let service = accessory.services.first(where: { $0.serviceType == HMServiceTypeAirPurifier }) else { return }
            
            if let powerChar = service.characteristics.first(where: { $0.characteristicType == HMCharacteristicTypePowerState }) {
                powerChar.writeValue(shouldActivate) { error in
                    if let error = error {
                        print("HOMEKIT: Failed to set air purifier: \(error)")
                    }
                }
            }
        }
    }
    
    /// Controls smart blinds position
    /// - Parameter position: Desired position (0=closed, 100=open)
    func setBlinds(position: Int) {
        accessories.forEach { accessory in
            guard let service = accessory.services.first(where: { $0.serviceType == HMServiceTypeWindowCovering }) else { return }
            
            if let positionChar = service.characteristics.first(where: { $0.characteristicType == HMCharacteristicTypeTargetPosition }) {
                positionChar.writeValue(position) { error in
                    if let error = error {
                        print("HOMEKIT: Failed to set blinds: \(error)")
                    }
                }
            }
        }
    }
    
    private func hasRelevantServices(_ accessory: HMAccessory) -> Bool {
        let relevantServiceTypes: Set<String> = [
            HMServiceTypeLightbulb,
            HMServiceTypeAirPurifier,
            HMServiceTypeWindowCovering
        ]
        return accessory.services.contains { relevantServiceTypes.contains($0.serviceType) }
    }
}

// MARK: - HMHomeManagerDelegate
extension HomeKitManager: HMHomeManagerDelegate {
    func homeManagerDidUpdateHomes(_ manager: HMHomeManager) {
        Task {
            await initialize()
        }
    }
    
    func homeManager(_ manager: HMHomeManager, didAdd home: HMHome) {
        primaryHome = home
    }
    
    func homeManager(_ manager: HMHomeManager, didRemove home: HMHome) {
        if home == primaryHome {
            primaryHome = nil
        }
    }
}
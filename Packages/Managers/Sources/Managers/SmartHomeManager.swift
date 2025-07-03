import Foundation
#if os(iOS)
import HomeKit
#endif
import Combine
import Network

class SmartHomeManager: NSObject, ObservableObject {
    static let shared = SmartHomeManager()
    
    // MARK: - Published Properties
    @Published var isHomeKitEnabled = false
    @Published var connectedDevices: [SmartHomeDevice] = []
    @Published var availableHomes: [HMHome] = []
    @Published var selectedHome: HMHome?
    @Published var roomEnvironments: [String: RoomEnvironment] = [:]
    @Published var automationRules: [EnvironmentAutomationRule] = []
    @Published var connectionStatus: SmartHomeConnectionStatus = .disconnected
    @Published var lastEnvironmentUpdate: Date?
    
    // MARK: - Private Properties
    private let homeManager = HMHomeManager()
    private let healthDataManager = HealthDataManager.shared
    private let networkMonitor = NWPathMonitor()
    private let automationEngine = SmartHomeAutomationEngine()
    
    private var cancellables = Set<AnyCancellable>()
    private var deviceDiscoveryTimer: Timer?
    private var environmentUpdateTimer: Timer?
    
    // Integration adapters for different smart home platforms
    private let homeKitAdapter = HomeKitAdapter()
    private let philipsHueAdapter = PhilipsHueAdapter()
    private let nestAdapter = NestAdapter()
    private let ecobeeAdapter = EcobeeAdapter()
    private let smartThingsAdapter = SmartThingsAdapter()
    
    // Environment monitoring
    private let environmentMonitor = EnvironmentMonitor()
    private let sleepOptimizer = SleepEnvironmentOptimizer()
    
    override init() {
        super.init()
        setupHomeManager()
        setupNetworkMonitoring()
        setupHealthDataIntegration()
        setupAutomationEngine()
        startEnvironmentMonitoring()
    }
    
    // MARK: - Setup
    
    private func setupHomeManager() {
        homeManager.delegate = self
        
        // Check HomeKit authorization
        checkHomeKitAuthorization()
    }
    
    private func setupNetworkMonitoring() {
        networkMonitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.updateConnectionStatus(path.status == .satisfied)
            }
        }
        
        let queue = DispatchQueue(label: "NetworkMonitor")
        networkMonitor.start(queue: queue)
    }
    
    private func setupHealthDataIntegration() {
        // Subscribe to health data changes for environment optimization
        healthDataManager.$currentSleepStage
            .compactMap { $0 }
            .sink { [weak self] sleepStage in
                self?.optimizeEnvironmentForSleep(stage: sleepStage)
            }
            .store(in: &cancellables)
        
        healthDataManager.$currentStressLevel
            .sink { [weak self] stressLevel in
                self?.adjustEnvironmentForStress(level: stressLevel)
            }
            .store(in: &cancellables)
        
        healthDataManager.$currentBodyTemperature
            .sink { [weak self] temperature in
                self?.adjustTemperatureForComfort(bodyTemp: temperature)
            }
            .store(in: &cancellables)
    }
    
    private func setupAutomationEngine() {
        automationEngine.delegate = self
        
        // Load saved automation rules
        loadAutomationRules()
        
        // Setup default automation rules
        createDefaultAutomationRules()
    }
    
    private func startEnvironmentMonitoring() {
        environmentUpdateTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.updateEnvironmentData()
        }
        
        // Initial environment update
        updateEnvironmentData()
    }
    
    // MARK: - HomeKit Authorization
    
    private func checkHomeKitAuthorization() {
        switch HMHomeManager.authorizationStatus {
        case .authorized:
            DispatchQueue.main.async {
                self.isHomeKitEnabled = true
                self.discoverDevices()
            }
        case .restricted, .denied:
            DispatchQueue.main.async {
                self.isHomeKitEnabled = false
                self.connectionStatus = .unauthorized
            }
        case .notDetermined:
            // Authorization will be requested when HomeManager is accessed
            break
        @unknown default:
            break
        }
    }
    
    // MARK: - Device Discovery
    
    func discoverDevices() {
        guard isHomeKitEnabled else { return }
        
        DispatchQueue.main.async {
            self.connectionStatus = .discovering
        }
        
        // Discover HomeKit devices
        discoverHomeKitDevices()
        
        // Discover third-party devices
        discoverThirdPartyDevices()
        
        // Start periodic discovery
        startPeriodicDiscovery()
    }
    
    private func discoverHomeKitDevices() {
        availableHomes = homeManager.homes
        
        if let primaryHome = homeManager.primaryHome {
            selectedHome = primaryHome
            
            var devices: [SmartHomeDevice] = []
            
            for accessory in primaryHome.accessories {
                let device = SmartHomeDevice(
                    id: accessory.uniqueIdentifier.uuidString,
                    name: accessory.name,
                    type: mapHomeKitDeviceType(accessory),
                    platform: .homeKit,
                    room: accessory.room?.name ?? "Unknown",
                    isReachable: accessory.isReachable,
                    capabilities: extractCapabilities(from: accessory),
                    lastUpdated: Date()
                )
                devices.append(device)
            }
            
            DispatchQueue.main.async {
                self.connectedDevices.append(contentsOf: devices)
                self.connectionStatus = .connected
                self.updateRoomEnvironments()
            }
        }
    }
    
    private func discoverThirdPartyDevices() {
        // Discover Philips Hue devices
        philipsHueAdapter.discoverDevices { [weak self] devices in
            DispatchQueue.main.async {
                self?.connectedDevices.append(contentsOf: devices)
                self?.updateRoomEnvironments()
            }
        }
        
        // Discover Nest devices
        nestAdapter.discoverDevices { [weak self] devices in
            DispatchQueue.main.async {
                self?.connectedDevices.append(contentsOf: devices)
                self?.updateRoomEnvironments()
            }
        }
        
        // Discover Ecobee devices
        ecobeeAdapter.discoverDevices { [weak self] devices in
            DispatchQueue.main.async {
                self?.connectedDevices.append(contentsOf: devices)
                self?.updateRoomEnvironments()
            }
        }
        
        // Discover SmartThings devices
        smartThingsAdapter.discoverDevices { [weak self] devices in
            DispatchQueue.main.async {
                self?.connectedDevices.append(contentsOf: devices)
                self?.updateRoomEnvironments()
            }
        }
    }
    
    private func startPeriodicDiscovery() {
        deviceDiscoveryTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            self?.discoverDevices()
        }
    }
    
    // MARK: - Environment Control
    
    func optimizeEnvironmentForSleep(stage: SleepStage) {
        let optimization = sleepOptimizer.calculateOptimalSettings(for: stage)
        
        Task {
            // Adjust lighting
            await adjustLighting(optimization.lighting)
            
            // Adjust temperature
            await adjustTemperature(optimization.temperature)
            
            // Adjust humidity
            await adjustHumidity(optimization.humidity)
            
            // Control noise
            await controlNoise(optimization.noise)
            
            // Update room environments
            DispatchQueue.main.async {
                self.updateRoomEnvironments()
            }
        }
    }
    
    func adjustEnvironmentForStress(level: Double) {
        guard level > 0.7 else { return } // Only adjust for high stress
        
        Task {
            // Dim lights for relaxation
            await adjustLighting(LightingSettings(
                brightness: 0.3,
                colorTemperature: 2700, // Warm light
                color: .warm
            ))
            
            // Slightly reduce temperature for comfort
            await adjustTemperature(TemperatureSettings(
                target: 21.0,
                mode: .comfort
            ))
            
            // Activate white noise if available
            await controlNoise(NoiseSettings(
                whiteNoise: true,
                volume: 0.3
            ))
        }
    }
    
    func adjustTemperatureForComfort(bodyTemp: Double) {
        guard bodyTemp > 0 else { return }
        
        let targetRoomTemp: Double
        
        if bodyTemp > 37.5 { // Elevated body temperature
            targetRoomTemp = 19.0 // Cooler room
        } else if bodyTemp < 36.5 { // Lower body temperature
            targetRoomTemp = 23.0 // Warmer room
        } else {
            targetRoomTemp = 21.0 // Normal room temperature
        }
        
        Task {
            await adjustTemperature(TemperatureSettings(
                target: targetRoomTemp,
                mode: .comfort
            ))
        }
    }
    
    // MARK: - Device Control Methods
    
    func adjustLighting(_ settings: LightingSettings) async {
        let lightingDevices = connectedDevices.filter { $0.type == .lighting }
        
        for device in lightingDevices {
            switch device.platform {
            case .homeKit:
                await homeKitAdapter.setLighting(device: device, settings: settings)
            case .philipsHue:
                await philipsHueAdapter.setLighting(device: device, settings: settings)
            case .smartThings:
                await smartThingsAdapter.setLighting(device: device, settings: settings)
            default:
                break
            }
        }
    }
    
    func adjustTemperature(_ settings: TemperatureSettings) async {
        let thermostatDevices = connectedDevices.filter { $0.type == .thermostat }
        
        for device in thermostatDevices {
            switch device.platform {
            case .homeKit:
                await homeKitAdapter.setTemperature(device: device, settings: settings)
            case .nest:
                await nestAdapter.setTemperature(device: device, settings: settings)
            case .ecobee:
                await ecobeeAdapter.setTemperature(device: device, settings: settings)
            default:
                break
            }
        }
    }
    
    func adjustHumidity(_ settings: HumiditySettings) async {
        let humidifierDevices = connectedDevices.filter { $0.type == .humidifier }
        
        for device in humidifierDevices {
            switch device.platform {
            case .homeKit:
                await homeKitAdapter.setHumidity(device: device, settings: settings)
            default:
                break
            }
        }
    }
    
    func controlNoise(_ settings: NoiseSettings) async {
        let audioDevices = connectedDevices.filter { $0.type == .speaker }
        
        for device in audioDevices {
            switch device.platform {
            case .homeKit:
                await homeKitAdapter.setNoise(device: device, settings: settings)
            default:
                break
            }
        }
    }
    
    // MARK: - Automation Rules
    
    private func createDefaultAutomationRules() {
        let sleepRule = EnvironmentAutomationRule(
            id: UUID().uuidString,
            name: "Sleep Environment Optimization",
            trigger: .sleepStage(.deep),
            conditions: [
                .timeRange(start: "22:00", end: "06:00"),
                .stressLevel(max: 0.5)
            ],
            actions: [
                .adjustLighting(brightness: 0.1, colorTemp: 2000),
                .setTemperature(target: 19.0),
                .enableWhiteNoise(volume: 0.2)
            ],
            isEnabled: true
        )
        
        let wakeRule = EnvironmentAutomationRule(
            id: UUID().uuidString,
            name: "Wake Up Environment",
            trigger: .sleepStage(.awake),
            conditions: [
                .timeRange(start: "06:00", end: "10:00")
            ],
            actions: [
                .adjustLighting(brightness: 0.8, colorTemp: 6500),
                .setTemperature(target: 22.0),
                .disableWhiteNoise()
            ],
            isEnabled: true
        )
        
        automationRules = [sleepRule, wakeRule]
        saveAutomationRules()
    }
    
    private func loadAutomationRules() {
        // Load from UserDefaults or Core Data
        if let data = UserDefaults.standard.data(forKey: "SmartHomeAutomationRules"),
           let rules = try? JSONDecoder().decode([EnvironmentAutomationRule].self, from: data) {
            automationRules = rules
        }
    }
    
    private func saveAutomationRules() {
        if let data = try? JSONEncoder().encode(automationRules) {
            UserDefaults.standard.set(data, forKey: "SmartHomeAutomationRules")
        }
    }
    
    // MARK: - Environment Monitoring
    
    private func updateEnvironmentData() {
        Task {
            let environments = await environmentMonitor.getCurrentEnvironments(for: connectedDevices)
            
            DispatchQueue.main.async {
                self.roomEnvironments = environments
                self.lastEnvironmentUpdate = Date()
            }
        }
    }
    
    private func updateRoomEnvironments() {
        let rooms = Set(connectedDevices.map { $0.room })
        
        for room in rooms {
            let roomDevices = connectedDevices.filter { $0.room == room }
            let environment = calculateRoomEnvironment(devices: roomDevices)
            roomEnvironments[room] = environment
        }
    }
    
    private func calculateRoomEnvironment(devices: [SmartHomeDevice]) -> RoomEnvironment {
        var temperature: Double = 21.0
        var humidity: Double = 50.0
        var lightLevel: Double = 0.5
        var noiseLevel: Double = 35.0
        var airQuality: AirQuality = .good
        
        // Extract environmental data from devices
        for device in devices {
            switch device.type {
            case .thermostat:
                if let temp = device.capabilities.currentTemperature {
                    temperature = temp
                }
                if let hum = device.capabilities.currentHumidity {
                    humidity = hum
                }
            case .lighting:
                if let brightness = device.capabilities.currentBrightness {
                    lightLevel = brightness
                }
            case .sensor:
                if let noise = device.capabilities.currentNoiseLevel {
                    noiseLevel = noise
                }
                if let air = device.capabilities.currentAirQuality {
                    airQuality = air
                }
            default:
                break
            }
        }
        
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
    
    // MARK: - Utility Methods
    
    private func updateConnectionStatus(_ isConnected: Bool) {
        connectionStatus = isConnected ? .connected : .disconnected
    }
    
    private func mapHomeKitDeviceType(_ accessory: HMAccessory) -> SmartHomeDeviceType {
        for service in accessory.services {
            switch service.serviceType {
            case HMServiceTypeLightbulb:
                return .lighting
            case HMServiceTypeThermostat:
                return .thermostat
            case HMServiceTypeHumidifierDehumidifier:
                return .humidifier
            case HMServiceTypeTemperatureSensor:
                return .sensor
            case HMServiceTypeHumiditySensor:
                return .sensor
            case HMServiceTypeAirQualitySensor:
                return .sensor
            case HMServiceTypeSwitch:
                return .switch
            case HMServiceTypeFan:
                return .fan
            default:
                continue
            }
        }
        return .unknown
    }
    
    private func extractCapabilities(from accessory: HMAccessory) -> DeviceCapabilities {
        var capabilities = DeviceCapabilities()
        
        for service in accessory.services {
            for characteristic in service.characteristics {
                switch characteristic.characteristicType {
                case HMCharacteristicTypeCurrentTemperature:
                    capabilities.currentTemperature = characteristic.value as? Double
                case HMCharacteristicTypeCurrentRelativeHumidity:
                    capabilities.currentHumidity = characteristic.value as? Double
                case HMCharacteristicTypeBrightness:
                    capabilities.currentBrightness = (characteristic.value as? Double).map { $0 / 100.0 }
                case HMCharacteristicTypeAirQuality:
                    if let value = characteristic.value as? Int {
                        capabilities.currentAirQuality = AirQuality(rawValue: value) ?? .good
                    }
                default:
                    break
                }
            }
        }
        
        return capabilities
    }
}

// MARK: - HMHomeManagerDelegate

extension SmartHomeManager: HMHomeManagerDelegate {
    func homeManagerDidUpdateHomes(_ manager: HMHomeManager) {
        DispatchQueue.main.async {
            self.availableHomes = manager.homes
            if let primaryHome = manager.primaryHome {
                self.selectedHome = primaryHome
            }
            self.discoverHomeKitDevices()
        }
    }
    
    func homeManager(_ manager: HMHomeManager, didAdd home: HMHome) {
        DispatchQueue.main.async {
            self.availableHomes = manager.homes
            self.discoverHomeKitDevices()
        }
    }
    
    func homeManager(_ manager: HMHomeManager, didRemove home: HMHome) {
        DispatchQueue.main.async {
            self.availableHomes = manager.homes
            self.connectedDevices.removeAll { $0.platform == .homeKit }
            self.discoverHomeKitDevices()
        }
    }
}

// MARK: - SmartHomeAutomationEngineDelegate

extension SmartHomeManager: SmartHomeAutomationEngineDelegate {
    func automationEngine(_ engine: SmartHomeAutomationEngine, shouldExecuteRule rule: EnvironmentAutomationRule) -> Bool {
        return rule.isEnabled
    }
    
    func automationEngine(_ engine: SmartHomeAutomationEngine, didExecuteRule rule: EnvironmentAutomationRule) {
        print("Executed automation rule: \(rule.name)")
    }
    
    func automationEngine(_ engine: SmartHomeAutomationEngine, didFailToExecuteRule rule: EnvironmentAutomationRule, error: Error) {
        print("Failed to execute automation rule: \(rule.name), error: \(error)")
    }
}
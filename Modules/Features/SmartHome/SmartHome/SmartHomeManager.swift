import Foundation
import HomeKit
import Combine
import SwiftData

/// Smart Home Manager for HomeKit integration and health-based automation
@MainActor
public class SmartHomeManager: NSObject, ObservableObject {
    public static let shared = SmartHomeManager()
    
    @Published public var isHomeKitAvailable = false
    @Published public var homes: [HMHome] = []
    @Published public var selectedHome: HMHome?
    @Published public var devices: [HMDevice] = []
    @Published public var automations: [HMAutomation] = []
    @Published public var healthRules: [HealthAutomationRule] = []
    @Published public var isAuthorized = false
    
    private let homeManager = HMHomeManager()
    private let analytics = DeepHealthAnalytics.shared
    private var cancellables = Set<AnyCancellable>()
    
    // Health-based automation triggers
    private var healthTriggers: [String: HealthTrigger] = [:]
    private var automationTimer: Timer?
    
    private override init() {
        super.init()
        setupHomeKit()
        setupHealthMonitoring()
    }
    
    /// Setup HomeKit integration
    private func setupHomeKit() {
        homeManager.delegate = self
        
        // Check HomeKit availability
        isHomeKitAvailable = HMHomeManager.isSupported
        
        if isHomeKitAvailable {
            // Request authorization
            homeManager.requestAccess { [weak self] granted in
                Task { @MainActor in
                    self?.isAuthorized = granted
                    if granted {
                        self?.loadHomes()
                        self?.setupDeviceMonitoring()
                    }
                }
            }
        }
        
        analytics.logEvent("smart_home_setup", parameters: [
            "homekit_available": isHomeKitAvailable,
            "authorized": isAuthorized
        ])
    }
    
    /// Load available homes
    private func loadHomes() {
        homes = homeManager.homes
        selectedHome = homes.first
        
        analytics.logEvent("homes_loaded", parameters: [
            "home_count": homes.count
        ])
    }
    
    /// Setup device monitoring
    private func setupDeviceMonitoring() {
        guard let home = selectedHome else { return }
        
        // Monitor all devices in the home
        for room in home.rooms {
            for accessory in room.accessories {
                for service in accessory.services {
                    for characteristic in service.characteristics {
                        monitorCharacteristic(characteristic, in: service, accessory: accessory)
                    }
                }
            }
        }
        
        // Load existing automations
        loadAutomations()
    }
    
    /// Monitor a specific characteristic for changes
    private func monitorCharacteristic(_ characteristic: HMCharacteristic, in service: HMService, accessory: HMAccessory) {
        characteristic.enableNotification(true) { [weak self] error in
            if let error = error {
                self?.analytics.logEvent("characteristic_monitoring_failed", parameters: [
                    "accessory": accessory.name,
                    "service": service.name,
                    "characteristic": characteristic.characteristicType,
                    "error": error.localizedDescription
                ])
            }
        }
    }
    
    /// Load existing automations
    private func loadAutomations() {
        guard let home = selectedHome else { return }
        
        automations = home.automations
        
        analytics.logEvent("automations_loaded", parameters: [
            "automation_count": automations.count
        ])
    }
    
    /// Setup health monitoring for automation triggers
    private func setupHealthMonitoring() {
        // Monitor health data changes and trigger automations
        NotificationCenter.default.publisher(for: .healthDataUpdated)
            .sink { [weak self] notification in
                if let healthData = notification.object as? HealthData {
                    self?.processHealthData(healthData)
                }
            }
            .store(in: &cancellables)
    }
    
    /// Process health data and trigger automations
    private func processHealthData(_ healthData: HealthData) {
        for rule in healthRules {
            if rule.shouldTrigger(for: healthData) {
                executeAutomation(rule: rule, healthData: healthData)
            }
        }
    }
    
    /// Execute a health-based automation
    private func executeAutomation(rule: HealthAutomationRule, healthData: HealthData) {
        guard let home = selectedHome else { return }
        
        Task {
            do {
                switch rule.action {
                case .adjustLighting(let brightness, let color):
                    try await adjustLighting(brightness: brightness, color: color)
                    
                case .adjustTemperature(let temperature):
                    try await adjustTemperature(temperature: temperature)
                    
                case .playSound(let soundType):
                    try await playSound(soundType: soundType)
                    
                case .sendNotification(let message):
                    try await sendNotification(message: message)
                    
                case .custom(let action):
                    try await executeCustomAction(action)
                }
                
                analytics.logEvent("health_automation_executed", parameters: [
                    "rule_id": rule.id,
                    "action": rule.action.description,
                    "health_metric": rule.trigger.metric
                ])
                
            } catch {
                analytics.logEvent("health_automation_failed", parameters: [
                    "rule_id": rule.id,
                    "error": error.localizedDescription
                ])
            }
        }
    }
    
    /// Adjust lighting based on health data
    private func adjustLighting(brightness: Double, color: UIColor?) async throws {
        guard let home = selectedHome else { throw SmartHomeError.noHomeSelected }
        
        let lightAccessories = home.accessories.filter { accessory in
            accessory.services.contains { service in
                service.serviceType == HMServiceTypeLightbulb
            }
        }
        
        for accessory in lightAccessories {
            if let lightService = accessory.services.first(where: { $0.serviceType == HMServiceTypeLightbulb }) {
                // Adjust brightness
                if let brightnessChar = lightService.characteristics.first(where: { $0.characteristicType == HMCharacteristicTypeBrightness }) {
                    try await setCharacteristicValue(brightnessChar, value: brightness)
                }
                
                // Adjust color if specified
                if let color = color,
                   let hueChar = lightService.characteristics.first(where: { $0.characteristicType == HMCharacteristicTypeHue }),
                   let saturationChar = lightService.characteristics.first(where: { $0.characteristicType == HMCharacteristicTypeSaturation }) {
                    
                    var hue: CGFloat = 0
                    var saturation: CGFloat = 0
                    var brightness: CGFloat = 0
                    var alpha: CGFloat = 0
                    
                    color.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
                    
                    try await setCharacteristicValue(hueChar, value: hue)
                    try await setCharacteristicValue(saturationChar, value: saturation)
                }
            }
        }
    }
    
    /// Adjust temperature based on health data
    private func adjustTemperature(temperature: Double) async throws {
        guard let home = selectedHome else { throw SmartHomeError.noHomeSelected }
        
        let thermostatAccessories = home.accessories.filter { accessory in
            accessory.services.contains { service in
                service.serviceType == HMServiceTypeThermostat
            }
        }
        
        for accessory in thermostatAccessories {
            if let thermostatService = accessory.services.first(where: { $0.serviceType == HMServiceTypeThermostat }) {
                if let targetTempChar = thermostatService.characteristics.first(where: { $0.characteristicType == HMCharacteristicTypeTargetTemperature }) {
                    try await setCharacteristicValue(targetTempChar, value: temperature)
                }
            }
        }
    }
    
    /// Play sound based on health data
    private func playSound(soundType: SoundType) async throws {
        guard let home = selectedHome else { throw SmartHomeError.noHomeSelected }
        
        let speakerAccessories = home.accessories.filter { accessory in
            accessory.services.contains { service in
                service.serviceType == HMServiceTypeSpeaker
            }
        }
        
        for accessory in speakerAccessories {
            if let speakerService = accessory.services.first(where: { $0.serviceType == HMServiceTypeSpeaker }) {
                // Play appropriate sound based on health data
                let soundURL = getSoundURL(for: soundType)
                // Implementation would depend on specific speaker capabilities
            }
        }
    }
    
    /// Send notification based on health data
    private func sendNotification(message: String) async throws {
        // Send local notification
        let content = UNMutableNotificationContent()
        content.title = "Health Alert"
        content.body = message
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        
        try await UNUserNotificationCenter.current().add(request)
    }
    
    /// Execute custom action
    private func executeCustomAction(_ action: String) async throws {
        // Execute custom automation action
        // This could be a webhook, custom script, or other integration
    }
    
    /// Set characteristic value with error handling
    private func setCharacteristicValue(_ characteristic: HMCharacteristic, value: Any) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            characteristic.writeValue(value) { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }
    
    /// Get sound URL for sound type
    private func getSoundURL(for soundType: SoundType) -> URL? {
        switch soundType {
        case .relaxation:
            return Bundle.main.url(forResource: "relaxation_sound", withExtension: "mp3")
        case .alert:
            return Bundle.main.url(forResource: "alert_sound", withExtension: "mp3")
        case .motivation:
            return Bundle.main.url(forResource: "motivation_sound", withExtension: "mp3")
        }
    }
    
    // MARK: - Public Methods
    
    /// Create a new health-based automation rule
    public func createHealthRule(
        trigger: HealthTrigger,
        action: AutomationAction,
        name: String,
        isEnabled: Bool = true
    ) async throws -> HealthAutomationRule {
        let rule = HealthAutomationRule(
            id: UUID().uuidString,
            name: name,
            trigger: trigger,
            action: action,
            isEnabled: isEnabled,
            createdAt: Date()
        )
        
        healthRules.append(rule)
        
        // Save to persistent storage
        try await saveHealthRules()
        
        analytics.logEvent("health_rule_created", parameters: [
            "rule_id": rule.id,
            "trigger_metric": trigger.metric,
            "action_type": action.description
        ])
        
        return rule
    }
    
    /// Update an existing health rule
    public func updateHealthRule(_ rule: HealthAutomationRule) async throws {
        if let index = healthRules.firstIndex(where: { $0.id == rule.id }) {
            healthRules[index] = rule
            try await saveHealthRules()
            
            analytics.logEvent("health_rule_updated", parameters: [
                "rule_id": rule.id
            ])
        }
    }
    
    /// Delete a health rule
    public func deleteHealthRule(_ rule: HealthAutomationRule) async throws {
        healthRules.removeAll { $0.id == rule.id }
        try await saveHealthRules()
        
        analytics.logEvent("health_rule_deleted", parameters: [
            "rule_id": rule.id
        ])
    }
    
    /// Get devices by type
    public func getDevices(of type: HMServiceType) -> [HMAccessory] {
        guard let home = selectedHome else { return [] }
        
        return home.accessories.filter { accessory in
            accessory.services.contains { service in
                service.serviceType == type
            }
        }
    }
    
    /// Test an automation rule
    public func testRule(_ rule: HealthAutomationRule) async throws {
        let testHealthData = HealthData() // Create test data
        executeAutomation(rule: rule, healthData: testHealthData)
    }
    
    // MARK: - Persistence
    
    private func saveHealthRules() async throws {
        // Save health rules to persistent storage
        // In a real implementation, this would use SwiftData or UserDefaults
    }
    
    private func loadHealthRules() async throws {
        // Load health rules from persistent storage
        // In a real implementation, this would load from SwiftData or UserDefaults
    }
}

// MARK: - HMHomeManagerDelegate

extension SmartHomeManager: HMHomeManagerDelegate {
    public func homeManagerDidUpdateHomes(_ manager: HMHomeManager) {
        Task { @MainActor in
            loadHomes()
        }
    }
    
    public func homeManager(_ manager: HMHomeManager, didAdd home: HMHome) {
        Task { @MainActor in
            homes.append(home)
            if selectedHome == nil {
                selectedHome = home
            }
        }
    }
    
    public func homeManager(_ manager: HMHomeManager, didRemove home: HMHome) {
        Task { @MainActor in
            homes.removeAll { $0.uniqueIdentifier == home.uniqueIdentifier }
            if selectedHome?.uniqueIdentifier == home.uniqueIdentifier {
                selectedHome = homes.first
            }
        }
    }
}

// MARK: - Data Models

public struct HealthAutomationRule: Identifiable, Codable {
    public let id: String
    public let name: String
    public let trigger: HealthTrigger
    public let action: AutomationAction
    public var isEnabled: Bool
    public let createdAt: Date
    
    public init(id: String, name: String, trigger: HealthTrigger, action: AutomationAction, isEnabled: Bool, createdAt: Date) {
        self.id = id
        self.name = name
        self.trigger = trigger
        self.action = action
        self.isEnabled = isEnabled
        self.createdAt = createdAt
    }
    
    public func shouldTrigger(for healthData: HealthData) -> Bool {
        guard isEnabled else { return false }
        
        switch trigger.metric {
        case "heart_rate":
            guard let heartRate = healthData.heartRate else { return false }
            return trigger.evaluate(value: heartRate)
            
        case "stress_level":
            guard let stressLevel = healthData.stressLevel else { return false }
            return trigger.evaluate(value: stressLevel)
            
        case "sleep_quality":
            guard let sleepScore = healthData.sleepScore else { return false }
            return trigger.evaluate(value: sleepScore)
            
        case "activity_level":
            guard let activityLevel = healthData.activityLevel else { return false }
            return trigger.evaluate(value: activityLevel)
            
        default:
            return false
        }
    }
}

public struct HealthTrigger: Codable {
    public let metric: String
    public let condition: TriggerCondition
    public let threshold: Double
    
    public init(metric: String, condition: TriggerCondition, threshold: Double) {
        self.metric = metric
        self.condition = condition
        self.threshold = threshold
    }
    
    public func evaluate(value: Double) -> Bool {
        switch condition {
        case .greaterThan:
            return value > threshold
        case .lessThan:
            return value < threshold
        case .equals:
            return abs(value - threshold) < 0.01
        case .greaterThanOrEqual:
            return value >= threshold
        case .lessThanOrEqual:
            return value <= threshold
        }
    }
}

public enum TriggerCondition: String, Codable, CaseIterable {
    case greaterThan = ">"
    case lessThan = "<"
    case equals = "="
    case greaterThanOrEqual = ">="
    case lessThanOrEqual = "<="
}

public enum AutomationAction: Codable {
    case adjustLighting(brightness: Double, color: UIColor?)
    case adjustTemperature(temperature: Double)
    case playSound(soundType: SoundType)
    case sendNotification(message: String)
    case custom(action: String)
    
    public var description: String {
        switch self {
        case .adjustLighting:
            return "Adjust Lighting"
        case .adjustTemperature:
            return "Adjust Temperature"
        case .playSound:
            return "Play Sound"
        case .sendNotification:
            return "Send Notification"
        case .custom:
            return "Custom Action"
        }
    }
}

public enum SoundType: String, Codable, CaseIterable {
    case relaxation = "Relaxation"
    case alert = "Alert"
    case motivation = "Motivation"
}

public enum SmartHomeError: Error {
    case noHomeSelected
    case deviceNotFound
    case characteristicNotFound
    case operationFailed
    case notAuthorized
} 
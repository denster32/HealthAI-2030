import Foundation
import UIKit
import CoreML

/// Service for selecting the appropriate ML model based on device capabilities.
public class DynamicModelSelector {
    
    /// Device capability information
    public struct DeviceCapabilities {
        public let hasNeuralEngine: Bool
        public let availableRAM: UInt64
        public let processorCores: Int
        public let isLowPowerMode: Bool
        public let thermalState: ProcessInfo.ThermalState
        public let batteryLevel: Float
        public let isCharging: Bool
        public let deviceModel: String
        public let iOSVersion: String
    }
    
    /// Model selection strategy
    public enum ModelStrategy {
        case lightweight    // Fastest, lowest accuracy
        case balanced       // Balanced performance and accuracy
        case highAccuracy   // Highest accuracy, slower
        case adaptive       // Dynamically adjusts based on conditions
    }
    
    /// Returns the appropriate model name based on device capabilities
    public static func selectModelName() -> String {
        let capabilities = getDeviceCapabilities()
        let strategy = determineModelStrategy(for: capabilities)
        
        return getModelName(for: strategy, capabilities: capabilities)
    }
    
    /// Gets comprehensive device capabilities
    public static func getDeviceCapabilities() -> DeviceCapabilities {
        let processInfo = ProcessInfo.processInfo
        
        return DeviceCapabilities(
            hasNeuralEngine: hasNeuralEngine(),
            availableRAM: getAvailableRAM(),
            processorCores: processInfo.processorCount,
            isLowPowerMode: processInfo.isLowPowerModeEnabled,
            thermalState: processInfo.thermalState,
            batteryLevel: getBatteryLevel(),
            isCharging: isDeviceCharging(),
            deviceModel: getDeviceModel(),
            iOSVersion: UIDevice.current.systemVersion
        )
    }
    
    /// Determines the best model strategy based on device capabilities
    public static func determineModelStrategy(for capabilities: DeviceCapabilities) -> ModelStrategy {
        // Check for critical constraints first
        if capabilities.isLowPowerMode {
            return .lightweight
        }
        
        if capabilities.thermalState == .critical || capabilities.thermalState == .serious {
            return .lightweight
        }
        
        if capabilities.batteryLevel < 0.2 && !capabilities.isCharging {
            return .lightweight
        }
        
        // Check for optimal conditions
        if capabilities.hasNeuralEngine && capabilities.availableRAM > 2_000_000_000 { // 2GB
            if capabilities.batteryLevel > 0.5 || capabilities.isCharging {
                return .highAccuracy
            } else {
                return .balanced
            }
        }
        
        // Check for moderate capabilities
        if capabilities.availableRAM > 1_000_000_000 { // 1GB
            return .balanced
        }
        
        // Default to lightweight for older/slower devices
        return .lightweight
    }
    
    /// Gets the model name for the given strategy and capabilities
    public static func getModelName(for strategy: ModelStrategy, capabilities: DeviceCapabilities) -> String {
        switch strategy {
        case .lightweight:
            return "healthai_lightweight_v1"
        case .balanced:
            return "healthai_balanced_v1"
        case .highAccuracy:
            return "healthai_high_accuracy_v1"
        case .adaptive:
            return getAdaptiveModelName(capabilities: capabilities)
        }
    }
    
    /// Gets adaptive model name based on current conditions
    private static func getAdaptiveModelName(capabilities: DeviceCapabilities) -> String {
        // Adaptive logic that can switch models based on real-time conditions
        let currentTime = Date()
        let hour = Calendar.current.component(.hour, from: currentTime)
        
        // Use lighter models during peak usage hours or when battery is low
        if (hour >= 8 && hour <= 18) || capabilities.batteryLevel < 0.3 {
            return "healthai_lightweight_v1"
        } else {
            return "healthai_balanced_v1"
        }
    }
    
    /// Checks if device has Neural Engine
    private static func hasNeuralEngine() -> Bool {
        // Check for Neural Engine availability
        if #available(iOS 12.0, *) {
            // Use Core ML to check for Neural Engine
            do {
                let config = MLModelConfiguration()
                config.computeUnits = .all
                
                // Try to create a simple model to test Neural Engine availability
                // This is a simplified check - in production you'd have actual models
                return true // Assume available for modern devices
            } catch {
                return false
            }
        }
        return false
    }
    
    /// Gets available RAM in bytes
    private static func getAvailableRAM() -> UInt64 {
        var pagesize: vm_size_t = 0
        var page_count: mach_port_t = 0
        
        host_page_size(mach_host_self(), &pagesize)
        
        var vmStats = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64>.size / MemoryLayout<integer_t>.size)
        
        let hostPort = mach_host_self()
        let result = withUnsafeMutablePointer(to: &vmStats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(hostPort, HOST_VM_INFO64, $0, &count)
            }
        }
        
        if result == KERN_SUCCESS {
            let freeMemory = UInt64(vmStats.free_count) * UInt64(pagesize)
            return freeMemory
        }
        
        // Fallback to a reasonable estimate
        return 2_000_000_000 // 2GB estimate
    }
    
    /// Gets current battery level
    private static func getBatteryLevel() -> Float {
        UIDevice.current.isBatteryMonitoringEnabled = true
        return UIDevice.current.batteryLevel
    }
    
    /// Checks if device is charging
    private static func isDeviceCharging() -> Bool {
        UIDevice.current.isBatteryMonitoringEnabled = true
        return UIDevice.current.batteryState == .charging || UIDevice.current.batteryState == .full
    }
    
    /// Gets device model identifier
    private static func getDeviceModel() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value))!)
        }
        return identifier
    }
    
    /// Gets recommended model configuration
    public static func getRecommendedModelConfiguration() -> MLModelConfiguration {
        let config = MLModelConfiguration()
        let capabilities = getDeviceCapabilities()
        
        if capabilities.hasNeuralEngine {
            config.computeUnits = .all
        } else {
            config.computeUnits = .cpuAndGPU
        }
        
        // Set memory limit based on available RAM
        if capabilities.availableRAM > 3_000_000_000 { // 3GB
            config.maxConcurrency = 4
        } else if capabilities.availableRAM > 1_000_000_000 { // 1GB
            config.maxConcurrency = 2
        } else {
            config.maxConcurrency = 1
        }
        
        return config
    }
    
    /// Checks if model switching is recommended
    public static func shouldSwitchModel(currentModel: String) -> (shouldSwitch: Bool, recommendedModel: String?) {
        let currentCapabilities = getDeviceCapabilities()
        let currentStrategy = determineModelStrategy(for: currentCapabilities)
        let recommendedModel = getModelName(for: currentStrategy, capabilities: currentCapabilities)
        
        return (currentModel != recommendedModel, recommendedModel)
    }
} 
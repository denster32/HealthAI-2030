import SwiftUI
import HealthKit

// DeviceCapabilityDetector.swift
class DeviceCapabilityDetector {
    static var hasHaptics: Bool {
        #if os(watchOS) || os(iOS)
        return CHHapticEngine.capabilitiesForHardware().supportsHaptics
        #else
        return false
        #endif
    }

    // Add other capability detectors
}
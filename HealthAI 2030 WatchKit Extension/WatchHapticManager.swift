import WatchKit
import Foundation

class WatchHapticManager {
    static let shared = WatchHapticManager()
    
    private let device = WKInterfaceDevice.current()
    private var hapticTimer: Timer?
    
    private init() {}
    
    // MARK: - Haptic Types
    
    enum HapticType: String, CaseIterable {
        case gentleWake = "gentleWake"
        case sleepIntervention = "sleepIntervention"
        case healthAlert = "healthAlert"
        case sessionStart = "sessionStart"
        case sessionEnd = "sessionEnd"
        case achievement = "achievement"
        case reminder = "reminder"
    }
    
    // MARK: - Public Interface
    
    func triggerHaptic(type: String) {
        guard let hapticType = HapticType(rawValue: type) else {
            print("Unknown haptic type: \(type)")
            return
        }
        
        triggerHaptic(type: hapticType)
    }
    
    func triggerHaptic(type: HapticType) {
        switch type {
        case .gentleWake:
            triggerGentleWakeHaptic()
        case .sleepIntervention:
            triggerSleepInterventionHaptic()
        case .healthAlert:
            triggerHealthAlertHaptic()
        case .sessionStart:
            triggerSessionStartHaptic()
        case .sessionEnd:
            triggerSessionEndHaptic()
        case .achievement:
            triggerAchievementHaptic()
        case .reminder:
            triggerReminderHaptic()
        }
    }
    
    // MARK: - Specific Haptic Patterns
    
    private func triggerGentleWakeHaptic() {
        // Gentle wake pattern: soft notification followed by gentle taps
        device.play(.notification)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.device.play(.click)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.device.play(.click)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.device.play(.click)
        }
    }
    
    private func triggerSleepInterventionHaptic() {
        // Sleep intervention pattern: very gentle, rhythmic taps
        device.play(.click)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.device.play(.click)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            self.device.play(.click)
        }
    }
    
    private func triggerHealthAlertHaptic() {
        // Health alert pattern: attention-grabbing but not jarring
        device.play(.notification)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.device.play(.notification)
        }
    }
    
    private func triggerSessionStartHaptic() {
        // Session start pattern: positive, encouraging
        device.play(.success)
    }
    
    private func triggerSessionEndHaptic() {
        // Session end pattern: completion, satisfaction
        device.play(.success)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.device.play(.click)
        }
    }
    
    private func triggerAchievementHaptic() {
        // Achievement pattern: celebratory
        device.play(.success)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.device.play(.success)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            self.device.play(.success)
        }
    }
    
    private func triggerReminderHaptic() {
        // Reminder pattern: gentle notification
        device.play(.click)
    }
    
    // MARK: - Advanced Haptic Patterns
    
    func triggerProgressiveWakeHaptic() {
        // Progressive wake pattern: gradually increasing intensity
        var intensity = 0.1
        
        hapticTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            
            if intensity <= 1.0 {
                self.device.play(.notification)
                intensity += 0.1
            } else {
                timer.invalidate()
                self.hapticTimer = nil
            }
        }
    }
    
    func triggerSleepStageTransitionHaptic(stage: SleepStage) {
        // Different haptic patterns for different sleep stage transitions
        switch stage {
        case .awake:
            device.play(.click)
        case .lightSleep:
            device.play(.click)
        case .deepSleep:
            // No haptic for deep sleep to avoid disturbance
            break
        case .remSleep:
            device.play(.click)
        case .unknown:
            break
        }
    }
    
    func triggerHeartRateAlertHaptic(heartRate: Double) {
        // Haptic feedback based on heart rate levels
        if heartRate > 100 {
            // High heart rate alert
            device.play(.notification)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.device.play(.notification)
            }
        } else if heartRate < 50 {
            // Low heart rate alert
            device.play(.notification)
        }
    }
    
    func triggerHRVCoherenceHaptic(coherence: Double) {
        // Haptic feedback for HRV coherence levels
        if coherence > 0.8 {
            // High coherence - positive feedback
            device.play(.success)
        } else if coherence < 0.3 {
            // Low coherence - gentle reminder
            device.play(.click)
        }
    }
    
    // MARK: - Custom Haptic Sequences
    
    func triggerCustomHapticSequence(_ sequence: [HapticType], interval: TimeInterval = 0.5) {
        for (index, hapticType) in sequence.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + interval * Double(index)) {
                self.triggerHaptic(type: hapticType)
            }
        }
    }
    
    func triggerRhythmicHaptic(pattern: [TimeInterval], duration: TimeInterval = 10.0) {
        let startTime = Date()
        
        hapticTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            
            let elapsed = Date().timeIntervalSince(startTime)
            
            if elapsed >= duration {
                timer.invalidate()
                self.hapticTimer = nil
                return
            }
            
            // Check if it's time for a haptic based on the pattern
            for interval in pattern {
                if abs(elapsed.truncatingRemainder(dividingBy: interval)) < 0.1 {
                    self.device.play(.click)
                    break
                }
            }
        }
    }
    
    // MARK: - Utility Methods
    
    func stopAllHaptics() {
        hapticTimer?.invalidate()
        hapticTimer = nil
    }
    
    func isHapticSupported() -> Bool {
        return device.isHapticSupported
    }
    
    func getHapticCapabilities() -> [String: Any] {
        return [
            "isSupported": device.isHapticSupported,
            "availableTypes": HapticType.allCases.map { $0.rawValue }
        ]
    }
} 
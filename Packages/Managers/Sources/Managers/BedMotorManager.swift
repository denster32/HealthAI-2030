import Foundation
import Combine

class BedMotorManager: ObservableObject {
    static let shared = BedMotorManager()

    // MARK: - Published Properties
    @Published var headElevation: Double = 0.0 // 0.0 to 1.0
    @Published var footElevation: Double = 0.0 // 0.0 to 1.0
    @Published var isMassaging: Bool = false
    @Published var massageIntensity: Double = 0.0 // 0.0 to 1.0
    @Published var isMoving: Bool = false
    @Published var lastError: BedMotorError?
    @Published var connectionStatus: ConnectionStatus = .disconnected
    
    // MARK: - Computed Properties
    var currentHeadElevation: Double {
        return headElevation
    }
    
    var currentFootElevation: Double {
        return footElevation
    }
    
    // MARK: - Private Properties
    private var positionHistory: [BedPosition] = []
    private var movementTimer: Timer?
    private let maxHistorySize = 100

    // MARK: - Initialization
    private init() {
        // Simulate connection to bed motor hardware
        simulateConnection()
    }
    
    // MARK: - Public Interface
    
    /// Adjust head elevation with safety checks
    func adjustHeadElevation(to targetElevation: Double) {
        guard connectionStatus == .connected else {
            handleError(.notConnected)
            return
        }
        
        let clampedElevation = max(0.0, min(1.0, targetElevation))
        
        // Safety check: prevent extreme angles
        if abs(clampedElevation - headElevation) > 0.8 {
            handleError(.unsafeMovement)
            return
        }
        
        print("Adjusting head elevation to: \(clampedElevation * 100)%")
        startMovement()
        
        // Simulate movement time
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.headElevation = clampedElevation
            self.stopMovement()
            self.recordPosition()
        }
    }

    /// Adjust foot elevation with safety checks
    func adjustFootElevation(to targetElevation: Double) {
        guard connectionStatus == .connected else {
            handleError(.notConnected)
            return
        }
        
        let clampedElevation = max(0.0, min(1.0, targetElevation))
        
        // Safety check: prevent extreme angles
        if abs(clampedElevation - footElevation) > 0.8 {
            handleError(.unsafeMovement)
            return
        }
        
        print("Adjusting foot elevation to: \(clampedElevation * 100)%")
        startMovement()
        
        // Simulate movement time
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.footElevation = clampedElevation
            self.stopMovement()
            self.recordPosition()
        }
    }

    /// Start massage with intensity control
    func startMassage(intensity: Double) {
        guard connectionStatus == .connected else {
            handleError(.notConnected)
            return
        }
        
        let clampedIntensity = max(0.0, min(1.0, intensity))
        print("Starting massage with intensity: \(clampedIntensity * 100)%")
        
        self.isMassaging = true
        self.massageIntensity = clampedIntensity
    }

    /// Stop massage
    func stopMassage() {
        print("Stopping massage")
        self.isMassaging = false
        self.massageIntensity = 0.0
    }
    
    // MARK: - Position Presets
    
    /// Set position for deep sleep optimization
    func setDeepSleepPosition() {
        print("Setting deep sleep position")
        adjustHeadElevation(to: 0.05) // Slight elevation
        adjustFootElevation(to: 0.1)  // Slight foot elevation
    }
    
    /// Set position for REM sleep optimization
    func setREMSleepPosition() {
        print("Setting REM sleep position")
        adjustHeadElevation(to: 0.0)  // Flat position
        adjustFootElevation(to: 0.0)  // Flat position
    }
    
    /// Set position for light sleep optimization
    func setLightSleepPosition() {
        print("Setting light sleep position")
        adjustHeadElevation(to: 0.1)  // Moderate elevation
        adjustFootElevation(to: 0.05) // Slight foot elevation
    }
    
    /// Set position for wake-up assistance
    func setWakeUpPosition() {
        print("Setting wake-up position")
        adjustHeadElevation(to: 0.3)  // Higher elevation
        adjustFootElevation(to: 0.0)  // Flat foot position
    }
    
    /// Set position for reading/relaxation
    func setReadingPosition() {
        print("Setting reading position")
        adjustHeadElevation(to: 0.4)  // High elevation
        adjustFootElevation(to: 0.2)  // Moderate foot elevation
    }
    
    // MARK: - Emergency Functions
    
    /// Emergency stop all movements
    func emergencyStop() {
        print("EMERGENCY STOP - Stopping all bed movements")
        stopMovement()
        stopMassage()
        handleError(.emergencyStop)
    }
    
    /// Flat position for safety
    func setFlatPosition() {
        print("Setting flat position for safety")
        adjustHeadElevation(to: 0.0)
        adjustFootElevation(to: 0.0)
    }
    
    // MARK: - Analytics and History
    
    /// Get position history for analytics
    func getPositionHistory() -> [BedPosition] {
        return positionHistory
    }
    
    /// Get current bed position
    func getCurrentPosition() -> BedPosition {
        return BedPosition(
            headElevation: headElevation,
            footElevation: footElevation,
            timestamp: Date()
        )
    }
    
    /// Get bed status summary
    func getStatusSummary() -> BedStatusSummary {
        return BedStatusSummary(
            isConnected: connectionStatus == .connected,
            isMoving: isMoving,
            isMassaging: isMassaging,
            currentPosition: getCurrentPosition(),
            lastError: lastError
        )
    }
    
    // MARK: - Private Helper Methods
    
    private func startMovement() {
        isMoving = true
        lastError = nil
        
        // Set a timer to prevent infinite movement
        movementTimer?.invalidate()
        movementTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: false) { _ in
            if self.isMoving {
                self.handleError(.movementTimeout)
                self.stopMovement()
            }
        }
    }
    
    private func stopMovement() {
        isMoving = false
        movementTimer?.invalidate()
        movementTimer = nil
    }
    
    private func recordPosition() {
        let position = BedPosition(
            headElevation: headElevation,
            footElevation: footElevation,
            timestamp: Date()
        )
        
        positionHistory.append(position)
        
        // Keep history size manageable
        if positionHistory.count > maxHistorySize {
            positionHistory.removeFirst()
        }
    }
    
    private func handleError(_ error: BedMotorError) {
        lastError = error
        print("BedMotor Error: \(error.description)")
        
        // Auto-recover from some errors
        switch error {
        case .notConnected:
            simulateConnection()
        case .movementTimeout, .unsafeMovement:
            stopMovement()
        case .emergencyStop:
            setFlatPosition()
        }
    }
    
    private func simulateConnection() {
        print("Simulating bed motor connection...")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.connectionStatus = .connected
            print("Bed motor connected successfully")
        }
    }
}

// MARK: - Supporting Types

enum ConnectionStatus {
    case connected
    case connecting
    case disconnected
    case error
}

enum BedMotorError: Error, LocalizedError {
    case notConnected
    case unsafeMovement
    case movementTimeout
    case emergencyStop
    case hardwareFailure
    
    var description: String {
        switch self {
        case .notConnected:
            return "Bed motor not connected"
        case .unsafeMovement:
            return "Unsafe movement detected"
        case .movementTimeout:
            return "Movement timeout - stopping for safety"
        case .emergencyStop:
            return "Emergency stop activated"
        case .hardwareFailure:
            return "Hardware failure detected"
        }
    }
    
    var errorDescription: String? {
        return description
    }
}

struct BedPosition: Codable {
    let headElevation: Double
    let footElevation: Double
    let timestamp: Date
}

struct BedStatusSummary {
    let isConnected: Bool
    let isMoving: Bool
    let isMassaging: Bool
    let currentPosition: BedPosition
    let lastError: BedMotorError?
}
import WatchKit
import Foundation
import SwiftUI

class InterfaceController: WKInterfaceController {
    
    // MARK: - Outlets
    @IBOutlet weak var heartRateLabel: WKInterfaceLabel!
    @IBOutlet weak var hrvLabel: WKInterfaceLabel!
    @IBOutlet weak var sleepStageLabel: WKInterfaceLabel!
    @IBOutlet weak var sessionButton: WKInterfaceButton!
    @IBOutlet weak var statusLabel: WKInterfaceLabel!
    @IBOutlet weak var batteryLabel: WKInterfaceLabel!
    
    // MARK: - Properties
    private let sessionManager = WatchSessionManager.shared
    private let hapticManager = WatchHapticManager.shared
    private var updateTimer: Timer?
    
    // MARK: - Lifecycle
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        setupUI()
        setupObservers()
        startUpdateTimer()
        
        print("InterfaceController awakened")
    }
    
    override func willActivate() {
        super.willActivate()
        
        updateUI()
        sessionManager.startHealthMonitoring()
        
        print("InterfaceController will activate")
    }
    
    override func didDeactivate() {
        super.didDeactivate()
        
        sessionManager.stopHealthMonitoring()
        stopUpdateTimer()
        
        print("InterfaceController did deactivate")
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        // Configure initial UI state
        sessionButton.setTitle("Start Sleep Session")
        statusLabel.setText("Ready")
        updateBatteryLevel()
    }
    
    private func setupObservers() {
        // Observe session manager changes
        sessionManager.$currentHeartRate
            .receive(on: DispatchQueue.main)
            .sink { [weak self] heartRate in
                self?.updateHeartRateDisplay(heartRate)
            }
            .store(in: &cancellables)
        
        sessionManager.$currentHRV
            .receive(on: DispatchQueue.main)
            .sink { [weak self] hrv in
                self?.updateHRVDisplay(hrv)
            }
            .store(in: &cancellables)
        
        sessionManager.$currentSleepStage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] stage in
                self?.updateSleepStageDisplay(stage)
            }
            .store(in: &cancellables)
        
        sessionManager.$isSleepSessionActive
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isActive in
                self?.updateSessionButton(isActive)
            }
            .store(in: &cancellables)
        
        sessionManager.$isMonitoring
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isMonitoring in
                self?.updateStatusDisplay(isMonitoring)
            }
            .store(in: &cancellables)
    }
    
    private func startUpdateTimer() {
        updateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateUI()
        }
    }
    
    private func stopUpdateTimer() {
        updateTimer?.invalidate()
        updateTimer = nil
    }
    
    // MARK: - UI Updates
    
    private func updateUI() {
        updateHeartRateDisplay(sessionManager.currentHeartRate)
        updateHRVDisplay(sessionManager.currentHRV)
        updateSleepStageDisplay(sessionManager.currentSleepStage)
        updateSessionButton(sessionManager.isSleepSessionActive)
        updateStatusDisplay(sessionManager.isMonitoring)
        updateBatteryLevel()
    }
    
    private func updateHeartRateDisplay(_ heartRate: Double) {
        let heartRateText = heartRate > 0 ? "\(Int(heartRate)) BPM" : "--- BPM"
        heartRateLabel.setText(heartRateText)
        
        // Color coding based on heart rate
        if heartRate > 100 {
            heartRateLabel.setTextColor(.red)
        } else if heartRate > 80 {
            heartRateLabel.setTextColor(.orange)
        } else if heartRate > 60 {
            heartRateLabel.setTextColor(.green)
        } else {
            heartRateLabel.setTextColor(.blue)
        }
    }
    
    private func updateHRVDisplay(_ hrv: Double) {
        let hrvText = hrv > 0 ? String(format: "%.1f ms", hrv) : "--- ms"
        hrvLabel.setText(hrvText)
        
        // Color coding based on HRV
        if hrv > 50 {
            hrvLabel.setTextColor(.green)
        } else if hrv > 30 {
            hrvLabel.setTextColor(.yellow)
        } else {
            hrvLabel.setTextColor(.red)
        }
    }
    
    private func updateSleepStageDisplay(_ stage: SleepStage) {
        let stageText: String
        let stageColor: UIColor
        
        switch stage {
        case .awake:
            stageText = "Awake"
            stageColor = .systemBlue
        case .lightSleep:
            stageText = "Light Sleep"
            stageColor = .systemYellow
        case .deepSleep:
            stageText = "Deep Sleep"
            stageColor = .systemPurple
        case .remSleep:
            stageText = "REM Sleep"
            stageColor = .systemGreen
        case .unknown:
            stageText = "Unknown"
            stageColor = .systemGray
        }
        
        sleepStageLabel.setText(stageText)
        sleepStageLabel.setTextColor(stageColor)
    }
    
    private func updateSessionButton(_ isActive: Bool) {
        if isActive {
            sessionButton.setTitle("Stop Session")
            sessionButton.setBackgroundColor(.red)
        } else {
            sessionButton.setTitle("Start Sleep Session")
            sessionButton.setBackgroundColor(.green)
        }
    }
    
    private func updateStatusDisplay(_ isMonitoring: Bool) {
        let statusText = isMonitoring ? "Monitoring" : "Ready"
        statusLabel.setText(statusText)
        
        if isMonitoring {
            statusLabel.setTextColor(.green)
        } else {
            statusLabel.setTextColor(.gray)
        }
    }
    
    private func updateBatteryLevel() {
        let batteryLevel = WKInterfaceDevice.current().batteryLevel
        let batteryText = String(format: "%.0f%%", batteryLevel * 100)
        batteryLabel.setText(batteryText)
        
        // Color coding based on battery level
        if batteryLevel < 0.2 {
            batteryLabel.setTextColor(.red)
        } else if batteryLevel < 0.5 {
            batteryLabel.setTextColor(.orange)
        } else {
            batteryLabel.setTextColor(.green)
        }
    }
    
    // MARK: - Actions
    
    @IBAction func sessionButtonTapped() {
        if sessionManager.isSleepSessionActive {
            stopSleepSession()
        } else {
            startSleepSession()
        }
    }
    
    private func startSleepSession() {
        sessionManager.startSleepSession()
        hapticManager.triggerHaptic(type: .sessionStart)
        
        // Show confirmation
        WKInterfaceDevice.current().play(.success)
        
        // Present session interface
        presentController(withName: "SleepSessionInterfaceController", context: nil)
    }
    
    private func stopSleepSession() {
        sessionManager.stopSleepSession()
        hapticManager.triggerHaptic(type: .sessionEnd)
        
        // Show confirmation
        WKInterfaceDevice.current().play(.success)
        
        // Dismiss session interface if needed
        dismiss()
    }
    
    // MARK: - Menu Actions
    
    override func contextForSegue(withIdentifier segueIdentifier: String) -> Any? {
        switch segueIdentifier {
        case "showHealthDetails":
            return sessionManager.getCurrentHealthStatus()
        case "showSleepSession":
            return nil
        default:
            return nil
        }
    }
    
    // MARK: - Health Alerts
    
    func showHealthAlert(_ alert: HealthAlert) {
        // Present health alert
        let alertAction = WKAlertAction(title: "OK", style: .default) {
            // Handle alert dismissal
        }
        
        presentAlert(withTitle: alert.title, message: alert.message, preferredStyle: .alert, actions: [alertAction])
        
        // Trigger appropriate haptic
        hapticManager.triggerHaptic(type: .healthAlert)
    }
    
    // MARK: - Utility Methods
    
    private var cancellables = Set<AnyCancellable>()
    
    deinit {
        cancellables.removeAll()
    }
}

// MARK: - Supporting Types

struct HealthAlert {
    let title: String
    let message: String
    let severity: AlertSeverity
}

enum AlertSeverity {
    case low
    case medium
    case high
    case critical
} 
import WatchKit
import HealthKit
import WatchConnectivity

class ExtensionDelegate: NSObject, WKExtensionDelegate, WCSessionDelegate {
    
    // MARK: - Properties
    private let healthStore = HKHealthStore()
    private let sessionManager = WatchSessionManager.shared
    private let hapticManager = WatchHapticManager.shared
    
    // Background task management
    private var backgroundTaskID: WKRefreshBackgroundTask?
    
    // MARK: - WKExtensionDelegate
    
    func applicationDidFinishLaunching() {
        print("WatchKit Extension launched")
        setupHealthKit()
        setupWatchConnectivity()
        setupBackgroundTasks()
    }
    
    func applicationDidBecomeActive() {
        print("WatchKit Extension became active")
        sessionManager.startHealthMonitoring()
    }
    
    func applicationWillResignActive() {
        print("WatchKit Extension will resign active")
        sessionManager.stopHealthMonitoring()
    }
    
    func handle(_ backgroundTasks: Set<WKRefreshBackgroundTask>) {
        for task in backgroundTasks {
            switch task {
            case let healthTask as WKApplicationRefreshBackgroundTask:
                handleHealthBackgroundTask(healthTask)
            case let snapshotTask as WKSnapshotRefreshBackgroundTask:
                handleSnapshotBackgroundTask(snapshotTask)
            case let connectivityTask as WKConnectivityRefreshBackgroundTask:
                handleConnectivityBackgroundTask(connectivityTask)
            case let urlSessionTask as WKURLSessionRefreshBackgroundTask:
                handleURLSessionBackgroundTask(urlSessionTask)
            default:
                task.setTaskCompletedWithSnapshot(false)
            }
        }
    }
    
    // MARK: - Setup Methods
    
    private func setupHealthKit() {
        guard HKHealthStore.isHealthDataAvailable() else {
            print("HealthKit not available on Watch")
            return
        }
        
        let dataTypes: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!,
            HKObjectType.quantityType(forIdentifier: .oxygenSaturation)!,
            HKObjectType.quantityType(forIdentifier: .bodyTemperature)!,
            HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
        ]
        
        healthStore.requestAuthorization(toShare: nil, read: dataTypes) { success, error in
            if success {
                print("HealthKit authorization granted on Watch")
                self.sessionManager.setupHealthKitObservers()
            } else {
                print("HealthKit authorization failed on Watch: \(error?.localizedDescription ?? "Unknown error")")
            }
        }
    }
    
    private func setupWatchConnectivity() {
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
            print("WatchConnectivity session activated")
        }
    }
    
    private func setupBackgroundTasks() {
        // Schedule background health monitoring
        WKExtension.shared().scheduleBackgroundRefresh(
            withPreferredDate: Date().addingTimeInterval(300), // 5 minutes
            userInfo: nil
        ) { error in
            if let error = error {
                print("Failed to schedule background refresh: \(error)")
            } else {
                print("Background refresh scheduled successfully")
            }
        }
    }
    
    // MARK: - Background Task Handlers
    
    private func handleHealthBackgroundTask(_ task: WKApplicationRefreshBackgroundTask) {
        print("Handling health background task")
        
        // Perform health monitoring
        sessionManager.performBackgroundHealthCheck { [weak self] in
            // Schedule next background refresh
            WKExtension.shared().scheduleBackgroundRefresh(
                withPreferredDate: Date().addingTimeInterval(300),
                userInfo: nil
            ) { _ in }
            
            self?.backgroundTaskID = task
            task.setTaskCompletedWithSnapshot(false)
        }
    }
    
    private func handleSnapshotBackgroundTask(_ task: WKSnapshotRefreshBackgroundTask) {
        print("Handling snapshot background task")
        task.setTaskCompletedWithSnapshot(true)
    }
    
    private func handleConnectivityBackgroundTask(_ task: WKConnectivityRefreshBackgroundTask) {
        print("Handling connectivity background task")
        task.setTaskCompletedWithSnapshot(false)
    }
    
    private func handleURLSessionBackgroundTask(_ task: WKURLSessionRefreshBackgroundTask) {
        print("Handling URL session background task")
        task.setTaskCompletedWithSnapshot(false)
    }
    
    // MARK: - WCSessionDelegate
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            print("WatchConnectivity activation failed: \(error)")
        } else {
            print("WatchConnectivity activated with state: \(activationState.rawValue)")
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        print("Received message from iPhone: \(message)")
        
        DispatchQueue.main.async {
            if let command = message["command"] as? String {
                self.handleCommand(command, data: message)
            }
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        print("Received message with reply from iPhone: \(message)")
        
        DispatchQueue.main.async {
            if let command = message["command"] as? String {
                let response = self.handleCommandWithResponse(command, data: message)
                replyHandler(response)
            } else {
                replyHandler(["status": "error", "message": "Unknown command"])
            }
        }
    }
    
    // MARK: - Command Handling
    
    private func handleCommand(_ command: String, data: [String: Any]) {
        switch command {
        case "startSleepSession":
            sessionManager.startSleepSession()
        case "stopSleepSession":
            sessionManager.stopSleepSession()
        case "triggerHaptic":
            if let hapticType = data["hapticType"] as? String {
                hapticManager.triggerHaptic(type: hapticType)
            }
        case "updateAudioSettings":
            if let volume = data["volume"] as? Float {
                sessionManager.updateAudioVolume(volume)
            }
        default:
            print("Unknown command: \(command)")
        }
    }
    
    private func handleCommandWithResponse(_ command: String, data: [String: Any]) -> [String: Any] {
        switch command {
        case "getHealthStatus":
            return sessionManager.getCurrentHealthStatus()
        case "getSleepStage":
            return sessionManager.getCurrentSleepStage()
        case "getBatteryLevel":
            return ["batteryLevel": WKInterfaceDevice.current().batteryLevel]
        default:
            return ["status": "error", "message": "Unknown command"]
        }
    }
} 
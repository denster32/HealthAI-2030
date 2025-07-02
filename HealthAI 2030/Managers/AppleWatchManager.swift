import Foundation
import WatchConnectivity
import HealthKit

class AppleWatchManager: NSObject, ObservableObject {
    static let shared = AppleWatchManager()
    
    // MARK: - Properties
    private let session = WCSession.default
    private var messageQueue: [WatchMessage] = []
    private var isReachable = false
    
    // Published properties for SwiftUI
    @Published var watchConnectionStatus: WatchConnectionStatus = .disconnected
    @Published var watchHealthData: WatchHealthData = WatchHealthData()
    @Published var watchSleepSession: WatchSleepSession?
    @Published var lastMessageReceived: Date?
    @Published var messageCount: Int = 0
    
    // Message handlers
    private var messageHandlers: [String: (WatchMessage) -> Void] = [:]
    
    // Health data integration
    private let healthDataManager = HealthDataManager.shared
    
    private override init() {
        super.init()
        setupSession()
        setupMessageHandlers()
    }
    
    // MARK: - Setup
    
    private func setupSession() {
        if WCSession.isSupported() {
            session.delegate = self
            session.activate()
            print("AppleWatchManager: WatchConnectivity session activated")
        } else {
            print("AppleWatchManager: WatchConnectivity not supported")
        }
    }
    
    private func setupMessageHandlers() {
        // Register message handlers
        messageHandlers["healthDataUpdate"] = handleHealthDataUpdate
        messageHandlers["sleepSessionStarted"] = handleSleepSessionStarted
        messageHandlers["sleepSessionEnded"] = handleSleepSessionEnded
        messageHandlers["healthAlert"] = handleHealthAlert
        messageHandlers["syncResponse"] = handleSyncResponse
        messageHandlers["watchStatus"] = handleWatchStatus
    }
    
    // MARK: - Message Sending
    
    func sendMessageToWatch(_ message: WatchMessage) {
        guard session.isReachable else {
            // Queue message for later
            messageQueue.append(message)
            print("AppleWatchManager: Watch not reachable, queuing message: \(message.command)")
            return
        }
        
        let messageDict = message.toDictionary()
        
        session.sendMessage(messageDict, replyHandler: { [weak self] reply in
            DispatchQueue.main.async {
                self?.handleMessageReply(reply, for: message)
            }
        }) { [weak self] error in
            DispatchQueue.main.async {
                self?.handleMessageError(error, for: message)
            }
        }
    }
    
    func sendMessageToWatchWithoutReply(_ message: WatchMessage) {
        guard session.isReachable else {
            messageQueue.append(message)
            return
        }
        
        let messageDict = message.toDictionary()
        session.sendMessage(messageDict, replyHandler: nil) { [weak self] error in
            DispatchQueue.main.async {
                self?.handleMessageError(error, for: message)
            }
        }
    }
    
    func sendUserInfoToWatch(_ message: WatchMessage) {
        let messageDict = message.toDictionary()
        session.transferUserInfo(messageDict)
    }
    
    func updateWatchApplicationContext(_ message: WatchMessage) {
        let messageDict = message.toDictionary()
        
        do {
            try session.updateApplicationContext(messageDict)
        } catch {
            print("AppleWatchManager: Failed to update application context: \(error)")
        }
    }
    
    // MARK: - Watch Commands
    
    func startWatchSleepSession() {
        let message = WatchMessage(
            command: "startSleepSession",
            data: [:],
            source: "iphone"
        )
        sendMessageToWatch(message)
    }
    
    func stopWatchSleepSession() {
        let message = WatchMessage(
            command: "stopSleepSession",
            data: [:],
            source: "iphone"
        )
        sendMessageToWatch(message)
    }
    
    func triggerWatchHaptic(type: String) {
        let message = WatchMessage(
            command: "triggerHaptic",
            data: ["hapticType": type],
            source: "iphone"
        )
        sendMessageToWatch(message)
    }
    
    func updateWatchAudioSettings(volume: Float, audioType: String) {
        let message = WatchMessage(
            command: "updateAudioSettings",
            data: [
                "volume": volume,
                "audioType": audioType
            ],
            source: "iphone"
        )
        sendMessageToWatch(message)
    }
    
    func requestWatchHealthStatus() {
        let message = WatchMessage(
            command: "getHealthStatus",
            data: [:],
            source: "iphone"
        )
        sendMessageToWatch(message)
    }
    
    func requestWatchSleepStage() {
        let message = WatchMessage(
            command: "getSleepStage",
            data: [:],
            source: "iphone"
        )
        sendMessageToWatch(message)
    }
    
    func syncWithWatch() {
        let message = WatchMessage(
            command: "syncRequest",
            data: [:],
            source: "iphone"
        )
        sendMessageToWatch(message)
    }
    
    // MARK: - Message Handling
    
    private func handleHealthDataUpdate(_ message: WatchMessage) {
        guard let heartRate = message.data["heartRate"] as? Double,
              let hrv = message.data["hrv"] as? Double,
              let sleepStage = message.data["sleepStage"] as? String,
              let timestamp = message.data["timestamp"] as? TimeInterval else {
            print("AppleWatchManager: Invalid health data update message")
            return
        }
        
        DispatchQueue.main.async {
            self.watchHealthData = WatchHealthData(
                heartRate: heartRate,
                hrv: hrv,
                sleepStage: sleepStage,
                timestamp: Date(timeIntervalSince1970: timestamp)
            )
            
            // Integrate with HealthDataManager
            self.healthDataManager.updateWatchHealthData(self.watchHealthData)
            
            print("AppleWatchManager: Updated watch health data - HR: \(heartRate), HRV: \(hrv), Stage: \(sleepStage)")
        }
    }
    
    private func handleSleepSessionStarted(_ message: WatchMessage) {
        DispatchQueue.main.async {
            self.watchSleepSession = WatchSleepSession(
                startTime: Date(),
                isActive: true
            )
            
            print("AppleWatchManager: Watch sleep session started")
        }
    }
    
    private func handleSleepSessionEnded(_ message: WatchMessage) {
        guard let duration = message.data["duration"] as? TimeInterval,
              let averageHeartRate = message.data["averageHeartRate"] as? Double,
              let averageHRV = message.data["averageHRV"] as? Double,
              let dataPoints = message.data["dataPoints"] as? Int else {
            print("AppleWatchManager: Invalid sleep session ended message")
            return
        }
        
        DispatchQueue.main.async {
            self.watchSleepSession = WatchSleepSession(
                startTime: Date().addingTimeInterval(-duration),
                endTime: Date(),
                duration: duration,
                averageHeartRate: averageHeartRate,
                averageHRV: averageHRV,
                dataPoints: dataPoints,
                isActive: false
            )
            
            // Save sleep session to HealthKit
            self.healthDataManager.saveWatchSleepSession(self.watchSleepSession!)
            
            print("AppleWatchManager: Watch sleep session ended - Duration: \(duration)s, Avg HR: \(averageHeartRate), Avg HRV: \(averageHRV)")
        }
    }
    
    private func handleHealthAlert(_ message: WatchMessage) {
        guard let title = message.data["title"] as? String,
              let alertMessage = message.data["message"] as? String,
              let severity = message.data["severity"] as? String else {
            print("AppleWatchManager: Invalid health alert message")
            return
        }
        
        DispatchQueue.main.async {
            // Handle health alert from Watch
            self.handleWatchHealthAlert(title: title, message: alertMessage, severity: severity)
        }
    }
    
    private func handleSyncResponse(_ message: WatchMessage) {
        // Handle sync response from Watch
        print("AppleWatchManager: Received sync response from Watch")
        
        // Update local data with Watch data
        if let heartRate = message.data["heartRate"] as? Double,
           let hrv = message.data["hrv"] as? Double,
           let sleepStage = message.data["sleepStage"] as? String {
            
            DispatchQueue.main.async {
                self.watchHealthData = WatchHealthData(
                    heartRate: heartRate,
                    hrv: hrv,
                    sleepStage: sleepStage,
                    timestamp: Date()
                )
            }
        }
    }
    
    private func handleWatchStatus(_ message: WatchMessage) {
        // Handle Watch status updates
        print("AppleWatchManager: Received Watch status update")
    }
    
    // MARK: - Reply and Error Handling
    
    private func handleMessageReply(_ reply: [String: Any], for message: WatchMessage) {
        print("AppleWatchManager: Received reply for \(message.command): \(reply)")
        
        if let status = reply["status"] as? String, status == "success" {
            messageCount += 1
        }
    }
    
    private func handleMessageError(_ error: Error, for message: WatchMessage) {
        print("AppleWatchManager: Failed to send message \(message.command): \(error)")
        
        // Retry logic
        if messageQueue.count < 10 {
            messageQueue.append(message)
        }
    }
    
    // MARK: - Queue Management
    
    func processMessageQueue() {
        guard session.isReachable else { return }
        
        let messagesToSend = messageQueue
        messageQueue.removeAll()
        
        for message in messagesToSend {
            sendMessageToWatchWithoutReply(message)
        }
    }
    
    // MARK: - Health Alert Handling
    
    private func handleWatchHealthAlert(title: String, message: String, severity: String) {
        // Create local notification
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = message
        content.sound = .default
        
        // Set notification category based on severity
        switch severity {
        case "critical":
            content.categoryIdentifier = "CRITICAL_HEALTH_ALERT"
            content.interruptionLevel = .critical
        case "high":
            content.categoryIdentifier = "HIGH_HEALTH_ALERT"
            content.interruptionLevel = .timeSensitive
        case "medium":
            content.categoryIdentifier = "MEDIUM_HEALTH_ALERT"
        case "low":
            content.categoryIdentifier = "LOW_HEALTH_ALERT"
        default:
            content.categoryIdentifier = "GENERAL_HEALTH_ALERT"
        }
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("AppleWatchManager: Failed to schedule notification: \(error)")
            }
        }
        
        // Also trigger local alert if app is active
        NotificationCenter.default.post(
            name: .watchHealthAlert,
            object: nil,
            userInfo: [
                "title": title,
                "message": message,
                "severity": severity
            ]
        )
    }
    
    // MARK: - Utility Methods
    
    func getWatchConnectionStatus() -> [String: Any] {
        return [
            "isReachable": session.isReachable,
            "isPaired": session.isPaired,
            "isWatchAppInstalled": session.isWatchAppInstalled,
            "activationState": session.activationState.rawValue,
            "messageCount": messageCount,
            "queueSize": messageQueue.count
        ]
    }
    
    func clearMessageQueue() {
        messageQueue.removeAll()
    }
    
    func isWatchAvailable() -> Bool {
        return session.isPaired && session.isWatchAppInstalled
    }
}

// MARK: - WCSessionDelegate

extension AppleWatchManager: WCSessionDelegate {
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            if let error = error {
                self.watchConnectionStatus = .error
                print("AppleWatchManager: WatchConnectivity activation failed: \(error)")
            } else {
                self.watchConnectionStatus = .connected
                print("AppleWatchManager: WatchConnectivity activated with state: \(activationState.rawValue)")
                self.processMessageQueue()
            }
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        DispatchQueue.main.async {
            self.handleReceivedMessage(message)
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        DispatchQueue.main.async {
            let response = self.handleReceivedMessageWithReply(message)
            replyHandler(response)
        }
    }
    
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        DispatchQueue.main.async {
            self.handleReceivedUserInfo(userInfo)
        }
    }
    
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        DispatchQueue.main.async {
            self.handleReceivedApplicationContext(applicationContext)
        }
    }
    
    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isReachable = session.isReachable
            self.watchConnectionStatus = session.isReachable ? .connected : .disconnected
            
            if session.isReachable {
                self.processMessageQueue()
            }
        }
    }
    
    // MARK: - Message Processing
    
    private func handleReceivedMessage(_ message: [String: Any]) {
        guard let command = message["command"] as? String else {
            print("AppleWatchManager: Received message without command")
            return
        }
        
        let watchMessage = WatchMessage(
            command: command,
            data: message,
            source: message["source"] as? String ?? "unknown"
        )
        
        if let handler = messageHandlers[command] {
            handler(watchMessage)
        } else {
            print("AppleWatchManager: No handler for command: \(command)")
        }
        
        lastMessageReceived = Date()
        messageCount += 1
    }
    
    private func handleReceivedMessageWithReply(_ message: [String: Any]) -> [String: Any] {
        guard let command = message["command"] as? String else {
            return ["status": "error", "message": "No command specified"]
        }
        
        let watchMessage = WatchMessage(
            command: command,
            data: message,
            source: message["source"] as? String ?? "unknown"
        )
        
        // Handle the message
        handleReceivedMessage(message)
        
        // Return appropriate response
        switch command {
        case "getHealthStatus":
            return healthDataManager.getCurrentHealthStatus()
        case "getSleepStage":
            return healthDataManager.getCurrentSleepStage()
        case "getBatteryLevel":
            return ["batteryLevel": UIDevice.current.batteryLevel]
        default:
            return ["status": "success", "message": "Command processed"]
        }
    }
    
    private func handleReceivedUserInfo(_ userInfo: [String: Any]) {
        print("AppleWatchManager: Received user info: \(userInfo)")
        // Handle user info transfer
    }
    
    private func handleReceivedApplicationContext(_ context: [String: Any]) {
        print("AppleWatchManager: Received application context: \(context)")
        // Handle application context update
    }
}

// MARK: - Supporting Types

enum WatchConnectionStatus {
    case disconnected
    case connecting
    case connected
    case error
}

struct WatchHealthData {
    let heartRate: Double
    let hrv: Double
    let sleepStage: String
    let timestamp: Date
}

struct WatchSleepSession {
    let startTime: Date
    var endTime: Date?
    var duration: TimeInterval?
    var averageHeartRate: Double?
    var averageHRV: Double?
    var dataPoints: Int?
    let isActive: Bool
}

struct WatchMessage {
    let command: String
    let data: [String: Any]
    let source: String
    let timestamp: Date
    
    init(command: String, data: [String: Any], source: String) {
        self.command = command
        self.data = data
        self.source = source
        self.timestamp = Date()
    }
    
    func toDictionary() -> [String: Any] {
        var dict = data
        dict["command"] = command
        dict["source"] = source
        dict["timestamp"] = timestamp.timeIntervalSince1970
        return dict
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let watchHealthAlert = Notification.Name("watchHealthAlert")
} 
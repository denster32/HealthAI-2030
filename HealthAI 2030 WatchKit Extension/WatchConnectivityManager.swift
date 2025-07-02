import WatchKit
import WatchConnectivity
import Foundation

class WatchConnectivityManager: NSObject, ObservableObject {
    static let shared = WatchConnectivityManager()
    
    // MARK: - Properties
    private let session = WCSession.default
    private var messageQueue: [WatchMessage] = []
    private var isReachable = false
    
    // Published properties for SwiftUI
    @Published var connectionStatus: ConnectionStatus = .disconnected
    @Published var lastMessageReceived: Date?
    @Published var messageCount: Int = 0
    
    // Message handlers
    private var messageHandlers: [String: (WatchMessage) -> Void] = [:]
    
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
            print("WatchConnectivity session activated")
        } else {
            print("WatchConnectivity not supported")
        }
    }
    
    private func setupMessageHandlers() {
        // Register message handlers
        messageHandlers["healthDataUpdate"] = handleHealthDataUpdate
        messageHandlers["sleepSessionStarted"] = handleSleepSessionStarted
        messageHandlers["sleepSessionEnded"] = handleSleepSessionEnded
        messageHandlers["healthAlert"] = handleHealthAlert
        messageHandlers["audioSettings"] = handleAudioSettings
        messageHandlers["environmentUpdate"] = handleEnvironmentUpdate
        messageHandlers["syncRequest"] = handleSyncRequest
    }
    
    // MARK: - Message Sending
    
    func sendMessage(_ message: WatchMessage) {
        guard session.isReachable else {
            // Queue message for later
            messageQueue.append(message)
            print("iPhone not reachable, queuing message: \(message.command)")
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
    
    func sendMessageWithoutReply(_ message: WatchMessage) {
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
    
    func sendUserInfo(_ message: WatchMessage) {
        let messageDict = message.toDictionary()
        session.transferUserInfo(messageDict)
    }
    
    func updateApplicationContext(_ message: WatchMessage) {
        let messageDict = message.toDictionary()
        
        do {
            try session.updateApplicationContext(messageDict)
        } catch {
            print("Failed to update application context: \(error)")
        }
    }
    
    // MARK: - Message Handling
    
    private func handleHealthDataUpdate(_ message: WatchMessage) {
        guard let heartRate = message.data["heartRate"] as? Double,
              let hrv = message.data["hrv"] as? Double,
              let sleepStage = message.data["sleepStage"] as? String else {
            print("Invalid health data update message")
            return
        }
        
        // Update local health data
        DispatchQueue.main.async {
            // This would update your health data manager
            print("Received health data: HR=\(heartRate), HRV=\(hrv), Stage=\(sleepStage)")
        }
    }
    
    private func handleSleepSessionStarted(_ message: WatchMessage) {
        DispatchQueue.main.async {
            print("Sleep session started on iPhone")
            // Handle sleep session start
        }
    }
    
    private func handleSleepSessionEnded(_ message: WatchMessage) {
        guard let duration = message.data["duration"] as? TimeInterval,
              let averageHeartRate = message.data["averageHeartRate"] as? Double,
              let averageHRV = message.data["averageHRV"] as? Double else {
            print("Invalid sleep session ended message")
            return
        }
        
        DispatchQueue.main.async {
            print("Sleep session ended: \(duration)s, Avg HR: \(averageHeartRate), Avg HRV: \(averageHRV)")
            // Handle sleep session end
        }
    }
    
    private func handleHealthAlert(_ message: WatchMessage) {
        guard let title = message.data["title"] as? String,
              let alertMessage = message.data["message"] as? String,
              let severity = message.data["severity"] as? String else {
            print("Invalid health alert message")
            return
        }
        
        DispatchQueue.main.async {
            // Show health alert on Watch
            self.showHealthAlert(title: title, message: alertMessage, severity: severity)
        }
    }
    
    private func handleAudioSettings(_ message: WatchMessage) {
        guard let volume = message.data["volume"] as? Float,
              let audioType = message.data["audioType"] as? String else {
            print("Invalid audio settings message")
            return
        }
        
        DispatchQueue.main.async {
            print("Audio settings updated: Volume=\(volume), Type=\(audioType)")
            // Update audio settings
        }
    }
    
    private func handleEnvironmentUpdate(_ message: WatchMessage) {
        guard let temperature = message.data["temperature"] as? Double,
              let humidity = message.data["humidity"] as? Double,
              let lightLevel = message.data["lightLevel"] as? Double else {
            print("Invalid environment update message")
            return
        }
        
        DispatchQueue.main.async {
            print("Environment updated: Temp=\(temperature), Humidity=\(humidity), Light=\(lightLevel)")
            // Update environment data
        }
    }
    
    private func handleSyncRequest(_ message: WatchMessage) {
        // Send current health data to iPhone
        let healthData = WatchSessionManager.shared.getCurrentHealthStatus()
        let syncMessage = WatchMessage(
            command: "syncResponse",
            data: healthData,
            source: "watch"
        )
        
        sendMessage(syncMessage)
    }
    
    // MARK: - Reply and Error Handling
    
    private func handleMessageReply(_ reply: [String: Any], for message: WatchMessage) {
        print("Received reply for \(message.command): \(reply)")
        
        if let status = reply["status"] as? String, status == "success" {
            // Message sent successfully
            messageCount += 1
        }
    }
    
    private func handleMessageError(_ error: Error, for message: WatchMessage) {
        print("Failed to send message \(message.command): \(error)")
        
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
            sendMessageWithoutReply(message)
        }
    }
    
    // MARK: - Health Alert Display
    
    private func showHealthAlert(title: String, message: String, severity: String) {
        // Present alert on Watch
        let alertAction = WKAlertAction(title: "OK", style: .default) {
            // Handle alert dismissal
        }
        
        // Get the current interface controller
        if let interfaceController = WKExtension.shared().rootInterfaceController {
            interfaceController.presentAlert(
                withTitle: title,
                message: message,
                preferredStyle: .alert,
                actions: [alertAction]
            )
        }
        
        // Trigger haptic feedback based on severity
        let hapticManager = WatchHapticManager.shared
        switch severity {
        case "critical":
            hapticManager.triggerHaptic(type: .healthAlert)
        case "high":
            hapticManager.triggerHaptic(type: .healthAlert)
        case "medium":
            hapticManager.triggerHaptic(type: .reminder)
        case "low":
            hapticManager.triggerHaptic(type: .reminder)
        default:
            break
        }
    }
    
    // MARK: - Utility Methods
    
    func getConnectionStatus() -> [String: Any] {
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
    
    // MARK: - Public Interface
    
    func sendHealthData(_ data: [String: Any]) {
        sendMessage(WatchMessage(command: "healthData", data: data, source: "watch"))
    }
    
    func sendSleepData(_ data: [String: Any]) {
        sendMessage(WatchMessage(command: "sleepData", data: data, source: "watch"))
    }
    
    func sendAnalyticsData(_ data: [String: Any]) {
        sendMessage(WatchMessage(command: "analyticsData", data: data, source: "watch"))
    }
    
    func requestiPhoneStatus() {
        sendMessage(WatchMessage(command: "statusRequest", data: [:], source: "watch"))
    }
}

// MARK: - WCSessionDelegate

extension WatchConnectivityManager: WCSessionDelegate {
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            if let error = error {
                self.connectionStatus = .error
                print("WatchConnectivity activation failed: \(error)")
            } else {
                self.connectionStatus = .connected
                print("WatchConnectivity activated with state: \(activationState.rawValue)")
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
            self.connectionStatus = session.isReachable ? .connected : .disconnected
            
            if session.isReachable {
                self.processMessageQueue()
            }
        }
    }
    
    // MARK: - Message Processing
    
    private func handleReceivedMessage(_ message: [String: Any]) {
        guard let command = message["command"] as? String else {
            print("Received message without command")
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
            print("No handler for command: \(command)")
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
            return WatchSessionManager.shared.getCurrentHealthStatus()
        case "getSleepStage":
            return WatchSessionManager.shared.getCurrentSleepStage()
        case "getBatteryLevel":
            return ["batteryLevel": WKInterfaceDevice.current().batteryLevel]
        default:
            return ["status": "success", "message": "Command processed"]
        }
    }
    
    private func handleReceivedUserInfo(_ userInfo: [String: Any]) {
        print("Received user info: \(userInfo)")
        // Handle user info transfer
    }
    
    private func handleReceivedApplicationContext(_ context: [String: Any]) {
        print("Received application context: \(context)")
        // Handle application context update
    }
}

// MARK: - Supporting Types

enum ConnectionStatus {
    case disconnected
    case connecting
    case connected
    case error
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
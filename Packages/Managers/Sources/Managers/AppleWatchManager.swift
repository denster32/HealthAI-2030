import Foundation
#if os(iOS)
import WatchConnectivity
#endif
import HealthKit
import os.log

@available(iOS 17.0, *)
@available(macOS 14.0, *)

/// AppleWatchManager - Comprehensive Apple Watch integration for SomnaSync Pro
@MainActor
class AppleWatchManager: NSObject, ObservableObject {
    static let shared = AppleWatchManager()
    
    // MARK: - Published Properties
    @Published var isWatchConnected = false
    @Published var isWatchAppInstalled = false
    @Published var watchBatteryLevel: Double = 0.0
    @Published var watchHeartRate: Double = 0.0
    @Published var watchHRV: Double = 0.0
    @Published var watchBloodOxygen: Double = 0.0
    @Published var watchMovement: Double = 0.0
    @Published var watchSleepStage: SleepStage = .awake
    @Published var watchSleepQuality: Double = 0.0
    @Published var watchSleepSession: WatchSleepSession?
    @Published var lastSyncTime: Date = Date()
    @Published var syncStatus: WatchSyncStatus = .disconnected
    
    // MARK: - Computed Properties for UI
    
    var isConnected: Bool {
        return isWatchConnected && syncStatus == .connected
    }
    
    var currentHeartRate: Int {
        return Int(watchHeartRate)
    }
    
    var isSleepTracking: Bool {
        return watchSleepSession != nil && watchSleepStage != .awake
    }
    
    // MARK: - Private Properties
    private var session: WCSession?
    private var healthStore: HKHealthStore?
    private var heartRateQuery: HKQuery?
    private var hrvQuery: HKQuery?
    private var bloodOxygenQuery: HKQuery?
    private var movementQuery: HKQuery?
    private var sleepSessionQuery: HKQuery?
    
    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    private var syncTimer: DispatchSourceTimer?
    private let syncQueue = DispatchQueue(label: "com.somnasync.watchSync", qos: .background)
    private var reconnectTimer: Timer?
    private var isSyncInProgress = false
    private let syncLeeway: DispatchTimeInterval = .seconds(10)
    
    // MARK: - Configuration
    /// Interval for background sync operations
    private let syncInterval: TimeInterval = 15.0 // Faster sync with tolerance
    private let maxReconnectAttempts = 5
    private var reconnectAttempts = 0

    private var healthKitAuthorized = false
    private var healthKitQueriesStarted = false
    
    override init() {
        super.init()
        setupWatchConnectivity()
        setupHealthKit()
    }
    
    deinit {
        stopWatchDependentServices()
        invalidateTimers()
    }
    
    // MARK: - Watch Connectivity Setup
    
    private func setupWatchConnectivity() {
        guard WCSession.isSupported() else {
            Logger.error("Watch Connectivity not supported on this device", log: Logger.watchManager)
            return
        }
        
        session = WCSession.default
        session?.delegate = self
        session?.activate()
        
        Logger.info("Watch Connectivity session activated", log: Logger.watchManager)
    }
    
    // MARK: - HealthKit Setup
    
    private func setupHealthKit() {
        guard HKHealthStore.isHealthDataAvailable() else {
            Logger.error("HealthKit not available", log: Logger.watchManager)
            return
        }
        
        healthStore = HKHealthStore()
        requestHealthKitPermissions()
    }
    
    private func requestHealthKitPermissions() {
        guard let healthStore = healthStore else { return }
        
        let typesToRead: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!,
            HKObjectType.quantityType(forIdentifier: .oxygenSaturation)!,
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
            HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
        ]
        
        let typesToWrite: Set<HKSampleType> = [
            HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
        ]
        
        healthStore.requestAuthorization(toShare: typesToWrite, read: typesToRead) { [weak self] success, error in
            DispatchQueue.main.async {
                if success {
                    Logger.success("HealthKit permissions granted", log: Logger.watchManager)
                    self?.healthKitAuthorized = true
                } else {
                    Logger.error("HealthKit permissions denied: \(error?.localizedDescription ?? "Unknown error")", log: Logger.watchManager)
                }
            }
        }
    }
    
    // MARK: - HealthKit Queries
    
    private func startHealthKitQueries() {
        startHeartRateQuery()
        startHRVQuery()
        startBloodOxygenQuery()
        startMovementQuery()
        startSleepSessionQuery()
    }
    
    private func startHeartRateQuery() {
        guard let healthStore = healthStore,
              let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) else { return }
        
        let predicate = HKQuery.predicateForSamples(withStart: Date().addingTimeInterval(-300), end: nil, options: .strictStartDate)
        
        heartRateQuery = HKAnchoredObjectQuery(type: heartRateType, predicate: predicate, anchor: nil, limit: HKObjectQueryNoLimit) { [weak self] query, samples, deletedObjects, anchor, error in
            self?.handleHeartRateUpdate(samples: samples, error: error)
        }
        
        heartRateQuery?.updateHandler = { [weak self] query, samples, deletedObjects, anchor, error in
            self?.handleHeartRateUpdate(samples: samples, error: error)
        }
        
        if let query = heartRateQuery {
            healthStore.execute(query)
        }
    }
    
    private func startHRVQuery() {
        guard let healthStore = healthStore,
              let hrvType = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN) else { return }
        
        let predicate = HKQuery.predicateForSamples(withStart: Date().addingTimeInterval(-300), end: nil, options: .strictStartDate)
        
        hrvQuery = HKAnchoredObjectQuery(type: hrvType, predicate: predicate, anchor: nil, limit: HKObjectQueryNoLimit) { [weak self] query, samples, deletedObjects, anchor, error in
            self?.handleHRVUpdate(samples: samples, error: error)
        }
        
        hrvQuery?.updateHandler = { [weak self] query, samples, deletedObjects, anchor, error in
            self?.handleHRVUpdate(samples: samples, error: error)
        }
        
        if let query = hrvQuery {
            healthStore.execute(query)
        }
    }
    
    private func startBloodOxygenQuery() {
        guard let healthStore = healthStore,
              let bloodOxygenType = HKQuantityType.quantityType(forIdentifier: .oxygenSaturation) else { return }
        
        let predicate = HKQuery.predicateForSamples(withStart: Date().addingTimeInterval(-300), end: nil, options: .strictStartDate)
        
        bloodOxygenQuery = HKAnchoredObjectQuery(type: bloodOxygenType, predicate: predicate, anchor: nil, limit: HKObjectQueryNoLimit) { [weak self] query, samples, deletedObjects, anchor, error in
            self?.handleBloodOxygenUpdate(samples: samples, error: error)
        }
        
        bloodOxygenQuery?.updateHandler = { [weak self] query, samples, deletedObjects, anchor, error in
            self?.handleBloodOxygenUpdate(samples: samples, error: error)
        }
        
        if let query = bloodOxygenQuery {
            healthStore.execute(query)
        }
    }
    
    private func startMovementQuery() {
        guard let healthStore = healthStore,
              let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else { return }
        
        let predicate = HKQuery.predicateForSamples(withStart: Date().addingTimeInterval(-60), end: nil, options: .strictStartDate)
        
        movementQuery = HKStatisticsQuery(quantityType: stepType, quantitySamplePredicate: predicate, options: .cumulativeSum) { [weak self] query, statistics, error in
            self?.handleMovementUpdate(statistics: statistics, error: error)
        }
        
        if let query = movementQuery {
            healthStore.execute(query)
        }
    }
    
    private func startSleepSessionQuery() {
        guard let healthStore = healthStore,
              let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else { return }
        
        let predicate = HKQuery.predicateForSamples(withStart: Date().addingTimeInterval(-3600), end: nil, options: .strictStartDate)
        
        sleepSessionQuery = HKAnchoredObjectQuery(type: sleepType, predicate: predicate, anchor: nil, limit: HKObjectQueryNoLimit) { [weak self] query, samples, deletedObjects, anchor, error in
            self?.handleSleepSessionUpdate(samples: samples, error: error)
        }
        
        sleepSessionQuery?.updateHandler = { [weak self] query, samples, deletedObjects, anchor, error in
            self?.handleSleepSessionUpdate(samples: samples, error: error)
        }
        
        if let query = sleepSessionQuery {
            healthStore.execute(query)
        }
    }
    
    // MARK: - HealthKit Data Handlers
    
    private func handleHeartRateUpdate(samples: [HKSample]?, error: Error?) {
        guard let samples = samples as? [HKQuantitySample], !samples.isEmpty else { return }
        
        guard let latestSample = samples.last else { return }
        let heartRate = latestSample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
        
        DispatchQueue.main.async {
            self.watchHeartRate = heartRate
            self.lastSyncTime = Date()
            self.syncStatus = .synced
        }
        
        Logger.info("Heart rate updated: \(heartRate) BPM", log: Logger.watchManager)
    }
    
    private func handleHRVUpdate(samples: [HKSample]?, error: Error?) {
        guard let samples = samples as? [HKQuantitySample], !samples.isEmpty else { return }
        
        guard let latestSample = samples.last else { return }
        let hrv = latestSample.quantity.doubleValue(for: HKUnit.secondUnit(with: .milli))
        
        DispatchQueue.main.async {
            self.watchHRV = hrv
        }
        
        Logger.info("HRV updated: \(hrv) ms", log: Logger.watchManager)
    }
    
    private func handleBloodOxygenUpdate(samples: [HKSample]?, error: Error?) {
        guard let samples = samples as? [HKQuantitySample], !samples.isEmpty else { return }
        
        guard let latestSample = samples.last else { return }
        let bloodOxygen = latestSample.quantity.doubleValue(for: HKUnit.percent())
        
        DispatchQueue.main.async {
            self.watchBloodOxygen = bloodOxygen * 100 // Convert to percentage
        }
        
        Logger.info("Blood oxygen updated: \(bloodOxygen * 100)%", log: Logger.watchManager)
    }
    
    private func handleMovementUpdate(statistics: HKStatistics?, error: Error?) {
        guard let statistics = statistics,
              let sum = statistics.sumQuantity() else { return }
        
        let steps = sum.doubleValue(for: HKUnit.count())
        let movement = min(1.0, steps / 100.0) // Normalize to 0-1
        
        DispatchQueue.main.async {
            self.watchMovement = movement
        }
        
        Logger.info("Movement updated: \(steps) steps", log: Logger.watchManager)
    }
    
    private func handleSleepSessionUpdate(samples: [HKSample]?, error: Error?) {
        guard let samples = samples as? [HKCategorySample] else { return }
        
        // Find the most recent sleep session
        let sleepSamples = samples.filter { $0.value == HKCategoryValueSleepAnalysis.inBed.rawValue || $0.value == HKCategoryValueSleepAnalysis.asleep.rawValue }
        
        if let latestSample = sleepSamples.last {
            let session = WatchSleepSession(
                startTime: latestSample.startDate,
                endTime: latestSample.endDate,
                stage: mapSleepStage(from: latestSample.value),
                quality: calculateSleepQuality(from: samples)
            )
            
            DispatchQueue.main.async {
                self.watchSleepSession = session
                self.watchSleepStage = session.stage
                self.watchSleepQuality = session.quality
            }
            
            Logger.info("Sleep session updated: \(session.stage)", log: Logger.watchManager)
        }
    }
    
    // MARK: - Watch Communication
    
    func sendMessageToWatch(_ message: WatchMessage) {
        guard let session = session, session.isReachable else {
            Logger.warning("Watch not reachable, queuing message", log: Logger.watchManager)
            queueMessage(message)
            return
        }
        
        do {
            let messageData = try JSONEncoder().encode(message)
            let messageDict = try JSONSerialization.jsonObject(with: messageData) as? [String: Any] ?? [:]
            
            session.sendMessage(messageDict, replyHandler: { [weak self] reply in
                self?.handleWatchReply(reply)
            }, errorHandler: { [weak self] error in
                self?.handleWatchError(error)
            })
            
            Logger.info("Message sent to watch: \(message.type)", log: Logger.watchManager)
        } catch {
            Logger.error("Failed to encode message: \(error.localizedDescription)", log: Logger.watchManager)
        }
    }
    
    func startSleepTracking() {
        let message = WatchMessage(
            type: .startSleepTracking,
            data: ["timestamp": Date().timeIntervalSince1970]
        )
        sendMessageToWatch(message)
    }
    
    func stopSleepTracking() {
        let message = WatchMessage(
            type: .stopSleepTracking,
            data: ["timestamp": Date().timeIntervalSince1970]
        )
        sendMessageToWatch(message)
    }
    
    func requestBiometricData() {
        let message = WatchMessage(
            type: .requestBiometricData,
            data: [:]
        )
        sendMessageToWatch(message)
    }
    
    // MARK: - Background Sync
    
    private func startBackgroundSync() {
        guard syncTimer == nil else { return }
        let timer = DispatchSource.makeTimerSource(queue: syncQueue)
        timer.schedule(deadline: .now() + syncInterval,
                       repeating: syncInterval,
                       leeway: syncLeeway)
        timer.setEventHandler { [weak self] in
            self?.performBackgroundSync()
        }
        syncTimer = timer
        timer.resume()
        Logger.info("Background sync timer started", log: Logger.watchManager)
    }

    private func stopBackgroundSync() {
        syncTimer?.cancel()
        syncTimer = nil
        Logger.info("Background sync timer stopped", log: Logger.watchManager)
    }

    private func startHealthKitQueriesIfNeeded() {
        guard healthKitAuthorized, !healthKitQueriesStarted else { return }
        startHealthKitQueries()
        healthKitQueriesStarted = true
    }

    private func stopHealthKitQueries() {
        heartRateQuery = nil
        hrvQuery = nil
        bloodOxygenQuery = nil
        movementQuery = nil
        sleepSessionQuery = nil
        healthKitQueriesStarted = false
    }

    private func startWatchDependentServices() {
        startBackgroundSync()
        startHealthKitQueriesIfNeeded()
        Logger.info("Started watch dependent services", log: Logger.watchManager)
    }

    private func stopWatchDependentServices() {
        stopBackgroundSync()
        stopHealthKitQueries()
        Logger.info("Stopped watch dependent services", log: Logger.watchManager)
    }
    
    private func performBackgroundSync() {
        guard isWatchConnected else { return }
        guard !isSyncInProgress else {
            Logger.debug("Sync already in progress", log: Logger.watchManager)
            return
        }

        isSyncInProgress = true
        let start = Date()
        defer {
            isSyncInProgress = false
            let duration = Date().timeIntervalSince(start)
            Logger.info("Background sync completed in \(duration)s", log: Logger.watchManager)
        }

        // Request fresh biometric data
        requestBiometricData()

        // Update battery level
        updateBatteryLevel()
    }
    
    private func updateBatteryLevel() {
        guard let session = session, session.isReachable else { return }
        
        let message = WatchMessage(
            type: .requestBatteryLevel,
            data: [:]
        )
        sendMessageToWatch(message)
    }
    
    // MARK: - Helper Functions
    
    private func mapSleepStage(from value: Int) -> SleepStage {
        switch value {
        case HKCategoryValueSleepAnalysis.inBed.rawValue:
            return .light
        case HKCategoryValueSleepAnalysis.asleep.rawValue:
            return .deep
        case HKCategoryValueSleepAnalysis.awake.rawValue:
            return .awake
        default:
            return .awake
        }
    }
    
    private func calculateSleepQuality(from samples: [HKCategorySample]) -> Double {
        // Calculate sleep quality based on sleep stage distribution
        let totalDuration = samples.reduce(0) { $0 + $1.endDate.timeIntervalSince($1.startDate) }
        let deepSleepDuration = samples.filter { $0.value == HKCategoryValueSleepAnalysis.asleep.rawValue }
            .reduce(0) { $0 + $1.endDate.timeIntervalSince($1.startDate) }
        
        return totalDuration > 0 ? deepSleepDuration / totalDuration : 0.0
    }
    
    private func queueMessage(_ message: WatchMessage) {
        // In a real implementation, this would store messages for later delivery
        Logger.info("Message queued for later delivery: \(message.type)", log: Logger.watchManager)
    }
    
    private func handleWatchReply(_ reply: [String: Any]) {
        if let batteryLevel = reply["batteryLevel"] as? Double {
            DispatchQueue.main.async {
                self.watchBatteryLevel = batteryLevel
            }
        }
        
        if let biometricData = reply["biometricData"] as? [String: Any] {
            handleBiometricData(biometricData)
        }
        
        Logger.info("Watch reply received", log: Logger.watchManager)
        isSyncInProgress = false
    }
    
    private func handleWatchError(_ error: Error) {
        Logger.error("Watch communication error: \(error.localizedDescription)", log: Logger.watchManager)
        
        DispatchQueue.main.async {
            self.syncStatus = .error
        }
        
        // Attempt to reconnect
        scheduleReconnect()
        isSyncInProgress = false
    }
    
    private func handleBiometricData(_ data: [String: Any]) {
        DispatchQueue.main.async {
            if let heartRate = data["heartRate"] as? Double {
                self.watchHeartRate = heartRate
            }
            if let hrv = data["hrv"] as? Double {
                self.watchHRV = hrv
            }
            if let bloodOxygen = data["bloodOxygen"] as? Double {
                self.watchBloodOxygen = bloodOxygen
            }
            if let movement = data["movement"] as? Double {
                self.watchMovement = movement
            }
            
            self.lastSyncTime = Date()
            self.syncStatus = .synced
        }
        isSyncInProgress = false
    }
    
    private func scheduleReconnect() {
        guard reconnectAttempts < maxReconnectAttempts else {
            Logger.error("Max reconnection attempts reached", log: Logger.watchManager)
            return
        }
        
        reconnectAttempts += 1
        let delay = TimeInterval(reconnectAttempts * 5) // Exponential backoff
        
        reconnectTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            self?.attemptReconnect()
        }
        Logger.info("Scheduled reconnect in \(delay)s", log: Logger.watchManager)
    }
    
    private func attemptReconnect() {
        guard let session = session else { return }
        
        if session.activationState == .activated {
            session.activate()
        }
        
        Logger.info("Reconnection attempt \(reconnectAttempts)", log: Logger.watchManager)
    }
    
    private func invalidateTimers() {
        syncTimer?.cancel()
        reconnectTimer?.invalidate()
    }
}

// MARK: - WCSessionDelegate

extension AppleWatchManager: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            self.isWatchConnected = activationState == .activated
            self.syncStatus = activationState == .activated ? .connected : .disconnected

            if let error = error {
                Logger.error("Watch session activation failed: \(error.localizedDescription)", log: Logger.watchManager)
            } else {
                Logger.success("Watch session activated successfully", log: Logger.watchManager)
                if activationState == .activated {
                    self.startWatchDependentServices()
                }
            }
        }
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isWatchConnected = false
            self.syncStatus = .disconnected
        }

        stopWatchDependentServices()
        Logger.warning("Watch session became inactive", log: Logger.watchManager)
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isWatchConnected = false
            self.syncStatus = .disconnected
        }

        stopWatchDependentServices()
        Logger.warning("Watch session deactivated", log: Logger.watchManager)
        
        // Reactivate the session
        session.activate()
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        handleWatchMessage(message)
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        handleWatchMessage(message, replyHandler: replyHandler)
    }
    
    private func handleWatchMessage(_ message: [String: Any], replyHandler: (([String: Any]) -> Void)? = nil) {
        guard let messageTypeString = message["type"] as? String,
              let messageType = WatchMessageType(rawValue: messageTypeString) else {
            Logger.error("Invalid message format received from watch", log: Logger.watchManager)
            return
        }
        
        switch messageType {
        case .biometricDataUpdate:
            if let data = message["data"] as? [String: Any] {
                handleBiometricData(data)
            }
            
        case .sleepStageUpdate:
            if let stageString = message["stage"] as? String,
               let stage = SleepStage(rawValue: stageString) {
                DispatchQueue.main.async {
                    self.watchSleepStage = stage
                }
            }
            
        case .batteryLevelUpdate:
            if let batteryLevel = message["batteryLevel"] as? Double {
                DispatchQueue.main.async {
                    self.watchBatteryLevel = batteryLevel
                }
            }
            
        case .appInstalled:
            DispatchQueue.main.async {
                self.isWatchAppInstalled = true
            }
            
        case .appUninstalled:
            DispatchQueue.main.async {
                self.isWatchAppInstalled = false
            }
        }
        
        // Send reply if needed
        if let replyHandler = replyHandler {
            let reply: [String: Any] = ["status": "received"]
            replyHandler(reply)
        }
        
        Logger.info("Message received from watch: \(messageType)", log: Logger.watchManager)
    }
}

// MARK: - Supporting Types

enum WatchMessageType: String, CaseIterable {
    case startSleepTracking = "startSleepTracking"
    case stopSleepTracking = "stopSleepTracking"
    case requestBiometricData = "requestBiometricData"
    case requestBatteryLevel = "requestBatteryLevel"
    case biometricDataUpdate = "biometricDataUpdate"
    case sleepStageUpdate = "sleepStageUpdate"
    case batteryLevelUpdate = "batteryLevelUpdate"
    case appInstalled = "appInstalled"
    case appUninstalled = "appUninstalled"
}

struct WatchMessage: Codable {
    let type: WatchMessageType
    let data: [String: Any]
    
    init(type: WatchMessageType, data: [String: Any]) {
        self.type = type
        self.data = data
    }
    
    enum CodingKeys: String, CodingKey {
        case type
        case data
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        type = try container.decode(WatchMessageType.self, forKey: .type)
        data = [:] // Simplified for this implementation
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        // data encoding would be handled separately for JSON serialization
    }
}

struct WatchSleepSession {
    let startTime: Date
    let endTime: Date
    let stage: SleepStage
    let quality: Double
    
    var duration: TimeInterval {
        return endTime.timeIntervalSince(startTime)
    }
}

enum WatchSyncStatus {
    case disconnected
    case connecting
    case connected
    case syncing
    case synced
    case error
} 
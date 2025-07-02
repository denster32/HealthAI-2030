import Foundation
import Combine
import WatchConnectivity

class RealTimeSyncManager: ObservableObject {
    static let shared = RealTimeSyncManager()
    
    // MARK: - Properties
    @Published var syncStatus: SyncStatus = .idle
    @Published var lastSyncTime: Date?
    @Published var dataConflicts: [DataConflict] = []
    @Published var syncProgress: Double = 0.0
    
    private let appleWatchManager = AppleWatchManager.shared
    private let healthDataManager = HealthDataManager.shared
    private let cloudKitSyncManager = CloudKitSyncManager.shared
    private let coreDataManager = CoreDataManager.shared
    
    private var cancellables = Set<AnyCancellable>()
    @available(iOS 16.0, macOS 13.0, *)
    private var syncTask: Task<Void, Never>?
    @available(iOS 16.0, macOS 13.0, *)
    private var conflictDetectionTask: Task<Void, Never>?
    private let syncInterval: Duration = .seconds(30)
    private let conflictInterval: Duration = .seconds(60)
    
    // Data queues for batch processing
    private var pendingHealthData: [HealthDataSync] = []
    private var pendingSleepData: [SleepDataSync] = []
    private var pendingMLPredictions: [MLPredictionSync] = []
    
    private let maxQueueSize = 50
    private let conflictResolutionStrategy: ConflictResolutionStrategy = .mostRecent
    
    private init() {
        if #available(iOS 16.0, macOS 13.0, *) {
            setupSyncScheduler()
            setupConflictDetection()
        }
        observeHealthDataChanges()
        observeWatchConnectivity()
    }
    
    // MARK: - Setup
    
    @available(iOS 16.0, macOS 13.0, *)
    private func setupSyncScheduler() {
        // Cancel any existing task before creating a new one
        syncTask?.cancel()
        syncTask = Task.detached(priority: .background) { [weak self] in
            let clock = ContinuousClock()
            for await _ in clock.timer(interval: self?.syncInterval ?? .seconds(30)) {
                guard let self else { continue }
                self.performPeriodicSync()
            }
        }
    }
    
    @available(iOS 16.0, macOS 13.0, *)
    private func setupConflictDetection() {
        conflictDetectionTask?.cancel()
        conflictDetectionTask = Task.detached(priority: .background) { [weak self] in
            let clock = ContinuousClock()
            for await _ in clock.timer(interval: self?.conflictInterval ?? .seconds(60)) {
                self?.detectAndResolveConflicts()
            }
        }
    }
    
    private func observeHealthDataChanges() {
        healthDataManager.$currentHeartRate
            .dropFirst()
            .sink { [weak self] heartRate in
                self?.queueHealthDataUpdate(type: .heartRate, value: heartRate, source: .iPhone)
            }
            .store(in: &cancellables)
        
        healthDataManager.$currentHRV
            .dropFirst()
            .sink { [weak self] hrv in
                self?.queueHealthDataUpdate(type: .hrv, value: hrv, source: .iPhone)
            }
            .store(in: &cancellables)
        
        healthDataManager.$predictedSleepStage
            .dropFirst()
            .compactMap { $0 }
            .sink { [weak self] sleepStage in
                self?.queueSleepDataUpdate(stage: sleepStage, source: .iPhone)
            }
            .store(in: &cancellables)
    }
    
    private func observeWatchConnectivity() {
        appleWatchManager.$watchHealthData
            .dropFirst()
            .sink { [weak self] watchData in
                self?.processWatchHealthData(watchData)
            }
            .store(in: &cancellables)
        
        appleWatchManager.$watchSleepSession
            .dropFirst()
            .compactMap { $0 }
            .sink { [weak self] sleepSession in
                self?.processWatchSleepSession(sleepSession)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Data Queuing
    
    private func queueHealthDataUpdate(type: HealthDataType, value: Double, source: DataSource) {
        let syncData = HealthDataSync(
            type: type,
            value: value,
            source: source,
            timestamp: Date(),
            deviceId: getDeviceId(for: source)
        )
        
        pendingHealthData.append(syncData)
        
        if pendingHealthData.count >= maxQueueSize {
            processHealthDataQueue()
        }
    }
    
    private func queueSleepDataUpdate(stage: String, source: DataSource) {
        let syncData = SleepDataSync(
            stage: stage,
            source: source,
            timestamp: Date(),
            deviceId: getDeviceId(for: source)
        )
        
        pendingSleepData.append(syncData)
        
        if pendingSleepData.count >= maxQueueSize {
            processSleepDataQueue()
        }
    }
    
    private func queueMLPrediction(predictionType: String, result: [String: Any], source: DataSource) {
        let syncData = MLPredictionSync(
            predictionType: predictionType,
            result: result,
            source: source,
            timestamp: Date(),
            deviceId: getDeviceId(for: source)
        )
        
        pendingMLPredictions.append(syncData)
    }
    
    // MARK: - Watch Data Processing
    
    private func processWatchHealthData(_ watchData: WatchHealthData) {
        queueHealthDataUpdate(type: .heartRate, value: watchData.heartRate, source: .watch)
        queueHealthDataUpdate(type: .hrv, value: watchData.hrv, source: .watch)
        
        if !watchData.sleepStage.isEmpty {
            queueSleepDataUpdate(stage: watchData.sleepStage, source: .watch)
        }
    }
    
    private func processWatchSleepSession(_ sleepSession: WatchSleepSession) {
        // Create detailed sleep data sync
        if let averageHeartRate = sleepSession.averageHeartRate {
            queueHealthDataUpdate(type: .heartRateAverage, value: averageHeartRate, source: .watch)
        }
        
        if let averageHRV = sleepSession.averageHRV {
            queueHealthDataUpdate(type: .hrvAverage, value: averageHRV, source: .watch)
        }
        
        // Queue session summary
        let sessionData: [String: Any] = [
            "duration": sleepSession.duration ?? 0,
            "dataPoints": sleepSession.dataPoints ?? 0,
            "isActive": sleepSession.isActive
        ]
        
        queueMLPrediction(predictionType: "sleepSession", result: sessionData, source: .watch)
    }
    
    // MARK: - Queue Processing
    
    private func processHealthDataQueue() {
        guard !pendingHealthData.isEmpty else { return }
        
        let dataToProcess = pendingHealthData
        pendingHealthData.removeAll()
        
        // Group by type and resolve conflicts
        let groupedData = Dictionary(grouping: dataToProcess) { $0.type }
        
        for (type, dataPoints) in groupedData {
            let resolvedData = resolveConflicts(in: dataPoints)
            syncHealthDataToAllSources(resolvedData, type: type)
        }
    }
    
    private func processSleepDataQueue() {
        guard !pendingSleepData.isEmpty else { return }
        
        let dataToProcess = pendingSleepData
        pendingSleepData.removeAll()
        
        let resolvedData = resolveConflicts(in: dataToProcess)
        syncSleepDataToAllSources(resolvedData)
    }
    
    private func processMLPredictionQueue() {
        guard !pendingMLPredictions.isEmpty else { return }
        
        let dataToProcess = pendingMLPredictions
        pendingMLPredictions.removeAll()
        
        syncMLPredictionsToCloud(dataToProcess)
    }
    
    // MARK: - Conflict Resolution
    
    private func resolveConflicts<T: SyncableData>(in data: [T]) -> T? {
        switch conflictResolutionStrategy {
        case .mostRecent:
            return data.max { $0.timestamp < $1.timestamp }
        case .watch:
            return data.first { $0.source == .watch } ?? data.last
        case .iPhone:
            return data.first { $0.source == .iPhone } ?? data.last
        case .manual:
            // For manual resolution, add to conflicts queue
            if data.count > 1 {
                let conflict = DataConflict(
                    type: String(describing: T.self),
                    conflictingData: data.map { $0.toDictionary() },
                    timestamp: Date()
                )
                DispatchQueue.main.async {
                    self.dataConflicts.append(conflict)
                }
            }
            return data.last
        }
    }
    
    private func detectAndResolveConflicts() {
        // Detect conflicts between different data sources
        let recentTimeWindow: TimeInterval = 10.0 // 10 seconds
        let now = Date()
        
        // Check for concurrent updates from different sources
        let recentHealthData = pendingHealthData.filter {
            now.timeIntervalSince($0.timestamp) < recentTimeWindow
        }
        
        let conflictGroups = Dictionary(grouping: recentHealthData) { data in
            "\(data.type)-\(Int(data.timestamp.timeIntervalSince1970 / 5))" // Group by type and 5-second windows
        }
        
        for (_, group) in conflictGroups {
            let uniqueSources = Set(group.map { $0.source })
            if uniqueSources.count > 1 {
                // Conflict detected
                let conflict = DataConflict(
                    type: "HealthData",
                    conflictingData: group.map { $0.toDictionary() },
                    timestamp: now
                )
                
                DispatchQueue.main.async {
                    self.dataConflicts.append(conflict)
                }
            }
        }
    }
    
    // MARK: - Sync Operations
    
    private func syncHealthDataToAllSources(_ data: HealthDataSync?, type: HealthDataType) {
        guard let data = data else { return }
        
        // Sync to Core Data
        let sensorSample = SensorSample(
            type: mapToSensorType(data.type),
            value: data.value,
            unit: getUnit(for: data.type),
            timestamp: data.timestamp
        )
        coreDataManager.saveSensorSamples([sensorSample])
        
        // Sync to CloudKit
        let cloudKitData = [
            "type": data.type.rawValue,
            "value": data.value,
            "timestamp": data.timestamp.timeIntervalSince1970,
            "source": data.source.rawValue
        ]
        
        // Sync to Watch (if data came from iPhone)
        if data.source == .iPhone && appleWatchManager.isWatchAvailable() {
            let watchMessage = WatchMessage(
                command: "healthDataUpdate",
                data: cloudKitData,
                source: "iphone"
            )
            appleWatchManager.sendMessageToWatchWithoutReply(watchMessage)
        }
    }
    
    private func syncSleepDataToAllSources(_ data: SleepDataSync?) {
        guard let data = data else { return }
        
        // Update local predictions
        DispatchQueue.main.async {
            self.healthDataManager.predictedSleepStage = data.stage
        }
        
        // Sync to Watch (if data came from iPhone)
        if data.source == .iPhone && appleWatchManager.isWatchAvailable() {
            let watchMessage = WatchMessage(
                command: "sleepStageUpdate",
                data: [
                    "sleepStage": data.stage,
                    "timestamp": data.timestamp.timeIntervalSince1970
                ],
                source: "iphone"
            )
            appleWatchManager.sendMessageToWatchWithoutReply(watchMessage)
        }
    }
    
    private func syncMLPredictionsToCloud(_ predictions: [MLPredictionSync]) {
        for prediction in predictions {
            let cloudData = [
                "predictionType": prediction.predictionType,
                "result": prediction.result,
                "timestamp": prediction.timestamp.timeIntervalSince1970,
                "source": prediction.source.rawValue
            ] as [String: Any]
            
            // This would sync to CloudKit or external ML service
            print("RealTimeSyncManager: Syncing ML prediction: \(prediction.predictionType)")
        }
    }
    
    // MARK: - Public Interface
    
    func performManualSync() {
        DispatchQueue.main.async {
            self.syncStatus = .syncing
            self.syncProgress = 0.0
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            self.performFullSync()
        }
    }
    
    private func performPeriodicSync() {
        processHealthDataQueue()
        processSleepDataQueue()
        processMLPredictionQueue()
        
        DispatchQueue.main.async {
            self.lastSyncTime = Date()
        }
    }
    
    private func performFullSync() {
        let totalSteps = 5
        var currentStep = 0
        
        // Step 1: Process all queues
        processHealthDataQueue()
        currentStep += 1
        updateSyncProgress(Double(currentStep) / Double(totalSteps))
        
        // Step 2: Sync with Watch
        if appleWatchManager.isWatchAvailable() {
            appleWatchManager.syncWithWatch()
        }
        currentStep += 1
        updateSyncProgress(Double(currentStep) / Double(totalSteps))
        
        // Step 3: Sync with CloudKit
        cloudKitSyncManager.syncHealthData { _ in
            currentStep += 1
            self.updateSyncProgress(Double(currentStep) / Double(totalSteps))
        }
        
        // Step 4: Process conflicts
        detectAndResolveConflicts()
        currentStep += 1
        updateSyncProgress(Double(currentStep) / Double(totalSteps))
        
        // Step 5: Complete
        currentStep += 1
        updateSyncProgress(Double(currentStep) / Double(totalSteps))
        
        DispatchQueue.main.async {
            self.syncStatus = .completed
            self.lastSyncTime = Date()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.syncStatus = .idle
                self.syncProgress = 0.0
            }
        }
    }
    
    private func updateSyncProgress(_ progress: Double) {
        DispatchQueue.main.async {
            self.syncProgress = progress
        }
    }
    
    func resolveConflict(_ conflict: DataConflict, chosenIndex: Int) {
        guard chosenIndex < conflict.conflictingData.count else { return }
        
        let chosenData = conflict.conflictingData[chosenIndex]
        // Apply the chosen resolution
        
        DispatchQueue.main.async {
            self.dataConflicts.removeAll { $0.id == conflict.id }
        }
    }
    
    func clearConflicts() {
        DispatchQueue.main.async {
            self.dataConflicts.removeAll()
        }
    }
    
    // MARK: - Utility Methods
    
    private func getDeviceId(for source: DataSource) -> String {
        switch source {
        case .iPhone:
            return UIDevice.current.identifierForVendor?.uuidString ?? "iPhone"
        case .watch:
            return "AppleWatch"
        case .cloud:
            return "CloudKit"
        }
    }
    
    private func mapToSensorType(_ healthDataType: HealthDataType) -> SensorType {
        switch healthDataType {
        case .heartRate, .heartRateAverage:
            return .heartRate
        case .hrv, .hrvAverage:
            return .hrv
        case .oxygenSaturation:
            return .oxygenSaturation
        case .bodyTemperature:
            return .bodyTemperature
        }
    }
    
    private func getUnit(for type: HealthDataType) -> String {
        switch type {
        case .heartRate, .heartRateAverage:
            return "count/min"
        case .hrv, .hrvAverage:
            return "ms"
        case .oxygenSaturation:
            return "%"
        case .bodyTemperature:
            return "°C"
        }
    }
}

// MARK: - Supporting Types

enum SyncStatus {
    case idle
    case syncing
    case completed
    case error(String)
}

enum DataSource: String, CaseIterable {
    case iPhone = "iPhone"
    case watch = "AppleWatch"
    case cloud = "CloudKit"
}

enum ConflictResolutionStrategy {
    case mostRecent
    case watch
    case iPhone
    case manual
}

enum HealthDataType: String, CaseIterable {
    case heartRate = "heartRate"
    case hrv = "hrv"
    case heartRateAverage = "heartRateAverage"
    case hrvAverage = "hrvAverage"
    case oxygenSaturation = "oxygenSaturation"
    case bodyTemperature = "bodyTemperature"
}

protocol SyncableData {
    var timestamp: Date { get }
    var source: DataSource { get }
    func toDictionary() -> [String: Any]
}

struct HealthDataSync: SyncableData {
    let type: HealthDataType
    let value: Double
    let source: DataSource
    let timestamp: Date
    let deviceId: String
    
    func toDictionary() -> [String: Any] {
        return [
            "type": type.rawValue,
            "value": value,
            "source": source.rawValue,
            "timestamp": timestamp.timeIntervalSince1970,
            "deviceId": deviceId
        ]
    }
}

struct SleepDataSync: SyncableData {
    let stage: String
    let source: DataSource
    let timestamp: Date
    let deviceId: String
    
    func toDictionary() -> [String: Any] {
        return [
            "stage": stage,
            "source": source.rawValue,
            "timestamp": timestamp.timeIntervalSince1970,
            "deviceId": deviceId
        ]
    }
}

struct MLPredictionSync: SyncableData {
    let predictionType: String
    let result: [String: Any]
    let source: DataSource
    let timestamp: Date
    let deviceId: String
    
    func toDictionary() -> [String: Any] {
        return [
            "predictionType": predictionType,
            "result": result,
            "source": source.rawValue,
            "timestamp": timestamp.timeIntervalSince1970,
            "deviceId": deviceId
        ]
    }
}

struct DataConflict: Identifiable {
    let id = UUID()
    let type: String
    let conflictingData: [[String: Any]]
    let timestamp: Date
}
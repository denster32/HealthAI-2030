import Foundation
import HealthAI2030Core
import AsyncAlgorithms
import Combine

/// Multi-user synchronization engine for real-time health data sharing
@MainActor
public class MultiUserSyncEngine: ObservableObject {
    @Published public private(set) var participants: [WellnessParticipant] = []
    @Published public private(set) var syncState: SyncState = .idle
    @Published public private(set) var groupMetrics: [String: AggregatedMetric] = [:]
    
    private var syncCoordinator: SyncCoordinator
    private var dataProcessor: GroupDataProcessor
    private var privacyManager: SyncPrivacyManager
    private var networkManager: SyncNetworkManager
    private var cancellables = Set<AnyCancellable>()
    
    public enum SyncState {
        case idle
        case syncing
        case error(String)
        case completed
    }
    
    public init() {
        self.syncCoordinator = SyncCoordinator()
        self.dataProcessor = GroupDataProcessor()
        self.privacyManager = SyncPrivacyManager()
        self.networkManager = SyncNetworkManager()
        
        setupObservers()
    }
    
    // MARK: - Public Interface
    
    /// Add a participant to the sync session
    public func addParticipant(_ participant: WellnessParticipant) async {
        participants.append(participant)
        await syncCoordinator.registerParticipant(participant)
        await privacyManager.configurePermissions(for: participant)
    }
    
    /// Remove a participant from the sync session
    public func removeParticipant(_ participantId: UUID) async {
        participants.removeAll { $0.id == participantId }
        await syncCoordinator.unregisterParticipant(participantId)
    }
    
    /// Sync health metrics with all participants
    public func syncMetrics(_ metrics: [HealthMetric], with participants: [WellnessParticipant]) async throws {
        guard !participants.isEmpty else { return }
        
        syncState = .syncing
        
        do {
            // Filter metrics based on privacy settings
            let filteredMetrics = await privacyManager.filterMetrics(metrics, for: participants)
            
            // Anonymize sensitive data
            let anonymizedMetrics = await privacyManager.anonymizeMetrics(filteredMetrics)
            
            // Sync with each participant
            try await syncCoordinator.syncMetrics(anonymizedMetrics, to: participants)
            
            // Process aggregated data
            await processAggregatedData(anonymizedMetrics)
            
            syncState = .completed
            
        } catch {
            syncState = .error(error.localizedDescription)
            throw error
        }
    }
    
    /// Generate group health insights from all participants
    public func generateGroupInsights(for participants: [WellnessParticipant]) async -> GroupHealthInsights {
        let insights = await dataProcessor.generateGroupInsights(
            participants: participants,
            aggregatedMetrics: groupMetrics
        )
        
        return insights
    }
    
    /// Broadcast a message to all participants
    public func broadcastMessage(_ message: SyncMessage) async {
        await networkManager.broadcast(message, to: participants)
    }
    
    /// Send a message to a specific participant or host
    public func sendMessage(_ message: SyncMessage, to target: MessageTarget) async {
        await networkManager.send(message, to: target, participants: participants)
    }
    
    /// Reset the sync engine
    public func reset() async {
        participants.removeAll()
        groupMetrics.removeAll()
        syncState = .idle
        
        await syncCoordinator.reset()
        await dataProcessor.reset()
        await privacyManager.reset()
        await networkManager.reset()
    }
    
    // MARK: - Private Implementation
    
    private func setupObservers() {
        syncCoordinator.$syncEvents
            .receive(on: DispatchQueue.main)
            .sink { [weak self] events in
                self?.handleSyncEvents(events)
            }
            .store(in: &cancellables)
        
        dataProcessor.$aggregatedMetrics
            .receive(on: DispatchQueue.main)
            .sink { [weak self] metrics in
                self?.groupMetrics = metrics
            }
            .store(in: &cancellables)
    }
    
    private func handleSyncEvents(_ events: [SyncEvent]) {
        for event in events {
            switch event.type {
            case .participantJoined:
                handleParticipantJoined(event)
            case .participantLeft:
                handleParticipantLeft(event)
            case .dataReceived:
                handleDataReceived(event)
            case .syncError:
                handleSyncError(event)
            }
        }
    }
    
    private func handleParticipantJoined(_ event: SyncEvent) {
        // Handle new participant joining
        print("Participant joined: \(event.participantId)")
    }
    
    private func handleParticipantLeft(_ event: SyncEvent) {
        // Handle participant leaving
        Task {
            await removeParticipant(event.participantId)
        }
    }
    
    private func handleDataReceived(_ event: SyncEvent) {
        // Handle incoming health data
        Task {
            if let data = event.data {
                await processIncomingData(data, from: event.participantId)
            }
        }
    }
    
    private func handleSyncError(_ event: SyncEvent) {
        syncState = .error(event.error?.localizedDescription ?? "Unknown sync error")
    }
    
    private func processAggregatedData(_ metrics: [HealthMetric]) async {
        await dataProcessor.processMetrics(metrics, from: participants)
    }
    
    private func processIncomingData(_ data: Data, from participantId: UUID) async {
        do {
            let metrics = try JSONDecoder().decode([HealthMetric].self, from: data)
            await dataProcessor.addParticipantMetrics(metrics, from: participantId)
        } catch {
            print("Failed to decode incoming health metrics: \(error)")
        }
    }
}

// MARK: - Sync Coordinator

public actor SyncCoordinator {
    @Published public var syncEvents: [SyncEvent] = []
    
    private var participantChannels: [UUID: ParticipantChannel] = [:]
    private var syncScheduler: SyncScheduler
    
    public init() {
        self.syncScheduler = SyncScheduler()
    }
    
    public func registerParticipant(_ participant: WellnessParticipant) async {
        let channel = ParticipantChannel(participant: participant)
        participantChannels[participant.id] = channel
        
        // Set up real-time sync for this participant
        await setupParticipantSync(participant, channel: channel)
        
        // Emit join event
        let event = SyncEvent(
            type: .participantJoined,
            participantId: participant.id,
            timestamp: Date()
        )
        syncEvents.append(event)
    }
    
    public func unregisterParticipant(_ participantId: UUID) async {
        participantChannels.removeValue(forKey: participantId)
        
        // Emit leave event
        let event = SyncEvent(
            type: .participantLeft,
            participantId: participantId,
            timestamp: Date()
        )
        syncEvents.append(event)
    }
    
    public func syncMetrics(_ metrics: [HealthMetric], to participants: [WellnessParticipant]) async throws {
        // Encode metrics for transmission
        let data = try JSONEncoder().encode(metrics)
        
        // Send to each participant channel
        for participant in participants {
            if let channel = participantChannels[participant.id] {
                try await channel.send(data)
            }
        }
        
        // Schedule next sync
        await syncScheduler.scheduleNext()
    }
    
    public func reset() async {
        participantChannels.removeAll()
        syncEvents.removeAll()
        await syncScheduler.reset()
    }
    
    private func setupParticipantSync(_ participant: WellnessParticipant, channel: ParticipantChannel) async {
        // Set up real-time data streaming for participant
        Task {
            for await data in channel.dataStream {
                let event = SyncEvent(
                    type: .dataReceived,
                    participantId: participant.id,
                    timestamp: Date(),
                    data: data
                )
                syncEvents.append(event)
            }
        }
    }
}

// MARK: - Group Data Processor

@MainActor
public class GroupDataProcessor: ObservableObject {
    @Published public var aggregatedMetrics: [String: AggregatedMetric] = [:]
    
    private var participantData: [UUID: [HealthMetric]] = [:]
    private var insightsGenerator: GroupInsightsGenerator
    
    public init() {
        self.insightsGenerator = GroupInsightsGenerator()
    }
    
    public func processMetrics(_ metrics: [HealthMetric], from participants: [WellnessParticipant]) async {
        // Aggregate metrics across all participants
        var newAggregatedMetrics: [String: AggregatedMetric] = [:]
        
        // Group metrics by type
        let groupedMetrics = Dictionary(grouping: metrics) { $0.type }
        
        for (metricType, typeMetrics) in groupedMetrics {
            let aggregated = AggregatedMetric(
                type: metricType,
                values: typeMetrics.map(\.value),
                participants: participants.count,
                timestamp: Date()
            )
            
            newAggregatedMetrics[metricType.rawValue] = aggregated
        }
        
        aggregatedMetrics = newAggregatedMetrics
    }
    
    public func addParticipantMetrics(_ metrics: [HealthMetric], from participantId: UUID) async {
        participantData[participantId] = metrics
        
        // Reprocess aggregated data
        let allMetrics = participantData.values.flatMap { $0 }
        // Would need participant list here - simplified for now
        // await processMetrics(allMetrics, from: participants)
    }
    
    public func generateGroupInsights(
        participants: [WellnessParticipant],
        aggregatedMetrics: [String: AggregatedMetric]
    ) async -> GroupHealthInsights {
        return await insightsGenerator.generate(
            participants: participants,
            metrics: aggregatedMetrics
        )
    }
    
    public func reset() async {
        participantData.removeAll()
        aggregatedMetrics.removeAll()
    }
}

// MARK: - Privacy Manager

public actor SyncPrivacyManager {
    private var participantPermissions: [UUID: PrivacyPermissions] = [:]
    private var anonymizationEngine: AnonymizationEngine
    
    public init() {
        self.anonymizationEngine = AnonymizationEngine()
    }
    
    public func configurePermissions(for participant: WellnessParticipant) async {
        let permissions = PrivacyPermissions(
            sharingLevel: participant.healthSharingLevel,
            allowedMetrics: getAllowedMetrics(for: participant.healthSharingLevel),
            anonymizationLevel: .medium
        )
        
        participantPermissions[participant.id] = permissions
    }
    
    public func filterMetrics(_ metrics: [HealthMetric], for participants: [WellnessParticipant]) async -> [HealthMetric] {
        var filteredMetrics: [HealthMetric] = []
        
        for participant in participants {
            guard let permissions = participantPermissions[participant.id] else { continue }
            
            let participantMetrics = metrics.filter { metric in
                permissions.allowedMetrics.contains(metric.type)
            }
            
            filteredMetrics.append(contentsOf: participantMetrics)
        }
        
        return filteredMetrics
    }
    
    public func anonymizeMetrics(_ metrics: [HealthMetric]) async -> [HealthMetric] {
        return await anonymizationEngine.anonymize(metrics)
    }
    
    public func reset() async {
        participantPermissions.removeAll()
    }
    
    private func getAllowedMetrics(for sharingLevel: WellnessParticipant.HealthSharingLevel) -> Set<MetricType> {
        switch sharingLevel {
        case .none:
            return []
        case .basic:
            return [.heartRate, .activityLevel]
        case .extended:
            return [.heartRate, .heartRateVariability, .activityLevel, .stressLevel, .sleepQuality]
        case .full:
            return Set(MetricType.allCases)
        }
    }
}

// MARK: - Network Manager

public actor SyncNetworkManager {
    private var messageQueue: [QueuedMessage] = []
    private var networkState: NetworkState = .disconnected
    
    public enum NetworkState {
        case disconnected
        case connecting
        case connected
        case error(String)
    }
    
    public func broadcast(_ message: SyncMessage, to participants: [WellnessParticipant]) async {
        let queuedMessage = QueuedMessage(
            message: message,
            targets: participants.map { .participant($0.id) },
            timestamp: Date()
        )
        
        messageQueue.append(queuedMessage)
        await processMessageQueue()
    }
    
    public func send(_ message: SyncMessage, to target: MessageTarget, participants: [WellnessParticipant]) async {
        let queuedMessage = QueuedMessage(
            message: message,
            targets: [target],
            timestamp: Date()
        )
        
        messageQueue.append(queuedMessage)
        await processMessageQueue()
    }
    
    public func reset() async {
        messageQueue.removeAll()
        networkState = .disconnected
    }
    
    private func processMessageQueue() async {
        guard networkState == .connected else { return }
        
        for queuedMessage in messageQueue {
            await deliverMessage(queuedMessage)
        }
        
        messageQueue.removeAll()
    }
    
    private func deliverMessage(_ queuedMessage: QueuedMessage) async {
        // Implementation would deliver message to targets
        print("Delivering message: \(queuedMessage.message.type) to \(queuedMessage.targets.count) targets")
    }
}

// MARK: - Supporting Types

public struct SyncEvent: Sendable {
    public enum EventType {
        case participantJoined
        case participantLeft
        case dataReceived
        case syncError
    }
    
    public let type: EventType
    public let participantId: UUID
    public let timestamp: Date
    public let data: Data?
    public let error: Error?
    
    public init(type: EventType, participantId: UUID, timestamp: Date, data: Data? = nil, error: Error? = nil) {
        self.type = type
        self.participantId = participantId
        self.timestamp = timestamp
        self.data = data
        self.error = error
    }
}

public struct AggregatedMetric: Sendable {
    public let type: MetricType
    public let values: [Double]
    public let participants: Int
    public let timestamp: Date
    
    public var average: Double {
        guard !values.isEmpty else { return 0 }
        return values.reduce(0, +) / Double(values.count)
    }
    
    public var minimum: Double {
        values.min() ?? 0
    }
    
    public var maximum: Double {
        values.max() ?? 0
    }
    
    public var variance: Double {
        guard values.count > 1 else { return 0 }
        let mean = average
        let squaredDifferences = values.map { pow($0 - mean, 2) }
        return squaredDifferences.reduce(0, +) / Double(values.count)
    }
}

public struct PrivacyPermissions: Sendable {
    public let sharingLevel: WellnessParticipant.HealthSharingLevel
    public let allowedMetrics: Set<MetricType>
    public let anonymizationLevel: AnonymizationLevel
    
    public enum AnonymizationLevel {
        case none
        case low
        case medium
        case high
    }
}

public enum SyncMessage: Sendable {
    case sessionEnding
    case participantLeaving
    case metricsUpdate([HealthMetric])
    case heartbeat
    case error(String)
    
    public var type: String {
        switch self {
        case .sessionEnding: return "session_ending"
        case .participantLeaving: return "participant_leaving"
        case .metricsUpdate: return "metrics_update"
        case .heartbeat: return "heartbeat"
        case .error: return "error"
        }
    }
}

public enum MessageTarget: Sendable {
    case host
    case participant(UUID)
    case all
}

public struct QueuedMessage: Sendable {
    public let message: SyncMessage
    public let targets: [MessageTarget]
    public let timestamp: Date
}

// MARK: - Helper Classes

public actor ParticipantChannel {
    public let participant: WellnessParticipant
    public let dataStream: AsyncStream<Data>
    private let dataContinuation: AsyncStream<Data>.Continuation
    
    public init(participant: WellnessParticipant) {
        self.participant = participant
        
        let (stream, continuation) = AsyncStream.makeStream(of: Data.self)
        self.dataStream = stream
        self.dataContinuation = continuation
    }
    
    public func send(_ data: Data) async throws {
        dataContinuation.yield(data)
    }
    
    deinit {
        dataContinuation.finish()
    }
}

public actor SyncScheduler {
    private var nextSyncTime: Date?
    private var syncInterval: TimeInterval = 1.0 // 1 second
    
    public func scheduleNext() async {
        nextSyncTime = Date().addingTimeInterval(syncInterval)
    }
    
    public func reset() async {
        nextSyncTime = nil
    }
}

public actor AnonymizationEngine {
    public func anonymize(_ metrics: [HealthMetric]) async -> [HealthMetric] {
        // Apply anonymization algorithms to protect privacy
        return metrics.map { metric in
            var anonymized = metric
            
            // Add noise to sensitive values
            if shouldAnonymize(metric.type) {
                anonymized = addNoise(to: anonymized)
            }
            
            return anonymized
        }
    }
    
    private func shouldAnonymize(_ type: MetricType) -> Bool {
        // Determine which metrics need anonymization
        switch type {
        case .heartRate, .heartRateVariability, .bloodPressureSystolic, .bloodPressureDiastolic:
            return true
        default:
            return false
        }
    }
    
    private func addNoise(to metric: HealthMetric) -> HealthMetric {
        // Add differential privacy noise
        let noise = Double.random(in: -0.5...0.5)
        let noisyValue = metric.value + noise
        
        return HealthMetric(
            id: metric.id,
            type: metric.type,
            value: noisyValue,
            unit: metric.unit,
            timestamp: metric.timestamp,
            confidence: metric.confidence * 0.95, // Slightly reduce confidence
            source: metric.source,
            metadata: metric.metadata
        )
    }
}

public actor GroupInsightsGenerator {
    public func generate(
        participants: [WellnessParticipant],
        metrics: [String: AggregatedMetric]
    ) async -> GroupHealthInsights {
        let participantCount = participants.count
        
        // Calculate group-level metrics
        let avgHeartRate = metrics["heartRate"]?.average
        let avgStressLevel = metrics["stressLevel"]?.average
        let groupEnergyLevel = calculateGroupEnergyLevel(metrics)
        let syncScore = calculateSyncScore(metrics, participantCount: participantCount)
        
        // Generate recommendations
        let recommendations = generateRecommendations(metrics: metrics, participantCount: participantCount)
        
        return GroupHealthInsights(
            participantCount: participantCount,
            averageHeartRate: avgHeartRate,
            averageStressLevel: avgStressLevel,
            groupEnergyLevel: groupEnergyLevel,
            syncScore: syncScore,
            recommendations: recommendations,
            timestamp: Date()
        )
    }
    
    private func calculateGroupEnergyLevel(_ metrics: [String: AggregatedMetric]) -> Double {
        // Calculate overall group energy based on various metrics
        var energyFactors: [Double] = []
        
        if let heartRate = metrics["heartRate"] {
            // Moderate heart rate indicates good energy
            let hrEnergy = max(0, 1.0 - abs(heartRate.average - 70) / 70)
            energyFactors.append(hrEnergy)
        }
        
        if let activity = metrics["activityLevel"] {
            energyFactors.append(activity.average / 10.0) // Normalize to 0-1
        }
        
        if let stress = metrics["stressLevel"] {
            // Lower stress = higher energy
            energyFactors.append(max(0, 1.0 - stress.average / 10.0))
        }
        
        return energyFactors.isEmpty ? 0.5 : energyFactors.reduce(0, +) / Double(energyFactors.count)
    }
    
    private func calculateSyncScore(_ metrics: [String: AggregatedMetric], participantCount: Int) -> Double {
        guard participantCount > 1 else { return 1.0 }
        
        var syncFactors: [Double] = []
        
        // Calculate synchronization based on variance
        for (_, metric) in metrics {
            let normalizedVariance = metric.variance / (metric.average * metric.average)
            let syncFactor = max(0, 1.0 - normalizedVariance)
            syncFactors.append(syncFactor)
        }
        
        return syncFactors.isEmpty ? 0.5 : syncFactors.reduce(0, +) / Double(syncFactors.count)
    }
    
    private func generateRecommendations(
        metrics: [String: AggregatedMetric],
        participantCount: Int
    ) -> [GroupRecommendation] {
        var recommendations: [GroupRecommendation] = []
        
        // Heart rate recommendations
        if let heartRate = metrics["heartRate"], heartRate.average > 100 {
            recommendations.append(GroupRecommendation(
                title: "Group Heart Rate Elevated",
                description: "The group's average heart rate is elevated. Consider a calming activity.",
                actionItems: [
                    "Try a group breathing exercise",
                    "Take a short break",
                    "Consider gentle movement"
                ],
                priority: .medium
            ))
        }
        
        // Stress recommendations
        if let stress = metrics["stressLevel"], stress.average > 6 {
            recommendations.append(GroupRecommendation(
                title: "High Group Stress Detected",
                description: "The group is experiencing elevated stress levels.",
                actionItems: [
                    "Initiate a mindfulness session",
                    "Encourage open communication",
                    "Consider ending the session early if needed"
                ],
                priority: .high
            ))
        }
        
        // Sync recommendations
        let syncScore = calculateSyncScore(metrics, participantCount: participantCount)
        if syncScore < 0.6 {
            recommendations.append(GroupRecommendation(
                title: "Improve Group Synchronization",
                description: "The group could benefit from better synchronization.",
                actionItems: [
                    "Try synchronized breathing",
                    "Use audio cues for timing",
                    "Check that everyone can see/hear instructions clearly"
                ],
                priority: .medium
            ))
        }
        
        return recommendations
    }
}
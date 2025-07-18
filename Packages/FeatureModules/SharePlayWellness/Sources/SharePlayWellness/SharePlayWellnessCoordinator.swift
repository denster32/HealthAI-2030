import Foundation
import GroupActivities
import Combine
import HealthAI2030Core
import MultiUserSync
import OSLog

@available(iOS 17.0, macOS 14.0, watchOS 10.0, tvOS 17.0, *)
extension OSLog {
    static let sharePlay = OSLog(subsystem: "com.healthai2030.shareplay", category: "wellness")
}

#if os(iOS) || os(iPadOS) || os(macOS) || os(visionOS)

/// SharePlay wellness coordinator for multi-user health experiences
@available(iOS 17.0, macOS 14.0, watchOS 10.0, tvOS 17.0, *)
@MainActor
public class SharePlayWellnessCoordinator: ObservableObject {
    public static let shared = SharePlayWellnessCoordinator()
    
    @Published public private(set) var sessions: [GroupSession<any GroupActivity>] = []
    @Published public private(set) var activeParticipants: [WellnessParticipant] = []
    @Published public private(set) var currentActivity: (any WellnessGroupActivity)?
    @Published public private(set) var isHosting = false
    @Published public private(set) var connectionState: ConnectionState = .disconnected
    
    private var multiUserSync: MultiUserSyncEngine
    private var groupSessionManager: GroupSessionManager
    private var cancellables = Set<AnyCancellable>()
    private var logger = OSLog.sharePlay
    
    public enum ConnectionState {
        case disconnected
        case connecting
        case connected
        case error(String)
    }
    
    private init() {
        self.multiUserSync = MultiUserSyncEngine()
        self.groupSessionManager = GroupSessionManager()
        
        setupGroupSessionObservers()
        setupSyncEngineObservers()
    }
    
    // MARK: - Public Interface
    
    /// Start a new SharePlay wellness activity
    public func startWellnessActivity<T: WellnessGroupActivity>(_ activity: T) async throws {
        guard !isHosting else {
            os_log("Already hosting a wellness activity", log: logger, type: .error)
            throw SharePlayError.alreadyHosting
        }
        
        os_log("Starting wellness activity: %@", log: logger, type: .info, activity.activityType.rawValue)
        
        // Prepare activity for SharePlay
        let preparedActivity = try await prepareActivity(activity)
        
        // Start GroupActivity session with improved error handling
        do {
            let result = await preparedActivity.prepareForActivation()
            
            switch result {
            case .activationPreferred:
                try await preparedActivity.activate()
                isHosting = true
                currentActivity = preparedActivity
                os_log("Successfully started wellness activity", log: logger, type: .info)
                
            case .activationDisabled:
                os_log("SharePlay activation is disabled", log: logger, type: .error)
                throw SharePlayError.activationDisabled
                
            case .cancelled:
                os_log("User cancelled wellness activity", log: logger, type: .info)
                throw SharePlayError.userCancelled
                
            @unknown default:
                os_log("Unknown activation result", log: logger, type: .error)
                throw SharePlayError.unknownError
            }
        } catch {
            os_log("Failed to start wellness activity: %@", log: logger, type: .error, error.localizedDescription)
            throw error
        }
    }
    
    /// Join an existing wellness activity
    public func joinWellnessActivity() async throws {
        guard let activity = currentActivity else {
            throw SharePlayError.noActiveActivity
        }
        
        connectionState = .connecting
        
        // Configure session for joining
        try await configureJoinSession(activity)
        
        connectionState = .connected
    }
    
    /// Leave current wellness activity
    public func leaveWellnessActivity() async {
        if isHosting {
            await endHostedActivity()
        } else {
            await leaveJoinedActivity()
        }
        
        await cleanupSession()
    }
    
    /// Sync health data with group participants
    public func syncHealthData(_ metrics: [HealthMetric]) async throws {
        guard connectionState == .connected else {
            throw SharePlayError.notConnected
        }
        
        try await multiUserSync.syncMetrics(metrics, with: activeParticipants)
    }
    
    /// Get aggregated group health insights
    public func getGroupHealthInsights() async -> GroupHealthInsights? {
        guard !activeParticipants.isEmpty else { return nil }
        
        return await multiUserSync.generateGroupInsights(for: activeParticipants)
    }
    
    // MARK: - Activity Management
    
    private func prepareActivity<T: WellnessGroupActivity>(_ activity: T) async throws -> T {
        // Configure activity settings
        var preparedActivity = activity
        preparedActivity.hostParticipant = WellnessParticipant.current()
        preparedActivity.sessionId = UUID()
        preparedActivity.startTime = Date()
        
        return preparedActivity
    }
    
    private func configureJoinSession(_ activity: any WellnessGroupActivity) async throws {
        // Set up participant data
        let participant = WellnessParticipant.current()
        activeParticipants.append(participant)
        
        // Initialize sync for this participant
        await multiUserSync.addParticipant(participant)
    }
    
    private func endHostedActivity() async {
        // Notify all participants that the session is ending
        await notifySessionEnd()
        
        // Clean up hosting state
        isHosting = false
        currentActivity = nil
    }
    
    private func leaveJoinedActivity() async {
        // Notify host that this participant is leaving
        await notifyParticipantLeaving()
        
        // Remove from active participants
        let currentParticipant = WellnessParticipant.current()
        activeParticipants.removeAll { $0.id == currentParticipant.id }
    }
    
    private func cleanupSession() async {
        connectionState = .disconnected
        activeParticipants.removeAll()
        currentActivity = nil
        
        await multiUserSync.reset()
    }
    
    // MARK: - Session Observers
    
    private func setupGroupSessionObservers() {
        groupSessionManager.$activeSessions
            .receive(on: DispatchQueue.main)
            .sink { [weak self] sessions in
                self?.sessions = sessions
            }
            .store(in: &cancellables)
        
        groupSessionManager.$connectionState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.connectionState = state
            }
            .store(in: &cancellables)
    }
    
    private func setupSyncEngineObservers() {
        multiUserSync.$participants
            .receive(on: DispatchQueue.main)
            .sink { [weak self] participants in
                self?.activeParticipants = participants
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Notifications
    
    private func notifySessionEnd() async {
        // Implementation would send session end notifications
        await multiUserSync.broadcastMessage(.sessionEnding)
    }
    
    private func notifyParticipantLeaving() async {
        // Implementation would notify host of participant leaving
        await multiUserSync.sendMessage(.participantLeaving, to: .host)
    }
}

// MARK: - Wellness Group Activities

public protocol WellnessGroupActivity: GroupActivity {
    var hostParticipant: WellnessParticipant? { get set }
    var sessionId: UUID? { get set }
    var startTime: Date? { get set }
    var maxParticipants: Int { get }
    var activityType: WellnessActivityType { get }
}

public enum WellnessActivityType: String, Sendable, CaseIterable {
    case groupMeditation = "group_meditation"
    case workoutChallenge = "workout_challenge"
    case breathingExercise = "breathing_exercise"
    case wellnessCheck = "wellness_check"
    case healthGoalSetting = "health_goal_setting"
    case mindfulnessSession = "mindfulness_session"
}

// MARK: - Specific Activities

public struct GroupMeditationActivity: WellnessGroupActivity {
    public var hostParticipant: WellnessParticipant?
    public var sessionId: UUID?
    public var startTime: Date?
    
    public let maxParticipants: Int = 8
    public let activityType: WellnessActivityType = .groupMeditation
    
    public let duration: TimeInterval
    public let meditationType: MeditationType
    public let guidedAudio: Bool
    
    public enum MeditationType: String, Sendable {
        case mindfulness
        case breathing
        case bodyJOurnal
        case loving kindness = "loving_kindness"
        case visualization
    }
    
    public var metadata: GroupActivityMetadata {
        GroupActivityMetadata(
            title: "Group Meditation",
            type: .generic,
            supportsContinuationOnTV: false
        )
    }
    
    public init(duration: TimeInterval, type: MeditationType, guidedAudio: Bool = true) {
        self.duration = duration
        self.meditationType = type
        self.guidedAudio = guidedAudio
    }
}

public struct WorkoutChallengeActivity: WellnessGroupActivity {
    public var hostParticipant: WellnessParticipant?
    public var sessionId: UUID?
    public var startTime: Date?
    
    public let maxParticipants: Int = 6
    public let activityType: WellnessActivityType = .workoutChallenge
    
    public let challengeType: ChallengeType
    public let duration: TimeInterval
    public let targetMetrics: [MetricTarget]
    
    public enum ChallengeType: String, Sendable {
        case stepCount = "step_count"
        case heartRate = "heart_rate"
        case caloriesBurned = "calories_burned"
        case activeMinutes = "active_minutes"
        case distance = "distance"
    }
    
    public var metadata: GroupActivityMetadata {
        GroupActivityMetadata(
            title: "Workout Challenge",
            type: .generic,
            supportsContinuationOnTV: true
        )
    }
    
    public init(type: ChallengeType, duration: TimeInterval, targets: [MetricTarget]) {
        self.challengeType = type
        self.duration = duration
        self.targetMetrics = targets
    }
}

public struct BreathingExerciseActivity: WellnessGroupActivity {
    public var hostParticipant: WellnessParticipant?
    public var sessionId: UUID?
    public var startTime: Date?
    
    public let maxParticipants: Int = 10
    public let activityType: WellnessActivityType = .breathingExercise
    
    public let breathingPattern: BreathingPattern
    public let duration: TimeInterval
    public let syncedBreathing: Bool
    
    public enum BreathingPattern: String, Sendable {
        case box = "4-4-4-4"
        case triangle = "4-4-8"
        case coherent = "5-5"
        case wim_hof = "wim_hof"
        case custom
    }
    
    public var metadata: GroupActivityMetadata {
        GroupActivityMetadata(
            title: "Group Breathing Exercise",
            type: .generic,
            supportsContinuationOnTV: false
        )
    }
    
    public init(pattern: BreathingPattern, duration: TimeInterval, synced: Bool = true) {
        self.breathingPattern = pattern
        self.duration = duration
        self.syncedBreathing = synced
    }
}

public struct WellnessCheckActivity: WellnessGroupActivity {
    public var hostParticipant: WellnessParticipant?
    public var sessionId: UUID?
    public var startTime: Date?
    
    public let maxParticipants: Int = 12
    public let activityType: WellnessActivityType = .wellnessCheck
    
    public let checkType: CheckType
    public let shareLevel: SharingLevel
    
    public enum CheckType: String, Sendable {
        case daily = "daily"
        case weekly = "weekly"
        case mood = "mood"
        case energy = "energy"
        case sleep = "sleep"
        case stress = "stress"
    }
    
    public enum SharingLevel: String, Sendable {
        case anonymous
        case nameOnly = "name_only"
        case full
    }
    
    public var metadata: GroupActivityMetadata {
        GroupActivityMetadata(
            title: "Wellness Check-in",
            type: .generic,
            supportsContinuationOnTV: false
        )
    }
    
    public init(type: CheckType, sharing: SharingLevel = .nameOnly) {
        self.checkType = type
        self.shareLevel = sharing
    }
}

// MARK: - Supporting Types

public struct WellnessParticipant: Identifiable, Sendable {
    public let id: UUID
    public let name: String
    public let avatar: String?
    public let deviceType: DeviceType
    public let joinedAt: Date
    public let healthSharingLevel: HealthSharingLevel
    
    public enum DeviceType: String, Sendable {
        case iPhone
        case iPad
        case mac = "Mac"
        case appleWatch = "Apple Watch"
        case appleTv = "Apple TV"
        case visionPro = "Vision Pro"
    }
    
    public enum HealthSharingLevel: String, Sendable {
        case none
        case basic  // Heart rate, activity level
        case extended  // + HRV, stress, sleep
        case full  // All available metrics
    }
    
    public static func current() -> WellnessParticipant {
        WellnessParticipant(
            id: UUID(),
            name: "Current User", // Would get from user profile
            avatar: nil,
            deviceType: .iPhone, // Would detect current device
            joinedAt: Date(),
            healthSharingLevel: .basic
        )
    }
}

public struct MetricTarget: Sendable {
    public let metricType: MetricType
    public let targetValue: Double
    public let unit: MetricUnit
    public let description: String
    
    public init(type: MetricType, target: Double, unit: MetricUnit, description: String) {
        self.metricType = type
        self.targetValue = target
        self.unit = unit
        self.description = description
    }
}

public struct GroupHealthInsights: Sendable {
    public let participantCount: Int
    public let averageHeartRate: Double?
    public let averageStressLevel: Double?
    public let groupEnergyLevel: Double
    public let syncScore: Double // How well-synchronized the group is
    public let recommendations: [GroupRecommendation]
    public let timestamp: Date
}

public struct GroupRecommendation: Sendable {
    public let title: String
    public let description: String
    public let actionItems: [String]
    public let priority: Priority
    
    public enum Priority: Int, Sendable {
        case low = 1
        case medium = 2
        case high = 3
    }
}

// MARK: - Group Session Manager

@available(iOS 17.0, macOS 14.0, watchOS 10.0, tvOS 17.0, *)
@MainActor
public class GroupSessionManager: ObservableObject {
    @Published public var activeSessions: [GroupSession<any GroupActivity>] = []
    @Published public var connectionState: SharePlayWellnessCoordinator.ConnectionState = .disconnected
    
    private var sessionObserver: Task<Void, Never>?
    private var logger = OSLog.sharePlay
    
    public init() {
        startSessionObservation()
    }
    
    deinit {
        sessionObserver?.cancel()
    }
    
    private func startSessionObservation() {
        sessionObserver = Task {
            do {
                for await session in GroupSession.$sessions.values {
                    await handleNewSession(session)
                }
            } catch {
                os_log("Error observing group sessions: %@", log: logger, type: .error, error.localizedDescription)
            }
        }
    }
    
    private func handleNewSession(_ session: GroupSession<any GroupActivity>) async {
        activeSessions.append(session)
        connectionState = .connected
        
        // Configure session
        session.join()
        
        // Observe session state changes
        Task {
            for await state in session.$state.values {
                await handleSessionStateChange(state, for: session)
            }
        }
    }
    
    private func handleSessionStateChange(
        _ state: GroupSession<any GroupActivity>.State,
        for session: GroupSession<any GroupActivity>
    ) async {
        switch state {
        case .joined:
            connectionState = .connected
            
        case .invalidated(let reason):
            connectionState = .error("Session invalidated: \(reason)")
            activeSessions.removeAll { $0.id == session.id }
            
        @unknown default:
            break
        }
    }
}

// MARK: - Error Types

public enum SharePlayError: Error, LocalizedError, Sendable {
    case alreadyHosting
    case activationDisabled
    case userCancelled
    case noActiveActivity
    case notConnected
    case unknownError
    case participantLimitReached
    case incompatibleDevice
    case networkError(String)
    
    public var errorDescription: String? {
        switch self {
        case .alreadyHosting:
            return "Already hosting a wellness activity"
        case .activationDisabled:
            return "SharePlay is disabled"
        case .userCancelled:
            return "User cancelled the activity"
        case .noActiveActivity:
            return "No active wellness activity to join"
        case .notConnected:
            return "Not connected to a SharePlay session"
        case .unknownError:
            return "An unknown error occurred"
        case .participantLimitReached:
            return "Maximum number of participants reached"
        case .incompatibleDevice:
            return "Device not compatible with this activity"
        case .networkError(let message):
            return "Network error: \(message)"
        }
    }
}

#endif
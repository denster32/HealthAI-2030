import SwiftUI
import GroupActivities
import Combine
import CloudKit

@available(tvOS 18.0, *)
class GroupSessionManager: NSObject, ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var isSessionActive = false
    @Published var currentSession: GroupHealthSession?
    @Published var participants: [GroupParticipant] = []
    @Published var sessionType: GroupSessionType = .meditation
    @Published var syncedHealthData: [String: ParticipantHealthData] = [:]
    @Published var groupProgress: GroupProgress = GroupProgress()
    @Published var sessionStatistics: GroupSessionStatistics = GroupSessionStatistics()
    
    // MARK: - Private Properties
    
    private var groupSession: GroupSession<GroupHealthActivity>?
    private var messenger: GroupSessionMessenger?
    private var cloudSyncManager: CloudKitSyncManager?
    private var healthDataSyncTimer: Timer?
    private var sessionProgressTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    // Real-time sync
    private var realtimeUpdates: [String: Date] = [:]
    private let maxSyncInterval: TimeInterval = 2.0
    
    // MARK: - Initialization
    
    override init() {
        super.init()
        setupGroupActivities()
        setupCloudSync()
    }
    
    // MARK: - Setup Methods
    
    private func setupGroupActivities() {
        // Observe group session state changes
        GroupSession.$sessions
            .sink { [weak self] sessions in
                self?.handleSessionUpdates(sessions)
            }
            .store(in: &cancellables)
    }
    
    private func setupCloudSync() {
        cloudSyncManager = CloudKitSyncManager()
    }
    
    private func handleSessionUpdates(_ sessions: Set<GroupSession<GroupHealthActivity>>) {
        if let session = sessions.first {
            configureGroupSession(session)
        } else {
            endGroupSession()
        }
    }
    
    // MARK: - Group Session Management
    
    func startGroupSession(type: GroupSessionType, title: String, duration: TimeInterval) async {
        let activity = GroupHealthActivity(
            sessionType: type,
            title: title,
            duration: duration,
            startTime: Date()
        )
        
        do {
            let session = try await activity.prepareForActivation()
            
            DispatchQueue.main.async {
                self.currentSession = GroupHealthSession(
                    id: UUID(),
                    activity: activity,
                    startTime: Date(),
                    duration: duration,
                    sessionType: type
                )
                self.sessionType = type
                
                self.configureGroupSession(session)
            }
            
            try await session.activate()
            
        } catch {
            print("Failed to start group session: \(error)")
        }
    }
    
    private func configureGroupSession(_ session: GroupSession<GroupHealthActivity>) {
        groupSession = session
        messenger = GroupSessionMessenger(session: session)
        
        // Configure session delegate
        session.$state
            .sink { [weak self] state in
                self?.handleSessionStateChange(state)
            }
            .store(in: &cancellables)
        
        // Configure messenger for real-time updates
        setupMessengerHandlers()
        
        isSessionActive = true
        startHealthDataSync()
        startSessionProgress()
    }
    
    private func setupMessengerHandlers() {
        guard let messenger = messenger else { return }
        
        // Handle health data updates
        messenger.receive(HealthDataUpdate.self) { [weak self] update in
            self?.handleHealthDataUpdate(update)
        }
        
        // Handle participant join/leave
        messenger.receive(ParticipantUpdate.self) { [weak self] update in
            self?.handleParticipantUpdate(update)
        }
        
        // Handle session progress updates
        messenger.receive(ProgressUpdate.self) { [weak self] update in
            self?.handleProgressUpdate(update)
        }
    }
    
    private func handleSessionStateChange(_ state: GroupSession<GroupHealthActivity>.State) {
        switch state {
        case .waiting:
            print("Group session waiting for participants...")
            
        case .joined:
            print("Joined group session")
            
        case .invalidated:
            endGroupSession()
            
        @unknown default:
            break
        }
    }
    
    func endGroupSession() {
        isSessionActive = false
        currentSession = nil
        participants.removeAll()
        syncedHealthData.removeAll()
        
        stopHealthDataSync()
        stopSessionProgress()
        
        groupSession?.leave()
        groupSession = nil
        messenger = nil
    }
    
    // MARK: - Health Data Synchronization
    
    private func startHealthDataSync() {
        healthDataSyncTimer = Timer.scheduledTimer(withTimeInterval: maxSyncInterval, repeats: true) { [weak self] _ in
            self?.syncHealthData()
        }
        
        // Initial sync
        syncHealthData()
    }
    
    private func stopHealthDataSync() {
        healthDataSyncTimer?.invalidate()
        healthDataSyncTimer = nil
    }
    
    private func syncHealthData() {
        Task {
            let currentData = await fetchCurrentHealthData()
            
            DispatchQueue.main.async {
                self.broadcastHealthData(currentData)
                self.updateLocalHealthData(currentData)
            }
        }
    }
    
    private func fetchCurrentHealthData() async -> ParticipantHealthData {
        // Simulate fetching current health data
        return ParticipantHealthData(
            participantId: UIDevice.current.identifierForVendor?.uuidString ?? "unknown",
            heartRate: Double.random(in: 65...85),
            hrv: Double.random(in: 30...60),
            stressLevel: Double.random(in: 20...80),
            breathingRate: Double.random(in: 12...20),
            oxygenSaturation: Double.random(in: 95...99),
            activityLevel: Double.random(in: 0.3...1.0),
            timestamp: Date()
        )
    }
    
    private func broadcastHealthData(_ data: ParticipantHealthData) {
        guard let messenger = messenger else { return }
        
        let update = HealthDataUpdate(data: data)
        
        Task {
            do {
                try await messenger.send(update)
            } catch {
                print("Failed to broadcast health data: \(error)")
            }
        }
    }
    
    private func updateLocalHealthData(_ data: ParticipantHealthData) {
        syncedHealthData[data.participantId] = data
        realtimeUpdates[data.participantId] = Date()
        
        // Update group progress
        calculateGroupProgress()
    }
    
    private func handleHealthDataUpdate(_ update: HealthDataUpdate) {
        DispatchQueue.main.async {
            self.syncedHealthData[update.data.participantId] = update.data
            self.realtimeUpdates[update.data.participantId] = Date()
            
            // Update participant list if needed
            self.updateParticipantList()
            
            // Recalculate group progress
            self.calculateGroupProgress()
        }
    }
    
    // MARK: - Participant Management
    
    private func updateParticipantList() {
        var updatedParticipants: [GroupParticipant] = []
        
        for (participantId, healthData) in syncedHealthData {
            if let existingParticipant = participants.first(where: { $0.id == participantId }) {
                var updatedParticipant = existingParticipant
                updatedParticipant.healthData = healthData
                updatedParticipants.append(updatedParticipant)
            } else {
                let newParticipant = GroupParticipant(
                    id: participantId,
                    name: "Participant \(updatedParticipants.count + 1)",
                    healthData: healthData,
                    joinedAt: Date(),
                    isConnected: true
                )
                updatedParticipants.append(newParticipant)
            }
        }
        
        participants = updatedParticipants
    }
    
    private func handleParticipantUpdate(_ update: ParticipantUpdate) {
        DispatchQueue.main.async {
            switch update.action {
            case .joined:
                if !self.participants.contains(where: { $0.id == update.participantId }) {
                    let participant = GroupParticipant(
                        id: update.participantId,
                        name: update.name,
                        healthData: nil,
                        joinedAt: Date(),
                        isConnected: true
                    )
                    self.participants.append(participant)
                }
                
            case .left:
                self.participants.removeAll { $0.id == update.participantId }
                self.syncedHealthData.removeValue(forKey: update.participantId)
            }
        }
    }
    
    // MARK: - Session Progress
    
    private func startSessionProgress() {
        sessionProgressTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateSessionProgress()
        }
    }
    
    private func stopSessionProgress() {
        sessionProgressTimer?.invalidate()
        sessionProgressTimer = nil
    }
    
    private func updateSessionProgress() {
        guard let session = currentSession else { return }
        
        let elapsed = Date().timeIntervalSince(session.startTime)
        let progress = min(elapsed / session.duration, 1.0)
        
        groupProgress.sessionProgress = progress
        
        if progress >= 1.0 {
            completeSession()
        }
        
        // Broadcast progress update
        broadcastProgressUpdate()
    }
    
    private func calculateGroupProgress() {
        guard !syncedHealthData.isEmpty else { return }
        
        let allHeartRates = syncedHealthData.values.compactMap { $0.heartRate }
        let allHRVs = syncedHealthData.values.compactMap { $0.hrv }
        let allStressLevels = syncedHealthData.values.compactMap { $0.stressLevel }
        
        groupProgress.averageHeartRate = allHeartRates.reduce(0, +) / Double(allHeartRates.count)
        groupProgress.averageHRV = allHRVs.reduce(0, +) / Double(allHRVs.count)
        groupProgress.averageStressLevel = allStressLevels.reduce(0, +) / Double(allStressLevels.count)
        
        // Calculate coherence score based on how synchronized the group is
        groupProgress.groupCoherence = calculateGroupCoherence()
    }
    
    private func calculateGroupCoherence() -> Double {
        guard syncedHealthData.count > 1 else { return 1.0 }
        
        let heartRates = syncedHealthData.values.compactMap { $0.heartRate }
        let hrvs = syncedHealthData.values.compactMap { $0.hrv }
        
        // Calculate standard deviation for heart rates and HRV
        let hrStdDev = standardDeviation(heartRates)
        let hrvStdDev = standardDeviation(hrvs)
        
        // Lower standard deviation means better coherence
        let hrCoherence = max(0, 1.0 - (hrStdDev / 20.0)) // Normalize by typical HR range
        let hrvCoherence = max(0, 1.0 - (hrvStdDev / 30.0)) // Normalize by typical HRV range
        
        return (hrCoherence + hrvCoherence) / 2.0
    }
    
    private func standardDeviation(_ values: [Double]) -> Double {
        guard values.count > 1 else { return 0 }
        
        let mean = values.reduce(0, +) / Double(values.count)
        let squaredDifferences = values.map { pow($0 - mean, 2) }
        let variance = squaredDifferences.reduce(0, +) / Double(values.count - 1)
        
        return sqrt(variance)
    }
    
    private func broadcastProgressUpdate() {
        guard let messenger = messenger else { return }
        
        let update = ProgressUpdate(progress: groupProgress)
        
        Task {
            do {
                try await messenger.send(update)
            } catch {
                print("Failed to broadcast progress update: \(error)")
            }
        }
    }
    
    private func handleProgressUpdate(_ update: ProgressUpdate) {
        DispatchQueue.main.async {
            // Update group progress with remote data
            self.groupProgress = update.progress
        }
    }
    
    // MARK: - Session Completion
    
    private func completeSession() {
        generateSessionStatistics()
        saveSessionToCloud()
        
        // Keep session active for review
        sessionProgressTimer?.invalidate()
        sessionProgressTimer = nil
    }
    
    private func generateSessionStatistics() {
        guard let session = currentSession else { return }
        
        sessionStatistics = GroupSessionStatistics(
            sessionId: session.id,
            sessionType: session.sessionType,
            duration: session.duration,
            participantCount: participants.count,
            averageHeartRate: groupProgress.averageHeartRate,
            averageHRV: groupProgress.averageHRV,
            averageStressReduction: calculateStressReduction(),
            groupCoherenceScore: groupProgress.groupCoherence,
            completionRate: groupProgress.sessionProgress,
            participantEngagement: calculateParticipantEngagement(),
            healthImprovementScore: calculateHealthImprovementScore()
        )
    }
    
    private func calculateStressReduction() -> Double {
        // Calculate stress reduction throughout the session
        // This would typically compare initial vs final stress levels
        return Double.random(in: 0.15...0.45) // Simulated for now
    }
    
    private func calculateParticipantEngagement() -> Double {
        // Calculate based on how consistently participants provided data
        let totalUpdatesExpected = participants.count * Int(currentSession?.duration ?? 0) / Int(maxSyncInterval)
        let actualUpdates = realtimeUpdates.count
        
        return min(Double(actualUpdates) / Double(totalUpdatesExpected), 1.0)
    }
    
    private func calculateHealthImprovementScore() -> Double {
        // Calculate overall health improvement based on various metrics
        let coherenceScore = groupProgress.groupCoherence
        let stressReduction = calculateStressReduction()
        let engagement = calculateParticipantEngagement()
        
        return (coherenceScore + stressReduction + engagement) / 3.0
    }
    
    // MARK: - Cloud Sync
    
    private func saveSessionToCloud() {
        Task {
            await cloudSyncManager?.saveGroupSession(sessionStatistics)
        }
    }
    
    // MARK: - Public Interface
    
    func joinExistingSession() async {
        // This would be called when the user wants to join an existing session
        // GroupActivities will handle the invitation flow
    }
    
    func inviteParticipants() async {
        guard let activity = currentSession?.activity else { return }
        
        do {
            try await activity.prepareForActivation().activate()
        } catch {
            print("Failed to invite participants: \(error)")
        }
    }
    
    func getParticipantData(for participantId: String) -> ParticipantHealthData? {
        return syncedHealthData[participantId]
    }
    
    func getCurrentGroupMetrics() -> GroupMetrics {
        return GroupMetrics(
            participantCount: participants.count,
            averageHeartRate: groupProgress.averageHeartRate,
            averageHRV: groupProgress.averageHRV,
            groupCoherence: groupProgress.groupCoherence,
            sessionProgress: groupProgress.sessionProgress
        )
    }
}

// MARK: - Supporting Types

enum GroupSessionType: String, CaseIterable {
    case meditation = "meditation"
    case breathingExercise = "breathing"
    case fitness = "fitness"
    case mindfulness = "mindfulness"
    case stressRelief = "stress_relief"
    
    var displayName: String {
        switch self {
        case .meditation: return "Group Meditation"
        case .breathingExercise: return "Breathing Exercise"
        case .fitness: return "Group Fitness"
        case .mindfulness: return "Mindfulness Practice"
        case .stressRelief: return "Stress Relief"
        }
    }
    
    var icon: String {
        switch self {
        case .meditation: return "leaf.fill"
        case .breathingExercise: return "wind"
        case .fitness: return "figure.run"
        case .mindfulness: return "brain.head.profile"
        case .stressRelief: return "heart.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .meditation: return .green
        case .breathingExercise: return .blue
        case .fitness: return .orange
        case .mindfulness: return .purple
        case .stressRelief: return .pink
        }
    }
}

struct GroupHealthActivity: GroupActivity {
    static let activityIdentifier = "com.healthai2030.grouphealth"
    
    let sessionType: GroupSessionType
    let title: String
    let duration: TimeInterval
    let startTime: Date
    
    var metadata: GroupActivityMetadata {
        var metadata = GroupActivityMetadata()
        metadata.title = title
        metadata.subtitle = sessionType.displayName
        metadata.type = .generic
        return metadata
    }
}

struct GroupHealthSession {
    let id: UUID
    let activity: GroupHealthActivity
    let startTime: Date
    let duration: TimeInterval
    let sessionType: GroupSessionType
}

struct GroupParticipant: Identifiable {
    let id: String
    var name: String
    var healthData: ParticipantHealthData?
    let joinedAt: Date
    var isConnected: Bool
}

struct ParticipantHealthData: Codable {
    let participantId: String
    let heartRate: Double
    let hrv: Double
    let stressLevel: Double
    let breathingRate: Double
    let oxygenSaturation: Double
    let activityLevel: Double
    let timestamp: Date
}

struct GroupProgress {
    var sessionProgress: Double = 0.0
    var averageHeartRate: Double = 0.0
    var averageHRV: Double = 0.0
    var averageStressLevel: Double = 0.0
    var groupCoherence: Double = 0.0
}

struct GroupSessionStatistics {
    let sessionId: UUID
    let sessionType: GroupSessionType
    let duration: TimeInterval
    let participantCount: Int
    let averageHeartRate: Double
    let averageHRV: Double
    let averageStressReduction: Double
    let groupCoherenceScore: Double
    let completionRate: Double
    let participantEngagement: Double
    let healthImprovementScore: Double
    
    init() {
        self.sessionId = UUID()
        self.sessionType = .meditation
        self.duration = 0
        self.participantCount = 0
        self.averageHeartRate = 0
        self.averageHRV = 0
        self.averageStressReduction = 0
        self.groupCoherenceScore = 0
        self.completionRate = 0
        self.participantEngagement = 0
        self.healthImprovementScore = 0
    }
    
    init(sessionId: UUID, sessionType: GroupSessionType, duration: TimeInterval, participantCount: Int, averageHeartRate: Double, averageHRV: Double, averageStressReduction: Double, groupCoherenceScore: Double, completionRate: Double, participantEngagement: Double, healthImprovementScore: Double) {
        self.sessionId = sessionId
        self.sessionType = sessionType
        self.duration = duration
        self.participantCount = participantCount
        self.averageHeartRate = averageHeartRate
        self.averageHRV = averageHRV
        self.averageStressReduction = averageStressReduction
        self.groupCoherenceScore = groupCoherenceScore
        self.completionRate = completionRate
        self.participantEngagement = participantEngagement
        self.healthImprovementScore = healthImprovementScore
    }
}

struct GroupMetrics {
    let participantCount: Int
    let averageHeartRate: Double
    let averageHRV: Double
    let groupCoherence: Double
    let sessionProgress: Double
}

// MARK: - Message Types

struct HealthDataUpdate: Codable {
    let data: ParticipantHealthData
}

struct ParticipantUpdate: Codable {
    let participantId: String
    let name: String
    let action: ParticipantAction
    
    enum ParticipantAction: String, Codable {
        case joined
        case left
    }
}

struct ProgressUpdate: Codable {
    let progress: GroupProgress
}

// MARK: - Cloud Sync Manager

class CloudKitSyncManager {
    private let container = CKContainer.default()
    private let database = CKContainer.default().publicCloudDatabase
    
    func saveGroupSession(_ statistics: GroupSessionStatistics) async {
        let record = CKRecord(recordType: "GroupSession")
        record["sessionId"] = statistics.sessionId.uuidString
        record["sessionType"] = statistics.sessionType.rawValue
        record["duration"] = statistics.duration
        record["participantCount"] = statistics.participantCount
        record["averageHeartRate"] = statistics.averageHeartRate
        record["averageHRV"] = statistics.averageHRV
        record["groupCoherenceScore"] = statistics.groupCoherenceScore
        record["completionRate"] = statistics.completionRate
        record["timestamp"] = Date()
        
        do {
            _ = try await database.save(record)
            print("Group session saved to CloudKit")
        } catch {
            print("Failed to save group session: \(error)")
        }
    }
    
    func fetchGroupSessions() async -> [GroupSessionStatistics] {
        let query = CKQuery(recordType: "GroupSession", predicate: NSPredicate(value: true))
        query.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
        
        do {
            let result = try await database.records(matching: query)
            return result.matchResults.compactMap { _, result in
                switch result {
                case .success(let record):
                    return parseGroupSessionRecord(record)
                case .failure:
                    return nil
                }
            }
        } catch {
            print("Failed to fetch group sessions: \(error)")
            return []
        }
    }
    
    private func parseGroupSessionRecord(_ record: CKRecord) -> GroupSessionStatistics? {
        guard let sessionIdString = record["sessionId"] as? String,
              let sessionId = UUID(uuidString: sessionIdString),
              let sessionTypeString = record["sessionType"] as? String,
              let sessionType = GroupSessionType(rawValue: sessionTypeString),
              let duration = record["duration"] as? Double,
              let participantCount = record["participantCount"] as? Int,
              let averageHeartRate = record["averageHeartRate"] as? Double,
              let averageHRV = record["averageHRV"] as? Double,
              let groupCoherenceScore = record["groupCoherenceScore"] as? Double,
              let completionRate = record["completionRate"] as? Double else {
            return nil
        }
        
        return GroupSessionStatistics(
            sessionId: sessionId,
            sessionType: sessionType,
            duration: duration,
            participantCount: participantCount,
            averageHeartRate: averageHeartRate,
            averageHRV: averageHRV,
            averageStressReduction: 0, // Not stored in this example
            groupCoherenceScore: groupCoherenceScore,
            completionRate: completionRate,
            participantEngagement: 0, // Not stored in this example
            healthImprovementScore: 0 // Not stored in this example
        )
    }
}

// MARK: - SwiftUI Views

@available(tvOS 18.0, *)
struct GroupSessionView: View {
    @StateObject private var sessionManager = GroupSessionManager()
    @State private var selectedSessionType: GroupSessionType = .meditation
    @State private var sessionTitle = ""
    @State private var sessionDuration: Double = 600 // 10 minutes
    @State private var showingSessionSetup = false
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                gradient: Gradient(colors: [Color.black.opacity(0.8), Color.purple.opacity(0.3)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            if sessionManager.isSessionActive {
                ActiveGroupSessionView(sessionManager: sessionManager)
            } else {
                SessionSetupView(
                    sessionManager: sessionManager,
                    selectedSessionType: $selectedSessionType,
                    sessionTitle: $sessionTitle,
                    sessionDuration: $sessionDuration,
                    showingSessionSetup: $showingSessionSetup
                )
            }
        }
    }
}

struct SessionSetupView: View {
    let sessionManager: GroupSessionManager
    @Binding var selectedSessionType: GroupSessionType
    @Binding var sessionTitle: String
    @Binding var sessionDuration: Double
    @Binding var showingSessionSetup: Bool
    
    var body: some View {
        VStack(spacing: 30) {
            // Header
            VStack(spacing: 15) {
                Text("Group Health Sessions")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Connect with others for shared wellness experiences")
                    .font(.title2)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
            
            // Session Type Selection
            VStack(spacing: 20) {
                Text("Choose Session Type")
                    .font(.title)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 20) {
                    ForEach(GroupSessionType.allCases, id: \.self) { sessionType in
                        SessionTypeCard(
                            sessionType: sessionType,
                            isSelected: selectedSessionType == sessionType
                        ) {
                            selectedSessionType = sessionType
                            sessionTitle = sessionType.displayName
                        }
                    }
                }
            }
            .padding()
            .background(Color.white.opacity(0.1))
            .cornerRadius(20)
            
            // Session Configuration
            VStack(spacing: 15) {
                Text("Duration: \(Int(sessionDuration / 60)) minutes")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Slider(value: $sessionDuration, in: 300...1800, step: 300)
                    .accentColor(selectedSessionType.color)
            }
            .padding()
            .background(Color.white.opacity(0.1))
            .cornerRadius(15)
            
            Spacer()
            
            // Action Buttons
            HStack(spacing: 20) {
                Button("Start Session") {
                    Task {
                        await sessionManager.startGroupSession(
                            type: selectedSessionType,
                            title: sessionTitle,
                            duration: sessionDuration
                        )
                    }
                }
                .buttonStyle(GroupSessionButtonStyle(color: selectedSessionType.color))
                
                Button("Join Session") {
                    Task {
                        await sessionManager.joinExistingSession()
                    }
                }
                .buttonStyle(GroupSessionButtonStyle(color: .gray))
            }
        }
        .padding()
    }
}

struct SessionTypeCard: View {
    let sessionType: GroupSessionType
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 15) {
                Image(systemName: sessionType.icon)
                    .font(.largeTitle)
                    .foregroundColor(sessionType.color)
                
                Text(sessionType.displayName)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
            }
            .frame(height: 120)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(isSelected ? sessionType.color.opacity(0.2) : Color.white.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(isSelected ? sessionType.color : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

struct ActiveGroupSessionView: View {
    @ObservedObject var sessionManager: GroupSessionManager
    
    var body: some View {
        VStack(spacing: 30) {
            // Session Header
            VStack(spacing: 10) {
                Text(sessionManager.currentSession?.activity.title ?? "Group Session")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Session Progress: \(Int(sessionManager.groupProgress.sessionProgress * 100))%")
                    .font(.title2)
                    .foregroundColor(.gray)
                
                ProgressView(value: sessionManager.groupProgress.sessionProgress)
                    .progressViewStyle(LinearProgressViewStyle(tint: sessionManager.sessionType.color))
                    .frame(width: 400)
            }
            
            // Participants Grid
            ParticipantsGridView(sessionManager: sessionManager)
            
            // Group Metrics
            GroupMetricsView(sessionManager: sessionManager)
            
            Spacer()
            
            // Session Controls
            HStack(spacing: 20) {
                Button("Invite More") {
                    Task {
                        await sessionManager.inviteParticipants()
                    }
                }
                .buttonStyle(GroupSessionButtonStyle(color: .blue))
                
                Button("End Session") {
                    sessionManager.endGroupSession()
                }
                .buttonStyle(GroupSessionButtonStyle(color: .red))
            }
        }
        .padding()
    }
}

struct ParticipantsGridView: View {
    @ObservedObject var sessionManager: GroupSessionManager
    
    var body: some View {
        VStack(spacing: 15) {
            Text("Participants (\(sessionManager.participants.count))")
                .font(.title)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 15) {
                ForEach(sessionManager.participants, id: \.id) { participant in
                    ParticipantCard(participant: participant, sessionManager: sessionManager)
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(20)
    }
}

struct ParticipantCard: View {
    let participant: GroupParticipant
    @ObservedObject var sessionManager: GroupSessionManager
    
    var body: some View {
        VStack(spacing: 10) {
            // Participant Info
            VStack(spacing: 5) {
                Circle()
                    .fill(participant.isConnected ? Color.green : Color.gray)
                    .frame(width: 60, height: 60)
                    .overlay(
                        Text(String(participant.name.prefix(2)))
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    )
                
                Text(participant.name)
                    .font(.headline)
                    .foregroundColor(.white)
                    .lineLimit(1)
            }
            
            // Health Data
            if let healthData = participant.healthData {
                VStack(spacing: 5) {
                    HStack {
                        Image(systemName: "heart.fill")
                            .foregroundColor(.red)
                            .font(.caption)
                        
                        Text("\(Int(healthData.heartRate)) BPM")
                            .font(.caption)
                            .foregroundColor(.white)
                    }
                    
                    HStack {
                        Image(systemName: "waveform.path.ecg")
                            .foregroundColor(.green)
                            .font(.caption)
                        
                        Text("\(String(format: "%.1f", healthData.hrv)) ms")
                            .font(.caption)
                            .foregroundColor(.white)
                    }
                    
                    HStack {
                        Image(systemName: "brain.head.profile")
                            .foregroundColor(.purple)
                            .font(.caption)
                        
                        Text("\(Int(healthData.stressLevel))%")
                            .font(.caption)
                            .foregroundColor(.white)
                    }
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(15)
    }
}

struct GroupMetricsView: View {
    @ObservedObject var sessionManager: GroupSessionManager
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Group Metrics")
                .font(.title)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            HStack(spacing: 30) {
                MetricDisplayCard(
                    title: "Avg Heart Rate",
                    value: "\(Int(sessionManager.groupProgress.averageHeartRate)) BPM",
                    icon: "heart.fill",
                    color: .red
                )
                
                MetricDisplayCard(
                    title: "Avg HRV",
                    value: "\(String(format: "%.1f", sessionManager.groupProgress.averageHRV)) ms",
                    icon: "waveform.path.ecg",
                    color: .green
                )
                
                MetricDisplayCard(
                    title: "Group Coherence",
                    value: "\(Int(sessionManager.groupProgress.groupCoherence * 100))%",
                    icon: "link.circle.fill",
                    color: .blue
                )
                
                MetricDisplayCard(
                    title: "Avg Stress",
                    value: "\(Int(sessionManager.groupProgress.averageStressLevel))%",
                    icon: "brain.head.profile",
                    color: .purple
                )
            }
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(20)
    }
}

struct MetricDisplayCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
    }
}

struct GroupSessionButtonStyle: ButtonStyle {
    let color: Color
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.white)
            .font(.headline)
            .fontWeight(.semibold)
            .frame(width: 200, height: 50)
            .background(color)
            .cornerRadius(10)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

#Preview {
    GroupSessionView()
}
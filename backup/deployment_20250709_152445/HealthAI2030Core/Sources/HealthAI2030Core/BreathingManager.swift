import Foundation
import Combine

@MainActor
public class BreathingManager: ObservableObject {
    public static let shared = BreathingManager()
    @Published public var sessions: [BreathingSession] = []
    @Published public var errors: [Error] = []
    @Published public var currentSession: BreathingSession?
    
    private let userDefaults = UserDefaults.standard
    private let sessionsKey = "BreathingSessions"
    
    private init() {
        loadPreviousSessions()
    }
    
    private func loadPreviousSessions() {
        if let data = userDefaults.data(forKey: sessionsKey),
           let decodedSessions = try? JSONDecoder().decode([BreathingSession].self, from: data) {
            sessions = decodedSessions
        }
    }
    
    private func saveSessions() {
        if let encoded = try? JSONEncoder().encode(sessions) {
            userDefaults.set(encoded, forKey: sessionsKey)
        }
    }
    
    public func startSession(duration: TimeInterval, pattern: String) {
        let session = BreathingSession(
            id: UUID(),
            startTime: Date(),
            duration: duration,
            pattern: pattern,
            status: .active
        )
        currentSession = session
    }
    
    public func endSession() {
        guard var session = currentSession else { return }
        
        session.endTime = Date()
        session.status = .completed
        session.actualDuration = session.endTime?.timeIntervalSince(session.startTime) ?? 0
        
        sessions.append(session)
        saveSessions()
        currentSession = nil
    }
}

public struct BreathingSession: Codable, Identifiable {
    public let id: UUID
    public let startTime: Date
    public var endTime: Date?
    public let duration: TimeInterval
    public let pattern: String
    public var status: SessionStatus
    public var actualDuration: TimeInterval?
    
    public enum SessionStatus: String, Codable {
        case active
        case completed
        case cancelled
    }
}

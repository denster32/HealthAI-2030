import Foundation

/// Represents a stage of sleep, used for classification and analytics.
public enum SleepStage: Int, CaseIterable {
    case awake = 0
    case light = 1
    case deep = 2
    case rem = 3
    
    /// A user-friendly display name for the sleep stage.
    public var displayName: String {
        switch self {
        case .awake: return NSLocalizedString("Awake", comment: "Sleep stage")
        case .light: return NSLocalizedString("Light Sleep", comment: "Sleep stage")
        case .deep: return NSLocalizedString("Deep Sleep", comment: "Sleep stage")
        case .rem: return NSLocalizedString("REM Sleep", comment: "Sleep stage")
        }
    }
    
    /// Color representation for UI
    public var color: Color {
        switch self {
        case .awake: return Color(red: 0.96, green: 0.81, blue: 0.26) // Yellow
        case .light: return Color(red: 0.30, green: 0.69, blue: 0.31) // Green
        case .deep: return Color(red: 0.13, green: 0.59, blue: 0.95) // Blue
        case .rem: return Color(red: 0.61, green: 0.15, blue: 0.69) // Purple
        }
    }
    
    /// SF Symbol name for icon representation
    public var iconName: String {
        switch self {
        case .awake: return "sun.max.fill"
        case .light: return "moon.fill"
        case .deep: return "moon.zzz.fill"
        case .rem: return "brain.head.profile"
        }
    }
}

/// Represents a transition between sleep stages at a specific time, with confidence score.
///
/// - Parameters:
///   - timestamp: The time of the stage change.
///   - from: The previous sleep stage.
///   - to: The new sleep stage.
///   - confidence: Confidence score (0.0 - 1.0) for the transition.
public struct SleepStageChange {
    public let timestamp: Date
    public let from: SleepStage
    public let to: SleepStage
    public let confidence: Double

    public init(timestamp: Date, from: SleepStage, to: SleepStage, confidence: Double) {
        self.timestamp = timestamp
        self.from = from
        self.to = to
        self.confidence = confidence
    }
    /// Device/source that detected the stage change
    public let source: SleepTrackingSource
    
    /// Associated sleep session ID
    public let sessionID: UUID?
    
    public init(timestamp: Date, from: SleepStage, to: SleepStage, confidence: Double,
                source: SleepTrackingSource = .unknown, sessionID: UUID? = nil) {
        self.timestamp = timestamp
        self.from = from
        self.to = to
        self.confidence = confidence
        self.source = source
        self.sessionID = sessionID
    }
}
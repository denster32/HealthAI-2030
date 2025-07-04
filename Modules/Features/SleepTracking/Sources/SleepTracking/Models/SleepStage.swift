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
        case .awake: return "Awake"
        case .light: return "Light Sleep"
        case .deep: return "Deep Sleep"
        case .rem: return "REM Sleep"
        }
    }
    // TODO: Localize displayName for internationalization support.
    // TODO: Add color or icon for each stage for UI use.
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
    // TODO: Add source/device metadata for provenance.
    // TODO: Link to SleepSession for context.
}
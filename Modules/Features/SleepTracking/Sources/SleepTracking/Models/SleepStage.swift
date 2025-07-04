import Foundation

public enum SleepStage: Int, CaseIterable {
    case awake = 0
    case light = 1
    case deep = 2
    case rem = 3
    
    public var displayName: String {
        switch self {
        case .awake: return "Awake"
        case .light: return "Light Sleep"
        case .deep: return "Deep Sleep"
        case .rem: return "REM Sleep"
        }
    }
}

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
}
import Foundation

public struct SleepMetrics {
    public var totalSleepTime: TimeInterval
    public var deepSleepTime: TimeInterval
    public var remSleepTime: TimeInterval
    public var lightSleepTime: TimeInterval
    public var awakeTime: TimeInterval
    public var interventions: [NudgeAction]

    public init(totalSleepTime: TimeInterval = 0, deepSleepTime: TimeInterval = 0, remSleepTime: TimeInterval = 0, lightSleepTime: TimeInterval = 0, awakeTime: TimeInterval = 0, interventions: [NudgeAction] = []) {
        self.totalSleepTime = totalSleepTime
        self.deepSleepTime = deepSleepTime
        self.remSleepTime = remSleepTime
        self.lightSleepTime = lightSleepTime
        self.awakeTime = awakeTime
        self.interventions = interventions
    }
    
    public var deepSleepPercentage: Double {
        guard totalSleepTime > 0 else { return 0 }
        return deepSleepTime / totalSleepTime
    }
    
    public var remSleepPercentage: Double {
        guard totalSleepTime > 0 else { return 0 }
        return remSleepTime / totalSleepTime
    }
    
    public var lightSleepPercentage: Double {
        guard totalSleepTime > 0 else { return 0 }
        return lightSleepTime / totalSleepTime
    }
    
    public var awakePercentage: Double {
        guard totalSleepTime > 0 else { return 0 }
        return awakeTime / totalSleepTime
    }
    
    public mutating func addTime(_ time: TimeInterval, to stage: SleepStageType) {
        switch stage {
        case .deepSleep:
            deepSleepTime += time
        case .remSleep:
            remSleepTime += time
        case .lightSleep:
            lightSleepTime += time
        case .awake:
            awakeTime += time
        case .unknown:
            awakeTime += time
        }
        totalSleepTime += time
    }
}
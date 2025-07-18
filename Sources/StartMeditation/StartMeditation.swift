import Foundation
import AppIntents
import MentalHealth // Add this import to resolve MentalHealthManager and MindfulnessType

// MARK: - Core Meditation Logic

@available(iOS 17.0, macOS 14.0, *)
public class MeditationManager {
    private let mentalHealthManager: MentalHealthManager

    public init(mentalHealthManager: MentalHealthManager = MentalHealthManager.shared) {
        self.mentalHealthManager = mentalHealthManager
    }

    public func startMeditation(type: MeditationType, duration: TimeInterval) async {
        // In a real app, this would trigger the meditation UI and session
        print("Starting \(type.displayName) meditation for \(duration / 60) minutes.")

        // For now, we'll just record the session immediately
        await mentalHealthManager.startMindfulnessSession(type: type.toMindfulnessType())
        // In a real implementation, we would end the session after the duration has passed.
        // For this refactoring, we'll simulate the completion.
        await mentalHealthManager.endMindfulnessSession()
    }
}

// MARK: - App Intent

@available(iOS 18.0, *)
public struct StartMeditationAppIntent: AppIntent {
    public static var title: LocalizedStringResource = "Start Meditation"
    public static var description = IntentDescription("Starts a guided meditation session.")

    @Parameter(title: "Type", description: "The type of meditation to perform.")
    public var type: MeditationTypeAppEnum

    @Parameter(title: "Duration", description: "The duration of the session in minutes.")
    public var duration: Double

    public init() {
        self.type = .mindfulness
        self.duration = 5.0
    }

    public init(type: MeditationTypeAppEnum, duration: Double) {
        self.type = type
        self.duration = duration
    }

    public func perform() async throws -> IntentResult {
        let meditationManager = MeditationManager()
        let durationInSeconds = duration * 60
        await meditationManager.startMeditation(type: MeditationType(from: type), duration: durationInSeconds)
        let result = "Started a \(duration)-minute \(type.rawValue) meditation."
        return .result(value: result)
    }
}

// MARK: - Supporting Enums

public enum MeditationType: String, CaseIterable {
    case mindfulness
    case lovingKindness
    case bodyScan
    case breathAwareness
    case transcendental

    public var displayName: String {
        return self.rawValue.prefix(1).capitalized + self.rawValue.dropFirst()
    }

    func toMindfulnessType() -> MindfulnessType {
        switch self {
        case .mindfulness: return .meditation
        case .lovingKindness: return .lovingKindness
        case .bodyScan: return .bodyScan
        case .breathAwareness: return .breathing
        case .transcendental: return .meditation // Map to general meditation
        }
    }

    init(from appEnum: MeditationTypeAppEnum) {
        self = MeditationType(rawValue: appEnum.rawValue) ?? .mindfulness
    }
}

public enum MeditationTypeAppEnum: String, AppEnum {
    case mindfulness
    case lovingKindness
    case bodyScan
    case breathAwareness
    case transcendental

    public static var typeDisplayRepresentation: TypeDisplayRepresentation = "Meditation Type"
    public static var caseDisplayRepresentations: [MeditationTypeAppEnum: DisplayRepresentation] = [
        .mindfulness: "Mindfulness",
        .lovingKindness: "Loving Kindness",
        .bodyScan: "Body Scan",
        .breathAwareness: "Breath Awareness",
        .transcendental: "Transcendental"
    ]
}
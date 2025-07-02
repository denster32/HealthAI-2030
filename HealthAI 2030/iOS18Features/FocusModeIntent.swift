import AppIntents
import Foundation

struct FocusModeIntent: AppIntent {
    static var title: LocalizedStringResource = "Activate Health Focus Mode"
    static var description = IntentDescription("Activates a specific health-aware focus mode.")

    @Parameter(title: "Focus Mode Name", description: "The name of the focus mode to activate (e.g., 'Health Monitoring', 'Sleep Preparation').")
    var focusModeName: String

    @Parameter(title: "Health Aware", description: "Whether the focus mode should apply health-aware filters.", defaultValue: true)
    var healthAware: Bool

    static var parameterSummary: some ParameterSummary {
        Summary("Activate \(\.$focusModeName) focus mode") {
            \.$healthAware
        }
    }

    func perform() async throws -> some IntentResult {
        // In a real application, this would interact with the FocusModeManager
        // to activate the specified focus mode and apply health-aware filters.
        // For now, we'll just print a message.
        print("Attempting to activate focus mode: \(focusModeName) with health-aware filters: \(healthAware)")
        
        // You would typically call a manager function here, e.g.:
        // await FocusModeManager.shared.activateFocusMode(byName: focusModeName, healthAware: healthAware)
        
        return .result(value: "Focus mode '\(focusModeName)' activation initiated.")
    }
}
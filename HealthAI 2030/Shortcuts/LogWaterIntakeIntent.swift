import AppIntents

struct LogWaterIntakeIntent: AppIntent {
    static var title: LocalizedStringResource = "Log Water Intake"
    func perform() async throws -> some IntentResult {
        // TODO: Log water intake
        return .result()
    }
}

import AppIntents

struct HealthSummaryIntent: AppIntent {
    static var title: LocalizedStringResource = "Show Health Summary"
    func perform() async throws -> some IntentResult {
        // TODO: Implement summary logic
        return .result()
    }
}

import AppIntents

struct StartMeditationIntent: AppIntent {
    static var title: LocalizedStringResource = "Start Meditation"
    func perform() async throws -> some IntentResult {
        // TODO: Start a meditation session
        return .result()
    }
}

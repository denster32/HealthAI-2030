import AppIntents

struct LogWaterIntakeIntent: AppIntent {
    static var title: LocalizedStringResource = "Log Water Intake"
    @Parameter(title: "Amount (ml)") var amount: Int
    func perform() async throws -> some IntentResult {
        // Integrate with health data store
        return .result()
    }
}

struct LogWaterIntakeShortcut: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(intent: LogWaterIntakeIntent(), phrases: ["Log water intake of \(.amount) ml"])
    }
}

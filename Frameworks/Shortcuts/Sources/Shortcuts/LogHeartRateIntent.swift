import AppIntents

struct LogHeartRateIntent: AppIntent {
    static var title: LocalizedStringResource = "Log Heart Rate"
    @Parameter(title: "Heart Rate (bpm)") var heartRate: Int
    func perform() async throws -> some IntentResult {
        // Integrate with health data store
        return .result()
    }
}

struct LogHeartRateShortcut: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(intent: LogHeartRateIntent(), phrases: ["Log heart rate of \(.heartRate) bpm"])
    }
}

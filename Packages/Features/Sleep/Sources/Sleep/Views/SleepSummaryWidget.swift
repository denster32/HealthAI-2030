import WidgetKit
import SwiftUI

/// Timeline entry for the sleep summary widget.
struct SleepSummaryEntry: TimelineEntry {
    let date: Date
    let summary: String
}

/// Provides timeline entries for the sleep summary widget.
struct SleepSummaryProvider: TimelineProvider {
    func placeholder(in context: Context) -> SleepSummaryEntry {
        SleepSummaryEntry(date: Date(), summary: "Sample Sleep Data")
    }
    func getSnapshot(in context: Context, completion: @escaping (SleepSummaryEntry) -> ()) {
        completion(SleepSummaryEntry(date: Date(), summary: "Snapshot Sleep Data"))
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<SleepSummaryEntry>) -> ()) {
        let realSummary = fetchRealSleepSummary()
        let entries = [SleepSummaryEntry(date: Date(), summary: realSummary)]
        completion(Timeline(entries: entries, policy: .atEnd))
    }
}

/// The main view for the sleep summary widget.
struct SleepSummaryWidgetEntryView: View {
    var entry: SleepSummaryProvider.Entry
    var body: some View {
        Text(entry.summary)
            .font(.headline)
            .accessibilityLabel(Text("Sleep summary: \(entry.summary)"))
            .dynamicTypeSize(.large ... .accessibility3)
            .foregroundColor(.primary)
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(8)
            .accessibilityAddTraits(.isSummaryElement)
            .accessibilityElement(children: .combine)
            .accessibilityHint(Text("Summary of your most recent sleep session"))
            .accessibilityIdentifier("SleepSummaryWidget")
    }
}

/// Widget extension for displaying a summary of sleep data.
@main
struct SleepSummaryWidget: Widget {
    let kind: String = "SleepSummaryWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SleepSummaryProvider()) { entry in
            SleepSummaryWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Sleep Summary")
        .description("Shows a summary of your sleep data.")
    }
}

private func fetchRealSleepSummary() -> String {
    // Placeholder: Replace with actual data fetch logic
    return NSLocalizedString("You slept 7h 45m. Deep: 22% REM: 18%", comment: "Sleep summary")
}
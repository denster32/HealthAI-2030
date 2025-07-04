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
        let entries = [SleepSummaryEntry(date: Date(), summary: "Timeline Sleep Data")]
        completion(Timeline(entries: entries, policy: .atEnd))
    }
    // TODO: Integrate with real sleep data source.
}

/// The main view for the sleep summary widget.
struct SleepSummaryWidgetEntryView: View {
    var entry: SleepSummaryProvider.Entry
    var body: some View {
        Text(entry.summary)
            .font(.headline)
            .accessibilityLabel("Sleep summary: \(entry.summary)")
    }
    // TODO: Add richer UI and accessibility support.
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
// TODO: Add localization, dynamic type, and real data integration.
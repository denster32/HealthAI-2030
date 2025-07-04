import WidgetKit
import SwiftUI

struct SleepSummaryEntry: TimelineEntry {
    let date: Date
    let summary: String
}

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
}

struct SleepSummaryWidgetEntryView: View {
    var entry: SleepSummaryProvider.Entry
    var body: some View {
        Text(entry.summary)
    }
}

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
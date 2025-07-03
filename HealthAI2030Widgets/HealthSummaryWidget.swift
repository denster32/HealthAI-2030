import WidgetKit
import SwiftUI

struct HealthSummaryEntry: TimelineEntry {
    let date: Date
    let summary: String
}

struct HealthSummaryProvider: TimelineProvider {
    func placeholder(in context: Context) -> HealthSummaryEntry {
        HealthSummaryEntry(date: Date(), summary: "Sample Health Data")
    }
    func getSnapshot(in context: Context, completion: @escaping (HealthSummaryEntry) -> ()) {
        completion(HealthSummaryEntry(date: Date(), summary: "Snapshot Health Data"))
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<HealthSummaryEntry>) -> ()) {
        let entries = [HealthSummaryEntry(date: Date(), summary: "Timeline Health Data")]
        completion(Timeline(entries: entries, policy: .atEnd))
    }
}

struct HealthSummaryWidgetEntryView: View {
    var entry: HealthSummaryProvider.Entry
    var body: some View {
        Text(entry.summary)
    }
}

@main
struct HealthSummaryWidget: Widget {
    let kind: String = "HealthSummaryWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: HealthSummaryProvider()) { entry in
            HealthSummaryWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Health Summary")
        .description("Shows a summary of your health data.")
    }
}

import WidgetKit
import SwiftUI

struct HealthSummaryWidgetEntry: TimelineEntry {
    let date: Date
    let summary: String
}

struct HealthSummaryWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> HealthSummaryWidgetEntry {
        HealthSummaryWidgetEntry(date: Date(), summary: "Sleep: 7h, Steps: 10k")
    }
    func getSnapshot(in context: Context, completion: @escaping (HealthSummaryWidgetEntry) -> ()) {
        completion(placeholder(in: context))
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<HealthSummaryWidgetEntry>) -> ()) {
        let entry = HealthSummaryWidgetEntry(date: Date(), summary: "Sleep: 7h, Steps: 10k")
        let timeline = Timeline(entries: [entry], policy: .atEnd)
        completion(timeline)
    }
}

struct HealthSummaryWidgetEntryView: View {
    var entry: HealthSummaryWidgetProvider.Entry
    var body: some View {
        VStack {
            Text(entry.summary)
                .font(.headline)
            Text(entry.date, style: .time)
                .font(.caption)
        }
        .padding()
    }
}

@main
struct HealthSummaryWidget: Widget {
    let kind: String = "HealthSummaryWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: HealthSummaryWidgetProvider()) { entry in
            HealthSummaryWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Health Summary")
        .description("Shows your latest health stats.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

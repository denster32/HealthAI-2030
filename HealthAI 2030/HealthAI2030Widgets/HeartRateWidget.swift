import WidgetKit
import SwiftUI

struct HeartRateWidgetEntry: TimelineEntry {
    let date: Date
    let heartRate: Int
}

struct HeartRateWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> HeartRateWidgetEntry {
        HeartRateWidgetEntry(date: Date(), heartRate: 72)
    }
    func getSnapshot(in context: Context, completion: @escaping (HeartRateWidgetEntry) -> ()) {
        completion(placeholder(in: context))
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<HeartRateWidgetEntry>) -> ()) {
        let entry = HeartRateWidgetEntry(date: Date(), heartRate: 72)
        let timeline = Timeline(entries: [entry], policy: .atEnd)
        completion(timeline)
    }
}

struct HeartRateWidgetEntryView: View {
    var entry: HeartRateWidgetProvider.Entry
    var body: some View {
        VStack {
            Text("Heart Rate")
                .font(.headline)
            Text("\(entry.heartRate) bpm")
                .font(.title)
            Text(entry.date, style: .time)
                .font(.caption)
        }
        .padding()
    }
}

@main
struct HeartRateWidget: Widget {
    let kind: String = "HeartRateWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: HeartRateWidgetProvider()) { entry in
            HeartRateWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Heart Rate")
        .description("Shows your current heart rate.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

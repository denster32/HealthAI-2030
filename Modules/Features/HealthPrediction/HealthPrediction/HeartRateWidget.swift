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
            Text(LocalizedStringKey("Heart Rate"))
                .font(.headline)
                .accessibilityLabel(Text("Heart Rate Widget Title", comment: "Accessibility label for the heart rate widget title"))
            Text(LocalizedStringKey("\(entry.heartRate) bpm"))
                .font(.title)
                .accessibilityLabel(Text("\(entry.heartRate) beats per minute", comment: "Accessibility value for heart rate"))
            Text(entry.date, style: .time)
                .font(.caption)
                .accessibilityLabel(Text("Measured at \(entry.date, style: .time)", comment: "Accessibility label for heart rate measurement time"))
        }
        .padding()
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isSummaryElement)
        .accessibilityHint(Text("Displays your current heart rate and the time it was measured.", comment: "Accessibility hint for heart rate widget"))
    }
}

@main
struct HeartRateWidget: Widget {
    let kind: String = "HeartRateWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: HeartRateWidgetProvider()) { entry in
            HeartRateWidgetEntryView(entry: entry)
        }
        .configurationDisplayName(Text("Heart Rate", comment: "Widget display name for heart rate"))
        .description(Text("Shows your current heart rate.", comment: "Widget description for heart rate"))
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

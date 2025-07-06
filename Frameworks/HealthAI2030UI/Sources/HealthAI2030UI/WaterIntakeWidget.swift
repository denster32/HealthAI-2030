import WidgetKit
import SwiftUI

struct WaterIntakeWidgetEntry: TimelineEntry {
    let date: Date
    let waterIntake: Int
}

struct WaterIntakeWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> WaterIntakeWidgetEntry {
        WaterIntakeWidgetEntry(date: Date(), waterIntake: 0)
    }
    func getSnapshot(in context: Context, completion: @escaping (WaterIntakeWidgetEntry) -> ()) {
        completion(placeholder(in: context))
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<WaterIntakeWidgetEntry>) -> ()) {
        let entry = WaterIntakeWidgetEntry(date: Date(), waterIntake: 1200)
        let timeline = Timeline(entries: [entry], policy: .atEnd)
        completion(timeline)
    }
}

struct WaterIntakeWidgetEntryView: View {
    var entry: WaterIntakeWidgetProvider.Entry
    var body: some View {
        VStack {
            Text("Water Intake")
                .font(.headline)
            Text("\(entry.waterIntake) ml")
                .font(.title)
            Text(entry.date, style: .time)
                .font(.caption)
        }
        .padding()
    }
}

@main
struct WaterIntakeWidget: Widget {
    let kind: String = "WaterIntakeWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WaterIntakeWidgetProvider()) { entry in
            WaterIntakeWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Water Intake")
        .description("Shows your daily water intake.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

import WidgetKit
import SwiftUI

struct StepCountEntry: TimelineEntry {
    let date: Date
    let steps: Int
}

struct StepCountProvider: TimelineProvider {
    func placeholder(in context: Context) -> StepCountEntry {
        StepCountEntry(date: Date(), steps: 1000)
    }
    func getSnapshot(in context: Context, completion: @escaping (StepCountEntry) -> ()) {
        completion(StepCountEntry(date: Date(), steps: 1200))
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<StepCountEntry>) -> ()) {
        let entries = [StepCountEntry(date: Date(), steps: 1500)]
        completion(Timeline(entries: entries, policy: .atEnd))
    }
}

struct StepCountWidgetEntryView: View {
    var entry: StepCountProvider.Entry
    var body: some View {
        VStack {
            Text("Steps")
            Text("\(entry.steps)")
                .font(.largeTitle)
        }
    }
}

@main
struct StepCountWidget: Widget {
    let kind: String = "StepCountWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: StepCountProvider()) { entry in
            StepCountWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Step Count")
        .description("Shows your daily step count.")
    }
}

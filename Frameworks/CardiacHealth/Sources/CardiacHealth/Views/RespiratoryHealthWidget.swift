import WidgetKit
import SwiftUI
import HealthKit
import SwiftData
import Modules.Features.Shared.Models.RespiratoryMetrics

struct RespiratoryHealthWidget: Widget {
    let kind: String = "RespiratoryHealthWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: RespiratoryHealthTimelineProvider()) { entry in
            RespiratoryHealthWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName(Text("Respiratory Health Widget", comment: "Widget display name for respiratory health"))
        .description(Text("Displays your key respiratory metrics.", comment: "Widget description for respiratory health"))
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct RespiratoryHealthTimelineProvider: TimelineProvider {
    @MainActor
    func placeholder(in context: Context) -> RespiratoryHealthEntry {
        RespiratoryHealthEntry(date: Date(), oxygenSaturation: 98.0, respiratoryRate: 16.0)
    }

    @MainActor
    func getSnapshot(in context: Context, completion: @escaping (RespiratoryHealthEntry) -> Void) {
        Task {
            let entry = await fetchLatestEntry()
            completion(entry)
        }
    }

    @MainActor
    func getTimeline(in context: Context, completion: @escaping (Timeline<RespiratoryHealthEntry>) -> Void) {
        Task {
            let entry = await fetchLatestEntry()
            let timeline = Timeline(entries: [entry], policy: .atEnd)
            completion(timeline)
        }
    }

    @MainActor
    private func fetchLatestEntry() async -> RespiratoryHealthEntry {
        // Use SwiftData to fetch the latest respiratory metrics
        let modelContext = try? ModelContext(for: RespiratoryMetrics.self)
        let request = FetchDescriptor<RespiratoryMetrics>(sortBy: [SortDescriptor(\RespiratoryMetrics.timestamp, order: .reverse)], fetchLimit: 1)
        if let metrics = try? modelContext?.fetch(request).first {
            return RespiratoryHealthEntry(date: metrics.timestamp, oxygenSaturation: metrics.oxygenSaturation, respiratoryRate: metrics.respiratoryRate)
        } else {
            return RespiratoryHealthEntry(date: Date(), oxygenSaturation: 98.0, respiratoryRate: 16.0)
        }
    }
}

struct RespiratoryHealthEntry: TimelineEntry {
    let date: Date
    let oxygenSaturation: Double
    let respiratoryRate: Double
}

struct RespiratoryHealthWidgetView: View {
    var entry: RespiratoryHealthTimelineProvider.Entry

    var body: some View {
        VStack(alignment: .leading) {
            Text("Respiratory Health")
                .font(.headline)
                .accessibilityLabel(Text("Respiratory Health Widget Title", comment: "Accessibility label for the widget title"))

            Spacer()

            HStack {
                Image(systemName: "lungs.fill")
                    .foregroundColor(.blue)
                    .accessibilityHidden(true)
                VStack(alignment: .leading) {
                    Text("Oxygen Saturation:")
                        .font(.caption)
                        .accessibilityLabel(Text("Oxygen Saturation Label", comment: "Accessibility label for oxygen saturation"))
                    Text("\(entry.oxygenSaturation, specifier: "%.1f")%")
                        .font(.title2)
                        .fontWeight(.bold)
                        .accessibilityValue(Text("\(entry.oxygenSaturation, specifier: "%.1f") percent", comment: "Accessibility value for oxygen saturation percentage"))
                }
            }
            .padding(.bottom, 5)

            HStack {
                Image(systemName: "waveform.path.ecg")
                    .foregroundColor(.green)
                    .accessibilityHidden(true)
                VStack(alignment: .leading) {
                    Text("Respiratory Rate:")
                        .font(.caption)
                        .accessibilityLabel(Text("Respiratory Rate Label", comment: "Accessibility label for respiratory rate"))
                    Text("\(entry.respiratoryRate, specifier: "%.1f") bpm")
                        .font(.title2)
                        .fontWeight(.bold)
                        .accessibilityValue(Text("\(entry.respiratoryRate, specifier: "%.1f") breaths per minute", comment: "Accessibility value for respiratory rate"))
                }
            }
        }
        .padding()
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isSummaryElement)
        .accessibilityLabel(Text("Respiratory Health Summary", comment: "Overall accessibility label for the respiratory health widget"))
    }
}

// Preview Provider for Xcode Canvas
#Preview(as: .systemSmall) {
    RespiratoryHealthWidget()
} timeline: {
    RespiratoryHealthEntry(date: .now, oxygenSaturation: 98.0, respiratoryRate: 16.0)
    RespiratoryHealthEntry(date: .now.advanced(by: 60 * 60), oxygenSaturation: 97.5, respiratoryRate: 15.5)
}

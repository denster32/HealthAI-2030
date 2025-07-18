import Foundation
import WidgetKit
import SwiftUI

public struct HealthAI2030Widgets {
    public static let version = "1.0.0"
    
    public init() {}
}

@available(iOS 17.0, *)
public struct HealthSummaryWidget: Widget {
    public let kind: String = "HealthSummaryWidget"
    
    public init() {}
    
    public var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: HealthSummaryProvider()) { entry in
            HealthSummaryWidgetView(entry: entry)
        }
        .configurationDisplayName("Health Summary")
        .description("View your health metrics at a glance")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

public struct HealthSummaryEntry: TimelineEntry {
    public let date: Date
    public let heartRate: Int
    public let steps: Int
    
    public init(date: Date, heartRate: Int = 72, steps: Int = 8432) {
        self.date = date
        self.heartRate = heartRate
        self.steps = steps
    }
}

public struct HealthSummaryProvider: TimelineProvider {
    public init() {}
    
    public func placeholder(in context: Context) -> HealthSummaryEntry {
        HealthSummaryEntry(date: Date())
    }
    
    public func getSnapshot(in context: Context, completion: @escaping (HealthSummaryEntry) -> ()) {
        let entry = HealthSummaryEntry(date: Date())
        completion(entry)
    }
    
    public func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let entries: [HealthSummaryEntry] = [
            HealthSummaryEntry(date: Date())
        ]
        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

@available(iOS 17.0, *)
public struct HealthSummaryWidgetView: View {
    let entry: HealthSummaryEntry
    
    public init(entry: HealthSummaryEntry) {
        self.entry = entry
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("HealthAI")
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Heart Rate")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(entry.heartRate) BPM")
                        .font(.title3)
                        .fontWeight(.medium)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Steps")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(entry.steps)")
                        .font(.title3)
                        .fontWeight(.medium)
                }
            }
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }
}
import SwiftUI
import WidgetKit

@available(watchOS 11.0, *)
struct WatchComplicationsView: View {
    var body: some View {
        VStack {
            Text("Complications")
                .font(.headline)
            
            ScrollView {
                VStack(spacing: 20) {
                    // Circular Complication
                    VStack {
                        Text("Circular")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        ZStack {
                            Circle()
                                .stroke(Color.green, lineWidth: 4)
                                .frame(width: 60, height: 60)
                            
                            VStack {
                                Image(systemName: "heart.fill")
                                    .foregroundColor(.red)
                                    .font(.caption)
                                Text("72")
                                    .font(.caption2)
                                    .fontWeight(.semibold)
                            }
                        }
                    }
                    
                    // Rectangular Complication
                    VStack {
                        Text("Rectangular")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            Image(systemName: "heart.fill")
                                .foregroundColor(.red)
                                .font(.caption)
                            
                            VStack(alignment: .leading) {
                                Text("72 BPM")
                                    .font(.caption2)
                                    .fontWeight(.semibold)
                                Text("HRV: 45ms")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                        }
                        .padding(8)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                        .frame(width: 120, height: 40)
                    }
                    
                    // Inline Complication
                    VStack {
                        Text("Inline")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            Image(systemName: "heart.fill")
                                .foregroundColor(.red)
                                .font(.caption2)
                            Text("72 BPM")
                                .font(.caption2)
                                .fontWeight(.semibold)
                        }
                        .padding(4)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(4)
                    }
                }
                .padding()
            }
        }
    }
}

// MARK: - Complication Widgets

@available(watchOS 11.0, *)
struct HeartRateComplicationWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "HeartRateComplication", provider: HeartRateComplicationProvider()) { entry in
            HeartRateComplicationEntryView(entry: entry)
        }
        .configurationDisplayName("Heart Rate")
        .description("Monitor your heart rate")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}

@available(watchOS 11.0, *)
struct HeartRateComplicationProvider: TimelineProvider {
    func placeholder(in context: Context) -> HeartRateComplicationEntry {
        HeartRateComplicationEntry(date: Date(), heartRate: 72, isActive: true)
    }
    
    func getSnapshot(in context: Context, completion: @escaping (HeartRateComplicationEntry) -> Void) {
        let entry = HeartRateComplicationEntry(date: Date(), heartRate: 72, isActive: true)
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<HeartRateComplicationEntry>) -> Void) {
        var entries: [HeartRateComplicationEntry] = []
        let currentDate = Date()
        
        for hourOffset in 0..<24 {
            let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
            let entry = HeartRateComplicationEntry(date: entryDate, heartRate: 72, isActive: true)
            entries.append(entry)
        }
        
        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

@available(watchOS 11.0, *)
struct HeartRateComplicationEntry: TimelineEntry {
    let date: Date
    let heartRate: Double
    let isActive: Bool
}

@available(watchOS 11.0, *)
struct HeartRateComplicationEntryView: View {
    let entry: HeartRateComplicationEntry
    
    var body: some View {
        VStack {
            Image(systemName: "heart.fill")
                .foregroundColor(entry.isActive ? .red : .gray)
                .font(.caption)
            Text("\(Int(entry.heartRate))")
                .font(.caption2)
                .fontWeight(.semibold)
        }
    }
}

@available(watchOS 11.0, *)
struct SleepComplicationWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "SleepComplication", provider: SleepComplicationProvider()) { entry in
            SleepComplicationEntryView(entry: entry)
        }
        .configurationDisplayName("Sleep")
        .description("Track your sleep")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular])
    }
}

@available(watchOS 11.0, *)
struct SleepComplicationProvider: TimelineProvider {
    func placeholder(in context: Context) -> SleepComplicationEntry {
        SleepComplicationEntry(date: Date(), sleepStage: .awake, isSleeping: false)
    }
    
    func getSnapshot(in context: Context, completion: @escaping (SleepComplicationEntry) -> Void) {
        let entry = SleepComplicationEntry(date: Date(), sleepStage: .awake, isSleeping: false)
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<SleepComplicationEntry>) -> Void) {
        var entries: [SleepComplicationEntry] = []
        let currentDate = Date()
        
        for hourOffset in 0..<24 {
            let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
            let entry = SleepComplicationEntry(date: entryDate, sleepStage: .awake, isSleeping: false)
            entries.append(entry)
        }
        
        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

@available(watchOS 11.0, *)
struct SleepComplicationEntry: TimelineEntry {
    let date: Date
    let sleepStage: SleepStage
    let isSleeping: Bool
}

@available(watchOS 11.0, *)
struct SleepComplicationEntryView: View {
    let entry: SleepComplicationEntry
    
    var body: some View {
        VStack {
            Image(systemName: "bed.double.fill")
                .foregroundColor(entry.isSleeping ? .purple : .gray)
                .font(.caption)
            Text(entry.sleepStage.displayName)
                .font(.caption2)
                .fontWeight(.semibold)
        }
    }
}

// MARK: - Complication Manager

@available(watchOS 11.0, *)
class WatchComplicationManager: ObservableObject {
    static let shared = WatchComplicationManager()
    
    @Published var currentHeartRate: Double = 0
    @Published var currentSleepStage: SleepStage = .awake
    @Published var isSleeping: Bool = false
    
    private init() {}
    
    func updateComplications() {
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    func updateHeartRate(_ heartRate: Double) {
        currentHeartRate = heartRate
        updateComplications()
    }
    
    func updateSleepStage(_ stage: SleepStage, isSleeping: Bool) {
        currentSleepStage = stage
        self.isSleeping = isSleeping
        updateComplications()
    }
} 
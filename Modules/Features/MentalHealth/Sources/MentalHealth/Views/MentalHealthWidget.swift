import WidgetKit
import SwiftUI
import HealthKit

// MARK: - Mental Health Widget

public struct MentalHealthWidget: Widget {
    let kind: String = "MentalHealthWidget"
    
    public init() {}
    
    public var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MentalHealthTimelineProvider()) { entry in
            MentalHealthWidgetView(entry: entry)
        }
        .configurationDisplayName("Mental Health")
        .description("Track your mental health score and mindfulness progress.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct MentalHealthTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> MentalHealthEntry {
        MentalHealthEntry(date: Date(), score: 0.75, stressLevel: .moderate, mindfulnessMinutes: 15)
    }
    
    func getSnapshot(in context: Context, completion: @escaping (MentalHealthEntry) -> Void) {
        let entry = MentalHealthEntry(date: Date(), score: 0.82, stressLevel: .low, mindfulnessMinutes: 20)
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<MentalHealthEntry>) -> Void) {
        let currentDate = Date()
        guard let refreshDate = Calendar.current.date(byAdding: .minute, value: 15, to: currentDate) else {
            // Fallback to 15 minutes from now if calendar operation fails
            let fallbackDate = currentDate.addingTimeInterval(15 * 60)
            let entry = MentalHealthEntry(
                date: currentDate,
                score: MentalHealthManager.shared.mentalHealthScore,
                stressLevel: MentalHealthManager.shared.stressLevel,
                mindfulnessMinutes: Int(MentalHealthManager.shared.mindfulnessSessions.reduce(0) { $0 + $1.duration } / 60)
            )
            let timeline = Timeline(entries: [entry], policy: .after(fallbackDate))
            completion(timeline)
            return
        }
        
        let entry = MentalHealthEntry(
            date: currentDate,
            score: MentalHealthManager.shared.mentalHealthScore,
            stressLevel: MentalHealthManager.shared.stressLevel,
            mindfulnessMinutes: Int(MentalHealthManager.shared.mindfulnessSessions.reduce(0) { $0 + $1.duration } / 60)
        )
        
        let timeline = Timeline(entries: [entry], policy: .after(refreshDate))
        completion(timeline)
    }
}

public struct MentalHealthEntry: TimelineEntry {
    public let date: Date
    public let score: Double
    public let stressLevel: StressLevel
    public let mindfulnessMinutes: Int
}

struct MentalHealthWidgetView: View {
    let entry: MentalHealthEntry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        switch family {
        case .systemSmall:
            MentalHealthSmallView(entry: entry)
        case .systemMedium:
            MentalHealthMediumView(entry: entry)
        default:
            MentalHealthSmallView(entry: entry)
        }
    }
}

struct MentalHealthSmallView: View {
    let entry: MentalHealthEntry
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "brain")
                    .foregroundColor(.purple)
                Text("Mental Health")
                    .font(.caption)
                    .fontWeight(.medium)
                Spacer()
            }
            
            Spacer()
            
            VStack(spacing: 4) {
                Text("\(Int(entry.score * 100))")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.purple)
                
                Text("Score")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            HStack {
                Label("\(entry.mindfulnessMinutes)m", systemImage: "leaf")
                    .font(.caption2)
                    .foregroundColor(.green)
                
                Spacer()
                
                Text(entry.stressLevel.displayName)
                    .font(.caption2)
                    .foregroundColor(stressColor)
            }
        }
        .padding()
        .background(Color(.systemBackground))
    }
    
    private var stressColor: Color {
        switch entry.stressLevel {
        case .low: return .green
        case .moderate: return .yellow
        case .high: return .orange
        case .severe: return .red
        }
    }
}

struct MentalHealthMediumView: View {
    let entry: MentalHealthEntry
    
    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "brain")
                        .foregroundColor(.purple)
                    Text("Mental Health")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Overall Score")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(Int(entry.score * 100))")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.purple)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 12) {
                HStack {
                    Image(systemName: "leaf")
                        .foregroundColor(.green)
                    Text("\(entry.mindfulnessMinutes)m")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                HStack {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundColor(stressColor)
                    Text(entry.stressLevel.displayName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
    }
    
    private var stressColor: Color {
        switch entry.stressLevel {
        case .low: return .green
        case .moderate: return .yellow
        case .high: return .orange
        case .severe: return .red
        }
    }
}
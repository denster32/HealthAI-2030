import WidgetKit
import SwiftUI
import HealthKit
import MentalHealth

// MARK: - Cardiac Health Widget

struct CardiacHealthWidget: Widget {
    let kind: String = "CardiacHealthWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CardiacHealthTimelineProvider()) { entry in
            CardiacHealthWidgetView(entry: entry)
        }
        .configurationDisplayName("Cardiac Health")
        .description("Monitor your heart health and fitness metrics.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct CardiacHealthTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> CardiacHealthEntry {
        CardiacHealthEntry(date: Date(), heartRate: 72, hrv: 45, afibStatus: .normal, vo2Max: 42)
    }
    
    func getSnapshot(in context: Context, completion: @escaping (CardiacHealthEntry) -> Void) {
        let entry = CardiacHealthEntry(date: Date(), heartRate: 68, hrv: 52, afibStatus: .normal, vo2Max: 45)
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<CardiacHealthEntry>) -> Void) {
        let currentDate = Date()
        guard let refreshDate = Calendar.current.date(byAdding: .minute, value: 10, to: currentDate) else {
            // Fallback to 10 minutes from now if calendar operation fails
            let fallbackDate = currentDate.addingTimeInterval(10 * 60)
            let entry = CardiacHealthEntry(
                date: currentDate,
                heartRate: AdvancedCardiacManager.shared.heartRateData.first?.value ?? 70,
                hrv: AdvancedCardiacManager.shared.hrvData.first?.value ?? 45,
                afibStatus: AdvancedCardiacManager.shared.afibStatus,
                vo2Max: AdvancedCardiacManager.shared.vo2Max
            )
            let timeline = Timeline(entries: [entry], policy: .after(fallbackDate))
            completion(timeline)
            return
        }
        
        let entry = CardiacHealthEntry(
            date: currentDate,
            heartRate: AdvancedCardiacManager.shared.heartRateData.first?.value ?? 70,
            hrv: AdvancedCardiacManager.shared.hrvData.first?.value ?? 45,
            afibStatus: AdvancedCardiacManager.shared.afibStatus,
            vo2Max: AdvancedCardiacManager.shared.vo2Max
        )
        
        let timeline = Timeline(entries: [entry], policy: .after(refreshDate))
        completion(timeline)
    }
}

struct CardiacHealthEntry: TimelineEntry {
    let date: Date
    let heartRate: Double
    let hrv: Double
    let afibStatus: AFibStatus
    let vo2Max: Double
}

struct CardiacHealthWidgetView: View {
    let entry: CardiacHealthEntry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        switch family {
        case .systemSmall:
            CardiacHealthSmallView(entry: entry)
        case .systemMedium:
            CardiacHealthMediumView(entry: entry)
        default:
            CardiacHealthSmallView(entry: entry)
        }
    }
}

struct CardiacHealthSmallView: View {
    let entry: CardiacHealthEntry
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "heart.fill")
                    .foregroundColor(.red)
                Text("Cardiac")
                    .font(.caption)
                    .fontWeight(.medium)
                Spacer()
            }
            
            Spacer()
            
            VStack(spacing: 4) {
                Text("\(Int(entry.heartRate))")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.red)
                
                Text("BPM")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            HStack {
                Label("\(Int(entry.hrv))ms", systemImage: "waveform.path.ecg")
                    .font(.caption2)
                    .foregroundColor(.blue)
                
                Spacer()
                
                Text(entry.afibStatus.displayName)
                    .font(.caption2)
                    .foregroundColor(afibColor)
            }
        }
        .padding()
        .background(Color(.systemBackground))
    }
    
    private var afibColor: Color {
        switch entry.afibStatus {
        case .normal: return .green
        case .low: return .yellow
        case .moderate: return .orange
        case .high: return .red
        }
    }
}

struct CardiacHealthMediumView: View {
    let entry: CardiacHealthEntry
    
    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "heart.fill")
                        .foregroundColor(.red)
                    Text("Cardiac Health")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Heart Rate")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(Int(entry.heartRate)) BPM")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.red)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 12) {
                HStack {
                    Image(systemName: "waveform.path.ecg")
                        .foregroundColor(.blue)
                    Text("\(Int(entry.hrv))ms")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                HStack {
                    Image(systemName: "figure.run")
                        .foregroundColor(.green)
                    Text("\(Int(entry.vo2Max))")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
    }
}

// MARK: - Respiratory Health Widget

struct RespiratoryHealthWidget: Widget {
    let kind: String = "RespiratoryHealthWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: RespiratoryHealthTimelineProvider()) { entry in
            RespiratoryHealthWidgetView(entry: entry)
        }
        .configurationDisplayName("Respiratory Health")
        .description("Track breathing patterns and oxygen saturation.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct RespiratoryHealthTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> RespiratoryHealthEntry {
        RespiratoryHealthEntry(date: Date(), respiratoryRate: 16, oxygenSaturation: 98, efficiency: 0.85, pattern: .normal)
    }
    
    func getSnapshot(in context: Context, completion: @escaping (RespiratoryHealthEntry) -> Void) {
        let entry = RespiratoryHealthEntry(date: Date(), respiratoryRate: 15, oxygenSaturation: 99, efficiency: 0.88, pattern: .normal)
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<RespiratoryHealthEntry>) -> Void) {
        let currentDate = Date()
        guard let refreshDate = Calendar.current.date(byAdding: .minute, value: 12, to: currentDate) else {
            // Fallback to 12 minutes from now if calendar operation fails
            let fallbackDate = currentDate.addingTimeInterval(12 * 60)
            let entry = RespiratoryHealthEntry(
                date: currentDate,
                respiratoryRate: RespiratoryHealthManager.shared.respiratoryRate,
                oxygenSaturation: RespiratoryHealthManager.shared.oxygenSaturation,
                efficiency: RespiratoryHealthManager.shared.respiratoryEfficiency,
                pattern: RespiratoryHealthManager.shared.breathingPattern
            )
            let timeline = Timeline(entries: [entry], policy: .after(fallbackDate))
            completion(timeline)
            return
        }
        
        let entry = RespiratoryHealthEntry(
            date: currentDate,
            respiratoryRate: RespiratoryHealthManager.shared.respiratoryRate,
            oxygenSaturation: RespiratoryHealthManager.shared.oxygenSaturation,
            efficiency: RespiratoryHealthManager.shared.respiratoryEfficiency,
            pattern: RespiratoryHealthManager.shared.breathingPattern
        )
        
        let timeline = Timeline(entries: [entry], policy: .after(refreshDate))
        completion(timeline)
    }
}

struct RespiratoryHealthEntry: TimelineEntry {
    let date: Date
    let respiratoryRate: Double
    let oxygenSaturation: Double
    let efficiency: Double
    let pattern: BreathingPattern
}

struct RespiratoryHealthWidgetView: View {
    let entry: RespiratoryHealthEntry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        switch family {
        case .systemSmall:
            RespiratoryHealthSmallView(entry: entry)
        case .systemMedium:
            RespiratoryHealthMediumView(entry: entry)
        default:
            RespiratoryHealthSmallView(entry: entry)
        }
    }
}

struct RespiratoryHealthSmallView: View {
    let entry: RespiratoryHealthEntry
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "lungs.fill")
                    .foregroundColor(.blue)
                Text("Respiratory")
                    .font(.caption)
                    .fontWeight(.medium)
                Spacer()
            }
            
            Spacer()
            
            VStack(spacing: 4) {
                Text("\(String(format: "%.1f", entry.oxygenSaturation))")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.cyan)
                
                Text("% O2")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            HStack {
                Label("\(String(format: "%.1f", entry.respiratoryRate))", systemImage: "lungs")
                    .font(.caption2)
                    .foregroundColor(.blue)
                
                Spacer()
                
                Text(entry.pattern.displayName)
                    .font(.caption2)
                    .foregroundColor(patternColor)
            }
        }
        .padding()
        .background(Color(.systemBackground))
    }
    
    private var patternColor: Color {
        switch entry.pattern {
        case .slow: return .blue
        case .normal: return .green
        case .slightlyElevated: return .yellow
        case .elevated: return .orange
        case .rapid: return .red
        }
    }
}

struct RespiratoryHealthMediumView: View {
    let entry: RespiratoryHealthEntry
    
    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "lungs.fill")
                        .foregroundColor(.blue)
                    Text("Respiratory Health")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Oxygen Saturation")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(String(format: "%.1f", entry.oxygenSaturation))%")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.cyan)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 12) {
                HStack {
                    Image(systemName: "lungs")
                    .foregroundColor(.blue)
                    Text("\(String(format: "%.1f", entry.respiratoryRate))")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                HStack {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .foregroundColor(.green)
                    Text("\(Int(entry.efficiency * 100))%")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
    }
}

// MARK: - Sleep Optimization Widget

struct SleepOptimizationWidget: Widget {
    let kind: String = "SleepOptimizationWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SleepOptimizationTimelineProvider()) { entry in
            SleepOptimizationWidgetView(entry: entry)
        }
        .configurationDisplayName("Sleep Optimization")
        .description("Monitor sleep quality and optimization status.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct SleepOptimizationTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> SleepOptimizationEntry {
        SleepOptimizationEntry(date: Date(), quality: 0.85, stage: .deep, isActive: true, temperature: 22.5, humidity: 45)
    }
    
    func getSnapshot(in context: Context, completion: @escaping (SleepOptimizationEntry) -> Void) {
        let entry = SleepOptimizationEntry(date: Date(), quality: 0.78, stage: .light, isActive: false, temperature: 21.8, humidity: 48)
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<SleepOptimizationEntry>) -> Void) {
        let currentDate = Date()
        guard let refreshDate = Calendar.current.date(byAdding: .minute, value: 5, to: currentDate) else {
            // Fallback to 5 minutes from now if calendar operation fails
            let fallbackDate = currentDate.addingTimeInterval(5 * 60)
            let entry = SleepOptimizationEntry(
                date: currentDate,
                quality: SleepOptimizationManager.shared.sleepQuality,
                stage: SleepOptimizationManager.shared.currentSleepStage,
                isActive: SleepOptimizationManager.shared.isOptimizationActive,
                temperature: EnvironmentManager.shared.currentTemperature,
                humidity: EnvironmentManager.shared.currentHumidity
            )
            let timeline = Timeline(entries: [entry], policy: .after(fallbackDate))
            completion(timeline)
            return
        }
        
        let entry = SleepOptimizationEntry(
            date: currentDate,
            quality: SleepOptimizationManager.shared.sleepQuality,
            stage: SleepOptimizationManager.shared.currentSleepStage,
            isActive: SleepOptimizationManager.shared.isOptimizationActive,
            temperature: EnvironmentManager.shared.currentTemperature,
            humidity: EnvironmentManager.shared.currentHumidity
        )
        
        let timeline = Timeline(entries: [entry], policy: .after(refreshDate))
        completion(timeline)
    }
}

struct SleepOptimizationEntry: TimelineEntry {
    let date: Date
    let quality: Double
    let stage: SleepStage
    let isActive: Bool
    let temperature: Double
    let humidity: Double
}

struct SleepOptimizationWidgetView: View {
    let entry: SleepOptimizationEntry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        switch family {
        case .systemSmall:
            SleepOptimizationSmallView(entry: entry)
        case .systemMedium:
            SleepOptimizationMediumView(entry: entry)
        case .systemLarge:
            SleepOptimizationLargeView(entry: entry)
        default:
            SleepOptimizationSmallView(entry: entry)
        }
    }
}

struct SleepOptimizationSmallView: View {
    let entry: SleepOptimizationEntry
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "bed.double.fill")
                    .foregroundColor(.indigo)
                Text("Sleep")
                    .font(.caption)
                    .fontWeight(.medium)
                Spacer()
                
                Circle()
                    .fill(entry.isActive ? Color.green : Color.gray)
                    .frame(width: 8, height: 8)
            }
            
            Spacer()
            
            VStack(spacing: 4) {
                Text("\(Int(entry.quality * 100))")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.indigo)
                
                Text("Quality")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(entry.stage.displayName)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
    }
}

struct SleepOptimizationMediumView: View {
    let entry: SleepOptimizationEntry
    
    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "bed.double.fill")
                        .foregroundColor(.indigo)
                    Text("Sleep Optimization")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Quality Score")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(Int(entry.quality * 100))%")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.indigo)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 12) {
                HStack {
                    Image(systemName: "thermometer")
                        .foregroundColor(.orange)
                    Text("\(String(format: "%.1f", entry.temperature))°C")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                HStack {
                    Image(systemName: "humidity")
                        .foregroundColor(.blue)
                    Text("\(Int(entry.humidity))%")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
    }
}

struct SleepOptimizationLargeView: View {
    let entry: SleepOptimizationEntry
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "bed.double.fill")
                    .foregroundColor(.indigo)
                Text("Sleep Optimization")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                
                HStack(spacing: 4) {
                    Circle()
                        .fill(entry.isActive ? Color.green : Color.gray)
                        .frame(width: 8, height: 8)
                    Text(entry.isActive ? "Active" : "Inactive")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            HStack(spacing: 20) {
                VStack(spacing: 4) {
                    Text("\(Int(entry.quality * 100))")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.indigo)
                    Text("Quality")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack(spacing: 4) {
                    Text(entry.stage.displayName)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.purple)
                    Text("Stage")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            HStack(spacing: 20) {
                VStack(spacing: 4) {
                    Text("\(String(format: "%.1f", entry.temperature))°C")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.orange)
                    Text("Temperature")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack(spacing: 4) {
                    Text("\(Int(entry.humidity))%")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                    Text("Humidity")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
    }
}

// MARK: - Widget Bundle

@main
struct HealthAI2030WidgetBundle: WidgetBundle {
    var body: some Widget {
        MentalHealthWidget()
        CardiacHealthWidget()
        RespiratoryHealthWidget()
        SleepOptimizationWidget()
    }
} 
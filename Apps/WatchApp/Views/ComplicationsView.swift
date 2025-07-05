import SwiftUI
import WidgetKit
import ClockKit

struct ComplicationsView: View {
    @StateObject private var complicationManager = ComplicationManager()
    
    var body: some View {
        VStack(spacing: 16) {
            // Complication Preview
            ComplicationPreviewView()
            
            // Complication Settings
            ComplicationSettingsView(complicationManager: complicationManager)
            
            // Available Complications
            AvailableComplicationsView(complicationManager: complicationManager)
        }
        .navigationTitle("Complications")
        .onAppear {
            complicationManager.updateComplications()
        }
    }
}

struct ComplicationPreviewView: View {
    var body: some View {
        VStack(spacing: 12) {
            Text("Complication Preview")
                .font(.headline)
            
            // Simulated watch face with complications
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.black)
                    .frame(width: 180, height: 180)
                
                // Center time
                VStack {
                    Text("9:41")
                        .font(.system(size: 24, weight: .medium, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("AM")
                        .font(.system(size: 12, weight: .light))
                        .foregroundColor(.white.opacity(0.7))
                }
                
                // Top complication (heart rate)
                VStack {
                    Image(systemName: "heart.fill")
                        .foregroundColor(.red)
                        .font(.caption)
                    Text("72")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white)
                }
                .offset(y: -60)
                
                // Bottom complication (steps)
                VStack {
                    Image(systemName: "figure.walk")
                        .foregroundColor(.green)
                        .font(.caption)
                    Text("8.2K")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white)
                }
                .offset(y: 60)
                
                // Left complication (battery)
                VStack {
                    Image(systemName: "battery.75")
                        .foregroundColor(.green)
                        .font(.caption)
                    Text("75%")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white)
                }
                .offset(x: -60)
                
                // Right complication (weather)
                VStack {
                    Image(systemName: "sun.max.fill")
                        .foregroundColor(.yellow)
                        .font(.caption)
                    Text("72°")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white)
                }
                .offset(x: 60)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
}

struct ComplicationSettingsView: View {
    @ObservedObject var complicationManager: ComplicationManager
    @State private var selectedComplication: ComplicationType = .heartRate
    
    enum ComplicationType: String, CaseIterable {
        case heartRate = "Heart Rate"
        case steps = "Steps"
        case calories = "Calories"
        case sleep = "Sleep"
        case activity = "Activity"
        case water = "Water"
        case medication = "Medication"
        case weather = "Weather"
        case battery = "Battery"
        
        var icon: String {
            switch self {
            case .heartRate: return "heart.fill"
            case .steps: return "figure.walk"
            case .calories: return "flame.fill"
            case .sleep: return "bed.double.fill"
            case .activity: return "figure.run"
            case .water: return "drop.fill"
            case .medication: return "pill.fill"
            case .weather: return "sun.max.fill"
            case .battery: return "battery.100"
            }
        }
        
        var color: Color {
            switch self {
            case .heartRate: return .red
            case .steps: return .green
            case .calories: return .orange
            case .sleep: return .blue
            case .activity: return .purple
            case .water: return .cyan
            case .medication: return .pink
            case .weather: return .yellow
            case .battery: return .green
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Complication Settings")
                .font(.headline)
            
            Picker("Complication Type", selection: $selectedComplication) {
                ForEach(ComplicationType.allCases, id: \.self) { type in
                    HStack {
                        Image(systemName: type.icon)
                            .foregroundColor(type.color)
                        Text(type.rawValue)
                    }
                    .tag(type)
                }
            }
            .pickerStyle(WheelPickerStyle())
            .frame(height: 100)
            
            // Update frequency
            VStack(alignment: .leading, spacing: 8) {
                Text("Update Frequency")
                    .font(.subheadline)
                
                HStack {
                    Button("1 min") {
                        complicationManager.setUpdateFrequency(.oneMinute)
                    }
                    .buttonStyle(.bordered)
                    
                    Button("5 min") {
                        complicationManager.setUpdateFrequency(.fiveMinutes)
                    }
                    .buttonStyle(.bordered)
                    
                    Button("15 min") {
                        complicationManager.setUpdateFrequency(.fifteenMinutes)
                    }
                    .buttonStyle(.bordered)
                }
            }
            
            // Enable/disable complications
            VStack(alignment: .leading, spacing: 8) {
                Text("Active Complications")
                    .font(.subheadline)
                
                ForEach(ComplicationType.allCases, id: \.self) { type in
                    HStack {
                        Image(systemName: type.icon)
                            .foregroundColor(type.color)
                        
                        Text(type.rawValue)
                        
                        Spacer()
                        
                        Toggle("", isOn: Binding(
                            get: { complicationManager.isComplicationEnabled(type) },
                            set: { complicationManager.setComplicationEnabled(type, enabled: $0) }
                        ))
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct AvailableComplicationsView: View {
    @ObservedObject var complicationManager: ComplicationManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Available Complications")
                .font(.headline)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                ComplicationCard(
                    title: "Heart Rate",
                    icon: "heart.fill",
                    color: .red,
                    value: "72 BPM",
                    isActive: true
                )
                
                ComplicationCard(
                    title: "Steps",
                    icon: "figure.walk",
                    color: .green,
                    value: "8,234",
                    isActive: true
                )
                
                ComplicationCard(
                    title: "Calories",
                    icon: "flame.fill",
                    color: .orange,
                    value: "342",
                    isActive: false
                )
                
                ComplicationCard(
                    title: "Sleep",
                    icon: "bed.double.fill",
                    color: .blue,
                    value: "7.5h",
                    isActive: false
                )
                
                ComplicationCard(
                    title: "Water",
                    icon: "drop.fill",
                    color: .cyan,
                    value: "6/8",
                    isActive: true
                )
                
                ComplicationCard(
                    title: "Activity",
                    icon: "figure.run",
                    color: .purple,
                    value: "85%",
                    isActive: false
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct ComplicationCard: View {
    let title: String
    let icon: String
    let color: Color
    let value: String
    let isActive: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title3)
                
                Spacer()
                
                if isActive {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.caption)
                }
            }
            
            Text(value)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(12)
        .background(isActive ? color.opacity(0.1) : Color(.systemGray5))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isActive ? color : Color.clear, lineWidth: 2)
        )
    }
}

class ComplicationManager: ObservableObject {
    @Published var enabledComplications: Set<String> = ["heartRate", "steps", "water"]
    @Published var updateFrequency: UpdateFrequency = .fiveMinutes
    
    enum UpdateFrequency: String, CaseIterable {
        case oneMinute = "1 minute"
        case fiveMinutes = "5 minutes"
        case fifteenMinutes = "15 minutes"
        case thirtyMinutes = "30 minutes"
        case oneHour = "1 hour"
    }
    
    func updateComplications() {
        // Update all active complications
        CLKComplicationServer.sharedInstance().reloadTimeline(for: .modularSmall)
        CLKComplicationServer.sharedInstance().reloadTimeline(for: .modularLarge)
        CLKComplicationServer.sharedInstance().reloadTimeline(for: .utilitarianSmall)
        CLKComplicationServer.sharedInstance().reloadTimeline(for: .utilitarianLarge)
        CLKComplicationServer.sharedInstance().reloadTimeline(for: .circularSmall)
        CLKComplicationServer.sharedInstance().reloadTimeline(for: .extraLarge)
    }
    
    func setUpdateFrequency(_ frequency: UpdateFrequency) {
        updateFrequency = frequency
        // Schedule updates based on frequency
        scheduleUpdates()
    }
    
    func isComplicationEnabled(_ type: ComplicationsView.ComplicationSettingsView.ComplicationType) -> Bool {
        let key = type.rawValue.lowercased().replacingOccurrences(of: " ", with: "")
        return enabledComplications.contains(key)
    }
    
    func setComplicationEnabled(_ type: ComplicationsView.ComplicationSettingsView.ComplicationType, enabled: Bool) {
        let key = type.rawValue.lowercased().replacingOccurrences(of: " ", with: "")
        if enabled {
            enabledComplications.insert(key)
        } else {
            enabledComplications.remove(key)
        }
        updateComplications()
    }
    
    private func scheduleUpdates() {
        // Schedule complication updates based on frequency
        let interval: TimeInterval
        switch updateFrequency {
        case .oneMinute: interval = 60
        case .fiveMinutes: interval = 300
        case .fifteenMinutes: interval = 900
        case .thirtyMinutes: interval = 1800
        case .oneHour: interval = 3600
        }
        
        // In a real implementation, you'd schedule background updates here
        print("Scheduling complication updates every \(updateFrequency.rawValue)")
    }
}

// MARK: - Complication Data Source

class ComplicationDataSource: NSObject, CLKComplicationDataSource {
    func getCurrentTimelineEntry(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTimelineEntry?) -> Void) {
        // Provide current complication data
        let template = createTemplate(for: complication)
        let entry = CLKComplicationTimelineEntry(date: Date(), complicationTemplate: template)
        handler(entry)
    }
    
    func getTimelineStartDate(for complication: CLKComplication, withHandler handler: @escaping (Date?) -> Void) {
        handler(Date())
    }
    
    func getTimelineEndDate(for complication: CLKComplication, withHandler handler: @escaping (Date?) -> Void) {
        handler(Date().addingTimeInterval(24 * 60 * 60)) // 24 hours from now
    }
    
    func getPrivacyBehavior(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationPrivacyBehavior) -> Void) {
        handler(.showOnLockScreen)
    }
    
    private func createTemplate(for complication: CLKComplication) -> CLKComplicationTemplate {
        switch complication.family {
        case .modularSmall:
            return createModularSmallTemplate()
        case .modularLarge:
            return createModularLargeTemplate()
        case .utilitarianSmall:
            return createUtilitarianSmallTemplate()
        case .utilitarianLarge:
            return createUtilitarianLargeTemplate()
        case .circularSmall:
            return createCircularSmallTemplate()
        case .extraLarge:
            return createExtraLargeTemplate()
        default:
            return createModularSmallTemplate()
        }
    }
    
    private func createModularSmallTemplate() -> CLKComplicationTemplate {
        let template = CLKComplicationTemplateModularSmallStackText()
        template.line1TextProvider = CLKSimpleTextProvider(text: "72")
        template.line2TextProvider = CLKSimpleTextProvider(text: "BPM")
        return template
    }
    
    private func createModularLargeTemplate() -> CLKComplicationTemplate {
        let template = CLKComplicationTemplateModularLargeTallBody()
        template.headerTextProvider = CLKSimpleTextProvider(text: "Heart Rate")
        template.bodyTextProvider = CLKSimpleTextProvider(text: "72 BPM")
        return template
    }
    
    private func createUtilitarianSmallTemplate() -> CLKComplicationTemplate {
        let template = CLKComplicationTemplateUtilitarianSmallFlat()
        template.textProvider = CLKSimpleTextProvider(text: "72")
        return template
    }
    
    private func createUtilitarianLargeTemplate() -> CLKComplicationTemplate {
        let template = CLKComplicationTemplateUtilitarianLargeFlat()
        template.textProvider = CLKSimpleTextProvider(text: "Heart Rate: 72 BPM")
        return template
    }
    
    private func createCircularSmallTemplate() -> CLKComplicationTemplate {
        let template = CLKComplicationTemplateCircularSmallStackText()
        template.line1TextProvider = CLKSimpleTextProvider(text: "72")
        template.line2TextProvider = CLKSimpleTextProvider(text: "BPM")
        return template
    }
    
    private func createExtraLargeTemplate() -> CLKComplicationTemplate {
        let template = CLKComplicationTemplateExtraLargeStackText()
        template.line1TextProvider = CLKSimpleTextProvider(text: "72")
        template.line2TextProvider = CLKSimpleTextProvider(text: "BPM")
        return template
    }
}

#Preview {
    ComplicationsView()
} 
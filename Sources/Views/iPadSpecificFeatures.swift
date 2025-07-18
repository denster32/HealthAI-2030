import SwiftUI
import PencilKit

@available(iOS 17.0, *)
@available(macOS 14.0, *)

// MARK: - iPad-Specific Features and Interactions

struct iPadMultitaskingSupport: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    
    private var isCompactMode: Bool {
        horizontalSizeClass == .compact || verticalSizeClass == .compact
    }
    
    var body: some View {
        Group {
            if isCompactMode {
                // Compact mode when in split view or slide over
                iPadCompactInterface()
            } else {
                // Full screen mode
                iPadFullInterface()
            }
        }
    }
}

struct iPadCompactInterface: View {
    var body: some View {
        VStack(spacing: 16) {
            // Essential health metrics only
            iPadCompactMetrics()
            
            // Quick actions
            iPadCompactQuickActions()
            
            Spacer()
        }
        .padding()
    }
}

struct iPadFullInterface: View {
    var body: some View {
        // Full dashboard with sidebar
        iPadDashboardLayout {
            // All dashboard content
            Group {
                // Health cards
                ForEach(0..<6, id: \.self) { _ in
                    iPadDashboardCard()
                }
            }
        }
    }
}

struct iPadDashboardCard: View {
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Health Metric")
                    .font(.headline)
                Spacer()
                Text("85%")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
            }
            
            ProgressView(value: 0.85)
                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

struct iPadCompactQuickActions: View {
    var body: some View {
        VStack(spacing: 12) {
            Text("Quick Actions")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 8) {
                Button(action: {}) {
                    HStack {
                        Image(systemName: "bed.double.fill")
                        Text("Sleep")
                        Spacer()
                    }
                }
                .buttonStyle(.bordered)
                
                Button(action: {}) {
                    HStack {
                        Image(systemName: "heart.fill")
                        Text("Heart Rate")
                        Spacer()
                    }
                }
                .buttonStyle(.bordered)
            }
        }
    }
}

// MARK: - Apple Pencil Integration

struct iPadPencilJournaling: View {
    @State private var canvasView = PKCanvasView()
    @State private var drawing = PKDrawing()
    @State private var showingJournal = false
    
    var body: some View {
        VStack {
            HStack {
                Text("Health Journal")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button("Add Entry") {
                    showingJournal = true
                }
                .buttonStyle(.borderedProminent)
            }
            
            // Recent journal entries
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(0..<5, id: \.self) { index in
                        iPadJournalEntry(date: Date())
                    }
                }
            }
        }
        .sheet(isPresented: $showingJournal) {
            iPadPencilJournalView(drawing: $drawing)
        }
    }
}

struct iPadJournalEntry: View {
    let date: Date
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(date, style: .date)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Button(action: {}) {
                    Image(systemName: "square.and.pencil")
                }
            }
            
            Text("Today I felt energetic after a good night's sleep. My HRV was higher than usual, and I maintained a consistent bedtime routine.")
                .font(.body)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

struct iPadPencilJournalView: View {
    @Binding var drawing: PKDrawing
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack {
                // Journal prompt
                Text("How are you feeling today? What health insights do you want to record?")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding()
                
                // Pencil drawing area
                PencilKitView(drawing: $drawing)
                    .frame(maxHeight: .infinity)
            }
            .navigationTitle("Health Journal Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        // Save journal entry
                        dismiss()
                    }
                    .fontWeight(.medium)
                }
            }
        }
    }
}

struct PencilKitView: UIViewRepresentable {
    @Binding var drawing: PKDrawing
    
    func makeUIView(context: Context) -> PKCanvasView {
        let canvasView = PKCanvasView()
        canvasView.drawingPolicy = .anyInput
        canvasView.tool = PKInkingTool(.pen, color: .systemBlue, width: 2)
        canvasView.drawing = drawing
        return canvasView
    }
    
    func updateUIView(_ canvasView: PKCanvasView, context: Context) {
        canvasView.drawing = drawing
    }
}

// MARK: - iPad Keyboard Shortcuts

struct iPadKeyboardShortcuts: ViewModifier {
    func body(content: Content) -> some View {
        content
            .focusedSceneValue(\.keyboardShortcuts, [
                // Dashboard shortcuts
                KeyboardShortcut(.init("d"), modifiers: [.command]): "dashboard",
                KeyboardShortcut(.init("a"), modifiers: [.command]): "analytics",
                KeyboardShortcut(.init("s"), modifiers: [.command]): "sleep",
                KeyboardShortcut(.init("h"), modifiers: [.command]): "heart",
                
                // Global shortcuts
                KeyboardShortcut(.init("r"), modifiers: [.command]): "refresh",
                KeyboardShortcut(.init(","), modifiers: [.command]): "settings"
            ])
    }
}

// MARK: - iPad Drag and Drop Support

struct iPadDragDropHealthData: View {
    @State private var draggedHealthMetric: HealthMetric?
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Customize Your Dashboard")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Drag and drop health metrics to rearrange your dashboard")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ForEach(HealthMetric.allCases, id: \.self) { metric in
                    iPadDraggableHealthCard(metric: metric)
                        .onDrag {
                            draggedHealthMetric = metric
                            return NSItemProvider(object: metric.rawValue as NSString)
                        }
                }
            }
        }
        .padding()
    }
}

struct iPadDraggableHealthCard: View {
    let metric: HealthMetric
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: metric.icon)
                .font(.title)
                .foregroundColor(metric.color)
            
            Text(metric.title)
                .font(.caption)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

enum HealthMetric: String, CaseIterable {
    case heartRate = "heartRate"
    case hrv = "hrv"
    case sleep = "sleep"
    case steps = "steps"
    case stress = "stress"
    case recovery = "recovery"
    
    var title: String {
        switch self {
        case .heartRate: return "Heart Rate"
        case .hrv: return "HRV"
        case .sleep: return "Sleep"
        case .steps: return "Steps"
        case .stress: return "Stress"
        case .recovery: return "Recovery"
        }
    }
    
    var icon: String {
        switch self {
        case .heartRate: return "heart.fill"
        case .hrv: return "waveform.path.ecg"
        case .sleep: return "bed.double.fill"
        case .steps: return "figure.walk"
        case .stress: return "brain.head.profile"
        case .recovery: return "arrow.clockwise"
        }
    }
    
    var color: Color {
        switch self {
        case .heartRate: return .red
        case .hrv: return .green
        case .sleep: return .purple
        case .steps: return .blue
        case .stress: return .orange
        case .recovery: return .mint
        }
    }
}

// MARK: - iPad Split View Health Monitoring

struct iPadSplitViewHealthMonitor: View {
    @State private var isMonitoring = false
    @StateObject private var healthDataManager = HealthDataManager.shared
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Real-time Monitor")
                    .font(.title3)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Toggle("Monitor", isOn: $isMonitoring)
                    .toggleStyle(SwitchToggleStyle(tint: .green))
            }
            
            if isMonitoring {
                VStack(spacing: 12) {
                    iPadLiveMetricRow(
                        title: "Heart Rate",
                        value: "\(Int(healthDataManager.currentHeartRate))",
                        unit: "BPM",
                        color: .red,
                        isLive: true
                    )
                    
                    iPadLiveMetricRow(
                        title: "HRV",
                        value: String(format: "%.1f", healthDataManager.currentHRV),
                        unit: "ms",
                        color: .green,
                        isLive: true
                    )
                    
                    iPadLiveMetricRow(
                        title: "Stress",
                        value: "Low",
                        unit: "",
                        color: .blue,
                        isLive: false
                    )
                }
            } else {
                Text("Tap monitor to start real-time health tracking")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.vertical)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct iPadLiveMetricRow: View {
    let title: String
    let value: String
    let unit: String
    let color: Color
    let isLive: Bool
    
    var body: some View {
        HStack {
            HStack(spacing: 8) {
                Circle()
                    .fill(isLive ? .green : .gray)
                    .frame(width: 8, height: 8)
                    .scaleEffect(isLive ? 1.2 : 1.0)
                    .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: isLive)
                
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            
            Spacer()
            
            HStack(alignment: .bottom, spacing: 2) {
                Text(value)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(color)
                
                if !unit.isEmpty {
                    Text(unit)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
}

// MARK: - iPad Accessibility Enhancements

struct iPadAccessibilityOptimizations: ViewModifier {
    func body(content: Content) -> some View {
        content
            .accessibilityElement(children: .combine)
            .accessibilityAction(.magicTap) {
                // Quick health summary
            }
            .accessibilityAction(.escape) {
                // Return to main dashboard
            }
            .accessibilityScrollAction { edge in
                // Custom scroll behavior for health data
                switch edge {
                case .top:
                    // Scroll to latest data
                    break
                case .bottom:
                    // Scroll to historical data
                    break
                default:
                    break
                }
            }
    }
}

// MARK: - iPad-Specific View Extensions

extension View {
    func iPadMultitaskingSupport() -> some View {
        self.modifier(iPadMultitaskingSupport())
    }
    
    func iPadKeyboardShortcuts() -> some View {
        self.modifier(iPadKeyboardShortcuts())
    }
    
    func iPadAccessibilityOptimized() -> some View {
        self.modifier(iPadAccessibilityOptimizations())
    }
}

// MARK: - Focus Scope for Keyboard Shortcuts

private struct KeyboardShortcutsKey: FocusedValueKey {
    typealias Value = [KeyboardShortcut: String]
}

extension FocusedValues {
    var keyboardShortcuts: KeyboardShortcutsKey.Value? {
        get { self[KeyboardShortcutsKey.self] }
        set { self[KeyboardShortcutsKey.self] = newValue }
    }
}
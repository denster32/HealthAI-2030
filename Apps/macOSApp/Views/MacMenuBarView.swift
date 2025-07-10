import SwiftUI
import AppKit

@available(macOS 15.0, *)
public struct MacMenuBarView: View {
    @StateObject private var menuBarManager = MacMenuBarManager.shared
    @State private var showingMenu = false
    
    public var body: some View {
        HStack(spacing: HealthAIDesignSystem.Spacing.sm) {
            // Health Status Indicator
            MacHealthStatusIndicator()
            
            Divider()
                .frame(height: 20)
            
            // Quick Actions
            MacQuickActionButtons()
            
            Divider()
                .frame(height: 20)
            
            // System Status
            MacSystemStatusView()
        }
        .padding(.horizontal, HealthAIDesignSystem.Spacing.md)
        .background(VisualEffectView(material: .hudWindow, blendingMode: .behindWindow))
        .cornerRadius(HealthAIDesignSystem.Layout.cornerRadius)
        .onTapGesture {
            showingMenu = true
        }
        .popover(isPresented: $showingMenu) {
            MacMenuBarPopover()
        }
    }
}

// MARK: - Health Status Indicator
struct MacHealthStatusIndicator: View {
    @StateObject private var healthManager = HealthDataManager.shared
    
    var body: some View {
        HStack(spacing: HealthAIDesignSystem.Spacing.xs) {
            Circle()
                .fill(healthStatusColor)
                .frame(width: 8, height: 8)
            
            Text("\(Int(healthManager.currentHeartRate))")
                .font(HealthAIDesignSystem.Typography.caption1)
                .fontWeight(.medium)
                .foregroundColor(HealthAIDesignSystem.Colors.textPrimary)
        }
        .onTapGesture {
            NSApp.activate(ignoringOtherApps: true)
        }
        .accessibilityLabel("Heart rate: \(Int(healthManager.currentHeartRate)) BPM")
        .accessibilityHint("Double tap to open HealthAI")
    }
    
    private var healthStatusColor: Color {
        let hr = healthManager.currentHeartRate
        switch hr {
        case 0..<60: return HealthAIDesignSystem.Colors.warning
        case 60..<100: return HealthAIDesignSystem.Colors.success
        default: return HealthAIDesignSystem.Colors.error
        }
    }
}

// MARK: - Quick Action Buttons
struct MacQuickActionButtons: View {
    var body: some View {
        HStack(spacing: HealthAIDesignSystem.Spacing.xs) {
            MacQuickActionButton(
                icon: "heart.fill",
                color: HealthAIDesignSystem.Colors.heartRate,
                action: { /* Quick heart rate check */ }
            )
            
            MacQuickActionButton(
                icon: "bed.double.fill",
                color: HealthAIDesignSystem.Colors.sleep,
                action: { /* Sleep tracking */ }
            )
            
            MacQuickActionButton(
                icon: "figure.run",
                color: HealthAIDesignSystem.Colors.activity,
                action: { /* Activity tracking */ }
            )
        }
    }
}

// MARK: - Quick Action Button
struct MacQuickActionButton: View {
    let icon: String
    let color: Color
    let action: () -> Void
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(color)
                .frame(width: 20, height: 20)
                .background(
                    Circle()
                        .fill(color.opacity(isHovered ? 0.2 : 0.1))
                )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isHovered ? 1.1 : 1.0)
        .animation(HealthAIDesignSystem.Layout.animationSpring, value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - System Status View
struct MacSystemStatusView: View {
    @StateObject private var systemManager = MacSystemManager.shared
    
    var body: some View {
        HStack(spacing: HealthAIDesignSystem.Spacing.xs) {
            // Sync Status
            MacStatusIndicator(
                icon: "arrow.clockwise",
                color: systemManager.syncStatus.color,
                isActive: systemManager.syncStatus == .syncing
            )
            
            // Analytics Status
            MacStatusIndicator(
                icon: "brain.head.profile",
                color: systemManager.analyticsStatus.color,
                isActive: systemManager.analyticsStatus == .processing
            )
        }
    }
}

// MARK: - Status Indicator
struct MacStatusIndicator: View {
    let icon: String
    let color: Color
    let isActive: Bool
    @State private var isRotating = false
    
    var body: some View {
        Image(systemName: icon)
            .font(.system(size: 10, weight: .medium))
            .foregroundColor(color)
            .rotationEffect(.degrees(isRotating ? 360 : 0))
            .animation(
                isActive ? 
                    .linear(duration: 1.0).repeatForever(autoreverses: false) : 
                    .default,
                value: isRotating
            )
            .onAppear {
                isRotating = isActive
            }
            .onChange(of: isActive) { newValue in
                isRotating = newValue
            }
    }
}

// MARK: - Menu Bar Popover
struct MacMenuBarPopover: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: HealthAIDesignSystem.Spacing.md) {
            // Header
            HStack {
                Text("HealthAI")
                    .font(HealthAIDesignSystem.Typography.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button("Settings") {
                    // Open settings
                    dismiss()
                }
                .buttonStyle(.bordered)
            }
            
            Divider()
            
            // Quick Actions
            VStack(spacing: HealthAIDesignSystem.Spacing.sm) {
                MacPopoverButton(
                    title: "Open Dashboard",
                    icon: "house.fill",
                    action: {
                        NSApp.activate(ignoringOtherApps: true)
                        dismiss()
                    }
                )
                
                MacPopoverButton(
                    title: "Quick Health Check",
                    icon: "heart.fill",
                    action: {
                        // Quick health check
                        dismiss()
                    }
                )
                
                MacPopoverButton(
                    title: "Start Workout",
                    icon: "figure.run",
                    action: {
                        // Start workout
                        dismiss()
                    }
                )
                
                MacPopoverButton(
                    title: "Log Water",
                    icon: "drop.fill",
                    action: {
                        // Log water
                        dismiss()
                    }
                )
            }
            
            Divider()
            
            // System Actions
            VStack(spacing: HealthAIDesignSystem.Spacing.sm) {
                MacPopoverButton(
                    title: "Sync Now",
                    icon: "arrow.clockwise",
                    action: {
                        // Sync data
                        dismiss()
                    }
                )
                
                MacPopoverButton(
                    title: "Export Data",
                    icon: "square.and.arrow.up",
                    action: {
                        // Export data
                        dismiss()
                    }
                )
                
                MacPopoverButton(
                    title: "Quit",
                    icon: "xmark.circle",
                    action: {
                        NSApplication.shared.terminate(nil)
                    }
                )
            }
        }
        .padding(HealthAIDesignSystem.Spacing.lg)
        .frame(width: 250)
    }
}

// MARK: - Popover Button
struct MacPopoverButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(HealthAIDesignSystem.Colors.primary)
                    .frame(width: 16)
                
                Text(title)
                    .font(HealthAIDesignSystem.Typography.body)
                    .foregroundColor(HealthAIDesignSystem.Colors.textPrimary)
                
                Spacer()
            }
            .padding(.horizontal, HealthAIDesignSystem.Spacing.sm)
            .padding(.vertical, HealthAIDesignSystem.Spacing.xs)
            .background(
                RoundedRectangle(cornerRadius: HealthAIDesignSystem.Layout.cornerRadiusSmall)
                    .fill(isHovered ? HealthAIDesignSystem.Colors.surface : Color.clear)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - Visual Effect View
struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}

// MARK: - Supporting Managers
class MacMenuBarManager: ObservableObject {
    static let shared = MacMenuBarManager()
    
    @Published var isVisible = true
    @Published var healthData = HealthData()
    
    private init() {}
}

class MacSystemManager: ObservableObject {
    static let shared = MacSystemManager()
    
    @Published var syncStatus: SyncStatus = .idle
    @Published var analyticsStatus: AnalyticsStatus = .idle
    
    private init() {}
}

enum SyncStatus {
    case idle, syncing, completed, error
    
    var color: Color {
        switch self {
        case .idle: return HealthAIDesignSystem.Colors.textSecondary
        case .syncing: return HealthAIDesignSystem.Colors.primary
        case .completed: return HealthAIDesignSystem.Colors.success
        case .error: return HealthAIDesignSystem.Colors.error
        }
    }
}

enum AnalyticsStatus {
    case idle, processing, completed, error
    
    var color: Color {
        switch self {
        case .idle: return HealthAIDesignSystem.Colors.textSecondary
        case .processing: return HealthAIDesignSystem.Colors.primary
        case .completed: return HealthAIDesignSystem.Colors.success
        case .error: return HealthAIDesignSystem.Colors.error
        }
    }
}

struct HealthData {
    var currentHeartRate: Double = 72.0
    var sleepQuality: Double = 0.85
    var activityLevel: Double = 0.65
} 
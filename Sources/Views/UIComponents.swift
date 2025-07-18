import SwiftUI
import Combine

// Component modules - to be implemented
// @_exported import struct CoreComponents.CoreComponents
// @_exported import struct HealthComponents.HealthComponents
// @_exported import struct ChartComponents.ChartComponents

// HIG-compliant color system is handled through system colors

// MARK: - Health App Colors (System Colors Only)
// Use system colors directly - no custom color definitions
// For health-specific colors, use HealthKit standard colors

// Custom gradients removed - use system materials instead

// MARK: - HIG-Compliant Button Styles
// Use native SwiftUI button styles instead of custom implementations
extension View {
    func primaryButtonStyle() -> some View {
        self
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .frame(maxWidth: .infinity)
    }
    
    func secondaryButtonStyle() -> some View {
        self
            .buttonStyle(.bordered)
            .controlSize(.large)
            .frame(maxWidth: .infinity)
    }
}

// Secondary button style is now handled by the extension above

// Icon button helper
extension View {
    func iconButtonStyle() -> some View {
        self
            .buttonStyle(.borderless)
            .controlSize(.large)
            .symbolRenderingMode(.hierarchical)
    }
}

// MARK: - HIG-Compliant Card Components
struct HealthCard<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        GroupBox {
            content
        }
        .groupBoxStyle(CardGroupBoxStyle())
    }
}

struct CardGroupBoxStyle: GroupBoxStyle {
    func makeBody(configuration: Configuration) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            configuration.content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

// MARK: - HIG-Compliant Progress Indicators
struct HealthProgressView: View {
    let value: Double
    let total: Double
    let label: String?
    
    init(value: Double, total: Double = 1.0, label: String? = nil) {
        self.value = value
        self.total = total
        self.label = label
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let label = label {
                HStack {
                    Text(label)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(Int(value / total * 100))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            ProgressView(value: value, total: total)
                .progressViewStyle(.linear)
                .tint(.accentColor)
        }
    }
}

// MARK: - HIG-Compliant Status Indicators
struct HealthStatusBadge: View {
    let title: String
    let systemImage: String
    let color: Color
    
    init(_ title: String, systemImage: String, color: Color = .accentColor) {
        self.title = title
        self.systemImage = systemImage
        self.color = color
    }
    
    var body: some View {
        Label(title, systemImage: systemImage)
            .font(.caption)
            .foregroundColor(color)
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .background(color.opacity(0.15))
            .clipShape(Capsule())
    }
}

// Common status badges
extension HealthStatusBadge {
    static func success(_ title: String) -> HealthStatusBadge {
        HealthStatusBadge(title, systemImage: "checkmark.circle.fill", color: .green)
    }
    
    static func warning(_ title: String) -> HealthStatusBadge {
        HealthStatusBadge(title, systemImage: "exclamationmark.triangle.fill", color: .orange)
    }
    
    static func error(_ title: String) -> HealthStatusBadge {
        HealthStatusBadge(title, systemImage: "xmark.circle.fill", color: .red)
    }
    
    static func info(_ title: String) -> HealthStatusBadge {
        HealthStatusBadge(title, systemImage: "info.circle.fill", color: .blue)
    }
}

// MARK: - HIG-Compliant Data Cards
struct HealthDataCard: View {
    let title: String
    let value: String
    let subtitle: String?
    let systemImage: String
    let trend: TrendDirection?
    
    enum TrendDirection {
        case up, down, neutral
        
        var icon: String {
            switch self {
            case .up: return "arrow.up.right"
            case .down: return "arrow.down.right"
            case .neutral: return "minus"
            }
        }
        
        var color: Color {
            switch self {
            case .up: return .green
            case .down: return .red
            case .neutral: return .secondary
            }
        }
    }
    
    init(
        title: String,
        value: String,
        subtitle: String? = nil,
        systemImage: String,
        trend: TrendDirection? = nil
    ) {
        self.title = title
        self.value = value
        self.subtitle = subtitle
        self.systemImage = systemImage
        self.trend = trend
    }
    
    var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(title)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            if let subtitle = subtitle {
                                Text(subtitle)
                                    .font(.caption2)
                                    .foregroundColor(.tertiary)
                            }
                        }
                    } icon: {
                        Image(systemName: systemImage)
                            .font(.title3)
                            .foregroundColor(.accentColor)
                    }
                    
                    Spacer()
                    
                    if let trend = trend {
                        Image(systemName: trend.icon)
                            .font(.caption)
                            .foregroundColor(trend.color)
                    }
                }
                
                Text(value)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }
        }
        .groupBoxStyle(CardGroupBoxStyle())
    }
}

// MARK: - HIG-Compliant List Items
struct HealthListRow<Trailing: View>: View {
    let title: String
    let subtitle: String?
    let systemImage: String
    let action: (() -> Void)?
    let trailing: Trailing
    
    init(
        title: String,
        subtitle: String? = nil,
        systemImage: String,
        action: (() -> Void)? = nil,
        @ViewBuilder trailing: () -> Trailing = { EmptyView() }
    ) {
        self.title = title
        self.subtitle = subtitle
        self.systemImage = systemImage
        self.action = action
        self.trailing = trailing()
    }
    
    var body: some View {
        HStack {
            Label {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            } icon: {
                Image(systemName: systemImage)
                    .font(.body)
                    .foregroundColor(.accentColor)
            }
            
            Spacer()
            
            trailing
                .foregroundColor(.secondary)
            
            if action != nil {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.tertiary)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            action?()
        }
    }
}

// MARK: - HIG-Compliant Animations
// Use subtle, system-consistent animations
extension View {
    func healthPulse() -> some View {
        self
            .symbolEffect(.pulse)
    }
    
    func healthBounce() -> some View {
        self
            .symbolEffect(.bounce)
    }
}

// MARK: - HIG-Compliant Loading States
struct HealthLoadingView: View {
    let message: String
    let progress: Double?
    
    init(message: String = "Loading...", progress: Double? = nil) {
        self.message = message
        self.progress = progress
    }
    
    var body: some View {
        VStack(spacing: 16) {
            if let progress = progress {
                ProgressView(value: progress)
                    .progressViewStyle(.circular)
            } else {
                ProgressView()
                    .progressViewStyle(.circular)
                    .controlSize(.large)
            }
            
            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: 300)
    }
}

// MARK: - HIG-Compliant Empty States
struct HealthEmptyState: View {
    let systemImage: String
    let title: String
    let message: String
    let action: (() -> Void)?
    let actionTitle: String?
    
    init(
        systemImage: String,
        title: String,
        message: String,
        action: (() -> Void)? = nil,
        actionTitle: String? = nil
    ) {
        self.systemImage = systemImage
        self.title = title
        self.message = message
        self.action = action
        self.actionTitle = actionTitle
    }
    
    var body: some View {
        ContentUnavailableView {
            Label(title, systemImage: systemImage)
        } description: {
            Text(message)
        } actions: {
            if let action = action, let actionTitle = actionTitle {
                Button(actionTitle, action: action)
                    .buttonStyle(.borderedProminent)
            }
        }
    }
}

// MARK: - HIG-Compliant View Extensions
extension View {
    // Removed custom animations in favor of system symbol effects
}

// All custom button styles have been removed in favor of native SwiftUI button styles

// MARK: - Haptic Feedback Manager

#if canImport(UIKit)
import UIKit

class HapticManager {
    static let shared = HapticManager()
    
    private init() {}
    
    func impact(style: UIImpactFeedbackGenerator.FeedbackStyle) {
        #if os(iOS)
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
        #endif
    }
    
    func notification(type: UINotificationFeedbackGenerator.FeedbackType) {
        #if os(iOS)
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(type)
        #endif
    }
    
    func selection() {
        #if os(iOS)
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        generator.selectionChanged()
        #endif
    }
}
#endif







// MARK: - View Extensions

extension View {
    func healthCard() -> some View {
        HealthCard {
            self
        }
    }
} 
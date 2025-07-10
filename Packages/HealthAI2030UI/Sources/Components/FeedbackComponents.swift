import SwiftUI

// MARK: - Alert Types
public enum HealthAIAlertType {
    case success
    case warning
    case error
    case info
    case critical
    case medical
}

// MARK: - HealthAI Alert
public struct HealthAIAlert: View {
    let type: HealthAIAlertType
    let title: String
    let message: String
    let icon: String?
    let actions: [AlertAction]
    let isDismissible: Bool
    let onDismiss: (() -> Void)?
    
    @State private var isVisible: Bool = true
    
    public init(
        type: HealthAIAlertType,
        title: String,
        message: String,
        icon: String? = nil,
        actions: [AlertAction] = [],
        isDismissible: Bool = true,
        onDismiss: (() -> Void)? = nil
    ) {
        self.type = type
        self.title = title
        self.message = message
        self.icon = icon
        self.actions = actions
        self.isDismissible = isDismissible
        self.onDismiss = onDismiss
    }
    
    public var body: some View {
        if isVisible {
            VStack(alignment: .leading, spacing: SpacingGrid.medium) {
                // Header
                HStack {
                    if let icon = icon {
                        Image(systemName: icon)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(iconColor)
                    }
                    
                    Text(title)
                        .font(TypographySystem.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(ColorPalette.textPrimary)
                    
                    Spacer()
                    
                    if isDismissible {
                        Button(action: dismiss) {
                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(ColorPalette.textSecondary)
                        }
                        .accessibilityLabel(Text("Dismiss alert"))
                    }
                }
                
                // Message
                Text(message)
                    .font(TypographySystem.body)
                    .foregroundColor(ColorPalette.textSecondary)
                    .multilineTextAlignment(.leading)
                
                // Actions
                if !actions.isEmpty {
                    HStack(spacing: SpacingGrid.medium) {
                        ForEach(actions, id: \.title) { action in
                            HealthAIButton(
                                title: action.title,
                                style: action.style,
                                size: .small,
                                action: action.handler
                            )
                        }
                    }
                }
            }
            .padding(SpacingGrid.large)
            .background(backgroundColor)
            .cornerRadius(SpacingGrid.medium)
            .overlay(
                RoundedRectangle(cornerRadius: SpacingGrid.medium)
                    .stroke(borderColor, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
            .transition(.move(edge: .top).combined(with: .opacity))
            .accessibilityElement(children: .contain)
            .accessibilityLabel(Text(accessibilityLabel))
            .accessibilityHint(Text(accessibilityHint))
        }
    }
    
    private func dismiss() {
        withAnimation(.easeInOut(duration: 0.3)) {
            isVisible = false
        }
        onDismiss?()
    }
    
    // MARK: - Style Properties
    private var backgroundColor: Color {
        switch type {
        case .success:
            return ColorPalette.success.opacity(0.1)
        case .warning:
            return ColorPalette.warning.opacity(0.1)
        case .error:
            return ColorPalette.critical.opacity(0.1)
        case .info:
            return ColorPalette.info.opacity(0.1)
        case .critical:
            return ColorPalette.critical.opacity(0.15)
        case .medical:
            return ColorPalette.healthPrimary.opacity(0.1)
        }
    }
    
    private var borderColor: Color {
        switch type {
        case .success:
            return ColorPalette.success
        case .warning:
            return ColorPalette.warning
        case .error:
            return ColorPalette.critical
        case .info:
            return ColorPalette.info
        case .critical:
            return ColorPalette.critical
        case .medical:
            return ColorPalette.healthPrimary
        }
    }
    
    private var iconColor: Color {
        switch type {
        case .success:
            return ColorPalette.success
        case .warning:
            return ColorPalette.warning
        case .error:
            return ColorPalette.critical
        case .info:
            return ColorPalette.info
        case .critical:
            return ColorPalette.critical
        case .medical:
            return ColorPalette.healthPrimary
        }
    }
    
    // MARK: - Accessibility Properties
    private var accessibilityLabel: String {
        return "\(type.rawValue) alert: \(title)"
    }
    
    private var accessibilityHint: String {
        return message
    }
}

// MARK: - Alert Action
public struct AlertAction {
    let title: String
    let style: HealthAIButtonStyle
    let handler: () -> Void
    
    public init(title: String, style: HealthAIButtonStyle = .primary, handler: @escaping () -> Void) {
        self.title = title
        self.style = style
        self.handler = handler
    }
}

// MARK: - Notification Types
public enum NotificationType {
    case success
    case warning
    case error
    case info
    case healthMetric
    case medical
}

// MARK: - HealthAI Notification
public struct HealthAINotification: View {
    let type: NotificationType
    let title: String
    let message: String?
    let icon: String?
    let duration: TimeInterval
    let onDismiss: (() -> Void)?
    
    @State private var isVisible: Bool = true
    @State private var offset: CGFloat = -100
    
    public init(
        type: NotificationType,
        title: String,
        message: String? = nil,
        icon: String? = nil,
        duration: TimeInterval = 4.0,
        onDismiss: (() -> Void)? = nil
    ) {
        self.type = type
        self.title = title
        self.message = message
        self.icon = icon
        self.duration = duration
        self.onDismiss = onDismiss
    }
    
    public var body: some View {
        if isVisible {
            HStack(spacing: SpacingGrid.medium) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(iconColor)
                }
                
                VStack(alignment: .leading, spacing: SpacingGrid.small) {
                    Text(title)
                        .font(TypographySystem.body.weight(.semibold))
                        .foregroundColor(ColorPalette.textPrimary)
                    
                    if let message = message {
                        Text(message)
                            .font(TypographySystem.caption)
                            .foregroundColor(ColorPalette.textSecondary)
                    }
                }
                
                Spacer()
                
                Button(action: dismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(ColorPalette.textSecondary)
                }
                .accessibilityLabel(Text("Dismiss notification"))
            }
            .padding(SpacingGrid.medium)
            .background(backgroundColor)
            .cornerRadius(SpacingGrid.medium)
            .overlay(
                RoundedRectangle(cornerRadius: SpacingGrid.medium)
                    .stroke(borderColor, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
            .offset(y: offset)
            .onAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    offset = 0
                }
                
                if duration > 0 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                        dismiss()
                    }
                }
            }
            .accessibilityElement(children: .contain)
            .accessibilityLabel(Text(accessibilityLabel))
            .accessibilityHint(Text(accessibilityHint))
        }
    }
    
    private func dismiss() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            offset = -100
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            isVisible = false
            onDismiss?()
        }
    }
    
    // MARK: - Style Properties
    private var backgroundColor: Color {
        switch type {
        case .success:
            return ColorPalette.success.opacity(0.1)
        case .warning:
            return ColorPalette.warning.opacity(0.1)
        case .error:
            return ColorPalette.critical.opacity(0.1)
        case .info:
            return ColorPalette.info.opacity(0.1)
        case .healthMetric:
            return ColorPalette.healthPrimary.opacity(0.1)
        case .medical:
            return ColorPalette.healthSecondary.opacity(0.1)
        }
    }
    
    private var borderColor: Color {
        switch type {
        case .success:
            return ColorPalette.success
        case .warning:
            return ColorPalette.warning
        case .error:
            return ColorPalette.critical
        case .info:
            return ColorPalette.info
        case .healthMetric:
            return ColorPalette.healthPrimary
        case .medical:
            return ColorPalette.healthSecondary
        }
    }
    
    private var iconColor: Color {
        switch type {
        case .success:
            return ColorPalette.success
        case .warning:
            return ColorPalette.warning
        case .error:
            return ColorPalette.critical
        case .info:
            return ColorPalette.info
        case .healthMetric:
            return ColorPalette.healthPrimary
        case .medical:
            return ColorPalette.healthSecondary
        }
    }
    
    // MARK: - Accessibility Properties
    private var accessibilityLabel: String {
        return "\(type.rawValue) notification: \(title)"
    }
    
    private var accessibilityHint: String {
        return message ?? "Double tap to dismiss"
    }
}

// MARK: - Progress Indicator Types
public enum ProgressIndicatorType {
    case linear
    case circular
    case healthMetric
    case medical
}

// MARK: - HealthAI Progress View
public struct HealthAIProgressView: View {
    let type: ProgressIndicatorType
    let progress: Double
    let title: String?
    let subtitle: String?
    let showPercentage: Bool
    let color: Color?
    
    public init(
        type: ProgressIndicatorType = .linear,
        progress: Double,
        title: String? = nil,
        subtitle: String? = nil,
        showPercentage: Bool = true,
        color: Color? = nil
    ) {
        self.type = type
        self.progress = max(0, min(1, progress))
        self.title = title
        self.subtitle = subtitle
        self.showPercentage = showPercentage
        self.color = color
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: SpacingGrid.small) {
            if let title = title {
                HStack {
                    Text(title)
                        .font(TypographySystem.body.weight(.medium))
                        .foregroundColor(ColorPalette.textPrimary)
                    
                    Spacer()
                    
                    if showPercentage {
                        Text("\(Int(progress * 100))%")
                            .font(TypographySystem.caption)
                            .foregroundColor(ColorPalette.textSecondary)
                    }
                }
            }
            
            switch type {
            case .linear:
                LinearProgressView(progress: progress, color: color)
            case .circular:
                CircularProgressView(progress: progress, color: color)
            case .healthMetric:
                HealthMetricProgressView(progress: progress, color: color)
            case .medical:
                MedicalProgressView(progress: progress, color: color)
            }
            
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(TypographySystem.caption)
                    .foregroundColor(ColorPalette.textSecondary)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text(accessibilityLabel))
        .accessibilityValue(Text("\(Int(progress * 100)) percent"))
    }
    
    private var accessibilityLabel: String {
        var label = "Progress indicator"
        if let title = title {
            label += " for \(title)"
        }
        return label
    }
}

// MARK: - Linear Progress View
private struct LinearProgressView: View {
    let progress: Double
    let color: Color?
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(ColorPalette.surface)
                    .frame(height: 8)
                    .cornerRadius(4)
                
                Rectangle()
                    .fill(progressColor)
                    .frame(width: geometry.size.width * progress, height: 8)
                    .cornerRadius(4)
                    .animation(.easeInOut(duration: 0.3), value: progress)
            }
        }
        .frame(height: 8)
    }
    
    private var progressColor: Color {
        return color ?? ColorPalette.primary
    }
}

// MARK: - Circular Progress View
private struct CircularProgressView: View {
    let progress: Double
    let color: Color?
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(ColorPalette.surface, lineWidth: 4)
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(progressColor, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.3), value: progress)
        }
        .frame(width: 40, height: 40)
    }
    
    private var progressColor: Color {
        return color ?? ColorPalette.primary
    }
}

// MARK: - Health Metric Progress View
private struct HealthMetricProgressView: View {
    let progress: Double
    let color: Color?
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(ColorPalette.surface)
                    .frame(height: 12)
                    .cornerRadius(6)
                
                Rectangle()
                    .fill(progressColor)
                    .frame(width: geometry.size.width * progress, height: 12)
                    .cornerRadius(6)
                    .animation(.easeInOut(duration: 0.3), value: progress)
            }
        }
        .frame(height: 12)
    }
    
    private var progressColor: Color {
        return color ?? ColorPalette.healthPrimary
    }
}

// MARK: - Medical Progress View
private struct MedicalProgressView: View {
    let progress: Double
    let color: Color?
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(ColorPalette.surface)
                    .frame(height: 6)
                    .cornerRadius(3)
                
                Rectangle()
                    .fill(progressColor)
                    .frame(width: geometry.size.width * progress, height: 6)
                    .cornerRadius(3)
                    .animation(.easeInOut(duration: 0.3), value: progress)
            }
        }
        .frame(height: 6)
    }
    
    private var progressColor: Color {
        return color ?? ColorPalette.healthSecondary
    }
}

// MARK: - Loading States

/// Loading spinner for health metrics
public struct HealthMetricLoadingView: View {
    let title: String
    let message: String?
    
    public init(title: String, message: String? = nil) {
        self.title = title
        self.message = message
    }
    
    public var body: some View {
        VStack(spacing: SpacingGrid.large) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: ColorPalette.healthPrimary))
                .scaleEffect(1.5)
            
            Text(title)
                .font(TypographySystem.healthMetricLabel)
                .fontWeight(.semibold)
                .foregroundColor(ColorPalette.textPrimary)
            
            if let message = message {
                Text(message)
                    .font(TypographySystem.caption)
                    .foregroundColor(ColorPalette.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(SpacingGrid.large)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text("Loading \(title.lowercased())"))
    }
}

/// Medical loading view
public struct MedicalLoadingView: View {
    let title: String
    let message: String?
    
    public init(title: String, message: String? = nil) {
        self.title = title
        self.message = message
    }
    
    public var body: some View {
        VStack(spacing: SpacingGrid.large) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: ColorPalette.healthSecondary))
                .scaleEffect(1.5)
            
            Text(title)
                .font(TypographySystem.medicalLabel)
                .fontWeight(.semibold)
                .foregroundColor(ColorPalette.textPrimary)
            
            if let message = message {
                Text(message)
                    .font(TypographySystem.medicalCaption)
                    .foregroundColor(ColorPalette.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(SpacingGrid.large)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text("Loading \(title.lowercased())"))
    }
}

// MARK: - Empty States

/// Empty state for health data
public struct HealthEmptyState: View {
    let title: String
    let message: String
    let icon: String
    let actionTitle: String?
    let action: (() -> Void)?
    
    public init(
        title: String,
        message: String,
        icon: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.message = message
        self.icon = icon
        self.actionTitle = actionTitle
        self.action = action
    }
    
    public var body: some View {
        VStack(spacing: SpacingGrid.large) {
            Image(systemName: icon)
                .font(.system(size: 48, weight: .light))
                .foregroundColor(ColorPalette.textSecondary)
            
            VStack(spacing: SpacingGrid.small) {
                Text(title)
                    .font(TypographySystem.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(ColorPalette.textPrimary)
                    .multilineTextAlignment(.center)
                
                Text(message)
                    .font(TypographySystem.body)
                    .foregroundColor(ColorPalette.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            if let actionTitle = actionTitle, let action = action {
                HealthAIButton(
                    title: actionTitle,
                    style: .primary,
                    action: action
                )
            }
        }
        .padding(SpacingGrid.large)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text("Empty state: \(title)"))
    }
}

// MARK: - Feedback Extensions

extension View {
    /// Show notification overlay
    public func showNotification(
        _ notification: HealthAINotification,
        isPresented: Binding<Bool>
    ) -> some View {
        self.overlay(
            Group {
                if isPresented.wrappedValue {
                    VStack {
                        notification
                            .padding()
                        Spacer()
                    }
                }
            }
        )
    }
    
    /// Show alert overlay
    public func showAlert(
        _ alert: HealthAIAlert,
        isPresented: Binding<Bool>
    ) -> some View {
        self.overlay(
            Group {
                if isPresented.wrappedValue {
                    alert
                        .padding()
                }
            }
        )
    }
} 
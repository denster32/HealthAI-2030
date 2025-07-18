import SwiftUI

/// Custom modifier for iPad split view behavior
struct iPadSplitViewModifier: ViewModifier {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    
    func body(content: Content) -> some View {
        content
            .navigationSplitViewStyle(.balanced)
            .navigationSplitViewColumnWidth(
                min: horizontalSizeClass == .regular ? 280 : 240,
                ideal: horizontalSizeClass == .regular ? 320 : 280
            )
            .navigationSplitViewPreferredCompactColumn(.sidebar)
    }
}

extension View {
    /// Applies iPad-specific split view styling
    func iPadSplitViewStyle() -> some View {
        modifier(iPadSplitViewModifier())
    }
}

/// Custom navigation split view for iPad with enhanced behavior
struct IPadNavigationSplitView<Sidebar: View, Content: View, Detail: View>: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    
    let sidebar: Sidebar
    let content: Content
    let detail: Detail
    
    init(
        @ViewBuilder sidebar: () -> Sidebar,
        @ViewBuilder content: () -> Content,
        @ViewBuilder detail: () -> Detail
    ) {
        self.sidebar = sidebar()
        self.content = content()
        self.detail = detail()
    }
    
    var body: some View {
        NavigationSplitView {
            sidebar
        } content: {
            content
        } detail: {
            detail
        }
        .iPadSplitViewStyle()
        .onAppear {
            configureSplitViewBehavior()
        }
    }
    
    private func configureSplitViewBehavior() {
        // Configure split view behavior based on device and orientation
        if horizontalSizeClass == .regular {
            // iPad in landscape or large screen
            // Enable balanced split view with sidebar preference
        } else {
            // iPhone or iPad in portrait
            // Use compact layout with sidebar preference
        }
    }
}

/// Custom sidebar style for iPad
struct IPadSidebarStyle: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    
    func body(content: Content) -> some View {
        content
            .background(
                Color(colorScheme == .dark ? .systemGray6 : .systemBackground)
                    .ignoresSafeArea()
            )
            .listStyle(.sidebar)
    }
}

extension View {
    /// Applies iPad-specific sidebar styling
    func iPadSidebarStyle() -> some View {
        modifier(IPadSidebarStyle())
    }
}

/// Custom content area style for iPad
struct IPadContentStyle: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    
    func body(content: Content) -> some View {
        content
            .background(
                Color(colorScheme == .dark ? .systemBackground : .systemGroupedBackground)
                    .ignoresSafeArea()
            )
            .listStyle(.insetGrouped)
    }
}

extension View {
    /// Applies iPad-specific content area styling
    func iPadContentStyle() -> some View {
        modifier(IPadContentStyle())
    }
}

/// Custom detail area style for iPad
struct IPadDetailStyle: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    
    func body(content: Content) -> some View {
        content
            .background(
                Color(colorScheme == .dark ? .systemBackground : .systemGroupedBackground)
                    .ignoresSafeArea()
            )
            .navigationBarTitleDisplayMode(.large)
    }
}

extension View {
    /// Applies iPad-specific detail area styling
    func iPadDetailStyle() -> some View {
        modifier(IPadDetailStyle())
    }
}

/// iPad-specific layout configuration
struct IPadLayoutConfiguration {
    static let sidebarMinWidth: CGFloat = 280
    static let sidebarIdealWidth: CGFloat = 320
    static let sidebarMaxWidth: CGFloat = 400
    
    static let contentMinWidth: CGFloat = 300
    static let contentIdealWidth: CGFloat = 400
    
    static let detailMinWidth: CGFloat = 400
    static let detailIdealWidth: CGFloat = 600
    
    static let cornerRadius: CGFloat = 12
    static let shadowRadius: CGFloat = 8
    static let shadowOpacity: Float = 0.1
    
    static let animationDuration: Double = 0.3
    static let springAnimation = Animation.spring(response: 0.3, dampingFraction: 0.8)
}

/// iPad-specific color scheme
struct IPadColorScheme {
    static let primaryBackground = Color(.systemBackground)
    static let secondaryBackground = Color(.systemGroupedBackground)
    static let tertiaryBackground = Color(.systemGray6)
    
    static let primaryText = Color(.label)
    static let secondaryText = Color(.secondaryLabel)
    static let tertiaryText = Color(.tertiaryLabel)
    
    static let accent = Color.blue
    static let success = Color.green
    static let warning = Color.orange
    static let error = Color.red
    
    static let cardBackground = Color(.secondarySystemBackground)
    static let cardBorder = Color(.separator)
}

/// iPad-specific spacing
struct IPadSpacing {
    static let small: CGFloat = 8
    static let medium: CGFloat = 16
    static let large: CGFloat = 24
    static let extraLarge: CGFloat = 32
    
    static let cardPadding: CGFloat = 20
    static let listRowPadding: CGFloat = 16
    static let sectionPadding: CGFloat = 24
}

/// iPad-specific typography
struct IPadTypography {
    static let largeTitle = Font.largeTitle.weight(.bold)
    static let title1 = Font.title.weight(.semibold)
    static let title2 = Font.title2.weight(.semibold)
    static let title3 = Font.title3.weight(.medium)
    static let headline = Font.headline.weight(.medium)
    static let body = Font.body
    static let callout = Font.callout
    static let subheadline = Font.subheadline
    static let footnote = Font.footnote
    static let caption = Font.caption
}

/// iPad-specific animation curves
struct IPadAnimations {
    static let standard = Animation.easeInOut(duration: 0.3)
    static let spring = Animation.spring(response: 0.3, dampingFraction: 0.8)
    static let bouncy = Animation.spring(response: 0.4, dampingFraction: 0.6)
    static let smooth = Animation.easeInOut(duration: 0.4)
}

/// iPad-specific haptic feedback
struct IPadHaptics {
    static func light() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
    
    static func medium() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
    
    static func heavy() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
        impactFeedback.impactOccurred()
    }
    
    static func selection() {
        let selectionFeedback = UISelectionFeedbackGenerator()
        selectionFeedback.selectionChanged()
    }
    
    static func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(type)
    }
}

/// iPad-specific accessibility
struct IPadAccessibility {
    static func configureForIPad(_ view: some View) -> some View {
        view
            .accessibilityAction(named: "Toggle Sidebar") {
                // Toggle sidebar action
            }
            .accessibilityAction(named: "Show Detail") {
                // Show detail action
            }
            .accessibilityAction(named: "Dismiss") {
                // Dismiss action
            }
    }
}

/// iPad-specific gesture handling
struct IPadGestures {
    static func swipeToDismiss(_ action: @escaping () -> Void) -> some Gesture {
        DragGesture()
            .onEnded { value in
                if value.translation.x > 100 {
                    action()
                }
            }
    }
    
    static func longPressToPreview(_ action: @escaping () -> Void) -> some Gesture {
        LongPressGesture(minimumDuration: 0.5)
            .onEnded { _ in
                action()
            }
    }
}

/// iPad-specific preview configuration
struct IPadPreviewConfiguration {
    static let deviceNames = [
        "iPad Pro (12.9-inch) (6th generation)",
        "iPad Pro (11-inch) (4th generation)",
        "iPad Air (5th generation)",
        "iPad (10th generation)",
        "iPad mini (6th generation)"
    ]
    
    static let orientations: [InterfaceOrientation] = [
        .portrait,
        .landscapeLeft,
        .landscapeRight
    ]
    
    static let colorSchemes: [ColorScheme] = [
        .light,
        .dark
    ]
}

/// iPad-specific environment values
struct IPadEnvironmentKey: EnvironmentKey {
    static let defaultValue = IPadEnvironment()
}

struct IPadEnvironment {
    let isIPad: Bool
    let isLandscape: Bool
    let isLargeScreen: Bool
    let supportsPencil: Bool
    let supportsKeyboard: Bool
    
    init() {
        self.isIPad = UIDevice.current.userInterfaceIdiom == .pad
        self.isLandscape = UIDevice.current.orientation.isLandscape
        self.isLargeScreen = UIScreen.main.bounds.width > 768
        self.supportsPencil = UIDevice.current.userInterfaceIdiom == .pad
        self.supportsKeyboard = UIDevice.current.userInterfaceIdiom == .pad
    }
}

extension EnvironmentValues {
    var iPadEnvironment: IPadEnvironment {
        get { self[IPadEnvironmentKey.self] }
        set { self[IPadEnvironmentKey.self] = newValue }
    }
}

/// iPad-specific view extensions
extension View {
    /// Applies iPad-specific styling and behavior
    func iPadOptimized() -> some View {
        self
            .environment(\.iPadEnvironment, IPadEnvironment())
            .iPadSplitViewStyle()
    }
    
    /// Applies iPad-specific card styling
    func iPadCard() -> some View {
        self
            .background(IPadColorScheme.cardBackground)
            .cornerRadius(IPadLayoutConfiguration.cornerRadius)
            .shadow(
                color: Color.black.opacity(Double(IPadLayoutConfiguration.shadowOpacity)),
                radius: IPadLayoutConfiguration.shadowRadius,
                x: 0,
                y: 2
            )
            .padding(.horizontal, IPadSpacing.medium)
    }
    
    /// Applies iPad-specific list row styling
    func iPadListRow() -> some View {
        self
            .padding(.vertical, IPadSpacing.small)
            .padding(.horizontal, IPadSpacing.medium)
            .background(IPadColorScheme.primaryBackground)
            .cornerRadius(IPadLayoutConfiguration.cornerRadius / 2)
    }
    
    /// Applies iPad-specific button styling
    func iPadButton() -> some View {
        self
            .padding(.horizontal, IPadSpacing.large)
            .padding(.vertical, IPadSpacing.medium)
            .background(IPadColorScheme.accent)
            .foregroundColor(.white)
            .cornerRadius(IPadLayoutConfiguration.cornerRadius)
            .font(IPadTypography.headline)
    }
} 
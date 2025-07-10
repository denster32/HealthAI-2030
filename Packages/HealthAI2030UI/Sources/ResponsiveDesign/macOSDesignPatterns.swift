import SwiftUI

// MARK: - macOS Design Patterns Manager
/// Comprehensive macOS-specific design patterns for HealthAI 2030
/// Provides desktop interface elements, window management, and macOS platform best practices
public class macOSDesignPatternsManager: ObservableObject {
    
    @Published public var windowSize: CGSize = CGSize(width: 800, height: 600)
    @Published public var isFullScreen: Bool = false
    @Published public var isCompactWidth: Bool = false
    @Published public var isCompactHeight: Bool = false
    @Published public var sidebarWidth: CGFloat = 250
    
    public static let shared = macOSDesignPatternsManager()
    
    private init() {
        setupWindowObserver()
        updateWindowInfo()
    }
    
    /// Setup observer for window changes
    private func setupWindowObserver() {
        NotificationCenter.default.addObserver(
            forName: NSWindow.didResizeNotification,
            object: nil,
            queue: .main
        ) { _ in
            self.handleWindowResize()
        }
        
        NotificationCenter.default.addObserver(
            forName: NSWindow.didEnterFullScreenNotification,
            object: nil,
            queue: .main
        ) { _ in
            self.handleFullScreenEnter()
        }
        
        NotificationCenter.default.addObserver(
            forName: NSWindow.didExitFullScreenNotification,
            object: nil,
            queue: .main
        ) { _ in
            self.handleFullScreenExit()
        }
    }
    
    /// Handle window resize
    private func handleWindowResize() {
        updateWindowInfo()
    }
    
    /// Handle full screen enter
    private func handleFullScreenEnter() {
        isFullScreen = true
        updateWindowInfo()
    }
    
    /// Handle full screen exit
    private func handleFullScreenExit() {
        isFullScreen = false
        updateWindowInfo()
    }
    
    /// Update window information
    private func updateWindowInfo() {
        // In a real implementation, this would get actual window size
        isCompactWidth = windowSize.width < 600
        isCompactHeight = windowSize.height < 400
    }
    
    /// Calculate optimal sidebar width
    public func calculateOptimalSidebarWidth() -> CGFloat {
        if isCompactWidth {
            return 200
        } else if windowSize.width > 1200 {
            return 300
        } else {
            return 250
        }
    }
}

// MARK: - macOS Layout Patterns
public struct macOSLayoutPatterns {
    
    // MARK: - Window Patterns
    
    /// Standard macOS window pattern
    public static func standardWindow<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(spacing: 0) {
            macOSWindowTitleBar(title: title)
            content()
        }
        .frame(minWidth: 600, minHeight: 400)
        .background(ColorPalette.background)
    }
    
    /// Healthcare application window pattern
    public static func healthcareWindow<Content: View>(
        title: String,
        subtitle: String? = nil,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(spacing: 0) {
            macOSHealthcareTitleBar(title: title, subtitle: subtitle)
            content()
        }
        .frame(minWidth: 800, minHeight: 600)
        .background(ColorPalette.background)
    }
    
    // MARK: - Sidebar Patterns
    
    /// Standard macOS sidebar pattern
    public static func standardSidebar<Content: View>(
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(spacing: 0) {
            content()
        }
        .frame(width: 250)
        .background(ColorPalette.sidebarBackground)
        .overlay(
            Rectangle()
                .frame(width: 1)
                .foregroundColor(ColorPalette.border),
            alignment: .trailing
        )
    }
    
    /// Healthcare sidebar pattern
    public static func healthcareSidebar<Content: View>(
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(spacing: 0) {
            macOSHealthcareSidebarHeader()
            content()
        }
        .frame(width: 250)
        .background(ColorPalette.sidebarBackground)
        .overlay(
            Rectangle()
                .frame(width: 1)
                .foregroundColor(ColorPalette.border),
            alignment: .trailing
        )
    }
    
    // MARK: - Toolbar Patterns
    
    /// Standard macOS toolbar pattern
    public static func standardToolbar<Content: View>(
        @ViewBuilder content: () -> Content
    ) -> some View {
        HStack(spacing: SpacingGrid.medium) {
            content()
        }
        .padding(SpacingGrid.medium)
        .background(ColorPalette.toolbarBackground)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(ColorPalette.border),
            alignment: .bottom
        )
    }
    
    /// Healthcare toolbar pattern
    public static func healthcareToolbar<Content: View>(
        @ViewBuilder content: () -> Content
    ) -> some View {
        HStack(spacing: SpacingGrid.medium) {
            content()
        }
        .padding(SpacingGrid.medium)
        .background(ColorPalette.toolbarBackground)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(ColorPalette.border),
            alignment: .bottom
        )
    }
    
    // MARK: - Content Area Patterns
    
    /// Standard macOS content area pattern
    public static func standardContentArea<Content: View>(
        @ViewBuilder content: () -> Content
    ) -> some View {
        ScrollView {
            VStack(spacing: SpacingGrid.large) {
                content()
            }
            .padding(SpacingGrid.large)
        }
        .background(ColorPalette.background)
    }
    
    /// Healthcare content area pattern
    public static func healthcareContentArea<Content: View>(
        @ViewBuilder content: () -> Content
    ) -> some View {
        ScrollView {
            VStack(spacing: SpacingGrid.large) {
                content()
            }
            .padding(SpacingGrid.large)
        }
        .background(ColorPalette.background)
    }
    
    // MARK: - Split View Patterns
    
    /// Standard macOS split view pattern
    public static func standardSplitView<Sidebar: View, Content: View>(
        @ViewBuilder sidebar: () -> Sidebar,
        @ViewBuilder content: () -> Content
    ) -> some View {
        HStack(spacing: 0) {
            sidebar()
            content()
        }
    }
    
    /// Healthcare split view pattern
    public static func healthcareSplitView<Sidebar: View, Content: View>(
        @ViewBuilder sidebar: () -> Sidebar,
        @ViewBuilder content: () -> Content
    ) -> some View {
        HStack(spacing: 0) {
            sidebar()
            content()
        }
    }
    
    // MARK: - Table Patterns
    
    /// Standard macOS table pattern
    public static func standardTable<Content: View>(
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(spacing: 0) {
            content()
        }
        .background(ColorPalette.background)
        .cornerRadius(SpacingGrid.small)
        .overlay(
            RoundedRectangle(cornerRadius: SpacingGrid.small)
                .stroke(ColorPalette.border, lineWidth: 1)
        )
    }
    
    /// Healthcare data table pattern
    public static func healthcareDataTable<Content: View>(
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(spacing: 0) {
            content()
        }
        .background(ColorPalette.background)
        .cornerRadius(SpacingGrid.medium)
        .overlay(
            RoundedRectangle(cornerRadius: SpacingGrid.medium)
                .stroke(ColorPalette.border, lineWidth: 1)
        )
    }
}

// MARK: - macOS Window Title Bar
private struct macOSWindowTitleBar: View {
    let title: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(TypographySystem.headline)
                .fontWeight(.semibold)
                .foregroundColor(ColorPalette.textPrimary)
            
            Spacer()
        }
        .padding(SpacingGrid.medium)
        .background(ColorPalette.titleBarBackground)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(ColorPalette.border),
            alignment: .bottom
        )
    }
}

// MARK: - macOS Healthcare Title Bar
private struct macOSHealthcareTitleBar: View {
    let title: String
    let subtitle: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: SpacingGrid.small) {
            Text(title)
                .font(TypographySystem.headline)
                .fontWeight(.semibold)
                .foregroundColor(ColorPalette.textPrimary)
            
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(TypographySystem.body)
                    .foregroundColor(ColorPalette.textSecondary)
            }
        }
        .padding(SpacingGrid.medium)
        .background(ColorPalette.titleBarBackground)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(ColorPalette.border),
            alignment: .bottom
        )
    }
}

// MARK: - macOS Healthcare Sidebar Header
private struct macOSHealthcareSidebarHeader: View {
    var body: some View {
        VStack(spacing: SpacingGrid.small) {
            Image(systemName: "heart.fill")
                .font(.system(size: 24))
                .foregroundColor(ColorPalette.healthPrimary)
            
            Text("HealthAI 2030")
                .font(TypographySystem.headline)
                .fontWeight(.bold)
                .foregroundColor(ColorPalette.textPrimary)
            
            Text("Healthcare Management")
                .font(TypographySystem.caption)
                .foregroundColor(ColorPalette.textSecondary)
        }
        .padding(SpacingGrid.medium)
        .background(ColorPalette.sidebarHeaderBackground)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(ColorPalette.border),
            alignment: .bottom
        )
    }
}

// MARK: - macOS Responsive Layout Modifiers
public extension View {
    
    /// Apply macOS-specific responsive layout
    func macOSResponsiveLayout() -> some View {
        self.modifier(macOSResponsiveLayoutModifier())
    }
    
    /// Apply macOS compact layout
    func macOSCompactLayout() -> some View {
        self.modifier(macOSCompactLayoutModifier())
    }
    
    /// Apply macOS large layout
    func macOSLargeLayout() -> some View {
        self.modifier(macOSLargeLayoutModifier())
    }
    
    /// Apply macOS window styling
    func macOSWindowStyle() -> some View {
        self.modifier(macOSWindowStyleModifier())
    }
}

// MARK: - macOS Responsive Layout Modifier
public struct macOSResponsiveLayoutModifier: ViewModifier {
    
    @ObservedObject private var patternsManager = macOSDesignPatternsManager.shared
    
    public func body(content: Content) -> some View {
        content
            .padding(.horizontal, getHorizontalPadding())
            .padding(.vertical, getVerticalPadding())
    }
    
    private func getHorizontalPadding() -> CGFloat {
        if patternsManager.isCompactWidth {
            return SpacingGrid.medium
        } else {
            return SpacingGrid.large
        }
    }
    
    private func getVerticalPadding() -> CGFloat {
        if patternsManager.isCompactHeight {
            return SpacingGrid.medium
        } else {
            return SpacingGrid.large
        }
    }
}

// MARK: - macOS Compact Layout Modifier
public struct macOSCompactLayoutModifier: ViewModifier {
    
    public func body(content: Content) -> some View {
        content
            .padding(.horizontal, SpacingGrid.medium)
            .padding(.vertical, SpacingGrid.medium)
    }
}

// MARK: - macOS Large Layout Modifier
public struct macOSLargeLayoutModifier: ViewModifier {
    
    public func body(content: Content) -> some View {
        content
            .padding(.horizontal, SpacingGrid.large)
            .padding(.vertical, SpacingGrid.large)
    }
}

// MARK: - macOS Window Style Modifier
public struct macOSWindowStyleModifier: ViewModifier {
    
    public func body(content: Content) -> some View {
        content
            .background(ColorPalette.background)
            .cornerRadius(SpacingGrid.medium)
            .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}

// MARK: - macOS Color Extensions
public extension ColorPalette {
    
    /// macOS-specific background colors
    static let sidebarBackground = Color(red: 0.95, green: 0.95, blue: 0.97)
    static let titleBarBackground = Color(red: 0.98, green: 0.98, blue: 0.98)
    static let toolbarBackground = Color(red: 0.96, green: 0.96, blue: 0.96)
    static let sidebarHeaderBackground = Color(red: 0.92, green: 0.92, blue: 0.94)
}

// MARK: - macOS Design Pattern Testing
public extension macOSDesignPatternsManager {
    
    /// Test window size detection
    func testWindowSizeDetection() -> String {
        return """
        Window Size: \(windowSize.width) x \(windowSize.height)
        Full Screen: \(isFullScreen)
        Compact Width: \(isCompactWidth)
        Compact Height: \(isCompactHeight)
        """
    }
    
    /// Test responsive layout
    func testResponsiveLayout() -> (horizontalPadding: CGFloat, verticalPadding: CGFloat) {
        let horizontalPadding: CGFloat = isCompactWidth ? SpacingGrid.medium : SpacingGrid.large
        let verticalPadding: CGFloat = isCompactHeight ? SpacingGrid.medium : SpacingGrid.large
        
        return (horizontalPadding, verticalPadding)
    }
    
    /// Get current layout configuration
    func getCurrentLayoutConfiguration() -> String {
        return """
        Window Size: \(windowSize.width) x \(windowSize.height)
        Full Screen: \(isFullScreen)
        Sidebar Width: \(sidebarWidth)
        """
    }
} 
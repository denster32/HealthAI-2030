import SwiftUI

// MARK: - Tab Switching Animations
/// Comprehensive tab switching animations for HealthAI 2030
/// Provides smooth transitions between tabs, tab bar animations, and tab state changes
public struct TabSwitchingAnimations {
    
    // MARK: - Tab Transitions
    
    /// Basic tab transitions
    public struct BasicTabTransitions {
        public static let fade = AnyTransition.opacity
        public static let slide = AnyTransition.asymmetric(
            insertion: .move(edge: .trailing),
            removal: .move(edge: .leading)
        )
        public static let slideReverse = AnyTransition.asymmetric(
            insertion: .move(edge: .leading),
            removal: .move(edge: .trailing)
        )
        public static let slideUp = AnyTransition.asymmetric(
            insertion: .move(edge: .bottom),
            removal: .move(edge: .top)
        )
        public static let slideDown = AnyTransition.asymmetric(
            insertion: .move(edge: .top),
            removal: .move(edge: .bottom)
        )
        public static let scale = AnyTransition.scale(scale: 0.9)
        public static let scaleUp = AnyTransition.scale(scale: 1.1)
        public static let rotate = AnyTransition.rotation3D(angle: 90, axis: (x: 0, y: 1, z: 0))
        public static let flip = AnyTransition.rotation3D(angle: 180, axis: (x: 0, y: 1, z: 0))
        public static let blur = AnyTransition.blur(radius: 10)
    }
    
    /// Advanced tab transitions
    public struct AdvancedTabTransitions {
        public static let morph = AnyTransition.scale(scale: 0.8).combined(with: .opacity).combined(with: .blur(radius: 5))
        public static let elastic = AnyTransition.scale(scale: 1.2).combined(with: .opacity)
        public static let bounce = AnyTransition.scale(scale: 1.1).combined(with: .opacity)
        public static let spring = AnyTransition.scale(scale: 1.05).combined(with: .opacity)
        public static let wave = AnyTransition.scale(scale: 0.9).combined(with: .opacity)
        public static let spiral = AnyTransition.rotation3D(angle: 360, axis: (x: 0, y: 0, z: 1)).combined(with: .scale(scale: 0.8))
        public static let cube = AnyTransition.rotation3D(angle: 90, axis: (x: 0, y: 1, z: 0))
        public static let card = AnyTransition.scale(scale: 0.9).combined(with: .opacity)
        public static let zoom = AnyTransition.scale(scale: 0.5).combined(with: .opacity)
        public static let dissolve = AnyTransition.opacity.combined(with: .blur(radius: 5))
    }
    
    /// Healthcare-specific tab transitions
    public struct HealthcareTabTransitions {
        public static let heartbeat = AnyTransition.scale(scale: 1.1).combined(with: .opacity)
        public static let pulse = AnyTransition.scale(scale: 1.05).combined(with: .opacity)
        public static let breathing = AnyTransition.scale(scale: 1.02).combined(with: .opacity)
        public static let scan = AnyTransition.opacity.combined(with: .blur(radius: 3))
        public static let xray = AnyTransition.opacity.combined(with: .blur(radius: 5))
        public static let microscope = AnyTransition.scale(scale: 0.1).combined(with: .opacity)
        public static let stethoscope = AnyTransition.opacity.combined(with: .move(edge: .bottom))
        public static let thermometer = AnyTransition.scale(scale: 0.1).combined(with: .opacity)
        public static let syringe = AnyTransition.scale(scale: 0.1).combined(with: .opacity)
        public static let pill = AnyTransition.scale(scale: 0.1).combined(with: .opacity)
    }
    
    /// Wellness tab transitions
    public struct WellnessTabTransitions {
        public static let meditation = AnyTransition.opacity.combined(with: .blur(radius: 2))
        public static let yoga = AnyTransition.scale(scale: 0.9).combined(with: .opacity)
        public static let exercise = AnyTransition.scale(scale: 1.1).combined(with: .opacity)
        public static let nutrition = AnyTransition.scale(scale: 0.8).combined(with: .opacity)
        public static let sleep = AnyTransition.opacity.combined(with: .blur(radius: 4))
        public static let mindfulness = AnyTransition.opacity.combined(with: .scale(scale: 0.95))
        public static let relaxation = AnyTransition.opacity.combined(with: .blur(radius: 3))
        public static let healing = AnyTransition.scale(scale: 1.05).combined(with: .opacity)
        public static let growth = AnyTransition.scale(scale: 1.1).combined(with: .opacity)
        public static let transformation = AnyTransition.scale(scale: 0.1).combined(with: .rotation3D(angle: 360, axis: (x: 0, y: 1, z: 0)))
    }
    
    // MARK: - Tab Bar Animations
    
    /// Tab bar visibility animations
    public struct TabBarVisibilityAnimations {
        public static let show = AnyTransition.move(edge: .bottom).combined(with: .opacity)
        public static let hide = AnyTransition.move(edge: .bottom).combined(with: .opacity)
        public static let fadeIn = AnyTransition.opacity
        public static let fadeOut = AnyTransition.opacity
        public static let slideIn = AnyTransition.move(edge: .bottom)
        public static let slideOut = AnyTransition.move(edge: .bottom)
        public static let scaleIn = AnyTransition.scale(scale: 0.9).combined(with: .opacity)
        public static let scaleOut = AnyTransition.scale(scale: 1.1).combined(with: .opacity)
        public static let blurIn = AnyTransition.blur(radius: 10).combined(with: .opacity)
        public static let blurOut = AnyTransition.blur(radius: 0).combined(with: .opacity)
    }
    
    /// Tab bar background animations
    public struct TabBarBackgroundAnimations {
        public static let transparent = AnyTransition.opacity
        public static let solid = AnyTransition.opacity
        public static let blur = AnyTransition.blur(radius: 10)
        public static let gradient = AnyTransition.opacity
        public static let glass = AnyTransition.opacity.combined(with: .blur(radius: 5))
        public static let frosted = AnyTransition.opacity.combined(with: .blur(radius: 8))
        public static let animated = AnyTransition.opacity
        public static let dynamic = AnyTransition.opacity
        public static let responsive = AnyTransition.opacity
        public static let adaptive = AnyTransition.opacity
    }
    
    /// Tab bar height animations
    public struct TabBarHeightAnimations {
        public static let expand = AnyTransition.scale(scale: 1.1, anchor: .bottom)
        public static let collapse = AnyTransition.scale(scale: 0.9, anchor: .bottom)
        public static let grow = AnyTransition.scale(scale: 1.05, anchor: .bottom)
        public static let shrink = AnyTransition.scale(scale: 0.95, anchor: .bottom)
        public static let stretch = AnyTransition.scale(scale: 1.2, anchor: .bottom)
        public static let compress = AnyTransition.scale(scale: 0.8, anchor: .bottom)
        public static let elastic = AnyTransition.scale(scale: 1.1, anchor: .bottom)
        public static let bouncy = AnyTransition.scale(scale: 1.05, anchor: .bottom)
        public static let smooth = AnyTransition.scale(scale: 1.02, anchor: .bottom)
        public static let responsive = AnyTransition.scale(scale: 1.1, anchor: .bottom)
    }
    
    // MARK: - Tab Item Animations
    
    /// Tab item selection animations
    public struct TabItemSelectionAnimations {
        public static let select = AnyTransition.scale(scale: 1.1).combined(with: .opacity)
        public static let deselect = AnyTransition.scale(scale: 1.0).combined(with: .opacity)
        public static let highlight = AnyTransition.scale(scale: 1.05).combined(with: .opacity)
        public static let unhighlight = AnyTransition.scale(scale: 1.0).combined(with: .opacity)
        public static let press = AnyTransition.scale(scale: 0.95)
        public static let release = AnyTransition.scale(scale: 1.0)
        public static let hover = AnyTransition.scale(scale: 1.05)
        public static let focus = AnyTransition.scale(scale: 1.1)
        public static let unfocus = AnyTransition.scale(scale: 1.0)
        public static let pulse = AnyTransition.scale(scale: 1.05)
    }
    
    /// Tab item icon animations
    public struct TabItemIconAnimations {
        public static let rotate = AnyTransition.rotation3D(angle: 180, axis: (x: 0, y: 0, z: 1))
        public static let spin = AnyTransition.rotation3D(angle: 360, axis: (x: 0, y: 0, z: 1))
        public static let bounce = AnyTransition.scale(scale: 1.2)
        public static let pulse = AnyTransition.scale(scale: 1.1)
        public static let shake = AnyTransition.rotation3D(angle: 10, axis: (x: 0, y: 0, z: 1))
        public static let wiggle = AnyTransition.rotation3D(angle: 5, axis: (x: 0, y: 0, z: 1))
        public static let flip = AnyTransition.rotation3D(angle: 180, axis: (x: 0, y: 1, z: 0))
        public static let scale = AnyTransition.scale(scale: 1.1)
        public static let glow = AnyTransition.opacity
        public static let sparkle = AnyTransition.opacity
    }
    
    /// Tab item label animations
    public struct TabItemLabelAnimations {
        public static let fadeIn = AnyTransition.opacity
        public static let fadeOut = AnyTransition.opacity
        public static let slideIn = AnyTransition.move(edge: .bottom)
        public static let slideOut = AnyTransition.move(edge: .top)
        public static let scaleIn = AnyTransition.scale(scale: 0.8)
        public static let scaleOut = AnyTransition.scale(scale: 1.2)
        public static let typewriter = AnyTransition.opacity
        public static let bounce = AnyTransition.scale(scale: 1.1)
        public static let pulse = AnyTransition.scale(scale: 1.05)
        public static let glow = AnyTransition.opacity
    }
    
    // MARK: - Tab State Animations
    
    /// Tab loading animations
    public struct TabLoadingAnimations {
        public static let loading = AnyTransition.opacity.combined(with: .blur(radius: 2))
        public static let loaded = AnyTransition.opacity
        public static let error = AnyTransition.shake
        public static let success = AnyTransition.scale(scale: 1.05).combined(with: .opacity)
        public static let warning = AnyTransition.pulse
        public static let disabled = AnyTransition.opacity
        public static let enabled = AnyTransition.opacity
        public static let active = AnyTransition.scale(scale: 1.1)
        public static let inactive = AnyTransition.scale(scale: 1.0)
        public static let selected = AnyTransition.scale(scale: 1.05)
        public static let unselected = AnyTransition.scale(scale: 1.0)
    }
    
    /// Tab notification animations
    public struct TabNotificationAnimations {
        public static let badge = AnyTransition.scale(scale: 0.1).combined(with: .opacity)
        public static let alert = AnyTransition.scale(scale: 1.2).combined(with: .opacity)
        public static let warning = AnyTransition.pulse
        public static let error = AnyTransition.shake
        public static let success = AnyTransition.scale(scale: 1.1).combined(with: .opacity)
        public static let info = AnyTransition.scale(scale: 1.05).combined(with: .opacity)
        public static let update = AnyTransition.scale(scale: 1.1).combined(with: .opacity)
        public static let sync = AnyTransition.rotation3D(angle: 360, axis: (x: 0, y: 0, z: 1))
        public static let download = AnyTransition.scale(scale: 1.1).combined(with: .opacity)
        public static let upload = AnyTransition.scale(scale: 1.1).combined(with: .opacity)
    }
    
    /// Tab progress animations
    public struct TabProgressAnimations {
        public static let progress = AnyTransition.scale(scale: 1.0, anchor: .leading)
        public static let completion = AnyTransition.scale(scale: 1.1).combined(with: .opacity)
        public static let milestone = AnyTransition.scale(scale: 1.05).combined(with: .opacity)
        public static let achievement = AnyTransition.scale(scale: 1.2).combined(with: .opacity)
        public static let goal = AnyTransition.scale(scale: 1.1).combined(with: .opacity)
        public static let target = AnyTransition.scale(scale: 1.05).combined(with: .opacity)
        public static let benchmark = AnyTransition.scale(scale: 1.1).combined(with: .opacity)
        public static let threshold = AnyTransition.scale(scale: 1.05).combined(with: .opacity)
        public static let limit = AnyTransition.scale(scale: 1.1).combined(with: .opacity)
        public static let range = AnyTransition.scale(scale: 1.05).combined(with: .opacity)
    }
    
    // MARK: - Platform-Specific Tab Animations
    
    /// iOS tab animations
    public struct iOSTabAnimations {
        public static let tabBar = AnyTransition.move(edge: .bottom)
        public static let tabItem = AnyTransition.scale(scale: 1.1)
        public static let tabContent = AnyTransition.opacity
        public static let tabBadge = AnyTransition.scale(scale: 0.1).combined(with: .opacity)
        public static let tabIndicator = AnyTransition.move(edge: .leading)
        public static let tabBackground = AnyTransition.opacity
        public static let tabShadow = AnyTransition.opacity
        public static let tabBorder = AnyTransition.opacity
        public static let tabGlow = AnyTransition.opacity
        public static let tabPulse = AnyTransition.scale(scale: 1.05)
    }
    
    /// macOS tab animations
    public struct macOSTabAnimations {
        public static let tabBar = AnyTransition.move(edge: .top)
        public static let tabItem = AnyTransition.scale(scale: 1.05)
        public static let tabContent = AnyTransition.opacity
        public static let tabBadge = AnyTransition.scale(scale: 0.8).combined(with: .opacity)
        public static let tabIndicator = AnyTransition.move(edge: .bottom)
        public static let tabBackground = AnyTransition.opacity
        public static let tabShadow = AnyTransition.opacity
        public static let tabBorder = AnyTransition.opacity
        public static let tabGlow = AnyTransition.opacity
        public static let tabPulse = AnyTransition.scale(scale: 1.02)
    }
    
    /// watchOS tab animations
    public struct watchOSTabAnimations {
        public static let tabBar = AnyTransition.scale(scale: 0.9).combined(with: .opacity)
        public static let tabItem = AnyTransition.scale(scale: 1.1)
        public static let tabContent = AnyTransition.opacity
        public static let tabBadge = AnyTransition.scale(scale: 0.5).combined(with: .opacity)
        public static let tabIndicator = AnyTransition.scale(scale: 1.1)
        public static let tabBackground = AnyTransition.opacity
        public static let tabShadow = AnyTransition.opacity
        public static let tabBorder = AnyTransition.opacity
        public static let tabGlow = AnyTransition.opacity
        public static let tabPulse = AnyTransition.scale(scale: 1.05)
    }
    
    /// tvOS tab animations
    public struct tvOSTabAnimations {
        public static let tabBar = AnyTransition.move(edge: .bottom)
        public static let tabItem = AnyTransition.scale(scale: 1.2)
        public static let tabContent = AnyTransition.opacity
        public static let tabBadge = AnyTransition.scale(scale: 1.1).combined(with: .opacity)
        public static let tabIndicator = AnyTransition.scale(scale: 1.1)
        public static let tabBackground = AnyTransition.opacity
        public static let tabShadow = AnyTransition.opacity
        public static let tabBorder = AnyTransition.opacity
        public static let tabGlow = AnyTransition.opacity
        public static let tabPulse = AnyTransition.scale(scale: 1.1)
    }
    
    // MARK: - Custom Animation Modifiers
    
    /// Tab animation modifiers
    public struct TabAnimationModifiers {
        public static func tabTransition(_ transition: AnyTransition, duration: Double = 0.3) -> some ViewModifier {
            return ViewModifier { content in
                content
                    .transition(transition)
                    .animation(.easeInOut(duration: duration), value: true)
            }
        }
        
        public static func platformTab(_ platform: TabPlatformType, duration: Double = 0.3) -> some ViewModifier {
            return ViewModifier { content in
                content
                    .transition(platform.transition)
                    .animation(.easeInOut(duration: duration), value: true)
            }
        }
        
        public static func tabState(_ state: TabStateType, duration: Double = 0.3) -> some ViewModifier {
            return ViewModifier { content in
                content
                    .transition(state.transition)
                    .animation(.easeInOut(duration: duration), value: true)
            }
        }
    }
    
    // MARK: - Animation Timing
    
    /// Tab animation timing
    public struct TabTiming {
        public static let fast = 0.2
        public static let normal = 0.3
        public static let slow = 0.5
        public static let verySlow = 0.8
        public static let responsive = 0.25
        public static let smooth = 0.4
        public static let snappy = 0.15
        public static let gentle = 0.6
        public static let bouncy = 0.35
        public static let elastic = 0.45
    }
    
    /// Tab animation curves
    public struct TabCurves {
        public static let linear = Animation.linear
        public static let easeIn = Animation.easeIn
        public static let easeOut = Animation.easeOut
        public static let easeInOut = Animation.easeInOut
        public static let spring = Animation.spring()
        public static let bouncy = Animation.spring(response: 0.5, dampingFraction: 0.6)
        public static let smooth = Animation.easeInOut(duration: 0.4)
        public static let snappy = Animation.spring(response: 0.3, dampingFraction: 0.8)
        public static let gentle = Animation.easeInOut(duration: 0.6)
        public static let responsive = Animation.spring(response: 0.4, dampingFraction: 0.7)
    }
}

// MARK: - Supporting Enums and Extensions
public enum TabPlatformType {
    case ios
    case macOS
    case watchOS
    case tvOS
    
    var transition: AnyTransition {
        switch self {
        case .ios:
            return TabSwitchingAnimations.iOSTabAnimations.tabContent
        case .macOS:
            return TabSwitchingAnimations.macOSTabAnimations.tabContent
        case .watchOS:
            return TabSwitchingAnimations.watchOSTabAnimations.tabContent
        case .tvOS:
            return TabSwitchingAnimations.tvOSTabAnimations.tabContent
        }
    }
}

public enum TabStateType {
    case loading
    case loaded
    case error
    case success
    case warning
    case disabled
    case enabled
    case active
    case inactive
    case selected
    case unselected
    
    var transition: AnyTransition {
        switch self {
        case .loading:
            return TabSwitchingAnimations.TabLoadingAnimations.loading
        case .loaded:
            return TabSwitchingAnimations.TabLoadingAnimations.loaded
        case .error:
            return TabSwitchingAnimations.TabLoadingAnimations.error
        case .success:
            return TabSwitchingAnimations.TabLoadingAnimations.success
        case .warning:
            return TabSwitchingAnimations.TabLoadingAnimations.warning
        case .disabled:
            return TabSwitchingAnimations.TabLoadingAnimations.disabled
        case .enabled:
            return TabSwitchingAnimations.TabLoadingAnimations.enabled
        case .active:
            return TabSwitchingAnimations.TabLoadingAnimations.active
        case .inactive:
            return TabSwitchingAnimations.TabLoadingAnimations.inactive
        case .selected:
            return TabSwitchingAnimations.TabLoadingAnimations.selected
        case .unselected:
            return TabSwitchingAnimations.TabLoadingAnimations.unselected
        }
    }
}

// MARK: - View Extensions
public extension View {
    func tabTransition(_ transition: AnyTransition, duration: Double = 0.3) -> some View {
        self.modifier(TabSwitchingAnimations.TabAnimationModifiers.tabTransition(transition, duration: duration))
    }
    
    func platformTab(_ platform: TabPlatformType, duration: Double = 0.3) -> some View {
        self.modifier(TabSwitchingAnimations.TabAnimationModifiers.platformTab(platform, duration: duration))
    }
    
    func tabState(_ state: TabStateType, duration: Double = 0.3) -> some View {
        self.modifier(TabSwitchingAnimations.TabAnimationModifiers.tabState(state, duration: duration))
    }
} 
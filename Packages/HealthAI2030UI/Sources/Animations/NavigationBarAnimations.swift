import SwiftUI

// MARK: - Navigation Bar Animations
/// Comprehensive navigation bar animations for HealthAI 2030
/// Provides smooth animations for navigation elements, headers, and navigation state changes
public struct NavigationBarAnimations {
    
    // MARK: - Navigation Bar States
    
    /// Navigation bar visibility animations
    public struct VisibilityAnimations {
        public static let show = AnyTransition.move(edge: .top).combined(with: .opacity)
        public static let hide = AnyTransition.move(edge: .top).combined(with: .opacity)
        public static let fadeIn = AnyTransition.opacity
        public static let fadeOut = AnyTransition.opacity
        public static let slideIn = AnyTransition.move(edge: .top)
        public static let slideOut = AnyTransition.move(edge: .top)
        public static let scaleIn = AnyTransition.scale(scale: 0.9).combined(with: .opacity)
        public static let scaleOut = AnyTransition.scale(scale: 1.1).combined(with: .opacity)
        public static let blurIn = AnyTransition.blur(radius: 10).combined(with: .opacity)
        public static let blurOut = AnyTransition.blur(radius: 0).combined(with: .opacity)
    }
    
    /// Navigation bar background animations
    public struct BackgroundAnimations {
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
    
    /// Navigation bar height animations
    public struct HeightAnimations {
        public static let expand = AnyTransition.scale(scale: 1.1, anchor: .top)
        public static let collapse = AnyTransition.scale(scale: 0.9, anchor: .top)
        public static let grow = AnyTransition.scale(scale: 1.05, anchor: .top)
        public static let shrink = AnyTransition.scale(scale: 0.95, anchor: .top)
        public static let stretch = AnyTransition.scale(scale: 1.2, anchor: .top)
        public static let compress = AnyTransition.scale(scale: 0.8, anchor: .top)
        public static let elastic = AnyTransition.scale(scale: 1.1, anchor: .top)
        public static let bouncy = AnyTransition.scale(scale: 1.05, anchor: .top)
        public static let smooth = AnyTransition.scale(scale: 1.02, anchor: .top)
        public static let responsive = AnyTransition.scale(scale: 1.1, anchor: .top)
    }
    
    // MARK: - Navigation Elements
    
    /// Title animations
    public struct TitleAnimations {
        public static let fadeIn = AnyTransition.opacity
        public static let fadeOut = AnyTransition.opacity
        public static let slideIn = AnyTransition.move(edge: .leading)
        public static let slideOut = AnyTransition.move(edge: .trailing)
        public static let scaleIn = AnyTransition.scale(scale: 0.8)
        public static let scaleOut = AnyTransition.scale(scale: 1.2)
        public static let typewriter = AnyTransition.opacity
        public static let bounce = AnyTransition.scale(scale: 1.1)
        public static let pulse = AnyTransition.scale(scale: 1.05)
        public static let glow = AnyTransition.opacity
    }
    
    /// Button animations
    public struct ButtonAnimations {
        public static let press = AnyTransition.scale(scale: 0.95)
        public static let release = AnyTransition.scale(scale: 1.0)
        public static let hover = AnyTransition.scale(scale: 1.05)
        public static let focus = AnyTransition.scale(scale: 1.1)
        public static let unfocus = AnyTransition.scale(scale: 1.0)
        public static let highlight = AnyTransition.opacity
        public static let disable = AnyTransition.opacity
        public static let enable = AnyTransition.opacity
        public static let loading = AnyTransition.rotation3D(angle: 360, axis: (x: 0, y: 0, z: 1))
        public static let success = AnyTransition.scale(scale: 1.2).combined(with: .opacity)
    }
    
    /// Icon animations
    public struct IconAnimations {
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
    
    // MARK: - Navigation Actions
    
    /// Back button animations
    public struct BackButtonAnimations {
        public static let appear = AnyTransition.move(edge: .leading).combined(with: .opacity)
        public static let disappear = AnyTransition.move(edge: .leading).combined(with: .opacity)
        public static let press = AnyTransition.scale(scale: 0.9)
        public static let release = AnyTransition.scale(scale: 1.0)
        public static let highlight = AnyTransition.scale(scale: 1.1)
        public static let pulse = AnyTransition.scale(scale: 1.05)
        public static let shake = AnyTransition.rotation3D(angle: 15, axis: (x: 0, y: 0, z: 1))
        public static let bounce = AnyTransition.scale(scale: 1.2)
        public static let glow = AnyTransition.opacity
        public static let fade = AnyTransition.opacity
    }
    
    /// Menu button animations
    public struct MenuButtonAnimations {
        public static let open = AnyTransition.rotation3D(angle: 90, axis: (x: 0, y: 0, z: 1))
        public static let close = AnyTransition.rotation3D(angle: -90, axis: (x: 0, y: 0, z: 1))
        public static let toggle = AnyTransition.rotation3D(angle: 180, axis: (x: 0, y: 0, z: 1))
        public static let press = AnyTransition.scale(scale: 0.9)
        public static let release = AnyTransition.scale(scale: 1.0)
        public static let highlight = AnyTransition.scale(scale: 1.1)
        public static let pulse = AnyTransition.scale(scale: 1.05)
        public static let bounce = AnyTransition.scale(scale: 1.2)
        public static let glow = AnyTransition.opacity
        public static let fade = AnyTransition.opacity
    }
    
    /// Action button animations
    public struct ActionButtonAnimations {
        public static let add = AnyTransition.scale(scale: 0.8).combined(with: .opacity)
        public static let remove = AnyTransition.scale(scale: 1.2).combined(with: .opacity)
        public static let edit = AnyTransition.rotation3D(angle: 90, axis: (x: 0, y: 0, z: 1))
        public static let save = AnyTransition.scale(scale: 1.1).combined(with: .opacity)
        public static let cancel = AnyTransition.scale(scale: 0.9).combined(with: .opacity)
        public static let confirm = AnyTransition.scale(scale: 1.2).combined(with: .opacity)
        public static let delete = AnyTransition.scale(scale: 0.8).combined(with: .opacity)
        public static let share = AnyTransition.scale(scale: 1.1).combined(with: .opacity)
        public static let search = AnyTransition.scale(scale: 1.05).combined(with: .opacity)
        public static let filter = AnyTransition.rotation3D(angle: 180, axis: (x: 0, y: 0, z: 1))
    }
    
    // MARK: - Navigation States
    
    /// Scroll-based animations
    public struct ScrollAnimations {
        public static let onScroll = AnyTransition.opacity
        public static let onScrollUp = AnyTransition.move(edge: .top)
        public static let onScrollDown = AnyTransition.move(edge: .top)
        public static let onScrollThreshold = AnyTransition.opacity
        public static let onScrollVelocity = AnyTransition.opacity
        public static let onScrollDistance = AnyTransition.opacity
        public static let onScrollDirection = AnyTransition.opacity
        public static let onScrollMomentum = AnyTransition.opacity
        public static let onScrollBounce = AnyTransition.opacity
        public static let onScrollEnd = AnyTransition.opacity
        public static let onScrollStart = AnyTransition.opacity
    }
    
    /// Focus-based animations
    public struct FocusAnimations {
        public static let onFocus = AnyTransition.scale(scale: 1.1).combined(with: .opacity)
        public static let onUnfocus = AnyTransition.scale(scale: 1.0).combined(with: .opacity)
        public static let onFocusChange = AnyTransition.opacity
        public static let onFocusEnter = AnyTransition.scale(scale: 1.05)
        public static let onFocusExit = AnyTransition.scale(scale: 1.0)
        public static let onFocusMove = AnyTransition.opacity
        public static let onFocusSelect = AnyTransition.scale(scale: 1.1)
        public static let onFocusDeselect = AnyTransition.scale(scale: 1.0)
        public static let onFocusHighlight = AnyTransition.opacity
        public static let onFocusGlow = AnyTransition.opacity
    }
    
    /// State-based animations
    public struct StateAnimations {
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
    }
    
    // MARK: - Platform-Specific Navigation
    
    /// iOS navigation animations
    public struct iOSNavigationAnimations {
        public static let push = AnyTransition.asymmetric(
            insertion: .move(edge: .trailing),
            removal: .move(edge: .leading)
        )
        public static let pop = AnyTransition.asymmetric(
            insertion: .move(edge: .leading),
            removal: .move(edge: .trailing)
        )
        public static let modal = AnyTransition.opacity.combined(with: .scale(scale: 0.9))
        public static let sheet = AnyTransition.move(edge: .bottom)
        public static let tab = AnyTransition.opacity
        public static let split = AnyTransition.opacity
        public static let stack = AnyTransition.asymmetric(
            insertion: .move(edge: .trailing),
            removal: .move(edge: .leading)
        )
        public static let navigation = AnyTransition.asymmetric(
            insertion: .move(edge: .trailing),
            removal: .move(edge: .leading)
        )
        public static let toolbar = AnyTransition.move(edge: .bottom)
        public static let statusBar = AnyTransition.move(edge: .top)
    }
    
    /// macOS navigation animations
    public struct macOSNavigationAnimations {
        public static let window = AnyTransition.scale(scale: 0.9).combined(with: .opacity)
        public static let panel = AnyTransition.move(edge: .trailing)
        public static let sidebar = AnyTransition.move(edge: .leading)
        public static let toolbar = AnyTransition.move(edge: .top)
        public static let statusBar = AnyTransition.move(edge: .bottom)
        public static let menu = AnyTransition.opacity.combined(with: .scale(scale: 0.95))
        public static let dialog = AnyTransition.scale(scale: 0.9).combined(with: .opacity)
        public static let alert = AnyTransition.scale(scale: 0.9).combined(with: .opacity)
        public static let notification = AnyTransition.move(edge: .top)
        public static let dock = AnyTransition.scale(scale: 0.8).combined(with: .opacity)
        public static let spotlight = AnyTransition.opacity.combined(with: .blur(radius: 5))
    }
    
    /// watchOS navigation animations
    public struct watchOSNavigationAnimations {
        public static let digitalCrown = AnyTransition.rotation3D(angle: 360, axis: (x: 0, y: 0, z: 1))
        public static let sideButton = AnyTransition.scale(scale: 0.9).combined(with: .opacity)
        public static let crown = AnyTransition.rotation3D(angle: 180, axis: (x: 0, y: 0, z: 1))
        public static let glance = AnyTransition.opacity.combined(with: .blur(radius: 2))
        public static let notification = AnyTransition.move(edge: .top)
        public static let complication = AnyTransition.scale(scale: 0.8).combined(with: .opacity)
        public static let workout = AnyTransition.scale(scale: 1.1).combined(with: .opacity)
        public static let heartRate = AnyTransition.scale(scale: 1.05).combined(with: .opacity)
        public static let activity = AnyTransition.scale(scale: 1.02).combined(with: .opacity)
        public static let health = AnyTransition.scale(scale: 1.1).combined(with: .opacity)
        public static let app = AnyTransition.scale(scale: 0.9).combined(with: .opacity)
    }
    
    /// tvOS navigation animations
    public struct tvOSNavigationAnimations {
        public static let focus = AnyTransition.scale(scale: 1.1).combined(with: .opacity)
        public static let unfocus = AnyTransition.scale(scale: 0.9).combined(with: .opacity)
        public static let selection = AnyTransition.scale(scale: 1.05).combined(with: .opacity)
        public static let navigation = AnyTransition.opacity.combined(with: .blur(radius: 3))
        public static let menu = AnyTransition.move(edge: .leading)
        public static let content = AnyTransition.opacity
        public static let video = AnyTransition.scale(scale: 0.9).combined(with: .opacity)
        public static let audio = AnyTransition.opacity.combined(with: .blur(radius: 2))
        public static let game = AnyTransition.scale(scale: 1.1).combined(with: .opacity)
        public static let app = AnyTransition.scale(scale: 0.8).combined(with: .opacity)
        public static let remote = AnyTransition.scale(scale: 1.05).combined(with: .opacity)
    }
    
    // MARK: - Custom Animation Modifiers
    
    /// Navigation animation modifiers
    public struct NavigationAnimationModifiers {
        public static func navigationTransition(_ transition: AnyTransition, duration: Double = 0.3) -> some ViewModifier {
            return ViewModifier { content in
                content
                    .transition(transition)
                    .animation(.easeInOut(duration: duration), value: true)
            }
        }
        
        public static func platformNavigation(_ platform: NavigationPlatformType, duration: Double = 0.3) -> some ViewModifier {
            return ViewModifier { content in
                content
                    .transition(platform.transition)
                    .animation(.easeInOut(duration: duration), value: true)
            }
        }
        
        public static func navigationState(_ state: NavigationStateType, duration: Double = 0.3) -> some ViewModifier {
            return ViewModifier { content in
                content
                    .transition(state.transition)
                    .animation(.easeInOut(duration: duration), value: true)
            }
        }
    }
    
    // MARK: - Animation Timing
    
    /// Navigation animation timing
    public struct NavigationTiming {
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
    
    /// Navigation animation curves
    public struct NavigationCurves {
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
public enum NavigationPlatformType {
    case ios
    case macOS
    case watchOS
    case tvOS
    
    var transition: AnyTransition {
        switch self {
        case .ios:
            return NavigationBarAnimations.iOSNavigationAnimations.push
        case .macOS:
            return NavigationBarAnimations.macOSNavigationAnimations.window
        case .watchOS:
            return NavigationBarAnimations.watchOSNavigationAnimations.digitalCrown
        case .tvOS:
            return NavigationBarAnimations.tvOSNavigationAnimations.focus
        }
    }
}

public enum NavigationStateType {
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
    
    var transition: AnyTransition {
        switch self {
        case .loading:
            return NavigationBarAnimations.StateAnimations.loading
        case .loaded:
            return NavigationBarAnimations.StateAnimations.loaded
        case .error:
            return NavigationBarAnimations.StateAnimations.error
        case .success:
            return NavigationBarAnimations.StateAnimations.success
        case .warning:
            return NavigationBarAnimations.StateAnimations.warning
        case .disabled:
            return NavigationBarAnimations.StateAnimations.disabled
        case .enabled:
            return NavigationBarAnimations.StateAnimations.enabled
        case .active:
            return NavigationBarAnimations.StateAnimations.active
        case .inactive:
            return NavigationBarAnimations.StateAnimations.inactive
        case .selected:
            return NavigationBarAnimations.StateAnimations.selected
        }
    }
}

// MARK: - Custom Transitions
public extension AnyTransition {
    static let shake = AnyTransition.modifier(
        active: ShakeModifier(amount: 10),
        identity: ShakeModifier(amount: 0)
    )
    
    static let pulse = AnyTransition.scale(scale: 1.1).combined(with: .opacity)
}

public struct ShakeModifier: ViewModifier {
    let amount: CGFloat
    
    func body(content: Content) -> some View {
        content
            .offset(x: amount)
            .animation(.easeInOut(duration: 0.1).repeatCount(3), value: amount)
    }
}

// MARK: - View Extensions
public extension View {
    func navigationTransition(_ transition: AnyTransition, duration: Double = 0.3) -> some View {
        self.modifier(NavigationBarAnimations.NavigationAnimationModifiers.navigationTransition(transition, duration: duration))
    }
    
    func platformNavigation(_ platform: NavigationPlatformType, duration: Double = 0.3) -> some View {
        self.modifier(NavigationBarAnimations.NavigationAnimationModifiers.platformNavigation(platform, duration: duration))
    }
    
    func navigationState(_ state: NavigationStateType, duration: Double = 0.3) -> some View {
        self.modifier(NavigationBarAnimations.NavigationAnimationModifiers.navigationState(state, duration: duration))
    }
} 
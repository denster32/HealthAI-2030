import SwiftUI

// MARK: - Page Transition Animations
/// Comprehensive page transition animations for HealthAI 2030
/// Provides smooth transitions between views, screens, and navigation states
public struct PageTransitionAnimations {
    
    // MARK: - Basic Transitions
    
    /// Fade transitions
    public struct FadeTransitions {
        public static let fadeIn = AnyTransition.opacity
        public static let fadeOut = AnyTransition.opacity
        public static let fadeInOut = AnyTransition.opacity
        public static let fadeInUp = AnyTransition.opacity.combined(with: .move(edge: .bottom))
        public static let fadeInDown = AnyTransition.opacity.combined(with: .move(edge: .top))
        public static let fadeInLeft = AnyTransition.opacity.combined(with: .move(edge: .trailing))
        public static let fadeInRight = AnyTransition.opacity.combined(with: .move(edge: .leading))
        public static let fadeInScale = AnyTransition.opacity.combined(with: .scale)
        public static let fadeInRotate = AnyTransition.opacity.combined(with: .rotation3D(angle: 90, axis: (x: 0, y: 1, z: 0)))
        public static let fadeInBlur = AnyTransition.opacity.combined(with: .blur(radius: 10))
    }
    
    /// Slide transitions
    public struct SlideTransitions {
        public static let slideInUp = AnyTransition.move(edge: .bottom)
        public static let slideInDown = AnyTransition.move(edge: .top)
        public static let slideInLeft = AnyTransition.move(edge: .trailing)
        public static let slideInRight = AnyTransition.move(edge: .leading)
        public static let slideOutUp = AnyTransition.move(edge: .top)
        public static let slideOutDown = AnyTransition.move(edge: .bottom)
        public static let slideOutLeft = AnyTransition.move(edge: .leading)
        public static let slideOutRight = AnyTransition.move(edge: .trailing)
        public static let slideInOut = AnyTransition.asymmetric(
            insertion: .move(edge: .trailing),
            removal: .move(edge: .leading)
        )
        public static let slideUpDown = AnyTransition.asymmetric(
            insertion: .move(edge: .bottom),
            removal: .move(edge: .top)
        )
    }
    
    /// Scale transitions
    public struct ScaleTransitions {
        public static let scaleIn = AnyTransition.scale(scale: 0.1)
        public static let scaleOut = AnyTransition.scale(scale: 2.0)
        public static let scaleInOut = AnyTransition.scale(scale: 0.5)
        public static let scaleInUp = AnyTransition.scale(scale: 0.1).combined(with: .move(edge: .bottom))
        public static let scaleInDown = AnyTransition.scale(scale: 0.1).combined(with: .move(edge: .top))
        public static let scaleInLeft = AnyTransition.scale(scale: 0.1).combined(with: .move(edge: .trailing))
        public static let scaleInRight = AnyTransition.scale(scale: 0.1).combined(with: .move(edge: .leading))
        public static let scaleInRotate = AnyTransition.scale(scale: 0.1).combined(with: .rotation3D(angle: 180, axis: (x: 0, y: 1, z: 0)))
        public static let scaleInBlur = AnyTransition.scale(scale: 0.1).combined(with: .blur(radius: 5))
        public static let scaleInFade = AnyTransition.scale(scale: 0.1).combined(with: .opacity)
    }
    
    // MARK: - Advanced Transitions
    
    /// 3D transitions
    public struct ThreeDTransitions {
        public static let rotate3D = AnyTransition.rotation3D(angle: 90, axis: (x: 0, y: 1, z: 0))
        public static let flipHorizontal = AnyTransition.rotation3D(angle: 180, axis: (x: 0, y: 1, z: 0))
        public static let flipVertical = AnyTransition.rotation3D(angle: 180, axis: (x: 1, y: 0, z: 0))
        public static let rotateIn = AnyTransition.rotation3D(angle: 360, axis: (x: 0, y: 0, z: 1))
        public static let rotateOut = AnyTransition.rotation3D(angle: -360, axis: (x: 0, y: 0, z: 1))
        public static let rotateInScale = AnyTransition.rotation3D(angle: 360, axis: (x: 0, y: 0, z: 1)).combined(with: .scale(scale: 0.1))
        public static let rotateInFade = AnyTransition.rotation3D(angle: 360, axis: (x: 0, y: 0, z: 1)).combined(with: .opacity)
        public static let rotateInSlide = AnyTransition.rotation3D(angle: 360, axis: (x: 0, y: 0, z: 1)).combined(with: .move(edge: .bottom))
        public static let rotateInBlur = AnyTransition.rotation3D(angle: 360, axis: (x: 0, y: 0, z: 1)).combined(with: .blur(radius: 10))
        public static let rotateInGlow = AnyTransition.rotation3D(angle: 360, axis: (x: 0, y: 0, z: 1)).combined(with: .opacity)
    }
    
    /// Morphing transitions
    public struct MorphingTransitions {
        public static let morphIn = AnyTransition.scale(scale: 0.1).combined(with: .opacity).combined(with: .blur(radius: 5))
        public static let morphOut = AnyTransition.scale(scale: 2.0).combined(with: .opacity).combined(with: .blur(radius: 5))
        public static let morphInOut = AnyTransition.asymmetric(
            insertion: .scale(scale: 0.1).combined(with: .opacity).combined(with: .blur(radius: 5)),
            removal: .scale(scale: 2.0).combined(with: .opacity).combined(with: .blur(radius: 5))
        )
        public static let morphInSlide = AnyTransition.scale(scale: 0.1).combined(with: .opacity).combined(with: .move(edge: .bottom))
        public static let morphInRotate = AnyTransition.scale(scale: 0.1).combined(with: .opacity).combined(with: .rotation3D(angle: 180, axis: (x: 0, y: 1, z: 0)))
        public static let morphInGlow = AnyTransition.scale(scale: 0.1).combined(with: .opacity)
        public static let morphInBounce = AnyTransition.scale(scale: 0.1).combined(with: .opacity)
        public static let morphInElastic = AnyTransition.scale(scale: 0.1).combined(with: .opacity)
        public static let morphInBack = AnyTransition.scale(scale: 0.1).combined(with: .opacity)
        public static let morphInCirc = AnyTransition.scale(scale: 0.1).combined(with: .opacity)
    }
    
    // MARK: - Healthcare-Specific Transitions
    
    /// Medical transitions
    public struct MedicalTransitions {
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
    
    /// Wellness transitions
    public struct WellnessTransitions {
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
    
    // MARK: - Platform-Specific Transitions
    
    /// iOS transitions
    public struct iOSTransitions {
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
        public static let fullScreen = AnyTransition.opacity
        public static let card = AnyTransition.scale(scale: 0.9).combined(with: .opacity)
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
    }
    
    /// macOS transitions
    public struct macOSTransitions {
        public static let window = AnyTransition.scale(scale: 0.9).combined(with: .opacity)
        public static let panel = AnyTransition.move(edge: .trailing)
        public static let sidebar = AnyTransition.move(edge: .leading)
        public static let toolbar = AnyTransition.move(edge: .top)
        public static let statusBar = AnyTransition.move(edge: .bottom)
        public static let dock = AnyTransition.scale(scale: 0.8).combined(with: .opacity)
        public static let menu = AnyTransition.opacity.combined(with: .scale(scale: 0.95))
        public static let dialog = AnyTransition.scale(scale: 0.9).combined(with: .opacity)
        public static let alert = AnyTransition.scale(scale: 0.9).combined(with: .opacity)
        public static let notification = AnyTransition.move(edge: .top)
    }
    
    /// watchOS transitions
    public struct watchOSTransitions {
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
    }
    
    /// tvOS transitions
    public struct tvOSTransitions {
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
    }
    
    // MARK: - Custom Transition Modifiers
    
    /// Transition modifiers
    public struct TransitionModifiers {
        public static func customTransition(_ transition: AnyTransition, duration: Double = 0.3) -> some ViewModifier {
            return ViewModifier { content in
                content
                    .transition(transition)
                    .animation(.easeInOut(duration: duration), value: true)
            }
        }
        
        public static func healthcareTransition(_ type: HealthcareTransitionType, duration: Double = 0.4) -> some ViewModifier {
            return ViewModifier { content in
                content
                    .transition(type.transition)
                    .animation(.easeInOut(duration: duration), value: true)
            }
        }
        
        public static func platformTransition(_ platform: PlatformType, duration: Double = 0.3) -> some ViewModifier {
            return ViewModifier { content in
                content
                    .transition(platform.transition)
                    .animation(.easeInOut(duration: duration), value: true)
            }
        }
    }
    
    // MARK: - Animation Timing
    
    /// Animation timing presets
    public struct AnimationTiming {
        public static let fast = 0.2
        public static let normal = 0.3
        public static let slow = 0.5
        public static let verySlow = 0.8
        public static let healthcare = 0.4
        public static let medical = 0.6
        public static let wellness = 0.35
        public static let emergency = 0.15
        public static let calming = 0.7
        public static let energetic = 0.25
    }
    
    /// Animation curves
    public struct AnimationCurves {
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
public enum HealthcareTransitionType {
    case heartbeat
    case pulse
    case breathing
    case scan
    case xray
    case microscope
    case stethoscope
    case thermometer
    case syringe
    case pill
    case meditation
    case yoga
    case exercise
    case nutrition
    case sleep
    case mindfulness
    case relaxation
    case healing
    case growth
    case transformation
    
    var transition: AnyTransition {
        switch self {
        case .heartbeat:
            return PageTransitionAnimations.MedicalTransitions.heartbeat
        case .pulse:
            return PageTransitionAnimations.MedicalTransitions.pulse
        case .breathing:
            return PageTransitionAnimations.MedicalTransitions.breathing
        case .scan:
            return PageTransitionAnimations.MedicalTransitions.scan
        case .xray:
            return PageTransitionAnimations.MedicalTransitions.xray
        case .microscope:
            return PageTransitionAnimations.MedicalTransitions.microscope
        case .stethoscope:
            return PageTransitionAnimations.MedicalTransitions.stethoscope
        case .thermometer:
            return PageTransitionAnimations.MedicalTransitions.thermometer
        case .syringe:
            return PageTransitionAnimations.MedicalTransitions.syringe
        case .pill:
            return PageTransitionAnimations.MedicalTransitions.pill
        case .meditation:
            return PageTransitionAnimations.WellnessTransitions.meditation
        case .yoga:
            return PageTransitionAnimations.WellnessTransitions.yoga
        case .exercise:
            return PageTransitionAnimations.WellnessTransitions.exercise
        case .nutrition:
            return PageTransitionAnimations.WellnessTransitions.nutrition
        case .sleep:
            return PageTransitionAnimations.WellnessTransitions.sleep
        case .mindfulness:
            return PageTransitionAnimations.WellnessTransitions.mindfulness
        case .relaxation:
            return PageTransitionAnimations.WellnessTransitions.relaxation
        case .healing:
            return PageTransitionAnimations.WellnessTransitions.healing
        case .growth:
            return PageTransitionAnimations.WellnessTransitions.growth
        case .transformation:
            return PageTransitionAnimations.WellnessTransitions.transformation
        }
    }
}

public enum PlatformType {
    case ios
    case macOS
    case watchOS
    case tvOS
    
    var transition: AnyTransition {
        switch self {
        case .ios:
            return PageTransitionAnimations.iOSTransitions.push
        case .macOS:
            return PageTransitionAnimations.macOSTransitions.window
        case .watchOS:
            return PageTransitionAnimations.watchOSTransitions.digitalCrown
        case .tvOS:
            return PageTransitionAnimations.tvOSTransitions.focus
        }
    }
}

// MARK: - View Extensions
public extension View {
    func healthcareTransition(_ type: HealthcareTransitionType, duration: Double = 0.4) -> some View {
        self.modifier(PageTransitionAnimations.TransitionModifiers.healthcareTransition(type, duration: duration))
    }
    
    func platformTransition(_ platform: PlatformType, duration: Double = 0.3) -> some View {
        self.modifier(PageTransitionAnimations.TransitionModifiers.platformTransition(platform, duration: duration))
    }
    
    func customTransition(_ transition: AnyTransition, duration: Double = 0.3) -> some View {
        self.modifier(PageTransitionAnimations.TransitionModifiers.customTransition(transition, duration: duration))
    }
} 
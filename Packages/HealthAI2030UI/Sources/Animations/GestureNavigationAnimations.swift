import SwiftUI

// MARK: - Gesture Navigation Animations
/// Comprehensive gesture navigation animations for HealthAI 2030
/// Provides smooth gesture-based navigation, swipe gestures, and interactive animations
public struct GestureNavigationAnimations {
    
    // MARK: - Swipe Gesture Animations
    
    /// Horizontal swipe animations
    public struct HorizontalSwipeAnimations {
        public static let swipeLeft = AnyTransition.move(edge: .trailing)
        public static let swipeRight = AnyTransition.move(edge: .leading)
        public static let swipeLeftOut = AnyTransition.move(edge: .leading)
        public static let swipeRightOut = AnyTransition.move(edge: .trailing)
        public static let swipeLeftIn = AnyTransition.move(edge: .trailing)
        public static let swipeRightIn = AnyTransition.move(edge: .leading)
        public static let swipeLeftScale = AnyTransition.move(edge: .trailing).combined(with: .scale(scale: 0.9))
        public static let swipeRightScale = AnyTransition.move(edge: .leading).combined(with: .scale(scale: 0.9))
        public static let swipeLeftRotate = AnyTransition.move(edge: .trailing).combined(with: .rotation3D(angle: 15, axis: (x: 0, y: 1, z: 0)))
        public static let swipeRightRotate = AnyTransition.move(edge: .leading).combined(with: .rotation3D(angle: -15, axis: (x: 0, y: 1, z: 0)))
    }
    
    /// Vertical swipe animations
    public struct VerticalSwipeAnimations {
        public static let swipeUp = AnyTransition.move(edge: .bottom)
        public static let swipeDown = AnyTransition.move(edge: .top)
        public static let swipeUpOut = AnyTransition.move(edge: .top)
        public static let swipeDownOut = AnyTransition.move(edge: .bottom)
        public static let swipeUpIn = AnyTransition.move(edge: .bottom)
        public static let swipeDownIn = AnyTransition.move(edge: .top)
        public static let swipeUpScale = AnyTransition.move(edge: .bottom).combined(with: .scale(scale: 0.9))
        public static let swipeDownScale = AnyTransition.move(edge: .top).combined(with: .scale(scale: 0.9))
        public static let swipeUpRotate = AnyTransition.move(edge: .bottom).combined(with: .rotation3D(angle: 15, axis: (x: 1, y: 0, z: 0)))
        public static let swipeDownRotate = AnyTransition.move(edge: .top).combined(with: .rotation3D(angle: -15, axis: (x: 1, y: 0, z: 0)))
    }
    
    /// Diagonal swipe animations
    public struct DiagonalSwipeAnimations {
        public static let swipeUpLeft = AnyTransition.move(edge: .bottom).combined(with: .move(edge: .trailing))
        public static let swipeUpRight = AnyTransition.move(edge: .bottom).combined(with: .move(edge: .leading))
        public static let swipeDownLeft = AnyTransition.move(edge: .top).combined(with: .move(edge: .trailing))
        public static let swipeDownRight = AnyTransition.move(edge: .top).combined(with: .move(edge: .leading))
        public static let swipeUpLeftScale = AnyTransition.move(edge: .bottom).combined(with: .move(edge: .trailing)).combined(with: .scale(scale: 0.9))
        public static let swipeUpRightScale = AnyTransition.move(edge: .bottom).combined(with: .move(edge: .leading)).combined(with: .scale(scale: 0.9))
        public static let swipeDownLeftScale = AnyTransition.move(edge: .top).combined(with: .move(edge: .trailing)).combined(with: .scale(scale: 0.9))
        public static let swipeDownRightScale = AnyTransition.move(edge: .top).combined(with: .move(edge: .leading)).combined(with: .scale(scale: 0.9))
        public static let swipeUpLeftRotate = AnyTransition.move(edge: .bottom).combined(with: .move(edge: .trailing)).combined(with: .rotation3D(angle: 15, axis: (x: 0, y: 0, z: 1)))
        public static let swipeUpRightRotate = AnyTransition.move(edge: .bottom).combined(with: .move(edge: .leading)).combined(with: .rotation3D(angle: -15, axis: (x: 0, y: 0, z: 1)))
    }
    
    // MARK: - Pinch Gesture Animations
    
    /// Pinch zoom animations
    public struct PinchZoomAnimations {
        public static let pinchIn = AnyTransition.scale(scale: 0.5)
        public static let pinchOut = AnyTransition.scale(scale: 2.0)
        public static let pinchInFade = AnyTransition.scale(scale: 0.5).combined(with: .opacity)
        public static let pinchOutFade = AnyTransition.scale(scale: 2.0).combined(with: .opacity)
        public static let pinchInBlur = AnyTransition.scale(scale: 0.5).combined(with: .blur(radius: 5))
        public static let pinchOutBlur = AnyTransition.scale(scale: 2.0).combined(with: .blur(radius: 5))
        public static let pinchInRotate = AnyTransition.scale(scale: 0.5).combined(with: .rotation3D(angle: 90, axis: (x: 0, y: 0, z: 1)))
        public static let pinchOutRotate = AnyTransition.scale(scale: 2.0).combined(with: .rotation3D(angle: -90, axis: (x: 0, y: 0, z: 1)))
        public static let pinchInElastic = AnyTransition.scale(scale: 0.3).combined(with: .opacity)
        public static let pinchOutElastic = AnyTransition.scale(scale: 3.0).combined(with: .opacity)
    }
    
    /// Pinch rotation animations
    public struct PinchRotationAnimations {
        public static let rotateClockwise = AnyTransition.rotation3D(angle: 90, axis: (x: 0, y: 0, z: 1))
        public static let rotateCounterClockwise = AnyTransition.rotation3D(angle: -90, axis: (x: 0, y: 0, z: 1))
        public static let rotate180 = AnyTransition.rotation3D(angle: 180, axis: (x: 0, y: 0, z: 1))
        public static let rotate360 = AnyTransition.rotation3D(angle: 360, axis: (x: 0, y: 0, z: 1))
        public static let rotateFlip = AnyTransition.rotation3D(angle: 180, axis: (x: 0, y: 1, z: 0))
        public static let rotateTilt = AnyTransition.rotation3D(angle: 45, axis: (x: 1, y: 0, z: 0))
        public static let rotateSpin = AnyTransition.rotation3D(angle: 720, axis: (x: 0, y: 0, z: 1))
        public static let rotateWobble = AnyTransition.rotation3D(angle: 15, axis: (x: 0, y: 0, z: 1))
        public static let rotateShake = AnyTransition.rotation3D(angle: 10, axis: (x: 0, y: 0, z: 1))
        public static let rotateBounce = AnyTransition.rotation3D(angle: 30, axis: (x: 0, y: 0, z: 1))
    }
    
    // MARK: - Long Press Gesture Animations
    
    /// Long press animations
    public struct LongPressAnimations {
        public static let press = AnyTransition.scale(scale: 0.95)
        public static let release = AnyTransition.scale(scale: 1.0)
        public static let hold = AnyTransition.scale(scale: 0.9)
        public static let trigger = AnyTransition.scale(scale: 1.1)
        public static let pressPulse = AnyTransition.scale(scale: 1.05)
        public static let pressGlow = AnyTransition.opacity
        public static let pressShake = AnyTransition.shake
        public static let pressBounce = AnyTransition.scale(scale: 1.2)
        public static let pressRotate = AnyTransition.rotation3D(angle: 15, axis: (x: 0, y: 0, z: 1))
        public static let pressBlur = AnyTransition.blur(radius: 3)
    }
    
    /// Long press feedback animations
    public struct LongPressFeedbackAnimations {
        public static let haptic = AnyTransition.scale(scale: 1.05)
        public static let visual = AnyTransition.opacity
        public static let audio = AnyTransition.scale(scale: 1.02)
        public static let tactile = AnyTransition.scale(scale: 1.03)
        public static let vibration = AnyTransition.shake
        public static let feedback = AnyTransition.scale(scale: 1.05)
        public static let response = AnyTransition.opacity
        public static let reaction = AnyTransition.scale(scale: 1.1)
        public static let confirmation = AnyTransition.scale(scale: 1.2)
        public static let acknowledgment = AnyTransition.opacity
    }
    
    // MARK: - Double Tap Gesture Animations
    
    /// Double tap animations
    public struct DoubleTapAnimations {
        public static let firstTap = AnyTransition.scale(scale: 0.95)
        public static let secondTap = AnyTransition.scale(scale: 1.1)
        public static let doubleTap = AnyTransition.scale(scale: 1.2)
        public static let doubleTapPulse = AnyTransition.scale(scale: 1.15)
        public static let doubleTapGlow = AnyTransition.opacity
        public static let doubleTapShake = AnyTransition.shake
        public static let doubleTapBounce = AnyTransition.scale(scale: 1.3)
        public static let doubleTapRotate = AnyTransition.rotation3D(angle: 30, axis: (x: 0, y: 0, z: 1))
        public static let doubleTapBlur = AnyTransition.blur(radius: 5)
        public static let doubleTapElastic = AnyTransition.scale(scale: 1.4)
    }
    
    /// Double tap action animations
    public struct DoubleTapActionAnimations {
        public static let like = AnyTransition.scale(scale: 1.3).combined(with: .opacity)
        public static let favorite = AnyTransition.scale(scale: 1.2).combined(with: .opacity)
        public static let bookmark = AnyTransition.scale(scale: 1.1).combined(with: .opacity)
        public static let share = AnyTransition.scale(scale: 1.2).combined(with: .opacity)
        public static let edit = AnyTransition.rotation3D(angle: 90, axis: (x: 0, y: 0, z: 1))
        public static let delete = AnyTransition.scale(scale: 0.8).combined(with: .opacity)
        public static let copy = AnyTransition.scale(scale: 1.1).combined(with: .opacity)
        public static let paste = AnyTransition.scale(scale: 1.1).combined(with: .opacity)
        public static let select = AnyTransition.scale(scale: 1.05).combined(with: .opacity)
        public static let deselect = AnyTransition.scale(scale: 1.0).combined(with: .opacity)
    }
    
    // MARK: - Drag Gesture Animations
    
    /// Drag animations
    public struct DragAnimations {
        public static let dragStart = AnyTransition.scale(scale: 0.95)
        public static let dragMove = AnyTransition.move(edge: .leading)
        public static let dragEnd = AnyTransition.scale(scale: 1.0)
        public static let dragCancel = AnyTransition.scale(scale: 1.0)
        public static let dragComplete = AnyTransition.scale(scale: 1.1)
        public static let dragSnap = AnyTransition.scale(scale: 1.05)
        public static let dragBounce = AnyTransition.scale(scale: 1.2)
        public static let dragElastic = AnyTransition.scale(scale: 1.3)
        public static let dragSpring = AnyTransition.scale(scale: 1.1)
        public static let dragMagnetic = AnyTransition.scale(scale: 1.05)
    }
    
    /// Drag feedback animations
    public struct DragFeedbackAnimations {
        public static let dragHaptic = AnyTransition.scale(scale: 1.02)
        public static let dragVisual = AnyTransition.opacity
        public static let dragAudio = AnyTransition.scale(scale: 1.01)
        public static let dragTactile = AnyTransition.scale(scale: 1.03)
        public static let dragVibration = AnyTransition.shake
        public static let dragFeedback = AnyTransition.scale(scale: 1.05)
        public static let dragResponse = AnyTransition.opacity
        public static let dragReaction = AnyTransition.scale(scale: 1.1)
        public static let dragConfirmation = AnyTransition.scale(scale: 1.2)
        public static let dragAcknowledgment = AnyTransition.opacity
    }
    
    // MARK: - Rotation Gesture Animations
    
    /// Rotation animations
    public struct RotationAnimations {
        public static let rotateStart = AnyTransition.rotation3D(angle: 0, axis: (x: 0, y: 0, z: 1))
        public static let rotateMove = AnyTransition.rotation3D(angle: 45, axis: (x: 0, y: 0, z: 1))
        public static let rotateEnd = AnyTransition.rotation3D(angle: 90, axis: (x: 0, y: 0, z: 1))
        public static let rotateCancel = AnyTransition.rotation3D(angle: 0, axis: (x: 0, y: 0, z: 1))
        public static let rotateComplete = AnyTransition.rotation3D(angle: 180, axis: (x: 0, y: 0, z: 1))
        public static let rotateSnap = AnyTransition.rotation3D(angle: 90, axis: (x: 0, y: 0, z: 1))
        public static let rotateBounce = AnyTransition.rotation3D(angle: 120, axis: (x: 0, y: 0, z: 1))
        public static let rotateElastic = AnyTransition.rotation3D(angle: 135, axis: (x: 0, y: 0, z: 1))
        public static let rotateSpring = AnyTransition.rotation3D(angle: 100, axis: (x: 0, y: 0, z: 1))
        public static let rotateMagnetic = AnyTransition.rotation3D(angle: 45, axis: (x: 0, y: 0, z: 1))
    }
    
    /// Rotation feedback animations
    public struct RotationFeedbackAnimations {
        public static let rotateHaptic = AnyTransition.rotation3D(angle: 5, axis: (x: 0, y: 0, z: 1))
        public static let rotateVisual = AnyTransition.opacity
        public static let rotateAudio = AnyTransition.rotation3D(angle: 2, axis: (x: 0, y: 0, z: 1))
        public static let rotateTactile = AnyTransition.rotation3D(angle: 3, axis: (x: 0, y: 0, z: 1))
        public static let rotateVibration = AnyTransition.shake
        public static let rotateFeedback = AnyTransition.rotation3D(angle: 10, axis: (x: 0, y: 0, z: 1))
        public static let rotateResponse = AnyTransition.opacity
        public static let rotateReaction = AnyTransition.rotation3D(angle: 15, axis: (x: 0, y: 0, z: 1))
        public static let rotateConfirmation = AnyTransition.rotation3D(angle: 20, axis: (x: 0, y: 0, z: 1))
        public static let rotateAcknowledgment = AnyTransition.opacity
    }
    
    // MARK: - Platform-Specific Gesture Animations
    
    /// iOS gesture animations
    public struct iOSGestureAnimations {
        public static let swipe = AnyTransition.move(edge: .trailing)
        public static let pinch = AnyTransition.scale(scale: 0.8)
        public static let longPress = AnyTransition.scale(scale: 0.95)
        public static let doubleTap = AnyTransition.scale(scale: 1.1)
        public static let drag = AnyTransition.move(edge: .leading)
        public static let rotate = AnyTransition.rotation3D(angle: 90, axis: (x: 0, y: 0, z: 1))
        public static let pan = AnyTransition.move(edge: .bottom)
        public static let tap = AnyTransition.scale(scale: 1.05)
        public static let hold = AnyTransition.scale(scale: 0.9)
        public static let release = AnyTransition.scale(scale: 1.0)
    }
    
    /// macOS gesture animations
    public struct macOSGestureAnimations {
        public static let swipe = AnyTransition.move(edge: .trailing)
        public static let pinch = AnyTransition.scale(scale: 0.9)
        public static let longPress = AnyTransition.scale(scale: 0.98)
        public static let doubleTap = AnyTransition.scale(scale: 1.05)
        public static let drag = AnyTransition.move(edge: .leading)
        public static let rotate = AnyTransition.rotation3D(angle: 45, axis: (x: 0, y: 0, z: 1))
        public static let pan = AnyTransition.move(edge: .bottom)
        public static let tap = AnyTransition.scale(scale: 1.02)
        public static let hold = AnyTransition.scale(scale: 0.95)
        public static let release = AnyTransition.scale(scale: 1.0)
    }
    
    /// watchOS gesture animations
    public struct watchOSGestureAnimations {
        public static let swipe = AnyTransition.scale(scale: 0.9)
        public static let pinch = AnyTransition.scale(scale: 0.7)
        public static let longPress = AnyTransition.scale(scale: 0.9)
        public static let doubleTap = AnyTransition.scale(scale: 1.2)
        public static let drag = AnyTransition.scale(scale: 0.8)
        public static let rotate = AnyTransition.rotation3D(angle: 90, axis: (x: 0, y: 0, z: 1))
        public static let pan = AnyTransition.scale(scale: 0.9)
        public static let tap = AnyTransition.scale(scale: 1.1)
        public static let hold = AnyTransition.scale(scale: 0.8)
        public static let release = AnyTransition.scale(scale: 1.0)
    }
    
    /// tvOS gesture animations
    public struct tvOSGestureAnimations {
        public static let swipe = AnyTransition.scale(scale: 1.1)
        public static let pinch = AnyTransition.scale(scale: 1.2)
        public static let longPress = AnyTransition.scale(scale: 1.05)
        public static let doubleTap = AnyTransition.scale(scale: 1.3)
        public static let drag = AnyTransition.scale(scale: 1.1)
        public static let rotate = AnyTransition.rotation3D(angle: 90, axis: (x: 0, y: 0, z: 1))
        public static let pan = AnyTransition.scale(scale: 1.1)
        public static let tap = AnyTransition.scale(scale: 1.2)
        public static let hold = AnyTransition.scale(scale: 1.1)
        public static let release = AnyTransition.scale(scale: 1.0)
    }
    
    // MARK: - Custom Animation Modifiers
    
    /// Gesture animation modifiers
    public struct GestureAnimationModifiers {
        public static func gestureTransition(_ transition: AnyTransition, duration: Double = 0.3) -> some ViewModifier {
            return ViewModifier { content in
                content
                    .transition(transition)
                    .animation(.easeInOut(duration: duration), value: true)
            }
        }
        
        public static func platformGesture(_ platform: GesturePlatformType, duration: Double = 0.3) -> some ViewModifier {
            return ViewModifier { content in
                content
                    .transition(platform.transition)
                    .animation(.easeInOut(duration: duration), value: true)
            }
        }
        
        public static func gestureType(_ type: GestureType, duration: Double = 0.3) -> some ViewModifier {
            return ViewModifier { content in
                content
                    .transition(type.transition)
                    .animation(.easeInOut(duration: duration), value: true)
            }
        }
    }
    
    // MARK: - Animation Timing
    
    /// Gesture animation timing
    public struct GestureTiming {
        public static let fast = 0.15
        public static let normal = 0.3
        public static let slow = 0.5
        public static let verySlow = 0.8
        public static let responsive = 0.2
        public static let smooth = 0.4
        public static let snappy = 0.1
        public static let gentle = 0.6
        public static let bouncy = 0.35
        public static let elastic = 0.45
    }
    
    /// Gesture animation curves
    public struct GestureCurves {
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
public enum GesturePlatformType {
    case ios
    case macOS
    case watchOS
    case tvOS
    
    var transition: AnyTransition {
        switch self {
        case .ios:
            return GestureNavigationAnimations.iOSGestureAnimations.swipe
        case .macOS:
            return GestureNavigationAnimations.macOSGestureAnimations.swipe
        case .watchOS:
            return GestureNavigationAnimations.watchOSGestureAnimations.swipe
        case .tvOS:
            return GestureNavigationAnimations.tvOSGestureAnimations.swipe
        }
    }
}

public enum GestureType {
    case swipe
    case pinch
    case longPress
    case doubleTap
    case drag
    case rotate
    case pan
    case tap
    case hold
    case release
    
    var transition: AnyTransition {
        switch self {
        case .swipe:
            return GestureNavigationAnimations.HorizontalSwipeAnimations.swipeLeft
        case .pinch:
            return GestureNavigationAnimations.PinchZoomAnimations.pinchIn
        case .longPress:
            return GestureNavigationAnimations.LongPressAnimations.press
        case .doubleTap:
            return GestureNavigationAnimations.DoubleTapAnimations.doubleTap
        case .drag:
            return GestureNavigationAnimations.DragAnimations.dragStart
        case .rotate:
            return GestureNavigationAnimations.RotationAnimations.rotateStart
        case .pan:
            return GestureNavigationAnimations.HorizontalSwipeAnimations.swipeLeft
        case .tap:
            return GestureNavigationAnimations.DoubleTapAnimations.firstTap
        case .hold:
            return GestureNavigationAnimations.LongPressAnimations.hold
        case .release:
            return GestureNavigationAnimations.LongPressAnimations.release
        }
    }
}

// MARK: - View Extensions
public extension View {
    func gestureTransition(_ transition: AnyTransition, duration: Double = 0.3) -> some View {
        self.modifier(GestureNavigationAnimations.GestureAnimationModifiers.gestureTransition(transition, duration: duration))
    }
    
    func platformGesture(_ platform: GesturePlatformType, duration: Double = 0.3) -> some View {
        self.modifier(GestureNavigationAnimations.GestureAnimationModifiers.platformGesture(platform, duration: duration))
    }
    
    func gestureType(_ type: GestureType, duration: Double = 0.3) -> some View {
        self.modifier(GestureNavigationAnimations.GestureAnimationModifiers.gestureType(type, duration: duration))
    }
} 
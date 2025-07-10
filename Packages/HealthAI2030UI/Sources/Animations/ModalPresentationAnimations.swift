import SwiftUI

// MARK: - Modal Presentation Animations
/// Comprehensive modal presentation animations for HealthAI 2030
/// Provides smooth modal presentations, dismissals, and various modal styles
public struct ModalPresentationAnimations {
    
    // MARK: - Modal Presentation Transitions
    
    /// Basic modal presentations
    public struct BasicModalPresentations {
        public static let fade = AnyTransition.opacity
        public static let slideUp = AnyTransition.move(edge: .bottom)
        public static let slideDown = AnyTransition.move(edge: .top)
        public static let slideLeft = AnyTransition.move(edge: .trailing)
        public static let slideRight = AnyTransition.move(edge: .leading)
        public static let scale = AnyTransition.scale(scale: 0.8)
        public static let scaleUp = AnyTransition.scale(scale: 1.2)
        public static let rotate = AnyTransition.rotation3D(angle: 90, axis: (x: 0, y: 1, z: 0))
        public static let flip = AnyTransition.rotation3D(angle: 180, axis: (x: 0, y: 1, z: 0))
        public static let blur = AnyTransition.blur(radius: 10)
    }
    
    /// Advanced modal presentations
    public struct AdvancedModalPresentations {
        public static let morph = AnyTransition.scale(scale: 0.5).combined(with: .opacity).combined(with: .blur(radius: 5))
        public static let elastic = AnyTransition.scale(scale: 1.3).combined(with: .opacity)
        public static let bounce = AnyTransition.scale(scale: 1.1).combined(with: .opacity)
        public static let spring = AnyTransition.scale(scale: 1.05).combined(with: .opacity)
        public static let wave = AnyTransition.scale(scale: 0.9).combined(with: .opacity)
        public static let spiral = AnyTransition.rotation3D(angle: 360, axis: (x: 0, y: 0, z: 1)).combined(with: .scale(scale: 0.8))
        public static let cube = AnyTransition.rotation3D(angle: 90, axis: (x: 0, y: 1, z: 0))
        public static let card = AnyTransition.scale(scale: 0.9).combined(with: .opacity)
        public static let zoom = AnyTransition.scale(scale: 0.3).combined(with: .opacity)
        public static let dissolve = AnyTransition.opacity.combined(with: .blur(radius: 5))
    }
    
    /// Healthcare-specific modal presentations
    public struct HealthcareModalPresentations {
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
    
    /// Wellness modal presentations
    public struct WellnessModalPresentations {
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
    
    // MARK: - Modal Dismissal Transitions
    
    /// Basic modal dismissals
    public struct BasicModalDismissals {
        public static let fade = AnyTransition.opacity
        public static let slideUp = AnyTransition.move(edge: .top)
        public static let slideDown = AnyTransition.move(edge: .bottom)
        public static let slideLeft = AnyTransition.move(edge: .leading)
        public static let slideRight = AnyTransition.move(edge: .trailing)
        public static let scale = AnyTransition.scale(scale: 1.2)
        public static let scaleDown = AnyTransition.scale(scale: 0.8)
        public static let rotate = AnyTransition.rotation3D(angle: -90, axis: (x: 0, y: 1, z: 0))
        public static let flip = AnyTransition.rotation3D(angle: -180, axis: (x: 0, y: 1, z: 0))
        public static let blur = AnyTransition.blur(radius: 0)
    }
    
    /// Advanced modal dismissals
    public struct AdvancedModalDismissals {
        public static let morph = AnyTransition.scale(scale: 2.0).combined(with: .opacity).combined(with: .blur(radius: 5))
        public static let elastic = AnyTransition.scale(scale: 0.7).combined(with: .opacity)
        public static let bounce = AnyTransition.scale(scale: 0.9).combined(with: .opacity)
        public static let spring = AnyTransition.scale(scale: 0.95).combined(with: .opacity)
        public static let wave = AnyTransition.scale(scale: 1.1).combined(with: .opacity)
        public static let spiral = AnyTransition.rotation3D(angle: -360, axis: (x: 0, y: 0, z: 1)).combined(with: .scale(scale: 1.2))
        public static let cube = AnyTransition.rotation3D(angle: -90, axis: (x: 0, y: 1, z: 0))
        public static let card = AnyTransition.scale(scale: 1.1).combined(with: .opacity)
        public static let zoom = AnyTransition.scale(scale: 3.0).combined(with: .opacity)
        public static let dissolve = AnyTransition.opacity.combined(with: .blur(radius: 0))
    }
    
    /// Healthcare-specific modal dismissals
    public struct HealthcareModalDismissals {
        public static let heartbeat = AnyTransition.scale(scale: 0.9).combined(with: .opacity)
        public static let pulse = AnyTransition.scale(scale: 0.95).combined(with: .opacity)
        public static let breathing = AnyTransition.scale(scale: 0.98).combined(with: .opacity)
        public static let scan = AnyTransition.opacity.combined(with: .blur(radius: 0))
        public static let xray = AnyTransition.opacity.combined(with: .blur(radius: 0))
        public static let microscope = AnyTransition.scale(scale: 10.0).combined(with: .opacity)
        public static let stethoscope = AnyTransition.opacity.combined(with: .move(edge: .top))
        public static let thermometer = AnyTransition.scale(scale: 10.0).combined(with: .opacity)
        public static let syringe = AnyTransition.scale(scale: 10.0).combined(with: .opacity)
        public static let pill = AnyTransition.scale(scale: 10.0).combined(with: .opacity)
    }
    
    // MARK: - Modal Styles
    
    /// Sheet modal styles
    public struct SheetModalStyles {
        public static let bottomSheet = AnyTransition.move(edge: .bottom)
        public static let topSheet = AnyTransition.move(edge: .top)
        public static let leftSheet = AnyTransition.move(edge: .leading)
        public static let rightSheet = AnyTransition.move(edge: .trailing)
        public static let centerSheet = AnyTransition.scale(scale: 0.8).combined(with: .opacity)
        public static let fullScreenSheet = AnyTransition.opacity
        public static let partialSheet = AnyTransition.scale(scale: 0.9).combined(with: .opacity)
        public static let floatingSheet = AnyTransition.scale(scale: 0.8).combined(with: .opacity)
        public static let cardSheet = AnyTransition.scale(scale: 0.9).combined(with: .opacity)
        public static let drawerSheet = AnyTransition.move(edge: .leading)
    }
    
    /// Alert modal styles
    public struct AlertModalStyles {
        public static let standardAlert = AnyTransition.scale(scale: 0.8).combined(with: .opacity)
        public static let actionSheet = AnyTransition.move(edge: .bottom)
        public static let confirmationDialog = AnyTransition.scale(scale: 0.9).combined(with: .opacity)
        public static let notificationAlert = AnyTransition.move(edge: .top)
        public static let warningAlert = AnyTransition.scale(scale: 0.8).combined(with: .opacity)
        public static let errorAlert = AnyTransition.shake
        public static let successAlert = AnyTransition.scale(scale: 1.1).combined(with: .opacity)
        public static let infoAlert = AnyTransition.scale(scale: 0.9).combined(with: .opacity)
        public static let customAlert = AnyTransition.scale(scale: 0.8).combined(with: .opacity)
        public static let modalAlert = AnyTransition.opacity.combined(with: .blur(radius: 5))
    }
    
    /// Dialog modal styles
    public struct DialogModalStyles {
        public static let standardDialog = AnyTransition.scale(scale: 0.8).combined(with: .opacity)
        public static let modalDialog = AnyTransition.opacity.combined(with: .blur(radius: 5))
        public static let popoverDialog = AnyTransition.scale(scale: 0.9).combined(with: .opacity)
        public static let tooltipDialog = AnyTransition.scale(scale: 0.8).combined(with: .opacity)
        public static let contextMenu = AnyTransition.scale(scale: 0.9).combined(with: .opacity)
        public static let dropdownDialog = AnyTransition.move(edge: .top)
        public static let slideoutDialog = AnyTransition.move(edge: .trailing)
        public static let drawerDialog = AnyTransition.move(edge: .leading)
        public static let overlayDialog = AnyTransition.opacity
        public static let floatingDialog = AnyTransition.scale(scale: 0.8).combined(with: .opacity)
    }
    
    // MARK: - Modal Background Animations
    
    /// Background overlay animations
    public struct BackgroundOverlayAnimations {
        public static let fadeIn = AnyTransition.opacity
        public static let fadeOut = AnyTransition.opacity
        public static let blurIn = AnyTransition.blur(radius: 10)
        public static let blurOut = AnyTransition.blur(radius: 0)
        public static let darkenIn = AnyTransition.opacity
        public static let darkenOut = AnyTransition.opacity
        public static let colorIn = AnyTransition.opacity
        public static let colorOut = AnyTransition.opacity
        public static let gradientIn = AnyTransition.opacity
        public static let gradientOut = AnyTransition.opacity
    }
    
    /// Background interaction animations
    public struct BackgroundInteractionAnimations {
        public static let tapToDismiss = AnyTransition.opacity
        public static let dragToDismiss = AnyTransition.move(edge: .bottom)
        public static let swipeToDismiss = AnyTransition.move(edge: .trailing)
        public static let pinchToDismiss = AnyTransition.scale(scale: 1.2)
        public static let shakeToDismiss = AnyTransition.shake
        public static let doubleTapToDismiss = AnyTransition.scale(scale: 1.1)
        public static let longPressToDismiss = AnyTransition.opacity
        public static let rotateToDismiss = AnyTransition.rotation3D(angle: 180, axis: (x: 0, y: 0, z: 1))
        public static let bounceToDismiss = AnyTransition.scale(scale: 1.1)
        public static let pulseToDismiss = AnyTransition.scale(scale: 1.05)
    }
    
    // MARK: - Modal Content Animations
    
    /// Content entrance animations
    public struct ContentEntranceAnimations {
        public static let slideIn = AnyTransition.move(edge: .bottom)
        public static let fadeIn = AnyTransition.opacity
        public static let scaleIn = AnyTransition.scale(scale: 0.8)
        public static let rotateIn = AnyTransition.rotation3D(angle: 90, axis: (x: 0, y: 1, z: 0))
        public static let flipIn = AnyTransition.rotation3D(angle: 180, axis: (x: 0, y: 1, z: 0))
        public static let bounceIn = AnyTransition.scale(scale: 1.2).combined(with: .opacity)
        public static let elasticIn = AnyTransition.scale(scale: 1.3).combined(with: .opacity)
        public static let springIn = AnyTransition.scale(scale: 1.1).combined(with: .opacity)
        public static let waveIn = AnyTransition.scale(scale: 0.9).combined(with: .opacity)
        public static let spiralIn = AnyTransition.rotation3D(angle: 360, axis: (x: 0, y: 0, z: 1)).combined(with: .scale(scale: 0.8))
    }
    
    /// Content exit animations
    public struct ContentExitAnimations {
        public static let slideOut = AnyTransition.move(edge: .top)
        public static let fadeOut = AnyTransition.opacity
        public static let scaleOut = AnyTransition.scale(scale: 1.2)
        public static let rotateOut = AnyTransition.rotation3D(angle: -90, axis: (x: 0, y: 1, z: 0))
        public static let flipOut = AnyTransition.rotation3D(angle: -180, axis: (x: 0, y: 1, z: 0))
        public static let bounceOut = AnyTransition.scale(scale: 0.8).combined(with: .opacity)
        public static let elasticOut = AnyTransition.scale(scale: 0.7).combined(with: .opacity)
        public static let springOut = AnyTransition.scale(scale: 0.9).combined(with: .opacity)
        public static let waveOut = AnyTransition.scale(scale: 1.1).combined(with: .opacity)
        public static let spiralOut = AnyTransition.rotation3D(angle: -360, axis: (x: 0, y: 0, z: 1)).combined(with: .scale(scale: 1.2))
    }
    
    // MARK: - Platform-Specific Modal Animations
    
    /// iOS modal animations
    public struct iOSModalAnimations {
        public static let sheet = AnyTransition.move(edge: .bottom)
        public static let fullScreen = AnyTransition.opacity
        public static let popover = AnyTransition.scale(scale: 0.9).combined(with: .opacity)
        public static let alert = AnyTransition.scale(scale: 0.8).combined(with: .opacity)
        public static let actionSheet = AnyTransition.move(edge: .bottom)
        public static let modal = AnyTransition.opacity.combined(with: .scale(scale: 0.9))
        public static let card = AnyTransition.scale(scale: 0.9).combined(with: .opacity)
        public static let drawer = AnyTransition.move(edge: .leading)
        public static let slideout = AnyTransition.move(edge: .trailing)
        public static let overlay = AnyTransition.opacity
    }
    
    /// macOS modal animations
    public struct macOSModalAnimations {
        public static let window = AnyTransition.scale(scale: 0.9).combined(with: .opacity)
        public static let panel = AnyTransition.move(edge: .trailing)
        public static let dialog = AnyTransition.scale(scale: 0.8).combined(with: .opacity)
        public static let alert = AnyTransition.scale(scale: 0.9).combined(with: .opacity)
        public static let sheet = AnyTransition.move(edge: .bottom)
        public static let popover = AnyTransition.scale(scale: 0.9).combined(with: .opacity)
        public static let tooltip = AnyTransition.scale(scale: 0.8).combined(with: .opacity)
        public static let contextMenu = AnyTransition.scale(scale: 0.9).combined(with: .opacity)
        public static let notification = AnyTransition.move(edge: .top)
        public static let overlay = AnyTransition.opacity
    }
    
    /// watchOS modal animations
    public struct watchOSModalAnimations {
        public static let sheet = AnyTransition.scale(scale: 0.8).combined(with: .opacity)
        public static let fullScreen = AnyTransition.opacity
        public static let alert = AnyTransition.scale(scale: 0.7).combined(with: .opacity)
        public static let actionSheet = AnyTransition.scale(scale: 0.8).combined(with: .opacity)
        public static let modal = AnyTransition.opacity.combined(with: .scale(scale: 0.8))
        public static let card = AnyTransition.scale(scale: 0.8).combined(with: .opacity)
        public static let drawer = AnyTransition.scale(scale: 0.9).combined(with: .opacity)
        public static let slideout = AnyTransition.scale(scale: 0.9).combined(with: .opacity)
        public static let overlay = AnyTransition.opacity
        public static let notification = AnyTransition.scale(scale: 0.8).combined(with: .opacity)
    }
    
    /// tvOS modal animations
    public struct tvOSModalAnimations {
        public static let sheet = AnyTransition.scale(scale: 1.1).combined(with: .opacity)
        public static let fullScreen = AnyTransition.opacity
        public static let alert = AnyTransition.scale(scale: 1.2).combined(with: .opacity)
        public static let actionSheet = AnyTransition.scale(scale: 1.1).combined(with: .opacity)
        public static let modal = AnyTransition.opacity.combined(with: .scale(scale: 1.1))
        public static let card = AnyTransition.scale(scale: 1.1).combined(with: .opacity)
        public static let drawer = AnyTransition.scale(scale: 1.2).combined(with: .opacity)
        public static let slideout = AnyTransition.scale(scale: 1.2).combined(with: .opacity)
        public static let overlay = AnyTransition.opacity
        public static let notification = AnyTransition.scale(scale: 1.1).combined(with: .opacity)
    }
    
    // MARK: - Custom Animation Modifiers
    
    /// Modal animation modifiers
    public struct ModalAnimationModifiers {
        public static func modalTransition(_ transition: AnyTransition, duration: Double = 0.3) -> some ViewModifier {
            return ViewModifier { content in
                content
                    .transition(transition)
                    .animation(.easeInOut(duration: duration), value: true)
            }
        }
        
        public static func platformModal(_ platform: ModalPlatformType, duration: Double = 0.3) -> some ViewModifier {
            return ViewModifier { content in
                content
                    .transition(platform.transition)
                    .animation(.easeInOut(duration: duration), value: true)
            }
        }
        
        public static func modalStyle(_ style: ModalStyleType, duration: Double = 0.3) -> some ViewModifier {
            return ViewModifier { content in
                content
                    .transition(style.transition)
                    .animation(.easeInOut(duration: duration), value: true)
            }
        }
    }
    
    // MARK: - Animation Timing
    
    /// Modal animation timing
    public struct ModalTiming {
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
    
    /// Modal animation curves
    public struct ModalCurves {
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
public enum ModalPlatformType {
    case ios
    case macOS
    case watchOS
    case tvOS
    
    var transition: AnyTransition {
        switch self {
        case .ios:
            return ModalPresentationAnimations.iOSModalAnimations.sheet
        case .macOS:
            return ModalPresentationAnimations.macOSModalAnimations.window
        case .watchOS:
            return ModalPresentationAnimations.watchOSModalAnimations.sheet
        case .tvOS:
            return ModalPresentationAnimations.tvOSModalAnimations.sheet
        }
    }
}

public enum ModalStyleType {
    case sheet
    case alert
    case dialog
    case popover
    case fullScreen
    case card
    case drawer
    case slideout
    case overlay
    case notification
    
    var transition: AnyTransition {
        switch self {
        case .sheet:
            return ModalPresentationAnimations.SheetModalStyles.bottomSheet
        case .alert:
            return ModalPresentationAnimations.AlertModalStyles.standardAlert
        case .dialog:
            return ModalPresentationAnimations.DialogModalStyles.standardDialog
        case .popover:
            return ModalPresentationAnimations.SheetModalStyles.centerSheet
        case .fullScreen:
            return ModalPresentationAnimations.BasicModalPresentations.fade
        case .card:
            return ModalPresentationAnimations.SheetModalStyles.cardSheet
        case .drawer:
            return ModalPresentationAnimations.SheetModalStyles.drawerSheet
        case .slideout:
            return ModalPresentationAnimations.SheetModalStyles.rightSheet
        case .overlay:
            return ModalPresentationAnimations.BasicModalPresentations.fade
        case .notification:
            return ModalPresentationAnimations.AlertModalStyles.notificationAlert
        }
    }
}

// MARK: - View Extensions
public extension View {
    func modalTransition(_ transition: AnyTransition, duration: Double = 0.3) -> some View {
        self.modifier(ModalPresentationAnimations.ModalAnimationModifiers.modalTransition(transition, duration: duration))
    }
    
    func platformModal(_ platform: ModalPlatformType, duration: Double = 0.3) -> some View {
        self.modifier(ModalPresentationAnimations.ModalAnimationModifiers.platformModal(platform, duration: duration))
    }
    
    func modalStyle(_ style: ModalStyleType, duration: Double = 0.3) -> some View {
        self.modifier(ModalPresentationAnimations.ModalAnimationModifiers.modalStyle(style, duration: duration))
    }
} 
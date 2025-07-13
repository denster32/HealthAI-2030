import SwiftUI

// MARK: - Musculoskeletal Illustrations
/// Detailed musculoskeletal anatomical illustrations for HealthAI 2030
/// Provides comprehensive bone anatomy, muscle structure, and joint mechanics visualizations for health education
public struct MusculoskeletalIllustrations {
    
    // MARK: - Skeletal System
    
    /// Axial skeleton illustrations
    public struct AxialSkeleton {
        public static let skull = "circle.fill"
        public static let vertebralColumn = "line.diagonal"
        public static let cervicalVertebrae = "line.diagonal"
        public static let thoracicVertebrae = "line.diagonal"
        public static let lumbarVertebrae = "line.diagonal"
        public static let sacrum = "line.diagonal"
        public static let coccyx = "line.diagonal"
        public static let ribs = "line.diagonal"
        public static let sternum = "line.diagonal"
        public static let hyoidBone = "circle.fill"
    }
    
    /// Appendicular skeleton illustrations
    public struct AppendicularSkeleton {
        public static let shoulderGirdle = "line.diagonal"
        public static let upperLimbs = "line.diagonal"
        public static let pelvicGirdle = "circle.fill"
        public static let lowerLimbs = "line.diagonal"
        public static let clavicle = "line.diagonal"
        public static let scapula = "line.diagonal"
        public static let humerus = "line.diagonal"
        public static let radius = "line.diagonal"
        public static let ulna = "line.diagonal"
        public static let femur = "line.diagonal"
    }
    
    /// Hand and foot illustrations
    public struct HandAndFoot {
        public static let carpalBones = "circle.fill"
        public static let metacarpals = "line.diagonal"
        public static let phalanges = "line.diagonal"
        public static let tarsalBones = "circle.fill"
        public static let metatarsals = "line.diagonal"
        public static let toePhalanges = "line.diagonal"
        public static let handArches = "circle.fill"
        public static let footArches = "circle.fill"
        public static let sesamoidBones = "circle.fill"
        public static let accessoryBones = "circle.fill"
    }
    
    // MARK: - Bone Structure
    
    /// Bone anatomy illustrations
    public struct BoneAnatomy {
        public static let compactBone = "ruler.fill"
        public static let spongyBone = "ruler.fill"
        public static let boneMarrow = "drop.fill"
        public static let periosteum = "ruler.fill"
        public static let endosteum = "ruler.fill"
        public static let haversianCanals = "line.diagonal"
        public static let osteocytes = "circle.fill"
        public static let osteoblasts = "circle.fill"
        public static let osteoclasts = "circle.fill"
        public static let boneMatrix = "ruler.fill"
    }
    
    /// Bone development illustrations
    public struct BoneDevelopment {
        public static let ossification = "ruler.fill"
        public static let growthPlates = "line.diagonal"
        public static let boneRemodeling = "ruler.fill"
        public static let boneHealing = "ruler.fill"
        public static let callusFormation = "ruler.fill"
        public static let boneResorption = "ruler.fill"
        public static let boneFormation = "ruler.fill"
        public static let mineralization = "ruler.fill"
        public static let calcification = "ruler.fill"
        public static let boneMaturation = "ruler.fill"
    }
    
    /// Bone pathology illustrations
    public struct BonePathology {
        public static let osteoporosis = "ruler.fill"
        public static let osteomalacia = "ruler.fill"
        public static let pagetDisease = "ruler.fill"
        public static let boneTumor = "ruler.fill"
        public static let boneInfection = "ruler.fill"
        public static let boneFracture = "ruler.fill"
        public static let boneDeformity = "ruler.fill"
        public static let boneCyst = "circle.fill"
        public static let boneSclerosis = "ruler.fill"
        public static let boneAtrophy = "ruler.fill"
    }
    
    // MARK: - Joint Anatomy
    
    /// Joint types illustrations
    public struct JointTypes {
        public static let synovialJoint = "circle.fill"
        public static let fibrousJoint = "circle.fill"
        public static let cartilaginousJoint = "circle.fill"
        public static let ballAndSocket = "circle.fill"
        public static let hingeJoint = "circle.fill"
        public static let pivotJoint = "circle.fill"
        public static let saddleJoint = "circle.fill"
        public static let condyloidJoint = "circle.fill"
        public static let planeJoint = "circle.fill"
        public static let ellipsoidJoint = "circle.fill"
    }
    
    /// Joint structure illustrations
    public struct JointStructure {
        public static let jointCapsule = "circle.fill"
        public static let synovialMembrane = "circle.fill"
        public static let synovialFluid = "drop.fill"
        public static let articularCartilage = "circle.fill"
        public static let ligaments = "line.diagonal"
        public static let tendons = "line.diagonal"
        public static let bursae = "circle.fill"
        public static let menisci = "circle.fill"
        public static let labrum = "circle.fill"
        public static let jointSpace = "circle.fill"
    }
    
    /// Specific joint illustrations
    public struct SpecificJoints {
        public static let kneeJoint = "circle.fill"
        public static let hipJoint = "circle.fill"
        public static let shoulderJoint = "circle.fill"
        public static let elbowJoint = "circle.fill"
        public static let wristJoint = "circle.fill"
        public static let ankleJoint = "circle.fill"
        public static let vertebralJoint = "circle.fill"
        public static let temporomandibular = "circle.fill"
        public static let sacroiliac = "circle.fill"
        public static let acromioclavicular = "circle.fill"
    }
    
    // MARK: - Muscle System
    
    /// Muscle types illustrations
    public struct MuscleTypes {
        public static let skeletalMuscle = "dumbbell.fill"
        public static let smoothMuscle = "dumbbell.fill"
        public static let cardiacMuscle = "heart.fill"
        public static let voluntaryMuscle = "dumbbell.fill"
        public static let involuntaryMuscle = "dumbbell.fill"
        public static let striatedMuscle = "dumbbell.fill"
        public static let nonStriatedMuscle = "dumbbell.fill"
        public static let fastTwitch = "dumbbell.fill"
        public static let slowTwitch = "dumbbell.fill"
        public static let mixedMuscle = "dumbbell.fill"
    }
    
    /// Muscle structure illustrations
    public struct MuscleStructure {
        public static let muscleFiber = "line.diagonal"
        public static let myofibril = "line.diagonal"
        public static let sarcomere = "line.diagonal"
        public static let actinFilaments = "line.diagonal"
        public static let myosinFilaments = "line.diagonal"
        public static let troponin = "circle.fill"
        public static let tropomyosin = "line.diagonal"
        public static let sarcoplasmicReticulum = "line.diagonal"
        public static let transverseTubules = "line.diagonal"
        public static let mitochondria = "circle.fill"
    }
    
    /// Muscle organization illustrations
    public struct MuscleOrganization {
        public static let muscleFascicle = "dumbbell.fill"
        public static let muscleBundle = "dumbbell.fill"
        public static let muscleBelly = "dumbbell.fill"
        public static let muscleOrigin = "dumbbell.fill"
        public static let muscleInsertion = "dumbbell.fill"
        public static let muscleTendon = "line.diagonal"
        public static let muscleAponeurosis = "line.diagonal"
        public static let muscleFascia = "line.diagonal"
        public static let muscleCompartment = "dumbbell.fill"
        public static let muscleGroup = "dumbbell.fill"
    }
    
    // MARK: - Muscle Function
    
    /// Muscle contraction illustrations
    public struct MuscleContraction {
        public static let isometricContraction = "dumbbell.fill"
        public static let isotonicContraction = "dumbbell.fill"
        public static let concentricContraction = "dumbbell.fill"
        public static let eccentricContraction = "dumbbell.fill"
        public static let slidingFilament = "line.diagonal"
        public static let crossBridge = "line.diagonal"
        public static let powerStroke = "line.diagonal"
        public static let calciumRelease = "drop.fill"
        public static let atpHydrolysis = "drop.fill"
        public static let muscleRelaxation = "dumbbell.fill"
    }
    
    /// Muscle mechanics illustrations
    public struct MuscleMechanics {
        public static let muscleLength = "line.diagonal"
        public static let muscleTension = "line.diagonal"
        public static let forceVelocity = "arrow.up.arrow.down"
        public static let lengthTension = "arrow.up.arrow.down"
        public static let musclePower = "bolt.fill"
        public static let muscleEndurance = "timer"
        public static let muscleFatigue = "dumbbell.fill"
        public static let muscleRecovery = "dumbbell.fill"
        public static let muscleHypertrophy = "dumbbell.fill"
        public static let muscleAtrophy = "dumbbell.fill"
    }
    
    // MARK: - Specific Muscle Groups
    
    /// Upper limb muscles illustrations
    public struct UpperLimbMuscles {
        public static let deltoid = "dumbbell.fill"
        public static let bicepsBrachii = "dumbbell.fill"
        public static let tricepsBrachii = "dumbbell.fill"
        public static let pectoralisMajor = "dumbbell.fill"
        public static let latissimusDorsi = "dumbbell.fill"
        public static let rotatorCuff = "dumbbell.fill"
        public static let forearmFlexors = "dumbbell.fill"
        public static let forearmExtensors = "dumbbell.fill"
        public static let handMuscles = "dumbbell.fill"
        public static let shoulderStabilizers = "dumbbell.fill"
    }
    
    /// Lower limb muscles illustrations
    public struct LowerLimbMuscles {
        public static let quadriceps = "dumbbell.fill"
        public static let hamstrings = "dumbbell.fill"
        public static let gluteusMaximus = "dumbbell.fill"
        public static let gluteusMedius = "dumbbell.fill"
        public static let gastrocnemius = "dumbbell.fill"
        public static let soleus = "dumbbell.fill"
        public static let tibialisAnterior = "dumbbell.fill"
        public static let peroneals = "dumbbell.fill"
        public static let hipFlexors = "dumbbell.fill"
        public static let hipAdductors = "dumbbell.fill"
    }
    
    /// Trunk muscles illustrations
    public struct TrunkMuscles {
        public static let rectusAbdominis = "dumbbell.fill"
        public static let externalObliques = "dumbbell.fill"
        public static let internalObliques = "dumbbell.fill"
        public static let transversusAbdominis = "dumbbell.fill"
        public static let erectorSpinae = "dumbbell.fill"
        public static let multifidus = "dumbbell.fill"
        public static let diaphragm = "line.diagonal"
        public static let intercostals = "line.diagonal"
        public static let pelvicFloor = "dumbbell.fill"
        public static let deepStabilizers = "dumbbell.fill"
    }
    
    // MARK: - Movement and Biomechanics
    
    /// Joint movement illustrations
    public struct JointMovement {
        public static let flexion = "arrow.up.arrow.down"
        public static let `extension` = "arrow.up.arrow.down"
        public static let abduction = "arrow.up.arrow.down"
        public static let adduction = "arrow.up.arrow.down"
        public static let rotation = "arrow.clockwise"
        public static let circumduction = "arrow.clockwise"
        public static let supination = "arrow.clockwise"
        public static let pronation = "arrow.clockwise"
        public static let dorsiflexion = "arrow.up.arrow.down"
        public static let plantarflexion = "arrow.up.arrow.down"
    }
    
    /// Biomechanics illustrations
    public struct Biomechanics {
        public static let forceApplication = "arrow.up.arrow.down"
        public static let leverSystems = "line.diagonal"
        public static let momentArm = "line.diagonal"
        public static let torque = "arrow.clockwise"
        public static let centerOfGravity = "circle.fill"
        public static let baseOfSupport = "line.diagonal"
        public static let stability = "shield.fill"
        public static let mobility = "arrow.up.arrow.down"
        public static let coordination = "figure.walk"
        public static let balance = "figure.walk"
    }
    
    // MARK: - Musculoskeletal Pathology
    
    /// Joint pathology illustrations
    public struct JointPathology {
        public static let osteoarthritis = "circle.fill"
        public static let rheumatoidArthritis = "circle.fill"
        public static let gout = "circle.fill"
        public static let bursitis = "circle.fill"
        public static let tendinitis = "line.diagonal"
        public static let ligamentSprain = "line.diagonal"
        public static let jointDislocation = "circle.fill"
        public static let meniscalTear = "circle.fill"
        public static let labralTear = "circle.fill"
        public static let jointInstability = "circle.fill"
    }
    
    /// Muscle pathology illustrations
    public struct MusclePathology {
        public static let muscleStrain = "dumbbell.fill"
        public static let muscleTear = "dumbbell.fill"
        public static let muscleSpasm = "dumbbell.fill"
        public static let myositis = "dumbbell.fill"
        public static let muscularDystrophy = "dumbbell.fill"
        public static let myastheniaGravis = "dumbbell.fill"
        public static let muscleWeakness = "dumbbell.fill"
        public static let muscleAtrophy = "dumbbell.fill"
        public static let musclePain = "dumbbell.fill"
        public static let muscleStiffness = "dumbbell.fill"
    }
    
    // MARK: - Rehabilitation and Exercise
    
    /// Exercise illustrations
    public struct Exercise {
        public static let strengthTraining = "dumbbell.fill"
        public static let flexibilityTraining = "figure.flexibility"
        public static let enduranceTraining = "timer"
        public static let balanceTraining = "figure.walk"
        public static let coordinationTraining = "figure.walk"
        public static let functionalTraining = "figure.walk"
        public static let aquaticExercise = "figure.pool.swim"
        public static let resistanceExercise = "dumbbell.fill"
        public static let aerobicExercise = "heart.circle.fill"
        public static let anaerobicExercise = "bolt.fill"
    }
    
    /// Rehabilitation illustrations
    public struct Rehabilitation {
        public static let physicalTherapy = "figure.walk"
        public static let occupationalTherapy = "hand.raised.fill"
        public static let manualTherapy = "hand.raised.fill"
        public static let therapeuticExercise = "figure.walk"
        public static let modalities = "bolt.fill"
        public static let assistiveDevices = "figure.walk"
        public static let orthotics = "figure.walk"
        public static let prosthetics = "figure.walk"
        public static let adaptiveEquipment = "hand.raised.fill"
        public static let homeExercise = "house.fill"
    }
}

// MARK: - Musculoskeletal Illustration Extensions
public extension MusculoskeletalIllustrations {
    
    /// Get illustration for musculoskeletal structure
    static func illustrationForStructure(_ structure: MusculoskeletalStructure) -> String {
        switch structure {
        case .skeleton:
            return AxialSkeleton.skull
        case .bones:
            return BoneAnatomy.compactBone
        case .joints:
            return JointTypes.synovialJoint
        case .muscles:
            return MuscleTypes.skeletalMuscle
        case .movement:
            return JointMovement.flexion
        case .pathology:
            return JointPathology.osteoarthritis
        }
    }
    
    /// Get illustration for musculoskeletal function
    static func illustrationForFunction(_ function: MusculoskeletalFunction) -> String {
        switch function {
        case .support:
            return AxialSkeleton.vertebralColumn
        case .movement:
            return JointMovement.flexion
        case .protection:
            return AxialSkeleton.ribs
        case .contraction:
            return MuscleContraction.isometricContraction
        case .biomechanics:
            return Biomechanics.forceApplication
        case .rehabilitation:
            return Rehabilitation.physicalTherapy
        }
    }
}

// MARK: - Supporting Enums
public enum MusculoskeletalStructure {
    case skeleton
    case bones
    case joints
    case muscles
    case movement
    case pathology
}

public enum MusculoskeletalFunction {
    case support
    case movement
    case protection
    case contraction
    case biomechanics
    case rehabilitation
} 
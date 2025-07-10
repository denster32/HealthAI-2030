import SwiftUI

// MARK: - Anatomical Illustrations
/// Comprehensive anatomical illustrations for HealthAI 2030
/// Provides detailed anatomical diagrams for health education and medical reference
public struct AnatomicalIllustrations {
    
    // MARK: - Cardiovascular System
    
    /// Heart anatomy illustrations
    public struct HeartAnatomy {
        public static let heart = "heart.fill"
        public static let heartChambers = "heart.circle.fill"
        public static let heartValves = "heart.circle"
        public static let coronaryArteries = "heart.circle.fill"
        public static let heartMuscle = "heart.fill"
        public static let heartConduction = "bolt.fill"
        public static let heartBloodFlow = "arrow.up.arrow.down"
        public static let heartCrossSection = "heart.circle"
        public static let heartFrontal = "heart.fill"
        public static let heartLateral = "heart.circle.fill"
    }
    
    /// Blood vessel illustrations
    public struct BloodVessels {
        public static let arteries = "line.diagonal"
        public static let veins = "line.diagonal"
        public static let capillaries = "line.diagonal"
        public static let aorta = "line.diagonal"
        public static let venaCava = "line.diagonal"
        public static let pulmonary = "line.diagonal"
        public static let coronary = "line.diagonal"
        public static let carotid = "line.diagonal"
        public static let femoral = "line.diagonal"
        public static let brachial = "line.diagonal"
    }
    
    /// Circulatory system illustrations
    public struct CirculatorySystem {
        public static let systemic = "arrow.up.arrow.down"
        public static let pulmonary = "lungs.fill"
        public static let portal = "arrow.up.arrow.down"
        public static let lymphatic = "line.diagonal"
        public static let bloodFlow = "arrow.up.arrow.down"
        public static let oxygenated = "drop.fill"
        public static let deoxygenated = "drop"
        public static let circulation = "arrow.clockwise"
        public static let bloodPressure = "drop.fill"
        public static let bloodVolume = "drop.fill"
    }
    
    // MARK: - Respiratory System
    
    /// Lung anatomy illustrations
    public struct LungAnatomy {
        public static let lungs = "lungs.fill"
        public static let leftLung = "lungs.fill"
        public static let rightLung = "lungs.fill"
        public static let bronchialTree = "lungs.fill"
        public static let alveoli = "circle.fill"
        public static let pleura = "lungs.fill"
        public static let diaphragm = "line.diagonal"
        public static let trachea = "line.diagonal"
        public static let bronchi = "line.diagonal"
        public static let bronchioles = "line.diagonal"
    }
    
    /// Respiratory function illustrations
    public struct RespiratoryFunction {
        public static let inspiration = "lungs.fill"
        public static let expiration = "lungs.fill"
        public static let gasExchange = "arrow.up.arrow.down"
        public static let oxygenDiffusion = "arrow.up.arrow.down"
        public static let carbonDioxide = "arrow.up.arrow.down"
        public static let breathing = "lungs.fill"
        public static let respiratoryRate = "lungs.fill"
        public static let tidalVolume = "lungs.fill"
        public static let vitalCapacity = "lungs.fill"
        public static let residualVolume = "lungs.fill"
    }
    
    // MARK: - Nervous System
    
    /// Brain anatomy illustrations
    public struct BrainAnatomy {
        public static let brain = "brain.head.profile"
        public static let cerebrum = "brain.head.profile"
        public static let cerebellum = "brain.head.profile"
        public static let brainstem = "brain.head.profile"
        public static let frontalLobe = "brain.head.profile"
        public static let temporalLobe = "brain.head.profile"
        public static let parietalLobe = "brain.head.profile"
        public static let occipitalLobe = "brain.head.profile"
        public static let hippocampus = "brain.head.profile"
        public static let amygdala = "brain.head.profile"
    }
    
    /// Nervous system illustrations
    public struct NervousSystem {
        public static let centralNervous = "brain.head.profile"
        public static let peripheralNervous = "line.diagonal"
        public static let spinalCord = "line.diagonal"
        public static let neurons = "line.diagonal"
        public static let synapses = "line.diagonal"
        public static let nerveImpulses = "bolt.fill"
        public static let sensoryNerves = "line.diagonal"
        public static let motorNerves = "line.diagonal"
        public static let autonomicNervous = "line.diagonal"
        public static let cranialNerves = "line.diagonal"
    }
    
    // MARK: - Musculoskeletal System
    
    /// Skeletal system illustrations
    public struct SkeletalSystem {
        public static let skeleton = "figure.walk"
        public static let skull = "circle.fill"
        public static let spine = "line.diagonal"
        public static let ribs = "line.diagonal"
        public static let pelvis = "circle.fill"
        public static let femur = "line.diagonal"
        public static let tibia = "line.diagonal"
        public static let humerus = "line.diagonal"
        public static let radius = "line.diagonal"
        public static let ulna = "line.diagonal"
    }
    
    /// Muscular system illustrations
    public struct MuscularSystem {
        public static let muscles = "dumbbell.fill"
        public static let skeletalMuscles = "dumbbell.fill"
        public static let smoothMuscles = "dumbbell.fill"
        public static let cardiacMuscle = "heart.fill"
        public static let biceps = "dumbbell.fill"
        public static let triceps = "dumbbell.fill"
        public static let quadriceps = "dumbbell.fill"
        public static let hamstrings = "dumbbell.fill"
        public static let abdominals = "dumbbell.fill"
        public static let backMuscles = "dumbbell.fill"
    }
    
    /// Joint anatomy illustrations
    public struct JointAnatomy {
        public static let synovialJoint = "circle.fill"
        public static let kneeJoint = "circle.fill"
        public static let hipJoint = "circle.fill"
        public static let shoulderJoint = "circle.fill"
        public static let elbowJoint = "circle.fill"
        public static let wristJoint = "circle.fill"
        public static let ankleJoint = "circle.fill"
        public static let vertebralJoint = "circle.fill"
        public static let cartilage = "circle.fill"
        public static let ligaments = "line.diagonal"
    }
    
    // MARK: - Digestive System
    
    /// Digestive tract illustrations
    public struct DigestiveTract {
        public static let mouth = "mouth.fill"
        public static let esophagus = "line.diagonal"
        public static let stomach = "circle.fill"
        public static let smallIntestine = "line.diagonal"
        public static let largeIntestine = "line.diagonal"
        public static let colon = "line.diagonal"
        public static let rectum = "line.diagonal"
        public static let anus = "circle.fill"
        public static let appendix = "line.diagonal"
        public static let peristalsis = "arrow.up.arrow.down"
    }
    
    /// Digestive organs illustrations
    public struct DigestiveOrgans {
        public static let liver = "circle.fill"
        public static let gallbladder = "circle.fill"
        public static let pancreas = "circle.fill"
        public static let spleen = "circle.fill"
        public static let salivaryGlands = "circle.fill"
        public static let gastricGlands = "circle.fill"
        public static let intestinalGlands = "circle.fill"
        public static let bileDucts = "line.diagonal"
        public static let pancreaticDucts = "line.diagonal"
        public static let digestiveEnzymes = "drop.fill"
    }
    
    // MARK: - Endocrine System
    
    /// Endocrine glands illustrations
    public struct EndocrineGlands {
        public static let pituitary = "circle.fill"
        public static let thyroid = "circle.fill"
        public static let parathyroid = "circle.fill"
        public static let adrenal = "circle.fill"
        public static let pancreas = "circle.fill"
        public static let ovaries = "circle.fill"
        public static let testes = "circle.fill"
        public static let pineal = "circle.fill"
        public static let thymus = "circle.fill"
        public static let hypothalamus = "brain.head.profile"
    }
    
    /// Hormone function illustrations
    public struct HormoneFunction {
        public static let insulin = "drop.fill"
        public static let glucagon = "drop.fill"
        public static let thyroidHormone = "drop.fill"
        public static let cortisol = "drop.fill"
        public static let adrenaline = "drop.fill"
        public static let growthHormone = "drop.fill"
        public static let estrogen = "drop.fill"
        public static let testosterone = "drop.fill"
        public static let oxytocin = "drop.fill"
        public static let vasopressin = "drop.fill"
    }
    
    // MARK: - Urinary System
    
    /// Urinary tract illustrations
    public struct UrinaryTract {
        public static let kidneys = "circle.fill"
        public static let ureters = "line.diagonal"
        public static let bladder = "circle.fill"
        public static let urethra = "line.diagonal"
        public static let nephron = "circle.fill"
        public static let glomerulus = "circle.fill"
        public static let renalTubules = "line.diagonal"
        public static let collectingDucts = "line.diagonal"
        public static let renalArtery = "line.diagonal"
        public static let renalVein = "line.diagonal"
    }
    
    /// Kidney function illustrations
    public struct KidneyFunction {
        public static let filtration = "arrow.up.arrow.down"
        public static let reabsorption = "arrow.up.arrow.down"
        public static let secretion = "arrow.up.arrow.down"
        public static let urineFormation = "drop.fill"
        public static let bloodFiltration = "drop.fill"
        public static let waterBalance = "drop.fill"
        public static let electrolyteBalance = "drop.fill"
        public static let acidBaseBalance = "drop.fill"
        public static let wasteRemoval = "drop.fill"
        public static let hormoneProduction = "drop.fill"
    }
    
    // MARK: - Reproductive System
    
    /// Female reproductive system
    public struct FemaleReproductive {
        public static let ovaries = "circle.fill"
        public static let fallopianTubes = "line.diagonal"
        public static let uterus = "circle.fill"
        public static let cervix = "circle.fill"
        public static let vagina = "line.diagonal"
        public static let vulva = "circle.fill"
        public static let mammaryGlands = "circle.fill"
        public static let endometrium = "circle.fill"
        public static let myometrium = "circle.fill"
        public static let ovulation = "circle.fill"
    }
    
    /// Male reproductive system
    public struct MaleReproductive {
        public static let testes = "circle.fill"
        public static let epididymis = "line.diagonal"
        public static let vasDeferens = "line.diagonal"
        public static let seminalVesicles = "circle.fill"
        public static let prostate = "circle.fill"
        public static let urethra = "line.diagonal"
        public static let penis = "line.diagonal"
        public static let scrotum = "circle.fill"
        public static let spermProduction = "drop.fill"
        public static let semen = "drop.fill"
    }
    
    // MARK: - Integumentary System
    
    /// Skin anatomy illustrations
    public struct SkinAnatomy {
        public static let epidermis = "rectangle.fill"
        public static let dermis = "rectangle.fill"
        public static let hypodermis = "rectangle.fill"
        public static let hairFollicles = "line.diagonal"
        public static let sweatGlands = "drop.fill"
        public static let sebaceousGlands = "drop.fill"
        public static let bloodVessels = "line.diagonal"
        public static let nerveEndings = "line.diagonal"
        public static let melanocytes = "circle.fill"
        public static let keratinocytes = "circle.fill"
    }
    
    /// Skin function illustrations
    public struct SkinFunction {
        public static let protection = "shield.fill"
        public static let temperature = "thermometer"
        public static let sensation = "hand.raised.fill"
        public static let vitaminD = "sun.max.fill"
        public static let excretion = "drop.fill"
        public static let absorption = "arrow.up.arrow.down"
        public static let woundHealing = "heart.fill"
        public static let immuneFunction = "shield.fill"
        public static let waterBalance = "drop.fill"
        public static let pigmentation = "circle.fill"
    }
    
    // MARK: - Lymphatic System
    
    /// Lymphatic system illustrations
    public struct LymphaticSystem {
        public static let lymphNodes = "circle.fill"
        public static let lymphVessels = "line.diagonal"
        public static let thymus = "circle.fill"
        public static let spleen = "circle.fill"
        public static let tonsils = "circle.fill"
        public static let adenoids = "circle.fill"
        public static let boneMarrow = "circle.fill"
        public static let lymphFlow = "arrow.up.arrow.down"
        public static let immuneCells = "circle.fill"
        public static let lymphaticDrainage = "arrow.up.arrow.down"
    }
    
    /// Immune system illustrations
    public struct ImmuneSystem {
        public static let whiteBloodCells = "circle.fill"
        public static let antibodies = "drop.fill"
        public static let antigens = "circle.fill"
        public static let macrophages = "circle.fill"
        public static let lymphocytes = "circle.fill"
        public static let neutrophils = "circle.fill"
        public static let eosinophils = "circle.fill"
        public static let basophils = "circle.fill"
        public static let naturalKiller = "circle.fill"
        public static let complement = "drop.fill"
    }
}

// MARK: - Anatomical Illustration Extensions
public extension AnatomicalIllustrations {
    
    /// Get illustration for body system
    static func illustrationForSystem(_ system: BodySystem) -> String {
        switch system {
        case .cardiovascular:
            return HeartAnatomy.heart
        case .respiratory:
            return LungAnatomy.lungs
        case .nervous:
            return BrainAnatomy.brain
        case .musculoskeletal:
            return SkeletalSystem.skeleton
        case .digestive:
            return DigestiveTract.mouth
        case .endocrine:
            return EndocrineGlands.pituitary
        case .urinary:
            return UrinaryTract.kidneys
        case .reproductive:
            return FemaleReproductive.ovaries
        case .integumentary:
            return SkinAnatomy.epidermis
        case .lymphatic:
            return LymphaticSystem.lymphNodes
        }
    }
    
    /// Get illustration for anatomical view
    static func illustrationForView(_ view: AnatomicalView) -> String {
        switch view {
        case .anterior:
            return "figure.walk"
        case .posterior:
            return "figure.walk"
        case .lateral:
            return "figure.walk"
        case .medial:
            return "figure.walk"
        case .superior:
            return "figure.walk"
        case .inferior:
            return "figure.walk"
        case .crossSection:
            return "circle.fill"
        case .sagittal:
            return "figure.walk"
        case .coronal:
            return "figure.walk"
        case .transverse:
            return "circle.fill"
        }
    }
}

// MARK: - Supporting Enums
public enum BodySystem {
    case cardiovascular
    case respiratory
    case nervous
    case musculoskeletal
    case digestive
    case endocrine
    case urinary
    case reproductive
    case integumentary
    case lymphatic
}

public enum AnatomicalView {
    case anterior
    case posterior
    case lateral
    case medial
    case superior
    case inferior
    case crossSection
    case sagittal
    case coronal
    case transverse
} 
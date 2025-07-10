import SwiftUI

// MARK: - Health Condition Illustrations
/// Comprehensive health condition illustrations for HealthAI 2030
/// Provides visual representations of various health conditions, symptoms, and disease states
public struct HealthConditionIllustrations {
    
    // MARK: - Cardiovascular Conditions
    
    /// Heart condition illustrations
    public struct HeartConditions {
        public static let heartAttack = "heart.circle.fill"
        public static let heartFailure = "heart.circle"
        public static let arrhythmia = "waveform.path.ecg"
        public static let coronaryDisease = "heart.circle.fill"
        public static let valveDisease = "heart.circle"
        public static let cardiomyopathy = "heart.circle.fill"
        public static let pericarditis = "heart.circle"
        public static let endocarditis = "heart.circle.fill"
        public static let hypertension = "drop.fill"
        public static let hypotension = "drop"
    }
    
    /// Vascular condition illustrations
    public struct VascularConditions {
        public static let atherosclerosis = "line.diagonal"
        public static let aneurysm = "circle.fill"
        public static let thrombosis = "line.diagonal"
        public static let embolism = "line.diagonal"
        public static let varicoseVeins = "line.diagonal"
        public static let deepVeinThrombosis = "line.diagonal"
        public static let peripheralArtery = "line.diagonal"
        public static let raynauds = "hand.raised.fill"
        public static let vasculitis = "line.diagonal"
        public static let lymphedema = "line.diagonal"
    }
    
    // MARK: - Respiratory Conditions
    
    /// Lung condition illustrations
    public struct LungConditions {
        public static let asthma = "lungs.fill"
        public static let copd = "lungs.fill"
        public static let pneumonia = "lungs.fill"
        public static let tuberculosis = "lungs.fill"
        public static let lungCancer = "lungs.fill"
        public static let pulmonaryEmbolism = "lungs.fill"
        public static let pleuralEffusion = "lungs.fill"
        public static let pneumothorax = "lungs.fill"
        public static let fibrosis = "lungs.fill"
        public static let bronchitis = "lungs.fill"
    }
    
    /// Breathing condition illustrations
    public struct BreathingConditions {
        public static let dyspnea = "lungs.fill"
        public static let apnea = "lungs.fill"
        public static let hyperventilation = "lungs.fill"
        public static let hypoventilation = "lungs.fill"
        public static let wheezing = "lungs.fill"
        public static let coughing = "lungs.fill"
        public static let chestPain = "lungs.fill"
        public static let shortnessOfBreath = "lungs.fill"
        public static let rapidBreathing = "lungs.fill"
        public static let shallowBreathing = "lungs.fill"
    }
    
    // MARK: - Neurological Conditions
    
    /// Brain condition illustrations
    public struct BrainConditions {
        public static let stroke = "brain.head.profile"
        public static let dementia = "brain.head.profile"
        public static let alzheimers = "brain.head.profile"
        public static let parkinsons = "brain.head.profile"
        public static let epilepsy = "brain.head.profile"
        public static let multipleSclerosis = "brain.head.profile"
        public static let brainTumor = "brain.head.profile"
        public static let meningitis = "brain.head.profile"
        public static let encephalitis = "brain.head.profile"
        public static let concussion = "brain.head.profile"
    }
    
    /// Nerve condition illustrations
    public struct NerveConditions {
        public static let neuropathy = "line.diagonal"
        public static let carpalTunnel = "hand.raised.fill"
        public static let sciatica = "line.diagonal"
        public static let trigeminalNeuralgia = "brain.head.profile"
        public static let bellPalsy = "face.dashed"
        public static let guillainBarre = "line.diagonal"
        public static let peripheralNerve = "line.diagonal"
        public static let autonomicDysfunction = "line.diagonal"
        public static let nerveCompression = "line.diagonal"
        public static let nerveInjury = "line.diagonal"
    }
    
    // MARK: - Musculoskeletal Conditions
    
    /// Bone condition illustrations
    public struct BoneConditions {
        public static let osteoporosis = "ruler.fill"
        public static let fracture = "ruler.fill"
        public static let arthritis = "hand.raised.fill"
        public static let osteoarthritis = "hand.raised.fill"
        public static let rheumatoidArthritis = "hand.raised.fill"
        public static let gout = "hand.raised.fill"
        public static let scoliosis = "line.diagonal"
        public static let kyphosis = "line.diagonal"
        public static let lordosis = "line.diagonal"
        public static let boneCancer = "ruler.fill"
    }
    
    /// Muscle condition illustrations
    public struct MuscleConditions {
        public static let muscleStrain = "dumbbell.fill"
        public static let muscleSpasm = "dumbbell.fill"
        public static let myositis = "dumbbell.fill"
        public static let muscularDystrophy = "dumbbell.fill"
        public static let fibromyalgia = "dumbbell.fill"
        public static let myastheniaGravis = "dumbbell.fill"
        public static let muscleWeakness = "dumbbell.fill"
        public static let muscleAtrophy = "dumbbell.fill"
        public static let musclePain = "dumbbell.fill"
        public static let muscleStiffness = "dumbbell.fill"
    }
    
    // MARK: - Digestive Conditions
    
    /// GI condition illustrations
    public struct GastrointestinalConditions {
        public static let gastritis = "circle.fill"
        public static let ulcer = "circle.fill"
        public static let gerd = "circle.fill"
        public static let ibs = "line.diagonal"
        public static let crohns = "line.diagonal"
        public static let colitis = "line.diagonal"
        public static let diverticulitis = "line.diagonal"
        public static let appendicitis = "line.diagonal"
        public static let gallstones = "circle.fill"
        public static let pancreatitis = "circle.fill"
    }
    
    /// Liver condition illustrations
    public struct LiverConditions {
        public static let hepatitis = "circle.fill"
        public static let cirrhosis = "circle.fill"
        public static let fattyLiver = "circle.fill"
        public static let liverCancer = "circle.fill"
        public static let jaundice = "circle.fill"
        public static let ascites = "drop.fill"
        public static let portalHypertension = "drop.fill"
        public static let liverFailure = "circle.fill"
        public static let liverEnlargement = "circle.fill"
        public static let liverInflammation = "circle.fill"
    }
    
    // MARK: - Endocrine Conditions
    
    /// Diabetes condition illustrations
    public struct DiabetesConditions {
        public static let type1Diabetes = "drop.fill"
        public static let type2Diabetes = "drop.fill"
        public static let gestationalDiabetes = "drop.fill"
        public static let hyperglycemia = "drop.fill"
        public static let hypoglycemia = "drop"
        public static let diabeticKetoacidosis = "drop.fill"
        public static let diabeticNeuropathy = "line.diagonal"
        public static let diabeticRetinopathy = "eye.fill"
        public static let diabeticNephropathy = "circle.fill"
        public static let insulinResistance = "drop.fill"
    }
    
    /// Thyroid condition illustrations
    public struct ThyroidConditions {
        public static let hypothyroidism = "circle.fill"
        public static let hyperthyroidism = "circle.fill"
        public static let thyroiditis = "circle.fill"
        public static let thyroidCancer = "circle.fill"
        public static let goiter = "circle.fill"
        public static let thyroidNodule = "circle.fill"
        public static let gravesDisease = "circle.fill"
        public static let hashimotos = "circle.fill"
        public static let thyroidStorm = "circle.fill"
        public static let thyroidEnlargement = "circle.fill"
    }
    
    // MARK: - Urinary Conditions
    
    /// Kidney condition illustrations
    public struct KidneyConditions {
        public static let kidneyStones = "circle.fill"
        public static let kidneyInfection = "circle.fill"
        public static let kidneyFailure = "circle.fill"
        public static let polycysticKidney = "circle.fill"
        public static let glomerulonephritis = "circle.fill"
        public static let nephroticSyndrome = "circle.fill"
        public static let kidneyCancer = "circle.fill"
        public static let kidneyInflammation = "circle.fill"
        public static let kidneyEnlargement = "circle.fill"
        public static let kidneyCysts = "circle.fill"
    }
    
    /// Bladder condition illustrations
    public struct BladderConditions {
        public static let urinaryTractInfection = "circle.fill"
        public static let bladderInfection = "circle.fill"
        public static let bladderCancer = "circle.fill"
        public static let incontinence = "drop.fill"
        public static let overactiveBladder = "circle.fill"
        public static let bladderStones = "circle.fill"
        public static let bladderInflammation = "circle.fill"
        public static let bladderEnlargement = "circle.fill"
        public static let bladderSpasms = "circle.fill"
        public static let bladderRetention = "circle.fill"
    }
    
    // MARK: - Skin Conditions
    
    /// Skin condition illustrations
    public struct SkinConditions {
        public static let eczema = "rectangle.fill"
        public static let psoriasis = "rectangle.fill"
        public static let acne = "circle.fill"
        public static let rosacea = "circle.fill"
        public static let dermatitis = "rectangle.fill"
        public static let hives = "circle.fill"
        public static let vitiligo = "rectangle.fill"
        public static let melanoma = "circle.fill"
        public static let basalCell = "circle.fill"
        public static let squamousCell = "circle.fill"
    }
    
    /// Skin infection illustrations
    public struct SkinInfections {
        public static let cellulitis = "rectangle.fill"
        public static let impetigo = "circle.fill"
        public static let ringworm = "circle.fill"
        public static let athleteFoot = "figure.walk"
        public static let jockItch = "figure.walk"
        public static let scabies = "circle.fill"
        public static let lice = "circle.fill"
        public static let herpes = "circle.fill"
        public static let shingles = "rectangle.fill"
        public static let warts = "circle.fill"
    }
    
    // MARK: - Mental Health Conditions
    
    /// Mood disorder illustrations
    public struct MoodDisorders {
        public static let depression = "brain.head.profile"
        public static let bipolar = "brain.head.profile"
        public static let anxiety = "brain.head.profile"
        public static let panicDisorder = "brain.head.profile"
        public static let ocd = "brain.head.profile"
        public static let ptsd = "brain.head.profile"
        public static let seasonalAffective = "brain.head.profile"
        public static let dysthymia = "brain.head.profile"
        public static let cyclothymia = "brain.head.profile"
        public static let adjustmentDisorder = "brain.head.profile"
    }
    
    /// Psychotic disorder illustrations
    public struct PsychoticDisorders {
        public static let schizophrenia = "brain.head.profile"
        public static let schizoaffective = "brain.head.profile"
        public static let delusionalDisorder = "brain.head.profile"
        public static let briefPsychotic = "brain.head.profile"
        public static let sharedPsychotic = "brain.head.profile"
        public static let substanceInduced = "brain.head.profile"
        public static let psychoticDepression = "brain.head.profile"
        public static let mania = "brain.head.profile"
        public static let hallucinations = "brain.head.profile"
        public static let paranoia = "brain.head.profile"
    }
    
    // MARK: - Cancer Conditions
    
    /// Cancer type illustrations
    public struct CancerTypes {
        public static let breastCancer = "circle.fill"
        public static let lungCancer = "lungs.fill"
        public static let colonCancer = "line.diagonal"
        public static let prostateCancer = "circle.fill"
        public static let skinCancer = "rectangle.fill"
        public static let leukemia = "drop.fill"
        public static let lymphoma = "circle.fill"
        public static let brainCancer = "brain.head.profile"
        public static let pancreaticCancer = "circle.fill"
        public static let ovarianCancer = "circle.fill"
    }
    
    /// Cancer treatment illustrations
    public struct CancerTreatment {
        public static let chemotherapy = "drop.fill"
        public static let radiation = "rays"
        public static let surgery = "scissors"
        public static let immunotherapy = "drop.fill"
        public static let targetedTherapy = "drop.fill"
        public static let hormoneTherapy = "drop.fill"
        public static let stemCell = "drop.fill"
        public static let boneMarrow = "drop.fill"
        public static let clinicalTrial = "drop.fill"
        public static let palliative = "drop.fill"
    }
    
    // MARK: - Infectious Diseases
    
    /// Bacterial infection illustrations
    public struct BacterialInfections {
        public static let strepThroat = "mouth.fill"
        public static let pneumonia = "lungs.fill"
        public static let uti = "circle.fill"
        public static let cellulitis = "rectangle.fill"
        public static let meningitis = "brain.head.profile"
        public static let tuberculosis = "lungs.fill"
        public static let lymeDisease = "circle.fill"
        public static let salmonella = "drop.fill"
        public static let eColi = "drop.fill"
        public static let staph = "circle.fill"
    }
    
    /// Viral infection illustrations
    public struct ViralInfections {
        public static let commonCold = "nose.fill"
        public static let flu = "lungs.fill"
        public static let covid = "lungs.fill"
        public static let hiv = "drop.fill"
        public static let hepatitis = "circle.fill"
        public static let herpes = "circle.fill"
        public static let chickenpox = "circle.fill"
        public static let measles = "circle.fill"
        public static let mumps = "circle.fill"
        public static let rubella = "circle.fill"
    }
    
    // MARK: - Autoimmune Conditions
    
    /// Autoimmune disorder illustrations
    public struct AutoimmuneDisorders {
        public static let lupus = "circle.fill"
        public static let rheumatoidArthritis = "hand.raised.fill"
        public static let multipleSclerosis = "brain.head.profile"
        public static let type1Diabetes = "drop.fill"
        public static let hashimotos = "circle.fill"
        public static let gravesDisease = "circle.fill"
        public static let psoriasis = "rectangle.fill"
        public static let crohns = "line.diagonal"
        public static let ulcerativeColitis = "line.diagonal"
        public static let sjogrens = "eye.fill"
    }
}

// MARK: - Health Condition Illustration Extensions
public extension HealthConditionIllustrations {
    
    /// Get illustration for condition category
    static func illustrationForCategory(_ category: HealthConditionCategory) -> String {
        switch category {
        case .cardiovascular:
            return HeartConditions.heartAttack
        case .respiratory:
            return LungConditions.asthma
        case .neurological:
            return BrainConditions.stroke
        case .musculoskeletal:
            return BoneConditions.arthritis
        case .digestive:
            return GastrointestinalConditions.gastritis
        case .endocrine:
            return DiabetesConditions.type1Diabetes
        case .urinary:
            return KidneyConditions.kidneyStones
        case .skin:
            return SkinConditions.eczema
        case .mentalHealth:
            return MoodDisorders.depression
        case .cancer:
            return CancerTypes.breastCancer
        case .infectious:
            return BacterialInfections.strepThroat
        case .autoimmune:
            return AutoimmuneDisorders.lupus
        }
    }
    
    /// Get illustration for condition severity
    static func illustrationForSeverity(_ severity: ConditionSeverity) -> String {
        switch severity {
        case .mild:
            return "exclamationmark.triangle"
        case .moderate:
            return "exclamationmark.triangle"
        case .severe:
            return "exclamationmark.triangle.fill"
        case .critical:
            return "exclamationmark.triangle.fill"
        case .chronic:
            return "clock.fill"
        case .acute:
            return "exclamationmark.triangle.fill"
        }
    }
}

// MARK: - Supporting Enums
public enum HealthConditionCategory {
    case cardiovascular
    case respiratory
    case neurological
    case musculoskeletal
    case digestive
    case endocrine
    case urinary
    case skin
    case mentalHealth
    case cancer
    case infectious
    case autoimmune
}

public enum ConditionSeverity {
    case mild
    case moderate
    case severe
    case critical
    case chronic
    case acute
} 
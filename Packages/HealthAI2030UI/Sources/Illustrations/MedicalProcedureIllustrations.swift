import SwiftUI

// MARK: - Medical Procedure Illustrations
/// Comprehensive medical procedure illustrations for HealthAI 2030
/// Provides detailed visual guides for medical procedures, treatments, and interventions
public struct MedicalProcedureIllustrations {
    
    // MARK: - Diagnostic Procedures
    
    /// Physical examination illustrations
    public struct PhysicalExamination {
        public static let auscultation = "stethoscope"
        public static let palpation = "hand.raised.fill"
        public static let percussion = "hand.raised.fill"
        public static let inspection = "eye.fill"
        public static let rangeOfMotion = "figure.walk"
        public static let reflexTesting = "hand.raised.fill"
        public static let strengthTesting = "dumbbell.fill"
        public static let coordination = "figure.walk"
        public static let balance = "figure.walk"
        public static let gait = "figure.walk"
    }
    
    /// Imaging procedure illustrations
    public struct ImagingProcedures {
        public static let xray = "rays"
        public static let ct = "rays"
        public static let mri = "brain.head.profile"
        public static let ultrasound = "waveform"
        public static let mammogram = "rays"
        public static let boneScan = "rays"
        public static let pet = "rays"
        public static let angiography = "rays"
        public static let fluoroscopy = "rays"
        public static let nuclear = "rays"
    }
    
    /// Laboratory procedure illustrations
    public struct LaboratoryProcedures {
        public static let bloodDraw = "syringe"
        public static let urineCollection = "drop.fill"
        public static let stoolCollection = "drop.fill"
        public static let sputumCollection = "drop.fill"
        public static let tissueBiopsy = "scissors"
        public static let boneMarrow = "scissors"
        public static let lumbarPuncture = "syringe"
        public static let amniocentesis = "syringe"
        public static let chorionicVillus = "syringe"
        public static let geneticTesting = "drop.fill"
    }
    
    // MARK: - Treatment Procedures
    
    /// Medication administration illustrations
    public struct MedicationAdministration {
        public static let oralMedication = "pills.fill"
        public static let injection = "syringe"
        public static let ivInfusion = "drop.fill"
        public static let topicalApplication = "tube"
        public static let inhalation = "wind"
        public static let rectal = "capsule.fill"
        public static let vaginal = "capsule.fill"
        public static let nasal = "drop.fill"
        public static let otic = "drop.fill"
        public static let ophthalmic = "drop.fill"
    }
    
    /// Surgical procedure illustrations
    public struct SurgicalProcedures {
        public static let incision = "scissors"
        public static let dissection = "scissors"
        public static let suturing = "line.diagonal"
        public static let cauterization = "flame.fill"
        public static let ligation = "line.diagonal"
        public static let excision = "scissors"
        public static let resection = "scissors"
        public static let anastomosis = "line.diagonal"
        public static let grafting = "rectangle.fill"
        public static let implantation = "circle.fill"
    }
    
    /// Minimally invasive procedure illustrations
    public struct MinimallyInvasive {
        public static let laparoscopy = "camera.fill"
        public static let endoscopy = "camera.fill"
        public static let arthroscopy = "camera.fill"
        public static let bronchoscopy = "camera.fill"
        public static let colonoscopy = "camera.fill"
        public static let cystoscopy = "camera.fill"
        public static let hysteroscopy = "camera.fill"
        public static let thoracoscopy = "camera.fill"
        public static let mediastinoscopy = "camera.fill"
        public static let laryngoscopy = "camera.fill"
    }
    
    // MARK: - Emergency Procedures
    
    /// Emergency intervention illustrations
    public struct EmergencyInterventions {
        public static let cpr = "heart.circle.fill"
        public static let defibrillation = "bolt.fill"
        public static let intubation = "lungs.fill"
        public static let tracheostomy = "line.diagonal"
        public static let chestTube = "line.diagonal"
        public static let centralLine = "line.diagonal"
        public static let arterialLine = "line.diagonal"
        public static let pericardiocentesis = "syringe"
        public static let thoracentesis = "syringe"
        public static let paracentesis = "syringe"
    }
    
    /// Trauma procedure illustrations
    public struct TraumaProcedures {
        public static let hemorrhageControl = "drop.fill"
        public static let fractureReduction = "ruler.fill"
        public static let splinting = "rectangle.fill"
        public static let woundDebridement = "scissors"
        public static let woundClosure = "line.diagonal"
        public static let amputation = "scissors"
        public static let fasciotomy = "scissors"
        public static let escharotomy = "scissors"
        public static let decompression = "line.diagonal"
        public static let stabilization = "rectangle.fill"
    }
    
    // MARK: - Cardiovascular Procedures
    
    /// Cardiac procedure illustrations
    public struct CardiacProcedures {
        public static let ecg = "waveform.path.ecg"
        public static let echocardiogram = "waveform"
        public static let stressTest = "heart.circle.fill"
        public static let cardiacCatheterization = "line.diagonal"
        public static let angioplasty = "line.diagonal"
        public static let stentPlacement = "circle.fill"
        public static let bypassSurgery = "heart.circle.fill"
        public static let pacemaker = "bolt.fill"
        public static let defibrillator = "bolt.fill"
        public static let ablation = "bolt.fill"
    }
    
    /// Vascular procedure illustrations
    public struct VascularProcedures {
        public static let angiography = "line.diagonal"
        public static let angioplasty = "line.diagonal"
        public static let stentPlacement = "circle.fill"
        public static let bypassGraft = "line.diagonal"
        public static let endarterectomy = "scissors"
        public static let thrombectomy = "scissors"
        public static let embolization = "drop.fill"
        public static let sclerotherapy = "drop.fill"
        public static let varicoseVein = "line.diagonal"
        public static let aneurysm = "circle.fill"
    }
    
    // MARK: - Respiratory Procedures
    
    /// Respiratory procedure illustrations
    public struct RespiratoryProcedures {
        public static let spirometry = "lungs.fill"
        public static let bronchoscopy = "camera.fill"
        public static let intubation = "lungs.fill"
        public static let tracheostomy = "line.diagonal"
        public static let chestTube = "line.diagonal"
        public static let thoracentesis = "syringe"
        public static let lungBiopsy = "scissors"
        public static let pleurodesis = "drop.fill"
        public static let bronchialWash = "drop.fill"
        public static let oxygenTherapy = "lungs.fill"
    }
    
    /// Pulmonary function illustrations
    public struct PulmonaryFunction {
        public static let tidalVolume = "lungs.fill"
        public static let vitalCapacity = "lungs.fill"
        public static let forcedExpiratory = "lungs.fill"
        public static let peakFlow = "lungs.fill"
        public static let diffusionCapacity = "arrow.up.arrow.down"
        public static let lungVolume = "lungs.fill"
        public static let airwayResistance = "line.diagonal"
        public static let compliance = "lungs.fill"
        public static let gasExchange = "arrow.up.arrow.down"
        public static let ventilation = "lungs.fill"
    }
    
    // MARK: - Gastrointestinal Procedures
    
    /// GI procedure illustrations
    public struct GastrointestinalProcedures {
        public static let endoscopy = "camera.fill"
        public static let colonoscopy = "camera.fill"
        public static let sigmoidoscopy = "camera.fill"
        public static let capsuleEndoscopy = "capsule.fill"
        public static let ercp = "camera.fill"
        public static let liverBiopsy = "scissors"
        public static let paracentesis = "syringe"
        public static let feedingTube = "line.diagonal"
        public static let gastricBypass = "scissors"
        public static let cholecystectomy = "scissors"
    }
    
    /// Digestive function illustrations
    public struct DigestiveFunction {
        public static let gastricEmptying = "arrow.up.arrow.down"
        public static let intestinalMotility = "arrow.up.arrow.down"
        public static let absorption = "arrow.up.arrow.down"
        public static let secretion = "drop.fill"
        public static let digestion = "drop.fill"
        public static let peristalsis = "arrow.up.arrow.down"
        public static let gastricAcid = "drop.fill"
        public static let bileSecretion = "drop.fill"
        public static let pancreaticEnzymes = "drop.fill"
        public static let defecation = "arrow.up.arrow.down"
    }
    
    // MARK: - Neurological Procedures
    
    /// Neurological procedure illustrations
    public struct NeurologicalProcedures {
        public static let eeg = "waveform.path.ecg"
        public static let emg = "waveform.path.ecg"
        public static let nerveConduction = "bolt.fill"
        public static let lumbarPuncture = "syringe"
        public static let brainBiopsy = "scissors"
        public static let deepBrainStimulation = "bolt.fill"
        public static let vagusNerve = "bolt.fill"
        public static let spinalStimulation = "bolt.fill"
        public static let craniotomy = "scissors"
        public static let laminectomy = "scissors"
    }
    
    /// Neurological assessment illustrations
    public struct NeurologicalAssessment {
        public static let mentalStatus = "brain.head.profile"
        public static let cranialNerves = "brain.head.profile"
        public static let motorFunction = "figure.walk"
        public static let sensoryFunction = "hand.raised.fill"
        public static let coordination = "figure.walk"
        public static let balance = "figure.walk"
        public static let reflexes = "hand.raised.fill"
        public static let gait = "figure.walk"
        public static let speech = "mouth.fill"
        public static let vision = "eye.fill"
    }
    
    // MARK: - Orthopedic Procedures
    
    /// Orthopedic procedure illustrations
    public struct OrthopedicProcedures {
        public static let fractureReduction = "ruler.fill"
        public static let jointReplacement = "circle.fill"
        public static let arthroscopy = "camera.fill"
        public static let tendonRepair = "line.diagonal"
        public static let ligamentReconstruction = "line.diagonal"
        public static let spinalFusion = "line.diagonal"
        public static let discectomy = "scissors"
        public static let laminectomy = "scissors"
        public static let osteotomy = "scissors"
        public static let amputation = "scissors"
    }
    
    /// Rehabilitation procedure illustrations
    public struct RehabilitationProcedures {
        public static let physicalTherapy = "figure.walk"
        public static let occupationalTherapy = "hand.raised.fill"
        public static let speechTherapy = "mouth.fill"
        public static let respiratoryTherapy = "lungs.fill"
        public static let aquaticTherapy = "figure.pool.swim"
        public static let electricalStimulation = "bolt.fill"
        public static let ultrasoundTherapy = "waveform"
        public static let heatTherapy = "thermometer.sun.fill"
        public static let coldTherapy = "thermometer.snowflake"
        public static let traction = "arrow.up.arrow.down"
    }
    
    // MARK: - Obstetric and Gynecological Procedures
    
    /// Obstetric procedure illustrations
    public struct ObstetricProcedures {
        public static let ultrasound = "waveform"
        public static let amniocentesis = "syringe"
        public static let chorionicVillus = "syringe"
        public static let fetalMonitoring = "waveform.path.ecg"
        public static let laborInduction = "figure.and.child.holdinghands"
        public static let cesareanSection = "scissors"
        public static let episiotomy = "scissors"
        public static let forcepsDelivery = "scissors"
        public static let vacuumExtraction = "circle.fill"
        public static let cordBlood = "drop.fill"
    }
    
    /// Gynecological procedure illustrations
    public struct GynecologicalProcedures {
        public static let papSmear = "drop.fill"
        public static let colposcopy = "camera.fill"
        public static let hysteroscopy = "camera.fill"
        public static let laparoscopy = "camera.fill"
        public static let hysterectomy = "scissors"
        public static let tubalLigation = "scissors"
        public static let endometrialBiopsy = "scissors"
        public static let dnc = "scissors"
        public static let iudPlacement = "circle.fill"
        public static let fertilityTreatment = "drop.fill"
    }
    
    // MARK: - Urological Procedures
    
    /// Urological procedure illustrations
    public struct UrologicalProcedures {
        public static let cystoscopy = "camera.fill"
        public static let prostateBiopsy = "scissors"
        public static let vasectomy = "scissors"
        public static let circumcision = "scissors"
        public static let kidneyBiopsy = "scissors"
        public static let lithotripsy = "waveform"
        public static let nephrectomy = "scissors"
        public static let prostatectomy = "scissors"
        public static let bladderSuspension = "line.diagonal"
        public static let urethralStent = "line.diagonal"
    }
    
    /// Renal function illustrations
    public struct RenalFunction {
        public static let glomerularFiltration = "arrow.up.arrow.down"
        public static let tubularReabsorption = "arrow.up.arrow.down"
        public static let tubularSecretion = "arrow.up.arrow.down"
        public static let urineConcentration = "drop.fill"
        public static let acidBaseBalance = "drop.fill"
        public static let electrolyteBalance = "drop.fill"
        public static let waterBalance = "drop.fill"
        public static let bloodPressure = "drop.fill"
        public static let erythropoietin = "drop.fill"
        public static let vitaminD = "drop.fill"
    }
}

// MARK: - Medical Procedure Illustration Extensions
public extension MedicalProcedureIllustrations {
    
    /// Get illustration for procedure type
    static func illustrationForProcedure(_ procedure: MedicalProcedureType) -> String {
        switch procedure {
        case .diagnostic:
            return PhysicalExamination.auscultation
        case .therapeutic:
            return MedicationAdministration.oralMedication
        case .surgical:
            return SurgicalProcedures.incision
        case .emergency:
            return EmergencyInterventions.cpr
        case .minimallyInvasive:
            return MinimallyInvasive.laparoscopy
        case .rehabilitation:
            return RehabilitationProcedures.physicalTherapy
        case .preventive:
            return PhysicalExamination.inspection
        case .palliative:
            return MedicationAdministration.ivInfusion
        }
    }
    
    /// Get illustration for procedure complexity
    static func illustrationForComplexity(_ complexity: ProcedureComplexity) -> String {
        switch complexity {
        case .simple:
            return "checkmark.circle.fill"
        case .moderate:
            return "exclamationmark.triangle"
        case .complex:
            return "exclamationmark.triangle.fill"
        case .critical:
            return "exclamationmark.triangle.fill"
        }
    }
}

// MARK: - Supporting Enums
public enum MedicalProcedureType {
    case diagnostic
    case therapeutic
    case surgical
    case emergency
    case minimallyInvasive
    case rehabilitation
    case preventive
    case palliative
}

public enum ProcedureComplexity {
    case simple
    case moderate
    case complex
    case critical
} 
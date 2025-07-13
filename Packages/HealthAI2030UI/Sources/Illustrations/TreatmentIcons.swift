import SwiftUI

// MARK: - Treatment Illustrations
/// Comprehensive treatment illustrations for HealthAI 2030
/// Provides visual representations of various medical treatments, therapies, and interventions
public struct TreatmentIcons {
    
    // MARK: - Medication Treatments
    
    /// Oral medication illustrations
    public struct OralMedications {
        public static let tablets = "pills.fill"
        public static let capsules = "capsule.fill"
        public static let liquid = "drop.fill"
        public static let syrup = "drop.fill"
        public static let suspension = "drop.fill"
        public static let powder = "circle.fill"
        public static let chewable = "pills.fill"
        public static let sublingual = "pills.fill"
        public static let buccal = "pills.fill"
        public static let oralSolution = "drop.fill"
    }
    
    /// Injectable medication illustrations
    public struct InjectableMedications {
        public static let intramuscular = "syringe"
        public static let subcutaneous = "syringe"
        public static let intravenous = "drop.fill"
        public static let intradermal = "syringe"
        public static let epidural = "syringe"
        public static let intrathecal = "syringe"
        public static let intraarticular = "syringe"
        public static let insulin = "syringe"
        public static let heparin = "syringe"
        public static let chemotherapy = "drop.fill"
    }
    
    /// Topical treatment illustrations
    public struct TopicalTreatments {
        public static let cream = "tube"
        public static let ointment = "tube"
        public static let gel = "tube"
        public static let lotion = "tube"
        public static let patch = "rectangle.fill"
        public static let spray = "wind"
        public static let drops = "drop.fill"
        public static let suppository = "capsule.fill"
        public static let enema = "drop.fill"
        public static let inhaler = "wind"
    }
    
    // MARK: - Surgical Treatments
    
    /// General surgery illustrations
    public struct GeneralSurgery {
        public static let appendectomy = "scissors"
        public static let cholecystectomy = "scissors"
        public static let herniaRepair = "scissors"
        public static let mastectomy = "scissors"
        public static let hysterectomy = "scissors"
        public static let prostatectomy = "scissors"
        public static let colectomy = "scissors"
        public static let gastrectomy = "scissors"
        public static let nephrectomy = "scissors"
        public static let splenectomy = "scissors"
    }
    
    /// Cardiovascular surgery illustrations
    public struct CardiovascularSurgery {
        public static let bypassSurgery = "heart.circle.fill"
        public static let valveReplacement = "heart.circle"
        public static let pacemaker = "bolt.fill"
        public static let defibrillator = "bolt.fill"
        public static let angioplasty = "line.diagonal"
        public static let stentPlacement = "circle.fill"
        public static let aneurysmRepair = "circle.fill"
        public static let heartTransplant = "heart.circle.fill"
        public static let ablation = "bolt.fill"
        public static let thrombectomy = "scissors"
    }
    
    /// Orthopedic surgery illustrations
    public struct OrthopedicSurgery {
        public static let jointReplacement = "circle.fill"
        public static let fractureFixation = "ruler.fill"
        public static let arthroscopy = "camera.fill"
        public static let spinalFusion = "line.diagonal"
        public static let discectomy = "scissors"
        public static let laminectomy = "scissors"
        public static let tendonRepair = "line.diagonal"
        public static let ligamentReconstruction = "line.diagonal"
        public static let amputation = "scissors"
        public static let osteotomy = "scissors"
    }
    
    // MARK: - Radiation Treatments
    
    /// Radiation therapy illustrations
    public struct RadiationTherapy {
        public static let externalBeam = "rays"
        public static let internalRadiation = "rays"
        public static let brachytherapy = "rays"
        public static let stereotactic = "rays"
        public static let protonTherapy = "rays"
        public static let gammaKnife = "rays"
        public static let cyberKnife = "rays"
        public static let intensityModulated = "rays"
        public static let conformal = "rays"
        public static let palliative = "rays"
    }
    
    /// Radiation planning illustrations
    public struct RadiationPlanning {
        public static let simulation = "rays"
        public static let treatmentPlanning = "rays"
        public static let dosimetry = "rays"
        public static let targetVolume = "circle.fill"
        public static let organsAtRisk = "circle.fill"
        public static let treatmentField = "rays"
        public static let fractionation = "rays"
        public static let doseDistribution = "rays"
        public static let qualityAssurance = "rays"
        public static let treatmentVerification = "rays"
    }
    
    // MARK: - Physical Therapy
    
    /// Physical therapy illustrations
    public struct PhysicalTherapy {
        public static let exercise = "figure.walk"
        public static let stretching = "figure.flexibility"
        public static let strengthening = "dumbbell.fill"
        public static let balance = "figure.walk"
        public static let coordination = "figure.walk"
        public static let gait = "figure.walk"
        public static let mobility = "figure.walk"
        public static let rangeOfMotion = "figure.walk"
        public static let functional = "figure.walk"
        public static let aquatic = "figure.pool.swim"
    }
    
    /// Physical therapy modalities illustrations
    public struct PhysicalTherapyModalities {
        public static let heat = "thermometer.sun.fill"
        public static let ice = "thermometer.snowflake"
        public static let ultrasound = "waveform"
        public static let electrical = "bolt.fill"
        public static let traction = "arrow.up.arrow.down"
        public static let massage = "hand.raised.fill"
        public static let manual = "hand.raised.fill"
        public static let compression = "rectangle.fill"
        public static let elevation = "arrow.up.circle.fill"
        public static let vibration = "waveform"
    }
    
    // MARK: - Occupational Therapy
    
    /// Occupational therapy illustrations
    public struct OccupationalTherapy {
        public static let adlTraining = "hand.raised.fill"
        public static let fineMotor = "hand.raised.fill"
        public static let grossMotor = "figure.walk"
        public static let cognitive = "brain.head.profile"
        public static let sensory = "hand.raised.fill"
        public static let adaptive = "hand.raised.fill"
        public static let workHardening = "hand.raised.fill"
        public static let driving = "car.fill"
        public static let homeModification = "house.fill"
        public static let assistive = "hand.raised.fill"
    }
    
    /// Rehabilitation illustrations
    public struct Rehabilitation {
        public static let stroke = "figure.walk"
        public static let spinalCord = "figure.walk"
        public static let brainInjury = "figure.walk"
        public static let cardiac = "heart.circle.fill"
        public static let pulmonary = "lungs.fill"
        public static let orthopedic = "figure.walk"
        public static let amputee = "figure.walk"
        public static let burn = "figure.walk"
        public static let pediatric = "figure.and.child.holdinghands"
        public static let geriatric = "figure.walk"
    }
    
    // MARK: - Mental Health Treatments
    
    /// Psychotherapy illustrations
    public struct Psychotherapy {
        public static let cognitiveBehavioral = "brain.head.profile"
        public static let dialecticalBehavioral = "brain.head.profile"
        public static let psychodynamic = "brain.head.profile"
        public static let interpersonal = "person.2.fill"
        public static let family = "person.3.fill"
        public static let group = "person.3.sequence.fill"
        public static let exposure = "brain.head.profile"
        public static let mindfulness = "brain.head.profile"
        public static let acceptance = "brain.head.profile"
        public static let trauma = "brain.head.profile"
    }
    
    /// Psychiatric treatment illustrations
    public struct PsychiatricTreatment {
        public static let medication = "pills.fill"
        public static let electroconvulsive = "bolt.fill"
        public static let transcranial = "bolt.fill"
        public static let deepBrain = "bolt.fill"
        public static let vagusNerve = "bolt.fill"
        public static let ketamine = "drop.fill"
        public static let psilocybin = "drop.fill"
        public static let artTherapy = "paintbrush.fill"
        public static let musicTherapy = "music.note"
        public static let animalAssisted = "figure.and.child.holdinghands"
    }
    
    // MARK: - Alternative Treatments
    
    /// Complementary medicine illustrations
    public struct ComplementaryMedicine {
        public static let acupuncture = "needle"
        public static let chiropractic = "hand.raised.fill"
        public static let osteopathy = "hand.raised.fill"
        public static let naturopathy = "leaf.fill"
        public static let homeopathy = "drop.fill"
        public static let herbal = "leaf.fill"
        public static let aromatherapy = "wind"
        public static let reflexology = "hand.raised.fill"
        public static let reiki = "hand.raised.fill"
        public static let meditation = "brain.head.profile"
    }
    
    /// Traditional medicine illustrations
    public struct TraditionalMedicine {
        public static let chinese = "leaf.fill"
        public static let ayurvedic = "leaf.fill"
        public static let nativeAmerican = "leaf.fill"
        public static let african = "leaf.fill"
        public static let middleEastern = "leaf.fill"
        public static let southAmerican = "leaf.fill"
        public static let pacificIsland = "leaf.fill"
        public static let european = "leaf.fill"
        public static let indian = "leaf.fill"
        public static let tibetan = "leaf.fill"
    }
    
    // MARK: - Emergency Treatments
    
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
    
    /// Trauma treatment illustrations
    public struct TraumaTreatment {
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
    
    // MARK: - Preventive Treatments
    
    /// Vaccination illustrations
    public struct Vaccination {
        public static let childhood = "syringe"
        public static let adult = "syringe"
        public static let travel = "syringe"
        public static let flu = "syringe"
        public static let covid = "syringe"
        public static let hepatitis = "syringe"
        public static let measles = "syringe"
        public static let mumps = "syringe"
        public static let rubella = "syringe"
        public static let hpv = "syringe"
    }
    
    /// Screening illustrations
    public struct Screening {
        public static let mammogram = "rays"
        public static let colonoscopy = "camera.fill"
        public static let papSmear = "drop.fill"
        public static let prostate = "drop.fill"
        public static let skin = "hand.raised.fill"
        public static let lung = "rays"
        public static let bone = "ruler.fill"
        public static let hearing = "ear.fill"
        public static let vision = "eye.fill"
        public static let dental = "mouth.fill"
    }
    
    // MARK: - Palliative Care
    
    /// Palliative care illustrations
    public struct PalliativeCare {
        public static let painManagement = "pills.fill"
        public static let symptomControl = "pills.fill"
        public static let comfort = "heart.fill"
        public static let emotional = "heart.fill"
        public static let spiritual = "heart.fill"
        public static let social = "person.2.fill"
        public static let family = "person.3.fill"
        public static let hospice = "house.fill"
        public static let endOfLife = "heart.fill"
        public static let bereavement = "heart.fill"
    }
    
    /// Supportive care illustrations
    public struct SupportiveCare {
        public static let nutrition = "fork.knife"
        public static let hydration = "drop.fill"
        public static let wound = "rectangle.fill"
        public static let ostomy = "circle.fill"
        public static let catheter = "line.diagonal"
        public static let feeding = "drop.fill"
        public static let breathing = "lungs.fill"
        public static let mobility = "figure.walk"
        public static let communication = "message.fill"
        public static let dignity = "heart.fill"
    }
}

// MARK: - Treatment Illustration Extensions
public extension TreatmentIllustrations {
    
    /// Get illustration for treatment type
    static func illustrationForTreatment(_ treatment: TreatmentType) -> String {
        switch treatment {
        case .medication:
            return OralMedications.tablets
        case .surgical:
            return GeneralSurgery.appendectomy
        case .radiation:
            return RadiationTherapy.externalBeam
        case .physicalTherapy:
            return PhysicalTherapy.exercise
        case .occupationalTherapy:
            return OccupationalTherapy.adlTraining
        case .psychotherapy:
            return Psychotherapy.cognitiveBehavioral
        case .complementary:
            return ComplementaryMedicine.acupuncture
        case .emergency:
            return EmergencyInterventions.cpr
        case .preventive:
            return Vaccination.childhood
        case .palliative:
            return PalliativeCare.painManagement
        }
    }
    
    /// Get illustration for treatment setting
    static func illustrationForSetting(_ setting: TreatmentSetting) -> String {
        switch setting {
        case .hospital:
            return "building.2.fill"
        case .clinic:
            return "building.2.fill"
        case .home:
            return "house.fill"
        case .outpatient:
            return "building.2.fill"
        case .inpatient:
            return "building.2.fill"
        case .emergency:
            return "exclamationmark.triangle.fill"
        case .rehabilitation:
            return "building.2.fill"
        case .hospice:
            return "house.fill"
        case .telemedicine:
            return "video.fill"
        case .mobile:
            return "car.fill"
        }
    }
}

// MARK: - Supporting Enums
public enum TreatmentType {
    case medication
    case surgical
    case radiation
    case physicalTherapy
    case occupationalTherapy
    case psychotherapy
    case complementary
    case emergency
    case preventive
    case palliative
}

public enum TreatmentSetting {
    case hospital
    case clinic
    case home
    case outpatient
    case inpatient
    case emergency
    case rehabilitation
    case hospice
    case telemedicine
    case mobile
} 
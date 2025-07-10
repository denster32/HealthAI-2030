import SwiftUI

// MARK: - Medical Procedure Icons
/// Comprehensive medical procedure icons for HealthAI 2030
/// Provides examinations, treatments, surgeries, and medical interventions
public struct MedicalProcedureIcons {
    
    // MARK: - Examination Icons
    
    /// Physical examination icons
    public struct Examination {
        public static let stethoscope = "stethoscope"
        public static let bloodPressure = "drop.fill"
        public static let temperature = "thermometer"
        public static let pulse = "heart.circle.fill"
        public static let respiration = "lungs.fill"
        public static let reflex = "hand.raised.fill"
        public static let vision = "eye.fill"
        public static let hearing = "ear.fill"
        public static let dental = "mouth.fill"
        public static let neurological = "brain.head.profile"
    }
    
    /// Diagnostic procedure icons
    public struct Diagnostic {
        public static let xray = "rays"
        public static let mri = "brain.head.profile"
        public static let ct = "rays"
        public static let ultrasound = "waveform"
        public static let endoscopy = "camera.fill"
        public static let colonoscopy = "camera.fill"
        public static let biopsy = "scissors"
        public static let bloodTest = "drop.fill"
        public static let urineTest = "drop.fill"
        public static let stoolTest = "drop.fill"
    }
    
    /// Laboratory test icons
    public struct Laboratory {
        public static let microscope = "magnifyingglass"
        public static let testTube = "testtube.2"
        public static let petriDish = "circle.fill"
        public static let centrifuge = "circle.fill"
        public static let pipette = "drop.fill"
        public static let slide = "rectangle.fill"
        public static let culture = "circle.fill"
        public static let specimen = "drop.fill"
        public static let reagent = "drop.fill"
        public static let analysis = "chart.bar.fill"
    }
    
    // MARK: - Treatment Icons
    
    /// Medication treatment icons
    public struct Medication {
        public static let pills = "pills.fill"
        public static let injection = "syringe"
        public static let iv = "drop.fill"
        public static let inhaler = "wind"
        public static let cream = "tube"
        public static let ointment = "tube"
        public static let drops = "drop.fill"
        public static let patch = "rectangle.fill"
        public static let suppository = "capsule.fill"
        public static let liquid = "drop.fill"
    }
    
    /// Physical therapy icons
    public struct PhysicalTherapy {
        public static let exercise = "figure.walk"
        public static let stretching = "figure.flexibility"
        public static let massage = "hand.raised.fill"
        public static let heat = "thermometer.sun.fill"
        public static let ice = "thermometer.snowflake"
        public static let ultrasound = "waveform"
        public static let electrical = "bolt.fill"
        public static let traction = "arrow.up.arrow.down"
        public static let mobility = "figure.walk"
        public static let rehabilitation = "figure.walk"
    }
    
    /// Surgical procedure icons
    public struct Surgery {
        public static let scalpel = "scissors"
        public static let forceps = "scissors"
        public static let sutures = "line.diagonal"
        public static let bandage = "rectangle.fill"
        public static let gauze = "rectangle.fill"
        public static let surgical = "scissors"
        public static let incision = "line.diagonal"
        public static let anesthesia = "drop.fill"
        public static let operating = "scissors"
        public static let recovery = "bed.double.fill"
    }
    
    // MARK: - Emergency Icons
    
    /// Emergency procedure icons
    public struct Emergency {
        public static let cpr = "heart.circle.fill"
        public static let defibrillator = "bolt.fill"
        public static let airway = "lungs.fill"
        public static let breathing = "lungs.fill"
        public static let circulation = "heart.circle.fill"
        public static let trauma = "exclamationmark.triangle.fill"
        public static let bleeding = "drop.fill"
        public static let shock = "exclamationmark.triangle.fill"
        public static let cardiac = "heart.circle.fill"
        public static let respiratory = "lungs.fill"
    }
    
    /// Critical care icons
    public struct CriticalCare {
        public static let ventilator = "lungs.fill"
        public static let monitor = "waveform.path.ecg"
        public static let ivPump = "drop.fill"
        public static let catheter = "line.diagonal"
        public static let feeding = "drop.fill"
        public static let dialysis = "drop.fill"
        public static let oxygen = "lungs.fill"
        public static let suction = "drop.fill"
        public static let chestTube = "line.diagonal"
        public static let centralLine = "line.diagonal"
    }
    
    // MARK: - Specialized Procedure Icons
    
    /// Cardiovascular procedure icons
    public struct Cardiovascular {
        public static let ecg = "waveform.path.ecg"
        public static let echocardiogram = "waveform"
        public static let stressTest = "heart.circle.fill"
        public static let angioplasty = "line.diagonal"
        public static let stent = "circle.fill"
        public static let bypass = "heart.circle.fill"
        public static let pacemaker = "bolt.fill"
        public static let defibrillator = "bolt.fill"
        public static let ablation = "bolt.fill"
        public static let catheterization = "line.diagonal"
    }
    
    /// Respiratory procedure icons
    public struct Respiratory {
        public static let spirometry = "lungs.fill"
        public static let bronchoscopy = "camera.fill"
        public static let intubation = "lungs.fill"
        public static let tracheostomy = "line.diagonal"
        public static let chestTube = "line.diagonal"
        public static let oxygen = "lungs.fill"
        public static let nebulizer = "wind"
        public static let peakFlow = "lungs.fill"
        public static let pulmonary = "lungs.fill"
        public static let ventilation = "lungs.fill"
    }
    
    /// Gastrointestinal procedure icons
    public struct Gastrointestinal {
        public static let endoscopy = "camera.fill"
        public static let colonoscopy = "camera.fill"
        public static let sigmoidoscopy = "camera.fill"
        public static let biopsy = "scissors"
        public static let polypectomy = "scissors"
        public static let gastroscopy = "camera.fill"
        public static let duodenoscopy = "camera.fill"
        public static let ercp = "camera.fill"
        public static let colonoscopy = "camera.fill"
        public static let capsule = "capsule.fill"
    }
    
    // MARK: - Imaging Icons
    
    /// Radiology procedure icons
    public struct Radiology {
        public static let xray = "rays"
        public static let ct = "rays"
        public static let mri = "brain.head.profile"
        public static let ultrasound = "waveform"
        public static let mammogram = "rays"
        public static let boneScan = "rays"
        public static let pet = "rays"
        public static let nuclear = "rays"
        public static let fluoroscopy = "rays"
        public static let angiography = "rays"
    }
    
    /// Nuclear medicine icons
    public struct NuclearMedicine {
        public static let pet = "rays"
        public static let spect = "rays"
        public static let boneScan = "rays"
        public static let thyroid = "rays"
        public static let cardiac = "heart.circle.fill"
        public static let lung = "lungs.fill"
        public static let brain = "brain.head.profile"
        public static let liver = "circle.fill"
        public static let kidney = "circle.fill"
        public static let tumor = "circle.fill"
    }
    
    // MARK: - Obstetric and Gynecological Icons
    
    /// Obstetric procedure icons
    public struct Obstetric {
        public static let ultrasound = "waveform"
        public static let amniocentesis = "drop.fill"
        public static let cvs = "drop.fill"
        public static let delivery = "figure.and.child.holdinghands"
        public static let cesarean = "scissors"
        public static let epidural = "drop.fill"
        public static let monitoring = "waveform.path.ecg"
        public static let contraction = "waveform"
        public static let fetal = "heart.circle.fill"
        public static let labor = "figure.and.child.holdinghands"
    }
    
    /// Gynecological procedure icons
    public struct Gynecological {
        public static let papSmear = "drop.fill"
        public static let colposcopy = "camera.fill"
        public static let hysteroscopy = "camera.fill"
        public static let laparoscopy = "camera.fill"
        public static let hysterectomy = "scissors"
        public static let tubal = "scissors"
        public static let biopsy = "scissors"
        public static let dnc = "scissors"
        public static let iud = "circle.fill"
        public static let fertility = "heart.circle.fill"
    }
    
    // MARK: - Pediatric Icons
    
    /// Pediatric procedure icons
    public struct Pediatric {
        public static let vaccination = "syringe"
        public static let growth = "ruler.fill"
        public static let development = "figure.and.child.holdinghands"
        public static let immunization = "syringe"
        public static let wellChild = "figure.and.child.holdinghands"
        public static let circumcision = "scissors"
        public static let hearing = "ear.fill"
        public static let vision = "eye.fill"
        public static let dental = "mouth.fill"
        public static let nutrition = "fork.knife"
    }
    
    // MARK: - Geriatric Icons
    
    /// Geriatric procedure icons
    public struct Geriatric {
        public static let fallRisk = "exclamationmark.triangle.fill"
        public static let mobility = "figure.walk"
        public static let cognition = "brain.head.profile"
        public static let nutrition = "fork.knife"
        public static let medication = "pills.fill"
        public static let incontinence = "drop.fill"
        public static let pressure = "circle.fill"
        public static let osteoporosis = "circle.fill"
        public static let arthritis = "hand.raised.fill"
        public static let dementia = "brain.head.profile"
    }
}

// MARK: - Medical Procedure Icon Extensions
public extension MedicalProcedureIcons {
    
    /// Get icon for procedure type
    static func iconForProcedure(_ procedure: MedicalProcedureType) -> String {
        switch procedure {
        case .examination:
            return Examination.stethoscope
        case .diagnostic:
            return Diagnostic.xray
        case .laboratory:
            return Laboratory.microscope
        case .medication:
            return Medication.pills
        case .physicalTherapy:
            return PhysicalTherapy.exercise
        case .surgery:
            return Surgery.scalpel
        case .emergency:
            return Emergency.cpr
        case .criticalCare:
            return CriticalCare.ventilator
        case .cardiovascular:
            return Cardiovascular.ecg
        case .respiratory:
            return Respiratory.spirometry
        case .gastrointestinal:
            return Gastrointestinal.endoscopy
        case .radiology:
            return Radiology.xray
        case .nuclearMedicine:
            return NuclearMedicine.pet
        case .obstetric:
            return Obstetric.ultrasound
        case .gynecological:
            return Gynecological.papSmear
        case .pediatric:
            return Pediatric.vaccination
        case .geriatric:
            return Geriatric.fallRisk
        }
    }
    
    /// Get icon for procedure urgency
    static func iconForUrgency(_ urgency: ProcedureUrgency) -> String {
        switch urgency {
        case .routine:
            return "clock"
        case .urgent:
            return "exclamationmark.triangle"
        case .emergency:
            return "exclamationmark.triangle.fill"
        case .critical:
            return "exclamationmark.triangle.fill"
        }
    }
}

// MARK: - Supporting Enums
public enum MedicalProcedureType {
    case examination
    case diagnostic
    case laboratory
    case medication
    case physicalTherapy
    case surgery
    case emergency
    case criticalCare
    case cardiovascular
    case respiratory
    case gastrointestinal
    case radiology
    case nuclearMedicine
    case obstetric
    case gynecological
    case pediatric
    case geriatric
}

public enum ProcedureUrgency {
    case routine
    case urgent
    case emergency
    case critical
} 
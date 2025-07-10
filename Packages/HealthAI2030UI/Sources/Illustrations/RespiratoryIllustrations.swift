import SwiftUI

// MARK: - Respiratory Illustrations
/// Detailed respiratory anatomical illustrations for HealthAI 2030
/// Provides comprehensive lung anatomy, breathing mechanics, and respiratory system visualizations for health education
public struct RespiratoryIllustrations {
    
    // MARK: - Upper Respiratory Tract
    
    /// Nasal cavity illustrations
    public struct NasalCavity {
        public static let nasalPassages = "nose.fill"
        public static let nasalSeptum = "nose.fill"
        public static let nasalTurbinates = "nose.fill"
        public static let nasalMucosa = "nose.fill"
        public static let olfactoryNerves = "nose.fill"
        public static let nasalBloodVessels = "nose.fill"
        public static let nasalLymphatics = "nose.fill"
        public static let nasalCilia = "nose.fill"
        public static let nasalGlands = "nose.fill"
        public static let nasalSinus = "nose.fill"
    }
    
    /// Pharynx illustrations
    public struct Pharynx {
        public static let nasopharynx = "mouth.fill"
        public static let oropharynx = "mouth.fill"
        public static let laryngopharynx = "mouth.fill"
        public static let pharyngealMuscles = "mouth.fill"
        public static let pharyngealMucosa = "mouth.fill"
        public static let pharyngealTonsils = "mouth.fill"
        public static let pharyngealBloodVessels = "mouth.fill"
        public static let pharyngealNerves = "mouth.fill"
        public static let pharyngealLymphatics = "mouth.fill"
        public static let pharyngealSwallowing = "mouth.fill"
    }
    
    /// Larynx illustrations
    public struct Larynx {
        public static let laryngealCartilage = "mouth.fill"
        public static let vocalCords = "mouth.fill"
        public static let epiglottis = "mouth.fill"
        public static let thyroidCartilage = "mouth.fill"
        public static let cricoidCartilage = "mouth.fill"
        public static let arytenoidCartilage = "mouth.fill"
        public static let laryngealMuscles = "mouth.fill"
        public static let laryngealMucosa = "mouth.fill"
        public static let laryngealNerves = "mouth.fill"
        public static let laryngealBloodVessels = "mouth.fill"
    }
    
    // MARK: - Lower Respiratory Tract
    
    /// Trachea illustrations
    public struct Trachea {
        public static let trachealCartilage = "line.diagonal"
        public static let trachealMucosa = "line.diagonal"
        public static let trachealMuscle = "line.diagonal"
        public static let trachealCilia = "line.diagonal"
        public static let trachealGlands = "line.diagonal"
        public static let trachealBloodVessels = "line.diagonal"
        public static let trachealNerves = "line.diagonal"
        public static let trachealLymphatics = "line.diagonal"
        public static let trachealBifurcation = "line.diagonal"
        public static let trachealStenosis = "line.diagonal"
    }
    
    /// Bronchi illustrations
    public struct Bronchi {
        public static let mainBronchi = "line.diagonal"
        public static let lobarBronchi = "line.diagonal"
        public static let segmentalBronchi = "line.diagonal"
        public static let subsegmentalBronchi = "line.diagonal"
        public static let bronchialCartilage = "line.diagonal"
        public static let bronchialMuscle = "line.diagonal"
        public static let bronchialMucosa = "line.diagonal"
        public static let bronchialCilia = "line.diagonal"
        public static let bronchialGlands = "line.diagonal"
        public static let bronchialBloodVessels = "line.diagonal"
    }
    
    /// Bronchioles illustrations
    public struct Bronchioles {
        public static let terminalBronchioles = "line.diagonal"
        public static let respiratoryBronchioles = "line.diagonal"
        public static let alveolarDucts = "line.diagonal"
        public static let alveolarSaccules = "line.diagonal"
        public static let bronchiolarMuscle = "line.diagonal"
        public static let bronchiolarMucosa = "line.diagonal"
        public static let bronchiolarCilia = "line.diagonal"
        public static let bronchiolarGlands = "line.diagonal"
        public static let bronchiolarBloodVessels = "line.diagonal"
        public static let bronchiolarNerves = "line.diagonal"
    }
    
    // MARK: - Lung Anatomy
    
    /// External lung illustrations
    public struct ExternalLungs {
        public static let leftLung = "lungs.fill"
        public static let rightLung = "lungs.fill"
        public static let lungLobes = "lungs.fill"
        public static let lungFissures = "lungs.fill"
        public static let lungPleura = "lungs.fill"
        public static let visceralPleura = "lungs.fill"
        public static let parietalPleura = "lungs.fill"
        public static let pleuralCavity = "lungs.fill"
        public static let pleuralFluid = "drop.fill"
        public static let lungSurface = "lungs.fill"
    }
    
    /// Internal lung illustrations
    public struct InternalLungs {
        public static let lungParenchyma = "lungs.fill"
        public static let lungInterstitium = "lungs.fill"
        public static let lungBloodVessels = "line.diagonal"
        public static let lungLymphatics = "line.diagonal"
        public static let lungNerves = "line.diagonal"
        public static let lungConnectiveTissue = "lungs.fill"
        public static let lungElasticFibers = "line.diagonal"
        public static let lungCollagen = "line.diagonal"
        public static let lungSmoothMuscle = "line.diagonal"
        public static let lungMacrophages = "circle.fill"
    }
    
    /// Alveoli illustrations
    public struct Alveoli {
        public static let alveolarSac = "circle.fill"
        public static let alveolarWall = "circle.fill"
        public static let alveolarEpithelium = "circle.fill"
        public static let type1Pneumocytes = "circle.fill"
        public static let type2Pneumocytes = "circle.fill"
        public static let alveolarMacrophages = "circle.fill"
        public static let alveolarCapillaries = "line.diagonal"
        public static let alveolarBasement = "circle.fill"
        public static let alveolarPores = "circle.fill"
        public static let alveolarSurfactant = "drop.fill"
    }
    
    // MARK: - Breathing Mechanics
    
    /// Inspiration illustrations
    public struct Inspiration {
        public static let diaphragmContraction = "line.diagonal"
        public static let intercostalContraction = "line.diagonal"
        public static let ribElevation = "line.diagonal"
        public static let thoracicExpansion = "lungs.fill"
        public static let lungExpansion = "lungs.fill"
        public static let negativePressure = "arrow.up.arrow.down"
        public static let airInflow = "wind"
        public static let alveolarFilling = "circle.fill"
        public static let chestExpansion = "lungs.fill"
        public static let abdominalMovement = "line.diagonal"
    }
    
    /// Expiration illustrations
    public struct Expiration {
        public static let diaphragmRelaxation = "line.diagonal"
        public static let intercostalRelaxation = "line.diagonal"
        public static let ribDepression = "line.diagonal"
        public static let thoracicContraction = "lungs.fill"
        public static let lungContraction = "lungs.fill"
        public static let positivePressure = "arrow.up.arrow.down"
        public static let airOutflow = "wind"
        public static let alveolarEmptying = "circle.fill"
        public static let chestContraction = "lungs.fill"
        public static let abdominalRelaxation = "line.diagonal"
    }
    
    /// Respiratory muscles illustrations
    public struct RespiratoryMuscles {
        public static let diaphragm = "line.diagonal"
        public static let externalIntercostals = "line.diagonal"
        public static let internalIntercostals = "line.diagonal"
        public static let scaleneMuscles = "line.diagonal"
        public static let sternocleidomastoid = "line.diagonal"
        public static let pectoralisMinor = "line.diagonal"
        public static let serratusAnterior = "line.diagonal"
        public static let abdominalMuscles = "line.diagonal"
        public static let accessoryMuscles = "line.diagonal"
        public static let respiratoryMuscleFatigue = "line.diagonal"
    }
    
    // MARK: - Gas Exchange
    
    /// Pulmonary gas exchange illustrations
    public struct PulmonaryGasExchange {
        public static let oxygenDiffusion = "arrow.up.arrow.down"
        public static let carbonDioxideDiffusion = "arrow.up.arrow.down"
        public static let alveolarCapillary = "line.diagonal"
        public static let gasPartialPressure = "drop.fill"
        public static let oxygenSaturation = "drop.fill"
        public static let carbonDioxideSaturation = "drop"
        public static let diffusionGradient = "arrow.up.arrow.down"
        public static let diffusionDistance = "line.diagonal"
        public static let diffusionSurface = "circle.fill"
        public static let diffusionCapacity = "arrow.up.arrow.down"
    }
    
    /// Tissue gas exchange illustrations
    public struct TissueGasExchange {
        public static let oxygenDelivery = "drop.fill"
        public static let carbonDioxideRemoval = "drop"
        public static let tissueCapillaries = "line.diagonal"
        public static let tissueOxygenation = "drop.fill"
        public static let tissueMetabolism = "drop.fill"
        public static let oxygenConsumption = "drop.fill"
        public static let carbonDioxideProduction = "drop"
        public static let tissueAcidosis = "drop"
        public static let tissueAlkalosis = "drop.fill"
        public static let tissueHypoxia = "drop"
    }
    
    // MARK: - Respiratory Physiology
    
    /// Lung volumes illustrations
    public struct LungVolumes {
        public static let tidalVolume = "lungs.fill"
        public static let inspiratoryReserve = "lungs.fill"
        public static let expiratoryReserve = "lungs.fill"
        public static let residualVolume = "lungs.fill"
        public static let vitalCapacity = "lungs.fill"
        public static let totalLungCapacity = "lungs.fill"
        public static let functionalResidual = "lungs.fill"
        public static let inspiratoryCapacity = "lungs.fill"
        public static let forcedExpiratory = "lungs.fill"
        public static let forcedVitalCapacity = "lungs.fill"
    }
    
    /// Respiratory rates illustrations
    public struct RespiratoryRates {
        public static let normalBreathing = "lungs.fill"
        public static let rapidBreathing = "lungs.fill"
        public static let slowBreathing = "lungs.fill"
        public static let deepBreathing = "lungs.fill"
        public static let shallowBreathing = "lungs.fill"
        public static let irregularBreathing = "lungs.fill"
        public static let periodicBreathing = "lungs.fill"
        public static let cheyneStokes = "lungs.fill"
        public static let biotBreathing = "lungs.fill"
        public static let kussmaulBreathing = "lungs.fill"
    }
    
    // MARK: - Respiratory Control
    
    /// Respiratory center illustrations
    public struct RespiratoryCenter {
        public static let medullaryCenter = "brain.head.profile"
        public static let pontineCenter = "brain.head.profile"
        public static let chemoreceptors = "brain.head.profile"
        public static let centralChemoreceptors = "brain.head.profile"
        public static let peripheralChemoreceptors = "brain.head.profile"
        public static let respiratoryNeurons = "brain.head.profile"
        public static let respiratoryRhythm = "brain.head.profile"
        public static let respiratoryDrive = "brain.head.profile"
        public static let respiratoryFeedback = "brain.head.profile"
        public static let respiratoryIntegration = "brain.head.profile"
    }
    
    /// Respiratory reflexes illustrations
    public struct RespiratoryReflexes {
        public static let heringBreuer = "lungs.fill"
        public static let coughReflex = "lungs.fill"
        public static let sneezeReflex = "nose.fill"
        public static let gagReflex = "mouth.fill"
        public static let swallowingReflex = "mouth.fill"
        public static let laryngealReflex = "mouth.fill"
        public static let bronchialReflex = "lungs.fill"
        public static let pulmonaryReflex = "lungs.fill"
        public static let cardiovascularReflex = "heart.circle.fill"
        public static let autonomicReflex = "brain.head.profile"
    }
    
    // MARK: - Respiratory Pathology
    
    /// Obstructive lung disease illustrations
    public struct ObstructiveLungDisease {
        public static let asthma = "lungs.fill"
        public static let chronicBronchitis = "lungs.fill"
        public static let emphysema = "lungs.fill"
        public static let bronchiectasis = "lungs.fill"
        public static let cysticFibrosis = "lungs.fill"
        public static let bronchiolitis = "lungs.fill"
        public static let trachealStenosis = "line.diagonal"
        public static let laryngealStenosis = "mouth.fill"
        public static let foreignBody = "circle.fill"
        public static let tumorObstruction = "circle.fill"
    }
    
    /// Restrictive lung disease illustrations
    public struct RestrictiveLungDisease {
        public static let pulmonaryFibrosis = "lungs.fill"
        public static let sarcoidosis = "lungs.fill"
        public static let pneumoconiosis = "lungs.fill"
        public static let hypersensitivity = "lungs.fill"
        public static let connectiveTissue = "lungs.fill"
        public static let neuromuscular = "lungs.fill"
        public static let chestWall = "lungs.fill"
        public static let pleuralDisease = "lungs.fill"
        public static let kyphoscoliosis = "line.diagonal"
        public static let obesity = "circle.fill"
    }
    
    /// Respiratory infection illustrations
    public struct RespiratoryInfection {
        public static let pneumonia = "lungs.fill"
        public static let tuberculosis = "lungs.fill"
        public static let bronchitis = "lungs.fill"
        public static let bronchiolitis = "lungs.fill"
        public static let sinusitis = "nose.fill"
        public static let pharyngitis = "mouth.fill"
        public static let laryngitis = "mouth.fill"
        public static let tracheitis = "line.diagonal"
        public static let pleurisy = "lungs.fill"
        public static let empyema = "drop.fill"
    }
    
    // MARK: - Respiratory Function Tests
    
    /// Spirometry illustrations
    public struct Spirometry {
        public static let flowVolume = "waveform"
        public static let timeVolume = "waveform"
        public static let peakFlow = "waveform"
        public static let forcedExpiratory = "waveform"
        public static let forcedVitalCapacity = "waveform"
        public static let forcedExpiratoryRatio = "waveform"
        public static let maximalVoluntary = "waveform"
        public static let slowVitalCapacity = "waveform"
        public static let inspiratoryCapacity = "waveform"
        public static let expiratoryReserve = "waveform"
    }
    
    /// Lung function illustrations
    public struct LungFunction {
        public static let diffusionCapacity = "arrow.up.arrow.down"
        public static let lungCompliance = "lungs.fill"
        public static let airwayResistance = "line.diagonal"
        public static let workOfBreathing = "lungs.fill"
        public static let oxygenConsumption = "drop.fill"
        public static let carbonDioxideProduction = "drop"
        public static let ventilationPerfusion = "arrow.up.arrow.down"
        public static let deadSpace = "lungs.fill"
        public static let alveolarVentilation = "lungs.fill"
        public static let minuteVentilation = "lungs.fill"
    }
}

// MARK: - Respiratory Illustration Extensions
public extension RespiratoryIllustrations {
    
    /// Get illustration for respiratory structure
    static func illustrationForStructure(_ structure: RespiratoryStructure) -> String {
        switch structure {
        case .upperTract:
            return NasalCavity.nasalPassages
        case .lowerTract:
            return Trachea.trachealCartilage
        case .lungs:
            return ExternalLungs.leftLung
        case .alveoli:
            return Alveoli.alveolarSac
        case .muscles:
            return RespiratoryMuscles.diaphragm
        case .control:
            return RespiratoryCenter.medullaryCenter
        }
    }
    
    /// Get illustration for respiratory function
    static func illustrationForFunction(_ function: RespiratoryFunction) -> String {
        switch function {
        case .breathing:
            return Inspiration.diaphragmContraction
        case .gasExchange:
            return PulmonaryGasExchange.oxygenDiffusion
        case .volumes:
            return LungVolumes.tidalVolume
        case .control:
            return RespiratoryCenter.medullaryCenter
        case .pathology:
            return ObstructiveLungDisease.asthma
        case .testing:
            return Spirometry.flowVolume
        }
    }
}

// MARK: - Supporting Enums
public enum RespiratoryStructure {
    case upperTract
    case lowerTract
    case lungs
    case alveoli
    case muscles
    case control
}

public enum RespiratoryFunction {
    case breathing
    case gasExchange
    case volumes
    case control
    case pathology
    case testing
} 
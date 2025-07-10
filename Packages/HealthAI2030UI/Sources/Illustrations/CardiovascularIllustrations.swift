import SwiftUI

// MARK: - Cardiovascular Illustrations
/// Detailed cardiovascular anatomical illustrations for HealthAI 2030
/// Provides comprehensive heart anatomy, blood vessels, and circulatory system visualizations for health education
public struct CardiovascularIllustrations {
    
    // MARK: - Heart Anatomy
    
    /// External heart anatomy illustrations
    public struct ExternalHeartAnatomy {
        public static let heartFrontal = "heart.fill"
        public static let heartLateral = "heart.circle.fill"
        public static let heartPosterior = "heart.circle"
        public static let heartInferior = "heart.circle.fill"
        public static let heartSuperior = "heart.circle"
        public static let heartCrossSection = "heart.circle"
        public static let heartSagittal = "heart.circle.fill"
        public static let heartCoronal = "heart.circle"
        public static let heartTransverse = "heart.circle.fill"
        public static let heart3D = "heart.fill"
    }
    
    /// Heart chambers illustrations
    public struct HeartChambers {
        public static let leftAtrium = "heart.circle.fill"
        public static let rightAtrium = "heart.circle"
        public static let leftVentricle = "heart.circle.fill"
        public static let rightVentricle = "heart.circle"
        public static let atrialSeptum = "heart.circle"
        public static let ventricularSeptum = "heart.circle.fill"
        public static let atrioventricular = "heart.circle"
        public static let interventricular = "heart.circle.fill"
        public static let chamberConnections = "heart.circle"
        public static let chamberBloodFlow = "arrow.up.arrow.down"
    }
    
    /// Heart valves illustrations
    public struct HeartValves {
        public static let mitralValve = "heart.circle"
        public static let tricuspidValve = "heart.circle"
        public static let aorticValve = "heart.circle.fill"
        public static let pulmonaryValve = "heart.circle"
        public static let valveOpen = "heart.circle"
        public static let valveClosed = "heart.circle.fill"
        public static let valveProlapse = "heart.circle"
        public static let valveStenosis = "heart.circle.fill"
        public static let valveRegurgitation = "heart.circle"
        public static let valveReplacement = "heart.circle.fill"
    }
    
    /// Heart muscle illustrations
    public struct HeartMuscle {
        public static let myocardium = "heart.fill"
        public static let endocardium = "heart.circle"
        public static let epicardium = "heart.circle.fill"
        public static let cardiacMuscle = "heart.fill"
        public static let muscleFibers = "line.diagonal"
        public static let muscleContraction = "heart.circle"
        public static let muscleRelaxation = "heart.circle.fill"
        public static let muscleThickness = "heart.circle"
        public static let muscleDamage = "heart.circle.fill"
        public static let muscleRegeneration = "heart.circle"
    }
    
    // MARK: - Coronary Circulation
    
    /// Coronary arteries illustrations
    public struct CoronaryArteries {
        public static let leftMain = "line.diagonal"
        public static let leftAnteriorDescending = "line.diagonal"
        public static let leftCircumflex = "line.diagonal"
        public static let rightCoronary = "line.diagonal"
        public static let posteriorDescending = "line.diagonal"
        public static let diagonalBranches = "line.diagonal"
        public static let obtuseMarginal = "line.diagonal"
        public static let coronaryDominance = "line.diagonal"
        public static let coronaryCollateral = "line.diagonal"
        public static let coronaryAnomalies = "line.diagonal"
    }
    
    /// Coronary blood flow illustrations
    public struct CoronaryBloodFlow {
        public static let arterialFlow = "arrow.up.arrow.down"
        public static let venousReturn = "arrow.up.arrow.down"
        public static let capillaryExchange = "arrow.up.arrow.down"
        public static let oxygenDelivery = "drop.fill"
        public static let nutrientDelivery = "drop.fill"
        public static let wasteRemoval = "drop"
        public static let bloodPressure = "drop.fill"
        public static let bloodVelocity = "arrow.up.arrow.down"
        public static let bloodVolume = "drop.fill"
        public static let bloodDistribution = "arrow.up.arrow.down"
    }
    
    // MARK: - Blood Vessels
    
    /// Arterial system illustrations
    public struct ArterialSystem {
        public static let aorta = "line.diagonal"
        public static let ascendingAorta = "line.diagonal"
        public static let aorticArch = "line.diagonal"
        public static let descendingAorta = "line.diagonal"
        public static let thoracicAorta = "line.diagonal"
        public static let abdominalAorta = "line.diagonal"
        public static let carotidArteries = "line.diagonal"
        public static let subclavianArteries = "line.diagonal"
        public static let brachialArteries = "line.diagonal"
        public static let femoralArteries = "line.diagonal"
    }
    
    /// Venous system illustrations
    public struct VenousSystem {
        public static let superiorVenaCava = "line.diagonal"
        public static let inferiorVenaCava = "line.diagonal"
        public static let jugularVeins = "line.diagonal"
        public static let subclavianVeins = "line.diagonal"
        public static let brachialVeins = "line.diagonal"
        public static let femoralVeins = "line.diagonal"
        public static let portalVein = "line.diagonal"
        public static let hepaticVeins = "line.diagonal"
        public static let pulmonaryVeins = "line.diagonal"
        public static let coronaryVeins = "line.diagonal"
    }
    
    /// Capillary network illustrations
    public struct CapillaryNetwork {
        public static let capillaryBeds = "line.diagonal"
        public static let capillaryExchange = "arrow.up.arrow.down"
        public static let oxygenDiffusion = "arrow.up.arrow.down"
        public static let carbonDioxideDiffusion = "arrow.up.arrow.down"
        public static let nutrientExchange = "arrow.up.arrow.down"
        public static let wasteExchange = "arrow.up.arrow.down"
        public static let capillaryDensity = "line.diagonal"
        public static let capillaryDiameter = "line.diagonal"
        public static let capillaryFlow = "arrow.up.arrow.down"
        public static let capillaryPressure = "drop.fill"
    }
    
    // MARK: - Circulatory System
    
    /// Systemic circulation illustrations
    public struct SystemicCirculation {
        public static let systemicFlow = "arrow.up.arrow.down"
        public static let oxygenatedBlood = "drop.fill"
        public static let deoxygenatedBlood = "drop"
        public static let bloodDistribution = "arrow.up.arrow.down"
        public static let organPerfusion = "arrow.up.arrow.down"
        public static let tissueOxygenation = "drop.fill"
        public static let bloodPressure = "drop.fill"
        public static let bloodVolume = "drop.fill"
        public static let bloodVelocity = "arrow.up.arrow.down"
        public static let bloodResistance = "line.diagonal"
    }
    
    /// Pulmonary circulation illustrations
    public struct PulmonaryCirculation {
        public static let pulmonaryFlow = "lungs.fill"
        public static let pulmonaryArteries = "line.diagonal"
        public static let pulmonaryVeins = "line.diagonal"
        public static let pulmonaryCapillaries = "line.diagonal"
        public static let gasExchange = "arrow.up.arrow.down"
        public static let oxygenUptake = "drop.fill"
        public static let carbonDioxideRelease = "drop"
        public static let pulmonaryPressure = "drop.fill"
        public static let pulmonaryResistance = "line.diagonal"
        public static let pulmonaryBloodFlow = "arrow.up.arrow.down"
    }
    
    /// Fetal circulation illustrations
    public struct FetalCirculation {
        public static let umbilicalVein = "line.diagonal"
        public static let umbilicalArteries = "line.diagonal"
        public static let ductusVenosus = "line.diagonal"
        public static let ductusArteriosus = "line.diagonal"
        public static let foramenOvale = "circle.fill"
        public static let placentalExchange = "arrow.up.arrow.down"
        public static let fetalHeart = "heart.circle.fill"
        public static let fetalBloodFlow = "arrow.up.arrow.down"
        public static let maternalBlood = "drop.fill"
        public static let fetalBlood = "drop.fill"
    }
    
    // MARK: - Cardiac Conduction
    
    /// Conduction system illustrations
    public struct ConductionSystem {
        public static let sinoatrialNode = "bolt.fill"
        public static let atrioventricularNode = "bolt.fill"
        public static let bundleOfHis = "line.diagonal"
        public static let bundleBranches = "line.diagonal"
        public static let purkinjeFibers = "line.diagonal"
        public static let electricalImpulse = "bolt.fill"
        public static let conductionPathway = "line.diagonal"
        public static let pacemaker = "bolt.fill"
        public static let conductionDelay = "bolt.fill"
        public static let conductionBlock = "bolt.fill"
    }
    
    /// ECG wave illustrations
    public struct ECGWaves {
        public static let pWave = "waveform.path.ecg"
        public static let qrsComplex = "waveform.path.ecg"
        public static let tWave = "waveform.path.ecg"
        public static let uWave = "waveform.path.ecg"
        public static let normalRhythm = "waveform.path.ecg"
        public static let sinusRhythm = "waveform.path.ecg"
        public static let atrialFibrillation = "waveform.path.ecg"
        public static let ventricularTachycardia = "waveform.path.ecg"
        public static let ventricularFibrillation = "waveform.path.ecg"
        public static let heartBlock = "waveform.path.ecg"
    }
    
    // MARK: - Cardiac Cycle
    
    /// Cardiac cycle phases illustrations
    public struct CardiacCycle {
        public static let atrialSystole = "heart.circle"
        public static let ventricularSystole = "heart.circle.fill"
        public static let atrialDiastole = "heart.circle"
        public static let ventricularDiastole = "heart.circle.fill"
        public static let isovolumetricContraction = "heart.circle"
        public static let isovolumetricRelaxation = "heart.circle.fill"
        public static let rapidEjection = "heart.circle"
        public static let reducedEjection = "heart.circle.fill"
        public static let rapidFilling = "heart.circle"
        public static let reducedFilling = "heart.circle.fill"
    }
    
    /// Heart sounds illustrations
    public struct HeartSounds {
        public static let s1Sound = "waveform"
        public static let s2Sound = "waveform"
        public static let s3Sound = "waveform"
        public static let s4Sound = "waveform"
        public static let normalSounds = "waveform"
        public static let murmur = "waveform"
        public static let gallop = "waveform"
        public static let click = "waveform"
        public static let rub = "waveform"
        public static let split = "waveform"
    }
    
    // MARK: - Cardiovascular Physiology
    
    /// Blood pressure illustrations
    public struct BloodPressure {
        public static let systolicPressure = "drop.fill"
        public static let diastolicPressure = "drop"
        public static let pulsePressure = "drop.fill"
        public static let meanPressure = "drop.fill"
        public static let pressureWave = "waveform"
        public static let hypertension = "drop.fill"
        public static let hypotension = "drop"
        public static let pressureGradient = "arrow.up.arrow.down"
        public static let pressureRegulation = "arrow.up.arrow.down"
        public static let pressureMeasurement = "drop.fill"
    }
    
    /// Cardiac output illustrations
    public struct CardiacOutput {
        public static let strokeVolume = "drop.fill"
        public static let heartRate = "heart.circle.fill"
        public static let cardiacOutput = "drop.fill"
        public static let ejectionFraction = "heart.circle"
        public static let preload = "drop.fill"
        public static let afterload = "line.diagonal"
        public static let contractility = "heart.circle.fill"
        public static let cardiacIndex = "drop.fill"
        public static let cardiacReserve = "drop.fill"
        public static let cardiacEfficiency = "heart.circle"
    }
    
    // MARK: - Cardiovascular Pathology
    
    /// Heart disease illustrations
    public struct HeartDisease {
        public static let coronaryDisease = "heart.circle.fill"
        public static let myocardialInfarction = "heart.circle.fill"
        public static let heartFailure = "heart.circle"
        public static let cardiomyopathy = "heart.circle.fill"
        public static let valveDisease = "heart.circle"
        public static let pericarditis = "heart.circle"
        public static let endocarditis = "heart.circle.fill"
        public static let arrhythmia = "waveform.path.ecg"
        public static let congenitalDefects = "heart.circle"
        public static let heartTumor = "heart.circle.fill"
    }
    
    /// Vascular disease illustrations
    public struct VascularDisease {
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
}

// MARK: - Cardiovascular Illustration Extensions
public extension CardiovascularIllustrations {
    
    /// Get illustration for cardiovascular structure
    static func illustrationForStructure(_ structure: CardiovascularStructure) -> String {
        switch structure {
        case .heart:
            return ExternalHeartAnatomy.heartFrontal
        case .chambers:
            return HeartChambers.leftAtrium
        case .valves:
            return HeartValves.mitralValve
        case .muscle:
            return HeartMuscle.myocardium
        case .coronary:
            return CoronaryArteries.leftMain
        case .arteries:
            return ArterialSystem.aorta
        case .veins:
            return VenousSystem.superiorVenaCava
        case .capillaries:
            return CapillaryNetwork.capillaryBeds
        case .conduction:
            return ConductionSystem.sinoatrialNode
        case .cycle:
            return CardiacCycle.atrialSystole
        }
    }
    
    /// Get illustration for cardiovascular function
    static func illustrationForFunction(_ function: CardiovascularFunction) -> String {
        switch function {
        case .circulation:
            return SystemicCirculation.systemicFlow
        case .pulmonary:
            return PulmonaryCirculation.pulmonaryFlow
        case .fetal:
            return FetalCirculation.umbilicalVein
        case .bloodPressure:
            return BloodPressure.systolicPressure
        case .cardiacOutput:
            return CardiacOutput.strokeVolume
        case .heartSounds:
            return HeartSounds.s1Sound
        case .ecg:
            return ECGWaves.normalRhythm
        }
    }
}

// MARK: - Supporting Enums
public enum CardiovascularStructure {
    case heart
    case chambers
    case valves
    case muscle
    case coronary
    case arteries
    case veins
    case capillaries
    case conduction
    case cycle
}

public enum CardiovascularFunction {
    case circulation
    case pulmonary
    case fetal
    case bloodPressure
    case cardiacOutput
    case heartSounds
    case ecg
} 
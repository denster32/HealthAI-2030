import SwiftUI

// MARK: - Digestive Illustrations
/// Detailed digestive system anatomical illustrations for HealthAI 2030
/// Provides comprehensive GI tract anatomy, digestive organs, and digestive process visualizations for health education
public struct DigestiveIllustrations {
    
    // MARK: - Upper Digestive Tract
    
    /// Oral cavity illustrations
    public struct OralCavity {
        public static let mouth = "mouth.fill"
        public static let tongue = "mouth.fill"
        public static let teeth = "mouth.fill"
        public static let gums = "mouth.fill"
        public static let palate = "mouth.fill"
        public static let uvula = "mouth.fill"
        public static let salivaryGlands = "mouth.fill"
        public static let tasteBuds = "mouth.fill"
        public static let oralMucosa = "mouth.fill"
        public static let oralMuscles = "mouth.fill"
    }
    
    /// Pharynx and esophagus illustrations
    public struct PharynxAndEsophagus {
        public static let pharynx = "mouth.fill"
        public static let esophagus = "line.diagonal"
        public static let upperEsophageal = "line.diagonal"
        public static let lowerEsophageal = "line.diagonal"
        public static let esophagealMuscle = "line.diagonal"
        public static let esophagealMucosa = "line.diagonal"
        public static let esophagealGlands = "line.diagonal"
        public static let esophagealBloodVessels = "line.diagonal"
        public static let esophagealNerves = "line.diagonal"
        public static let esophagealLymphatics = "line.diagonal"
    }
    
    /// Stomach illustrations
    public struct Stomach {
        public static let stomachBody = "circle.fill"
        public static let fundus = "circle.fill"
        public static let antrum = "circle.fill"
        public static let pylorus = "circle.fill"
        public static let gastricMucosa = "circle.fill"
        public static let gastricGlands = "circle.fill"
        public static let parietalCells = "circle.fill"
        public static let chiefCells = "circle.fill"
        public static let mucousCells = "circle.fill"
        public static let gastricMuscle = "circle.fill"
    }
    
    // MARK: - Lower Digestive Tract
    
    /// Small intestine illustrations
    public struct SmallIntestine {
        public static let duodenum = "line.diagonal"
        public static let jejunum = "line.diagonal"
        public static let ileum = "line.diagonal"
        public static let intestinalVilli = "line.diagonal"
        public static let intestinalCrypts = "line.diagonal"
        public static let intestinalMucosa = "line.diagonal"
        public static let intestinalMuscle = "line.diagonal"
        public static let intestinalGlands = "line.diagonal"
        public static let intestinalBloodVessels = "line.diagonal"
        public static let intestinalLymphatics = "line.diagonal"
    }
    
    /// Large intestine illustrations
    public struct LargeIntestine {
        public static let cecum = "line.diagonal"
        public static let ascendingColon = "line.diagonal"
        public static let transverseColon = "line.diagonal"
        public static let descendingColon = "line.diagonal"
        public static let sigmoidColon = "line.diagonal"
        public static let rectum = "line.diagonal"
        public static let analCanal = "line.diagonal"
        public static let colonMucosa = "line.diagonal"
        public static let colonMuscle = "line.diagonal"
        public static let haustra = "line.diagonal"
    }
    
    /// Anus and defecation illustrations
    public struct AnusAndDefecation {
        public static let analSphincters = "line.diagonal"
        public static let internalSphincter = "line.diagonal"
        public static let externalSphincter = "line.diagonal"
        public static let analCanal = "line.diagonal"
        public static let analColumns = "line.diagonal"
        public static let analValves = "line.diagonal"
        public static let hemorrhoidalPlexus = "line.diagonal"
        public static let defecation = "arrow.up.arrow.down"
        public static let continence = "line.diagonal"
        public static let analReflexes = "line.diagonal"
    }
    
    // MARK: - Accessory Digestive Organs
    
    /// Liver illustrations
    public struct Liver {
        public static let liverLobes = "circle.fill"
        public static let rightLobe = "circle.fill"
        public static let leftLobe = "circle.fill"
        public static let caudateLobe = "circle.fill"
        public static let quadrateLobe = "circle.fill"
        public static let liverCells = "circle.fill"
        public static let hepatocytes = "circle.fill"
        public static let kupfferCells = "circle.fill"
        public static let liverSinusoids = "line.diagonal"
        public static let portalTriads = "circle.fill"
    }
    
    /// Gallbladder illustrations
    public struct Gallbladder {
        public static let gallbladderBody = "circle.fill"
        public static let gallbladderFundus = "circle.fill"
        public static let gallbladderNeck = "circle.fill"
        public static let cysticDuct = "line.diagonal"
        public static let gallbladderMucosa = "circle.fill"
        public static let gallbladderMuscle = "circle.fill"
        public static let bileStorage = "drop.fill"
        public static let bileConcentration = "drop.fill"
        public static let gallbladderContraction = "circle.fill"
        public static let bileRelease = "drop.fill"
    }
    
    /// Pancreas illustrations
    public struct Pancreas {
        public static let pancreasHead = "circle.fill"
        public static let pancreasBody = "circle.fill"
        public static let pancreasTail = "circle.fill"
        public static let pancreaticDuct = "line.diagonal"
        public static let accessoryDuct = "line.diagonal"
        public static let acinarCells = "circle.fill"
        public static let isletCells = "circle.fill"
        public static let betaCells = "circle.fill"
        public static let alphaCells = "circle.fill"
        public static let deltaCells = "circle.fill"
    }
    
    /// Spleen illustrations
    public struct Spleen {
        public static let spleenBody = "circle.fill"
        public static let spleenCapsule = "circle.fill"
        public static let redPulp = "circle.fill"
        public static let whitePulp = "circle.fill"
        public static let splenicArtery = "line.diagonal"
        public static let splenicVein = "line.diagonal"
        public static let splenicLymphatics = "line.diagonal"
        public static let splenicMacrophages = "circle.fill"
        public static let splenicLymphocytes = "circle.fill"
        public static let splenicFunction = "circle.fill"
    }
    
    // MARK: - Digestive Processes
    
    /// Ingestion illustrations
    public struct Ingestion {
        public static let chewing = "mouth.fill"
        public static let swallowing = "mouth.fill"
        public static let salivaSecretion = "drop.fill"
        public static let tastePerception = "mouth.fill"
        public static let smellPerception = "nose.fill"
        public static let foodBolus = "circle.fill"
        public static let oralDigestion = "mouth.fill"
        public static let mechanicalBreakdown = "mouth.fill"
        public static let chemicalBreakdown = "drop.fill"
        public static let foodTransport = "arrow.up.arrow.down"
    }
    
    /// Digestion illustrations
    public struct Digestion {
        public static let mechanicalDigestion = "arrow.up.arrow.down"
        public static let chemicalDigestion = "drop.fill"
        public static let enzymaticBreakdown = "drop.fill"
        public static let proteinDigestion = "drop.fill"
        public static let carbohydrateDigestion = "drop.fill"
        public static let fatDigestion = "drop.fill"
        public static let nucleicAcidDigestion = "drop.fill"
        public static let gastricDigestion = "circle.fill"
        public static let intestinalDigestion = "line.diagonal"
        public static let pancreaticDigestion = "circle.fill"
    }
    
    /// Absorption illustrations
    public struct Absorption {
        public static let nutrientAbsorption = "arrow.up.arrow.down"
        public static let waterAbsorption = "drop.fill"
        public static let electrolyteAbsorption = "drop.fill"
        public static let vitaminAbsorption = "drop.fill"
        public static let mineralAbsorption = "drop.fill"
        public static let aminoAcidAbsorption = "drop.fill"
        public static let glucoseAbsorption = "drop.fill"
        public static let fattyAcidAbsorption = "drop.fill"
        public static let bileSaltAbsorption = "drop.fill"
        public static let drugAbsorption = "drop.fill"
    }
    
    /// Secretion illustrations
    public struct Secretion {
        public static let salivaSecretion = "drop.fill"
        public static let gastricSecretion = "drop.fill"
        public static let pancreaticSecretion = "drop.fill"
        public static let bileSecretion = "drop.fill"
        public static let intestinalSecretion = "drop.fill"
        public static let mucusSecretion = "drop.fill"
        public static let enzymeSecretion = "drop.fill"
        public static let hormoneSecretion = "drop.fill"
        public static let acidSecretion = "drop.fill"
        public static let bicarbonateSecretion = "drop.fill"
    }
    
    // MARK: - Digestive Hormones
    
    /// Hormone regulation illustrations
    public struct HormoneRegulation {
        public static let gastrin = "drop.fill"
        public static let secretin = "drop.fill"
        public static let cholecystokinin = "drop.fill"
        public static let gastricInhibitory = "drop.fill"
        public static let motilin = "drop.fill"
        public static let somatostatin = "drop.fill"
        public static let glucagon = "drop.fill"
        public static let insulin = "drop.fill"
        public static let ghrelin = "drop.fill"
        public static let leptin = "drop.fill"
    }
    
    /// Hormone function illustrations
    public struct HormoneFunction {
        public static let acidStimulation = "drop.fill"
        public static let enzymeStimulation = "drop.fill"
        public static let bileStimulation = "drop.fill"
        public static let motilityStimulation = "arrow.up.arrow.down"
        public static let motilityInhibition = "arrow.up.arrow.down"
        public static let appetiteStimulation = "heart.fill"
        public static let appetiteInhibition = "heart.fill"
        public static let satietySignaling = "heart.fill"
        public static let hungerSignaling = "heart.fill"
        public static let metabolicRegulation = "drop.fill"
    }
    
    // MARK: - Digestive Motility
    
    /// Peristalsis illustrations
    public struct Peristalsis {
        public static let esophagealPeristalsis = "arrow.up.arrow.down"
        public static let gastricPeristalsis = "arrow.up.arrow.down"
        public static let intestinalPeristalsis = "arrow.up.arrow.down"
        public static let colonicPeristalsis = "arrow.up.arrow.down"
        public static let segmentation = "arrow.up.arrow.down"
        public static let massMovement = "arrow.up.arrow.down"
        public static let haustralChurning = "arrow.up.arrow.down"
        public static let migratingMotor = "arrow.up.arrow.down"
        public static let retrogradeMovement = "arrow.up.arrow.down"
        public static let mixingMovement = "arrow.up.arrow.down"
    }
    
    /// Sphincter function illustrations
    public struct SphincterFunction {
        public static let upperEsophageal = "line.diagonal"
        public static let lowerEsophageal = "line.diagonal"
        public static let pyloricSphincter = "circle.fill"
        public static let ileocecalSphincter = "line.diagonal"
        public static let internalAnalSphincter = "line.diagonal"
        public static let externalAnalSphincter = "line.diagonal"
        public static let sphincterRelaxation = "line.diagonal"
        public static let sphincterContraction = "line.diagonal"
        public static let sphincterCoordination = "line.diagonal"
        public static let sphincterDysfunction = "line.diagonal"
    }
    
    // MARK: - Digestive Pathology
    
    /// Upper GI disorders illustrations
    public struct UpperGIDisorders {
        public static let gastritis = "circle.fill"
        public static let pepticUlcer = "circle.fill"
        public static let gastroesophagealReflux = "line.diagonal"
        public static let esophagealStricture = "line.diagonal"
        public static let esophagealCancer = "line.diagonal"
        public static let gastricCancer = "circle.fill"
        public static let hiatalHernia = "line.diagonal"
        public static let achalasia = "line.diagonal"
        public static let esophagealVarices = "line.diagonal"
        public static let malloryWeiss = "line.diagonal"
    }
    
    /// Lower GI disorders illustrations
    public struct LowerGIDisorders {
        public static let inflammatoryBowel = "line.diagonal"
        public static let crohnsDisease = "line.diagonal"
        public static let ulcerativeColitis = "line.diagonal"
        public static let irritableBowel = "line.diagonal"
        public static let diverticulosis = "line.diagonal"
        public static let diverticulitis = "line.diagonal"
        public static let colorectalCancer = "line.diagonal"
        public static let hemorrhoids = "line.diagonal"
        public static let analFissure = "line.diagonal"
        public static let fecalIncontinence = "line.diagonal"
    }
    
    /// Liver disorders illustrations
    public struct LiverDisorders {
        public static let hepatitis = "circle.fill"
        public static let cirrhosis = "circle.fill"
        public static let fattyLiver = "circle.fill"
        public static let liverCancer = "circle.fill"
        public static let liverFailure = "circle.fill"
        public static let portalHypertension = "drop.fill"
        public static let ascites = "drop.fill"
        public static let jaundice = "circle.fill"
        public static let liverEnlargement = "circle.fill"
        public static let liverInflammation = "circle.fill"
    }
    
    /// Pancreatic disorders illustrations
    public struct PancreaticDisorders {
        public static let pancreatitis = "circle.fill"
        public static let pancreaticCancer = "circle.fill"
        public static let pancreaticInsufficiency = "circle.fill"
        public static let diabetesMellitus = "drop.fill"
        public static let pancreaticCysts = "circle.fill"
        public static let pancreaticStones = "circle.fill"
        public static let pancreaticPseudocyst = "circle.fill"
        public static let pancreaticAbscess = "circle.fill"
        public static let pancreaticFistula = "line.diagonal"
        public static let pancreaticAtrophy = "circle.fill"
    }
    
    // MARK: - Digestive Function Tests
    
    /// Diagnostic procedures illustrations
    public struct DiagnosticProcedures {
        public static let endoscopy = "camera.fill"
        public static let colonoscopy = "camera.fill"
        public static let sigmoidoscopy = "camera.fill"
        public static let capsuleEndoscopy = "capsule.fill"
        public static let bariumSwallow = "rays"
        public static let bariumEnema = "rays"
        public static let ctScan = "rays"
        public static let mri = "brain.head.profile"
        public static let ultrasound = "waveform"
        public static let biopsy = "scissors"
    }
    
    /// Laboratory tests illustrations
    public struct LaboratoryTests {
        public static let stoolAnalysis = "drop.fill"
        public static let bloodTests = "drop.fill"
        public static let liverFunction = "drop.fill"
        public static let pancreaticFunction = "drop.fill"
        public static let gastricAnalysis = "drop.fill"
        public static let breathTests = "wind"
        public static let stoolCulture = "drop.fill"
        public static let parasiteExam = "magnifyingglass"
        public static let occultBlood = "drop.fill"
        public static let fecalFat = "drop.fill"
    }
}

// MARK: - Digestive Illustration Extensions
public extension DigestiveIllustrations {
    
    /// Get illustration for digestive structure
    static func illustrationForStructure(_ structure: DigestiveStructure) -> String {
        switch structure {
        case .upperTract:
            return OralCavity.mouth
        case .lowerTract:
            return SmallIntestine.duodenum
        case .accessory:
            return Liver.liverLobes
        case .processes:
            return Ingestion.chewing
        case .hormones:
            return HormoneRegulation.gastrin
        case .motility:
            return Peristalsis.esophagealPeristalsis
        }
    }
    
    /// Get illustration for digestive function
    static func illustrationForFunction(_ function: DigestiveFunction) -> String {
        switch function {
        case .ingestion:
            return Ingestion.chewing
        case .digestion:
            return Digestion.mechanicalDigestion
        case .absorption:
            return Absorption.nutrientAbsorption
        case .secretion:
            return Secretion.salivaSecretion
        case .motility:
            return Peristalsis.esophagealPeristalsis
        case .elimination:
            return AnusAndDefecation.defecation
        }
    }
}

// MARK: - Supporting Enums
public enum DigestiveStructure {
    case upperTract
    case lowerTract
    case accessory
    case processes
    case hormones
    case motility
}

public enum DigestiveFunction {
    case ingestion
    case digestion
    case absorption
    case secretion
    case motility
    case elimination
} 
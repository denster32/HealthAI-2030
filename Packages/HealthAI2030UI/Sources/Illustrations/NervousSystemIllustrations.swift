import SwiftUI

// MARK: - Nervous System Illustrations
/// Detailed nervous system anatomical illustrations for HealthAI 2030
/// Provides comprehensive brain anatomy, nerve structure, and neural pathway visualizations for health education
public struct NervousSystemIllustrations {
    
    // MARK: - Central Nervous System
    
    /// Brain anatomy illustrations
    public struct BrainAnatomy {
        public static let cerebrum = "brain.head.profile"
        public static let cerebellum = "brain.head.profile"
        public static let brainstem = "brain.head.profile"
        public static let diencephalon = "brain.head.profile"
        public static let midbrain = "brain.head.profile"
        public static let pons = "brain.head.profile"
        public static let medulla = "brain.head.profile"
        public static let thalamus = "brain.head.profile"
        public static let hypothalamus = "brain.head.profile"
        public static let pituitary = "circle.fill"
    }
    
    /// Cerebral lobes illustrations
    public struct CerebralLobes {
        public static let frontalLobe = "brain.head.profile"
        public static let temporalLobe = "brain.head.profile"
        public static let parietalLobe = "brain.head.profile"
        public static let occipitalLobe = "brain.head.profile"
        public static let insula = "brain.head.profile"
        public static let limbicLobe = "brain.head.profile"
        public static let cingulateGyrus = "brain.head.profile"
        public static let parahippocampalGyrus = "brain.head.profile"
        public static let uncus = "brain.head.profile"
        public static let subcallosalGyrus = "brain.head.profile"
    }
    
    /// Brain structures illustrations
    public struct BrainStructures {
        public static let hippocampus = "brain.head.profile"
        public static let amygdala = "brain.head.profile"
        public static let basalGanglia = "brain.head.profile"
        public static let corpusCallosum = "brain.head.profile"
        public static let fornix = "line.diagonal"
        public static let septumPellucidum = "brain.head.profile"
        public static let ventricles = "circle.fill"
        public static let choroidPlexus = "circle.fill"
        public static let cerebralAqueduct = "line.diagonal"
        public static let centralCanal = "line.diagonal"
    }
    
    // MARK: - Spinal Cord
    
    /// Spinal cord anatomy illustrations
    public struct SpinalCordAnatomy {
        public static let cervicalCord = "line.diagonal"
        public static let thoracicCord = "line.diagonal"
        public static let lumbarCord = "line.diagonal"
        public static let sacralCord = "line.diagonal"
        public static let coccygealCord = "line.diagonal"
        public static let grayMatter = "line.diagonal"
        public static let whiteMatter = "line.diagonal"
        public static let dorsalHorn = "line.diagonal"
        public static let ventralHorn = "line.diagonal"
        public static let lateralHorn = "line.diagonal"
    }
    
    /// Spinal cord tracts illustrations
    public struct SpinalCordTracts {
        public static let corticospinalTract = "line.diagonal"
        public static let spinothalamicTract = "line.diagonal"
        public static let dorsalColumn = "line.diagonal"
        public static let spinocerebellarTract = "line.diagonal"
        public static let rubrospinalTract = "line.diagonal"
        public static let vestibulospinalTract = "line.diagonal"
        public static let reticulospinalTract = "line.diagonal"
        public static let tectospinalTract = "line.diagonal"
        public static let olivospinalTract = "line.diagonal"
        public static let autonomicTracts = "line.diagonal"
    }
    
    /// Spinal nerves illustrations
    public struct SpinalNerves {
        public static let cervicalNerves = "line.diagonal"
        public static let thoracicNerves = "line.diagonal"
        public static let lumbarNerves = "line.diagonal"
        public static let sacralNerves = "line.diagonal"
        public static let coccygealNerves = "line.diagonal"
        public static let dorsalRoot = "line.diagonal"
        public static let ventralRoot = "line.diagonal"
        public static let dorsalRootGanglion = "circle.fill"
        public static let spinalNerve = "line.diagonal"
        public static let rami = "line.diagonal"
    }
    
    // MARK: - Peripheral Nervous System
    
    /// Cranial nerves illustrations
    public struct CranialNerves {
        public static let olfactory = "nose.fill"
        public static let optic = "eye.fill"
        public static let oculomotor = "eye.fill"
        public static let trochlear = "eye.fill"
        public static let trigeminal = "face.dashed"
        public static let abducens = "eye.fill"
        public static let facial = "face.dashed"
        public static let vestibulocochlear = "ear.fill"
        public static let glossopharyngeal = "mouth.fill"
        public static let vagus = "line.diagonal"
        public static let accessory = "line.diagonal"
        public static let hypoglossal = "mouth.fill"
    }
    
    /// Peripheral nerves illustrations
    public struct PeripheralNerves {
        public static let brachialPlexus = "line.diagonal"
        public static let lumbarPlexus = "line.diagonal"
        public static let sacralPlexus = "line.diagonal"
        public static let medianNerve = "line.diagonal"
        public static let ulnarNerve = "line.diagonal"
        public static let radialNerve = "line.diagonal"
        public static let femoralNerve = "line.diagonal"
        public static let sciaticNerve = "line.diagonal"
        public static let tibialNerve = "line.diagonal"
        public static let peronealNerve = "line.diagonal"
    }
    
    /// Autonomic nervous system illustrations
    public struct AutonomicNervousSystem {
        public static let sympathetic = "line.diagonal"
        public static let parasympathetic = "line.diagonal"
        public static let enteric = "line.diagonal"
        public static let sympatheticChain = "line.diagonal"
        public static let preganglionic = "line.diagonal"
        public static let postganglionic = "line.diagonal"
        public static let autonomicGanglia = "circle.fill"
        public static let autonomicReflexes = "line.diagonal"
        public static let autonomicTone = "line.diagonal"
        public static let autonomicBalance = "scale.3d"
    }
    
    // MARK: - Neuron Structure
    
    /// Neuron anatomy illustrations
    public struct NeuronAnatomy {
        public static let cellBody = "circle.fill"
        public static let dendrites = "line.diagonal"
        public static let axon = "line.diagonal"
        public static let axonHillock = "line.diagonal"
        public static let myelinSheath = "line.diagonal"
        public static let nodesOfRanvier = "line.diagonal"
        public static let axonTerminals = "line.diagonal"
        public static let synapticKnobs = "circle.fill"
        public static let neurofilaments = "line.diagonal"
        public static let microtubules = "line.diagonal"
    }
    
    /// Neuron types illustrations
    public struct NeuronTypes {
        public static let multipolarNeuron = "circle.fill"
        public static let bipolarNeuron = "circle.fill"
        public static let unipolarNeuron = "circle.fill"
        public static let pseudounipolarNeuron = "circle.fill"
        public static let sensoryNeuron = "circle.fill"
        public static let motorNeuron = "circle.fill"
        public static let interneuron = "circle.fill"
        public static let pyramidalNeuron = "circle.fill"
        public static let purkinjeNeuron = "circle.fill"
        public static let granuleNeuron = "circle.fill"
    }
    
    /// Synapse illustrations
    public struct Synapse {
        public static let chemicalSynapse = "line.diagonal"
        public static let electricalSynapse = "line.diagonal"
        public static let presynapticTerminal = "circle.fill"
        public static let postsynapticMembrane = "circle.fill"
        public static let synapticCleft = "line.diagonal"
        public static let synapticVesicles = "circle.fill"
        public static let neurotransmitter = "drop.fill"
        public static let receptorSites = "circle.fill"
        public static let synapticPlasticity = "line.diagonal"
        public static let synapticStrength = "line.diagonal"
    }
    
    // MARK: - Neural Pathways
    
    /// Sensory pathways illustrations
    public struct SensoryPathways {
        public static let somatosensory = "line.diagonal"
        public static let visualPathway = "eye.fill"
        public static let auditoryPathway = "ear.fill"
        public static let olfactoryPathway = "nose.fill"
        public static let gustatoryPathway = "mouth.fill"
        public static let vestibularPathway = "ear.fill"
        public static let proprioceptive = "hand.raised.fill"
        public static let nociceptive = "exclamationmark.triangle.fill"
        public static let thermoreceptive = "thermometer"
        public static let mechanoreceptive = "hand.raised.fill"
        public static let chemoreceptive = "nose.fill"
    }
    
    /// Motor pathways illustrations
    public struct MotorPathways {
        public static let corticospinal = "line.diagonal"
        public static let corticobulbar = "line.diagonal"
        public static let extrapyramidal = "line.diagonal"
        public static let rubrospinal = "line.diagonal"
        public static let vestibulospinal = "line.diagonal"
        public static let reticulospinal = "line.diagonal"
        public static let tectospinal = "line.diagonal"
        public static let olivospinal = "line.diagonal"
        public static let autonomicMotor = "line.diagonal"
        public static let somaticMotor = "line.diagonal"
    }
    
    /// Association pathways illustrations
    public struct AssociationPathways {
        public static let arcuateFasciculus = "line.diagonal"
        public static let cingulum = "line.diagonal"
        public static let uncinateFasciculus = "line.diagonal"
        public static let superiorLongitudinal = "line.diagonal"
        public static let inferiorLongitudinal = "line.diagonal"
        public static let frontoOccipital = "line.diagonal"
        public static let corpusCallosum = "brain.head.profile"
        public static let anteriorCommissure = "line.diagonal"
        public static let posteriorCommissure = "line.diagonal"
        public static let habenularCommissure = "line.diagonal"
    }
    
    // MARK: - Brain Function
    
    /// Cognitive function illustrations
    public struct CognitiveFunction {
        public static let memory = "brain.head.profile"
        public static let attention = "target"
        public static let language = "mouth.fill"
        public static let executiveFunction = "brain.head.profile"
        public static let spatialProcessing = "eye.fill"
        public static let temporalProcessing = "clock.fill"
        public static let emotionalProcessing = "heart.fill"
        public static let decisionMaking = "brain.head.profile"
        public static let problemSolving = "brain.head.profile"
        public static let creativity = "paintbrush.fill"
    }
    
    /// Motor function illustrations
    public struct MotorFunction {
        public static let voluntaryMovement = "figure.walk"
        public static let involuntaryMovement = "figure.walk"
        public static let fineMotor = "hand.raised.fill"
        public static let grossMotor = "figure.walk"
        public static let coordination = "figure.walk"
        public static let balance = "figure.walk"
        public static let posture = "figure.walk"
        public static let gait = "figure.walk"
        public static let reflexes = "hand.raised.fill"
        public static let motorLearning = "figure.walk"
    }
    
    /// Sensory function illustrations
    public struct SensoryFunction {
        public static let vision = "eye.fill"
        public static let hearing = "ear.fill"
        public static let smell = "nose.fill"
        public static let taste = "mouth.fill"
        public static let touch = "hand.raised.fill"
        public static let proprioception = "hand.raised.fill"
        public static let pain = "exclamationmark.triangle.fill"
        public static let temperature = "thermometer"
        public static let vibration = "waveform"
        public static let pressure = "hand.raised.fill"
    }
    
    // MARK: - Neurotransmitters
    
    /// Neurotransmitter types illustrations
    public struct Neurotransmitters {
        public static let acetylcholine = "drop.fill"
        public static let dopamine = "drop.fill"
        public static let serotonin = "drop.fill"
        public static let norepinephrine = "drop.fill"
        public static let epinephrine = "drop.fill"
        public static let glutamate = "drop.fill"
        public static let gaba = "drop.fill"
        public static let glycine = "drop.fill"
        public static let endorphins = "drop.fill"
        public static let substanceP = "drop.fill"
    }
    
    /// Neurotransmitter function illustrations
    public struct NeurotransmitterFunction {
        public static let excitatory = "bolt.fill"
        public static let inhibitory = "minus.circle.fill"
        public static let neuromodulatory = "drop.fill"
        public static let synapticTransmission = "line.diagonal"
        public static let receptorActivation = "circle.fill"
        public static let signalAmplification = "bolt.fill"
        public static let signalInhibition = "minus.circle.fill"
        public static let neurotransmitterSynthesis = "drop.fill"
        public static let neurotransmitterRelease = "drop.fill"
        public static let neurotransmitterReuptake = "drop.fill"
    }
    
    // MARK: - Nervous System Pathology
    
    /// Neurological disorders illustrations
    public struct NeurologicalDisorders {
        public static let stroke = "brain.head.profile"
        public static let alzheimers = "brain.head.profile"
        public static let parkinsons = "brain.head.profile"
        public static let multipleSclerosis = "brain.head.profile"
        public static let epilepsy = "brain.head.profile"
        public static let huntingtons = "brain.head.profile"
        public static let amyotrophicLateral = "brain.head.profile"
        public static let guillainBarre = "line.diagonal"
        public static let bellPalsy = "face.dashed"
        public static let trigeminalNeuralgia = "face.dashed"
    }
    
    /// Brain injury illustrations
    public struct BrainInjury {
        public static let traumaticBrainInjury = "brain.head.profile"
        public static let concussion = "brain.head.profile"
        public static let contusion = "brain.head.profile"
        public static let hematoma = "drop.fill"
        public static let diffuseAxonal = "line.diagonal"
        public static let penetratingInjury = "brain.head.profile"
        public static let brainSwelling = "brain.head.profile"
        public static let intracranialPressure = "drop.fill"
        public static let brainHerniation = "brain.head.profile"
        public static let secondaryInjury = "brain.head.profile"
    }
    
    /// Nerve injury illustrations
    public struct NerveInjury {
        public static let nerveCompression = "line.diagonal"
        public static let nerveTransection = "line.diagonal"
        public static let nerveStretch = "line.diagonal"
        public static let carpalTunnel = "hand.raised.fill"
        public static let cubitalTunnel = "hand.raised.fill"
        public static let sciatica = "line.diagonal"
        public static let peripheralNeuropathy = "line.diagonal"
        public static let nerveRegeneration = "line.diagonal"
        public static let nerveDegeneration = "line.diagonal"
        public static let nerveEntrapment = "line.diagonal"
    }
    
    // MARK: - Neuroimaging
    
    /// Imaging techniques illustrations
    public struct Neuroimaging {
        public static let mri = "brain.head.profile"
        public static let ct = "rays"
        public static let pet = "rays"
        public static let spect = "rays"
        public static let eeg = "waveform.path.ecg"
        public static let emg = "waveform.path.ecg"
        public static let nerveConduction = "bolt.fill"
        public static let evokedPotentials = "waveform.path.ecg"
        public static let angiography = "rays"
        public static let ultrasound = "waveform"
    }
    
    /// Diagnostic procedures illustrations
    public struct DiagnosticProcedures {
        public static let lumbarPuncture = "syringe"
        public static let brainBiopsy = "scissors"
        public static let nerveBiopsy = "scissors"
        public static let muscleBiopsy = "scissors"
        public static let neuropsychological = "brain.head.profile"
        public static let neurologicalExam = "brain.head.profile"
        public static let reflexTesting = "hand.raised.fill"
        public static let coordinationTesting = "figure.walk"
        public static let balanceTesting = "figure.walk"
        public static let gaitAnalysis = "figure.walk"
    }
}

// MARK: - Nervous System Illustration Extensions
public extension NervousSystemIllustrations {
    
    /// Get illustration for nervous system structure
    static func illustrationForStructure(_ structure: NervousSystemStructure) -> String {
        switch structure {
        case .brain:
            return BrainAnatomy.cerebrum
        case .spinalCord:
            return SpinalCordAnatomy.cervicalCord
        case .peripheral:
            return CranialNerves.olfactory
        case .neurons:
            return NeuronAnatomy.cellBody
        case .pathways:
            return SensoryPathways.somatosensory
        case .function:
            return CognitiveFunction.memory
        }
    }
    
    /// Get illustration for nervous system function
    static func illustrationForFunction(_ function: NervousSystemFunction) -> String {
        switch function {
        case .sensory:
            return SensoryFunction.vision
        case .motor:
            return MotorFunction.voluntaryMovement
        case .cognitive:
            return CognitiveFunction.memory
        case .autonomic:
            return AutonomicNervousSystem.sympathetic
        case .integration:
            return BrainAnatomy.cerebrum
        case .regulation:
            return BrainAnatomy.hypothalamus
        }
    }
}

// MARK: - Supporting Enums
public enum NervousSystemStructure {
    case brain
    case spinalCord
    case peripheral
    case neurons
    case pathways
    case function
}

public enum NervousSystemFunction {
    case sensory
    case motor
    case cognitive
    case autonomic
    case integration
    case regulation
} 
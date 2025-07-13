import SwiftUI

// MARK: - Emergency Icons
/// Comprehensive emergency icons for HealthAI 2030
/// Provides emergency situations, first aid, emergency contacts, and critical health alerts
public struct EmergencyIcons {
    
    // MARK: - Emergency Situation Icons
    
    /// Medical emergency icons
    public struct MedicalEmergency {
        public static let cardiac = "heart.circle.fill"
        public static let respiratory = "lungs.fill"
        public static let stroke = "brain.head.profile"
        public static let seizure = "brain.head.profile"
        public static let bleeding = "drop.fill"
        public static let trauma = "exclamationmark.triangle.fill"
        public static let allergic = "exclamationmark.triangle.fill"
        public static let poisoning = "exclamationmark.triangle.fill"
        public static let overdose = "exclamationmark.triangle.fill"
        public static let unconscious = "person.fill"
    }
    
    /// Emergency severity icons
    public struct EmergencySeverity {
        public static let critical = "exclamationmark.triangle.fill"
        public static let urgent = "exclamationmark.triangle"
        public static let serious = "exclamationmark.triangle"
        public static let moderate = "exclamationmark.triangle"
        public static let minor = "exclamationmark.triangle"
        public static let stable = "checkmark.circle.fill"
        public static let improving = "arrow.up.circle.fill"
        public static let deteriorating = "arrow.down.circle.fill"
        public static let unknown = "questionmark.circle.fill"
        public static let monitoring = "eye.fill"
    }
    
    /// Emergency response icons
    public struct EmergencyResponse {
        public static let ambulance = "car.fill"
        public static let fire = "flame.fill"
        public static let police = "car.fill"
        public static let helicopter = "airplane"
        public static let emergency = "exclamationmark.triangle.fill"
        public static let rescue = "person.2.fill"
        public static let evacuation = "arrow.up.circle.fill"
        public static let shelter = "house.fill"
        public static let emergencyExit = "arrow.up.circle.fill"
        public static let emergencyRoute = "map.fill"
    }
    
    // MARK: - First Aid Icons
    
    /// First aid kit icons
    public struct FirstAidKit {
        public static let bandage = "rectangle.fill"
        public static let gauze = "rectangle.fill"
        public static let antiseptic = "drop.fill"
        public static let adhesive = "rectangle.fill"
        public static let scissors = "scissors"
        public static let tweezers = "scissors"
        public static let thermometer = "thermometer"
        public static let gloves = "hand.raised.fill"
        public static let mask = "face.dashed"
        public static let firstAid = "cross.fill"
    }
    
    /// First aid procedure icons
    public struct FirstAidProcedures {
        public static let cpr = "heart.circle.fill"
        public static let heimlich = "hand.raised.fill"
        public static let pressure = "hand.raised.fill"
        public static let elevation = "arrow.up.circle.fill"
        public static let ice = "thermometer.snowflake"
        public static let heat = "thermometer.sun.fill"
        public static let immobilization = "rectangle.fill"
        public static let splint = "rectangle.fill"
        public static let tourniquet = "line.diagonal"
        public static let wound = "drop.fill"
    }
    
    /// Injury type icons
    public struct Injuries {
        public static let cut = "scissors"
        public static let burn = "flame.fill"
        public static let fracture = "ruler.fill"
        public static let sprain = "hand.raised.fill"
        public static let dislocation = "hand.raised.fill"
        public static let concussion = "brain.head.profile"
        public static let puncture = "scissors"
        public static let abrasion = "hand.raised.fill"
        public static let laceration = "scissors"
        public static let bruise = "circle.fill"
    }
    
    // MARK: - Emergency Contact Icons
    
    /// Emergency contact icons
    public struct EmergencyContacts {
        public static let doctor = "person.fill"
        public static let nurse = "person.fill"
        public static let family = "person.3.fill"
        public static let friend = "person.2.fill"
        public static let neighbor = "person.2.fill"
        public static let coworker = "person.2.fill"
        public static let emergency = "phone.fill"
        public static let poison = "phone.fill"
        public static let mentalHealth = "phone.fill"
        public static let crisis = "phone.fill"
    }
    
    /// Communication icons
    public struct Communication {
        public static let phone = "phone.fill"
        public static let text = "message.fill"
        public static let email = "envelope.fill"
        public static let video = "video.fill"
        public static let voice = "mic.fill"
        public static let sos = "exclamationmark.triangle.fill"
        public static let alert = "bell.fill"
        public static let notification = "bell"
        public static let broadcast = "megaphone.fill"
        public static let emergency = "exclamationmark.triangle.fill"
    }
    
    /// Location and navigation icons
    public struct Location {
        public static let hospital = "building.2.fill"
        public static let clinic = "building.2.fill"
        public static let pharmacy = "building.2.fill"
        public static let emergency = "building.2.fill"
        public static let urgent = "building.2.fill"
        public static let trauma = "building.2.fill"
        public static let cardiac = "building.2.fill"
        public static let pediatric = "building.2.fill"
        public static let mentalHealth = "building.2.fill"
        public static let rehabilitation = "building.2.fill"
    }
    
    // MARK: - Health Alert Icons
    
    /// Health alert icons
    public struct HealthAlerts {
        public static let critical = "exclamationmark.triangle.fill"
        public static let warning = "exclamationmark.triangle"
        public static let caution = "exclamationmark.triangle"
        public static let info = "info.circle.fill"
        public static let notice = "bell.fill"
        public static let advisory = "megaphone.fill"
        public static let outbreak = "exclamationmark.triangle.fill"
        public static let contamination = "exclamationmark.triangle.fill"
        public static let recall = "exclamationmark.triangle.fill"
        public static let safety = "shield.fill"
    }
    
    /// Vital sign alert icons
    public struct VitalSignAlerts {
        public static let heartRate = "heart.circle.fill"
        public static let bloodPressure = "drop.fill"
        public static let temperature = "thermometer"
        public static let oxygen = "lungs.fill"
        public static let respiration = "lungs.fill"
        public static let glucose = "drop.fill"
        public static let pain = "exclamationmark.triangle.fill"
        public static let consciousness = "person.fill"
        public static let bleeding = "drop.fill"
        public static let seizure = "brain.head.profile"
    }
    
    /// Medication alert icons
    public struct MedicationAlerts {
        public static let allergy = "exclamationmark.triangle.fill"
        public static let interaction = "exclamationmark.triangle"
        public static let overdose = "exclamationmark.triangle.fill"
        public static let sideEffect = "exclamationmark.triangle"
        public static let missed = "clock"
        public static let expired = "calendar"
        public static let contraindication = "xmark.circle.fill"
        public static let pregnancy = "exclamationmark.triangle"
        public static let breastfeeding = "exclamationmark.triangle"
        public static let driving = "car.fill"
    }
    
    // MARK: - Emergency Services Icons
    
    /// Emergency service icons
    public struct EmergencyServices {
        public static let ambulance = "car.fill"
        public static let fire = "flame.fill"
        public static let police = "car.fill"
        public static let coast = "water.waves"
        public static let mountain = "mountain.2.fill"
        public static let air = "airplane"
        public static let search = "magnifyingglass"
        public static let rescue = "person.2.fill"
        public static let evacuation = "arrow.up.circle.fill"
        public static let emergency = "exclamationmark.triangle.fill"
    }
    
    /// Emergency equipment icons
    public struct EmergencyEquipment {
        public static let defibrillator = "bolt.fill"
        public static let ventilator = "lungs.fill"
        public static let monitor = "waveform.path.ecg"
        public static let oxygen = "lungs.fill"
        public static let stretcher = "rectangle.fill"
        public static let wheelchair = "figure.walk"
        public static let crutches = "figure.walk"
        public static let neckBrace = "rectangle.fill"
        public static let backboard = "rectangle.fill"
        public static let emergency = "exclamationmark.triangle.fill"
    }
    
    // MARK: - Disaster Icons
    
    /// Natural disaster icons
    public struct NaturalDisasters {
        public static let earthquake = "waveform.path.ecg"
        public static let hurricane = "wind"
        public static let tornado = "wind"
        public static let flood = "water.waves"
        public static let fire = "flame.fill"
        public static let landslide = "mountain.2.fill"
        public static let tsunami = "water.waves"
        public static let volcano = "mountain.2.fill"
        public static let blizzard = "thermometer.snowflake"
        public static let drought = "sun.max.fill"
    }
    
    /// Man-made disaster icons
    public struct ManMadeDisasters {
        public static let explosion = "flame.fill"
        public static let chemical = "exclamationmark.triangle.fill"
        public static let nuclear = "exclamationmark.triangle.fill"
        public static let biological = "exclamationmark.triangle.fill"
        public static let radiological = "exclamationmark.triangle.fill"
        public static let structural = "building.2.fill"
        public static let transportation = "car.fill"
        public static let power = "bolt.fill"
        public static let water = "drop.fill"
        public static let communication = "antenna.radiowaves.left.and.right"
    }
    
    // MARK: - Emergency Planning Icons
    
    /// Emergency planning icons
    public struct EmergencyPlanning {
        public static let plan = "doc.text.fill"
        public static let kit = "bag.fill"
        public static let supplies = "cube.box.fill"
        public static let route = "map.fill"
        public static let meeting = "person.3.fill"
        public static let drill = "exclamationmark.triangle"
        public static let training = "person.2.fill"
        public static let procedure = "list.bullet"
        public static let `protocol` = "doc.text"
        public static let emergency = "exclamationmark.triangle.fill"
    }
    
    /// Emergency preparedness icons
    public struct EmergencyPreparedness {
        public static let food = "fork.knife"
        public static let water = "drop.fill"
        public static let shelter = "house.fill"
        public static let clothing = "tshirt.fill"
        public static let medicine = "pills.fill"
        public static let documents = "doc.text.fill"
        public static let cash = "dollarsign.circle.fill"
        public static let battery = "battery.100"
        public static let radio = "antenna.radiowaves.left.and.right"
        public static let flashlight = "lightbulb.fill"
    }
}

// MARK: - Emergency Icon Extensions
public extension EmergencyIcons {
    
    /// Get icon for emergency type
    static func iconForEmergencyType(_ type: EmergencyType) -> String {
        switch type {
        case .medical:
            return MedicalEmergency.cardiac
        case .trauma:
            return MedicalEmergency.trauma
        case .environmental:
            return NaturalDisasters.earthquake
        case .chemical:
            return ManMadeDisasters.chemical
        case .fire:
            return NaturalDisasters.fire
        case .water:
            return NaturalDisasters.flood
        case .weather:
            return NaturalDisasters.hurricane
        case .structural:
            return ManMadeDisasters.structural
        case .transportation:
            return ManMadeDisasters.transportation
        case .utility:
            return ManMadeDisasters.power
        }
    }
    
    /// Get icon for emergency severity
    static func iconForSeverity(_ severity: EmergencySeverity) -> String {
        switch severity {
        case .critical:
            return EmergencySeverity.critical
        case .urgent:
            return EmergencySeverity.urgent
        case .serious:
            return EmergencySeverity.serious
        case .moderate:
            return EmergencySeverity.moderate
        case .minor:
            return EmergencySeverity.minor
        case .stable:
            return EmergencySeverity.stable
        case .improving:
            return EmergencySeverity.improving
        case .deteriorating:
            return EmergencySeverity.deteriorating
        case .unknown:
            return EmergencySeverity.unknown
        case .monitoring:
            return EmergencySeverity.monitoring
        }
    }
    
    /// Get icon for emergency service
    static func iconForService(_ service: EmergencyService) -> String {
        switch service {
        case .ambulance:
            return EmergencyServices.ambulance
        case .fire:
            return EmergencyServices.fire
        case .police:
            return EmergencyServices.police
        case .coast:
            return EmergencyServices.coast
        case .mountain:
            return EmergencyServices.mountain
        case .air:
            return EmergencyServices.air
        case .search:
            return EmergencyServices.search
        case .rescue:
            return EmergencyServices.rescue
        case .evacuation:
            return EmergencyServices.evacuation
        case .emergency:
            return EmergencyServices.emergency
        }
    }
}

// MARK: - Supporting Enums
public enum EmergencyType {
    case medical
    case trauma
    case environmental
    case chemical
    case fire
    case water
    case weather
    case structural
    case transportation
    case utility
}

public enum EmergencySeverity {
    case critical
    case urgent
    case serious
    case moderate
    case minor
    case stable
    case improving
    case deteriorating
    case unknown
    case monitoring
}

public enum EmergencyService {
    case ambulance
    case fire
    case police
    case coast
    case mountain
    case air
    case search
    case rescue
    case evacuation
    case emergency
} 
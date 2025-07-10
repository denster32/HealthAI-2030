import SwiftUI

// MARK: - Medication Icons
/// Comprehensive medication icons for HealthAI 2030
/// Provides different medication types, administration methods, and pharmaceutical categories
public struct MedicationIcons {
    
    // MARK: - Medication Form Icons
    
    /// Oral medication icons
    public struct Oral {
        public static let pill = "pills.fill"
        public static let capsule = "capsule.fill"
        public static let tablet = "pills.fill"
        public static let liquid = "drop.fill"
        public static let syrup = "drop.fill"
        public static let suspension = "drop.fill"
        public static let powder = "circle.fill"
        public static let chewable = "pills.fill"
        public static let sublingual = "pills.fill"
        public static let buccal = "pills.fill"
    }
    
    /// Injectable medication icons
    public struct Injectable {
        public static let syringe = "syringe"
        public static let injection = "syringe"
        public static let iv = "drop.fill"
        public static let im = "syringe"
        public static let sc = "syringe"
        public static let ivPump = "drop.fill"
        public static let ivBag = "drop.fill"
        public static let ivLine = "line.diagonal"
        public static let ivPort = "circle.fill"
        public static let ivCannula = "line.diagonal"
    }
    
    /// Topical medication icons
    public struct Topical {
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
    
    // MARK: - Medication Category Icons
    
    /// Antibiotic icons
    public struct Antibiotics {
        public static let penicillin = "pills.fill"
        public static let cephalosporin = "pills.fill"
        public static let macrolide = "pills.fill"
        public static let tetracycline = "pills.fill"
        public static let fluoroquinolone = "pills.fill"
        public static let aminoglycoside = "pills.fill"
        public static let sulfonamide = "pills.fill"
        public static let vancomycin = "drop.fill"
        public static let metronidazole = "pills.fill"
        public static let clindamycin = "pills.fill"
    }
    
    /// Pain medication icons
    public struct PainMedication {
        public static let acetaminophen = "pills.fill"
        public static let ibuprofen = "pills.fill"
        public static let aspirin = "pills.fill"
        public static let naproxen = "pills.fill"
        public static let morphine = "drop.fill"
        public static let codeine = "pills.fill"
        public static let oxycodone = "pills.fill"
        public static let hydrocodone = "pills.fill"
        public static let tramadol = "pills.fill"
        public static let fentanyl = "drop.fill"
    }
    
    /// Cardiovascular medication icons
    public struct Cardiovascular {
        public static let betaBlocker = "pills.fill"
        public static let aceInhibitor = "pills.fill"
        public static let calciumBlocker = "pills.fill"
        public static let diuretic = "pills.fill"
        public static let statin = "pills.fill"
        public static let anticoagulant = "pills.fill"
        public static let antiplatelet = "pills.fill"
        public static let digoxin = "pills.fill"
        public static let nitroglycerin = "pills.fill"
        public static let warfarin = "pills.fill"
    }
    
    /// Respiratory medication icons
    public struct Respiratory {
        public static let inhaler = "wind"
        public static let bronchodilator = "wind"
        public static let corticosteroid = "wind"
        public static let antihistamine = "pills.fill"
        public static let decongestant = "pills.fill"
        public static let expectorant = "pills.fill"
        public static let mucolytic = "pills.fill"
        public static let oxygen = "lungs.fill"
        public static let nebulizer = "wind"
        public static let spacer = "wind"
    }
    
    /// Gastrointestinal medication icons
    public struct Gastrointestinal {
        public static let antacid = "pills.fill"
        public static let protonPump = "pills.fill"
        public static let h2Blocker = "pills.fill"
        public static let antiemetic = "pills.fill"
        public static let antidiarrheal = "pills.fill"
        public static let laxative = "pills.fill"
        public static let prokinetic = "pills.fill"
        public static let antispasmodic = "pills.fill"
        public static let antiulcer = "pills.fill"
        public static let antiinflammatory = "pills.fill"
    }
    
    /// Endocrine medication icons
    public struct Endocrine {
        public static let insulin = "syringe"
        public static let metformin = "pills.fill"
        public static let sulfonylurea = "pills.fill"
        public static let thyroid = "pills.fill"
        public static let steroid = "pills.fill"
        public static let growth = "drop.fill"
        public static let parathyroid = "pills.fill"
        public static let adrenal = "pills.fill"
        public static let pituitary = "drop.fill"
        public static let gonadotropin = "drop.fill"
    }
    
    /// Psychiatric medication icons
    public struct Psychiatric {
        public static let antidepressant = "pills.fill"
        public static let antipsychotic = "pills.fill"
        public static let anxiolytic = "pills.fill"
        public static let moodStabilizer = "pills.fill"
        public static let stimulant = "pills.fill"
        public static let sedative = "pills.fill"
        public static let hypnotic = "pills.fill"
        public static let anticonvulsant = "pills.fill"
        public static let lithium = "pills.fill"
        public static let benzodiazepine = "pills.fill"
    }
    
    /// Immunosuppressant icons
    public struct Immunosuppressants {
        public static let prednisone = "pills.fill"
        public static let cyclosporine = "drop.fill"
        public static let tacrolimus = "drop.fill"
        public static let mycophenolate = "pills.fill"
        public static let azathioprine = "pills.fill"
        public static let methotrexate = "pills.fill"
        public static let rituximab = "drop.fill"
        public static let infliximab = "drop.fill"
        public static let adalimumab = "drop.fill"
        public static let etanercept = "drop.fill"
    }
    
    // MARK: - Medication Schedule Icons
    
    /// Dosing schedule icons
    public struct Schedule {
        public static let onceDaily = "1.circle.fill"
        public static let twiceDaily = "2.circle.fill"
        public static let threeTimes = "3.circle.fill"
        public static let fourTimes = "4.circle.fill"
        public static let asNeeded = "questionmark.circle.fill"
        public static let beforeMeals = "fork.knife"
        public static let afterMeals = "fork.knife"
        public static let withFood = "fork.knife"
        public static let emptyStomach = "circle.fill"
        public static let bedtime = "bed.double.fill"
    }
    
    /// Medication timing icons
    public struct Timing {
        public static let morning = "sunrise.fill"
        public static let noon = "sun.max.fill"
        public static let evening = "sunset.fill"
        public static let night = "moon.fill"
        public static let everyHour = "clock.fill"
        public static let everyTwoHours = "clock"
        public static let everyFourHours = "clock"
        public static let everySixHours = "clock"
        public static let everyEightHours = "clock"
        public static let everyTwelveHours = "clock"
    }
    
    // MARK: - Medication Safety Icons
    
    /// Safety and warning icons
    public struct Safety {
        public static let allergy = "exclamationmark.triangle.fill"
        public static let interaction = "exclamationmark.triangle"
        public static let contraindication = "xmark.circle.fill"
        public static let sideEffect = "exclamationmark.triangle"
        public static let overdose = "exclamationmark.triangle.fill"
        public static let pregnancy = "exclamationmark.triangle"
        public static let breastfeeding = "exclamationmark.triangle"
        public static let driving = "car.fill"
        public static let alcohol = "exclamationmark.triangle"
        public static let food = "fork.knife"
    }
    
    /// Storage and handling icons
    public struct Storage {
        public static let refrigerator = "thermometer.snowflake"
        public static let roomTemp = "thermometer"
        public static let dark = "moon.fill"
        public static let light = "sun.max.fill"
        public static let dry = "drop.slash.fill"
        public static let airtight = "seal.fill"
        public static let childproof = "lock.fill"
        public static let expiration = "calendar"
        public static let disposal = "trash.fill"
        public static let transport = "bag.fill"
    }
    
    // MARK: - Medication Administration Icons
    
    /// Administration method icons
    public struct Administration {
        public static let oral = "mouth.fill"
        public static let injection = "syringe"
        public static let topical = "hand.raised.fill"
        public static let inhaled = "lungs.fill"
        public static let rectal = "capsule.fill"
        public static let vaginal = "capsule.fill"
        public static let nasal = "nose.fill"
        public static let otic = "ear.fill"
        public static let ophthalmic = "eye.fill"
        public static let transdermal = "rectangle.fill"
    }
    
    /// Medication device icons
    public struct Devices {
        public static let pillBox = "pills.fill"
        public static let syringe = "syringe"
        public static let inhaler = "wind"
        public static let nebulizer = "wind"
        public static let patch = "rectangle.fill"
        public static let pump = "drop.fill"
        public static let pen = "syringe"
        public static let vial = "drop.fill"
        public static let ampule = "drop.fill"
        public static let bottle = "drop.fill"
    }
}

// MARK: - Medication Icon Extensions
public extension MedicationIcons {
    
    /// Get icon for medication form
    static func iconForForm(_ form: MedicationForm) -> String {
        switch form {
        case .oral:
            return Oral.pill
        case .injectable:
            return Injectable.syringe
        case .topical:
            return Topical.cream
        case .inhaled:
            return Topical.inhaler
        case .rectal:
            return Topical.suppository
        case .vaginal:
            return Topical.suppository
        case .nasal:
            return Topical.drops
        case .otic:
            return Topical.drops
        case .ophthalmic:
            return Topical.drops
        case .transdermal:
            return Topical.patch
        }
    }
    
    /// Get icon for medication category
    static func iconForCategory(_ category: MedicationCategory) -> String {
        switch category {
        case .antibiotic:
            return Antibiotics.penicillin
        case .pain:
            return PainMedication.acetaminophen
        case .cardiovascular:
            return Cardiovascular.betaBlocker
        case .respiratory:
            return Respiratory.inhaler
        case .gastrointestinal:
            return Gastrointestinal.antacid
        case .endocrine:
            return Endocrine.insulin
        case .psychiatric:
            return Psychiatric.antidepressant
        case .immunosuppressant:
            return Immunosuppressants.prednisone
        }
    }
    
    /// Get icon for administration method
    static func iconForAdministration(_ method: AdministrationMethod) -> String {
        switch method {
        case .oral:
            return Administration.oral
        case .injection:
            return Administration.injection
        case .topical:
            return Administration.topical
        case .inhaled:
            return Administration.inhaled
        case .rectal:
            return Administration.rectal
        case .vaginal:
            return Administration.vaginal
        case .nasal:
            return Administration.nasal
        case .otic:
            return Administration.otic
        case .ophthalmic:
            return Administration.ophthalmic
        case .transdermal:
            return Administration.transdermal
        }
    }
}

// MARK: - Supporting Enums
public enum MedicationForm {
    case oral
    case injectable
    case topical
    case inhaled
    case rectal
    case vaginal
    case nasal
    case otic
    case ophthalmic
    case transdermal
}

public enum MedicationCategory {
    case antibiotic
    case pain
    case cardiovascular
    case respiratory
    case gastrointestinal
    case endocrine
    case psychiatric
    case immunosuppressant
}

public enum AdministrationMethod {
    case oral
    case injection
    case topical
    case inhaled
    case rectal
    case vaginal
    case nasal
    case otic
    case ophthalmic
    case transdermal
} 
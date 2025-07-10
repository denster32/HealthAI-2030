import SwiftUI

// MARK: - Medication Administration Illustrations
/// Comprehensive medication administration illustrations for safe medication practices
/// Provides detailed visual guides for various medication administration routes and procedures
public struct MedicationAdministrationIllustrations {
    
    // MARK: - Oral Medication Administration
    
    /// Oral medication administration illustration
    public struct OralMedicationIllustration: View {
        let medicationType: OralMedicationType
        let dosageForm: DosageForm
        @State private var showingSteps: Bool = false
        @State private var currentStep: Int = 0
        
        public init(
            medicationType: OralMedicationType = .tablet,
            dosageForm: DosageForm = .solid
        ) {
            self.medicationType = medicationType
            self.dosageForm = dosageForm
        }
        
        public var body: some View {
            VStack(spacing: 20) {
                // Medication Title
                Text("Oral \(medicationType.displayName) Administration")
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                // Dosage Form Selector
                Picker("Dosage Form", selection: .constant(dosageForm)) {
                    ForEach(DosageForm.allCases, id: \.self) { form in
                        Text(form.displayName).tag(form)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                
                // Administration Illustration
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemGray6))
                        .frame(height: 300)
                    
                    OralAdministrationView(
                        medicationType: medicationType,
                        dosageForm: dosageForm,
                        currentStep: currentStep
                    )
                    .frame(height: 280)
                }
                
                // Step Controls
                VStack(spacing: 12) {
                    HStack(spacing: 20) {
                        Button(action: { 
                            if currentStep > 0 {
                                currentStep -= 1
                            }
                        }) {
                            Image(systemName: "backward.fill")
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(8)
                        }
                        .disabled(currentStep == 0)
                        
                        Text("Step \(currentStep + 1) of \(oralAdministrationSteps.count)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Button(action: { 
                            if currentStep < oralAdministrationSteps.count - 1 {
                                currentStep += 1
                            }
                        }) {
                            Image(systemName: "forward.fill")
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(8)
                        }
                        .disabled(currentStep == oralAdministrationSteps.count - 1)
                    }
                    
                    // Step Instructions
                    if currentStep < oralAdministrationSteps.count {
                        Text(oralAdministrationSteps[currentStep])
                            .font(.subheadline)
                            .multilineTextAlignment(.center)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                }
                
                // Safety Information
                OralMedicationSafetyView(medicationType: medicationType)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        }
        
        private var oralAdministrationSteps: [String] {
            [
                "Wash hands thoroughly with soap and water",
                "Check medication label and expiration date",
                "Verify correct dosage and timing",
                "Take medication with appropriate amount of water",
                "Record administration time and any side effects"
            ]
        }
    }
    
    // MARK: - Injectable Medication Administration
    
    /// Injectable medication administration illustration
    public struct InjectableMedicationIllustration: View {
        let injectionType: InjectionType
        let bodySite: InjectionSite
        @State private var showingTechnique: Bool = false
        @State private var currentPhase: InjectionPhase = .preparation
        
        public init(
            injectionType: InjectionType = .subcutaneous,
            bodySite: InjectionSite = .abdomen
        ) {
            self.injectionType = injectionType
            self.bodySite = bodySite
        }
        
        public var body: some View {
            VStack(spacing: 20) {
                // Injection Title
                Text("\(injectionType.displayName) Injection - \(bodySite.displayName)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                // Body Site Selector
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(InjectionSite.allCases, id: \.self) { site in
                            InjectionSiteButton(
                                site: site,
                                isSelected: bodySite == site,
                                action: { /* Update body site */ }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Injection Illustration
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemGray6))
                        .frame(height: 300)
                    
                    InjectableAdministrationView(
                        injectionType: injectionType,
                        bodySite: bodySite,
                        currentPhase: currentPhase
                    )
                    .frame(height: 280)
                }
                
                // Phase Controls
                VStack(spacing: 12) {
                    HStack(spacing: 20) {
                        Button(action: { 
                            if let previousPhase = currentPhase.previous {
                                currentPhase = previousPhase
                            }
                        }) {
                            Image(systemName: "backward.fill")
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(8)
                        }
                        .disabled(currentPhase.previous == nil)
                        
                        Text(currentPhase.displayName)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Button(action: { 
                            if let nextPhase = currentPhase.next {
                                currentPhase = nextPhase
                            }
                        }) {
                            Image(systemName: "forward.fill")
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(8)
                        }
                        .disabled(currentPhase.next == nil)
                    }
                    
                    // Phase Instructions
                    Text(currentPhase.instructions)
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }
                
                // Safety Information
                InjectableSafetyView(injectionType: injectionType)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        }
    }
    
    // MARK: - Topical Medication Administration
    
    /// Topical medication administration illustration
    public struct TopicalMedicationIllustration: View {
        let topicalType: TopicalMedicationType
        let applicationArea: ApplicationArea
        @State private var showingTechnique: Bool = false
        @State private var currentStep: Int = 0
        
        public init(
            topicalType: TopicalMedicationType = .cream,
            applicationArea: ApplicationArea = .skin
        ) {
            self.topicalType = topicalType
            self.applicationArea = applicationArea
        }
        
        public var body: some View {
            VStack(spacing: 20) {
                // Topical Title
                Text("\(topicalType.displayName) Application - \(applicationArea.displayName)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                // Application Area Selector
                Picker("Application Area", selection: .constant(applicationArea)) {
                    ForEach(ApplicationArea.allCases, id: \.self) { area in
                        Text(area.displayName).tag(area)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                
                // Application Illustration
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemGray6))
                        .frame(height: 300)
                    
                    TopicalApplicationView(
                        topicalType: topicalType,
                        applicationArea: applicationArea,
                        currentStep: currentStep
                    )
                    .frame(height: 280)
                }
                
                // Step Controls
                VStack(spacing: 12) {
                    HStack(spacing: 20) {
                        Button(action: { 
                            if currentStep > 0 {
                                currentStep -= 1
                            }
                        }) {
                            Image(systemName: "backward.fill")
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(8)
                        }
                        .disabled(currentStep == 0)
                        
                        Text("Step \(currentStep + 1) of \(topicalApplicationSteps.count)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Button(action: { 
                            if currentStep < topicalApplicationSteps.count - 1 {
                                currentStep += 1
                            }
                        }) {
                            Image(systemName: "forward.fill")
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(8)
                        }
                        .disabled(currentStep == topicalApplicationSteps.count - 1)
                    }
                    
                    // Step Instructions
                    if currentStep < topicalApplicationSteps.count {
                        Text(topicalApplicationSteps[currentStep])
                            .font(.subheadline)
                            .multilineTextAlignment(.center)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                }
                
                // Safety Information
                TopicalSafetyView(topicalType: topicalType)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        }
        
        private var topicalApplicationSteps: [String] {
            [
                "Clean and dry the application area thoroughly",
                "Check medication label and expiration date",
                "Apply appropriate amount as directed",
                "Gently massage into the skin if required",
                "Wash hands after application"
            ]
        }
    }
    
    // MARK: - Inhalation Medication Administration
    
    /// Inhalation medication administration illustration
    public struct InhalationMedicationIllustration: View {
        let inhalerType: InhalerType
        let medicationType: InhalationMedicationType
        @State private var showingTechnique: Bool = false
        @State private var currentStep: Int = 0
        
        public init(
            inhalerType: InhalerType = .meteredDose,
            medicationType: InhalationMedicationType = .bronchodilator
        ) {
            self.inhalerType = inhalerType
            self.medicationType = medicationType
        }
        
        public var body: some View {
            VStack(spacing: 20) {
                // Inhalation Title
                Text("\(inhalerType.displayName) - \(medicationType.displayName)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                // Inhaler Type Selector
                Picker("Inhaler Type", selection: .constant(inhalerType)) {
                    ForEach(InhalerType.allCases, id: \.self) { type in
                        Text(type.displayName).tag(type)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                
                // Inhalation Illustration
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemGray6))
                        .frame(height: 300)
                    
                    InhalationAdministrationView(
                        inhalerType: inhalerType,
                        medicationType: medicationType,
                        currentStep: currentStep
                    )
                    .frame(height: 280)
                }
                
                // Step Controls
                VStack(spacing: 12) {
                    HStack(spacing: 20) {
                        Button(action: { 
                            if currentStep > 0 {
                                currentStep -= 1
                            }
                        }) {
                            Image(systemName: "backward.fill")
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(8)
                        }
                        .disabled(currentStep == 0)
                        
                        Text("Step \(currentStep + 1) of \(inhalationSteps.count)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Button(action: { 
                            if currentStep < inhalationSteps.count - 1 {
                                currentStep += 1
                            }
                        }) {
                            Image(systemName: "forward.fill")
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(8)
                        }
                        .disabled(currentStep == inhalationSteps.count - 1)
                    }
                    
                    // Step Instructions
                    if currentStep < inhalationSteps.count {
                        Text(inhalationSteps[currentStep])
                            .font(.subheadline)
                            .multilineTextAlignment(.center)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                }
                
                // Safety Information
                InhalationSafetyView(inhalerType: inhalerType)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        }
        
        private var inhalationSteps: [String] {
            [
                "Shake inhaler well before use",
                "Exhale completely",
                "Place mouthpiece in mouth and seal lips",
                "Press down and inhale slowly and deeply",
                "Hold breath for 10 seconds, then exhale slowly"
            ]
        }
    }
}

// MARK: - Supporting Views

struct OralAdministrationView: View {
    let medicationType: OralMedicationType
    let dosageForm: DosageForm
    let currentStep: Int
    
    var body: some View {
        VStack(spacing: 16) {
            // Medication visualization
            HStack(spacing: 20) {
                // Medication representation
                VStack {
                    Image(systemName: medicationIcon)
                        .font(.system(size: 40))
                        .foregroundColor(.blue)
                    
                    Text(medicationType.displayName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Administration process
                VStack {
                    Image(systemName: "hand.raised.fill")
                        .font(.system(size: 30))
                        .foregroundColor(.green)
                    
                    Text("Administration")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Water glass
                VStack {
                    Image(systemName: "drop.fill")
                        .font(.system(size: 30))
                        .foregroundColor(.blue)
                    
                    Text("Water")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Step indicator
            HStack(spacing: 8) {
                ForEach(0..<5, id: \.self) { step in
                    Circle()
                        .fill(step <= currentStep ? Color.blue : Color.gray)
                        .frame(width: 12, height: 12)
                }
            }
        }
    }
    
    private var medicationIcon: String {
        switch medicationType {
        case .tablet: return "pill.fill"
        case .capsule: return "capsule.fill"
        case .liquid: return "drop.fill"
        case .powder: return "circle.fill"
        }
    }
}

struct InjectableAdministrationView: View {
    let injectionType: InjectionType
    let bodySite: InjectionSite
    let currentPhase: InjectionPhase
    
    var body: some View {
        VStack(spacing: 16) {
            // Body outline with injection site
            ZStack {
                // Body outline
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray5))
                    .frame(width: 120, height: 200)
                
                // Injection site indicator
                Circle()
                    .fill(Color.red)
                    .frame(width: 20, height: 20)
                    .position(injectionSitePosition)
            }
            
            // Injection equipment
            HStack(spacing: 20) {
                VStack {
                    Image(systemName: "syringe")
                        .font(.system(size: 30))
                        .foregroundColor(.blue)
                    
                    Text("Syringe")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack {
                    Image(systemName: "bandage")
                        .font(.system(size: 30))
                        .foregroundColor(.orange)
                    
                    Text("Bandage")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Phase indicator
            Text(currentPhase.displayName)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.blue)
        }
    }
    
    private var injectionSitePosition: CGPoint {
        switch bodySite {
        case .abdomen: return CGPoint(x: 60, y: 100)
        case .thigh: return CGPoint(x: 60, y: 150)
        case .arm: return CGPoint(x: 30, y: 80)
        case .buttock: return CGPoint(x: 60, y: 180)
        }
    }
}

struct TopicalApplicationView: View {
    let topicalType: TopicalMedicationType
    let applicationArea: ApplicationArea
    let currentStep: Int
    
    var body: some View {
        VStack(spacing: 16) {
            // Application area visualization
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray5))
                    .frame(width: 150, height: 100)
                
                // Application area indicator
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.blue.opacity(0.3))
                    .frame(width: 100, height: 60)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.blue, lineWidth: 2)
                    )
            }
            
            // Application tools
            HStack(spacing: 20) {
                VStack {
                    Image(systemName: "hand.raised.fill")
                        .font(.system(size: 30))
                        .foregroundColor(.green)
                    
                    Text("Hand")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack {
                    Image(systemName: "drop.fill")
                        .font(.system(size: 30))
                        .foregroundColor(.blue)
                    
                    Text(topicalType.displayName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Step indicator
            HStack(spacing: 8) {
                ForEach(0..<5, id: \.self) { step in
                    Circle()
                        .fill(step <= currentStep ? Color.blue : Color.gray)
                        .frame(width: 12, height: 12)
                }
            }
        }
    }
}

struct InhalationAdministrationView: View {
    let inhalerType: InhalerType
    let medicationType: InhalationMedicationType
    let currentStep: Int
    
    var body: some View {
        VStack(spacing: 16) {
            // Inhaler visualization
            HStack(spacing: 30) {
                // Inhaler device
                VStack {
                    Image(systemName: "lungs.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.blue)
                    
                    Text(inhalerType.displayName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Inhalation process
                VStack {
                    Image(systemName: "wind")
                        .font(.system(size: 40))
                        .foregroundColor(.green)
                    
                    Text("Inhalation")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Breathing indicator
            HStack(spacing: 20) {
                VStack {
                    Image(systemName: "lungs")
                        .font(.system(size: 30))
                        .foregroundColor(.blue)
                    
                    Text("Inhale")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack {
                    Image(systemName: "lungs.fill")
                        .font(.system(size: 30))
                        .foregroundColor(.green)
                    
                    Text("Hold")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack {
                    Image(systemName: "lungs")
                        .font(.system(size: 30))
                        .foregroundColor(.orange)
                    
                    Text("Exhale")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Step indicator
            HStack(spacing: 8) {
                ForEach(0..<5, id: \.self) { step in
                    Circle()
                        .fill(step <= currentStep ? Color.blue : Color.gray)
                        .frame(width: 12, height: 12)
                }
            }
        }
    }
}

// MARK: - Safety Information Views

struct OralMedicationSafetyView: View {
    let medicationType: OralMedicationType
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Safety Information")
                .font(.headline)
                .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("• Take with food if directed")
                Text("• Do not crush or break unless instructed")
                Text("• Store in a cool, dry place")
                Text("• Keep out of reach of children")
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

struct InjectableSafetyView: View {
    let injectionType: InjectionType
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Safety Information")
                .font(.headline)
                .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("• Use sterile technique")
                Text("• Rotate injection sites")
                Text("• Dispose of needles safely")
                Text("• Monitor for adverse reactions")
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

struct TopicalSafetyView: View {
    let topicalType: TopicalMedicationType
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Safety Information")
                .font(.headline)
                .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("• Apply to clean, dry skin")
                Text("• Avoid contact with eyes and mouth")
                Text("• Wash hands after application")
                Text("• Do not cover unless directed")
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

struct InhalationSafetyView: View {
    let inhalerType: InhalerType
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Safety Information")
                .font(.headline)
                .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("• Rinse mouth after use")
                Text("• Clean inhaler regularly")
                Text("• Check expiration date")
                Text("• Keep track of doses used")
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

// MARK: - Supporting Types

enum OralMedicationType: String, CaseIterable {
    case tablet = "tablet"
    case capsule = "capsule"
    case liquid = "liquid"
    case powder = "powder"
    
    var displayName: String {
        switch self {
        case .tablet: return "Tablet"
        case .capsule: return "Capsule"
        case .liquid: return "Liquid"
        case .powder: return "Powder"
        }
    }
}

enum DosageForm: String, CaseIterable {
    case solid = "solid"
    case liquid = "liquid"
    case powder = "powder"
    
    var displayName: String {
        switch self {
        case .solid: return "Solid"
        case .liquid: return "Liquid"
        case .powder: return "Powder"
        }
    }
}

enum InjectionType: String, CaseIterable {
    case subcutaneous = "subcutaneous"
    case intramuscular = "intramuscular"
    case intravenous = "intravenous"
    case intradermal = "intradermal"
    
    var displayName: String {
        switch self {
        case .subcutaneous: return "Subcutaneous"
        case .intramuscular: return "Intramuscular"
        case .intravenous: return "Intravenous"
        case .intradermal: return "Intradermal"
        }
    }
}

enum InjectionSite: String, CaseIterable {
    case abdomen = "abdomen"
    case thigh = "thigh"
    case arm = "arm"
    case buttock = "buttock"
    
    var displayName: String {
        switch self {
        case .abdomen: return "Abdomen"
        case .thigh: return "Thigh"
        case .arm: return "Arm"
        case .buttock: return "Buttock"
        }
    }
}

enum InjectionPhase: String, CaseIterable {
    case preparation = "preparation"
    case siteSelection = "siteSelection"
    case cleaning = "cleaning"
    case injection = "injection"
    case disposal = "disposal"
    
    var displayName: String {
        switch self {
        case .preparation: return "Preparation"
        case .siteSelection: return "Site Selection"
        case .cleaning: return "Cleaning"
        case .injection: return "Injection"
        case .disposal: return "Disposal"
        }
    }
    
    var instructions: String {
        switch self {
        case .preparation: return "Gather all necessary supplies and verify medication"
        case .siteSelection: return "Select appropriate injection site and mark if needed"
        case .cleaning: return "Clean injection site with alcohol swab"
        case .injection: return "Administer injection using proper technique"
        case .disposal: return "Safely dispose of used needle and syringe"
        }
    }
    
    var previous: InjectionPhase? {
        switch self {
        case .preparation: return nil
        case .siteSelection: return .preparation
        case .cleaning: return .siteSelection
        case .injection: return .cleaning
        case .disposal: return .injection
        }
    }
    
    var next: InjectionPhase? {
        switch self {
        case .preparation: return .siteSelection
        case .siteSelection: return .cleaning
        case .cleaning: return .injection
        case .injection: return .disposal
        case .disposal: return nil
        }
    }
}

enum TopicalMedicationType: String, CaseIterable {
    case cream = "cream"
    case ointment = "ointment"
    case gel = "gel"
    case lotion = "lotion"
    
    var displayName: String {
        switch self {
        case .cream: return "Cream"
        case .ointment: return "Ointment"
        case .gel: return "Gel"
        case .lotion: return "Lotion"
        }
    }
}

enum ApplicationArea: String, CaseIterable {
    case skin = "skin"
    case scalp = "scalp"
    case nails = "nails"
    case eyes = "eyes"
    
    var displayName: String {
        switch self {
        case .skin: return "Skin"
        case .scalp: return "Scalp"
        case .nails: return "Nails"
        case .eyes: return "Eyes"
        }
    }
}

enum InhalerType: String, CaseIterable {
    case meteredDose = "meteredDose"
    case dryPowder = "dryPowder"
    case softMist = "softMist"
    case nebulizer = "nebulizer"
    
    var displayName: String {
        switch self {
        case .meteredDose: return "Metered Dose"
        case .dryPowder: return "Dry Powder"
        case .softMist: return "Soft Mist"
        case .nebulizer: return "Nebulizer"
        }
    }
}

enum InhalationMedicationType: String, CaseIterable {
    case bronchodilator = "bronchodilator"
    case corticosteroid = "corticosteroid"
    case combination = "combination"
    case rescue = "rescue"
    
    var displayName: String {
        switch self {
        case .bronchodilator: return "Bronchodilator"
        case .corticosteroid: return "Corticosteroid"
        case .combination: return "Combination"
        case .rescue: return "Rescue"
        }
    }
}

struct InjectionSiteButton: View {
    let site: InjectionSite
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(site.displayName)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : .blue)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.blue : Color.blue.opacity(0.1))
                .cornerRadius(8)
        }
    }
} 
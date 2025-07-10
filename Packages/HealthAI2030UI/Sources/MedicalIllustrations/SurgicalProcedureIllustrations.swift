import SwiftUI

// MARK: - Surgical Procedure Illustrations
/// Comprehensive surgical procedure illustrations for health education and medical guidance
/// Provides detailed visual guides for various surgical procedures and medical interventions
public struct SurgicalProcedureIllustrations {
    
    // MARK: - Cardiac Surgery Illustrations
    
    /// Heart surgery procedure illustration
    public struct HeartSurgeryIllustration: View {
        let procedureType: HeartSurgeryType
        let isAnimated: Bool
        @State private var animationPhase: AnimationPhase = .preparation
        
        public init(
            procedureType: HeartSurgeryType = .bypass,
            isAnimated: Bool = false
        ) {
            self.procedureType = procedureType
            self.isAnimated = isAnimated
        }
        
        public var body: some View {
            VStack(spacing: 20) {
                // Procedure Title
                Text(procedureType.title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                // Heart Illustration
                ZStack {
                    // Background
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemGray6))
                        .frame(height: 300)
                    
                    // Heart Anatomy
                    HeartAnatomyView(
                        procedureType: procedureType,
                        animationPhase: animationPhase
                    )
                    .frame(height: 280)
                }
                
                // Procedure Steps
                ProcedureStepsView(
                    steps: procedureType.steps,
                    currentStep: animationPhase
                )
                
                // Controls
                if isAnimated {
                    AnimationControlsView(
                        currentPhase: $animationPhase,
                        totalPhases: procedureType.steps.count
                    )
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        }
    }
    
    // MARK: - Orthopedic Surgery Illustrations
    
    /// Joint replacement surgery illustration
    public struct JointReplacementIllustration: View {
        let jointType: JointType
        let replacementType: ReplacementType
        @State private var showingBeforeAfter: Bool = false
        
        public init(
            jointType: JointType = .hip,
            replacementType: ReplacementType = .total
        ) {
            self.jointType = jointType
            self.replacementType = replacementType
        }
        
        public var body: some View {
            VStack(spacing: 20) {
                // Procedure Title
                Text("\(jointType.displayName) \(replacementType.displayName) Replacement")
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                // Before/After Toggle
                Picker("View", selection: $showingBeforeAfter) {
                    Text("Before").tag(false)
                    Text("After").tag(true)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                
                // Joint Illustration
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemGray6))
                        .frame(height: 300)
                    
                    JointIllustrationView(
                        jointType: jointType,
                        replacementType: replacementType,
                        isAfter: showingBeforeAfter
                    )
                    .frame(height: 280)
                }
                
                // Procedure Details
                JointReplacementDetailsView(
                    jointType: jointType,
                    replacementType: replacementType
                )
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        }
    }
    
    // MARK: - Neurosurgery Illustrations
    
    /// Brain surgery procedure illustration
    public struct BrainSurgeryIllustration: View {
        let procedureType: BrainSurgeryType
        @State private var showingCrossSection: Bool = false
        
        public init(procedureType: BrainSurgeryType = .tumorRemoval) {
            self.procedureType = procedureType
        }
        
        public var body: some View {
            VStack(spacing: 20) {
                // Procedure Title
                Text(procedureType.title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                // View Toggle
                Picker("View", selection: $showingCrossSection) {
                    Text("External").tag(false)
                    Text("Cross Section").tag(true)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                
                // Brain Illustration
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemGray6))
                        .frame(height: 300)
                    
                    BrainIllustrationView(
                        procedureType: procedureType,
                        showingCrossSection: showingCrossSection
                    )
                    .frame(height: 280)
                }
                
                // Procedure Information
                BrainSurgeryInfoView(procedureType: procedureType)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        }
    }
    
    // MARK: - General Surgery Illustrations
    
    /// Appendectomy procedure illustration
    public struct AppendectomyIllustration: View {
        @State private var animationPhase: AppendectomyPhase = .normal
        
        public var body: some View {
            VStack(spacing: 20) {
                // Procedure Title
                Text("Appendectomy")
                    .font(.title2)
                    .fontWeight(.bold)
                
                // Abdomen Illustration
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemGray6))
                        .frame(height: 300)
                    
                    AbdomenIllustrationView(phase: animationPhase)
                        .frame(height: 280)
                }
                
                // Phase Controls
                Picker("Phase", selection: $animationPhase) {
                    ForEach(AppendectomyPhase.allCases, id: \.self) { phase in
                        Text(phase.displayName).tag(phase)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                
                // Procedure Details
                AppendectomyDetailsView(phase: animationPhase)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        }
    }
    
    // MARK: - Laparoscopic Surgery Illustrations
    
    /// Laparoscopic procedure illustration
    public struct LaparoscopicIllustration: View {
        let procedureType: LaparoscopicType
        @State private var showingInstruments: Bool = false
        
        public init(procedureType: LaparoscopicType = .gallbladder) {
            self.procedureType = procedureType
        }
        
        public var body: some View {
            VStack(spacing: 20) {
                // Procedure Title
                Text("Laparoscopic \(procedureType.displayName)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                // Instrument Toggle
                Toggle("Show Instruments", isOn: $showingInstruments)
                    .padding(.horizontal)
                
                // Procedure Illustration
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemGray6))
                        .frame(height: 300)
                    
                    LaparoscopicProcedureView(
                        procedureType: procedureType,
                        showingInstruments: showingInstruments
                    )
                    .frame(height: 280)
                }
                
                // Procedure Information
                LaparoscopicInfoView(procedureType: procedureType)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        }
    }
}

// MARK: - Supporting Views

struct HeartAnatomyView: View {
    let procedureType: HeartSurgeryType
    let animationPhase: AnimationPhase
    
    var body: some View {
        ZStack {
            // Heart outline
            HeartShape()
                .stroke(Color.red, lineWidth: 3)
                .frame(width: 200, height: 200)
            
            // Procedure-specific elements
            switch procedureType {
            case .bypass:
                BypassGraftView(phase: animationPhase)
            case .valve:
                ValveReplacementView(phase: animationPhase)
            case .pacemaker:
                PacemakerImplantView(phase: animationPhase)
            case .stent:
                StentPlacementView(phase: animationPhase)
            }
        }
    }
}

struct HeartShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        
        path.move(to: CGPoint(x: width * 0.5, y: height * 0.2))
        path.addCurve(
            to: CGPoint(x: width * 0.2, y: height * 0.4),
            control1: CGPoint(x: width * 0.3, y: height * 0.1),
            control2: CGPoint(x: width * 0.1, y: height * 0.3)
        )
        path.addCurve(
            to: CGPoint(x: width * 0.5, y: height * 0.8),
            control1: CGPoint(x: width * 0.1, y: height * 0.6),
            control2: CGPoint(x: width * 0.3, y: height * 0.8)
        )
        path.addCurve(
            to: CGPoint(x: width * 0.8, y: height * 0.4),
            control1: CGPoint(x: width * 0.7, y: height * 0.8),
            control2: CGPoint(x: width * 0.9, y: height * 0.6)
        )
        path.addCurve(
            to: CGPoint(x: width * 0.5, y: height * 0.2),
            control1: CGPoint(x: width * 0.9, y: height * 0.3),
            control2: CGPoint(x: width * 0.7, y: height * 0.1)
        )
        
        return path
    }
}

struct BypassGraftView: View {
    let phase: AnimationPhase
    
    var body: some View {
        // Bypass graft visualization
        Path { path in
            path.move(to: CGPoint(x: 100, y: 150))
            path.addLine(to: CGPoint(x: 150, y: 100))
        }
        .stroke(Color.blue, lineWidth: 4)
        .opacity(phase.rawValue >= 2 ? 1.0 : 0.0)
    }
}

struct ValveReplacementView: View {
    let phase: AnimationPhase
    
    var body: some View {
        // Valve replacement visualization
        Circle()
            .fill(Color.green)
            .frame(width: 30, height: 30)
            .position(x: 150, y: 120)
            .opacity(phase.rawValue >= 2 ? 1.0 : 0.0)
    }
}

struct PacemakerImplantView: View {
    let phase: AnimationPhase
    
    var body: some View {
        // Pacemaker visualization
        RoundedRectangle(cornerRadius: 8)
            .fill(Color.gray)
            .frame(width: 40, height: 25)
            .position(x: 180, y: 200)
            .opacity(phase.rawValue >= 2 ? 1.0 : 0.0)
    }
}

struct StentPlacementView: View {
    let phase: AnimationPhase
    
    var body: some View {
        // Stent visualization
        Capsule()
            .fill(Color.yellow)
            .frame(width: 60, height: 8)
            .position(x: 150, y: 140)
            .opacity(phase.rawValue >= 2 ? 1.0 : 0.0)
    }
}

struct ProcedureStepsView: View {
    let steps: [String]
    let currentStep: AnimationPhase
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Procedure Steps")
                .font(.headline)
                .fontWeight(.semibold)
            
            ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                HStack {
                    Circle()
                        .fill(index <= currentStep.rawValue ? Color.blue : Color.gray)
                        .frame(width: 20, height: 20)
                        .overlay(
                            Text("\(index + 1)")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        )
                    
                    Text(step)
                        .font(.subheadline)
                        .foregroundColor(index <= currentStep.rawValue ? .primary : .secondary)
                    
                    Spacer()
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct AnimationControlsView: View {
    @Binding var currentPhase: AnimationPhase
    let totalPhases: Int
    
    var body: some View {
        HStack(spacing: 20) {
            Button(action: { 
                if currentPhase.rawValue > 0 {
                    currentPhase = AnimationPhase(rawValue: currentPhase.rawValue - 1) ?? .preparation
                }
            }) {
                Image(systemName: "backward.fill")
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(8)
            }
            .disabled(currentPhase.rawValue == 0)
            
            Text("Step \(currentPhase.rawValue + 1) of \(totalPhases)")
                .font(.subheadline)
                .fontWeight(.medium)
            
            Button(action: { 
                if currentPhase.rawValue < totalPhases - 1 {
                    currentPhase = AnimationPhase(rawValue: currentPhase.rawValue + 1) ?? .completion
                }
            }) {
                Image(systemName: "forward.fill")
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(8)
            }
            .disabled(currentPhase.rawValue == totalPhases - 1)
        }
    }
}

struct JointIllustrationView: View {
    let jointType: JointType
    let replacementType: ReplacementType
    let isAfter: Bool
    
    var body: some View {
        ZStack {
            // Joint anatomy
            switch jointType {
            case .hip:
                HipJointView(replacementType: replacementType, isAfter: isAfter)
            case .knee:
                KneeJointView(replacementType: replacementType, isAfter: isAfter)
            case .shoulder:
                ShoulderJointView(replacementType: replacementType, isAfter: isAfter)
            case .elbow:
                ElbowJointView(replacementType: replacementType, isAfter: isAfter)
            }
        }
    }
}

struct HipJointView: View {
    let replacementType: ReplacementType
    let isAfter: Bool
    
    var body: some View {
        VStack(spacing: 10) {
            // Pelvis
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.brown)
                .frame(width: 120, height: 20)
            
            // Femur
            RoundedRectangle(cornerRadius: 8)
                .fill(isAfter ? Color.gray : Color.brown)
                .frame(width: 20, height: 80)
            
            // Joint replacement
            if isAfter {
                Circle()
                    .fill(Color.gray)
                    .frame(width: 40, height: 40)
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 2)
                    )
            }
        }
    }
}

struct KneeJointView: View {
    let replacementType: ReplacementType
    let isAfter: Bool
    
    var body: some View {
        VStack(spacing: 5) {
            // Femur
            RoundedRectangle(cornerRadius: 8)
                .fill(isAfter ? Color.gray : Color.brown)
                .frame(width: 30, height: 40)
            
            // Joint replacement
            if isAfter {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray)
                    .frame(width: 50, height: 15)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(Color.white, lineWidth: 1)
                    )
            }
            
            // Tibia
            RoundedRectangle(cornerRadius: 8)
                .fill(isAfter ? Color.gray : Color.brown)
                .frame(width: 25, height: 50)
        }
    }
}

struct ShoulderJointView: View {
    let replacementType: ReplacementType
    let isAfter: Bool
    
    var body: some View {
        HStack(spacing: 10) {
            // Scapula
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.brown)
                .frame(width: 60, height: 40)
            
            // Joint replacement
            if isAfter {
                Circle()
                    .fill(Color.gray)
                    .frame(width: 30, height: 30)
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 2)
                    )
            }
            
            // Humerus
            RoundedRectangle(cornerRadius: 8)
                .fill(isAfter ? Color.gray : Color.brown)
                .frame(width: 15, height: 60)
        }
    }
}

struct ElbowJointView: View {
    let replacementType: ReplacementType
    let isAfter: Bool
    
    var body: some View {
        HStack(spacing: 5) {
            // Humerus
            RoundedRectangle(cornerRadius: 8)
                .fill(isAfter ? Color.gray : Color.brown)
                .frame(width: 20, height: 50)
            
            // Joint replacement
            if isAfter {
                Circle()
                    .fill(Color.gray)
                    .frame(width: 25, height: 25)
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 1)
                    )
            }
            
            // Ulna/Radius
            VStack(spacing: 2) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(isAfter ? Color.gray : Color.brown)
                    .frame(width: 12, height: 30)
                RoundedRectangle(cornerRadius: 4)
                    .fill(isAfter ? Color.gray : Color.brown)
                    .frame(width: 10, height: 30)
            }
        }
    }
}

struct JointReplacementDetailsView: View {
    let jointType: JointType
    let replacementType: ReplacementType
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Procedure Details")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 8) {
                DetailRow(title: "Joint Type", value: jointType.displayName)
                DetailRow(title: "Replacement Type", value: replacementType.displayName)
                DetailRow(title: "Duration", value: jointType.duration)
                DetailRow(title: "Recovery Time", value: jointType.recoveryTime)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct DetailRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}

struct BrainIllustrationView: View {
    let procedureType: BrainSurgeryType
    let showingCrossSection: Bool
    
    var body: some View {
        ZStack {
            if showingCrossSection {
                BrainCrossSectionView(procedureType: procedureType)
            } else {
                BrainExternalView(procedureType: procedureType)
            }
        }
    }
}

struct BrainExternalView: View {
    let procedureType: BrainSurgeryType
    
    var body: some View {
        // Simplified brain external view
        Ellipse()
            .fill(Color.pink.opacity(0.7))
            .frame(width: 180, height: 140)
            .overlay(
                Ellipse()
                    .stroke(Color.pink, lineWidth: 2)
            )
    }
}

struct BrainCrossSectionView: View {
    let procedureType: BrainSurgeryType
    
    var body: some View {
        // Simplified brain cross section
        Circle()
            .fill(Color.pink.opacity(0.7))
            .frame(width: 160, height: 160)
            .overlay(
                Circle()
                    .stroke(Color.pink, lineWidth: 2)
            )
    }
}

struct BrainSurgeryInfoView: View {
    let procedureType: BrainSurgeryType
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Procedure Information")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 8) {
                DetailRow(title: "Procedure", value: procedureType.title)
                DetailRow(title: "Duration", value: procedureType.duration)
                DetailRow(title: "Risk Level", value: procedureType.riskLevel)
                DetailRow(title: "Recovery", value: procedureType.recoveryTime)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct AbdomenIllustrationView: View {
    let phase: AppendectomyPhase
    
    var body: some View {
        ZStack {
            // Abdomen outline
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.skin.opacity(0.3))
                .frame(width: 200, height: 150)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.skin, lineWidth: 2)
                )
            
            // Appendix location
            Circle()
                .fill(phase == .inflamed ? Color.red : Color.gray)
                .frame(width: 20, height: 20)
                .position(x: 160, y: 100)
            
            // Incision
            if phase == .incision || phase == .removal || phase == .closure {
                Rectangle()
                    .fill(Color.black)
                    .frame(width: 60, height: 2)
                    .position(x: 100, y: 75)
            }
        }
    }
}

struct AppendectomyDetailsView: View {
    let phase: AppendectomyPhase
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Appendectomy Details")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 8) {
                DetailRow(title: "Current Phase", value: phase.displayName)
                DetailRow(title: "Duration", value: "1-2 hours")
                DetailRow(title: "Anesthesia", value: "General")
                DetailRow(title: "Recovery", value: "2-4 weeks")
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct LaparoscopicProcedureView: View {
    let procedureType: LaparoscopicType
    let showingInstruments: Bool
    
    var body: some View {
        ZStack {
            // Abdomen
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.skin.opacity(0.3))
                .frame(width: 200, height: 150)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.skin, lineWidth: 2)
                )
            
            // Trocar sites
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(Color.gray)
                    .frame(width: 8, height: 8)
                    .position(
                        x: 80 + CGFloat(index * 40),
                        y: 75 + CGFloat(index * 20)
                    )
            }
            
            // Instruments
            if showingInstruments {
                ForEach(0..<3, id: \.self) { index in
                    Rectangle()
                        .fill(Color.gray)
                        .frame(width: 3, height: 40)
                        .position(
                            x: 80 + CGFloat(index * 40),
                            y: 55 + CGFloat(index * 20)
                        )
                }
            }
        }
    }
}

struct LaparoscopicInfoView: View {
    let procedureType: LaparoscopicType
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Laparoscopic Information")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 8) {
                DetailRow(title: "Procedure", value: procedureType.displayName)
                DetailRow(title: "Approach", value: "Minimally Invasive")
                DetailRow(title: "Duration", value: procedureType.duration)
                DetailRow(title: "Recovery", value: procedureType.recoveryTime)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Data Models

enum HeartSurgeryType: CaseIterable {
    case bypass
    case valve
    case pacemaker
    case stent
    
    var title: String {
        switch self {
        case .bypass: return "Coronary Artery Bypass Graft"
        case .valve: return "Heart Valve Replacement"
        case .pacemaker: return "Pacemaker Implantation"
        case .stent: return "Coronary Stent Placement"
        }
    }
    
    var steps: [String] {
        switch self {
        case .bypass:
            return [
                "Preparation and anesthesia",
                "Chest incision",
                "Graft harvesting",
                "Bypass grafting",
                "Chest closure"
            ]
        case .valve:
            return [
                "Preparation and anesthesia",
                "Chest incision",
                "Heart-lung bypass",
                "Valve replacement",
                "Chest closure"
            ]
        case .pacemaker:
            return [
                "Preparation and anesthesia",
                "Chest incision",
                "Lead placement",
                "Pacemaker implantation",
                "Incision closure"
            ]
        case .stent:
            return [
                "Preparation and anesthesia",
                "Catheter insertion",
                "Angiography",
                "Stent placement",
                "Catheter removal"
            ]
        }
    }
}

enum AnimationPhase: Int, CaseIterable {
    case preparation = 0
    case incision = 1
    case procedure = 2
    case closure = 3
    case completion = 4
}

enum JointType: CaseIterable {
    case hip
    case knee
    case shoulder
    case elbow
    
    var displayName: String {
        switch self {
        case .hip: return "Hip"
        case .knee: return "Knee"
        case .shoulder: return "Shoulder"
        case .elbow: return "Elbow"
        }
    }
    
    var duration: String {
        switch self {
        case .hip: return "2-3 hours"
        case .knee: return "1-2 hours"
        case .shoulder: return "2-3 hours"
        case .elbow: return "1-2 hours"
        }
    }
    
    var recoveryTime: String {
        switch self {
        case .hip: return "3-6 months"
        case .knee: return "3-6 months"
        case .shoulder: return "4-6 months"
        case .elbow: return "3-4 months"
        }
    }
}

enum ReplacementType: CaseIterable {
    case total
    case partial
    case revision
    
    var displayName: String {
        switch self {
        case .total: return "Total"
        case .partial: return "Partial"
        case .revision: return "Revision"
        }
    }
}

enum BrainSurgeryType: CaseIterable {
    case tumorRemoval
    case aneurysm
    case epilepsy
    case hydrocephalus
    
    var title: String {
        switch self {
        case .tumorRemoval: return "Brain Tumor Removal"
        case .aneurysm: return "Aneurysm Clipping"
        case .epilepsy: return "Epilepsy Surgery"
        case .hydrocephalus: return "Shunt Placement"
        }
    }
    
    var duration: String {
        switch self {
        case .tumorRemoval: return "4-8 hours"
        case .aneurysm: return "3-6 hours"
        case .epilepsy: return "4-6 hours"
        case .hydrocephalus: return "1-2 hours"
        }
    }
    
    var riskLevel: String {
        switch self {
        case .tumorRemoval: return "High"
        case .aneurysm: return "Very High"
        case .epilepsy: return "High"
        case .hydrocephalus: return "Medium"
        }
    }
    
    var recoveryTime: String {
        switch self {
        case .tumorRemoval: return "6-12 weeks"
        case .aneurysm: return "8-12 weeks"
        case .epilepsy: return "6-8 weeks"
        case .hydrocephalus: return "2-4 weeks"
        }
    }
}

enum AppendectomyPhase: CaseIterable {
    case normal
    case inflamed
    case incision
    case removal
    case closure
    
    var displayName: String {
        switch self {
        case .normal: return "Normal Appendix"
        case .inflamed: return "Inflamed Appendix"
        case .incision: return "Surgical Incision"
        case .removal: return "Appendix Removal"
        case .closure: return "Wound Closure"
        }
    }
}

enum LaparoscopicType: CaseIterable {
    case gallbladder
    case appendix
    case hernia
    case colon
    
    var displayName: String {
        switch self {
        case .gallbladder: return "Gallbladder Removal"
        case .appendix: return "Appendectomy"
        case .hernia: return "Hernia Repair"
        case .colon: return "Colon Surgery"
        }
    }
    
    var duration: String {
        switch self {
        case .gallbladder: return "1-2 hours"
        case .appendix: return "30-60 minutes"
        case .hernia: return "1-2 hours"
        case .colon: return "2-4 hours"
        }
    }
    
    var recoveryTime: String {
        switch self {
        case .gallbladder: return "1-2 weeks"
        case .appendix: return "1-2 weeks"
        case .hernia: return "2-4 weeks"
        case .colon: return "4-6 weeks"
        }
    }
}

// MARK: - Extensions

extension Color {
    static let skin = Color(red: 0.9, green: 0.8, blue: 0.7)
} 
import SwiftUI

// MARK: - Treatment Illustrations
/// Comprehensive treatment illustrations for various medical treatments and therapies
/// Provides detailed visual guides for treatment procedures and therapeutic interventions
public struct TreatmentIllustrations {
    
    // MARK: - Physical Therapy Illustrations
    
    /// Physical therapy exercise illustration
    public struct PhysicalTherapyIllustration: View {
        let exerciseType: PhysicalTherapyExercise
        let bodyPart: BodyPart
        @State private var showingAnimation: Bool = false
        @State private var animationProgress: Double = 0
        
        public init(
            exerciseType: PhysicalTherapyExercise = .stretching,
            bodyPart: BodyPart = .shoulder
        ) {
            self.exerciseType = exerciseType
            self.bodyPart = bodyPart
        }
        
        public var body: some View {
            VStack(spacing: 20) {
                // Exercise Title
                Text("\(exerciseType.displayName) - \(bodyPart.displayName)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                // Exercise Animation
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemGray6))
                        .frame(height: 300)
                    
                    ExerciseAnimationView(
                        exerciseType: exerciseType,
                        bodyPart: bodyPart,
                        showingAnimation: showingAnimation,
                        animationProgress: animationProgress
                    )
                    .frame(height: 280)
                }
                
                // Animation Controls
                VStack(spacing: 12) {
                    Button(action: { 
                        showingAnimation.toggle()
                        if showingAnimation {
                            startAnimation()
                        } else {
                            animationProgress = 0
                        }
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: showingAnimation ? "stop.fill" : "play.fill")
                            Text(showingAnimation ? "Stop" : "Start Animation")
                        }
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(showingAnimation ? Color.red : Color.green)
                        .cornerRadius(8)
                    }
                    
                    if showingAnimation {
                        ProgressView(value: animationProgress)
                            .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                    }
                }
                
                // Exercise Instructions
                ExerciseInstructionsView(exerciseType: exerciseType)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        }
        
        private func startAnimation() {
            withAnimation(.linear(duration: 3).repeatForever(autoreverses: true)) {
                animationProgress = 1.0
            }
        }
    }
    
    // MARK: - Medication Administration Illustrations
    
    /// Medication administration illustration
    public struct MedicationAdministrationIllustration: View {
        let medicationType: MedicationType
        let administrationRoute: AdministrationRoute
        @State private var showingSteps: Bool = false
        @State private var currentStep: Int = 0
        
        public init(
            medicationType: MedicationType = .pill,
            administrationRoute: AdministrationRoute = .oral
        ) {
            self.medicationType = medicationType
            self.administrationRoute = administrationRoute
        }
        
        public var body: some View {
            VStack(spacing: 20) {
                // Medication Title
                Text("\(medicationType.displayName) Administration")
                    .font(.title2)
                    .fontWeight(.bold)
                
                // Route Selector
                Picker("Route", selection: .constant(administrationRoute)) {
                    ForEach(AdministrationRoute.allCases, id: \.self) { route in
                        Text(route.displayName).tag(route)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                
                // Administration Illustration
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemGray6))
                        .frame(height: 300)
                    
                    MedicationAdministrationView(
                        medicationType: medicationType,
                        administrationRoute: administrationRoute,
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
                        
                        Text("Step \(currentStep + 1) of \(administrationRoute.steps.count)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Button(action: { 
                            if currentStep < administrationRoute.steps.count - 1 {
                                currentStep += 1
                            }
                        }) {
                            Image(systemName: "forward.fill")
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(8)
                        }
                        .disabled(currentStep == administrationRoute.steps.count - 1)
                    }
                    
                    // Step Instructions
                    if currentStep < administrationRoute.steps.count {
                        Text(administrationRoute.steps[currentStep])
                            .font(.subheadline)
                            .multilineTextAlignment(.center)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                }
                
                // Safety Information
                MedicationSafetyView(medicationType: medicationType)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        }
    }
    
    // MARK: - Wound Care Illustrations
    
    /// Wound care procedure illustration
    public struct WoundCareIllustration: View {
        let woundType: WoundType
        let carePhase: WoundCarePhase
        @State private var showingEquipment: Bool = false
        
        public init(
            woundType: WoundType = .abrasion,
            carePhase: WoundCarePhase = .cleaning
        ) {
            self.woundType = woundType
            self.carePhase = carePhase
        }
        
        public var body: some View {
            VStack(spacing: 20) {
                // Wound Care Title
                Text("\(woundType.displayName) Wound Care")
                    .font(.title2)
                    .fontWeight(.bold)
                
                // Phase Selector
                Picker("Phase", selection: .constant(carePhase)) {
                    ForEach(WoundCarePhase.allCases, id: \.self) { phase in
                        Text(phase.displayName).tag(phase)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                
                // Wound Care Illustration
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemGray6))
                        .frame(height: 300)
                    
                    WoundCareView(
                        woundType: woundType,
                        carePhase: carePhase,
                        showingEquipment: showingEquipment
                    )
                    .frame(height: 280)
                }
                
                // Equipment Toggle
                Toggle("Show Equipment", isOn: $showingEquipment)
                    .padding(.horizontal)
                
                // Care Instructions
                WoundCareInstructionsView(woundType: woundType, carePhase: carePhase)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        }
    }
    
    // MARK: - Respiratory Therapy Illustrations
    
    /// Respiratory therapy illustration
    public struct RespiratoryTherapyIllustration: View {
        let therapyType: RespiratoryTherapyType
        @State private var showingBreathing: Bool = false
        @State private var breathingPhase: BreathingPhase = .inhale
        
        public init(therapyType: RespiratoryTherapyType = .inhaler) {
            self.therapyType = therapyType
        }
        
        public var body: some View {
            VStack(spacing: 20) {
                // Therapy Title
                Text("\(therapyType.displayName) Therapy")
                    .font(.title2)
                    .fontWeight(.bold)
                
                // Breathing Animation
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemGray6))
                        .frame(height: 300)
                    
                    RespiratoryTherapyView(
                        therapyType: therapyType,
                        showingBreathing: showingBreathing,
                        breathingPhase: breathingPhase
                    )
                    .frame(height: 280)
                }
                
                // Breathing Controls
                VStack(spacing: 12) {
                    Button(action: { 
                        showingBreathing.toggle()
                        if showingBreathing {
                            startBreathingAnimation()
                        }
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: showingBreathing ? "pause.fill" : "play.fill")
                            Text(showingBreathing ? "Pause" : "Start Breathing")
                        }
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(showingBreathing ? Color.orange : Color.green)
                        .cornerRadius(8)
                    }
                    
                    if showingBreathing {
                        Text(breathingPhase.displayName)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.blue)
                    }
                }
                
                // Therapy Instructions
                RespiratoryTherapyInstructionsView(therapyType: therapyType)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        }
        
        private func startBreathingAnimation() {
            Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
                withAnimation(.easeInOut(duration: 1.0)) {
                    breathingPhase = breathingPhase == .inhale ? .exhale : .inhale
                }
            }
        }
    }
    
    // MARK: - Rehabilitation Illustrations
    
    /// Rehabilitation exercise illustration
    public struct RehabilitationIllustration: View {
        let rehabilitationType: RehabilitationType
        let exercisePhase: ExercisePhase
        @State private var showingProgress: Bool = false
        
        public init(
            rehabilitationType: RehabilitationType = .postSurgery,
            exercisePhase: ExercisePhase = .early
        ) {
            self.rehabilitationType = rehabilitationType
            self.exercisePhase = exercisePhase
        }
        
        public var body: some View {
            VStack(spacing: 20) {
                // Rehabilitation Title
                Text("\(rehabilitationType.displayName) Rehabilitation")
                    .font(.title2)
                    .fontWeight(.bold)
                
                // Phase Selector
                Picker("Phase", selection: .constant(exercisePhase)) {
                    ForEach(ExercisePhase.allCases, id: \.self) { phase in
                        Text(phase.displayName).tag(phase)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                
                // Rehabilitation Illustration
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemGray6))
                        .frame(height: 300)
                    
                    RehabilitationView(
                        rehabilitationType: rehabilitationType,
                        exercisePhase: exercisePhase,
                        showingProgress: showingProgress
                    )
                    .frame(height: 280)
                }
                
                // Progress Toggle
                Toggle("Show Progress", isOn: $showingProgress)
                    .padding(.horizontal)
                
                // Rehabilitation Plan
                RehabilitationPlanView(rehabilitationType: rehabilitationType)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        }
    }
}

// MARK: - Supporting Views

struct ExerciseAnimationView: View {
    let exerciseType: PhysicalTherapyExercise
    let bodyPart: BodyPart
    let showingAnimation: Bool
    let animationProgress: Double
    
    var body: some View {
        ZStack {
            // Body outline
            BodyOutlineView(bodyPart: bodyPart)
            
            // Exercise animation
            if showingAnimation {
                ExerciseMovementView(
                    exerciseType: exerciseType,
                    bodyPart: bodyPart,
                    progress: animationProgress
                )
            }
        }
    }
}

struct BodyOutlineView: View {
    let bodyPart: BodyPart
    
    var body: some View {
        switch bodyPart {
        case .shoulder:
            // Shoulder outline
            Ellipse()
                .stroke(Color.black, lineWidth: 2)
                .frame(width: 80, height: 60)
        case .knee:
            // Knee outline
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.black, lineWidth: 2)
                .frame(width: 60, height: 80)
        case .back:
            // Back outline
            Rectangle()
                .stroke(Color.black, lineWidth: 2)
                .frame(width: 40, height: 120)
        case .neck:
            // Neck outline
            RoundedRectangle(cornerRadius: 4)
                .stroke(Color.black, lineWidth: 2)
                .frame(width: 30, height: 40)
        }
    }
}

struct ExerciseMovementView: View {
    let exerciseType: PhysicalTherapyExercise
    let bodyPart: BodyPart
    let progress: Double
    
    var body: some View {
        switch exerciseType {
        case .stretching:
            StretchingAnimation(bodyPart: bodyPart, progress: progress)
        case .strengthening:
            StrengtheningAnimation(bodyPart: bodyPart, progress: progress)
        case .rangeOfMotion:
            RangeOfMotionAnimation(bodyPart: bodyPart, progress: progress)
        case .balance:
            BalanceAnimation(bodyPart: bodyPart, progress: progress)
        }
    }
}

struct StretchingAnimation: View {
    let bodyPart: BodyPart
    let progress: Double
    
    var body: some View {
        // Stretching movement visualization
        Circle()
            .fill(Color.blue.opacity(0.6))
            .frame(width: 20, height: 20)
            .scaleEffect(1.0 + progress * 0.5)
            .opacity(0.8)
    }
}

struct StrengtheningAnimation: View {
    let bodyPart: BodyPart
    let progress: Double
    
    var body: some View {
        // Strengthening movement visualization
        RoundedRectangle(cornerRadius: 4)
            .fill(Color.green.opacity(0.6))
            .frame(width: 30, height: 10)
            .scaleEffect(1.0 + progress * 0.3)
    }
}

struct RangeOfMotionAnimation: View {
    let bodyPart: BodyPart
    let progress: Double
    
    var body: some View {
        // Range of motion visualization
        Arc(startAngle: .degrees(0), endAngle: .degrees(180 * progress))
            .stroke(Color.orange, lineWidth: 3)
            .frame(width: 60, height: 60)
    }
}

struct BalanceAnimation: View {
    let bodyPart: BodyPart
    let progress: Double
    
    var body: some View {
        // Balance visualization
        Circle()
            .fill(Color.purple.opacity(0.6))
            .frame(width: 25, height: 25)
            .offset(x: CGFloat(sin(progress * 2 * .pi) * 10))
    }
}

struct ExerciseInstructionsView: View {
    let exerciseType: PhysicalTherapyExercise
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Exercise Instructions")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(exerciseType.instructions, id: \.self) { instruction in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "circle.fill")
                            .font(.caption)
                            .foregroundColor(.blue)
                            .offset(y: 4)
                        
                        Text(instruction)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct MedicationAdministrationView: View {
    let medicationType: MedicationType
    let administrationRoute: AdministrationRoute
    let currentStep: Int
    
    var body: some View {
        ZStack {
            // Patient outline
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.skin.opacity(0.3))
                .frame(width: 120, height: 80)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.skin, lineWidth: 2)
                )
            
            // Medication
            medicationVisualization
            
            // Administration route
            administrationRouteVisualization
        }
    }
    
    @ViewBuilder
    private var medicationVisualization: some View {
        switch medicationType {
        case .pill:
            Capsule()
                .fill(Color.white)
                .frame(width: 20, height: 8)
                .overlay(
                    Capsule()
                        .stroke(Color.gray, lineWidth: 1)
                )
        case .injection:
            Rectangle()
                .fill(Color.gray)
                .frame(width: 4, height: 30)
                .overlay(
                    Rectangle()
                        .fill(Color.blue)
                        .frame(width: 4, height: 20)
                        .offset(y: -5)
                )
        case .inhaler:
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.blue)
                .frame(width: 25, height: 40)
        case .topical:
            Circle()
                .fill(Color.white.opacity(0.8))
                .frame(width: 30, height: 30)
                .overlay(
                    Circle()
                        .stroke(Color.gray, lineWidth: 2)
                )
        }
    }
    
    @ViewBuilder
    private var administrationRouteVisualization: some View {
        switch administrationRoute {
        case .oral:
            // Mouth
            Ellipse()
                .fill(Color.pink.opacity(0.3))
                .frame(width: 20, height: 15)
                .offset(y: -30)
        case .injection:
            // Injection site
            Circle()
                .fill(Color.red.opacity(0.3))
                .frame(width: 15, height: 15)
                .offset(x: 40, y: -10)
        case .inhalation:
            // Nose/mouth
            Ellipse()
                .fill(Color.pink.opacity(0.3))
                .frame(width: 15, height: 10)
                .offset(y: -35)
        case .topical:
            // Skin surface
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.skin.opacity(0.5))
                .frame(width: 40, height: 20)
                .offset(x: 30, y: 0)
        }
    }
}

struct MedicationSafetyView: View {
    let medicationType: MedicationType
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Safety Information")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(medicationType.safetyTips, id: \.self) { tip in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                            .font(.caption)
                        
                        Text(tip)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct WoundCareView: View {
    let woundType: WoundType
    let carePhase: WoundCarePhase
    let showingEquipment: Bool
    
    var body: some View {
        ZStack {
            // Wound area
            woundVisualization
            
            // Care equipment
            if showingEquipment {
                careEquipmentVisualization
            }
        }
    }
    
    @ViewBuilder
    private var woundVisualization: some View {
        switch woundType {
        case .abrasion:
            Ellipse()
                .fill(Color.red.opacity(0.3))
                .frame(width: 40, height: 30)
                .overlay(
                    Ellipse()
                        .stroke(Color.red, lineWidth: 2)
                )
        case .laceration:
            Rectangle()
                .fill(Color.red.opacity(0.3))
                .frame(width: 50, height: 8)
                .overlay(
                    Rectangle()
                        .stroke(Color.red, lineWidth: 2)
                )
        case .puncture:
            Circle()
                .fill(Color.red.opacity(0.3))
                .frame(width: 15, height: 15)
                .overlay(
                    Circle()
                        .stroke(Color.red, lineWidth: 2)
                )
        case .burn:
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.orange.opacity(0.3))
                .frame(width: 45, height: 35)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.orange, lineWidth: 2)
                )
        }
    }
    
    @ViewBuilder
    private var careEquipmentVisualization: some View {
        switch carePhase {
        case .cleaning:
            // Cleaning supplies
            VStack(spacing: 5) {
                Circle()
                    .fill(Color.blue.opacity(0.6))
                    .frame(width: 20, height: 20)
                Text("Cleanser")
                    .font(.caption2)
                    .foregroundColor(.blue)
            }
            .offset(x: -50, y: -30)
        case .dressing:
            // Dressing materials
            VStack(spacing: 5) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.white.opacity(0.8))
                    .frame(width: 30, height: 20)
                Text("Dressing")
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
            .offset(x: 50, y: -30)
        case .monitoring:
            // Monitoring tools
            VStack(spacing: 5) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.green.opacity(0.6))
                    .frame(width: 25, height: 15)
                Text("Monitor")
                    .font(.caption2)
                    .foregroundColor(.green)
            }
            .offset(x: 0, y: 50)
        }
    }
}

struct WoundCareInstructionsView: View {
    let woundType: WoundType
    let carePhase: WoundCarePhase
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Care Instructions")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(carePhase.instructions, id: \.self) { instruction in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                        
                        Text(instruction)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct RespiratoryTherapyView: View {
    let therapyType: RespiratoryTherapyType
    let showingBreathing: Bool
    let breathingPhase: BreathingPhase
    
    var body: some View {
        ZStack {
            // Patient outline
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.skin.opacity(0.3))
                .frame(width: 120, height: 80)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.skin, lineWidth: 2)
                )
            
            // Lungs
            HStack(spacing: 20) {
                Circle()
                    .fill(Color.pink.opacity(0.3))
                    .frame(width: 30, height: 30)
                    .scaleEffect(showingBreathing ? (breathingPhase == .inhale ? 1.2 : 0.8) : 1.0)
                
                Circle()
                    .fill(Color.pink.opacity(0.3))
                    .frame(width: 30, height: 30)
                    .scaleEffect(showingBreathing ? (breathingPhase == .inhale ? 1.2 : 0.8) : 1.0)
            }
            .offset(y: -10)
            
            // Therapy device
            therapyDeviceVisualization
        }
    }
    
    @ViewBuilder
    private var therapyDeviceVisualization: some View {
        switch therapyType {
        case .inhaler:
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.blue)
                .frame(width: 20, height: 40)
                .offset(x: -60, y: -20)
        case .nebulizer:
            Ellipse()
                .fill(Color.gray)
                .frame(width: 35, height: 25)
                .offset(x: -60, y: -20)
        case .spirometer:
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.green)
                .frame(width: 30, height: 20)
                .offset(x: -60, y: -20)
        case .oxygen:
            Circle()
                .fill(Color.blue.opacity(0.6))
                .frame(width: 25, height: 25)
                .offset(x: -60, y: -20)
        }
    }
}

struct RespiratoryTherapyInstructionsView: View {
    let therapyType: RespiratoryTherapyType
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Therapy Instructions")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(therapyType.instructions, id: \.self) { instruction in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "circle.fill")
                            .foregroundColor(.blue)
                            .font(.caption)
                            .offset(y: 4)
                        
                        Text(instruction)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct RehabilitationView: View {
    let rehabilitationType: RehabilitationType
    let exercisePhase: ExercisePhase
    let showingProgress: Bool
    
    var body: some View {
        ZStack {
            // Patient outline
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.skin.opacity(0.3))
                .frame(width: 120, height: 80)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.skin, lineWidth: 2)
                )
            
            // Rehabilitation visualization
            rehabilitationVisualization
            
            // Progress indicator
            if showingProgress {
                progressVisualization
            }
        }
    }
    
    @ViewBuilder
    private var rehabilitationVisualization: some View {
        switch rehabilitationType {
        case .postSurgery:
            // Surgical site
            Circle()
                .fill(Color.red.opacity(0.3))
                .frame(width: 20, height: 20)
                .offset(x: 40, y: -10)
        case .stroke:
            // Brain visualization
            Ellipse()
                .fill(Color.pink.opacity(0.3))
                .frame(width: 30, height: 25)
                .offset(y: -30)
        case .cardiac:
            // Heart visualization
            HeartShape()
                .fill(Color.red.opacity(0.3))
                .frame(width: 25, height: 25)
                .offset(x: 0, y: -15)
        case .orthopedic:
            // Joint visualization
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 30, height: 15)
                .offset(x: 40, y: 10)
        }
    }
    
    @ViewBuilder
    private var progressVisualization: some View {
        VStack(spacing: 5) {
            ProgressView(value: exercisePhase.progress)
                .progressViewStyle(LinearProgressViewStyle(tint: .green))
                .frame(width: 80)
            
            Text("\(Int(exercisePhase.progress * 100))%")
                .font(.caption)
                .foregroundColor(.green)
        }
        .offset(y: 50)
    }
}

struct RehabilitationPlanView: View {
    let rehabilitationType: RehabilitationType
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Rehabilitation Plan")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(rehabilitationType.plan, id: \.self) { item in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "list.bullet")
                            .foregroundColor(.blue)
                            .font(.caption)
                            .offset(y: 4)
                        
                        Text(item)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Data Models

enum PhysicalTherapyExercise: CaseIterable {
    case stretching
    case strengthening
    case rangeOfMotion
    case balance
    
    var displayName: String {
        switch self {
        case .stretching: return "Stretching"
        case .strengthening: return "Strengthening"
        case .rangeOfMotion: return "Range of Motion"
        case .balance: return "Balance"
        }
    }
    
    var instructions: [String] {
        switch self {
        case .stretching:
            return [
                "Hold each stretch for 30 seconds",
                "Breathe deeply and relax",
                "Don't bounce or force the stretch",
                "Stop if you feel pain"
            ]
        case .strengthening:
            return [
                "Perform 3 sets of 10-15 repetitions",
                "Maintain proper form throughout",
                "Rest 1-2 minutes between sets",
                "Gradually increase resistance"
            ]
        case .rangeOfMotion:
            return [
                "Move slowly and smoothly",
                "Go to the point of mild discomfort",
                "Hold end positions briefly",
                "Repeat 5-10 times"
            ]
        case .balance:
            return [
                "Stand on a stable surface",
                "Keep your eyes open initially",
                "Gradually increase difficulty",
                "Have support nearby"
            ]
        }
    }
}

enum BodyPart: CaseIterable {
    case shoulder
    case knee
    case back
    case neck
    
    var displayName: String {
        switch self {
        case .shoulder: return "Shoulder"
        case .knee: return "Knee"
        case .back: return "Back"
        case .neck: return "Neck"
        }
    }
}

enum MedicationType: CaseIterable {
    case pill
    case injection
    case inhaler
    case topical
    
    var displayName: String {
        switch self {
        case .pill: return "Oral Medication"
        case .injection: return "Injection"
        case .inhaler: return "Inhaler"
        case .topical: return "Topical"
        }
    }
    
    var safetyTips: [String] {
        switch self {
        case .pill:
            return [
                "Take with water",
                "Follow dosage instructions",
                "Store in a cool, dry place",
                "Check expiration date"
            ]
        case .injection:
            return [
                "Use sterile technique",
                "Rotate injection sites",
                "Dispose of needles properly",
                "Check for allergies"
            ]
        case .inhaler:
            return [
                "Shake before use",
                "Rinse mouth after use",
                "Clean regularly",
                "Check expiration date"
            ]
        case .topical:
            return [
                "Clean area before application",
                "Apply thin layer",
                "Wash hands after use",
                "Avoid contact with eyes"
            ]
        }
    }
}

enum AdministrationRoute: CaseIterable {
    case oral
    case injection
    case inhalation
    case topical
    
    var displayName: String {
        switch self {
        case .oral: return "Oral"
        case .injection: return "Injection"
        case .inhalation: return "Inhalation"
        case .topical: return "Topical"
        }
    }
    
    var steps: [String] {
        switch self {
        case .oral:
            return [
                "Wash hands thoroughly",
                "Check medication label",
                "Take with water",
                "Wait 30 minutes before lying down"
            ]
        case .injection:
            return [
                "Gather supplies",
                "Clean injection site",
                "Prepare medication",
                "Administer injection",
                "Dispose of needle safely"
            ]
        case .inhalation:
            return [
                "Shake inhaler",
                "Breathe out completely",
                "Inhale medication",
                "Hold breath for 10 seconds",
                "Rinse mouth"
            ]
        case .topical:
            return [
                "Clean application area",
                "Apply thin layer",
                "Cover if needed",
                "Wash hands thoroughly"
            ]
        }
    }
}

enum WoundType: CaseIterable {
    case abrasion
    case laceration
    case puncture
    case burn
    
    var displayName: String {
        switch self {
        case .abrasion: return "Abrasion"
        case .laceration: return "Laceration"
        case .puncture: return "Puncture"
        case .burn: return "Burn"
        }
    }
}

enum WoundCarePhase: CaseIterable {
    case cleaning
    case dressing
    case monitoring
    
    var displayName: String {
        switch self {
        case .cleaning: return "Cleaning"
        case .dressing: return "Dressing"
        case .monitoring: return "Monitoring"
        }
    }
    
    var instructions: [String] {
        switch self {
        case .cleaning:
            return [
                "Wash hands thoroughly",
                "Clean with mild soap and water",
                "Rinse thoroughly",
                "Pat dry gently"
            ]
        case .dressing:
            return [
                "Apply antibiotic ointment if needed",
                "Cover with sterile dressing",
                "Secure with tape or bandage",
                "Change dressing daily"
            ]
        case .monitoring:
            return [
                "Check for signs of infection",
                "Monitor healing progress",
                "Keep area clean and dry",
                "Contact healthcare provider if concerned"
            ]
        }
    }
}

enum RespiratoryTherapyType: CaseIterable {
    case inhaler
    case nebulizer
    case spirometer
    case oxygen
    
    var displayName: String {
        switch self {
        case .inhaler: return "Inhaler"
        case .nebulizer: return "Nebulizer"
        case .spirometer: return "Spirometer"
        case .oxygen: return "Oxygen Therapy"
        }
    }
    
    var instructions: [String] {
        switch self {
        case .inhaler:
            return [
                "Shake inhaler well",
                "Breathe out completely",
                "Inhale medication slowly",
                "Hold breath for 10 seconds",
                "Rinse mouth after use"
            ]
        case .nebulizer:
            return [
                "Assemble nebulizer",
                "Add medication to cup",
                "Breathe normally through mouthpiece",
                "Continue until medication is gone",
                "Clean equipment after use"
            ]
        case .spirometer:
            return [
                "Sit upright",
                "Place mouthpiece in mouth",
                "Breathe in slowly and deeply",
                "Hold breath briefly",
                "Exhale slowly"
            ]
        case .oxygen:
            return [
                "Check oxygen flow rate",
                "Place nasal cannula properly",
                "Keep tubing untangled",
                "Monitor oxygen saturation",
                "Follow prescribed flow rate"
            ]
        }
    }
}

enum BreathingPhase {
    case inhale
    case exhale
    
    var displayName: String {
        switch self {
        case .inhale: return "Inhale"
        case .exhale: return "Exhale"
        }
    }
}

enum RehabilitationType: CaseIterable {
    case postSurgery
    case stroke
    case cardiac
    case orthopedic
    
    var displayName: String {
        switch self {
        case .postSurgery: return "Post-Surgery"
        case .stroke: return "Stroke"
        case .cardiac: return "Cardiac"
        case .orthopedic: return "Orthopedic"
        }
    }
    
    var plan: [String] {
        switch self {
        case .postSurgery:
            return [
                "Pain management",
                "Wound care",
                "Gradual mobility",
                "Strength building",
                "Return to activities"
            ]
        case .stroke:
            return [
                "Neurological assessment",
                "Mobility training",
                "Speech therapy",
                "Cognitive rehabilitation",
                "Adaptive equipment"
            ]
        case .cardiac:
            return [
                "Cardiac monitoring",
                "Gradual exercise",
                "Lifestyle modification",
                "Medication management",
                "Stress management"
            ]
        case .orthopedic:
            return [
                "Joint mobility",
                "Strength training",
                "Balance exercises",
                "Functional training",
                "Return to sports"
            ]
        }
    }
}

enum ExercisePhase: CaseIterable {
    case early
    case intermediate
    case advanced
    case maintenance
    
    var displayName: String {
        switch self {
        case .early: return "Early"
        case .intermediate: return "Intermediate"
        case .advanced: return "Advanced"
        case .maintenance: return "Maintenance"
        }
    }
    
    var progress: Double {
        switch self {
        case .early: return 0.25
        case .intermediate: return 0.5
        case .advanced: return 0.75
        case .maintenance: return 1.0
        }
    }
}

// MARK: - Extensions

extension Color {
    static let skin = Color(red: 0.9, green: 0.8, blue: 0.7)
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

struct Arc: Shape {
    let startAngle: Angle
    let endAngle: Angle
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        
        path.addArc(
            center: center,
            radius: radius,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: false
        )
        
        return path
    }
} 
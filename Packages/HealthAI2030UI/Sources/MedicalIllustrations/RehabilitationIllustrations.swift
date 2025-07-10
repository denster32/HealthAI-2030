import SwiftUI

// MARK: - Rehabilitation Illustrations
/// Comprehensive rehabilitation illustrations for physical therapy and recovery exercises
/// Provides detailed visual guides for rehabilitation exercises and therapeutic interventions
public struct RehabilitationIllustrations {
    
    // MARK: - Physical Therapy Exercises
    
    /// Physical therapy exercise illustration
    public struct PhysicalTherapyExerciseIllustration: View {
        let exerciseType: PhysicalTherapyExercise
        let bodyPart: RehabilitationBodyPart
        @State private var showingAnimation: Bool = false
        @State private var animationProgress: Double = 0
        @State private var currentPhase: ExercisePhase = .starting
        
        public init(
            exerciseType: PhysicalTherapyExercise = .stretching,
            bodyPart: RehabilitationBodyPart = .shoulder
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
                
                // Body Part Selector
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(RehabilitationBodyPart.allCases, id: \.self) { part in
                            BodyPartButton(
                                bodyPart: part,
                                isSelected: bodyPart == part,
                                action: { /* Update body part */ }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Exercise Animation
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemGray6))
                        .frame(height: 300)
                    
                    ExerciseAnimationView(
                        exerciseType: exerciseType,
                        bodyPart: bodyPart,
                        currentPhase: currentPhase,
                        animationProgress: animationProgress
                    )
                    .frame(height: 280)
                }
                
                // Animation Controls
                VStack(spacing: 12) {
                    HStack(spacing: 20) {
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
                                .frame(width: 100)
                        }
                    }
                    
                    // Phase Indicator
                    Text(currentPhase.displayName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
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
    
    // MARK: - Occupational Therapy Illustrations
    
    /// Occupational therapy activity illustration
    public struct OccupationalTherapyIllustration: View {
        let activityType: OccupationalTherapyActivity
        let difficultyLevel: DifficultyLevel
        @State private var showingSteps: Bool = false
        @State private var currentStep: Int = 0
        
        public init(
            activityType: OccupationalTherapyActivity = .dressing,
            difficultyLevel: DifficultyLevel = .beginner
        ) {
            self.activityType = activityType
            self.difficultyLevel = difficultyLevel
        }
        
        public var body: some View {
            VStack(spacing: 20) {
                // Activity Title
                Text("\(activityType.displayName) - \(difficultyLevel.displayName)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                // Difficulty Level Selector
                Picker("Difficulty", selection: .constant(difficultyLevel)) {
                    ForEach(DifficultyLevel.allCases, id: \.self) { level in
                        Text(level.displayName).tag(level)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                
                // Activity Illustration
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemGray6))
                        .frame(height: 300)
                    
                    OccupationalActivityView(
                        activityType: activityType,
                        difficultyLevel: difficultyLevel,
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
                        
                        Text("Step \(currentStep + 1) of \(activitySteps.count)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Button(action: { 
                            if currentStep < activitySteps.count - 1 {
                                currentStep += 1
                            }
                        }) {
                            Image(systemName: "forward.fill")
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(8)
                        }
                        .disabled(currentStep == activitySteps.count - 1)
                    }
                    
                    // Step Instructions
                    if currentStep < activitySteps.count {
                        Text(activitySteps[currentStep])
                            .font(.subheadline)
                            .multilineTextAlignment(.center)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                }
                
                // Activity Benefits
                ActivityBenefitsView(activityType: activityType)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        }
        
        private var activitySteps: [String] {
            switch activityType {
            case .dressing:
                return [
                    "Prepare clothing items",
                    "Start with larger items first",
                    "Use adaptive equipment if needed",
                    "Practice with both hands",
                    "Gradually increase complexity"
                ]
            case .cooking:
                return [
                    "Gather ingredients and tools",
                    "Follow safety guidelines",
                    "Use adaptive kitchen tools",
                    "Practice basic techniques",
                    "Build confidence gradually"
                ]
            case .writing:
                return [
                    "Use proper grip technique",
                    "Practice letter formation",
                    "Work on spacing and alignment",
                    "Use adaptive writing tools",
                    "Build endurance over time"
                ]
            case .grooming:
                return [
                    "Set up grooming area",
                    "Use adaptive grooming tools",
                    "Practice one-handed techniques",
                    "Focus on safety and comfort",
                    "Build independence gradually"
                ]
            }
        }
    }
    
    // MARK: - Speech Therapy Illustrations
    
    /// Speech therapy exercise illustration
    public struct SpeechTherapyIllustration: View {
        let exerciseType: SpeechTherapyExercise
        let targetSound: TargetSound
        @State private var showingAnimation: Bool = false
        @State private var currentRepetition: Int = 0
        @State private var totalRepetitions: Int = 10
        
        public init(
            exerciseType: SpeechTherapyExercise = .articulation,
            targetSound: TargetSound = .s
        ) {
            self.exerciseType = exerciseType
            self.targetSound = targetSound
        }
        
        public var body: some View {
            VStack(spacing: 20) {
                // Exercise Title
                Text("\(exerciseType.displayName) - \(targetSound.displayName) Sound")
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                // Target Sound Selector
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(TargetSound.allCases, id: \.self) { sound in
                            SoundButton(
                                sound: sound,
                                isSelected: targetSound == sound,
                                action: { /* Update target sound */ }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Speech Exercise Illustration
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemGray6))
                        .frame(height: 300)
                    
                    SpeechExerciseView(
                        exerciseType: exerciseType,
                        targetSound: targetSound,
                        currentRepetition: currentRepetition,
                        totalRepetitions: totalRepetitions
                    )
                    .frame(height: 280)
                }
                
                // Exercise Controls
                VStack(spacing: 12) {
                    HStack(spacing: 20) {
                        Button(action: { 
                            showingAnimation.toggle()
                            if showingAnimation {
                                startRepetitions()
                            } else {
                                currentRepetition = 0
                            }
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: showingAnimation ? "stop.fill" : "play.fill")
                                Text(showingAnimation ? "Stop" : "Start Exercise")
                            }
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(showingAnimation ? Color.red : Color.green)
                            .cornerRadius(8)
                        }
                        
                        Text("\(currentRepetition)/\(totalRepetitions)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.blue)
                    }
                    
                    // Progress Bar
                    ProgressView(value: Double(currentRepetition), total: Double(totalRepetitions))
                        .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                        .padding(.horizontal)
                }
                
                // Exercise Instructions
                SpeechExerciseInstructionsView(exerciseType: exerciseType, targetSound: targetSound)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        }
        
        private func startRepetitions() {
            Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { timer in
                if currentRepetition < totalRepetitions {
                    currentRepetition += 1
                } else {
                    timer.invalidate()
                    showingAnimation = false
                }
            }
        }
    }
    
    // MARK: - Cognitive Rehabilitation Illustrations
    
    /// Cognitive rehabilitation exercise illustration
    public struct CognitiveRehabilitationIllustration: View {
        let exerciseType: CognitiveExercise
        let difficultyLevel: CognitiveDifficulty
        @State private var showingExercise: Bool = false
        @State private var currentQuestion: Int = 0
        @State private var score: Int = 0
        
        public init(
            exerciseType: CognitiveExercise = .memory,
            difficultyLevel: CognitiveDifficulty = .easy
        ) {
            self.exerciseType = exerciseType
            self.difficultyLevel = difficultyLevel
        }
        
        public var body: some View {
            VStack(spacing: 20) {
                // Exercise Title
                Text("\(exerciseType.displayName) - \(difficultyLevel.displayName)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                // Exercise Type Selector
                Picker("Exercise Type", selection: .constant(exerciseType)) {
                    ForEach(CognitiveExercise.allCases, id: \.self) { type in
                        Text(type.displayName).tag(type)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                
                // Cognitive Exercise Display
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemGray6))
                        .frame(height: 300)
                    
                    CognitiveExerciseView(
                        exerciseType: exerciseType,
                        difficultyLevel: difficultyLevel,
                        currentQuestion: currentQuestion,
                        score: score
                    )
                    .frame(height: 280)
                }
                
                // Exercise Controls
                VStack(spacing: 12) {
                    HStack(spacing: 20) {
                        Button(action: { 
                            showingExercise.toggle()
                            if showingExercise {
                                startExercise()
                            } else {
                                currentQuestion = 0
                                score = 0
                            }
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: showingExercise ? "stop.fill" : "play.fill")
                                Text(showingExercise ? "Stop" : "Start Exercise")
                            }
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(showingExercise ? Color.red : Color.green)
                            .cornerRadius(8)
                        }
                        
                        Text("Score: \(score)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.green)
                    }
                    
                    // Question Progress
                    Text("Question \(currentQuestion + 1) of \(totalQuestions)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Exercise Benefits
                CognitiveBenefitsView(exerciseType: exerciseType)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        }
        
        private var totalQuestions: Int {
            switch difficultyLevel {
            case .easy: return 5
            case .medium: return 10
            case .hard: return 15
            }
        }
        
        private func startExercise() {
            // Simulate exercise progression
            Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { timer in
                if currentQuestion < totalQuestions - 1 {
                    currentQuestion += 1
                    score += Int.random(in: 0...1) // Simulate correct/incorrect answers
                } else {
                    timer.invalidate()
                    showingExercise = false
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct ExerciseAnimationView: View {
    let exerciseType: PhysicalTherapyExercise
    let bodyPart: RehabilitationBodyPart
    let currentPhase: ExercisePhase
    let animationProgress: Double
    
    var body: some View {
        VStack(spacing: 16) {
            // Body outline with highlighted area
            ZStack {
                // Body outline
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray5))
                    .frame(width: 120, height: 200)
                
                // Highlighted body part
                Circle()
                    .fill(Color.blue.opacity(0.3))
                    .frame(width: 30, height: 30)
                    .position(bodyPartPosition)
                    .overlay(
                        Circle()
                            .stroke(Color.blue, lineWidth: 2)
                    )
            }
            
            // Exercise movement indicator
            HStack(spacing: 20) {
                VStack {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 30))
                        .foregroundColor(.green)
                        .opacity(currentPhase == .upward ? 1.0 : 0.3)
                    
                    Text("Up")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack {
                    Image(systemName: "arrow.down")
                        .font(.system(size: 30))
                        .foregroundColor(.red)
                        .opacity(currentPhase == .downward ? 1.0 : 0.3)
                    
                    Text("Down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Progress indicator
            ProgressView(value: animationProgress)
                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                .frame(width: 200)
        }
    }
    
    private var bodyPartPosition: CGPoint {
        switch bodyPart {
        case .shoulder: return CGPoint(x: 60, y: 60)
        case .elbow: return CGPoint(x: 60, y: 90)
        case .wrist: return CGPoint(x: 60, y: 120)
        case .hip: return CGPoint(x: 60, y: 140)
        case .knee: return CGPoint(x: 60, y: 170)
        case .ankle: return CGPoint(x: 60, y: 190)
        }
    }
}

struct OccupationalActivityView: View {
    let activityType: OccupationalTherapyActivity
    let difficultyLevel: DifficultyLevel
    let currentStep: Int
    
    var body: some View {
        VStack(spacing: 16) {
            // Activity visualization
            HStack(spacing: 30) {
                // Activity icon
                VStack {
                    Image(systemName: activityIcon)
                        .font(.system(size: 40))
                        .foregroundColor(.blue)
                    
                    Text(activityType.displayName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Difficulty indicator
                VStack {
                    HStack(spacing: 4) {
                        ForEach(0..<difficultyStars, id: \.self) { _ in
                            Image(systemName: "star.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.yellow)
                        }
                    }
                    
                    Text(difficultyLevel.displayName)
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
            
            // Activity description
            Text(activityDescription)
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
        }
    }
    
    private var activityIcon: String {
        switch activityType {
        case .dressing: return "tshirt"
        case .cooking: return "flame"
        case .writing: return "pencil"
        case .grooming: return "scissors"
        }
    }
    
    private var difficultyStars: Int {
        switch difficultyLevel {
        case .beginner: return 1
        case .intermediate: return 2
        case .advanced: return 3
        }
    }
    
    private var activityDescription: String {
        switch activityType {
        case .dressing: return "Practice dressing skills with adaptive equipment"
        case .cooking: return "Learn cooking techniques with safety focus"
        case .writing: return "Improve handwriting and fine motor skills"
        case .grooming: return "Develop personal care and grooming abilities"
        }
    }
}

struct SpeechExerciseView: View {
    let exerciseType: SpeechTherapyExercise
    let targetSound: TargetSound
    let currentRepetition: Int
    let totalRepetitions: Int
    
    var body: some View {
        VStack(spacing: 16) {
            // Mouth and speech visualization
            HStack(spacing: 30) {
                // Mouth position
                VStack {
                    Image(systemName: "mouth")
                        .font(.system(size: 40))
                        .foregroundColor(.pink)
                    
                    Text("Mouth Position")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Sound production
                VStack {
                    Image(systemName: "waveform")
                        .font(.system(size: 40))
                        .foregroundColor(.blue)
                    
                    Text("Sound: \(targetSound.displayName)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Repetition counter
            VStack {
                Text("\(currentRepetition)")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
                
                Text("of \(totalRepetitions) repetitions")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Exercise type indicator
            Text(exerciseType.displayName)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.green)
        }
    }
}

struct CognitiveExerciseView: View {
    let exerciseType: CognitiveExercise
    let difficultyLevel: CognitiveDifficulty
    let currentQuestion: Int
    let score: Int
    
    var body: some View {
        VStack(spacing: 16) {
            // Brain visualization
            HStack(spacing: 30) {
                // Brain icon
                VStack {
                    Image(systemName: "brain")
                        .font(.system(size: 40))
                        .foregroundColor(.purple)
                    
                    Text("Cognitive")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Exercise type
                VStack {
                    Image(systemName: exerciseIcon)
                        .font(.system(size: 40))
                        .foregroundColor(.blue)
                    
                    Text(exerciseType.displayName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Score display
            VStack {
                Text("\(score)")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.green)
                
                Text("points")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Difficulty indicator
            HStack(spacing: 4) {
                ForEach(0..<difficultyLevel.rawValue, id: \.self) { _ in
                    Image(systemName: "star.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.yellow)
                }
            }
        }
    }
    
    private var exerciseIcon: String {
        switch exerciseType {
        case .memory: return "brain.head.profile"
        case .attention: return "eye"
        case .problemSolving: return "lightbulb"
        case .language: return "text.bubble"
        }
    }
}

// MARK: - Instruction Views

struct ExerciseInstructionsView: View {
    let exerciseType: PhysicalTherapyExercise
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Instructions")
                .font(.headline)
                .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("• Perform exercises slowly and controlled")
                Text("• Stop if you feel pain or discomfort")
                Text("• Breathe normally throughout the exercise")
                Text("• Maintain proper form and alignment")
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

struct ActivityBenefitsView: View {
    let activityType: OccupationalTherapyActivity
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Benefits")
                .font(.headline)
                .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("• Improves daily living skills")
                Text("• Enhances independence")
                Text("• Builds confidence")
                Text("• Promotes functional recovery")
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

struct SpeechExerciseInstructionsView: View {
    let exerciseType: SpeechTherapyExercise
    let targetSound: TargetSound
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Instructions")
                .font(.headline)
                .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("• Practice the \(targetSound.displayName) sound")
                Text("• Focus on proper mouth positioning")
                Text("• Repeat each exercise clearly")
                Text("• Take breaks as needed")
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

struct CognitiveBenefitsView: View {
    let exerciseType: CognitiveExercise
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Benefits")
                .font(.headline)
                .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("• Improves cognitive function")
                Text("• Enhances memory and attention")
                Text("• Builds problem-solving skills")
                Text("• Promotes brain health")
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

enum PhysicalTherapyExercise: String, CaseIterable {
    case stretching = "stretching"
    case strengthening = "strengthening"
    case rangeOfMotion = "rangeOfMotion"
    case balance = "balance"
    
    var displayName: String {
        switch self {
        case .stretching: return "Stretching"
        case .strengthening: return "Strengthening"
        case .rangeOfMotion: return "Range of Motion"
        case .balance: return "Balance"
        }
    }
}

enum RehabilitationBodyPart: String, CaseIterable {
    case shoulder = "shoulder"
    case elbow = "elbow"
    case wrist = "wrist"
    case hip = "hip"
    case knee = "knee"
    case ankle = "ankle"
    
    var displayName: String {
        switch self {
        case .shoulder: return "Shoulder"
        case .elbow: return "Elbow"
        case .wrist: return "Wrist"
        case .hip: return "Hip"
        case .knee: return "Knee"
        case .ankle: return "Ankle"
        }
    }
}

enum ExercisePhase: String, CaseIterable {
    case starting = "starting"
    case upward = "upward"
    case holding = "holding"
    case downward = "downward"
    case resting = "resting"
    
    var displayName: String {
        switch self {
        case .starting: return "Starting Position"
        case .upward: return "Upward Movement"
        case .holding: return "Hold Position"
        case .downward: return "Downward Movement"
        case .resting: return "Rest"
        }
    }
}

enum OccupationalTherapyActivity: String, CaseIterable {
    case dressing = "dressing"
    case cooking = "cooking"
    case writing = "writing"
    case grooming = "grooming"
    
    var displayName: String {
        switch self {
        case .dressing: return "Dressing"
        case .cooking: return "Cooking"
        case .writing: return "Writing"
        case .grooming: return "Grooming"
        }
    }
}

enum DifficultyLevel: String, CaseIterable {
    case beginner = "beginner"
    case intermediate = "intermediate"
    case advanced = "advanced"
    
    var displayName: String {
        switch self {
        case .beginner: return "Beginner"
        case .intermediate: return "Intermediate"
        case .advanced: return "Advanced"
        }
    }
}

enum SpeechTherapyExercise: String, CaseIterable {
    case articulation = "articulation"
    case fluency = "fluency"
    case voice = "voice"
    case language = "language"
    
    var displayName: String {
        switch self {
        case .articulation: return "Articulation"
        case .fluency: return "Fluency"
        case .voice: return "Voice"
        case .language: return "Language"
        }
    }
}

enum TargetSound: String, CaseIterable {
    case s = "s"
    case r = "r"
    case l = "l"
    case th = "th"
    case sh = "sh"
    
    var displayName: String {
        switch self {
        case .s: return "S"
        case .r: return "R"
        case .l: return "L"
        case .th: return "TH"
        case .sh: return "SH"
        }
    }
}

enum CognitiveExercise: String, CaseIterable {
    case memory = "memory"
    case attention = "attention"
    case problemSolving = "problemSolving"
    case language = "language"
    
    var displayName: String {
        switch self {
        case .memory: return "Memory"
        case .attention: return "Attention"
        case .problemSolving: return "Problem Solving"
        case .language: return "Language"
        }
    }
}

enum CognitiveDifficulty: Int, CaseIterable {
    case easy = 1
    case medium = 2
    case hard = 3
    
    var displayName: String {
        switch self {
        case .easy: return "Easy"
        case .medium: return "Medium"
        case .hard: return "Hard"
        }
    }
}

struct BodyPartButton: View {
    let bodyPart: RehabilitationBodyPart
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(bodyPart.displayName)
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

struct SoundButton: View {
    let sound: TargetSound
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(sound.displayName)
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